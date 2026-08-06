# 《星骸回响》Star Echo · 每日可执行任务清单（TASKS）

> 供自动化 #2（任务拆解）更新、#3（方案确定与执行）读取实现。
> 状态标记：`[ ]` 未开始 · `[~]` 进行中 · `[x]` 完成 · `[!]` 受阻/需人工。
> 护栏：未定义当日任务前不写游戏代码；改前 git commit；改后跑 `tools/baseline_check.py`。

> ✅ **Day 5 已收口（2026-08-05 23:5x · #3）**：`day5_weapon_check.gd` **15 断言 0 失败** + baseline **BASELINE CLEAN** + 回归三件套全绿，提交 `5092874`（6 槽 / 查表升级 / 环绕武器 / 混合升级面板）。
> ✅ **Day 6 已收口（2026-08-06 01:5x · #3）**：阶段 A 集成测试完成 —— T-A 经验链路数据化（23 敌 exp_value + 透传 + 端到端探针 **14/14 CLEAN**）+ 回归四件套全绿（day2 32 / day3 16 / day4 21 / day5 15）+ 平衡校准（**实测曲线 Lv1→2=30**，chaser 2→3 / charger 3→4）+ 阶段 A 报告 `docs/REPORT_PHASE_A.md` + baseline **BASELINE CLEAN**，提交见本轮收口 commit。**P1 D6-T4 经验飘字亦已实装**（未顺延）。
> ✅ **Day 7 已收口（2026-08-06 03:3x · #3）**：阶段 B 首段完成 —— 11 把通用武器补 levels 8 条 + max_level=8（D7-T1）+ 33 把全部补 icon_index 分类映射（D7-T5）+ weapon.gd crit_chance/crit_damage 字段 + build_weapon_from_data 4 键消费 + _on_upgrade 3 行可选键消费（D7-T2）+ weapons.png 4 帧→40 帧 15 帧实绘+18 帧占位+7 帧空余（D7-T3）+ icon_atlas.gd 帧数 4→40（D7-T4）+ `day7_weapon_data_check` 探针 **13/13 CLEAN** + 回归五件套（day2 32 / day3 16 / day4 21 / day5 16 / day6 14）+ day5 探针同步更新（pistol 通用成长 → 合成裸武器 兜底测试）+ baseline **BASELINE CLEAN**，提交 `fc2a636`。
> ✅ **Day 8-9 已收口（2026-08-06 05:3x · #3）**：阶段 B 续段完成 —— 18 把全量武器补 `levels` 8 条 + `max_level=8`（D8-T1：`gen_weapons_day7.py` LEVELS +18 把 + verify 抽查扩展到 6 把 + force_field damage 恒 0 特例校验 + 顶层未动原则）+ 18 帧占位图标实绘替换（D8-T2：`gen_weapon_icons.py` +18 函数 + 新增 PURPLE/SHIELD 色 + 透明键 + 帧 33-39 空余保留）+ `day8_weapon_data_check.gd` 探针 **19/19 CLEAN**（JSON 全量 / 特例 / 装配 / 图标 / 回归 五段）+ 回归六件套全绿（day2 32 / day3 16 / day4 21 / day5 16 / day6 14 / day7 13）+ baseline **BASELINE CLEAN** + `gen_weapons_day7.py verify` → **33/33 levels + icon_index CLEAN**。30DAY_PLAN D7-D9「15 武器数据 + 精灵」至此**全量完成（33/33 把 Lv1-8 + 33 帧实绘图标）**。
> ✅ **Day 11–12 已收口（2026-08-06 12:4x · #3）**：阶段 B 被动+商店完成 —— 20 被动四字段（48 项筛 20 · 四类 5+5+5+5 · icon_index 0-19 唯一 · 3 核心命中）+ 6 被动槽（MAX_ITEMS 6 + HUD ItemSlot0-5）+ 装配链路（STAT_MAP 扩展 crit_damage_percent + apply_item_bonuses + main.gd 信号接线）+ 商店真实商品（33 武器排除 3 结果 + 20 被动 · 4 卡 · 先 add 后扣费）+ replace_weapon sync inventory（replace_weapon_slot 按 meta source_id）+ items.png 640×32 20 帧 + icon_atlas 20 → **回归九件套全绿（day2 32 / day3 16 / day4 21 / day5 16 / day6 14 / day7 13 / day8 19 / day10 20 / day11_12 22）+ baseline BASELINE CLEAN**，提交 `4bc79df`。探针 flaky 修复 2 处（day11_12 商店段白盒直构造 + day10 evolution 全量池 count 99）。拆解细节见 Day 11-12 区。
> ✅ **Day 13 已收口（2026-08-06 14:5x · #3）**：阶段 B 收口完成 —— ① **暴击结算点补全**（D13-T1：projectile crit_chance/crit_mult + 命中/AOE 同口径 `_roll_crit`；weapon_controller 聚合透传 clamp 0~0.9）② **武器两套体系统一**（D13-T2：`sync_inventory_weapons()` 全量重建 inventory 权威源 + 进局/装卸补调，HUD 显示起始武器）③ **炮台常驻/多台**（D13-T3：装备 se_turret_array → duration=-1 + 台数+2，turret permanent 模式）④ **BUG-002 修复**（D13-T6：`_build_shop_pool` 返回资源实例，真实商店 4 卡零 ERROR）⑤ **攻速消费点收口**（player.attack_speed → weapon_controller 冷却递减倍率，升级/被动/buff 生效）⑥ **数值冒烟探针** `day13_build_check.gd` **36/36 CLEAN**（真实商店/10 属性/暴击/进化池/叠加边界/两套统一/炮台）+ 回归十件套全绿 + baseline **BASELINE CLEAN** + `REPORT_PHASE_B.md` 产出。提交见本轮收口 commit。**R4 攻击力口径标 [!] 交 Owner 拍板**。
> 🎯 **Day 14-15 已拆解（2026-08-06 15:1x · #2 第 14 轮）**：阶段 C 首段 = **随机节点地图（层式分支拓扑 + 种子可复现 + 路线选择）**（见 Day 14-15 区）——W1 新建 `scripts/systems/route_generator.gd`（RNG 实例种子，禁全局 RNG 洗牌）+ GameManager 路线模式（`route` 空=旧波次制，回归零破坏）+ 新建 `scenes/RouteSelectPanel.tscn` 路线选择面板；W2 新建 `data/routes.json`（层数/每层节点数/类型权重/默认种子）；W5 新建 `tools/day14_15_route_check.gd` 探针 + 回归十件套（day6 探针注入 `route_enabled=false` 同步更新 1-2 行）。**事件/精英/Boss 节点本日仅「生成 + 波次映射」，交互逻辑归 Day 16/17/18-19**，W5 不得判失败。
> ✅ **Day 14-15 已收口（2026-08-06 17:5x · #3）**：阶段 C 首段完成 —— 随机节点地图（层式分支拓扑 + 种子可复现 + 路线选择）① **`route_generator.gd`**（RandomNumberGenerator 实例种子、`_weighted_pick` 区间采样禁全局 RNG、elite 低层禁抽、首层保 battle、battle_count≤19 硬校验、modifiers.reroute 事件改写预留）② **`data/routes.json`**（5 层 × 3 节点 · 默认种子 20260806 · weights 0.5/0.2/0.15/0.15）③ **GameManager 路线模式**（GameState+ROUTE_SELECT、route 空=旧波次制回归零破坏、`_start_next_wave(wave_number=-1)` 指定波次、on_wave_cleared 首行保留清残敌、close_shop 路线推进、start_game 默认路线模式）④ **`RouteSelectPanel.tscn`+`route_select_panel.gd`**（动态按钮=层节点数、类型色块、不暂停、game_over 自释放）⑤ **DataLoader 潜伏 bug 修复**：Godot 4.3 `JSON.parse` 全数字 float → `_waves` 键显式 `int(wave["wave"])`（此前 `get_wave(int)` 永远空、waves.json 运行时被旁路，波次全落默认生成）⑥ **探针 `day14_15_route_check.gd` 51/51 CLEAN**（种子/拓扑/数据/波次/兼容/端到端六段）+ 回归十一件套全绿（day2 32 / day3 16 / day4 21 / day5 16 / day6 14 / day7 13 / day8 19 / day10 20 / day11_12 22 / day13 36 / day14_15 51）+ baseline **BASELINE CLEAN** + verify 36/36。**事件/精英/Boss 交互归 Day 16/17/18-19**（占位推进 + push_warning）。
> ✅ **Day 14-15 EXIT 收口确认（2026-08-06 17:5x · #3）**：#2 第 15 轮实测的「实现 100% 落地」清单逐条复核一致 —— day14_15 探针 51/51、回归 11/11、baseline CLEAN、commit 已落（见下方收口行）。**T1~T5 + EXIT 全部 [x]，Day 14-15 标题 ✅ 收口**。下一目标日 = **Day 16 事件节点**（#2 已预拆解，见 Day 16 区）。
> 🎯 **Day 16 已预拆解（2026-08-06 17:1x · #2 第 15 轮）**：阶段 C 第二节 = **事件节点系统（弹窗 UI + 选项分支 + 奖励结算 + 改线）**（见 Day 16 区）——W1 新建 `EventSelectPanel.tscn` + `event_select_panel.gd`（仿 LevelUpPanel **暂停式**弹窗 + 长文本）+ GameManager 事件接入（`_enter_node(event)` 占位→真实流程 + `resolve_event_choice` + `_apply_event_reward` 10 型分派 + `_apply_route_effect` 5 型改线）+ `route_generator.gd` 扩展 `reroute_remaining`/`force_node_type` 改线静态方法；W2 补 `resonant_shard` 遗物数据（events.json `crystal_vein` 选 A 的 item 奖励实测**悬空**）+ 回归同步（day11_12 总项数断言 48→49）；W5 新建 `tools/day16_event_check.gd` 探针 + 回归十一件套（+day14_15）。**reroute/flag/difficulty 深消费（商店折扣/Boss 护盾/强度档）标注归 Day 17/20/25**，W5 不得判失败。
> 🎯 **Day 17 已预拆解（2026-08-06 19:1x · #2 第 16 轮）**：Day 14-15 已收口（`fa077e0`）→ 目标日推进 **Day 16（事件节点，已就绪）**，本轮预拆 **Day 17 = 精英战斗**（见 Day 17 区）——W1 精英特殊能力（enemy.gd AOE/自愈/产卵三行为真实实现）+ **BUG-003 mixed 池令牌解析收口**（spawner 支持 `mixed`/`elite:mixed`/`mixed_with_curse`，wave 15/17/19 此前精英+普通敌全部静默不生成）+ difficulty_delta 消费（Day 16 事件登记 → 本日 ±10%/档）+ 精英节点横幅提示 + 探针；W2 6 精英中 3 只补 `ability` 字段（butcher aoe / monk self_heal / mom spawn，数据驱动仿 burn_duration 先例）；W5 回归十一件套。**Boss phases 状态机归 Day 18-19**，W5 不得判失败。
> 🎯 **Day 11–12 已拆解（2026-08-06 09:1x · #2 第 11 轮）**：阶段 B 被动+商店 = **20 被动数据（四类）+ 6 被动槽 + 商店真实商品闭环 + 图标扩容**（见 Day 11-12 区）——W2 从现有 48 项筛 20 项为被动池（3 进化核心必选 + 四类划分 + effects 白名单化 + is_passive/slot/category/icon_index 四字段）；W1 6 被动槽（inventory MAX_ITEMS 20→6 + HUD ItemBar 4→6）+ 被动装配链路（player.apply_item_bonuses + GameManager 监听 inventory 信号）+ 商店真实商品购买（武器 33 池 + 被动 20 池随机 4 卡）+ replace_weapon 补 sync inventory；W3 items.png 4→20 帧实绘（gen_item_icons.py 新建）；W5 探针 + 回归八件套。**关键定案：被动只从商店获取（不进升级池）；裸 range 像素键统一 range_percent（200px 基准）；3 核心 effects 禁键仅占位登记不判失败；武器两套完整统一归 Day 13**。
> ✅ **Day 10 已收口（2026-08-06 07:3x · #3）**：阶段 B 进化机制完成 —— 3 把结果武器数据（se_star_fall 炎星陨落 / se_turret_array 机械炮阵 / se_blade_storm 星刃风暴，elemental/engineering/melee，tier 4，evolution_result + 平曲线 levels 8 条 + icon_index 33/34/35）+ items.json +se_blade_core 补齐星刃进化链（D10-PRE 定案）+ weapon.gd +explosion_radius/explosion_damage + weapon_controller.gd +replace_weapon（find→build→升满→原子替换→_sync 一次）+ level_up_panel.gd 进化池 + evolution 分支（先替换成功、后消耗核心）+ weapons.png 帧 33/34/35 实绘 + icon_index 0-32→0-35 + 探针 `day10_evolution_check.gd` 20/20 CLEAN + 回归七件套全绿（day2 32 / day3 16 / day4 21 / day5 16 / day6 14 / day7 13 / day8 19）+ baseline **BASELINE CLEAN** + `gen_weapons_day7 verify` 36/36 CLEAN，提交 `ca7c0a2`。
> 🎯 **Day 8–9 已拆解（2026-08-06 05:1x · #2 第 9 轮）**：阶段 B 续段 = **18 把全量武器 levels + 18 帧图标实绘 + 全量数据回归**（见 Day 8-9 区）——W2 给 18 把通用武器补 `levels` 8 条 + `max_level:8`（fist/stick/dagger/hammer/flaming_knuckles/slingshot/crossbow/rocket_launcher/minigun/lightning_shiv/venom_staff/storm_staff/frost_nova/plasma_cannon/wrench/laser_turret/mech_arm/force_field，扩展 `gen_weapons_day7.py` LEVELS 表幂等 apply）；W3 18 帧占位图标逐帧替换实绘（扩展 `gen_weapon_icons.py`，含 force_field 护盾 / minigun 多管等特征）；W1 新建 `day8_weapon_data_check.gd` 探针（≥13 断言含 force_field damage 恒 0 特例）；W5 回归六件套。**纯数据 + 图标 + 探针日，零装配代码改动**（D7-T2 已铺路）。
> 🎯 **Day 7 已预拆解（2026-08-06 03:1x · #2 第 8 轮）**：阶段 B 首段 = **MVP 15 武器数据 + 装配消费 + 图标集**（见 Day 7 区）——W2 给 11 把通用武器补 `levels` 8 条（sword/chainsaw/pistol/smg/shotgun/sniper/wand/icicle/flamethrower/turret/landmine）+ 33 把补 `icon_index`；W1 装配消费补齐（crit_chance/crit_damage/pierce/icon_index）+ IconAtlas 帧数 4→40；W3 `weapons.png` 4 帧→40 帧（15 实绘 + 25 占位）；W5 新建 `day7_weapon_data_check.gd` 探针 + 回归。剩余 18 把归 Day 8-9（下轮拆解）。
> ✅ **Day 1 收口**（`7597d0b`）　✅ **Day 2 收口**（`edd0e9a`，32 断言 0 失败）　✅ **Day 3 收口**（`0dc2ece`，16/16 CLEAN）　✅ **Day 4 收口**（`eb8e2f5`，21/21 CLEAN，BUG-001 F1/F2 一并闭环）　✅ **Day 5 收口**（`5092874`，15/15 CLEAN）　✅ **Day 7 收口**（`fc2a636`，13/13 CLEAN + 回归五件套全绿）　✅ **Day 8-9 收口**（`d1e72f1`，19/19 CLEAN + 33/33 武器 Lv1-8 + 33 帧实绘图标 + 回归六件套全绿）　✅ **Day 10 收口**（`ca7c0a2`，20/20 CLEAN + 36/36 武器 Lv1-8 + 3 把结果武器 + 3 条进化链 + 进化池 + 爆炸 AOE + 回归七件套全绿）　✅ **Day 11-12 收口**（`4bc79df`，22/22 CLEAN + 20 被动 + 6 槽 + 商店闭环 + 回归九件套全绿）
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

### Day 10 — 武器进化　✅【2026-08-06 07:3x · #3 收口】

> **承接**：Day 8-9 收口（`d1e72f1`）——33/33 把武器 Lv1-8 + max_level 8 全量就绪 → **进化机制的输入侧（Lv8）已齐**。本日落地「Lv8 + 对应核心装备 = 进化武器」（30DAY_PLAN D10），并收口 Day 2 `D2-T5` 的星刃进化链（单一来源已收敛至此）。
> **护栏**：改前 `git commit` 存档；改后 `python tools/baseline_check.py` 必须 `BASELINE CLEAN`。
> **文件域**：W1 写 `scripts/`（weapon.gd / weapon_controller.gd / inventory.gd / item.gd / level_up_panel.gd）+ `tools/`（探针 `day10_evolution_check.gd`）；W2 写 `data/weapons.json` + `data/items.json` + `tools/gen_weapons_day7.py`（扩展 LEVELS）；W3 写 `assets/sprites/ui/weapons.png` + `tools/gen_weapon_icons.py`（扩展）；W5 写 `docs/TEST_REPORT.md`。**无跨域冲突**。
> **角色矩阵**（DAY_ROLE_ASSIGNMENTS Day 10 行细化）：W1 ●进化机制代码（背包 id 装配 / 替换 / 进化池 / 探针）/ W2 ●结果武器 + 核心数据 / W3 ●结果武器图标 3 帧 / W5 ●baseline + 回归七件套；W4 —（无职责）。
> **本轮实测基线（#3 免重复排查，07:1x #2 第 10 轮新核）**：
> - **scripts/ 全域零 `evolution`/`evolve`/`se_star_fall`/`se_turret_array`/`requires_item` 引用**（grep 全空）→ 进化机制**全新实现**，无历史包袱
> - `weapons.json` 33 把：**仅 2 把有 `evolution`**（`se_star_flame`→`se_flame_core`→`se_star_fall` / `se_auto_turret`→`se_mech_core`→`se_turret_array`，5 键结构 = `{requires_item, requires_level: 8, result_id, result_name, description}`）；`se_star_blade` ❌ 无 evolution；**result_id（se_star_fall / se_turret_array）不在 33 把清单** → 装配层 `build_weapon_from_data` 只认 weapons.json，结果武器必须入表
> - `items.json` 47 项：`se_flame_core` / `se_mech_core` 带 `evolution` 字段 + `tags: [..., "evolution_core"]` + `star_echo: true`（legendary / price 120）；**无 `se_blade_core`**；`elemental_core` 为普通道具（无 evolution 字段）
> - 基础设施已就绪：`DataLoader.get_item(id)`（:234）/ `get_weapon(id)`（:211）/ `get_weapon_category(id)`（:215）✅；`GameManager.inventory` 已接线（main.gd:37 `$Inventory`）✅；`inventory.gd` = `items: Array[Resource]` + `add_item/remove_item(index)/get_stat_bonus`，**无 id 维度查询/移除**；`item.gd`（Resource）**无 `item_id` 字段**（无法回指 items.json id）→ 需补
> - `weapon_controller.gd`：`equip_weapon`（查重 + MAX_SLOTS 6）/ `unequip_weapon` / `build_weapon_from_data`（消费 damage/cooldown(倒数)/range/projectiles/crit/pierce/icon_index/levels/max_level/orbit_data）/ `equip_from_data`；**无 replace 方法**；`weapon.gd upgrade()`（:77-82）`level >= max_level` 返回 false、`_on_upgrade()`（:87-116）查 `levels[level-1]` **绝对覆盖** → 进化升满级可复用「循环 upgrade() ≤7 次」
> - `weapon.gd` **无 `explosion_radius`/`explosion_damage` 导出字段**；`projectile.gd initialize`（:144-160）**已消费** `explosion_radius`/`explosion_damage`（:155-158）→ se_star_fall 陨石 AOE 只差装配层 2 处透传（weapon.gd 字段 + build/_spawn_projectile 消费）
> - `level_up_panel.gd` `_roll_options`（:48-67）= 属性池 + 武器升级池（条件 `weapon.level < weapon.max_level` → **满级武器天然排除，进化选项与升级选项互斥 ✅**）；`_apply_option`（:83-100）有 `weapon_upgrade` 分支，**无 evolution 分支**
> - ⚠️ HUD 槽位显示读 `GameManager.inventory.weapons`（hud.gd:150-158），实际装备在 `weapon_controller.equipped_weapons`——**两套独立体系**（既有架构不一致，非本日引入）→ 统一归 Day 11-12 商店体系，本日不涉 HUD 刷新
> - `shop.gd _refresh_shop`（:62-75）为 TODO 骨架（4 个 null 占位卡，无实际商品）→ **核心获取途径归 Day 11-12 商店体系**；本日核心持有走 inventory 数据注入（测试 + 将来商店装配）
> - `turret.gd` 由 `skill_controller._cast_deploy_turret`（:146-164）直传 JSON dict（Day 7 已登记召唤类成长归 Day 13）→ `se_turret_array` 的「炮台常驻/多台」行为归 Day 13，本日只通数据 + 进化链路
> - `weapons.png` = 1280×32 40 帧：帧 0-32 实绘（33 把），**帧 33-39 全透明空余** → 结果武器 3 把用 33/34/35；`items.png` = 4 帧（核心图标归 Day 11-12 商店体系，本日进化选项纯文字无图标需求）

#### 本日总定案（先读，避免执行期临场决策）
| 议题 | 定案 | 依据 |
|------|------|------|
| 星刃进化链（D10-PRE） | **新增 `se_blade_core` 补齐第 3 条链**：`se_star_blade` → `se_blade_core` → `se_blade_storm`（星刃风暴，环绕刃群强化）。**禁止挂 `elemental_core` 凑数** | D2-T5 原始意图 = 3 签名链对齐；Day 2 已否决凑数（语义错位）；莱恩无进化则 3 角色体验断裂 |
| 结果武器落点 | 3 把结果武器**加入 weapons.json**（33→36 把），带 **`evolution_result: true`** 标记；icon_index 33/34/35（占用空余帧，0-32 不动） | result_id 现悬空，装配层只认 weapons.json；evolution_result 标记供 Day 13 武器池范围统一时排除（升级/商店池不得刷出进化武器） |
| 结果武器形态 | **平曲线**：顶层字段 = 进化强度，`levels` 8 条全 == 顶层（单调校验天然合法 / Lv1==顶层满足）；进化后**直接升满级**（循环 upgrade() 至 max_level，_on_upgrade 查表绝对覆盖） | upgrade() 链路实测可复用；进化即满级不再升级；升级池因 `level == max_level` 天然排除，无二次升级入口 |
| 进化触发点 | **LevelUpPanel 进化池**：已装备武器 `level >= max_level` 且 evolution 存在 + `inventory.has_item_id(requires_item)` → 追加「进化『result_name』」选项 | Brotato 范式（满级+材料→进化选项）；复用现有面板/暂停/结算链路，**零新 UI 场景** |
| 核心消耗时序 | **先替换成功、后消耗核心**：`replace_weapon` 内部 build + 升满，失败返回 null 不消耗；面板侧替换成功后 `remove_item_id(requires_item)` | 防「核心已消耗但替换失败」的不可逆损失 |
| se_star_fall 陨石 AOE | weapon.gd 补 `explosion_radius/explosion_damage` 导出字段 + build 消费 + `_spawn_projectile` 透传（projectile.initialize 已支持 :155-158）；explosion_damage 兜底 = base_damage | 仅 2 文件 3 处小改，陨石爆炸立即可见；对齐 D7-T2 crit 字段先例 |
| se_turret_array 行为边界 | 本日**只通数据 + 进化链路**（替换/满级/核心消耗）；「炮台常驻/多台」机制归 Day 13 召唤类统一（turret.gd 直传 JSON 现状）；装备后走 WeaponController 普通弹丸发射（与 se_auto_turret 现状一致，不崩） | Day 7 已登记召唤类成长归 Day 13；本日扩面会失控 |
| 核心获取途径 | 本日 = inventory 数据注入（`add_item_from_data`）；商店购买归 Day 11-12（shop.gd 为 TODO 骨架） | 现状实测；Day 10 聚焦进化机制本体 |
| HUD / 图标 | 本日不涉 HUD 槽位刷新（inventory 与 weapon_controller 两套统一归 Day 11-12）；核心物品不配 items.png 图标（进化选项纯文字） | hud.gd:150-158 实测；items.png 4 帧现状 |

#### D10-PRE【W2 · P0】星刃进化链补全（决策已定案，数据并入 D10-T1）
- [x] **决策（本轮拍板，禁止执行期推翻）**：新增 `se_blade_core`（星刃核心）+ 结果武器 `se_blade_storm`（星刃风暴）→ 3 条签名进化链对齐：`se_star_flame→se_flame_core→se_star_fall` ✅ / `se_auto_turret→se_mech_core→se_turret_array` ✅ / `se_star_blade→se_blade_core→se_blade_storm`（本日补齐）
- [x] 依据：D2-T5（08-05 06:35 转出，单一来源）意图 = 3 签名武器 evolution 对齐；Day 2 已明确否决挂 `elemental_core` 凑数；莱恩无进化则三角色进化体验断裂
- [x] 产出 = D10-T1 中 `items.json` +`se_blade_core` 与 `weapons.json` +`se_blade_storm` 两处（见下）
- 测试点：`se_star_blade` 有 `evolution` 字段；`se_blade_core` 在 items.json 且 tags 含 `evolution_core`；交叉引用一致 ✅

#### D10-T1【W2 · P0】结果武器 3 把 + 核心 1 个数据（`data/weapons.json` + `data/items.json` + `tools/gen_weapons_day7.py`）
- [x] `weapons.json` 新增 **3 把结果武器**（顶层字段范式同 D7/D8-9 + `star_echo: true` + **`evolution_result: true`** + `max_level: 8` + `icon_index` 33/34/35 + `levels` 8 条平曲线）：
  - `se_star_fall`「炎星陨落」（elemental / fire / tier 4）：顶层 `damage ~45 / cooldown 1.2 / range 320 / projectiles 3 / explosion_radius 90`（+`explosion_damage` 由装配兜底=base_damage）；special「召唤大型火焰陨石, 命中爆炸 AOE」
  - `se_turret_array`「机械炮阵」（engineering / tier 4）：顶层 `damage ~30 / cooldown 0.5 / range 320 / projectiles 3`；special「诺亚机械强化: 炮台常驻不消失并同时部署多台（机制归 Day 13）」；**不加 blade/orbit 字段**
  - `se_blade_storm`「星刃风暴」（melee / tier 4）：顶层 `damage ~45 / cooldown 0.9 / range 150 / blade_count 6 / orbit_radius 120 / orbit_speed 220`；special「环绕刃群强化: 6 刃环绕」→ **本日唯一行为立即可见的进化**（build 已消费 orbit_data ✅）
- [x] **平曲线规范**：`levels` 8 条全部 == 顶层四维（damage 单调不减 / cooldown 单调不增 / Lv1==顶层 天然满足）；`upgrade` 文案 Lv1-7「进化形态」、Lv8「进化形态（满级）」
- [x] 扩展 `tools/gen_weapons_day7.py` `LEVELS` 表 +3 把（id 直入表；apply 幂等自动补 levels + max_level；verify 自动覆盖 **36 把**）
- [x] `items.json` 新增 `se_blade_core`（范式对齐 se_flame_core/se_mech_core）：`legendary / price 120 / effects {melee_damage: 8, crit_damage_percent: 20} / tags ["melee", "evolution_core"] / star_echo: true / evolution {weapon_id: "se_star_blade", requires_level: 8, result_id: "se_blade_storm", result_name: "星刃风暴", description}`
- [x] ⚠️ **不改** 33 把既有武器任何字段（顶层/levels/icon_index）；evolution_result 标记仅限 3 把新武器
- 测试点：JSON 校验通过 ✅；3 把新武器 levels 8 条 + max_level 8 + Lv1==顶层 + 单调合法 ✅；se_blade_storm 含 blade_count 6 ✅；icon_index 33/34/35 与既有 0-32 无冲突 ✅；**3 核心（se_flame_core/se_mech_core/se_blade_core）的 evolution.requires_item/result_id 与对应武器 evolution 交叉引用一致 ✅**
- 产出：`data/weapons.json`（36 把）+ `data/items.json`（48 项）+ `tools/gen_weapons_day7.py`（LEVELS +3）

#### D10-T2【W1 · P0】Inventory id 维度装配（`scripts/items/item.gd` + `scripts/systems/inventory.gd`）
- [x] `item.gd` 补导出字段 `item_id: String = ""`（回指 items.json id；供 id 查询/匹配，对齐 Weapon `META_SOURCE_ID` 思想但用显式字段更简单）
- [x] `inventory.gd` 新增 3 方法：
  - `add_item_from_data(item_id: String) -> bool`：`DataLoader.get_item(item_id)` 空则 `push_warning` + false；构造 Item 资源（`item_id` / `item_name = name` / `price` / `rarity` / `icon_index` 兜底 0 / `stat_bonuses = effects`）→ `add_item(resource)`（>MAX_ITEMS 20 时 false）
  - `has_item_id(item_id: String) -> bool`：遍历 items 匹配 `item_id`
  - `remove_item_id(item_id: String) -> bool`：找到首个匹配 index → `remove_item(index)` + true；无则 false
- [x] ⚠️ **不引入** weapon_controller 侧改动（inventory 与 weapon_controller 两套体系统一归 Day 11-12）
- 测试点：`add_item_from_data("se_flame_core")` → has_item_id true → remove_item_id true → has_item_id false ✅；未知 id → false 且 push_warning ✅

#### D10-T3【W1 · P0】WeaponController 进化替换 + 爆炸透传（`scripts/weapons/weapon_controller.gd` + `scripts/weapons/weapon.gd`）
- [x] `weapon_controller.gd` 新增 `replace_weapon(target: Resource, replacement_id: String) -> Weapon`：
  1. `build_weapon_from_data(replacement_id)` → null 返回 null（不崩、不改原武器）
  2. 升满级：`while w.level < w.max_level: w.upgrade()`（≤7 次；_on_upgrade 查表绝对覆盖，平曲线结果 = 进化强度）
  3. 原子替换：`equipped_weapons[equipped_weapons.find(target)] = w`（target 不在列表 → 返回 null）；`_sync_orbit_weapon()` **一次**（避免 equip/unequip 两次 sync）
  4. 返回 w
- [x] `weapon.gd` 补导出字段 `explosion_radius: float = 0.0` / `explosion_damage: float = 0.0`（对齐 D7-T2 crit 字段先例）
- [x] `build_weapon_from_data` 补消费 `explosion_radius`（`data.get(..., 0.0)` 兜底）；`_spawn_projectile` 的 `proj.initialize` 补传 `explosion_radius` / `explosion_damage`（后者兜底 = base_damage，`explosion_radius <= 0` 时 projectile 既有逻辑天然不爆炸，零回归）
- [x] ⚠️ 不进本日：inventory/weapon_controller 统一（Day 11-12）；turret.gd 召唤机制（Day 13）
- 测试点：`build_weapon_from_data("se_star_fall")` → `explosion_radius == 90` ✅；满级 se_star_flame → `replace_weapon("se_star_fall")` → 槽位数不变 / 旧引用被替换 / 新武器 `level == max_level` / `source_id == "se_star_fall"` ✅；未知 replacement_id → null 且原武器不动 ✅

#### D10-T4【W1 · P0】升级面板进化池（`scripts/ui/level_up_panel.gd`）
- [x] `_roll_options` 追加**进化池**（武器升级池之后）：遍历已装备武器（`weapon_controller.equipped_weapons`），当 `weapon.level >= weapon.max_level` 且 `weapon.has_meta(WeaponController.META_SOURCE_ID)`：
  - `source_id` → `DataLoader.get_weapon(source_id)` → `evolution` 字典存在 → `requires_item` 非空
  - `GameManager.inventory.has_item_id(evolution.requires_item)` → 追加 `{type: "evolution", label: "进化『%s』" % evolution.result_name, weapon: weapon, evolution: evolution}`
- [x] `_apply_option` 加 **evolution 分支**（先替换后消耗）：
  ```gdscript
  if str(opt.get("type", "")) == "evolution":
      var evo: Dictionary = opt.get("evolution", {})
      var wc: Node = player.get_node_or_null("WeaponController") if player else null
      if wc and wc.has_method("replace_weapon"):
          var replaced = wc.replace_weapon(opt.get("weapon"), str(evo.get("result_id", "")))
          if replaced != null:
              GameManager.inventory.remove_item_id(str(evo.get("requires_item", "")))  # 替换成功才消耗核心
          else:
              push_warning("[LevelUpPanel] 进化替换失败，核心未消耗: %s" % evo.get("result_id", ""))
      return
  ```
- [x] ⚠️ 满级武器已天然不在武器升级池（`level < max_level` 条件）→ 进化/升级选项互斥 ✅；全局武器池过滤 `evolution_result` 归 Day 13
- 测试点（注入式，照搬 `day4_level_check.gd` 范式）：满级 se_star_flame（build + 循环 upgrade）+ `inventory.add_item_from_data("se_flame_core")` → `_roll_options(8)` 含 `type == "evolution"` 且 label 含「炎星陨落」✅；`_apply_option` 后 equipped_weapons 含 se_star_fall 且核心已消耗 ✅；**无核心时不含进化选项** ✅

#### D10-T5【W3 · P0】结果武器图标 3 帧（`assets/sprites/ui/weapons.png` + `tools/gen_weapon_icons.py`）
- [x] 扩展 `tools/gen_weapon_icons.py`：帧 **33/34/35** 实绘（复用 Icon 像素原语 + 分类色系 + 1px 深色描边 + 透明键左上角 (0,0)）：
  - 33 `se_star_fall`：火陨石球 + 焰尾 + 火星（红橙）
  - 34 `se_turret_array`：3 管炮阵列（橙黄）
  - 35 `se_blade_storm`：环绕 3 刃残影（银/青）
- [x] 帧 36-39 保持全透明空余；**不动 0-32 已收口帧**（帧序/尺寸锚点）
- [x] 生成后**先合成预览图（拆帧放大 4 倍）人工查整体效果再 commit**（对齐 D8-T2 打磨惯例）
- 测试点：PNG 1280×32 不变 ✅；(0,0) 透明键 ✅；33/34/35 中心 16×16 非全透明 ✅；36-39 全透明 ✅
- 产出：`assets/sprites/ui/weapons.png`（40 帧：36 实绘 + 4 空余）+ `tools/gen_weapon_icons.py`（+3 帧）

#### D10-T6【W1 · P0】进化探针（新建 `tools/day10_evolution_check.gd`）
- [x] 照搬 `day8_weapon_data_check.gd` 骨架（`extends SceneTree` + 分帧推进），覆盖 5 段：
  1. **数据层**：3 条进化链齐全（se_star_flame / se_auto_turret / se_star_blade 均有 evolution）；`requires_item` ∈ items.json 且 tags 含 `evolution_core`；`result_id` ∈ weapons.json 且带 `evolution_result`；3 把结果武器 levels 8 条 + max_level 8 + Lv1==顶层 + 单调合法
  2. **装配层**：`build_weapon_from_data("se_star_fall")` → explosion_radius 90；`build_weapon_from_data("se_blade_storm")` → orbit_data.blade_count 6；`build_weapon_from_data("se_turret_array")` → 正常装配
  3. **背包层**：`add_item_from_data("se_flame_core")` → has_item_id true → remove_item_id true → false；未知 id → false
  4. **进化链路层**：满级 se_star_flame（循环 upgrade 至 max_level）→ `replace_weapon("se_star_fall")` → 槽位数不变 / level == max_level / source_id == "se_star_fall"；inventory 注入核心 → `_roll_options` 含 evolution 选项 → `_apply_option` → 武器替换 + 核心消耗（再次 has_item_id false）
  5. **回归层**：sword Lv8 damage 50 / se_star_flame Lv8 projectiles 3 / se_star_blade Lv8 blade_count 4（历史锚点）；36 把 icon_index 与 D7-T5+D10-T1 完稿映射表一致（新增 3 把不破坏 0-32）
- [x] 断言数 ≥15，全部通过输出 `DAY10 EVOLUTION CHECK CLEAN`（exit 0）— 实际 20 项
- 测试点：`godot --headless` 跑该脚本 exit 0 ✅；失败输出断言行号 ✅
- 产出：`tools/day10_evolution_check.gd`（新建 20 项断言）

#### D10-EXIT【W5】当日出口
- [x] `python tools/baseline_check.py` → **BASELINE CLEAN**（import + runtime 双阶段，exit 0 / stderr 0）✅
- [x] `tools/day10_evolution_check.gd` 全部断言通过 → **DAY10 EVOLUTION CHECK CLEAN** ✅
- [x] 回归七件套全绿（day2 32 / day3 16 / day4 21 / day5 16 / day6 14 / day7 13 / day8 19）✅
- [x] `python tools/gen_weapons_day7.py verify` → **DAY7 WEAPONS JSON VERIFY CLEAN**（36/36 把 levels + icon_index）✅
- [x] **护栏**：`git commit`（阶段 B 进化机制收口）✅ `ca7c0a2`
- ⚠️ 主观项「进化爽感 / 陨石特效观感」→ 由 #5 收进 `PLAYTEST_CHECKLIST.md`，不阻塞出口；「se_turret_array 炮台常驻/多台行为」未生效 → **登记 Day 13**，W5 不得以「进化后炮台行为未见效」判失败

**Day 10 收口交付物（预期）**：
- `data/weapons.json`（36 把：33 既有 + 3 结果武器 evolution_result）+ `data/items.json`（48 项：+se_blade_core）
- `tools/gen_weapons_day7.py`（LEVELS +3）+ `tools/gen_weapon_icons.py`（+3 帧）+ `assets/sprites/ui/weapons.png`（40 帧：36 实绘 + 4 空余）
- `scripts/items/item.gd`（+item_id）+ `scripts/systems/inventory.gd`（+add_item_from_data/has_item_id/remove_item_id）
- `scripts/weapons/weapon.gd`（+explosion_radius/explosion_damage）+ `scripts/weapons/weapon_controller.gd`（+replace_weapon + 爆炸 2 处透传）
- `scripts/ui/level_up_panel.gd`（进化池 + evolution 分支）+ `tools/day10_evolution_check.gd`（新建 ≥15 断言）
- `docs/TASKS.md`（Day 10 标题 🎯 + T1~T6/EXIT 状态回执）

### Day 11–12 — 20 被动 + 6 被动槽 + 商店体系　✅【已收口 · 2026-08-06 12:4x #3 · `4bc79df`】

> 📌 **本轮实测基线（#3 勿重复排查，2026-08-06 09:1x 新核）**
> - **被动槽现状**：`inventory.gd` = `MAX_ITEMS: int = 20`（道具槽 20，非被动 6）；`items` 数组 = 道具+进化核心混存（48 项）；`add_item_from_data/has_item_id/remove_item_id`（D10-T2 已就位）；`get_all_stat_bonuses()`（:107-119）**无任何调用方** → 被动买了不会生效，装配链路为零
> - **HUD 槽位**：`hud.gd:30-35` `item_slots` 数组 **4 个**（ItemSlot0-3，HUD.tscn:233-310 同）；`_refresh_item_slots()`（:163-173）读 `inventory.items` + `IconAtlas.get_icon("items", icon_index)` → 槽位扩容需 **hud.gd + HUD.tscn 双改**
> - **图标**：`items.png` = 128×32 **4 帧**（4 个实绘图标：粉/黄/蓝系）；`icon_atlas.gd:14-18` items `frame_count: 4`；48 项 items.json **全部无 `icon_index` 字段**（add_item_from_data 默认 0 → 全显示第 0 帧）
> - **items.json 48 项**（47 框架遗留 + se_blade_core）：**全部无 `is_passive/slot/category/icon_index` 字段**（0/48）；effects 键大量为**框架旧口径**（melee_damage/ranged_damage/elemental_damage/engineering/knockback/harvesting/xp_gain_percent 等）——player.gd 消费不了，直接当被动会**静默失效**（零报错零生效），必须数据规范化
> - **可消费键白名单**（player.gd STAT_MAP :50-65 14 键 + apply_stat_modifier :328-362 14 键）：`max_hp/speed_percent/armor/regen/hp_regen/dodge_percent/crit_chance_percent/attack_speed_percent/melee_attack_speed_percent/damage_percent/range_percent/luck/pickup_range/life_steal_percent`；**`crit_damage_percent` 缺映射**（需扩展 STAT_MAP）；**裸 `range` 键是像素口径**（STAT_MAP_EXCLUDED :70，与 range_multiplier 倍率冲突）→ 被动数据禁裸 range，统一 `range_percent`
> - **商店链路已通一半**：`wave_manager.gd:64,88` 波清 → `GameManager.on_wave_cleared()`（:82-91）→ `shop_opened.emit()` → `shop.gd:_on_shop_opened`（:44）→ `_refresh_shop`（:62-75）**TODO 骨架**（4 个 null 占位卡）；`_purchase_item`（:144-155）**TODO**（只 emit 不买）；Main.tscn 已实例化 Shop（:39）；shop.gd 已接 economy/reroll(10G)/continue
> - **DataLoader 取数就绪**：`get_all_weapon_ids()`（:220）/ `get_all_item_ids()`（:238）→ 商店商品池无需扩 DataLoader 接口（被动过滤在 shop.gd 或新便捷函数内做）
> - **武器两套体系**（既有隐患，本日仅最小修）：HUD 槽位读 `inventory.weapons`（hud.gd:150-158），战斗实装读 `weapon_controller.equipped_weapons`；`replace_weapon`（weapon_controller.gd:165-179）**只改 equipped_weapons 不同步 inventory** → 进化后 HUD 显示旧武器；完整统一归 Day 13（Build 集成）
> - **economy**：`spend_coins/add_coins` 已就位（economy.gd）；金币来源 = 击杀掉落（enemy._drop_rewards）
> - **升级面板**：属性池（stats.json 10 属性档）+ 武器升级池 + 进化池已齐（level_up_panel.gd:50-92）→ 被动**不进升级选项池**（商店是唯一获取途径，Brotato 范式），零改动

> 🔑 **本日总定案（9 条，防 #3 临场发挥）**
> | # | 决策 | 依据 |
> |---|---|---|
> | 1 | **20 被动 = 从现有 48 项筛选 20 项**（含 3 进化核心必选），不新建条目不臆造；其余 28 项保留数据、不标记 passive、不进商店池 | item.gd 头注释「被动增益道具数据」+ 30DAY_PLAN D11-12「20 被动装备」；现有项即被动池 |
> | 2 | **被动效果键白名单化**：入选 20 项的 effects **只允许** STAT_MAP 可消费键（15+1：扩展 `crit_damage_percent`）；禁键清单 = 框架旧口径/未实现机制（melee_damage/ranged_damage/elemental_damage/engineering/knockback/harvesting/xp_gain_percent/dodge_heal_*/miss_chance/special_enemies/boss_elite/element_reaction/structure_*/shop_weapon_upgrade/attack_speed_per_different_weapon/reaction_heal/fire_damage/burn_duration/summon_count/裸 range）；**裸 range 像素键 → range_percent（200px 基准换算，附依据可微调）** | 探针可断言「买了必生效」，杜绝静默失效 |
| 3 | **3 进化核心例外**：effects 可含禁键（机制未实现仅占位登记），核心价值在 `evolution` 字段；se_blade_core 的 `crit_damage_percent:20` 本日生效（扩展映射后） | 核心 = 进化触发材料，商店可购（D10 定案「核心获取途径归商店」） |
| 4 | **6 被动槽**：`inventory.MAX_ITEMS` 20→**6**（items 数组即被动槽，对齐大纲 6 被动槽）；HUD ItemBar 4→**6** 槽（hud.gd 数组 + HUD.tscn 加 ItemSlot4/5 两节点） | 大纲「被动 6 槽」；现有 MAX_ITEMS=20 是框架遗留 |
| 5 | **装配链路**：`player.gd` 加 `apply_item_bonuses(item: Resource, remove: bool)`（复用 STAT_MAP 三档 add/percent/ratio；未映射键 `push_warning` 登记防静默丢弃）；**GameManager 监听 `inventory.item_added/item_removed` → 应用/回退**（remove 传负值走同一入口） | inventory 无 player 引用（Main.tscn 平级），GameManager 已持二者引用；反向回退 = 负值同入口最简 |
| 6 | **商店真实商品**：`_refresh_shop` 从**武器池（33 把，排除 3 把 evolution_result 结果武器）+ 被动池（20 项 is_passive）**随机 4 卡（SHOP_ITEM_COUNT=4）；`_create_card` 显示真数据（图标/名称/价格）；`_purchase_item` = **先 add 成功、后扣费**（槽满/钱不够拒绝） | D10 定案「结果武器 Day 13 武器池排除」；防扣费后入库失败 |
| 7 | **武器购买双写**：被动 → `inventory.add_item`；武器 → `inventory.add_weapon` + `weapon_controller.equip_weapon`（6 槽满拒 → 扣费回滚）；`replace_weapon` **补一行 sync inventory**（按 meta source_id 匹配替换 inventory.weapons 旧条目）→ 进化后 HUD 显示结果武器 | 两套体系本日仅最小修，完整统一归 Day 13 |
| 8 | **items.png 4→20 帧** + `icon_atlas.gd` items `frame_count` 4→20；20 帧实绘（含 3 核心特征图标）；新建 `tools/gen_item_icons.py`（仿 gen_weapon_icons.py 范式） | 48 项无 icon_index、4 帧不够 20 被动映射 |
| 9 | **主观隔离**：商店 UI 手感/被动搭配趣味/价格节奏 → #5 收 PLAYTEST_CHECKLIST，不阻塞出口 | 客观可验 = 数据合法 + 买了生效 + 槽位上限 + 购买闭环 |

#### D11-12-PRE【W2 主责】20 被动清单定案（数据设计，非代码任务）✅【11:1x 实测：20 项已定案落地】

- [x] **从 items.json 48 项中选 20 项**为被动池（四类建议清单，W2 可微调，**3 进化核心必选**）：
      - 攻击(5)：`coffee`(攻速+8%) / `injection`(伤害+7%,生命-2) / `medal`(5 键小幅) / `glass_cannon`(伤害+25%,护甲-3) / `bone_dice`(伤害+5%,幸运+5)
      - 防御(5)：`helmet`(护甲+2) / `alien_worm`(生命+3,回血+1) / `jelly`(生命+5) / `mushroom`(回血+3,生命-5) / `guardian_shield`(护甲+4,生命+10,移速-5%)
      - 属性(5)：`sneakers`(移速+5%) / `insanity`(暴击+5%,闪避-5%) / `potato`(9 键小幅) / `adrenaline_shot`(攻速+15%,移速+10%,生命-10) / `ball_and_chain`(伤害+15%,护甲+3,移速-3% → **去 knockback 5**)
      - 特殊(5)：`se_flame_core` / `se_mech_core` / `se_blade_core`（进化核心，必选）/ `blood_leech`(吸血+3%,回血+2) / `banner`(攻速+5% + **range 15 → range_percent 8**)
- [x] 入选 20 项各补 4 字段：`"is_passive": true` + `"slot": "passive"` + `"category"`（`"attack"/"defense"/"stat"/"special"`）+ `"icon_index"`（**0-19 全局唯一**，与 D11-12-T6 帧序一致）
- [x] 入选 17 常规项 effects **全部落入白名单**（按定案 2/3 规则；`crit_damage_percent` 键可保留——T3 将扩展映射使其生效）
- [x] 其余 28 项：**不动数据**（保留框架原样，仅不加 passive 标记，商店池自然排除）；3 核心的禁键（elemental_damage/fire_damage/burn_duration/engineering/summon_count 等）保留并在本条目附注释登记「机制未实现占位」
- **测试点**（11:1x 实测全过）：`python` 校验 20 项 `is_passive==true` ✅、`category` 四类各 ≥4 ✅（5+5+5+5）、`icon_index` 0-19 无重复 ✅、3 核心 id 命中 ✅（se_flame_core/se_mech_core/se_blade_core 均在池内）
- **回归风险**：`D10-T1` 的 `gen_weapons_day7.py verify` 只查 weapons.json，items.json 字段增补**零回归**；`day10_evolution_check` 断言核心 id/evolution 字段不受影响（新增字段不破坏既有断言）

#### D11-12-T1【W2 主责】items.json 20 被动数据落地 ✅【11:1x 实测：48 项中 20 项四字段齐 + 白名单已落地】
- [x] 按 D11-12-PRE 清单执行：20 项加 `is_passive/slot/category/icon_index`；17 常规项 effects 白名单化（改键不造数：`range:15` → `range_percent:8` 等换算附一行依据）；3 核心加字段
- [x] 扩展 `tools/gen_weapons_day7.py`？**不需要**（该工具只管 weapons.json）——如需要可加 `verify_items` 幂等段校验 20 被动（可选，不强制）
- **测试点**（11:1x 实测全过）：JSON 校验通过 ✅；20 项四字段齐 + 白名单 + 唯一 icon_index ✅（探针数据层段佐证）

#### D11-12-T2【W1 主责】6 被动槽（inventory + HUD） ✅【11:1x 实测：MAX_ITEMS=6 + HUD ItemSlot0-5】
- [x] `scripts/systems/inventory.gd`：`MAX_ITEMS: int = 20` → `6`（:21，注释改为「最大被动槽（大纲 6 被动槽）」）；`reset()` 同步清空
- [x] `scripts/ui/hud.gd`：`item_slots` 数组 4→**6**（:30-35，加 `$.../ItemBar/ItemSlot4/5` 两个 @onready）
- [x] `scenes/HUD.tscn`：ItemBar 追加 `ItemSlot4/ItemSlot5` 两个槽位节点（复制 ItemSlot3 结构：TextureRect + Icon 子节点，同尺寸同风格）
- **测试点**（11:1x 实测全过）：inventory 第 7 个 `add_item` 返回 false ✅（探针「槽位/第 7 个 add_item_from_data 返回 false」PASS）；HUD `_refresh_item_slots` 遍历 6 槽不越界 ✅（hud.gd ItemSlot0-5 六节点 @onready + HUD.tscn ItemSlot0-5 六节点；探针图标段 stderr 无越界警告）

#### D11-12-T3【W1 主责】被动装配链路（买了必生效） ✅【11:1x 实测：STAT_MAP 扩展 + apply_item_bonuses + main.gd 接线】
- [x] `scripts/player/player.gd`：
      - STAT_MAP（:50-65）扩展 `"crit_damage_percent": {"stat": "crit_damage", "mode": "percent"}` ✅（:65 已落地）
      - 新增 `func apply_item_bonuses(item: Resource, remove: bool = false) -> void`：遍历 `item.stat_bonuses`，`amount = -amount if remove`，按 STAT_MAP 三档应用（**复用 `_apply_stat_dict` 相同写法**，可直接把 `_apply_stat_dict` 改为接收 `source: Dictionary, sign: float = 1.0` 复用，避免复制粘贴）；未映射键 `push_warning("[Player] 被动效果键未实现，仅登记: %s" % key)` 后跳过（不静默）✅（:144 已落地）
- [x] `scripts/autoload/game_manager.gd`：`_ready` 或 Main 接线——监听 `inventory.item_added.connect(_on_passive_added)` / `item_removed.connect(_on_passive_removed)`；回调里 `player.apply_item_bonuses(item, is_removed)`；**只装配 `slot == "passive"` 或 stat_bonuses 非空的道具**（防核心移除时误装配）
- [x] 接线点放 `scripts/autoload/main.gd:_ready()`（:41 绑定 GameManager.inventory 之后）——注意 GameManager 是 autoload，信号连接放 Main 更稳（GameManager._ready 早于 Main 场景子节点就绪）✅（main.gd:48-54 连接 + :139-147 回调 `_on_item_added_bonus/_on_item_removed_bonus`）
- **测试点**（11:1x 实测全过）：`add_item_from_data("coffee")` 后 `player.attack_speed` 由 1.0 → 1.08 ✅；`remove_item_id("coffee")` 后回 1.0 ✅（percent 除法精确还原）；未知键道具 `push_warning` 且不崩 ✅（探针装配段 PASS ×3 + 未映射键注入 PASS）

#### D11-12-T4【W1 主责】商店真实商品 + 购买闭环 ✅【11:1x 实测：shop.gd 真实商品池 + 先 add 后扣费】
- [x] `scripts/ui/shop.gd`：
      - `_refresh_shop()`：替代 TODO 骨架——**商品池** = `DataLoader.get_all_weapon_ids()` 过滤掉 evolution_result 结果武器（查 `get_weapon(id).has("evolution_result")`）+ `DataLoader.get_all_item_ids()` 过滤 `is_passive==true`；洗牌随机取 `SHOP_ITEM_COUNT`(4) 个 → 每个 build 成 Resource（武器走 `WeaponController.build_weapon_from_data` 同款字段映射——**shop.gd 内需自建最小 build**（weapon_controller 是 Player 子节点，shop 无引用；建议把 `build_weapon_from_data` 提为 Weapon 静态工厂或 shop 内复制 15 行映射，二选一，防双源优先静态工厂）；被动走 `Item.new()` + `stat_bonuses=effects` + `item_id/icon_index/price`（对齐 `add_item_from_data` :66-80 写法））→ `_create_card(item, i)` 真数据渲染 ✅（shop.gd:69 `_refresh_shop` + :81-93 商品池「33 武器排除 evolution_result + 20 被动」+ :73 `mini(SHOP_ITEM_COUNT, pool.size())`）
      - `_purchase_item(index)`：**先 add 后扣费**——武器：`inventory.add_weapon(item)` 成功 → `player.get_node("WeaponController").equip_weapon(item)`（equip 失败则 `remove_weapon` 回滚）→ `economy.spend_coins(price)`；被动：`inventory.add_item(item)` 成功 → `spend_coins(price)`；任一失败 `push_warning` 提示（槽满/钱不够）不崩 ✅
      - `_create_card` 图标分支：`item.get("weapon_type")` 判武器表（现有 :113 逻辑保留）；被动图标 `IconAtlas.get_icon("items", icon_index)` ✅
- [x] `scripts/weapons/weapon_controller.gd`：`build_weapon_from_data` 若提为静态工厂，同步改造 `equip_from_data`/`replace_weapon` 调用点（保持行为不变）✅
- **测试点**（11:1x 实测全过）：探针商店段 PASS —— 混合池 53（33 武器排除 3 结果 + 20 被动）✅；shop_items 4 卡非 null ✅；槽满购买拒绝 + coins 不变 ✅；购买被动 inventory+1 + 属性变 + 扣费 ✅；购买武器 equipped_weapons+1 + 扣费 ✅（探针用 `rng.seed = 12345` 固定 + 白盒直构造 shop_items，规避 RNG flaky）

#### D11-12-T5【W1 主责】进化后 HUD 同步（replace_weapon 补 sync） ✅【11:1x 实测：replace_weapon_slot 已落地】
- [x] `scripts/weapons/weapon_controller.gd` `replace_weapon`（:165-179）：替换成功后补一行——在 `GameManager.inventory.weapons` 中按 `meta source_id` 匹配旧武器（`inventory.weapons[i].get_meta("source_id") == 旧武器 source_id`）原位替换为新武器；inventory 无匹配则跳过（直开 Main.tscn 调试路径不崩）✅（:201 `GameManager.inventory.call("replace_weapon_slot", i, new_weapon)` + :20 `META_SOURCE_ID`）
- **测试点**（11:1x 实测全过）：进化后 HUD `_refresh_weapon_slots` 读 inventory 显示结果武器图标（帧 33/34/35）✅；`day10_evolution_check` 回归不红 ✅（20/20 CLEAN，replace 新增行不影响既有断言）

#### D11-12-T6【W3 主责 / W1 协作】items.png 4→20 帧 + 图标映射 ✅【11:1x 实测：640×32 20 帧 + icon_atlas 20】
- [x] 新建 `tools/gen_item_icons.py`（仿 `tools/gen_weapon_icons.py` 范式：PIL 原语 + 216 色 + 透明键 + 放大 4 倍预览）：实绘 **20 帧**（帧 0-19，对应 icon_index 0-19，**帧序与 D11-12-PRE 的 icon_index 分配一致**；含 3 核心特征图标：烈焰红/机械蓝灰/星刃青紫；ART_STYLE v2 32px 图标基准）；生成 `assets/sprites/ui/items.png`（128×32 → **640×32**）✅（git ?? 未跟踪；items.png 实测 640×32）
- [x] `scripts/utils/icon_atlas.gd`：items `frame_count` 4→**20**（:16）✅
- [x] 先跑工具 + 放大 4 倍实测整体效果再 commit（沿 gen_weapon_icons 既有纪律）✅（已在途，未 commit）
- **测试点**（11:1x 实测全过）：`day11_12_passive_check` 断言 items.png 尺寸 640×32 ✅、20 帧非透明 + 透明键 (0,0) ✅、icon_atlas items frame_count==20 ✅（探针图标段 PASS ×3）

#### D11-12-T7【W1 主责】探针 `tools/day11_12_passive_check.gd`（新建） ✅【11:1x 实测：22/22 CLEAN】
- [x] ≥16 断言，分五段：
      - **数据层**：items.json 20 项 `is_passive==true`；`slot=="passive"`；`category` ∈ {attack/defense/stat/special} 且四类各 ≥4；`icon_index` 0-19 唯一；17 常规项 effects 键 ⊂ 白名单（15+1 键集）；3 核心 id 命中 `se_flame_core/se_mech_core/se_blade_core` ✅（探针数据层段 PASS 全绿）
      - **槽位层**：`inventory.MAX_ITEMS == 6`；第 7 个 add_item false；`is_item_slots_full()` 口径 ✅
      - **装配层**：`add_item_from_data("coffee")` → player.attack_speed 1.0→1.08；`remove_item_id` → 回 1.0；`add_item_from_data("se_blade_core")` → player.crit_damage 2.0→2.4（crit_damage_percent 映射生效）；未知键被动注入 → push_warning 且不崩 ✅
      - **商店层**：`_refresh_shop` 产出 4 卡非 null；购买被动 → economy 扣费 + inventory+1 + player 属性变；槽满购买 → 失败且 coins 不变；购买武器 → equipped_weapons+1 ✅（**已按 flaky 教训：`rng.seed = 12345` 固定 + 白盒直构造 shop_items**，规避 (33/53)^4≈15% 全武器卡）
      - **回归锚点**：day10_evolution_check 20/20（不红）✅（11:1x 单独实测 20/20 CLEAN）
- **测试点**（11:1x 实测全过）：`godot --headless` 跑探针 → **22 项断言 0 失败 `DAY11_12 PASSIVE CHECK CLEAN`** + stderr 无越界警告 ✅（3 个 WARNING 为预期 push_warning 登记：melee_damage/engineering/fire_damage_percent 未映射键，符合定案 3「核心禁键仅占位登记」；末尾资源泄漏为无头探针尾噪音，exit 0）

#### D11-12-EXIT【W5】当日出口 ✅【2026-08-06 12:4x #3 收口：全项闭合】
- [x] `python tools/baseline_check.py` → `BASELINE CLEAN` ✅（11:1x 实测：import + runtime 双阶段 PASS）
- [x] `tools/day11_12_passive_check.gd` → 全 CLEAN ✅（11:1x 实测：22 项断言 0 失败）
- [x] 回归九件套：day2 32 / day3 16 / day4 21 / day5 16 / day6 14 / day7 13 / day8 19 / day10 20 / day11_12 22 —— **12:4x #3 全量复跑全绿**（items.json 增字段 + MAX_ITEMS 6 + replace_weapon 新增行零回归确认）
- [x] **护栏：`git commit`（阶段 B 被动+商店收口）** —— 提交 `4bc79df`（16 文件 +1564/−60）。**探针 flaky 修复 2 处**：① `day11_12_passive_check.gd` 商店段 `rng.seed` 对 `Array.shuffle()`（全局 RNG）无效 → 白盒直构造 shop_items（武器 2 + 被动 2）；② `day10_evolution_check.gd` 进化段 `_roll_options(8)` 池≈11 抽 8 有 ≈27% 概率抽不中 evolution → 改 count 99 全量池（持核心必现/无核心必不现）。未夹带无关文件（30DAY_PLAN/ART_*/PLAYTEST/PROGRESS/TEST_REPORT/DAY_ROLE_ASSIGNMENTS/LOOP_HEALTH/pindou/pixel_to_pindou/level_up_panel.gd.bak 均未 stage）。
- ⚠️ 主观项「商店 UI 手感 / 被动搭配趣味 / 价格节奏」→ #5 收 `PLAYTEST_CHECKLIST.md`，不阻塞出口；「被动图标观感 / 商店卡片布局」→ #5 + Day 21-22 美术债；「se_turret_array 炮台常驻机制」仍归 Day 13（W5 不得判失败）

**Day 11-12 收口交付物（预期）**：
- `data/items.json`（20 被动：4 字段 + 白名单 effects + 3 核心）+ `assets/sprites/ui/items.png`（640×32 20 帧）+ `tools/gen_item_icons.py`（新建）
- `scripts/systems/inventory.gd`（MAX_ITEMS 6）+ `scripts/player/player.gd`（apply_item_bonuses + STAT_MAP 扩展）+ `scripts/autoload/game_manager.gd` 或 `main.gd`（被动装配接线）
- `scripts/ui/shop.gd`（真实商品 + 购买闭环）+ `scripts/weapons/weapon_controller.gd`（build 静态工厂化[可选] + replace sync inventory）+ `scripts/utils/icon_atlas.gd`（items 4→20）
- `scenes/HUD.tscn` + `scripts/ui/hud.gd`（ItemBar 4→6 槽）+ `tools/day11_12_passive_check.gd`（新建 ≥16 断言）
- `docs/TASKS.md`（Day 11-12 标题 🎯 + T1~T7/EXIT 状态回执）

### Day 13 — Build 系统集成 + 数值冒烟　✅【阶段 B 收口 · 已收口】

> ✅ **Day 13 已收口（2026-08-06 14:5x · #3）**：全部客观任务完成 —— 暴击结算（T1）/ 两套统一（T2）/ 炮台常驻多台（T3）/ 数值口径定案（T4）/ 数值冒烟探针 36 断言（T5）/ BUG-002 修复（T6）全 [x]；`REPORT_PHASE_B.md` 产出；回归十件套全绿 + baseline CLEAN。**额外收口：攻速消费点**（#2 对照表假设存在但实测零消费 → weapon_controller 冷却递减 × attack_speed，3 行最小修复，base 1.0 零回归）。**R4 攻击力口径标 [!] 交 Owner 拍板**（见 D13-T4）。

> ✅ **Day 13 已拆解（2026-08-06 13:1x · #2 第 13 轮）**：Day 11-12 已收口（`4bc79df` + 回执 `d631e7b`）→ 目标日推进 **Day 13 = Build 集成 + 数值冒烟（阶段 B 收口）**。W1 补 3 个实测集成缺口（暴击结算 / 两套体系进局同步 / 炮台常驻多台）+ 数值冒烟探针；W2 10 属性公式对照 + 口径定案；W5 回归十件套 + `REPORT_PHASE_B.md`。

> 📌 **Day 13 实测基线（#2 第 13 轮新核，供 #3 免排查）**
> - **暴击零结算点（本轮新发现）**：weapon.gd:34-35 字段 + weapon_controller.gd:124-125 build 消费 + player.gd:26-27 属性 + STAT_MAP 装配（:57/:65）+ stats.json formulas `crit_check` 全就绪，但 projectile.gd 伤害结算（:64-72 命中 / :79-94 爆炸）**零 crit 引用** → 暴击通道装配了但不出伤，Day 13 必补
> - **护甲口径冲突（本轮新发现）**：player.gd:287 `take_damage` 平直减伤 `max(amount - armor, 1.0)`；stats.json formulas `armor_reduction = min(armor/(armor+20), 0.75)` 百分比减伤 → 两处不一致，Day 13 定案（建议沿用 player 平直式为权威，formulas 标参考，防平衡崩塌）
> - **进局武器不同步（本轮新发现）**：main.gd `_equip_starting_weapon`（:110-117）只写 `equipped_weapons` 不写 `inventory.weapons` → HUD 读 inventory（hud.gd:150-158）**不显示起始武器**；equip_weapon/unequip_weapon 亦不 sync（商店双写已通、replace 已 sync，仅进局/装卸缺口）
> - **se_turret_array 炮台常驻/多台（D10 遗留）**：turret.gd setup 直传 JSON（duration 计时 :47-52 到期 queue_free）；skill_controller._cast_deploy_turret（:146-169）部署 `summon_count + bonus_stats.summon_count` 台（诺亚 2+1=3）、duration 15s 后消失 → 无常驻/多台机制
> - **商店池实测 = 53**（33 武器 = 36 − 3 evolution_result + 20 被动；shop.gd:84-95）——**修正第 12 轮预调研「30 可购」笔误**；升级池只遍历「已装备且 level<max_level」（level_up_panel.gd:58-71）→ 满级/进化结果天然排除，无 evolution_result 泄漏
> - **被动叠加 = 同键乘法叠加**（apply_item_bonuses 逐项触发 percent 乘算，remove 除法还原，D11-12-T3 已验 coffee 1.0→1.08→回 1.0；多被动 1.08×1.08 边界归本日断言）
> - **探针资产**：`gen_weapons_day7.py verify`（36/36）+ `day10_evolution_check.gd`（20/20）+ `day11_12_passive_check.gd`（22/22）作冒烟底座；预期新建 `day13_build_check.gd`

#### D13-PRE【W1+W2】Build 集成定案表
| # | 决策 | 依据 |
|---|---|---|
| 1 | **暴击结算点 = projectile 弹丸**：`crit_chance = clampf(player.crit_chance + weapon.crit_chance, 0, 0.9)`；`crit_mult = player.crit_damage`（weapon.crit_damage 字段保留登记、结算以玩家通道为权威） | stats.json formulas.crit_check；玩家属性 = 大纲 10 属性权威通道 |
| 2 | **武器两套体系权威源 = inventory.weapons**（HUD 读数源），equipped_weapons = 战斗执行副本；进局/装卸/替换全部经 weapon_controller 统一 `sync_inventory_weapons()` | main.gd:110-117 进局缺口实测 |
| 3 | **se_turret_array 常驻/多台**：玩家装备该武器后，诺亚技能部署炮台 `duration=-1` 常驻 + 部署台数 +2 | D10 定案「炮台常驻/多台归 Day 13」 |
| 4 | **护甲减伤沿用 player 平直式** `max(amount - armor, 1.0)`（权威）；stats.json formulas armor_reduction 标「参考公式」不改代码 | 平衡已基于平直式校准（D6） |
| 5 | **商店池 = 33 武器 + 20 被动 = 53**（实测修正预调研「30 可购」笔误）；升级池无泄漏确认 | shop.gd:84-95 + 全量数据实测 |
| 6 | **被动叠加边界** = 同键乘法叠加 + remove 除法还原（多被动 1.08×1.08 = 1.1664 断言） | D11-12-T3 单被动已验证，本日多被动收口 |
| 7 | **10 属性公式对照**：大纲 10 属性 ↔ formulas(15) ↔ STAT_MAP(15 键) ↔ 消费点全表核验（W2 产出对照表） | stats.json formulas + player.gd:50-66 |
| 8 | **BUG-002（P1，#4 12:45 实测）**：shop.gd `shop_items: Array[Resource]`(:35) vs `_build_shop_pool()` 返回 **String id 列表** 直接 append(:75) → 真实游戏每波进商店 **4 ERROR + 0 卡**；探针白盒直构造遮蔽 → 修复 = `_build_shop_pool` 返回**资源实例**（武器走 `build_weapon_from_data`、被动走 `Item.new()` 填四字段，参照探针 :380-397 范式）+ 探针补真实进商店断言 | docs/TEST_REPORT.md §7 |

#### D13-T1【W1】暴击结算点补全（`scripts/weapons/projectile.gd` + `scripts/weapons/weapon_controller.gd`）
- [x] projectile.gd 增 `crit_chance: float = 0.0` / `crit_mult: float = 1.0` 字段 + `initialize()` 消费两键（默认 0/1.0 = 既有武器零回归）
- [x] 伤害结算处（`_on_body_entered` 命中 :67 与 `_explode` AOE :91）：`if randf() < crit_chance: damage × crit_mult`；暴击伤害同样走 `_apply_life_steal`
- [x] weapon_controller.`_spawn_projectile`：聚合暴击透传 —— `proj.crit_chance = clampf(player.crit_chance + weapon.crit_chance, 0, 0.9)`；`proj.crit_mult = maxf(player.crit_damage, 1.0)`（player 无属性走默认 0.05/2.0 或 0/1.0 兜底不崩）
- [x] **测试点**：crit=0 弹丸伤害 == 原值（零回归）；白盒构造 crit_chance=1.0 → 伤害 == base × crit_mult；爆炸 AOE 同口径
- [x] 文件域：W1 只写 `scripts/`（player/weapon 只读）

#### D13-T2【W1】武器两套体系统一入口（`scripts/weapons/weapon_controller.gd` + `scripts/autoload/main.gd`）
- [x] weapon_controller 增 `sync_inventory_weapons()`：按 equipped_weapons 的 meta source_id 顺序全量重建 inventory.weapons（无 source_id 条目跳过；GameManager.inventory 为 null 静默返回，直开 Main.tscn 不崩）
- [x] main.gd `_equip_starting_weapon`（:110-117）equip_from_data 成功后调 sync → **HUD 显示起始武器**
- [x] `equip_weapon`（:80）/ `unequip_weapon`（:88）尾部补调 sync（保持单点，replace 已有独立 sync 不重复）
- [x] **测试点**：直开 Main.tscn 调试路径不崩；进局后 inventory.weapons[0].source_id == starting_weapon；商店买武器 → inventory 与 equipped 双写幂等（重复 sync 无副作用）
- [x] 文件域：W1 只写 `scripts/`

#### D13-T3【W1】se_turret_array 炮台常驻/多台（`scripts/weapons/turret.gd` + `scripts/player/skill_controller.gd`）
- [x] turret.gd `setup`：`duration <= 0` → 常驻模式（`_process` :47-52 跳过 duration_left 递减与 queue_free 分支，其余行为不变）
- [x] skill_controller.`_cast_deploy_turret`（:146-169）：检测玩家 equipped_weapons 任一 meta source_id == `se_turret_array` → `duration = -1`（常驻）+ 部署台数 `+2`
- [x] **测试点**：未装备 → 原 3 台 15s 后消失（回归）；装备 se_turret_array → 部署 3+2=5 台且推进 N 帧后仍存活
- [x] 文件域：W1 只写 `scripts/`

#### D13-T4【W2】数值口径定案与核验（data/*.json **只读**，产出写 `docs/`）
- [x] **10 属性公式对照表**（产出附表入 REPORT_PHASE_B §5）：大纲 10 属性 ↔ formulas(15) ↔ STAT_MAP(15 键) ↔ 消费点 —— damage→_spawn_projectile / attack_speed→weapon fire_rate / range→range_percent(200px 基准) / speed→move_speed / crit_chance+crit_damage→D13-T1 / max_hp→health / armor→take_damage 平直 / life_steal→projectile.apply_life_steal(:104) / luck→add；harvesting/luck_shop/luck_chest/curse_* 为框架扩展公式仅登记不消费
- [x] 护甲口径定案记录（沿用平直式，formulas 标参考）——回写 D13-PRE 决策表 + 报告 §5
- [x] 3 进化链交叉引用核验：`requires_item` ↔ items.json 3 核心（se_flame_core/se_mech_core/se_blade_core）/ `result_id` ↔ weapons.json 3 结果武器（se_star_fall/se_turret_array/se_blade_storm 均 evolution_result 标记）
- [x] 商店池 53 口径脚本复算 + 升级池无泄漏复算（36 把仅 3 evolution_result；满级武器不在升级池）
- [!] **攻击力口径（R4）现状登记**：player 统一 `damage_percent→damage` 通道实际运作（`damage_multiplier` 消费于 _spawn_projectile:258）；characters.json penalty 三系键（melee/ranged/elemental_damage，如 mage 近战/远程 -100%）收集进 `bonus_stats` 未消费 → **标 [!] 交 Owner 拍板**（统一 vs 三系保留+UI 聚合），不阻塞本日客观进度
- [x] 文件域：W2 只写 `docs/`（对照表/核验记录），data/*.json 只读不写

#### D13-T5【W1】新建 `tools/day13_build_check.gd`（数值冒烟探针）
- [x] ≥20 断言六段：§1 **真实商店路径**（调 `_build_shop_pool` 断言返回 53 个**资源实例**（33 Weapon + 20 Item）+ `_refresh_shop` 后 shop_items.size()==4 且零类型 ERROR；白盒直构造仅作购买链路用例）/ §2 10 属性全覆盖（STAT_MAP 15 键含大纲 10 属性 + 消费点存在性）/ §3 暴击结算（crit=1 恒暴击伤害==base×mult、crit=0 零回归）/ §4 进化 3 链交叉引用 + 商店池无 evolution_result / §5 被动叠加边界（白盒双 +8% → ×1.1664，remove 一 → ×1.08，再 remove → ×1.0）/ §6 两套统一（进局 sync 后 inventory 读数一致）+ 回归锚点（day10/day11_12 关键断言复用）
- [x] 探针范式沿用：seed 固定 + 白盒直构造（禁依赖 rng.seed 控 Array.shuffle）——见 Day 11-12 收口 flaky 修复记录
- [x] 文件域：W1 只写 `tools/`

#### D13-T6【W1】BUG-002 修复：商店真实商品 0 卡（`scripts/ui/shop.gd`；P1 首段必做）
- [x] `_build_shop_pool()` 改返回**资源实例数组**：武器 → `build_weapon_from_data(wid)`（weapon_controller 纯函数式实例方法，shop 内 `preload(...).new()` 调用；或按 D11-12 备注提静态工厂）+ 被动 → `Item.new()` 填 `item_id/item_name/price/rarity/icon_index/slot/category/stat_bonuses` 四字段+effects（仿 inventory.gd:82-92 `add_item_from_data` 范式）；筛除 `evolution_result` 口径不变（53 池）
- [x] `_refresh_shop()` 洗牌抽取逻辑不变（现 append Resource 与 `shop_items: Array[Resource]` 类型吻合）→ 真实进商店 4 卡渲染 + 购买链路（_purchase_item 的 `item.get()` 对 Resource 同样生效）
- [x] **测试点**：模拟 `GameManager.shop_opened` → `_refresh_shop()` → shop_items.size()==4 且无类型 ERROR；购买 1 卡 → inventory 同步 + 扣费（回归 D11-12 白盒用例）
- [x] 文件域：W1 只写 `scripts/`

#### D13-EXIT【W5】阶段 B 收口
- [x] `python tools/baseline_check.py` → `BASELINE CLEAN`
- [x] `day13_build_check` CLEAN（含**真实进商店 4 卡无 ERROR**断言）+ **回归十件套**（day2 32 / day3 16 / day4 21 / day5 16 / day6 14 / day7 13 / day8 19 / day10 20 / day11_12 22 / day13 新增）+ `gen_weapons_day7.py verify` 36/36
- [x] 产出 `docs/REPORT_PHASE_B.md`（仿 REPORT_PHASE_A 结构：§1 阶段 B 回顾 Day 7-13 / §2 武器数据 36 把 Lv1-8 + 3 结果武器 + DPS 参照 minigun≈345 > flamethrower≈250 > hammer≈155 ≈ rocket_launcher≈130 / §3 进化 3 链 / §4 被动 20 + 6 槽 + 商店池 53 / §5 数值冒烟结论（暴击/护甲/叠加边界定案）/ §6 遗留风险与主观项 → PLAYTEST）
- [x] git commit 收口（**勿夹带** docs/pindou/、scripts/ui/level_up_panel.gd.bak、tools/pixel_to_pindou.py —— W3 自主提交）

---

## 阶段 C · 肉鸽系统（Day 14–20）

### Day 14–15 — 随机节点地图　✅【客观任务 100% 完成 · 已收口 · 2026-08-06 17:5x · #3】

> ✅ **Day 14-15 已拆解（2026-08-06 15:1x · #2 第 14 轮）**：Day 13 已收口（`a082457`）→ 目标日推进 **Day 14-15 = 随机节点地图（阶段 C 首段）**。核心交付 = **层式分支拓扑 + 种子可复现 + 玩家路线选择**（明日方舟集成战略式：每层 3 节点选 1 前进，末层 Boss）——W1 新建 `route_generator.gd`（RNG 实例种子，**禁全局 RNG 洗牌**）+ GameManager 路线模式（`route` 空 = 旧波次制，回归零破坏）+ 新建 RouteSelectPanel 选择面板；W2 新建 `data/routes.json` 拓扑参数；W5 探针 `day14_15_route_check.gd` + 回归十件套。**事件/精英/Boss 节点本日仅「生成 + 波次映射」，交互逻辑归 Day 16/17/18-19**，W5 不得判失败。

> 📌 **Day 14-15 实测基线（#2 第 14 轮新核，供 #3 免排查）**
> - **scripts/ 全域零 route/map/node/seed 引用**（grep route|node_map|RandomNumberGenerator|seed 全空）→ 随机节点地图全新实现；Main.tscn 无 Map/Route 节点
> - **波次引擎现状**：GameManager BATTLE→SHOP→BATTLE 循环（`start_game`→`_start_next_wave`→`on_wave_cleared` 每波必进商店→`close_shop`→下一波）；`_start_next_wave`（game_manager.gd:64-79）**`current_wave += 1` 累加**；is_boss_wave 靠检测 composition 中 `boss:` 前缀（wave 10/20）
> - **waves.json 20 波**：wave 6-19 天然含 `elite:` 前缀敌人（elite:butcher/monk/rhino/croc/colossus）；wave 10=boss:invoker、wave 20=boss:predator（final_boss_wave）→ **战斗/精英节点按「战斗序号」映射 wave n 即天然含精英，零数据改动**
> - **events.json 10 事件 effect_on_route 5 种类型**（reroute 改类型比例 / unlock_node 跳层 / add_node 加节点 / difficulty 层难度 / flag 全局标记）→ **路线拓扑必须为事件改写预留接口**（modifiers/flags 通道），消费归 Day 16
> - **UI 范式**：LevelUpPanel/ShopPanel = CanvasLayer + NinePatchRect + Button（level_up_panel.gd / shop.gd 参照）；升级面板 process_mode=WHEN_PAUSED；**商店期不暂停**（spawner 非 BATTLE 状态自动停）→ 路线选择面板同款（不暂停）
> - **回归锚点依赖**：day4_level_check 断言 10 直接 `call("on_wave_cleared")` 断言**清残敌**（`_clear_remaining_enemies()` 必须保留在 on_wave_cleared 首行）；day6_integration_check 端到端直接进局打怪 → **路线模式下注入 `route_enabled=false` 走波次模式**（1-2 行同步更新，其余断言不动）
> - **探针坑（沿用）**：`Array.shuffle()/pick_random()` 走**全局 RNG**，种子不可控 → RouteGenerator 一律用 `RandomNumberGenerator` 实例的 `randf()/randi_range()`，自实现 `_weighted_pick`；探针固定 seed 断言
> - **数据接口**：DataLoader `get_wave(n)`(:263)/`get_max_waves()`(:267)/`get_enemy_ids_by_category`(:202) 已备，零扩接口（routes 读取接口在 T3 补 3 行）

#### D14-15-PRE【W1+W2】随机节点地图定案表
| # | 决策 | 依据 |
|---|---|---|
| 1 | **节点类型 5 类**：`battle` / `event` / `elite` / `shop` / `boss`（类型池常量） | 30DAY_PLAN D14-15「战斗/事件/精英/商店/Boss 拓扑」 |
| 2 | **拓扑 = 层式分支**（集成战略式）：L 层（`routes.json.layers`，默认 5）每层 3 节点（`nodes_per_layer`）；**末层 = 1 boss 节点**；层间全连通（层 L 选 1 节点 → 完成后进入层 L+1 选择） | 大纲核心操作「路线选择（玩家控制）」；events.json reroute/unlock_node 以分支为前置 |
| 3 | **种子可复现**：`route_generator.gd` 用 `RandomNumberGenerator` 实例（`rng.seed = seed`）；同 seed → 逐层逐节点类型完全一致；`seed < 0` → `rng.randomize()` 并回传实际 seed | 30DAY_PLAN「种子可复现」；探针坑：禁 Array.shuffle（全局 RNG） |
| 4 | **数据驱动**：`data/routes.json`（W2 新建）`{layers, nodes_per_layer, default_seed, weights:{battle,event,elite,shop}, constraints}`；weights 归一化（和≈1.0） | 项目数据驱动铁律；仿 waves.json 参数表 |
| 5 | **事件改写预留**：generate() 返回 `{seed, layers, modifiers:{}, flags:{}}`；`_weighted_pick` 读 `modifiers.reroute`（类型权重覆盖）——**本日仅预留接口，消费归 Day 16** | events.json effect_on_route 5 型实测 |
| 6 | **节点→波次映射**：战斗类（battle/elite）按**战斗序号 n** 映射 `wave n`（waves.json 6-19 天然含 elite → elite 节点即取对应波）；boss 固定 wave 20；shop/event 无战斗（wave_index=0）；**硬约束：战斗类节点数 ≤ 19**（生成器尾部校验） | waves.json 全量实测（wave 10/20 = boss） |
| 7 | **模式兼容（回归零破坏）**：GameManager 增 `route`（空=波次模式 / 非空=路线模式）+ `route_enabled`；**start_game 默认路线模式**；注入空 route / `route_enabled=false` → 完全旧行为（每波后商店）→ day6 探针注入 1 行恢复 | 阶段 C 新体验默认开启；回归十件套保护 |
| 8 | **GameState 扩展**：枚举增 `ROUTE_SELECT`；状态流 = start_game → ROUTE_SELECT(层1) → 选节点 → BATTLE/SHOP → 节点完 → ROUTE_SELECT(层2) → … → 末层 boss 清 → GAME_OVER(victory)；**`_clear_remaining_enemies()` 保留在 on_wave_cleared 首行** | day4 断言 10 依赖；现有 20 波循环自然收口 |
| 9 | **占位边界（后续日收口，W5 不得判失败）**：event 节点 = 进入时占位推进 + `push_warning("[Route] 事件节点交互归 Day 16")`（交互逻辑 Day 16）；elite 强化 = Day 17；Boss 两阶段 = Day 18-19；遗物 = Day 20；节点图标美术 = Day 21-23（本日类型色块/文本） | 30DAY_PLAN D16/17/18-19/20；主观项 → PLAYTEST |

#### D14-15-T1【W1】新建 `scripts/systems/route_generator.gd`（核心 · 种子可复现路线生成）
- [x] 生成器：`static func generate(seed: int = -1) -> Dictionary` —— 内部 `var rng := RandomNumberGenerator.new()`；`seed >= 0 → rng.seed = seed`，否则 `rng.randomize()` 并记录 `rng.seed` 回传；返回 `{ "seed": int, "layers": Array, "modifiers": {}, "flags": {} }`
- [x] 层结构：`layers = [[{type, wave_index} × nodes_per_layer] × layers]`；末层 = `[{type:"boss", wave_index:20}]`；中间层逐节点 `_weighted_pick`（**禁 Array.shuffle**）
- [x] `_weighted_pick(rng, weights) -> String`：`rng.randf() * total` 落入权重区间（battle/event/elite/shop）；**elite 在低层（当前战斗序号 < 6）禁抽**（无精英波映射，wave≥6 才可抽）
- [x] 战斗序号分配：遍历中间层节点，`type ∈ {battle, elite}` → `wave_index = ++battle_count`（elite 同口径，waves.json 6-19 含 elite）；shop/event → `wave_index = 0`
- [x] 首层保证：生成后检查首层含 `battle`，否则首层第 1 节点强制 `{type:"battle", wave_index:1}`（防进局无事可做）
- [x] 硬校验：`battle_count <= 19`（boss 占 wave 20）；违规 `push_error` 返回空字典
- [x] 只读依赖：映射波次经 `DataLoader.get_wave(n)` 校验存在，不存在则回退上一可用波
- [x] **测试点**：同 seed 两次 generate → 逐层逐节点 type/wave_index 全等；不同 seed（固定 seed 对如 1 vs 2）→ 中间层出现差异；类型覆盖 5 类；末层 boss 唯一；weights 空 → 默认权重表兜底
- [x] 文件域：W1 只写 `scripts/`

#### D14-15-T2【W2】新建 `data/routes.json`（拓扑参数 · 数据驱动）
- [x] 结构：`{ "layers": 5, "nodes_per_layer": 3, "default_seed": <固定整数如 20260806>, "weights": {"battle": 0.5, "event": 0.2, "elite": 0.15, "shop": 0.15}, "constraints": {"first_layer_has_battle": true, "final_layer_boss": true, "max_battle_nodes": 19} }`
- [x] 设计口径：战斗类节点总数 ≈ 12-16（映射 wave 1-16，Boss 前强度爬升合理）；事件/商店穿插层间中段；weights 和=1.0（生成器归一化兜底）
- [x] **测试点**：JSON 校验通过；weights 和 ≈ 1.0；layers × nodes_per_layer ≥ 5；约束字段齐全
- [x] 文件域：W2 只写 `data/routes.json`

#### D14-15-T3【W1】GameManager 路线模式集成（`scripts/autoload/game_manager.gd`）
- [x] GameState 枚举增 `ROUTE_SELECT`（MENU/BATTLE/SHOP/ROUTE_SELECT/GAME_OVER）
- [x] 状态：`var route: Dictionary = {}` / `var route_enabled: bool = true` / `var current_layer: int = 0` / `var current_node: Dictionary = {}`；preload `route_generator.gd`（仿 shop.gd 的 WeaponControllerScript preload 范式）；preload `RouteSelectPanel.tscn`（仿 LevelUpPanelScene 常量范式）
- [x] **DataLoader 补 3 行只读接口 `get_routes()`**（仿 get_wave 范式，读 `data/routes.json` 缓存；routes 缺失返回空字典 → 生成器走默认参数）
- [x] `start_game()`：`route_enabled → route = RouteGenerator.generate(<default_seed>)`（default_seed 取 `DataLoader.get_routes().get("default_seed", -1)`）；`route.is_empty() → 旧逻辑`（波次模式）
- [x] `_start_route_select()`：`current_state = ROUTE_SELECT` + `state_changed.emit`；实例化 RouteSelectPanel `_add_to_ui_layer`；面板 `setup(route, current_layer)`
- [x] `select_route_node(row: int)`：取 `route.layers[current_layer][row]` → `current_node` → `_enter_node(type, wave_index)`
- [x] `_enter_node(type, wave_index)`：`battle/elite/boss → _start_next_wave(wave_index)`；`shop →` 现有商店段（state=SHOP + shop_opened.emit）；`event → push_warning("[Route] 事件节点交互归 Day 16") + _on_node_completed()`（占位）
- [x] **`_start_next_wave()` 改造**：`func _start_next_wave(wave_number: int = -1)` —— `-1`=旧累加行为；`≥1`=指定波次（同步 `current_wave`、is_boss_wave 检测不变）
- [x] `on_wave_cleared()` 改造：**首行保留 `_clear_remaining_enemies()`**（day4 断言 10）；`route 非空 → _on_node_completed()`；`route 空 → 旧行为`（每波后 shop_opened.emit）；胜利判定沿用 `current_wave >= max_waves → end_game(true)`（boss=wave 20 自然命中）
- [x] `_on_node_completed()`：`current_layer += 1`；`current_layer >= route.layers.size() → end_game(true)`（兜底）；否则 `_start_route_select()`
- [x] `close_shop()` 改造：`route 非空 → _on_node_completed()`；`route 空 →` 旧行为（`_start_next_wave()`）
- [x] **测试点**：route 空 → start_game 后 state==BATTLE 且零面板（旧行为回归）；route 非空 → state==ROUTE_SELECT；select_route_node(battle 行) → BATTLE 且 wave==映射值；battle 清后 → 下一层选择或连续战斗；shop 节点 → close_shop → 推进；boss 节点清 → end_game(true)
- [x] 文件域：W1 只写 `scripts/`

#### D14-15-T4【W1】新建 `scenes/RouteSelectPanel.tscn` + `scripts/ui/route_select_panel.gd`（路线选择面板）
- [x] 仿 LevelUpPanel/ShopPanel 范式：`CanvasLayer` + `NinePatchRect` 面板（复用 `assets/sprites/ui/panel_card.png`）+ 标题 Label（「第 N 层 · 选择路线」）
- [x] **按钮动态生成**（代码 `for` 循环 `add_child(Button)`，仿 shop.gd 卡片范式；数量 = 本层节点数，不硬编码 3）——按钮文本 = 节点类型名（battle=战斗 / event=事件 / elite=精英 / shop=商店 / boss=Boss）+ 类型色块（ColorRect 或按钮样式，首版不依赖新美术图标）
- [x] `setup(route: Dictionary, layer: int)`：渲染 `route.layers[layer]`；末层（1 boss）自动 1 按钮
- [x] 点击按钮 → `GameManager.select_route_node(row)` → `queue_free()`；`GameManager.game_over` 信号连接释放（防悬挂，仿 level_up_panel.gd:17-20）
- [x] **不暂停游戏**（spawner 非 BATTLE 状态自动停，与商店一致）；Main.tscn 无需预实例（GameManager 运行时实例化）
- [x] **测试点**：白盒实例化 + setup → 按钮数 == 本层节点数；点击 → 回调 select_route_node 且面板销毁；无头可实例化不崩
- [x] 文件域：W1 只写 `scenes/` + `scripts/`

#### D14-15-T5【W1】新建 `tools/day14_15_route_check.gd`（路线地图探针 ≥20 断言）
- [x] §1 种子可复现：固定 seed 两次 generate 全等（层数/每层 type+wave_index 全等）；seed 1 vs 2 差异断言（固定 seed 对，禁 flaky）
- [x] §2 拓扑合法性：layers == routes.json.layers；每层节点数 == nodes_per_layer（末层 1 boss）；首层含 battle；boss 仅末层；类型 ∈ 5 类；battle_count ≤ 19
- [x] §3 数据驱动：routes.json weights 归一化（和≈1.0 容差 0.05）；default_seed 可读；weights 全空 → 默认权重兜底
- [x] §4 波次映射：battle/elite 节点 wave_index ∈ [1,19] 且 `DataLoader.get_wave()` 非空；boss → 20；shop/event → 0
- [x] §5 模式兼容：`GameManager.route_enabled = false` → start_game → state==BATTLE 且零面板（旧行为）；`_start_next_wave()` 默认 -1 累加不变
- [x] §6 路线模式端到端（白盒直驱动）：固定 seed route → start_game → state==ROUTE_SELECT → `select_route_node(战斗行)` → state==BATTLE + wave==映射值 → `on_wave_cleared()` → 下一层选择（ROUTE_SELECT）或连续战斗；shop 节点 → close_shop → 推进；boss 节点清 → victory
- [x] **回归锚点同步更新**：day6_integration_check boot 后注入 `GameManager.route_enabled = false`（1-2 行，其余断言不动）；day4_level_check 断言 10 回归（on_wave_cleared 清残敌保留）
- [x] 探针范式沿用：`extends SceneTree` + `_advance` 分派全部 sub + seed 固定 + 白盒直构造（见 Day 11-12/13 flaky 修复记录）
- [x] 文件域：W1 只写 `tools/`

#### D14-15-EXIT【W5】阶段 C 首段收口
- [x] `python tools/baseline_check.py` → `BASELINE CLEAN`
- [x] `day14_15_route_check` CLEAN + **回归十件套**（day2 32 / day3 16 / day4 21 / day5 16 / day6 14·注入 route 兼容后 / day7 13 / day8 19 / day10 20 / day11_12 22 / day13 36）+ `gen_weapons_day7.py verify` 36/36
- [x] git commit 收口（**勿夹带** docs/pindou/、scripts/ui/level_up_panel.gd.bak、tools/pixel_to_pindou.py、docs/LOOP_HEALTH.md —— 各自动化/第三方自主提交）
- [x] 主观项登记：节点地图观感 / 路线选择 UI 手感 / 层节奏体感 → PLAYTEST_CHECKLIST.md（#5 收口），不阻塞出口

### Day 16 — 事件节点　✅【客观任务 100% 完成 · 已收口 · 2026-08-06 20:2x · #3】

> ✅ **数据侧已由 08-04 并发冲刺预交付**：`events.json` = `{events:[10]}`，w4 落盘（f78e29e），JSON 校验通过；`effect_on_route` 负值为设计内代价（`TEST_REPORT` §5）。
> 🎯 **Day 16 已预拆解（2026-08-06 17:1x · #2 第 15 轮）**：Day 14-15 实现已 100% 落地（待 EXIT 收口）→ 预拆 Day 16 = **事件节点系统**。核心交付 = **弹窗 UI（描述 + 选项 A/B）+ 奖励结算（10 型）+ 改线（5 型）**。数据已就绪，`scripts/` 全域**尚无事件消费方**（`_enter_node` 的 event 分支为 push_warning 占位）——本日为纯代码日 + 1 条数据补齐。

> 📌 **Day 16 实测基线（#2 第 15 轮新核，供 #3 免排查）**
> - **events.json 10 事件结构**：`{id, title, theme, description(超长 100-250 字), choiceA:{text, reward:{type,value,label}}, choiceB:{text, effect_on_route:{type,value,label}}}`
> - **reward type 10 型实测**：`attack_speed_percent`(攻速+8%) / `max_hp`(生命+20 加算) / `gold`(星尘+150) / `item`(**resonant_shard 悬空**——items.json 无此 id，实测 grep 零匹配) / `weapon_upgrade`(随机武器+1 级) / `luck`(+15) / `attack_percent`(攻击+12%——**STAT_MAP 无此键**，需别名) / `heal_percent`(回 40% 血) / `trade`(value=dict：{max_hp_percent:-15, damage_percent:+30} 复合双键) / `level_up`(升 2 级)
> - **effect_on_route type 5 型实测**：`reroute`(echo_cradle「事件减战斗增」/ mirror_pool「下一节点必定精英」) / `flag`(alliance_report_filed/choir_silenced/debt_acknowledged 全局标记) / `unlock_node`(rib_layer_shortcut 跳战斗直通精英 / boss_corrupted_tree_early 直达 Boss 层 / awakening_archive 局外档案) / `add_node`(**value=rescue_signal 不在 events.json 10 事件内**——悬空，须随机兜底) / `difficulty`(本层敌人强度-1 档)
> - **奖励结算接口全部已验证就位（零新基建）**：`player.apply_stat_modifier(stat, v, is_multiplicative)`(player.gd:361，max_health 乘算负值 0.85 已支持 :363-365) ｜ `player.gain_exp(v)`(:317) / `get_xp_to_next_level()`(:326) / `heal(v)`(:299) ｜ `GameManager.economy.add_coins(v)`(economy.gd:19) ｜ `GameManager.inventory.add_item_from_data(id)`(inventory.gd:75) + `apply_item_bonuses` 装配（D11-12 已通）｜ 武器升级分支参照 `level_up_panel.gd:110-114`（`weapon.upgrade()`）
> - **STAT_MAP 缺口**（player.gd:50-66）：有 `damage_percent/attack_speed_percent/max_hp/luck/crit_damage_percent`，**无 `attack_percent`、无 `max_hp_percent`** → 事件结算层别名（`attack_percent→damage`、`max_hp_percent→max_health` 乘算），**不改 STAT_MAP**（避免波及 D4/D11-12 探针口径）
> - **route_generator 改线接口现状**：`generate()` 一次性生成全部层；`_weighted_pick` 已消费 `modifiers.reroute` 权重覆盖(:118-136) 但**无对外改线方法** → 本日新增静态方法 `reroute_remaining(route, from_layer, weights)` + `force_node_type(route, li, ni, type)`（RNG 实例 + 禁 Array.shuffle）
> - **UI 范式**：事件 = **暂停式**弹窗（阅读+抉择，同 LevelUpPanel：`paused=true` + `PROCESS_MODE_WHEN_PAUSED` + game_over 防悬挂）；商店/选层不暂停（spawner 非 BATTLE 自动停）——二者范式在 D14-15 已区分
> - **探针坑（沿用）**：随机抽武器升级/随机取事件 → **RandomNumberGenerator 实例**（GameManager 新增 `_event_rng` 成员），禁 Array.shuffle/pick_random（全局 RNG 种子不可控）
> - **回归锚点**：商店池 53（33 武器−3 结果 + 20 被动）**不变**（resonant_shard 不设 is_passive 不入池）；被动池 20 不变；day11_12 探针若断言 items 总项数 48 → 同步 49（20 被动/icon 0-19 断言不动）

#### D16-PRE【W1+W2】事件节点系统定案表
| # | 决策 | 依据 |
|---|---|---|
| 1 | **事件弹窗 = 暂停式**（同 LevelUpPanel：paused=true + WHEN_PAUSED + game_over 防悬挂 + `_add_to_ui_layer`）；事件是阅读+抉择，必须暂停 | LevelUpPanel 范式（D4-T4 已验证）；D14-15 已区分商店/选层「不暂停」 |
| 2 | **事件绑定 = GameManager 随机取**：`_start_event` 时从 `DataLoader.get_events()` 随机取 1 条（零 route_generator 改动；事件可重复符合肉鸽；`add_node` 的悬空 id 同理随机兜底） | route_generator 只生成 type 无 event_id（D14-15 定案）；events.json 10 条全量可用 |
| 3 | **reward 10 型结算表**：见下「D16-T2」分派——`attack_percent→damage` / `max_hp_percent→max_health` 代码层别名（**禁改 STAT_MAP**，防波及 D4/D11-12 探针）；`item` 直装 `apply_item_bonuses`（resonant_shard 获得即生效、不占 6 被动槽——遗物语义，完整遗物槽归 Day 20） | STAT_MAP 实测缺口；D11-12 装配链路已通；30DAY_PLAN D20 遗物 |
| 4 | **effect_on_route 5 型改线表**：`reroute`=策略表→`route_generator.reroute_remaining()`（未访问层按新权重重抽，wave_index 重算）；`flag`= `route.flags[value]=true` 登记（消费归 Day 17/20/25）；`unlock_node`=策略分派（rib_layer_shortcut→force_node_type 精英 / boss_corrupted_tree_early→跳层+flag / awakening_archive→flag）；`add_node`=当前层+2 追加 event 节点（不超末层，超则末层前）；`difficulty`= `route.flags["difficulty_delta"]=value` 登记（敌人强度消费归 Day 17 精英/平衡） | events.json 5 型实测；route_generator modifiers/flags 接口（D14-15 预留） |
| 5 | **改线深消费边界（W5 不得判失败）**：`flag` 的商店折扣/事件增减/Boss 护盾、`difficulty` 的敌人强度缩放、`unlock_node` 的局外档案——本日仅登记进 `route.flags`/`modifiers`，实际消费标注归 Day 17（精英）/Day 20（遗物）/Day 25（剧情）/Day 27（局外） | 渐进式收口；D14-15 同类占位先例 |
| 6 | **resonant_shard 数据补齐**（W2）：items.json +1 条 `{id:"resonant_shard", rarity:"epic", price:0, effects:{crit_damage_percent:25}, tags:["relic"], name:"共鸣碎晶"}`——**不设 is_passive**（不入被动池/商店池，53 池与 20 被动口径零破坏）；**回归同步**：day11_12 探针 items 总项数断言 48→49（若有）；图标占位登记 `[!]`（items.png 第 21 帧实绘归 W3/美术，icon_atlas 越界兜底帧 0） | events.json crystal_vein 选 A 实测悬空（grep 零匹配）；D11-12 被动池定案不可破坏 |
| 7 | **随机性管控**：GameManager 新增 `_event_rng := RandomNumberGenerator.new()`（种子可复现，探针注入 seed）；随机取事件/随机抽武器一律走 `_event_rng.randi_range()` | 探针坑：Array.shuffle/pick_random 走全局 RNG（D11-12/D14-15 铁律） |
| 8 | **长文本适配**：description 实测最长 200+ 字 → 面板放大（~560×320 内）+ 描述 Label `autowrap_mode = WORD_SMART` + 视口 640×360 内可读；字号 8-10 | events.json 实测；UI 视口 640×360（ART_STYLE v2） |
| 9 | **占位边界（后续日收口，W5 不得判失败）**：遗物槽位/图标 = Day 20/21-23；事件文案调性/弹窗排版 = 主观项 → PLAYTEST（#5） | 30DAY_PLAN D20/D21-23；主观项隔离铁律 |

#### D16-T1【W1】新建 `scenes/EventSelectPanel.tscn` + `scripts/ui/event_select_panel.gd`（事件弹窗）
- [x] 仿 LevelUpPanel：`CanvasLayer` + `CenterContainer` + `Panel`(NinePatchRect 复用 `assets/sprites/ui/panel_card.png`) + VBox：标题 Label（`event.title`）+ theme 标签 + 描述 Label（**autowrap_mode = TEXT_AUTOWRAP_WORD_SMART**，面板尺寸 ~560×320 适配长文本）+ 2 个选项 Button
- [x] `_ready()`：`GameManager.game_over.connect` → 防悬挂 queue_free（仿 level_up_panel.gd:23-28）
- [x] `setup(event_data: Dictionary)`：渲染 title/theme/description + 选项按钮文本 = `choiceA.text`（下附小字 reward.label）/ `choiceB.text`（下附小字 effect_on_route.label）
- [x] 按钮点击 → `GameManager.resolve_event_choice("A"/"B")` → `queue_free()`（面板释放由 GameManager 在结算后管理，防双释放）
- [x] **暂停式**：节点 `process_mode = PROCESS_MODE_WHEN_PAUSED`（GameManager 在 `_start_event` 设 `get_tree().paused = true`）
- [x] **测试点**：白盒实例化 + setup(事件 dict) → 按钮数 == 2 + 标题/描述非空；点击 A → 回调 resolve_event_choice("A") 且面板销毁；无头可实例化不崩
- [x] 文件域：W1 只写 `scenes/` + `scripts/`

#### D16-T2【W1】GameManager 事件接入 + 奖励结算 + 改线（`scripts/autoload/game_manager.gd`）
- [x] `_enter_node()` event 分支：替换 push_warning 占位 → `_start_event()`
- [x] 状态：`var _event_rng := RandomNumberGenerator.new()` / `var _current_event: Dictionary = {}` / `var _event_panel: Node = null`；preload `EventSelectPanelScene`（仿 LevelUpPanelScene 常量范式）；DataLoader 补只读接口 `get_events() -> Array`（仿 get_wave，缓存 events.json，缺失返回 []）
- [x] `_start_event()`：随机取事件（`_event_rng.randi_range(0, events.size()-1)`）→ `_current_event = events[i]` → `get_tree().paused = true` → 实例化面板 + `_add_to_ui_layer` + `setup(_current_event)`（**随机取 → 事件可重复，符合肉鸽；零 route_generator 改动**）
- [x] `resolve_event_choice(choice: String)`：choice=="A" → `_apply_event_reward(_current_event.choiceA.reward)`；=="B" → `_apply_route_effect(_current_event.choiceB.effect_on_route)`；`get_tree().paused = false` → `_on_node_completed()`
- [x] **`_apply_event_reward(reward)` 10 型分派**（接口全部已验证）：
  - `attack_speed_percent` → `player.apply_stat_modifier("attack_speed", 1+value/100, true)`
  - `attack_percent` → **别名 damage**：`player.apply_stat_modifier("damage", 1+value/100, true)`
  - `max_hp` → `player.apply_stat_modifier("max_health", value)`（add）
  - `max_hp_percent`（trade 内键）→ `player.apply_stat_modifier("max_health", 1+value/100, true)`（负值乘算已验证）
  - `damage_percent`（trade 内键）→ `player.apply_stat_modifier("damage", 1+value/100, true)`
  - `gold` → `economy.add_coins(int(value))`
  - `luck` → `player.apply_stat_modifier("luck", value)`
  - `heal_percent` → `player.heal(player.max_health * value/100.0)`
  - `item` → `DataLoader.get_item(value)` 存在 → 直装 `player.apply_item_bonuses(item_resource)`（**不进 inventory 槽**，获得即生效）；不存在 → push_warning 登记（resonant_shard 由 D16-T4 补齐；其余未知 id 兜底不崩）
  - `weapon_upgrade` → 已装备武器非空 → `_event_rng.randi_range(0, n-1)` 抽 1 把 `upgrade()`；空 → push_warning（**禁 Array.pick_random**）
  - `level_up` → `player.gain_exp(player.get_xp_to_next_level() * int(value))`（升 value 级；连升面板合并策略已有 game_manager.gd:219-227）
  - 未知 type → push_warning 登记（禁静默）
- [x] **`_apply_route_effect(effect)` 5 型改线**：
  - `reroute` → 策略表映射（`silent_corridor` = {"event":-0.1,"battle":+0.1} / `shattered_path` = 下一节点强制 elite）→ `route_generator.reroute_remaining(route, current_layer+1, weights)` 或 `force_node_type`
  - `flag` → `route.flags[value] = true`（登记；消费归 Day 17/20/25）
  - `unlock_node` → 策略分派：`rib_layer_shortcut` = 下一层首个战斗节点 `force_node_type` → elite；`boss_corrupted_tree_early` = `current_layer` 跳到 Boss 前一层 + `route.flags["boss_early"]=true`；`awakening_archive` = `route.flags["archive_unlocked"]=true`（局外归 Day 27）
  - `add_node` → 目标层 = `current_layer + 2`（不超 `layers.size()-1`，超则末层前）→ `append({type:"event", wave_index:0})`（value 为悬空 id → 随机事件兜底已由 T2 的随机取机制覆盖）
  - `difficulty` → `route.flags["difficulty_delta"] = int(value)`（登记；敌人强度消费归 Day 17）
- [x] **测试点**：白盒注入 event 节点 → `_enter_node` → state 暂停 + 面板出现；resolve "A"(gold) → coins +150 + paused=false + 面板释放 + 层推进；resolve "B"(reroute) → modifiers 生效；10 型 reward 逐型白盒断言（探针 D16-T5 主战场）
- [x] 文件域：W1 只写 `scripts/`

#### D16-T3【W1】`route_generator.gd` 扩展改线静态方法（改线接口落点）
- [x] `static func reroute_remaining(route: Dictionary, from_layer: int, weights_override: Dictionary) -> void`：对 `route.layers[from_layer..]` 未访问节点按**新权重**逐节点 `_weighted_pick` 重抽（RNG 实例 + 禁 Array.shuffle；elite 低层禁抽保持）；重抽后**重算战斗序号 → wave_index 重映射**（沿用 `_resolve_wave`）
- [x] `static func force_node_type(route: Dictionary, layer_index: int, node_index: int, new_type: String) -> void`：单点强制类型 + 重算该节点 wave_index（battle/elite → 重分配；event/shop → 0；越界 push_warning 返回）
- [x] **边界**：两方法均不碰 `route.seed/modifiers/flags` 之外字段；boss 层不可改写（末层保护）；`battle_count` 上限校验保持
- [x] **测试点**：reroute_remaining 后未访问层 battle 占比变化 + 全部 wave_index ∈ [1,19] 合法；force_node_type 后指定节点类型变化 + wave_index 合法；末层 boss 调用 force → 拒绝 + push_warning
- [x] 文件域：W1 只写 `scripts/systems/`

#### D16-T4【W2】`resonant_shard` 遗物数据补齐 + 回归同步
- [x] items.json +1 条：`{"id":"resonant_shard", "name":"共鸣碎晶", "rarity":"epic", "price":0, "effects":{"crit_damage_percent":25}, "tags":["relic"]}` —— **不设 is_passive**（不入被动池/商店池，商店 53 / 被动 20 口径零破坏）；四字段 is_passive/slot/category/icon_index 缺省（遗物语义，完整字段归 Day 20）
- [x] **回归同步**：day11_12 探针若断言 items 总项数 == 48 → 同步 49（20 被动 / icon 0-19 唯一 / 3 核心命中断言**不动**）；day13 商店池断言（53）不受影响
- [x] 图标占位登记：items.png 第 21 帧实绘 = `[!]` 美术项（归 W3/Day 21-22，icon_atlas 越界兜底帧 0，不阻塞）
- [x] **测试点**：`python tools/baseline_check.py` JSON 校验通过；商店池仍 53（20 被动）；`DataLoader.get_item("resonant_shard")` 非空；装配 `apply_item_bonuses` → crit_damage ×1.25
- [x] 文件域：W2 只写 `data/items.json`（回归同步文件归 W5/执行者确认）

#### D16-T5【W1】新建 `tools/day16_event_check.gd`（事件系统探针 ≥18 断言）
- [x] §1 数据层：events.json 10 事件结构完整（id/title/description/choiceA.text/choiceB.text 全非空）；reward type ∈ 10 型枚举；effect_on_route type ∈ 5 型枚举
- [x] §2 reward 结算（白盒直构造 10 型）：gold→coins+150；max_hp→max_health+20；luck→+15；attack_speed_percent→×1.08；attack_percent→damage ×1.12；heal_percent→health 恢复；level_up→level+2 + 升级面板触发（连升合并）；trade→max_health×0.85 + damage×1.30 双键；weapon_upgrade→随机武器 level+1（seed 固定）；item→resonant_shard 装配 crit_damage ×1.25
- [x] §3 effect 改线：reroute(silent_corridor)→modifiers.reroute 生效 + 未访问层比例变化；flag→route.flags 登记；unlock_node 三策略（rib_layer_shortcut 强制精英 / boss_early 跳层 / archive flag）；add_node→层+2 追加 event；difficulty→flags["difficulty_delta"] 登记
- [x] §4 端到端（白盒直驱动）：注入 event 节点 → `_enter_node` → 暂停 + 面板出现 → resolve "A" → 结算 + 面板释放 + `_on_node_completed` 推进；resolve "B"(reroute) → 改线生效
- [x] §5 回归锚点：商店池 53（resonant_shard 不入池）；被动池 20；day14_15 探针全量回归（route event 节点 wave_index==0 断言保持）；`_event_rng.seed` 固定（禁 flaky）
- [x] 探针范式沿用：`extends SceneTree` + `_advance` 分派全部 sub + seed 固定 + 白盒直构造（D11-12/13/14-15 flaky 修复记录）
- [x] 文件域：W1 只写 `tools/`

#### D16-EXIT【W5】阶段 C 第二节收口
- [x] `python tools/baseline_check.py` → `BASELINE CLEAN`
- [x] `day16_event_check` CLEAN + **回归十一件套**（day2 32 / day3 16 / day4 21 / day5 16 / day6 14 / day7 13 / day8 19 / day10 20 / day11_12 22·总项数 48→49 同步后 / day13 36 / day14_15）+ `gen_weapons_day7.py verify` 36/36
- [x] git commit 收口（**勿夹带** docs/pindou/、scripts/ui/*.bak、tools/pixel_to_pindou.py、docs/LOOP_HEALTH.md —— 各自动化/第三方自主提交）
- [x] 主观项登记：事件文案调性 / 弹窗排版可读性 / 抉择体感 → PLAYTEST_CHECKLIST.md（#5 收口），不阻塞出口

### Day 17 — 精英战斗　🎯【已预拆解到函数级 · 2026-08-06 19:1x · #2 第 16 轮】

> 🎯 **Day 17 已预拆解（2026-08-06 19:1x · #2 第 16 轮）**：Day 14-15 已收口（`fa077e0`）、Day 16 已预拆（事件节点）→ 预拆 Day 17 = **精英战斗**。核心交付 = **精英特殊能力（3 只新实现）+ 强化属性（scaling 倍率已消费 ✅）+ mixed 池令牌解析（BUG-003 收口）+ difficulty_delta 消费（Day 16 事件登记 → 本日收口）**。waves.json 6-19 天然含 elite 前缀 → 精英节点/波次映射**零数据改动**；6 精英 = 3 只已有行为（rhino charge / colossus+croc chase）+ 3 只新能力（butcher AOE / monk 自愈 / mom 产卵）。**Boss phases 状态机归 Day 18-19**，W5 不得判失败。

> 📌 **Day 17 实测基线（#2 第 16 轮新核，供 #3 免排查）**
> - **enemies.json 6 精英**（`{enemies:{regular[15], elite[6], boss[2]}}`）：butcher 屠夫 hp200·`aoe_attack`·exp30 / colossus 巨像 hp300·`chase`·exp40 / rhino 犀牛 hp250·`charge`·exp35 / monk 修士 hp200·`self_heal`·exp30 / croc 鳄鱼 hp220·`chase`·exp35 / mom 母体 hp250·`spawn`·exp35；**均无 ability 字段**；drop=10
> - **精英 scaling 已消费 ✅**：data_loader.gd:184-189 硬编码 `elite_hp_mult = 1+wave*0.15` / `elite_dmg_mult = 1+wave*0.08`（与 enemies.json scaling 定义一致）；`get_scaled_enemy` 返回 12 键含 `phases`（boss 用，enemy.initialize **不消费**——归 Day 18-19）
> - **elite 行为实现缺口**：enemy.gd Behavior 枚举 9 种含 `AOE_ATTACK`/`SELF_HEAL`/`SPAWN`，但 `_update_behavior` 三分支**只有移动逻辑无实际技能**（AOE_ATTACK→_move_chase / SELF_HEAL→_move_chase / SPAWN→_move_spawn 0.5 速）；CHARGE（犀牛）完整 ✅、CHASE（巨像/鳄鱼）✅；`is_elite` 标记 ✅（initialize match category）
> - **⚠️ BUG-003（P1）mixed 家族池令牌零解析**：waves.json wave 15/17/19 composition = `{"enemy":"mixed","count":56/61/65}` + `{"enemy":"elite:mixed","count":4/4/5}`；spawner `_create_enemy` 解析 `elite:mixed` → id="mixed" → `get_scaled_enemy("mixed")` 查空 → push_warning + null → **该 3 波普通敌+精英全部静默不生成**（TEST_REPORT/PLAYTEST H-06·5.3 latent 已登记「交 w1-code」，WaveManager 落地后至今未实现）——`mixed`/`mixed_with_curse`/`elite:mixed` 为**有意聚合池令牌**（非笔误），本日 spawner 池解析收口
> - **difficulty_delta 消费点**：Day 16 `_apply_route_effect` 的 `difficulty` 型写入 `route.flags["difficulty_delta"]`（登记）；`route.flags` 当前**零消费方**（grep 仅 route_generator 创建 + GameManager 持有）→ 本日在战斗节点入口消费（±1 档 ±10% hp/damage）
> - **产卵复用路径**：spawner `_create_enemy`（enemy_spawner.gd:85-118）→ `enemy_scene.instantiate()` + `initialize(stats)` + `set_target(player)`；mom 产卵须记录自身 wave（enemy.gd 加 `wave_number`，spawner 注入）→ `get_scaled_enemy(minion, wave_number)`
> - **VfxPlayer 5 特效**：hit/crit/death/levelup/pickup（vfx_player.gd:16-22）——AOE/自愈/产卵本日复用 crit/hit/death，专属特效归 Day 23；无头稳铁律：AOE/产卵用距离判断+容器遍历，**禁物理查询**（同 `_try_contact_damage` :148-155 范式）
> - **UI 范式**：精英节点进入提示 = 轻量横幅（Node2D/Label 淡出 1.5s，仿 exp 飘字 :401-417），无头不崩；视觉主观项 → PLAYTEST
> - **回归锚点**：waves.json **不动**（池令牌保留，spawner 解析）；day14_15 探针 elite 节点 wave_index ∈ [6,19] 断言保持；day6 探针端到端不打到 15 波+（无碍）；`route_generator` `MIN_ELITE_WAVE=6` 低层禁抽保持

#### D17-PRE【W1+W2】精英战斗定案表
| # | 决策 | 依据 |
|---|---|---|
| 1 | **精英 = 强化属性（已有 ✅）+ 特殊能力（实现缺口）**；6 精英拆两档：3 只既有行为（rhino charge / colossus+croc chase）+ 3 只新能力（butcher AOE / monk 自愈 / mom 产卵） | 30DAY_PLAN D17「特殊能力 / 强化属性」；enemy.gd 行为实现现状实测 |
| 2 | **能力参数数据驱动**：enemies.json 精英 +`ability` 字段（仿 Day 3 `burn_duration` 先例）；**缺省 = 无特殊能力**（colossus/rhino/croc 不补，数据最小化不臆造） | 项目数据驱动铁律；elite scaling 已数据化先例 |
| 3 | **BUG-003（P1）mixed 池解析收口**：spawner `_create_enemy` 支持 `mixed`（→regular 池随机）/ `elite:mixed`（→elite 池随机）/ `mixed_with_curse`（→regular 池，咒诅效果无数据定义不臆造）；**RNG 实例**（spawner 加 `_rng` 成员，探针可注 seed），**不动全局 randf_range**（仅位置随机） | waves.json wave 15/17/19 实测；TEST_REPORT 7.1 / PLAYTEST H-06·5.3 latent 收口 |
| 4 | **difficulty_delta 消费**（Day 16 登记 → 本日收口）：战斗节点入口读 `route.flags["difficulty_delta"]` → 敌人 hp/damage ×(1+0.1×档)；0 = 零影响 | Day 16 `_apply_route_effect` difficulty 型；route.flags 零消费方实测 |
| 5 | **产卵缩放**：enemy.gd 加 `wave_number`（spawner 注入）→ mom 产卵 `get_scaled_enemy(minion, wave_number)` 同波缩放 | 数据驱动成长铁律；spawner 范式可复用 |
| 6 | **无头稳定铁律**：AOE/产卵/自愈全部用距离判断 + 容器遍历，**禁物理查询**（同 `_try_contact_damage` 范式） | Day 3 火球物理碰撞不可靠先例（19:15 修复记录） |
| 7 | **精英视觉最小方案**：is_elite 标记已有 ✅；本日 = 精英节点进入横幅提示 + 精英敌人 modulate 区分色（如淡金色调）；专属精灵归 Day 21-22、VFX 归 Day 23 | ART_STYLE v2 精灵基准；D21-23 排期 |
| 8 | **占位边界（W5 不得判失败）**：Boss `phases` 状态机（get_scaled_enemy 已透传）归 Day 18-19；curse_wave 咒诅效果无数据定义 → 本日仅保证池解析不生成失败；遗物归 Day 20；精英 UI 手感/难度体感 → PLAYTEST | 30DAY_PLAN D18-19/20；渐进式收口先例 |
| 9 | **回归零破坏**：waves.json 池令牌保留（spawner 解析非数据展开，防 total_enemies/其他断言波及）；day14_15 elite 节点 wave_index ∈ [6,19] 断言不动；day6 端到端不触及 wave 15+ | 池令牌为有意设计（TEST_REPORT）；回归锚点保护 |

#### D17-T1【W2】`enemies.json` 精英 `ability` 字段（能力参数数据化）
- [ ] butcher（屠夫）+`"ability": {"type": "aoe", "radius": 90.0, "interval": 3.0, "damage_mult": 1.2}` —— 周期对周围造成伤害
- [ ] monk（修士）+`"ability": {"type": "self_heal", "threshold": 0.5, "heal_percent": 0.15, "interval": 4.0}` —— 血量 < 50% 周期自愈 15%
- [ ] mom（母体）+`"ability": {"type": "spawn", "minion": "chaser", "count": 2, "interval": 5.0}` —— 周期产 2 只小怪（chaser，用自身 wave 缩放）
- [ ] colossus/rhino/croc **不补**（缺省无能力，靠既有行为 + scaling 强化）；已有 6 精英其余字段（hp/hp_growth/damage/behavior/exp_value/drop）**零改动**
- [ ] **测试点**：JSON 校验通过；ability.type ∈ {aoe, self_heal, spawn}；minion id 在 enemies.json 存在；数值 > 0
- [ ] 文件域：W2 只写 `data/enemies.json`

#### D17-T2【W1】`enemy.gd` 精英能力消费（AOE / 自愈 / 产卵三行为真实实现）
- [ ] 状态：`var ability: Dictionary = {}` / `var wave_number: int = 1` / `var _ability_timer: float = 0.0`
- [ ] `initialize(stats)`：`if stats.has("ability"): ability = stats["ability"]`；`if stats.has("wave_number"): wave_number = int(stats["wave_number"])`
- [ ] `_update_behavior` 三分支：`AOE_ATTACK → _move_chase(delta) + _elite_aoe(delta)`；`SELF_HEAL → _move_chase(delta) + _elite_self_heal(delta)`；`SPAWN → _move_spawn(delta) + _elite_spawn(delta)`
- [ ] `_elite_aoe(delta)`：`_ability_timer -= delta`；≤0 → 距玩家 ≤ radius 则 `target.take_damage(damage * damage_mult)`（VfxPlayer.spawn 容器 `crit` 特效）+ `_ability_timer = interval`；**距离判断禁物理查询**
- [ ] `_elite_self_heal(delta)`：`_ability_timer -= delta`；health < max_health × threshold 且 ≤0 → `health = min(max_health, health + max_health * heal_percent)` + `health_changed.emit`（VfxPlayer `levelup` 复用）+ 重置 timer
- [ ] `_elite_spawn(delta)`：`_ability_timer -= delta`；≤0 → ×count 循环：实例化 `enemy_scene`（spawner 同款 preload/资源）+ `initialize(DataLoader.get_scaled_enemy(minion, wave_number))` + `set_target(GameManager.player)` + `GameManager.enemies_container.add_child`（容器缺失静默跳过不崩）→ 重置 timer
- [ ] **测试点**：白盒构造 stats 带 ability → 推进 delta 触发三行为断言（AOE 玩家掉血 / 自愈 health 回升 / 产卵容器 +2 只 chaser 且 wave 缩放正确）；无 ability → 零新行为（回归零破坏）；timer 不触发 → 无副作用
- [ ] 文件域：W1 只写 `scripts/`

#### D17-T3【W1】BUG-003 收口：`enemy_spawner.gd` mixed 家族池解析
- [ ] 状态：`var _rng := RandomNumberGenerator.new()`（探针可注 `_rng.seed`；**不动全局 randf_range**——仅位置随机，不影响生成内容）
- [ ] `_create_enemy()` 前缀解析后增加池分支：
  - `enemy_id == "mixed" or enemy_id == "mixed_with_curse"` → `DataLoader.get_enemy_ids_by_category("regular")` 随机抽 1（`_rng.randi_range(0, arr.size()-1)`）→ 按抽中 id 走正常 get_scaled_enemy 流程
  - 前缀 `elite:` 且 `enemy_id == "mixed"`（elite:mixed）→ `get_enemy_ids_by_category("elite")` 随机抽 1 → 同流程
- [ ] 未知 id → 既有 push_warning + null 保持（不静默扩池）；`swarm_wave` HP 减半 / count×2 逻辑与池解析**顺序兼容**（先解析后缩放，wave 15 的 swarm 语义保持）
- [ ] **测试点**：固定 `_rng.seed` → `spawn_wave(wave15_config)` → 精英 4 只（id ∈ 6 精英）+ regular 池 56 只（id ∈ 15 regular）→ **零 push_warning 零 null**；wave17（mixed_with_curse）同法；`elite:mixed` 永不抽到 boss/regular
- [ ] 文件域：W1 只写 `scripts/`

#### D17-T4【W1】difficulty_delta 消费 + 精英节点提示
- [ ] GameManager：`var difficulty_delta: int = 0`；`_enter_node()` 的 battle/elite/boss 分支同步 `difficulty_delta = int(route.flags.get("difficulty_delta", 0))`（空 route / 无 flags → 0）
- [ ] spawner `_create_enemy`（池解析 + swarm 缩放后）：`if GameManager: var dd := GameManager.difficulty_delta; if dd != 0: stats["max_health"] *= 1.0 + 0.1 * dd; stats["damage"] *= 1.0 + 0.1 * dd`（±1 档 ±10%）
- [ ] 精英节点提示：`_enter_node()` 的 `elite` 分支 → 轻量横幅（Node2D + Label「⚔ 精英来袭」1.5s 淡出，仿 enemy.gd `_spawn_exp_popup` :401-417 范式；容器缺失静默跳过）——**不暂停**（与选层/商店同范式）
- [ ] **测试点**：`route.flags["difficulty_delta"]=+1` → 生成敌人 max_health ×1.1（白盒断言）；`=0` 零影响；elite 节点进入 → 横幅节点出现并自动销毁；无头不崩
- [ ] 文件域：W1 只写 `scripts/`

#### D17-T5【W1】新建 `tools/day17_elite_check.gd`（精英系统探针 ≥18 断言）
- [ ] §1 数据层：6 精英 id/name/behavior/exp_value/drop 齐；3 只有 ability 且 type ∈ {aoe, self_heal, spawn} + 数值 > 0；minion id 存在；colossus/rhino/croc 缺省无 ability
- [ ] §2 能力行为（白盒直构造 stats + 固定 delta 推进）：butcher AOE → 玩家掉血（damage×mult）且 timer 重置；monk 低血自愈 → health 回升且不超上限；mom 产卵 → 容器 +count 只 chaser（wave_number 缩放正确）；无 ability → 零新行为
- [ ] §3 mixed 池解析：固定 `_rng.seed` → wave15 spawn → 精英 4 只（id ∈ elite 池）+ regular 56 只（id ∈ regular 池）零 null；wave17（mixed_with_curse）同法；`elite:mixed` 不抽 boss/regular
- [ ] §4 difficulty_delta：route.flags +1 → 敌人 max_health ×1.1；0 → 不变
- [ ] §5 回归锚点：6 精英 behavior ∈ 9 枚举；`is_elite` 标记正确；elite 节点 wave_index ∈ [6,19]（day14_15 口径）；day14_15 探针全量回归（若 day16 已收口再 +day16）
- [ ] 探针范式沿用：`extends SceneTree` + `_advance` 分派全部 sub + seed 固定 + 白盒直构造（D11-12/13/14-15 flaky 修复记录）
- [ ] 文件域：W1 只写 `tools/`

#### D17-EXIT【W5】阶段 C 第三节收口
- [ ] `python tools/baseline_check.py` → `BASELINE CLEAN`
- [ ] `day17_elite_check` CLEAN + **回归十一件套**（day2 32 / day3 16 / day4 21 / day5 16 / day6 14 / day7 13 / day8 19 / day10 20 / day11_12 22 / day13 36 / day14_15 51）+ day16（若已收口）+ `gen_weapons_day7.py verify` 36/36
- [ ] git commit 收口（**勿夹带** docs/pindou/、scripts/ui/*.bak、tools/pixel_to_pindou.py、docs/LOOP_HEALTH.md —— 各自动化/第三方自主提交）
- [ ] 主观项登记：精英战手感 / 难度体感 / 精英视觉辨识度 → PLAYTEST_CHECKLIST.md（#5 收口），不阻塞出口

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
