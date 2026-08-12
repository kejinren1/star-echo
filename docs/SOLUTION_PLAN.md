# 方案计划（2026-08-12 · 第 19 轮）

## 当前开发日：阶段 F 技术债整改（F2 代码边界收拢）

> **本轮性质：F2 正式方案轮**（#2 第 44 轮 07:2x 函数级拆解 F2 T0~T6+EXIT 批次 A/B/C → 方案师第 19 轮定案）。
> 触发：F1-C 已收口（`486bbb1`）→ 第 43 轮「F1 仅剩 F1-G-尾/F1-E → 下一轮可启动 F2」条件满足 → #2 第 44 轮拆 F2。
> 红线全程遵守：不写码 / 不改 .gd/.tscn/.tres/.json / 不 commit / 不跑探针；产出仅 SOLUTION_PLAN.md + TASKS 标注 + 记忆文件。

---

## 0) P0 调度硬性输入检查（读 PLAYTEST 追踪区头部 · 本轮实测 08:00）

- ✅ **增量 #62（08-12 00:5x · 反馈专员：无待处理反馈轮）= 无新机器可验证 P0**：F1-C 护甲口径挂起项机器侧收口确认（TEST_REPORT #43 = 34/34 · 830 断言全绿首跑，runner 并入 day29_elin 14 + day29_attack 20 + day30_f1_scaling 14；`486bbb1` F1-C 收口；主观行判断「纯数值口径统一不新增噪音行」）——主观项交 #5，无机器侧缺口。
- 🟠 **无新增用户拍板调度指令**；🟢 **美术资源策略（08-07 拍板）遵守**（F2 纯代码层零美术生成）。
- ⏳ **顺延项 5 条 P1 挂账不阻塞**：F-11 接口偏差 / vfx_container / 遗物 HUD 槽 / 空间音 / mech_heart 入池；R4 攻击力口径挂账第 34 轮维持。
- 📋 **F1-G-尾 阻塞实测（本轮确认）**：`docs/~$GameData.xlsx` 锁文件**仍在盘**（165B，mtime 08-11 21:07 = WPS/et.exe 占用持续）→ **F1-G-尾 维持阻塞**，方案同第 18 轮（3 键行号 bait row 43 / anvil row 82 / mech_heart row 111 + 删行脚本已备好，待用户关闭 WPS 后 #3 下轮执行）。
- 📋 **G 系列框架拓展**：FRAMEWORK_EXPANSION.md（08-12 用户拍板 R1-R6）已立**待 #2 拆解**（下轮评估粒度），本轮方案师仅登记不拆（硬性工作流：规格→拆解→执行）。

---

## 1) 任务方案（F2 区 · TASKS:2369-2380 · 本轮核心产出）

> **F2 全局口径（#2 第 44 轮已定 + 方案师核验）**：
> - 批次：**A = T0+T3+T4**（容器/工厂基建，独立先做）→ **B = T1+T2**（GM 状态信号 + UI 直读收口）→ **C = T5+T6+EXIT**（系统信号化 + GM 首拆 + 探针收口）。每批次一收口 commit 带 T 编号。
> - **F2 纯代码层改动零数值，不涉 Excel**（数据管线铁律不触发）；验收 = 依赖图无 UI→核心字段直读 / 无 get_parent() 跨层链 / 无直接 new 实体 + 探针全绿。
> - 回归基准：**34 项/830 断言**（`python tools/_regression_run.py`），落地后 + day30_f2_boundary_check ≥18 = **35 项 ≥848 断言**。

### 任务 F2-T0 基建：world.gd 容器服务【✅ 方案已定 · 批次 A 首步】

- **落地合理性**：三处 `_find_container`（weapon_controller.gd:40-46 / turret.gd:145-152 / skill_controller.gd:254-261）注释已写明「World/Projectiles 优先，回退 World」——**Projectiles 容器实测不存在，全部回退 World** = 弹丸实际直挂 World 下。建容器后三处**行为真实变化**（弹丸挂 World/Projectiles），属预期收口而非回归；但**弹丸命中/清理/clear 逻辑敏感**，批次 A commit 前必须跑回归全套。
- **实现方式**：新建 `scripts/world/world.gd`（挂 scenes/Main.tscn :16 World 节点）——`CONTAINER_MAP := {"projectiles": "Projectiles", "enemies": "Enemies", "vfx": "VfxContainer"}` + `get_container(key)`（get_node_or_null + 未知 key push_warning）+ `_ready()` 预创建 Projectiles 容器 + 工厂 `spawn_projectile(scene, weapon_data, aim_dir, owner)` / `spawn_turret(weapon_data, duration, player)` / `spawn_minion(scene)`（**工厂仅 instantiate + 挂载正确容器 + setup 透传；位置/朝向/初始化细节留消费点，防工厂上帝化**）；GameManager 新增 `var world: Node` + `get_world()`（main._ready 注入，仿 `enemies_container` 先例——enemy 挂 Enemies 容器下 get_parent()≠World，拿 world 的唯一途径）。⚠️ **新建 class_name/脚本挂载后必须重建 `.godot/global_script_class_cache.cfg`**（headless --editor --quit-after 120 扫描，记忆坑）。
- **风险评估**：**中**——行为变化集中在弹丸容器归属；回归敏感点 = 弹丸命中（_on_body_entered 依赖 parent 树?实测无）、clear 逻辑（若遍历 World 子节点清弹丸则漏 World/Projectiles 下的）、day23_vfx `current_fx` 观测字段、day10/day13 弹丸断言。**替代方案**：若回归出现大面积红 → 降级为「仅创建容器 + 三处 _find_container 改 get_container，工厂延迟到 T4」分两步走。
- **验证方式**：回归 34 项全绿 + day30_f2_boundary_check §3（get_container("projectiles") 返回真实节点 / spawn_projectile 生成弹丸挂 Projectiles 下 / spawn_turret 挂 World 下）。

### 任务 F2-T1 GM 状态信号化（T-031 铺路）【✅ 方案已定 · 批次 B】

- **落地合理性**：8 处 `current_state = ` 直接赋值（:118/144/165/202/246/357/574/592）分散 = F3 状态机规范化前置；信号化后 UI/系统可订阅状态变更，消除轮询。纯重构零行为变化（_set_state 同值早退保持幂等）。
- **实现方式**：game_manager.gd 新增 `signal state_changed(state: int, context: Dictionary)` + `func _set_state(next: int)`（同值早退 → 赋值 → emit state_changed(next, {})，context 预留 F3 正交维度）；8 处赋值收口。⚠️ 注意 :574/:592 两处若在 end_game/reset 流程内，早退语义与原直接赋值一致（同值跳过 emit 不影响逻辑）。
- **风险评估**：**低**——纯赋值点收敛；唯一注意 = 现有代码若在赋值后依赖「立即读取已更新值」仍成立（_set_state 内先赋值后 emit，同步语义不变）。
- **验证方式**：grep `current_state = ` 仅 _set_state 内 1 处 + 白盒驱动 MENU→BATTLE 断言 state_changed 信号值/次数（并入 day30_f2 §2）。

### 任务 F2-T2 UI 直读收口（T-037~041）【✅ 方案已定 · 批次 B】

- **落地合理性**：5 处 UI/横切层直读核心字段 = 边界原则 §2.5 违规（TECH_DEBT_PLAN §1.3 已登记：shop.gd:346 economy.coins / :384 手动回滚 / hud.gd:129 轮询敌人容器 / base_station.gd:141 直读存档字典）；逐一收口为查询接口。**⚠️ shop.gd 购买回滚段（:393-396）是 F-16 修复过的关键路径**，改动须保持行为逐字节等价。
- **实现方式**：① economy.gd `can_afford(price) -> bool`，shop.gd:356 改调 ② player.gd `get_weapon_controller() -> Node`，shop.gd:369/:390 改调 ③ inventory.gd `get_weapons()/get_items() -> Array`（**浅拷贝防外部改内部数组**）+ `remove_last_weapon() -> bool`（pop_back + emit weapon_removed），shop.gd:393-396 回滚段改调 ④ hud.gd:290 直读改 get_weapons/get_items；:121-133/164-168 轮询敌人容器 → `GameManager.get_alive_enemy_count()`（GM 新增查询：优先 wave_manager `_alive_enemy_count`，spawner.get_alive_count 兜底）⑤ base_station.gd:141/:144 → `GameManager.get_research_points()/get_research_level(key)`。
- **⚠️ 决策点（方案师补充）**：F-06 轮询改信号（wave_manager `enemy_count_changed` 信号 + register_kill :156 emit）为**推荐增强项**——**建议本轮不并入批次 B**（hud 改查询接口已满足收口目标；信号化扩大改动面 + 需 HUD 重接线，留 F3 状态机轮与状态信号统一做），#3 按「查询接口」口径执行即可，EnemyCountLabel 轮询保留。
- **风险评估**：**中**——涉及购买流程（F-16 关键路径）与 HUD 显示链路；浅拷贝必须（防 get_weapons 暴露内部数组被外部改坏）；base_station 查询接口改动影响 day27_meta 探针（若探针直读 meta_progress 需核验——实测 day27_meta 用独立临时档走 GM 接口，受影响面小）。
- **验证方式**：回归 34 项全绿 + day30_f2 §1 静态 grep（shop/hud/base_station 无 `economy.coins`·`inventory.get("weapons")`·`meta_progress.get` 直读）+ §2 行为（can_afford 边界 + 查询接口返回值）。

### 任务 F2-T3 跨层容器访问收口（T-043）【✅ 方案已定 · 批次 A】

- **落地合理性**：三处 `_find_container` 复制粘贴 = 消灭重复；T0 提供 get_container 后收口。⚠️ **行为变化确认**：弹丸容器 World → World/Projectiles（_find_container 注释已表明「优先 World/Projectiles」——此前容器不存在才回退 World，建容器后行为即为注释语义）。
- **实现方式**：weapon_controller.gd:41-46 / skill_controller.gd:256-261 / turret.gd:147-152 三处 `_find_container` 改 `world.get_container("projectiles")`（不再回退 World；**null 守卫保留**——get_container 未知 key 返回 null，消费点判空防崩）。
- **风险评估**：**中**（同 T0 行为变化风险）——**批次 A commit 前必须跑回归全套**（弹丸命中/清理/clear 逻辑敏感）；turret 弹丸（:103 container 获取）与 skill 火球同受影响。
- **验证方式**：回归 34 项全绿 + day30_f2 §3（弹丸挂载位置断言）。

### 任务 F2-T4 实体创建收口（T-044）【✅ 方案已定 · 批次 A】

- **落地合理性**：直接 instantiate 点 = 实体创建散落 5 处 → world 工厂统一；工厂仅 instantiate + 挂载 + setup 透传（**位置/朝向/初始化细节留消费点**，防工厂上帝化——skill 火球有 skill_data 初始化（pierce/暴击 meta 透传）、炮台有 duration/owner 语义，细节不能进工厂）。
- **实现方式**：weapon_controller.gd:318 弹丸 → `world.spawn_projectile`；skill_controller.gd:118 火球 + :181-185 炮台 → spawn_projectile/spawn_turret（:134/:185 add_child 移除）；enemy.gd:560/:699 Boss 召唤物 → `GameManager.get_world().spawn_minion(...)`（enemy 无 World 父级，经 GM 途径——**GM.world 为 null 时（非战斗环境/探针白盒）判空兜底，保持旧路径或跳过**）。
- **风险评估**：**中**——Boss 召唤物（:560/:699）与 day18_19 探针弹丸/召唤断言相关，判空兜底必须（探针环境可能无 world）；skill 火球 pierce/暴击 meta 透传保持（:102 注释「对齐 weapon_controller._spawn_projectile 口径」）。
- **验证方式**：回归 34 项全绿 + day30_f2 §3（spawn_projectile/spawn_turret 挂载位置）。

### 任务 F2-T5 系统间信号化（T-042/045）【✅ 方案已定 · 批次 C】

- **落地合理性**：wave_manager `_spawning_incomplete()` 用 `get("_is_spawning")`/`get("spawn_queue")` 私有字段动态访问（F-30 补丁引入）= 隐性耦合 → spawner 显式接口；enemy→GM 的 boss_killed / died 信号化 = F3 状态机信号底座。**⚠️ 信号链装配改变事件流时序**，main.gd 装配点（enemy_spawned → died → wave_manager；boss_killed → GM）须在 _ready 完成，避免漏接导致通关判定失效（F-28/F-30 回归面）。
- **实现方式**：① enemy_spawner.gd `is_spawning() -> bool` / `has_pending_spawns() -> bool`；wave_manager.gd:96-100 改用接口 ② enemy.gd:782 register_boss_killed → 新增 `signal boss_killed`（die 内 is_boss emit）+ GM 订阅（main.gd 装配）③ enemy.gd:785 check_wave_clear 已 emit `died` → wave_manager 订阅 died 内部响应（main.gd 装配）④ **保留项（注明不拆）**：enemy:795-796 add_coins/gain_exp + player:470 debug_cheat = 实体→系统向下依赖（§2.5 允许）。
- **风险评估**：**中**——信号链时序（同帧 emit/订阅顺序）；day18_feedback6（F-30 通关判定 10 断言）/ day18_19（boss_killed 48 断言）/ day24_f13（on_kill）三探针直接覆盖此链路，红=装配漏接立即暴露。**替代方案**：若 died 订阅改造引入 flaky → 降级为「仅新增信号 + main 装配，wave_manager 内部响应逻辑保持原 check_wave_clear 调用点」。
- **验证方式**：回归 34 项全绿 + day30_f2 §4（enemy died → wave_manager check_wave_clear 通关判定 / boss_killed → GM route.flags boss_defeated 登记）。

### 任务 F2-T6 GameManager 首拆（T-046）【✅ 方案已定 · 批次 C · ⚠️ 探针兼容约束为关键决策】

- **落地合理性**：GM 754 行四合一（状态机+存档+面板工厂+事件系统）→ 首拆面板工厂 + 事件系统，目标 ≈450 行；存档留 F4。**行为零改动硬要求**（防回归）。
- **⚠️ 方案师关键实测（探针兼容约束，供 #3 免排查）**：`tools/day16_event_check.gd` 探针**直接 `_gm.call("_apply_event_reward", ...)` / `_gm.call("_apply_route_effect", ...)` 白盒调用**（:238-285 十型 reward / :322-355 五型改线）+ **:109 直接 `_gm._event_rng.seed = 12345` 固定随机序列** → **拆分后 GM 必须保留同名薄委托方法**（`_apply_event_reward` / `_apply_route_effect` / `_start_event` / `resolve_event_choice` / `_apply_event_item` / `_apply_event_weapon_upgrade` / `_apply_reroute` / `_apply_unlock_node` / `_apply_add_node` / `_build_event_item` 全量转发 EventManager）+ **`_event_rng` 属性必须可经 GM 访问**（方案：EventManager 持 rng，GM 保留 `var _event_rng` getter 转发 → 探针零改动；**若直接迁走 `_event_rng`，day16 探针必红**）。
- **实现方式**：① 新建 `scripts/ui/ui_panel_factory.gd`：迁移 `_spawn_game_over_panel`（:631-650）/`_add_to_ui_layer`（:651-657）→ `UIPanelFactory.spawn_game_over_panel(ui_layer, victory)`，GM end_game 薄委托 ② 新建 `scripts/systems/event_manager.gd`：迁移事件段 :367-571（≈200 行 + _event_rng），GM 保留入口薄委托（事件流经 GM 状态机，F3 状态收口时接口稳定）③ 拆分后回归 34 项全绿（day16 41 断言 + day24_f13 17 + day27_meta 35 直接覆盖事件域）。
- **风险评估**：**中**（GM 为全局流程核心，但薄委托方案 + 探针兼容约束已把风险收敛为「转发遗漏」类）——**高风险点 = 薄委托遗漏任一方法名 → day16 探针红**；new class_name 脚本需重建 global_script_class_cache。
- **验证方式**：回归 34 项全绿（重点 day16_event_check 41/41）+ day30_f2 §1 静态 grep + GM 行数实测 ≈754→450（可选断言）。

### 任务 F2-EXIT 探针 + 回归收口【✅ 方案已定 · 批次 C 尾】

- **实现方式**：新建 `tools/day30_f2_boundary_check.gd` **≥18 断言四段**——§1 静态 grep（`get_parent().get_node_or_null` 零残留 / `.instantiate()` 仅 world.gd 工厂内 / shop·hud·base_station 无 `economy.coins`·`inventory.get("weapons")`·`meta_progress.get` 直读 / `current_state = ` 仅 _set_state 内）；§2 行为（state_changed 信号值/次数 + can_afford 边界 + 查询接口返回）；§3 容器/工厂（get_container 真实节点 + spawn_projectile 挂 Projectiles / spawn_turret 挂 World）；§4 信号链（enemy died → check_wave_clear；boss_killed → route.flags boss_defeated）——回归 **34 项 830 断言 + day30_f2 ≥18 + BASELINE CLEAN**。
- **⚠️ grep 口径注意（方案师补充）**：§1 静态 grep **禁止**把 `GameManager.enemies_container.get_children()` 类容器遍历列入禁止项——projectile.gd:120/:208/:212 / player.gd:578 / turret.gd:88-92 / orbit_weapon.gd:105-108 / weapon_controller.gd:262-281 的敌人容器遍历是 F-19 合法范式（实体→实体遍历，非 UI→核心直读），**F2 不扩大化**；grep 目标仅限 UI 层（shop/hud/base_station）。
- **验证方式**：`python tools/_regression_run.py` 35 项 ≥848 断言全绿 + baseline CLEAN。

---

## 2) 风险与观察点（供 #3/#4/#5/#1/主窗口参考）

| # | 观察点 | 归属 | 状态 |
|---|--------|------|------|
| 1 | **F2 批次 A（T0+T3+T4）行为变化**：弹丸容器 World → World/Projectiles | #3 | ⚠️ 批次 A commit 前必须回归全套 34 项（弹丸命中/清理/clear 敏感）；红则降级两步行（先容器后工厂） |
| 2 | **F2-T6 探针兼容约束**：GM 保留同名薄委托 + `_event_rng` getter 转发（day16 探针 :109 直设 seed） | #3 | 🔴 遗漏任一方法名 → day16 41 断言红 |
| 3 | **F2-T2 购买回滚段**（shop.gd:393-396）= F-16 关键路径 | #3 | ⚠️ 行为逐字节等价；浅拷贝必须（get_weapons/get_items） |
| 4 | **F2-T5 信号链装配**：main._ready 完成 enemy_spawned→died→wave_manager / boss_killed→GM | #3 | ⚠️ 漏接 → day18_feedback6(10)/day18_19(48)/day24_f13(17) 三探针立即红 |
| 5 | **F1-G-尾 阻塞持续**：`~$GameData.xlsx` 锁在盘（et.exe）→ 3 键删数据无法执行 | 用户/主窗口 | 🔴 待用户关闭 WPS；删行脚本已备好（bait row 43 / anvil row 82 / mech_heart row 111） |
| 6 | **F1 剩余散条目**（T-007/008/009/011/012/013/015/053 数值参数化） | #2 待拆 | ⏳ 建议 F2 收口后作为 F1-尾 单批拆解（纯数值，与 F2 纯代码不混批） |
| 7 | **G 系列框架拓展**（FRAMEWORK_EXPANSION.md R1-R6） | #2 待拆 | ⏳ 下轮评估拆解粒度（08-12 教训：规格→拆解→执行） |
| 8 | F1-E 表现抽表大改 | 主窗口 | 🏠 #3 勿自行开工，轮次标注「F1-E 主窗口承接」 |
| 9 | F-35 主观回归面 ②（F1-G 接线 5 键生效感）+ F1-C 护甲 | #5 真人 | 🟡 待真人回归 |
| 10 | 工作区在途 = docs 4 M + tools 3 M（Excel 管线）+ FRAMEWORK_EXPANSION.md / art_ai / perfect-pixels / 用户素材 xlsx / `~$GameData.xlsx` 锁 | #2/#3 | ⏳ 零游戏代码在途；#3 动 data/*.json 前 git status 确认 |

---

## 3) 展望（后续窗口）

- **阶段 F 当前批（#3 下一执行窗口）**：按批次 A → B → C 执行 F2（每批次一收口 commit 带 T 编号）；**F1-G-尾 若用户已关 WPS 则优先执行**（3 键删数据 → excel_export → 回归 → T-050 收口）；F1-E 维持主窗口承接。
- **F2 收口后**：F1-尾 散条目（T-007/008/009/011/012/013/015/053 数值参数化）单批拆解 → F3 状态机规范化（F2 信号底座已铺好）。
- **G 系列**：FRAMEWORK_EXPANSION.md 规格书待 #2 拆解（R1-R6 + 优先级 + 数据结构），方案师定案。
- **红线遵守**：不写码 / 不改 .gd/.tscn/.tres/.json / 不 commit / 不跑探针；产出仅 SOLUTION_PLAN.md + TASKS 标注 + 记忆文件。

---

## 阶段 F 技术债整改方案（供 #3 执行岗接手 · 本文件权威版本，单份）

> 总方案/决策记录：docs/TECH_DEBT_PLAN.md（§7 决策表 · §8 状态机选型 · §8.6 能力上限清单）
> 债清单：docs/TECH_DEBT_ISSUES.md（T-001~T-053 逐条状态）
> **数据管线铁律**：改数只改 docs/GameData.xlsx → `python tools/excel_export.py`（校验不过禁止提交）→ 探针；data/*.json 为 generated 禁手改。
> **探针套件**：`python tools/_regression_run.py`（当前 **34 项/830 断言**，F2 落地后 **35 项 ≥848**）；数值基线 `tools/baseline_numerics.json`（F4 拆分后对比防漂移）。

### 已完成（无需再执行）
- F0 基线冻结 + 2 P0 bug 修复（f0-baseline / 42871c9）
- F1.0 Excel 管线全链（f1-excel-pipeline / 9c1440e）
- F1-A enemies.scaling 参数化（T-001/002）、F1-B waves.generation + routes.boss_wave（T-003/014），day30_f1_scaling_check.gd 10 断言（438295d）
- F1-D 商店参数数据化（b6e0177，day30_f1d_shop_check 8/8）、F1-F 机制 id 收敛（162fa52，grep 零残留）、F1-G 主键裁决（112e6a9，22/22）
- F1-C 护甲公式统一（486bbb1，day30_f1_scaling §4 10→14 断言）

### 任务 F1-G-尾 删数据 3 键落 Excel（T-050 收尾）【✅ 方案已定 · ⚠️ WPS 占用阻塞 · 待用户关闭后执行 · 见 §1 第 18 轮详情】
- **3 键**：`no_weapon_armor_bonus`（anvil）/ `special_enemies_next_wave`（bait）/ `auto_turret_per_wave`（mech_heart）——scripts/ 零机制消费（仅 desc_builder 中文映射 3 处本轮不删）；只删键不删条目
- **操作**：GameData.xlsx items_effects 子表删 3 行（bait row 43 / anvil row 82 / mech_heart row 111）→ excel_export.py --check-only → 导出 items.json → 回归 34 项全绿 → T-050 已收口 → F1-G 行整体转 [x]
- **风险**：低——CONSUMED_BONUS_KEYS 白名单不含 3 键零改动；**阻塞源 = WPS 锁文件仍在盘（08-12 08:00 实测）**

### 任务 F1-E 表现配置抽表（T-016~024）【大改 · 主窗口优先承接，执行者勿自行开工】
- **内容**：enemy.gd SPRITE_MAP(26 条)/FALLBACK_SPRITES/BEHAVIOR_MAP、audio_manager BGM_MAP/SFX_MAP、vfx_player FX_CONFIG、icon_atlas SHEET_CONFIG、hud SKILL_ICON_MAP、weapon_controller 初始枪、turret 默认值 → **新建 Excel presentation sheet** + 各脚本改 DataLoader 读取（**保留代码兜底默认值**）
- **规模**：涉及 7+ 脚本 + 新数据表，与图标/精灵资产耦合 → 主窗口分步执行并逐脚本验证；#3 标注「F1-E 主窗口承接」勿自行开工

### 任务 F2 代码边界收拢（T-037~046）【✅ 第 19 轮方案已定 · 批次 A/B/C 待 #3 执行 · 见 §1 详情】
- **批次 A = T0+T3+T4**（world.gd 容器服务 + 三处 _find_container 收口 + 实体创建工厂化）——⚠️ 弹丸容器行为变化，commit 前回归全套
- **批次 B = T1+T2**（GM state_changed 信号化 + UI 直读收口 5 处）——T2 购买回滚段行为等价 + 浅拷贝
- **批次 C = T5+T6+EXIT**（spawner 接口 + boss_killed/died 信号链 + GM 首拆面板工厂/事件系统 + day30_f2_boundary_check ≥18 断言）——⚠️ GM 保留同名薄委托 + _event_rng getter（day16 探针兼容）
- **验收（§4）**：依赖图无 UI→核心字段直读 / 无 get_parent() 跨层链 / 无直接 new 实体；回归 35 项 ≥848 + BASELINE CLEAN

### 任务 F3 状态机规范化（T-031~036）【待 F2 后拆解】
- 范式已定（TECH_DEBT_PLAN §8.5/8.6）：**仅两种形态**——① 扁平流程态 enum+match+`_transition()`；② 行为/表现态 enum+状态表。禁多 bool/字符串状态/int 字面量/散落赋值
- 交付含：状态机合规探针（扫描代码）+ 状态流探针（固定序列断言流转）

### 任务 F4/F5【概要】F4 拆分 GM/enemy/player 上帝脚本（<400 行 + 数值快照零漂移）；F5 全量回归 + CODE_STYLE.md + DATA_DICT_GUIDE.md（策划改数手册）

### 执行者交接说明
- **#3 当前批 = F2 批次 A/B/C**（每批次一收口 commit 带 T 编号）；**F1-G-尾 阻塞解除后（用户关 WPS）优先执行**
- 主窗口承接 F1-E（表现抽表大改）；G 系列规格书待 #2 拆解
- 冲突规避：动 data/*.json 前先 `git status` 确认无他人未提交改动；改 Excel 前同样检查（`~$GameData.xlsx` 锁文件在盘时确认无打开实例）
- 每任务完成后在 TASKS.md 阶段 F 区标记 [x] + TECH_DEBT_ISSUES.md 对应条目状态 → 已收口

---

## 执行结果（#3 第 44 轮登记 · 2026-08-11 08:3x · 阶段 F 收尾轮 · 部分完成：F1-C ✅ + F1-G-尾 ⛔ 阻塞 + runner 34 项 · 保留归档）

- **输入核验**：方案第 18 轮（F1-C 阻塞解除 + F1-G-尾 新拆 + F1-E 主窗口承接）；P0 检查 = 增量 #61 无新机器可验证 P0。git HEAD=`39e08a5` → 检查点 `b2aad23`。
- **F1-C ✅ 收口（`486bbb1`）**：enemy.gd :761-763 百分比公式 → 平直减法 `max(amount - armor, 1.0)`（与 player.gd :466 同式；玩家零改动）；stats.formulas 死公式 T-006 登记作废；day30_f1_scaling_check +§4（10→14 断言）；回归 34/34（830）全绿。
- **F1-G-尾 ⛔ 执行阻塞（WPS 占用 Excel）**：GameData.xlsx 被 WPS 表格进程（et.exe 23860）打开（锁在盘）→ openpyxl 删行 save 报 PermissionError（磁盘零改动）→ 按方案风险表不强行写入，T-050 阻塞登记，**待用户关闭 WPS 后执行**（3 键行号 bait row 43 / anvil row 82 / mech_heart row 111，删行脚本已备好）。
- **runner 34 项 ✅**：PROBES +day29_elin(14) + day29_attack(20) + day30_f1_scaling 14 → 34 项/830 断言。
- **F1-E 🏠 主窗口承接**（未开工）。回归 34/34 全绿（830 断言）。

---

## 执行结果（#3 第 45 轮登记 · 2026-08-12 08:4x · 阶段 F F2 全批收口 · 完成）

- **输入核验**：方案第 19 轮（F2 正式方案批次 A/B/C）；P0 检查 = 增量 #62 无新机器可验证 P0。git HEAD=`2457f51`。
- **F1-G-尾 ⛔ 维持阻塞**：`docs/~$GameData.xlsx` 锁文件仍在盘（WPS et.exe 占用持续，08-12 08:20 实测）→ 3 键删数据（bait row 43 / anvil row 82 / mech_heart row 111）本轮不执行，T-050 维持阻塞登记，**待用户关闭 WPS 后下轮执行**。
- **F2 批次 A ✅（`10c4a37` T0+T3+T4）**：新建 world.gd 容器服务（CONTAINER_MAP + get_container + _ready 预创建 Projectiles + spawn_projectile/spawn_turret/spawn_minion 工厂——initialize 先于 add_child 时序铁律）+ GM world 引用/get_world（is_instance_valid 防悬空）+ main 注入 + 三处 _find_container 收口 + 5 处直接 instantiate 工厂化（enemy 两处 Boss 召唤经 GM 判空兜底）。🕳️ 回归 29/34 → 探针场景 Main 释放后 world 悬空 → 全消费点加 is_instance_valid 修复 → 34/34。
- **F2 批次 B ✅（`d38f00f` T1+T2）**：_set_state 8 处赋值收口（同值早退幂等；⚠️ 执行偏差：现有 signal state_changed(new_state: GameState) 单参已被 hud 消费 → 保留签名不改双参，信号化目标达成）+ economy.can_afford/get_coins + player.get_weapon_controller + inventory.get_weapons/get_items（浅拷贝）/remove_last_weapon + GM.get_alive_enemy_count/get_research_points/get_research_level + shop 购买回滚段（F-16 关键路径）行为等价改造 + hud/base_station 查询接口。⚠️ 执行偏差：get_alive_enemy_count 兜底 spawner.get_alive_count 实测 child_count 不判存活（day18_feedback F-06 递减断言暴露）→ 改容器遍历 is_alive 语义，get_alive_count 留最后兜底。F-06 轮询改信号按方案建议不并入（查询接口已满足收口目标）。
- **F2 批次 C ✅（`a9ebe49` T5+T6+EXIT）**：enemy_spawner is_spawning/has_pending_spawns 显式接口（wave_manager._spawning_incomplete 改调，消灭私有字段动态访问）+ enemy boss_killed 信号化（die 内 is_boss emit，main 装配 GM 订阅；day18_19 探针 :404 适配装配）+ GM 首拆：ui_panel_factory.gd（GameOver 面板 + add_to_ui_layer 静态）/ event_manager.gd（事件段 10 方法 + _event_rng 迁移；GM 保留同名薄委托 + _event_rng getter 转发——day16 探针 :109 兼容零改动）+ GM 783→634 行（存档留 F4）。⚠️ 执行偏差：T5 ③ died→wave_manager 订阅按方案替代方案执行（check_wave_clear 原调用点保留，仅 boss_killed 信号化——避免探针/时序 flaky）。
- **EXIT ✅**：day30_f2_boundary_check.gd **36 断言四段**（§1 静态 grep 全过 / §2 行为 / §3 容器工厂 / §4 信号链）+ runner 34→**35 项 / 866 断言**（day26 §6 锚点 830→866 同步）+ **BASELINE CLEAN** + TASKS F2-T0~T6+EXIT 全 [x] + TECH_DEBT_ISSUES T-037~046 全「已收口」。
- **F1-E 🏠 主窗口承接**（未开工，维持）。**F3 状态机规范化 / G 系列框架拓展**：待 #2 拆解（F2 信号底座已铺好）。
- **执行偏差汇总（方案第 19 轮）**：① T1 双参 signal 改单参保留（hud 消费者兼容）② T2 兜底 get_alive_count 语义修正 ③ T4 工厂签名带 setup 透传（initialize props 字典，保时序）④ T5 ③ 按替代方案 ⑤ T2 grep 口径补 get_coins（方案遗漏 shop :128/:362 两处 coins 直读）。
