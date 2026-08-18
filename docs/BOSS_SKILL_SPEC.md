# Boss 技能与效果系统设计规格书（Boss Skill & Effect System Spec）

> 📌 **摘要**：用户拍板 2026-08-12 晚，Boss 战从"倒计时放光球"的演出式技能，升级为 **RPG 式交互技能**（地面预警圈 / 扇形 / 激光 / 打断 QTE），并整体**数据驱动**（数值、演出时间可随意管控 = 动态调难度，同技能变参数复用给不同 Boss）。同时**统一效果系统**：现有散落的烧伤/中毒类效果（元素表、敌人状态机、玩家技能、武器、被动）合并为一套中立系统，**玩家 / Boss / 怪物三方共用**。本文档为唯一规格来源，交 #2 拆解、#3 执行；**禁止跳过拆解流程直接动工。**

> 状态：✅ **已实装 BS-A~D + PS-B**（circle/fan/beam/charge/QTE 打断/位移三型/难度合成，探针 day30_boss_skill 49/49 + day31_skill_movement 13/13 全绿）· 决策点已全部拍板（2026-08-12 23:09 用户"按照你的思路来"）· **补充需求 2026-08-18：Boss 行为节奏调整（走走停停、大范围技能主导、追踪占比降低）→ 见 docs/RELIC_EXPANSION_SPEC.md §7 F 项**
> 关联文档：docs/FRAMEWORK_EXPANSION.md（G 系列，格式参照）、docs/TECH_DEBT_PLAN.md（F3 状态机收拢）、docs/GameData.xlsx（唯一事实源）、docs/PLAYTEST_CHECKLIST.md（追踪区）

---

## 1. 背景与决策

### 1.1 用户原话要点（2026-08-12 晚 19:18–22:35 连续讨论）

1. **Boss 技能要有 RPG 式交互**：不要"倒计时一到往周边放光球"，要地上生成圈 + 倒计时 + 圈内受伤、扇形、激光、特殊互动（QTE）等常规 RPG Boss 技能。
2. **数据驱动 + 变种复用**：技能像装备一样随意管控数值、演出时间（= 动态调难度）；同一技能换个参数给其他 Boss / 精英用。
3. **效果不止伤害**：还要击退、眩晕、异常状态（中毒/流血）、持续减防等负面效果。
4. **效果统一（已拍板）**：现有物品/武器里的烧伤类效果统一成同一套效果系统，人能用、Boss 能用、怪物也能用。

### 1.2 范围声明

| 纳入本次 | 不纳入本次 |
|---------|-----------|
| Boss 技能四拍子框架（预警→决策→结算→反馈） | 元素反应（element_reactions，独立系统不动） |
| 技能三层结构（类型行为 / 模板数据 / 实例状态） | 手感/数值平衡（用户自行收集方案） |
| 数据表：boss_skill / boss_pattern / effect（Excel 唯一事实源） | Boss 美术与 QTE 演出（占位即可） |
| 难度缩放层（动态调难度 + 公平底线钳制） | 新 Boss / 新武器内容设计 |
| 效果系统统一（elements sheet 升级 + 状态组件抽取 + apply_effect 统一入口） | 玩家主动技能/被动数值重做 |
| 免疫表（Boss 侧硬控门禁，可读化） | |

---

## 2. 设计框架：技能四拍子（一切技能的骨架）

> 核心观点：Boss 技能的本质是"给玩家出一道题"，而不是"放一个演出"。每个技能必须经历完整的四拍子循环，**设计重点是前两拍**（预警、决策窗口），结算只是兑现，反馈（后摇）是给玩家的喘息与输出窗口。

### 2.1 四拍子循环

```
待机 → 预警（亮出范围与时机）→ 决策窗口（玩家做出选择）→ 结算（兑现结果）→ 反馈（后摇 + 喘息）→ 回到待机
```

- **预警（Telegraph）**：位置、时机、结果一次性亮明白。圈=位置锁定+视觉读秒（收缩环/闪烁/渐亮）。
- **决策窗口（Decision）**：玩家必须"来得及作答"。窗口长度由公平底线公式保证（见 §2.2）。
- **结算（Resolve）**：兑现伤害/效果。绝不追加预警之外的新信息。
- **反馈（Feedback）**：Boss 硬直 + 输出窗口；玩家得到正反馈（闪避成功=安全输出）。

### 2.2 公平底线公式（所有躲避型技能必须满足，防"不可躲"）

```
预警时长 t_w > 最坏逃生时间 + 反应时间（≈0.4s）
最坏逃生时间：圈 = 2r ÷ 玩家移速；扇形按弧长；激光按横向位移
```

例：玩家移速 300px/s、圈半径 120px → t_w > 0.8 + 0.4 = 1.2s，实配 1.5~2.0s 手感最佳。
**难度缩放可以缩短 t_w，但不得突破此底线**（钳制见 §5）——难度提升的是压迫感（频率/组合），不是不可读性。

### 2.3 技能分类法（按"玩家需要做什么"设计）

| 分类 | 示例 | 星骸适配度 |
|------|------|-----------|
| 躲避型 | 地面圈 / 扇形 / 激光 / 横扫 | ★ 最基础，玩家本就持续移动，先做这个 |
| 拆解型 | 召唤核心 / 集火目标 / 图腾 | ★ 自动射击天然适配：索敌自动打，玩家用走位决定先打谁 |
| 互动型（QTE） | 火力打断 / 占点 / 火力充能 | ★ 见 §2.4，行为条件型 |
| 利用型 | 引弹清杂 / 借 Boss 技能打无敌怪 | ☆ 机制爽点，依赖前三类跑通后再做 |

### 2.4 互动型（QTE）设计规则

**星骸不做"按键时机"型 QTE**（操作面只有移动+技能，按键 QTE 撕裂手感）。QTE = **行为条件**：

- **火力打断**（首选）：Boss 蓄力读条 + 充能盾 → 窗口内造成 ≥N 伤害 → 打断成功（硬直 + 易伤窗口奖励）；超时 → 大招释放（全屏预警、仍可躲避）。自动射击天然适配，玩家只需"集火"。
- **占点**：大招倒计时时场上出现安全圈，玩家在时限内站入免伤——"圈"机制的反向复用。
- **三条铁律**：① 失败不致命（大招有预警可躲，只损失打断奖励）；② 成功有回报（硬直+易伤，直观"赚了"）；③ 一场 Boss 战最多 1~2 个机制（Boss 战要节奏不要考试）。

---

## 3. 技能系统架构：三层结构

**行为代码 × 配置数据 × 运行状态**三层分离，是"变种复用"与"动态调难度"的基础。

| 层 | 内容 | 变更成本 |
|----|------|---------|
| 技能类型（行为） | circle.gd / fan.gd / beam.gd / charge.gd，每种写一次 | 新增类型 = 新脚本 + 枚举值 |
| 技能模板（数据） | boss_skill 表一行 = 一个具名技能（参数化） | 改参数即变种，零代码 |
| 技能实例（状态） | 每次释放临时生成（圈位置/剩余倒计时/阶段），战斗内存，不落表 | 无 |

### 3.1 代码架构（伪代码，供拆解参考）

```gdscript
# 每个技能类型一个脚本，实现同一接口
class_name SkillExecutor extends Node
func enter(p: Dictionary) -> void: pass
func tick(delta: float, p: Dictionary) -> void: pass
func exit(p: Dictionary) -> void: pass

# Boss.gd —— 不认识任何具体技能，只挑 pattern 行
func _pick_and_cast() -> void:
    var row: Dictionary = _next_skill_from_pattern()             # 权重随机 + 保底
    var params: Dictionary = DataLoader.get_boss_skill(row.id)   # 模板（Excel 生成）
    params.merge(row.override)                                   # 变种覆盖
    params = _apply_difficulty(params)                           # 难度缩放（§5）
    var exec: SkillExecutor = _factory.make(row.type)            # 按 type 造执行器
    add_child(exec)
    exec.enter(params)
```

要点：Boss 不认识技能（只挑行）；执行器只认参数不认 Boss；难度在合成时统一缩放（表里永远基准值）。

---

## 4. 数据表设计（GameData.xlsx 新增 sheet，excel_export.py 生成 JSON，禁手改）

### 4.1 boss_skill 技能定义表 → `data/boss_skills.json`

| 字段 | 说明 |
|------|------|
| id | 技能唯一标识（爆裂圈 / 腐蚀圈 / 扇扫…） |
| type | 行为类型枚举：circle / fan / beam / charge / spawn… |
| telegraph | 预警时长 s（基准值，难度缩放从这里扣） |
| radius / arc | 范围（圈半径 / 扇形角 / 激光长宽） |
| effects | 效果列表：引用 effect id + 参数覆盖（§4.3） |
| resolve_delay | 结算延迟 s（与视觉爆炸同步） |
| cooldown | 冷却 s |
| vfx / sfx / warn_style | 演出：收缩环 / 闪烁 / 渐亮 + 特效音效 |

一行 = 一个技能；**变种 = 同 type 不同参数的新行**（或 pattern 的 override，见 4.2）。

### 4.2 boss_pattern 技能循环表 → `data/boss_patterns.json`

| 字段 | 说明 |
|------|------|
| boss_id | 哪个 Boss 用 |
| skill_id | 引用哪个技能 |
| weight | 随机权重 |
| phase | 血量阶段 100 / 66 / 33（阶段解锁新技能） |
| override | 参数覆盖 JSON（同技能不同 Boss 微调，如精英放大半径） |
| min_interval | 最短释放间隔 |

循环策略：权重随机 + **保底规则**（同技能不连续出 2 次、大招有冷却）= "Boss 有智商"的来源。
Boss 免疫表（`resist` 列，见 §6.4）可放本表或 boss 表，拆解时定。

### 4.3 effect 效果定义表（升级自现有 elements sheet）→ `data/elements.json`

现有 `elemental_status`（fire/ice/lightning/poison/plasma）字段各写各的（dot / slow_percent / stun / armor_reduction），升级为统一字段：

| 字段 | 说明 | 现状映射 |
|------|------|---------|
| id | fire / ice / lightning / poison / plasma… | 现有 key |
| type | 即时（一次性）/ 持续（tick） | fire/poison=持续；新增击退/眩晕=即时 |
| duration | 时长 s | 现有 duration |
| tick_interval | 每几秒一跳（持续型） | 默认 1s |
| value | 数值：跳伤 / 位移 / 属性改动 | dot / slow_percent / armor_reduction 并入 |
| scaling_attr + ratio | 受属性缩放（如元素伤害×0.2） | dot_scaling 保留 |
| target_attr | 作用到哪个属性（defense / move_speed…） | 新增（减防→defense） |
| max_stacks | 叠加上限（0=不可叠） | 新增 |
| icon / vfx / sfx | 表现 | 新增 |

**伤害也是效果的一种（type=即时）**——技能不再有独立的 damage 字段，全走 effects 列表。

---

## 5. 难度缩放链路（动态调难度）

```
基础难度（关卡/波次） ─┐
                        ├→ 难度系数（合成 0.5~2.0）→ 参数倍率 → 公平底线钳制 → 技能实例参数
动态难度（build 强度） ─┘                          （预警↓ 伤害↑ 半径↑）  （t_w ≥ 底线）
```

- **表里永远只存基准值**；改难度不碰表，只调系数。
- 两个输入源：基础难度（关卡/波次，已有）+ 动态难度（玩家 build 强度——装备越好系数越高，防"胡了碾压无趣"）。
- **公平底线钳制**（§2.2）：难度缩短 t_w 但不得低于"逃生时间 + 0.4s"，否则技能变不可躲。

---

## 6. 效果系统统一（用户已拍板方向）

### 6.1 现状查证（2026-08-12 实测，5 处分散）

| # | 位置 | 现状 | 问题 |
|---|------|------|------|
| 1 | `data/elements.json`（Excel elements sheet 生成） | 5 元素状态定义 + 元素反应 | 字段各写各的，未抽象成效果 |
| 2 | `scripts/enemy/enemy.gd:257-290` | 最小状态机 apply_status/_update_status | **只落地了 DoT**（取更长+更高防滚雪球）；减速/麻痹/减防无运行时 |
| 3 | `scripts/player/skill_controller.gd:99-160` | 燃烧 dps 独立计算（读 elements.json） | 玩家侧无统一状态组件，口径独立 |
| 4 | `data/weapons.json:1756` | "施加中毒(5秒)" | 文本级描述，未与效果表数值联动 |
| 5 | `data/items.json:707` + desc_builder.gd:21 | burn_duration_percent 被动 | 独立字段，单独翻译 |

### 6.2 统一方案（三步）

1. **elements sheet 升级为 effect 表**（§4.3）：现有字段映射进统一结构，数值不变，走 Excel 管线重生成（data_schema.py 注册映射，excel_export.py 输出）。
2. **enemy.gd 状态机抽成通用 `StatusComponent`**：玩家 / Boss / 怪物挂同一组件；skill_controller 的燃烧 dps 并入，删除重复口径；玩家 HUD 状态栏从组件读剩余秒数/层数（可读性原则）。
3. **统一施加入口 `apply_effect(source, target, effect_id, params)`**：武器特殊效果、被动、玩家技能、Boss 技能全走它；weapons.json 的"施加中毒"从文本升级为结构化 effect 引用。

### 6.3 叠加规则（决策点 O1，待用户拍板）

- 现状（enemy.gd）：重复附着取"更长剩余时间 + 更高 dps"，异源也合并取优（宽松）。
- 建议统一为标准规则：**同源（同技能同来源）→ 刷新计时不叠层；异源 → 各自独立实例各自 tick**；可叠层效果用 `max_stacks` 控制。防数值指数爆炸，且规则全局一致。

### 6.4 免疫表（Boss 侧门禁）

- Boss 表/pattern 加 `resist` 列（如 `["stun", "knockback"]`）。
- **惯例**：硬控（眩晕/击退——剥夺行动）Boss 普遍免疫或大幅减免；**软控（减速/中毒/减防——削弱不剥夺）保留**，让玩家异常 build 在 Boss 战仍有价值。
- **免疫必须可视化**：Boss 血条下挂免疫图标（可读性原则），避免玩家带无效 build 打到一半才发现。

---

## 7. 优先级与依赖

| 顺序 | 任务 | 依赖 | 理由 |
|------|------|------|------|
| 1 | effect 表升级 + StatusComponent 抽取 + apply_effect | 无（地基） | 玩家/怪侧效果先行统一，Boss 才能挂效果 |
| 2 | 技能执行器框架 + circle 类型 + 公平底线公式 | 1（effects 引用） | 先跑通四拍子最小闭环 |
| 3 | boss_skill / boss_pattern 表 + Boss pattern 状态机 | 2 | 接 F3 状态机收拢（idle→telegraph→resolve→recover） |
| 4 | 难度缩放层（系数 + 钳制） | 2、3 | 动态调难度落地 |
| 5 | fan / beam / charge / 打断 QTE 扩展 | 2（同骨架换参数） | 最小路径后的增量 |
| 6 | 利用型技能、免疫表 UI | 3 | 收尾 |

**最小路径**：先只做"圈"（地面预警 → 延迟结算 → 后摇），跑通四拍子后其余都是同骨架换参数。

---

## 8. 数据结构规格（供拆解参考，最终以方案师定案为准）

### 8.1 新增数据文件（均由 Excel 生成，禁手改）

- `data/boss_skills.json` — 技能定义（结构 §4.1）
- `data/boss_patterns.json` — Boss 技能循环（结构 §4.2）

### 8.2 现有文件改动

- `data/elements.json` — elemental_status 升级为统一 effect 字段（§4.3），数值不变
- `scripts/enemy/enemy.gd` — 状态机抽为通用 StatusComponent（玩家/Boss 复用）
- `scripts/player/skill_controller.gd` — 燃烧 dps 并入状态组件，删重复口径
- `data/weapons.json` / `data/items.json` — 效果描述改结构化 effect 引用；burn_duration_percent 改读 effect 时长
- `tools/data_schema.py` / `tools/excel_export.py` — 注册新 sheet 映射与生成

---

## 9. 开放问题（全部已拍板 2026-08-12 23:09，交拆解）

| # | 问题 | 拍板结果 | 状态 |
|---|------|---------|------|
| O1 | 叠加规则 | ✅ **同源刷新 / 异源独立 + max_stacks**（替代现状"取更长+更高"） | 已拍板 |
| O2 | 减速/麻痹/减防运行时落地 | ✅ **统一时一次性补齐**（改移速/禁行动/改 defense） | 已拍板 |
| O3 | Boss 硬控免疫范围 | ✅ 硬控免疫（眩晕/击退）、软控保留 | 已拍板 |
| O4 | 玩家状态 HUD 显示 | ✅ 状态栏实时显示剩余秒数/层数 | 已拍板 |
| O5 | 免疫表放 boss 表还是 pattern 表 | ✅ 放 boss 表（全局属性，pattern 只管循环） | 已拍板 |

---

## 10. 拆解建议（交 #2）

- 建议按 §7 顺序函数级拆解入 TASKS.md，每步 2-3 个 W 任务：数据层 / 代码层 / 接线+探针。
- 探针：`tools/dayXX_boss_skill_check.gd`（圈：预警→结算→圈内伤害、圈外无伤、t_w≥底线断言）+ `dayXX_effect_check.gd`（DoT 跳数、同源刷新/异源独立、到期还原属性、免疫表），断言覆盖 §11 验收列；回归套件须全绿。
- 探针注意既有坑：Boss/敌人状态机改动后，回归前序"无 levels"探针依赖（data 层 int 归一化、合成裸 Weapon 等）不可破坏。
- 禁止在拆解完成前写游戏代码（遵守 TASKS 护栏）。

---

## 11. 验收标准

1. **四拍子闭环**：圈技能走完 预警→结算→后摇，预警时长 ≥ 公平底线（探针断言）。
2. **数据驱动**：boss_skill 所有数值改 Excel 生效，无需改代码；同技能变种（override）可给不同 Boss 使用。
3. **效果统一**：同一 effect（如中毒）可由武器 / 被动 / 玩家技能 / Boss 技能施加，目标为玩家、Boss、怪物任一，行为一致。
4. **持续效果正确**：tick 跳数符合 interval；同源刷新不叠层；异源独立；到期移除并还原属性（减防恢复）。
5. **免疫可读**：Boss 免疫的硬控在血条下可见；免疫效果对 Boss 无效。
6. **难度缩放**：系数变化时技能参数随之变化，且 t_w 不突破公平底线。
7. **回归**：既有 34 项回归套件全绿；存档兼容（meta_progress 无破坏性改动）。
