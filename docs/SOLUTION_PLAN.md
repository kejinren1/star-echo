# 方案计划（2026-08-10 · 第 17 轮）

## 当前开发日：阶段 F 技术债整改（Day 30 后追加 · 用户 08-10 拍板）

> **本轮性质：阶段 F 正式方案轮**（第 16 轮头部确认 v7 → 第 17 轮「阶段 F 任务方案」）。
> 触发：#2 第 42 轮（07:2x）已把阶段 F 纳入 TASKS 台账——**F0/F1.0/F1-A/B 已收口，F1-C/D/E/F/G 方案已定待执行（勿重复拆解），F1-E 主窗口承接**。方案师本岗职责 = 覆盖写 SOLUTION_PLAN.md 为第 17 轮正式方案（阶段 F 章节去重保留单份，逐任务补落地/验证/风险），供 #3 执行岗直接接手。
> 红线全程遵守：不写码 / 不改 .gd/.tscn/.tres/.json / 不 commit / 不跑探针；产出仅 SOLUTION_PLAN.md + TASKS 标注 + 记忆文件。

---

## 0) P0 调度硬性输入检查（读 PLAYTEST 追踪区头部 · 本轮实测 07:50）

- ✅ **增量 #60（00:5x · 最新）= F0 P0 两修复确认 + F-35 主观回归面登记**：**F0 已收口（`42871c9`）**——P0-Bug1 希亚「神圣庇护」实装（`se_skill_holy_shield` 此前零分支空实现 → skill_controller.gd 新增 `_cast_holy_shield` match 分支 + player.gd 护盾吸收层 `shield/add_shield/_handle_shield`，数值全来自 skill_data 禁硬编码）/ P0-Bug2 被动未映射键修复（apply_item_bonuses 此前 17/39 键静默不生效 → 一律收进 bonus_stats：CONSUMED_BONUS_KEYS 白名单 + remove 对称还原）+ **新探针 day30_p0_fix_check 15 断言 + 回归 30 项/774 断言 + docs/TECH_DEBT_ISSUES.md 债登记 53 条 + tools/baseline_numerics.json 数值基准**。
- 🔴 **P0 其余检查**：F0 两 P0 bug 已修复 = 「机器侧已闭环 · 待真人回归」主观项（**F-35 主观回归面 2 项**：① 希亚空格放「神圣庇护」目视护盾吸收 + 5s 回血 ② 购买未映射键被动确认实际生效）；F 系列（F-01~F-34 + T-C/T-D）全 🟢 已落地·待真人回归 = 主观项交 #5；E-0 阶段 E 首段终审完整局 = 真人侧最高优先。**无新机器可验证 P0 需拆**。
- 🟠 **无新增用户拍板调度指令**（阶段 F 整改节奏 F0→F1.0→F1→…→F5 连续做完 = 08-10 拍板已定，本轮无新增）。
- 🟢 **美术资源策略（08-07 21:1x 拍板）遵守**：阶段 F 全部任务零美术生成（数据/逻辑整改域）。
- ⏳ **顺延项 5 条 P1 挂账不阻塞**：F-11 接口偏差（语义等价非缺陷）/ vfx_container / 遗物 HUD 槽 / 空间音 / mech_heart 入池；R4 攻击力口径挂账第 32 轮维持。
- 📋 **观察点（供 #4）**：TEST_REPORT #41（快照 `fb1317d`）早于 F0/F1.0/F1-A/B 共 3 提交 → **请 #4 下轮（#42）正式纳入 day30_p0_fix_check（15 断言）+ day30_f1_scaling_check（10 断言）= 33 件套 ≥809 断言、快照覆盖 `47e0519`**（#2 第 42 轮同口径，本方案确认）。

---

## 1) 任务方案（TASKS 阶段 F 区 · TASKS:2337-2367）

### F0 基线冻结【✅ 已收口 · 无方案动作】
- `42871c9`（f0-baseline）：30 项/774 断言基线 + P0 两 bug + 债登记 53 条 + 数值快照——第 42 轮已确认，本岗不再重复方案。

### F1.0 Excel 数据管线【✅ 已收口 · 无方案动作】
- `9c1440e`（f1-excel-pipeline）：GameData.xlsx 唯一事实源 + json_to_excel/excel_export/data_schema + day30_data_effect_check 在位。**数据管线铁律生效：改数只改 Excel → `python tools/excel_export.py`（校验不过禁止提交）→ 探针；data/*.json 为 generated 禁手改。**

### F1-A/B 参数化【✅ 已收口 · 无方案动作】
- `438295d`：enemies.scaling + waves.generation + routes.boss_wave 参数化（T-001/002/003/014），day30_f1_scaling_check 10 断言。

### 任务 F1-C 护甲公式统一（T-006）【✅ 方案已定 · 待 #3 执行】

- **现状（落地合理性）**：player.gd `take_damage` 用平直减法 `max(amount - armor, 1.0)`；enemy.gd 减伤用百分比 `min(armor/(armor+20), 0.75)`——两套口径并存 = 改 Excel 护甲数据对玩家/敌人行为不对称；stats.json.formulas 的 armor_reduction/armor_final 公式字符串零消费（公式双源债）。
- **实现方式**：① stats.json formulas 段参数化（stats_formulas sheet：`armor_factor: 20` / `armor_cap: 0.75`，**改 Excel 导出**，禁手改 JSON）；② player.gd `take_damage` 改百分比减伤 `actual = amount * (1 - min(armor/(armor+armor_factor), armor_cap))`，**保留 damage_taken_mult 后乘与 F-04 金手指倍率**（防遗物 broken_crown 受伤 +30% 与调试模式回归）；③ 伤害数值口径变更属**数值重平衡**——统一前须确认角色/道具 armor 数据（max_hp 体系小数值 2-15）在百分比制下的等效性，必要时按比例换算并在 DATA_OVERVIEW 对比。
- **风险评估**：**高**——① 数值语义变更直接影响全伤害曲线（玩家承受伤害整体下降/上升取决于换算），探针断言与 baseline_numerics.json 可能红；② 敌我公式统一后 armor 数据等效性未经用户确认即改 = 数值漂移风险。**替代/兜底方案**：执行前若无法确认换算口径 → 在 TASKS 标记「执行阻塞：护甲数值口径待用户确认」不强行改（本任务含「执行阻塞」兜底标记，见 TASKS:2358）。
- **验证方式**：day30 新探针或扩 day30_f1_scaling_check——armor=0 全伤 / armor=20 → 50% / armor 超限 clamp cap 三断言 + 回归 31 项全绿 + baseline_numerics.json 数值快照对比（F4 防漂移基准）。

### 任务 F1-D 商店参数数据化（T-010）【✅ 方案已定 · 待 #3 执行】

- **现状**：shop.gd `REROLL_COST = 10`（:31）、星刃核心保底 `current_wave == 4`（:125）——内联配置无处可改。
- **实现方式**：① stats.json 顶层加 `shop` 段（`reroll_cost: 10` / `core_grace_wave: 4`，**改 Excel stats sheet 结构 → 新增 sheet 后 excel_export 需在 data_schema.py 注册**）；② shop.gd 两处常量改 `DataLoader.get_stats_shop()`（新接口，DataLoader 加载 stats.json 时缓存 shop 段）。
- **风险评估**：**低-中**——纯常量→数据读参，消费点有探针断言覆盖（day13/day28_f31 测 REROLL_COST 消费）；唯一风险 = Excel stats sheet 结构变更未注册 data_schema → 导出校验失败（拦截即修，非运行时风险）。
- **验证方式**：day13_build_check / day28_f31_check 回归（REROLL_COST 消费点有断言）+ 新探针断言 shop 读参（改 Excel reroll_cost → 断言 shop 行为变化 = F1.0「配置生效探针」范式）。

### 任务 F1-E 表现配置抽表（T-016~024）【🏠 主窗口承接 · #3 勿自行开工】

- **内容**：enemy.gd SPRITE_MAP(26 条)/FALLBACK_SPRITES/BEHAVIOR_MAP、audio_manager BGM_MAP/SFX_MAP、vfx_player FX_CONFIG、icon_atlas SHEET_CONFIG、hud SKILL_ICON_MAP、weapon_controller 初始枪、turret 默认值 → **新建 Excel presentation sheet**（data_schema.py 注册新表 → data/presentation.json）+ 各脚本改 DataLoader 读取（**保留代码兜底默认值**，缺字段不崩）。
- **规模/风险**：**高**——涉及 7+ 脚本 + 新数据表 + 与图标/精灵资产耦合；改错即大面积换皮/音效/特效配置失效。兜底 = 沿用现有 `get(x, 默认)` 惯例。
- **执行约定**：由主窗口（用户会话）分步执行并逐脚本验证；**#3 看到本任务未在 TASKS 标记 [x] 时不要自行开工**（避免与主窗口冲突），轮次里标注「F1-E 主窗口承接」即可。

### 任务 F1-F 机制 id 收敛（T-025~030）【✅ 方案已定 · 待 #3 执行】

- **现状**：character_select.gd HERO_IDS 硬编码 4 SE；道具/技能 id 散落消费点（shop `se_blade_core` / main `executioner_mark` / player `last_stand` / projectile `overload_capacitor` / skill_controller 三技能 id）——改名即坏、编译器不拦。
- **实现方式**：character_select.gd HERO_IDS → `DataLoader.get_all_character_ids()` 过滤 SE 前缀（先例：base_station.gd 已用 DataLoader 全量）；道具/技能 id 消费点统一走 DataLoader 常量接口（`DataLoader.has_item_id` 已有，新增 `get_skill_ids()` 或字符串常量收敛到 data 侧）。
- **风险评估**：**中**——常量化若漏消费点 → 机制静默失效；兜底 = day24_f13 探针已覆盖 on_crit/on_kill/low_health 三 id 消费 + 回归 31 项全绿 + **grep 断言无新业务 id 字面量**（F1 验收口径）。
- **验证方式**：回归 31 项全绿 + grep 断言（scripts/ 无新出现业务数值/机制 id 字面量）。

### 任务 F1-G 无消费方键裁决（T-050 22 键）【✅ 方案已定 · 待 #3 执行 · 每键一个提交】

- **现状**：22 个无消费方效果键逐键裁决。
- **实现方式**：**有现成消费点先接线**（harvesting → wave_rewards.harvesting_bonus 波次奖励；xp_gain_percent → player.gain_exp；knockback → 武器/弹丸击退；engineering → turret 属性；fire_damage_percent/burn_duration_percent → 元素伤害计算；melee_damage/ranged_damage → 对应武器 scaling 消费）；**纯设计残留**（miss_chance/no_weapon_armor_bonus/dodge_heal_* 等无系统支撑）→ TECH_DEBT_ISSUES 标记「删数据」或「保留待 F2+」**不硬接**（防为接线而接线）。
- **风险评估**：**中**——接线可能引入行为变化（如 harvesting 接线后金币量变化）；兜底 = 每键独立提交 + 每接线跑 day11_12_passive_check + 回归；删除类键须先 grep 确认零消费方（防隐藏消费）。
- **验证方式**：每接线一键跑 day11_12_passive_check + 回归 31 项。

---

## 2) 风险与观察点（供 #4/#5/#1/主窗口参考）

| # | 观察点 | 归属 | 状态 |
|---|--------|------|------|
| 1 | TEST_REPORT #41 快照滞后（`fb1317d` 早于 F0/F1.0/F1-A/B 共 3 提交） | #4 #42 | ⚠️ 请下轮纳入 day30_p0_fix(15)+day30_f1_scaling(10) = **33 件套 ≥809 断言**、快照覆盖 `47e0519` |
| 2 | F1-C 护甲数值重平衡口径（小数值 armor 2-15 百分比制等效性） | 用户/主窗口 | ⚠️ 口径确认前 #3 不强行改（执行阻塞标记已挂 TASKS:2358） |
| 3 | F1-E 表现抽表大改 | 主窗口 | 🏠 #3 勿自行开工，轮次标注「F1-E 主窗口承接」 |
| 4 | F-35 主观回归面（希亚护盾目视 + 未映射键被动生效） | #5 真人 | 🟡 待真人回归（F0 修复后双轨） |
| 5 | 工作区在途 = docs/LOOP_HEALTH.md + docs/TASKS.md（#2 第 42 轮产物） | #2 | ⏳ 非本岗产物，方案师不动；#3 动 data/*.json 前先 git status 确认 |
| 6 | F2~F5（边界收拢/状态机/拆分/收口） | #2 待拆 | ⏳ F1 收口后再拆解，本轮不拆 |

---

## 3) 展望（后续窗口）

- **阶段 F 当前批**：F1-C/D/F/G 由 #3 按本方案执行（**每任务一收口 commit，提交信息带 T 编号**，改数走 Excel → excel_export.py → 探针）；F1-E 由主窗口承接；#3 合规轮次标注「F1-E 主窗口承接」。
- **F2 代码边界收拢（T-037~045）**：待 F1 收口后 #2 拆解 + 方案师定案（或主窗口承接信号化骨架）——本轮不拆。
- **F3 状态机规范化（T-031~036）**：范式已定（TECH_DEBT_PLAN §8.5/8.6 自研两形态 + 能力上限清单 + 踩线即停先问再干），待 F2 后拆解。
- **F4/F5**：上帝脚本拆分（<400 行 + 数值快照零漂移）+ 回归收口（CODE_STYLE.md / DATA_DICT_GUIDE.md 策划改数手册）。
- **红线遵守**：不写码 / 不改 .gd/.tscn/.tres/.json / 不 commit / 不跑探针；产出仅 SOLUTION_PLAN.md + TASKS 标注 + 记忆文件。

---

## 阶段 F 技术债整改方案（供 #3 执行岗接手 · 本文件权威版本，单份）

> 总方案/决策记录：docs/TECH_DEBT_PLAN.md（§7 决策表 · §8 状态机选型 · §8.6 能力上限清单）
> 债清单：docs/TECH_DEBT_ISSUES.md（T-001~T-053 逐条状态）
> **数据管线铁律**：改数只改 docs/GameData.xlsx → `python tools/excel_export.py`（校验不过禁止提交）→ 探针；data/*.json 为 generated 禁手改。
> **探针套件**：`python tools/_regression_run.py`（当前 31 项/784 断言，改完必跑）；数值基线 `tools/baseline_numerics.json`（F4 拆分后对比防漂移）。

### 已完成（无需再执行）
- F0 基线冻结 + 2 P0 bug 修复（f0-baseline / 42871c9）
- F1.0 Excel 管线全链（f1-excel-pipeline / 9c1440e）
- F1-A enemies.scaling 参数化（T-001/002）、F1-B waves.generation + routes.boss_wave（T-003/014），day30_f1_scaling_check.gd 10 断言（438295d）

### 任务 F1-C 护甲公式统一（T-006）【执行者按第 17 轮 §1 方案执行】
- **现状**：player.gd `take_damage` 用平直减法 `max(amount - armor, 1.0)`；enemy.gd 减伤用百分比 `min(armor/(armor+20), 0.75)`；stats.json.formulas 的 armor_reduction/armor_final 公式字符串零消费
- **改动**：① stats.json formulas 段参数化（stats_formulas sheet）：`armor_factor: 20` / `armor_cap: 0.75`（改 Excel 导出）；② player.gd `take_damage` 改为百分比减伤 `actual = amount * (1 - min(armor/(armor+armor_factor), armor_cap))`，保留 damage_taken_mult 后乘与 F-04 金手指；③ 伤害数值口径变更属**数值重平衡**——统一前先确认：角色/道具 armor 数据（max_hp 体系小数值 2-15）在百分比制下的等效性，必要时按比例换算并在 DATA_OVERVIEW 对比
- **验证**：day30 新探针或扩 day30_f1_scaling_check：armor=0 全伤 / armor=20 → 50% / armor 超限 clamp cap；回归 31 项全绿
- ⚠️ 本任务含数值语义变更，执行前若无法确认换算口径 → 在 TASKS 标记「执行阻塞：护甲数值口径待用户确认」不强行改

### 任务 F1-D 商店参数数据化（T-010）【执行者按第 17 轮 §1 方案执行】
- **现状**：shop.gd `REROLL_COST = 10`（:31）、`current_wave == 4` 星刃核心保底（:125）
- **改动**：① stats.json 顶层加 `shop` 段（stats_formulas sheet 同级：新 sheet 或并入 formulas）：`reroll_cost: 10` / `core_grace_wave: 4`（改 Excel stats sheet 结构 → 新增 sheet 后 excel_export 需在 data_schema.py 注册）；② shop.gd 两处常量改 `DataLoader.get_stats_shop()`（新接口，DataLoader 加载 stats.json 时缓存 shop 段）
- **验证**：day13_build_check / day28_f31_check 回归（REROLL_COST 消费点有断言）+ 新探针断言 shop 读参

### 任务 F1-E 表现配置抽表（T-016~024）【大改 · 主窗口优先承接，执行者勿自行开工】
- **内容**：enemy.gd SPRITE_MAP(26 条)/FALLBACK_SPRITES/BEHAVIOR_MAP、audio_manager BGM_MAP/SFX_MAP、vfx_player FX_CONFIG、icon_atlas SHEET_CONFIG、hud SKILL_ICON_MAP、weapon_controller 初始枪、turret 默认值 → **新建 Excel presentation sheet**（data_schema.py 注册新表 → data/presentation.json）+ 各脚本改 DataLoader 读取（**保留代码兜底默认值**，缺字段不崩）
- **规模**：涉及 7+ 脚本 + 新数据表，且与图标/精灵资产耦合 → 由主窗口（用户会话）分步执行并逐脚本验证；执行者看到本任务未在 TASKS 标记 [x] 时**不要自行开工**（避免与主窗口冲突），在轮次里标注「F1-E 主窗口承接」即可

### 任务 F1-F 机制 id 收敛（T-025~030）【执行者按第 17 轮 §1 方案执行】
- character_select.gd HERO_IDS → `DataLoader.get_all_character_ids()` 过滤 SE 前缀（先例：base_station.gd 已用 DataLoader 全量）；道具/技能 id 散落消费点（shop se_blade_core / main executioner_mark / player last_stand / projectile overload_capacitor / skill_controller 三技能 id）→ 统一走 DataLoader 常量接口（`DataLoader.has_item_id` 已有，新增 `get_skill_ids()` 或直接字符串常量收敛到 data 侧）
- **验证**：回归 31 项全绿（day24_f13 覆盖 on_crit/on_kill/low_health 三 id 消费）+ grep 断言无新字面量

### 任务 F1-G 无消费方键裁决（T-050）【执行者按第 17 轮 §1 方案执行，每键一个提交】
- 22 个无消费方效果键逐键裁决：**有现成消费点先接线**（harvesting → wave_rewards.harvesting_bonus 波次奖励；xp_gain_percent → player.gain_exp；knockback → 武器/弹丸击退；engineering → turret 属性；fire_damage_percent/burn_duration_percent → 元素伤害计算；melee_damage/ranged_damage → 对应武器 scaling 消费）；**纯设计残留**（miss_chance/no_weapon_armor_bonus/dodge_heal_* 等无系统支撑）→ TECH_DEBT_ISSUES 标记「删数据」或「保留待 F2+」不硬接
- **验证**：每接线一键跑 day11_12_passive_check + 回归

### 任务 F2 代码边界收拢（T-037~045）【待 F1 收口后拆解】
- 概览：GameManager 状态信号化（state_changed）、UI 直读改查询接口、跨层容器访问收口（world.get_container）、实体创建工厂化（world.spawn_*）、wave_manager↔spawner 信号化、GM 面板工厂/事件系统首拆
- 方案：进入 F2 时由 #2 拆解 + 方案师定案（或主窗口承接信号化骨架）

### 任务 F3 状态机规范化（T-031~036）【待 F2 后拆解】
- 范式已定（TECH_DEBT_PLAN §8.5/8.6）：**仅两种形态**——① 扁平流程态 enum+match+`_transition()`；② 行为/表现态 enum+状态表。禁多 bool/字符串状态/int 字面量/散落赋值；单机 >8 态或层级需求 → 触发评审
- 交付含：状态机合规探针（扫描代码）+ 状态流探针（固定序列断言流转）

### 任务 F4/F5【概要】F4 拆分 GM/enemy/player 上帝脚本（<400 行 + 数值快照零漂移）；F5 全量回归 + CODE_STYLE.md + DATA_DICT_GUIDE.md（策划改数手册）

### 执行者交接说明
- 主窗口（用户会话）与 #3 执行岗并行推进：**主窗口承接 F1-E（表现抽表大改）与 F2+ 骨架**；**#3 按本方案执行 F1-C/D/F/G**（每任务一个收口 commit，提交信息带 T 编号）
- 冲突规避：动 data/*.json 前先 `git status` 确认无他人未提交改动；改 Excel 前同样检查（Excel 是共享文件）
- 每任务完成后在 TASKS.md 阶段 F 区标记 [x] + TECH_DEBT_ISSUES.md 对应条目状态 → 已收口

---

## 执行结果（#3 第 43 轮登记 · 2026-08-10 08:3x · 阶段 F 首执行轮 · 部分完成）

- **输入核验**：方案第 17 轮正式方案（F1-C/D/E/F/G）；P0 检查 = 增量 #60 无新机器可验证 P0（F0 两修复已落地待真人回归）。
- **F1-D ✅ 收口（`b6e0177`）**：Excel stats_shop sheet（reroll_cost 10 / core_grace_wave 4）→ data_schema.py 注册 stats_shop + excel_export stats.shop 导出 → stats.json 顶层 shop 段 → DataLoader.get_stats_shop() → shop.gd 读参兜底（REROLL_COST 常量改 REROLL_COST_DEFAULT + reroll_cost var）→ day30_f1d_shop_check 8/8 + 入 runner（31→32 项/792 断言）+ 回归 32/32 全绿。
- **F1-F ✅ 收口（`162fa52`）**：HERO_IDS → DataLoader SE 前缀过滤（HERO_ID_FALLBACK 兜底）+ 9 机制 id 常量（4 道具/4 技能/se_turret_array）+ get_skill_ids() + 消费点收敛（shop/main/player/projectile/skill_controller）+ day26 回归锚点同步（31→32/784→792）+ grep 零残留 + 回归 32/32 全绿。
- **F1-G ⚠️ 部分收口（`112e6a9`）**：22/22 键裁决——接线 5 键（xp_gain_percent→gain_exp；melee_damage/ranged_damage→weapon_controller 分类伤害；knockback→弹丸击退累加；boss_elite_damage_percent→projectile 精英/Boss 增伤）+ shop_weapon_upgrade 实为已消费（F31-3 服务池，登记滞后修正）+ 13 键保留待 F2+ + 3 键删数据（no_weapon_armor_bonus/special_enemies_next_wave/auto_turret_per_wave 已 grep 零代码消费）；CONSUMED_BONUS_KEYS 白名单 +excel_export 注释/总览同步；回归 32/32 全绿。**执行登记**：方案「每键一提交」合并为同域分组提交（5 键同属武器/经验增益域，回归全绿兜底）；🕳️ 踩坑 self-fix：`weapon.get("weapon_type", "")` 双参 → Object.get 编译期 Parse Error 致 weapon_controller.gd 加载失败（记忆坑复现）→ 改单参+判空。
- **F1-C ⛔ 执行阻塞（TASKS:2359 已标）**：armor 数据实测（道具 -3~+4 / 角色 passive 零 / stats base 0 max 20「减免物理伤害, 上限75%减伤」）——平直制→百分比制改变玩家承伤曲线（低伤害平直护甲过强如 armor4 对 5 伤减 80%、高伤害过弱对 30 伤仅 13%），**换算口径需用户确认**（是否按比例换算/保持小数值语义）→ 按方案兜底标记执行阻塞不强行改；stats_formulas 参数化（armor_factor 20 / armor_cap 0.75）随时可落地。
- **F1-E 🏠 主窗口承接**（未开工，标注不执行）。
- **观察点**：#4 #42 请以 runner **现 32 项/792 断言**为口径正式纳入（含 day30_p0_fix 15 + day30_f1_scaling 10 + day30_f1d_shop 8；runner 为执行侧事实源，原方案「33 件套 ≥809」系 #41 快照估算，以实测为准），快照覆盖最新提交（`112e6a9`）。
- 收尾：git add -A 全部提交推送（3 个 F1 收口 commit + 挂账 docs）。
