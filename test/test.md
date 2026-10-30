---
title: "工程作业模板测试"
subtitle: "Pandoc Markdown 转 PDF"
title-details:
  - text: "示例学生"
    bold: true
  - text: "学号：示例编号"
    size: small
  - text: "课程：模拟电路原理"
    italic: true
  - text: "日期：YYYY-MM-DD"
    underline: true
toc: true
toc-depth: 2
numbersections: true
secnumdepth: 3
center-heading-depth: 2
---

# 正文、标题与常用元素

本节集中检查中英文混排、强调、链接、脚注和标题层级。模板启用了 `center-heading-depth: 2`，因此一级、二级标题应居中，三级标题应左对齐。

中文正文可以混排 English terms、**粗体**、*斜体*、[Pandoc 官方网站](https://pandoc.org/)以及脚注。[^note] 常用特殊字符包括效率 95%、参数 A&B 和文件名 `measurement_data.csv`。

[^note]: 这是脚注排版测试，正文与脚注之间应保持清晰层次。

## 二级标题

二级标题应居中显示。正文中的行内图片 ![行内图标](./assets/example.png){width=1em} 应随文字排列，不应用独立图片的默认宽度。

### 三级标题

三级标题应保持左对齐，用于验证标题层级和章节编号。

## 列表与引用

- 无序列表第一项；
- 无序列表第二项，包含子项：
  - 电压测量；
  - 波形记录。

1. 阅读题目；
2. 建立模型；
3. 求解并检查单位。

> 工程计算不仅要得到数值，还应检查单位、数量级和物理意义。

# 数学公式

行内公式示例：欧姆定律为 $U=IR$，工程单位可写成 $R=4.7\,\mathrm{k}\Omega$、$f=10\,\mathrm{kHz}$。

下面检查独立公式、对齐和积分符号：

$$
\begin{aligned}
A_v &= \frac{U_o}{U_i},\\
u_L(t) &= L\frac{\mathrm{d}i(t)}{\mathrm{d}t},\\
u_C(t) &= \frac{1}{C}\int i(t)\,\mathrm{d}t.
\end{aligned}
$$

矩阵与分段函数示例：

$$
\mathbf{A}=\begin{bmatrix}1&2\\3&4\end{bmatrix},
\qquad
u_o=\begin{cases}
-U_{\mathrm{sat}}, & A_vu_i<-U_{\mathrm{sat}},\\
A_vu_i, & |A_vu_i|\le U_{\mathrm{sat}},\\
+U_{\mathrm{sat}}, & A_vu_i>+U_{\mathrm{sat}}.
\end{cases}
$$

# 代码排版

带语言标记的代码应具有语法高亮、背景、边框和内边距：

```python
import numpy as np


def rms(values):
    values = np.asarray(values, dtype=float)
    return np.sqrt(np.mean(values**2))


print(f"RMS = {rms([1, -1, 1, -1]):.2f}")
```

无语言标记的代码块应使用相同的外框样式：

```
Vin  = 1.00 V
Vout = 8.52 V
Av   = 8.52
```

## 行内代码换行

短行内代码应保持为单个圆角框，例如 `inline_code` 和 `a_b\c{d}%#&~^--`。

下面的长路径应优先在路径分隔符、点、下划线或连字符后换行，每行仍是完整的代码框：`C:\projects\engineering-homework\reports\2026\semester-one\experiment-results\measurement_data_2026_final_review_version.csv`。

没有自然断点的连续标识符应在无法容纳时按字符拆分：`verylongcontinuousidentifierwithoutanyseparatorandwithenoughadditionalcharacterstobecomewiderthantheentiretextlinewidth`。

\newpage

# 表格

## 基础样式、对齐与题注

下面的短表同时检查完整竖线、表头上下双横线、正文细横线、左中右对齐、数学内容和题注。单元格上下留白应一致；表格结束后第一列竖线不得向下延长，表格与下方正文之间也不应出现异常空白。

| 元件 | 参数 | 数值 |
|:---:|:---:|:---:|
| 电阻 $R_1$ | 阻值 | $1.0\,\mathrm{k}\Omega$ |
| 电容 $C_1$ | 电容值 | $100\,\mathrm{nF}$ |
| 电感 $L_1$ | 电感值 | $10\,\mathrm{mH}$ |

: 基本元件参数

下面的短表检查普通表格的自然宽度和统一内边距。它应按内容所需宽度排版，不应强制铺满正文。

| 项目 | 状态 |
|:---:|:---:|
| 短表 | 正常 |

下面的短表用于检查实际字体度量。中英文、粗体和斜体应按最终字体的真实宽度参与分配，同时保持内容宽度，不应铺满正文。

| 样式 | 内容 | 状态 |
|:---:|:---:|:---:|
| 混排 | 中文 **WMW 粗体**、*italic narrow* 与普通文本 | 正常 |

## 宽度分类与普通文本换行

下面的表格源文本足以触发 Pandoc 的宽表候选，但实际内容可以在正文内自然排下，因此最终仍应按内容宽度收缩。

| 圆极化波辐射状态 | $\hat n'\perp\hat n$ | $\hat n'\parallel\hat n$ |
|:---:|:---:|:---:|
| 直射波 $I_i$ | 正常 | 正常 |

下面的宽表用于检查长单元格换行、换行后的列宽重新分配和总宽度约束。自然宽度超过正文后应自动换行；换行后的首选宽度若小于正文预算，表格应随新宽度收缩，而不是继续铺满正文。表格左右边框不得超出正文页边距。

| 项目 | 详细说明 | 状态 |
|:---:|:---:|:---:|
| 宽度约束 | This cell contains a deliberately long sentence with ordinary spaces and enough words to require wrapped fixed-width columns while the complete table remains inside the document text margins. | 正常 |

下面的表格专门检查换行表头与正文的纵向留白。较长表头应换成约两行，第一行相对表头下方双横线的下沿保留约 `3pt` 距离；正文换行后的上下留白应与普通表格一致，内容整体保持竖直居中。

| 序号 | 这是一个故意写得很长并且需要自动换行以检查首行与表头下方双横线距离是否保持一致的表头内容 | 检查结果 |
|:---:|:---|:---:|
| 1 | 表头与正文都发生换行后，第一行和最后一行仍应分别保留统一的上、下内边距，并且整行内容在单元格中保持竖直居中。 | 正常 |

下面的表格用于检查未被 Pandoc 预先标记为宽表、但全角显示宽度已经超过正文的情况。中文内容应自动换行，表格不得越过正文页边距。

| 内容 | 状态 |
|:---:|:---:|
| 这是一个源码字符数较少但全角显示宽度很大的中文连续内容用于验证自然列宽表格也能被识别 | 正常 |

下面的表格用于检查没有空格的 URL、路径和长标识符。只在内容无法装入最终列宽时增加断点，不应伸出单元格边框。

| 类型 | 内容 | 状态 |
|:---:|:---|:---:|
| URL | https://example.com/reports/2026/very_long_measurement_result_identifier_without_spaces | 正常 |
| 路径 | C:\\measurements\\waveguide_results\\very_long_output_filename_without_spaces.csv | 正常 |
| 标识符 | ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ | 正常 |

## 公式、图片、Raw LaTeX 与代码

下面的表格用于检查原子内容和特殊内容参与首次列宽分配，而不只是依赖落版后的安全检查。公式应以实际 TeX 宽度参与分配；自动宽度图片的首选宽度不超过正文内容预算的 33%；显式宽度图片应保留作者设置；所有内容最终都不得穿过单元格边线。

| 类型 | 内容 | 预期结果 |
|:---:|:---:|:---:|
| 公式 | $V_{\mathrm{out}}=A_v(V_+-V_-)+V_{\mathrm{offset}}+\frac{R_2}{R_1+R_2}V_{\mathrm{ref}}$ | 实际宽度参与分配 |
| 图片（自动） | ![自动宽度单元格图片](./assets/example.png) | 保持比例并限制在单元格内 |
| 图片（显式） | ![显式宽度单元格图片](./assets/example.png){width=28mm} | 保留 `28mm` 设置 |
| Raw LaTeX | `\textsc{Measured Raw Content}`{=latex} | 实际宽度参与分配 |
| 行内代码 | `calibration_result_identifier_2026` | 必要时分段换行 |

下面的网格表用于检查表格单元格中的代码块。最长代码行应参与首选列宽计算，但仍可按字符换行，不应形成不可突破的硬宽度。

+----------+------------------------------------------------------------------+
| 类型     | 内容
+==========+==================================================================+
| 代码块   |     calibration_result_identifier_without_separator_2026
|          |     second_line
+----------+------------------------------------------------------------------+

## 横向页面降级

下面的十二列表格用于检查最小可读列宽和横向页面降级。各列不得被压缩到不可读宽度，整张表应自动放入横向页面，并在结束后恢复纵向页面。

| 第01列 | 第02列 | 第03列 | 第04列 | 第05列 | 第06列 | 第07列 | 第08列 | 第09列 | 第10列 | 第11列 | 第12列 |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| 数据01 | 数据02 | 数据03 | 数据04 | 数据05 | 数据06 | 数据07 | 数据08 | 数据09 | 数据10 | 数据11 | 数据12 |

## 跨页续表

下面的长表用于检查单元格换行和跨页逻辑。发生分页时，前一页末尾应显示“下页续”，下一页应先显示“表2（续）”，随后重复列标题。

| 序号 | 测试项目 | 方法与预期结果 | 状态 |
|:---:|:---:|:---|:---:|
| 1 | 空载输出 | 测量稳态电压，结果应接近设计值 | 合格 |
| 2 | 半载输出 | 接入额定负载的一半并记录电压 | 合格 |
| 3 | 满载输出 | 接入额定负载并检查压降 | 合格 |
| 4 | 输出纹波 | 使用示波器测量峰峰值纹波 | 合格 |
| 5 | 启动时间 | 记录上电至输出稳定所需时间 | 合格 |
| 6 | 关断响应 | 检查关断后的输出衰减过程 | 合格 |
| 7 | 低频增益 | 输入低频正弦信号并记录幅值 | 合格 |
| 8 | 中频增益 | 在通带内测量输入输出幅值 | 合格 |
| 9 | 高频增益 | 提高频率并观察增益下降 | 待复核 |
| 10 | 截止频率 | 寻找幅频响应下降至 $-3\,\mathrm{dB}$ 的位置 | 合格 |
| 11 | 相位响应 | 比较输入输出信号的相位差 | 合格 |
| 12 | 输出削顶 | 增大输入幅值并观察非线性失真 | 合格 |
| 13 | 温度变化 | 连续运行后记录关键器件温度 | 待复核 |
| 14 | 电源扰动 | 改变供电电压并检查输出稳定性 | 合格 |
| 15 | 重复测量 | 重复关键步骤并比较测量偏差 | 合格 |
| 16 | 数据归档 | 检查原始数据、图像和计算记录 | 合格 |
| 17 | 零点校准 | 短接输入并检查仪器零点偏差 | 合格 |
| 18 | 量程检查 | 切换测量量程并比较显示结果 | 合格 |
| 19 | 探头补偿 | 输入方波并调整示波器探头补偿 | 合格 |
| 20 | 接地检查 | 确认公共地连接可靠且无地环路 | 合格 |
| 21 | 噪声测量 | 记录无输入时的输出噪声 | 待复核 |
| 22 | 失真测量 | 测量额定输出下的谐波失真 | 合格 |
| 23 | 负载变化 | 切换不同负载并比较输出变化 | 合格 |
| 24 | 参数计算 | 使用原始数据重新计算关键参数 | 合格 |
| 25 | 图表核对 | 对照数据检查曲线与题注 | 合格 |
| 26 | 单位核对 | 检查数值、单位和数量级 | 合格 |
| 27 | 结论复核 | 确认结论能够由测量结果支持 | 合格 |
| 28 | 文件检查 | 确认文档、图片和数据均已保存 | 合格 |

: 综合测试记录

# 图片、题注与编号

## 单张图片

下面的独立图片没有填写 `width`，应自动使用正文宽度的 33%，生成“图1”并可被引用。

![默认宽度单图](./assets/example.png){#fig:single-default}

下面显式设置 `width=18%`，因此应覆盖默认宽度并生成“图2”。

![显式宽度单图](./assets/example.png){#fig:single-explicit width=18%}

引用检查：图 \ref{fig:single-default} 和图 \ref{fig:single-explicit}。

## 单行图片组

只有子题注时，不显示整组题注；该组占用主编号 3：

::: {.image-row #fig:row-child-only}
![单图子题注](./assets/example.png){#fig:row-child-only-a}
:::

整组题注和子题注可以同时使用；`scale` 用于整体缩放：

::: {.image-row #fig:row-both caption="两张图片的整组题注" scale=0.8}
![左侧子图](./assets/example.png){#fig:row-both-left}
![右侧子图](./assets/example.png){#fig:row-both-right}
:::

只有整组题注时，子图仍有独立编号但不显示说明文字。该组三张图片还用于检查动态间距和最大高度：

::: {.image-row #fig:row-group-only caption="三张图片的整组题注" scale=1.2 gap-ratio=0.03 max-height=45mm}
![](./assets/example.png){#fig:row-group-only-a}
![](./assets/example.png){#fig:row-group-only-b}
![](./assets/example.png){#fig:row-group-only-c}
:::

下面的图片组没有整组题注和子题注，应只显示图片，不生成题注，也不占用图片编号：

::: {.image-row}
![](./assets/example.png)
![](./assets/example.png)
:::

因此，图片组后的普通单图应继续编号为“图6”。

![图片组后的普通单图](./assets/example.png){#fig:image-after-rows width=18%}

编号引用检查：图 \ref{fig:row-child-only}、图 \ref{fig:row-child-only-a}、图 \ref{fig:row-both-left}、图 \ref{fig:row-group-only-b} 和图 \ref{fig:image-after-rows}。

# 最终检查清单

- 目录、章节编号和三级标题对齐是否正确；
- 代码块、引用块和长行内代码是否完整；
- 表格分页前是否显示“下页续”，续页是否显示“表2（续）”并重复列标题；
- 单图默认宽度、显式宽度和图片组等高排版是否正确；
- 无题注图片组是否不占编号，最后一张普通图片是否为“图6”；
- 页边距、页码以及中英文字体是否一致。
