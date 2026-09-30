<div align="center">

# 🔲 AHK WM <sub>v2.11.0</sub>

<p>
  <img src="https://img.shields.io/badge/AutoHotkey-v2.0-cba6f7?style=flat-square" alt="AutoHotkey v2" />
  <img src="https://img.shields.io/badge/platform-Windows_7_~_11-b4befe?style=flat-square" alt="Platform" />
  <img src="https://img.shields.io/badge/license-MIT-f5c2e7?style=flat-square" alt="License" />
  <img src="https://img.shields.io/badge/version-v2.11.0-cba6f7?style=flat-square" alt="Version" />
</p>

<p>
  <a href="README.md"><img src="https://img.shields.io/badge/README-English-cba6f7?style=flat-square" alt="English" /></a>
  <a href="docs/README-zh.md"><img src="https://img.shields.io/badge/README-简体中文-b4befe?style=flat-square" alt="简体中文" /></a>
</p>

**A lightweight, fast, single-file window manager for Windows — powered by AutoHotkey v2**

</div>

<p align="center">
  <img src="docs/images/tagline.svg" alt="AHK WM tagline" width="85%">
</p>

<p align="center">
  <img src="docs/images/banner.png" alt="AHK WM Banner" width="90%">
</p>

---

## 📑 Contents

- [✨ Features](#-features)
- [📸 Screenshots](#-screenshots)
- [📦 Installation](#-installation)
- [🚀 Quick Start](#-quick-start)
- [🧰 Detailed Features](#-detailed-features)
- [🔌 External Interfaces](#-external-interfaces)
- [⚙️ Configuration](#️-configuration)
- [🛠️ Changelog](docs/CHANGELOG.md)
- [🔮 Roadmap](#-roadmap)
- [❓ Troubleshooting](#-troubleshooting)
- [🤝 Contributing](#-contributing)
- [📄 License](#-license)

---

## ✨ Features

|  |  |  |
|---|---|---|
| 🖥️ **Virtual Desktops** | Switch, move and gather windows by hotkey | 🧩 **Smart Tiling** | One key arranges every window |
| 📊 **Status Bar** | Gradients, rounded corners, multi-monitor | 🎨 **20+ Themes** | Nord, Dracula, Catppuccin, … |
| 🥧 **Pie Menu** | Space + Right Mouse | ⌨️ **WTM Mode** | Keyboard-driven tiling |
| ✋ **KDE-style Drag** | Alt + drag anywhere to move/resize | 🔤 **WinSelect** | Quick pick among stacked windows |
| 📋 **Clipboard History** | Built-in logging and viewer | 🔌 **External API** | OSD & bar widgets from other scripts |
| ⏱️ **Work Timer** | Configurable progress bar | 📐 **Snapping** | Drag-to-snap, configurable distances |

> Two years of daily-use polish, with as little interruption as possible.

<p align="center">
  <img src="docs/images/sep-tile.svg" alt="" width="85%">
</p>

---

## 📸 Screenshots

| Preview | Description |
|---------|-------------|
| ![Screenshots](docs/images/Screenshots.png) | Desktop overview — borders, tiling, multi-window layout |
| ![Smart Tile](docs/images/Smart-tile.gif) | Smart Tiling — one key arranges all windows |
| ![Pie Menu](docs/images/pie-menu.gif) | Pie Menu — Space + Right Mouse |
| ![WinSelect](docs/images/window-Select.gif) | WinSelect — quick pick among stacked windows |
| ![Bar Widgets](docs/images/bar-widgets-2.png) | Status Bar — gradient widgets, rounded corners |
| ![Border Gradient](docs/images/border-gradient.png) | Borders — highlight the window being dragged |
| ![Border Fullscreen](docs/images/border-fullscreen.png) | Gradient borders — any color frame you want |
| ![wtm mode](docs/images/wtm.gif) | WTM Mode — keyboard-driven tiling with fully customizable layouts and animation support |
| ![Help](docs/images/help-menu.png) | Built-in Help — check every hotkey at a glance |

---

<p align="center">
  <img src="docs/images/divider.svg" alt="divider" width="85%">
</p>

## 📦 Installation

1. Install **AutoHotkey v2** → https://www.autohotkey.com/
2. Download `wm.ahk` from the [latest release](https://github.com/EngineeringMechanicsB/AHK_WM/releases/latest)
3. **Run as Administrator** (otherwise elevated windows ignore it)

<p align="center">
  <a href="https://github.com/EngineeringMechanicsB/AHK_WM/releases/latest">
    <img src="https://img.shields.io/badge/Download-Latest_Release-cba6f7?style=flat-square" alt="Download Latest Release" />
  </a>
</p>

> ⚠️ The pie menu, external script calls and other advanced features need AHK v2. Installing AHK and running the `.ahk` script directly is recommended.

---

## 🚀 Quick Start

| Action | Hotkey |
|--------|--------|
| 📖 Help | `Alt + /` |
| 🧩 Tile current monitor | `Alt + D` |
| ✋ Drag to move a window | `Alt + Left Mouse` |
| 📐 Drag to resize a window | `Alt + Right Mouse` |
| 🔄 Switch desktop 1~9 | `Alt + 1 ~ 9` |
| 📦 Move window to desktop | `Alt + Shift + 1 ~ 9` |
| 🚀 Move and follow | `Ctrl + Alt + 1 ~ 9` |
| 📊 Toggle status bar | `Ctrl + Alt + B` |
| ⌨️ WTM mode (toggle) | `Alt + Shift + D` |
| ⌨️ WTM: move focus | `Alt + H / J / K / L` |
| ⌨️ WTM: swap windows | `Alt + Shift + H / J / K / L` |
| ⌨️ WTM: resize window | `Ctrl + Alt + H / J / K / L` |
| 💾 Save layout | `Alt + Shift + S` |
| 🧲 Gather all windows | `Alt + Shift + G` |
| 📌 Always on top | `Alt + T` |
| 🔃 Reload script | `Alt + R` |
| 🥧 Pie menu | `Space + Right Mouse` drag |
| ⚡ Power menu | `Alt + X` |

<p align="center">
  <img src="docs/images/sep-drag.svg" alt="" width="85%">
</p>

---

## 🧰 Detailed Features

| Feature | Description |
|---------|-------------|
| 🖥️ **Virtual Desktops** | Several independent desktops. Switch (`Alt+N`), move windows (`Alt+Shift+N`) or move and follow (`Ctrl+Alt+N`) with your own hotkeys. Windows on other desktops can be minimized or hidden. |
| 🧩 **Smart Tiling** | Arranges every window on the current monitor with one key. Custom per-monitor layout rules and gaps. |
| ✋ **KDE-style Drag** | Hold `Alt` and drag anywhere on a window to move it. `Alt + Right Mouse` drags to resize. |
| 🥧 **Pie Menu** | Hold `Space` and right-click: a radial menu appears. Move the mouse in a direction and release to trigger that action. |
| 📊 **Status Bar** | Multi-monitor status bar with gradients, rounded corners and per-element alignment. Shows desktop labels, time, date, progress bars, system stats and custom widgets — external scripts can push to it too. |
| 🖼️ **Window Borders** | Fully customizable colored window borders with gradient support. |
| ⌨️ **WTM Mode** | Entering it arranges every monitor by your rules; `Alt + H/J/K/L` moves focus, `Alt + Shift + H/J/K/L` moves the window, `Ctrl + Alt + H/J/K/L` resizes it. A fullscreen or maximized window suspends tiling on that monitor; `[Tiling] AnimationDuration` enables animated moves. |
| 📐 **Window Snapping** | Windows snap when dragged to screen edges or other windows. Configurable snap and release distances. |
| 🎨 **Themes** | 20+ built-in themes. Export the current theme as a custom palette in one click. |
| ⏱️ **Work Timer** | Configurable work periods, shown as a progress bar on the status bar. |
| 📋 **Clipboard History** | Records every copied text to a file, with timestamps. |
| ⚡ **Power Menu** | Shutdown / sleep / restart menu with gradient buttons. |

---

## 🔌 External Interfaces

AHK_WM listens for `WM_COPYDATA` messages, so other scripts can push text to the **status bar** or pop up a notification **on screen** — with full visual customization.

### OSD (on-screen display)

```ahk
; Basic — uses the config defaults
AHK_WM_OSD("Build passed!", 3000)

; Per-call overrides (every key is optional)
AHK_WM_OSD("Disk full!", 5000, "fs=36,bg=CC3333,tx=FFFFFF,op=95,pos=30")
```

**Available override keys** (full table in `docs/config-reference.md`):

| Key | Meaning | Default |
|-----|---------|---------|
| `fs` | Font size | Config `OSDFontSize` (20) |
| `op` | Opacity % | Config `OSDOpacity` (78) |
| `pos` | Vertical position % | Config `OSDPositionPct` (80) |
| `x` / `y` | Pixel/percentage coordinates | *(center / config)* |
| `bg` / `tx` | Background / text color | Theme colors |
| `wr` | Max width (auto-wrap) | 85% of screen width |
| `rd` / `rr` | Rounded corners on/off + radius | Config values |
| `fn` | Font face | Config `FontName` |
| `tag` | Logical label (same-tag OSDs replace each other) | *(none)* |

External OSDs run in a separate instance pool — they never interfere with
`wm.ahk`'s own internal OSD popups.

### Bar custom widgets (`external_N`)

Like OSD, the bar exposes an external interface — push content from any script:
```ahk
WMBarPush(1, "0.5/0.8", "Now Playing: Hey Jude — The Beatles")
WMBarPush(2, "(200-550)/1920", "Take a sad song`nand make it better")  ; `n = newline, renders as 2 lines
```

### Bundled examples

Ready-to-run examples are in `docs/Examples/OSDExamples/` and `docs/Examples/BarExamples/`,
each with English (`En/`) and Chinese (`Ch/`) variants, heavily commented with full parameter docs.

### Claude Code integration

```json
{
  "hooks": {
    "Stop": [
      { "command": "C:\\Users\\Administrator\\Desktop\\AHK_WM\\docs\\Examples\\OSDExamples\\En\\osd-simple.ahk" }
    ]
  }
}
```

A simple config lets Claude Code pop an OSD when it finishes — the same idea works for task schedulers, CI pipelines, Pomodoro timers, whatever.

📂 `docs/Examples/OSDExamples/` and `docs/Examples/BarExamples/` — several ready-to-run demos to learn from.

<p align="center">
  <img src="docs/images/sep-config.svg" alt="" width="85%">
</p>

---

## ⚙️ Configuration

<p align="center">
  <a href="docs/config-reference.md">
    <img src="https://img.shields.io/badge/Config_Reference-docs/config--reference.md-cba6f7?style=flat-square" alt="Config Reference" />
  </a>
</p>

All configuration lives in `%USERPROFILE%\.config\AHK_WM\wm_config.ini`. Edit it, then press `Alt + R` to reload — no restart needed.

---

## 🔮 Roadmap

- **Per-monitor desktops** — independent desktop switching per monitor
- **Package managers** — Scoop, Chocolatey, winget distribution
- **Window exclude rules** — current exclusion rules need improvement
- **Bar auto-hide & reveal** — currently only full hide; add occlusion-based auto-hide or transparency mode

---

## ❓ Troubleshooting

| Symptom | Fix |
|---------|-----|
| Hotkeys fail in admin windows | Run script as Administrator |
| Pie menu customization broken | Install AHK v2 (not just the .exe) |
| Borders look offset | Adjust `Border` thickness or radius |

---

## 🤝 Contributing

- 🐛 **Bug reports** — Open an issue with repro steps and Windows version
- 💡 **Feature requests** — Open an issue with the `enhancement` label
- 🔧 **Pull requests** — Welcome. For large changes, open an issue first.

---

<p align="center">
  <img src="docs/images/thanks.svg" alt="Thanks" width="75%">
</p>

## 📄 License

[MIT](LICENSE) © 2024-2026 EngineeringMechanicsB
