#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
; ==============================================================================
; Bar Example 2 — Multi-Line Text + Custom Font Size (Self-Contained)
; ==============================================================================
;
; [What this does]
;   Pushes two-line poems every 5 seconds using the NEW self-contained
;   protocol.  NO Layout config needed — position, color, font, wrap
;   all passed in the push.
;
; [Keys]
;   fs=N     — Font size pt
;   wrap=N   — Max lines (>1 = multi-line, bar auto-grows)
;   `n       — Newline in text renders as separate lines
;
; [Controls]
;   Esc — exit
; ==============================================================================

global Poems := [
    "Roses are red`nViolets are blue",
    "Sugar is sweet`nAnd so are you",
    "Twinkle twinkle`nLittle star",
    "How I wonder`nWhat you are"
]
global gIdx := 1

PushPoem() {
    global gIdx, Poems
    ; Self-contained push with span + color + font + wrap
    WMBarPushEx(1, "0.3/0.9", Poems[gIdx], "tx=CDD6F4,fs=14,wrap=2")
    gIdx := Mod(gIdx, Poems.Length) + 1
}

PushPoem()
SetTimer(PushPoem, 5000)
Esc::ExitApp

; ------------------------------------------------------------------------------
; Helper functions — see bar-simple.ahk for full docs.
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
