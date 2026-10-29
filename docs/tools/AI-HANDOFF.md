# AI 交接文档 — AHK_WM 现状、坑与后续

> 撰写：2026-10-29。基线 `v2.14.0` + 本地未发布改动（9 项，见第 3 节）。
> 读者：接手继续改 `wm.ahk` 的 AI（或人）。行号基于 2026-10-29 的 11446 行版本，
> 改动后会漂移，请用函数名 grep，不要相信行号。

配套文档：

| 文档 | 内容 |
|---|---|
| `docs/tools/01-算法说明.md` | 现在怎么算（平铺 / 滚动 / Overview），以及多屏带的目标算法 |
| `docs/tools/02-当前问题.md` | 本轮 9 个问题的现象、根因、修法 |
| `docs/tools/03-待拍板.md` | 还没定的决策，带推荐项 |
| `docs/tools/AI-NOTES.md` | 更早一轮的踩坑记录（编码、ByRef、`/validate`、错误弹窗） |
| `docs/CHANGELOG-zh.md` | 对外更新日志 |

---

## 1. 这台机器上的路径

| 角色 | 路径 |
|---|---|
| git 仓库（代码在此） | `C:\Users\Administrator\Desktop\AI\AHK_WM\repo` |
| 工作文档（不提交） | `C:\Users\Administrator\Desktop\AI\AHK_WM\work\docs` |
| 备份 | `C:\Users\Administrator\Desktop\AI\AHK_WM\history\backups` |
| **实际运行的副本** | `C:\Users\Administrator\Desktop\zxw\StartUp\wm.ahk` |
| 配置 | `C:\Users\Administrator\.config\AHK_WM\wm_config.ini`（UTF-16 LE） |
| 排除规则 | `C:\Users\Administrator\.config\AHK_WM\exclude.ini` |
| 运行日志 | `C:\Users\Administrator\.config\AHK_WM\wm.log`（+ `.old`） |
| AutoHotkey | `C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe` |

改仓库 ≠ 改运行中的脚本。部署流程见第 9 节。

### 编码（必须保持）

- `wm.ahk`：**UTF-8 带 BOM + CRLF**。BOM 掉了 AHK 按 ANSI 读，中文全乱。
- `wm_config.ini`、`docs/Examples/example-configs/wm_config.ini`：**UTF-16 LE**。
  用 UTF-8 工具重写会直接毁配置，脚本下次启动读不到任何键。
- 用 Python 改脚本：`encoding='utf-8-sig'` 读写，`newline=''`，最后显式把 LF 转回 CRLF。

---

## 2. 当前状态一句话

单文件脚本，11446 行，版本号仍写 `2.14.0`（用户要求最后统一升 `2.15.0`）。
本轮 9 项修复已完成、语法校验通过、已部署到运行副本，单屏行为现场验证过；
**多显示器相关代码路径在本机无法验证**（本机只有一块 1600×900 屏），
用户会拿回家用真实多屏环境复测。

未提交的东西：`wm.ahk`、`docs/Examples/example-configs/wm_config.ini`。
仓库根目录有若干不该提交的产物：`wm.ahk.bak`、`wm32.exe`、`wm64.exe`、
`wm_osd.ahk`、`README-zh.md`（旧副本）。**不要 `git add -A`**。

---

## 3. 本轮（2026-10-29）改了什么

| 编号 | 内容 | 主要落点 |
|---|---|---|
| B1 | Overview 最小缩放、画布可超屏、视口跟随焦点、1px 下限 | `_OverviewEnter` / `_OverviewEnsureVisible` / `_OverviewApplyViewport` |
| B2 | 普通热键按住只触发一次 | `RegHotkey` 第三参 `once`、`HotkeyOnce` / `OnceRun` / `HotkeyMainKey` |
| B3 | 托盘 Exclude / Diagnose 改成“点选窗口” | `PickWindowThen` / `PickWindowClick` / `PickFinish` |
| B4 | 进 WTM 真正聚焦（含 AttachThreadInput 兜底） | `WTM.Activate` / `FocusWindowSafely` |
| B5 | Alt+D 不再抓其他桌面最小化窗口 | `GetVisibleWindow` 跳过最小化 |
| B6 | 最小化后恢复能重新平铺 | `_MemberSig` 跳过最小化 |
| B7 | Overview 分割线随视口移动、屏外首显不可见 | `_OverviewDrawDividers` / `_OverviewAddLine` / `_AnimGui` |
| B8 | 切回滚动桌面归拢屏外窗口，且不改尺寸 | `SwitchDesktop` → `_GatherDesktop`；`_MoveNoResize` |
| B9 | 非 WTM 操作统一目标 = 光标下窗口 | `_GetTargetHwnd`，见第 6 节 |

附带：去掉全局 100px 窗口过滤（改 2px）；托盘菜单加版本号；
`[GUI] OverviewMinScale`（默认 0.35）进模板与示例配置。

---

## 4. 代码地图（单文件，从上到下）

| 区段 | 行（约） | 说明 |
|---|---|---|
| 顶部全局 | 1–320 | `WM_Version`、主题、GUI 尺寸、日志、吸附、WTM 全局 |
| 日志 | 650–720 | `WMLog`，按级别过滤、去重（同 key 每 50 次才写一次）、512KB 轮转 |
| 配置模板 | 约 2260–2520 | `DefaultIni`，首次运行写出的完整配置文件 |
| 配置加载 | 约 2520–2760 | `IniRead` / `CfgRead`（旧键回退）、`ParseScrollDesktops` |
| 热键注册 | 1770–1900 | `RegHotkey`、`HotkeyOnce`、`RegisterAllHotkeys` |
| OSD | 3137+ | `class OSD`，`Show` / `ShowExternal` / `_ParseOpts` |
| 外部接口 | 3316–3400 | `OnMessage(0x4A, _WM_OnCopyData)`，`OSD:` / `BAR:` 解析 |
| 边框 | 3585+ | `class PinBorder`（Win32 分层窗口画边框，非 GUI） |
| 饼菜单 | 3811+ | `class PieMenu` |
| 状态栏 | 4405+ | `class StatusBar`，部件、渐变、外部部件 `external_N` |
| 显示器 / 槽位 | 5200–5750 | `IsBarWindow`、`GetTileArea`、`GetSlotTable`、`GetLayoutRule` |
| 平铺入口 | 5999+ | `TileCurrentMonitor`（Alt+D） |
| 可见窗口收集 | 6225–6320 | `IsTilableWindow`、`GetVisibleWindow`、`GetVisibleWindowsOnMonitor` |
| 拖拽 / 吸附 | 6478–6700 | `DragMoveHandler`、`DragResizeHandler`、`SnapWindow` |
| **WTM 类** | 6784–10150 | 全部平铺 / 滚动 / Overview / 全屏逻辑 |
| 桌面切换 | 3957+ | `SwitchDesktop`、`MoveWindowToDesktop`、`MoveAndSwitch` |
| 非 WTM 窗口操作 | 3695–3800 | `_GetHwndUnderMouse`、`_GetTargetHwnd`、`_MoveNoResize`、关闭/最小化/最大化/置顶/透明度 |
| 托盘 | 约 11350 | `SetupTrayIcon`，菜单含禁用版本号项 |
| 启动 | 文件末尾 | 加载配置、注册热键、`WTM.Tick` 定时器 |

### WTM 关键方法

| 方法 | 行（约） | 作用 |
|---|---|---|
| `Activate` / `Deactivate` | 6830 / 6902 | 进出 WTM，恢复/记录顺序 |
| `OnDesktopSwitched` | 6955 | 切桌面后重建顺序 |
| `AutoTile` | 7105 | 每屏 `_RePlace` |
| `_RePlace` | 7132 | 单屏按槽位表摆放 |
| `_ScrollInit` / `_ScrollRestore` / `_ScrollReindex` | 7339 / 7356 / 7388 | 页数组生命周期 |
| `_ScrollSync` | 7431 | 成员变化 → 页归属修正 |
| `_ScrollLayout` | 7501 | 一页的矩形计算 |
| `_ScrollParkAnchor` | 7550 | 非当前页停到显示器并集之外 |
| `_ScrollApplyAll` | 7566 | 全页应用 |
| `_GatherAllOffscreen` / `_GatherDesktop` | 7653 / 7690 | 归拢屏外窗口（只移不缩放） |
| `_ScrollFlipPageFocus` / `_ScrollMovePage` | 7804 / 7862 | 页边翻页 |
| `_AnimMove` / `_AnimGui` / `AnimTick` | 7990 / 8033 / 8060 | 所有动画，含分割线 GUI |
| `FocusDir` / `MoveDir` | 8330 / 8387 | 页内方向选择 |
| `MoveToMonitorDir` / `FocusToMonitorDir` | 8472 / 8507 | 物理跨屏 |
| `Tick` / `_SlowCheck` | 8161 / 8177 | 250ms 巡检，成员签名变化 → AutoTile；**Overview 中会重进**（见 J1） |
| `ToggleOverview` / `_OverviewEnter` / `_OverviewExit` | 9485 / 9792 / 9889 | Overview |
| `_OverviewDrawDividers` / `_OverviewAddLine` | 9676 / 9602 | 分割线 |
| `_OverviewApplyViewport` / `_OverviewEnsureVisible` | 9750 / 9766 | 视口平移 |
| `_ForcePlace` | 9916 | 直接 `SetWindowPos`（含尺寸） |

---

## 5. 核心数据模型

```ahk
; 桌面
CurrentDesktop           ; 1..9
Desktops[d]              ; 该桌面的 hwnd 列表
AlwaysVisible            ; 固定（所有桌面可见）的 hwnd 集合
DesktopFocus[d]          ; 切回该桌面时要恢复的焦点 hwnd

; 滚动（只一台屏）
WTM.ScrollOn             ; 当前桌面是否滚动
WTM.ScrollMon            ; 滚动屏序号（1-based）
WTM.ScrollPages          ; 数组，每项 Page = Map(monIdx -> hwnd 数组)
WTM.ScrollView           ; 当前页号（1-based）
WTM.ScrollOwner[hwnd]    ; 窗口归属显示器
WTM.ScrollPageOf[hwnd]   ; 窗口归属页号
WTM.ScrollDesktop        ; 页快照按桌面保存

; 顺序
WTM.TileOrder            ; 当前桌面所有被管窗口顺序
WTM.DesktopOrders[d]     ; 每桌面顺序

; Overview（全部是画布坐标）
OverviewRects[hwnd]      ; {x,y,w,h} 画布坐标
OverviewView             ; {tx,ty,vx,vy,cw,ch,tw,th,wx0,wy0,s}
OverviewPages            ; 页矩形（画布坐标）
OverviewFrames           ; 分割线 GUI 列表
Overview_SmallKeep       ; 退出时白名单，AutoTile 期间有效

; 动画
WTM.Anim[hwnd]           ; {x,y,w,h,sx,sy,sw,sh,t0,...}
```

### 屏幕坐标换算（Overview 唯一的换算入口）

```ahk
screen.x = v.tx + canvas.x - v.vx
screen.y = v.ty + canvas.y - v.vy
```

分割线、窗口、导航、拖拽全部走这一条。任何地方直接用 `r.x` 当屏幕坐标都是 bug
（B7 之前就是这样漏的）。

---

## 6. 必须维持的不变量

1. **非当前页停在所有显示器并集之外**（`_ScrollParkAnchor`）。否则会在相邻屏露出来。
2. `ScrollView` 从 1 开始；`ScrollPages` 空时视为 1。
3. `ScrollPageOf` / `ScrollPages` 必须一致，改页后调 `_ScrollReindex`。
4. **最小化窗口不参与收集、不参与归拢**。`WinGetPos` 对最小化窗口返回假 rect
   （常见 `160×28`），任何 `WinMove` 都会把这个假尺寸写成恢复尺寸。
5. 只移动不改尺寸 → `_MoveNoResize`（`SetWindowPos` + `SWP_NOSIZE`）。
6. **非 WTM 的窗口操作目标 = 光标下窗口**（`_GetTargetHwnd`）。WTM 内部仍用
   `FocusHwnd`。新增非 WTM 操作时不要写 `WinExist("A")`。
7. Overview 退出必须设 `Overview_SmallKeep`，`AutoTile` 结束后清空。
8. 外部边框 / 分割线 / OSD 都是独立分层窗口，不进 `BorderMap`，但要进孤儿清扫保留列表。

---

## 7. 踩坑清单（本轮新增，按代价排序）

### 7.1 分层窗口第一次 `Show` 在屏幕外 → DWM 永不合成

- 现象：Overview 分割线只显示“进 Overview 那一刻屏内可见”的那几条，左右移动后新页缝没有线。
- 根因：`Gui.Show()` 加 `WinSetTransparent` 的分层窗口，首次显示坐标落在屏幕外时
  DWM 不建合成表面；之后 `SetWindowPos` 移进屏幕仍然不可见。
- 修法（`_OverviewAddLine`）：先 clamp 到屏幕内 `Show`，再 `_MoveNoResize` 到真实坐标。

```ahk
sx := Max(0, Min(A_ScreenWidth - w, x))
sy := Max(0, Min(A_ScreenHeight - h, y))
g.Show(Format("x{} y{} w{} h{} NoActivate", sx, sy, w, h))
if (sx != x || sy != y)
    _MoveNoResize(g.Hwnd, x, y)
```

- 适用范围：任何“创建后立刻放到画布/虚拟坐标”的 GUI（以后做多屏带还会遇到）。

### 7.2 最小化窗口的假 rect

- `WinGetPos` 返回 `160×28`；`WinMove` 会把它写成恢复尺寸，用户看到窗口变小。
- 修法：收集阶段跳过 `WinGetMinMax(hwnd) = -1`；移动一律用 `_MoveNoResize`。
- 相关：`_GatherAllOffscreen`、`_GatherDesktop`、`GetVisibleWindow`、
  `GetVisibleWindowsOnMonitor`、`_MemberSig` 都已加最小化跳过滤镜。

### 7.3 `KeyWait` 不接受带修饰符的键名

`NormalizeHotkey` 产出 AHK 写法（`!w`、`!{Enter}`）。`KeyWait("!w")` 直接抛
`Parameter #1 invalid`，包装静默失效，热键照旧连发。

- `HotkeyMainKey()` 先剥 `! ^ + # ~ * $ < >`，`{Enter}` 去花括号，再判断
  `WheelUp/Down/LButton/RButton/MButton` 与 `&` 组合键 → 返回空，退回连发。
- 连发白名单：WTM 方向/移动/缩放、跨屏移动/聚焦、Alt+滚轮、拖拽。

### 7.4 未初始化全局在 AHK v2 直接报错

`PickActive` / `PickCb` 之前没有声明，托盘点 Exclude 无反应，日志里是
`This global variable appears to never be assigned a value`。现在在全局区初始化。

### 7.5 `Map` 缺键会抛异常

`Map()[key]` 不返回空串，直接 `Item has no value`。一律先 `.Has()`。

### 7.6 `//` 只接受整数

`GetTileArea` 算出的 `W/H` 是浮点，`(W - w) // 2` 抛
`Expected an Integer but got a Float`。用 `/ 2` + `Round()`。

### 7.7 ByRef 调用点必须带 `&`

`GetTileArea(m, gap, &X, &Y, &W, &H)`。漏 `&` 不报错，只是永远拿不到值。

### 7.8 `Ahk2Exe` 不能当语法检查

这台机器上它对任何脚本都报 `Failed to compile:`。用
`AutoHotkey64.exe /validate /ErrorStdOut`（`docs/tools/validate.sh`）。

### 7.9 系统自动重复 + `#MaxThreadsPerHotkey=1`

AHK 热键按住会按系统重复率重复触发。用 `KeyWait(主键, "L")` 让线程挂住，
重复触发被线程上限丢掉。副作用：该热键在松键前不响应第二次，这是想要的行为。

### 7.10 用户现场比截图可信

遇到过：我截图判断“线在”，用户坚持“没有”。事实是 Windows 截屏能拿到已绘制
但未合成的表面，用户眼睛看不到。**以用户描述为准，用日志/坐标推理，不要用截图反驳。**

---

## 8. 可用的工具与排障手段

| 工具 | 用法 | 备注 |
|---|---|---|
| `docs/tools/validate.sh` | `bash docs/tools/validate.sh [file]` | 只解析不执行，`OK` = 通过 |
| `docs/tools/run_testslots.sh` | 同上 | 抽顶层函数跑槽位/方向数学断言；**类方法抽不到**，可测逻辑尽量放顶层函数 |
| `docs/tools/probe_pick.ahk` | 随机布局对比方向选取 | 改方向算法后跑 |
| `docs/tools/check_borders.ps1` | 列出所有 `AHKWM_BORDER` 窗口 | 查边框泄漏 |
| `docs/tools/ahk-error-watcher.ahk` | 轮询 AHK 报错弹窗 → 截图 → OCR → 记 `errors.log` → 关窗 | 配 `ocr.ps1`（PowerShell 5.1 + WinRT OCR） |
| `docs/tools/sync_version.sh` | `--check` / `--set X.Y.Z` | 升版本时用，会同步文档与 CHANGELOG 断言 |
| `docs/tools/release.sh` | 发布链 | 本机 Ahk2Exe 不可用，只能用到语法那一步 |

### 日志

- `[Logging] Level`：`DEBUG` / `INFO` / `WARN` / `ERROR`。默认 `INFO`。
- 同样内容去重：同 `组件|消息` 每 50 次才写一行，行尾标 `(repeated Nx)`。
- 512KB 轮转到 `.old`。
- 现场排障让用户：`Alt+R` 重载 → 复现 → 把 `wm.log` 尾部贴回来。
- 临时诊断日志（如 `Overview pages=...`）用完必须删掉，用户不喜欢日志噪音。

### 环境限制

- 本机一块屏 1600×900：`_AdjacentMonitor`、`MoveToMonitorDir`、多屏 Overview、
  滚动屏 + 副屏组合**全部无法实测**。
- 假 hwnd 过不了 `WinExist` / `_OrderIndex`；需要窗口身份的测试必须建真 `Gui` 再销毁。
- `Ahk2Exe` 不可用；发布产物由用户自己在别处编译。
- 混合 DPI 未测。

---

## 9. 部署与回滚

```bash
# 1. 备份运行副本（必须）
cp "C:/Users/Administrator/Desktop/zxw/StartUp/wm.ahk" \
   "C:/Users/Administrator/Desktop/AI/AHK_WM/history/backups/wm.ahk.before-<tag>-$(date +%Y%m%d)"

# 2. 校验
bash docs/tools/validate.sh
bash docs/tools/run_testslots.sh

# 3. 部署（用户按 Alt+R 重载，或在托盘重载）
cp wm.ahk "C:/Users/Administrator/Desktop/zxw/StartUp/wm.ahk"
```

回滚 = 把备份复制回去 + `Alt+R`。备份命名参考：
`wm.ahk.before-targetgather-20261029`（运行副本）、`wm.ahk.repo-before-...`（仓库副本）。

**不要**直接编辑运行副本，也不要在运行副本上做实验。

---

## 10. 还没定的（详见 `03-待拍板.md`）

| 编号 | 问题 | 推荐 |
|---|---|---|
| J1 | Overview 中成员变化，`_SlowCheck` 重进 `_OverviewEnter`，视口/分割线被重置 | 保留 `vx/vy` 与 `FocusHwnd`，只重算矩形和线 |
| J2 | 光标在状态栏 / 自身 GUI 上 → `_GetTargetHwnd()` 返回 0，操作不执行 | 保持严格光标语义，不回退焦点 |
| F3 | 外部接口第一批指令、旧 `BAR:` 是否删、`QUERY` 返回方式 | 用户定为“复杂，后面再谈” |
| F1 | 术语表 `docs/GLOSSARY.md`（双语一文件） | 已定形式，最后写 |
| G2 | 版本号 | 全部改完统一升 `2.15.0` |
| S1 | 多屏水平滚动带 | 见第 11 节 |

F4（不再向后兼容）已定：迁移函数保留源码 + 注释 “legacy, not executed”，
不做 `migrate_config.py`；兼容说明写本地文档，**不上传 git**。

---

## 11. S1 多屏滚动带 — 下一块硬骨头

### 现状为什么做不到

1. 页的坐标只基于 `ScrollMon` 一台屏；
2. 页号是全局整数，上下两条带没法各自维护；
3. 新窗口只路由到 `ScrollMon`；
4. 跨屏是物理搬运，不是同一条带上的平移。

### 目标模型（用户倾向并集口径）

- 水平相邻的屏（垂直重叠足够 + 水平间隙足够小）取传递闭包 → 一条**带**；
- 每条带：虚拟视口 = 水平并集 × 垂直交集；自己的页数组和页号；
- 一页在整条带并集矩形上取槽位表，窗口可跨显示器边框；
- 左右翻页 = 整条带平移；上下到边 → 跨带；
- Overview：带内页横排，带与带上下排列。

### 建议实施顺序

1. 新增 `ScrollBands`（建议 `static ScrollBands := []`），每项：
   `{mons: [..], x0, y0, w, h, pages: [], view: 1}`；先只支持“每个桌面一条带”，
   单屏时结构与现在等价，保证不回退。
2. 写 `_BuildBands(desktop)`：水平邻接判定 + 传递闭包 + 按 `x0` 排序；
   垂直交集小于阈值（建议 `min(160, 0.3 × 较矮屏高)`）则不组带。
3. 把 `ScrollMon` 换成“带”的抽象，但**保留 `ScrollMon` 作为单屏兼容别名**指向
   `bands[0].mons[0]`，减少一次性改动面。
4. 改这几处：`_ScrollLayout`、`_ScrollParkAnchor`（锚点要落在**所有带**之外）、
   `_ScrollApplyAll`、`_ScrollSync`（新窗口按焦点窗口所在带路由）、
   `_ScrollFlipPageFocus`、`_ScrollMovePage`、`_ScrollPageFocusTarget`。
5. 快捷键语义：带内 `Alt+H/L` 用方向选择/翻页；`Ctrl+Alt+Shift+K/J` 跨带；
   `Ctrl+Alt+Shift+H/L` 在带内是否保留物理搬运，取决于 H5 决策。
6. Overview 的 `_OverviewLayoutMap` / `_OverviewPageRects` 要按带分组布局。
7. 配置 H4：`ScrollableDesktops=1`（该桌面所有水平带滚动）/ `1:2`（只让 2 号屏所在带滚动）。

### 风险点

- 停靠锚点必须避开**所有**显示器（不只是滚动屏），否则窗口会在副屏露头；
- 槽位跨边框时 `GetTileArea(monIdx, ...)` 要换成带矩形版本；
- 页在带间迁移（窗口在带 A 被移到带 B）时 `ScrollOwner` / `ScrollPageOf` 要同步；
- Overview 缩放下限 0.35 对超宽带（3840+）可能不够，需要复核；
- 现有单屏测试基线（`run_testslots.sh`）必须保持绿。

**建议单独分支 `feat/scroll-bands`。** 单屏行为不变是硬要求，因为用户日常就在用。

---

## 12. 外部接口（F3）现状

- `WM_COPYDATA (0x4A)` → `_WM_OnCopyData`（约 3319 行）。
- `OSD:text[:duration][:fs=..,op=..,x=..,y=..,bg=..,tx=..]` → `OSD.ShowExternal`，
  每次调用独立 GUI，不互相覆盖。
- `BAR:slot:lo/hi:text[:opts]` 新格式；旧的 `BAR:slot:text` 仍能解析（待删）。
- `BAR:` 写入 `[Bar]` 的 `external_N` 项，由状态栏部件读取；外部写入会被定期刷新覆盖，
  需要理解这个刷新时序再改。
- 计划中的 `BORDER:ADD/SET/DEL/CLEAR`、`MOVE`、`FOCUS` 等：外部边框必须单独存表，
  不能进 WTM 的 `BorderMap`，否则孤儿清扫和 WTM 刷新会互相打架。

---

## 13. 协作约定（用户明确要求）

- **中文回复**，直接给结论，不要铺垫。
- 复杂任务先给方案/计划，确认后再动代码。
- **功能没定型、没验证前不要写文档**；用户会明确说“现在改文档”。
- 注释：英文在前、较完整；中文极简。不要叙事性注释。
- 版本号最后统一升；不要中途改。
- 不自动 `git push`；用户说“提交”时才提交，提交信息 `<type>: <摘要>`。
- 不提交 `*.exe`、`*.bak`、运行副本、`docs/tools/shots/`、`errors.log`。
- 改任何东西前先备份，且备份放项目自己的 `history/backups`。
- 用户会自己观察现象；他描述“没有就是没有”，不要用截图/推断反驳。
- 兼容代码保留并注释 `legacy, not executed`；兼容说明文档只留本地，不进 git。

---

## 14. 改完自检清单

- [ ] `bash docs/tools/validate.sh` → `OK`
- [ ] `bash docs/tools/run_testslots.sh` → `==== 全部通过 ====`
- [ ] 临时诊断日志已删除
- [ ] 新逻辑没有用 `WinExist("A")` 当目标（除桌面切换焦点记忆）
- [ ] 移动窗口用 `_MoveNoResize` 或确认要改尺寸
- [ ] 最小化窗口被跳过
- [ ] 分层 GUI 首次 `Show` 在屏幕内
- [ ] 备份存在，运行副本已更新
- [ ] 中文文档只在用户要求时更新

### 单屏可自测（回家前先过一遍）

- `Alt+D` 平铺；`Alt+Q/W/F/T` 对光标下窗口生效（焦点在别处也要生效）
- `Alt+O` Overview：分屏线随左右移动出现；`Alt+HJKL` 移到视口外会自动平移
- `Alt+Shift+D` 进 WTM：焦点真实切到窗口，边框跟随
- 滚动桌面：右翻几页 → 切到别的桌面 → 切回来，窗口仍在当前页内，尺寸未变
- 最小化一个窗口 → 恢复 → 自动重新平铺
- 普通热键按住不放 → 只触发一次

### 必须回家多屏验证

- `Ctrl+Alt+Shift+H/L/K/J` 把窗口发到相邻屏后源屏重排
- 滚动屏 + 副屏：翻页时窗口不会在副屏露头
- 滚动桌面切回时副屏窗口不被误归拢
- 多屏 Overview 布局与分割线
- `ScrollableDesktops=1:2` 指定屏生效、其它屏普通平铺
