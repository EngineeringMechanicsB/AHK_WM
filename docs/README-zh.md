<div align="center">

# 🔲 AHK WM <sub>v2.10.1</sub>

<p>
  <img src="https://img.shields.io/badge/AutoHotkey-v2.0-cba6f7?style=flat-square" alt="AutoHotkey v2" />
  <img src="https://img.shields.io/badge/平台-Windows_7_~_11-b4befe?style=flat-square" alt="平台" />
  <img src="https://img.shields.io/badge/许可-MIT-f5c2e7?style=flat-square" alt="许可" />
  <img src="https://img.shields.io/badge/版本-v2.10.1-cba6f7?style=flat-square" alt="版本" />
</p>

<p>
  <a href="../README.md"><img src="https://img.shields.io/badge/README-English-cba6f7?style=flat-square" alt="English" /></a>
  <a href="docs/README-zh.md"><img src="https://img.shields.io/badge/README-简体中文-b4befe?style=flat-square" alt="简体中文" /></a>
</p>

**轻量、快速、单文件的 Windows 窗口管理器 — AutoHotkey v2 驱动**

</div>

<p align="center">
  <img src="images/tagline-zh.svg" alt="AHK WM 标语" width="85%">
</p>

<p align="center">
  <img src="images/banner.png" alt="AHK WM Banner" width="90%">
</p>

---

## 📑 目录

- [✨ 功能概览](#-功能概览)
- [📸 截图](#-截图)
- [📦 安装](#-安装)
- [🚀 快速上手](#-快速上手)
- [🧰 详细功能](#-详细功能)
- [🔌 外部接口](#-外部接口)
- [⚙️ 配置](#️-配置)
- [🛠️ 更新日志](CHANGELOG-zh.md)
- [🔮 路线图](#-路线图)
- [❓ 常见问题](#-常见问题)
- [🤝 参与贡献](#-参与贡献)
- [📄 许可](#-许可)

---

## ✨ 功能概览

|  |  |  |
|---|---|---|
| 🖥️ **虚拟桌面** | 快捷键切换、移动、收集窗口 | 🧩 **智能平铺** |
| 📊 **状态栏** | 渐变、圆角、多显示器 | 🎨 **20+ 主题** |
| 🥧 **饼菜单** | 空格 + 右键 | ⌨️ **WTM 模式** |
| ✋ **KDE 风格拖拽** | Alt + 任意位置拖拽移动/缩放 | 🔤 **WinSelect** |
| 📋 **剪贴板历史** | 内置记录和查看 | 🔌 **外部接口** |
| ⏱️ **工作计时** | 可配置的进度条 | 📐 **吸附** |

> 两年日常使用打磨，尽可能减少干扰。

<p align="center">
  <img src="images/sep-tile.svg" alt="" width="85%">
</p>

---

## 📸 截图

| 预览 | 说明 |
|---------|-------------|
| ![Screenshots](images/Screenshots.png) | 桌面概览 — 边框、平铺、多窗口布局 |
| ![Smart Tile](images/Smart-tile.gif) | 智能平铺 — 一键排布所有窗口 |
| ![Pie Menu](images/pie-menu.gif) | 饼菜单 — 空格 + 右键 |
| ![WinSelect](images/window-Select.gif) | WinSelect — 快速选择堆叠窗口 |
| ![Bar Widgets](images/bar-widgets-2.png) | 状态栏 — 渐变部件、圆角 |
| ![Border Gradient](images/border-gradient.png) | 边框 — 高亮标识拖拽窗口 |
| ![Border Fullscreen](images/border-fullscreen.png) | 渐变边框 — 自定义您想要的彩色边框 |
| ![Help](images/help-menu.png) | 内置帮助 —迅速查看所有快捷键 |

---

<p align="center">
  <img src="images/divider-zh.svg" alt="分隔线" width="85%">
</p>

## 📦 安装

1. 安装 **AutoHotkey v2** → https://www.autohotkey.com/
2. 下载 `wm.ahk`：[最新版本](https://github.com/EngineeringMechanicsB/AHK_WM/releases/latest)
3. **以管理员身份运行**（否则对管理员窗口无效）

<p align="center">
  <a href="https://github.com/EngineeringMechanicsB/AHK_WM/releases/latest">
    <img src="https://img.shields.io/badge/下载-最新版本-cba6f7?style=flat-square" alt="下载最新版本" />
  </a>
</p>

> ⚠️ 饼菜单运行以及外部脚本调用等高级功能需要 AHK v2。推荐安装AHK后直接运行 `.ahk` 脚本。

---

## 🚀 快速上手

| 操作 | 快捷键 |
|--------|--------|
| 📖 帮助 | `Alt + /` |
| 🧩 平铺当前显示器 | `Alt + D` |
| ✋ 拖拽移动窗口 | `Alt + 鼠标左键` |
| 📐 拖拽缩放窗口 | `Alt + 鼠标右键` |
| 🔄 切换桌面 1~9 | `Alt + 1 ~ 9` |
| 📦 移动窗口到桌面 | `Alt + Shift + 1 ~ 9` |
| 🚀 移动并跟随 | `Ctrl + Alt + 1 ~ 9` |
| 📊 开关状态栏 | `Ctrl + Alt + B` |
| ⌨️ WTM 键盘平铺 | `Ctrl + Alt + T` |
| 💾 保存布局 | `Alt + Shift + S` |
| 🧲 收集所有窗口 | `Alt + Shift + G` |
| 📌 窗口置顶 | `Alt + T` |
| 🔃 重载脚本 | `Alt + R` |
| 🥧 饼菜单 | `空格 + 鼠标右键`拖拽 |
| ⚡ 电源菜单 | `Alt + X` |

<p align="center">
  <img src="images/sep-drag.svg" alt="" width="85%">
</p>

---

## 🧰 详细功能

| 功能 | 说明 |
|---------|-------------|
| 🖥️ **虚拟桌面** | 多个独立桌面，可通过自定义快捷键切换（`Alt+N`）、移动窗口（`Alt+Shift+N`）或带窗口切换（`Ctrl+Alt+N`）。非当前桌面窗口可最小化或隐藏。 |
| 🧩 **智能平铺** | 一键铺满当前显示器。支持按显示器自定义布局规则和间距。 |
| ✋ **KDE 风格拖拽** | 按住 `Alt` 在窗口任意位置拖拽即可移动。`Alt + 右键` 拖拽缩放。 |
| 🥧 **饼菜单** | 按住 `空格`，点右键出现径向菜单，朝不同方向移动鼠标释放后触发对应操作。 |
| 📊 **状态栏** | 多显示器状态栏，支持渐变色、圆角、每个元素独立对齐。显示桌面标签、时间、日期、进度条、系统状态等自定义部件，甚至支持外部脚本调用。 |
| 🖼️ **窗口边框** | 完全可自定义彩色窗口边框，支持渐变。 |
| 📐 **窗口吸附** | 拖拽窗口到屏幕边缘或其他窗口时自动吸附，可配置吸附距离和脱离距离。 |
| 🎨 **主题** | 20+ 内置主题，一键导出当前主题为自定义配色。 |
| ⏱️ **工作计时** | 可配置的工作时段，状态栏显示进度条。 |
| 📋 **剪贴板历史** | 自动记录所有复制文本到文件，带时间戳。 |
| ⚡ **电源菜单** | 关机 / 休眠 / 重启菜单，渐变按钮。 |

---

## 🔌 外部接口

AHK_WM 监听 `WM_COPYDATA` 消息，外部脚本可以向**状态栏**推送文本或在**屏幕**弹出通知——并支持完整的视觉自定义。

### OSD（屏幕提示）

```ahk
; 基础用法 — 使用配置文件默认值
AHK_WM_OSD("编译完成！", 3000)

; 逐次覆盖外观（所有键可选，未指定则回退配置文件值）
AHK_WM_OSD("磁盘满了！", 5000, "fs=36,bg=CC3333,tx=FFFFFF,op=95,pos=30")
```

**可用覆盖键**（完整表格见 `docs/config-reference-zh.md`）：

| 键 | 含义 | 默认值 |
|---|---|---|
| `fs` | 字体大小 | 配置 `OSDFontSize` (20) |
| `op` | 不透明度 % | 配置 `OSDOpacity` (78) |
| `pos` | 垂直位置 % | 配置 `OSDPositionPct` (80) |
| `x` / `y` | 像素/百分比坐标 | *(居中 / 配置)* |
| `bg` / `tx` | 背景色 / 文字色 | 主题颜色 |
| `wr` | 最大宽度（自动换行）| 屏幕宽 × 0.85 |
| `rd` / `rr` | 圆角开关 + 半径 | 配置值 |
| `fn` | 字体名称 | 配置 `FontName` |
| `tag` | 逻辑标签（同标签新 OSD 替换旧 OSD）| *(无)* |

外部 OSD 运行在独立实例池，与 `wm.ahk` 自身的内部 OSD 互不干扰。

### Bar 自定义部件（`external_N`）

Bar和OSD一样留下了外部接口，可以从其他脚本推送内容：
```ahk
WMBarPush(1, "0.5/0.8", "正在播放：Hey Jude — The Beatles")
WMBarPush(2, (200-550)/1920， "Take a sad song`nand make it better")  ; `n = 换行符，渲染为两行
```

### 随附示例

开箱即用的示例脚本位于 `docs/Examples/OSDExamples/` 和 `docs/Examples/BarExamples/`，
每种均提供英文（`En/`）和中文（`Ch/`）双语版本，注释详尽含完整参数文档。

### Claude Code 集成

```json
{
  "hooks": {
    "Stop": [
      { "command": "C:\\Users\\Administrator\\Desktop\\AHK_WM\\docs\\Examples\\OSDExamples\\Ch\\osd-simple.ahk" }
    ]
  }
}
```

通过简单的配置，即可让Claude Code每次运行完成后弹出运行完成的提示，同样的思路可以拓展很多用法——任务计划、CI 流水线、番茄钟都行。

📂 `docs/Examples/OSDExamples/`和 `docs/Examples/BarExamples/`— 多个开箱即用的示例脚本，可以参考学习。

<p align="center">
  <img src="images/sep-config.svg" alt="" width="85%">
</p>

---

## ⚙️ 配置

<p align="center">
  <a href="config-reference-zh.md">
    <img src="https://img.shields.io/badge/配置参考-docs/config--reference--zh.md-cba6f7?style=flat-square" alt="配置参考" />
  </a>
</p>

所有配置在 `%USERPROFILE%\.config\AHK_WM\wm_config.ini` 中。编辑后按 `Alt + R` 重载即可，无需重启。

---

## 🔮 路线图

- **WTM 模式** — 现阶段的WTM模式问题非常多
- **多显示器独立桌面** — 每显示器独立切换桌面
- **包管理器** — Scoop、Chocolatey、winget 分发
- **窗口排除规则** — 现阶段的窗口排除规则不完善
- **BAR自动隐藏和显示** — 现在仅仅是全盘隐藏，添加一个遮挡自动隐藏或者降低透明度模式

---

## ❓ 常见问题

| 现象 | 解决 |
|------|------|
| 管理员窗口快捷键无效 | 以管理员身份运行脚本 |
| 饼菜单自定义不生效 | 安装 AHK v2（仅 exe 不够） |
| 边框偏移 | 调整 `Border` 粗细或圆角 |

---

## 🤝 参与贡献

- 🐛 **Bug 报告** — 提交 Issue，附重现步骤和 Windows 版本
- 💡 **功能建议** — 提交带 `enhancement` 标签的 Issue
- 🔧 **Pull Request** — 欢迎。大改动请先开 Issue 讨论。

---

<p align="center">
  <img src="images/thanks-zh.svg" alt="致谢" width="75%">
</p>

## 📄 许可

[MIT](LICENSE) © 2024-2026 EngineeringMechanicsB
