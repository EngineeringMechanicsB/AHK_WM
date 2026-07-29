# Changelog

### v2.10.1 (2026-07-29)

- 🆕 **Generate Theme from Wallpaper** — extract dominant colors from the desktop wallpaper via screen sampling and auto-generate a full theme palette; accessible from tray menu `Theme > Generate from Wallpaper`; generated theme stored in `wallpaper_theme.ini` without touching user's `[Theme]` config; switch back via `Theme > wallpaper (from image)`
- 🎨 **Theme color assignment** — intelligently maps wallpaper colors to theme roles: darkest → Background, lightest → Text, most frequent → Active, most vivid → BorderPin, hue-matched → PM buttons; all colors guaranteed distinct with automatic divergence
- 🔴 **Scan progress indicator** — real-time growing red bar shows sampling position during extraction; bar rendered below scan line to avoid contaminating samples
- 🖥️ **Sampling environment** — auto-hides status bar, minimizes all windows, hides desktop icons and taskbar during scan; restores everything on completion
- 🔗 **Color `#` prefix** — all config hex color values now use standard `#RRGGBB` format; backward-compatible reading strips `#` automatically
- 🔗 **Per-task color support** — `TaskTimes` config entries support color suffixes (e.g. `1_1200_1300,#ff0000,#00ff00`)

### v2.10.0 (2026-07-17)

- 🆕 **OSD per-call customization** — external scripts can override every visual setting (font size, opacity, position, colors, width, rounding, font face) per OSD call via `key=value` pairs appended to the payload; all keys optional, fall back to `[GUI]` config defaults
- 🆕 **OSD tag & instance isolation** — `tag=` key lets same-tag OSDs replace each other (no stacking); external OSDs run in a separate instance pool from internal `wm.ahk` OSDs, so the two never interfere
- 🆕 **Bar per-element `fs=` and `wrap=` attributes** — Layout elements can now set their own font size (`fs=14`) and line count (`wrap=2`); bar auto-grows when wrapped elements need more height
- 📚 **Bilingual example suite** — new `docs/Examples/OSDExamples/` (5 scripts) and `docs/Examples/BarExamples/` (3 scripts), each with `En/` and `Ch/` variants, heavily commented with full parameter documentation
- 📚 **New examples include**: lyrics reader with tag replacement, timed notification daemon, text-file paginator, dual-slot bar lyrics simulator, multi-line poetry display
- 🆕 **osd-timed-notify: `_*/N[xC]` interval-start suffix** — daily/weekly/once schedules can now take an interval suffix (e.g. `1200_*/30` = every 30 min from 12:00, `1400_*/20x3` = 3 times every 20 min from 14:00); interval only runs after the base time, resets at midnight
- 🛡️ **All example OSD helpers now use `SendMessageTimeoutW`** — 2s timeout + `SMTO_ABORTIFHUNG` prevents indefinite thread blocking when wm.ahk is busy; data copied into independent `Buffer` instead of `StrPtr` on a local variable
- 🐛 **Removed `Esc::ExitApp` from all example scripts** — Esc is bound by too many apps; all examples now rely on tray-menu exit
- 🧹 **Removed** `[WorkTime] NotificationRule` — timed notifications are now handled by a standalone script (`osd-timed-notify.ahk`), keeping wm.ahk lean

### v2.9.0 (2026-07-15)

- 🆕 **External bar widgets** — `external_N` on `[Bar] Layout`, push text from any AHK script via `WM_COPYDATA`; `bar-examples/` and `osd-examples/` with CN/EN demos
- 🆕 **Config key migration** — legacy `snake_case` auto-renamed to `PascalCase`; `CfgRead` with fallback chain
- 🆕 **UTF-8 config auto-repair** — `SanitizeConfigEncoding` detects and fixes corrupted INI files
- 🐛 **Config encoding fixed** — UTF-16 for all writes (AHK native), fixes Chinese/symbol garbled display
- 🐛 **WTM focus color** — borders toggle focus/unfocus correctly; `RefreshBorder` full rebuild + HWND verify loop
- 🐛 **WTM MoveDir** — Euclidean distance (same as FocusDir), up/down no longer erratic
- 🐛 **Move-to-desktop** — `DesktopFocus[target]` set on move, window inserted at top of Z-order
- 🐛 **Bar ghosting** — desktop cell HBITMAPs properly freed in `BarInstance.Destroy()`
- 🐛 **Font consistency** — PowerMenu and PieMenu now respect `FontName` config
- ⚡ **WTM responsiveness** — signature check every 10ms (was 150ms), stability delay 80ms
- 🧹 **Logging overhaul** — ms timestamps, dedup, rotation, session start/end banners, `OnExit` handler
- 🧹 **Self-test removed** — replaced by structured logging

### v2.8.5 (2026-07-10)

- 🐛 **GDI handle leak fixed** — `CreateGradient()` 1×1 seed bitmap was leaked on every call (up to 100/s during border drag); now properly freed
- 🐛 **Rapid desktop-switch race fixed** — `DesktopIsSwitching` flag guards `SwitchDesktop`, WTM/AllBorders ticks, `TogglePin`, `GatherAll`, and `SaveLayoutStateForReload`
- ⚡ **Bar polling optimized** — WiFi and disk info cached for 30 s, avoiding per-second `netsh` subprocess spawn and `DriveGetSpaceFree` I/O
- 🆕 **External OSD interface** — `WM_COPYDATA` receiver lets other scripts pop OSD messages
- 🧹 **Duplicate code extracted** — `_GetHwndUnderMouse`, `_RemoveFromAllDesktops`, `_GetTileMode`, `_BorderPlaceFrame`, `_BuildSysWidget` shared helpers
- 🧹 **UpdateClock table-driven** — `SysWidgets` array replaces 7 repeated if-blocks
- 🧹 **_BuildElements unified** — `WidgetMeta` Map + multi-value case fallthrough replaces 7 repeated cases
- 🎨 **Tiling edge gap fixed** — `Gap=0` now truly flush to screen edges

### v2.8.4 (2026-07-01)

- 🐛 **Clipboard fixed** — `RecordClipboard()` was missing `FileAppend`; history is now actually written to file
- 🐛 **Bar white edge fixed** — `RoundWindowEx` now disables DWM non-client rendering before `SetWindowRgn`
- 🐛 **ShowWin fixed** — `SW_SHOWNA(8)` → `SW_RESTORE(9)`; minimized windows now restore correctly
- 🐛 **Desktops white clipping** — layoutBg creation moved to `_BuildElements`
- 🆕 **Span alignment** — `+`/`-` sign controls both group positioning and text alignment
- 🧹 **GDI leak** — task-marker bitmaps now tracked and released on bar destroy
- ⚡ **Clipboard debounce** — 200ms filter suppresses rapid duplicate fires

### v2.8.0 (2026-06-29)

- 🌈 **Gradient colors** — bar elements, borders, and PowerMenu now support gradient backgrounds and gradient text
- 🔲 **Bar rounded corners** — per-element `on|off` switch for bg-mode rounded corners
- 🎨 **Bar layout overhaul** — new `N,element,span,colors,bg|tx,on|off` format
- 🔧 **Border gradient** — `BorderDrag`/`BorderPin`/`BorderUnfocus` support comma-separated gradient colors
- ⚙️ **Pause-on-fullscreen** — `[General] PauseOnFullscreen=on` suspends hotkeys when gaming
- 🔍 **Transparency step** — configurable step size, snap to multiples

### v2.6.4 (2026-06-18)

- 🆕 **Config integrity check** — auto-detect missing keys & add defaults on every startup
- 🐛 **Pin border rounding** — now reads from config
- 🔧 **DWM compensation** — extracted into shared function
