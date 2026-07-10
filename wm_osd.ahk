#Requires AutoHotkey v2.0
; ==============================================================================
; AHK_WM External OSD Sender
; ==============================================================================
; Shows an on-screen message through AHK_WM — no polling, no temp files.
;
; Double-click this file to test, or copy the AHK_WM_OSD() function below
; into your own script and call it directly.
;
; AHK_WM must be running.
; ==============================================================================

; ---- Copy this function into any AHK v2 script ----
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

; ---- Quick demo (double-click to run) ----
AHK_WM_OSD("AHK_WM OSD is working!", 2000)
Sleep(2500)
AHK_WM_OSD("You can call this from any script", 2500)
Sleep(3000)
MsgBox("Demo complete!`n`nCopy the AHK_WM_OSD() function into your own script to use it anywhere.")
ExitApp()
