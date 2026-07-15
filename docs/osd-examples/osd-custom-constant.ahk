#Requires AutoHotkey v2.0
#SingleInstance Force
; ==============================================================================
; AHK_WM OSD 外部调用示例 1：显示一条固定通知
; ==============================================================================
; 【功能说明】
;   向 AHK_WM 发送一条 OSD（屏幕中央弹出提示），显示固定文本并自动消失。
;   运行一次即可，文本在屏幕上显示指定时长后自动淡出。
;
; 【使用前提】
;   1. AHK_WM (wm.ahk) 正在运行
;   2. 无需任何配置文件修改——OSD 功能始终可用
;   3. OSD 消息格式: "OSD:文本[:持续时间ms]"，持续时间可选，默认 1000ms
;
; 【调用方式】
;   AHK_WM_OSD("要显示的文本", 持续时间毫秒)
;   持续时间: 文本在屏幕上停留的毫秒数（默认 1000 = 1秒）
;   支持 emoji 和中文，文本长度建议 <= 80 字
;
; 【工作原理】
;   通过 WM_COPYDATA 消息向 wm.ahk 主窗口发送 "OSD:文本:持续时间"。
;   wm.ahk 内部收到后调用 ShowOSD() 显示在屏幕中央。
;   单次调用、即时显示、自动消失。
;
; 【与 Bar 部件的区别】
;   - Bar 部件: 持续显示在状态栏上，适合持久信息（时钟、网速等）
;   - OSD 通知: 临时弹出后消失，适合一次性通知（任务完成、错误提示等）
;   - 两者使用同一个 WM_COPYDATA 通道，只是消息前缀不同（BAR: vs OSD:）
;
; 【注意】
;   - OSD 有防刷机制：短时间内重复调用可能被合并
;   - 持续时间太长会妨碍操作，建议 <= 5000ms
; ==============================================================================

AHK_WM_OSD("✅ 任务完成！", 3000)
Sleep(3000)
ExitApp

; ------------------------------------------------------------------------------
; AHK_WM_OSD(text, duration) —— 通用辅助函数，可直接复制到你自己的脚本中使用
; ------------------------------------------------------------------------------
; 参数:
;   text     - 要显示的文本内容（支持中文、emoji）
;   duration - 显示时长（毫秒），默认 1000
; 返回值: true=发送成功, false=未找到 wm.ahk 窗口
;
; 实现细节:
;   1. DetectHiddenWindows 找到隐藏的 wm.ahk 主窗口
;   2. 构造消息 "OSD:文本:持续时间"
;   3. 通过 SendMessage 发送 WM_COPYDATA (0x4A) 消息
;   4. 消息编码为 UTF-16，确保中文和 emoji 正确显示
;
; 适用场景:
;   - 脚本/任务完成后的通知（如："备份完成"）
;   - 系统事件的即时提示（如："WiFi 已连接"）
;   - 键盘快捷键的视觉反馈
;   - 调试/状态确认（如："配置已重载"）
; ------------------------------------------------------------------------------
AHK_WM_OSD(text, duration := 1000) {
    DetectHiddenWindows(true)
    h := WinExist("wm.ahk ahk_class AutoHotkey")
    if !h
        return false
    payload := "OSD:" . text . ":" . duration
    ; ---- 构建 COPYDATASTRUCT 并通过 SendMessage 发送 ----
    c := StrPut(payload, "UTF-16")                     ; UTF-16 字节数（含 NUL）
    b := Buffer(A_PtrSize * 3, 0)                      ; COPYDATASTRUCT
    NumPut("Ptr", 0, b, 0)                             ; dwData (未使用)
    NumPut("UInt", c, b, A_PtrSize)                    ; cbData (字节数)
    NumPut("Ptr", StrPtr(payload), b, A_PtrSize * 2)   ; lpData (指向消息文本)
    try SendMessage(0x4A, 0, b.Ptr, , "ahk_id " . h)   ; WM_COPYDATA
    return true
}
