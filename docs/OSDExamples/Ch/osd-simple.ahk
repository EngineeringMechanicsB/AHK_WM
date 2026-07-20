#Requires AutoHotkey v2.0
#SingleInstance Force
; ==============================================================================
; OSD 示例 1 — 简单调用（无自定义选项）
; ==============================================================================
;
; 【功能说明】
;   向 AHK_WM 发送一条 OSD 通知，只传文本和持续时间，不做任何外观自定义。
;   所有视觉设置（字体、颜色、位置、透明度）完全使用 wm_config.ini 中
;   [GUI] 配置节的全局默认值。
;
; 【使用前提】
;   1. AHK_WM (wm.ahk) 必须正在运行
;   2. 无需修改配置文件——OSD 功能始终可用
;
; 【工作原理】
;   构造消息 "OSD:文本:持续时间"，通过 WM_COPYDATA 发送到 wm.ahk 主窗口。
;   wm.ahk 内部调用 OSD.Show() 在当前显示器中央弹出通知。
;
;   消息格式：OSD:<文本>:<持续时间毫秒>
;     - 文本：   任意 UTF-8 字符串（支持中文、emoji）
;     - 持续时间：弹窗停留的毫秒数（默认 1000）
;
; 【使用方法】
;   双击运行本脚本。会看到一条弹窗，3 秒后自动消失。
;
; 【自定义外观】
;   参见 osd-custom-all.ahk —— 支持逐次调用的颜色/大小/位置等全部覆盖。
; ==============================================================================

AHK_WM_OSD("你好！这是一条简单的 OSD 通知。", 3000)
Sleep(3500)
ExitApp

; ------------------------------------------------------------------------------
; AHK_WM_OSD(text, duration, opts) —— 通用辅助函数，可直接复制到你的脚本中使用
; ------------------------------------------------------------------------------
; 参数：
;   text     - 要显示的文本内容（UTF-8，支持中文和 emoji）
;   duration - 显示时长（毫秒），默认 1000。设为 0 则持续显示直到被下一条覆盖
;   opts     - （可选）逐次调用的外观覆盖，格式 "键=值,键=值"
;              不传则完全使用 wm_config.ini 中的全局默认值
;              全部可用键参见 osd-custom-all.ahk
;
; 返回值：true=发送成功，false=未找到 wm.ahk 窗口
;
; 实现细节：
;   1. 通过 DetectHiddenWindows 找到隐藏的 wm.ahk 主窗口
;   2. 构造消息 "OSD:文本:持续时间[:选项]"
;   3. 编码为 UTF-16，通过 SendMessage 发送 WM_COPYDATA (0x4A) 消息
; ------------------------------------------------------------------------------
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
