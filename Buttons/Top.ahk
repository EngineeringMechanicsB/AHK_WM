SetWorkingDir(A_ScriptDir)
CoordMode("Mouse", "Screen")
SetTitleMatchMode(2)
SetWinDelay(0)
SetControlDelay(0)

Top() {
    ToolTip "Top"
    Sleep 200
    ToolTip()
}