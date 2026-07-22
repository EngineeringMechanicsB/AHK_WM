#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
; ==============================================================================
; OSD 示例 5 — 文本文件分页阅读器
; ==============================================================================
;
; 【功能说明】
;   读取 .txt 文件，按每页 N 个字分页，用方向键翻页。每页通过 OSD 弹窗显示。
;   可以当作"提词器"或"慢速阅读器"来阅读任意文本。
;
; 【使用前提】
;   1. wm.ahk 必须正在运行
;   2. 修改下方 FILE_PATH 指向你的文本文件
;
; 【操作方式】
;   ↑ / ← / PgUp — 上一页
;   ↓ / → / PgDn — 下一页
;   Home         — 跳到第一页
;   End          — 跳到最后一页
;   Esc          — 退出
;
; 【可调参数】
;   FILE_PATH      — 要读取的 .txt 文件路径
;   CHARS_PER_PAGE — 每页显示字数（默认 10）
;   OSD_DURATION   — 显示时长毫秒（0 = 持续显示，翻页时替换）
;
; 【工作原理】
;   1. 启动时读入整个文件，去除换行符
;   2. 按 CHARS_PER_PAGE 切分成页
;   3. 方向键触发 AHK_WM_OSD 显示当前页
;   4. 使用 tag="pager" 键，每次翻页替换旧 OSD，不会堆积
; ==============================================================================

; ==================== 配置区 ====================
global FILE_PATH      := A_ScriptDir "\osd-pager-demo.txt"  ; 同目录下的示例文本
global CHARS_PER_PAGE := 20
global OSD_DURATION   := 0    ; 0 = 持续显示到翻页（tag 替换）
; ================================================

global gText      := ""   ; 全文
global gPages     := []   ; 每页字符串数组
global gTotalPage := 0
global gCurPage   := 1

; ---- 读文件 + 分页 ----
LoadFile(path) {
    global gText, gPages, gTotalPage, gCurPage
    if !FileExist(path) {
        MsgBox("文件不存在：`n" . path, "文本分页器", "IconX")
        ExitApp
    }
    gText := FileRead(path, "UTF-8")
    if (gText = "") {
        MsgBox("文件为空或无法读取。", "文本分页器", "IconX")
        ExitApp
    }
    ; 去除换行符（如需保留段落请删除此行）
    gText := RegExReplace(gText, "[\r\n]+", "")
    len := StrLen(gText)
    gPages := []
    start := 1
    while (start <= len) {
        gPages.Push(SubStr(gText, start, CHARS_PER_PAGE))
        start += CHARS_PER_PAGE
    }
    gTotalPage := gPages.Length
    gCurPage   := 1
}

; ---- 通过 OSD 显示当前页 ----
ShowPage(n) {
    global gPages, gTotalPage, OSD_DURATION
    if (n < 1 or n > gTotalPage)
        return
    pageText := gPages[n]
    ; tag=pager 确保每页替换上一页，不堆积
    msg := Format("第 {}/{} 页 | {}", n, gTotalPage, pageText)
    AHK_WM_OSD(msg, OSD_DURATION
        , "fs=22,bg=1E1E2E,tx=CDD6F4,op=88,pos=80,tag=pager")
}

; ---- 翻页热键 ----
PrevPage() {
    global gCurPage
    if (gCurPage > 1) {
        gCurPage--
        ShowPage(gCurPage)
    }
}
NextPage() {
    global gCurPage, gTotalPage
    if (gCurPage < gTotalPage) {
        gCurPage++
        ShowPage(gCurPage)
    }
}

Up::PrevPage()
Down::NextPage()
Left::PrevPage()
Right::NextPage()
PgUp::PrevPage()
PgDn::NextPage()
Home:: {
    global gCurPage
    gCurPage := 1
    ShowPage(1)
}
End:: {
    global gCurPage, gTotalPage
    gCurPage := gTotalPage
    ShowPage(gTotalPage)
}
Esc::ExitApp

; ---- 启动 ----
LoadFile(FILE_PATH)
ShowPage(1)

; ------------------------------------------------------------------------------
; AHK_WM_OSD(text, duration, opts) —— 参见 osd-custom-all.ahk 完整参数文档
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
