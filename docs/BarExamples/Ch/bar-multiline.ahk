#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
; ==============================================================================
; Bar 示例 2 — 多行文本 + 自定义字体大小（自包含协议）
; ==============================================================================
;
; 【功能说明】
;   每 5 秒推送一首两行诗词，使用新版自包含协议。无需 Layout 配置——
;   位置、颜色、字体、换行全部在推送时直接传递。
;
;   fs=N     — 字体大小 pt
;   wrap=N   — 最大行数（>1 多行，bar 自动增高）
;   `n       — 文本中的换行符渲染为独立行
;
; 【操作】
;   Esc — 退出
; ==============================================================================

global Poems := [
    "床前明月光`n疑是地上霜",
    "举头望明月`n低头思故乡",
    "白日依山尽`n黄河入海流",
    "欲穷千里目`n更上一层楼"
]
global gIdx := 1

PushPoem() {
    global gIdx, Poems
    ; 自包含推送：跨度+颜色+字体+换行，一次搞定
    WMBarPushEx(1, "0.3/0.9", Poems[gIdx], "tx=CDD6F4,fs=14,wrap=2")
    gIdx := Mod(gIdx, Poems.Length) + 1
}

PushPoem()
SetTimer(PushPoem, 5000)
Esc::ExitApp

; ------------------------------------------------------------------------------
; 辅助函数 —— 详细文档参见 bar-simple.ahk
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
