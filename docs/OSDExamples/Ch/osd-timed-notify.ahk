#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
; ==============================================================================
; OSD 示例 4 — 定时通知调度器
; ==============================================================================
;
; 【功能说明】
;   独立运行的定时通知守护脚本。定义时间+内容规则，到时间自动弹出 OSD。
;   完全通过外部 OSD 接口（AHK_WM_OSD）实现，不依赖 wm.ahk 的任何内置功能。
;   Unix 风格——一个小脚本只做一件事。
;
; 【支持的时间格式】
;   HHMM               — 天循环：每天 HH:MM 触发
;   W_HHMM             — 周循环：每周第 W 天（1=周一..7=周日）触发
;   YYYY_MM_DD_HHMM    — 单次：指定日期时间触发一次
;
; 【如何配置】
;   修改下方的 RULES 数组。每条规则是一个对象：
;     {time: "时间格式", text: "通知内容", dur: 持续秒数, opts: "键=值,..."}
;
;   opts 可选——不填则使用配置文件默认值。可用键：
;     fs=N, op=N, pos=N, bg=RRGGBB, tx=RRGGBB, wr=N, rd=on|off, rr=N, fn=名称
;   完整文档见 osd-custom-all.ahk
;
;   示例：
;     {time: "0900",  text: "晨会！",      dur: 5, opts: "fs=30,bg=FF6644,tx=FFF,pos=30"}
;     {time: "1322",  text: "下午茶！",    dur: 5, opts: "fs=24,bg=4CAF50,tx=FFF,rr=20"}
;     {time: "5_1700", text: "周末快乐！",  dur: 5, opts: "fs=28,bg=A020F0,op=85,pos=85"}
;
; 【工作原理】
;   SetTimer 每 30 秒触发一次检查。比较当前时间（HH:MM）与规则匹配。
;   匹配时通过 WM_COPYDATA 发送 OSD，并将规则标记为"已触发"（防抖）。
;   已触发集合在午夜自动清空，天/周循环规则第二天重新生效。
;   单次规则以完整日期为 key，永不重复触发。
;
; 【使用前提】
;   1. wm.ahk 必须正在运行
;   2. 运行前编辑 RULES 数组
;   3. 保持本脚本运行（后台守护进程）
;
; 【操作】
;   Esc — 退出守护进程
; ==============================================================================

; ==================== 在这里配置你的通知规则 ====================
; 每条规则：{time, text, dur, opts?} — opts 可选（见上方说明）
global RULES := [
    {time: "0957",   text: "☕ Good morning! Time to start the day.",
        dur: 5, opts: "fs=28,bg=FF8C42,tx=FFFFFF,op=90,pos=25,rr=12"},
    {time: "1200",   text: "🍜 Lunch break! Take a rest.",
        dur: 5, opts: "fs=26,bg=4CAF50,tx=FFFFFF,op=88,pos=80,rr=16"},
    {time: "1322",   text: "🍵 Tea time! Stretch and refresh.",
        dur: 5, opts: "fs=24,bg=8B5CF6,tx=FFFFFF,op=85,pos=85,rr=14"},
    {time: "5_1700", text: "🎉 Happy Friday! Weekend ahead!",
        dur: 6, opts: "fs=30,bg=A020F0,tx=FFD700,op=92,pos=50,rr=20"},
    ; One-shot example (uncomment to test):
    ; {time: "2026_12_25_0800", text: "🎄 Merry Christmas!",
    ;     dur: 10, opts: "fs=36,bg=CC3333,tx=FFFFFF,op=95,pos=40,rr=18"}
]
; ================================================================

global FIRED    := Map()   ; 已触发 key 集合（防抖）
global LAST_DAY := ""      ; 日期追踪，午夜重置

; ---- 解析时间规格 → {type, mins[, wday][, year, month, day]} ----
ParseTime(t) {
    t := Trim(t)
    ; 单次：YYYY_MM_DD_HHMM
    if RegExMatch(t, "^(\d{4})_(\d{2})_(\d{2})_(\d{2})(\d{2})$", &m)
        return {type: "once", mins: Integer(m[4])*60+Integer(m[5])
            , year: Integer(m[1]), month: Integer(m[2]), day: Integer(m[3])}
    ; 周循环：W_HHMM（W=1..7 周一..周日）
    if RegExMatch(t, "^(\d)_(\d{2})(\d{2})$", &m)
        return {type: "weekly", mins: Integer(m[2])*60+Integer(m[3]), wday: Integer(m[1])}
    ; 天循环：HHMM
    if RegExMatch(t, "^(\d{2})(\d{2})$", &m)
        return {type: "daily", mins: Integer(m[1])*60+Integer(m[2])}
    return 0
}

; ---- 检查所有规则并在匹配时触发 OSD（每 30 秒调用）----
CheckAndFire() {
    global FIRED, LAST_DAY, RULES

    ; 午夜重置已触发集合
    today := FormatTime(, "yyyyMMdd")
    if (LAST_DAY != today) {
        FIRED := Map()
        LAST_DAY := today
    }

    nowMins  := A_Hour * 60 + A_Min
    userWDay := (A_WDay == 1) ? 7 : A_WDay - 1   ; 1=周一..7=周日
    nowY     := Integer(FormatTime(, "yyyy"))
    nowMon   := Integer(FormatTime(, "MM"))
    nowD     := Integer(FormatTime(, "dd"))

    for rule in RULES {
        pt := ParseTime(rule.time)
        if !IsObject(pt)
            continue

        fireKey := "", shouldFire := false
        switch pt.type {
        case "daily":
            fireKey := "d_" . pt.mins
            shouldFire := (nowMins == pt.mins)
        case "weekly":
            if (pt.wday != userWDay)
                continue
            fireKey := "w_" . pt.wday . "_" . pt.mins
            shouldFire := (nowMins == pt.mins)
        case "once":
            if (pt.year != nowY || pt.month != nowMon || pt.day != nowD)
                continue
            fireKey := "o_" . rule.time
            shouldFire := (nowMins == pt.mins)
        }

        if (!shouldFire || FIRED.Has(fireKey))
            continue

        FIRED[fireKey] := true
        durMs := (rule.dur > 0) ? rule.dur * 1000 : 3000
        ruleOpts := rule.HasOwnProp("opts") ? rule.opts : ""
        AHK_WM_OSD(rule.text, durMs, ruleOpts)
    }
}

; ---- 每 30 秒轮询（分钟级精度足够）----
SetTimer(CheckAndFire, 30000)
CheckAndFire()   ; 启动时立刻检查一次
Esc::ExitApp

; ------------------------------------------------------------------------------
; AHK_WM_OSD(text, duration, opts) —— 参见 osd-custom-all.ahk 完整参数文档
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
