#Requires AutoHotkey v2.0
#SingleInstance Force
#WinActivateForce
Persistent

; ==============================================================================
; 📂 TABLE OF CONTENTS
; ==============================================================================
;
; 1.  Environment & Global Directives
; 2.  Constants & Shared State
;   ├─ Theme/Colors · Status Bar · Pie Menu · Paths/Editor · OSD
;   ├─ Borders · Pinning · Tiling/Snapping · Virtual Desktops · 22 Built-in Themes
;   └─ GUI Rounding · WinSelect · Window Snapping
; 3.  Utility Functions
;   ├─ Math · Color/Gradient Parsing · GDI Bitmaps · Rounding · Logging
;   ├─ Window Exclusion · Layout Rules · Hotkey Formatting · Snapshots
;   └─ Reload Persistence (save/restore desktop layout)
; 4.  Startup Sequence
; 5.  Hotkey Registration
; 6.  Configuration Template (Default INI)
; 7.  Configuration Loading & Parsing
; 8.  Common GUI
;   ├─ Help Menu · Welcome Screen · OSD · 8-Dir Button Templates
;   └─ Window-Select Mode (WinSelect)
; 9.  Border System
;   ├─ HollowFrame · DragBorder · PinBorder
;   └─ All-Window Borders Mode
; 10. Window Actions (close, minimize, maximize, toggle-top, transparency)
; 11. Pie Menu (radial menu)
; 12. Virtual Desktops
;   ├─ Switch · Move · MoveAndSwitch
;   └─ Layout Save/Restore · Reload Persistence
; 13. Status Bar
;   ├─ BarInstance class · Gradient/bg/tx rendering · Per-element config
;   └─ System widgets: WiFi · Battery · Volume · Disk · Memory · CPU
; 14. Smart Tiling (TileSmart)
; 15. Window Snapping
; 16. Drag Move / Resize & Directional Snap
; 17. WTM Tiling Mode (hyprland-like)
; 18. All-Window Borders Mode
; 19. Enhanced Window-Select Mode (WinSelect)
; 20. Clipboard / Editor / Terminal / Power Menu
; 21. Theme Switching
; 22. Tray Menu & Exit
; 23. External 8-Direction Button Scripts
;
; ==============================================================================
; 1. Environment & Global Directives / 环境与全局指令
; ==============================================================================

global WM_Version := "2.13.0"
global FontName

SetWorkingDir(A_ScriptDir)
CoordMode("Mouse", "Screen")
SetTitleMatchMode(2)
SetWinDelay(0)
SetControlDelay(0)

; ==============================================================================
; 2. Constants & Shared State / 常量与共享状态
; ==============================================================================

; ---- Theme & UI colors / 主题颜色 ----
global Color_Bg, Color_Text, Color_Active, Color_Task
global Border_Drag_Color, Border_Pin_Color
global PM_Bg, PM_BtnShutdown, PM_BtnSleep, PM_BtnReboot

; ---- Status-bar state / 状态栏 ----
global Bar_Height, Bar_Transparent, Bar_FontSize
global Bar_MonitorIdx := 1
global Bar_Visible    := true
global Bar_AutoHide   := false
global Bar_FsHidden   := false
global Bar_ShownState := true
global Bar_Rounded    := "off"
global Bar_Radius     := 10
global Bar_CornerMode := "bottom"
global Bar_MarginLeft  := 0
global Bar_MarginRight := 0
global Bars := []
global Bar_Cfg := Map()
global Bar_ExternalData := Map()
global Bar_ExternalSlots := Map()

; ---- Pie-menu parameters / 功能环 ----
global Pie_Size, Pie_Radius, Pie_CenterZone
global Pie_FontSize, Pie_FontSizeActive, Pie_Transparent
global Pie_Config

; ---- Paths & editor / 路径 ----
global Path_Button, Path_Output, Path_OutputFile, Path_Vim, Path_Terminal
global Vim_X, Vim_Y, Vim_Width, Vim_Height
global Vim_CurrentPID := 0

; ---- OSD & work-time / OSD工时 ----
global OSD_Height, OSD_Transparent, OSD_FontSize
global Work_Start, Work_End, Work_WeekendBar, Work_Mode, Work_TaskTimes
global ActiveTheme

; ---- Unified border model / 边框模型 ----
global Border_Enable      := "on"
global Border_Mode        := "full"
global Border_FocusColor  := "A020F0"
global Border_UnfocusColor:= "555555"
global Border_Thickness   := 2
global Border_Offset      := 0
global Border_OffsetTop   := 1
global Border_Opacity     := 200
global Border_Rounded     := "on"
global Border_Radius      := 10
global Border_Gap         := 10
global Border_SizeStep    := 3

; ---- Pinned-window indicator / 置顶指示 ----
global Border_Pin_Thickness, Border_Pin_Offset, Border_Pin_OffsetTop, Border_Pin_Transparent
global Border_Pin_Mode  := "top"
global Border_Pin_Rounded, Border_Pin_Radius

; ---- Shared border refresh interval / 刷新间隔 ----
global Border_RefreshMs := 10
global TransparencyStep := 20
global PauseOnFullscreenMode := "bar"

; ---- Tiling & window exclusion / 平铺排除 ----
global CurrentTileGap := 0
global Tile_Gap        := 15
global LayoutRules     := Map()
global Excl_Titles     := []
global Excl_Classes    := []
global Excl_Processes  := []
global Excl_NeedField  := 0
global Tile_IncludeAlwaysOnTop := true
global TileBound_L := 0, TileBound_T := 0, TileBound_R := 0, TileBound_B := 0
global TileBoundSet := false
global TileSink := 0
global SlotTableCache := Map()
global WTM_Gap    := 10
global WTM_AnimMs := 0
global WTM_Debug  := false
global WTM_ResizeStep := 20
global WTM_ResizeRules    := Map()
global WTM_LayoutOverride := false
global WTM_ScrollDesktops := Map()

; ---- GUI rounding / GUI圆角 ----
global GUI_Rounded     := "on"
global GUI_CornerRadius := 12
global Help_Rounded, Help_Radius, PM_Rounded, PM_Radius
global OSD_Rounded, OSD_Radius

; ---- Window snapping / 窗口吸附 ----
global Snap_Enable   := true
global Snap_Distance := 12
global Snap_Release  := 8

; ---- Deferred startup warning / 启动警告 ----
global PathWarning := ""

; ---- Help & power-menu sizing / 菜单尺寸 ----
global Help_FontSize := 10, Help_Width := 620, Help_Height := 0, Help_Opacity := 255
global PM_FontSize := 12, PM_Width := 500, PM_Height := 160, PM_Opacity := 255

; ---- Virtual desktops / 虚拟桌面 ----
global Desktop_HideMethod := "minimize"
global DesktopFocus := Map()
global CurrentDesktop  := 1
global DesktopCount    := 9
global Desktops        := Map()
global AlwaysVisible   := Map()

global DesktopIsSwitching := false

; ---- Other shared state / 共享状态 ----
global HelpGuiObj    := ""
global PowerMenuObj  := ""
global ConfigDir  := EnvGet("USERPROFILE") . "\.config\AHK_WM"
global ConfigFile := ConfigDir . "\wm_config.ini"
global ExcludeFile := ConfigDir . "\exclude.ini"
global LastClipContent := ""
; ---- Clipboard module settings / 剪贴板设置 ([Clipboard]) ----
global Clip_MaxChars     := 100000
global Clip_ExcludeProcs := []
global Clip_LogBinary    := true

global HK := Map()

; ---- Window-select mode settings / 窗口选择 ----
global WS_Scale := 0.85
global WS_Letters := "ASDFGHJKLQWERTYUIOPZXCVBNM"
global WS_SizeMap := Map()
global WS_BarColor := "", WS_TextColor := ""
global WS_BarHeight := 28, WS_BarWidth := 0, WS_OffsetY := 8
global WS_FontSize := 14, WS_Opacity := 217
global WS_Rounded := "on", WS_Radius := 10, WS_CornerMode := "top"
global WS_Timeout := 12

; ---- Window-select sidebar settings / 侧边栏 ----
global WS_Sidebar_FontSize := 14
global WS_Sidebar_Width := 80
global WS_Sidebar_Position := "left"
global WS_Sidebar_OffsetX := 10
global WS_Sidebar_OffsetY := 0

; ---- Pie-menu direction symbols / 方向符号 ----
Pie_Config := Map(
    "Top","↑", "TopRight","↗", "Right","→", "DownRight","↘",
    "Down","↓", "DownLeft","↙", "Left","←", "TopLeft","↖", "Center","●"
)

; ---- Built-in themes / 内置主题 ----
global Themes := Map(
    "nord",             Map("Color_Bg","2E3440","Color_Text","D8DEE9","Color_Active","88C0D0","Color_Task","A3BE8C","Border_Drag_Color","88C0D0","Border_Pin_Color","BF616A","PM_Bg","3B4252","PM_BtnShutdown","BF616A","PM_BtnSleep","5E81AC","PM_BtnReboot","D08770","WTM_BorderFocusColor","88C0D0","WTM_BorderUnfocusColor","4C566A"),
    "tokyonight",       Map("Color_Bg","1A1B26","Color_Text","C0CAF5","Color_Active","7AA2F7","Color_Task","9ECE6A","Border_Drag_Color","7AA2F7","Border_Pin_Color","F7768E","PM_Bg","24283B","PM_BtnShutdown","F7768E","PM_BtnSleep","7AA2F7","PM_BtnReboot","E0AF68","WTM_BorderFocusColor","7AA2F7","WTM_BorderUnfocusColor","414868"),
    "dracula",          Map("Color_Bg","282A36","Color_Text","F8F8F2","Color_Active","BD93F9","Color_Task","50FA7B","Border_Drag_Color","BD93F9","Border_Pin_Color","FF5555","PM_Bg","44475A","PM_BtnShutdown","FF5555","PM_BtnSleep","6272A4","PM_BtnReboot","FFB86C","WTM_BorderFocusColor","BD93F9","WTM_BorderUnfocusColor","44475A"),
    "gruvbox",          Map("Color_Bg","282828","Color_Text","EBDBB2","Color_Active","FABD2F","Color_Task","B8BB26","Border_Drag_Color","FABD2F","Border_Pin_Color","FB4934","PM_Bg","3C3836","PM_BtnShutdown","FB4934","PM_BtnSleep","458588","PM_BtnReboot","FE8019","WTM_BorderFocusColor","FABD2F","WTM_BorderUnfocusColor","504945"),
    "monokai",          Map("Color_Bg","272822","Color_Text","F8F8F2","Color_Active","A6E22E","Color_Task","FD971F","Border_Drag_Color","A6E22E","Border_Pin_Color","F92672","PM_Bg","3E3D32","PM_BtnShutdown","F92672","PM_BtnSleep","A6E22E","PM_BtnReboot","FD971F","WTM_BorderFocusColor","A6E22E","WTM_BorderUnfocusColor","49483E"),
    "solarized-dark",   Map("Color_Bg","002B36","Color_Text","839496","Color_Active","268BD2","Color_Task","859900","Border_Drag_Color","268BD2","Border_Pin_Color","DC322F","PM_Bg","073642","PM_BtnShutdown","DC322F","PM_BtnSleep","268BD2","PM_BtnReboot","CB4B16","WTM_BorderFocusColor","268BD2","WTM_BorderUnfocusColor","586E75"),
    "solarized-light",  Map("Color_Bg","FDF6E3","Color_Text","657B83","Color_Active","268BD2","Color_Task","859900","Border_Drag_Color","268BD2","Border_Pin_Color","DC322F","PM_Bg","EEE8D5","PM_BtnShutdown","DC322F","PM_BtnSleep","268BD2","PM_BtnReboot","CB4B16","WTM_BorderFocusColor","268BD2","WTM_BorderUnfocusColor","93A1A1"),
    "catppuccin-mocha", Map("Color_Bg","1E1E2E","Color_Text","CDD6F4","Color_Active","CBA6F7","Color_Task","A6E3A1","Border_Drag_Color","89B4FA","Border_Pin_Color","F38BA8","PM_Bg","313244","PM_BtnShutdown","F38BA8","PM_BtnSleep","89B4FA","PM_BtnReboot","FAB387","WTM_BorderFocusColor","CBA6F7","WTM_BorderUnfocusColor","45475A"),
    "catppuccin-latte", Map("Color_Bg","EFF1F5","Color_Text","4C4F69","Color_Active","8839EF","Color_Task","40A02B","Border_Drag_Color","1E66F5","Border_Pin_Color","D20F39","PM_Bg","E6E9EF","PM_BtnShutdown","D20F39","PM_BtnSleep","1E66F5","PM_BtnReboot","FE640B","WTM_BorderFocusColor","8839EF","WTM_BorderUnfocusColor","ACB0BE"),
    "onedark",          Map("Color_Bg","282C34","Color_Text","ABB2BF","Color_Active","61AFEF","Color_Task","98C379","Border_Drag_Color","56B6C2","Border_Pin_Color","E06C75","PM_Bg","3E4452","PM_BtnShutdown","E06C75","PM_BtnSleep","61AFEF","PM_BtnReboot","D19A66","WTM_BorderFocusColor","61AFEF","WTM_BorderUnfocusColor","4B5263"),
    "ayu-dark",         Map("Color_Bg","0A0E14","Color_Text","B3B1AD","Color_Active","FFB454","Color_Task","C2D94C","Border_Drag_Color","59C2FF","Border_Pin_Color","F07178","PM_Bg","131721","PM_BtnShutdown","F07178","PM_BtnSleep","59C2FF","PM_BtnReboot","FF8F40","WTM_BorderFocusColor","FFB454","WTM_BorderUnfocusColor","3D424D"),
    "github-dark",      Map("Color_Bg","0D1117","Color_Text","C9D1D9","Color_Active","58A6FF","Color_Task","3FB950","Border_Drag_Color","58A6FF","Border_Pin_Color","F85149","PM_Bg","161B22","PM_BtnShutdown","F85149","PM_BtnSleep","58A6FF","PM_BtnReboot","D29922","WTM_BorderFocusColor","58A6FF","WTM_BorderUnfocusColor","30363D"),
    "rose-pine",        Map("Color_Bg","191724","Color_Text","E0DEF4","Color_Active","C4A7E7","Color_Task","9CCFD8","Border_Drag_Color","C4A7E7","Border_Pin_Color","EB6F92","PM_Bg","1F1D2E","PM_BtnShutdown","EB6F92","PM_BtnSleep","C4A7E7","PM_BtnReboot","F6C177","WTM_BorderFocusColor","C4A7E7","WTM_BorderUnfocusColor","26233A"),
    "everforest",       Map("Color_Bg","2D353B","Color_Text","D3C6AA","Color_Active","A7C080","Color_Task","DBBC7F","Border_Drag_Color","A7C080","Border_Pin_Color","E67E80","PM_Bg","374145","PM_BtnShutdown","E67E80","PM_BtnSleep","A7C080","PM_BtnReboot","E69875","WTM_BorderFocusColor","A7C080","WTM_BorderUnfocusColor","4F585E"),
    "kanagawa",         Map("Color_Bg","1F1F28","Color_Text","DCD7BA","Color_Active","7E9CD8","Color_Task","98BB6C","Border_Drag_Color","7E9CD8","Border_Pin_Color","E46876","PM_Bg","2A2A37","PM_BtnShutdown","E46876","PM_BtnSleep","7E9CD8","PM_BtnReboot","FFA066","WTM_BorderFocusColor","7E9CD8","WTM_BorderUnfocusColor","363646"),
    "material-deep",    Map("Color_Bg","263238","Color_Text","EEFFFF","Color_Active","82AAFF","Color_Task","C3E88D","Border_Drag_Color","82AAFF","Border_Pin_Color","F07178","PM_Bg","37474F","PM_BtnShutdown","F07178","PM_BtnSleep","82AAFF","PM_BtnReboot","F78C6C","WTM_BorderFocusColor","82AAFF","WTM_BorderUnfocusColor","546E7A"),
    "nightfox",         Map("Color_Bg","192330","Color_Text","CDCECF","Color_Active","719CD6","Color_Task","81B29A","Border_Drag_Color","719CD6","Border_Pin_Color","C94F6D","PM_Bg","212E3F","PM_BtnShutdown","C94F6D","PM_BtnSleep","719CD6","PM_BtnReboot","F4A261","WTM_BorderFocusColor","719CD6","WTM_BorderUnfocusColor","39506D"),
    "palenight",        Map("Color_Bg","292D3E","Color_Text","A6ACCD","Color_Active","82AAFF","Color_Task","C3E88D","Border_Drag_Color","82AAFF","Border_Pin_Color","FF5370","PM_Bg","343A4F","PM_BtnShutdown","FF5370","PM_BtnSleep","82AAFF","PM_BtnReboot","F78C6C","WTM_BorderFocusColor","82AAFF","WTM_BorderUnfocusColor","444A60"),
    "horizon",          Map("Color_Bg","1C1E26","Color_Text","CBCED0","Color_Active","E95678","Color_Task","29D398","Border_Drag_Color","E95678","Border_Pin_Color","E95678","PM_Bg","232530","PM_BtnShutdown","E95678","PM_BtnSleep","E95678","PM_BtnReboot","FAB795","WTM_BorderFocusColor","E95678","WTM_BorderUnfocusColor","3D4055"),
    "oxocarbon",        Map("Color_Bg","161616","Color_Text","F2F4F8","Color_Active","82CFFF","Color_Task","42BE65","Border_Drag_Color","82CFFF","Border_Pin_Color","FF7EB6","PM_Bg","262626","PM_BtnShutdown","FF7EB6","PM_BtnSleep","82CFFF","PM_BtnReboot","BE95FF","WTM_BorderFocusColor","82CFFF","WTM_BorderUnfocusColor","393939")
)

; ---- Theme key normalization (v2.8: per-component) / 主题补全 ----
for _tname, _tmap in Themes {
    if !_tmap.Has("Border_FocusColor")
        _tmap["Border_FocusColor"] := _tmap.Has("WTM_BorderFocusColor")
            ? _tmap["WTM_BorderFocusColor"]
            : (_tmap.Has("Border_Drag_Color") ? _tmap["Border_Drag_Color"] : "A020F0")
    if !_tmap.Has("Border_UnfocusColor")
        _tmap["Border_UnfocusColor"] := _tmap.Has("WTM_BorderUnfocusColor")
            ? _tmap["WTM_BorderUnfocusColor"] : "555555"
    if !_tmap.Has("Color_BorderUnfocus")
        _tmap["Color_BorderUnfocus"] := _tmap.Has("WTM_BorderUnfocusColor")
            ? _tmap["WTM_BorderUnfocusColor"] : "555555"

}

; ==============================================================================
; 3. Utility Functions / 通用工具函数
; ==============================================================================

; ---- Pct2Alpha / 百分比 ----
Pct2Alpha(p) => Round(Max(0, Min(100, p+0)) * 255 / 100)

; ---- GetPrimaryDim / 主屏尺寸 ----
GetPrimaryDim(&pw, &ph) {
    MonitorGetWorkArea(MonitorGetPrimary(), &l, &t, &r, &b)
    pw := r - l, ph := b - t
}

; ---- Pct2PxH / 转高度 ----
Pct2PxH(p)   {
    GetPrimaryDim(&pw, &ph)
    return Round(p * ph / 100)
}

; ---- Pct2PxW / 转宽度 ----
Pct2PxW(p)   {
    GetPrimaryDim(&pw, &ph)
    return Round(p * pw / 100)
}

; ---- Pct2PxMin / 转短边 ----
Pct2PxMin(p) {
    GetPrimaryDim(&pw, &ph)
    return Round(p * Min(pw, ph) / 100)
}

; ---- Pct2Border / 转边框 ----
Pct2Border(p) => Round(Max(0, Min(100, p+0)) * 20 / 100)

; ---- DWM frame-gap compensation / DWM补偿 ----
GetDWMGapCompensation(hwnds) {
    for _hw in hwnds {
        WinGetPos(&_wx, &_wy, &_ww, &_wh, _hw)
        if GetWindowVisualRect(_hw, &_vx, &_vy, &_vw, &_vh)
            return (_wx - _vx) * 2
    }
    return 0
}

; ---- SafeInt / 整数解析 ----
SafeInt(val, def := 0) {
    val := Trim(val "")
    if (val = "")
        return def
    if IsInteger(val)
        return Integer(val)
    if IsNumber(val)
        return Round(val + 0)
    return def
}

; ---- SplitEscaped / 转义拆分 ----
SplitEscaped(str, delim) {
    out := [], buf := "", i := 1
    while (i <= StrLen(str)) {
        c := SubStr(str, i, 1)
        if (c = "\" && i < StrLen(str)) {
            buf .= SubStr(str, i + 1, 1), i += 2
        } else if (c = delim) {
            out.Push(buf), buf := "", i++
        } else {
            buf .= c, i++
        }
    }
    out.Push(buf)
    return out
}

; ---- UnescapeSpaces / 转义空格还原 ----
UnescapeSpaces(str) {
    result := "", i := 1
    while (i <= StrLen(str)) {
        c := SubStr(str, i, 1)
        if (c = "\" && i < StrLen(str)) {
            next := SubStr(str, i + 1, 1)
            if (next = "s")
                result .= " ", i += 2
            else if (next = "\")
                result .= "\", i += 2
            else
                result .= c, i++
        } else {
            result .= c, i++
        }
    }
    return result
}

; ---- ParseColor (supports gradient: c1,c2,...) / 颜色解析 ----
ParseColor(cstr) {
    cstr := Trim(cstr)
    if (cstr = "")
        return {isGrad:false, first:"", colors:[]}
    cstr := RegExReplace(cstr, "i)^#", "")
    parts := StrSplit(cstr, ",")
    colors := []
    for p in parts {
        p := Trim(p)
        p := RegExReplace(p, "i)^#", "")
        if (p != "")
            colors.Push(p)
    }
    if (colors.Length = 0)
        return {isGrad:false, first:"", colors:[]}
    return {isGrad: colors.Length > 1, first: colors[1], colors: colors}
}
; ---- C1 (first color) / 取首色 ----
C1(raw, def := "000000") {
    pc := ParseColor(raw)
    return (pc.first != "") ? pc.first : def
}

; ---- GDI helpers ----
RgnRoundRect(w, h, r) {
    d := Max(1, r * 2)
    return DllCall("Gdi32\CreateRoundRectRgn"
        , "Int",0,"Int",0,"Int",w+1,"Int",h+1,"Int",d,"Int",d,"Ptr")
}
BgrFromRgb(hex) => ((hex & 0xFF) << 16) | (hex & 0xFF00) | (hex >> 16)
ScrBitmap(w, h) {
    scrDC := DllCall("Gdi32\CreateDC", "Str","DISPLAY", "Ptr",0, "Ptr",0, "Ptr",0, "Ptr")
    hBM := DllCall("Gdi32\CreateCompatibleBitmap", "Ptr",scrDC, "Int",w,"Int",h,"Ptr")
    DllCall("Gdi32\DeleteDC", "Ptr",scrDC)
    return hBM
}
MakeFont(fh, name := FontName) {
    return DllCall("Gdi32\CreateFontW"
        , "Int",fh, "Int",0, "Int",0, "Int",0, "Int",700
        , "Int",0, "Int",0, "Int",0, "Int",0, "Int",0
        , "Int",5, "Int",0, "Int",0, "Str",name, "Ptr")
}
RoundClipBM(hBM, w, h, r, bgColor := "") {
    hOut := ScrBitmap(w, h)
    if !hOut
        return hBM
    dcD := DllCall("Gdi32\CreateCompatibleDC", "Ptr",0, "Ptr")
    hOldD := DllCall("Gdi32\SelectObject", "Ptr",dcD, "Ptr",hOut, "Ptr")
    if (bgColor != "") {
        rc := Buffer(16, 0)
        NumPut("Int", 0, "Int", 0, "Int", w, "Int", h, rc)
        bgVal := Integer("0x" bgColor)
        bgRef := BgrFromRgb(bgVal)
        hBgBrush := DllCall("Gdi32\CreateSolidBrush", "UInt", bgRef, "Ptr")
        DllCall("User32\FillRect", "Ptr", dcD, "Ptr", rc, "Ptr", hBgBrush)
        DllCall("Gdi32\DeleteObject", "Ptr", hBgBrush)
    }
    hRgn := RgnRoundRect(w, h, r)
    DllCall("Gdi32\SelectClipRgn", "Ptr",dcD, "Ptr",hRgn)
    dcS := DllCall("Gdi32\CreateCompatibleDC", "Ptr",0, "Ptr")
    hOldS := DllCall("Gdi32\SelectObject", "Ptr",dcS, "Ptr",hBM, "Ptr")
    DllCall("Gdi32\BitBlt", "Ptr",dcD, "Int",0,"Int",0,"Int",w,"Int",h
        , "Ptr",dcS, "Int",0,"Int",0, "UInt",0xCC0020)
    DllCall("Gdi32\SelectObject", "Ptr",dcS, "Ptr",hOldS, "Ptr")
    DllCall("Gdi32\DeleteDC", "Ptr",dcS)
    DllCall("Gdi32\SelectClipRgn", "Ptr",dcD, "Ptr",0)
    DllCall("Gdi32\DeleteObject", "Ptr",hRgn)
    DllCall("Gdi32\SelectObject", "Ptr",dcD, "Ptr",hOldD, "Ptr")
    DllCall("Gdi32\DeleteDC", "Ptr",dcD)
    DllCall("Gdi32\DeleteObject", "Ptr",hBM)
    return hOut
}

; ---- MakeGradientBM / 统一渐变位图（含可选圆角）----
MakeGradientBM(w, h, colors, rounded := "off", radius := 0, fillColor := "", bgBM := 0, bgOffX := 0, bgOffY := 0) {
    global Color_Bg, Color_Active
    if (w < 2 || h < 2)
        return 0
    useColors := colors.Length > 0 ? colors : [C1(Color_Active)]
    if (useColors.Length = 1)
        useColors.Push(useColors[1])
    hGrad := CreateGradient(w, h, 0, useColors*)
    if !(hGrad && rounded = "on")
        return hGrad
    r := radius > 0 ? radius : Max(4, Min(w, h) // 6)
    hOut := ScrBitmap(w, h)
    if !hOut {
        DllCall("Gdi32\DeleteObject", "Ptr", hGrad)
        return 0
    }
    dcD := DllCall("Gdi32\CreateCompatibleDC", "Ptr", 0, "Ptr")
    hOldD := DllCall("Gdi32\SelectObject", "Ptr", dcD, "Ptr", hOut, "Ptr")
    if (fillColor != "") {
        rc := Buffer(16, 0)
        NumPut("Int", 0, "Int", 0, "Int", w, "Int", h, rc)
        bgVal := Integer("0x" fillColor)
        hBgBr := DllCall("Gdi32\CreateSolidBrush", "UInt", BgrFromRgb(bgVal), "Ptr")
        DllCall("User32\FillRect", "Ptr", dcD, "Ptr", rc, "Ptr", hBgBr)
        DllCall("Gdi32\DeleteObject", "Ptr", hBgBr)
    } else if (bgBM != 0) {
        dcBg := DllCall("Gdi32\CreateCompatibleDC", "Ptr", 0, "Ptr")
        hOldBg := DllCall("Gdi32\SelectObject", "Ptr", dcBg, "Ptr", bgBM, "Ptr")
        DllCall("Gdi32\BitBlt", "Ptr", dcD, "Int", 0, "Int", 0, "Int", w, "Int", h
            , "Ptr", dcBg, "Int", bgOffX, "Int", bgOffY, "UInt", 0xCC0020)
        DllCall("Gdi32\SelectObject", "Ptr", dcBg, "Ptr", hOldBg, "Ptr")
        DllCall("Gdi32\DeleteDC", "Ptr", dcBg)
    } else {
        rc := Buffer(16, 0)
        NumPut("Int", 0, "Int", 0, "Int", w, "Int", h, rc)
        bgVal := Integer("0x" C1(Color_Bg))
        hBgBr := DllCall("Gdi32\CreateSolidBrush", "UInt", BgrFromRgb(bgVal), "Ptr")
        DllCall("User32\FillRect", "Ptr", dcD, "Ptr", rc, "Ptr", hBgBr)
        DllCall("Gdi32\DeleteObject", "Ptr", hBgBr)
    }
    hRgn := RgnRoundRect(w, h, r)
    DllCall("Gdi32\SelectClipRgn", "Ptr", dcD, "Ptr", hRgn)
    dcS := DllCall("Gdi32\CreateCompatibleDC", "Ptr", 0, "Ptr")
    hOldS := DllCall("Gdi32\SelectObject", "Ptr", dcS, "Ptr", hGrad, "Ptr")
    DllCall("Gdi32\BitBlt", "Ptr", dcD, "Int", 0, "Int", 0, "Int", w, "Int", h
        , "Ptr", dcS, "Int", 0, "Int", 0, "UInt", 0xCC0020)
    DllCall("Gdi32\SelectObject", "Ptr", dcS, "Ptr", hOldS, "Ptr")
    DllCall("Gdi32\DeleteDC", "Ptr", dcS)
    DllCall("Gdi32\SelectClipRgn", "Ptr", dcD, "Ptr", 0)
    DllCall("Gdi32\DeleteObject", "Ptr", hRgn)
    DllCall("Gdi32\SelectObject", "Ptr", dcD, "Ptr", hOldD, "Ptr")
    DllCall("Gdi32\DeleteDC", "Ptr", dcD)
    DllCall("Gdi32\DeleteObject", "Ptr", hGrad)
    return hOut
}

; ---- CreateGradient / 渐变位图 ----
CreateGradient(W, H, V := 0, Colors*) {
    N := Colors.Length
    if (N < 1)
        return 0
    if (N = 1) {
        Colors.Push(Colors[1])
        N := 2
    }
    X := V ? W : 0
    Y := V ? 0 : H
    xOFF := X ? 0 : Ceil(W / (N - 1))
    yOFF := Y ? 0 : Ceil(H / (N - 1))
    VERT := Buffer(N * 16, 0)
    MESH := Buffer(N * 8, 0)
    Loop N {
        if V
            X := (X = 0) ? W : 0
        else
            Y := (Y = 0) ? H : 0
        cVal := Integer("0x" Colors[A_Index])
        col := Format("{:06X}", cVal & 0xFFFFFF)
        r := Integer("0x" SubStr(col, 1, 2)) * 0x101
        g := Integer("0x" SubStr(col, 3, 2)) * 0x101
        b := Integer("0x" SubStr(col, 5, 2)) * 0x101
        colorVal := (0xFF00 << 48) | (b << 32) | (g << 16) | r
        NumPut("Int", X, "Int", Y, "Int64", colorVal, VERT, (A_Index - 1) * 16)
        NumPut("Int", A_Index - 1, "Int", A_Index, MESH, (A_Index - 1) * 8)
        if V
            Y += yOFF
        else
            X += xOFF
    }
    hSeed := DllCall("Gdi32.dll\CreateBitmap", "Int", 1, "Int", 1, "Int", 0x1, "Int", 32, "PtrP", 0, "Ptr")
    hBM := DllCall("User32.dll\CopyImage", "Ptr", hSeed, "Int", 0x0, "Int", W, "Int", H, "Int", 0x0008, "Ptr")
    DllCall("Gdi32.dll\DeleteObject", "Ptr", hSeed)
    mDC := DllCall("Gdi32.dll\CreateCompatibleDC", "Ptr", 0, "Ptr")
    DllCall("Gdi32.dll\SaveDC", "Ptr", mDC)
    DllCall("Gdi32.dll\SelectObject", "Ptr", mDC, "Ptr", hBM)
    DllCall("Msimg32.dll\GradientFill", "Ptr", mDC, "Ptr", VERT, "Int", N, "Ptr", MESH, "Int", N - 1, "Int", !!V)
    DllCall("Gdi32.dll\RestoreDC", "Ptr", mDC, "Int", -1)
    DllCall("Gdi32.dll\DeleteDC", "Ptr", mDC)
    return hBM
}

; ---- TextOnGradient / 渐变文字 ----
TextOnGradient(W, H, Colors, Text, FontSize, Style := "text", fontFace := FontName, BgBM := 0, BgOffX := 0, RoundedBg := "", Align := "Center", wrapLines := 0) {
    global FontName
    if (W < 2 || H < 2 || Colors.Length < 2 || Text = "")
        return 0
    if (W > 4096 || H > 512)
        return 0
    alignFlags := (Align = "Left") ? 0x0 : (Align = "Right") ? 0x2 : 0x1
    drawFlags := (wrapLines > 0) ? (alignFlags | 0x10 | 0x4) : (alignFlags | 0x20 | 0x4)
    if (Style = "bg" || Style = "bg_rounded") {
        hBM := CreateGradient(W, H, 0, Colors*)
        if (!hBM)
            return 0
        hDC := DllCall("Gdi32.dll\CreateCompatibleDC", "Ptr", 0, "Ptr")
        hOldBM := DllCall("Gdi32.dll\SelectObject", "Ptr", hDC, "Ptr", hBM, "Ptr")
        fh := -Round(FontSize * A_ScreenDPI / 72)
        hFont := MakeFont(fh, fontFace)
        DllCall("Gdi32.dll\SelectObject", "Ptr", hDC, "Ptr", hFont, "Ptr")
        DllCall("Gdi32.dll\SetBkMode", "Ptr", hDC, "Int", 1)
        DllCall("Gdi32.dll\SetTextColor", "Ptr", hDC, "UInt", 0xFFFFFF)
        rc := Buffer(16, 0)
        NumPut("Int", 0, "Int", 0, "Int", W, "Int", H, rc)
        DllCall("User32.dll\DrawTextW", "Ptr", hDC, "Str", Text, "Int", -1, "Ptr", rc
            , "UInt", drawFlags)
        DllCall("Gdi32.dll\DeleteObject", "Ptr", hFont)
        DllCall("Gdi32.dll\SelectObject", "Ptr", hDC, "Ptr", hOldBM, "Ptr")
        DllCall("Gdi32.dll\DeleteDC", "Ptr", hDC)
        if (Style = "bg_rounded")
            hBM := RoundClipBM(hBM, W, H, Max(4, Min(W, H) // 6), RoundedBg)
        return hBM
    }

    fh := -Round(FontSize * A_ScreenDPI / 72)
    hFont := MakeFont(fh, fontFace)
    if (!hFont)
        return 0

    rc := Buffer(16, 0)
    NumPut("Int", 0, "Int", 0, "Int", W, "Int", H, rc)

    ; ---- 1) 创建渐变位图 / Gradient bitmap ----
    hGrad := CreateGradient(W, H, 0, Colors*)
    if (!hGrad) {
        DllCall("Gdi32.dll\DeleteObject", "Ptr", hFont)
        return 0
    }
    gradDC := DllCall("Gdi32.dll\CreateCompatibleDC", "Ptr", 0, "Ptr")
    hOldGrad := DllCall("Gdi32.dll\SelectObject", "Ptr", gradDC, "Ptr", hGrad, "Ptr")

    ; ---- 2) 创建 mask：白字黑底 / White text on black bg ----
    maskDC := DllCall("Gdi32.dll\CreateCompatibleDC", "Ptr", 0, "Ptr")
    hMask := DllCall("Gdi32.dll\CreateCompatibleBitmap", "Ptr", gradDC, "Int", W, "Int", H, "Ptr")
    hOldMask := DllCall("Gdi32.dll\SelectObject", "Ptr", maskDC, "Ptr", hMask, "Ptr")
    hBlack := DllCall("Gdi32.dll\GetStockObject", "Int", 4, "Ptr")
    DllCall("User32.dll\FillRect", "Ptr", maskDC, "Ptr", rc, "Ptr", hBlack)
    DllCall("Gdi32.dll\SelectObject", "Ptr", maskDC, "Ptr", hFont, "Ptr")
    DllCall("Gdi32.dll\SetBkMode", "Ptr", maskDC, "Int", 1)
    DllCall("Gdi32.dll\SetTextColor", "Ptr", maskDC, "UInt", 0xFFFFFF)
    DllCall("User32.dll\DrawTextW", "Ptr", maskDC, "Str", Text, "Int", -1, "Ptr", rc
        , "UInt", drawFlags)

    ; ---- 3) 创建 NOT-mask：黑字白底 / Black text on white bg ----
    notDC := DllCall("Gdi32.dll\CreateCompatibleDC", "Ptr", 0, "Ptr")
    hNot := DllCall("Gdi32.dll\CreateCompatibleBitmap", "Ptr", gradDC, "Int", W, "Int", H, "Ptr")
    hOldNot := DllCall("Gdi32.dll\SelectObject", "Ptr", notDC, "Ptr", hNot, "Ptr")
    hWhite := DllCall("Gdi32.dll\GetStockObject", "Int", 0, "Ptr")
    DllCall("User32.dll\FillRect", "Ptr", notDC, "Ptr", rc, "Ptr", hWhite)
    DllCall("Gdi32.dll\SelectObject", "Ptr", notDC, "Ptr", hFont, "Ptr")
    DllCall("Gdi32.dll\SetBkMode", "Ptr", notDC, "Int", 1)
    DllCall("Gdi32.dll\SetTextColor", "Ptr", notDC, "UInt", 0x000000)
    DllCall("User32.dll\DrawTextW", "Ptr", notDC, "Str", Text, "Int", -1, "Ptr", rc
        , "UInt", drawFlags)

    ; ---- 4) 填充bar背景色 / filled with bar bg ----
    finalDC := DllCall("Gdi32.dll\CreateCompatibleDC", "Ptr", 0, "Ptr")
    hFinal := DllCall("Gdi32.dll\CreateCompatibleBitmap", "Ptr", gradDC, "Int", W, "Int", H, "Ptr")
    hOldFinal := DllCall("Gdi32.dll\SelectObject", "Ptr", finalDC, "Ptr", hFinal, "Ptr")
    if (BgBM) {
        bgDC := DllCall("Gdi32.dll\CreateCompatibleDC", "Ptr", 0, "Ptr")
        hOldBg := DllCall("Gdi32.dll\SelectObject", "Ptr", bgDC, "Ptr", BgBM, "Ptr")
        DllCall("Gdi32.dll\BitBlt", "Ptr", finalDC, "Int", 0, "Int", 0, "Int", W, "Int", H
            , "Ptr", bgDC, "Int", BgOffX, "Int", 0, "UInt", 0xCC0020)
        DllCall("Gdi32.dll\SelectObject", "Ptr", bgDC, "Ptr", hOldBg, "Ptr")
        DllCall("Gdi32.dll\DeleteDC", "Ptr", bgDC)
    } else {
        bgVal := Integer("0x" C1(RoundedBg != "" ? RoundedBg : "000000"))
        bgRef := BgrFromRgb(bgVal)
        hBgBrush := DllCall("Gdi32.dll\CreateSolidBrush", "UInt", bgRef, "Ptr")
        DllCall("User32.dll\FillRect", "Ptr", finalDC, "Ptr", rc, "Ptr", hBgBrush)
        DllCall("Gdi32.dll\DeleteObject", "Ptr", hBgBrush)
    }

    ; ---- 5) 组合：渐变文字 / Compose: gradient text ----
    tempDC := DllCall("Gdi32.dll\CreateCompatibleDC", "Ptr", 0, "Ptr")
    hTemp := DllCall("Gdi32.dll\CreateCompatibleBitmap", "Ptr", gradDC, "Int", W, "Int", H, "Ptr")
    hOldTemp := DllCall("Gdi32.dll\SelectObject", "Ptr", tempDC, "Ptr", hTemp, "Ptr")
    DllCall("Gdi32.dll\BitBlt", "Ptr", tempDC, "Int", 0, "Int", 0, "Int", W, "Int", H
        , "Ptr", gradDC, "Int", 0, "Int", 0, "UInt", 0xCC0020)
    DllCall("Gdi32.dll\BitBlt", "Ptr", tempDC, "Int", 0, "Int", 0, "Int", W, "Int", H
        , "Ptr", maskDC, "Int", 0, "Int", 0, "UInt", 0x8800C6)
    DllCall("Gdi32.dll\BitBlt", "Ptr", finalDC, "Int", 0, "Int", 0, "Int", W, "Int", H
        , "Ptr", notDC, "Int", 0, "Int", 0, "UInt", 0x8800C6)
    DllCall("Gdi32.dll\BitBlt", "Ptr", finalDC, "Int", 0, "Int", 0, "Int", W, "Int", H
        , "Ptr", tempDC, "Int", 0, "Int", 0, "UInt", 0xEE0086)

    ; ---- 6) 清理 / Cleanup ----
    DllCall("Gdi32.dll\SelectObject", "Ptr", tempDC, "Ptr", hOldTemp, "Ptr")
    DllCall("Gdi32.dll\DeleteObject", "Ptr", hTemp)
    DllCall("Gdi32.dll\DeleteDC", "Ptr", tempDC)
    DllCall("Gdi32.dll\SelectObject", "Ptr", notDC, "Ptr", hOldNot, "Ptr")
    DllCall("Gdi32.dll\DeleteObject", "Ptr", hNot)
    DllCall("Gdi32.dll\DeleteDC", "Ptr", notDC)
    DllCall("Gdi32.dll\SelectObject", "Ptr", maskDC, "Ptr", hOldMask, "Ptr")
    DllCall("Gdi32.dll\DeleteObject", "Ptr", hMask)
    DllCall("Gdi32.dll\DeleteDC", "Ptr", maskDC)
    DllCall("Gdi32.dll\SelectObject", "Ptr", gradDC, "Ptr", hOldGrad, "Ptr")
    DllCall("Gdi32.dll\DeleteObject", "Ptr", hGrad)
    DllCall("Gdi32.dll\DeleteDC", "Ptr", gradDC)
    DllCall("Gdi32.dll\SelectObject", "Ptr", finalDC, "Ptr", hOldFinal, "Ptr")
    DllCall("Gdi32.dll\DeleteDC", "Ptr", finalDC)
    DllCall("Gdi32.dll\DeleteObject", "Ptr", hFont)
    return hFinal
}

; ---- Logging state (v2.9: structured, deduplicated, rotated) / 日志系统状态 ----
global WM_LogFile   := ""
global WM_LogLevel  := 2
global WM_LogMaxKB  := 512
global WM_LogSeen   := Map()

; ---- Level name to number / 级别名转数值 ----
_WMLogLevelNum(name) {
    switch StrUpper(Trim(name)) {
        case "DEBUG":           return 1
        case "INFO":            return 2
        case "WARN", "WARNING": return 3
        case "ERROR":           return 4
    }
    return 2
}

; ---- WMLog / 日志 ----
WMLog(msg, level := "INFO", comp := "Core") {
    global ConfigDir, WM_LogFile, WM_LogLevel, WM_LogMaxKB, WM_LogSeen
    if (WM_LogFile = "")
        WM_LogFile := ConfigDir . "\wm.log"
    if (_WMLogLevelNum(level) < WM_LogLevel)
        return
    key := comp . "|" . msg
    if WM_LogSeen.Has(key) {
        WM_LogSeen[key] += 1
        if (Mod(WM_LogSeen[key], 50) != 0)
            return
        msg := msg . "  (repeated " . WM_LogSeen[key] . "x)"
    } else {
        WM_LogSeen[key] := 1
    }
    try {
        if (WM_LogMaxKB > 0 && FileExist(WM_LogFile)
            && FileGetSize(WM_LogFile, "K") >= WM_LogMaxKB) {
            try FileDelete(WM_LogFile . ".old")
            try FileMove(WM_LogFile, WM_LogFile . ".old")
        }
    }
    line := FormatTime(, "yyyy-MM-dd HH:mm:ss") . "." . Format("{:03}", A_MSec)
          . "  [" . StrUpper(level) . "]  [" . comp . "]  " . msg . "`r`n"
    try FileAppend(line, WM_LogFile, "UTF-8")
}

; ---- LogSessionExit / 会话退出记录 ----
LogSessionExit(exitReason, exitCode) {
    global WM_LogFile
    try WTM.CleanupOnExit()
    if (WM_LogFile = "")
        return
    try {
        line := FormatTime(, "yyyy-MM-dd HH:mm:ss") . "." . Format("{:03}", A_MSec)
              . "  [INFO]  [Startup]  ===== AHK_WM session end (reason: " . exitReason . ", code: " . exitCode . ") =====" . "`r`n"
        FileAppend(line, WM_LogFile, "UTF-8")
    }
}

; ---- WMFormatErr / 异常格式 ----
WMFormatErr(context, err) {
    if !IsObject(err)
        return context . ": " . err
    out := context . ": " . err.Message
    try if (err.Extra != "")
        out .= "  | Extra: " . err.Extra
    try if (err.What != "")
        out .= "  | in: " . err.What
    try out .= "  | at: " . err.File . ":" . err.Line
    try if (err.Stack != "")
        out .= "`r`n    Call stack:`r`n"
             . RegExReplace(RTrim(err.Stack, "`r`n"), "m)^", "        ")
    return out
}

; ---- WMLogErr / 异常日志 ----
WMLogErr(context, err) {
    WMLog(WMFormatErr(context, err), "ERROR", "Error")
}

; ---- WMGuard / 故障隔离 ----
WMGuard(context, fn) {
    try {
        fn()
        return true
    } catch Error as e {
        WMLogErr(context, e)
        return false
    }
}

; ---- Rounded corners using global [GUI] settings / 全局圆角 ----
RoundWindow(guiOrHwnd) {
    global GUI_Rounded, GUI_CornerRadius
    RoundWindowEx(guiOrHwnd, GUI_Rounded, GUI_CornerRadius)
}

; ---- Rounded corners with per-GUI overrides / 独立圆角 ----
RoundWindowEx(guiOrHwnd, enabled, radius, corners := "all") {
    if (enabled != "on")
        return
    hwnd := IsObject(guiOrHwnd) ? guiOrHwnd.Hwnd : guiOrHwnd
    try {
        WinGetPos(, , &w, &h, hwnd)
        if (w <= 0 || h <= 0)
            return
        r := Max(0, radius)
        r := Min(r, w // 2, h // 2)
        d := r * 2
        if (d <= 0)
            return
        DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", hwnd, "UInt", 2, "Int*", 1, "UInt", 4)
        hRgn := DllCall("Gdi32\CreateRoundRectRgn"
            , "Int", 0, "Int", 0, "Int", w + 1, "Int", h + 1
            , "Int", d, "Int", d, "Ptr")
        corners := StrLower(Trim(corners))
        if (corners = "top" || corners = "bottom") {
            if (corners = "top")
                hRect := DllCall("Gdi32\CreateRectRgn"
                    , "Int", 0, "Int", h - r, "Int", w + 1, "Int", h + 1, "Ptr")
            else
                hRect := DllCall("Gdi32\CreateRectRgn"
                    , "Int", 0, "Int", 0, "Int", w + 1, "Int", r, "Ptr")
            DllCall("Gdi32\CombineRgn", "Ptr", hRgn, "Ptr", hRgn, "Ptr", hRect, "Int", 2)
            DllCall("Gdi32\DeleteObject", "Ptr", hRect)
        }
        DllCall("User32\SetWindowRgn", "Ptr", hwnd, "Ptr", hRgn, "Int", 1)
    }
}

; ---- SplitExclude / 排除列表 ----
SplitExcludeList(str) {
    out := []
    for part in StrSplit(str, ";") {
        part := Trim(part)
        if (part != "")
            out.Push(part)
    }
    return out
}

; ---- GlobMatch / 通配符匹配（* 任意多个, ? 单个, 其余按字面） ----
GlobMatch(text, pat) {
    n := StrLen(pat), m := StrLen(text)
    if (n = 0)
        return (m = 0)
    ti := 0, pi := 0, star := -1, mark := 0
    while (ti < m) {
        if (pi < n) {
            c := SubStr(pat, pi + 1, 1)
            if (c = "*") {
                star := pi, mark := ti, pi += 1
                continue
            }
            if (c = "?" || c = SubStr(text, ti + 1, 1)) {
                ti += 1, pi += 1
                continue
            }
        }
        if (star >= 0) {
            pi := star + 1, mark += 1, ti := mark
            continue
        }
        return false
    }
    while (pi < n && SubStr(pat, pi + 1, 1) = "*")
        pi += 1
    return (pi = n)
}

; ---- MatchField / 单字段匹配 ----
MatchField(text, rule, field) {
    rule := Trim(rule)
    if (rule = "")
        return false
    low := StrLower(rule)
    if (SubStr(low, 1, 5) = "proc:") {
        if (field != "proc")
            return false
        rule := Trim(SubStr(rule, 6))
    } else if (SubStr(low, 1, 4) = "cls:") {
        if (field != "class")
            return false
        rule := Trim(SubStr(rule, 5))
    } else if (SubStr(low, 1, 6) = "title:") {
        if (field != "title")
            return false
        rule := Trim(SubStr(rule, 7))
    }
    if (rule = "")
        return false
    text := "" . text
    if (SubStr(rule, 1, 1) = "=")
        return (StrLower(Trim(text)) = StrLower(Trim(SubStr(rule, 2))))
    if (SubStr(rule, 1, 3) = "re:" || SubStr(rule, 1, 2) = "~=") {
        pat := (SubStr(rule, 1, 3) = "re:") ? SubStr(rule, 4) : SubStr(rule, 3)
        try
            return (text ~= pat) ? true : false
        catch
            return false
    }
    if (InStr(rule, "*") || InStr(rule, "?"))
        return GlobMatch(StrLower(text), StrLower(rule))
    if (field = "proc")
        return InStr(StrLower(_StripExe(text)), StrLower(_StripExe(rule))) ? true : false
    return InStr(StrLower(text), StrLower(rule)) ? true : false
}

_StripExe(s) {
    s := Trim(s)
    return (SubStr(StrLower(s), -4) = ".exe") ? SubStr(s, 1, StrLen(s) - 4) : s
}

MatchTitleRule(text, rule) {
    return MatchField(text, rule, "title")
}

; ---- Exclusion rule field bits / 排除规则字段位 ----
ExclFieldBit(field) {
    return (field = "title") ? 1 : (field = "class") ? 2 : 4
}

ExclRecomputeNeed() {
    global Excl_Titles, Excl_Classes, Excl_Processes, Excl_NeedField
    need := 0
    for r in Excl_Titles {
        low := StrLower(Trim(r))
        if (SubStr(low, 1, 5) = "proc:")
            need |= 4
        else if (SubStr(low, 1, 4) = "cls:")
            need |= 2
        else
            need |= 1
    }
    for r in Excl_Classes {
        low := StrLower(Trim(r))
        if (SubStr(low, 1, 5) = "proc:")
            need |= 4
        else if (SubStr(low, 1, 6) = "title:")
            need |= 1
        else
            need |= 2
    }
    for r in Excl_Processes {
        low := StrLower(Trim(r))
        if (SubStr(low, 1, 6) = "title:")
            need |= 1
        else if (SubStr(low, 1, 4) = "cls:")
            need |= 2
        else
            need |= 4
    }
    Excl_NeedField := need
}

; ---- IsExcluded / 窗口排除 ----
IsExcludedWindow(hwnd) {
    global Excl_Titles, Excl_Classes, Excl_Processes, Excl_NeedField
    if (Excl_NeedField = 0)
        return false
    title := "", cls := "", proc := ""
    try {
        if (Excl_NeedField & 1)
            title := WinGetTitle(hwnd)
        if (Excl_NeedField & 2)
            cls := WinGetClass(hwnd)
        if (Excl_NeedField & 4)
            proc := WinGetProcessName(hwnd)
    }
    for rule in Excl_Titles
        if MatchField(title, rule, "title")
            return true
    for rule in Excl_Classes
        if (cls != "" && MatchField(cls, rule, "class"))
            return true
    for rule in Excl_Processes
        if (proc != "" && MatchField(proc, rule, "proc"))
            return true
    return false
}

ExclusionReason(hwnd) {
    global Excl_Titles, Excl_Classes, Excl_Processes, Excl_NeedField
    title := "", cls := "", proc := ""
    try {
        title := WinGetTitle(hwnd)
        cls   := WinGetClass(hwnd)
        proc  := WinGetProcessName(hwnd)
    }
    for rule in Excl_Titles
        if MatchField(title, rule, "title")
            return "[Titles] " . rule
    for rule in Excl_Classes
        if (cls != "" && MatchField(cls, rule, "class"))
            return "[Classes] " . rule
    for rule in Excl_Processes
        if (proc != "" && MatchField(proc, rule, "proc"))
            return "[Processes] " . rule
    return ""
}

; ---- exclude.ini / 排除规则文件 ----
ExclFileHeader() {
    return ""
        . "; ================================================================`r`n"
        . ";  AHK_WM window exclusion rules / AHK_WM 窗口排除规则`r`n"
        . "; ================================================================`r`n"
        . "; Case-insensitive. Rule forms / 匹配写法（大小写不敏感）：`r`n"
        . ";   foo          substring (default) / 子串包含`r`n"
        . ";   =foo         exact match / 完全等于`r`n"
        . ";   *foo*        wildcard, * = any run, ? = one char / 通配符`r`n"
        . ";   ~=^foo$      regex, the re: prefix works too / 正则`r`n"
        . ";   proc: / cls: / title:   force one field, may cross sections / 指定字段`r`n"
        . "; The section decides the default field; a process name may skip .exe`r`n"
        . "; 分区决定默认字段；进程名可不带 .exe（chrome == chrome.exe）。`r`n"
        . "; `r`n"
        . "; [Preset-*] is generated and overwritten on update / 预设段生成，手改会丢`r`n"
        . "; Put your own rules in [User-*] / 自定义规则写进 [User-*]`r`n"
        . "; Hotkeys / 热键：Alt+Shift+X adds the current window to [User-Processes];`r`n"
        . ";   DiagnoseWindow (unbound by default) explains whether it matched.`r`n"
        . "; ================================================================`r`n"
        . "`r`n"
}

global ExclPresetRev := 3

global ExclPresetIniText := ""
    . "[Preset-Titles]`r`n"
    . "; Picture-in-picture only; the browser process is untouched / 只排画中画小窗`r`n"
    . "1=title:Picture-in-Picture`r`n"
    . "2=title:画中画`r`n"
    . "`r`n"
    . "[Preset-Classes]`r`n"
    . "; Desktop / taskbar / tray / 桌面任务栏托盘`r`n"
    . "1=cls:Progman`r`n"
    . "2=cls:WorkerW`r`n"
    . "3=cls:Shell_TrayWnd`r`n"
    . "4=cls:Shell_SecondaryTrayWnd`r`n"
    . "5=cls:NotifyIconOverflowWindow`r`n"
    . "6=cls:TopLevelWindowForOverflowXamlIsland`r`n"
    . "; Task switcher / task view / thumbnail previews / 任务切换与预览`r`n"
    . "7=cls:TaskSwitcherWnd`r`n"
    . "8=cls:MultitaskingViewFrame`r`n"
    . "9=cls:XamlExplorerHostIslandWindow`r`n"
    . "10=cls:TaskListThumbnailWnd`r`n"
    . "11=cls:ForegroundStaging`r`n"
    . "; Transient overlays: tooltips, context and system menus / 瞬时覆盖层`r`n"
    . "12=cls:tooltips_class32`r`n"
    . "13=cls:#32768`r`n"
    . "`r`n"
    . "[Preset-Processes]`r`n"
    . "; Empty on purpose: a process rule excludes every window of that app.`r`n"
    . "; 故意留空：进程规则会连该程序的所有窗口一起排除。`r`n"
    . "; Use Alt+Shift+X to add one app to [User-Processes] / 要排某个程序按 Alt+Shift+X`r`n"
    . "`r`n"
ExclPresetIni() {
    global ExclPresetIniText
    if (ExclPresetIniText != "")
        return ExclPresetIniText
    return "[Preset-Titles]`r`n`r`n[Preset-Classes]`r`n`r`n[Preset-Processes]`r`n"
}

EnsureExcludeFile() {
    global ExcludeFile, ConfigFile, ConfigDir, ExclPresetRev
    if FileExist(ExcludeFile)
        return
    txt := ExclFileHeader() . ExclPresetIni() . "`r`n"
        . "[User-Titles]`r`n`r`n[User-Classes]`r`n`r`n[User-Processes]`r`n"
    for name in ["Titles", "Classes", "Processes"] {
        raw := ""
        try raw := IniRead(ConfigFile, "Exclude", name, "")
        arr := SplitExcludeList(raw)
        if (arr.Length = 0)
            continue
        lines := ""
        for i, r in arr
            lines .= i . "=" . r . "`r`n"
        hdr := "[User-" . name . "]`r`n"
        txt := StrReplace(txt, hdr, hdr . lines)
    }
    txt .= "`r`n[Meta]`r`nPresetRev=" . ExclPresetRev . "`r`n"
    try {
        if !DirExist(ConfigDir)
            DirCreate(ConfigDir)
        FileAppend(txt, ExcludeFile, "UTF-16")
    } catch {
        try WMLog("EnsureExcludeFile failed: " . A_LastError)
    }
}

ExclRefreshPreset() {
    global ExcludeFile, ExclPresetRev
    cur := ""
    try cur := IniRead(ExcludeFile, "Meta", "PresetRev", "0")
    if (cur = "" . ExclPresetRev)
        return
    user := ""
    for name in ["Titles", "Classes", "Processes"] {
        sec := ""
        try sec := IniRead(ExcludeFile, "User-" . name)
        user .= "[User-" . name . "]`r`n" . RTrim(sec, "`r`n") . "`r`n`r`n"
    }
    txt := ExclFileHeader() . ExclPresetIni() . "`r`n" . user
        . "[Meta]`r`nPresetRev=" . ExclPresetRev . "`r`n"
    try {
        FileDelete(ExcludeFile)
        FileAppend(txt, ExcludeFile, "UTF-16")
        try WMLog("ExclRefreshPreset → rev " . ExclPresetRev)
    } catch {
        try WMLog("ExclRefreshPreset failed: " . A_LastError)
    }
}

ExclParseSection(text) {
    out := []
    for line in StrSplit(text, "`n", "`r") {
        line := Trim(line)
        if (line = "" || SubStr(line, 1, 1) = ";")
            continue
        p := InStr(line, "=")
        val := (p = 0) ? line : Trim(SubStr(line, p + 1))
        for r in SplitExcludeList(val)
            out.Push(r)
    }
    return out
}

ExclReadSection(name) {
    global ExcludeFile
    out := []
    for pre in ["Preset-", "User-"] {
        raw := ""
        try raw := IniRead(ExcludeFile, pre . name)
        for r in ExclParseSection(raw)
            out.Push(r)
    }
    return out
}

LoadExcludeRules() {
    global Excl_Titles, Excl_Classes, Excl_Processes
    EnsureExcludeFile()
    ExclRefreshPreset()
    Excl_Titles    := ExclReadSection("Titles")
    Excl_Classes   := ExclReadSection("Classes")
    Excl_Processes := ExclReadSection("Processes")
    ExclRecomputeNeed()
}

; ---- Write user rules / 用户规则写入 ----
ExclRuleExists(rule) {
    global Excl_Processes, Excl_Classes, Excl_Titles
    low := StrLower(Trim(rule))
    for arr in [Excl_Processes, Excl_Classes, Excl_Titles]
        for r in arr
            if (StrLower(Trim(r)) = low)
                return true
    return false
}

ExclAppendUser(sec, rule) {
    global ExcludeFile
    cur := ""
    try cur := IniRead(ExcludeFile, "User-" . sec)
    n := 0
    for line in StrSplit(cur, "`n", "`r") {
        line := Trim(line)
        if (line != "" && SubStr(line, 1, 1) != ";")
            n += 1
    }
    try IniWrite(rule, ExcludeFile, "User-" . sec, n + 1)
}

; ---- Hotkey: add to exclusions / 加入排除 ----
ExcludeCurrentWindow(*) {
    global ExcludeFile, WM_LogLevel
    hwnd := 0
    try hwnd := WinExist("A")
    if !hwnd {
        ShowOSD("Exclude: No Window")
        return
    }
    proc := ""
    try proc := WinGetProcessName(hwnd)
    if (proc = "") {
        ShowOSD("Exclude: Failed")
        return
    }
    rule := _StripExe(proc)
    if ExclRuleExists(rule) {
        ShowOSD("Already Excluded: " . rule)
        return
    }
    ExclAppendUser("Processes", rule)
    LoadExcludeRules()
    ShowOSD("Excluded: " . rule)
    if (WM_LogLevel <= 2)
        try WMLog("ExcludeCurrentWindow proc=" . rule . " file=" . ExcludeFile)
}

; ---- Hotkey: diagnose window / 诊断窗口 ----
DiagnoseWindow(*) {
    hwnd := 0
    try hwnd := WinExist("A")
    if !hwnd {
        ShowOSD("Diagnose: no active window", 3000)
        return
    }
    title := "", cls := "", proc := "", maxed := ""
    try title := WinGetTitle(hwnd)
    try cls   := WinGetClass(hwnd)
    try proc  := WinGetProcessName(hwnd)
    try maxed := WinGetMinMax(hwnd)
    reason := ExclusionReason(hwnd)
    msg := "Proc    : " . proc . "`n"
        .  "Class   : " . cls . "`n"
        .  "Title   : " . title . "`n"
        .  "MinMax  : " . maxed . "  (-1 minimized, 1 maximized)`n"
        .  "HWND    : " . Format("0x{:X}", hwnd) . "`n"
        .  "Excluded: " . (reason = "" ? "no" : "yes") . "`n"
    if (reason != "")
        msg .= "Rule    : " . reason
    else if (HK.Has("ExcludeWindow") && HK["ExcludeWindow"] != "")
        msg .= "Tip     : " . PrettifyHotkey(HK["ExcludeWindow"]) . " adds a rule; [User-*] in exclude.ini targets one field."
    else
        msg .= "Tip     : ExcludeWindow is unbound; add rules by hand in exclude.ini ([User-*])."
    ; 屏幕居中；顶上会让状态栏压住它，贴底会被下边缘截断。tag 保证重复按只留一个。
    ; Centred: the top edge hides it behind the status bar, the bottom one clips it.
    OSD.ShowExternal(msg, 6000, "x=center,y=center,tag=diagnose")
}

; ---- ParseAxis / 轴解析 ----
ParseAxis(tok) {
    tok := Trim(tok)
    if (tok = "")
        throw Error("empty axis")
    if (tok = "1")
        return {lo: 0.0, hi: 1.0, align: "Center"}
    if RegExMatch(tok, "^\((\d+)\s*-\s*(\d+)\)/([+\-]?)(\d+)$", &m) {
        a := Integer(m[1]), c := Integer(m[2]), b := Integer(m[4])
        sign := m[3]
        if (b <= 0 || a < 1 || c < 1 || a > c || c > b)
            throw Error("bad range axis: " tok)
        align := (sign = "+") ? "Right" : (sign = "-") ? "Left" : "Center"
        return {lo: (a - 1) / b, hi: c / b, align: align}
    }
    if RegExMatch(tok, "^(\d+)/([+\-]?)(\d+)$", &m) {
        a := Integer(m[1]), b := Integer(m[3])
        sign := m[2]
        if (b <= 0 || a < 1 || a > b)
            throw Error("bad axis: " tok)
        align := (sign = "+") ? "Right" : (sign = "-") ? "Left" : "Center"
        return {lo: (a - 1) / b, hi: a / b, align: align}
    }
    throw Error("unrecognized axis: " tok)
}

; ---- Scrollable desktops "1;3" -> Map / 滚动桌面列表 ----
ParseScrollDesktops(str, maxD := 9) {
    out := Map()
    for tok in StrSplit(Trim(str), ";") {
        tok := Trim(tok)
        if (tok = "")
            continue
        if !IsInteger(tok) {
            WMLog("ScrollableDesktops skipped (bad token): " tok)
            continue
        }
        d := Integer(tok)
        if (d < 1 || d > maxD) {
            WMLog("ScrollableDesktops skipped (out of range): " tok)
            continue
        }
        out[d] := true
    }
    return out
}

; ---- ParseLayoutRules / 平铺规则 ----
ParseLayoutRules(str) {
    result := Map()
    str := Trim(str)
    if (str = "")
        return result
    groups := Map()
    counts := Map()
    monKey := Map()
    bad    := Map()
    for clause in StrSplit(str, ";") {
        clause := Trim(clause)
        if (clause = "")
            continue
        f := StrSplit(clause, ",")
        if (f.Length = 4) {
            f.InsertAt(1, "*")
        } else if (f.Length != 5) {
            WMLog("Layout rule skipped (field count): " clause)
            continue
        }
        M := Trim(f[1])
        if (M != "*" && !(IsInteger(M) && Integer(M) >= 1)) {
            WMLog("Layout rule skipped (bad monitor '" M "'): " clause)
            continue
        }
        if (M != "*")
            M := Integer(M)
        if !IsInteger(Trim(f[2])) {
            WMLog("Layout rule skipped (N not integer): " clause)
            continue
        }
        N := Integer(Trim(f[2]))
        if (N < 1) {
            WMLog("Layout rule skipped (N < 1): " clause)
            continue
        }
        key := M "|" N
        if !IsInteger(Trim(f[3])) {
            bad[key] := true
            WMLog("Layout group " key " invalid (I not integer): " clause)
            continue
        }
        I := Integer(Trim(f[3]))
        if (I < 1 || I > N) {
            bad[key] := true
            WMLog("Layout group " key " invalid (I out of range): " clause)
            continue
        }
        try {
            xr := ParseAxis(f[4])
            yr := ParseAxis(f[5])
        } catch Error as e {
            bad[key] := true
            WMLog("Layout group " key " invalid (" e.Message ")")
            continue
        }
        if !groups.Has(key) {
            groups[key] := Map()
            counts[key] := N
            monKey[key] := M
        }
        if groups[key].Has(I) {
            bad[key] := true
            WMLog("Layout group " key " invalid (duplicate window " I ")")
            continue
        }
        groups[key][I] := {x: xr, y: yr}
    }
    for key, items in groups {
        if bad.Has(key)
            continue
        N := counts[key]
        complete := (items.Count = N)
        if complete {
            loop N {
                if !items.Has(A_Index) {
                    complete := false
                    break
                }
            }
        }
        if !complete {
            WMLog("Layout group " key " invalid (incomplete/duplicate window list)")
            continue
        }
        arr := []
        loop N
            arr.Push(items[A_Index])
        M := monKey[key]
        if !result.Has(M)
            result[M] := Map()
        result[M][N] := arr
    }
    return result
}

; ---- GetCustomLayout / 布局查询 ----
GetCustomLayout(monIdx, n) {
    global LayoutRules, WTM_ResizeRules, WTM_LayoutOverride
    if (n < 1)
        return ""
    if (WTM_LayoutOverride && WTM_ResizeRules.Has(monIdx) && WTM_ResizeRules[monIdx].Has(n))
        return WTM_ResizeRules[monIdx][n]
    if (LayoutRules.Has(monIdx) && LayoutRules[monIdx].Has(n))
        return LayoutRules[monIdx][n]
    if (LayoutRules.Has("*") && LayoutRules["*"].Has(n))
        return LayoutRules["*"][n]
    return ""
}

; ---- ApplyCustomLayout / 布局应用 ----
ApplyCustomLayout(wins, X, Y, W, H, monIdx := 0) {
    n := wins.Length
    rules := GetCustomLayout(monIdx, n)
    if (rules = "")
        return false
    for i, hwnd in wins {
        if (i > rules.Length)
            break
        r  := rules[i]
        wx := X + r.x.lo * W
        ww := (r.x.hi - r.x.lo) * W
        wy := Y + r.y.lo * H
        wh := (r.y.hi - r.y.lo) * H
        EmitPlace(hwnd, wx, wy, ww, wh)
    }
    return true
}

; ---- NormalizeHotkey / 热键转换 ----
NormalizeHotkey(s) {
    s := Trim(s)
    if (s = "")
        return ""
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

; ---- PrettifyHotkey / 热键显示 ----
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

; ---- NormalizeModifiers / 修饰键 ----
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

; ---- VisualRect / DWM矩形 ----
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

; ---- FrameDelta / 边框偏移 ----
GetFrameDelta(hwnd, &dx, &dy, &dw, &dh) {
    WinGetPos(&wx, &wy, &ww, &wh, hwnd)
    if !GetWindowVisualRect(hwnd, &vx, &vy, &vw, &vh) {
        dx := 0, dy := 0, dw := 0, dh := 0
        return false
    }
    dx := vx - wx
    dy := vy - wy
    dw := ww - vw
    dh := wh - vh
    return true
}

; ---- MonitorAtPoint / 显示器坐标 ----
GetMonitorIndexAtPoint(x, y) {
    loop MonitorGetCount() {
        MonitorGet(A_Index, &mL, &mT, &mR, &mB)
        if (x >= mL && x < mR && y >= mT && y < mB)
            return A_Index
    }
    return 1
}

; ---- MonitorOfWindow / 显示器窗口 ----
GetMonitorIndex(hwnd := 0) {
    if !hwnd || !WinExist(hwnd) {
        MouseGetPos(&mx, &my)
        return GetMonitorIndexAtPoint(mx, my)
    }
    WinGetPos(&wx, &wy, &ww, &wh, hwnd)
    return GetMonitorIndexAtPoint(wx + ww/2, wy + wh/2)
}

; ---- MaskAlt / Alt屏蔽 ----
MaskAltMenu() {
    if GetKeyState("Alt", "P")
        try Send("{Blind}{vkE8}")
}

; ---- FocusSafely / 窗口激活 ----
FocusWindowSafely(hwnd) {
    if (!hwnd || !WinExist(hwnd))
        return false
    MaskAltMenu()
    Loop 3 {
        try WinActivate(hwnd)
        ok := 0
        try ok := WinWaitActive(hwnd, , 0.1)
        if ok
            return true
        Sleep(10)
    }
    return false
}

; ---- Save desktop layout before Reload / 存布局 ----
SaveLayoutStateForReload() {
    global Desktops, DesktopFocus, CurrentDesktop, AlwaysVisible, ConfigDir, DesktopIsSwitching
    if DesktopIsSwitching {
        SetTimer(() => SaveLayoutStateForReload(), -100)
        return
    }
    stateFile := ConfigDir . "\wm_layout.dat"
    try FileDelete(stateFile)
    catch
    try {
        f := FileOpen(stateFile, "w", "UTF-8")
        f.WriteLine("CURRENT=" CurrentDesktop)
        for dNum, winList in Desktops {
            parts := []
            for h in winList {
                if WinExist(h)
                    parts.Push(h)
            }
            if parts.Length > 0
                f.WriteLine("D" dNum "=" HwndListStr(parts))
        }
        for dNum, hwnd in DesktopFocus {
            if WinExist(hwnd)
                f.WriteLine("F" dNum "=" hwnd)
        }
        avParts := []
        for hwnd, _ in AlwaysVisible {
            if WinExist(hwnd)
                avParts.Push(hwnd)
        }
        if avParts.Length > 0
            f.WriteLine("AV=" HwndListStr(avParts))
        f.Close()
    }
}

HwndListStr(arr) {
    s := ""
    for i, v in arr
        s .= (i = 1 ? "" : ",") . v
    return s
}

; ---- Restore desktop layout after Reload / 恢复布局 ----
RestoreLayoutState() {
    global Desktops, DesktopFocus, CurrentDesktop, AlwaysVisible, ConfigDir
    stateFile := ConfigDir . "\wm_layout.dat"
    if !FileExist(stateFile)
        return false
    restored := false
    try {
        f := FileOpen(stateFile, "r", "UTF-8")
        content := f.Read()
        f.Close()
        for line in StrSplit(content, "`n", "`r") {
            line := Trim(line)
            if line = ""
                continue
            if RegExMatch(line, "i)^CURRENT=(\d+)$", &m) {
                d := Integer(m[1])
                if d >= 1 && d <= DesktopCount {
                    CurrentDesktop := d
                    restored := true
                }
                continue
            }
            if RegExMatch(line, "i)^AV=(.+)$", &m) {
                for h in StrSplit(m[1], ",") {
                    hw := Integer(Trim(h))
                    if hw && WinExist(hw) {
                        AlwaysVisible[hw] := true
                    }
                }
                continue
            }
            if RegExMatch(line, "i)^D(\d+)=(.+)$", &m) {
                dNum := Integer(m[1])
                if dNum < 1 || dNum > DesktopCount
                    continue
                parts := []
                for h in StrSplit(m[2], ",") {
                    hw := Integer(Trim(h))
                    if hw && WinExist(hw)
                        parts.Push(hw)
                }
                if parts.Length > 0 {
                    Desktops[dNum] := parts
                    restored := true
                }
                continue
            }
            if RegExMatch(line, "i)^F(\d+)=(.+)$", &m) {
                hw := Integer(Trim(m[2]))
                if hw && WinExist(hw)
                    DesktopFocus[Integer(m[1])] := hw
                continue
            }
        }
        FileDelete(stateFile)
    }
    if restored {
        if Desktops.Has(CurrentDesktop) {
            loop Desktops[CurrentDesktop].Length {
                h := Desktops[CurrentDesktop][Desktops[CurrentDesktop].Length - A_Index + 1]
                ShowWin(h)
            }
        }
        for hwnd, _ in AlwaysVisible
            ShowWin(hwnd)
        if DesktopFocus.Has(CurrentDesktop) && DesktopFocus[CurrentDesktop]
               && WinExist(DesktopFocus[CurrentDesktop])
            FocusWindowSafely(DesktopFocus[CurrentDesktop])
    }
    return restored
}

; ---- Reload script with layout save / 存后重载 ----
ScriptReload(*) {
    SaveLayoutStateForReload()
    Reload()
}

; ==============================================================================
; 4. Startup Sequence / 启动流程
; ==============================================================================

OnError(WM_OnError)

WM_OnError(err, mode) {
    WMLogErr("Unhandled runtime error (" . mode . ")", err)
    return true
}

isFirstRun := !FileExist(ConfigFile)

LoadOrInitConfig()

    ; ---- Startup banner / 启动日志横幅 ----
    WMLog("============================================================", "INFO", "Startup")
    WMLog("AHK_WM v" . WM_Version . "  session start", "INFO", "Startup")
    WMLog("PID: " . ProcessExist() . "  |  Config: " . ConfigFile, "DEBUG", "Startup")
    WMLog("Desktop count: " . DesktopCount . "  |  Active theme: " . ActiveTheme, "DEBUG", "Startup")
    WMLog("Font: " . FontName . "  |  Bar height: " . Bar_Height . "px", "DEBUG", "Startup")
    WMLog("============================================================", "INFO", "Startup")
    OnExit(LogSessionExit)

Loop DesktopCount
    Desktops[A_Index] := []

if RestoreLayoutState()
    isFirstRun := false

if !DirExist(Path_Output) {
    try DirCreate(Path_Output)
    if !DirExist(Path_Output)
        PathWarning := "The output directory does not exist and could not be created:`n`n"
                     . Path_Output
                     . "`n`nClipboard history will not be saved until you set a valid"
                     . " OutputDir / OutputFile in the [Paths] section of:`n`n" . ConfigFile
}
if !DirExist(Path_Button)
    try DirCreate(Path_Button)

buttonsCreated := false
try buttonsCreated := InitializeButtons()
catch Error as e
    WMLogErr("Startup: InitializeButtons", e)

WMGuard("Startup: RegisterAllHotkeys", RegisterAllHotkeys)

if isFirstRun
    WMGuard("Startup: WelcomeScreen", () => WelcomeScreen.Show())
else if buttonsCreated
    Reload()

WMGuard("Startup: CreateStatusBar",        CreateStatusBar)
WMGuard("Startup: UpdateStatusBar",        UpdateStatusBar)
WMGuard("Startup: UpdateClockAndProgress", UpdateClockAndProgress)
SetTimer(UpdateClockAndProgress, 1000)
WMGuard("Startup: SetupTrayIcon",          SetupTrayIcon)
OnClipboardChange(OnClipboardChanged)

if (PathWarning != "")
    SetTimer(ShowPathWarning, -1500)

; ---- ShowPathWarning / 启动弹窗 ----
ShowPathWarning() {
    global PathWarning
    if (PathWarning = "")
        return
    msg := PathWarning
    PathWarning := ""
    try MsgBox(msg, "AHK WM - Configuration Warning", "Iconi 0x40000")
}

; ==============================================================================
; 5. Hotkey Registration / 热键注册
; ==============================================================================

; ---- RegHotkey / 热键注册 ----
RegHotkey(key, fn) {
    global HK
    if !HK.Has(key)
        return false
    combo := HK[key]
    if (combo = "")
        return false
    try {
        Hotkey(combo, fn)
        return true
    } catch Error as e {
        WMLog("Hotkey register failed [" key "=" combo "]: " e.Message)
        return false
    }
}

; ---- RegisterAll / 注册全部 ----
RegisterAllHotkeys() {
    global HK, DesktopCount

    RegHotkey("Help", ShowHelpGui)

    pSwitch := HK.Has("DesktopSwitchPrefix")     ? HK["DesktopSwitchPrefix"]     : ""
    pMove   := HK.Has("DesktopMovePrefix")       ? HK["DesktopMovePrefix"]       : ""
    pBoth   := HK.Has("DesktopMoveSwitchPrefix") ? HK["DesktopMoveSwitchPrefix"] : ""
    Loop DesktopCount {
        i := A_Index
        if (pSwitch != "")
            try Hotkey(pSwitch . i, SwitchDesktop.Bind(i))
        if (pMove != "")
            try Hotkey(pMove . i, MoveWindowToDesktop.Bind(i))
        if (pBoth != "")
            try Hotkey(pBoth . i, MoveAndSwitch.Bind(i))
    }

    RegHotkey("TileSmart", TileCurrentMonitor)
    RegHotkey("GatherAll", GatherAllToCurrent)
    RegHotkey("TogglePin", TogglePin)
    RegHotkey("ToggleBar", ToggleBar)
    RegHotkey("Exit",      RestoreAndExit)

    RegHotkey("CloseWindow",    CloseWindowDispatch)
    RegHotkey("CloseWindowAlt", CloseWindowDispatch)
    RegHotkey("ToggleMaximize", ToggleMaximizeDispatch)
    RegHotkey("ToggleTop",      ToggleTopDispatch)
    RegHotkey("HideWindow",     HideUnderMouse)

    RegHotkey("TransparencyUp",   AdjustTransparency.Bind(20))
    RegHotkey("TransparencyDown", AdjustTransparency.Bind(-20))

    RegHotkey("LaunchTerminal", LaunchTerminal)
    RegHotkey("EditFile",       OpenWithVim)
    RegHotkey("PowerMenu",      ShowPowerMenu)

    RegHotkey("SnapLeft",  SnapWindow.Bind("Left"))
    RegHotkey("SnapRight", SnapWindow.Bind("Right"))
    RegHotkey("SnapUp",    SnapWindow.Bind("Up"))
    RegHotkey("SnapDown",  SnapWindow.Bind("Down"))

    RegHotkey("SaveLayout",    CopyLayoutRules)
    RegHotkey("ExcludeWindow",  ExcludeCurrentWindow)
    RegHotkey("DiagnoseWindow", DiagnoseWindow)

    RegHotkey("Reload", (*) => ScriptReload())
    RegHotkey("ClipboardHistory", (*) => ToggleVimWindow())

    if RegHotkey("PieMenuTrigger", (*) => PieMenu.Start()) {
        try Hotkey("~Space Up", PieMenuExecute)
        try HotIf((*) => PieMenu.IsActive || PieMenu.PendingRUp)
        try Hotkey("RButton Up", PieMenuRButtonUp)
        try HotIf()
    }

    RegHotkey("DragMove",   DragMoveHandler)
    RegHotkey("DragResize", DragResizeHandler)

    RegHotkey("WinSelect", (*) => WinSelect.Start())

    RegHotkey("WTMToggle",     (*) => WTM.Toggle())
    if (HK["WTMFull"] != HK["ToggleMaximize"])
        RegHotkey("WTMFull",   (*) => WTM.ToggleFull())
    RegHotkey("WTMTrueMax",    (*) => WTM.ToggleTrueMax())
    RegHotkey("WTMOverview",   (*) => WTM.ToggleOverview())
    RegHotkey("WTMFocusLeft",  (*) => WTM.FocusDir("L"))
    RegHotkey("WTMFocusDown",  (*) => WTM.FocusDir("D"))
    RegHotkey("WTMFocusUp",    (*) => WTM.FocusDir("U"))
    RegHotkey("WTMFocusRight", (*) => WTM.FocusDir("R"))
    RegHotkey("WTMMoveLeft",   (*) => WTM.MoveDir("L"))
    RegHotkey("WTMMoveDown",   (*) => WTM.MoveDir("D"))
    RegHotkey("WTMMoveUp",     (*) => WTM.MoveDir("U"))
    RegHotkey("WTMMoveRight",  (*) => WTM.MoveDir("R"))
    RegHotkey("WTMShrinkWidth",  (*) => WTM.Resize("X", false))
    RegHotkey("WTMGrowWidth",    (*) => WTM.Resize("X", true))
    RegHotkey("WTMGrowHeight",   (*) => WTM.Resize("Y", true))
    RegHotkey("WTMShrinkHeight", (*) => WTM.Resize("Y", false))
}

; ---- PieMenuExecute / 饼菜单 ----
PieMenuExecute(*) {
    if PieMenu.IsActive
        PieMenu.Execute()
}

; ---- Pie-menu RButton-up handler (conditional hotkey; RButton-down is swallowed so no context menu) / 功能环右键抬起处理 ----
; ---- Pie-menu RButton-up handler (conditional; swallowed to avoid context menu) ----
PieMenuRButtonUp(*) {
    if PieMenu.IsActive
        PieMenu.Execute()
    PieMenu.PendingRUp := false
}

; ---- ToggleMaximize / 最大化分发 ----
ToggleMaximizeDispatch(*) {
    if WTM.Active
        WTM.ToggleFull()
    else
        ToggleMaximizeUnderMouse()
}

; ---- ToggleTop / 置顶分发 ----
ToggleTopDispatch(*) {
    if WTM.Active
        WTM.TogglePinExclude()
    else
        ToggleTopUnderMouse()
}

; ---- CloseWindow / 关闭分发 ----
CloseWindowDispatch(*) {
    if WTM.Active
        WTM.CloseFocused()
    else
        CloseWindowUnderMouse()
}

; ==============================================================================
; 6. Configuration Generation & Migration / 配置生成与迁移
; ==============================================================================

; ---- Strip # prefix from color values / 去除颜色值 # 前缀 ----
_StripHash(s) => (s != "" && SubStr(s, 1, 1) = "#") ? SubStr(s, 2) : s

; ---- CfgRead / 配置读取 ----
CfgRead(sec, key, defVal, fallbacks*) {
    global ConfigFile
    miss := "__WM_MISSING__"
    v := IniRead(ConfigFile, sec, key, miss)
    if (v != miss)
        return _StripHash(v)
    for fb in fallbacks {
        v := IniRead(ConfigFile, fb[1], fb[2], miss)
        if (v != miss)
            return _StripHash(v)
    }
    return defVal
}

; ---- ParseCustomItems / 自定义项 ----
ParseCustomItems(itemsRaw, iconRaw := "", textRaw := "") {
    out := []
    if (Trim(itemsRaw) != "") {
        for part in StrSplit(itemsRaw, ";") {
            part := UnescapeSpaces(Trim(part))
            if (part != "")
                out.Push(part)
        }
        return out
    }
    if (Trim(iconRaw) != "")
        out.Push(Trim(iconRaw))
    if (Trim(textRaw) != "")
        out.Push(Trim(textRaw))
    return out
}

; ---- Auto-migrate legacy key names (v2.9 unified to PascalCase) / 旧键名自动迁移 ----
RegExEscape(s) => RegExReplace(s, "([.*?+\[\]{}()|\\^$])", "\$1")

MigrateConfigKeys() {
    global ConfigFile
    if !FileExist(ConfigFile)
        return
    v := IniRead(ConfigFile, "General", "ConfigVersion", "0")
    if (v = "0" || v = "1")
        _MigrateV2(ConfigFile)
    if (v != "3")
        _MigrateV3(ConfigFile)
}

; ---- v2：旧键名统一为 PascalCase / v2: legacy key names -> PascalCase ----
_MigrateV2(ConfigFile) {
    renames := [["Bar","time_format","TimeFormat"],["Bar","date_format","DateFormat"]
        ,["Bar","custom_items","CustomItems"],["Bar","desktop_labels","DesktopLabels"]
        ,["Bar","current_desktop_left","CurrentDesktopLeft"],["Bar","current_desktop_right","CurrentDesktopRight"]
        ,["Bar","current_desktop_color","CurrentDesktopColor"],["Bar","desktop_display_mode","DesktopDisplayMode"]
        ,["Bar","position","Position"],["Bar","offset","Offset"]
        ,["Bar","margin_left","MarginLeft"],["Bar","margin_right","MarginRight"]
        ,["Bar","layout","Layout"],["Bar","instances","Instances"]]
    content := ""
    try content := FileRead(ConfigFile, "UTF-16")
    if (content = "")
        return
    migrated := 0
    for r in renames {
        sec := r[1], oldKey := r[2], newKey := r[3]
        secEsc := RegExEscape("[" sec "]")
        oldEsc := RegExEscape(oldKey)
        if RegExMatch(content, "is)(" secEsc "[^\[]*)", &secMatch) {
            secBlock := secMatch[1]
            if RegExMatch(secBlock, "im)^\s*" oldEsc "\s*=") && !InStr(secBlock, "`n" newKey "=") {
                newBlock := RegExReplace(secBlock, "im)^\s*" oldEsc "\s*=", newKey "=")
                content := StrReplace(content, secBlock, newBlock)
                migrated++
            }
        }
    }
    if (migrated > 0 || !InStr(content, "ConfigVersion=2")) {
        if RegExMatch(content, "is)(\[General\][^\[]*)", &genMatch) {
            genBlock := genMatch[1]
            if !InStr(genBlock, "`nConfigVersion=") {
                newGen := RTrim(genBlock, "`r`n") "`r`nConfigVersion=2`r`n"
                content := StrReplace(content, genBlock, newGen)
            }
        }
        try {
            FileDelete(ConfigFile)
            FileAppend(content, ConfigFile, "UTF-16")
        }
    }
}

; ---- v3：PauseOnFullscreen on/off → all/bar 三态 / v3: pause mode becomes 3-state ----
_MigrateV3(ConfigFile) {
    content := ""
    try content := FileRead(ConfigFile, "UTF-16")
    if (content = "")
        return
    newContent := RegExReplace(content, "im)^(\s*PauseOnFullscreen\s*=\s*)on\s*$", "$1all")
    newContent := RegExReplace(newContent, "im)^(\s*ConfigVersion\s*=\s*)\d+\s*$", "${1}3")
    if !RegExMatch(newContent, "im)^\s*ConfigVersion\s*=") {
        if RegExMatch(newContent, "is)(\[General\][^\[]*)", &gm) {
            gb := gm[1]
            newContent := StrReplace(newContent, gb, RTrim(gb, "`r`n") "`r`nConfigVersion=3`r`n")
        }
    }
    if (newContent = content)
        return
    try {
        FileDelete(ConfigFile)
        FileAppend(newContent, ConfigFile, "UTF-16")
    }
}

_ConfigWrite(section, key, val) {
    global ConfigFile
    content := ""
    try content := FileRead(ConfigFile, "UTF-16")
    if (content = "")
        return
    secEsc := RegExEscape("[" section "]")
    keyEsc := RegExEscape(key)
    if RegExMatch(content, "is)(" secEsc "[^\[]*)", &secMatch) {
        secBlock := secMatch[1]
        if RegExMatch(secBlock, "im)^\s*" keyEsc "\s*=.*$") {
            newBlock := RegExReplace(secBlock, "im)^\s*" keyEsc "\s*=.*$", key "=" val)
            content := StrReplace(content, secBlock, newBlock)
        } else {
            newBlock := RTrim(secBlock, "`r`n") "`r`n" key "=" val "`r`n"
            content := StrReplace(content, secBlock, newBlock)
        }
    } else {
        content := RTrim(content, "`r`n") "`r`n`r`n[" section "]`r`n" key "=" val "`r`n"
    }
    try {
        FileDelete(ConfigFile)
        FileAppend(content, ConfigFile, "UTF-16")
    }
}

; ==============================================================================
; 7. Configuration Loading & Parsing / 配置读取与解析
; ==============================================================================

; ---- SanitizeConfigEncoding / 修复配置文件编码 ----
SanitizeConfigEncoding() {
    global ConfigFile
    raw := ""
    try raw := FileRead(ConfigFile)
    if !InStr(raw, Chr(0xFFFD)) && !InStr(raw, "��")
        return
    WMLog("Config encoding corrupted, repairing...")
    sections := ["General","Theme","Paths","Desktop","Bar","Border","Tiling","Snapping",
                 "PieMenu","GUI","WorkTime","Exclude","WinSelect","WinSelectSidebar","Hotkeys"]
    backup := Map()
    for sec in sections {
        backup[sec] := Map()
        try {
            allKeys := IniRead(ConfigFile, sec)
            if (allKeys = "")
                continue
            for line in StrSplit(allKeys, "`n", "`r") {
                if RegExMatch(line, "^([^=]+)=(.*)$", &m)
                    backup[sec][Trim(m[1])] := m[2]
            }
        }
    }
    newContent := ";==========================================================================`r`n"
        . "; AHK WM Configuration — auto-repaired`r`n"
        . ";==========================================================================`r`n`r`n"
    for sec in sections {
        if backup[sec].Count = 0
            continue
        newContent .= "[" sec "]`r`n"
        for key, val in backup[sec]
            newContent .= key "=" val "`r`n"
        newContent .= "`r`n"
    }
    try {
        FileDelete(ConfigFile)
        FileAppend(newContent, ConfigFile, "UTF-16")
        WMLog("Config repaired and saved as UTF-8")
    }
}

; ---- LoadOrInitConfig / 配置加载 ----
LoadOrInitConfig() {
    global

    if !DirExist(ConfigDir) {
        try DirCreate(ConfigDir)
        catch Error as e {
            MsgBox("Failed to create config directory:`n" . ConfigDir . "`n`n" . e.Message)
            ExitApp
        }
    }

    DefaultIni := "
    (
;==========================================================================
; AHK WM Configuration / AHK WM 配置文件
;==========================================================================

[General]
; Theme name; see docs/config-reference.md for the full list / 主题名称
; custom, nord, tokyonight, dracula, gruvbox, monokai, solarized-dark,
; solarized-light, catppuccin-mocha, catppuccin-latte, onedark, ayu-dark,
; github-dark, rose-pine, everforest, kanagawa, material-deep, nightfox,
; palenight, horizon, oxocarbon.
ActiveTheme=custom
; Font name; a Nerd Font is needed for icons / 字体名称（图标需 Nerd Font）
FontName=Segoe UI
; Transparency step / 透明度步长
TransparencyStep=10
; Pause on fullscreen: all | bar | off (default bar) / 全屏时暂停
;   all = any monitor going fullscreen pauses the script / 任意屏全屏都暂停
;   bar = only bar-owning monitors go fullscreen pause it / 只有配了 bar 的屏才暂停
;   off = never pause / 从不暂停
; Legacy on == all; migrated automatically / 旧值 on 等价 all，自动迁移
PauseOnFullscreen=bar

[Theme]
; All colors support gradients / 颜色支持渐变
Background=#0e050f
Text=#e5e9f0
Active=#744da9
BorderDrag=#A020F0,#CBA6F7
BorderPin=#FF5555
BorderUnfocus=#666666
PowerMenuBg=#2E3440
PowerBtnShutdown=#B48EAD
PowerBtnSleep=#5E81AC
PowerBtnReboot=#BF616A
; Per-component overrides (default = base color) / 组件专属色

[Paths]
; Button scripts directory / 按钮脚本目录
ButtonDir=Buttons
; Clipboard output directory / 剪贴板输出目录
OutputDir=%OUTPUTDIR%
; Clipboard file name / 剪贴板文件名
OutputFile=CB.txt
; Editor executable / 编辑器
VimPath=C:\Windows\system32\notepad.exe
; Terminal executable / 终端
TerminalExe=C:\Windows\system32\cmd.exe
; Editor geometry, screen percent / 编辑器窗口位置与尺寸（屏宽高百分比）
EditorXPct=20
EditorYPct=0
EditorWidthPct=52
EditorHeightPct=74

[Desktop]
; Virtual desktop count: 1-9 / 虚拟桌面数量
Count=9
; Inactive-desktop handling: minimize | hide / 非当前桌面的处理
HideMethod=minimize

[Bar]
; Bar height, percent of screen height / 栏高（屏高百分比）
HeightPct=3
; Opacity, 0-100 / 不透明度
Opacity=78
; Font size / 字号
FontSize=10
; Monitor index / 显示器编号
MonitorIdx=1
; Clock format, FormatTime pattern / 时间格式
TimeFormat=HH:mm
; Date format, FormatTime pattern / 日期格式
DateFormat=yyyy-MM-dd
; Custom items, ";"-separated / 自定义内容
CustomItems=✐ Edit config to hide
; Desktop labels, ","-separated / 桌面名称
DesktopLabels=Work,Net
; Current-desktop tags (use \s for a literal space) / 当前桌面标记（\s 转义空格）
CurrentDesktopLeft=[
CurrentDesktopRight=]
; Current-desktop highlight, same format as Layout; empty disables / 当前桌面高亮，留空关闭
CurrentDesktopColor=
; Desktop display mode: all | current | occupied / 桌面显示模式
DesktopDisplayMode=all
; Edge position: top | bottom / 栏位置
Position=top
; Edge offset in px / 边偏移
Offset=0
; Left / right margin in px / 左右边距
MarginLeft=0
MarginRight=0
;----------------------------------------------------------------------
; Element layout / 元素布局
;   N,element,span,c1..cn,bg|tx,on|off;...
;   N      = bar number (default 1) / 第几个 bar
;   span   = (a-c)/d; +d right-align, -d left-align, d center / 对齐方式
;   bg|tx  = gradient background / gradient text / 渐变底 / 渐变字
;   on|off = rounded corners in bg mode; colors are 6-hex, "#" optional
;   Legacy: element:span,color,... is still accepted / 旧写法兼容
;   Available: desktops, time, date, progress, wifi, battery, volume, disk,
;              mem, cpu, custom_1..n, external_1..n
;   external_N is text pushed by a script via WM_COPYDATA ("BAR:N:text"),
;   it persists until the next push / 外部脚本推送，推送后常驻
;   Example: 1,time,20/20,ff0000,00ff00,tx;desktops,(1-3)/-20,FAB387,bg,on;
;----------------------------------------------------------------------
Layout=custom_1,(4-7)/20,#B48EAD,#CF8DC9,bg,on;desktops,(1-3)/20;date,(18-19)/20;time,20/20,#744da9,#CF8DC9;progress,3/5,#744da9,#e5e9f0;
; Multi-bar instances: M,pos,offset;... M = monitor or "*" / 多栏实例
Instances=1,top,0
; Auto-hide on fullscreen: on | off / 全屏时自动隐藏
AutoHideOnFullscreen=on
; Rounded corners: on | off / 圆角开关
Rounded=on
CornerRadius=10
CornerMode=bottom

[Border]
; Refresh interval in ms / 刷新间隔
RefreshMs=10
; Drag border: on | off / 拖拽边框开关
Enable=on
; Border mode: top | full / 边框模式
Mode=full
; Thickness / 厚度
Thickness=35
; Offset / 内缩
Offset=15
; Top offset / 顶部内缩
OffsetTop=5
; Opacity, 0-100 / 不透明度
Opacity=80
; Rounded corners: on | off / 圆角开关
RoundedCorners=on
; Corner radius in px / 圆角半径
Radius=10
; Corner mode: all | top | bottom / 圆角模式
CornerMode=all
; WTM tiling gap in px / WTM 平铺间隙
Gap=10
; WTM resize step / WTM 调整步长
SizeStep=3
; Pin indicator mode / 置顶指示模式
PinMode=top
; Pin thickness / 置顶指示厚度
PinThickness=35
; Pin offset / 置顶指示内缩
PinOffset=0
; Pin top offset / 置顶指示顶部内缩
PinOffsetTop=5
; Pin opacity / 置顶指示不透明度
PinOpacity=90
; Pin rounded: on | off / 置顶指示圆角
PinRounded=off
; Pin corner radius / 置顶指示圆角半径
PinRadius=0

[Tiling]
; Smart-tile gap in px, may be negative / 智能平铺间隙，可为负
Gap=15
; WTM gap in px; empty falls back to [Border] Gap / WTM 间隙，留空回落到 [Border] Gap
WTMGap=
; Move/resize animation in ms, 0 = instant / 平铺动画时长，0 为关闭
AnimationDuration=0
; WTM resize step in px; each edge moves half of it / WTM 缩放步长，每条边走一半
ResizeStep=20
; Tile always-on-top windows / 置顶窗口是否参与平铺
TileAlwaysOnTop=off
; Scrollable tiling desktops, e.g. 1;3; empty = off / 无限滚动平铺桌面
ScrollableDesktops=
; Custom layout rules: M,N,I,X,Y;... (full docs in docs/config-reference.md)
;   M = monitor ("*" = all), N = window count, I = window index
;   X/Y span: 1 = full, a/b = one segment, (a-c)/b = several segments
;   Exact monitor beats "*"; both beat the built-in layout / 精确屏 > * > 内置布局
;   Example: 1,3,1,1/2,1 = 3 windows on monitor 1; #1 is the left half, full height
;     +-----------+-----------+
;     |           |  W#2 top  |
;     |   W#1     |-----------|
;     |           |  W#3 bot  |
;     +-----------+-----------+
Rules=1,3,1,1/2,1;1,3,2,2/2,1/2;1,3,3,2/2,2/2;1,5,1,(2-4)/5,1;1,5,2,1/5,1/2;1,5,3,1/5,2/2;1,5,4,5/5,(1-2)/3;1,5,5,5/5,3/3;

[Snapping]
; Snap: on | off / 吸附开关
Enable=on
; Snap trigger distance in px / 触发距离
Distance=0
; Snap release distance in px / 脱离距离
Release=5

[PieMenu]
; Pie menu size, percent of the screen's short side / 功能环尺寸
SizePct=28
; Center dead zone in percent / 中心死区
CenterZonePct=27
; Opacity, 0-100 / 不透明度
Opacity=78
; Font size / 字号
FontSize=14
; Active-sector font size / 激活扇区字号
FontSizeActive=22

[GUI]
; Global rounded corners: on | off / 全局圆角开关
RoundedCorners=on
; Global corner radius / 全局圆角半径
CornerRadius=12
; Help font size / 帮助界面字号
HelpFontSize=10
; Help width in px / 帮助界面宽度
HelpWidth=620
; Help height in px, 0 = auto / 帮助界面高度，0 为自适应
HelpHeight=0
; Help opacity / 帮助界面不透明度
HelpOpacity=100
; Power menu font size / 电源菜单字号
PowerFontSize=12
; Power menu width in px / 电源菜单宽度
PowerWidth=500
; Power menu height in px / 电源菜单高度
PowerHeight=160
; Power menu opacity / 电源菜单不透明度
PowerOpacity=100
; OSD vertical position in percent / OSD 垂直位置百分比
OSDPositionPct=80
; OSD opacity / OSD 不透明度
OSDOpacity=78
; OSD font size / OSD 字号
OSDFontSize=20

[WorkTime]
; Mode: off | workday | allday / 工作时间模式
Mode=off
; Weekend progress bar: on | off / 周末进度条
WeekendBar=off
; Work hours, HHMM / 工作时段
WorkStart=0900
WorkEnd=1745
; Task slots: weekday_start_end,color;... 1 = Mon .. 7 = Sun
;   Color is optional and falls back to the theme / 颜色可选，默认主题色
TaskTimes=1_1200_1300,#CDD6F4;2_1200_1300,#CDD6F4;3_1200_1300,#CDD6F4;4_1200_1300,#CDD6F4;5_1200_1300,#CDD6F4;6_1200_1300,#CDD6F4;7_1200_1300,#CDD6F4;2_1700_1745;3_0900_0920;1_1545_1600;2_1545_1600;3_1545_1600;4_1545_1600;5_1545_1600;1_1330_1500;

; Window exclusion rules moved out of this file -> exclude.ini
; 窗口排除规则已移出本文件，见同目录 exclude.ini
; A legacy [Exclude] section is migrated on first run / 旧 [Exclude] 段首次运行会自动迁移

[WinSelect]
; Scale ratio / 缩放比例
ScaleRatio=0.85
; Letter pool / 字母池
Letters=ASDFGHJKLQWERTYUIOPZXCVBNM
; Size map: N:ratio|WxH;... / 尺寸映射
SizeMap=1:0.5;2:0.8;3:1.2;9:1920x1080
; Label bar color, empty = theme / 标签条颜色，留空用主题色
BarColor=
TextColor=
; Label bar height in px; width 0 = window width / 标签条高度，宽度 0 为窗口宽度
Height=28
Width=0
; Label offset / 标签偏移
OffsetY=0
; Label font size / 标签字号
FontSize=14
; Opacity, 0-100 / 不透明度
Opacity=85
; Rounding: on | off / 圆角
Rounded=on
CornerRadius=10
CornerMode=top
; Auto-exit after N seconds, 0 = never / 无操作退出秒数，0 为不退出
Timeout=12

[WinSelectSidebar]
; Font size / 字号
FontSize=14
; Width / 宽度
Width=80
; Position: left | right / 位置
Position=left
OffsetX=10
OffsetY=0

[Clipboard]
; Max characters per history entry, 0 = unlimited / 单条历史上限字符数
MaxChars=100000
; Processes excluded from clipboard logging, ";"-separated
; Example: KeePass.exe;1Password.exe / 不记录的进程，可用 ; 分隔
ExcludeProcesses=
; Log binary clipboard info (paths / content type): on | off / 是否记录二进制内容信息
LogBinary=on

[Logging]
; Log file path; empty = config dir\wm.log / 日志路径，留空用配置目录
File=
; Log level: DEBUG | INFO | WARN | ERROR / 日志级别
Level=INFO
; Rotate the log above this size in KB, 0 = never / 超过该大小轮转，0 为不轮转
MaxSizeKB=512

;--------------------------------------------------------------------------
; Hotkeys: names joined by "+" / 热键，用 + 连接
; Modifiers: Alt / Shift / Ctrl / Win / 修饰键
;--------------------------------------------------------------------------

[Hotkeys]
Help=Alt+/
Exit=Alt+F12
Reload=Alt+R

DesktopSwitchPrefix=Alt
DesktopMovePrefix=Alt+Shift
DesktopMoveSwitchPrefix=Ctrl+Alt

TileSmart=Alt+D
GatherAll=Alt+Shift+G
TogglePin=Ctrl+Alt+T
; Toggle the status bar / 显隐状态栏
ToggleBar=Ctrl+Alt+B
; Copy current layout rules to the clipboard / 复制当前布局的规则串
SaveLayout=Alt+Shift+S
; Add the current window to the exclusions (exclude.ini) / 把当前窗口加入排除
ExcludeWindow=Alt+Shift+X
; Diagnose why a window is excluded; unbound by default / 诊断窗口是否被排除，默认不绑定
DiagnoseWindow=

CloseWindow=Alt+Q
CloseWindowAlt=Alt+MButton
ToggleMaximize=Alt+F
ToggleTop=Alt+T
HideWindow=Alt+W
TransparencyUp=Alt+WheelUp
TransparencyDown=Alt+WheelDown

SnapLeft=Alt+Left
SnapRight=Alt+Right
SnapUp=Alt+Up
SnapDown=Alt+Down

LaunchTerminal=Alt+Enter
EditFile=Alt+V
PowerMenu=Alt+X
ClipboardHistory=Ctrl+``

DragMove=Alt+LButton
DragResize=Alt+RButton

PieMenuTrigger=~Space & RButton

WinSelect=Alt+S

WTMToggle=Alt+Shift+D
WTMFocusLeft=Alt+H
WTMFocusDown=Alt+J
WTMFocusUp=Alt+K
WTMFocusRight=Alt+L
WTMMoveLeft=Alt+Shift+H
WTMMoveDown=Alt+Shift+J
WTMMoveUp=Alt+Shift+K
WTMMoveRight=Alt+Shift+L
WTMFull=Alt+F
WTMTrueMax=Alt+Shift+F
WTMOverview=Alt+O
WTMShrinkWidth=Ctrl+Alt+H
WTMGrowWidth=Ctrl+Alt+L
WTMGrowHeight=Ctrl+Alt+J
WTMShrinkHeight=Ctrl+Alt+K
    )"

    if !FileExist(ConfigFile) {
        tmpIni := StrReplace(DefaultIni, "%OUTPUTDIR%", A_MyDocuments)
        try {
            FileAppend(tmpIni, ConfigFile, "UTF-16")
        } catch Error as e {
            MsgBox("Failed to create config file: " . e.Message)
            ExitApp
        }
    } else {
        SanitizeConfigEncoding()
        MigrateConfigKeys()
    }

    ; ---- [Logging] (loaded early so later parse errors honour the config) / 日志配置 ----
    WM_LogFile := Trim(IniRead(ConfigFile, "Logging", "File", ""))
    if (WM_LogFile = "")
        WM_LogFile := ConfigDir . "\wm.log"
    WM_LogLevel := _WMLogLevelNum(IniRead(ConfigFile, "Logging", "Level", "INFO"))
    WM_LogMaxKB := Max(0, SafeInt(IniRead(ConfigFile, "Logging", "MaxSizeKB", "512"), 512))

    ActiveTheme := IniRead(ConfigFile, "General", "ActiveTheme", "custom")
    FontName    := IniRead(ConfigFile, "General", "FontName",    "Segoe UI")

    Color_Bg     := CfgRead("Theme", "Background", "0e050f", ["Colors","Background"])
    Color_Text   := CfgRead("Theme", "Text",       "e5e9f0", ["Colors","Text"])
    Color_Active := CfgRead("Theme", "Active",     "744da9", ["Colors","Active"])
    Color_Task   := CfgRead("Theme", "Task",       "CF8DC9", ["Colors","Task"])

    Border_FocusColor   := CfgRead("Theme", "BorderDrag",   "A020F0", ["Colors","BorderDrag"])
    Border_Pin_Color    := CfgRead("Theme", "BorderPin",    "FF5555", ["Colors","BorderPin"])
    Border_UnfocusColor := CfgRead("Theme", "BorderUnfocus","555555", ["Colors","BorderUnfocus"])
    Color_BorderUnfocus := Border_UnfocusColor
    Border_Drag_Color   := Border_FocusColor

    PM_Bg          := CfgRead("Theme", "PowerMenuBg",      "2E3440", ["Colors","PowerMenuBg"])
    PM_BtnShutdown := CfgRead("Theme", "PowerBtnShutdown", "B48EAD", ["Colors","PowerBtnShutdown"])
    PM_BtnSleep    := CfgRead("Theme", "PowerBtnSleep",    "5E81AC", ["Colors","PowerBtnSleep"])
    PM_BtnReboot   := CfgRead("Theme", "PowerBtnReboot",   "BF616A", ["Colors","PowerBtnReboot"])

    Bar_Height       := Pct2PxH(Integer(CfgRead("Bar", "HeightPct",  "3",  ["StatusBar","HeightPct"])))
    Bar_Transparent  := Pct2Alpha(Integer(CfgRead("Bar", "Opacity",  "78", ["StatusBar","Opacity"])))
    Bar_FontSize     := Integer(CfgRead("Bar", "FontSize",   "10", ["StatusBar","FontSize"]))
    Bar_MonitorIdx   := Integer(CfgRead("Bar", "MonitorIdx", "1",  ["StatusBar","MonitorIdx"]))
    Bar_MarginLeft   := Max(0, Integer(CfgRead("Bar", "MarginLeft",  "0", ["Bar","margin_left"])))
    Bar_MarginRight  := Max(0, Integer(CfgRead("Bar", "MarginRight", "0", ["Bar","margin_right"])))
    Bar_Rounded    := StrLower(Trim(IniRead(ConfigFile, "Bar", "Rounded", "off")))
    Bar_Radius     := Integer(IniRead(ConfigFile, "Bar", "CornerRadius", 10))
    Bar_CornerMode := StrLower(Trim(IniRead(ConfigFile, "Bar", "CornerMode", "bottom")))

    Pie_Size           := Pct2PxMin(Integer(IniRead(ConfigFile, "PieMenu", "SizePct",       "28")))
    Pie_Radius         := Pie_Size / 2
    Pie_CenterZone     := Round(Pie_Radius * Integer(IniRead(ConfigFile, "PieMenu", "CenterZonePct", "27")) / 100)
    Pie_Transparent    := Pct2Alpha(Integer(IniRead(ConfigFile, "PieMenu", "Opacity",       "78")))
    Pie_FontSize       := Integer(IniRead(ConfigFile, "PieMenu", "FontSize",       "14"))
    Pie_FontSizeActive := Integer(IniRead(ConfigFile, "PieMenu", "FontSizeActive", "22"))

    OSD_Height       := Pct2PxH(Integer(CfgRead("GUI", "OSDPositionPct", "80", ["OSD","PositionPct"])))
    OSD_Transparent  := Pct2Alpha(Integer(CfgRead("GUI", "OSDOpacity",   "78", ["OSD","Opacity"])))
    OSD_FontSize     := Integer(CfgRead("GUI", "OSDFontSize", "20", ["OSD","FontSize"]))

    Border_RefreshMs := Max(1, SafeInt(IniRead(ConfigFile, "Border", "RefreshMs", "10"), 10))

    TransparencyStep := Max(1, Min(50, SafeInt(IniRead(ConfigFile, "General", "TransparencyStep", "20"), 20)))
    PauseOnFullscreenMode := PauseModeRead(IniRead(ConfigFile, "General", "PauseOnFullscreen", "bar"), "bar")

    Border_Enable := CfgRead("Border", "Enable", "on", ["Border","DragEnable"], ["BorderDrag","Enable"])

    Border_Mode := StrLower(Trim(CfgRead("Border", "Mode", "full", ["Border","DragMode"], ["WTM","BorderMode"])))
    if !(Border_Mode = "top" || Border_Mode = "full")
        Border_Mode := "full"

    Border_FocusColor   := CfgRead("Theme", "BorderDrag",   "A020F0", ["Border","FocusColor"], ["Colors","BorderDrag"])
    Border_UnfocusColor := CfgRead("Theme", "BorderUnfocus", "555555", ["Border","UnfocusColor"], ["Colors","BorderUnfocus"])

    Border_Thickness := Pct2Border(SafeInt(CfgRead("Border", "Thickness", "8", ["WTM","BorderThickness"], ["Border","DragThickness"], ["BorderDrag","Thickness"]), 8))
    Border_Offset    := Pct2Border(SafeInt(CfgRead("Border", "Offset",    "0", ["WTM","BorderOffset"],    ["Border","DragOffset"],    ["BorderDrag","Offset"]), 0))
    Border_OffsetTop := Pct2Border(SafeInt(CfgRead("Border", "OffsetTop", "5", ["Border","DragOffsetTop"], ["BorderDrag","OffsetTop"]), 5))
    Border_Opacity   := Pct2Alpha(SafeInt(CfgRead("Border", "Opacity",   "80", ["WTM","BorderOpacity"],   ["Border","DragOpacity"],   ["BorderDrag","Opacity"]), 80))

    Border_Rounded := StrLower(Trim(CfgRead("Border", "RoundedCorners", "on", ["WTM","RoundedCorners"], ["Border","DragRounded"], ["BorderDrag","RoundedCorners"])))
    Border_Radius  := Max(0, SafeInt(CfgRead("Border", "Radius", "10", ["WTM","CornerRadius"], ["Border","DragRadius"], ["BorderDrag","CornerRadius"]), 10))

    Border_Gap      := SafeInt(CfgRead("Border", "Gap", "10", ["WTM","Gap"]), 10)
    Border_SizeStep := SafeInt(CfgRead("Border", "SizeStep", "3", ["WTM","SizeStep"]), 3)

    Border_Pin_Mode        := StrLower(IniRead(ConfigFile, "Border", "PinMode", "top"))
    if !(Border_Pin_Mode = "top" || Border_Pin_Mode = "full")
        Border_Pin_Mode := "top"
    Border_Pin_Thickness   := Pct2Border(SafeInt(CfgRead("Border", "PinThickness", "10", ["BorderPin","Thickness"]), 10))
    Border_Pin_Offset      := Pct2Border(SafeInt(CfgRead("Border", "PinOffset",    "0",  ["BorderPin","Offset"]), 0))
    Border_Pin_OffsetTop   := Pct2Border(SafeInt(CfgRead("Border", "PinOffsetTop", "5",  ["BorderPin","OffsetTop"]), 5))
    Border_Pin_Transparent := Pct2Alpha(SafeInt(CfgRead("Border", "PinOpacity",   "78", ["BorderPin","Opacity"]), 78))

    Tile_Gap         := Integer(CfgRead("Tiling", "Gap", "15", ["Layout","Gap"]))
    LayoutRules      := ParseLayoutRules(CfgRead("Tiling", "Rules", "", ["Layout","Rules"]))
    Tile_IncludeAlwaysOnTop := BarShown(IniRead(ConfigFile, "Tiling", "TileAlwaysOnTop", "off"))
    _wtmGapRaw := Trim(IniRead(ConfigFile, "Tiling", "WTMGap", ""))
    WTM_Gap    := (_wtmGapRaw = "") ? Border_Gap : SafeInt(_wtmGapRaw, Border_Gap)
    WTM_AnimMs := Max(0, SafeInt(IniRead(ConfigFile, "Tiling", "AnimationDuration", "0"), 0))
    WTM_Debug  := BarShown(IniRead(ConfigFile, "Tiling", "WTMDebug", "off"))
    WTM_ResizeStep := Max(1, SafeInt(IniRead(ConfigFile, "Tiling", "ResizeStep", "20"), 20))
    InvalidateSlotTables()

    Snap_Enable   := BarShown(IniRead(ConfigFile, "Snapping", "Enable", "on"))
    Snap_Distance := Integer(IniRead(ConfigFile, "Snapping", "Distance", "12"))
    Snap_Release  := Max(0, Integer(IniRead(ConfigFile, "Snapping", "Release", "8")))

    LoadExcludeRules()

    GUI_Rounded      := IniRead(ConfigFile, "GUI", "RoundedCorners", "on")
    GUI_CornerRadius := Max(0, Integer(IniRead(ConfigFile, "GUI", "CornerRadius", "12")))

    Help_Rounded := CfgRead("GUI", "HelpRounded", GUI_Rounded, ["HelpMenu","RoundedCorners"])
    Help_Radius  := Max(0, Integer(CfgRead("GUI", "HelpRadius", GUI_CornerRadius, ["HelpMenu","CornerRadius"])))
    PM_Rounded   := CfgRead("GUI", "PowerRounded", GUI_Rounded, ["PowerMenu","RoundedCorners"])
    PM_Radius    := Max(0, Integer(CfgRead("GUI", "PowerRadius", GUI_CornerRadius, ["PowerMenu","CornerRadius"])))
    OSD_Rounded  := CfgRead("GUI", "OSDRounded", GUI_Rounded, ["OSD","RoundedCorners"])
    OSD_Radius   := Max(0, Integer(CfgRead("GUI", "OSDRadius", GUI_CornerRadius, ["OSD","CornerRadius"])))

    Border_Pin_Rounded := StrLower(Trim(IniRead(ConfigFile, "Border", "PinRounded", "off")))
    Border_Pin_Radius  := Max(0, Integer(IniRead(ConfigFile, "Border", "PinRadius", "0")))

    Help_FontSize := Integer(CfgRead("GUI", "HelpFontSize", "10",  ["HelpMenu","FontSize"]))
    Help_Width    := Integer(CfgRead("GUI", "HelpWidth",    "620", ["HelpMenu","Width"]))
    Help_Height   := Max(0, Integer(CfgRead("GUI", "HelpHeight",   "0",   ["HelpMenu","Height"])))
    Help_Opacity  := Pct2Alpha(Integer(CfgRead("GUI", "HelpOpacity",  "100", ["HelpMenu","Opacity"])))

    PM_FontSize := Integer(CfgRead("GUI", "PowerFontSize", "12",  ["PowerMenu","FontSize"]))
    PM_Width    := Integer(CfgRead("GUI", "PowerWidth",    "500", ["PowerMenu","Width"]))
    PM_Height   := Integer(CfgRead("GUI", "PowerHeight",   "160", ["PowerMenu","Height"]))
    PM_Opacity  := Pct2Alpha(Integer(CfgRead("GUI", "PowerOpacity",  "100", ["PowerMenu","Opacity"])))

    DesktopCount := Integer(CfgRead("Desktop", "Count", "9", ["Desktops","Count"]))
    if (DesktopCount < 1)
        DesktopCount := 1
    if (DesktopCount > 9)
        DesktopCount := 9
    WTM_ScrollDesktops := ParseScrollDesktops(IniRead(ConfigFile, "Tiling", "ScrollableDesktops", ""), DesktopCount)
    Desktop_HideMethod := StrLower(CfgRead("Desktop", "HideMethod", "minimize", ["Desktops","HideMethod"]))
    if !(Desktop_HideMethod = "minimize" || Desktop_HideMethod = "hide")
        Desktop_HideMethod := "minimize"

    Bar_Cfg := Map()
    Bar_Cfg["layout"]       := ParseBarLayout(CfgRead("Bar", "Layout", "", ["Bar","layout"]))
    _bar1 := Bar_Cfg["layout"].Has(1) ? Bar_Cfg["layout"][1] : Map()
    for k in ["desktops","time","date","progress"]
        Bar_Cfg[k] := _bar1.Has(k)
    Bar_Cfg["time_format"]  := CfgRead("Bar", "TimeFormat", "HH:mm",      ["Bar","time_format"])
    Bar_Cfg["date_format"]  := CfgRead("Bar", "DateFormat", "yyyy-MM-dd", ["Bar","date_format"])
    Bar_Cfg["cur_left"]     := UnescapeSpaces(CfgRead("Bar", "CurrentDesktopLeft",  "[", ["Bar","current_desktop_left"]))
    Bar_Cfg["cur_right"]    := UnescapeSpaces(CfgRead("Bar", "CurrentDesktopRight", "]", ["Bar","current_desktop_right"]))
    Bar_Cfg["cur_color"]    := CfgRead("Bar", "CurrentDesktopColor", "", ["Bar","current_desktop_color"])
    Bar_Cfg["display_mode"] := StrLower(CfgRead("Bar", "DesktopDisplayMode", "all", ["Bar","desktop_display_mode"]))
    Bar_Cfg["position"]     := StrLower(CfgRead("Bar", "Position", "top", ["Bar","position"]))
    Bar_Cfg["offset"]       := SafeInt(CfgRead("Bar", "Offset", "0", ["Bar","offset"]), 0)
    Bar_Cfg["instances"]    := CfgRead("Bar", "Instances", "", ["Bar","instances"])

    Bar_Cfg["custom_items"] := ParseCustomItems(
        CfgRead("Bar", "CustomItems", "", ["Bar","custom_items"]),
        IniRead(ConfigFile, "Bar", "custom_icon",  ""),
        IniRead(ConfigFile, "Bar", "custom_text",  ""))

    Bar_AutoHide := BarShown(IniRead(ConfigFile, "Bar", "AutoHideOnFullscreen", "off"))

    ; ---- [Clipboard] / 剪贴板模块 ----
    Clip_MaxChars     := Max(0, SafeInt(IniRead(ConfigFile, "Clipboard", "MaxChars", "100000"), 100000))
    Clip_ExcludeProcs := SplitExcludeList(IniRead(ConfigFile, "Clipboard", "ExcludeProcesses", ""))
    Clip_LogBinary    := BoolCfg(IniRead(ConfigFile, "Clipboard", "LogBinary", "on"))

    barLabelsRaw := CfgRead("Bar", "DesktopLabels", "", ["Bar","desktop_labels"])
    barLabels := []
    if (Trim(barLabelsRaw) != "") {
        for lbl in StrSplit(barLabelsRaw, ",")
            barLabels.Push(Trim(lbl))
    }
    Bar_Cfg["desktop_labels"] := barLabels

    bDirTemp        := IniRead(ConfigFile, "Paths", "ButtonDir",  "Buttons")
    Path_Button     := (bDirTemp ~= "^[a-zA-Z]:") ? bDirTemp : (A_ScriptDir . "\" . bDirTemp)
    Path_Output     := Trim(IniRead(ConfigFile, "Paths", "OutputDir", A_MyDocuments))
    Path_Output := RegExReplace(Path_Output, "i)%OUTPUTDIR%", A_MyDocuments)
    if (Path_Output = "" || InStr(Path_Output, "%"))
        Path_Output := A_MyDocuments
    outFileCfg      := Trim(IniRead(ConfigFile, "Paths", "OutputFile", "CB.txt"))
    if (outFileCfg = "")
        outFileCfg := "CB.txt"
    Path_OutputFile := (outFileCfg ~= "^[a-zA-Z]:|^\\\\") ? outFileCfg : (Path_Output . "\" . outFileCfg)
    Path_Vim        := IniRead(ConfigFile, "Paths", "VimPath",     "C:\Windows\system32\notepad.exe")
    Path_Terminal   := IniRead(ConfigFile, "Paths", "TerminalExe", "C:\Windows\system32\cmd.exe")

    Vim_X      := Pct2PxW(Integer(CfgRead("Paths", "EditorXPct",      "20", ["VimLayout","XPct"])))
    Vim_Y      := Pct2PxH(Integer(CfgRead("Paths", "EditorYPct",      "0",  ["VimLayout","YPct"])))
    Vim_Width  := Pct2PxW(Integer(CfgRead("Paths", "EditorWidthPct",  "52", ["VimLayout","WidthPct"])))
    Vim_Height := Pct2PxH(Integer(CfgRead("Paths", "EditorHeightPct", "74", ["VimLayout","HeightPct"])))

    Work_Mode       := IniRead(ConfigFile, "WorkTime", "Mode",       "off")
    Work_WeekendBar := IniRead(ConfigFile, "WorkTime", "WeekendBar", "off")
    Work_Start      := IniRead(ConfigFile, "WorkTime", "WorkStart",  "0900")
    Work_End        := IniRead(ConfigFile, "WorkTime", "WorkEnd",    "1745")
    Work_TaskTimes  := IniRead(ConfigFile, "WorkTime", "TaskTimes",  "")

    WS_Scale := 0.85
    wsScaleRaw := Trim(IniRead(ConfigFile, "WinSelect", "ScaleRatio", "0.85"))
    if IsNumber(wsScaleRaw)
        WS_Scale := Max(0.2, Min(1.0, wsScaleRaw + 0))
    WS_Letters := StrUpper(RegExReplace(IniRead(ConfigFile, "WinSelect", "Letters", "ASDFGHJKLQWERTYUIOPZXCVBNM"), "[^A-Za-z]"))
    if (WS_Letters = "")
        WS_Letters := "ASDFGHJKLQWERTYUIOPZXCVBNM"
    WS_SizeMap   := ParseWinSelectSizeMap(IniRead(ConfigFile, "WinSelect", "SizeMap", "1:0.5;2:0.8;3:1.2;9:1920x1080"))
    WS_BarColor  := Trim(IniRead(ConfigFile, "WinSelect", "BarColor",  Color_Bg))
    WS_TextColor := Trim(IniRead(ConfigFile, "WinSelect", "TextColor", Color_Active))
    WS_BarHeight := Max(16, SafeInt(IniRead(ConfigFile, "WinSelect", "Height", "28"), 28))
    WS_BarWidth  := Max(0,  SafeInt(IniRead(ConfigFile, "WinSelect", "Width",  "0"),  0))
    WS_OffsetY   := SafeInt(IniRead(ConfigFile, "WinSelect", "OffsetY", "8"), 8)
    WS_FontSize  := Max(6,  SafeInt(IniRead(ConfigFile, "WinSelect", "FontSize", "14"), 14))
    WS_Opacity   := Pct2Alpha(SafeInt(IniRead(ConfigFile, "WinSelect", "Opacity", "85"), 85))
    WS_Rounded   := StrLower(Trim(IniRead(ConfigFile, "WinSelect", "Rounded", "on")))
    WS_Radius    := Max(0, SafeInt(IniRead(ConfigFile, "WinSelect", "CornerRadius", "10"), 10))
    WS_CornerMode := StrLower(Trim(IniRead(ConfigFile, "WinSelect", "CornerMode", "top")))
    WS_Timeout   := Max(0, SafeInt(IniRead(ConfigFile, "WinSelect", "Timeout", "12"), 12))

    WS_Sidebar_FontSize := Max(8,  SafeInt(IniRead(ConfigFile, "WinSelectSidebar", "FontSize", "14"), 14))
    WS_Sidebar_Width   := Max(50, SafeInt(IniRead(ConfigFile, "WinSelectSidebar", "Width",   "80"), 80))
    WS_Sidebar_Position := StrLower(Trim(IniRead(ConfigFile, "WinSelectSidebar", "Position", "left")))
    if !(WS_Sidebar_Position = "left" || WS_Sidebar_Position = "right")
        WS_Sidebar_Position := "left"
    WS_Sidebar_OffsetX := SafeInt(IniRead(ConfigFile, "WinSelectSidebar", "OffsetX", "10"), 10)
    WS_Sidebar_OffsetY := SafeInt(IniRead(ConfigFile, "WinSelectSidebar", "OffsetY", "0"), 0)

    HK := Map()
    hkKeys := ["Help","Exit","Reload",
               "DesktopSwitchPrefix","DesktopMovePrefix","DesktopMoveSwitchPrefix",
               "TileSmart","GatherAll","TogglePin","ToggleBar","SaveLayout",
               "ExcludeWindow","DiagnoseWindow",
               "CloseWindow","CloseWindowAlt","ToggleMaximize","ToggleTop","HideWindow",
               "TransparencyUp","TransparencyDown",
               "SnapLeft","SnapRight","SnapUp","SnapDown",
               "LaunchTerminal","EditFile","PowerMenu","ClipboardHistory",
               "DragMove","DragResize","PieMenuTrigger","WinSelect",
               "WTMToggle","WTMFocusLeft","WTMFocusDown","WTMFocusUp","WTMFocusRight",
               "WTMMoveLeft","WTMMoveDown","WTMMoveUp","WTMMoveRight","WTMFull",
               "WTMTrueMax","WTMOverview",
               "WTMShrinkWidth","WTMGrowWidth","WTMGrowHeight","WTMShrinkHeight"]
    hkDefaults := Map(
        "Help","Alt+/","Exit","Alt+F12","Reload","Alt+R",
        "DesktopSwitchPrefix","Alt","DesktopMovePrefix","Alt+Shift","DesktopMoveSwitchPrefix","Ctrl+Alt",
        "TileSmart","Alt+D","GatherAll","Alt+Shift+G","TogglePin","Ctrl+Alt+T",
        "ToggleBar","Ctrl+Alt+B",
        "SaveLayout","Alt+Shift+S",
        "ExcludeWindow","Alt+Shift+X","DiagnoseWindow","",
        "CloseWindow","Alt+Q","CloseWindowAlt","Alt+MButton","ToggleMaximize","Alt+F",
        "ToggleTop","Alt+T","HideWindow","Alt+W",
        "TransparencyUp","Alt+WheelUp","TransparencyDown","Alt+WheelDown",
        "SnapLeft","Alt+Left","SnapRight","Alt+Right","SnapUp","Alt+Up","SnapDown","Alt+Down",
        "LaunchTerminal","Alt+Enter","EditFile","Alt+V","PowerMenu","Alt+X","ClipboardHistory","Ctrl+``",
        "DragMove","Alt+LButton","DragResize","Alt+RButton","PieMenuTrigger","~Space & RButton",
        "WinSelect","Alt+S",
        "WTMToggle","Alt+Shift+D",
        "WTMFocusLeft","Alt+H","WTMFocusDown","Alt+J","WTMFocusUp","Alt+K","WTMFocusRight","Alt+L",
        "WTMMoveLeft","Alt+Shift+H","WTMMoveDown","Alt+Shift+J",
        "WTMMoveUp","Alt+Shift+K","WTMMoveRight","Alt+Shift+L",
        "WTMFull","Alt+F","WTMTrueMax","Alt+Shift+F","WTMOverview","Alt+O",
        "WTMShrinkWidth","Ctrl+Alt+H","WTMGrowWidth","Ctrl+Alt+L",
        "WTMGrowHeight","Ctrl+Alt+J","WTMShrinkHeight","Ctrl+Alt+K"
    )
    for k in hkKeys {
        raw := IniRead(ConfigFile, "Hotkeys", k, hkDefaults[k])
        if (k = "WTMFull" && NormalizeHotkey(raw) = NormalizeHotkey("Alt+Shift+F"))
            raw := "Alt+F"
        if InStr(k, "Prefix") {
            HK[k] := NormalizeModifiersOnly(raw)
        } else {
            HK[k] := NormalizeHotkey(raw)
        }
    }

    if (ActiveTheme = "wallpaper") {
        wpFile := ConfigDir "\wallpaper_theme.ini"
        if FileExist(wpFile) {
            Color_Bg     := _StripHash(IniRead(wpFile, "Theme", "Background",       Color_Bg))
            Color_Text   := _StripHash(IniRead(wpFile, "Theme", "Text",             Color_Text))
            Color_Active := _StripHash(IniRead(wpFile, "Theme", "Active",           Color_Active))
            Color_Task   := _StripHash(IniRead(wpFile, "Theme", "Task",             Color_Task))
            Border_FocusColor   := _StripHash(IniRead(wpFile, "Theme", "BorderDrag",    Border_FocusColor))
            Border_Pin_Color    := _StripHash(IniRead(wpFile, "Theme", "BorderPin",     Border_Pin_Color))
            Border_UnfocusColor := _StripHash(IniRead(wpFile, "Theme", "BorderUnfocus", Border_UnfocusColor))
            PM_Bg          := _StripHash(IniRead(wpFile, "Theme", "PowerMenuBg",      PM_Bg))
            PM_BtnShutdown := _StripHash(IniRead(wpFile, "Theme", "PowerBtnShutdown", PM_BtnShutdown))
            PM_BtnSleep    := _StripHash(IniRead(wpFile, "Theme", "PowerBtnSleep",    PM_BtnSleep))
            PM_BtnReboot   := _StripHash(IniRead(wpFile, "Theme", "PowerBtnReboot",   PM_BtnReboot))
        }
    } else if (ActiveTheme != "custom" && Themes.Has(ActiveTheme)) {
        palette := Themes[ActiveTheme]
        for key, val in palette
            try %key% := val
    }

    if (Bar_MonitorIdx < 1 || Bar_MonitorIdx > MonitorGetCount())
        Bar_MonitorIdx := 1
}

; ---- Parse [WinSelect] SizeMap / 尺寸映射 ----
ParseWinSelectSizeMap(str) {
    out := Map()
    for clause in StrSplit(str, ";") {
        clause := Trim(clause)
        if (clause = "")
            continue
        p := StrSplit(clause, ":")
        if (p.Length != 2) {
            WMLog("WinSelect SizeMap skipped (format): " clause)
            continue
        }
        k := Trim(p[1]), v := Trim(p[2])
        if !(StrLen(k) = 1 && IsDigit(k)) {
            WMLog("WinSelect SizeMap skipped (key not a digit): " clause)
            continue
        }
        if RegExMatch(v, "i)^(\d+)\s*x\s*(\d+)$", &m) {
            out[k] := {type:"abs", w:Max(100, Integer(m[1])), h:Max(80, Integer(m[2]))}
        } else if IsNumber(v) {
            r := v + 0
            if (r > 0.05 && r <= 10)
                out[k] := {type:"ratio", r:r}
            else
                WMLog("WinSelect SizeMap skipped (ratio out of range): " clause)
        } else {
            WMLog("WinSelect SizeMap skipped (bad value): " clause)
        }
    }
    return out
}

; ==============================================================================
; 8. Common GUI (Help / Welcome / Buttons / OSD) / 通用界面
; ==============================================================================

; ---- Destroy transient GUIs / 临时清理 ----
DestroyTransientGuis() {
    global HelpGuiObj, PowerMenuObj
    try {
        if IsObject(HelpGuiObj) {
            HelpGuiObj.Destroy()
            HelpGuiObj := ""
        }
    }
    try {
        if IsObject(PowerMenuObj) {
            PowerMenuObj.Destroy()
            PowerMenuObj := ""
        }
    }
    if PieMenu.IsActive {
        PieMenu.IsActive := false
        if !GetKeyState("RButton", "P")
            PieMenu.PendingRUp := false
        try SetTimer(PieMenu.TimerFn, 0)
        try {
            if IsObject(PieMenu.GuiObj)
                PieMenu.GuiObj.Destroy()
        }
    }
    try {
        if WinSelect.Active
            WinSelect.Cancel()
    }
    try {
        if IsObject(OSD.GuiObj) {
            OSD.GuiObj.Destroy()
            OSD.GuiObj := 0
        }
    }
    try DragBorder.Destroy()
}

; ---- Help GUI / 帮助界面 ----
ShowHelpGui(*) {
    global HelpGuiObj, HK
    global Help_FontSize, Help_Width, Help_Height, Help_Opacity, Help_Rounded, Help_Radius

    CloseWatcher() {
        if !IsObject(HelpGuiObj) {
            SetTimer CloseWatcher, 0
            return
        }
        if GetKeyState("Escape", "P") || GetKeyState("LButton", "P") {
            try HelpGuiObj.Destroy()
            HelpGuiObj := ""
            SetTimer CloseWatcher, 0
        }
    }

    if IsObject(HelpGuiObj) {
        HelpGuiObj.Destroy()
        HelpGuiObj := ""
        return
    }

    fsc  := Help_FontSize / 10.0
    wsc  := Help_Width / 620.0
    fullW := Round(620 * wsc)
    rowH  := Round(23 * fsc)

    helpGui := Gui("-Caption +AlwaysOnTop +ToolWindow -DPIScale +Owner")
    helpGui.BackColor := Color_Bg
    helpGui.SetFont("s" Round(20*fsc) " w700 c" . Color_Active, FontName)
    helpGui.Add("Text", "x0 y" Round(20*fsc) " w" fullW " Center", "HELP")
    helpGui.SetFont("s" Help_FontSize " w700 c" . Color_Active, FontName)
    helpGui.Add("Text", "x0 y" Round(60*fsc) " w" fullW " Center", "Natural-language hotkeys (Alt / Shift / Ctrl / Win + key)")

    helpGui.SetFont("s" Help_FontSize " w600 c" . Color_Active)
    helpGui.Add("Text", "x" Round(50*wsc) " y" Round(90*fsc) " w" Round(545*wsc) " h5 0x10")

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
        [PrefP("WTMFull"),                    "WTM Fullscreen (keep bar+border)"],
        [PrefP("WTMTrueMax"),                 "WTM Maximize (ignore bar)"],
        [PrefP("WTMOverview"),                "WTM Overview"],
        [PrefP("WTMShrinkWidth") . " / " . PrefP("WTMGrowWidth"), "WTM Resize Width (H/L)"],
        [PrefP("WTMGrowHeight") . " / " . PrefP("WTMShrinkHeight"), "WTM Resize Height (J/K)"],
        [PrefP("WinSelect"),                  "Window Select Mode"],
        [PrefP("DragMove"),                   "Drag Move Window"],
        [PrefP("DragResize"),                 "Drag Resize Window"],
        [PrefP("TransparencyUp") . " / " . PrefP("TransparencyDown"), "Window Transparency"],
        [PrefP("SnapLeft") . " / " . PrefP("SnapRight"), "Snap Left / Right"],
        [PrefP("SnapUp")   . " / " . PrefP("SnapDown"),  "Maximize / Minimize"],
        [PrefP("SaveLayout"),                 "Copy Layout Rules to Clipboard"],
        [PrefP("ExcludeWindow"),              "Exclude Current Window (add rule)"],
        [PrefP("DiagnoseWindow"),             "Diagnose Window Exclusions"],
        [PrefP("GatherAll"),                  "Gather All Windows"],
        [PrefP("CloseWindow"),                "Close Window"],
        [PrefP("TileSmart"),                  "Smart Tile (current monitor)"],
        [PrefP("HideWindow"),                 "Minimize Window"],
        [PrefP("ToggleMaximize"),             "Maximize / Restore"],
        [PrefP("Reload"),                     "Reload Script"],
        [PrefP("ToggleTop"),                  "Toggle OnTop (or WTM exclude)"],
        [PrefP("TogglePin"),                  "Toggle Always Visible"],
        [PrefP("ToggleBar"),                  "Toggle Top Bar"],
        [PrefP("ClipboardHistory"),           "Clipboard History (Vim)"],
        [PrefP("EditFile"),                   "Edit Selected File"],
        [PrefP("LaunchTerminal"),             "Launch Terminal"],
        [PrefP("Exit"),                       "Safely Exit"],
        [PrefP("PowerMenu"),                  "Power Menu"]
    ]

    helpGui.SetFont("s" Help_FontSize " w400 c" . Color_Text)
    rowsStart := Round(110 * fsc)
    for i, item in shortcuts {
        yPos := rowsStart + (i-1)*rowH
        helpGui.Add("Text", "x" Round(60*wsc)  " y" yPos " w" Round(240*wsc) " c" . Color_Text, item[1])
        helpGui.Add("Text", "x" Round(300*wsc) " y" yPos " w" Round(300*wsc) " +Right", item[2])
    }

    showOpts := "Center"
    if (Help_Height > 0)
        showOpts .= " h" Help_Height
    helpGui.Show(showOpts)
    try WinSetTransparent(Help_Opacity, helpGui.Hwnd)
    RoundWindowEx(helpGui, Help_Rounded, Help_Radius)
    HelpGuiObj := helpGui
    SetTimer CloseWatcher, 50
}

; ---- Welcome screen / 欢迎屏 ----
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
        g.SetFont("s64 w800 c" . Color_Active, FontName)
        g.Add("Text", "x0 y" Round(vh*0.22) " w" vw " Center BackgroundTrans", "WM Script")

        g.SetFont("s18 w400 c" . Color_Text, FontName)
        g.Add("Text", "x0 y" Round(vh*0.35) " w" vw " Center BackgroundTrans"
            , "An AHK tiling window manager for Windows")

        g.Add("Text", "x" (cx-200) " y" Round(vh*0.40) " w400 h2 Background" Color_Active, "")

        g.SetFont("s13 w800 c" . Color_Text, "Consolas")
        infoLines := [
            "  >  9 Virtual Desktops          " . PrettifyHotkey(HK["DesktopSwitchPrefix"]) . " + 1-9",
            "  >  Smart Tiling                " . PrettifyHotkey(HK["TileSmart"]),
            "  >  WTM Mode (hyprland-like)    " . PrettifyHotkey(HK["WTMToggle"]),
            "  >  Window Snap                 " . PrettifyHotkey(HK["SnapLeft"]) . " etc.",
            "  >  Copy Layout Rules           " . PrettifyHotkey(HK["SaveLayout"]),
            "  >  Exclude Window              " . PrettifyHotkey(HK["ExcludeWindow"]),
            "  >  Help Menu                   " . PrettifyHotkey(HK["Help"])
        ]
        yStart := Round(vh * 0.46)
        for i, line in infoLines
            g.Add("Text", "x" (cx-280) " y" (yStart + (i-1)*32) " w860 BackgroundTrans c" Color_Text, line)

        g.SetFont("s11 w400 c" . Color_Text, "Consolas")
        g.Add("Text", "x0 y" Round(vh*0.78) " w" vw " Center BackgroundTrans"
            , "Config: " . ConfigFile)

        g.SetFont("s14 w600 c" . Color_Active, FontName)
        g.Add("Text", "x0 y" Round(vh*0.84) " w" vw " Center BackgroundTrans"
            , "Made with <3 by ZXW")

        g.SetFont("s10 w400 c" . Color_Text, FontName)
        g.Add("Text", "x0 y" Round(vh*0.88) " w" vw " Center BackgroundTrans"
            , "V" . WM_Version . "  ::  AutoHotkey v2")

        g.SetFont("s10 w600 c" . Color_Active, FontName)
        g.Add("Text", "x0 y" Round(vh*0.91) " w" vw " Center BackgroundTrans"
            , "GitHub: https://github.com/EngineeringMechanicsB/AHK_WM")

        g.SetFont("s11 w600 c" . Color_Active, FontName)
        hint := g.Add("Text", "x0 y" Round(vh*0.95) " w" vw " Center BackgroundTrans"
            , "[ Press any key or click to continue ]")

        g.Show(Format("x{} y{} w{} h{} NoActivate", vx, vy, vw, vh))
        WinSetTransparent(245, g.Hwnd)
        try WinSetAlwaysOnTop(1, g.Hwnd)
        try WinActivate(g.Hwnd)
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

; ---- Eight-direction button template init / 按钮模板 ----
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

; ---- On-screen display / 屏幕提示 ----
class OSD {
    static GuiObj := 0, Timer := 0
    static ExtGuis := Map()

    static _ParseOpts(optsStr) {
        m := Map()
        if (optsStr = "")
            return m
        for part in StrSplit(optsStr, ",") {
            part := Trim(part)
            if RegExMatch(part, "^([a-z]{1,4})=(.*)$", &kv)
                m[kv[1]] := Trim(kv[2])
        }
        return m
    }

    static Show(text, duration := 1000) {
        if IsObject(this.GuiObj) {
            try this.GuiObj.Destroy()
            this.GuiObj := 0
        }
        if this.Timer
            SetTimer(this.Timer, 0)

        MouseGetPos(&mx,)
        monIdx := GetMonitorIndexAtPoint(mx, OSD_Height)
        MonitorGet(monIdx, &mL, &mT, &mR, &mB)
        monW := mR - mL
        cx := (mL + mR) // 2

        fScale := OSD_FontSize / 20.0
        padX := Round(30 * fScale)
        padY := Round(12 * fScale)
        maxW := Round(monW * 0.85)

        g := Gui("+AlwaysOnTop -Caption +ToolWindow +Disabled +Owner -DPIScale")
        g.BackColor := Color_Bg
        g.SetFont("s" . OSD_FontSize . " w600 c" . Color_Active, FontName)
        g.Add("Text", "x" padX " y" padY " Center", text)

        g.Show(Format("NoActivate AutoSize Hide"))
        g.GetPos(, , &gw, &gh)
        if (gw > maxW) {
            g.Destroy()
            g := Gui("+AlwaysOnTop -Caption +ToolWindow +Disabled +Owner -DPIScale")
            g.BackColor := Color_Bg
            g.SetFont("s" . OSD_FontSize . " w600 c" . Color_Active, FontName)
            g.Add("Text", "x" padX " y" padY " w" (maxW - padX*2) " Center", text)
            g.Show(Format("NoActivate AutoSize Hide"))
            g.GetPos(, , &gw, &gh)
        }
        ; 底部会出屏就上移，否则长文本被屏幕下边缘截断
        ; Lift it when it would run past the monitor bottom, or long text gets clipped.
        yPos := OSD_Height
        if (yPos + gh > mB - 8)
            yPos := Max(mT + 8, mB - 8 - gh)
        g.Show(Format("NoActivate AutoSize x{} y{}", cx - gw//2, yPos))

        WinSetTransparent(OSD_Transparent, g.Hwnd)
        RoundWindowEx(g, OSD_Rounded, OSD_Radius)

        this.GuiObj := g
        this.Timer  := () => (IsObject(OSD.GuiObj) ? (OSD.GuiObj.Destroy(), OSD.GuiObj := 0) : 0)
        SetTimer(this.Timer, -duration)
    }

    static ShowExternal(text, duration := 1000, optsStr := "") {
        global OSD_FontSize, OSD_Transparent, OSD_Height, Color_Bg, Color_Active
        global OSD_Rounded, OSD_Radius
        o := OSD._ParseOpts(optsStr)

        ; ---- Per-element config: override wins, else fall back to globals / 逐项解析 ----
        fs       := o.Has("fs")  ? Max(6, Integer(o["fs"]))             : OSD_FontSize
        opPct    := o.Has("op")  ? Integer(o["op"])                      : 0
        opVal    := (opPct > 0)  ? Pct2Alpha(opPct)                      : OSD_Transparent
        bgCol    := o.Has("bg")  ? C1(o["bg"])                           : Color_Bg
        txCol    := o.Has("tx")  ? C1(o["tx"])                           : Color_Active
        maxWVal  := o.Has("wr")  ? Max(100, Integer(o["wr"]))           : 0
        roundOn  := o.Has("rd")  ? o["rd"]                               : OSD_Rounded
        roundRad := o.Has("rr")  ? Max(0, Integer(o["rr"]))              : OSD_Radius
        ff       := o.Has("fn")  ? o["fn"]                               : FontName

        MouseGetPos(&mx,)
        monIdx := GetMonitorIndexAtPoint(mx, OSD_Height)
        MonitorGet(monIdx, &mL, &mT, &mR, &mB)
        monW := mR - mL, monH := mB - mT
        cx := (mL + mR) // 2

        ; ---- x/y 定位（像素 / 百分比 / center），pos=N 旧版兼容 ----
        ; center = 画面居中；y 方向要等拿到 GUI 高度才能算，见下面的 yCenter。
        yCenter := false
        if o.Has("x") {
            xs := o["x"]
            if (xs = "center")
                xPos := cx
            else
                xPos := RegExMatch(xs, "^(\d+)%$", &xp) ? mL + Round(monW * Integer(xp[1]) / 100) : mL + Integer(xs)
        } else {
            xPos := cx
        }
        if o.Has("y") {
            ys := o["y"]
            if (ys = "center") {
                yCenter := true
                yPos := mT
            } else {
                yPos := RegExMatch(ys, "^(\d+)%$", &yp) ? mT + Round(monH * Integer(yp[1]) / 100) : mT + Integer(ys)
            }
        } else if o.Has("pos") {
            yPos := (Integer(o["pos"]) > 0) ? Pct2PxH(Integer(o["pos"])) : OSD_Height
        } else {
            yPos := OSD_Height
        }

        fScale := fs / 20.0
        padX := Round(30 * fScale)
        padY := Round(12 * fScale)
        maxW := (maxWVal > 0) ? maxWVal : Round(monW * 0.85)

        g := Gui("+AlwaysOnTop -Caption +ToolWindow +Disabled +Owner -DPIScale")
        g.BackColor := bgCol
        g.SetFont("s" . fs . " w600 c" . txCol, ff)
        g.Add("Text", "x" padX " y" padY " Center", text)

        g.Show(Format("NoActivate AutoSize Hide"))
        g.GetPos(, , &gw, &gh)
        if (gw > maxW) {
            g.Destroy()
            g := Gui("+AlwaysOnTop -Caption +ToolWindow +Disabled +Owner -DPIScale")
            g.BackColor := bgCol
            g.SetFont("s" . fs . " w600 c" . txCol, ff)
            g.Add("Text", "x" padX " y" padY " w" (maxW - padX*2) " Center", text)
            g.Show(Format("NoActivate AutoSize Hide"))
            g.GetPos(, , &gw, &gh)
        }
        if (yCenter)
            yPos := mT + (monH - gh) // 2
        ; 同上：只在真的超出屏幕时才修正 y，常规百分比定位不受影响
        ; Same idea: only correct y when it truly overflows, explicit placement stays put.
        if (yPos + gh > mB - 8)
            yPos := Max(mT + 8, mB - 8 - gh)
        g.Show(Format("NoActivate AutoSize x{} y{}", xPos - gw//2, yPos))

        WinSetTransparent(opVal, g.Hwnd)
        RoundWindowEx(g, roundOn, roundRad)

        ; ---- tag 机制：同 tag 的旧 OSD 先销毁（实现替换式更新）----
        tagVal := o.Has("tag") ? o["tag"] : ""
        if (tagVal != "") {
            for eid, eg in OSD.ExtGuis {
                try {
                    if (eg.HasProp("_tag") && eg._tag = tagVal) {
                        eg.Destroy()
                        OSD.ExtGuis.Delete(eid)
                    }
                }
            }
        }

        ; ---- Register into the external instance table; self-destructing / 注册到外部实例表 ----
        extId := Format("ext_{:04d}", A_TickCount & 0xFFFF)
        g._tag := tagVal
        OSD.ExtGuis[extId] := g
        fn := ObjBindMethod(OSD, "_DestroyExt", extId)
        SetTimer(fn, -duration)
        return extId
    }

    static _DestroyExt(extId) {
        if !OSD.ExtGuis.Has(extId)
            return
        try OSD.ExtGuis[extId].Destroy()
        OSD.ExtGuis.Delete(extId)
    }
}

; ---- OSD shorthand / OSD快捷（内部调用，始终用配置）----
ShowOSD(text, duration := 1000) => OSD.Show(text, duration)

; ---- External interface via WM_COPYDATA / 外部消息接口 ----
OnMessage(0x4A, _WM_OnCopyData)

_WM_OnCopyData(wParam, lParam, msgNum, hwnd) {
    global Bar_ExternalData
    cds := lParam
    cbData := NumGet(cds, A_PtrSize, "UInt")
    lpData := NumGet(cds, A_PtrSize * 2, "Ptr")
    if !lpData || !cbData
        return false
    text := RTrim(StrGet(lpData, cbData // 2, "UTF-16"), Chr(0))
    if (SubStr(text, 1, 4) = "OSD:") {
        payload := SubStr(text, 5)
        dur := 1000, optsStr := ""
        if RegExMatch(payload, "^(.*?):([a-z]{1,4}=.*)$", &mKv) {
            pre := mKv[1], optsStr := mKv[2]
            if RegExMatch(pre, "^(.*):(\d+)$", &mDur)
                payload := mDur[1], dur := Integer(mDur[2])
            else
                payload := pre
        } else if RegExMatch(payload, "^(.*):(\d+)$", &m) {
            payload := m[1], dur := Integer(m[2])
        }
        try OSD.ShowExternal(payload, dur, optsStr)
        return true
    }
    if RegExMatch(text, "s)^BAR:(\d+):(.*)$", &mBar) {
        slot := Integer(mBar[1])
        rest := mBar[2]
        ; ---- Self-contained format: BAR:slot:lo/hi:text[:opts] / 自包含格式 ----
        if RegExMatch(rest, "s)^([\d.]+)/([\d.]+):(.*)$", &mSc) {
            lo := mSc[1] + 0
            hi := mSc[2] + 0
            afterSpan := mSc[3]
            txt := afterSpan
            optsStr := ""
            if RegExMatch(afterSpan, "s)^(.*?):([a-z]{1,4}=.*)$", &mOpts) {
                txt := mOpts[1]
                optsStr := mOpts[2]
            }
            cfg := Bar_ExternalSlots.Has(slot) ? Bar_ExternalSlots[slot] : Map()
            cfg["lo"] := lo
            cfg["hi"] := hi
            if (optsStr != "") {
                for part in StrSplit(optsStr, ",") {
                    part := Trim(part)
                    if RegExMatch(part, "^([a-z]{1,4})=(.*)$", &kv2) {
                        cfg[kv2[1]] := Trim(kv2[2])
                    }
                }
            }
            Bar_ExternalSlots[slot] := cfg
            Bar_ExternalData[slot] := txt
            CreateStatusBar()
            UpdateExternalWidgets()
            return true
        }
        ; ---- Legacy format cleanup: BAR:slot:text / 旧格式清理 ----
        if (rest = "" && Bar_ExternalSlots.Has(slot)) {
            Bar_ExternalSlots.Delete(slot)
            Bar_ExternalData.Delete(slot)
            CreateStatusBar()
            return true
        }
        Bar_ExternalData[slot] := rest
        try UpdateExternalWidgets(slot)
        return true
    }
    return false
}

; ---- Refresh external widgets on all bars / 推送刷新所有 bar 的外部部件 ----
UpdateExternalWidgets(slot := 0) {
    global Bars
    if !IsSet(Bars)
        return
    for b in Bars
        try b.UpdateExternal(slot)
}

; ==============================================================================
; 9. Border System (BorderFrame / DragBorder / PinBorder) / 边框系统
; ==============================================================================

; ---- Hollow-frame border window / 空心边框 ----
class BorderFrame {
    Gui   := ""
    Color := ""
    Owner := 0
    LastW := -1, LastH := -1, LastT := -1, LastR := -1
    LastMode := ""
    LastPX := -99999, LastPY := -99999, LastPW := -1, LastPH := -1
    LastThk := -1, LastRadC := -1, LastPMode := ""
    _GbW := -1, _GbH := -1
    GradCols := []
    GradPic := ""
    BigGradBM := 0

    __New(color, opacity) {
        pc := ParseColor(color)
        g := Gui("-Caption +ToolWindow +E0x20 -DPIScale")
        g.BackColor := pc.first
        g.Show("NoActivate x-3000 y-3000 w10 h10")
        try g.Title := "AHKWM_BORDER"
        try WinSetTransparent(opacity, g.Hwnd)
        this.Gui      := g
        this.Color    := color
        this.GradCols := pc.isGrad ? pc.colors : []
        this.GradPic  := ""
    }

    SetColor(color) {
        if (this.Color = color)
            return
        pc := ParseColor(color)
        try {
            this.Gui.BackColor := pc.first
            WinRedraw(this.Gui.Hwnd)
        }
        this.Color    := color
        this.GradCols := pc.isGrad ? pc.colors : []
        this._GbW := -1, this._GbH := -1
        if IsObject(this.GradPic) {
            try this.GradPic.Destroy()
            this.GradPic := ""
        }
        this.LastPX := -99999, this.LastPY := -99999
        if (this.GradCols.Length > 1 && this.LastPW > 0)
            this._GradBg(this.LastPW, this.LastPMode = "top" ? this.LastThk : this.LastPH)
    }

    _GradBg(w, h) {
        if !(this.GradCols.Length > 1) && !this.BigGradBM
            return
        if (w = this._GbW && h = this._GbH)
            return
        this._GbW := w, this._GbH := h
        if this.BigGradBM {
            if IsObject(this.GradPic) {
                try this.GradPic.Move(0, 0, w, h)
            } else {
                this.GradPic := this.Gui.Add("Picture", "x0 y0 w" w " h" h, "HBITMAP:" this.BigGradBM)
            }
            return
        }
        oldPic := this.GradPic
        hBM := CreateGradient(w, h, 0, this.GradCols*)
        if hBM {
            this.GradPic := this.Gui.Add("Picture", "x0 y0 w" w " h" h, "HBITMAP:" hBM)
            if IsObject(oldPic) {
                try oldPic.Destroy()
                oldPic := ""
            }
        }
    }

    _ZOrder(insertAfter) {
        if (insertAfter = -1 || insertAfter = 0)
            return insertAfter
        prev := DllCall("GetWindow", "Ptr", insertAfter, "UInt", 3, "Ptr")
        while (prev) {
            ex := 0
            try ex := WinGetExStyle(prev)
            if !(ex & 0x8)
                break
            prev := DllCall("GetWindow", "Ptr", prev, "UInt", 3, "Ptr")
        }
        return prev ? prev : 0
    }

    Place(x, y, w, h, thickness, radius, opacity, mode := "full", insertAfter := -1) {
        if !IsObject(this.Gui)
            return
        t   := Max(1, Round(thickness))
        rad := Max(0, Round(radius))
        x := Round(x), y := Round(y)
        if (mode = "top") {
            w := Round(Max(t, w)), h := t
        } else {
            w := Round(Max(t*2 + 1, w)), h := Round(Max(t*2 + 1, h))
        }
        if (x = this.LastPX && y = this.LastPY && w = this.LastPW && h = this.LastPH
         && t = this.LastThk && rad = this.LastRadC && mode = this.LastPMode) {
            if (insertAfter != -1 && insertAfter != 0) {
                ins := this._ZOrder(insertAfter)
                try DllCall("SetWindowPos", "Ptr", this.Gui.Hwnd, "Ptr", ins
                    , "Int", 0, "Int", 0, "Int", 0, "Int", 0
                    , "UInt", 0x1 | 0x2 | 0x10 | 0x40)
            }
            return
        }
        this.LastPX := x, this.LastPY := y, this.LastPW := w, this.LastPH := h
        this.LastThk := t, this.LastRadC := rad, this.LastPMode := mode
        ins := this._ZOrder(insertAfter)
        if (insertAfter != -1) {
            exb := 0
            try exb := WinGetExStyle(this.Gui.Hwnd)
            if (exb & 0x8)
                try WinSetAlwaysOnTop(false, this.Gui.Hwnd)
        }
        this._GradBg(w, h)
        try DllCall("SetWindowPos", "Ptr", this.Gui.Hwnd, "Ptr", ins
            , "Int", x, "Int", y, "Int", w, "Int", h
            , "UInt", 0x10 | 0x40)
        if (mode = "top")
            this._ApplyTopRegion(w, t)
        else
            this._ApplyRegion(w, h, t, rad)
    }

    _ApplyTopRegion(w, t) {
        if (this.LastMode = "top" && w = this.LastW && t = this.LastT)
            return
        this.LastMode := "top", this.LastW := w, this.LastH := t, this.LastT := t, this.LastR := 0
        try DllCall("User32\SetWindowRgn", "Ptr", this.Gui.Hwnd, "Ptr", 0, "Int", 1)
    }

    _ApplyRegion(w, h, t, radius) {
        if (this.LastMode = "full" && w = this.LastW && h = this.LastH && t = this.LastT && radius = this.LastR)
            return
        this.LastMode := "full"
        this.LastW := w, this.LastH := h, this.LastT := t, this.LastR := radius
        d := radius * 2
        if (d > 0) {
            outer := DllCall("Gdi32\CreateRoundRectRgn", "Int",0,"Int",0,"Int",w+1,"Int",h+1,"Int",d,"Int",d,"Ptr")
            id    := Max(0, d - t*2)
            inner := DllCall("Gdi32\CreateRoundRectRgn", "Int",t,"Int",t,"Int",w-t+1,"Int",h-t+1,"Int",id,"Int",id,"Ptr")
        } else {
            outer := DllCall("Gdi32\CreateRectRgn", "Int",0,"Int",0,"Int",w,"Int",h,"Ptr")
            inner := DllCall("Gdi32\CreateRectRgn", "Int",t,"Int",t,"Int",w-t,"Int",h-t,"Ptr")
        }
        DllCall("Gdi32\CombineRgn", "Ptr",outer, "Ptr",outer, "Ptr",inner, "Int",4)
        DllCall("Gdi32\DeleteObject", "Ptr", inner)
        try DllCall("User32\SetWindowRgn", "Ptr", this.Gui.Hwnd, "Ptr", outer, "Int", 1)
    }

    BindOwner(owner) {
        if !IsObject(this.Gui) || !this.Gui.Hwnd || !owner
            return
        if (this.Owner = owner)
            return
        this.Owner := owner
        try DllCall("User32\SetWindowLongPtr", "Ptr", this.Gui.Hwnd, "Int", -8, "Ptr", owner)
    }

    Show() {
        if IsObject(this.Gui)
            try DllCall("ShowWindow", "Ptr", this.Gui.Hwnd, "Int", 8)
    }

    Hide() {
        if IsObject(this.Gui)
            try DllCall("ShowWindow", "Ptr", this.Gui.Hwnd, "Int", 0)
        this.LastPX := -99999
    }

    Destroy() {
        if IsObject(this.Gui) {
            try {
                if (this.Gui.Hwnd)
                    DllCall("User32\DestroyWindow", "Ptr", this.Gui.Hwnd)
            }
        }
        this.Gui := ""
    }
}

; ---- Drag border (single rounded frame) / 拖拽边框 ----
class DragBorder {
    static Frame := ""
    static LastX := -9999, LastY := -9999, LastW := -1, LastH := -1

    static Show() {
        if (Border_Enable != "on")
            return
        this.Destroy()
        this.Frame := BorderFrame(Border_FocusColor, Border_Opacity)
        pc := ParseColor(Border_FocusColor)
        if (pc.isGrad) {
            MonitorGetWorkArea(MonitorGetPrimary(), &mL, &mT, &mR, &mB)
            this.Frame.BigGradBM := CreateGradient(mR - mL, mB - mT, 0, pc.colors*)
        }
        this.LastX := -9999, this.LastY := -9999, this.LastW := -1, this.LastH := -1
    }

    static Update(hwnd) {
        if !IsObject(this.Frame)
            return
        if !hwnd || !WinExist(hwnd)
            return
        if !GetWindowVisualRect(hwnd, &x, &y, &w, &h)
            return
        o  := Border_Offset
        ot := Border_OffsetTop
        x -= o, y -= (o + ot), w += 2*o, h += 2*o + ot
        rad := (Border_Rounded = "on") ? Border_Radius : 0
        if (x = this.LastX && y = this.LastY && w = this.LastW && h = this.LastH)
            return
        this.LastX := x, this.LastY := y, this.LastW := w, this.LastH := h
        this.Frame.Place(x, y, w, h, Border_Thickness, rad, Border_Opacity, Border_Mode, -1)
    }

    static Destroy() {
        if IsObject(this.Frame) {
            if this.Frame.BigGradBM {
                DllCall("Gdi32\DeleteObject", "Ptr", this.Frame.BigGradBM)
                this.Frame.BigGradBM := 0
            }
            this.Frame.Destroy()
        }
        this.Frame := ""
    }
}

; ---- Pinned-window border / 置顶边框 ----
class PinBorder {
    static Map     := Map()
    static TimerFn := ObjBindMethod(PinBorder, "Tick")
    static Started := false

    static Add(hwnd) {
        if this.Map.Has(hwnd)
            return
        this.Map[hwnd] := BorderFrame(Border_Pin_Color, Border_Pin_Transparent)

        if !this.Started {
            SetTimer(this.TimerFn, Border_RefreshMs)
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
        t := Max(3, Border_Pin_Thickness)
        for hwnd, frame in this.Map.Clone() {
            if !WinExist(hwnd) {
                this.Remove(hwnd)
                continue
            }
            try {
                if (WinGetMinMax(hwnd) = -1) {
                    frame.Hide()
                    continue
                }
                if !GetWindowVisualRect(hwnd, &x, &y, &w, &h)
                    continue
            } catch {
                continue
            }
            o  := Border_Pin_Offset
            ot := Border_Pin_OffsetTop
            x -= o, y -= (o + ot), w += 2*o, h += 2*o + ot
            rad := (Border_Pin_Rounded = "on") ? Border_Pin_Radius : 0
            frame.Place(x, y, w, h, t, rad, Border_Pin_Transparent, Border_Pin_Mode, -1)
            try WinSetAlwaysOnTop(true, frame.Gui.Hwnd)
        }
    }
}

; ==============================================================================
; 10. Window Actions / 窗口操作
; ==============================================================================

; ---- Get HWND under the mouse (bar excluded) / 获取鼠标下窗口 ----
_GetHwndUnderMouse() {
    MouseGetPos(,, &hwnd)
    if hwnd && !IsBarWindow(hwnd)
        return hwnd
    return 0
}

; ---- Close window under mouse / 关闭窗口 ----
CloseWindowUnderMouse(*) {
    hwnd := _GetHwndUnderMouse()
    if !hwnd
        return
    try {
        WinClose(hwnd)
        PinBorder.Remove(hwnd)
        ShowOSD("Closing Window...")
    }
    WTM.OnWindowChanged()
}

; ---- Minimize window under mouse / 最小化 ----
HideUnderMouse(*) {
    hwnd := _GetHwndUnderMouse()
    if !hwnd
        return
    try {
        WinMinimize(hwnd)
        ShowOSD("WinMinimized")
    }
    WTM.OnWindowChanged()
}

; ---- Toggle maximize under mouse / 最大化 ----
ToggleMaximizeUnderMouse(*) {
    hwnd := _GetHwndUnderMouse()
    if !hwnd
        return
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

; ---- Toggle always-on-top under mouse / 置顶切换 ----
ToggleTopUnderMouse(*) {
    hwnd := _GetHwndUnderMouse()
    if !hwnd
        return
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

; ---- Adjust window transparency / 透明度 ----
AdjustTransparency(amount, *) {
    global TransparencyStep
    MouseGetPos(,, &hwnd)
    try {
        cur := WinGetTransparent(hwnd)
        if !IsNumber(cur)
            cur := 255
        curPct := Round(cur * 100 / 255)
        if (amount > 0) {
            newPct := Ceil(curPct / TransparencyStep) * TransparencyStep
            if (newPct <= curPct)
                newPct += TransparencyStep
        } else {
            newPct := Floor(curPct / TransparencyStep) * TransparencyStep
            if (newPct >= curPct)
                newPct -= TransparencyStep
        }
        newPct := Max(1, Min(100, newPct))
        newVal := Round(newPct * 255 / 100)
        WinSetTransparent(newVal, hwnd)
        ShowOSD("Transparency: " . newPct . "%")
    }
}

; ==============================================================================
; 11. Pie Menu / 功能环菜单
; ==============================================================================

; ---- Radial pie menu / 功能环 ----
class PieMenu {
    static DirMap   := ["Right","DownRight","Down","DownLeft","Left","TopLeft","Top","TopRight"]
    static IsActive := false, GuiObj := "", Labels := Map()
    static PendingRUp := false
    static TimerFn  := ObjBindMethod(PieMenu, "CheckMouse")
    static StartX   := 0, StartY := 0, CurrentSector := "", LastSector := ""

    static Start() {
        if this.IsActive || GetKeyState("Alt", "P")
            return
        this.IsActive := true
        this.PendingRUp := GetKeyState("RButton", "P") ? true : false
        MouseGetPos(&x, &y)
        this.StartX := x, this.StartY := y
        this.CurrentSector := "Center", this.LastSector := ""
        this.CreateGui()
        SetTimer(this.TimerFn, 8)
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
                ctrl.SetFont("s" . Pie_FontSize . " c" . Color_Text . " w600", FontName)
                ctrl.Opt("c" . Color_Text)
            }
        }
        if this.Labels.Has(this.CurrentSector) {
            try {
                curr := this.Labels[this.CurrentSector]
                curr.SetFont("s" . Pie_FontSizeActive . " c" . Color_Active . " w700", FontName)
                curr.Opt("c" . Color_Active)
            }
        }
    }

    static Execute() {
        this.IsActive := false
        if !GetKeyState("RButton", "P")
            this.PendingRUp := false
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

; ==============================================================================
; 12. Virtual Desktops / 虚拟桌面
; ==============================================================================

; ---- HideWin / 隐藏窗口 ----
HideWin(hwnd) {
    global Desktop_HideMethod
    if (Desktop_HideMethod = "hide"){
        try DllCall("ShowWindow", "Ptr", hwnd, "Int", 0)
    }
    else{
        try WinMinimize(hwnd)
    }
}

; ---- ShowWin / 显示窗口 ----
ShowWin(hwnd) {
    global Desktop_HideMethod
    if (Desktop_HideMethod = "hide"){
        try DllCall("ShowWindow", "Ptr", hwnd, "Int", 9)
    }
    else{
        try WinRestore(hwnd)
    }
}

; ---- Remove window from all desktops / 从所有桌面移除窗口 ----
_RemoveFromAllDesktops(hwnd) {
    global Desktops, DesktopCount
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
}

; ---- Desktop switching busy flag / 桌面切换忙标志 ----

; ---- SwitchDesktop / 切换桌面 ----
SwitchDesktop(target, *) {
    global CurrentDesktop, Desktops, AlwaysVisible, DesktopFocus, DesktopIsSwitching
    if DesktopIsSwitching
        return
    DesktopIsSwitching := true
    try {
        if (target == CurrentDesktop) {
            ShowOSD("Desktop " . target)
            return
        }

        wasWTMActive := WTM.Active
        if wasWTMActive {
            WTM.SaveOrderForDesktop(CurrentDesktop)
            WTM.DestroyAllBorders()
        }
        if AllBorders.Active
            AllBorders.DestroyAll()
        DestroyTransientGuis()

        curFocus := 0
        try curFocus := WinExist("A")
        if curFocus
            DesktopFocus[CurrentDesktop] := curFocus

        Desktops[CurrentDesktop] := GetVisibleWindows()
        for hwnd in Desktops[CurrentDesktop] {
            if !AlwaysVisible.Has(hwnd)
                HideWin(hwnd)
        }
        loop Desktops[target].Length {
            h := Desktops[target][Desktops[target].Length - A_Index + 1]
            ShowWin(h)
        }
        for hwnd, _ in AlwaysVisible
            ShowWin(hwnd)

        CurrentDesktop := target
        UpdateStatusBar()
        A_IconTip := "AHK WM - Desktop " . CurrentDesktop
        ShowOSD("Desktop " . CurrentDesktop)

        if (DesktopFocus.Has(target) && DesktopFocus[target] && WinExist(DesktopFocus[target]))
            FocusWindowSafely(DesktopFocus[target])

        if wasWTMActive
            WTM.OnDesktopSwitched(target)
        if AllBorders.Active
            AllBorders.Rebuild()
        for hwnd, frame in PinBorder.Map.Clone() {
            if !AlwaysVisible.Has(hwnd) {
                try {
                    if (WinGetMinMax(hwnd) = -1 || !DllCall("IsWindowVisible", "Ptr", hwnd))
                        DllCall("ShowWindow", "Ptr", frame.Gui.Hwnd, "Int", 0)
                }
            }
        }
    } finally {
        DesktopIsSwitching := false
    }
}

; ---- MoveWindowToDesktop / 移至桌面 ----
MoveWindowToDesktop(target, *) {
    global CurrentDesktop, Desktops, AlwaysVisible, DesktopFocus

    hwnd := 0
    try hwnd := WinExist("A")
    if (!hwnd || IsBarWindow(hwnd))
        return

    if AlwaysVisible.Has(hwnd) {
        AlwaysVisible.Delete(hwnd)
        PinBorder.Remove(hwnd)
    }

    _RemoveFromAllDesktops(hwnd)

    Desktops[target].InsertAt(1, hwnd)
    DesktopFocus[target] := hwnd

    if (target != CurrentDesktop) {
        HideWin(hwnd)
        ShowOSD("Window -> Desktop " . target)
    } else {
        try WinMoveTop(hwnd)
    }
    WTM.OnWindowChanged()
}

; ---- Move window and switch, keeping its focus / 携带切换 ----
MoveAndSwitch(target, *) {
    global CurrentDesktop, DesktopFocus

    hwnd := 0
    try hwnd := WinExist("A")
    if (hwnd && IsBarWindow(hwnd))
        hwnd := 0

    MoveWindowToDesktop(target)

    if (hwnd && target != CurrentDesktop)
        DesktopFocus[target] := hwnd

    SwitchDesktop(target)

    if (hwnd && WinExist(hwnd)) {
        try ShowWin(hwnd)
        FocusWindowSafely(hwnd)
        try WinMoveTop(hwnd)
        DesktopFocus[target] := hwnd
    }
    ShowOSD("Move And Switch -> " . target)
}

; ==============================================================================
; 13. Status Bar / 状态栏
; ==============================================================================

; ---- Truthy-flag parsing for config values / 开关判定 ----
BarShown(str) {
    s := StrLower(Trim(str))
    return !(s = "" || s = "false" || s = "off" || s = "0")
}
BoolCfg(str) => BarShown(str)

; ---- Parse "element:expr;..." bar layout / 布局解析 ----
ParseBarLayout(str) {
    result := Map()
    
    if InStr(str, ":") && !InStr(str, "bg") && !InStr(str, "tx") && !InStr(str, "fs=") && !InStr(str, "wrap=") {
        for clause in SplitEscaped(str, ";") {
            clause := Trim(clause)
            if (clause = "")
                continue
            p := StrSplit(clause, ":")
            if (p.Length != 2)
                continue
            name := StrLower(Trim(p[1]))
            fields := SplitEscaped(Trim(p[2]), ",")
            if (fields.Length < 1)
                continue
            try axis := ParseAxis(fields[1])
            catch Error as e {
                WMLog("Bar layout invalid (" e.Message "): " clause)
                continue
            }
            colors := []
            loop fields.Length - 1 {
                c := Trim(fields[A_Index + 1])
                if (c != "")
                    colors.Push(c)
            }
            if !result.Has(1)
                result[1] := Map()
            result[1][name] := {lo: axis.lo, hi: axis.hi, colors: colors, mode: "text", rounded: "off", align: axis.align, fontSize: 0, wrapLines: 0}
        }
        return result
    }
    
    for clause in SplitEscaped(str, ";") {
        clause := Trim(clause)
        if (clause = "")
            continue
        fields := SplitEscaped(clause, ",")
        if (fields.Length < 2)
            continue
        
        idx := 1, barNum := 1
        if IsInteger(Trim(fields[1])) {
            barNum := Integer(Trim(fields[1]))
            idx := 2
        }
        if (idx > fields.Length)
            continue
        elName := StrLower(Trim(fields[idx]))
        idx++
        if (idx > fields.Length)
            continue
        try axis := ParseAxis(Trim(fields[idx]))
        catch Error as e {
            WMLog("Bar layout axis invalid (" e.Message "): " clause)
            continue
        }
        idx++
        colors := [], mode := "text", rounded := "off", fontSize := 0, wrapLines := 0
        loop fields.Length - idx + 1 {
            f := Trim(fields[idx + A_Index - 1])
            if (f = "")
                continue
            if RegExMatch(f, "i)^#?[0-9a-fA-F]{6}$") {
                f := _StripHash(f)
                colors.Push(f)
            }
            else if (f = "bg" || f = "tx")
                mode := (f = "bg") ? "bg" : "text"
            else if (f = "on" || f = "off")
                rounded := f
            else if RegExMatch(f, "^fs=(\d+)$", &fss)
                fontSize := Max(6, Integer(fss[1]))
            else if RegExMatch(f, "^wrap=(\d+)$", &wrs)
                wrapLines := Max(0, Integer(wrs[1]))
        }
        if !result.Has(barNum)
            result[barNum] := Map()
        result[barNum][elName] := {lo: axis.lo, hi: axis.hi, colors: colors, mode: mode, rounded: rounded, align: axis.align, fontSize: fontSize, wrapLines: wrapLines}
    }
    return result
}

; ---- ParseCurColor / 当前桌面高亮颜色解析 ----
ParseCurColor(raw) {
    raw := Trim(raw)
    if (raw = "")
        return Map()
    fields := StrSplit(raw, ",")
    if (fields.Length < 1)
        return Map()
    colors := [], mode := "bg", rounded := "off"
    for f in fields {
        f := Trim(f)
        if (f = "")
            continue
        if RegExMatch(f, "i)^#?[0-9a-fA-F]{6}$") {
            f := _StripHash(f)
            colors.Push(f)
        }
        else if (f = "bg" || f = "tx")
            mode := (f = "bg") ? "bg" : "text"
        else if (f = "on" || f = "off")
            rounded := f
    }
    if (colors.Length = 0)
        return Map()
    return {colors: colors, mode: mode, rounded: rounded}
}

; ---- Work-time range in minutes / 工时范围 ----
WorkRangeMins(&baseStart, &baseEnd) {
    global Work_Mode, Work_WeekendBar, Work_Start, Work_End
    baseStart := 0, baseEnd := 1439
    if (Work_Mode != "off") {
        isWeekend := (A_WDay == 1 || A_WDay == 7)
        if !(isWeekend && Work_WeekendBar = "off") {
            baseStart := Integer(SubStr(Work_Start, 1, 2)) * 60 + Integer(SubStr(Work_Start, 3, 2))
            baseEnd   := Integer(SubStr(Work_End,   1, 2)) * 60 + Integer(SubStr(Work_End,   3, 2))
        }
    }
}

; ---- Today's task slots / 任务时段 ----
WorkDayTasks(baseStart, baseEnd) {
    global Work_TaskTimes
    out := []
    if (Work_TaskTimes = "" || baseEnd - baseStart <= 0)
        return out
    userWDay := (A_WDay == 1) ? 7 : A_WDay - 1
    Loop Parse, Work_TaskTimes, ";" {
        if (A_LoopField = "")
            continue
        taskFields := StrSplit(A_LoopField, ",")
        timePart := Trim(taskFields[1])
        taskColors := []
        loop taskFields.Length - 1 {
            c := _StripHash(Trim(taskFields[A_Index + 1]))
            if (c != "")
                taskColors.Push(c)
        }
        parts := StrSplit(timePart, "_")
        if (parts.Length == 3 && Integer(parts[1]) == userWDay) {
            rs := Integer(SubStr(parts[2],1,2))*60 + Integer(SubStr(parts[2],3,2))
            re := Integer(SubStr(parts[3],1,2))*60 + Integer(SubStr(parts[3],3,2))
            s := Max(rs, baseStart), e := Min(re, baseEnd)
            if (e > s)
                out.Push({Start:s, End:e, RawStart:rs, Colors: taskColors})
        }
    }
    if (out.Length > 1) {
        Loop out.Length {
            i := A_Index
            Loop out.Length - i {
                j := A_Index
                if (out[j].RawStart > out[j+1].RawStart) {
                    tmp := out[j], out[j] := out[j+1], out[j+1] := tmp
                }
            }
        }
    }
    return out
}

; ---- System status (Wi-Fi, BT, Batt, Vol, Disk, Mem, CPU) / 系统状态 ----
GetSysInfo(what) {
    static cpuLastIdle := 0, cpuLastKernel := 0, cpuLastUser := 0
    static wifiCache := "", wifiCacheTime := 0, diskCache := "", diskCacheTime := 0
    static wifiPending := false, wifiTmp := A_Temp . "\_wm_wifi.tmp", wifiDone := A_Temp . "\_wm_wifi.done"
    try {
        switch what {
        case "wifi":
            now := A_TickCount
            if wifiPending {
                if FileExist(wifiDone) {
                    out := ""
                    try out := Trim(FileRead(wifiTmp))
                    try FileDelete(wifiTmp)
                    try FileDelete(wifiDone)
                    wifiPending := false
                    wifiCacheTime := now
                    wifiCache := Chr(0xF1EB) . " " . (out != "" ? out : "off")
                }
                return wifiCache != "" ? wifiCache : Chr(0xF1EB) . " ..."
            }
            if (wifiCacheTime && now - wifiCacheTime < 30000)
                return wifiCache
            wifiPending := true
            try {
                psCmd := 'powershell -NoProfile -Command "(Get-NetConnectionProfile -ErrorAction SilentlyContinue).Name"'
                Run(A_ComSpec . ' /c ' . psCmd . ' > "' . wifiTmp . '" & echo 1 > "' . wifiDone . '"', , "Hide")
            } catch {
                wifiPending := false
                wifiCacheTime := now
                wifiCache := Chr(0xF1EB) . " off"
            }
            return wifiCache != "" ? wifiCache : Chr(0xF1EB) . " ..."
        case "battery":
            st := Buffer(12, 0)
            DllCall("kernel32\GetSystemPowerStatus", "Ptr", st)
            pct := NumGet(st, 2, "UChar")
            acl := NumGet(st, 0, "UChar")
            if pct = 255
                return Chr(0xF244) " --"
            code := pct >= 90 ? 0xF240 : pct >= 70 ? 0xF241 : pct >= 40 ? 0xF242 : pct >= 15 ? 0xF243 : 0xF244
            return Chr(code) " " pct "%" (acl = 1 ? " " Chr(0xF1E6) : "")
        case "volume":
            vol := Round(SoundGetVolume())
            code := vol = 0 ? 0xF026 : vol < 33 ? 0xF027 : 0xF028
            return Chr(code) " " vol
        case "disk":
            now := A_TickCount
            if (diskCacheTime && now - diskCacheTime < 30000)
                return diskCache
            diskCacheTime := now
            try {
                free := DriveGetSpaceFree("C:\")
                freeGB := Round(free / 1024)
                code := freeGB < 10 ? 0xF071 : 0xF0C7
                diskCache := Chr(code) " C " freeGB "G"
                return diskCache
            }
            diskCache := Chr(0xF071) " C ?"
            return diskCache
        case "mem":
            info := GlobalMemoryStatusEx()
            used := info.MemoryLoad
            code := used >= 90 ? 0xF071 : 0xF0E4
            return Chr(code) " " used "%"
        case "cpu":
            idle := Buffer(8, 0), kernel := Buffer(8, 0), user := Buffer(8, 0)
            if !DllCall("kernel32\GetSystemTimes", "Ptr", idle, "Ptr", kernel, "Ptr", user)
                return Chr(0xF085) " ?"
            i := NumGet(idle, 0, "Int64"), k := NumGet(kernel, 0, "Int64"), u := NumGet(user, 0, "Int64")
            usage := 0
            if (cpuLastIdle > 0) {
                dIdle := i - cpuLastIdle, dKernel := k - cpuLastKernel, dUser := u - cpuLastUser
                dTotal := dKernel + dUser
                if (dTotal > 0)
                    usage := Round((dTotal - dIdle) / dTotal * 100)
            }
            cpuLastIdle := i, cpuLastKernel := k, cpuLastUser := u
            code := usage >= 90 ? 0xF071 : usage >= 70 ? 0xF200 : 0xF085
            return Chr(code) " " usage "%"
        }
    }
    return ""
}
GlobalMemoryStatusEx() {
    buf := Buffer(64, 0)
    NumPut("UInt", 64, buf, 0)
    DllCall("kernel32\GlobalMemoryStatusEx", "Ptr", buf)
    return { MemoryLoad: NumGet(buf, 4, "UInt") }
}

; ---- Work-time progress percent / 工时进度 ----
WorkPercent() {
    global Work_Mode, Work_WeekendBar, Work_Start, Work_End
    NowTime := A_Now, TodayDate := FormatTime(NowTime, "yyyyMMdd"), WDay := A_WDay
    if (Work_Mode = "off") {
        StartTS := TodayDate "000000", EndTS := TodayDate "235959", ForceFull := false
    } else {
        StartTS := TodayDate Work_Start "00", EndTS := TodayDate Work_End "00"
        ForceFull := ((WDay == 1 || WDay == 7) && Work_WeekendBar = "off")
    }
    if ForceFull
        return 100
    TotalSec   := DateDiff(EndTS, StartTS, "Seconds")
    ElapsedSec := DateDiff(NowTime, StartTS, "Seconds")
    if (TotalSec <= 0)
        return 100
    if (ElapsedSec < 0)
        return 0
    if (ElapsedSec > TotalSec)
        return 100
    return (ElapsedSec / TotalSec) * 100
}

; ---- Bar wrap 高度扫描辅助（Layout + 动态槽位共用）----
_BarScanWrapFn(elName, seg, minThick, bi) {
    global Bar_ExternalData, Bar_FontSize
    elWL := (seg.HasOwnProp("wrapLines") && seg.wrapLines > 0) ? seg.wrapLines : 0
    if (elWL == 0 && RegExMatch(elName, "^external_(\d+)$", &meExt)) {
        n := Integer(meExt[1])
        if Bar_ExternalData.Has(n) && InStr(Bar_ExternalData[n], "`n")
            elWL := Max(2, StrSplit(Bar_ExternalData[n], "`n").Length)
    }
    if (elWL > 1) {
        elFS := (seg.HasOwnProp("fontSize") && seg.fontSize > 0) ? seg.fontSize : Bar_FontSize
        elLH := bi._LineHeightForFont(elFS)
        wrapH := elLH * elWL + 4
        if (wrapH > minThick)
            minThick := wrapH
    }
    return minThick
}

; ---- One bar strip on one monitor edge / 状态栏实例 ----
class BarInstance {
    Mon := 1, Pos := "top", Offset := 0, Thick := 30
    BarNum := 1
    Gui := "", Visible := true
    DesktopsCtrl := "", TimeCtrl := "", DateCtrl := "", Progress := ""
    ProgX := 0, ProgY := 0, ProgW := 0, ProgH := 0
    ProgHasGradient := false, ProgGradientColors := []
    ProgGradientPic := "", ProgOldBM := 0
    WifiCtrl := "", BattCtrl := "", VolCtrl := "", DiskCtrl := "", MemCtrl := "", CpuCtrl := ""
    LastVals := Map()
    ExtCtrls := Map()
    GradText := Map()
    BgGradBM := 0
    TaskMarkerBMs := []
    DesktopCellCtrls := []
    DesktopCurColor  := Map()
    DesktopSeg       := {cx:0, cy:0, cw:0, ch:0}
    DesktopLayoutColors := []
    DesktopLayoutMode   := "text"
    DesktopLayoutRounded := "off"
    DesktopLayoutAlign   := "Center"

    static SysWidgets := [
        {ctrl: "WifiCtrl",  key: "wifi",    gradKey: "wifi",      sysFn: "wifi",   label: "WiFi"},
        {ctrl: "BattCtrl",  key: "battery", gradKey: "battery",   sysFn: "battery", label: "Batt"},
        {ctrl: "VolCtrl",   key: "volume",  gradKey: "volume",    sysFn: "volume",  label: "Vol"},
        {ctrl: "DiskCtrl",  key: "disk",    gradKey: "disk",      sysFn: "disk",    label: "Disk"},
        {ctrl: "MemCtrl",   key: "mem",     gradKey: "mem",       sysFn: "mem",     label: "Mem"},
        {ctrl: "CpuCtrl",   key: "cpu",     gradKey: "cpu",       sysFn: "cpu",     label: "CPU"},
    ]

    static WidgetMeta := Map()
    static __InitWidgetMeta() {
        for w in BarInstance.SysWidgets
            BarInstance.WidgetMeta[w.sysFn] := w
    }

    __New(mon, pos, offset, barNum := 1) {
        this.Mon := mon, this.Pos := pos, this.Offset := offset
        this.BarNum := barNum
        this.DesktopCellCtrls := []
        this.Build()
    }

    IsHorizontal() => (this.Pos = "top" || this.Pos = "bottom")

    _MyLayout() {
        global Bar_Cfg
        layout := Bar_Cfg["layout"]
        if layout.Has(this.BarNum)
            return layout[this.BarNum]
        if layout.Has(1)
            return layout[1]
        return Map()
    }

    _Seg(name) {
        myLayout := this._MyLayout()
        keys := [name]
        if (name = "custom_1") {
            keys.Push("custom_icon")
            keys.Push("custom_text")
        } else if (name = "custom_2") {
            keys.Push("custom_text")
        }
        for k in keys {
            if myLayout.Has(k)
                return myLayout[k]
        }
        if RegExMatch(name, "^external_(\d+)$", &me) {
            global Bar_ExternalSlots
            n := Integer(me[1])
            if Bar_ExternalSlots.Has(n) {
                ec := Bar_ExternalSlots[n]
                colors := [], mode := "text"
                if ec.Has("bg")
                    colors.Push(ec["bg"]), mode := "bg"
                else if ec.Has("tx")
                    colors.Push(ec["tx"])
                return {lo: ec.Has("lo") ? ec["lo"] : 0.0
                    , hi: ec.Has("hi") ? ec["hi"] : 1.0
                    , colors: colors, mode: mode
                    , rounded: ec.Has("rd") ? ec["rd"] : "off"
                    , align: "Center"
                    , fontSize: ec.Has("fs") ? Integer(ec["fs"]) : 0
                    , wrapLines: ec.Has("wrap") ? Integer(ec["wrap"]) : 0}
            }
        }
        defaults := Map(
            "desktops",  {lo:0.00, hi:0.30, colors:[], mode:"text", rounded:"off", align:"Center", fontSize:0, wrapLines:0},
            "custom_1",  {lo:0.30, hi:0.48, colors:[], mode:"text", rounded:"off", align:"Center", fontSize:0, wrapLines:0},
            "custom_2",  {lo:0.48, hi:0.62, colors:[], mode:"text", rounded:"off", align:"Center", fontSize:0, wrapLines:0},
            "progress",  {lo:0.40, hi:0.62, colors:[], mode:"text", rounded:"off", align:"Center", fontSize:0, wrapLines:0},
            "date",      {lo:0.64, hi:0.82, colors:[], mode:"text", rounded:"off", align:"Center", fontSize:0, wrapLines:0},
            "time",      {lo:0.82, hi:1.00, colors:[], mode:"text", rounded:"off", align:"Center", fontSize:0, wrapLines:0},
            "wifi",      {lo:0.00, hi:0.10, colors:[], mode:"text", rounded:"off", align:"Center", fontSize:0, wrapLines:0},
            "battery",   {lo:0.00, hi:0.10, colors:[], mode:"text", rounded:"off", align:"Center", fontSize:0, wrapLines:0},
            "volume",    {lo:0.00, hi:0.10, colors:[], mode:"text", rounded:"off", align:"Center", fontSize:0, wrapLines:0},
            "disk",      {lo:0.00, hi:0.10, colors:[], mode:"text", rounded:"off", align:"Center", fontSize:0, wrapLines:0},
            "mem",       {lo:0.00, hi:0.10, colors:[], mode:"text", rounded:"off", align:"Center", fontSize:0, wrapLines:0},
            "cpu",       {lo:0.00, hi:0.10, colors:[], mode:"text", rounded:"off", align:"Center", fontSize:0, wrapLines:0}
        )
        return defaults.Has(name) ? defaults[name] : {lo:0.0, hi:1.0, colors:[], mode:"text", rounded:"off", align:"Center", fontSize:0, wrapLines:0}
    }

    _LineHeightForFont(fontSize) {
        global FontName
        fh := -Round(fontSize * A_ScreenDPI / 72)
        hFont := DllCall("Gdi32\CreateFontW", "Int",fh,"Int",0,"Int",0,"Int",0,"Int",700
            ,"Int",0,"Int",0,"Int",0,"Int",0,"Int",0,"Int",5,"Int",0,"Int",0,"Str",FontName,"Ptr")
        dc := DllCall("Gdi32\CreateCompatibleDC", "Ptr",0, "Ptr")
        old := DllCall("Gdi32\SelectObject", "Ptr",dc, "Ptr",hFont, "Ptr")
        tm := Buffer(57, 0)
        DllCall("Gdi32\GetTextMetricsW", "Ptr",dc, "Ptr",tm)
        DllCall("Gdi32\SelectObject", "Ptr",dc, "Ptr",old, "Ptr")
        DllCall("Gdi32\DeleteDC", "Ptr",dc)
        DllCall("Gdi32\DeleteObject", "Ptr",hFont)
        return NumGet(tm, 0, "Int") + 4
    }
    _LineHeight() {
        global Bar_FontSize
        return this._LineHeightForFont(Bar_FontSize)
    }

    _TextWidth(txt) {
        global Bar_FontSize, FontName
        fh := -Round(Bar_FontSize * A_ScreenDPI / 72)
        hFont := DllCall("Gdi32\CreateFontW", "Int",fh,"Int",0,"Int",0,"Int",0,"Int",700
            ,"Int",0,"Int",0,"Int",0,"Int",0,"Int",0,"Int",5,"Int",0,"Int",0,"Str",FontName,"Ptr")
        dc := DllCall("Gdi32\CreateCompatibleDC", "Ptr",0, "Ptr")
        old := DllCall("Gdi32\SelectObject", "Ptr",dc, "Ptr",hFont, "Ptr")
        sz := Buffer(8, 0)
        DllCall("Gdi32\GetTextExtentPoint32W", "Ptr",dc, "Str",txt, "Int",StrLen(txt), "Ptr",sz)
        w := NumGet(sz, 0, "Int")
        DllCall("Gdi32\SelectObject", "Ptr",dc, "Ptr",old, "Ptr")
        DllCall("Gdi32\DeleteObject", "Ptr",hFont)
        DllCall("Gdi32\DeleteDC", "Ptr",dc)
        return w
    }

    _GradBgBM(w, h, colors, rounded := "off", radius := 0, fillColor := "", bgOffX := 0, bgOffY := 0) {
        return MakeGradientBM(w, h, colors, rounded, radius, fillColor, this.BgGradBM, bgOffX, bgOffY)
    }

    _Opt(x, y, w, h, align) {
        return Format("x{} y{} w{} h{} BackgroundTrans {}", Round(x), Round(y), Round(w), Round(h), align)
    }

    Build() {
        global Color_Bg, Color_Active, Bar_FontSize, Bar_Height, Bar_Transparent
        global Bar_Rounded, Bar_Radius, Bar_CornerMode
        global Bar_MarginLeft, Bar_MarginRight
        if (this.Mon < 1 || this.Mon > MonitorGetCount())
            this.Mon := 1
        MonitorGet(this.Mon, &mL, &mT, &mR, &mB)

        mlEff := mL + Bar_MarginLeft
        mrEff := mR - Bar_MarginRight
        barW  := mrEff - mlEff
        if (barW < 50) {
            mlEff := mL, barW := mR - mL
            WMLog("Bar: margins exceed monitor " this.Mon " width; ignored")
        }

        lineH := this._LineHeight()
        thick := Bar_Height
        minThick := Max(lineH + 4, Round(Bar_FontSize * 2 + 5))
        ; ---- Scan wrap elements + already-pushed multi-line text: the bar must fit them / 扫描 wrap 元素 ----
        layout := this._MyLayout()
        for elName, seg in layout
            minThick := _BarScanWrapFn(elName, seg, minThick, this)
        global Bar_ExternalSlots
        for n, ec in Bar_ExternalSlots {
            seg := {wrapLines: ec.Has("wrap") ? Integer(ec["wrap"]) : 0
                , fontSize: ec.Has("fs") ? Integer(ec["fs"]) : 0}
            minThick := _BarScanWrapFn("external_" n, seg, minThick, this)
        }
        if (thick < minThick)
            thick := minThick
        this.Thick := thick
        off := this.Offset

        if (this.Pos = "bottom")
            bx := mlEff, by := mB - thick - off
        else
            this.Pos := "top", bx := mlEff, by := mT + off
        bw := barW, bh := thick

        g := Gui("-Caption +AlwaysOnTop +ToolWindow +Owner +E0x08000000 -DPIScale")
        pcBg := ParseColor(Color_Bg)
        g.BackColor := pcBg.first
        g.SetFont("s" Bar_FontSize " w600 c" C1(Color_Active), FontName)
        this.Gui := g
        if (pcBg.isGrad) {
            hBMBg := this._GradBgBM(bw, bh, pcBg.colors, Bar_Rounded, Bar_Radius, pcBg.first)
            if hBMBg {
                this.BgGradBM := hBMBg
                g.Add("Picture", "x0 y0 w" bw " h" bh, "HBITMAP:" hBMBg)
            }
        }

        this._BuildElements(bw, bh, true)

        g.Show(Format("x{} y{} w{} h{} NoActivate", bx, by, bw, bh))
        WinSetTransparent(Bar_Transparent, g.Hwnd)
        if (!pcBg.isGrad)
            RoundWindowEx(g, Bar_Rounded, Bar_Radius, Bar_CornerMode)
        this.UpdateDesktops()
    }

    _AddTextOrGrad(g, el, cx, cy, cw, ch, colors, mode, rounded, txt, align, fontSize := 0, wrapLines := 0) {
        if (colors.Length > 1 || (colors.Length > 0 && mode = "bg") || wrapLines > 0) {
            useColors := colors
            if (wrapLines > 0 && colors.Length == 1)
                useColors := [colors[1], colors[1]]
            else if (wrapLines > 0 && colors.Length == 0) {
                global Color_Active
                useColors := [Color_Active, Color_Active]
            }
            this._AddGradTextCtrl(g, el, cx, cy, cw, ch, useColors, mode, rounded, txt, align, fontSize, wrapLines)
            return this.GradText.Has(el) ? this.GradText[el].ctrl : ""
        }
        ctrl := g.Add("Text", this._Opt(cx, cy, cw, ch, align), txt)
        useFS := (fontSize > 0) ? fontSize : Bar_FontSize
        if (colors.Length = 1)
            ctrl.SetFont("c" colors[1], FontName)
        else
            ctrl.SetFont("s" useFS " w600", FontName)
        return ctrl
    }

    _BuildSysWidget(g, el, cx, cy, cw, ch, colors, mode, rounded, align) {
        if BarInstance.WidgetMeta.Count = 0 {
            for w in BarInstance.SysWidgets {
                BarInstance.WidgetMeta[w.sysFn] := w
                BarInstance.WidgetMeta[w.gradKey] := w
            }
        }
        meta := BarInstance.WidgetMeta[el]
        if !IsObject(meta)
            return
        initial := GetSysInfo(meta.sysFn) || meta.label
        this.%meta.ctrl% := this._AddTextOrGrad(g, el, cx, cy, cw, ch, colors, mode, rounded, initial, align)
    }

    _BuildElements(L, T, horiz) {
        global Bar_Cfg, Bar_FontSize, Bar_ExternalData
        g := this.Gui
        fontH := this._LineHeight()
        pad := 6

        items := Bar_Cfg["custom_items"]
        layout := this._MyLayout()

        elements := []
        if layout.Has("desktops")
            elements.Push("desktops")
        for idx, val in items {
            key := "custom_" idx
            if layout.Has(key) && BarShown(val)
                elements.Push(key)
        }
        for k in ["progress","date","time","wifi","battery","volume","disk","mem","cpu"] {
            if layout.Has(k)
                elements.Push(k)
        }
        for key, _ in layout {
            if RegExMatch(key, "^external_\d+$")
                elements.Push(key)
        }
        global Bar_ExternalSlots
        for n, _ in Bar_ExternalSlots {
            key := "external_" n
            if !layout.Has(key)
                elements.Push(key)
        }

        for el in elements {
            seg := this._Seg(el)
            s   := seg.lo * L
            segLen := Max(10, (seg.hi - seg.lo) * L)
            if horiz {
                cx := s, cy := (T - fontH) // 2, cw := segLen, ch := fontH
            } else {
                cx := pad, cy := s, cw := T - 2*pad, ch := fontH
            }
            try colors := seg.colors
            catch
                colors := []
            try mode := seg.mode
            catch
                mode := "text"
            try rounded := seg.rounded
            catch
                rounded := "off"
            try align := seg.align
            catch
                align := "Center"

            switch el {
                case "desktops":
                    this.DesktopCurColor := ParseCurColor(Bar_Cfg.Has("cur_color") ? Bar_Cfg["cur_color"] : "")
                    this.DesktopSeg := {cx: Round(cx), cy: Round(cy), cw: Round(cw), ch: Round(ch)}
                    this.DesktopLayoutColors := colors
                    this.DesktopLayoutMode   := mode
                    this.DesktopLayoutRounded := rounded
                    this.DesktopLayoutAlign   := align
                    if (this.DesktopCurColor.HasOwnProp("colors")) {
                        layoutBgStatic := (colors.Length > 0 && mode = "bg")
                        if layoutBgStatic
                            this._AddGradTextCtrl(g, el, cx, cy, cw, ch, colors, mode, rounded, " ", align)
                        else {
                            this.DesktopsCtrl := g.Add("Text", this._Opt(cx, cy, cw, ch, align), "")
                            if (colors.Length = 1)
                                this.DesktopsCtrl.SetFont("c" colors[1])
                        }
                    } else {
                        if (colors.Length > 1 || (colors.Length > 0 && mode = "bg"))
                            this._AddGradTextCtrl(g, el, cx, cy, cw, ch, colors, mode, rounded, " ", align)
                        else {
                            this.DesktopsCtrl := g.Add("Text", this._Opt(cx, cy, cw, ch, align), "")
                            if (colors.Length = 1)
                                this.DesktopsCtrl.SetFont("c" colors[1])
                        }
                    }
                case "date":
                    this.DateCtrl := this._AddTextOrGrad(g, el, cx, cy, cw, ch, colors, mode, rounded, " ", align)
                case "time":
                    this.TimeCtrl := this._AddTextOrGrad(g, el, cx, cy, cw, ch, colors, mode, rounded, " ", align)
                case "progress":
                    if (mode = "bg") {
                        WMLog("Bar element 'progress' does not support bg mode, using text")
                        mode := "text"
                    }
                    this._BuildProgress(s, segLen, T, horiz, colors)
                case "wifi", "battery", "volume", "disk", "mem", "cpu":
                    this._BuildSysWidget(g, el, cx, cy, cw, ch, colors, mode, rounded, align)
                default:
                    if RegExMatch(el, "^custom_(\d+)$", &mm) {
                        n := Integer(mm[1])
                        txt := (n >= 1 && n <= items.Length) ? items[n] : ""
                        this._AddTextOrGrad(g, el, cx, cy, cw, ch, colors, mode, rounded, txt, align)
                    } else if RegExMatch(el, "^external_(\d+)$", &me) {
                        n := Integer(me[1])
                        txt := Bar_ExternalData.Has(n) ? Bar_ExternalData[n] : ""
                        elFS := (seg.HasOwnProp("fontSize") && seg.fontSize > 0) ? seg.fontSize : 0
                        elWL := (seg.HasOwnProp("wrapLines") && seg.wrapLines > 0) ? seg.wrapLines : 0
                        if (elWL == 0 && InStr(txt, "`n"))
                            elWL := Max(2, StrSplit(txt, "`n").Length)
                        if (elWL == 0)
                            elWL := 1
                        if (elFS > 0 || elWL > 1) {
                            useFS := (elFS > 0) ? elFS : Bar_FontSize
                            ch := Max(ch, this._LineHeightForFont(useFS) * Max(1, elWL) + 4)
                        }
                        ctrl := this._AddTextOrGrad(g, el, cx, cy, cw, ch, colors, mode, rounded, txt, align, elFS, elWL)
                        this.ExtCtrls[n] := this.GradText.Has(el) ? "" : ctrl
                    }
            }
        }
    }

    UpdateExternal(slot := 0) {
        global Bar_ExternalData
        for n, ctrl in this.ExtCtrls {
            if (slot && n != slot)
                continue
            val := Bar_ExternalData.Has(n) ? Bar_ExternalData[n] : ""
            key := "external_" n
            if (this.LastVals.Has(key) && this.LastVals[key] = val)
                continue
            this.LastVals[key] := val
            if this.GradText.Has(key)
                this._UpdateGradText(key, val)
            else if IsObject(ctrl)
                try ctrl.Value := val
        }
    }

    _AddGradTextCtrl(g, el, cx, cy, cw, ch, colors, mode := "text", rounded := "off", txt := "", align := "Center", fontSize := 0, wrapLines := 0) {
        global Bar_FontSize, Color_Bg
        w := Round(cw), h := Round(ch)
        if (w < 2 || h < 2)
            return
        bgOff := Round(cx)
        useFS := (fontSize > 0) ? fontSize : Bar_FontSize

        if (mode = "bg") {
            hBM := this._GradBgBM(w, h, colors, rounded, 0, C1(Color_Bg))
            if hBM
                g.Add("Picture", Format("x{} y{} w{} h{}", Round(cx), Round(cy), w, h), "HBITMAP:" hBM)
            tColor := C1(Color_Bg)
            ctrl := g.Add("Text", Format("x{} y{} w{} h{} {} BackgroundTrans c{}"
                , Round(cx), Round(cy), w, h, align, tColor), txt)
            ctrl.SetFont("s" useFS " w600", FontName)
            this.GradText[el] := {colors: colors, w: w, h: h, cx: Round(cx), cy: Round(cy)
                , ctrl: ctrl, oldBM: hBM, mode: mode, rounded: rounded, isSimple: true, align: align
                , fontSize: fontSize, wrapLines: wrapLines}

        } else {
            hBM := TextOnGradient(w, h, colors, txt, useFS, "text", FontName, this.BgGradBM, bgOff, C1(Color_Bg), align, wrapLines)
            ctrl := g.Add("Picture", Format("x{} y{} w{} h{}", Round(cx), Round(cy), w, h)
                , hBM ? "HBITMAP:" hBM : "")
            this.GradText[el] := {colors: colors, w: w, h: h, cx: Round(cx), cy: Round(cy)
                , ctrl: ctrl, oldBM: hBM, mode: mode, rounded: rounded, isSimple: false, align: align
                , fontSize: fontSize, wrapLines: wrapLines}
        }
        switch el {
            case "desktops":  this.DesktopsCtrl := ctrl
            case "time":      this.TimeCtrl := ctrl
            case "date":      this.DateCtrl := ctrl
            case "wifi":      this.WifiCtrl := ctrl
            case "battery":   this.BattCtrl := ctrl
            case "volume":    this.VolCtrl := ctrl
            case "disk":      this.DiskCtrl := ctrl
            case "mem":       this.MemCtrl := ctrl
            case "cpu":       this.CpuCtrl := ctrl
        }
    }

    _UpdateGradText(el, newText) {
        global Bar_FontSize, Color_Bg
        if !this.GradText.Has(el)
            return
        gi := this.GradText[el]
        if (gi.w < 2 || gi.h < 2)
            return
        if (gi.HasOwnProp("isSimple") && gi.isSimple) {
            try gi.ctrl.Value := newText
            return
        }
        style := "text"
        if (gi.mode = "bg") {
            style := gi.rounded = "on" ? "bg_rounded" : "bg"
        }
        eFS := (gi.HasOwnProp("fontSize") && gi.fontSize > 0) ? gi.fontSize : Bar_FontSize
        eWL := (gi.HasOwnProp("wrapLines") && gi.wrapLines > 0) ? gi.wrapLines : 0
        if (eWL <= 1 && InStr(newText, "`n")) {
            eWL := Max(2, StrSplit(newText, "`n").Length)
            gi.wrapLines := eWL
        }
        hBM := TextOnGradient(gi.w, gi.h, gi.colors, newText, eFS, style, FontName, this.BgGradBM, gi.cx, C1(Color_Bg), gi.align, eWL)
        if (!hBM)
            return
        try gi.ctrl.Value := "HBITMAP:" hBM
        if (gi.oldBM)
            DllCall("Gdi32.dll\DeleteObject", "Ptr", gi.oldBM)
        gi.oldBM := hBM
    }

    _BuildProgress(mainStart, mainLen, T, horiz, colors := []) {
        global Color_Active
        g := this.Gui
        bar := 6
        if horiz {
            px := mainStart, py := (T - bar) // 2 + 3, pw := mainLen, ph := bar
            g.Add("Text", Format("x{} y{} w{} h{} Background333333", Round(px), Round(py), Round(pw), ph), "")
            if (colors.Length > 1) {
                this.ProgHasGradient := true
                this.ProgGradientColors := colors
                this.ProgGradientPic := g.Add("Picture"
                    , Format("x{} y{} w{} h{}", Round(px), Round(py), 0, ph), "")
                this.ProgGradientPic.Visible := false
            } else {
                progColor := (colors.Length = 1) ? colors[1] : C1(Color_Active)
                this.Progress := g.Add("Progress"
                    , Format("x{} y{} w{} h{} c{} Background333333 +Smooth"
                        , Round(px), Round(py), Round(pw), ph, progColor), 0)
            }
            this.ProgX := px, this.ProgW := pw, this.ProgY := py, this.ProgH := ph
            this._BuildTaskMarkers(px, pw, py)
        } else {
            px := (T - bar) // 2, py := mainStart, pw := bar, ph := mainLen
            g.Add("Text", Format("x{} y{} w{} h{} Background333333", Round(px), Round(py), pw, Round(ph)), "")
            if (colors.Length > 1) {
                this.ProgHasGradient := true
                this.ProgGradientColors := colors
                this.ProgGradientPic := g.Add("Picture"
                    , Format("x{} y{} w{} h{}", Round(px), Round(py), pw, 0), "")
                this.ProgGradientPic.Visible := false
            } else {
                progColor := (colors.Length = 1) ? colors[1] : C1(Color_Active)
                this.Progress := g.Add("Progress"
                    , Format("x{} y{} w{} h{} Vertical c{} Background333333 +Smooth"
                        , Round(px), Round(py), pw, Round(ph), progColor), 0)
            }
            this.ProgX := px, this.ProgY := py, this.ProgW := pw, this.ProgH := ph
        }
    }

    _BuildTaskMarkers(progX, progW, progY) {
        global Color_Task
        WorkRangeMins(&bs, &be)
        range := be - bs
        if (range <= 0)
            return
        tasks := WorkDayTasks(bs, be)
        taskH := 4
        track1Y := progY - taskH - 2
        track2Y := track1Y - taskH - 1
        lastEnd := -1
        for task in tasks {
            offR := (task.Start - bs) / range
            wR   := (task.End - task.Start) / range
            mkX  := Round(progX + progW * offR)
            mkW  := Max(2, Round(progW * wR))
            useY := track1Y
            if (task.Start < lastEnd)
                useY := track2Y
            else
                lastEnd := task.End
            tColors := (task.HasOwnProp("Colors") && IsObject(task.Colors)) ? task.Colors : []
            if (mkW > 0 && taskH > 0) {
                if (tColors.Length > 1) {
                    hBM := CreateGradient(mkW, taskH, 0, tColors*)
                    this.Gui.Add("Picture", Format("x{} y{} w{} h{}", mkX, useY, mkW, taskH), "HBITMAP:" hBM)
                    this.TaskMarkerBMs.Push(hBM)
                } else {
                    useColors := (tColors.Length = 1) ? [tColors[1], tColors[1]] : ParseColor(Color_Task).colors
                    if (useColors.Length = 0)
                        useColors := [C1(Color_Task), C1(Color_Task)]
                    hBM := CreateGradient(mkW, taskH, 0, useColors*)
                    this.Gui.Add("Picture", Format("x{} y{} w{} h{}", mkX, useY, mkW, taskH), "HBITMAP:" hBM)
                    this.TaskMarkerBMs.Push(hBM)
                }
            }
        }
    }

    UpdateDesktops() {
        global CurrentDesktop, DesktopCount, Desktops, Bar_Cfg, Color_Bg, Color_Active, Bar_FontSize, FontName
        labels := Bar_Cfg["desktop_labels"]
        lft := Bar_Cfg["cur_left"], rgt := Bar_Cfg["cur_right"]
        mode := Bar_Cfg["display_mode"]

        if (this.DesktopCurColor.HasOwnProp("colors")) {
            seg := this.DesktopSeg
            g := this.Gui
            if (seg.cw < 2)
                return

            loop this.DesktopCellCtrls.Length {
                ctrl := this.DesktopCellCtrls[A_Index]
                if IsObject(ctrl) {
                    try ctrl.Visible := false
                    try ctrl.Value := ""
                    if (ctrl.HasOwnProp("hBM") && ctrl.hBM)
                        DllCall("Gdi32.dll\DeleteObject", "Ptr", ctrl.hBM)
                    try ctrl.Destroy()
                }
            }
            this.DesktopCellCtrls := []

            visible := []
            Loop DesktopCount {
                i := A_Index
                show := true
                if (mode = "current")
                    show := (i = CurrentDesktop)
                else if (mode = "occupied")
                    show := (i = CurrentDesktop) || (Desktops.Has(i) && Desktops[i].Length > 0)
                if show
                    visible.Push(i)
            }
            if (visible.Length = 0)
                return
            labelsW := Map()
            for i in visible {
                lbl := (i <= labels.Length) ? labels[i] : (i "")
                label := (i = CurrentDesktop) ? (lft lbl rgt) : lbl
                labelsW[i] := this._TextWidth(label)
            }

            layoutBg := (this.DesktopLayoutColors.Length > 0 && this.DesktopLayoutMode = "bg")
            gradientTx := (!layoutBg && this.DesktopLayoutMode = "text" && this.DesktopLayoutColors.Length > 1)
            tBgColor := C1(Color_Bg)
            curColor := this.DesktopCurColor

            sepW := this._TextWidth("  ")
            totalW := 0
            for i in visible {
                lbl := (i <= labels.Length) ? labels[i] : (i "")
                label := (i = CurrentDesktop) ? (lft lbl rgt) : lbl
                totalW += this._TextWidth(label)
            }
            totalW += (visible.Length - 1) * sepW
            groupOff := 0
            if (this.DesktopLayoutAlign = "Right")
                groupOff := seg.cw - totalW
            else if (this.DesktopLayoutAlign = "Center")
                groupOff := (seg.cw - totalW) / 2
            if (groupOff < 0)
                groupOff := 0
            x := seg.cx + groupOff
            curCellX := 0, curCellW := 0

            for idx, i in visible {
                w := labelsW[i]
                if (i = CurrentDesktop) {
                    curCellX := x, curCellW := w
                } else {
                    lbl := (i <= labels.Length) ? labels[i] : (i "")
                    if gradientTx {
                        hBM := TextOnGradient(w, seg.ch, this.DesktopLayoutColors, lbl, Bar_FontSize, "text", FontName, this.BgGradBM, Round(x), C1(Color_Bg), this.DesktopLayoutAlign)
                        ctrl := g.Add("Picture", Format("x{} y{} w{} h{}", Round(x), seg.cy, w, seg.ch), hBM ? "HBITMAP:" hBM : "")
                        ctrl.hBM := hBM
                    } else {
                        cOpt := layoutBg ? "c" tBgColor : ""
                        ctrl := g.Add("Text", Format("x{} y{} w{} h{} {} BackgroundTrans {}"
                            , Round(x), seg.cy, w, seg.ch, this.DesktopLayoutAlign, cOpt), lbl)
                        ctrl.SetFont("s" Bar_FontSize " w600", FontName)
                    }
                    this.DesktopCellCtrls.Push(ctrl)
                }
                x += w + sepW
            }

            if (curCellW > 0) {
                if (curColor.HasOwnProp("colors") && curColor.colors.Length > 0) {
                    hBM := this._GradBgBM(curCellW, seg.ch, curColor.colors, curColor.rounded, 0, tBgColor)
                    if hBM {
                        pic := g.Add("Picture", Format("x{} y{} w{} h{}", Round(curCellX), seg.cy, curCellW, seg.ch), "HBITMAP:" hBM)
                        this.DesktopCellCtrls.Push(pic)
                    }
                }
                curLbl := (CurrentDesktop <= labels.Length) ? labels[CurrentDesktop] : (CurrentDesktop "")
                curLabel := lft curLbl rgt
                curCtrl := g.Add("Text", Format("x{} y{} w{} h{} {} BackgroundTrans c{}"
                    , Round(curCellX), seg.cy, curCellW, seg.ch, this.DesktopLayoutAlign, tBgColor), curLabel)
                curCtrl.SetFont("s" Bar_FontSize " w600", FontName)
                this.DesktopCellCtrls.Push(curCtrl)
            }
            return
        }

        if !IsObject(this.DesktopsCtrl)
            return
        sep := this.IsHorizontal() ? "  " : "`n"
        str := ""
        Loop DesktopCount {
            i := A_Index
            lbl := (i <= labels.Length) ? labels[i] : (i "")
            show := true
            if (mode = "current")
                show := (i = CurrentDesktop)
            else if (mode = "occupied")
                show := (i = CurrentDesktop) || (Desktops.Has(i) && Desktops[i].Length > 0)
            if !show
                continue
            cell := (i = CurrentDesktop) ? (lft lbl rgt) : lbl
            str .= (str = "" ? "" : sep) cell
        }
        if (str != (this.LastVals.Has("desktops") ? this.LastVals["desktops"] : "")) {
            if this.GradText.Has("desktops")
                this._UpdateGradText("desktops", str)
            else
                try this.DesktopsCtrl.Value := str
            this.LastVals["desktops"] := str
        }
    }

    UpdateClock(pct) {
        global Bar_Cfg
        if IsObject(this.TimeCtrl) {
            val := FormatTime(, Bar_Cfg["time_format"])
            if (val != (this.LastVals.Has("time") ? this.LastVals["time"] : "")) {
                if this.GradText.Has("time")
                    this._UpdateGradText("time", val)
                else
                    try this.TimeCtrl.Value := val
                this.LastVals["time"] := val
            }
        }
        if IsObject(this.DateCtrl) {
            val := FormatTime(, Bar_Cfg["date_format"])
            if (val != (this.LastVals.Has("date") ? this.LastVals["date"] : "")) {
                if this.GradText.Has("date")
                    this._UpdateGradText("date", val)
                else
                    try this.DateCtrl.Value := val
                this.LastVals["date"] := val
            }
        }
        for w in BarInstance.SysWidgets {
            ctrl := this.%w.ctrl%
            if IsObject(ctrl) {
                val := GetSysInfo(w.sysFn)
                if (val != (this.LastVals.Has(w.key) ? this.LastVals[w.key] : "")) {
                    if this.GradText.Has(w.gradKey)
                        this._UpdateGradText(w.gradKey, val)
                    else
                        try ctrl.Value := val
                    this.LastVals[w.key] := val
                }
            }
        }
        if (this.ProgHasGradient && IsObject(this.ProgGradientPic)) {
            newBM := 0, doUpdate := false
            if (this.IsHorizontal()) {
                fillW := Round(this.ProgW * pct / 100)
                if (fillW > 0) {
                    hBM := CreateGradient(fillW, this.ProgH, 0, this.ProgGradientColors*)
                    if (hBM) {
                        this.ProgGradientPic.Value := "HBITMAP:" hBM
                        this.ProgGradientPic.Move(Round(this.ProgX), Round(this.ProgY), fillW, this.ProgH)
                        this.ProgGradientPic.Visible := true
                        newBM := hBM, doUpdate := true
                    }
                } else {
                    this.ProgGradientPic.Visible := false
                }
            } else {
                fillH := Round(this.ProgH * pct / 100)
                if (fillH > 0) {
                    hBM := CreateGradient(this.ProgW, fillH, 1, this.ProgGradientColors*)
                    if (hBM) {
                        this.ProgGradientPic.Value := "HBITMAP:" hBM
                        this.ProgGradientPic.Move(Round(this.ProgX), Round(this.ProgY), this.ProgW, fillH)
                        this.ProgGradientPic.Visible := true
                        newBM := hBM, doUpdate := true
                    }
                } else {
                    this.ProgGradientPic.Visible := false
                }
            }
            if (doUpdate) {
                if (this.ProgOldBM)
                    DllCall("Gdi32.dll\DeleteObject", "Ptr", this.ProgOldBM)
                this.ProgOldBM := newBM
            }
        }
        if IsObject(this.Progress)
            try this.Progress.Value := Integer(pct)
    }

    Show()    => (this.Gui ? this.Gui.Show("NoActivate") : 0)
    Hide() {
        if IsObject(this.Gui)
            try DllCall("ShowWindow", "Ptr", this.Gui.Hwnd, "Int", 0)
    }
    Destroy() {
        for _el, gi in this.GradText {
            if (gi.oldBM)
                DllCall("Gdi32.dll\DeleteObject", "Ptr", gi.oldBM)
        }
        this.LastVals := Map()
        this.GradText := Map()
        if (this.ProgOldBM)
            DllCall("Gdi32.dll\DeleteObject", "Ptr", this.ProgOldBM)
        if (this.BgGradBM)
            DllCall("Gdi32.dll\DeleteObject", "Ptr", this.BgGradBM)
        for hBM in this.TaskMarkerBMs
            DllCall("Gdi32.dll\DeleteObject", "Ptr", hBM)
        this.TaskMarkerBMs := []
        for ctrl in this.DesktopCellCtrls {
            try {
                if (ctrl.HasOwnProp("hBM") && ctrl.hBM)
                    DllCall("Gdi32.dll\DeleteObject", "Ptr", ctrl.hBM)
            }
        }
        this.DesktopCellCtrls := []
        this.DesktopCurColor := Map()
        this.DesktopLayoutColors := []
        this.DesktopLayoutMode := "text"
        this.DesktopLayoutRounded := "off"
        if IsObject(this.Gui)
            try this.Gui.Destroy()
        this.Gui := ""
    }
}

; ---- BarInstances / 实例解析 ----
BarInstances() {
    global Bar_Cfg, Bar_MonitorIdx
    out := []
    monCount := MonitorGetCount()
    spec   := Bar_Cfg.Has("instances") ? Bar_Cfg["instances"] : ""
    defPos := Bar_Cfg.Has("position")  ? Bar_Cfg["position"]  : "top"
    defOff := Bar_Cfg.Has("offset")    ? Bar_Cfg["offset"]    : 0
    if !(defPos ~= "^(top|bottom)$")
        defPos := "top"

    if (Trim(spec) != "") {
        for clause in StrSplit(spec, ";") {
            clause := Trim(clause)
            if (clause = "")
                continue
            p := StrSplit(clause, ",")
            if (p.Length < 1)
                continue
            mraw := Trim(p[1])
            pos  := (p.Length >= 2 && Trim(p[2]) != "") ? StrLower(Trim(p[2])) : defPos
            off  := (p.Length >= 3 && IsInteger(Trim(p[3]))) ? Integer(Trim(p[3])) : defOff
            if !(pos ~= "^(top|bottom)$")
                pos := "top"
            mons := []
            if (mraw = "*") {
                Loop monCount
                    mons.Push(A_Index)
            } else if (IsInteger(mraw) && Integer(mraw) >= 1 && Integer(mraw) <= monCount) {
                mons.Push(Integer(mraw))
            } else {
                WMLog("Bar instance skipped (bad monitor '" mraw "'): " clause)
                continue
            }
            for m in mons
                out.Push({mon:m, pos:pos, offset:off})
        }
    }
    if (out.Length = 0) {
        mon := (Bar_MonitorIdx >= 1 && Bar_MonitorIdx <= monCount) ? Bar_MonitorIdx : 1
        out.Push({mon:mon, pos:defPos, offset:defOff})
    }
    return out
}

; ---- IsBarWindow / 窗口判定 ----
IsBarWindow(hwnd) {
    global Bars
    if !IsSet(Bars)
        return false
    for b in Bars {
        if (IsObject(b.Gui) && hwnd = b.Gui.Hwnd)
            return true
    }
    return false
}

; ---- Monitors that own a bar / 有 bar 的显示器集合 ----
BarMonitorSet() {
    global Bars
    s := Map()
    if IsSet(Bars) {
        for b in Bars
            s[b.Mon] := true
    }
    return s
}

; ---- BarReserve / 区域预留 ----
BarReserve(monIdx, &L, &T, &R, &B) {
    global Bars, Bar_ShownState
    if (!IsSet(Bars) || !Bar_ShownState)
        return
    margin := 5
    for b in Bars {
        if (b.Mon != monIdx)
            continue
        reserve := b.Thick + b.Offset + margin
        switch b.Pos {
            case "bottom": B -= reserve
            default:       T += reserve
        }
    }
}

; ---- DestroyAllBars / 销毁全部 ----
DestroyAllBars() {
    global Bars
    if !IsSet(Bars)
        return
    for b in Bars {
        try {
            for ctrl in b.DesktopCellCtrls {
                try {
                    if (ctrl.HasOwnProp("hBM") && ctrl.hBM)
                        DllCall("Gdi32.dll\DeleteObject", "Ptr", ctrl.hBM)
                }
            }
            b.DesktopCellCtrls := []
            for _el, gi in b.GradText {
                try {
                    if (gi.oldBM)
                        DllCall("Gdi32.dll\DeleteObject", "Ptr", gi.oldBM)
                }
            }
            b.GradText := Map()
            if (b.ProgOldBM) {
                try DllCall("Gdi32.dll\DeleteObject", "Ptr", b.ProgOldBM)
                b.ProgOldBM := 0
            }
            if (b.BgGradBM) {
                try DllCall("Gdi32.dll\DeleteObject", "Ptr", b.BgGradBM)
                b.BgGradBM := 0
            }
            if IsObject(b.Gui) {
                try b.Gui.Destroy()
                b.Gui := ""
            }
        }
    }
    Bars := []
}

; ---- CreateStatusBar / 创建全部 ----
CreateStatusBar() {
    global Bars, Bar_ShownState
    DestroyAllBars()
    Bars := []
    barIdx := 0
    for inst in BarInstances() {
        barIdx++
        try Bars.Push(BarInstance(inst.mon, inst.pos, inst.offset, barIdx))
        catch Error as e
            WMLog("Bar build failed (mon " inst.mon " bar " barIdx "): " e.Message)
    }
    Bar_ShownState := true
    ApplyBarVisibility()
    UpdateStatusBar()
}

; ---- UpdateStatusBar / 桌面刷新 ----
UpdateStatusBar() {
    global Bars
    if !IsSet(Bars)
        return
    for b in Bars
        try b.UpdateDesktops()
}

; ---- UpdateClockAndProgress / 每秒刷新 ----
UpdateClockAndProgress() {
    global Bars
    static LastDay := ""
    CurrentDay := FormatTime(, "yyyyMMdd")
    if (LastDay != "" && LastDay != CurrentDay)
        WMGuard("Tick: CreateStatusBar (midnight)", CreateStatusBar)
    LastDay := CurrentDay
    if !IsSet(Bars)
        return
    pct := 100
    try pct := WorkPercent()
    catch Error as e
        WMLogErr("Tick: WorkPercent", e)
    for b in Bars
        try b.UpdateClock(pct)
    try ApplyBarVisibility()
    catch Error as e
        WMLogErr("Tick: ApplyBarVisibility", e)
    try ApplyPauseOnFullscreen()
    catch Error as e
        WMLogErr("Tick: ApplyPauseOnFullscreen", e)
}

; ---- HasFullscreenWindow / 全屏检测 ----
HasFullscreenWindow(targetMon) {
    for hwnd in GetVisibleWindow() {
        try {
            if (WinGetMinMax(hwnd) = -1)
                continue
            cls := WinGetClass(hwnd)
            if (cls = "Progman" || cls = "WorkerW" || cls = "Shell_TrayWnd")
                continue
            WinGetPos(&wx, &wy, &ww, &wh, hwnd)
            if (ww < 100 || wh < 100)
                continue
            mon := GetMonitorIndexAtPoint(wx + ww//2, wy + wh//2)
            if (mon != targetMon)
                continue
            MonitorGet(mon, &mL, &mT, &mR, &mB)
            if (wx <= mL + 2 && wy <= mT + 2 && wx + ww >= mR - 2 && wy + wh >= mB - 2)
                return true
        }
    }
    return false
}

; ---- ApplyBarVisibility / 可见性 ----
ApplyBarVisibility() {
    global Bars, Bar_Visible, Bar_AutoHide, Bar_FsHidden, Bar_ShownState
    if !IsSet(Bars)
        return

    anyHidden := false
    anyShown  := false

    for b in Bars {
        if !Bar_Visible {
            b.Hide()
            anyHidden := true
            continue
        }
        fsHidden := (Bar_AutoHide && HasFullscreenWindow(b.Mon))
        if fsHidden {
            b.Hide()
            anyHidden := true
        } else {
            b.Show()
            anyShown := true
        }
    }

    Bar_FsHidden  := anyHidden
    Bar_ShownState := anyShown
}

; ---- Read the pause-on-fullscreen mode / 全屏暂停模式读取 ----
PauseModeRead(raw, def := "bar") {
    m := StrLower(Trim(raw))
    if (m = "all" || m = "on" || m = "1" || m = "true")
        return "all"
    if (m = "bar")
        return "bar"
    if (m = "off" || m = "0" || m = "false")
        return "off"
    return def
}

; ---- Which monitor holds a fullscreen window (participating monitors only) / 哪个显示器上有全屏窗口 ----
HasFullscreenMonitor(mode) {
    global PauseOnFullscreenMode
    if (mode = "off")
        return false
    if (mode = "all") {
        Loop MonitorGetCount() {
            if HasFullscreenWindow(A_Index)
                return true
        }
        return false
    }
    for mon, _ in BarMonitorSet() {
        if HasFullscreenWindow(mon)
            return true
    }
    return false
}

; ---- ApplyPauseOnFullscreen / 全屏暂停 ----
ApplyPauseOnFullscreen() {
    global PauseOnFullscreenMode
    static wasPaused := false
    mode := PauseOnFullscreenMode
    if (mode != "all" && mode != "bar")
        mode := "off"
    fullscreen := HasFullscreenMonitor(mode)
    if fullscreen && !wasPaused {
        Suspend true
        wasPaused := true
    } else if !fullscreen && wasPaused {
        Suspend false
        wasPaused := false
    }
}

; ---- Toggle status bar / 显隐状态栏 ----
ToggleBar(*) {
    global Bar_Visible
    Bar_Visible := !Bar_Visible
    ApplyBarVisibility()
}

; ---- Toggle always-visible pin / 常显窗口 ----
TogglePin(*) {
    global AlwaysVisible, DesktopIsSwitching
    if DesktopIsSwitching
        return
    hwnd := 0
    try hwnd := WinExist("A")
    if (!hwnd || IsBarWindow(hwnd))
        return

    if AlwaysVisible.Has(hwnd) {
        AlwaysVisible.Delete(hwnd)
        PinBorder.Remove(hwnd)
        try WinSetAlwaysOnTop(0, hwnd)
        _RemoveFromAllDesktops(hwnd)
        if Desktops.Has(CurrentDesktop)
            Desktops[CurrentDesktop].InsertAt(1, hwnd)
        ShowOSD("Unpinned")
    } else {
        AlwaysVisible[hwnd] := true
        PinBorder.Add(hwnd)
        try WinSetAlwaysOnTop(1, hwnd)
        ShowOSD("Pinned (Always Visible)")
    }
}

; ---- Gather all windows to the current desktop / 聚集全部 ----
GatherAllToCurrent(*) {
    global Desktops, CurrentDesktop, AlwaysVisible, DesktopIsSwitching
    if DesktopIsSwitching
        return
    ShowOSD("Gathering All Windows...")

    Loop DesktopCount {
        if Desktops.Has(A_Index) {
            for h in Desktops[A_Index]
                try ShowWin(h)
        }
    }

    fullList := WinGetList()
    Loop DesktopCount
        Desktops[A_Index] := []
    AlwaysVisible.Clear()
    PinBorder.RemoveAll()
    count := 0

    for hwnd in fullList {
        try {
            if IsBarWindow(hwnd)
                continue
            winClass := WinGetClass(hwnd)
            if (winClass == "Progman" || winClass == "Shell_TrayWnd")
                continue
            ex := WinGetExStyle(hwnd)
            if (ex & 0x80)
                continue
            WinRestore(hwnd)
            Desktops[CurrentDesktop].Push(hwnd)
            count++
        }
    }
    ShowOSD("Gathered " . count . " Windows")
    WTM.OnWindowChanged()
}

; ==============================================================================
; 14. Smart Tiling / 智能平铺
; ==============================================================================

; ---- Set protected tiling boundary / 平铺外边 ----
SetTileBound(l, t, r, b) {
    global TileBound_L, TileBound_T, TileBound_R, TileBound_B, TileBoundSet
    TileBound_L := l, TileBound_T := t, TileBound_R := r, TileBound_B := b
    TileBoundSet := true
}

; ---- Clear protected tiling boundary / 平铺外边 ----
ClearTileBound() {
    global TileBoundSet
    TileBoundSet := false
}

; ---- Tiling area of a monitor / 计算某显示器的平铺区域 ----
GetTileArea(monIdx, gapBase, &X, &Y, &W, &H) {
    MonitorGetWorkArea(monIdx, &WL, &WT, &WR, &WB)
    BarReserve(monIdx, &WL, &WT, &WR, &WB)
    W := WR - WL, H := WB - WT
    edgeMargin := gapBase / 2
    if (edgeMargin > 0) {
        WL += edgeMargin, WT += edgeMargin
        W -= edgeMargin * 2, H -= edgeMargin * 2
    }
    X := WL, Y := WT
}

; ==============================================================================
; Slot table / 槽位表
; ==============================================================================
SlotFromSpan(xlo, xhi, ylo, yhi, src) {
    return { xlo: xlo, xhi: xhi, ylo: ylo, yhi: yhi
           , cx: (xlo + xhi) / 2, cy: (ylo + yhi) / 2
           , xfull: (xlo <= 1.0e-9 && xhi >= 1 - 1.0e-9)
           , yfull: (ylo <= 1.0e-9 && yhi >= 1 - 1.0e-9)
           , src: src }
}

; ---- Which slot contains a point (0 = none) / 归一化坐标落在哪个槽位 ----
SlotIndexAtPoint(table, nx, ny) {
    eps := 1.0e-9
    for k, t in table {
        if (nx < t.xlo - eps || nx > t.xhi + eps)
            continue
        if (ny < t.ylo - eps || ny > t.yhi + eps)
            continue
        return k
    }
    return 0
}

; ---- Bounding box of measurable rects / 一组矩形的外框 ----
RectBBox(recs, &x0, &y0, &bw, &bh) {
    found := false
    for r in recs {
        if (r.HasProp("claim") && !r.claim)
            continue
        if !found {
            x0 := r.x, y0 := r.y, x1 := r.x + r.w, y1 := r.y + r.h, found := true
            continue
        }
        x0 := Min(x0, r.x), y0 := Min(y0, r.y)
        x1 := Max(x1, r.x + r.w), y1 := Max(y1, r.y + r.h)
    }
    if !found
        x0 := recs[1].x, y0 := recs[1].y, bw := Max(1, recs[1].w), bh := Max(1, recs[1].h)
    else
        bw := Max(1, x1 - x0), bh := Max(1, y1 - y0)
}

; ---- Sort rects into rows, then by x (returns a new array) / 行带排序 ----
SortRowsByX(recs) {
    n := recs.Length
    out := []
    for r in recs
        out.Push(r)
    if (n < 2)
        return out
    Loop (n - 1) {
        i := A_Index + 1
        me := out[i]
        my := me.y + me.h / 2
        j := i - 1
        while (j >= 1 && (out[j].y + out[j].h / 2) > my) {
            out[j + 1] := out[j]
            j -= 1
        }
        out[j + 1] := me
    }
    s := 1
    Loop n {
        i := A_Index
        if (i < n) {
            a := out[s], b := out[i + 1]
            if (b.y + b.h / 2 - (a.y + a.h / 2) <= 0.4 * Min(a.h, b.h))
                continue
        }
        Loop (i - s) {
            k := s + A_Index
            me := out[k]
            mx := me.x + me.w / 2
            j := k - 1
            while (j >= s && (out[j].x + out[j].w / 2) > mx) {
                out[j + 1] := out[j]
                j -= 1
            }
            out[j + 1] := me
        }
        s := i + 1
    }
    return out
}

; ---- Map measured rects onto slots / 把实测矩形认回槽位 ----
SlotAssign(recs, table, x0, y0, bw, bh, &filled) {
    n := recs.Length
    out := [], free := []
    loop n {
        out.Push(0)
        free.Push(true)
    }
    rest := []
    for i, r in recs {
        k := 0
        if !(r.HasProp("claim") && !r.claim)
            k := SlotIndexAtPoint(table, (r.x + r.w / 2 - x0) / bw, (r.y + r.h / 2 - y0) / bh)
        if !k || out[k] {
            rest.Push({x: r.x, y: r.y, w: r.w, h: r.h, idx: i})
            continue
        }
        out[k] := i, free[k] := false
    }
    filled := rest.Length
    if (filled = 0)
        return out
    for r in SortRowsByX(rest) {
        nx := (r.x + r.w / 2 - x0) / bw, ny := (r.y + r.h / 2 - y0) / bh
        best := 0, bestD := 0
        for k, t in table {
            if !free[k]
                continue
            d := Sqrt((nx - t.cx) ** 2 + (ny - t.cy) ** 2)
            if (!best || d < bestD)
                best := k, bestD := d
        }
        if !best
            break
        out[best] := r.idx, free[best] := false
    }
    return out
}

; ---- Dry-run the built-in algorithms / 空跑内置算法得到槽位表 ----
BuildBuiltinSlotTable(n, W, H) {
    global TileSink, CurrentTileGap, TileBoundSet
    if (n < 1 || W <= 0 || H <= 0)
        return []
    rects := []
    dummy := []
    loop n
        dummy.Push(A_Index)
    savedSink := TileSink, savedGap := CurrentTileGap, savedBound := TileBoundSet
    TileSink := (hwnd, x, y, w, h) => rects.Push({x: x, y: y, w: w, h: h})
    CurrentTileGap := 0
    TileBoundSet := false
    try {
        switch _GetTileMode(W, H) {
            case "Vertical":  TileVertical(dummy, 0, 0, W, H)
            case "Ultrawide": TileUltrawide(dummy, 0, 0, W, H)
            default:          TileNormal(dummy, 0, 0, W, H)
        }
    } finally {
        TileSink := savedSink
        CurrentTileGap := savedGap
        TileBoundSet := savedBound
    }
    table := []
    for i, r in rects
        table.Push(SlotFromSpan(r.x / W, (r.x + r.w) / W, r.y / H, (r.y + r.h) / H, "builtin"))
    return table
}

; ---- Get slot table for (monitor, window count), cached / 取槽位表 ----
GetSlotTable(monIdx, n, W, H) {
    global SlotTableCache
    key := monIdx . "|" . n . "|" . Round(W) . "x" . Round(H)
    if SlotTableCache.Has(key)
        return SlotTableCache[key]
    rules := GetCustomLayout(monIdx, n)
    table := []
    if (rules != "") {
        for i, r in rules
            table.Push(SlotFromSpan(r.x.lo, r.x.hi, r.y.lo, r.y.hi, "custom"))
    } else {
        table := BuildBuiltinSlotTable(n, W, H)
    }
    SlotTableCache[key] := table
    return table
}

; ---- Invalidate the cache (on config/rule change) / 清空槽位表缓存 ----
InvalidateSlotTables() {
    global SlotTableCache
    SlotTableCache := Map()
}

; ---- Directional pick on the slot table / 槽位表上的方向选择 ----
PickSlotFromTable(table, i, dir) {
    n := table.Length
    if (i < 1 || i > n)
        return 0
    cur := table[i]
    horizontal := (dir = "L" || dir = "R")
    if (horizontal ? cur.xfull : cur.yfull)
        return 0
    primary   := horizontal ? "cx" : "cy"
    secondary := horizontal ? "cy" : "cx"
    forward   := (dir = "R" || dir = "D")

    all := []
    for j, _ in table {
        if (j != i)
            all.Push(j)
    }
    if (all.Length = 0)
        return 0

    cand := NarrowByBand(all, table, cur, horizontal)

    myLo := horizontal ? cur.xlo : cur.ylo
    myHi := horizontal ? cur.xhi : cur.yhi

    past := []
    for j in cand {
        t := table[j]
        loJ := horizontal ? t.xlo : t.ylo
        hiJ := horizontal ? t.xhi : t.yhi
        if (forward ? (loJ >= myHi - 1.0e-9) : (hiJ <= myLo + 1.0e-9))
            past.Push(j)
    }
    if (past.Length = 0) {
        for j in all {
            t := table[j]
            if (forward ? (t.%primary% > cur.%primary% + 1.0e-9)
                       : (t.%primary% < cur.%primary% - 1.0e-9))
                past.Push(j)
        }
        if (past.Length = 0)
            return 0
        past := NarrowByBand(past, table, cur, horizontal)
        if (past.Length > 1) {
            loKey := horizontal ? "ylo" : "xlo"
            hiKey := horizontal ? "yhi" : "xhi"
            best := -1.0e18
            for j in past {
                ov := Min(cur.%hiKey%, table[j].%hiKey%) - Max(cur.%loKey%, table[j].%loKey%)
                if (ov > best)
                    best := ov
            }
            keep := []
            for j in past {
                ov := Min(cur.%hiKey%, table[j].%hiKey%) - Max(cur.%loKey%, table[j].%loKey%)
                if (ov >= best - 1.0e-9)
                    keep.Push(j)
            }
            past := keep
        }
    }
    cand := past
    if (cand.Length = 1)
        return cand[1]

    cand := NarrowByAxis(cand, table, cur, primary)
    if (cand.Length = 1)
        return cand[1]

    cand := NarrowByAxis(cand, table, cur, secondary)
    if (cand.Length = 1)
        return cand[1]

    pick := 0, best := 0
    for j in cand {
        d := table[j].%secondary% - cur.%secondary%
        if (d < 0 && (!pick || d > best)) {
            best := d
            pick := j
        }
    }
    return pick ? pick : cand[1]
}

; ---- Narrow by the cross-axis band / 按垂直轴同一条带收窄 ----
NarrowByBand(cand, table, cur, horizontal) {
    loKey := horizontal ? "ylo" : "xlo"
    hiKey := horizontal ? "yhi" : "xhi"
    cLo := cur.%loKey%, cHi := cur.%hiKey%
    out := []
    for j in cand {
        if (Min(cHi, table[j].%hiKey%) - Max(cLo, table[j].%loKey%) > 1.0e-9)
            out.Push(j)
    }
    if (out.Length)
        return out
    best := 1.0e18
    for j in cand {
        gap := Max(0, Max(cLo - table[j].%hiKey%, table[j].%loKey% - cHi))
        if (gap < best)
            best := gap
    }
    for j in cand {
        if (Max(0, Max(cLo - table[j].%hiKey%, table[j].%loKey% - cHi)) <= best + 1.0e-9)
            out.Push(j)
    }
    return out
}

; ---- Narrow candidates by minimal axis delta / 按某轴差值最小收窄 ----
NarrowByAxis(cand, table, cur, axis) {
    best := 1.0e18
    for j in cand {
        d := Abs(table[j].%axis% - cur.%axis%)
        if (d < best)
            best := d
    }
    out := []
    for j in cand {
        if (Abs(table[j].%axis% - cur.%axis%) <= best + 1.0e-9)
            out.Push(j)
    }
    return out
}

; ---- Resize spans on one axis (pure; 0 when unchanged) / 缩放跨度 ----
ResizeSpans(spans, i, grow, delta, minSpan) {
    n := spans.Length
    if (i < 1 || i > n)
        return 0
    me := spans[i]
    if (me.hi - me.lo <= minSpan + 1.0e-9 && !grow)
        return 0

    eps := 1.0e-9
    loSame := [], loGiver := []
    hiSame := [], hiGiver := []
    for j, s in spans {
        if (j = i)
            continue
        if (Abs(s.lo - me.lo) <= eps)
            loSame.Push(j)
        if (Abs(s.hi - me.lo) <= eps)
            loGiver.Push(j)
        if (Abs(s.hi - me.hi) <= eps)
            hiSame.Push(j)
        if (Abs(s.lo - me.hi) <= eps)
            hiGiver.Push(j)
    }

    newLo := me.lo, newHi := me.hi

    if grow {
        tgt := Max(me.lo - delta, 0.0)
        for j in loGiver
            tgt := Max(tgt, spans[j].lo + minSpan)
        if (tgt < me.lo - eps)
            newLo := tgt
    } else if (loGiver.Length) {
        tgt := me.lo + delta
        for j in loSame
            tgt := Min(tgt, spans[j].hi - minSpan)
        tgt := Min(tgt, me.hi - minSpan)
        if (tgt > me.lo + eps)
            newLo := tgt
    }

    if grow {
        tgt := Min(me.hi + delta, 1.0)
        for j in hiGiver
            tgt := Min(tgt, spans[j].hi - minSpan)
        if (tgt > me.hi + eps)
            newHi := tgt
    } else if (hiGiver.Length) {
        tgt := me.hi - delta
        for j in hiSame
            tgt := Max(tgt, spans[j].lo + minSpan)
        tgt := Max(tgt, newLo + minSpan)
        if (tgt < me.hi - eps)
            newHi := tgt
    }

    if (Abs(newLo - me.lo) <= eps && Abs(newHi - me.hi) <= eps)
        return 0

    out := []
    for j, s in spans {
        lo := s.lo, hi := s.hi
        if (j = i) {
            lo := newLo, hi := newHi
        } else {
            if (Abs(s.hi - me.lo) <= eps)
                hi := newLo
            if (Abs(s.lo - me.lo) <= eps)
                lo := newLo
            if (Abs(s.lo - me.hi) <= eps)
                lo := newHi
            if (Abs(s.hi - me.hi) <= eps)
                hi := newHi
        }
        out.Push({lo: lo, hi: hi})
    }
    return out
}

; ---- Quantise spans to the pixel grid (pure) / 量化到像素栅格 ----
QuantizeSpans(spans, D) {
    out := []
    for s in spans {
        lo := Max(0.0, Min(1.0, Round(s.lo * D) / D))
        hi := Max(0.0, Min(1.0, Round(s.hi * D) / D))
        if (hi - lo < 1.0 / D)
            hi := Min(1.0, lo + 1.0 / D)
        out.Push({lo: lo, hi: hi})
    }
    return out
}

; ---- Rules to a config string (pasteable into [Tiling] Rules) / 规则数组转配置串 ----
RuleStringFor(rules, W, H) {
    out := ""
    n := rules.Length
    for i, r in rules {
        out .= (i > 1 ? ";" : "") . n . "," . i . "," . LayoutAxisToken(r.x.lo, r.x.hi, W) . "," . LayoutAxisToken(r.y.lo, r.y.hi, H)
    }
    return out . ";"
}

; ---- One axis to a config token / 单个轴转配置记号 ----
LayoutAxisToken(lo, hi, D) {
    D := Round(D)
    if (D <= 0)
        D := 1
    if (lo <= 1.0e-9 && hi >= 1.0 - 1.0e-9)
        return "1"
    b := Round(hi * D)
    if (lo <= 1.0e-9) {
        if (b < 1)
            b := 1
        return b . "/" . D
    }
    a := Round(lo * D) + 1
    if (b < a)
        b := a
    if (b > D)
        b := D
    return "(" . a . "-" . b . ")/" . D
}

; ---- Determine tile mode by aspect ratio / 按宽高比确定平铺模式 ----
_GetTileMode(W, H) {
    if (H > W)
        return "Vertical"
    if (H != 0 && W / H >= 32/9 - 0.15)
        return "Ultrawide"
    return "Normal"
}

; ---- Single tiling entry point (shared by TileSmart / WinSelect / WTM) / 显示器平铺唯一入口 ----
; ---- Canonical per-monitor tiling entry (shared by TileSmart / WinSelect / WTM) ----
TileWindowsOnMonitor(wins, monIdx, gapBase, useDwmComp := true) {
    global CurrentTileGap
    if (wins.Length = 0)
        return false
    if (monIdx < 1 || monIdx > MonitorGetCount())
        monIdx := 1
    MonitorGetWorkArea(monIdx, &WL, &WT, &WR, &WB)
    BarReserve(monIdx, &WL, &WT, &WR, &WB)
    SetTileBound(WL, WT, WR, WB)
    W := WR - WL, H := WB - WT
    gapEff := gapBase + (useDwmComp ? GetDWMGapCompensation(wins) : 0)
    edgeMargin := gapBase / 2
    if (edgeMargin > 0) {
        WL += edgeMargin, WT += edgeMargin, W -= edgeMargin * 2, H -= edgeMargin * 2
    }
    CurrentTileGap := gapEff
    usedCustom := ApplyCustomLayout(wins, WL, WT, W, H, monIdx)
    if !usedCustom {
        switch _GetTileMode(W, H) {
            case "Vertical":  TileVertical(wins, WL, WT, W, H)
            case "Ultrawide": TileUltrawide(wins, WL, WT, W, H)
            default:          TileNormal(wins, WL, WT, W, H)
        }
    }
    CurrentTileGap := 0
    ClearTileBound()
    return usedCustom
}

; ---- Smart-tile the monitor under the mouse / 当前显示 ----
TileCurrentMonitor(*) {
    global Tile_Gap

    if WTM.Active {
        ShowOSD("WTM: Smart Tile Disabled")
        return
    }

    MouseGetPos(&mx, &my)
    targetMon := GetMonitorIndexAtPoint(mx, my)

    windows := GetVisibleWindowsOnMonitor(targetMon)
    n := windows.Length
    if (n == 0) {
        ShowOSD("No Windows To Tile")
        return
    }

    MonitorGetWorkArea(targetMon, &WL, &WT, &WR, &WB)
    usedCustom := TileWindowsOnMonitor(windows, targetMon, Tile_Gap, true)
    mode := usedCustom ? "Custom" : _GetTileMode(WR - WL, WB - WT)
    ShowOSD("Tile [" . mode . "] [Mon " . targetMon . "]: " . n)
}

; ---- Apply gap & bound clamp, yield the final rect / 计算最终矩形 ----
ComputeTileRect(x, y, w, h, &fx, &fy, &fw, &fh) {
    global CurrentTileGap, TileBound_L, TileBound_T, TileBound_R, TileBound_B, TileBoundSet
    if (CurrentTileGap != 0) {
        half := CurrentTileGap / 2
        x += half, y += half, w -= CurrentTileGap, h -= CurrentTileGap
    }
    if (TileBoundSet) {
        x2 := x + w, y2 := y + h
        if (x  < TileBound_L)
            x := TileBound_L
        if (y  < TileBound_T)
            y := TileBound_T
        if (x2 > TileBound_R)
            x2 := TileBound_R
        if (y2 > TileBound_B)
            y2 := TileBound_B
        w := x2 - x, h := y2 - y
    }
    fx := Round(x), fy := Round(y)
    fw := Max(50, Round(x + w) - fx), fh := Max(50, Round(y + h) - fy)
}

; ---- Move a window to an exact rect / 搬到精确矩形 ----
MoveWinTo(hwnd, x, y, w, h) {
    try {
        mm := 0
        try mm := WinGetMinMax(hwnd)
        if (mm = 0) {
            WinGetPos(&cx, &cy, &cw, &ch, hwnd)
            if (cx = x && cy = y && cw = w && ch = h)
                return false
        }
        WinRestore(hwnd)
        WinMove(x, y, w, h, hwnd)
        return true
    } catch {
        return false
    }
}

; ---- Place one window with gap & bound clamp / 摆放窗口 ----
PlaceWin(hwnd, x, y, w, h) {
    ComputeTileRect(x, y, w, h, &fx, &fy, &fw, &fh)
    return MoveWinTo(hwnd, fx, fy, fw, fh)
}

; ---- Tiling output stage / 平铺输出端 ----
EmitPlace(hwnd, x, y, w, h) {
    global TileSink
    ComputeTileRect(x, y, w, h, &fx, &fy, &fw, &fh)
    if TileSink {
        TileSink(hwnd, fx, fy, fw, fh)
        return false
    }
    return MoveWinTo(hwnd, fx, fy, fw, fh)
}

; ---- Grid tiling / 网格平铺 ----
TileGrid(wins, X, Y, W, H, isVertical := false) {
    n := wins.Length
    if (n == 0)
        return
    if (n == 1) {
        EmitPlace(wins[1], X, Y, W, H)
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
            EmitPlace(wins[idx], X + c * colW, Y + r * rowH, colW, rowH)
            idx++
        }
    }
}

; ---- Normal-aspect tiling / 常规屏平 ----
TileNormal(wins, WL, WT, W, H) {
    n := wins.Length
    switch n {
        case 3:
            EmitPlace(wins[1], WL,        WT,        W/2, H)
            EmitPlace(wins[2], WL + W/2,  WT,        W/2, H/2)
            EmitPlace(wins[3], WL + W/2,  WT + H/2,  W/2, H/2)
            return
        case 5:
            colW := W/3, halfH := H/2
            EmitPlace(wins[1], WL + colW,    WT,         colW, H)
            EmitPlace(wins[2], WL,           WT,         colW, halfH)
            EmitPlace(wins[3], WL,           WT + halfH, colW, halfH)
            EmitPlace(wins[4], WL + 2*colW,  WT,         colW, halfH)
            EmitPlace(wins[5], WL + 2*colW,  WT + halfH, colW, halfH)
            return
    }
    TileGrid(wins, WL, WT, W, H, false)
}

; ---- Vertical-monitor tiling / 竖屏平铺 ----
TileVertical(wins, X, Y, W, H) {
    n := wins.Length
    if (n <= 3) {
        itemH := H / n
        for i, hwnd in wins
            EmitPlace(hwnd, X, Y + (i-1)*itemH, W, itemH)
        return
    }
    TileGrid(wins, X, Y, W, H, true)
}

; ---- Ultrawide-monitor tiling / 超宽屏平 ----
TileUltrawide(wins, X, Y, W, H) {
    n := wins.Length
    if (n == 1) {
        mainW := Min(W, H * 16/9)
        EmitPlace(wins[1], X + (W - mainW)/2, Y, mainW, H)
        return
    }
    if (n == 2) {
        EmitPlace(wins[1], X,       Y, W/2, H)
        EmitPlace(wins[2], X + W/2, Y, W/2, H)
        return
    }
    mainW := Min(H * 16/9, W * 0.5)
    sideW := (W - mainW) / 2
    mainX := X + sideW
    EmitPlace(wins[1], mainX, Y, mainW, H)
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

; ---- Tiling eligibility check / 可平铺判 ----
IsTilableWindow(hwnd) {
    global Tile_IncludeAlwaysOnTop
    if Tile_IncludeAlwaysOnTop
        return true
    ex := 0
    try ex := WinGetExStyle(hwnd)
    return !(ex & 0x8)
}

; ---- Visible windows on one monitor / 显示器可 ----
GetVisibleWindowsOnMonitor(monIdx) {
    out := []
    for hwnd in GetVisibleWindow() {
        if !IsTilableWindow(hwnd)
            continue
        try {
            WinGetPos(&wx, &wy, &ww, &wh, hwnd)
            cx := wx + ww/2, cy := wy + wh/2
            if (GetMonitorIndexAtPoint(cx, cy) == monIdx)
                out.Push(hwnd)
        }
    }
    return out
}

; ---- Visible windows, exclusion-aware / 当前桌面 ----
GetVisibleWindow() {
    windows := []
    ids := WinGetList(,, "Program Manager")
    for this_id in ids {
        try {
            style := WinGetStyle(this_id)
            if !(style & 0x10000000)
                continue
            exStyle := WinGetExStyle(this_id)
            if (exStyle & 0x00000080)
                continue
            isCloaked := 0
            DllCall("dwmapi\DwmGetWindowAttribute"
                , "Ptr", this_id, "Int", 14, "Int*", &isCloaked, "Int", 4)
            if isCloaked
                continue
            if IsExcludedWindow(this_id)
                continue
            if (WinGetTitle(this_id) == "")
                continue
            WinGetPos(,, &w, &h, this_id)
            if (w < 100 || h < 100)
                continue
        } catch
            continue
        windows.Push(this_id)
    }
    return windows
}

; ---- Visible windows for desktop bookkeeping / 可见窗口 ----
GetVisibleWindows() {
    list := WinGetList()
    windows := []
    for hwnd in list {
        try {
            if IsBarWindow(hwnd)
                continue
            winClass := WinGetClass(hwnd)
            if (winClass == "Progman" || winClass == "Shell_TrayWnd")
                continue
            ex := WinGetExStyle(hwnd)
            if (ex & 0x80)
                continue
            if IsExcludedWindow(hwnd)
                continue
            if (WinGetMinMax(hwnd) != -1)
                windows.Push(hwnd)
        }
    }
    return windows
}

; ==============================================================================
; 15. Window Snapping / 窗口吸附
; ==============================================================================

; ---- Per-axis sticky-snap context / 吸附状态 ----
class SnapCtx {
    xOn := false, xLine := 0, xEdge := ""
    yOn := false, yLine := 0, yEdge := ""
}

; ---- Gather candidate snap lines / 收集吸附 ----
GatherSnapLines(skipHwnd, &vLines, &hLines) {
    vLines := [], hLines := []
    mon := GetMonitorIndex(skipHwnd)
    MonitorGet(mon, &mL, &mT, &mR, &mB)
    MonitorGetWorkArea(mon, &wL, &wT, &wR, &wB)
    bL := wL, bT := wT, bR := wR, bB := wB
    BarReserve(mon, &bL, &bT, &bR, &bB)
    for v in [mL, mR, wL, wR, bL, bR]
        vLines.Push(v)
    for hh in [mT, mB, wT, wB, bT, bB]
        hLines.Push(hh)
    for h in GetVisibleWindow() {
        if (h = skipHwnd)
            continue
        try {
            if (WinGetMinMax(h) = -1)
                continue
            if !GetWindowVisualRect(h, &ox, &oy, &ow, &oh)
                WinGetPos(&ox, &oy, &ow, &oh, h)
        } catch
            continue
        vLines.Push(ox)
        vLines.Push(ox + ow)
        hLines.Push(oy)
        hLines.Push(oy + oh)
    }
}

; ---- Snap one axis of a move / 移动吸附 ----
_SnapMoveAxis(edgeLo, edgeHi, size, lines, ctx, axis, &outLo) {
    global Snap_Distance, Snap_Release
    rad := Max(1, Abs(Snap_Distance)), gap := Snap_Distance, rel := Max(0, Snap_Release)
    on   := (axis = "x") ? ctx.xOn   : ctx.yOn
    line := (axis = "x") ? ctx.xLine : ctx.yLine
    edge := (axis = "x") ? ctx.xEdge : ctx.yEdge
    outLo := edgeLo
    settled := false
    if on {
        cmp := (edge = "lo") ? edgeLo : edgeHi
        if (Abs(cmp - line) <= rad + rel) {
            outLo := (edge = "lo") ? (line + gap) : (line - gap - size)
            settled := true
        } else {
            on := false
        }
    }
    if !settled {
        bestD := rad + 1, found := false
        for ln in lines {
            if (Abs(edgeLo - ln) < bestD) {
                bestD := Abs(edgeLo - ln), line := ln, edge := "lo", found := true
            }
            if (Abs(edgeHi - ln) < bestD) {
                bestD := Abs(edgeHi - ln), line := ln, edge := "hi", found := true
            }
        }
        if found {
            on := true
            outLo := (edge = "lo") ? (line + gap) : (line - gap - size)
        }
    }
    if (axis = "x") {
        ctx.xOn := on, ctx.xLine := line, ctx.xEdge := edge
    } else {
        ctx.yOn := on, ctx.yLine := line, ctx.yEdge := edge
    }
}

; ---- Snap a window move / 移动吸附 ----
SnapMove(rawX, rawY, w, h, vLines, hLines, ctx, &outX, &outY) {
    global Snap_Enable
    outX := rawX, outY := rawY
    if !Snap_Enable
        return
    _SnapMoveAxis(rawX, rawX + w, w, vLines, ctx, "x", &outX)
    _SnapMoveAxis(rawY, rawY + h, h, hLines, ctx, "y", &outY)
}

; ---- Snap one moving edge of a resize / 缩放吸附 ----
_SnapResizeAxis(movingEdge, isLowEdge, lines, ctx, axis, &outEdge) {
    global Snap_Distance, Snap_Release
    rad := Max(1, Abs(Snap_Distance)), gap := Snap_Distance, rel := Max(0, Snap_Release)
    on   := (axis = "x") ? ctx.xOn   : ctx.yOn
    line := (axis = "x") ? ctx.xLine : ctx.yLine
    outEdge := movingEdge
    settled := false
    if on {
        if (Abs(movingEdge - line) <= rad + rel) {
            outEdge := isLowEdge ? (line + gap) : (line - gap)
            settled := true
        } else {
            on := false
        }
    }
    if !settled {
        bestD := rad + 1, found := false
        for ln in lines {
            if (Abs(movingEdge - ln) < bestD) {
                bestD := Abs(movingEdge - ln), line := ln, found := true
            }
        }
        if found {
            on := true
            outEdge := isLowEdge ? (line + gap) : (line - gap)
        }
    }
    if (axis = "x") {
        ctx.xOn := on, ctx.xLine := line
    } else {
        ctx.yOn := on, ctx.yLine := line
    }
}

; ---- Snap a window resize / 缩放吸附 ----
SnapResize(nX, nW, nY, nH, winX, winY, fixedRight, fixedBottom, isLeft, isUp, vLines, hLines, ctx, &oX, &oW, &oY, &oH) {
    global Snap_Enable
    oX := nX, oW := nW, oY := nY, oH := nH
    if !Snap_Enable
        return
    if isLeft {
        _SnapResizeAxis(nX, true, vLines, ctx, "x", &sx)
        oX := sx, oW := fixedRight - sx
    } else {
        _SnapResizeAxis(nX + nW, false, vLines, ctx, "x", &sx)
        oW := sx - winX
    }
    if isUp {
        _SnapResizeAxis(nY, true, hLines, ctx, "y", &sy)
        oY := sy, oH := fixedBottom - sy
    } else {
        _SnapResizeAxis(nY + nH, false, hLines, ctx, "y", &sy)
        oH := sy - winY
    }
}

; ==============================================================================
; 16. Drag Move / Resize & Directional Snap / 拖拽移动缩放与方向吸附
; ==============================================================================

; ---- Keep WTM / all-window borders glued while dragging / 拖拽时边 ----
BorderFollowDrag(hwnd) {
    try WTM.DrawOne(hwnd)
    try AllBorders.DrawOne(hwnd)
}

; ---- Drag-move handler / 拖拽移动 ----
DragMoveHandler(*) {
    MouseGetPos(,, &hwnd)
    if !hwnd
        return
    try WinActivate(hwnd)
    if !WinExist(hwnd)
        return

    mm := 0
    try mm := WinGetMinMax(hwnd)
    if (mm == 1) {
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
    if !GetWindowVisualRect(hwnd, &vx, &vy, &vw, &vh) {
        try WinGetPos(&vx, &vy, &vw, &vh, hwnd)
        catch
            return
    }
    WinGetPos(&wx, &wy, &ww, &wh, hwnd)
    frameDX := vx - wx, frameDY := vy - wy
    frameDW := ww - vw, frameDH := wh - vh

    ctx := SnapCtx()
    vLines := [], hLines := []
    try GatherSnapLines(hwnd, &vLines, &hLines)

    DragBorder.Show()
    lastCX := "", lastCY := ""
    while GetKeyState("LButton", "P") {
        MouseGetPos(&curX, &curY)
        if (curX = lastCX && curY = lastCY) {
            Sleep(4)
            continue
        }
        lastCX := curX, lastCY := curY
        rawX := vx + (curX - startX)
        rawY := vy + (curY - startY)
        SnapMove(rawX, rawY, vw, vh, vLines, hLines, ctx, &nx, &ny)
        try WinMove(nx - frameDX, ny - frameDY,,, hwnd)
        catch
            break
        DragBorder.Update(hwnd)
        BorderFollowDrag(hwnd)
    }
    DragBorder.Destroy()
    if WTM.Active
        WTM.HandleDragDrop(hwnd)
    else
        WTM.OnWindowChanged()
}

; ---- Drag-resize handler / 拖拽缩放 ----
DragResizeHandler(*) {
    MouseGetPos(,, &hwnd)
    if !hwnd
        return
    if (WinGetMinMax(hwnd) == 1)
        return

    if !GetWindowVisualRect(hwnd, &vx, &vy, &vw, &vh) {
        try WinGetPos(&vx, &vy, &vw, &vh, hwnd)
        catch
            return
    }
    WinGetPos(&wx, &wy, &ww, &wh, hwnd)
    frameDX := vx - wx, frameDY := vy - wy
    frameDW := ww - vw, frameDH := wh - vh
    if (vw <= 0 || vh <= 0)
        return

    MouseGetPos(&startX, &startY)
    isLeft := (startX - vx) / vw < 0.5
    isUp   := (startY - vy) / vh < 0.5
    fixedRight  := vx + vw
    fixedBottom := vy + vh

    ctx := SnapCtx()
    vLines := [], hLines := []
    try GatherSnapLines(hwnd, &vLines, &hLines)

    DragBorder.Show()
    lastCX := "", lastCY := ""
    while GetKeyState("RButton", "P") {
        MouseGetPos(&curX, &curY)
        if (curX = lastCX && curY = lastCY) {
            Sleep(4)
            continue
        }
        lastCX := curX, lastCY := curY
        dX := curX - startX, dY := curY - startY
        nX := isLeft ? (vx+dX) : vx, nW := isLeft ? (vw-dX) : (vw+dX)
        nY := isUp   ? (vy+dY) : vy, nH := isUp   ? (vh-dY) : (vh+dY)
        SnapResize(nX, nW, nY, nH, vx, vy, fixedRight, fixedBottom, isLeft, isUp
                 , vLines, hLines, ctx, &nX, &nW, &nY, &nH)
        if (nW > 50 && nH > 50) {
            try WinMove(nX - frameDX, nY - frameDY, nW + frameDW, nH + frameDH, hwnd)
            catch
                break
            DragBorder.Update(hwnd)
            BorderFollowDrag(hwnd)
        }
    }
    DragBorder.Destroy()
    WTM.OnWindowChanged()
}

; ---- Directional snap (left/right halves, max/min) / 方向吸附 ----
SnapWindow(direction, *) {
    hwnd := 0
    try hwnd := WinExist("A")
    if !hwnd
        return

    targetMon := GetMonitorIndex(hwnd)
    MonitorGetWorkArea(targetMon, &L, &T, &R, &B)
    BarReserve(targetMon, &L, &T, &R, &B)
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

; ==============================================================================
; 16b. Copy Current Layout as [Tiling] Rules / 复制当前布局为配置规则串
; ==============================================================================

; ---- Order rects for rule output (pure) / 规则串排序 ----
SortRectsForRules(recs) {
    out := []
    for r in recs
        out.Push(r)
    n := out.Length
    if (n < 2)
        return out
    Loop (n - 1) {
        i := A_Index + 1
        me := out[i]
        j := i - 1
        while (j >= 1 && out[j].y > me.y) {
            out[j + 1] := out[j]
            j -= 1
        }
        out[j + 1] := me
    }
    s := 1
    Loop n {
        i := A_Index
        if (i < n) {
            a := out[s], b := out[i + 1]
            if (Abs(b.y - a.y) <= 0.4 * Min(a.h, b.h))
                continue
        }
        Loop (i - s) {
            k := s + A_Index
            me := out[k]
            j := k - 1
            while (j >= s && out[j].x > me.x) {
                out[j + 1] := out[j]
                j -= 1
            }
            out[j + 1] := me
        }
        s := i + 1
    }
    return out
}

; ---- One monitor -> rule string (pure; rects need x,y,w,h,mon) / 单显示器转规则串 ----
BuildLayoutRulesForMonitor(rects, mon, gap) {
    GetTileArea(mon, gap, &ax, &ay, &W, &H)
    if (W <= 0 || H <= 0 || rects.Length = 0)
        return ""
    ordered := SortRectsForRules(rects)
    rules := []
    for r in ordered {
        rules.Push({
            x: {lo: (r.x - ax) / W, hi: (r.x + r.w - ax) / W},
            y: {lo: (r.y - ay) / H, hi: (r.y + r.h - ay) / H}
        })
    }
    return RuleStringFor(rules, W, H)
}

; ---- Copy current layout rules to the clipboard / 复制当前布局到剪贴板 ----
CopyLayoutRules(*) {
    global Tile_Gap, WTM_Gap, WM_LogFile
    gap := WTM.Active ? WTM_Gap : Tile_Gap

    byMon := Map()
    for hwnd in GetVisibleWindow() {
        if !IsTilableWindow(hwnd)
            continue
        try {
            if (WinGetMinMax(hwnd) = -1)
                continue
            WinGetPos(&x, &y, &w, &h, hwnd)
        } catch {
            continue
        }
        m := 1
        try m := GetMonitorIndexAtPoint(x + w / 2, y + h / 2)
        if (m < 1)
            m := 1
        if !byMon.Has(m)
            byMon[m] := []
        byMon[m].Push({x: x, y: y, w: w, h: h, mon: m})
    }

    lineFor := Map()
    total := 0
    for m, rects in byMon {
        s := BuildLayoutRulesForMonitor(rects, m, gap)
        if (s != "") {
            lineFor[m] := s
            total += rects.Length
        }
    }
    if (total = 0) {
        ShowOSD("Copy Layout: No Windows")
        return
    }

    out := ""
    for m in [1, 2, 3, 4, 5, 6, 7, 8, 9] {
        if lineFor.Has(m)
            out .= lineFor[m] . "`r`n"
    }

    prevClip := ""
    try prevClip := A_Clipboard
    A_Clipboard := ""
    A_Clipboard := out
    ok := false
    try {
        if (A_Clipboard != "")
            ok := true
    }
    if !ok {
        try A_Clipboard := prevClip
        ShowOSD("Copy Layout: Clipboard Failed")
        try WMLog("CopyLayoutRules failed len=" . StrLen(out))
        return
    }
    ShowOSD("Layout Rules Copied (" . byMon.Count . " mon, " . total . " win)")
    if WM_LogLevel <= 2
        try WMLog("CopyLayoutRules mon=" . byMon.Count . " win=" . total . " len=" . StrLen(out))
}

; ==============================================================================
; 17. WTM - Windows Tile Manager (hyprland-like) / WTM 平铺模式
; ==============================================================================

; ---- Shared border drawing helpers (WTM / AllBorders) / 共享边框绘制辅助 ----
_BorderPlaceFrame(borderMap, hwnd) {
    if !borderMap.Has(hwnd)
        return
    try {
        GetWindowVisualRect(hwnd, &x, &y, &w, &h)
        if !WinExist(hwnd)
            return
    } catch {
        return
    }
    o  := Border_Offset
    ot := Border_OffsetTop
    x -= o, y -= (o + ot), w += 2*o, h += 2*o + ot
    rad := (Border_Rounded = "on") ? Border_Radius : 0
    bf := borderMap[hwnd]
    bf.BindOwner(hwnd)
    bf.Place(x, y, w, h, Max(2, Border_Thickness), rad, Border_Opacity, Border_Mode, 0)
}

; ---- Dynamic tiling mode / 动态平铺 ----
; ---- Real elapsed ms for a timer callback / 定时器回调的真实间隔 ----
TickElapsed(prev, nominal) {
    now := A_TickCount
    dt := prev ? (now - prev) : 0
    if (dt <= 0 || dt > 1000)
        dt := nominal
    return {dt: dt, now: now}
}

class WTM {
    static Active     := false
    static TileOrder  := []
    static DesktopOrders := Map()
    static Excluded   := Map()
    static FocusHwnd  := 0
    static BorderMap   := Map()
    static BorderState := Map()
    static _Placed    := Map()
    static _LastBSig  := ""
    static _LastBFocus := 0
    static _LastArea  := ""
    static _LastWins  := ""
    static _SlowAccum := 0
    static _LastTick  := 0
    static _FsMon     := Map()
    static SoloMon    := Map()
    static SoloAuto   := Map()
    static SoloHidden := Map()
    static Anim       := Map()
    static AnimStarted := false
    static TickFn     := ObjBindMethod(WTM, "Tick")
    static AnimTickFn := ObjBindMethod(WTM, "AnimTick")
    static ScrollOn      := false
    static ScrollPages   := Map()
    static ScrollView    := Map()
    static ScrollOwner   := Map()
    static ScrollPageOf  := Map()
    static ScrollDesktop := Map()
    static Overview      := false
    static OverviewRects := Map()

    static Toggle() {
        if this.Active
            this.Deactivate()
        else
            this.Activate()
    }

    static Activate() {
        global WTM_ResizeRules, WTM_LayoutOverride, CurrentDesktop
        WTM_LayoutOverride := true
        WTM_ResizeRules    := Map()
        InvalidateSlotTables()
        this.Active      := true
        this.Excluded    := Map()
        this.TileOrder   := []
        this.DestroyAllBorders()
        this.BorderMap   := Map()
        this.BorderState := Map()
        this._Placed     := Map()
        this._LastWins   := ""
        this._SlowAccum  := 0
        this._FsMon      := Map()
        this.SoloMon     := Map()
        this.SoloAuto    := Map()
        this.SoloHidden  := Map()
        this._StopAnim()
        this.FocusHwnd := 0
        try this.FocusHwnd := WinGetID("A")
        this.RebuildOrder()
        this.SeedOrderByPosition()
        this.ScrollOn      := WTM_ScrollDesktops.Has(CurrentDesktop)
        this.ScrollDesktop := Map()
        this.Overview      := false
        this.OverviewRects := Map()
        this._ScrollClear()
        if this.ScrollOn
            this._ScrollInit()
        for hwnd in this.TileOrder {
            try {
                if (WinGetMinMax(hwnd) = 1)
                    WinRestore(hwnd)
            }
        }
        this._LastArea := this._AreaSig()
        this._LastBSig := "", this._LastBFocus := 0
        this.AutoTile()
        this.RefreshBorder()
        this.LogSlotTables()
        SetTimer(this.TickFn, Border_RefreshMs)
        AllBorders.Suspend()
        ShowOSD("WTM Mode: ON")
    }

    static CleanupOnExit() {
        if (!this.Active && this.SoloHidden.Count = 0)
            return
        SetTimer(this.TickFn, 0)
        try {
            this._StopAnim()
            this._ExitSolo()
        } finally {
            this.DestroyAllBorders()
        }
    }

    static Deactivate() {
        global WTM_ResizeRules, WTM_LayoutOverride
        this.Active := false
        SetTimer(this.TickFn, 0)
        try {
            this._StopAnim()
            this._ExitSolo()
            this._GatherOffscreen()
        } catch Error as e {
            WMLogErr("WTM Deactivate", e)
        } finally {
            this.Overview      := false
            this.OverviewRects := Map()
            this.DestroyAllBorders()
            this._ForceSweepBorders()
            this._LastWins := ""
            this._Placed := Map()
            this.DesktopOrders := Map()
            this.ScrollDesktop := Map()
            this.ScrollOn := false
            this._ScrollClear()
            WTM_LayoutOverride := false
            WTM_ResizeRules    := Map()
            InvalidateSlotTables()
            AllBorders.Rebuild()
            ShowOSD("WTM Mode: OFF")
        }
    }

    static SaveOrderForDesktop(d) {
        if !this.Active
            return
        this.DesktopOrders[d] := this.TileOrder.Clone()
        if this.ScrollOn
            this.ScrollDesktop[d] := {pages: this._ScrollCopyPages(), view: this.ScrollView.Clone()}
    }

    static OnDesktopSwitched(target := 0) {
        if !this.Active
            return
        this._StopAnim()
        this._ExitSolo()
        this.DestroyAllBorders()
        this.Overview      := false
        this.OverviewRects := Map()
        this._ScrollClear()
        this.ScrollOn := (target && WTM_ScrollDesktops.Has(target))
        if (target && this.DesktopOrders.Has(target))
            this.TileOrder := this.DesktopOrders[target].Clone()
        this._Placed   := Map()
        this._LastWins := ""
        this.RebuildOrder()
        if this.ScrollOn {
            if (target && this.ScrollDesktop.Has(target))
                this._ScrollRestore(target)
            else
                this._ScrollInit()
        }
        this.AutoTile()
        this.RefreshBorder()
    }

    static OnWindowChanged() {
        if !this.Active
            return
        this.AutoTile()
        this.RefreshBorder()
    }

    static RebuildOrder() {
        alive := Map()
        for hwnd in GetVisibleWindow() {
            if this.Excluded.Has(hwnd)
                continue
            if !IsTilableWindow(hwnd)
                continue
            try {
                if (WinGetMinMax(hwnd) = -1)
                    continue
            } catch {
                continue
            }
            alive[hwnd] := true
        }
        for hwnd, _ in this.SoloHidden {
            if WinExist(hwnd)
                alive[hwnd] := true
        }
        newOrder := []
        for hwnd in this.TileOrder {
            if alive.Has(hwnd) && WinExist(hwnd) {
                newOrder.Push(hwnd)
                alive.Delete(hwnd)
            }
        }
        if (alive.Count > 0) {
            ins := 0
            if (this.FocusHwnd && WinExist(this.FocusHwnd)) {
                fi := this._OrderIndex(this.FocusHwnd)
                if fi
                    ins := fi
            }
            ins := Min(ins, newOrder.Length)
            for hwnd, _ in alive {
                if ins {
                    newOrder.InsertAt(ins + 1, hwnd)
                    ins += 1
                } else {
                    newOrder.Push(hwnd)
                }
            }
        }
        this.TileOrder := newOrder
    }

    static SeedOrderByPosition() {
        byMon := Map()
        for hwnd in GetVisibleWindow() {
            if this.Excluded.Has(hwnd)
                continue
            if !IsTilableWindow(hwnd)
                continue
            try {
                mm := WinGetMinMax(hwnd)
                if (mm = -1)
                    continue
                WinGetPos(&x, &y, &w, &h, hwnd)
            } catch {
                continue
            }
            m := 1
            try m := GetMonitorIndex(hwnd)
            if !byMon.Has(m)
                byMon[m] := []
            byMon[m].Push({hwnd: hwnd, m: m, x: x, y: y, w: w, h: h, cx: x + w / 2, cy: y + h / 2
                         , claim: (mm != 1)})
        }
        order := []
        Loop MonitorGetCount() {
            m := A_Index
            if byMon.Has(m)
                for hwnd in this._SeedMonitorOrder(m, byMon[m])
                    order.Push(hwnd)
        }
        this.TileOrder := order
    }

    static _SeedMonitorOrder(monIdx, recs) {
        n := recs.Length
        if (n = 0)
            return []
        if (n = 1)
            return [recs[1].hwnd]
        gap := WTM.Active ? WTM_Gap : Tile_Gap
        x0 := 0, y0 := 0, bw := 0, bh := 0
        GetTileArea(monIdx, gap, &x0, &y0, &bw, &bh)
        if (bw <= 0 || bh <= 0)
            RectBBox(recs, &x0, &y0, &bw, &bh)
        filled := 0
        slotOf := SlotAssign(recs, GetSlotTable(monIdx, n, bw, bh), x0, y0, bw, bh, &filled)
        res := []
        for k, i in slotOf
            if i
                res.Push(recs[i].hwnd)
        WMLog("WTM seed mon" monIdx " n" n " kept" (n - filled) " fill" filled)
        return res
    }

    static AutoTile() {
        if this.Overview
            return
        this.RebuildOrder()
        if this.ScrollOn
            this._ScrollSync()
        if (this.TileOrder.Length = 0) {
            this._Placed := Map()
            return
        }
        groups := Map()
        for hwnd in this.TileOrder {
            m := this._MonOf(hwnd)
            if (m < 1)
                m := 1
            if !groups.Has(m)
                groups[m] := []
            groups[m].Push(hwnd)
        }
        for m, wins in groups
            this._RePlace(m, wins)
    }

    static _RePlace(monIdx, wins := 0, animate := true) {
        global TileSink
        if this.Overview
            return
        if (this._FsMon.Has(monIdx) && this._FsMon[monIdx])
            return
        if this.SoloMon.Has(monIdx) {
            solo := this.SoloMon[monIdx]
            try {
                if (WinExist(solo) && WinGetMinMax(solo) = 1)
                    return
            }
        }
        if (wins = 0) {
            wins := []
            for hwnd in this.TileOrder {
                if !WinExist(hwnd)
                    continue
                if (this._MonOf(hwnd) = monIdx)
                    wins.Push(hwnd)
            }
        }
        if (this.SoloHidden.Count > 0) {
            vis := []
            for hwnd in wins {
                if !this.SoloHidden.Has(hwnd)
                    vis.Push(hwnd)
            }
            wins := vis
        }
        if (wins.Length = 0)
            return
        rects := []
        saved := TileSink
        TileSink := (hwnd, x, y, w, h) => rects.Push({hwnd: hwnd, x: x, y: y, w: w, h: h})
        try {
            if this.ScrollOn
                this._ScrollLayout(monIdx, wins)
            else
                TileWindowsOnMonitor(wins, monIdx, WTM_Gap, false)
        } finally {
            TileSink := saved
        }
        this._ApplyRects(rects, animate, monIdx)
    }

    ; ---- Scrollable tiling state / 无限滚动状态 ----
    static _MonOf(hwnd) {
        if (this.ScrollOn && this.ScrollOwner.Has(hwnd))
            return this.ScrollOwner[hwnd]
        try return GetMonitorIndex(hwnd)
        return 1
    }

    static _ScrollClear() {
        this.ScrollPages  := Map()
        this.ScrollView   := Map()
        this.ScrollOwner  := Map()
        this.ScrollPageOf := Map()
    }

    static _ScrollPagesOf(m) {
        if !this.ScrollPages.Has(m)
            this.ScrollPages[m] := [[]]
        pages := this.ScrollPages[m]
        if !(pages is Array) {
            WMLog("WTM scroll pages reset mon" m " (" Type(pages) ")")
            pages := [[]]
            this.ScrollPages[m] := pages
        }
        return pages
    }

    static _ScrollCopyPages() {
        out := Map()
        for m, pages in this.ScrollPages {
            arr := []
            if (pages is Array) {
                for group in pages
                    if (group is Array)
                        arr.Push(group.Clone())
            }
            out[m] := arr
        }
        return out
    }

    static _ScrollInit() {
        this._ScrollClear()
        for hwnd in this.TileOrder {
            m := 1
            try m := GetMonitorIndex(hwnd)
            if (m < 1)
                m := 1
            if !this.ScrollPages.Has(m)
                this.ScrollPages[m] := [[]]
            this.ScrollPages[m][1].Push(hwnd)
        }
        for m, pages in this.ScrollPages
            this.ScrollView[m] := 1
        this._ScrollReindex()
    }

    static _ScrollRestore(d) {
        snap := this.ScrollDesktop[d]
        this._ScrollClear()
        for m, pages in snap.pages {
            arr := []
            for group in pages {
                if !(group is Array)
                    continue
                g := []
                for h in group
                    if (WinExist(h) && this._OrderIndex(h))
                        g.Push(h)
                if g.Length
                    arr.Push(g)
            }
            if arr.Length
                this.ScrollPages[m] := arr
        }
        for m, pages in this.ScrollPages {
            v := snap.view.Has(m) ? snap.view[m] : 1
            this.ScrollView[m] := Max(1, Min(v, pages.Length))
        }
        this._ScrollReindex()
    }

    static _ScrollReindex() {
        this.ScrollOwner  := Map()
        this.ScrollPageOf := Map()
        loop MonitorGetCount() {
            m := A_Index
            if !this.ScrollPages.Has(m)
                continue
            pages := this._ScrollPagesOf(m)
            for p, group in pages {
                for h in group {
                    this.ScrollOwner[h]  := m
                    this.ScrollPageOf[h] := p
                }
            }
            v := this.ScrollView.Has(m) ? this.ScrollView[m] : 1
            this.ScrollView[m] := Max(1, Min(v, pages.Length))
        }
    }

    static _ScrollFlatten() {
        order := []
        loop MonitorGetCount() {
            m := A_Index
            if !this.ScrollPages.Has(m)
                continue
            for group in this.ScrollPages[m] {
                if !(group is Array)
                    continue
                for h in group
                    if WinExist(h)
                        order.Push(h)
            }
        }
        this.TileOrder := order
    }

    static _ScrollSync() {
        loop MonitorGetCount() {
            m := A_Index
            if !this.ScrollPages.Has(m)
                continue
            pages := this._ScrollPagesOf(m)
            view := this.ScrollView.Has(m) ? this.ScrollView[m] : 1
            newPages := [], remap := Map()
            for p, group in pages {
                if !(group is Array)
                    continue
                g := []
                for h in group
                    if (WinExist(h) && this._OrderIndex(h))
                        g.Push(h)
                if g.Length {
                    newPages.Push(g)
                    remap[p] := newPages.Length
                }
            }
            this.ScrollPages[m] := newPages
            if remap.Has(view)
                this.ScrollView[m] := remap[view]
            else
                this.ScrollView[m] := newPages.Length ? Min(view, newPages.Length) : 1
        }
        seen := Map()
        loop MonitorGetCount() {
            m := A_Index
            if !this.ScrollPages.Has(m)
                continue
            for group in this.ScrollPages[m] {
                for h in group
                    seen[h] := true
            }
        }
        for hwnd in this.TileOrder {
            if seen.Has(hwnd)
                continue
            m := 1, p := 1
            if (this.FocusHwnd && this.ScrollOwner.Has(this.FocusHwnd)) {
                m := this.ScrollOwner[this.FocusHwnd]
                p := this.ScrollPageOf[this.FocusHwnd]
            } else {
                try m := GetMonitorIndex(hwnd)
            }
            pages := this._ScrollPagesOf(m)
            if !this.ScrollView.Has(m)
                this.ScrollView[m] := 1
            if (pages.Length = 0) {
                pages.Push([])
                this.ScrollView[m] := 1
            }
            p := Max(1, Min(p, pages.Length))
            pages[p].Push(hwnd)
            seen[hwnd] := true
        }
        this._ScrollReindex()
        this._ScrollFlatten()
    }

    static _ScrollLayout(monIdx, wins) {
        global CurrentTileGap, TileBoundSet
        if !this.ScrollPages.Has(monIdx)
            return
        pages := this._ScrollPagesOf(monIdx)
        view  := this.ScrollView.Has(monIdx) ? this.ScrollView[monIdx] : 1
        GetTileArea(monIdx, WTM_Gap, &X, &Y, &W, &H)
        if (W <= 0 || H <= 0)
            return
        allow := Map()
        for h in wins
            allow[h] := true
        savedGap := CurrentTileGap, savedBound := TileBoundSet
        CurrentTileGap := WTM_Gap
        TileBoundSet   := false
        try {
            for p, group in pages {
                n := group.Length
                if (n < 1)
                    continue
                table := GetSlotTable(monIdx, n, W, H)
                if (table.Length < n)
                    continue
                dx := (p - view) * W
                for i, hwnd in group {
                    if (!allow.Has(hwnd) || !WinExist(hwnd))
                        continue
                    t := table[i]
                    EmitPlace(hwnd, X + dx + t.xlo * W, Y + t.ylo * H
                            , (t.xhi - t.xlo) * W, (t.yhi - t.ylo) * H)
                }
            }
        } finally {
            CurrentTileGap := savedGap
            TileBoundSet   := savedBound
        }
    }

    ; Bring off-screen windows back into view without re-tiling.
    static _PointOnAnyMonitor(x, y) {
        loop MonitorGetCount() {
            MonitorGet(A_Index, &L, &T, &R, &B)
            if (x >= L && x < R && y >= T && y < B)
                return true
        }
        return false
    }

    ; Pull windows whose center is outside every monitor back into view.
    static _GatherOffscreen() {
        for hwnd in this.TileOrder {
            if !WinExist(hwnd)
                continue
            try WinGetPos(&x, &y, &w, &h, hwnd)
            catch
                continue
            cx := x + w / 2, cy := y + h / 2
            if this._PointOnAnyMonitor(cx, cy)
                continue
            m := 1
            if this.ScrollOwner.Has(hwnd)
                m := this.ScrollOwner[hwnd]
            else if (this._Placed.Has(hwnd) && this._Placed[hwnd].mon)
                m := this._Placed[hwnd].mon
            if (m < 1 || m > MonitorGetCount())
                m := 1
            GetTileArea(m, WTM_Gap, &ax, &ay, &W, &H)
            this._ForcePlace(hwnd, ax + Max(0, (W - w) / 2), ay + Max(0, (H - h) / 2), w, h)
        }
    }

    static _ScrollPickWithin(hwnd, dir) {
        m := this._MonOf(hwnd)
        if (!this.ScrollPages.Has(m) || !this.ScrollPageOf.Has(hwnd))
            return 0
        p := this.ScrollPageOf[hwnd]
        pages := this._ScrollPagesOf(m)
        if (p < 1 || p > pages.Length)
            return 0
        group := pages[p]
        i := 0
        for k, h in group
            if (h = hwnd) {
                i := k
                break
            }
        if !i
            return 0
        GetTileArea(m, WTM_Gap, &X, &Y, &W, &H)
        table := GetSlotTable(m, group.Length, W, H)
        if (table.Length < group.Length)
            return 0
        j := PickSlotFromTable(table, i, dir)
        return j ? group[j] : 0
    }

    static _ScrollNeighborPage(hwnd, dir) {
        m := this._MonOf(hwnd)
        if (!this.ScrollPages.Has(m) || !this.ScrollPageOf.Has(hwnd))
            return 0
        p := this.ScrollPageOf[hwnd]
        pages := this._ScrollPagesOf(m)
        np := (dir = "L") ? p - 1 : (dir = "R") ? p + 1 : 0
        if (!np || np < 1 || np > pages.Length || pages[np].Length = 0)
            return 0
        GetTileArea(m, WTM_Gap, &X, &Y, &W, &H)
        try WinGetPos(&cx, &cy, &cw, &ch, hwnd)
        catch
            return 0
        ccy := cy + ch / 2
        table := GetSlotTable(m, pages[np].Length, W, H)
        best := 0, bestX := (dir = "L") ? -1.0e18 : 1.0e18, bestDy := 1.0e18
        for i, h in pages[np] {
            if (i > table.Length)
                break
            sx := table[i].cx * W
            dy := Abs(Y + table[i].cy * H - ccy)
            better := (dir = "L") ? (sx > bestX + 1 || (Abs(sx - bestX) <= 1 && dy < bestDy))
                                  : (sx < bestX - 1 || (Abs(sx - bestX) <= 1 && dy < bestDy))
            if better
                bestX := sx, bestDy := dy, best := h
        }
        if best
            return {page: np, hwnd: best}
        return 0
    }

    static _ScrollMoveAcross(hwnd, dir) {
        m := this._MonOf(hwnd)
        if (!this.ScrollPages.Has(m) || !this.ScrollPageOf.Has(hwnd))
            return
        pages := this._ScrollPagesOf(m)
        p := this.ScrollPageOf[hwnd]
        if (p < 1 || p > pages.Length)
            return
        group := pages[p]
        i := 0
        for k, h in group
            if (h = hwnd) {
                i := k
                break
            }
        if !i
            return
        group.RemoveAt(i)
        targetIdx := 0
        if (dir = "L") {
            if (p > 1) {
                this._ScrollInsertByX(m, pages[p - 1], hwnd, dir)
                targetIdx := p - 1
            } else {
                pages.InsertAt(1, [hwnd])
                targetIdx := 1
            }
        } else {
            if (p < pages.Length) {
                this._ScrollInsertByX(m, pages[p + 1], hwnd, dir)
                targetIdx := p + 1
            } else {
                pages.Push([hwnd])
                targetIdx := pages.Length
            }
        }
        if (group.Length = 0) {
            for k, g in pages {
                if (g.Length = 0) {
                    pages.RemoveAt(k)
                    if (k < targetIdx)
                        targetIdx -= 1
                    break
                }
            }
        }
        this.ScrollView[m] := Max(1, Min(targetIdx, pages.Length))
        this._ScrollReindex()
        this._ScrollFlatten()
    }

    ; Insert at the rightmost (L) / leftmost (R) slot after re-layout.
    static _ScrollInsertByX(m, group, hwnd, dir) {
        GetTileArea(m, WTM_Gap, &X, &Y, &W, &H)
        table := GetSlotTable(m, group.Length + 1, W, H)
        idx := 1, best := (dir = "L") ? -1.0e18 : 1.0e18
        for i, t in table {
            if ((dir = "L" && t.cx > best) || (dir = "R" && t.cx < best)) {
                best := t.cx
                idx := i
            }
        }
        group.InsertAt(Min(idx, group.Length + 1), hwnd)
    }

    static _ScrollDetach(hwnd) {
        m := this._MonOf(hwnd)
        if (!this.ScrollPages.Has(m) || !this.ScrollPageOf.Has(hwnd))
            return 0
        pages := this._ScrollPagesOf(m)
        p := this.ScrollPageOf[hwnd]
        if (p < 1 || p > pages.Length)
            return 0
        group := pages[p]
        found := false
        for k, h in group
            if (h = hwnd) {
                group.RemoveAt(k)
                found := true
                break
            }
        if !found
            return 0
        if (group.Length = 0) {
            for k, g in pages
                if (g.Length = 0) {
                    pages.RemoveAt(k)
                    break
                }
        }
        return m
    }

    ; Rightmost (L) / leftmost (R) window on monitors in that direction.
    static _ScrollExtremeWindow(dir, skipMon, refHwnd) {
        if (skipMon < 1 || skipMon > MonitorGetCount())
            skipMon := 1
        MonitorGet(skipMon, &cL, &cT, &cR, &cB)
        ccx := (cL + cR) / 2
        try WinGetPos(&fx, &fy, &fw, &fh, refHwnd)
        catch
            return 0
        fcy := fy + fh / 2
        best := 0, bestX := 0, bestDy := 1.0e18
        loop MonitorGetCount() {
            m := A_Index
            if (m = skipMon)
                continue
            MonitorGet(m, &mL, &mT, &mR, &mB)
            mcx := (mL + mR) / 2
            if (dir = "L" && mcx >= ccx)
                continue
            if (dir = "R" && mcx <= ccx)
                continue
            if !this.ScrollPages.Has(m)
                continue
            pages := this._ScrollPagesOf(m)
            view := this.ScrollView.Has(m) ? this.ScrollView[m] : 1
            GetTileArea(m, WTM_Gap, &X, &Y, &W, &H)
            for p, group in pages {
                if (!(group is Array) || group.Length = 0)
                    continue
                table := GetSlotTable(m, group.Length, W, H)
                for i, h in group {
                    if (i > table.Length || !WinExist(h))
                        continue
                    gx := mL + (p - view) * W + table[i].cx * W
                    gy := mT + table[i].cy * H
                    better := false
                    if !best
                        better := true
                    else if (dir = "L")
                        better := (gx > bestX + 1) || (Abs(gx - bestX) <= 1 && Abs(gy - fcy) < bestDy)
                    else
                        better := (gx < bestX - 1) || (Abs(gx - bestX) <= 1 && Abs(gy - fcy) < bestDy)
                    if better {
                        best := {mon: m, page: p, hwnd: h}
                        bestX := gx, bestDy := Abs(gy - fcy)
                    }
                }
            }
        }
        return best
    }

    ; Move at the strip edge -> extreme-x slot on the target monitor.
    static _ScrollCrossMonitor(hwnd, dir) {
        m := this._MonOf(hwnd)
        ext := this._ScrollExtremeWindow(dir, m, hwnd)
        targetMon := 0, targetPage := 0
        if ext {
            targetMon  := ext.mon
            targetPage := ext.page
        } else {
            targetMon := this._AdjacentMonitor(m, dir)
            if !targetMon
                return 0
        }
        if !this._ScrollDetach(hwnd)
            return 0
        ap := this._ScrollPagesOf(targetMon)
        if (targetPage < 1 || targetPage > ap.Length) {
            if (ap.Length = 0)
                ap.Push([])
            targetPage := (dir = "L") ? ap.Length : 1
        }
        this._ScrollInsertByX(targetMon, ap[targetPage], hwnd, dir)
        this.ScrollView[targetMon] := targetPage
        this._ScrollReindex()
        this._ScrollFlatten()
        WMLog("WTM scroll cross move " dir " mon" m " -> mon" targetMon " page" targetPage)
        return targetMon
    }

    ; Focus jumps to the x-extreme window on the target monitor.
    static _ScrollCrossFocus(hwnd, dir) {
        m := this._MonOf(hwnd)
        ext := this._ScrollExtremeWindow(dir, m, hwnd)
        if !ext
            return 0
        this.ScrollView[ext.mon] := ext.page
        WMLog("WTM scroll cross focus " dir " mon" m " -> mon" ext.mon " page" ext.page)
        return {mon: ext.mon, hwnd: ext.hwnd}
    }

    static _ScrollDrop(hwnd) {
        this.RebuildOrder()
        if !this._OrderIndex(hwnd)
            return
        MouseGetPos(&mx, &my)
        dm := GetMonitorIndexAtPoint(mx, my)
        if (dm < 1)
            dm := 1
        oldM := this._MonOf(hwnd)
        if (this.ScrollPages.Has(oldM) && this.ScrollPageOf.Has(hwnd)) {
            pages := this._ScrollPagesOf(oldM)
            pOld := this.ScrollPageOf[hwnd]
            if (pOld >= 1 && pOld <= pages.Length) {
                group := pages[pOld]
                for k, h in group
                    if (h = hwnd) {
                        group.RemoveAt(k)
                        break
                    }
                if (group.Length = 0) {
                    for k, g in pages
                        if (g.Length = 0) {
                            pages.RemoveAt(k)
                            break
                        }
                }
            }
        }
        pages := this._ScrollPagesOf(dm)
        if !this.ScrollView.Has(dm)
            this.ScrollView[dm] := 1
        p := Max(1, Min(this.ScrollView.Has(dm) ? this.ScrollView[dm] : 1, pages.Length))
        group := pages[p]
        GetTileArea(dm, WTM_Gap, &X, &Y, &W, &H)
        group.Push(hwnd)
        table := GetSlotTable(dm, group.Length, W, H)
        idx := group.Length, best := 1.0e18
        for i, t in table {
            sx := X + t.cx * W, sy := Y + t.cy * H
            d := (sx - mx) ** 2 + (sy - my) ** 2
            if (d < best)
                best := d, idx := i
        }
        for k, h in group
            if (h = hwnd) {
                group.RemoveAt(k)
                break
            }
        group.InsertAt(Min(idx, group.Length + 1), hwnd)
        this.ScrollView[dm] := p
        this._ScrollReindex()
        this._ScrollFlatten()
        this.AutoTile()
        this.RefreshBorder()
    }

    static _ApplyRects(rects, animate, monIdx := 0) {
        for r in rects {
            if !WinExist(r.hwnd)
                continue
            this._Placed[r.hwnd] := {x: r.x, y: r.y, w: r.w, h: r.h, mon: monIdx}
            try {
                if (WinGetMinMax(r.hwnd) != 0)
                    continue
            } catch {
                continue
            }
            if (animate && WTM_AnimMs > 0)
                this._AnimMove(r.hwnd, r.x, r.y, r.w, r.h, true)
            else {
                this._AnimDrop(r.hwnd)
                this._ForcePlace(r.hwnd, r.x, r.y, r.w, r.h)
            }
        }
    }

    static _AnimDrop(hwnd) {
        if this.Anim.Has(hwnd)
            this.Anim.Delete(hwnd)
    }

    static _AnimMove(hwnd, tx, ty, tw, th, noClamp := false) {
        if (WTM_AnimMs <= 0) {
            this._AnimDrop(hwnd)
            if noClamp
                this._ForcePlace(hwnd, tx, ty, tw, th)
            else
                MoveWinTo(hwnd, tx, ty, tw, th)
            return
        }
        try {
            if (WinGetMinMax(hwnd) != 0) {
                this._AnimDrop(hwnd)
                return
            }
            WinGetPos(&cx, &cy, &cw, &ch, hwnd)
        } catch {
            return
        }
        if (cx = tx && cy = ty && cw = tw && ch = th) {
            this._AnimDrop(hwnd)
            return
        }
        this.Anim[hwnd] := {x0: cx, y0: cy, w0: cw, h0: ch
                          , x1: tx, y1: ty, w1: tw, h1: th
                          , noClamp: noClamp
                          , t0: A_TickCount, dur: Max(30, WTM_AnimMs)}
        if !this.AnimStarted {
            this.AnimStarted := true
            SetTimer(this.AnimTickFn, 12)
        }
    }

    static AnimTick() {
        if (this.Anim.Count = 0) {
            SetTimer(this.AnimTickFn, 0)
            this.AnimStarted := false
            return
        }
        now := A_TickCount
        for hwnd, a in this.Anim.Clone() {
            if !WinExist(hwnd) {
                this._AnimDrop(hwnd)
                continue
            }
            try {
                if (WinGetMinMax(hwnd) != 0) {
                    this._AnimDrop(hwnd)
                    continue
                }
            } catch {
                this._AnimDrop(hwnd)
                continue
            }
            p := (now - a.t0) / a.dur
            if (p >= 1) {
                this._AnimDrop(hwnd)
                if a.noClamp
                    this._ForcePlace(hwnd, a.x1, a.y1, a.w1, a.h1)
                else
                    try MoveWinTo(hwnd, a.x1, a.y1, a.w1, a.h1)
                try this._DrawBorder(hwnd, this.FocusHwnd)
                continue
            }
            e := 1 - (1 - p) ** 3
            x := Round(a.x0 + (a.x1 - a.x0) * e)
            y := Round(a.y0 + (a.y1 - a.y0) * e)
            w := Round(Max(50, a.w0 + (a.w1 - a.w0) * e))
            h := Round(Max(50, a.h0 + (a.h1 - a.h0) * e))
            flags := 0x4 | 0x10 | (a.noClamp ? 0x400 : 0)
            try DllCall("SetWindowPos", "Ptr", hwnd, "Ptr", 0
                , "Int", x, "Int", y, "Int", w, "Int", h, "UInt", flags)
            try this._DrawBorder(hwnd, this.FocusHwnd)
        }
    }

    static _StopAnim() {
        SetTimer(this.AnimTickFn, 0)
        this.AnimStarted := false
        this.Anim := Map()
    }

    static _MemberSig() {
        arr := []
        for hwnd in GetVisibleWindow() {
            if this.Excluded.Has(hwnd)
                continue
            if !IsTilableWindow(hwnd)
                continue
            arr.Push(hwnd + 0)
        }
        for hwnd, _ in this.SoloHidden {
            if WinExist(hwnd)
                arr.Push(hwnd + 0)
        }
        n := arr.Length
        Loop n {
            i := A_Index
            Loop n - i {
                j := A_Index
                if (arr[j] > arr[j+1]) {
                    t := arr[j], arr[j] := arr[j+1], arr[j+1] := t
                }
            }
        }
        sig := ""
        for v in arr
            sig .= v ","
        return sig
    }

    static Tick() {
        global DesktopIsSwitching
        if !this.Active || DesktopIsSwitching
            return
        this._SlowAccum += this._Elapsed()
        if (this._SlowAccum >= 250) {
            this._SlowAccum := 0
            this._SlowCheck()
            return
        }
        this._FastCheck()
    }

    static _Elapsed() {
        r := TickElapsed(this._LastTick, Border_RefreshMs)
        this._LastTick := r.now
        return r.dt
    }

    static _SlowCheck() {
        if this.Overview {
            sig := this._MemberSig()
            if (sig != this._LastWins) {
                this._LastWins := sig
                this._OverviewEnter()
            }
            this.SweepOrphanBorders()
            return
        }
        asig := this._AreaSig()
        if (asig != this._LastArea) {
            this._LastArea := asig
            this.AutoTile()
            this.RefreshBorder()
            return
        }
        sig := this._MemberSig()
        if (sig != this._LastWins) {
            this._LastWins := sig
            this.AutoTile()
            this.RefreshBorder()
            return
        }
        this._CheckFullscreen()
        this._CheckDrift()
        this.SweepOrphanBorders()
    }

    static _OrphanSeen := Map()
    static SweepOrphanBorders() {
        keep := Map()
        for _, m in [this.BorderMap, AllBorders.Frames, PinBorder.Map] {
            for _, bf in m {
                try {
                    if (IsObject(bf) && IsObject(bf.Gui) && bf.Gui.Hwnd)
                        keep[bf.Gui.Hwnd] := true
                }
            }
        }
        try {
            if (IsObject(DragBorder.Frame) && IsObject(DragBorder.Frame.Gui) && DragBorder.Frame.Gui.Hwnd)
                keep[DragBorder.Frame.Gui.Hwnd] := true
        }
        me   := DllCall("GetCurrentProcessId")
        seen := Map()
        for h in WinGetList("AHKWM_BORDER ahk_class AutoHotkeyGUI") {
            if keep.Has(h)
                continue
            try {
                if (WinGetPID(h) != me)
                    continue
            } catch {
                continue
            }
            seen[h] := true
            if !this._OrphanSeen.Has(h)
                continue
            if WTM_Debug
                WMLog("WTM border sweep - " h " (孤儿边框回收)")
            try DllCall("User32\DestroyWindow", "Ptr", h)
        }
        this._OrphanSeen := seen
    }

    static _AreaSig() {
        s := ""
        loop MonitorGetCount() {
            m := A_Index
            MonitorGetWorkArea(m, &L, &T, &R, &B)
            BarReserve(m, &L, &T, &R, &B)
            s .= m ":" L "," T "," R "," B ";"
        }
        return s
    }

    static _FastCheck() {
        fh := 0
        try fh := WinGetID("A")
        if (fh && fh != this.FocusHwnd && this._OrderIndex(fh))
            this.FocusHwnd := fh
        else if (this.FocusHwnd && (!WinExist(this.FocusHwnd) || !this._OrderIndex(this.FocusHwnd)))
            this.FocusHwnd := this.TileOrder.Length ? this.TileOrder[1] : 0
        this.RefreshBorder()
    }

    static _CheckDrift() {
        if GetKeyState("LButton", "P") || GetKeyState("RButton", "P")
            return
        dirty := Map()
        for hwnd in this.TileOrder {
            if !WinExist(hwnd)
                continue
            if this.Anim.Has(hwnd)
                continue
            if this.SoloHidden.Has(hwnd)
                continue
            try {
                if (WinGetMinMax(hwnd) != 0)
                    continue
            } catch {
                continue
            }
            if !this._Placed.Has(hwnd)
                continue
            t := this._Placed[hwnd]
            try {
                WinGetPos(&x, &y, &w, &h, hwnd)
            } catch {
                continue
            }
            if (Abs(x - t.x) > 2 || Abs(y - t.y) > 2 || Abs(w - t.w) > 2 || Abs(h - t.h) > 2) {
                m := this._MonOf(hwnd)
                dirty[m] := true
                if (t.HasProp("mon") && t.mon && t.mon != m && t.mon >= 1 && t.mon <= MonitorGetCount())
                    dirty[t.mon] := true
            }
        }
        if (dirty.Count = 0)
            return
        for m, _ in dirty
            this._RePlace(m)
        this.RefreshBorder()
    }

    static _MoveCursorToWindow(hwnd) {
        if !hwnd || !WinExist(hwnd)
            return
        try {
            if !GetWindowVisualRect(hwnd, &x, &y, &w, &h)
                WinGetPos(&x, &y, &w, &h, hwnd)
            DllCall("SetCursorPos", "Int", x + w//2, "Int", y + h//2)
        }
    }

    static FocusDir(dir) {
        if !this.Active
            return
        m0 := this._MonOf(this.FocusHwnd)
        if this.SoloMon.Has(m0) {
            this._LeaveSoloRestoreMon(m0)
            this.AutoTile()
            this.RefreshBorder()
        }
        this.RebuildOrder()
        if (this.TileOrder.Length = 0)
            return
        cur := this._OrderIndex(this.FocusHwnd) ? this.FocusHwnd : this.TileOrder[1]
        if this.Overview {
            target := this._OverviewPick(cur, dir)
            if target {
                FocusWindowSafely(target)
                this.FocusHwnd := target
                this._MoveCursorToWindow(target)
                this.RefreshBorder()
            }
            return
        }
        if this.ScrollOn {
            target := this._ScrollPickWithin(cur, dir)
            if target {
                FocusWindowSafely(target)
                this.FocusHwnd := target
                this._MoveCursorToWindow(target)
                this.RefreshBorder()
                return
            }
            np := this._ScrollNeighborPage(cur, dir)
            if np {
                this.ScrollView[this._MonOf(cur)] := np.page
                this._RePlace(this._MonOf(cur))
                FocusWindowSafely(np.hwnd)
                this.FocusHwnd := np.hwnd
                this._MoveCursorToWindow(np.hwnd)
                this.RefreshBorder()
                return
            }
            if (dir = "L" || dir = "R") {
                cf := this._ScrollCrossFocus(cur, dir)
                if cf {
                    this._RePlace(cf.mon)
                    FocusWindowSafely(cf.hwnd)
                    this.FocusHwnd := cf.hwnd
                    this._MoveCursorToWindow(cf.hwnd)
                    this.RefreshBorder()
                }
            }
            return
        }
        curMon := this._MonOf(cur)
        target := this._PickSwapTarget(cur, dir, curMon, "focus")
        if (!target && MonitorGetCount() > 1) {
            target := this._PickNeighbor(cur, dir, curMon)
            if target
                WMLog("WTM focus " dir " 跨屏兜底 -> " target)
        }
        if target {
            FocusWindowSafely(target)
            this.FocusHwnd := target
            this._MoveCursorToWindow(target)
            this.RefreshBorder()
        }
    }

    static MoveDir(dir) {
        if !this.Active
            return
        m0 := this._MonOf(this.FocusHwnd)
        if this.SoloMon.Has(m0) {
            this._LeaveSoloRestoreMon(m0)
            this.AutoTile()
        }
        this.RebuildOrder()
        cur := this._OrderIndex(this.FocusHwnd) ? this.FocusHwnd : 0
        if (!cur && this.TileOrder.Length)
            cur := this.TileOrder[1]
        if !cur
            return
        if this.Overview {
            target := this._OverviewPick(cur, dir)
            if target
                this._OverviewSwap(cur, target)
            return
        }
        if this.ScrollOn {
            m := this._MonOf(cur)
            target := this._ScrollPickWithin(cur, dir)
            if target {
                p := this.ScrollPageOf[cur]
                pgs := this._ScrollPagesOf(m)
                if (p < 1 || p > pgs.Length)
                    return
                group := pgs[p]
                i1 := 0, i2 := 0
                for k, h in group {
                    if (h = cur)
                        i1 := k
                    else if (h = target)
                        i2 := k
                }
                if (i1 && i2) {
                    group[i1] := target
                    group[i2] := cur
                }
                this._ScrollFlatten()
                this._RePlace(m)
                this.FocusHwnd := cur
                this._MoveCursorToWindow(cur)
                this.RefreshBorder()
                return
            }
            if (dir = "L" || dir = "R") {
                p := this.ScrollPageOf.Has(cur) ? this.ScrollPageOf[cur] : 0
                pgs := this._ScrollPagesOf(m)
                atEdge := (dir = "L" && p = 1) || (dir = "R" && p = pgs.Length)
                adj := atEdge ? this._ScrollCrossMonitor(cur, dir) : 0
                if !adj
                    this._ScrollMoveAcross(cur, dir)
                this._RePlace(m)
                if adj
                    this._RePlace(adj)
                this.FocusHwnd := cur
                this._MoveCursorToWindow(cur)
                this.RefreshBorder()
            }
            return
        }
        curMon := this._MonOf(cur)

        target := this._PickSwapTarget(cur, dir, curMon)
        if target {
            i1 := this._OrderIndex(cur)
            i2 := this._OrderIndex(target)
            if (i1 && i2) {
                tmp := this.TileOrder[i1]
                this.TileOrder[i1] := this.TileOrder[i2]
                this.TileOrder[i2] := tmp
            }
            this._RePlace(curMon)
            this.FocusHwnd := cur
            this._MoveCursorToWindow(cur)
            this.RefreshBorder()
            return
        }

        adj := 0
        try adj := this._AdjacentMonitor(curMon, dir)
        if adj {
            this._MoveWindowToMonitor(cur, adj)
            this._RePlace(curMon)
            this._RePlace(adj)
            this._MoveCursorToWindow(cur)
            this.RefreshBorder()
        }
    }

    static Resize(axis, grow) {
        global WTM_ResizeRules, WTM_LayoutOverride, WTM_Gap, WTM_ResizeStep
        if (!this.Active || this.Overview)
            return
        this.RebuildOrder()
        cur := this._OrderIndex(this.FocusHwnd) ? this.FocusHwnd : 0
        if !cur
            return
        mon := this._MonOf(cur)
        if (this._FsMon.Has(mon) && this._FsMon[mon])
            return
        wins := this._MonitorSlots(mon)
        if this.ScrollOn {
            if (!this.ScrollPages.Has(mon) || !this.ScrollPageOf.Has(cur))
                return
            pgs := this._ScrollPagesOf(mon)
            p := this.ScrollPageOf[cur]
            if (p < 1 || p > pgs.Length)
                return
            wins := pgs[p]
        }
        n := wins.Length
        if (n < 2)
            return
        i := 0
        for idx, h in wins {
            if (h = cur) {
                i := idx
                break
            }
        }
        if !i
            return

        GetTileArea(mon, WTM_Gap, &ax, &ay, &W, &H)
        axisX := (axis = "X")
        span := axisX ? W : H
        if (span <= 0)
            return
        table := GetSlotTable(mon, n, W, H)
        if (table.Length < n)
            return

        spans := []
        for t in table
            spans.Push({lo: axisX ? t.xlo : t.ylo, hi: axisX ? t.xhi : t.yhi})

        minSpan := Max(WTM_ResizeStep * 2, 80) / span
        delta   := (WTM_ResizeStep / 2) / span
        newSpans := ResizeSpans(spans, i, grow, delta, minSpan)
        if !newSpans
            return

        newSpans := QuantizeSpans(newSpans, span)

        rules := []
        for j, t in table {
            xlo := t.xlo
            xhi := t.xhi
            ylo := t.ylo
            yhi := t.yhi
            if axisX {
                xlo := newSpans[j].lo
                xhi := newSpans[j].hi
            } else {
                ylo := newSpans[j].lo
                yhi := newSpans[j].hi
            }
            rules.Push({x: {lo: xlo, hi: xhi, align: "Center"}, y: {lo: ylo, hi: yhi, align: "Center"}})
        }

        if !WTM_ResizeRules.Has(mon)
            WTM_ResizeRules[mon] := Map()
        WTM_ResizeRules[mon][n] := rules
        WTM_LayoutOverride := true
        InvalidateSlotTables()
        this._RePlace(mon)
        this.RefreshBorder()
        WMLog("WTM resize " (axisX ? "X" : "Y") (grow ? "+" : "-") " mon" mon " n" n
            . " step" WTM_ResizeStep " -> " RuleStringFor(rules, W, H))
    }

    static _MonitorSlots(monIdx) {
        wins := []
        for h in this.TileOrder {
            if !WinExist(h)
                continue
            if (this._MonOf(h) = monIdx)
                wins.Push(h)
        }
        return wins
    }

    static _PickSwapTarget(hwnd, dir, monIdx, kind := "swap") {
        global WTM_Debug
        wins := this._MonitorSlots(monIdx)
        n := wins.Length
        if (n < 2)
            return 0
        i := 0
        for idx, h in wins {
            if (h = hwnd) {
                i := idx
                break
            }
        }
        if !i
            return 0
        GetTileArea(monIdx, WTM_Gap, &ax, &ay, &W, &H)
        table := GetSlotTable(monIdx, n, W, H)
        if (table.Length < n)
            return 0
        j := PickSlotFromTable(table, i, dir)
        if WTM_Debug {
            s := ""
            for k, t in table
                s .= (k > 1 ? " " : "") . k . ":" . Round(t.cx, 3) . "/" . Round(t.cy, 3)
            WMLog("WTM " kind " " dir " slots n" n " mon" monIdx " | " s)
        }
        if (j && j <= table.Length && i <= table.Length)
            WMLog("WTM " kind " " dir " #" i " -> #" j " n" n
                . " from " Round(table[i].cx, 3) "/" Round(table[i].cy, 3)
                . " to " Round(table[j].cx, 3) "/" Round(table[j].cy, 3))
        else
            WMLog("WTM " kind " " dir " #" i " -> none n" n " mon" monIdx)
        return j ? wins[j] : 0
    }

    static _MoveWindowToMonitor(hwnd, monIdx) {
        if !hwnd || !WinExist(hwnd)
            return
        if (monIdx < 1 || monIdx > MonitorGetCount())
            return
        MonitorGetWorkArea(monIdx, &L, &T, &R, &B)
        try {
            WinGetPos(, , &w, &h, hwnd)
            cx := L + (R - L) // 2, cy := T + (B - T) // 2
            this._ForcePlace(hwnd, cx - w // 2, cy - h // 2, w, h)
        }
    }

    static _AdjacentMonitor(monIdx, dir) {
        if (monIdx < 1 || monIdx > MonitorGetCount())
            monIdx := 1
        MonitorGet(monIdx, &L, &T, &R, &B)
        ccx := (L + R) // 2, ccy := (T + B) // 2
        best := 0, bestDist := 1.0e18
        loop MonitorGetCount() {
            if (A_Index = monIdx)
                continue
            MonitorGet(A_Index, &l2, &t2, &r2, &b2)
            mx := (l2 + r2) // 2, my := (t2 + b2) // 2
            dx := mx - ccx, dy := my - ccy
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
                best := A_Index
            }
        }
        return best
    }

    static CloseFocused() {
        if !this.Active
            return
        hwnd := this.FocusHwnd
        if (!hwnd || !WinExist(hwnd)) {
            try hwnd := WinGetID("A")
        }
        if (!hwnd || !WinExist(hwnd)) {
            if (this.TileOrder.Length)
                hwnd := this.TileOrder[1]
        }
        if (!hwnd || !WinExist(hwnd))
            return
        try {
            WinClose(hwnd)
            this.RemoveBorder(hwnd)
            PinBorder.Remove(hwnd)
        }
        if (this.FocusHwnd = hwnd)
            this.FocusHwnd := 0
        this.OnWindowChanged()
    }

    static TogglePinExclude() {
        if this.Overview
            return
        hwnd := 0
        try hwnd := WinGetID("A")
        if (hwnd && IsBarWindow(hwnd))
            hwnd := 0
        if !hwnd
            MouseGetPos(,, &hwnd)
        if !hwnd
            return
        if this.Excluded.Has(hwnd) {
            this.Excluded.Delete(hwnd)
            try WinSetAlwaysOnTop(0, hwnd)
            PinBorder.Remove(hwnd)
            ShowOSD("WTM Include")
        } else {
            this.Excluded[hwnd] := true
            try WinSetAlwaysOnTop(1, hwnd)
            PinBorder.Add(hwnd)
            this.RemoveBorder(hwnd)
            ShowOSD("WTM Float (top + bar)")
        }
        this.RebuildOrder()
        this.AutoTile()
        this.RefreshBorder()
    }

    static _OrderIndex(hwnd) {
        for i, h in this.TileOrder
            if (h = hwnd)
                return i
        return 0
    }

    static _PickNeighbor(hwnd, dir, skipMon := 0) {
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
            if this.SoloHidden.Has(h)
                continue
            if skipMon && (this._MonOf(h) = skipMon)
                continue
            try WinGetPos(&x, &y, &w, &h2, h)
            catch
                continue
            tx := x + w/2, ty := y + h2/2
            dx := tx - ccx, dy := ty - ccy

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

    static EnsureBorder(hwnd, state := "unfocus") {
        col := (state = "focus") ? Border_FocusColor : Border_UnfocusColor
        if this.BorderMap.Has(hwnd) {
            bf := this.BorderMap[hwnd]
            if (IsObject(bf.Gui) && bf.Gui.Hwnd && DllCall("User32\IsWindow", "Ptr", bf.Gui.Hwnd))
                return
            if WTM_Debug
                WMLog("WTM border ! " hwnd " (边框 GUI 已死，重建)")
            this.RemoveBorder(hwnd)
        }
        if WTM_Debug
            WMLog("WTM border + " hwnd " " state " (n=" this.BorderMap.Count + 1 ")")
        this.BorderMap[hwnd]   := BorderFrame(col, Border_Opacity)
        this.BorderState[hwnd] := state
    }

    static RemoveBorder(hwnd) {
        if !this.BorderMap.Has(hwnd)
            return
        if WTM_Debug
            WMLog("WTM border - " hwnd " (" (WinExist(hwnd) ? "窗口还在" : "窗口已销毁") ")")
        bf := this.BorderMap[hwnd]
        try {
            if IsObject(bf.Gui) && bf.Gui.Hwnd
                DllCall("User32\DestroyWindow", "Ptr", bf.Gui.Hwnd)
        }
        bf.Gui := ""
        this.BorderMap.Delete(hwnd)
        if this.BorderState.Has(hwnd)
            this.BorderState.Delete(hwnd)
    }

    static DestroyAllBorders() {
        hwnds := []
        for hwnd, bf in this.BorderMap.Clone() {
            try {
                if IsObject(bf.Gui) && bf.Gui.Hwnd
                    hwnds.Push(bf.Gui.Hwnd)
            }
            try bf.Destroy()
        }
        this.BorderMap   := Map()
        this.BorderState := Map()
        for _, h in hwnds {
            if DllCall("User32\IsWindow", "Ptr", h)
                try DllCall("User32\DestroyWindow", "Ptr", h)
        }
    }

    ; Kill leftover AHKWM_BORDER windows of this process, keeping other modes' frames.
    static _ForceSweepBorders() {
        keep := Map()
        try {
            for _, bf in AllBorders.Frames
                if (IsObject(bf) && IsObject(bf.Gui) && bf.Gui.Hwnd)
                    keep[bf.Gui.Hwnd] := true
        }
        try {
            for _, bf in PinBorder.Map
                if (IsObject(bf) && IsObject(bf.Gui) && bf.Gui.Hwnd)
                    keep[bf.Gui.Hwnd] := true
        }
        me := DllCall("GetCurrentProcessId")
        for h in WinGetList("AHKWM_BORDER ahk_class AutoHotkeyGUI") {
            if keep.Has(h)
                continue
            try {
                if (WinGetPID(h) != me)
                    continue
            } catch {
                continue
            }
            try DllCall("User32\DestroyWindow", "Ptr", h)
        }
    }

    static _SetBorderColor(hwnd, state) {
        if !this.BorderMap.Has(hwnd)
            return
        if (this.BorderState.Has(hwnd) && this.BorderState[hwnd] = state)
            return
        col := (state = "focus") ? Border_FocusColor : Border_UnfocusColor
        bf  := this.BorderMap[hwnd]
        if (bf.Color = col) {
            this.BorderState[hwnd] := state
            return
        }
        if WTM_Debug
            WMLog("WTM bordercolor " hwnd " -> " state " (换边框)")
        this.BorderMap[hwnd]   := BorderFrame(col, Border_Opacity)
        this.BorderState[hwnd] := state
        try bf.Destroy()
    }

    static RefreshBorder() {
        if !this.Active
            return
        want := Map()
        for hwnd in this.TileOrder {
            if !WinExist(hwnd)
                continue
            if !DllCall("User32\IsWindowVisible", "Ptr", hwnd)
                continue
            if (PinBorder.Map.Has(hwnd) || AlwaysVisible.Has(hwnd))
                continue
            if this.SoloHidden.Has(hwnd)
                continue
            try {
                if (WinGetMinMax(hwnd) = -1)
                    continue
            } catch {
                continue
            }
            m := this._MonOf(hwnd)
            if (this.SoloMon.Has(m) && this.SoloMon[m] != hwnd)
                continue
            if (this._FsMon.Has(m) && this._FsMon[m])
                continue
            want[hwnd] := true
        }
        for hwnd, _ in this.BorderMap.Clone() {
            if !want.Has(hwnd)
                this.RemoveBorder(hwnd)
        }
        for hwnd, _ in want {
            st := (hwnd = this.FocusHwnd) ? "focus" : "unfocus"
            this.EnsureBorder(hwnd, st)
            this._SetBorderColor(hwnd, st)
            _BorderPlaceFrame(this.BorderMap, hwnd)
        }
        if WTM_Debug {
            sig := ""
            for hwnd, _ in this.BorderMap
                sig .= hwnd ","
            if (sig != this._LastBSig || this.FocusHwnd != this._LastBFocus) {
                this._LastBSig   := sig
                this._LastBFocus := this.FocusHwnd
                WMLog("WTM border n=" this.BorderMap.Count " want=" want.Count
                    " focus=" this.FocusHwnd " solo=" this.SoloMon.Count
                    " fs=" this._FsMon.Count
                    " | 其它边框: all=" AllBorders.Frames.Count
                    " pin=" PinBorder.Map.Count
                    " drag=" (IsObject(DragBorder.Frame) ? 1 : 0)
                    " | sig=" sig)
            }
        }
    }

    static _DrawBorder(hwnd, focusH) {
        if !WinExist(hwnd)
            return
        if (PinBorder.Map.Has(hwnd) || AlwaysVisible.Has(hwnd)) {
            this.RemoveBorder(hwnd)
            return
        }
        try {
            if (WinGetMinMax(hwnd) = -1) {
                if this.BorderMap.Has(hwnd)
                    this.BorderMap[hwnd].Hide()
                return
            }
        } catch {
            return
        }
        st := hwnd = focusH ? "focus" : "unfocus"
        this.EnsureBorder(hwnd, st)
        this._SetBorderColor(hwnd, st)
        _BorderPlaceFrame(this.BorderMap, hwnd)
    }

    static DrawOne(hwnd) {
        if (!this.Active || !this.BorderMap.Has(hwnd))
            return
        this._DrawBorder(hwnd, this.FocusHwnd)
    }

    ; ==========================================================================
    ; 全屏 / 单人模式 / Fullscreen & Solo
    ; ==========================================================================
    static _CheckFullscreen() {
        changed := false
        loop MonitorGetCount() {
            m := A_Index
            fs := false
            try {
                if this._FullscreenTestApplies(m)
                    fs := HasFullscreenWindow(m)
            }
            old := this._FsMon.Has(m) ? this._FsMon[m] : false
            if (fs != old) {
                this._FsMon[m] := fs
                changed := true
            }
        }
        for m, _ in this._MonitorsOfOrder() {
            if this.SoloMon.Has(m) {
                solo := this.SoloMon[m]
                auto := (this.SoloAuto.Has(m) && this.SoloAuto[m])
                ok   := false
                try {
                    if auto
                        ok := (WinExist(solo) && WinGetMinMax(solo) = 1 && this._OrderIndex(solo))
                    else
                        ok := (WinExist(solo) && WinGetMinMax(solo) != -1 && this._OrderIndex(solo))
                }
                if !ok {
                    this._ExitSolo(m)
                    changed := true
                }
                continue
            }
            if (this._FsMon.Has(m) && this._FsMon[m])
                continue
            if this._EnterSoloOn(m)
                changed := true
        }
        if changed {
            this.AutoTile()
            this.RefreshBorder()
        }
    }

    ; 平铺区域与整块显示器重合（该屏没有 bar、没有间隙）时，"窗口铺满显示器"分不清真全屏
    ; 和 WTM 自己平铺出来的单窗口 —— 跳过该屏的全屏判定，否则会被永久冻结
    ; A tile area equal to the whole monitor means there is no bar to cover, so the
    ; fullscreen test cannot tell a real fullscreen window from our own single tile.
    static _FullscreenTestApplies(monIdx) {
        global WTM_Gap
        MonitorGet(monIdx, &mL, &mT, &mR, &mB)
        GetTileArea(monIdx, WTM_Gap, &tL, &tT, &tW, &tH)
        return (tL > mL + 2 || tT > mT + 2 || tL + tW < mR - 2 || tT + tH < mB - 2)
    }

    static _MonitorsOfOrder() {
        out := Map()
        for hwnd in this.TileOrder {
            m := this._MonOf(hwnd)
            if (m < 1)
                m := 1
            out[m] := true
        }
        return out
    }

    static _EnterSoloWith(monIdx, target, auto := false) {
        if (!target || !WinExist(target))
            return false
        if this.SoloHidden.Has(target)
            return false
        this.SoloMon[monIdx] := target
        if auto
            this.SoloAuto[monIdx] := true
        else if this.SoloAuto.Has(monIdx)
            this.SoloAuto.Delete(monIdx)
        for hwnd in this.TileOrder {
            if (hwnd = target)
                continue
            if this.SoloHidden.Has(hwnd)
                continue
            if (this._MonOf(hwnd) != monIdx)
                continue
            try {
                DllCall("ShowWindow", "Ptr", hwnd, "Int", 0)
                this.SoloHidden[hwnd] := monIdx
            }
        }
        return true
    }

    static _EnterSoloOn(monIdx) {
        target := 0
        for hwnd in this.TileOrder {
            if !WinExist(hwnd)
                continue
            if (this.SoloHidden.Has(hwnd) || this.Excluded.Has(hwnd))
                continue
            if (this._MonOf(hwnd) != monIdx)
                continue
            try {
                if (WinGetMinMax(hwnd) = 1) {
                    target := hwnd
                    break
                }
            } catch {
                continue
            }
        }
        if !target
            return false
        return this._EnterSoloWith(monIdx, target, true)
    }

    static _ExitSolo(onlyMon := 0) {
        if (this.SoloHidden.Count > 0) {
            for hwnd, m in this.SoloHidden.Clone() {
                if (onlyMon && m != onlyMon)
                    continue
                try {
                    if WinExist(hwnd)
                        DllCall("ShowWindow", "Ptr", hwnd, "Int", 8)
                }
                this.SoloHidden.Delete(hwnd)
            }
        }
        if onlyMon {
            if this.SoloMon.Has(onlyMon)
                this.SoloMon.Delete(onlyMon)
            if this.SoloAuto.Has(onlyMon)
                this.SoloAuto.Delete(onlyMon)
        } else {
            this.SoloMon  := Map()
            this.SoloAuto := Map()
        }
        this._Placed := Map()
    }

    static _LeaveSoloRestoreMon(m) {
        if !this.SoloMon.Has(m)
            return
        try {
            h := this.SoloMon[m]
            if (WinExist(h) && WinGetMinMax(h) = 1)
                WinRestore(h)
        }
        this._ExitSolo(m)
    }

    static ToggleFull() {
        if (!this.Active || this.Overview)
            return
        cur := this._OrderIndex(this.FocusHwnd) ? this.FocusHwnd : 0
        if !cur
            return
        m := this._MonOf(cur)
        if (m < 1)
            m := 1
        if (this.SoloMon.Has(m) && this.SoloMon[m] = cur) {
            this._LeaveSoloRestoreMon(m)
            this.AutoTile()
            this.RefreshBorder()
            ShowOSD("WTM Full: OFF")
            return
        }
        if !this._EnterSoloWith(m, cur)
            return
        this.AutoTile()
        this.RefreshBorder()
        ShowOSD("WTM Full: ON")
    }

    ; ==========================================================================
    ; 拖拽交换 / Drag-and-drop swap
    ; ==========================================================================
    static HandleDragDrop(hwnd) {
        if (!this.Active || !hwnd || !WinExist(hwnd))
            return
        m0 := this._MonOf(hwnd)
        if this.SoloMon.Has(m0)
            this._ExitSolo(m0)
        this.RebuildOrder()
        if !this._OrderIndex(hwnd)
            return
        if this.Overview {
            target := this._PickNearestByPos(hwnd)
            if target
                this._OverviewSwap(hwnd, target)
            return
        }
        if this.ScrollOn {
            this._ScrollDrop(hwnd)
            return
        }
        try {
            if !GetWindowVisualRect(hwnd, &cx, &cy, &cw, &ch)
                WinGetPos(&cx, &cy, &cw, &ch, hwnd)
        } catch {
            return
        }
        px := cx + cw/2, py := cy + ch/2
        dropMon := GetMonitorIndexAtPoint(px, py)
        if (dropMon < 1)
            dropMon := 1
        wins := this._MonitorSlots(dropMon)
        n := wins.Length
        if (n < 1) {
            this.AutoTile()
            this.RefreshBorder()
            return
        }
        GetTileArea(dropMon, WTM_Gap, &ax, &ay, &W, &H)
        table := GetSlotTable(dropMon, n, W, H)
        if (table.Length < n) {
            this._Placed := Map()
            this.AutoTile()
            this.RefreshBorder()
            return
        }
        best := 0, bestD := 1.0e18
        for j, t in table {
            sx := ax + t.cx * W, sy := ay + t.cy * H
            d := (sx - px) ** 2 + (sy - py) ** 2
            if (d < bestD) {
                bestD := d
                best := j
            }
        }
        if (best >= 1 && best <= wins.Length)
            this._SwapSlots(hwnd, wins[best])
        this._Placed := Map()
        this.AutoTile()
        this.RefreshBorder()
    }

    static _SwapSlots(a, b) {
        ia := this._OrderIndex(a)
        ib := this._OrderIndex(b)
        if (!ia || !ib || ia = ib)
            return
        tmp := this.TileOrder[ia]
        this.TileOrder[ia] := this.TileOrder[ib]
        this.TileOrder[ib] := tmp
    }

    ; ---- Overview / 全局缩略 ----
    static ToggleTrueMax() {
        if (!this.Active || this.Overview)
            return
        hwnd := this.FocusHwnd
        if (!hwnd || !WinExist(hwnd))
            return
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

    static ToggleOverview() {
        if !this.Active {
            ShowOSD("WTM Overview: need WTM")
            return
        }
        if this.Overview
            this._OverviewExit()
        else
            this._OverviewEnter()
    }

    ; Dry-run the current tiling model without moving any window.
    static _ComputeModelRects() {
        global TileSink
        this.RebuildOrder()
        if this.ScrollOn
            this._ScrollSync()
        groups := Map()
        for hwnd in this.TileOrder {
            if (!WinExist(hwnd) || this.SoloHidden.Has(hwnd))
                continue
            m := this._MonOf(hwnd)
            if (m < 1)
                m := 1
            if !groups.Has(m)
                groups[m] := []
            groups[m].Push(hwnd)
        }
        model := Map()
        saved := TileSink
        for m, wins in groups {
            rects := []
            TileSink := (hwnd, x, y, w, h) => rects.Push({hwnd: hwnd, x: x, y: y, w: w, h: h})
            try {
                if this.ScrollOn
                    this._ScrollLayout(m, wins)
                else
                    TileWindowsOnMonitor(wins, m, WTM_Gap, false)
            } finally {
                TileSink := saved
            }
            for r in rects
                model[r.hwnd] := {x: r.x, y: r.y, w: r.w, h: r.h, mon: m}
        }
        return model
    }

    static _OverviewEnter() {
        this._StopAnim()
        model := this._ComputeModelRects()
        if (model.Count = 0)
            return
        rects := Map(), found := false
        wx0 := 0, wy0 := 0, wx1 := 0, wy1 := 0
        for hwnd, r in model {
            if !WinExist(hwnd)
                continue
            try {
                if (WinGetMinMax(hwnd) != 0)
                    continue
            } catch {
                continue
            }
            x := r.x, y := r.y, w := r.w, h := r.h
            rects[hwnd] := {x: x, y: y, w: w, h: h}
            if !found {
                wx0 := x, wy0 := y, wx1 := x + w, wy1 := y + h
                found := true
            } else {
                wx0 := Min(wx0, x), wy0 := Min(wy0, y)
                wx1 := Max(wx1, x + w), wy1 := Max(wy1, y + h)
            }
        }
        if !found
            return
        m := this._MonOf(this.FocusHwnd)
        if (m < 1)
            m := 1
        GetTileArea(m, WTM_Gap, &tx, &ty, &tw, &th)
        pad := Round(Min(tw, th) * 0.06)
        tx += pad, ty += pad, tw -= pad * 2, th -= pad * 2
        ww := Max(1, wx1 - wx0), wh := Max(1, wy1 - wy0)
        s := Min(tw / ww, th / wh, 1.0)
        ox := tx + (tw - ww * s) / 2
        oy := ty + (th - wh * s) / 2
        this.Overview := true
        this.OverviewRects := Map()
        this._Placed := model.Clone()
        for hwnd, r in rects {
            nx := Round(ox + (r.x - wx0) * s)
            ny := Round(oy + (r.y - wy0) * s)
            nw := Max(120, Round(r.w * s))
            nh := Max(80,  Round(r.h * s))
            this.OverviewRects[hwnd] := {x: nx, y: ny, w: nw, h: nh}
            this._AnimMove(hwnd, nx, ny, nw, nh, true)
        }
        this.RefreshBorder()
        ShowOSD("WTM Overview: ON")
    }

    static _OverviewExit() {
        this.Overview := false
        this.OverviewRects := Map()
        if (this.ScrollOn && this.FocusHwnd && this.ScrollPageOf.Has(this.FocusHwnd)) {
            m := this._MonOf(this.FocusHwnd)
            this.ScrollView[m] := this.ScrollPageOf[this.FocusHwnd]
        }
        this.AutoTile()
        this.RefreshBorder()
        ShowOSD("WTM Overview: OFF")
    }

    ; Model rects are authoritative: some apps refuse to shrink below their
    ; minimum size, so actual positions can differ from the overview layout.
    static _ForcePlace(hwnd, x, y, w, h) {
        try {
            if (WinGetMinMax(hwnd) != 0)
                WinRestore(hwnd)
            DllCall("SetWindowPos", "Ptr", hwnd, "Ptr", 0
                , "Int", Round(x), "Int", Round(y), "Int", Round(w), "Int", Round(h)
                , "UInt", 0x4 | 0x10 | 0x400)
        }
    }

    static _OverviewPick(hwnd, dir) {
        if !this.OverviewRects.Has(hwnd)
            return 0
        cur := this.OverviewRects[hwnd]
        ccx := cur.x + cur.w / 2, ccy := cur.y + cur.h / 2
        best := 0, bestD := 1.0e18
        for h, r in this.OverviewRects {
            if (h = hwnd)
                continue
            dx := r.x + r.w / 2 - ccx
            dy := r.y + r.h / 2 - ccy
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
            d := dx * dx + dy * dy
            if (d < bestD)
                bestD := d, best := h
        }
        return best
    }

    static _PickNearestByPos(hwnd) {
        try WinGetPos(&cx, &cy, &cw, &ch, hwnd)
        catch
            return 0
        ccx := cx + cw / 2, ccy := cy + ch / 2
        best := 0, bestD := 1.0e18
        for h, r in this.OverviewRects {
            if (h = hwnd)
                continue
            d := (r.x + r.w / 2 - ccx) ** 2 + (r.y + r.h / 2 - ccy) ** 2
            if (d < bestD)
                bestD := d, best := h
        }
        return best
    }

    static _OverviewSwap(a, b) {
        if (!a || !b || a = b)
            return
        if this.ScrollOn {
            ma := this._MonOf(a), mb := this._MonOf(b)
            if (ma != mb || !this.ScrollPageOf.Has(a) || !this.ScrollPageOf.Has(b))
                return
            pa := this.ScrollPageOf[a], pb := this.ScrollPageOf[b]
            pgs := this._ScrollPagesOf(ma)
            if (pa < 1 || pa > pgs.Length || pb < 1 || pb > pgs.Length)
                return
            ga := pgs[pa], gb := pgs[pb]
            ia := 0, ib := 0
            for k, h in ga
                if (h = a)
                    ia := k
            for k, h in gb
                if (h = b)
                    ib := k
            if (!ia || !ib)
                return
            ga[ia] := b, gb[ib] := a
            this._ScrollReindex()
            this._ScrollFlatten()
        } else {
            ia := this._OrderIndex(a), ib := this._OrderIndex(b)
            if (!ia || !ib)
                return
            tmp := this.TileOrder[ia]
            this.TileOrder[ia] := this.TileOrder[ib]
            this.TileOrder[ib] := tmp
        }
        if (this._Placed.Has(a) && this._Placed.Has(b)) {
            t := this._Placed[a]
            this._Placed[a] := this._Placed[b]
            this._Placed[b] := t
        }
        ra := this.OverviewRects.Has(a) ? this.OverviewRects[a] : 0
        rb := this.OverviewRects.Has(b) ? this.OverviewRects[b] : 0
        if (ra && rb) {
            this.OverviewRects[a] := rb
            this.OverviewRects[b] := ra
            this._AnimMove(a, rb.x, rb.y, rb.w, rb.h, true)
            this._AnimMove(b, ra.x, ra.y, ra.w, ra.h, true)
        }
        this.RefreshBorder()
    }

    static LogSlotTables() {
        if this.ScrollOn {
            for m, pages in this.ScrollPages {
                line := "WTM scroll mon" . m . " view" . this.ScrollView[m] . " |"
                for p, group in pages {
                    line .= " p" . p . ":"
                    for h in group
                        line .= h ","
                    line .= ";"
                }
                WMLog(line)
            }
            return
        }
        for m, _ in this._MonitorsOfOrder() {
            wins := this._MonitorSlots(m)
            n := wins.Length
            if (n < 1)
                continue
            GetTileArea(m, WTM_Gap, &ax, &ay, &W, &H)
            table := GetSlotTable(m, n, W, H)
            line := "WTM slots mon" . m . " n" . n . " src" . (table.Length ? table[1].src : "-") . " |"
            for i, t in table
                line .= Format(" {:.3f}/{:.3f}", t.cx, t.cy)
            WMLog(line)
        }
    }
}

; ==============================================================================
; 18. All-Window Borders Mode / 全窗口边框模式
; ==============================================================================

; ---- Borders on every window (defers to WTM) / 全窗口边 ----
class AllBorders {
    static Active  := false
    static Frames  := Map()
    static State   := Map()
    static _Wins   := []
    static _Accum  := 0
    static _LastTick := 0
    static TimerFn := ObjBindMethod(AllBorders, "Tick")

    static Toggle() {
        if this.Active
            this.Deactivate()
        else
            this.Activate()
    }

    static Activate() {
        this.Active := true
        ShowOSD("All Borders: ON")
        if WTM.Active
            return
        this.Tick()
        SetTimer(this.TimerFn, Border_RefreshMs)
    }

    static Deactivate() {
        this.Active := false
        SetTimer(this.TimerFn, 0)
        this.DestroyAll()
        ShowOSD("All Borders: OFF")
    }

    static Rebuild() {
        if !this.Active
            return
        this.DestroyAll()
        if WTM.Active
            return
        this.Tick()
        SetTimer(this.TimerFn, Border_RefreshMs)
    }

    static Suspend() {
        SetTimer(this.TimerFn, 0)
        this.DestroyAll()
    }

    static DestroyAll() {
        for hwnd, _ in this.Frames.Clone()
            this.Remove(hwnd)
        this.Frames := Map()
        this.State  := Map()
        this._Wins  := []
        this._Accum := 0
    }

    static Remove(hwnd) {
        if !this.Frames.Has(hwnd)
            return
        try this.Frames[hwnd].Destroy()
        this.Frames.Delete(hwnd)
        if this.State.Has(hwnd)
            this.State.Delete(hwnd)
    }

    static Ensure(hwnd) {
        if this.Frames.Has(hwnd)
            return
        this.Frames[hwnd] := BorderFrame(Border_UnfocusColor, Border_Opacity)
        this.State[hwnd]  := "unfocus"
    }

    static SetColor(hwnd, state) {
        if !this.Frames.Has(hwnd)
            return
        if (this.State.Has(hwnd) && this.State[hwnd] = state)
            return
        col := (state = "focus") ? Border_FocusColor : Border_UnfocusColor
        this.Frames[hwnd].SetColor(col)
        this.State[hwnd] := state
    }

    static Tick() {
        global DesktopIsSwitching
        if !this.Active || WTM.Active || DesktopIsSwitching
            return
        r := TickElapsed(this._LastTick, Border_RefreshMs)
        this._LastTick := r.now
        this._Accum += r.dt
        if (this._Accum >= 200 || this._Wins.Length = 0) {
            this._Accum := 0
            this._Wins  := GetVisibleWindow()
            valid := Map()
            for hwnd in this._Wins
                valid[hwnd] := true
            for hwnd, _ in this.Frames.Clone() {
                if !valid.Has(hwnd) || !WinExist(hwnd)
                    this.Remove(hwnd)
            }
        }
        focusH := 0
        try focusH := WinGetID("A")
        for hwnd in this._Wins
            this._DrawBorder(hwnd, focusH)
    }

    static _DrawBorder(hwnd, focusH) {
        if !WinExist(hwnd)
            return
        if (PinBorder.Map.Has(hwnd) || AlwaysVisible.Has(hwnd)) {
            this.Remove(hwnd)
            return
        }
        try {
            if (WinGetMinMax(hwnd) = -1) {
                if this.Frames.Has(hwnd)
                    this.Frames[hwnd].Hide()
                return
            }
        } catch {
            return
        }
        this.Ensure(hwnd)
        this.SetColor(hwnd, hwnd = focusH ? "focus" : "unfocus")
        _BorderPlaceFrame(this.Frames, hwnd)
    }

    static DrawOne(hwnd) {
        if (!this.Active || WTM.Active || !this.Frames.Has(hwnd))
            return
        focusH := 0
        try focusH := WinGetID("A")
        this._DrawBorder(hwnd, focusH)
    }
}

; ==============================================================================
; 19. Enhanced Window-Select Mode (WinSelect) / 增强窗口选择模式
; ==============================================================================
; ---- Window-select mode / 窗口选择 ----
class WinSelect {
    static Active := false
    static Items  := []
    static Locks  := Map()
    static IH     := ""
    static ZOrder := []
    static SidebarGui   := ""
    static SidebarItems := []

    static _CleanLocks() {
        for L, h in this.Locks.Clone() {
            if !WinExist(h)
                this.Locks.Delete(L)
        }
    }

    static _LockLetterFor(hwnd) {
        for L, h in this.Locks
            if (h = hwnd)
                return L
        return ""
    }

    static Start() {
        global WS_Scale, WS_Letters
        if this.Active {
            this.Cancel()
            return
        }
        if WTM.Active {
            ShowOSD("WTM: WinSelect Disabled")
            return
        }
        this._CleanLocks()
        wins := GetVisibleWindow()
        visibleSet := Map()
        for hwnd in wins
            visibleSet[hwnd] := true
        sidebarLetters := []
        for L, hwnd in this.Locks {
            if !visibleSet.Has(hwnd) && WinExist(hwnd)
                sidebarLetters.Push(L)
        }
        if (wins.Length = 0 && sidebarLetters.Length = 0) {
            ShowOSD("WinSelect: No Windows")
            return
        }
        this.Active := true
        this.Items := []
        this.ZOrder := wins.Clone()
        used := Map()
        for L, h in this.Locks
            used[L] := true
        for hwnd in wins {
            try WinGetPos(&x, &y, &w, &h, hwnd)
            catch
                continue
            letter := this._LockLetterFor(hwnd)
            if (letter = "") {
                Loop Parse, WS_Letters {
                    if !used.Has(A_LoopField) {
                        letter := A_LoopField
                        break
                    }
                }
            }
            if (letter = "") {
                WMLog("WinSelect: letter pool exhausted; remaining windows unlabeled")
                break
            }
            used[letter] := true
            this.Items.Push({hwnd:hwnd, letter:letter, gui:"", x:x, y:y, w:w, h:h})
        }

        if (this.Items.Length > 0) {
            tileHwnds := []
            for it in this.Items
                tileHwnds.Push(it.hwnd)
            this._TileForSelect(tileHwnds)

            for it in this.Items {
                if (WS_Scale < 0.999) {
                    try WinGetPos(&tx, &ty, &tw, &th, it.hwnd)
                    catch
                        continue
                    nw := Max(120, Round(tw * WS_Scale))
                    nh := Max(90,  Round(th * WS_Scale))
                    nx := Round(tx + (tw - nw) / 2)
                    ny := Round(ty + (th - nh) / 2)
                    try WinMove(nx, ny, nw, nh, it.hwnd)
                }
                it.gui := this._MakeLabel(it)
            }
        }

        if (sidebarLetters.Length > 0)
            this._CreateSidebar(sidebarLetters)

        this._Capture()
    }

    static _TileForSelect(hwnds) {
        global Tile_Gap
        if (hwnds.Length = 0)
            return
        MouseGetPos(&mx, &my)
        mon := GetMonitorIndexAtPoint(mx, my)
        TileWindowsOnMonitor(hwnds, mon, Tile_Gap, true)
    }

    static _MakeLabel(it) {
        global WS_BarColor, WS_TextColor, WS_BarHeight, WS_BarWidth, WS_OffsetY
        global WS_FontSize, WS_Opacity, WS_Rounded, WS_Radius, WS_CornerMode
        global Color_Bg, Color_Active
        bg := (WS_BarColor != "") ? WS_BarColor : Color_Bg
        fg := (WS_TextColor != "") ? WS_TextColor : Color_Active
        if !GetWindowVisualRect(it.hwnd, &x, &y, &w, &h) {
            try WinGetPos(&x, &y, &w, &h, it.hwnd)
            catch
                return ""
        }
        bw := (WS_BarWidth > 0) ? WS_BarWidth : w
        bh := Max(16, WS_BarHeight)
        bx := x + (w - bw) // 2
        by := y - bh - WS_OffsetY
        mon := GetMonitorIndexAtPoint(x + w//2, y + h//2)
        MonitorGet(mon, &mL, &mT, &mR, &mB)
        if (by < mT)
            by := y + WS_OffsetY
        g := ""
        try {
            g := Gui("-Caption +AlwaysOnTop +ToolWindow +Owner +E0x20 -DPIScale")
            g.BackColor := bg
            g.SetFont("s" WS_FontSize " w700 c" fg, FontName)
            g.Add("Text", Format("x0 y0 w{} h{} Center +0x200 BackgroundTrans", bw, bh), it.letter)
            g.Show(Format("x{} y{} w{} h{} NoActivate", bx, by, bw, bh))
            try WinSetTransparent(WS_Opacity, g.Hwnd)
            RoundWindowEx(g, WS_Rounded, WS_Radius, WS_CornerMode)
        }
        return g
    }

    static _Capture() {
        global WS_SizeMap, WS_Timeout
        pendingSize := ""
        loop {
            opts := "L1"
            if (WS_Timeout > 0)
                opts .= " T" . WS_Timeout
            ih := InputHook(opts)
            ih.KeyOpt("{All}", "E S")
            ih.KeyOpt("{LAlt}{RAlt}{LShift}{RShift}{LControl}{RControl}{LWin}{RWin}", "-E -S")
            this.IH := ih
            ih.Start()
            ih.Wait()
            this.IH := ""
            if !this.Active
                return
            if (ih.EndReason != "EndKey") {
                this.Cancel()
                return
            }
            key := ih.EndKey
            if RegExMatch(key, "^Numpad(\d)$", &m)
                key := m[1]
            if (StrLen(key) = 1 && IsDigit(key) && WS_SizeMap.Has(key)) {
                pendingSize := key
                ShowOSD("WinSelect size [" key "] - press a letter")
                continue
            }
            this._Finish(key, pendingSize)
            return
        }
    }

    static _Finish(key, pending) {
        global WS_SizeMap
        key := StrUpper(Trim(key))
        target := 0
        orig := ""
        for it in this.Items {
            if (it.letter = key) {
                target := it.hwnd
                orig := {x:it.x, y:it.y, w:it.w, h:it.h}
                break
            }
        }
        fromLock := false
        if (!target && this.Locks.Has(key)) {
            if WinExist(this.Locks[key]) {
                target := this.Locks[key]
                fromLock := true
            } else {
                this.Locks.Delete(key)
            }
        }
        this._RestoreAll()
        if (!target || !WinExist(target))
            return
        if fromLock {
            this._BringToCurrentDesktop(target)
            try {
                WinGetPos(&ox, &oy, &ow, &oh, target)
                orig := {x:ox, y:oy, w:ow, h:oh}
            }
        }
        if !IsObject(orig)
            orig := {x:0, y:0, w:1000, h:700}
        this.Locks[key] := target

        w := orig.w, h := orig.h
        if (pending != "" && WS_SizeMap.Has(pending)) {
            spec := WS_SizeMap[pending]
            if (spec.type = "ratio") {
                w := Max(120, Round(orig.w * spec.r))
                h := Max(90,  Round(orig.h * spec.r))
            } else {
                w := spec.w, h := spec.h
            }
        }
        MouseGetPos(&mx, &my)
        mon := GetMonitorIndexAtPoint(mx, my)
        MonitorGetWorkArea(mon, &L, &T, &R, &B)
        BarReserve(mon, &L, &T, &R, &B)
        w := Min(w, R - L), h := Min(h, B - T)
        x := L + ((R - L) - w) // 2
        y := T + ((B - T) - h) // 2
        try {
            WinRestore(target)
            WinMove(Round(x), Round(y), Round(w), Round(h), target)
        }
        FocusWindowSafely(target)
        ShowOSD("WinSelect [" . key . "]" . (pending != "" ? " size " . pending : ""))
    }

    static _BringToCurrentDesktop(hwnd) {
        _RemoveFromAllDesktops(hwnd)
        try ShowWin(hwnd)
    }

    static _CreateSidebar(sidebarLetters) {
        global WS_Sidebar_FontSize, WS_Sidebar_Width, WS_Sidebar_Position
        global WS_Sidebar_OffsetX, WS_Sidebar_OffsetY
        global WS_Opacity, GUI_Rounded, GUI_CornerRadius
        global Color_Bg, Color_Text, Color_Active
        if (sidebarLetters.Length = 0)
            return false
        this.SidebarItems := sidebarLetters.Clone()
        MouseGetPos(&mx, &my)
        mon := GetMonitorIndexAtPoint(mx, my)
        MonitorGetWorkArea(mon, &mL, &mT, &mR, &mB)
        BarReserve(mon, &mL, &mT, &mR, &mB)
        sw := WS_Sidebar_Width
        sx := (WS_Sidebar_Position = "right")
            ? (mR - sw - WS_Sidebar_OffsetX)
            : (mL + WS_Sidebar_OffsetX)
        sy := mT + WS_Sidebar_OffsetY
        g := Gui("-Caption +AlwaysOnTop +ToolWindow +Owner -DPIScale")
        g.BackColor := Color_Bg
        g.MarginX := 0, g.MarginY := 0
        titleH := Round(WS_Sidebar_FontSize * 2.2)
        g.SetFont("s" WS_Sidebar_FontSize " w700 c" Color_Active, FontName)
        g.Add("Text", "x0 y4 w" sw " h" titleH " Center +0x200 BackgroundTrans", "Locks")
        g.Add("Text", "x8 y" (titleH+2) " w" (sw-16) " h1 Background" Color_Active, "")
        itemH := Max(36, Round(WS_Sidebar_FontSize * 2.6))
        itemY := titleH + 10
        g.SetFont("s" WS_Sidebar_FontSize " w600 c" Color_Active, FontName)
        for L in sidebarLetters {
            ctl := g.Add("Text", "x0 y" itemY " w" sw " h" itemH " Center +0x200 BackgroundTrans", L)
            ctl.OnEvent("Click", ObjBindMethod(this, "_SidebarClick", L))
            itemY += itemH + 2
        }
        totalH := itemY
        g.Show(Format("x{} y{} w{} h{} NoActivate", sx, sy, sw, totalH))
        try WinSetTransparent(WS_Opacity, g.Hwnd)
        RoundWindowEx(g, GUI_Rounded, GUI_CornerRadius)
        this.SidebarGui := g
        return true
    }

    static _SidebarClick(letter, ctl, *) {
        if !this.Active
            return
        try {
            if IsObject(this.IH)
                this.IH.Stop()
        }
        this._Finish(letter, "")
    }

    static _DestroySidebar() {
        if IsObject(this.SidebarGui) {
            try this.SidebarGui.Destroy()
            this.SidebarGui := ""
        }
        this.SidebarItems := []
    }

    static _RestoreZOrder(order) {
        static SWP := 0x1 | 0x2 | 0x10
        i := order.Length
        while (i >= 1) {
            h := order[i]
            i--
            if !WinExist(h)
                continue
            insertAfter := 0
            try {
                if (WinGetExStyle(h) & 0x8)
                    insertAfter := -1
            }
            try DllCall("SetWindowPos", "Ptr", h, "Ptr", insertAfter
                , "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", SWP)
        }
    }

    static _RestoreAll() {
        zorder := this.ZOrder
        for it in this.Items {
            if IsObject(it.gui)
                try it.gui.Destroy()
            try {
                if WinExist(it.hwnd) {
                    WinMove(it.x, it.y, it.w, it.h, it.hwnd)
                    if PinBorder.Map.Has(it.hwnd)
                        WinSetAlwaysOnTop(1, it.hwnd)
                }
            }
        }
        if (zorder.Length > 0)
            this._RestoreZOrder(zorder)
        this._DestroySidebar()
        this.Items := []
        this.ZOrder := []
        this.Active := false
    }

    static Cancel() {
        try {
            if IsObject(this.IH)
                this.IH.Stop()
        }
        this._DestroySidebar()
        this._RestoreAll()
    }
}
; ==============================================================================
; 20. Clipboard / Editor / Terminal / Power Menu / 剪贴板编辑器终端电源
; ==============================================================================

; ---- Clipboard-change callback / 剪贴板变 ----
OnClipboardChanged(dataType) {
    static lastTick := 0
    if (A_TickCount - lastTick < 200)
        return
    lastTick := A_TickCount
    if _ClipSourceExcluded()
        return
    if (dataType = 1)
        RecordClipboard()
    else if (dataType = 2)
        RecordClipboardBinary()
}

; ---- Is the copy source app excluded / 复制来源是否在排除列表 ----
_ClipSourceExcluded() {
    global Clip_ExcludeProcs
    if (Clip_ExcludeProcs.Length = 0)
        return false
    proc := ""
    try proc := WinGetProcessName("A")
    if (proc = "")
        return false
    for p in Clip_ExcludeProcs {
        if (StrLower(proc) = StrLower(Trim(p)))
            return true
    }
    return false
}

; ---- History entry header / 历史条目分隔头 ----
_ClipEntryHeader() {
    return "------------------------------------------------------------------------------------------------`r`n"
         . FormatTime(, "yyyy-MM-dd HH:mm:ss") . "`r`n"
}

; ---- Append clipboard text to the history file / 剪贴板历 ----
RecordClipboard() {
    global LastClipContent, Path_OutputFile, Clip_MaxChars
    txt := ""
    try txt := A_Clipboard
    if (Type(txt) != "String" || txt == "" || txt == LastClipContent)
        return
    LastClipContent := txt
    if (Clip_MaxChars > 0 && StrLen(txt) > Clip_MaxChars) {
        WMLog("Clipboard entry truncated (" . StrLen(txt) . " -> " . Clip_MaxChars . " chars)", "INFO", "Clipboard")
        txt := SubStr(txt, 1, Clip_MaxChars) . "`r`n[... truncated / 已截断 ...]"
    }
    Content := _ClipEntryHeader() . txt . "`r`n`r`n"
    try FileAppend(Content, Path_OutputFile, "`n")
}

; ---- Log binary clipboard content info / 记录二进制剪贴板内容信息 ----
RecordClipboardBinary() {
    global Path_OutputFile, Clip_LogBinary, LastClipContent
    if !Clip_LogBinary
        return
    desc := ""
    files := ""
    try files := A_Clipboard
    if (files != "") {
        if (files == LastClipContent)
            return
        LastClipContent := files
        desc := "[files / 文件]`r`n" . files
    } else if DllCall("User32\IsClipboardFormatAvailable", "UInt", 2)
        desc := "[image / 图像] (bitmap on clipboard, data not saved)"
    else if DllCall("User32\IsClipboardFormatAvailable", "UInt", 8)
        desc := "[image / 图像] (DIB on clipboard, data not saved)"
    else
        desc := "[binary / 二进制] (non-text clipboard content)"
    Content := _ClipEntryHeader() . desc . "`r`n`r`n"
    try FileAppend(Content, Path_OutputFile, "`n")
}

; ---- Toggle the clipboard-history viewer / 剪贴板查 ----
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

; ---- Launch the terminal / 启动终端 ----
LaunchTerminal(*) {
    global Path_Terminal
    path := Explorer_GetPath()
    try Run('"' . Path_Terminal . '"' . (path ? ' -d "' . path . '"' : ""))
}

; ---- Open the selected file in the editor / 用编辑器 ----
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

; ---- Power menu / 电源菜单 ----
ShowPowerMenu(*) {
    global PowerMenuObj
    global PM_FontSize, PM_Width, PM_Height, PM_Opacity, PM_Rounded, PM_Radius, FontName
    if IsObject(PowerMenuObj) {
        PowerMenuObj.Destroy()
        PowerMenuObj := ""
        return
    }
    wsc := PM_Width / 500.0
    hsc := PM_Height / 160.0

    pGui := Gui("+AlwaysOnTop -Caption +ToolWindow +Owner")
    pcBg := ParseColor(PM_Bg)
    pGui.BackColor := pcBg.first
    if (pcBg.isGrad) {
        pw := Round(500 * wsc), ph := Round(160 * hsc)
        hBMBg := CreateGradient(pw, ph, 0, pcBg.colors*)
        if hBMBg
            pGui.Add("Picture", "x0 y0 w" pw " h" ph, "HBITMAP:" hBMBg)
    }
    pGui.SetFont("s" PM_FontSize " c" . C1(Color_Text), FontName)
    pGui.Add("Text", "x0 y" Round(15*hsc) " w" Round(500*wsc) " Center c" . C1(Color_Active), "System Power Menu")
    pGui.Add("Text", "x" Round(50*wsc) " y" Round(45*hsc) " w" Round(400*wsc) " h2 0x10")

    AddBtn(x, y, txt, fn, col) {
        bw := Round(120*wsc), bh := Round(60*hsc)
        pc := ParseColor(col)
        hBM := MakeGradientBM(bw, bh, pc.isGrad ? pc.colors : [col, col], PM_Rounded, 0, pcBg.first)
        pPic := pGui.Add("Picture"
            , "x" Round(x*wsc) " y" Round(y*hsc) " w" bw " h" bh
            , hBM ? "HBITMAP:" hBM : "")
        pTxt := pGui.Add("Text"
            , "x" Round(x*wsc) " y" Round(y*hsc) " w" bw " h" bh " Center 0x200 BackgroundTrans cWhite", txt)
        pTxt.SetFont("s" PM_FontSize " w700", FontName)
        pTxt.OnEvent("Click", fn)
        pPic.OnEvent("Click", fn)
    }
    AddBtn(50,  70, "Shutdown", (*) => Shutdown(1), PM_BtnShutdown)
    AddBtn(190, 70, "Sleep"
         , (*) => DllCall("PowrProf\SetSuspendState","Int",0,"Int",0,"Int",0), PM_BtnSleep)
    AddBtn(330, 70, "Reboot",   (*) => Shutdown(2), PM_BtnReboot)
    pGui.OnEvent("Escape", (*) => (pGui.Destroy(), PowerMenuObj := ""))
    pGui.Show("w" Round(500*wsc) " h" Round(160*hsc))
    try WinSetTransparent(PM_Opacity, pGui.Hwnd)
    RoundWindowEx(pGui, PM_Rounded, PM_Radius)
    PowerMenuObj := pGui
}

; ---- Selected item in Explorer / 资源管理 ----
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

; ---- Current folder of Explorer / 资源管理 ----
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

; ==============================================================================
; 21a. Generate Theme from Wallpaper / 壁纸取色生成主题
; ==============================================================================

; ---- GDIPlus 常量 ----

; ---- Resolve the current wallpaper file path / 获取当前壁纸文件路径 ----
_GetWallpaperPath() {
    try {
        path := RegRead("HKCU\Control Panel\Desktop", "WallPaper")
        if FileExist(path)
            return path
    }
    transcoded := A_AppData "\Microsoft\Windows\Themes\TranscodedWallpaper"
    if FileExist(transcoded)
        return transcoded
    try {
        CLSID := "{C2CF3110-460E-4fc1-B9D0-8A1C0C9CC4BD}"
        IID   := "{B92B56A9-8B55-4E14-9A89-0199BBB6F93B}"
        dw := ComObject(CLSID, IID)
        count := 0
        ComCall(3, dw, "UInt*", &count)
        if count > 0 {
            pMonID := 0
            ComCall(4, dw, "UInt", 0, "Ptr*", &pMonID)
            if pMonID {
                pWP := 0
                ComCall(11, dw, "Ptr", pMonID, "Ptr*", &pWP)
                if pWP {
                    path := StrGet(pWP)
                    if FileExist(path)
                        return path
                }
            }
        }
    }
    return ""
}

; ---- GDIPlus 生命周期 ----
_Gdip_Startup() {
    si := Buffer(A_PtrSize = 8 ? 24 : 16, 0)
    NumPut("UInt", 1, si, 0)
    token := 0
    DllCall("gdiplus.dll\GdiplusStartup", "UPtr*", &token, "Ptr", si.Ptr, "Ptr", 0)
    return token
}

_Gdip_Shutdown(token) {
    DllCall("gdiplus.dll\GdiplusShutdown", "UPtr", token)
}

; ---- Perceived luminance (0-255) / 感知亮度 ----
_Lum(r, g, b) => Round(0.299 * r + 0.587 * g + 0.114 * b)

; ---- Saturation (0-255) / 饱和度 ----
_Sat(r, g, b) {
    maxC := Max(r, Max(g, b)), minC := Min(r, Min(g, b))
    return maxC = 0 ? 0 : Round((maxC - minC) / maxC * 255)
}

; ---- RGB → HSL (输出 0-255 量程) ----
_RGB2HSL(r, g, b) {
    r := r / 255, g := g / 255, b := b / 255
    maxC := Max(r, Max(g, b)), minC := Min(r, Min(g, b))
    l := (maxC + minC) / 2
    if (maxC = minC) {
        return {h:0, s:0, l:Round(l*255)}
    }
    d := maxC - minC
    s := l > 0.5 ? d / (2 - maxC - minC) : d / (maxC + minC)
    if (maxC = r)
        h := Mod((g - b) / d + (g < b ? 6 : 0), 6) / 6
    else if (maxC = g)
        h := ((b - r) / d + 2) / 6
    else
        h := ((r - g) / d + 4) / 6
    return {h:Round(h*255), s:Round(s*255), l:Round(l*255)}
}

; ---- HSL → RGB ----
_HSL2RGB(h, s, l) {
    h := h / 255, s := s / 255, l := l / 255
    if (s = 0)
        return {r:Round(l*255), g:Round(l*255), b:Round(l*255)}
    q := l < 0.5 ? l * (1 + s) : l + s - l * s
    p := 2 * l - q
    _h2c(t) {
        if t < 0
            t += 1
        if t > 1
            t -= 1
        if t < 1/6
            return Round((p + (q - p) * 6 * t) * 255)
        if t < 1/2
            return Round(q * 255)
        if t < 2/3
            return Round((p + (q - p) * (2/3 - t) * 6) * 255)
        return Round(p * 255)
    }
    return {r:_h2c(h + 1/3), g:_h2c(h), b:_h2c(h - 1/3)}
}

; ---- RGB → Hex 字符串 (含 # 前缀) ----
_RGB2Hex(r, g, b) => Format("#{:02X}{:02X}{:02X}", r, g, b)

; ---- Extract dominant colours from the wallpaper (returns [{r,g,b,count}, ...] by descending frequency) / 从壁纸提取主色调 ----
_ExtractWallpaperColors(filePath, sampleStep := 10, quantLevels := 24, topN := 16) {
    pBitmap := 0
    DllCall("gdiplus.dll\GdipCreateBitmapFromFile", "Ptr", StrPtr(filePath), "UPtr*", &pBitmap)
    if pBitmap = 0
        return []

    width := 0, height := 0
    DllCall("gdiplus.dll\GdipGetImageWidth",  "UPtr", pBitmap, "UInt*", &width)
    DllCall("gdiplus.dll\GdipGetImageHeight", "UPtr", pBitmap, "UInt*", &height)

    rect := Buffer(16, 0)
    NumPut("UInt", 0, rect, 0), NumPut("UInt", 0, rect, 4)
    NumPut("UInt", width, rect, 8), NumPut("UInt", height, rect, 12)

    bmd := Buffer(A_PtrSize = 8 ? 32 : 24, 0)
    DllCall("gdiplus.dll\GdipBitmapLockBits",
        "UPtr", pBitmap, "Ptr", rect.Ptr,
        "UInt", 0x0001,
        "Int",  0x26200A,
        "Ptr",  bmd.Ptr)

    scan0  := NumGet(bmd, A_PtrSize = 8 ? 16 : 12, "UPtr")
    stride := NumGet(bmd, 8, "Int")

    colorMap := Map()
    bucket := 256 // quantLevels

    y := 0
    while y < height {
        x := 0
        while x < width {
            offset := y * stride + x * 4
            b := NumGet(scan0 + offset, 0, "UChar")
            g := NumGet(scan0 + offset, 1, "UChar")
            r := NumGet(scan0 + offset, 2, "UChar")

            qr := r // bucket
            qg := g // bucket
            qb := b // bucket
            key := (qr << 16) | (qg << 8) | qb

            if colorMap.Has(key) {
                colorMap[key].count += 1
            } else {
                colorMap[key] := {
                    r: qr * bucket + bucket // 2,
                    g: qg * bucket + bucket // 2,
                    b: qb * bucket + bucket // 2,
                    count: 1
                }
            }
            x += sampleStep
        }
        y += sampleStep
    }

    DllCall("gdiplus.dll\GdipBitmapUnlockBits", "UPtr", pBitmap, "Ptr", bmd.Ptr)
    DllCall("gdiplus.dll\GdipDisposeImage", "UPtr", pBitmap)

    arr := []
    for _, v in colorMap
        arr.Push(v)

    if arr.Length > 1 {
        Loop arr.Length - 1 {
            i := A_Index
            Loop arr.Length - i {
                j := i + A_Index
                if arr[j].count > arr[i].count {
                    tmp := arr[i], arr[i] := arr[j], arr[j] := tmp
                }
            }
        }
    }

    result := []
    loop Min(topN, arr.Length)
        result.Push(arr[A_Index])
    return result
}

; ---- Sample the screen to extract wallpaper colours / 屏幕采样提取壁纸主色调 ----
_ExtractScreenColors(quantLevels := 24, topN := 16) {
    global Bar_Visible

    barWasVisible := Bar_Visible
    if (barWasVisible) {
        Bar_Visible := false
        ApplyBarVisibility()
    }

    WinMinimizeAll()
    Sleep(400)
    try ControlHide("SysListView321", "ahk_class Progman")
    try ControlHide("SysListView321", "ahk_class WorkerW")
    WinHide("ahk_class Shell_TrayWnd")
    Sleep(200)
    mW := A_ScreenWidth, mH := A_ScreenHeight
    MouseMove(mW - 2, mH - 2, 0)

    colorMap := Map()
    bucket := 256 // quantLevels
    xStep := Max(8, mW // 70)
    yStep := Max(10, mH // 30)

    bar := Gui("+AlwaysOnTop +ToolWindow -Caption")
    bar.BackColor := "FF3333"
    tick := 0

    y := 0
    while (y < mH) {
        x := 0
        while (x < mW) {
            c := PixelGetColor(x, y)
            qr := ((c >> 16) & 0xFF) // bucket
            qg := ((c >> 8) & 0xFF) // bucket
            qb := (c & 0xFF) // bucket
            key := (qr << 16) | (qg << 8) | qb
            if colorMap.Has(key)
                colorMap[key].count += 1
            else
                colorMap[key] := {r: qr * bucket + bucket // 2, g: qg * bucket + bucket // 2, b: qb * bucket + bucket // 2, count: 1}
            tick++
            if (Mod(tick, 10) = 0)
                bar.Show("x0 y" (y+4) " w" x " h4 NoActivate")
            x += xStep
        }
        bar.Show("x0 y" (y+4) " w" mW " h4 NoActivate")
        y += yStep
    }

    y := mH - 1
    x := 0
    while (x < mW) {
        c := PixelGetColor(x, y)
        qr := ((c >> 16) & 0xFF) // bucket
        qg := ((c >> 8) & 0xFF) // bucket
        qb := (c & 0xFF) // bucket
        key := (qr << 16) | (qg << 8) | qb
        if colorMap.Has(key)
            colorMap[key].count += 1
        else
            colorMap[key] := {r: qr * bucket + bucket // 2, g: qg * bucket + bucket // 2, b: qb * bucket + bucket // 2, count: 1}
        x += xStep
    }

    bar.Destroy()
    WinShow("ahk_class Shell_TrayWnd")
    WinMinimizeAllUndo()
    Sleep(100)
    try ControlShow("SysListView321", "ahk_class Progman")
    try ControlShow("SysListView321", "ahk_class WorkerW")
    if (barWasVisible) {
        Bar_Visible := true
        ApplyBarVisibility()
    }

    arr := []
    for _, v in colorMap
        arr.Push(v)
    if (arr.Length > 1) {
        Loop arr.Length - 1 {
            i := A_Index
            Loop arr.Length - i {
                j := i + A_Index
                if (arr[j].count > arr[i].count) {
                    tmp := arr[i], arr[i] := arr[j], arr[j] := tmp
                }
            }
        }
    }
    result := []
    loop Min(topN, arr.Length)
        result.Push(arr[A_Index])
    return result
}

; ---- Build a theme from the wallpaper and apply it / 从壁纸生成主题并应用 ----
GenerateThemeFromWallpaper(*) {
    global ConfigFile, ConfigDir

    ShowOSD("Sampling wallpaper...")

    colors := _ExtractScreenColors(24, 16)
    if (colors.Length < 3) {
        ShowOSD("Not enough colors extracted")
        return
    }

    info := []
    for _, c in colors {
        hsl := _RGB2HSL(c.r, c.g, c.b)
        info.Push({r:c.r, g:c.g, b:c.b, h:hsl.h, s:hsl.s, l:hsl.l, lum:_Lum(c.r,c.g,c.b), sat:_Sat(c.r,c.g,c.b), cnt:c.count})
    }

    ; ---- Sort (inline bubble) / 排序 ----
    byFreq := info.Clone()
    if (byFreq.Length > 1) {
        Loop byFreq.Length - 1 {
            i := A_Index
            Loop byFreq.Length - i {
                j := i + A_Index
                if (byFreq[j].cnt > byFreq[i].cnt) {
                    tmp := byFreq[i], byFreq[i] := byFreq[j], byFreq[j] := tmp
                }
            }
        }
    }

    byLum := info.Clone()
    if (byLum.Length > 1) {
        Loop byLum.Length - 1 {
            i := A_Index
            Loop byLum.Length - i {
                j := i + A_Index
                if (byLum[j].lum < byLum[i].lum) {
                    tmp := byLum[i], byLum[i] := byLum[j], byLum[j] := tmp
                }
            }
        }
    }

    bySat := info.Clone()
    if (bySat.Length > 1) {
        Loop bySat.Length - 1 {
            i := A_Index
            Loop bySat.Length - i {
                j := i + A_Index
                if (bySat[j].sat > bySat[i].sat) {
                    tmp := bySat[i], bySat[i] := bySat[j], bySat[j] := tmp
                }
            }
        }
    }

    ; ---- Assign theme colours / 分配主题色 ----
    _Eq(a, b) => _RGB2Hex(a.r, a.g, a.b) = _RGB2Hex(b.r, b.g, b.b)

    bg := byLum[1]
    if (bg.l > 35) {
        hsl := _RGB2HSL(bg.r, bg.g, bg.b)
        hsl.l := Max(8, bg.l - 30)
        rgb := _HSL2RGB(hsl.h, hsl.s, hsl.l)
        bg := {r:rgb.r, g:rgb.g, b:rgb.b, h:hsl.h, s:hsl.s, l:hsl.l, lum:_Lum(rgb.r,rgb.g,rgb.b), sat:bg.sat, cnt:bg.cnt}
    }

    tx := byLum[byLum.Length]
    if (tx.l < 200) {
        hsl := _RGB2HSL(tx.r, tx.g, tx.b)
        hsl.l := Max(215, tx.l + 50)
        hsl.s := Max(0, hsl.s - 40)
        rgb := _HSL2RGB(hsl.h, hsl.s, hsl.l)
        tx := {r:rgb.r, g:rgb.g, b:rgb.b, h:hsl.h, s:hsl.s, l:hsl.l, lum:_Lum(rgb.r,rgb.g,rgb.b), sat:0, cnt:tx.cnt}
    }

    pin := ""
    for _, c in bySat {
        if (_Eq(c, bg) || _Eq(c, tx))
            continue
        pin := c
        break
    }
    if (pin = "") {
        rgb := _HSL2RGB(3, 230, 130)
        pin := {r:rgb.r, g:rgb.g, b:rgb.b, h:3, s:230, l:130, lum:_Lum(rgb.r,rgb.g,rgb.b), sat:230, cnt:1}
    }

    active := ""
    for _, c in byFreq {
        if (_Eq(c, bg) || _Eq(c, tx))
            continue
        active := c
        break
    }
    if (active = "") {
        rgb := _HSL2RGB(Mod(pin.h+80,255), 200, 135)
        active := {r:rgb.r, g:rgb.g, b:rgb.b, h:Mod(pin.h+80,255), s:200, l:135, lum:_Lum(rgb.r,rgb.g,rgb.b), sat:200, cnt:1}
    }

    bdr := ""
    for _, c in bySat {
        if (_Eq(c, bg) || _Eq(c, tx) || _Eq(c, pin))
            continue
        hd := Abs(c.h - active.h)
        if (hd > 128)
            hd := 255 - hd
        if (hd > 20) {
            bdr := c
            break
        }
    }
    if (bdr = "") {
        rgb := _HSL2RGB(Mod(active.h+85,255), 200, 130)
        bdr := {r:rgb.r, g:rgb.g, b:rgb.b, h:Mod(active.h+85,255), s:200, l:130, lum:_Lum(rgb.r,rgb.g,rgb.b), sat:200, cnt:1}
    }

    task := ""
    for _, c in byFreq {
        if (_Eq(c, bg) || _Eq(c, tx) || _Eq(c, active))
            continue
        task := c
        break
    }
    if (task = "") {
        rgb := _HSL2RGB(Mod(active.h+100,255), 160, 135)
        task := {r:rgb.r, g:rgb.g, b:rgb.b, h:Mod(active.h+100,255), s:160, l:135, lum:_Lum(rgb.r,rgb.g,rgb.b), sat:160, cnt:1}
    }

    unfocus := ""
    for _, c in byLum {
        if (c.sat < 60 && c.lum > 40 && c.lum < 120) {
            unfocus := c
            break
        }
    }
    if (unfocus = "") {
        rgb := _HSL2RGB(bg.h, Max(0,bg.s-70), Min(bg.l+35, 120))
        unfocus := {r:rgb.r, g:rgb.g, b:rgb.b, h:bg.h, s:Max(0,bg.s-70), l:Min(bg.l+35,120), lum:_Lum(rgb.r,rgb.g,rgb.b), sat:Max(0,bg.s-70), cnt:1}
    }

    rgb := _HSL2RGB(bg.h, bg.s, Min(bg.l+18, 65))
    pmBg := {r:rgb.r, g:rgb.g, b:rgb.b}

    sdBest := "", sdBestSc := -1
    for _, c in info {
        hd := Abs(c.h - 0)
        if (hd > 128)
            hd := 255 - hd
        if (hd <= 35 && c.sat >= 30) {
            sc := c.sat * 2 + c.cnt
            if (sc > sdBestSc) {
                sdBestSc := sc
                sdBest := {r:c.r, g:c.g, b:c.b}
            }
        }
    }
    if (sdBest = "") {
        for _, c in info {
            if (c.sat >= 15) {
                hsl := _RGB2HSL(c.r, c.g, c.b)
                hsl.h := 3
                hsl.s := Max(hsl.s, 210)
                rgb := _HSL2RGB(hsl.h, hsl.s, 130)
                sdBest := {r:rgb.r, g:rgb.g, b:rgb.b}
                break
            }
        }
    }
    if (sdBest = "") {
        rgb := _HSL2RGB(3, 210, 130)
        sdBest := {r:rgb.r, g:rgb.g, b:rgb.b}
    }
    sd := sdBest

    slBest := "", slBestSc := -1
    for _, c in info {
        hd := Abs(c.h - 150)
        if (hd > 128)
            hd := 255 - hd
        if (hd <= 35 && c.sat >= 30) {
            sc := c.sat * 2 + c.cnt
            if (sc > slBestSc) {
                slBestSc := sc
                slBest := {r:c.r, g:c.g, b:c.b}
            }
        }
    }
    if (slBest = "") {
        for _, c in info {
            if (c.sat >= 15) {
                hsl := _RGB2HSL(c.r, c.g, c.b)
                hsl.h := 150
                hsl.s := Max(hsl.s, 200)
                rgb := _HSL2RGB(hsl.h, hsl.s, 130)
                slBest := {r:rgb.r, g:rgb.g, b:rgb.b}
                break
            }
        }
    }
    if (slBest = "") {
        rgb := _HSL2RGB(150, 200, 130)
        slBest := {r:rgb.r, g:rgb.g, b:rgb.b}
    }
    sl := slBest

    rbBest := "", rbBestSc := -1
    for _, c in info {
        hd := Abs(c.h - 22)
        if (hd > 128)
            hd := 255 - hd
        if (hd <= 35 && c.sat >= 30) {
            sc := c.sat * 2 + c.cnt
            if (sc > rbBestSc) {
                rbBestSc := sc
                rbBest := {r:c.r, g:c.g, b:c.b}
            }
        }
    }
    if (rbBest = "") {
        for _, c in info {
            if (c.sat >= 15) {
                hsl := _RGB2HSL(c.r, c.g, c.b)
                hsl.h := 22
                hsl.s := Max(hsl.s, 210)
                rgb := _HSL2RGB(hsl.h, hsl.s, 130)
                rbBest := {r:rgb.r, g:rgb.g, b:rgb.b}
                break
            }
        }
    }
    if (rbBest = "") {
        rgb := _HSL2RGB(22, 210, 130)
        rbBest := {r:rgb.r, g:rgb.g, b:rgb.b}
    }
    rb := rbBest

    ShowOSD("Applying theme...")

    ; ---- Write a standalone wallpaper theme file, leaving the main config alone / 写入独立主题文件 ----
    wpFile := ConfigDir "\wallpaper_theme.ini"
    try FileDelete(wpFile)
    IniWrite(_RGB2Hex(bg.r,bg.g,bg.b),       wpFile, "Theme", "Background")
    IniWrite(_RGB2Hex(tx.r,tx.g,tx.b),       wpFile, "Theme", "Text")
    IniWrite(_RGB2Hex(active.r,active.g,active.b), wpFile, "Theme", "Active")
    IniWrite(_RGB2Hex(bdr.r,bdr.g,bdr.b),    wpFile, "Theme", "BorderDrag")
    IniWrite(_RGB2Hex(pin.r,pin.g,pin.b),    wpFile, "Theme", "BorderPin")
    IniWrite(_RGB2Hex(unfocus.r,unfocus.g,unfocus.b), wpFile, "Theme", "BorderUnfocus")
    IniWrite(_RGB2Hex(pmBg.r,pmBg.g,pmBg.b), wpFile, "Theme", "PowerMenuBg")
    IniWrite(_RGB2Hex(sd.r,sd.g,sd.b),       wpFile, "Theme", "PowerBtnShutdown")
    IniWrite(_RGB2Hex(sl.r,sl.g,sl.b),       wpFile, "Theme", "PowerBtnSleep")
    IniWrite(_RGB2Hex(rb.r,rb.g,rb.b),       wpFile, "Theme", "PowerBtnReboot")
    catalog := "`r`n; All extracted wallpaper colors:`r`n"
    for _, c in colors
        catalog .= "; " _RGB2Hex(c.r, c.g, c.b) "`t(count:" c.count ")`r`n"
    FileAppend(catalog, wpFile, "UTF-8")

    _ConfigWrite("General", "ActiveTheme", "wallpaper")

    ShowOSD("Theme from wallpaper — reloading")
    Sleep(800)
    ScriptReload()
}

; ==============================================================================
; 21. Theme Switching / 主题切换
; ==============================================================================

; ---- Apply a theme & reload / 应用主题 ----
ApplyTheme(themeName, *) {
    _ConfigWrite("General", "ActiveTheme", themeName)
    ShowOSD("Theme: " . themeName)
    Sleep(400)
    ScriptReload()
}

; ---- Export the active theme to [Theme] / 导出主题 ----
ExportThemeToCustom(*) {
    global ActiveTheme, Themes, ConfigFile
    if (ActiveTheme = "custom" || !Themes.Has(ActiveTheme)) {
        ShowOSD("Already custom")
        return
    }
    palette := Themes[ActiveTheme]
    nameMap := Map(
        "Border_FocusColor","BorderDrag",
        "Border_Pin_Color","BorderPin", "Border_UnfocusColor","BorderUnfocus",
        "PM_Bg","PowerMenuBg", "PM_BtnShutdown","PowerBtnShutdown",
        "PM_BtnSleep","PowerBtnSleep", "PM_BtnReboot","PowerBtnReboot"
    )
    borderMap := Map(
        "Border_FocusColor",   "FocusColor",
        "Border_UnfocusColor", "UnfocusColor"
    )
    for key, val in palette {
        if nameMap.Has(key)
            _ConfigWrite("Theme", nameMap[key], "#" val)
        else if borderMap.Has(key)
            _ConfigWrite("Border", borderMap[key], "#" val)
    }
    _ConfigWrite("General", "ActiveTheme", "custom")
    ShowOSD("Exported -> custom")
    Sleep(400)
    ScriptReload()
}

; ==============================================================================
; 22. Tray Menu & Exit / 托盘菜单与退出
; ==============================================================================

; ---- Tray menu setup / 托盘菜单 ----
SetupTrayIcon() {
    global Themes, ActiveTheme
    A_TrayMenu.Delete()
    A_TrayMenu.Add("Gather All Windows", GatherAllToCurrent)
    A_TrayMenu.Add("Toggle Status Bar",  ToggleBar)
    A_TrayMenu.Add("Toggle WTM Mode",    (*) => WTM.Toggle())
    A_TrayMenu.Add("Copy Layout Rules",  CopyLayoutRules)
    A_TrayMenu.Add("Exclude Current Window", ExcludeCurrentWindow)
    A_TrayMenu.Add("Diagnose Window",    DiagnoseWindow)
    A_TrayMenu.Add()

    themeMenu := Menu()
    themeMenu.Add("custom (use [Colors])", ApplyTheme.Bind("custom"))
    themeMenu.Add("wallpaper (from image)", ApplyTheme.Bind("wallpaper"))
    for name, _ in Themes
        themeMenu.Add(name, ApplyTheme.Bind(name))
    themeMenu.Add()
    themeMenu.Add("Generate from Wallpaper", (*) => GenerateThemeFromWallpaper())
    try themeMenu.Check(ActiveTheme = "wallpaper" ? "wallpaper (from image)"
                      : ActiveTheme = "custom" ? "custom (use [Colors])" : ActiveTheme)
    A_TrayMenu.Add("Theme", themeMenu)
    A_TrayMenu.Add()

    Loop DesktopCount {
        i := A_Index
        A_TrayMenu.Add("Switch to Desktop " . i, SwitchDesktop.Bind(i))
    }

    A_TrayMenu.Add()
    A_TrayMenu.Add("Show Welcome",        (*) => WelcomeScreen.Show())
    A_TrayMenu.Add("Open Config Folder",  (*) => Run('explorer.exe "' . ConfigDir . '"'))
    A_TrayMenu.Add("Reload Script",       (*) => ScriptReload())
    A_TrayMenu.Add("Restore && Exit",     RestoreAndExit)

    A_IconTip := "AHK WM - Desktop " . CurrentDesktop
}

; ---- Restore everything & exit / 还原并退 ----
RestoreAndExit(*) {
    global Desktops, AlwaysVisible
    ShowOSD("Script Shutting Down ...")
    Sleep(500)
    WTM.Deactivate()
    if AllBorders.Active
        AllBorders.Deactivate()
    PinBorder.RemoveAll()
    DestroyAllBars()

    Loop DesktopCount {
        if Desktops.Has(A_Index) {
            for h in Desktops[A_Index]
                try DllCall("ShowWindow", "Ptr", h, "Int", 9)
        }
    }
    for h, _ in AlwaysVisible
        try DllCall("ShowWindow", "Ptr", h, "Int", 9)

    for hwnd in WinGetList() {
        try {
            winClass := WinGetClass(hwnd)
            if (winClass != "Progman" && winClass != "Shell_TrayWnd")
                WinRestore(hwnd)
        }
    }
    ExitApp
}

; ==============================================================================
; 23. External Eight-Direction Button Scripts / 外部八方向按钮脚本
; ==============================================================================

#Include "*i %A_ScriptDir%\Buttons\Top.ahk"
#Include "*i %A_ScriptDir%\Buttons\TopRight.ahk"
#Include "*i %A_ScriptDir%\Buttons\Right.ahk"
#Include "*i %A_ScriptDir%\Buttons\DownRight.ahk"
#Include "*i %A_ScriptDir%\Buttons\Down.ahk"
#Include "*i %A_ScriptDir%\Buttons\DownLeft.ahk"
#Include "*i %A_ScriptDir%\Buttons\Left.ahk"
#Include "*i %A_ScriptDir%\Buttons\TopLeft.ahk"
