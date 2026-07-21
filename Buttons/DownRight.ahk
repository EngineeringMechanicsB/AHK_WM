SetWorkingDir(A_ScriptDir)
CoordMode("Mouse", "Screen")
SetTitleMatchMode(2)
SetWinDelay(0)
SetControlDelay(0)

DownRight() {
    ToolTip "DownRight"
    Sleep 200
    ToolTip()
}