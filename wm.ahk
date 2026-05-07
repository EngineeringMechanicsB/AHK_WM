#Requires AutoHotkey v2.0
#SingleInstance Force
#WinActivateForce

; ==============================================================================
;  WM Script - v2.0
;  - Refactored naming, multi-monitor tiling/bar, drag+resize borders, themes
; ==============================================================================

SetWorkingDir(A_ScriptDir)
CoordMode("Mouse", "Screen")
SetTitleMatchMode(2)
SetWinDelay(0)
SetControlDelay(0)

; ------------------------------------------------------------------------------
; Globals (grouped & prefixed)
; ------------------------------------------------------------------------------
; --- Visual ---
global Color_Bg, Color_Text, Color_Active, Color_Task

; --- Status Bar ---
global Bar_Height, Bar_Transparent, Bar_FontSize
global Bar_MonitorIdx := 1                        ; 哪个显示器显示 Bar
global Bar_Visible    := true
global Bar_Gui := "", Bar_LeftText := "", Bar_RightText := "", Bar_Progress := ""

; --- Pie Menu ---
global Pie_Size, Pie_Radius, Pie_CenterZone
global Pie_FontSize, Pie_FontSizeActive, Pie_Transparent
global Pie_Config

; --- Paths ---
global Path_Button, Path_Output, Path_OutputFile, Path_Vim, Path_Terminal

; --- Vim Window Layout ---
global Vim_X, Vim_Y, Vim_Width, Vim_Height
global Vim_CurrentPID := 0

; --- OSD ---
global OSD_Height, OSD_Transparent

; --- Work Time / Task Bar ---
global Work_Start, Work_End, Work_WeekendBar, Work_Mode, Work_TaskTimes

; --- Theme ---
global ActiveTheme

; --- Drag Border (临时, 拖拽/调整大小时显示) ---
global Border_Drag_Enable, Border_Drag_Thickness
global Border_Drag_Offset, Border_Drag_OffsetTop
global Border_Drag_Color, Border_Drag_Transparent

; --- Pin Border (持久, 置顶窗口) ---
global Border_Pin_Thickness, Border_Pin_Offset, Border_Pin_OffsetTop
global Border_Pin_Color, Border_Pin_Transparent

; --- Power Menu ---
global PM_Bg, PM_BtnShutdown, PM_BtnSleep, PM_BtnReboot

; --- Runtime State ---
global ConfigDir  := EnvGet("USERPROFILE") . "\.config\AHK_WM"
global ConfigFile := ConfigDir . "\wm_config.ini"
global CurrentDesktop  := 1
global DesktopCount    := 9
global Desktops        := Map()
global AlwaysVisible   := Map()
global LastClipContent := ""
global LayoutSnapshot  := Map()

Pie_Config := Map(
    "Top",       "↑", "TopRight",  "↗", "Right",     "→", "DownRight", "↘",
    "Down",      "↓", "DownLeft",  "↙", "Left",      "←", "TopLeft",   "↖",
    "Center",    "●"
)

; ==============================================================================
;  Built-in Themes (color overlay only, never overwrites your [Visual])
; ==============================================================================
global Themes := Map(
    "nord",             Map("Color_Bg","2E3440", "Color_Text","D8DEE9", "Color_Active","88C0D0", "Color_Task","A3BE8C", "Border_Drag_Color","88C0D0", "Border_Pin_Color","BF616A", "PM_Bg","3B4252", "PM_BtnShutdown","BF616A", "PM_BtnSleep","5E81AC", "PM_BtnReboot","D08770"),
    "tokyonight",       Map("Color_Bg","1A1B26", "Color_Text","C0CAF5", "Color_Active","7AA2F7", "Color_Task","9ECE6A", "Border_Drag_Color","7AA2F7", "Border_Pin_Color","F7768E", "PM_Bg","24283B", "PM_BtnShutdown","F7768E", "PM_BtnSleep","7AA2F7", "PM_BtnReboot","E0AF68"),
    "dracula",          Map("Color_Bg","282A36", "Color_Text","F8F8F2", "Color_Active","BD93F9", "Color_Task","50FA7B", "Border_Drag_Color","8BE9FD", "Border_Pin_Color","FF5555", "PM_Bg","44475A", "PM_BtnShutdown","FF5555", "PM_BtnSleep","6272A4", "PM_BtnReboot","FFB86C"),
    "gruvbox",          Map("Color_Bg","282828", "Color_Text","EBDBB2", "Color_Active","FABD2F", "Color_Task","B8BB26", "Border_Drag_Color","83A598", "Border_Pin_Color","FB4934", "PM_Bg","3C3836", "PM_BtnShutdown","FB4934", "PM_BtnSleep","458588", "PM_BtnReboot","FE8019"),
    "monokai",          Map("Color_Bg","272822", "Color_Text","F8F8F2", "Color_Active","A6E22E", "Color_Task","FD971F", "Border_Drag_Color","66D9EF", "Border_Pin_Color","F92672", "PM_Bg","3E3D32", "PM_BtnShutdown","F92672", "PM_BtnSleep","66D9EF", "PM_BtnReboot","FD971F"),
    "solarized-dark",   Map("Color_Bg","002B36", "Color_Text","839496", "Color_Active","268BD2", "Color_Task","859900", "Border_Drag_Color","2AA198", "Border_Pin_Color","DC322F", "PM_Bg","073642", "PM_BtnShutdown","DC322F", "PM_BtnSleep","268BD2", "PM_BtnReboot","CB4B16"),
    "solarized-light",  Map("Color_Bg","FDF6E3", "Color_Text","657B83", "Color_Active","268BD2", "Color_Task","859900", "Border_Drag_Color","2AA198", "Border_Pin_Color","DC322F", "PM_Bg","EEE8D5", "PM_BtnShutdown","DC322F", "PM_BtnSleep","268BD2", "PM_BtnReboot","CB4B16"),
    "catppuccin-mocha", Map("Color_Bg","1E1E2E", "Color_Text","CDD6F4", "Color_Active","CBA6F7", "Color_Task","A6E3A1", "Border_Drag_Color","89B4FA", "Border_Pin_Color","F38BA8", "PM_Bg","313244", "PM_BtnShutdown","F38BA8", "PM_BtnSleep","89B4FA", "PM_BtnReboot","FAB387"),
    "catppuccin-latte", Map("Color_Bg","EFF1F5", "Color_Text","4C4F69", "Color_Active","8839EF", "Color_Task","40A02B", "Border_Drag_Color","1E66F5", "Border_Pin_Color","D20F39", "PM_Bg","E6E9EF", "PM_BtnShutdown","D20F39", "PM_BtnSleep","1E66F5", "PM_BtnReboot","FE640B"),
    "onedark",          Map("Color_Bg","282C34", "Color_Text","ABB2BF", "Color_Active","61AFEF", "Color_Task","98C379", "Border_Drag_Color","56B6C2", "Border_Pin_Color","E06C75", "PM_Bg","3E4452", "PM_BtnShutdown","E06C75", "PM_BtnSleep","61AFEF", "PM_BtnReboot","D19A66"),
    "ayu-dark",         Map("Color_Bg","0A0E14", "Color_Text","B3B1AD", "Color_Active","FFB454", "Color_Task","C2D94C", "Border_Drag_Color","59C2FF", "Border_Pin_Color","F07178", "PM_Bg","131721", "PM_BtnShutdown","F07178", "PM_BtnSleep","59C2FF", "PM_BtnReboot","FF8F40"),
    "github-dark",      Map("Color_Bg","0D1117", "Color_Text","C9D1D9", "Color_Active","58A6FF", "Color_Task","3FB950", "Border_Drag_Color","58A6FF", "Border_Pin_Color","F85149", "PM_Bg","161B22", "PM_BtnShutdown","F85149", "PM_BtnSleep","58A6FF", "PM_BtnReboot","D29922"),
    "rose-pine",        Map("Color_Bg","191724", "Color_Text","E0DEF4", "Color_Active","C4A7E7", "Color_Task","9CCFD8", "Border_Drag_Color","31748F", "Border_Pin_Color","EB6F92", "PM_Bg","1F1D2E", "PM_BtnShutdown","EB6F92", "PM_BtnSleep","31748F", "PM_BtnReboot","F6C177"),
    "everforest",       Map("Color_Bg","2D353B", "Color_Text","D3C6AA", "Color_Active","A7C080", "Color_Task","DBBC7F", "Border_Drag_Color","7FBBB3", "Border_Pin_Color","E67E80", "PM_Bg","374145", "PM_BtnShutdown","E67E80", "PM_BtnSleep","7FBBB3", "PM_BtnReboot","E69875"),
    "kanagawa",         Map("Color_Bg","1F1F28", "Color_Text","DCD7BA", "Color_Active","7E9CD8", "Color_Task","98BB6C", "Border_Drag_Color","7FB4CA", "Border_Pin_Color","E46876", "PM_Bg","2A2A37", "PM_BtnShutdown","E46876", "PM_BtnSleep","7E9CD8", "PM_BtnReboot","FFA066"),
    "material-deep",    Map("Color_Bg","263238", "Color_Text","EEFFFF", "Color_Active","82AAFF", "Color_Task","C3E88D", "Border_Drag_Color","89DDFF", "Border_Pin_Color","F07178", "PM_Bg","37474F", "PM_BtnShutdown","F07178", "PM_BtnSleep","82AAFF", "PM_BtnReboot","F78C6C")
)

; ==============================================================================
;  Initialization
; ==============================================================================
LoadOrInitConfig()

Loop DesktopCount {
    Desktops[A_Index] := []
}

if !DirExist(Path_Output)
    DirCreate(Path_Output)
if !DirExist(Path_Button)
    DirCreate(Path_Button)

if InitializeButtons() {
    Reload()
}

if (IsSet(isFirstRun) && isFirstRun) {
	WelcomeScreen.Show()
}

CreateStatusBar()
UpdateStatusBar()
UpdateClockAndProgress()
SetTimer(UpdateClockAndProgress, 1000)
SetupTrayIcon()
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

Hotkey("!d",       TileCurrentMonitor)
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

~LButton & RButton:: Send("^c")
~RButton & LButton:: Send("^c")

Hotkey("!Enter", LaunchTerminal)
Hotkey("!s", (*) => Run("devmgmt.msc"))
Hotkey("!n", (*) => Run("ncpa.cpl"))
Hotkey("!v", OpenWithVim)
Hotkey("!x", ShowPowerMenu)

Hotkey("!Left",  SnapWindow.Bind("Left"))
Hotkey("!Right", SnapWindow.Bind("Right"))
Hotkey("!Up",    SnapWindow.Bind("Up"))
Hotkey("!Down",  SnapWindow.Bind("Down"))

Hotkey("!+s", SaveLayout)
Hotkey("!+r", RestoreLayout)

!r::{
    Reload()
}

^`:: ToggleVimWindow()

~Space & RButton:: PieMenu.Start()

Space Up::
RButton Up:: 
{
    if PieMenu.IsActive
        PieMenu.Execute()
}

; ==============================================================================
;  [Module] Config File
; ==============================================================================
LoadOrInitConfig() {
    global

    if !DirExist(ConfigDir) {
        try {
            DirCreate(ConfigDir)
        } catch as e {
            MsgBox("Failed to create config directory:`n" . ConfigDir . "`n`n" . e.Message)
            ExitApp
        }
    }

    if !FileExist(ConfigFile) {
        DefaultIni := "
        (
        [WM_Config]

        [Theme]
        ; custom / nord / tokyonight / dracula / gruvbox / monokai
        ; / solarized-dark / solarized-light / catppuccin-mocha / catppuccin-latte
        ; / onedark / ayu-dark / github-dark / rose-pine / everforest / kanagawa / material-deep
        ; When NOT 'custom', built-in theme overrides color values in memory only.
        ; Your [Visual] / [Border_*] / [PowerMenu] colors in this file are NEVER touched.
        ActiveTheme=custom

        [Visual]
        ; Background Color
        Color_Bg=0e050f
        ; Text Color
        Color_Text=744da9
        ; Active/Highlight Color
        Color_Active=744da9

        [Bar]
        ; Status Bar Height (px)
        Height=35
        ; Status Bar Transparency (0-255)
        Transparent=200
        ; Status Bar Font Size
        FontSize=10
        ; Which monitor displays the bar (1-based)
        MonitorIdx=1

        [PieMenu]
        ; Menu Diameter
        Size=300
        ; Center Dead Zone Range
        CenterZone=40
        ; Menu Font Size
        FontSize=14
        ; Active Item Font Size
        FontSizeActive=22
        ; Menu Transparency (0-255)
        Transparent=200

        [Paths]
        ; Button Script Directory (relative or absolute)
        ButtonDir=Buttons
        ; Clipboard Recovery Output Directory
        OutputDir=C:\Users\Administrator\Documents
        ; Editor Path (Vim recommended)
        VimPath=C:\Windows\system32\notepad.exe
        ; Terminal Path
        TerminalExe=C:\Windows\system32\cmd.exe

        [VimLayout]
        ; Vim Window X / Y / Width / Height
        X=400
        Y=0
        Width=1000
        Height=800

        [OSD]
        ; OSD Height Position
        Height=850
        ; OSD Transparency (0-255)
        Transparent=200

        [WorkTime]
        ; Work Time Format HHmm
        WorkStart=0900
        WorkEnd=1745
        ; Show full bar on weekend (on/off)
        WeekendBar=off
        ; Use work-time progress / full-day progress (on/off)
        Mode=on
        ; Task Bar Color
        Color_Task=CF8DC9
        ; Task Time entries: D_HHMM_HHMM (D=1-7 Mon-Sun); separated by ';'
        TaskTimes=1_1200_1300;2_1200_1300;3_1200_1300;4_1200_1300;5_1200_1300;6_1200_1300;7_1200_1300;2_1700_1745;3_0900_0920;

        [Border_Drag]
        ; Border shown while dragging OR resizing window with Alt+LButton/RButton
        ; Enable on/off
        Enable=on
        ; Thickness in px
        Thickness=3
        ; Outward Offset in px (all 4 sides)
        Offset=0
        ; Extra TOP offset to compensate DWM invisible top frame
        OffsetTop=1
        ; Color
        Color=A020F0
        ; Transparency (0-255)
        Transparent=180

        [Border_Pin]
        ; Persistent border on pinned/always-on-top windows
        Thickness=2
        Offset=0
        OffsetTop=1
        Color=FF5555
        Transparent=200

        [PowerMenu]
        ; Power menu colors
        Bg=2E3440
        BtnShutdown=B48EAD
        BtnSleep=5E81AC
        BtnReboot=BF616A
        )"

		try {
		    FileAppend(DefaultIni, ConfigFile, "UTF-8")
		    isFirstRun := true
		} catch as e {
		    MsgBox("Failed to create config file: " . e.Message)
		    ExitApp
		}
            }

    ; --- Theme ---
    ActiveTheme              := IniRead(ConfigFile, "Theme",       "ActiveTheme", "custom")

    ; --- Visual ---
    Color_Bg                 := IniRead(ConfigFile, "Visual",      "Color_Bg",     "181818")
    Color_Text               := IniRead(ConfigFile, "Visual",      "Color_Text",   "CCCCCC")
    Color_Active             := IniRead(ConfigFile, "Visual",      "Color_Active", "A020F0")

    ; --- Bar ---
    Bar_Height               := Integer(IniRead(ConfigFile, "Bar", "Height",      "35"))
    Bar_Transparent          := Integer(IniRead(ConfigFile, "Bar", "Transparent", "200"))
    Bar_FontSize             := Integer(IniRead(ConfigFile, "Bar", "FontSize",    "10"))
    Bar_MonitorIdx           := Integer(IniRead(ConfigFile, "Bar", "MonitorIdx",  "1"))

    ; --- Pie Menu ---
    Pie_Size                 := Integer(IniRead(ConfigFile, "PieMenu", "Size",            "300"))
    Pie_Radius               := Pie_Size / 2
    Pie_CenterZone           := Integer(IniRead(ConfigFile, "PieMenu", "CenterZone",      "40"))
    Pie_FontSize             := Integer(IniRead(ConfigFile, "PieMenu", "FontSize",        "14"))
    Pie_FontSizeActive       := Integer(IniRead(ConfigFile, "PieMenu", "FontSizeActive",  "22"))
    Pie_Transparent          := Integer(IniRead(ConfigFile, "PieMenu", "Transparent",     "200"))

    ; --- Paths ---
    bDirTemp                 := IniRead(ConfigFile, "Paths", "ButtonDir", "Buttons")
    Path_Button              := (bDirTemp ~= "^[a-zA-Z]:") ? bDirTemp : (A_ScriptDir . "\" . bDirTemp)
    Path_Output              := IniRead(ConfigFile, "Paths", "OutputDir",   "C:\Users\Administrator\Documents")
    Path_OutputFile          := Path_Output . "\CB.txt"
    Path_Vim                 := IniRead(ConfigFile, "Paths", "VimPath",     "C:\Windows\system32\notepad.exe")
    Path_Terminal            := IniRead(ConfigFile, "Paths", "TerminalExe", "C:\Windows\system32\cmd.exe")

    ; --- Vim Layout ---
    Vim_X                    := Integer(IniRead(ConfigFile, "VimLayout", "X",      "400"))
    Vim_Y                    := Integer(IniRead(ConfigFile, "VimLayout", "Y",      "0"))
    Vim_Width                := Integer(IniRead(ConfigFile, "VimLayout", "Width",  "1000"))
    Vim_Height               := Integer(IniRead(ConfigFile, "VimLayout", "Height", "800"))

    ; --- OSD ---
    OSD_Height               := Integer(IniRead(ConfigFile, "OSD", "Height",      "850"))
    OSD_Transparent          := Integer(IniRead(ConfigFile, "OSD", "Transparent", "200"))

    ; --- Work Time ---
    Work_Start               := IniRead(ConfigFile, "WorkTime", "WorkStart",  "0900")
    Work_End                 := IniRead(ConfigFile, "WorkTime", "WorkEnd",    "1745")
    Work_WeekendBar          := IniRead(ConfigFile, "WorkTime", "WeekendBar", "off")
    Work_Mode                := IniRead(ConfigFile, "WorkTime", "Mode",       "on")
    Color_Task               := IniRead(ConfigFile, "WorkTime", "Color_Task", "069700")
    Work_TaskTimes           := IniRead(ConfigFile, "WorkTime", "TaskTimes",  "")

    ; --- Border (Drag) ---
    Border_Drag_Enable       := IniRead(ConfigFile, "Border_Drag", "Enable",      "on")
    Border_Drag_Thickness    := Integer(IniRead(ConfigFile, "Border_Drag", "Thickness",   "3"))
    Border_Drag_Offset       := Integer(IniRead(ConfigFile, "Border_Drag", "Offset",      "0"))
    Border_Drag_OffsetTop    := Integer(IniRead(ConfigFile, "Border_Drag", "OffsetTop",   "1"))
    Border_Drag_Color        := IniRead(ConfigFile, "Border_Drag", "Color",       "A020F0")
    Border_Drag_Transparent  := Integer(IniRead(ConfigFile, "Border_Drag", "Transparent", "180"))

    ; --- Border (Pin) ---
    Border_Pin_Thickness     := Integer(IniRead(ConfigFile, "Border_Pin", "Thickness",   "2"))
    Border_Pin_Offset        := Integer(IniRead(ConfigFile, "Border_Pin", "Offset",      "0"))
    Border_Pin_OffsetTop     := Integer(IniRead(ConfigFile, "Border_Pin", "OffsetTop",   "1"))
    Border_Pin_Color         := IniRead(ConfigFile, "Border_Pin", "Color",       "FF5555")
    Border_Pin_Transparent   := Integer(IniRead(ConfigFile, "Border_Pin", "Transparent", "200"))

    ; --- Power Menu ---
    PM_Bg                    := IniRead(ConfigFile, "PowerMenu", "Bg",          "2E3440")
    PM_BtnShutdown           := IniRead(ConfigFile, "PowerMenu", "BtnShutdown", "B48EAD")
    PM_BtnSleep              := IniRead(ConfigFile, "PowerMenu", "BtnSleep",    "5E81AC")
    PM_BtnReboot             := IniRead(ConfigFile, "PowerMenu", "BtnReboot",   "BF616A")

    ; --- Theme overlay (memory only; ini file untouched) ---
    if (ActiveTheme != "custom" && Themes.Has(ActiveTheme)) {
        palette := Themes[ActiveTheme]
        for key, val in palette {
            try {
                %key% := val
            } catch {
                continue
            }
        }
    }

    ; --- Validate Bar_MonitorIdx ---
    if (Bar_MonitorIdx < 1 || Bar_MonitorIdx > MonitorGetCount())
        Bar_MonitorIdx := 1
}

; ==============================================================================
;  [Module] DWM Visual Rect helper (compensates invisible window border)
; ==============================================================================
GetWindowVisualRect(hwnd, &x, &y, &w, &h) {
    rect := Buffer(16, 0)
    ; DWMWA_EXTENDED_FRAME_BOUNDS = 9
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

; ==============================================================================
;  [Module] Help GUI
; ==============================================================================
ShowHelpGui(*) {
    static helpGui := ""

    CloseWatcher() {
        if !IsObject(helpGui) {
            SetTimer CloseWatcher, 0
            return
        }
        if GetKeyState("Escape", "P") || GetKeyState("LButton", "P") {
            try {
                helpGui.Destroy()
            } catch {
                ; ignore
            }
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
    helpGui.SetFont("s16 w700 c" . Color_Active, "Segoe UI")
    helpGui.Add("Text", "x0 y25 w600 Center", "HELP")

    helpGui.SetFont("s10 w600 c" . Color_Active)
    helpGui.Add("Text", "x50 y65 w500 h2 0x10")

    shortcuts := [
        ["Alt + /",            "Show / Hide Help Menu"],
        ["Space + RClick",     "Pie Menu (Mouse)"],
        ["Alt + 1-9",          "Switch Desktop (+Shift Move, +Ctrl Move&Switch)"],
        ["Alt + LButton",      "Move Window (with border)"],
        ["Alt + RButton",      "Resize Window (with border)"],
        ["Alt + Wheel",        "Window Transparency"],
        ["Alt + Arrows",       "Snap L / R / Maximize / Minimize"],
        ["Alt + Shift + S/R",  "Save / Restore Layout"],
        ["Alt + Shift + G",    "Gather All Windows"],
        ["Alt + Q",            "Close Window"],
        ["Alt + D",            "Smart Tile (current monitor)"],
        ["Alt + W",            "Minimize Window"],
        ["Alt + F",            "Maximize / Restore"],
        ["Alt + R",            "Reload Script"],
        ["Alt + T",            "Toggle Pin / OnTop (with border)"],
        ["Ctrl + Alt + T",     "Toggle Always Visible"],
        ["Ctrl + ``",          "Clipboard History (Vim)"],
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
    SetTimer CloseWatcher, 50
}

; ==============================================================================
;  [Module] Welcome Screen (first-run only, fullscreen borderless)
; ==============================================================================
class WelcomeScreen {
    static GuiObj := ""

    static Show() {
        if IsObject(this.GuiObj)
            return

        ; 全屏覆盖整个虚拟桌面 (含多显示器)
        vx := SysGet(76)   ; SM_XVIRTUALSCREEN
        vy := SysGet(77)   ; SM_YVIRTUALSCREEN
        vw := SysGet(78)   ; SM_CXVIRTUALSCREEN
        vh := SysGet(79)   ; SM_CYVIRTUALSCREEN

        g := Gui("-Caption +AlwaysOnTop +ToolWindow -DPIScale +E0x08000000")
        g.BackColor := Color_Bg
        g.MarginX := 0
        g.MarginY := 0

        cx := vw // 2

        ; ---------- 主标题 ----------
        g.SetFont("s64 w800 c" . Color_Active, "Segoe UI")
        g.Add("Text", "x0 y" (vh*0.22) " w" vw " Center BackgroundTrans", "WM Script")

        ; ---------- 副标题 ----------
        g.SetFont("s18 w400 c" . Color_Text, "Segoe UI")
        g.Add("Text", "x0 y" (vh*0.35) " w" vw " Center BackgroundTrans"
            , "A minimalist tiling window manager for Windows")

        ; ---------- 分隔线 ----------
        g.Add("Text", "x" (cx-200) " y" (vh*0.40) " w400 h2 Background" Color_Active, "")

        ; ---------- 信息块 ----------
        g.SetFont("s13 w400 c" . Color_Text, "Consolas")
        infoLines := [
            "  >  9 Virtual Desktops          Alt + 1-9",
            "  >  Smart Tiling                  Alt + D",
            "  >  Pie Menu               Space + RClick",
            "  >  Window Snap              Alt + Arrows",
            "  >  Layout Snapshot     Alt + Shift + S/R",
            "  >  Help Menu                     Alt + /"
        ]
        yStart := vh * 0.46
        for i, line in infoLines {
            g.Add("Text", "x" (cx-260) " y" (yStart + (i-1)*32) " w520 BackgroundTrans c" Color_Text, line)
        }

        ; ---------- 配置路径提示 ----------
        g.SetFont("s11 w400 c" . Color_Text, "Consolas")
        g.Add("Text", "x0 y" (vh*0.78) " w" vw " Center BackgroundTrans"
            , "Config: " . ConfigFile)

        ; ---------- Footer (love & version) ----------
        g.SetFont("s14 w600 c" . Color_Active, "Segoe UI")
        g.Add("Text", "x0 y" (vh*0.84) " w" vw " Center BackgroundTrans"
            , "Made with <3 by ZXW")

        g.SetFont("s10 w400 c" . Color_Text, "Segoe UI")
        g.Add("Text", "x0 y" (vh*0.88) " w" vw " Center BackgroundTrans"
            , "v2.0  ::  AutoHotkey v2")

        ; ---------- 提示 ----------
        g.SetFont("s11 w600 c" . Color_Active, "Segoe UI")
        hint := g.Add("Text", "x0 y" (vh*0.93) " w" vw " Center BackgroundTrans"
            , "[ Press any key or click to continue ]")

        g.Show(Format("x{} y{} w{} h{} NoActivate", vx, vy, vw, vh))
        WinSetTransparent(245, g.Hwnd)
        this.GuiObj := g

        ; 闪烁提示文本 (呼吸效果)
        this.HintCtrl := hint
        this.HintState := true
        SetTimer(ObjBindMethod(this, "Blink"), 600)

        ; 关闭监听
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
        } catch {
            ; ignore
        }
    }

    static WaitClose() {
        if !IsObject(this.GuiObj) {
            SetTimer(ObjBindMethod(this, "WaitClose"), 0)
            return
        }
        if (GetKeyState("LButton","P") || GetKeyState("Escape","P")
         || GetKeyState("Enter","P")  || GetKeyState("Space","P")) {
            this.Close()
        }
    }

    static Close() {
        SetTimer(ObjBindMethod(this, "WaitClose"), 0)
        SetTimer(ObjBindMethod(this, "Blink"),     0)
        try {
            this.GuiObj.Destroy()
        } catch {
            ; ignore
        }
        this.GuiObj := ""
    }
}

; ==============================================================================
;  [Module] Pie Menu Buttons Init
; ==============================================================================
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

; ==============================================================================
;  [Module] OSD (multi-monitor aware, single instance)
; ==============================================================================
class OSD {
    static GuiObj := 0
    static Timer  := 0

    static Show(text, duration := 1000) {
        if IsObject(this.GuiObj) {
            try {
                this.GuiObj.Destroy()
            } catch {
                ; ignore
            }
            this.GuiObj := 0
        }
        if this.Timer
            SetTimer(this.Timer, 0)

        g := Gui("+AlwaysOnTop -Caption +ToolWindow +Disabled +Owner -DPIScale")
        g.BackColor := Color_Bg
        g.SetFont("s20 w600 c" . Color_Active, "Segoe UI")
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

; ==============================================================================
;  [Module] Drag Border (temporary, for move/resize)
; ==============================================================================
class DragBorder {
    static Guis := []

    static Show() {
        if (Border_Drag_Enable != "on")
            return
        this.Destroy()
        Loop 4 {
            g := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 -DPIScale")
            g.BackColor := Border_Drag_Color
            g.Show("NoActivate Hide")
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
        x -= o
        y -= (o + ot)
        w += 2*o
        h += 2*o + ot
        try {
            this.Guis[1].Show(Format("NoActivate x{} y{} w{} h{}", x,       y,       w, t))
            this.Guis[2].Show(Format("NoActivate x{} y{} w{} h{}", x,       y+h-t,   w, t))
            this.Guis[3].Show(Format("NoActivate x{} y{} w{} h{}", x,       y,       t, h))
            this.Guis[4].Show(Format("NoActivate x{} y{} w{} h{}", x+w-t,   y,       t, h))
        } catch {
            ; ignore
        }
    }

    static Destroy() {
        for g in this.Guis {
            try {
                g.Destroy()
            } catch {
                continue
            }
        }
        this.Guis := []
    }
}

; ==============================================================================
;  [Module] Pin Border (persistent for AlwaysOnTop windows)
; ==============================================================================
class PinBorder {
    static Map     := Map()
    static TimerFn := ObjBindMethod(PinBorder, "Tick")
    static Started := false

    static Add(hwnd) {
        if this.Map.Has(hwnd)
            return
        guis := []
        Loop 4 {
            g := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 -DPIScale")
            g.BackColor := Border_Pin_Color
            g.Show("NoActivate Hide")
            WinSetTransparent(Border_Pin_Transparent, g.Hwnd)
            guis.Push(g)
        }
        this.Map[hwnd] := guis
        if !this.Started {
            SetTimer(this.TimerFn, 100)
            this.Started := true
        }
    }

    static Remove(hwnd) {
        if !this.Map.Has(hwnd)
            return
        for g in this.Map[hwnd] {
            try {
                g.Destroy()
            } catch {
                continue
            }
        }
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
        for hwnd, guis in this.Map.Clone() {
            if !WinExist(hwnd) {
                this.Remove(hwnd)
                continue
            }
            try {
                if (WinGetMinMax(hwnd) = -1) {
                    for g in guis {
                        try {
                            g.Hide()
                        } catch {
                            continue
                        }
                    }
                    continue
                }
                if !GetWindowVisualRect(hwnd, &x, &y, &w, &h)
                    continue
            } catch {
                continue
            }
            t  := Border_Pin_Thickness
            o  := Border_Pin_Offset
            ot := Border_Pin_OffsetTop
            x -= o
            y -= (o + ot)
            w += 2*o
            h += 2*o + ot
            try {
                guis[1].Show(Format("NoActivate x{} y{} w{} h{}", x,       y,       w, t))
                guis[2].Show(Format("NoActivate x{} y{} w{} h{}", x,       y+h-t,   w, t))
                guis[3].Show(Format("NoActivate x{} y{} w{} h{}", x,       y,       t, h))
                guis[4].Show(Format("NoActivate x{} y{} w{} h{}", x+w-t,   y,       t, h))
            } catch {
                continue
            }
        }
    }
}

; ==============================================================================
;  [Module] Window Operations (under mouse)
; ==============================================================================
CloseWindowUnderMouse(*) {
    MouseGetPos(,, &hwnd)
    try {
        WinClose(hwnd)
        PinBorder.Remove(hwnd)
        ShowOSD("Closing Window...")
    } catch {
        return
    }
}

HideUnderMouse(*) {
    MouseGetPos(,, &hwnd)
    try {
        WinMinimize(hwnd)
        ShowOSD("WinMinimized")
    } catch {
        return
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
    } catch {
        return
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
    } catch {
        return
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
    } catch {
        return
    }
}

; ==============================================================================
;  [Module] Pie Menu
; ==============================================================================
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
            } catch {
                continue
            }
        }
        if this.Labels.Has(this.CurrentSector) {
            try {
                curr := this.Labels[this.CurrentSector]
                curr.SetFont("s" . Pie_FontSizeActive . " c" . Color_Active . " w700")
                curr.Opt("c" . Color_Active)
            } catch {
                ; ignore
            }
        }
    }

    static Execute() {
        this.IsActive := false
        SetTimer(this.TimerFn, 0)
        if IsObject(this.GuiObj)
            this.GuiObj.Destroy()
        if (this.CurrentSector != "Center" && this.CurrentSector != "") {
            try {
                %this.CurrentSector%()
            } catch {
                ShowOSD("Function Lost: " . this.CurrentSector)
            }
        }
    }
}

; ==============================================================================
;  [Module] Virtual Desktops
; ==============================================================================
SwitchDesktop(target, *) {
    global CurrentDesktop, Desktops, AlwaysVisible
    if (target == CurrentDesktop) {
        ShowOSD("Desktop " . target)
        return
    }
    Desktops[CurrentDesktop] := GetVisibleWindows()
    for hwnd in Desktops[CurrentDesktop] {
        if !AlwaysVisible.Has(hwnd) {
            try {
                WinMinimize(hwnd)
            } catch {
                continue
            }
        }
    }
    for hwnd in Desktops[target] {
        try {
            WinRestore(hwnd)
        } catch {
            continue
        }
    }
    for hwnd, _ in AlwaysVisible {
        try {
            WinRestore(hwnd)
        } catch {
            continue
        }
    }

    CurrentDesktop := target
    UpdateStatusBar()
    A_IconTip := "WM Script - Desktop " . CurrentDesktop
    ShowOSD("Desktop " . CurrentDesktop)
}

MoveWindowToDesktop(target, *) {
    global CurrentDesktop, Desktops, AlwaysVisible

    hwnd := 0
    try {
        hwnd := WinExist("A")
    } catch {
        return
    }
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
        try {
            WinMinimize(hwnd)
        } catch {
            ; ignore
        }
        ShowOSD("Window -> Desktop " . target)
    }
}

MoveAndSwitch(target, *) {
    MoveWindowToDesktop(target)
    SwitchDesktop(target)
    ShowOSD("Move And Switch -> " . target)
}

; ==============================================================================
;  [Module] Status Bar
; ==============================================================================
CreateStatusBar() {
    global

    try {
        if IsSet(Bar_Gui) && IsObject(Bar_Gui)
            Bar_Gui.Destroy()
    } catch {
        ; ignore
    }

    ; Bar shown on Bar_MonitorIdx
    MonitorGet(Bar_MonitorIdx, &mL, &mT, &mR, &mB)
    barScreenWidth := mR - mL
    barX := mL
    barY := mT

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
    BaseStartMins := 0
    BaseEndMins   := 1439
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
    try {
        Bar_LeftText.Value := str
    } catch {
        return
    }
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

    try {
        Bar_RightText.Value := FormatTime(, "yyyy-MM-dd   HH:mm")
    } catch {
        ; ignore
    }

    NowTime   := A_Now
    TodayDate := FormatTime(NowTime, "yyyyMMdd")
    WDay      := A_WDay
    StartTS   := ""
    EndTS     := ""
    ForceFull := false

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
    } catch {
        ; ignore
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
    try {
        hwnd := WinExist("A")
    } catch {
        return
    }
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
        } catch {
            continue
        }
    }
    ShowOSD("Gathered " . count . " Windows")
}

; ==============================================================================
;  [Module] Smart Tiling (current monitor only)
; ==============================================================================
TileCurrentMonitor(*) {
    global Bar_Height, Bar_Visible, Bar_MonitorIdx

    ; 取光标所在显示器
    MouseGetPos(&mx, &my)
    targetMon := GetMonitorIndexAtPoint(mx, my)
    MonitorGetWorkArea(targetMon, &WL, &WT, &WR, &WB)

    ; 仅当 bar 在该显示器上才补偿高度
    if (Bar_Visible && targetMon == Bar_MonitorIdx)
        WT += Bar_Height + 5

    W := WR - WL
    H := WB - WT

    ; 仅平铺该显示器内的可见窗口
    windows := GetVisibleWindowsOnMonitor(targetMon)
    count := windows.Length
    if (count == 0) {
        ShowOSD("No Windows To Tile")
        return
    }
    ShowOSD("Tile [Mon " . targetMon . "]: " . count)

    PlaceWin(hwnd, x, y, w, h) {
        try {
            WinRestore(hwnd)
            WinMove(x, y, w, h, hwnd)
        } catch {
            ; ignore
        }
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
                cols  := count / 2
                itemW := W / cols
                itemH := H / 2
                for i, hwnd in windows {
                    idx := i - 1
                    r   := Floor(idx/cols)
                    c   := Mod(idx, cols)
                    PlaceWin(hwnd, WL + c*itemW, WT + r*itemH, itemW, itemH)
                }
            }
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
        } catch {
            continue
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
        } catch {
            ; ignore
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

; ==============================================================================
;  [Module] Window Snap (Alt + Arrows)
; ==============================================================================
SnapWindow(direction, *) {
    global Bar_Visible, Bar_Height, Bar_MonitorIdx
    hwnd := 0
    try {
        hwnd := WinExist("A")
    } catch {
        return
    }
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
    } catch {
        return
    }
}

; ==============================================================================
;  [Module] Layout Snapshot
; ==============================================================================
SaveLayout(*) {
    global LayoutSnapshot
    LayoutSnapshot := Map()
    for hwnd in GetVisibleWindow() {
        try {
            WinGetPos(&x, &y, &w, &h, hwnd)
            LayoutSnapshot[hwnd] := {x:x, y:y, w:w, h:h}
        } catch {
            continue
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
        } catch {
            continue
        }
    }
    ShowOSD("Layout Restored (" . n . ")")
}

; ==============================================================================
;  [Module] Clipboard / Vim / Terminal / Power
; ==============================================================================
OnClipboardChanged(dataType) {
    if (dataType != 1)
        return
    RecordClipboard()
}

RecordClipboard() {
    global LastClipContent, Path_OutputFile
    txt := ""
    try {
        txt := A_Clipboard
    } catch {
        return
    }
    if (Type(txt) != "String" || txt == "" || txt == LastClipContent)
        return
    LastClipContent := txt
    Content := "------------------------------------------------------------------------------------------------`r`n"
             . FormatTime(, "yyyy-MM-dd HH:mm:ss") . "`r`n" . txt . "`r`n`r`n"
    try {
        FileAppend(Content, Path_OutputFile, "UTF-8")
    } catch {
        ; ignore
    }
}

ToggleVimWindow() {
    global Vim_CurrentPID, Path_Vim, Path_OutputFile, Vim_X, Vim_Y
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
            WinMove(Vim_X, Vim_Y, , , "ahk_pid " . pid)
            WinActivate("ahk_pid " . pid)
        }
    } catch {
        ShowOSD("Vim Boot Failed")
    }
}

LaunchTerminal(*) {
    global Path_Terminal
    path := Explorer_GetPath()
    try {
        Run('"' . Path_Terminal . '"' . (path ? ' -d "' . path . '"' : ""))
    } catch {
        return
    }
}

OpenWithVim(*) {
    global Path_Vim
    targetPath := Explorer_GetSelection()
    if (targetPath == "") {
        ShowOSD("No File Selected")
        return
    }
    try {
        Run('"' . Path_Vim . '" "' . targetPath . '"')
    } catch {
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

; ==============================================================================
;  [Module] Theme Switching
; ==============================================================================
ApplyTheme(themeName, *) {
    IniWrite(themeName, ConfigFile, "Theme", "ActiveTheme")
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
    sectionMap := Map(
        "Color_Bg",          "Visual",
        "Color_Text",        "Visual",
        "Color_Active",      "Visual",
        "Color_Task",        "WorkTime",
        "Border_Drag_Color", "Border_Drag",
        "Border_Pin_Color",  "Border_Pin",
        "PM_Bg",             "PowerMenu",
        "PM_BtnShutdown",    "PowerMenu",
        "PM_BtnSleep",       "PowerMenu",
        "PM_BtnReboot",      "PowerMenu"
    )
    nameMap := Map(
        "PM_Bg",             "Bg",
        "PM_BtnShutdown",    "BtnShutdown",
        "PM_BtnSleep",       "BtnSleep",
        "PM_BtnReboot",      "BtnReboot",
        "Border_Drag_Color", "Color",
        "Border_Pin_Color",  "Color"
    )
    for key, val in palette {
        sec := sectionMap.Has(key) ? sectionMap[key] : "Visual"
        ini := nameMap.Has(key)    ? nameMap[key]    : key
        IniWrite(val, ConfigFile, sec, ini)
    }
    IniWrite("custom", ConfigFile, "Theme", "ActiveTheme")
    ShowOSD("Exported -> custom")
    Sleep(400)
    Reload()
}

; ==============================================================================
;  [Module] Misc / Helpers
; ==============================================================================
RestoreAndExit(*) {
    global Bar_Gui
    ShowOSD("Script Shutting Down ...")
    Sleep(500)
    PinBorder.RemoveAll()
    if IsObject(Bar_Gui)
        Bar_Gui.Destroy()
    for hwnd in WinGetList() {
        try {
            winClass := WinGetClass(hwnd)
            if (winClass != "Progman" && winClass != "Shell_TrayWnd")
                WinRestore(hwnd)
        } catch {
            continue
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
        } catch {
            continue
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
        } catch {
            return ""
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
        } catch {
            return ""
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
        } catch {
            return ""
        }
    }
    return ""
}

; ==============================================================================
;  [Module] Tray Icon
; ==============================================================================
SetupTrayIcon() {
    global Themes, ActiveTheme
    A_TrayMenu.Delete()
    A_TrayMenu.Add("Gather All Windows", GatherAllToCurrent)
    A_TrayMenu.Add("Toggle Status Bar",  ToggleBar)
    A_TrayMenu.Add("Save Layout",        SaveLayout)
    A_TrayMenu.Add("Restore Layout",     RestoreLayout)
    A_TrayMenu.Add()

    ; --- Theme Submenu ---
    themeMenu := Menu()
    themeMenu.Add("custom (use [Visual])", ApplyTheme.Bind("custom"))
    for name, _ in Themes
        themeMenu.Add(name, ApplyTheme.Bind(name))
    try {
        themeMenu.Check(ActiveTheme = "custom" ? "custom (use [Visual])" : ActiveTheme)
    } catch {
        ; ignore
    }
    A_TrayMenu.Add("Theme", themeMenu)
    A_TrayMenu.Add("Export Theme -> custom", ExportThemeToCustom)
    A_TrayMenu.Add()

    Loop DesktopCount {
        i := A_Index
        A_TrayMenu.Add("Switch to Desktop " . i, SwitchDesktop.Bind(i))
    }

    A_TrayMenu.Add()
    A_TrayMenu.Add("Reload Script",   (*) => Reload())
    A_TrayMenu.Add("Restore && Exit", RestoreAndExit)
	A_TrayMenu.Add("Open Config Folder", (*) => Run('explorer.exe "' . ConfigDir . '"'))

    A_IconTip := "WM Script - Desktop " . CurrentDesktop
}

; ==============================================================================
;  [Module] Mouse Drag / Resize  (with DragBorder)
; ==============================================================================
!LButton:: {
    MouseGetPos(,, &hwnd)
    if !hwnd
        return

    try {
        WinActivate(hwnd)
    } catch {
        return
    }

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
        WinGetPos(&winX, &winY, &winW, &winH, hwnd)
    } catch {
        return
    }

    DragBorder.Show()

    while GetKeyState("LButton", "P") {
        MouseGetPos(&curX, &curY)
        try {
            WinMove(winX + (curX - startX), winY + (curY - startY),,, hwnd)
        } catch {
            break
        }
        DragBorder.Update(hwnd)
    }

    DragBorder.Destroy()
}

!RButton:: {
    MouseGetPos(,, &hwnd)
    if !hwnd
        return
    if (WinGetMinMax(hwnd) == 1)
        return

    try {
        WinGetPos(&winX, &winY, &winW, &winH, hwnd)
    } catch {
        return
    }
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
            try {
                WinMove(nX, nY, nW, nH, hwnd)
            } catch {
                break
            }
            DragBorder.Update(hwnd)
        }
    }

    DragBorder.Destroy()
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
