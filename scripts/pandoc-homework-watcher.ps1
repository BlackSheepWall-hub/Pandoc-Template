param(
    [Parameter(Mandatory = $true)]
    [string]$Directory,

    [Parameter(Mandatory = $true)]
    [string]$PandocPath,

    [Parameter(Mandatory = $true)]
    [int]$ParentProcessId,

    [Parameter(Mandatory = $true)]
    [long]$ParentStartTimeUtcTicks
)

$ErrorActionPreference = 'Stop'
$watchDirectory = [System.IO.Path]::GetFullPath($Directory)
$stateRoot = Join-Path $env:LOCALAPPDATA 'PandocHomeworkWatcher'

function Get-WatcherKey {
    param([string]$Path)

    $normalized = [System.IO.Path]::GetFullPath($Path).TrimEnd('\').ToLowerInvariant()
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($normalized)
        $hash = $sha256.ComputeHash($bytes)
        return ([System.BitConverter]::ToString($hash)).Replace('-', '').Substring(0, 16)
    }
    finally {
        $sha256.Dispose()
    }
}

function Write-WatcherLog {
    param([string]$Message)

    $line = '{0:yyyy-MM-dd HH:mm:ss} {1}' -f (Get-Date), $Message
    Add-Content -LiteralPath $script:logPath -Value $line -Encoding UTF8
}

function Test-ParentProcessAlive {
    try {
        $parent = Get-Process -Id $ParentProcessId -ErrorAction Stop
        return $parent.StartTime.ToUniversalTime().Ticks -eq $ParentStartTimeUtcTicks
    }
    catch {
        return $false
    }
}

function Invoke-MarkdownConversion {
    param([string]$MarkdownPath)

    $pdfPath = [System.IO.Path]::ChangeExtension($MarkdownPath, '.pdf')
    if (-not (Test-Path -LiteralPath $pdfPath -PathType Leaf)) {
        return
    }

    $name = [System.IO.Path]::GetFileNameWithoutExtension($pdfPath)
    $temporaryPdf = Join-Path $watchDirectory ('.{0}.pandoc-watch-{1}.pdf' -f $name, $PID)

    try {
        Write-WatcherLog ('开始转换: {0}' -f [System.IO.Path]::GetFileName($MarkdownPath))
        $output = & $PandocPath $MarkdownPath -d homework -o $temporaryPdf 2>&1
        $exitCode = $LASTEXITCODE

        if ($output) {
            foreach ($line in $output) {
                Write-WatcherLog ([string]$line)
            }
        }

        if ($exitCode -ne 0 -or -not (Test-Path -LiteralPath $temporaryPdf -PathType Leaf)) {
            Write-WatcherLog ('转换失败，保留原 PDF: {0}' -f [System.IO.Path]::GetFileName($pdfPath))
            return
        }

        Move-Item -LiteralPath $temporaryPdf -Destination $pdfPath -Force
        Write-WatcherLog ('已更新: {0}' -f [System.IO.Path]::GetFileName($pdfPath))
    }
    catch {
        Write-WatcherLog ('转换异常，保留原 PDF: {0}' -f $_.Exception.Message)
    }
    finally {
        if (Test-Path -LiteralPath $temporaryPdf) {
            Remove-Item -LiteralPath $temporaryPdf -Force -ErrorAction SilentlyContinue
        }
    }
}

if (-not (Test-Path -LiteralPath $watchDirectory -PathType Container)) {
    throw "监视目录不存在: $watchDirectory"
}

if (-not (Test-Path -LiteralPath $PandocPath -PathType Leaf)) {
    throw "Pandoc 不存在: $PandocPath"
}

New-Item -ItemType Directory -Path $stateRoot -Force | Out-Null
$watcherKey = Get-WatcherKey -Path $watchDirectory
$pidPath = Join-Path $stateRoot "$watcherKey.pid"
$script:logPath = Join-Path $stateRoot "$watcherKey.log"

Set-Content -LiteralPath $pidPath -Value $PID -Encoding ASCII

try {
    Set-Location -LiteralPath $watchDirectory
    Write-WatcherLog "开始监视: $watchDirectory"

    $knownWriteTimes = @{}
    $pendingChanges = @{}

    foreach ($file in Get-ChildItem -LiteralPath $watchDirectory -Filter '*.md' -File) {
        $knownWriteTimes[$file.FullName] = $file.LastWriteTimeUtc.Ticks
    }

    while (Test-ParentProcessAlive) {
        $now = [DateTime]::UtcNow
        $currentFiles = @{}

        foreach ($file in Get-ChildItem -LiteralPath $watchDirectory -Filter '*.md' -File -ErrorAction SilentlyContinue) {
            $currentFiles[$file.FullName] = $file.LastWriteTimeUtc.Ticks

            if (-not $knownWriteTimes.ContainsKey($file.FullName)) {
                $knownWriteTimes[$file.FullName] = $file.LastWriteTimeUtc.Ticks
                $pendingChanges[$file.FullName] = $now
            }
            elseif ($knownWriteTimes[$file.FullName] -ne $file.LastWriteTimeUtc.Ticks) {
                $knownWriteTimes[$file.FullName] = $file.LastWriteTimeUtc.Ticks
                $pendingChanges[$file.FullName] = $now
            }
        }

        foreach ($path in @($knownWriteTimes.Keys)) {
            if (-not $currentFiles.ContainsKey($path)) {
                $knownWriteTimes.Remove($path)
                $pendingChanges.Remove($path)
            }
        }

        foreach ($path in @($pendingChanges.Keys)) {
            if (($now - $pendingChanges[$path]).TotalMilliseconds -ge 750) {
                $pendingChanges.Remove($path)
                if (Test-Path -LiteralPath $path -PathType Leaf) {
                    Invoke-MarkdownConversion -MarkdownPath $path
                }
            }
        }

        Start-Sleep -Milliseconds 250
    }

    Write-WatcherLog "启动终端已关闭，自动停止监视: $watchDirectory"
}
finally {
    Write-WatcherLog "停止监视: $watchDirectory"
    if (Test-Path -LiteralPath $pidPath) {
        Remove-Item -LiteralPath $pidPath -Force -ErrorAction SilentlyContinue
    }
}

