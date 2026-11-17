# AGENTS.md — 项目级 Agent 行为约束

> 本文件面向所有在此仓库工作的 AI Agent。项目文档为中文，回答与提交说明也使用中文。
> 生效范围：仓库根目录（本目录含 `.git`，是项目根）到当前工作目录。子目录可按需增加自己的 `AGENTS.md`。

## 1. 项目是什么

这是一个**中文工科作业 Markdown → A4 PDF 的 Pandoc + XeLaTeX 模板系统**，并且本目录**同时是 Pandoc 的用户数据目录**（`pandoc -d homework` 依赖这个位置）。

| 路径 | 作用 | 改动代价 |
|---|---|---|
| `defaults/homework.yaml` | 转换入口：pdf 引擎、模板、metadata、过滤器顺序 | 高（全局） |
| `metadata/homework.yaml` | 约 50 个设计 token 默认值 | 中 |
| `filters/*.lua` | 6 个过滤器：取默认宽、表格测量、行内图/代码、单元格内边距、跨页图提示 | 高 |
| `templates/homework.tex` | 主模板 1566 行：视觉层 + 表格实测引擎 | 高 |
| `templates/homework-backup.tex` | Pandoc 3.11 默认 latex 模板备份，**不参与转换** | 只读 |
| `scripts/*.ps1` | `pandoc` 函数钩子 + 后台 watcher（自动重编译） | 中 |
| `test/test.md` / `test/test.pdf` | 功能验收清单 + 视觉回归基线 | 只读基线 |
| `README.md` / `DEVELOPMENT.md` | 用户手册 / 维护者实现文档 | 改行为时同步 |

## 2. 硬性约束（必须遵守）

1. **转换入口唯一**：在 Markdown 所在目录执行 `pandoc <name>.md -d homework -o <name>.pdf`。
   不要绕过 `-d homework` 直接 `--template`：模板没有 metadata 回退，缺字段会在 XeLaTeX 阶段报错。
2. **过滤器顺序不可变**（`defaults/homework.yaml`）：
   `image-row → table-width → inline-image → table-padding → inline-code → figure-defer-note`。
   顺序承载依赖关系，调整前先读 DEVELOPMENT.md §1。
3. **Lua ⇄ TeX 契约双向同步**：过滤器注入的 `\Homework*` 宏、`data-homework-default-width`、
   `data-homework-inside-table` 标记，改任一侧必须同步另一侧，并在 `test/test.md` 增加对应样例。
4. **不要手改二进制产物**：`test/test.pdf` 只能由 test.md 重新生成；改模板/过滤器后必须重生成，
   并按 test.md 末尾的检查清单人工核对版面（表格跨页、横向页、图片组编号、跨页提示页码等）。
5. **`homework-backup.tex` 是只读基线**：它是本机 Pandoc 3.11 `pandoc -D latex` 的逐字备份（UTF-16LE），
   不是旧版本模板，也不要拿它覆盖 `homework.tex`。
6. **没有用户明确要求时，不要执行 `git commit` / `git push` / 改 `.git`**；不要删除或移动
   `defaults/`、`metadata/`、`filters/`、`templates/`（它们的位置就是 Pandoc 数据目录约定）。
7. **不提交生成物**：`*.aux`、`*.log`、`*.toc`、`*.out`、`*.fls`、转换临时 PDF；
   `test/report.md`、`test/report.pdf`、`test/codes/`（重复素材）目前是未跟踪文件，不要顺手加入 git。
8. **最小 diff**：不要整体格式化/重排 `homework.tex` 或 `table-width.lua`；不要重命名既有
   `\Homework*` 宏与 metadata 键（会破坏 README 的公开契约）。
9. **新增参数必须四件套齐全**：`metadata/homework.yaml` 默认值 → 模板读取 → `README.md` 参数表 →
   如涉及算法再补 `DEVELOPMENT.md`。不要在 Lua 里新增硬编码中文文案（现有硬编码属历史债）。
10. **不要删除“兼容分支”**：未测量表格的 `l/c/r/p` 列分支、紧急断点估算等路径，
   清理前须按 DEVELOPMENT.md §8.4 / §11.3 逐项确认。

## 3. 改动地图（改什么 → 先看哪里）

| 想改动 | 应修改 | 修改前必读 |
|---|---|---|
| 字体/页面/字号/行距 | `metadata/homework.yaml` | README“文档、页面与标题区” |
| 代码块/引用块/行内代码样式 | `metadata` + `homework.tex` L379–L560 | README 对应表 |
| 单图默认宽度/题注 | `image-row.lua`、`metadata`、模板 L83–L126 | README“单张图片与题注” |
| 图片组 | `image-row.lua` + 模板 L129–L341 | README“单行图片组” |
| 表格列宽/换行/跨页/横向页 | `table-width.lua` + 模板 L641–L1404 | **DEVELOPMENT.md §3–§11** |
| 跨页图片提示 | `figure-defer-note.lua` + 模板 L97–L127 | DEVELOPMENT.md §9 |
| 自动转换/监视器 | `scripts/*.ps1` | README“自动转换” |

## 4. 验证流程

1. 在 `test/` 下重新生成：`pandoc test.md -d homework -o test.pdf`（需要多趟 XeLaTeX，正常）；
2. 检查编译日志：不得出现 `homework-table` 错误、表格相关 `Overfull \hbox`、非法列格式；
3. 对照 `test/test.md` 末尾清单检查：表格双线/续表、横向页、图片编号连续性、跨页提示唯一性、页边距；
4. 表格改动额外对照 DEVELOPMENT.md §11.2 的 11 项检查清单；
5. 改完若行为变化，同步更新 README/DEVELOPMENT 对应章节，并说明未验证项。

## 5. 环境与已知边界

- 版本基线：**Pandoc 3.11**、XeLaTeX（TeX Live 2026）、Windows PowerShell 5.1。
  模板强耦合 Pandoc writer 输出形状，升级 Pandoc 前必须先用 test.md 回归。
- 已知问题：表格内自动宽度图片的 `\pandocbounded` 依赖需 `-V graphics=true` 验证（DEVELOPMENT §12）；
  复杂块级单元格、局部跨列、无题注跨页长表编号未完全覆盖。
- 自动转换：`pandoc` 函数由 PowerShell profile 点源 `scripts/pandoc-command-hook.ps1` 提供；
  后台 watcher 硬编码 `-d homework`、250 ms 轮询、状态文件在 `%LOCALAPPDATA%\PandocHomeworkWatcher\`。
  改脚本时保持 UTF-8 BOM、避免递归调用自身、不要留下运行中的 watcher。
- 本文件由 Agent 运行时自动加载；修改后在**新会话**或下一次文件读写后才重新生效（不是实时监视）。
