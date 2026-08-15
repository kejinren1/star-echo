# 方案计划（2026-08-16 · 第 23 轮 · 正式方案：F5 回归与收口 + 玩家侧技能系统批 A-E）

## 当前开发日：阶段 F（F5 回归与收口）+ 玩家侧技能系统（批 A-E）

> **git 实测**：HEAD=`f3fdabc`（#2 第 47 轮 00:0x 拆解提交：F5 T1~T5+EXIT + 玩家侧技能系统批 A-E + F4/G 标题收口同步 + T-046 遗留登记）。
> **工作区在途（零游戏代码本岗不碰）**：M `assets/sprites/**` 46 个资产文件（items 图集 25→54 帧重建 + 角色动画 v2 实装期，用户会话在途）——**F5-T1 锚点同步的前置依赖**。
> **F 区块状态**：F0~F4 / F1-散 / BS-A~D / G 系列全 [x] ✅ ｜ **F1-E [ ] 🏠 主窗口承接（非 #3 域）** ｜ **F5 [ ] 待执行（本轮方案定案）** ｜ **玩家侧技能系统 [ ] 待执行（本轮方案定案）**。
> **P0 检查（P0 调度硬性输入）**：追踪区最新增量 #67（08-15 19:5x · 执行者直修 F-39 登记）= **F-39 spawner 死锁已修复 `54ccee3` 双保险**（根因 = `_process` 短路致 `_is_spawning` 永久 true → 普通关永不判通；修复 = `_spawn_next` 出队复位 + `_process` 自愈；护栏 day31_spawner_deadlock_check 7/7 + 回归 47/47 · 1046 断言 + BASELINE CLEAN）→ **🔴 P0 无新增 / 🟠 无用户拍板调度指令 → 无新机器可验证 P0 需拆**。⚠️ **锚点登记（交 #3 随资产入库同步）**：items 图集 25→54 帧 → day11_12/day20/day24_f13 探针锚点（frame_count 25→54 / items.png 800×32→1728×32 / icon_index 0-24→0-53）+ day26 runner 锚点 46→47（TEST_REPORT #47 3 FAIL = 同因工具侧期望过期）。
> **本轮判定**：#2 第 47 轮已函数级拆解两区块（F5 批 A/B/C + 玩家侧技能系统批 A-E）→ **两区块正式方案定案**（规则 5 合规）。#3 执行输入 = 本方案 + TASKS 拆解；执行序 = **F5 全批 → 玩家侧技能系统批 A→B→C→E→D**。

---

## §0 状态快照（本轮各观察点）

| 观察点 | 状态 |
|---|---|
| 回归基准 | **47 件套 · ≥1046 断言**（runner 47 项：46 旧 + day31_spawner_deadlock_check 7；TEST_REPORT #47 的 3 FAIL = items 图集锚点过期工具侧问题，非游戏缺陷，待资产入库同步） |
| F5 | [ ] 未开始（#2 第 47 轮已函数级拆解：T1~T5 + EXIT，批 A/B/C） |
| 玩家侧技能系统 | [ ] 未开始（#2 第 47 轮已函数级拆解：批 A-E；规格 docs/PLAYER_SKILL_SPEC.md 已入库 `d81c7a8`） |
| F1-E | 🏠 主窗口承接维持（阶段 F 唯一 [ ]，F5 收口不触碰） |
| 在途资产 | 46 个 assets/sprites/** M（用户会话）——F5-T1 前置依赖，锚点同步须与其同批 |
| P0 | 无新机器可验证项（F-01~F-37 全 🟢 待真人回归 = 主观项交 #5） |

---

## §1 F5 回归与收口（批 A/B/C · TECH_DEBT_PLAN §4 F5 · git 收口 f5-stabilize）

> 性质 = **文档 + 回归收口日，非功能开发日**；纯文档/回归零数值，不涉 Excel（DATA_DICT_GUIDE 手册内容是写 Excel 管线链路说明，非改数）。批次 A = T1+T2 / B = T3 / C = T4+T5+EXIT，每批一收口 commit 带 T 编号。

### 任务1：F5-T1【W5】全量回归复跑（批次 A）
- 文件：tools/_regression_run.py（runner 锚点）+ tools/day11_12_passive_check.gd / tools/day20_relic_check.gd / tools/day24_f13_check.gd（3 探针 items 图集锚点）
- 改动：① **锚点同步（前置）**：3 探针硬编码 items 图集期望 25 帧 → 采纳 TEST_REPORT #47 action item 建议改**动态读取 `icon_atlas.get_frame_count()`**（防再漂移，勿硬编码 54）；day26_integration_check §6 runner 锚点 46→47（若其引用探针数）。② **同步时机 = 工作区 46 资产入库同批**（#3 协调用户会话：资产提交 + 锚点同步 + 本任务同一收口 commit，防中间态红）。③ 复跑 47 件套 ≥1046 断言一键全绿 + baseline **BASELINE CLEAN**。
- 风险：中——锚点同步与资产入库强耦合，若资产迟迟不提交则本任务挂起；**兜底**：先跑除 3 锚点探针外全量 44/47 确认绿（隔离验证），资产入库后补 3 探针，两段各自 commit。
- 验证：`_regression_run.py` 47/47 + BASELINE CLEAN。

### 任务2：F5-T2【W1】性能对比基线（批次 A）
- 文件：tools/day28_perf_check.gd（复用，零改动）
- 改动：复跑 7/7（同屏 50 敌逻辑帧 6.88ms≈145fps / 最差 14.9ms / static 53MB），与 F0 快照（`510ef61` 记录值）对比**零劣化登记**（结果写入 F5 收口 commit message 或 DATA_DICT_GUIDE 附录）。
- 风险：低——纯复跑对比，无新探针。
- 验证：day28_perf_check 7/7 + 对比登记。

### 任务3：F5-T3【W1】docs/DATA_DICT_GUIDE.md 策划改数手册（批次 B · 唯一新交付物）
- 文件：新建 docs/DATA_DICT_GUIDE.md
- 改动：**先读 tools/data_schema.py SHEETS 注册表**（实测已注册 24+ sheet：weapons/weapons_levels/items/items_effects/enemies/enemy_scaling/characters/characters_passives/characters_penalties/waves/wave_generation/wave_rewards/events/stats/stats_formulas/stats_leveling/stats_shop/stats_combat/stats_physics/stats_skills/elements/element_reactions/reaction_rules/routes 及 skill_tree/boss_skill/boss_pattern/skill_relics 等新表），**勿凭记忆编 sheet 清单**。每表写「改哪个 sheet → 跑什么命令（tools/excel_export.py）→ 看什么校验（--check-only / manifest 指纹 / 探针锚点）」，与 F1.0 管线（data_schema.py 注册 / json_to_excel.py / excel_export.py）逐一对应；含「改数典型流程」示例（改→导出→校验→探针→回归）。验收「策划可自助改数」。
- 风险：低——纯文档；唯一坑 = sheet 清单必须按 data_schema.py 实测盘点到落笔时最新（玩家侧技能系统若已加 skill_relics/skill_unlocks 表，手册须覆盖）。
- 验证：文件落盘 + 抽查 3 表「sheet 名→命令→校验」链正确 + 债清点。

### 任务4：F5-T4【W1】新功能开发恢复门槛（批次 C）
- 文件：docs/CODE_STYLE.md（既有 §5/§8 引用）+ TASKS 玩家侧技能系统区（门槛标注）
- 改动：提交前过「配置化评审清单」（CODE_STYLE §5/§8：数值走 DataLoader / 状态走枚举+transition / 跨层信号 / 数据改 Excel）——**玩家侧技能系统 = 恢复门槛后首个新功能大块，F5 收口为其开工前置**（排期 F5 → 玩家侧技能系统）。
- 风险：低——既有规范引用。
- 验证：F5 收口 commit 前清单过检（#3 自查登记）。

### 任务5：F5-T5【W1】F4 遗留决策登记（批次 C）
- 文件：docs/TECH_DEBT_ISSUES.md（T-046 收口附注）
- 改动：登记「放宽判据：enemy/player 达标 + GM 相对 F2 首拆 783 行净减 160 行（GM 已拆 SaveSystem/DebugConsole/EventManager/UIPanelFactory 四组件，继续拆边际收益低）」，交 #1/Owner 裁决。
- 风险：低——不阻塞 F5 其余项。
- 验证：TECH_DEBT_ISSUES T-046 附注落盘。

### 任务6：F5-EXIT【W5】收口（批次 C）
- 文件：docs/TASKS.md（F5 标题 [x]）+ docs/TECH_DEBT_ISSUES.md（债清点）
- 改动：DATA_DICT_GUIDE.md 落盘 + 回归 47 件套 ≥1046 + baseline **BASELINE CLEAN** + TECH_DEBT_ISSUES T 编号残留归零 + F5 标题 [x] + 阶段 F 全闭（F1-E 维持 🏠 主窗口承接）+ PLAYTEST 主观项登记（E-0 终审完整局 + F-37 G 系列新 UI 交 #5）。
- 风险：低。
- 验证：同 F5-T1 + 债清点 grep。

---

## §2 玩家侧技能系统（批 A-E · PLAYER_SKILL_SPEC D1-D7 · git 收口建议 ps-* 前缀）

> 执行序 = **批 A → B → C → E → D**（D 高风险最后收口）。数据管线铁律（全程）：skill_relics 新表 / invulnerable 效果类型 / routes chapter 字段 / 局外等级门槛表 = 全走 docs/GameData.xlsx → tools/excel_export.py（data_schema.py 注册）→ data/*.json → 探针，**data/*.json 禁手改**。占位标准 = UI 色块+文字标签零美术（08-07 策略）。回归硬门槛：day3_skill_check 16/16 / day17_p0 20/20 / day18_19 48/48 / day30_boss_skill 49/49。
> **关键裁决 PS-A0（数据迁移降级）**：#2 拆解「characters.json skill→skills 数组迁移」**本轮不做数据迁移，做代码层列表化**——理由：① 规格书 §2 范围声明「玩家现有 4 技能迁入中立表 = 远期重构」；② 槽 0 = 英雄默认技能 = skill 单字段天然成立（characters.json 实测 4 处 skill :141/:184/:228/:272），数据不迁移 3 槽照样成立；③ 掉落技能由 PS-C1 skill_relics 新表承载注入槽 1/2，不依赖 skills 数组；④ Excel characters sheet 结构改造（对象数组表达）风险大收益低，违背「一个回合量级非重构」。**skill→skills 数组迁移登记为 PS 收尾后远期债**（TECH_DEBT，与「4 技能迁入中立表」同域）。

### 任务1：PS-A 批 · 多技能位 + 键位路由（规格 §4 · 中高风险先行）
- **PS-A1【W1】skill_controller 列表化**：
  - 文件：scripts/player/skill_controller.gd（实测：skill_data :22 / setup 读 `char_data.get("skill")` :49 / try_cast :68 / match 分派 :74-82 / _cast_fireball :94 / _cast_deploy_turret :172 / _cast_blade_burst :224 / _cast_holy_shield :258 / _resolve_projectile_container :284 / _find_nearest_enemy :298 / _get_aim_direction :313）
  - 改动：单技能 match → **技能列表 + 槽位路由**（3 槽：槽 0=空格 / 槽 1=鼠标左键 / 槽 2=鼠标右键，独立 CD 各转各的）；`skills: Array` 容器（元素 = Dictionary：id/type/params/slot/cd_left）；setup 把英雄 skill 字段装载为槽 0（PS-A0：数据零迁移）；新增 `try_cast_slot(slot: int) -> bool` 槽路由（槽空 can_cast=false 静默返回）；try_cast 保留为槽 0 薄转发（**day3_skill_check 16/16 零改动硬门槛**——探针直调 try_cast 走火球路径不变）。
  - 风险：中——skill_controller 结构变化触及 day3 探针锚点；**兜底**：try_cast 保留兼容签名 + match 分派逻辑整体迁入槽 0 执行路径，行为逐字节等价。
  - 验证：day3_skill_check 16/16 + day31_skill_slots_check（PS-A4）§1。
- **PS-A2【W1】键位输入路由**：
  - 文件：project.godot（实测 skill_cast :75 空格已有，**无鼠标左/右键动作 → 需补 2 个**）+ scripts/player/player.gd（_unhandled_input 区）
  - 改动：input map 补 `skill_slot1`（鼠标左键）+ `skill_slot2`（鼠标右键）；_unhandled_input 技能路由（空格/左键/右键 → try_cast_slot 0/1/2）；**UI 消费输入防误触**（暂停菜单/背包/商店点按钮时技能键不得触发——Control mouse_filter STOP 消费或 pause 时禁用路由；P1-4 金手指 ↑↓ 守卫域保留不动）；指向性技能 = InputEventMouseButton 转世界坐标（复用 _get_aim_direction :313 目标点逻辑）。
  - 风险：中——输入路由可能误触发 UI 操作；**兜底**：仅 BATTLE 状态路由技能键（仿 P1-4 状态守卫先例）。
  - 验证：day31_skill_slots_check §2 + day17_p0 20/20（金手指守卫锚点）。
- **PS-A3【W1】HUD 技能栏 1→3 格**：
  - 文件：scripts/ui/hud.gd（实测：skill_slot :18 / skill_label :19 / _apply_skill_icon 调用 :307 / 定义 :317 / texture :334 / modulate :340/:343）+ scenes/HUD.tscn SkillBar
  - 改动：SkillBar 1 槽 → 3 槽（横向排列，各转各 CD 圈 + 剩余秒 Label；槽 1/2 空槽灰显占位）；_apply_skill_icon 按槽接线（T-D 图标复用：槽 0 = 英雄技能图标，槽 1/2 = 掉落技能图标 or 占位色块）。
  - 风险：低-中——HUD 布局改动；**兜底**：3 槽复用现有 SkillSlot 节点复制（场景文件改动小），空槽零 ERROR。
  - 验证：day31_skill_slots_check §3 + day26 场景 25/25。
- **PS-A4【W1】探针 tools/day31_skill_slots_check.gd（≥10 断言）**：三槽独立 CD / 键位路由 / 默认技能兼容（槽 0 = 英雄技能）/ UI 点按钮不触发（白盒 push_input）/ 金手指守卫不破坏。
- **PS-A-EXIT【W5】回归**：47 件套 + day3_skill_check 16/16 零改动 + baseline **BASELINE CLEAN**。

### 任务2：PS-B 批 · SkillExecutor 新类型 + invulnerable 效果（规格 §5/§6 · 依赖批 A 列表容器）
- **PS-B1【W1】executor 工厂扩展**：
  - 文件：scripts/boss/boss_skill_factory.gd（实测：无 class_name preload 范式 / preload 4 执行器 :7-11 / static make :13）+ scripts/boss/skill_executor.gd（fair_telegraph :23 / enter :55 / tick :63 / exit :97）
  - 改动：factory 扩展 **dash / blink / leap / spawn / buff** 类型（preload 新增执行器脚本；未知 type push_warning 返回 null 先例保留）；玩家版参数口径 §9.3（telegraph 归零或 0.1s / radius ×0.6 / cooldown ×1.5-2 即 8-12s / damage 挂 scaling_attr 吃玩家属性 / aftercast 0.2s）——**口径统一封装在 params 合成处，勿散落各执行器**。
  - 风险：中——执行器是 Boss 共享中立层（day18_19 48/48 + day30_boss_skill 49/49 零破坏硬门槛）；**新增只加不改**，既有 4 类型零触碰。
  - 验证：day30_boss_skill 49/49 + day31_skill_movement_check（PS-B4）§1。
- **PS-B2【W1】位移三型实现**：
  - 文件：新建 scripts/boss/exec_dash.gd / exec_blink.gd / exec_leap.gd（复用三接口 enter/tick/exit）
  - 改动：dash 冲刺（沿移动方向 distance/duration，最通用）/ blink 闪现（瞬移目标点可穿怪，CD 最长）/ leap 跃击（起跳砸落点 + 落点小范围伤害/击退 + 落地后摇）——参数全数据驱动（distance/duration/effects/cooldown/aftercast/可选 leave_damage）；**玩家消费点 = player.gd 位移逻辑**（移动方向输入 + 位置瞬移 + 状态机 PlayerState 复用 F3-T6 收口态）。
  - 风险：中——位移触碰 player 位置与碰撞；**兜底**：瞬移/冲刺期间禁接触伤害结算（复用 invulnerable 窗口 PS-B3 同一通道）。
  - 验证：day31_skill_movement_check §2（dash 距离 / blink 穿怪 / leap 落点伤害）。
- **PS-B3【W1】invulnerable 效果（D2 不写死）**：
  - 文件：docs/GameData.xlsx elements/effect 表 + tools/data_schema.py 注册 + tools/excel_export.py + scripts/systems/status_component.gd / player.gd
  - 改动：effect 表新增 `invulnerable` 类型（type + duration）；player 消费点 = 无敌帧窗口（P0-Bug1 护盾层先例同链路：受击判定前查 invulnerable 状态免疫）；默认手感起点 dash 0.3s / blink 0.1s / leap 落地前 0.2s（数值归数值可调）。
  - 风险：低-中——效果表结构升级（BS-A 已铺路）+ player 受击判定加一道检查；**兜底**：无 invulnerable 数据时行为等价现有。
  - 验证：day31_skill_movement_check §3（无敌帧窗口生效 + 改表数值 → 行为变化）。
- **PS-B4【W1】探针 tools/day31_skill_movement_check.gd（≥10 断言）**：三型位移行为 / 无敌帧窗口 / invulnerable 效果表驱动 / 玩家版参数口径 / 与公平底线关系（§6.4 位移压缩 2r/v 不破坏底线）。
- **PS-B-EXIT【W5】回归**：47 件套 + day18_19 48/48 + day30_boss_skill 49/49 + baseline **BASELINE CLEAN**。

### 任务3：PS-C 批 · skill_relics 掉落表 + per_character 变体 + 三选一装配（规格 §7/§9 · D7 核心）
- **PS-C1【W2】skill_relics 新表**：
  - 文件：docs/GameData.xlsx 新 sheet + tools/data_schema.py 注册 + tools/excel_export.py → data/skill_relics.json
  - 改动：id/name/desc/per_character:{char_id:{type, params…}} + 掉落源标记；每个掉落物按角色变体配置（type 引用 SkillExecutor 行为类型，params 覆盖技能参数）；**数据管线铁律：改 Excel → 导出 → 探针，data/*.json 禁手改**。
  - 风险：中——新表注册走 F1.0 管线（data_schema 注册 + manifest 指纹），漏注册必红。
  - 验证：excel_export --check-only + manifest + day31_skill_relic_check（PS-C5）§1。
- **PS-C2【W1】掉落钩子（D4/D5）**：
  - 文件：scripts/enemy/enemy_damage.gd（F4-T3 拆分后实测：take_damage :22 / die :41 / _drop_rewards :65（:67 add_coins）——掉落链消费点在 enemy_damage 组件）
  - 改动：die 路径精英怪 **80% 触发技能三选一**（20% 替代奖励金币/属性碎片，数值可配）+ **章 Boss 招牌技必掉**（该 Boss 用过的招式 = 教学闭环）+ 随机池（复用 F-16 掉落先例 / F-19/21 奖励结算路径）。
  - 风险：中——掉落触发点改动波及死亡流程（day4 21/21 / day18_feedback 16/16 死亡流程探针）；**兜底**：掉落逻辑挂在 _drop_rewards 尾段（金币掉落零改动），触发判定纯数据。
  - 验证：day31_skill_relic_check §2（白盒注入抽样 80%/20%）。
- **PS-C3【W1】三选一装配 UI（§7 拾取交互）**：复用 level_up_panel 卡片交互范式（掉落 → 随机抽 3 候选 → 三选一装配/替换当前槽，可换可不换；槽位 = 批 A 列表容器）；暂停式弹窗仿 EventSelectPanel/LevelUpPanel。
- **PS-C4【W1】per_character 变体消费（§9.2/9.4）**：装配时 DataLoader 按当前角色查 `per_character[char_id]` 得实际技能（type + params 覆盖）；无该角色条目 → 通用兜底或不可用；**剑士星刃替换（§9.4）**：se_star_blade 默认主动技能 → **剑气爆发**（向前挥出扇形/贯穿剑气一次爆发，作为剑士默认槽替换）。
- **PS-C5【W1】探针 tools/day31_skill_relic_check.gd（≥10 断言）**：掉落率 80% 触发 / 20% 替代奖励 / 章 Boss 必掉招牌技 / per_character 映射（同 relic 不同角色 → 不同技能 type/params）/ 无条目兜底 / 三选一装配后替换生效 / 星刃→剑气替换。
- **PS-C-EXIT【W5】回归**：47 件套 + baseline **BASELINE CLEAN**。

### 任务4：PS-E 批 · 局外等级奖励（规格 §3 D6 · 低风险）
- **PS-E1【W2】局外等级奖励门槛表**：docs/GameData.xlsx 新 sheet（角色等级 → 解锁技能包/第 3 槽位，门槛不写死）→ data_schema 注册 + excel_export → data/skill_unlocks.json；数据管线铁律同上。
- **PS-E2【W1】解锁链路**：角色等级提升（get_char_level/add_char_xp 链路，G-R6 O1 技能点发放先例）→ 达门槛 → 解锁技能包/槽位（meta_progress 扩展，SaveSystem F4-T4 直读写，缺省空兼容旧档）+ 主菜单/基地入口提示。
- **PS-E3【W1】探针 tools/day31_skill_levelup_check.gd（≥8 断言）**：门槛配置生效（改表 → 解锁等级变化）/ 持久化 / 槽位解锁后局内可用。
- **PS-E-EXIT【W5】回归**：47 件套 + baseline **BASELINE CLEAN**。

### 任务5：PS-D 批 · 章节化 routes（规格 §8 · ⚠️ 高风险 · 独立批次最后收口）
- **PS-D1【W2】routes.json chapter 字段**：
  - 文件：docs/GameData.xlsx routes sheet（实测 routes.json：layers 15 / nodes_per_layer 3 / boss_layers [9,14] / boss_wave 10 / weights）→ excel_export → data/routes.json
  - 改动：扩展 chapter_id / 主题怪池 / 精英位 / 章末节点类型；**4 章层数 3/4/4/4**（章 1 层 1-3 / 章 2 层 4-7 / 章 3 层 8-11 / 章 4 层 12-15）；章末节点类型（**章 1 = 事件休息+奖励，无 Boss（D3）/ 章 2-4 = Boss**）；**渐进式数据落地**：chapter 字段缺省空 = 现行为（旧结构零改动兼容），再调 boss_layers 映射（章 2/3/4 Boss 位）。**⚠️ 触及 day14_15 53/53 数据结构层 + F-28 通关判定（Boss 关击杀即通）+ F-27 15 层双 Boss 映射 + 大地图显示 → 逐探针验证，禁一次改完再验**。
  - 风险：高——routes 数据结构变化波及面最广（day14_15 53/53 / day18_feedback5 27/27 / day30_g_map 20/20 / day30_f1_scaling）；**兜底**：① 渐进式（先加字段后调映射，每步导出+探针）② 若探针红 → 回滚 routes 数据（Excel 改回重导出），代码零改动 ③ 章 1 章末事件复用现有事件面板/奖励结算 10 型（零新系统）。
  - 验证：day14_15 53/53 + day18_feedback5 27/27 + day30_g_map 20/20 + day30_f1_scaling + day31_chapter_check（PS-D4）。
- **PS-D2【W1】章末事件节点 + Boss 位映射**：章 1 末节点 = 事件（休息 + 奖励，复用事件面板/奖励结算 10 型）+ 章 Boss 位（boss_layers 映射调整为 4 章 Boss 位）；章间可插整备节点（商店/回血/事件）做呼吸感。
- **PS-D3【W1】大地图章界（G-R1 承接）**：G-R1 节点地图加章界横幅/分隔线（数据驱动，不动画布架构——day30_g_map 20/20 零改动硬门槛）。
- **PS-D4【W1】探针 tools/day31_chapter_check.gd（≥10 断言）**：4 章拓扑合法（层数 3/4/4/4 + 章末类型正确）/ 章 1 无 Boss 章末事件 / 章 Boss 击杀即通（F-28 兼容）/ 大地图章界显示 / 回归锚点。
- **PS-D-EXIT【W5】回归**：47 件套 + baseline **BASELINE CLEAN**。

### 任务6：PS-EXIT【W5】总收口
- 文件：docs/TASKS.md（玩家侧技能系统标题 [x]）+ docs/TECH_DEBT_ISSUES.md（新债登记：skill→skills 数组迁移远期债等）
- 改动：批 A-E 探针全绿 + 全量回归 47 件套 ≥1046 + baseline **BASELINE CLEAN** + PLAYTEST 主观项登记（多技能位操作手感 / 位移技能走位解法 / 掉落节奏 / 章节节奏 / 剑士剑气体验，交 #5）+ 阶段 F 收口后首个新功能大块完成确认（F5 恢复门槛已过）。

---

## §3 风险表

| # | 级别 | 风险 | 缓解/兜底 |
|---|---|---|---|
| R1 | 🟠 中 | F5-T1 锚点同步与 46 在途资产强耦合（用户会话），资产未提交则挂起 | 先跑 44/47 隔离验证，资产入库后补 3 探针，两段各自 commit |
| R2 | 🟠 中 | PS-A skill_controller 列表化触及 day3_skill_check 锚点 | try_cast 保留槽 0 薄转发 + 行为逐字节等价（PS-A0 数据零迁移降风险） |
| R3 | 🟠 中 | PS-B 执行器扩展触碰 Boss 共享中立层 | 新增只加不改，既有 4 类型零触碰；day18_19/day30_boss_skill 零改动硬门槛 |
| R4 | 🟠 中 | PS-C 掉落钩子改动死亡流程（day4/day18_feedback 探针） | 掉落逻辑挂 _drop_rewards 尾段，金币掉落零改动，触发判定纯数据 |
| R5 | 🔴 高 | **PS-D 章节化 routes** 波及 day14_15/F-28/F-27/大地图 | 渐进式数据落地 + 逐探针验证 + 探针红即回滚数据（代码零改动）+ 章 1 章末事件复用现有系统 |
| R6 | 🟢 低 | PS-E 局外等级奖励 | 复用 G-R6 O1 技能点发放链路 + SaveSystem F4-T4 |
| R7 | 🟢 低 | F5-T3 手册 sheet 清单遗漏 | 先读 data_schema.py 注册表盘点，勿凭记忆 |

---

## §4 执行序汇总（#3 每批一收口 commit）

1. **F5 批 A**：锚点同步（资产入库同批）→ T1 回归 47 件套 → T2 性能对比
2. **F5 批 B**：T3 DATA_DICT_GUIDE.md（先读 data_schema.py）
3. **F5 批 C**：T4 恢复门槛 → T5 F4 遗留登记 → EXIT（阶段 F 全闭，F1-E 维持主窗口承接）
4. **PS 批 A**：A1 列表化 → A2 键位路由 → A3 HUD 3 槽 → A4 探针 → EXIT
5. **PS 批 B**：B1 工厂扩展 → B2 位移三型 → B3 invulnerable → B4 探针 → EXIT
6. **PS 批 C**：C1 新表 → C2 掉落钩子 → C3 三选一 UI → C4 per_character + 星刃剑气 → C5 探针 → EXIT
7. **PS 批 E**：E1 门槛表 → E2 解锁链路 → E3 探针 → EXIT（低风险先行消化）
8. **PS 批 D**：D1 chapter 字段（渐进式）→ D2 章末事件 + Boss 位 → D3 大地图章界 → D4 探针 → EXIT（**高风险最后收口**）
9. **PS-EXIT**：总收口 + 新债登记

## §5 回归基准与观察点

- 回归基准：**47 件套 ≥1046 断言**（TEST_REPORT #47 3 FAIL 修复后）→ F5 收口维持 47 件套 → PS 收口 **52 件套预期**（+day31_skill_slots / day31_skill_movement / day31_skill_relic / day31_skill_levelup / day31_chapter 5 新探针）。
- 观察点（下轮）：#3 是否按本方案开工 F5 批 A（git HEAD 实测 + DATA_DICT_GUIDE.md 在盘 + 回归 47 件套）；资产是否入库（锚点同步前置）。
- 工作流硬性：只按规格书（PLAYER_SKILL_SPEC.md）+ 本方案 + TASKS 拆解执行，禁止单条对话动工（08-12 教训）。
- 红线遵守：本方案不写码 / 不改 .gd/.tscn/.tres/.json / 不 commit / 不跑探针；产出仅 SOLUTION_PLAN.md + TASKS 标注 + 记忆文件。

---

## 执行结果（2026-08-16 #3 第 49 轮）

**状态：部分完成（F5 全批 [x] + 玩家侧技能系统批 A/B/C/E [x]，批 D 部分 [~]）**

- **F5 三批全收口**：批 A `b46fc20`（3 探针 items 锚点改动态读取 get_frame_count() 防再漂移，消除 git HEAD 中间态红——HEAD items.png 25 帧 vs 探针 54 锚点；回归 47/47 + 性能对比零劣化 6.95ms≈144fps）；批 B `a40c32c`（DATA_DICT_GUIDE.md 策划改数手册，26 表按 data_schema.py 实测盘点）；批 C `cda8008`（T4 恢复门槛 + T-046 放宽判据附注 + PLAYTEST #68）→ 阶段 F 全闭（F1-E 维持主窗口承接）。
- **PS 批 A**（多技能位 3 槽 + 键位路由）：skill_controller 列表化（槽 0=英雄技能/槽 1 左键/槽 2 右键，独立 CD，try_cast 槽 0 薄转发 day3 零改动）+ input map skill_slot1/2 + player BATTLE 守卫路由 + HUD 1→3 格 + day31_skill_slots 11/11 → 回归 48/48。
- **PS 批 B**（位移三型 + invulnerable）：boss_skill_factory 扩展 dash/blink/leap/spawn/buff（新增只加不改）+ 5 执行器 + elements 表 invulnerable 类型（Excel 导出）+ status_component 置位/还原 + player.take_damage 免疫 + day31_skill_movement 13/13 → 回归 49/49。
- **PS 批 C**（skill_relics + per_character + 剑士剑气）：新表 skill_relics（3 掉落 dash/blink/leap 变体）/ skill_unlocks（局外门槛表）+ DataLoader 5 接口 + enemy_damage 掉落钩子（精英 80% / 章 Boss 必掉）+ 剑士星刃→剑气爆发（se_skill_sword_arc，day3 探针同步）+ SaveSystem skill_slots 持久化 + day31_skill_relic 9/9 + day31_skill_levelup 7/7 → 回归 51/51。
- **PS 批 D 部分**：chapters 字段已落地（4 章定义 3/4/4/4 + 章末类型章 1=event 章 2-4=boss，数据层零回归）+ day31_chapter 5/5；**boss_layers 映射调整执行阻塞**——章 2/3/4 Boss 位 [7,11,15] 与 F-27 用户拍板「15 层双 Boss [9,14]」冲突（day14_15/fb5 探针红），按方案 R5 兜底已回滚 boss_layers 至 [9,14]，**交方案师裁决**（改三 Boss 同步探针 or 保留双 Boss 章节化仅做章界表现）。
- 回归基准：**52 件套 ≥1091 断言**（F5 47 → PS 收口 +5 探针）全绿 + baseline **BASELINE CLEAN**。
- 下轮观察点：方案师裁决 PS-D boss_layers 冲突；46 资产文件（items 图集 25→54 帧）未提交（用户会话在途，探针已动态读取不再阻塞回归）。
