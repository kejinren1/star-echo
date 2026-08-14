# 方案计划（2026-08-14 · 第 21 轮）

## 当前开发日：阶段 F（F4 上帝脚本拆分）+ G 系列框架拓展（R1-R6）

> **git 实测**：HEAD=`f70dcf4`（08-14 00:5x PLAYTEST 增量 #64），工作区在途仅 docs 5 M（LOOP_HEALTH/PROGRESS/TASKS/TECH_DEBT_ISSUES/TEST_REPORT）+ 未跟踪（art_ai 工具链含 `.ssh_tmp/` / ComfyUI docx / 测试立绘/）——**零游戏代码在途，不碰**。
> **F 区块状态**：F0 / F1.0 / F1-A~G（含 F1-G-尾）/ F1-散 / F2 / F3 / BS-A~D 全 [x] ✅（TEST_REPORT #45 = **40/40 · 985 断言**）｜ **F1-E [ ] 🏠 主窗口承接（#3 勿开工，本方案不重复拆解）**｜ **F4 [ ] 本轮方案定案（#2 第 46 轮已函数级拆解）**｜ F5 未开始（F4 收口后按 TECH_DEBT_PLAN §4 拆）。
> **G 系列**：规格 `docs/FRAMEWORK_EXPANSION.md`（唯一来源，已全文读）+ #2 第 46 轮函数级拆解完成 + **⏰ 动工窗口 08-13 18:00 已过 → 解锁执行**。
> **P0 检查（P0 调度硬性输入）**：追踪区增量 #64（08-14 00:5x · 反馈专员）= 无待处理反馈轮 · TEST_REPORT #45（40/40 · 985 断言全绿 · BS 系统全落地 + F-36 主观回归面登记）→ 🔴 P0 无新增 / 🟠 无用户拍板调度指令 → **无新机器可验证 P0 需拆**（F-01~F-36 全 🟢 已落地·待真人回归 = 主观项交 #5）；美术资源策略（08-07 拍板）遵守（F4 零美术 / G 系列占位色块+Label 零生成）。
> **执行输入**：#3 以本方案为准执行。**F4 = 行为零改动纯代码迁移（防回归）**；**G 系列 = 新功能占位先行（UI 排布合理即可）**。数据管线铁律 = 改数只改 docs/GameData.xlsx → tools/excel_export.py（--check-only 校验）→ 探针；data/*.json 禁手改（skill_tree.json 例外：tools 生成，见 §3-D2）。

---

## §0 执行序总览（#3 每批次一收口 commit 带 T/G 编号）

| 序 | 批次 | 内容 | 依赖 | 回归基准（收口时） |
|---|---|---|---|---|
| 0 | **F4-A** | enemy.gd 拆分（T1 移动 / T2 Boss 域 / T3 受伤掉落） | 无（最大块先行） | 40 件套 ≥985 + day17_elite/day18_19/day30_boss_skill 等硬门槛 |
| 1 | **F4-B** | GM 拆分（T4 SaveSystem / T5 金手指） | F4-A（同库不同文件，可并行但顺序执行防混批） | 40 件套 ≥985 + day27_meta 35/35 + day17_p0 20/20 |
| 2 | **F4-C** | player.gd 拆分（T6 AttributeController / T7 PlayerAnim） | F4-A/B | 40 件套 ≥985 + day30_p0_fix 15/15 + day29_elin/attack |
| 3 | **F4-D** | EXIT：数值快照零漂移 + 依赖图无环 + 全量回归 | F4-A/B/C | 40 件套 ≥985 + baseline CLEAN + T-047/048 收口 |
| 4 | **G-A** | R2 主菜单框架（G-R2-1~3） | 无（一切入口） | 40 + day30_g_mainmenu ≥8 |
| 5 | **G-B** | R1 大地图模式（G-R1-1~3）⭐ | 无（与 R2 并行，同批顺序执行） | 40 + day30_g_map ≥10 |
| 6 | **G-C** | R3 图鉴 + R4 回廊（G-R3-1~3 / G-R4-1~2） | **F4-B（SaveSystem 已拆，读写 meta_progress 扩展）** + G-A 入口 | 40 + codex ≥10 + archive ≥8 |
| 7 | **G-D** | R5 背包（G-R5-1~2） | 独立（暂停菜单入口） | 40 + day30_g_backpack ≥8 |
| 8 | **G-E** | R6 技能树（G-R6-1~4） | G-A + **F4-B**（meta_progress.skill_tree） | 40 + day30_g_skilltree ≥10 |
| 9 | **G-F** | G 系列 EXIT 收口 | G-A~E | 全量 + baseline CLEAN + PLAYTEST 主观项登记 |

> **关键执行序定案（§3-D1）**：**F4 全批（批次 0~3）先于 G 系列全批（批次 4~9）**——G-R3/G-R6 直接消费 F4-T4 拆出的 SaveSystem 读写 meta_progress 扩展字段；若先做 G 再拆 F4，SaveSystem 拆分时须迁移 G 新增的 codex/skill_tree 读写点，回归面重叠。F1-E 维持主窗口承接不占 #3 窗口。

---

## §1 F4 上帝脚本拆分（行为零改动 · 纯代码迁移 · 数值零漂移）

> 总则（TECH_DEBT_PLAN §6 拆分原则）：**每拆一个跑一次该模块专属探针，禁止一次拆完再验证**；组件一律 **无 class_name preload 范式**（StatusComponent 先例——探针 --script 不注册全局类名，历史教训）；新文件仅 instantiate+挂载+薄委托透传，**行为零改动**；F4 纯代码层拆分零数值，**不涉 Excel**。目标 = enemy/player/GM 全部 <400 行。

### 批次 A · enemy.gd 拆分（1097 行 → 目标 <400，T-047）

#### 任务 1：F4-T1【W1】移动行为拆分（批次 A 首步）
- 文件：新建 `scripts/enemy/enemy_movement.gd` + `scripts/enemy/enemy.gd`
- 改动：迁 `_update_behavior`（:417）/`_move_chase`（:458）/`_move_charge`（:464）/`_move_zigzag`（:486）/`_move_ranged`（:498）/`_move_heal`（:514）/`_move_spawn`（:525）/`_process_knockback`（:235）/`_try_contact_damage`（:254）→ enemy_movement.gd（无 class_name preload 范式；Behavior 枚举/BEHAVIOR_MAP/移速/击退状态经成员函数或注入引用访问）；enemy.gd 保留薄委托（`_physics_process` 内调 `movement.tick(...)`）；**行为零改动**，移动/击退/接触伤害语义逐一对应
- 风险：**高**——移动行为是每帧热路径（chase/charge 冲锋倍率 F1-散 T-009 已数据化、击退衰减 F-19、接触伤害判定），迁移若引用方式错位（组件持有 enemy 引用 vs enemy 持有组件）会导致空引用/状态丢失 → **组件构造时注入 enemy 实例引用，行为函数签名与调用点逐一对照**；`_process_knockback`/`_try_contact_damage` 涉及 hit_radius（D16 解耦锚点）与 contact_cooldown（F1-散 T-015 数据化）不可漂移
- 验证：day17_elite 39/39 + day14_15 53/53 **零改动** + day13 36/36（击退/接触段）+ day30_f1_scatter 19/19（冲锋参数消费点）

#### 任务 2：F4-T2【W1】Boss 域拆分（批次 A · T-047）
- 文件：新建 `scripts/enemy/enemy_boss.gd` + `scripts/enemy/enemy.gd`
- 改动：迁 Boss 专属段 20 个方法——`_parse_attack`（:372）/`_check_phase_transition`（:626）/`_transition_phase`（:636）/`_reset_boss_phase`（:647）/`_show_boss_phase_banner`（:675）/`_process_boss_attacks`（:695）/`_process_boss_patterns`（:728）/`_pick_and_cast`（:742）/`_active_pattern_pool`（:797）/`_compose_skill_params`（:811）/`_compose_difficulty_coeff`（:825）/`_interrupt_active_executor`（:836）/`_execute_attack`（:842）/`_boss_summon`（:857）/`_spawn_minion_node`（:886）/`_boss_spread`（:905）/`_boss_barrage`（:916）/`_boss_aoe`（:921）/`_spawn_enemy_projectile`（:932）→ enemy_boss.gd（BossController 组件，持有 enemy 弱引用 + phases/PHASE_TABLE/BossPhase 枚举引用）；enemy.gd 保留 `take_damage` 内 Boss 分支（存活命中阈值切换 + die 击杀登记）薄委托；**⚠️ F3-T4 枚举已收口、BS-C2 pattern 状态机已落地，拆分只移方法不移语义**
- 风险：**高（本批最高）**——Boss 域融合了 F3 阶段枚举 + BS 四拍子/难度合成/QTE 打断 + D18-19 attacks 指令 + pattern 数据门控降级，20 个方法互相调用（_pick_and_cast → _compose_skill_params → _execute_attack → _boss_summon...），迁移链必须整体搬移且保持互调关系；`take_damage` 内 Boss 分支（存活阈值切换 :790-791 区 + QTE interrupt 钩子）与 die 内 boss_killed 登记留在 enemy.gd 薄委托 → **迁移后立即跑双探针**
- 验证：**day18_19_boss_check 48/48 + day30_boss_skill 49/49 零改动硬门槛** + day21_22 38/38（Boss scale/换皮锚点）

#### 任务 3：F4-T3【W1】受伤掉落拆分（批次 A · T-047）
- 文件：新建 `scripts/enemy/enemy_damage.gd` + `scripts/enemy/enemy.gd`
- 改动：迁 `take_damage`（:956）/`die`（:975）/`_drop_rewards`（:997）/`_spawn_exp_popup`（:1007）/`_spawn_damage_number`（:1027）→ enemy_damage.gd（DamageNumberScript/掉落/经验弹窗迁入；enemy 保留血量字段 + 信号）；**⚠️ die 是击杀链路核心**（coin_value 掉落 F-16 / exp_value 经验 / boss_killed 登记 / G-R3 敌人首次击杀图鉴记录时机，**G 系列批 C 在此挂点**）
- 风险：**高**——die 内清理顺序（is_alive=false → 掉落 → 信号）被 day4/day13/day18_19 死亡流程探针全覆盖，迁移必须保持调用序；take_damage 还承载 F1-C 平直减护甲公式（max(amount-armor,1.0)）+ hit_radius 接触判定 + 暴击透传（F-11 伤害数字 is_crit）→ 数值语义零改动
- 验证：day4 21/21 + day18_feedback 16/16 死亡流程探针**零改动** + day13 36/36 + day30_p0_fix 15/15（护甲锚点）

> **批次 A 收口判据**：enemy.gd 残留 <400 行（状态声明/动画/初始化/兼容包装）+ 三组件探针全绿 + 回归 40 件套 ≥985。

### 批次 B · GameManager 拆分（686 行 → 目标 <400，T-046 续）

#### 任务 4：F4-T4【W1】存档系统 SaveSystem 拆分
- 文件：新建 `scripts/systems/save_system.gd` + `scripts/autoload/game_manager.gd`
- 改动：迁 meta 段 `_default_meta`（:590）/`load_meta`（:600）/`save_meta`（:630）/`get_meta_bonus`（:639）/`upgrade_research`（:653）/`add_research_point`（:669）+ 存档路径 var（D44 可覆写 meta_save_path）→ SaveSystem 组件（load/save/get_bonus/upgrade/add 纯逻辑，**存档格式零改动**——用户存档不损坏；⚠️ G 系列 meta_progress 扩展字段 codex/archives/skill_tree 由 SaveSystem 读写，**缺省空兼容旧档**）；GM 保留薄委托（同名方法转发）+ end_game/reset 内 save 调用点收口
- 风险：**中**——存档是用户数据，格式/路径/容错（缺档/损坏 JSON 兜底零值）必须逐行迁移；GM 薄委托漏任一方法名 → day27_meta 探针直接红；`meta_save_path` 可覆写 var 保持（探针独立档 D44）
- 验证：day27_meta_check 35/35 + day26 §5 存档锚点**零改动** + 白盒临时档读写（D44 惯例）

#### 任务 5：F4-T5【W1】金手指拆分（批次 B · T-046 续）
- 文件：新建 `scripts/systems/debug_console.gd`（薄组件）+ `scripts/autoload/game_manager.gd`
- 改动：迁 `toggle_debug_cheat`（:427）/`_show_debug_banner`（:438）→ debug_console.gd（或并入 SaveSystem，**方案定案：独立 debug_console.gd**——职责单一：调试入口 + 横幅，与存档无耦合）；player.debug_cheat 消费点不变
- 风险：低——金手指独立性强（↑+↓ toggle），迁移面小；`_show_debug_banner` 依赖 UI 工厂（F2-T6 已拆 ui_panel_factory）→ 注入引用
- 验证：day17_p0_check 20/20 **F-04 段零改动**

> **批次 B 收口判据**：GM 残留 <400 行 + 双组件探针全绿 + 回归 40 件套 ≥985。

### 批次 C · player.gd 拆分（732 行 → 目标 <400，T-048）

#### 任务 6：F4-T6【W1】属性系统 AttributeController 拆分
- 文件：新建 `scripts/player/attribute_controller.gd` + `scripts/player/player.gd`
- 改动：迁 `STAT_MAP`（:60）/`STAT_MAP_EXCLUDED`（:83）/`CONSUMED_BONUS_KEYS`（:91）/`_apply_stat_dict`（:176）/`apply_item_bonuses`（:202）/`apply_character` 属性段（:159）/`apply_stat_modifier` → AttributeController 组件（接 STAT_MAP 全量映射 + bonus_stats 白名单收拢——**F0 已修 P0-Bug2 逻辑整体迁移，勿重写**）；player 保留 take_damage/heal/护盾/经验等数值消费薄委托；**⚠️ 消费方锚点**：main.gd 增益注入（D42 直调 apply_stat_modifier）、G-R6 技能树效果注入（同链路）、F-13 low_health 乘算开关
- 风险：**中高**——STAT_MAP 22 键映射 + bonus_stats 白名单是 F0 收口的核心（P0-Bug2），迁移错一键即数值漂移；`apply_stat_modifier` 被 main（D42）/player 内部/未来 G-R6 多处调用，签名必须保留
- 验证：day30_p0_fix_check 15/15 + day2 32/32 + day13 36/36 **数值锚点零漂移硬门槛** + day27_meta 35/35（增益注入链路）

#### 任务 7：F4-T7【W1】动画推断 PlayerAnim 拆分
- 文件：新建 `scripts/player/player_anim.gd` + `scripts/player/player.gd`
- 改动：迁 `_apply_character_sprite`（:238）/`_sheet_meta`（:272）/`_setup_animation`（:279）/`_update_animation`（:347）/`_transition_state`（:360）/`_play_attack_anim`（:396）/`_play_skill_anim`（:401）/`_on_anim_finished`（:407）/`_play_hit_anim`（:415）/`_play_hit_flash`（:419）/`_update_facing`（:458）→ player_anim.gd（或并入 F3 已收口 PlayerState/ANIM_MAP 引用；**动画守卫内聚防 regression**——F-32 索敌门控 / F-33 flip_h 转向 / HIT 同值重入 stop+play 语义全部保留）
- 风险：**中高**——动画状态机与 F3 枚举化（PlayerState/ANIM_MAP/_transition_state）深度耦合，F3 已收口的守卫逻辑（attack-skill 互斥/动画缺失降级）逐行迁移；换皮复位点（:245 与 _setup_animation 初始播放同步 _state）不可漂移
- 验证：day29_elin_anim_check 14/14 + day29_attack_check 20/20 **零改动硬门槛** + day21_22 38/38（换皮锚点）

> **批次 C 收口判据**：player.gd 残留 <400 行 + 双组件探针全绿 + 回归 40 件套 ≥985。

### 批次 D · EXIT 数值快照 + 全量回归（T-047/048 收口）

#### 任务 8：F4-EXIT【W5】收口
- 文件：docs/TECH_DEBT_ISSUES.md
- 改动：① 跑 `tools/gen_baseline_numerics.py` 生成快照 vs F0 `baseline_numerics.json` 对比**零漂移**（F0-5 基线；数值口径零变化仅代码迁移）② 依赖图无环检查（grep 预加载链/实例化链无环 + 手动核对：enemy_movement/enemy_boss/enemy_damage ↔ enemy、save_system/debug_console ↔ GM、attribute_controller/player_anim ↔ player）③ 全量回归 **40 件套 ≥985 断言** + 拆分新增组件冒烟（并入既有探针覆盖，不新建 day30_f4_*——拆分组件无新行为，既有 40 探针即覆盖）④ baseline **BASELINE CLEAN** ⑤ TECH_DEBT_ISSUES T-047/048 转已收口
- 风险：中——快照对比若出现漂移，按「先定位组件迁移差异 → 回滚该组件 → 重对比」处理（禁止整体回滚）
- 验证：回归 40 项一键跑通 + baseline CLEAN

---

## §2 G 系列框架拓展（占位先行 · 规格 docs/FRAMEWORK_EXPANSION.md · 决策点 O1~O6 全拍板）

> 总则：占位标准 = **UI 色块 + 文字标签，零美术生成**（08-07 美术策略遵守）；每系统探针覆盖「验收」列；meta_progress 扩展（codex/archives/skill_tree 缺省空兼容旧档）由 **F4-T4 SaveSystem**（批次 0~3 已先落）读写；**data/skill_tree.json 走 tools 生成（§3-D2 定案）**；characters.json story 复用零改动。

### 批次 G-A · R2 主菜单框架（集成战略式 · 无依赖先行）

#### 任务 9：G-R2-1【W1】MainMenu 主场景
- 文件：新建 `scenes/MainMenu.tscn` + `scripts/ui/main_menu.gd` + `project.godot`
- 改动：全屏 Control + 标题 + 按钮列（开始游戏→CharacterSelect 进局 / 方舟基地→BaseStation / 图鉴→CodexPanel / 回廊→ArchivePanel / 技能树→SkillTreePanel，后三者先建按钮，面板后续就绪再接线）；动态构建仿 CharacterSelect 范式；**project.godot 主场景入口 Main → MainMenu**（`run/main_scene`，原 CharacterSelect 保留可直达——回归零破坏）；占位标准 = 色块+Label 零美术
- 风险：**中**——主场景入口改动是全局性质变（进游戏先进主菜单），但原入口保留可回退；`run/main_scene` 改后 headless 冒烟必须覆盖（场景 17/17 基准）
- 验证：新探针 day30_g_mainmenu §1 入口断言 + 场景可实例化

#### 任务 10：G-R2-2【W1】返回路径闭环
- 文件：scripts/ui/base_station.gd / scripts/character_select.gd + 各子页
- 改动：BaseStation 现返回 CharacterSelect → 改返回 MainMenu；CharacterSelect 加「返回主菜单」按钮；Codex/Archive/SkillTree 面板返回按钮 → MainMenu
- 风险：低——纯按钮接线；BaseStation/CharacterSelect 现有返回逻辑单点改
- 验证：day30_g_mainmenu §3 返回闭环（白盒驱动切场景）

#### 任务 11：G-R2-3【W1】探针 `tools/day30_g_mainmenu_check.gd`（≥8 断言）
- 改动：主场景入口=MainMenu / 按钮列齐（5 入口）/ 开始游戏可达 CharacterSelect / 各子页返回闭环 / 占位面板零 ERROR
- 风险：低
- 验证：≥8/8 CLEAN

### 批次 G-B · R1 大地图模式（杀戮尖塔式 · ⭐最高优先体验）

#### 任务 12：G-R1-1【W1】RouteSelectPanel 改可视化节点地图
- 文件：`scenes/RouteSelectPanel.tscn` + `scripts/ui/route_select_panel.gd`
- 改动：布局改网格画布（非垂直按钮列表）——节点 = 色块+文字标签（战斗红/事件蓝/精英紫/商店金/Boss 深红），连线画路径（Line2D 或 Control 自绘）；**旧 route_generator 数据结构零改动**（routes.json 15 层 × 3 节点仍为数据源）；选本层节点 → 进入对应节点类型（复用现有 `_enter_node` 分派）
- 风险：**中**——RouteSelectPanel 是局内高频路径（每关结算进入），改造必须保持 `_enter_node` 分派与 close_shop 路线推进逻辑（P1-1 商店弹出 / P1-2 波次跳号 / F-28 通关判定链路）；建议保留旧垂直列表代码为回退（或 git 历史可回退即可）
- 验证：day14_15_route 53/53 **零改动**（数据结构层）+ day30_g_map §4 选节点进入断言

#### 任务 13：G-R1-2【W1】预见性 + 迷雾规则（O3 拍板）
- 改动：打开显示 ≥3 层节点（当前层可点选 + **前 2 层可见、之后模糊**——迷雾层节点显示色块但标签灰显/遮罩，不可点）；已走节点灰显（复用 wave_index/row 状态）；后方路径连线随已走节点熄灭
- 风险：中——迷雾/灰显状态渲染逻辑新增，但纯 UI 层零战斗逻辑改动；节点坐标布局由数据层（routes.json 层×节点）推导，禁硬编码
- 验证：day30_g_map §2 迷雾层标签状态断言

#### 任务 14：G-R1-3【W1】探针 `tools/day30_g_map_check.gd`（≥10 断言）
- 改动：地图层数 ≥3 / 节点类型色块映射 / 前 2 层可见后模糊（迷雾层标签状态）/ 已走灰显 / 选节点 → 正确节点类型进入 / 旧数据兼容（routes.json 零改动）
- 风险：低
- 验证：≥10/10 CLEAN

### 批次 G-C · R3 图鉴 + R4 回廊（依赖 F4-B SaveSystem + G-A 入口）

#### 任务 15：G-R3-1【W1】记录层接线
- 文件：scripts/systems/save_system.gd（或 GM 薄委托）+ scripts/enemy/enemy.gd / scripts/ui/shop.gd / scripts/character_select.gd / scripts/ui/event_select_panel.gd / scripts/player/skill_controller.gd
- 改动：GameManager（经 SaveSystem）新增 `record_codex(category, id)` 接口（去重入 meta_progress.codex；缺省空兼容旧档，D44 可覆写路径沿用）；**记录时机（首版最小集，防记录点过多）**：武器=进局起始武器 + 商店卡生成时 / 角色=选角页可见（character_select 加载时批量）/ 敌人=**首次击杀**（enemy.die 内，O5 拍板——F4-T3 拆分后挂点明确）/ 道具=商店卡生成时 / 事件=事件面板展示时；**「升级出现时记录」登记 P1 不做**（防 level_up_panel 耦合）
- 风险：**中**——enemy.die 是击杀热路径（F4-T3 刚拆分），记录调用必须零开销（去重查表）；商店卡生成点（_build_shop_pool 循环）加记录防重复
- 验证：day30_g_codex §1 白盒注入五分类断言

#### 任务 16：G-R3-2【W1】CodexPanel UI
- 文件：新建 `scenes/CodexPanel.tscn` + `scripts/ui/codex_panel.gd`
- 改动：分类标签（武器/角色/敌人/道具/事件）→ 网格卡片（色块+名称）；未见条目显示「？？？」占位不泄露名称；MainMenu 图鉴入口接线；返回按钮
- 风险：低——纯 UI 展示，读 meta_progress.codex
- 验证：day30_g_codex §3 未见条目不泄露名称

#### 任务 17：G-R3-3【W1】探针 `tools/day30_g_codex_check.gd`（≥10 断言）
- 改动：记录接口白盒注入五分类 / 存档重启保留（meta_progress.codex 持久化）/ 未见条目不泄露名称 / UI 卡片与记录同步
- 风险：低
- 验证：≥10/10 CLEAN

#### 任务 18：G-R4-1【W1】ArchivePanel 回廊（从简 O6）
- 文件：新建 `scenes/ArchivePanel.tscn` + `scripts/ui/archive_panel.gd`
- 改动：角色列表（色块占位）→ 选中显示 characters.json story 文本（复用现有 story 字段，O6 从简）；**解锁判定 = 角色等级达标（get_char_level >= story_unlock_level，D27 链路已有）——方案定案：零新增存档字段（§3-D3），天然持久化**；未解锁角色显示解锁条件（story_unlock_level）不显示内容；MainMenu 回廊入口接线；**事件解锁 flag（awakening_archive）首版不做，登记 P1**
- 风险：低——纯 UI + 读既有数据（characters.json story / meta_progress char_xp）
- 验证：day30_g_archive §1/§2 已解锁可读 / 未解锁只显条件

#### 任务 19：G-R4-2【W1】探针 `tools/day30_g_archive_check.gd`（≥8 断言）
- 改动：已解锁档案可读 / 未解锁显示条件不显示内容 / 解锁状态持久化（重启后保留——经角色 xp 存档天然满足）/ story 字段零改动
- 风险：低
- 验证：≥8/8 CLEAN

### 批次 G-D · R5 背包（独立 · 入口=暂停菜单 O4）

#### 任务 20：G-R5-1【W1】BackpackPanel
- 文件：新建 `scenes/BackpackPanel.tscn` + `scripts/ui/backpack_panel.gd` + 暂停菜单接线
- 改动：半屏面板，武器槽（6）+ 被动槽（6）网格 + 属性一览（读 player/inventory 实时数据——**F2-T2 已备 get_weapons/get_items/get_weapon_controller 接口直接消费**）；打开时游戏暂停（pause 模式）；**入口 = 暂停菜单（Esc 暂停菜单加「背包」按钮，O4 拍板仅暂停菜单先行）**
- 风险：中——暂停菜单（PauseMenu/Esc 处理）现状需实测挂点（game_over_panel 同域）；pause 模式与 P1-1 商店弹窗/P1-4 金手指状态守卫交互需回归
- 验证：day30_g_backpack §3 打开时暂停生效

#### 任务 21：G-R5-2【W1】探针 `tools/day30_g_backpack_check.gd`（≥8 断言）
- 改动：显示当前装备与等级（与 inventory 实时一致）/ 属性数值与 player 实际一致 / 打开时暂停生效 / 关闭恢复
- 风险：低
- 验证：≥8/8 CLEAN

### 批次 G-E · R6 技能树（依赖 G-A + F4-B）

#### 任务 22：G-R6-1【W2】skill_tree.json 数据定义
- 文件：新建 `data/skill_tree.json` + `tools/gen_skill_tree.py`（新建，生成脚本）
- 改动：节点结构（id/名称/描述/前置/消耗/效果，规格 §R6）；首版最小集（攻击/生命/幸运 3 系 × 2-3 节点，占位即可）；**数据管线定案（§3-D2）：tools/gen_skill_tree.py 直接生成 JSON + 探针**（设计未定稿、占位先行，走 Excel 注册过度设计；与 gen_* 工具先例一致，登记 F1-E 后若需策划改数再收编 Excel）；meta_progress.skill_tree 扩展（unlocked + points，缺省空兼容旧档——SaveSystem F4-T4 已拆，直接扩展读写）
- 风险：低——新数据文件零回归；gen 脚本幂等（重跑覆盖一致）
- 验证：gen 脚本幂等断言 + day30_g_skilltree §1 数据加载

#### 任务 23：G-R6-2【W1】技能点发放（O1 拍板）
- 文件：scripts/autoload/game_manager.gd（或 SaveSystem）
- 改动：**角色等级提升 +1 技能点**（复用 get_char_level/add_char_xp 链路，**等级提升处发放** → meta_progress.skill_tree.points+1 + save_meta）——⚠️ 等级提升点 = D27 链路中 level 变化检测处（add_char_xp 后 get_char_level 跃迁即发放），需实测确认挂点
- 风险：中——等级跃迁检测若挂在 add_char_xp 内会多计（连续 +2 xp 跨 2 级），**定案：每调用 add_char_xp 计算 old_level vs new_level 差值发放（n 级差 = n 点）**；day27_meta 35/35 存档断言零改动（skill_tree 缺省空）
- 验证：day30_g_skilltree §4 等级提升 +1 断言

#### 任务 24：G-R6-3【W1】SkillTreePanel UI + 效果注入
- 文件：新建 `scenes/SkillTreePanel.tscn` + `scripts/ui/skill_tree_panel.gd`
- 改动：树状分层按钮（占位：分层布局 + 前置锁定态——前置未解锁节点灰显不可点）；解锁消耗技能点并持久化；**效果注入局内 = 与 meta research 同链路（get_meta_bonus/apply_stat_modifier 扩展，O2 拍板独立并存 research 保留）**；MainMenu 技能树入口接线
- 风险：中——效果注入经 apply_stat_modifier（F4-T6 刚拆到 AttributeController，消费点接新组件）；解锁条件校验（前置 + 点数）纯函数化防 UI 层逻辑膨胀
- 验证：day30_g_skilltree §2/§3 前置锁定 + 消耗持久化 + 注入生效

#### 任务 25：G-R6-4【W1】探针 `tools/day30_g_skilltree_check.gd`（≥10 断言）
- 改动：前置满足才可点 / 消耗技能点并持久化（重启保留）/ 效果注入局内生效（白盒验证加成）/ 技能点发放链路（等级提升 +1）/ research 独立并存零回归
- 风险：低
- 验证：≥10/10 CLEAN

### 批次 G-F · G 系列 EXIT 收口

#### 任务 26：G-EXIT【W5】收口
- 文件：docs/TECH_DEBT_ISSUES.md + PLAYTEST 登记（#5 域）
- 改动：各系统探针全绿（6 探针） + 全量回归 **40 件套 ≥985 + day30_g_*（46 件套预期）** + baseline **BASELINE CLEAN** + PLAYTEST 主观项登记（大地图可预见性 / 主菜单观感 / 图鉴回廊背包技能树 UI 观感，交 #5）；占位标准全程零美术生成
- 风险：低
- 验证：回归 46 项一键跑通

---

## §3 方案定案决策点（#2 拆解遗留 + 本方案补充，共 4 项）

> **D1（#2 遗留 · 二选一）**：meta_progress 扩展（codex/archives/skill_tree）读写 = 「G 系列批前先落 F4」定案 —— **F4 全批先行**，理由：G-R3/G-R6 直接消费 F4-T4 SaveSystem 新接口；先做 G 再拆 F4 会导致 SaveSystem 拆分时须迁移 G 新增读写点，回归面重叠。
> **D2（#2 遗留 · 是否走 Excel 注册）**：data/skill_tree.json **不走 Excel 注册，tools/gen_skill_tree.py 直接生成 + 探针**——设计未定稿、占位先行、最小集 3 系 × 2-3 节点，走 Excel 注册属过度设计；与 gen_* 工具先例一致；**登记取舍**：F1-E（主窗口）后若策划需自助改数，收编进 Excel 管线。
> **D3（本方案补充 · R4 存档字段）**：G-R4 回廊解锁 **零新增存档字段**——解锁判定 = 角色等级达标（get_char_level >= story_unlock_level，D27 链路已有），角色 xp 已持久化天然满足「解锁状态持久化」；O6 从简精神贯彻；事件解锁 flag（awakening_archive）首版不做登记 P1。
> **D4（本方案补充 · 技能点发放粒度）**：G-R6-2 等级跃迁按 **old vs new 差值发放（n 级差 = n 点）**，挂点 = add_char_xp 调用处（防连续升级少计/多计）；research 独立并存（O2 拍板，技能树效果经 apply_stat_modifier 同链路注入但 research 保留）。

## §4 风险总表（高→低）

| 风险 | 等级 | 缓解 |
|---|---|---|
| F4-T2 Boss 域 20 方法整体迁移（F3 枚举 + BS 四拍子/QTE/难度合成 + D18-19 attacks 融合域） | **高** | 迁移链整体搬移保持互调关系；take_damage/die 薄委托保留；day18_19 48/48 + day30_boss_skill 49/49 零改动硬门槛 |
| F4-T1 移动热路径迁移（chase/击退/接触伤害） | **高** | 组件注入 enemy 实例引用；签名与调用点逐一对照；hit_radius/contact_cooldown 不可漂移 |
| F4-T3 die 击杀链路迁移（掉落/经验/boss_killed/G-R3 图鉴挂点） | **高** | 清理顺序保持（is_alive=false 先行）；day4/day13/day18_19 死亡流程探针零改动 |
| F4-T6 STAT_MAP/bonus_stats 迁移（P0-Bug2 核心） | **中高** | 整体迁移勿重写；apply_stat_modifier 签名保留（main D42 / G-R6 消费）；day30_p0_fix 15/15 硬门槛 |
| F4-T7 动画状态机迁移（F3 枚举 + F-32/F-33 守卫） | **中高** | 守卫逻辑逐行迁移；day29_elin 14/14 + day29_attack 20/20 零改动硬门槛 |
| F4-T4 SaveSystem 存档格式零改动（用户存档不损坏） | **中** | 格式/路径/容错逐行迁移；D44 可覆写路径保持；day27_meta 35/35 + day26 §5 锚点 |
| G-R2 主场景入口改 MainMenu（全局性质变） | **中** | run/main_scene 改后 headless 冒烟；原 CharacterSelect 保留可回退 |
| G-R1 RouteSelectPanel 可视化改造（局内高频路径） | **中** | _enter_node 分派 / close_shop 推进 / F-28 通关判定链路零改动；day14_15 53/53 零改动 |
| G-R6-2 等级跃迁发放挂点（多计/少计） | **中** | old vs new 差值发放；day27_meta 存档断言零改动 |
| G-R3 记录时机散点（die 热路径 / 商店池） | **中** | 记录调用零开销（去重查表）；首版最小集 5 时机，升级出现时登记 P1 |
| 新 tscn ×5 + 新组件 ×6 的 Godot 缓存（新 class_name/UID） | 低 | 沿用无 class_name preload 范式（StatusComponent 先例）；headless --editor 扫描重建 global_script_class_cache |
| 工作区在途 art_ai 工具链（.ssh_tmp/ 未甄别）commit 夹带 | 低 | 每批 commit 显式 add 本次文件；.ssh_tmp/ 与 ComfyUI docx 不碰（归属用户会话） |
| F4 数值快照漂移（baseline_numerics.json） | 中 | 快照对比失败 → 定位组件迁移差异 → 回滚该组件重对比（禁整体回滚） |

## §5 观察点与请求（交 #3/#4/#5/#1）

- **#3**：① 执行序 = F4-A→B→C→D→G-A→B→C→D→E→F，每批一收口 commit（F4 带 T-047/048 系列 / G 带 G-R 编号）；② F4 每拆一个组件立即跑该模块专属探针（§1 各任务验证列），禁止一次拆完再验证；③ commit 勿夹带用户在途资产（art_ai 工具链 / .ssh_tmp/ / ComfyUI docx / 测试立绘 / xlsx 素材）；④ **F1-E 维持主窗口承接勿自行开工**；⑤ G 系列探针命名 day30_g_*，全部并入 `_regression_run.py`（请求 #3 顺手，防 #4 覆盖滞后重演）；⑥ 新文件一律无 class_name preload 范式。
- **#4**：TEST_REPORT #46+ 覆盖本轮新探针（day30_g_mainmenu / day30_g_map / day30_g_codex / day30_g_archive / day30_g_backpack / day30_g_skilltree），回归基准 40 件套 985 → **46 件套预期**；F4 拆分无新探针（既有 40 件套即覆盖，快照对比由 #3 自证）。
- **#5**：G 系列落地后主观项登记（大地图可预见性 / 主菜单观感 / 图鉴回廊背包技能树 UI 观感 / F-36 BS 交互技能回归面）；占位 UI 观感按「功能可辨识」口径（美术策略，不按华丽度）。
- **#1**：G 系列为 30 天计划外新增框架块（用户 08-12 拍板），若排期与 F5 冲突请裁决优先级（建议 F4 → G → F5 顺序，F5 收尾文档不阻塞 G）。

## §6 收口判据（全部达成即本轮方案执行完毕）

1. **F4-D EXIT**：enemy/player/GM 全部 <400 行 + 数值快照 vs F0 零漂移 + 依赖图无环 + 回归 40 件套 ≥985 + baseline CLEAN + T-047/048 转已收口。
2. **G-F EXIT**：6 探针全绿 + 回归 46 件套预期 + baseline CLEAN + PLAYTEST 主观项登记 + 全程零美术生成。
3. **F1-E 仍主窗口承接**（阶段 F 唯一外部项）；F5 未开始（F4 收口后按 TECH_DEBT_PLAN §4 拆）。
4. 存档兼容：meta_progress 扩展字段缺省空兼容旧档（SaveSystem 拆分零格式改动）。

---

## 执行结果（#3 · 2026-08-14 第 21 轮方案 · 状态：完成）

> **F4 全批（批次 0~3）+ G 系列全批（批次 4~9）全部落地**，共 11 个收口 commit：
> `dc77e47`（F4-A enemy 拆分）+ `a654662`（F4-B/C GM+player 拆分）+ `3168c14`/`0551cd9`（F4-D 快照+EXIT）
> + `16e4a1d`（G-A 主菜单）+ `bcd97bc`（G-B 大地图）+ `74e5e3a`（G-C 图鉴回廊）+ `e93d63a`（G-D 背包）
> + `e01b612`（G-E 技能树）+ G-F 收口 commit（本轮）。
>
> **F4-D EXIT 判据**：enemy.gd 1097→397 ✓ / player.gd 732→399 ✓ / **GM 686→623（⚠️ T4/T5 拆出 63 行，<400 未达——方案任务量与收口判据不匹配，登记交方案师下轮决策：继续拆 banner/路线段 or 放宽判据）**；
> 数值快照重新生成（差异全为 F0 后数据管线变化——F1.0 Excel int 表示 / F1-G-尾删键，**非 F4 引入，data/*.json 零改动实证**）；
> 依赖图无环 ✓（组件仅 preload 纯枚举文件 enemy_enums/player_enums，宿主 load() 创建组件）；
> 回归 40/40（985 断言基准）+ BASELINE CLEAN ✓；T-047/048 转已收口 ✓。
>
> **G-F EXIT 判据**：6 探针全绿（mainmenu 10 / map 20 / codex 13 / archive 9 / backpack 11 / skilltree 13）+ 全量回归 **46 件套预期** + BASELINE CLEAN + PLAYTEST 主观项登记（增量 #65）+ **全程零美术生成**（占位色块+Label 口径）✓。
>
> **执行登记（探针锚点同步 8 处，均因拆分迁移语义等价）**：day26（伤害数字/精灵链路）、day29_elin/day29_attack（hit 禁打断/skill 守卫文本）、day23（crit/levelup 特效锚点）、day30_f2（enemy instantiate 收口）、day18_19/day30_boss_skill/day18_feedback3（`_default_meta`/`_compose_difficulty_coeff`/`_process_knockback` 三薄委托补齐——探针直接 call 的方法必须保留宿主薄委托，此为拆分最重要兼容教训）。
>
> **踩坑记录（复用价值）**：① 组件 preload 宿主脚本（引用 Autoload 标识符）→ 探针 --script 编译期 Identifier not found → 抽纯枚举文件；② `player_script.new()` 直造不入树不触发 _ready → 薄委托须惰性 `_ensure_components()`（day24_f13 实证）；③ Node/Resource `.get()` 只收 1 参（历史坑复踩 2 次：shop.gd/backpack_panel.gd）；④ SceneTree 探针自身即树（无 get_tree()）；⑤ GDScript 无括号不可跨行续接。
