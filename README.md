<div align="center">

# 🔲 AHK WM v2.6.1

🇬🇧 English · [🇨🇳 中文](README-zh.md)

</div>

---

A lightweight, fast, single-file window manager for Windows, powered by **AutoHotkey v2**.

Built for people who keep too many windows open and still want their desktop to feel light, predictable, and easy to escape from.

-  📄 **Single-file script** — zero dependency hell
-  ⚡ **Fast response** — no heavy background framework
-  🪟 **Windows 7 ~ 11** — works everywhere
-  🧹 **Low interference** — shared/work computer friendly
-  ⚙️ **Config-driven** — plug and play
-  🧩 Virtual desktops, smart tiling, KDE-style drag, pie menu, status bar, borders, GUI help page… the works

> I made this because most Windows window managers felt too heavy, too laggy, and would make my computer unusable for anyone else.
> This project has been written and used in real work for about two years.

---

### 📸 Screenshots

| Preview | Description |
|---------|-------------|
| ![Status Bar](/docs/images/status-bar.png) | **Status Bar** — desktop indicator, clock, date, progress bar, and custom text/emoji |
| ![Screenshots](/docs/images/Screenshots.png) | **Desktop Overview** — borders, tiling, and multi-window layout |
| ![Smart Tile](/docs/images/Smart-tile.gif) | **Smart Tiling** — one-key window arrangement |
| ![Pie Menu](/docs/images/pie-menu.gif) | **Pie Menu** — radial menu for quick actions |
| ![WinSelect](/docs/images/window-Select.gif) | **WinSelect Mode** — letter-labeled window picker |
| ![Help Menu](/docs/images/help-menu.png) | **Help Page** — built-in hotkey reference |

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

| Action | Hotkey |
|--------|--------|
| 📖 Show/hide help | `Alt + /` |
| 🧩 Smart tile current monitor | `Alt + D` |
| ✋ Move window | `Alt + Left Mouse` |
| 📐 Resize window | `Alt + Right Mouse` |
| 🔄 Switch desktop | `Alt + 1~9` |
| 📦 Move window to desktop | `Alt + Shift + 1~9` |
| 🚀 Move & switch desktop | `Ctrl + Alt + 1~9` |
| 📊 Toggle status bar | `Ctrl + Alt + B` |
| 💾 Save layout | `Alt + Shift + S` |
| 🔁 Restore layout | `Alt + Shift + R` |
| 📌 Gather all windows | `Alt + Shift + G` |
| ❌ Close window | `Alt + Q` |
| 🔄 Reload script | `Alt + R` |
| 🛑 Exit safely | `Alt + F12` |
| ⚡ Power menu | `Alt + X` |

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

| # | Issue | Fix |
|---|-------|-----|
| 1️⃣ | **Toggle OnTop full border had no rounded corners** 🟦 | `PinBorder.Tick()` hardcoded `radius=0` → now uses `Border_Rounded`/`Border_Radius` dynamically |
| 2️⃣ | **WinSelect letter bar wider than the window** 📏 | `_MakeLabel()` switched from `WinGetPos` to `GetWindowVisualRect()` for true visual width |
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

*Version 2.6.1 — 2026-06-15*
