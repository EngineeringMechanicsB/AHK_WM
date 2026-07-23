#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
; ==============================================================================
; OSD 示例 3 — 动态内容：歌词逐句播放器
; ==============================================================================
;
; 【功能说明】
;   模拟歌词显示——逐句播放歌曲，每句以自定义风格的 OSD 弹出。
;   使用 "tag=lyrics" 键，每次新句自动替换旧句，不会出现多个弹窗堆积。
;
;   按 Space 演示多实例共存：同时弹出 3 条不同颜色/位置的 OSD（不同 tag）。
;
; 【歌曲】
;   "Hey Jude" — The Beatles，全世界耳熟能详的经典。
;
; 【操作方式】
;   ↑ / ↓ 方向键 — 上一句 / 下一句歌词
;   Space        — 同时弹出 3 条不同位置的 OSD（多实例共存演示）
;   Esc          — 退出
;
; 【演示的核心概念】
;   1. tag="lyrics" → 每句新歌词替换旧句（替换模式，无堆积）
;   2. 不同 tag / 无 tag → 多实例共存（Space 演示）
;   3. 外部 OSD 与 wm.ahk 内部 OSD 实例隔离，互不干扰
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

; ---- 显示当前歌词句（tag="lyrics" 确保替换而非堆积）----
ShowCurrent() {
    global gIdx, Lyrics
    text := Lyrics[gIdx]
    ; tag=lyrics 确保新句销毁旧句——不会出现多个弹窗堆积
    AHK_WM_OSD(text, 2500, "fs=28,bg=A020F0,tx=FFFFFF,op=82,pos=85,tag=lyrics")
}

; ---- 翻页 ----
Up:: {
    global gIdx, Lyrics
    gIdx := (gIdx > 1) ? gIdx - 1 : Lyrics.Length
    ShowCurrent()
}
Down:: {
    global gIdx, Lyrics
    gIdx := (gIdx < Lyrics.Length) ? gIdx + 1 : 1
    ShowCurrent()
}

; ---- 多实例共存演示：3 条不同位置/颜色的 OSD 同时显示 ----
Space:: {
    ; 三条不同 tag，各自独立，同时存在
    AHK_WM_OSD("顶部通知",   3000, "fs=16,bg=CC3333,tx=FFFFFF,op=90,pos=15,tag=demo1")
    Sleep(200)
    AHK_WM_OSD("中部通知",   3000, "fs=16,bg=33AA55,tx=FFFFFF,op=90,pos=50,tag=demo2")
    Sleep(200)
    AHK_WM_OSD("底部通知",   3000, "fs=16,bg=3355CC,tx=FFFFFF,op=90,pos=85,tag=demo3")
}

; 退出：托盘右键 → Exit（Esc 太常用，不绑）

; ------------------------------------------------------------------------------
; AHK_WM_OSD(text, duration, opts) —— 参见 osd-custom-all.ahk 完整参数文档
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

ShowCurrent()
