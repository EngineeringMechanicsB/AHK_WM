#Requires AutoHotkey v2.0
#SingleInstance Force
; ==============================================================================
; OSD 示例 2 — 全自定义外观展示（逐项演示所有覆盖键）
; ==============================================================================
;
; 【功能说明】
;   依次弹出 7 条 OSD 通知，每条使用不同的视觉覆盖，演示全部可用的
;   per-call 自定义键。
;
; 【可用覆盖键（全部可选）】
;   fs  — 字体大小（磅）        默认：配置文件 OSDFontSize，20
;   op  — 不透明度（百分比）    默认：配置文件 OSDOpacity，78
;   pos — 垂直位置（百分比）    默认：配置文件 OSDPositionPct，80
;   x   — 水平位置 px 或 %      默认：居中                  如 x=300 x=50%
;   y   — 垂直位置 px 或 %      默认：pos 或配置值           如 y=200 y=30%
;   bg  — 背景色（6 位 hex）   默认：主题 Color_Bg
;   tx  — 文字色（6 位 hex）   默认：主题 Color_Active
;   wr  — 最大宽度（像素）      默认：屏幕宽度 × 0.85，超出自动换行
;   rd  — 圆角开关 on/off      默认：配置文件 OSDRounded
;   rr  — 圆角半径（像素）      默认：配置文件 OSDRadius
;   fn  — 字体名称              默认：配置文件 FontName
;   tag — 逻辑标签，同 tag 的新 OSD 会替换旧的（参见 osd-complex-demo）
;
;   所有键均可选。未指定的键回退使用 wm_config.ini 的全局值。
;   不传 opts 的旧脚本完全不受影响。
;
; 【带自定义的消息格式】
;   OSD:<文本>:<持续时间毫秒>:fs=36,op=95,bg=CC3333,tx=FFFFFF,pos=30
;
; 【使用方法】
;   双击运行，依次观看 7 种不同风格的 OSD 弹出效果。
; ==============================================================================

; --- 1. 大字红色警告（屏幕上方）---
AHK_WM_OSD("⚠️ 警告：磁盘空间不足！", 3000, "fs=36,bg=CC3333,tx=FFFFFF,op=95,pos=30")
Sleep(3500)

; --- 2. 小字绿色成功（屏幕下方）---
AHK_WM_OSD("✅ 备份完成 (2.3 GB)", 3000, "fs=14,bg=33AA55,tx=FFFFFF,op=85,pos=92")
Sleep(3500)

; --- 3. 半透明紫色（屏幕中上）---
AHK_WM_OSD("🎵 正在播放：Hey Jude - The Beatles", 3000, "fs=24,bg=A020F0,tx=FFFFFF,op=70,pos=40")
Sleep(3500)

; --- 4. 窄宽度多行自动换行 ---
AHK_WM_OSD("这是一段很长的文字用来演示多行自动换行效果，最大宽度限制为 300 像素。", 4000, "fs=16,bg=1E1E2E,tx=CDD6F4,wr=300,pos=60")
Sleep(4500)

; --- 5. 直角矩形（无圆角）---
AHK_WM_OSD("直角矩形 OSD — 关闭圆角", 3000, "fs=20,bg=444444,tx=FFD700,rd=off,pos=50")
Sleep(3500)

; --- 6. 大圆角 ---
AHK_WM_OSD("大圆角 OSD — 半径 30px", 3000, "fs=20,bg=2E2E4E,tx=7AA2F7,rr=30,pos=50")
Sleep(3500)

; --- 7. 自定义字体 + 高透明度 ---
AHK_WM_OSD("Consolas 字体 | 半透明", 3000, "fs=18,bg=0E050F,tx=9ECE6A,op=60,fn=Consolas,pos=70")
Sleep(3500)

; --- 8. 像素+百分比混合定位 (x=300, y=60%) ---
AHK_WM_OSD("x=300, y=60% — 像素+百分比混用", 2500, "fs=20,bg=2E5E8E,tx=FFF,x=300,y=60%")
Sleep(3000)

; --- 9. 纯百分比定位 (x=40%, y=30%) ---
AHK_WM_OSD("x=40%, y=30% — 纯百分比定位", 2500, "fs=22,bg=5E2E8E,tx=FFF,x=40%,y=30%")
Sleep(3000)

ExitApp

; ------------------------------------------------------------------------------
; AHK_WM_OSD(text, duration, opts) —— 通用辅助函数，可直接复制到你的脚本中使用
; ------------------------------------------------------------------------------
; 参数：
;   text     - 要显示的文本（UTF-8，支持中文/emoji/任意 Unicode）
;   duration - 显示时长（毫秒），默认 1000
;   opts     - （可选）逐次调用的外观覆盖，"键=值,键=值" 格式
;              所有键可选，未指定则回退配置文件全局默认值
;
; 可用 opts 键（全部可选）：
;   fs=N     — 字体大小（磅），默认配置 OSDFontSize
;   op=N     — 不透明度 0-100，默认配置 OSDOpacity
;   pos=N    — 垂直位置百分比，默认配置 OSDPositionPct
;   x=N[%]   — 水平位置 px 或百分比（默认居中）
;   y=N[%]   — 垂直位置 px 或百分比（默认 pos 或配置值）
;   bg=RRGGBB — 背景色 hex，默认主题 Color_Bg
;   tx=RRGGBB — 文字色 hex，默认主题 Color_Active
;   wr=N     — 最大宽度像素，超出自动换行，默认 monW×0.85
;   rd=on|off — 圆角开关，默认配置 OSDRounded
;   rr=N     — 圆角半径像素，默认配置 OSDRadius
;   fn=名称  — 字体名称，默认配置 FontName
;   tag=ID   — 逻辑标签，同标签新 OSD 替换旧 OSD，无标签则多实例共存
;
; 返回值：true=发送成功，false=未找到 wm.ahk 窗口
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
