$script:HomeworkPandocWatcherScript = Join-Path $PSScriptRoot 'pandoc-homework-watcher.ps1'
$script:HomeworkPandocExecutable = (Get-Command pandoc.exe -CommandType Application -ErrorAction Stop).Source
$script:HomeworkPandocStateRoot = Join-Path $env:LOCALAPPDATA 'PandocHomeworkWatcher'

function Get-HomeworkPandocWatcherKey {
    param([string]$Directory)

    $normalized = [System.IO.Path]::GetFullPath($Directory).TrimEnd('\').ToLowerInvariant()
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

function Get-HomeworkPandocWatcherState {
    param([string]$Directory)

    $fullDirectory = [System.IO.Path]::GetFullPath($Directory)
    $key = Get-HomeworkPandocWatcherKey -Directory $fullDirectory
    [PSCustomObject]@{
        Directory = $fullDirectory
        PidPath   = Join-Path $script:HomeworkPandocStateRoot "$key.pid"
        LogPath   = Join-Path $script:HomeworkPandocStateRoot "$key.log"
    }
}

function Test-HomeworkDefaultsArguments {
    param([object[]]$Arguments)

    for ($index = 0; $index -lt $Arguments.Count; $index++) {
        $argument = [string]$Arguments[$index]
        $value = $null

        if (($argument -eq '-d' -or $argument -eq '--defaults') -and $index + 1 -lt $Arguments.Count) {
            $value = [string]$Arguments[$index + 1]
        }
        elseif ($argument -match '^(?:-d|--defaults)=(.+)$') {
            $value = $Matches[1]
        }

        if ($null -ne $value) {
            $leaf = [System.IO.Path]::GetFileNameWithoutExtension($value)
            if ($leaf -ieq 'homework') {
                return $true
            }
        }
    }

    return $false
}

function Get-HomeworkMarkdownDirectories {
    param([object[]]$Arguments)

    $directories = @{}
    foreach ($argumentObject in $Arguments) {
        $argument = [string]$argumentObject
        if ($argument.StartsWith('-') -or [System.IO.Path]::GetExtension($argument) -ine '.md') {
            continue
        }

        $candidate = $argument
        if (-not [System.IO.Path]::IsPathRooted($candidate)) {
            $candidate = Join-Path (Get-Location).Path $candidate
        }

        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            $directory = [System.IO.Path]::GetDirectoryName([System.IO.Path]::GetFullPath($candidate))
            $directories[$directory.ToLowerInvariant()] = $directory
        }
    }

    return @($directories.Values)
}

function Start-HomeworkPandocWatcher {
    param([Parameter(Mandatory = $true)][string]$Directory)

    $state = Get-HomeworkPandocWatcherState -Directory $Directory
    if (Test-Path -LiteralPath $state.PidPath) {
        $existingPid = Get-Content -LiteralPath $state.PidPath -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($existingPid -and (Get-Process -Id ([int]$existingPid) -ErrorAction SilentlyContinue)) {
            return $false
        }
        Remove-Item -LiteralPath $state.PidPath -Force -ErrorAction SilentlyContinue
    }

    $quotedScript = '"{0}"' -f $script:HomeworkPandocWatcherScript
    $quotedDirectory = '"{0}"' -f $state.Directory
    $quotedPandoc = '"{0}"' -f $script:HomeworkPandocExecutable
    $parentStartTimeUtcTicks = (Get-Process -Id $PID).StartTime.ToUniversalTime().Ticks
    $processArguments = @(
        '-NoLogo',
        '-NoProfile',
        '-NonInteractive',
        '-ExecutionPolicy', 'Bypass',
        '-File', $quotedScript,
        '-Directory', $quotedDirectory,
        '-PandocPath', $quotedPandoc,
        '-ParentProcessId', $PID,
        '-ParentStartTimeUtcTicks', $parentStartTimeUtcTicks
    )

    Start-Process -FilePath 'powershell.exe' -ArgumentList $processArguments -WindowStyle Hidden | Out-Null

    for ($attempt = 0; $attempt -lt 20; $attempt++) {
        if (Test-Path -LiteralPath $state.PidPath) {
            return $true
        }
        Start-Sleep -Milliseconds 100
    }

    Write-Warning "未能确认后台监视器启动，请运行 pandoc-watch-status 查看日志。"
    return $false
}

function global:pandoc-watch-status {
    param([string]$Directory = (Get-Location).Path)

    $state = Get-HomeworkPandocWatcherState -Directory $Directory
    $running = $false
    $watcherPid = $null

    if (Test-Path -LiteralPath $state.PidPath) {
        $watcherPid = Get-Content -LiteralPath $state.PidPath -ErrorAction SilentlyContinue | Select-Object -First 1
        $running = [bool]($watcherPid -and (Get-Process -Id ([int]$watcherPid) -ErrorAction SilentlyContinue))
    }

    if ($running) {
        Write-Output "正在监视: $($state.Directory) (PID $watcherPid)"
    }
    else {
        Write-Output "未监视: $($state.Directory)"
    }

    if (Test-Path -LiteralPath $state.LogPath) {
        Write-Output "日志: $($state.LogPath)"
        Get-Content -LiteralPath $state.LogPath -Tail 10
    }
}

function global:pandoc-watch-stop {
    param([string]$Directory = (Get-Location).Path)

    $state = Get-HomeworkPandocWatcherState -Directory $Directory
    if (-not (Test-Path -LiteralPath $state.PidPath)) {
        Write-Output "该目录没有正在运行的监视器: $($state.Directory)"
        return
    }

    $watcherPid = Get-Content -LiteralPath $state.PidPath -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($watcherPid) {
        Stop-Process -Id ([int]$watcherPid) -ErrorAction SilentlyContinue
    }
    Remove-Item -LiteralPath $state.PidPath -Force -ErrorAction SilentlyContinue
    Write-Output "已停止监视: $($state.Directory)"
}

function global:pandoc {
    $pandocArguments = @($args)
    & $script:HomeworkPandocExecutable @pandocArguments
    $pandocExitCode = $LASTEXITCODE

    if ($pandocExitCode -eq 0 -and (Test-HomeworkDefaultsArguments -Arguments $pandocArguments)) {
        foreach ($directory in Get-HomeworkMarkdownDirectories -Arguments $pandocArguments) {
            if (Start-HomeworkPandocWatcher -Directory $directory) {
                Write-Output "已自动监视 Markdown 目录: $directory"
            }
        }
    }

    $global:LASTEXITCODE = $pandocExitCode
}

