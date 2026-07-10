#Requires AutoHotkey v2.0
; ==============================================================================
; AHK_WM OSD 外部调用辅助 / External OSD Helper
; ==============================================================================
; 用法:
;   1. #Include 此文件，调用 AHK_WM_OSD("消息文本", 显示毫秒)
;   2. 或直接复制函数到你的脚本中
;
; 前置条件: AHK_WM 必须正在运行
; 原理: 查找主窗口（标题含 wm.ahk，类 AutoHotkey），发送 WM_COPYDATA
; ==============================================================================

AHK_WM_OSD(text, duration := 1000) {
    DetectHiddenWindows(true)
    ; AHK v2 主窗口标题默认是脚本完整路径，含脚本文件名
    wmHwnd := WinExist("wm.ahk ahk_class AutoHotkey")
    if !wmHwnd
        return false

    payload := "OSD:" . text . ":" . duration
    cbData := StrPut(payload, "UTF-16")
    cds := Buffer(A_PtrSize * 3, 0)
    NumPut("Ptr", 0, cds, 0)
    NumPut("UInt", cbData, cds, A_PtrSize)
    NumPut("Ptr", StrPtr(payload), cds, A_PtrSize * 2)
    try {
        SendMessage(0x4A, 0, cds.Ptr, , "ahk_id " . wmHwnd)
        return true
    }
    return false
}
