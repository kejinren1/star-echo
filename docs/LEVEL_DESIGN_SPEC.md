# 关卡设计规格书（Level Design Spec）：固定出生点 + Boss 阶段演出

> 📌 **摘要**：用户拍板 2026-08-18 晚（对话：关卡设计现状 → 唯一事实源扩展）。关卡数据已大部分入表（waves/enemies/boss_skill/boss_pattern 等），但仍有三块硬编码在代码里：**① 刷新位置规则**（enemy_spawner.gd 写死 ±200×±120 随机、最小距离 110px）；**② 特殊波语义**（swarm 翻倍/HP 减半 等 if/else 特判）；**③ Boss 血线演出**（phases 只支持换技能池+移速，血线到了静悄悄，无横幅/特效/台词）。本次收口：**刷新位置改为固定出生点（表驱动）+ 新增 boss_phase_events 独立演出表 + 正向属性状态系统（attr buff，通用型）**。本文档为唯一规格来源，交 #2 拆解、#3 执行；**禁止跳过拆解流程直接动工。**

> 状态：📋 **待 #2 拆解**（用户已拍板三项核心决策；其余细节决策点见 §8）
> 关联文档：docs/GameData.xlsx（唯一事实源）、docs/DATA_DICT_GUIDE.md（策划改数手册，收口后同步）、docs/BOSS_SKILL_SPEC.md（相位/效果先例）、tools/excel_export.py（导出管线）、docs/PLAYTEST_CHECKLIST.md（追踪区）

---

## 1. 背景与决策

### 1.1 用户原话要点（2026-08-18 22:57 对话）

1. 关卡设计现状追问："关卡设计现在什么形式？是不是硬写到程序里的？"
2. 诉求："关卡有多少怪、什么位置刷新、刷新什么怪、怪的属性、额外技能"都要能在唯一事实源里调。
3. **Boss 演出诉求（本次核心）**："Boss 血量降到多少的时候，会横幅提示也好、特效变更也好，这样的表格形式，方便我去调动这些资源。"
4. **拍板 1（刷新位置）**：固定出生点（非随机参数化）。
5. **拍板 2（演出表）**：独立表 `boss_phase_events`，一行一个演出事件。
6. **拍板 3（正向状态）**：通用属性状态一次到位（attack%/speed%/armor/crit 等；用户认可"金手指也是可以是一种状态"的思路）。

### 1.2 现状盘点（2026-08-18 实测）

**已数据化（GameData.xlsx 唯一事实源 → excel_export.py → data/*.json → DataLoader）：**

| 能力 | 表 | 说明 |
|---|---|---|
| 每波多少怪/什么怪/持续多久 | waves | 20 波；composition 列 JSON `[{"enemy":"chaser","count":8}]` |
| 怪的基础属性/成长/掉落/护甲/免疫 | enemies | 24 行；hp/hp_growth/damage/speed/armor/resist |
| 怪的额外技能 | enemies ability.* | aoe/self_heal/spawn + 半径/间隔/倍率/召唤物/数量/最大批数 |
| Boss 技能 | boss_skill | circle/fan/beam 等 + 预警/结算/冷却/vfx/sfx |
| Boss 技能分配 | boss_pattern | boss_id + skill_id + weight + phase(100/66/33) + override + min_interval |
| Boss 血线阶段（换技能池） | enemies.phases | JSON：hp_threshold_percent + attacks[] + speed_multiplier |
| 外观/行为映射 | enemy_sprites / enemy_behavior | 最近两批已收口 |

**硬编码（本次要收口）：**

| # | 位置 | 内容 |
|---|---|---|
| ① | enemy_spawner.gd `_get_random_spawn_position` | 以玩家为中心 ±200×±120 随机、min_dist 110px；spawn_margin 100、base_spawn_interval 0.8（decay 已抽 wave_generation 表） |
| ② | enemy_spawner.gd:82 / 其他 | swarm_wave 数量翻倍 + HP 减半等特殊波语义 if/else |
| ③ | enemy.gd / enemy_damage.gd phases 消费 | 血线只触发换技能池，无演出事件（横幅/特效/台词/震屏） |

### 1.3 范围声明

| 纳入本次 | 不纳入本次 |
|---------|-----------|
| 固定出生点表 spawn_points + spawner 按点位生成 | 手写 JSON（生成物禁手改，铁律） |
| boss_phase_events 演出表 + 触发执行器（banner/vfx/sfx/dialogue） | 新 Boss / 新怪内容设计（策划另填表） |
| 特殊波语义参数化（swarm 倍数等，若拆解后成本可控） | 元素反应系统（独立，不动） |
| 点位/演出缺省兼容（表空回退随机，防空白波次崩游戏） | 演出美术资源制作（占位即可） |
| 正向属性状态 attr（buff：attack%/speed%/armor/crit 等，含金手指一致性说明） | 金手指 Debug 模式实现改动（F-04 用户已拍板，保持现状） |

---

## 2. 固定出生点设计

### 2.1 动机

- **根治 F-48**（2026-08-18 用户反馈"最后一个敌人死活不出现"）：随机生成矩形存在视野死角 → 点位固定后可读、可控、可设计"怪从哪来"的演出感。
- 演出感：怪从视野边缘/固定入口涌入，玩家可预判（配合现有 Aggro Leash 320 双保险）。
- 与 Boss 演出表配合：Boss 登场点 + 血线演出 = 完整 Boss 战编排能力。

### 2.2 表结构 `spawn_points`

| 列 | 类型 | 说明 |
|---|---|---|
| point_id | 主键 | 如 `north` / `south_east` / `arena_center` / `boss_top` |
| type | 枚举 | `edge`（竞技场边缘方位）/ `anchor`（绝对坐标）/ `ring`（以竞技场中心为圆心、radius 半径圆周均分） |
| direction | 字符串 | type=edge 时：north/south/east/west/ne/nw/se/sw |
| x / y | 数字 | type=anchor 时：竞技场局部坐标（0~1 比例，0.5=中心，运行时乘竞技场尺寸） |
| radius | 数字 | type=ring 时：半径（像素，相对竞技场中心） |
| inset | 数字 | 默认 0：从竞技场边缘内缩像素（edge 用，防止刷墙外） |
| min_dist_player | 数字 | 默认 110：该点位生成时离玩家的最小距离（沿用现常量） |

### 2.3 waves 表扩展

- 新增列 `spawn_set`（JSON 字符串数组）：`["north","south_east","ring_outer"]` —— 本波按此点位组生成。
- **缺省（空）** = 默认边缘均匀组（见 §2.4），保证 20 波零改动即可跑。
- 生成顺序：`spawn_order` 列（可选，缺省 `sequence`：按队列顺序轮换点位；可选 `random`：组内随机）。

### 2.4 默认配置（推荐值，策划可改）

| 场景 | 点位 | 说明 |
|---|---|---|
| 普通波缺省 | edge × 8（n/s/e/w + 4 斜角），inset 40 | 环绕竞技场，玩家视野内可预判 |
| 精英波 | 同上 + 中央 anchor(0.5, 0.45) 或由策划指定 | 精英怪"压轴登场"感 |
| Boss 波 | `boss_top`（edge north, inset 60）或 anchor(0.5, 0.3) | Boss 从正上方登场（现 Boss 波 composition 已是单 boss:xxx） |
| swarm 波 | 同普通波 | 数量翻倍语义不变，倍数见 §4 特殊波参数 |

### 2.5 安全规则

1. 所有点位生成后仍经 `clamp_to_ground` 钳制（墙外兜底）。
2. 点位内缩保证不落入竞技场边界外（inset 默认 40）。
3. 与玩家出生点（竞技场中央偏下）不重叠：anchor 类点位由策划负责，`min_dist_player` 运行期兜底（尝试 3 次换点，仍近则原样生成，不静默丢弃——沿用现兜底语义）。
4. 点位表为空 / 某波 spawn_set 引用了不存在的 point_id → 导出校验报错（excel_export.py 校验清单新增 FK 检查），运行期缺省回退随机（防空白波次）。

---

## 3. Boss 阶段演出事件设计

### 3.1 表结构 `boss_phase_events`

| 列 | 类型 | 说明 |
|---|---|---|
| boss_id | FK → enemies.id | 哪个 Boss 的演出 |
| hp_threshold_percent | 数字 | 血线阈值（整数 1~99；100 = 开局登场演出） |
| seq | 数字 | 同阈值多条事件顺序（1 起） |
| event_type | 枚举 | `banner` 横幅 / `vfx` 特效 / `sfx` 音效 / `dialogue` 台词 / `camera` 震屏 |
| param | JSON | 见 3.4，按类型定义 |
| once | 数字 | 默认 1：只触发一次；0 = 每次进该阈值段都触发（慎用） |

### 3.2 触发时机（复用现有相位钩子）

- 挂点：`enemy_damage.gd:35` 存活命中 → `_check_phase_transition()` 同一处（enemy.gd:355 `_transition_phase` 链）。
- 阈值语义与 phases 一致：**> 上一阈值 且 ≤ 本阈值**（如 100→60 段内，血量首次 ≤60 时触发 60 的行）。
- **击杀瞬间不触发**（沿用决策 D6：避免死亡帧残留横幅）。
- 同一阈值多条事件按 seq 顺序执行；同帧多次命中只执行一次（once=1）。

### 3.3 事件类型参数定义（param JSON）

| event_type | param 字段 | 说明 |
|---|---|---|
| banner | `{"text":"狂怒！火力全开","color":"#E24B4A","duration":1.5}` | 仿 GameManager._show_elite_banner 范式（淡出上浮 1.5s 自毁）；color 缺省红 |
| vfx | `{"name":"screen_flash","anchor":"screen"}` | VfxPlayer 注册表按名调用；未知名 warn + 跳过 |
| sfx | `{"name":"boss_phase_up"}` | audio_manager 按名播放；未知名 warn + 跳过 |
| dialogue | `{"text":"这就是……最后的挣扎","speaker":"invoker"}` | 台词框（可先复用 banner 样式占位） |
| camera | `{"strength":"heavy","count":2}` | 复用 Main._trigger_camera_shake |
| buff | `{"target":"self","effect":"frenzy","duration":10}` | 给目标附加 attr 状态（见 §4）；target=self（Boss 自身狂暴）/ player（对玩家附加，慎用） |

### 3.4 与 boss_pattern / phases 的关系（不改动现结构）

- `boss_pattern.phase`（100/66/33 技能分配）**保持现状**——管"换什么技能"。
- `enemies.phases`（attacks + speed_multiplier）**保持现状**——管"技能池与速度"。
- `boss_phase_events` **只负责演出**（横幅/特效/音效/台词/震屏）。三者阈值各自独立可配（同一 Boss 可 60% 换技能、50% 弹横幅），互不阻塞。

---

## 4. 正向属性状态系统（attr buff，通用型）

### 4.1 背景与决策

- 用户 2026-08-18 拍板：**通用属性状态一次到位**（attack%/speed%/armor/crit 等），不做"只加攻击力"的最小版；认可"金手指也是一种状态"的概念。
- 现状：status_component（2026-08-13 效果统一）只支持 dot/slow/stun/armor/invulnerable —— **全是负面/防御**，无正向增益类型。
- 地基已齐：玩家 `damage_multiplier` 已存在且**全伤害出口统一乘**（weapon_controller:338/354、skill_controller:178/341、turret:104、orbit_weapon:117、melee_sweep:108）；enemy 侧 move_speed/armor 同理。→ 只要状态能改这些变量，等于改了全部。

### 4.2 机制（最小扩展，复用 slow 范式）

- `elements` 表 type 新增 **`attr`**（属性乘算）：进入时 `_target[target_attr] *= (1 + value/100)` 并记录 orig；到期/刷新还原（与 slow 的"记录原值→改→还原"完全同构）。
- **value 可正可负**（+100 = +100%；-30 = -30%），正向增益/负向减益同一机制、同一行表数据。
- 叠加/免疫/max_stacks/同源刷新/异源独立：**全部沿用现有组件规则，零新增**。
- target_attr 在目标上不存在 → warn + 跳过（防脏数据崩游戏）。

### 4.3 target_attr 白名单（拆解时按消费点实测登记）

| target_attr | 消费点 | 现状 |
|---|---|---|
| damage_multiplier | weapon_controller / skill_controller / turret / orbit_weapon / melee_sweep | ✓ 全乘 |
| move_speed | player / enemy 移动 | ✓（slow 类型保留兼容；attr 为通用乘算通道，可表达加速） |
| armor | enemy_damage / player 平直减伤 | 加减法继续走 armor 类型；attr 乘算可选 |
| crit_chance / crit_damage | F-11 暴击体系 | 拆解时登记实际属性名，缺失则挂 TECH_DEBT |
| attack_speed | 武器发射间隔 | 拆解时登记实际属性名，缺失则挂 TECH_DEBT |

### 4.4 金手指状态化（一致性说明，不推翻 F-04）

- F-04 Debug 模式（↑+↓ 跳关 / debug_mult ×10 / 受伤 0.1%）为 2026-08-06 用户拍板实现，**本期保持现状**。
- 设计说明：金手指 = 攻击力 +900% 整局 attr buff 在概念上完全成立；未来若统一，elements 表加一行 + debug_console 改走 apply_effect 即可——本期不做，记 TECH_DEBT。

### 4.5 与 boss_phase_events 联动

- 事件类型新增 `buff`（§3.3）：Boss 血线 60% 弹横幅**同时**附加"狂暴"（attack+50% 10s）——演出 + 数值一表打通。
- 示例行：`invoker | 60 | 3 | buff | {"target":"self","effect":"frenzy","duration":10} | 1`（frenzy 为 elements 表一行：type=attr, value=50, target_attr=damage_multiplier, duration=10）

---

## 5. 特殊波参数化（可选批次）

- 现状：swarm_wave 在 enemy_spawner.gd:82 硬编码 `count *= 2`、HP ×0.5；curse/high_pressure/chest_enemy 等标记语义散落 wave_manager/event_manager。
- 方案（若拆解后成本可控，否则记 TECH_DEBT）：wave_generation 表（或新增 special_rules 表）加行：`special / count_mult / hp_mult / damage_mult`，spawner 读表替换 if/else。
- **本次不强求**：#2 拆解时评估，成本 > 0.5 天则只收 ①②③ 主目标，本项挂 TECH_DEBT_PLAN.md。

---

## 6. 数据管线改动

| 环节 | 改动 |
|---|---|
| GameData.xlsx | 新增 sheet：`spawn_points`、`boss_phase_events`；waves 表加 `spawn_set`、`spawn_order` 列；elements 表由策划按需加 type=attr 的 buff 行（如 frenzy） |
| tools/excel_export.py | SHEETS 注册两新表 + waves 新列；FK 校验（spawn_points 不存在 point_id / boss_phase_events 不存在 boss_id → 报错）；--check-only 只读缺陷（已知，顺手修或登记） |
| 生成 JSON | data/spawn_points.json、data/boss_phase_events.json（独立文件，结构同 sheet 平铺） |
| data_loader.gd | `get_spawn_points()` / `get_spawn_set(wave)` / `get_boss_phase_events(boss_id)` 接口 + 缓存 |
| 总览双份 | DATA_OVERVIEW.md + 总览 sheet 同步（excel_export.py --overview 既有机制） |
| DATA_DICT_GUIDE.md | 策划改数手册补两新表说明（收口后由 #3 或 #1 顺手更新） |

## 7. 运行时改动点

| 文件 | 改动 |
|---|---|
| enemy_spawner.gd | `_get_random_spawn_position()` → `_get_spawn_position(entry)`：按 spawn_set 点位队列轮换；表空回退随机（保留现函数兜底）；swarm 语义改读表（§4 落地时） |
| wave_manager.gd | 透传 spawn_set 给 spawner（spawn_wave 参数扩展，缺省兼容） |
| enemy.gd / enemy_damage.gd | `_check_phase_transition` 链上加演出事件触发（读 boss_phase_events，按阈值段执行 seq） |
| 演出执行器 | 新脚本 `boss_phase_player.gd`（或并入 enemy_boss.gd）：banner 仿 _show_elite_banner 范式；vfx/sfx 走 VfxPlayer/audio_manager 注册表；未知类型 warn + 跳过 |
| status_component.gd | `_apply`/`_revert` 新增 `attr` 分支：target_attr 乘算 + 还原（复用 slow 范式）；未知 target_attr warn + 跳过 |
| game_manager.gd | 不动（演出执行器自持横幅样式，或复用其静态横幅工具函数，拆解时定） |

## 8. 拆解要点（给 #2）

- **批次建议**：
  - 批 A：两新 sheet + excel_export.py 注册/校验 + 生成 JSON + DataLoader 接口 + 探针（解析/缺省回退/FK 报错）
  - 批 B：enemy_spawner 按点位生成改造 + 回归（重点：F-48 修复不回归、20 波零配置可跑）
  - 批 C：boss_phase_events 触发 + 演出执行器 + 探针（阈值触发/once/击杀不触发/未知类型跳过）
  - 批 D（可选）：特殊波参数化
  - 批 E：attr 正向状态（status_component 扩展 + elements 示例行 + 探针）+ boss_phase_events 的 buff 事件类型联动
- **决策点**（#2/#5 可提建议，必要时回用户拍板）：
  1. 默认 8 边缘点的具体 inset 值（推荐 40）
  2. Boss 登场点推荐 anchor(0.5, 0.3) 是否采纳
  3. dialogue 台词框是否本期做（可先用 banner 样式占位）
  4. 特殊波参数化是否本期纳入（成本评估后）
  5. attr 白名单属性名以消费点实测为准（crit/攻速属性若缺失则挂 TECH_DEBT）
- **验收锚点**：回归套件 52 项全绿；新增探针 ≥3 组；Excel 改 spawn_set/boss_phase_events 导出后游戏内实测生效（#4 测试 + #5 试玩各走一轮）。
