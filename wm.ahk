#Requires AutoHotkey v2.0
#SingleInstance Force
#WinActivateForce

; ===============================
; 增强版虚拟桌面 (Suckless Virtual Desktop Enhanced)
; ===============================

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

; --- 托盘菜单设置 ---
A_TrayMenu.Delete() ; 清空默认菜单
A_TrayMenu.Add("Gather All Windows Here", GatherAllToCurrentDesktop)
A_TrayMenu.Add("Toggle Window Pin", ToggleAlwaysVisible)
A_TrayMenu.Add() ; 分隔线

; 动态添加切换菜单
Loop DesktopCount {
    i := A_Index
    A_TrayMenu.Add("Switch to Desktop " . i, SwitchDesktop.Bind(i))
}

A_TrayMenu.Add()
A_TrayMenu.Add("Reload Script", (*) => Reload())
A_TrayMenu.Add("Exit", CleanupAndExit)

; 初始化托盘提示
UpdateTrayTip()

; --- 核心功能函数 ---

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

SwitchDesktop(target, *) {
    global CurrentDesktop, Desktops, AlwaysVisible
    
    if (target == CurrentDesktop) {
        ShowOSD("Current: Desktop " . target)
        return
    }

    ; 1. 保存当前桌面
    Desktops[CurrentDesktop] := GetVisibleWindows()

    ; 2. 隐藏当前桌面窗口
    for hwnd in Desktops[CurrentDesktop] {
        if (!AlwaysVisible.Has(hwnd)) {
            try WinMinimize("ahk_id " hwnd)
        }
    }

    ; 3. 恢复目标桌面窗口
    for hwnd in Desktops[target] {
        try WinRestore("ahk_id " hwnd)
    }

    ; 4. 确保固定窗口显示
    for hwnd, _ in AlwaysVisible {
        try WinRestore("ahk_id " hwnd)
    }

    ; 5. 激活目标桌面顶层窗口
    if (Desktops[target].Length > 0) {
        hwnd := Desktops[target][1]
        try WinActivate("ahk_id " hwnd)
    }

    CurrentDesktop := target
    
    ; 更新 UI
    ShowOSD("Desktop " . CurrentDesktop)
    UpdateTrayTip()
}

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
        ShowOSD("Window Moved to " . target)
    } else {
        ShowOSD("Window is on " . target)
    }
}

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
    ShowOSD("All Windows Gathered")
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
        ShowOSD("Unpinned")
    } else {
        AlwaysVisible[hwnd] := true
        try WinRestore("ahk_id " hwnd)
        ShowOSD("Pinned (Always Visible)")
    }
}

CleanupAndExit(*) {
    for hwnd in GetAllWindows() {
        try WinRestore("ahk_id " hwnd)
    }
    ExitApp
}

UpdateTrayTip() {
    A_IconTip := "Virtual Desktop: " . CurrentDesktop
}

; --- UI 显示函数 (OSD) ---
ShowOSD(text) {
    static OsdGui := ""
    
    ; 销毁旧 GUI 以刷新
    if IsObject(OsdGui)
        OsdGui.Destroy()
    
    ; 创建无边框 GUI
    OsdGui := Gui("+AlwaysOnTop -Caption +ToolWindow +Disabled +Owner")
    OsdGui.BackColor := "202020" ; 深灰色背景
    
    ; 设置字体 (白色, Segoe UI)
    OsdGui.SetFont("s20 w600 cWhite", "Segoe UI")
    OsdGui.Add("Text", "x20 y10 Center", text)
    
    ; 显示在屏幕底部上方一点 (y850 适合 1080p，可自行调整)
    ; NoActivate 防止打断当前工作
    OsdGui.Show("NoActivate AutoSize y850") 
    
    ; 设置半透明 (200/255)
    WinSetTransparent(200, OsdGui.Hwnd)
    
    ; 1.2秒后自动消失
    SetTimer(() => (IsObject(OsdGui) ? OsdGui.Destroy() : ""), -1200)
}

; --- 热键绑定 ---

Loop 9 {
    i := A_Index
    Hotkey("!" . i, SwitchDesktop.Bind(i))        ; Alt + 1..9 切换
    Hotkey("!+" . i, MoveWindowToDesktop.Bind(i)) ; Alt + Shift + 1..9 移动
    Hotkey("^!" . i, MoveAndSwitch.Bind(i))       ; Ctrl + Alt + 1..9 移动并切换
}

Hotkey("!+g", GatherAllToCurrentDesktop) ; Alt + Shift + G 聚合所有窗口
Hotkey("^!t", ToggleAlwaysVisible)       ; Ctrl + Alt + T 固定窗口
Hotkey("!F12", CleanupAndExit)           ; Alt + F12 还原并退出