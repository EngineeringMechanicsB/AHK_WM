#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
; ==============================================================================
; Bar Example 3 — Dual-Slot Dynamic Lyrics Simulator
; ==============================================================================
;
; [What this does]
;   Simulates a music player lyrics display using TWO bar slots:
;     external_1 — Song title (small font, single line)
;     external_2 — Current lyric line (large font, 2-line wrap)
;
;   Lyrics auto-advance every 3 seconds.  Every 5 lines, a celebratory
;   OSD pops up with playback stats.
;
; [Song]
;   "Hey Jude" by The Beatles.
;
; [Prerequisites]
;   1. wm.ahk must be running
;   2. Add BOTH external_1 and external_2 to [Bar] Layout, e.g.:
;        Layout=external_1,1/5,7AA2F7,tx,fs=12;external_2,(2-4)/5,9ECE6A,CDD6F4,tx,fs=16,wrap=2;time,+20/20;
;   3. Reload config (Alt+R) after editing
;
; [Key concepts]
;   - Two independent slots pushed from a single script
;   - fs= and wrap= per slot (small title + large wrapped lyrics)
;   - OSD + Bar combined: OSD for occasional notifications, Bar for persistent info
;   - Push-driven: no polling, updates only when content changes
;
; [Controls]
;   Esc — exit
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
    WMBarPush(1, "Hey Jude — The Beatles")

    ; Slot 2: Current lyric — large font, two-line wrap
    WMBarPush(2, Lyrics[gIdx])

    ; Every 5 lines: OSD celebration with stats
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
; WMBarPush(slot, text) — see bar-simple.ahk for full documentation.
; ------------------------------------------------------------------------------
WMBarPush(slot, text) {
    DetectHiddenWindows(true)
    h := WinExist("wm.ahk ahk_class AutoHotkey")
    if !h
        return false
    msg  := "BAR:" . slot . ":" . text
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
; AHK_WM_OSD(text, duration, opts) — see OSDExamples/En/osd-custom-all.ahk
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
