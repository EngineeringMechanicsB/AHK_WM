#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
; ==============================================================================
; OSD 示例 — 定时通知调度器
; ==============================================================================
;
; 【功能】独立运行的定时通知守护脚本。按规则在指定时间弹出 OSD 提示。
;   完全通过外部 OSD 接口通信，不依赖 wm.ahk 内置功能。
;
; 【四种时间模式】
;   */N        — 间隔循环：每 N 分钟触发一次  (如 */30 = 每30分钟)
;   HHMM       — 天循环：  每天 HH:MM 触发     (如 0900 = 每天9点)
;   W_HHMM     — 周循环：  每周第W天 HH:MM 触发 (W=1周一..7周日)
;   YYYY_MM_DD_HHMM — 单次：指定日期时间触发一次
;
; ═══════════════════════════════════════════════════════════════
; 【如何配置】修改下方 RULES 数组。每条规则一个 {}：
;
;   { time: "时间格式", text: "通知文字",
;     dur: 持续秒数, opts: "键=值,键=值" }
;
;   opts 全部可选，不填则用配置文件默认值。支持的全部键：
;   ┌────────┬──────────────────────┬──────────────────────────┐
;   │ 键     │ 含义                 │ 示例                     │
;   ├────────┼──────────────────────┼──────────────────────────┤
;   │ fs=N   │ 字体大小(磅)         │ fs=36                    │
;   │ op=N   │ 不透明度(0-100)      │ op=90                    │
;   │ pos=N  │ 垂直位置%(0=顶100=底)│ pos=30                   │
;   │ x=N[%] │ 水平坐标(px或%)      │ x=50%  x=300             │
;   │ y=N[%] │ 垂直坐标(px或%)      │ y=20%  y=100             │
;   │ bg=…   │ 背景色(6位hex)       │ bg=CC3333                │
;   │ tx=…   │ 文字色(6位hex)       │ tx=FFFFFF                │
;   │ wr=N   │ 最大宽度(px,超宽换行)│ wr=400                   │
;   │ rd=…   │ 圆角开关(on|off)     │ rd=on                    │
;   │ rr=N   │ 圆角半径(px)         │ rr=20                    │
;   │ fn=…   │ 字体名称             │ fn=Consolas              │
;   │ tag=…  │ 逻辑标签(同tag替换)  │ tag=alert                │
;   └────────┴──────────────────────┴──────────────────────────┘
;
;   换行：文本中加 `n 即换行，如 "第一行`n第二行"
;
; 【工作原理】SetTimer 每 30 秒检查一次，匹配规则即触发 OSD。
;   同一分钟内不会重复触发。午夜自动重置，天/周/间隔循环永续。
;
; 【前提】1.wm.ahk 运行中  2.编辑 RULES 后保存  3.保持本脚本运行
; 【操作】Esc — 退出
; ==============================================================================

; ╔══════════════════════════════════════════════════════════════╗
; ║                 在这里配置你的通知规则                       ║
; ╚══════════════════════════════════════════════════════════════╝
global RULES := [
    ; ── 间隔循环：每 30 分钟提醒休息 ──
    {time: "*/30",  text: "👀 已经工作30分钟了，起来活动一下！",
        dur: 8, opts: "fs=22,bg=2E5E8E,tx=FFFFFF,op=92,pos=tc,x=50%"},

    ; ── 天循环：上午启动提醒 ──
    {time: "0900",  text: "☕ 早上好！今天有什么计划？",
        dur: 6, opts: "fs=28,bg=FF8C42,tx=FFF,op=90,pos=25,rr=14"},

    ; ── 天循环：午休 ──
    {time: "1200",  text: "🍜 午饭时间！别看屏幕了。",
        dur: 6, opts: "fs=26,bg=4CAF50,tx=FFF,op=88,pos=85,rr=16"},

    ; ── 天循环：下午茶（多行+窄宽自动换行）──
    {time: "1500",  text: "🍵 下午茶时间！`n站起来走走，看看窗外。",
        dur: 7, opts: "fs=22,bg=8B5CF6,tx=FFF,op=85,wr=350,pos=80,rr=14"},

    ; ── 周循环：周五下班 ──
    {time: "5_1700", text: "🎉 TGIF！周末快乐！",
        dur: 8, opts: "fs=32,bg=A020F0,tx=FFD700,op=92,pos=50,rr=20"},

    ; ── 天循环：晚间提醒（右下角小字）──
    {time: "2100",  text: "🌙 夜深了，准备休息吧。",
        dur: 6, opts: "fs=16,bg=1E1E2E,tx=9ECE6A,op=80,pos=br"},

    ; ── 单次示例（取消注释即可测试，改为当前时间+1分钟）──
    ; {time: "2026_12_25_0800", text: "🎄 圣诞快乐！",
    ;     dur: 10, opts: "fs=36,bg=CC3333,tx=FFF,op=95,pos=40,rr=18,tag=xmas"},
]
; ═══════════════════════════════════════════════════════════════

global FIRED       := Map()   ; 已触发 key（防抖）
global LAST_DAY    := ""      ; 日期追踪（午夜重置）
global LAST_MIN    := 0       ; 上次检查的分钟（间隔模式用）

; ---- 解析时间规格 ----
ParseTime(t) {
    t := Trim(t)
    ; 间隔：*/N — 每 N 分钟
    if RegExMatch(t, "^\*\/(\d+)$", &m)
        return {type: "interval", interval: Max(1, Integer(m[1]))}
    ; 单次：YYYY_MM_DD_HHMM
    if RegExMatch(t, "^(\d{4})_(\d{2})_(\d{2})_(\d{2})(\d{2})$", &m)
        return {type: "once", mins: Integer(m[4])*60+Integer(m[5])
            , year: Integer(m[1]), month: Integer(m[2]), day: Integer(m[3])}
    ; 周循环：W_HHMM
    if RegExMatch(t, "^(\d)_(\d{2})(\d{2})$", &m)
        return {type: "weekly", mins: Integer(m[2])*60+Integer(m[3]), wday: Integer(m[1])}
    ; 天循环：HHMM
    if RegExMatch(t, "^(\d{2})(\d{2})$", &m)
        return {type: "daily", mins: Integer(m[1])*60+Integer(m[2])}
    return 0
}

; ---- 主检查（每30秒）----
CheckAndFire() {
    global FIRED, LAST_DAY, LAST_MIN, RULES

    ; 午夜重置
    today := FormatTime(, "yyyyMMdd")
    if (LAST_DAY != today) {
        FIRED := Map()
        LAST_DAY := today
        LAST_MIN := 0
    }

    nowMins  := A_Hour * 60 + A_Min
    userWDay := (A_WDay == 1) ? 7 : A_WDay - 1
    nowY     := Integer(FormatTime(, "yyyy"))
    nowMon   := Integer(FormatTime(, "MM"))
    nowD     := Integer(FormatTime(, "dd"))

    for rule in RULES {
        pt := ParseTime(rule.time)
        if !IsObject(pt)
            continue

        fireKey := "", shouldFire := false
        switch pt.type {
        case "interval":
            ; 间隔模式：当前分钟对间隔取模=0时触发
            if (nowMins == LAST_MIN)
                continue
            slot := (nowMins // pt.interval) * pt.interval
            fireKey := "i_" . pt.interval . "_" . slot
            shouldFire := (Mod(nowMins, pt.interval) == 0)
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
        LAST_MIN := nowMins
        durMs := (rule.dur > 0) ? rule.dur * 1000 : 3000
        ruleOpts := rule.HasOwnProp("opts") ? rule.opts : ""
        AHK_WM_OSD(rule.text, durMs, ruleOpts)
    }
}

SetTimer(CheckAndFire, 30000)
CheckAndFire()
Esc::ExitApp

; ------------------------------------------------------------------------------
; AHK_WM_OSD(text, duration_ms, opts)
;   通过 WM_COPYDATA 向 wm.ahk 发送 OSD 消息。
;   opts 格式："键=值,键=值"（全部可选，未指定回退配置文件默认值）
;   完整参数文档见 osd-custom-all.ahk
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
