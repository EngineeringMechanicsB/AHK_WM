#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
; ==============================================================================
; OSD Example 5 — Text File Pager
; ==============================================================================
;
; [What this does]
;   Reads a .txt file, splits it into pages of N characters each, and lets
;   you flip through them with arrow keys.  Each page is displayed as an OSD
;   popup.  Think of it as a "teleprompter" or "slow reader" for any text.
;
; [Prerequisites]
;   1. wm.ahk must be running
;   2. Edit FILE_PATH below to point to your text file
;
; [Controls]
;   Up / Left / PgUp   — previous page
;   Down / Right / PgDn — next page
;   Home               — jump to first page
;   End                — jump to last page
;   Esc                — exit
;
; [Configurable parameters]
;   FILE_PATH      — path to the .txt file to read
;   CHARS_PER_PAGE — how many characters per page (default 10)
;   OSD_DURATION   — display duration in ms (0 = persistent, replaced on flip)
;
; [How it works]
;   1. On startup, reads the entire file into memory, strips line breaks.
;   2. Splits into pages of CHARS_PER_PAGE characters.
;   3. Arrow keys call AHK_WM_OSD to show the current page.
;   4. Uses the "tag=pager" key so each new page replaces the old one.
; ==============================================================================

; ==================== CONFIGURATION ====================
global FILE_PATH      := A_ScriptDir "\osd-pager-demo.txt"  ; demo file in same folder
global CHARS_PER_PAGE := 10
global OSD_DURATION   := 0    ; 0 = stay until next page (uses tag replacement)
; =======================================================

global gText      := ""   ; full file content
global gPages     := []   ; array of page strings
global gTotalPage := 0
global gCurPage   := 1

; ---- Load file and paginate ----
LoadFile(path) {
    global gText, gPages, gTotalPage, gCurPage
    if !FileExist(path) {
        MsgBox("File not found:`n" . path, "Text Pager", "IconX")
        ExitApp
    }
    gText := FileRead(path, "UTF-8")
    if (gText = "") {
        MsgBox("File is empty or unreadable.", "Text Pager", "IconX")
        ExitApp
    }
    ; Strip line breaks (remove if you want to preserve paragraphs)
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

; ---- Display current page via OSD ----
ShowPage(n) {
    global gPages, gTotalPage, OSD_DURATION
    if (n < 1 or n > gTotalPage)
        return
    pageText := gPages[n]
    ; tag=pager ensures each new page replaces the old OSD
    msg := Format("Page {}/{} | {}", n, gTotalPage, pageText)
    AHK_WM_OSD(msg, OSD_DURATION
        , "fs=22,bg=1E1E2E,tx=CDD6F4,op=88,pos=80,tag=pager")
}

; ---- Navigation hotkeys ----
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

; ---- Startup ----
LoadFile(FILE_PATH)
ShowPage(1)

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
