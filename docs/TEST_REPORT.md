# 《星骸回响》Star Echo · 测试报告（TEST_REPORT）

> 负责人：**w5-qa**（并发团队 starecho-sprint，验证单点归口）
> 执行日期：2026-08-04
> 基线版本：`git HEAD = 343c78a`（docs: 交接简报同步至最新工程状态）
> 项目路径：`D:\Program Files\30DAYS` · 引擎 `tools/Godot_v4.3-stable_win64.exe`（Godot **4.3.stable.official.77dcf97d8**）
> 执行器：`C:\Users\Administrator\.workbuddy\binaries\python\versions\3.13.12\python.exe`
> 范围：无头基线自校验 · 全量 JSON 可解析性 · 数据交叉引用 · 新增美术资产规格抽检
> **本报告全程只读验证，未修改任何游戏代码 / 数据 / 美术；唯一写入文件为本文件。**

---

## 〇、执行摘要（TL;DR）

**baseline：✅ PASS —— 两次执行均输出 `BASELINE CLEAN`。无 import 错误、无运行时错误、无 JSON 解析失败。当前工程可提交。**

但基线「绿」不等于内容已就绪 —— 静态交叉检查发现 **1 个真实悬空引用** 与 **1 组美术未接线的命名错位**，二者都在 baseline 的盲区内（未被现有场景/脚本引用，故无头运行不会报错），但会在 **Day 2「角色选择 + 3 英雄」** 落地时立刻暴露。详见第五节。

| 检查项 | T1（并发写入前） | T2（并发写入后） |
|---|---|---|
| `baseline_check.py` | ✅ **BASELINE CLEAN** | ✅ **BASELINE CLEAN** |
| 深度运行探测（600 帧） | ✅ CLEAN | ✅ CLEAN |
| `data/*.json` 可解析 | ✅ 7/7 | ✅ **8/8**（新增 `events.json`） |
| ID 唯一性 / 悬空引用 | ✅ 无重复 ID | ⚠️ 1 处悬空（`shuriken`，**存量**） |
| 新增美术规格 | — | ✅ 帧 strip 合约达标（但未接线） |

---

## 一、baseline_check 执行结果（完整输出）

命令（项目根执行）：

```
C:\Users\Administrator\.workbuddy\binaries\python\versions\3.13.12\python.exe tools/baseline_check.py
```

### T1 · 并发写入前（工作区无游戏代码改动）

```
[import] --quit
[import] PASS - exit 0, stderr clean
[runtime] --quit-after 4
[runtime] PASS - exit 0, stderr clean

BASELINE CLEAN - safe to commit.
```

退出码 `0`。

### T2 · 并发写入后（w2 已写入 3 份 JSON + `events.json`，w3 已落 9 张 PNG）

```
[import] --quit
[import] PASS - exit 0, stderr clean
[runtime] --quit-after 4
[runtime] PASS - exit 0, stderr clean

BASELINE CLEAN - safe to commit.
```

退出码 `0`。**队友本轮产出未破坏基线。**

### 日志落盘校验（确认引擎确被拉起，排除「空跑假通过」）

| 日志文件 | 大小 | 内容 |
|---|---|---|
| `tools/baseline_import_out.log` | 73 B | Godot Engine v4.3.stable.official.77dcf97d8 横幅 |
| `tools/baseline_import_err.log` | **0 B** | 无 stderr |
| `tools/baseline_runtime_out.log` | 73 B | Godot 横幅 |
| `tools/baseline_runtime_err.log` | **0 B** | 无 stderr |

两个 `*_err.log` 均为 **0 字节** —— 无脚本解析错误、无 autoload 初始化错误、无运行时报错。

### 追加：深度运行探测（w5 自建，输出走内存管道，未向项目写入日志）

`baseline_check.py:86` 的 runtime 阶段用 `--quit-after 4`。**Godot 4 中 `--quit-after N` 的单位是「迭代/帧」而非「秒」**（同文件 `:85` 注释写作 "Run the main scene for 4s"，注释与实际语义不符）。4 帧 ≈ 0.07 秒游戏时间，仅能覆盖 `_ready` 与首帧。为排除浅层假阴性，追加 **600 帧（≈10 秒游戏时间）** 探测：

```
[import(--quit)]     exit=0 wall=0.71s stderr_lines=0 -> PASS
[runtime(600 iters)] exit=0 wall=4.80s stderr_lines=0 -> PASS

DEEP RESULT: CLEAN
```

T2 复跑同样 CLEAN（wall 0.76s / 4.80s）。**结论：PASS 判定可信，非浅层通过。**

---

## 二、JSON 可解析性校验

方法：Python 遍历 `data/*.json` 逐个 `json.load()`。以下为 **T2（最新状态）** 结果。

| 文件 | 解析 | 顶层键（条目数） | 体积 | 变化 |
|---|---|---|---|---|
| `data/characters.json` | ✅ OK | `characters`(**9**) | 6453 B | ⬆ 6→9（+3 英雄） |
| `data/elements.json` | ✅ OK | `elemental_status`(5) / `element_reactions`(10) / `reaction_rules`(4) | 3400 B | — |
| `data/enemies.json` | ✅ OK | `enemies`(3 档) / `scaling`(5) | 4558 B | — |
| `data/events.json` | ✅ OK | `events`(**10**) | 8791 B | 🆕 新增 |
| `data/items.json` | ✅ OK | `items`(**47**) | 8730 B | ⬆ 45→47 |
| `data/stats.json` | ✅ OK | `stats`(3) / `formulas`(15) / `leveling`(3) | 4135 B | — |
| `data/waves.json` | ✅ OK | `waves`(20) / `generation`(3) / `rewards`(3) | 6123 B | — |
| `data/weapons.json` | ✅ OK | `weapons`(4 类 / **32 叶子**) | 16557 B | ⬆ 29→32 叶子 |

```
TOTAL=8  OK=8  FAIL=0
```

**无任何 JSONDecodeError / 编码异常 / 文件截断。**（并发写入期间未捕获到半截 JSON —— 说明队友是原子性覆盖写。）

### 2.1 条目口径澄清（避免误读为「数据丢失」）

`enemies` / `weapons` 顶层键少（3 / 4）是**分组嵌套**结构，叶子条目数与文档口径一致：

| 数据 | 分组明细 | 叶子数 | 文档口径 | 结论 |
|---|---|---|---|---|
| weapons | melee 8 / ranged 8 / elemental 9 / engineering 7 | **32** | 29 | ✅ 29 + 3 把 SE 签名武器 |
| enemies | regular 15 / elite 6 / boss 2 | **23** | 23 | ✅ 一致 |
| characters | 扁平数组 | **9** | 6 | ✅ 6 + 3 英雄 |
| waves | 扁平数组 | **20** | 20 | ✅ 一致 |
| items | 扁平数组 | **47** | 39 | ⚠️ 文档偏旧（见 5.4） |

---

## 三、数据交叉引用完整性（w5 追加只读检查）

- **ID 唯一性**：characters / weapons / items / enemies 四类均**无重复 ID**（含新增 3 英雄与 3 武器，未与存量撞 ID）。
- **waves → enemies**：`waves.json` 引用的敌人 ID **全部命中** `enemies.json`，无悬空。
- **characters → weapons**：9 个角色的 `starting_weapon` 中 **8 个解析成功，1 个悬空**（见 5.1）。

```
  well_rounded  starting_weapon -> pistol           OK
  brawler       starting_weapon -> fist             OK
  ranger        starting_weapon -> slingshot        OK
  mage          starting_weapon -> wand             OK
  engineer      starting_weapon -> turret           OK
  gambler       starting_weapon -> shuriken         *** MISSING ***
  se_irene      starting_weapon -> se_star_flame    OK
  se_noa        starting_weapon -> se_auto_turret   OK
  se_ren        starting_weapon -> se_star_blade    OK
```

> 说明：`brawler.weapon_restrictions=["no_ranged"]` / `ranger.weapon_restrictions=["no_melee"]` 曾被我的启发式规则误报为悬空武器 ID，经核实是**限制标签而非武器 ID**，已排除，**非缺陷**。

新增 3 英雄的签名武器链路完整：`se_irene→se_star_flame`（炎星术）、`se_noa→se_auto_turret`（自动炮台）、`se_ren→se_star_blade`（星刃），与 `docs/TASKS.md` Day 2 要求一致。

---

## 四、新增美术资产规格抽检（w3 产出，只读）

对照 `docs/ART_STYLE.md` 帧 strip 硬契约（横向排列、帧宽 = 精灵尺寸）与 32px / Indexed 32 色规范：

| 文件 | 尺寸 | 模式 | 色数 | 帧 strip 判定 | `.import` |
|---|---|---|---|---|---|
| `elin_idle.png` | 128×32 | P(索引) | 8 | ✅ 4 帧 @32px | ❌ 无 |
| `elin_walk.png` | 192×32 | P | 8 | ✅ 6 帧 @32px | ❌ 无 |
| `elin_portrait.png` | 64×64 | P | 8 | ✅ 立绘 1 帧 @64px | ❌ 无 |
| `noah_idle.png` | 128×32 | P | 8 | ✅ 4 帧 @32px | ❌ 无 |
| `noah_walk.png` | 192×32 | P | 8 | ✅ 6 帧 @32px | ❌ 无 |
| `noah_portrait.png` | 64×64 | P | 8 | ✅ 立绘 1 帧 @64px | ❌ 无 |
| `lain_idle.png` | 128×32 | P | 9 | ✅ 4 帧 @32px | ❌ 无 |
| `lain_walk.png` | 192×32 | P | 9 | ✅ 6 帧 @32px | ❌ 无 |
| `lain_portrait.png` | 64×64 | P | 9 | ✅ 立绘 1 帧 @64px | ❌ 无 |
| `fighter_idle.png`（存量） | 128×32 | RGBA | 9 | ✅ 4 帧 @32px | ✅ 有 |

**规格结论：9 张新图全部满足帧 strip 硬契约（宽 = 帧数 × 32）与 ≤32 色索引色板要求，尺寸与存量 `fighter_*` 完全对齐。美术规格本身合格。**
（新图为 Indexed `P` 模式、存量为 `RGBA`；`P` 更贴合 ART_STYLE 的 Indexed 32 色约定，此差异不构成缺陷，仅记录。）

---

## 五、发现项汇总

### 5.1 ⚠️【真实缺陷 · Day 2 阻断风险 · 存量】`gambler.starting_weapon = "shuriken"` 悬空

`data/characters.json` 中角色「赌徒 gambler」的 `starting_weapon` 指向 **`shuriken`**，但 `data/weapons.json` 全部 **32** 个武器叶子 ID 中**不存在** `shuriken`：

```
melee       : chainsaw dagger fist flaming_knuckles hammer stick sword se_star_blade
ranged      : crossbow minigun pistol shotgun slingshot smg sniper rocket_launcher
elemental   : flamethrower force_field frost_nova icicle lightning_shiv storm_staff
              venom_staff wand se_star_flame
engineering : landmine laser_turret mech_arm plasma_cannon turret wrench se_auto_turret
```

- **性质**：**存量问题**，非本轮并发引入（`gambler` 属框架期角色）。
- **为何 baseline 没抓到**：全局检索 `scripts/*.gd` 与 `scenes/*.tscn`，**当前无任何代码引用 `shuriken` 或读取 `starting_weapon`** —— 角色选择尚未实现，该字段还没有消费方，故无头运行不触发。
- **何时爆炸**：**Day 2「角色选择 + 绑定初始武器」**。一旦选择界面把 `gambler` 列为可选（其 `unlock_condition` 为「默认解锁」），按 `starting_weapon` 取武器时将拿到 null，轻则无武器裸奔，重则空引用崩溃。
- **建议处置（交集成节点 / w2-data，w5 不改数据）**：二选一 —— ① 在 `weapons.json` 补一条 `shuriken`（飞镖，归 `ranged`）；② 将 `gambler.starting_weapon` 改指向已存在武器（如 `dagger`）。

### 5.2 ⚠️【集成风险】英雄 ID 与精灵文件名错位，且 `characters.json` 无精灵路径字段

| 角色 ID（w2 数据） | 中文名 | 精灵文件名（w3 美术） |
|---|---|---|
| `se_irene` | 炎术师·艾琳 | `elin_idle/walk/portrait.png` |
| `se_noa` | （诺亚） | `noah_idle/walk/portrait.png` |
| `se_ren` | （莱恩） | `lain_idle/walk/portrait.png` |

两侧命名各行其是：`se_irene` ↔ `elin`、`se_noa` ↔ `noah`、`se_ren` ↔ `lain`。同时 **`characters.json` 的角色条目里完全没有 `sprite` / `texture` / 资源路径字段**（已递归遍历确认，无任何 `.png` 或 `res://` 字符串）。

- **后果**：若 Day 2 的加载逻辑按「约定路径」拼接（如 `res://assets/sprites/characters/{id}_idle.png` → `se_irene_idle.png`），**三个英雄的精灵将全部加载失败**。
- **旁证**：9 张新 PNG **均无 `.import` 伴生文件**，且两次无头导入后仍未生成 —— 说明它们**尚未被任何场景/脚本引用**，Godot 未对其建立导入记录。美术资产目前处于「已落盘、未接线」状态，baseline 覆盖不到。
- **建议**：由 w1-code / w2-data / w3-art 三方在 Day 2 集成时对齐同一套命名，二选一 —— ① 在 `characters.json` 显式增加 `sprite_idle` / `sprite_walk` / `portrait` 路径字段（推荐，最贴合「数据驱动、零代码改动」约定）；② 统一把文件重命名为 `se_irene_*` / `se_noa_*` / `se_ren_*`。

### 5.3 ℹ️【结构提示 · 给 w1-code】`characters.json` 顶层是**数组**不是字典

`data["characters"]` 为 **list of dict**（每条含 `id` 键），而 `data["weapons"]` / `data["enemies"]` 是 **dict 分组嵌套**。两类结构不同，`DataLoader` 按 id 建缓存时需分别处理，勿套用同一套遍历。
（w5 自建校验脚本首版即因假设为 dict 而静默跳过了全部角色引用检查，修正后才暴露 5.1 的 `shuriken` 悬空 —— 此坑同样会绊到取数代码，特此提示。）

### 5.4 ℹ️【非阻断 · 文档漂移】items 计数

`docs/PROJECT_BRIEF.md:64` 与 `docs/30DAY_PLAN.md:7` 记为 `items(39)`，实际已为 **47** 条；同处 `characters(6)` 亦应为 **9**、`weapons(29)` 应为 **32**。数据健康，纯属文档计数未同步，建议由文档归口方顺手校正。

### 5.5 ℹ️【方法学建议】baseline runtime 阶段覆盖过浅

`tools/baseline_check.py:86` 的 `--quit-after 4` 为 **4 帧**（≈0.07s），仅覆盖 `_ready` 与首帧。Day 3+ 引入技能冷却、波次推进、召唤物生命周期后，极易漏掉定时器 / 状态机类运行时报错。
**建议**（交集成节点，**w5 不改代码**）：runtime 阶段提升至 `--quit-after 300~600`，实测成本仅 **+4 秒**（600 帧 wall 4.80s），性价比极高；并同步修正 `:85` 的 "4s" 注释。

---

## 六、并发编辑风险提示

> ⚠️ **多 Agent 并发写入同一工程时，「基线 PASS」具有强时效性 —— 它只对执行那一刻的磁盘快照负责。** 本次已实测到该风险：T1 校验时 `git status` 显示工作区**零**游戏改动，而在我准备提交报告的间隙，w2-data 已改写 `characters.json` / `items.json` / `weapons.json` 并新增 `events.json`、w3-art 已落 9 张 PNG —— **T1 报告在写完的瞬间即告过时，被迫全量重跑得到 T2**。`data/*.json` 是四方共享的最高冲突面，同文件不同键并发写会造成后写覆盖先写，极端情况下留下半截 JSON 导致 `DataLoader` 启动即崩（本轮万幸未发生，队友均为原子覆盖写）。
>
> **执行约定：① Godot 无头 / baseline 一律由 w5 单点串行执行，w1–w4 不要自行拉起（避免多实例争抢引擎与 `tools/baseline_*.log` 写锁）；② 本报告的 T2 结论仅对「w2/w3 已落盘、w1 代码尚未落盘」这一快照有效；③ 集成节点必须在所有人停手、改动全部落盘后重跑一次 `baseline_check.py` 复验，并以那一次结果为准出闸 —— 届时 5.1 / 5.2 两项极可能从「静态告警」升级为「运行时报错」。**

---

## 七、验证清单（本次已执行）

- [x] `tools/baseline_check.py` 完整执行并捕获全量输出 —— T1 / T2 两次均 `BASELINE CLEAN`
- [x] 校验 `baseline_*_err.log` 均为 0 字节，排除空跑假通过
- [x] 追加 600 帧深度运行探测（T1 / T2）—— 均 CLEAN
- [x] `data/*.json` 全量 `json.load()` —— T1 7/7、T2 8/8 通过
- [x] ID 唯一性 + waves→enemies + characters→weapons 悬空引用检查 —— 查出 1 处存量悬空
- [x] 9 张新增 PNG 帧 strip / 尺寸 / 色数 / `.import` 状态抽检
- [x] 全局检索确认 `shuriken` 与新美术在代码中的引用情况
- [x] 条目口径与文档比对
- [x] 全程只读，未触碰 `scripts/` / `data/` / `assets/`；`git add` 仅暂存本文件

---

*报告生成：**w5-qa** · 唯一写入文件：`docs/TEST_REPORT.md` · 提交信息：`w5: baseline + json validity report`*
