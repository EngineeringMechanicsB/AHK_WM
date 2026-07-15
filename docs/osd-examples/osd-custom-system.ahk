#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
; ==============================================================================
; AHK_WM OSD 外部调用示例 3：窗口变化通知（标题 + 位置大小）
; ==============================================================================
; 【功能说明】
;   监视当前活动窗口的变化，每当切换窗口时弹出一条 OSD 通知，
;   显示新窗口的标题和位置/大小信息。
;   按 Esc 退出。按 Ctrl+F5 手动触发一次查询。
;
; 【使用前提】
;   1. AHK_WM (wm.ahk) 正在运行
;   2. 无需配置文件修改
;
; 【调用方式】
;   AHK_WM_OSD("要显示的文本", 持续时间毫秒)
;   本例在窗口切换时自动触发，也可手动按 Ctrl+F5 触发
;
; 【工作原理】
;   每 500ms 检查当前活动窗口句柄是否变化；
;   若变化则采集 WinTitle + WinGetPos + WinGetClass 信息；
;   格式化为多行文本通过 OSD 弹出（OSD 支持 `n 换行）。
;
; 【适用场景】
;   - 调试窗口布局问题（快速查看窗口坐标）
;   - 无障碍辅助（窗口切换时语音/文字提示当前窗口信息）
;   - 开发工具（确认窗口类名和进程名）
;
; 【注意】
;   按 Esc 键退出本脚本
; ==============================================================================

global LastHwnd := 0

CheckWindow() {
    global LastHwnd
    hwnd := 0
    try hwnd := WinExist("A")
    if (!hwnd || hwnd = LastHwnd)
        return
    LastHwnd := hwnd

    ; ---- 采集窗口信息 ----
    title := ""
    try title := WinGetTitle(hwnd)
    if (title = "")
        title := "(untitled)"
    if (StrLen(title) > 30)
        title := SubStr(title, 1, 29) . "…"

    cls := ""
    try cls := WinGetClass(hwnd)

    proc := ""
    try proc := WinGetProcessName(hwnd)

    try WinGetPos(&x, &y, &w, &h, hwnd)

    ; ---- 格式化多行 OSD ----
    text := Format("[{}]`nClass: {}  Proc: {}`nPos: ({},{})  Size: {}x{}"
        , title, cls, proc, x, y, w, h)
    AHK_WM_OSD(text, 2500)
}

SetTimer(CheckWindow, 500)
^F5::CheckWindow()               ; 手动触发 / Manual trigger
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
