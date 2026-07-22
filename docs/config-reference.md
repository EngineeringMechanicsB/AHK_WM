# AHK_WM Configuration Reference (v2.9.0)

Config file location: `%USERPROFILE%\.config\AHK_WM\wm_config.ini` (UTF-8).
The file is created with defaults on first run. After editing, reload the script
(default hotkey `Alt+R`, or tray → *Reload Script*).

**Value conventions**

| Notation | Meaning |
|---|---|
| `on\|off` | Boolean switch. `off`, `false`, `0` and empty count as off; anything else is on. |
| color | 6-digit hex `RRGGBB`, optional `#` prefix. Almost every color accepts a **gradient**: a comma-separated list, e.g. `A020F0,CBA6F7`. |
| span | Bar position expression: `a/b` (cell *a* of *b*), `(a-c)/b` (cells *a*..*c* of *b*). Prefix the divisor with `+` for right-align or `-` for left-align of the text inside the span: `20/+20`. `1` = full width. |
| % | Integer percentage 0–100. |

**v2.9 migration** — the `[Bar]` snake_case keys (`time_format`, `layout`, …) were
renamed to PascalCase. Old configs are migrated automatically on first start
(old key values are copied to the new names, old keys removed, and
`[General] ConfigVersion=2` is written). No manual action is required.

---

## [General]

| Key | Type | Default | Valid values | Description |
|---|---|---|---|---|
| `ActiveTheme` | string | `custom` | `custom`, `nord`, `tokyonight`, `dracula`, `gruvbox`, `monokai`, `solarized-dark`, `solarized-light`, `catppuccin-mocha`, `catppuccin-latte`, `onedark`, `ayu-dark`, `github-dark`, `rose-pine`, `everforest`, `kanagawa`, `material-deep`, `nightfox`, `palenight`, `horizon`, `oxocarbon` | Active color theme. `custom` uses the colors from `[Theme]`; any built-in name overrides them. |
| `FontName` | string | `Segoe UI` | any installed font | UI font. Use a Nerd Font to get bar icons (Wi-Fi, battery, …). |
| `TransparencyStep` | int | `10` | 1–50 | Step size (in %) for the window-transparency hotkeys. |
| `PauseOnFullscreen` | on/off | `off` | `on`, `off` | Suspend all script hotkeys while a fullscreen window is on a bar monitor. |
| `ConfigVersion` | int | *(auto)* | `2` | Internal migration marker written by the script. Do not edit. |

## [Theme]

All keys are colors and all accept gradients. Used only when `ActiveTheme=custom`
(built-in themes provide their own palette).

| Key | Default | Description |
|---|---|---|
| `Background` | `0e050f` | Base background for bar, menus, OSD. |
| `Text` | `e5e9f0` | Base text color. |
| `Active` | `744da9` | Accent color (active elements, OSD text, progress). |
| `Task` | `CF8DC9` | Work-timer task-marker color (optional key). |
| `BorderDrag` | `A020F0,CBA6F7` | Focused / drag border color (gradient supported). |
| `BorderPin` | `FF5555` | Always-on-top (pin) indicator color. |
| `BorderUnfocus` | `666666` | Unfocused window border color (WTM / All-Borders modes). |
| `PowerMenuBg` | `2E3440` | Power menu background. |
| `PowerBtnShutdown` | `B48EAD` | Shutdown button color. |
| `PowerBtnSleep` | `5E81AC` | Sleep button color. |
| `PowerBtnReboot` | `BF616A` | Reboot button color. |

## [Paths]

| Key | Type | Default | Description |
|---|---|---|---|
| `ButtonDir` | path | `Buttons` | Directory of the 8-direction pie-menu button scripts. Relative paths resolve against the script directory. |
| `OutputDir` | path | *(My Documents)* | Clipboard-history output directory. `%OUTPUTDIR%` expands to My Documents. |
| `OutputFile` | filename | `CB.txt` | Clipboard-history file name. Absolute paths are used as-is; otherwise relative to `OutputDir`. |
| `VimPath` | path | `C:\Windows\system32\notepad.exe` | Editor used for the clipboard-history viewer and "edit selected file". |
| `TerminalExe` | path | `C:\Windows\system32\cmd.exe` | Terminal launched by the terminal hotkey. |
| `EditorXPct` / `EditorYPct` | % | `20` / `0` | Editor window position, in percent of primary-screen size. |
| `EditorWidthPct` / `EditorHeightPct` | % | `52` / `74` | Editor window size, in percent of primary-screen size. |

## [Desktop]

| Key | Type | Default | Valid values | Description |
|---|---|---|---|---|
| `Count` | int | `9` | 1–9 | Number of virtual desktops. |
| `HideMethod` | string | `minimize` | `minimize`, `hide` | How windows on inactive desktops are put away. `hide` removes them from taskbar/Alt-Tab; `minimize` keeps them reachable. |

## [Bar]

| Key | Type | Default | Valid values | Description |
|---|---|---|---|---|
| `HeightPct` | int | `3` | 1–100 | Bar height in percent of screen height (auto-raised to fit the font). |
| `Opacity` | % | `78` | 0–100 | Bar opacity. |
| `FontSize` | int | `10` | ≥6 | Bar font size (pt). |
| `MonitorIdx` | int | `1` | 1–monitor count | Monitor for the default bar (when `Instances` is empty). |
| `TimeFormat` | string | `HH:mm` | AHK `FormatTime` pattern | Clock format. |
| `DateFormat` | string | `yyyy-MM-dd` | AHK `FormatTime` pattern | Date format. |
| `CustomItems` | list | `✐ Edit config to hide` | `;`-separated texts | Static texts for `custom_1..n` widgets. Use `\s` for a literal leading/trailing space, `\\` for a backslash. |
| `DesktopLabels` | list | `Work,Net` | `,`-separated names | Optional desktop names; desktops beyond the list show their number. |
| `CurrentDesktopLeft` / `CurrentDesktopRight` | string | `[` / `]` | any text | Markers around the current desktop label (`\s` = space). |
| `CurrentDesktopColor` | spec | *(empty)* | `color1,color2,…,bg\|tx,on\|off` | Highlight for the current desktop cell. Empty = plain bracket style. |
| `DesktopDisplayMode` | string | `all` | `all`, `current`, `occupied` | Which desktops appear in the desktops widget. |
| `Position` | string | `top` | `top`, `bottom` | Default bar edge. |
| `Offset` | int px | `0` | ≥0 | Gap between bar and screen edge. |
| `MarginLeft` / `MarginRight` | int px | `0` | ≥0 | Horizontal insets of the bar. |
| `Layout` | spec | *(see template)* | see below | Bar element layout — the heart of the bar. |
| `Instances` | spec | `1,top,0` | `M,pos,offset;…` (`M` = monitor index or `*`) | Multiple bar instances. Empty = one bar on `MonitorIdx`. |
| `AutoHideOnFullscreen` | on/off | `on` | `on`, `off` | Hide the bar while a fullscreen window is on its monitor. |
| `Rounded` | on/off | `on` | `on`, `off` | Rounded bar corners. |
| `CornerRadius` | int px | `10` | ≥0 | Bar corner radius. |
| `CornerMode` | string | `bottom` | `all`, `top`, `bottom` | Which corners are rounded. |

### Layout format

```
Layout=[N,]element,span[,color1,color2,…][,bg|tx][,on|off][,fs=N][,wrap=N]; …
```

- `N` — bar number (matches the order in `Instances`), default `1`.
- `element` — one of: `desktops`, `time`, `date`, `progress`, `wifi`, `battery`,
  `volume`, `disk`, `mem`, `cpu`, `custom_1..n`, `external_1..n`.
- colors — 6-hex values; one color = plain colored text, two or more = gradient.
- `bg` — gradient becomes the widget **background** (text is punched out in the
  bar color); `tx` (default) — gradient is applied to the **text**.
- `on|off` — rounded corners for `bg` mode.
- `fs=N` — per-element font size in points (default: global `Bar_FontSize`).
- `wrap=N` — maximum display lines for this element (default: `0` = single line).
  When `wrap ≥ 2` the bar auto-grows to fit.  Text with embedded newlines (`` `n ``)
  renders as separate lines; long lines auto-wrap at word boundaries.
- Legacy `element:span,color,…` syntax is still accepted.

`external_N` widgets can be created in two ways:

**Self-contained** (v2.11+): `BAR:N:lo/hi:text:key=val` — position, colors, font
all passed in the push. No Layout declaration needed. Keys: `bg`, `tx`, `rd`,
`rr`, `fs`, `wrap`.  Example: `BAR:1:0.5/0.8:Hello:bg=7AA2F7,fs=14`

**Legacy**: `BAR:N:text` — requires `external_N` in Layout (see above).
A single push persists until the next push or a bar reload.
See the bundled examples in `docs/Examples/BarExamples/` and `docs/Examples/OSDExamples/`.

## [Border]

Pixel-ish values (`Thickness`, `Offset`, `OffsetTop`, pin variants) are expressed
on a 0–100 scale that maps to 0–20 px.

| Key | Type | Default | Valid values | Description |
|---|---|---|---|---|
| `RefreshMs` | int ms | `10` | ≥1 | Border/tick timer interval. Raise to 15–20 on weak machines; borders now skip unchanged frames automatically. |
| `Enable` | on/off | `on` | `on`, `off` | Show the drag border during drag-move/resize. |
| `Mode` | string | `full` | `top`, `full` | Border style: full frame or top strip. |
| `Thickness` | 0–100 | `35` | 0–100 → 0–20 px | Border thickness. |
| `Offset` | 0–100 | `15` | 0–100 → 0–20 px | Outward offset from the window. |
| `OffsetTop` | 0–100 | `5` | 0–100 → 0–20 px | Extra offset at the top edge. |
| `Opacity` | % | `80` | 0–100 | Border opacity. |
| `RoundedCorners` | on/off | `on` | `on`, `off` | Rounded border corners. |
| `Radius` | int px | `10` | ≥0 | Border corner radius. |
| `CornerMode` | string | `all` | — | **Reserved** — currently not applied to borders. |
| `Gap` | int px | `10` | any | WTM tiling gap (space reserved between tiled windows for borders). |
| `SizeStep` | int | `3` | ≥1 | **Reserved** — WTM resize step for a future resize hotkey. |
| `PinMode` | string | `top` | `top`, `full` | Pin (always-on-top) indicator style. |
| `PinThickness` | 0–100 | `35` | 0–100 → 0–20 px | Pin indicator thickness. |
| `PinOffset` / `PinOffsetTop` | 0–100 | `0` / `5` | 0–100 → 0–20 px | Pin indicator offsets. |
| `PinOpacity` | % | `90` | 0–100 | Pin indicator opacity. |
| `PinRounded` | on/off | `off` | `on`, `off` | Rounded pin indicator. |
| `PinRadius` | int px | `0` | ≥0 | Pin indicator radius. |

Border **colors** live in `[Theme]`: `BorderDrag` (focused), `BorderUnfocus`
(unfocused), `BorderPin` (pinned). All support gradients; WTM uses
`BorderDrag`/`BorderUnfocus` for its focused/unfocused window borders.

## [Tiling]

| Key | Type | Default | Valid values | Description |
|---|---|---|---|---|
| `Gap` | int px | `15` | any (may be negative) | Gap between windows for Smart Tile and WinSelect tiling. |
| `TileAlwaysOnTop` | on/off | `off` | `on`, `off` | Include always-on-top windows when tiling. |
| `Rules` | spec | *(see template)* | `M,N,I,X,Y;…` | Custom layout rules, used by Smart Tile **and** WTM (user rules take priority). `M` = monitor (`*` = any), `N` = total window count the rule applies to, `I` = window index (1..N), `X`/`Y` = span expressions (`1` = full, `a/b`, `(a-c)/b`). A rule group is used only when complete (every `I` from 1..N present exactly once). |

## [Snapping]

| Key | Type | Default | Valid values | Description |
|---|---|---|---|---|
| `Enable` | on/off | `on` | `on`, `off` | Edge snapping during drag-move/resize. |
| `Distance` | int px | `0` | ≥0 | Snap trigger distance (gap kept from the snap line). |
| `Release` | int px | `5` | ≥0 | Extra distance needed to break away from a snap line. |

## [PieMenu]

| Key | Type | Default | Valid values | Description |
|---|---|---|---|---|
| `SizePct` | % | `28` | 1–100 | Pie diameter in percent of the shorter screen side. |
| `CenterZonePct` | % | `27` | 0–100 | Dead-zone radius (percent of pie radius) that cancels the action. |
| `Opacity` | % | `78` | 0–100 | Pie opacity. |
| `FontSize` | int | `14` | ≥6 | Sector label size. |
| `FontSizeActive` | int | `22` | ≥6 | Highlighted sector label size. |

## [GUI]

| Key | Type | Default | Valid values | Description |
|---|---|---|---|---|
| `RoundedCorners` | on/off | `on` | `on`, `off` | Global rounded corners for script GUIs. |
| `CornerRadius` | int px | `12` | ≥0 | Global corner radius. |
| `HelpFontSize` | int | `10` | ≥6 | Help window font size. |
| `HelpWidth` | int px | `620` | ≥200 | Help window width. |
| `HelpHeight` | int px | `0` | 0 = auto | Help window height. |
| `HelpOpacity` | % | `100` | 0–100 | Help window opacity. |
| `PowerFontSize` | int | `12` | ≥6 | Power menu font size. |
| `PowerWidth` / `PowerHeight` | int px | `500` / `160` | ≥100 | Power menu size. |
| `PowerOpacity` | % | `100` | 0–100 | Power menu opacity. |
| `OSDPositionPct` | % | `80` | 0–100 | OSD vertical position (percent of screen height). |
| `OSDOpacity` | % | `78` | 0–100 | OSD opacity. |
| `OSDFontSize` | int | `20` | ≥6 | OSD font size. |
| `HelpRounded`, `HelpRadius`, `PowerRounded`, `PowerRadius`, `OSDRounded`, `OSDRadius` | — | *(global)* | — | Optional per-GUI overrides of the two global rounding keys. |

### OSD per-call customization (WM_COPYDATA)

External scripts can override all OSD visual settings per call by appending
`key=value` pairs to the payload:

```
OSD:text[:duration_ms][:fs=24,op=90,x=50%,y=30%,bg=FF4444,tx=FFFFFF]
```

| Key | Type | Default | Description |
|---|---|---|---|
| `fs` | int pt | `OSDFontSize` (20) | Font size. |
| `op` | %  | `OSDOpacity` (78) | Opacity. |
| `pos` | %  | `OSDPositionPct` (80) | Vertical position (0=top, 100=bottom). |
| `x` | px/% | *(center)* | Horizontal pos: `300` = 300px, `50%` = half screen. |
| `y` | px/% | *(pos/config)* | Vertical pos: `200` = 200px, `30%` = screen height %. |
| `bg` | 6-hex | theme `Color_Bg` | Background color. |
| `tx` | 6-hex | theme `Color_Active` | Text color. |
| `wr` | int px | `monW × 0.85` | Max width; text auto-wraps when exceeded. |
| `rd` | on/off | `OSDRounded` | Rounded corners. |
| `rr` | int px | `OSDRadius` | Corner radius. |
| `fn` | name | `FontName` | Font face. |
| `tag` | string | *(none)* | Logical label. A new OSD with the same `tag` replaces the previous one (same-tag OSDs don't stack). Without a tag, each OSD is an independent instance. |

All keys are optional — unspecified keys fall back to the `[GUI]` config values.
Existing scripts that don't pass opts continue to work unchanged.

**Instance isolation:** External OSDs (via `WM_COPYDATA`) and internal OSDs
(called by `wm.ahk` itself) run in separate instance pools.  Internal OSDs
replace each other (single instance); external OSDs are independent unless
grouped by `tag`.  Neither side interferes with the other.

## [WorkTime]

| Key | Type | Default | Valid values | Description |
|---|---|---|---|---|
| `Mode` | string | `off` | `off`, `workday`, `allday` | Work-timer mode for the bar progress widget. `off` = progress spans the whole day. |
| `WeekendBar` | on/off | `off` | `on`, `off` | Show work progress on weekends. |
| `WorkStart` / `WorkEnd` | HHMM | `0900` / `1745` | 0000–2359 | Working hours. |
| `TaskTimes` | spec | *(see template)* | `W_HHMM_HHMM[,color…];…` | Task markers above the progress bar. `W` = weekday (1=Mon … 7=Sun). Colors optional (gradient supported); default is the theme task color. Overlapping tasks are drawn on a second row. |

## [Exclude]

Windows matching any rule are ignored by tiling, borders and WinSelect.

| Key | Type | Default | Description |
|---|---|---|---|
| `Titles` | list | `Picture-in-Picture` | `;`-separated title rules: plain text = *contains*; `=text` = exact match; `re:pattern` = regular expression. |
| `Classes` | list | *(empty)* | `;`-separated window classes (exact, case-insensitive). |
| `Processes` | list | *(empty)* | `;`-separated process names (exact, case-insensitive), e.g. `mpv.exe`. |

## [WinSelect]

| Key | Type | Default | Valid values | Description |
|---|---|---|---|---|
| `ScaleRatio` | float | `0.85` | 0.2–1.0 | Shrink factor applied to tiled windows during selection. |
| `Letters` | string | `ASDFGHJKLQWERTYUIOPZXCVBNM` | A–Z | Letter pool for labels, in assignment order. |
| `SizeMap` | spec | `1:0.5;2:0.8;3:1.2;9:1920x1080` | `N:ratio` or `N:WxH;…` | Pressing digit `N` before a letter resizes the chosen window (ratio 0.05–10, or absolute size). |
| `BarColor` / `TextColor` | color | *(theme)* | color | Label bar colors; empty = theme background / accent. |
| `Height` | int px | `28` | ≥16 | Label bar height. |
| `Width` | int px | `0` | 0 = window width | Label bar width. |
| `OffsetY` | int px | `0` | any | Label bar vertical offset from the window. |
| `FontSize` | int | `14` | ≥6 | Label font size. |
| `Opacity` | % | `85` | 0–100 | Label opacity. |
| `Rounded` | on/off | `on` | `on`, `off` | Rounded label corners. |
| `CornerRadius` | int px | `10` | ≥0 | Label corner radius. |
| `CornerMode` | string | `top` | `all`, `top`, `bottom` | Which label corners are rounded. |
| `Timeout` | int s | `12` | 0 = never | Auto-exit after this many idle seconds. |

## [WinSelectSidebar]

Sidebar listing locked windows that live on other desktops.

| Key | Type | Default | Valid values | Description |
|---|---|---|---|---|
| `FontSize` | int | `14` | ≥8 | Sidebar font size. |
| `Width` | int px | `80` | ≥50 | Sidebar width. |
| `Position` | string | `left` | `left`, `right` | Screen side. |
| `OffsetX` / `OffsetY` | int px | `10` / `0` | any | Sidebar offsets. |

## [Clipboard] *(new in v2.9)*

Clipboard capture is system-wide: it fires for **every** copy method
(Ctrl+C, context menu, Edit menu, programmatic copies).

| Key | Type | Default | Valid values | Description |
|---|---|---|---|---|
| `MaxChars` | int | `100000` | 0 = unlimited | Text entries longer than this are truncated in the history file (a truncation note is appended and logged). |
| `ExcludeProcesses` | list | *(empty)* | `;`-separated exe names | Copies made while one of these processes owns the active window are not recorded — e.g. `KeePass.exe;1Password.exe`. |
| `LogBinary` | on/off | `on` | `on`, `off` | Record non-text clipboard content: file copies log the file paths; images log the content type (image data itself is never saved). |

## [Logging] *(new in v2.9)*

Structured log: `timestamp.ms  [LEVEL]  [Component]  message`. Repeated
identical messages are deduplicated with a running count. The log file is
appended across script reloads.

| Key | Type | Default | Valid values | Description |
|---|---|---|---|---|
| `File` | path | *(empty)* | any path | Log file. Empty = `<config dir>\wm.log`. |
| `Level` | string | `INFO` | `DEBUG`, `INFO`, `WARN`, `ERROR` | Minimum level written. |
| `MaxSizeKB` | int KB | `512` | 0 = never | When the log exceeds this size it is rotated to `<file>.old` (one generation kept). |

## [Hotkeys]

Natural syntax: modifier names joined by `+` — `Alt`, `Shift`, `Ctrl`, `Win` —
plus a key name, e.g. `Ctrl+Alt+T`. Raw AHK modifier syntax (`^!t`) is also
accepted. **An empty value disables that hotkey.** The three `*Prefix` keys take
modifiers only and are combined with digits `1–9`.

| Key | Default | Action |
|---|---|---|
| `Help` | `Alt+/` | Show / hide the help window. |
| `Exit` | `Alt+F12` | Restore all windows and exit. |
| `Reload` | `Alt+R` | Reload the script (desktop layout preserved). |
| `DesktopSwitchPrefix` | `Alt` | + `1–9`: switch desktop. |
| `DesktopMovePrefix` | `Alt+Shift` | + `1–9`: move active window to desktop. |
| `DesktopMoveSwitchPrefix` | `Ctrl+Alt` | + `1–9`: move window and follow it (window is raised on arrival). |
| `TileSmart` | `Alt+D` | Smart-tile the monitor under the mouse. |
| `GatherAll` | `Alt+Shift+G` | Gather every window onto the current desktop. |
| `TogglePin` | `Ctrl+Alt+T` | Toggle "always visible on every desktop". |
| `ToggleBar` | `Ctrl+Alt+B` | Show / hide the bar. |
| `SaveLayout` / `RestoreLayout` | `Alt+Shift+S` / `Alt+Shift+R` | Save / restore a window-position snapshot. |
| `CloseWindow` | `Alt+Q` | Close window (under mouse; **focused** window in WTM mode). |
| `CloseWindowAlt` | `Alt+MButton` | Same as `CloseWindow`. |
| `ToggleMaximize` | `Alt+F` | Maximize / restore window under mouse. |
| `ToggleTop` | `Alt+T` | Toggle always-on-top (WTM: float + exclude the focused window). |
| `HideWindow` | `Alt+W` | Minimize window under mouse. |
| `ToggleAllBorders` | *(empty)* | Toggle borders on all windows. |
| `TransparencyUp` / `TransparencyDown` | `Alt+WheelUp` / `Alt+WheelDown` | Adjust window transparency. |
| `SnapLeft` / `SnapRight` | `Alt+Left` / `Alt+Right` | Snap window to the left / right half. |
| `SnapUp` / `SnapDown` | `Alt+Up` / `Alt+Down` | Maximize / minimize. |
| `LaunchTerminal` | `Alt+Enter` | Open the terminal (in the Explorer folder if one is active). |
| `EditFile` | `Alt+V` | Open the selected Explorer file in the editor. |
| `PowerMenu` | `Alt+X` | Show the power menu. |
| `ClipboardHistory` | ``Ctrl+` `` | Toggle the clipboard-history viewer. |
| `DragMove` | `Alt+LButton` | Drag-move with snapping. |
| `DragResize` | `Alt+RButton` | Drag-resize with snapping. |
| `PieMenuTrigger` | `~Space & RButton` | Open the pie menu. |
| `WinSelect` | `Alt+S` | Window-select mode. |
| `WTMToggle` | *(empty; suggested `Alt+Shift+D`)* | Toggle WTM tiling mode. |
| `WTMFocusLeft/Down/Up/Right` | `Alt+H/J/K/L` | WTM: focus in a direction. |
| `WTMMoveLeft/Down/Up/Right` | `Alt+Shift+H/J/K/L` | WTM: swap / move in a direction (crosses monitors). |

---

## External interfaces (WM_COPYDATA)

Send a `WM_COPYDATA` message to the hidden main window
(`wm.ahk ahk_class AutoHotkey`, with hidden-window detection on):

| Payload | Effect |
|---|---|
| `OSD:text[:duration_ms]` | Show an OSD popup using config defaults. |
| `OSD:text[:duration_ms]:fs=N,op=N,…` | Show an OSD with per-call visual overrides (see [GUI] → OSD per-call customization above). |
| `BAR:N:text` | (Legacy) Set content of `external_N` bar widget. |
| `BAR:N:lo/hi:text:key=val,…` | (v2.11+) Self-contained bar push — position, colors, font, wrap all in one call. |

Bundled example scripts live in `docs/Examples/OSDExamples/` (OSD popups) and
`docs/Examples/BarExamples/` (bar widgets), each with English (`En/`) and
Chinese (`Ch/`) variants.  Every script includes a ready-to-copy helper
function with full parameter documentation.

## Self-test

Tray menu → **Run Self-Test** exercises config parsing, INI round-trip, themes,
GDI gradients, border frames, bar instances, virtual-desktop structures, the
hotkey table, clipboard capture (snapshot & restore), logging and the external
bar interface, then shows a PASS/FAIL/SKIP report and writes details to the log.
It never moves, closes or modifies real windows; checks that would are SKIPped
by design.
