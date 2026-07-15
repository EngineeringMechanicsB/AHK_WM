#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
; ==============================================================================
; AHK_WM Bar External Widget Example 3: Active Window Info (Title + Position/Size)
; ==============================================================================
; [What this does]
;   Captures the active window's title and position/size in real time and pushes
;   the result to the AHK_WM status bar.
;   Display format: "[title…] (left,top)-(right,bottom) widthxheight"
;   Example: "[Notepad] (100,200)-(900,600) 800x400"
;   Refreshes every 1 second, demonstrating how to collect system info for the bar.
;
; [Prerequisites]
;   1. AHK_WM (wm.ahk) must be running.
;   2. Your config [Bar] Layout must include an external_3 widget, e.g.:
;        Layout=desktops,(1-3)/20;external_3,(14-17)/20,89B4FA,A6E3A1,tx;time,20/20;
;      Reserve enough span (>= 4 columns) — window info text can be long.
;
; [How it works]
;   PushWinInfo() runs every 1 second via SetTimer:
;     1. WinExist("A") gets the currently active window handle.
;     2. WinGetTitle(hwnd) gets the window title, truncated to 15 chars.
;     3. WinGetPos(&x, &y, &w, &h) gets position and size.
;     4. The result is formatted into compact text and pushed to the bar.
;   If the active window is the bar itself or the desktop, "—" is shown instead.
;
; [How to call]
;   WMBarPush(slot, "text to display")
;   This script collects WinTitle + WinGetPos data; you can replace that with any
;   other system information:
;   - CPU usage (via WMI/PDH)
;   - Memory consumption
;   - Network speed
;   - Battery status
;   - Currently playing track
;
; [Extension ideas]
;   - Add WinGetClass to distinguish different window types.
;   - Add WinGetProcessName to show which program owns the window.
;   - Only update on window switch to save CPU.
;
; [Notes]
;   - WinGetPos returns the full window rect (including frame), not the client area.
;   - Minimized window positions may be unreliable.
;   - Sanitize window titles if they contain private information.
; ==============================================================================

; ---- Global state ----
; Cache the last window handle to avoid redundant computation
global LastHwnd := 0

; ---- Periodic push callback ----
; Triggered every 1000 ms by SetTimer
PushWinInfo() {
    global LastHwnd
    hwnd := 0
    try hwnd := WinExist("A")                              ; Active window
    if (!hwnd) {
        WMBarPush(3, "[no window]")
        return
    }
    ; Skip desktop & taskbar
    cls := WinGetClass(hwnd)
    if (cls = "Progman" || cls = "WorkerW" || cls = "Shell_TrayWnd") {
        WMBarPush(3, "[Desktop]")
        return
    }
    ; Skip update if same window to save resources
    if (hwnd = LastHwnd)
        return
    LastHwnd := hwnd

    ; ---- Collect window info ----
    ; Window title
    title := ""
    try title := WinGetTitle(hwnd)
    if (title = "")
        title := "(untitled)"
    ; Truncate long titles
    if (StrLen(title) > 15)
        title := SubStr(title, 1, 14) . "…"

    ; Window position & size
    try WinGetPos(&x, &y, &w, &h, hwnd)

    ; ---- Format output ----
    ; Format: "[title…] (left,top) widthxheight"
    text := Format("[{}] ({},{}) {}x{}", title, x, y, w, h)
    WMBarPush(3, text)
}

PushWinInfo()                     ; Push the first value immediately
SetTimer(PushWinInfo, 1000)       ; Then update every 1 second

; ------------------------------------------------------------------------------
; WMBarPush(slot, text) — reusable helper; copy into your own scripts as needed.
; ------------------------------------------------------------------------------
; Parameters:
;   slot - Slot number (1-99), matching external_N in your config Layout.
;   text - The text content to display (any string).
; Returns: true = sent successfully, false = wm.ahk window not found.
;
; Implementation details:
;   1. Locate the (possibly hidden) wm.ahk main window via DetectHiddenWindows.
;   2. Build the message string "BAR:slot:text".
;   3. Encode it as UTF-16 and compute the byte count.
;   4. Populate a COPYDATASTRUCT with the payload.
;   5. Send WM_COPYDATA (0x4A) via SendMessageTimeoutW.
;   6. SMTO_ABORTIFHUNG (0x2) + 2000 ms timeout prevents hangs if the target is busy.
; ------------------------------------------------------------------------------
WMBarPush(slot, text) {
    prevDetect := A_DetectHiddenWindows
    prevMatch  := A_TitleMatchMode
    DetectHiddenWindows(true)
    SetTitleMatchMode(2)
    target := WinExist("wm.ahk ahk_class AutoHotkey")
    DetectHiddenWindows(prevDetect)
    SetTitleMatchMode(prevMatch)
    if !target
        return false
    msg  := "BAR:" . slot . ":" . text
    size := (StrLen(msg) + 1) * 2                     ; UTF-16 byte count (incl. NUL terminator)
    buf  := Buffer(size, 0)
    StrPut(msg, buf, "UTF-16")
    cds := Buffer(A_PtrSize * 3, 0)                   ; COPYDATASTRUCT
    NumPut("Ptr",  0,       cds, 0)                   ; dwData (unused)
    NumPut("UInt", size,    cds, A_PtrSize)           ; cbData (byte count)
    NumPut("Ptr",  buf.Ptr, cds, A_PtrSize * 2)       ; lpData (points to message text)
    res := 0
    return DllCall("User32\SendMessageTimeoutW", "Ptr", target, "UInt", 0x4A
        , "Ptr", A_ScriptHwnd, "Ptr", cds.Ptr
        , "UInt", 0x2, "UInt", 2000, "UInt*", &res, "Ptr") ? true : false
}
