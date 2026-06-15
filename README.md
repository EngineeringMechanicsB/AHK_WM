# 🔲 AHK WM v2.6.1

<div align="center">

[🇬🇧 **English**](#en) · [🇨🇳 **中文**](#cn)

</div>

---

## 🇬🇧 <a id="en"></a>

A lightweight, fast, single-file window manager for Windows, powered by **AutoHotkey v2**.

Built for people who keep too many windows open and still want their desktop to feel light, predictable, and easy to escape from.

- 📄 **Single-file script** — zero dependency hell
- ⚡ **Fast response** — no heavy background framework
- 🪟 **Windows 7 ~ 11** — works everywhere
- 🧹 **Low interference** — shared/work computer friendly
- ⚙️ **Config-driven** — plug and play
- 🧩 Virtual desktops, smart tiling, KDE-style drag, pie menu, status bar, borders, GUI help page… the works

> I made this because most Windows window managers felt too heavy, too laggy, and would make my computer unusable for anyone else.
> This project has been written and used in real work for about two years.

---

### 📸 Screenshots

| Preview                                       | Description                                                                          |
| --------------------------------------------- | ------------------------------------------------------------------------------------ |
| ![Status Bar](./docs/images/status-bar.png)   | **Status Bar** — desktop indicator, clock, date, progress bar, and custom text/emoji |
| ![Screenshots](./docs/images/Screenshots.png) | **Desktop Overview** — borders, tiling, and multi-window layout                      |
| ![Smart Tile](./docs/images/Smart-tile.gif)   | **Smart Tiling** — one-key window arrangement                                        |
| ![Pie Menu](./docs/images/pie-menu.gif)       | **Pie Menu** — radial menu for quick actions                                         |
| ![WinSelect](./docs/images/window-Select.gif) | **WinSelect Mode** — letter-labeled window picker                                    |
| ![Help Menu](./docs/images/help-menu.png)     | **Help Page** — built-in hotkey reference                                            |

---

### 📦 Installation

#### Option 1: Run the `.ahk` script

1. Install **AutoHotkey v2**  
   👉 <https://www.autohotkey.com/>

2. Download the script to your machine.

3. **Run as Administrator** (recommended — operations on elevated windows won't work otherwise).

That's it.

#### Option 2: Compiled `.exe`

You can also run the compiled executable directly.

> ⚠️ Without AHK v2 installed, the pie menu customization won't work. Installing AHK v2 is still recommended.

---

### 🚀 Quick Start

| Action                        | Hotkey              |
| ----------------------------- | ------------------- |
| 📖 Show/hide help             | `Alt + /`           |
| 🧩 Smart tile current monitor | `Alt + D`           |
| ✋ Move window                 | `Alt + Left Mouse`  |
| 📐 Resize window              | `Alt + Right Mouse` |
| 🔄 Switch desktop             | `Alt + 1~9`         |
| 📦 Move window to desktop     | `Alt + Shift + 1~9` |
| 🚀 Move & switch desktop      | `Ctrl + Alt + 1~9`  |
| 📊 Toggle status bar          | `Ctrl + Alt + B`    |
| 💾 Save layout                | `Alt + Shift + S`   |
| 🔁 Restore layout             | `Alt + Shift + R`   |
| 📌 Gather all windows         | `Alt + Shift + G`   |
| ❌ Close window                | `Alt + Q`           |
| 🔄 Reload script              | `Alt + R`           |
| 🛑 Exit safely                | `Alt + F12`         |
| ⚡ Power menu                  | `Alt + X`           |

Forgot something? Press `Alt + /` — the built-in help page has everything.

---

### 🧰 Features

#### 🖥️ Virtual Desktops

Lightweight virtual desktop system with:

- Desktop switching
- Move windows between desktops
- Move and switch in one action
- Hide method: minimize / transparency

#### 🧩 Smart Tiling

Arrange all windows on the current monitor in one keypress.

Default: `Alt + D`

```ini
[Tiling]
Gap=8
Rules=1,3,1,1/2,1;1,3,2,2/2,1/2;1,3,3,2/2,2/2;
```

Rule format: `M,N,I,X,Y`

- `M` = monitor (`*` = all)
- `N` = total windows
- `I` = window index
- `X` = horizontal span: `1` full / `a/b` segment a / `(a-c)/b` a~c
- `Y` = vertical span (same syntax)

#### ✋ KDE-style Drag

Move/resize from anywhere — no need to aim for the title bar.

```text
Alt + Left  = move
Alt + Right = resize
```

#### 🥧 Pie Menu

Trigger: `Space + Right Mouse`

```ini
[PieMenu]
SizePct=28
CenterZonePct=27
Opacity=78
FontSize=14
FontSizeActive=22
```

Customize with your own shortcuts and workflow commands.

#### 📊 Status Bar

Displays: desktops, time, date, progress, custom text/emoji.

```ini
[Bar]
HeightPct=3
Opacity=78
MonitorIdx=1
position=top    ; top / bottom
```

Custom items:

```ini
custom_items=text1;icon1;text2
layout=custom_1:1/10;custom_2:2/10;desktops:(1-3)/20
```

#### 🖼️ Window Borders

Focused / dragged / pinned / managed windows get visual borders.

```ini
[Border]
DragMode=full          ; full = 4-sided, top = top strip only
DragThickness=15
DragRounded=on
DragRadius=10
PinMode=top
```

#### ⌨️ WTM Mode

Keyboard-driven tiling preview mode. Still experimental — default hotkeys are disabled.

```ini
[WTM]
BorderMode=full
BorderFocusColor=A020F0
BorderThickness=8
Gap=10
```

Enable in config:

```ini
[Hotkeys]
WTMToggle=Alt+Shift+D
```

#### 🎨 Themes

Built-in themes: `nord, tokyonight, dracula, gruvbox, monokai, solarized-dark/light, catppuccin-mocha/latte, onedark, ayu-dark, github-dark, rose-pine, everforest, kanagawa, material-deep, nightfox, palenight, horizon, oxocarbon`

#### ⏱️ Work Timer / Progress Bar

```ini
[WorkTime]
Mode=off
WorkStart=0900
WorkEnd=1745
TaskTimes=1_1200_1300    ; Monday 12:00-13:00
```

---

### 🛠️ v2.6.1 Changelog

Three long-standing window coordinate issues fixed — all rooted in **Windows DWM extended frame causing `WinGetPos` to misalign with what you actually see**.

| #   | Issue                                                     | Fix                                                                                                                                                     |
| --- | --------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1️⃣ | **Toggle OnTop full border had no rounded corners** 🟦    | `PinBorder.Tick()` hardcoded `radius=0` → now uses `Border_Rounded`/`Border_Radius` dynamically                                                         |
| 2️⃣ | **WinSelect letter bar wider than the window** 📏         | `_MakeLabel()` switched from `WinGetPos` to `GetWindowVisualRect()` for true visual width                                                               |
| 3️⃣ | **Negative snap distance broke screen-edge alignment** 🧲 | Added `GetFrameDelta()` helper; `GatherSnapLines`, drag-move, and drag-resize all use visual-rect coordinates for snap, then convert back for `WinMove` |

> 💡 You can now set `Snapping → Distance` back to `8~12`. No more `-15` hacks.

---

### 🔮 Future Plans

- **🧹 Config consolidation** — the current INI structure has accumulated cruft over two years. Plans to gradually unify and clean up configuration sections.
- **🔧 WTM mode stability** — the keyboard-driven tiling mode is still experimental. Future work will focus on edge cases, crash recovery, and smoother multi-monitor support.

---

### ⚙️ Configuration

INI-based. Main sections:

```ini
[General] [Theme] [Paths] [Desktop] [Bar]
[Border] [Tiling] [WTM] [PieMenu] [GUI]
[WorkTime] [Exclude] [Hotkeys] [Snapping] [WinSelect]
```

Edit the config, then reload with `Alt + R`.

---

### 📋 Notes

AHK WM isn't a full desktop environment — it just makes daily window management faster and less annoying.

- WTM is still experimental.
- Some special windows may need manual exclusions.
- Admin windows may require the script to run as administrator.
- Games, UWP apps, and remote desktop sessions may behave differently.

Happy to use. ✨

---

## 🇨🇳 <a id="cn"></a>

# 🔲 AHK WM v2.6.1

一个轻量、快速、单文件的 Windows 窗口管理器，基于 **AutoHotkey v2**。

专为那些窗口永远开一堆、但还想要桌面清爽的人准备。

- 📄 **单文件脚本**，没有复杂依赖
- ⚡ **响应迅速**，没有沉重的后台框架
- 🪟 **Windows 7 ~ 11** 都能跑
- 🧹 **低侵入**，办公室 / 公用电脑友好
- ⚙️ **配置驱动**，开箱即用，不用折腾
- 🧩 虚拟桌面、智能平铺、KDE 风格拖拽、饼菜单、状态栏、窗口边框、GUI 帮助页……该有的都有

> 我写这个脚本是因为觉得大多 Windows 窗口管理器太重、太卡、并且会让其他人完全无法使用我的电脑。
> 这个项目已经写了大约两年，并在实际工作中一直在用。

---

### 📸 截图

| 预览                                                                           | 说明                                 |
| ---------------------------------------------------------------------------- | ---------------------------------- |
| ![状态栏](./docs/images/status-bar.png)                                         | **状态栏** — 桌面指示器、时钟、日期、进度条、自定义文字/图标 |
| ![效果一览](./docs/images/Screenshots.png)                                       | **效果一览** — 窗口边框、平铺、多窗口布局           |
| ![智能平铺](C:\Users\Administrator\Desktop\AHK_WM\docs\images\Smart-tile.gif)    | **智能平铺** — 一键排列窗口                  |
| ![饼菜单](./docs/images/pie-menu.gif)                                           | **饼菜单** — 径向菜单 + 快捷操作              |
| ![窗口选择](C:\Users\Administrator\Desktop\AHK_WM\docs\images\window-Select.gif) | **WinSelect 选择模式** — 字母标签快速选中窗口    |
| ![帮助页](C:\Users\Administrator\Desktop\AHK_WM\docs\images\help-menu.png)      | **内置帮助页** — 快捷键速查                  |

---

### 📦 安装

#### 方式一：直接运行 `.ahk` 脚本

1. 安装 **AutoHotkey v2** 👉 <https://www.autohotkey.com/>
2. 下载脚本到本地
3. **以管理员身份运行**（推荐，否则对管理员窗口的部分操作可能无效）

搞定。

#### 方式二：编译版 `.exe`

也可以直接跑编译后的 exe 文件。

> ⚠️ 如果没装 AHK v2，饼菜单的功能无法自定义。建议还是装上。

---

### 🚀 基本操作

| 功能           | 快捷键                 |
| ------------ | ------------------- |
| 📖 显示/隐藏帮助   | `Alt + /`           |
| 🧩 智能平铺当前显示器 | `Alt + D`           |
| ✋ 移动窗口       | `Alt + 左键`          |
| 📐 调整窗口大小    | `Alt + 右键`          |
| 🔄 切换桌面      | `Alt + 1~9`         |
| 📦 移动窗口到桌面   | `Alt + Shift + 1~9` |
| 🚀 移动并切到桌面   | `Ctrl + Alt + 1~9`  |
| 📊 切换顶部状态栏   | `Ctrl + Alt + B`    |
| 💾 保存布局      | `Alt + Shift + S`   |
| 🔁 恢复布局      | `Alt + Shift + R`   |
| 📌 收集所有窗口    | `Alt + Shift + G`   |
| ❌ 关闭窗口       | `Alt + Q`           |
| 🔄 重载脚本      | `Alt + R`           |
| 🛑 安全退出      | `Alt + F12`         |
| ⚡ 电源菜单       | `Alt + X`           |

按 `Alt + /` 打开内置帮助页。

---

### 🧰 主要功能

#### 🖥️ 虚拟桌面

轻量级虚拟桌面系统。支持切换桌面、移窗口到另一个桌面、移动并切换、可选隐藏方式。

#### 🧩 智能平铺

一键排列当前显示器的所有窗口。默认 `Alt + D`。

```ini
[Tiling]
Gap=8
Rules=1,3,1,1/2,1;1,3,2,2/2,1/2;1,3,3,2/2,2/2;
```

规则格式：`M,N,I,X,Y` — M 显示器 / N 窗口数 / I 索引 / X 水平跨度 / Y 垂直跨度

#### ✋ KDE 风格窗口拖拽

从窗口任意位置拖拽/缩放，不用对准标题栏。

```text
Alt + 左键 = 移动
Alt + 右键 = 缩放
```

#### 🥧 饼菜单

按 `空格 + 右键` 触发，菜单项可自定义。

```ini
[PieMenu]
SizePct=28
CenterZonePct=27
Opacity=78
FontSize=14
FontSizeActive=22
```

#### 📊 状态栏

显示虚拟桌面、时间、日期、进度条、自定义文字/图标/emoji。

```ini
[Bar]
HeightPct=3
position=top    ; top / bottom
```

#### 🖼️ 窗口边框

```ini
[Border]
DragMode=full    ; full 四边框 / top 仅顶条
DragThickness=15
DragRounded=on
PinMode=top
```

#### ⌨️ WTM 模式

键盘驱动的窗口平铺预览模式，仍在测试中。

#### 🎨 主题

内置 20+ 主题：nord、tokyonight、dracula、gruvbox、monokai 等。

#### ⏱️ 工作进度条

```ini
[WorkTime]
Mode=off
WorkStart=0900
WorkEnd=1745
```

---

### 🛠️ v2.6.1 更新内容

修复了三个长期存在的窗口坐标问题，根源都一样——**Windows DWM 扩展边框导致 WinGetPos 和肉眼可见的不一致**。

| #   | 问题                             | 怎么修的                                                                       |
| --- | ------------------------------ | -------------------------------------------------------------------------- |
| 1️⃣ | **Toggle OnTop 全边框没有圆角** 🟦    | `PinBorder.Tick()` 传 radius=0 → 改为根据 `Border_Rounded`/`Border_Radius` 动态计算 |
| 2️⃣ | **WinSelect 字母标签条比窗口宽一截** 📏   | `_MakeLabel()` 改用 `GetWindowVisualRect()` 获取真实可视宽度                         |
| 3️⃣ | **吸附功能距离设负数才对齐，结果屏幕边界吸附偏移** 🧲 | 新增 `GetFrameDelta()` 辅助函数，`GatherSnapLines`、拖拽移动/缩放全改成以可视矩形坐标做吸附计算         |

---

### 🔮 未来计划

- **🧹 配置统一整理** — 脚本功能越来越多，INI 配置项有些散乱。计划逐步统一、清理配置结构。
- **🔧 WTM 模式稳定性** — 键盘平铺模式目前仍在试验阶段，计划逐步完善。

---

### ⚙️ 配置

INI 配置文件，主要段落：`[General] [Theme] [Bar] [Border] [Tiling] [WTM] [PieMenu] [GUI] [WorkTime] [Exclude] [Hotkeys] [Snapping] [WinSelect]`

改完配置按 `Alt + R` 重载即可。

---

### 📋 注意事项

AHK WM 不是桌面环境，不打算替代 Windows。只是让日常窗口操作快一点、少烦人一点。

- WTM 模式仍在试验中
- 某些特殊窗口可能需要手动排除
- 管理员窗口可能要求脚本以管理员身份运行
- 游戏 / UWP / 远程桌面可能会有不同表现

Happy to use. ✨

---

*Version 2.6.1 — 2026-06-15*
