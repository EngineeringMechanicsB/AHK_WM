#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
; ==============================================================================
; AHK_WM bar 外部部件示例 2：动态变量推送（符号轮换 + 数值递增）
; ==============================================================================
; 【功能说明】
;   向 AHK_WM 状态栏的 external_2 槽位推送持续变化的内容。
;   左侧是一个符号在不断轮换（视觉上能看到"动画"效果），
;   右侧是一个从 0 开始持续递增的数值，直观展示动态更新能力。
;   显示效果类似:  ◉ 42  一秒后 →  ◉ 43  …  ◎ 100  一秒后 →  ◎ 101 …
;
; 【使用前提】
;   1. AHK_WM (wm.ahk) 正在运行
;   2. 配置文件 [Bar] Layout 中放置 external_2 部件，例如：
;        Layout=desktops,(1-3)/20;external_2,(13-15)/20,7AA2F7,9ECE6A,tx;time,20/20;
;      建议用 tx 模式（渐变文字）+ 双色，这样文字颜色会随渐变而变化，更有动态感。
;
; 【工作原理】
;   每 1 秒执行一次 PushTick():
;     1. 符号每 3 次切换一次（◉ → ◈ → ◆ → ◎ → ◉ …），制造视觉变化
;     2. 数值持续递增（1, 2, 3, 4 …），展示实时更新
;     3. 右侧数值每达到 100 自动归零，模拟"周期计数器"
;   使用 SetTimer 定时调用，无需手动循环。
;
; 【调用方式】
;   WMBarPush(槽位号, "要显示的文本")
;   在 SetTimer 的回调函数中调用，实现周期性更新。
;   推荐间隔 >= 500ms，避免刷新过快 bar 来不及渲染。
;
; 【扩展思路】
;   - 把数值换成 CPU/内存占用 → 系统监控
;   - 把符号换成天气图标 + 温度 → 天气显示
;   - 把数值换成倒计时 → 番茄钟/计时器
;   - 把符号换成播放状态图标 + 歌名 → 音乐播放器
;
; 【注意】
;   - 退出本脚本后 bar 保留最后一次推送的值
;   - SetTimer 的回调函数会在独立线程中执行，互不阻塞
;   - 脚本中 Counter 在函数外初始化，函数内用 global 声明访问
; ==============================================================================

; ---- 全局状态 / Global state ----
; Counter: 递增的数值，每次 PushTick 调用 +1
; SymbolIdx: 符号数组的索引，每 3 次 +1 实现符号轮换
global Counter := 0
global SymbolIdx := 1
; 轮换的符号池 / Pool of cycling symbols
global Symbols := ["◉", "◈", "◆", "◎"]

; ---- 定时推送回调 / Periodic push callback ----
; 每 1000ms 由 SetTimer 触发
PushTick() {
    global Counter, SymbolIdx, Symbols
    Counter++
    ; 每 3 次计数切换一个符号，制造"慢速轮换"的视觉效果
    ; Change symbol every 3 ticks for a "slow rotation" visual effect
    if (Mod(Counter, 3) = 0)
        SymbolIdx := Mod(SymbolIdx, Symbols.Length) + 1
    sym := Symbols[SymbolIdx]
    ; 数值每 100 自动归零，模拟周期计数器 / wrap every 100 for a cycle effect
    val := Mod(Counter, 100)
    ; 格式化输出: 符号 数值（如 "◉ 42"）
    WMBarPush(2, Format("{} {:3d}", sym, val))
}

PushTick()                        ; 立即推送首个值 / Push the first value immediately
SetTimer(PushTick, 1000)          ; 之后每 1 秒更新 / Then update every 1 second

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
