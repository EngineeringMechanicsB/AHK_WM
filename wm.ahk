#Requires AutoHotkey v2.0
#SingleInstance Force
#WinActivateForce

; ==============================================================================
;  WM Script  (Refactored & Bug-fixed)
;  - 修复了 SetupTrayIcon 中函数嵌套错误
;  - 修复 !r 热键写法、class 关键字冲突、ShowOSD 静态变量作用域
;  - 修复 AdjustTransparency 下限、剪贴板录制阻塞
;  - 新增：Alt+方向键 窗口吸附 / 布局快照保存恢复 / 配置热重载 / 多屏 OSD
; ==============================================================================

SetWorkingDir(A_ScriptDir)
CoordMode("Mouse", "Screen")
SetTitleMatchMode(2)
SetWinDelay(0)
SetControlDelay(0)

; ------------------------------------------------------------------------------
; 全局变量（保持原架构，便于和你既有习惯对齐）
; ------------------------------------------------------------------------------
global Color_Bg, Color_Text, Color_Active, BarHeight, BarTransparent, BarFontSize
global MenuSize, Radius, CenterZone, FontSize, FontSizeActive, MenuTransparent
global ButtonDir, OutputDir, OutputFile, VimPath, TerminalExe
global VimWinX, VimWinY, VimWinWidth, VimWinHeight
global OSDHeight, OSDTransparent
global WorkStart, WorkEnd, WDayBar, WorkTime, Color_Task, TaskTimes
global PieConfig
global ConfigFile      := A_ScriptDir . "\wm_config.ini"
global CurrentDesktop  := 1
global DesktopCount    := 9
global Desktops        := Map()
global AlwaysVisible   := Map()
global BarVisible      := true
global CurrentVimPID   := 0
global LastClipContent := ""
global BarGui := "", BarLeftText := "", BarRightText := "", BarProgress := ""
global LayoutSnapshot  := Map()       ; 新增：窗口布局快照

PieConfig := Map(
    "Top","↑", "TopRight","↗", "Right","→", "DownRight","↘",
    "Down","↓", "DownLeft","↙", "Left","←",  "TopLeft","↖", "Center","●"
)

; ==============================================================================
;  Initialization
; ==============================================================================
LoadOrInitConfig()

Loop DesktopCount
    Desktops[A_Index] := []

if !DirExist(OutputDir)
    DirCreate(OutputDir)
if !DirExist(ButtonDir)
    DirCreate(ButtonDir)

if InitializeButtons()
    Reload()

CreateStatusBar()
UpdateStatusBar()
UpdateClockAndProgress()
SetTimer(UpdateClockAndProgress, 1000)
SetupTrayIcon()

; 新增：用 OnClipboardChange 替代 ~^c + Sleep 阻塞热键的写法
OnClipboardChange(OnClipboardChanged)

; ==============================================================================
;  Hotkeys
; ==============================================================================
Hotkey("!/", ShowHelpGui)

Loop 9 {
    i := A_Index
    Hotkey("!"  . i, SwitchDesktop.Bind(i))
    Hotkey("!+" . i, MoveWindowToDesktop.Bind(i))
    Hotkey("^!" . i, MoveAndSwitch.Bind(i))
}

Hotkey("!d",       TileCurrentDesktop)
Hotkey("!+g",      GatherAllToCurrent)
Hotkey("^!t",      TogglePin)
Hotkey("^!b",      ToggleBar)
Hotkey("!F12",     RestoreAndExit)

Hotkey("!q",       CloseWindowUnderMouse)
Hotkey("!MButton", CloseWindowUnderMouse)
Hotkey("!f",       ToggleMaximizeUnderMouse)
Hotkey("!t",       ToggleTopUnderMouse)
Hotkey("!w",       HideUnderMouse)

Hotkey("!WheelUp",   AdjustTransparency.Bind(20))
Hotkey("!WheelDown", AdjustTransparency.Bind(-20))

Hotkey("!Enter", LaunchTerminal)
Hotkey("!s",     (*) => Run("devmgmt.msc"))
Hotkey("!n",     (*) => Run("ncpa.cpl"))
Hotkey("!v",     OpenWithVim)
Hotkey("!x",     ShowPowerMenu)
Hotkey("!r",     (*) => Reload())

; 新增：Alt + 方向键 → 窗口吸附（半屏 / 全屏）
Hotkey("!Left",  SnapWindow.Bind("Left"))
Hotkey("!Right", SnapWindow.Bind("Right"))
Hotkey("!Up",    SnapWindow.Bind("Up"))
Hotkey("!Down",  SnapWindow.Bind("Down"))

; 新增：布局快照
Hotkey("!+s",  SaveLayout)
Hotkey("!+r",  RestoreLayout)

; 不能用 Hotkey() 注册的特殊组合
~LButton & RButton:: Send("^c")
~RButton & LButton:: Send("^c")

^`:: ToggleVimWindow()

~Space & RButton::  PieMenu.Start()
Space Up::          (PieMenu.IsActive ? PieMenu.Execute() : 0)
RButton Up::        (PieMenu.IsActive ? PieMenu.Execute() : 0)

; ==============================================================================
;  [Module] Config
; ==============================================================================
LoadOrInitConfig() {
    global

    if !FileExist(ConfigFile) {
        DefaultIni := "
        (
        [WM_Config]

        [Visual]
        Color_Bg=181818
        Color_Text=CCCCCC
        Color_Active=A020F0
        BarHeight=35
        BarTransparent=200
        BarFontSize=10

        [PieMenu]
        MenuSize=300
        CenterZone=40
        FontSize=14
        FontSizeActive=22
        MenuTransparent=200

        [Paths]
        ButtonDir=Buttons
        OutputDir=C:\Users\Administrator\Documents
        VimPath=C:\Windows\system32\notepad.exe
        TerminalExe=C:\Windows\system32\cmd.exe

        [Layout]
        VimWinX=400
        VimWinY=0
        VimWinWidth=1000
        VimWinHeight=800

        [OSD]
        OSDHeight=850
        OSDTransparent=200

        [WorkTime]
        WorkStart=0900
        WorkEnd=1745
        WDayBar=off
        WorkTime=on
        Color_Task=069700
        TaskTimes=1_1200_1300;2_1200_1300;3_1200_1300;4_1200_1300;5_1200_1300;6_1200_1300;7_1200_1300;
        )"
        try {
            FileAppend(DefaultIni, ConfigFile, "UTF-8")
            MsgBox("First run detected. Config file created at:`n" . ConfigFile
                 . "`n`nPress 'Alt + /' to open Help.", "WM Config", "Iconi")
        } catch as e {
            MsgBox("Failed to create config file: " . e.Message)
            ExitApp
        }
    }

    ; --- Visual ---
    Color_Bg        := IniRead(ConfigFile, "Visual", "Color_Bg",        "181818")
    Color_Text      := IniRead(ConfigFile, "Visual", "Color_Text",      "CCCCCC")
    Color_Active    := IniRead(ConfigFile, "Visual", "Color_Active",    "A020F0")
    BarHeight       := Integer(IniRead(ConfigFile, "Visual", "BarHeight",       "35"))
    BarTransparent  := Integer(IniRead(ConfigFile, "Visual", "BarTransparent",  "200"))
    BarFontSize     := Integer(IniRead(ConfigFile, "Visual", "BarFontSize",     "10"))

    ; --- PieMenu ---
    MenuSize        := Integer(IniRead(ConfigFile, "PieMenu", "MenuSize",        "300"))
    Radius          := MenuSize / 2
    CenterZone      := Integer(IniRead(ConfigFile, "PieMenu", "CenterZone",      "40"))
    FontSize        := Integer(IniRead(ConfigFile, "PieMenu", "FontSize",        "14"))
    FontSizeActive  := Integer(IniRead(ConfigFile, "PieMenu", "FontSizeActive",  "22"))
    MenuTransparent := Integer(IniRead(ConfigFile, "PieMenu", "MenuTransparent", "200"))

    ; --- Paths ---
    bDirTemp        := IniRead(ConfigFile, "Paths", "ButtonDir", "Buttons")
    ButtonDir       := (bDirTemp ~= "^[a-zA-Z]:") ? bDirTemp : (A_ScriptDir . "\" . bDirTemp)
    OutputDir       := IniRead(ConfigFile, "Paths", "OutputDir",   "C:\Users\Administrator\Documents")
    OutputFile      := OutputDir . "\CB.txt"
    VimPath         := IniRead(ConfigFile, "Paths", "VimPath",     "C:\Windows\system32\notepad.exe")
    TerminalExe     := IniRead(ConfigFile, "Paths", "TerminalExe", "C:\Windows\system32\cmd.exe")

    ; --- Layout ---
    VimWinX         := Integer(IniRead(ConfigFile, "Layout", "VimWinX",      "400"))
    VimWinY         := Integer(IniRead(ConfigFile, "Layout", "VimWinY",      "0"))
    VimWinWidth     := Integer(IniRead(ConfigFile, "Layout", "VimWinWidth",  "1000"))
    VimWinHeight    := Integer(IniRead(ConfigFile, "Layout", "VimWinHeight", "800"))

    ; --- OSD ---
    OSDHeight       := Integer(IniRead(ConfigFile, "OSD", "OSDHeight",      "850"))
    OSDTransparent  := Integer(IniRead(ConfigFile, "OSD", "OSDTransparent", "200"))

    ; --- WorkTime ---
    WorkStart       := IniRead(ConfigFile, "WorkTime", "WorkStart",  "0900")
    WorkEnd         := IniRead(ConfigFile, "WorkTime", "WorkEnd",    "1745")
    WDayBar         := IniRead(ConfigFile, "WorkTime", "WDayBar",    "off")
    WorkTime        := IniRead(ConfigFile, "WorkTime", "WorkTime",   "on")
    Color_Task      := IniRead(ConfigFile, "WorkTime", "Color_Task", "069700")
    TaskTimes       := IniRead(ConfigFile, "WorkTime", "TaskTimes",  "")
}

; ==============================================================================
;  [Module] Help GUI
; ==============================================================================
ShowHelpGui(*) {
    static helpGui := ""

    CloseWatcher() {
        if !IsObject(helpGui) {
            SetTimer(CloseWatcher, 0)
            return
        }
        if GetKeyState("Escape", "P") || GetKeyState("LButton", "P") {
            try helpGui.Destroy()
            helpGui := ""
            SetTimer(CloseWatcher, 0)
        }
    }

    if IsObject(helpGui) {
        helpGui.Destroy(), helpGui := ""
        return
    }

    helpGui := Gui("-Caption +AlwaysOnTop +ToolWindow -DPIScale +Owner")
    helpGui.BackColor := Color_Bg
    helpGui.SetFont("s16 w700 c" . Color_Active, "Segoe UI")
    helpGui.Add("Text", "x0 y25 w600 Center", "HELP")
    helpGui.SetFont("s10 w600 c" . Color_Active)
    helpGui.Add("Text", "x50 y65 w500 h2 0x10")

    shortcuts := [
        ["Alt + /",            "Show/Hide Help Menu"],
        ["Space + RClick",     "Pie Menu (Mouse)"],
        ["Alt + 1-9",          "Switch Desktop (Shift to Move)"],
        ["Alt + LButton",      "Move Window"],
        ["Alt + RButton",      "Resize Window"],
        ["Alt + Wheel",        "Window Transparency"],
        ["Alt + Arrows",       "Snap Window (NEW)"],
        ["Alt + Shift + S/R",  "Save / Restore Layout (NEW)"],
        ["Alt + Shift + G",    "Gather All Windows"],
        ["Alt + Q",            "Close Window"],
        ["Alt + D",            "Smart Tiling"],
        ["Alt + W",            "Minimize Window"],
        ["Alt + F",            "Maximize / Restore"],
        ["Alt + R",            "Reload Script"],
        ["Alt + T",            "Toggle Pin / OnTop"],
        ["Ctrl + Alt + T",     "Toggle Always Visible"],
        ["Ctrl + ``",          "Clipboard History"],
        ["Ctrl + Alt + B",     "Toggle Top Bar"],
        ["Alt + V",            "Edit Selected File"],
        ["Alt + F12",          "Safely Exit"],
        ["Alt + X",            "Power Menu"]
    ]

    helpGui.SetFont("s11 w400 c" . Color_Text)
    for i, item in shortcuts {
        yPos := 80 + (i-1)*28
        helpGui.Add("Text", "x60 y"  . yPos . " w180 c" . Color_Active, item[1])
        helpGui.Add("Text", "x240 y" . yPos . " w320", item[2])
    }
    helpGui.Show("Center")
    SetTimer(CloseWatcher, 50)
}

; ==============================================================================
;  [Module] Pie Menu Buttons Init
; ==============================================================================
InitializeButtons() {
    dirs    := ["Top","TopRight","Right","DownRight","Down","DownLeft","Left","TopLeft"]
    created := false
    for d in dirs {
        fPath := ButtonDir . "\" . d . ".ahk"
        if !FileExist(fPath) {
            template := '
            (
            SetWorkingDir(A_ScriptDir)
            CoordMode("Mouse", "Screen")
            SetTitleMatchMode(2)
            SetWinDelay(0)
            SetControlDelay(0)

            %dir%() {
                ToolTip "%dir%"
                Sleep 200
                ToolTip()
            }
            )'
            FileAppend(StrReplace(template, "%dir%", d), fPath, "UTF-8")
            created := true
        }
    }
    return created
}

; ==============================================================================
;  [Module] OSD  (单例 + 多屏感知)
; ==============================================================================
class OSD {
    static GuiObj := 0
    static Timer  := 0

    static Show(text, duration := 1000) {
        ; 销毁旧 OSD（修复多次触发引用已销毁对象的隐患）
        if IsObject(this.GuiObj) {
            try this.GuiObj.Destroy()
            this.GuiObj := 0
        }
        if this.Timer
            SetTimer(this.Timer, 0)

        g := Gui("+AlwaysOnTop -Caption +ToolWindow +Disabled +Owner -DPIScale")
        g.BackColor := Color_Bg
        g.SetFont("s20 w600 c" . Color_Active, "Segoe UI")
        g.Add("Text", "Center", text)

        ; 在鼠标所在显示器居中显示
        MouseGetPos(&mx,)
        monIdx := GetMonitorIndexAtPoint(mx, OSDHeight)
        MonitorGet(monIdx, &mL,, &mR,)
        cx := (mL + mR) // 2

        g.Show(Format("NoActivate AutoSize Hide"))
        g.GetPos(,, &gw,)
        g.Show(Format("NoActivate AutoSize x{} y{}", cx - gw//2, OSDHeight))
        WinSetTransparent(OSDTransparent, g.Hwnd)

        this.GuiObj := g
        this.Timer  := () => (IsObject(this.GuiObj)
                              ? (this.GuiObj.Destroy(), this.GuiObj := 0) : 0)
        SetTimer(this.Timer, -duration)
    }
}
ShowOSD(text) => OSD.Show(text)        ; 旧调用兼容

GetMonitorIndexAtPoint(x, y) {
    loop MonitorGetCount() {
        MonitorGet(A_Index, &mL, &mT, &mR, &mB)
        if (x >= mL && x < mR && y >= mT && y < mB)
            return A_Index
    }
    return 1
}

; ==============================================================================
;  [Module] Window operations (under mouse)
; ==============================================================================
CloseWindowUnderMouse(*) {
    MouseGetPos(,, &hwnd)
    try (WinClose(hwnd), ShowOSD("Closing Window..."))
}

HideUnderMouse(*) {
    MouseGetPos(,, &hwnd)
    try (WinMinimize(hwnd), ShowOSD("WinMinimized"))
}

ToggleMaximizeUnderMouse(*) {
    MouseGetPos(,, &hwnd)
    try {
        if WinGetMinMax(hwnd) {
            WinRestore(hwnd),  ShowOSD("WinRestore")
        } else {
            WinMaximize(hwnd), ShowOSD("WinMaximized")
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
        ; 修复：下限改为整数 40（约 16%），避免接近 0 不可见
        newVal := Max(40, Min(255, Integer(cur) + amount))
        WinSetTransparent(newVal, hwnd)
        ShowOSD("Transparency: " . Round(newVal/255*100) . "%")
    }
}

; ==============================================================================
;  [Module] Pie Menu
; ==============================================================================
class PieMenu {
    static DirMap   := ["Right","DownRight","Down","DownLeft","Left","TopLeft","Top","TopRight"]
    static IsActive := false, GuiObj := "", Labels := Map()
    static TimerFn  := ObjBindMethod(PieMenu, "CheckMouse")
    static StartX := 0, StartY := 0, CurrentSector := "", LastSector := ""

    static Start() {
        if this.IsActive || GetKeyState("Alt", "P")
            return
        this.IsActive := true
        MouseGetPos(&x, &y)
        this.StartX := x, this.StartY := y
        this.CurrentSector := "Center", this.LastSector := ""
        this.CreateGui()
        SetTimer(this.TimerFn, 10)
    }

    static CreateGui() {
        this.Labels := Map()
        this.GuiObj := Gui("-Caption +AlwaysOnTop +ToolWindow +Owner +E0x20 -DPIScale")
        this.GuiObj.BackColor := Color_Bg
        WinSetTransparent(MenuTransparent, this.GuiObj)
        WinSetRegion("0-0 w" . MenuSize . " h" . MenuSize . " E", this.GuiObj)

        this.Labels["Center"] := this.GuiObj.Add("Text",
            "x" Radius-20 " y" Radius-20 " w40 h40 Center +0x200 c" Color_Text,
            PieConfig["Center"])

        loop 8 {
            dir   := this.DirMap[A_Index]
            angle := (A_Index-1) * 45, rad := angle * 0.01745329
            fX    := Radius + Cos(rad)*Radius*0.75 - 30
            fY    := Radius + Sin(rad)*Radius*0.75 - 20
            this.Labels[dir] := this.GuiObj.Add("Text",
                "x" fX " y" fY " w60 h40 Center +0x200 c" Color_Text, PieConfig[dir])
        }
        this.GuiObj.Show("x" this.StartX-Radius " y" this.StartY-Radius
                       . " w" MenuSize " h" MenuSize " NoActivate")
    }

    static CheckMouse() {
        if !this.IsActive
            return
        MouseGetPos(&mx, &my)
        dx := mx - this.StartX, dy := my - this.StartY
        dist := Sqrt(dx*dx + dy*dy)

        if (dist < CenterZone) {
            this.CurrentSector := "Center"
        } else {
            angle := DllCall("msvcrt\atan2", "Double", dy, "Double", dx, "Cdecl Double")
                   * 180 / 3.1415926
            if (angle < 0)
                angle += 360
            sectorIdx := Round(angle / 45)
            if (sectorIdx == 8)
                sectorIdx := 0
            this.CurrentSector := this.DirMap[sectorIdx + 1]
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
            try %this.CurrentSector%()           ; 调用 Buttons 文件中的同名函数
            catch
                ShowOSD("Function Lost: " . this.CurrentSector)
        }
    }
}

; ==============================================================================
;  [Module] WM (Desktops + Tiling)
; ==============================================================================
SwitchDesktop(target, *) {
    global CurrentDesktop, Desktops, AlwaysVisible
    if (target == CurrentDesktop) {
        ShowOSD("Desktop " . target)
        return
    }
    Desktops[CurrentDesktop] := GetVisibleWindows()
    for hwnd in Desktops[CurrentDesktop]
        if !AlwaysVisible.Has(hwnd)
            try WinMinimize(hwnd)
    for hwnd in Desktops[target]
        try WinRestore(hwnd)
    for hwnd, _ in AlwaysVisible
        try WinRestore(hwnd)

    CurrentDesktop := target
    UpdateStatusBar()
    ShowOSD("Desktop " . CurrentDesktop)
}

MoveWindowToDesktop(target, *) {
    global CurrentDesktop, Desktops, AlwaysVisible
    hwnd := 0
    try hwnd := WinExist("A")
    if (!hwnd || (BarGui && hwnd == BarGui.Hwnd))
        return
    if AlwaysVisible.Has(hwnd)
        AlwaysVisible.Delete(hwnd)

    Loop DesktopCount {
        d := A_Index
        if Desktops.Has(d) {
            nl := []
            for h in Desktops[d]
                if (h != hwnd)
                    nl.Push(h)
            Desktops[d] := nl
        }
    }
    Desktops[target].Push(hwnd)
    if (target != CurrentDesktop) {
        try WinMinimize(hwnd)
        ShowOSD("Window → Desktop " . target)
    }
}

MoveAndSwitch(target, *) {
    MoveWindowToDesktop(target)
    SwitchDesktop(target)
    ShowOSD("Move & Switch → " . target)
}

; ==============================================================================
;  [Module] Status Bar
; ==============================================================================
CreateStatusBar() {
    global

    try if IsObject(BarGui)
        BarGui.Destroy()

    minNeededHeight := Round(BarFontSize * 2 + 5)
    if (BarHeight < minNeededHeight)
        BarHeight := minNeededHeight

    padding       := 15
    progressWidth := Round(A_ScreenWidth * 0.30)
    textBoxWidth  := Round((A_ScreenWidth - progressWidth - padding*4) / 2)
    textControlH  := Round(BarFontSize * 2)
    textY         := (BarHeight - textControlH) / 2
    progY         := (BarHeight - 6) / 2 + 3
    taskH         := 4
    track1Y       := progY - taskH - 2
    track2Y       := track1Y - taskH - 1
    progressX     := (A_ScreenWidth / 2) - (progressWidth / 2)
    rightTextX    := A_ScreenWidth - textBoxWidth - padding

    BarGui := Gui("-Caption +AlwaysOnTop +ToolWindow +Owner +E0x08000000 -DPIScale")
    BarGui.BackColor := Color_Bg
    BarGui.SetFont("s" . BarFontSize . " w600 c" . Color_Active, "Segoe UI")

    BarLeftText := BarGui.Add("Text",
        "x" padding " y" textY " w" textBoxWidth " h" textControlH " BackgroundTrans", "")

    CalcMins(t) => Integer(SubStr(t,1,2))*60 + Integer(SubStr(t,3,2))
    BaseStartMins := 0, BaseEndMins := 1439
    if (WorkTime != "off") {
        isWeekend := (A_WDay == 1 || A_WDay == 7)
        if !(isWeekend && WDayBar == "off") {
            BaseStartMins := CalcMins(WorkStart)
            BaseEndMins   := CalcMins(WorkEnd)
        }
    }
    TotalRange := BaseEndMins - BaseStartMins

    if (TaskTimes != "" && TotalRange > 0) {
        UserWDay := (A_WDay == 1) ? 7 : A_WDay - 1
        DayTasks := []

        Loop Parse, TaskTimes, ";" {
            if (A_LoopField == "")
                continue
            parts := StrSplit(A_LoopField, "_")
            if (parts.Length == 3 && Integer(parts[1]) == UserWDay) {
                rs := CalcMins(parts[2]), re := CalcMins(parts[3])
                s  := Max(rs, BaseStartMins), e := Min(re, BaseEndMins)
                if (e > s)
                    DayTasks.Push({Start:s, End:e, RawStart:rs})
            }
        }

        ; 按 RawStart 排序（冒泡，列表很短可接受）
        n := DayTasks.Length
        Loop n - 1 {
            i := A_Index
            Loop n - i {
                j := A_Index
                if (DayTasks[j].RawStart > DayTasks[j+1].RawStart) {
                    tmp := DayTasks[j]
                    DayTasks[j] := DayTasks[j+1]
                    DayTasks[j+1] := tmp
                }
            }
        }

        lastEndTrack1 := -1
        for task in DayTasks {
            offsetRatio := (task.Start - BaseStartMins) / TotalRange
            widthRatio  := (task.End - task.Start) / TotalRange
            mkX := Round(progressX + progressWidth * offsetRatio)
            mkW := Max(2, Round(progressWidth * widthRatio))
            useY := track1Y
            if (task.Start < lastEndTrack1)
                useY := track2Y
            else
                lastEndTrack1 := task.End
            BarGui.Add("Text",
                Format("x{1} y{2} w{3} h{4} Background{5}", mkX, useY, mkW, taskH, Color_Task), "")
        }
    }

    BarGui.Add("Text",
        "x" progressX " y" progY " w" progressWidth " h6 Background333333", "")
    BarProgress := BarGui.Add("Progress",
        Format("x{1} y{2} w{3} h6 c{4} Background333333 +Smooth",
               progressX, progY, progressWidth, Color_Active), 0)

    BarRightText := BarGui.Add("Text",
        "x" rightTextX " y" textY " w" textBoxWidth " h" textControlH
        . " BackgroundTrans Right", "")

    BarGui.Show("x0 y0 w" . A_ScreenWidth . " h" . BarHeight . " NoActivate")
    WinSetTransparent(BarTransparent, BarGui.Hwnd)
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
    global BarRightText, BarProgress, WorkStart, WorkEnd, WDayBar, WorkTime
    static LastDay := ""

    if !IsObject(BarRightText)
        return

    CurrentDay := FormatTime(, "yyyyMMdd")
    if (LastDay != "" && LastDay != CurrentDay)
        CreateStatusBar()
    LastDay := CurrentDay

    try BarRightText.Value := FormatTime(, "yyyy-MM-dd   HH:mm")

    NowTime := A_Now, TodayDate := FormatTime(NowTime, "yyyyMMdd"), WDay := A_WDay
    ForceFull := false

    if (WorkTime = "off") {
        StartTS := TodayDate . "000000"
        EndTS   := TodayDate . "235959"
    } else {
        StartTS := TodayDate . WorkStart . "00"
        EndTS   := TodayDate . WorkEnd   . "00"
        if ((WDay == 1 || WDay == 7) && WDayBar = "off")
            ForceFull := true
    }

    pct := 0
    if ForceFull {
        pct := 100
    } else {
        TotalSec   := DateDiff(EndTS, StartTS, "Seconds")
        ElapsedSec := DateDiff(NowTime, StartTS, "Seconds")
        pct := (TotalSec <= 0) ? 100
             : (ElapsedSec < 0) ? 0
             : (ElapsedSec > TotalSec) ? 100
             : (ElapsedSec / TotalSec) * 100
    }
    try if IsObject(BarProgress)
        BarProgress.Value := Integer(pct)
}

ToggleBar(*) {
    global BarVisible, BarGui
    BarVisible := !BarVisible
    BarVisible ? BarGui.Show("NoActivate") : BarGui.Hide()
}

TogglePin(*) {
    global AlwaysVisible, BarGui
    hwnd := 0
    try hwnd := WinExist("A")
    if (!hwnd || (BarGui && hwnd == BarGui.Hwnd))
        return
    if AlwaysVisible.Has(hwnd) {
        AlwaysVisible.Delete(hwnd), ShowOSD("Unpinned")
    } else {
        AlwaysVisible[hwnd] := true,  ShowOSD("Pinned (Always Visible)")
    }
}

GatherAllToCurrent(*) {
    global Desktops, CurrentDesktop, AlwaysVisible, BarGui
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
            winClass := WinGetClass(hwnd)              ; 修复：避免 class 关键字
            if (winClass == "Progman" || winClass == "Shell_TrayWnd")
                continue
            WinRestore(hwnd)
            Desktops[CurrentDesktop].Push(hwnd)
            count++
        }
    }
    ShowOSD("Gathered " . count . " Windows")
}

; ==============================================================================
;  [Module] Smart Tiling
; ==============================================================================
TileCurrentDesktop(*) {
    global BarHeight, BarVisible
    windows := GetVisibleWindow()
    count := windows.Length
    if (count == 0) {
        ShowOSD("No Windows To Tile")
        return
    }
    ShowOSD("Tile: " . count)

    targetMon := GetMonitorIndex(WinExist("A"))
    MonitorGetWorkArea(targetMon, &WL, &WT, &WR, &WB)
    if (BarVisible)
        WT += BarHeight + 5
    W := WR - WL, H := WB - WT

    PlaceWin(hwnd, x, y, w, h) {
        try (WinRestore(hwnd), WinMove(x, y, w, h, hwnd))
    }

    switch count {
        case 1:
            PlaceWin(windows[1], WL, WT, W, H)
        case 2:
            PlaceWin(windows[1], WL,        WT, W/2, H)
            PlaceWin(windows[2], WL + W/2,  WT, W/2, H)
        case 3:
            PlaceWin(windows[1], WL,        WT,        W/2, H)
            PlaceWin(windows[2], WL + W/2,  WT,        W/2, H/2)
            PlaceWin(windows[3], WL + W/2,  WT + H/2,  W/2, H/2)
        case 5:
            colW := W/3, halfH := H/2
            PlaceWin(windows[1], WL + colW,    WT,         colW, H)
            PlaceWin(windows[2], WL,           WT,         colW, halfH)
            PlaceWin(windows[3], WL,           WT + halfH, colW, halfH)
            PlaceWin(windows[4], WL + 2*colW,  WT,         colW, halfH)
            PlaceWin(windows[5], WL + 2*colW,  WT + halfH, colW, halfH)
        default:
            if (Mod(count, 2) != 0) {
                itemW := W / count
                for i, hwnd in windows
                    PlaceWin(hwnd, WL + (i-1)*itemW, WT, itemW, H)
            } else {
                cols := count / 2, itemW := W / cols, itemH := H / 2
                for i, hwnd in windows {
                    idx := i - 1, r := Floor(idx/cols), c := Mod(idx, cols)
                    PlaceWin(hwnd, WL + c*itemW, WT + r*itemH, itemW, itemH)
                }
            }
    }
}

GetVisibleWindow() {
    windows := []
    for this_id in WinGetList(,, "Program Manager") {
        try {
            style := WinGetStyle(this_id)
            if !(style & 0x10000000)
                continue
            if (WinGetExStyle(this_id) & 0x00000080)
                continue
            isCloaked := 0
            DllCall("dwmapi\DwmGetWindowAttribute",
                    "Ptr", this_id, "Int", 14, "Int*", &isCloaked, "Int", 4)
            if isCloaked
                continue
            if (WinGetTitle(this_id) == "")
                continue
            WinGetPos(,, &w, &h, this_id)
            if (w < 100 || h < 100)
                continue
            windows.Push(this_id)
        }
    }
    return windows
}

GetMonitorIndex(hwnd := 0) {
    if !hwnd || !WinExist(hwnd) {
        MouseGetPos(&mx, &my)
        return GetMonitorIndexAtPoint(mx, my)
    }
    WinGetPos(&wx, &wy, &ww, &wh, hwnd)
    return GetMonitorIndexAtPoint(wx + ww/2, wy + wh/2)
}

; ==============================================================================
;  [Module] NEW: Window Snap (Alt + Arrows)
; ==============================================================================
SnapWindow(direction, *) {
    hwnd := WinExist("A")
    if !hwnd
        return
    targetMon := GetMonitorIndex(hwnd)
    MonitorGetWorkArea(targetMon, &L, &T, &R, &B)
    if BarVisible
        T += BarHeight + 5
    W := R - L, H := B - T

    try WinRestore(hwnd)
    switch direction {
        case "Left":  WinMove(L,        T, W/2, H, hwnd), ShowOSD("Snap ◀")
        case "Right": WinMove(L + W/2,  T, W/2, H, hwnd), ShowOSD("Snap ▶")
        case "Up":    WinMaximize(hwnd),                  ShowOSD("Maximize ▲")
        case "Down":  WinMinimize(hwnd),                  ShowOSD("Minimize ▼")
    }
}

; ==============================================================================
;  [Module] NEW: Layout Snapshot
; ==============================================================================
SaveLayout(*) {
    global LayoutSnapshot
    LayoutSnapshot := Map()
    for hwnd in GetVisibleWindow() {
        try {
            WinGetPos(&x, &y, &w, &h, hwnd)
            LayoutSnapshot[hwnd] := {x:x, y:y, w:w, h:h}
        }
    }
    ShowOSD("Layout Saved (" . LayoutSnapshot.Count . ")")
}

RestoreLayout(*) {
    global LayoutSnapshot
    if (LayoutSnapshot.Count = 0) {
        ShowOSD("No Saved Layout")
        return
    }
    n := 0
    for hwnd, pos in LayoutSnapshot {
        try {
            if WinExist(hwnd) {
                WinRestore(hwnd)
                WinMove(pos.x, pos.y, pos.w, pos.h, hwnd)
                n++
            }
        }
    }
    ShowOSD("Layout Restored (" . n . ")")
}

; ==============================================================================
;  [Module] Clipboard / Vim / Terminal / Power
; ==============================================================================
OnClipboardChanged(dataType) {                ; 替代旧的 ~^c + Sleep 写法
    if (dataType != 1)                        ; 只处理文本
        return
    RecordClipboard()
}

RecordClipboard() {
    global LastClipContent, OutputFile
    txt := ""
    try txt := A_Clipboard
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
        return
    }
    RunCmd := InStr(VimPath, "vim")
            ? Format('"{1}" "+$" "{2}"', VimPath, OutputFile)
            : Format('"{1}" "{2}"',      VimPath, OutputFile)
    try {
        Run(RunCmd, , , &pid)
        CurrentVimPID := pid
        if WinWait("ahk_pid " . pid, , 3) {
            WinSetAlwaysOnTop(1, "ahk_pid " . pid)
            WinMove(VimWinX, VimWinY, , , "ahk_pid " . pid)
            WinActivate("ahk_pid " . pid)
        }
    } catch {
        ShowOSD("Vim Boot Failed")
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
        btn := pGui.Add("Text",
            "x" x " y" y " w120 h60 Center 0x200 +Border cWhite Background" col, txt)
        btn.OnEvent("Click", fn)
    }
    AddBtn(50,  70, "Shutdown", (*) => Shutdown(1), "b48ead")
    AddBtn(190, 70, "Sleep",
           (*) => DllCall("PowrProf\SetSuspendState","Int",0,"Int",0,"Int",0), "5e81ac")
    AddBtn(330, 70, "Reboot",   (*) => Shutdown(2), "bf616a")
    pGui.OnEvent("Escape", (*) => (pGui.Destroy(), pGui := ""))
    pGui.Show("w500 h160")
}

; ==============================================================================
;  [Module] Misc / Helpers
; ==============================================================================
RestoreAndExit(*) {
    global BarGui
    ShowOSD("Script Shutting Down...")
    Sleep(500)
    if IsObject(BarGui)
        BarGui.Destroy()
    for hwnd in WinGetList() {
        try {
            winClass := WinGetClass(hwnd)
            if (winClass != "Progman" && winClass != "Shell_TrayWnd")
                WinRestore(hwnd)
        }
    }
    ExitApp
}

GetVisibleWindows() {
    global BarGui
    windows := []
    for hwnd in WinGetList() {
        try {
            if (BarGui && hwnd == BarGui.Hwnd)
                continue
            winClass := WinGetClass(hwnd)
            if (winClass == "Progman" || winClass == "Shell_TrayWnd")
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
    winClass := WinGetClass(hwnd)
    if (winClass ~= "Progman|WorkerW") {
        try {
            oDesktop := ComObject("Shell.Application").Windows.Item(ComValue(19, 8))
            sel := oDesktop.Document.SelectedItems
            if (sel.Count > 0)
                return sel.Item(0).Path
        }
    } else if (winClass ~= "(Cabinet|Explore)WClass") {
        try {
            for window in ComObject("Shell.Application").Windows
                if (window.HWND == hwnd) {
                    sel := window.Document.SelectedItems
                    if (sel.Count > 0)
                        return sel.Item(0).Path
                }
        }
    }
    return ""
}

Explorer_GetPath() {
    hwnd := WinExist("A")
    if !hwnd
        return ""
    winClass := WinGetClass(hwnd)
    if (winClass ~= "Progman|WorkerW")
        return A_Desktop
    if (winClass ~= "(Cabinet|Explore)WClass") {
        try {
            for window in ComObject("Shell.Application").Windows
                if (window.HWND == hwnd)
                    return window.Document.Folder.Self.Path
        }
    }
    return ""
}

; ==============================================================================
;  [Module] Tray Icon  (修复：嵌套函数问题已移除)
; ==============================================================================
SetupTrayIcon() {
    A_TrayMenu.Delete()
    A_TrayMenu.Add("Gather All Windows", GatherAllToCurrent)
    A_TrayMenu.Add("Toggle Status Bar",  ToggleBar)
    A_TrayMenu.Add("Save Layout",        SaveLayout)         ; 新增
    A_TrayMenu.Add("Restore Layout",     RestoreLayout)      ; 新增
    A_TrayMenu.Add()
    Loop DesktopCount {
        i := A_Index
        A_TrayMenu.Add("Switch to Desktop " . i, SwitchDesktop.Bind(i))
    }
    A_TrayMenu.Add()
    A_TrayMenu.Add("Reload Config",  (*) => (LoadOrInitConfig(),
                                             CreateStatusBar(),
                                             ShowOSD("Config Reloaded")))   ; 新增
    A_TrayMenu.Add("Reload Script",  (*) => Reload())
    A_TrayMenu.Add()
    A_TrayMenu.Add("Restore && Exit", RestoreAndExit)
    A_IconTip := "WM Script - Desktop " . CurrentDesktop
}

; ==============================================================================
;  [Module] Mouse Drag / Resize
; ==============================================================================
!LButton:: {
    MouseGetPos(,, &hwnd)
    if !hwnd
        return
    try WinActivate(hwnd)
    catch {
        return
    }

    if (WinGetMinMax(hwnd) == 1) {
        try {
            WinRestore(hwnd)
            WinGetPos(,, &rw, &rh, hwnd)
            MouseGetPos(&mx, &my)
            WinMove(mx - rw/2, my - rh/2,,, hwnd)
        } catch
            return
    }

    MouseGetPos(&startX, &startY)
    try WinGetPos(&winX, &winY,,, hwnd)
    catch {
    return
}

    while GetKeyState("LButton", "P") {
        MouseGetPos(&curX, &curY)
        try WinMove(winX + (curX - startX), winY + (curY - startY),,, hwnd)
    }
}

!RButton:: {
    MouseGetPos(,, &hwnd)
    if (!hwnd || WinGetMinMax(hwnd) == 1)
        return
    try {
        WinGetPos(&winX, &winY, &winW, &winH, hwnd)
        if (winW <= 0 || winH <= 0)               ; 修复：除零
            return
        MouseGetPos(&startX, &startY)
        isLeft := (startX - winX) / winW < 0.5
        isUp   := (startY - winY) / winH < 0.5
        while GetKeyState("RButton", "P") {
            MouseGetPos(&curX, &curY)
            dX := curX - startX, dY := curY - startY
            nX := isLeft ? (winX+dX) : winX, nW := isLeft ? (winW-dX) : (winW+dX)
            nY := isUp   ? (winY+dY) : winY, nH := isUp   ? (winH-dY) : (winH+dY)
            if (nW > 50 && nH > 50)
                try WinMove(nX, nY, nW, nH, hwnd)
        }
    }
}

; ==============================================================================
;  [Module] External Buttons Include
; ==============================================================================
#Include "*i %A_ScriptDir%\Buttons\Top.ahk"
#Include "*i %A_ScriptDir%\Buttons\TopRight.ahk"
#Include "*i %A_ScriptDir%\Buttons\Right.ahk"
#Include "*i %A_ScriptDir%\Buttons\DownRight.ahk"
#Include "*i %A_ScriptDir%\Buttons\Down.ahk"
#Include "*i %A_ScriptDir%\Buttons\DownLeft.ahk"
#Include "*i %A_ScriptDir%\Buttons\Left.ahk"
#Include "*i %A_ScriptDir%\Buttons\TopLeft.ahk"
