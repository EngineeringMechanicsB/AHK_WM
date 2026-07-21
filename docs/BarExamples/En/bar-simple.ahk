#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
; ==============================================================================
; Bar Example 1 — Self-Contained Push (No Layout Config Needed)
; ==============================================================================
;
; [What this does]
;   Pushes a clock to the bar every 3 seconds using the NEW self-contained
;   protocol.  NO [Bar] Layout declaration needed — position, color, and
;   font size are all passed in the push message.
;
; [Protocols]
;   NEW (v2.11+):  BAR:<slot>:<lo/hi>:<text>:<key=val,...>
;     Self-contained.  Creates the bar element on the fly.  No Layout needed.
;     Keys: bg=RRGGBB, tx=RRGGBB, rd=on|off, rr=N, fs=N, wrap=N
;   OLD:  BAR:<slot>:<text>
;     Requires external_N declared in [Bar] Layout.
;
;   lo/hi = span fraction ("0.5/0.8") or pixel ("(200-550)/1920")
;
; [Controls]
;   Esc — exit
; ==============================================================================

PushTick() {
    WMBarPushEx(1, "0.5/0.8", FormatTime(, "HH:mm:ss"), "bg=7AA2F7,fs=14")
}

PushTick()
SetTimer(PushTick, 3000)
Esc::ExitApp

; ------------------------------------------------------------------------------
; WMBarPush(slot, text) — Old protocol (requires Layout external_N)
; ------------------------------------------------------------------------------
WMBarPush(slot, text) {
    return _WMSend("BAR:" . slot . ":" . text)
}

; ------------------------------------------------------------------------------
; WMBarPushEx(slot, loHi, text, opts := "") — NEW self-contained protocol
;   slot  — Slot number (1-99)
;   loHi  — Span: "0.5/0.8" (fraction) or "(200-550)/1920" (pixels)
;   text  — Display text. Use `n for newlines if wrap=N.
;   opts  — "key=val,key=val"  (all optional):
;             bg=RRGGBB  — Background fill
;             tx=RRGGBB  — Text color
;             rd=on|off  — Rounded corners
;             rr=N       — Corner radius px
;             fs=N       — Font size pt
;             wrap=N     — Max lines (>1 = multi-line, bar auto-grows)
; ------------------------------------------------------------------------------
WMBarPushEx(slot, loHi, text, opts := "") {
    msg := "BAR:" . slot . ":" . loHi . ":" . text
    if (opts != "")
        msg .= ":" . opts
    return _WMSend(msg)
}

; ---- Low-level WM_COPYDATA sender ----
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
