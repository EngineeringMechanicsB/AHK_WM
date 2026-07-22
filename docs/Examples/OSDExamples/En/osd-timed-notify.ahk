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
; [Four time modes]
;   */N        — Interval:  every N minutes        (e.g. */30 = every 30 min)
;   HHMM       — Daily:     at HH:MM each day      (e.g. 0900 = 9:00 AM)
;   W_HHMM     — Weekly:    on weekday W at HH:MM  (W=1 Mon..7 Sun)
;   YYYY_MM_DD_HHMM — Once: on the specified date+time
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
; [How] SetTimer fires every 30s.  Matching rules trigger OSD via
;   WM_COPYDATA.  Each rule fires at most once per minute (debounced).
;   Fired-set resets at midnight.
;
; [Prerequisites] 1. wm.ahk running  2. Edit RULES  3. Keep daemon running
; [Controls] Esc — exit
; ==============================================================================

; ╔══════════════════════════════════════════════════════════════╗
; ║                   CONFIGURE YOUR RULES HERE                 ║
; ╚══════════════════════════════════════════════════════════════╝
global RULES := [
    ; ── Interval: every 30 min — stretch reminder ──
    {time: "*/30",  text: "👀 30 minutes have passed. Stand up and stretch!",
        dur: 8, opts: "fs=22,bg=2E5E8E,tx=FFF,op=92,x=50%,y=15%"},

    ; ── Daily: morning kickoff ──
    {time: "0900",  text: "☕ Good morning! What's the plan today?",
        dur: 6, opts: "fs=28,bg=FF8C42,tx=FFF,op=90,pos=25,rr=14"},

    ; ── Daily: lunch break ──
    {time: "1200",  text: "🍜 Lunch time! Step away from the screen.",
        dur: 6, opts: "fs=26,bg=4CAF50,tx=FFF,op=88,pos=85,rr=16"},

    ; ── Daily: afternoon tea (multi-line + narrow width) ──
    {time: "1500",  text: "🍵 Afternoon tea!`nStand up, stretch, look out the window.",
        dur: 7, opts: "fs=22,bg=8B5CF6,tx=FFF,op=85,wr=350,pos=80,rr=14"},

    ; ── Weekly: Friday sign-off ──
    {time: "5_1700", text: "🎉 TGIF! Have a great weekend!",
        dur: 8, opts: "fs=32,bg=A020F0,tx=FFD700,op=92,pos=50,rr=20"},

    ; ── Daily: evening wind-down (bottom-right, small font) ──
    {time: "2100",  text: "🌙 Getting late. Time to wind down.",
        dur: 6, opts: "fs=16,bg=1E1E2E,tx=9ECE6A,op=80,x=90%,y=90%"},

    ; ── Once (uncomment and set to current time +1 min to test) ──
    ; {time: "2026_12_25_0800", text: "🎄 Merry Christmas!",
    ;     dur: 10, opts: "fs=36,bg=CC3333,tx=FFF,op=95,pos=40,rr=18,tag=xmas"},
]
; ═══════════════════════════════════════════════════════════════

global FIRED       := Map()
global LAST_DAY    := ""

; ---- Parse time spec ----
ParseTime(t) {
    t := Trim(t)
    ; Interval: */N
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

    ; Midnight reset
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

        fireKey := "", shouldFire := false
        switch pt.type {
        case "interval":
            ; Interval: fire when Mod(minute, interval) == 0 (FIRED Map handles debounce)
            fireKey := "i_" . pt.interval . "_" . (nowMins // pt.interval)
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
        durMs := (rule.dur > 0) ? rule.dur * 1000 : 3000
        ruleOpts := rule.HasOwnProp("opts") ? rule.opts : ""
        AHK_WM_OSD(rule.text, durMs, ruleOpts)
    }
}

SetTimer(CheckAndFire, 30000)
CheckAndFire()

; Startup confirmation
TrayTip("⏰ Timed Notify started", RULES.Length " rules loaded. Press Esc to exit.")
OutputDebug("[osd-timed-notify] started — " RULES.Length " rules loaded`n")

Esc::ExitApp

; ------------------------------------------------------------------------------
; AHK_WM_OSD(text, duration_ms, opts)
;   Sends an OSD message via WM_COPYDATA to wm.ahk.
;   opts format: "key=val,key=val" (all optional, fall back to config defaults)
;   Full docs: osd-custom-all.ahk
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
