#Requires AutoHotkey v2.0
#SingleInstance Force

; 加网段需要管理员权限, 非管理员则自动提权重开
if not A_IsAdmin {
    try Run('*RunAs "' A_ScriptFullPath '"')
    ExitApp
}

; ==============================================================================
; 原有快捷键 (保留不动)
; ==============================================================================

; Win+E 用 Total Commander 替代资源管理器
;#e::Run "C:\Program Files\totalcmd\TOTALCMD64.EXE"

; ==============================================================================
; Win+E → Windows Terminal 里启动 yazi (替代资源管理器 / 原 Total Commander)
;   起始目录固定为「盘符目录」(drives), 效果接近资源管理器的"此电脑"
;   列表由 sync-drives.ps1 自动生成维护: 命名 <盘符>-<卷标>, 例 C-系统 / F-Ventoy
;   插拔 U 盘 / 移动硬盘会自动增删 (见下方 WatchDrives)
; ==============================================================================

DRIVES_BASE := "C:\Users\Administrator\drives"
SYNC_PS     := "C:\Users\Administrator\Desktop\AI\yazi-adb-drives-auto-20261008\sync-drives.ps1"

; 同步盘符 junction (隐藏窗口, 不闪控制台)
SyncDrives() {
    global SYNC_PS
    RunWait('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "' SYNC_PS '"', , "Hide")
}

; 盘符列表变了 (插拔 U 盘/移动硬盘) → 后台重同步一次
WatchDrives() {
    global LastDriveList, SYNC_PS
    cur := DriveGetList()
    if (cur = LastDriveList)
        return
    LastDriveList := cur
    Run('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "' SYNC_PS '"', , "Hide")
}

; 启动时先同步一次, 之后每 3 秒盯一次盘符变化
Run('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "' SYNC_PS '"', , "Hide")
LastDriveList := DriveGetList()
SetTimer(WatchDrives, 3000)

#e:: {
    SyncDrives()   ; 保证「进入即是最新盘符」
    Run('"C:\Soft\terminal\WindowsTerminal.exe" -d "' DRIVES_BASE '" "C:\Users\Administrator\scoop\shims\yazi.exe"')
}

!s::Run("devmgmt.msc")
!n::Run("ncpa.cpl")

try Hotkey("~LButton & RButton", (*) => Send("^c"))
try Hotkey("~RButton & LButton", (*) => Send("^c"))

; ==============================================================================
; EMS 设备发现 + Ping (Alt+P)  —— Catppuccin Mocha 紫 + 圆角
;   上方: 手动输入 IP
;   下方: 轮询发现的在线设备列表, 点击 IP 或按行首字母键快速 ping
;   平台交换机 (PLATFORM_SW) 绿色显示, 且固定排在列表最下方
;   窗口激活时: 字母键 = 直接 ping 对应设备 (字母 ≈ 数字/点, 不影响手输 IP)
;   手动输入或点击选择的 IP 都会写入剪贴板
; ==============================================================================

EMSDIR   := "C:\Users\Administrator\Desktop\AI\ems-device-discovery"
DAEMON   := EMSDIR . "\discovery_daemon.py"
DEVFILES := EMSDIR . "\devices.txt"
ADDFILE  := EMSDIR . "\add_subnet.ps1"

; Catppuccin Mocha 调色板
C_BASE    := "1E1E2E"  ; 主背景
C_SURFACE := "313244"  ; 控件背景
C_TEXT    := "CDD6F4"  ; 主文本
C_SUBTEXT := "A6ADC8"  ; 次要文本
C_MAUVE   := "CBA6F7"  ; 紫 (强调)
C_LAVENDER:= "B4BEFE"  ; 淡紫
C_GREEN   := "A6E3A1"  ; 平台交换机行

; 平台交换机: 绿色显示, 固定排在列表最下方 (发现进程没上报也保留占位, 随时可 ping)
PLATFORM_SW := ["10.253.83.81", "10.255.137.117", "10.255.137.120"
              , "10.253.75.85", "10.253.148.71"]

; 键盘快捷键字母池: 按行顺序分配 (主行优先), 全是字母 —— 与手输 IP 的数字/点不冲突
KEYPOOL := "asdfghjklqwertyuiopzxcvbnm"

global PingGui   := ""
global EditObj   := ""
global LV        := ""
global StatusTxt := ""
global DaemonPid := 0
global GuiHwnd   := 0        ; 当前 PingGui 窗口句柄 (用于字母热键的生效范围)
global LVHwnd    := 0        ; 当前设备列表控件句柄 (自绘用, 只存数字, 不碰已销毁的控件对象)
global RowIsPlat := Map()    ; 行号(1基) -> 是否平台交换机
global KeyOfIP   := Map()    ; IP   -> 快捷键字母 (跨刷新保持稳定)
global KeyTarget := Map()    ; 快捷键字母 -> IP

; 平台交换机精确匹配集
PLATSET := Map()
for ip in PLATFORM_SW
    PLATSET[ip] := true

; RRGGBB -> COLORREF: COLORREF 是 0x00BBGGRR (低字节是红), 别写反
RGB2BGR(hex) {
    return (Integer("0x" SubStr(hex, 5, 2)) << 16)   ; B
         | (Integer("0x" SubStr(hex, 3, 2)) << 8)    ; G
         |  Integer("0x" SubStr(hex, 1, 2))          ; R
}
PLAT_CLR    := RGB2BGR(C_GREEN)
SURFACE_CLR := RGB2BGR(C_SURFACE)

; 字母键: 仅在 PingGui 激活时生效, 按对应字母 ping 该行设备
HotIf(PingGuiActive)
for ch in StrSplit(KEYPOOL)
    try Hotkey("$" ch, PingByKey.Bind(ch))
HotIf()

PingGuiActive(*) {
    global GuiHwnd
    return GuiHwnd && WinActive("ahk_id " GuiHwnd)
}

PingByKey(ch, *) {
    global KeyTarget
    if KeyTarget.Has(ch)
        ExecutePing(KeyTarget[ch])
}

!p:: {
    global PingGui, EditObj, LV, StatusTxt, DaemonPid, DAEMON, GuiHwnd, LVHwnd

    ; 若窗口已存在则关闭重建
    ClosePingGui()

    ; 启动设备发现守护进程 (若未运行)
    if (DaemonPid = 0 || !ProcessExist(DaemonPid))
        Run('python "' DAEMON '"', , "Hide", &DaemonPid)

    ; 创建 GUI: 无边框 + 置顶 + 工具窗口
    PingGui := Gui("-Caption +AlwaysOnTop +ToolWindow +Owner")
    PingGui.BackColor := C_BASE
    PingGui.MarginX := 16
    PingGui.MarginY := 14

    ; 上方: 手动输入 IP (加宽)
    PingGui.SetFont("s14 c" C_MAUVE, "Segoe UI")
    PingGui.Add("Text", "x15 y14", "Ping >")
    PingGui.SetFont("s14 c" C_TEXT, "Segoe UI")
    EditObj := PingGui.Add("Edit", "x85 y10 w533 h32 Background" C_SURFACE " c" C_TEXT " -E0x200 vTargetIP")
    if RegExMatch(A_Clipboard, "^[\w\-\.]+$")
        EditObj.Value := A_Clipboard

    ; 状态提示
    PingGui.SetFont("s10 c" C_SUBTEXT, "Segoe UI")
    StatusTxt := PingGui.Add("Text", "x15 y52 w637", "在线设备 (搜索中...)")

    ; 列标题 (自定义 Catppuccin 紫, 与列表列对齐)
    PingGui.SetFont("s9 c" C_MAUVE, "Segoe UI")
    PingGui.Add("Text", "x19 y76", "键")
    PingGui.Add("Text", "x45 y76", "类型")
    PingGui.Add("Text", "x101 y76", "IP 地址")
    PingGui.Add("Text", "x241 y76", "MAC 地址")
    PingGui.Add("Text", "x431 y76", "掩码")
    PingGui.Add("Text", "x543 y76", "网关")

    ; 设备列表: 去掉系统表头(-Hdr)与边框(-E0x200), 纯深色列表 (加宽)
    PingGui.SetFont("s11 c" C_LAVENDER, "Segoe UI")
    LV := PingGui.Add("ListView", "x15 y96 w637 h190 -Hdr -E0x200 Background" C_SURFACE " c" C_LAVENDER, ["", "", "", "", "", ""])
    LV.ModifyCol(1, 26)    ; 键 (快捷键字母)
    LV.ModifyCol(2, 56)    ; 类型
    LV.ModifyCol(3, 140)   ; IP
    LV.ModifyCol(4, 190)   ; MAC
    LV.ModifyCol(5, 112)   ; 掩码
    LV.ModifyCol(6, 112)   ; 网关

    ; 点击设备 IP 快速 ping
    LV.OnEvent("ItemSelect", (*) => PingSelected())

    ; 回车执行 (默认按钮)
    PingGui.Add("Button", "x-10 y-10 w0 h0 Default").OnEvent("Click", (*) => ExecutePing())

    ; Esc / 关闭 → 停守护进程并关闭
    PingGui.OnEvent("Escape", (*) => StopAndClose())
    PingGui.OnEvent("Close",  (*) => StopAndClose())

    PingGui.Show("AutoSize Center")
    GuiHwnd := PingGui.Hwnd          ; 供 PingGuiActive() 判定字母热键生效范围
    LVHwnd  := LV.Hwnd               ; 供 LVNotify 判定自绘目标
    ApplyRounded(PingGui.Hwnd, 16)

    ; 立即刷新一次, 之后每秒轮询
    RefreshDevices()
    SetTimer(RefreshDevices, 1000)
}

; 给无边框窗口加圆角 (Win10 兼容, 用 SetWindowRgn)
ApplyRounded(hwnd, radius := 16) {
    if !hwnd
        return
    WinGetPos(, , &w, &h, hwnd)
    rgn := DllCall("gdi32\CreateRoundRectRgn"
        , "Int", 0, "Int", 0
        , "Int", w + 1, "Int", h + 1
        , "Int", radius * 2, "Int", radius * 2, "Ptr")
    DllCall("user32\SetWindowRgn", "Ptr", hwnd, "Ptr", rgn, "Int", 1)
}

; 关闭窗口 (同时清掉句柄, 防止字母热键误判/自绘访问已销毁的控件)
ClosePingGui() {
    global PingGui, GuiHwnd, LVHwnd
    GuiHwnd := 0
    LVHwnd  := 0
    if IsObject(PingGui)
        PingGui.Destroy()
}

; 点击设备列表项 → 取该行 IP 执行 ping (IP 现在是第 3 列)
PingSelected() {
    global LV
    Row := LV.GetNext()
    if !Row
        return
    ExecutePing(LV.GetText(Row, 3))
}

; 执行 ping: 写入剪贴板 + 停守护进程 + 关 GUI + 开 ping 窗口
ExecutePing(Target := "") {
    global PingGui, EditObj
    if Target = ""
        Target := Trim(EditObj.Value)
    if Target = ""
        return
    A_Clipboard := Target
    EnsureSubnet(Target)  ; 本机无该网段时自动加最小网段
    StopDaemon()
    ClosePingGui()
    Run(A_ComSpec ' /k "title Ping: ' Target ' && ping ' Target ' -t"')
}

; 自动补网段: 本机没有该设备 /24 网段时, 加一个最小网段 IP 到活跃网卡
; 用 Run 异步执行, 不阻塞 GUI (有网段时 powershell 秒退, 无网段时后台加)
EnsureSubnet(ip) {
    global ADDFILE
    parts := StrSplit(ip, ".")
    if parts.Length != 4
        return
    ps := 'powershell -NoProfile -ExecutionPolicy Bypass -File "' ADDFILE '" -ip "' ip '"'
    Run(ps, , "Hide")
}

; Esc / 关闭窗口
StopAndClose() {
    StopDaemon()
    ClosePingGui()
}

; 停止守护进程 (释放 8004 端口)
StopDaemon() {
    global DaemonPid
    SetTimer(RefreshDevices, 0)
    if DaemonPid && ProcessExist(DaemonPid)
        ProcessClose(DaemonPid)
    DaemonPid := 0
}

; AHK 脚本退出时兜底停守护进程, 防止残留占用 8004
OnExit((*) => StopDaemon())

; IP 补零成定长串, 便于按数字序排序 (10.2.3.4 -> 010.002.003.004)
PadIP(ip) {
    out := ""
    for p in StrSplit(ip, ".") {
        if !IsNumber(p)
            return ip
        out := out . Format("{:03}", p) . "."
    }
    return out
}

; ==============================================================================
; 列表逐行着色: 拦截 WM_NOTIFY / NM_CUSTOMDRAW, 平台交换机行改绿色文字
;   (AHK 原生 ListView 没有逐行颜色接口, 只能自绘)
;   注意: 脚本退出时 AHK 会先清空全局变量再销毁窗口, 此时 ListView 仍会发
;   WM_NOTIFY —— 所以必须先 IsSet() 再取值, 否则退出瞬间会弹错误框
; ==============================================================================
OnMessage(0x004E, LVNotify)   ; WM_NOTIFY

LVNotify(wParam, lParam, msg, hwnd) {
    global LVHwnd, RowIsPlat, PLAT_CLR, SURFACE_CLR
    static NM_CUSTOMDRAW       := -12
    static CDDS_PREPAINT       := 0x00000001
    static CDDS_ITEMPREPAINT   := 0x00010001
    static CDRF_DODEFAULT      := 0x00000000
    static CDRF_NOTIFYITEMDRAW := 0x00000020
    static CDRF_NEWFONT        := 0x00000002
    ; NMCUSTOMDRAW / NMLVCUSTOMDRAW 字段偏移 (32/64 位不同)
    static OFF_ITEM := (A_PtrSize = 8) ? 56 : 36    ; nmcd.dwItemSpec
    static OFF_TEXT := (A_PtrSize = 8) ? 80 : 48    ; clrText (其后 4 字节为 clrTextBk)
    ; 颜色首次调用时缓存一份 (退出阶段全局变量已不可读)
    static CLR_PLAT  := PLAT_CLR
    static CLR_BK    := SURFACE_CLR

    ; 只比对缓存的句柄数字: LV 控件对象在窗口销毁后读 .Hwnd 会抛错
    if !IsSet(LVHwnd) || !LVHwnd
        return
    if NumGet(lParam, 0, "Ptr") != LVHwnd                     ; NMHDR.hwndFrom = 设备列表
        return
    if NumGet(lParam, A_PtrSize * 2, "Int") != NM_CUSTOMDRAW   ; NMHDR.code
        return

    stage := NumGet(lParam, A_PtrSize * 3, "UInt")             ; nmcd.dwDrawStage
    if stage = CDDS_PREPAINT
        return CDRF_NOTIFYITEMDRAW
    if stage != CDDS_ITEMPREPAINT
        return CDRF_DODEFAULT

    row := NumGet(lParam, OFF_ITEM, "UPtr") + 1                ; dwItemSpec (0 基)
    if !IsSet(RowIsPlat) || !RowIsPlat.Has(row)
        return CDRF_DODEFAULT                                  ; 普通设备用控件默认色

    ; 实测 uItemState 常带 CDIS_SELECTED, 不能拿它当"选中态"过滤, 否则整列都不上色
    NumPut("UInt", CLR_PLAT, lParam, OFF_TEXT)
    NumPut("UInt", CLR_BK, lParam, OFF_TEXT + 4)               ; 行背景保持面板色
    return CDRF_NEWFONT
}

; 轮询读取 devices.txt, 刷新设备列表
;   普通设备按 IP 数字序, 平台交换机绿色且固定排在最下方
;   每行首列是该设备的快捷键字母 (窗口激活时按字母 = ping 该设备)
RefreshDevices() {
    global LV, StatusTxt, DEVFILES, PLATSET, PLATFORM_SW
    global RowIsPlat, KeyOfIP, KeyTarget, KEYPOOL
    if !IsObject(LV)
        return

    LV.Opt("-Redraw")
    LV.Delete()
    RowIsPlat := Map()

    normals := []      ; 普通设备
    plats   := Map()   ; 平台交换机 (IP -> 行数据)
    count   := 0       ; 发现进程上报的在线设备数
    err     := ""
    noFile  := !FileExist(DEVFILES)   ; 守护进程还没写出结果

    for line in (noFile ? [] : StrSplit(FileRead(DEVFILES, "UTF-8"), "`n", "`r")) {
        line := Trim(line)
        if line = ""
            continue
        if InStr(line, "ERROR:") = 1 {
            err := line
            continue
        }
        parts := StrSplit(line, "|")
        ip := Trim(parts[1])
        if ip = ""
            continue
        dtype := parts.Has(5) ? parts[5] : ""
        if dtype = "HIK"
            dtype := "海康"
        rec := {ip: ip, dtype: dtype
              , mac:  parts.Has(2) ? parts[2] : ""
              , mask: parts.Has(3) ? parts[3] : ""
              , gw:   parts.Has(4) ? parts[4] : ""
              , pkey: PadIP(ip)}
        if PLATSET.Has(ip)
            plats[ip] := rec
        else
            normals.Push(rec)
        count++
    }

    ; 普通设备: 插入排序, 保证刷新之间顺序稳定
    sorted := []
    for rec in normals {
        pos := sorted.Length
        while (pos >= 1 && StrCompare(sorted[pos].pkey, rec.pkey) > 0)
            pos--
        sorted.InsertAt(pos + 1, rec)
    }

    ; 平台交换机固定排在最后, 顺序同 PLATFORM_SW
    ; (发现进程没上报的也占位保留, 便于随时 ping 到)
    for ip in PLATFORM_SW {
        if plats.Has(ip)
            sorted.Push(plats[ip])
        else
            sorted.Push({ip: ip, dtype: "平台", mac: "", mask: "", gw: ""
                       , pkey: PadIP(ip)})
    }

    ; 分配快捷键字母: 老 IP 的键位保留 (刷新不跳变), 新设备取字母池里下一个空闲字母
    oldKeys := KeyOfIP
    used := Map()
    for rec in sorted
        if oldKeys.Has(rec.ip)
            used[oldKeys[rec.ip]] := true

    KeyOfIP := Map()
    KeyTarget := Map()
    nextKey := 1
    for rec in sorted {
        key := oldKeys.Has(rec.ip) ? oldKeys[rec.ip] : ""
        if key = "" {
            while (nextKey <= StrLen(KEYPOOL)) {
                c := SubStr(KEYPOOL, nextKey, 1)
                nextKey++
                if !used.Has(c) {
                    key := c
                    used[c] := true
                    break
                }
            }
            if key = ""                       ; 字母池用尽 (>26 台): 只能鼠标点
                nextKey := StrLen(KEYPOOL) + 1
        }
        rec.key := key
        if key != "" {
            KeyOfIP[rec.ip] := key
            KeyTarget[key] := rec.ip
        }
    }

    for rec in sorted {
        row := LV.Add(, rec.key, rec.dtype, rec.ip, rec.mac, rec.mask, rec.gw)
        if PLATSET.Has(rec.ip)
            RowIsPlat[row] := true
    }

    LV.Opt("+Redraw")
    WinRedraw(LV.Hwnd)

    if err != ""
        StatusTxt.Text := "在线设备 — " err
    else if noFile
        StatusTxt.Text := "在线设备 (搜索中...) — 按行首字母键直接 Ping"
    else if count = 0
        StatusTxt.Text := "在线设备 (未发现, 持续搜索中...) — 按行首字母键直接 Ping"
    else
        StatusTxt.Text := "在线设备 (" count " 台) — 按行首字母键直接 Ping"
}
