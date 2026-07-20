#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
; ==============================================================================
; Bar Example 2 — Multi-Line Text + Custom Font Size
; ==============================================================================
;
; [What this does]
;   Pushes two-line poems to the bar's external_1 slot every 5 seconds.
;   Demonstrates fs=N (font size override) and wrap=N (multi-line display)
;   configured in the bar Layout.
;
; [Prerequisites]
;   1. wm.ahk must be running
;   2. Add external_1 with fs= and wrap= to [Bar] Layout, e.g.:
;        Layout=external_1,(2-4)/5,CDD6F4,tx,fs=14,wrap=2;time,+20/20;
;      The span "(2-4)/5" gives it 40% of bar width — enough for poems.
;   3. Reload config (Alt+R) after editing
;
; [Layout attributes explained]
;   fs=N     — Font size in points for this slot (default: global Bar_FontSize)
;   wrap=N   — Maximum display lines (0 = single line, default)
;
;   When wrap > 1:
;     - The bar automatically grows taller to fit multi-line content.
;     - Text with `n (newlines) renders as separate lines.
;     - Long text without newlines auto-wraps at word boundaries.
;
;   Example Layout entries:
;     external_1,1/3,FFAA00,tx,fs=12        ← larger font, single line
;     external_1,1/3,FFAA00,tx,fs=14,wrap=2 ← even larger, two lines
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
    WMBarPush(1, Poems[gIdx])
    gIdx := Mod(gIdx, Poems.Length) + 1
}

PushPoem()
SetTimer(PushPoem, 5000)
Esc::ExitApp

; ------------------------------------------------------------------------------
; WMBarPush(slot, text)
;   See bar-simple.ahk for full documentation.
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
