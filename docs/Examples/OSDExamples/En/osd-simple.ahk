#Requires AutoHotkey v2.0
#SingleInstance Force
; ==============================================================================
; OSD Example 1 — Simple Call (No Customization)
; ==============================================================================
;
; [What this does]
;   Sends a single OSD popup to AHK_WM using only text and duration.
;   All visual settings (font, color, position, opacity) come from the
;   [GUI] section of wm_config.ini — no per-call overrides.
;
; [Prerequisites]
;   1. AHK_WM (wm.ahk) must be running
;   2. No config changes needed — OSD is always available
;
; [How it works]
;   Constructs the message "OSD:text:duration" and sends it via WM_COPYDATA
;   to the wm.ahk main window.  wm.ahk internally calls OSD.Show() which
;   displays the popup at the center of the current monitor.
;
;   Message format:  OSD:<text>:<duration_ms>
;     - text:     any UTF-8 string (Chinese / emoji OK)
;     - duration: milliseconds the popup stays visible (default 1000)
;
; [Usage]
;   Double-click this script.  You'll see a popup that auto-fades after 3s.
;
; [Customization]
;   See osd-custom-all.ahk for per-call overrides (color, size, position, etc.)
; ==============================================================================

AHK_WM_OSD("Hello! This is a simple OSD notification.", 3000)
Sleep(3500)
ExitApp

; ------------------------------------------------------------------------------
; AHK_WM_OSD(text, duration, opts)
;
;   Generic helper — copy this function into your own scripts.
;
;   Parameters:
;     text     — The text to display (UTF-8, supports emoji and Chinese).
;     duration — How long the popup stays visible, in milliseconds.
;                Default 1000.  0 = stays until the next OSD replaces it.
;     opts     — (Optional) Per-call visual overrides as "key=value,key=value".
;                Leave empty to use wm_config.ini defaults.
;                See osd-custom-all.ahk for all available keys.
;
;   Returns: true = message sent successfully, false = wm.ahk window not found.
;
;   Implementation:
;     1. Finds the hidden wm.ahk main window via DetectHiddenWindows.
;     2. Builds the payload "OSD:text:duration[:opts]".
;     3. Encodes as UTF-16 and sends WM_COPYDATA (0x4A) via SendMessage.
; ------------------------------------------------------------------------------
AHK_WM_OSD(text, duration := 1000, opts := "") {
    DetectHiddenWindows(true)
    h := WinExist("wm.ahk ahk_class AutoHotkey")
    if !h
        return false
    payload := "OSD:" . text . ":" . duration
    if (opts != "")
        payload .= ":" . opts
    dataSize := (StrLen(payload) + 1) * 2
    dataBuf := Buffer(dataSize, 0)
    StrPut(payload, dataBuf, "UTF-16")
    cds := Buffer(A_PtrSize * 3, 0)
    NumPut("Ptr", 0, cds, 0)
    NumPut("UInt", dataSize, cds, A_PtrSize)
    NumPut("Ptr", dataBuf.Ptr, cds, A_PtrSize * 2)
    res := 0
    DllCall("User32\SendMessageTimeoutW"
        , "Ptr", h, "UInt", 0x4A, "Ptr", A_ScriptHwnd
        , "Ptr", cds.Ptr, "UInt", 0x2, "UInt", 2000
        , "UInt*", &res, "Ptr")
    return true
}
