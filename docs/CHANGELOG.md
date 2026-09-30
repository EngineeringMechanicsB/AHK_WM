# Changelog

### v2.11.0 follow-ups (2026-09-30)

- **Entering WTM no longer rearranges the screen** — the mode used to rebuild the layout from its own window order, so a monitor you had just tiled with `Alt+D` came back looking different (window contents typically permuted). Entering now measures every window, normalises its centre and looks up the slot it already sits in (`SlotAssign`), so each window keeps the slot it had; only windows that cannot be matched (newly opened, dragged away) go into the remaining free slots, ordered by row band and then by x. Geometry still comes from `[Tiling] Rules` (built-in algorithm when a monitor has none) plus `[Tiling] WTMGap`, so entering WTM is "the same layout, with the WTM gap", and toggling it is idempotent. A maximized window is never taken as evidence of an existing layout (its rect is the whole monitor)
- **Adjacent tiles no longer overlap by one pixel** — `ComputeTileRect` rounded `x` and `w` (or `y` and `h`) independently, so a tile's right edge was `Round(x)+Round(w)` while its neighbour's left edge was `Round(x+w)`, and the two could differ by 1 px: at 1906×991 (column width 476.5) columns 2 and 3 really did overlap. The directional funnel requires a candidate to lie **entirely** past the focused slot, so that overlap read as "the neighbour is pressing on me, it hasn't fully crossed" and the key skipped it for a farther slot (in the log, `2 →` picked 4, `3 ←` picked 1, `6 →` 8, `7 ←` 5). Shared edges are now rounded as coordinates, so neighbouring tiles are an exact partition
- **The WTM gap no longer grows on every toggle** — a short-lived "inherit the measured proportions" path fed the on-screen rects back in as slot boundaries, and since those rects already contain the previous gap, every toggle added another layer (10 → 20 → 30 px). That inheritance is gone: entering the mode only decides *which window goes into which slot*
- **Test harness moved to `docs/tools/`** — `mk_testslots.sh` / `run_testslots.sh` / `validate.sh` / `probe_pick.ahk` / `check_borders.ps1` now live under `docs/`, and the assertions grew from 128 to 170: a new scenario at 1906×991 (a tiling area that does not divide evenly) reproduces the old 1-px overlap and pins the eight directional picks from the log, and a new seeding scenario covers slot matching, the fallback for a displaced window, the maximized-window guard and the idempotence of repeated toggling

### v2.11.0 (2026-09-29)

- **Focus movement and window swapping now share one rule** — `Alt+H/J/K/L` used to go through `_PickNeighbor` (pixel Euclidean distance between window-rect centres) while `Alt+Shift+H/J/K/L` used the slot-table three-step funnel, so the same monitor and the same direction could resolve to two different neighbours: in the 10-window layout (`|1|2|3|4|` / `|5|6|7|8|` / `|9|10|`) focus on slot 7 pressed right swapped with 8 but *focused* 10 on the third row (10's centre is nearer on x). Both now go through `_PickSwapTarget` → `PickSlotFromTable`; the pixel picker is kept only as a cross-monitor fallback when no same-monitor target exists and more than one monitor is attached
- **"Same band" now checks real overlap first** — `NarrowByBand` used to compare interval gaps only, so "merely touching" and "fully overlapping" both scored 0 and tied: in the 10-window layout, slot 9 (left half of `|9|10|`) pressed right skipped the 10 directly to its right and went to 7 on the row above. Candidates whose span **overlaps** the focused span on the cross axis (truly the same line) are now kept first; only when none overlap does it fall back to comparing gaps
- **Directional picks are logged** — every `Alt+H/J/K/L` / `Alt+Shift+H/J/K/L` writes one line `WTM focus R #7 -> #8 n10 from 0.625/0.499 to 0.875/0.499` (slot numbers are the on-screen left-to-right, top-to-bottom numbering), or `-> none` when nothing is picked; with `[Tiling] WTMDebug=on` the whole slot table's centre coordinates are dumped alongside, so a key's result can be checked against the numbers visible on screen
- **Resizing no longer leaks into tiling outside WTM** — a resized layout is now stored in a WTM-session-only map (`WTM_ResizeRules` guarded by `WTM_LayoutOverride`), read only by layout lookups made while WTM is on; leaving WTM (`Alt+Shift+D` off) drops it immediately and flushes the slot-table cache, so `Alt+D` (Smart Tile) goes back to the configured `[Tiling] Rules`. Resizing used to write straight into the global `LayoutRules`, which kept that monitor's altered proportions after WTM was switched off (only a script reload restored them) and also shadowed the monitor's rules from the config file
- **Directional pick now looks at "the same band" first** — the three-step funnel is reordered to ① smallest cross-axis interval gap (prefer windows on the same horizontal/vertical line) ② the movement axis must lie entirely past the focused slot ③ smallest movement-axis centre delta; when no window in that band lies in the requested direction it falls back to the old "direction first, then smallest band gap", so every key still lands somewhere. With that fallback the two orders are mathematically equivalent (`B∩D ≠ ∅` forces the smallest band gap *within* D to equal the global one, giving the same set; when empty the fallback runs the old order literally) — `docs/tools/probe_pick.ahk` compares both over 24000 random 2-D guillotine layouts with diff=0, and the four expected tables plus every built-in layout assertion are unchanged

- **WTM rebuilt on a fractional slot model** — WTM no longer computes layouts of its own: entering the mode calls the same entry point Smart Tile uses (`TileWindowsOnMonitor`), preferring `[Tiling] Rules` and falling back to the built-in algorithm. Each window's placement on each monitor is expressed as normalized fractional spans `{xlo,xhi,ylo,yhi,cx,cy,xfull,yfull}`, and every move/swap is pure math on that slot table — no pixel reads
- **Directional move/swap (Hyprland-style)** — `Alt+Shift+H/J/K/L` swaps the focused window with its neighbour in that direction, picked by a **three-step funnel**: ① cross axis — smallest interval gap (overlapping or touching = 0, i.e. "on the same horizontal/vertical line") ② movement axis — a candidate must lie **entirely past** the focused slot (spans may not overlap, so same-column/row slots and any spanning window covering the focused one are out) ③ movement axis — smallest centre delta. As soon as a step leaves a single candidate it is swapped in and the later steps are skipped. If a tie survives all three, the smallest cross-axis centre delta wins, then the negative one (upper/left). A window spanning a full axis (`0..1`) cannot move along it and falls through to the cross-monitor branch
- **WTM resize (new)** — `Ctrl+Alt+H/J/K/L` resizes the focused window along X/Y (`[Tiling] ResizeStep`, default 20 px, is split over both edges, so total width/height changes by 20 px). What moves is the **whole boundary line**: every edge sitting at that coordinate shifts with it, whichever side of the line it is on and whichever row/column it belongs to — in the 2×2 layout (`|1|3|` / `|2|4|`) growing window 1 also drags window 2's right and window 4's left edge, so the bottom row cannot split open and columns/rows stay aligned. The space is taken from / handed to the windows on that line, no window is ever squeezed below the minimum size (`2 × ResizeStep`, floor 80 px), and when shrinking, a line with nobody to hand the space to does not move (so shrinking against the screen edge leaves no gap either). The new layout is written to the in-memory rules for **that monitor + that window count** only (other monitors/counts still use the config; it is dropped when WTM is left, see below), goes through the same placement path as custom layouts — so the `[Tiling] AnimationDuration` animation applies — and is quantised to the pixel grid and logged as `WTM resize X+ mon1 n3 step20 -> 3,1,630/1920,1;3,2,(631-1290)/1920,1;3,3,(1291-1920)/1920,1;`, ready to paste back into `[Tiling] Rules`
- **Fixed "the spanning window steals the neighbour"** — candidates used to be filtered by centre comparison (`t.cy > cur.cy`), so a window spanning several rows that covers the focused one was eligible too, and its nearer centre let it steal the slot directly below or beside it: in the 5-window layout (tall window in the middle, two on each side) `Alt+Shift+J` on window 2 swapped it with window 1 instead of window 3 below it. Filtering now requires a full span crossing (`loJ >= cur.xhi` / `hiJ <= cur.xlo` and the vertical equivalents), so anything covering the focused window is no longer a neighbour; the four directions for the 3-window rules `3,1,(2-3)/3,1;3,2,1/3,1/2;3,3,1/3,2/2`, the 5-window layout and the 2×2 grid now match cell by cell
- **Only two windows move** — a swap exchanges two entries in `TileOrder` and re-applies the slots; every other window's rect is untouched (no more "re-layout the whole monitor in a new order")
- **Drag-to-swap** — dropping a window near a slot's centre swaps it into that slot (works across monitors)
- **Fullscreen & maximized handling** — true fullscreen (covers the bar) suspends tiling on that monitor and hides its borders; maximizing enters "solo mode": bar and borders stay, the monitor's other windows are `SW_HIDE`n, and only that window takes part in tiling; un-maximizing restores everything
- **Incremental border diff-sync** — borders are no longer destroyed and rebuilt on every focus change: only surplus/missing ones are created or destroyed, geometry and colour update on demand, exactly one border per window, and `RefreshBorder` is the single "destroy surplus" entry point
- **Animated moves** — `[Tiling] AnimationDuration` (ms, `0` = off) drives an ease-out cubic animation (single 12 ms timer)
- **`[Tiling] WTMGap`** — WTM-only tiling gap, decoupled from `Gap` (falls back to `[Border] Gap`); WTM passes `useDwmComp=false` so borders hug the DWM visual rect
- **Fixed "rebuild all borders on focus change"** — the old code destroyed and recreated every border GUI whenever focus changed, which is what made borders stick, linger or duplicate
- **Two-rate polling with real elapsed time** — fast path (border follow + focus) every `Border_RefreshMs`, slow path (membership / external drift / fullscreen) about every 250 ms; accumulation now uses real `A_TickCount` deltas (the old nominal-period sum made the slow path many times slower when `RefreshMs=0` is clamped to 1 ms). `AllBorders` fixed the same way
- **Windows dragged to another monitor** — drift detection now also re-tiles the monitor the window came from, instead of leaving a hole there
- **Floating windows are no longer yanked** — `Alt+Shift+H/J/K/L` does nothing when the focused window is floating/excluded (the old code relocated it to the adjacent monitor)
- **Hidden windows restored on reload/exit** — windows `SW_HIDE`n by solo mode are restored via an `OnExit` cleanup, so they can no longer stay invisible forever
- **Standalone pure-function test harness** — `docs/tools/mk_testslots.sh` extracts `ParseAxis`/`SlotFromSpan`/`PickSlotFromTable`/`ResizeSpans`/`RuleStringFor` & co. verbatim from `wm.ahk` and runs them independently (128 assertions: the full 4-direction tables for the 7-window / 5-window / 3-window / 2×2 layouts, the built-in layouts for n=2..5 plus portrait and ultrawide, the resize + rule-string round trip, and the scope of resize overrides); `docs/tools/probe_pick.ahk` separately cross-checks the two pick orders at random
- **Docs corrected** — README's WTM hotkey `Ctrl+Alt+T` fixed to the actual default `Alt+Shift+D` (focus `Alt+H/J/K/L`, swap `Alt+Shift+H/J/K/L`); `[Border] Gap` documented as the legacy location of the WTM gap
- **Borders track animated windows frame by frame** — while a move/swap animation runs, every frame re-reads the target's real rect and redraws its border, so unfocused windows no longer lag behind the window they belong to
- **Orphan border frames are reclaimed** — border windows carry the `AHKWM_BORDER` title (never shown, used only as a marker); `WTM.SweepOrphanBorders` destroys any frame of this process that is absent from all border maps for two consecutive passes, so a leftover frame can no longer stay on screen
- **Solo / fullscreen handling is per monitor** — `Alt+Shift+F` and maximizing enter and exit only on the focused window's monitor; the other monitors keep their own layout, borders and solo state
- **`osd-keycast.ahk` example (Ch/En)** — bottom-left overlay listing the keys currently held; polls `GetKeyState(key,"P")`, re-sends only when the set changes, and uses `duration=0` + `tag=keycast` so exactly one overlay exists; `Ctrl+Alt+F12` exits and clears the overlay (its `OnExit` handler returns nothing — a non-zero return value would stop AHK v2 from exiting)
- **Example config refreshed** — `docs/Examples/example-configs/wm_config.ini` now matches the current key set (`WTMFull`, `WTMGap`, `AnimationDuration`, `WTMDebug`, `#`-prefixed colors); personal paths are genericized

### v2.10.2 (2026-07-31)

- **PinBorder Z-order fix** — pin borders now stay in the topmost Z band so they render above the target window instead of being partially hidden behind it
- **TogglePin unpin cleanup** — unpinning now removes the window from all other virtual desktops, keeping it only on the current desktop; also properly sets/clears `AlwaysOnTop` on the target window

### v2.10.1 (2026-07-29)

- **Generate Theme from Wallpaper** — extract dominant colors from the desktop wallpaper via screen sampling and auto-generate a full theme palette; accessible from tray menu `Theme > Generate from Wallpaper`; generated theme stored in `wallpaper_theme.ini` without touching user's `[Theme]` config; switch back via `Theme > wallpaper (from image)`
- **Theme color assignment** — intelligently maps wallpaper colors to theme roles: darkest → Background, lightest → Text, most frequent → Active, most vivid → BorderPin, hue-matched → PM buttons; all colors guaranteed distinct with automatic divergence
- **Scan progress indicator** — real-time growing red bar shows sampling position during extraction; bar rendered below scan line to avoid contaminating samples
- **Sampling environment** — auto-hides status bar, minimizes all windows, hides desktop icons and taskbar during scan; restores everything on completion
- **Color `#` prefix** — all config hex color values now use standard `#RRGGBB` format; backward-compatible reading strips `#` automatically
- **Per-task color support** — `TaskTimes` config entries support color suffixes (e.g. `1_1200_1300,#ff0000,#00ff00`)

### v2.10.0 (2026-07-17)

- **OSD per-call customization** — external scripts can override every visual setting (font size, opacity, position, colors, width, rounding, font face) per OSD call via `key=value` pairs appended to the payload; all keys optional, fall back to `[GUI]` config defaults
- **OSD tag & instance isolation** — `tag=` key lets same-tag OSDs replace each other (no stacking); external OSDs run in a separate instance pool from internal `wm.ahk` OSDs, so the two never interfere
- **Bar per-element `fs=` and `wrap=` attributes** — Layout elements can now set their own font size (`fs=14`) and line count (`wrap=2`); bar auto-grows when wrapped elements need more height
- **Bilingual example suite** — new `docs/Examples/OSDExamples/` (5 scripts) and `docs/Examples/BarExamples/` (3 scripts), each with `En/` and `Ch/` variants, heavily commented with full parameter documentation
- **New examples include**: lyrics reader with tag replacement, timed notification daemon, text-file paginator, dual-slot bar lyrics simulator, multi-line poetry display
- **osd-timed-notify: `_*/N[xC]` interval-start suffix** — daily/weekly/once schedules can now take an interval suffix (e.g. `1200_*/30` = every 30 min from 12:00, `1400_*/20x3` = 3 times every 20 min from 14:00); interval only runs after the base time, resets at midnight
- **All example OSD helpers now use `SendMessageTimeoutW`** — 2s timeout + `SMTO_ABORTIFHUNG` prevents indefinite thread blocking when wm.ahk is busy; data copied into independent `Buffer` instead of `StrPtr` on a local variable
- **Removed `Esc::ExitApp` from all example scripts** — Esc is bound by too many apps; all examples now rely on tray-menu exit
- **Removed** `[WorkTime] NotificationRule` — timed notifications are now handled by a standalone script (`osd-timed-notify.ahk`), keeping wm.ahk lean

### v2.9.0 (2026-07-15)

- **External bar widgets** — `external_N` on `[Bar] Layout`, push text from any AHK script via `WM_COPYDATA`; `bar-examples/` and `osd-examples/` with CN/EN demos
- **Config key migration** — legacy `snake_case` auto-renamed to `PascalCase`; `CfgRead` with fallback chain
- **UTF-8 config auto-repair** — `SanitizeConfigEncoding` detects and fixes corrupted INI files
- **Config encoding fixed** — UTF-16 for all writes (AHK native), fixes Chinese/symbol garbled display
- **WTM focus color** — borders toggle focus/unfocus correctly; `RefreshBorder` full rebuild + HWND verify loop
- **WTM MoveDir** — Euclidean distance (same as FocusDir), up/down no longer erratic
- **Move-to-desktop** — `DesktopFocus[target]` set on move, window inserted at top of Z-order
- **Bar ghosting** — desktop cell HBITMAPs properly freed in `BarInstance.Destroy()`
- **Font consistency** — PowerMenu and PieMenu now respect `FontName` config
- **WTM responsiveness** — signature check every 10ms (was 150ms), stability delay 80ms
- **Logging overhaul** — ms timestamps, dedup, rotation, session start/end banners, `OnExit` handler
- **Self-test removed** — replaced by structured logging

### v2.8.5 (2026-07-10)

- **GDI handle leak fixed** — `CreateGradient()` 1×1 seed bitmap was leaked on every call (up to 100/s during border drag); now properly freed
- **Rapid desktop-switch race fixed** — `DesktopIsSwitching` flag guards `SwitchDesktop`, WTM/AllBorders ticks, `TogglePin`, `GatherAll`, and `SaveLayoutStateForReload`
- **Bar polling optimized** — WiFi and disk info cached for 30 s, avoiding per-second `netsh` subprocess spawn and `DriveGetSpaceFree` I/O
- **External OSD interface** — `WM_COPYDATA` receiver lets other scripts pop OSD messages
- **Duplicate code extracted** — `_GetHwndUnderMouse`, `_RemoveFromAllDesktops`, `_GetTileMode`, `_BorderPlaceFrame`, `_BuildSysWidget` shared helpers
- **UpdateClock table-driven** — `SysWidgets` array replaces 7 repeated if-blocks
- **_BuildElements unified** — `WidgetMeta` Map + multi-value case fallthrough replaces 7 repeated cases
- **Tiling edge gap fixed** — `Gap=0` now truly flush to screen edges

### v2.8.4 (2026-07-01)

- **Clipboard fixed** — `RecordClipboard()` was missing `FileAppend`; history is now actually written to file
- **Bar white edge fixed** — `RoundWindowEx` now disables DWM non-client rendering before `SetWindowRgn`
- **ShowWin fixed** — `SW_SHOWNA(8)` → `SW_RESTORE(9)`; minimized windows now restore correctly
- **Desktops white clipping** — layoutBg creation moved to `_BuildElements`
- **Span alignment** — `+`/`-` sign controls both group positioning and text alignment
- **GDI leak** — task-marker bitmaps now tracked and released on bar destroy
- **Clipboard debounce** — 200ms filter suppresses rapid duplicate fires

### v2.8.0 (2026-06-29)

- **Gradient colors** — bar elements, borders, and PowerMenu now support gradient backgrounds and gradient text
- **Bar rounded corners** — per-element `on|off` switch for bg-mode rounded corners
- **Bar layout overhaul** — new `N,element,span,colors,bg|tx,on|off` format
- **Border gradient** — `BorderDrag`/`BorderPin`/`BorderUnfocus` support comma-separated gradient colors
- **Pause-on-fullscreen** — `[General] PauseOnFullscreen=on` suspends hotkeys when gaming
- **Transparency step** — configurable step size, snap to multiples

### v2.6.4 (2026-06-18)

- **Config integrity check** — auto-detect missing keys & add defaults on every startup
- **Pin border rounding** — now reads from config
- **DWM compensation** — extracted into shared function
