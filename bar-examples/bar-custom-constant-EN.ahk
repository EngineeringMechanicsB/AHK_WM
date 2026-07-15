#Requires AutoHotkey v2.0
#SingleInstance Force
; ==============================================================================
; AHK_WM Bar External Widget Example 1: Push a Fixed Text String
; ==============================================================================
; [What this does]
;   Pushes a fixed text string to the external_1 slot of the AHK_WM status bar.
;   Run once — the text persists on the bar until the next push or bar reload.
;
; [Prerequisites]
;   1. AHK_WM (wm.ahk) must be running.
;   2. Your config [Bar] Layout must include an external_1 widget, e.g.:
;        Layout=desktops,(1-3)/20;external_1,(9-12)/20,B48EAD,CF8DC9,bg,on;time,20/20;
;      Format: external_N, span, color1, color2, bg|tx, on|off
;      - N: slot number (1-99), matches the first argument of WMBarPush below
;      - Span: (start-end)/columns; center-align (a/cols), right-align (+cols), left-align (-cols)
;      - Colors: single or dual-color gradient, 6-digit hex
;      - Mode: bg=gradient background + text overlay, tx=gradient text
;      - Rounded: on / off
;   3. Mix freely with other widgets (desktops, time, date, etc.)
;
; [How to call]
;   WMBarPush(slot, "text to display")
;   slot = 1-99, must match the N in external_N in Layout
;   Text length is unlimited, but the bar has limited space — ~20 chars recommended.
;
; [How it works]
;   Sends a WM_COPYDATA message containing "BAR:slot:text" to the wm.ahk main window.
;   wm.ahk stores it in Bar_ExternalData[slot]; the bar reflects it on the next refresh.
;   Single call, no polling, no temp files.
;
; [Notes]
;   - Exiting this script leaves the last pushed value on the bar (until another
;     script pushes the same slot, or the bar is reloaded).
;   - Multiple scripts can push to different slots simultaneously.
;   - If nothing appears, verify that your Layout includes external_N for this slot.
; ==============================================================================

if WMBarPush(1, "★ Hello from external script")
    TrayTip("Pushed to bar slot 1")
else
    TrayTip("AHK_WM window not found — is wm.ahk running?")
Sleep(1500)
ExitApp

; ------------------------------------------------------------------------------
; WMBarPush(slot, text) — reusable helper; copy into your own scripts as needed.
; ------------------------------------------------------------------------------
; Parameters:
;   slot - Slot number (1-99), matching external_N in your config Layout.
;   text - The text content to display (any string).
; Returns: true = sent successfully, false = wm.ahk window not found.
;
; Implementation details:
;   1. Locate the (possibly hidden) wm.ahk main window via DetectHiddenWindows.
;   2. Build the message string "BAR:slot:text".
;   3. Encode it as UTF-16 and compute the byte count.
;   4. Populate a COPYDATASTRUCT with the payload.
;   5. Send WM_COPYDATA (0x4A) via SendMessageTimeoutW.
;   6. SMTO_ABORTIFHUNG (0x2) + 2000 ms timeout prevents hangs if the target is busy.
; ------------------------------------------------------------------------------
WMBarPush(slot, text) {
    prevDetect := A_DetectHiddenWindows
    prevMatch  := A_TitleMatchMode
    DetectHiddenWindows(true)
    SetTitleMatchMode(2)
    target := WinExist("wm.ahk ahk_class AutoHotkey")
    DetectHiddenWindows(prevDetect)
    SetTitleMatchMode(prevMatch)
    if !target
        return false
    msg  := "BAR:" . slot . ":" . text
    size := (StrLen(msg) + 1) * 2                     ; UTF-16 byte count (incl. NUL terminator)
    buf  := Buffer(size, 0)
    StrPut(msg, buf, "UTF-16")
    cds := Buffer(A_PtrSize * 3, 0)                   ; COPYDATASTRUCT
    NumPut("Ptr",  0,       cds, 0)                   ; dwData (unused)
    NumPut("UInt", size,    cds, A_PtrSize)           ; cbData (byte count)
    NumPut("Ptr",  buf.Ptr, cds, A_PtrSize * 2)       ; lpData (points to message text)
    res := 0
    return DllCall("User32\SendMessageTimeoutW", "Ptr", target, "UInt", 0x4A
        , "Ptr", A_ScriptHwnd, "Ptr", cds.Ptr
        , "UInt", 0x2, "UInt", 2000, "UInt*", &res, "Ptr") ? true : false
}
