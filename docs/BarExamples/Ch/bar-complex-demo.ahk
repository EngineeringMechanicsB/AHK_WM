#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
; ==============================================================================
; Bar 示例 3 — 双槽位动态歌词模拟器（自包含协议）
; ==============================================================================
;
; 【功能说明】
;   模拟音乐播放器歌词显示，使用两个 bar 槽位：
;     slot 1 — 歌名（小字单行）
;     slot 2 — 当前歌词（大字两行换行）
;   使用自包含协议——无需 Layout 配置。
;
;   歌词每 3 秒自动切换到下一句。每 5 句，弹出一条 OSD 显示进度。
;
; 【歌曲】"Hey Jude" — The Beatles
;
; 【操作】Esc — 退出
; ==============================================================================

global Lyrics := [
    "Hey Jude, don't make it bad",
    "Take a sad song and make it better",
    "Remember to let her into your heart",
    "Then you can start to make it better",
    "Hey Jude, don't be afraid",
    "You were made to go out and get her",
    "The minute you let her under your skin",
    "Then you begin to make it better",
    "And anytime you feel the pain",
    "Hey Jude, refrain",
    "Don't carry the world upon your shoulders",
    "For well you know that it's a fool",
    "Who plays it cool",
    "By making his world a little colder",
    "Na na na na na na na na na",
    "Hey Jude..."
]
global gIdx := 1
global gCounter := 0

PushLyrics() {
    global gIdx, gCounter, Lyrics
    gCounter++

    ; 槽位 1：歌名 — 小字单行
    WMBarPushEx(1, "0.05/0.35", "🎵 Hey Jude — The Beatles", "tx=7AA2F7,fs=12")

    ; 槽位 2：当前歌词 — 大字两行
    WMBarPushEx(2, "0.35/0.95", Lyrics[gIdx], "tx=CDD6F4,fs=16,wrap=2")

    ; 每 5 句弹 OSD 显示进度
    if (Mod(gCounter, 5) = 0) {
        AHK_WM_OSD(Format("已播放 {}/{} 句", gIdx, Lyrics.Length)
            , 2000, "fs=16,bg=1E1E2E,tx=9ECE6A,op=85,pos=80")
    }

    gIdx := Mod(gIdx, Lyrics.Length) + 1
}

PushLyrics()
SetTimer(PushLyrics, 3000)
Esc::ExitApp

; ------------------------------------------------------------------------------
; WMBarPushEx(slot, loHi, text, opts) — 自包含协议，详细文档见 bar-simple.ahk
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

; ------------------------------------------------------------------------------
; AHK_WM_OSD(text, duration, opts) — 详细文档见 OSDExamples/Ch/osd-custom-all.ahk
; ------------------------------------------------------------------------------
AHK_WM_OSD(text, duration := 1000, opts := "") {
    DetectHiddenWindows(true)
    h := WinExist("wm.ahk ahk_class AutoHotkey")
    if !h
        return false
    payload := "OSD:" . text . ":" . duration
    if (opts != "")
        payload .= ":" . opts
    c := StrPut(payload, "UTF-16")
    b := Buffer(A_PtrSize * 3, 0)
    NumPut("Ptr", 0, b, 0)
    NumPut("UInt", c, b, A_PtrSize)
    NumPut("Ptr", StrPtr(payload), b, A_PtrSize * 2)
    try SendMessage(0x4A, 0, b.Ptr, , "ahk_id " . h)
    return true
}
