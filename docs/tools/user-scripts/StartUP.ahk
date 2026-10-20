; ============================================================
;  自定义启动项管理器 - AutoHotkey v2
;  通过 Task Scheduler 在登录时运行此脚本
; ============================================================

#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent false

; ************************************************************
;  ↓↓↓ 用户配置区（只需要改这里）↓↓↓
; ************************************************************

; --- 全局设置 ---
LOG_ENABLED  := true                              ; 是否记录日志
LOG_FILE     := A_ScriptDir "\startup_log.txt"    ; 日志路径
HIDE_TIMEOUT := 10                                ; 隐藏窗口超时（秒）
LOG_MAX_SIZE := 1024 * 100                        ; 日志文件最大大小（字节），超过自动清理，0=不限

; --- 启动项列表 ---
; 每行一个，用 App() 函数添加，参数依次为：
;   App(名称, 路径, 参数, 延迟秒数, 隐藏窗口, 管理员权限, 启用)
;                          │        │       │            │
;                          │        │       │            └─ 默认 true
;                          │        │       └─ 默认 false
;                          │        └─ 默认 false
;                          └─ 默认 0

STARTUP_LIST := []

; —— 在下方添加你的启动项，一行一个 ——

App("AHK_WM",    "C:\Users\Administrator\Desktop\zxw\StartUp\wm.ahk",,,,true,)
App("AHK_WM_notify",    "C:\Users\Administrator\Desktop\zxw\StartUp\osd-timed-notify.ahk",,,,true,)
App("AHK_Launcher",    "C:\Users\Administrator\Desktop\zxw\StartUp\Launcher_V1.2.ahk",,,,,false)
App("AHK_Ping", "C:\Users\Administrator\Desktop\zxw\StartUp\GuiPing.ahk",,,,,)
App("AHK_PrintScreen", "C:\Users\Administrator\Desktop\zxw\StartUp\PrintScreen_V1.1.ahk",,,,true,)
App("ShareX",       "C:\Program Files\ShareX\ShareX.exe",,,true,,false)
App("Listary",       "C:\Program Files\Listary\Listary.exe",,,true,,true)
App("VSCode",     "C:\Users\" A_UserName "\AppData\Local\Programs\Microsoft VS Code\Code.exe",, 3,,, false)

; —— 添加结束 ——

; ************************************************************
;  ↑↑↑ 用户配置区结束 ↑↑↑
; ************************************************************
; ************************************************************
;  以下为功能实现，无需修改
; ************************************************************

; ============================================================
;  快捷添加函数
; ============================================================
App(name, path, args := "", delay := 0, hidden := false, admin := false, enabled := true) {
    STARTUP_LIST.Push({
        name:    name,
        path:    path,
        args:    args,
        delay:   delay,
        hidden:  hidden,
        admin:   admin,
        enabled: enabled
    })
}

; ============================================================
;  启动管理器
; ============================================================
class StartupManager {

    static Run(items, logFile, logEnabled, hideTimeout, logMaxSize) {
        ; 日志自动清理
        if logEnabled && logMaxSize > 0 && FileExist(logFile) {
            try {
                if FileGetSize(logFile) > logMaxSize
                    FileDelete(logFile)
            }
        }

        this._Log(logFile, logEnabled, "")
        this._Log(logFile, logEnabled, "========== 启动项管理器开始执行 ==========")
        this._Log(logFile, logEnabled, "时间: " FormatTime(, "yyyy-MM-dd HH:mm:ss"))
        this._Log(logFile, logEnabled, "用户: " A_UserName "  |  系统: " A_OSVersion)

        successCount := 0
        failCount    := 0
        skipCount    := 0

        for item in items {
            ; 跳过禁用项
            if !item.enabled {
                this._Log(logFile, logEnabled, "[禁用] " item.name)
                skipCount++
                continue
            }

            ; 延迟
            if item.delay > 0 {
                this._Log(logFile, logEnabled, "[等待] " item.name " → " item.delay " 秒")
                Sleep(item.delay * 1000)
            }

            ; 路径检查
            if !FileExist(item.path) {
                this._Log(logFile, logEnabled, "[失败] " item.name " → 路径不存在: " item.path)
                failCount++
                continue
            }

            ; 进程去重
            SplitPath(item.path, &exeName)
            if ProcessExist(exeName) {
                this._Log(logFile, logEnabled, "[已运行] " item.name " → PID " ProcessExist(exeName))
                skipCount++
                continue
            }

            ; 启动
            try {
                workDir := ""
                SplitPath(item.path, , &workDir)
                cmdLine := item.path (item.args ? " " item.args : "")

                if item.admin
                    cmdLine := "*RunAs " cmdLine

                Run(cmdLine, workDir)

                ; 隐藏窗口（等窗口真正出现后再隐藏）
                if item.hidden {
                    this._HideByExe(exeName, hideTimeout)
                    this._Log(logFile, logEnabled, "[成功] " item.name " → 已启动并隐藏")
                } else {
                    this._Log(logFile, logEnabled, "[成功] " item.name " → 已启动")
                }
                successCount++
            } catch as e {
                this._Log(logFile, logEnabled, "[失败] " item.name " → " e.Message)
                failCount++
            }
        }

        this._Log(logFile, logEnabled,
            Format("========== 完毕: 成功 {1} / 失败 {2} / 跳过 {3} ==========",
                successCount, failCount, skipCount))
    }

    ; 通过 ahk_exe 匹配窗口并隐藏
    static _HideByExe(exeName, timeout) {
        try {
            if WinWait("ahk_exe " exeName, , timeout)
                WinHide("ahk_exe " exeName)
        }
    }

    ; 写日志
    static _Log(logFile, logEnabled, msg) {
        if !logEnabled
            return
        try
            FileAppend(msg "`n", logFile, "UTF-8")
    }
}

; ============================================================
;  入口：执行并退出
; ============================================================
StartupManager.Run(STARTUP_LIST, LOG_FILE, LOG_ENABLED, HIDE_TIMEOUT, LOG_MAX_SIZE)
ExitApp()
