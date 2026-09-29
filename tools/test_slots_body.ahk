
; ==================== 测试主体 ====================
; 只做纯数学验证，不移动任何窗口。

CurrentTileGap := 0
TileBoundSet := false
TileBound_L := 0, TileBound_T := 0, TileBound_R := 0, TileBound_B := 0
TileSink := 0
LayoutRules := Map()

OUT := A_ScriptDir "\test_slots.out.txt"
try FileDelete(OUT)
Log(s) => FileAppend(s "`n", OUT, "UTF-8")

; 未捕获异常必须留下痕迹并给出非零退出码（否则测试会静默通过）
ErrHandler(err, mode) {
    FileAppend("UNCAUGHT: " err.Message " @ " err.File ":" err.Line "`n", OUT, "UTF-8")
    ExitApp(3)
}
OnError(ErrHandler)

_rpad(s, n) {
    s := "" s
    while (StrLen(s) < n)
        s .= " "
    return s
}
_lpad(s, n) {
    s := "" s
    while (StrLen(s) < n)
        s := " " s
    return s
}
_fmt(v) => _rpad(SubStr(Round(v * 1000) / 1000, 1, 6), 6)

_DumpTable(label, table) {
    Log("== " label " (n=" table.Length ") ==")
    Log("   i | xlo    xhi    ylo    yhi    | cx     cy     | xfull yfull")
    for i, t in table {
        line := _lpad(i, 4) " | "
        line .= _fmt(t.xlo) _fmt(t.xhi) _fmt(t.ylo) _fmt(t.yhi) " | "
        line .= _fmt(t.cx) _fmt(t.cy) " |  "
        line .= (t.xfull ? "1" : "0") "     " (t.yfull ? "1" : "0")
        Log(line)
    }
}

_Pick(table, i, d) {
    try {
        v := PickSlotFromTable(table, i, d)
        return v
    } catch Error as e {
        return "ERR:" e.Message
    }
}

Fail := 0
Assert(cond, msg) {
    global Fail
    if !cond {
        Fail += 1
        Log("  x FAIL: " msg)
    } else {
        Log("  . ok  : " msg)
    }
}

; ---------------------------------------------------------------
; 场景 A：用户 7 窗口规则（来自设计方案 / 回答.md）
;   |2| |5|
;   |3|1|6|
;   |4| |7|
; ---------------------------------------------------------------
RULES := "7,1,2/3,1;7,2,1/3,1/3;7,3,1/3,2/3;7,4,1/3,3/3;7,5,3/3,1/3;7,6,3/3,2/3;7,7,3/3,3/3;"
LayoutRules := ParseLayoutRules(RULES)
rules := GetCustomLayout(7, 7)
Assert(IsObject(rules) && rules.Length = 7, "A: 规则解析出 7 个窗口 (实际 " (IsObject(rules) ? rules.Length : 0) ")")
if !(IsObject(rules) && rules.Length = 7) {
    Log("规则解析失败，终止")
    ExitApp(2)
}

table := []
for i, r in rules
    table.Push(SlotFromSpan(r.x.lo, r.x.hi, r.y.lo, r.y.hi, "custom"))
_DumpTable("A: 用户 7 窗口规则", table)

Log("")
Log("-- A: 四方向移动目标 (1 起槽位号，0 = 本屏无目标 → 跨屏) --")
Log("   窗口 |  L   R   U   D  | 位置")
pos := ["左中", "左上", "左中", "左下", "右上", "右中", "右下"]
loop 7 {
    i := A_Index
    line := _lpad(i, 6) " | "
    for d in ["L", "R", "U", "D"]
        line .= _lpad(_Pick(table, i, d), 4)
    line .= " | " pos[i]
    Log(line)
}

Log("")
Log("-- A: 断言 --")
; 用户原文两个例子
Assert(_Pick(table, 3, "R") = 1, "A1: 窗口3 向右 → 窗口1 (用户原文例)")
Assert(_Pick(table, 1, "R") = 6, "A2: 窗口1 向右 → 窗口6 (并列取 y 差最小)")
; 回答.md 的修正：满轴不可移动
Assert(_Pick(table, 1, "U") = 0, "A3: 窗口1 两轴全满 → 不可上移 (回答.md 修正)")
Assert(_Pick(table, 1, "D") = 0, "A4: 窗口1 两轴全满 → 不可下移 (回答.md 修正)")
Assert(_Pick(table, 2, "L") = 0, "A5: 窗口2 已在最左 → 不可左移")
Assert(_Pick(table, 5, "R") = 0, "A6: 窗口5 已在最右 → 不可右移")
Assert(_Pick(table, 3, "L") = 0, "A7: 窗口3 左移无目标")
Assert(_Pick(table, 3, "U") = 2, "A8: 窗口3 上移 → 窗口2")
Assert(_Pick(table, 3, "D") = 4, "A9: 窗口3 下移 → 窗口4")
Assert(_Pick(table, 5, "D") = 6, "A10: 窗口5 下移 → 窗口6")
Assert(_Pick(table, 5, "L") = 1, "A11: 窗口5 左移 → 窗口1")
Assert(_Pick(table, 5, "U") = 0, "A12: 窗口5 上移无目标")
Assert(_Pick(table, 6, "L") = 1, "A13: 窗口6 左移 → 窗口1")
Assert(_Pick(table, 7, "L") = 1, "A14: 窗口7 左移 → 窗口1")
Assert(_Pick(table, 1, "L") = 3, "A15: 窗口1 左移 → 窗口3 (与 A1 互逆)")
Assert(_Pick(table, 6, "R") = 0, "A16: 窗口6 已在最右 → 不可右移")

; ---------------------------------------------------------------
; 场景 B：区间与满轴识别
; ---------------------------------------------------------------
; (2-3)/3 = 第2~3份 / 共3份 = 1/3..1.0（"-" 是"到"，不是减）
ax := ParseAxis("(2-3)/3")
Assert(Abs(ax.lo - 1/3) < 1e-9 && Abs(ax.hi - 1) < 1e-9, "B1: (2-3)/3 → lo=1/3 hi=1")
ax2 := ParseAxis("(1-2)/3")
Assert(Abs(ax2.lo - 0) < 1e-9 && Abs(ax2.hi - 2/3) < 1e-9, "B2: (1-2)/3 → lo=0 hi=2/3")
Assert(Abs(ParseAxis("1").lo - 0) < 1e-9 && Abs(ParseAxis("1").hi - 1) < 1e-9, "B3: 1 → 全轴 0..1")
s := SlotFromSpan(0, 1, 1/3, 2/3, "t")
Assert(s.xfull && !s.yfull, "B4: xfull/yfull 识别正确")
Assert(Abs(s.cy - 0.5) < 1e-9, "B5: 区间中点作副轴比较值")
Assert(ParseAxis("2/2").lo > 0 && Abs(ParseAxis("2/2").hi - 1) < 1e-9, "B6: 2/2 → 下半轴 (单轴不判满)")
; Q9：对齐后缀保留解析（当前不参与几何，只影响文档语义）
; 语法为符号加在分母前：1/+2 = Right、1/-2 = Left（见 docs/config-reference-zh.md）
Assert(ParseAxis("1/+2").align = "Right", "B7: 1/+2 → 对齐 Right (后缀保留解析)")
Assert(ParseAxis("1/-2").align = "Left", "B8: 1/-2 → 对齐 Left")
Assert(ParseAxis("1/2").align = "Center", "B9: 1/2 → 对齐 Center (默认)")
Assert(ParseAxis("(1-2)/+3").align = "Right", "B10: 区间轴也支持对齐后缀")
Assert(Abs(ParseAxis("1/-2").hi - 0.5) < 1e-9, "B10b: 对齐后缀不影响几何")
bad := false
try
    ParseAxis("0/3")
catch
    bad := true
Assert(bad, "B11: 0/3 抛错 (分子至少 1)")

; ---------------------------------------------------------------
; 场景 C：内置算法空跑出来的槽位表（Q2 允许）
; ---------------------------------------------------------------
Log("")
W := 2560, H := 1440
loop 5 {
    n := A_Index + 1
    bt := BuildBuiltinSlotTable(n, W, H)
    if (bt.Length != n) {
        Assert(false, "C: n=" n " 空跑得到 " bt.Length " 个矩形（应为 " n "）")
        continue
    }
    _DumpTable("C: 内置算法 n=" n " @" W "x" H, bt)
    ok := true
    detail := ""
    loop bt.Length {
        for d in ["L", "R", "U", "D"] {
            j := _Pick(bt, A_Index, d)
            if !IsInteger(j) || j < 0 || j > n || j = A_Index {
                ok := false
                detail .= " [n=" n " i=" A_Index " " d " → " j "]"
            }
        }
    }
    Assert(ok, "C: n=" n " 四方向结果合法且不等于自身" detail)
}

btv := BuildBuiltinSlotTable(4, 900, 1600)
_DumpTable("C: 内置算法 n=4 @900x1600 (Vertical)", btv)
Assert(btv.Length = 4, "C: 竖屏 n=4 得到 4 个矩形")

btu := BuildBuiltinSlotTable(3, 5120, 1440)
_DumpTable("C: 内置算法 n=3 @5120x1440 (Ultrawide)", btu)
Assert(btu.Length = 3, "C: 超宽 n=3 得到 3 个矩形")

Log("")
Log(Fail ? "==== 失败 " Fail " 项 ====" : "==== 全部通过 ====")
ExitApp(Fail ? 1 : 0)
