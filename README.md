<div align="center">

# 🔲 AHK WM <sub>v2.6.4</sub>

<p>
  <img src="https://img.shields.io/badge/AutoHotkey-v2.0-brightgreen?style=flat-square" alt="AutoHotkey v2" />
  <img src="https://img.shields.io/badge/platform-Windows_7_~_11-blue?style=flat-square" alt="Platform" />
  <img src="https://img.shields.io/badge/license-MIT-brightgreen?style=flat-square" alt="License" />
  <img src="https://badgen.net/github/release/EngineeringMechanicsB/AHK_WM?icon=github" alt="Release" />
  <img src="https://badgen.net/github/stars/EngineeringMechanicsB/AHK_WM?icon=github" alt="Stars" />
  <img src="https://badgen.net/github/license/EngineeringMechanicsB/AHK_WM?icon=github" alt="License" />
</p>

<p>
  <a href="README.md"><img src="https://img.shields.io/badge/README-English-blue?style=for-the-badge" alt="English" /></a>
  <a href="README-zh.md"><img src="https://img.shields.io/badge/README-简体中文-red?style=for-the-badge" alt="简体中文" /></a>
</p>

**A tiny, fast, single-file window manager for Windows — powered by AutoHotkey v2.**

</div>

---

## 📑 Contents

- [✨ Features](#-features)
- [📸 Screenshots](#-screenshots)
- [📦 Installation](#-installation)
- [🚀 Quick Start](#-quick-start)
- [🧰 Detailed Features](#-detailed-features)
  - [🖥️ Virtual Desktops](#️-virtual-desktops)
  - [🧩 Smart Tiling](#-smart-tiling)
  - [✋ KDE-style Drag](#-kde-style-drag)
  - [🥧 Pie Menu](#-pie-menu)
  - [📊 Status Bar](#-status-bar)
  - [🖼️ Window Borders](#️-window-borders)
  - [🔤 WinSelect](#-winselect)
  - [⌨️ WTM Mode](#️-wtm-mode)
  - [📐 Window Snapping](#-window-snapping)
  - [💾 Layout Save/Restore](#-layout-saverestore)
  - [🎨 Themes](#-themes)
  - [⏱️ Work Timer](#️-work-timer)
  - [📋 Clipboard History](#-clipboard-history)
  - [🔌 Editor & Terminal](#-editor--terminal)
  - [⚡ Power Menu & More](#-power-menu--more)
- [⚙️ Configuration](#️-configuration)
- [🛠️ Changelog](#️-changelog)
- [🔮 Roadmap](#-roadmap)
- [❓ Troubleshooting](#-troubleshooting)
- [🤝 Contributing](#-contributing)
- [📄 License](#-license)
- [⭐ Star History](#-star-history)

---

## ✨ Features

|  |  |  |
|---|---|---|
| 📄 **Single file** | One `.ahk` script, no dependencies | 🧩 **Smart Tiling** | One-key layout per monitor |
| ⚡ **Fast** | No background framework | 🖥️ **9 Virtual Desktops** | Switch, move, gather via hotkeys |
| 🖥️ **Win 7 ~ 11** | All modern Windows versions | 🥧 **Pie Menu** | `Space + Right Mouse` |
| 🧹 **Low interference** | Shared-computer friendly | 📊 **Status Bar** | Desktop, clock, date, progress |
| ⚙️ **INI config** | Edit and reload on the fly | 🎨 **20+ Themes** | Nord, Dracula, Catppuccin, etc. |
| 🛡️ **Fault isolation** | Errors caught — won't crash | 📋 **Clipboard History** | Built-in logger & viewer |

> Built over two years of daily use because every other Windows WM felt too heavy and made my computer unusable for anyone else.

---

## 📸 Screenshots

| Preview | Description |
|---------|-------------|
| ![Screenshots](docs/images/Screenshots.png) | **Desktop Overview** — borders, tiling, multi-window layout |
| ![Smart Tile](docs/images/Smart-tile.gif) | **Smart Tiling** — one key arranges all windows on current monitor |
| ![Pie Menu](docs/images/pie-menu.gif) | **Pie Menu** — radial menu, `Space + Right Mouse` |
| ![WinSelect](docs/images/window-Select.gif) | **WinSelect** — letter-labeled overlay for quick switching |
| ![Status Bar](docs/images/status-bar.png) | **Status Bar** — desktop indicator, clock, date, progress bar |
| ![Help Page](docs/images/help-menu.png) | **Built-in Help** — `Alt + /` for full hotkey reference |

---

## 📦 Installation

### Option 1: Run the `.ahk` script ⭐ Recommended

1. Install **AutoHotkey v2** → https://www.autohotkey.com/
2. Download `wm_V2.6.4.ahk` from the [latest release](https://github.com/EngineeringMechanicsB/AHK_WM/releases/latest)
3. **Run as Administrator** (required for operations on elevated windows)

Done.

### Option 2: Compiled `.exe`

Run the pre-compiled executable — no AHK installation needed for basic use.

<p align="center">
  <a href="https://github.com/EngineeringMechanicsB/AHK_WM/releases/latest">
    <img src="https://img.shields.io/badge/Download-Latest_Release-blue?style=for-the-badge" alt="Download Latest Release" />
  </a>
</p>

> ⚠️ Pie menu customization and some advanced features require AHK v2. Running the script is recommended.

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
| 💾 Save layout | `Alt + Shift + S` |
| 🔁 Restore layout | `Alt + Shift + R` |
| 📌 Gather all windows | `Alt + Shift + G` |
| 🔍 Window transparency | `Alt + Mouse Wheel` |
| 📌 Toggle always-on-top | `Alt + T` |
| ❌ Close window under mouse | `Alt + Q` |
| 🔄 Reload script | `Alt + R` |
| 🛑 Safe exit | `Alt + F12` |
| ⚡ Power menu | `Alt + X` |
| 🥧 Pie menu | `Space + Right Mouse` |

> 💡 Press `Alt + /` anytime — the built-in help page lists every hotkey.

---

## 🧰 Detailed Features

### 🖥️ Virtual Desktops

9 desktops with independent focus tracking per desktop.

| Action | Hotkey |
|--------|--------|
| Switch to desktop 1~9 | `Alt + 1 ~ 9` |
| Move window to desktop | `Alt + Shift + 1 ~ 9` |
| Move window & follow | `Ctrl + Alt + 1 ~ 9` |
| Gather all windows here | `Alt + Shift + G` |

Hide method: **minimize** or **transparency**. Mark windows as always-visible across desktops.

```ini
[Desktop]
HideMethod=minimize        ; minimize | transparency
```

---

### 🧩 Smart Tiling

A single hotkey arranges all visible windows on the current monitor. Layouts adapt to monitor aspect ratio — **standard** (16:9/16:10), **vertical** (portrait), and **ultrawide** each get their own rules.

Default: `Alt + D`

```ini
[Tiling]
Gap=8
Rules=1,3,1,1/2,1;1,3,2,2/2,1/2;1,3,3,2/2,2/2;
```

**Rule format:** `M,N,I,X,Y`

| Field | Meaning | Example |
|-------|---------|---------|
| `M` | Monitor index (`*` = all) | `1` |
| `N` | Total windows on monitor | `3` |
| `I` | This window's index (1-based) | `2` |
| `X` | Horizontal span | `1` = full, `a/b` = segment a, `(a-c)/b` = segments a~c |
| `Y` | Vertical span | Same syntax |

**Exclude windows** by title, class, or process:
```ini
[Exclude]
Title=re:.*Steam.*;=Calculator
Class=AceApp
Process=devenv.exe;chrome.exe
```

Protected tiling boundaries via `SetTileBound` / `ClearTileBound`.

---

### ✋ KDE-style Drag

Move and resize from anywhere on the window — no need to grab the title bar.

```
Alt + Left Mouse  →  Move
Alt + Right Mouse →  Resize
```

DWM frame delta compensation for pixel-accurate positioning.

---

### 🥧 Pie Menu

8-direction radial menu on `Space + Right Mouse`. Items, opacity, font size, and center zone are all configurable.

```ini
[PieMenu]
SizePct=28
CenterZonePct=27
Opacity=78
FontSize=14
FontSizeActive=22
```

---

### 📊 Status Bar

Multi-monitor bar with proportional layout. Shows virtual desktops, clock, date, work progress, and custom text/emoji/icons.

```ini
[Bar]
HeightPct=3
Opacity=78
MonitorIdx=1
position=top              ; top | bottom
```

Custom items:
```ini
custom_items=text1;icon1;text2
layout=custom_1:1/10;custom_2:2/10;desktops:(1-3)/20
```

- Auto-hides when a fullscreen app is detected
- Toggle: `Ctrl + Alt + B`
- Rounded corners, per-monitor instances

---

### 🖼️ Window Borders

Visual borders for active, dragged, pinned, and managed windows.

| Mode | Purpose |
|------|---------|
| **Focus border** | Highlights the active window |
| **Drag border** | Visual feedback during move/resize |
| **Pin border** | Marks always-on-top windows |
| **All-window borders** | Borders on every visible window |

```ini
[Border]
DragMode=full             ; full = 4-sided | top = top strip only
DragThickness=15
DragRounded=on
DragRadius=10
PinMode=top
```

---

### 🔤 WinSelect

Letter-labeled overlay — press a key to jump to that window. Scales windows down, overlays letters. Sidebar mode with configurable position. Auto-dismiss on timeout. Restores always-on-top state on exit.

```ini
[WinSelect]
SidebarWidth=200
SidebarPosition=right     ; left | right
Timeout=3000
```

---

### ⌨️ WTM Mode

Keyboard-driven dynamic tiling preview. Auto-tiles on activation, has its own border system, desktop-switch aware.

> ⚠️ **Experimental** — hotkeys disabled by default.

```ini
[WTM]
BorderMode=full
BorderFocusColor=A020F0
BorderThickness=8
Gap=10
```

Enable it:
```ini
[Hotkeys]
WTMToggle=Alt+Shift+D
```

---

### 📐 Window Snapping

Edge snapping during move and resize — snaps to other window edges and screen edges.

```ini
[Snapping]
SnapDistance=10
SnapReleaseDistance=20
```

---

### 💾 Layout Save/Restore

Snapshot and restore all window positions, sizes, and states.

| Action | Hotkey |
|--------|--------|
| Save layout | `Alt + Shift + S` |
| Restore layout | `Alt + Shift + R` |

---

### 🎨 Themes

20+ built-in themes, instant hot-switching. Each defines: background, text, accent, task, border, pie menu, power menu, and WTM colors.

```
nord · tokyonight · dracula · gruvbox · monokai
solarized-dark · solarized-light · catppuccin-mocha · catppuccin-latte
onedark · ayu-dark · github-dark · rose-pine · everforest
kanagawa · material-deep · nightfox · palenight · horizon · oxocarbon
```

Switch from the system tray menu or config. Export current theme with `ExportThemeToCustom()`.

---

### ⏱️ Work Timer

Status bar progress bar showing how far through the workday you are.

```ini
[WorkTime]
Mode=off
WorkStart=0900
WorkEnd=1745
TaskTimes=1_1200_1300     ; Monday 12:00-13:00 (lunch)
```

Per-weekday task slots, weekend bar option, percentage display.

---

### 📋 Clipboard History

Monitors clipboard changes and logs them to file. Built-in viewer for reviewing past clips.

```ini
[Paths]
ClipboardLog=%A_MyDocuments%\AHK_WM\clipboard.log
```

---

### 🔌 Editor & Terminal

Quick-launch terminal and editor from anywhere. Explorer integration — get selected files, get current path.

```ini
[Paths]
Editor=C:\path\to\your\editor.exe
Terminal=wt.exe           ; Windows Terminal
```

---

### ⚡ Power Menu & More

**Power menu** (`Alt + X`): shutdown, sleep, reboot. Button colors follow the active theme.

Additional features:
- 🖱️ **System tray** — right-click for theme switch, reload, safe exit
- 🛡️ **Fault isolation** — `WMGuard()` wraps all operations in try/catch
- 📝 **Error logging** — `WMLogErr()` deduplicates repeated errors
- 🔄 **Config migration** — `MigrateLegacyConfig()` upgrades old configs
- 🔍 **Transparency** — `Alt + Mouse Wheel` on any window
- 📌 **Always-on-top** — `Alt + T`
- 🔇 **Minimize** window under mouse
- 🖥️ **Maximize** window under mouse

---

## ⚙️ Configuration

Single INI file:

```
%USERPROFILE%\.config\AHK_WM\wm_config.ini
```

| Section | Purpose |
|---------|---------|
| `[General]` | Core behavior, language, startup |
| `[Theme]` | Active theme |
| `[Paths]` | Editor, terminal, clipboard log |
| `[Desktop]` | Virtual desktop settings, hide method |
| `[Bar]` | Status bar height, position, opacity, custom items |
| `[Border]` | Border mode, thickness, colors, rounded corners |
| `[Tiling]` | Gap, layout rules, exclusions |
| `[WTM]` | Keyboard tiling mode settings |
| `[PieMenu]` | Pie menu size, opacity, items |
| `[GUI]` | Help window & GUI preferences |
| `[WorkTime]` | Work hours, task slots, progress bar |
| `[Exclude]` | Window exclusions (title/class/process) |
| `[Hotkeys]` | Custom keybindings |
| `[Snapping]` | Snap distance, release distance |
| `[WinSelect]` | Sidebar position, width, timeout |

> 💡 Edit config, press `Alt + R` to reload — no restart needed.

---

## 🛠️ Changelog

### v2.6.4 (2026-06-18)

- 🆕 **Config integrity check** — auto-detect missing keys & add defaults on every startup
- 🆕 **Encoding enforcement** — force UTF-16 LE on startup to prevent editor corruption
- 🐛 **Pin border rounding** — `Border_Pin_Rounded`/`Pin_Radius` now read from config
- 🔧 **DWM compensation** — extracted into shared `GetDWMGapCompensation()` function
- 🔧 **Template-based config** — default config template moved to module level for reuse

### v2.6.3 (2026-06-16)
- Updated compiled executables (64-bit & 32-bit)

### v2.6.2 (2026-06-15)

| # | Issue | Fix |
|---|-------|-----|
| 1️⃣ | Bar text vertical centering | Proper padding to avoid tall-glyph clipping |
| 2️⃣ | Tiling gap vs snapping mismatch | Auto DWM frame detection for visual zero-gap |
| 3️⃣ | WinSelect strips AlwaysOnTop | `_RestoreAll()` reapplies topmost for pinned windows |
| 4️⃣ | Bottom-right resize pixel offset | Full `frameDW`/`frameDH` compensation |
| 5️⃣ | Border colors mismatch theme | `Border_Drag_Color` unified with `Color_Active` |
| 6️⃣ | Welcome screen behind bar | Force `WinSetAlwaysOnTop()` after welcome GUI |

---

## 🔮 Roadmap

- **Config consolidation** — clean up two years of accumulated INI cruft
- **WTM mode** — edge cases, crash recovery, multi-monitor improvements
- **Per-monitor desktops** — independent desktop switching per monitor
- **Package managers** — Scoop, Chocolatey, winget distribution

---

## ❓ Troubleshooting

| Symptom | Fix |
|---------|-----|
| Hotkeys fail in admin windows | Run script as Administrator |
| Pie menu customization broken | Install AHK v2 (not just the .exe) |
| Games / UWP act strange | Add to `[Exclude]` |
| Status bar hidden by fullscreen | By design. Toggle with `Ctrl+Alt+B` |
| Borders look offset | Adjust `Border` thickness or radius |
| Remote Desktop issues | Some features differ over RDP (DWM changes) |

---

## 🤝 Contributing

- 🐛 **Bug reports** — Open an issue with repro steps and Windows version
- 💡 **Feature requests** — Open an issue with the `enhancement` label
- 🔧 **Pull requests** — Welcome. For large changes, open an issue first.
- 🎨 **Themes** — Submit with a screenshot.

---

## 📄 License

[MIT](LICENSE) © 2024-2026 EngineeringMechanicsB

---

## ⭐ Star History

[![Star History Chart](https://api.star-history.com/svg?repos=EngineeringMechanicsB/AHK_WM&type=Date)](https://star-history.com/#EngineeringMechanicsB/AHK_WM&Date)

---

<p align="center">
  <sub>Made with AutoHotkey v2 · Two years and counting</sub>
</p>
