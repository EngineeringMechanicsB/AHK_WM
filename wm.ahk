#Requires AutoHotkey v2.0
#SingleInstance Force
#WinActivateForce

; ==============================================================================
; SUCKLESS WM v2.5 (Final Stable)
; 结构：配置 -> 初始化 -> 按键绑定 -> 功能模块
; ==============================================================================

; --- 0. 环境设置 (Environment) ---
SetWorkingDir(A_ScriptDir)
CoordMode("Mouse", "Screen")
SetTitleMatchMode(2)
SetWinDelay(0)
SetControlDelay(0)

; ==============================================================================
; 1. 全局配置与变量 (Global Configuration)
; ==============================================================================

; --- 核心 WM 配置 ---
global CurrentDesktop := 1
global DesktopCount   := 9
global Desktops       := Map()       
global AlwaysVisible  := Map()       
global DoubleAlt      := false       
global BarHeight      := 28          
global BarVisible     := true

; --- GUI 对象占位 (必须初始化为空) ---
global BarGui := "", BarLeftText := "", BarRightText := "", BarProgress := ""

; --- 外部工具路径 (请确保路径正确，否则 Alt+Enter/Alt+V 无效) ---
global VimPath     := "C:\Program Files\Vim\vim91\vim.exe"
global TerminalExe := "C:\Soft\terminal\WindowsTerminal.exe"

; --- 初始化桌面数据 ---
Loop DesktopCount {
    Desktops[A_Index] := []
}

; --- 剪切板路径设置 ---
; 请确保路径准确，建议使用变量组合，方便迁移
global VimPath    := "C:\Program Files\Vim\vim91\vim.exe" 
global OutputDir  := "C:\Users\Administrator\Desktop\zxw"
global OutputFile := OutputDir . "\CB.txt"

; --- 窗口布局设置 ---
global VimWinX      := 400   ; 窗口 X 坐标
global VimWinY      := 0     ; 窗口 Y 坐标
global VimWinWidth  := 1000  ; 建议设置一个宽度，或者留空使用默认
global VimWinHeight := 800   ; 建议设置一个高度

; --- 运行状态变量 ---
global CurrentVimPID := 0    ; 用于追踪 Vim 进程 ID
global LastClipContent := "" ; 用于防止重复记录
; ==============================================================================
; 2. 启动流程 (Initialization)
; ==============================================================================
CreateStatusBar()
UpdateStatusBar()
UpdateClockAndProgress()
SetTimer(UpdateClockAndProgress, 1000) ; 每秒刷新
SetupTrayIcon()
; 确保目标目录存在，不存在则创建
if !DirExist(OutputDir)
    DirCreate(OutputDir)
RecordClipboard()
; ==============================================================================
; 3. 快捷键绑定 (Key Bindings)
; ==============================================================================

; --- 桌面管理 (1-9) ---
Loop 9 {
    i := A_Index
    ; Alt + N: 切换桌面
    Hotkey("!" . i, SwitchDesktop.Bind(i))
    ; Alt + Shift + N: 仅移动窗口
    Hotkey("!+" . i, MoveWindowToDesktop.Bind(i))
    ; Ctrl + Alt + N: 移动窗口并跟随跳转
    Hotkey("^!" . i, MoveAndSwitch.Bind(i))
}

; --- 核心功能 ---
Hotkey("!d", TileCurrentDesktop)       ; Alt + D: 智能平铺
Hotkey("!+g", GatherAllToCurrent)      ; Alt + Shift + G: 召唤所有窗口
Hotkey("^!t", TogglePin)               ; Ctrl + Alt + T: 钉住/解钉窗口
Hotkey("^!b", ToggleBar)               ; Ctrl + Alt + B: 开关顶栏显隐
Hotkey("!F12", RestoreAndExit)         ; Alt + F12: 还原所有窗口并退出脚本

; --- 窗口操作 (鼠标下的窗口) ---
Hotkey("!q", CloseWindowUnderMouse)        ; Alt + Q: 关闭
Hotkey("!MButton", CloseWindowUnderMouse)  ; Alt + 中键: 关闭
Hotkey("!f", ToggleMaximizeUnderMouse)     ; Alt + F: 最大化/还原
Hotkey("!t", ToggleTopUnderMouse)          ; Alt + T: 置顶/取消置顶

; --- 鼠标增强 ---
; Alt + 滚轮: 调节透明度
Hotkey("!WheelUp", AdjustTransparency.Bind(20))
Hotkey("!WheelDown", AdjustTransparency.Bind(-20))
; 鼠标左右键同按: 模拟 Ctrl+C
~LButton & RButton::Send("^c")
~RButton & LButton::Send("^c")

; --- 外部工具快捷键 ---
Hotkey("!Enter", LaunchTerminal)           ; Alt + Enter: 当前目录打开终端
Hotkey("!s", (*) => Run("devmgmt.msc"))    ; Alt + S: 设备管理器 (修正语法)
Hotkey("!v", OpenWithVim)                  ; Alt + V: 用 Vim 打开选中文件
Hotkey("!x", ShowPowerMenu)                ; Alt + X: 电源菜单

; --- 剪切板快捷键 ---
; --- 监听复制 (Ctrl + C) ---
~^c::
{
        ; 延时一小会儿，确保系统剪贴板已更新
            Sleep(100) 
                RecordClipboard()
}

; --- 呼出/隐藏 Vim 记录 (Ctrl + `) ---
^`::
{
        ToggleVimWindow()
}


; ==============================================================================
; 4. 模块：状态栏 (Status Bar & Progress)
; ==============================================================================

CreateStatusBar() {
    global BarGui, BarLeftText, BarRightText, BarProgress, BarHeight
    
    try {
        if IsObject(BarGui)
            BarGui.Destroy()
    }

    BarGui := Gui("-Caption +AlwaysOnTop +ToolWindow +Owner +E0x08000000 -DPIScale")
    BarGui.BackColor := "181818"
    
    ; 左侧：桌面指示器
    BarGui.SetFont("s10 w600 cA020F0", "Segoe UI")
    BarLeftText := BarGui.Add("Text", "x15 y4 w300 h20 BackgroundTrans", "")
    
    ; 中间：下班进度条
    ProgressWidth := 300
    ProgressX := (A_ScreenWidth / 2) - (ProgressWidth / 2)
    ; 背景底槽
    BarGui.Add("Text", "x" ProgressX " y10 w" ProgressWidth " h6 Background333333", "") 
    ; 进度实体 (紫色) - 添加 Smooth 属性
    BarProgress := BarGui.Add("Progress", "x" ProgressX " y10 w" ProgressWidth " h6 cA020F0 Background333333 +Smooth", 0)
    
    ; 右侧：时钟
    BarGui.SetFont("s10 w600 cA020F0", "Segoe UI")
    BarRightText := BarGui.Add("Text", "x" . (A_ScreenWidth - 260 ) . " y4 w250 h20 BackgroundTrans Right", "")
    
    BarGui.Show("x0 y0 w" . A_ScreenWidth . " h" . BarHeight . " NoActivate")
}

UpdateStatusBar() {
    global CurrentDesktop, DesktopCount, BarLeftText
    if !IsObject(BarLeftText)
        return
    str := ""
    Loop DesktopCount
        str .= (A_Index == CurrentDesktop) ? " [" A_Index "] " : "  " A_Index "  "
    try BarLeftText.Value := str
}

UpdateClockAndProgress() {
    global BarRightText, BarProgress
    if !IsObject(BarRightText)
        return

    ; 更新时间
    try BarRightText.Value := FormatTime(, "yyyy-MM-dd   HH:mm")

    ; --- 进度条逻辑 ---
    WorkStart := "0900", WorkEnd := "1745"
    NowTime := A_Now
    TodayDate := FormatTime(NowTime, "yyyyMMdd")
    StartTS := TodayDate . WorkStart . "00"
    EndTS   := TodayDate . WorkEnd . "00"
    
    WDay := A_WDay ; 1=周日, 7=周六
    
    pct := 0
    ; 周末显示满条 (100%)
    if (WDay == 1 || WDay == 7) {
        pct := 100
    } else {
        TotalSec := DateDiff(EndTS, StartTS, "Seconds")
        ElapsedSec := DateDiff(NowTime, StartTS, "Seconds")
        
        if (ElapsedSec < 0) {
            pct := 0
        } else if (ElapsedSec > TotalSec) {
            pct := 100
        } else {
            pct := (ElapsedSec / TotalSec) * 100
        }
    }
    
    ; 严格错误处理：确保赋值给控件的是整数
    try {
        if IsObject(BarProgress)
            BarProgress.Value := Integer(pct)
    }
}

ToggleBar(*) {
    global BarVisible, BarGui
    if (BarVisible := !BarVisible)
        BarGui.Show("NoActivate")
    else
        BarGui.Hide()
}

; ==============================================================================
; 5. 模块：虚拟桌面核心 (Virtual Desktop Core)
; ==============================================================================

SwitchDesktop(target, *) {
    global CurrentDesktop, Desktops, AlwaysVisible
    
    if (target == CurrentDesktop) {
        ShowOSD("Desktop " . target)
        return
    }
    
    ; 保存当前
    Desktops[CurrentDesktop] := GetVisibleWindows()
    
    ; 隐藏当前桌面非 Pin 窗口
    for hwnd in Desktops[CurrentDesktop] {
        if (!AlwaysVisible.Has(hwnd)) {
            try WinMinimize(hwnd)
        }
    }
    
    ; 恢复目标桌面窗口
    for hwnd in Desktops[target] {
        try WinRestore(hwnd)
    }
    
    ; 强制恢复 Pin 窗口
    for hwnd, _ in AlwaysVisible {
        try WinRestore(hwnd)
    }
    
    ; 激活焦点
    if (Desktops[target].Length > 0) {
        try WinActivate(Desktops[target][1])
    }
        
    CurrentDesktop := target
    UpdateStatusBar()
    ShowOSD("Desktop " . CurrentDesktop)
}

MoveWindowToDesktop(target, *) {
    global CurrentDesktop, Desktops, AlwaysVisible
    
    ; 严谨的 Try-Catch 获取窗口
    hwnd := 0
    try {
        hwnd := WinExist("A")
    } catch {
        return
    }
    
    if (!hwnd || (BarGui && hwnd == BarGui.Hwnd)) 
        return

    ; 处理 Pin 状态
    if (AlwaysVisible.Has(hwnd)) 
        AlwaysVisible.Delete(hwnd)

    ; 从所有桌面列表中移除
    Loop DesktopCount {
        d := A_Index
        if (Desktops.Has(d)) {
            nl := []
            for h in Desktops[d] {
                if (h != hwnd) 
                    nl.Push(h)
            }
            Desktops[d] := nl
        }
    }
    
    ; 加入目标桌面
    Desktops[target].Push(hwnd)
    
    if (target != CurrentDesktop) {
        try WinMinimize(hwnd)
        ShowOSD("Window -> Desktop " . target)
    }
}

MoveAndSwitch(target, *) {
    MoveWindowToDesktop(target)
    SwitchDesktop(target)
    ShowOSD("Move And Switch -> " . target) 
}

GatherAllToCurrent(*) {
    global Desktops, CurrentDesktop, AlwaysVisible
    ShowOSD("Gathering All Windows...")
    
    fullList := WinGetList()
    Loop DesktopCount
        Desktops[A_Index] := []
    
    AlwaysVisible.Clear()
    count := 0
    
    for hwnd in fullList {
        try {
            if (BarGui && hwnd == BarGui.Hwnd) 
                continue
            
            class := WinGetClass(hwnd)
            if (class == "Progman" || class == "Shell_TrayWnd") 
                continue
            
            WinRestore(hwnd)
            Desktops[CurrentDesktop].Push(hwnd)
            count++
        }
    }
    ShowOSD("Gathered " . count . " Windows")
}

TogglePin(*) {
    global AlwaysVisible
    hwnd := 0
    try { 
        hwnd := WinExist("A") 
    } catch { 
        return 
    }
    
    if (!hwnd || (BarGui && hwnd == BarGui.Hwnd)) 
        return
        
    if (AlwaysVisible.Has(hwnd)) {
        AlwaysVisible.Delete(hwnd)
        ShowOSD("Unpinned")
    } else {
        AlwaysVisible[hwnd] := true
        ShowOSD("Pinned (Always Visible)")
    }
}

; ==============================================================================
; 6. 模块：智能平铺 (Smart Tiling)
; ==============================================================================

TileCurrentDesktop(*) {
    global BarHeight, BarVisible
    windows := GetVisibleWindows()
    count := windows.Length
    
    if (count == 0) {
        ShowOSD("No Windows")
        return
    }

    MonitorGetWorkArea(1, &WL, &WT, &WR, &WB)
    if (BarVisible)
        WT += BarHeight
    
    W := WR - WL, H := WB - WT 
    ShowOSD("Tiling: " . count)

    ; 算法 A: 1个窗口
    if (count == 1) {
        try {
            WinRestore(windows[1])
            WinMove(WL, WT, W, H, windows[1])
        }
        return
    }
    ; 算法 B: 2个窗口
    if (count == 2) {
        try {
            WinRestore(windows[1]), WinMove(WL, WT, W/2, H, windows[1])
            WinRestore(windows[2]), WinMove(WL + W/2, WT, W/2, H, windows[2])
        }
        return
    }
    ; 算法 C: 奇数 (列模式)
    if (Mod(count, 2) != 0) { 
        try {
            itemWidth := W / count
            for i, hwnd in windows
                WinRestore(hwnd), WinMove(WL + (i-1)*itemWidth, WT, itemWidth, H, hwnd)
        }
        return
    }
    ; 算法 D: 偶数 (网格模式)
    if (Mod(count, 2) == 0) { 
        try {
            cols := count / 2
            itemWidth := W / cols, itemHeight := H / 2
            for i, hwnd in windows {
                idx := i - 1
                r := Floor(idx / cols), c := Mod(idx, cols)
                WinRestore(hwnd), WinMove(WL + c*itemWidth, WT + r*itemHeight, itemWidth, itemHeight, hwnd)
            }
        }
        return
    }
}

; ==============================================================================
; 7. 模块：KDE 交互 (Mouse Interaction)
; ==============================================================================

!LButton:: {
    global DoubleAlt
    MouseGetPos(,, &hwnd)
    
    if (DoubleAlt) {
        try WinMinimize(hwnd)
        return
    }
    
    ; 自动还原并吸附 (吸附到鼠标位置)
    if (WinGetMinMax(hwnd) == 1) {
        try {
            WinRestore(hwnd)
            WinGetPos(,, &rw, &rh, hwnd)
            MouseGetPos(&mx, &my)
            ; 移动窗口使得鼠标位于标题栏附近
            WinMove(mx - rw/2, my - rh/10,,, hwnd)
        } catch {
            return
        }
    }
    
    MouseGetPos(&startX, &startY)
    try {
        WinGetPos(&winX, &winY,,, hwnd)
    } catch {
        return
    }
    
    while GetKeyState("LButton", "P") {
        MouseGetPos(&curX, &curY)
        try WinMove(winX + (curX - startX), winY + (curY - startY),,, hwnd)
    }
}

!RButton:: {
    global DoubleAlt
    MouseGetPos(,, &hwnd)
    
    if (DoubleAlt) {
        try (WinGetMinMax(hwnd) == 1 ? WinRestore(hwnd) : WinMaximize(hwnd))
        return
    }
    
    if (WinGetMinMax(hwnd) == 1) 
        return
        
    try {
        WinGetPos(&winX, &winY, &winW, &winH, hwnd)
        MouseGetPos(&startX, &startY)
        isLeft := (startX - winX) / winW < 0.5
        isUp   := (startY - winY) / winH < 0.5
        
        while GetKeyState("RButton", "P") {
            MouseGetPos(&curX, &curY)
            dX := curX - startX, dY := curY - startY
            nX := isLeft ? (winX+dX) : winX, nW := isLeft ? (winW-dX) : (winW+dX)
            nY := isUp ? (winY+dY) : winY, nH := isUp ? (winH-dY) : (winH+dY)
            
            if (nW > 50 && nH > 50)
                try WinMove(nX, nY, nW, nH, hwnd)
        }
    }
}

~Alt:: {
    global DoubleAlt := (A_PriorHotkey == "~Alt" && A_TimeSincePriorHotkey < 400)
    KeyWait("Alt")
    DoubleAlt := false
}

; ==============================================================================
; 8. 模块：辅助功能 (Helpers & Tools)
; ==============================================================================

; --- 窗口操作辅助 ---
CloseWindowUnderMouse(*) {
    MouseGetPos(,, &hwnd)
    try WinClose(hwnd)
}

ToggleMaximizeUnderMouse(*) {
    try {
        MouseGetPos(,, &hwnd)
        if WinGetMinMax(hwnd)
            WinRestore(hwnd)
        else
            WinMaximize(hwnd)
    }
}

ToggleTopUnderMouse(*) {
    try {
        MouseGetPos(,, &hwnd)
        WinSetAlwaysOnTop(-1, hwnd)
        ShowOSD("Topmost Toggled")
    }
}

AdjustTransparency(amount, *) {
    MouseGetPos(,, &hwnd)
    try {
        cur := WinGetTransparent(hwnd)
        if !IsNumber(cur) ; 修复：如果获取失败或为空，默认为不透明(255)
            cur := 255
            
        newVal := cur + amount
        if (newVal > 255) 
            newVal := 255
        if (newVal < 30) 
            newVal := 30
            
        WinSetTransparent(newVal, hwnd)
    }
}

; --- 外部工具启动逻辑 ---
LaunchTerminal(*) {
    path := Explorer_GetPath()
    if (path != "") {
        try Run('"' . TerminalExe . '" -d "' . path . '"')
    } else {
        try Run('"' . TerminalExe . '"')
    }
}

OpenWithVim(*) {
    targetPath := Explorer_GetSelection()
    if (targetPath == "") {
        ShowOSD("No file selected")
        return
    }
    try {
        Run('"' . VimPath . '" "' . targetPath . '"')
    } catch as e {
        ShowOSD("Vim Launch Failed")
    }
}

ShowPowerMenu(*) {
    static pGui := ""
    if IsObject(pGui) {
        pGui.Destroy()
        pGui := ""
        return
    }
    pGui := Gui("+AlwaysOnTop -Caption +ToolWindow +Owner")
    pGui.BackColor := "2e3440"
    pGui.SetFont("s12", "Arial")
    pGui.Add("Text", "x0 y15 w500 Center cceceff4", "System Power Menu")
    pGui.Add("Text", "x50 y45 w400 h2 0x10")
    
    AddBtn(x, y, text, func, color) {
        btn := pGui.Add("Text", "x" x " y" y " w120 h60 Center 0x200 +Border cWhite Background" color, text)
        btn.OnEvent("Click", func)
    }
    
    AddBtn(50,  70, "Shutdown", (*) => Shutdown(1), "b48ead")
    AddBtn(190, 70, "Sleep",    (*) => DllCall("PowrProf\SetSuspendState", "Int", 0, "Int", 0, "Int", 0), "5e81ac")
    AddBtn(330, 70, "Reboot",   (*) => Shutdown(2), "bf616a")
    
    pGui.OnEvent("Escape", (*) => (pGui.Destroy(), pGui := ""))
    pGui.Show("w500 h160")
}

; --- 资源管理器路径获取 (Robust COM) ---
Explorer_GetSelection() {
    hwnd := WinExist("A")
    if !hwnd
        return ""

    WinClass := WinGetClass(hwnd)
    
    ; --- 情况 A: 桌面 (Progman / WorkerW) ---
    if (WinClass ~= "Progman|WorkerW") {
        try {
            ; 核心修复：ComValue(19, 8) 对应 VT_UI4, SCW_DESKTOP
            ; 这能直接获取桌面对象，不再报错
            oDesktop := ComObject("Shell.Application").Windows.Item(ComValue(19, 8))
            
            sel := oDesktop.Document.SelectedItems
            if (sel.Count > 0)
                return sel.Item(0).Path
        } catch {
            return ""
        }
    }
    ; --- 情况 B: 资源管理器 (CabinetWClass) ---
    else if (WinClass ~= "(Cabinet|Explore)WClass") {
        try {
            for window in ComObject("Shell.Application").Windows {
                if (window.HWND == hwnd) {
                    sel := window.Document.SelectedItems
                    if (sel.Count > 0)
                        return sel.Item(0).Path
                }
            }
        }
    }
    
    return ""
}

Explorer_GetPath() {
    hwnd := WinExist("A")
    if !hwnd
        return ""
    
    WinClass := WinGetClass(hwnd)
    
    ; 如果是桌面，返回桌面路径
    if (WinClass ~= "Progman|WorkerW")
        return A_Desktop
        
    ; 如果是资源管理器，返回当前目录
    if (WinClass ~= "(Cabinet|Explore)WClass") {
        try {
            for window in ComObject("Shell.Application").Windows {
                if (window.HWND == hwnd)
                    return window.Document.Folder.Self.Path
            }
        }
    }
    return ""
}

; --- 系统辅助 ---
RestoreAndExit(*) {
    global BarGui
    ShowOSD("Exiting...")
    Sleep(500)
    
    if IsObject(BarGui) 
        BarGui.Destroy()
        
    for hwnd in WinGetList() {
        try {
            class := WinGetClass(hwnd)
            if (class != "Progman" && class != "Shell_TrayWnd") 
                WinRestore(hwnd)
        }
    }
    ExitApp
}

GetVisibleWindows() {
    global BarGui
    list := WinGetList()
    windows := []
    for hwnd in list {
        try {
            if (BarGui && hwnd == BarGui.Hwnd) 
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
    A_TrayMenu.Add("Restore & Exit", RestoreAndExit)
}
; ==============================================================================
; 9. 模块：剪切板模块
; ==============================================================================
/**
 * 记录剪贴板内容到文件
 */
RecordClipboard() {
    global LastClipContent
    
    ; 1. 尝试获取文本内容
    try {
        txt := A_Clipboard
    } catch {
        return ; 如果剪贴板无法读取，直接返回
    }

    ; 2. 只有当剪贴板包含纯文本时才记录 (防止复制文件或图片时写入乱码)
    if (Type(txt) != "String" || txt == "")
        return

    ; 3. 防止连续重复记录相同内容
    if (txt == LastClipContent)
        return

    LastClipContent := txt
    
    ; 4. 格式化写入内容
    Timestamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    Separator := "------------------------------------------------------------------------------------------------"
    
    ; 构造最终文本块
    Content := Separator . "`r`n" . Timestamp . "`r`n" . txt . "`r`n`r`n"
    
    ; 5. 追加到文件 (指定 UTF-8 编码)
    try {
        FileAppend(Content, OutputFile, "UTF-8")
        
        ; 可选：显示一个小提示，告知用户记录成功 (不想被打扰可注释掉下面这行)
        ; ToolTip("已记录到 CB.txt")
        ; SetTimer () => ToolTip(), -1000
    } catch as e {
        ; 文件被占用或其他错误时忽略
    }
}

/**
 * 切换 Vim 窗口显示状态
 */
ToggleVimWindow() {
    global CurrentVimPID, VimPath, OutputFile

    ; 判断 Vim 窗口是否已经存在
    if (CurrentVimPID && WinExist("ahk_pid " . CurrentVimPID)) {
        ; --- 状态 A: 窗口存在，执行关闭 ---
        WinClose("ahk_pid " . CurrentVimPID)
        CurrentVimPID := 0
    } else {
        ; --- 状态 B: 窗口不存在，执行打开 ---
        
        ; 使用 "+$" 参数告诉 Vim 打开后直接跳转到最后一行 (无需 Send G)
        RunCmd := Format('"{1}" "+$" "{2}"', VimPath, OutputFile)
        
        try {
            Run(RunCmd, , , &pid)
            CurrentVimPID := pid
            
            ; 等待窗口出现 (最多等 3 秒)
            if WinWait("ahk_pid " . pid, , 3) {
                ; 设置置顶
                WinSetAlwaysOnTop(1, "ahk_pid " . pid)
                ; 移动窗口 (宽和高如果不需要改变，可以去掉后两个参数)
                WinMove(VimWinX, VimWinY, , , "ahk_pid " . pid)
                ; 激活窗口
                WinActivate("ahk_pid " . pid)
            }
        } catch as e {
            MsgBox("无法启动 Vim，请检查路径配置：`n" . VimPath)
        }
    }
}
