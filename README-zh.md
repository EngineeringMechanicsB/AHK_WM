<div align="center">

# 🔲 AHK WM <sub>v2.8.5</sub>

<p>
  <img src="https://img.shields.io/badge/AutoHotkey-v2.0-cba6f7?style=flat-square" alt="AutoHotkey v2" />
  <img src="https://img.shields.io/badge/平台-Windows_7_~_11-b4befe?style=flat-square" alt="平台" />
  <img src="https://img.shields.io/badge/许可-MIT-f5c2e7?style=flat-square" alt="许可" />
  <img src="https://img.shields.io/badge/版本-v2.8.5-cba6f7?style=flat-square" alt="版本" />
</p>

<p>
  <a href="README.md"><img src="https://img.shields.io/badge/README-English-cba6f7?style=flat-square" alt="English" /></a>
  <a href="README-zh.md"><img src="https://img.shields.io/badge/README-简体中文-b4befe?style=flat-square" alt="简体中文" /></a>
</p>

**轻量、快速、单文件的 Windows 窗口管理器 — AutoHotkey v2 驱动**

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
| ⚡ **飞快** | 无运行时框架 | 🖥️ **9 个虚拟桌面** | 快捷键切换/移动/收集 |
| 🖥️ **Win 7 ~ 11** | 兼容所有主流版本 | 🥧 **饼菜单** | `空格 + 右键` 触发 |
| 🧹 **低侵入** | 公用电脑也无妨 | 📊 **状态栏** | 渐变、圆角、多显示器 |
| ⚙️ **INI 配置** | 编辑即生效，无需重启 | 🎨 **20+ 主题** | Nord、Dracula、Catppuccin 等 |
| 🌈 **渐变色** | 状态栏、边框、电源菜单 | 📋 **剪贴板历史** | 内置记录与查看器 |

> 两年日常使用打磨。起因很简单：市面上的 Windows 窗口管理器都太复杂，别人根本没法用我的电脑。

---

## 📸 截图

| 预览 | 说明 |
|------|------|
| ![效果一览](docs/images/Screenshots.png) | **效果一览** — 边框、平铺、多窗口布局 |
| ![智能平铺](docs/images/Smart-tile.gif) | **智能平铺** — 一键排列当前显示器所有窗口 |
| ![饼菜单](docs/images/pie-menu.gif) | **饼菜单** — `空格 + 右键` 径向菜单 |
| ![窗口选择](docs/images/window-Select.gif) | **WinSelect** — 字母标签叠加，快速切换窗口 |
| ![状态栏](docs/images/status-bar.png) | **状态栏** — 桌面指示器、时钟、日期、进度条 |
| ![帮助页](docs/images/help-menu.png) | **内置帮助** — `Alt + /` 查看全部快捷键 |

### 🎨 状态栏部件（v2.8）

逐元素渐变背景（`bg`）、渐变文字（`tx`）、圆角开关，以及 **span 符号对齐** — 每个部件通过布局字符串独立配置样式。

<p align="center">
  <img src="docs/images/bar-widgets-2.png" alt="状态栏部件全景" width="95%" />
  <br/><em>渐变背景 + 圆角部件（桌面、日期、时间、进度、CPU、内存、磁盘）</em>
</p>

<p align="center">
  <img src="docs/images/bar-widgets-1.png" alt="状态栏部件细节" width="60%" />
  <br/><em>细节：渐变背景与当前桌面高亮圆角效果</em>
</p>

<p align="center">
  <img src="docs/images/bar-layout.png" alt="状态栏布局" width="80%" />
  <br/><em>布局配置效果</em>
</p>

<p align="center">
  <img src="docs/images/bar-config.png" alt="状态栏配置" width="80%" />
  <br/><em>配置格式：N,element,span,colors,bg|tx,on|off</em>
</p>

### 🌈 边框渐变（v2.8）

`BorderDrag`、`BorderPin`、`BorderUnfocus` 支持逗号分隔渐变色。

<p align="center">
  <img src="docs/images/border-gradient.png" alt="边框渐变" width="80%" />
  <br/><em>拖拽边框渐变</em>
</p>

<p align="center">
  <img src="docs/images/border-fullscreen.png" alt="边框全屏" width="80%" />
  <br/><em>边框渐变实机效果</em>
</p>

---

## 📦 安装

### 方式一：运行 `.ahk` 脚本 ⭐ 推荐

1. 安装 **AutoHotkey v2** → https://www.autohotkey.com/
2. 从[最新发布页](https://github.com/EngineeringMechanicsB/AHK_WM/releases/latest)下载 `wm.ahk`
3. **以管理员身份运行**（操作管理员窗口需要权限）

搞定。

### 方式二：编译版 `.exe`

直接运行，无需安装 AHK 即可使用基本功能。

<p align="center">
  <a href="https://github.com/EngineeringMechanicsB/AHK_WM/releases/latest">
    <img src="https://img.shields.io/badge/下载-最新版本-cba6f7?style=flat-square" alt="下载最新版本" />
  </a>
</p>

> ⚠️ 饼菜单自定义等高级功能需要 AHK v2。建议直接运行脚本。

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

> 💡 忘了快捷键？按 `Alt + /`，内置帮助页列出了全部。

---

## 🧰 详细功能

### 🖥️ 虚拟桌面

9 个桌面，各自独立追踪焦点窗口。

| 操作 | 快捷键 |
|------|--------|
| 切换到桌面 1~9 | `Alt + 1 ~ 9` |
| 移动窗口到其他桌面 | `Alt + Shift + 1 ~ 9` |
| 移动并跟随切换 | `Ctrl + Alt + 1 ~ 9` |
| 收集所有窗口到当前桌面 | `Alt + Shift + G` |

隐藏方式：**最小化** 或 **透明化**。可标记窗口跨桌面始终可见。

```ini
[Desktop]
HideMethod=minimize        ; minimize | transparency
```

---

### 🧩 智能平铺

一键排列当前显示器所有窗口。根据屏幕比例自动适配布局 — **标准屏** (16:9/16:10)、**竖屏**、**超宽屏** 各有独立规则。

默认快捷键：`Alt + D`

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
| `X` | 水平跨度 | `1` = 全宽, `a/b` = 第 a 段, `(a-c)/b` = a~c 段 |
| `Y` | 垂直跨度 | 同上 |

**排除窗口**（按标题/类名/进程）：
```ini
[Exclude]
Title=re:.*Steam.*;=Calculator
Class=AceApp
Process=devenv.exe;chrome.exe
```

`SetTileBound` / `ClearTileBound` 保护平铺边界。

---

### ✋ KDE 风格拖拽

从窗口任意位置拖拽移动或缩放，不用对准标题栏。

```
Alt + 左键  →  移动
Alt + 右键  →  缩放
```

DWM 边框差量补偿，像素级精准定位。

---

### 🥧 饼菜单

`空格 + 右键` 弹出 8 方向径向菜单。菜单项、透明度、字号、中心死区均可配置。

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

多显示器状态栏，比例布局，**支持渐变色、圆角和对齐控制**。显示虚拟桌面、时钟、日期、工作进度、系统状态和自定义文字/图标。

```ini
[Bar]
HeightPct=3
Opacity=78
MonitorIdx=1
position=top              ; top | bottom
```

**元素布局格式**（渐变 + 圆角 + 对齐）：

```ini
; N,element,span,colors,bg|tx,on|off
layout=1,time,20/20,ff0000,00ff00,tx;desktops,(1-3)/20,FAB387,A020F0,bg,on;cpu,14/-20
```

| 参数 | 取值 | 说明 |
|------|------|------|
| `N` | Bar 实例编号（默认 1） | 多栏时使用 |
| `element` | desktops, time, date, progress, wifi, bluetooth, battery, volume, disk, mem, cpu, custom_1..n | |
| `span` | `a/b`, `a/+b`, `a/-b`, `(a-c)/b`, `(a-c)/+b`, `(a-c)/-b` | **`+`=右对齐, `-`=左对齐, 无=居中** |
| `colors` | 一个或多个 6 位 hex 色值（逗号分隔） | 支持 `#` 前缀 |
| `mode` | `bg` = 彩色背景, `tx` = 渐变文字 | |
| `rounded` | `on` 或 `off` | 圆角开关（bg 模式） |

**Span 对齐** — `+`/`-` 符号同时控制标签组整体在 span 内的偏移和每个格子内的文字对齐：

- `(1-3)/20` → 标签组居中
- `(1-3)/+20` → 标签组靠右，文字右对齐
- `(1-3)/-20` → 标签组靠左，文字左对齐

**当前桌面高亮** — 设置 `current_desktop_color`，使用相同的 `colors,bg|tx,on|off` 格式，让当前桌面有独立的视觉高亮：

```ini
current_desktop_color=FAB387,A020F0,bg,on
```

**可用元素**：`desktops`、`time`、`date`、`progress`、`wifi`、`bluetooth`、`battery`、`volume`、`disk`、`mem`、`cpu`、`custom_1`..`custom_n`

- 颜色支持 `#` 前缀：`#FF0000,#00FF00`
- 兼容旧格式：`element:span,color`
- 全屏应用自动隐藏
- 全屏暂停选项（`[General] PauseOnFullscreen=on`）
- 切换：`Ctrl + Alt + B` · 重载：`Alt + R`

---

### 🖼️ 窗口边框

为活跃、拖拽、置顶和受管理窗口显示视觉边框 — 现已支持**渐变色**。

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

`BorderDrag`、`BorderPin`、`BorderUnfocus` 均支持逗号分隔渐变色。

---

### 🔤 WinSelect

字母标签叠加层，按对应字母键跳转到该窗口。窗口缩小并叠加字母标签、侧边栏模式可配位置、超时自动退出、退出时恢复置顶状态。

```ini
[WinSelect]
SidebarWidth=200
SidebarPosition=right     ; left | right
Timeout=3000
```

---

### ⌨️ WTM 模式

键盘驱动的动态平铺。激活时自动排列窗口，独立边框系统，桌面切换感知。

> ⚠️ **实验功能** — 默认未启用的热键。

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

20+ 内置主题，即时切换。每个主题覆盖：背景、文字、强调色、任务色、边框、饼菜单、电源菜单、WTM 等全部颜色。

```
nord · tokyonight · dracula · gruvbox · monokai
solarized-dark · solarized-light · catppuccin-mocha · catppuccin-latte
onedark · ayu-dark · github-dark · rose-pine · everforest
kanagawa · material-deep · nightfox · palenight · horizon · oxocarbon
```

通过托盘菜单或配置文件切换。`ExportThemeToCustom()` 可导出当前主题配色。

---

### ⏱️ 工作计时器

状态栏进度条，直观显示当天工作进度。

```ini
[WorkTime]
Mode=off
WorkStart=0900
WorkEnd=1745
TaskTimes=1_1200_1300     ; 周一 12:00-13:00（午休）
```

按工作日分时段标记、周末进度条可选、百分比显示。

---

### 📋 剪贴板历史

监控剪贴板变化并记录到文件。内置查看器，含 200ms 防抖避免重复记录。

```ini
[Paths]
OutputDir=C:\Users\...\Documents
OutputFile=CB.txt
```

---

### 🔌 编辑器 & 终端

快速启动终端和编辑器。资源管理器集成 — 获取选中文件、当前目录。

```ini
[Paths]
VimPath=C:\path\to\your\editor.exe
TerminalExe=wt.exe         ; Windows Terminal
```

---

### ⚡ 电源菜单及其他

**电源菜单**（`Alt + X`）：关机、休眠、重启。按钮颜色跟随主题。

其他功能：
- 🖱️ **系统托盘** — 右键切换主题、重载、安全退出
- 🛡️ **故障隔离** — `WMGuard()` 包裹所有操作为 try/catch
- 📝 **错误日志** — `WMLogErr()` 自动去重防刷屏
- 🔄 **配置自修复** — 每次启动自动补充缺失的配置键
- 🔍 **透明度调节** — `Alt + 滚轮` 调节任意窗口
- 📌 **置顶** — `Alt + T`
- 🔇 **最小化** — 鼠标下方窗口
- 🖥️ **最大化** — 鼠标下方窗口

### 🔔 外部 OSD 调用（v2.8.5）

其他 AHK 脚本可通过标准 `WM_COPYDATA` 消息向 AHK_WM 发送 OSD 提示。无需轮询、无需临时文件，一个函数调用即可。

复制下面这个函数到你的脚本：

```ahk
; 通过 AHK_WM 弹出 OSD 横幅。AHK_WM 需在运行中。
AHK_WM_OSD(text, duration := 1000) {
    DetectHiddenWindows(true)
    h := WinExist("wm.ahk ahk_class AutoHotkey")
    if !h
        return false
    payload := "OSD:" . text . ":" . duration
    c := StrPut(payload, "UTF-16")
    b := Buffer(A_PtrSize * 3, 0)
    NumPut("Ptr",  0,             b, 0)
    NumPut("UInt", c,             b, A_PtrSize)
    NumPut("Ptr",  StrPtr(payload), b, A_PtrSize * 2)
    SendMessage(0x4A, 0, b.Ptr, , "ahk_id " . h)
    return true
}

AHK_WM_OSD("编译完成！", 3000)
```

完整示例见 `wm_osd.ahk`。

---

## ⚙️ 配置

单个 INI 文件：

```
%USERPROFILE%\.config\AHK_WM\wm_config.ini
```

| 段落 | 用途 |
|------|------|
| `[General]` | 主题、字体、透明度步长、全屏暂停 |
| `[Theme]` | 所有颜色定义（均支持渐变） |
| `[Paths]` | 编辑器、终端、剪贴板日志路径 |
| `[Desktop]` | 虚拟桌面数量、隐藏方式 |
| `[Bar]` | 高度、透明度、布局、对齐、圆角 |
| `[Border]` | 模式、粗细、颜色、圆角 |
| `[Tiling]` | 间隙、自定义布局规则、排除项 |
| `[WTM]` | 键盘平铺模式设置 |
| `[PieMenu]` | 大小、透明度、字体 |
| `[GUI]` | 帮助窗口与 OSD 偏好 |
| `[WorkTime]` | 工作时间、任务时段、进度条 |
| `[Exclude]` | 窗口排除（标题/类名/进程） |
| `[Hotkeys]` | 所有快捷键绑定 |
| `[Snapping]` | 吸附距离、脱离距离 |
| `[WinSelect]` | 侧边栏位置、宽度、超时 |

> 💡 改完配置按 `Alt + R` 重载，无需重启脚本。

---

## 🛠️ 更新日志

### v2.8.5 (2026-07-10)

- 🐛 **修复 GDI 句柄泄漏** — `CreateGradient()` 中 1x1 种子位图每次泄漏，边框拖拽可达 100 次/秒；现正确释放
- 🐛 **修复快速切换桌面竞态** — `DesktopIsSwitching` 标志护卫 `SwitchDesktop`，WTM/AllBorders/TogglePin/GatherAll/SaveLayout 均加守卫，`try/finally` 确保标志不卡死
- ⚡ **Bar 系统轮询优化** — WiFi 和 Disk 信息添加 30 秒缓存，避免每秒 fork netsh/cmd 子进程和 `DriveGetSpaceFree` I/O
- 🆕 **OSD 外部接口** — `WM_COPYDATA` 接收器，其他脚本可调用弹出 OSD；附带 `wm_osd_helper.ahk` 辅助库 + `wm_osd_send.ahk` 独立发送器
- 🎨 **平铺边缘间隙修复** — `Gap=0` 时窗口紧贴屏幕边缘；DWM 补偿仅用于窗口间间距
- 🧹 **重复代码提取** — `_GetHwndUnderMouse`、`_RemoveFromAllDesktops`、`_GetTileMode`、`_BorderPlaceFrame`、`_BuildSysWidget` 等共享函数
- 🧹 **UpdateClock 数据表驱动** — `SysWidgets` 数组替代 7 个重复 if 块
- 🧹 **_BuildElements 统一** — `WidgetMeta` Map + 多值 case fallthrough 替代 7 个重复 case

### v2.8.4 (2026-07-01)

- 🐛 **修复剪贴板** — `RecordClipboard()` 缺少 `FileAppend`，历史记录现已正常写入文件
- 🐛 **修复 Bar 圆角白边** — `RoundWindowEx` 先禁用 DWM 非客户区渲染再执行 `SetWindowRgn`，消除 Win10 19041+ 右侧白色裁切
- 🐛 **修复 ShowWin** — `SW_SHOWNA(8)` → `SW_RESTORE(9)`，最小化窗口现在能正确还原
- 🐛 **修复 desktops 白色间隙** — layoutBg 改为在 `_BuildElements` 中创建（与其他部件时机一致），消除对齐导致的空白区域
- 🆕 **Span 对齐** — span 格式中的 `+`/`-` 符号现在同时控制标签组整体偏移和文字对齐
- 🆕 **高亮模式 tx 支持** — `tx` 模式现在正确渲染桌面标签
- 🧹 **GDI 泄漏** — 任务标记位图句柄追踪释放
- 🧹 **代码清理** — 移除旧版全局变量、删除重复 INI 解析、补充 `Persistent` 指令
- ⚡ **剪贴板防抖** — 200ms 防抖避免重复触发

### v2.8.0 (2026-06-29)

- 🌈 **渐变色** — 状态栏元素、边框、电源菜单全面支持渐变背景和渐变文字
- 🔲 **状态栏圆角** — 逐元素 `on|off` 开关，bg 模式独立圆角控制
- 🎨 **状态栏布局重构** — 新格式 `N,element,span,colors,bg|tx,on|off`，精细控制
- 🔧 **边框渐变** — `BorderDrag`/`BorderPin`/`BorderUnfocus` 支持逗号分隔渐变色
- ⚙️ **全屏暂停** — `PauseOnFullscreen=on` 游戏时自动暂停热键
- 🔍 **透明度步长** — 可配置步长，吸附到步长倍数
- 🧹 **代码清理** — 移除旧版迁移代码、旧 WTM 变量、冗余段落
- 🐛 **修复** — bg 圆角无效、单色渲染黑框、透明度最小值、帮助页/OSD 主题跟随

### v2.6.4 (2026-06-18)

- 🆕 **配置完整性检查** — 每次启动自动对比模板补充缺失键
- 🐛 **置顶边框圆角** — 改为从配置读取
- 🔧 **DWM 补偿去重** — 提取为公共函数

---

## 🔮 路线图

- **配置整理** — 清理两年积累的 INI 冗余项
- **WTM 模式** — 边界情况处理、崩溃恢复、多显示器改进
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
| 边框位置偏移 | 调整 `Border` 粗细或半径 |
| 远程桌面表现不同 | RDP 下 DWM 机制变化，部分功能受限 |

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

<a href="https://www.star-history.com/?repos=EngineeringMechanicsB%2FAHK_WM&type=date&legend=top-left">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/chart?repos=EngineeringMechanicsB/AHK_WM&type=date&theme=dark&legend=top-left&sealed_token=_J_8zskMe52yv6UIFPZ9OD2-uy6J9Mzlgd81FzHj4jpVS1DqGQSBxo6kVNN5ALPMk4TmOMjqPEWCKCWalWKuv85qPnLFMjuQfKUU_TX3ikOWo8aGeuaTVQzgHJo9meGUkj8y7NHv-Bh6CJRourXAF1mVgnYdagI_Rk0FfLJRGXvpk6g7GTGTeNHmD916" />
    <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/chart?repos=EngineeringMechanicsB/AHK_WM&type=date&legend=top-left&sealed_token=_J_8zskMe52yv6UIFPZ9OD2-uy6J9Mzlgd81FzHj4jpVS1DqGQSBxo6kVNN5ALPMk4TmOMjqPEWCKCWalWKuv85qPnLFMjuQfKUU_TX3ikOWo8aGeuaTVQzgHJo9meGUkj8y7NHv-Bh6CJRourXAF1mVgnYdagI_Rk0FfLJRGXvpk6g7GTGTeNHmD916" />
    <img alt="Star History Chart" src="https://api.star-history.com/chart?repos=EngineeringMechanicsB/AHK_WM&type=date&legend=top-left&sealed_token=_J_8zskMe52yv6UIFPZ9OD2-uy6J9Mzlgd81FzHj4jpVS1DqGQSBxo6kVNN5ALPMk4TmOMjqPEWCKCWalWKuv85qPnLFMjuQfKUU_TX3ikOWo8aGeuaTVQzgHJo9meGUkj8y7NHv-Bh6CJRourXAF1mVgnYdagI_Rk0FfLJRGXvpk6g7GTGTeNHmD916" />
  </picture>
</a>

---

<p align="center">
  <img src="https://capsule-render.vercel.app/api?type=waving&color=cba6f7&height=100&section=footer" width="100%" alt="footer" />
</p>

<p align="center">
  <sub>用 AutoHotkey v2 打造 · 两年有余</sub>
</p>
