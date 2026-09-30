#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
; ==============================================================================
; OSD 示例 — 按键显示（屏幕左下角显示当前按下的键）
; ==============================================================================
;
; 【功能】像教程视频那样，在屏幕角落实时显示当前按下的所有按键，松开后停留一会儿再消失。
;
; 【前提】1. wm.ahk 正在运行  2. 本脚本保持运行
;
; 【工作原理】
;   每 30ms 用 GetKeyState(键名, "P") 轮询一遍键表，拼出"Ctrl + Alt + A"这样的文字；
;   只有内容变化时才发 OSD，避免无意义刷新。浮层用 duration=0 + tag=keycast，
;   所以永远只存在一个实例（同 tag 的新 OSD 会替换旧的）。
;   全部松开后不立即消失，而是重发一次带 HOLD_MS 时长的同内容浮层，到点由 wm.ahk 自己销毁；
;   这段停留期内再按键就直接替换，所以连续操作不会一闪一闪。
;
; 【自定义】
;   POLL_MS       轮询间隔（ms）。越小越跟手，越大越省 CPU
;   HOLD_MS       松开后浮层停留多久（ms）。觉得消失太快就加大
;   OVERLAY_POS   浮层位置，px 或百分比。默认左下角
;   OVERLAY_STYLE 外观选项：字体/颜色/不透明度/圆角等
;   想改显示哪些键，直接改下面的 MODS 和 KEYS 两张表
;
; 【退出】Ctrl+Alt+F12
; ==============================================================================

; ---- 可调参数 ----
global POLL_MS       := 30
global HOLD_MS       := 1200
global OVERLAY_POS   := "x=16%,y=88%"
global OVERLAY_STYLE := "fs=22,op=92,rd=on,rr=10,tag=keycast"

; ---- 修饰键：显示名 → 物理键名（左右任一按下即显示，只显示一个名字）----
global MOD_ORDER := ["Ctrl", "Alt", "Shift", "Win"]
global MODS := Map(
    "Ctrl",  ["LControl", "RControl"],
    "Alt",   ["LAlt", "RAlt"],
    "Shift", ["LShift", "RShift"],
    "Win",   ["LWin", "RWin"]
)

; ---- 普通键：键名 → 显示名（写入顺序 = 显示顺序）----
global KEYS := Map(
    "a", "A", "b", "B", "c", "C", "d", "D", "e", "E", "f", "F", "g", "G",
    "h", "H", "i", "I", "j", "J", "k", "K", "l", "L", "m", "M", "n", "N",
    "o", "O", "p", "P", "q", "Q", "r", "R", "s", "S", "t", "T", "u", "U",
    "v", "V", "w", "W", "x", "X", "y", "Y", "z", "Z",
    "0", "0", "1", "1", "2", "2", "3", "3", "4", "4", "5", "5",
    "6", "6", "7", "7", "8", "8", "9", "9",
    "F1", "F1", "F2", "F2", "F3", "F3", "F4", "F4", "F5", "F5", "F6", "F6",
    "F7", "F7", "F8", "F8", "F9", "F9", "F10", "F10", "F11", "F11", "F12", "F12",
    "Space", "Space", "Enter", "Enter", "Tab", "Tab", "Esc", "Esc",
    "Backspace", "Backspace", "Delete", "Delete", "Insert", "Insert",
    "Home", "Home", "End", "End", "PgUp", "PgUp", "PgDn", "PgDn",
    "Up", "↑", "Down", "↓", "Left", "←", "Right", "→",
    "CapsLock", "CapsLock", "-", "-", "=", "=", "``", "``",
    "[", "[", "]", "]", "\", "\", ";", ";", "'", "'",
    ",", ",", ".", ".", "/", "/"
)

; ---- 隐藏用：把浮层移到屏幕外并压到几乎透明 ----
global HIDE_OPTS := "x=-4000,y=-4000,fs=8,op=1,rd=on,rr=10,tag=keycast"

; ---- 主循环 ----
global LAST_TEXT  := ""      ; 当前浮层内容，"" = 屏幕上什么都没有
global LAST_FIXED := false   ; 当前浮层是不是"按住期间"的常驻状态

Tick() {
    global MOD_ORDER, MODS, KEYS, LAST_TEXT, LAST_FIXED
    global HOLD_MS, OVERLAY_POS, OVERLAY_STYLE

    parts := []
    for name in MOD_ORDER {
        for k in MODS[name] {
            if GetKeyState(k, "P") {
                parts.Push(name)
                break
            }
        }
    }
    for k, label in KEYS {
        if GetKeyState(k, "P")
            parts.Push(label)
    }

    if (parts.Length = 0) {
        ; 全部松开：把常驻浮层换成"HOLD_MS 后自动消失"，只做这一次
        if (LAST_TEXT = "" || !LAST_FIXED)
            return
        if AHK_WM_OSD(LAST_TEXT, HOLD_MS, OVERLAY_POS "," OVERLAY_STYLE)
            LAST_FIXED := false
        return
    }

    text := ""
    for p in parts
        text .= (text = "" ? "" : " + ") . p

    if (text = LAST_TEXT && LAST_FIXED)
        return
    if AHK_WM_OSD(text, 0, OVERLAY_POS "," OVERLAY_STYLE) {
        LAST_TEXT  := text
        LAST_FIXED := true
    }
}

; ---- 退出前先收掉浮层（duration=0 的 OSD 不会自己消失）----
; 注意：OnExit 回调返回非零值会让脚本退不掉（AHK v2 语义），所以这里用函数而不是箭头表达式
OnExit(CleanUp)

CleanUp(*) {
    AHK_WM_OSD(" ", 0, HIDE_OPTS)
}

SetTimer(Tick, POLL_MS)
Tick()

^!F12::ExitApp

; ------------------------------------------------------------------------------
; AHK_WM_OSD(text, duration, opts) —— 通用辅助函数，可直接复制到你的脚本中使用
; ------------------------------------------------------------------------------
; 参数：
;   text     — 要显示的文字（UTF-8，支持中文和 emoji）
;   duration — 显示时长（毫秒），默认 1000。设为 0 则一直显示到被下一个同 tag 的 OSD 替换
;   opts     — （可选）外观覆盖项，格式 "键=值,键=值"，不填则用 wm_config.ini 默认值
;              可用键见 osd-custom-all.ahk
;
; 返回：true = 发送成功，false = 没找到 wm.ahk 主窗口
;
; 实现：
;   1. 用 DetectHiddenWindows 找到隐藏的 wm.ahk 主窗口
;   2. 拼出 "OSD:文字:时长[:选项]" 载荷
;   3. 转成 UTF-16，用 WM_COPYDATA (0x4A) 发给 wm.ahk
; ------------------------------------------------------------------------------
AHK_WM_OSD(text, duration := 1000, opts := "") {
    DetectHiddenWindows(true)
    h := WinExist("wm.ahk ahk_class AutoHotkey")
    if !h
        return false
    payload := "OSD:" . text . ":" . duration
    if (opts != "")
        payload .= ":" . opts
    dataSize := (StrLen(payload) + 1) * 2
    dataBuf := Buffer(dataSize, 0)
    StrPut(payload, dataBuf, "UTF-16")
    cds := Buffer(A_PtrSize * 3, 0)
    NumPut("Ptr", 0, cds, 0)
    NumPut("UInt", dataSize, cds, A_PtrSize)
    NumPut("Ptr", dataBuf.Ptr, cds, A_PtrSize * 2)
    res := 0
    DllCall("User32\SendMessageTimeoutW"
        , "Ptr", h, "UInt", 0x4A, "Ptr", A_ScriptHwnd
        , "Ptr", cds.Ptr, "UInt", 0x2, "UInt", 2000
        , "UInt*", &res, "Ptr")
    return true
}
