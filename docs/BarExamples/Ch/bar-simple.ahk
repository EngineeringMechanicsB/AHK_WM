#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
; ==============================================================================
; Bar 示例 1 — 自包含推送（无需 Layout 配置）
; ==============================================================================
;
; 【功能说明】
;   每 3 秒向 bar 推送当前时间，使用新版自包含协议。无需 [Bar] Layout
;   声明——位置、颜色、字体全部在推送消息中直接传递。
;
; 【协议格式】
;   新版（v2.11+）：BAR:<槽位>:<lo/hi>:<文本>:<键=值,...>
;     完全自包含，动态创建 bar 元素。无需 Layout。
;     可用键：bg=RRGGBB, tx=RRGGBB, rd=on|off, rr=N, fs=N, wrap=N
;   旧版：BAR:<槽位>:<文本>
;     需在 [Bar] Layout 中声明 external_N
;
;   lo/hi = 宽度比例 "0.5/0.8" 或像素 "(200-550)/1920"
;
; 【操作】
;   Esc — 退出
; ==============================================================================

PushTick() {
    WMBarPushEx(1, "0.5/0.8", FormatTime(, "HH:mm:ss"), "bg=7AA2F7,fs=14")
}

PushTick()
SetTimer(PushTick, 3000)

; 退出时清空 bar 内容
OnExit(Cleanup)
Cleanup(*) => _WMSend("BAR:1:")
Esc::ExitApp

; ------------------------------------------------------------------------------
; WMBarPush(slot, text) — 旧版协议（需 Layout 声明 external_N）
; ------------------------------------------------------------------------------
WMBarPush(slot, text) {
    return _WMSend("BAR:" . slot . ":" . text)
}

; ------------------------------------------------------------------------------
; WMBarPushEx(slot, loHi, text, opts := "") — 新版自包含协议
;   slot  — 槽位号 (1-99)
;   loHi  — 跨度："0.5/0.8"（比例）或 "(200-550)/1920"（像素）
;   text  — 显示文本（`n 换行，需配合 wrap=N）
;   opts  — "键=值,键=值"（全部可选）：
;             bg=RRGGBB  — 背景色
;             tx=RRGGBB  — 文字色
;             rd=on|off  — 圆角开关
;             rr=N       — 圆角半径 px
;             fs=N       — 字体大小 pt
;             wrap=N     — 最大行数（>1 多行，bar 自动增高）
; ------------------------------------------------------------------------------
WMBarPushEx(slot, loHi, text, opts := "") {
    msg := "BAR:" . slot . ":" . loHi . ":" . text
    if (opts != "")
        msg .= ":" . opts
    return _WMSend(msg)
}

; ---- 底层 WM_COPYDATA 发送 ----
_WMSend(msg) {
    DetectHiddenWindows(true)
    h := WinExist("wm.ahk ahk_class AutoHotkey")
    if !h
        return false
    size := (StrLen(msg) + 1) * 2
    buf  := Buffer(size, 0)
    StrPut(msg, buf, "UTF-16")
    cds := Buffer(A_PtrSize * 3, 0)
    NumPut("Ptr",  0,       cds, 0)
    NumPut("UInt", size,    cds, A_PtrSize)
    NumPut("Ptr",  buf.Ptr, cds, A_PtrSize * 2)
    res := 0
    return DllCall("User32\SendMessageTimeoutW", "Ptr", h, "UInt", 0x4A
        , "Ptr", A_ScriptHwnd, "Ptr", cds.Ptr
        , "UInt", 0x2, "UInt", 2000, "UInt*", &res, "Ptr") ? true : false
}
