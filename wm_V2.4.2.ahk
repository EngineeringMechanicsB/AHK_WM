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
global WTM_Gap

; ---- Border display mode (top|full) + one global refresh interval ----
global Border_RefreshMs := 10
global Border_Drag_Mode := "full"
global Border_Pin_Mode  := "top"
global WTM_BorderMode    := "full"

; ---- Bar auto-hide on fullscreen ----
global Bar_AutoHide   := false    ; from [Bar] AutoHideOnFullscreen
global Bar_FsHidden   := false    ; true while the bar is hidden *because* of fullscreen
global Bar_ShownState := true     ; last applied show/hide state (avoids per-tick churn)

global CurrentTileGap := 0

; ---- Bar rounded corners ----
global Bar_Rounded    := "off"    ; from [Bar] Rounded (on|off)
global Bar_Radius     := 10       ; from [Bar] CornerRadius
global Bar_CornerMode := "bottom" ; from [Bar] CornerMode (all|top|bottom)

; ---- New: tiling gap / GUI rounding / custom layout / window exclusion ----
global Tile_Gap        := 8
global GUI_Rounded     := "on"
global GUI_CornerRadius := 12
; Custom tiling rules: Map(monitorKey -> Map(N -> [{x:{lo,hi}, y:{lo,hi}}, ...]))
; monitorKey is a 1-based monitor index or the wildcard "*".
global LayoutRules     := Map()
global Excl_Titles     := []
global Excl_Classes    := []
global Excl_Processes  := []

; ---- Per-GUI rounded-corner overrides (each falls back to global [GUI]) ----
global Help_Rounded, Help_Radius, PM_Rounded, PM_Radius
global OSD_Rounded, OSD_Radius
global Border_Drag_Rounded, Border_Drag_Radius
global Border_Pin_Rounded, Border_Pin_Radius
global WTM_BorderRounded, WTM_BorderRadius

; ---- Help / Power menu sizing ----
global Help_FontSize := 10, Help_Width := 620, Help_Height := 0, Help_Opacity := 255
global PM_FontSize := 12, PM_Width := 500, PM_Height := 160, PM_Opacity := 255

; ---- All-window-borders mode (toggle) ----
global Color_BorderUnfocus := "555555"

; ---- Tiling outer boundary (bar-reserved work area; protects Bar on negative gap) ----
global TileBound_L := 0, TileBound_T := 0, TileBound_R := 0, TileBound_B := 0
global TileBoundSet := false

; ---- Virtual-desktop hide method & per-desktop focus memory ----
global Desktop_HideMethod := "minimize"     ; "minimize" | "hide"
global DesktopFocus := Map()                 ; desktop index -> last focused hwnd

; ---- Bar instances (new fully-customizable bar system) ----
global Bars := []
global Bar_Cfg := Map()

global HelpGuiObj    := ""
global PowerMenuObj  := ""

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

; Seed Color_BorderUnfocus (used by the all-window-borders mode) into every theme,
; reusing each theme's existing WTM unfocused-border color so no preset is missing it.
for _tname, _tmap in Themes {
    if !_tmap.Has("Color_BorderUnfocus")
        _tmap["Color_BorderUnfocus"] := _tmap.Has("WTM_BorderUnfocusColor") ? _tmap["WTM_BorderUnfocusColor"] : "555555"
}

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

; ---- Lightweight logging (silent; avoids interrupting the user) ----
WMLog(msg) {
    global ConfigDir
    try FileAppend(FormatTime(, "yyyy-MM-dd HH:mm:ss") . "  " . msg . "`r`n"
                 , ConfigDir . "\wm.log", "UTF-8")
}

; ---- GUI rounded corners (unified) ----
; Apply rounded corners to a GUI/HWND after .Show(). RoundWindow uses the global
; [GUI] settings; RoundWindowEx lets a specific GUI override enable/radius.
RoundWindow(guiOrHwnd) {
    global GUI_Rounded, GUI_CornerRadius
    RoundWindowEx(guiOrHwnd, GUI_Rounded, GUI_CornerRadius)
}

RoundWindowEx(guiOrHwnd, enabled, radius, corners := "all") {
    if (enabled != "on")
        return
    hwnd := IsObject(guiOrHwnd) ? guiOrHwnd.Hwnd : guiOrHwnd
    try {
        WinGetPos(, , &w, &h, hwnd)
        if (w <= 0 || h <= 0)
            return
        ; Clamp radius to the half-extent so partial-corner squaring stays correct
        ; even on a thin strip like the bar.
        r := Max(0, radius)
        r := Min(r, w // 2, h // 2)
        d := r * 2                  ; CreateRoundRectRgn takes the ellipse diameter
        if (d <= 0)
            return
        hRgn := DllCall("Gdi32\CreateRoundRectRgn"
            , "Int", 0, "Int", 0, "Int", w + 1, "Int", h + 1
            , "Int", d, "Int", d, "Ptr")

        ; For top/bottom modes, OR a plain rectangle over the side we want to keep
        ; square, turning those two corners back into right angles.
        corners := StrLower(Trim(corners))
        if (corners = "top" || corners = "bottom") {
            if (corners = "top")
                ; keep TOP rounded -> square the bottom: cover the bottom r pixels
                hRect := DllCall("Gdi32\CreateRectRgn"
                    , "Int", 0, "Int", h - r, "Int", w + 1, "Int", h + 1, "Ptr")
            else
                ; keep BOTTOM rounded -> square the top: cover the top r pixels
                hRect := DllCall("Gdi32\CreateRectRgn"
                    , "Int", 0, "Int", 0, "Int", w + 1, "Int", r, "Ptr")
            DllCall("Gdi32\CombineRgn", "Ptr", hRgn, "Ptr", hRgn, "Ptr", hRect, "Int", 2) ; RGN_OR
            DllCall("Gdi32\DeleteObject", "Ptr", hRect)
        }

        ; Ownership transfers to the system on success; no manual release needed.
        DllCall("User32\SetWindowRgn", "Ptr", hwnd, "Ptr", hRgn, "Int", 1)
    }
}

; ---- Window exclusion rules ----
SplitExcludeList(str) {
    out := []
    for part in StrSplit(str, ";") {
        part := Trim(part)
        if (part != "")
            out.Push(part)
    }
    return out
}

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

; ---- Custom tiling layout: parsing & application ----
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

; Parse the whole rule string -> Map(monitorKey -> Map(N -> [{x,y}, ...])).
; New 5-field format:  M,N,I,X,Y   (M = monitor index or "*" wildcard).
; Legacy 4-field format:  N,I,X,Y  is accepted and treated as M = "*".
; Any invalid (M,N) group is dropped wholesale (with a log) and falls back to default.
ParseLayoutRules(str) {
    result := Map()
    str := Trim(str)
    if (str = "")
        return result

    groups := Map()    ; "M|N" -> Map(I -> {x, y})
    counts := Map()    ; "M|N" -> N
    monKey := Map()    ; "M|N" -> M
    bad    := Map()    ; "M|N" -> true

    for clause in StrSplit(str, ";") {
        clause := Trim(clause)
        if (clause = "")
            continue
        f := StrSplit(clause, ",")
        ; Normalize to M,N,I,X,Y: a 4-field clause is legacy (apply to all monitors).
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
        } catch as e {
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

; Resolve the custom rule set for a monitor + window count.
; Priority: exact monitor index -> "*" wildcard -> "" (no rule, use default tiling).
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

; Apply a matching custom layout for the given monitor; return true if applied.
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

; ---- Hotkey notation conversion ----
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
OnError(WM_OnError)
WM_OnError(err, mode) {
    try WMLog("Runtime: " . (IsObject(err) ? err.Message : err))
    return true     ; 抑制默认错误弹窗
}

isFirstRun := !FileExist(ConfigFile)

LoadOrInitConfig()

Loop DesktopCount
    Desktops[A_Index] := []

if !DirExist(Path_Output)
    DirCreate(Path_Output)
if !DirExist(Path_Button)
    DirCreate(Path_Button)

buttonsCreated := InitializeButtons()
if isFirstRun
    WelcomeScreen.Show()
else if buttonsCreated
    Reload()

CreateStatusBar()
UpdateStatusBar()
UpdateClockAndProgress()
SetTimer(UpdateClockAndProgress, 1000)
SetupTrayIcon()
OnClipboardChange(OnClipboardChanged)
RegisterAllHotkeys()

; ---- Hotkey registration ----
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
    } catch as e {
        WMLog("Hotkey register failed [" key "=" combo "]: " e.Message)
        return false
    }
}

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
        try Hotkey("~Space Up",   PieMenuExecute)
        try Hotkey("~RButton Up", PieMenuExecute)
    }

    RegHotkey("DragMove",   DragMoveHandler)
    RegHotkey("DragResize", DragResizeHandler)

    ; ---- WTM-mode hotkeys ----
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

CloseWindowDispatch(*) {
    if WTM.Active
        WTM.CloseFocused()
    else
        CloseWindowUnderMouse()
}

; ---- Config helper: new section/key first, then legacy fallbacks, then default ----
; fallbacks is a list of [section, key] pairs tried in order. This lets an old
; config keep working while the file is migrated to the new [section] structure.
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

; Parse the unified custom_items list (';'-separated, ordered). When custom_items is
; empty, fall back to the legacy custom_icon then custom_text so old configs still show.
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

; If the config still uses the old [section] names, copy values into the new structure
; (raw strings, so no unit conversion is lost), merge legacy custom items, drop the
; legacy sections, and keep a .bak. A no-op once the file is already in the new layout.
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

    ; Merge legacy custom_icon / custom_text into custom_items (icon first, then text).
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
; Theme name. Built-in examples:
; custom, nord, tokyonight, dracula, gruvbox, monokai, solarized-dark,
; solarized-light, catppuccin-mocha, catppuccin-latte, onedark, ayu-dark,
; github-dark, rose-pine, everforest, kanagawa, material-deep, nightfox,
; palenight, horizon, oxocarbon.
ActiveTheme=custom

[Theme]
; Hex colors without '#'.
Background=0e050f
Text=e5e9f0
Active=744da9
Task=CF8DC9
BorderDrag=A020F0
BorderPin=FF5555
; Border color for unfocused windows when all-window borders are enabled.
BorderUnfocus=666666
PowerMenuBg=2E3440
PowerBtnShutdown=B48EAD
PowerBtnSleep=5E81AC
PowerBtnReboot=BF616A

[Paths]
; Resource/output paths and launch targets.
ButtonDir=Buttons
OutputDir=C:\Users\Administrator\Documents
VimPath=C:\Windows\system32\notepad.exe
TerminalExe=C:\Windows\system32\cmd.exe
; Editor window position and size, in screen percentage.
EditorXPct=20
EditorYPct=0
EditorWidthPct=52
EditorHeightPct=74

[Desktop]
; Virtual desktop count: 1-9.
Count=9
; Inactive desktop window handling: minimize | hide (hide reduces flicker).
HideMethod=minimize

[Bar]
; Status bar geometry.
HeightPct=3
Opacity=78
FontSize=10
MonitorIdx=1
; Widget visibility.
desktops=true
time=true
date=true
progress=true
; AutoHotkey FormatTime patterns.
time_format=HH:mm
date_format=yyyy-MM-dd
; Ordered custom items separated by ';'. Reference them in 'layout' as
; custom_1, custom_2, ... custom_n. May be text, symbols, icons, or emoji.
custom_items=Edit Configuration file to hide
; Comma-separated desktop names. Falls back to numbers if count mismatches.
desktop_labels=
; Current desktop label wrapper.
current_desktop_left=[
current_desktop_right=]
; Desktop display: all | current | occupied.
desktop_display_mode=all
; Bar edge: top | bottom. Distance from screen edge in pixels.
position=top
offset=0
; Multi-bar format: M:pos:offset;...  M=monitor index or '*'.
; Example: instances=1:top:0;2:bottom:8
instances=
; Element layout: element:span;...  Span uses [Tiling] fraction syntax.
; Elements: desktops, time, date, progress, custom_1..n.
layout=custom_1:(2-5)/10;desktops:(1-3)/20;date:(18-19)/20;time:20/20
; Hide the bar while a fullscreen window exists on the current desktop.
AutoHideOnFullscreen=off
; CornerMode: all (four corners) | top (top two only) | bottom (bottom two only).
Rounded=off
CornerRadius=10
CornerMode=bottom

[Border]
; One refresh interval (ms) shared by all border drawing.
RefreshMs=10
; Drag/focus border. Mode: top (top edge only) | full (all sides).
DragEnable=on
DragMode=full
DragThickness=15
DragOffset=0
DragOffsetTop=5
DragOpacity=70
DragRounded=on
DragRadius=10
; Pinned-window indicator. Highest priority: a pinned window draws no other
; border. Mode: top | full.
PinMode=top
PinThickness=10
PinOffset=0
PinOffsetTop=5
PinOpacity=78

[Tiling]
; Smart tiling gap in pixels (may be negative; outer work area stays protected).
Gap=8
; Custom tiling rules: M,N,I,X,Y;...  M=monitor index or '*', N=window count,
; I=window index, X/Y=area span (1=full, a/b=segment, (a-c)/b=multi-segment).
; Priority: exact monitor > '*' > built-in default. Legacy N,I,X,Y => '*',N,I,X,Y.
Rules=1,3,1,1/2,1;1,3,2,2/2,1/2;1,3,3,2/2,2/2;1,5,1,(2-4)/5,1;1,5,2,1/5,1/2;1,5,3,1/5,2/2;1,5,4,5/5,(1-2)/3;1,5,5,5/5,3/3;

[WTM]
; Window Tree Manager. BorderMode: top | full.
BorderMode=full
BorderFocusColor=A020F0
BorderUnfocusColor=555555
BorderThickness=8
BorderOffset=0
BorderOpacity=80
SizeStep=3
; Gap may be negative; windows can overlap but never cover bars.
Gap=10
RoundedCorners=on
CornerRadius=10

[PieMenu]
; Radial menu size, center dead zone, transparency, and font sizes.
SizePct=28
CenterZonePct=27
Opacity=78
FontSize=14
FontSizeActive=22

[GUI]
;OSD Help menu and power menu rounding defaults.
RoundedCorners=on
CornerRadius=12
; Help menu (Height=0 = auto). Power menu. On-screen display.
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
; WorkTime / AllDay progress.
Mode=off
WeekendBar=off
; WorkStart / WorkEnd format: HHMM.
WorkStart=0900
WorkEnd=1745
; TaskTimes format: Weekday_Start_End;...  Weekday 1=Mon..7=Sun, time HHMM.
TaskTimes=1_1200_1300;2_1200_1300;3_1200_1300;4_1200_1300;5_1200_1300;6_1200_1300;7_1200_1300;2_1700_1745;3_0900_0920;

[Exclude]
; Matching windows are ignored by tiling / WTM.  Multiple entries use ';'.
; Title: contains by default; re:xxx = regex; =xxx = exact.
Titles=Picture-in-Picture
; Class name: exact, case-insensitive.
Classes=
; Process exe name: exact, case-insensitive. Example: notepad.exe
Processes=

;--------------------------------------------------------------------------
; Hotkeys - use natural names joined by '+': Alt / Shift / Ctrl / Win
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
; Under testing
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

; Under testing
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

        try {
            FileAppend(DefaultIni, ConfigFile, "UTF-8")
        } catch as e {
            MsgBox("Failed to create config file: " . e.Message)
            ExitApp
        }
    }

    ; Migrate an old-structure config to the new [section] layout (backs up to .bak).
    MigrateLegacyConfig()

    ActiveTheme := IniRead(ConfigFile, "General", "ActiveTheme", "custom")

    ; ---- Theme colors ([Theme], legacy [Colors]) ----
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
    ; All-window-borders mode: unfocused border color (focused reuses BorderDrag).
    Color_BorderUnfocus := CfgRead("Theme", "BorderUnfocus",  "555555", ["Colors","BorderUnfocus"])

    ; ---- Bar geometry ([Bar], legacy [StatusBar]) ----
    Bar_Height       := Pct2PxH(Integer(CfgRead("Bar", "HeightPct",  "3",  ["StatusBar","HeightPct"])))
    Bar_Transparent  := Pct2Alpha(Integer(CfgRead("Bar", "Opacity",  "78", ["StatusBar","Opacity"])))
    Bar_FontSize     := Integer(CfgRead("Bar", "FontSize",   "10", ["StatusBar","FontSize"]))
    Bar_MonitorIdx   := Integer(CfgRead("Bar", "MonitorIdx", "1",  ["StatusBar","MonitorIdx"]))
	Bar_Rounded    := StrLower(Trim(IniRead(ConfigFile, "Bar", "Rounded", "off")))
	Bar_Radius     := Integer(IniRead(ConfigFile, "Bar", "CornerRadius", 10))
	Bar_CornerMode := StrLower(Trim(IniRead(ConfigFile, "Bar", "CornerMode", "bottom")))

    ; ---- Pie menu ([PieMenu]) ----
    Pie_Size           := Pct2PxMin(Integer(IniRead(ConfigFile, "PieMenu", "SizePct",       "28")))
    Pie_Radius         := Pie_Size / 2
    Pie_CenterZone     := Round(Pie_Radius * Integer(IniRead(ConfigFile, "PieMenu", "CenterZonePct", "27")) / 100)
    Pie_Transparent    := Pct2Alpha(Integer(IniRead(ConfigFile, "PieMenu", "Opacity",       "78")))
    Pie_FontSize       := Integer(IniRead(ConfigFile, "PieMenu", "FontSize",       "14"))
    Pie_FontSizeActive := Integer(IniRead(ConfigFile, "PieMenu", "FontSizeActive", "22"))

    ; ---- OSD ([GUI] OSD*, legacy [OSD]) ----
    OSD_Height       := Pct2PxH(Integer(CfgRead("GUI", "OSDPositionPct", "80", ["OSD","PositionPct"])))
    OSD_Transparent  := Pct2Alpha(Integer(CfgRead("GUI", "OSDOpacity",   "78", ["OSD","Opacity"])))
    OSD_FontSize     := Integer(CfgRead("GUI", "OSDFontSize", "20", ["OSD","FontSize"]))

    ; ---- Borders: one global refresh + per-type mode ([Border], legacy [BorderDrag]/[BorderPin]) ----
    Border_RefreshMs := Max(1, Integer(IniRead(ConfigFile, "Border", "RefreshMs", "10")))

    Border_Drag_Enable      := CfgRead("Border", "DragEnable", "on", ["BorderDrag","Enable"])
    Border_Drag_Mode        := StrLower(IniRead(ConfigFile, "Border", "DragMode", "full"))
    if !(Border_Drag_Mode = "top" || Border_Drag_Mode = "full")
        Border_Drag_Mode := "full"
    Border_Drag_Thickness   := Pct2Border(Integer(CfgRead("Border", "DragThickness", "15", ["BorderDrag","Thickness"])))
    Border_Drag_Offset      := Pct2Border(Integer(CfgRead("Border", "DragOffset",    "0",  ["BorderDrag","Offset"])))
    Border_Drag_OffsetTop   := Pct2Border(Integer(CfgRead("Border", "DragOffsetTop", "5",  ["BorderDrag","OffsetTop"])))
    Border_Drag_Transparent := Pct2Alpha(Integer(CfgRead("Border", "DragOpacity",   "70", ["BorderDrag","Opacity"])))

    Border_Pin_Mode        := StrLower(IniRead(ConfigFile, "Border", "PinMode", "top"))
    if !(Border_Pin_Mode = "top" || Border_Pin_Mode = "full")
        Border_Pin_Mode := "top"
    Border_Pin_Thickness   := Pct2Border(Integer(CfgRead("Border", "PinThickness", "10", ["BorderPin","Thickness"])))
    Border_Pin_Offset      := Pct2Border(Integer(CfgRead("Border", "PinOffset",    "0",  ["BorderPin","Offset"])))
    Border_Pin_OffsetTop   := Pct2Border(Integer(CfgRead("Border", "PinOffsetTop", "5",  ["BorderPin","OffsetTop"])))
    Border_Pin_Transparent := Pct2Alpha(Integer(CfgRead("Border", "PinOpacity",   "78", ["BorderPin","Opacity"])))

    ; ---- WTM ([WTM]) ----
    WTM_BorderMode         := StrLower(IniRead(ConfigFile, "WTM", "BorderMode", "full"))
    if !(WTM_BorderMode = "top" || WTM_BorderMode = "full")
        WTM_BorderMode := "full"
    WTM_BorderFocusColor   := IniRead(ConfigFile, "WTM", "BorderFocusColor",   "A020F0")
    WTM_BorderUnfocusColor := IniRead(ConfigFile, "WTM", "BorderUnfocusColor", "555555")
    WTM_BorderThickness    := Pct2Border(Integer(IniRead(ConfigFile, "WTM", "BorderThickness", "8")))
    WTM_BorderOffset       := Pct2Border(Integer(IniRead(ConfigFile, "WTM", "BorderOffset",    "0")))
    WTM_BorderOpacity      := Pct2Alpha(Integer(IniRead(ConfigFile, "WTM", "BorderOpacity",   "80")))
    WTM_SizeStep           := Integer(IniRead(ConfigFile, "WTM", "SizeStep", "3"))
    ; Gap may be negative (windows draw closer / overlap); not clamped to >= 0.
    WTM_Gap                := Integer(IniRead(ConfigFile, "WTM", "Gap", "10"))

    ; ---- Tiling ([Tiling], legacy [Layout]) ----
    ; Gap may be negative (windows draw closer / overlap); not clamped to >= 0.
    Tile_Gap         := Integer(CfgRead("Tiling", "Gap", "8", ["Layout","Gap"]))
    LayoutRules      := ParseLayoutRules(CfgRead("Tiling", "Rules", "", ["Layout","Rules"]))

    Excl_Titles      := SplitExcludeList(IniRead(ConfigFile, "Exclude", "Titles",    ""))
    Excl_Classes     := SplitExcludeList(IniRead(ConfigFile, "Exclude", "Classes",   ""))
    Excl_Processes   := SplitExcludeList(IniRead(ConfigFile, "Exclude", "Processes", ""))

    ; ---- GUI rounding + per-GUI overrides ([GUI], legacy [GUI]/[HelpMenu]/[PowerMenu]/[OSD]) ----
    GUI_Rounded      := IniRead(ConfigFile, "GUI", "RoundedCorners", "on")
    GUI_CornerRadius := Max(0, Integer(IniRead(ConfigFile, "GUI", "CornerRadius", "12")))

    ; Per-GUI rounded-corner overrides. Each defaults to the global [GUI] values so a
    ; section that omits the keys simply inherits the global setting.
    Help_Rounded := CfgRead("GUI", "HelpRounded", GUI_Rounded, ["HelpMenu","RoundedCorners"])
    Help_Radius  := Max(0, Integer(CfgRead("GUI", "HelpRadius", GUI_CornerRadius, ["HelpMenu","CornerRadius"])))
    PM_Rounded   := CfgRead("GUI", "PowerRounded", GUI_Rounded, ["PowerMenu","RoundedCorners"])
    PM_Radius    := Max(0, Integer(CfgRead("GUI", "PowerRadius", GUI_CornerRadius, ["PowerMenu","CornerRadius"])))
    OSD_Rounded  := CfgRead("GUI", "OSDRounded", GUI_Rounded, ["OSD","RoundedCorners"])
    OSD_Radius   := Max(0, Integer(CfgRead("GUI", "OSDRadius", GUI_CornerRadius, ["OSD","CornerRadius"])))

    Border_Drag_Rounded := CfgRead("Border", "DragRounded", GUI_Rounded, ["BorderDrag","RoundedCorners"])
    Border_Drag_Radius  := Max(0, Integer(CfgRead("Border", "DragRadius", "10", ["BorderDrag","CornerRadius"])))
    Border_Pin_Rounded  := "off"   ; pin strip: never rounded
    Border_Pin_Radius   := 0
    WTM_BorderRounded   := IniRead(ConfigFile, "WTM", "RoundedCorners", GUI_Rounded)
    WTM_BorderRadius    := Max(0, Integer(IniRead(ConfigFile, "WTM", "CornerRadius", "10")))

    ; Help menu sizing (FontSize/Opacity exact; Width/Height best-effort scaling).
    Help_FontSize := Integer(CfgRead("GUI", "HelpFontSize", "10",  ["HelpMenu","FontSize"]))
    Help_Width    := Integer(CfgRead("GUI", "HelpWidth",    "620", ["HelpMenu","Width"]))
    Help_Height   := Integer(CfgRead("GUI", "HelpHeight",   "0",   ["HelpMenu","Height"]))
    Help_Opacity  := Integer(CfgRead("GUI", "HelpOpacity",  "255", ["HelpMenu","Opacity"]))

    ; Power menu sizing.
    PM_FontSize := Integer(CfgRead("GUI", "PowerFontSize", "12",  ["PowerMenu","FontSize"]))
    PM_Width    := Integer(CfgRead("GUI", "PowerWidth",    "500", ["PowerMenu","Width"]))
    PM_Height   := Integer(CfgRead("GUI", "PowerHeight",   "160", ["PowerMenu","Height"]))
    PM_Opacity  := Integer(CfgRead("GUI", "PowerOpacity",  "255", ["PowerMenu","Opacity"]))

    ; ---- Virtual desktops ([Desktop], legacy [Desktops]) ----
    DesktopCount := Integer(CfgRead("Desktop", "Count", "9", ["Desktops","Count"]))
    if (DesktopCount < 1)
        DesktopCount := 1
    if (DesktopCount > 9)
        DesktopCount := 9                ; switch hotkeys map to digits 1-9
    Desktop_HideMethod := StrLower(CfgRead("Desktop", "HideMethod", "minimize", ["Desktops","HideMethod"]))
    if !(Desktop_HideMethod = "minimize" || Desktop_HideMethod = "hide")
        Desktop_HideMethod := "minimize"

    ; ---- Bar configuration (new fully-customizable bar system) ----
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
    Bar_Cfg["offset"]       := Integer(IniRead(ConfigFile, "Bar", "offset", "0"))
    Bar_Cfg["instances"]    := IniRead(ConfigFile, "Bar", "instances", "")
    Bar_Cfg["layout"]       := ParseBarLayout(IniRead(ConfigFile, "Bar", "layout", ""))

    ; Unified custom items list. Legacy custom_icon/custom_text are merged (icon, text)
    ; only when custom_items is absent, so old configs keep showing their content.
    Bar_Cfg["custom_items"] := ParseCustomItems(
        IniRead(ConfigFile, "Bar", "custom_items", ""),
        IniRead(ConfigFile, "Bar", "custom_icon",  ""),
        IniRead(ConfigFile, "Bar", "custom_text",  ""))

    ; Auto-hide the bar while a fullscreen window exists on the current desktop.
    Bar_AutoHide := BarShown(IniRead(ConfigFile, "Bar", "AutoHideOnFullscreen", "off"))

    barLabelsRaw := IniRead(ConfigFile, "Bar", "desktop_labels", "")
    barLabels := []
    if (Trim(barLabelsRaw) != "") {
        for lbl in StrSplit(barLabelsRaw, ",")
            barLabels.Push(Trim(lbl))
    }
    Bar_Cfg["desktop_labels"] := barLabels

    ; ---- Paths ([Paths]; editor position legacy [VimLayout]) ----
    bDirTemp        := IniRead(ConfigFile, "Paths", "ButtonDir",  "Buttons")
    Path_Button     := (bDirTemp ~= "^[a-zA-Z]:") ? bDirTemp : (A_ScriptDir . "\" . bDirTemp)
    Path_Output     := IniRead(ConfigFile, "Paths", "OutputDir",   "C:\Users\Administrator\Documents")
    Path_OutputFile := Path_Output . "\CB.txt"
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

    HK := Map()
    hkKeys := ["Help","Exit","Reload",
               "DesktopSwitchPrefix","DesktopMovePrefix","DesktopMoveSwitchPrefix",
               "TileSmart","GatherAll","TogglePin","ToggleBar","SaveLayout","RestoreLayout",
               "CloseWindow","CloseWindowAlt","ToggleMaximize","ToggleTop","HideWindow",
               "ToggleAllBorders",
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
        "ToggleTop","Alt+T","HideWindow","Alt+W","ToggleAllBorders","Alt+B",
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

; ---- DWM visible rect ----
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
        try SetTimer(PieMenu.TimerFn, 0)
        try {
            if IsObject(PieMenu.GuiObj)
                PieMenu.GuiObj.Destroy()
        }
    }
    try {
        if IsObject(OSD.GuiObj) {
            OSD.GuiObj.Destroy()
            OSD.GuiObj := 0
        }
    }
    try DragBorder.Destroy()
}

; ---- Help GUI ----
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

    ; Two independent scales: font scale (fsc) honors the configured FontSize and drives
    ; text + vertical rhythm; width scale (wsc) stretches the columns horizontally.
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

; ---- Welcome screen ----
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
            , "V2.4.2  ::  AutoHotkey v2")

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
        RoundWindowEx(g, OSD_Rounded, OSD_Radius)

        this.GuiObj := g
        this.Timer  := () => (IsObject(OSD.GuiObj) ? (OSD.GuiObj.Destroy(), OSD.GuiObj := 0) : 0)
        SetTimer(this.Timer, -duration)
    }
}
ShowOSD(text) => OSD.Show(text)

; ==============================================================================
;  BorderFrame - a single hollow-frame border window (replaces the old 4-rect
;  approach). One GUI per bordered window; its region is an outer rounded rect
;  minus an inner rounded rect, so the frame keeps clean, unbroken rounded
;  corners. Radius 0 yields a sharp rectangular frame (no visual/perf change).
; ==============================================================================
class BorderFrame {
    Gui   := ""
    Color := ""
    LastW := -1, LastH := -1, LastT := -1, LastR := -1
    LastMode := ""

    __New(color, opacity) {
        ; Not +AlwaysOnTop: WTM / all-window borders sit just above their own target
        ; window in the normal Z order (see Place) instead of floating over everything.
        g := Gui("-Caption +ToolWindow +E0x20 -DPIScale")
        g.BackColor := color
        g.Show("NoActivate x-3000 y-3000 w10 h10")
        try WinSetTransparent(opacity, g.Hwnd)
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

    ; Resolve SetWindowPos hwndInsertAfter:
    ;   -1            -> HWND_TOPMOST (drag border: intentionally on top while dragging)
    ;    0            -> HWND_TOP
    ;   window handle -> sit immediately above that target window in the normal Z order
    _ZOrder(insertAfter) {
        if (insertAfter = -1 || insertAfter = 0)
            return insertAfter
        prev := DllCall("GetWindow", "Ptr", insertAfter, "UInt", 3, "Ptr")   ; GW_HWNDPREV
        return prev ? prev : 0
    }

    ; Position the border around the given rect. mode "full" draws a hollow frame on all
    ; sides; mode "top" draws a single solid strip along the top edge. insertAfter sets
    ; Z order (see _ZOrder).
    Place(x, y, w, h, thickness, radius, opacity, mode := "full", insertAfter := -1) {
        if !IsObject(this.Gui)
            return
        t   := Max(1, Round(thickness))
        ins := this._ZOrder(insertAfter)
        if (mode = "top") {
            ww := Round(Max(t, w))
            try DllCall("SetWindowPos", "Ptr", this.Gui.Hwnd, "Ptr", ins
                , "Int", Round(x), "Int", Round(y), "Int", ww, "Int", t
                , "UInt", 0x10 | 0x40)   ; SWP_NOACTIVATE | SWP_SHOWWINDOW
            this._ApplyTopRegion(ww, t)
            return
        }
        w := Round(Max(t*2 + 1, w)), h := Round(Max(t*2 + 1, h))
        try DllCall("SetWindowPos", "Ptr", this.Gui.Hwnd, "Ptr", ins
            , "Int", Round(x), "Int", Round(y), "Int", w, "Int", h
            , "UInt", 0x10 | 0x40)
        this._ApplyRegion(w, h, t, Max(0, Round(radius)))
    }

    ; Top mode: the whole strip-sized window is solid; clear any prior hollow region.
    _ApplyTopRegion(w, t) {
        if (this.LastMode = "top" && w = this.LastW && t = this.LastT)
            return
        this.LastMode := "top", this.LastW := w, this.LastH := t, this.LastT := t, this.LastR := 0
        try DllCall("User32\SetWindowRgn", "Ptr", this.Gui.Hwnd, "Ptr", 0, "Int", 1)
    }

    _ApplyRegion(w, h, t, radius) {
        ; Skip region rebuilds when geometry is unchanged (cheap drag-loop updates).
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
        DllCall("Gdi32\CombineRgn", "Ptr",outer, "Ptr",outer, "Ptr",inner, "Int",4)   ; RGN_DIFF
        DllCall("Gdi32\DeleteObject", "Ptr", inner)
        ; SetWindowRgn takes ownership of 'outer'; do not delete it here.
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

; ---- Drag border (now a single rounded frame) ----
class DragBorder {
    static Frame := ""

    static Show() {
        if (Border_Drag_Enable != "on")
            return
        this.Destroy()
        this.Frame := BorderFrame(Border_Drag_Color, Border_Drag_Transparent)
    }

    static Update(hwnd) {
        if !IsObject(this.Frame)
            return
        if !hwnd || !WinExist(hwnd)
            return
        if !GetWindowVisualRect(hwnd, &x, &y, &w, &h)
            return
        o  := Border_Drag_Offset
        ot := Border_Drag_OffsetTop
        x -= o, y -= (o + ot), w += 2*o, h += 2*o + ot
        rad := (Border_Drag_Rounded = "on") ? Border_Drag_Radius : 0
        ; Drag border stays HWND_TOPMOST (-1) so it is clearly visible while dragging.
        this.Frame.Place(x, y, w, h, Border_Drag_Thickness, rad, Border_Drag_Transparent, Border_Drag_Mode, -1)
    }

    static Destroy() {
        if IsObject(this.Frame)
            this.Frame.Destroy()
        this.Frame := ""
    }
}

; ---- Pinned border ----
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
            ; Pin border is highest priority and stays HWND_TOPMOST (-1); never rounded.
            frame.Place(x, y, w, h, t, 0, Border_Pin_Transparent, Border_Pin_Mode, -1)
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
; Hide / show a window according to the configured method:
;   "minimize" (default) -> WinMinimize / WinRestore
;   "hide"               -> raw ShowWindow SW_HIDE / SW_SHOWNA (no taskbar flicker)
; Raw DllCalls on the explicit HWND avoid needing DetectHiddenWindows.
HideWin(hwnd) {
    global Desktop_HideMethod
    if (Desktop_HideMethod = "hide"){
        try DllCall("ShowWindow", "Ptr", hwnd, "Int", 0)    ; SW_HIDE
	}
    else{
        try WinMinimize(hwnd)
		}
}
ShowWin(hwnd) {
    global Desktop_HideMethod
    if (Desktop_HideMethod = "hide"){
        try DllCall("ShowWindow", "Ptr", hwnd, "Int", 8)    ; SW_SHOWNA (show, no activate)
	}
    else{
        try WinRestore(hwnd)
	}
}

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
        AllBorders.DestroyAll()       ; clear borders so none linger on the old desktop
    DestroyTransientGuis()

    ; Remember which window was focused on the desktop we are leaving.
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

    ; Restore focus to whatever was active on the target desktop, so switching away and
    ; back keeps the same focused window instead of letting Windows pick arbitrarily.
    if (DesktopFocus.Has(target) && DesktopFocus[target] && WinExist(DesktopFocus[target]))
        try WinActivate(DesktopFocus[target])

    if wasWTMActive
        WTM.OnDesktopSwitched()
    if AllBorders.Active
        AllBorders.Rebuild()          ; redraw borders for the new desktop's windows
}

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

MoveAndSwitch(target, *) {
    MoveWindowToDesktop(target)
    SwitchDesktop(target)
    ShowOSD("Move And Switch -> " . target)
}

; ==============================================================================
;  Status Bar - fully customizable. A BarInstance is one strip on one monitor
;  edge (top/bottom/left/right). Multiple instances may exist (one per monitor).
;  Widgets, formats, desktop labels, display mode, position, offset and the
;  internal element layout are all driven by the [Bar] config (see Bar_Cfg).
; ==============================================================================

; True unless the value reads as an "off" sentinel; used for custom_text/icon content.
BarShown(str) {
    s := StrLower(Trim(str))
    return !(s = "" || s = "false" || s = "off" || s = "0")
}
BarFlag(key) {
    global Bar_Cfg
    return (Bar_Cfg.Has(key) && Bar_Cfg[key])
}

; Parse "element:expr;..." into Map(element -> {lo,hi}) reusing ParseAxis fractions.
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
        } catch as e {
            WMLog("Bar layout segment invalid (" e.Message "): " clause)
        }
    }
    return m
}

; ---- Work-time helpers (shared by every bar's progress widget) ----
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

class BarInstance {
    Mon := 1, Pos := "top", Offset := 0, Thick := 30
    Gui := "", Visible := true
    DesktopsCtrl := "", TimeCtrl := "", DateCtrl := "", Progress := ""
    ProgX := 0, ProgY := 0, ProgW := 0

    __New(mon, pos, offset) {
        this.Mon := mon, this.Pos := pos, this.Offset := offset
        this.Build()
    }

    IsHorizontal() => (this.Pos = "top" || this.Pos = "bottom")

    ; Resolve an element's main-axis segment {lo,hi}: layout override else default.
    ; Legacy aliases (custom_1<-custom_icon, custom_2<-custom_text) let layouts written
    ; for the old split custom_text/custom_icon config keep applying after migration.
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

	_LineHeight() {
	    global Bar_FontSize
	    px := Bar_FontSize * A_ScreenDPI / 72
	    return Round(px * 1.4) + 2
	}

    _Opt(x, y, w, h, align) {
        return Format("x{} y{} w{} h{} BackgroundTrans {}", Round(x), Round(y), Round(w), Round(h), align)
    }

    Build() {
        global Color_Bg, Color_Active, Bar_FontSize, Bar_Height, Bar_Transparent
        global Bar_Rounded, Bar_Radius, Bar_CornerMode
        if (this.Mon < 1 || this.Mon > MonitorGetCount())
            this.Mon := 1
        MonitorGet(this.Mon, &mL, &mT, &mR, &mB)
        monW := mR - mL

        ; Bar thickness: at least one line of text plus padding.
        lineH := this._LineHeight()
        thick := Bar_Height
        minThick := Max(lineH + 4, Round(Bar_FontSize * 2 + 5))
        if (thick < minThick)
            thick := minThick
        this.Thick := thick
        off := this.Offset

        ; Bar only supports top / bottom (a full-width horizontal strip).
        if (this.Pos = "bottom")
            bx := mL, by := mB - thick - off
        else
            this.Pos := "top", bx := mL, by := mT + off
        bw := monW, bh := thick

        g := Gui("-Caption +AlwaysOnTop +ToolWindow +Owner +E0x08000000 -DPIScale")
        g.BackColor := Color_Bg
        g.SetFont("s" Bar_FontSize " w600 c" Color_Active, "Segoe UI")
        this.Gui := g

        this._BuildElements(bw, bh, true)

        g.Show(Format("x{} y{} w{} h{} NoActivate", bx, by, bw, bh))
        WinSetTransparent(Bar_Transparent, g.Hwnd)
        ; Optional rounded corners for the bar (all / top / bottom).
        RoundWindowEx(g, Bar_Rounded, Bar_Radius, Bar_CornerMode)
        this.UpdateDesktops()
    }

    _BuildElements(L, T, horiz) {
        global Bar_Cfg, Bar_FontSize
        g := this.Gui
        fontH := this._LineHeight()
        pad := 6

        items := Bar_Cfg["custom_items"]
        elements := []
        if BarFlag("desktops")
            elements.Push("desktops")
        ; Each non-empty custom item is referenced as custom_1, custom_2, ... custom_n.
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
                    ; custom_N -> render the Nth unified custom item (text/icon/emoji).
                    if RegExMatch(el, "^custom_(\d+)$", &mm) {
                        n := Integer(mm[1])
                        txt := (n >= 1 && n <= items.Length) ? items[n] : ""
                        g.Add("Text", this._Opt(cx, cy, cw, ch, "Center"), txt)
                    }
            }
        }
    }

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
            lbl := (i <= labels.Length) ? labels[i] : (i "")   ; robust fallback to number
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

    UpdateClock(pct) {
        global Bar_Cfg
        if IsObject(this.TimeCtrl)
            try this.TimeCtrl.Value := FormatTime(, Bar_Cfg["time_format"])
        if IsObject(this.DateCtrl)
            try this.DateCtrl.Value := FormatTime(, Bar_Cfg["date_format"])
        if IsObject(this.Progress)
            try this.Progress.Value := Integer(pct)
    }

    Show()    => (this.Gui ? this.Gui.Show("NoActivate") : 0)
    Hide()    => (this.Gui ? this.Gui.Hide() : 0)
    Destroy() {
        if IsObject(this.Gui)
            try this.Gui.Destroy()
        this.Gui := ""
    }
}

; Resolve the configured bar instances -> [{mon,pos,offset}, ...].
; Falls back to a single legacy top bar (from [StatusBar]) when no spec is given.
; At most one bar per monitor (extra entries are warned and ignored).
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
            ; Only top / bottom are supported; anything else falls back to top.
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

; True when hwnd belongs to any bar (so layout/desktop logic can skip bars).
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

; Subtract every visible bar on a monitor from a work-area rect (direction-aware),
; so window tiling never overlaps a bar. Replaces the old single-bar reservation.
BarReserve(monIdx, &L, &T, &R, &B) {
    global Bars, Bar_ShownState
    ; Reserve only for bars that are actually on screen (covers manual toggle + auto-hide).
    if (!IsSet(Bars) || !Bar_ShownState)
        return
    margin := 5
    for b in Bars {
        if (b.Mon != monIdx)
            continue
        reserve := b.Thick + b.Offset + margin
        switch b.Pos {
            case "bottom": B -= reserve
            default:       T += reserve   ; top
        }
    }
}

DestroyAllBars() {
    global Bars
    if !IsSet(Bars)
        return
    for b in Bars
        try b.Destroy()
    Bars := []
}

CreateStatusBar() {
    global Bars, Bar_ShownState
    DestroyAllBars()
    Bars := []
    for inst in BarInstances() {
        try Bars.Push(BarInstance(inst.mon, inst.pos, inst.offset))
        catch as e
            WMLog("Bar build failed (mon " inst.mon "): " e.Message)
    }
    Bar_ShownState := true        ; freshly built bars are shown; re-apply auto-hide below
    ApplyBarVisibility()
    UpdateStatusBar()
}

UpdateStatusBar() {
    global Bars
    if !IsSet(Bars)
        return
    for b in Bars
        try b.UpdateDesktops()
}

UpdateClockAndProgress() {
    global Bars
    static LastDay := ""
    CurrentDay := FormatTime(, "yyyyMMdd")
    if (LastDay != "" && LastDay != CurrentDay)
        CreateStatusBar()         ; rebuild at midnight so task markers refresh
    LastDay := CurrentDay
    if !IsSet(Bars)
        return
    pct := WorkPercent()
    for b in Bars
        try b.UpdateClock(pct)
    ApplyBarVisibility()      ; fullscreen auto-hide (respects the manual toggle state)
}

; True if any non-minimized window on the current desktop covers an entire monitor
; (full screen, not just the work area) - e.g. a fullscreen video or game.
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

; Apply the bar show/hide state from the manual toggle (Bar_Visible) combined with the
; fullscreen auto-hide option. The manual toggle is authoritative: a manually hidden bar
; is never auto-shown. Memoized so the per-second timer does not re-show every tick.
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

ToggleBar(*) {
    global Bar_Visible
    Bar_Visible := !Bar_Visible
    ApplyBarVisibility()
}

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

GatherAllToCurrent(*) {
    global Desktops, CurrentDesktop, AlwaysVisible
    ShowOSD("Gathering All Windows...")

    ; When using the "hide" method, windows parked on other desktops are hidden and would
    ; not appear in WinGetList; un-hide every tracked window first so all get gathered.
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
            ; Skip the script's own ToolWindows.
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

; ---- Tiling outer-boundary helpers (protect Bar / work-area edge on negative gaps) ----
SetTileBound(l, t, r, b) {
    global TileBound_L, TileBound_T, TileBound_R, TileBound_B, TileBoundSet
    TileBound_L := l, TileBound_T := t, TileBound_R := r, TileBound_B := b
    TileBoundSet := true
}
ClearTileBound() {
    global TileBoundSet
    TileBoundSet := false
}

; ---- Smart tiling ----
TileCurrentMonitor(*) {
    global CurrentTileGap, Tile_Gap

    MouseGetPos(&mx, &my)
    targetMon := GetMonitorIndexAtPoint(mx, my)
    MonitorGetWorkArea(targetMon, &WL, &WT, &WR, &WB)
    BarReserve(targetMon, &WL, &WT, &WR, &WB)   ; subtract every bar on this monitor

    ; The bar-reserved work area is the protected outer boundary; remember it so PlaceWin
    ; can clamp against it (relevant only when the gap is negative).
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

    ; Positive gap keeps the old outer margin; negative gap leaves the outer rect at the
    ; work area and is applied purely as a per-window inset in PlaceWin (allows overlap).
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

    ; Prefer the user's custom layout for this monitor; fall back to the default logic.
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

PlaceWin(hwnd, x, y, w, h) {
    global CurrentTileGap, TileBound_L, TileBound_T, TileBound_R, TileBound_B, TileBoundSet
    ; Per-window gap inset (gap may be negative -> neighbouring windows overlap).
    if (CurrentTileGap != 0) {
        half := CurrentTileGap / 2
        x += half, y += half, w -= CurrentTileGap, h -= CurrentTileGap
    }
    ; Clamp to the protected outer boundary so a negative gap never crosses the Bar /
    ; work-area edge, while still allowing windows to overlap each other inside it.
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
        if IsExcludedWindow(this_id)
            continue
        windows.Push(this_id)
    }
    return windows
}

; ---- Window snapping ----
SnapWindow(direction, *) {
    hwnd := 0
    try hwnd := WinExist("A")
    if !hwnd
        return

    targetMon := GetMonitorIndex(hwnd)
    MonitorGetWorkArea(targetMon, &L, &T, &R, &B)
    BarReserve(targetMon, &L, &T, &R, &B)   ; subtract every bar on this monitor
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
    global PowerMenuObj
    global PM_FontSize, PM_Width, PM_Height, PM_Opacity, PM_Rounded, PM_Radius
    if IsObject(PowerMenuObj) {
        PowerMenuObj.Destroy()
        PowerMenuObj := ""
        return
    }
    ; Width/height scale the base 500x160 layout; FontSize is honored directly.
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
    ; [Colors] section keys
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
    wtmMap := Map(
        "WTM_BorderFocusColor",   "BorderFocusColor",
        "WTM_BorderUnfocusColor", "BorderUnfocusColor"
    )
    for key, val in palette {
        if nameMap.Has(key)
            IniWrite(val, ConfigFile, "Theme", nameMap[key])
        else if wtmMap.Has(key)
            IniWrite(val, ConfigFile, "WTM", wtmMap[key])
    }
    IniWrite("custom", ConfigFile, "General", "ActiveTheme")
    ShowOSD("Exported -> custom")
    Sleep(400)
    Reload()
}

; ---- Misc helpers ----
RestoreAndExit(*) {
    global Desktops, AlwaysVisible
    ShowOSD("Script Shutting Down ...")
    Sleep(500)
    WTM.Deactivate()
    if AllBorders.Active
        AllBorders.Deactivate()
    PinBorder.RemoveAll()
    DestroyAllBars()

    ; Make sure no window stays hidden/minimized by us: explicitly un-hide every tracked
    ; window across all desktops first (covers the "hide" method), then restore the rest.
    Loop DesktopCount {
        if Desktops.Has(A_Index) {
            for h in Desktops[A_Index]
                try DllCall("ShowWindow", "Ptr", h, "Int", 9)   ; SW_RESTORE (un-hide + restore)
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
; ==============================================================================
class WTM {
    static Active     := false
    static TileOrder  := []
    static Excluded   := Map()
    static FocusHwnd  := 0
    static BorderMap   := Map()    ; hwnd -> BorderFrame
    static BorderState := Map()    ; hwnd -> "focus" | "unfocus"
    static _LastSig   := ""
    static _Accum     := 0         ; ms accumulator: throttles retile detection
    static TickFn     := ObjBindMethod(WTM, "Tick")

    static Toggle() {
        if this.Active
            this.Deactivate()
        else
            this.Activate()
    }

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
        AllBorders.Suspend()     ; WTM owns borders while active
        ShowOSD("WTM Mode: ON")
    }

    static Deactivate() {
        this.Active := false
        SetTimer(this.TickFn, 0)
        this.DestroyAllBorders()
        AllBorders.Rebuild()     ; resume all-borders mode if it was enabled
        ShowOSD("WTM Mode: OFF")
    }

    static OnDesktopSwitched() {
        if !this.Active
            return
        ; Keep window positions after a desktop switch: only rebuild order & borders,
        ; do not re-tile. The target desktop's windows are restored in SwitchDesktop and
        ; Windows preserves their previous positions.
        ; Fully reset borders so none of the previous desktop's frames can linger.
        this.DestroyAllBorders()
        this.RebuildOrder()
        ; Refresh the signature cache so Tick does not retile just because the visible
        ; window set changed.
        this._LastSig := this._Signature()
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
    }

    static _TileMonitor(monIdx, wins) {
        global CurrentTileGap, WTM_Gap
        if (wins.Length = 0)
            return
        if (monIdx < 1 || monIdx > MonitorGetCount())
            monIdx := 1
        MonitorGetWorkArea(monIdx, &WL, &WT, &WR, &WB)
        BarReserve(monIdx, &WL, &WT, &WR, &WB)   ; subtract every bar on this monitor
        SetTileBound(WL, WT, WR, WB)             ; protected outer boundary for PlaceWin
        W := WR - WL, H := WB - WT

        g := WTM_Gap
        if (g > 0) {
            WL += g/2, WT += g/2, W -= g, H -= g
        }
        CurrentTileGap := g

        ; Prefer the user's custom layout for this monitor; fall back to default tiling.
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

    static _Signature() {
        sig := ""
        for hwnd in GetVisibleWindow() {
            if this.Excluded.Has(hwnd)
                continue
            try {
                if (WinGetMinMax(hwnd) = -1)   ; ignore minimized windows (avoids spurious retiles)
                    continue
                WinGetPos(&x, &y, &w, &h, hwnd)
                sig .= hwnd "|" w "x" h ";"
            }
        }
        return sig
    }

    static Tick() {
        if !this.Active
            return
        ; Borders redraw every tick (global Border_RefreshMs). The heavier retile
        ; detection is throttled to ~150ms so a fast refresh interval stays cheap.
        this._Accum += Border_RefreshMs
        if (this._Accum >= 150) {
            this._Accum := 0
            sig := this._Signature()
            if (sig != this._LastSig) {
                this._LastSig := sig
                this.AutoTile()
                this._LastSig := this._Signature()
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
        this.RebuildOrder()
        if (this.TileOrder.Length = 0)
            return
        cur := this.FocusHwnd ? this.FocusHwnd : this.TileOrder[1]
        target := this._PickNeighbor(cur, dir)
        if target {
            try {
                WinActivate(target)
                this.FocusHwnd := target
                this._MoveCursorToWindow(target)
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
        if !target {
            adj := 0
            try adj := this._AdjacentMonitor(GetMonitorIndex(cur), dir)
            if adj {
                this._MoveWindowToMonitor(cur, adj)
                this.AutoTile()
                this._MoveCursorToWindow(cur)
                this.RefreshBorder()
            }
            return
        }
        curMon := 1, tgtMon := 1
        try curMon := GetMonitorIndex(cur)
        try tgtMon := GetMonitorIndex(target)
        i1 := this._OrderIndex(cur)
        i2 := this._OrderIndex(target)
        if (i1 && i2) {
            tmp := this.TileOrder[i1]
            this.TileOrder[i1] := this.TileOrder[i2]
            this.TileOrder[i2] := tmp
        }
        if (curMon != tgtMon) {
            this._MoveWindowToMonitor(cur, tgtMon)
            this._MoveWindowToMonitor(target, curMon)
        }
        this.AutoTile()
        this._MoveCursorToWindow(cur)
        this.RefreshBorder()
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
            WinMove(cx - w // 2, cy - h // 2, , , hwnd)
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
        this.OnWindowChanged()
    }

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

    static _OrderIndex(hwnd) {
        for i, h in this.TileOrder
            if (h = hwnd)
                return i
        return 0
    }

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

    static EnsureBorder(hwnd) {
        if this.BorderMap.Has(hwnd)
            return
        this.BorderMap[hwnd]   := BorderFrame(WTM_BorderUnfocusColor, WTM_BorderOpacity)
        this.BorderState[hwnd] := "unfocus"
    }

    static RemoveBorder(hwnd) {
        if !this.BorderMap.Has(hwnd)
            return
        try this.BorderMap[hwnd].Destroy()
        this.BorderMap.Delete(hwnd)
        if this.BorderState.Has(hwnd)
            this.BorderState.Delete(hwnd)
    }

    static DestroyAllBorders() {
        for hwnd, _ in this.BorderMap.Clone()
            this.RemoveBorder(hwnd)
        this.BorderMap   := Map()
        this.BorderState := Map()
    }

    static _SetBorderColor(hwnd, state) {
        if !this.BorderMap.Has(hwnd)
            return
        if (this.BorderState.Has(hwnd) && this.BorderState[hwnd] = state)
            return
        col := (state = "focus") ? WTM_BorderFocusColor : WTM_BorderUnfocusColor
        this.BorderMap[hwnd].SetColor(col)
        this.BorderState[hwnd] := state
    }

    static RefreshBorder() {
        if !this.Active
            return
        valid := Map()
        for hwnd in this.TileOrder
            valid[hwnd] := true
        ; Prune borders whose window left the tile order (closed / floated / moved off).
        for hwnd, _ in this.BorderMap.Clone() {
            if !valid.Has(hwnd) || !WinExist(hwnd)
                this.RemoveBorder(hwnd)
        }

        focusH := this.FocusHwnd
        for hwnd in this.TileOrder {
            if !WinExist(hwnd)
                continue
            ; Pin border has highest priority: a pinned / always-visible window draws no
            ; WTM border over its pin indicator.
            if (PinBorder.Map.Has(hwnd) || AlwaysVisible.Has(hwnd)) {
                this.RemoveBorder(hwnd)
                continue
            }
            try {
                if (WinGetMinMax(hwnd) = -1) {
                    if this.BorderMap.Has(hwnd)
                        this.BorderMap[hwnd].Hide()
                    continue
                }
            } catch {
                continue
            }
            this.EnsureBorder(hwnd)
            if !GetWindowVisualRect(hwnd, &x, &y, &w, &ht)
                continue
            o := WTM_BorderOffset
            x -= o, y -= o, w += 2*o, ht += 2*o
            this._SetBorderColor(hwnd, hwnd = focusH ? "focus" : "unfocus")
            rad := (WTM_BorderRounded = "on") ? WTM_BorderRadius : 0
            ; Sit just above this window in the Z order (not topmost) - see BorderFrame.Place.
            this.BorderMap[hwnd].Place(x, y, w, ht, Max(2, WTM_BorderThickness), rad, WTM_BorderOpacity, WTM_BorderMode, hwnd)
        }
    }
}

; ==============================================================================
;  AllBorders - "show borders on every window" toggle mode. Independent of WTM;
;  while WTM is active it defers (WTM already draws borders). Focused window uses
;  the drag-border color, the rest use Color_BorderUnfocus. Built on BorderFrame.
; ==============================================================================
class AllBorders {
    static Active  := false
    static Frames  := Map()    ; hwnd -> BorderFrame
    static State   := Map()    ; hwnd -> "focus" | "unfocus"
    static _Wins   := []       ; cached visible-window list (re-enumerated ~every 200ms)
    static _Accum  := 0        ; ms accumulator: throttles re-enumeration
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
        if WTM.Active            ; WTM owns borders while active; we resume on WTM off
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

    ; Rebuild from scratch (used after desktop switch or when WTM turns off).
    static Rebuild() {
        if !this.Active
            return
        this.DestroyAll()
        if WTM.Active
            return
        this.Tick()
        SetTimer(this.TimerFn, Border_RefreshMs)
    }

    ; Called by WTM when it turns on: stop drawing but keep the Active flag.
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
        this.Frames[hwnd] := BorderFrame(Color_BorderUnfocus, WTM_BorderOpacity)
        this.State[hwnd]  := "unfocus"
    }

    static SetColor(hwnd, state) {
        if !this.Frames.Has(hwnd)
            return
        if (this.State.Has(hwnd) && this.State[hwnd] = state)
            return
        col := (state = "focus") ? Border_Drag_Color : Color_BorderUnfocus
        this.Frames[hwnd].SetColor(col)
        this.State[hwnd] := state
    }

    static Tick() {
        if !this.Active || WTM.Active
            return
        ; Re-enumerate the (heavier) visible-window list only ~every 200ms; reposition
        ; the borders every tick at the global Border_RefreshMs rate.
        this._Accum += Border_RefreshMs
        if (this._Accum >= 200 || this._Wins.Length = 0) {
            this._Accum := 0
            this._Wins  := GetVisibleWindow()    ; current-desktop, exclusion-aware
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
        for hwnd in this._Wins {
            if !WinExist(hwnd)
                continue
            ; Pin border has highest priority: a pinned / always-visible window draws no
            ; all-window border over its pin indicator.
            if (PinBorder.Map.Has(hwnd) || AlwaysVisible.Has(hwnd)) {
                this.Remove(hwnd)
                continue
            }
            try {
                if (WinGetMinMax(hwnd) = -1) {
                    if this.Frames.Has(hwnd)
                        this.Frames[hwnd].Hide()
                    continue
                }
            } catch {
                continue
            }
            this.Ensure(hwnd)
            if !GetWindowVisualRect(hwnd, &x, &y, &w, &h)
                continue
            o := WTM_BorderOffset
            x -= o, y -= o, w += 2*o, h += 2*o
            this.SetColor(hwnd, hwnd = focusH ? "focus" : "unfocus")
            rad := (WTM_BorderRounded = "on") ? WTM_BorderRadius : 0
            ; Sit just above this window in the Z order (not topmost) - see BorderFrame.Place.
            this.Frames[hwnd].Place(x, y, w, h, Max(2, WTM_BorderThickness), rad, WTM_BorderOpacity, Border_Drag_Mode, hwnd)
        }
    }
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
    A_TrayMenu.Add("Show Welcome",        (*) => WelcomeScreen.Show())
    A_TrayMenu.Add("Open Config Folder",  (*) => Run('explorer.exe "' . ConfigDir . '"'))
    A_TrayMenu.Add("Reload Script",       (*) => Reload())
    A_TrayMenu.Add("Restore && Exit",     RestoreAndExit)

    A_IconTip := "AHK WM - Desktop " . CurrentDesktop
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
