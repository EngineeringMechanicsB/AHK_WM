#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
; ==============================================================================
; Bar 示例 3 — 双槽位歌词模拟（自包含协议）
; ==============================================================================
;
; 【功能说明】
;   使用两个 bar 槽位模拟歌词显示：
;     slot 1 — 歌名（小字单行）
;     slot 2 — 歌词（大字两行）
;   自包含协议——无需 Layout 配置。
;   每 3 秒切一句，每 5 句弹 OSD 进度。退出时自动清空 bar。
;
; 【歌曲】"Twinkle Twinkle Little Star"（公有领域·Jane Taylor 1806）
;
; 【操作】Esc — 退出
; ==============================================================================

global Lyrics := [
    "Twinkle, twinkle, little star",
    "How I wonder what you are",
    "Up above the world so high",
    "Like a diamond in the sky",
    "Twinkle, twinkle, little star",
    "How I wonder what you are",
    "When the blazing sun is gone",
    "When he nothing shines upon",
    "Then you show your little light",
    "Twinkle, twinkle, all the night",
    "Twinkle, twinkle, little star",
    "How I wonder what you are",
    "Then the traveler in the dark",
    "Thanks you for your tiny spark",
    "He could not see which way to go",
    "If you did not twinkle so"
]
global gIdx := 1
global gCounter := 0

PushLyrics() {
    global gIdx, gCounter, Lyrics
    gCounter++

    WMBarPushEx(1, "0.05/0.35", "Twinkle Twinkle Little Star", "tx=7AA2F7,fs=12")
    WMBarPushEx(2, "0.35/0.95", Lyrics[gIdx], "tx=CDD6F4,fs=16,wrap=2")

    if (Mod(gCounter, 5) = 0) {
        AHK_WM_OSD(Format("{}/{} 句已播放", gIdx, Lyrics.Length)
            , 2000, "fs=16,bg=1E1E2E,tx=9ECE6A,op=85,pos=80")
    }
    gIdx := Mod(gIdx, Lyrics.Length) + 1
}

PushLyrics()
SetTimer(PushLyrics, 3000)

; 退出清空两个槽位
OnExit(Cleanup)
Cleanup(*) {
    _WMSend("BAR:1::")
    _WMSend("BAR:2::")
}
Esc::ExitApp

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
    buf := Buffer(size, 0)
    StrPut(msg, buf, "UTF-16")
    cds := Buffer(A_PtrSize * 3, 0)
    NumPut("Ptr", 0, cds, 0)
    NumPut("UInt", size, cds, A_PtrSize)
    NumPut("Ptr", buf.Ptr, cds, A_PtrSize * 2)
    res := 0
    return DllCall("User32\SendMessageTimeoutW", "Ptr", h, "UInt", 0x4A
        , "Ptr", A_ScriptHwnd, "Ptr", cds.Ptr
        , "UInt", 0x2, "UInt", 2000, "UInt*", &res, "Ptr") ? true : false
}
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
