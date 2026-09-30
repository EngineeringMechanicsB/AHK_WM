
; ==================== 测试主体 ====================
; 只做纯数学验证，不移动任何窗口。

CurrentTileGap := 0
TileBoundSet := false
TileBound_L := 0, TileBound_T := 0, TileBound_R := 0, TileBound_B := 0
TileSink := 0
LayoutRules := Map()
; WTM 会话内的缩放覆盖（wm.ahk 里由 WTM.Activate/Deactivate 开关），测试里保持关闭
WTM_ResizeRules    := Map()
WTM_LayoutOverride := false

OUT := A_ScriptDir "\test_slots.out.txt"
try FileDelete(OUT)
Log(s) => FileAppend(s "`n", OUT, "UTF-8")

; 未捕获异常必须留下痕迹并给出非零退出码（否则测试会静默通过）
; 注意：处理函数自己绝不能再抛出，否则 AHK 会弹错误对话框。
; （踩过一次：把 stdout 重定向到 OUT 同一路径导致文件被占用，
;   FileAppend 抛 error 32，对话框就弹出来了。）
ErrHandler(err, mode) {
    msg := "UNCAUGHT: " err.Message " @ " err.File ":" err.Line "`n"
    try FileAppend(msg, OUT, "UTF-8")
    catch
        try FileAppend(msg, A_ScriptDir "\test_slots.err.txt", "UTF-8")
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
; A17：整表逐格对齐用户给的三步漏斗预期
exp7 := [[3, 6, 0, 0], [0, 1, 0, 3], [0, 1, 2, 4], [0, 1, 3, 0], [1, 0, 0, 6], [1, 0, 5, 7], [1, 0, 6, 0]]
loop 7 {
    i7 := A_Index
    for di7, d7 in ["L", "R", "U", "D"]
        Assert(_Pick(table, i7, d7) = exp7[i7][di7], "A17: 窗口" i7 " " d7 " → " exp7[i7][di7])
}

; ---------------------------------------------------------------
; 场景 A2：三窗口规则（用户配置）
;   3,1,(2-3)/3,1;3,2,1/3,1/2;3,3,1/3,2/2
;   |2|   |
;   | | 1 |
;   |3|   |
; 回归：窗口2 下移必须到窗口3（正下方），不能被"高窗1中心更近"抢走
; ---------------------------------------------------------------
t3 := []
t3.Push(SlotFromSpan(1/3, 1, 0, 1, "custom"))
t3.Push(SlotFromSpan(0, 1/3, 0, 1/2, "custom"))
t3.Push(SlotFromSpan(0, 1/3, 1/2, 1, "custom"))
Log("")
_DumpTable("A2: 三窗口规则", t3)
Assert(_Pick(t3, 2, "D") = 3, "A2-1: 窗口2 下移 → 窗口3 (正下方，不是高窗1)")
Assert(_Pick(t3, 2, "R") = 1, "A2-2: 窗口2 右移 → 窗口1")
Assert(_Pick(t3, 3, "U") = 2, "A2-3: 窗口3 上移 → 窗口2")
Assert(_Pick(t3, 3, "R") = 1, "A2-4: 窗口3 右移 → 窗口1")
Assert(_Pick(t3, 3, "D") = 0, "A2-5: 窗口3 已在最下 → 不可下移")
Assert(_Pick(t3, 2, "U") = 0, "A2-6: 窗口2 已在最上 → 不可上移")
Assert(_Pick(t3, 1, "L") = 2, "A2-7: 窗口1 左移 → 窗口2 (并列取副轴差为负/偏上)")

; ---------------------------------------------------------------
; 场景 A3：五窗口内置布局（高窗居中 + 左右各二）—— 用户表二
;   |2| |4|
;   |3|1|5|
; 回归：窗口2 下移必须到窗口3；压在身上的高窗 1（y 0..1）不算候选
; ---------------------------------------------------------------
t5 := []
t5.Push(SlotFromSpan(1/3, 2/3, 0, 1, "custom"))
t5.Push(SlotFromSpan(0, 1/3, 0, 1/2, "custom"))
t5.Push(SlotFromSpan(0, 1/3, 1/2, 1, "custom"))
t5.Push(SlotFromSpan(2/3, 1, 0, 1/2, "custom"))
t5.Push(SlotFromSpan(2/3, 1, 1/2, 1, "custom"))
Log("")
_DumpTable("A3: 五窗口规则", t5)
exp5 := [[2, 4, 0, 0], [0, 1, 0, 3], [0, 1, 2, 0], [1, 0, 0, 5], [1, 0, 4, 0]]
dirs := ["L", "R", "U", "D"]
loop 5 {
    i5 := A_Index
    for di, d in dirs
        Assert(_Pick(t5, i5, d) = exp5[i5][di], "A3: 窗口" i5 " " d " → " exp5[i5][di])
}

; ---------------------------------------------------------------
; 场景 A4：四窗口 2x2 —— 用户表三
;   |1|2|
;   |3|4|
; ---------------------------------------------------------------
t4 := []
t4.Push(SlotFromSpan(0, 1/2, 0, 1/2, "custom"))
t4.Push(SlotFromSpan(1/2, 1, 0, 1/2, "custom"))
t4.Push(SlotFromSpan(0, 1/2, 1/2, 1, "custom"))
t4.Push(SlotFromSpan(1/2, 1, 1/2, 1, "custom"))
Log("")
_DumpTable("A4: 四窗口 2x2", t4)
exp4 := [[0, 2, 0, 3], [1, 0, 0, 4], [0, 4, 1, 0], [3, 0, 2, 0]]
loop 4 {
    i4 := A_Index
    for di, d in dirs
        Assert(_Pick(t4, i4, d) = exp4[i4][di], "A4: 窗口" i4 " " d " → " exp4[i4][di])
}

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

; ---------------------------------------------------------------
; 场景 D：WTM 缩放（ResizeSpans 纯函数 + RuleStringFor 规则字符串）
;   3,1,1/3,1;3,2,2/3,1;3,3,3/3,1;  @1920 宽 → 三列，焦点窗口 2，步长 20
; ---------------------------------------------------------------
Log("")
DX := 1920
dMin := 80 / DX        ; 最小尺寸 80px
dDelta := 10 / DX      ; 步长 20 → 每条边 10px
spans3 := [{lo: 0, hi: 1/3}, {lo: 1/3, hi: 2/3}, {lo: 2/3, hi: 1}]

rs := ResizeSpans(spans3, 2, true, dDelta, dMin)
okD := IsObject(rs) && Abs(rs[1].hi - 630/DX) < 1e-9 && Abs(rs[2].lo - 630/DX) < 1e-9
    && Abs(rs[2].hi - 1290/DX) < 1e-9 && Abs(rs[3].lo - 1290/DX) < 1e-9
Assert(okD, "D1: 放大窗口2 → 窗口1 让到 630、窗口3 让到 1290")

; 与 WTM.Resize 相同的像素栅格量化 → 生成规则字符串
q := QuantizeSpans(rs, DX)
rulesD := []
for i, s in q
    rulesD.Push({x: {lo: s.lo, hi: s.hi, align: "Center"}, y: {lo: 0.0, hi: 1.0, align: "Center"}})
strD := RuleStringFor(rulesD, DX, 1080)
Assert(strD = "3,1,630/1920,1;3,2,(631-1290)/1920,1;3,3,(1291-1920)/1920,1;",
    "D2: 规则字符串可粘回配置 (实际 " strD ")")
rtD := ParseLayoutRules(strD)
rd := rtD.Has("*") ? rtD["*"] : ""
Assert(IsObject(rd) && rd.Has(3) && Abs(rd[3][1].x.hi - 630/DX) < 1e-9
    && Abs(rd[3][2].x.lo - 630/DX) < 1e-9 && Abs(rd[3][2].x.hi - 1290/DX) < 1e-9
    && Abs(rd[3][3].x.lo - 1290/DX) < 1e-9, "D3: 粘回配置解析后与量化结果一致")

; 缩回去：应精确回到原始三列
rs2 := ResizeSpans(rs, 2, false, dDelta, dMin)
Assert(IsObject(rs2) && Abs(rs2[1].hi - 1/3) < 1e-9 && Abs(rs2[2].lo - 1/3) < 1e-9
    && Abs(rs2[2].hi - 2/3) < 1e-9 && Abs(rs2[3].lo - 2/3) < 1e-9,
    "D4: 缩小窗口2 → 精确回到 1/3 与 2/3")

; 屏幕边缘：放大窗口1（左边已贴 0）→ 只有右边动
rs3 := ResizeSpans(spans3, 1, true, dDelta, dMin)
Assert(IsObject(rs3) && Abs(rs3[1].lo) < 1e-9 && Abs(rs3[1].hi - (1/3 + dDelta)) < 1e-9
    && Abs(rs3[2].lo - (1/3 + dDelta)) < 1e-9, "D5: 贴边放大 → 只动有邻居的那条边")

; 已经最小 → 不再缩
spansMin := [{lo: 0, hi: 80/DX}, {lo: 80/DX, hi: 1}]
Assert(ResizeSpans(spansMin, 1, false, dDelta, dMin) = 0, "D6: 已到最小尺寸 → 缩小无变化")

; 邻居最多让到最小尺寸；已经小于最小尺寸则一点都不让
rs4 := ResizeSpans([{lo: 0, hi: 0.06}, {lo: 0.06, hi: 1}], 2, true, 0.05, 0.05)
Assert(IsObject(rs4) && Abs(rs4[2].lo - 0.05) < 1e-9 && Abs(rs4[1].hi - 0.05) < 1e-9,
    "D7: 邻居只能让到最小尺寸 (0.05)")
Assert(!IsObject(ResizeSpans([{lo: 0, hi: 0.03}, {lo: 0.03, hi: 1}], 2, true, 0.005, 0.05)),
    "D7b: 邻居已小于最小尺寸 → 放大被挡下")

; 没有邻居接手 → 缩小时不留空洞
rs5 := ResizeSpans([{lo: 0, hi: 0.5}, {lo: 0.9, hi: 1}], 2, false, dDelta, dMin)
Assert(!IsObject(rs5), "D8: 缩小时无邻居接手 → 不动 (不留空洞)")

; ---------------------------------------------------------------
; 场景 E：整条线平移 —— 同一条线上的边（不论在哪一行/列）一起动
;   |1|3|      放大窗口1 的 X → 左下列(2)的右边、右下列(4)的左边都得跟着走
;   |2|4|      否则底行会裂开一条缝
; ---------------------------------------------------------------
eD := 0.1
eMin := 0.05
; X 轴跨度：索引 1=窗口1(左上) 2=窗口3(右上) 3=窗口2(左下) 4=窗口4(右下)
eX := [{lo: 0, hi: 0.5}, {lo: 0.5, hi: 1}, {lo: 0, hi: 0.5}, {lo: 0.5, hi: 1}]
eXg := ResizeSpans(eX, 1, true, eD, eMin)
Assert(IsObject(eXg) && Abs(eXg[1].hi - 0.6) < 1e-9 && Abs(eXg[2].lo - 0.6) < 1e-9
    && Abs(eXg[3].hi - 0.6) < 1e-9 && Abs(eXg[4].lo - 0.6) < 1e-9,
    "E1: 2x2 放大窗口1 → 窗口2/3/4 的边界都跟到 0.6 (不裂缝)")
eXb := ResizeSpans(eXg, 1, false, eD, eMin)
Assert(IsObject(eXb) && Abs(eXb[1].hi - 0.5) < 1e-9 && Abs(eXb[2].lo - 0.5) < 1e-9
    && Abs(eXb[3].hi - 0.5) < 1e-9 && Abs(eXb[4].lo - 0.5) < 1e-9,
    "E2: 缩回去 → 精确回到 0.5")
Assert(IsObject(eXb) && Abs(eXb[1].lo) < 1e-9 && Abs(eXb[3].lo) < 1e-9,
    "E2b: 贴屏幕边缘的边没人接手 → 不缩 (边缘不留缝)")

; Y 轴跨度：索引 1=窗口1(左上) 2=窗口3(右上) 3=窗口2(左下) 4=窗口4(右下)
eY := [{lo: 0, hi: 0.5}, {lo: 0, hi: 0.5}, {lo: 0.5, hi: 1}, {lo: 0.5, hi: 1}]
eYg := ResizeSpans(eY, 1, true, eD, eMin)
Assert(IsObject(eYg) && Abs(eYg[1].hi - 0.6) < 1e-9 && Abs(eYg[2].hi - 0.6) < 1e-9
    && Abs(eYg[3].lo - 0.6) < 1e-9 && Abs(eYg[4].lo - 0.6) < 1e-9,
    "E3: 2x2 纵向放大窗口1 → 窗口2/3/4 同样跟到 0.6")
eYb := ResizeSpans(eYg, 1, false, eD, eMin)
Assert(IsObject(eYb) && Abs(eYb[1].hi - 0.5) < 1e-9 && Abs(eYb[2].hi - 0.5) < 1e-9
    && Abs(eYb[3].lo - 0.5) < 1e-9 && Abs(eYb[4].lo - 0.5) < 1e-9,
    "E4: 纵向缩回去 → 精确回到 0.5")

; 7 窗口布局：放大窗口2 → 同列(左列)的窗口3/4 边界一起走，左中高窗1 让位
e7x := []
for i, t in table
    e7x.Push({lo: t.xlo, hi: t.xhi})
e7g := ResizeSpans(e7x, 2, true, 0.05, 0.02)
Assert(IsObject(e7g) && Abs(e7g[2].hi - (1/3 + 0.05)) < 1e-9
    && Abs(e7g[3].lo) < 1e-9 && Abs(e7g[3].hi - (1/3 + 0.05)) < 1e-9
    && Abs(e7g[4].lo) < 1e-9 && Abs(e7g[4].hi - (1/3 + 0.05)) < 1e-9
    && Abs(e7g[1].lo - (1/3 + 0.05)) < 1e-9,
    "E5: 7 窗口放大窗口2 → 左列 2/3/4 同步、窗口1 让位 (整列不错位)")

; ---------------------------------------------------------------
; 场景 F：缩放覆盖的作用域（只活在 WTM 会话里，退出后回到配置文件）
; ---------------------------------------------------------------
Log("")
Log("-- F: 缩放覆盖只作用于 WTM 会话 --")

; 加一条"只属于 1 号屏 / 3 窗口"的配置规则，用来验证覆盖不会串屏
LayoutRules[1] := Map(3, ParseLayoutRules("1,3,1,1/3,1;1,3,2,2/3,1;1,3,3,3/3,1;")[1][3])

; 模拟 WTM.Resize 的写入：mon1 / n3 里窗口 1 的右边界从 1/3 推到这里
ovr := []
for i, r in LayoutRules[1][3]
    ovr.Push({x: {lo: r.x.lo, hi: r.x.hi, align: "Center"}, y: {lo: r.y.lo, hi: r.y.hi, align: "Center"}})
ovr[1] := {x: {lo: 0.0, hi: 0.25, align: "Center"}, y: {lo: ovr[1].y.lo, hi: ovr[1].y.hi, align: "Center"}}
WTM_ResizeRules := Map(1, Map(3, ovr))
WTM_LayoutOverride := true

Assert(Abs(GetCustomLayout(1, 3)[1].x.hi - 0.25) < 1e-9, "F1: WTM 会话内 → 缩放覆盖生效 (1/3 → 0.25)")
Assert(Abs(GetCustomLayout(1, 3)[2].x.hi - 2/3) < 1e-9, "F2: 覆盖里没动过的窗口保持原样")
Assert(Abs(LayoutRules[1][3][1].x.hi - 1/3) < 1e-9, "F3: 写覆盖不污染配置文件规则 (LayoutRules 里仍是 1/3)")
Assert(GetCustomLayout(2, 3) = "",
    "F4: 会话内其它屏/其它窗口数照旧 (2 号屏无规则 → 走内置算法)")
Assert(IsObject(GetCustomLayout(2, 7)), "F4b: 其它屏仍拿得到配置里的 *|7 规则")

; 退出 WTM：清空覆盖 → 立刻回到配置文件里的规则
WTM_LayoutOverride := false
WTM_ResizeRules := Map()
Assert(Abs(GetCustomLayout(1, 3)[1].x.hi - 1/3) < 1e-9,
    "F5: 退出 WTM 后 → Alt+D 平铺回到配置文件规则 (0.25 → 1/3)")

LayoutRules.Delete(1)

; ---------------------------------------------------------------
; 场景 G：10 窗口内置布局（4/4/2）—— 用户报告的"向右跳格"复现
;   |1|2|3|4|
;   |5|6|7|8|
;   | 9 |10 |
; ---------------------------------------------------------------
Log("")
Log("-- G: 10 窗口内置布局（4/4/2）四方向 --")
tbl10 := BuildBuiltinSlotTable(10, 1920, 1080)
_DumpTable("G: 内置 10 窗口", tbl10)
Assert(tbl10.Length = 10, "G0: 内置算法给出 10 个槽位")
Log("   窗口 |  L   R   U   D")
loop 10 {
    i := A_Index
    line := _lpad(i, 6) " | "
    for d in ["L", "R", "U", "D"]
        line .= _lpad(_Pick(tbl10, i, d), 4)
    Log(line)
}
Assert(_Pick(tbl10, 2, "R") = 3, "G1: 窗口2 向右 → 3 (不是 4)")
Assert(_Pick(tbl10, 6, "R") = 7, "G2: 窗口6 向右 → 7 (不是 8)")
Assert(_Pick(tbl10, 7, "R") = 8, "G3: 窗口7 向右 → 8 (不是 10)")
Assert(_Pick(tbl10, 3, "L") = 2, "G4: 窗口3 向左 → 2 (不是 1)")
Assert(_Pick(tbl10, 7, "L") = 6, "G5: 窗口7 向左 → 6 (不是 5)")
Assert(_Pick(tbl10, 2, "D") = 6, "G6: 窗口2 向下 → 6")
Assert(_Pick(tbl10, 6, "D") = 9, "G7: 窗口6 向下 → 9 (第三行窗口更宽，取同列的 9)")
Assert(_Pick(tbl10, 10, "U") = 7, "G7b: 窗口10 向上 → 7 (与 8 并列时取偏左)")
Assert(_Pick(tbl10, 4, "R") = 0, "G7c: 窗口4 已在最右 → 不右移")
Assert(_Pick(tbl10, 9, "U") = 5, "G8: 窗口9 向上 → 5")
Assert(_Pick(tbl10, 9, "R") = 10, "G9: 窗口9 向右 → 10")

; ---------------------------------------------------------------
; 场景 H：平铺区尺寸不能整除（1906/4 = 476.5，991/3 = 330.33）
;   用户日志里那台机器的真实尺寸就是 W=1906 H=991。旧代码把 x 和 w 各自取整，
;   右边界 = Round(x) + Round(w)，与邻格左边界 Round(x+w) 差 1px →
;   第 2、3 列重叠 1px → 方向选取判定"相邻槽位压在自己身上、没完全越过自己"
;   而跳过它（日志里 2 向右 → 4、3 向左 → 1、6 向右 → 8、7 向左 → 5）。
; ---------------------------------------------------------------
Log("")
Log("-- H: 不能整除的平铺区 1906x991（复现日志里的跳格） --")
tblH := BuildBuiltinSlotTable(10, 1906, 991)
_DumpTable("H: 内置 10 窗口 @1906x991", tblH)
Assert(tblH.Length = 10, "H0: 槽位数 = 10")

badH := ""
for i in [1, 2, 3, 5, 6, 7] {
    if (tblH[i].xhi > tblH[i+1].xlo + 1.0e-9)
        badH .= i "|"
}
Assert(badH = "", "H1: 同一行相邻列不重叠 (重叠: " badH ")")
badV := ""
for i in [1, 2, 3, 4] {
    if (tblH[i].yhi > tblH[i+4].ylo + 1.0e-9)
        badV .= i "|"
}
Assert(badV = "", "H1b: 同一列相邻行不重叠 (重叠: " badV ")")

Assert(_Pick(tblH, 2, "R") = 3, "H2: 1906x991 窗口2 向右 → 3 (日志里错跳成 4)")
Assert(_Pick(tblH, 6, "R") = 7, "H3: 窗口6 向右 → 7 (日志里错跳成 8)")
Assert(_Pick(tblH, 3, "L") = 2, "H4: 窗口3 向左 → 2 (日志里错跳成 1)")
Assert(_Pick(tblH, 7, "L") = 6, "H5: 窗口7 向左 → 6 (日志里错跳成 5)")
Assert(_Pick(tblH, 1, "R") = 2, "H6: 窗口1 向右 → 2")
Assert(_Pick(tblH, 5, "R") = 6, "H7: 窗口5 向右 → 6")
Assert(_Pick(tblH, 4, "L") = 3, "H8: 窗口4 向左 → 3")
Assert(_Pick(tblH, 8, "L") = 7, "H9: 窗口8 向左 → 7")
Assert(_Pick(tblH, 9, "R") = 10, "H10: 窗口9 向右 → 10")
Assert(_Pick(tblH, 2, "D") = 6, "H11: 窗口2 向下 → 6")
Assert(_Pick(tblH, 10, "U") = 7, "H12: 窗口10 向上 → 7")

; 进入 WTM 时"认槽位"靠的就是这个：窗口中心归一化后落在哪个槽位里
Assert(SlotIndexAtPoint(tblH, 0.375, 0.166) = 2, "H13: 点 (0.375,0.166) → 槽位 2")
Assert(SlotIndexAtPoint(tblH, 0.99, 0.99) = 10, "H14: 右下角 (0.99,0.99) → 槽位 10")
Assert(SlotIndexAtPoint(tblH, 0.24, 0.166) = 1, "H15: 点 (0.24,0.166) → 槽位 1")
Assert(SlotIndexAtPoint(tblH, 1.2, 0.5) = 0, "H16: 表外的点 (1.2,0.5) → 无槽位")

; ---------------------------------------------------------------
; 场景 I：就近平铺 —— 进入 WTM 时把实测窗口矩形映射回槽位
;   "先用 Alt+D 平铺过、再按 Alt+Shift+D 进 WTM"时，窗口外框就是
;   ComputeTileRect 的输出；SlotAssign 必须让每个窗口认回自己那个槽位
;   （filled = 0 → 每个窗口各归其位：进 WTM 不换窗口，几何仍由配置/内置规则 + WTMGap 算）。
; ---------------------------------------------------------------
Log("")
Log("-- I: 就近平铺（实测矩形 → 槽位） --")

; 造一个"已平铺"的实测画面：像素外框用和 ComputeTileRect 一样的取整方式
_PxFromSlot(t, W, H) {
    x := Round(t.xlo * W), y := Round(t.ylo * H)
    return {x: x, y: y, w: Max(50, Round(t.xhi * W) - x), h: Max(50, Round(t.yhi * H) - y)}
}
_MkRecs(table, W, H) {
    recs := []
    for i, t in table {
        r := _PxFromSlot(t, W, H)
        recs.Push({hwnd: 1000 + i, m: 1, x: r.x, y: r.y, w: r.w, h: r.h
                  , cx: r.x + r.w / 2, cy: r.y + r.h / 2})
    }
    return recs
}

recsI := _MkRecs(tblH, 1906, 991)
x0I := 0, y0I := 0, bwI := 0, bhI := 0
RectBBox(recsI, &x0I, &y0I, &bwI, &bhI)
Assert(x0I = 0 && y0I = 0 && bwI = 1906 && bhI = 991,
    "I1: RectBBox 实测外框 0,0 1906x991 (实际 " x0I "," y0I " " bwI "x" bhI ")")

filledI := 0
slotOfI := SlotAssign(recsI, tblH, x0I, y0I, bwI, bhI, &filledI)
Assert(filledI = 0, "I2: 已平铺画面 → 每个窗口都认回槽位 (兜底 " filledI " 个)")
sameI := true
for k, i in slotOfI {
    if (i != k)
        sameI := false
}
Assert(sameI, "I3: 槽位号 = 窗口号 → 进入 WTM 不换窗口")

; 一个窗口被拖到左上角（1 号槽位已被占）→ 只有它需要兜底，且正好落回空出来的 5 号槽位
recsJ := _MkRecs(tblH, 1906, 991)
recsJ[5].x := 40, recsJ[5].y := 40
recsJ[5].cx := recsJ[5].x + recsJ[5].w / 2
recsJ[5].cy := recsJ[5].y + recsJ[5].h / 2
filledJ := 0
slotOfJ := SlotAssign(recsJ, tblH, 0, 0, 1906, 991, &filledJ)
Assert(filledJ = 1, "I4: 一个窗口被拖走 → 只有它需要兜底 (实际 " filledJ ")")
Assert(slotOfJ[5] = 5, "I5: 它回到空出来的 5 号槽位")
Assert(slotOfJ[1] = 1 && slotOfJ[6] = 6 && slotOfJ[10] = 10, "I6: 其它窗口槽位不变")

; 最大化的窗口（外框往往比平铺区还大）不能当"已经铺好"的证据：
; 它自己不认槽位，也不能撑大归一化基准
recsK := _MkRecs(tblH, 1906, 991)
recsK[3] := {hwnd: 2000, m: 1, x: -50, y: -50, w: 2006, h: 1091, cx: 953, cy: 495.5, claim: false}
x0K := 0, y0K := 0, bwK := 0, bhK := 0
RectBBox(recsK, &x0K, &y0K, &bwK, &bhK)
Assert(x0K = 0 && y0K = 0 && bwK = 1906 && bhK = 991,
    "I8: RectBBox 忽略最大化窗口 (实际 " x0K "," y0K " " bwK "x" bhK ")")
filledK := 0
slotOfK := SlotAssign(recsK, tblH, x0K, y0K, bwK, bhK, &filledK)
Assert(filledK = 1, "I9: 最大化窗口不认槽位 → 只有它兜底 (实际 " filledK ")")
Assert(slotOfK[1] = 1 && slotOfK[2] = 2 && slotOfK[4] = 4 && slotOfK[10] = 10,
    "I10: 其余窗口照常认回自己的槽位")
Assert(slotOfK[3] = 3, "I11: 最大化的那个落到唯一空出的 3 号槽位（值 = recs 下标）")

; 反复开关 WTM 幂等的关键：窗口被 WTMGap 内缩之后，中心仍落在自己那个槽位里
recsL := []
for i, t in tblH {
    r := _PxFromSlot(t, 1906, 991)
    d := 5                                   ; 每边内缩 WTMGap/2
    x := r.x + d, y := r.y + d, w := r.w - 2 * d, h := r.h - 2 * d
    recsL.Push({hwnd: 1000 + i, m: 1, x: x, y: y, w: w, h: h
              , cx: x + w / 2, cy: y + h / 2, claim: true})
}
x0L := 0, y0L := 0, bwL := 0, bhL := 0
RectBBox(recsL, &x0L, &y0L, &bwL, &bhL)
filledL := 0
slotOfL := SlotAssign(recsL, tblH, x0L, y0L, bwL, bhL, &filledL)
sameL := true
for k, i in slotOfL {
    if (i != k)
        sameL := false
}
Assert(filledL = 0 && sameL, "I12: WTMGap 内缩后仍认回原槽位 → 反复开关幂等 (fill " filledL ")")

; 行带排序：中心 y 差不到 0.4 倍窗高算同一行，行内按 x
srI := SortRowsByX([{x: 100, y: 0, w: 10, h: 10}, {x: 0, y: 1, w: 10, h: 10}
                  , {x: 200, y: 200, w: 10, h: 10}, {x: 50, y: 190, w: 10, h: 10}])
Assert(srI[1].x = 0 && srI[2].x = 100 && srI[3].x = 50 && srI[4].x = 200,
    "I7: SortRowsByX 行内按 x、行间按 y (实际 "
    . srI[1].x "," srI[2].x "," srI[3].x "," srI[4].x ")")

Log("")
Log(Fail ? "==== 失败 " Fail " 项 ====" : "==== 全部通过 ====")
ExitApp(Fail ? 1 : 0)
