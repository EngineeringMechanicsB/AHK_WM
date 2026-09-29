; 只读探针：验证"AHKWM_BORDER"标记能被 WinGetList 按标题+类名找回来
; 自己建窗口自己销毁，不碰任何别的窗口。结果写文件，不弹框。
#Requires AutoHotkey v2.0
#SingleInstance Off

OUT := A_ScriptDir "\probe_border_tag.out.txt"
try FileDelete(OUT)

OnError((e, mode) => (FileAppend("UNCAUGHT: " e.Message " @ " e.File ":" e.Line "`n", OUT, "UTF-8"), ExitApp(3)))

log(s) => FileAppend(s "`n", OUT, "UTF-8")

g := Gui("-Caption +ToolWindow +E0x20 -DPIScale")
g.BackColor := "A020F0"
g.Show("NoActivate x-3000 y-3000 w10 h10")
g.Title := "AHKWM_BORDER"
Sleep 120

log("own hwnd = " g.Hwnd)
log("title now = [" WinGetTitle(g.Hwnd) "]")
log("pid = " WinGetPID(g.Hwnd) " (me " DllCall("GetCurrentProcessId") ")")

hit1 := WinGetList("AHKWM_BORDER ahk_class AutoHotkeyGUI")
hit2 := WinGetList("ahk_class AutoHotkeyGUI")
log("match title+class: " hit1.Length)
log("match class only : " hit2.Length)

found := false
for h in hit1 {
    log("  candidate " h " title=[" WinGetTitle(h) "]")
    if (h = g.Hwnd)
        found := true
}
log("EXACT-MATCH " (found ? "YES" : "NO"))

; 确认 WinGetPID 与自身 PID 一致（孤儿回收要靠它区分别的实例）
log("pid-filter " ((WinGetPID(g.Hwnd) = DllCall("GetCurrentProcessId")) ? "OK" : "MISMATCH"))

g.Destroy()
Sleep 120
log("after destroy, match = " WinGetList("AHKWM_BORDER ahk_class AutoHotkeyGUI").Length)
ExitApp(found ? 0 : 1)
