#Requires AutoHotkey v2.0
#SingleInstance Force
; ==============================================================================
; AHK_WM OSD External Call Example 1: Display a Fixed Notification
; ==============================================================================
; [What this does]
;   Sends a one-shot OSD (on-screen display) notification to AHK_WM.
;   The text appears center-screen and auto-dismisses after the specified duration.
;   Run once — text shows for the given time and fades out automatically.
;
; [Prerequisites]
;   1. AHK_WM (wm.ahk) must be running.
;   2. No config changes needed — OSD is always available.
;   3. Message format: "OSD:text[:durationMs]" — duration is optional, default 1000 ms.
;
; [How to call]
;   AHK_WM_OSD("text to display", durationInMs)
;   duration: how long the text stays on screen in milliseconds (default 1000 = 1 s).
;   Emoji and Unicode are supported; recommended <= 80 characters.
;
; [How it works]
;   Sends "OSD:text:duration" via WM_COPYDATA to the wm.ahk main window.
;   wm.ahk calls ShowOSD() internally, which renders the text center-screen.
;   Single call, instant display, auto-dismiss.
;
; [Bar widget vs. OSD]
;   - Bar widget: persistent on the status bar — ideal for ongoing info (clock, net speed, …)
;   - OSD: temporary center-screen popup — ideal for one-shot events (task done, error, …)
;   - Both use the same WM_COPYDATA channel; only the message prefix differs (BAR: vs OSD:)
;
; [Notes]
;   - OSD has anti-spam: rapid repeated calls may be coalesced.
;   - Long durations can interfere with workflow; <= 5000 ms recommended.
; ==============================================================================

AHK_WM_OSD("✅ Task completed!", 3000)
Sleep(3000)
ExitApp

; ------------------------------------------------------------------------------
; AHK_WM_OSD(text, duration) — reusable helper; copy into your own scripts as needed.
; ------------------------------------------------------------------------------
; Parameters:
;   text     - The text to display (Unicode & emoji supported).
;   duration - Display duration in milliseconds, default 1000.
; Returns: true = sent successfully, false = wm.ahk window not found.
;
; Implementation details:
;   1. Locate the (possibly hidden) wm.ahk main window via DetectHiddenWindows.
;   2. Build the message "OSD:text:duration".
;   3. Send WM_COPYDATA (0x4A) via SendMessage.
;   4. Payload is UTF-16 encoded to preserve emoji and CJK characters.
;
; Use cases:
;   - Script/task completion notifications (e.g. "Backup done")
;   - System event alerts (e.g. "WiFi connected")
;   - Keyboard shortcut visual feedback
;   - Debug/status confirmations (e.g. "Config reloaded")
; ------------------------------------------------------------------------------
AHK_WM_OSD(text, duration := 1000) {
    DetectHiddenWindows(true)
    h := WinExist("wm.ahk ahk_class AutoHotkey")
    if !h
        return false
    payload := "OSD:" . text . ":" . duration
    ; ---- Build COPYDATASTRUCT and send via SendMessage ----
    c := StrPut(payload, "UTF-16")                     ; UTF-16 byte count (incl. NUL)
    b := Buffer(A_PtrSize * 3, 0)                      ; COPYDATASTRUCT
    NumPut("Ptr", 0, b, 0)                             ; dwData (unused)
    NumPut("UInt", c, b, A_PtrSize)                    ; cbData (byte count)
    NumPut("Ptr", StrPtr(payload), b, A_PtrSize * 2)   ; lpData (points to message text)
    try SendMessage(0x4A, 0, b.Ptr, , "ahk_id " . h)   ; WM_COPYDATA
    return true
}
