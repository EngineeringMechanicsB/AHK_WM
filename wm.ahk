#Requires AutoHotkey v2.0
#SingleInstance Force
#WinActivateForce

; ==============================================================================
; Suckless Virtual Desktop Manager v1.0
; ==============================================================================

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
global BarVisible := true ; 记录 Bar 的显示状态

; --- GUI 对象变量 ---
global BarGui := ""
global BarLeftText := ""
global BarRightText := ""

; 初始化桌面数组
Loop DesktopCount {
    Desktops[A_Index] := []
}

; --- 初始化启动 ---
SetupTrayIcon()      ; 配置托盘
CreateStatusBar()    ; 创建顶栏
UpdateStatusBar()    ; 刷新顶栏内容
UpdateTrayTip()      ; 刷新托盘提示
SetTimer(UpdateClock, 1000) ; 启动时钟

; ==============================================================================
; 1. 顶部状态栏 (Status Bar)
; ==============================================================================

CreateStatusBar() {
    global BarGui, BarLeftText, BarRightText
    
    ; 创建无边框、置顶、工具窗口、不激活 (+E0x08000000) 的 GUI
    BarGui := Gui("-Caption +AlwaysOnTop +ToolWindow +Owner +E0x08000000", "DesktopBar")
    BarGui.BackColor := "181818" ; 深灰色背景
    BarGui.MarginX := 0
    BarGui.MarginY := 0
    
    ; 设置字体
    BarGui.SetFont("s10 w600 cWhite", "Segoe UI")
    
    ; 左侧：桌面列表
    BarLeftText := BarGui.Add("Text", "x15 y4 w" . (A_ScreenWidth/2) . " h20 BackgroundTrans vDesktopList", "")
    
    ; 右侧：时间
    RightX := A_ScreenWidth - 220
    BarRightText := BarGui.Add("Text", "x" . RightX . " y4 w200 h20 Right BackgroundTrans vClock", "")
    
    ; 显示 Bar (高度 28px)
    BarGui.Show("x0 y0 w" . A_ScreenWidth . " h28 NoActivate")
    
    ; 设置轻微透明
    WinSetTransparent(240, BarGui.Hwnd)
}

UpdateStatusBar() {
    global CurrentDesktop, DesktopCount, BarLeftText
    
    ; 构建类似于 [1] 2 3 4 的字符串
    displayStr := ""
    Loop DesktopCount {
        if (A_Index == CurrentDesktop) {
            displayStr .= " [" . A_Index . "] " 
        } else {
            displayStr .= "  " . A_Index . "  "
        }
    }
    BarLeftText.Value := displayStr
}

UpdateClock() {
    global BarRightText
    BarRightText.Value := FormatTime(, "yyyy-MM-dd   HH:mm")
}

ToggleStatusBar(*) {
    global BarVisible, BarGui
    if (BarVisible) {
        BarGui.Hide()
        BarVisible := false
        ShowOSD("Status Bar: Hidden")
    } else {
        BarGui.Show("NoActivate") ; 显示但不抢焦点
        BarVisible := true
        ShowOSD("Status Bar: Visible")
    }
}

; ==============================================================================
; 2. 屏幕显示提示 (OSD / HUD)
; ==============================================================================

ShowOSD(text) {
    static OsdGui := ""
    
    if IsObject(OsdGui)
        OsdGui.Destroy()
    
    OsdGui := Gui("+AlwaysOnTop -Caption +ToolWindow +Disabled +Owner")
    OsdGui.BackColor := "202020"
    OsdGui.SetFont("s20 w600 cWhite", "Segoe UI")
    OsdGui.Add("Text", "x20 y10 Center", text)
    
    ; 显示在屏幕下方 (y850)
    OsdGui.Show("NoActivate AutoSize y850")
    WinSetTransparent(200, OsdGui.Hwnd)
    
    ; 1.2秒后自动销毁
    SetTimer(() => (IsObject(OsdGui) ? OsdGui.Destroy() : ""), -1200)
}

; ==============================================================================
; 3. 托盘图标设置 (Tray Icon)
; ==============================================================================

SetupTrayIcon() {
    A_TrayMenu.Delete()
    A_TrayMenu.Add("Gather All Windows", GatherAllToCurrentDesktop)
    A_TrayMenu.Add("Toggle Window Pin", ToggleAlwaysVisible)
    A_TrayMenu.Add("Toggle Status Bar", ToggleStatusBar)
    A_TrayMenu.Add() ; 分隔线
    
    Loop DesktopCount {
        i := A_Index
        A_TrayMenu.Add("Switch to Desktop " . i, SwitchDesktop.Bind(i))
    }
    
    A_TrayMenu.Add()
    A_TrayMenu.Add("Reload Script", (*) => Reload())
    A_TrayMenu.Add("Exit", CleanupAndExit)
}

UpdateTrayTip() {
    A_IconTip := "Current Desktop: " . CurrentDesktop
}

; ==============================================================================
; 4. 虚拟桌面核心逻辑 (Core Logic)
; ==============================================================================

GetAllWindows() {
    list := WinGetList()
    windows := []
    for hwnd in list {
        try {
            class := WinGetClass("ahk_id " hwnd)
            if (class == "Progman" || class == "Shell_TrayWnd" || (BarGui && hwnd == BarGui.Hwnd))
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
            if (class == "Progman" || class == "Shell_TrayWnd" || (BarGui && hwnd == BarGui.Hwnd))
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

    Desktops[CurrentDesktop] := GetVisibleWindows()

    for hwnd in Desktops[CurrentDesktop] {
        if (!AlwaysVisible.Has(hwnd))
            try WinMinimize("ahk_id " hwnd)
    }

    for hwnd in Desktops[target]
        try WinRestore("ahk_id " hwnd)

    for hwnd, _ in AlwaysVisible
        try WinRestore("ahk_id " hwnd)

    if (Desktops[target].Length > 0) {
        hwnd := Desktops[target][1]
        try WinActivate("ahk_id " hwnd)
    }

    CurrentDesktop := target
    
    ; 更新所有 UI 组件
    UpdateStatusBar()
    UpdateTrayTip()
    ShowOSD("Desktop " . CurrentDesktop)
}

MoveWindowToDesktop(target, *) {
    global CurrentDesktop, Desktops, AlwaysVisible
    
    try hwnd := WinExist("A")
    catch
        return

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
    ShowOSD("Gathered All Windows")
}

ToggleAlwaysVisible(*) {
    global AlwaysVisible
    try hwnd := WinExist("A")
    catch
        return

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

; ==============================================================================
; 5. 快捷键绑定 (Hotkeys)
; ==============================================================================

Loop 9 {
    i := A_Index
    Hotkey("!" . i, SwitchDesktop.Bind(i))        ; Alt + 1..9
    Hotkey("!+" . i, MoveWindowToDesktop.Bind(i)) ; Alt + Shift + 1..9
    Hotkey("^!" . i, MoveAndSwitch.Bind(i))       ; Ctrl + Alt + 1..9
}

Hotkey("!+g", GatherAllToCurrentDesktop) ; Alt + Shift + G (聚合)
Hotkey("^!t", ToggleAlwaysVisible)       ; Ctrl + Alt + T (钉住窗口)
Hotkey("!F12", CleanupAndExit)           ; Alt + F12 (还原并退出)
Hotkey("^!b", ToggleStatusBar)           ; Ctrl + Alt + B (显示/隐藏顶栏) ★新增