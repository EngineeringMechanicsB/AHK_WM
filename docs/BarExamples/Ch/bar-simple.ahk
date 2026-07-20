#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
; ==============================================================================
; Bar 示例 1 — 简单单行推送
; ==============================================================================
;
; 【功能说明】
;   每 3 秒向 bar 的 external_1 槽位推送当前时间。无字体大小或换行覆盖——
;   完全使用配置文件的全局 Bar_FontSize。
;
; 【使用前提】
;   1. wm.ahk 必须正在运行
;   2. 在 wm_config.ini 的 [Bar] Layout 中添加 external_1，例如：
;        Layout=desktops,1/3;external_1,1/3,7AA2F7,tx;time,+20/20;
;   3. 修改 INI 后按 Alt+R 重载配置
;
; 【工作原理】
;   构造 "BAR:<槽位号>:<文本>"，通过 WM_COPYDATA 发送。文本持续显示在
;   bar 上，直到下一次推送或 bar 重建。推送驱动——不轮询，有变化才更新。
;
;   协议格式：BAR:<槽位号>:<文本>
;     - 槽位号：对应 Layout 中的 external_N（1-99）
;     - 文本：  任意 UTF-8 字符串，持久显示直到下次推送
;
; 【操作】
;   Esc — 退出
; ==============================================================================

PushTick() {
    WMBarPush(1, Format("{}", FormatTime(, "HH:mm:ss")))
}

PushTick()
SetTimer(PushTick, 3000)
Esc::ExitApp

; ------------------------------------------------------------------------------
; WMBarPush(slot, text) —— 向 bar 外部槽位推送文本的通用辅助函数
; ------------------------------------------------------------------------------
; 参数：
;   slot — 槽位号（1-99），对应 [Bar] Layout 中的 external_N
;   text — 要显示在 bar 上的文本。持久显示直到下次推送或 bar 重建。
;          如果该槽位在 Layout 中配置了 wrap=N，文本可以包含 `n 换行符
;
; 返回值：true=发送成功，false=未找到 wm.ahk 窗口
;
; 实现细节：
;   1. 找到隐藏的 wm.ahk 窗口
;   2. 构造消息 "BAR:槽位:文本"
;   3. 编码为 UTF-16，通过 SendMessageTimeoutW 发送 WM_COPYDATA (0x4A)
;      使用 SMTO_ABORTIFHUNG + 2000ms 超时，确保不会因目标卡死而阻塞
; ------------------------------------------------------------------------------
WMBarPush(slot, text) {
    DetectHiddenWindows(true)
    h := WinExist("wm.ahk ahk_class AutoHotkey")
    if !h
        return false
    msg  := "BAR:" . slot . ":" . text
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
