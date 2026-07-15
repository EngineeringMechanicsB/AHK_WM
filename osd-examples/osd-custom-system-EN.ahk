#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
; ==============================================================================
; AHK_WM OSD External Call Example 3: Window Change Notification (Title + Pos/Size)
; ==============================================================================
; [What this does]
;   Monitors the active window. When it changes, an OSD notification pops up
;   showing the new window's title, class, process name, position, and size.
;   Press Esc to exit. Press Ctrl+F5 to trigger a manual query.
;
; [Prerequisites]
;   1. AHK_WM (wm.ahk) must be running.
;   2. No config changes required.
;
; [How to call]
;   AHK_WM_OSD("text to display", durationMs)
;   This script triggers automatically on window switch, or press Ctrl+F5.
;
; [How it works]
;   Every 500 ms, checks whether the active window handle has changed.
;   If changed, collects WinTitle + WinGetPos + WinGetClass + WinGetProcessName.
;   Formats as multi-line text and pops up via OSD (OSD supports `n for line breaks).
;
; [Use cases]
;   - Debugging window layout issues (quick coordinate check)
;   - Accessibility aid (spoken/visual cue on window switch)
;   - Developer tool (confirm window class & process name)
;
; [Notes]
;   Press Esc to exit this script.
; ==============================================================================

global LastHwnd := 0

CheckWindow() {
    global LastHwnd
    hwnd := 0
    try hwnd := WinExist("A")
    if (!hwnd || hwnd = LastHwnd)
        return
    LastHwnd := hwnd

    ; ---- Collect window info ----
    title := ""
    try title := WinGetTitle(hwnd)
    if (title = "")
        title := "(untitled)"
    if (StrLen(title) > 30)
        title := SubStr(title, 1, 29) . "…"

    cls := ""
    try cls := WinGetClass(hwnd)

    proc := ""
    try proc := WinGetProcessName(hwnd)

    try WinGetPos(&x, &y, &w, &h, hwnd)

    ; ---- Format multi-line OSD ----
    text := Format("[{}]`nClass: {}  Proc: {}`nPos: ({},{})  Size: {}x{}"
        , title, cls, proc, x, y, w, h)
    AHK_WM_OSD(text, 2500)
}

SetTimer(CheckWindow, 500)
^F5::CheckWindow()               ; Manual trigger
Esc::ExitApp

AHK_WM_OSD(text, duration := 1000) {
    DetectHiddenWindows(true)
    h := WinExist("wm.ahk ahk_class AutoHotkey")
    if !h
        return false
    payload := "OSD:" . text . ":" . duration
    c := StrPut(payload, "UTF-16")
    b := Buffer(A_PtrSize * 3, 0)
    NumPut("Ptr", 0, b, 0)
    NumPut("UInt", c, b, A_PtrSize)
    NumPut("Ptr", StrPtr(payload), b, A_PtrSize * 2)
    try SendMessage(0x4A, 0, b.Ptr, , "ahk_id " . h)
    return true
}
