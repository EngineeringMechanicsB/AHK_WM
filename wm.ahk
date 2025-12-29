#Requires AutoHotkey v2.0
#SingleInstance Force
#WinActivateForce

; ==============================================================================
; Suckless Virtual Desktop Environment (v2)
; 包含：虚拟桌面管理 + 顶部状态栏 + 极简 Ping 工具
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

; --- 状态栏 GUI 变量 ---
global BarGui := ""
global BarLeftText := ""
global BarRightText := ""

; 初始化桌面数组
Loop DesktopCount {
    Desktops[A_Index] := []
}

; --- 启动初始化 ---
CreateStatusBar() ; 创建顶栏
UpdateStatusBar() ; 刷新一次状态
SetTimer(UpdateClock, 1000) ; 每秒刷新时间

; ==============================================================================
; 状态栏逻辑 (Status Bar)
; ==============================================================================

CreateStatusBar() {
    global BarGui, BarLeftText, BarRightText
    
    ; 创建无边框、置顶、工具窗口、不激活 (+E0x08000000 = WS_EX_NOACTIVATE)
    ; 不激活属性非常重要，防止点击状态栏时当前窗口失去焦点
    BarGui := Gui("-Caption +AlwaysOnTop +ToolWindow +Owner +E0x08000000")
    BarGui.BackColor := "181818" ; 深灰色背景 (类似 Arch Linux 终端配色)
    BarGui.MarginX := 0
    BarGui.MarginY := 0
    
    ; 设置字体 (等宽字体在状态栏表现更好，推荐 Consolas 或 Segoe UI)
    BarGui.SetFont("s10 w600 cWhite", "Segoe UI")
    
    ; --- 左侧组件 (桌面指示器) ---
    ; 宽度设为屏幕的一半
    BarLeftText := BarGui.Add("Text", "x15 y4 w" . (A_ScreenWidth/2) . " h20 BackgroundTrans vDesktopList", "")
    
    ; --- 右侧组件 (时间信息) ---
    ; 计算右侧位置
    RightX := A_ScreenWidth - 220
    BarRightText := BarGui.Add("Text", "x" . RightX . " y4 w200 h20 Right BackgroundTrans vClock", "")
    
    ; 显示 Bar，横跨屏幕顶部，高度 28px
    BarGui.Show("x0 y0 w" . A_ScreenWidth . " h28 NoActivate")
    
    ; 让 Bar 稍微透明一点 (可选)
    WinSetTransparent(200, BarGui.Hwnd)
}

UpdateStatusBar() {
    global CurrentDesktop, DesktopCount, BarLeftText
    
    ; 构建桌面显示字符串，例如: [1]  2  3  4 ...
    displayStr := ""
    Loop DesktopCount {
        if (A_Index == CurrentDesktop) {
            ; 当前桌面：用方括号包裹，或者你可以换成实心圆 ●
            displayStr .= " [" . A_Index . "] " 
        } else {
            ; 其他桌面：显示数字
            displayStr .= "  " . A_Index . "  "
        }
    }
    
    BarLeftText.Value := displayStr
}

UpdateClock() {
    global BarRightText
    ; 格式：YYYY-MM-DD HH:mm:ss
    timeStr := FormatTime(, "yyyy-MM-dd   HH:mm")
    BarRightText.Value := timeStr
}

; ==============================================================================
; 虚拟桌面核心逻辑
; ==============================================================================

GetAllWindows() {
    list := WinGetList()
    windows := []
    for hwnd in list {
        try {
            class := WinGetClass("ahk_id " hwnd)
            if (class == "Progman" || class == "Shell_TrayWnd" || hwnd == BarGui.Hwnd) ; 排除 Bar 本身
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
            if (class == "Progman" || class == "Shell_TrayWnd" || hwnd == BarGui.Hwnd)
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
    
    ; ★ 切换后立即更新 Bar
    UpdateStatusBar()
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

; ==============================================================================
; 热键绑定
; ==============================================================================

Loop 9 {
    i := A_Index
    Hotkey("!" . i, SwitchDesktop.Bind(i))        ; Alt + 1..9
    Hotkey("!+" . i, MoveWindowToDesktop.Bind(i)) ; Alt + Shift + 1..9
    Hotkey("^!" . i, MoveAndSwitch.Bind(i))       ; Ctrl + Alt + 1..9
}

Hotkey("!+g", GatherAllToCurrentDesktop)
Hotkey("^!t", ToggleAlwaysVisible)
Hotkey("!F12", CleanupAndExit)
