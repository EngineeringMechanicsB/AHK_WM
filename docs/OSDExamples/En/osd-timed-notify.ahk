#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
; ==============================================================================
; OSD Example 4 — Timed Notification Scheduler
; ==============================================================================
;
; [What this does]
;   A standalone timed-notification daemon.  Define rules with time + text,
;   and this script pops an OSD when each rule's time arrives.
;   Completely independent of wm.ahk internal features — uses only the
;   external OSD interface (AHK_WM_OSD).
;
; [Supported time formats]
;   HHMM               — Daily: fires every day at HH:MM
;   W_HHMM             — Weekly: fires on weekday W (1=Mon..7=Sun)
;   YYYY_MM_DD_HHMM    — One-shot: fires once on the specified date+time
;
; [How to configure]
;   Edit the RULES array below.  Each entry is an object:
;     {time: "HHMM", text: "...", dur: seconds, opts: "key=value,..."}
;
;   opts is optional — omit to use config defaults.  Available keys:
;     fs=N, op=N, pos=N, bg=RRGGBB, tx=RRGGBB, wr=N, rd=on|off, rr=N, fn=Name
;   See osd-custom-all.ahk for full documentation of every key.
;
;   Examples:
;     {time: "0900",  text: "Standup!",      dur: 5, opts: "fs=30,bg=FF6644,tx=FFF,pos=30"}
;     {time: "1322",  text: "Tea time!",     dur: 5, opts: "fs=24,bg=4CAF50,tx=FFF,rr=20"}
;     {time: "5_1700", text: "Happy Friday!", dur: 5, opts: "fs=28,bg=A020F0,op=85,pos=85"}
;
; [How it works]
;   A SetTimer fires every 30 seconds.  It checks whether the current time
;   (HH:MM) matches any rule.  When a match is found, it sends an OSD
;   via WM_COPYDATA and marks the rule as "fired" for that minute
;   (preventing duplicate fires within the same minute).
;
;   The fired-set resets at midnight so daily/weekly rules fire again
;   the next day.  One-shot rules fire only once ever (keyed by full date).
;
; [Prerequisites]
;   1. wm.ahk must be running.
;   2. Edit the RULES array before running.
;   3. Keep this script running (it's a daemon — runs in the background).
;
; [Controls]
;   Esc — exit the daemon
; ==============================================================================

; ================= CONFIGURE YOUR RULES HERE =================
; Each rule: {time, text, dur, opts?}  — opts is optional (see above)
global RULES := [
    {time: "0957",   text: "Morning! Time to start.",
        dur: 5, opts: "fs=28,bg=FF8C42,tx=FFFFFF,op=90,pos=25,rr=12"},
    {time: "1200",   text: "Lunch break!",
        dur: 5, opts: "fs=26,bg=4CAF50,tx=FFFFFF,op=88,pos=80,rr=16"},
    {time: "1322",   text: "Afternoon tea time!",
        dur: 5, opts: "fs=24,bg=8B5CF6,tx=FFFFFF,op=85,pos=85,rr=14"},
    {time: "5_1700", text: "Happy Friday! Weekend ahead!",
        dur: 6, opts: "fs=30,bg=A020F0,tx=FFD700,op=92,pos=50,rr=20"},
    ; One-shot example (uncomment to test):
    ; {time: "2026_12_25_0800", text: "Merry Christmas!",
    ;     dur: 10, opts: "fs=36,bg=CC3333,tx=FFFFFF,op=95,pos=40,rr=18"}
]
; =============================================================

global FIRED    := Map()   ; set of already-fired keys (debounce)
global LAST_DAY := ""      ; resets the fired set at midnight

; ---- Parse a time spec string → {type, mins[, wday][, year, month, day]} ----
ParseTime(t) {
    t := Trim(t)
    ; One-shot: YYYY_MM_DD_HHMM
    if RegExMatch(t, "^(\d{4})_(\d{2})_(\d{2})_(\d{2})(\d{2})$", &m)
        return {type: "once", mins: Integer(m[4])*60+Integer(m[5])
            , year: Integer(m[1]), month: Integer(m[2]), day: Integer(m[3])}
    ; Weekly: W_HHMM (W = 1..7, Mon..Sun)
    if RegExMatch(t, "^(\d)_(\d{2})(\d{2})$", &m)
        return {type: "weekly", mins: Integer(m[2])*60+Integer(m[3]), wday: Integer(m[1])}
    ; Daily: HHMM
    if RegExMatch(t, "^(\d{2})(\d{2})$", &m)
        return {type: "daily", mins: Integer(m[1])*60+Integer(m[2])}
    return 0
}

; ---- Check all rules and fire OSD if any match (called every 30s) ----
CheckAndFire() {
    global FIRED, LAST_DAY, RULES

    ; Reset fired set at midnight
    today := FormatTime(, "yyyyMMdd")
    if (LAST_DAY != today) {
        FIRED := Map()
        LAST_DAY := today
    }

    nowMins  := A_Hour * 60 + A_Min
    userWDay := (A_WDay == 1) ? 7 : A_WDay - 1   ; 1=Mon..7=Sun
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

; ---- Poll every 30 seconds (minute-level precision is sufficient) ----
SetTimer(CheckAndFire, 30000)
CheckAndFire()   ; Check immediately on startup
Esc::ExitApp

; ------------------------------------------------------------------------------
; AHK_WM_OSD(text, duration, opts)
;   See osd-custom-all.ahk for full parameter documentation.
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
