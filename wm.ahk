#Requires AutoHotkey v2.0
#SingleInstance Force
#WinActivateForce

SetWorkingDir(A_ScriptDir)
CoordMode("Mouse", "Screen")
SetTitleMatchMode(2)
SetWinDelay(0)
SetControlDelay(0)

; ---- Globals ----
global Color_Bg, Color_Text, Color_Active, Color_Task
global Border_Drag_Color, Border_Pin_Color
global PM_Bg, PM_BtnShutdown, PM_BtnSleep, PM_BtnReboot
global Bar_Height, Bar_Transparent, Bar_FontSize
global Bar_MonitorIdx := 1
global Bar_Visible    := true
global Bar_Gui := "", Bar_LeftText := "", Bar_RightText := "", Bar_Progress := ""
global Pie_Size, Pie_Radius, Pie_CenterZone
global Pie_FontSize, Pie_FontSizeActive, Pie_Transparent
global Pie_Config
global Path_Button, Path_Output, Path_OutputFile, Path_Vim, Path_Terminal
global Vim_X, Vim_Y, Vim_Width, Vim_Height
global Vim_CurrentPID := 0
global OSD_Height, OSD_Transparent, OSD_FontSize
global Work_Start, Work_End, Work_WeekendBar, Work_Mode, Work_TaskTimes
global ActiveTheme
global Border_Drag_Enable, Border_Drag_Thickness
global Border_Drag_Offset, Border_Drag_OffsetTop, Border_Drag_Transparent
global Border_Pin_Thickness, Border_Pin_Offset, Border_Pin_OffsetTop, Border_Pin_Transparent
global WTM_BorderFocusColor, WTM_BorderUnfocusColor
global WTM_BorderThickness, WTM_BorderOffset, WTM_BorderOpacity, WTM_SizeStep

global ConfigDir  := EnvGet("USERPROFILE") . "\.config\AHK_WM"
global ConfigFile := ConfigDir . "\wm_config.ini"
global CurrentDesktop  := 1
global DesktopCount    := 9
global Desktops        := Map()
global AlwaysVisible   := Map()
global LastClipContent := ""
global LayoutSnapshot  := Map()
global HK := Map()

Pie_Config := Map(
    "Top","↑", "TopRight","↗", "Right","→", "DownRight","↘",
    "Down","↓", "DownLeft","↙", "Left","←", "TopLeft","↖", "Center","●"
)

; ---- Built-in themes ----
global Themes := Map(
    "nord",             Map("Color_Bg","2E3440","Color_Text","D8DEE9","Color_Active","88C0D0","Color_Task","A3BE8C","Border_Drag_Color","88C0D0","Border_Pin_Color","BF616A","PM_Bg","3B4252","PM_BtnShutdown","BF616A","PM_BtnSleep","5E81AC","PM_BtnReboot","D08770"),
    "tokyonight",       Map("Color_Bg","1A1B26","Color_Text","C0CAF5","Color_Active","7AA2F7","Color_Task","9ECE6A","Border_Drag_Color","7AA2F7","Border_Pin_Color","F7768E","PM_Bg","24283B","PM_BtnShutdown","F7768E","PM_BtnSleep","7AA2F7","PM_BtnReboot","E0AF68"),
    "dracula",          Map("Color_Bg","282A36","Color_Text","F8F8F2","Color_Active","BD93F9","Color_Task","50FA7B","Border_Drag_Color","8BE9FD","Border_Pin_Color","FF5555","PM_Bg","44475A","PM_BtnShutdown","FF5555","PM_BtnSleep","6272A4","PM_BtnReboot","FFB86C"),
    "gruvbox",          Map("Color_Bg","282828","Color_Text","EBDBB2","Color_Active","FABD2F","Color_Task","B8BB26","Border_Drag_Color","83A598","Border_Pin_Color","FB4934","PM_Bg","3C3836","PM_BtnShutdown","FB4934","PM_BtnSleep","458588","PM_BtnReboot","FE8019"),
    "monokai",          Map("Color_Bg","272822","Color_Text","F8F8F2","Color_Active","A6E22E","Color_Task","FD971F","Border_Drag_Color","66D9EF","Border_Pin_Color","F92672","PM_Bg","3E3D32","PM_BtnShutdown","F92672","PM_BtnSleep","66D9EF","PM_BtnReboot","FD971F"),
    "solarized-dark",   Map("Color_Bg","002B36","Color_Text","839496","Color_Active","268BD2","Color_Task","859900","Border_Drag_Color","2AA198","Border_Pin_Color","DC322F","PM_Bg","073642","PM_BtnShutdown","DC322F","PM_BtnSleep","268BD2","PM_BtnReboot","CB4B16"),
    "solarized-light",  Map("Color_Bg","FDF6E3","Color_Text","657B83","Color_Active","268BD2","Color_Task","859900","Border_Drag_Color","2AA198","Border_Pin_Color","DC322F","PM_Bg","EEE8D5","PM_BtnShutdown","DC322F","PM_BtnSleep","268BD2","PM_BtnReboot","CB4B16"),
    "catppuccin-mocha", Map("Color_Bg","1E1E2E","Color_Text","CDD6F4","Color_Active","CBA6F7","Color_Task","A6E3A1","Border_Drag_Color","89B4FA","Border_Pin_Color","F38BA8","PM_Bg","313244","PM_BtnShutdown","F38BA8","PM_BtnSleep","89B4FA","PM_BtnReboot","FAB387"),
    "catppuccin-latte", Map("Color_Bg","EFF1F5","Color_Text","4C4F69","Color_Active","8839EF","Color_Task","40A02B","Border_Drag_Color","1E66F5","Border_Pin_Color","D20F39","PM_Bg","E6E9EF","PM_BtnShutdown","D20F39","PM_BtnSleep","1E66F5","PM_BtnReboot","FE640B"),
    "onedark",          Map("Color_Bg","282C34","Color_Text","ABB2BF","Color_Active","61AFEF","Color_Task","98C379","Border_Drag_Color","56B6C2","Border_Pin_Color","E06C75","PM_Bg","3E4452","PM_BtnShutdown","E06C75","PM_BtnSleep","61AFEF","PM_BtnReboot","D19A66"),
    "ayu-dark",         Map("Color_Bg","0A0E14","Color_Text","B3B1AD","Color_Active","FFB454","Color_Task","C2D94C","Border_Drag_Color","59C2FF","Border_Pin_Color","F07178","PM_Bg","131721","PM_BtnShutdown","F07178","PM_BtnSleep","59C2FF","PM_BtnReboot","FF8F40"),
    "github-dark",      Map("Color_Bg","0D1117","Color_Text","C9D1D9","Color_Active","58A6FF","Color_Task","3FB950","Border_Drag_Color","58A6FF","Border_Pin_Color","F85149","PM_Bg","161B22","PM_BtnShutdown","F85149","PM_BtnSleep","58A6FF","PM_BtnReboot","D29922"),
    "rose-pine",        Map("Color_Bg","191724","Color_Text","E0DEF4","Color_Active","C4A7E7","Color_Task","9CCFD8","Border_Drag_Color","31748F","Border_Pin_Color","EB6F92","PM_Bg","1F1D2E","PM_BtnShutdown","EB6F92","PM_BtnSleep","31748F","PM_BtnReboot","F6C177"),
    "everforest",       Map("Color_Bg","2D353B","Color_Text","D3C6AA","Color_Active","A7C080","Color_Task","DBBC7F","Border_Drag_Color","7FBBB3","Border_Pin_Color","E67E80","PM_Bg","374145","PM_BtnShutdown","E67E80","PM_BtnSleep","7FBBB3","PM_BtnReboot","E69875"),
    "kanagawa",         Map("Color_Bg","1F1F28","Color_Text","DCD7BA","Color_Active","7E9CD8","Color_Task","98BB6C","Border_Drag_Color","7FB4CA","Border_Pin_Color","E46876","PM_Bg","2A2A37","PM_BtnShutdown","E46876","PM_BtnSleep","7E9CD8","PM_BtnReboot","FFA066"),
    "material-deep",    Map("Color_Bg","263238","Color_Text","EEFFFF","Color_Active","82AAFF","Color_Task","C3E88D","Border_Drag_Color","89DDFF","Border_Pin_Color","F07178","PM_Bg","37474F","PM_BtnShutdown","F07178","PM_BtnSleep","82AAFF","PM_BtnReboot","F78C6C")
)

; ---- Scaling helpers: 0-100 -> real units ----
Pct2Alpha(p) => Round(Max(0, Min(100, p+0)) * 255 / 100)

GetPrimaryDim(&pw, &ph) {
    MonitorGetWorkArea(MonitorGetPrimary(), &l, &t, &r, &b)
    pw := r - l, ph := b - t
}
Pct2PxH(p)   { 
	GetPrimaryDim(&pw, &ph)
	return Round(p * ph / 100)
}
Pct2PxW(p)   {
	GetPrimaryDim(&pw, &ph)
	return Round(p * pw / 100)
}
Pct2PxMin(p) {
	GetPrimaryDim(&pw, &ph)
	return Round(p * Min(pw, ph) / 100)
}
Pct2Border(p) => Round(Max(0, Min(100, p+0)) * 20 / 100)

; ---- Hotkey notation conversion ----
;  Natural form in config/help : "Alt+Shift+D" / "Ctrl+``" / "Alt+WheelUp"
;  AHK form used internally    : "!+d" / "^``" / "!WheelUp"
NormalizeHotkey(s) {
    s := Trim(s)
    if (s = "")
        return ""
    ; Already AHK form? leave as-is
    if RegExMatch(s, "^[\!\^\+\#<>\*~\$]")
        return s
    mods := "", key := ""
    parts := StrSplit(s, ["+", "-"])
    for p in parts {
        p := Trim(p)
        if (p = "")
            continue
        switch StrLower(p) {
            case "alt":             mods .= "!"
            case "shift":           mods .= "+"
            case "ctrl", "control": mods .= "^"
            case "win", "lwin", "rwin": mods .= "#"
            default:
                key := p
        }
    }
    if (StrLen(key) = 1)
        key := StrLower(key)
    return mods . key
}

PrettifyHotkey(s) {
    s := Trim(s)
    if (s = "")
        return ""
    mods := [], rest := s
    while (StrLen(rest) > 0 && InStr("!+^#", SubStr(rest, 1, 1))) {
        switch SubStr(rest, 1, 1) {
            case "!": mods.Push("Alt")
            case "+": mods.Push("Shift")
            case "^": mods.Push("Ctrl")
            case "#": mods.Push("Win")
        }
        rest := SubStr(rest, 2)
    }
    if (StrLen(rest) = 1)
        rest := StrUpper(rest)
    out := ""
    for m in mods
        out .= m . " + "
    return out . rest
}

; ---- Initialization ----
global WelcomeFlag := ConfigDir . "\welcome_shown.flag"

LoadOrInitConfig()

Loop DesktopCount
    Desktops[A_Index] := []

if !DirExist(Path_Output)
    DirCreate(Path_Output)
if !DirExist(Path_Button)
    DirCreate(Path_Button)

if InitializeButtons()
    Reload()

if !FileExist(WelcomeFlag) {
    try FileAppend("shown", WelcomeFlag, "UTF-8")
    WelcomeScreen.Show()
}

CreateStatusBar()
UpdateStatusBar()
UpdateClockAndProgress()
SetTimer(UpdateClockAndProgress, 1000)
SetupTrayIcon()
OnClipboardChange(OnClipboardChanged)
RegisterAllHotkeys()

; ---- Hotkey registration (all from config) ----
RegisterAllHotkeys() {
    global HK

    Hotkey(HK["Help"], ShowHelpGui)

    ; 9 virtual desktops: Alt+N switch / Alt+Shift+N move / Ctrl+Alt+N move&switch
    pSwitch := HK["DesktopSwitchPrefix"]
    pMove   := HK["DesktopMovePrefix"]
    pBoth   := HK["DesktopMoveSwitchPrefix"]
    Loop 9 {
        i := A_Index
        try Hotkey(pSwitch . i, SwitchDesktop.Bind(i))
        try Hotkey(pMove   . i, MoveWindowToDesktop.Bind(i))
        try Hotkey(pBoth   . i, MoveAndSwitch.Bind(i))
    }

    Hotkey(HK["TileSmart"], TileCurrentMonitor)
    Hotkey(HK["GatherAll"], GatherAllToCurrent)
    Hotkey(HK["TogglePin"], TogglePin)
    Hotkey(HK["ToggleBar"], ToggleBar)
    Hotkey(HK["Exit"],      RestoreAndExit)

    Hotkey(HK["CloseWindow"],    CloseWindowUnderMouse)
    Hotkey(HK["CloseWindowAlt"], CloseWindowUnderMouse)
    Hotkey(HK["ToggleMaximize"], ToggleMaximizeUnderMouse)
    ; Alt+T is context-sensitive: WTM-mode -> pin-exclude; otherwise -> ToggleOnTop
    Hotkey(HK["ToggleTop"],      ToggleTopDispatch)
    Hotkey(HK["HideWindow"],     HideUnderMouse)

    Hotkey(HK["TransparencyUp"],   AdjustTransparency.Bind(20))
    Hotkey(HK["TransparencyDown"], AdjustTransparency.Bind(-20))

    Hotkey("~LButton & RButton", (*) => Send("^c"))
    Hotkey("~RButton & LButton", (*) => Send("^c"))

    Hotkey(HK["LaunchTerminal"], LaunchTerminal)
    Hotkey(HK["EditFile"],       OpenWithVim)
    Hotkey(HK["PowerMenu"],      ShowPowerMenu)

    Hotkey(HK["SnapLeft"],  SnapWindow.Bind("Left"))
    Hotkey(HK["SnapRight"], SnapWindow.Bind("Right"))
    Hotkey(HK["SnapUp"],    SnapWindow.Bind("Up"))
    Hotkey(HK["SnapDown"],  SnapWindow.Bind("Down"))

    Hotkey(HK["SaveLayout"],    SaveLayout)
    Hotkey(HK["RestoreLayout"], RestoreLayout)

    Hotkey(HK["Reload"], (*) => Reload())
    Hotkey(HK["ClipboardHistory"], (*) => ToggleVimWindow())

    Hotkey(HK["PieMenuTrigger"], (*) => PieMenu.Start())
    Hotkey("Space Up",   PieMenuExecute)
    Hotkey("RButton Up", PieMenuExecute)

    Hotkey(HK["DragMove"],   DragMoveHandler)
    Hotkey(HK["DragResize"], DragResizeHandler)

    ; ---- WTM-mode hotkeys ----
    Hotkey(HK["WTMToggle"],     (*) => WTM.Toggle())
    Hotkey(HK["WTMFocusLeft"],  (*) => WTM.FocusDir("L"))
    Hotkey(HK["WTMFocusDown"],  (*) => WTM.FocusDir("D"))
    Hotkey(HK["WTMFocusUp"],    (*) => WTM.FocusDir("U"))
    Hotkey(HK["WTMFocusRight"], (*) => WTM.FocusDir("R"))
    Hotkey(HK["WTMMoveLeft"],   (*) => WTM.MoveDir("L"))
    Hotkey(HK["WTMMoveDown"],   (*) => WTM.MoveDir("D"))
    Hotkey(HK["WTMMoveUp"],     (*) => WTM.MoveDir("U"))
    Hotkey(HK["WTMMoveRight"],  (*) => WTM.MoveDir("R"))
}

PieMenuExecute(*) {
    if PieMenu.IsActive
        PieMenu.Execute()
}

ToggleTopDispatch(*) {
    if WTM.Active
        WTM.TogglePinExclude()
    else
        ToggleTopUnderMouse()
}

; ---- Config (load or initialize default) ----
LoadOrInitConfig() {
    global

    if !DirExist(ConfigDir) {
        try DirCreate(ConfigDir)
        catch as e {
            MsgBox("Failed to create config directory:`n" . ConfigDir . "`n`n" . e.Message)
            ExitApp
        }
    }

    if !FileExist(ConfigFile) {
        DefaultIni := "
        (
        ;==========================================================================
        ; AHK WM Configuration
        ;==========================================================================

        [General]
        ; custom / nord / tokyonight / dracula / gruvbox / monokai
        ; / solarized-dark / solarized-light / catppuccin-mocha / catppuccin-latte
        ; / onedark / ayu-dark / github-dark / rose-pine / everforest / kanagawa / material-deep
        ActiveTheme=custom

        [Colors]
        Background=0e050f
        Text=e5e9f0
        Active=744da9
        Task=CF8DC9
        BorderDrag=A020F0
        BorderPin=FF5555
        PowerMenuBg=2E3440
        PowerBtnShutdown=B48EAD
        PowerBtnSleep=5E81AC
        PowerBtnReboot=BF616A

        [StatusBar]
        HeightPct=3
        Opacity=78
        FontSize=10
        MonitorIdx=1

        [PieMenu]
        SizePct=28
        CenterZonePct=27
        Opacity=78
        FontSize=14
        FontSizeActive=22

        [OSD]
        PositionPct=80
        Opacity=78
        FontSize=20

        [BorderDrag]
        Enable=on
        Thickness=15
        Offset=0
        OffsetTop=5
        Opacity=70

        [BorderPin]
        Thickness=10
        Offset=0
        OffsetTop=5
        Opacity=78

        [Paths]
        ButtonDir=Buttons
        OutputDir=C:\Users\Administrator\Documents
        VimPath=C:\Windows\system32\notepad.exe
        TerminalExe=C:\Windows\system32\cmd.exe

        [VimLayout]
        XPct=20
        YPct=0
        WidthPct=52
        HeightPct=74

        [WorkTime]
        Mode=off
        WeekendBar=off
        WorkStart=0900
        WorkEnd=1745
        TaskTimes=1_1200_1300;2_1200_1300;3_1200_1300;4_1200_1300;5_1200_1300;6_1200_1300;7_1200_1300;2_1700_1745;3_0900_0920;

        [WTM]
        ; Window Tile Manager mode (hyprland-like). Border / auto-tile params.
        BorderFocusColor=A020F0
        BorderUnfocusColor=555555
        BorderThickness=8
        BorderOffset=0
        BorderOpacity=80
        SizeStep=3

        ;--------------------------------------------------------------------------
        ; Hotkeys - natural language:  Alt / Shift / Ctrl / Win  joined by '+'
        ; Examples:  Alt+Shift+D  /  Ctrl+``  /  Alt+WheelUp
        ; For 1-9 desktop hotkeys, only the modifier prefix is configured here;
        ; the trailing digit (1-9) is appended automatically by the script.
        ;--------------------------------------------------------------------------
        [Hotkeys]
        Help=Alt+/
        Exit=Alt+F12
        Reload=Alt+R

        ; Desktop prefixes:  <prefix> + digit (1-9)
        DesktopSwitchPrefix=Alt
        DesktopMovePrefix=Alt+Shift
        DesktopMoveSwitchPrefix=Ctrl+Alt

        ; Window management
        TileSmart=Alt+D
        GatherAll=Alt+Shift+G
        TogglePin=Ctrl+Alt+T
        ToggleBar=Ctrl+Alt+B
        SaveLayout=Alt+Shift+S
        RestoreLayout=Alt+Shift+R

        ; Under-cursor actions
        CloseWindow=Alt+Q
        CloseWindowAlt=Alt+MButton
        ToggleMaximize=Alt+F
        ToggleTop=Alt+T
        HideWindow=Alt+W
        TransparencyUp=Alt+WheelUp
        TransparencyDown=Alt+WheelDown

        ; Window snapping
        SnapLeft=Alt+Left
        SnapRight=Alt+Right
        SnapUp=Alt+Up
        SnapDown=Alt+Down

        ; Launchers
        LaunchTerminal=Alt+Enter
        EditFile=Alt+V
        PowerMenu=Alt+X
        ClipboardHistory=Ctrl+``

        ; Mouse drag
        DragMove=Alt+LButton
        DragResize=Alt+RButton

        ; Pie menu (raw AHK combo retained)
        PieMenuTrigger=~Space & RButton

        ; WTM mode
        WTMToggle=Alt+Shift+D
        WTMFocusLeft=Alt+H
        WTMFocusDown=Alt+J
        WTMFocusUp=Alt+K
        WTMFocusRight=Alt+L
        WTMMoveLeft=Alt+Shift+H
        WTMMoveDown=Alt+Shift+J
        WTMMoveUp=Alt+Shift+K
        WTMMoveRight=Alt+Shift+L
        )"

        try {
            FileAppend(DefaultIni, ConfigFile, "UTF-8")
        } catch as e {
            MsgBox("Failed to create config file: " . e.Message)
            ExitApp
        }
    }

    ActiveTheme := IniRead(ConfigFile, "General", "ActiveTheme", "custom")

    Color_Bg          := IniRead(ConfigFile, "Colors", "Background",       "0e050f")
    Color_Text        := IniRead(ConfigFile, "Colors", "Text",             "744da9")
    Color_Active      := IniRead(ConfigFile, "Colors", "Active",           "744da9")
    Color_Task        := IniRead(ConfigFile, "Colors", "Task",             "CF8DC9")
    Border_Drag_Color := IniRead(ConfigFile, "Colors", "BorderDrag",       "A020F0")
    Border_Pin_Color  := IniRead(ConfigFile, "Colors", "BorderPin",        "FF5555")
    PM_Bg             := IniRead(ConfigFile, "Colors", "PowerMenuBg",      "2E3440")
    PM_BtnShutdown    := IniRead(ConfigFile, "Colors", "PowerBtnShutdown", "B48EAD")
    PM_BtnSleep       := IniRead(ConfigFile, "Colors", "PowerBtnSleep",    "5E81AC")
    PM_BtnReboot      := IniRead(ConfigFile, "Colors", "PowerBtnReboot",   "BF616A")

    Bar_Height       := Pct2PxH(Integer(IniRead(ConfigFile, "StatusBar", "HeightPct",  "3")))
    Bar_Transparent  := Pct2Alpha(Integer(IniRead(ConfigFile, "StatusBar", "Opacity",  "78")))
    Bar_FontSize     := Integer(IniRead(ConfigFile, "StatusBar", "FontSize",   "10"))
    Bar_MonitorIdx   := Integer(IniRead(ConfigFile, "StatusBar", "MonitorIdx", "1"))

    Pie_Size           := Pct2PxMin(Integer(IniRead(ConfigFile, "PieMenu", "SizePct",       "28")))
    Pie_Radius         := Pie_Size / 2
    Pie_CenterZone     := Round(Pie_Radius * Integer(IniRead(ConfigFile, "PieMenu", "CenterZonePct", "27")) / 100)
    Pie_Transparent    := Pct2Alpha(Integer(IniRead(ConfigFile, "PieMenu", "Opacity",       "78")))
    Pie_FontSize       := Integer(IniRead(ConfigFile, "PieMenu", "FontSize",       "14"))
    Pie_FontSizeActive := Integer(IniRead(ConfigFile, "PieMenu", "FontSizeActive", "22"))

    OSD_Height       := Pct2PxH(Integer(IniRead(ConfigFile, "OSD", "PositionPct", "80")))
    OSD_Transparent  := Pct2Alpha(Integer(IniRead(ConfigFile, "OSD", "Opacity",   "78")))
    OSD_FontSize     := Integer(IniRead(ConfigFile, "OSD", "FontSize", "20"))

    Border_Drag_Enable      := IniRead(ConfigFile, "BorderDrag", "Enable",    "on")
    Border_Drag_Thickness   := Pct2Border(Integer(IniRead(ConfigFile, "BorderDrag", "Thickness", "15")))
    Border_Drag_Offset      := Pct2Border(Integer(IniRead(ConfigFile, "BorderDrag", "Offset",    "0")))
    Border_Drag_OffsetTop   := Pct2Border(Integer(IniRead(ConfigFile, "BorderDrag", "OffsetTop", "5")))
    Border_Drag_Transparent := Pct2Alpha(Integer(IniRead(ConfigFile, "BorderDrag", "Opacity",   "70")))

    Border_Pin_Thickness   := Pct2Border(Integer(IniRead(ConfigFile, "BorderPin", "Thickness", "10")))
    Border_Pin_Offset      := Pct2Border(Integer(IniRead(ConfigFile, "BorderPin", "Offset",    "0")))
    Border_Pin_OffsetTop   := Pct2Border(Integer(IniRead(ConfigFile, "BorderPin", "OffsetTop", "5")))
    Border_Pin_Transparent := Pct2Alpha(Integer(IniRead(ConfigFile, "BorderPin", "Opacity",   "78")))

    WTM_BorderFocusColor   := IniRead(ConfigFile, "WTM", "BorderFocusColor",   "A020F0")
    WTM_BorderUnfocusColor := IniRead(ConfigFile, "WTM", "BorderUnfocusColor", "555555")
    WTM_BorderThickness    := Pct2Border(Integer(IniRead(ConfigFile, "WTM", "BorderThickness", "8")))
    WTM_BorderOffset       := Pct2Border(Integer(IniRead(ConfigFile, "WTM", "BorderOffset",    "0")))
    WTM_BorderOpacity      := Pct2Alpha(Integer(IniRead(ConfigFile, "WTM", "BorderOpacity",   "80")))
    WTM_SizeStep           := Integer(IniRead(ConfigFile, "WTM", "SizeStep", "3"))

    bDirTemp        := IniRead(ConfigFile, "Paths", "ButtonDir",  "Buttons")
    Path_Button     := (bDirTemp ~= "^[a-zA-Z]:") ? bDirTemp : (A_ScriptDir . "\" . bDirTemp)
    Path_Output     := IniRead(ConfigFile, "Paths", "OutputDir",   "C:\Users\Administrator\Documents")
    Path_OutputFile := Path_Output . "\CB.txt"
    Path_Vim        := IniRead(ConfigFile, "Paths", "VimPath",     "C:\Windows\system32\notepad.exe")
    Path_Terminal   := IniRead(ConfigFile, "Paths", "TerminalExe", "C:\Windows\system32\cmd.exe")

    Vim_X      := Pct2PxW(Integer(IniRead(ConfigFile, "VimLayout", "XPct",      "20")))
    Vim_Y      := Pct2PxH(Integer(IniRead(ConfigFile, "VimLayout", "YPct",      "0")))
    Vim_Width  := Pct2PxW(Integer(IniRead(ConfigFile, "VimLayout", "WidthPct",  "52")))
    Vim_Height := Pct2PxH(Integer(IniRead(ConfigFile, "VimLayout", "HeightPct", "74")))

    Work_Mode       := IniRead(ConfigFile, "WorkTime", "Mode",       "on")
    Work_WeekendBar := IniRead(ConfigFile, "WorkTime", "WeekendBar", "off")
    Work_Start      := IniRead(ConfigFile, "WorkTime", "WorkStart",  "0900")
    Work_End        := IniRead(ConfigFile, "WorkTime", "WorkEnd",    "1745")
    Work_TaskTimes  := IniRead(ConfigFile, "WorkTime", "TaskTimes",  "")

    HK := Map()
    hkKeys := ["Help","Exit","Reload",
               "DesktopSwitchPrefix","DesktopMovePrefix","DesktopMoveSwitchPrefix",
               "TileSmart","GatherAll","TogglePin","ToggleBar","SaveLayout","RestoreLayout",
               "CloseWindow","CloseWindowAlt","ToggleMaximize","ToggleTop","HideWindow",
               "TransparencyUp","TransparencyDown",
               "SnapLeft","SnapRight","SnapUp","SnapDown",
               "LaunchTerminal","EditFile","PowerMenu","ClipboardHistory",
               "DragMove","DragResize","PieMenuTrigger",
               "WTMToggle","WTMFocusLeft","WTMFocusDown","WTMFocusUp","WTMFocusRight",
               "WTMMoveLeft","WTMMoveDown","WTMMoveUp","WTMMoveRight"]
    hkDefaults := Map(
        "Help","Alt+/","Exit","Alt+F12","Reload","Alt+R",
        "DesktopSwitchPrefix","Alt","DesktopMovePrefix","Alt+Shift","DesktopMoveSwitchPrefix","Ctrl+Alt",
        "TileSmart","Alt+D","GatherAll","Alt+Shift+G","TogglePin","Ctrl+Alt+T","ToggleBar","Ctrl+Alt+B",
        "SaveLayout","Alt+Shift+S","RestoreLayout","Alt+Shift+R",
        "CloseWindow","Alt+Q","CloseWindowAlt","Alt+MButton","ToggleMaximize","Alt+F",
        "ToggleTop","Alt+T","HideWindow","Alt+W",
        "TransparencyUp","Alt+WheelUp","TransparencyDown","Alt+WheelDown",
        "SnapLeft","Alt+Left","SnapRight","Alt+Right","SnapUp","Alt+Up","SnapDown","Alt+Down",
        "LaunchTerminal","Alt+Enter","EditFile","Alt+V","PowerMenu","Alt+X","ClipboardHistory","Ctrl+``",
        "DragMove","Alt+LButton","DragResize","Alt+RButton","PieMenuTrigger","~Space & RButton",
        "WTMToggle","Alt+Shift+D",
        "WTMFocusLeft","Alt+H","WTMFocusDown","Alt+J","WTMFocusUp","Alt+K","WTMFocusRight","Alt+L",
        "WTMMoveLeft","Alt+Shift+H","WTMMoveDown","Alt+Shift+J",
        "WTMMoveUp","Alt+Shift+K","WTMMoveRight","Alt+Shift+L"
    )
    for k in hkKeys {
        raw := IniRead(ConfigFile, "Hotkeys", k, hkDefaults[k])
        ; Desktop prefixes need modifier-only output (no trailing key)
        if InStr(k, "Prefix") {
            HK[k] := NormalizeModifiersOnly(raw)
        } else {
            HK[k] := NormalizeHotkey(raw)
        }
    }

    if (ActiveTheme != "custom" && Themes.Has(ActiveTheme)) {
        palette := Themes[ActiveTheme]
        for key, val in palette
            try %key% := val
    }

    if (Bar_MonitorIdx < 1 || Bar_MonitorIdx > MonitorGetCount())
        Bar_MonitorIdx := 1
}

; Modifier-only normalizer: "Alt+Shift" -> "!+", "Ctrl+Alt" -> "^!"
NormalizeModifiersOnly(s) {
    s := Trim(s)
    if (s = "")
        return ""
    if RegExMatch(s, "^[\!\^\+\#]+$")
        return s
    out := ""
    for p in StrSplit(s, ["+", "-"]) {
        switch StrLower(Trim(p)) {
            case "alt":             out .= "!"
            case "shift":           out .= "+"
            case "ctrl", "control": out .= "^"
            case "win", "lwin", "rwin": out .= "#"
        }
    }
    return out
}

; ---- DWM visible rect (compensates invisible border) ----
GetWindowVisualRect(hwnd, &x, &y, &w, &h) {
    rect := Buffer(16, 0)
    hr := DllCall("dwmapi\DwmGetWindowAttribute"
                , "Ptr", hwnd, "Int", 9, "Ptr", rect, "Int", 16)
    if (hr = 0) {
        L := NumGet(rect, 0,  "Int")
        T := NumGet(rect, 4,  "Int")
        R := NumGet(rect, 8,  "Int")
        B := NumGet(rect, 12, "Int")
        x := L, y := T, w := R - L, h := B - T
        return true
    }
    WinGetPos(&x, &y, &w, &h, hwnd)
    return false
}

GetMonitorIndexAtPoint(x, y) {
    loop MonitorGetCount() {
        MonitorGet(A_Index, &mL, &mT, &mR, &mB)
        if (x >= mL && x < mR && y >= mT && y < mB)
            return A_Index
    }
    return 1
}

GetMonitorIndex(hwnd := 0) {
    if !hwnd || !WinExist(hwnd) {
        MouseGetPos(&mx, &my)
        return GetMonitorIndexAtPoint(mx, my)
    }
    WinGetPos(&wx, &wy, &ww, &wh, hwnd)
    return GetMonitorIndexAtPoint(wx + ww/2, wy + wh/2)
}

; ---- Help GUI ----
ShowHelpGui(*) {
    static helpGui := ""
    global HK

    CloseWatcher() {
        if !IsObject(helpGui) {
            SetTimer CloseWatcher, 0
            return
        }
        if GetKeyState("Escape", "P") || GetKeyState("LButton", "P") {
            try helpGui.Destroy()
            helpGui := ""
            SetTimer CloseWatcher, 0
        }
    }

    if IsObject(helpGui) {
        helpGui.Destroy()
        helpGui := ""
        return
    }

    helpGui := Gui("-Caption +AlwaysOnTop +ToolWindow -DPIScale +Owner")
    helpGui.BackColor := Color_Bg
    helpGui.SetFont("s20 w700 c" . Color_Text, "Segoe UI")
    helpGui.Add("Text", "x0 y20 w620 Center", "HELP")
    helpGui.SetFont("s10 w700 c" . Color_Active, "Segoe UI")
    helpGui.Add("Text", "x0 y60 w620 Center", "Natural-language hotkeys (Alt / Shift / Ctrl / Win + key)")

    helpGui.SetFont("s10 w600 c" . Color_Active)
    helpGui.Add("Text", "x50 y90 w545 h5 0x10")

    PrefP(k) => PrettifyHotkey(HK[k])
    DesktopRange(p) => PrettifyHotkey(p) . " + 1-9"

    shortcuts := [
        [PrefP("Help"),                       "Show / Hide Help Menu"],
        [PrefP("PieMenuTrigger"),             "Pie Menu (Mouse)"],
        [DesktopRange(HK["DesktopSwitchPrefix"]),     "Switch Desktop"],
        [DesktopRange(HK["DesktopMovePrefix"]),       "Move Window to Desktop"],
        [DesktopRange(HK["DesktopMoveSwitchPrefix"]), "Move And Switch"],
        [PrefP("WTMToggle"),                  "Toggle WTM Tiling Mode"],
        [PrefP("WTMFocusLeft") . " / J / K / L",      "WTM Focus (H/J/K/L)"],
        [PrefP("WTMMoveLeft")  . " / J / K / L",      "WTM Move/Swap (Shift+HJKL)"],
        [PrefP("DragMove"),                   "Drag Move Window"],
        [PrefP("DragResize"),                 "Drag Resize Window"],
        [PrefP("TransparencyUp") . " / " . PrefP("TransparencyDown"), "Window Transparency"],
        [PrefP("SnapLeft") . " / " . PrefP("SnapRight"), "Snap Left / Right"],
        [PrefP("SnapUp")   . " / " . PrefP("SnapDown"),  "Maximize / Minimize"],
        [PrefP("SaveLayout") . " / " . PrefP("RestoreLayout"), "Save / Restore Layout"],
        [PrefP("GatherAll"),                  "Gather All Windows"],
        [PrefP("CloseWindow"),                "Close Window"],
        [PrefP("TileSmart"),                  "Smart Tile (current monitor)"],
        [PrefP("HideWindow"),                 "Minimize Window"],
        [PrefP("ToggleMaximize"),             "Maximize / Restore"],
        [PrefP("Reload"),                     "Reload Script"],
        [PrefP("ToggleTop"),                  "Toggle OnTop (or WTM exclude)"],
        [PrefP("TogglePin"),                  "Toggle Always Visible"],
        [PrefP("ClipboardHistory"),           "Clipboard History (Vim)"],
        [PrefP("ToggleBar"),                  "Toggle Top Bar"],
        [PrefP("EditFile"),                   "Edit Selected File"],
        [PrefP("LaunchTerminal"),             "Launch Terminal"],
        [PrefP("Exit"),                       "Safely Exit"],
        [PrefP("PowerMenu"),                  "Power Menu"]
    ]

    helpGui.SetFont("s10 w400 c" . Color_Text)
    for i, item in shortcuts {
        yPos := 110 + (i-1)*23
        helpGui.Add("Text", "x60 y"  . yPos . " w240 c" . Color_Text, item[1])
        helpGui.Add("Text", "x300 y" . yPos . " w300 +Right", item[2])
    }

    helpGui.Show("Center")
    SetTimer CloseWatcher, 50
}

; ---- Welcome screen (first run, centered on primary monitor) ----
class WelcomeScreen {
    static GuiObj := ""

    static Show() {
        if IsObject(this.GuiObj)
            return
        priIdx := MonitorGetPrimary()
        MonitorGet(priIdx, &mL, &mT, &mR, &mB)
        vx := mL, vy := mT, vw := mR - mL, vh := mB - mT

        g := Gui("-Caption +AlwaysOnTop +ToolWindow -DPIScale +E0x08000000")
        g.BackColor := Color_Bg
        g.MarginX := 0, g.MarginY := 0
        cx := vw // 2

        g.SetFont("s64 w800 c" . Color_Active, "Segoe UI")
        g.Add("Text", "x0 y" Round(vh*0.22) " w" vw " Center BackgroundTrans", "WM Script")

        g.SetFont("s18 w400 c" . Color_Text, "Segoe UI")
        g.Add("Text", "x0 y" Round(vh*0.35) " w" vw " Center BackgroundTrans"
            , "An AHK tiling window manager for Windows")

        g.Add("Text", "x" (cx-200) " y" Round(vh*0.40) " w400 h2 Background" Color_Active, "")

        g.SetFont("s13 w800 c" . Color_Text, "Consolas")
        infoLines := [
            "  >  9 Virtual Desktops          " . PrettifyHotkey(HK["DesktopSwitchPrefix"]) . " + 1-9",
            "  >  Smart Tiling                " . PrettifyHotkey(HK["TileSmart"]),
            "  >  WTM Mode (hyprland-like)    " . PrettifyHotkey(HK["WTMToggle"]),
            "  >  Window Snap                 " . PrettifyHotkey(HK["SnapLeft"]) . " etc.",
            "  >  Layout Snapshot             " . PrettifyHotkey(HK["SaveLayout"]) . " / " . PrettifyHotkey(HK["RestoreLayout"]),
            "  >  Help Menu                   " . PrettifyHotkey(HK["Help"])
        ]
        yStart := Round(vh * 0.46)
        for i, line in infoLines
            g.Add("Text", "x" (cx-280) " y" (yStart + (i-1)*32) " w860 BackgroundTrans c" Color_Text, line)

        g.SetFont("s11 w400 c" . Color_Text, "Consolas")
        g.Add("Text", "x0 y" Round(vh*0.78) " w" vw " Center BackgroundTrans"
            , "Config: " . ConfigFile)

        g.SetFont("s14 w600 c" . Color_Active, "Segoe UI")
        g.Add("Text", "x0 y" Round(vh*0.84) " w" vw " Center BackgroundTrans"
            , "Made with <3 by ZXW")

        g.SetFont("s10 w400 c" . Color_Text, "Segoe UI")
        g.Add("Text", "x0 y" Round(vh*0.88) " w" vw " Center BackgroundTrans"
            , "v2.2  ::  AutoHotkey v2")

        g.SetFont("s11 w600 c" . Color_Active, "Segoe UI")
        hint := g.Add("Text", "x0 y" Round(vh*0.93) " w" vw " Center BackgroundTrans"
            , "[ Press any key or click to continue ]")

        g.Show(Format("x{} y{} w{} h{} NoActivate", vx, vy, vw, vh))
        WinSetTransparent(245, g.Hwnd)
        this.GuiObj := g
        this.HintCtrl := hint
        this.HintState := true
        SetTimer(ObjBindMethod(this, "Blink"), 600)
        SetTimer(ObjBindMethod(this, "WaitClose"), 50)
    }

    static Blink() {
        if !IsObject(this.GuiObj) {
            SetTimer(ObjBindMethod(this, "Blink"), 0)
            return
        }
        try {
            this.HintState := !this.HintState
            this.HintCtrl.SetFont(this.HintState ? "c" Color_Active : "c" Color_Text)
        }
    }

    static WaitClose() {
        if !IsObject(this.GuiObj) {
            SetTimer(ObjBindMethod(this, "WaitClose"), 0)
            return
        }
        if (GetKeyState("LButton","P") || GetKeyState("Escape","P")
         || GetKeyState("Enter","P")  || GetKeyState("Space","P"))
            this.Close()
    }

    static Close() {
        SetTimer(ObjBindMethod(this, "WaitClose"), 0)
        SetTimer(ObjBindMethod(this, "Blink"),     0)
        try this.GuiObj.Destroy()
        this.GuiObj := ""
    }
}

; ---- Eight-direction button template init ----
InitializeButtons() {
    dirs := ["Top","TopRight","Right","DownRight","Down","DownLeft","Left","TopLeft"]
    created := false
    for d in dirs {
        fPath := Path_Button . "\" . d . ".ahk"
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

; ---- OSD ----
class OSD {
    static GuiObj := 0, Timer := 0

    static Show(text, duration := 1000) {
        if IsObject(this.GuiObj) {
            try this.GuiObj.Destroy()
            this.GuiObj := 0
        }
        if this.Timer
            SetTimer(this.Timer, 0)

        g := Gui("+AlwaysOnTop -Caption +ToolWindow +Disabled +Owner -DPIScale")
        g.BackColor := Color_Bg
        g.SetFont("s" . OSD_FontSize . " w600 c" . Color_Active, "Segoe UI")
        g.Add("Text", "Center", text)

        MouseGetPos(&mx,)
        monIdx := GetMonitorIndexAtPoint(mx, OSD_Height)
        MonitorGet(monIdx, &mL, , &mR, )
        cx := (mL + mR) // 2

        g.Show("NoActivate AutoSize Hide")
        g.GetPos(, , &gw, )
        g.Show(Format("NoActivate AutoSize x{} y{}", cx - gw//2, OSD_Height))
        WinSetTransparent(OSD_Transparent, g.Hwnd)

        this.GuiObj := g
        this.Timer  := () => (IsObject(OSD.GuiObj) ? (OSD.GuiObj.Destroy(), OSD.GuiObj := 0) : 0)
        SetTimer(this.Timer, -duration)
    }
}
ShowOSD(text) => OSD.Show(text)

; ---- Drag border (overlay during move/resize) ----
class DragBorder {
    static Guis := []

    static Show() {
        if (Border_Drag_Enable != "on")
            return
        this.Destroy()
        Loop 4 {
            g := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 -DPIScale")
            g.BackColor := Border_Drag_Color
            g.Show("NoActivate x-1000 y-1000 w10 h10")
            WinSetTransparent(Border_Drag_Transparent, g.Hwnd)
            this.Guis.Push(g)
        }
    }

    static Update(hwnd) {
        if (this.Guis.Length != 4)
            return
        if !hwnd || !WinExist(hwnd)
            return
        if !GetWindowVisualRect(hwnd, &x, &y, &w, &h)
            return
        t  := Border_Drag_Thickness
        o  := Border_Drag_Offset
        ot := Border_Drag_OffsetTop
        x -= o, y -= (o + ot), w += 2*o, h += 2*o + ot
        try {
            WinMove(x,       y,       w, t, this.Guis[1].Hwnd)
            WinMove(x,       y+h-t,   w, t, this.Guis[2].Hwnd)
            WinMove(x,       y,       t, h, this.Guis[3].Hwnd)
            WinMove(x+w-t,   y,       t, h, this.Guis[4].Hwnd)
        }
    }

    static Destroy() {
        for g in this.Guis
            try g.Destroy()
        this.Guis := []
    }
}

; ---- Pinned-window persistent border ----
class PinBorder {
    static Map     := Map()
    static TimerFn := ObjBindMethod(PinBorder, "Tick")
    static Started := false

    static Add(hwnd) {
        if this.Map.Has(hwnd)
            return
        g := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 -DPIScale")
        g.BackColor := Border_Pin_Color
        g.Show("NoActivate x-1000 y-1000 w200 h10")
        WinSetTransparent(Border_Pin_Transparent, g.Hwnd)
        this.Map[hwnd] := g

        if !this.Started {
            SetTimer(this.TimerFn, 100)
            this.Started := true
        }
    }

    static Remove(hwnd) {
        if !this.Map.Has(hwnd)
            return
        try this.Map[hwnd].Destroy()
        this.Map.Delete(hwnd)
        if (this.Map.Count = 0) {
            SetTimer(this.TimerFn, 0)
            this.Started := false
        }
    }

    static RemoveAll() {
        for hwnd, _ in this.Map.Clone()
            this.Remove(hwnd)
    }

    static Tick() {
        t   := Max(3, Border_Pin_Thickness)
        gap := Border_Pin_OffsetTop
        for hwnd, g in this.Map.Clone() {
            if !WinExist(hwnd) {
                this.Remove(hwnd)
                continue
            }
            try {
                if (WinGetMinMax(hwnd) = -1) {
                    try DllCall("ShowWindow", "Ptr", g.Hwnd, "Int", 0)
                    continue
                }
                if !GetWindowVisualRect(hwnd, &x, &y, &w, &h)
                    continue
            } catch {
                continue
            }
            try {
                ; HWND_TOPMOST=-1, SWP_NOACTIVATE=0x10, SWP_SHOWWINDOW=0x40
                DllCall("SetWindowPos"
                    , "Ptr", g.Hwnd, "Ptr", -1
                    , "Int", x, "Int", y - t - gap
                    , "Int", w, "Int", t
                    , "UInt", 0x10 | 0x40)
            }
        }
    }
}

; ---- Under-cursor window actions ----
CloseWindowUnderMouse(*) {
    MouseGetPos(,, &hwnd)
    try {
        WinClose(hwnd)
        PinBorder.Remove(hwnd)
        ShowOSD("Closing Window...")
    }
    WTM.OnWindowChanged()
}

HideUnderMouse(*) {
    MouseGetPos(,, &hwnd)
    try {
        WinMinimize(hwnd)
        ShowOSD("WinMinimized")
    }
    WTM.OnWindowChanged()
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
        if (state & 0x8) {
            PinBorder.Add(hwnd)
            ShowOSD("WinOnTop")
        } else {
            PinBorder.Remove(hwnd)
            ShowOSD("WinOffTop")
        }
    }
}

AdjustTransparency(amount, *) {
    MouseGetPos(,, &hwnd)
    try {
        cur := WinGetTransparent(hwnd)
        if !IsNumber(cur)
            cur := 255
        newVal := Max(2, Min(255, Integer(cur) + amount))
        WinSetTransparent(newVal, hwnd)
        ShowOSD("Transparency: " . Round(newVal/255*100) . "%")
    }
}

; ---- Pie menu ----
class PieMenu {
    static DirMap   := ["Right","DownRight","Down","DownLeft","Left","TopLeft","Top","TopRight"]
    static IsActive := false, GuiObj := "", Labels := Map()
    static TimerFn  := ObjBindMethod(PieMenu, "CheckMouse")
    static StartX   := 0, StartY := 0, CurrentSector := "", LastSector := ""

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
        WinSetTransparent(Pie_Transparent, this.GuiObj)
        WinSetRegion("0-0 w" . Pie_Size . " h" . Pie_Size . " E", this.GuiObj)

        this.Labels["Center"] := this.GuiObj.Add("Text"
            , "x" Pie_Radius-20 " y" Pie_Radius-20 " w40 h40 Center +0x200 c" Color_Text
            , Pie_Config["Center"])

        loop 8 {
            dir   := this.DirMap[A_Index]
            angle := (A_Index-1) * 45, rad := angle * 0.01745329
            fX    := Pie_Radius + Cos(rad)*Pie_Radius*0.75 - 30
            fY    := Pie_Radius + Sin(rad)*Pie_Radius*0.75 - 20
            this.Labels[dir] := this.GuiObj.Add("Text"
                , "x" fX " y" fY " w60 h40 Center +0x200 c" Color_Text
                , Pie_Config[dir])
        }
        this.GuiObj.Show("x" this.StartX-Pie_Radius " y" this.StartY-Pie_Radius
                       . " w" Pie_Size " h" Pie_Size " NoActivate")
    }

    static CheckMouse() {
        if !this.IsActive
            return
        MouseGetPos(&mx, &my)
        dx := mx - this.StartX, dy := my - this.StartY
        dist := Sqrt(dx*dx + dy*dy)

        if (dist < Pie_CenterZone) {
            this.CurrentSector := "Center"
        } else {
            angle := DllCall("msvcrt\atan2", "Double", dy, "Double", dx, "Cdecl Double") * 180 / 3.1415926
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
                ctrl.SetFont("s" . Pie_FontSize . " c" . Color_Text . " w600")
                ctrl.Opt("c" . Color_Text)
            }
        }
        if this.Labels.Has(this.CurrentSector) {
            try {
                curr := this.Labels[this.CurrentSector]
                curr.SetFont("s" . Pie_FontSizeActive . " c" . Color_Active . " w700")
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
            try %this.CurrentSector%()
            catch
                ShowOSD("Function Lost: " . this.CurrentSector)
        }
    }
}

; ---- Virtual desktops ----
SwitchDesktop(target, *) {
    global CurrentDesktop, Desktops, AlwaysVisible
    if (target == CurrentDesktop) {
        ShowOSD("Desktop " . target)
        return
    }
    Desktops[CurrentDesktop] := GetVisibleWindows()
    for hwnd in Desktops[CurrentDesktop] {
        if !AlwaysVisible.Has(hwnd)
            try WinMinimize(hwnd)
    }
    for hwnd in Desktops[target]
        try WinRestore(hwnd)
    for hwnd, _ in AlwaysVisible
        try WinRestore(hwnd)

    CurrentDesktop := target
    UpdateStatusBar()
    A_IconTip := "WM Script - Desktop " . CurrentDesktop
    ShowOSD("Desktop " . CurrentDesktop)
    WTM.OnDesktopSwitched()
}

MoveWindowToDesktop(target, *) {
    global CurrentDesktop, Desktops, AlwaysVisible, Bar_Gui

    hwnd := 0
    try hwnd := WinExist("A")
    if (!hwnd || (Bar_Gui && hwnd == Bar_Gui.Hwnd))
        return

    if AlwaysVisible.Has(hwnd) {
        AlwaysVisible.Delete(hwnd)
        PinBorder.Remove(hwnd)
    }

    Loop DesktopCount {
        d := A_Index
        if Desktops.Has(d) {
            nl := []
            for h in Desktops[d] {
                if (h != hwnd)
                    nl.Push(h)
            }
            Desktops[d] := nl
        }
    }

    Desktops[target].Push(hwnd)

    if (target != CurrentDesktop) {
        try WinMinimize(hwnd)
        ShowOSD("Window -> Desktop " . target)
    }
    WTM.OnWindowChanged()
}

MoveAndSwitch(target, *) {
    MoveWindowToDesktop(target)
    SwitchDesktop(target)
    ShowOSD("Move And Switch -> " . target)
}

; ---- Status bar ----
CreateStatusBar() {
    global

    try {
        if IsSet(Bar_Gui) && IsObject(Bar_Gui)
            Bar_Gui.Destroy()
    }

    MonitorGet(Bar_MonitorIdx, &mL, &mT, &mR, &mB)
    barScreenWidth := mR - mL
    barX := mL, barY := mT

    local minNeededHeight := Round(Bar_FontSize * 2 + 5)
    if (Bar_Height < minNeededHeight)
        Bar_Height := minNeededHeight
    local padding       := 15
    local progressWidth := Round(barScreenWidth * 0.30)
    local textBoxWidth  := Round((barScreenWidth - progressWidth - padding*4) / 2)
    local textControlH  := Round(Bar_FontSize * 2)
    local textY         := (Bar_Height - textControlH) / 2
    local progY         := (Bar_Height - 6) / 2 + 3
    local taskH         := 4
    local track1Y       := progY - taskH - 2
    local track2Y       := track1Y - taskH - 1
    local progressX     := (barScreenWidth / 2) - (progressWidth / 2)
    local rightTextX    := barScreenWidth - textBoxWidth - padding

    Bar_Gui := Gui("-Caption +AlwaysOnTop +ToolWindow +Owner +E0x08000000 -DPIScale")
    Bar_Gui.BackColor := Color_Bg
    Bar_Gui.SetFont("s" . Bar_FontSize . " w600 c" . Color_Active, "Segoe UI")

    Bar_LeftText := Bar_Gui.Add("Text"
        , "x" padding " y" textY " w" textBoxWidth " h" textControlH " BackgroundTrans", "")

    CalcMins(tStr) => Integer(SubStr(tStr, 1, 2)) * 60 + Integer(SubStr(tStr, 3, 2))
    BaseStartMins := 0, BaseEndMins := 1439
    if (Work_Mode != "off") {
        isWeekend := (A_WDay == 1 || A_WDay == 7)
        if !(isWeekend && Work_WeekendBar == "off") {
            BaseStartMins := CalcMins(Work_Start)
            BaseEndMins   := CalcMins(Work_End)
        }
    }
    TotalRange := BaseEndMins - BaseStartMins

    if (Work_TaskTimes != "" && TotalRange > 0) {
        CurrentUserWDay := (A_WDay == 1) ? 7 : A_WDay - 1
        DayTasks := []

        Loop Parse, Work_TaskTimes, ";" {
            if (A_LoopField == "")
                continue
            parts := StrSplit(A_LoopField, "_")
            if (parts.Length == 3 && Integer(parts[1]) == CurrentUserWDay) {
                rs := CalcMins(parts[2]), re := CalcMins(parts[3])
                s  := Max(rs, BaseStartMins), e := Min(re, BaseEndMins)
                if (e > s)
                    DayTasks.Push({Start: s, End: e, RawStart: rs})
            }
        }

        if (DayTasks.Length > 1) {
            Loop DayTasks.Length {
                i := A_Index
                Loop DayTasks.Length - i {
                    j := A_Index
                    if (DayTasks[j].RawStart > DayTasks[j+1].RawStart) {
                        temp := DayTasks[j]
                        DayTasks[j]   := DayTasks[j+1]
                        DayTasks[j+1] := temp
                    }
                }
            }
        }

        lastEndTrack1 := -1
        for task in DayTasks {
            offsetRatio := (task.Start - BaseStartMins) / TotalRange
            widthRatio  := (task.End - task.Start) / TotalRange
            mkX := Round(progressX + (progressWidth * offsetRatio))
            mkW := Max(2, Round(progressWidth * widthRatio))
            useY := track1Y
            if (task.Start < lastEndTrack1)
                useY := track2Y
            else
                lastEndTrack1 := task.End
            Bar_Gui.Add("Text"
                , Format("x{1} y{2} w{3} h{4} Background{5}", mkX, useY, mkW, taskH, Color_Task), "")
        }
    }

    Bar_Gui.Add("Text"
        , "x" progressX " y" progY " w" progressWidth " h6 Background333333", "")
    Bar_Progress := Bar_Gui.Add("Progress"
        , Format("x{1} y{2} w{3} h6 c{4} Background333333 +Smooth"
                , progressX, progY, progressWidth, Color_Active), 0)

    Bar_RightText := Bar_Gui.Add("Text"
        , "x" rightTextX " y" textY " w" textBoxWidth " h" textControlH
        . " BackgroundTrans Right", "")

    Bar_Gui.Show("x" barX " y" barY " w" barScreenWidth " h" Bar_Height " NoActivate")
    WinSetTransparent(Bar_Transparent, Bar_Gui.Hwnd)
}

UpdateStatusBar() {
    global CurrentDesktop, DesktopCount, Bar_LeftText
    if !IsObject(Bar_LeftText)
        return
    str := ""
    Loop DesktopCount
        str .= (A_Index == CurrentDesktop) ? " [" A_Index "] " : "  " A_Index "  "
    try Bar_LeftText.Value := str
}

UpdateClockAndProgress() {
    global Bar_RightText, Bar_Progress
    global Work_Start, Work_End, Work_WeekendBar, Work_Mode
    static LastDay := ""

    if !IsObject(Bar_RightText)
        return

    CurrentDay := FormatTime(, "yyyyMMdd")
    if (LastDay != "" && LastDay != CurrentDay)
        CreateStatusBar()
    LastDay := CurrentDay

    try Bar_RightText.Value := FormatTime(, "yyyy-MM-dd   HH:mm")

    NowTime := A_Now, TodayDate := FormatTime(NowTime, "yyyyMMdd")
    WDay := A_WDay, StartTS := "", EndTS := "", ForceFull := false

    if (Work_Mode = "off") {
        StartTS := TodayDate . "000000"
        EndTS   := TodayDate . "235959"
    } else {
        StartTS := TodayDate . Work_Start . "00"
        EndTS   := TodayDate . Work_End   . "00"
        if ((WDay == 1 || WDay == 7) && Work_WeekendBar = "off")
            ForceFull := true
    }

    pct := 0
    if ForceFull {
        pct := 100
    } else {
        TotalSec   := DateDiff(EndTS, StartTS, "Seconds")
        ElapsedSec := DateDiff(NowTime, StartTS, "Seconds")
        if (TotalSec <= 0)
            pct := 100
        else if (ElapsedSec < 0)
            pct := 0
        else if (ElapsedSec > TotalSec)
            pct := 100
        else
            pct := (ElapsedSec / TotalSec) * 100
    }
    try {
        if IsObject(Bar_Progress)
            Bar_Progress.Value := Integer(pct)
    }
}

ToggleBar(*) {
    global Bar_Visible, Bar_Gui
    Bar_Visible := !Bar_Visible
    if Bar_Visible
        Bar_Gui.Show("NoActivate")
    else
        Bar_Gui.Hide()
}

TogglePin(*) {
    global AlwaysVisible, Bar_Gui
    hwnd := 0
    try hwnd := WinExist("A")
    if (!hwnd || (Bar_Gui && hwnd == Bar_Gui.Hwnd))
        return

    if AlwaysVisible.Has(hwnd) {
        AlwaysVisible.Delete(hwnd)
        PinBorder.Remove(hwnd)
        ShowOSD("Unpinned")
    } else {
        AlwaysVisible[hwnd] := true
        PinBorder.Add(hwnd)
        ShowOSD("Pinned (Always Visible)")
    }
}

GatherAllToCurrent(*) {
    global Desktops, CurrentDesktop, AlwaysVisible, Bar_Gui
    ShowOSD("Gathering All Windows...")

    fullList := WinGetList()
    Loop DesktopCount
        Desktops[A_Index] := []
    AlwaysVisible.Clear()
    PinBorder.RemoveAll()
    count := 0

    for hwnd in fullList {
        try {
            if (Bar_Gui && hwnd == Bar_Gui.Hwnd)
                continue
            winClass := WinGetClass(hwnd)
            if (winClass == "Progman" || winClass == "Shell_TrayWnd")
                continue
            WinRestore(hwnd)
            Desktops[CurrentDesktop].Push(hwnd)
            count++
        }
    }
    ShowOSD("Gathered " . count . " Windows")
    WTM.OnWindowChanged()
}

; ---- Smart tiling (vertical / standard / ultrawide) ----
TileCurrentMonitor(*) {
    global Bar_Height, Bar_Visible, Bar_MonitorIdx

    MouseGetPos(&mx, &my)
    targetMon := GetMonitorIndexAtPoint(mx, my)
    MonitorGetWorkArea(targetMon, &WL, &WT, &WR, &WB)

    if (Bar_Visible && targetMon == Bar_MonitorIdx)
        WT += Bar_Height + 5

    W := WR - WL
    H := WB - WT
    aspect := (H != 0) ? W / H : 1

    windows := GetVisibleWindowsOnMonitor(targetMon)
    n := windows.Length
    if (n == 0) {
        ShowOSD("No Windows To Tile")
        return
    }

    if (H > W)
        mode := "Vertical"
    else if (aspect >= 32/9 - 0.15)
        mode := "Ultrawide"
    else
        mode := "Normal"

    ShowOSD("Tile [" . mode . "] [Mon " . targetMon . "]: " . n)

    switch mode {
        case "Vertical":  TileVertical(windows, WL, WT, W, H)
        case "Ultrawide": TileUltrawide(windows, WL, WT, W, H)
        default:          TileNormal(windows, WL, WT, W, H)
    }
}

PlaceWin(hwnd, x, y, w, h) {
    try {
        WinRestore(hwnd)
        WinMove(Round(x), Round(y), Round(w), Round(h), hwnd)
    }
}

; Zero-gap grid: auto rows/cols, last row stretches to fill width
TileGrid(wins, X, Y, W, H, isVertical := false) {
    n := wins.Length
    if (n == 0)
        return
    if (n == 1) {
        PlaceWin(wins[1], X, Y, W, H)
        return
    }
    if isVertical {
        rows := Ceil(Sqrt(n))
        cols := Ceil(n / rows)
    } else {
        cols := Ceil(Sqrt(n))
        rows := Ceil(n / cols)
    }
    rowH := H / rows
    idx  := 1
    Loop rows {
        r := A_Index - 1
        remaining := n - (idx - 1)
        rowsLeft  := rows - r
        thisCols := Min(cols, remaining)
        if (rowsLeft > 1 && thisCols > remaining - (rowsLeft - 1))
            thisCols := remaining - (rowsLeft - 1)
        thisCols := Max(1, Min(cols, thisCols))
        colW := W / thisCols
        Loop thisCols {
            c := A_Index - 1
            if (idx > n)
                break
            PlaceWin(wins[idx], X + c * colW, Y + r * rowH, colW, rowH)
            idx++
        }
    }
}

TileNormal(wins, WL, WT, W, H) {
    n := wins.Length
    ; Special-case layouts: 3 windows (left-big + right-split) / 5 windows (center + 4 corners)
    switch n {
        case 3:
            PlaceWin(wins[1], WL,        WT,        W/2, H)
            PlaceWin(wins[2], WL + W/2,  WT,        W/2, H/2)
            PlaceWin(wins[3], WL + W/2,  WT + H/2,  W/2, H/2)
            return
        case 5:
            colW := W/3, halfH := H/2
            PlaceWin(wins[1], WL + colW,    WT,         colW, H)
            PlaceWin(wins[2], WL,           WT,         colW, halfH)
            PlaceWin(wins[3], WL,           WT + halfH, colW, halfH)
            PlaceWin(wins[4], WL + 2*colW,  WT,         colW, halfH)
            PlaceWin(wins[5], WL + 2*colW,  WT + halfH, colW, halfH)
            return
    }
    TileGrid(wins, WL, WT, W, H, false)
}

TileVertical(wins, X, Y, W, H) {
    n := wins.Length
    if (n <= 3) {
        itemH := H / n
        for i, hwnd in wins
            PlaceWin(hwnd, X, Y + (i-1)*itemH, W, itemH)
        return
    }
    TileGrid(wins, X, Y, W, H, true)
}

TileUltrawide(wins, X, Y, W, H) {
    n := wins.Length
    if (n == 1) {
        mainW := Min(W, H * 16/9)
        PlaceWin(wins[1], X + (W - mainW)/2, Y, mainW, H)
        return
    }
    if (n == 2) {
        PlaceWin(wins[1], X,       Y, W/2, H)
        PlaceWin(wins[2], X + W/2, Y, W/2, H)
        return
    }
    mainW := Min(H * 16/9, W * 0.5)
    sideW := (W - mainW) / 2
    mainX := X + sideW
    PlaceWin(wins[1], mainX, Y, mainW, H)
    leftCount  := Floor((n-1) / 2)
    rightCount := (n-1) - leftCount
    if (leftCount > 0) {
        leftWins := []
        Loop leftCount
            leftWins.Push(wins[1 + A_Index])
        TileGrid(leftWins, X, Y, sideW, H, true)
    }
    if (rightCount > 0) {
        rightWins := []
        Loop rightCount
            rightWins.Push(wins[1 + leftCount + A_Index])
        TileGrid(rightWins, X + sideW + mainW, Y, sideW, H, true)
    }
}

GetVisibleWindowsOnMonitor(monIdx) {
    out := []
    for hwnd in GetVisibleWindow() {
        try {
            WinGetPos(&wx, &wy, &ww, &wh, hwnd)
            cx := wx + ww/2, cy := wy + wh/2
            if (GetMonitorIndexAtPoint(cx, cy) == monIdx)
                out.Push(hwnd)
        }
    }
    return out
}

GetVisibleWindow() {
    windows := []
    ids := WinGetList(,, "Program Manager")
    for this_id in ids {
        try {
            style := WinGetStyle(this_id)
        } catch {
            continue
        }
        if !(style & 0x10000000)
            continue
        exStyle := WinGetExStyle(this_id)
        if (exStyle & 0x00000080)
            continue
        isCloaked := 0
        try {
            DllCall("dwmapi\DwmGetWindowAttribute"
                , "Ptr", this_id, "Int", 14, "Int*", &isCloaked, "Int", 4)
            if isCloaked
                continue
        }
        title := WinGetTitle(this_id)
        if (title == "")
            continue
        WinGetPos(,, &w, &h, this_id)
        if (w < 100 || h < 100)
            continue
        windows.Push(this_id)
    }
    return windows
}

; ---- Window snapping ----
SnapWindow(direction, *) {
    global Bar_Visible, Bar_Height, Bar_MonitorIdx
    hwnd := 0
    try hwnd := WinExist("A")
    if !hwnd
        return

    targetMon := GetMonitorIndex(hwnd)
    MonitorGetWorkArea(targetMon, &L, &T, &R, &B)
    if (Bar_Visible && targetMon == Bar_MonitorIdx)
        T += Bar_Height + 5
    W := R - L, H := B - T

    try {
        switch direction {
            case "Left":
                WinRestore(hwnd)
                WinMove(L, T, W/2, H, hwnd)
                ShowOSD("Snap <-")
            case "Right":
                WinRestore(hwnd)
                WinMove(L + W/2, T, W/2, H, hwnd)
                ShowOSD("Snap ->")
            case "Up":
                WinMaximize(hwnd)
                ShowOSD("Maximize")
            case "Down":
                WinMinimize(hwnd)
                ShowOSD("Minimize")
        }
    }
}

; ---- Layout snapshot ----
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

; ---- Clipboard / Vim / Terminal / Power ----
OnClipboardChanged(dataType) {
    if (dataType != 1)
        return
    RecordClipboard()
}

RecordClipboard() {
    global LastClipContent, Path_OutputFile
    txt := ""
    try txt := A_Clipboard
    if (Type(txt) != "String" || txt == "" || txt == LastClipContent)
        return
    LastClipContent := txt
    Content := "------------------------------------------------------------------------------------------------`r`n"
             . FormatTime(, "yyyy-MM-dd HH:mm:ss") . "`r`n" . txt . "`r`n`r`n"
    try FileAppend(Content, Path_OutputFile, "UTF-8")
}

ToggleVimWindow() {
    global Vim_CurrentPID, Path_Vim, Path_OutputFile, Vim_X, Vim_Y, Vim_Width, Vim_Height
    if (Vim_CurrentPID && WinExist("ahk_pid " . Vim_CurrentPID)) {
        WinClose("ahk_pid " . Vim_CurrentPID)
        Vim_CurrentPID := 0
        return
    }
    if InStr(Path_Vim, "vim")
        RunCmd := Format('"{1}" "+$" "{2}"', Path_Vim, Path_OutputFile)
    else
        RunCmd := Format('"{1}" "{2}"', Path_Vim, Path_OutputFile)

    try {
        Run(RunCmd, , , &pid)
        Vim_CurrentPID := pid
        if WinWait("ahk_pid " . pid, , 3) {
            WinSetAlwaysOnTop(1, "ahk_pid " . pid)
            WinMove(Vim_X, Vim_Y, Vim_Width, Vim_Height, "ahk_pid " . pid)
            WinActivate("ahk_pid " . pid)
        }
    } catch {
        ShowOSD("Vim Boot Failed")
    }
}

LaunchTerminal(*) {
    global Path_Terminal
    path := Explorer_GetPath()
    try Run('"' . Path_Terminal . '"' . (path ? ' -d "' . path . '"' : ""))
}

OpenWithVim(*) {
    global Path_Vim
    targetPath := Explorer_GetSelection()
    if (targetPath == "") {
        ShowOSD("No File Selected")
        return
    }
    try Run('"' . Path_Vim . '" "' . targetPath . '"')
    catch
        ShowOSD("Vim Launch Failed")
}

ShowPowerMenu(*) {
    static pGui := ""
    if IsObject(pGui) {
        pGui.Destroy()
        pGui := ""
        return
    }
    pGui := Gui("+AlwaysOnTop -Caption +ToolWindow +Owner")
    pGui.BackColor := PM_Bg
    pGui.SetFont("s12 c" . Color_Text, "Arial")
    pGui.Add("Text", "x0 y15 w500 Center c" . Color_Active, "System Power Menu")
    pGui.Add("Text", "x50 y45 w400 h2 0x10")

    AddBtn(x, y, txt, fn, col) {
        btn := pGui.Add("Text"
            , "x" x " y" y " w120 h60 Center 0x200 +Border cWhite Background" col, txt)
        btn.OnEvent("Click", fn)
    }
    AddBtn(50,  70, "Shutdown", (*) => Shutdown(1), PM_BtnShutdown)
    AddBtn(190, 70, "Sleep"
         , (*) => DllCall("PowrProf\SetSuspendState","Int",0,"Int",0,"Int",0), PM_BtnSleep)
    AddBtn(330, 70, "Reboot",   (*) => Shutdown(2), PM_BtnReboot)
    pGui.OnEvent("Escape", (*) => (pGui.Destroy(), pGui := ""))
    pGui.Show("w500 h160")
}

; ---- Theme switching ----
ApplyTheme(themeName, *) {
    IniWrite(themeName, ConfigFile, "General", "ActiveTheme")
    ShowOSD("Theme: " . themeName)
    Sleep(400)
    Reload()
}

ExportThemeToCustom(*) {
    global ActiveTheme, Themes, ConfigFile
    if (ActiveTheme = "custom" || !Themes.Has(ActiveTheme)) {
        ShowOSD("Already custom")
        return
    }
    palette := Themes[ActiveTheme]
    nameMap := Map(
        "Color_Bg",          "Background",
        "Color_Text",        "Text",
        "Color_Active",      "Active",
        "Color_Task",        "Task",
        "Border_Drag_Color", "BorderDrag",
        "Border_Pin_Color",  "BorderPin",
        "PM_Bg",             "PowerMenuBg",
        "PM_BtnShutdown",    "PowerBtnShutdown",
        "PM_BtnSleep",       "PowerBtnSleep",
        "PM_BtnReboot",      "PowerBtnReboot"
    )
    for key, val in palette {
        ini := nameMap.Has(key) ? nameMap[key] : key
        IniWrite(val, ConfigFile, "Colors", ini)
    }
    IniWrite("custom", ConfigFile, "General", "ActiveTheme")
    ShowOSD("Exported -> custom")
    Sleep(400)
    Reload()
}

; ---- Misc helpers ----
RestoreAndExit(*) {
    global Bar_Gui
    ShowOSD("Script Shutting Down ...")
    Sleep(500)
    WTM.Deactivate()
    PinBorder.RemoveAll()
    if IsObject(Bar_Gui)
        Bar_Gui.Destroy()
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
    global Bar_Gui
    list := WinGetList()
    windows := []
    for hwnd in list {
        try {
            if (Bar_Gui && hwnd == Bar_Gui.Hwnd)
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
    winClass := WinGetClass(hwnd)
    if (winClass ~= "Progman|WorkerW")
        return A_Desktop
    if (winClass ~= "(Cabinet|Explore)WClass") {
        try {
            for window in ComObject("Shell.Application").Windows {
                if (window.HWND == hwnd)
                    return window.Document.Folder.Self.Path
            }
        }
    }
    return ""
}

; ---- Tray menu ----
SetupTrayIcon() {
    global Themes, ActiveTheme
    A_TrayMenu.Delete()
    A_TrayMenu.Add("Gather All Windows", GatherAllToCurrent)
    A_TrayMenu.Add("Toggle Status Bar",  ToggleBar)
    A_TrayMenu.Add("Toggle WTM Mode",    (*) => WTM.Toggle())
    A_TrayMenu.Add("Save Layout",        SaveLayout)
    A_TrayMenu.Add("Restore Layout",     RestoreLayout)
    A_TrayMenu.Add()

    themeMenu := Menu()
    themeMenu.Add("custom (use [Colors])", ApplyTheme.Bind("custom"))
    for name, _ in Themes
        themeMenu.Add(name, ApplyTheme.Bind(name))
    try themeMenu.Check(ActiveTheme = "custom" ? "custom (use [Colors])" : ActiveTheme)
    A_TrayMenu.Add("Theme", themeMenu)
    A_TrayMenu.Add("Export Theme -> custom", ExportThemeToCustom)
    A_TrayMenu.Add()

    Loop DesktopCount {
        i := A_Index
        A_TrayMenu.Add("Switch to Desktop " . i, SwitchDesktop.Bind(i))
    }

    A_TrayMenu.Add()
    A_TrayMenu.Add("Show Welcome", (*) => (
            FileExist(WelcomeFlag) ? FileDelete(WelcomeFlag) : "",
            WelcomeScreen.Show()
        ))
    A_TrayMenu.Add("Open Config Folder",  (*) => Run('explorer.exe "' . ConfigDir . '"'))
    A_TrayMenu.Add("Reload Script",       (*) => Reload())
    A_TrayMenu.Add("Restore && Exit",     RestoreAndExit)

    A_IconTip := "WM Script - Desktop " . CurrentDesktop
}

; ---- Mouse drag move / resize ----
DragMoveHandler(*) {
    MouseGetPos(,, &hwnd)
    if !hwnd
        return
    try WinActivate(hwnd)
    catch
        return

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
    try WinGetPos(&winX, &winY, &winW, &winH, hwnd)
    catch
        return

    DragBorder.Show()
    while GetKeyState("LButton", "P") {
        MouseGetPos(&curX, &curY)
        try WinMove(winX + (curX - startX), winY + (curY - startY),,, hwnd)
        catch
            break
        DragBorder.Update(hwnd)
    }
    DragBorder.Destroy()
    WTM.OnWindowChanged()
}

DragResizeHandler(*) {
    MouseGetPos(,, &hwnd)
    if !hwnd
        return
    if (WinGetMinMax(hwnd) == 1)
        return

    try WinGetPos(&winX, &winY, &winW, &winH, hwnd)
    catch
        return
    if (winW <= 0 || winH <= 0)
        return

    MouseGetPos(&startX, &startY)
    isLeft := (startX - winX) / winW < 0.5
    isUp   := (startY - winY) / winH < 0.5

    DragBorder.Show()
    while GetKeyState("RButton", "P") {
        MouseGetPos(&curX, &curY)
        dX := curX - startX, dY := curY - startY
        nX := isLeft ? (winX+dX) : winX, nW := isLeft ? (winW-dX) : (winW+dX)
        nY := isUp   ? (winY+dY) : winY, nH := isUp   ? (winH-dY) : (winH+dY)
        if (nW > 50 && nH > 50) {
            try WinMove(nX, nY, nW, nH, hwnd)
            catch
                break
            DragBorder.Update(hwnd)
        }
    }
    DragBorder.Destroy()
    WTM.OnWindowChanged()
}

; ==============================================================================
;  WTM - Windows Tile Manager (hyprland-like dynamic tiling mode)
;     - Toggle on/off (WTMToggle)
;     - Stable TileOrder: existing windows keep slot; new ones append;
;       gone/excluded ones drop out -> manual moves don't reshuffle layout
;     - HJKL focus / Shift+HJKL swap
;     - Alt+T excludes the focused / under-cursor window from tiling
;     - Auto re-tile on add / remove / size change
; ==============================================================================
class WTM {
    static Active     := false
    static TileOrder  := []
    static Excluded   := Map()
    static FocusHwnd  := 0
    static BorderGuis := []
    static _LastSig   := ""
    static TickFn     := ObjBindMethod(WTM, "Tick")

    static Toggle() {
        if this.Active
            this.Deactivate()
        else
            this.Activate()
    }

    static Activate() {
        this.Active    := true
        this.Excluded  := Map()
        this.TileOrder := []
        this._LastSig  := ""
        this.CreateBorder()
        this.RebuildOrder()
        this.AutoTile()
        SetTimer(this.TickFn, 150)
        ShowOSD("WTM Mode: ON")
    }

    static Deactivate() {
        this.Active := false
        SetTimer(this.TickFn, 0)
        this.DestroyBorder()
        ShowOSD("WTM Mode: OFF")
    }

    static OnDesktopSwitched() {
        if !this.Active
            return
        this.TileOrder := []
        this.RebuildOrder()
        this.AutoTile()
    }

    static OnWindowChanged() {
        if !this.Active
            return
        this.AutoTile()
    }

    ; Stable order: keep existing slots; append newcomers; drop dead/excluded.
    static RebuildOrder() {
        alive := Map()
        for hwnd in GetVisibleWindowsOnMonitor(GetMonitorIndex())
            alive[hwnd] := true
        newOrder := []
        for hwnd in this.TileOrder {
            if alive.Has(hwnd) && !this.Excluded.Has(hwnd) && WinExist(hwnd) {
                newOrder.Push(hwnd)
                alive.Delete(hwnd)
            }
        }
        for hwnd, _ in alive {
            if !this.Excluded.Has(hwnd)
                newOrder.Push(hwnd)
        }
        this.TileOrder := newOrder
    }

    static AutoTile() {
        global Bar_Height, Bar_Visible, Bar_MonitorIdx
        this.RebuildOrder()
        if (this.TileOrder.Length = 0)
            return
        mon := GetMonitorIndex()
        MonitorGetWorkArea(mon, &WL, &WT, &WR, &WB)
        if (Bar_Visible && mon = Bar_MonitorIdx)
            WT += Bar_Height + 5
        W := WR - WL, H := WB - WT
        aspect := (H != 0) ? W / H : 1
        if (H > W)
            TileVertical(this.TileOrder, WL, WT, W, H)
        else if (aspect >= 32/9 - 0.15)
            TileUltrawide(this.TileOrder, WL, WT, W, H)
        else
            TileNormal(this.TileOrder, WL, WT, W, H)
    }

    static Tick() {
        if !this.Active
            return
        ; Detect window add/remove/resize -> trigger auto re-tile
        sig := ""
        for hwnd in GetVisibleWindowsOnMonitor(GetMonitorIndex()) {
            if this.Excluded.Has(hwnd)
                continue
            try {
                WinGetPos(&x, &y, &w, &h, hwnd)
                sig .= hwnd "|" w "x" h ";"
            }
        }
        if (sig != this._LastSig) {
            this._LastSig := sig
            this.AutoTile()
            ; refresh sig after retile to avoid endless loop
            sig := ""
            for hwnd in GetVisibleWindowsOnMonitor(GetMonitorIndex()) {
                if this.Excluded.Has(hwnd)
                    continue
                try {
                    WinGetPos(&x, &y, &w, &h, hwnd)
                    sig .= hwnd "|" w "x" h ";"
                }
            }
            this._LastSig := sig
        }
        ; Update focus border
        try {
            fh := WinGetID("A")
            if (fh && fh != this.FocusHwnd) {
                this.FocusHwnd := fh
                this.RefreshBorder()
            } else if (fh) {
                this.RefreshBorder()
            }
        }
    }

    static FocusDir(dir) {
        if !this.Active
            return
        this.RebuildOrder()
        if (this.TileOrder.Length = 0)
            return
        cur := this.FocusHwnd ? this.FocusHwnd : this.TileOrder[1]
        target := this._PickNeighbor(cur, dir)
        if target {
            try {
                WinActivate(target)
                this.FocusHwnd := target
                this.RefreshBorder()
            }
        }
    }

    static MoveDir(dir) {
        if !this.Active
            return
        this.RebuildOrder()
        cur := this.FocusHwnd ? this.FocusHwnd : (this.TileOrder.Length ? this.TileOrder[1] : 0)
        if !cur
            return
        target := this._PickNeighbor(cur, dir)
        if !target
            return
        i1 := this._OrderIndex(cur)
        i2 := this._OrderIndex(target)
        if (i1 && i2) {
            tmp := this.TileOrder[i1]
            this.TileOrder[i1] := this.TileOrder[i2]
            this.TileOrder[i2] := tmp
            this.AutoTile()
        }
    }

    static TogglePinExclude() {
        ; Exclude / re-include the window under cursor (or focused) from tiling.
        MouseGetPos(,, &hwnd)
        if !hwnd {
            try hwnd := WinGetID("A")
        }
        if !hwnd
            return
        if this.Excluded.Has(hwnd) {
            this.Excluded.Delete(hwnd)
            try WinSetAlwaysOnTop(0, hwnd)
            ShowOSD("WTM Include")
        } else {
            this.Excluded[hwnd] := true
            try WinSetAlwaysOnTop(1, hwnd)
            ShowOSD("WTM Exclude (floating)")
        }
        this.RebuildOrder()
        this.AutoTile()
    }

    static _OrderIndex(hwnd) {
        for i, h in this.TileOrder
            if (h = hwnd)
                return i
        return 0
    }

; Pick nearest neighbor in direction (L/R/U/D) using window centers.
    static _PickNeighbor(hwnd, dir) {
        if !WinExist(hwnd)
            return 0
        try WinGetPos(&cx, &cy, &cw, &ch, hwnd)
        catch
            return 0
        ccx := cx + cw/2, ccy := cy + ch/2
        best := 0, bestDist := 1.0e18
        for h in this.TileOrder {
            if (h = hwnd)
                continue
            try WinGetPos(&x, &y, &w, &h2, h)
            catch
                continue
            tx := x + w/2, ty := y + h2/2
            dx := tx - ccx, dy := ty - ccy

            ; Direction filter: skip if neighbor is not on the requested side
            skip := false
            if      (dir = "L" && dx >= 0)
                skip := true
            else if (dir = "R" && dx <= 0)
                skip := true
            else if (dir = "U" && dy >= 0)
                skip := true
            else if (dir = "D" && dy <= 0)
                skip := true
            if skip
                continue

            dist := dx*dx + dy*dy
            if (dist < bestDist) {
                bestDist := dist
                best := h
            }
        }
        return best
    }

    static CreateBorder() {
        this.DestroyBorder()
        Loop 4 {
            g := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 -DPIScale")
            g.BackColor := WTM_BorderFocusColor
            g.Show("NoActivate x-1000 y-1000 w10 h10")
            WinSetTransparent(WTM_BorderOpacity, g.Hwnd)
            this.BorderGuis.Push(g)
        }
    }

    static DestroyBorder() {
        for g in this.BorderGuis
            try g.Destroy()
        this.BorderGuis := []
    }

    static RefreshBorder() {
        if (this.BorderGuis.Length != 4)
            return
        h := this.FocusHwnd
        if !h || !WinExist(h) {
            for g in this.BorderGuis
                try WinMove(-2000, -2000, 1, 1, g.Hwnd)
            return
        }
        if !GetWindowVisualRect(h, &x, &y, &w, &ht)
            return
        t  := Max(2, WTM_BorderThickness)
        o  := WTM_BorderOffset
        x -= o, y -= o, w += 2*o, ht += 2*o
        try {
            WinMove(x,        y,         w,  t, this.BorderGuis[1].Hwnd)
            WinMove(x,        y+ht-t,    w,  t, this.BorderGuis[2].Hwnd)
            WinMove(x,        y,         t, ht, this.BorderGuis[3].Hwnd)
            WinMove(x+w-t,    y,         t, ht, this.BorderGuis[4].Hwnd)
        }
    }
}

; ---- External eight-direction button scripts ----
#Include "*i %A_ScriptDir%\Buttons\Top.ahk"
#Include "*i %A_ScriptDir%\Buttons\TopRight.ahk"
#Include "*i %A_ScriptDir%\Buttons\Right.ahk"
#Include "*i %A_ScriptDir%\Buttons\DownRight.ahk"
#Include "*i %A_ScriptDir%\Buttons\Down.ahk"
#Include "*i %A_ScriptDir%\Buttons\DownLeft.ahk"
#Include "*i %A_ScriptDir%\Buttons\Left.ahk"
#Include "*i %A_ScriptDir%\Buttons\TopLeft.ahk"
