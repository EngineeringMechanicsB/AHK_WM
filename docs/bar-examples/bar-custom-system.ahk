#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
; ==============================================================================
; AHK_WM bar 外部部件示例 3：获取当前窗口信息（窗口名称 + 位置大小）
; ==============================================================================
; 【功能说明】
;   实时获取当前活动窗口的标题和位置/大小信息，推送到 AHK_WM 状态栏。
;   显示格式: "[窗口标题前10字…] (左,上)-(右,下) 宽x高"
;   例如: "[记事本] (100,200)-(900,600) 800x400"
;   每 1 秒刷新一次，直观展示如何采集系统信息并推送到 bar。
;
; 【使用前提】
;   1. AHK_WM (wm.ahk) 正在运行
;   2. 配置文件 [Bar] Layout 中放置 external_3 部件，例如：
;        Layout=desktops,(1-3)/20;external_3,(14-17)/20,89B4FA,A6E3A1,tx;time,20/20;
;      建议留足空间（跨度至少 4 列），因为窗口信息文本较长
;
; 【工作原理】
;   每 1 秒执行一次 PushWinInfo():
;     1. WinExist("A") 获取当前活动窗口句柄
;     2. WinGetTitle(hwnd) 获取窗口标题，截取前 15 字避免过长
;     3. WinGetPos(&x, &y, &w, &h) 获取窗口位置和大小
;     4. 格式化为紧凑文本推送到 bar
;   如果当前活动窗口是 bar 自身或桌面，则显示 "—" 占位
;
; 【调用方式】
;   WMBarPush(槽位号, "要显示的文本")
;   本脚本采集的是 WinTitle + WinGetPos 信息，你可以替换成任何其他系统信息：
;   - CPU 占用率 (通过 WMI/PDH)
;   - 内存使用量
;   - 网络速度
;   - 电池电量状态
;   - 当前播放的音乐
;
; 【扩展思路】
;   - 添加窗口类名 (WinGetClass) 来区分不同类型的窗口
;   - 添加进程名 (WinGetProcessName) 来显示是哪个程序
;   - 只在窗口切换时才更新，节省 CPU
;
; 【注意】
;   - WinGetPos 获取的是窗口矩形（含边框），不是客户区
;   - 最小化窗口的位置可能不准确
;   - 如果窗口标题包含隐私信息，建议做脱敏处理
; ==============================================================================

; ---- 全局状态 / Global state ----
; 缓存上次的窗口句柄，避免相同的窗口重复计算
global LastHwnd := 0

; ---- 定时推送回调 / Periodic push callback ----
; 每 1000ms 由 SetTimer 触发
PushWinInfo() {
    global LastHwnd
    hwnd := 0
    try hwnd := WinExist("A")                              ; 当前活动窗口 / Active window
    if (!hwnd) {
        WMBarPush(3, "[no window]")
        return
    }
    ; 跳过桌面和任务栏 / Skip desktop & taskbar
    cls := WinGetClass(hwnd)
    if (cls = "Progman" || cls = "WorkerW" || cls = "Shell_TrayWnd") {
        WMBarPush(3, "[Desktop]")
        return
    }
    ; 如果窗口没变，跳过更新节省资源 / Skip update if same window
    if (hwnd = LastHwnd)
        return
    LastHwnd := hwnd

    ; ---- 采集窗口信息 / Collect window info ----
    ; 窗口标题 / Window title
    title := ""
    try title := WinGetTitle(hwnd)
    if (title = "")
        title := "(untitled)"
    ; 截断过长的标题 / Truncate long titles
    if (StrLen(title) > 15)
        title := SubStr(title, 1, 14) . "…"

    ; 窗口位置和大小 / Window position & size
    try WinGetPos(&x, &y, &w, &h, hwnd)

    ; ---- 格式化输出 / Format output ----
    ; 格式: "[标题前15字] (左,上) 宽x高"
    text := Format("[{}] ({},{}) {}x{}", title, x, y, w, h)
    WMBarPush(3, text)
}

PushWinInfo()                     ; 立即推送首个值 / Push the first value immediately
SetTimer(PushWinInfo, 1000)       ; 之后每 1 秒更新 / Then update every 1 second

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
