#Requires AutoHotkey v2.0
; ==============================================================================
; AHK_WM OSD 外部调用测试 / External OSD Test
; ==============================================================================

#Include "wm_osd_helper.ahk"

DetectHiddenWindows(true)

hwnd := WinExist("wm.ahk ahk_class AutoHotkey")
if hwnd {
    title := WinGetTitle(hwnd)
    MsgBox("找到 AHK_WM 主窗口！`nhwnd=" . hwnd . "`ntitle=" . title . "`n`n开始 OSD 测试...")
} else {
    MsgBox("未找到 AHK_WM 窗口！`n`n请确认 AHK_WM 已启动（运行 wm.ahk）")
    ExitApp()
}

AHK_WM_OSD("Hello from external script!")
Sleep(1500)
AHK_WM_OSD("这条消息显示 3 秒", 3000)
Sleep(3500)
AHK_WM_OSD("外部脚本调用成功！")
Sleep(1500)

MsgBox("OSD 测试完成！")
ExitApp()
