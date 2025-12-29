#Requires AutoHotkey v2.0
#SingleInstance Force
#WinActivateForce

; ==============================================================================
; Suckless WM v2.0 (Phase 2)
; 核心：虚拟桌面 + 悬浮Bar + 智能平铺(避让Bar) + KDE交互 + 安全退出
; ==============================================================================

; --- 环境设置 ---
SetWorkingDir(A_ScriptDir)
CoordMode("Mouse", "Screen") ; 必须：鼠标和窗口移动基于屏幕绝对坐标
SetTitleMatchMode(2)
SetWinDelay(0)               ; 必须：0延迟保证KDE拖拽流畅
SetControlDelay(0)

; --- 全局变量 ---
global CurrentDesktop := 1
global DesktopCount   := 9
global Desktops       := Map()       ; 存储桌面窗口列表
global AlwaysVisible  := Map()       ; 存储钉住(Pin)的窗口
global DoubleAlt      := false       ; Alt双击状态检测
global BarGui         := ""          ; Bar GUI对象
global BarLeftText    := ""          ; 左侧文字控件
global BarRightText   := ""          ; 右侧文字控件
global BarHeight      := 28          ; 定义Bar的高度，用于平铺避让
global BarVisible     := true        ; Bar显示状态

; 初始化桌面数组
Loop DesktopCount {
    Desktops[A_Index] := []
}

; --- 启动流程 ---
CreateStatusBar()
UpdateStatusBar()
UpdateClock()
SetTimer(UpdateClock, 1000)
SetupTrayIcon()

; ==============================================================================
; 1. 顶部状态栏 (悬浮模式 & 显隐控制)
; ==============================================================================

CreateStatusBar() {
    global BarGui, BarLeftText, BarRightText, BarHeight
    
    ; 创建：无边框、置顶、工具窗口、不抢焦点 (+E0x08000000)
    BarGui := Gui("-Caption +AlwaysOnTop +ToolWindow +Owner +E0x08000000")
    BarGui.BackColor := "181818"
    BarGui.SetFont("s10 w600 cA020F0", "Segoe UI") ; 紫色主题
    
    ; 左侧：桌面指示器
    BarLeftText := BarGui.Add("Text", "x15 y4 w" . (A_ScreenWidth/2) . " h20 BackgroundTrans", "")
    
    ; 右侧：时间 (右对齐视觉位置)
    BarRightText := BarGui.Add("Text", "x" . (A_ScreenWidth - 540) . " y4 w250 h20 BackgroundTrans", "")
    
    ; 显示
    BarGui.Show("x0 y0 w" . A_ScreenWidth . " h" . BarHeight . " NoActivate")
}

UpdateStatusBar() {
    global CurrentDesktop, DesktopCount, BarLeftText
    if !BarLeftText
        return
    displayStr := ""
    Loop DesktopCount {
        if (A_Index == CurrentDesktop)
            displayStr .= " [" . A_Index . "] " 
        else
            displayStr .= "  " . A_Index . "  "
    }
    BarLeftText.Value := displayStr
}

UpdateClock() {
    global BarRightText
    if BarRightText
        try BarRightText.Value := FormatTime(, "yyyy-MM-dd   HH:mm:ss")
}

ToggleBar(*) {
    global BarVisible, BarGui
    if (BarVisible) {
        BarGui.Hide()
        BarVisible := false
        ShowOSD("Bar Hidden")
    } else {
        BarGui.Show("NoActivate")
        BarVisible := true
        ShowOSD("Bar Visible")
    }
}

; ==============================================================================
; 2. 智能平铺 (Alt + D) - 自动避让 Bar 高度
; ==============================================================================

TileCurrentDesktop(*) {
    global BarHeight
    windows := GetVisibleWindows()
    count := windows.Length
    
    if (count == 0) {
        ShowOSD("No Windows")
        return
    }

    ; 1. 获取屏幕工作区 (WL, WT, WR, WB) - 系统会自动减去任务栏
    MonitorGetWorkArea(1, &WL, &WT, &WR, &WB)
    
    ; 2. ★ 修正坐标：顶部避让 Bar 的高度
    if (BarVisible) {
        WT := WT + BarHeight  ; Y起点下移
    }
    
    ; 3. 计算实际可用宽高
    W := WR - WL
    H := WB - WT 

    ShowOSD("Tiling: " . count)

    ; --- 算法 A: 1 个窗口 (铺满) ---
    if (count == 1) {
        try{
        WinRestore(windows[1])
        WinMove(WL, WT, W, H, windows[1])
        return
        }
    }

    ; --- 算法 B: 2 个窗口 (左右护法) ---
    if (count == 2) {
        try{
        WinRestore(windows[1])
        WinMove(WL, WT, W/2, H, windows[1])
        
        WinRestore(windows[2])
        WinMove(WL + W/2, WT, W/2, H, windows[2])
        return
        }
    }

    ; --- 算法 C: 奇数个 (川字形/竖条) ---
    if (Mod(count, 2) != 0) {
        try{
        itemWidth := W / count
        Loop count {
            hwnd := windows[A_Index]
            WinRestore(hwnd)
            WinMove(WL + (A_Index - 1) * itemWidth, WT, itemWidth, H, hwnd)
        }
        return
        }
    }

    ; --- 算法 D: 偶数个 (田字形/网格) ---
    if (Mod(count, 2) == 0) {
        try{
        cols := count / 2
        itemWidth := W / cols
        itemHeight := H / 2 ; 上下两行
        
        Loop count {
            hwnd := windows[A_Index]
            WinRestore(hwnd)
            
            idx := A_Index - 1
            r := Floor(idx / cols) ; 行索引 0/1
            c := Mod(idx, cols)    ; 列索引
            
            xPos := WL + c * itemWidth
            yPos := WT + r * itemHeight
            
            WinMove(xPos, yPos, itemWidth, itemHeight, hwnd)
        }
        return
        }
    }
}

; ==============================================================================
; 3. KDE 风格窗口管理 (修复了 Try Catch 语法)
; ==============================================================================

; --- Alt + 左键: 拖动 ---
!LButton:: {
    global DoubleAlt
    MouseGetPos(,, &hwnd)
    
    if (DoubleAlt) {
        WinMinimize(hwnd)
        return
    }
    
    if (WinGetMinMax(hwnd) == 1) ; 最大化窗口不拖动
        return

    MouseGetPos(&startX, &startY)
    try WinGetPos(&winX, &winY,,, hwnd)
    catch {
        return ; 捕获错误直接返回，防止报错
    }
    
    while GetKeyState("LButton", "P") {
        MouseGetPos(&curX, &curY)
        try WinMove(winX + (curX - startX), winY + (curY - startY),,, hwnd)
    }
}

; --- Alt + 右键: 调整大小 ---
!RButton:: {
    global DoubleAlt
    MouseGetPos(,, &hwnd)
    
    if (DoubleAlt) {
        if (WinGetMinMax(hwnd) == 1)
            WinRestore(hwnd)
        else
            WinMaximize(hwnd)
        return
    }

    if (WinGetMinMax(hwnd) == 1)
        return

    try WinGetPos(&winX, &winY, &winW, &winH, hwnd)
    catch {
        return
    }

    MouseGetPos(&startX, &startY)
    
    ; 智能判断点击区域 (左/右? 上/下?)
    clickRelX := (startX - winX) / winW
    clickRelY := (startY - winY) / winH
    isLeft := (clickRelX < 0.5)
    isUp   := (clickRelY < 0.5)

    while GetKeyState("RButton", "P") {
        MouseGetPos(&curX, &curY)
        dX := curX - startX
        dY := curY - startY
        
        newX := isLeft ? (winX + dX) : winX
        newW := isLeft ? (winW - dX) : (winW + dX)
        newY := isUp ? (winY + dY) : winY
        newH := isUp ? (winH - dY) : (winH + dY)
        
        if (newW > 50 && newH > 50)
            try WinMove(newX, newY, newW, newH, hwnd)
    }
}

; --- Alt + 中键 / Alt + Q : 关闭 ---
!MButton::
!q:: {
    MouseGetPos(,, &hwnd)
    try WinClose(hwnd)
}

; --- Alt + 滚轮 : 透明度 ---
!WheelUp:: {
    MouseGetPos(,, &hwnd)
    try {
        cur := WinGetTransparent(hwnd)
        if (cur == "") 
            cur := 255
        WinSetTransparent(Min(cur + 20, 255), hwnd)
    }
}

!WheelDown:: {
    MouseGetPos(,, &hwnd)
    try {
        cur := WinGetTransparent(hwnd)
        if (cur == "") 
            cur := 255
        WinSetTransparent(Max(cur - 20, 50), hwnd)
    }
}

; --- Alt 双击检测 ---
~Alt:: {
    global DoubleAlt
    if (A_PriorHotkey == "~Alt" && A_TimeSincePriorHotkey < 400)
        DoubleAlt := true
    else
        DoubleAlt := false
    KeyWait("Alt")
    DoubleAlt := false
}

; ==============================================================================
; 4. 虚拟桌面与窗口管理核心
; ==============================================================================

SwitchDesktop(target, *) {
    global CurrentDesktop, Desktops, AlwaysVisible
    
    if (target == CurrentDesktop) {
        ShowOSD("Desktop " . target)
        return
    }

    ; 1. 保存当前桌面窗口
    Desktops[CurrentDesktop] := GetVisibleWindows()
    
    ; 2. 隐藏当前桌面非钉住窗口
    for hwnd in Desktops[CurrentDesktop] {
        if (!AlwaysVisible.Has(hwnd))
            try WinMinimize(hwnd)
    }

    ; 3. 恢复目标桌面窗口
    for hwnd in Desktops[target]
        try WinRestore(hwnd)

    ; 4. 强制恢复钉住的窗口
    for hwnd, _ in AlwaysVisible
        try WinRestore(hwnd)

    ; 5. 激活一个窗口焦点
    if (Desktops[target].Length > 0)
        try WinActivate(Desktops[target][1])

    CurrentDesktop := target
    UpdateStatusBar()
    ShowOSD("Desktop " . CurrentDesktop)
}

MoveWindowToDesktop(target, *) {
    global CurrentDesktop, Desktops, AlwaysVisible
    
    try hwnd := WinExist("A")
    catch {
        return ; 修复 Catch Return 错误：v2 必须使用 block 或直接 return
    }
    
    if (!hwnd || hwnd == BarGui.Hwnd) 
        return

    ; 如果移动了钉住的窗口，取消钉住状态
    if (AlwaysVisible.Has(hwnd))
        AlwaysVisible.Delete(hwnd)

    ; 从所有桌面记录中移除
    Loop DesktopCount {
        d := A_Index
        if (Desktops.Has(d)) {
            newList := []
            for h in Desktops[d] {
                if (h != hwnd)
                    newList.Push(h)
            }
            Desktops[d] := newList
        }
    }
    
    ; 加入目标
    Desktops[target].Push(hwnd)

    if (target != CurrentDesktop) {
        try WinMinimize(hwnd)
        ShowOSD("Window -> Desktop " . target)
    }
}

; --- 聚合所有窗口 (Alt + Shift + G) ---
GatherAllToCurrent(*) {
    global Desktops, CurrentDesktop, AlwaysVisible
    
    ShowOSD("Gathering All Windows...")
    
    ; 获取所有物理窗口
    fullList := WinGetList()
    
    ; 清空所有桌面的记录，重新分配
    Loop DesktopCount
        Desktops[A_Index] := []
    AlwaysVisible.Clear()
    
    count := 0
    for hwnd in fullList {
        try {
            if (hwnd == BarGui.Hwnd)
                continue
            class := WinGetClass(hwnd)
            if (class == "Progman" || class == "Shell_TrayWnd")
                continue
            
            ; 恢复并加入当前桌面
            WinRestore(hwnd)
            Desktops[CurrentDesktop].Push(hwnd)
            count++
        }
    }
    ShowOSD("Gathered " . count . " Windows")
}

; --- 钉住/解钉窗口 (Ctrl + Alt + T) ---
TogglePin(*) {
    global AlwaysVisible
    try hwnd := WinExist("A")
    catch {
        return
    }
    
    if (!hwnd || hwnd == BarGui.Hwnd)
        return
        
    if (AlwaysVisible.Has(hwnd)) {
        AlwaysVisible.Delete(hwnd)
        ShowOSD("Unpinned")
    } else {
        AlwaysVisible[hwnd] := true
        ShowOSD("Pinned (Always Visible)")
    }
}

; --- 还原所有并退出 (Alt + F12) ---
RestoreAndExit(*) {
    global BarGui
    ShowOSD("Restoring & Exiting...")
    Sleep(500) ; 给一点时间显示OSD
    
    ; 1. 销毁 Bar
    if BarGui
        BarGui.Destroy()
        
    ; 2. 还原所有窗口
    list := WinGetList()
    for hwnd in list {
        try {
            class := WinGetClass(hwnd)
            if (class != "Progman" && class != "Shell_TrayWnd")
                WinRestore(hwnd)
        }
    }
    
    ExitApp
}

; --- 辅助：获取当前可见窗口 ---
GetVisibleWindows() {
    global BarGui
    list := WinGetList()
    windows := []
    for hwnd in list {
        try {
            if (hwnd == BarGui.Hwnd)
                continue
            class := WinGetClass(hwnd)
            if (class == "Progman" || class == "Shell_TrayWnd")
                continue
            if (WinGetMinMax(hwnd) != -1) 
                windows.Push(hwnd)
        }
    }
    return windows
}

ShowOSD(text) {
    static OsdGui := ""
    if IsObject(OsdGui)
        OsdGui.Destroy()
    
    OsdGui := Gui("+AlwaysOnTop -Caption +ToolWindow +Disabled +Owner")
    OsdGui.BackColor := "181818"
    OsdGui.SetFont("s20 w600 cA020F0", "Segoe UI")
    OsdGui.Add("Text", "Center", text)
    OsdGui.Show("NoActivate AutoSize y850")
    WinSetTransparent(200, OsdGui.Hwnd)
    SetTimer(() => (IsObject(OsdGui) ? OsdGui.Destroy() : ""), -1000)
}

SetupTrayIcon() {
    A_TrayMenu.Delete()
    A_TrayMenu.Add("Tile Windows (Alt+D)", TileCurrentDesktop)
    A_TrayMenu.Add("Gather All (Alt+Shift+G)", GatherAllToCurrent)
    A_TrayMenu.Add("Restore & Exit (Alt+F12)", RestoreAndExit)
}

; ==============================================================================
; 5. 快捷键映射 (User Defined)
; ==============================================================================

; 切换桌面 (Alt + 1..9)
; 移动窗口 (Alt + Shift + 1..9)
Loop 9 {
    i := A_Index
    Hotkey("!" . i, SwitchDesktop.Bind(i))
    Hotkey("!+" . i, MoveWindowToDesktop.Bind(i))
}

Hotkey("!d", TileCurrentDesktop)      ; Alt + D : 平铺
Hotkey("!+g", GatherAllToCurrent)     ; Alt + Shift + G : 聚合所有窗口
Hotkey("^!t", TogglePin)              ; Ctrl + Alt + T  : 钉住窗口
Hotkey("^!b", ToggleBar)              ; Ctrl + Alt + B  : 开关顶栏
Hotkey("!F12", RestoreAndExit)        ; Alt + F12       : 安全退出
