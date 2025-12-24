#Requires AutoHotkey v2.0
#SingleInstance Force
#WinActivateForce

; --- 环境设置 ---
SetWorkingDir(A_ScriptDir)
CoordMode("Mouse", "Screen")
SendMode("Input")
SetTitleMatchMode(2)
SetControlDelay(1)
SetWinDelay(0)
SetKeyDelay(-1)
SetMouseDelay(-1)

; --- 全局变量 ---
global CurrentDesktop := 1
global DesktopCount := 9
global Desktops := Map()
global AlwaysVisible := Map()

; 初始化桌面数组
Loop DesktopCount {
    Desktops[A_Index] := []
}

; --- 核心函数 ---

GetAllWindows() {
    list := WinGetList()
    windows := []
    for hwnd in list {
        try {
            class := WinGetClass("ahk_id " hwnd)
            if (class == "Progman" || class == "Shell_TrayWnd")
                continue
            windows.Push(hwnd)
        }
    }
    return windows
}

GetVisibleWindows() {
    list := WinGetList()
    windows := []
    for hwnd in list {
        try {
            class := WinGetClass("ahk_id " hwnd)
            if (class == "Progman" || class == "Shell_TrayWnd")
                continue
            
            minmax := WinGetMinMax("ahk_id " hwnd)
            if (minmax != -1) 
                windows.Push(hwnd)
        }
    }
    return windows
}

RemoveWindowFromDesktop(desktop, hwnd) {
    global Desktops
    newList := []
    if Desktops.Has(desktop) {
        for h in Desktops[desktop] {
            if (h != hwnd)
                newList.Push(h)
        }
        Desktops[desktop] := newList
    }
}

RemoveWindowFromAllDesktops(hwnd) {
    global DesktopCount
    Loop DesktopCount {
        RemoveWindowFromDesktop(A_Index, hwnd)
    }
}

; 注意：这里加了 * 号来忽略 Hotkey 自动传入的第二个参数
SwitchDesktop(target, *) {
    global CurrentDesktop, Desktops, AlwaysVisible
    
    if (target == CurrentDesktop)
        return

    Desktops[CurrentDesktop] := GetVisibleWindows()

    for hwnd in Desktops[CurrentDesktop] {
        if (!AlwaysVisible.Has(hwnd)) {
            try WinMinimize("ahk_id " hwnd)
        }
    }

    for hwnd in Desktops[target] {
        try WinRestore("ahk_id " hwnd)
    }

    for hwnd, _ in AlwaysVisible {
        try WinRestore("ahk_id " hwnd)
    }

    if (Desktops[target].Length > 0) {
        hwnd := Desktops[target][1]
        try WinActivate("ahk_id " hwnd)
    }

    CurrentDesktop := target
}

; 注意：这里加了 * 号
MoveWindowToDesktop(target, *) {
    global CurrentDesktop, Desktops, AlwaysVisible
    
    try {
        hwnd := WinExist("A")
    } catch {
        return
    }

    if (!hwnd)
        return

    if (AlwaysVisible.Has(hwnd))
        AlwaysVisible.Delete(hwnd)

    RemoveWindowFromAllDesktops(hwnd)
    
    if !Desktops.Has(target)
        Desktops[target] := []
        
    Desktops[target].Push(hwnd)

    if (target != CurrentDesktop) {
        try WinMinimize("ahk_id " hwnd)
    }
}

; 注意：这里加了 * 号
MoveAndSwitch(target, *) {
    MoveWindowToDesktop(target)
    SwitchDesktop(target)
}

GatherAllToCurrentDesktop(*) {
    global CurrentDesktop, Desktops, AlwaysVisible
    
    Desktops[CurrentDesktop] := []
    
    for hwnd in GetAllWindows() {
        RemoveWindowFromAllDesktops(hwnd)
        Desktops[CurrentDesktop].Push(hwnd)
        try WinRestore("ahk_id " hwnd)
    }
    AlwaysVisible.Clear()
}

ToggleAlwaysVisible(*) {
    global AlwaysVisible
    try {
        hwnd := WinExist("A")
    } catch {
        return
    }

    if (!hwnd)
        return

    if (AlwaysVisible.Has(hwnd)) {
        AlwaysVisible.Delete(hwnd)
    } else {
        AlwaysVisible[hwnd] := true
        try WinRestore("ahk_id " hwnd)
    }
}

CleanupAndExit(*) {
    for hwnd in GetAllWindows() {
        try WinRestore("ahk_id " hwnd)
    }
    ExitApp
}

; --- 热键绑定 ---

Loop 9 {
    i := A_Index
    ; Bind(i) 会把 i 作为第一个参数，Hotkey 命令会自动把热键名作为第二个参数传入
    ; 所以上面的函数定义里都加了 * 来接收这多余的第二个参数
    Hotkey("!" . i, SwitchDesktop.Bind(i))
    Hotkey("!+" . i, MoveWindowToDesktop.Bind(i))
    Hotkey("^!" . i, MoveAndSwitch.Bind(i))
}

Hotkey("!+g", GatherAllToCurrentDesktop)
Hotkey("^!t", ToggleAlwaysVisible)
Hotkey("!F12", CleanupAndExit)