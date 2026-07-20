#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
; ==============================================================================
; Bar 示例 2 — 多行文本 + 自定义字体大小
; ==============================================================================
;
; 【功能说明】
;   每 5 秒向 bar 的 external_1 槽位推送一首两行诗词。
;   演示在 Layout 中配置 fs=N（字体大小覆盖）和 wrap=N（多行显示）。
;
; 【使用前提】
;   1. wm.ahk 必须正在运行
;   2. 在 [Bar] Layout 中为 external_1 添加 fs= 和 wrap=，例如：
;        Layout=external_1,(2-4)/5,CDD6F4,tx,fs=14,wrap=2;time,+20/20;
;      span "(2-4)/5" 占 bar 宽度的 40%，足够显示诗词
;   3. 修改后按 Alt+R 重载配置
;
; 【Layout 属性说明】
;   fs=N     — 该槽位的字体大小（磅），默认使用全局 Bar_FontSize
;   wrap=N   — 最大显示行数，0=单行（默认），>0=多行
;
;   当 wrap > 1 时：
;     - Bar 自动增高以容纳多行内容
;     - 文本中的 `n 换行符会渲染为独立行
;     - 不含换行符的长文本会在单词边界自动换行
;
;   Layout 配置示例：
;     external_1,1/3,FFAA00,tx,fs=12        ← 大字单行
;     external_1,1/3,FFAA00,tx,fs=14,wrap=2 ← 更大字两行
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
    WMBarPush(1, Poems[gIdx])
    gIdx := Mod(gIdx, Poems.Length) + 1
}

PushPoem()
SetTimer(PushPoem, 5000)
Esc::ExitApp

; ------------------------------------------------------------------------------
; WMBarPush(slot, text) —— 完整文档参见 bar-simple.ahk
; ------------------------------------------------------------------------------
WMBarPush(slot, text) {
    DetectHiddenWindows(true)
    h := WinExist("wm.ahk ahk_class AutoHotkey")
    if !h
        return false
    msg  := "BAR:" . slot . ":" . text
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
