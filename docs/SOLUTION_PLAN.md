# 方案计划（2026-08-07 · 方案师自动化轮 · 首轮）

> 角色：**方案师（Solution Architect）** —— 只定方案，不写代码、不改游戏文件、不 commit、不跑探针。
> 本文件为 **Day 18-19（Boss 多阶段）** 的完整落地方案，执行者（RS-方案执行）按本方案实现。
> 红线遵守声明：本轮仅产出本文件 + TASKS.md 标注，零游戏代码/数据改动（git 工作区零变更可核）。

---

## 〇、P0 调度硬性输入检查（步骤 0 产出）

**读 docs/PLAYTEST_CHECKLIST.md「未解决问题追踪区」头部（增量 #28 · 2026-08-07 12:0x）：**

- ✅ **P0 四件套（F-01/F-02/F-04/F-15）** 已于 2026-08-06 22:5x 全部落地（`6e84751`+`1bc0255`，day17_p0 20/20），**机器侧闭环**；P1 四修复（P1-1~P1-4）同于 00:30 收口（回归 8/8 全绿）。
- ✅ **#4 输出延迟观察已解除**（TEST_REPORT #24 轮 12:15 已写入）。
- ⏳ 剩余开放项 = **真人回归**（P0 围杀 / P1 四修复 / 阶段 C 三合一完整局）—— 纯主观项，归属 #5 试玩专员，**不构成本轮机器可验证 P0**。
- 🔴 上下文：**#3 执行者连续第 7 个执行窗口零产出，「自动化疑似故障交 Owner」判定维持（第 23 轮裁决）**；Day 18-19 挂账 🔴🔴；#2 第 25 轮（13:0x）确认 **目标日 = Day 18-19（Boss 多阶段）**、D18-19 全任务 `[ ]` 未开始、批次 A/B/C 重排有效。

**结论：无新机器可验证 P0 需纳入本方案**；本方案对「Owner 修复 #3 后从批次 A 直接执行」保持完全就绪。

---

## 一、目标日任务清单（docs/TASKS.md Day 18-19 区 · 全部 [ ]）

| 任务 | 内容 | 批次 |
|---|---|---|
| D18-19-PRE | 定案表 9 条（方案基线，本方案逐条落实） | — |
| D18-19-T1 | enemy.gd Boss phases 状态机（阶段切换） | B |
| D18-19-T2 | attacks 指令解析（纯函数）+ 行为执行器 | A(解析) / B(执行器) |
| D18-19-T3 | 新建 `scripts/enemy/enemy_projectile.gd`（敌人弹幕） | A |
| D18-19-T4 | GameManager Boss 接入 + boss_killed 登记 | C |
| D18-19-T5 | 新建 `tools/day18_19_boss_check.gd`（五段 ≥20 断言） | C |
| D18-19-EXIT | baseline + 回归十三件套 + 收口 commit + 主观项登记 | C |

**执行顺序（#1 最终裁决批次 A/B/C 保持，任一批次完成即 commit 勿等全量）：**
- **批次 A**：T3（enemy_projectile.gd，纯新建零依赖）+ T2 的 `_parse_attack` 纯函数段 → 局部 commit
- **批次 B**：T1（phases 状态机）+ T2 执行器段 → 局部 commit
- **批次 C**：T4 + T5 + 回归 + baseline + 收口 commit

---

## 二、实测基线（方案师本轮磁盘核实 · 供执行者免排查）

> ⚠️ **TASKS 中 D18-19 旧行号（take_damage :364-374 等）是 D17 精英能力落地前测得，已过时**；以下为 2026-08-07 13:5x 实测现行行号。

**scripts/enemy/enemy.gd（现行）：**
- 属性区 `:103-132`（新增 Boss 状态变量建议插在 `:132 _ability_timer` 之后新增「# Boss 阶段」块）
- `_physics_process` `:141`（`:148` 调 `_update_behavior`）
- `_try_contact_damage` `:155-162`（`:161 target.take_damage(damage)` = 冲锋命中倍率守卫点）
- `_update_behavior` `:268-293`（Boss 分支插在 `:270` 目标校验之后、`match behavior:` 之前）
- `_move_charge` `:302-320`（**F-15 已定型倍率 1.5，本日只复用、不改移动倍率**）
- `_elite_spawn` `:414-451`（D17 召唤范式：容器解析 `:425-432` / 场景 `:433-440` / 循环 `:441-450` —— `_boss_summon` 仿此）
- `take_damage` `:463-473`（相位切换插入点）
- `die` `:476-487`（`:481 died.emit(self)` 后插 register_boss_killed）
- `initialize` `:521-553`（`:547-551` category match 置 is_boss；phases 初始化插 `:551` 后、`:552 health = max_health` 前）

**scripts/autoload/game_manager.gd：**
- `_enter_node` `:199-218`（`"battle","elite","boss"` 分支 `:201`；elite 横幅判断 `:206-207` → boss 分支插旁）
- `_show_elite_banner` `:222-241`（横幅范式：Node2D+Label+1.5s 淡出 tween，容器缺失静默）
- `reset` `:514-533`（`:519 difficulty_delta = 0` 附近加 `boss_killed = 0`）
- `route["flags"]` 范式 `:431-432`（`route["flags"] = route.get("flags", {})` 再写键）

**容器拓扑（关键）：**
- `Main.tscn`：`World/Enemies`（`:23`）+ `World/VfxContainer`（`:25`）；main.gd 接线 `:9-10/:52/:54`
- ⚠️ **`enemy_spawner.get_alive_count()`（:172-175）= `enemies_container.get_child_count()`** → **敌人弹丸绝对不可入 Enemies 容器**（会污染波次清空判定）

**数据（data/enemies.json `:272-336` 实测，零改动）：**
- `invoker`（wave 10，hp 8000/dmg 15/speed 200/exp 400）：P1(100%)=`summon_2_enemies_every_5s`+`3_projectile_spread`·×1.0；P2(60%)=`summon_4_enemies_every_2.5s`+`6_projectile_spread`·×1.2
- `predator`（wave 20，hp 15000/dmg 20/speed 300/exp 500）：P1(100%)=`charge_attack`+`aoe_every_8s`·×1.0；P2(66%)=`charge_attack_2x`+`summon_1_elite`+`projectile_barrage`·×1.0；P3(33%)=`all_attacks_2x`+`summon_2_elite`·×1.3
- 8 型指令与 `_parse_attack` 定案表一一对应，**未知指令 = 0**；无藤蔓/毒雨（以数据为准，PRE #8）
- `get_scaled_enemy`（data_loader.gd `:172-216`）恒返回 `phases` 键（`:212`，默认 []）；`get_enemy_ids_by_category` `:222`（regular 15 / elite 6 池）

**其它：**
- 玩家弹丸范式 `scripts/weapons/projectile.gd`：`_make_bullet_texture` `:144-158`（运行时圆形弹体）、`set_direction` `:161-163`、`initialize` `:166+`；`:110` VfxPlayer.spawn(vfx_container, pos, "crit")
- VfxPlayer（`class_name` 全局）FX_CONFIG（vfx_player.gd `:16-22`）：**hit / crit / death / levelup / pickup** 五个特效名齐备；静态 `spawn(parent, pos, fx_name)` `:57`
- 玩家 `player.gd`：`take_damage` `:281` / `heal` `:305` / `debug_mult` `:33`
- 波次锚点：**路线模式终局 Boss = invoker，wave_index = 10**（`999a1bd` Fix-2 后口径，探针勿写 20）；predator（wave 20）仅旧波次制出场——两 Boss 状态机都实现

---

## 三、方案师关键设计决策（执行者按此实现）

| # | 决策 | 理由 / 风险规避 |
|---|---|---|
| D1 | **敌人弹丸挂载点 = Boss 节点本身**（`boss.add_child(proj)`，非 Enemies 容器） | 防 `get_alive_count` 污染（最高风险点）；Boss 死亡/超时清理时弹丸随父销毁，行为一致；零场景改动。**备选方案**：Main.tscn 新建 `World/Projectiles` + `GameManager.projectiles_container`（+1 场景节点 +1 var），执行者偏好显式容器可用，但默认走 D1 |
| D2 | **charge_attack 复用 `_move_charge`（:302-320）既有逻辑**，阶段激活置位 `_boss_charge=true` + `_boss_charge_mult`（1/2）；命中伤害在 `_try_contact_damage` :161 乘倍率（`is_boss` 守卫） | **不动移动倍率**（F-15 已定型 1.5，防围杀回归）；接触伤害对普通敌人零影响 |
| D3 | **all_attacks_2x = 阶段修饰符**：`_reset_boss_phase` 时 `_attack_mult *= 2.0`（仅 predator P3 含此指令，单次激活；对 summon 无效） | 数据自描述语义；修饰符只在伤害类生效 |
| D4 | **spread/barrage 计时**：无 `every_Xs` 的发射类攻击默认 interval **4.0s**（PRE #2 定案）；`barrage` = **8 向 × 3 波 0.25s 间隔** | 数据无默认间隔字段；发射类频率高于 AOE 8s 基准 |
| D5 | **aoe radius 定案 120px**（数据无 radius 字段，取 AOE 常规半径） | PRE #2 定案 |
| D6 | **take_damage 相位切换**：`if health <= 0.0: die(); return` **先行**，随后才检查相位 → 仅存活命中触发切换 | 避免击杀瞬间多余横幅/状态残留（对 T1 措辞「die 之前」的实现细化） |
| D7 | **scale ×2 视觉过渡**：initialize 中 `is_boss and not phases.is_empty()` → `scale = Vector2(2.0, 2.0)`（32→64px） | 接触判定用 `frame_size`（未缩放值）恒定；物理已按 F-02 与玩家分层 → 纯视觉零逻辑影响；专属 Boss 精灵归 D21-22 |
| D8 | **Boss 弹幕无物理节点**：距离判断命中玩家，禁物理查询（D3 火球教训） | 无头稳定性铁律 |
| D9 | **探针锚点**：wave **10**（勿写 20）；predator 旧制亦验证；player projectile.gd **零改动** | 回归十二件套保护 |

---

## 四、任务方案

### 任务1：D18-19-T1【W1】enemy.gd Boss phases 状态机（阶段切换）　风险：中

- **文件**：`scripts/enemy/enemy.gd`
- **改动**：
  1. 属性区（`:132 _ability_timer` 后新增「# Boss 阶段（D18-19-T1）」块）：
     `var phases: Array = []` / `var _current_phase_idx: int = 0` / `var _attack_timers: Dictionary = {}` / `var _attack_mult: float = 1.0` / `var _boss_charge: bool = false` / `var _boss_charge_mult: float = 1.0` / `var _base_speed: float = 120.0` / `var _rng := RandomNumberGenerator.new()`（探针可注 `_rng.seed`；禁 Array.shuffle/pick_random 全局 RNG）
  2. `initialize`（`:551` category match 之后、`:552 health = max_health` 之前）：`if stats.has("phases"): phases = stats["phases"]`；`_base_speed = move_speed`；`if is_boss and not phases.is_empty(): _reset_boss_phase(0); scale = Vector2(2.0, 2.0)`（决策 D7）
  3. `take_damage`（`:470 _play_hit_flash()` 之后）改为：
     ```
     if health <= 0.0:
         die()
         return
     if is_boss and not phases.is_empty():
         _check_phase_transition()
     ```
     （决策 D6；非 Boss 路径与现状完全一致）
  4. 新增 `_check_phase_transition()`：从 `_current_phase_idx + 1` 起遍历后续 phase，找第一个 `health / max_health <= float(phase.hp_threshold_percent) / 100.0` → `_reset_boss_phase(i)`；无更低阈值 → 保持
  5. 新增 `_reset_boss_phase(idx)`：`_current_phase_idx = idx`；清空 `_attack_timers`；遍历该 phase `attacks` → `var parsed = _parse_attack(cmd)`（T2，返回空字典则跳过）→ 缓存 `_attack_timers[cmd] = {parsed, timer: 0.0}`；`all_attacks_2x` 修饰符 → `_attack_mult *= 2.0`（决策 D3）；`charge` 型 → `_boss_charge = true; _boss_charge_mult = parsed.mult`（决策 D2）；`move_speed = _base_speed * float(phase.get("speed_multiplier", 1.0))`；阶段横幅「⚠ Boss 进入第 N 阶段」（N = idx+1，1.5s 淡出，仿 `_spawn_exp_popup` :500-516 / D17 横幅范式，容器缺失静默跳过）
  6. `die()`（`:481 died.emit(self)` 之后）：`if is_boss and GameManager and GameManager.has_method("register_boss_killed"): GameManager.register_boss_killed()`（autoload 恒在，双守卫防纯数据探针异常）
- **落地合理性 / 副作用**：全部行为以 `is_boss and not phases.is_empty()` 双条件守卫——普通/精英敌人零新行为；既有 Boss 波（wave 10 invoker / wave 20 predator 旧制）spawn 后自动激活相位（`get_scaled_enemy` 恒返回 phases 键，`stats.has("phases")` 恒真但仅 is_boss 消费）；`_reset_boss_phase(0)` 在 initialize 期调用不依赖任何外部节点（横幅容器缺失静默）。`scale ×2` 为纯视觉（决策 D7）。**不破坏既有探针**：day17_elite/day17_p0 均不构造 is_boss+phases 组合。
- **验证**：新探针 `day18_19_boss_check.gd` §2（白盒构造 stats：category=boss + invoker 两段 phases 副本）→ 初始 phase 0 / `_attack_timers` 键数 == attacks 数；`take_damage` 压过 60% 阈值 → phase 1（attacks 更新 / move_speed ×1.2 / 横幅节点出现并自动销毁）；全阶段走完不再切；**非 boss 构造同 stats 去掉 category=boss → 零新行为（回归锚点）**
- **风险**：中 —— 触碰 take_damage/die/initialize 核心路径；缓解 = 双条件守卫 + die() 后置相位检查（D6）；**替代方案**：若担心核心路径，可将 `_check_phase_transition` 调用整体包进 `if is_boss` 独立分支，普通敌人函数体零改动（本方案已如此，属同一策略）

### 任务2：D18-19-T2【W1】attacks 指令解析 + 行为执行器　风险：中

- **文件**：`scripts/enemy/enemy.gd`
- **改动（A：`_parse_attack` 纯函数）**：
  `_parse_attack(cmd: String) -> Dictionary` —— 推荐 RegEx 类（或用 `split("_")` 手动解析，执行者自选，输出必须与下表一致）：

  | 指令 | 输出 {kind, count, interval, mult, elite} |
  |---|---|
  | `summon_N_enemies_every_Xs` | {kind:"summon", count:N, interval:X, elite:false} |
  | `summon_N_elite` | {kind:"summon", count:N, interval:0.0, elite:true}（一次性） |
  | `N_projectile_spread` | {kind:"spread", count:N, interval:4.0}（决策 D4） |
  | `projectile_barrage` | {kind:"barrage", interval:4.0}（决策 D4） |
  | `aoe_every_Xs` | {kind:"aoe", interval:X} |
  | `charge_attack` / `charge_attack_2x` | {kind:"charge", mult:1.0 / 2.0, interval:-1.0}（永续置位，无计时） |
  | `all_attacks_2x` | {kind:"mult", mult:2.0, interval:-1.0}（阶段修饰符，无计时） |
  | 未知 | `push_warning("[Boss] 未知攻击指令: %s" % cmd)` + 返回 {}（不崩） |

- **改动（B：`_process_boss_attacks(delta)` + 执行器）**：
  1. `_update_behavior`（`:270` 目标校验后、`match behavior:` 前）插入：
     ```
     if is_boss and not phases.is_empty():
         _process_boss_attacks(delta)
         if _boss_charge:
             _move_charge(delta)
         else:
             _move_chase(delta)
         return
     ```
  2. `_process_boss_attacks(delta)`：遍历 `_attack_timers`；`interval < 0`（charge/mult 置位型）跳过；一次性（`interval <= 0`）→ 首次 tick 执行后**移除该键**；周期型 → `timer -= delta` 到点执行 + 重置为 interval
  3. 执行器（全距离/容器遍历，禁物理查询，决策 D8）：
     - `_boss_summon(count, elite)`：池 = `DataLoader.get_enemy_ids_by_category("elite" if elite else "regular")`；×count 循环 `_rng.randi_range(0, pool.size()-1)` 取 id → `get_scaled_enemy(id, wave_number)` → 复用 `_elite_spawn` 的容器/场景范式（`:425-440`：GameManager.enemies_container → spawner.enemies_container → 缺失静默；`GameManager.enemy_spawner.enemy_scene` → `load("res://scenes/Enemy.tscn")`）→ instantiate + initialize(stats) + set_target(GameManager.player) + add_child
     - `_boss_spread(count)`：基准角 = 朝向玩家；`angle = base + TAU * i / count`；实例化 `EnemyProjectile.new()`（T3，preload 或 class_name）→ `initialize({speed:220.0, damage:damage*_attack_mult, lifetime:2.0})` + `set_direction(dir)` → **`add_child` 到自身（决策 D1）**
     - `_boss_barrage()`：8 向 × 3 波、波间隔 0.25s（决策 D4）；实现 = 内嵌小计时器（`_barrage_wave` 状态变量）或每 0.25s 触发一次 `_boss_spread(8)`；单发伤害同 spread 口径（`damage*_attack_mult`）
     - `_boss_aoe(radius=120.0)`（决策 D5）：玩家距离 ≤ radius → `player.take_damage(damage * _attack_mult)` + `VfxPlayer.spawn(_resolve_fx_container(), global_position, "crit")`（容器缺失静默）
     - `_boss_charge()`：由 D1 决策 D2 的置位机制承担（`_boss_charge` 置位后 `_move_charge` 自动生效，无独立计时）；命中伤害倍率在 `_try_contact_damage` :161 消费：`target.take_damage(damage * (_boss_charge_mult if (is_boss and _boss_charge) else 1.0))`（普通敌人恒 ×1.0）
- **落地合理性 / 副作用**：`_update_behavior` 的 boss 分支在普通敌人路径之前 return，普通/精英行为零变化；召唤进 Enemies 容器（是敌人、计入存活 ✅）；**弹丸进 Boss 自身容器（不计入存活 ✅，决策 D1）**；charge 复用 `_move_charge` 不改移动倍率（防 F-15 回归，决策 D2）；`_attack_mult` 仅作用于伤害类。
- **验证**：探针 §3（白盒直构造 + `_rng.seed` 固定）：`summon_2_enemies_every_5s` → 容器 +2（id ∈ regular 池）；`summon_1_elite` → +1（is_elite）；`3_projectile_spread` → Boss 子节点 +3 EnemyProjectile；`aoe_every_8s` → 玩家掉血（damage×mult）；`charge_attack_2x` 置位 → 接触伤害 ×2；`all_attacks_2x` → `_attack_mult == 2.0`；未知指令 → push_warning 不崩
- **风险**：中 —— 新行为代码量最大；**最高风险 = 弹丸容器污染 alive-count（决策 D1 已规避）**；其次 = 冲锋伤害倍率误伤普通敌人（is_boss 守卫已规避）。**替代方案**：弹丸改入新建 `World/Projectiles` 容器（决策 D1 备选）

### 任务3：D18-19-T3【W1】新建 `scripts/enemy/enemy_projectile.gd`　风险：低

- **文件**：`scripts/enemy/enemy_projectile.gd`（**新建**，纯代码无场景文件）
- **改动**：
  - `class_name EnemyProjectile` + `extends Node2D`；**无物理碰撞节点**（决策 D8）
  - 属性：`speed: float = 220.0` / `damage: float = 10.0` / `lifetime: float = 2.0` / `direction: Vector2` / `bullet_color: Color = Color(0.75, 0.3, 0.9)`（暗紫，区分玩家霓虹黄）/ `bullet_radius: float = 4.0`
  - `_ready()`：`add_to_group("enemy_projectiles")`（探针批量断言用）+ Sprite2D 运行时绘制（复制 projectile.gd `_make_bullet_texture` :144-158 范式，含 `bullet_color.lightened(0.45)` 核心亮色）
  - `_physics_process(delta)`：`global_position += direction * speed * delta`；`_lifetime_timer += delta` 超时 → `queue_free()`；玩家判定 = `GameManager.player` 有效 && 距离 ≤ `bullet_radius + 12.0` && `player.has_method("take_damage")` → `player.take_damage(damage)` + `VfxPlayer.spawn(GameManager.vfx_container, global_position, "hit")`（容器缺失静默）+ `queue_free()`（命中即毁，无穿透）
  - `initialize(props: Dictionary)`（speed/damage/lifetime/bullet_color/bullet_radius 逐键可选覆盖）+ `set_direction(dir)`（normalized + rotation = direction.angle()）
- **落地合理性 / 副作用**：纯新建文件零依赖、零既有代码触碰；挂载于 Boss 节点（D1）——global_position 为世界坐标，移动不受父节点位移影响；Boss 死亡/波次超时清理 → 弹丸随父销毁，与「Boss 倒下攻击停止」语义一致；player projectile.gd **零改动**（回归保护）。
- **验证**：探针 §4（白盒）：摆位玩家 60px → 推进 delta → 玩家掉血 + 弹丸 queue_free；lifetime 耗尽销毁；`damage` 透传正确；玩家无效/无容器 → 不崩
- **风险**：低 —— 唯一注意点 = `_make_bullet_texture` 需 bounds check（PIL 教训不适用，Image.create 尺寸由 radius 推导 ≥8，安全）

### 任务4：D18-19-T4【W1】GameManager Boss 接入 + 胜利标记　风险：低

- **文件**：`scripts/autoload/game_manager.gd`
- **改动**：
  1. 属性区（`:48 debug_cheat` 附近）：`var boss_killed: int = 0`
  2. `reset()`（`:519 difficulty_delta = 0` 旁）：`boss_killed = 0`
  3. `_enter_node`（`:206-207` elite 横幅判断旁）boss 分支：
     ```
     if node_type == "boss":
         _show_boss_banner()
         route["flags"] = route.get("flags", {})
         route["flags"]["boss_encountered"] = true
     ```
     随后照常 `_start_next_wave(wave_index)`（`:208` 已有）
  4. 新增 `_show_boss_banner()`（仿 `_show_elite_banner` :222-241）：Node2D+Label「⚠ 最终 Boss」+ 1.5s 淡出上浮 tween；容器 = vfx_container → current_scene → 缺失静默返回
  5. 新增 `register_boss_killed()`：`boss_killed += 1`；`if not route.is_empty(): route["flags"] = route.get("flags", {}); route["flags"]["boss_defeated"] = true`（旧波次制 route 空 → 仅计数）；配合 T1-die() 调用
- **落地合理性 / 副作用**：纯增量——flags 写法沿用 `:431-432` 既有范式；`boss_killed` 是 Day 27 局外养成（研究点=胜利局数）的既有预登记消费源（#2 第 23 轮定案：`boss_defeated` 由 end_game(victory) 统一消费），本日先登记不臆造；route 空（旧制）零影响。
- **验证**：探针 §5：白盒 enemy die（is_boss）→ `boss_killed == 1` + flags.boss_defeated；`_enter_node("boss", 10)` → BossBanner 节点出现（容器就绪时）+ flags.boss_encountered；`reset()` → 清零
- **风险**：低 —— 无既有行为改动

### 任务5：D18-19-T5【W1】新建 `tools/day18_19_boss_check.gd`　风险：低

- **文件**：`tools/day18_19_boss_check.gd`（**新建**）
- **改动**：`extends SceneTree` 探针（范式沿用 D11-12/13/14-15 flaky 修复记录：`_advance` 分派全部 sub + 固定 seed + 白盒直构造 + `_rng.seed` 固定），五段 ≥20 断言：
  - §1 数据层：boss[2]（invoker 2 phases / predator 3 phases / hp / damage / exp_value 齐）；`hp_threshold_percent` 单调递减（100→60 / 100→66→33）；attacks 全量可被 `_parse_attack` 解析（未知指令 = 0）
  - §2 阶段状态机：白盒 stats（category=boss + invoker phases）→ 初始 phase 0 / `_attack_timers` 键数 == attacks 数 / 非 boss 零新行为；`take_damage` 压过阈值 → 阶段切换（attacks 更新 / move_speed ×speed_multiplier / 横幅出现且自动销毁）；全阶段走完不再切
  - §3 指令执行（固定 `_rng.seed`）：`summon_2_enemies_every_5s` → Enemies 容器 +2（id ∈ regular 池）；`summon_1_elite` → +1（is_elite）；`3_projectile_spread` → **Boss 子节点 +3 EnemyProjectile**（决策 D1 断言口径）；`aoe_every_8s` → 玩家掉血（damage×mult）；`charge_attack_2x` 置位 → 接触伤害 ×2；`all_attacks_2x` → `_attack_mult == 2.0`
  - §4 弹丸：enemy_projectile 白盒 → 命中玩家掉血 + 销毁；lifetime 耗尽销毁；damage 透传
  - §5 回归：wave 10 `boss:invoker` / wave 20 `boss:predator` 白盒 spawn → `is_boss` + category=boss + phases 透传非空；**route 末层 boss wave_index=10**（勿写 20）；boss 波击杀 → `boss_killed` 登记
- **落地合理性 / 副作用**：新探针独立文件，不触碰既有探针；回归锚点文档化（wave 10 / 容器断言口径 / player projectile 零改动）
- **验证**：headless 运行 `day18_19_boss_check.gd` + 回归十三件套（day2 32 / day3 16 / day4 21 / day5 16 / day6 14 / day7 13 / day8 19 / day10 20 / day11_12 22 / day13 36 / day14_15 53 / day16 41 / day17 39 / day17_p0 20 —— 实际为十四件套 + day18_19 新探针）
- **风险**：低 —— 潜在 flaky 点 = 弹丸容器断言（D1 已定 Boss 子节点口径，稳定）；回归若某件套因 phases 初始化行为变化变红 → 先查非 Boss 守卫是否遗漏

### 任务6：D18-19-EXIT【W5】阶段 C 第四节收口　风险：低

- **文件**：无（执行/验证动作）
- **改动**：`python tools/baseline_check.py` → `BASELINE CLEAN`；`day18_19_boss_check` CLEAN + 回归十三件套全绿 + `gen_weapons_day7.py verify` 36/36；git commit 收口（勿夹带 docs/pindou/、scripts/ui/*.bak、tools/pixel_to_pindou.py、docs/LOOP_HEALTH.md）；主观项登记（Boss 战难度曲线 / 阶段切换表现力 / Boss 视觉辨识度 / 弹幕躲避手感 → PLAYTEST_CHECKLIST #5）
- **落地合理性 / 副作用**：纯收口动作；**若批次 A/B 已分别 commit，本批仅 T4+T5+回归+收口 commit**
- **验证**：baseline + 探针 + verify 三重出口
- **风险**：低

---

## 五、全局风险评估

| 风险 | 等级 | 缓解 |
|---|---|---|
| 弹丸入 Enemies 容器 → get_alive_count 污染 → 波次永不结束 | **高（已消解）** | 决策 D1：弹丸挂 Boss 节点；备选 = 新 Projectiles 容器 |
| charge 倍率误伤普通敌人 | 中（已消解） | `is_boss and _boss_charge` 双守卫，普通敌人恒 ×1.0 |
| 冲锋移动倍率被改 → F-15 围杀回归 | 中（已消解） | 决策 D2：只乘命中伤害倍率，`_move_charge` :302-320 零改动 |
| take_damage/die/initialize 核心路径改动破坏回归 | 中 | `is_boss and not phases.is_empty()` 双守卫 + D6 后置相位检查 + 非 Boss 白盒断言入探针 |
| Boss 波击杀/超时行为变化 | 低 | 现状保持（wave_manager 30s 超时 → on_wave_cleared → _clear_remaining_enemies 清 Boss 及其弹丸子节点） |
| 探针 flaky（弹幕/召唤） | 低 | 白盒直构造 + `_rng.seed` + 固定 delta + 容器断言用 Boss 子节点口径（D1） |
| Boss 横幅/特效容器缺失 | 低 | 全链路容器缺失静默跳过（既有范式） |
| 执行者 7 窗口零产出（流程风险，非方案风险） | 🔴 流程 | 交 Owner 核查（#3 配置/模型/prompt/触发链路）；本方案已就绪，修复后从批次 A 直接执行 |

---

## 六、红线确认

- ✅ 本方案零代码、零数据、零 git 改动产出（仅 docs/SOLUTION_PLAN.md + docs/TASKS.md 标注）
- ✅ 未跑任何探针 / headless 验证（验证方式均为「执行者阶段」动作，已逐任务写明）
- ✅ 大纲「腐化巨树藤蔓/毒雨」差异：以数据为准（invoker/predator），登记不臆造（PRE #8）
