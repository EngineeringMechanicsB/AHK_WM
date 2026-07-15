#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
; ==============================================================================
; AHK_WM OSD External Call Example 2: Dynamic Notification (Symbol Rotation + Counter)
; ==============================================================================
; [What this does]
;   Pops up an OSD notification every 2 seconds. Left side: cycling symbol
;   (◉→◈→◆→◎). Right side: incrementing counter. Demonstrates periodic OSD usage.
;   Press Esc to exit.
;
; [Prerequisites]
;   1. AHK_WM (wm.ahk) must be running.
;   2. No config changes required.
;
; [How to call]
;   AHK_WM_OSD("text to display", durationMs)
;   Call inside a SetTimer callback for periodic popups.
;   OSD has anti-spam; >= 2000 ms interval recommended.
;
; [Bar variable vs. OSD variable]
;   - Bar variable (bar-custom-variable): persistent on bar — ideal for ongoing info
;   - OSD variable (this script): periodic center-screen popup — ideal for stage alerts
;     (e.g. "⏰ 30 minutes elapsed")
;
; [Notes]
;   Press Esc to exit this script.
; ==============================================================================

global Counter := 0
global SymbolIdx := 1
global Symbols := ["◉", "◈", "◆", "◎"]

PushTick() {
    global Counter, SymbolIdx, Symbols
    Counter++
    if (Mod(Counter, 3) = 0)
        SymbolIdx := Mod(SymbolIdx, Symbols.Length) + 1
    sym := Symbols[SymbolIdx]
    val := Mod(Counter, 100)
    AHK_WM_OSD(Format("{} Count: {:3d}", sym, val), 1500)
}

PushTick()
SetTimer(PushTick, 2000)
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
