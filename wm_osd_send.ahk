#Requires AutoHotkey v2.0
; ==============================================================================
; AHK_WM OSD 单脚本发送器
; 用法1（双击运行后用输入框输入消息）
; 用法2（命令行）: AutoHotkey64.exe wm_osd_send.ahk "你的消息" 2000
; 用法3（粘贴到你自己的脚本里）: 复制下方 AHK_WM_OSD 函数即可，无需 #Include
; ==============================================================================

; ---- 核心函数（复制此函数到任何脚本即可使用）----
AHK_WM_OSD(text, duration := 1000) {
    DetectHiddenWindows(true)
    h := WinExist("wm.ahk ahk_class AutoHotkey")
    if !h
        return false
    p := "OSD:" . text . ":" . duration
    c := StrPut(p, "UTF-16")
    b := Buffer(A_PtrSize * 3, 0)
    NumPut("Ptr", 0, b, 0)
    NumPut("UInt", c, b, A_PtrSize)
    NumPut("Ptr", StrPtr(p), b, A_PtrSize * 2)
    try {
        SendMessage(0x4A, 0, b.Ptr, , "ahk_id " . h)
        return true
    }
    return false
}

; ---- 直接运行时 / Standalone mode ----
if (A_Args.Length > 0) {
    ; 命令行模式
    txt := A_Args[1]
    dur := (A_Args.Length > 1) ? Integer(A_Args[2]) : 1000
    AHK_WM_OSD(txt, dur)
} else {
    ; 交互模式
    ib := InputBox("输入 OSD 消息", "AHK_WM OSD Sender", "w300 h100")
    if (ib.Result = "OK" && ib.Value != "")
        AHK_WM_OSD(ib.Value, 2000)
}
ExitApp()
