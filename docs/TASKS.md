# 《星骸回响》Star Echo · 每日可执行任务清单（TASKS）

> 供自动化 #2（任务拆解）更新、#3（方案确定与执行）读取实现。
> 状态标记：`[ ]` 未开始 · `[~]` 进行中 · `[x]` 完成 · `[!]` 受阻/需人工。
> 护栏：未定义当日任务前不写游戏代码；改前 git commit；改后跑 `tools/baseline_check.py`。

> ✅ **Day 5 已收口（2026-08-05 23:5x · #3）**：`day5_weapon_check.gd` **15 断言 0 失败** + baseline **BASELINE CLEAN** + 回归三件套全绿，提交 `5092874`（6 槽 / 查表升级 / 环绕武器 / 混合升级面板）。
> ✅ **Day 6 已收口（2026-08-06 01:5x · #3）**：阶段 A 集成测试完成 —— T-A 经验链路数据化（23 敌 exp_value + 透传 + 端到端探针 **14/14 CLEAN**）+ 回归四件套全绿（day2 32 / day3 16 / day4 21 / day5 15）+ 平衡校准（**实测曲线 Lv1→2=30**，chaser 2→3 / charger 3→4）+ 阶段 A 报告 `docs/REPORT_PHASE_A.md` + baseline **BASELINE CLEAN**，提交见本轮收口 commit。**P1 D6-T4 经验飘字亦已实装**（未顺延）。
> ✅ **Day 7 已收口（2026-08-06 03:3x · #3）**：阶段 B 首段完成 —— 11 把通用武器补 levels 8 条 + max_level=8（D7-T1）+ 33 把全部补 icon_index 分类映射（D7-T5）+ weapon.gd crit_chance/crit_damage 字段 + build_weapon_from_data 4 键消费 + _on_upgrade 3 行可选键消费（D7-T2）+ weapons.png 4 帧→40 帧 15 帧实绘+18 帧占位+7 帧空余（D7-T3）+ icon_atlas.gd 帧数 4→40（D7-T4）+ `day7_weapon_data_check` 探针 **13/13 CLEAN** + 回归五件套（day2 32 / day3 16 / day4 21 / day5 16 / day6 14）+ day5 探针同步更新（pistol 通用成长 → 合成裸武器 兜底测试）+ baseline **BASELINE CLEAN**，提交 `fc2a636`。
> ✅ **Day 8-9 已收口（2026-08-06 05:3x · #3）**：阶段 B 续段完成 —— 18 把全量武器补 `levels` 8 条 + `max_level=8`（D8-T1：`gen_weapons_day7.py` LEVELS +18 把 + verify 抽查扩展到 6 把 + force_field damage 恒 0 特例校验 + 顶层未动原则）+ 18 帧占位图标实绘替换（D8-T2：`gen_weapon_icons.py` +18 函数 + 新增 PURPLE/SHIELD 色 + 透明键 + 帧 33-39 空余保留）+ `day8_weapon_data_check.gd` 探针 **19/19 CLEAN**（JSON 全量 / 特例 / 装配 / 图标 / 回归 五段）+ 回归六件套全绿（day2 32 / day3 16 / day4 21 / day5 16 / day6 14 / day7 13）+ baseline **BASELINE CLEAN** + `gen_weapons_day7.py verify` → **33/33 levels + icon_index CLEAN**。30DAY_PLAN D7-D9「15 武器数据 + 精灵」至此**全量完成（33/33 把 Lv1-8 + 33 帧实绘图标）**。
> 🎯 **Day 8–9 已拆解（2026-08-06 05:1x · #2 第 9 轮）**：阶段 B 续段 = **18 把全量武器 levels + 18 帧图标实绘 + 全量数据回归**（见 Day 8-9 区）——W2 给 18 把通用武器补 `levels` 8 条 + `max_level:8`（fist/stick/dagger/hammer/flaming_knuckles/slingshot/crossbow/rocket_launcher/minigun/lightning_shiv/venom_staff/storm_staff/frost_nova/plasma_cannon/wrench/laser_turret/mech_arm/force_field，扩展 `gen_weapons_day7.py` LEVELS 表幂等 apply）；W3 18 帧占位图标逐帧替换实绘（扩展 `gen_weapon_icons.py`，含 force_field 护盾 / minigun 多管等特征）；W1 新建 `day8_weapon_data_check.gd` 探针（≥13 断言含 force_field damage 恒 0 特例）；W5 回归六件套。**纯数据 + 图标 + 探针日，零装配代码改动**（D7-T2 已铺路）。
> 🎯 **Day 7 已预拆解（2026-08-06 03:1x · #2 第 8 轮）**：阶段 B 首段 = **MVP 15 武器数据 + 装配消费 + 图标集**（见 Day 7 区）——W2 给 11 把通用武器补 `levels` 8 条（sword/chainsaw/pistol/smg/shotgun/sniper/wand/icicle/flamethrower/turret/landmine）+ 33 把补 `icon_index`；W1 装配消费补齐（crit_chance/crit_damage/pierce/icon_index）+ IconAtlas 帧数 4→40；W3 `weapons.png` 4 帧→40 帧（15 实绘 + 25 占位）；W5 新建 `day7_weapon_data_check.gd` 探针 + 回归。剩余 18 把归 Day 8-9（下轮拆解）。
> ✅ **Day 1 收口**（`7597d0b`）　✅ **Day 2 收口**（`edd0e9a`，32 断言 0 失败）　✅ **Day 3 收口**（`0dc2ece`，16/16 CLEAN）　✅ **Day 4 收口**（`eb8e2f5`，21/21 CLEAN，BUG-001 F1/F2 一并闭环）　✅ **Day 5 收口**（`5092874`，15/15 CLEAN）　✅ **Day 7 收口**（`fc2a636`，13/13 CLEAN + 回归五件套全绿）　✅ **Day 8-9 收口**（`> ✅ **Day 8-9 收口**（`d1e72f1`，19/19 CLEAN + 33/33 武器 Lv1-8 + 33 帧实绘图标 + 回归六件套全绿）`，19/19 CLEAN + 33/33 武器 Lv1-8 + 33 帧实绘图标 + 回归六件套全绿）
> 🔴 **Day 4 首段必做 BUG-001 F1/F2**（用户 19:50 反馈「第 2 关后全员静止」、19:53 确认留待下一轮 = 本日首段；已固化为 `D4-T7` / `D4-T8`，见 Day 4 区）
> ✅ **Day 3 已收口（2026-08-05 19:2x · #3）** —— `day3_skill_check.gd` **16 断言 0 失败（DAY3 SKILL CHECK CLEAN）** + `baseline_check` **BASELINE CLEAN** + `day2_hero_check` 回归 32/0 CLEAN，已 `git commit`（Day3 收口提交）。
> **19:15 修复记录**（此前 19:10 #1 实测 18 断言 4 失败 → 已全部闭环）：
>    - F1/F2（火球未命中）：headless 下 `body_entered` 物理碰撞不可靠 → 火球不触发中途命中，靠 **lifetime(1.4s)×speed(280) = 392px 寿命耗尽爆炸**。修正：测试敌人摆位 60px → **飞行终点 392px**（爆炸半径 90 覆盖）；另修复 `skill_controller.gd` 5 处 `:=` 类型推断错误（`var player` 无类型 → 成员访问为 Variant，`:=` 无法推断，改显式类型/去推断）
>    - F3（诺亚断言口径）：`day3_skill_check.gd` `noa` 用例改为期望 `try_cast == false`（T4 顺延占位不进冷却，符合定案）✅
>    - F4（莱恩双重还原）：测试脚本改为**单次释放**（CD 10s > duration 5s，真实游戏不可重叠触发；不做引用计数，避免过度设计）✅
> **产出清单**：`scripts/player/skill_controller.gd`（新建：cooldown_changed/skill_cast 信号、setup/_ensure_loaded/try_cast 分派、`_cast_fireball`、`_cast_blade_burst`、`_cast_deploy_turret` 静默桩）｜ `scenes/Player.tscn` +SkillController 节点 ｜ `player.gd:223` 转发 ｜ `main.gd:83 _setup_skill` ｜ `data/characters.json:143` `burn_duration:4.0` ｜ `tools/day3_skill_check.gd`（新建）
> `D3-T4` 炮台与 `D3-T6` HUD 按重排**顺延 Day 4 首段**（`D4-T5`/`D4-T6`），条目标 `[~]` 不阻塞推进。
>
> 🎁 **Day 4 已预拆解**（本轮 #2 完成，见 Day 4 区）——吸取 Day 2「#2 拆解晚于 #3 启动 → 空转一轮」教训，避免 #3 收口 Day 3 后无米下锅。Day 4 = 承接 `D3-T4`（炮台）+ `D3-T6`（HUD 冷却，P1）+ 经验/升级/Build 初版本体。

---

## 并发冲刺（starecho-sprint）已交付 · 2026-08-04

> 5 个并行 Agent（w1-code / w2-data / w3-art / w4-narrative / w5-qa）并发落盘，文件域隔离无冲突。
> 集成节点（team lead）完成 `project.godot` 接线（`run/main_scene` → `CharacterSelect.tscn`）与最终基线复验。

- [x] **集成基线复验**：`tools/baseline_check.py` → `BASELINE CLEAN`（import + runtime 双阶段，exit 0 / stderr 0）
- [x] w1-code：角色选择场景 `scenes/CharacterSelect.tscn` + `scripts/character_select.gd`（英雄 ID↔精灵别名 `PORTRAIT_ALIAS` 已桥接，缺图自动降级占位色块）
- [x] w2-data：`data/characters.json` +3 英雄（se_irene/noa/ren）、`weapons.json` +3 签名武器、`items.json` +2 进化核心
- [x] w3-art：`assets/sprites/characters/` 9 张英雄 PNG + `docs/ART_ANIME_SPEC.md`
- [x] w4-narrative：`data/events.json` 10 事件 + `docs/LORE.md`
- [x] w5-qa：`docs/TEST_REPORT.md`（baseline 双跑 CLEAN + 8/8 JSON 校验 + 交叉引用）
- [x] 数据缺陷修复：`gambler.starting_weapon` 悬空 `shuriken` → `dagger`（9/9 角色起始武器全部命中）

**冲刺遗留待办**：已于 2026-08-05 拆解并归位到 **Day 2 的 `D2-T1` / `D2-T3`**，此处不再重复维护（避免双源漂移）。

---

## 阶段 A · 核心循环对齐 & 手感打磨（Day 1–6）

### Day 1 — 框架基线 & 差异清单　✅【客观任务 4/4 完成 · 已收口】

- [x] 跑 `python tools/baseline_check.py`，确认输出 `BASELINE CLEAN`（集成节点复验 2026-08-04）

#### D1-T1【W1 主责】核对大纲 §5 操作 vs 现有输入映射
- [x] 在 `project.godot` 的 `[input]` 段新增主动技能动作 `skill_cast`（建议 `Space` + 鼠标右键双绑定）✅ 已落地（Space 物理键码 32 + 鼠标右键 button_index 2）
- [x] `scripts/player/player.gd`：预留 `_unhandled_input` / `Input.is_action_just_pressed("skill_cast")` 空实现挂钩（Day 3 填充逻辑，本日仅打桩不实现技能）✅ `_try_cast_skill()` 空挂钩已加（player.gd:119-128）
- **实测现状（本轮已核查，勿重复排查）**：`[input]` 原仅 6 个动作 —— `move_up/move_down/move_left/move_right`(WASD) + `ui_accept`(Z/Enter) + `ui_cancel`(Esc)；本日新增 `skill_cast` 后为 7 个
- **差异结论**：移动 ✅ 已具备；自动攻击 ✅ 已具备（鼠标方向自动射击，无需输入动作）；**主动技能 ❌→🟡 缺口已打桩**（输入动作 + 空挂钩，逻辑归 Day 3）——大纲 §5 三项操作里唯一缺口已闭环输入层
- **测试点**：`InputMap.has_action("skill_cast") == true` ✅；4 向移动动作零回归 ✅；`baseline_check` → `BASELINE CLEAN` ✅（改动后复验 2026-08-05）

#### D1-T2【W2 主责 / W1 协作】产出 `docs/DIFF_FRAMEWORK_STARECHO.md`
- [x] 新建该文件，按 6 章成文（本轮核查结论已备齐，直接落笔即可）✅ 已产出 `docs/DIFF_FRAMEWORK_STARECHO.md`（8 章：导言+§1~§6+风险+交付物）
  - [x] §1 输入操作差异 —— 引用 D1-T1 结论（`skill_cast` 已打桩）
  - [x] §2 角色差异 —— 9 英雄（原框架 6 + Star Echo 3），`starting_weapon` 交叉引用 **9/9 全部命中**；`se_irene/se_noa/se_ren` 已带 `skill` 字段；**三者均无 `sprite` 字段**，`character_select.gd` 目前靠硬编码 `PORTRAIT_ALIAS` 映射 → 建议 Day 2 补 `sprite` 字段收敛
  - [x] §3 武器差异 —— `weapons.json` 共 **32 把**（melee 8 / ranged / elemental / engineering 四类）；条目字段为 `damage/cooldown/range/crit_chance/crit_damage/scaling/knockback/life_steal/special`；**se_ 签名武器已含 Lv1-8 `level[]` + `evolution`，29 把旧武器缺 `level` 升级表** → 阻塞 Day 5 / Day 7–9（Day 10 进化 schema 已可用）
  - [x] §4 属性差异 —— 大纲 10 属性 vs `stats.json`（basic/offensive/economy）：攻速`attack_speed`/范围`range`/移速`speed`/暴击率`crit_chance`/暴伤`crit_damage`/生命`max_hp`/护甲`armor`/吸血`life_steal`/幸运`luck` **9 项直接对应**；**「攻击力」为唯一口径冲突**——现框架拆成 `melee_damage`/`ranged_damage`/`elemental_damage` 三系，需决策「聚合为统一攻击力」或「保留三系并在 UI 聚合展示」（Day 4 强化面板依赖此决策）
  - [x] §5 被动/道具差异 —— `items.json` 共 **47 项**（字段 `id/name/rarity/price/effects/tags`）；进化核心已就位 `se_flame_core`/`se_mech_core`/`elemental_core`；**缺被动槽位标识**，6 被动槽装配（Day 11–12）需补 `slot`/`is_passive` 区分道具与被动
  - [x] §6 缺失系统清单 —— 主动技能系统、XP/升级面板、6+6 槽、武器进化、随机节点地图、事件节点、精英、两阶段 Boss、遗物、局外养成
- **测试点**：文件存在且 6 章齐全 ✅；文中引用的所有 id（`se_star_flame`/`se_flame_core` 等）在对应 JSON 中可检索命中 ✅

#### D1-T3【W2】确认现有数据结构可复用
- [x] 将本轮实测结论固化进 D1-T2 §2/§3/§4/§5（无需另起文件）✅ 已固化
- **实测结论**：`characters.json` = `{characters:[9]}`、`weapons.json` = `{weapons:{4 类, 共 32}}`、`items.json` = `{items:[47]}`、`stats.json` = `{stats,formulas(15),leveling}`
- **判定：结构可复用 ✅**，全部为「增字段」而非「改结构」，`DataLoader` 无需重写；武器仅旧 29 把需补 `level`，被动需补 `slot` 标识

#### D1-EXIT【W5】当日出口
- [x] `python tools/baseline_check.py` → `BASELINE CLEAN` ✅（2026-08-05 改动后复验）
- [x] `docs/DIFF_FRAMEWORK_STARECHO.md` 存在且非空 ✅
- 备注：`docs/PROGRESS.md` 目前尚未生成（属自动化 #1 交付物，不阻塞 Day 1 出口）

### Day 2 — 角色选择 + 3 英雄　✅【客观任务完成 · 已收口】

- [x] 实现角色选择场景/界面（3 英雄：艾琳 Mage / 诺亚 Summoner / 莱恩 Melee）
      → `scenes/CharacterSelect.tscn` + `scripts/character_select.gd` 已落盘，`project.godot` 入口已指向该场景
- [x] 初始武器**数据**就位：`se_star_flame` / `se_auto_turret` / `se_star_blade`（已实测：9/9 英雄 `starting_weapon` 交叉引用全部命中）
- [x] 专属技能**数据**占位：`se_irene` / `se_noa` / `se_ren` 三英雄的 `skill` 字段已存在于 `characters.json`
- [x] `baseline_check` 通过（2026-08-04 集成节点复验 `BASELINE CLEAN`）

> ⚠️ 上述为**数据侧**完成；**代码侧消费链路仍未打通**——本轮已实测 `scripts/autoload/main.gd`（59 行）**零 hero/character 引用**。以下为 Day 2 真实剩余工作。

> 📌 **本轮实测基线（#3 勿重复排查）**
> - 节点路径：`Main`(Node2D) → `$World/Player`(CharacterBody2D，来自 `Player.tscn`) → `$World/Player/WeaponController`(Node，挂 `weapon_controller.gd`)
> - **执行顺序陷阱**：Godot 中子节点 `_ready()` **先于**父节点。`weapon_controller.gd:22-25` 的 `_ready()` 会先跑 `_equip_default_weapon()`（`:38-50` 硬编码「初始枪」），**早于** `main.gd:_ready()`。故注入必须是**替换**而非追加。
> - `DataLoader` 可用接口：`get_character(id)->Dictionary`(`:250`)、`get_weapon(id)->Dictionary`(`:209`)、`get_weapon_category(id)->String`(`:213`)
> - `characters.json` 9 英雄**全部无 `sprite` 字段**（0/9）；`assets/sprites/characters/` 实有 `elin|noah|lain` × `portrait|idle|walk` 共 9 张 + 遗留 `fighter_idle|fighter_walk`
> - `player.gd:176-200` `apply_stat_modifier()` **仅支持 9 个键**：`max_health/move_speed/armor/damage/attack_speed/crit_chance/range/regen/pickup_range` —— 三位 SE 英雄的 `passive` 键**几乎全部落在支持范围之外**（见 D2-T1c 映射表）

> 🔁 **本轮调度重排（2026-08-05 04:40 · 自动化 #1 进度分析）**
> **触发**：#3 于 04:20 轮**零代码产出** —— git 最后提交仍为 02:39 的 `7597d0b`（Day 1），实测 `scripts/autoload/main.gd` **0 处 hero/character 引用**、`weapon_controller.gd` **无 `equip_from_data`**、`characters.json` **0/9 有 `sprite`**、`PORTRAIT_ALIAS` 硬编码仍在（`character_select.gd:27`）。
> **原因研判**：#2 的 Day 2 细粒度拆解 **04:38** 才落盘，晚于 #3 的 **04:20** 启动 → #3 读到的是粗粒度旧版（Day 2 顶部 4 项已 `[x]`），误判为"本日已完成"而空转一轮。
> **重排原则**：把 Day 2 的 W1 五连项按「出口必需 / 可顺延」二分，保证**单轮可收口**，避免整日反复空转。
>
> | 优先级 | 任务 | 归属 | 说明 |
> |---|---|---|---|
> | **P0 出口必需** | `D2-T1a` 取 id + 兜底 · `D2-T1b` 起始武器注入 | W1 | 二者即可满足 `D2-EXIT` 的「三英雄起始武器 3/3 命中」断言 |
> | **P0 出口必需** | `D2-T2` 前半：`data/characters.json` 补 9× `sprite` 前缀字段 | W2 | 单文件、无跨域，与 W1 完全并行，不互相等待 |
> | P1 顺延允许 | `D2-T1c` 被动/惩罚注入 · `D2-T4` 玩家精灵切换 · `D2-T2` 后半（删 `PORTRAIT_ALIAS` 硬编码） | W1 | **不计入 Day 2 出口**；本轮未完成则顺延为 Day 3 首段 |
> | P2 空闲产能 | 补 `se_star_blade.evolution`（预支 Day 10） | W2 | W2 本日仅 1 项、产能闲置；Day 10 三英雄进化对齐正缺此一角 |
>
> **顺延依赖校验**：`D2-T1c` 产出的 `bonus_stats` 字典本就是 Day 3 技能系统的读数入口，合并进 Day 3 首段**不产生新阻塞**；`D2-T4` 依赖 `D2-T2` 的 `sprite` 字段，二者同为 P1，顺延后先后次序不变、无倒挂。
> **文件域校验**：W1 只写 `scripts/`，W2 只写 `data/characters.json` + `data/weapons.json`，**无跨域写冲突**。

#### D2-T1【W1 主责】`Main` 侧消费 hero id（Day 2 核心剩余项）

**D2-T1a — 取 id + 兜底**（`scripts/autoload/main.gd`）
- [x] 在 `_ready()` 内、`_start_game_delayed()`（`:39`）**之前**插入英雄解析段
- [x] 调用 `CharacterSelect.get_selected_character_id(self)` 取 id
      （接口已就绪：`character_select.gd:48` 静态方法；`class_name CharacterSelect` 为全局类，**无需 preload**；经 `get_tree().root` 的 `SELECTION_META` 元数据跨场景传递，`:201` 写入；未选择返回**空串**）
- [x] 空值/非法值兜底：回退默认英雄 `well_rounded`（已实测存在，`starting_weapon = "pistol"`），直开 `Main.tscn` 调试路径**禁止崩溃**
- [x] 建议在 `GameManager` 上暴露 `current_character_id` 供 Day 3 技能系统读取（与 `:22-27` 现有绑定风格一致）
- **测试点**：`root` 无 meta 时 id 解析为 `well_rounded` 且无 `push_error`

**D2-T1b — 起始武器注入**（`scripts/weapons/weapon_controller.gd`）
- [x] 新增公开方法 `equip_from_data(weapon_id: String) -> bool`：`DataLoader.get_weapon(id)` 取数据 → 构造 `Weapon` 资源 → **先 `equipped_weapons.clear()`** 再 `equip_weapon()`（覆盖 `_ready()` 已装的「初始枪」）
- [x] `main.gd` 侧取 `$World/Player/WeaponController` 调用之；返回 `false`（id 未命中）时保留默认武器并 `push_warning`，不崩
- [x] **JSON → `Weapon` 字段映射表**（`weapon.gd:14-34` 为准，照抄即可）：

  | weapons.json | Weapon 属性 | 换算 |
  |---|---|---|
  | `name` | `weapon_name` | 直传 |
  | `damage` | `base_damage` | 直传 |
  | `cooldown` | `fire_rate` | **`1.0 / max(cooldown, 0.01)`**（JSON 是「攻击间隔秒」，Weapon 是「次/秒」，**必须取倒数**） |
  | `range` | `attack_range` | 直传 |
  | `knockback` | `knockback` | 缺省 0 |
  | `max_level` | `max_level` | 缺省 5 |
  | `projectiles` | `projectile_count` | 缺省 1 |
  | `get_weapon_category(id)` | `weapon_type` | 直传分类串（`melee`/`ranged`/`elemental`/`engineering`） |
  | —（JSON 无） | `projectile_speed` | 保留默认 `400.0`；`lifetime` 由 `_spawn_projectile():117` 用 `range/speed` 自动推导，**不要手设** |

- **测试点**：选艾琳 → 首武器 `weapon_name == "炎星术"`、`base_damage == 6`、`fire_rate ≈ 1.818`；诺亚 → `se_auto_turret`；莱恩 → `se_star_blade`；`equipped_weapons.size() == 1`（默认枪已被清掉，不得叠成 2 把）

**D2-T1c — 被动 / 惩罚注入**（`scripts/player/player.gd`）
- [x] `main.gd` 取角色 `passive` + `penalty` 两个 Dictionary，逐键注入 `player`
- [x] **键映射表**（`apply_stat_modifier():177-199` 的 match 分支为唯一合法键）：

  | JSON passive 键 | 处理方式 |
  |---|---|
  | `max_hp` | → `apply_stat_modifier("max_health", v)` |
  | `speed_percent` | → `("move_speed", 1.0 + v/100.0, true)` 乘算 |
  | `crit_chance_percent` | → `("crit_chance", v/100.0)` 加算 |
  | `attack_speed_percent` | → `("attack_speed", 1.0 + v/100.0, true)` 乘算 |
  | `range` / `range_percent` | → `("range", …)` |
  | `armor` | → `("armor", v)` |
  | **其余未支持键** | 见下条 —— **禁止静默丢弃** |

- [x] `player.gd` 新增 `var bonus_stats: Dictionary = {}` 收纳**当前引擎未实现的键**（`elemental_damage` / `fire_damage_percent` / `burn_duration_percent` / `engineering` / `structure_hp_percent` / `summon_count` / `melee_damage` / `ranged_damage_percent` / `life_steal_percent` / `harvesting` …），Day 3 技能系统与 Day 4 强化面板直接读该字典
- [x] `penalty` 同表处理，值为负数直接走同一入口（艾琳 `melee_damage_percent:-50 / max_hp:-10`；诺亚 `attack_speed_percent:-15 / speed_percent:-5`；莱恩 `ranged_damage_percent:-50 / range:-20`）
- **测试点**：选莱恩 → `player.crit_chance ≈ 0.15`（基础 0.05 + 被动 10%）、`bonus_stats["life_steal_percent"] == 5`；选诺亚 → `attack_speed ≈ 0.85`；选艾琳 → `max_health == 90`；**9 位英雄逐一注入均无报错**

#### D2-T2【W2】英雄精灵字段收敛
- [x] `data/characters.json` 为 **9/9 英雄**补 `sprite` 字段。**统一 schema：资源名前缀字符串**（非路径、非字典），目录固定 `res://assets/sprites/characters/`，消费方按 `{prefix}_portrait.png` / `{prefix}_idle.png` / `{prefix}_walk.png` 组装
      - `se_irene → "elin"`　`se_noa → "noah"`　`se_ren → "lain"`
      - 遗留 6 位（`well_rounded/brawler/ranger/mage/engineer/gambler`）→ `"fighter"`（仅有 idle/walk，portrait 自动走占位色块）
      - **选型理由**：`character_select.gd:150-163` 已按「前缀 + 后缀」组装候选路径，`player.gd:34-35` 的 `idle_texture/walk_texture` 也只差同一前缀 —— 单字段同时服务立绘/idle/walk 三个消费点，改动面最小
- [x] 删除 `character_select.gd:27-31` 硬编码 `PORTRAIT_ALIAS`，`_load_portrait()` 改读 `DataLoader.get_character(id).get("sprite", "")`
- **测试点**：删除硬编码映射后角色选择界面 3 张立绘仍正确显示；把 `sprite` 改成不存在的前缀仍走占位色块降级、不崩

#### D2-T3【W3 / 环境项】英雄 PNG `.import` 生成
- [!] 9 张英雄 PNG 中 6 张缺 `.import`（实测仅 `fighter_idle/fighter_walk` 有）；无头 `--quit` 不生成，代码已优雅降级，**编辑器打开或出包时自动补全**
- 判定：**非阻塞**，不计入 Day 2 客观出口，编辑器一开即消解（Day 21–22 统一验收）

#### D2-T4【W1】玩家精灵按英雄切换（承接 D2-T2，依赖其 `sprite` 字段）
- [x] `main.gd` 在注入武器/被动的同时，按 `sprite` 前缀 `load()` 贴图赋给 `player.idle_texture` / `player.walk_texture`（`player.gd:34-35`），并**在赋值后重新调用** `player._setup_animation()`（`:59`）刷新 `AnimatedSprite2D`
- [x] 贴图缺失（`ResourceLoader.exists()` 为假）→ 保留 `Player.tscn` 内预设贴图，不覆盖、不报错
- **测试点**：三英雄进局后 `AnimatedSprite2D` 贴图各不相同；缺 `.import` 时（当前状态）走降级仍能进局

#### D2-T6【W1 · P0 补漏 · 04:50 发现 → ✅ 04:55 已修复】角色 `penalty` 未注入

> ✅ **已闭环**：`player.gd:100` 新增 `_apply_stat_dict(char_data.get("penalty", {}))`，与 `passive` 走同一入口（负值天然通用）；
> `_apply_stat_dict()` 对未映射键**叠加**而非覆盖（`bonus_stats[key] += amount`，正确处理 `passive`/`penalty` 命中同键的情况）；
> 顺序正确 —— 两次注入均在 `health = max_health`（`:104`）之前，`max_hp` 惩罚不会被满血覆盖。`BASELINE CLEAN` 复验通过。
> 遗留取证项：**9 英雄逐一注入的数值断言尚未跑**（艾琳 `max_health == 90` / 诺亚 `attack_speed ≈ 0.85` / 莱恩 `attack_range -20`）→ 并入 `D2-EXIT` 冒烟一起验。



> 🔴 **功能缺口**。`main.gd:_setup_character()` 仅调 `player.apply_character(data)`，而 `player.gd:apply_character()`（`:81-92`）只处理了 `passive` + `sprite`，**完全没有消费 `penalty`**。
> 实测 `grep -rn "penalty" scripts/` → **全域 0 命中**；`data/characters.json` 中 **8/9 英雄带 `penalty`**。
> 后果：玩家吃满被动加成却不吃任何惩罚 → **角色差异化设计失效、数值全面偏强**，并会污染 Day 4 强化面板与 Day 6 平衡初调的基准。**必须在 Day 3 之前补上。**

- [x] `player.gd:apply_character()` 补一行 `_apply_penalty(char_data.get("penalty", {}))` ✅（实为 `_apply_stat_dict(char_data.get("penalty", {}))`，与 passive 同入口；#3 04:37 验证：艾琳 max_health==90 / 诺亚 attack_speed≈0.85 / 莱恩 bonus_stats[life_steal_percent]==5 全命中）
- [x] 复用 `STAT_MAP` 机制（已重命名 `PASSIVE_MAP`→`STAT_MAP`），未映射键叠加收纳进 `bonus_stats` ✅
- [x] **执行顺序**：`penalty` 在 `health = max_health`（`:104`）**之前**应用 ✅（`apply_character` 先 passive 再 penalty 再赋值 health）
- **待注入清单（实测 8/9）**：`brawler{range:-50}` · `ranger{max_hp:-25}` · `mage{melee_damage_percent:-100, ranged_damage_percent:-100, engineering:-50}` · `engineer{attack_speed_percent:-20, melee_damage:-10}` · `gambler{damage_percent:-30, attack_speed_percent:-20}` · `se_irene{melee_damage_percent:-50, max_hp:-10}` · `se_noa{attack_speed_percent:-15, speed_percent:-5}` · `se_ren{ranged_damage_percent:-50, range:-20}` ✅ 全量注入零报错（day2_hero_check 9 英雄逐一进局 PASS）
- **测试点**：艾琳 → `max_health == 90`；诺亚 → `attack_speed ≈ 0.85`；莱恩 → `attack_range` 减 20；9 英雄逐一注入零报错 ✅ 实测通过（fire_rate 取倒数、crit_chance 0.05+0.10=0.15、life_steal_percent 收进 bonus_stats）

#### D2-T7【W3 · 美术债 · 顺延 Day 21–22】遗留 6 英雄缺真立绘

> ~~schema 口径偏离~~ —— **该项 04:55 已自行收敛作废**：#3 最终落地为拆解规定的「**资源名前缀字符串**」
> （实测 `se_irene→"elin"` / `se_noa→"noah"` / `se_ren→"lain"` / 遗留 6 位→`"fighter"`），与 `D2-T2` 约定一致，**无需回写文档**。

- [!] 遗留 6 位英雄（`well_rounded/brawler/ranger/mage/engineer/gambler`）仅有 `fighter_idle/walk`，**无 portrait 立绘** → 角色选择界面走占位色块降级
- 判定：**非阻塞**，登记为美术债，Day 21–22 统一决策（补齐真立绘 or 明确接受占位）

#### D2-T5【W2 · 空闲产能 / P2】补 `se_star_blade.evolution`（**已转出 → Day 10**）
- [!] `data/weapons.json` 中 `se_star_blade` 缺 `evolution` 字段：现有 `se_flame_core→炎星术`、`se_mech_core→自动炮台` 已有 `evolution` 绑定，`elemental_core` 无绑定；星刃缺专属剑刃核心，强行挂 `elemental_core` 语义错位，故**拒绝注入错误数据关系**
- [!] 对应进化核心：星刃缺专属核心；是否新增 `se_blade_core` 属进化系统设计决策
- 判定：**不计入 Day 2 出口**。原为 `[~]` 在进行中，08-05 06:35（#2 第 3 轮）**改标 `[!]` 并转出为 Day 10 的 `D10-PRE` 条目**——技术决策依赖进化系统本体，留在 Day 2 会造成目标日定位被永久钉死在已完工的一天（双源漂移）

#### D2-EXIT【W5】当日出口
- ✅ **出口口径（04:40 重排后）**：仅需 **P0 三项**（`D2-T1a` / `D2-T1b` / `D2-T2` 前半）落地即判定 Day 2 通过；P1 三项顺延 Day 3 首段，**不阻塞目标日推进**
- [x] `python tools/baseline_check.py` → `BASELINE CLEAN`（2026-08-05 04:40 复验：import PASS + runtime PASS，exit 0 / stderr 0）—— 改动后需再跑一次
- [x] `python tools/baseline_check.py` → `BASELINE CLEAN`（import + runtime 双阶段，exit 0 / stderr 0）—— #3 04:37 本轮复验 PASS
- [x] **无头三英雄冒烟**（`tools/day2_hero_check.gd`）：32 项断言 0 失败 → `DAY2 HERO CHECK CLEAN`；起始武器命中率 **4/4**（艾琳炎星术 / 诺亚自动炮台 / 莱恩星刃 / 兜底手枪）
- [x] 直开 `Main.tscn`（无 meta）零 error，兜底英雄 `well_rounded` 生效，无 `push_error` ✅
- ⚠️ 「三英雄手感差异是否明显」属**主观项**，不计入本日出口，由 #5 收进 `PLAYTEST_CHECKLIST.md`

### Day 3 — 主动技能机制　🎯【本轮目标日 · 已拆解到函数级 · 2026-08-05 06:35】	✅【客观任务完成 · 已收口 · 2026-08-05 19:2x】

> **护栏**：改前 `git commit` 存档；改后 `python tools/baseline_check.py` 必须 `BASELINE CLEAN`。
> **文件域**：W1 写 `scripts/` `scenes/`；W2 只写 `data/characters.json`；**无跨域冲突**。
> **前置全部实测确认**：`skill_cast` 已注册（物理键码 32 + 鼠标右键 button_index 2）｜`player.gd:219-227` `_unhandled_input`+`_try_cast_skill()` 空桩已在位｜`GameManager.current_character_id`（`game_manager.gd:30`）与 `player.character_id`（`player.gd:96`）双通道可读英雄｜`player.bonus_stats`（`player.gd:69`）为技能读数入口。

#### 本日总定案（先读，避免执行期临场决策）
| 议题 | 定案 | 依据 |
|------|------|------|
| 技能逻辑放哪 | **新建 `scripts/player/skill_controller.gd`，作为 Player 子节点**，与 `WeaponController` 同层同构 | `Player.tscn:23` 已有 WeaponController 范式；避免 `player.gd` 继续膨胀 |
| 「资源/法力」做不做 | **本日只做冷却，不做法力** | `characters.json` 三技能均无 `cost`/`mana` 字段，**不臆造数值** |
| 火球用新场景还是扩展 | **扩展现有 `projectile.gd`**，新增可选字段，默认值 = 现有行为 | 已是 Area2D+`body_entered`，新增场景会翻倍维护面；`explosion_radius=0` 保证既有武器**零回归** |
| AOE 判定方式 | **遍历 `GameManager.enemy_spawner.enemies_container` 算距离**，不用物理查询 | 复用 `weapon_controller.gd:126-137` 现成范式；无头测试下物理帧不可靠 |
| 燃烧 DoT 载体 | **`enemy.gd` 新增最小状态机 `apply_status()`** | 实测 `enemy.gd` **零** DoT/status 实现，是真实缺口，不是重复造轮子 |
| 技能 VFX | 复用现有 `crit`（火球爆炸）/ `hit`（炮台开火） | `vfx_player.gd:17-21` 仅 5 种特效，**专属 VFX 属 Day 23**，本日不越界 |

---

#### 🔁 本轮调度重排（2026-08-05 06:47 · 自动化 #1 进度分析）

> **触发**：Day 3 客观进度 0/8，且 **W1 单点承担 7 项、W2 仅 1 项、W3/W4 空闲**——负载严重失衡，单轮一次性吞下 7 项极可能重演 Day 2 的「整日空转」。
> **重排原则**：① 先补硬缺口（`D3-T2b`）；② 按「**最小可验闭环**」切出 P0，保证单轮可收口；③ 重活（`T4` 新建 2 文件）与非功能项（`T6` HUD）顺延。

| 优先级 | 任务 | 归属 | 说明 |
|---|---|---|---|
| **P0 ①** | `D3-T1` 技能控制器骨架 | W1 | 一切技能的载体，无它则 T3/T4/T5 全部无处挂 |
| **P0 ②** | `D3-T2` `projectile.gd` 爆炸 AOE + 元素附着 | W1 | 火球依赖；默认值 = 现有行为，既有武器零回归 |
| **P0 ③** | **`D3-T2b` `enemy.gd` 状态机 `apply_status()`**（**本轮新增**） | W1 | **硬缺口**：不补则燃烧静默失效 + `D3-EXIT` 断言 5 必挂 |
| **P0 ④** | `D3-T5` 莱恩「星刃爆发」 | W1 | **最轻**（纯 buff 数值 + 计时，无新建文件）——提前做可**最快验证 T1 骨架是否正确**，失败时返工成本最低 |
| **P0 ⑤** | `D3-T3` 艾琳「炽星火球」 | W1 | 依赖 T2 + T2b；完成后「技能系统 + AOE + DoT」全链路首次贯通 |
| **P0 ⑥** | `D3-T7` `characters.json` 补 `burn_duration` + 元素口径收敛 | W2 | 单文件、与 W1 完全并行，不互相等待 |
| P1 顺延 | `D3-T4` 诺亚「紧急部署」+ 炮台实体 | W1 | **工作量最大**（新建 `turret.gd` + `Turret.tscn` + 索敌/存活/摆位）；未完成则顺延 Day 4 首段 |
| P1 顺延 | `D3-T6` HUD 技能冷却指示 | W1 | 纯表现层，技能功能本身在 T1–T5 已客观可验 |
| P2 空闲产能 | W3 可预支 `D2-T7` 美术债（6 遗留英雄立绘）或 Day 23 火球/召唤 VFX 素材 | W3 | **不计入 Day 3 出口**；`assets/sprites/` 独占域，与 W1/W2 零冲突 |

> **顺延依赖校验**：`D3-T4` 产出的 `Turret` 与 Day 4「XP/升级」无耦合，顺延至 Day 4 首段**不产生新阻塞**；`D3-T6` 仅读 `SkillController` 的 `cooldown_changed` 信号（T1 已定义），顺延后接口不变、无倒挂。
> **文件域校验**：W1 只写 `scripts/` + `scenes/`，W2 只写 `data/characters.json` + `data/elements.json`，W3 只写 `assets/sprites/` —— **无跨域写冲突**。
> **出口口径调整**：见本日 `D3-EXIT` 内「P0 收口口径」——断言 3（Turret 数 == 3）随 `D3-T4` 一并顺延，不阻塞目标日推进。

---

#### ✅ 19:08 #2 第 4 轮 · P0 实现落点实测（#3 免重复排查，直接跳到 EXIT 测试）

> **结论**：P0 六项实现已全部落地且接线齐备，**任务条目保持 `[~]`（待 EXIT 测试闭环后再标 `[x]`）**。
> **剩三件事**：建 `day3_skill_check.gd` → 跑断言 + 回归 + baseline → `git commit`。实现落点如下：

| 任务 | 落点（文件:行号） | 核验要点 |
|---|---|---|
| D3-T1 骨架 | `skill_controller.gd` 全文（信号 :9-10 / setup :30 / _ensure_loaded :36 / _process :43 / can_cast :51 / try_cast :55 / 分派表 :61-70） | 未知 id → warning 不进冷却 ✅；`_cd_total` 读 `skill.cooldown` ✅ |
| D3-T1 接线 | `Player.tscn:27` SkillController 节点 ｜ `player.gd:223-227` 转发（get_node_or_null + has_method 守卫）｜ `main.gd:83-86 _setup_skill`（节点缺失只 warning） | 三条全在 ✅ |
| D3-T2 爆炸 AOE | `projectile.gd:16-20` 5 导出字段（默认=现有行为）｜ `_explode()` :72（`_exploded` 守卫 :73、距离判定 :81、状态附着 :85-86）｜ 命中 :64 与寿命耗尽 :53 双路径触发 | 普通弹丸 `explosion_radius=0` 零回归 ✅ |
| D3-T2b 状态机 | `enemy.gd:125 _status` ｜ `apply_status` :202（max 刷新不叠加）｜ `_update_status` :224（:137 调用，先收集后 erase）｜ `has_status` :214 ｜ `get_status_time_left` :218 | 私有字段不直接断言，用公开查询 ✅ |
| D3-T3 火球 | `skill_controller.gd:78-113 _cast_fireball`（伤害 × `player.damage_multiplier` :93、dps = dot + bonus×dot_scaling :87-91 只读 `elements.json`、`initialize` 传入 9 键 :96-106、`_get_aim_direction` :178 鼠标/最近敌/UP 三级回退） | 艾琳 passive `elemental_damage:8` → dps = 4.6 ✅ |
| D3-T5 星刃爆发 | `skill_controller.gd:123-146`（攻速 ×1.5 乘法通道 :132、`_restore_blade_burst` 用 `1.0/1.5` 逆元还原 :144、`is_instance_valid(player)` 守卫 :141、`orbit_blade_count` 埋点 :135/:146） | 连续释放不漂移（逆元）✅ |
| D3-T7 数据 | `characters.json:143` `"burn_duration": 4.0` ｜ 注释「技能覆写通用 3s 基准（D3-T7b 案 A）」在 `skill_controller.gd:84` | 案 A 落地：`elements.json.duration=3` 保留为通用基准 ✅ |

---

#### D3-T1【W1 · P0】技能控制器骨架 `scripts/player/skill_controller.gd`（新建）　🟡 实现已落地（19:08 实测），待 EXIT 验证
- [x] 新建脚本，`extends Node`；在 `scenes/Player.tscn` 内 `WeaponController` **同层**添加节点 `SkillController`
- [x] 状态字段：`var skill_data: Dictionary = {}` / `var _cd_left: float = 0.0` / `var _cd_total: float = 0.0` / `var player: Node2D`
- [x] 信号：`signal cooldown_changed(left: float, total: float)`、`signal skill_cast(skill_id: String)`
- [x] `_ready()`：`player = get_parent() as Node2D`（**禁止**在此读 `player.character_id`——子节点 `_ready()` 早于父节点，此刻英雄尚未装载，与 D2 踩过的坑同源）
- [x] `setup(char_data: Dictionary) -> void`：取 `char_data.get("skill", {})` 存入 `skill_data`，`_cd_total = float(skill_data.get("cooldown", 0.0))`，发一次 `cooldown_changed(0.0, _cd_total)`
- [x] `_ensure_loaded() -> void`：`skill_data` 为空时兜底自查 `DataLoader.get_character(GameManager.current_character_id)`——保证**直开 `Main.tscn` 调试路径**技能仍可用
- [x] `_process(delta)`：`_cd_left > 0` 时递减并 `cooldown_changed.emit()`；归零时 clamp 到 0（禁止负数）
- [x] `can_cast() -> bool`：`_cd_left <= 0.0 and not skill_data.is_empty()`
- [x] `try_cast() -> bool`：`_ensure_loaded()` → `can_cast()` 失败返回 `false`（**静默，不刷 warning**，玩家会狂按）→ 按 `skill_data.id` 分派 → 成功则 `_cd_left = _cd_total` + `skill_cast.emit(id)`
- [x] 分派表（`match str(skill_data.get("id", ""))`，未知 id → `push_warning` 且不进冷却）：
  | skill id | 处理函数 | 归属任务 |
  |----------|----------|----------|
  | `se_skill_fireball` | `_cast_fireball()` | D3-T3 |
  | `se_skill_deploy_turret` | `_cast_deploy_turret()` | D3-T4 |
  | `se_skill_blade_burst` | `_cast_blade_burst()` | D3-T5 |
- [x] `scripts/player/player.gd:224` `_try_cast_skill()` 改为转发：取 `get_node_or_null("SkillController")`，有则 `.try_cast()`，无则原样 `pass`（**保留空实现分支**，防 Player.tscn 未更新时崩）
- [x] `scripts/autoload/main.gd:_setup_character()` 在 `player.apply_character(data)` **之后**、`_equip_starting_weapon()` **之前**插入 `_setup_skill(data)`：取 `player.get_node_or_null("SkillController")` 调 `setup(data)`，节点缺失只 `push_warning` 不阻断
- 测试点：三英雄各自 `_cd_total` == 8.0 / 12.0 / 10.0；`well_rounded`（无 `skill` 字段）`can_cast()` 恒 `false` 且**不报错**

#### D3-T2【W1 · P0】`projectile.gd` 扩展：爆炸 AOE + 元素附着　🟡 实现已落地（19:08 实测），待 EXIT 验证
- [x] 新增导出字段（**全部给默认值 = 现有行为**，保证既有武器零回归）：
  - `@export var explosion_radius: float = 0.0`（0 = 不爆炸）
  - `@export var explosion_damage: float = 0.0`
  - `@export var status_type: String = ""`（`""` = 不附着）
  - `@export var status_duration: float = 0.0`
  - `@export var status_dps: float = 0.0`
- [x] `initialize(props)` 补齐上述 5 键的读取（沿用现有 `if props.has(...)` 写法，**不改签名**）
- [x] 新增 `_explode() -> void`：`explosion_radius <= 0.0` 直接 return；否则遍历 `GameManager.enemy_spawner.enemies_container.get_children()`，`is_instance_valid(e) and e.is_alive` 且 `global_position.distance_to(e.global_position) <= explosion_radius` → `e.take_damage(explosion_damage)`，并在 `status_type != ""` 时调 `e.apply_status(status_type, status_duration, status_dps)`（**先 `has_method` 守卫**）
- [x] `_explode()` 末尾 `VfxPlayer.spawn(GameManager.vfx_container, global_position, "crit")`，`vfx_container` 为 null 时跳过
- [x] 调用时机两处：`_on_body_entered()` 命中后**销毁前**调一次；`_physics_process()` 寿命耗尽 `queue_free()` **前**调一次（火球打空也要炸）
- ⚠️ **防重复爆炸**：加 `var _exploded: bool = false` 守卫，两条路径都可能触发
- 测试点：普通武器弹丸（`explosion_radius=0`）行为与 Day 2 完全一致；`pistol` 伤害数值不变

#### D3-T2b【W1 · P0】`enemy.gd` 最小状态机 `apply_status()`（**06:47 #1 新增 · 补任务清单硬缺口**）　🟡 实现已落地（19:08 实测），待 EXIT 验证

> 🔴 **为何必须新增**：本日「定案表」已把燃烧 DoT 载体定为「`enemy.gd` 新增最小状态机 `apply_status()`」，
> 但 `D3-T1`～`D3-T7` **无任何一条任务承载该实现**；`D3-T2` 只写了「先 `has_method` 守卫」——
> 守卫的后果是**方法不存在时静默跳过、不报错**，燃烧永远不生效，且 `D3-EXIT` 断言 5「`_status` 内含 `fire`」**必然失败**。
> **实测取证**（06:47）：`grep -rn "status\|_dot\|burn\|debuff" scripts/enemy/enemy.gd` → **0 命中**，零实现确认。
> **依赖次序：必须先于 `D3-T3` 落地**，否则 T3 写完也验不出燃烧。

- [x] `scripts/enemy/enemy.gd` 新增字段 `var _status: Dictionary = {}`，结构 `{ "<type>": {"left": float, "dps": float} }`
- [x] 新增 `func apply_status(type: String, duration: float, dps: float) -> void`：
      同类型状态**取较长时长 + 较高 dps**（`max()` 刷新，**不叠加多层**）——避免火球连击导致 DoT 无限堆叠
- [x] 在 `_physics_process(delta)` 内（`:131`，**现有 `if not is_alive or _is_dying: return` 守卫之后**）调 `_tick_status(delta)`
- [x] `func _tick_status(delta) -> void`：逐条 `left -= delta` 并 `take_damage(dps * delta)`；`left <= 0` 时 `erase()`
      - ⚠️ **遍历时删除的坑**：先收集待删 key 到数组，循环结束后统一 `erase()`，**禁止在 `for` 内直接 `erase`**
      - ⚠️ `take_damage()` 可能触发死亡 → 每次调用前 `if not is_alive: return`，防止对已死敌人持续结算
- [x] 新增 `func has_status(type: String) -> bool`（供 `D3-EXIT` 断言 5 与 Day 17 精英免疫读取）
- [x] **不做**元素反应（`elements.json.element_reactions` 归 Day 7–9 元素武器），本日仅单状态 DoT
- 测试点：`apply_status("fire", 4.0, 4.6)` 后敌人 `health` 每帧下降；4 秒后 `has_status("fire") == false`；DoT 击杀敌人时**不重复触发死亡逻辑**（`_is_dying` 守卫生效）；未附着状态的敌人 `_status` 恒为空、`_tick_status` 零开销

#### D3-T3【W1 · P0】艾琳「炽星火球」`_cast_fireball()`　🟡 实现已落地（19:08 实测），待 EXIT 验证
- [x] 读数：`damage` 30 / `radius` 90 / `element_type` `"fire"`（均来自 `skill_data`，缺省值兜底）
- [x] 燃烧时长读 `skill_data.get("burn_duration", 4.0)`（**依赖 D3-T5 补字段**；未补时 4.0 兜底，与 description「燃烧(4秒)」一致）
- [x] 燃烧 dps 口径（唯一算法，取自 `elements.json.elemental_status.fire`：`dot=3, dot_scaling=0.2`）：
  ```
  dps = 3.0 + player.bonus_stats.get("elemental_damage", 0.0) * 0.2
  ```
  艾琳 passive `elemental_damage: 8` → **dps = 4.6**，4 秒共 18.4 —— 这正是 D2-T1c 埋下 `bonus_stats` 的第一个消费方，**闭环**
- [x] 伤害套玩家倍率：`damage * player.damage_multiplier`（对齐 `weapon_controller.gd:169-170` 现有口径）
- [x] 生成：`preload("res://scenes/Projectile.tscn")` 实例化 → `initialize({speed:280, damage:<直击伤害>, lifetime:1.4, pierce:0, explosion_radius:90, explosion_damage:<同上>, status_type:"fire", status_duration:4.0, status_dps:4.6})`
- [x] 挂载父节点与朝向：复用 `weapon_controller.gd:33-40 _find_container()` 同策略（`World/Projectiles` 优先，回退 `World`）；方向 = `player.get_global_mouse_position()` 归一化，鼠标贴身（< 6.0）时回退最近敌人 → 再回退 `Vector2.UP`（**照抄 `_get_aim_direction()`**，避免两套瞄准口径）
- 测试点：CD 内二次按键无第二发火球；半径 90 内**所有**敌人同时掉血；`bonus_stats` 无 `elemental_damage` 的英雄不崩（dps 退化为 3.0）

#### D3-T4【W1 · P1 顺延 Day 4 首段】诺亚「紧急部署」`_cast_deploy_turret()` + 炮台实体　🟡 已占位（`skill_controller.gd:117` 返回 false 不进冷却），实体实现移至 **Day 4 `D4-T5`**
- [x]（Day 4 收口） 新建 `scripts/weapons/turret.gd`（`extends Node2D`）+ `scenes/Turret.tscn`
- [x]（Day 4 收口） 炮台数值**全部来自** `DataLoader.get_weapon("se_auto_turret")`（实测 `damage:5 / cooldown:0.5 / range:220`），**禁止硬编码**
- [x]（Day 4 收口） 炮台行为：`_process` 冷却计时 → 射程内索敌（复用 `_find_nearest_enemy()` 范式）→ 生成 `Projectile`（`speed:400, lifetime:range/speed`）→ 无敌人则空转不开火
- [x]（Day 4 收口） 存活：`duration` 取 `skill_data.get("duration", 15.0)`，到期 `queue_free()`；**每帧递减写在 `_process`，禁止用 `Timer` 节点**（无头测试下 Timer 依赖 SceneTree 计时更易漂）
- [x]（Day 4 收口） 部署数量定案：`skill_data.summon_count`(2) **+** `player.bonus_stats.get("summon_count", 0.0)`(诺亚 passive = 1) = **3 台**——passive `summon_count: 1` 明确写在 `characters.json`，属有据加成非臆造
- [x]（Day 4 收口） 摆位：以玩家为心、半径 40px 圆周**均布**（`TAU / count * i`）
- [x]（Day 4 收口） 挂载：`player.get_parent()`（即 `World`）——**不挂 Player 子节点**，炮台是「部署」语义，不得跟随玩家移动
- [x]（Day 4 收口） 炮台外观：`vfx_player.gd` 无炮台图，**用 `Polygon2D` 或运行时 `Image` 画占位方块**（对齐 `projectile.gd:57 _make_bullet_texture()` 的运行时绘制范式），真精灵登记为 Day 21–22 美术债
- 测试点：释放后 `World` 下 Turret 节点数 == 3；15 秒后归 0；炮台在玩家跑开后**留在原地**

#### D3-T5【W1 · P0】莱恩「星刃爆发」`_cast_blade_burst()`　🟡 实现已落地（19:08 实测），待 EXIT 验证
- [x] 读 `skill_data.effects`（实测 `{orbit_blade_count: 3, attack_speed_percent: 50}`）与 `duration`(5.0)
- [x] 攻速 buff：`player.apply_stat_modifier("attack_speed", 1.5, true)`；5 秒后**用乘法逆元还原** `apply_stat_modifier("attack_speed", 1.0 / 1.5, true)`
  - ⚠️ **禁止用加减还原**：`attack_speed` 在 `player.gd:286-287` 是乘法通道，加减会导致反复释放后数值漂移
- [x] 计时用 `await get_tree().create_timer(duration).timeout`；`await` 后**必须** `if not is_instance_valid(player): return`（玩家可能已死，否则 5 秒后访问已释放对象报错）
- [x] `orbit_blade_count`：`player.bonus_stats["orbit_blade_count"] += 3`，到期 `-= 3`
- 🔶 **本日可见性边界（必须写进验收口径，防 W5 误判）**：环绕刃**渲染机制尚不存在**（`se_star_blade.blade_count/orbit_radius/orbit_speed` 数据已齐，但环绕武器逻辑属 **Day 5 武器 6 槽挂载**）。故莱恩技能本日为「**攻速 buff 可见 + 刃数字段埋点**」，Day 5 环绕武器实现时自动消费 `bonus_stats.orbit_blade_count`。**不在本日臆造环绕刃渲染**
- 测试点：释放瞬间 `attack_speed` == 基线 × 1.5；5.01 秒后**精确回到**基线（误差 < 0.001）；连续释放 3 次后仍不漂移

#### D3-T6【W1 · P1 顺延 Day 4 首段】HUD 技能冷却指示　🟡 未做，移至 **Day 4 `D4-T6`**（P1，不阻塞出口）
- [x]（Day 4 收口） `scenes/HUD.tscn` 在 `MarginContainer/VBoxContainer/BottomBar` 下新增 `SkillSlot`（`TextureRect` + 子 `Label` 显示剩余秒数，样式对齐现有 `WeaponSlot0`）
- [x]（Day 4 收口） `scripts/ui/hud.gd` 新增 `_on_skill_cooldown_changed(left, total)`：`left <= 0` 显示「就绪」并满亮度；否则显示 `"%.1f" % left` 且 `modulate` 压暗到 0.4
- [x]（Day 4 收口） 连接时机：`_ready()` 内 `await get_tree().process_frame` 后取 `GameManager.player.get_node_or_null("SkillController")` 再 connect（**HUD 与 Player 的 `_ready` 顺序不保证**）；取不到只 `push_warning` 不崩
- 判定：P1，不阻塞 Day 3 出口（技能功能本身在 T1–T5 已客观可验）

#### D3-T7【W2 · P0】`characters.json` 补显式技能字段　🟡 实现已落地（19:08 实测：`:143` `burn_duration:4.0`），待 EXIT 验证
- [x] `se_irene.skill` 补 `"burn_duration": 4.0`——**当前 4 秒只写在 `description` 文本里，代码无法读取**，属真实数据缺口（`se_noa` 的 `duration:15.0`、`se_ren` 的 `duration:5.0` 均已显式，仅艾琳缺）
- [x] 复核三技能 schema 一致性：`id/name/type/cooldown` 四键 3/3 齐全（实测已齐，仅确认不改）
- [x] **不新增** `cost`/`mana`/`resource_type` 字段——本日不做资源系统，避免注入无消费方的死数据

**🟡 D3-T7b — 元素状态时长口径收敛（06:47 #1 新增）**

> **冲突实测**：`data/elements.json:elemental_status.fire` = `{"duration": 3, "dot": 3, "dot_scaling": 0.2}`，
> 而艾琳 `skill.description` 写「燃烧(**4**秒)」、`D3-T3` 定 `status_duration:4.0`、`D3-T7` 要补 `burn_duration:4.0`。
> **同一个 `fire` 燃烧状态存在 3 秒与 4 秒两个口径** —— `D3-T3` 恰好是「dps 取 `elements.json`、duration 取 description」的混合读法，
> 若原样落地，`elements.json.duration:3` 沦为死数据；等 Day 7–9 通用元素武器按 `elements.json` 读到 3 秒时，
> **同一燃烧 buff 会出现两种时长**，Day 13「10 属性公式校验」必然翻车。

- [x] **二选一并写明理由**（推荐 A）：
      - **A · 技能显式覆写**（推荐）：保留 `elements.json.duration = 3` 作为**通用元素武器基准**，艾琳技能 `burn_duration: 4.0` 视为**英雄技能特权加成**，
        并在 `D3-T3` 读数处加注释 `# 技能覆写通用 3s 基准，见 D3-T7b`。理由：改动面最小，且「英雄技能强于通用武器」符合设计直觉
      - B · 统一为 4 秒：改 `elements.json.fire.duration = 4`。**风险**：该字段可能已被其它元素配置交叉引用，需先 `grep -rn "elemental_status" scripts/ data/` 确认消费方
- [x] 无论选哪个，**dps 公式唯一化**：`dps = dot + bonus_stats.elemental_damage * dot_scaling`，`dot`/`dot_scaling` **只从 `elements.json` 读**，禁止在技能数据里另写一份
- 文件域：`data/characters.json` +（若选 B）`data/elements.json`，与 W1 无冲突

#### D3-EXIT【W5】当日出口

> ✅ **P0 收口口径（06:47 重排后）**：落地 **P0 六项**（`T1` / `T2` / `T2b` / `T5` / `T3` / `T7`）+ 下列断言 **1·2·4·5·6** 全过，即判定 Day 3 通过、推进 Day 4。
> 断言 **3（Turret 数 == 3）随 `D3-T4` 一并顺延至 Day 4 首段**，`D3-T6`（HUD）不计入出口。

- [x] `python tools/baseline_check.py` → `BASELINE CLEAN`（import + runtime 双阶段，exit 0 / stderr 0）
- [x] 新建 `tools/day3_skill_check.gd` 无头断言（照搬 `tools/day2_hero_check.gd` 的 `extends SceneTree` + 分帧推进骨架），覆盖：
  1. 三英雄 `SkillController._cd_total` 分别 == 8.0 / 12.0 / 10.0　【P0】
  2. `try_cast()` 首次返回 `true`，紧接第二次返回 `false`（冷却生效）　【P0】
  3. 诺亚释放后 `World` 下 Turret 节点数 == **3**　【⏭ 随 `D3-T4` 顺延 Day 4，本日不判】
  4. 莱恩释放后 `attack_speed` == 基线 × 1.5，且到期精确还原　【P0】
  5. 艾琳火球爆炸后半径内敌人 `health` 下降，且 `has_status("fire") == true`　【P0 · **依赖 `D3-T2b`**，原文「`_status` 内含 `fire`」改用 `D3-T2b` 提供的公开查询接口，避免断言私有字段】
  6. `well_rounded`（无 skill）按键**零 error**、`can_cast()` 恒 false　【P0】
- [x] 回归：`tools/day2_hero_check.gd` 仍 32 断言 0 失败（**防 T2 改动 `projectile.gd` 波及既有武器**）
- [x] **护栏（Day 2 破口复查）**：本日改动必须 `git commit`——Day 2 曾出现「代码已落地但未提交」，现已由 `edd0e9a` 补上，勿再重演
- ⚠️ 主观项「技能释放爽不爽 / 火球打击感 / 炮台摆位是否顺手」→ 不计入出口，由 #5 收进 `PLAYTEST_CHECKLIST.md`

### Day 4 — 经验 / 升级 / Build 初版　✅【2026-08-05 21:3x #3 收口】🎯【已预拆解到函数级 · 2026-08-05 19:08 #2 第 4 轮】

> **✅ 收口记录（2026-08-05 21:3x · #3）**：`day4_level_check.gd` **21 项断言 0 失败（DAY4 LEVEL CHECK CLEAN）** + `baseline_check` **BASELINE CLEAN** + `day2_hero_check` 32/0 + `day3_skill_check` 16/0 回归 CLEAN，已 `git commit`。
> **实现偏差（2 处，均有据）**：
>    - 吸血结算实现于 `projectile.gd`（`apply_life_steal()`，线弹命中 + 爆炸 AOE 共用）而非 `weapon_controller.gd`——weapon_controller 只有开火逻辑，**无「伤害生效后」钩子**，实际命中结算点在 projectile；方法公开供无头白盒测试。
>    - 连升多级弹窗采用**合并策略**（一次 gain_exp 弹一窗，多级合并显示，`_level_up_panel` 非空守卫防叠加）——TASKS D4-T4 测试点明确「逐级弹窗或合并二选一」。
> **测试同步更新**：`day2_hero_check.gd` se_ren 用例 `bonus_key=life_steal_percent` → `life_steal==0.05`（D4-T3 后该键从 bonus_stats 移入属性通道）；`day3_skill_check.gd` noa 用例「占位应 false」→「部署成功 true + 冷却生效」（D4-T5 已实现）。
> **产出**：`scripts/player/skill_controller.gd`（占位→真实炮台部署）｜ `scripts/weapons/turret.gd` + `scenes/Turret.tscn`（新建）｜ `scenes/LevelUpPanel.tscn` + `scripts/ui/level_up_panel.gd`（新建）｜ `scenes/GameOverPanel.tscn` + `scripts/ui/game_over_panel.gd`（新建）｜ `player.gd`（exp/level/level_up/gain_exp/Expression 曲线/life_steal）｜ `enemy.gd`（经验掉落）｜ `projectile.gd`（吸血结算）｜ `game_manager.gd`（升级暂停+双面板+清残敌）｜ `hud.gd`+`HUD.tscn`（XpBar 接入+SkillSlot 冷却）｜ `enemy_spawner.gd`（商店禁生成）｜ `data/stats.json`（10 属性档）｜ `tools/day4_level_check.gd`（新建）

> **承接**：`D3-T4`（诺亚炮台，P1 顺延首段 → 本日 `D4-T5`）＋ `D3-T6`（HUD 冷却，P1 → 本日 `D4-T6`）。
> 🔴 **BUG-001 承接（用户 19:53 确认留待下一轮 = 本日首段）**：「第 2 关后全员静止」根因 = 玩家死亡无 Game Over 反馈（`game_over` 信号零消费方）+ 波次切换不清理残敌（商店期间残敌继续攻击）。
> → 本日**首段**执行 `D4-T7`（Game Over 面板）+ `D4-T8`（波次切换清残敌），否则试玩会再次误判「卡死」。条目已固化，见下。
> **护栏**：改前 `git commit`（Day 3 教训：实现落地≠收口，必须提交）；改后 `baseline_check` 必须 `BASELINE CLEAN`。
> **文件域**：W1 写 `scripts/` + `scenes/`；W2 只写 `data/stats.json`；无跨域冲突。
> **实测基线（#3 免重复排查，19:08 #2 已核）**：
> - `enemy.gd:45` 已有 `exp_value: int = 1` 字段，但 `_drop_rewards()`（`:389`）**只掉金币**（`economy.add_coins`），经验**零消费**——真实缺口
> - `player.gd` **无 exp/level 字段**；`hud.gd:137 update_xp(current, maximum)` 已定义但 **无调用方**；`HUD.tscn:48` 已有 `XpBar` 节点
> - `stats.json.leveling`：`xp_per_level = "20 + current_level * 10"`（字符串表达式）、`choices_per_level: 3`、`upgrade_options` 四组**均为框架旧属性名**（`melee_damage/ranged_damage/elemental_damage/dodge/harvesting/engineering`）——**与大纲 10 属性口径不符，必须重写（D4-T2）**
> - `player.gd:272 apply_stat_modifier()` 实际支持键（12）：`max_health/move_speed/armor/damage/attack_speed/crit_chance/range/regen/pickup_range/crit_damage/dodge/luck`——大纲 10 属性中 **9 项可直通，吸血（life_steal）唯一缺失**
> - `player.gd:66 STAT_MAP_EXCLUDED = ["range"]`：注释明示「口径统一属 Day 4 强化面板的决策」——range 像素加减会打负倍率，**定案统一走倍率通道**
> - **无任何升级/强化面板**（`scenes/` 无 LevelUp*，参考范式：`scripts/ui/shop.gd` 的 ShopPanel）

#### 本日总定案（先读，避免执行期临场决策）
| 议题 | 定案 | 依据 |
|------|------|------|
| 经验来源 | 在 `enemy._drop_rewards()` 补 `exp_value` 掉落，**直接** `GameManager.player.gain_exp(exp_value)` 结算——**不造磁吸宝石实体** | 宝石/磁吸属手感 polish，后续轮次再做；直接结算无头可测、改动最小 |
| 经验曲线 | 用 Godot `Expression` 类解析 `stats.json.leveling.xp_per_level` 字符串（代入 `current_level`） | 避免代码里硬编码第二份曲线（双源漂移）；`"20 + current_level * 10"` 为唯一权威 |
| 升级行为 | 经验满 → `player.level_up` 信号 → **暂停游戏**（`get_tree().paused = true`）→ 弹 LevelUpPanel 三选一 → 选择后恢复 | Brotato 范式；`GameManager.state_changed` 已有状态机可扩展；面板 `PROCESS_MODE_WHEN_PAUSED` |
| 强化项口径 | **重写 `stats.json.leveling.upgrade_options` 为大纲 10 属性档**（下表），去掉三系伤害与 dodge/harvesting/engineering | `apply_stat_modifier` 无三系伤害通道；大纲 10 属性为权威 |
| range 口径 | **统一走倍率通道** `range_multiplier`（percent 模式 → `1.0 + v/100` 乘算）；`STAT_MAP_EXCLUDED["range"]` 保持排除不动 | `player.gd:66` 注释明示 Day 4 决策；像素平直加减会把倍率打负 |
| 吸血补齐 | `player.gd` 新增 `life_steal` 字段 + `apply_stat_modifier("life_steal")` 分支 + STAT_MAP 补 `life_steal_percent→ratio`；命中回血在 `weapon_controller.gd` 结算 | 大纲 10 属性必须全齐（攻击/攻速/范围/移速/暴击率/暴伤/生命/护甲/吸血/幸运） |
| 升级面板 | 新建 `scenes/LevelUpPanel.tscn` + `scripts/ui/level_up_panel.gd`，从 `stats.json.leveling.upgrade_options` 随机取 3 个不重复选项 | 实测无任何升级 UI；`choices_per_level: 3` 已定 |

**10 属性强化数值档**（`D4-T2` 按此重写 `upgrade_options`，`mode` 对齐 `STAT_MAP` 语义）：

| 属性 | stat 键 | mode | 数值 | apply_stat_modifier 通道 |
|---|---|---|---|---|
| 攻击 | `damage` | percent | +10% | `damage_multiplier` 乘算 ✅ |
| 攻速 | `attack_speed` | percent | +5% | `attack_speed` 乘算 ✅ |
| 范围 | `range` | percent | +8% | `range_multiplier` 乘算 ✅（口径定案） |
| 移速 | `move_speed` | percent | +5% | `move_speed` 乘算 ✅ |
| 暴击率 | `crit_chance` | ratio | +3% | `crit_chance` 加算 ✅ |
| 暴伤 | `crit_damage` | percent | +10% | `crit_damage` 乘算 ✅ |
| 生命 | `max_health` | add | +10 | `max_health` 加算 ✅ |
| 护甲 | `armor` | add | +1 | `armor` 加算 ✅ |
| 吸血 | `life_steal` | ratio | +2% | **需 `D4-T3` 新增通道** ⚠️ |
| 幸运 | `luck` | add | +5 | `luck` 加算 ✅ |

#### D4-T1【W1 · P0】经验获取与升级核心
- [x] `enemy.gd:_drop_rewards()`（`:389`，金币掉落之后）补：`if GameManager.player and GameManager.player.has_method("gain_exp"): GameManager.player.gain_exp(exp_value)`（保留金币逻辑不动）
- [x] `player.gd` 新增状态与信号：`var exp: float = 0.0` / `var level: int = 1` / `signal level_up(new_level: int)`
- [x] `player.gd` 新增 `func gain_exp(amount: float) -> void`：`exp += amount` → `_check_level_up()`
- [x] `player.gd` 新增 `func _check_level_up() -> void`：**while 循环**（一次大量经验可连升多级）——
      `Expression` 解析 `DataLoader.get_leveling()["xp_per_level"]`（若无该接口则直接读 `stats.json` 的 `leveling` 字典），把 `current_level` 绑定到 `level` 求值；`exp >= need` 则 `exp -= need; level += 1; level_up.emit(level)`，循环直到不足
      - ⚠️ 解析失败（表达式异常）→ `push_warning` 并回退默认曲线 `20 + level * 10`，**禁止崩溃**
- [x] `scripts/autoload/game_manager.gd` 监听 `player.level_up` → 暂停 + 弹面板（依赖 `D4-T4`；面板未就绪时仅暂停 + `push_warning`，不崩）
- [x] `hud.gd:137 update_xp()` 接入：player 的 `exp` / 当前级需求值变化时刷新 `XpBar`（连 `level_up` 或轮询均可，最简：`_on_xp_changed` 信号或 `_process` 内低频刷新）
- **测试点**：击杀 1 敌 → `player.exp == exp_value`（enemy 数据 `exp_value:1`）；0→1 级需求 20、1→2 级需求 30（`20+1*10`）；一次性 +60 经验连升多级、`level_up` 信号次数正确；`well_rounded` 直开 `Main.tscn` 升级不崩

#### D4-T2【W2 · P0】`data/stats.json` 强化口径重写
- [x] 重写 `leveling.upgrade_options`：**保持 4 组结构**（damage/offense/defense/economy），选项内容换为「10 属性强化数值档」表——
      damage 组：攻击 +10% / 攻速 +5% / 暴伤 +10%　offense 组：范围 +8% / 暴击率 +3% / 移速 +5%　defense 组：生命 +10 / 护甲 +1 / 吸血 +2%　economy 组：幸运 +5（余位补 暴伤 或 攻击 二选一，**不得回填三系伤害/dodge/harvesting/engineering**）
- [x] `xp_per_level`（`"20 + current_level * 10"`）与 `choices_per_level`（3）**原样保留**
- [x] 选项 schema 建议：`{"label": "攻击 +10%", "stat": "damage", "mode": "percent", "value": 10}`——`mode` 复用 `STAT_MAP` 三值（add/percent/ratio），`D4-T4` 面板直接按此调 `apply_stat_modifier`
- **测试点**：`python -c` JSON 校验通过；10 属性中每个 `stat` 键都在 `apply_stat_modifier` 支持集（`D4-T3` 后含 `life_steal` 共 11 键）；`grep` 确认无 `melee_damage/ranged_damage/elemental_damage/dodge/harvesting/engineering` 残留

#### D4-T3【W1 · P0】吸血属性通道（大纲 10 属性补齐）
- [x] `player.gd` 新增 `@export var life_steal: float = 0.0`（0~1，注释「吸血：命中伤害回血比例」）
- [x] `apply_stat_modifier()` match 分支加 `"life_steal"`：`life_steal = clampf(apply_value(life_steal, value, is_multiplicative), 0.0, 1.0)`
- [x] `STAT_MAP`（`:47`）补 `"life_steal_percent": {"stat": "life_steal", "mode": "ratio"}`——让已收进 `bonus_stats` 的英雄 `life_steal_percent` 数据（莱恩 5）自动进通道
- [x] `scripts/weapons/weapon_controller.gd` 命中结算处（伤害生效后）：`var player_node := GameManager.player; if player_node and player_node.life_steal > 0.0: player_node.heal(final_damage * player_node.life_steal)`
      - ⚠️ 若 `player.gd` 无 `heal()` 方法：新增 `func heal(amount) -> void`（`health = min(health + amount, max_health)` + `health_changed.emit`），或直接内联，**二选一并保持一致**
- **测试点**：`life_steal = 0.2` 命中 10 伤害 → 回 2 血；不加吸血零变化；莱恩进局 `life_steal == 0.05`（passive `life_steal_percent:5`）

#### D4-T4【W1 · P0】LevelUpPanel 强化选择 UI（新建）
- [x] `scenes/LevelUpPanel.tscn`：`CenterContainer` → `Panel` → `VBoxContainer`（标题 `Label`「升级！选择一项强化」+ 3 个 `Button`，样式对齐 `ShopPanel`）
- [x] 节点 `process_mode = PROCESS_MODE_WHEN_PAUSED`（游戏暂停期间可交互）
- [x] `scripts/ui/level_up_panel.gd`：
      - `var player: Node2D`（`GameManager.player`）
      - `func setup() -> void`：从 `DataLoader.get_leveling().upgrade_options` 摊平所有选项 → **随机取 3 个不重复** → 渲染到 3 个 Button（label 文本 + 点击回调绑定对应选项）
      - 点击回调：`player.apply_stat_modifier(opt.stat, opt.value, opt.mode == "percent")`——percent 走乘算（`1.0 + value/100` 由 `apply_stat_modifier` 的调用方语义决定，**按 D4-T2 的 schema：percent 传 `value` 并标记 multiplicative、ratio 传 `value/100` 非乘算、add 直传**——若不一致以 `STAT_MAP._apply_stat_dict()` 既有三档写法为准照抄）
      - 选择后：`get_tree().paused = false` → `queue_free()`；玩家死亡时若面板仍开着 → 一并释放防悬挂
- [x] `game_manager.gd`：`level_up` 处理器实例化面板并 `add_child` 到 UI 层（CanvasLayer 下）
- **测试点**：升级 → 面板出现且 `get_tree().paused == true`；点「攻击 +10%」→ `damage_multiplier == 1.1` 且恢复运行；3 个选项不重复；连升多级时逐级弹窗（或合并，二选一，**推荐逐级**保持节奏）

#### D4-T5【W1 · P0】承接 D3-T4：诺亚「紧急部署」炮台实体
- [x] 新建 `scripts/weapons/turret.gd`（`extends Node2D`）+ `scenes/Turret.tscn`
- [x] 炮台数值**全部来自** `DataLoader.get_weapon("se_auto_turret")`（实测 `damage:5 / cooldown:0.5 / range:220`），**禁止硬编码**
- [x] 行为：`_process` 冷却计时 → 射程内索敌（复用 `enemy_spawner.enemies_container` 遍历，同 `skill_controller.gd:163` 范式）→ 生成 `Projectile`（`speed:400, lifetime:range/speed`）→ 无敌人空转不开火
- [x] 存活：`duration` 取 `skill_data.get("duration", 15.0)`，每帧递减写 `_process`，到期 `queue_free()`（**禁用 `Timer` 节点**，无头下 SceneTree 计时更易漂）
- [x] 部署数量定案：`skill_data.summon_count`(2) **+** `player.bonus_stats.get("summon_count", 0.0)`(诺亚 passive = 1) = **3 台**（有据非臆造）
- [x] 摆位：玩家为心、半径 40px 圆周均布（`TAU / count * i`）；挂载 `player.get_parent()`（World）——**不挂 Player 子节点**，炮台不随玩家移动
- [x] 外观：`Polygon2D` 运行时绘制占位方块（对齐 `projectile.gd` `_make_bullet_texture()` 范式）；真精灵登记 Day 21–22 美术债
- [x] `skill_controller.gd:117 _cast_deploy_turret()` 占位**替换为真实实现**（生成 3 台 → 返回 true）
- **测试点**：释放后 World 下 Turret 节点数 == **3**；15 秒后归 0；玩家跑开后炮台留在原地；炮台开火命中伤害 == 5（`se_auto_turret.damage`）；**此断言即 Day 3 `D3-EXIT` 顺延的断言 3，在此收口**

#### D4-T6【W1 · P1】承接 D3-T6：HUD 技能冷却指示
- [x] `HUD.tscn` `BottomBar` 下新增 `SkillSlot`（`TextureRect` + 子 `Label` 显示剩余秒数，样式对齐 `WeaponSlot0`）
- [x] `hud.gd` 新增 `_on_skill_cooldown_changed(left, total)`：`left <= 0` 显示「就绪」满亮度；否则 `"%.1f" % left` 且 `modulate` 压暗 0.4
- [x] 连接：`_ready()` 内 `await get_tree().process_frame` 后取 `GameManager.player.get_node_or_null("SkillController")` 再 connect；取不到只 `push_warning` 不崩
- 判定：P1，**不阻塞 Day 4 出口**

#### D4-T7【W1 · P0 · BUG-001-F1 · 首段】Game Over 结果面板（新建）
> 工单 BUG-001：`game_over` 信号**零消费方**（`game_manager.gd:91` emit、`player.gd:267` 触发）→ 玩家死亡后游戏「静默结束」= 用户所见「第 2 关后全员静止」。
- [x] 新建 `scenes/GameOverPanel.tscn`：`CanvasLayer` → `CenterContainer` → `Panel` → `VBoxContainer`（标题 `Label`（「你已阵亡」/「胜利」随 `victory` 布尔切换）+ 说明 + 重新开始 `Button`）；`process_mode = PROCESS_MODE_WHEN_PAUSED`
- [x] 新建 `scripts/ui/game_over_panel.gd`：`setup(victory: bool, reason: String)`；重开按钮 → `get_tree().paused = false` 后 `get_tree().reload_current_scene()`（回 Main 重开本局）；返回选人按钮（可选）→ 切 `CharacterSelect.tscn`
- [x] `game_manager.gd` 的 `_on_game_over`（`:91` 附近）实例化面板挂 UI 层，并 `get_tree().paused = true`（防死亡后敌人继续攻击导致连锁异常）
- **测试点**：`player.die()` 触发 → 面板出现 + `paused == true` + 标题为「你已阵亡」；点重开 → 场景重载零 error、可再次进局
- 依赖：无（纯新建 UI + 信号消费，不与 D4-T1~T6 冲突，可**并行**做）

#### D4-T8【W1 · P0 · BUG-001-F2 · 首段】波次切换清理残敌
> 工单 BUG-001 根因 5：`enemy_spawner` 只清 `spawn_queue`，**不 free 已生成敌人** → 商店期间残敌继续攻击玩家，玩家常在商店/第 2 关初阵亡。
- [x] `game_manager.gd`（或 `enemy_spawner` 内部）在 `on_wave_cleared` / 进入商店状态时：遍历 `enemy_spawner.enemies_container.get_children()`，对 `is_instance_valid(e) and e.is_alive` 的敌人统一 `queue_free()`（或置 `is_alive = false` + 播放死亡效果——**二选一，推荐直接 `queue_free()`，最简且无残留状态**）
- [x] 清理时机放在**波次结算奖励发放之前**（先清敌、后发奖，避免清敌逻辑干扰奖励计数）；商店期间 `enemy_spawner` 不得再生成新敌人（若已有商店禁生成的守卫则确认）
- **测试点**：第 1 波清空 → 进入商店 → `enemies_container.get_child_count() == 0`；商店期间玩家**不再受到伤害**
- 依赖：无（纯清理逻辑，与 D4-T7 可并行）

#### D4-EXIT【W5】当日出口
- [x] `python tools/baseline_check.py` → `BASELINE CLEAN`（import + runtime 双阶段，exit 0 / stderr 0）
- [x] 新建 `tools/day4_level_check.gd` 无头断言（照搬 `day2_hero_check.gd` 的 `extends SceneTree` + 分帧推进骨架），覆盖：
  1. 击杀 1 敌 → `player.exp == exp_value`　【P0】
  2. 经验曲线：0→1 级需求 20、1→2 级需求 30（`20 + level*10`）　【P0】
  3. 升级触发 `level_up` 信号 + 面板出现 + `get_tree().paused == true`　【P0】
  4. 选「攻击 +10%」→ `damage_multiplier == 1.1`，且选择后面板消失、游戏恢复　【P0】
  5. 选「范围 +8%」→ `range_multiplier == 1.08`（口径定案验证）　【P0】
  6. `life_steal = 0.2` 命中回血　【P0】
  7. 诺亚释放 → World 下 Turret == **3**、15 秒后归 0（**Day 3 顺延断言 3 收口**）　【P0】
  8. 连升多级（+60 经验）信号次数与级数正确；`well_rounded` 直升不崩　【P0】
  9. `player.die()` → GameOver 面板出现 + `paused == true` + 标题「你已阵亡」；点重开 → 场景重载零 error　【P0 · BUG-001-F1 收口】
  10. 波次清空进商店 → `enemies_container.get_child_count() == 0`　【P0 · BUG-001-F2 收口】
- [x] 回归：`day3_skill_check.gd` / `day2_hero_check.gd` 0 失败
- [x] **护栏**：`git commit`（Day 3 破口不得重演——实现落地≠收口）
- ⚠️ 主观项「升级弹窗手感 / 三选一体验 / 炮台摆位是否顺手」→ 不计入出口，由 #5 收进 `PLAYTEST_CHECKLIST.md`

### Day 5 — 武器 6 槽挂载　✅【客观任务完成 · 已收口 · 2026-08-05 23:5x #3】

> **✅ 收口记录（2026-08-05 23:5x · #3）**：`day5_weapon_check.gd` **15 项断言 0 失败（DAY5 WEAPON CHECK CLEAN）** + `baseline_check` **BASELINE CLEAN** + 回归三件套（`day4_level_check` 21/0 · `day3_skill_check` 16/0 · `day2_hero_check` 32/0）全绿，已 `git commit`（`5092874`）。
> **实现偏差（2 处，均有据）**：
>    - D5-EXIT 断言 2 计数口径：Lv1→Lv8 为 7 次成功升级（非 8），第 8 次调用返回 false（max_level=8 封顶），测试按逻辑实现；TASKS 原文「第 9 次」为计数笔误。
>    - D5-T4 断言 7（卸下清理）：`unequip_weapon → _sync_orbit_weapon → orbit_node.queue_free()` 为延迟释放，测试拆「卸下 → 空转一帧 → 断言」两帧完成（与 day4 炮台到期同款手法）。
> **产出**：`scripts/weapons/orbit_weapon.gd`（新建，环绕刃驱动 + D3-T5 埋点消费收口）｜ `weapon.gd`（level_table/orbit_data + 查表升级）｜ `weapon_controller.gd`（6 槽 + 查表构建 + orbit 分流）｜ `level_up_panel.gd`（混合选项池）｜ `tools/day5_weapon_check.gd`（新建）
> **护栏**：改前 `git commit` 存档；改后 `python tools/baseline_check.py` 必须 `BASELINE CLEAN`。
> **文件域**：W1 写 `scripts/` + `scenes/`；W2 只写 `data/weapons.json`（核验/微调）；**无跨域冲突**。
> **目标**（30DAY_PLAN D5）：自动攻击与武器挂载 6 槽逻辑（对齐大纲 6 武器上限 + Lv1-8 升级）。
> **本轮实测基线（#3 免重复排查，23:1x #2 已核）**：
> - `weapon_controller.gd:22` `equipped_weapons: Array[Resource] = []` **无槽位上限**；`equip_weapon`(`:66-68`) 只查重不查容量 → 6 槽上限需新增
> - `weapon_controller.gd:57-61` `_process` 已遍历 `equipped_weapons` 齐射 → 多武器自动攻击**雏形已具**，Day 5 非从零搭建
> - `weapon.gd:33-34` `level: int = 1` / `max_level: int = 5` 默认 5；`build_weapon_from_data`(`weapon_controller.gd:98`) `max_level = int(data.get("max_level", 5))`——**签名武器 JSON 已带 `max_level: 8` + `levels` 8 条**（`se_star_blade` 实测 8/8；Lv1 伤7→Lv8 伤32，含 blade_count 逐级成长：Lv1:1把→Lv3:2把→Lv5:3把→Lv7:4把）；29 把旧武器无 `max_level`/`levels`（数据缺口，归 Day 7-9）
> - `weapon.gd:64-69` `upgrade() -> bool`（`level >= max_level` 返回 false）+ `_on_upgrade()`(`:72-74`：`base_damage *= 1.25; fire_rate *= 1.1` 通用成长) **已存在**——但**未消费 JSON `levels[]` 表**，签名武器逐级曲线将失效
> - `weapon.gd:79-84` `get_damage() / get_attack_interval()` 读数函数已存在（查表在 `_on_upgrade` 覆写底层字段后，读数函数无需改）
> - `weapon.gd` **无 orbit 字段**；`se_star_blade` JSON 含 `blade_count/orbit_radius/orbit_speed` → 环绕渲染**全新建**
> - `weapons.json` 结构：`weapons: {melee|ranged|elemental|engineering: [数组]}`（**四类为数组**，非 dict；签名武器在对应类数组内）
> - **环绕埋点**：`skill_controller.gd:178-199` 莱恩技能写 `player.bonus_stats["orbit_blade_count"] += 3`（释放）`-= 3`（到期还原）——Day 5 环绕武器**必须消费此键**，只读不写
> - `level_up_panel.gd`：`setup()` → `_roll_options(3)` 从 `stats.json.leveling.upgrade_options` 摊平 shuffle 取 3；`_apply_option` 走 `apply_stat_modifier` 三档（percent/ratio/add）——**武器升级入口需扩展此面板**
> - ⚠️ **D4 回归风险**：`day4_level_check.gd` 断言 4/5 依赖「选攻击/范围属性选项」——混合池后随机 3 个可能不含目标属性 → **断言必须同步改为注入式验证**（见 D5-T3）

#### 本日总定案（先读，避免执行期临场决策）
| 议题 | 定案 | 依据 |
|------|------|------|
| 6 槽超限策略 | `equip_weapon()` 满槽返回 `false` **拒绝**（已装备不受影响）；「替换旧武器」交互归 Day 11-12 商店体系 | 最小可验闭环；替换 UI 需要背包/商店支撑，本日不臆造 |
| 升级数据源 | **`levels[]` 查表优先**：`_on_upgrade()` 读 `levels[level-1]` 绝对覆盖（damage / cooldown→fire_rate 取倒数 / projectiles / range / orbit 键）；表空回退现有通用成长（×1.25 / ×1.1） | 签名武器 8 级曲线为权威数据；通用成长只是旧武器兜底 |
| max_level 口径 | `max_level = maxi(int(data.get("max_level", 5)), level_table.size())`——防 levels 表 8 条而 max_level 缺省时只能升到 5 | `build_weapon_from_data:98` 现取默认 5，与表长可能不一致 |
| 升级入口 | **扩展 LevelUpPanel 混合选项池**：属性（stats.json，现状保留）+ 武器升级（已装备且 `level < max_level` 的武器，每把 1 个「升级『X』」选项）随机取 3 | Brotato 范式；当前无商店体系，升级面板是唯一在局升级入口 |
| 环绕武器实现 | 新建 `scripts/weapons/orbit_weapon.gd`（extends Node2D）挂 **Player 子节点**；WeaponController 检测 `orbit_data` 非空 → 跳过弹丸发射，由 orbit 节点独立驱动；接触伤害用**容器遍历**（复用 `_find_nearest_enemy` 范式，禁物理查询） | 环绕刃无弹道，发射逻辑不适用；无头测试下物理帧不可靠（D3 教训） |
| bonus_stats 消费 | 实际刃数 = `orbit_data.blade_count + int(player.bonus_stats.get("orbit_blade_count", 0))`——**D3 埋点收口点** | 莱恩技能 +3 在此自动生效，无需改 skill_controller |
| 环绕视觉 | 运行时绘制占位刃（Polygon2D 三角形，对齐 `projectile.gd _make_bullet_texture()` 范式）；真精灵登记 Day 21-22 美术债 | 无头可测；素材归 W3 域 |

#### D5-T1【W1 · P0】6 槽上限 + 装备管理（`scripts/weapons/weapon_controller.gd`）
- [x] 新增 `const MAX_SLOTS: int = 6`
- [x] `equip_weapon(weapon)` 改返回 `bool`：`weapon in equipped_weapons` 或 `equipped_weapons.size() >= MAX_SLOTS` → 返回 `false` 不追加；否则追加返回 `true`（⚠️ 现有调用方 `_equip_default_weapon`/`equip_from_data` 不检查返回值，保持兼容即可）
- [x] 新增查询 `func get_slot_count() -> int` / `func is_full() -> bool`（测试与后续 UI 用）
- 测试点：连装 6 把 → `is_full() == true`；第 7 把 `equip_weapon` 返回 false 且 `size() == 6` 不变

#### D5-T2【W1 · P0】武器 Lv1-8 升级机制（`scripts/weapons/weapon.gd` + `weapon_controller.gd`）
- [x] `weapon.gd` 新增字段：`var level_table: Array = []`（存 JSON `levels[]`）与 `var orbit_data: Dictionary = {}`（存 `blade_count/orbit_radius/orbit_speed`）
- [x] `build_weapon_from_data`（`weapon_controller.gd:79-100`）补读：
      - `w.level_table = data.get("levels", [])`（数组，逐级状态表）
      - `w.max_level = maxi(int(data.get("max_level", 5)), w.level_table.size())`（防短表）
      - 若 `data` 含 `blade_count`（orbit 武器）：`w.orbit_data = {"blade_count": int(...), "orbit_radius": float(...), "orbit_speed": float(...)}`（取 data 当前值；升级时由 levels 表覆写）
- [x] `weapon.gd:_on_upgrade()` 改查表（**核心改动**）：
      ```
      if level_table.is_empty():
          base_damage *= 1.25   # 旧武器通用成长兜底
          fire_rate *= 1.1
          return
      var idx := level - 1
      if idx < 0 or idx >= level_table.size(): return
      var entry: Dictionary = level_table[idx]
      if entry.has("damage"): base_damage = float(entry["damage"])
      if entry.has("cooldown"): fire_rate = 1.0 / maxf(float(entry["cooldown"]), 0.01)   # 取倒数（D2 同款口径）
      if entry.has("projectiles"): projectile_count = maxi(int(entry["projectiles"]), 1)
      if entry.has("range"): attack_range = float(entry["range"])
      if entry.has("blade_count") or entry.has("orbit_radius") or entry.has("orbit_speed"):
          orbit_data["blade_count"] = int(entry.get("blade_count", orbit_data.get("blade_count", 1)))
          orbit_data["orbit_radius"] = float(entry.get("orbit_radius", orbit_data.get("orbit_radius", 110.0)))
          orbit_data["orbit_speed"] = float(entry.get("orbit_speed", orbit_data.get("orbit_speed", 180.0)))
      ```
      ⚠️ `upgrade()` 先 `level += 1` 再 `_on_upgrade()`（`weapon.gd:64-69`）→ `level - 1` 恰为新等级索引，**勿再偏移**；levels 表为「该等级的绝对状态值」非 delta
- [x] `get_damage()/get_attack_interval()` 保持现状（查表已覆写底层字段，读数函数零改动）
- 测试点：`se_star_flame` 从 Lv1 连续 `upgrade()` 到 Lv8 全 true，第 9 次 false；Lv2 后 `base_damage == levels[1].damage`；`pistol`（无 levels 表）升级走通用成长（`base_damage == 5 * 1.25`）

#### D5-T3【W1 · P0】升级入口：LevelUpPanel 混合选项池（`scripts/ui/level_up_panel.gd`）
- [x] `_roll_options(count)` 选项池 = 属性池（`upgrade_options` 摊平，现状保留）**+** 武器升级池：
      - 取 `GameManager.player.get_node_or_null("WeaponController")`（取不到则仅属性池，不崩）
      - 遍历 `equipped_weapons`，对 `weapon.level < weapon.max_level` 的武器生成 `{"label": "升级「%s」" % weapon.weapon_name, "type": "weapon_upgrade", "weapon": weapon}`
- [x] `_apply_option()` 加分支：`opt.get("type", "") == "weapon_upgrade"` → `opt.weapon.upgrade()`（先 `has_method` 守卫），**不调 `apply_stat_modifier`**；其余保持 D4 三档
- [x] ⚠️ **D4 回归联动（必须）**：`day4_level_check.gd` 断言 4/5（选「攻击+10%」→ `damage_multiplier==1.1` / 选「范围+8%」→ `range_multiplier==1.08`）依赖纯属性池随机——混合池后随机 3 个可能不含目标选项 → **同步改为注入式**：直接构造 `_options` 为固定选项再调 `_apply_option`（白盒验证），或固定随机种子，保证 D4 回归稳定不偶发失败
- 测试点：升级 → 面板出现且 `paused == true`；选项池含「升级『星刃』」类选项；选择后 `equipped_weapons[i].level == 2`、`paused == false`、面板消失；D4 属性选项仍可应用（注入式回归）

#### D5-T4【W1 · P0】环绕武器机制（新建 `scripts/weapons/orbit_weapon.gd` + WeaponController 分流）
- [x] 新建 `orbit_weapon.gd`（`extends Node2D`，`class_name OrbitWeapon`）：
      - 字段：`var weapon: Resource` / `var player: Node2D` / `var _angles: Array = []`（每刃当前角，度）/ `var _hit_cd: Array = []`（每刃命中冷却计时）
      - `func setup(w: Resource, p: Node2D) -> void`：存引用并调 `_sync_blades()`
      - `func _sync_blades() -> void`：实际刃数 = `weapon.orbit_data.get("blade_count", 1) + int(player.bonus_stats.get("orbit_blade_count", 0))`；增删子 `Polygon2D`（三角形 8×12px，`set_polygon` 运行时绘制，颜色对齐现有占位风格）到数量一致
      - `func _process(delta) -> void`：① `is_instance_valid(player)` 守卫（玩家可能已死），失效即 `set_process(false)`；② 每刃 `_angles[i] += weapon.orbit_data.get("orbit_speed", 180.0) * delta`；刃全局位置 = `player.global_position + Vector2.from_angle(deg_to_rad(_angles[i])) * orbit_radius`；③ 命中判定：遍历 `GameManager.enemy_spawner.enemies_container.get_children()`，`is_instance_valid(e) and e.is_alive` 且 `刃位置.distance_to(e.global_position) <= 12.0` 且 `_hit_cd[i] <= 0` → `e.take_damage(weapon.get_damage() * player.damage_multiplier)`，`_hit_cd[i] = weapon.get_attack_interval()`；④ `_hit_cd[i] -= delta`；⑤ 刃数变化（升级/技能）时自动 `_sync_blades()`
      - ⚠️ **不做**：刃与刃碰撞、刃挡子弹、反弹——无数据支撑，不臆造
- [x] `weapon_controller.gd` 集成：
      - 新字段 `var orbit_node: Node2D = null`
      - `_process` 遍历时：`if weapon.orbit_data and not weapon.orbit_data.is_empty(): continue`（**跳过弹丸发射**，环绕武器不自发弹丸）
      - 新增 `func _sync_orbit_weapon() -> void`：扫描 `equipped_weapons` 找第一个 `orbit_data` 非空 weapon → 无则清理 `orbit_node`（`queue_free()` + 置 null）；有则：`orbit_node` 为 null 时创建 `OrbitWeapon.new()`、`owner_node.add_child(orbit_node)`（挂 **Player 子节点**，跟随移动）、命名 `"OrbitWeapon"`；再 `orbit_node.setup(weapon, owner_node)`
      - `equip_weapon()/unequip_weapon()` 末尾调 `_sync_orbit_weapon()`
      - ⚠️ `Player.tscn` **不需要**预置 OrbitWeapon 节点——运行时由 `_sync_orbit_weapon` 创建；直开 `Main.tscn` 无环绕武器时该节点不存在，零影响
- 测试点：装备 `se_star_blade` → Player 下 `OrbitWeapon` 存在且刃 Polygon2D 数 == 1（Lv1 `blade_count`）；手动 `player.bonus_stats["orbit_blade_count"] = 3` → 下帧刃数 == 4（**D3 埋点消费收口**）；刃旋转经过敌人 → 敌人 `health` 下降 `7 × damage_multiplier`；卸下星刃 → OrbitWeapon 被清理；玩家移动后刃**跟随玩家**（挂 Player 下）

#### D5-T5【W2 · P0】数据核验（`data/weapons.json`）
- [x] 核验 3 把签名武器（`se_star_flame`/`se_auto_turret`/`se_star_blade`）`max_level == 8` 且 `levels` 恰 8 条、逐级 `level` 字段递增（`se_star_blade` 已实测 8/8 ✅；另两把按同口径核验）
- [x] 核验 `se_star_blade` levels 表含 `blade_count/orbit_radius/orbit_speed` 逐级成长（Lv1:1把→Lv3:2把→Lv5:3把→Lv7:4把，已实测 ✅）
- [x] **不批量给旧武器补 `levels`**（属 Day 7-9「12 通用武器 Lv1-8 数据」排期）；本日仅登记缺口
- 测试点：JSON 校验通过；3 把签名武器 `max_level == 8` 且 `levels.size() == 8`；`pistol` 无 levels 表（走通用成长兜底）

#### D5-EXIT【W5】当日出口
- [x] `python tools/baseline_check.py` → `BASELINE CLEAN`（import + runtime 双阶段，exit 0 / stderr 0）
- [x] 新建 `tools/day5_weapon_check.gd` 无头断言（照搬 `day4_level_check.gd` 的 `extends SceneTree` + 分帧推进骨架），覆盖：
  1. 连装 6 把 → `is_full() == true`，第 7 把被拒（`size() == 6`）　【P0 · D5-T1】
  2. `se_star_flame` 连续 `upgrade()` Lv1→Lv8 全 true，第 9 次 false；Lv2 后 `base_damage == levels[1].damage`（查表生效）　【P0 · D5-T2】
  3. `pistol`（无 levels 表）升级走通用成长（`base_damage == 5 * 1.25`）　【P0 · D5-T2 兜底】
  4. 升级面板选项池含武器升级项；选「升级『星刃』」→ 星刃 `level == 2`、`paused == false`、面板消失　【P0 · D5-T3】
  5. 装备星刃 → Player 下 OrbitWeapon 刃数 == 1（Lv1 `blade_count`）；`bonus_stats["orbit_blade_count"] = 3` → 刃数 == 4（**D3 埋点收口**）　【P0 · D5-T4】
  6. 刃接触敌人 → 敌人掉血（`7 × damage_multiplier`）　【P0 · D5-T4】
  7. 卸下星刃 → Player 下无 OrbitWeapon 节点　【P0 · D5-T4】
- [x] **回归三件套**：`day4_level_check` 21 断言 0 失败（**注意 D5-T3 要求的注入式改造**）+ `day3_skill_check` 16/0 + `day2_hero_check` 32/0
- [x] **护栏**：`git commit`（Day 3/4 破口教训：实现落地≠收口，必须提交）
- ⚠️ 主观项「环绕刃手感 / 多武器齐射观感 / 武器平衡」→ 不计入出口，由 #5 收进 `PLAYTEST_CHECKLIST.md`

### Day 6 — 阶段 A 集成测试　✅【客观任务完成 · 已收口 · 2026-08-06 01:5x #3】

> **承接**：T-A（经验链路数据化 + 首升配比校准 + 端到端探针）—— PLAYTEST 追踪区 🟡 待 #2 拾取（证据最硬），#1 第 8 轮「下一步」明示优先纳入；T-B（经验可见性）为 P1 顺延。
> **护栏**：改前 `git commit` 存档；改后 `python tools/baseline_check.py` 必须 `BASELINE CLEAN`。
> **文件域**：W1 写 `scripts/` + `tools/`（探针）；W2 只写 `data/enemies.json` + `data/weapons.json`；W5 写 `docs/REPORT_PHASE_A.md` + `docs/TEST_REPORT.md`。**无跨域冲突**。
> **角色矩阵**（DAY_ROLE_ASSIGNMENTS Day 6 行）：W1 集成 ● / W2 平衡初调 ● / W5 全量 baseline + 报告 ●。
> **本轮实测基线（#3 免重复排查，01:1x #2 已核）**：
> - **T-A 硬缺口实锤**：`enemy.gd:45` `@export var exp_value: int = 1` **硬编码**；`enemies.json` **23 个敌人（15 regular + 6 elite + 2 boss）全部无 `exp_value` 字段**；`DataLoader.get_scaled_enemy()`（`data_loader.gd:158-192`）返回字典**固定 10 键不含 exp_value**，无透传 → 全敌人经验恒 = 1
> - **首升失衡量化**：升级曲线 `"20 + current_level * 10"`（`stats.json.leveling`），wave1 仅 12 敌（8 chaser + 4 fly）→ 12 经验 **< 20，第 1 波打满升不了级**；玩家 100 HP 白板出门却无成长反馈，与「前 1 分钟理解核心循环」的爽点哲学冲突
> - **数据注入路径（D6-T2 落点）**：`enemy_spawner.gd:99` `DataLoader.get_scaled_enemy(id, wave)` → `:108-110` `enemy_scene.instantiate()` + `enemy.initialize(stats)`——**只需改 `get_scaled_enemy()` 返回值加 1 键 + `enemy.gd initialize()` 读 1 行**
> - **玩家基准**：`player.gd:17-34` max_health 100 / move_speed 300 / damage_multiplier 1.0 / crit 0.05 / crit_dmg 2.0 / armor 0 / luck 0 / life_steal 0
> - **敌人基准**：regular hp 3-80 / dmg 3-8（`enemies.json.enemies.regular`，15 只）；elite hp 200-300 / dmg 6-10（6 只）；boss invoker 8000hp / predator 15000hp（各带 `wave` 字段——W2 核验该波次合理性）；scaling 5 档公式（`base + growth*wave`，elite 乘数 `1+wave*0.15/0.08`）
> - **波次**：20 波（wave1=12 敌 → wave16=62 敌）；generation 公式 `base+wave*2` / `max(0.3, base_interval-wave*0.02)` / `min(20+wave*2, 60)`；rewards `5+wave*2` 金币
> - **武器 DPS 基准（平衡对照用）**：pistol 5/0.45s ≈ 11.1 DPS；炎星术 Lv1 6/0.55s ≈ 10.9；星刃 Lv1 7/0.5s ≈ 14（+环绕）；自动炮台 5/0.5s（3 台 = 30 DPS 上限）
> - **三英雄 penalty 已生效**（D2-T6 收口）：艾琳 max_hp 90 / 诺亚攻速 0.85 / 莱恩 range -20 —— 平衡基准必须基于 penalty 后数值
> - ⚠️ **PROGRESS.md 双源风险**：该文件为 #1 每 2h **独占追加**；30DAY_PLAN 粗粒度「产出阶段 A 报告 → PROGRESS.md」若由 #3/#5 落笔会造成双写冲突 → **定案：阶段 A 报告独立成文 `docs/REPORT_PHASE_A.md`（W5 域），PROGRESS.md 只由 #1 维护**

#### 本日总定案（先读，避免执行期临场决策）
| 议题 | 定案 | 依据 |
|------|------|------|
| exp_value 数据落点 | `data/enemies.json` 23 敌补 `exp_value` 字段 → `get_scaled_enemy()` 返回值补 `"exp_value"` 键 → `enemy.gd initialize()` 读 `stats.get("exp_value", 1)` | 数据注入路径已实测（spawner→get_scaled_enemy→initialize）；硬编码 1 是 T-A 根因 |
| 首升配比目标 | **第 1 波结束前升 1 级**（wave1 累计经验 ≥ 20）；第 2 波中段升 2 级 | 玩家 100 HP 出门，首升过早无意义、过晚无成长反馈；20 需求曲线已定 |
| exp_value 建议梯度 | regular 按威胁 2~15（chaser 2 / fly 3 / bruiser 6 / slasher 10 / mad_slasher 15）；elite 25~40；boss 300~500 —— **W2 定稿并写进 JSON** | wave1 = 8×2 + 4×3 = 28 ≥ 20 ✓ 满足首升目标；梯度随 HP/威胁正相关 |
| 阶段 A 报告落点 | **新建 `docs/REPORT_PHASE_A.md`**（W5 域）：六日回顾 + 集成结论 + 平衡结论 + 遗留风险 | PROGRESS.md 为 #1 独占追加，双写冲突；报告是 W5 一次性交付物，独立成文可回读 |
| 手感冒烟 | **主观项 → #5 归档 PLAYTEST_CHECKLIST，不阻塞 Day 6 出口** | 项目铁律：主观不进关键路径（Day 29 集中）；W5 客观部分 = 回归 + 报告 |
| T-B 经验可见性 | P1：W1 产能不足可顺延 **Day 7 首段**，不阻塞本日出口 | 中优打磨项；T-A（客观链路）才是 P0 |
| T-C 炮台提示 / T-D 技能图标 | **不进本日**：T-C 归 Day 17（精英/炮台域）或 backlog；T-D backlog（用户明示不急） | PLAYTEST 追踪区已标优先级 |

#### D6-T1【W2 · P0 · T-A-1】敌人经验数据化（`data/enemies.json`）
- [x] 为 **23 个敌人全部** 补 `exp_value` 字段（15 regular + 6 elite + 2 boss），按「定案表」梯度定稿；**禁止只给 wave1 出场的敌人补**（后续波次敌人也要有值，否则 scaling 后经验归 1）✅ 23/23 已补（chaser 3 / fly 3 / charger 4 / … / mad_slasher 15；elite 30-40；boss invoker 400 / predator 500）
- [x] `exp_value` 应随威胁/HP 正相关（示例：chaser 2 / fly 3 / bruiser 6 / slasher 10 / mad_slasher 15 / butcher(精英) 30 / invoker(Boss) 400）—— 最终值 W2 依据「首升目标 + 击杀时间」平衡 ✅ 梯度按威胁/HP 正相关定稿
- [x] ⚠️ **不修改** `scaling` 公式（hp/damage/speed 的 wave 成长保持现状，本日只补经验维）✅ 未动 scaling
- 测试点：`python -c` JSON 校验通过；23/23 敌人均有 `exp_value` 且为正整数；`grep -c exp_value data/enemies.json` ≥ 23 ✅ 全部通过（实测 23/23 正整数）

#### D6-T2【W1 · P0 · T-A-2】消费 exp_value（`data_loader.gd` + `enemy.gd`）
- [x] `data_loader.gd get_scaled_enemy()`（`:158-192`）返回值补键：`"exp_value": int(data.get("exp_value", 1))`（兜底 1 = 现状行为，字段缺失不崩）✅ 已补（:191）
- [x] `enemy.gd` `initialize(stats)` 内补：`exp_value = int(stats.get("exp_value", exp_value))`（**保留 @export 默认 1 兜底**，直开调试路径不崩；`initialize` 现有 stats 键映射照抄风格）✅ 已补（initialize 内 `if stats.has("exp_value")`）
- [x] `enemy.gd:395-396` `_drop_rewards()` 的 `gain_exp(exp_value)` **零改动**（已消费该字段）✅ 未改该行（仅在其后追加 D6-T4 飘字）
- 测试点：wave1 杀 1 chaser → `player.exp == 2`（非 1）；杀 1 fly → `exp == 3`；`well_rounded` 直开 `Main.tscn` 杀敌不崩 ✅ 实测 exp==3（chaser 校准后），探针断言从 JSON 读期望值

#### D6-T3【W1 · P0 · T-A-3】端到端集成探针（新建 `tools/day6_integration_check.gd`）
- [x] 照搬 `tools/day5_weapon_check.gd` 的 `extends SceneTree` + 分帧推进骨架，覆盖**阶段 A 全链路**（选角→进局→武器→击杀→经验→升级→技能→6槽→死亡/重开）✅ 新建，7 段全链路覆盖
  1. 直开 `Main.tscn`（无 meta）→ 兜底英雄 `well_rounded` 进局零 error　【回归 D2-T1a】✅
  2. 注入英雄 `se_irene` → 首武器 `se_star_flame`、`exp == 0`、`level == 1`　【D2 链路】✅
  3. 手动调 `enemy.initialize`（或直接 spawn）杀 1 敌 → `player.exp == exp_value`（读 JSON 值，非 1）　【T-A 收口 · D6-T1/T2】✅
  4. 累计经验跨过 20 → `level == 2` + `level_up` 信号触发　【D4 链路】✅（实际曲线 Lv1→2=30，探针按 30 断言）
  5. `try_cast()` 火球成功 + 冷却生效（二次 false）　【D3 链路】✅
  6. 装备第 6 把武器 → `is_full()`；第 7 把被拒　【D5 链路】✅
  7. `player.die()` → GameOver 面板 + `paused == true`；重开 → 场景重载零 error　【D4-T7/BUG-001 回归】✅
- [x] 断言数 ≥ 12（拆分细分），全部通过输出 `DAY6 INTEGRATION CHECK CLEAN` ✅ **14 断言 0 失败（DAY6 INTEGRATION CHECK CLEAN，exit 0）**
- 测试点：`godot --headless` 跑该脚本 exit 0；失败时输出具体断言行号 ✅ exit 0

#### D6-T4【W1 · P1 · T-B】经验可见性（中优，可顺延 Day 7 首段）
> PLAYTEST 追踪区 T-B：经验获取无任何视觉反馈（掉落物/飘字/拾取感缺失；`fx_pickup` 闲置、`pickup_range` 未接线）。
- [x] 最低可行闭环（三选一即可，推荐 A）✅ **方案 A 已实装（本轮完成，未顺延）**：`enemy._drop_rewards()` 调 `gain_exp` 后生成 Label 飘字「+N」上浮 0.6s 淡出消失（挂 VfxContainer，缺失时回退 current_scene，再无则静默跳过不崩）
      - A · 经验飘字：`enemy._drop_rewards()` 调 `gain_exp` 处生成 `Label` 飘字「+N」上浮 0.6s 消失（挂 World，样式对齐 VfxPlayer 占位风格）✅
      - B · 拾取感：`fx_pickup` 特效在升级时触发（`level_up` 信号 → `VfxPlayer.spawn(..., "pickup")`）—（未选）
      - C · 经验条闪动：`hud.gd` XpBar 在 `xp_changed` 时做短暂高亮 modulate —（未选）
- [x] 判定：P1，**不计入 Day 6 出口**；未完成顺延 Day 7 首段，不阻塞目标日推进 ✅ 已提前完成，计入本日
- 测试点：击杀敌人后 World 下出现飘字节点并在 0.6s 后消失；无特效容器时不崩 ✅（day6 探针杀敌路径下 VfxContainer 挂 Label 无异常；容器缺失走静默分支）

#### D6-T5【W2 · P0】平衡初调（基础数值）
> 目标：找出阶段 A 明显失衡点并微调（**全部改动必须附对照表依据，禁臆造**）。
- [x] **必查清单（按优先序）**：
  1. **首升节奏**（T-A 收口后验证）：wave1 打满 → `level == 2`；wave1+wave2 → `level == 3`（经验曲线 20/30）✅ **校准**：实测曲线 Lv1→2=30（`20+current_level*10`，#2 定案误读为 20）→ wave1=36≥30 ✓、wave1+2=95≥70 ✓（详见 REPORT_PHASE_A §3.1）
  2. **敌人 scaling vs 玩家成长**：取 chaser/fly/bruiser/slasher 四型，按 `hp_formula` 算 wave 1/6/11/16 的 HP，对照玩家对应阶段武器 DPS（Lv1 手枪 11 / Lv4 签名 ≈ 20-25 / Lv8 签名 ≈ 40+）——找出「wave N 单敌需要 > 5s 击杀」的断层点 ✅ 对照表完成（wave1-3 无断层；wave11+ 单武器口径 >5s 登记观察项，未计入合成 DPS 不臆造调值）
  3. **Boss 数值**：核验 `invoker`/`predator` 的 `wave` 字段对应波次，8000/15000 HP 在该波次玩家 DPS 下击杀时间是否 > 90s（过久则下调 HP 或调高成长）✅ invoker 60-90s 边缘可接受 / predator ~62s 合理，均不动
  4. **三英雄 penalty 后基准**：艾琳 90 HP / 诺亚 0.85 攻速 / 莱恩 range-20 的存活与输出是否可接受（对照普通敌人 3-8 伤害）✅ 均可接受，不动
  5. **经济**（可选）：`rewards` 5+wave*2 金币 vs 商店价格（`items.json` price 分布）——明显买不起时登记，不动数据 ✅ 最便宜 8 金币 vs wave1 结束 7 金币 → 登记观察项，不动
- [x] 微调范围限制：**只动 `data/enemies.json` / `data/weapons.json` / `data/waves.json` 的数值字段**；结构/schema/公式不改（公式改归 Day 13）✅ 仅动 enemies.json（chaser 2→3 / charger 3→4）
- [x] 产出**平衡对照表**（写入 `docs/REPORT_PHASE_A.md` §平衡结论，D6-T6 引）：每项调整 = 前值 → 后值 → 依据（对照数据）✅ §3 完成
- 测试点：`python -c` 三文件 JSON 校验通过；wave1 至 wave3 无「单敌 >5s」断层（对照表自证）✅

#### D6-T6【W5 · P0】全量回归 + 阶段 A 报告
- [x] **全量回归四件套**：`day2_hero_check` 32/0 + `day3_skill_check` 16/0 + `day4_level_check` 21/0 + `day5_weapon_check` 15/0（**D6-T2 改 `get_scaled_enemy`/`initialize` 后 day4 断言 1「exp == exp_value」需同步用新值——先跑，红了按新 exp_value 更新断言数值**）✅ 四件套全绿（32/16/21/15，0 失败，无需改断言——day4 断言已兼容）
- [x] 新建 `docs/REPORT_PHASE_A.md`，结构：
      - §1 阶段 A 六日回顾（D1-D5 收口提交哈希 + D6 集成结论）✅
      - §2 集成测试结果（D6-T3 探针通过率 + 全量回归表）✅ 14/14 + 四件套
      - §3 平衡结论（引用 D6-T5 平衡对照表：调整项 + 前/后值 + 依据）✅
      - §4 遗留风险（exp 曲线后续校准 / 29 把旧武器 levels 缺口 / Boss 击杀时间复核 / 主观项指针 → PLAYTEST）✅
- [x] `python tools/baseline_check.py` → `BASELINE CLEAN` ✅
- [x] `git commit`（护栏：实现落地≠收口）✅

#### D6-EXIT【W5】当日出口
- [x] `python tools/baseline_check.py` → `BASELINE CLEAN`（import + runtime 双阶段，exit 0 / stderr 0）✅
- [x] `tools/day6_integration_check.gd` 全部断言通过 → `DAY6 INTEGRATION CHECK CLEAN`（≥12 断言，含 T-A 收口断言 3）✅ **14 断言 0 失败**
- [x] 回归四件套全绿（day2 32 / day3 16 / day4 21 / day5 15，0 失败）✅
- [x] `docs/REPORT_PHASE_A.md` 存在且 §1-§4 齐全（含平衡对照表）✅
- [x] **护栏**：`git commit`（Day 3/4/5 破口教训，必须提交）✅
- ⚠️ 主观项「手感冒烟 / 阶段 A 整体手感 / 升级节奏体感」→ 不计入出口，由 #5 收进 `PLAYTEST_CHECKLIST.md`（H-01/H-02/H-03 已在）✅ 不阻塞

---

## 阶段 B · Build 系统（Day 7–13）

### Day 7 — MVP 15 武器数据 + 装配消费 + 图标集　✅【2026-08-06 03:3x · #3 收口】

> **承接**：REPORT_PHASE_A §4.2「29 把旧武器缺 `levels` 升级表 → Day 7–9 批量补数据」；30DAY_PLAN D7-D9「15 武器数据 + 精灵（Lv1-8：伤害/数量/范围/攻速升级），优先 3 签名 + 12 通用」。
> **护栏**：改前 `git commit` 存档；改后 `python tools/baseline_check.py` 必须 `BASELINE CLEAN`。
> **文件域**：W1 写 `scripts/`（weapon.gd / weapon_controller.gd / icon_atlas.gd）+ `tools/`（探针）；W2 只写 `data/weapons.json`；W3 只写 `assets/sprites/ui/weapons.png`；W5 写 `docs/TEST_REPORT.md`。**无跨域冲突**。
> **角色矩阵**（DAY_ROLE_ASSIGNMENTS Day 7 行细化）：W1 装配消费 ● / W2 数据补全 ● / W3 图标扩容 ● / W5 回归 ●；W4 —（无职责）。
> **本轮实测基线（#3 免重复排查，03:1x #2 已核）**：
> - `weapons.json` 顶层 `{weapons: {melee|ranged|elemental|engineering: [数组]}}`，共 **33 把**；仅 **4 把有 `levels`**（`se_star_flame`/`se_auto_turret`/`se_star_blade`/`se_holy_staff`，各 8 条 + `max_level:8`）→ **29 把缺口**
> - 无 levels 旧武器字段 = `damage/cooldown/range/crit_chance/crit_damage/scaling/special/tier/price`（**无** levels/max_level/projectiles/knockback/icon_index）
> - 签名武器 levels 范式（**绝对状态值** 8 条）：`{level, damage, cooldown, range, projectiles?, upgrade}`；环绕型追加 `blade_count/orbit_radius/orbit_speed`；召唤型追加 `summon_count/duration`
> - `weapon.gd _on_upgrade()`（:83-104）消费键：`damage`/`cooldown`(→fire_rate 取倒数)/`projectiles`/`range`/`blade_count`+`orbit_*` —— **不消费 `crit_chance`/`crit_damage`/`pierce`/`summon_count`/`duration`**；表空回退通用成长 ×1.25/×1.1（max_level 默认 5）
> - `weapon.gd` **无 `crit_chance`/`crit_damage` 字段**（需补）；`pierce` 字段已有（:28）但 build 未消费
> - `build_weapon_from_data`（weapon_controller.gd:105-135）消费：name/category/special/damage/cooldown/range/projectiles/knockback/levels/max_level/blade_count+orbit —— **未消费 `crit_chance`/`crit_damage`/`pierce`/`icon_index`**
> - IconAtlas（icon_atlas.gd:8-19）：`weapons.png` = 128×32 = **4 帧 32×32**（frame_count=4）→ 33 把武器不够映射；`items.png` 同 4 帧（**本日不动**，Day 11-12 被动时再扩）
> - HUD 消费点：`hud.gd:158` `IconAtlas.get_icon("weapons", weapon.icon_index)` → 当前所有武器 `icon_index` 默认 0（build 未消费）→ 全部显示第 0 帧
> - `turret.gd` 由 `SkillController._cast_deploy_turret`（:146-164）直接传 JSON dict（`se_auto_turret`），**不走** `build_weapon_from_data` → 召唤类 `summon_count/duration` 随武器等级成长**本日不做**（登记 Day 13）
> - 升级池/商店选项范围 vs 15 把就绪范围的一致性 → 登记 Day 13 Build 集成统一（本日不动逻辑）

#### 本日总定案（先读，避免执行期临场决策）
| 议题 | 定案 | 依据 |
|------|------|------|
| MVP 15 武器清单 | **4 已备 levels（se_star_flame / se_auto_turret / se_star_blade / se_holy_staff）+ 11 通用补 levels**：melee 2（sword / chainsaw）· ranged 4（pistol / smg / shotgun / sniper）· elemental 3（wand / icicle / flamethrower）· engineering 2（turret / landmine） | 30DAY_PLAN「3 签名 + 12 通用」口径；四分类覆盖 + tier1-3 + 攻击范式差异（单发/连射/散射/重击/持续/放置）确保 Build 多样性可验；剩余 14 把归 Day 8-9 |
| levels 字段集 | 11 把补 `levels` 8 条 = `{level, damage, cooldown, range, projectiles?, upgrade}`（**绝对状态值**）；**不放** crit/pierce/summon 进阶键（防数据写了没人读） | weapon.gd `_on_upgrade` 消费键实测；30DAY_PLAN「伤害/数量/范围/攻速升级」四维口径 |
| levels 成长规范 | Lv1 条与顶层字段**完全一致**（防首装偏差）；damage 逐级 **×1.2–1.35** 左右（参照签名曲线形态，星刃 Lv1 7→Lv8 32）；cooldown 每 2 级 −5–8%；range 每 3 级 +5–10%；projectiles 在特定级 +1（如 shotgun 3 发起步） | 签名武器曲线形态实测 + D6 平衡对照表（Lv4 ≈20-25 / Lv8 ≈40+ DPS 锚点） |
| 装配消费补齐 | weapon.gd 补 `crit_chance/crit_damage` 导出字段（默认 0.0/1.0）；build_weapon_from_data 消费 `crit_chance/crit_damage/pierce/icon_index`（`data.get(..., 0)` 兜底）；`_on_upgrade()` 补消费 levels 中可选 `crit_chance/crit_damage/pierce`（**防 Day 8-9 放键漏消费**，2 行低风险） | 旧武器 JSON 已含 crit 字段但装配丢弃（实锤缺口）；HUD 图标全 0 帧（实锤） |
| 图标集扩容 | `weapons.png` **4 帧 → 40 帧（1280×32）**：**15 帧实绘**（MVP 15 武器按分类色系：melee 银灰 / ranged 棕 / elemental 蓝紫 / engineering 橙黄）+ 25 帧分类色占位（Day 8-9 逐帧替换）；icon_atlas.gd `frame_count` 4→40；33 把全部补 `icon_index`（分类内顺序索引 melee 0-7 / ranged 8-16 / elemental 17-25 / engineering 26-32） | 32×32 图标基准（ART_STYLE v2 UI 视口 640×360 不变）；一次扩容免二次返工 |
| 召唤类成长 | `summon_count/duration` 本日**只收进 Weapon 资源字段不消费**（turret.gd 走 SkillController 直传 JSON dict，改动面大）；登记 Day 13 | turret.gd 接口实测；诺亚 3 台上限已平衡（D6 §3.4） |
| 升级池范围 | 本日**不动** LevelUpPanel 选项池逻辑（现状可跑：无 levels 武器走通用成长不崩） | 选项池范围统一归 Day 13 Build 集成 |

#### D7-T1【W2 · P0】MVP 15 武器 levels 数据补全（`data/weapons.json`）
- [x] 按「定案表」为 **11 把通用武器**补 `levels` 8 条 + `max_level: 8`：sword / chainsaw / pistol / smg / shotgun / sniper / wand / icicle / flamethrower / turret / landmine；字段集 = `{level, damage, cooldown, range, projectiles?, upgrade}`（绝对状态值，**Lv1 条与顶层字段一致**）✅ `tools/gen_weapons_day7.py` 幂等生成（可重跑），含 damage 单调不减 / cooldown 单调不增 / Lv1==顶层 / signature 未被改 校验
- [x] 4 把已有 levels 武器（se_star_flame / se_auto_turret / se_star_blade / se_holy_staff）**只核验不改** ✅ 探针 Part 1 断言通过
- [x] 升级描述文案 `upgrade` 逐级填写（「伤害提升」「攻速提升」「弹数+1」…，供升级面板展示）✅
- [x] ⚠️ **不改** 顶层 `damage/cooldown/range/scaling/special`（商店/首装数值口径保持现状；levels 是叠加层）✅ 探针断言 Lv1==顶层
- 测试点：JSON 校验通过 ✅；≥15 把武器 `levels` 8 条 ✅；抽查 3 把 Lv1==顶层 ✅；levels 内 damage 单调不减 ✅

#### D7-T2【W1 · P0】装配消费补齐（`weapon.gd` + `weapon_controller.gd`）
- [x] `weapon.gd` 成长属性组补导出字段：`crit_chance: float = 0.0`、`crit_damage: float = 1.0` ✅（:21-32 战斗属性区追加）
- [x] `build_weapon_from_data`（weapon_controller.gd:120-126）补消费 4 键：`crit_chance` / `crit_damage` / `pierce` / `icon_index`（**沿用 `data.get(..., 默认)` 兜底范式**，字段缺失不崩）✅
- [x] `_on_upgrade()`（weapon.gd:106-114）补 3 行消费：`entry.has("crit_chance")` / `entry.has("crit_damage")` / `entry.has("pierce")` ✅（**兼容未来 levels 放进阶键**，本日 levels 不放也不受影响）
- [x] ⚠️ 不引入新依赖/不改 `fire()` / `_spawn_projectile()` 弹丸生成（伤害/暴击结算点不变，暴击判定归 Day 13 公式统一）✅
- 测试点：`build_weapon_from_data("pistol")` 探针实测 → `crit_chance == 0.05` / `crit_damage == 1.5` / `icon_index == 8` ✅；`build_weapon_from_data("sword")` 后 `upgrade()` → Lv2 base_damage 15 / fire_rate 2.0 ✅

#### D7-T3【W3 · P0】武器图标集扩容（`assets/sprites/ui/weapons.png`）
- [x] 新建 `weapons.png` **1280×32（40 帧 × 32×32）**：**15 帧实绘**（MVP 15 把，像素风格对齐 ART_STYLE v2：1-2px 描边 / 透明键左上角 / 高饱和分类色）+ **18 帧分类色占位**（深底 + 类别简形：melee/ranged/elemental/engineering 各自方块+简形）+ 7 帧空余（33-39）✅ `tools/gen_weapon_icons.py` 程序化生成（PixelArt 像素图 + 描边 + 分类色）
- [x] 帧序 = D7-T5 定案映射（详见 D7-T5 映射表：melee 0-7 / ranged 8-16 / elemental 17-25 / engineering 26-32）✅
- [x] 导出 PNG（RGBA / Nearest 渲染无丢失）；`weapons.png.import` 保留原 import 设置（Godot 会重导入）✅ import 文件未改
- 测试点：PNG 尺寸 1280×32 ✅；40 帧各 32×32 ✅；（0,0）透明键 ✅；frames 33-39 全透明 ✅

#### D7-T4【W1 · P0】IconAtlas 帧数同步 + HUD 验证
- [x] `icon_atlas.gd` SHEET_CONFIG `weapons.frame_count`: 4 → **40**（items 保持 4 不动）✅
- [x] 冒烟：`IconAtlas.get_icon("weapons", 0)` / `get_icon("weapons", 39)` 返回非 null ✅；`get_icon("weapons", 40)` 返回 null 且 push_warning（越界保护不崩）✅
- 测试点：headless 直开 Main 后 HUD `_refresh_weapon_slots` 遍历 icon_index ≤ 39 不越界 ✅ baseline_check import+runtime 双阶段 PASS

#### D7-T5【W2 · P0】33 把武器补 `icon_index` 字段（`data/weapons.json`）
- [x] 33 把全部补 `icon_index`（分类内顺序索引：melee 0-7 / ranged 8-16 / elemental 17-25 / engineering 26-32）✅
- [x] `id ↔ icon_index` 映射表写入本条目完成备注（W3 与 W2 同源核对）⬇
- [x] 修正定案表内部不一致：spec 例举 `sword 0 / chainsaw 1 / se_star_blade 7 / pistol 8 / smg 9 / shotgun 10 / sniper 16 / se_holy_staff 16?` 与「分类内顺序索引」规则冲突；**以规则为准**（weapons.json 数组顺序 = 帧顺序），映射表如下
- 测试点：33/33 有 icon_index 且 0 ≤ v ≤ 32 ✅；MVP 15 把索引互不重复 ✅

**`id ↔ icon_index` 完稿映射表**（同源 D7-T3 与 D7-T5，W3 与 W2 一致）：

| idx | melee (0-7) | ranged (8-16) | elemental (17-25) | engineering (26-32) |
|---:|:---|:---|:---|:---|
| 0 | fist 🔲 | | | |
| 1 | stick 🔲 | | | |
| 2 | dagger 🔲 | | | |
| 3 | **sword** ⭐ | | | |
| 4 | hammer 🔲 | | | |
| 5 | **chainsaw** ⭐ | | | |
| 6 | flaming_knuckles 🔲 | | | |
| 7 | **se_star_blade** ⭐ (签) | | | |
| 8 | | **pistol** ⭐ | | |
| 9 | | slingshot 🔲 | | |
| 10 | | crossbow 🔲 | | |
| 11 | | **smg** ⭐ | | |
| 12 | | **shotgun** ⭐ | | |
| 13 | | **sniper** ⭐ | | |
| 14 | | rocket_launcher 🔲 | | |
| 15 | | minigun 🔲 | | |
| 16 | | **se_holy_staff** ⭐ (签) | | |
| 17 | | | **wand** ⭐ | |
| 18 | | | **icicle** ⭐ | |
| 19 | | | lightning_shiv 🔲 | |
| 20 | | | **flamethrower** ⭐ | |
| 21 | | | venom_staff 🔲 | |
| 22 | | | storm_staff 🔲 | |
| 23 | | | frost_nova 🔲 | |
| 24 | | | plasma_cannon 🔲 | |
| 25 | | | **se_star_flame** ⭐ (签) | |
| 26 | | | | **turret** ⭐ |
| 27 | | | | **landmine** ⭐ |
| 28 | | | | wrench 🔲 |
| 29 | | | | laser_turret 🔲 |
| 30 | | | | mech_arm 🔲 |
| 31 | | | | force_field 🔲 |
| 32 | | | | **se_auto_turret** ⭐ (签) |

> ⭐ = MVP 15 把实测绘帧；🔲 = 18 帧分类色占位（Day 8-9 逐帧替换）；(签) = 4 把签名武器

#### D7-T6【W1 · P0】武器数据探针（新建 `tools/day7_weapon_data_check.gd`）
- [x] 照搬 `day6_integration_check.gd` 骨架（`extends SceneTree` + 分帧推进），覆盖 5 段：
  1. **JSON 层**：11 把通用武器 levels 8 条 + max_level ≥ 8；3 把 Lv1 与顶层 damage/cooldown/range 一致；levels 内 damage 单调不减、cooldown 单调不增；4 把签名武器 levels 未被 D7-T1 破坏　【D7-T1】
  2. **装配层**：build_weapon_from_data("pistol") 装配后 crit_chance 0.05 / crit_damage 1.5 / icon_index 8 消费；build_weapon_from_data("sword") upgrade() → Lv2 base_damage 15 / fire_rate 2.0 ✅　【D7-T2】
  3. **图标层**：IconAtlas.get_icon("weapons", 0/39) 非 null、(40) null + push_warning 不崩 ✅　【D7-T4】
  4. **回归层**：equip_from_data("se_star_flame") 首武器正常 + icon_index 25 + 来源标记 ✅
  5. **枚举层**：33 把武器 icon_index 0≤v≤32 互不重复；MVP 15 把互不重复 ✅　【D7-T5】
- [x] 断言数 13，全部通过输出 `DAY7 WEAPON DATA CHECK CLEAN`（exit 0）✅
- 测试点：`godot --headless` 跑该脚本 exit 0 ✅；失败输出断言行号 ✅

#### D7-EXIT【W5】当日出口
- [x] `python tools/baseline_check.py` → **BASELINE CLEAN**（import + runtime 双阶段，exit 0 / stderr 0）✅
- [x] `tools/day7_weapon_data_check.gd` 全部断言通过 → **DAY7 WEAPON DATA CHECK CLEAN（13 断言）** ✅
- [x] 回归五件套全绿（day2 32 / day3 16 / day4 21 / day5 16 / day6 14）+ **day5 探针同步更新**（pistol 通用成长 → 合成裸武器 兜底测试，因 D7-T1 给 pistol 补了 levels）✅
- [x] `python tools/gen_weapons_day7.py verify` → **DAY7 WEAPONS JSON VERIFY CLEAN**（33 把 icon_index + 11 把 levels 齐）✅
- [x] **护栏**：`git commit`（阶段 B 首段收口）✅
- ⚠️ 主观项「武器图标观感 / 升级曲线体感」→ 由 #5 收进 `PLAYTEST_CHECKLIST.md`，不阻塞出口

**Day 7 收口交付物**：
- `data/weapons.json`（+21KB，11 把 × 8 条 levels + 33 把 icon_index）
- `assets/sprites/ui/weapons.png`（1280×32，40 帧，15 实绘 + 18 占位 + 7 空余）
- `scripts/weapons/weapon.gd`（+10 行：crit_chance/crit_damage 字段 + _on_upgrade 3 行可选键消费）
- `scripts/weapons/weapon_controller.gd`（+4 行：build_weapon_from_data 4 键消费）
- `scripts/utils/icon_atlas.gd`（frame_count 4→40）
- `tools/gen_weapons_day7.py`（新建：数据生成 + 校验 幂等工具）
- `tools/gen_weapon_icons.py`（新建：图标集生成工具）
- `tools/day7_weapon_data_check.gd`（新建：13 断言探针）
- `tools/day5_weapon_check.gd`（同步更新：通用成长兜底改用合成裸武器）
- `docs/TASKS.md`（Day 7 标题 ✅ + T1~T6/EXIT 全部 [x] + 完整 id↔icon_index 映射表）

### Day 8–9 — 18 把武器全量补全 + 图标实绘 + 全量数据回归　✅【2026-08-06 05:3x · #3 收口】

> **承接**：Day 7 收口（`fc2a636`）——MVP 15 把 levels + 33 把 icon_index + 40 帧图标（15 实绘 + 18 占位 + 7 空余）。本区间消灭全部剩余缺口：**18 把通用武器补 levels + 18 帧占位图标实绘** → 30DAY_PLAN D7-D9「15 武器数据 + 精灵」至此**全量完成（33/33）**。
> **护栏**：改前 `git commit` 存档；改后 `python tools/baseline_check.py` 必须 `BASELINE CLEAN`。
> **文件域**：W1 写 `tools/`（探针 `day8_weapon_data_check.gd`）；W2 写 `data/weapons.json` + `tools/gen_weapons_day7.py`（扩展）；W3 写 `assets/sprites/ui/weapons.png` + `tools/gen_weapon_icons.py`（扩展）；W5 写 `docs/TEST_REPORT.md`。**无跨域冲突**。
> **角色矩阵**（DAY_ROLE_ASSIGNMENTS Day 7-9 行细化）：W1 ◐探针 / W2 ●18 把 levels / W3 ●18 帧实绘 / W5 ●回归六件套；W4 —（无职责）。
> **本轮实测基线（#3 免重复排查，05:1x #2 第 9 轮新核）**：
> - `weapons.json` 33 把：**15 把有 levels**（D7 完成）/ **18 把无 levels**（fist/stick/dagger/hammer/flaming_knuckles/slingshot/crossbow/rocket_launcher/minigun/lightning_shiv/venom_staff/storm_staff/frost_nova/plasma_cannon/wrench/laser_turret/mech_arm/force_field）→ 本区间补齐后 **33/33 全量**
> - 18 把顶层字段（本轮已导出）：全部有 `damage/cooldown/range/scaling/tier/price/icon_index`；melee/ranged/elemental 另有 `crit_chance/crit_damage`；elemental 另有 `element_type`；engineering 4 把（wrench/laser_turret/mech_arm/force_field）**无 crit 字段**
> - **18 把顶层均无 `projectiles` 字段** → levels 字段集 = `{level, damage, cooldown, range, upgrade}` 5 键（四维 + 文案），与 D7 范式一致
> - **特例 1 force_field**（t3 engineering）：顶层 `damage: 0` / `cooldown: 2.0` / `range: 120` / special「生成护盾区域, 减伤50%」→ levels damage 恒 0（护盾无伤害，单调不减天然满足），只升 cd（→1.5）与 rng（→160）
> - **特例 2 minigun**（t4 ranged）：顶层 `cd: 0.08`（全表最低）→ levels cd 微降（→0.055），damage 4→~19（×1.25 型）
> - 已补 levels 武器 Lv8 锚点（D7 实值，新曲线对齐用）：pistol 22/0.33/308 · sniper 40→158 ×3.95 / 1.18/475 · landmine 20→80 ×4.0 / 0.76/124 · chainsaw 8→33 ×4.1 / 0.08/180 · flamethrower 2→10 ×5.0 / 0.04/198 → **DPS 上限参照**：重击型（hammer/rocket/plasma）走 ×4 左右总量，控单发爆炸
> - `weapons.png` = 1280×32 **40 帧**：帧 3/5/7/8/11/12/13/16/17/18/20/25/26/27/32 已实绘（MVP 15），帧 **0/1/2/4/6/9/10/14/15/19/21/22/23/24/28/29/30/31 仍为分类色占位**（🔲），帧 33-39 全透明空余
> - 装配链路已通（D7-T2）：`build_weapon_from_data` 消费 `damage/cooldown/range/projectiles/levels/max_level/crit_chance/crit_damage/pierce/icon_index` → 18 把补 levels 后**无需任何代码改动**，纯数据 + 图标 + 探针日
> - 工具结构（复用）：`gen_weapons_day7.py` = `LEVELS` dict（dmg/cd/rng/proj/up 五数组）+ `build_levels(wid, top)`（Lv1 强制取顶层）+ `apply()`（幂等：`"levels" not in w` 才写）+ `verify()`（遍历 `LEVELS.keys()`）→ **+18 把只需扩 LEVELS 表**，apply/verify 自动覆盖
> - 工具结构（复用）：`gen_weapon_icons.py` = `Icon` 类像素原语（set/rect/rect_o/line/diamond/disc/tri）+ 40 帧画布 + 帧表 → **+18 帧只需新增 18 个实绘函数并在帧表注册**

#### 本日总定案（先读，避免执行期临场决策）
| 议题 | 定案 | 依据 |
|------|------|------|
| 18 把清单 | **18 把**（修正原粗条目「14 把」文字矛盾，以括号清单 + 实测为准）：melee 5（fist/stick/dagger/hammer/flaming_knuckles）· ranged 4（slingshot/crossbow/rocket_launcher/minigun）· elemental 5（lightning_shiv/venom_staff/storm_staff/frost_nova/plasma_cannon）· engineering 4（wrench/laser_turret/mech_arm/force_field） | 实测 weapons.json 33 − 15 = 18 |
| levels 字段集 | `{level, damage, cooldown, range, upgrade}` 5 键（**无 projectiles**——18 把顶层均无此字段；**不放** crit/pierce 进阶键，顶层 crit 已装配消费） | 18 把顶层字段实测；D7 范式统一；防过度设计 |
| levels 成长规范 | Lv1 条与顶层完全一致；damage 逐级 ×1.18–1.32（t1 轻快型 ×1.25 附近 / t3-4 重击型 ×1.22 附近控 DPS）；cooldown 每 2 级 −5–8%；range 每 2-3 级 +3–6% 取整；**Lv8 建议目标**见下表（W2 可微调，必须过单调校验） | D7 定案表 + 实测曲线形态 |
| force_field 特例 | damage 恒 0（护盾无伤害）；levels 只升 cd（2.0→1.5）与 rng（120→160）；upgrade 文案「护盾范围扩大 / 冷却缩短」 | 顶层 damage:0 实测；护盾型语义 |
| 工具策略 | **扩展 `gen_weapons_day7.py`**（LEVELS +18 把；docstring 更新为 Day 7–9 全量；apply 幂等只补无 levels 武器；verify 自动覆盖 33 把）——不新建 day89 工具，防双源漂移 | 工具幂等设计实测（`"levels" not in w`）；Day 7 收口记录不变 |
| 图标策略 | **扩展 `gen_weapon_icons.py`**：18 帧占位（idx 0/1/2/4/6/9/10/14/15/19/21/22/23/24/28/29/30/31）逐帧替换为实绘；分类色系对齐 D7（melee 银灰 / ranged 棕 / elemental 蓝紫+元素点缀 / engineering 橙黄）；**不动已收口 15 帧**（帧序/尺寸锚点）；33-39 空余帧保持透明 | D7-T3 定案 + PLAYTEST backlog（D7 帧偏简 → 本批实绘细节 ≥ 2-3 色阶） |
| 探针策略 | 新建 `tools/day8_weapon_data_check.gd`（照搬 day7 探针骨架 `extends SceneTree`）：JSON 全量 33 把 + force_field/minigun 特例 + 装配抽查 3 把 + 图标 18 帧非透明 + 回归 day7 15 把；**day7 探针不动**（历史锚点 13/13） | 防破坏 Day 7 收口记录；覆盖新增缺口 |
| 回归范围 | 六件套：day2 32 / day3 16 / day4 21 / day5 16 / day6 14 / day7 13（day5 为 D7 收口后 16 断言口径） | D7-EXIT 实测 |

**18 把 Lv8 建议目标（W2 照此生成 LEVELS 数组，可微调；必须满足 damage 单调不减 / cooldown 单调不增）**：

| id | 分类 | tier | Lv1（=顶层） | Lv8 建议 damage / cooldown / range | 特性（顶层 special） |
|---|---|---|---|---|---|
| fist | melee | 1 | 3 / 0.30 / 120 | ~14 / 0.22 / 150 | 攻速极快 |
| stick | melee | 1 | 6 / 0.55 / 160 | ~28 / 0.41 / 200 | 高击退 |
| dagger | melee | 1 | 4 / 0.25 / 130 | ~19 / 0.19 / 160 | 高暴击伤害（顶层 15%/250% 已装配消费） |
| hammer | melee | 3 | 30 / 1.20 / 200 | ~140 / 0.90 / 250 | 范围AOE（×1.22 型控 DPS） |
| flaming_knuckles | melee | 3 | 10 / 0.30 / 130 | ~47 / 0.22 / 160 | 燃烧 3 秒（fire） |
| slingshot | ranged | 1 | 4 / 0.35 / 220 | ~19 / 0.26 / 270 | 弹射 2 次 |
| crossbow | ranged | 2 | 15 / 0.90 / 300 | ~70 / 0.68 / 370 | 穿透 3 |
| rocket_launcher | ranged | 3 | 25 / 1.20 / 280 | ~117 / 0.90 / 340 | 爆炸AOE（×1.22 型控 DPS） |
| minigun | ranged | 4 | 4 / 0.08 / 260 | ~19 / 0.055 / 310 | 每3发1发长冷却 |
| lightning_shiv | elemental | 2 | 6 / 0.35 / 220 | ~28 / 0.26 / 270 | 连锁 3（lightning） |
| venom_staff | elemental | 2 | 4 / 0.60 / 200 | ~19 / 0.45 / 250 | 中毒 5 秒（poison） |
| storm_staff | elemental | 3 | 12 / 0.80 / 300 | ~56 / 0.60 / 370 | 范围闪电（lightning） |
| frost_nova | elemental | 3 | 8 / 1.00 / 180 | ~37 / 0.76 / 220 | 自身AOE 冻结 1 秒（ice） |
| plasma_cannon | elemental | 4 | 20 / 1.00 / 350 | ~94 / 0.76 / 430 | 穿透所有（plasma） |
| wrench | engineering | 2 | 8 / 0.50 / 150 | ~37 / 0.38 / 185 | 修复结构物 |
| laser_turret | engineering | 2 | 3 / 0.15 / 250 | ~14 / 0.11 / 310 | 持续激光 15 秒 |
| mech_arm | engineering | 3 | 15 / 0.60 / 180 | ~70 / 0.45 / 225 | 挥击+小型导弹 |
| force_field | engineering | 3 | 0 / 2.00 / 120 | **0** / 1.50 / 160 | 护盾减伤 50%（damage 恒 0） |

#### D8-T1【W2 · P0】18 把武器 levels 数据补全（`data/weapons.json` + `tools/gen_weapons_day7.py`）
- [x] 扩展 `tools/gen_weapons_day7.py` 的 `LEVELS` 表：按「定案表 + Lv8 建议目标」为 **18 把**补 `levels` 8 条 + `max_level: 8`；字段集 = `{level, damage, cooldown, range, upgrade}`（绝对状态值，**Lv1 条与顶层字段一致**；force_field damage 恒 0）✅
- [x] 升级描述 `upgrade` 逐级填写（force_field 全程「护盾范围扩大 / 冷却缩短」，**严禁**「伤害提升」）✅
- [x] 幂等应用：`python tools/gen_weapons_day7.py apply` 只补无 levels 的 18 把（15 把 + 4 签名 只核验不改）；`verify` 模式 **DAY7 WEAPONS JSON VERIFY CLEAN** ✅
- [x] ✅ **不改**顶层 `damage/cooldown/range/scaling/special/crit_chance/crit_damage/price/tier/element_type/icon_index`（商店/首装数值口径保持现状；levels 是叠加层）
- 测试点：JSON 校验通过 ✅；**33/33 把 levels 8 条** + max_level==8 ✅；Lv1==顶层（抽查 fist/rocket_launcher/force_field/sword/pistol/turret 6 把）✅；18 把 damage 单调不减 / cooldown 单调不增 ✅；force_field damage 全 0 合法 ✅
- 产出：`data/weapons.json`（+18 把 levels）+ `tools/gen_weapons_day7.py`（LEVELS +18 把，docstring 更新为 Day 7–9）

#### D8-T2【W3 · P0】18 帧占位图标替换为实绘（`assets/sprites/ui/weapons.png` + `tools/gen_weapon_icons.py`）
- [x] 扩展 `tools/gen_weapon_icons.py`：为 18 把（idx 0/1/2/4/6/9/10/14/15/19/21/22/23/24/28/29/30/31）各实现一帧**实绘**（像素原语 set/rect/rect_o/line/diamond/disc/tri + 分类色系 + 1px 深色描边 + 透明键左上角(0,0)）✅
- [x] ✅ **打磨细节（PLAYTEST backlog）**：每帧 ≥ 2-3 色阶 + 特征高光点（fist 指节 / stick 暗部高光 / dagger 金护手 / hammer 锤头高光 / flaming_knuckles 红金焰 / slingshot 弹丸 / crossbow 箭头 / rocket_launcher 红弹头尖 / minigun 3 管 + 弹链匣 / lightning_shiv 闪电纹 / venom_staff 绿毒珠 / storm_staff 紫雷球+黄电弧 / frost_nova 六芒+光环 / plasma_cannon 紫球+散热片 / wrench 开口环+高光 / laser_turret 红激光束 / mech_arm 关节+钳爪 / force_field 蓝球+光晕）
- [x] ✅ **不动**已收口 15 帧的帧序/尺寸/内容（锚点）；33-39 空余帧保持全透明
- [x] 重跑生成后**先合成预览图（拆 4 组 g0-g3 放大 4 倍）人工查整体效果再 commit** ✅
- 测试点：PNG 尺寸 1280×32 不变 ✅；18 帧中心 16×16 区域非全透明 ✅；(0,0) 透明键 ✅；33-39 全透明 ✅
- 产出：`assets/sprites/ui/weapons.png`（40 帧：33 实绘 + 7 空余，**零占位**）+ `tools/gen_weapon_icons.py`（+18 实绘 + PURPLE/SHIELD 新色）

#### D8-T3【W1 · P0】全量数据探针（新建 `tools/day8_weapon_data_check.gd`）
- [x] 照搬 `day7_weapon_data_check.gd` 骨架（`extends SceneTree` + 分帧推进），覆盖 5 段 ✅
  1. **JSON 全量层**：33/33 把 levels 8 条 + max_level==8 ✅；18 把 Lv1 与顶层 damage/cooldown/range 一致（抽查 fist/rocket_launcher/force_field）✅；18 把 damage 单调不减 + cooldown 单调不增（全扫）✅
  2. **特例层**：force_field levels damage 全 0（护盾型放行）✅；minigun Lv1 cooldown == 0.08（顶层一致）✅
  3. **装配层**：`build_weapon_from_data("fist")` → base_damage 3 / icon_index 0 ✅；`build_weapon_from_data("force_field")` → base_damage 0 不崩 / icon_index 31 / `upgrade()` 后 damage 仍 0 ✅；`build_weapon_from_data("rocket_launcher")` → icon_index 14 ✅
  4. **图标层**：18 帧中心 16×16 区域非全透明 ✅；(0,0) 透明键 ✅；帧 33-39 全透明 ✅
  5. **回归层**：sword Lv8 damage 50 ✅ / se_star_flame Lv8 projectiles 3 ✅ / se_star_blade Lv8 blade_count 4 ✅；33 把 icon_index 与 D7-T5 完稿映射表一致 ✅
- [x] 断言数 19（≥13），全部通过输出 `DAY8 WEAPON DATA CHECK CLEAN`（exit 0）✅
- 测试点：`godot --headless` 跑该脚本 exit 0 ✅
- 产出：`tools/day8_weapon_data_check.gd`（新建 19 断言）

#### D8-EXIT【W5】当日出口
- [x] `python tools/baseline_check.py` → **BASELINE CLEAN**（import + runtime 双阶段，exit 0 / stderr 0）✅
- [x] `tools/day8_weapon_data_check.gd` 全部断言通过 → **DAY8 WEAPON DATA CHECK CLEAN（19 断言）** ✅
- [x] 回归六件套全绿（day2 32 / day3 16 / day4 21 / day5 16 / day6 14 / day7 13）✅
- [x] `python tools/gen_weapons_day7.py verify` → **DAY7 WEAPONS JSON VERIFY CLEAN**（33/33 levels + icon_index）✅
- [x] **护栏**：`git commit`（阶段 B 全量数据收口：33/33 武器 Lv1-8 + 33 帧实绘图标）✅
- ⚠️ 主观项「18 帧图标观感 / 全武器升级曲线体感」→ 由 #5 收进 `PLAYTEST_CHECKLIST.md`，不阻塞出口

**Day 8-9 收口交付物（预期）**：
- `data/weapons.json`（33/33 把 levels 8 条 + max_level 8，全量齐）
- `assets/sprites/ui/weapons.png`（40 帧：33 实绘 + 7 空余，零占位）
- `tools/gen_weapons_day7.py`（LEVELS +18 把，docstring 更新 Day 7–9）
- `tools/gen_weapon_icons.py`（+18 帧实绘）
- `tools/day8_weapon_data_check.gd`（新建 ≥13 断言）
- `docs/TASKS.md`（Day 8-9 标题 ✅ + T1~T3/EXIT 全部 [x]）

### Day 10 — 武器进化
- [ ] **D10-PRE【W2】星刃进化链补全**（由 Day 2 `D2-T5` 转入，08-05 06:35 #2 收敛为单一来源）：3 把签名武器中 `se_star_flame→se_flame_core→se_star_fall` ✅、`se_auto_turret→se_mech_core→se_turret_array` ✅ 两条链完整，**唯独 `se_star_blade` ❌ 缺 `evolution` 且无专属核心**。本日决策：新增 `se_blade_core` 补齐第三条链，or 明确接受莱恩无进化。**禁止挂 `elemental_core` 凑数**（语义错位，Day 2 已否决）
- [ ] 进化机制：Lv8 + 对应核心装备 = 进化武器
- [ ] 示例：炎星术Lv8 + 烈焰核心 → 炎星陨落（陨石 AOE）
- [ ] `baseline_check` 通过

### Day 11–12 — 20 被动
- [ ] 4 类被动：攻击/防御/属性/特殊（示例 红宝石 攻击+20%）
- [ ] 6 被动槽装配逻辑
- [ ] `baseline_check` 通过

### Day 13 — Build 系统集成 + 数值冒烟
- [ ] 10 属性公式校验（攻击/暴击/吸血/护甲…）
- [ ] 进化链路、被动叠加边界测试
- [ ] `baseline_check` 通过；产出阶段 B 报告

---

## 阶段 C · 肉鸽系统（Day 14–20）

### Day 14–15 — 随机节点地图
- [ ] 节点拓扑：战斗 / 事件 / 精英 / 商店 / Boss
- [ ] 种子可复现随机生成
- [ ] `baseline_check` 通过

### Day 16 — 事件节点　【数据侧已由 08-04 并发冲刺预交付】
- [x] 文本选择事件 ×10（描述 + 选择A 奖励 + 选择B 改线）—— w4 已落盘（f78e29e），实测 `events.json` = `{events:[10]}`
- [x] 事件数据填 `data/events.json` —— JSON 校验通过，`effect_on_route` 负值为设计内代价（`TEST_REPORT` §5）
- [ ] **W1 剩余**：事件节点**代码逻辑**（弹窗 UI / 选项分支 / 奖励结算 / 改线）—— `scripts/` 全域尚无事件节点消费方
- [ ] `baseline_check` 通过

### Day 17 — 精英战斗
- [ ] 精英敌人特殊能力 / 强化属性
- [ ] `baseline_check` 通过

### Day 18–19 — Boss 腐化巨树 两阶段
- [ ] 阶段1：召唤藤蔓限制移动
- [ ] 阶段2：全屏毒雨
- [ ] 奖励：解锁森林区域
- [ ] `baseline_check` 通过

### Day 20 — 遗物 + 阶段 C 回归
- [ ] 遗物：破碎王冠（攻击+50%/受伤+30%）、机械核心（机械伤害+100%）
- [ ] 阶段 C 平衡回归；产出阶段 C 报告

---

## 阶段 D · 美术·音频·剧情整合（Day 21–26）

### Day 21–22 — 美术资产落地　【部分已由 08-04 并发冲刺预交付】
- [x] 3 英雄 二次元像素 Sprite（立绘表现 + 战斗帧 strip）—— w3 已落盘（7d39e75）：`elin/noah/lain` × `portrait/idle/walk` 共 9 张 PNG
- [ ] 敌人 / Boss（腐化巨树）精灵 —— **未开工**，`assets/sprites/enemies/` 仍为框架遗留素材
- [x] 遵守 `ART_STYLE.md`：32px 网格 / 32 色 / Nearest / 1px 描边 —— 规范已成文 `docs/ART_ANIME_SPEC.md`（16137 B）
- [ ] anime 方向调和（高饱和幻想色 + 华丽特效预留）—— 规范已定，**素材侧待 Day 23 VFX 一并落地**
- [!] 承接 D2-T3：9 张英雄 PNG 中 6 张缺 `.import`（仅 `fighter_idle/walk` 有），本日统一验收

#### D21-T0【W3 · 概念图驱动的美术实装 · 2026-08-05 用户交接 · 2026-08-05 晚已部分提前实装】

> **参考图**：`docs/art_refs/concept_2026-08-05_chatgpt_star_echo.png`（已转码真 PNG，用户 2026-08-05 19:46 提供；用户另发 3 张分区截图：立绘/头像/局内模型）
> **优先级（按用户指令）**：①头像 → ②人物模型 → ③特效
> **关键发现**：参考图引入**第四角色「希亚」（医师 / 治疗 / 辅助，白蓝紫配色，初始武器「光耀法杖」，主动技能「神圣庇护」）**——项目当前 `characters.json` 仅 3 英雄（艾琳/诺亚/莱恩），数据层需先预建希亚条目，美工才能实装。
> ✅ **2026-08-05 晚提前实装**（用户明确要求不等 Day 21）：A 头像 + B idle 已实装 + D 数据预建完成，提交 `4707861`/`fd3ba69`；剩余 C 特效、B walk/attack/skill strip、遗留 6 英雄沿用 Day 21-22 排期。

**A. 头像（pixel portrait，实际 64×64 静态）**
- [x] 艾琳 / 诺亚 / 莱恩 —— 已替换 `{elin|noah|lain}_portrait.png`（2026-08-05 从用户头像截图抠图，64×64 / 32 色 / 1px 描边，边缘透明 ≤12%）
- [x] 希亚（新增）—— 已建 `assets/sprites/characters/siia_portrait.png`（⚠️ 命名按 `character_select` 的 sprite 前缀规则，非 `se_siia_`；D21-T0 原文笔误已纠正）
- [ ] 遗留 6 英雄（well_rounded/brawler/ranger/mage/engineer/gambler，D2-T7 美术债）—— 沿用参考图艺术方向补齐或明确接受占位

**B. 人物模型（pixel 32×32，4 状态 strip：待机/移动/攻击/技能）**
- [x] 艾琳 / 诺亚 / 莱恩 idle —— 已替换 `{elin|noah|lain}_idle.png`（4 帧横向 sheet 128×32，当前 4 帧同图；真多帧动画归 Day 21-22）
- [x] 希亚 idle（新增）—— 已建 `assets/sprites/characters/siia_idle.png`（同 4 帧格式）
- [ ] walk（`{elin|noah|lain|siia}_walk.png` 192×32）—— 三英雄沿用旧素材、**希亚无 walk → 进局走 fighter 兜底**，归 Day 21-22
- [x] `.import` —— 已用 `godot --headless --import` 补全（本地生效；gitignore 排除不入库）
- [ ] 攻击 / 技能帧 strip —— **当前不存在**（Player.gd 仅 idle/walk 接入），归 Day 21-22

**C. 特效与图标（Day 23 VFX 子集，本任务可提前实装静态图标）**
- [ ] 武器图标：炎星术 / 自动炮台 / 星刃 / 光耀法杖 —— 落点 `assets/sprites/weapons/{se_star_flame|se_auto_turret|se_star_blade|se_holy_staff}_icon.png`（IconAtlas.weapons 索引新增 1 项）
- [ ] 技能图标：炽星火球 / 机械矩阵 / 剑域绽放 / 神圣庇护 —— 落点 `assets/sprites/skills/{skill_id}_icon.png`（HUD 冷却指示 SkillSlot，D3-T6 顺延）
- [ ] 阵营图标：回响者联盟 / 星骸教会 / 深渊议会 / 机械帝国 / 自由佣兵团 —— 落点 `assets/sprites/factions/{id}.png`
- [ ] 场景概念图（梧蓝工区 / 腐化森林 / 熔岩矿城 / 虚空回廊）—— 落点 `assets/sprites/backgrounds/{id}.png`，供 Day 23+ 选关场景参考

**D. 数据预建（希亚新增 · W2 · 先于美术）**
- [x] `data/characters.json` 新增 `se_siia`：Healer / 治疗辅助 / 起始武器 `se_holy_staff` / sprite `"siia"` / 技能 `se_skill_holy_shield`（神圣庇护 shield30 heal10 cd14s）
- [x] `data/weapons.json` 新增 `se_holy_staff`（光耀法杖 · 8 级 · signature_of se_siia）
- [x] `data/items.json` / `data/events.json` 按需补希亚条目 —— 判定无必要，未新增（不臆造）
- [ ] `docs/ART_ANIME_SPEC.md` 与 `docs/LORE.md` 同步更新（希亚背景故事、职业说明）—— 待补

**E. 验收口径（提交后 #4 自动化测试）**
- 4 角色在角色选择界面 4 张 portrait 正常显示（希亚非占位）—— ✅ 已可验（`character_select.gd` `HERO_IDS` 已加 `se_siia`；`BASELINE CLEAN` + Day2 回归 32/32）
- 进局后 hero.gd `_setup_animation()` 接入新角色 idle/walk 无 warning，缺图走占位降级—— ✅ idle 已接入；希亚 walk 走 fighter 兜底（预期降级）
- IconAtlas.weapons 索引 ≥ 4，技能图标在 HUD SkillSlot 可读 —— 未做（C 未实装）
- `data/characters.json` 4 角色无 schema 缺失、9/9 hero_id 命中；希亚进局零 error（无 skill/id 时 try_cast 静默 false 不刷 warning）—— ✅ 10/10 hero 数据完整；希亚技能未实现走静默 false

### Day 23 — 华丽技能特效
- [ ] 火球 / 召唤 / 环绕 / 进化陨石 / 毒雨 VFX（粒子 + 闪白 + 霓虹点缀）

### Day 24 — 音频接入
- [ ] BGM / SFX / 空间音（占位或 `tools` 资源）

### Day 25 — 剧情文本　【已由 08-04 并发冲刺预交付】
- [x] 世界观（星骸/回响者联盟/苏醒悬念）—— w4 已落盘 `docs/LORE.md`（14075 B，f78e29e）
- [x] 10 事件文本、角色剧情解锁文案 —— 随 `data/events.json` 一并交付
- [ ] **剩余**：角色剧情**解锁条件**接线（依赖 Day 27 局外养成的角色培养系统）

### Day 26 — 整合校验
- [ ] 美术/音频/剧情与玩法整合
- [ ] 主观项标记给人工（→ `docs/PLAYTEST_CHECKLIST.md`）

---

## 阶段 E · 长期养成 + 测试·发布（Day 27–30）

### Day 27 — 局外养成
- [ ] 方舟基地 + 研究系统（永久 攻击+5% / 生命+10% / 幸运+5%）
- [ ] 角色培养（等级 / 技能升级 / 潜能突破 / 剧情解锁）
- [ ] `baseline_check` 通过

### Day 28 — 全量测试 + 性能
- [ ] 自动化测试 + 性能（帧率/内存/同屏敌人数）
- [ ] 回归 `baseline_check`；产出 `docs/TEST_REPORT.md`

### Day 29 — 人工试玩 + 修复
- [ ] **人工试玩**（手感/难度/乐趣/UI/视听/剧情）
- [ ] 收集反馈 → 修复关键缺陷 + polish

### Day 30 — 发布准备
- [ ] `python tools/build_release.py --zip`
- [ ] Steam 构建 / 导出 pck+exe / 存档兼容
- [ ] 资产库上传 `build`

---

## 🪲 已知 Bug 工单（BUG-xxx）

> 用户/试玩上报的缺陷在此登记，供 #3 择机修复与 #1 进度追踪。
> 修复后改标 `[x]` 并附提交哈希；未修复保持 `[!]`。

#### BUG-001【W1 · 高优 · 核心循环】第 2 关之后人物与怪物全部无法移动（疑似"玩家死亡但无 Game Over 反馈"）

- [!] **上报**：用户 2026-08-05 19:50 反馈（此前试玩遇到）——"第 2 关之后，人物和怪物都无法移动"。
- **现象**：画面静止、玩家不能动、敌人也不追，无任何报错或提示。
- **根因分析（19:52 已完成代码级排查，指向死亡链，非波次切换）**：
  1. 全项目 grep：`game_over` 信号**无任何消费方**（仅 `game_manager.gd:91` emit、`player.gd:267` 触发）→ 玩家死亡后**没有任何 UI 反馈**，游戏"静默结束"。
  2. 玩家死亡 `die()` → `is_alive=false` → `player.gd:194` `_physics_process` 直接 return → **玩家不动**。
  3. 敌人 `enemy.gd is_target_valid()`：`target.get("is_alive") == false` → 返回 false → `_update_behavior` 直接 return → **敌人不追**。
  4. 三者叠加 = "全员静止"且无法区分"卡死"与"已阵亡"。
  5. 触发时机吻合"第 2 关之后"：**波次切换（`on_wave_cleared`）不清理场上残余敌人**（enemy_spawner 只清 spawn_queue，不 free 已生成敌人）→ 商店期间残敌继续攻击 → 玩家在商店/第 2 关初阵亡。
- **建议修复（按依赖序）**：
  - [ ] `BUG-001-F1`【P0】Game Over UI：`game_over(victory)` 信号接一个结果面板（CanvasLayer，居中显示「你已阵亡 / 胜利」+ 重新开始按钮 → `get_tree().reload_current_scene()` 或回 CharacterSelect）。让"死亡"可感知，消除"静默卡死"。
  - [ ] `BUG-001-F2`【P0】波次切换清理残敌：`GameManager.on_wave_cleared()` 内遍历 `enemy_spawner.enemies_container` 统一 `queue_free()`（或标记为不攻击），防止商店期间被旧敌人打死。
  - [ ] `BUG-001-F3`【P2】可选项：敌人 `is_target_valid()` 对已死亡 target 的行为保持现状（死亡即停追）——F1 落地后该行为正确，无需改。
- **验收**：选任意英雄 → 故意被敌人打死 → 弹出「你已阵亡」面板且游戏停止、可重开；打完一波进商店 → 场上无残留敌人攻击。
- **归属**：W1（scripts/ + scenes/，新建 GameOver UI 场景）。建议在 **Day 6（阶段 A 集成测试）之前**修复，避免试玩误判"卡死"。
- **承接**：**Day 4 首段**执行 `BUG-001-F1` + `BUG-001-F2`（用户 2026-08-05 19:53 确认按计划留待下一轮，不即时修复）——**已固化为 `D4-T7` / `D4-T8` 并写入 Day 4 EXIT 断言 9/10（#2 第 5 轮 21:1x），#3 无需另找工单**。

---

## 需人工介入标记（自动化 #5 汇总到 `docs/PLAYTEST_CHECKLIST.md`）
- [ ] 手感「跟手」度
- [ ] 难度曲线体感（难/肝/无聊）
- [ ] 数值「好玩」度（Build 流派趣味）
- [ ] UI/UX 顺畅度与可读性
- [ ] 视觉/听觉主观感受（Anime 像素、华丽特效、音频氛围）
- [ ] 剧情文本调性
- [ ] 崩溃复现需真人路径
