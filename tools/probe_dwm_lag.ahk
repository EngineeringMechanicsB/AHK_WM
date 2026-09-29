; 只读探针：SetWindowPos 之后立刻读回位置，看有没有滞后。
; 边框定位依赖"搬完窗口马上读它真实矩形"，若这一读拿到的是旧值，
; 边框就会系统性滞后于窗口。自建窗口自测，不碰别的窗口。
#Requires AutoHotkey v2.0
#SingleInstance Off

OUT := A_ScriptDir "\probe_dwm_lag.out.txt"
try FileDelete(OUT)
OnError((e, mode) => (FileAppend("UNCAUGHT: " e.Message " @ " e.File ":" e.Line "`n", OUT, "UTF-8"), ExitApp(3)))
log(s) => FileAppend(s "`n", OUT, "UTF-8")

; DWMWA_EXTENDED_FRAME_BOUNDS = 9
ExtFrame(hwnd, &x, &y, &w, &h) {
    r := Buffer(16, 0)
    if (DllCall("dwmapi\DwmGetWindowAttribute", "Ptr", hwnd, "UInt", 9, "Ptr", r, "UInt", 16, "Int") = 0) {
        x := NumGet(r, 0, "Int"), y := NumGet(r, 4, "Int")
        w := NumGet(r, 8, "Int") - x, h := NumGet(r, 12, "Int") - y
        return true
    }
    return false
}

g := Gui("-Caption +ToolWindow")
g.BackColor := "204080"
g.Show("NoActivate x100 y100 w400 h300")
hwnd := g.Hwnd
Sleep 300

maxWP := 0, maxDW := 0, n := 0
loop 60 {
    x := 100 + A_Index * 6
    y := 100 + A_Index * 3
    DllCall("SetWindowPos", "Ptr", hwnd, "Ptr", 0, "Int", x, "Int", y
        , "Int", 400, "Int", 300, "UInt", 0x4 | 0x10)   ; NOZORDER|NOACTIVATE
    WinGetPos(&cx, &cy, &cw, &ch, hwnd)
    d := Max(Abs(cx - x), Abs(cy - y))
    if (d > maxWP) {
        maxWP := d
        log("WinGetPos  lag=" d "  @" A_Index "  got " cx "," cy "  want " x "," y)
    }
    if ExtFrame(hwnd, &vx, &vy, &vw, &vh) {
        d2 := Max(Abs(vx - x), Abs(vy - y))
        if (d2 > maxDW) {
            maxDW := d2
            log("ExtFrame   lag=" d2 "  @" A_Index "  got " vx "," vy "  want " x "," y)
        }
    }
    n += 1
    Sleep 12
}
log("steps=" n "  maxWinGetPosLag=" maxWP "  maxExtFrameLag=" maxDW)
g.Destroy()
ExitApp(0)
