<div align="center">

# 🔲 AHK WM <sub>v2.8.0</sub>

<p>
  <img src="https://img.shields.io/badge/AutoHotkey-v2.0-brightgreen?style=flat-square" alt="AutoHotkey v2" />
  <img src="https://img.shields.io/badge/平台-Windows_7_~_11-blue?style=flat-square" alt="平台" />
  <img src="https://img.shields.io/badge/许可-MIT-brightgreen?style=flat-square" alt="许可" />
  <img src="https://badgen.net/github/release/EngineeringMechanicsB/AHK_WM?icon=github" alt="版本" />
  <img src="https://badgen.net/github/stars/EngineeringMechanicsB/AHK_WM?icon=github" alt="Stars" />
</p>

<p>
  <a href="README.md"><img src="https://img.shields.io/badge/README-English-blue?style=for-the-badge" alt="English" /></a>
  <a href="README-zh.md"><img src="https://img.shields.io/badge/README-简体中文-red?style=for-the-badge" alt="简体中文" /></a>
</p>

**轻量、快速、单文件的 Windows 窗口管理器 — AutoHotkey v2**

</div>

---

## 📑 目录

- [✨ 功能概览](#-功能概览)
- [📸 截图](#-截图)
- [📦 安装](#-安装)
- [🚀 快速上手](#-快速上手)
- [🧰 详细功能](#-详细功能)
  - [🖥️ 虚拟桌面](#️-虚拟桌面)
  - [🧩 智能平铺](#-智能平铺)
  - [✋ KDE 风格拖拽](#-kde-风格拖拽)
  - [🥧 饼菜单](#-饼菜单)
  - [📊 状态栏](#-状态栏)
  - [🖼️ 窗口边框](#️-窗口边框)
  - [🔤 WinSelect](#-winselect)
  - [⌨️ WTM 模式](#️-wtm-模式)
  - [📐 窗口吸附](#-窗口吸附)
  - [💾 布局保存/恢复](#-布局保存恢复)
  - [🎨 主题](#-主题)
  - [⏱️ 工作计时器](#️-工作计时器)
  - [📋 剪贴板历史](#-剪贴板历史)
  - [🔌 编辑器 & 终端](#-编辑器--终端)
  - [⚡ 电源菜单及其他](#-电源菜单及其他)
- [⚙️ 配置](#️-配置)
- [🛠️ 更新日志](#️-更新日志)
- [🔮 路线图](#-路线图)
- [❓ 常见问题](#-常见问题)
- [🤝 参与贡献](#-参与贡献)
- [📄 许可证](#-许可证)
- [⭐ Star 历史](#-star-历史)

---

## ✨ 功能概览

|  |  |  |
|---|---|---|
| 📄 **单文件** | 一个 `.ahk` 脚本，零依赖 | 🧩 **智能平铺** | 一键排列窗口 |
| ⚡ **快速** | 无后台框架 | 🖥️ **9 个虚拟桌面** | 快捷键切换/移动/收集 |
| 🖥️ **Win 7 ~ 11** | 覆盖所有版本 | 🥧 **饼菜单** | `空格 + 右键` 触发 |
| 🧹 **低侵入** | 公用电脑友好 | 📊 **状态栏** | 桌面、时钟、日期、进度 |
| ⚙️ **INI 配置** | 编辑即重载 | 🎨 **20+ 主题** | Nord、Dracula、Catppuccin 等 |
| 🌈 **渐变色** | 状态栏、边框、电源菜单 | 📋 **剪贴板历史** | 内置记录与查看 |

> 两年日常使用打磨。起因是市面上的 Windows 窗口管理器都太重，别人完全没法用我的电脑。

---

## 📸 截图

| 预览 | 说明 |
|------|------|
| ![效果一览](docs/images/Screenshots.png) | **效果一览** — 边框、平铺、多窗口布局 |
| ![智能平铺](docs/images/Smart-tile.gif) | **智能平铺** — 一键排列当前显示器所有窗口 |
| ![饼菜单](docs/images/pie-menu.gif) | **饼菜单** — `空格 + 右键` 径向菜单 |
| ![窗口选择](docs/images/window-Select.gif) | **WinSelect** — 字母标签叠加层，快速切换 |
| ![状态栏](docs/images/status-bar.png) | **状态栏** — 桌面指示器、时钟、日期、进度条 |
| ![帮助页](docs/images/help-menu.png) | **内置帮助** — `Alt + /` 查看全部快捷键 |

### 🎨 Bar 自定义（v2.8）

逐元素渐变背景、圆角和文字样式。

<p align="center">
  <img src="docs/images/bar-layout.png" alt="Bar Layout" width="80%" />
  <br/><em>渐变背景 + 圆角（bg 模式）</em>
</p>

<p align="center">
  <img src="docs/images/bar-config.png" alt="Bar Config" width="80%" />
  <br/><em>配置格式：N,element,span,colors,bg|tx,on|off</em>
</p>

<p align="center">
  <img src="docs/images/bar-fullscreen.png" alt="Bar Fullscreen" width="80%" />
  <br/><em>自定义效果一览</em>
</p>

### 🌈 边框渐变（v2.8）

`BorderDrag`、`BorderPin`、`BorderUnfocus` 支持逗号分隔渐变色。

<p align="center">
  <img src="docs/images/border-gradient.png" alt="Border Gradient" width="80%" />
  <br/><em>拖拽边框渐变效果</em>
</p>

<p align="center">
  <img src="docs/images/border-fullscreen.png" alt="Border Fullscreen" width="80%" />
  <br/><em>边框渐变实机展示</em>
</p>

---

## 📦 安装

### 方式一：运行 `.ahk` 脚本 ⭐ 推荐

1. 安装 **AutoHotkey v2** → https://www.autohotkey.com/
2. 从[最新发布页](https://github.com/EngineeringMechanicsB/AHK_WM/releases/latest)下载 `wm_V2.6.4.ahk`
3. **以管理员身份运行**（操作管理员窗口需要）

完成。

### 方式二：编译版 `.exe`

直接运行，无需安装 AHK 即可使用基本功能。

<p align="center">
  <a href="https://github.com/EngineeringMechanicsB/AHK_WM/releases/latest">
    <img src="https://img.shields.io/badge/下载-最新版本-blue?style=for-the-badge" alt="下载最新版本" />
  </a>
</p>

> ⚠️ 饼菜单自定义等高级功能需要 AHK v2。建议使用脚本运行。

---

## 🚀 快速上手

| 操作 | 快捷键 |
|------|--------|
| 📖 帮助页 | `Alt + /` |
| 🧩 平铺当前显示器 | `Alt + D` |
| ✋ 任意位置移动窗口 | `Alt + 左键` |
| 📐 任意位置缩放窗口 | `Alt + 右键` |
| 🔄 切换桌面 1~9 | `Alt + 1 ~ 9` |
| 📦 移动窗口到其他桌面 | `Alt + Shift + 1 ~ 9` |
| 🚀 移动并跟随切换 | `Ctrl + Alt + 1 ~ 9` |
| 📊 切换状态栏 | `Ctrl + Alt + B` |
| 💾 保存布局 | `Alt + Shift + S` |
| 🔁 恢复布局 | `Alt + Shift + R` |
| 🧲 收集所有窗口 | `Alt + Shift + G` |
| 🔍 调节窗口透明度 | `Alt + 滚轮` |
| 📌 切换置顶 | `Alt + T` |
| ❌ 关闭鼠标下方窗口 | `Alt + Q` |
| 🔃 重载脚本 | `Alt + R` |
| 🛑 安全退出 | `Alt + F12` |
| ⚡ 电源菜单 | `Alt + X` |
| 🥧 饼菜单 | `空格 + 右键` |

> 💡 忘了快捷键？按 `Alt + /`，内置帮助页列出了所有按键。

---

## 🧰 详细功能

### 🖥️ 虚拟桌面

9 个桌面，各自独立追踪焦点。

| 操作 | 快捷键 |
|------|--------|
| 切换到桌面 1~9 | `Alt + 1 ~ 9` |
| 移动窗口到其他桌面 | `Alt + Shift + 1 ~ 9` |
| 移动并跟随切换 | `Ctrl + Alt + 1 ~ 9` |
| 收集所有窗口到当前桌面 | `Alt + Shift + G` |

隐藏方式：**最小化** 或 **透明化**。可指定窗口跨桌面始终可见。

```ini
[Desktop]
HideMethod=minimize        ; minimize | transparency
```

---

### 🧩 智能平铺

一键排列当前显示器所有窗口。根据显示器比例自动匹配布局 — **标准屏** (16:9/16:10)、**竖屏**、**超宽屏** 各有独立规则。

默认：`Alt + D`

```ini
[Tiling]
Gap=8
Rules=1,3,1,1/2,1;1,3,2,2/2,1/2;1,3,3,2/2,2/2;
```

**规则格式：** `M,N,I,X,Y`

| 字段 | 含义 | 示例 |
|------|------|------|
| `M` | 显示器编号（`*` = 全部） | `1` |
| `N` | 该显示器窗口总数 | `3` |
| `I` | 当前窗口序号（从 1 开始） | `2` |
| `X` | 水平跨度 | `1` = 全宽, `a/b` = a 段, `(a-c)/b` = a~c 段 |
| `Y` | 垂直跨度 | 同上 |

**排除窗口**（按标题/类名/进程）：
```ini
[Exclude]
Title=re:.*Steam.*;=Calculator
Class=AceApp
Process=devenv.exe;chrome.exe
```

使用 `SetTileBound` / `ClearTileBound` 保护平铺边界。

---

### ✋ KDE 风格拖拽

从窗口任意位置拖拽移动或缩放，不用对准标题栏。

```
Alt + 左键  →  移动
Alt + 右键  →  缩放
```

DWM 边框差量补偿，像素级定位。

---

### 🥧 饼菜单

`空格 + 右键` 弹出 8 方向径向菜单。菜单项、透明度、字号、中心区域均可配置。

```ini
[PieMenu]
SizePct=28
CenterZonePct=27
Opacity=78
FontSize=14
FontSizeActive=22
```

---

### 📊 状态栏

多显示器状态栏，比例布局，**支持渐变色和圆角**。显示虚拟桌面、时钟、日期、工作进度、自定义文字/图标。

```ini
[Bar]
HeightPct=3
Opacity=78
MonitorIdx=1
position=top              ; top | bottom
```

**元素布局格式**（渐变 + 圆角）：
```ini
; N,element,span,c1..cn,bg|tx,on|off
layout=1,time,20/20,ff0000,00ff00,bg,on;desktops,(1-3)/20;custom_1,5/20,FAB387,bg,on
```

- `bg` = 渐变/纯色背景 · `tx` = 渐变文字 · `on|off` = 圆角开关（仅 bg）
- 颜色支持 `#` 前缀：`#FF0000,#00FF00`
- 兼容旧格式：`element:span,color`

- 全屏应用自动隐藏 · 全屏暂停选项（`PauseOnFullscreen=on`）
- 切换：`Ctrl + Alt + B` · 重新加载：`Alt + R`

---

### 🖼️ 窗口边框

为活跃、拖拽、置顶和受管理窗口显示视觉边框。

| 模式 | 用途 |
|------|------|
| **焦点边框** | 高亮当前活跃窗口 |
| **拖拽边框** | 拖拽/缩放时的视觉反馈 |
| **置顶边框** | 标记置顶窗口 |
| **全局边框** | 所有可见窗口显示边框 |

```ini
[Border]
Mode=full                  ; full | top
Thickness=15
RoundedCorners=on
Radius=10
; 边框颜色支持渐变：color1,color2,...
```
DragRadius=10
PinMode=top
```

---

### 🔤 WinSelect

字母标签叠加层，按对应字母键跳转到该窗口。窗口缩小叠加字母、侧边栏模式可配置位置、超时自动消失、退出时恢复置顶状态。

```ini
[WinSelect]
SidebarWidth=200
SidebarPosition=right     ; left | right
Timeout=3000
```

---

### ⌨️ WTM 模式

键盘驱动的动态平铺预览。激活时自动平铺，独立边框系统，桌面切换感知。

> ⚠️ **实验功能** — 默认未启用。

```ini
[WTM]
BorderMode=full
BorderFocusColor=A020F0
BorderThickness=8
Gap=10
```

启用：
```ini
[Hotkeys]
WTMToggle=Alt+Shift+D
```

---

### 📐 窗口吸附

拖拽和缩放时吸附到其他窗口边缘和屏幕边缘。

```ini
[Snapping]
SnapDistance=10
SnapReleaseDistance=20
```

---

### 💾 布局保存/恢复

快照并恢复所有窗口的位置、大小和状态。

| 操作 | 快捷键 |
|------|--------|
| 保存布局 | `Alt + Shift + S` |
| 恢复布局 | `Alt + Shift + R` |

---

### 🎨 主题

20+ 内置主题，即时切换。每个主题覆盖：背景、文字、强调色、任务色、边框、饼菜单、电源菜单、WTM 颜色。

```
nord · tokyonight · dracula · gruvbox · monokai
solarized-dark · solarized-light · catppuccin-mocha · catppuccin-latte
onedark · ayu-dark · github-dark · rose-pine · everforest
kanagawa · material-deep · nightfox · palenight · horizon · oxocarbon
```

通过托盘菜单或配置文件切换。`ExportThemeToCustom()` 导出当前主题。

---

### ⏱️ 工作计时器

状态栏进度条，显示当天工作进度。

```ini
[WorkTime]
Mode=off
WorkStart=0900
WorkEnd=1745
TaskTimes=1_1200_1300     ; 周一 12:00-13:00（午休）
```

按工作日分时段、周末进度条、百分比显示。

---

### 📋 剪贴板历史

监控剪贴板变化并记录到文件。内置查看器回顾历史内容。

```ini
[Paths]
ClipboardLog=%A_MyDocuments%\AHK_WM\clipboard.log
```

---

### 🔌 编辑器 & 终端

快速启动终端和编辑器。资源管理器集成 — 获取选中文件、当前路径。

```ini
[Paths]
Editor=C:\path\to\your\editor.exe
Terminal=wt.exe           ; Windows Terminal
```

---

### ⚡ 电源菜单及其他

**电源菜单**（`Alt + X`）：关机、休眠、重启。按钮颜色跟随主题。

其他功能：
- 🖱️ **系统托盘** — 右键切换主题、重载、退出
- 🛡️ **故障隔离** — `WMGuard()` 包裹所有操作为 try/catch
- 📝 **错误日志** — `WMLogErr()` 去重防止刷屏
- 🔄 **配置迁移** — `MigrateLegacyConfig()` 升级旧版配置
- 🔍 **透明度** — `Alt + 滚轮` 调节任意窗口
- 📌 **置顶** — `Alt + T`
- 🔇 **最小化** — 鼠标下方窗口
- 🖥️ **最大化** — 鼠标下方窗口

---

## ⚙️ 配置

单个 INI 文件：

```
%USERPROFILE%\.config\AHK_WM\wm_config.ini
```

| 段落 | 用途 |
|------|------|
| `[General]` | 核心行为、语言、启动 |
| `[Theme]` | 当前主题 |
| `[Paths]` | 编辑器、终端、剪贴板日志 |
| `[Desktop]` | 虚拟桌面设置、隐藏方式 |
| `[Bar]` | 状态栏高度、位置、透明度、自定义项 |
| `[Border]` | 边框模式、粗细、颜色、圆角 |
| `[Tiling]` | 间隙、布局规则、排除项 |
| `[WTM]` | 键盘平铺模式 |
| `[PieMenu]` | 饼菜单大小、透明度、菜单项 |
| `[GUI]` | 帮助窗口及界面偏好 |
| `[WorkTime]` | 工作时间、任务时段、进度条 |
| `[Exclude]` | 窗口排除（标题/类名/进程） |
| `[Hotkeys]` | 自定义快捷键 |
| `[Snapping]` | 吸附距离、释放距离 |
| `[WinSelect]` | 侧边栏位置、宽度、超时 |

> 💡 改完配置按 `Alt + R` 重载，无需重启。

---

## 🛠️ 更新日志

### v2.8.0 (2026-06-29)

- 🌈 **渐变色** — 状态栏元素、边框、电源菜单支持渐变背景和渐变文字
- 🔲 **状态栏圆角** — 逐元素 `on|off` 开关，bg 模式圆角控制
- 🎨 **状态栏布局重构** — 新格式 `N,element,span,colors,bg|tx,on|off`
- 🔧 **边框渐变** — `BorderDrag`/`BorderPin`/`BorderUnfocus` 支持逗号分隔渐变色
- ⚙️ **全屏暂停** — `PauseOnFullscreen=on` 游戏时自动暂停热键
- 🔍 **透明度步长** — 可配置步长，吸附到步长倍数
- 🧹 **代码清理** — 移除旧版迁移、旧 WTM 变量、冗余代码
- 🐛 **修复** — bg 圆角开关无效、单色渲染黑框、透明度最小值、帮助页/OSD 不跟随主题

### v2.6.4 (2026-06-18)

- 🆕 **配置完整性检查** — 每次启动自动对比模板，补充缺失键
- 🐛 **Pin 边框圆角** — 改为从配置读取
- 🔧 **DWM 补偿去重** — 提取为公共函数
| 3️⃣ | WinSelect 取消置顶 | `_RestoreAll()` 恢复后重新置顶 |
| 4️⃣ | 右下角拖拽像素偏移 | 补全 `frameDW`/`frameDH` 尺寸补偿 |
| 5️⃣ | 边框颜色与主题不搭 | `Border_Drag_Color` 统一为 `Color_Active` |
| 6️⃣ | 欢迎页被状态栏遮挡 | 强制 `WinSetAlwaysOnTop()` |

---

## 🔮 路线图

- **配置整理** — 清理两年积累的 INI 冗余
- **WTM 模式** — 边缘情况处理、崩溃恢复、多显示器改进
- **独立桌面切换** — 每个显示器独立切换桌面
- **包管理器** — Scoop、Chocolatey、winget 分发

---

## ❓ 常见问题

| 现象 | 解决 |
|------|------|
| 管理员窗口快捷键无效 | 以管理员身份运行脚本 |
| 饼菜单自定义不生效 | 安装 AHK v2（仅 exe 不够） |
| 游戏/UWP 行为异常 | 加入 `[Exclude]` 排除列表 |
| 全屏应用遮挡状态栏 | 设计如此，`Ctrl+Alt+B` 切换 |
| 边框偏移 | 调整 `Border` 粗细或半径 |
| 远程桌面异常 | RDP 下 DWM 变化，部分功能表现不同 |

---

## 🤝 参与贡献

- 🐛 **Bug 报告** — 提交 Issue，附复现步骤和 Windows 版本
- 💡 **功能建议** — 用 `enhancement` 标签提交
- 🔧 **Pull Request** — 欢迎，大改动请先开 Issue 讨论
- 🎨 **主题** — 附截图提交

---

## 📄 许可证

[MIT](LICENSE) © 2024-2026 EngineeringMechanicsB

---

## ⭐ Star 历史

[![Star History Chart](https://api.star-history.com/svg?repos=EngineeringMechanicsB/AHK_WM&type=Date)](https://star-history.com/#EngineeringMechanicsB/AHK_WM&Date)

---

<p align="center">
  <sub>用 AutoHotkey v2 打造 · 两年有余</sub>
</p>
