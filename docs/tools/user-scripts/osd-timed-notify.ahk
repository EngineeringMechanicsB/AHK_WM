#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
; ==============================================================================
; OSD 定时通知调度器
; ==============================================================================
; 【时间格式】
;   */N              — 间隔：每 N 分钟（从 00:00 起）
;   HHMM             — 天循环：每天 HH:MM
;   W_HHMM           — 周循环：周 W(1-7) HH:MM
;   YYYY_MM_DD_HHMM  — 单次：指定时间
;
;   HHMM_*/N         — 天循环起 + 每 N 分钟（当天持续）
;   HHMM_*/NxC       — 同上，限 C 次
;   W_HHMM_*/N[xC]   — 周循环起 + 每 N 分钟（当天持续，可选次数）
;   YYYY_MM_DD_HHMM_*/N[xC] — 单次起 + 每 N 分钟（当天持续，可选次数）
;
; 【原理】每 30 秒检查。同分钟内不重复。午夜重置天/周循环。
; 【前提】wm.ahk 运行中 | 退出：托盘右键 → Exit
; ==============================================================================

; ╔══════════════════════════════════════════════════════════════╗
; ║                    通知规则配置                             ║
; ╚══════════════════════════════════════════════════════════════╝
global RULES := [
    ; ── 间隔：每 30 分钟 ──
    {time: "*/30", text: "👀 已经工作30分钟了，起来活动一下！",
        dur: 8, opts: "fs=22,bg=2E5E8E,tx=FFFFFF,op=92,x=50%,y=15%"},

    ; ── 天循环 ──
    {time: "0902", text: "☕ 早上好！",
        dur: 6, opts: "fs=28,bg=FF8C42,tx=FFF,op=90,pos=25,rr=14"},
    {time: "1155", text: "🍜 午饭时间！",
        dur: 6, opts: "fs=26,bg=4CAF50,tx=FFF,op=88,pos=85,rr=16"},
    {time: "1544", text: "🍵 休息时间！！站起来走走，看看窗外。",
        dur: 7, opts: "fs=22,bg=8B5CF6,tx=FFF,op=85,wr=350,pos=80,rr=14"},

    ; ── 周循环 ──
    {time: "5_1730", text: "🎉 周末快乐！",
        dur: 8, opts: "fs=32,bg=A020F0,tx=FFD700,op=92,pos=50,rr=30,x=90%,y=90%"},
    {time: "2_1658", text: " 做卫生 ",
        dur: 8, opts: "fs=32,bg=A020F0,tx=FFD700,op=92,pos=50,rr=30,x=90%,y=90%"},
    {time: "3_0903", text: " 开会 ",
        dur: 8, opts: "fs=32,bg=A020F0,tx=FFD700,op=92,pos=50,rr=30,x=90%,y=90%"},

    ; ── 示例：天循环 + 间隔后缀 ──
    ; {time: "0900_*/15", text: "每15分钟提醒", dur: 5, opts: "fs=18,pos=80"},
    ; {time: "1400_*/30x3", text: "下午3次提醒", dur: 5, opts: "fs=18,pos=80"},
    ; ── 示例：周循环 + 间隔后缀 ──
    ; {time: "5_1200_*/30", text: "周五午间每30分", dur: 5, opts: "fs=18,pos=80"},
    ; ── 示例：单次 + 间隔后缀 ──
    ; {time: "2026_12_25_0800_*/60x4", text: "圣诞4次提醒", dur: 8, opts: "fs=24"},
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

        ; 一级 + 间隔：YYYY_MM_DD_HHMM_*/N[xC]
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

; ---- 发送 OSD（WM_COPYDATA，独立 Buffer + 2s 超时）----
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
