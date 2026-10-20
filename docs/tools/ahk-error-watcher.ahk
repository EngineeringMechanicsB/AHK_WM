#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; Watch AutoHotkey error/warning dialogs: screenshot, OCR, log, close.
; 监控 AHK 报错弹窗：截图 + OCR + 记录 + 自动关闭。

global BaseDir  := A_ScriptDir
global LogFile  := BaseDir "\errors.log"
global ShotDir  := BaseDir "\shots"
global Ps1      := BaseDir "\ocr.ps1"
global Paused   := false
global Handled  := Map()
global MePid    := DllCall("GetCurrentProcessId")

if !DirExist(ShotDir)
    DirCreate(ShotDir)

SetupTray()
DetectHiddenWindows(true)
SetTimer(Scan, 800)
TrayTip("AHK Error Watcher", "Watching error dialogs...", 1)

SetupTray() {
    A_TrayMenu.Delete()
    A_TrayMenu.Add("Pause / Resume", TogglePause)
    A_TrayMenu.Add("Open errors.log", (*) => Run('notepad.exe "' LogFile '"'))
    A_TrayMenu.Add("Open shots folder", (*) => Run('explorer.exe "' ShotDir '"'))
    A_TrayMenu.Add()
    A_TrayMenu.Add("Exit", (*) => ExitApp())
    A_IconTip := "AHK Error Watcher"
}

TogglePause(*) {
    global Paused
    Paused := !Paused
    TrayTip("AHK Error Watcher", Paused ? "Paused" : "Watching", 1)
}

Scan() {
    global Handled, MePid, Paused
    if Paused
        return
    now := A_TickCount
    for h, t in Handled.Clone() {
        if (now - t > 10000)
            Handled.Delete(h)
    }
    for h in WinGetList() {
        if Handled.Has(h)
            continue
        try {
            pid := WinGetPID(h)
            if (pid = MePid)
                continue
            name := ProcessGetName(pid)
            if !InStr(name, "AutoHotkey")
                continue
            cls   := WinGetClass(h)
            title := WinGetTitle(h)
            txt   := ""
            try txt := Trim(WinGetText(h))
            isErr := (cls = "#32770")
                  || RegExMatch(title, "i)^(error|warning|critical)\b")
                  || RegExMatch(txt, "i)^(error|warning|critical)\s*:")
                  || (InStr(txt, "Specifically:") && InStr(txt, "Line:"))
            if !isErr
                continue
            Handled[h] := now
            HandleDialog(h, title, cls, name, txt)
        }
    }
}

HandleDialog(hwnd, title, cls, proc, txt) {
    global LogFile, ShotDir, Ps1
    stamp := FormatTime(A_Now, "yyyyMMdd-HHmmss")
    png   := ShotDir "\" . stamp . "-" . hwnd . ".png"
    txtf  := ShotDir "\" . stamp . "-" . hwnd . ".ocr.txt"
    ocr   := ""
    try {
        WinGetPos(&x, &y, &w, &hh, hwnd)
        if (w > 0 && hh > 0) {
            cmd := Format('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "{}" -Out "{}" -Txt "{}" -X {} -Y {} -W {} -H {}'
                        , Ps1, png, txtf, x, y, w, hh)
            RunWait(cmd, , "Hide")
            if FileExist(txtf)
                ocr := Trim(FileRead(txtf, "UTF-8"))
        }
    }
    entry := "=== " . FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss") . " ===`r`n"
           . "title: " title "`r`n"
           . "class: " cls "`r`n"
           . "proc : " proc "`r`n"
           . "--- window text ---`r`n" txt "`r`n"
           . "--- ocr ---`r`n" ocr "`r`n"
           . "png: " png "`r`n`r`n"
    try FileAppend(entry, LogFile, "UTF-8")
    try WinClose(hwnd)
    Sleep(400)
    if WinExist(hwnd)
        try WinKill(hwnd)
}
