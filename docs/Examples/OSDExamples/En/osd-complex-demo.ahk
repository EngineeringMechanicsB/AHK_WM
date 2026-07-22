#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
; ==============================================================================
; OSD Example 3 — Dynamic Content: Lyrics Reader
; ==============================================================================
;
; [What this does]
;   Simulates a lyrics display — cycles through lines of a song, showing
;   each line as a styled OSD popup.  Uses the "tag" key so each new line
;   REPLACES the previous one (no GUI stacking).
;
;   Also demonstrates: pressing Space shows THREE simultaneous OSDs
;   with different colors and positions — proving multi-instance coexistence
;   when tags differ.
;
; [Song]
;   "Hey Jude" by The Beatles — one of the most universally recognized songs.
;
; [Controls]
;   Up / Down arrow — previous / next lyric line
;   Space           — pop 3 simultaneous OSDs at different positions
;   Esc             — exit
;
; [Key concepts demonstrated]
;   1. tag="lyrics"  → each new line destroys the old one (replacement pattern)
;   2. No tag        → each OSD is independent, multiple coexist (Space demo)
;   3. External OSDs never interfere with wm.ahk's internal OSDs
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

; ---- Show current lyric line (tag="lyrics" replaces previous) ----
ShowCurrent() {
    global gIdx, Lyrics
    text := Lyrics[gIdx]
    ; tag=lyrics ensures each new line destroys the old one — no stacking
    AHK_WM_OSD(text, 2500, "fs=28,bg=A020F0,tx=FFFFFF,op=82,pos=85,tag=lyrics")
}

; ---- Navigation ----
Up:: {
    global gIdx, Lyrics
    gIdx := (gIdx > 1) ? gIdx - 1 : Lyrics.Length
    ShowCurrent()
}
Down:: {
    global gIdx, Lyrics
    gIdx := (gIdx < Lyrics.Length) ? gIdx + 1 : 1
    ShowCurrent()
}

; ---- Multi-instance demo: 3 OSDs at different positions simultaneously ----
Space:: {
    ; These three have different tags (or no tag) → all stay visible at once
    AHK_WM_OSD("Top notification",     3000, "fs=16,bg=CC3333,tx=FFFFFF,op=90,pos=15,tag=demo1")
    Sleep(200)
    AHK_WM_OSD("Middle notification",  3000, "fs=16,bg=33AA55,tx=FFFFFF,op=90,pos=50,tag=demo2")
    Sleep(200)
    AHK_WM_OSD("Bottom notification",  3000, "fs=16,bg=3355CC,tx=FFFFFF,op=90,pos=85,tag=demo3")
}

Esc::ExitApp

; ------------------------------------------------------------------------------
; AHK_WM_OSD(text, duration, opts)
;   See osd-custom-all.ahk for full parameter documentation.
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

ShowCurrent()
