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
; 一、环境与全局指令 / 1. Environment & Global Directives
; ==============================================================================

global WM_Version := "2.10.0"
global FontName

SetWorkingDir(A_ScriptDir)
CoordMode("Mouse", "Screen")
SetTitleMatchMode(2)
SetWinDelay(0)
SetControlDelay(0)

; ==============================================================================
; 二、常量与共享状态 / 2. Constants & Shared State
; ==============================================================================

; ---- Theme & UI colors / 主题颜色 ----
global Color_Bg, Color_Text, Color_Active, Color_Task
global Border_Drag_Color, Border_Pin_Color
global PM_Bg, PM_BtnShutdown, PM_BtnSleep, PM_BtnReboot
; Per-component colors (v2.8) / 组件色

; ---- Status-bar state / 状态栏 ----
global Bar_Height, Bar_Transparent, Bar_FontSize
global Bar_MonitorIdx := 1
global Bar_Visible    := true
; (已移除旧版全局 Bar 控件引用，现由 BarInstance 类管理)
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
; 外部脚本推送的 bar 自定义部件内容（槽位号 → 文本，持续显示直至下次更新）
; External bar widget data pushed via WM_COPYDATA (slot -> text, persists until next push)
global Bar_ExternalData := Map()
; 外部动态槽位配置（自包含协议推送，无需 Layout 声明）
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
global PauseOnFullscreen := false

; ---- Tiling & window exclusion / 平铺排除 ----
global CurrentTileGap := 0
global Tile_Gap        := 15
global LayoutRules     := Map()
global Excl_Titles     := []
global Excl_Classes    := []
global Excl_Processes  := []
global Tile_IncludeAlwaysOnTop := true
global TileBound_L := 0, TileBound_T := 0, TileBound_R := 0, TileBound_B := 0
global TileBoundSet := false

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
global LastClipContent := ""
; ---- Clipboard module settings / 剪贴板设置 ([Clipboard]) ----
global Clip_MaxChars     := 100000   ; 单条历史上限字符数，0=不限制
global Clip_ExcludeProcs := []       ; 不记录剪贴板的进程列表
global Clip_LogBinary    := true     ; 是否记录二进制内容（文件路径/类型）

global LayoutSnapshot  := Map()
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
    ; 边框色：从预设旧键推导 / Border: derive from legacy preset keys
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
; 三、通用工具函数 / 3. Utility Functions
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
; 将 \s 转为空格、\\ 转为反斜杠。IniRead 会修剪尾随空格，用此函数还原
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
    ; 移除 # 前缀 / Strip # prefix
    cstr := RegExReplace(cstr, "i)^#", "")
    parts := StrSplit(cstr, ",")
    colors := []
    for p in parts {
        p := Trim(p)
        ; 每个颜色段也去掉 # (支持 #RRGGBB,#RRGGBB 格式)
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
; RgnRoundRect / 圆角矩形 ----
RgnRoundRect(w, h, r) {
    d := Max(1, r * 2)
    return DllCall("Gdi32\CreateRoundRectRgn"
        , "Int",0,"Int",0,"Int",w+1,"Int",h+1,"Int",d,"Int",d,"Ptr")
}
; RGB→BGR / Convert RGB hex to GDI BGR COLORREF
BgrFromRgb(hex) => ((hex & 0xFF) << 16) | (hex & 0xFF00) | (hex >> 16)
; Screen-compatible bitmap / 兼容位图
ScrBitmap(w, h) {
    scrDC := DllCall("Gdi32\CreateDC", "Str","DISPLAY", "Ptr",0, "Ptr",0, "Ptr",0, "Ptr")
    hBM := DllCall("Gdi32\CreateCompatibleBitmap", "Ptr",scrDC, "Int",w,"Int",h,"Ptr")
    DllCall("Gdi32\DeleteDC", "Ptr",scrDC)
    return hBM
}
; Create font with ClearType quality / 创建字体(ClearType)
MakeFont(fh, name := FontName) {
    return DllCall("Gdi32\CreateFontW"
        , "Int",fh, "Int",0, "Int",0, "Int",0, "Int",700
        , "Int",0, "Int",0, "Int",0, "Int",0, "Int",0
        , "Int",5, "Int",0, "Int",0, "Str",name, "Ptr")
}
; Clip bitmap to rounded rect, bgColor fills corners (hex RRGGBB) / 圆角裁剪
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
; fillColor: ""且bgBM=0 → 不填充(黑色); ""且bgBM≠0 → 从bgBM取样填充; 指定颜色 → 填充该色
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
    ; --- 圆角裁剪 / Rounded clip ---
    r := radius > 0 ? radius : Max(4, Min(w, h) // 6)
    hOut := ScrBitmap(w, h)
    if !hOut {
        DllCall("Gdi32\DeleteObject", "Ptr", hGrad)
        return 0
    }
    dcD := DllCall("Gdi32\CreateCompatibleDC", "Ptr", 0, "Ptr")
    hOldD := DllCall("Gdi32\SelectObject", "Ptr", dcD, "Ptr", hOut, "Ptr")
    ; 填充角部 / Fill corners
    if (fillColor != "") {
        ; 显式指定色 / Explicit fill color
        rc := Buffer(16, 0)
        NumPut("Int", 0, "Int", 0, "Int", w, "Int", h, rc)
        bgVal := Integer("0x" fillColor)
        hBgBr := DllCall("Gdi32\CreateSolidBrush", "UInt", BgrFromRgb(bgVal), "Ptr")
        DllCall("User32\FillRect", "Ptr", dcD, "Ptr", rc, "Ptr", hBgBr)
        DllCall("Gdi32\DeleteObject", "Ptr", hBgBr)
    } else if (bgBM != 0) {
        ; 渐变 bar：从背景位图取样 / Gradient bar: sample from bg bitmap
        dcBg := DllCall("Gdi32\CreateCompatibleDC", "Ptr", 0, "Ptr")
        hOldBg := DllCall("Gdi32\SelectObject", "Ptr", dcBg, "Ptr", bgBM, "Ptr")
        DllCall("Gdi32\BitBlt", "Ptr", dcD, "Int", 0, "Int", 0, "Int", w, "Int", h
            , "Ptr", dcBg, "Int", bgOffX, "Int", bgOffY, "UInt", 0xCC0020)
        DllCall("Gdi32\SelectObject", "Ptr", dcBg, "Ptr", hOldBg, "Ptr")
        DllCall("Gdi32\DeleteDC", "Ptr", dcBg)
    } else {
        ; 纯色 bar：回退用 bar 底色 / Solid bar: fallback to bar bg color
        rc := Buffer(16, 0)
        NumPut("Int", 0, "Int", 0, "Int", w, "Int", h, rc)
        bgVal := Integer("0x" C1(Color_Bg))
        hBgBr := DllCall("Gdi32\CreateSolidBrush", "UInt", BgrFromRgb(bgVal), "Ptr")
        DllCall("User32\FillRect", "Ptr", dcD, "Ptr", rc, "Ptr", hBgBr)
        DllCall("Gdi32\DeleteObject", "Ptr", hBgBr)
    }
    ; 圆角裁剪 + 渐变覆绘 / Clip & draw gradient
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
    ; 单色：复制自身作为第二色，生成纯色位图
    if (N = 1) {
        Colors.Push(Colors[1])
        N := 2
    }
    X := V ? W : 0
    Y := V ? 0 : H
    xOFF := X ? 0 : Ceil(W / (N - 1))
    yOFF := Y ? 0 : Ceil(H / (N - 1))
    ; TRIVERTEX: {x:Int32, y:Int32, Red:UInt16, Green:UInt16, Blue:UInt16, Alpha:UInt16} = 16 bytes
    VERT := Buffer(N * 16, 0)
    ; GRADIENT_RECT: {UpperLeft:UInt32, LowerRight:UInt32} = 8 bytes
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
    ; 对齐标志 / Alignment flags
    alignFlags := (Align = "Left") ? 0x0 : (Align = "Right") ? 0x2 : 0x1
    ; wrapLines>0 时用 DT_WORDBREAK 替代 DT_SINGLELINE 实现多行换行
    drawFlags := (wrapLines > 0) ? (alignFlags | 0x10 | 0x4) : (alignFlags | 0x20 | 0x4)
    ; DT_WORDBREAK(0x10) | DT_VCENTER(0x4)  — 多行居中
    ; DT_SINGLELINE(0x20) | DT_VCENTER(0x4) — 单行居中（默认）
    ; bg / bg_rounded 模式 / gradient bg + white text
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
    ; text 模式：文字渐变色（背景透明，跟随 bar 背景）
    ; text mode: gradient text, transparent bg (follows bar bg)

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
        ; 纯色背景 / Solid bg
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

; ---- 日志系统状态 / Logging state (v2.9: structured, deduplicated, rotated) ----
global WM_LogFile   := ""        ; [Logging] File（空 = 配置目录\wm.log）
global WM_LogLevel  := 2         ; 1=DEBUG 2=INFO 3=WARN 4=ERROR ([Logging] Level)
global WM_LogMaxKB  := 512       ; 轮转阈值 KB，0=不轮转 ([Logging] MaxSizeKB)
global WM_LogSeen   := Map()     ; 去重: "组件|消息" -> 出现次数

; ---- 级别名转数值 / Level name to number ----
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
; 结构化日志：毫秒时间戳 + 级别 + 组件 + 消息。
; 同组件同消息去重计数（每重复 50 次补记一条汇总）；超过 MaxSizeKB 轮转为 .old。
; 日志文件跨 Reload 追加保留 / Log persists across script reloads (append mode).
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
; 去重由 WMLog 统一处理（同一错误点生成相同文本 → 自动计数去重）
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
        ; 禁用 DWM 非客户区渲染，消除 Win10 19041+ SetWindowRgn 白边
        ; Disable DWM non-client rendering to fix SetWindowRgn white artifacts
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

; ---- MatchTitle / 标题匹配 ----
MatchTitleRule(text, rule) {
    rule := Trim(rule)
    if (rule = "")
        return false
    if (SubStr(rule, 1, 3) = "re:") {
        try return (text ~= SubStr(rule, 4)) ? true : false
        return false
    }
    if (SubStr(rule, 1, 1) = "=")
        return (StrLower(text) = StrLower(SubStr(rule, 2)))
    return InStr(text, rule, false) ? true : false
}

; ---- IsExcluded / 窗口排除 ----
IsExcludedWindow(hwnd) {
    global Excl_Titles, Excl_Classes, Excl_Processes
    if (Excl_Titles.Length = 0 && Excl_Classes.Length = 0 && Excl_Processes.Length = 0)
        return false
    title := "", cls := "", proc := ""
    try title := WinGetTitle(hwnd)
    try cls   := WinGetClass(hwnd)
    try proc  := WinGetProcessName(hwnd)
    for rule in Excl_Titles
        if MatchTitleRule(title, rule)
            return true
    for rule in Excl_Classes
        if (cls != "" && StrLower(cls) = StrLower(Trim(rule)))
            return true
    for rule in Excl_Processes
        if (proc != "" && StrLower(proc) = StrLower(Trim(rule)))
            return true
    return false
}

; ---- ParseAxis / 轴解析 ----
ParseAxis(tok) {
    tok := Trim(tok)
    if (tok = "")
        throw Error("empty axis")
    if (tok = "1")
        return {lo: 0.0, hi: 1.0, align: "Center"}
    ; 范围格式 / Range format: (a-c)/b, (a-c)/+b, (a-c)/-b
    if RegExMatch(tok, "^\((\d+)\s*-\s*(\d+)\)/([+\-]?)(\d+)$", &m) {
        a := Integer(m[1]), c := Integer(m[2]), b := Integer(m[4])
        sign := m[3]
        if (b <= 0 || a < 1 || c < 1 || a > c || c > b)
            throw Error("bad range axis: " tok)
        align := (sign = "+") ? "Right" : (sign = "-") ? "Left" : "Center"
        return {lo: (a - 1) / b, hi: c / b, align: align}
    }
    ; 简单格式 / Simple format: a/b, a/+b, a/-b
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
    global LayoutRules
    if (n < 1)
        return ""
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
        PlaceWin(hwnd, wx, wy, ww, wh)
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
                ; 键必须为整数（与 SwitchDesktop 等处一致），字符串键会导致查不到
                if hw && WinExist(hw)
                    DesktopFocus[Integer(m[1])] := hw
                continue
            }
        }
        FileDelete(stateFile)
    }
    if restored {
        ; 显示当前桌面窗口 / Show current desktop windows
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
; 四、启动流程 / 4. Startup Sequence
; ==============================================================================

OnError(WM_OnError)

WM_OnError(err, mode) {
    WMLogErr("Unhandled runtime error (" . mode . ")", err)
    return true
}

isFirstRun := !FileExist(ConfigFile)

LoadOrInitConfig()

    ; ---- 启动日志横幅 / Startup banner ----
    WMLog("============================================================", "INFO", "Startup")
    WMLog("AHK_WM v" . WM_Version . "  session start", "INFO", "Startup")
    WMLog("PID: " . ProcessExist() . "  |  Config: " . ConfigFile, "DEBUG", "Startup")
    WMLog("Desktop count: " . DesktopCount . "  |  Active theme: " . ActiveTheme, "DEBUG", "Startup")
    WMLog("Font: " . FontName . "  |  Bar height: " . Bar_Height . "px", "DEBUG", "Startup")
    WMLog("============================================================", "INFO", "Startup")
    OnExit(LogSessionExit)

Loop DesktopCount
    Desktops[A_Index] := []

; Restore layout from prior reload / 尝试恢复
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
; 五、热键注册 / 5. Hotkey Registration
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
    RegHotkey("ToggleMaximize", ToggleMaximizeUnderMouse)
    RegHotkey("ToggleTop",      ToggleTopDispatch)
    RegHotkey("HideWindow",     HideUnderMouse)
    RegHotkey("ToggleAllBorders", (*) => AllBorders.Toggle())

    RegHotkey("TransparencyUp",   AdjustTransparency.Bind(20))
    RegHotkey("TransparencyDown", AdjustTransparency.Bind(-20))

    RegHotkey("LaunchTerminal", LaunchTerminal)
    RegHotkey("EditFile",       OpenWithVim)
    RegHotkey("PowerMenu",      ShowPowerMenu)

    RegHotkey("SnapLeft",  SnapWindow.Bind("Left"))
    RegHotkey("SnapRight", SnapWindow.Bind("Right"))
    RegHotkey("SnapUp",    SnapWindow.Bind("Up"))
    RegHotkey("SnapDown",  SnapWindow.Bind("Down"))

    RegHotkey("SaveLayout",    SaveLayout)
    RegHotkey("RestoreLayout", RestoreLayout)

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
    RegHotkey("WTMFocusLeft",  (*) => WTM.FocusDir("L"))
    RegHotkey("WTMFocusDown",  (*) => WTM.FocusDir("D"))
    RegHotkey("WTMFocusUp",    (*) => WTM.FocusDir("U"))
    RegHotkey("WTMFocusRight", (*) => WTM.FocusDir("R"))
    RegHotkey("WTMMoveLeft",   (*) => WTM.MoveDir("L"))
    RegHotkey("WTMMoveDown",   (*) => WTM.MoveDir("D"))
    RegHotkey("WTMMoveUp",     (*) => WTM.MoveDir("U"))
    RegHotkey("WTMMoveRight",  (*) => WTM.MoveDir("R"))
}

; ---- PieMenuExecute / 饼菜单 ----
PieMenuExecute(*) {
    if PieMenu.IsActive
        PieMenu.Execute()
}

; ---- 功能环右键抬起处理（条件热键，按下被吞以避免弹出右键菜单）----
; ---- Pie-menu RButton-up handler (conditional; swallowed to avoid context menu) ----
PieMenuRButtonUp(*) {
    if PieMenu.IsActive
        PieMenu.Execute()
    PieMenu.PendingRUp := false
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
; 六、配置生成与迁移 / 6. Configuration Generation & Migration
; ==============================================================================

; ---- CfgRead / 配置读取 ----
CfgRead(sec, key, defVal, fallbacks*) {
    global ConfigFile
    miss := "__WM_MISSING__"
    v := IniRead(ConfigFile, sec, key, miss)
    if (v != miss)
        return v
    for fb in fallbacks {
        v := IniRead(ConfigFile, fb[1], fb[2], miss)
        if (v != miss)
            return v
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

; ---- 旧键名自动迁移（v2.9 命名统一为 PascalCase）/ Auto-migrate legacy key names ----
; 首次运行时把 [Bar] 的 snake_case 旧键改写为新键并删除旧键；
; 之后以 [General] ConfigVersion=2 标记跳过。读取侧仍保留旧键回退，双保险。
; 转义正则特殊字符
RegExEscape(s) => RegExReplace(s, "([.*?+\[\]{}()|\\^$])", "\$1")

MigrateConfigKeys() {
    global ConfigFile
    if !FileExist(ConfigFile)
        return
    if (IniRead(ConfigFile, "General", "ConfigVersion", "") = "2")
        return
    renames := [["Bar","time_format","TimeFormat"],["Bar","date_format","DateFormat"]
        ,["Bar","custom_items","CustomItems"],["Bar","desktop_labels","DesktopLabels"]
        ,["Bar","current_desktop_left","CurrentDesktopLeft"],["Bar","current_desktop_right","CurrentDesktopRight"]
        ,["Bar","current_desktop_color","CurrentDesktopColor"],["Bar","desktop_display_mode","DesktopDisplayMode"]
        ,["Bar","position","Position"],["Bar","offset","Offset"]
        ,["Bar","margin_left","MarginLeft"],["Bar","margin_right","MarginRight"]
        ,["Bar","layout","Layout"],["Bar","instances","Instances"]]
    ; 文本级替换，保留注释和顺序 / In-place key rename preserves comments
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

; 安全写入：文本级替换保留注释和顺序 / In-place key edit
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
; 七、配置读取与解析 / 7. Configuration Loading & Parsing
; ==============================================================================

; ---- SanitizeConfigEncoding / 修复配置文件编码 ----
; 检测 INI 文件中是否出现 Unicode 替换字符（UTF-16 被误存为 ANSI 的标志），
; 若是则用 IniRead 读出所有值，按 UTF-8 重建文件，保留全部配置数据。
SanitizeConfigEncoding() {
    global ConfigFile
    raw := ""
    try raw := FileRead(ConfigFile)
    ; 未出现乱码标记 → 无需修复
    if !InStr(raw, Chr(0xFFFD)) && !InStr(raw, "��")
        return
    WMLog("Config encoding corrupted, repairing...")
    ; 用 IniRead 抢救所有 section/key
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
    ; 重建文件（UTF-8）
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
; Theme name / 主题名称
; custom, nord, tokyonight, dracula, gruvbox, monokai, solarized-dark,
; solarized-light, catppuccin-mocha, catppuccin-latte, onedark, ayu-dark,
; github-dark, rose-pine, everforest, kanagawa, material-deep, nightfox,
; palenight, horizon, oxocarbon.
ActiveTheme=custom
; Font name (Nerd Font for icons) / 字体名称 (Nerd Font 用于图标)
FontName=Segoe UI
; Transparency step / 透明度调
TransparencyStep=10
; Pause script when fullscreen / 全屏时暂
PauseOnFullscreen=off

[Theme]
; All colors support gradient / 渐变色支持
Background=0e050f
Text=e5e9f0
Active=744da9
BorderDrag=A020F0,CBA6F7
BorderPin=FF5555
BorderUnfocus=666666
PowerMenuBg=2E3440
PowerBtnShutdown=B48EAD
PowerBtnSleep=5E81AC
PowerBtnReboot=BF616A
; Per-component (default = base color) / 组件专属

[Paths]
; Button scripts dir / 按钮脚本
ButtonDir=Buttons
; Clipboard output dir / 剪贴板输
OutputDir=%OUTPUTDIR%
; Clipboard filename / 剪贴板文
OutputFile=CB.txt
; Editor / 编辑器
VimPath=C:\Windows\system32\notepad.exe
; terminal / 终端
TerminalExe=C:\Windows\system32\cmd.exe
; Editor geometry in screen percent. / 编辑器窗
EditorXPct=20
EditorYPct=0
EditorWidthPct=52
EditorHeightPct=74

[Desktop]
; Virtual desktop count: 1-9. / 虚拟桌面
Count=9
; Inactive-desktop handling: minimize | hide / 非当前桌
HideMethod=minimize

[Bar]
; Bar height (percent of screen height) / 栏高百分比
HeightPct=3
; Opacity (0-100) / 不透明度
Opacity=78
; Font size / 字号
FontSize=10
; Monitor index / 显示器编号
MonitorIdx=1
; Time format (FormatTime pattern) / 时间格式
TimeFormat=HH:mm
; Date format (FormatTime pattern) / 日期格式
DateFormat=yyyy-MM-dd
; Custom items (;-separated) / 自定义内容
CustomItems=✐ Edit config to hide
; Desktop labels (,-separated) / 桌面名称
DesktopLabels=Work,Net
; Current desktop tags / 当前桌面标记 (use \s for literal space 用\s转义空格)
CurrentDesktopLeft=[
CurrentDesktopRight=]
; Current desktop highlight gradient (same format as layout: color1,color2,bg|tx,on|off)
; Leave empty to disable / 留空则不高亮：ffffff,cccccc,bg,on
CurrentDesktopColor=
; Desktop display mode: all|current|occupied / 桌面显示模式
DesktopDisplayMode=all
; Edge position: top|bottom / 栏位置
Position=top
; Edge offset (px) / 边偏移
Offset=0
; Left/Right margin (px) / 左右边距
MarginLeft=0
MarginRight=0
	;----------------------------------------------------------------------
	; Element layout / 元素布局
	;   N,element,span,c1..cn,bg|tx,on|off;...
	;   N=bar#(default 1)
	;   span=(a-c)/d  -- +d=right-align, -d=left-align, d=center
	;   bg=gradient background / tx=gradient text
	;   on|off=rounded corners (bg mode) / colors=6hex comma sep, supports # prefix
	;   Legacy compatible: element:span,color,...
	;   Available: desktops, time, date, progress, wifi, battery, volume, disk,
	;   mem, cpu, custom_1..n, external_1..n
	;   external_N = text pushed by an external script via WM_COPYDATA
	;   ("BAR:N:text", see bar-custom-*.ahk examples); persists until next push
	;   Current-desktop highlight: CurrentDesktopColor=color1,color2,bg|tx,on|off
	; Examples:
	;   1,time,20/20,ff0000,00ff00,tx;desktops,(1-3)/-20,FAB387,bg,on;cpu,14/+20;
	;----------------------------------------------------------------------
Layout=custom_1,(4-7)/20,B48EAD,CF8DC9,bg,on;desktops,(1-3)/20;date,(18-19)/20;time,20/20,744da9,CF8DC9;progress,3/5,744da9,e5e9f0;
; Multi-bar instances: M,pos,offset;...  M=monitor or * / 多栏实例
Instances=1,top,0
; Auto-hide on fullscreen: on|off / 全屏自动隐藏
AutoHideOnFullscreen=on
; Rounded corners / 圆角
Rounded=on
CornerRadius=10
CornerMode=bottom

[Border]
; Border refresh interval / 边框刷新
RefreshMs=10
; Drag border enable / 拖拽边框
Enable=on
; Border mode / 边框模式 top|full
Mode=full
; Thickness / 厚度
Thickness=35
; Offset / 内缩
Offset=15
; Top offset / 顶部内缩
OffsetTop=5
; Opacity / 不透明度 0-100
Opacity=80
; Rounded corners / 圆角开关 on|off
RoundedCorners=on
; Radius / 圆角半径 px
Radius=10
; Corner mode / 圆角模式 all|top|bottom
CornerMode=all
; WTM gap / WTM 平铺间隙 px
Gap=10
; WTM size step / WTM 调整步长
SizeStep=3
; Pin mode / 置顶指示
PinMode=top
; Pin thickness / 置顶指示
PinThickness=35
; Pin offset / 置顶指示
PinOffset=0
; Pin top offset / 置顶指示
PinOffsetTop=5
; Pin opacity / 置顶不透
PinOpacity=90
; Pin rounded / 置顶圆角 on|off
PinRounded=off
; Pin radius / 置顶圆角
PinRadius=0

[Tiling]
; WTM tiling gap (px, may be negative) / 平铺间隙
Gap=15
; Tile always-on-top windows / 置顶窗口参与平铺
TileAlwaysOnTop=off
; Custom layout rules: M,N,I,X,Y;... (see README for full docs)
; M=monitor (*=all), N=window count, I=window index, X/Y=span
; (1=full, a/b=segment, (a-c)/b=multi-segment). Exact > * > default.
; Example / 示例:
;   1,3,1,1/2,1  -> 3 windows on monitor 1: #1 left half full height
;   1,3,2,2/2,1/2 -> #2 right half top half
;   1,3,3,2/2,2/2 -> #3 right half bottom half
;
; Layout visualization / 布局示意:
;
; +-----------+-----------+
; |           |  W#2 top  |
; |   W#1     |-----------|
; |           |  W#3 bot  |
; +-----------+-----------+
;
Rules=1,3,1,1/2,1;1,3,2,2/2,1/2;1,3,3,2/2,2/2;1,5,1,(2-4)/5,1;1,5,2,1/5,1/2;1,5,3,1/5,2/2;1,5,4,5/5,(1-2)/3;1,5,5,5/5,3/3;

[Snapping]
; Snap enable / 吸附开关 on|off
Enable=on
; Snap distance / 触发距离 px
Distance=0
; Snap release / 脱离距离 px
Release=5

[PieMenu]
; Pie menu size (% of screen min side) / 功能环尺寸
SizePct=28
; Center dead zone (%) / 中心死区
CenterZonePct=27
; Opacity (0-100) / 不透明度
Opacity=78
; Font size / 字体大小
FontSize=14
; Active sector font size / 激活态字号
FontSizeActive=22

[GUI]
; Global rounded / 全局圆角 on|off
RoundedCorners=on
; Global corner radius / 全局圆角
CornerRadius=12
; Help font size / 帮助字体
HelpFontSize=10
; Help width / 帮助宽度 px
HelpWidth=620
; Help height / 帮助高度 px (0=auto)
HelpHeight=0
; Help opacity / 帮助不透
HelpOpacity=100
; Power font size / 电源字体
PowerFontSize=12
; Power width / 电源宽度 px
PowerWidth=500
; Power height / 电源高度 px
PowerHeight=160
; Power opacity / 电源不透
PowerOpacity=100
; OSD position pct / OSD 位置 %
OSDPositionPct=80
; OSD opacity / OSD 不透明度
OSDOpacity=78
; OSD font size / OSD 字体大小
OSDFontSize=20

[WorkTime]
; Work time mode: off|workday|allday / 工作时间模式
Mode=off
; Weekend progress bar: on|off / 周末进度条
WeekendBar=off
; Work hours (HHMM) / 工作时段
WorkStart=0900
WorkEnd=1745
; Task slots / 任务时段
;   weekday_start_end,color,...;...  1=Mon..7=Sun
;   Colors optional, fallback = theme / 颜色可选，默认主题色
TaskTimes=1_1200_1300,CDD6F4;2_1200_1300,CDD6F4;3_1200_1300,CDD6F4;4_1200_1300,CDD6F4;5_1200_1300,CDD6F4;6_1200_1300,CDD6F4;7_1200_1300,CDD6F4;2_1700_1745;3_0900_0920;1_1545_1600;2_1545_1600;3_1545_1600;4_1545_1600;5_1545_1600;1_1330_1500;

[Exclude]
; Excluded titles / 排除标题 contains|re:|=
Titles=Picture-in-Picture
; Excluded classes / 排除类名
Classes=
; Excluded processes / 排除进程
Processes=

[WinSelect]
; Scale ratio / 缩放比例
ScaleRatio=0.85
; Letter pool / 字母池
Letters=ASDFGHJKLQWERTYUIOPZXCVBNM
; Size map / 尺寸映射 N:ratio|WxH;...
SizeMap=1:0.5;2:0.8;3:1.2;9:1920x1080
; Bar color (empty=theme) / 标签条颜
BarColor=
TextColor=
; Bar height, width (0=window width) / 标签条高
Height=28
Width=0
; Label offset / 标签偏移
OffsetY=0
; Label font size / 标签字体
FontSize=14
; Opacity / 不透明度 0-100
Opacity=85
; Rounding / 圆角
Rounded=on
CornerRadius=10
CornerMode=top
; Auto-exit seconds (0=never) / 无按键退
Timeout=12

[WinSelectSidebar]
; Font size / 字体大小
FontSize=14
; Width / 宽度
Width=80
; Position / 位置 left|right
Position=left
OffsetX=10
OffsetY=0

[Clipboard]
; Max chars per history entry (0=unlimited) / 单条历史上限字符数
MaxChars=100000
; Processes excluded from clipboard logging (;-separated) / 排除记录的进程
; Example / 示例: KeePass.exe;1Password.exe
ExcludeProcesses=
; Log binary clipboard content info (file paths / content type): on|off / 记录二进制内容信息
LogBinary=on

[Logging]
; Log file path (empty = config dir\wm.log) / 日志文件路径（留空=配置目录）
File=
; Log level: DEBUG|INFO|WARN|ERROR / 日志级别
Level=INFO
; Rotate log when it exceeds this size (KB, 0=never) / 轮转阈值
MaxSizeKB=512

;--------------------------------------------------------------------------
; Hotkeys: natural names joined by '+' / 热键自然
; Alt / Shift / Ctrl / Win
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
ToggleBar=Ctrl+Alt+B
SaveLayout=Alt+Shift+S
RestoreLayout=Alt+Shift+R

CloseWindow=Alt+Q
CloseWindowAlt=Alt+MButton
ToggleMaximize=Alt+F
ToggleTop=Alt+T
HideWindow=Alt+W
ToggleAllBorders=
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

WTMToggle=
WTMFocusLeft=Alt+H
WTMFocusDown=Alt+J
WTMFocusUp=Alt+K
WTMFocusRight=Alt+L
WTMMoveLeft=Alt+Shift+H
WTMMoveDown=Alt+Shift+J
WTMMoveUp=Alt+Shift+K
WTMMoveRight=Alt+Shift+L
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
        ; 检测配置文件编码损坏（UTF-16 → ANSI 误存导致中文乱码）并自动修复
        SanitizeConfigEncoding()
        ; 旧键名自动迁移（v2.9 统一命名）/ Migrate legacy key names
        MigrateConfigKeys()
    }

    ; ---- 日志配置（尽早加载，后续解析错误才能按配置记录）/ [Logging] ----
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
    Color_BorderUnfocus := Border_UnfocusColor  ; 向后兼容
    Border_Drag_Color   := Border_FocusColor    ; 向后兼容

    PM_Bg          := CfgRead("Theme", "PowerMenuBg",      "2E3440", ["Colors","PowerMenuBg"])
    PM_BtnShutdown := CfgRead("Theme", "PowerBtnShutdown", "B48EAD", ["Colors","PowerBtnShutdown"])
    PM_BtnSleep    := CfgRead("Theme", "PowerBtnSleep",    "5E81AC", ["Colors","PowerBtnSleep"])
    PM_BtnReboot   := CfgRead("Theme", "PowerBtnReboot",   "BF616A", ["Colors","PowerBtnReboot"])
    ; -- 组件专属色（空值回退基础色）/ Per-component colors (empty = base) --
    ; Use CfgRead with fallback; C1 handles empty with default color

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
    PauseOnFullscreen := (StrLower(Trim(IniRead(ConfigFile, "General", "PauseOnFullscreen", "off"))) = "on")

    Border_Enable := CfgRead("Border", "Enable", "on", ["Border","DragEnable"], ["BorderDrag","Enable"])

    Border_Mode := StrLower(Trim(CfgRead("Border", "Mode", "full", ["Border","DragMode"], ["WTM","BorderMode"])))
    if !(Border_Mode = "top" || Border_Mode = "full")
        Border_Mode := "full"

    ; 颜色统一从 [Theme] 读取，[Border] FocusColor 作为旧版回退
    ; Colors unified in [Theme]; [Border] FocusColor kept as legacy fallback
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
    ; 缺省值与模板一致改为 off（原代码默认 on；模板显式写 off，绝大多数用户不受影响）
    Tile_IncludeAlwaysOnTop := BarShown(IniRead(ConfigFile, "Tiling", "TileAlwaysOnTop", "off"))

    Snap_Enable   := BarShown(IniRead(ConfigFile, "Snapping", "Enable", "on"))
    Snap_Distance := Integer(IniRead(ConfigFile, "Snapping", "Distance", "12"))
    Snap_Release  := Max(0, Integer(IniRead(ConfigFile, "Snapping", "Release", "8")))

    Excl_Titles      := SplitExcludeList(IniRead(ConfigFile, "Exclude", "Titles",    ""))
    Excl_Classes     := SplitExcludeList(IniRead(ConfigFile, "Exclude", "Classes",   ""))
    Excl_Processes   := SplitExcludeList(IniRead(ConfigFile, "Exclude", "Processes", ""))

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
    Desktop_HideMethod := StrLower(CfgRead("Desktop", "HideMethod", "minimize", ["Desktops","HideMethod"]))
    if !(Desktop_HideMethod = "minimize" || Desktop_HideMethod = "hide")
        Desktop_HideMethod := "minimize"

    ; [Bar] 键名 v2.9 统一为 PascalCase，旧 snake_case 键作为回退 / new names, legacy fallbacks
    Bar_Cfg := Map()
    Bar_Cfg["layout"]       := ParseBarLayout(CfgRead("Bar", "Layout", "", ["Bar","layout"]))
    ; 从 bar 1 layout 推断组件开关 / Derive widget flags from bar 1 layout
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
    ; layout 已在上面解析，此处复用 / layout already parsed above

    Bar_Cfg["custom_items"] := ParseCustomItems(
        CfgRead("Bar", "CustomItems", "", ["Bar","custom_items"]),
        IniRead(ConfigFile, "Bar", "custom_icon",  ""),
        IniRead(ConfigFile, "Bar", "custom_text",  ""))

    Bar_AutoHide := BarShown(IniRead(ConfigFile, "Bar", "AutoHideOnFullscreen", "off"))

    ; ---- 剪贴板模块 / [Clipboard] ----
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

    ; 默认值与模板一致改为 off（原代码默认 on 与模板注释矛盾）/ default aligned with template
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
               "TileSmart","GatherAll","TogglePin","ToggleBar","SaveLayout","RestoreLayout",
               "CloseWindow","CloseWindowAlt","ToggleMaximize","ToggleTop","HideWindow",
               "ToggleAllBorders",
               "TransparencyUp","TransparencyDown",
               "SnapLeft","SnapRight","SnapUp","SnapDown",
               "LaunchTerminal","EditFile","PowerMenu","ClipboardHistory",
               "DragMove","DragResize","PieMenuTrigger","WinSelect",
               "WTMToggle","WTMFocusLeft","WTMFocusDown","WTMFocusUp","WTMFocusRight",
               "WTMMoveLeft","WTMMoveDown","WTMMoveUp","WTMMoveRight"]
    hkDefaults := Map(
        "Help","Alt+/","Exit","Alt+F12","Reload","Alt+R",
        "DesktopSwitchPrefix","Alt","DesktopMovePrefix","Alt+Shift","DesktopMoveSwitchPrefix","Ctrl+Alt",
        "TileSmart","Alt+D","GatherAll","Alt+Shift+G","TogglePin","Ctrl+Alt+T","ToggleBar","Ctrl+Alt+B",
        "SaveLayout","Alt+Shift+S","RestoreLayout","Alt+Shift+R",
        "CloseWindow","Alt+Q","CloseWindowAlt","Alt+MButton","ToggleMaximize","Alt+F",
        "ToggleTop","Alt+T","HideWindow","Alt+W","ToggleAllBorders","Alt+B",
        "TransparencyUp","Alt+WheelUp","TransparencyDown","Alt+WheelDown",
        "SnapLeft","Alt+Left","SnapRight","Alt+Right","SnapUp","Alt+Up","SnapDown","Alt+Down",
        "LaunchTerminal","Alt+Enter","EditFile","Alt+V","PowerMenu","Alt+X","ClipboardHistory","Ctrl+``",
        "DragMove","Alt+LButton","DragResize","Alt+RButton","PieMenuTrigger","~Space & RButton",
        "WinSelect","Alt+S",
        "WTMToggle","Alt+Shift+D",
        "WTMFocusLeft","Alt+H","WTMFocusDown","Alt+J","WTMFocusUp","Alt+K","WTMFocusRight","Alt+L",
        "WTMMoveLeft","Alt+Shift+H","WTMMoveDown","Alt+Shift+J",
        "WTMMoveUp","Alt+Shift+K","WTMMoveRight","Alt+Shift+L"
    )
    for k in hkKeys {
        raw := IniRead(ConfigFile, "Hotkeys", k, hkDefaults[k])
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
; 八、通用界面 / 8. Common GUI (Help / Welcome / Buttons / OSD)
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
        [PrefP("WinSelect"),                  "Window Select Mode"],
        [PrefP("ToggleAllBorders"),           "Toggle All Window Borders"],
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

    ; -- 显示欢迎屏 / Show the welcome screen --
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
            "  >  Layout Snapshot             " . PrettifyHotkey(HK["SaveLayout"]) . " / " . PrettifyHotkey(HK["RestoreLayout"]),
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
        ; ★ v2.6.2: force welcome screen to top so it's never behind the bar
        try WinSetAlwaysOnTop(1, g.Hwnd)
        try WinActivate(g.Hwnd)
        this.GuiObj := g
        this.HintCtrl := hint
        this.HintState := true
        SetTimer(ObjBindMethod(this, "Blink"), 600)
        SetTimer(ObjBindMethod(this, "WaitClose"), 50)
    }

    ; -- 提示闪烁 / Blink the hint line --
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

    ; -- 等待关闭 / Wait for a close key --
    static WaitClose() {
        if !IsObject(this.GuiObj) {
            SetTimer(ObjBindMethod(this, "WaitClose"), 0)
            return
        }
        if (GetKeyState("LButton","P") || GetKeyState("Escape","P")
         || GetKeyState("Enter","P")  || GetKeyState("Space","P"))
            this.Close()
    }

    ; -- 关闭欢迎屏 / Close the welcome screen --
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
    static GuiObj := 0, Timer := 0           ; 内部 OSD（wm.ahk 自身调用，单实例互替）
    static ExtGuis := Map()                  ; 外部 OSD（脚本调用，多实例共存，互不干扰）

    ; -- 解析键值选项 "fs=24,op=90,bg=FF4444" → Map --
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

    ; -- 内部 OSD（wm.ahk 自身调用，始终使用配置文件设置，单实例）--
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

        ; Scale padding & max-width to font size / 随字号缩放
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
            ; Rebuild with constrained width, multi-line / 超宽则换行重建
            g.Destroy()
            g := Gui("+AlwaysOnTop -Caption +ToolWindow +Disabled +Owner -DPIScale")
            g.BackColor := Color_Bg
            g.SetFont("s" . OSD_FontSize . " w600 c" . Color_Active, FontName)
            g.Add("Text", "x" padX " y" padY " w" (maxW - padX*2) " Center", text)
            g.Show(Format("NoActivate AutoSize Hide"))
            g.GetPos(, , &gw, &gh)
        }
        g.Show(Format("NoActivate AutoSize x{} y{}", cx - gw//2, OSD_Height))

        WinSetTransparent(OSD_Transparent, g.Hwnd)
        RoundWindowEx(g, OSD_Rounded, OSD_Radius)

        this.GuiObj := g
        this.Timer  := () => (IsObject(OSD.GuiObj) ? (OSD.GuiObj.Destroy(), OSD.GuiObj := 0) : 0)
        SetTimer(this.Timer, -duration)
    }

    ; -- 外部 OSD（脚本通过 WM_COPYDATA 调用，支持 per-call 覆盖，多实例共存）--
    static ShowExternal(text, duration := 1000, optsStr := "") {
        global OSD_FontSize, OSD_Transparent, OSD_Height, Color_Bg, Color_Active
        global OSD_Rounded, OSD_Radius
        o := OSD._ParseOpts(optsStr)

        ; ---- 逐项解析：有则用覆盖值，缺则回退配置文件全局值 ----
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

        ; ---- x/y 定位（像素或百分比），pos=N 旧版兼容 ----
        if o.Has("x") {
            xs := o["x"]
            xPos := RegExMatch(xs, "^(\d+)%$", &xp) ? mL + Round(monW * Integer(xp[1]) / 100) : mL + Integer(xs)
        } else {
            xPos := cx
        }
        if o.Has("y") {
            ys := o["y"]
            yPos := RegExMatch(ys, "^(\d+)%$", &yp) ? mT + Round(monH * Integer(yp[1]) / 100) : mT + Integer(ys)
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

        ; ---- 注册到外部实例表，独立 self-destruct ----
        extId := Format("ext_{:04d}", A_TickCount & 0xFFFF)
        g._tag := tagVal  ; 在 Gui 对象上标记 tag
        OSD.ExtGuis[extId] := g
        fn := ObjBindMethod(OSD, "_DestroyExt", extId)
        SetTimer(fn, -duration)
        return extId
    }

    ; -- 销毁指定外部 OSD 实例（仅销毁自身，不影响内部 OSD）--
    static _DestroyExt(extId) {
        if !OSD.ExtGuis.Has(extId)
            return
        try OSD.ExtGuis[extId].Destroy()
        OSD.ExtGuis.Delete(extId)
    }
}

; ---- OSD shorthand / OSD快捷（内部调用，始终用配置）----
ShowOSD(text) => OSD.Show(text)

; ---- 外部消息接口 / External interface via WM_COPYDATA ----
; 其他 AHK 脚本可通过 SendMessage 向 AHK_WM 发送消息（查找主窗口
; "wm.ahk ahk_class AutoHotkey"），支持两种协议：
;   "OSD:消息文本[:持续时间ms][:键值选项]"  → 弹出 OSD 提示（外部，per-call 自定义）
;   "BAR:槽位号:文本"                      → 旧版 bar（需 Layout 声明 external_N）
;   "BAR:槽位号:lo/hi:文本[:键值选项]"      → 新版 bar（自包含，无需 Layout）
;
; OSD 键值: fs=N,op=N,x=N[%],y=N[%],pos=N,bg=RRGGBB,tx=RRGGBB,wr=N,rd=on|off,rr=N,fn=Name,tag=ID
;   x=N[%] / y=N[%] — 像素或%坐标; pos=N — 旧版垂直%
; BAR 键值: bg=RRGGBB,tx=RRGGBB,rd=on|off,rr=N,fs=N,wrap=N
; 所有键均可选，未指定回退默认值。外部 OSD 与内部 OSD 实例隔离、互不干扰。
OnMessage(0x4A, _WM_OnCopyData)  ; WM_COPYDATA

_WM_OnCopyData(wParam, lParam, msgNum, hwnd) {
    global Bar_ExternalData
    ; COPYDATASTRUCT: dwData(ptr) + cbData(u32) + lpData(ptr)
    cds := lParam
    cbData := NumGet(cds, A_PtrSize, "UInt")
    lpData := NumGet(cds, A_PtrSize * 2, "Ptr")
    if !lpData || !cbData
        return false
    ; cbData 是字节数：转字符数读取并剔除结尾 NUL
    text := RTrim(StrGet(lpData, cbData // 2, "UTF-16"), Chr(0))
    if (SubStr(text, 1, 4) = "OSD:") {
        payload := SubStr(text, 5)
        dur := 1000, optsStr := ""
        ; 先尝试匹配键值选项后缀 / Try key=value suffix first
        if RegExMatch(payload, "^(.*?):([a-z]{1,4}=.*)$", &mKv) {
            pre := mKv[1], optsStr := mKv[2]
            ; pre 可能还带持续时间 :digits
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
        slot := Integer(mBar[1]), rest := mBar[2]
        ; ---- 自包含格式：BAR:slot:lo/hi:text[:opts] ----
        if RegExMatch(rest, "^([\d.]+)/([\d.]+):(.*)$", &mSc) {
            lo := Number(mSc[1]), hi := Number(mSc[2])
            afterSpan := mSc[3]
            txt := afterSpan, optsStr := ""
            if RegExMatch(afterSpan, "^(.*?):([a-z]{1,4}=.*)$", &mOpts)
                txt := mOpts[1], optsStr := mOpts[2]
            ; 更新槽位配置
            cfg := Bar_ExternalSlots.Has(slot) ? Bar_ExternalSlots[slot] : Map()
            changed := (!cfg.Has("lo") || cfg["lo"] != lo || cfg["hi"] != hi)
            cfg["lo"] := lo, cfg["hi"] := hi
            if (optsStr != "") {
                for part in StrSplit(optsStr, ",") {
                    part := Trim(part)
                    if RegExMatch(part, "^([a-z]{1,4})=(.*)$", &kv2) {
                        key := kv2[1], val := Trim(kv2[2])
                        if (!cfg.Has(key) || cfg[key] != val)
                            changed := true
                        cfg[key] := val
                    }
                }
            }
            Bar_ExternalSlots[slot] := cfg
            Bar_ExternalData[slot] := txt
            if changed {
                CreateStatusBar()
                UpdateExternalWidgets()
            } else {
                try UpdateExternalWidgets(slot)
            }
            return true
        }
        ; ---- 旧格式：BAR:slot:text ----
        Bar_ExternalData[slot] := rest
        try UpdateExternalWidgets(slot)
        return true
    }
    return false
}

; ---- 推送刷新所有 bar 的 external 部件 / Refresh external widgets on all bars ----
UpdateExternalWidgets(slot := 0) {
    global Bars
    if !IsSet(Bars)
        return
    for b in Bars
        try b.UpdateExternal(slot)
}

; ==============================================================================
; Border System (BorderFrame / DragBorder / PinBorder) / 九边框系
; ==============================================================================

; ---- Hollow-frame border window / 空心边框 ----
class BorderFrame {
    Gui   := ""
    Color := ""
    LastW := -1, LastH := -1, LastT := -1, LastR := -1
    LastMode := ""
    ; 上次 Place 的完整几何（未变时跳过 SetWindowPos，高刷屏下省大量系统调用）
    ; Last placement geometry — unchanged placements skip SetWindowPos entirely
    LastPX := -99999, LastPY := -99999, LastPW := -1, LastPH := -1
    LastThk := -1, LastRadC := -1, LastPMode := ""
    _GbW := -1, _GbH := -1  ; Gradient cache dims / 渐变缓存尺寸
    GradCols := []
    GradPic := ""
    BigGradBM := 0  ; Pre-rendered large gradient to reuse / 预渲染大渐变底图

    ; -- 创建 / __New --
    __New(color, opacity) {
        pc := ParseColor(color)
        g := Gui("-Caption +ToolWindow +E0x20 -DPIScale")
        g.BackColor := pc.first
        g.Show("NoActivate x-3000 y-3000 w10 h10")
        try WinSetTransparent(opacity, g.Hwnd)
        this.Gui      := g
        this.Color    := color
        this.GradCols := pc.isGrad ? pc.colors : []
        this.GradPic  := ""
    }

    ; -- 颜色 / SetColor --
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
        ; 渐变内容已变：销毁旧渐变图并强制下次 Place 重建
        ; Gradient changed: drop cached picture so next Place rebuilds it
        this._GbW := -1, this._GbH := -1
        if IsObject(this.GradPic) {
            try this.GradPic.Destroy()
            this.GradPic := ""
        }
        ; 重置几何缓存，强制下次 Place 完整重建（颜色变了但位置未变时也必须重绘）
        ; Reset geometry cache so next Place does a full rebuild (required when color
        ; changes but position/size stay the same — Place would otherwise skip it).
        this.LastPX := -99999, this.LastPY := -99999
        if (this.GradCols.Length > 1 && this.LastPW > 0)
            this._GradBg(this.LastPW, this.LastPMode = "top" ? this.LastThk : this.LastPH)
    }

    ; -- Gradient background / 渐变背景 --
    _GradBg(w, h) {
        if !(this.GradCols.Length > 1) && !this.BigGradBM
            return
        if (w = this._GbW && h = this._GbH)
            return
        this._GbW := w, this._GbH := h
        if this.BigGradBM {
            ; Reuse big bitmap — just Move existing Picture, no destroy/recreate
            if IsObject(this.GradPic) {
                try this.GradPic.Move(0, 0, w, h)
            } else {
                this.GradPic := this.Gui.Add("Picture", "x0 y0 w" w " h" h, "HBITMAP:" this.BigGradBM)
            }
            return
        }
        ; No big bitmap — create exact-size gradient, add before destroy to avoid flash
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

    ; -- Z序 / _ZOrder --
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

    ; -- Place border / 定位边框 --
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
        ; 几何完全未变：跳过重定位（锚定窗口时仅低成本重申 Z 序）
        ; Unchanged geometry: skip SetWindowPos; hwnd-anchored frames re-assert z-order only
        if (x = this.LastPX && y = this.LastPY && w = this.LastPW && h = this.LastPH
         && t = this.LastThk && rad = this.LastRadC && mode = this.LastPMode) {
            if (insertAfter != -1 && insertAfter != 0) {
                ins := this._ZOrder(insertAfter)
                try DllCall("SetWindowPos", "Ptr", this.Gui.Hwnd, "Ptr", ins
                    , "Int", 0, "Int", 0, "Int", 0, "Int", 0
                    , "UInt", 0x1 | 0x2 | 0x10 | 0x40)   ; NOSIZE|NOMOVE|NOACTIVATE|SHOW
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
        ; Update gradient BEFORE resize — prevents flash / 先更新渐变再调尺寸
        this._GradBg(w, h)
        try DllCall("SetWindowPos", "Ptr", this.Gui.Hwnd, "Ptr", ins
            , "Int", x, "Int", y, "Int", w, "Int", h
            , "UInt", 0x10 | 0x40)
        if (mode = "top")
            this._ApplyTopRegion(w, t)
        else
            this._ApplyRegion(w, h, t, rad)
    }

    ; -- 顶条 / _ApplyTopRegion --
    _ApplyTopRegion(w, t) {
        if (this.LastMode = "top" && w = this.LastW && t = this.LastT)
            return
        this.LastMode := "top", this.LastW := w, this.LastH := t, this.LastT := t, this.LastR := 0
        try DllCall("User32\SetWindowRgn", "Ptr", this.Gui.Hwnd, "Ptr", 0, "Int", 1)
    }

    ; -- 空心框 / _ApplyRegion --
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

    ; -- 显示（不激活）/ Show without activating --
    ; 修复：旧版 Show() 实际执行 SW_HIDE，且各处调用的 Hide() 并不存在
    ; Fix: legacy Show() actually hid the window and callers used a missing Hide()
    Show() {
        if IsObject(this.Gui)
            try DllCall("ShowWindow", "Ptr", this.Gui.Hwnd, "Int", 8)   ; SW_SHOWNA
    }

    ; -- 隐藏 / Hide --
    Hide() {
        if IsObject(this.Gui)
            try DllCall("ShowWindow", "Ptr", this.Gui.Hwnd, "Int", 0)   ; SW_HIDE
        this.LastPX := -99999   ; 隐藏后强制下次 Place 重新定位 / force re-place next time
    }

    ; -- 销毁 / Destroy --
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

    ; -- Show border, pre-render big gradient / 显示 +预渲大渐变 --
    static Show() {
        if (Border_Enable != "on")
            return
        this.Destroy()
        this.Frame := BorderFrame(Border_FocusColor, Border_Opacity)
        ; Pre-render one large gradient at monitor resolution — reuse during resize
        pc := ParseColor(Border_FocusColor)
        if (pc.isGrad) {
            MonitorGetWorkArea(MonitorGetPrimary(), &mL, &mT, &mR, &mB)
            this.Frame.BigGradBM := CreateGradient(mR - mL, mB - mT, 0, pc.colors*)
        }
        this.LastX := -9999, this.LastY := -9999, this.LastW := -1, this.LastH := -1
    }

    ; -- Update position / 更新位置 --
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
        ; Skip if unchanged / 未变则跳过
        if (x = this.LastX && y = this.LastY && w = this.LastW && h = this.LastH)
            return
        this.LastX := x, this.LastY := y, this.LastW := w, this.LastH := h
        this.Frame.Place(x, y, w, h, Border_Thickness, rad, Border_Opacity, Border_Mode, -1)
    }

    ; -- Destroy / 销毁 --
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

    ; -- 添加 / Add a pinned window --
    static Add(hwnd) {
        if this.Map.Has(hwnd)
            return
        this.Map[hwnd] := BorderFrame(Border_Pin_Color, Border_Pin_Transparent)

        if !this.Started {
            SetTimer(this.TimerFn, Border_RefreshMs)
            this.Started := true
        }
    }

    ; -- 移除 / Remove a pinned window --
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

    ; -- 全部移除 / Remove all --
    static RemoveAll() {
        for hwnd, _ in this.Map.Clone()
            this.Remove(hwnd)
    }

    ; -- 定时刷新 / Periodic refresh --
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
            ; ★ v2.6.4: Pin bar uses own rounded settings from [Border] PinRounded/PinRadius
            rad := (Border_Pin_Rounded = "on") ? Border_Pin_Radius : 0
            frame.Place(x, y, w, h, t, rad, Border_Pin_Transparent, Border_Pin_Mode, -1)
        }
    }
}

; ==============================================================================
; Window Actions / 十窗口操
; ==============================================================================

; ---- 获取鼠标下窗口（排除 bar）/ Get HWND under mouse (exclude bar) ----
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
; Pie Menu / 十一功能
; ==============================================================================

; ---- Radial pie menu / 功能环 ----
class PieMenu {
    static DirMap   := ["Right","DownRight","Down","DownLeft","Left","TopLeft","Top","TopRight"]
    static IsActive := false, GuiObj := "", Labels := Map()
    static PendingRUp := false
    static TimerFn  := ObjBindMethod(PieMenu, "CheckMouse")
    static StartX   := 0, StartY := 0, CurrentSector := "", LastSector := ""

    ; -- 启动 / Start --
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

    ; -- 构建 / CreateGui --
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

    ; -- 扇区 / CheckMouse --
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

    ; -- 高亮 / UpdateUI --
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

    ; -- 执行 / Execute --
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
; Virtual Desktops / 十二虚拟
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
        try DllCall("ShowWindow", "Ptr", hwnd, "Int", 9)   ; SW_RESTORE（非 SW_SHOWNA，避免最小化窗口无法还原）
    }
    else{
        try WinRestore(hwnd)
    }
}

; ---- 从所有桌面移除窗口 / Remove window from all desktops ----
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

; ---- 桌面切换忙标志 / Desktop switching busy flag ----

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
            WTM.SaveOrderForDesktop(CurrentDesktop)   ; 保留本桌面平铺顺序 / keep this desktop's order
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
        ; 从底到顶恢复 Z 序 / Restore bottom→top to preserve Z-order
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
        ; 隐藏不可见窗口的置顶边框（目标桌面窗口已 ShowWin 可见，不会被隐藏）
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
    ; 记录被移动窗口为目标的聚焦窗口，切换桌面时自动聚焦
    DesktopFocus[target] := hwnd

    if (target != CurrentDesktop) {
        HideWin(hwnd)
        ShowOSD("Window -> Desktop " . target)
    } else {
        ; 同桌面移动：立即置顶 / Same-desktop move: raise immediately
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
        ; 用户带窗口过来是为了立即使用：抵达后置于目标桌面所有窗口之上
        ; （一次性 Z 序调整，非持久置顶）/ One-shot raise on arrival, not a pin
        try WinMoveTop(hwnd)
        DesktopFocus[target] := hwnd
    }
    ShowOSD("Move And Switch -> " . target)
}

; ==============================================================================
; 十三、状态栏 / 13. Status Bar
; ==============================================================================

; ---- Truthy-flag parsing for config values / 开关判定 ----
BarShown(str) {
    s := StrLower(Trim(str))
    return !(s = "" || s = "false" || s = "off" || s = "0")
}
; 通用别名（非 Bar 场景使用更清晰的命名）
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
        ; 解析剩余字段：颜色(6位hex)、模式(bg/tx)、圆角(on/off)、字体(fs=N)、换行(wrap=N)
        colors := [], mode := "text", rounded := "off", fontSize := 0, wrapLines := 0
        loop fields.Length - idx + 1 {
            f := Trim(fields[idx + A_Index - 1])
            if (f = "")
                continue
            if RegExMatch(f, "^[0-9a-fA-F]{6}$")
                colors.Push(f)
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
; 格式同 layout 颜色尾部：color1,color2,...,bg|tx,on|off
; 返回 {colors, mode, rounded} 或空 Map（未配置）
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
        if RegExMatch(f, "^[0-9a-fA-F]{6}$")
            colors.Push(f)
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
; 支持颜色: weekday_start_end,color1,color2,...;  颜色可选，无则用主题色
; 颜色值必须是 6 位十六进制 RRGGBB（大小写均可），可以 # 开头
WorkDayTasks(baseStart, baseEnd) {
    global Work_TaskTimes
    out := []
    if (Work_TaskTimes = "" || baseEnd - baseStart <= 0)
        return out
    userWDay := (A_WDay == 1) ? 7 : A_WDay - 1
    Loop Parse, Work_TaskTimes, ";" {
        if (A_LoopField = "")
            continue
        ; 分离时间部分和颜色部分 / Split time and color parts
        taskFields := StrSplit(A_LoopField, ",")
        timePart := Trim(taskFields[1])
        taskColors := []
        loop taskFields.Length - 1 {
            c := Trim(taskFields[A_Index + 1])
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
    ; CPU sampling state (function-level, not inside case) / CPU采样状态
    static cpuLastIdle := 0, cpuLastKernel := 0, cpuLastUser := 0
    ; 缓存：避免每秒 fork 子进程 / Cache to avoid spawning child process every second
    static wifiCache := "", wifiCacheTime := 0, diskCache := "", diskCacheTime := 0
    ; WiFi 异步查询状态 / Async Wi-Fi query state
    static wifiPending := false, wifiTmp := A_Temp . "\_wm_wifi.tmp", wifiDone := A_Temp . "\_wm_wifi.done"
    try {
        switch what {
        case "wifi":
            now := A_TickCount
            ; 异步刷新：后台进程写临时文件，后续 tick 收取结果。
            ; 原实现 RunWait 会在 UI 线程阻塞最长 ~1s，造成 bar/边框间歇卡顿。
            ; Async refresh: background process writes a temp file collected on a
            ; later tick — the old RunWait blocked the event loop for up to ~1s.
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
    ExtCtrls := Map()   ; 外部推送部件: 槽位号 → 控件（渐变路径存 ""，经 GradText 更新）
    GradText := Map()   ; 渐变文字
    BgGradBM := 0       ; bar背景渐变
    TaskMarkerBMs := [] ; 任务标记位图句柄（用于释放）
    ; 桌面高亮（仅 cur_color 配置后启用）/ Desktop highlight cells
    DesktopCellCtrls := []       ; 所有动态控件（每轮 UpdateDesktops 销毁重建）
    DesktopCurColor  := Map()    ; 解析后的 cur_color
    DesktopSeg       := {cx:0, cy:0, cw:0, ch:0}
    DesktopLayoutColors := []
    DesktopLayoutMode   := "text"
    DesktopLayoutRounded := "off"
    DesktopLayoutAlign   := "Center"  ; 文字对齐 / text alignment

    ; 系统部件元数据表（UpdateClock + _BuildElements 共用）/ System widget metadata
    static SysWidgets := [
        {ctrl: "WifiCtrl",  key: "wifi",    gradKey: "wifi",      sysFn: "wifi",   label: "WiFi"},
        {ctrl: "BattCtrl",  key: "battery", gradKey: "battery",   sysFn: "battery", label: "Batt"},
        {ctrl: "VolCtrl",   key: "volume",  gradKey: "volume",    sysFn: "volume",  label: "Vol"},
        {ctrl: "DiskCtrl",  key: "disk",    gradKey: "disk",      sysFn: "disk",    label: "Disk"},
        {ctrl: "MemCtrl",   key: "mem",     gradKey: "mem",       sysFn: "mem",     label: "Mem"},
        {ctrl: "CpuCtrl",   key: "cpu",     gradKey: "cpu",       sysFn: "cpu",     label: "CPU"},
    ]

    ; WidgetMeta: 元素名 → 元数据快速索引（供 _BuildElements 使用）
    static WidgetMeta := Map()
    static __InitWidgetMeta() {
        for w in BarInstance.SysWidgets
            BarInstance.WidgetMeta[w.sysFn] := w
    }

    ; -- 构造 / __New --
    __New(mon, pos, offset, barNum := 1) {
        this.Mon := mon, this.Pos := pos, this.Offset := offset
        this.BarNum := barNum
        this.DesktopCellCtrls := []   ; 每实例独立数组
        this.Build()
    }

    ; -- 水平检测 / IsHorizontal --
    IsHorizontal() => (this.Pos = "top" || this.Pos = "bottom")

    ; -- 获取当前bar的布局 / Get this bar's layout Map --
    _MyLayout() {
        global Bar_Cfg
        layout := Bar_Cfg["layout"]
        if layout.Has(this.BarNum)
            return layout[this.BarNum]
        if layout.Has(1)
            return layout[1]
        return Map()
    }

    ; -- 元素跨度解析 / Resolve an element's layout segment --
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
        ; 动态外部槽位（自包含协议，无需 Layout 声明）
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

    ; -- 行高 / _LineHeightForFont (GDI 实测字体避免偏移，可指定字号) --
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
        return NumGet(tm, 0, "Int") + 4  ; tmHeight + padding
    }
    _LineHeight() {
        global Bar_FontSize
        return this._LineHeightForFont(Bar_FontSize)
    }

    ; -- 文字像素宽度 / Measure text width in pixels --
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

    ; -- 统一渐变位图（含圆角）/ Unified gradient bitmap — 委托给全局 MakeGradientBM --
    _GradBgBM(w, h, colors, rounded := "off", radius := 0, fillColor := "", bgOffX := 0, bgOffY := 0) {
        return MakeGradientBM(w, h, colors, rounded, radius, fillColor, this.BgGradBM, bgOffX, bgOffY)
    }

    ; -- 控件选项 / _Opt --
    _Opt(x, y, w, h, align) {
        return Format("x{} y{} w{} h{} BackgroundTrans {}", Round(x), Round(y), Round(w), Round(h), align)
    }

    ; -- 构建 / Build --
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
        ; ---- 扫描 wrap 元素 + 已有推送数据的多行文本：bar 高度必须容纳 ----
        layout := this._MyLayout()
        for elName, seg in layout
            minThick := _BarScanWrapFn(elName, seg, minThick, this)
        ; 动态外部槽位
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
        ; 渐变背景 / Gradient bar background (位图圆角，不经 SetWindowRgn)
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
        ; 纯色背景用 SetWindowRgn（已加 DWM 修复）；渐变背景位图已有圆角无需再设
        ; Solid bg: SetWindowRgn (DWM fix applied); Gradient bg: bitmap already rounded
        if (!pcBg.isGrad)
            RoundWindowEx(g, Bar_Rounded, Bar_Radius, Bar_CornerMode)
        this.UpdateDesktops()
    }

    ; -- 文本/渐变控件统一创建（各元素分支共用的唯一实现）--
    ; -- Canonical text-or-gradient ctrl factory shared by every element branch --
    ; 多色/ bg 模式/ 多行换行 → 走渐变位图路径（GDI DT_WORDBREAK 换行），否则普通 Text 控件
    _AddTextOrGrad(g, el, cx, cy, cw, ch, colors, mode, rounded, txt, align, fontSize := 0, wrapLines := 0) {
        ; wrapLines>0 强制走 GDI 路径（非渐变 Text 控件无法多行换行）
        if (colors.Length > 1 || (colors.Length > 0 && mode = "bg") || wrapLines > 0) {
            useColors := colors
            ; 单色+多行：复制颜色使其通过 TextOnGradient 的 Colors.Length>=2 检查
            if (wrapLines > 0 && colors.Length == 1)
                useColors := [colors[1], colors[1]]
            else if (wrapLines > 0 && colors.Length == 0) {
                ; 无颜色：用主题色做"伪渐变"保证多行渲染
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

    ; -- 构建系统部件控件（由 WidgetMeta 驱动）/ Build a single system widget ctrl ----
    _BuildSysWidget(g, el, cx, cy, cw, ch, colors, mode, rounded, align) {
        ; 惰性初始化 WidgetMeta / Lazy-init WidgetMeta
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

    ; -- 构建元素 / _BuildElements --
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
        ; 外部推送部件 external_N / External push widgets
        for key, _ in layout {
            if RegExMatch(key, "^external_\d+$")
                elements.Push(key)
        }
        ; 动态外部槽位（自包含协议，无需 Layout 声明）
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
                        ; 高亮模式：layoutBg 在此提前创建（与其他 bg 部件相同），桌面标签在 UpdateDesktops 刷新
                        ; Highlight mode: layoutBg created here (same timing as other bg elements)
                        layoutBgStatic := (colors.Length > 0 && mode = "bg")
                        if layoutBgStatic
                            this._AddGradTextCtrl(g, el, cx, cy, cw, ch, colors, mode, rounded, " ", align)
                        else {
                            this.DesktopsCtrl := g.Add("Text", this._Opt(cx, cy, cw, ch, align), "")
                            if (colors.Length = 1)
                                this.DesktopsCtrl.SetFont("c" colors[1])
                        }
                    } else {
                        ; 原逻辑 / Legacy
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
                        ; 外部推送部件：初值取自 Bar_ExternalData（bar 重建后内容保留）
                        ; External widget: initial value from Bar_ExternalData (survives bar rebuild)
                        n := Integer(me[1])
                        txt := Bar_ExternalData.Has(n) ? Bar_ExternalData[n] : ""
                        ; 提取 per-slot 字体大小和换行配置
                        elFS := (seg.HasOwnProp("fontSize") && seg.fontSize > 0) ? seg.fontSize : 0
                        elWL := (seg.HasOwnProp("wrapLines") && seg.wrapLines > 0) ? seg.wrapLines : 0
                        ; 自动检测：文本含换行符但未显式配置 wrap → 自动启用多行
                        if (elWL == 0 && InStr(txt, "`n"))
                            elWL := Max(2, StrSplit(txt, "`n").Length)
                        ; 外部槽位始终强制走 GDI 路径（普通 Text 控件无法后续切换多行）
                        if (elWL == 0)
                            elWL := 1
                        ctrl := this._AddTextOrGrad(g, el, cx, cy, cw, ch, colors, mode, rounded, txt, align, elFS, elWL)
                        ; 渐变路径经 GradText 更新，存 "" 占位 / gradient path updates via GradText
                        this.ExtCtrls[n] := this.GradText.Has(el) ? "" : ctrl
                    }
            }
        }
    }

    ; -- 外部部件刷新（推送驱动，非轮询）/ Refresh external widgets (push-driven) --
    ; slot=0 刷新全部；值未变则跳过 / slot=0 refreshes all; unchanged values skipped
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

    ; -- 渐变文字控件 / _AddGradTextCtrl --
    _AddGradTextCtrl(g, el, cx, cy, cw, ch, colors, mode := "text", rounded := "off", txt := "", align := "Center", fontSize := 0, wrapLines := 0) {
        global Bar_FontSize, Color_Bg
        w := Round(cw), h := Round(ch)
        if (w < 2 || h < 2)
            return
        bgOff := Round(cx)
        useFS := (fontSize > 0) ? fontSize : Bar_FontSize

        ; ===== bg 模式：彩色背景 + Text 叠加（文字透明显示 bar 底色）=====
        if (mode = "bg") {
            ; 圆角用bar底色填充，保持bar背景连续感 / Fill corners with bar bg for seamless look
            hBM := this._GradBgBM(w, h, colors, rounded, 0, C1(Color_Bg))
            if hBM
                g.Add("Picture", Format("x{} y{} w{} h{}", Round(cx), Round(cy), w, h), "HBITMAP:" hBM)
            ; 文字浮于背景上方，背景透明，文字色=bar底色（呈现"挖空"效果）
            tColor := C1(Color_Bg)
            ctrl := g.Add("Text", Format("x{} y{} w{} h{} {} BackgroundTrans c{}"
                , Round(cx), Round(cy), w, h, align, tColor), txt)
            ctrl.SetFont("s" useFS " w600", FontName)
            this.GradText[el] := {colors: colors, w: w, h: h, cx: Round(cx), cy: Round(cy)
                , ctrl: ctrl, oldBM: hBM, mode: mode, rounded: rounded, isSimple: true, align: align
                , fontSize: fontSize, wrapLines: wrapLines}

        ; ===== text 模式：原有渐变文字 bitmap 渲染 =====
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

    ; -- 更新渐变文字 / _UpdateGradText --
    _UpdateGradText(el, newText) {
        global Bar_FontSize, Color_Bg
        if !this.GradText.Has(el)
            return
        gi := this.GradText[el]
        if (gi.w < 2 || gi.h < 2)
            return
        ; 单色bg：直接更新文字 / Solid bg: just update text
        if (gi.HasOwnProp("isSimple") && gi.isSimple) {
            try gi.ctrl.Value := newText
            return
        }
        style := "text"
        if (gi.mode = "bg") {
            style := gi.rounded = "on" ? "bg_rounded" : "bg"
        }
        ; 使用 per-slot 的 fontSize 和 wrapLines（无覆盖时回退全局）
        eFS := (gi.HasOwnProp("fontSize") && gi.fontSize > 0) ? gi.fontSize : Bar_FontSize
        eWL := (gi.HasOwnProp("wrapLines") && gi.wrapLines > 0) ? gi.wrapLines : 0
        ; 自动检测：文本含换行符但未配置 wrap → 自动启用多行渲染
        if (eWL <= 1 && InStr(newText, "`n")) {
            eWL := Max(2, StrSplit(newText, "`n").Length)
            gi.wrapLines := eWL  ; 更新存储值，下次不重复检测
        }
        hBM := TextOnGradient(gi.w, gi.h, gi.colors, newText, eFS, style, FontName, this.BgGradBM, gi.cx, C1(Color_Bg), gi.align, eWL)
        if (!hBM)
            return
        try gi.ctrl.Value := "HBITMAP:" hBM
        if (gi.oldBM)
            DllCall("Gdi32.dll\DeleteObject", "Ptr", gi.oldBM)
        gi.oldBM := hBM
    }

    ; -- 构建进度条 / Build the progress widget (支持渐变) --
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

    ; -- 任务标记 / _BuildTaskMarkers --
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
                    ; 多色渐变
                    hBM := CreateGradient(mkW, taskH, 0, tColors*)
                    this.Gui.Add("Picture", Format("x{} y{} w{} h{}", mkX, useY, mkW, taskH), "HBITMAP:" hBM)
                    this.TaskMarkerBMs.Push(hBM)
                } else {
                    ; 单色 / 主题回退：统一走 CreateGradient
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

    ; -- 桌面更新 / UpdateDesktops --
    UpdateDesktops() {
        global CurrentDesktop, DesktopCount, Desktops, Bar_Cfg, Color_Bg, Color_Active, Bar_FontSize, FontName
        labels := Bar_Cfg["desktop_labels"]
        lft := Bar_Cfg["cur_left"], rgt := Bar_Cfg["cur_right"]
        mode := Bar_Cfg["display_mode"]

        ; ===== 分支 B：当前桌面高亮模式 / per-desktop cells =====
        if (this.DesktopCurColor.HasOwnProp("colors")) {
            seg := this.DesktopSeg
            g := this.Gui
            if (seg.cw < 2)
                return

            ; ========== 1. 销毁上一轮所有控件 / Destroy all previous cells ==========
            loop this.DesktopCellCtrls.Length {
                ctrl := this.DesktopCellCtrls[A_Index]
                if IsObject(ctrl) {
                    try ctrl.Visible := false
                    try ctrl.Value := ""       ; Picture 释放位图引用
                    if (ctrl.HasOwnProp("hBM") && ctrl.hBM)
                        DllCall("Gdi32.dll\DeleteObject", "Ptr", ctrl.hBM)
                    try ctrl.Destroy()
                }
            }
            this.DesktopCellCtrls := []

            ; ========== 2. 计算可见桌面 + 像素宽度 ==========
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

            ; ========== 3. 整体偏移 / Group offset from alignment ==========
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

            ; ========== 4. 桌面标签 + 当前高亮（layoutBg 已在 _BuildElements 创建）==========
            for idx, i in visible {
                w := labelsW[i]
                if (i = CurrentDesktop) {
                    curCellX := x, curCellW := w
                } else {
                    lbl := (i <= labels.Length) ? labels[i] : (i "")
                    if gradientTx {
                        ; 渐变文字 / Gradient text bitmap per label
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

            ; ========== 5. 当前桌面高亮 ==========
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

        ; ===== 分支 A：原逻辑 / legacy single-control mode =====
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

    ; -- 时钟/进度更新 / Update clock & progress --
    ; 渐变模式下每 tick 重建渐变位图至当前填充宽度
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
        ; 系统状态组件（由 SysWidgets 数据表驱动）/ System widgets (driven by SysWidgets table)
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
        ; 渐变进度条 / Gradient progress bar
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
            ; 仅在新位图成功创建后替换旧位图，避免 GDI 泄漏
            if (doUpdate) {
                if (this.ProgOldBM)
                    DllCall("Gdi32.dll\DeleteObject", "Ptr", this.ProgOldBM)
                this.ProgOldBM := newBM
            }
        }
        if IsObject(this.Progress)
            try this.Progress.Value := Integer(pct)
    }

    ; -- 显示/隐藏 / Show, Hide --
    Show()    => (this.Gui ? this.Gui.Show("NoActivate") : 0)
    ; -- 隐藏 / Hide --
    Hide() {
        if IsObject(this.Gui)
            try DllCall("ShowWindow", "Ptr", this.Gui.Hwnd, "Int", 0)
    }
    ; -- 销毁 / Destroy --
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
        ; 任务标记位图 / Task marker bitmaps
        for hBM in this.TaskMarkerBMs
            DllCall("Gdi32.dll\DeleteObject", "Ptr", hBM)
        this.TaskMarkerBMs := []
        ; 桌面控件的 HBITMAP 必须手动释放（GUI 销毁不会自动删 GDI 位图）
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
            ; 强制清理残余桌面控件位图 / Force-clean leftover desktop cell bitmaps
            for ctrl in b.DesktopCellCtrls {
                try {
                    if (ctrl.HasOwnProp("hBM") && ctrl.hBM)
                        DllCall("Gdi32.dll\DeleteObject", "Ptr", ctrl.hBM)
                }
            }
            b.DesktopCellCtrls := []
            ; 清理渐变文字位图 / Clean gradient text bitmaps
            for _el, gi in b.GradText {
                try {
                    if (gi.oldBM)
                        DllCall("Gdi32.dll\DeleteObject", "Ptr", gi.oldBM)
                }
            }
            b.GradText := Map()
            ; 清理进度条位图 / Clean progress bar bitmaps
            if (b.ProgOldBM) {
                try DllCall("Gdi32.dll\DeleteObject", "Ptr", b.ProgOldBM)
                b.ProgOldBM := 0
            }
            if (b.BgGradBM) {
                try DllCall("Gdi32.dll\DeleteObject", "Ptr", b.BgGradBM)
                b.BgGradBM := 0
            }
            ; 销毁 GUI / Destroy GUI window
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

; ---- ApplyPauseOnFullscreen / 全屏暂停 ----
ApplyPauseOnFullscreen() {
    global PauseOnFullscreen
    static wasPaused := false
    if !PauseOnFullscreen {
        if wasPaused {
            Suspend false
            wasPaused := false
        }
        return
    }
    ; 仅检测有 bar 的显示器——无 bar 的显示器上单窗口平铺不应触发暂停
    fullscreen := false
    if IsSet(Bars) {
        for b in Bars {
            if HasFullscreenWindow(b.Mon) {
                fullscreen := true
                break
            }
        }
    }
    if fullscreen && !wasPaused {
        Suspend true
        wasPaused := true
    } else if !fullscreen && wasPaused {
        Suspend false
        wasPaused := false
    }
}

; ---- ToggleBar / 切换显隐 ----
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
        ShowOSD("Unpinned")
    } else {
        AlwaysVisible[hwnd] := true
        PinBorder.Add(hwnd)
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
; 十四、智能平铺 / 14. Smart Tiling
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

; ---- 根据宽高比确定平铺模式 / Determine tile mode by aspect ratio ----
_GetTileMode(W, H) {
    if (H > W)
        return "Vertical"
    if (H != 0 && W / H >= 32/9 - 0.15)
        return "Ultrawide"
    return "Normal"
}

; ---- 显示器平铺唯一入口（TileSmart / WinSelect / WTM 共用）----
; ---- Canonical per-monitor tiling entry (shared by TileSmart / WinSelect / WTM) ----
; gapBase:    基础间隙。TileSmart/WinSelect 传 Tile_Gap；WTM 传 Border_Gap
;             （WTM 需要为边框留空间，与普通平铺间隙语义不同，故各自配置）。
; useDwmComp: 是否叠加 DWM 阴影补偿。TileSmart/WinSelect 为 true（使可视间距一致）；
;             WTM 为 false（其边框贴合 DWM 可视矩形，补偿反而造成双重间距）。
; 返回是否命中用户自定义布局规则 / Returns whether a custom layout rule was applied.
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

; ---- Place one window with gap & bound clamp / 摆放窗口 ----
PlaceWin(hwnd, x, y, w, h) {
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
    try {
        WinRestore(hwnd)
        WinMove(Round(x), Round(y), Round(Max(50, w)), Round(Max(50, h)), hwnd)
    }
}

; ---- Grid tiling / 网格平铺 ----
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

; ---- Normal-aspect tiling / 常规屏平 ----
TileNormal(wins, WL, WT, W, H) {
    n := wins.Length
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

; ---- Vertical-monitor tiling / 竖屏平铺 ----
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

; ---- Ultrawide-monitor tiling / 超宽屏平 ----
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
            if (WinGetTitle(this_id) == "")
                continue
            WinGetPos(,, &w, &h, this_id)
            if (w < 100 || h < 100)
                continue
            if IsExcludedWindow(this_id)
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
            if (WinGetMinMax(hwnd) != -1)
                windows.Push(hwnd)
        }
    }
    return windows
}

; ==============================================================================
; 十五、窗口吸附 / 15. Window Snapping
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
            ; ★ FIX: use visual rect for consistent snapping
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
; 十六、拖拽移动/缩放与方向吸附 / 16. Drag Move / Resize & Directional Snap
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
    ; ★ FIX: use visual rect for snapping, convert back for WinMove
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
        ; 鼠标未动：不做任何窗口操作并让出 CPU（高刷屏下大幅降低占用与延迟）
        ; Cursor idle: skip all work and yield — keeps 120Hz+ drags cheap and responsive
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
    WTM.OnWindowChanged()
}

; ---- Drag-resize handler / 拖拽缩放 ----
DragResizeHandler(*) {
    MouseGetPos(,, &hwnd)
    if !hwnd
        return
    if (WinGetMinMax(hwnd) == 1)
        return

    ; ★ FIX: use visual rect for snapping, convert back for WinMove
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
        ; 鼠标未动：跳过并让出 CPU / Cursor idle: skip & yield
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
            ; ★ v2.6.2: convert visual size back to WinGetPos size
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

; ---- Save layout snapshot / 布局快照 ----
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

; ---- Restore layout snapshot / 布局快照 ----
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
; 十七、WTM 平铺模式 / 17. WTM - Windows Tile Manager (hyprland-like)
; ==============================================================================

; ---- 共享边框绘制辅助（WTM / AllBorders 共用）----
; 获取窗口可视矩形 → 偏移 → 计算圆角 → 调用 Place
_BorderPlaceFrame(borderMap, hwnd) {
    if !GetWindowVisualRect(hwnd, &x, &y, &w, &h)
        return
    o := Border_Offset
    x -= o, y -= o, w += 2*o, h += 2*o
    rad := (Border_Rounded = "on") ? Border_Radius : 0
    borderMap[hwnd].Place(x, y, w, h, Max(2, Border_Thickness), rad, Border_Opacity, Border_Mode, hwnd)
}

; ---- Dynamic tiling mode / 动态平铺 ----
class WTM {
    static Active     := false
    static TileOrder  := []
    static DesktopOrders := Map()   ; 各虚拟桌面独立的平铺顺序 / per-desktop tile order
    static Excluded   := Map()
    static FocusHwnd  := 0
    static BorderMap   := Map()
    static BorderState := Map()
    static _LastSig   := ""
    static _Accum     := 0
    static _LastSigChange   := 0   ; 签名上次变化的时间戳，用于防抖
    static _LastBorderSig   := ""  ; 边框签名：焦点+窗口列表变化时全毁全建
    static TickFn     := ObjBindMethod(WTM, "Tick")

    ; -- 模式切换 / Toggle the mode --
    static Toggle() {
        if this.Active
            this.Deactivate()
        else
            this.Activate()
    }

    ; -- 启用 / Activate --
    static Activate() {
        this.Active      := true
        this.Excluded    := Map()
        this.TileOrder   := []
        this.BorderMap   := Map()
        this.BorderState := Map()
        this._LastSig    := ""
        this._LastSigChange := 0
        this.RebuildOrder()
        this.AutoTile()
        this.RefreshBorder()
        SetTimer(this.TickFn, Border_RefreshMs)
        AllBorders.Suspend()
        ShowOSD("WTM Mode: ON")
    }

    ; -- 停用 / Deactivate --
    ; 边框必须全部清干净，不留幽灵边框 / All borders must be removed — no ghosts
    static Deactivate() {
        this.Active := false
        SetTimer(this.TickFn, 0)
        this.DestroyAllBorders()
        this._LastBorderSig := ""
        this._LastSig := ""
        this.DesktopOrders := Map()
        AllBorders.Rebuild()
        ShowOSD("WTM Mode: OFF")
    }

    ; -- 切换前保存当前桌面的平铺顺序 / Save this desktop's tile order before switching --
    static SaveOrderForDesktop(d) {
        if this.Active
            this.DesktopOrders[d] := this.TileOrder.Clone()
    }

    ; -- 桌面切换处理 / Handle a desktop switch --
    ; 恢复目标桌面已保存的顺序（不再从头重建），保证各桌面布局互相独立
    ; Restores the target desktop's saved order instead of rebuilding from scratch,
    ; so each desktop keeps its own tiling layout across switches.
    static OnDesktopSwitched(target := 0) {
        if !this.Active
            return
        this._LastBorderSig := ""   ; 强制下次 RefreshBorder 全毁全建
        this.DestroyAllBorders()
        if (target && this.DesktopOrders.Has(target))
            this.TileOrder := this.DesktopOrders[target].Clone()
        this.RebuildOrder()      ; 清理失效窗口、追加新窗口（保序）/ prune dead, append new
        this.AutoTile()          ; 按恢复的顺序重铺目标桌面 / re-apply the saved layout
        this._LastSigChange := 0
        this.RefreshBorder()
    }

    ; -- 窗口变更处理 / Handle a window change --
    static OnWindowChanged() {
        if !this.Active
            return
        this.AutoTile()
        this.RefreshBorder()
    }

    ; -- 重建平铺顺序 / Rebuild the tile order --
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
        newOrder := []
        for hwnd in this.TileOrder {
            if alive.Has(hwnd) && WinExist(hwnd) {
                newOrder.Push(hwnd)
                alive.Delete(hwnd)
            }
        }
        for hwnd, _ in alive
            newOrder.Push(hwnd)
        this.TileOrder := newOrder
    }

    ; -- 自动平铺 / Auto-tile all monitors --
    static AutoTile() {
        this.RebuildOrder()
        if (this.TileOrder.Length = 0)
            return
        groups := Map()
        for hwnd in this.TileOrder {
            m := 1
            try m := GetMonitorIndex(hwnd)
            if (m < 1)
                m := 1
            if !groups.Has(m)
                groups[m] := []
            groups[m].Push(hwnd)
        }
        for m, wins in groups
            this._TileMonitor(m, wins)
        this._LastSig := this._Signature()
    }

    ; -- 单显示器平铺 / Tile one monitor --
    ; WTM 用 Border_Gap（为边框留空间）且不加 DWM 补偿，见 TileWindowsOnMonitor 注释
    static _TileMonitor(monIdx, wins) {
        global Border_Gap
        TileWindowsOnMonitor(wins, monIdx, Border_Gap, false)
    }

    ; -- 成员+几何签名 / Membership & geometry signature --
    ; v2.9: 加入量化后的窗口位置/尺寸（32px 粒度），使手动移动或缩放任何托管窗口
    ; 在稳定后也会触发重排（AutoTile 完成后立即刷新签名，平铺本身不会再次触发）。
    ; Includes 32px-quantized geometry so moving/resizing any managed window
    ; re-tiles the monitor once the change settles; AutoTile refreshes the
    ; signature afterwards so tiling itself never re-triggers.
    static _Signature() {
        arr := []
        for hwnd in GetVisibleWindow() {
            if this.Excluded.Has(hwnd)
                continue
            if !IsTilableWindow(hwnd)
                continue
            try {
                if (WinGetMinMax(hwnd) = -1)
                    continue
                WinGetPos(&sx, &sy, &sw, &sh, hwnd)
            } catch {
                continue
            }
            arr.Push((hwnd + 0) . ":" . (sx // 32) . "," . (sy // 32) . "," . (sw // 32) . "," . (sh // 32))
        }
        n := arr.Length
        Loop n {
            i := A_Index
            Loop n - i {
                j := A_Index
                if (StrCompare(arr[j], arr[j+1]) > 0) {
                    t := arr[j], arr[j] := arr[j+1], arr[j+1] := t
                }
            }
        }
        sig := ""
        for v in arr
            sig .= v ";"
        return sig
    }

    ; -- 定时刷新（Alt 按住期间推迟重排，避免组合键过程中误平铺）--
    ; -- Periodic tick (retile deferred while Alt is held, so unfinished
    ;    Alt-chords / desktop switches never trigger a mid-sequence retile) --
    static Tick() {
        global DesktopIsSwitching
        if !this.Active || DesktopIsSwitching
            return
        ; 每 tick 检查签名，窗口开关即时响应 / Check signature every tick for instant response
        if !GetKeyState("Alt", "P") {
            sig := this._Signature()
            if (sig != this._LastSig) {
                this._LastSig := sig
                this._LastSigChange := A_TickCount
            }
            ; 签名稳定 ≥80ms 后执行重排，避免快速关闭多个窗口时的闪烁
            if (this._LastSigChange && A_TickCount - this._LastSigChange >= 80) {
                this._LastSigChange := 0
                sig2 := this._Signature()
                if (sig2 != this._LastSig)
                    this._LastSig := sig2
                this.AutoTile()
            }
        }
        try {
            fh := WinGetID("A")
            if (fh && fh != this.FocusHwnd) {
                this.FocusHwnd := fh
            }
        }
        this.RefreshBorder()
    }

    ; -- 光标移至窗口中心 / Move cursor to a window's center --
    static _MoveCursorToWindow(hwnd) {
        if !hwnd || !WinExist(hwnd)
            return
        try {
            if !GetWindowVisualRect(hwnd, &x, &y, &w, &h)
                WinGetPos(&x, &y, &w, &h, hwnd)
            DllCall("SetCursorPos", "Int", x + w//2, "Int", y + h//2)
        }
    }

    ; -- 方向聚焦 / Focus in a direction --
    static FocusDir(dir) {
        if !this.Active
            return
        this.RebuildOrder()
        if (this.TileOrder.Length = 0)
            return
        cur := this.FocusHwnd ? this.FocusHwnd : this.TileOrder[1]
        target := this._PickNeighbor(cur, dir)
        if target {
            FocusWindowSafely(target)
            this.FocusHwnd := target
            this._MoveCursorToWindow(target)
            this.RefreshBorder()
        }
    }

    ; -- 方向移动/交换 / Move or swap in a direction --
    static MoveDir(dir) {
        if !this.Active
            return
        this.RebuildOrder()
        cur := this.FocusHwnd ? this.FocusHwnd : (this.TileOrder.Length ? this.TileOrder[1] : 0)
        if !cur
            return
        curMon := 1
        try curMon := GetMonitorIndex(cur)

        target := this._PickSwapTarget(cur, dir, curMon)
        if target {
            i1 := this._OrderIndex(cur)
            i2 := this._OrderIndex(target)
            if (i1 && i2) {
                tmp := this.TileOrder[i1]
                this.TileOrder[i1] := this.TileOrder[i2]
                this.TileOrder[i2] := tmp
            }
            this.AutoTile()
            this._MoveCursorToWindow(cur)
            this.RefreshBorder()
            return
        }

        adj := 0
        try adj := this._AdjacentMonitor(curMon, dir)
        if adj {
            this._MoveWindowToMonitor(cur, adj)
            this.AutoTile()
            this._MoveCursorToWindow(cur)
            this.RefreshBorder()
        }
    }

    ; -- 同屏交换目标选取 / Pick the in-monitor swap target --
    ; 与 _PickNeighbor 相同逻辑：欧氏距离最近者优先，无主轴/副轴差异
    ; Same logic as _PickNeighbor: closest by Euclidean distance, no primary/secondary bias
    static _PickSwapTarget(hwnd, dir, monIdx) {
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
            tm := 1
            try tm := GetMonitorIndex(h)
            if (tm != monIdx)
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

    ; -- 跨屏移动 / Relocate a window onto another monitor --
    static _MoveWindowToMonitor(hwnd, monIdx) {
        if !hwnd || !WinExist(hwnd)
            return
        if (monIdx < 1 || monIdx > MonitorGetCount())
            return
        MonitorGetWorkArea(monIdx, &L, &T, &R, &B)
        try {
            WinGetPos(, , &w, &h, hwnd)
            cx := L + (R - L) // 2, cy := T + (B - T) // 2
            WinMove(cx - w // 2, cy - h // 2, , , hwnd)
        }
    }

    ; -- 相邻显示器查找 / Find the adjacent monitor in a direction --
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

    ; -- 关闭聚焦窗口 / Close the focused window --
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
        this.OnWindowChanged()
    }

    ; -- 浮动/置顶排除切换 / Toggle float + pin exclusion --
    ; WTM 模式下窗口热键统一作用于聚焦窗口（而非鼠标下窗口）/ In WTM mode,
    ; window-targeting hotkeys act on the FOCUSED window, not the one under the cursor.
    static TogglePinExclude() {
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

    ; -- 顺序索引查找 / Find a window's order index --
    static _OrderIndex(hwnd) {
        for i, h in this.TileOrder
            if (h = hwnd)
                return i
        return 0
    }

    ; -- 方向邻居选取 / Pick the nearest neighbor in a direction --
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

    ; -- 确保边框存在 / Ensure a border frame exists --
    static EnsureBorder(hwnd) {
        if this.BorderMap.Has(hwnd)
            return
        this.BorderMap[hwnd]   := BorderFrame(Border_UnfocusColor, Border_Opacity)
        this.BorderState[hwnd] := "unfocus"
    }

    ; -- 移除边框 / Remove a border frame --
    static RemoveBorder(hwnd) {
        if !this.BorderMap.Has(hwnd)
            return
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

    ; -- 移除全部边框 + 验证循环 / Destroy all + verify until clean --
    static DestroyAllBorders() {
        ; 第一轮：收集所有边框 HWND 并逐一 DestroyWindow
        ; Round 1: collect all HWNDs and destroy them
        hwnds := []
        for hwnd, bf in this.BorderMap {
            try {
                if IsObject(bf.Gui) && bf.Gui.Hwnd
                    hwnds.Push(bf.Gui.Hwnd)
            }
        }
        for hwnd in hwnds
            try DllCall("User32\DestroyWindow", "Ptr", hwnd)
        this.BorderMap   := Map()
        this.BorderState := Map()

        ; 验证循环：只要还有残留就继续补刀，最多 20 轮
        ; Verify loop: keep killing survivors, up to 20 rounds
        loop 20 {
            survivors := []
            for _, hwnd in hwnds {
                if DllCall("User32\IsWindow", "Ptr", hwnd)
                    survivors.Push(hwnd)
            }
            if (survivors.Length = 0)
                break
            for hwnd in survivors
                try DllCall("User32\DestroyWindow", "Ptr", hwnd)
            Sleep(2)
            hwnds := survivors
        }
    }

    ; -- 边框颜色切换 / Set a border's focus state color --
    static _SetBorderColor(hwnd, state) {
        if !this.BorderMap.Has(hwnd)
            return
        if (this.BorderState.Has(hwnd) && this.BorderState[hwnd] = state)
            return
        col := (state = "focus") ? Border_FocusColor : Border_UnfocusColor
        this.BorderMap[hwnd].SetColor(col)
        this.BorderState[hwnd] := state
    }

    ; -- 全部边框刷新 / Refresh all borders --
    ; 焦点变化或窗口列表变化时全毁全建，杜绝残留颜色/几何缓存不一致。
    ; 纯几何变化（移动/缩放）仍走增量更新路径 / incremental path for pure geometry.
    ; Full teardown + rebuild on focus change or window-list change.
    static RefreshBorder() {
        if !this.Active
            return
        ; 计算签名：焦点 + 窗口列表 + 个数 / Build signature: focus + window list + count
        sig := (this.FocusHwnd ? this.FocusHwnd : 0) . "|"
        for hwnd in this.TileOrder
            sig .= hwnd . ","
        sig .= ":" . this.TileOrder.Length
        if (sig != this._LastBorderSig) {
            this._LastBorderSig := sig
            this.DestroyAllBorders()
            for hwnd in this.TileOrder {
                if !WinExist(hwnd)
                    continue
                if (PinBorder.Map.Has(hwnd) || AlwaysVisible.Has(hwnd))
                    continue
                try {
                    if (WinGetMinMax(hwnd) = -1)
                        continue
                } catch {
                    continue
                }
                this.EnsureBorder(hwnd)
                this._SetBorderColor(hwnd, hwnd = this.FocusHwnd ? "focus" : "unfocus")
                _BorderPlaceFrame(this.BorderMap, hwnd)
            }
            return
        }
        ; 签名未变：仅更新几何（移动/缩放）/ Signature unchanged: geometry-only update
        for hwnd, _ in this.BorderMap.Clone() {
            if !WinExist(hwnd)
                this.RemoveBorder(hwnd)
        }
        for hwnd in this.TileOrder
            this._DrawBorder(hwnd, this.FocusHwnd)
    }

    ; -- 单窗口边框绘制 / Draw one window's border --
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
        this.EnsureBorder(hwnd)
        this._SetBorderColor(hwnd, hwnd = focusH ? "focus" : "unfocus")
        _BorderPlaceFrame(this.BorderMap, hwnd)
    }

    ; -- 拖拽实时边框 / Live border update during drag --
    static DrawOne(hwnd) {
        if (!this.Active || !this.BorderMap.Has(hwnd))
            return
        this._DrawBorder(hwnd, this.FocusHwnd)
    }
}

; ==============================================================================
; 十八、全窗口边框模式 / 18. All-Window Borders Mode
; ==============================================================================

; ---- Borders on every window (defers to WTM) / 全窗口边 ----
class AllBorders {
    static Active  := false
    static Frames  := Map()
    static State   := Map()
    static _Wins   := []
    static _Accum  := 0
    static TimerFn := ObjBindMethod(AllBorders, "Tick")

    ; -- 模式切换 / Toggle --
    static Toggle() {
        if this.Active
            this.Deactivate()
        else
            this.Activate()
    }

    ; -- 启用 / Activate --
    static Activate() {
        this.Active := true
        ShowOSD("All Borders: ON")
        if WTM.Active
            return
        this.Tick()
        SetTimer(this.TimerFn, Border_RefreshMs)
    }

    ; -- 停用 / Deactivate --
    static Deactivate() {
        this.Active := false
        SetTimer(this.TimerFn, 0)
        this.DestroyAll()
        ShowOSD("All Borders: OFF")
    }

    ; -- 重建 / Rebuild from scratch --
    static Rebuild() {
        if !this.Active
            return
        this.DestroyAll()
        if WTM.Active
            return
        this.Tick()
        SetTimer(this.TimerFn, Border_RefreshMs)
    }

    ; -- 挂起（WTM 接管）/ Suspend while WTM owns borders --
    static Suspend() {
        SetTimer(this.TimerFn, 0)
        this.DestroyAll()
    }

    ; -- 全部销毁 / Destroy all frames --
    static DestroyAll() {
        for hwnd, _ in this.Frames.Clone()
            this.Remove(hwnd)
        this.Frames := Map()
        this.State  := Map()
        this._Wins  := []
        this._Accum := 0
    }

    ; -- 移除单个 / Remove one frame --
    static Remove(hwnd) {
        if !this.Frames.Has(hwnd)
            return
        try this.Frames[hwnd].Destroy()
        this.Frames.Delete(hwnd)
        if this.State.Has(hwnd)
            this.State.Delete(hwnd)
    }

    ; -- 确保存在 / Ensure a frame exists --
    static Ensure(hwnd) {
        if this.Frames.Has(hwnd)
            return
        this.Frames[hwnd] := BorderFrame(Border_UnfocusColor, Border_Opacity)
        this.State[hwnd]  := "unfocus"
    }

    ; -- 颜色切换 / Set focus-state color --
    static SetColor(hwnd, state) {
        if !this.Frames.Has(hwnd)
            return
        if (this.State.Has(hwnd) && this.State[hwnd] = state)
            return
        col := (state = "focus") ? Border_FocusColor : Border_UnfocusColor
        this.Frames[hwnd].SetColor(col)
        this.State[hwnd] := state
    }

    ; -- 定时刷新 / Periodic tick --
    static Tick() {
        global DesktopIsSwitching
        if !this.Active || WTM.Active || DesktopIsSwitching
            return
        this._Accum += Border_RefreshMs
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

    ; -- 单窗口边框绘制 / Draw one window's border --
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

    ; -- 拖拽实时边框 / Live border update during drag --
    static DrawOne(hwnd) {
        if (!this.Active || WTM.Active || !this.Frames.Has(hwnd))
            return
        focusH := 0
        try focusH := WinGetID("A")
        this._DrawBorder(hwnd, focusH)
    }
}

; ==============================================================================
; 十九、增强窗口选择模式 / 19. Enhanced Window-Select Mode (WinSelect)
; ==============================================================================
; ---- Window-select mode / 窗口选择 ----
class WinSelect {
    static Active := false
    static Items  := []
    static Locks  := Map()
    static IH     := ""
    static ZOrder := []   ; 进入模式时的层级（上→下）/ z-order on entry (top->bottom)
    static SidebarGui   := ""    ; 侧边栏 GUI / sidebar showing locked-but-absent windows
    static SidebarItems := []    ; 侧边栏显示的字母 / letters currently shown in the sidebar

    ; -- 清理失效锁定 / Purge locks whose window is gone --
    static _CleanLocks() {
        for L, h in this.Locks.Clone() {
            if !WinExist(h)
                this.Locks.Delete(L)
        }
    }

    ; -- 查询窗口的锁定字母 / Locked letter of a window --
    static _LockLetterFor(hwnd) {
        for L, h in this.Locks
            if (h = hwnd)
                return L
        return ""
    }

    ; -- 启动选择模式 / Start the selection mode --
    ; ★ v2.6.3: 可在任何桌面运行（包括空桌面），侧边栏显示其他桌面的锁定窗口
    ; ★ v2.6.3: works on every desktop (including empty ones); sidebar shows locked windows from other desktops
    static Start() {
        global WS_Scale, WS_Letters
        if this.Active {
            this.Cancel()
            return
        }
        this._CleanLocks()
        ; GetVisibleWindow 借助 WinGetList 返回的是 Z 序（上→下）
        ; GetVisibleWindow uses WinGetList which is z-ordered (top->bottom)
        wins := GetVisibleWindow()
        ; 构造当前桌面的可见窗口集合 / Build set of visible HWNDs on this desktop
        visibleSet := Map()
        for hwnd in wins
            visibleSet[hwnd] := true
        ; 构建侧边栏字母列表：锁定的、但在当前桌面不可见的窗口
        ; Build sidebar letters: locked windows NOT visible on the current desktop
        sidebarLetters := []
        for L, hwnd in this.Locks {
            if !visibleSet.Has(hwnd) && WinExist(hwnd)
                sidebarLetters.Push(L)
        }
        ; 既无可见窗口也无侧边栏可显示 / No visible windows AND no sidebar items
        if (wins.Length = 0 && sidebarLetters.Length = 0) {
            ShowOSD("WinSelect: No Windows")
            return
        }
        this.Active := true
        this.Items := []
        this.ZOrder := wins.Clone()   ; 记录进入前层级 / capture z-order
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

        ; 平铺窗口并显示标签（仅当有可见窗口时）/ Tile & label only when visible windows exist
        if (this.Items.Length > 0) {
            tileHwnds := []
            for it in this.Items
                tileHwnds.Push(it.hwnd)
            this._TileForSelect(tileHwnds)

            ; 在平铺后的位置上缩小窗口并显示标签
            ; Shrink each tiled window in place, then show its label
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

        ; 创建侧边栏（如有锁定窗口不在当前桌面）/ Show sidebar for locked-but-absent windows
        if (sidebarLetters.Length > 0)
            this._CreateSidebar(sidebarLetters)

        this._Capture()
    }

    ; -- 为选择模式平铺窗口 / Tile windows for the selection overlay --
    static _TileForSelect(hwnds) {
        global Tile_Gap
        if (hwnds.Length = 0)
            return
        MouseGetPos(&mx, &my)
        mon := GetMonitorIndexAtPoint(mx, my)
        TileWindowsOnMonitor(hwnds, mon, Tile_Gap, true)
    }

    ; -- 字母标签条 / Build one letter label bar --
    static _MakeLabel(it) {
        global WS_BarColor, WS_TextColor, WS_BarHeight, WS_BarWidth, WS_OffsetY
        global WS_FontSize, WS_Opacity, WS_Rounded, WS_Radius, WS_CornerMode
        global Color_Bg, Color_Active
        bg := (WS_BarColor != "") ? WS_BarColor : Color_Bg
        fg := (WS_TextColor != "") ? WS_TextColor : Color_Active
        ; ★ FIX: use visual rect for bar width to match visible window area
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

    ; -- 按键捕获循环 / Modal key-capture loop --
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

    ; -- 完成选择 / Finish: restore all, act on the chosen letter --
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
        ; 还原全部窗口位置与层级（目标窗口随后单独抬升）
        ; Restore all positions & z-order (target is raised separately below)
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

    ; -- 调取锁定窗口到当前桌面 / Bring a locked window to this desktop --
    static _BringToCurrentDesktop(hwnd) {
        _RemoveFromAllDesktops(hwnd)
        try ShowWin(hwnd)
    }

    ; ★ v2.6.3: 创建侧边栏 — 显示其他桌面的锁定窗口字母
    ; ★ v2.6.3: Create sidebar — show letters of locked windows from other desktops
    static _CreateSidebar(sidebarLetters) {
        global WS_Sidebar_FontSize, WS_Sidebar_Width, WS_Sidebar_Position
        global WS_Sidebar_OffsetX, WS_Sidebar_OffsetY
        global WS_Opacity, GUI_Rounded, GUI_CornerRadius
        global Color_Bg, Color_Text, Color_Active
        if (sidebarLetters.Length = 0)
            return false
        this.SidebarItems := sidebarLetters.Clone()
        ; 确定侧边栏位置 / Determine sidebar position
        MouseGetPos(&mx, &my)
        mon := GetMonitorIndexAtPoint(mx, my)
        MonitorGetWorkArea(mon, &mL, &mT, &mR, &mB)
        BarReserve(mon, &mL, &mT, &mR, &mB)
        sw := WS_Sidebar_Width
        sx := (WS_Sidebar_Position = "right")
            ? (mR - sw - WS_Sidebar_OffsetX)
            : (mL + WS_Sidebar_OffsetX)
        sy := mT + WS_Sidebar_OffsetY
        ; 构建 GUI / Build the sidebar GUI
        g := Gui("-Caption +AlwaysOnTop +ToolWindow +Owner -DPIScale")
        g.BackColor := Color_Bg
        g.MarginX := 0, g.MarginY := 0
        ; 标题 / Title
        titleH := Round(WS_Sidebar_FontSize * 2.2)
        g.SetFont("s" WS_Sidebar_FontSize " w700 c" Color_Active, FontName)
        g.Add("Text", "x0 y4 w" sw " h" titleH " Center +0x200 BackgroundTrans", "Locks")
        ; 分隔线 / Separator
        g.Add("Text", "x8 y" (titleH+2) " w" (sw-16) " h1 Background" Color_Active, "")
        ; 字母项 / Letter items
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

    ; ★ v2.6.3: 侧边栏字母点击 / Sidebar letter click handler
    static _SidebarClick(letter, ctl, *) {
        if !this.Active
            return
        ; 停止活跃的 InputHook / Stop the active input hook
        try {
            if IsObject(this.IH)
                this.IH.Stop()
        }
        this._Finish(letter, "")
    }

    ; ★ v2.6.3: 销毁侧边栏 / Destroy sidebar GUI
    static _DestroySidebar() {
        if IsObject(this.SidebarGui) {
            try this.SidebarGui.Destroy()
            this.SidebarGui := ""
        }
        this.SidebarItems := []
    }

    ; -- 还原层级 / Re-apply captured z-order (top->bottom list) --
    static _RestoreZOrder(order) {
        static SWP := 0x1 | 0x2 | 0x10   ; NOSIZE | NOMOVE | NOACTIVATE
        ; 从最底层向最顶层逐个置顶，最终复原相对层级
        ; Push each window to the top of its band from bottom to top
        i := order.Length
        while (i >= 1) {
            h := order[i]
            i--
            if !WinExist(h)
                continue
            insertAfter := 0          ; HWND_TOP
            try {
                if (WinGetExStyle(h) & 0x8)   ; WS_EX_TOPMOST
                    insertAfter := -1          ; HWND_TOPMOST
            }
            try DllCall("SetWindowPos", "Ptr", h, "Ptr", insertAfter
                , "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", SWP)
        }
    }

    ; -- 还原全部并清理标签 / Restore all windows & destroy labels --
    static _RestoreAll() {
        zorder := this.ZOrder
        for it in this.Items {
            if IsObject(it.gui)
                try it.gui.Destroy()
            try {
                if WinExist(it.hwnd) {
                    WinMove(it.x, it.y, it.w, it.h, it.hwnd)
                    ; ★ v2.6.2: re-apply always-on-top if pin is active
                    if PinBorder.Map.Has(it.hwnd)
                        WinSetAlwaysOnTop(1, it.hwnd)
                }
            }
        }
        ; 复原层级（不激活），保持各窗口相对上下层关系
        ; Restore z-order without activating, keeping relative stacking
        if (zorder.Length > 0)
            this._RestoreZOrder(zorder)
        ; ★ v2.6.3: 销毁侧边栏 / destroy sidebar GUI
        this._DestroySidebar()
        this.Items := []
        this.ZOrder := []
        this.Active := false
    }

    ; -- 取消模式 / Cancel the mode --
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
; 二十、剪贴板 / 编辑器 / 终端 / 电源 / 20. Clipboard / Editor / Terminal / Power
; ==============================================================================

; ---- Clipboard-change callback / 剪贴板变 ----
; OnClipboardChange 由系统触发，覆盖一切复制途径（Ctrl+C、右键菜单、程序内 Edit 菜单等）。
; dataType: 1=文本 2=二进制（文件、图像等）
OnClipboardChanged(dataType) {
    ; 防抖：200ms 内重复触发忽略 / Debounce: ignore rapid re-fires
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

; ---- 复制来源是否在排除列表 / Is the copy source app excluded ----
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

; ---- 历史条目分隔头 / History entry header ----
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
    ; 超大内容截断，防止历史文件被单次复制撑爆 / Cap oversized payloads
    if (Clip_MaxChars > 0 && StrLen(txt) > Clip_MaxChars) {
        WMLog("Clipboard entry truncated (" . StrLen(txt) . " -> " . Clip_MaxChars . " chars)", "INFO", "Clipboard")
        txt := SubStr(txt, 1, Clip_MaxChars) . "`r`n[... truncated / 已截断 ...]"
    }
    Content := _ClipEntryHeader() . txt . "`r`n`r`n"
    try FileAppend(Content, Path_OutputFile, "`n")
}

; ---- 记录二进制剪贴板内容信息 / Log binary clipboard content info ----
; 文件复制 → 记录文件路径列表；图像等 → 记录内容类型（不保存数据本身）
RecordClipboardBinary() {
    global Path_OutputFile, Clip_LogBinary, LastClipContent
    if !Clip_LogBinary
        return
    desc := ""
    files := ""
    try files := A_Clipboard   ; CF_HDROP 时 AHK 会给出文件路径文本
    if (files != "") {
        if (files == LastClipContent)
            return
        LastClipContent := files
        desc := "[files / 文件]`r`n" . files
    } else if DllCall("User32\IsClipboardFormatAvailable", "UInt", 2)        ; CF_BITMAP
        desc := "[image / 图像] (bitmap on clipboard, data not saved)"
    else if DllCall("User32\IsClipboardFormatAvailable", "UInt", 8)          ; CF_DIB
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
    ; 渐变背景 / Gradient background
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
; 21. Theme Switching / 二十一主
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
            _ConfigWrite("Theme", nameMap[key], val)
        else if borderMap.Has(key)
            _ConfigWrite("Border", borderMap[key], val)
    }
    _ConfigWrite("General", "ActiveTheme", "custom")
    ShowOSD("Exported -> custom")
    Sleep(400)
    ScriptReload()
}


; ==============================================================================
; 22. Tray Menu & Exit / 二十二托
; ==============================================================================

; ---- Tray menu setup / 托盘菜单 ----
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
; 23. External Eight-Direction Button Scripts / 二十三外
; ==============================================================================

#Include "*i %A_ScriptDir%\Buttons\Top.ahk"
#Include "*i %A_ScriptDir%\Buttons\TopRight.ahk"
#Include "*i %A_ScriptDir%\Buttons\Right.ahk"
#Include "*i %A_ScriptDir%\Buttons\DownRight.ahk"
#Include "*i %A_ScriptDir%\Buttons\Down.ahk"
#Include "*i %A_ScriptDir%\Buttons\DownLeft.ahk"
#Include "*i %A_ScriptDir%\Buttons\Left.ahk"
#Include "*i %A_ScriptDir%\Buttons\TopLeft.ahk"
