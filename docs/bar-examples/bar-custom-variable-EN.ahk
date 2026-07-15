#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
; ==============================================================================
; AHK_WM Bar External Widget Example 2: Dynamic Variable (Symbol Rotation + Counter)
; ==============================================================================
; [What this does]
;   Pushes continuously-changing content to the external_2 slot of the AHK_WM bar.
;   The left side shows a cycling symbol (creating a visual "animation" effect),
;   while the right side shows an incrementing number, clearly demonstrating
;   dynamic update capability.
;   Display example:  ◉ 42  → (1 s) →  ◉ 43  …  ◎ 100  →  ◎ 101 …
;
; [Prerequisites]
;   1. AHK_WM (wm.ahk) must be running.
;   2. Your config [Bar] Layout must include an external_2 widget, e.g.:
;        Layout=desktops,(1-3)/20;external_2,(13-15)/20,7AA2F7,9ECE6A,tx;time,20/20;
;      The "tx" mode (gradient text) + dual colors is recommended for a dynamic feel.
;
; [How it works]
;   PushTick() runs every 1 second via SetTimer:
;     1. The symbol cycles every 3 ticks (◉ → ◈ → ◆ → ◎ → ◉ …) for visual variety
;     2. The counter increments continuously (1, 2, 3, …) showing real-time updates
;     3. The counter wraps back to 0 every 100, simulating a "cycle counter"
;   Uses SetTimer for scheduling — no manual loop needed.
;
; [How to call]
;   WMBarPush(slot, "text to display")
;   Call it inside a SetTimer callback for periodic updates.
;   Recommended interval >= 500 ms to allow the bar time to render.
;
; [Extension ideas]
;   - Replace the number with CPU/memory usage → system monitor
;   - Replace the symbol with weather icons + temperature → weather display
;   - Replace the number with a countdown → pomodoro timer
;   - Replace the symbol with play-state icons + song name → music player
;
; [Notes]
;   - Exiting this script leaves the last pushed value on the bar.
;   - SetTimer callbacks run on independent threads and do not block each other.
;   - Counter is initialized outside the function; the function accesses it via `global`.
; ==============================================================================

; ---- Global state ----
; Counter: incrementing value, +1 per PushTick call
; SymbolIdx: index into the symbol array, advances every 3 increments
global Counter := 0
global SymbolIdx := 1
; Pool of cycling symbols
global Symbols := ["◉", "◈", "◆", "◎"]

; ---- Periodic push callback ----
; Triggered every 1000 ms by SetTimer
PushTick() {
    global Counter, SymbolIdx, Symbols
    Counter++
    ; Change symbol every 3 ticks for a "slow rotation" visual effect
    if (Mod(Counter, 3) = 0)
        SymbolIdx := Mod(SymbolIdx, Symbols.Length) + 1
    sym := Symbols[SymbolIdx]
    ; Wrap counter every 100 for a cycle effect
    val := Mod(Counter, 100)
    ; Format: symbol + space-padded number (e.g. "◉ 42")
    WMBarPush(2, Format("{} {:3d}", sym, val))
}

PushTick()                        ; Push the first value immediately
SetTimer(PushTick, 1000)          ; Then update every 1 second

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
