#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
; ==============================================================================
; Bar Example 2 — Multi-Line Text (Self-Contained)
; ==============================================================================
;
; [Content] Les Misérables — Do You Hear the People Sing? (public domain novel·1862)
; [Exit] Ctrl+Alt+F12 (or tray right-click → Exit)
; ==============================================================================

global Lines := [
    "Do you hear the people sing`nSinging the song of angry men",
    "It is the music of the people`nWho will not be slaves again",
    "When the beating of your heart`nEchoes the beating of the drums",
    "There is a life about to start`nWhen tomorrow comes"
]
global gIdx := 1

PushLine() {
    global gIdx, Lines
    WMBarPushEx(1, "0.3/0.9", Lines[gIdx], "tx=CDD6F4,fs=11,wrap=2")
    gIdx := Mod(gIdx, Lines.Length) + 1
}

PushLine()
SetTimer(PushLine, 5000)

^!F12::ExitApp  ; Ctrl+Alt+F12 to exit (safer than Esc)

WMBarPushEx(slot, loHi, text, opts := "") {
    msg := "BAR:" . slot . ":" . loHi . ":" . text
    if (opts != "")
        msg .= ":" . opts
    return _WMSend(msg)
}
_WMSend(msg) {
    DetectHiddenWindows(true)
    h := WinExist("wm.ahk ahk_class AutoHotkey")
    if !h
        return false
    size := (StrLen(msg) + 1) * 2
    buf := Buffer(size, 0)
    StrPut(msg, buf, "UTF-16")
    cds := Buffer(A_PtrSize * 3, 0)
    NumPut("Ptr", 0, cds, 0)
    NumPut("UInt", size, cds, A_PtrSize)
    NumPut("Ptr", buf.Ptr, cds, A_PtrSize * 2)
    res := 0
    return DllCall("User32\SendMessageTimeoutW", "Ptr", h, "UInt", 0x4A
        , "Ptr", A_ScriptHwnd, "Ptr", cds.Ptr
        , "UInt", 0x2, "UInt", 2000, "UInt*", &res, "Ptr") ? true : false
}
