# Pandoc 工科作业模板

将中文 Markdown 工科作业转换为 A4 PDF。模板基于 XeLaTeX，支持标题、目录、公式、代码、引用块、网格表格、跨页续表、图片题注和单行图片组。

## 常用功能与参数速查

Markdown 顶部的同名 YAML 字段会覆盖全局默认值。

| 功能 | 参数或写法 | 默认值 | 说明 |
|---|---|---:|---|
| 主标题 | `title` | 无 | 未设置时不生成标题区 |
| 副标题 | `subtitle` | 无 | 显示在主标题下方 |
| 标题附加信息 | `title-details` | 无 | 字符串或带样式的项目列表 |
| 目录 | `toc` | `false` | 设为 `true` 后生成目录 |
| 章节编号 | `numbersections` | `false` | 设为 `true` 后为标题编号 |
| 正文字号 | `fontsize` | `11pt` | 常用值如 `10pt`、`11pt`、`12pt` |
| 正文行距 | `linestretch` | `1.30` | 行距倍数 |
| 页边距 | `geometry` | 四边 `30mm` | 建议同时填写四边 |
| 标题居中层级 | `center-heading-depth` | `1` | `0` 不居中，`1` 至 `3` 对应标题层级 |
| 单图宽度 | `width=...` | `33%` | 仅独立图片使用默认值；显式值优先 |
| 行内图片垂直偏移 | `inline-image-shift` | `-0.20em` | 负值向下移动，使图片与正文视觉居中 |
| 图片组缩放 | `scale` / `image-row-scale` | `1` | 最终不会超过正文宽度 |
| 图片组间距 | `gap-ratio` / `image-row-gap-ratio` | `0.04` | 全部间距占图片组总宽度的比例 |
| 图片组最大高度 | `max-height` / `image-row-max-height` | `60mm` | 保持宽高比，不裁剪 |
| 表格单元格横向留白 | `table-padding-x` | `10pt` | 控制表格紧凑程度 |
| 表格单元格纵向留白 | `table-padding-y` | `3pt` | 撑开文字首末行及表格图片的上下净空 |
| 表格行高 | `table-row-stretch` | `1.30` | 表格行高倍数 |
| 行内代码内边距 | `inline-code-padding-x/y` | `2pt` | 长代码会自动拆成多行代码框 |

完整默认值位于 [metadata/homework.yaml](./metadata/homework.yaml)，完整示例位于 [test/test.md](./test/test.md)。表格实现、数据流和维护约定见 [DEVELOPMENT.md](./DEVELOPMENT.md)。

## 快速开始

在 Markdown 文件所在目录运行：

```powershell
pandoc homework.md -d homework -o homework.pdf
```

最小文档：

```markdown
---
title: "第 1 次作业"
subtitle: "模拟电路实验报告"
title-details:
  - "示例学生"
  - "电子信息 1 班"
toc: true
numbersections: true
---

# 第一题

正文内容。
```

请从 Markdown 文件所在目录执行命令；图片位于其他目录时，可通过 Pandoc 的 `resource-path` 指定搜索路径。

## 自动转换

首次成功执行带 `-d homework` 或 `--defaults homework` 的命令后，PowerShell 会监视该 Markdown 所在目录：

- 保存 `.md` 时，仅当同目录已有同名 `.pdf` 才自动覆盖更新；
- 转换失败时保留原 PDF；
- 重复执行转换命令不会启动重复监视器；
- 监视器与启动它的 PowerShell 终端绑定，关闭终端后自动停止。

查看状态和最近日志：

```powershell
pandoc-watch-status
```

停止监视当前目录：

```powershell
pandoc-watch-stop
```

## 参数详细说明

### 文档、页面与标题区

| 字段 | 默认值 | 作用 |
|---|---:|---|
| `title` | 无 | 主标题；未设置时不生成标题区 |
| `subtitle` | 无 | 副标题 |
| `title-details` | 无 | 主标题下的自定义信息列表 |
| `title-details-font-size` | `normalsize` | 附加信息的默认字号 |
| `title-details-italic-slant` | `0.20` | 中文仿斜体的倾斜程度 |
| `documentclass` | `article` | LaTeX 文档类型，通常无需修改 |
| `fontsize` | `11pt` | 正文字号 |
| `papersize` | `a4` | 纸张尺寸 |
| `geometry` | 四边 `30mm` | 页面边距 |
| `linestretch` | `1.30` | 正文行距倍数 |
| `colorlinks` | `false` | 是否使用彩色链接文字 |

`title-details` 可以直接填写字符串，也可以设置单项样式：

```yaml
title-details:
  - "班级：电子信息 1 班"
  - text: "实验组：第三组"
    size: small
    bold: true
  - text: "指导教师：示例教师"
    italic: true
    underline: true
```

单项支持 `text`、`size`、`bold`、`italic` 和 `underline`。标题区使用正文字体；主标题和副标题字号由模板固定。

### 目录与章节标题

| 字段 | 默认值 | 作用 |
|---|---:|---|
| `toc` | `false` | 是否生成目录 |
| `toc-depth` | `2` | 目录收录的标题层级 |
| `toc-title` | `目录` | 目录标题 |
| `toc-linestretch` | `1.30` | 目录行距 |
| `numbersections` | `false` | 是否为标题添加编号 |
| `secnumdepth` | `5` | 标题编号的最大层级 |
| `center-heading-depth` | `1` | 居中的标题层级，范围为 `0` 至 `3` |

在 Markdown YAML 中使用 `toc` 和 `numbersections`，不要写成 defaults 文件选项名 `table-of-contents` 或 `number-sections`。

### 字体

| 字段 | 默认值 | 用途 |
|---|---|---|
| `mainfont` | `TeX Gyre Termes` | 英文正文 |
| `sansfont` | `TeX Gyre Heros` | 英文无衬线文字 |
| `monofont` | `Latin Modern Mono` | 英文代码 |
| `CJKmainfont` | `FandolSong-Regular` | 中文正文 |
| `CJKsansfont` | `FandolHei-Regular` | 中文无衬线文字 |
| `CJKmonofont` | `FandolFang-Regular` | 中文代码 |
| `mathfont` | `Latin Modern Math` | 数学公式 |

自定义字体前，应确认 XeLaTeX 能找到对应字体。

### 代码块、引用块与行内代码

颜色使用六位十六进制值，不写 `#`。

| 类型 | 参数 | 默认值 |
|---|---|---:|
| 代码块 | `code-background` | `F8F8F8` |
| 代码块 | `code-border-color` / `code-border-width` | `D2D2D2` / `0.5pt` |
| 代码块 | `code-border-radius` | `5pt` |
| 代码块 | `code-padding-x` / `code-padding-y` | `8pt` / `6pt` |
| 代码块 | `code-block-spacing` | `1.2em` |
| 引用块 | `quote-border-color` / `quote-border-width` | `808080` / `2pt` |
| 引用块 | `quote-background` | `F7F7F7` |
| 引用块 | `quote-padding-x` / `quote-padding-y` | `10pt` / `6pt` |
| 引用块 | `quote-block-spacing` | `0.8em` |
| 行内代码 | `inline-code-border-color` / `inline-code-border-width` | `A6A6A6` / `0.4pt` |
| 行内代码 | `inline-code-border-radius` | `1pt` |
| 行内代码 | `inline-code-padding-x` / `inline-code-padding-y` | `2pt` / `2pt` |

短行内代码保持为一个完整圆角框。内容超过正文行宽时，优先在空格、路径分隔符、点、下划线、连字符和常用标点后换行；没有自然断点时才按字符拆分。换行后的每一行都继续使用完整的行内代码样式。

### 单张图片与题注

```markdown
![输出波形](./assets/waveform.png){#fig:waveform}

如图 \ref{fig:waveform} 所示，输出符合预期。
```

- 独立图片未设置 `width` 时默认使用正文宽度的 33%；
- `width=52%` 等显式值会覆盖默认宽度；
- 图片始终保持宽高比，不改变全局页边距；
- 方括号中的文字生成题注，`#fig:...` 生成引用标签；
- 方括号为空时不生成题注和图片编号；
- 正文中的行内图片不应用 33% 默认宽度；
- 行内图片默认下移 `0.20em` 以对齐正文，可通过 `inline-image-shift` 调整，负值向下、正值向上。

题注参数：

| 字段 | 默认值 | 作用 |
|---|---:|---|
| `caption-font-size` | `small` | 题注字号 |
| `caption-font-family` | `FandolFang-Regular` | 题注字体 |
| `caption-label-weight` | `md` | 编号标签字重 |
| `caption-figure-name` | `图` | 图片题注名称 |
| `caption-table-name` | `表` | 表格题注名称 |
| `caption-label-separator` | `space` | 编号与题注内容的分隔方式 |

### 单行图片组

```markdown
::: {.image-row #fig:waveforms caption="不同负载下的输出波形" scale=1.1}
![空载](./assets/no-load.png){#fig:no-load}
![半载](./assets/half-load.png){#fig:half-load}
![满载](./assets/full-load.png){#fig:full-load}
:::
```

`.image-row` 中的图片始终排列为一行、等高显示并保持各自宽高比。图片较多时整体缩小，间距随数量自动减小，不会修改或超出正文页边距。

| 全局字段 | 组内覆盖参数 | 默认值 | 作用 |
|---|---|---:|---|
| `image-row-full-count` | 无 | `3` | 达到该数量时默认使用完整正文宽度 |
| `image-row-scale` | `scale` | `1` | 图片组整体缩放系数 |
| `image-row-gap-ratio` | `gap-ratio` | `0.04` | 全部间距占图片组总宽度的比例 |
| `image-row-max-height` | `max-height` | `60mm` | 图片最大显示高度 |

题注和编号规则：

- `caption` 是可选的整组题注；每张图片方括号中的文字是可选的子题注；
- 只有子题注时，不显示整组题注；
- 只有整组题注时，子图仍显示独立编号；
- 两类题注都存在时，同时显示整组题注和子题注；
- 两类题注全部为空时，只排版图片，不生成题注、编号或可引用标签；
- 有题注的图片组占用一个主编号，各子图使用 `4-1`、`4-2` 等编号，后续普通图片继续使用下一个主编号。

### 表格

```markdown
| 元件 | 数值 | 单位 |
|:---|:---:|---:|
| 电阻 $R_1$ | 4.7 | k$\Omega$ |

: 基本元件参数
```

分隔行中的 `:---`、`:---:` 和 `---:` 分别表示左对齐、居中和右对齐。表格采用完整网格，表头上下为双横线；跨页时，前一页显示“下页续”，续页显示“表 n（续）”并重复列标题。

所有表格都会在 TeX 排版前使用最终字体测量普通文字、公式、图片、Raw LaTeX 和代码的实际宽度，不再依赖 Pandoc 是否已将其标记为宽表。普通文字的自然宽度包括同一行中的中文、英文、粗体、斜体和公式；自然宽度能够放入正文时，短表直接使用内容所需宽度。只有自然宽度确实超出页面时，模板才会通过二分搜索寻找满足表头约两行、正文单元格约三行的最小首选宽度；重新分配后的总宽度小于正文预算时，表格会随内容收缩。每列仍保留 `table-min-readable-columns` 指定的硬下限，纵向页面容纳不下时自动切换为横向页面；横向页面仍无法满足硬下限时终止转换并说明所需宽度。连续 URL、路径或标识符会预先获得不可见断点，使试排和最终表格具有一致的换行能力。公式和安全的行内 Raw LaTeX 使用有限缩放的硬下限；结构性 Raw LaTeX 仍会终止转换。行内代码和代码块以完整实测宽度作为首选宽度，页面空间不足时仍可收缩并换行。无显式宽度的图片以固有尺寸和正文宽度的 33% 中较小者作为首选宽度，显式图片宽度按作者设置参与分配；图片最终保持比例并限制在单元格内部。defaults 文件中的 `columns: 60` 仅用于兼容 Pandoc 及未显式配置时的预算回退，不再参与宽表筛选。

| 字段 | 默认值 | 作用 |
|---|---:|---|
| `table-rule-width` | `0.35pt` | 外框、竖线和正文横线粗细 |
| `table-header-rule-gap` | `1.2pt` | 表头双横线间距 |
| `table-padding-x` | `10pt` | 单元格水平内边距 |
| `table-padding-y` | `3pt` | 撑开实际首末行和表格图片上下边距；表头顶部从双横线的下方横线起算 |
| `table-row-stretch` | `1.30` | 表格行高倍数 |
| `table-natural-width-columns` | `72` | 纵向页面的名义字符预算；用于把最小可读宽度换算为物理尺寸，不再用于筛选宽表 |
| `table-unbreakable-text-columns` | `12` | 连续文本触发紧急断点前保留的宽度；不作用于公式 |
| `table-min-readable-columns` | `6` | 每列不可突破的最小可读宽度 |
| `table-overflow-policy` | `landscape` | 纵向页面无法满足硬下限时切换到横向页面 |
| `table-landscape-width-columns` | `112` | 横向页面的字符宽度预算 |
| `table-overflow-failure` | `error` | 横向页面仍无法容纳时停止转换并报告原因 |
| `table-math-min-scale` | `0.8` | 公式实测宽度参与列宽分配时的硬下限，同时限制最终安全缩放；再小则停止转换 |

### 数学公式与工程单位

使用 Pandoc Markdown 的行内公式 `$...$` 和独立公式 `$$...$$`。工程单位可写为 `$R=4.7\,\mathrm{k}\Omega$`；不要把希腊字母放进 `\mathrm{...}`，以免数学字体缺字。

## 文件结构

```text
pandoc/
├── README.md
├── defaults/homework.yaml          # Pandoc 转换配置
├── filters/
│   ├── image-row.lua               # 单图默认宽度与图片组排版
│   ├── inline-image.lua            # 行内图片垂直对齐
│   └── inline-code.lua             # 长行内代码换行
├── metadata/homework.yaml          # 可覆盖的默认元数据
├── scripts/
│   ├── pandoc-command-hook.ps1     # Pandoc 命令入口
│   └── pandoc-homework-watcher.ps1 # Markdown 后台监视器
├── templates/
│   ├── homework.tex                # 当前转换模板
│   └── homework-backup.tex         # Pandoc 默认模板的备份
└── test/
    ├── test.md                     # 带说明的完整功能示例
    ├── test.pdf                    # 示例输出
    └── assets/example.png
```

`homework-backup.tex` 是 Pandoc 默认 LaTeX 转换模板的备份，仅用于查阅和对照，不参与实际转换，也不是当前模板的恢复副本。

## 使用建议

- 单篇文档的调整写在 Markdown YAML 中；
- 需要改变所有文档的默认值时修改 `metadata/homework.yaml`；
- 只有改变结构或排版逻辑时才修改 `templates/homework.tex` 或过滤器；
- 修改模板后重新生成 `test/test.pdf`，并对照 `test/test.md` 中的说明检查结果。

Pandoc 的标准元数据，如 `abstract`、`bibliography` 和 `header-includes`，仍可正常使用。
