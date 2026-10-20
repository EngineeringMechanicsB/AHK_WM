#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn

;==========================================================================
; ---- System Setup ----
;==========================================================================
SetWorkingDir(A_ScriptDir)
CoordMode("Mouse", "Screen")
SetWinDelay(0)
SetControlDelay(0)

try DllCall("User32.dll\SetProcessDpiAwarenessContext", "Ptr", -4, "Ptr")
catch
    try DllCall("User32.dll\SetProcessDPIAware")

A_IconTip := "AHK Launcher"

;==========================================================================
; ---- Globals ----
;==========================================================================
global ConfigDir  := EnvGet("USERPROFILE") . "\.config\AHK_Launcher"
global ConfigFile := ConfigDir . "\launcher.ini"

global ActiveTheme
global Color_Bg, Color_Text, Color_Active, Color_Accent, Color_Border, Color_Error
global Border_Enabled, Border_Thickness, Border_Opacity, Border_Radius
global WIN_W, WIN_H, TOP_RATIO
global WT_PATH
global HK := Map()
global LauncherBorder := ""          ; 持久 BorderFrame 实例
global TrackedLauncherHwnd := 0

;==========================================================================
; ---- Theme Presets ----
;==========================================================================
global Themes := Map(
    "nord",            Map("Color_Bg","2E3440","Color_Text","D8DEE9","Color_Active","88C0D0","Color_Accent","A3BE8C","Color_Border","88C0D0","Color_Error","BF616A"),
    "tokyonight",      Map("Color_Bg","1A1B26","Color_Text","C0CAF5","Color_Active","7AA2F7","Color_Accent","9ECE6A","Color_Border","7AA2F7","Color_Error","F7768E"),
    "dracula",         Map("Color_Bg","282A36","Color_Text","F8F8F2","Color_Active","BD93F9","Color_Accent","50FA7B","Color_Border","8BE9FD","Color_Error","FF5555"),
    "gruvbox",         Map("Color_Bg","282828","Color_Text","EBDBB2","Color_Active","83A598","Color_Accent","B8BB26","Color_Border","FABD2F","Color_Error","FB4934"),
    "monokai",         Map("Color_Bg","272822","Color_Text","F8F8F2","Color_Active","66D9EF","Color_Accent","A6E22E","Color_Border","FD971F","Color_Error","F92672"),
    "solarized-dark",  Map("Color_Bg","002B36","Color_Text","93A1A1","Color_Active","268BD2","Color_Accent","859900","Color_Border","2AA198","Color_Error","DC322F"),
    "solarized-light", Map("Color_Bg","FDF6E3","Color_Text","586E75","Color_Active","268BD2","Color_Accent","859900","Color_Border","2AA198","Color_Error","DC322F"),
    "catppuccin-mocha",Map("Color_Bg","1E1E2E","Color_Text","CDD6F4","Color_Active","89B4FA","Color_Accent","A6E3A1","Color_Border","CBA6F7","Color_Error","F38BA8"),
    "catppuccin-latte",Map("Color_Bg","EFF1F5","Color_Text","4C4F69","Color_Active","1E66F5","Color_Accent","40A02B","Color_Border","8839EF","Color_Error","D20F39"),
    "onedark",         Map("Color_Bg","282C34","Color_Text","ABB2BF","Color_Active","61AFEF","Color_Accent","98C379","Color_Border","C678DD","Color_Error","E06C75"),
    "ayu-dark",        Map("Color_Bg","0A0E14","Color_Text","B3B1AD","Color_Active","59C2FF","Color_Accent","C2D94C","Color_Border","FFB454","Color_Error","F07178"),
    "github-dark",     Map("Color_Bg","0D1117","Color_Text","C9D1D9","Color_Active","58A6FF","Color_Accent","3FB950","Color_Border","D2A8FF","Color_Error","F85149"),
    "rose-pine",       Map("Color_Bg","191724","Color_Text","E0DEF4","Color_Active","9CCFD8","Color_Accent","31748F","Color_Border","C4A7E7","Color_Error","EB6F92"),
    "everforest",      Map("Color_Bg","2D353B","Color_Text","D3C6AA","Color_Active","7FBBB3","Color_Accent","A7C080","Color_Border","D699B6","Color_Error","E67E80"),
    "kanagawa",        Map("Color_Bg","1F1F28","Color_Text","DCD7BA","Color_Active","7E9CD8","Color_Accent","98BB6C","Color_Border","957FB8","Color_Error","E82424"),
    "material-deep",   Map("Color_Bg","263238","Color_Text","EEFFFF","Color_Active","82AAFF","Color_Accent","C3E88D","Color_Border","C792EA","Color_Error","F07178"),
    "nightfox",        Map("Color_Bg","192330","Color_Text","CDCECF","Color_Active","719CD6","Color_Accent","81B29A","Color_Border","9D79D6","Color_Error","C94F6D"),
    "palenight",       Map("Color_Bg","292D3E","Color_Text","A6ACCD","Color_Active","82AAFF","Color_Accent","C3E88D","Color_Border","C792EA","Color_Error","F07178"),
    "horizon",         Map("Color_Bg","1C1E26","Color_Text","CBCED0","Color_Active","25B0BC","Color_Accent","09F7A0","Color_Border","B877DB","Color_Error","E95678"),
    "oxocarbon",       Map("Color_Bg","161616","Color_Text","F2F4F8","Color_Active","33B1FF","Color_Accent","42BE65","Color_Border","BE95FF","Color_Error","FF7EB6")
)

;==========================================================================
; ---- Bootstrap ----
;==========================================================================
LoadOrInitConfig()

Hotkey(HK["AppLauncher"], (*) => ToggleLauncher("Launcher",   "Launcher"))
Hotkey(HK["FileFinder"],  (*) => ToggleLauncher("FileFinder", "FileFinder"))
Hotkey(HK["WebSearch"],   (*) => ToggleLauncher("WebSearch",  "WebSearch"))

BuildTrayMenu()

;==========================================================================
; ============== Configuration: Load / Init / Helpers ==================
;==========================================================================

LoadOrInitConfig() {
    global

    if !DirExist(ConfigDir) {
        try DirCreate(ConfigDir)
        catch as e {
            MsgBox("Failed to create config directory:`n" . ConfigDir . "`n`n" . e.Message)
            ExitApp
        }
    }

    if !FileExist(ConfigFile)
        WriteDefaultConfig()

    ActiveTheme := IniRead(ConfigFile, "General", "ActiveTheme", "catppuccin-mocha")

    Color_Bg     := IniRead(ConfigFile, "Colors", "Background", "1E1E2E")
    Color_Text   := IniRead(ConfigFile, "Colors", "Text",       "CDD6F4")
    Color_Active := IniRead(ConfigFile, "Colors", "Active",     "89B4FA")
    Color_Accent := IniRead(ConfigFile, "Colors", "Accent",     "A6E3A1")
    Color_Border := IniRead(ConfigFile, "Colors", "Border",     "CBA6F7")
    Color_Error  := IniRead(ConfigFile, "Colors", "Error",      "F38BA8")

    WIN_W     := Integer(IniRead(ConfigFile, "Window", "Width",    "1200"))
    WIN_H     := Integer(IniRead(ConfigFile, "Window", "Height",   "820"))
    TOP_RATIO := Number(IniRead(ConfigFile, "Window", "TopRatio", "0.15"))

    Border_Enabled   := (StrLower(IniRead(ConfigFile, "Border", "Enabled", "on")) = "on")
    Border_Thickness := Integer(IniRead(ConfigFile, "Border", "Thickness", "3"))
    Border_Opacity   := Round(Integer(IniRead(ConfigFile, "Border", "Opacity", "90")) * 255 / 100)
    Border_Radius    := Integer(IniRead(ConfigFile, "Border", "Radius", "12"))

    WT_PATH := ExpandEnv(IniRead(ConfigFile, "Paths", "WindowsTerminal", "%LOCALAPPDATA%\Microsoft\WindowsApps\wt.exe"))

    HK := Map()
    hkDefaults := Map(
        "AppLauncher", "Alt+Space",
        "FileFinder",  "Alt+Shift+Space",
        "WebSearch",   "Alt+W"
    )
    for k, def in hkDefaults
        HK[k] := NormalizeHotkey(IniRead(ConfigFile, "Hotkeys", k, def))

    if (ActiveTheme != "custom" && Themes.Has(ActiveTheme)) {
        for key, val in Themes[ActiveTheme] {
            try %key% := val
        }
    }
}

WriteDefaultConfig() {
    DefaultIni := "
    (
;==========================================================================
; Launcher Configuration
;==========================================================================

[General]
; Theme: custom / nord / tokyonight / dracula / gruvbox / monokai
; / solarized-dark / solarized-light / catppuccin-mocha / catppuccin-latte
; / onedark / ayu-dark / github-dark / rose-pine / everforest / kanagawa
; / material-deep / nightfox / palenight / horizon / oxocarbon
ActiveTheme=catppuccin-mocha

[Colors]
Background=1E1E2E
Text=CDD6F4
Active=89B4FA
Accent=A6E3A1
Border=CBA6F7
Error=F38BA8

[Window]
Width=1200
Height=820
; Position: 0.0-1.0 (0.15 = 15% from top)
TopRatio=0.15

[Border]
; Show decorative border: on / off
Enabled=on
Thickness=3
; Opacity: 1-100
Opacity=90
; Corner radius in pixels (半径，非直径)
Radius=12

[Paths]
WindowsTerminal=%LOCALAPPDATA%\Microsoft\WindowsApps\wt.exe

[Hotkeys]
AppLauncher=Alt+Space
FileFinder=Alt+Shift+Space
WebSearch=Alt+W
    )"
    try FileAppend(DefaultIni, ConfigFile, "UTF-8")
    catch {
        MsgBox("Failed to create config file: " . e.Message)
        ExitApp
    }
}

ExpandEnv(s) {
    while RegExMatch(s, "%([^%]+)%", &m) {
        v := EnvGet(m[1])
        s := StrReplace(s, m[0], v)
    }
    return s
}

NormalizeHotkey(s) {
    s := Trim(s)
    if (s = "")
        return ""
    if RegExMatch(s, "^[\!\^\+\#<>\*~\$]")
        return s
    mods := "", keys := ""
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
                keys := p
        }
    }
    if (StrLen(keys) = 1)
        keys := StrLower(keys)
    return mods . keys
}

;==========================================================================
; ===================== Features: Border Overlay =======================
; 移植自参考脚本的 BorderFrame：纯 region 裁形 + 整窗着色（不用 TransColor），
; 透明度只在 __New 设置一次（避免重复设分层透明导致四角残线）。
; radius 按“半径”语义，内部 d := radius*2，与其他脚本一致。
;==========================================================================
class BorderFrame {
    Gui   := ""
    Color := ""
    LastW := -1, LastH := -1, LastT := -1, LastR := -1

    __New(color, opacity) {
        ; +E0x20 = WS_EX_TRANSPARENT：点击穿透；先移到屏外，避免初始闪烁
        g := Gui("-Caption +ToolWindow +E0x20 -DPIScale")
        g.BackColor := color
        g.Show("NoActivate x-3000 y-3000 w10 h10")
        try WinSetTransparent(opacity, g.Hwnd)   ; 只设这一次
        this.Gui   := g
        this.Color := color
    }

    SetColor(color) {
        if (this.Color = color)
            return
        try {
            this.Gui.BackColor := color
            WinRedraw(this.Gui.Hwnd)
        }
        this.Color := color
    }

    ; 摆到目标矩形并裁成空心边框；insertAfter=-1 → HWND_TOPMOST，盖在 WT 之上
    Place(x, y, w, h, thickness, radius) {
        if !IsObject(this.Gui)
            return
        t := Max(1, Round(thickness))
        w := Round(Max(t*2 + 1, w)), h := Round(Max(t*2 + 1, h))
        try DllCall("SetWindowPos", "Ptr", this.Gui.Hwnd, "Ptr", -1
            , "Int", Round(x), "Int", Round(y), "Int", w, "Int", h
            , "UInt", 0x10 | 0x40)   ; SWP_NOACTIVATE | SWP_SHOWWINDOW
        this._ApplyRegion(w, h, t, Max(0, Round(radius)))
    }

    _ApplyRegion(w, h, t, radius) {
        ; 几何不变就跳过重建
        if (w = this.LastW && h = this.LastH && t = this.LastT && radius = this.LastR)
            return
        this.LastW := w, this.LastH := h, this.LastT := t, this.LastR := radius

        d := radius * 2                       ; 半径 → 直径
        if (d > 0) {
            ; +1：CreateRoundRectRgn 右/下为开区间，补回末像素，消除直角残线
            outer := DllCall("Gdi32\CreateRoundRectRgn", "Int",0,"Int",0,"Int",w+1,"Int",h+1,"Int",d,"Int",d,"Ptr")
            id    := Max(0, d - t*2)          ; 内圆角，保持描边粗细均匀
            inner := DllCall("Gdi32\CreateRoundRectRgn", "Int",t,"Int",t,"Int",w-t+1,"Int",h-t+1,"Int",id,"Int",id,"Ptr")
        } else {
            outer := DllCall("Gdi32\CreateRectRgn", "Int",0,"Int",0,"Int",w,"Int",h,"Ptr")
            inner := DllCall("Gdi32\CreateRectRgn", "Int",t,"Int",t,"Int",w-t,"Int",h-t,"Ptr")
        }
        DllCall("Gdi32\CombineRgn", "Ptr",outer, "Ptr",outer, "Ptr",inner, "Int",4)  ; RGN_DIFF
        DllCall("Gdi32\DeleteObject", "Ptr", inner)
        ; SetWindowRgn 接管 outer 所有权，勿手动删除
        try DllCall("User32\SetWindowRgn", "Ptr", this.Gui.Hwnd, "Ptr", outer, "Int", 1)
    }

    Hide() {
        if IsObject(this.Gui)
            try DllCall("ShowWindow", "Ptr", this.Gui.Hwnd, "Int", 0)   ; SW_HIDE
    }

    Destroy() {
        if IsObject(this.Gui)
            try this.Gui.Destroy()
        this.Gui := ""
    }
}

;==========================================================================
; 取窗口“可视”外框（不含不可见拉伸边框与投影阴影）
; DWMWA_EXTENDED_FRAME_BOUNDS = 9
;==========================================================================
GetVisualRect(hwnd) {
    rect := Buffer(16, 0)
    hr := DllCall("dwmapi\DwmGetWindowAttribute", "Ptr", hwnd, "UInt", 9, "Ptr", rect, "UInt", 16, "Int")
    if (hr != 0) {
        WinGetPos(&x, &y, &w, &h, "ahk_id " hwnd)
        return { x: x, y: y, w: w, h: h }
    }
    l := NumGet(rect, 0, "Int"), t := NumGet(rect, 4, "Int")
    r := NumGet(rect, 8, "Int"), b := NumGet(rect, 12, "Int")
    return { x: l, y: t, w: r - l, h: b - t }
}

;==========================================================================
; ===================== Features: Launcher Toggle ======================
;==========================================================================

ToggleLauncher(profileName, tabTitle) {
    global WIN_W, WIN_H, TOP_RATIO, WT_PATH, Border_Enabled, TrackedLauncherHwnd

    matchTitle := tabTitle " ahk_exe WindowsTerminal.exe"

    ; 已打开 → 关闭并停止跟踪
    if hwndExist := WinExist(matchTitle) {
        HideLauncherBorder()
        WinClose("ahk_id " hwndExist)
        TrackedLauncherHwnd := 0
        SetTimer(UpdateLauncherBorder, 0)
        return
    }

    winId := "_" StrLower(profileName)
    cmd := Format('"{}" -w {} new-tab -p "{}"', WT_PATH, winId, profileName)
    try {
        Run(cmd, , "Hide")
    } catch {
        Run('cmd /c start "" wt -w ' winId ' new-tab -p "' profileName '"', , "Hide")
    }

    if !WinWait(matchTitle, , 3)
        return
    hwnd := WinGetID(matchTitle)

    MonitorGetWorkArea(MonitorGetPrimary(), &left, &top, &right, &bottom)
    sw := right - left, sh := bottom - top
    x  := left + (sw - WIN_W) // 2
    y  := top  + Integer(sh * TOP_RATIO)

    WinMove(x, y, WIN_W, WIN_H, "ahk_id " hwnd)
    WinActivate("ahk_id " hwnd)

    ; 定位完毕后立即绘制一次，再启动跟踪计时器
    TrackedLauncherHwnd := hwnd
    if Border_Enabled {
        Sleep(80)
        UpdateLauncherBorder()
    }
    SetTimer(UpdateLauncherBorder, 30)
}

UpdateLauncherBorder() {
    global TrackedLauncherHwnd, Border_Enabled, LauncherBorder
    global Border_Thickness, Border_Radius, Border_Opacity, Color_Border
    static lastX := "", lastY := "", lastW := "", lastH := ""

    hwnd := TrackedLauncherHwnd
    if !hwnd || !WinExist("ahk_id " hwnd) {
        HideLauncherBorder()
        TrackedLauncherHwnd := 0
        lastX := "", lastY := "", lastW := "", lastH := ""
        SetTimer(UpdateLauncherBorder, 0)
        return
    }
    if !Border_Enabled {
        HideLauncherBorder()
        return
    }

    vr := GetVisualRect(hwnd)
    if (vr.x != lastX || vr.y != lastY || vr.w != lastW || vr.h != lastH) {
        if !IsObject(LauncherBorder)
            LauncherBorder := BorderFrame(Color_Border, Border_Opacity)
        LauncherBorder.SetColor(Color_Border)
        LauncherBorder.Place(vr.x, vr.y, vr.w, vr.h, Border_Thickness, Border_Radius)
        lastX := vr.x, lastY := vr.y, lastW := vr.w, lastH := vr.h
    }
}

HideLauncherBorder() {
    global LauncherBorder
    if IsObject(LauncherBorder)
        LauncherBorder.Hide()
}

;==========================================================================
; ======================= Features: Theme Apply ========================
;==========================================================================

ApplyTheme(themeName, *) {
    IniWrite(themeName, ConfigFile, "General", "ActiveTheme")
    Sleep(200)
    Reload()
}

;==========================================================================
; ========================== Tray Menu (UI) ============================
;==========================================================================

BuildTrayMenu() {
    global ActiveTheme, ConfigDir, Themes

    tm := A_TrayMenu
    try tm.Delete()

    themeMenu := Menu()
    themeMenu.Add("custom (use [Colors])", ApplyTheme.Bind("custom"))
    themeMenu.Add()
    for name, _ in Themes
        themeMenu.Add(name, ApplyTheme.Bind(name))
    try themeMenu.Check(ActiveTheme = "custom" ? "custom (use [Colors])" : ActiveTheme)

    tm.Add("Theme", themeMenu)
    tm.Add("Reload", (*) => Reload())
    tm.Add("Open Config Folder", (*) => Run('explorer.exe "' . ConfigDir . '"'))
    tm.Add()
    tm.Add("Exit", (*) => ExitApp())
}
