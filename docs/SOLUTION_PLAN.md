# 方案计划（2026-08-07 · 方案师自动化轮 · 第 2 轮）

> 角色：方案师（Solution Architect）· 只定方案，不写代码 / 不改 .gd/.tscn/.tres/.json / 不 git commit / 不跑探针。
> 本轮目标日：**Day 18-19（Boss 多阶段）** · 状态 = **批次 A ✅ / 批次 B ✅ 已提交 · 批次 C（收口批）执行中**。
> 执行者入口：`docs/TASKS.md` Day 18-19 区（T1~T5 + EXIT）+ 本方案。

---

## 〇、P0 调度硬性输入检查（步骤 0 产出）

- **追踪区最新增量 #30（2026-08-07 16:0x · #5 标记岗）**：TEST_REPORT #25（14:12）= **Day18-FB 六件套正式覆盖**（15 件套 381 断言全绿，day18_feedback 16/16）；git HEAD 已推进 `d3b95a0` = #3 恢复后首个实现提交（批次 A）——「自动化疑似故障」判定解除实证；D18-19 挂账 🔴🔴 → 🟡（批次 A ✅ / 批次 B·C 待执行）。
- **本方案师磁盘复核（15:5x）**：HEAD 已再推进 **`afe5ef7` = 批次 B 已提交**（enemy.gd Boss phases 状态机 + attacks 执行器 + 阶段横幅 + scale×2 + die 登记；day17 回归 39/39 + 20/20 自证）。
- **P0 结论**：F-01/F-02/F-04/F-15（用户拍板四件套）+ P1 四修复 + 六件套（F-03/05/06/07/08/11）**机器侧全闭环**，无新机器可验证 P0 需拆 → 剩余动作 = 真人回归（主观项，交 #5）。**本轮无新增 P0 任务，批次 C 收口即完成 D18-19 挂账清偿。**

---

## 一、目标日任务清单（docs/TASKS.md Day 18-19 区 · 批次状态）

| 任务 | 内容 | 状态（方案师实测） | 本方案章节 |
|---|---|---|---|
| D18-19-T1 | enemy.gd Boss phases 状态机 | ✅ **批次 B 已提交（`afe5ef7`）**：`_check_phase_transition` :542 / `_reset_boss_phase` :550 / 双守卫 :739-740 / scale×2 :837 附近 | —（核验见 §四·0） |
| D18-19-T2 | attacks 指令解析 + 行为执行器 | ✅ **批次 B 已提交（`afe5ef7`）**：`_parse_attack` :298 / `_process_boss_attacks` :598 / 执行器 :674-706 | —（核验见 §四·0） |
| D18-19-T3 | 新建 `enemy_projectile.gd` | ✅ **批次 A 已提交（`d3b95a0`）**：90 行，`class_name EnemyProjectile` + `initialize(props)` :56 + `set_direction` :69 + `enemy_projectiles` group | —（核验见 §四·0） |
| D18-19-T4 | GameManager Boss 接入 + 胜利标记 | 🔶 **进行中**：enemy.gd die() 调 `register_boss_killed` 已提交（:749-751）；**game_manager.gd 改动在工作区未提交**（+39 行） | §四·任务1 |
| D18-19-T5 | 新建 `tools/day18_19_boss_check.gd`（≥20 断言五段） | ❌ **未创建**（tools/ 无此文件） | §四·任务2 |
| D18-19-EXIT | baseline + 回归 + verify + commit | ❌ 未执行 | §四·任务3 |

> **批次 C 剩余工作 = T4 收尾核验 + T5 探针五段 + EXIT 收口。** 批次 A/B 均已单批 commit，符合 #1 重排「任一批次完成即 commit」裁决。

---

## 二、实测基线（方案师本轮磁盘核实 · 供执行者免排查）

- **git HEAD = `afe5ef7`**（批次 B）→ `d3b95a0`（批次 A）→ `8c54efb`（docs：方案师首轮 SOLUTION_PLAN.md 落盘）→ `4a43f8c`（docs）→ `16c6dd3`（反馈专员六件套）。
- **工作区**：`M scripts/autoload/game_manager.gd`（+39 行，批次 C T4 在途）+ `M docs/PLAYTEST_CHECKLIST.md`（#5 增量 #30）。**⚠️ game_manager.gd 未提交改动 = T4 成果，禁止丢弃**（详见风险表）。
- **enemy.gd 现行行号**（TASKS 旧行号已过时，勿照抄旧值）：
  - `is_boss` :56 / `_attack_mult` :146 / `_boss_charge` :147 / `_boss_charge_mult` :148 / 接触伤害倍率消费 :181-182
  - `_parse_attack(cmd)` :298 / `_update_behavior` Boss 分支 :347-349 / `_check_phase_transition` :542 / `_reset_boss_phase` :550（含 _attack_mult / _boss_charge 置位 :562-570）/ `_process_boss_attacks` :598 / 弹幕执行器 :674-706 / `take_damage` 相位检查 :739-740 / `die()` :743 + `register_boss_killed` 调用 :749-751 / is_boss 标记 :831 / `_reset_boss_phase(0)` + scale×2 :837-838
- **enemy_projectile.gd**（90 行）：`class_name EnemyProjectile` / `_ready` 加 `enemy_projectiles` group / `initialize(props)` :56（speed/damage/lifetime/bullet_color/bullet_radius 逐键可选）/ `set_direction(dir)` :69。
- **game_manager.gd 工作区改动内容（方案师已逐行核对，与 TASKS T4 定案一致）**：
  1. 属性区 :49-50：`var boss_killed: int = 0`（注释指向 Day 27 消费源）
  2. `_enter_node` "boss" 分支 :223-227：`_show_boss_banner()` + `route.flags["boss_encountered"] = true` → 照常 `_start_next_wave`
  3. 新增 `_show_boss_banner()` :263-283（仿 `_show_elite_banner` 范式：Node2D+Label「⚠ 最终 Boss」+ 1.5s 淡出上浮；容器缺失静默）
  4. 新增 `register_boss_killed()` :285-291：`boss_killed += 1` + route 非空时 `flags["boss_defeated"] = true`
  5. `reset()` :569：`boss_killed = 0`
- **回归清单（当前为 15 件套）**：day2 32 / day3 16 / day4 21 / day5 16 / day6 14 / day7 13 / day8 19 / day10 20 / day11_12 22 / day13 36 / day14_15 53 / day16 41 / day17 39 / day17_p0 20 / **day18_feedback 16**（反馈专员六件套，TEST_REPORT #25 起正式纳入）。
- **探针范式先例**：`tools/day17_elite_check.gd`（extends SceneTree + `_advance` 分派 + `_load_mocks` 白盒 stub：`ENEMY_SCENE_PATH` load + `initialize(stats)` + 玩家 stub）。

---

## 三、方案师关键设计决策（批次 C · 承上轮 D1-D9）

| # | 决策 | 依据 |
|---|---|---|
| D10 | **T4 不重写、核验收尾**：game_manager.gd 工作区改动已逐行核对与 TASKS T4 定案完全一致 → 执行者仅核验无遗漏（对照本方案 §四·任务1 清单）后归入收口 commit | 方案师 git diff 实测（+39 行 5 处改动全部命中定案） |
| D11 | **T5 探针断言口径 = Boss 子节点 + `enemy_projectiles` group**：弹幕断言查 group 成员数而非全局容器（决策 D1 延续，防 alive-count 污染误判）；召唤断言查 `GameManager.enemy_spawner.enemies_container`（或白盒 stub 容器） | enemy_projectile `_ready` 已加 group（实测）；D1 弹丸挂 Boss 节点 |
| D12 | **T5 玩家 stub 范式**：白盒 Node2D stub（`global_position` + `take_damage(amount)` 记录 last_damage + health 扣减）挂到 GameManager.player；**禁止依赖真实 Main 场景**（探针独立运行，Main 未实例化） | day17_elite_check `_load_mocks` 先例 |
| D13 | **boss die → `boss_killed` 登记断言走 GameManager autoload 实例**：headless 下 GameManager 是 autoload（`get_node("/root/GameManager")` 恒在）；白盒 enemy 白盒 die 后断言 `boss_killed == 1` + `route.flags["boss_defeated"]`；**断言前须手动置 route 非空**（`_enter_node` 或直接构造 route 字典） | enemy.gd :749-751 双守卫（GameManager 有效 + has_method）实测；GameManager.reset 后 route 为空 → 仅计数不登记 flags |
| D14 | **收口 commit 必须显式 `git add scripts/autoload/game_manager.gd`**（工作区在途改动）+ 新探针 + docs 同步；勿夹带 docs/pindou/、scripts/ui/*.bak、tools/pixel_to_pindou.py、docs/LOOP_HEALTH.md（护栏延续） | 工作区现状实测；TASKS EXIT 护栏 |
| D15 | **批次 C 完成判据（供 #1/#4 复核）**：`day18_19_boss_check` CLEAN（≥20 断言）+ 回归 15 件套全绿 + `baseline_check` → BASELINE CLEAN + `gen_weapons_day7.py verify` 36/36 + 收口 commit 含 game_manager.gd | 重排裁决口径 + TEST_REPORT #25 十五件套基线 |

---

## 四、任务方案

### 任务1：D18-19-T4【W1】GameManager Boss 接入核验 + 收尾　风险：中

- **文件**：`scripts/autoload/game_manager.gd`（工作区在途，未提交）
- **现状**：5 处改动已落盘且与 TASKS T4 定案一致（§二已逐行核对）。执行者动作 = **核验清单**（非重写）：
  1. `var boss_killed: int = 0` 存在（:49-50 附近）✅ 已核
  2. `reset()` 内 `boss_killed = 0` ✅ 已核（:569）
  3. `_enter_node` "boss" 分支：`_show_boss_banner()` + `route.flags["boss_encountered"] = true`，随后照常 `_start_next_wave` ✅ 已核（:223-227）
  4. `_show_boss_banner()`（「⚠ 最终 Boss」1.5s 淡出，容器缺失静默）✅ 已核（:263-283）
  5. `register_boss_killed()`：`boss_killed += 1` + route 非空 → `flags["boss_defeated"] = true` ✅ 已核（:285-291）
- **无新增改动需求**；若核验发现遗漏（对照上表），仅补遗漏点，不重构。
- **落地合理性 / 副作用**：纯增量零既有行为改动；`boss_killed`/`flags.boss_defeated` 是 Day 27 局外养成既定消费源（#2 第 23 轮定案：end_game(victory) 统一结算），本日登记不臆造；旧波次制 route 空 → 仅计数零影响。
- **验证**：探针 §5（任务 2）+ 目测 `git diff scripts/autoload/game_manager.gd` 与上表逐条对照。
- **风险**：中 —— **最高风险 = 工作区改动丢失**（若执行者误 `git checkout -- .` / `git stash` / reset 硬回退 → T4 全丢且无法从已提交内容恢复）。缓解：**先 `git status` 确认 M 状态 → 改动即成果 → commit 阶段显式 `git add scripts/autoload/game_manager.gd`**（D14）。**替代方案**：无（改动已在盘，只需保留+提交）。

### 任务2：D18-19-T5【W1】新建 `tools/day18_19_boss_check.gd`（探针五段 ≥20 断言）　风险：中

- **文件**：`tools/day18_19_boss_check.gd`（**新建**；运行：`tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day18_19_boss_check.gd`）
- **范式**：`extends SceneTree` + `_advance` 分派全部 sub + 固定 seed + 白盒直构造（照抄 day17_elite_check.gd 骨架：`_initialize` / `_process` 分发 / `_load_mocks` / `_report` 退出码=失败项数）。
- **白盒 stub（`_load_mocks` 段）**：
  - 敌人：`const ENEMY_SCENE_PATH = "res://scenes/Enemy.tscn"` → `load().instantiate()` → `initialize(stats)`（stats 白盒构造：category="boss" + invoker phases 副本 / predator 3 段副本；**相位阈值数据从 DataLoader.get_scaled_enemy("invoker"/"predator") 读取后原地构造副本，勿改 JSON**）
  - 玩家：Node2D stub（`global_position = Vector2(100, 100)` + `health` + `take_damage(amount)` 记录 `last_damage` 并 `health -= amount`）→ 挂 `GameManager.player`（`get_node("/root/GameManager")`，autoload 恒在）
  - 召唤容器：优先 `GameManager.enemy_spawner.enemies_container`；缺失 → 白盒 stub 容器（Node 挂 spawner 上，探针自建）
- **五段断言（≥20，固定 `_rng.seed` + 固定 delta）**：
  - **§1 数据层（≥4）**：`boss[2]` 齐（invoker/predator 的 phases 非空 + hp + damage + exp_value）；`hp_threshold_percent` 单调递减（invoker 100→60 / predator 100→66→33）；attacks 数组非空且**全量可被 `_parse_attack` 解析**（遍历 invoker+predator 全部 phase attacks → 解析结果非空字典，未知指令计数 == 0）
  - **§2 阶段状态机（≥5）**：白盒 invoker stats → 初始 `_current_phase_idx == 0` + `_attack_timers` 键数 == phase0 attacks 数；`take_damage` 压过 60% 阈值 → phase 1（attacks 更新 / `move_speed == _base_speed * 1.2` / 横幅节点出现并 1.5s 内销毁——横幅断言用 `_advance` 步进）；全阶段走完再压 → 不再切；**非 boss 白盒（category 改 "regular"）→ 零新行为（_attack_timers 空 / 无横幅 / die 不调 register）**
  - **§3 指令执行（≥6，白盒直构造 + `_rng.seed` 固定）**：`summon_2_enemies_every_5s` → 召唤容器 +2（id ∈ regular 池，is_elite == false）；`summon_1_elite` → +1（is_elite == true）；`3_projectile_spread` → Boss 子节点 +3（`get_tree().get_nodes_in_group("enemy_projectiles")` 口径，决策 D11）；`aoe_every_8s` → 玩家 stub `health` 扣减 == `damage * _attack_mult`；`charge_attack_2x` 置位 → 白盒接触伤害路径 ×2（或断言 `_boss_charge == true` + `_boss_charge_mult == 2.0`）；`all_attacks_2x` → `_attack_mult == 2.0`
  - **§4 弹丸（≥3）**：EnemyProjectile 白盒（`initialize({speed, damage, lifetime})` + `set_direction`）→ 玩家摆位 60px 推进 → 玩家 stub health 扣减 + 弹丸 queue_free；lifetime 耗尽（无玩家命中路径）→ 销毁；damage 透传 == 配置值
  - **§5 回归（≥4）**：wave 10 `boss:invoker` / wave 20 `boss:predator` 白盒 spawn（get_scaled_enemy + instantiate）→ `is_boss == true` + category == "boss" + phases 非空；**route 末层 boss wave_index == 10**（`999a1bd` Fix-2 后口径，**勿写 20**）；boss die（白盒 `die()`）→ `GameManager.boss_killed == 1` + `route.flags["boss_defeated"] == true`（**断言前置 route 非空**，决策 D13）
- **落地合理性 / 副作用**：独立新文件零触碰既有探针；回归锚点文档化（wave 10 / group 口径 / player projectile 零改动）。
- **验证**：headless 单跑 CLEAN → 收口轮跑回归 15 件套。
- **风险**：中 —— 潜在 flaky 点：① 召唤/弹幕容器断言（决策 D11 group 口径已稳定）；② 横幅断言依赖 tween 推进（用 `_advance` 步进 1.6s 或直接断言节点创建，横幅销毁断言降级为「不阻塞」）；③ `_rng.seed` 固定但 `_attack_timers` 遍历顺序依赖 Dictionary（GDScript 4 保序，安全）。**替代方案**：若横幅销毁断言 flaky → 只断言「创建」不断言「销毁」（横幅为视觉项，非核心）。

### 任务3：D18-19-EXIT【W5】阶段 C 第四节收口　风险：低

- **文件**：无（执行/验证动作）
- **改动**：
  1. `python tools/baseline_check.py` → **BASELINE CLEAN**
  2. `day18_19_boss_check` CLEAN（≥20 断言）
  3. **回归十五件套**全绿：day2 32 / day3 16 / day4 21 / day5 16 / day6 14 / day7 13 / day8 19 / day10 20 / day11_12 22 / day13 36 / day14_15 53 / day16 41 / day17 39 / day17_p0 20 / **day18_feedback 16**（TEST_REPORT #25 起正式纳入，勿漏）
  4. `gen_weapons_day7.py verify` → 36/36
  5. **git commit 收口（决策 D14）**：显式 `git add scripts/autoload/game_manager.gd`（工作区在途 T4）+ `tools/day18_19_boss_check.gd` + 相关 docs；**勿夹带** docs/pindou/、scripts/ui/*.bak、tools/pixel_to_pindou.py、docs/LOOP_HEALTH.md
  6. 主观项登记：Boss 战难度曲线 / 阶段切换表现力 / Boss 视觉辨识度 / 弹幕躲避手感 → PLAYTEST_CHECKLIST.md（#5 收口），不阻塞出口
- **验证**：三重出口（baseline + 探针 + verify）。
- **风险**：低 —— 若回归某件套变红：优先查 `is_boss and not phases.is_empty()` 双守卫遗漏（普通敌人误入 Boss 分支）；若 day18_feedback 变红：查 take_damage/die 签名变化波及（批次 B commit 已自证 day17 39/39，day18_feedback 首跑全量在收口轮）。

---

## 五、全局风险评估

| 风险 | 等级 | 缓解 |
|---|---|---|
| **工作区 game_manager.gd（T4）未提交改动丢失** | 🔴 **高** | 执行者先 `git status` 确认 M → 改动即成果，禁止 checkout -- / stash / reset 丢弃；commit 显式 add（D14） |
| 批次 C 收口轮首跑全量回归（15 件套） | 中 | 批次 A/B 已单批自证（day17 39/39 + 20/20）；收口轮按 EXIT 清单全量；变红先查双守卫遗漏 |
| T5 探针首跑 flaky（横幅 tween / 容器口径） | 中 | 白盒 stub + `_rng.seed` + group 口径（D11/D12）；横幅断言降级为「创建不销毁」（替代方案） |
| 弹丸/召唤容器断言污染误判 | 中（已消解） | 决策 D1（弹丸挂 Boss 节点）+ D11（group 断言口径） |
| TASKS 旧行号误导执行者 | 低 | §二已给现行行号（enemy.gd :542/:598/:749 等），勿照抄 TASKS 旧值 |
| Boss 横幅/特效容器缺失 | 低 | 全链路容器缺失静默跳过（既有范式） |
| 执行者批次 C 再次空转（流程风险） | 🟡 流程 | 批次 A/B 已实证 #3 恢复运行（`d3b95a0`/`afe5ef7` 落地）；本方案已就绪，下窗口直接执行 |

---

## 六、红线确认

- ✅ 本方案零代码、零数据、零 git 改动产出（仅 docs/SOLUTION_PLAN.md + docs/TASKS.md 标注）
- ✅ 未跑任何探针 / headless 验证（验证方式均为「执行者阶段」动作，已逐任务写明）
- ✅ 大纲「腐化巨树藤蔓/毒雨」差异：以数据为准（invoker/predator），登记不臆造（PRE #8，上轮已登记，本轮无新差异）
- ✅ 批次 C 完成判据（D15）已明确，供 #1/#4 复核

---

## 七、执行结果：完成（2026-08-07 15:5x · #3 第 26 轮执行）

**批次 A（`d3b95a0`）**：`enemy_projectile.gd` 新建（纯 Node2D + 距离判定禁物理 D8 + 挂 Boss 节点 D1）+ `_parse_attack` 8 型指令纯函数。import 零错误 + day17_elite 39/39。

**批次 B（`afe5ef7`）**：phases 状态机（initialize 透传 / `_reset_boss_phase(0)` / take_damage D6 先行 / `_check_phase_transition` / 阶段横幅 / die 击杀登记）+ attacks 执行器（`_process_boss_attacks` / summon / spread / barrage 8 向×3 波 / aoe 120px / charge 命中倍率 D2 / all_attacks_2x D3）+ scale×2 视觉过渡 D7。回归 39/39 + 20/20。

**批次 C（本轮收口）**：GameManager Boss 接入（`boss_killed` / `register_boss_killed` / `_show_boss_banner` / route.flags boss_encountered·boss_defeated / reset 清零）+ 探针 `day18_19_boss_check.gd` **48/48 CLEAN**（§1 数据 / §2 状态机 / §3 指令 / §4 弹丸 / §5 回归）+ 回归十五件套 15/15 全绿 + baseline **BASELINE CLEAN** + verify 36/36。

**探针同步 1 处**：`day14_15_route_check.gd` FIXED_ROUTE `const`→`var`（Godot 4 const Dictionary 只读；T4 `route["flags"]` 写键触发 `Invalid assignment on read-only value`，探针端同步，代码零回退）。

**执行中问题 2 项（已闭环，登记备查）**：
1. 探针 `preload` enemy_projectile.gd 编译失败（`--script` 编译期 autoload 标识符 `GameManager` 未注册）→ 改运行期 `load()`（enemy.gd 同范式）。
2. 探针 `Node.get(key, default)` 双参误用（Object.get 单参 vs Dictionary.get 双参）→ 修正 + `_clear_enemy_container` 立即销毁防 queue_free 延迟污染断言。

**主观项（交 #5 登记，不阻塞）**：Boss 战难度曲线 / 阶段切换表现力 / Boss 视觉辨识度 / 弹幕躲避手感。**D18-19 挂账 🔴🔴 解除**。
