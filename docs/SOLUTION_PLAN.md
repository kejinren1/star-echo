# 方案计划（2026-08-13 · 第 20 轮）

## 当前开发日：阶段 F 续段（F1-散收尾批 + F3 状态机规范化 + Boss 技能与效果系统 BS-A~D）

> **git 实测**：HEAD=`010f522`（PLAYTEST 增量 #63），工作区在途仅 docs 5 M + 未跟踪（BOSS_SKILL_SPEC.md / art_ai / ComfyUI docx / 测试立绘/）——**零游戏代码在途，不碰**。
> **F 区块状态**：F0 / F1.0 / F1-A~G（含 F1-G-尾）/ F2 全 [x] ✅（`990e8c8`）｜ **F1-E [ ] 🏠 主窗口承接（#3 勿开工，本方案不重复拆解）**｜ F3 [ ]（#2 第 45 轮已函数级拆解）｜ F1-散 [ ]（#2 第 45 轮拆解）｜ BS A~D [ ]（#2 第 45 轮拆解）｜ F4/F5 未开始。
> **P0 检查（P0 调度硬性输入）**：追踪区增量 #63（08-13 00:4x）= 无待处理反馈轮 · TEST_REPORT #44（35/35 · 866 断言全绿）→ 🔴 P0 无新增 / 🟠 无用户拍板调度指令 → **无新机器可验证 P0 需拆**；美术资源策略（08-07 拍板）遵守（本轮零美术生成）。
> **执行输入**：#3 以本方案为准执行；F3/BS 均按「**行为零改动原则**」只收口写法不改语义（防回归），数据管线铁律 = 改数只改 docs/GameData.xlsx → tools/excel_export.py（--check-only 校验）→ 探针；data/*.json 禁手改。

## §0 执行序总览（#3 每批次一收口 commit 带 T 编号）

| 序 | 批次 | 内容 | 依赖 | 回归基准（收口时） |
|---|---|---|---|---|
| 0 | **F1-散** | 数值参数化散条目（T-007/008/009/011/012/013/015/053） | 无（独立，先行释放 F1 剩余债） | 35 件套 ≥866 + day30_f1_scatter ≥12 |
| 1 | **F3-A** | CODE_STYLE + GM 状态机收口（T0~T3） | 无 | 35 件套 ≥866 |
| 2 | **F3-B** | enemy + player 状态机（T4~T6） | F3-A | 35 件套 ≥866 |
| 3 | **F3-C** | audio 枚举 + 双探针 + EXIT（T7~T9） | F3-A/B | 35 + day30_f3_compliance + day30_f3_flow |
| 4 | **BS-A** | 效果系统统一地基（A1~A5） | 无（与 F3 独立，但改 enemy.gd 与 F3-B 同文件 → 顺序执行防冲突） | 35 + day30_effect ≥16 |
| 5 | **BS-B** | SkillExecutor 框架 + circle 最小闭环（B1~B4） | BS-A | 35 + effect + boss_skill ≥14 |
| 6 | **BS-C** | boss_skill/boss_pattern 表 + Boss pattern 状态机（C1~C4） | BS-B + **F3-T4 已落地** | 35 + 双探针 |
| 7 | **BS-D** | 难度缩放 + 扩展技能 + 免疫 UI（D1~D4） | BS-C | 全量 + baseline CLEAN |

> 批次 0~3 为「代码边界收拢」整块（F3 完整收口后回归 37 件套先稳定）；批次 4~7 为独立大系统（BS）整块推进。F1-E 维持主窗口承接不占 #3 窗口。

---

## §1 F1-散 收尾批（数值参数化 · ⚠️ 数值零变化仅抽表，断言零漂移预期）

> **⚠️ 方案修正（#2 拆解 2 处实测笔误，历次先例）**：
> ① **通关回血行号 :184 → 实测 :247**（game_manager.gd `_apply_wave_heal()` :242-247，`player.heal(float(player.max_health) * 0.5)` :247；:184 为 `_set_state(GameState.BATTLE)` 无关）；
> ② **max_waves 兜底口径修正**：实测 `DataLoader.get_max_waves()` :332-337 = **从 waves.json 键推导最大值**（非硬编码 20），game_manager.gd:45/:175 + wave_manager.gd:23/:30 的 20 为**声明/兜底字面量** → T-008 参数化对象 = **兜底默认值 20（4 处字面量）**，**维持 waves.json 推导为主源**（勿把 get_max_waves 改为读 stats.json——会使 max_waves 与 waves 键脱钩，未来加键不同步）。

### 任务 1：F1-散-1【W2】Excel 抽表（数据侧）
- 文件：docs/GameData.xlsx（stats sheet + enemies.scaling 扩展段）+ tools/data_schema.py + tools/excel_export.py
- 改动：stats sheet 新增 `combat` 段（T-007 wave_clear_heal_ratio=0.5 / T-008 max_waves=20 / T-013 i_frames=0.4·dodge_cap=0.9·debug_damage_mult=0.001 / T-015 knockback_decay=0.5·contact_cooldown=0.5·armor_cap=0.75）+ `physics` 段（T-011 projectile_mask=2·projectile_radius=4.0）+ `skills` 段（T-012 fireball_speed/lifetime/pierce/radius，**现值以 skill_controller.gd:118-130 实测为准**）+ enemies.scaling 扩展（T-009 charge_speed_mult/charge_windup/charge_duration，**现值以 enemy.gd:421/425/434 实测为准**）；data_schema 注册映射；excel_export 导出 → 仅 stats.json/enemies.json 字段增，其余 JSON 零漂移（--check-only 先行）
- 风险：中——Excel 管线已稳定（F1-G-尾 双行表头后零漂移先例），但新增段若与既有段键冲突会静默覆盖 → 导出后 diff 核对新增键 + 8 JSON 零漂移断言；⚠️ 改前确认 docs/ 下无 `~$GameData.xlsx` 锁（WPS 未开），有锁即阻塞上报勿强改
- 验证：tools/excel_export.py --check-only 通过 + 导出后 git diff 仅 stats.json/enemies.json + day30_data_effect_check 全绿

### 任务 2：F1-散-2【W1】DataLoader 接口
- 文件：scripts/autoload/data_loader.gd（仿 get_stats_shop :386 先例）
- 改动：新增 `get_stats_combat() -> Dictionary` / `get_stats_physics() -> Dictionary` / `get_stats_skills() -> Dictionary` + scaling 扩展键透传（enemy_scaling 段已有）；**缺段兜底默认值 = 现硬编码值**（combat 兜底 {wave_clear_heal_ratio:0.5, max_waves:20, i_frames:0.4, dodge_cap:0.9, debug_damage_mult:0.001, knockback_decay:0.5, contact_cooldown:0.5, armor_cap:0.75} / physics 兜底 {projectile_mask:2, projectile_radius:4.0} / skills 兜底以 skill_controller 实测现值）——兜底=当前行为值，防 Excel 未导出时行为漂移
- 风险：低——纯新增接口零消费点改动
- 验证：探针 F1-散-4 §2 缺表兜底断言（白盒删段 → 接口返回兜底值）

### 任务 3：F1-散-3【W1】消费点替换 8 处（实测行号）
- 文件：game_manager.gd / wave_manager.gd / enemy.gd / projectile.gd / skill_controller.gd / player.gd / enemy_spawner.gd
- 改动：① game_manager.gd:247 通关回血 `0.5` → get_stats_combat().wave_clear_heal_ratio（F-05 功能保留，数值改读表）② game_manager.gd:45/:175 + wave_manager.gd:23/:30 兜底 20 → get_stats_combat().max_waves（**主源维持 get_max_waves() waves 推导**）③ enemy.gd:421/:425/:434 冲锋倍率/蓄力/时长 → scaling 扩展值 ④ projectile.gd:47/:56 collision_mask/半径 → get_stats_physics ⑤ skill_controller.gd:118-130 火球 speed/lifetime/pierce/radius → get_stats_skills ⑥ player.gd:471 金手指受伤倍率 0.001 / :649 闪避 clamp 0.9 / take_damage 无敌帧 0.4 → get_stats_combat ⑦ enemy.gd:190/:212/:762 击退衰减/接触冷却/护甲上限 → get_stats_combat（⚠️ :762 与 F1-C 平直减公式并存——**护甲上限钳制数值读表，公式本身零改动**）⑧ **T-053**：enemy_spawner.gd:126 `stats.wave_number` 补键 → `get_scaled_enemy()` 返回值补该键（Boss 召唤物路径可读，消费点缺省零改动）
- 风险：中——8 处跨 7 文件，任何一处兜底值 ≠ 现硬编码值即行为漂移 → 逐处替换后跑 day30_f1_scaling / day13 / day4 等数值锚点探针；⑦ 处 :762 护甲钳制与 F1-C 公式共存易混淆，替换前后数值断言比对
- 验证：F1-散-4 探针 + 回归 35 件套（数值锚点探针零漂移=抽表正确性的最强证据）

### 任务 4：F1-散-4【W1】配置生效探针（新建 tools/day30_f1_scatter_check.gd ≥12 断言）
- 文件：tools/day30_f1_scatter_check.gd（新建）
- 改动：四段——§1 端到端生效（wave_clear_heal_ratio 改 0.5→0.6 → 导出 → 断言 _apply_wave_heal 实际回血 60%；**⚠️ 断言后必须改回 0.5 并重新导出（强制动作，防数值漂移污染玩家游戏）**）/ §2 读表锚点（max_waves 读表 / 火球参数 / 冲锋倍率 / wave_number 补键在位）/ §3 缺表兜底（白盒删段断言接口返回兜底值）/ §4 回归抽样（day13 攻速 / day4 数值锚点）
- 风险：低——探针只读+白盒，唯一风险 = §1 改 Excel 后忘改回 → 方案强制「改回+重导出」为收口步骤之一
- 验证：探针自跑 ≥12/12 CLEAN

### 任务 5：F1-散-EXIT【W5】回归收口
- 文件：docs/TECH_DEBT_ISSUES.md
- 改动：全量回归 35 件套 ≥866 + day30_f1_scatter ≥12 + baseline **BASELINE CLEAN** + T-007/008/009/011/012/013/015/053 转已收口
- 风险：低
- 验证：回归脚本 36 项一键跑通

---

## §2 F3 状态机规范化（行为零改动 · 纯代码层零数值）

> 总则（TECH_DEBT_PLAN §2.6 + §8）：仅两种形态——① 扁平流程态 = enum + match + `_transition(next, context)`；② 行为/表现态 = enum + 状态表 Dictionary。禁多 bool 组合 / 字符串状态值 / int 字面量状态 / 状态切换散落多处。

### 任务 1：F3-T0【W1】docs/CODE_STYLE.md 状态机规范章节（批次 A 首步 · 新建）
- 文件：docs/CODE_STYLE.md（新建，当前不存在）
- 改动：写入 §2.6 两种固定形态 + 四条禁令 + §8.6 能力上限（单机 ≤8 态 / 转移条件 ≤10 / 状态表 ≤20 行，超限停手先问）+ F5 复用为评审清单
- 风险：低——纯文档
- 验证：F3-T8 合规探针 §5 断言文件存在且含关键词

### 任务 2：F3-T1【W1】GM `_set_state` → `_transition(next, context)` 升级（T-031 收口）
- 文件：scripts/autoload/game_manager.gd（`_set_state` :146-151 / 调用点 8 处 :184/:209/:229/:265/:309/:419/:472/:497——**实测与拆解一致**）
- 改动：签名升级 `_transition(next: GameState, context: Dictionary = {})`（**形参 int → GameState 类型标注**；同值早退幂等保留 :147-148 / 赋值 :149 / `_state_context` 存储 / emit :150 保留）——**⚠️ signal state_changed 保留单参签名（:13 `signal state_changed(new_state: GameState)`，hud._on_state_changed 已消费，改签名破坏消费者）**；context 经新查询接口 `get_state_context() -> Dictionary` 读取；8 处调用点改 `_transition(`，按需传 context（SHOP 带 `{"from_battle": _shop_from_battle}` 等，BATTLE/MENU 可传 {}）；**关键决策：T9「非法序列拒绝」定案 = 不做硬拦截**（引入合法转移矩阵属行为变化，违反行为零改动硬约束）——_transition 保持任意态可切（现状语义），探针断言「非法跳态调用安全不崩 + 状态不损坏 + 后续合法流转正常」，**合法性矩阵正式启用留 BS-C 决策点**
- 风险：中——8 处调用点改名 + 签名类型收紧；同值早退保留防重复 emit；grep `_set_state` 零残留；hud 消费 state_changed 的 1 参签名不动
- 验证：grep `_set_state` 零残留 + F3-T9 状态流探针（context 透传 / 信号次数值 / 非法调用安全）

### 任务 3：F3-T2【W1】GM 正交维度归一（T-032）
- 文件：scripts/autoload/game_manager.gd（route.is_empty() 裸判断 / is_boss_wave 置位复位 / _shop_from_battle 置位复位）
- 改动：① 派生查询 `_is_route_mode() -> bool`（= not route.is_empty()）替代裸判断——**⚠️ 实测 6 处非 5 处：:182/:223/:252/:298/:368/:486（拆解漏 :298 难度系数段 `if not route.is_empty() else 0`，一并替换）**；② is_boss_wave（置位 :205/:207 · 复位 :200/:499）/ _shop_from_battle（置位 :254/:417-418 · 复位 :505）赋值点收敛 → 移入 _transition 相邻的 BATTLE/SHOP 转换点统一赋值（**行为等价：置位/复位时机与现状一致**，禁合并或延迟）；③ 语义注释入 CODE_STYLE（正交维度 = context 承载，非独立状态）
- 风险：中——赋值点收敛若时机偏差会导致 is_boss_wave 状态错位（Boss SFX :208 依赖置位）→ 改后跑 day24_audio / day18_19_boss 探针 + 白盒 BATTLE 流转断言
- 验证：grep `route.is_empty()` 仅 _is_route_mode 内 + F3-T9 双路径等价断言（旧制/路线制）

### 任务 4：F3-T3【W1】route 节点类型枚举化（T-036 之 GM 侧）
- 文件：scripts/autoload/game_manager.gd（match node_type: :294-311 / prev_type :416-417）
- 改动：新建 `enum RouteNodeType { BATTLE, ELITE, BOSS, SHOP, EVENT, UNKNOWN }` + 转换纯函数 `route_type_from_string(s: String) -> RouteNodeType`（未知值 UNKNOWN + push_warning，**数据层字符串→枚举单点转换**）；消费点 match 改枚举；**routes.json 数据零改动**（仅代码侧收敛）
- 风险：低——字符串 match 的枚举化等价改写；:294 的 `match node_type:` 分支内容逐一对照；未知值路径现状行为 = 默认分支（不崩），UNKNOWN 保留该语义
- 验证：grep 状态赋值处字符串 match 零残留（route_type_from_string 单点白名单）+ day14_15_route 探针 53/53 零改动

### 任务 5：F3-T4【W1】enemy Boss 阶段机 → 阶段枚举 + 状态表（T-033）
- 文件：scripts/enemy/enemy.gd（`_current_phase_idx: int` :155 / `_check_phase_transition` :578-583 / `_reset_boss_phase` :586-612 / `_show_boss_phase_banner` :614 / die 内 :790-791）
- 改动：`_current_phase_idx: int` → `enum BossPhase { P1, P2, P3 }` + `_phase: BossPhase` + **PHASE_TABLE 状态表（per §8.5 范式：skills/weights/ai_interval——⚠️ 由 `phases` 数据（enemies.json 透传）构建，勿硬编码重复数据：phases.size()==1 → 仅 P1；==2 → P1/P2；≥3 → P1/P2/P3 映射）** + `_transition_phase(next: BossPhase)` 统一入口（同值早退 + 赋值 + 进入钩子，`_reset_boss_phase` 侧写保留）；`_check_phase_transition` :579 for 循环改枚举推进（`_phase` 单调递增语义与 `_current_phase_idx + 1` 一致）；**⚠️ 债清单同步：T-033「int 下标 + 4 个并行 bool」描述过时（实测 = `_current_phase_idx: int` + `phases: Array` 数据，无并行 bool）→ 收口时登记修正 TECH_DEBT_ISSUES**
- 风险：中高（本批最高）——Boss 阶段切换是战斗核心路径（阈值切换 :790-791 → die 时检查），枚举化必须与 phases.size() 动态数据对齐（invoker/predator 各 2 阶段 vs 3 阶段枚举的映射边界）→ PHASE_TABLE 构建时对 phases.size() 边界断言（0/1/2/≥3 四态）；`_reset_boss_phase(idx)` 现有形参 int 改 BossPhase 或保留 int 转发（**推荐保留 int 转发防内部调用点漂移，仅 `_phase` 字段与推进逻辑枚举化**）
- 验证：day18_19_boss_check 48/48 **零改动**（行为等价 = 验收硬门槛）+ day21_22 38/38（Boss scale/换皮锚点）

### 任务 6：F3-T5【W1】enemy `_is_dying` 冗余删除（T-035）
- 文件：scripts/enemy/enemy.gd（:126 声明 / :173/:177/:199/:265 守卫 / :797 置位）
- 改动：删 `_is_dying: bool`，守卫 `if not is_alive or _is_dying:` → `if not is_alive:`（die :795 起 is_alive=false 后即进入死亡态，重复 die 由 is_alive 拦截）
- 风险：中——:797 `_is_dying = true` 置位位于 die 内 is_alive=false 之后（:795-797 顺序需实测确认置位在 is_alive=false 之后，若置位在 is_alive 赋值前则语义变化——**执行时先读 :793-800 确认顺序再删**）；四守卫中 :173/:177 为死亡/受击路径需重点回归
- 验证：grep `_is_dying` 零残留 + 死亡流程探针（die 幂等/清理/掉落单次——day4/day13/day18_19 覆盖）

### 任务 7：F3-T6【W1】player 行为态枚举化（T-034）
- 文件：scripts/player/player.gd（`_is_walking` :114 / 动画播放 :336/:344/:361 / `_update_animation` :327-331 区）
- 改动：`_is_walking` 归并 → `enum PlayerState { IDLE, WALK, ATTACK, SKILL, HIT, DEAD }` + `_state: PlayerState` + `const ANIM_MAP := {PlayerState.ATTACK: "attack", PlayerState.SKILL: "skill", PlayerState.HIT: "hit", PlayerState.WALK: "walk", PlayerState.IDLE: "idle"}` + `_transition_state(next: PlayerState)` 统一入口（进入钩子侧写 `_play_attack_anim/_play_skill_anim/_play_hit_anim`）；**⚠️ 保留项：`_last_stand_active`（:105）= F-13 机制标志不进状态机；`_facing_left`（:116）= 朝向不进状态机（两处现有 bool 保留，进 F3-T8 白名单）**；`_update_animation` :327-331 的 moving 判定改走 `_state`（WALK/IDLE 互切走 _transition_state）
- 风险：中——动画状态机与 F-32/F-33（索敌门控/翻转）耦合：:234/:357 复位点（idle 复位）必须保留语义；day29_elin 14/14 + day29_attack 20/20 **零改动**为验收硬门槛
- 验证：day29_elin_anim_check 14/14 + day29_attack_check 20/20 零改动 + grep `_is_walking` 零残留

### 任务 8：F3-T7【W1】audio int 字面量 → GameState 枚举（T-005/T-036）
- 文件：scripts/autoload/audio_manager.gd（:90-95 match state:）
- 改动：`match state:` 分支 `0:`（:91）→ `GameState.MENU` / `1, 2, 3:`（:93）→ `GameState.BATTLE, GameState.SHOP, GameState.ROUTE_SELECT` / `4:`（:95）→ `GameState.GAME_OVER`（GameState 为 GameManager Autoload 枚举，audio 侧引用常量，**⚠️ AudioManager 第 3 Autoload 依赖 GameManager 先加载——project.godot autoload 顺序已定，引用枚举编译期可见**）
- 风险：低——等值改写；唯一注意 = 枚举定义在 game_manager.gd 顶部（:8 区），audio 侧 `GameState.X` 直接引用即可
- 验证：day24_audio_check 14/14 零改动 + BGM 状态机行为等价（白盒驱动 5 态）

### 任务 9：F3-T8【W1】状态机合规探针（新建 tools/day30_f3_compliance_check.gd ≥12 断言）
- 文件：tools/day30_f3_compliance_check.gd（新建）
- 改动：静态扫描——① `current_state = ` 仅 _transition 内 1 处（:149 赋值，其余零残留）② `_set_state` 零残留（已改 _transition）③ 状态赋值处无字符串字面量（route_type_from_string 单点白名单）④ **禁新增 bool 行为标志**：扫描 scripts/ `var \w+: bool` 声明 vs 白名单（_last_stand_active / _facing_left / debug_cheat / is_boss_wave / _shop_from_battle / _is_dying 已删 / 其他机制标志——**执行时先扫 F2 收口现状清单定白名单**，白名单外未注释新增 bool → 失败）⑤ CODE_STYLE.md 存在且含两形态+禁令关键词 ⑥ audio match 无 int 字面量
- 风险：低——只读扫描；⚠️ 断言 ④ 白名单需在批次 C 执行时先实测全项目 bool 清单（防误报/漏报）
- 验证：探针自跑 ≥12/12 CLEAN

### 任务 10：F3-T9【W1】状态流探针（新建 tools/day30_f3_flow_check.gd ≥14 断言）
- 文件：tools/day30_f3_flow_check.gd（新建）
- 改动：白盒驱动 GM 状态流转——合法序列 MENU→ROUTE_SELECT→BATTLE→SHOP→BATTLE→GAME_OVER→MENU（逐一 `_transition` + 断言 current_state 与 context）+ **非法序列安全断言（方案修正：不做硬拒绝，断言 GAME_OVER→BATTLE 等跳态调用不崩 / 状态不损坏 / 可继续合法流转——因 _transition 不引入合法性矩阵（行为零改动），若现状有早退路径则断言早退）** + route 模式 vs 旧波次制双路径等价 + state_changed 信号次数/值核对 + get_state_context() 读取
- 风险：低——白盒直驱动不依赖真实游戏流程时序（沿用 day30_f2 范式）
- 验证：探针自跑 ≥14/14 CLEAN

### 任务 11：F3-EXIT【W5】批次 C 尾收口
- 文件：docs/TECH_DEBT_ISSUES.md
- 改动：grep 验收三连（状态切换单一入口 / 无字符串状态 / 无新增 bool 标志）+ 双探针全绿 + 回归 **35 件套 ≥866 + day30_f3_compliance + day30_f3_flow** + baseline **BASELINE CLEAN** + T-031~036 转已收口
- 风险：低
- 验证：回归 37 项一键跑通

---

## §3 Boss 技能与效果系统（BS-A~D · 规格唯一来源 docs/BOSS_SKILL_SPEC.md · 决策点 O1~O5 全拍板）

> **规格入库提醒**：BOSS_SKILL_SPEC.md 当前未入库（工作区 ?? 状态），#3 首轮提交顺手入库（docs 单独 commit 或与批 A 同 commit 均可）。
> 批次依赖（#2 已定）：A（效果地基）→ B（circle 最小闭环）→ C（pattern 表 + Boss 状态机，**依赖 F3-T4**）→ D（难度缩放 + 扩展 + 免疫 UI）。F3-A/B 完成后即可启动 BS-A。

### BS 批 A · 效果系统统一（§7-1 地基 · 依赖无）

#### 任务 1：BS-A1【W2】elements sheet 升级为 effect 表（§4.3）
- 文件：docs/GameData.xlsx（elements sheet）+ tools/data_schema.py + tools/excel_export.py
- 改动：elements sheet 字段升级（id/type 即时·持续/duration/tick_interval/value/scaling_attr+ratio/target_attr/max_stacks/icon/vfx/sfx），现有 5 元素状态（fire/ice/lightning/poison/plasma）字段映射进统一结构**数值不变**；data_schema 注册；excel_export 重生成 elements.json（结构升级，数值零漂移断言）
- 风险：中——elements.json 被 enemy.gd:257-290 / skill_controller.gd:99-160 / 探针 day17_elite / day24_f13 消费，结构升级后消费方在 BS-A2/A3 才迁移 → **A1 与 A2 必须同批次落地**（防中间态漂移）；改前 diff 记录 elements.json 现值
- 验证：excel_export 校验 + elements.json 数值零漂移 diff + day17_elite 39/39

#### 任务 2：BS-A2【W1】通用 StatusComponent 抽取（§6.2-2）
- 文件：新建 scripts/systems/status_component.gd + scripts/enemy/enemy.gd（:257-290 状态机迁入）+ scripts/player/skill_controller.gd（:99-160 燃烧 dps 并入）+ player.gd（挂组件）
- 改动：Node 组件（效果实例列表 + tick 循环 + **O1 叠加规则**：同源刷新不叠层 / 异源独立实例各自 tick / max_stacks 上限 + 到期还原 target_attr + 查询剩余秒数/层数接口）；enemy 状态机迁入（**行为等价：DoT 取更长+更高防滚雪球 → O1 新规则，这是拍板的行为变化，需登记**）；skill_controller 燃烧 dps 并入（删重复口径）；player/Boss 挂同一组件
- 风险：高（本批最高）——⚠️ **O1 叠加规则变化 = 行为变化**（现状「同源/异源都取更长+更高」→ 拍板「同源刷新/异源独立」）：对既有数值锚点探针的冲击需逐一核（day17_elite 精英能力 / day24_f13 on_crit / day4 燃烧）；doT dps 口径三处（enemy/skill_controller）必须收敛为同一组件同一公式；enemy.gd:257-290 与 F3-B 同文件（但区域不重叠，顺序执行已规避）
- 验证：day30_effect_check ≥16 四段 + day17_elite / day24_f13 回归核销（**行为变化点明确列 changelog 供 #5 主观回归**）

#### 任务 3：BS-A3【W1】统一施加入口 apply_effect（§6.2-3）
- 文件：新建 scripts/systems/effect_apply.gd（或 StatusComponent 静态入口）+ weapons.json（Excel weapons 表对应列）+ desc_builder.gd
- 改动：`apply_effect(source, target, effect_id, params)` 统一入口（武器特殊效果 / 被动 / 玩家技能 / Boss 技能全走它）；weapons.json:1756「施加中毒(5秒)」文本级 → 结构化 effect 引用（**Excel weapons 表新增 effect 引用列**）；**O2 软控运行时补齐**：减速（改 move_speed）/ 麻痹（禁行动）/ 减防（改 defense）三类型真实落地
- 风险：中——weapons.json 效果列改造走 Excel 管线；desc_builder 中文映射同步（描述从 effect 表生成，避免双 % 类显示回归 day18_feedback5 断言）；软控三类型新消费点（move_speed/行动守卫/defense）需在 player/enemy 相应消费处接入
- 验证：day30_effect §3 三类型软控断言 + day18_feedback5 27/27（tooltip 描述零回归）

#### 任务 4：BS-A4【W1】HUD 玩家状态栏（O4）
- 文件：scripts/ui/hud.gd
- 改动：玩家状态栏实时显示 StatusComponent 剩余秒数/层数（可读性原则，仿 Boss 血条挂 UI 先例）
- 风险：低——纯新增 UI 显示，零逻辑改动；hud 布局现有约束（640×360 视口）
- 验证：探针断言状态栏节点存在 + 数值更新（白盒挂效果→读 UI 文本）

#### 任务 5：BS-A5【W1】探针 tools/day30_effect_check.gd（≥16 断言四段 · §11 验收 3/4/5 机器侧）
- 文件：tools/day30_effect_check.gd（新建）
- 改动：DoT 跳数符合 interval / 同源刷新不叠层 / 异源独立各自 tick / max_stacks 上限 / 到期移除并还原属性（减防恢复）/ 三类型软控行为（减速·麻痹·减防）/ 免疫表（硬控免疫软控保留）
- 风险：低
- 验证：≥16/16 CLEAN

#### 任务 6：BS-A-EXIT【W5】回归
- 文件：—
- 改动：35 件套 ≥866 + day30_effect ≥16 + baseline **BASELINE CLEAN**（StatusComponent 抽取不动行为，前序探针零改动预期；O1 规则变化点除外——单独 changelog 交 #5）
- 风险：中——O1 行为变化若致前序探针红，按 changelog 逐条核销（判断为「拍板行为变化」则同步探针口径并登记，非缺陷）
- 验证：回归 36 项

### BS 批 B · 技能执行器框架 + circle 最小闭环（§7-2 · 依赖批 A）

#### 任务 7：BS-B1【W1】SkillExecutor 接口框架（§3.1）
- 文件：新建 scripts/boss/skill_executor.gd + scripts/boss/boss_skill_factory.gd
- 改动：`class_name SkillExecutor extends Node`（enter(p)/tick(delta, p)/exit(p) 三接口）+ 工厂 `make(type: String) -> SkillExecutor`（未知 type push_warning 返回 null）
- 风险：低——纯新文件零回归（⚠️ 新 class_name 需重建 global_script_class_cache，headless --editor --quit-after 120 扫描，历史教训）
- 验证：探针实例化 + 工厂未知 type 返回 null

#### 任务 8：BS-B2【W1】circle 类型执行器（§2.1 四拍子最小闭环）
- 文件：新建 scripts/boss/exec_circle.gd
- 改动：telegraph（预警收缩环，warn_style 数据驱动）→ resolve（resolve_delay 结算：圈内伤害圈外无伤，effects 列表消费）→ recover（后摇）；参数全来自 params（radius/telegraph/resolve_delay/effects/cooldown），**Boss 不认识技能**（只挑 pattern 行）
- 风险：中——圈内/圈外判定禁物理查询（沿用 F-19 距离判定范式）；VFX 占位（美术策略：色块/发光，豁免色号编码）
- 验证：day30_boss_skill_check §1 四拍子闭环断言

#### 任务 9：BS-B3【W1】公平底线公式（§2.2）
- 文件：新建或并入 exec_circle.gd / 工具函数
- 改动：`func fair_telegraph(radius: float, player_speed: float) -> float`（t_w ≥ 2r/v + 0.4s）——难度缩放缩短 t_w 时钳制不得低于底线；探针内白盒单测
- 风险：低——纯函数
- 验证：探针 §3 底线断言（含 player_speed=300 / radius=120 → t_w ≥ 1.2s 锚点）

#### 任务 10：BS-B4【W1】探针 tools/day30_boss_skill_check.gd（≥14 断言三段 · §11 验收 1/2）
- 文件：tools/day30_boss_skill_check.gd（新建）
- 改动：圈技能走完 预警→结算→后摇 / 圈内伤害圈外无伤 / t_w ≥ 底线断言 / override 变种参数生效 / 数据驱动（改 Excel 数值→导出→行为变化，**⚠️ 断言后改回基准值+重导出，同 F1-散-4 强制动作**）
- 风险：低
- 验证：≥14/14 CLEAN

#### 任务 11：BS-B-EXIT【W5】回归
- 文件：—
- 改动：35 件套 + day30_effect + day30_boss_skill + baseline **BASELINE CLEAN**
- 风险：低
- 验证：回归 37 项

### BS 批 C · boss_skill/boss_pattern 表 + Boss pattern 状态机（§7-3 · 依赖批 B + F3-T4）

#### 任务 12：BS-C1【W2】boss_skill / boss_pattern 表（§4.1/4.2）
- 文件：docs/GameData.xlsx（新增 boss_skill + boss_pattern sheet）+ tools/data_schema.py + tools/excel_export.py
- 改动：boss_skill sheet（id/type/telegraph/radius/arc/effects/resolve_delay/cooldown/vfx/sfx/warn_style）+ boss_pattern sheet（boss_id/skill_id/weight/phase 100/66/33/override/min_interval）+ **boss 表加 `resist` 列（O5 拍板：免疫表放 boss 表，pattern 只管循环）**；data_schema 注册；excel_export 生成 data/boss_skills.json + data/boss_patterns.json
- 风险：中——新增 sheet 走 Excel 管线（F1-G-尾 双行表头规范遵循）；初始数据以最小集落地（circle 技能 1-2 行 + pattern 引用）
- 验证：excel_export 校验 + JSON 生成 + 探针读表断言

#### 任务 13：BS-C2【W1】Boss pattern 状态机（§7-3 · 接 F3 模式）
- 文件：scripts/enemy/enemy.gd（Boss 段扩展）
- 改动：Boss 新增 pattern 循环（`_pick_and_cast` 权重随机 + **保底规则**：同技能不连续 2 次 / 大招有冷却）+ **phase 解锁**（phase 100/66/33 按 F3-T4 BossPhase 阈值表）；四拍子态（idle→telegraph→resolve→recover）复用 exec_* 执行器（F3 BossPhase 状态表扩展）——**⚠️ 与现有 phases attacks 指令执行器（_process_boss_attacks）并存策略：新 pattern 循环优先接管 Boss 技能释放，旧 attacks 指令执行器保留为降级路径（Boss 无 pattern 数据时零变化，防回归）**
- 风险：高（本批最高）——Boss 行为核心路径改动：day18_19_boss_check 48/48 覆盖现有 attacks 指令，新 pattern 循环必须在「无 pattern 数据」时行为完全等价（数据门控：boss_patterns.json 无该 boss_id → 走旧路径）；同技能不连续保底需状态记录（上次技能 id）
- 验证：day18_19_boss_check 48/48 零改动（无 pattern 数据兜底）+ BS-C4 §4 pattern 段（有 pattern 数据行为）

#### 任务 14：BS-C3【W1】变种 override 合成（§3.1）
- 文件：scripts/boss/（合成逻辑）
- 改动：params = DataLoader.get_boss_skill(row.id) + row.override 合并（同技能不同 Boss 微调，如精英放大半径）+ 难度缩放占位（批 D 接入，先恒 1.0）
- 风险：低——纯字典合并（merge 顺序：模板 → override 覆盖）
- 验证：探针 override 合成断言

#### 任务 15：BS-C4【W1】探针扩展
- 文件：tools/day30_boss_skill_check.gd（+§4）
- 改动：+§4 pattern 段（权重随机边界 / 保底不连续 / phase 解锁 / override 合成 ≥10 断言）
- 风险：低
- 验证：探针全绿

#### 任务 16：BS-C-EXIT【W5】回归
- 文件：—
- 改动：35 件套 + 双探针 + baseline **BASELINE CLEAN**
- 风险：低
- 验证：回归全量

### BS 批 D · 难度缩放 + 扩展技能 + 免疫 UI（§7-4/5/6 · 依赖批 C）

#### 任务 17：BS-D1【W1】难度缩放层（§5）
- 文件：scripts/boss/（难度合成）
- 改动：基础难度（关卡/波次，已有）× 动态难度（build 强度——装备越好系数越高）→ 难度系数合成（0.5~2.0）→ 参数倍率（预警↓伤害↑半径↑）→ **公平底线钳制（BS-B3）**；表里恒存基准值
- 风险：中——动态难度「build 强度」量化口径需定（建议 = 已装备武器数/被动数加权或研究等级，**执行时以最小可验证口径落地，过度设计禁**）；合成系数范围 0.5~2.0 钳制
- 验证：BS-D4 §5 系数合成/钳制断言

#### 任务 18：BS-D2【W1】fan / beam / charge / 打断 QTE 扩展（§2.3/2.4）
- 文件：新建 scripts/boss/exec_fan.gd / exec_beam.gd / exec_charge.gd（可含打断 QTE）
- 改动：同骨架换参数（exec_fan / exec_beam / exec_charge）；**QTE = 行为条件**（§2.4：打断窗口内玩家攻击命中 → 中断 resolve——星骸不做按键时机型 QTE）；均为批 B circle 同接口实现
- 风险：中——QTE「窗口内玩家攻击命中」需伤害事件挂点（enemy 受伤回调 → 打断窗口判定），与 F2 信号链（enemy died 等）正交新增；三条铁律（失败不致命/成功有回报/一场 ≤1-2 机制）
- 验证：探针 §5 扩展断言（fan/beam 走四拍子 + QTE 打断路径）

#### 任务 19：BS-D3【W1】免疫表 UI 收尾（O3/O5）
- 文件：scripts/ui/hud.gd（Boss 血条区）
- 改动：Boss 血条下挂免疫图标（BS-C1 resist 列消费，硬控免疫软控保留；Boss 免疫可视化——图标占位色块 + 文案，豁免色号编码）
- 风险：低——纯 UI
- 验证：探针 §6 免疫 UI 段（节点存在 + 数据源正确）

#### 任务 20：BS-D4【W1】探针扩展 + §11 验收全项核销
- 文件：tools/day30_boss_skill_check.gd（+§5/§6）
- 改动：+§5 难度段（系数合成/钳制生效）+ §6 免疫 UI 段；**§11 验收 1-7 全项机器侧清单核销**（1 四拍子闭环 / 2 数据驱动 / 3 效果统一 / 4 持续效果正确 / 5 免疫可读 / 6 难度缩放 / 7 回归+存档兼容 meta_progress 无破坏）
- 风险：低
- 验证：探针全绿 + §11 清单逐项打勾

#### 任务 21：BS-D-EXIT【W5】收口
- 文件：docs/TECH_DEBT_ISSUES.md + PLAYTEST 登记（#5 域）
- 改动：全量回归 + baseline **BASELINE CLEAN** + TECH_DEBT_ISSUES 登记新债或关单 + PLAYTEST 主观项登记（Boss 战体感交 #5：圈/扇形/QTE 交互手感、难度节奏、免疫可视化）
- 风险：低
- 验证：回归全量一键跑通

---

## §4 风险总表（高→低）

| 风险 | 等级 | 缓解 |
|---|---|---|
| BS-A2 StatusComponent 抽取 + O1 叠加规则变化（行为变化） | **高** | 批 A 内部 A1+A2 同批落地防中间态；changelog 逐条登记供 #5；前序探针按「拍板行为变化」口径核销非缺陷 |
| BS-C2 Boss pattern 状态机与现有 attacks 指令执行器并存 | **高** | 数据门控：无 pattern 数据 → 旧路径行为完全等价；day18_19_boss_check 48/48 零改动为硬门槛 |
| F3-T4 Boss 阶段枚举化（战斗核心路径） | **中高** | PHASE_TABLE 由 phases 数据构建（防硬编码漂移）；_reset_boss_phase 保留 int 转发；phases.size() 边界断言 |
| F3-T2 正交维度赋值点收敛（is_boss_wave 置位时序） | **中** | 置位/复位时机与现状逐点一致；day24_audio + day18_19 回归 |
| F1-散 8 处消费点替换（兜底值 ≠ 现值即漂移） | **中** | 兜底=现硬编码值；数值锚点探针全量回归 |
| F1-散-4 / BS-B4 探针「改 Excel 数值测试后忘改回」 | **中** | 方案强制「改回+重导出」为收口步骤（两处探针均标注） |
| Excel 锁（WPS 未关）阻塞改表 | **中** | 改前检查 `~$GameData.xlsx`；有锁即上报勿强改（F1-G-尾 教训） |
| 新 class_name（SkillExecutor 等）缓存未重建 | 低 | headless --editor --quit-after 120 扫描（历史教训） |
| F3-T8 bool 白名单误报 | 低 | 执行时先扫 F2 现状清单定白名单 |

## §5 观察点与请求（交 #3/#4/#5）

- **#3**：① BOSS_SKILL_SPEC.md 未入库（工作区 ??），首轮提交顺手入库；② 每批次收口 commit 带 T 编号（F3 用 T-031~036 系列 / F1-散 用 T-007/008/009/011/012/013/015/053 / BS 用 BS- 系列），commit 勿夹带用户在途资产（art_ai 工具链 / 测试立绘 / ComfyUI docx / xlsx 素材）；③ **F1-E 维持主窗口承接勿自行开工**（本方案不含 F1-E 拆解）；④ F1-散-3 ⑧ T-053 与 BS 系统执行顺序：wave_number 补键属 F1-散，Boss 召唤物路径消费点缺省零改动，BS 批 C 若遇召唤物相关需求以补键后读数为准
- **#4**：TEST_REPORT #45+ 覆盖本轮新探针（day30_f1_scatter / day30_f3_compliance / day30_f3_flow / day30_effect / day30_boss_skill），回归基准 35 件套 866 → 40 件套预期
- **#5**：BS 系统落地后主观项登记（Boss 战交互手感 / 免疫可视化 / 软控体感）；O1 叠加规则变化点（同源刷新/异源独立）交真人回归验证「异源双 dot 并存」

## §6 收口判据（全部达成即阶段 F 主体完成）

1. F1-散 EXIT：35 + day30_f1_scatter ≥12 全绿 + T-007/008/009/011/012/013/015/053 收口
2. F3 EXIT：grep 验收三连 + day30_f3_compliance + day30_f3_flow + T-031~036 收口（含 T-033 描述修正登记）
3. BS-D EXIT：全量回归 + §11 验收 1-7 核销 + TECH_DEBT 关单/登记
4. F1-E 仍主窗口承接（阶段 F 唯一外部项）；F4/F5 待 F3/BS 收口后按 TECH_DEBT_PLAN §4 拆解
5. baseline 全程 **BASELINE CLEAN**；存档兼容（meta_progress 无破坏性改动——BS-A2 挂组件不改存档结构）

---

## 执行结果（第 46 轮 · #3 执行者 · 2026-08-13 08:30 窗口）

**【完成】批次 0~7 全量收口（F1-散 + F3-A/B/C + BS-A/B/C/D = 8 批 12 commit）**

| 批次 | 收口 commit | 要点 | 回归 |
|---|---|---|---|
| 0 F1-散 | `734f79e` | stats.combat/physics/skills 三表 + enemy_scaling 冲锋 3 列；DataLoader 三接口+兜底；8 消费点替换（armor_cap 无消费点登记 T-054）；探针 19/19 双跑实证（0.6→0.5 改回强制） | 36/36 · 885 |
| 1 F3-A | `9981ca2` | CODE_STYLE.md + GM `_transition(next,context)`+get_state_context + `_is_route_mode` 6 处 + RouteNodeType 枚举化 | 36/36 |
| 2 F3-B | `1cead61` | enemy BossPhase 枚举+PHASE_TABLE+`_transition_phase`；`_is_dying` 删；player PlayerState+ANIM_MAP+`_transition_state` | 38/38 · 918 |
| 3 F3-C | `1696295` | audio GameState 枚举（Autoload 实例名）；合规 12/12 + 流 21/21；**修复 F3-A start_game 条件反转 bug** | 38/38 |
| 4 BS-A | `743a953` | effect 表升级（poison max_stacks=2）+ StatusComponent（O1 同源刷新/异源独立）+ apply_effect + O2 软控三类型 + HUD 状态栏；探针 18/18 | 39/39 · 936 |
| 5 BS-B | `8fa5d0f` | SkillExecutor 三接口 + 工厂 + exec_circle 四拍子 + fair_telegraph；探针 16/16 | 40/40 · 952 |
| 6 BS-C | `ad1bb87` | boss_skill/boss_pattern 表 + resist 列（O5）+ Boss pattern 状态机（数据门控降级）+ override 合成；探针 26/26（+§4） | 40/40 · 962 |
| 7 BS-D | 本轮 | 难度合成+钳制+公平底线 + fan/beam/charge/QTE + 免疫 UI；探针 49/49（+§5/§5b/§6/§11 验收核销） | **40/40 · 985** |

- **验证**：全量回归 **40/40 · 985 断言全绿**（runner 36→40 项）+ baseline 全程 **BASELINE CLEAN** + 每批次独立 commit 带 T 编号。
- **执行登记（偏差/修正）**：① F3-A start_game 条件反转（`_is_route_mode()` 应为 `not`）→ F3-C 修复 + 流探针固化；② audio GameState 枚举经 Autoload 实例名（方案「编译期可见」假设修正）；③ 方案「class_name SkillExecutor/StatusComponent」改无 class_name preload 范式（探针 --script 约束）；④ BS-A3 weapons.json:1756 中毒文本已随数据重生成消失 → 子项无对象；⑤ day18_19 探针适配（pattern 数据已入库 → 白盒清 `_patterns` 走旧路径断言，48/48 语义零变化）；⑥ T-033 描述修正登记（无并行 bool）。
- **行为变化（拍板口径，交 #5 真人回归）**：O1 叠加规则（同源刷新/异源独立+max_stacks，原「取更长+更高」废止）；poison max_stacks=2（异源双毒可叠）；Boss 技能伤害在 resolve_delay 后落地（QTE 窗口语义）。
- **主观项登记（#5 域）**：Boss 战圈/扇形/QTE 交互手感、难度节奏（0.5~2.0 系数）、免疫可视化标签、玩家状态栏观感、异源双 dot 并存体感——交 PLAYTEST。
- **阶段 F 状态**：F0/F1.0/F1-A~G/F2/F1-散/F3/BS-A~D 全 [x]；**F1-E 维持主窗口承接（未动）**；F4/F5 未开始（按 TECH_DEBT_PLAN §4 待拆）。G 系列框架拓展动工窗口 = 今日 18:00 后（#2 拆解）。
