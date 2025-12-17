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

global CurrentDesktop := 1
global Desktops := {}
DesktopCount := 9

Loop %DesktopCount%
    Desktops[A_Index] := []

GetVisibleWindows() {
    WinGet, winList, List
    windows := []
    Loop % winList {
        hwnd := winList%A_Index%
        WinGetClass, class, ahk_id %hwnd%
        if (class = "Progman" || class = "Shell_TrayWnd")
            continue
        WinGet, style, Style, ahk_id %hwnd%
        if (style & 0x10000000)
            windows.Push(hwnd)
    }
    return windows
}

SwitchDesktop(target) {
    global CurrentDesktop, Desktops
    if (target = CurrentDesktop)
        return
    Desktops[CurrentDesktop] := GetVisibleWindows()
    for _, hwnd in Desktops[CurrentDesktop]
        WinHide, ahk_id %hwnd%
    for _, hwnd in Desktops[target]
        WinShow, ahk_id %hwnd%
    if (Desktops[target].Length() > 0) {
        hwnd := Desktops[target][1]
        WinActivate, ahk_id %hwnd%
    }
    CurrentDesktop := target
}

RemoveWindowFromDesktop(desktop, hwnd) {
    global Desktops
    newList := []
    for _, h in Desktops[desktop]
        if (h != hwnd)
            newList.Push(h)
    Desktops[desktop] := newList
}

MoveWindowToDesktop(target) {
    global CurrentDesktop, Desktops
    hwnd := WinExist("A")
    if (!hwnd)
        return
    RemoveWindowFromDesktop(CurrentDesktop, hwnd)
    Desktops[target].Push(hwnd)
    if (target != CurrentDesktop)
        WinHide, ahk_id %hwnd%
}

!1::SwitchDesktop(1)
!2::SwitchDesktop(2)
!3::SwitchDesktop(3)
!4::SwitchDesktop(4)
!5::SwitchDesktop(5)
!6::SwitchDesktop(6)
!7::SwitchDesktop(7)
!8::SwitchDesktop(8)
!9::SwitchDesktop(9)

!+1::MoveWindowToDesktop(1)
!+2::MoveWindowToDesktop(2)
!+3::MoveWindowToDesktop(3)
!+4::MoveWindowToDesktop(4)
!+5::MoveWindowToDesktop(5)
!+6::MoveWindowToDesktop(6)
!+7::MoveWindowToDesktop(7)
!+8::MoveWindowToDesktop(8)
!+9::MoveWindowToDesktop(9)
