; ===============================
; Simple suckless virtual desktop
; ===============================
;#####脚本由测试组张栩玮制作#####
#SingleInstance Force
#Persistent
#NoEnv
SetBatchLines, -1
SetWorkingDir %A_ScriptDir%
CoordMode, Mouse, Screen
SendMode Input
SetTitleMatchMode 2
#WinActivateForce
SetControlDelay 1
SetWinDelay 0
SetKeyDelay -1
SetMouseDelay -1
SetTitleMatchMode, 2

; -------- 全局状态 --------
global CurrentDesktop := 1
global Desktops := {}

DesktopCount := 3

Loop %DesktopCount%
    Desktops[A_Index] := []

; -------- 获取当前可见窗口 --------
GetVisibleWindows() {
    WinGet, winList, List
    windows := []

    Loop % winList {
        hwnd := winList%A_Index%

        ; 跳过桌面和任务栏
        WinGetClass, class, ahk_id %hwnd%
        if (class = "Progman" || class = "Shell_TrayWnd")
            continue

        WinGet, style, Style, ahk_id %hwnd%
        ; WS_VISIBLE = 0x10000000
        if (style & 0x10000000)
            windows.Push(hwnd)
    }
    return windows
}

; -------- 切换桌面 --------
SwitchDesktop(target) {
    global CurrentDesktop, Desktops

    if (target = CurrentDesktop)
        return

    ; 保存当前桌面窗口
    Desktops[CurrentDesktop] := GetVisibleWindows()

    ; 隐藏当前桌面窗口
    for _, hwnd in Desktops[CurrentDesktop] {
        WinHide, ahk_id %hwnd%
    }

    ; 显示目标桌面窗口
    for _, hwnd in Desktops[target] {
        WinShow, ahk_id %hwnd%
    }

    ; 激活一个窗口（如果有）
    if (Desktops[target].Length() > 0) {
        hwnd := Desktops[target][1]
        WinActivate, ahk_id %hwnd%
    }

    CurrentDesktop := target
}

; -------- 快捷键 --------
!1::SwitchDesktop(1)
!2::SwitchDesktop(2)
!3::SwitchDesktop(3)

; -------- 可选：新窗口自动加入当前桌面 --------
#IfWinActive
~LButton::
    Sleep, 100
    hwnd := WinExist("A")
    if (hwnd) {
        Desktops[CurrentDesktop].Push(hwnd)
    }
return
