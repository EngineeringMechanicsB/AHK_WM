# AHK_WM 配置参考（v2.10.0）

配置文件位置：`%USERPROFILE%\.config\AHK_WM\wm_config.ini`（UTF-16 LE 编码）。
首次运行时自动生成默认配置。修改后重载脚本生效（默认热键 `Alt+R`，或托盘菜单 → *Reload Script*）。

**取值约定**

| 记法 | 含义 |
|---|---|
| `on\|off` | 开关值。`off`、`false`、`0`、空值视为关；其余视为开。 |
| 颜色 | 6 位十六进制 `RRGGBB`，可带 `#` 前缀。几乎所有颜色都支持**渐变**：逗号分隔多个颜色，如 `A020F0,CBA6F7`。 |
| 跨度 | 状态栏定位表达式：`a/b`（共 b 格中的第 a 格）、`(a-c)/b`（第 a 到 c 格）。分母加 `+` 表示文本右对齐、加 `-` 表示左对齐：`20/+20`；`1` = 整行。 |
| % | 0–100 的整数百分比。 |

**v2.9 迁移说明** —— `[Bar]` 节原 snake_case 键（`time_format`、`layout` 等）已统一
改为 PascalCase。旧配置在首次启动时**自动迁移**（旧键值复制到新键名、删除旧键，并写入
`[General] ConfigVersion=2` 标记），无需手动处理。

---

## [General] 全局

| 键 | 类型 | 默认值 | 取值范围 | 说明 |
|---|---|---|---|---|
| `ActiveTheme` | 字符串 | `custom` | `custom`、`nord`、`tokyonight`、`dracula`、`gruvbox`、`monokai`、`solarized-dark`、`solarized-light`、`catppuccin-mocha`、`catppuccin-latte`、`onedark`、`ayu-dark`、`github-dark`、`rose-pine`、`everforest`、`kanagawa`、`material-deep`、`nightfox`、`palenight`、`horizon`、`oxocarbon` | 当前主题。`custom` 使用 `[Theme]` 节的颜色；内置主题名会覆盖之。 |
| `FontName` | 字符串 | `Segoe UI` | 任意已安装字体 | 界面字体。使用 Nerd Font 可显示状态栏图标（WiFi、电池等）。 |
| `TransparencyStep` | 整数 | `10` | 1–50 | 窗口透明度热键的调节步长（%）。 |
| `PauseOnFullscreen` | 开关 | `off` | `on`、`off` | 状态栏所在显示器出现全屏窗口时挂起全部脚本热键。 |
| `ConfigVersion` | 整数 | *(自动)* | `2` | 脚本写入的迁移标记，请勿手改。 |

## [Theme] 主题颜色

所有键均为颜色且支持渐变。仅在 `ActiveTheme=custom` 时生效（内置主题自带配色）。

| 键 | 默认值 | 说明 |
|---|---|---|
| `Background` | `0e050f` | 状态栏、菜单、OSD 的基础背景色。 |
| `Text` | `e5e9f0` | 基础文字颜色。 |
| `Active` | `744da9` | 强调色（激活元素、OSD 文字、进度条）。 |
| `Task` | `CF8DC9` | 工时任务标记颜色（可选键）。 |
| `BorderDrag` | `A020F0,CBA6F7` | 聚焦/拖拽边框颜色（支持渐变）。 |
| `BorderPin` | `FF5555` | 置顶（钉住）指示条颜色。 |
| `BorderUnfocus` | `666666` | 非聚焦窗口边框颜色（WTM / 全窗口边框模式）。 |
| `PowerMenuBg` | `2E3440` | 电源菜单背景。 |
| `PowerBtnShutdown` | `B48EAD` | 关机按钮颜色。 |
| `PowerBtnSleep` | `5E81AC` | 睡眠按钮颜色。 |
| `PowerBtnReboot` | `BF616A` | 重启按钮颜色。 |

## [Paths] 路径

| 键 | 类型 | 默认值 | 说明 |
|---|---|---|---|
| `ButtonDir` | 路径 | `Buttons` | 功能环 8 方向按钮脚本目录。相对路径基于脚本目录解析。 |
| `OutputDir` | 路径 | *(我的文档)* | 剪贴板历史输出目录。`%OUTPUTDIR%` 展开为"我的文档"。 |
| `OutputFile` | 文件名 | `CB.txt` | 剪贴板历史文件名。绝对路径按原样使用，否则相对于 `OutputDir`。 |
| `VimPath` | 路径 | `C:\Windows\system32\notepad.exe` | 剪贴板历史查看器与"编辑选中文件"所用编辑器。 |
| `TerminalExe` | 路径 | `C:\Windows\system32\cmd.exe` | 终端热键启动的终端程序。 |
| `EditorXPct` / `EditorYPct` | % | `20` / `0` | 编辑器窗口位置（主屏尺寸百分比）。 |
| `EditorWidthPct` / `EditorHeightPct` | % | `52` / `74` | 编辑器窗口大小（主屏尺寸百分比）。 |

## [Desktop] 虚拟桌面

| 键 | 类型 | 默认值 | 取值范围 | 说明 |
|---|---|---|---|---|
| `Count` | 整数 | `9` | 1–9 | 虚拟桌面数量。 |
| `HideMethod` | 字符串 | `minimize` | `minimize`、`hide` | 非当前桌面窗口的收纳方式。`hide` 从任务栏/Alt-Tab 移除；`minimize` 仍可达。 |

## [Bar] 状态栏

| 键 | 类型 | 默认值 | 取值范围 | 说明 |
|---|---|---|---|---|
| `HeightPct` | 整数 | `3` | 1–100 | 栏高（屏高百分比，不足以容纳字体时自动加高）。 |
| `Opacity` | % | `78` | 0–100 | 不透明度。 |
| `FontSize` | 整数 | `10` | ≥6 | 字号（pt）。 |
| `MonitorIdx` | 整数 | `1` | 1–显示器数 | 默认栏所在显示器（`Instances` 为空时生效）。 |
| `TimeFormat` | 字符串 | `HH:mm` | AHK `FormatTime` 格式 | 时间格式。 |
| `DateFormat` | 字符串 | `yyyy-MM-dd` | AHK `FormatTime` 格式 | 日期格式。 |
| `CustomItems` | 列表 | `✐ Edit config to hide` | `;` 分隔的文本 | `custom_1..n` 部件的静态文本。`\s` 转义空格、`\\` 转义反斜杠。 |
| `DesktopLabels` | 列表 | `Work,Net` | `,` 分隔的名称 | 桌面名称（超出列表的桌面显示数字）。 |
| `CurrentDesktopLeft` / `CurrentDesktopRight` | 字符串 | `[` / `]` | 任意文本 | 当前桌面标签两侧的标记（`\s` = 空格）。 |
| `CurrentDesktopColor` | 规格 | *(空)* | `颜色1,颜色2,…,bg\|tx,on\|off` | 当前桌面单元格高亮。留空 = 仅方括号样式。 |
| `DesktopDisplayMode` | 字符串 | `all` | `all`、`current`、`occupied` | 桌面部件显示哪些桌面。 |
| `Position` | 字符串 | `top` | `top`、`bottom` | 默认栏位置。 |
| `Offset` | 整数 px | `0` | ≥0 | 栏与屏幕边缘的间距。 |
| `MarginLeft` / `MarginRight` | 整数 px | `0` | ≥0 | 栏左右内缩。 |
| `Layout` | 规格 | *(见模板)* | 见下文 | 栏元素布局——状态栏的核心配置。 |
| `Instances` | 规格 | `1,top,0` | `M,位置,偏移;…`（`M` = 显示器编号或 `*`） | 多栏实例。留空 = 在 `MonitorIdx` 上一条栏。 |
| `AutoHideOnFullscreen` | 开关 | `on` | `on`、`off` | 栏所在显示器全屏时自动隐藏栏。 |
| `Rounded` | 开关 | `on` | `on`、`off` | 栏圆角。 |
| `CornerRadius` | 整数 px | `10` | ≥0 | 圆角半径。 |
| `CornerMode` | 字符串 | `bottom` | `all`、`top`、`bottom` | 哪些角做圆角。 |

### Layout 格式

```
Layout=[N,]元素,跨度[,颜色1,颜色2,…][,bg|tx][,on|off][,fs=N][,wrap=N]; …
```

- `N` —— 栏编号（对应 `Instances` 中的顺序），默认 `1`。
- 元素 —— `desktops`、`time`、`date`、`progress`、`wifi`、`battery`、`volume`、
  `disk`、`mem`、`cpu`、`custom_1..n`、`external_1..n` 之一。
- 颜色 —— 6 位十六进制；一个颜色 = 纯色文字，两个及以上 = 渐变。
- `bg` —— 渐变作为部件**背景**（文字以栏底色"挖空"显示）；`tx`（默认）—— 渐变
  作用于**文字**。
- `on|off` —— `bg` 模式下的圆角开关。
- `fs=N` —— 逐元素的字体大小（磅），默认使用全局 `Bar_FontSize`。
- `wrap=N` —— 逐元素的最大显示行数（默认 `0` = 单行）。`wrap ≥ 2` 时栏自动增高
  以容纳多行。文本中的换行符（`` `n ``）渲染为独立行；长文本自动在单词边界换行。
- 兼容旧语法 `元素:跨度,颜色,…`。

`external_N` 部件支持两种创建方式：

**自包含**（v2.11+）：`BAR:N:lo/hi:文本:键=值` — 位置、颜色、字体全部在推送时
传递，无需 Layout 声明。可用键：`bg`、`tx`、`rd`、`rr`、`fs`、`wrap`。
示例：`BAR:1:0.5/0.8:你好:bg=7AA2F7,fs=14`

**旧版**：`BAR:N:文本` — 需在 Layout 中声明 `external_N`。
推送一次即持续显示，直到下次推送或栏重载。
参见随附示例 `docs/Examples/BarExamples/` 和 `docs/Examples/OSDExamples/`。

## [Border] 边框

类像素值（`Thickness`、`Offset`、`OffsetTop` 及 Pin 系列）采用 0–100 刻度，映射到 0–20 px。

| 键 | 类型 | 默认值 | 取值范围 | 说明 |
|---|---|---|---|---|
| `RefreshMs` | 整数 ms | `10` | ≥1 | 边框/定时器刷新间隔。低配机器可调至 15–20；边框已自动跳过未变化帧。 |
| `Enable` | 开关 | `on` | `on`、`off` | 拖拽移动/缩放时显示拖拽边框。 |
| `Mode` | 字符串 | `full` | `top`、`full` | 边框样式：整框或顶条。 |
| `Thickness` | 0–100 | `35` | 映射 0–20 px | 边框厚度。 |
| `Offset` | 0–100 | `15` | 映射 0–20 px | 边框相对窗口的外扩量。 |
| `OffsetTop` | 0–100 | `5` | 映射 0–20 px | 顶边额外外扩。 |
| `Opacity` | % | `80` | 0–100 | 边框不透明度。 |
| `RoundedCorners` | 开关 | `on` | `on`、`off` | 边框圆角。 |
| `Radius` | 整数 px | `10` | ≥0 | 边框圆角半径。 |
| `CornerMode` | 字符串 | `all` | — | **保留键**——当前未应用于边框。 |
| `Gap` | 整数 px | `10` | 任意 | WTM 平铺间隙（为窗口间边框预留的空间）。 |
| `SizeStep` | 整数 | `3` | ≥1 | **保留键**——预留给未来的 WTM 缩放热键。 |
| `PinMode` | 字符串 | `top` | `top`、`full` | 置顶指示样式。 |
| `PinThickness` | 0–100 | `35` | 映射 0–20 px | 置顶指示厚度。 |
| `PinOffset` / `PinOffsetTop` | 0–100 | `0` / `5` | 映射 0–20 px | 置顶指示偏移。 |
| `PinOpacity` | % | `90` | 0–100 | 置顶指示不透明度。 |
| `PinRounded` | 开关 | `off` | `on`、`off` | 置顶指示圆角。 |
| `PinRadius` | 整数 px | `0` | ≥0 | 置顶指示圆角半径。 |

边框**颜色**统一在 `[Theme]` 配置：`BorderDrag`（聚焦）、`BorderUnfocus`（非聚焦）、
`BorderPin`（置顶）。均支持渐变；WTM 模式的聚焦/非聚焦窗口边框分别使用
`BorderDrag` / `BorderUnfocus`。

## [Tiling] 平铺

| 键 | 类型 | 默认值 | 取值范围 | 说明 |
|---|---|---|---|---|
| `Gap` | 整数 px | `15` | 任意（可为负） | 智能平铺与 WinSelect 平铺的窗口间隙。 |
| `TileAlwaysOnTop` | 开关 | `off` | `on`、`off` | 置顶窗口是否参与平铺。 |
| `Rules` | 规格 | *(见模板)* | `M,N,I,X,Y;…` | 自定义布局规则，智能平铺与 **WTM 均适用**（用户规则优先于内置算法）。`M` = 显示器（`*` = 任意），`N` = 规则适用的窗口总数，`I` = 窗口序号（1..N），`X`/`Y` = 跨度表达式（`1` = 全幅、`a/b`、`(a-c)/b`）。规则组必须完整（1..N 每个序号恰好出现一次）才会生效。 |

## [Snapping] 吸附

| 键 | 类型 | 默认值 | 取值范围 | 说明 |
|---|---|---|---|---|
| `Enable` | 开关 | `on` | `on`、`off` | 拖拽时的边缘吸附。 |
| `Distance` | 整数 px | `0` | ≥0 | 吸附触发距离（同时是吸附后保留的缝隙）。 |
| `Release` | 整数 px | `5` | ≥0 | 脱离吸附线所需的额外距离。 |

## [PieMenu] 功能环

| 键 | 类型 | 默认值 | 取值范围 | 说明 |
|---|---|---|---|---|
| `SizePct` | % | `28` | 1–100 | 功能环直径（屏幕短边百分比）。 |
| `CenterZonePct` | % | `27` | 0–100 | 中心死区半径（环半径百分比），松开于死区内则取消。 |
| `Opacity` | % | `78` | 0–100 | 不透明度。 |
| `FontSize` | 整数 | `14` | ≥6 | 扇区文字字号。 |
| `FontSizeActive` | 整数 | `22` | ≥6 | 高亮扇区字号。 |

## [GUI] 界面

| 键 | 类型 | 默认值 | 取值范围 | 说明 |
|---|---|---|---|---|
| `RoundedCorners` | 开关 | `on` | `on`、`off` | 脚本 GUI 全局圆角。 |
| `CornerRadius` | 整数 px | `12` | ≥0 | 全局圆角半径。 |
| `HelpFontSize` | 整数 | `10` | ≥6 | 帮助窗口字号。 |
| `HelpWidth` | 整数 px | `620` | ≥200 | 帮助窗口宽度。 |
| `HelpHeight` | 整数 px | `0` | 0 = 自动 | 帮助窗口高度。 |
| `HelpOpacity` | % | `100` | 0–100 | 帮助窗口不透明度。 |
| `PowerFontSize` | 整数 | `12` | ≥6 | 电源菜单字号。 |
| `PowerWidth` / `PowerHeight` | 整数 px | `500` / `160` | ≥100 | 电源菜单尺寸。 |
| `PowerOpacity` | % | `100` | 0–100 | 电源菜单不透明度。 |
| `OSDPositionPct` | % | `80` | 0–100 | OSD 垂直位置（屏高百分比）。 |
| `OSDOpacity` | % | `78` | 0–100 | OSD 不透明度。 |
| `OSDFontSize` | 整数 | `20` | ≥6 | OSD 字号。 |
| `HelpRounded`、`HelpRadius`、`PowerRounded`、`PowerRadius`、`OSDRounded`、`OSDRadius` | — | *(全局值)* | — | 可选的按 GUI 覆盖全局圆角设置。 |

### OSD 逐次调用自定义（WM_COPYDATA）

外部脚本可在每次调用时通过附加 `键=值` 键值对覆盖 OSD 的全部视觉设置：

```
OSD:文本[:持续时间毫秒][:fs=24,op=90,x=50%,y=30%,bg=FF4444,tx=FFFFFF]
```

| 键 | 类型 | 默认值 | 说明 |
|---|---|---|---|
| `fs` | 整数 磅 | `OSDFontSize` (20) | 字体大小。 |
| `op` | %  | `OSDOpacity` (78) | 不透明度。 |
| `pos` | %  | `OSDPositionPct` (80) | 垂直位置（0=顶部，100=底部）。 |
| `x` | px/% | *(居中)* | 水平位置：`300` = 300px，`50%` = 屏幕一半。 |
| `y` | px/% | *(pos/配置)* | 垂直位置：`200` = 200px，`30%` = 屏高百分比。 |
| `bg` | 6 位 hex | 主题 `Color_Bg` | 背景色。 |
| `tx` | 6 位 hex | 主题 `Color_Active` | 文字色。 |
| `wr` | 整数 px | `屏幕宽 × 0.85` | 最大宽度，超出自动换行。 |
| `rd` | on/off | `OSDRounded` | 圆角开关。 |
| `rr` | 整数 px | `OSDRadius` | 圆角半径。 |
| `fn` | 名称 | `FontName` | 字体名称。 |
| `tag` | 字符串 | *(无)* | 逻辑标签。同 tag 的新 OSD 会替换旧的（不堆积）。无 tag 则每条 OSD 独立共存。 |

所有键均可选——未指定的键回退使用 `[GUI]` 配置节的全局值。
不传 opts 的旧脚本完全不受影响。

**实例隔离：** 外部 OSD（通过 `WM_COPYDATA` 调用）与内部 OSD
（`wm.ahk` 自身调用）使用独立的实例池。内部 OSD 单实例互替；
外部 OSD 默认独立共存，除非通过 `tag` 分组。两边互不干扰。

## [WorkTime] 工时

| 键 | 类型 | 默认值 | 取值范围 | 说明 |
|---|---|---|---|---|
| `Mode` | 字符串 | `off` | `off`、`workday`、`allday` | 状态栏进度条的工时模式。`off` = 进度条按全天计算。 |
| `WeekendBar` | 开关 | `off` | `on`、`off` | 周末是否显示工时进度。 |
| `WorkStart` / `WorkEnd` | HHMM | `0900` / `1745` | 0000–2359 | 工作时段。 |
| `TaskTimes` | 规格 | *(见模板)* | `星期_HHMM_HHMM[,颜色…];…` | 进度条上方的任务标记。星期 1=周一 … 7=周日。颜色可选（支持渐变），缺省用主题任务色。时间重叠的任务绘制在第二行。 |

## [Exclude] 排除

命中任一规则的窗口不参与平铺、边框和 WinSelect。

| 键 | 类型 | 默认值 | 说明 |
|---|---|---|---|
| `Titles` | 列表 | `Picture-in-Picture` | `;` 分隔的标题规则：纯文本 = *包含*；`=文本` = 精确匹配；`re:模式` = 正则表达式。 |
| `Classes` | 列表 | *(空)* | `;` 分隔的窗口类名（精确，不区分大小写）。 |
| `Processes` | 列表 | *(空)* | `;` 分隔的进程名（精确，不区分大小写），如 `mpv.exe`。 |

## [WinSelect] 窗口选择

| 键 | 类型 | 默认值 | 取值范围 | 说明 |
|---|---|---|---|---|
| `ScaleRatio` | 小数 | `0.85` | 0.2–1.0 | 选择模式下平铺窗口的缩小比例。 |
| `Letters` | 字符串 | `ASDFGHJKLQWERTYUIOPZXCVBNM` | A–Z | 标签字母池（按分配顺序）。 |
| `SizeMap` | 规格 | `1:0.5;2:0.8;3:1.2;9:1920x1080` | `N:比例` 或 `N:宽x高;…` | 先按数字 `N` 再按字母：选中窗口按此调整大小（比例 0.05–10 或绝对尺寸）。 |
| `BarColor` / `TextColor` | 颜色 | *(主题)* | 颜色 | 标签条颜色；留空 = 主题背景 / 强调色。 |
| `Height` | 整数 px | `28` | ≥16 | 标签条高度。 |
| `Width` | 整数 px | `0` | 0 = 窗口宽度 | 标签条宽度。 |
| `OffsetY` | 整数 px | `0` | 任意 | 标签条相对窗口的垂直偏移。 |
| `FontSize` | 整数 | `14` | ≥6 | 标签字号。 |
| `Opacity` | % | `85` | 0–100 | 标签不透明度。 |
| `Rounded` | 开关 | `on` | `on`、`off` | 标签圆角。 |
| `CornerRadius` | 整数 px | `10` | ≥0 | 标签圆角半径。 |
| `CornerMode` | 字符串 | `top` | `all`、`top`、`bottom` | 哪些角做圆角。 |
| `Timeout` | 整数 秒 | `12` | 0 = 永不 | 无按键自动退出时间。 |

## [WinSelectSidebar] 选择侧边栏

列出锁定在其他桌面的窗口字母。

| 键 | 类型 | 默认值 | 取值范围 | 说明 |
|---|---|---|---|---|
| `FontSize` | 整数 | `14` | ≥8 | 侧边栏字号。 |
| `Width` | 整数 px | `80` | ≥50 | 侧边栏宽度。 |
| `Position` | 字符串 | `left` | `left`、`right` | 所在屏幕侧。 |
| `OffsetX` / `OffsetY` | 整数 px | `10` / `0` | 任意 | 侧边栏偏移。 |

## [Clipboard] 剪贴板 *（v2.9 新增）*

剪贴板捕获为系统级：**任何复制途径**都会触发（Ctrl+C、右键菜单、程序内 Edit
菜单、程序化复制）。

| 键 | 类型 | 默认值 | 取值范围 | 说明 |
|---|---|---|---|---|
| `MaxChars` | 整数 | `100000` | 0 = 不限 | 超过此长度的文本在历史文件中截断（追加截断说明并记日志）。 |
| `ExcludeProcesses` | 列表 | *(空)* | `;` 分隔的 exe 名 | 活动窗口属于这些进程时不记录剪贴板——如 `KeePass.exe;1Password.exe`。 |
| `LogBinary` | 开关 | `on` | `on`、`off` | 记录非文本剪贴板内容：复制文件时记录文件路径；图像记录内容类型（不保存图像数据本身）。 |

## [Logging] 日志 *（v2.9 新增）*

结构化日志：`时间戳.毫秒  [级别]  [组件]  消息`。相同消息自动去重计数。
日志文件跨脚本重载持续追加。

| 键 | 类型 | 默认值 | 取值范围 | 说明 |
|---|---|---|---|---|
| `File` | 路径 | *(空)* | 任意路径 | 日志文件。留空 = `<配置目录>\wm.log`。 |
| `Level` | 字符串 | `INFO` | `DEBUG`、`INFO`、`WARN`、`ERROR` | 最低写入级别。 |
| `MaxSizeKB` | 整数 KB | `512` | 0 = 永不 | 超过此大小时轮转为 `<文件>.old`（保留一代）。 |

## [Hotkeys] 热键

自然语法：修饰键名用 `+` 连接——`Alt`、`Shift`、`Ctrl`、`Win`——加一个键名，
如 `Ctrl+Alt+T`。也接受 AHK 原生修饰符语法（`^!t`）。**留空即禁用该热键。**
三个 `*Prefix` 键只填修饰键，与数字 `1–9` 组合使用。

| 键 | 默认值 | 功能 |
|---|---|---|
| `Help` | `Alt+/` | 显示/隐藏帮助窗口。 |
| `Exit` | `Alt+F12` | 还原所有窗口并退出。 |
| `Reload` | `Alt+R` | 重载脚本（桌面布局保留）。 |
| `DesktopSwitchPrefix` | `Alt` | + `1–9`：切换桌面。 |
| `DesktopMovePrefix` | `Alt+Shift` | + `1–9`：把活动窗口移到桌面。 |
| `DesktopMoveSwitchPrefix` | `Ctrl+Alt` | + `1–9`：携带窗口切换（到达后窗口置于最前）。 |
| `TileSmart` | `Alt+D` | 智能平铺鼠标所在显示器。 |
| `GatherAll` | `Alt+Shift+G` | 把所有窗口聚集到当前桌面。 |
| `TogglePin` | `Ctrl+Alt+T` | 切换"所有桌面常显"。 |
| `ToggleBar` | `Ctrl+Alt+B` | 显示/隐藏状态栏。 |
| `SaveLayout` / `RestoreLayout` | `Alt+Shift+S` / `Alt+Shift+R` | 保存/恢复窗口位置快照。 |
| `CloseWindow` | `Alt+Q` | 关闭窗口（鼠标下窗口；**WTM 模式下为聚焦窗口**）。 |
| `CloseWindowAlt` | `Alt+MButton` | 同 `CloseWindow`。 |
| `ToggleMaximize` | `Alt+F` | 最大化/还原鼠标下窗口。 |
| `ToggleTop` | `Alt+T` | 切换置顶（WTM 模式：浮动并排除聚焦窗口）。 |
| `HideWindow` | `Alt+W` | 最小化鼠标下窗口。 |
| `ToggleAllBorders` | *(空)* | 切换全窗口边框模式。 |
| `TransparencyUp` / `TransparencyDown` | `Alt+WheelUp` / `Alt+WheelDown` | 调整窗口透明度。 |
| `SnapLeft` / `SnapRight` | `Alt+Left` / `Alt+Right` | 窗口吸附到左/右半屏。 |
| `SnapUp` / `SnapDown` | `Alt+Up` / `Alt+Down` | 最大化 / 最小化。 |
| `LaunchTerminal` | `Alt+Enter` | 打开终端（资源管理器活动时定位到当前目录）。 |
| `EditFile` | `Alt+V` | 用编辑器打开资源管理器选中的文件。 |
| `PowerMenu` | `Alt+X` | 显示电源菜单。 |
| `ClipboardHistory` | ``Ctrl+` `` | 打开/关闭剪贴板历史查看器。 |
| `DragMove` | `Alt+LButton` | 拖拽移动（带吸附）。 |
| `DragResize` | `Alt+RButton` | 拖拽缩放（带吸附）。 |
| `PieMenuTrigger` | `~Space & RButton` | 打开功能环。 |
| `WinSelect` | `Alt+S` | 窗口选择模式。 |
| `WTMToggle` | *(空；建议 `Alt+Shift+D`)* | 切换 WTM 平铺模式。 |
| `WTMFocusLeft/Down/Up/Right` | `Alt+H/J/K/L` | WTM：方向聚焦。 |
| `WTMMoveLeft/Down/Up/Right` | `Alt+Shift+H/J/K/L` | WTM：方向交换/移动（可跨显示器）。 |

---

## 外部接口（WM_COPYDATA）

向隐藏主窗口发送 `WM_COPYDATA` 消息（窗口标识 `wm.ahk ahk_class AutoHotkey`，
需开启隐藏窗口检测）：

| 负载 | 效果 |
|---|---|
| `OSD:文本[:时长ms]` | 弹出 OSD 提示（使用配置默认值）。 |
| `OSD:文本[:时长ms]:fs=N,op=N,…` | 弹出 OSD 并逐次覆盖外观（参见上方 [GUI] → OSD 逐次调用自定义）。 |
| `BAR:N:文本` | （旧版）设置状态栏 external_N 部件内容。 |
| `BAR:N:lo/hi:文本:键=值,…` | （v2.11+）自包含推送——位置颜色字体换行一次调用。 |

随附示例脚本位于 `docs/Examples/OSDExamples/`（OSD 弹窗）和 `docs/Examples/BarExamples/`
（状态栏部件），每种均提供英文（`En/`）和中文（`Ch/`）版本。
每个脚本内含可直接复制的辅助函数及完整参数文档。
