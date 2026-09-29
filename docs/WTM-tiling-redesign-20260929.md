# WTM 重构设计文档 —— 用「布局规则槽位模型」替代像素几何

> 日期：2026-09-29
> 状态：**设计稿，未写任何代码**
> 目标文件：`wm.ahk`（v2.10.2，7487 行）
> 关联：`[Tiling] Rules` 自定义布局、`BorderFrame` 边框系统、虚拟桌面、PinBorder/AllBorders

---

## 0. 一句话结论

把 WTM 从「**读取像素坐标 → 定时轮询检测变化 → 全量重铺 → 全毁全建边框**」
改造成「**读配置规则/内置算法 → 归一化槽位表 → 槽位↔窗口持久映射**」。

- **移动** = 在槽位表上做纯数学比较，选目标槽位，**只交换两个槽位的归属**，其他窗口一个像素都不动。
- **平铺** = 复用已有的 `TileWindowsOnMonitor()`，不写第二套平铺逻辑。
- **边框** = 复用已有的 `BorderFrame`（含其成熟的几何缓存与 Z 序能力），但把「焦点一变就全毁全建」换成 **diff 同步**，一个窗口一个边框，销毁时机收敛到一张明确的事件表。

---

## 1. 现状代码地图（我读到的关键点）

### 1.1 平铺（已高度复用，WTM 不必重造）

| 位置 | 函数 | 作用 |
|---|---|---|
| 4906 | `TileWindowsOnMonitor(wins, monIdx, gapBase, useDwmComp)` | **唯一平铺入口**，TileSmart / WinSelect / WTM 共用 |
| 4914 | `SetTileBound` / `ClearTileBound` | 平铺期间保护边界，`PlaceWin` 里做 clamp |
| 4922 | `ApplyCustomLayout` | 命中用户规则 → 返回 true |
| 4924 | `_GetTileMode` + `TileVertical/Ultrawide/Normal/Grid` | 无规则时的内置算法 |
| 4956 | `PlaceWin` | 施加 gap + 边界 clamp + `WinRestore` + `WinMove` |

**关键既有事实**：`TileWindowsOnMonitor` 已经同时支持"用户规则"和"内置算法"，且 **WTM 已经调它**（5639-5642）。也就是说"让 WTM 使用智能平铺方案"这件事**代码层面已经成立**——你痛的不是这里，而是下面两件事：

1. `wins` 数组的**顺序即槽位**，而这个顺序由一个会自我重排的列表 `TileOrder` 决定（5591-5616 `RebuildOrder`）；
2. 移动/focus/重铺时，`TileOrder` 与"窗口当前像素位置"互相污染。

### 1.2 规则解析链路（我确认过的语义）

```
ParseAxis(810)          → {lo, hi, align}   ; "1"→0..1, "a/b"→(a-1)/b..a/b, "(a-c)/b"→(a-1)/b..c/b
ParseLayoutRules(836)   → Map(monKey → Map(N → Array[N]{x:{lo,hi},y:{lo,hi}}))
GetCustomLayout(933)    → 精确匹配 M|N，其次 "*"|N
ApplyCustomLayout(945)  → wins[i] ← rules[i]
```

- 规则组必须 **1..N 每个序号恰好出现一次**，否则整组被丢弃并写日志（904-920）。这个校验已经很稳。
- `Rules` 的 `M` 字段是**显示器号**（1 起），只在 `ApplyCustomLayout` 里通过 `GetCustomLayout(monIdx, n)` 参与匹配；`n` 是**该显示器上的窗口数量**（5623-5632 按 `GetMonitorIndex` 分组后分别铺）。
- ⚠️ **发现一个静默无效项**：`ParseAxis` 解析出的 `align`（后缀写法是**符号加在分母前**：`1/-2` = Left、`1/+2` = Right，见 `docs/config-reference-zh.md` 的 span 说明）在 `ApplyCustomLayout` 里**完全没有被使用**（只被状态栏元素用到，3481/3531）。也就是平铺规则里的 `+/-` 后缀目前是**解析了但无效果**的。按你的答复（§9-Q9）保留解析、修正文档，行为不变。
- ⚠️ **gap 语义分叉**：WTM 传的是 `Border_Gap`（`[Border] Gap`，默认 10），TileSmart/WinSelect 传的是 `Tile_Gap`（`[Tiling] Gap`，默认 15）。你给的示例配置写的是 `[Tiling] Gap=0`，但 WTM 实际读的是 `[Border] Gap`。**这是个必须确认的坑**（§9-Q1）。

### 1.3 WTM 类现状（5511-6082，577 行）

| 成员 | 说明 | 问题 |
|---|---|---|
| `TileOrder` | **全局单一数组，索引即槽位** | 增删窗口时全员位移的根源 |
| `DesktopOrders` | 每桌面保存一份 `TileOrder` 克隆 | 思路正确，但保存的是"顺序"而非"槽位归属" |
| `_Signature` | 枚举全部窗口 + **O(n²) 冒泡排序**（5662-5670），几何量化到 **32px** | 每 10ms 跑一次；量化和排序都很贵 |
| `Tick` | 10ms 轮询；`Alt` 按住则整段跳过（5682） | Alt 组合键期间完全不刷新（含边框） |
| `RefreshBorder` | **只要"焦点 + 窗口列表"签名变化 → `DestroyAllBorders()` 全毁全建**（6026-6044） | **边框闪烁/残影/卡顿的头号来源** |
| `DestroyAllBorders` | `DestroyWindow` + **20 轮 `IsWindow` 验证循环**（5992-6004） | 每次焦点变化都跑，且引入 `Sleep` |
| `MoveDir` | `_PickSwapTarget` 用**当前像素中心**选目标（5770-5810） | 与规则布局不同构，且受 gap/DWM/bar 干扰；历史 CHANGELOG 里"按上却左移"就是这里 |
| `_MoveWindowToMonitor` | 跨屏把窗口挪到屏幕中心再全量重铺 | 会造成同屏其他窗口重排 |

### 1.4 边框系统：目前有 **4 个所有者**并行

| 所有者 | 位置 | 存活条件 |
|---|---|---|
| `BorderFrame` | 2779 | 基类（`Place` / `SetColor` / `Hide` / `Destroy`） |
| `DragBorder` | 2961 | 拖拽期间的单一边框 |
| `PinBorder` | 3011 | 置顶窗口，独立定时器 |
| `AllBorders` | 6089 | 全窗口边框模式（WTM 激活时被 `Suspend`，5546/6135） |
| `WTM.BorderMap` | 5517 | WTM 自己的 map |

**好消息**：`BorderFrame.Place()` 是**可复用的**——它有完整几何缓存 `LastPX/LastPY/LastPW/LastPH/LastThk/LastRadC`（2878-2887），几何没变则只重插 Z 序、不做 `SetWindowPos`；`_ApplyRegion` 也有自己的缓存（2909/2917）。也就是说"焦点变化"根本**不需要重建边框**，现在的全毁全建是完全没有必要的。

**坏消息**：`BorderFrame.SetColor()` 会重置渐变缓存并可能重建位图（2820-2822），焦点切换频繁时是额外开销 → 只对"状态真的变了"的两个窗口调用即可（现有 `_SetBorderColor` 已做 state 判重，OK）。

---

## 2. 我理解的你的方案（复述，确认没有跑偏）

1. **WTM 不重复造轮子**：进入模式 = 对当前桌面/显示器跑一次智能平铺（读 `[Tiling] Rules`，无规则则用内置算法）。
2. **移动 = 数学选择**：按你给的"主轴向取差最小 → 副轴向破平局 → 仍平局取负值"选择要交换的窗口。
3. **交换 = 只换这两个窗口的槽位**：其他窗口保持原槽位不变；交换后重新应用平铺逻辑（即"把窗口编号换一下再铺"）。
4. **边框必须复用现有成熟实现**（拖拽边框那套），一个窗口只能有一个边框，切换桌面/窗口关闭/退出模式都要清理干净，不能有残留、不能重复生成。
5. 我理解你的核心诉求是：**把"窗口在哪"从"屏幕上量出来的像素"变成"配置里算出来的分数"**，让所有操作建立在同一套精确、稳定、可预期的基础上。

---

## 3. 数学统一：槽位表（Slot Table）

### 3.1 定义

对某个显示器的 `n` 个窗口，定义一张**归一化槽位表**：

```
SlotTable[n] = [ { i, xlo, xhi, ylo, yhi,  cx, cy,  src } , ... ]   ; i = 1..n
  xlo/xhi/ylo/yhi ∈ [0,1] （相对显示器工作区，已扣除 BarReserve）
  cx = (xlo+xhi)/2,  cy = (ylo+yhi)/2      ← 代表值（中心）
  src = "custom" | "builtin"
```

槽位表有两个可能来源，**对下游完全同构**：

- **来源 A：用户规则**（优先）。直接由 `ParseAxis` 的 `lo/hi` 得到，是**精确有理数**。
- **来源 B：内置算法**（无规则时）。见 §3.3，通过"空跑"内置算法拿到归一化矩形。

### 3.2 代表值：为什么用「跨度中心」

你说"取这个坐标的中间值"，我把它统一成 **`(lo+hi)/2`，两个轴都用它**。用你的 7 窗口例子验算：

| i | 规则字段 | x 跨度 | y 跨度 | cx | cy |
|---|---|---|---|---|---|
| 1 | `2/3, 1` | 1/3 – 2/3 | 0 – 1 | **1/2** | **1/2** |
| 2 | `1/3, 1/3` | 0 – 1/3 | 0 – 1/3 | 1/6 | 1/6 |
| 3 | `1/3, 2/3` | 0 – 1/3 | 1/3 – 2/3 | 1/6 | 1/2 |
| 4 | `1/3, 3/3` | 0 – 1/3 | 2/3 – 1 | 1/6 | 5/6 |
| 5 | `3/3, 1/3` | 2/3 – 1 | 0 – 1/3 | 5/6 | 1/6 |
| 6 | `3/3, 2/3` | 2/3 – 1 | 1/3 – 2/3 | 5/6 | 1/2 |
| 7 | `3/3, 3/3` | 2/3 – 1 | 2/3 – 1 | 5/6 | 5/6 |

对照你画的 `|2|·|5| / |3|1|6| / |4|·|7|` —— **完全一致**。✅

**你的两个手算例子用中心值复算，结论都一模一样：**

- **窗口3 按右**：候选（cx > 1/6）= {1(1/2), 5(5/6), 6(5/6), 7(5/6)}；主轴向差 = {1/3, 2/3, 2/3, 2/3} → 唯一最小 → **窗口1** ✅（与你结论一致）
- **窗口1 按右**：候选 = {5,6,7}，主轴向差全为 1/3 → 平局；副轴向（y）差 = {5: -1/3, 6: **0**, 7: +1/3} → 取最小绝对值 → **窗口6** ✅

> 附带说明：你手算时把窗口1 的 `y=1` 换算成 `2/3` 再比，其实是想表达"取跨度中心"；`(0+1)/2 = 1/2`，与窗口6 的中心 `(1/3+2/3)/2 = 1/2` 差 **恰好为 0**，所以结论仍是窗口6。中心法更干净且不需要"把 1 折算成分母 3"这种临时约定。

### 3.3 内置算法怎么进同一张表

内置算法（`TileNormal/TileGrid/TileVertical/TileUltrawide`）目前**直接调 `PlaceWin` 搬窗口**，拿不到"它会摆成什么样"。

**方案 B1（推荐）：dry-run + 输出下沉（sink）**

把 `PlaceWin` 调用点改成调用一个可替换的输出函数：

```ahk
; 模块级：默认写窗口；dry-run 时替换成"记录矩形"
TileSink := PlaceWin          ; 默认行为完全不变
Emit(x, y, w, h) => TileSink(x, y, w, h)
```

`TileNormal/TileGrid/...` 内部把 `PlaceWin(...)` 换成 `Emit(...)`。然后：

```
BuildBuiltinTable(monIdx, n):
   TileSink := (x,y,w,h) => rects.Push({x,y,w,h})
   用一块“单位矩形”(0,0,W,H)、gap=0 空跑 TileNormal/TileVertical/TileUltrawide
   TileSink := PlaceWin          ; 立刻还原
   rects → 除以 (W,H) → (xlo,xhi) = (x/W, (x+w)/W) ...
```

- **零行为变化**（默认 sink 就是 `PlaceWin`），却让"没有自定义规则"的情况也有精确槽位表。
- dry-run 用**归一化单位矩形、gap=0**，因此得到的分数**不受 gap / DWM / 缩放 影响**，天然可比较。

**方案 B2（备选，更省事但精度低）**：在 `PlaceWin` 里顺手记录 `_LastRects[hwnd] = {x,y,w,h}`，平铺结束把实际矩形归一化。优点：绝对真实（含 gap 效果）；缺点：像素取整会让"本该相等"的两个值差 1px，破平局判据会抖 → 需要量化到 1/1000 或更粗。

**我推荐 B1**：判据要的是"分数相等"，就该用分数。B2 留作交叉验证。

### 3.4 缓存的槽位表

```
SlotTableCache := Map( monIdx . "|" . n  →  { table: [...], src: "custom"|"builtin", key: 规则文本 } )
```

- 配置重载（`Alt+R` → `LoadOrInitConfig`，2050 重解析 `Rules`）时清空缓存。
- `n` 变化（窗口开关）时才重算；**移动/交换不重算表**。

---

## 4. 移动算法（四方向统一）

### 4.1 目标选取

```
PickSwapSlot(i, dir):                    ; i = 当前窗口的槽位号
  T  = SlotTable(mon, n);  cur = T[i]
  (P, S) = (主轴向, 副轴向):
        L/R → P = cx, S = cy
        U/D → P = cy, S = cx

  ; ① 只取"方向正确"的槽位（严格不等式 → 同轴同值的窗口被排除）
  cand = { j ≠ i : dir∈{R,D} ? T[j].P > cur.P : T[j].P < cur.P }
  if cand = ∅ → return 0            ; 交给跨屏 fallback（§4.3）

  ; ② 主轴向差最小
  d1 = min |T[j].P - cur.P| over cand
  cand = { j ∈ cand : |T[j].P - cur.P| = d1 }
  if |cand| = 1 → return it

  ; ③ 副轴向破平局
  d2 = min |T[j].S - cur.S| over cand
  cand = { j ∈ cand : |T[j].S - cur.S| = d2 }
  if |cand| = 1 → return it

  ; ④ 仍平局 → 取副轴向差为负的那个（偏上 / 偏左）
  return { j ∈ cand : T[j].S - cur.S < 0 且该差值最接近 0 }
```

- **①的严格不等式**正是你例子里"窗口2、4 被排除"的原因（它们和窗口3 的 x 值相同）。副作用：**同一列上下相邻的两个窗口无法用 L/R 互推**——这是你的规则本身决定的，我按你的描述实现，见 §9-Q3。
- **④** 是你说的"如果有多个则取为负值并且差值最接近于0的一个"。当移动方向是 U/D 时，副轴向是 x，"负值"= 偏左。见 §9-Q3 需要你确认这个泛化。

### 4.2 用你的例子穷举验证（这是我理解是否正确的硬证据）

N=7 时，从各窗口出发的目标（按上表计算）：

| 起点 | 左 L | 右 R | 上 U | 下 D |
|---|---|---|---|---|
| **1** | 3 | 6 | 2 | 4 |
| **2** | — | 1 | — | 3 |
| **3** | — | **1** | 2 | 4 |
| **4** | — | 1 | 3 | — |
| **5** | 1 | — | — | 6 |
| **6** | 1 | — | 5 | 7 |
| **7** | 1 | — | 6 | — |

（"—" = 该方向没有候选槽位 → 触发跨屏移动）

对照你的描述：
- 窗口3 按右 → **窗口1** ✅（你的原例）
- 窗口1 按右 → 5/6/7 平局 → 副轴最小 → **窗口6** ✅（你的原例）
- 窗口5 按下 → **窗口6**（同列下一个）✅ 直觉正确
- 窗口3 按上 → 候选 {2, 5} 主轴向平局 → 副轴 x 差 {2: 0, 5: 2/3} → **窗口2**（同列上一个）✅
- 窗口3 按左 → 无候选 → 跨屏

**请重点核对此表**：如果这张表和你想的有一格不同，说明我对平局规则的理解有偏差，越早发现越好。

### 4.3 跨屏 fallback

保留现有 `_AdjacentMonitor`（5827）+ `_MoveWindowToMonitor`（5813），但把"挪到屏幕中心"改成"挪到目标屏的空闲槽位"：

```
跨屏 = 源屏槽位释放 + 压缩 → 目标屏 append/插入空闲槽位 → 两屏各自 re-place
```

### 4.4 交换的实现（关键：其他窗口不动）

```
SwapSlots(i, j):
  h1 := Owner[mon][i],  h2 := Owner[mon][j]
  Owner[mon][i] := h2,  Owner[mon][j] := h1
  Of[h1] := j,          Of[h2] := i
  RePlace(mon)        ; 只把这两个窗口 WinMove 到新槽位的矩形，其他窗口跳过
```

`RePlace` 里对每个槽位算矩形（槽位表 + gap + 边界），**只对"目标矩形 ≠ 当前矩形"的窗口调用 `PlaceWin`**。因为只有两个窗口的矩形变了，实际只有 2 次 `WinMove` → 这就是"其他窗口不变形、不位移"的技术保证。

---

## 5. 槽位模型的持久状态

```
WTMSlots := Map( desktop → Map( monIdx → {
      Owner : Map(slotIdx → hwnd),
      Of    : Map(hwnd → slotIdx)
} ) )
```

| 事件 | 动作 |
|---|---|
| 进入模式 | 用当前 z 序（或屏幕位置排序，§9-Q6）填充 `1..n`；`AutoTile()` |
| 窗口关闭 | 释放槽位 → **压缩**（后面槽位前移，保序）→ 重算 n → 取新 n 的表 → re-place 全部（§9-Q4） |
| 新窗口出现 | 追加到末尾 **或** 插入到焦点之后（§9-Q5） |
| 移出（Pin/Float，`TogglePinExclude`） | 释放槽位 + 压缩；该窗口 `Excluded` + 置顶 + PinBorder |
| 交换（MoveDir） | 只换两个槽位归属 → 只搬这两个窗口 |
| 跨屏移动 | 源屏释放+压缩，目标屏追加 |
| 切换桌面 | 先存 `WTMSlots[当前桌面]`（现有 `SaveOrderForDesktop` 的位置，3339）→ 切完恢复 + 清理失效窗口 + re-place |
| 退出模式 | 清状态、销毁所有边框、`AllBorders.Rebuild()`（保持现有 5558 的行为） |

**注意一个固有约束**（必须提前讲清楚）：规则是**按窗口数量 N 分组**定义的。窗口数量从 7 变成 6 时，会切到 N=6 的规则组（若没定义则回落内置算法），此时**位置必然整体变化**。这不是 bug，是规则体系的设计。你的规则文件里定义了 N=1,2,3,7，所以 4/5/6 窗口时走内置算法。见 §9-Q9 有可选缓解方案。

---

## 6. 边框管理：单一所有者 + diff 同步

### 6.1 现状为什么"卡住 / 没消除 / 重复生成"

| # | 位置 | 问题 |
|---|---|---|
| 1 | 6019-6044 `RefreshBorder` | 签名含**焦点 hwnd** → 每次焦点变化都 `DestroyAllBorders()` + 全量重建 → 视觉闪烁、GUI 反复创建销毁 |
| 2 | 5979-6005 `DestroyAllBorders` | `DestroyWindow` + **20 轮 `IsWindow` 验证循环 + `Sleep(2)`**；被上一行高频触发 |
| 3 | 5678-5703 `Tick` | 10ms 一次 `_Signature()`：枚举所有窗口 + **O(n²) 冒泡排序**；`GetKeyState("Alt")` 为真时**整段跳过**（含边框刷新） |
| 4 | 5659 | 几何量化到 **32px** → 小幅移动不触发重铺（窗口停在错位），大动作立刻全量重铺（打断用户） |
| 5 | 5538-5539 / 6038 | `Activate` 里 `BorderMap := Map()` 直接丢弃旧 map，**没有销毁对应的 GUI** → 旧边框可能成为孤儿窗口（"没消除"） |
| 6 | 5970 | 只 `DestroyWindow` 不 `ShowWindow(0)`，销毁失败的窗口会留在屏幕上 |
| 7 | 6058-6065 | `PinBorder.Map.Has(hwnd) || AlwaysVisible.Has(hwnd)` 时 `RemoveBorder` → 但 `PinBorder` 自己有定时器也在管同一个窗口，**两个所有者可能同时给一个窗口画边框**（"重复生成"） |

### 6.2 新设计：`SyncBorders(targetSet)`

**保留 `BorderFrame` 原封不动**（它的 `Place` 已有几何缓存、Z 序重插、圆角 Region 缓存）。只改 WTM 的**生命周期管理**：

```
SyncBorders(mon):
  want := { 该显示器所有已入槽且可平铺的窗口 }
  ; ① 多余的 → 销毁（唯一销毁点）
  for hwnd in this.BorderMap.Clone():
      if !want.Has(hwnd) or !WinExist(hwnd): DestroyFrame(hwnd)
  ; ② 缺失的 → 创建
  for hwnd in want: EnsureBorder(hwnd)
  ; ③ 状态与几何
  for hwnd in want:
      _SetBorderColor(hwnd, focus ? "focus" : "unfocus")   ; 内部已判重，不变则不碰
      _BorderPlaceFrame(BorderMap, hwnd)                   ; 内部几何缓存，不变则只重插 Z 序
```

**幂等 + 有序**：任何时刻 `BorderMap` 的键集合 = 应该有条框的窗口集合，不多不少。

**销毁时机表（收敛成一张表，只有这些地方会销毁边框）**：

| 时机 | 动作 |
|---|---|
| 退出 WTM（`Deactivate` 5551） | 全销毁 → `AllBorders.Rebuild()` |
| 切换桌面（`SwitchDesktop` 3337-3341） | **在 `HideWin` 之前**全销毁（现有顺序是对的，保留） |
| 窗口关闭 | 单销毁 |
| 窗口进入 `Excluded`/Pin | 单销毁（交给 PinBorder） |
| 窗口最小化 | `Hide()`（不销毁，恢复时 `Place` 会自动重新定位，`Hide` 已重置 `LastPX`，2945） |
| 窗口消失/失效 | 单销毁 |
| 配置重载 / 脚本退出 | 全销毁（需核对 `DestroyTransientGuis`（2280）是否覆盖 BorderFrame 的 GUI → 待办核对项） |

**性能**：焦点切换 = 2 次 `SetColor` + 2 次 `Place`（其中一次走"几何未变只重插 Z 序"分支）→ 无闪烁、无窗口重建。10ms 定时器保留用于**跟手**（拖拽/移动中的边框跟随），但**几何签名检查降频**（见 §7）。

### 6.3 四个边框所有者的互斥规则（写死，避免抢画）

```
WTM.Active      ⇒ AllBorders.Suspend()      （已存在，5546）
拖拽进行中       ⇒ DragBorder 独占焦点窗口的边框；WTM 对该窗口 Hide 边框，拖拽结束 SyncBorders 恢复
PinBorder       ⇒ 与其管理的窗口互斥：WTM 永不为其 PinBorder.Map.Has(hwnd) 的窗口建边框（已存在，6032）
```

---

## 7. 事件驱动替代"定时全量重铺"

现状是"10ms 检测到任何几何变化就重铺"——这是"窗口位移/变形"的直接成因（用户拖动、程序自己调整大小、甚至 `WinMove` 的取整，都会把全部窗口重新摆一次）。

**改成两级**：

| 级别 | 频率 | 检查内容 | 触发动作 |
|---|---|---|---|
| 轻量轮询 | 250–300ms | 只比 **hwnd 集合**（有无新窗口/关闭/最小化），不算几何、不排序 | 槽位增删 + `SyncBorders` |
| 显式事件 | 即时 | 进入模式 / MoveDir / Pin 切换 / 桌面切换 / 拖拽结束 / 窗口关闭（`CloseWindowDispatch` 1418 已挂） | 局部 re-place 或全量 `AutoTile` |

**与用户手动拖拽的关系**（必须明确，§9-Q7）：WTM 激活时 `DragMoveHandler`（5318）结束会调 `WTM.OnWindowChanged()`（5372），也就是**拖完会被拉回槽位**。三种可选语义：
- (a) snap-back（现行为，hyprland 风格）；
- (b) **拖拽交换**：松手时找最近的槽位中心，与之交换槽位（更接近"拖动改变布局"的直觉）；
- (c) 拖出即浮动（`Excluded`）。

---

## 8. 与既有功能的正交性核对表

| 功能 | 影响 | 处理 |
|---|---|---|
| 状态栏占位 | `BarReserve`（4615）已在 `TileWindowsOnMonitor` 内 | 槽位表以"工作区"为基准 → 天然一致 |
| DWM 阴影补偿 | WTM 传 `useDwmComp := false`（5641） | dry-run 用 gap=0 单位矩形 → 与补偿无关，保持 false |
| gap 来源分叉 | WTM 用 `Border_Gap`，TileSmart 用 `Tile_Gap` | §9-Q1 需你定 |
| 全屏/最大化 | `RebuildOrder`（5599）只跳过最小化；`HasFullscreenWindow`（4720）目前只服务状态栏 | 需要给 WTM 加"全屏窗口时暂停平铺/隐藏边框" → §9-Q8 |
| 排除规则 | `IsExcludedWindow`（789）/ `GetVisibleWindow`（5110） | 槽位表只对"可平铺窗口"生效，逻辑与现在一致 |
| `AlwaysVisible` 窗口 | 跨桌面常驻 | 不占槽位、不画边框（现有 6032 行为保留） |
| 置顶窗口 | `Tile_IncludeAlwaysOnTop` 默认 off → 置顶窗口不进平铺 | 保留；`IsTilableWindow`（5084）不改 |
| WinSelect 平铺 | 6345 也消费同一套 `Rules` | 新模型**只读**表，不改 `TileWindowsOnMonitor` 的默认行为（sink 默认仍是 `PlaceWin`） |
| 多显示器 + 不同分辨率 | 槽位按显示器索引；规则 `M` 字段已支持 | 表按 `(monIdx, n)` 缓存 |
| 虚拟桌面 hide 模式 | `ShowWindow(0)` 隐藏窗口 | 切桌前先销毁边框（已做，3337-3341） |
| 脚本重载 | `SaveLayoutStateForReload`（1106） | 需把 `WTMSlots` 一并序列化（现在是保存 `TileOrder`） |
| 日志 | `WMLog/WMGuard`（653/714） | 新增路径都包 `WMGuard`，便于你贴日志排错 |

---

## 9. 需要你拍板的决策点

| # | 问题 | 我的倾向 |
|---|---|---|
| **Q1** | WTM 的间隙用哪个配置？现状是 `[Border] Gap`（10），而示例配置写在 `[Tiling] Gap`（0） | 建议 WTM 改用 `[Tiling] Gap`（与"复用智能平铺"一致），或在 `[Tiling]` 新增 `WTMGap=` 显式区分 |
| **Q2** | 无自定义规则的窗口数量（如 4/5/6）时，允许移动吗？ | 允许：用内置算法 dry-run 出来的槽位表 |
| **Q3** | 破平局第 ④ 步"取负值"如何泛化到四方向？我按"永远取**屏幕坐标系负方向**（左/上）"。你的原例只覆盖了 y 轴 | 需要你确认；另一种理解是"永远取 偏上/偏左 之外的反向"（即 U/L 时取正），差别很大 |
| **Q4** | 关闭窗口后是否**压缩槽位**（后续窗口前移，位置会变一次）？ | 压缩（保序）。若不压缩，槽位空洞会让 n 与规则组不符 |
| **Q5** | 新窗口插入到**末尾**还是**焦点之后**？ | 焦点之后（更符合平铺 WM 直觉），末尾更简单 |
| **Q6** | 进入 WTM 时初始槽位顺序按 z 序还是屏幕位置（左→右、上→下）？ | 屏幕位置排序更符合"我看到什么就是什么" |
| **Q7** | WTM 中手动拖拽的语义：snap-back / 拖拽交换 / 拖出浮动？ | **拖拽交换**（最贴合"移动=数学交换"的整体设计） |
| **Q8** | WTM 中最大化/全屏窗口怎么处理？ | 有全屏窗口时暂停该屏平铺 + 隐藏该屏边框；最大化窗口参与平铺（现状） |
| **Q9** | `1/2-`、`1/2+` 这类 `align` 后缀在平铺规则里目前**完全无效**——是修正文档，还是实现它？ | 修正文档（保留解析），避免行为突然变化 |
| **Q10** | 是否允许"最近 N"回落（如没有 N=6 规则，用 N=7 的前 6 个槽位）？ | 不做，保持严格；失败时 OSD 提示"该窗口数无规则，已用内置布局" |

---

## 10. 实施步骤（每阶段可独立验证、可回退）

> 前置：`AHK_WM` 是 git 仓库且当前 `main` 干净 → 建分支 `wtm-redesign`，每阶段一个 commit。全局规范要求改动前可回退，这一步就是回退点。

| 阶段 | 内容 | 验证方式 |
|---|---|---|
| **0** | 分支 + 备份；只加日志，不改行为 | `Alt+R` 重载无报错，日志无 ERROR |
| **1** | `Emit` sink 改造 + `BuildSlotTable` + `SlotTableCache`；加一个调试热键把表打到日志 | 热键输出的 7 窗口表 = §3.2 的表；TileSmart/WinSelect 行为**完全不变**（回归对比） |
| **2** | 槽位模型替换 `TileOrder`（先不动目标选择算法，保持旧行为） | 交换后**其他窗口零位移**（用日志比对前后矩形） |
| **3** | `PickSwapSlot` 上线，替换 `_PickSwapTarget` | 逐格核对 §4.2 的穷举表 |
| **4** | 边框 diff 同步 + 去掉焦点触发的全毁全建 + 签名检查降频 | 连续切焦点 100 次：无闪烁、无残影；`Alt+Tab` 狂按后统计边框 GUI 数量 == 窗口数 |
| **5** | 边界：跨屏 / 桌面切换 / 关闭 / 新增 / Pin-Float / 最小化恢复 / 全屏 | 手写 20 条边界 case 逐条过 |
| **6** | 文档（README-zh/En + config-reference）、CHANGELOG、Obsidian 笔记 | — |

**每阶段验收硬指标**：① `Alt+R` 重载无错；② 退出 WTM 后**剩余边框数量 = 0**（用 AHK 自身枚举 + `IsWindow` 统计）；③ 窗口数 n 下 `WinGetPos` 与槽位表预测值的误差 ≤ 1px。

---

## 11. 风险与遗留

1. ~~**`Alt` 按住即停刷新**（5682）：你的快捷键是 `Alt+HJKL`，按住 Alt 期间 `Tick` 整段跳过 → 边框不跟手。~~ **已解决**：新 `Tick` 不再对 Alt 设门（快速档照跑，只把"重铺管控"降频），见 §13.2。
2. **`PlaceWin` 里 `WinRestore`**（4975）：对最大化窗口会先还原再移动 → 全屏窗口行为需按 Q8 处理。
3. **`WinMove` 阻塞**：窗口无响应时 `WinMove` 卡住（`SetWinDelay(0)` 已设，但仍可能）；需要给 re-place 加"目标矩形与当前矩形相同则跳过"（正好也是性能优化）。
4. **孤儿边框**：`Activate` 丢弃旧 map 不销毁 GUI（5538-5539）→ 必须先销毁再清空（这是"边框没消除"的可疑原因之一）。
5. **`DestroyTransientGuis`（2280）**是否覆盖 `BorderFrame` 的 GUI → 待核对，决定 `Alt+R` 重载后是否残留。
6. 槽位模型只在**同一显示器内**交换；跨屏语义（源屏压缩、目标屏插入）需按 Q4/Q5 一致化。
7. 无自动化测试（AHK 项目现状），靠"调试热键 + 日志"做半自动回归；阶段 1-3 可以写一个纯计算的**自检函数**（构造 1..9 个假槽位表，跑一遍验证不变量：交换后集合相等、pick 不自选、方向单调），这是唯一能便宜拿到的回归保障。

---

## 12. 我下一步会做什么（等你确认后）

1. 你先核对 §4.2 的穷举表（这是全部数学的验收样本）+ 回答 §9 的 Q1/Q3/Q4/Q7（其余我可以按倾向先做，后续容易改）。
2. 我从**阶段 1** 开始写代码（`Emit` sink + 槽位表 + 调试热键），改完立即给你一个可验证的中间态，而不是一次性大改。
3. 全程不碰 `TileWindowsOnMonitor` 的默认行为，确保 TileSmart / WinSelect 零回归。

---

## 13. 实施记录（2026-09-29，v2.11.0）

六阶段全部落地，`wm.ahk` 语法校验通过（`bash tools/validate.sh wm.ahk` → `OK`）。
按你的要求：**没有动任何现有配置值**，只在 `[Tiling]` 末尾新增两行；备份 `wm_config.ini.bak-20260929`。

### 13.1 落地的改动（按代码位置）

| 位置 | 改动 |
|---|---|
| `ComputeTileRect` / `MoveWinTo` / `PlaceWin` / `EmitPlace`（5120+） | 把"算矩形"与"搬窗口"拆开：`EmitPlace` 是内置平铺算法的唯一出口，`TileSink` 非 0 时只收集不搬窗口（默认 0 → 行为与旧版完全一致，TileSmart / WinSelect 零改动） |
| `SlotFromSpan` / `BuildBuiltinSlotTable` / `GetSlotTable`（4929+） | 槽位表：归一化分数跨度 + 内置算法"空跑"（`TileSink` 收集后按 W/H 归一化，全程不碰窗口）+ 按 `(mon,n,W,H)` 缓存 |
| `PickSlotFromTable` / `NarrowByAxis`（4998+） | 方向选择的纯函数实现（五步规则，含满轴拦截）——可脱离窗口独立测试 |
| `GetTileArea`（4910） | 与 `TileWindowsOnMonitor` 内部几何完全同口径（工作区 − Bar − 边缘间隙），保证 dry-run 与真实摆放算出同一张表 |
| 配置解析（2066） | `[Tiling] WTMGap`（缺省 = `Border_Gap`）、`[Tiling] AnimationDuration`（缺省 0 = 关闭动画），解析后 `InvalidateSlotTables()` |
| `class WTM`（5715+） | 见 §13.2 |

### 13.2 WTM 的行为

- **进模式**：`Activate` → 先销毁遗留边框（含孤儿 GUI）→ `RebuildOrder`（按屏幕位置/焦点插入新窗口）→ `AutoTile` → `RefreshBorder` → 写槽位表日志。
- **平铺**：`_RePlace(mon)` 借唯一入口 `TileWindowsOnMonitor(wins, mon, WTM_Gap, false)` 算矩形，输出接到收集器上，再按需动画或直搬。**WTM 自己不实现任何布局**。
- **交换**：`MoveDir` 只对调 `TileOrder` 里两个槽位，其余窗口矩形不变。
- **边框**：`RefreshBorder` 是唯一"销毁多余边框"的入口，逐窗口 diff（缺则建、多则毁、几何/颜色按需更新），一窗恒一边框。
- **全屏/最大化**：真全屏 → 该屏不铺不画边框；最大化 → 单人模式（隐藏同屏其它窗口，只让这一个参与平铺），退出即复原。
- **轮询**：快速档每 `Border_RefreshMs`（边框跟随 + 焦点，**不再因按住 Alt 而跳过**）；慢速档约 250ms（成员变化 / 外部漂移 / 全屏判定），累加用真实时间。

### 13.3 数学验证（`tools/mk_testslots.sh`，36 项断言全过）

从 `wm.ahk` **原样抽取** `ParseAxis` / `ParseLayoutRules` / `SlotFromSpan` / `PickSlotFromTable` / `NarrowByAxis` / `BuildBuiltinSlotTable` 等，独立运行、不移动任何窗口：

```
生成: bash tools/mk_testslots.sh
运行: powershell Start-Process ...\AutoHotkey64.exe tools\test_slots.ahk
输出: tools/test_slots.out.txt        (exit 0 = 全部通过)
```

你给的 7 窗口规则（`|2|·|5| / |3|1|6| / |4|·|7|`）四方向结果：

| 窗口 | 位置 | L | R | U | D |
|---|---|---|---|---|---|
| 1 | 中间 | 3 | 6 | — | — |
| 2 | 左上 | — | 1 | — | 3 |
| 3 | 左中 | — | 1 | 2 | 4 |
| 4 | 左下 | — | 1 | 3 | — |
| 5 | 右上 | 1 | — | — | 6 |
| 6 | 右中 | 1 | — | 5 | 7 |
| 7 | 右下 | 1 | — | 6 | — |

（`—` = 本屏无目标 → 走跨屏分支）

- 你手算的两个例子都对：窗口3→右 = 窗口1；窗口1→右 = 窗口6。
- 你在 `回答.md` 里的修正也在里面：窗口1 的 y 跨度为满 → **U/D 为 `—`**（横向仍可动）。
- 内置算法 dry-run：n=2..6 横屏、n=4 竖屏、n=3 超宽，四方向结果全部合法且不自选。
- `(2-3)/3` = 1/3..1.0（`-` 是"到"，不是减）；`1/-2` = 后半轴且 `align=Left`（后缀不参与几何）。

### 13.4 实测前你必须做的一步

你的 `wm_config.ini` 里 **[Hotkeys] `WTMToggle=` 是空的** → `RegHotkey` 直接跳过，等于没有进入 WTM 的快捷键（默认值是 `Alt+Shift+D`）。我没有改你的既有配置，请自己补上，例如：

```ini
WTMToggle=Alt+Shift+D
```

然后 `Alt+R` 重载。快速验收：

1. 进 WTM → 每块屏按 `Rules` 铺开，边框一窗一个；
2. `Alt+Shift+H/J/K/L` 交换 → 只有两个窗口动，其余像素不动；
3. 狂按 `Alt+Tab` / 切焦点 → 边框不闪、不残留（§10 的"边框 GUI 数 == 窗口数"）；
4. 拖一个窗口到另一块屏 → 原屏补位，不留空洞；
5. `Alt+F` 最大化 / 真全屏 → 该屏暂停平铺；退出 WTM → 残留边框数为 0。

想要动画：把 `[Tiling] AnimationDuration=0` 改成 `120`（毫秒）即可，建议 120–180。

### 13.5 顺带修掉的其它问题（详见 CHANGELOG v2.11.0）

1. **慢速档按标称周期累加**：`Border_RefreshMs` 配 0 会被钳到 1ms，而 AHK 定时器实际约 15.6ms → 250ms/200ms 的"慢速档"会慢十几倍。改为 `TickElapsed()` 用 `A_TickCount` 算真实间隔，`WTM` 与 `AllBorders` 均已修正（你的配置里 `[Border] RefreshMs=0`，正好踩中）。
2. **浮动窗口被搬走**：焦点在浮动/被排除窗口上时按 `Alt+Shift+H/J/K/L` 会把该窗口搬到相邻显示器。现在焦点不在槽位表里就不动作。
3. **跨屏拖拽留空洞**：`_CheckDrift` 现在同时重铺"原显示器"。
4. **重载后窗口永久隐藏**：单人模式用 `SW_HIDE`，脚本重载后状态丢失、窗口再也回不来。现在 `OnExit` 里 `WTM.CleanupOnExit()` 复原。

### 13.6 回退

- 代码：`git checkout wtm-redesign -- wm.ahk`（本分支未提交前的版本），或 `git checkout main -- wm.ahk`；
- 配置：`copy wm_config.ini.bak-20260929 wm_config.ini`（只有 2 行差异）。

### 13.7 仍需你实测确认的项

`§10` 的硬指标只能在你的机器上跑：重载无错、退出后残留边框为 0、`WinGetPos` 与槽位表预测误差 ≤ 1px；以及跨屏交换的期望语义（源屏压缩 vs 目标屏插入）、浮动窗口在 WTM 下的期望行为——这两条我按"严格、不猜"实现，你实测后若想改，都是局部改动。
