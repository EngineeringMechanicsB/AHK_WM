#Requires AutoHotkey v2.0
; 探针：对比"先方向后带"（旧）与"先带后方向"（新）在随机布局上的差异
; Probe: compare old (direction-then-band) vs new (band-then-direction) pickers
#NoTrayIcon
SetTitleMatchMode 2

; ---------- 旧顺序 / OLD order ----------
PickOld(table, i, dir) {
    n := table.Length
    if (i < 1 || i > n)
        return 0
    cur := table[i]
    horizontal := (dir = "L" || dir = "R")
    if (horizontal ? cur.xfull : cur.yfull)
        return 0
    primary   := horizontal ? "cx" : "cy"
    secondary := horizontal ? "cy" : "cx"
    forward   := (dir = "R" || dir = "D")
    myLo := horizontal ? cur.xlo : cur.ylo
    myHi := horizontal ? cur.xhi : cur.yhi
    cand := []
    for j, t in table {
        if (j = i)
            continue
        loJ := horizontal ? t.xlo : t.ylo
        hiJ := horizontal ? t.xhi : t.yhi
        if (forward ? (loJ >= myHi - 1.0e-9) : (hiJ <= myLo + 1.0e-9))
            cand.Push(j)
    }
    if (cand.Length <= 1)
        return cand.Length ? cand[1] : 0
    cand := NarrowByBand(cand, table, cur, horizontal)
    if (cand.Length = 1)
        return cand[1]
    cand := NarrowByAxis(cand, table, cur, primary)
    if (cand.Length = 1)
        return cand[1]
    cand := NarrowByAxis(cand, table, cur, secondary)
    if (cand.Length = 1)
        return cand[1]
    pick := 0, best := 0
    for j in cand {
        d := table[j].%secondary% - cur.%secondary%
        if (d < 0 && (!pick || d > best)) {
            best := d
            pick := j
        }
    }
    return pick ? pick : cand[1]
}

; ---------- 新顺序 / NEW order（与 wm.ahk 一致，含兜底） ----------
PickNew(table, i, dir) {
    n := table.Length
    if (i < 1 || i > n)
        return 0
    cur := table[i]
    horizontal := (dir = "L" || dir = "R")
    if (horizontal ? cur.xfull : cur.yfull)
        return 0
    primary   := horizontal ? "cx" : "cy"
    secondary := horizontal ? "cy" : "cx"
    forward   := (dir = "R" || dir = "D")
    all := []
    for j, _ in table {
        if (j != i)
            all.Push(j)
    }
    if (all.Length = 0)
        return 0
    cand := NarrowByBand(all, table, cur, horizontal)
    myLo := horizontal ? cur.xlo : cur.ylo
    myHi := horizontal ? cur.xhi : cur.yhi
    past := []
    for j in cand {
        t := table[j]
        loJ := horizontal ? t.xlo : t.ylo
        hiJ := horizontal ? t.xhi : t.yhi
        if (forward ? (loJ >= myHi - 1.0e-9) : (hiJ <= myLo + 1.0e-9))
            past.Push(j)
    }
    if (past.Length = 0) {
        for j in all {
            t := table[j]
            loJ := horizontal ? t.xlo : t.ylo
            hiJ := horizontal ? t.xhi : t.yhi
            if (forward ? (loJ >= myHi - 1.0e-9) : (hiJ <= myLo + 1.0e-9))
                past.Push(j)
        }
        if (past.Length = 0)
            return 0
        past := NarrowByBand(past, table, cur, horizontal)
    }
    cand := past
    if (cand.Length = 1)
        return cand[1]
    cand := NarrowByAxis(cand, table, cur, primary)
    if (cand.Length = 1)
        return cand[1]
    cand := NarrowByAxis(cand, table, cur, secondary)
    if (cand.Length = 1)
        return cand[1]
    pick := 0, best := 0
    for j in cand {
        d := table[j].%secondary% - cur.%secondary%
        if (d < 0 && (!pick || d > best)) {
            best := d
            pick := j
        }
    }
    return pick ? pick : cand[1]
}

; ---------- 共享工具（自 wm.ahk 抄来，保持等价 / copied from wm.ahk） ----------
NarrowByBand(cand, table, cur, horizontal) {
    loKey := horizontal ? "ylo" : "xlo"
    hiKey := horizontal ? "yhi" : "xhi"
    cLo := cur.%loKey%, cHi := cur.%hiKey%
    out := []
    for j in cand {
        if (Min(cHi, table[j].%hiKey%) - Max(cLo, table[j].%loKey%) > 1.0e-9)
            out.Push(j)
    }
    if (out.Length)
        return out
    best := 1.0e18
    for j in cand {
        gap := Max(0, Max(cLo - table[j].%hiKey%, table[j].%loKey% - cHi))
        if (gap < best)
            best := gap
    }
    for j in cand {
        if (Max(0, Max(cLo - table[j].%hiKey%, table[j].%loKey% - cHi)) <= best + 1.0e-9)
            out.Push(j)
    }
    return out
}

NarrowByAxis(cand, table, cur, axis) {
    best := 1.0e18
    for j in cand {
        d := Abs(table[j].%axis% - cur.%axis%)
        if (d < best)
            best := d
    }
    out := []
    for j in cand {
        if (Abs(table[j].%axis% - cur.%axis%) <= best + 1.0e-9)
            out.Push(j)
    }
    return out
}

SlotFromSpan(xlo, xhi, ylo, yhi, src) {
    return {xlo: xlo, xhi: xhi, ylo: ylo, yhi: yhi
          , cx: (xlo + xhi) / 2, cy: (ylo + yhi) / 2
          , xfull: (xlo <= 1.0e-9 && xhi >= 1.0 - 1.0e-9)
          , yfull: (ylo <= 1.0e-9 && yhi >= 1.0 - 1.0e-9), src: src}
}

; ---------- 随机布局生成（二维切饼干：每次随机挑一块、随机横竖切一刀） ----------
; ---------- Random 2-D guillotine layouts ----------
RandLayout(n) {
    parts := [{xlo: 0.0, xhi: 1.0, ylo: 0.0, yhi: 1.0}]
    guard := 0
    while (parts.Length < n && guard < 200) {
        guard++
        k := Random(1, parts.Length)
        p := parts[k]
        vert := (p.xhi - p.xlo) > (p.yhi - p.ylo)   ; 长边那条切
        if (Random(0, 3) = 0)
            vert := !vert
        if (vert) {
            if (p.xhi - p.xlo < 0.16)
                continue
            t := p.xlo + (p.xhi - p.xlo) * (0.3 + 0.4 * Random(0, 1000) / 1000)
            a := {xlo: p.xlo, xhi: t, ylo: p.ylo, yhi: p.yhi}
            b := {xlo: t, xhi: p.xhi, ylo: p.ylo, yhi: p.yhi}
        } else {
            if (p.yhi - p.ylo < 0.16)
                continue
            t := p.ylo + (p.yhi - p.ylo) * (0.3 + 0.4 * Random(0, 1000) / 1000)
            a := {xlo: p.xlo, xhi: p.xhi, ylo: p.ylo, yhi: t}
            b := {xlo: p.xlo, xhi: p.xhi, ylo: t, yhi: p.yhi}
        }
        parts.RemoveAt(k)
        parts.InsertAt(k, a)
        parts.InsertAt(k, b)
    }
    return parts
}

Main() {
    RandomSeed := 20260930
    diffs := 0, total := 0, noKeyOld := 0, noKeyNew := 0
    examples := ""
    loop 6000 {
        n := Random(2, 7)
        parts := RandLayout(n)
        if (parts.Length < 2)
            continue
        tbl := []
        for p in parts
            tbl.Push(SlotFromSpan(p.xlo, p.xhi, p.ylo, p.yhi, "probe"))
        i := Random(1, tbl.Length)
        i := Random(1, tbl.Length)
        for dir in ["L", "R", "U", "D"] {
            total++
            a := PickOld(tbl, i, dir)
            b := PickNew(tbl, i, dir)
            if (!a)
                noKeyOld++
            if (!b)
                noKeyNew++
            if (a = b)
                continue
            diffs++
            if (examples = "") {
                s := "n=" tbl.Length " i=" i " dir=" dir " old=" a " new=" b "`n"
                for k, t in tbl
                    s .= "  " k ": x[" Round(t.xlo, 3) "-" Round(t.xhi, 3) "] y[" Round(t.ylo, 3) "-" Round(t.yhi, 3) "]`n"
                examples := s
            }
        }
    }
    out := A_ScriptDir "\probe_pick.out.txt"
    try FileDelete(out)
    FileAppend("cases=" total " diff=" diffs " noKeyOld=" noKeyOld " noKeyNew=" noKeyNew "`n`n" examples, out, "UTF-8")
    ExitApp 0
}

Main()
