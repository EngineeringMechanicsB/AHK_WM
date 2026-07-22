# 更新日志

### v2.10.0 (2026-07-17)

- 🆕 **OSD 逐次调用自定义** — 外部脚本可通过附加 `键=值` 键值对在每次调用时覆盖全部视觉设置（字体大小、不透明度、位置、颜色、宽度、圆角、字体名）；所有键可选，未指定则回退 `[GUI]` 配置默认值
- 🆕 **OSD tag 与实例隔离** — `tag=` 键使同标签 OSD 互相替换（不堆积）；外部 OSD 运行在独立实例池，与 wm.ahk 内部 OSD 互不干扰
- 🆕 **Bar 逐元素 `fs=` 和 `wrap=` 属性** — Layout 元素可独立设置字体大小（`fs=14`）和行数（`wrap=2`）；bar 自动增高以容纳换行内容
- 📚 **双语示例套件** — 新增 `docs/Examples/OSDExamples/`（5 个脚本）和 `docs/Examples/BarExamples/`（3 个脚本），每种均有 `En/` 和 `Ch/` 双语版本，注释详尽含完整参数文档
- 📚 **新示例包括**：tag 替换式歌词播放器、定时通知守护进程、文本文件分页器、双槽位 bar 歌词模拟、多行诗词展示
- 🧹 **移除** `[WorkTime] NotificationRule` — 定时通知改为独立脚本（`osd-timed-notify.ahk`），保持 wm.ahk 精简

### v2.9.0 (2026-07-15)

- 🆕 **Bar 外部部件** — `[Bar] Layout` 的 `external_N` 槽位，外部脚本通过 `WM_COPYDATA` 推送文本；`bar-examples/` 和 `osd-examples/` 含中英文示例
- 🆕 **配置键迁移** — 旧 `snake_case` 自动更名为 `PascalCase`；`CfgRead` 带回退链
- 🆕 **UTF-8 配置修复** — `SanitizeConfigEncoding` 检测并修复损坏的配置文件
- 🐛 **配置编码修复** — 所有写入使用 UTF-16（AHK 原生 INI 格式），彻底解决中文/符号乱码
- 🐛 **WTM 聚焦颜色** — 边框在聚焦/非聚焦间正确切换；`RefreshBorder` 全毁全建 + HWND 验证循环
- 🐛 **WTM MoveDir 修复** — 上下方向改用欧氏距离（与 FocusDir 一致），不再出现按上却左移
- 🐛 **移动窗口到桌面** — `DesktopFocus[target]` 自动设置，窗口插入 Z 序顶端
- 🐛 **Bar 残影修复** — `BarInstance.Destroy()` 正确释放桌面控件 HBITMAP
- 🐛 **字体一致性** — PowerMenu 和 PieMenu 现在遵循 `FontName` 配置
- ⚡ **WTM 响应提升** — 签名每 10ms 检查（原 150ms），稳定延迟降至 80ms
- 🧹 **日志系统重写** — 毫秒时间戳、去重、轮转、启动/退出横幅、`OnExit` 处理
- 🧹 **自检删除** — 由结构化日志取代

### v2.8.5 (2026-07-10)

- 🐛 **修复 GDI 句柄泄漏** — `CreateGradient()` 中 1x1 种子位图每次泄漏，边框拖拽可达 100 次/秒
- 🐛 **修复快速切换桌面竞态** — `DesktopIsSwitching` 标志护卫 `SwitchDesktop`
- ⚡ **Bar 系统轮询优化** — WiFi 和 Disk 信息添加 30 秒缓存
- 🆕 **OSD 外部接口** — `WM_COPYDATA` 接收器，其他脚本可调用弹出 OSD
- 🧹 **重复代码提取** — 共享函数抽取
- 🎨 **平铺边缘间隙修复** — `Gap=0` 时窗口紧贴屏幕边缘

### v2.8.4 (2026-07-01)

- 🐛 **修复剪贴板** — `RecordClipboard()` 缺少 `FileAppend`
- 🐛 **修复 Bar 圆角白边** — `RoundWindowEx` 先禁用 DWM 非客户区渲染
- 🐛 **修复 ShowWin** — `SW_SHOWNA(8)` → `SW_RESTORE(9)`
- 🆕 **Span 对齐** — `+`/`-` 符号控制标签组偏移和文字对齐
- 🧹 **GDI 泄漏** — 任务标记位图追踪释放
- ⚡ **剪贴板防抖** — 200ms 过滤

### v2.8.0 (2026-06-29)

- 🌈 **渐变色** — bar 元素、边框、PowerMenu 支持渐变背景和渐变文字
- 🔲 **Bar 圆角** — 每个元素独立的 `on|off` 开关
- 🎨 **Bar 布局重写** — 新 `N,element,span,colors,bg|tx,on|off` 格式
- 🔧 **边框渐变** — `BorderDrag`/`BorderPin`/`BorderUnfocus` 支持逗号分隔渐变
- ⚙️ **全屏暂停** — `[General] PauseOnFullscreen=on`

### v2.6.4 (2026-06-18)

- 🆕 **配置完整性检查** — 自动检测缺失键并补默认值
- 🐛 **Pin 边框圆角** — 现在读取配置
