#Requires AutoHotkey v2.0
; ==============================================================================
; AHK_WM External OSD — Minimal Example (English)
; ==============================================================================
; Prerequisite: AHK_WM must be running.
; Copy the function below into any AHK v2 script and call AHK_WM_OSD(text, ms).

; ---- Core function (copy-paste into your own script) ----
AHK_WM_OSD(text, duration := 1000) {
    DetectHiddenWindows(true)
    h := WinExist("wm.ahk ahk_class AutoHotkey")
    if !h
        return false
    p := "OSD:" . text . ":" . duration
    c := StrPut(p, "UTF-16")
    b := Buffer(A_PtrSize * 3, 0)
    NumPut("Ptr", 0, b, 0)
    NumPut("UInt", c, b, A_PtrSize)
    NumPut("Ptr", StrPtr(p), b, A_PtrSize * 2)
    try SendMessage(0x4A, 0, b.Ptr, , "ahk_id " . h)
    return true
}

; ---- Demo (runs when you double-click this file) ----
AHK_WM_OSD("Hello from AHK_WM OSD!", 2000)
Sleep(2500)
AHK_WM_OSD("Build passed — 0 errors, 0 warnings", 3000)
Sleep(3500)
AHK_WM_OSD("Deploy complete", 1500)
ExitApp()
