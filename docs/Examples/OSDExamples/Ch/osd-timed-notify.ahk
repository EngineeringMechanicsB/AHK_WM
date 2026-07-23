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
; 【七种时间格式】
;   */N              — 间隔：每 N 分钟（从 00:00 起）
;   HHMM             — 天循环：每天 HH:MM
;   W_HHMM           — 周循环：周 W(1=周一..7=周日) HH:MM
;   YYYY_MM_DD_HHMM  — 单次：指定日期时间
;
;   HHMM_*/N         — 天循环起 + 每 N 分钟（HH:MM 后持续到 24:00）
;   HHMM_*/NxC       — 同上，总共 C 次后停止
;   W_HHMM_*/N[xC]   — 按周几的 HH:MM 起，每 N 分钟（当天持续，可选次数）
;   YYYY_MM_DD_HHMM_*/N[xC] — 指定日期 HH:MM 起，每 N 分钟（当天持续，可选次数）
;
; 【带后缀格式的关键行为】
;   例如 1200_*/30 → 每天 00:00–11:59 不触发，12:00 开始每 30 分钟触发
;   直到 24:00。第二天从 00:00 重新等待到 12:00 再开始。
;
; ═══════════════════════════════════════════════════════════════
; 【如何配置】修改下方 RULES 数组。每条规则一个 {}：
;
;   { time: "时间格式", text: "通知文字",
;     dur: 持续秒数, opts: "键=值,键=值" }
;
;   opts 全部可选，不填则用配置文件默认值：
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
; 【工作原理】SetTimer 每 30 秒检查，匹配规则即触发 OSD（WM_COPYDATA）。
;   同一时间槽不重复。午夜自动重置。
;
; 【前提】1.wm.ahk 运行中  2.编辑 RULES 后保存  3.保持本脚本运行
; 【退出】托盘图标右键 → Exit
; ==============================================================================

; ╔══════════════════════════════════════════════════════════════╗
; ║                 在这里配置你的通知规则                       ║
; ╚══════════════════════════════════════════════════════════════╝
global RULES := [
    ; ── 间隔循环：每 30 分钟（全天）──
    {time: "*/30",  text: "👀 已经工作30分钟了，起来活动一下！",
        dur: 8, opts: "fs=22,bg=2E5E8E,tx=FFFFFF,op=92,x=50%,y=15%"},

    ; ── 天循环 ──
    {time: "0900",  text: "☕ 早上好！今天有什么计划？",
        dur: 6, opts: "fs=28,bg=FF8C42,tx=FFF,op=90,pos=25,rr=14"},
    {time: "1200",  text: "🍜 午饭时间！别看屏幕了。",
        dur: 6, opts: "fs=26,bg=4CAF50,tx=FFF,op=88,pos=85,rr=16"},
    {time: "1500",  text: "🍵 下午茶时间！`n站起来走走，看看窗外。",
        dur: 7, opts: "fs=22,bg=8B5CF6,tx=FFF,op=85,wr=350,pos=80,rr=14"},

    ; ── 周循环 ──
    {time: "5_1700", text: "🎉 TGIF！周末快乐！",
        dur: 8, opts: "fs=32,bg=A020F0,tx=FFD700,op=92,pos=50,rr=20"},

    ; ── 天循环：晚间提醒（右下角小字）──
    {time: "2100",  text: "🌙 夜深了，准备休息吧。",
        dur: 6, opts: "fs=16,bg=1E1E2E,tx=9ECE6A,op=80,x=90%,y=90%"},

    ; ── 天循环起 + 间隔后缀示例（取消注释测试）──
    ; {time: "0900_*/15",    text: "☕ 每15分钟",  dur: 5, opts: "fs=18,pos=85"},
    ; {time: "1400_*/20x3",  text: "⏰ 下午3次",  dur: 5, opts: "fs=18,pos=85"},
    ; ── 周循环起 + 间隔后缀 ──
    ; {time: "5_1200_*/30",  text: "🎉 周五中午起每半小时", dur: 5, opts: "fs=18,pos=85"},
    ; ── 单次起 + 间隔后缀 ──
    ; {time: "2026_12_25_0800_*/60x4", text: "🎄 圣诞快乐", dur: 8, opts: "fs=24,pos=50"},
]
; ═══════════════════════════════════════════════════════════════

global FIRED       := Map()   ; 已触发 key（防抖）
global LAST_DAY    := FormatTime(, "yyyyMMdd")

; ---- 解析时间规格 ----
ParseTime(t) {
    t := Trim(t)

    ; ── 检查 _*/N 或 _*/NxC 后缀 ──
    if RegExMatch(t, "^(.+)_(\*\/\d+)(?:x(\d+))?$", &sf) {
        prefix    := sf[1]
        interval  := Integer(RegExReplace(sf[2], "\*\/", ""))
        maxCount  := (sf.Count >= 3 && sf[3] != "") ? Integer(sf[3]) : 0

        ; 单次 + 间隔：YYYY_MM_DD_HHMM_*/N[xC]
        if RegExMatch(prefix, "^(\d{4})_(\d{2})_(\d{2})_(\d{2})(\d{2})$", &pm)
            return {type: "once_iv", baseMins: Integer(pm[4])*60+Integer(pm[5])
                , year: Integer(pm[1]), month: Integer(pm[2]), day: Integer(pm[3])
                , interval: interval, maxCount: maxCount}

        ; 周循环 + 间隔：W_HHMM_*/N[xC]
        if RegExMatch(prefix, "^(\d)_(\d{2})(\d{2})$", &pm)
            return {type: "weekly_iv", baseMins: Integer(pm[2])*60+Integer(pm[3])
                , wday: Integer(pm[1]), interval: interval, maxCount: maxCount}

        ; 天循环 + 间隔：HHMM_*/N[xC]
        if RegExMatch(prefix, "^(\d{2})(\d{2})$", &pm)
            return {type: "daily_iv", baseMins: Integer(pm[1])*60+Integer(pm[2])
                , interval: interval, maxCount: maxCount}

        return 0
    }

    ; ── 无后缀：原有四种格式 ──
    ; 简单间隔：*/N
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
    global FIRED, LAST_DAY, RULES

    today := FormatTime(, "yyyyMMdd")
    if (LAST_DAY != today) {
        FIRED := Map()
        LAST_DAY := today
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

        fireKey := ""
        shouldFire := false

        ; ── 简单间隔 */N ──
        if (pt.type == "interval") {
            fireKey := "i_" . pt.interval . "_" . (nowMins // pt.interval)
            shouldFire := (Mod(nowMins, pt.interval) == 0)

        ; ── 天循环 HHMM ──
        } else if (pt.type == "daily") {
            fireKey := "d_" . pt.mins
            shouldFire := (nowMins == pt.mins)

        ; ── 周循环 W_HHMM ──
        } else if (pt.type == "weekly") {
            if (pt.wday != userWDay)
                continue
            fireKey := "w_" . pt.wday . "_" . pt.mins
            shouldFire := (nowMins == pt.mins)

        ; ── 单次 YYYY_MM_DD_HHMM ──
        } else if (pt.type == "once") {
            if (pt.year != nowY || pt.month != nowMon || pt.day != nowD)
                continue
            fireKey := "o_" . rule.time
            shouldFire := (nowMins == pt.mins)

        ; ── 天循环 + 间隔 HHMM_*/N[xC] ──
        } else if (pt.type == "daily_iv") {
            if (nowMins < pt.baseMins)
                continue
            elapsed := nowMins - pt.baseMins
            if (Mod(elapsed, pt.interval) != 0)
                continue
            slot := elapsed // pt.interval
            if (pt.maxCount > 0 && slot >= pt.maxCount)
                continue
            fireKey := "di_" . pt.baseMins . "_" . pt.interval . "_" . slot
            shouldFire := true

        ; ── 周循环 + 间隔 W_HHMM_*/N[xC] ──
        } else if (pt.type == "weekly_iv") {
            if (pt.wday != userWDay)
                continue
            if (nowMins < pt.baseMins)
                continue
            elapsed := nowMins - pt.baseMins
            if (Mod(elapsed, pt.interval) != 0)
                continue
            slot := elapsed // pt.interval
            if (pt.maxCount > 0 && slot >= pt.maxCount)
                continue
            fireKey := "wi_" . pt.wday . "_" . pt.baseMins . "_" . pt.interval . "_" . slot
            shouldFire := true

        ; ── 单次 + 间隔 YYYY_MM_DD_HHMM_*/N[xC] ──
        } else if (pt.type == "once_iv") {
            if (pt.year != nowY || pt.month != nowMon || pt.day != nowD)
                continue
            if (nowMins < pt.baseMins)
                continue
            elapsed := nowMins - pt.baseMins
            if (Mod(elapsed, pt.interval) != 0)
                continue
            slot := elapsed // pt.interval
            if (pt.maxCount > 0 && slot >= pt.maxCount)
                continue
            fireKey := "oi_" . pt.year . "_" . pt.month . "_" . pt.day
                . "_" . pt.baseMins . "_" . pt.interval . "_" . slot
            shouldFire := true
        }

        if (!shouldFire || FIRED.Has(fireKey))
            continue

        FIRED[fireKey] := true
        durMs := (rule.dur > 0) ? rule.dur * 1000 : 3000
        ruleOpts := rule.HasOwnProp("opts") ? rule.opts : ""
        _SendOSD(rule.text, durMs, ruleOpts)
    }
}

SetTimer(CheckAndFire, 30000)
CheckAndFire()

; ---- 发送 OSD（WM_COPYDATA，独立 Buffer + 2s 超时防止卡死）----
_SendOSD(text, duration, opts := "") {
    DetectHiddenWindows(true)
    h := WinExist("wm.ahk ahk_class AutoHotkey")
    if !h
        return false

    payload := "OSD:" . text . ":" . duration
    if (opts != "")
        payload .= ":" . opts

    dataSize := (StrLen(payload) + 1) * 2
    dataBuf := Buffer(dataSize, 0)
    StrPut(payload, dataBuf, "UTF-16")

    cds := Buffer(A_PtrSize * 3, 0)
    NumPut("Ptr", 0, cds, 0)
    NumPut("UInt", dataSize, cds, A_PtrSize)
    NumPut("Ptr", dataBuf.Ptr, cds, A_PtrSize * 2)

    res := 0
    DllCall("User32\SendMessageTimeoutW"
        , "Ptr", h
        , "UInt", 0x4A
        , "Ptr", A_ScriptHwnd
        , "Ptr", cds.Ptr
        , "UInt", 0x2
        , "UInt", 2000
        , "UInt*", &res
        , "Ptr")
    return true
}
