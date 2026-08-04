# 《星骸回响》Star Echo · 测试报告（TEST_REPORT）

> 负责人：**w5-qa**（并发团队 starecho-sprint）
> 执行时间：2026-08-04
> 被测版本：`git HEAD = 343c78a`（docs: 交接简报同步至最新工程状态）
> 项目路径：`D:\Program Files\30DAYS` · 引擎 `tools/Godot_v4.3-stable_win64.exe`（Godot 4.3.stable.official.77dcf97d8）
> 执行器：`C:\Users\Administrator\.workbuddy\binaries\python\versions\3.13.12\python.exe`
> 范围：无头基线自校验 + 全量 JSON 可解析性 + 数据交叉引用完整性。**本报告为只读验证，未修改任何游戏代码/数据/美术。**

---

## 一、总体结论

| 项目 | 结果 |
|---|---|
| **baseline_check（权威判定）** | ✅ **PASS —— 输出 `BASELINE CLEAN`** |
| 深度运行探测（600 帧，w5 追加） | ✅ PASS（exit 0，stderr 干净） |
| `data/*.json` 全量可解析 | ✅ PASS（7/7 文件，0 失败） |
| 数据交叉引用（ID 唯一性 / 悬空引用） | ✅ PASS（无重复 ID、无悬空引用） |
| import / 运行时错误 | ✅ 无（两阶段 stderr 均为空文件） |

**结论：当前 HEAD 基线干净，允许提交。** 未发现任何阻断级（Blocker）缺陷。发现 2 项非阻断观察项与 1 项方法学提示，见第五节。

---

## 二、baseline_check 执行结果（完整输出）

命令（在项目根执行）：

```
C:\Users\Administrator\.workbuddy\binaries\python\versions\3.13.12\python.exe tools/baseline_check.py
```

完整捕获输出：

```
[import] --quit
[import] PASS - exit 0, stderr clean
[runtime] --quit-after 4
[runtime] PASS - exit 0, stderr clean

BASELINE CLEAN - safe to commit.
```

退出码 `0`。

日志落盘校验（确认脚本确实拉起了引擎，非空跑）：

| 日志文件 | 大小 | 内容 |
|---|---|---|
| `tools/baseline_import_out.log` | 73 B | Godot Engine v4.3.stable.official.77dcf97d8 横幅 |
| `tools/baseline_import_err.log` | **0 B** | 无 stderr |
| `tools/baseline_runtime_out.log` | 73 B | Godot 横幅 |
| `tools/baseline_runtime_err.log` | **0 B** | 无 stderr |

> 两个 `*_err.log` 均为 0 字节 —— **无 import 错误、无 autoload 解析错误、无运行时错误**。

### 2.1 追加：深度运行探测（w5 自建，未写入项目）

`baseline_check.py` 的 runtime 阶段使用 `--quit-after 4`。**Godot 4 的 `--quit-after N` 单位是「迭代/帧」而非「秒」**（脚本 docstring 注释写作「run the main scene for 4s」，属注释与实际语义不符）。4 帧仅约 0.07 秒游戏时间，只能覆盖 `_ready` 与首帧，波次推进 / 敌人生成 / 计时器等逻辑基本未被触达。

为避免「浅层通过」造成的假阴性，w5 追加了一次 **600 帧（≈10 秒游戏时间）** 的只读探测（输出走内存管道，**不向项目目录写入任何日志**）：

```
[import(--quit)]     exit=0 wall=0.71s stderr_lines=0 -> PASS
[runtime(600 iters)] exit=0 wall=4.80s stderr_lines=0 -> PASS

DEEP RESULT: CLEAN
```

结论：加深到 600 帧后依旧零 stderr，**基线 PASS 判定可信，非浅层假通过**。

---

## 三、JSON 可解析性校验

方法：Python 遍历 `data/*.json` 逐个 `json.load()`。

| 文件 | 解析 | 顶层类型 | 顶层键 | 体积 |
|---|---|---|---|---|
| `data/characters.json` | ✅ OK | dict | `characters`(6) | 2797 B |
| `data/elements.json` | ✅ OK | dict | `elemental_status`(5) / `element_reactions`(10) / `reaction_rules`(4) | 3400 B |
| `data/enemies.json` | ✅ OK | dict | `enemies`(3 档) / `scaling`(5) | 4558 B |
| `data/items.json` | ✅ OK | dict | `items`(45) | 7742 B |
| `data/stats.json` | ✅ OK | dict | `stats`(3) / `formulas`(15) / `leveling`(3) | 4135 B |
| `data/waves.json` | ✅ OK | dict | `waves`(20) / `generation`(3) / `rewards`(3) | 6123 B |
| `data/weapons.json` | ✅ OK | dict | `weapons`(4 类) | 10796 B |

```
TOTAL=7  OK=7  FAIL=0
```

**无任何 JSONDecodeError / 编码错误 / 截断文件。**

### 3.1 条目口径澄清（避免误判为「数据丢失」）

`enemies` / `weapons` 顶层键数少（3 / 4）是因为采用了**分组嵌套**结构，叶子条目数与文档口径一致：

| 数据 | 分组 | 叶子条目 | 文档口径 | 结论 |
|---|---|---|---|---|
| weapons | melee 7 / ranged 8 / elemental 8 / engineering 6 | **29** | 29 | ✅ 一致 |
| enemies | regular 15 / elite 6 / boss 2 | **23** | 23 | ✅ 一致 |
| characters | 扁平 | **6** | 6 | ✅ 一致 |
| waves | 扁平 | **20** | 20 | ✅ 一致 |
| items | 扁平 | **45** | 39 | ⚠️ 文档偏旧（见 5.2） |

---

## 四、数据交叉引用完整性（w5 追加只读检查）

- **ID 唯一性**：characters / weapons / items / enemies 四类均**无重复 ID**。
- **悬空引用**：`waves.json` 中引用的敌人 ID **全部**能在 `enemies.json` 命中；`characters.json` 的初始武器字段**未发现**指向不存在武器的悬空引用。
- 当前 ID 清单（供 w1–w4 对齐命名，避免并发新增时撞 ID）：
  - characters：`well_rounded` / `brawler` / `ranger` / `mage` / `engineer` / `gambler`
  - weapons（分类）：`melee` / `ranged` / `elemental` / `engineering`
  - enemies（档位）：`regular` / `elite` / `boss`

```
XREF OK - no duplicate ids, no dangling references detected
```

> ⚠️ 对 w4-narrative / w2-data 的提示：Day 2 要接入的 3 英雄（艾琳 Mage / 诺亚 Summoner / 莱恩 Melee）在当前 `characters.json` 中**尚不存在**（现有 6 个是框架期的通用原型 `mage`/`brawler` 等）。这属于**待实现**而非缺陷，但新增时请沿用既有嵌套结构与 ID 命名风格。

---

## 五、发现项汇总

### 5.1 [非阻断 · 方法学] runtime 阶段覆盖过浅

`tools/baseline_check.py:86` 使用 `--quit-after 4`，语义为 **4 帧**而非 4 秒；同文件 `:85` 注释「Run the main scene for 4s」与实际不符。当前它只能捕获 `_ready` 期错误。
**影响**：后续 Day 3+ 引入技能冷却、波次推进、召唤物生命周期后，短帧数运行可能漏掉定时/状态机类运行时报错。
**建议**（交集成节点处理，**w5 不改代码**）：将 runtime 阶段提升到 `--quit-after 300~600`，成本仅 +4 秒。

### 5.2 [非阻断 · 文档漂移] items 实际 45 条，文档写 39

`docs/PROJECT_BRIEF.md:64` 与 `docs/30DAY_PLAN.md:7` 记为 `items(39)`，实际 `data/items.json` 为 **45** 条。数据本身健康，属文档计数未同步。建议由文档归口方顺手校正。

### 5.3 [非阻断 · 环境] 本次基线反映的是「改动前」状态

执行时 `git status` 显示**工作区无任何游戏代码/数据/美术改动**，仅有 4 个未跟踪的新文档（`30DAY_PLAN.md` / `30DAY_PLAN_STARECHO.md` / `CONCURRENCY_PLAN.md` / `TASKS.md`）与 1 个 `.docx`。
**因此：本报告的 PASS 是 Day 1 的「干净起点基线」，不代表 w1–w4 本轮产出的代码已被验证。** w1–w4 的改动落盘后，必须由 w5 重跑一次基线才能形成「改动后」判定。

---

## 六、并发编辑风险提示

> ⚠️ **多 Agent 并发写入同一工程时，「基线 PASS」具有强时效性 —— 它只对我执行那一刻的磁盘快照负责。** w1-code / w2-data / w3-art / w4-narrative 若在本次校验期间或之后写入 `scripts/`、`data/`、`assets/`，本报告结论即刻失效；尤其 `data/*.json` 是四方共享的高冲突面（同文件不同键并发写会造成后写覆盖先写、甚至留下半截 JSON 导致 `DataLoader` 启动即崩）。**约定：Godot 无头/baseline 一律由 w5 单点串行执行（避免多实例争抢引擎与 `tools/baseline_*.log` 写锁）；集成节点在所有人停手、改动全部落盘后，必须重跑一次 `baseline_check.py` 复验，以那次结果为准出闸。**

---

## 七、验证清单（本次已执行）

- [x] `tools/baseline_check.py` 完整执行并捕获全量输出 → `BASELINE CLEAN`
- [x] 校验 `baseline_*_err.log` 为 0 字节，确认非空跑假通过
- [x] 追加 600 帧深度运行探测 → CLEAN
- [x] `data/*.json` 全量 `json.load()` → 7/7 通过
- [x] ID 唯一性 + waves/characters 悬空引用交叉检查 → 通过
- [x] 条目口径与文档比对 → 仅 items 计数漂移
- [x] 全程只读，未触碰 `scripts/` / `data/` / `assets/`

---

*报告生成：w5-qa · 唯一写入文件为本文件 `docs/TEST_REPORT.md`*
