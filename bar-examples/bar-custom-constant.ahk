#Requires AutoHotkey v2.0
#SingleInstance Force
; ==============================================================================
; AHK_WM bar 外部部件示例 1：推送一段固定文本
; ==============================================================================
; 【功能说明】
;   向 AHK_WM 状态栏的 external_1 槽位推送一段固定文本。
;   运行一次即可，内容会一直显示在 bar 上，直到下一次推送覆盖或 bar 重载。
;
; 【使用前提】
;   1. AHK_WM (wm.ahk) 正在运行
;   2. 配置文件 [Bar] Layout 中放置了 external_1 部件，例如：
;        Layout=desktops,(1-3)/20;external_1,(9-12)/20,B48EAD,CF8DC9,bg,on;time,20/20;
;      格式: external_N, 跨度, 颜色1, 颜色2, bg|tx, on|off
;      - N: 槽位号 (1-99)，与本脚本中 WMBarPush 的第一个参数对应
;      - 跨度: (起始列-结束列)/总列数，支持居中对齐 (a/列)、右对齐 (+列)、左对齐 (-列)
;      - 颜色: 支持单色或双色渐变，6 位十六进制
;      - 模式: bg=渐变背景+文字, tx=渐变文字
;      - 圆角: on 开启 / off 关闭
;   3. 支持与其他部件（desktops, time, date 等）自由组合排列
;
; 【调用方式】
;   WMBarPush(槽位号, "要显示的文本")
;   槽位号 1-99，与 Layout 中的 external_N 的 N 对应
;   文本长度不限，但 bar 空间有限，建议控制在 ~20 个字符以内
;
; 【工作原理】
;   通过 WM_COPYDATA 消息向 wm.ahk 主窗口发送 "BAR:槽位:文本"。
;   wm.ahk 内部收到后存入 Bar_ExternalData[槽位]，bar 下次刷新时自动显示。
;   单次调用、无轮询、无临时文件。
;
; 【注意】
;   - 退出本脚本后 bar 保留最后推送的值（直到其他脚本推送同一槽位或 bar 重载）
;   - 多个脚本可以同时向不同槽位推送，互不干扰
;   - 如果 bar 不显示内容，检查 Layout 中是否配置了对应槽位的 external_N
; ==============================================================================

if WMBarPush(1, "★ Hello from external script")
    TrayTip("已推送到 bar external_1")
else
    TrayTip("未找到 AHK_WM 主窗口，请确认 wm.ahk 正在运行")
Sleep(1500)
ExitApp

; ------------------------------------------------------------------------------
; WMBarPush(slot, text) —— 通用辅助函数，可直接复制到你自己的脚本中使用
; ------------------------------------------------------------------------------
; 参数:
;   slot - 槽位号 (1-99)，与配置文件中 external_N 的 N 对应
;   text - 要显示的文本内容 (任意字符串)
; 返回值: true=发送成功, false=未找到 wm.ahk 窗口
;
; 实现细节:
;   1. 通过 DetectHiddenWindows 找到隐藏的 wm.ahk 主窗口
;   2. 构造消息 "BAR:槽位:文本"
;   3. 将消息编码为 UTF-16，计算字节长度
;   4. 填充 COPYDATASTRUCT 结构体
;   5. 通过 SendMessageTimeoutW 发送 WM_COPYDATA (0x4A) 消息
;   6. SMTO_ABORTIFHUNG (0x2) + 2000ms 超时，确保不会因目标卡死而阻塞
; ------------------------------------------------------------------------------
WMBarPush(slot, text) {
    prevDetect := A_DetectHiddenWindows
    prevMatch  := A_TitleMatchMode
    DetectHiddenWindows(true)
    SetTitleMatchMode(2)
    target := WinExist("wm.ahk ahk_class AutoHotkey")
    DetectHiddenWindows(prevDetect)
    SetTitleMatchMode(prevMatch)
    if !target
        return false
    msg  := "BAR:" . slot . ":" . text
    size := (StrLen(msg) + 1) * 2                     ; UTF-16 字节数（含 NUL 终止符）
    buf  := Buffer(size, 0)
    StrPut(msg, buf, "UTF-16")
    cds := Buffer(A_PtrSize * 3, 0)                   ; COPYDATASTRUCT 结构体
    NumPut("Ptr",  0,       cds, 0)                   ; dwData (未使用)
    NumPut("UInt", size,    cds, A_PtrSize)           ; cbData (字节数)
    NumPut("Ptr",  buf.Ptr, cds, A_PtrSize * 2)       ; lpData (指向消息文本)
    res := 0
    return DllCall("User32\SendMessageTimeoutW", "Ptr", target, "UInt", 0x4A
        , "Ptr", A_ScriptHwnd, "Ptr", cds.Ptr
        , "UInt", 0x2, "UInt", 2000, "UInt*", &res, "Ptr") ? true : false
}
