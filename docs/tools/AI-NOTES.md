# AI Notes — Working on AHK_WM Without Breaking the User's Session

Audience: an AI agent (or a human) editing `wm.ahk` on the user's live machine.
Every item below was hit for real while building v2.13.0. Read this before touching the script.

## 1. Where things actually run

| Role | Path |
|---|---|
| Source / git repo | `C:\Users\Administrator\Desktop\AI\AHK_WM` |
| The copy the user runs | `C:\Users\Administrator\Desktop\zxw\StartUp\wm.ahk` |
| Live config | `C:\Users\Administrator\.config\AHK_WM\wm_config.ini` |
| Live log | `C:\Users\Administrator\.config\AHK_WM\wm.log` |
| Exclusions | `C:\Users\Administrator\.config\AHK_WM\exclude.ini` |

Editing the repo does **not** change the running script. To deploy:

1. Back up both the deployed `wm.ahk` and `wm_config.ini` (the user asks for this explicitly).
2. `cp` the repo `wm.ahk` over the deployed one.
3. The user presses `Alt+R` (the script's own reload hotkey) or restarts it.

The script is a single file; `#Include "*i %A_ScriptDir%\Buttons\..."` at the bottom is an
optional include, so a copy placed elsewhere still parses.

## 2. File encoding / line endings

- `wm.ahk` is **UTF-8 with BOM + CRLF**. Preserve both. A BOM-less file makes AHK read it as ANSI
  and Chinese strings corrupt.
- The config file is **UTF-16 LE**. Read/write it with `iconv` or AHK's `FileRead(..., "UTF-16")`.
  Never rewrite it with a UTF-8 tool.
- Editing `wm.ahk` with Python: read `encoding='utf-8-sig'`, write `encoding='utf-8-sig'` with
  `newline=''`, then explicitly convert LF → CRLF. Python's universal-newline read turns CRLF into
  LF, so a naive rewrite silently converts the whole file.
- `docs/Examples/example-configs/wm_config.ini` is also UTF-16 LE.

## 3. Syntax-checking without launching the window manager

Running `wm.ahk` for real starts the tiler, registers global hotkeys and rearranges windows.
Do **not** do that as a syntax check.

**Preferred method — the `/validate` switch:**

```bash
bash docs/tools/validate.sh              # wm.ahk by default
bash docs/tools/validate.sh path/to.ahk  # any script
```

It runs `AutoHotkey64.exe /validate /ErrorStdOut <file>`, which parses without executing.
Exit 0 = OK, 2 = error. This is the correct tool; use it first.

**Fallback trick** (if `/validate` is unavailable): copy the file and insert `return` immediately
after the first `#Requires` line. AHK parses the whole file (functions and classes are hoisted)
but the auto-execute section exits immediately.

```bash
python - <<'PY'
b = open('wm.ahk','rb').read()
i = b.find(b'\r\n')
open('tmp.ahk','wb').write(b[:i+2] + b'return\r\n' + b[i+2:])
PY
"C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" tmp.ahk; echo "exit=$?"
```

Caveats:

- The fallback intentionally triggers `#Warn` "line will never execute". The warning is harmless,
  but it pops a dialog and will be captured by `ahk-error-watcher.ahk`. Delete the temp file
  afterwards and do not leave it anywhere the user watches.
- `Ahk2Exe.exe` on this machine fails with `Failed to compile:` even for a one-line script. Do not
  rely on it as a syntax checker.
- A better harness for behaviour tests is a small file that calls the class methods and ends with
  `ExitApp`, followed by the **entire** `wm.ahk` source. The source parses, but its startup section
  never executes. Initialize the globals you need (`WTM_Gap`, `TileSink`, `SlotTableCache`,
  `WTM_LayoutOverride`, exclude arrays, …) in the harness, because top-level assignments in the
  included source are skipped.

## 4. AHK v2 gotchas that cost time

### ByRef output parameters need `&` at the call site

```ahk
GetTileArea(monIdx, gap, &X, &Y, &W, &H)   ; correct
GetTileArea(monIdx, gap, &X, &Y, W, H)     ; W/H are never assigned
```

The second form produces `Warning: This local variable appears to never be assigned a value` and
then an `Expected an Integer but got a Float`-style failure later. This applies to user-defined
ByRef functions, not just built-ins.

### `//` is integer division and rejects floats

`GetTileArea` computes `edgeMargin := gapBase / 2`, so its `W`/`H` outputs are floats.
`(W - w) // 2` then throws `Expected an Integer but got a Float`. Use `/ 2` and `Round()` before
passing values to `DllCall(..., "Int", ...)`.

### Missing Map keys throw

`Map()[key]` on a missing key raises `Item has no value`; it does **not** return an empty string.
Always guard with `.Has(key)`.

### `#Warn` syntax differs by version

- `#Warn Off` is invalid (`Parameter #1 invalid`).
- `#Warn All, Stderr` is invalid on this build (`Parameter #2 invalid`).
- Leave `#Warn` alone, or use `#Warn All, OutputDebug`.

### Class statics are available before auto-execute

`class WTM { static ... }` is hoisted, so a harness at the top of the file can call `WTM.Method()`
even though the class text appears later. Static property initializers run at load time.

### Strings are indexable, Arrays have methods

If `pages[p]` returns a single character, `pages[p].Push(...)` fails with
`This value of type "String" has no method named "Push"`. That means the object you thought was
an array is a string (or a Map value got corrupted). Validate with `value is Array` and reset.

### Comma-separated statements are fine

Existing code uses `a := 1, b := 2`; it is valid AHK v2 and matches the file's style.

## 5. Forcing window sizes

Some apps (Windows Terminal is the usual suspect) clamp their size. WTM uses:

```ahk
DllCall("SetWindowPos", "Ptr", hwnd, "Ptr", 0
    , "Int", Round(x), "Int", Round(y), "Int", Round(w), "Int", Round(h)
    , "UInt", 0x4 | 0x10 | 0x400)   ; NOZORDER | NOACTIVATE | NOSENDCHANGING
```

- `SWP_NOSENDCHANGING (0x400)` skips `WM_WINDOWPOSCHANGING`, where many apps re-apply their
  minimum size.
- `WM_GETMINMAXINFO` only governs user resizing; `SetWindowPos` is not limited by it.
- A few apps clamp again in `WM_SIZE` / `WM_EXITSIZEMOVE`; defeating those requires temporarily
  toggling `WS_THICKFRAME` and is not worth it.
- Negative window coordinates are accepted by Windows (verified with `SetWindowPos(-2500, ...)`).
- `WM_GETMINMAXINFO` can be queried with `SendMessage(hwnd, 0x24, 0, &mi)`; `ptMinTrackSize` sits
  at offsets 24/28 in a 40-byte `MINMAXINFO`.

For Overview, never trust actual window rects: keep the intended rects in `OverviewRects` and use
them for direction picking, swapping and drag drops. Apps that refuse a size would otherwise
break navigation.

## 6. AutoHotkey error dialogs

- Runtime and load errors use window class `#32770`, and the title is usually the script file name
  (e.g. `bad.ahk`), not the word "Error".
- `WinGetText(hwnd)` contains the exact text (`Error: ...`, `Line: ...`, `File: ...`), which is
  more reliable than OCR.
- `WinGetList()` only sees visible windows; call `DetectHiddenWindows(true)` before scanning if
  dialogs may be hidden.
- `docs/tools/ahk-error-watcher.ahk` polls, screenshots, OCRs (`ocr.ps1`), logs to `errors.log`
  and closes the dialog. It deliberately matches only AutoHotkey processes and only dialogs whose
  title/text starts with `Error:` / `Warning:` (or class `#32770`), so it does not touch the
  script's own OSD/help windows (`AutoHotkeyGUI`, different title).
- OCR uses `Windows.Media.Ocr` from PowerShell 5.1. The WinRT async call needs the `AsTask`
  reflection helper in `ocr.ps1`; direct `.GetResults()` calls do not work from PowerShell.
- The Chinese OCR engine misreads `l`/`1`/`i`; always log the exact window text alongside OCR.

## 7. Test-environment limits

- This machine reports **one** display (`1600x900`). Cross-monitor code paths cannot be exercised
  locally; cover them with unit-style tests on the page model and reason carefully about
  `_AdjacentMonitor` / `_ScrollExtremeWindow`.
- Fake hwnds do not survive `WinExist` / `_OrderIndex`, so tests that need window identity must
  create real `Gui` windows and destroy them afterwards.
- The pure-function harness is `bash docs/tools/run_testslots.sh`; it extracts top-level functions
  from `wm.ahk` and must stay green. Class methods are not extracted, so keep testable math in
  top-level functions when adding new logic.

## 8. Workflow / style rules from the user

- Do not write or update documentation until the feature is complete and verified. The user
  repeatedly asks for code first, docs last.
- Code comments: English first, then a very short Chinese fragment, matching existing banners:
  `; ---- Scrollable tiling state / 无限滚动状态 ----`. No narrative comments.
- Back up before deploying; never edit the live copy directly.
- Commit messages follow `<type>: <summary>`, Chinese or English, consistent within the repo.
- The user watches errors themselves; if a dialog appears, they may paste it. The error watcher
  exists so they do not have to.
