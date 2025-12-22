#NoEnv
#SingleInstance Force
SetTitleMatchMode, 2

global CurrentDesktop := 1
global DesktopCount := 9
global Desktops := {}
global AlwaysVisible := {}

Loop %DesktopCount%
    Desktops[A_Index] := []

GetAllWindows() {
    WinGet, winList, List
    windows := []
    Loop % winList {
        hwnd := winList%A_Index%
        WinGetClass, class, ahk_id %hwnd%
        if (class = "Progman" || class = "Shell_TrayWnd")
            continue
        windows.Push(hwnd)
    }
    return windows
}

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

RemoveWindowFromDesktop(desktop, hwnd) {
    global Desktops
    newList := []
    for _, h in Desktops[desktop]
        if (h != hwnd)
            newList.Push(h)
    Desktops[desktop] := newList
}

RemoveWindowFromAllDesktops(hwnd) {
    global Desktops, DesktopCount
    Loop %DesktopCount%
        RemoveWindowFromDesktop(A_Index, hwnd)
}

SwitchDesktop(target) {
    global CurrentDesktop, Desktops, AlwaysVisible
    if (target = CurrentDesktop)
        return
    Desktops[CurrentDesktop] := GetVisibleWindows()
    for _, hwnd in Desktops[CurrentDesktop]
        if (!AlwaysVisible.HasKey(hwnd))
            WinHide, ahk_id %hwnd%
    for _, hwnd in Desktops[target]
        WinShow, ahk_id %hwnd%
    for hwnd, _ in AlwaysVisible
        WinShow, ahk_id %hwnd%
    if (Desktops[target].Length() > 0) {
        hwnd := Desktops[target][1]
        WinActivate, ahk_id %hwnd%
    }
    CurrentDesktop := target
}

MoveWindowToDesktop(target) {
    global CurrentDesktop, Desktops, AlwaysVisible
    hwnd := WinExist("A")
    if (!hwnd)
        return
    if (AlwaysVisible.HasKey(hwnd))
        AlwaysVisible.Delete(hwnd)
    RemoveWindowFromAllDesktops(hwnd)
    Desktops[target].Push(hwnd)
    if (target != CurrentDesktop)
        WinHide, ahk_id %hwnd%
}

MoveAndSwitch(target) {
    MoveWindowToDesktop(target)
    SwitchDesktop(target)
}

GatherAllToCurrentDesktop() {
    global CurrentDesktop, Desktops, AlwaysVisible
    Desktops[CurrentDesktop] := []
    for _, hwnd in GetAllWindows() {
        RemoveWindowFromAllDesktops(hwnd)
        Desktops[CurrentDesktop].Push(hwnd)
        WinShow, ahk_id %hwnd%
    }
    AlwaysVisible := {}
}

ToggleAlwaysVisible() {
    global AlwaysVisible
    hwnd := WinExist("A")
    if (!hwnd)
        return
    if (AlwaysVisible.HasKey(hwnd)) {
        AlwaysVisible.Delete(hwnd)
    } else {
        AlwaysVisible[hwnd] := true
        WinShow, ahk_id %hwnd%
    }
}

CleanupAndExit() {
    for _, hwnd in GetAllWindows()
        WinShow, ahk_id %hwnd%
    ExitApp
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

^!1::MoveAndSwitch(1)
^!2::MoveAndSwitch(2)
^!3::MoveAndSwitch(3)
^!4::MoveAndSwitch(4)
^!5::MoveAndSwitch(5)
^!6::MoveAndSwitch(6)
^!7::MoveAndSwitch(7)
^!8::MoveAndSwitch(8)
^!9::MoveAndSwitch(9)

!+g::GatherAllToCurrentDesktop()
^!t::ToggleAlwaysVisible()
!F12::CleanupAndExit()