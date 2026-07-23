#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
; ==============================================================================
; OSD Example — Timed Notification Scheduler
; ==============================================================================
;
; [What] A standalone daemon that pops OSD notifications on a schedule.
;   Communicates entirely via the external OSD interface — zero dependency
;   on wm.ahk internal features.
;
; [Seven time formats]
;   */N              — Interval: every N minutes (from 00:00)
;   HHMM             — Daily: at HH:MM each day
;   W_HHMM           — Weekly: on weekday W (1=Mon..7=Sun) at HH:MM
;   YYYY_MM_DD_HHMM  — Once: on the specified date+time
;
;   HHMM_*/N         — Daily start + every N min (from HH:MM until 24:00)
;   HHMM_*/NxC       — Same as above, limited to C total firings
;   W_HHMM_*/N[xC]   — Weekly start + every N min (on that day, opt. count)
;   YYYY_MM_DD_HHMM_*/N[xC] — Once start + every N min (on that day, opt. count)
;
; [Key suffix behavior]
;   e.g. 1200_*/30 → silent from 00:00–11:59, fires every 30 min from
;   12:00 until 24:00. Resets next day — waits again until 12:00.
;
; ═══════════════════════════════════════════════════════════════
; [Configuration] Edit the RULES array below. Each entry:
;
;   { time: "format", text: "message",
;     dur: seconds, opts: "key=val,key=val" }
;
;   opts — all optional (fall back to config defaults):
;   ┌────────┬──────────────────────────┬─────────────────────┐
;   │ Key    │ Meaning                  │ Example             │
;   ├────────┼──────────────────────────┼─────────────────────┤
;   │ fs=N   │ Font size (pt)           │ fs=36               │
;   │ op=N   │ Opacity (0-100)          │ op=90               │
;   │ pos=N  │ Vertical position %      │ pos=30              │
;   │ x=N[%] │ Horizontal pos (px or %) │ x=50%  x=300        │
;   │ y=N[%] │ Vertical pos (px or %)   │ y=20%  y=100        │
;   │ bg=…   │ Background (6-hex)       │ bg=CC3333           │
;   │ tx=…   │ Text color (6-hex)       │ tx=FFFFFF           │
;   │ wr=N   │ Max width (px, wraps)    │ wr=400              │
;   │ rd=…   │ Rounded corners on|off   │ rd=on               │
;   │ rr=N   │ Corner radius (px)       │ rr=20               │
;   │ fn=…   │ Font face                │ fn=Consolas         │
;   │ tag=…  │ Label (same-tag replace) │ tag=alert           │
;   └────────┴──────────────────────────┴─────────────────────┘
;
;   Multi-line: use `n in text — "Line one`nLine two"
;
; [How] SetTimer fires every 30s. Matching rules trigger OSD via WM_COPYDATA.
;   Each time-slot fires at most once (FIRED map). Midnight auto-reset.
;
; [Prerequisites] 1. wm.ahk running  2. Edit RULES  3. Keep daemon running
; [Exit] Tray icon right-click → Exit
; ==============================================================================

; ╔══════════════════════════════════════════════════════════════╗
; ║                   CONFIGURE YOUR RULES HERE                 ║
; ╚══════════════════════════════════════════════════════════════╝
global RULES := [
    ; ── Interval: every 30 min (all day) ──
    {time: "*/30",  text: "👀 30 minutes have passed. Stand up and stretch!",
        dur: 8, opts: "fs=22,bg=2E5E8E,tx=FFF,op=92,x=50%,y=15%"},

    ; ── Daily ──
    {time: "0900",  text: "☕ Good morning! What's the plan today?",
        dur: 6, opts: "fs=28,bg=FF8C42,tx=FFF,op=90,pos=25,rr=14"},
    {time: "1200",  text: "🍜 Lunch time! Step away from the screen.",
        dur: 6, opts: "fs=26,bg=4CAF50,tx=FFF,op=88,pos=85,rr=16"},
    {time: "1500",  text: "🍵 Afternoon tea!`nStand up, stretch, look out the window.",
        dur: 7, opts: "fs=22,bg=8B5CF6,tx=FFF,op=85,wr=350,pos=80,rr=14"},

    ; ── Weekly ──
    {time: "5_1700", text: "🎉 TGIF! Have a great weekend!",
        dur: 8, opts: "fs=32,bg=A020F0,tx=FFD700,op=92,pos=50,rr=20"},

    ; ── Daily: evening wind-down (bottom-right, small font) ──
    {time: "2100",  text: "🌙 Getting late. Time to wind down.",
        dur: 6, opts: "fs=16,bg=1E1E2E,tx=9ECE6A,op=80,x=90%,y=90%"},

    ; ── Daily start + interval suffix examples (uncomment to test) ──
    ; {time: "0900_*/15",    text: "☕ Every 15 min",    dur: 5, opts: "fs=18,pos=85"},
    ; {time: "1400_*/20x3",  text: "⏰ Afternoon ×3",   dur: 5, opts: "fs=18,pos=85"},
    ; ── Weekly start + interval suffix ──
    ; {time: "5_1200_*/30",  text: "🎉 Friday every 30 min", dur: 5, opts: "fs=18,pos=85"},
    ; ── Once start + interval suffix ──
    ; {time: "2026_12_25_0800_*/60x4", text: "🎄 Merry Christmas!", dur: 8, opts: "fs=24,pos=50"},
]
; ═══════════════════════════════════════════════════════════════

global FIRED       := Map()
global LAST_DAY    := FormatTime(, "yyyyMMdd")

; ---- Parse time spec ----
ParseTime(t) {
    t := Trim(t)

    ; ── Check for _*/N or _*/NxC suffix ──
    if RegExMatch(t, "^(.+)_(\*\/\d+)(?:x(\d+))?$", &sf) {
        prefix    := sf[1]
        interval  := Integer(RegExReplace(sf[2], "\*\/", ""))
        maxCount  := (sf.Count >= 3 && sf[3] != "") ? Integer(sf[3]) : 0

        ; Once + interval: YYYY_MM_DD_HHMM_*/N[xC]
        if RegExMatch(prefix, "^(\d{4})_(\d{2})_(\d{2})_(\d{2})(\d{2})$", &pm)
            return {type: "once_iv", baseMins: Integer(pm[4])*60+Integer(pm[5])
                , year: Integer(pm[1]), month: Integer(pm[2]), day: Integer(pm[3])
                , interval: interval, maxCount: maxCount}

        ; Weekly + interval: W_HHMM_*/N[xC]
        if RegExMatch(prefix, "^(\d)_(\d{2})(\d{2})$", &pm)
            return {type: "weekly_iv", baseMins: Integer(pm[2])*60+Integer(pm[3])
                , wday: Integer(pm[1]), interval: interval, maxCount: maxCount}

        ; Daily + interval: HHMM_*/N[xC]
        if RegExMatch(prefix, "^(\d{2})(\d{2})$", &pm)
            return {type: "daily_iv", baseMins: Integer(pm[1])*60+Integer(pm[2])
                , interval: interval, maxCount: maxCount}

        return 0
    }

    ; ── No suffix: four original formats ──
    ; Simple interval: */N
    if RegExMatch(t, "^\*\/(\d+)$", &m)
        return {type: "interval", interval: Max(1, Integer(m[1]))}

    ; Once: YYYY_MM_DD_HHMM
    if RegExMatch(t, "^(\d{4})_(\d{2})_(\d{2})_(\d{2})(\d{2})$", &m)
        return {type: "once", mins: Integer(m[4])*60+Integer(m[5])
            , year: Integer(m[1]), month: Integer(m[2]), day: Integer(m[3])}

    ; Weekly: W_HHMM
    if RegExMatch(t, "^(\d)_(\d{2})(\d{2})$", &m)
        return {type: "weekly", mins: Integer(m[2])*60+Integer(m[3]), wday: Integer(m[1])}

    ; Daily: HHMM
    if RegExMatch(t, "^(\d{2})(\d{2})$", &m)
        return {type: "daily", mins: Integer(m[1])*60+Integer(m[2])}

    return 0
}

; ---- Main check (every 30s) ----
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

        ; ── Simple interval */N ──
        if (pt.type == "interval") {
            fireKey := "i_" . pt.interval . "_" . (nowMins // pt.interval)
            shouldFire := (Mod(nowMins, pt.interval) == 0)

        ; ── Daily HHMM ──
        } else if (pt.type == "daily") {
            fireKey := "d_" . pt.mins
            shouldFire := (nowMins == pt.mins)

        ; ── Weekly W_HHMM ──
        } else if (pt.type == "weekly") {
            if (pt.wday != userWDay)
                continue
            fireKey := "w_" . pt.wday . "_" . pt.mins
            shouldFire := (nowMins == pt.mins)

        ; ── Once YYYY_MM_DD_HHMM ──
        } else if (pt.type == "once") {
            if (pt.year != nowY || pt.month != nowMon || pt.day != nowD)
                continue
            fireKey := "o_" . rule.time
            shouldFire := (nowMins == pt.mins)

        ; ── Daily + interval HHMM_*/N[xC] ──
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

        ; ── Weekly + interval W_HHMM_*/N[xC] ──
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

        ; ── Once + interval YYYY_MM_DD_HHMM_*/N[xC] ──
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

; ---- Send OSD via WM_COPYDATA (independent buffer + 2s timeout) ----
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
