#Requires AutoHotkey v2.0
#SingleInstance Force
#WinActivateForce
; ==============================================================================
;全局配置与变量 (Configuration)
; ==============================================================================

; --- 环境设置 ---
SetWorkingDir(A_ScriptDir)
CoordMode("Mouse", "Screen")
SetTitleMatchMode(2)
SetWinDelay(0)
SetControlDelay(0)

; --- 声明全局变量 ---
global Color_Bg, Color_Text, Color_Active, BarHeight
global MenuSize, Radius, CenterZone, FontSize, FontSizeActive
global ButtonDir, OutputDir, OutputFile, VimPath, TerminalExe
global VimWinX, VimWinY, VimWinWidth, VimWinHeight
global WorkStart, WorkEnd
global PieConfig
global ConfigFile := A_ScriptDir . "\wm_config.ini" ; 定义配置文件路径

; --- 状态变量 ---
global CurrentDesktop := 1
global DesktopCount   := 9
global Desktops       := Map()
global AlwaysVisible  := Map()
global BarVisible     := true
global CurrentVimPID  := 0
global LastClipContent := ""
global BarGui := "", BarLeftText := "", BarRightText := "", BarProgress := ""

; --- 环形菜单固定配置 ---
PieConfig := Map(
    "Top", "↑", "TopRight", "↗", "Right", "→", "DownRight", "↘", 
    "Down", "↓", "DownLeft", "↙", "Left", "←", "TopLeft", "↖", "Center", "●"
)

; ==============================================================================
;启动流程 (Initialization)
; ==============================================================================

LoadOrInitConfig()
; 初始化桌面数组
Loop DesktopCount {
    Desktops[A_Index] := []
}

; 检查目录
if !DirExist(OutputDir)
    DirCreate(OutputDir)
if !DirExist(ButtonDir)
    DirCreate(ButtonDir)

if InitializeButtons() {
    Reload() ; 重新加载以生效 Include
}

; 启动 UI 模块
CreateStatusBar()
UpdateStatusBar()
UpdateClockAndProgress()
SetTimer(UpdateClockAndProgress, 1000)
SetupTrayIcon()
if !DirExist(OutputDir)
DirCreate(OutputDir)
RecordClipboard() ; 启动时检查一次剪贴板

; ==============================================================================
; 快捷键绑定 (Key Bindings)
; ==============================================================================

; --- 帮助系统 ---
Hotkey("!/", ShowHelpGui)                    ; Alt + / : 显示帮助菜单

; --- 桌面管理 (Alt + 1-9) ---
Loop 9 {
    i := A_Index
    Hotkey("!" . i, SwitchDesktop.Bind(i))        ; 切换桌面
    Hotkey("!+" . i, MoveWindowToDesktop.Bind(i)) ; 移动窗口
    Hotkey("^!" . i, MoveAndSwitch.Bind(i))       ; 移动并跟随
}

; --- 核心 WM 功能 ---
Hotkey("!d", TileCurrentDesktop)             ; Alt + D : 智能平铺
Hotkey("!+g", GatherAllToCurrent)            ; Alt + Shift + G : 召唤所有窗口
Hotkey("^!t", TogglePin)                     ; Ctrl + Alt + T : 钉住窗口
Hotkey("^!b", ToggleBar)                     ; Ctrl + Alt + B : 开关顶栏
Hotkey("!F12", RestoreAndExit)               ; Alt + F12 : 还原并退出

; --- 窗口操作 ---
Hotkey("!q", CloseWindowUnderMouse)          ; Alt + Q : 关闭窗口
Hotkey("!MButton", CloseWindowUnderMouse)    ; Alt + 中键 : 关闭窗口
Hotkey("!f", ToggleMaximizeUnderMouse)       ; Alt + F : 最大化/还原
Hotkey("!t", ToggleTopUnderMouse)            ; Alt + T : 置顶/取消
Hotkey("!w", HideUnderMouse)                 ; Alt + W : 最小化

; --- 鼠标增强 ---
Hotkey("!WheelUp", AdjustTransparency.Bind(20))   ; Alt + 滚轮上 : 增加透明度
Hotkey("!WheelDown", AdjustTransparency.Bind(-20))
~LButton & RButton::Send("^c")                    ; 左右键同按 : 复制
~RButton & LButton::Send("^c")

; --- 工具与剪贴板 ---
Hotkey("!Enter", LaunchTerminal)             ; Alt + Enter : 打开终端
Hotkey("!s", (*) => Run("devmgmt.msc"))      ; Alt + S : 设备管理器
Hotkey("!n", (*) => Run("ncpa.cpl"))         ; Alt + N : 网络管理器
Hotkey("!v", OpenWithVim)                    ; Alt + V : Vim 打开文件
Hotkey("!x", ShowPowerMenu)                  ; Alt + X : 电源菜单

!r::{
    Reload                                   ; Alt + R :刷新配置
    }

^`:: ToggleVimWindow()                       ; Ctrl + ` : 剪贴板历史
~^c:: (Sleep(100), RecordClipboard())        ; 监听复制

; --- 环形菜单 ---
~Space & RButton:: PieMenu.Start()

Space Up:: 
RButton Up:: 
{
    if PieMenu.IsActive
        PieMenu.Execute()
}

; ==============================================================================
; 功能实现模块 (Function Modules)
; ==============================================================================
; ------------------------------------------------------------------------------
; [Module] 配置文件
; ------------------------------------------------------------------------------
LoadOrInitConfig() {
    global
    
    ; 1. 如果配置文件不存在，生成默认配置
    if !FileExist(ConfigFile) {
        DefaultIni := "
        (
        [ZhangXuWei_WM_Config]

        [Visual]
        ; 背景颜色 (深灰)
        Color_Bg=181818
        ; 文字颜色 (浅灰)
        Color_Text=CCCCCC
        ; 高亮/激活颜色 (紫色)
        Color_Active=A020F0
        ; 顶部状态栏高度
        BarHeight=35
        
        [PieMenu]
        ; 环形菜单直径
        MenuSize=300
        ; 中心死区范围
        CenterZone=40
        ; 菜单字体大小
        FontSize=14
        ; 选中项字体大小
        FontSizeActive=22
        
        [Paths]
        ; 按钮脚本目录
        ButtonDir=Buttons
        ; 剪贴板记录输出目录
        OutputDir=C:\Users\Administrator\Desktop\zxw
        ; Vim 编辑器路径
        VimPath=C:\Program Files\Vim\vim91\vim.exe
        ; 终端路径
        TerminalExe=C:\Soft\terminal\WindowsTerminal.exe
        
        [Layout]
        ; Vim 浮动窗口坐标 X
        VimWinX=400
        ; Vim 浮动窗口坐标 Y
        VimWinY=0
        ; Vim 浮动窗口宽度
        VimWinWidth=1000
        ; Vim 浮动窗口高度
        VimWinHeight=800

        [WorkTime]
        ; 工作时间 格式为时分
        WorkStart=0900
        WorkEnd=1745
        )"
        
        try {
            FileAppend(DefaultIni, ConfigFile, "UTF-8")
            MsgBox("检测到首次运行，已生成配置文件：`n" . ConfigFile . "`n`n请根据需要修改配置。", "WM Config", "Iconi")
        } catch as e {
            MsgBox("无法创建配置文件，请检查权限！`n" . e.Message)
        }
    }

    ; 2. 从 INI 文件读取配置 (IniRead, 文件名, 节, 键, 默认值)
    ; 注意：IniRead 读出来是字符串，对于数字计算，建议转为 Number/Integer
    
    ; --- Visual ---
    Color_Bg      := IniRead(ConfigFile, "Visual", "Color_Bg", "181818")
    Color_Text    := IniRead(ConfigFile, "Visual", "Color_Text", "CCCCCC")
    Color_Active  := IniRead(ConfigFile, "Visual", "Color_Active", "A020F0")
    BarHeight     := Integer(IniRead(ConfigFile, "Visual", "BarHeight", "28"))

    ; --- PieMenu ---
    MenuSize      := Integer(IniRead(ConfigFile, "PieMenu", "MenuSize", "300"))
    Radius        := MenuSize / 2  ; Radius 是计算属性，不需要存ini，直接算
    CenterZone    := Integer(IniRead(ConfigFile, "PieMenu", "CenterZone", "40"))
    FontSize      := Integer(IniRead(ConfigFile, "PieMenu", "FontSize", "14"))
    FontSizeActive:= Integer(IniRead(ConfigFile, "PieMenu", "FontSizeActive", "22"))

    ; --- Paths ---
    ; 处理相对路径：如果 INI 里写的是 "Buttons"，我们把它转为绝对路径
    bDirTemp      := IniRead(ConfigFile, "Paths", "ButtonDir", "Buttons")
    ButtonDir     := (bDirTemp ~= "^[a-zA-Z]:") ? bDirTemp : (A_ScriptDir . "\" . bDirTemp)
    
    OutputDir     := IniRead(ConfigFile, "Paths", "OutputDir", "C:\Users\Administrator\Desktop\zxw")
    OutputFile    := OutputDir . "\CB.txt" ; 拼接文件名
    
    VimPath       := IniRead(ConfigFile, "Paths", "VimPath", "C:\Program Files\Vim\vim91\vim.exe")
    TerminalExe   := IniRead(ConfigFile, "Paths", "TerminalExe", "C:\Soft\terminal\WindowsTerminal.exe")

    ; --- Layout ---
    VimWinX       := Integer(IniRead(ConfigFile, "Layout", "VimWinX", "400"))
    VimWinY       := Integer(IniRead(ConfigFile, "Layout", "VimWinY", "0"))
    VimWinWidth   := Integer(IniRead(ConfigFile, "Layout", "VimWinWidth", "1000"))
    VimWinHeight  := Integer(IniRead(ConfigFile, "Layout", "VimWinHeight", "800"))

    ; --- WorkTime ---
    WorkStart     := IniRead(ConfigFile, "WorkTime", "WorkStart", "0900")
    WorkEnd       := IniRead(ConfigFile, "WorkTime", "WorkEnd", "1745")
}


; ------------------------------------------------------------------------------
; [Module] 帮助 GUI
; ------------------------------------------------------------------------------
ShowHelpGui(*) {
    static helpGui := ""
    
    ; --- 定义关闭检测函数 (嵌套函数) ---
    CloseWatcher() {
        if !IsObject(helpGui) {
            SetTimer CloseWatcher, 0 ; 关闭定时器
            return
        }

        if GetKeyState("Escape", "P") || GetKeyState("LButton", "P") {
            try helpGui.Destroy()
            helpGui := ""            ; 清空变量
            SetTimer CloseWatcher, 0 ; 关闭定时器
        }
    }

    ; --- 主逻辑 ---
    if IsObject(helpGui) {
        helpGui.Destroy()
        helpGui := ""
        return
    }

    ; --- 创建 GUI ---
    ; 忽略 DPI 缩放 (-DPIScale)
    helpGui := Gui("-Caption +AlwaysOnTop +ToolWindow -DPIScale +Owner")
    helpGui.BackColor := Color_Bg
    helpGui.SetFont("s16 w700 c" . Color_Active, "Segoe UI")
    helpGui.Add("Text", "x0 y25 w600 Center", "ZhangXuWei WM HELP")
    
    helpGui.SetFont("s10 w600 c" . Color_Active)
    helpGui.Add("Text", "x50 y65 w500 h2 0x10") ; 紫色分割线

    ; 帮助列表
    shortcuts := [
        ["Alt + /", "显示/隐藏帮助菜单"],
        ["Space + RClick", "环形菜单 (Pie Menu)"],
        ["Alt + 1-9", "切换桌面 (Shift 移动)"],
        ["Alt + LButton", "移动窗口"],
        ["Alt + RButton", "调整窗口大小"],
        ["Alt + Wheel", "调整窗口透明度"],
        ["Alt + Q", "关闭窗口"],
        ["Alt + D", "智能平铺"],
        ["Alt + W", "最小化窗口"],
        ["Alt + F", "最大化/还原"],
        ["Alt + R", "强制刷新脚本"],
        ["Alt + T", "置顶/取消置顶"],
        ["Alt + F12", "安全退出脚本"],
        ["Ctrl + ``", "剪贴板历史 (Vim)"],
        ["Ctrl + Alt + B", "开关顶部 Bar"],
        ["Alt + V", "使用Vim编辑选中文件"],
        ["Alt + X", "电源菜单"]
    ]

    helpGui.SetFont("s11 w400 c" . Color_Text)
    for i, item in shortcuts {
        yPos := 80 + (i-1)*30
        helpGui.Add("Text", "x60 y" . yPos . " w160 c" . Color_Active, item[1])
        helpGui.Add("Text", "x220 y" . yPos . " w320", item[2])
    }
    
    helpGui.Show("Center")
    
    ; --- 启动检测定时器 ---
    SetTimer CloseWatcher, 50
}


; ------------------------------------------------------------------------------
; [Module] 外部按钮脚本管理
; ------------------------------------------------------------------------------
InitializeButtons() {
    dirs := ["Top", "TopRight", "Right", "DownRight", "Down", "DownLeft", "Left", "TopLeft"]
    created := false
    
    for d in dirs {
        fPath := ButtonDir . "\" . d . ".ahk"
        if !FileExist(fPath) {
            ; 生成符合要求的模板
            template := '
            (
            SetWorkingDir(A_ScriptDir)
            CoordMode("Mouse", "Screen")
            SetTitleMatchMode(2)
            SetWinDelay(0)
            SetControlDelay(0)

            %dir%(){
                ToolTip "%dir%"
                Sleep 200
                ToolTip()
            }
            )'
            FileAppend(StrReplace(template, "%dir%", d), fPath, "UTF-8")
            created := true
        }
    }
    return created ; 返回是否创建了新文件
}

; ------------------------------------------------------------------------------
; [Module] OSD 提示系统
; ------------------------------------------------------------------------------
ShowOSD(text) {
    try{
    static OsdGui := ""
    if IsObject(OsdGui)
        OsdGui.Destroy()
    ; 忽略 DPI 缩放
    OsdGui := Gui("+AlwaysOnTop -Caption +ToolWindow +Disabled +Owner -DPIScale")
    OsdGui.BackColor := Color_Bg
    OsdGui.SetFont("s20 w600 c" . Color_Active, "Segoe UI")
    OsdGui.Add("Text", "Center", text)
    OsdGui.Show("NoActivate AutoSize y850")
    WinSetTransparent(200, OsdGui.Hwnd)
    SetTimer(() => (IsObject(OsdGui) ? OsdGui.Destroy() : ""), -1000)
    }
}
; ------------------------------------------------------------------------------
; [Module] 窗口操作 (带 GUI 提示)
; ------------------------------------------------------------------------------
CloseWindowUnderMouse(*) {
    MouseGetPos(,, &hwnd)
    try {
        WinClose(hwnd)
        ShowOSD("Closing Windows...")
    }
}

HideUnderMouse(*) {
    MouseGetPos(,, &hwnd)
    try {
        WinMinimize(hwnd)
        ShowOSD("WinMinimized")
    }
}

ToggleMaximizeUnderMouse(*) {
    MouseGetPos(,, &hwnd)
    try {
        if WinGetMinMax(hwnd) {
            WinRestore(hwnd)
            ShowOSD("WinRestore")
        } else {
            WinMaximize(hwnd)
            ShowOSD("WinMaximized")
        }
    }
}

ToggleTopUnderMouse(*) {
    MouseGetPos(,, &hwnd)
    try {
        WinSetAlwaysOnTop(-1, hwnd)
        state := WinGetExStyle(hwnd)
        ShowOSD((state & 0x8) ? "WinOnTop" : "WinOffTop")
    }
}

AdjustTransparency(amount, *) {
    MouseGetPos(,, &hwnd)
    try {
        cur := WinGetTransparent(hwnd)
        if !IsNumber(cur) 
            cur := 255
        newVal := cur + amount
        newVal := Max(2.55, Min(255, newVal))
        WinSetTransparent(newVal, hwnd)
        ShowOSD("WinTransparent: " . Integer(newVal/2.55) . "%")
    }
}

; ------------------------------------------------------------------------------
; [Module] 环形菜单 (Pie Menu)
; ------------------------------------------------------------------------------
class PieMenu {
    static IsActive := false, GuiObj := "", Labels := Map(), TimerFn := ObjBindMethod(PieMenu, "CheckMouse")
    static StartX := 0, StartY := 0, CurrentSector := "", LastSector := ""

    static Start() {
        if this.IsActive || GetKeyState("Alt", "P")
            return
        this.IsActive := true
        MouseGetPos(&x, &y)
        this.StartX := x, this.StartY := y, this.CurrentSector := "Center", this.LastSector := ""
        this.CreateGui()
        SetTimer(this.TimerFn, 10)
    }

    static CreateGui() {
        ; 忽略 DPI 缩放，确保物理定位
        this.GuiObj := Gui("-Caption +AlwaysOnTop +ToolWindow +Owner +E0x20 -DPIScale") 
        this.GuiObj.BackColor := Color_Bg
        WinSetTransparent(220, this.GuiObj)
        WinSetRegion("0-0 w" . MenuSize . " h" . MenuSize . " E", this.GuiObj)
        
        this.Labels["Center"] := this.GuiObj.Add("Text", "x" Radius-20 " y" Radius-20 " w40 h40 Center +0x200 c" Color_Text, PieConfig["Center"])
        
        dirs := ["Right", "DownRight", "Down", "DownLeft", "Left", "TopLeft", "Top", "TopRight"]
        loop 8 {
            dir := dirs[A_Index], angle := (A_Index-1)*45, rad := angle*0.01745329
            fX := Radius + Cos(rad)*Radius*0.75 - 30
            fY := Radius + Sin(rad)*Radius*0.75 - 20
            this.Labels[dir] := this.GuiObj.Add("Text", "x" fX " y" fY " w60 h40 Center +0x200 c" Color_Text, PieConfig[dir])
        }
        this.GuiObj.Show("x" this.StartX-Radius " y" this.StartY-Radius " w" MenuSize " h" MenuSize " NoActivate")
    }

    static CheckMouse() {
        if !this.IsActive
            return
        MouseGetPos(&mx, &my)
        dx := mx - this.StartX
        dy := my - this.StartY
        dist := Sqrt(dx*dx + dy*dy)

        if (dist < CenterZone) {
            this.CurrentSector := "Center"
        } else {
            angle := DllCall("msvcrt\atan2", "Double", dy, "Double", dx, "Cdecl Double") * 180 / 3.1415926
            if (angle < 0)
                angle += 360
            sectorIdx := Round(angle / 45)
            if (sectorIdx == 8)
                sectorIdx := 0
            static dirMap := ["Right", "DownRight", "Down", "DownLeft", "Left", "TopLeft", "Top", "TopRight"]
            this.CurrentSector := dirMap[sectorIdx + 1]
        }

        if (this.CurrentSector != this.LastSector) {
            this.UpdateUI()
            this.LastSector := this.CurrentSector
        }
    }

    static UpdateUI() {
        if !IsObject(this.GuiObj)
            return
        for dir, ctrl in this.Labels {
            try {
                ctrl.SetFont("s" . FontSize . " c" . Color_Text . " w600")
                ctrl.Opt("c" . Color_Text)
            }
        }
        if this.Labels.Has(this.CurrentSector) {
            try {
                curr := this.Labels[this.CurrentSector]
                curr.SetFont("s" . FontSizeActive . " c" . Color_Active . " w700")
                curr.Opt("c" . Color_Active)
            }
        }
    }

    static Execute() {
        this.IsActive := false
        SetTimer(this.TimerFn, 0)
        if IsObject(this.GuiObj)
            this.GuiObj.Destroy()
        if (this.CurrentSector != "Center" && this.CurrentSector != "") {
            ; 动态调用外部引用进来的函数
            try %this.CurrentSector%()
            catch
                ShowOSD("Function Loust: " . this.CurrentSector)
        }
    }
}

; ------------------------------------------------------------------------------
; [Module] 虚拟桌面与状态栏
; ------------------------------------------------------------------------------
SwitchDesktop(target, *) {
    global CurrentDesktop, Desktops, AlwaysVisible
    if (target == CurrentDesktop) {
        ShowOSD("Desktop " . target)
        return
    }
    Desktops[CurrentDesktop] := GetVisibleWindows()
    for hwnd in Desktops[CurrentDesktop]
        if (!AlwaysVisible.Has(hwnd))
            try WinMinimize(hwnd)
    for hwnd in Desktops[target]
        try WinRestore(hwnd)
    for hwnd, _ in AlwaysVisible
        try WinRestore(hwnd)
    
    CurrentDesktop := target
    UpdateStatusBar()
    ShowOSD("DeskTop " . CurrentDesktop)
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

CreateStatusBar() {
    global BarGui, BarLeftText, BarRightText, BarProgress, BarHeight

    try {
        if IsObject(BarGui)
            BarGui.Destroy()
    }

    ; 创建 GUI
    BarGui := Gui("-Caption +AlwaysOnTop +ToolWindow +Owner +E0x08000000 -DPIScale")
    BarGui.BackColor := "181818"
    ; --- 动态计算垂直居中坐标 ---
    ; 假设文字高度约为 20px, 进度条高度设定为 6px
    TextY := (BarHeight - 20) / 2   ; 文字的 Y 坐标
    ProgY := (BarHeight - 6) / 2    ; 进度条的 Y 坐标
    
    ; 左侧：桌面指示器
    BarGui.SetFont("s10 w600 c" . Color_Active , "Segoe UI")
    ; 使用变量 TextY 替换原来的 y4
    BarLeftText := BarGui.Add("Text", "x15 y" . TextY . " w300 h20 BackgroundTrans", "")
    
    ; 中间：下班进度条
    ProgressWidth := 300
    ProgressX := (A_ScreenWidth / 2) - (ProgressWidth / 2)
    
    ; 背景底槽 (使用 ProgY 替换 y10)
    BarGui.Add("Text", "x" ProgressX " y" . ProgY . " w" ProgressWidth " h6 Background333333", "") 
    
    ; 进度实体 (紫色) (使用 ProgY 替换 y10)
    ProgressOptions := Format("x{1} y{2} w{3} h6 c{4} Background333333 +Smooth",ProgressX,ProgY,ProgressWidth,Color_Active )
    BarProgress := BarGui.Add("Progress",ProgressOptions, 0)
    
    ; 右侧：时钟
    BarGui.SetFont("s10 w600 c" . Color_Active , "Segoe UI")
    ; 使用变量 TextY 替换原来的 y4
    BarRightText := BarGui.Add("Text", "x" . (A_ScreenWidth - 260 ) . " y" . TextY . " w250 h20 BackgroundTrans Right", "")
    
    ; 显示 Bar
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
    global WorkStart, WorkEnd
    if !IsObject(BarRightText)
        return

    ; 更新时间
    try BarRightText.Value := FormatTime(, "yyyy-MM-dd   HH:mm")

    ; --- 进度条逻辑 ---
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

TileCurrentDesktop(*) {
    global BarHeight, BarVisible
    windows := GetVisibleWindows()
    count := windows.Length
    if (count == 0) {
        ShowOSD("No Windows To Tile")
        return
    }
    ShowOSD("Tile: " . count)
    MonitorGetWorkArea(1, &WL, &WT, &WR, &WB)
    if (BarVisible)
        WT += BarHeight
    W := WR - WL, H := WB - WT 
    
    if (count == 1) {
        try WinRestore(windows[1]), WinMove(WL, WT, W, H, windows[1])
    } 
    else if (count == 2) {
        try WinRestore(windows[1]), WinMove(WL, WT, W/2, H, windows[1])
        try WinRestore(windows[2]), WinMove(WL + W/2, WT, W/2, H, windows[2])
    }
    else if (count == 3) {

        try WinRestore(windows[1]), WinMove(WL, WT, W/2, H, windows[1])
        try WinRestore(windows[2]), WinMove(WL + W/2, WT, W/2, H/2, windows[2])
        try WinRestore(windows[3]), WinMove(WL + W/2, WT + H/2, W/2, H/2, windows[3])
    }
    else if (count == 5) {
        colW := W / 3
        halfH := H / 2
        try WinRestore(windows[1]), WinMove(WL + colW, WT, colW, H, windows[1])
        try WinRestore(windows[2]), WinMove(WL, WT, colW, halfH, windows[2])
        try WinRestore(windows[3]), WinMove(WL, WT + halfH, colW, halfH, windows[3])
        try WinRestore(windows[4]), WinMove(WL + 2*colW, WT, colW, halfH, windows[4])
        try WinRestore(windows[5]), WinMove(WL + 2*colW, WT + halfH, colW, halfH, windows[5])

    }
    else if (Mod(count, 2) != 0) {
        try {
            itemWidth := W / count
            for i, hwnd in windows
                WinRestore(hwnd), WinMove(WL + (i-1)*itemWidth, WT, itemWidth, H, hwnd)
        }
    } else {
        try {
            cols := count / 2, itemW := W / cols, itemH := H / 2
            for i, hwnd in windows {
                idx := i - 1, r := Floor(idx/cols), c := Mod(idx, cols)
                WinRestore(hwnd), WinMove(WL + c*itemW, WT + r*itemH, itemW, itemH, hwnd)
            }
        }
    }
}

; ------------------------------------------------------------------------------
; [Module] 剪贴板与工具
; ------------------------------------------------------------------------------
RecordClipboard() {
    global LastClipContent
    try txt := A_Clipboard
    catch 
        return
    if (Type(txt) != "String" || txt == "" || txt == LastClipContent)
        return
    LastClipContent := txt
    Content := "------------------------------------------------------------------------------------------------`r`n"
             . FormatTime(, "yyyy-MM-dd HH:mm:ss") . "`r`n" . txt . "`r`n`r`n"
    try FileAppend(Content, OutputFile, "UTF-8")
}

ToggleVimWindow() {
    global CurrentVimPID, VimPath, OutputFile, VimWinX, VimWinY
    if (CurrentVimPID && WinExist("ahk_pid " . CurrentVimPID)) {
        WinClose("ahk_pid " . CurrentVimPID)
        CurrentVimPID := 0
    } else {
        RunCmd := Format('"{1}" "+$" "{2}"', VimPath, OutputFile)
        try {
            Run(RunCmd, , , &pid)
            CurrentVimPID := pid
            if WinWait("ahk_pid " . pid, , 3) {
                WinSetAlwaysOnTop(1, "ahk_pid " . pid)
                WinMove(VimWinX, VimWinY, , , "ahk_pid " . pid)
                WinActivate("ahk_pid " . pid)
            }
        } catch {
            ShowOSD("Vim Boot Filed")
        }
    }
}

LaunchTerminal(*) {
    path := Explorer_GetPath()
    try Run('"' . TerminalExe . '"' . (path ? ' -d "' . path . '"' : ""))
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
        pGui.Destroy(), pGui := ""
        return
    }
    pGui := Gui("+AlwaysOnTop -Caption +ToolWindow +Owner")
    pGui.BackColor := "2e3440"
    pGui.SetFont("s12", "Arial")
    pGui.Add("Text", "x0 y15 w500 Center c" . Color_Active, "System Power Menu")
    pGui.Add("Text", "x50 y45 w400 h2 0x10")
    
    AddBtn(x, y, txt, fn, col) {
        btn := pGui.Add("Text", "x" x " y" y " w120 h60 Center 0x200 +Border cWhite Background" col, txt)
        btn.OnEvent("Click", fn)
    }
    AddBtn(50, 70, "Shutdown", (*) => Shutdown(1), "b48ead")
    AddBtn(190, 70, "Sleep", (*) => DllCall("PowrProf\SetSuspendState", "Int", 0, "Int", 0, "Int", 0), "5e81ac")
    AddBtn(330, 70, "Reboot", (*) => Shutdown(2), "bf616a")
    pGui.OnEvent("Escape", (*) => (pGui.Destroy(), pGui := ""))
    pGui.Show("w500 h160")
}

; ------------------------------------------------------------------------------
; [Module] 系统辅助
; ------------------------------------------------------------------------------
RestoreAndExit(*) {
    global BarGui
    ShowOSD("Script Shutting Down ...")
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

Explorer_GetSelection() {
    hwnd := WinExist("A")
    if !hwnd
        return ""

    WinClass := WinGetClass(hwnd)
    
    ; --- 情况 A: 桌面 (Progman / WorkerW) ---
    if (WinClass ~= "Progman|WorkerW") {
        try {
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
    
    if (WinClass ~= "Progman|WorkerW")
        return A_Desktop
        
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

SetupTrayIcon() {
    A_TrayMenu.Delete()
    A_TrayMenu.Add("Restore & Exit", RestoreAndExit)
}

; ------------------------------------------------------------------------------
; 模块：KDE 交互 (Mouse Interaction)
; ------------------------------------------------------------------------------

!LButton:: {
    MouseGetPos(,, &hwnd)
    if (WinGetMinMax(hwnd) == 1) {
        try {
            WinRestore(hwnd)
            WinGetPos(,, &rw, &rh, hwnd)
            MouseGetPos(&mx, &my)
            WinMove(mx - rw/2, my - rh/2,,, hwnd)
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
    MouseGetPos(,, &hwnd)
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
; ------------------------------------------------------------------------------
; 外部脚本引用 (External Buttons Include)
; ------------------------------------------------------------------------------

; 使用 *i 忽略错误，确保 InitializeButtons 创建文件后重载能正常读取
#Include "*i %A_ScriptDir%\Buttons\Top.ahk"
#Include "*i %A_ScriptDir%\Buttons\TopRight.ahk"
#Include "*i %A_ScriptDir%\Buttons\Right.ahk"
#Include "*i %A_ScriptDir%\Buttons\DownRight.ahk"
#Include "*i %A_ScriptDir%\Buttons\Down.ahk"
#Include "*i %A_ScriptDir%\Buttons\DownLeft.ahk"
#Include "*i %A_ScriptDir%\Buttons\Left.ahk"
#Include "*i %A_ScriptDir%\Buttons\TopLeft.ahk"
