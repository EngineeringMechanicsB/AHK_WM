#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
; ==============================================================================
; OSD Example — Keycast (show currently pressed keys in a screen corner)
; ==============================================================================
;
; [What this does]
;   Shows every key you are holding right now, like the key overlay in tutorial
;   videos. Keys appear as you press them and disappear when you release them.
;
; [Prerequisites]
;   1. AHK_WM (wm.ahk) must be running
;   2. Keep this script running
;
; [How it works]
;   A timer polls the key table every 30 ms with GetKeyState(key, "P") and builds
;   a string such as "Ctrl + Alt + A".  The OSD is only re-sent when the string
;   changes, so there is no pointless redraw.
;   The overlay uses duration=0 plus tag=keycast, so exactly one instance exists
;   at a time (a new OSD with the same tag replaces the old one).
;   When nothing is pressed it sends a blank overlay moved off-screen — the
;   equivalent of "hidden", with no leftover artifact.
;
; [Customization]
;   POLL_MS       Poll interval in ms.  Smaller = snappier, larger = lighter
;   OVERLAY_POS   Overlay position in px or %.  Default bottom-left
;   OVERLAY_STYLE Visual options: font, color, opacity, radius, ...
;   To change which keys are watched, edit the MODS and KEYS tables below
;
; [Exit] Ctrl+Alt+F12
; ==============================================================================

; ---- Tunables ----
global POLL_MS       := 30
global OVERLAY_POS   := "x=16%,y=88%"
global OVERLAY_STYLE := "fs=22,op=92,rd=on,rr=10,tag=keycast"

; ---- Modifiers: display name → physical key names (either side counts, shown once) ----
global MOD_ORDER := ["Ctrl", "Alt", "Shift", "Win"]
global MODS := Map(
    "Ctrl",  ["LControl", "RControl"],
    "Alt",   ["LAlt", "RAlt"],
    "Shift", ["LShift", "RShift"],
    "Win",   ["LWin", "RWin"]
)

; ---- Regular keys: key name → display label (insertion order = display order) ----
global KEYS := Map(
    "a", "A", "b", "B", "c", "C", "d", "D", "e", "E", "f", "F", "g", "G",
    "h", "H", "i", "I", "j", "J", "k", "K", "l", "L", "m", "M", "n", "N",
    "o", "O", "p", "P", "q", "Q", "r", "R", "s", "S", "t", "T", "u", "U",
    "v", "V", "w", "W", "x", "X", "y", "Y", "z", "Z",
    "0", "0", "1", "1", "2", "2", "3", "3", "4", "4", "5", "5",
    "6", "6", "7", "7", "8", "8", "9", "9",
    "F1", "F1", "F2", "F2", "F3", "F3", "F4", "F4", "F5", "F5", "F6", "F6",
    "F7", "F7", "F8", "F8", "F9", "F9", "F10", "F10", "F11", "F11", "F12", "F12",
    "Space", "Space", "Enter", "Enter", "Tab", "Tab", "Esc", "Esc",
    "Backspace", "Backspace", "Delete", "Delete", "Insert", "Insert",
    "Home", "Home", "End", "End", "PgUp", "PgUp", "PgDn", "PgDn",
    "Up", "↑", "Down", "↓", "Left", "←", "Right", "→",
    "CapsLock", "CapsLock", "-", "-", "=", "=", "``", "``",
    "[", "[", "]", "]", "\", "\", ";", ";", "'", "'",
    ",", ",", ".", ".", "/", "/"
)

; ---- For hiding: move the overlay off-screen and make it nearly transparent ----
global HIDE_OPTS := "x=-4000,y=-4000,fs=8,op=1,rd=on,rr=10,tag=keycast"

; ---- Main loop ----
global LAST_TEXT := " "   ; initial value = empty state, nothing sent at startup

Tick() {
    global MOD_ORDER, MODS, KEYS, LAST_TEXT, OVERLAY_POS, OVERLAY_STYLE, HIDE_OPTS

    parts := []
    for name in MOD_ORDER {
        for k in MODS[name] {
            if GetKeyState(k, "P") {
                parts.Push(name)
                break
            }
        }
    }
    for k, label in KEYS {
        if GetKeyState(k, "P")
            parts.Push(label)
    }

    if (parts.Length = 0) {
        if (LAST_TEXT = " ")
            return
        if AHK_WM_OSD(" ", 0, HIDE_OPTS)
            LAST_TEXT := " "
        return
    }

    text := ""
    for p in parts
        text .= (text = "" ? "" : " + ") . p

    if (text = LAST_TEXT)
        return
    if AHK_WM_OSD(text, 0, OVERLAY_POS "," OVERLAY_STYLE)
        LAST_TEXT := text
}

; ---- Remove the overlay before exiting (a duration=0 OSD never disappears by itself) ----
; Note: an OnExit callback that returns non-zero prevents the script from exiting (AHK v2),
; so use a function here rather than an arrow expression
OnExit(CleanUp)

CleanUp(*) {
    AHK_WM_OSD(" ", 0, HIDE_OPTS)
}

SetTimer(Tick, POLL_MS)
Tick()

^!F12::ExitApp

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
