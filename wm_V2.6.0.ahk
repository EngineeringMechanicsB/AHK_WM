#Requires AutoHotkey v2.0
#SingleInstance Force
#WinActivateForce

; ==============================================================================
; 一、环境与全局指令 / 1. Environment & Global Directives
; ==============================================================================

global WM_Version := "2.5.3"

SetWorkingDir(A_ScriptDir)
CoordMode("Mouse", "Screen")
SetTitleMatchMode(2)
SetWinDelay(0)
SetControlDelay(0)

; ==============================================================================
; 二、常量与共享状态 / 2. Constants & Shared State
; ==============================================================================

; ---- 主题与界面颜色 / Theme & UI colors ----
global Color_Bg, Color_Text, Color_Active, Color_Task
global Border_Drag_Color, Border_Pin_Color
global PM_Bg, PM_BtnShutdown, PM_BtnSleep, PM_BtnReboot

; ---- 状态栏状态 / Status-bar state ----
global Bar_Height, Bar_Transparent, Bar_FontSize
global Bar_MonitorIdx := 1
global Bar_Visible    := true
global Bar_Gui := "", Bar_LeftText := "", Bar_RightText := "", Bar_Progress := ""
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

; ---- 功能环参数 / Pie-menu parameters ----
global Pie_Size, Pie_Radius, Pie_CenterZone
global Pie_FontSize, Pie_FontSizeActive, Pie_Transparent
global Pie_Config

; ---- 路径与编辑器 / Paths & editor ----
global Path_Button, Path_Output, Path_OutputFile, Path_Vim, Path_Terminal
global Vim_X, Vim_Y, Vim_Width, Vim_Height
global Vim_CurrentPID := 0

; ---- OSD 与工作时间 / OSD & work-time ----
global OSD_Height, OSD_Transparent, OSD_FontSize
global Work_Start, Work_End, Work_WeekendBar, Work_Mode, Work_TaskTimes
global ActiveTheme

; ---- 统一边框模型 / Unified border model ----
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

; ---- 置顶窗口指示条 / Pinned-window indicator ----
global Border_Pin_Thickness, Border_Pin_Offset, Border_Pin_OffsetTop, Border_Pin_Transparent
global Border_Pin_Mode  := "top"
global Border_Pin_Rounded, Border_Pin_Radius

; ---- 边框刷新间隔 / Shared border refresh interval ----
global Border_RefreshMs := 10

; ---- 兼容旧版 WTM 颜色 / Legacy WTM color globals ----
global WTM_BorderFocusColor, WTM_BorderUnfocusColor

; ---- 平铺与窗口排除 / Tiling & window exclusion ----
global CurrentTileGap := 0
global Tile_Gap        := 8
global LayoutRules     := Map()
global Excl_Titles     := []
global Excl_Classes    := []
global Excl_Processes  := []
global Tile_IncludeAlwaysOnTop := true
global TileBound_L := 0, TileBound_T := 0, TileBound_R := 0, TileBound_B := 0
global TileBoundSet := false

; ---- GUI 圆角 / GUI rounding ----
global GUI_Rounded     := "on"
global GUI_CornerRadius := 12
global Help_Rounded, Help_Radius, PM_Rounded, PM_Radius
global OSD_Rounded, OSD_Radius

; ---- 窗口吸附 / Window snapping ----
global Snap_Enable   := true
global Snap_Distance := 12
global Snap_Release  := 8

; ---- 启动延迟警告 / Deferred startup warning ----
global PathWarning := ""

; ---- 帮助与电源菜单尺寸 / Help & power-menu sizing ----
global Help_FontSize := 10, Help_Width := 620, Help_Height := 0, Help_Opacity := 255
global PM_FontSize := 12, PM_Width := 500, PM_Height := 160, PM_Opacity := 255

; ---- 全窗口边框模式 / All-window-borders mode ----
global Color_BorderUnfocus := "555555"

; ---- 虚拟桌面 / Virtual desktops ----
global Desktop_HideMethod := "minimize"
global DesktopFocus := Map()
global CurrentDesktop  := 1
global DesktopCount    := 9
global Desktops        := Map()
global AlwaysVisible   := Map()

; ---- 其他共享状态 / Other shared state ----
global HelpGuiObj    := ""
global PowerMenuObj  := ""
global ConfigDir  := EnvGet("USERPROFILE") . "\.config\AHK_WM"
global ConfigFile := ConfigDir . "\wm_config.ini"
global LastClipContent := ""
global LayoutSnapshot  := Map()
global HK := Map()

; ---- 窗口选择模式配置 / Window-select mode settings ----
global WS_Scale := 0.85
global WS_Letters := "ASDFGHJKLQWERTYUIOPZXCVBNM"
global WS_SizeMap := Map()
global WS_BarColor := "", WS_TextColor := ""
global WS_BarHeight := 28, WS_BarWidth := 0, WS_OffsetY := 8
global WS_FontSize := 14, WS_Opacity := 217
global WS_Rounded := "on", WS_Radius := 10, WS_CornerMode := "top"
global WS_Timeout := 12

; ---- 功能环方向符号 / Pie-menu direction symbols ----
Pie_Config := Map(
    "Top","↑", "TopRight","↗", "Right","→", "DownRight","↘",
    "Down","↓", "DownLeft","↙", "Left","←", "TopLeft","↖", "Center","●"
)

; ---- 内置主题 / Built-in themes ----
global Themes := Map(
    "nord",             Map("Color_Bg","2E3440","Color_Text","D8DEE9","Color_Active","88C0D0","Color_Task","A3BE8C","Border_Drag_Color","88C0D0","Border_Pin_Color","BF616A","PM_Bg","3B4252","PM_BtnShutdown","BF616A","PM_BtnSleep","5E81AC","PM_BtnReboot","D08770","WTM_BorderFocusColor","88C0D0","WTM_BorderUnfocusColor","4C566A"),
    "tokyonight",       Map("Color_Bg","1A1B26","Color_Text","C0CAF5","Color_Active","7AA2F7","Color_Task","9ECE6A","Border_Drag_Color","7AA2F7","Border_Pin_Color","F7768E","PM_Bg","24283B","PM_BtnShutdown","F7768E","PM_BtnSleep","7AA2F7","PM_BtnReboot","E0AF68","WTM_BorderFocusColor","7AA2F7","WTM_BorderUnfocusColor","414868"),
    "dracula",          Map("Color_Bg","282A36","Color_Text","F8F8F2","Color_Active","BD93F9","Color_Task","50FA7B","Border_Drag_Color","8BE9FD","Border_Pin_Color","FF5555","PM_Bg","44475A","PM_BtnShutdown","FF5555","PM_BtnSleep","6272A4","PM_BtnReboot","FFB86C","WTM_BorderFocusColor","BD93F9","WTM_BorderUnfocusColor","44475A"),
    "gruvbox",          Map("Color_Bg","282828","Color_Text","EBDBB2","Color_Active","FABD2F","Color_Task","B8BB26","Border_Drag_Color","83A598","Border_Pin_Color","FB4934","PM_Bg","3C3836","PM_BtnShutdown","FB4934","PM_BtnSleep","458588","PM_BtnReboot","FE8019","WTM_BorderFocusColor","FABD2F","WTM_BorderUnfocusColor","504945"),
    "monokai",          Map("Color_Bg","272822","Color_Text","F8F8F2","Color_Active","A6E22E","Color_Task","FD971F","Border_Drag_Color","66D9EF","Border_Pin_Color","F92672","PM_Bg","3E3D32","PM_BtnShutdown","F92672","PM_BtnSleep","66D9EF","PM_BtnReboot","FD971F","WTM_BorderFocusColor","A6E22E","WTM_BorderUnfocusColor","49483E"),
    "solarized-dark",   Map("Color_Bg","002B36","Color_Text","839496","Color_Active","268BD2","Color_Task","859900","Border_Drag_Color","2AA198","Border_Pin_Color","DC322F","PM_Bg","073642","PM_BtnShutdown","DC322F","PM_BtnSleep","268BD2","PM_BtnReboot","CB4B16","WTM_BorderFocusColor","268BD2","WTM_BorderUnfocusColor","586E75"),
    "solarized-light",  Map("Color_Bg","FDF6E3","Color_Text","657B83","Color_Active","268BD2","Color_Task","859900","Border_Drag_Color","2AA198","Border_Pin_Color","DC322F","PM_Bg","EEE8D5","PM_BtnShutdown","DC322F","PM_BtnSleep","268BD2","PM_BtnReboot","CB4B16","WTM_BorderFocusColor","268BD2","WTM_BorderUnfocusColor","93A1A1"),
    "catppuccin-mocha", Map("Color_Bg","1E1E2E","Color_Text","CDD6F4","Color_Active","CBA6F7","Color_Task","A6E3A1","Border_Drag_Color","89B4FA","Border_Pin_Color","F38BA8","PM_Bg","313244","PM_BtnShutdown","F38BA8","PM_BtnSleep","89B4FA","PM_BtnReboot","FAB387","WTM_BorderFocusColor","CBA6F7","WTM_BorderUnfocusColor","45475A"),
    "catppuccin-latte", Map("Color_Bg","EFF1F5","Color_Text","4C4F69","Color_Active","8839EF","Color_Task","40A02B","Border_Drag_Color","1E66F5","Border_Pin_Color","D20F39","PM_Bg","E6E9EF","PM_BtnShutdown","D20F39","PM_BtnSleep","1E66F5","PM_BtnReboot","FE640B","WTM_BorderFocusColor","8839EF","WTM_BorderUnfocusColor","ACB0BE"),
    "onedark",          Map("Color_Bg","282C34","Color_Text","ABB2BF","Color_Active","61AFEF","Color_Task","98C379","Border_Drag_Color","56B6C2","Border_Pin_Color","E06C75","PM_Bg","3E4452","PM_BtnShutdown","E06C75","PM_BtnSleep","61AFEF","PM_BtnReboot","D19A66","WTM_BorderFocusColor","61AFEF","WTM_BorderUnfocusColor","4B5263"),
    "ayu-dark",         Map("Color_Bg","0A0E14","Color_Text","B3B1AD","Color_Active","FFB454","Color_Task","C2D94C","Border_Drag_Color","59C2FF","Border_Pin_Color","F07178","PM_Bg","131721","PM_BtnShutdown","F07178","PM_BtnSleep","59C2FF","PM_BtnReboot","FF8F40","WTM_BorderFocusColor","FFB454","WTM_BorderUnfocusColor","3D424D"),
    "github-dark",      Map("Color_Bg","0D1117","Color_Text","C9D1D9","Color_Active","58A6FF","Color_Task","3FB950","Border_Drag_Color","58A6FF","Border_Pin_Color","F85149","PM_Bg","161B22","PM_BtnShutdown","F85149","PM_BtnSleep","58A6FF","PM_BtnReboot","D29922","WTM_BorderFocusColor","58A6FF","WTM_BorderUnfocusColor","30363D"),
    "rose-pine",        Map("Color_Bg","191724","Color_Text","E0DEF4","Color_Active","C4A7E7","Color_Task","9CCFD8","Border_Drag_Color","31748F","Border_Pin_Color","EB6F92","PM_Bg","1F1D2E","PM_BtnShutdown","EB6F92","PM_BtnSleep","31748F","PM_BtnReboot","F6C177","WTM_BorderFocusColor","C4A7E7","WTM_BorderUnfocusColor","26233A"),
    "everforest",       Map("Color_Bg","2D353B","Color_Text","D3C6AA","Color_Active","A7C080","Color_Task","DBBC7F","Border_Drag_Color","7FBBB3","Border_Pin_Color","E67E80","PM_Bg","374145","PM_BtnShutdown","E67E80","PM_BtnSleep","7FBBB3","PM_BtnReboot","E69875","WTM_BorderFocusColor","A7C080","WTM_BorderUnfocusColor","4F585E"),
    "kanagawa",         Map("Color_Bg","1F1F28","Color_Text","DCD7BA","Color_Active","7E9CD8","Color_Task","98BB6C","Border_Drag_Color","7FB4CA","Border_Pin_Color","E46876","PM_Bg","2A2A37","PM_BtnShutdown","E46876","PM_BtnSleep","7E9CD8","PM_BtnReboot","FFA066","WTM_BorderFocusColor","7E9CD8","WTM_BorderUnfocusColor","363646"),
    "material-deep",    Map("Color_Bg","263238","Color_Text","EEFFFF","Color_Active","82AAFF","Color_Task","C3E88D","Border_Drag_Color","89DDFF","Border_Pin_Color","F07178","PM_Bg","37474F","PM_BtnShutdown","F07178","PM_BtnSleep","82AAFF","PM_BtnReboot","F78C6C","WTM_BorderFocusColor","82AAFF","WTM_BorderUnfocusColor","546E7A"),
    "nightfox",         Map("Color_Bg","192330","Color_Text","CDCECF","Color_Active","719CD6","Color_Task","81B29A","Border_Drag_Color","719CD6","Border_Pin_Color","C94F6D","PM_Bg","212E3F","PM_BtnShutdown","C94F6D","PM_BtnSleep","719CD6","PM_BtnReboot","F4A261","WTM_BorderFocusColor","719CD6","WTM_BorderUnfocusColor","39506D"),
    "palenight",        Map("Color_Bg","292D3E","Color_Text","A6ACCD","Color_Active","82AAFF","Color_Task","C3E88D","Border_Drag_Color","82AAFF","Border_Pin_Color","FF5370","PM_Bg","343A4F","PM_BtnShutdown","FF5370","PM_BtnSleep","82AAFF","PM_BtnReboot","F78C6C","WTM_BorderFocusColor","82AAFF","WTM_BorderUnfocusColor","444A60"),
    "horizon",          Map("Color_Bg","1C1E26","Color_Text","CBCED0","Color_Active","E95678","Color_Task","29D398","Border_Drag_Color","26BBD9","Border_Pin_Color","E95678","PM_Bg","232530","PM_BtnShutdown","E95678","PM_BtnSleep","26BBD9","PM_BtnReboot","FAB795","WTM_BorderFocusColor","E95678","WTM_BorderUnfocusColor","3D4055"),
    "oxocarbon",        Map("Color_Bg","161616","Color_Text","F2F4F8","Color_Active","82CFFF","Color_Task","42BE65","Border_Drag_Color","82CFFF","Border_Pin_Color","FF7EB6","PM_Bg","262626","PM_BtnShutdown","FF7EB6","PM_BtnSleep","82CFFF","PM_BtnReboot","BE95FF","WTM_BorderFocusColor","82CFFF","WTM_BorderUnfocusColor","393939")
)

; ---- 主题键补全 / Theme key normalization ----
for _tname, _tmap in Themes {
    if !_tmap.Has("Color_BorderUnfocus")
        _tmap["Color_BorderUnfocus"] := _tmap.Has("WTM_BorderUnfocusColor") ? _tmap["WTM_BorderUnfocusColor"] : "555555"
    if !_tmap.Has("Border_FocusColor")
        _tmap["Border_FocusColor"] := _tmap.Has("WTM_BorderFocusColor") ? _tmap["WTM_BorderFocusColor"]
                                    : (_tmap.Has("Border_Drag_Color") ? _tmap["Border_Drag_Color"] : "A020F0")
    if !_tmap.Has("Border_UnfocusColor")
        _tmap["Border_UnfocusColor"] := _tmap.Has("WTM_BorderUnfocusColor") ? _tmap["WTM_BorderUnfocusColor"] : "555555"
}

; ==============================================================================
; 三、通用工具函数 / 3. Utility Functions
; ==============================================================================

; ---- 百分比换算 / Percent-to-unit scaling ----
Pct2Alpha(p) => Round(Max(0, Min(100, p+0)) * 255 / 100)

; ---- 主屏工作区尺寸 / Primary work-area dimensions ----
GetPrimaryDim(&pw, &ph) {
    MonitorGetWorkArea(MonitorGetPrimary(), &l, &t, &r, &b)
    pw := r - l, ph := b - t
}

; ---- 百分比转像素（高）/ Percent to pixels (height) ----
Pct2PxH(p)   {
    GetPrimaryDim(&pw, &ph)
    return Round(p * ph / 100)
}

; ---- 百分比转像素（宽）/ Percent to pixels (width) ----
Pct2PxW(p)   {
    GetPrimaryDim(&pw, &ph)
    return Round(p * pw / 100)
}

; ---- 百分比转像素（短边）/ Percent to pixels (min side) ----
Pct2PxMin(p) {
    GetPrimaryDim(&pw, &ph)
    return Round(p * Min(pw, ph) / 100)
}

; ---- 百分比转边框厚度 / Percent to border thickness ----
Pct2Border(p) => Round(Max(0, Min(100, p+0)) * 20 / 100)

; ---- 容错整数解析 / Tolerant integer parse ----
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

; ---- 日志全局状态 / Logging state ----
global WM_LogFile := ""
global WM_LogSeen := Map()

; ---- 静默文件日志 / Silent file log ----
WMLog(msg, level := "INFO") {
    global ConfigDir, WM_LogFile
    if (WM_LogFile = "")
        WM_LogFile := ConfigDir . "\wm.log"
    try FileAppend(FormatTime(, "yyyy-MM-dd HH:mm:ss") . "  [" . level . "]  " . msg . "`r`n"
                 , WM_LogFile, "UTF-8")
}

; ---- 异常格式化 / Format a thrown value into one diagnostic string ----
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

; ---- 异常日志（去重防刷屏）/ Log a fault once per distinct message ----
WMLogErr(context, err) {
    global WM_LogSeen
    key := context . "|" . (IsObject(err) ? err.Message : err)
    if WM_LogSeen.Has(key) {
        WM_LogSeen[key] += 1
        return
    }
    WM_LogSeen[key] := 1
    WMLog(WMFormatErr(context, err), "ERROR")
}

; ---- 故障隔离执行 / Run fn() with fault isolation & logging ----
WMGuard(context, fn) {
    try {
        fn()
        return true
    } catch Error as e {
        WMLogErr(context, e)
        return false
    }
}

; ---- GUI 圆角（全局设置）/ Rounded corners using global [GUI] settings ----
RoundWindow(guiOrHwnd) {
    global GUI_Rounded, GUI_CornerRadius
    RoundWindowEx(guiOrHwnd, GUI_Rounded, GUI_CornerRadius)
}

; ---- GUI 圆角（独立参数）/ Rounded corners with per-GUI overrides ----
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

; ---- 排除列表拆分 / Split ';'-separated exclusion list ----
SplitExcludeList(str) {
    out := []
    for part in StrSplit(str, ";") {
        part := Trim(part)
        if (part != "")
            out.Push(part)
    }
    return out
}

; ---- 标题规则匹配 / Title rule matching (contains | re: | =) ----
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

; ---- 窗口排除判定 / Window exclusion check ----
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

; ---- 布局轴解析 / Parse one layout axis token ----
ParseAxis(tok) {
    tok := Trim(tok)
    if (tok = "")
        throw Error("empty axis")
    if (tok = "1")
        return {lo: 0.0, hi: 1.0}
    if RegExMatch(tok, "^\((\d+)\s*-\s*(\d+)\)/(\d+)$", &m) {
        a := Integer(m[1]), c := Integer(m[2]), b := Integer(m[3])
        if (b <= 0 || a < 1 || c < 1 || a > c || c > b)
            throw Error("bad range axis: " tok)
        return {lo: (a - 1) / b, hi: c / b}
    }
    if RegExMatch(tok, "^(\d+)/(\d+)$", &m) {
        a := Integer(m[1]), b := Integer(m[2])
        if (b <= 0 || a < 1 || a > b)
            throw Error("bad axis: " tok)
        return {lo: (a - 1) / b, hi: a / b}
    }
    throw Error("unrecognized axis: " tok)
}

; ---- 自定义平铺规则解析 / Parse custom tiling rules ----
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

; ---- 自定义布局查询 / Resolve custom rules for monitor + count ----
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

; ---- 自定义布局应用 / Apply a matching custom layout ----
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

; ---- 热键记法转换 / Natural hotkey notation -> AHK notation ----
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

; ---- 热键美化显示 / Prettify hotkey for display ----
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

; ---- 修饰键前缀转换 / Modifier-only prefix normalization ----
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

; ---- DWM 可视矩形 / DWM visible rect ----
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

; ---- 坐标所在显示器 / Monitor index at a point ----
GetMonitorIndexAtPoint(x, y) {
    loop MonitorGetCount() {
        MonitorGet(A_Index, &mL, &mT, &mR, &mB)
        if (x >= mL && x < mR && y >= mT && y < mB)
            return A_Index
    }
    return 1
}

; ---- 窗口所在显示器 / Monitor index of a window ----
GetMonitorIndex(hwnd := 0) {
    if !hwnd || !WinExist(hwnd) {
        MouseGetPos(&mx, &my)
        return GetMonitorIndexAtPoint(mx, my)
    }
    WinGetPos(&wx, &wy, &ww, &wh, hwnd)
    return GetMonitorIndexAtPoint(wx + ww/2, wy + wh/2)
}

; ---- Alt 菜单屏蔽 / Mask the Alt key-up menu activation ----
MaskAltMenu() {
    if GetKeyState("Alt", "P")
        try Send("{Blind}{vkE8}")
}

; ---- 可靠窗口激活 / Reliable window activation (Alt-held safe) ----
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

; ==============================================================================
; 四、启动流程 / 4. Startup Sequence
; ==============================================================================

; ---- 全局错误回调注册 / Global error sink registration ----
OnError(WM_OnError)

; ---- 未处理错误回调 / Unhandled-error handler ----
WM_OnError(err, mode) {
    WMLogErr("Unhandled runtime error (" . mode . ")", err)
    return true
}

isFirstRun := !FileExist(ConfigFile)

LoadOrInitConfig()

Loop DesktopCount
    Desktops[A_Index] := []

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

; ---- 启动警告弹窗 / Deferred startup warning popup ----
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

; ---- 单条热键注册 / Register one configured hotkey ----
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

; ---- 全部热键注册 / Register all hotkeys ----
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

    try Hotkey("~LButton & RButton", (*) => Send("^c"))
    try Hotkey("~RButton & LButton", (*) => Send("^c"))

    RegHotkey("LaunchTerminal", LaunchTerminal)
    RegHotkey("EditFile",       OpenWithVim)
    RegHotkey("PowerMenu",      ShowPowerMenu)

    RegHotkey("SnapLeft",  SnapWindow.Bind("Left"))
    RegHotkey("SnapRight", SnapWindow.Bind("Right"))
    RegHotkey("SnapUp",    SnapWindow.Bind("Up"))
    RegHotkey("SnapDown",  SnapWindow.Bind("Down"))

    RegHotkey("SaveLayout",    SaveLayout)
    RegHotkey("RestoreLayout", RestoreLayout)

    RegHotkey("Reload", (*) => Reload())
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

; ---- 功能环松开执行（Space）/ Pie-menu execute on Space release ----
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

; ---- 置顶切换分发 / Toggle-top dispatch (WTM-aware) ----
ToggleTopDispatch(*) {
    if WTM.Active
        WTM.TogglePinExclude()
    else
        ToggleTopUnderMouse()
}

; ---- 关闭窗口分发 / Close-window dispatch (WTM-aware) ----
CloseWindowDispatch(*) {
    if WTM.Active
        WTM.CloseFocused()
    else
        CloseWindowUnderMouse()
}

; ==============================================================================
; 六、配置生成与迁移 / 6. Configuration Generation & Migration
; ==============================================================================

; ---- 配置读取（含旧版回退）/ Config read with legacy fallbacks ----
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

; ---- 自定义项解析 / Parse unified custom_items list ----
ParseCustomItems(itemsRaw, iconRaw := "", textRaw := "") {
    out := []
    if (Trim(itemsRaw) != "") {
        for part in StrSplit(itemsRaw, ";") {
            part := Trim(part)
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

; ---- 旧版配置结构迁移 / Migrate legacy [section] layout ----
MigrateLegacyConfig() {
    global ConfigFile
    miss := "__WM_MISSING__"
    isLegacy := (IniRead(ConfigFile, "Colors",    "Background", miss) != miss)
             || (IniRead(ConfigFile, "StatusBar", "HeightPct",  miss) != miss)
             || (IniRead(ConfigFile, "Layout",    "Gap",        miss) != miss)
             || (IniRead(ConfigFile, "Desktops",  "Count",      miss) != miss)
             || (IniRead(ConfigFile, "VimLayout", "XPct",       miss) != miss)
    if !isLegacy
        return

    try FileCopy(ConfigFile, ConfigFile . ".bak", true)

    moves := [
        ["Theme","Background","Colors","Background"],
        ["Theme","Text","Colors","Text"],
        ["Theme","Active","Colors","Active"],
        ["Theme","Task","Colors","Task"],
        ["Theme","BorderDrag","Colors","BorderDrag"],
        ["Theme","BorderPin","Colors","BorderPin"],
        ["Theme","BorderUnfocus","Colors","BorderUnfocus"],
        ["Theme","PowerMenuBg","Colors","PowerMenuBg"],
        ["Theme","PowerBtnShutdown","Colors","PowerBtnShutdown"],
        ["Theme","PowerBtnSleep","Colors","PowerBtnSleep"],
        ["Theme","PowerBtnReboot","Colors","PowerBtnReboot"],
        ["Bar","HeightPct","StatusBar","HeightPct"],
        ["Bar","Opacity","StatusBar","Opacity"],
        ["Bar","FontSize","StatusBar","FontSize"],
        ["Bar","MonitorIdx","StatusBar","MonitorIdx"],
        ["Border","DragEnable","BorderDrag","Enable"],
        ["Border","DragThickness","BorderDrag","Thickness"],
        ["Border","DragOffset","BorderDrag","Offset"],
        ["Border","DragOffsetTop","BorderDrag","OffsetTop"],
        ["Border","DragOpacity","BorderDrag","Opacity"],
        ["Border","DragRounded","BorderDrag","RoundedCorners"],
        ["Border","DragRadius","BorderDrag","CornerRadius"],
        ["Border","PinThickness","BorderPin","Thickness"],
        ["Border","PinOffset","BorderPin","Offset"],
        ["Border","PinOffsetTop","BorderPin","OffsetTop"],
        ["Border","PinOpacity","BorderPin","Opacity"],
        ["Tiling","Gap","Layout","Gap"],
        ["Tiling","Rules","Layout","Rules"],
        ["GUI","HelpFontSize","HelpMenu","FontSize"],
        ["GUI","HelpWidth","HelpMenu","Width"],
        ["GUI","HelpHeight","HelpMenu","Height"],
        ["GUI","HelpOpacity","HelpMenu","Opacity"],
        ["GUI","HelpRounded","HelpMenu","RoundedCorners"],
        ["GUI","HelpRadius","HelpMenu","CornerRadius"],
        ["GUI","PowerFontSize","PowerMenu","FontSize"],
        ["GUI","PowerWidth","PowerMenu","Width"],
        ["GUI","PowerHeight","PowerMenu","Height"],
        ["GUI","PowerOpacity","PowerMenu","Opacity"],
        ["GUI","PowerRounded","PowerMenu","RoundedCorners"],
        ["GUI","PowerRadius","PowerMenu","CornerRadius"],
        ["GUI","OSDPositionPct","OSD","PositionPct"],
        ["GUI","OSDOpacity","OSD","Opacity"],
        ["GUI","OSDFontSize","OSD","FontSize"],
        ["GUI","OSDRounded","OSD","RoundedCorners"],
        ["GUI","OSDRadius","OSD","CornerRadius"],
        ["Desktop","Count","Desktops","Count"],
        ["Desktop","HideMethod","Desktops","HideMethod"],
        ["Paths","EditorXPct","VimLayout","XPct"],
        ["Paths","EditorYPct","VimLayout","YPct"],
        ["Paths","EditorWidthPct","VimLayout","WidthPct"],
        ["Paths","EditorHeightPct","VimLayout","HeightPct"]
    ]
    for m in moves {
        v := IniRead(ConfigFile, m[3], m[4], miss)
        if (v != miss && IniRead(ConfigFile, m[1], m[2], miss) = miss)
            try IniWrite(v, ConfigFile, m[1], m[2])
    }

    if (IniRead(ConfigFile, "Bar", "custom_items", miss) = miss) {
        icon := IniRead(ConfigFile, "Bar", "custom_icon", "")
        text := IniRead(ConfigFile, "Bar", "custom_text", "")
        merged := ""
        if (Trim(icon) != "")
            merged := icon
        if (Trim(text) != "")
            merged := (merged = "" ? text : merged ";" text)
        if (merged != "")
            try IniWrite(merged, ConfigFile, "Bar", "custom_items")
    }
    try IniDelete(ConfigFile, "Bar", "custom_icon")
    try IniDelete(ConfigFile, "Bar", "custom_text")

    for sec in ["Colors","StatusBar","BorderDrag","BorderPin","Layout","HelpMenu","PowerMenu","OSD","Desktops","VimLayout"]
        try IniDelete(ConfigFile, sec)
}

EnsureConfigEncoding() {
    global ConfigFile
    if !FileExist(ConfigFile)
        return
    buf := ""
    try buf := FileRead(ConfigFile, "RAW")
    if (!IsObject(buf) || buf.Size < 3)
        return
    b1 := NumGet(buf, 0, "UChar"), b2 := NumGet(buf, 1, "UChar"), b3 := NumGet(buf, 2, "UChar")
    if (b1 = 0xFF && b2 = 0xFE)
        return
    if !(b1 = 0xEF && b2 = 0xBB && b3 = 0xBF)
        return
    try {
        txt := FileRead(ConfigFile, "UTF-8")
        FileCopy(ConfigFile, ConfigFile . ".enc.bak", true)
        FileDelete(ConfigFile)
        FileAppend(txt, ConfigFile, "UTF-16")
        WMLog("Config converted UTF-8 -> UTF-16 for full Unicode (Chinese) support")
    } catch Error as e {
        WMLogErr("EnsureConfigEncoding", e)
    }
}

; ==============================================================================
; 七、配置读取与解析 / 7. Configuration Loading & Parsing
; ==============================================================================

; ---- 配置加载（缺失时生成默认）/ Load config, creating defaults when missing ----
LoadOrInitConfig() {
    global

    if !DirExist(ConfigDir) {
        try DirCreate(ConfigDir)
        catch Error as e {
            MsgBox("Failed to create config directory:`n" . ConfigDir . "`n`n" . e.Message)
            ExitApp
        }
    }

    if !FileExist(ConfigFile) {
        DefaultIni := "
        (
;==========================================================================
; AHK WM 配置文件 / AHK WM Configuration
;==========================================================================

[General]
; 主题名称 / Theme name. 可选 / built-in examples:
; custom, nord, tokyonight, dracula, gruvbox, monokai, solarized-dark,
; solarized-light, catppuccin-mocha, catppuccin-latte, onedark, ayu-dark,
; github-dark, rose-pine, everforest, kanagawa, material-deep, nightfox,
; palenight, horizon, oxocarbon.
ActiveTheme=custom

[Theme]
; 十六进制颜色，不带 '#' / Hex colors without '#'.
Background=0e050f
Text=e5e9f0
Active=744da9
Task=CF8DC9
BorderDrag=A020F0
BorderPin=FF5555
; 非聚焦窗口边框色（全窗口边框模式）/ Unfocused border color (all-borders mode).
BorderUnfocus=666666
PowerMenuBg=2E3440
PowerBtnShutdown=B48EAD
PowerBtnSleep=5E81AC
PowerBtnReboot=BF616A

[Paths]
; 八方向按钮脚本目录（相对脚本目录或绝对路径）。
; Folder of the eight directional button scripts (relative or absolute).
ButtonDir=Buttons
; 剪贴板历史输出目录 / Directory for the clipboard-history file.
OutputDir=%OUTPUTDIR%
; 剪贴板历史文件：纯文件名写入 OutputDir，绝对路径则按原样使用。
; Clipboard-history file: bare name goes inside OutputDir; absolute path used as-is.
OutputFile=CB.txt
; 编辑器 / 终端程序 / Editor and terminal executables.
VimPath=C:\Windows\system32\notepad.exe
TerminalExe=C:\Windows\system32\cmd.exe
; 编辑器窗口位置与大小（屏幕百分比）/ Editor geometry in screen percent.
EditorXPct=20
EditorYPct=0
EditorWidthPct=52
EditorHeightPct=74

[Desktop]
; 虚拟桌面数量 1-9 / Virtual desktop count: 1-9.
Count=9
; 非当前桌面窗口的处理方式 / Inactive-desktop handling: minimize | hide
HideMethod=minimize

[Bar]
; 状态栏几何 / Status-bar geometry.
HeightPct=3
Opacity=78
FontSize=10
MonitorIdx=1
; 组件开关 / Widget visibility.
desktops=true
time=true
date=true
progress=true
; 时间日期格式（AutoHotkey FormatTime）/ FormatTime patterns.
time_format=HH:mm
date_format=yyyy-MM-dd
; 自定义内容（支持中文/图标/emoji），';' 分隔，按顺序以 custom_1..n 引用。
; Custom items (Chinese / icons / emoji supported), ';'-separated, custom_1..n.
custom_items=自定义文本 Edit Configuration file to hide
; 桌面名称（支持中文），逗号分隔；数量不符时回退为数字。
; Comma-separated desktop labels (Chinese supported); falls back to numbers.
desktop_labels=Work,Net,Game
; 当前桌面标记 / Current desktop label wrapper.
current_desktop_left=[
current_desktop_right=]
; 桌面显示模式 / Desktop display: all | current | occupied.
desktop_display_mode=all
; 位置（top|bottom）与距屏幕边缘像素偏移 / Bar edge and pixel offset.
position=top
offset=0
; 状态栏左右边距（距显示器左右边框像素）/ Bar left/right margin from monitor edges (px).
margin_left=0
margin_right=0
; 多栏配置 / Multi-bar format: M:pos:offset;...  M=显示器序号或 '*'.
; 例 / Example: instances=1:top:0;2:bottom:8
instances=
; 元素布局 / Element layout: element:span;...  Span 使用 [Tiling] 分数语法。
; 可用元素 / Elements: desktops, time, date, progress, custom_1..n.
layout=custom_1:(2-5)/10;desktops:(1-3)/20;date:(18-19)/20;time:20/20
; 当前桌面存在全屏窗口时自动隐藏状态栏 / Hide while a fullscreen window exists.
AutoHideOnFullscreen=off
; 圆角与方向 / Rounding. CornerMode: all | top | bottom.
Rounded=on
CornerRadius=10
CornerMode=bottom

[Border]
; 所有边框共用的刷新间隔（毫秒）/ Shared border refresh interval (ms).
RefreshMs=10
; 拖拽/聚焦边框总开关 / Master switch for the drag/focus border.
Enable=on
; 边框显示模式 / Mode: top (仅顶边) | full (四边).
Mode=full
; 聚焦/非聚焦窗口颜色 / Focused & unfocused colors.
FocusColor=A020F0
UnfocusColor=555555
; 厚度 / 内缩 / 不透明度（0-100）/ Thickness, insets, opacity (0-100).
Thickness=15
Offset=0
OffsetTop=5
Opacity=80
; 圆角 / Rounded corners + radius (px).
RoundedCorners=on
Radius=10
; WTM 平铺间隙（像素，可为负）/ WTM tiling gap (px, may be negative).
Gap=10
; WTM 调整步长（保留）/ WTM resize step (reserved).
SizeStep=3
; 置顶窗口指示条 / Pinned-window indicator. Mode: top | full.
PinMode=top
PinThickness=10
PinOffset=0
PinOffsetTop=5
PinOpacity=78

[Tiling]
; 智能平铺间隙（像素，可为负）/ Smart tiling gap in pixels (may be negative).
Gap=-15
; 置顶窗口是否参与平铺 / Whether always-on-top windows take part in tiling.
TileAlwaysOnTop=off
; 自定义平铺规则 / Custom tiling rules: M,N,I,X,Y;...
; M=显示器序号或 '*'，N=窗口数，I=窗口序号，X/Y=区域跨度
; (1=整个区域, a/b=单段, (a-c)/b=多段)。优先级：指定显示器 > '*' > 内置默认。
; M=monitor or '*', N=window count, I=window index, X/Y=span
; (1=full, a/b=segment, (a-c)/b=multi-segment). Exact monitor > '*' > default.
; eg:
; 1,3,1,(1-2)/3,1;1,3,2,3/3,1/2;1,3,2,3/3,2/2;
; │ │ │ └──┬──┘ │
; │ │ │    │    └─ Full screen height (100%)
; │ │ │    └─ Occupies columns 1-2 out of 3
; │ │ └─ Window #1
; │ └─ Applies when there are 3 windows
; └─ Desktop #1
; 
; Layout visualization:
; 
; +-----------+-----------+-----------+
; |                       |           |
; |                       |           |
; |                       | Window #2 |
; |                       |           |
; |       Window #1       |-----------|
; |                       |           |
; |                       | Window #3 |
; |                       |           |
; |                       |           |
; +-----------+-----------+-----------+
;

Rules=1,3,1,1/2,1;1,3,2,2/2,1/2;1,3,3,2/2,2/2;1,5,1,(2-4)/5,1;1,5,2,1/5,1/2;1,5,3,1/5,2/2;1,5,4,5/5,(1-2)/3;1,5,5,5/5,3/3;

[Snapping]
; 拖拽时的磁性吸附 / Magnetic snapping while dragging / resizing.
Enable=off
; 触发半径与间隙（像素，可为负）/ Trigger radius and gap in pixels.
Distance=-15
; 脱离吸附所需位移（像素）/ Pixels past the snap point before release.
Release=5

[PieMenu]
; 功能环尺寸、中心死区、透明度与字号 / Radial menu size, dead zone, opacity, fonts.
SizePct=28
CenterZonePct=27
Opacity=78
FontSize=14
FontSizeActive=22

[GUI]
; 全局 GUI 圆角默认值 / Global GUI rounding defaults.
RoundedCorners=on
CornerRadius=12
; 帮助菜单（Height=0 自动）/ 电源菜单 / OSD。
; Help menu (Height=0 = auto), power menu, on-screen display.
HelpFontSize=10
HelpWidth=620
HelpHeight=0
HelpOpacity=255
PowerFontSize=12
PowerWidth=500
PowerHeight=160
PowerOpacity=255
OSDPositionPct=80
OSDOpacity=78
OSDFontSize=20

[WorkTime]
; 工作时间 / 全天进度条 / WorkTime / AllDay progress.
Mode=off
WeekendBar=off
; 开始/结束时间，格式 HHMM / WorkStart / WorkEnd format: HHMM.
WorkStart=0900
WorkEnd=1745
; 任务时段 / TaskTimes format: Weekday_Start_End;...  Weekday 1=Mon..7=Sun.
TaskTimes=1_1200_1300;2_1200_1300;3_1200_1300;4_1200_1300;5_1200_1300;6_1200_1300;7_1200_1300;2_1700_1745;3_0900_0920;

[Exclude]
; 匹配的窗口不参与平铺 / WTM / Matching windows are ignored by tiling / WTM.
; 标题：默认包含匹配；re:xxx 正则；=xxx 精确 / Title: contains | re: | =.
Titles=Picture-in-Picture
; 类名：精确、不区分大小写 / Class name: exact, case-insensitive.
Classes=
; 进程名：精确，如 notepad.exe / Process exe name: exact.
Processes=

[WinSelect]
; ---- 增强窗口选择模式 / Enhanced window-select mode ----
; 进入模式时窗口缩放比例（1.0 原始大小，0.8 缩至 80%）。
; Scale ratio while the mode is active (1.0 = original, 0.8 = 80%).
ScaleRatio=0.85
; 字母分配顺序 / Letter pool used for window labels.
Letters=ASDFGHJKLQWERTYUIOPZXCVBNM
; 数字尺寸映射：先按数字再按字母时选中窗口的尺寸。N:比例 或 N:宽x高。
; Numeric size mapping (digit pressed before the letter): N:ratio or N:WxH.
; 例 / e.g. 1:0.8;2:1.5;3:1920x1080
SizeMap=1:0.5;2:0.8;3:1.2;9:1920x1080
; 标签条颜色（留空跟随主题 Background/Active）/ Label bar colors (empty = theme).
BarColor=
TextColor=
; 标签条高度（像素）与宽度（0 = 与窗口同宽）/ Bar height; width (0 = window width).
Height=28
Width=0
; 标签条相对窗口顶部的向上偏移（像素）/ Upward offset above the window (px).
OffsetY=8
; 标签字号 / Label font size.
FontSize=14
; 不透明度 0-100 / Opacity 0-100.
Opacity=85
; 圆角与方向 / Rounding. CornerMode: all | top | bottom.
Rounded=on
CornerRadius=10
CornerMode=top
; 无按键自动退出秒数（0 = 不超时）/ Auto-exit seconds (0 = never).
Timeout=12

;--------------------------------------------------------------------------
; 热键：使用自然名称并以 '+' 连接 / Hotkeys - natural names joined by '+':
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
; 全窗口边框（测试功能）/ Border on every window (under testing).
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

; 增强窗口选择模式 / Enhanced window-select mode.
WinSelect=Alt+S

; WTM 模式（测试功能）/ WTM mode (under testing).
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

        DefaultIni := StrReplace(DefaultIni, "%OUTPUTDIR%", A_MyDocuments)
        try {
            FileAppend(DefaultIni, ConfigFile, "UTF-16")
        } catch Error as e {
            MsgBox("Failed to create config file: " . e.Message)
            ExitApp
        }
    }

    EnsureConfigEncoding()

    MigrateLegacyConfig()

    ActiveTheme := IniRead(ConfigFile, "General", "ActiveTheme", "custom")

    Color_Bg          := CfgRead("Theme", "Background",       "0e050f", ["Colors","Background"])
    Color_Text        := CfgRead("Theme", "Text",             "744da9", ["Colors","Text"])
    Color_Active      := CfgRead("Theme", "Active",           "744da9", ["Colors","Active"])
    Color_Task        := CfgRead("Theme", "Task",             "CF8DC9", ["Colors","Task"])
    Border_Drag_Color := CfgRead("Theme", "BorderDrag",       "A020F0", ["Colors","BorderDrag"])
    Border_Pin_Color  := CfgRead("Theme", "BorderPin",        "FF5555", ["Colors","BorderPin"])
    PM_Bg             := CfgRead("Theme", "PowerMenuBg",      "2E3440", ["Colors","PowerMenuBg"])
    PM_BtnShutdown    := CfgRead("Theme", "PowerBtnShutdown", "B48EAD", ["Colors","PowerBtnShutdown"])
    PM_BtnSleep       := CfgRead("Theme", "PowerBtnSleep",    "5E81AC", ["Colors","PowerBtnSleep"])
    PM_BtnReboot      := CfgRead("Theme", "PowerBtnReboot",   "BF616A", ["Colors","PowerBtnReboot"])
    Color_BorderUnfocus := CfgRead("Theme", "BorderUnfocus",  "555555", ["Colors","BorderUnfocus"])

    Bar_Height       := Pct2PxH(Integer(CfgRead("Bar", "HeightPct",  "3",  ["StatusBar","HeightPct"])))
    Bar_Transparent  := Pct2Alpha(Integer(CfgRead("Bar", "Opacity",  "78", ["StatusBar","Opacity"])))
    Bar_FontSize     := Integer(CfgRead("Bar", "FontSize",   "10", ["StatusBar","FontSize"]))
    Bar_MonitorIdx   := Integer(CfgRead("Bar", "MonitorIdx", "1",  ["StatusBar","MonitorIdx"]))
    Bar_MarginLeft   := Max(0, Integer(CfgRead("Bar", "margin_left",  "0")))
    Bar_MarginRight  := Max(0, Integer(CfgRead("Bar", "margin_right", "0")))
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

    Border_Enable := CfgRead("Border", "Enable", "on", ["Border","DragEnable"], ["BorderDrag","Enable"])

    Border_Mode := StrLower(Trim(CfgRead("Border", "Mode", "full", ["Border","DragMode"], ["WTM","BorderMode"])))
    if !(Border_Mode = "top" || Border_Mode = "full")
        Border_Mode := "full"

    Border_FocusColor   := CfgRead("Border", "FocusColor",   "A020F0", ["WTM","BorderFocusColor"],   ["Theme","BorderDrag"])
    Border_UnfocusColor := CfgRead("Border", "UnfocusColor", "555555", ["WTM","BorderUnfocusColor"], ["Theme","BorderUnfocus"])

    Border_Thickness := Pct2Border(SafeInt(CfgRead("Border", "Thickness", "8", ["WTM","BorderThickness"], ["Border","DragThickness"], ["BorderDrag","Thickness"]), 8))
    Border_Offset    := Pct2Border(SafeInt(CfgRead("Border", "Offset",    "0", ["WTM","BorderOffset"],    ["Border","DragOffset"],    ["BorderDrag","Offset"]), 0))
    Border_OffsetTop := Pct2Border(SafeInt(CfgRead("Border", "OffsetTop", "5", ["Border","DragOffsetTop"], ["BorderDrag","OffsetTop"]), 5))
    Border_Opacity   := Pct2Alpha(SafeInt(CfgRead("Border", "Opacity",   "80", ["WTM","BorderOpacity"],   ["Border","DragOpacity"],   ["BorderDrag","Opacity"]), 80))

    Border_Rounded := StrLower(Trim(CfgRead("Border", "RoundedCorners", "on", ["WTM","RoundedCorners"], ["Border","DragRounded"], ["BorderDrag","RoundedCorners"])))
    Border_Radius  := Max(0, SafeInt(CfgRead("Border", "Radius", "10", ["WTM","CornerRadius"], ["Border","DragRadius"], ["BorderDrag","CornerRadius"]), 10))

    Border_Gap      := SafeInt(CfgRead("Border", "Gap", "10", ["WTM","Gap"]), 10)
    Border_SizeStep := SafeInt(CfgRead("Border", "SizeStep", "3", ["WTM","SizeStep"]), 3)

    WTM_BorderFocusColor   := Border_FocusColor
    WTM_BorderUnfocusColor := Border_UnfocusColor

    Border_Pin_Mode        := StrLower(IniRead(ConfigFile, "Border", "PinMode", "top"))
    if !(Border_Pin_Mode = "top" || Border_Pin_Mode = "full")
        Border_Pin_Mode := "top"
    Border_Pin_Thickness   := Pct2Border(SafeInt(CfgRead("Border", "PinThickness", "10", ["BorderPin","Thickness"]), 10))
    Border_Pin_Offset      := Pct2Border(SafeInt(CfgRead("Border", "PinOffset",    "0",  ["BorderPin","Offset"]), 0))
    Border_Pin_OffsetTop   := Pct2Border(SafeInt(CfgRead("Border", "PinOffsetTop", "5",  ["BorderPin","OffsetTop"]), 5))
    Border_Pin_Transparent := Pct2Alpha(SafeInt(CfgRead("Border", "PinOpacity",   "78", ["BorderPin","Opacity"]), 78))

    Tile_Gap         := Integer(CfgRead("Tiling", "Gap", "8", ["Layout","Gap"]))
    LayoutRules      := ParseLayoutRules(CfgRead("Tiling", "Rules", "", ["Layout","Rules"]))
    Tile_IncludeAlwaysOnTop := BarShown(IniRead(ConfigFile, "Tiling", "TileAlwaysOnTop", "on"))

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

    Border_Pin_Rounded  := "off"
    Border_Pin_Radius   := 0

    Help_FontSize := Integer(CfgRead("GUI", "HelpFontSize", "10",  ["HelpMenu","FontSize"]))
    Help_Width    := Integer(CfgRead("GUI", "HelpWidth",    "620", ["HelpMenu","Width"]))
    Help_Height   := Integer(CfgRead("GUI", "HelpHeight",   "0",   ["HelpMenu","Height"]))
    Help_Opacity  := Integer(CfgRead("GUI", "HelpOpacity",  "255", ["HelpMenu","Opacity"]))

    PM_FontSize := Integer(CfgRead("GUI", "PowerFontSize", "12",  ["PowerMenu","FontSize"]))
    PM_Width    := Integer(CfgRead("GUI", "PowerWidth",    "500", ["PowerMenu","Width"]))
    PM_Height   := Integer(CfgRead("GUI", "PowerHeight",   "160", ["PowerMenu","Height"]))
    PM_Opacity  := Integer(CfgRead("GUI", "PowerOpacity",  "255", ["PowerMenu","Opacity"]))

    DesktopCount := Integer(CfgRead("Desktop", "Count", "9", ["Desktops","Count"]))
    if (DesktopCount < 1)
        DesktopCount := 1
    if (DesktopCount > 9)
        DesktopCount := 9
    Desktop_HideMethod := StrLower(CfgRead("Desktop", "HideMethod", "minimize", ["Desktops","HideMethod"]))
    if !(Desktop_HideMethod = "minimize" || Desktop_HideMethod = "hide")
        Desktop_HideMethod := "minimize"

    Bar_Cfg := Map()
    Bar_Cfg["desktops"]     := (StrLower(IniRead(ConfigFile, "Bar", "desktops", "true")) = "true")
    Bar_Cfg["time"]         := (StrLower(IniRead(ConfigFile, "Bar", "time",     "true")) = "true")
    Bar_Cfg["date"]         := (StrLower(IniRead(ConfigFile, "Bar", "date",     "true")) = "true")
    Bar_Cfg["progress"]     := (StrLower(IniRead(ConfigFile, "Bar", "progress", "true")) = "true")
    Bar_Cfg["time_format"]  := IniRead(ConfigFile, "Bar", "time_format", "HH:mm")
    Bar_Cfg["date_format"]  := IniRead(ConfigFile, "Bar", "date_format", "yyyy-MM-dd")
    Bar_Cfg["cur_left"]     := IniRead(ConfigFile, "Bar", "current_desktop_left",  "[")
    Bar_Cfg["cur_right"]    := IniRead(ConfigFile, "Bar", "current_desktop_right", "]")
    Bar_Cfg["display_mode"] := StrLower(IniRead(ConfigFile, "Bar", "desktop_display_mode", "all"))
    Bar_Cfg["position"]     := StrLower(IniRead(ConfigFile, "Bar", "position", "top"))
    Bar_Cfg["offset"]       := SafeInt(IniRead(ConfigFile, "Bar", "offset", "0"), 0)
    Bar_Cfg["instances"]    := IniRead(ConfigFile, "Bar", "instances", "")
    Bar_Cfg["layout"]       := ParseBarLayout(IniRead(ConfigFile, "Bar", "layout", ""))

    Bar_Cfg["custom_items"] := ParseCustomItems(
        IniRead(ConfigFile, "Bar", "custom_items", ""),
        IniRead(ConfigFile, "Bar", "custom_icon",  ""),
        IniRead(ConfigFile, "Bar", "custom_text",  ""))

    Bar_AutoHide := BarShown(IniRead(ConfigFile, "Bar", "AutoHideOnFullscreen", "off"))

    barLabelsRaw := IniRead(ConfigFile, "Bar", "desktop_labels", "")
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

    Work_Mode       := IniRead(ConfigFile, "WorkTime", "Mode",       "on")
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
    WS_BarColor  := Trim(IniRead(ConfigFile, "WinSelect", "BarColor",  ""))
    WS_TextColor := Trim(IniRead(ConfigFile, "WinSelect", "TextColor", ""))
    WS_BarHeight := Max(16, SafeInt(IniRead(ConfigFile, "WinSelect", "Height", "28"), 28))
    WS_BarWidth  := Max(0,  SafeInt(IniRead(ConfigFile, "WinSelect", "Width",  "0"),  0))
    WS_OffsetY   := SafeInt(IniRead(ConfigFile, "WinSelect", "OffsetY", "8"), 8)
    WS_FontSize  := Max(6,  SafeInt(IniRead(ConfigFile, "WinSelect", "FontSize", "14"), 14))
    WS_Opacity   := Pct2Alpha(SafeInt(IniRead(ConfigFile, "WinSelect", "Opacity", "85"), 85))
    WS_Rounded   := StrLower(Trim(IniRead(ConfigFile, "WinSelect", "Rounded", "on")))
    WS_Radius    := Max(0, SafeInt(IniRead(ConfigFile, "WinSelect", "CornerRadius", "10"), 10))
    WS_CornerMode := StrLower(Trim(IniRead(ConfigFile, "WinSelect", "CornerMode", "top")))
    WS_Timeout   := Max(0, SafeInt(IniRead(ConfigFile, "WinSelect", "Timeout", "12"), 12))

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

; ---- 窗口选择模式尺寸映射解析 / Parse [WinSelect] SizeMap ----
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

; ---- 临时 GUI 清理 / Destroy transient GUIs ----
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

; ---- 帮助界面 / Help GUI ----
ShowHelpGui(*) {
    global HelpGuiObj, HK
    global Help_FontSize, Help_Width, Help_Opacity, Help_Rounded, Help_Radius

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
    helpGui.SetFont("s" Round(20*fsc) " w700 c" . Color_Text, "Segoe UI")
    helpGui.Add("Text", "x0 y" Round(20*fsc) " w" fullW " Center", "HELP")
    helpGui.SetFont("s" Help_FontSize " w700 c" . Color_Active, "Segoe UI")
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

    helpGui.Show("Center")
    try WinSetTransparent(Help_Opacity, helpGui.Hwnd)
    RoundWindowEx(helpGui, Help_Rounded, Help_Radius)
    HelpGuiObj := helpGui
    SetTimer CloseWatcher, 50
}

; ---- 欢迎屏 / Welcome screen ----
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
            , "V" . WM_Version . "  ::  AutoHotkey v2")

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

; ---- 八方向按钮模板生成 / Eight-direction button template init ----
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

; ---- 屏幕提示 / On-screen display ----
class OSD {
    static GuiObj := 0, Timer := 0

    ; -- 显示提示 / Show an OSD message --
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
        RoundWindowEx(g, OSD_Rounded, OSD_Radius)

        this.GuiObj := g
        this.Timer  := () => (IsObject(OSD.GuiObj) ? (OSD.GuiObj.Destroy(), OSD.GuiObj := 0) : 0)
        SetTimer(this.Timer, -duration)
    }
}

; ---- OSD 快捷函数 / OSD shorthand ----
ShowOSD(text) => OSD.Show(text)

; ==============================================================================
; 九、边框系统 / 9. Border System (BorderFrame / DragBorder / PinBorder)
; ==============================================================================

; ---- 空心边框窗口 / Hollow-frame border window ----
class BorderFrame {
    Gui   := ""
    Color := ""
    LastW := -1, LastH := -1, LastT := -1, LastR := -1
    LastMode := ""

    ; -- 创建边框 / Create the frame --
    __New(color, opacity) {
        g := Gui("-Caption +ToolWindow +E0x20 -DPIScale")
        g.BackColor := color
        g.Show("NoActivate x-3000 y-3000 w10 h10")
        try WinSetTransparent(opacity, g.Hwnd)
        this.Gui   := g
        this.Color := color
    }

    ; -- 设置颜色 / Set frame color --
    SetColor(color) {
        if (this.Color = color)
            return
        try {
            this.Gui.BackColor := color
            WinRedraw(this.Gui.Hwnd)
        }
        this.Color := color
    }

    ; -- Z 序解析 / Resolve SetWindowPos insert-after handle --
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

    ; -- 定位边框 / Position the frame around a rect --
    Place(x, y, w, h, thickness, radius, opacity, mode := "full", insertAfter := -1) {
        if !IsObject(this.Gui)
            return
        t   := Max(1, Round(thickness))
        ins := this._ZOrder(insertAfter)
        if (insertAfter != -1) {
            exb := 0
            try exb := WinGetExStyle(this.Gui.Hwnd)
            if (exb & 0x8)
                try WinSetAlwaysOnTop(false, this.Gui.Hwnd)
        }
        if (mode = "top") {
            ww := Round(Max(t, w))
            try DllCall("SetWindowPos", "Ptr", this.Gui.Hwnd, "Ptr", ins
                , "Int", Round(x), "Int", Round(y), "Int", ww, "Int", t
                , "UInt", 0x10 | 0x40)
            this._ApplyTopRegion(ww, t)
            return
        }
        w := Round(Max(t*2 + 1, w)), h := Round(Max(t*2 + 1, h))
        try DllCall("SetWindowPos", "Ptr", this.Gui.Hwnd, "Ptr", ins
            , "Int", Round(x), "Int", Round(y), "Int", w, "Int", h
            , "UInt", 0x10 | 0x40)
        this._ApplyRegion(w, h, t, Max(0, Round(radius)))
    }

    ; -- 顶条区域 / Solid top-strip region --
    _ApplyTopRegion(w, t) {
        if (this.LastMode = "top" && w = this.LastW && t = this.LastT)
            return
        this.LastMode := "top", this.LastW := w, this.LastH := t, this.LastT := t, this.LastR := 0
        try DllCall("User32\SetWindowRgn", "Ptr", this.Gui.Hwnd, "Ptr", 0, "Int", 1)
    }

    ; -- 空心框区域 / Hollow-frame region --
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

    ; -- 隐藏 / Hide the frame --
    Hide() {
        if IsObject(this.Gui)
            try DllCall("ShowWindow", "Ptr", this.Gui.Hwnd, "Int", 0)
    }

    ; -- 销毁 / Destroy the frame --
    Destroy() {
        if IsObject(this.Gui)
            try this.Gui.Destroy()
        this.Gui := ""
    }
}

; ---- 拖拽边框 / Drag border (single rounded frame) ----
class DragBorder {
    static Frame := ""

    ; -- 显示 / Show --
    static Show() {
        if (Border_Enable != "on")
            return
        this.Destroy()
        this.Frame := BorderFrame(Border_FocusColor, Border_Opacity)
    }

    ; -- 跟随更新 / Update to follow a window --
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
        this.Frame.Place(x, y, w, h, Border_Thickness, rad, Border_Opacity, Border_Mode, -1)
    }

    ; -- 销毁 / Destroy --
    static Destroy() {
        if IsObject(this.Frame)
            this.Frame.Destroy()
        this.Frame := ""
    }
}

; ---- 置顶指示边框 / Pinned-window border ----
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
            frame.Place(x, y, w, h, t, 0, Border_Pin_Transparent, Border_Pin_Mode, -1)
        }
    }
}

; ==============================================================================
; 十、鼠标下窗口操作 / 10. Under-Cursor Window Actions
; ==============================================================================

; ---- 关闭鼠标下窗口 / Close window under mouse ----
CloseWindowUnderMouse(*) {
    MouseGetPos(,, &hwnd)
    try {
        WinClose(hwnd)
        PinBorder.Remove(hwnd)
        ShowOSD("Closing Window...")
    }
    WTM.OnWindowChanged()
}

; ---- 最小化鼠标下窗口 / Minimize window under mouse ----
HideUnderMouse(*) {
    MouseGetPos(,, &hwnd)
    try {
        WinMinimize(hwnd)
        ShowOSD("WinMinimized")
    }
    WTM.OnWindowChanged()
}

; ---- 最大化/还原鼠标下窗口 / Toggle maximize under mouse ----
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

; ---- 置顶切换（鼠标下）/ Toggle always-on-top under mouse ----
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

; ---- 透明度调节 / Adjust window transparency ----
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

; ==============================================================================
; 十一、功能环 / 11. Pie Menu
; ==============================================================================

; ---- 功能环 / Radial pie menu ----
class PieMenu {
    static DirMap   := ["Right","DownRight","Down","DownLeft","Left","TopLeft","Top","TopRight"]
    static IsActive := false, GuiObj := "", Labels := Map()
    static PendingRUp := false
    static TimerFn  := ObjBindMethod(PieMenu, "CheckMouse")
    static StartX   := 0, StartY := 0, CurrentSector := "", LastSector := ""

    ; -- 启动 / Start the pie menu --
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

    ; -- 构建界面 / Build the GUI --
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

    ; -- 鼠标扇区检测 / Track mouse sector --
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

    ; -- 高亮刷新 / Refresh sector highlight --
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

    ; -- 执行所选方向 / Execute the selected sector --
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
; 十二、虚拟桌面 / 12. Virtual Desktops
; ==============================================================================

; ---- 隐藏窗口 / Hide one window per configured method ----
HideWin(hwnd) {
    global Desktop_HideMethod
    if (Desktop_HideMethod = "hide"){
        try DllCall("ShowWindow", "Ptr", hwnd, "Int", 0)
    }
    else{
        try WinMinimize(hwnd)
    }
}

; ---- 显示窗口 / Show one window per configured method ----
ShowWin(hwnd) {
    global Desktop_HideMethod
    if (Desktop_HideMethod = "hide"){
        try DllCall("ShowWindow", "Ptr", hwnd, "Int", 8)
    }
    else{
        try WinRestore(hwnd)
    }
}

; ---- 切换桌面 / Switch virtual desktop ----
SwitchDesktop(target, *) {
    global CurrentDesktop, Desktops, AlwaysVisible, DesktopFocus
    if (target == CurrentDesktop) {
        ShowOSD("Desktop " . target)
        return
    }

    wasWTMActive := WTM.Active
    if wasWTMActive
        WTM.DestroyAllBorders()
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
    for hwnd in Desktops[target]
        ShowWin(hwnd)
    for hwnd, _ in AlwaysVisible
        ShowWin(hwnd)

    CurrentDesktop := target
    UpdateStatusBar()
    A_IconTip := "AHK WM - Desktop " . CurrentDesktop
    ShowOSD("Desktop " . CurrentDesktop)

    if (DesktopFocus.Has(target) && DesktopFocus[target] && WinExist(DesktopFocus[target]))
        FocusWindowSafely(DesktopFocus[target])

    if wasWTMActive
        WTM.OnDesktopSwitched()
    if AllBorders.Active
        AllBorders.Rebuild()
}

; ---- 移动窗口到桌面 / Move active window to a desktop ----
MoveWindowToDesktop(target, *) {
    global CurrentDesktop, Desktops, AlwaysVisible

    hwnd := 0
    try hwnd := WinExist("A")
    if (!hwnd || IsBarWindow(hwnd))
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
        HideWin(hwnd)
        ShowOSD("Window -> Desktop " . target)
    }
    WTM.OnWindowChanged()
}

; ---- 携带窗口切换桌面（保持焦点）/ Move window and switch, keeping its focus ----
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
        DesktopFocus[target] := hwnd
    }
    ShowOSD("Move And Switch -> " . target)
}

; ==============================================================================
; 十三、状态栏 / 13. Status Bar
; ==============================================================================

; ---- 开关值判定 / Truthy-flag parsing for config values ----
BarShown(str) {
    s := StrLower(Trim(str))
    return !(s = "" || s = "false" || s = "off" || s = "0")
}

; ---- 组件开关查询 / Widget-flag lookup ----
BarFlag(key) {
    global Bar_Cfg
    return (Bar_Cfg.Has(key) && Bar_Cfg[key])
}

; ---- 状态栏布局解析 / Parse "element:expr;..." bar layout ----
ParseBarLayout(str) {
    m := Map()
    for clause in StrSplit(str, ";") {
        clause := Trim(clause)
        if (clause = "")
            continue
        p := StrSplit(clause, ":")
        if (p.Length != 2)
            continue
        try {
            m[StrLower(Trim(p[1]))] := ParseAxis(p[2])
        } catch Error as e {
            WMLog("Bar layout segment invalid (" e.Message "): " clause)
        }
    }
    return m
}

; ---- 工作时间范围（分钟）/ Work-time range in minutes ----
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

; ---- 当日任务时段 / Today's task slots ----
WorkDayTasks(baseStart, baseEnd) {
    global Work_TaskTimes
    out := []
    if (Work_TaskTimes = "" || baseEnd - baseStart <= 0)
        return out
    userWDay := (A_WDay == 1) ? 7 : A_WDay - 1
    Loop Parse, Work_TaskTimes, ";" {
        if (A_LoopField = "")
            continue
        parts := StrSplit(A_LoopField, "_")
        if (parts.Length == 3 && Integer(parts[1]) == userWDay) {
            rs := Integer(SubStr(parts[2],1,2))*60 + Integer(SubStr(parts[2],3,2))
            re := Integer(SubStr(parts[3],1,2))*60 + Integer(SubStr(parts[3],3,2))
            s := Max(rs, baseStart), e := Min(re, baseEnd)
            if (e > s)
                out.Push({Start:s, End:e, RawStart:rs})
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

; ---- 工作进度百分比 / Work-time progress percent ----
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

; ---- 状态栏实例 / One bar strip on one monitor edge ----
class BarInstance {
    Mon := 1, Pos := "top", Offset := 0, Thick := 30
    Gui := "", Visible := true
    DesktopsCtrl := "", TimeCtrl := "", DateCtrl := "", Progress := ""
    ProgX := 0, ProgY := 0, ProgW := 0

    ; -- 构造 / Construct & build --
    __New(mon, pos, offset) {
        this.Mon := mon, this.Pos := pos, this.Offset := offset
        this.Build()
    }

    ; -- 是否水平 / Horizontal orientation check --
    IsHorizontal() => (this.Pos = "top" || this.Pos = "bottom")

    ; -- 元素跨度解析 / Resolve an element's layout segment --
    _Seg(name) {
        global Bar_Cfg
        layout := Bar_Cfg["layout"]
        keys := [name]
        if (name = "custom_1") {
            keys.Push("custom_icon")
            keys.Push("custom_text")
        } else if (name = "custom_2") {
            keys.Push("custom_text")
        }
        for k in keys {
            if layout.Has(k)
                return layout[k]
        }
        defaults := Map(
            "desktops",  {lo:0.00, hi:0.30},
            "custom_1",  {lo:0.30, hi:0.48},
            "custom_2",  {lo:0.48, hi:0.62},
            "progress",  {lo:0.40, hi:0.62},
            "date",      {lo:0.64, hi:0.82},
            "time",      {lo:0.82, hi:1.00}
        )
        return defaults.Has(name) ? defaults[name] : {lo:0.0, hi:1.0}
    }

    ; -- 行高计算 / Text line-height --
    _LineHeight() {
        global Bar_FontSize
        px := Bar_FontSize * A_ScreenDPI / 72
        return Round(px * 1.4) + 2
    }

    ; -- 控件选项串 / Control option string --
    _Opt(x, y, w, h, align) {
        return Format("x{} y{} w{} h{} BackgroundTrans {}", Round(x), Round(y), Round(w), Round(h), align)
    }

    ; -- 构建状态栏 / Build the bar window --
    ; -- 构建状态栏 / Build the bar window --
    Build() {
        global Color_Bg, Color_Active, Bar_FontSize, Bar_Height, Bar_Transparent
        global Bar_Rounded, Bar_Radius, Bar_CornerMode
        global Bar_MarginLeft, Bar_MarginRight
        if (this.Mon < 1 || this.Mon > MonitorGetCount())
            this.Mon := 1
        MonitorGet(this.Mon, &mL, &mT, &mR, &mB)

        ; 应用左右边距，夹紧避免越界 / Apply L/R margins, clamp to stay valid
        mlEff := mL + Bar_MarginLeft
        mrEff := mR - Bar_MarginRight
        barW  := mrEff - mlEff
        if (barW < 50) {
            mlEff := mL, barW := mR - mL    ; 边距过大则回退 / fall back if margins too wide
            WMLog("Bar: margins exceed monitor " this.Mon " width; ignored")
        }

        lineH := this._LineHeight()
        thick := Bar_Height
        minThick := Max(lineH + 4, Round(Bar_FontSize * 2 + 5))
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
        g.BackColor := Color_Bg
        g.SetFont("s" Bar_FontSize " w600 c" Color_Active, "Segoe UI")
        this.Gui := g

        this._BuildElements(bw, bh, true)

        g.Show(Format("x{} y{} w{} h{} NoActivate", bx, by, bw, bh))
        WinSetTransparent(Bar_Transparent, g.Hwnd)
        RoundWindowEx(g, Bar_Rounded, Bar_Radius, Bar_CornerMode)
        this.UpdateDesktops()
    }
    ; -- 构建元素 / Build bar elements --
    _BuildElements(L, T, horiz) {
        global Bar_Cfg, Bar_FontSize
        g := this.Gui
        fontH := this._LineHeight()
        pad := 6

        items := Bar_Cfg["custom_items"]
        elements := []
        if BarFlag("desktops")
            elements.Push("desktops")
        for idx, val in items {
            if BarShown(val)
                elements.Push("custom_" idx)
        }
        if BarFlag("progress")
            elements.Push("progress")
        if BarFlag("date")
            elements.Push("date")
        if BarFlag("time")
            elements.Push("time")

        for el in elements {
            seg := this._Seg(el)
            s   := seg.lo * L
            segLen := Max(10, (seg.hi - seg.lo) * L)
            if horiz {
                cx := s, cy := (T - fontH) // 2, cw := segLen, ch := fontH
            } else {
                cx := pad, cy := s, cw := T - 2*pad, ch := fontH
            }
            switch el {
                case "desktops":
                    this.DesktopsCtrl := g.Add("Text", this._Opt(cx, cy, cw, ch, "Center"), "")
                case "date":
                    this.DateCtrl := g.Add("Text", this._Opt(cx, cy, cw, ch, "Center"), "")
                case "time":
                    this.TimeCtrl := g.Add("Text", this._Opt(cx, cy, cw, ch, "Center"), "")
                case "progress":
                    this._BuildProgress(s, segLen, T, horiz)
                default:
                    if RegExMatch(el, "^custom_(\d+)$", &mm) {
                        n := Integer(mm[1])
                        txt := (n >= 1 && n <= items.Length) ? items[n] : ""
                        g.Add("Text", this._Opt(cx, cy, cw, ch, "Center"), txt)
                    }
            }
        }
    }

    ; -- 构建进度条 / Build the progress widget --
    _BuildProgress(mainStart, mainLen, T, horiz) {
        global Color_Active
        g := this.Gui
        bar := 6
        if horiz {
            px := mainStart, py := (T - bar) // 2 + 3, pw := mainLen, ph := bar
            g.Add("Text", Format("x{} y{} w{} h{} Background333333", Round(px), Round(py), Round(pw), ph), "")
            this.Progress := g.Add("Progress"
                , Format("x{} y{} w{} h{} c{} Background333333 +Smooth", Round(px), Round(py), Round(pw), ph, Color_Active), 0)
            this.ProgX := px, this.ProgW := pw, this.ProgY := py
            this._BuildTaskMarkers(px, pw, py)
        } else {
            px := (T - bar) // 2, py := mainStart, pw := bar, ph := mainLen
            g.Add("Text", Format("x{} y{} w{} h{} Background333333", Round(px), Round(py), pw, Round(ph)), "")
            this.Progress := g.Add("Progress"
                , Format("x{} y{} w{} h{} Vertical c{} Background333333 +Smooth", Round(px), Round(py), pw, Round(ph), Color_Active), 0)
        }
    }

    ; -- 任务时段标记 / Task-slot markers --
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
            this.Gui.Add("Text", Format("x{} y{} w{} h{} Background{}", mkX, useY, mkW, taskH, Color_Task), "")
        }
    }

    ; -- 桌面指示更新 / Update the desktops widget --
    UpdateDesktops() {
        global CurrentDesktop, DesktopCount, Desktops, Bar_Cfg
        if !IsObject(this.DesktopsCtrl)
            return
        labels := Bar_Cfg["desktop_labels"]
        lft := Bar_Cfg["cur_left"], rgt := Bar_Cfg["cur_right"]
        mode := Bar_Cfg["display_mode"]
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
        try this.DesktopsCtrl.Value := str
    }

    ; -- 时钟/进度更新 / Update clock & progress --
    UpdateClock(pct) {
        global Bar_Cfg
        if IsObject(this.TimeCtrl)
            try this.TimeCtrl.Value := FormatTime(, Bar_Cfg["time_format"])
        if IsObject(this.DateCtrl)
            try this.DateCtrl.Value := FormatTime(, Bar_Cfg["date_format"])
        if IsObject(this.Progress)
            try this.Progress.Value := Integer(pct)
    }

    ; -- 显示 / Show --
    Show()    => (this.Gui ? this.Gui.Show("NoActivate") : 0)
    ; -- 隐藏 / Hide --
    Hide()    => (this.Gui ? this.Gui.Hide() : 0)
    ; -- 销毁 / Destroy --
    Destroy() {
        if IsObject(this.Gui)
            try this.Gui.Destroy()
        this.Gui := ""
    }
}

; ---- 状态栏实例解析 / Resolve configured bar instances ----
BarInstances() {
    global Bar_Cfg, Bar_MonitorIdx
    out := [], seenMon := Map()
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
            p := StrSplit(clause, ":")
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
            for m in mons {
                if seenMon.Has(m) {
                    WMLog("Bar: monitor " m " already has a bar; ignoring '" clause "'")
                    continue
                }
                seenMon[m] := true
                out.Push({mon:m, pos:pos, offset:off})
            }
        }
    }
    if (out.Length = 0) {
        mon := (Bar_MonitorIdx >= 1 && Bar_MonitorIdx <= monCount) ? Bar_MonitorIdx : 1
        out.Push({mon:mon, pos:defPos, offset:defOff})
    }
    return out
}

; ---- 状态栏窗口判定 / Bar-window check ----
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

; ---- 状态栏区域预留 / Subtract bars from a work-area rect ----
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

; ---- 销毁全部状态栏 / Destroy all bars ----
DestroyAllBars() {
    global Bars
    if !IsSet(Bars)
        return
    for b in Bars
        try b.Destroy()
    Bars := []
}

; ---- 创建状态栏 / Create all configured bars ----
CreateStatusBar() {
    global Bars, Bar_ShownState
    DestroyAllBars()
    Bars := []
    for inst in BarInstances() {
        try Bars.Push(BarInstance(inst.mon, inst.pos, inst.offset))
        catch Error as e
            WMLog("Bar build failed (mon " inst.mon "): " e.Message)
    }
    Bar_ShownState := true
    ApplyBarVisibility()
    UpdateStatusBar()
}

; ---- 桌面指示刷新 / Refresh the desktops widget on every bar ----
UpdateStatusBar() {
    global Bars
    if !IsSet(Bars)
        return
    for b in Bars
        try b.UpdateDesktops()
}

; ---- 每秒时钟刷新 / Per-second clock & progress tick ----
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
}

; ---- 全屏窗口检测 / Detect a fullscreen window on a monitor ----
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

; ---- 状态栏可见性应用 / Apply manual toggle + fullscreen auto-hide ----
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
            }
            else {
            b.Show()
            anyShown := true
        }
    }

    Bar_FsHidden  := anyHidden
    Bar_ShownState := anyShown
}

; ---- 状态栏显隐切换 / Toggle bar visibility ----
ToggleBar(*) {
    global Bar_Visible
    Bar_Visible := !Bar_Visible
    ApplyBarVisibility()
}

; ---- 常显窗口切换 / Toggle always-visible pin ----
TogglePin(*) {
    global AlwaysVisible
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

; ---- 聚集全部窗口 / Gather all windows to the current desktop ----
GatherAllToCurrent(*) {
    global Desktops, CurrentDesktop, AlwaysVisible
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

; ---- 平铺外边界设置 / Set protected tiling boundary ----
SetTileBound(l, t, r, b) {
    global TileBound_L, TileBound_T, TileBound_R, TileBound_B, TileBoundSet
    TileBound_L := l, TileBound_T := t, TileBound_R := r, TileBound_B := b
    TileBoundSet := true
}

; ---- 平铺外边界清除 / Clear protected tiling boundary ----
ClearTileBound() {
    global TileBoundSet
    TileBoundSet := false
}

; ---- 当前显示器智能平铺 / Smart-tile the monitor under the mouse ----
TileCurrentMonitor(*) {
    global CurrentTileGap, Tile_Gap

    MouseGetPos(&mx, &my)
    targetMon := GetMonitorIndexAtPoint(mx, my)
    MonitorGetWorkArea(targetMon, &WL, &WT, &WR, &WB)
    BarReserve(targetMon, &WL, &WT, &WR, &WB)

    SetTileBound(WL, WT, WR, WB)

    W := WR - WL
    H := WB - WT

    windows := GetVisibleWindowsOnMonitor(targetMon)
    n := windows.Length
    if (n == 0) {
        ShowOSD("No Windows To Tile")
        ClearTileBound()
        return
    }

    g := Tile_Gap
    if (g > 0) {
        WL += g/2, WT += g/2, W -= g, H -= g
    }
    CurrentTileGap := g

    aspect := (H != 0) ? W / H : 1
    if (H > W)
        mode := "Vertical"
    else if (aspect >= 32/9 - 0.15)
        mode := "Ultrawide"
    else
        mode := "Normal"

    if ApplyCustomLayout(windows, WL, WT, W, H, targetMon) {
        ShowOSD("Tile [Custom] [Mon " . targetMon . "]: " . n)
    } else {
        ShowOSD("Tile [" . mode . "] [Mon " . targetMon . "]: " . n)
        switch mode {
            case "Vertical":  TileVertical(windows, WL, WT, W, H)
            case "Ultrawide": TileUltrawide(windows, WL, WT, W, H)
            default:          TileNormal(windows, WL, WT, W, H)
        }
    }

    CurrentTileGap := 0
    ClearTileBound()
}

; ---- 摆放窗口（含间隙与边界保护）/ Place one window with gap & bound clamp ----
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

; ---- 网格平铺 / Grid tiling ----
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

; ---- 常规屏平铺 / Normal-aspect tiling ----
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

; ---- 竖屏平铺 / Vertical-monitor tiling ----
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

; ---- 超宽屏平铺 / Ultrawide-monitor tiling ----
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

; ---- 可平铺判定 / Tiling eligibility check ----
IsTilableWindow(hwnd) {
    global Tile_IncludeAlwaysOnTop
    if Tile_IncludeAlwaysOnTop
        return true
    ex := 0
    try ex := WinGetExStyle(hwnd)
    return !(ex & 0x8)
}

; ---- 显示器可见窗口 / Visible windows on one monitor ----
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

; ---- 当前桌面可见窗口（含过滤）/ Visible windows, exclusion-aware ----
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

; ---- 可见窗口（桌面切换用）/ Visible windows for desktop bookkeeping ----
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

; ---- 吸附状态上下文 / Per-axis sticky-snap context ----
class SnapCtx {
    xOn := false, xLine := 0, xEdge := ""
    yOn := false, yLine := 0, yEdge := ""
}

; ---- 收集吸附线 / Gather candidate snap lines ----
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
            WinGetPos(&ox, &oy, &ow, &oh, h)
        } catch
            continue
        vLines.Push(ox)
        vLines.Push(ox + ow)
        hLines.Push(oy)
        hLines.Push(oy + oh)
    }
}

; ---- 移动吸附（单轴）/ Snap one axis of a move ----
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

; ---- 移动吸附 / Snap a window move ----
SnapMove(rawX, rawY, w, h, vLines, hLines, ctx, &outX, &outY) {
    global Snap_Enable
    outX := rawX, outY := rawY
    if !Snap_Enable
        return
    _SnapMoveAxis(rawX, rawX + w, w, vLines, ctx, "x", &outX)
    _SnapMoveAxis(rawY, rawY + h, h, hLines, ctx, "y", &outY)
}

; ---- 缩放吸附（单轴）/ Snap one moving edge of a resize ----
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

; ---- 缩放吸附 / Snap a window resize ----
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

; ---- 拖拽时边框跟随 / Keep WTM / all-window borders glued while dragging ----
BorderFollowDrag(hwnd) {
    try WTM.DrawOne(hwnd)
    try AllBorders.DrawOne(hwnd)
}

; ---- 拖拽移动 / Drag-move handler ----
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
    try WinGetPos(&winX, &winY, &winW, &winH, hwnd)
    catch
        return

    ctx := SnapCtx()
    vLines := [], hLines := []
    try GatherSnapLines(hwnd, &vLines, &hLines)

    DragBorder.Show()
    while GetKeyState("LButton", "P") {
        MouseGetPos(&curX, &curY)
        rawX := winX + (curX - startX)
        rawY := winY + (curY - startY)
        SnapMove(rawX, rawY, winW, winH, vLines, hLines, ctx, &nx, &ny)
        try WinMove(nx, ny,,, hwnd)
        catch
            break
        DragBorder.Update(hwnd)
        BorderFollowDrag(hwnd)
    }
    DragBorder.Destroy()
    WTM.OnWindowChanged()
}

; ---- 拖拽缩放 / Drag-resize handler ----
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
    fixedRight  := winX + winW
    fixedBottom := winY + winH

    ctx := SnapCtx()
    vLines := [], hLines := []
    try GatherSnapLines(hwnd, &vLines, &hLines)

    DragBorder.Show()
    while GetKeyState("RButton", "P") {
        MouseGetPos(&curX, &curY)
        dX := curX - startX, dY := curY - startY
        nX := isLeft ? (winX+dX) : winX, nW := isLeft ? (winW-dX) : (winW+dX)
        nY := isUp   ? (winY+dY) : winY, nH := isUp   ? (winH-dY) : (winH+dY)
        SnapResize(nX, nW, nY, nH, winX, winY, fixedRight, fixedBottom, isLeft, isUp
                 , vLines, hLines, ctx, &nX, &nW, &nY, &nH)
        if (nW > 50 && nH > 50) {
            try WinMove(nX, nY, nW, nH, hwnd)
            catch
                break
            DragBorder.Update(hwnd)
            BorderFollowDrag(hwnd)
        }
    }
    DragBorder.Destroy()
    WTM.OnWindowChanged()
}

; ---- 方向吸附 / Directional snap (left/right halves, max/min) ----
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

; ---- 布局快照保存 / Save layout snapshot ----
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

; ---- 布局快照恢复 / Restore layout snapshot ----
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

; ---- WTM 动态平铺模式 / Dynamic tiling mode ----
class WTM {
    static Active     := false
    static TileOrder  := []
    static Excluded   := Map()
    static FocusHwnd  := 0
    static BorderMap   := Map()
    static BorderState := Map()
    static _LastSig   := ""
    static _Accum     := 0
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
        this.RebuildOrder()
        this.AutoTile()
        this.RefreshBorder()
        SetTimer(this.TickFn, Border_RefreshMs)
        AllBorders.Suspend()
        ShowOSD("WTM Mode: ON")
    }

    ; -- 停用 / Deactivate --
    static Deactivate() {
        this.Active := false
        SetTimer(this.TickFn, 0)
        this.DestroyAllBorders()
        AllBorders.Rebuild()
        ShowOSD("WTM Mode: OFF")
    }

    ; -- 桌面切换处理 / Handle a desktop switch --
    static OnDesktopSwitched() {
        if !this.Active
            return
        this.DestroyAllBorders()
        this.RebuildOrder()
        this._LastSig := this._Signature()
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
    static _TileMonitor(monIdx, wins) {
        global CurrentTileGap, Border_Gap
        if (wins.Length = 0)
            return
        if (monIdx < 1 || monIdx > MonitorGetCount())
            monIdx := 1
        MonitorGetWorkArea(monIdx, &WL, &WT, &WR, &WB)
        BarReserve(monIdx, &WL, &WT, &WR, &WB)
        SetTileBound(WL, WT, WR, WB)
        W := WR - WL, H := WB - WT

        g := Border_Gap
        if (g > 0) {
            WL += g/2, WT += g/2, W -= g, H -= g
        }
        CurrentTileGap := g

        if !ApplyCustomLayout(wins, WL, WT, W, H, monIdx) {
            aspect := (H != 0) ? W / H : 1
            if (H > W)
                TileVertical(wins, WL, WT, W, H)
            else if (aspect >= 32/9 - 0.15)
                TileUltrawide(wins, WL, WT, W, H)
            else
                TileNormal(wins, WL, WT, W, H)
        }

        CurrentTileGap := 0
        ClearTileBound()
    }

    ; -- 成员签名 / Membership signature (order/size independent) --
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
            } catch {
                continue
            }
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
            sig .= v ";"
        return sig
    }

    ; -- 定时刷新（Alt 按住期间推迟重排，避免组合键过程中误平铺）--
    ; -- Periodic tick (retile deferred while Alt is held, so unfinished
    ;    Alt-chords / desktop switches never trigger a mid-sequence retile) --
    static Tick() {
        if !this.Active
            return
        this._Accum += Border_RefreshMs
        if (this._Accum >= 150) {
            this._Accum := 0
            if !GetKeyState("Alt", "P") {
                sig := this._Signature()
                if (sig != this._LastSig)
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
    static _PickSwapTarget(hwnd, dir, monIdx) {
        if !WinExist(hwnd)
            return 0
        try WinGetPos(&cx, &cy, &cw, &ch, hwnd)
        catch
            return 0
        ccx := cx + cw/2, ccy := cy + ch/2
        best := 0
        bestP := 0, bestS := 0, have := false
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
            if      (dir = "L" && dx >= 0)
                continue
            else if (dir = "R" && dx <= 0)
                continue
            else if (dir = "U" && dy >= 0)
                continue
            else if (dir = "D" && dy <= 0)
                continue
            if (dir = "L" || dir = "R") {
                pri := Abs(dx), sec := Abs(dy)
            } else {
                pri := Abs(dy), sec := Abs(dx)
            }
            if (!have || pri < bestP || (pri = bestP && sec < bestS)) {
                have := true, best := h, bestP := pri, bestS := sec
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
    static TogglePinExclude() {
        MouseGetPos(,, &hwnd)
        if !hwnd {
            try hwnd := WinGetID("A")
        }
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
        try this.BorderMap[hwnd].Destroy()
        this.BorderMap.Delete(hwnd)
        if this.BorderState.Has(hwnd)
            this.BorderState.Delete(hwnd)
    }

    ; -- 移除全部边框 / Remove all border frames --
    static DestroyAllBorders() {
        for hwnd, _ in this.BorderMap.Clone()
            this.RemoveBorder(hwnd)
        this.BorderMap   := Map()
        this.BorderState := Map()
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
    static RefreshBorder() {
        if !this.Active
            return
        valid := Map()
        for hwnd in this.TileOrder
            valid[hwnd] := true
        for hwnd, _ in this.BorderMap.Clone() {
            if !valid.Has(hwnd) || !WinExist(hwnd)
                this.RemoveBorder(hwnd)
        }

        focusH := this.FocusHwnd
        for hwnd in this.TileOrder
            this._DrawBorder(hwnd, focusH)
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
        if !GetWindowVisualRect(hwnd, &x, &y, &w, &ht)
            return
        o := Border_Offset
        x -= o, y -= o, w += 2*o, ht += 2*o
        this._SetBorderColor(hwnd, hwnd = focusH ? "focus" : "unfocus")
        rad := (Border_Rounded = "on") ? Border_Radius : 0
        this.BorderMap[hwnd].Place(x, y, w, ht, Max(2, Border_Thickness), rad, Border_Opacity, Border_Mode, hwnd)
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

; ---- 全窗口边框 / Borders on every window (defers to WTM) ----
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
        if !this.Active || WTM.Active
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
        if !GetWindowVisualRect(hwnd, &x, &y, &w, &h)
            return
        o := Border_Offset
        x -= o, y -= o, w += 2*o, h += 2*o
        this.SetColor(hwnd, hwnd = focusH ? "focus" : "unfocus")
        rad := (Border_Rounded = "on") ? Border_Radius : 0
        this.Frames[hwnd].Place(x, y, w, h, Max(2, Border_Thickness), rad, Border_Opacity, Border_Mode, hwnd)
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
; 按下激活热键后：当前桌面所有窗口按配置比例缩小，每个窗口上方显示一个字母
; 标签条（样式可在 [WinSelect] 配置）。松开热键后标签仍保留，直到按下任意键：
;   字母            -> 还原全部窗口，并把所选窗口移到鼠标所在屏幕中央；
;   数字 + 字母     -> 同上，且按 [WinSelect] SizeMap 调整所选窗口尺寸；
;   其他任意键      -> 直接还原退出。
; 选中即把该字母锁定到该窗口：之后即使在其他桌面，按同一字母也会调取该窗口；
; 锁定期间其他窗口不会复用该字母；窗口关闭后锁定自动释放。
; ------------------------------------------------------------------------------
; On the activation hotkey: every window on the current desktop is scaled down
; by the configured ratio and a letter bar is shown above it. The labels stay
; after the hotkey is released until one key is pressed:
;   letter          -> restore all windows, center the chosen one on the
;                      monitor under the mouse cursor;
;   digit + letter  -> same, and resize per the [WinSelect] SizeMap entry;
;   any other key   -> restore and exit.
; Selecting locks the letter to that window: pressing the same letter later -
; even on another desktop - summons the same window; while locked no other
; window reuses the letter; the lock auto-releases when the window closes.
; ==============================================================================

; ---- 窗口选择模式 / Window-select mode ----
class WinSelect {
    static Active := false
    static Items  := []
    static Locks  := Map()
    static IH     := ""
    static ZOrder := []   ; 进入模式时的层级（上→下）/ z-order on entry (top->bottom)

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
        if (wins.Length = 0) {
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
        if (this.Items.Length = 0) {
            this.Active := false
            this.ZOrder := []
            return
        }

        ; 先平铺所有参与窗口 / Tile all participating windows first
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
        this._Capture()
    }

    ; -- 为选择模式平铺窗口 / Tile windows for the selection overlay --
    static _TileForSelect(hwnds) {
        global CurrentTileGap, Tile_Gap
        if (hwnds.Length = 0)
            return
        MouseGetPos(&mx, &my)
        mon := GetMonitorIndexAtPoint(mx, my)
        MonitorGetWorkArea(mon, &WL, &WT, &WR, &WB)
        BarReserve(mon, &WL, &WT, &WR, &WB)
        SetTileBound(WL, WT, WR, WB)

        W := WR - WL
        H := WB - WT

        g := Tile_Gap
        if (g > 0) {
            WL += g/2, WT += g/2, W -= g, H -= g
        }
        CurrentTileGap := g

        aspect := (H != 0) ? W / H : 1
        if (H > W)
            mode := "Vertical"
        else if (aspect >= 32/9 - 0.15)
            mode := "Ultrawide"
        else
            mode := "Normal"

        if !ApplyCustomLayout(hwnds, WL, WT, W, H, mon) {
            switch mode {
                case "Vertical":  TileVertical(hwnds, WL, WT, W, H)
                case "Ultrawide": TileUltrawide(hwnds, WL, WT, W, H)
                default:          TileNormal(hwnds, WL, WT, W, H)
            }
        }

        CurrentTileGap := 0
        ClearTileBound()
    }

    ; -- 字母标签条 / Build one letter label bar --
    static _MakeLabel(it) {
        global WS_BarColor, WS_TextColor, WS_BarHeight, WS_BarWidth, WS_OffsetY
        global WS_FontSize, WS_Opacity, WS_Rounded, WS_Radius, WS_CornerMode
        global Color_Bg, Color_Active
        bg := (WS_BarColor != "") ? WS_BarColor : Color_Bg
        fg := (WS_TextColor != "") ? WS_TextColor : Color_Active
        try WinGetPos(&x, &y, &w, &h, it.hwnd)
        catch
            return ""
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
            g.SetFont("s" WS_FontSize " w700 c" fg, "Segoe UI")
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
        try ShowWin(hwnd)
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
                if WinExist(it.hwnd)
                    WinMove(it.x, it.y, it.w, it.h, it.hwnd)
            }
        }
        ; 复原层级（不激活），保持各窗口相对上下层关系
        ; Restore z-order without activating, keeping relative stacking
        if (zorder.Length > 0)
            this._RestoreZOrder(zorder)
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
        this._RestoreAll()
    }
}
; ==============================================================================
; 二十、剪贴板 / 编辑器 / 终端 / 电源 / 20. Clipboard / Editor / Terminal / Power
; ==============================================================================

; ---- 剪贴板变更回调 / Clipboard-change callback ----
OnClipboardChanged(dataType) {
    if (dataType != 1)
        return
    RecordClipboard()
}

; ---- 剪贴板历史记录 / Append clipboard text to the history file ----
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

; ---- 剪贴板查看窗口 / Toggle the clipboard-history viewer ----
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

; ---- 启动终端 / Launch the terminal ----
LaunchTerminal(*) {
    global Path_Terminal
    path := Explorer_GetPath()
    try Run('"' . Path_Terminal . '"' . (path ? ' -d "' . path . '"' : ""))
}

; ---- 用编辑器打开选中文件 / Open the selected file in the editor ----
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

; ---- 电源菜单 / Power menu ----
ShowPowerMenu(*) {
    global PowerMenuObj
    global PM_FontSize, PM_Width, PM_Height, PM_Opacity, PM_Rounded, PM_Radius
    if IsObject(PowerMenuObj) {
        PowerMenuObj.Destroy()
        PowerMenuObj := ""
        return
    }
    wsc := PM_Width / 500.0
    hsc := PM_Height / 160.0

    pGui := Gui("+AlwaysOnTop -Caption +ToolWindow +Owner")
    pGui.BackColor := PM_Bg
    pGui.SetFont("s" PM_FontSize " c" . Color_Text, "Arial")
    pGui.Add("Text", "x0 y" Round(15*hsc) " w" Round(500*wsc) " Center c" . Color_Active, "System Power Menu")
    pGui.Add("Text", "x" Round(50*wsc) " y" Round(45*hsc) " w" Round(400*wsc) " h2 0x10")

    AddBtn(x, y, txt, fn, col) {
        btn := pGui.Add("Text"
            , "x" Round(x*wsc) " y" Round(y*hsc) " w" Round(120*wsc) " h" Round(60*hsc) " Center 0x200 +Border cWhite Background" col, txt)
        btn.OnEvent("Click", fn)
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

; ---- 资源管理器选中项 / Selected item in Explorer ----
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

; ---- 资源管理器当前路径 / Current folder of Explorer ----
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
; 二十一、主题切换 / 21. Theme Switching
; ==============================================================================

; ---- 应用主题 / Apply a theme & reload ----
ApplyTheme(themeName, *) {
    IniWrite(themeName, ConfigFile, "General", "ActiveTheme")
    ShowOSD("Theme: " . themeName)
    Sleep(400)
    Reload()
}

; ---- 导出主题到 custom / Export the active theme to [Theme] ----
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
        "Color_BorderUnfocus","BorderUnfocus",
        "PM_Bg",             "PowerMenuBg",
        "PM_BtnShutdown",    "PowerBtnShutdown",
        "PM_BtnSleep",       "PowerBtnSleep",
        "PM_BtnReboot",      "PowerBtnReboot"
    )
    borderMap := Map(
        "WTM_BorderFocusColor",   "FocusColor",
        "WTM_BorderUnfocusColor", "UnfocusColor",
        "Border_FocusColor",      "FocusColor",
        "Border_UnfocusColor",    "UnfocusColor"
    )
    for key, val in palette {
        if nameMap.Has(key)
            IniWrite(val, ConfigFile, "Theme", nameMap[key])
        else if borderMap.Has(key)
            IniWrite(val, ConfigFile, "Border", borderMap[key])
    }
    IniWrite("custom", ConfigFile, "General", "ActiveTheme")
    ShowOSD("Exported -> custom")
    Sleep(400)
    Reload()
}

; ==============================================================================
; 二十二、托盘菜单与退出 / 22. Tray Menu & Exit
; ==============================================================================

; ---- 托盘菜单 / Tray menu setup ----
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
    A_TrayMenu.Add("Show Welcome",        (*) => WelcomeScreen.Show())
    A_TrayMenu.Add("Open Config Folder",  (*) => Run('explorer.exe "' . ConfigDir . '"'))
    A_TrayMenu.Add("Reload Script",       (*) => Reload())
    A_TrayMenu.Add("Restore && Exit",     RestoreAndExit)

    A_IconTip := "AHK WM - Desktop " . CurrentDesktop
}

; ---- 还原并退出 / Restore everything & exit ----
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
; 二十三、外部八方向按钮脚本 / 23. External Eight-Direction Button Scripts
; ==============================================================================

#Include "*i %A_ScriptDir%\Buttons\Top.ahk"
#Include "*i %A_ScriptDir%\Buttons\TopRight.ahk"
#Include "*i %A_ScriptDir%\Buttons\Right.ahk"
#Include "*i %A_ScriptDir%\Buttons\DownRight.ahk"
#Include "*i %A_ScriptDir%\Buttons\Down.ahk"
#Include "*i %A_ScriptDir%\Buttons\DownLeft.ahk"
#Include "*i %A_ScriptDir%\Buttons\Left.ahk"
#Include "*i %A_ScriptDir%\Buttons\TopLeft.ahk"
