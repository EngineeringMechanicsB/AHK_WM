# Changelog

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
