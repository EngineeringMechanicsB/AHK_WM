#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
; ==============================================================================
; Bar Example 3 — Dual-Slot Dynamic Lyrics Simulator (Self-Contained)
; ==============================================================================
;
; [What this does]
;   Simulates a music player's lyrics display using two bar slots:
;     slot 1 — Song title (small font, single line)
;     slot 2 — Current lyric (large font, two-line wrap)
;   Uses self-contained protocol — NO Layout config needed.
;
;   Lyrics advance every 3 seconds.  Every 5 lines, an OSD pops up.
;
; [Song] "Hey Jude" — The Beatles
;
; [Controls] Esc — exit
; ==============================================================================

global Lyrics := [
    "Hey Jude, don't make it bad",
    "Take a sad song and make it better",
    "Remember to let her into your heart",
    "Then you can start to make it better",
    "Hey Jude, don't be afraid",
    "You were made to go out and get her",
    "The minute you let her under your skin",
    "Then you begin to make it better",
    "And anytime you feel the pain",
    "Hey Jude, refrain",
    "Don't carry the world upon your shoulders",
    "For well you know that it's a fool",
    "Who plays it cool",
    "By making his world a little colder",
    "Na na na na na na na na na",
    "Hey Jude..."
]
global gIdx := 1
global gCounter := 0

PushLyrics() {
    global gIdx, gCounter, Lyrics
    gCounter++

    ; Slot 1: Song title — small font, single line
    WMBarPushEx(1, "0.05/0.35", "Hey Jude — The Beatles", "tx=7AA2F7,fs=12")

    ; Slot 2: Current lyric — large font, two-line wrap
    WMBarPushEx(2, "0.35/0.95", Lyrics[gIdx], "tx=CDD6F4,fs=16,wrap=2")

    ; Every 5 lines: OSD celebration
    if (Mod(gCounter, 5) = 0) {
        AHK_WM_OSD(Format("{} / {} lines played", gIdx, Lyrics.Length)
            , 2000, "fs=16,bg=1E1E2E,tx=9ECE6A,op=85,pos=80")
    }

    gIdx := Mod(gIdx, Lyrics.Length) + 1
}

PushLyrics()
SetTimer(PushLyrics, 3000)
Esc::ExitApp

; ------------------------------------------------------------------------------
; WMBarPushEx(slot, loHi, text, opts) — Self-contained protocol (see bar-simple.ahk)
; ------------------------------------------------------------------------------
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
    buf  := Buffer(size, 0)
    StrPut(msg, buf, "UTF-16")
    cds := Buffer(A_PtrSize * 3, 0)
    NumPut("Ptr",  0,       cds, 0)
    NumPut("UInt", size,    cds, A_PtrSize)
    NumPut("Ptr",  buf.Ptr, cds, A_PtrSize * 2)
    res := 0
    return DllCall("User32\SendMessageTimeoutW", "Ptr", h, "UInt", 0x4A
        , "Ptr", A_ScriptHwnd, "Ptr", cds.Ptr
        , "UInt", 0x2, "UInt", 2000, "UInt*", &res, "Ptr") ? true : false
}

; ------------------------------------------------------------------------------
; AHK_WM_OSD(text, duration, opts) — See osd-custom-all.ahk for full docs
; ------------------------------------------------------------------------------
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
