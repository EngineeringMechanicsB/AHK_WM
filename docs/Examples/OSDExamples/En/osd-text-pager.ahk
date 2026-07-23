#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
; ==============================================================================
; OSD Example 5 — Text File Pager
; ==============================================================================
;
; [What this does]
;   Reads a .txt file, splits it into pages of N words each (space-delimited),
;   and lets you flip through them with arrow keys.  Each page is displayed as
;   an OSD popup — works as a "teleprompter" or "slow reader" for any text.
;
;   Unlike the Chinese version (character-based), English text is split by
;   words to avoid breaking mid-word.
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
;   Tray right-click   — exit (Esc too common to bind)
;
; [Configurable parameters]
;   FILE_PATH      — path to the .txt file to read
;   WORDS_PER_PAGE — how many words per page (default 15)
;   OSD_DURATION   — display duration in ms (0 = persistent, replaced on flip)
;
; [How it works]
;   1. On startup, reads the entire file, normalizes whitespace.
;   2. Splits by spaces into words; groups WORDS_PER_PAGE words per page.
;   3. Arrow keys call AHK_WM_OSD to show the current page.
;   4. Uses the "tag=pager" key so each new page replaces the old one.
; ==============================================================================

; ==================== CONFIGURATION ====================
global FILE_PATH      := A_ScriptDir "\osd-pager-demo.txt"  ; demo file in same folder
global WORDS_PER_PAGE := 15
global OSD_DURATION   := 0    ; 0 = stay until next page (uses tag replacement)
; =======================================================

global gText      := ""   ; full file content
global gPages     := []   ; array of page strings
global gTotalPage := 0
global gCurPage   := 1

; ---- Load file and paginate (word-based) ----
LoadFile(path) {
    global gText, gPages, gTotalPage, gCurPage, WORDS_PER_PAGE
    if !FileExist(path) {
        MsgBox("File not found:`n" . path, "Text Pager", "IconX")
        ExitApp
    }
    gText := FileRead(path, "UTF-8")
    if (gText = "") {
        MsgBox("File is empty or unreadable.", "Text Pager", "IconX")
        ExitApp
    }
    ; Normalize whitespace: newlines → spaces, collapse multiple spaces
    gText := RegExReplace(gText, "[\r\n]+", " ")
    gText := Trim(RegExReplace(gText, "\s+", " "))
    ; Split into words by spaces, group WORDS_PER_PAGE per page
    words := StrSplit(gText, " ")
    gPages := []
    i := 1
    while (i <= words.Length) {
        pageText := ""
        loop WORDS_PER_PAGE {
            if (i > words.Length)
                break
            if (A_Index > 1)
                pageText .= " "
            pageText .= words[i]
            i++
        }
        gPages.Push(pageText)
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
; Exit: tray right-click → Exit (Esc too common to bind)

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
    dataSize := (StrLen(payload) + 1) * 2
    dataBuf := Buffer(dataSize, 0)
    StrPut(payload, dataBuf, "UTF-16")
    cds := Buffer(A_PtrSize * 3, 0)
    NumPut("Ptr", 0, cds, 0)
    NumPut("UInt", dataSize, cds, A_PtrSize)
    NumPut("Ptr", dataBuf.Ptr, cds, A_PtrSize * 2)
    res := 0
    DllCall("User32\SendMessageTimeoutW"
        , "Ptr", h, "UInt", 0x4A, "Ptr", A_ScriptHwnd
        , "Ptr", cds.Ptr, "UInt", 0x2, "UInt", 2000
        , "UInt*", &res, "Ptr")
    return true
}
