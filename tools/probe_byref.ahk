#Requires AutoHotkey v2.0
#NoTrayIcon
; 判定：给 ByRef 形参传"类静态属性"时，值会不会回写？
; 只写文件，不弹任何对话框。

OUT := A_ScriptDir "\probe_byref.out.txt"
try FileDelete(OUT)
P(s) => FileAppend(s "`n", OUT, "UTF-8")

F(&t, v) {
    t := v
}

class C {
    static V := 0
    static Run() {
        ; ① 传局部变量
        x := 0
        F(x, 11)
        P("1 局部变量回写:      " (x = 11 ? "YES" : "NO") "  (x=" x ")")
        ; ② 传类静态属性
        C.V := 0
        F(C.V, 22)
        P("2 类静态属性回写:    " (C.V = 22 ? "YES" : "NO") "  (V=" C.V ")")
        ; ③ 经 this 访问静态属性
        C.V := 0
        F(this.V, 33)
        P("3 this.属性回写:     " (C.V = 33 ? "YES" : "NO") "  (V=" C.V ")")
        ; ④ 传数组元素
        a := [0]
        F(a[1], 44)
        P("4 数组元素回写:      " (a[1] = 44 ? "YES" : "NO") "  (a[1]=" a[1] ")")
    }
}

try {
    C.Run()
    ; ⑤ 复现 TickElapsed 的真实形态：形参初始为 0
    P("---- 复现 TickElapsed 形态 ----")
    C.V := 0
    TickProbe(C.V, 10)
    P("首次调用返回:        " TickProbe(C.V, 10) "  (期望 0)")
    P("第二次调用返回:      " TickProbe(C.V, 10) "  (真回写应≈0或正数，假回写必恒为 0)")
} catch as e {
    P("EXC: " e.Message " | What=" e.What)
}

TickProbe(&lastTick, nominal) {
    now := A_TickCount
    dt := lastTick ? (now - lastTick) : 0
    lastTick := now
    if (dt < 0 || dt > 1000)
        dt := nominal
    return dt
}

ExitApp(0)
