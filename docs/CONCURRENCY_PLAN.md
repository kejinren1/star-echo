# 并发分工执行方案（CONCURRENCY_PLAN）

> 目的：把《星骸回响》30 天冲刺的每日任务，用**多 Agent 并发团队**在同一会话内并行执行，同时避免共享 Godot 工程下的并发写冲突。
> 适用：D:\Program Files\30DAYS（单一 Godot 4.3 工程，数据驱动 JSON + 帧 strip）。
> 配套：本方案与 `docs/30DAY_PLAN.md`（规划）、`docs/TASKS.md`（每日任务）、`docs/MEMORY.md`（专家配置）协同。

---

## 一、总体架构

```
        调度 Orchestrator（拆 Day 任务 → 派发）
            │ 扇出
   ┌────────┼────────┬────────┬────────┐
 玩法代码  数值数据  美术资产  剧情文案   QA 测试   ← 5 条并行工作流
   │        │        │        │        │
   └────────┼────────┴────────┴────────┘
            │ 汇合
      集成节点（Git 提交 · baseline 校验 · 冲突合并）
```

- **调度**：将 `TASKS.md` 中当日任务按文件域切片，派发给对应工作流。
- **并行**：5 条工作流在同一会话内同时运行，互不等待。
- **汇合**：各工作流完成后，由集成节点统一提交与回归校验。

---

## 二、工作流分工矩阵

| # | 工作流 | 负责专家（现成） | 独占文件域 | 主要产出 | 护栏 |
|---|--------|------------------|------------|----------|------|
| W1 | 玩法代码 | godot-dev / GodotGameScriptEngineer | `scripts/`、`scenes/` | 角色/武器/敌人/Boss/事件 逻辑实现 | 只改自身脚本；不碰 JSON/美术 |
| W2 | 数值数据 | GameDesigner | `data/characters.json`、`weapons.json`、`items.json`、`stats.json`、`waves.json` | 平衡数值、成长公式、武器/被动数据 | 只改 assigned JSON；不碰他人 JSON |
| W3 | 美术资产 | pixel-artist / TechnicalArtist | `assets/sprites/`、`docs/ART_STYLE.md`（仅追加方向） | 英雄/敌人/Boss 精灵、技能 VFX | 遵守 32px/32色/Nearest/1px 描边 |
| W4 | 剧情文案 | NarrativeDesigner | `data/events.json`、`docs/` 叙事文档 | 10 事件文本、世界观、角色剧情 | 只改 events.json 与叙事 doc |
| W5 | QA 测试 | 自动化测试（无头） | 只读 + `docs/TEST_REPORT.md` | baseline_check、回归、性能 | 只跑校验，不写游戏代码 |

> **关键**：W2 与 W4 都碰 `data/`，但**分文件**——W2 管战斗/数值 JSON，W4 只管 `events.json` 文本，无重叠。

---

## 三、文件域隔离规则（冲突预防核心）

1. **严格按矩阵划域**：每个 Agent 只写自己独占的文件域；跨域改动一律走集成节点。
2. **共享文件 `project.godot` 序列化**：Autoload / 场景注册等需改 `project.godot` 时，**不并发改**——由集成节点在各 Agent 完成后统一合并（或预先由 W1 一次性写入）。
3. **报告文件互不重叠**：各自动化/工作流写独立文件，避免互踩：
   - 进度日报 → `docs/PROGRESS_LOG.md`
   - 测试报告 → `docs/TEST_REPORT.md`
   - 人工试玩清单 → `docs/PLAYTEST_CHECKLIST.md`
   - 专家池 → `docs/EXPERT_POOL.md`
4. **数据原则**：新增内容 = 一条 JSON 记录 + 一张帧 strip PNG（已有约定），天然适合并行——各 Agent 追加不同文件/不同 key，零冲突。

---

## 四、Git 策略

采用 **trunk-based + 文件级隔离**（最简单、零冲突）：

- 各 Agent 只 `git add` 自己独占的文件（`git add scripts/`、`git add data/weapons.json` 等），不 `git add -A`。
- 因文件域不重叠，**无合并冲突**，可直接提交到主分支。
- 仅在涉及 `project.godot` 等共享文件时，由集成节点串行处理并提交。
- 重大改动前各 Agent 先 `git commit` 当前状态（护栏之一）。
- 可选：每个冲刺开 `sprint/day-XX` 分支，集成节点统一 `merge` 后删分支。

---

## 五、冲突解决预案

| 风险 | 触发 | 解决 |
|------|------|------|
| 两个 Agent 改同一 JSON | 域划分疏漏 | 矩阵已分文件；若发生，集成节点 `git merge` 冲突手动解，按「数值优先 W2 / 文本优先 W4」裁决 |
| `project.godot` 并发改 | W1 多次注册 | 预写或串行合并，不并发 |
| 帧 strip 命名撞车 | 美术与代码约定不一 | 命名规范 `角色_动作_帧宽.png`，集成节点核对 `assets/sprites/` |
| baseline 回归失败 | 某 Agent 引入 import 错误 | W5 立即报 `TEST_REPORT.md`，对应工作流回滚该提交 |

---

## 六、集成与校验

- **必跑**：每次汇合跑 `python tools/baseline_check.py`，必须 `BASELINE CLEAN` 才允许合并/提交。
- **W5 职责**：无头 Godot 校验、运行时报错、数据边界、性能（帧率/内存/同屏敌人数）。
- **人工试玩**：W5 把主观项（手感/难度/视听/剧情）汇总 `docs/PLAYTEST_CHECKLIST.md`，不自动试玩。

---

## 七、与现有 7 个自动化的关系

- 7 个自动化负责**「何时触发 / 分析进度 / 标记人工」**（时间错峰：08:00→21:00）。
- 并发团队负责**「当日任务的实际执行」**。
- 衔接点：将自动化 **#3（方案确定与执行，每日 09:00）** 改为「拉起并发团队」——#3 读取 `TASKS.md` 当日任务，按本方案矩阵派发给 5 条工作流，再由 W5 校验汇合。其余 #1/#2/#4/#5/#6/#7 不变。

---

## 八、执行前阻塞清单（必须先清）

- [ ] **关闭 Word 中的 `30DAY_PLAN.md`**（当前 EBUSY，写不进）；将 `docs/30DAY_PLAN_STARECHO.md` 改名为 `30DAY_PLAN.md`。
- [ ] 跑一次 `python tools/baseline_check.py` 确认当前 `BASELINE CLEAN`（并发前基线必须绿）。
- [ ] 确认 5 条工作流的文件域划分无遗漏（对照本方案矩阵）。
- [ ] 确认 `data/events.json` 与战斗 JSON 已分离，避免 W2/W4 冲突。

---

## 九、落地步骤（确认后执行）

1. `TeamCreate` 建团队（team_name=starecho-sprint）。
2. 用 `Agent` 拉起 5 个子代理，各带本方案对应工作流指令 + 文件域护栏。
3. 调度 Agent（主）读取 `TASKS.md` 当日任务切片派发。
4. 各子代理并行执行 → 各自 git 提交独占文件。
5. 集成节点（主 Agent）合并 `project.godot`、`baseline_check` 回归、产出日报。
6. 循环至 30 天窗口结束。

> 本方案为**安全并发蓝图**，正式拉起团队前需先清除第八节阻塞项。
