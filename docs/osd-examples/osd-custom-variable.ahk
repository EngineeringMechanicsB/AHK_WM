#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
; ==============================================================================
; AHK_WM OSD 外部调用示例 2：动态变量通知（符号轮换 + 数值递增）
; ==============================================================================
; 【功能说明】
;   每 2 秒弹出一条 OSD 通知，左侧符号轮换（◉→◈→◆→◎），右侧数值递增。
;   展示 OSD 的周期性调用能力——适合定期状态提醒。
;   按 Esc 退出。
;
; 【使用前提】
;   1. AHK_WM (wm.ahk) 正在运行
;   2. 无需配置文件修改
;
; 【调用方式】
;   AHK_WM_OSD("要显示的文本", 持续时间毫秒)
;   在 SetTimer 回调中调用实现周期性弹出
;   OSD 有防刷机制，建议间隔 >= 2000ms
;
; 【与 Bar 变量的区别】
;   - Bar 变量 (bar-custom-variant): 持续显示在状态栏，适合常驻信息
;   - OSD 变量 (本脚本): 周期性弹出到屏幕中央，适合阶段性提醒（如"已运行30分钟"）
;
; 【注意】
;   按 Esc 键退出本脚本
; ==============================================================================

global Counter := 0
global SymbolIdx := 1
global Symbols := ["◉", "◈", "◆", "◎"]

PushTick() {
    global Counter, SymbolIdx, Symbols
    Counter++
    if (Mod(Counter, 3) = 0)
        SymbolIdx := Mod(SymbolIdx, Symbols.Length) + 1
    sym := Symbols[SymbolIdx]
    val := Mod(Counter, 100)
    AHK_WM_OSD(Format("{} 计数: {:3d}", sym, val), 1500)
}

PushTick()
SetTimer(PushTick, 2000)
Esc::ExitApp

AHK_WM_OSD(text, duration := 1000) {
    DetectHiddenWindows(true)
    h := WinExist("wm.ahk ahk_class AutoHotkey")
    if !h
        return false
    payload := "OSD:" . text . ":" . duration
    c := StrPut(payload, "UTF-16")
    b := Buffer(A_PtrSize * 3, 0)
    NumPut("Ptr", 0, b, 0)
    NumPut("UInt", c, b, A_PtrSize)
    NumPut("Ptr", StrPtr(payload), b, A_PtrSize * 2)
    try SendMessage(0x4A, 0, b.Ptr, , "ahk_id " . h)
    return true
}
