#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
; ==============================================================================
; Bar Example 1 — Simple Single-Line Push
; ==============================================================================
;
; [What this does]
;   Pushes a clock to the bar's external_1 slot every 3 seconds.
;   No font-size or wrap overrides — uses the global Bar_FontSize from config.
;
; [Prerequisites]
;   1. wm.ahk must be running
;   2. Add external_1 to [Bar] Layout in wm_config.ini, e.g.:
;        Layout=desktops,1/3;external_1,1/3,7AA2F7,tx;time,+20/20;
;   3. Reload config (Alt+R in wm.ahk) after editing the INI file
;
; [How it works]
;   Constructs "BAR:<slot>:<text>" and sends it via WM_COPYDATA.
;   The text persists on the bar until the next push or bar reload.
;   No polling — updates are push-driven.
;
;   Protocol:  BAR:<slot_number>:<text>
;     - slot_number: matches external_N in Layout (1-99)
;     - text:        any UTF-8 string, persists until next push
;
; [Controls]
;   Esc — exit
; ==============================================================================

PushTick() {
    WMBarPush(1, Format("{}", FormatTime(, "HH:mm:ss")))
}

PushTick()
SetTimer(PushTick, 3000)
Esc::ExitApp

; ------------------------------------------------------------------------------
; WMBarPush(slot, text)
;
;   Push text to a bar external slot.  Copy this function into your scripts.
;
;   Parameters:
;     slot — Slot number (1-99), matches external_N in [Bar] Layout.
;     text — The text to display on the bar.  Persists until next push
;            or bar reload.  Supports newlines (`n) if slot has wrap=N.
;
;   Returns: true = sent, false = wm.ahk not found.
;
;   Implementation:
;     1. Finds the hidden wm.ahk window.
;     2. Builds payload "BAR:slot:text".
;     3. Encodes as UTF-16 and sends WM_COPYDATA (0x4A).
;        Uses SendMessageTimeoutW to avoid blocking if wm.ahk is hung.
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
