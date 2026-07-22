#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
; ==============================================================================
; Bar 示例 3 — 双槽位诗词模拟（自包含协议）
; ==============================================================================
;
; 【内容】红楼梦·黛玉葬花吟（公有领域·曹雪芹 18世纪）
;   slot 1 — 标题（小字单行）
;   slot 2 — 当前句（大字两行）
;   每 3 秒切一句，每 6 句弹 OSD。退出时清空 bar + 恢复高度。
;
; 【操作】Esc — 退出
; ==============================================================================

global Verses := [
    "花谢花飞花满天",
    "红消香断有谁怜",
    "游丝软系飘春榭",
    "落絮轻沾扑绣帘",
    "闺中女儿惜春暮",
    "愁绪满怀无释处",
    "手把花锄出绣帘",
    "忍踏落花来复去",
    "柳丝榆荚自芳菲",
    "不管桃飘与李飞",
    "桃李明年能再发",
    "明年闺中知有谁",
    "三月香巢已垒成",
    "梁间燕子太无情",
    "明年花发虽可啄",
    "却不道人去梁空巢也倾"
]
global gIdx := 1
global gCounter := 0

PushVerse() {
    global gIdx, gCounter, Verses
    gCounter++

    WMBarPushEx(1, "0.05/0.35", "葬花吟·红楼梦", "tx=7AA2F7,fs=12")
    WMBarPushEx(2, "0.35/0.95", Verses[gIdx], "tx=CDD6F4,fs=16,wrap=2")

    if (Mod(gCounter, 6) = 0) {
        AHK_WM_OSD(Format("{}/{} 句", gIdx, Verses.Length)
            , 2000, "fs=16,bg=1E1E2E,tx=9ECE6A,op=85,pos=80")
    }
    gIdx := Mod(gIdx, Verses.Length) + 1
}

PushVerse()
SetTimer(PushVerse, 3000)

OnExit(Cleanup)
Cleanup(*) {
    _WMSend("BAR:1:")
    _WMSend("BAR:2:")
}
Esc::ExitApp

WMBarPushEx(slot, loHi, text, opts := "") {
    msg := "BAR:" . slot . ":" . loHi . ":" . text
    if (opts != "")
        msg .= ":" . opts
    return _WMSend(msg)
}
_WMSend(msg) {
    DetectHiddenWindows(true)
    h := WinExist("wm.ahk ahk_class AutoHotkey")
    if !h
        return false
    size := (StrLen(msg) + 1) * 2
    buf := Buffer(size, 0)
    StrPut(msg, buf, "UTF-16")
    cds := Buffer(A_PtrSize * 3, 0)
    NumPut("Ptr", 0, cds, 0)
    NumPut("UInt", size, cds, A_PtrSize)
    NumPut("Ptr", buf.Ptr, cds, A_PtrSize * 2)
    res := 0
    return DllCall("User32\SendMessageTimeoutW", "Ptr", h, "UInt", 0x4A
        , "Ptr", A_ScriptHwnd, "Ptr", cds.Ptr
        , "UInt", 0x2, "UInt", 2000, "UInt*", &res, "Ptr") ? true : false
}
AHK_WM_OSD(text, duration := 1000, opts := "") {
    DetectHiddenWindows(true)
    h := WinExist("wm.ahk ahk_class AutoHotkey")
    if !h
        return false
    payload := "OSD:" . text . ":" . duration
    if (opts != "")
        payload .= ":" . opts
    c := StrPut(payload, "UTF-16")
    b := Buffer(A_PtrSize * 3, 0)
    NumPut("Ptr", 0, b, 0)
    NumPut("UInt", c, b, A_PtrSize)
    NumPut("Ptr", StrPtr(payload), b, A_PtrSize * 2)
    try SendMessage(0x4A, 0, b.Ptr, , "ahk_id " . h)
    return true
}
