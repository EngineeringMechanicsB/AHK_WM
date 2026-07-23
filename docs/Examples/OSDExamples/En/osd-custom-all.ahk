#Requires AutoHotkey v2.0
#SingleInstance Force
; ==============================================================================
; OSD Example 2 — Full Per-Call Customization Demo
; ==============================================================================
;
; [What this does]
;   Pops up OSD notifications in sequence, each with different visual
;   overrides to demonstrate ALL available per-call customization keys.
;
; [Available override keys]
;   fs  — Font size in points       (default: OSDFontSize from config, 20)
;   op  — Opacity percentage        (default: OSDOpacity from config, 78)
;   pos — Vertical position %       (default: OSDPositionPct from config, 80)
;   x   — Horizontal pos px or %    (default: center)        e.g. x=300 x=50%
;   y   — Vertical pos px or %      (default: pos or config) e.g. y=200 y=30%
;   bg  — Background color (6-hex)  (default: theme Color_Bg)
;   tx  — Text color (6-hex)        (default: theme Color_Active)
;   wr  — Max width in pixels       (default: 85% of monitor width)
;   rd  — Rounded corners on/off    (default: OSDRounded from config)
;   rr  — Corner radius in pixels   (default: OSDRadius from config)
;   fn  — Font face name            (default: FontName from config)
;   tag — Logical tag for replacing previous OSD with same tag (see osd-complex-demo)
;
;   ALL keys are optional.  Missing keys fall back to wm_config.ini values.
;   Existing scripts that don't pass opts continue to work unchanged.
;
; [Message format with overrides]
;   OSD:<text>:<duration_ms>:fs=36,op=95,bg=CC3333,tx=FFFFFF,pos=30
;
; [Usage]
;   Double-click and watch 7 different OSD styles appear in sequence.
; ==============================================================================

; --- 1. Large red warning near the top ---
AHK_WM_OSD("⚠️ WARNING: Disk space low!", 3000, "fs=36,bg=CC3333,tx=FFFFFF,op=95,pos=30")
Sleep(3500)

; --- 2. Small green success near the bottom ---
AHK_WM_OSD("✅ Backup complete (2.3 GB)", 3000, "fs=14,bg=33AA55,tx=FFFFFF,op=85,pos=92")
Sleep(3500)

; --- 3. Semi-transparent purple, upper-middle ---
AHK_WM_OSD("🎵 Now Playing: Hey Jude - The Beatles", 3000, "fs=24,bg=A020F0,tx=FFFFFF,op=70,pos=40")
Sleep(3500)

; --- 4. Narrow width with multi-line auto-wrap ---
AHK_WM_OSD("This is a long sentence that will auto-wrap because the max width is limited to 300 pixels.", 4000, "fs=16,bg=1E1E2E,tx=CDD6F4,wr=300,pos=60")
Sleep(4500)

; --- 5. Sharp rectangle — no rounded corners ---
AHK_WM_OSD("Sharp corners — no rounding", 3000, "fs=20,bg=444444,tx=FFD700,rd=off,pos=50")
Sleep(3500)

; --- 6. Large rounded corners ---
AHK_WM_OSD("Large rounded corners — radius=30px", 3000, "fs=20,bg=2E2E4E,tx=7AA2F7,rr=30,pos=50")
Sleep(3500)

; --- 7. Custom font + high transparency ---
AHK_WM_OSD("Consolas font | Semi-transparent", 3000, "fs=18,bg=0E050F,tx=9ECE6A,op=60,fn=Consolas,pos=70")
Sleep(3500)

; --- 8. Pixel-positioned (x=300 from left, y=60% from top) ---
AHK_WM_OSD("x=300, y=60% — pixel + percent", 2500, "fs=20,bg=2E5E8E,tx=FFF,x=300,y=60%")
Sleep(3000)

; --- 9. Both axes as percentages ---
AHK_WM_OSD("x=40%, y=30% — both percent", 2500, "fs=22,bg=5E2E8E,tx=FFF,x=40%,y=30%")
Sleep(3000)

ExitApp

; ------------------------------------------------------------------------------
; AHK_WM_OSD(text, duration, opts)
;
;   Generic helper — copy this function into your own scripts.
;
;   Parameters:
;     text     — Text to display (UTF-8, supports emoji / Chinese / any Unicode).
;     duration — Display duration in milliseconds.  Default 1000.
;     opts     — (Optional) Per-call visual overrides as "key=value,key=value".
;                All keys optional.  Unspecified keys use wm_config.ini defaults.
;
;   Available opts keys (all optional):
;     fs=N   — Font size in pt (default: config OSDFontSize)
;     op=N   — Opacity 0-100 (default: config OSDOpacity)
;     pos=N  — Vertical position % (default: config OSDPositionPct)
;     x=N[%] — Horizontal position, px or % (default: center)
;     y=N[%] — Vertical position, px or % (default: pos or config)
;     bg=RRGGBB — Background color hex (default: theme Color_Bg)
;     tx=RRGGBB — Text color hex (default: theme Color_Active)
;     wr=N   — Max width in px, auto-wraps if exceeded (default: monW*0.85)
;     rd=on|off — Rounded corners (default: config OSDRounded)
;     rr=N   — Corner radius in px (default: config OSDRadius)
;     fn=Name — Font face name (default: config FontName)
;     tag=ID — Logical tag; new OSD with same tag replaces the old one
;
;   Returns: true = sent, false = wm.ahk not found.
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
