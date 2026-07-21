#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
; ==============================================================================
; Bar Example 3 — Dual-Slot Poetry Display (Self-Contained)
; ==============================================================================
;
; [Content] Dante Alighieri, Inferno — Canto I (public domain·1320)
;   slot 1 — Title (small font)
;   slot 2 — Verse (large font, two-line)
;   3s per line.  OSD every 7 lines.  Clears bar + restores height on exit.
;
; [Controls] Esc — exit
; ==============================================================================

global Verses := [
    "Midway upon the journey of our life",
    "I found myself within a forest dark",
    "For the straightforward pathway had been lost",
    "Ah me! how hard a thing it is to say",
    "What was this forest savage and harsh",
    "Which in the very thought renews the fear",
    "So bitter is it, death is little more",
    "But of the good to treat which there I found",
    "I'll speak of the other things I saw there",
    "I cannot well repeat how I entered",
    "So full of slumber at that point was I",
    "When I the true way had abandoned",
    "But after I had reached a mountain's foot",
    "Where that valley ended which had pierced",
    "My heart with fear, I looked up and saw",
    "Its shoulders clothed with the planet's rays"
]
global gIdx := 1
global gCounter := 0

PushVerse() {
    global gIdx, gCounter, Verses
    gCounter++

    WMBarPushEx(1, "0.05/0.35", "Dante's Inferno — Canto I", "tx=7AA2F7,fs=12")
    WMBarPushEx(2, "0.35/0.95", Verses[gIdx], "tx=CDD6F4,fs=16,wrap=2")

    if (Mod(gCounter, 7) = 0) {
        AHK_WM_OSD(Format("{} / {} lines", gIdx, Verses.Length)
            , 2000, "fs=16,bg=1E1E2E,tx=9ECE6A,op=85,pos=80")
    }
    gIdx := Mod(gIdx, Verses.Length) + 1
}

PushVerse()
SetTimer(PushVerse, 3000)

OnExit(Cleanup)
Cleanup(*) {
    _WMSend("BAR:1::")
    _WMSend("BAR:2::")
}
Esc::ExitApp

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
AHK_WM_OSD(text, duration := 1000, opts := "") {
    DetectHiddenWindows(true)
    h := WinExist("wm.ahk ahk_class AutoHotkey")
    if !h
        return false
    payload := "OSD:" . text . ":" . duration
    if (opts != "")
        payload .= ":" . opts
    c := StrPut(payload, "UTF-16")
    b := Buffer(A_PtrSize * 3, 0)
    NumPut("Ptr", 0, b, 0)
    NumPut("UInt", c, b, A_PtrSize)
    NumPut("Ptr", StrPtr(payload), b, A_PtrSize * 2)
    try SendMessage(0x4A, 0, b.Ptr, , "ahk_id " . h)
    return true
}
