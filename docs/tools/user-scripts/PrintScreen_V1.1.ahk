#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn

SetWorkingDir(A_ScriptDir)
CoordMode("Mouse", "Screen")
SetWinDelay(0)
SetControlDelay(0)

try DllCall("User32.dll\SetProcessDpiAwarenessContext", "Ptr", -4, "Ptr")
catch
    try DllCall("User32.dll\SetProcessDPIAware")

;==========================================================================
; ---- Globals ----
;==========================================================================
global ConfigDir  := EnvGet("USERPROFILE") . "\.config\AHK_screenshot"
global ConfigFile := ConfigDir . "\screenshot.ini"

global ActiveTheme
global Color_Bg, Color_Text, Color_Active, Color_Accent, Color_Border, Color_Error
global Toast_Enabled, Toast_FontSize, Toast_Opacity, Toast_Duration, Toast_Width
global Toast_PositionX, Toast_PositionY, Toast_Margin
global Border_Color, Border_Thickness, Overlay_Alpha
global FFmpeg_Path, Output_Dir, Video_Dir
global Capture_Backend, Capture_HDR, Capture_DrawMouse, Capture_Format
global Video_Framerate, Video_Encoder, Video_Quality, Video_AudioDevice, Video_Container
global HK := Map()
global IsSelecting := false
global IsRecording := false
global RecPID := 0
global RecFile := ""
global RecMode := ""
global DDAGrabDisabled := false

;==========================================================================
; ---- Themes ----
;==========================================================================
global Themes := Map(
    "nord",            Map("Color_Bg","2E3440","Color_Text","D8DEE9","Color_Active","88C0D0","Color_Accent","A3BE8C","Color_Border","88C0D0","Color_Error","BF616A","Border_Color","88C0D0"),
    "tokyonight",      Map("Color_Bg","1A1B26","Color_Text","C0CAF5","Color_Active","7AA2F7","Color_Accent","9ECE6A","Color_Border","7AA2F7","Color_Error","F7768E","Border_Color","7AA2F7"),
    "dracula",         Map("Color_Bg","282A36","Color_Text","F8F8F2","Color_Active","BD93F9","Color_Accent","50FA7B","Color_Border","8BE9FD","Color_Error","FF5555","Border_Color","BD93F9"),
    "gruvbox",         Map("Color_Bg","282828","Color_Text","EBDBB2","Color_Active","83A598","Color_Accent","B8BB26","Color_Border","FABD2F","Color_Error","FB4934","Border_Color","83A598"),
    "monokai",         Map("Color_Bg","272822","Color_Text","F8F8F2","Color_Active","66D9EF","Color_Accent","A6E22E","Color_Border","FD971F","Color_Error","F92672","Border_Color","66D9EF"),
    "solarized-dark",  Map("Color_Bg","002B36","Color_Text","93A1A1","Color_Active","268BD2","Color_Accent","859900","Color_Border","2AA198","Color_Error","DC322F","Border_Color","268BD2"),
    "solarized-light", Map("Color_Bg","FDF6E3","Color_Text","586E75","Color_Active","268BD2","Color_Accent","859900","Color_Border","2AA198","Color_Error","DC322F","Border_Color","268BD2"),
    "catppuccin-mocha",Map("Color_Bg","1E1E2E","Color_Text","CDD6F4","Color_Active","89B4FA","Color_Accent","A6E3A1","Color_Border","CBA6F7","Color_Error","F38BA8","Border_Color","89B4FA"),
    "catppuccin-latte",Map("Color_Bg","EFF1F5","Color_Text","4C4F69","Color_Active","1E66F5","Color_Accent","40A02B","Color_Border","8839EF","Color_Error","D20F39","Border_Color","1E66F5"),
    "onedark",         Map("Color_Bg","282C34","Color_Text","ABB2BF","Color_Active","61AFEF","Color_Accent","98C379","Color_Border","C678DD","Color_Error","E06C75","Border_Color","61AFEF"),
    "ayu-dark",        Map("Color_Bg","0A0E14","Color_Text","B3B1AD","Color_Active","59C2FF","Color_Accent","C2D94C","Color_Border","FFB454","Color_Error","F07178","Border_Color","59C2FF"),
    "github-dark",     Map("Color_Bg","0D1117","Color_Text","C9D1D9","Color_Active","58A6FF","Color_Accent","3FB950","Color_Border","D2A8FF","Color_Error","F85149","Border_Color","58A6FF"),
    "rose-pine",       Map("Color_Bg","191724","Color_Text","E0DEF4","Color_Active","9CCFD8","Color_Accent","31748F","Color_Border","C4A7E7","Color_Error","EB6F92","Border_Color","9CCFD8"),
    "everforest",      Map("Color_Bg","2D353B","Color_Text","D3C6AA","Color_Active","7FBBB3","Color_Accent","A7C080","Color_Border","D699B6","Color_Error","E67E80","Border_Color","7FBBB3"),
    "kanagawa",        Map("Color_Bg","1F1F28","Color_Text","DCD7BA","Color_Active","7E9CD8","Color_Accent","98BB6C","Color_Border","957FB8","Color_Error","E82424","Border_Color","7E9CD8"),
    "material-deep",   Map("Color_Bg","263238","Color_Text","EEFFFF","Color_Active","82AAFF","Color_Accent","C3E88D","Color_Border","C792EA","Color_Error","F07178","Border_Color","82AAFF"),
    "nightfox",        Map("Color_Bg","192330","Color_Text","CDCECF","Color_Active","719CD6","Color_Accent","81B29A","Color_Border","9D79D6","Color_Error","C94F6D","Border_Color","719CD6"),
    "palenight",       Map("Color_Bg","292D3E","Color_Text","A6ACCD","Color_Active","82AAFF","Color_Accent","C3E88D","Color_Border","C792EA","Color_Error","F07178","Border_Color","82AAFF"),
    "horizon",         Map("Color_Bg","1C1E26","Color_Text","CBCED0","Color_Active","25B0BC","Color_Accent","09F7A0","Color_Border","B877DB","Color_Error","E95678","Border_Color","25B0BC"),
    "oxocarbon",       Map("Color_Bg","161616","Color_Text","F2F4F8","Color_Active","33B1FF","Color_Accent","42BE65","Color_Border","BE95FF","Color_Error","FF7EB6","Border_Color","33B1FF")
)

;==========================================================================
; ---- Hotkey notation ----
;==========================================================================
NormalizeHotkey(s) {
    s := Trim(s)
    if (s = "")
        return ""
    if RegExMatch(s, "^[\!\^\+\#<>\*~\$]")
        return s
    if InStr(s, "&")
        return s
    mods := "", key := ""
    for p in StrSplit(s, ["+", "-"]) {
        p := Trim(p)
        if (p = "")
            continue
        switch StrLower(p) {
            case "alt":                 mods .= "!"
            case "shift":               mods .= "+"
            case "ctrl", "control":     mods .= "^"
            case "win", "lwin", "rwin": mods .= "#"
            default: key := p
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

;==========================================================================
; ---- Config ----
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

    if !FileExist(ConfigFile) {
        DefaultIni := "
        (
        ;==========================================================================
        ; Screenshot & Recorder Configuration
        ;==========================================================================

        [General]
        ; custom / nord / tokyonight / dracula / gruvbox / monokai
        ; / solarized-dark / solarized-light / catppuccin-mocha / catppuccin-latte
        ; / onedark / ayu-dark / github-dark / rose-pine / everforest / kanagawa
        ; / material-deep / nightfox / palenight / horizon / oxocarbon
        ActiveTheme=custom

        [Colors]
        Background=0e050f
        Text=e5e9f0
        Active=744da9
        Accent=CF8DC9
        Border=A020F0
        Error=FF5555

        [Toast]
        ; Show GUI notifications: on / off
        Enabled=on
        FontSize=11
        ; 1-100
        Opacity=85
        ; ms
        Duration=2200
        Width=380
        ; Screen-edge margin in pixels
        Margin=16
        ; Position as percentage of work area.
        ; PositionX: 0=left, 50=center, 100=right
        ; PositionY: 0=bottom, 50=middle, 100=top
        PositionX=100
        PositionY=0

        [Selection]
        ; Leave empty to inherit theme Border color
        BorderColor=
        BorderThickness=5
        OverlayAlpha=35
        ; 窗口吸附: on / off ; 区域选择时悬停自动框选窗口，单击确认，按住拖动则手动框选
        WindowSnap=on

        [Capture]
        ; auto / ddagrab / gdigrab
        Backend=auto
        ; on / off ; HDR(10bit) capture; screenshots auto tonemap to SDR PNG
        HDR=off
        DrawMouse=on
        ; png / jpg
        Format=png

        [Video]
        Framerate=60
        ; auto / hevc_nvenc / h264_nvenc / hevc_amf / h264_amf / hevc_qsv / h264_qsv / libx264 / libx265
        Encoder=auto
        ; CRF for libx26x, CQ for nvenc/amf/qsv (lower = better, 18-28 typical)
        Quality=20
        ; mp4 / mkv
        Container=mp4
        ; empty = no audio; otherwise dshow device name e.g. ""Stereo Mix""
        AudioDevice=

        [Paths]
        FFmpegPath=ffmpeg.exe
        OutputDir=%USERPROFILE%\Pictures\Screenshots
        VideoDir=%USERPROFILE%\Videos\Recordings

        [Hotkeys]
        CaptureFull=PrintScreen
        CaptureRegion=Alt+PrintScreen
        RecordFull=Ctrl+Alt+PrintScreen
        RecordRegion=Ctrl+Alt+Shift+PrintScreen
        Cancel=Esc
        )"
        try FileAppend(DefaultIni, ConfigFile, "UTF-8")
        catch as e {
            MsgBox("Failed to create config file: " . e.Message)
            ExitApp
        }
    }

    ActiveTheme  := IniRead(ConfigFile, "General", "ActiveTheme", "custom")

    Color_Bg     := IniRead(ConfigFile, "Colors", "Background", "0e050f")
    Color_Text   := IniRead(ConfigFile, "Colors", "Text",       "e5e9f0")
    Color_Active := IniRead(ConfigFile, "Colors", "Active",     "744da9")
    Color_Accent := IniRead(ConfigFile, "Colors", "Accent",     "CF8DC9")
    Color_Border := IniRead(ConfigFile, "Colors", "Border",     "A020F0")
    Color_Error  := IniRead(ConfigFile, "Colors", "Error",      "FF5555")

    Toast_Enabled   := (StrLower(IniRead(ConfigFile, "Toast", "Enabled", "on")) = "on")
    Toast_FontSize  := Integer(IniRead(ConfigFile, "Toast", "FontSize", "11"))
    Toast_Opacity   := Round(Integer(IniRead(ConfigFile, "Toast", "Opacity", "85")) * 255 / 100)
    Toast_Duration  := Integer(IniRead(ConfigFile, "Toast", "Duration", "2200"))
    Toast_Width     := Integer(IniRead(ConfigFile, "Toast", "Width", "380"))
    Toast_Margin    := Integer(IniRead(ConfigFile, "Toast", "Margin", "16"))
    Toast_PositionX := Number(IniRead(ConfigFile, "Toast", "PositionX", "100"))
    Toast_PositionY := Number(IniRead(ConfigFile, "Toast", "PositionY", "0"))

    selBorder        := IniRead(ConfigFile, "Selection", "BorderColor", "")
    Border_Color     := (selBorder != "") ? selBorder : Color_Border
    Border_Thickness := Integer(IniRead(ConfigFile, "Selection", "BorderThickness", "5"))
    Overlay_Alpha    := Integer(IniRead(ConfigFile, "Selection", "OverlayAlpha", "35"))
    ; 新增：窗口吸附开关
    global Window_Snap := (StrLower(IniRead(ConfigFile, "Selection", "WindowSnap", "on")) = "on")

    Capture_Backend   := StrLower(IniRead(ConfigFile, "Capture", "Backend", "auto"))
    Capture_HDR       := (StrLower(IniRead(ConfigFile, "Capture", "HDR", "off")) = "on")
    Capture_DrawMouse := (StrLower(IniRead(ConfigFile, "Capture", "DrawMouse", "on")) = "on")
    Capture_Format    := StrLower(IniRead(ConfigFile, "Capture", "Format", "png"))

    Video_Framerate   := Integer(IniRead(ConfigFile, "Video", "Framerate", "60"))
    Video_Encoder     := StrLower(IniRead(ConfigFile, "Video", "Encoder", "auto"))
    Video_Quality     := Integer(IniRead(ConfigFile, "Video", "Quality", "20"))
    Video_Container   := StrLower(IniRead(ConfigFile, "Video", "Container", "mp4"))
    Video_AudioDevice := IniRead(ConfigFile, "Video", "AudioDevice", "")

    FFmpeg_Path := ExpandEnv(IniRead(ConfigFile, "Paths", "FFmpegPath", "ffmpeg.exe"))
    Output_Dir  := ExpandEnv(IniRead(ConfigFile, "Paths", "OutputDir",  "%USERPROFILE%\Pictures\Screenshots"))
    Video_Dir   := ExpandEnv(IniRead(ConfigFile, "Paths", "VideoDir",   "%USERPROFILE%\Videos\Recordings"))

    HK := Map()
    hkDefaults := Map(
        "CaptureFull",   "PrintScreen",
        "CaptureRegion", "Alt+PrintScreen",
        "RecordFull",    "Ctrl+Alt+PrintScreen",
        "RecordRegion",  "Ctrl+Alt+Shift+PrintScreen",
        "Cancel",        "Esc"
    )
    for k, def in hkDefaults
        HK[k] := NormalizeHotkey(IniRead(ConfigFile, "Hotkeys", k, def))

    ; Apply theme overrides
    if (ActiveTheme != "custom" && Themes.Has(ActiveTheme)) {
        for key, val in Themes[ActiveTheme] {
            try %key% := val
        }
        if (selBorder = "")
            Border_Color := Themes[ActiveTheme].Has("Border_Color")
                ? Themes[ActiveTheme]["Border_Color"]
                : Color_Border
    }

    if !DirExist(Output_Dir)
        try DirCreate(Output_Dir)
    if !DirExist(Video_Dir)
        try DirCreate(Video_Dir)
}

ExpandEnv(s) {
    while RegExMatch(s, "%([^%]+)%", &m) {
        v := EnvGet(m[1])
        s := StrReplace(s, m[0], v)
    }
    return s
}

;==========================================================================
; ---- GUI Toast ----
;==========================================================================
class Toast {
    static List := []

    static Show(title, text, kind := "info") {
        global Color_Bg, Color_Text, Color_Accent, Color_Border, Color_Error
        global Toast_Enabled, Toast_FontSize, Toast_Opacity, Toast_Duration, Toast_Width
        global Toast_PositionX, Toast_PositionY, Toast_Margin

        if !Toast_Enabled
            return

        accent := (kind = "error")   ? Color_Error
              :   (kind = "success") ? Color_Accent
              :                        Color_Border

        barW := 4
        contentX := barW + 12
        contentW := Toast_Width - contentX - 12

        g := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x08000000 -DPIScale")
        g.BackColor := Color_Bg
        g.MarginX := 0, g.MarginY := 0

        g.AddText("x0 y0 w" barW " h10 vBar Background" accent, "")
        g.SetFont("s" Toast_FontSize " bold c" accent, "Segoe UI")
        g.AddText("x" contentX " y10 w" contentW, title)
        g.SetFont("s" (Toast_FontSize - 1) " norm c" Color_Text, "Segoe UI")
        g.AddText("x" contentX " y+4 w" contentW " r3", text)

        g.Show("Hide AutoSize NoActivate")
        g.GetClientPos(, , &gw, &gh)
        gh += 10
        g.Move(, , gw, gh)
        g["Bar"].Move(, , , gh)

        MonitorGetWorkArea(MonitorGetPrimary(), &mL, &mT, &mR, &mB)
        workW := mR - mL, workH := mB - mT
        m := Toast_Margin
        freeX := Max(0, workW - gw - 2 * m)
        freeY := Max(0, workH - gh - 2 * m)

        x := mL + m + Round(freeX * (Toast_PositionX / 100))
        y := mB - m - gh - Round(freeY * (Toast_PositionY / 100))

        stackUp := (Toast_PositionY < 50)
        offset := 0
        for t in Toast.List
            offset += t.h + 8
        y += stackUp ? -offset : offset

        g.Show(Format("x{} y{} NoActivate", x, y))
        WinSetTransparent(Toast_Opacity, "ahk_id " g.Hwnd)

        item := { gui: g, h: gh }
        Toast.List.Push(item)
        SetTimer(() => Toast.Dismiss(item), -Toast_Duration)
    }

    static Dismiss(item) {
        try item.gui.Destroy()
        for i, v in Toast.List {
            if (v = item) {
                Toast.List.RemoveAt(i)
                break
            }
        }
    }
}

Notify(title, text, kind := "info") {
    Toast.Show(title, text, kind)
}

;==========================================================================
; ---- Init ----
;==========================================================================
LoadOrInitConfig()
RegisterAllHotkeys()
SetupTrayIcon()
; 性能优化：脚本启动 1.5s 后在后台预取一次编码器列表，
; 让首次录制不必现场探测编码器（避免首录卡顿）。
SetTimer(PrewarmEncoders, -1500)

RegisterAllHotkeys() {
    global HK
    Hotkey(HK["CaptureFull"],   (*) => CaptureFullScreen())
    Hotkey(HK["CaptureRegion"], (*) => CaptureSelectedRegion())
    Hotkey(HK["RecordFull"],    (*) => ToggleRecord("full"))
    Hotkey(HK["RecordRegion"],  (*) => ToggleRecord("region"))
}

PrewarmEncoders() {
    global Video_Encoder
    if (Video_Encoder = "auto")
        GetEncoderList()   ; 触发一次缓存
}

;==========================================================================
; ---- Screenshot ----
;==========================================================================
CaptureFullScreen() {
    vs := GetVirtualScreen()
    CaptureRegion(vs.x, vs.y, vs.w, vs.h)
}

CaptureSelectedRegion() {
    rect := SelectRegion()
    if !rect
        return
    Sleep(120)   ; 等遮罩/边框彻底消失，避免被截进画面
    CaptureRegion(rect.x, rect.y, rect.w, rect.h)
}

CaptureRegion(x, y, w, h) {
    global Output_Dir, Capture_Backend, Capture_Format, DDAGrabDisabled

    x := Round(x), y := Round(y), w := Round(w), h := Round(h)
    if (w < 1 || h < 1) {
        Notify("Capture failed", "Invalid region size", "error")
        return
    }

    ext := (Capture_Format = "jpg") ? "jpg" : "png"
    outFile := Output_Dir "\Shot_" FormatTime(A_Now, "yyyyMMdd_HHmmss") "_" A_MSec "." ext

    useDDA := (Capture_Backend = "ddagrab") || (Capture_Backend = "auto" && !DDAGrabDisabled)
    if (useDDA) {
        r := TryDDAShot(x, y, w, h, outFile)
        if (r.ok) {
            Notify("Capture saved (ddagrab)", outFile, "success")
            return
        }
        if (r.reason = "multi-monitor") {
            if (Capture_Backend = "ddagrab") {
                Notify("Capture failed", "ddagrab does not support cross-monitor regions. Use auto/gdigrab.", "error")
                return
            }
        } else {
            if (Capture_Backend = "auto") {
                DDAGrabDisabled := true
                Notify("Notice", "ddagrab unavailable, falling back to gdigrab", "info")
            } else {
                Notify("Capture failed", "ddagrab error: " r.reason, "error")
                return
            }
        }
    }
    if (Capture_Backend = "ddagrab")
        return

    if GDIShot(x, y, w, h, outFile)
        Notify("Capture saved (gdigrab)", outFile, "success")
    else
        Notify("Capture failed", "FFmpeg execution failed", "error")
}

TryDDAShot(x, y, w, h, outFile) {
    global FFmpeg_Path, Capture_DrawMouse, Capture_HDR
    mon := FindMonitorContaining(x, y, w, h)
    if !mon
        return { ok: false, reason: "multi-monitor" }
    lx := x - mon.x, ly := y - mon.y
    drawMouse := Capture_DrawMouse ? 1 : 0
    fmtPart := Capture_HDR ? ":output_fmt=10bit" : ""
    filter := Format("ddagrab=output_idx={}:draw_mouse={}:offset_x={}:offset_y={}:video_size={}x{}:framerate=30{}",
        mon.idx - 1, drawMouse, lx, ly, w, h, fmtPart)
    vf := Capture_HDR
        ? "hwdownload,format=p010le,zscale=t=linear:npl=100,format=gbrpf32le,zscale=p=bt709:t=bt709:m=bt709:r=tv,format=rgb24"
        : "hwdownload,format=bgra"
    args := Format('-hide_banner -loglevel error -y -f lavfi -i "{}" -vf "{}" -frames:v 1 "{}"',
        filter, vf, outFile)
    try ec := RunWait(Quote(FFmpeg_Path) " " args, , "Hide")
    catch
        return { ok: false, reason: "ffmpeg-not-found" }
    return (ec = 0 && FileExist(outFile))
        ? { ok: true, reason: "" }
        : { ok: false, reason: "exit=" ec }
}

GDIShot(x, y, w, h, outFile) {
    global FFmpeg_Path, Capture_DrawMouse
    drawMouse := Capture_DrawMouse ? 1 : 0
    args := Format('-hide_banner -loglevel error -y -f gdigrab -draw_mouse {} -offset_x {} -offset_y {} -video_size {}x{} -i desktop -frames:v 1 "{}"',
        drawMouse, x, y, w, h, outFile)
    try ec := RunWait(Quote(FFmpeg_Path) " " args, , "Hide")
    catch
        return false
    return ec = 0 && FileExist(outFile)
}

;==========================================================================
; ---- Video Recording ----
;==========================================================================
ToggleRecord(mode) {
    global IsRecording
    if (IsRecording) {
        StopRecording()
        return
    }
    if (mode = "full") {
        vs := GetVirtualScreen()
        StartRecording(vs.x, vs.y, vs.w, vs.h, mode)
    } else {
        rect := SelectRegion()
        if !rect {
            Notify("Recording canceled", "No region selected", "info")
            return
        }
        Sleep(120)
        StartRecording(rect.x, rect.y, rect.w, rect.h, mode)
    }
}

StartRecording(x, y, w, h, mode) {
    global FFmpeg_Path, Video_Dir, Video_Framerate, Video_Encoder, Video_Quality
    global Video_Container, Video_AudioDevice, Capture_HDR, Capture_DrawMouse
    global Capture_Backend, DDAGrabDisabled, IsRecording, RecPID, RecFile, RecMode, HK

    w := w - Mod(w, 2), h := h - Mod(h, 2)
    if (w < 16 || h < 16) {
        Notify("Recording failed", "Region is too small", "error")
        return
    }

    enc := ResolveEncoder()
    container := (Video_Container = "mkv") ? "mkv" : "mp4"
    RecFile := Video_Dir "\Rec_" FormatTime(A_Now, "yyyyMMdd_HHmmss") "." container
    RecMode := mode

    useDDA := (Capture_Backend != "gdigrab") && !DDAGrabDisabled
    mon := useDDA ? FindMonitorContaining(x, y, w, h) : ""

    inputArgs := ""
    vf := ""
    if (mon) {
        lx := x - mon.x, ly := y - mon.y
        drawMouse := Capture_DrawMouse ? 1 : 0
        fmtPart := Capture_HDR ? ":output_fmt=10bit" : ""
        filter := Format("ddagrab=output_idx={}:draw_mouse={}:offset_x={}:offset_y={}:video_size={}x{}:framerate={}{}",
            mon.idx - 1, drawMouse, lx, ly, w, h, Video_Framerate, fmtPart)
        inputArgs := Format('-f lavfi -i "{}"', filter)
        ;----------------------------------------------------------------
        ; HDR 0KB Bug 修复点：
        ; 原代码在 nvenc + HDR 时把 vf 留空，让 ddagrab 的 D3D11 10bit
        ; 硬件帧直接喂给 nvenc，同时编码器参数又指定了软件像素格式
        ; -pix_fmt p010le，二者冲突 -> nvenc 初始化失败 -> 0KB 文件。
        ; 修复：HDR 一律先 hwdownload 到系统内存 p010le，使输入像素格式
        ; 与编码器 -pix_fmt p010le 保持一致。SDR 路径完全不变。
        ;----------------------------------------------------------------
        if InStr(enc.name, "nvenc") {
            vf := Capture_HDR ? "hwdownload,format=p010le" : ""
        } else {
            vf := Capture_HDR ? "hwdownload,format=p010le" : "hwdownload,format=bgra,format=yuv420p"
        }
    } else {
        drawMouse := Capture_DrawMouse ? 1 : 0
        inputArgs := Format('-f gdigrab -draw_mouse {} -framerate {} -offset_x {} -offset_y {} -video_size {}x{} -i desktop',
            drawMouse, Video_Framerate, x, y, w, h)
        vf := "format=yuv420p"
    }

    audioArgs := ""
    if (Video_AudioDevice != "") {
        audioArgs := Format('-f dshow -i audio="{}" -c:a aac -b:a 192k', Video_AudioDevice)
    }

    vfArg := (vf != "") ? Format(' -vf "{}"', vf) : ""
    encArgs := BuildEncoderArgs(enc, Capture_HDR)

    fullArgs := Format('-hide_banner -loglevel error -y {} {}{} {} "{}"',
        inputArgs, audioArgs, vfArg, encArgs, RecFile)

    try {
        Run(Quote(FFmpeg_Path) " " fullArgs, , "Hide", &pid)
        RecPID := pid
        IsRecording := true
        hkPretty := PrettifyHotkey(mode = "full" ? HK["RecordFull"] : HK["RecordRegion"])
        Notify("Recording started",
            "Press " hkPretty " again to stop.`nEncoder: " enc.name "  " w "x" h "@" Video_Framerate "fps",
            "success")
    } catch {   ; Bug 修复：原来是 catch{}，引用 e.Message 会再次抛错
        Notify("Recording failed", "Could not start FFmpeg: " e.Message, "error")
    }
}

StopRecording() {
    global IsRecording, RecPID, RecFile, RecMode
    if !IsRecording
        return
    IsRecording := false

    ; 确保清理 FFmpeg 进程
    if (RecPID && ProcessExist(RecPID)) {
        ; 先尝试优雅关闭（让 ffmpeg 写完文件尾，否则文件损坏）
        if !SendCtrlCToProcess(RecPID) {
            try ProcessClose(RecPID)
        }
        ; 等待进程退出
        Loop 60 {
            if !ProcessExist(RecPID)
                break
            Sleep(100)
        }
        ; 如果还在运行，强制终止
        if ProcessExist(RecPID) {
            try Run('taskkill /F /PID ' RecPID, , "Hide")
        }
    }

    Sleep(300)
    if FileExist(RecFile)
        Notify("Recording saved", RecFile, "success")
    else
        Notify("Recording stopped", "No file produced. Check your configuration.", "error")

    RecPID := 0, RecFile := "", RecMode := ""
}

ResolveEncoder() {
    global Video_Encoder
    sel := Video_Encoder
    if (sel = "auto") {
        for cand in ["hevc_nvenc", "h264_nvenc", "hevc_amf", "h264_amf", "hevc_qsv", "h264_qsv", "libx264"] {
            if HasEncoder(cand) {
                sel := cand
                break
            }
        }
        if (sel = "auto")
            sel := "libx264"
    }
    return { name: sel }
}

;----------------------------------------------------------------------
; 性能优化：编码器探测
; 原实现对每个候选编码器各启动一次 ffmpeg（最多 7 次 RunWait），
; 首次录制会明显卡顿。现在只调用一次 ffmpeg 拉取完整编码器列表
; 并整体缓存，后续所有 HasEncoder 都是内存字符串查找。
;----------------------------------------------------------------------
global _EncList := ""

GetEncoderList() {
    global FFmpeg_Path, _EncList
    if (_EncList != "")
        return _EncList
    tmp := A_Temp "\ffenc_" A_TickCount ".txt"
    try RunWait(A_ComSpec ' /c ' Quote(FFmpeg_Path) ' -hide_banner -encoders > "' tmp '" 2>&1', , "Hide")
    try _EncList := FileRead(tmp)
    try FileDelete(tmp)
    if (_EncList = "")
        _EncList := " "   ; 标记为“已加载”，避免反复探测
    return _EncList
}

HasEncoder(name) {
    return InStr(GetEncoderList(), " " name " ") > 0
}

BuildEncoderArgs(enc, hdr) {
    global Video_Quality
    n := enc.name
    if InStr(n, "nvenc") {
        base := Format('-c:v {} -preset p5 -tune hq -rc vbr -cq {} -b:v 0', n, Video_Quality)
        if (hdr && InStr(n, "hevc"))
            base .= ' -profile:v main10 -pix_fmt p010le -color_primaries bt2020 -color_trc smpte2084 -colorspace bt2020nc'
        return base
    } else if InStr(n, "amf") {
        return Format('-c:v {} -quality balanced -rc cqp -qp_i {} -qp_p {}', n, Video_Quality, Video_Quality)
    } else if InStr(n, "qsv") {
        return Format('-c:v {} -global_quality {}', n, Video_Quality)
    } else if (n = "libx265") {
        return Format('-c:v libx265 -preset medium -crf {}', Video_Quality)
    } else {
        return Format('-c:v libx264 -preset veryfast -crf {} -pix_fmt yuv420p', Video_Quality)
    }
}

SendCtrlCToProcess(pid) {
    DllCall("FreeConsole")
    if !DllCall("AttachConsole", "UInt", pid)
        return false
    DllCall("SetConsoleCtrlHandler", "Ptr", 0, "Int", 1)
    ok := DllCall("GenerateConsoleCtrlEvent", "UInt", 0, "UInt", 0)
    Sleep(100)
    DllCall("FreeConsole")
    DllCall("SetConsoleCtrlHandler", "Ptr", 0, "Int", 0)
    return ok
}

;==========================================================================
; ---- Region selection (含窗口吸附) ----
;==========================================================================
SelectRegion() {
    global Overlay_Alpha, IsSelecting, Window_Snap
    if IsSelecting
        return ""
    IsSelecting := true

    ; 等待修饰键释放，避免热键的 Alt/Ctrl/Shift 影响后续判断
    KeyWait("Alt"), KeyWait("Ctrl"), KeyWait("Shift")

    vs := GetVirtualScreen()
    overlay := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale")
    overlay.BackColor := "000000"
    overlay.Show(Format("x{} y{} w{} h{} NA", vs.x, vs.y, vs.w, vs.h))
    WinSetTransparent(Overlay_Alpha, "ahk_id " overlay.Hwnd)

    borders := CreateBorders()

    ; 窗口检测需要排除我们自己创建的窗口（遮罩 + 4 条边框）
    exclude := Map(overlay.Hwnd, true)
    for b in borders
        exclude[b.Hwnd] := true

    rect := "", canceled := false
    dragThreshold := 6           ; 移动超过该像素阈值才视为“拖动”
    lastKey := ""                ; 边框去抖：避免重复刷新

    try {
        ;------------------------------------------------------------------
        ; 阶段 1：悬停吸附（仅当 WindowSnap=on）
        ; 鼠标移动到窗口上时自动框选该窗口，直到按下左键或 Esc。
        ;------------------------------------------------------------------
        snapRect := ""
        if (Window_Snap) {
            lastX := -99999, lastY := -99999
            while !GetKeyState("LButton", "P") {
                if GetKeyState("Escape", "P") {
                    canceled := true
                    break
                }
                MouseGetPos(&mx, &my)
                if (mx != lastX || my != lastY) {     ; 仅在鼠标真正移动时计算
                    lastX := mx, lastY := my
                    wb := WindowUnderPoint(mx, my, exclude)
                    if (wb) {
                        snapRect := ClampRect(wb, vs)
                        keys := snapRect.x "," snapRect.y "," snapRect.w "," snapRect.h
                        if (keys != lastKey) {
                            ShowBorders(borders, snapRect.x, snapRect.y, snapRect.w, snapRect.h)
                            lastKey := keys
                        }
                    } else {
                        snapRect := "", lastKey := ""
                        HideBorders(borders)
                    }
                }
                Sleep(16)
            }
        } else {
            ; 不吸附：直接等待按键，行为与旧版一致
            while !GetKeyState("LButton", "P") {
                if GetKeyState("Escape", "P") {
                    canceled := true
                    break
                }
                Sleep(10)
            }
        }

        if !canceled {
            MouseGetPos(&sx, &sy)
            ; 在按下点重新确认一次吸附目标，避免与最后一次悬停有偏差
            if (Window_Snap) {
                wb := WindowUnderPoint(sx, sy, exclude)
                if (wb)
                    snapRect := ClampRect(wb, vs)
            }

            dragged := false
            ;--------------------------------------------------------------
            ; 阶段 2：判定 单击(吸附) 还是 拖动(手动框选)
            ; 一旦位移超过阈值即进入手动模式，忽略吸附框。
            ;--------------------------------------------------------------
            while GetKeyState("LButton", "P") {
                if GetKeyState("Escape", "P") {
                    canceled := true
                    break
                }
                MouseGetPos(&ex, &ey)
                if (!dragged && (Abs(ex - sx) > dragThreshold || Abs(ey - sy) > dragThreshold))
                    dragged := true
                if (dragged) {
                    rect := ClampRect(NormalizeRect(sx, sy, ex, ey), vs)
                    keys := rect.x "," rect.y "," rect.w "," rect.h
                    if (keys != lastKey) {
                        ShowBorders(borders, rect.x, rect.y, rect.w, rect.h)
                        lastKey := keys
                    }
                }
                Sleep(8)
            }

            if !canceled {
                if (dragged) {
                    MouseGetPos(&ex, &ey)
                    rect := ClampRect(NormalizeRect(sx, sy, ex, ey), vs)
                } else {
                    rect := snapRect      ; 单击 -> 采用吸附窗口；无吸附则为空
                }
            }
        }
    } finally {
        try overlay.Destroy()
        for b in borders
            try b.Destroy()
        IsSelecting := false
    }

    if (canceled || rect = "" || rect.w < 3 || rect.h < 3)
        return ""
    return rect
}

CreateBorders() {
    global Border_Color
    arr := []
    Loop 4 {
        ; +E0x20 = WS_EX_TRANSPARENT：边框点击穿透，不干扰检测与点击
        g := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 -DPIScale")
        g.BackColor := Border_Color
        arr.Push(g)
    }
    return arr
}

ShowBorders(borders, x, y, w, h) {
    global Border_Thickness
    if (w < 1 || h < 1)
        return
    t := Min(Border_Thickness, Floor(w / 2), Floor(h / 2))
    if (t < 1)
        return
    inH := Max(1, h - 2 * t)
    borders[1].Show(Format("x{} y{} w{} h{} NA", x,         y,           w, t))
    borders[2].Show(Format("x{} y{} w{} h{} NA", x,         y + h - t,   w, t))
    borders[3].Show(Format("x{} y{} w{} h{} NA", x,         y + t,       t, inH))
    borders[4].Show(Format("x{} y{} w{} h{} NA", x + w - t, y + t,       t, inH))
}

HideBorders(borders) {
    for b in borders
        try b.Hide()
}

;==========================================================================
; ---- Window hit-test helpers（窗口吸附核心）----
;==========================================================================
; 用 EnumWindows 自顶向下枚举顶层窗口，返回光标下“最上层”窗口的可视边界。
; 用 EnumWindows 而非 WindowFromPoint：因为半透明遮罩在最上层，
; WindowFromPoint 会被遮罩拦截；枚举可逐个跳过我们自己的窗口。
WindowUnderPoint(px, py, exclude) {
    result := ""
    found := false

    EnumProc(hwnd, lParam) {
        if found
            return 0                                   ; 已命中，停止枚举
        if exclude.Has(hwnd)
            return 1
        if !DllCall("User32\IsWindowVisible", "Ptr", hwnd, "Int")
            return 1
        cloaked := 0                                   ; 跳过被隐藏(cloaked)的 UWP 窗口
        try DllCall("dwmapi\DwmGetWindowAttribute", "Ptr", hwnd, "UInt", 14, "Int*", &cloaked, "UInt", 4)
        if (cloaked)
            return 1
        b := GetWindowBounds(hwnd)
        if (b && px >= b.x && py >= b.y && px < b.x + b.w && py < b.y + b.h) {
            result := b
            found := true
            return 0
        }
        return 1
    }

    cb := CallbackCreate(EnumProc, "Fast", 2)
    DllCall("User32\EnumWindows", "Ptr", cb, "Ptr", 0)
    CallbackFree(cb)
    return result
}

; 取窗口的“可视”矩形：优先用 DWM 扩展边界（不含投影阴影），失败再退回 GetWindowRect

GetWindowBounds(hwnd) {

    rect := Buffer(16, 0)

    ; DWMWA_EXTENDED_FRAME_BOUNDS = 9

    hr := DllCall("dwmapi\DwmGetWindowAttribute", "Ptr", hwnd, "UInt", 9, "Ptr", rect, "UInt", 16, "Int")

    if (hr != 0) {

        ; DWM 失败则回退到普通窗口矩形

        if !DllCall("User32\GetWindowRect", "Ptr", hwnd, "Ptr", rect, "Int")

            return ""

    }

    l := NumGet(rect, 0, "Int"), t := NumGet(rect, 4, "Int")

    r := NumGet(rect, 8, "Int"), b := NumGet(rect, 12, "Int")

    w := r - l, h := b - t

    if (w < 1 || h < 1)

        return ""

    return { x: l, y: t, w: w, h: h }

}



;==========================================================================

; ---- Geometry helpers ----

;==========================================================================

GetVirtualScreen() {

    return { x: SysGet(76), y: SysGet(77), w: SysGet(78), h: SysGet(79) }

}



NormalizeRect(x1, y1, x2, y2) {

    return { x: Round(Min(x1,x2)), y: Round(Min(y1,y2)),

             w: Round(Abs(x2-x1)), h: Round(Abs(y2-y1)) }

}



ClampRect(r, vs) {

    x1 := Max(r.x, vs.x), y1 := Max(r.y, vs.y)

    x2 := Min(r.x + r.w, vs.x + vs.w), y2 := Min(r.y + r.h, vs.y + vs.h)

    return { x: Round(x1), y: Round(y1), w: Max(0, Round(x2-x1)), h: Max(0, Round(y2-y1)) }

}



FindMonitorContaining(x, y, w, h) {

    Loop MonitorGetCount() {

        MonitorGet(A_Index, &l, &t, &r, &b)

        if (x >= l && y >= t && x + w <= r && y + h <= b)

            return { idx: A_Index, x: l, y: t, w: r - l, h: b - t }

    }

    return ""

}



Quote(v) {

    return '"' StrReplace(v, '"', '\"') '"'

}



;==========================================================================

; ---- Tray menu ----

;==========================================================================

ApplyTheme(themeName, *) {

    IniWrite(themeName, ConfigFile, "General", "ActiveTheme")

    Sleep(200)

    Reload()

}



OpenFolder(path, *) {

    if !DirExist(path)

        try DirCreate(path)

    try Run('explorer.exe "' path '"')

}



OpenConfigFolder(*) {

    global ConfigDir

    if !DirExist(ConfigDir)

        try DirCreate(ConfigDir)

    try Run('explorer.exe "' ConfigDir '"')

}



ReloadScript(*) {

    Reload()

}



ExitScript(*) {

    ExitApp()

}



SetupTrayIcon() {

    global Themes, ActiveTheme, Output_Dir, Video_Dir, ConfigDir



    tm := A_TrayMenu

    tm.Delete()



    ; 主要功能（不显示快捷键）

    tm.Add("Capture Full Screen", (*) => CaptureFullScreen())

    tm.Add("Capture Region", (*) => CaptureSelectedRegion())

    tm.Add()

    tm.Add("Record Full Screen", (*) => ToggleRecord("full"))

    tm.Add("Record Region", (*) => ToggleRecord("region"))

    tm.Add()



    ; 文件夹访问

    tm.Add("Open Screenshots Folder", OpenFolder.Bind(Output_Dir))

    tm.Add("Open Recordings Folder", OpenFolder.Bind(Video_Dir))

    tm.Add("Open Config Folder", OpenConfigFolder)

    tm.Add()



    ; 主题选择

    themeMenu := Menu()

    themeMenu.Add("custom (use [Colors])", ApplyTheme.Bind("custom"))

    themeMenu.Add()

    for name, _ in Themes

        themeMenu.Add(name, ApplyTheme.Bind(name))

    try themeMenu.Check(ActiveTheme = "custom" ? "custom (use [Colors])" : ActiveTheme)

    tm.Add("Theme", themeMenu)



    tm.Add()

    tm.Add("Reload", ReloadScript)

    tm.Add("Exit", ExitScript)



    tm.Default := "Capture Region"

    A_IconTip := "AHK Screenshot"

}
