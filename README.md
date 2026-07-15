<div align="center">

# 🔲 AHK WM <sub>v2.9.0</sub>

<p>
  <img src="https://img.shields.io/badge/AutoHotkey-v2.0-cba6f7?style=flat-square" alt="AutoHotkey v2" />
  <img src="https://img.shields.io/badge/platform-Windows_7_~_11-b4befe?style=flat-square" alt="Platform" />
  <img src="https://img.shields.io/badge/license-MIT-f5c2e7?style=flat-square" alt="License" />
  <img src="https://img.shields.io/badge/release-v2.9.0-cba6f7?style=flat-square" alt="Release" />
</p>

<p>
  <a href="README.md"><img src="https://img.shields.io/badge/README-English-cba6f7?style=flat-square" alt="English" /></a>
  <a href="README-zh.md"><img src="https://img.shields.io/badge/README-简体中文-b4befe?style=flat-square" alt="简体中文" /></a>
</p>
**A tiny, fast, single-file window manager for Windows — powered by AutoHotkey v2.**

---

## 📑 Contents

- [✨ Features](#-features)
- [📸 Screenshots](#-screenshots)
- [📦 Installation](#-installation)
- [🚀 Quick Start](#-quick-start)
- [🧰 Detailed Features](#-detailed-features)
- [🔌 External Interfaces](#-external-interfaces)
- [⚙️ Configuration](#️-configuration)
- [🛠️ Changelog](CHANGELOG.md)
- [🔮 Roadmap](#-roadmap)
- [❓ Troubleshooting](#-troubleshooting)
- [🤝 Contributing](#-contributing)
- [📄 License](#-license)

---

## ✨ Features

|  |  |  |
|---|---|---|
| 🖥️ **9 Virtual Desktops** | Switch, move, gather via hotkeys | 🧩 **Smart Tiling** | One-key layout per monitor |
| 📊 **Status Bar** | Gradient, rounded, multi-monitor | 🎨 **20+ Themes** | Nord, Dracula, Catppuccin, etc. |
| 🥧 **Pie Menu** | Space + Right Mouse | ⌨️ **WTM Mode** | Hyprland-like keyboard tiling |
| ✋ **KDE-style Drag** | Alt + drag anywhere to move/resize | 🔤 **WinSelect** | Letter-labeled overlay for quick switching |
| 📋 **Clipboard History** | Built-in logger & viewer | 🔌 **External API** | OSD & bar widgets via WM_COPYDATA |
| ⏱️ **Work Timer** | Configurable progress bar | 📐 **Snapping** | Drag-to-snap, configurable thresholds |

> Two years of daily-use refinement. Built because every other Windows WM was too heavy and made my machine unusable for anyone else.

---

## 📸 Screenshots

| Preview | Description |
|---------|-------------|
| ![Screenshots](docs/images/Screenshots.png) | Desktop overview — borders, tiling, multi-window layout |
| ![Smart Tile](docs/images/Smart-tile.gif) | Smart Tiling — one key arranges all windows |
| ![Pie Menu](docs/images/pie-menu.gif) | Pie Menu — radial menu, Space + Right Mouse |
| ![WinSelect](docs/images/window-Select.gif) | WinSelect — letter-labeled overlay |
| ![Bar Widgets](docs/images/bar-widgets-2.png) | Status Bar — gradient widgets, rounded corners |
| ![Border Gradient](docs/images/border-gradient.png) | Gradient Borders — focus/unfocus with gradient colors |
| ![Border Fullscreen](docs/images/border-fullscreen.png) | Border in action — colored frames around tiled windows |
| ![Help](docs/images/help-menu.png) | Built-in Help — Alt + / for full hotkey reference |

---

## 📦 Installation

1. Install **AutoHotkey v2** → https://www.autohotkey.com/
2. Download `wm.ahk` from the [latest release](https://github.com/EngineeringMechanicsB/AHK_WM/releases/latest)
3. **Run as Administrator** (required for elevated windows)

<p align="center">
  <a href="https://github.com/EngineeringMechanicsB/AHK_WM/releases/latest">
    <img src="https://img.shields.io/badge/Download-Latest_Release-cba6f7?style=flat-square" alt="Download Latest Release" />
  </a>
</p>

> ⚠️ Pie menu customization and some advanced features require AHK v2. Running the `.ahk` script is recommended.

---

## 🚀 Quick Start

| Action | Hotkey |
|--------|--------|
| 📖 Help page | `Alt + /` |
| 🧩 Tile current monitor | `Alt + D` |
| ✋ Move window (anywhere) | `Alt + Left Mouse` |
| 📐 Resize window (anywhere) | `Alt + Right Mouse` |
| 🔄 Switch desktop 1~9 | `Alt + 1 ~ 9` |
| 📦 Move window to desktop | `Alt + Shift + 1 ~ 9` |
| 🚀 Move & follow to desktop | `Ctrl + Alt + 1 ~ 9` |
| 📊 Toggle status bar | `Ctrl + Alt + B` |
| ⌨️ WTM keyboard tiling | `Ctrl + Alt + T` |
| 💾 Save layout | `Alt + Shift + S` |
| 🧲 Gather all windows | `Alt + Shift + G` |
| 📌 Toggle always-on-top | `Alt + T` |
| 🔃 Reload script | `Alt + R` |
| 🥧 Pie menu | `Space + Right Mouse` |
| ⚡ Power menu | `Alt + X` |

---

## 🧰 Detailed Features

| Feature | Description |
|---------|-------------|
| 🖥️ **Virtual Desktops** | 9 independent desktops. Switch (`Alt+N`), move windows (`Alt+Shift+N`), or move-and-follow (`Ctrl+Alt+N`). Inactive-desktop windows can be minimized or hidden. |
| 🧩 **Smart Tiling** | One key tiles all windows on the current monitor. Custom layout rules per monitor with gap control. |
| ✋ **KDE-style Drag** | Move windows by holding `Alt` + dragging anywhere (not just the title bar). Resize with `Alt + Right Mouse`. |
| 🥧 **Pie Menu** | Hold `Space`, then right-click: a radial menu appears. Move the mouse in a direction to trigger that action. |
| 📊 **Status Bar** | Multi-monitor bar with gradient colors, rounded corners, and per-element alignment. Shows desktops, clock, date, progress, system stats, and custom widgets. |
| 🖼️ **Window Borders** | Colored borders around active/inactive windows with live gradient support. Toggle with `Ctrl+Alt+B`. |
| ⌨️ **WTM Mode** | Full keyboard window management: HJKL to move focus and swap windows, `Ctrl+HJKL` to resize, `Alt+HJKL` to snap. |
| 📐 **Window Snapping** | Drag windows to screen edges or other windows to snap. Configurable snap/release distances. |
| 🎨 **Themes** | 20+ built-in themes (Nord, Dracula, Catppuccin, Gruvbox, Tokyo Night, Monokai…). Export any theme to custom in one click. |
| ⏱️ **Work Timer** | Configurable work period with progress bar on the status bar. |
| 📋 **Clipboard History** | Logs all copied text to a file with timestamps. |
| ⚡ **Power Menu** | Shutdown / Sleep / Reboot menu with gradient buttons. |

---

## 🔌 External Interfaces

AHK_WM listens for `WM_COPYDATA` messages. External scripts can push text to the **status bar** or pop up **center-screen notifications**.

### OSD (on-screen display)

```ahk
; AHK_WM must be running
AHK_WM_OSD(text, duration := 1000) {
    DetectHiddenWindows(true)
    h := WinExist("wm.ahk ahk_class AutoHotkey")
    if !h
        return false
    payload := "OSD:" . text . ":" . duration
    c := StrPut(payload, "UTF-16")
    b := Buffer(A_PtrSize * 3, 0)
    NumPut("Ptr", 0, b, 0), NumPut("UInt", c, b, A_PtrSize), NumPut("Ptr", StrPtr(payload), b, A_PtrSize * 2)
    SendMessage(0x4A, 0, b.Ptr, , "ahk_id " . h)
    return true
}
AHK_WM_OSD("Build passed!", 3000)
```

### Bar custom widgets (`external_N`)

Add `external_N` to `[Bar] Layout`, then push text from any script:

```ahk
WMBarPush(slot, text) {
    DetectHiddenWindows(true), SetTitleMatchMode(2)
    target := WinExist("wm.ahk ahk_class AutoHotkey")
    if !target
        return false
    msg := "BAR:" . slot . ":" . text
    size := (StrLen(msg) + 1) * 2, buf := Buffer(size, 0)
    StrPut(msg, buf, "UTF-16")
    cds := Buffer(A_PtrSize * 3, 0)
    NumPut("Ptr", 0, cds, 0), NumPut("UInt", size, cds, A_PtrSize), NumPut("Ptr", buf.Ptr, cds, A_PtrSize * 2)
    res := 0
    DllCall("User32\SendMessageTimeoutW", "Ptr", target, "UInt", 0x4A, "Ptr", A_ScriptHwnd, "Ptr", cds.Ptr, "UInt", 0x2, "UInt", 2000, "UInt*", &res, "Ptr")
    return true
}
WMBarPush(1, "Hello from external script")
```

### Claude Code integration

Hook AHK_WM into Claude Code for completion notifications. Add to `.claude/settings.json`:

```json
{
  "hooks": {
    "Stop": [
      { "command": "C:\\Users\\Administrator\\Desktop\\AHK_WM\\osd-examples\\osd-claude-done.ahk" }
    ]
  }
}
```

Now every time Claude Code finishes, you'll see `🤖 Claude Code run Completed！`. The same pattern works with any tool that can run a `.ahk` file — task schedulers, CI pipelines, build scripts, whatever.

📂 `bar-examples/` and `osd-examples/` have 12 ready-to-run demos (Chinese / English, heavily commented).

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

- **WTM border cleanup** — eliminate border ghosting on window close / mode exit
- **Per-monitor desktops** — independent desktop switching per monitor
- **Package managers** — Scoop, Chocolatey, winget distribution
- **Config GUI** — graphical settings editor

---

## ❓ Troubleshooting

| Symptom | Fix |
|---------|-----|
| Hotkeys fail in admin windows | Run script as Administrator |
| Pie menu customization broken | Install AHK v2 (not just the .exe) |
| Games / UWP act strange | Add to `[Exclude]` |
| Status bar hidden by fullscreen | By design. Toggle with `Ctrl+Alt+B` |
| Borders look offset | Adjust `Border` thickness or radius |

---

## 🤝 Contributing

- 🐛 **Bug reports** — Open an issue with repro steps and Windows version
- 💡 **Feature requests** — Open an issue with the `enhancement` label
- 🔧 **Pull requests** — Welcome. For large changes, open an issue first.
- 🎨 **Themes** — Submit with a screenshot.

---

## 📄 License

[MIT](LICENSE) © 2024-2026 EngineeringMechanicsB
