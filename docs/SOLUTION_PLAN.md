# 方案计划（2026-08-09 · 第 16 轮）

## 当前开发日：Day 28（全量测试 + 性能 · #4 域；性能段方案 C 已闭环）

> **本轮性质：头部确认版 v7**（第 15 轮「F-31 收口确认」→ 第 16 轮「性能段闭环 + 用户直派链入库确认 + 头部刷新」）。
> 触发：**Day 28 性能段（#4 域，跨 10 轮挂账）已由方案 C 机器侧名义闭环**（`510ef61` 7/7 全绿，用户拍板「仅补最小探针」）+ **用户直派链全部入库**（`e0490c2` 艾琳全动画 / `908d1f5` 项目迁移 / F-32/F-33/F-34）——Day 28 唯一客观开发任务集 D28-F31-1~3 + EXIT 已全 [x]（第 15 轮确认），**无开发任务待方案化**；剩余 [ ]（TASKS:2284-2285）= **#4 域**（TEST_REPORT #41 正式覆盖三新探针 + baseline），无需开发方案。
> 方案师本岗仅覆盖写头部确认版 + TASKS 标注，红线全程遵守（不写码 / 不改 .gd/.tscn/.tres/.json / 不 commit / 不跑探针）。

---

## 0) P0 调度硬性输入检查（读 PLAYTEST 追踪区头部 · 本轮实测 07:50）

- ✅ **Day 28 性能段（#4 域，跨 10 轮挂账）→ 机器侧名义闭环**：用户拍板方案 C「仅补最小探针」（不降级不核查 #4）→ 反馈专员执行 `tools/day28_perf_check.gd`（`510ef61`）**7/7 全绿**——同屏 50 chaser（wave 10 成长）30 帧预热 + 120 帧计时：**平均逻辑帧 6.88ms（≈145fps）· 最差帧 14.9ms · 容器敌数 50/50 零意外死亡 · 引擎 static 53MB**（宽松阈值 512MB）→ **性能余量巨大，佐证 D 阶段架构评估**（TASKS:1932「无粒子系统/特效自动 queue_free/并发=命中数级，风险低」）；**真机帧率体感主观项由 E-0 终审完整局承接**（不新增表格行防噪音）。
- ✅ **用户直派链（先例 788af22/e0490c2 延续）已全部入库，零 #2 拆解需求**：
  - `e0490c2` **Day29 艾琳全动画实装**（用户 08-08 21:0x 直派 ART/RAW/elin 28 JPG → `gen_elin_anim_jpg.py` 管线（抠底容差 100 → bbox → 统一窗口 → 54px 缩放 → 64×64 帧）→ idle 320×64·5帧 / walk 640×64·10帧 / attack 320×64·5帧 / skill 384×64·6帧 / hit 128×64·2帧 + **hit 受击动画**（`_play_hit_anim` + 状态机禁打断 + take_damage 触发）→ day29_elin_anim_check **14/14**）
  - `908d1f5` **项目迁移 D:/Program Files\30DAYS → D:/30DAYS**（根治 Program Files ACL 写盘间歇失败致 Godot 缓存损坏/段错误；robocopy 排除 .godot* 缓存与 *.log；工具/docs/bat 路径批量替换；7 自动化 cwds 已同步；素材归档 `.godot_tmp_backup/`）——**迁移后新路径 `--path "D:/30DAYS"` 复验 day29 探针 14/14 全绿 = 迁移无破坏**
  - `675ef4b` **F-32 攻击索敌门控 + SKILL 动画守卫**（weapon_controller 开火前 `_has_enemy_in_range` 射程门控 → idle/walk 恢复正常；`_play_attack_anim` 加 skill 守卫 → 空格技能 6 帧完整播放；day29_attack_check 15/15 + day13 回归同步）
  - `7273814` **F-33 动画左右转向**（`_update_facing` 按水平移动方向驱动 flip_h，idle/walk/attack/skill/hit 共享朝向；day29_attack +§4 转向 5 断言 = **20/20**）
  - `ae6b0cb` **F-34 物品描述百分比双 % 修复**（根因 = desc_builder.effects_text :69 `suffix="%%"` 是值变量原样插入，`%%` 转义仅适用格式串本身 → 改 `"%"`；纯显示层零数值影响；day18_feedback5 三处 tooltip 断言**加 `not contains("%%")` 防子串掩盖回归**，27/27）
  - 护栏链：以上全链回归 **29/29（759 断言）PASS** + 工作区 CLEAN（迁移后）。
- ✅ **增量 #59（01:4x · 最新）= F-34 登记轮**：无新机器可验证 P0（F-34 🟢 已落地 · 待真人目视「商店悬停带百分比卡显示单 %」= 主观项）。
- 🔴 **P0 其余检查**：F 系列（F-01~F-34 + T-C/T-D）全 🟢「已落地 · 待真人回归」= 主观项交 #5；E-0 阶段 E 首段终审完整局（含 U-1 目视 + F-32/F-33 转向回归面）= 真人侧最高优先；无其他新机器可验证 P0。
- 🟠 **美术资源策略（08-07 21:1x 拍板）遵守**：本轮零美术任务（性能探针纯逻辑；用户直派动画/素材管线为例外先例）。
- ⏳ **顺延项 5 条 P1 挂账不阻塞**：F-11 接口偏差（语义等价非缺陷）/ vfx_container / 遗物 HUD 槽 / 空间音 / mech_heart 入池；R4 攻击力口径挂账第 31 轮维持。

---

## 1) 任务方案（TASKS Day 28 区 · 当前状态核验）

### 任务 D28-F31-1~3 + EXIT【已全 [x] 收口 · 无方案动作】

> 第 14 轮方案（F-31 正式方案）为 #3 16:35 窗口执行依据，已全部执行完毕（`f30d402` + `f0606bf`，day28_f31_check 26/26 + 回归 29/29 759 断言 + BASELINE CLEAN，第 15 轮确认）。**本岗不再重复方案**。

### 任务（TASKS:2284-2285）【#4 域 · 无需开发方案】

- [ ] 自动化测试 + 性能（帧率/内存/同屏敌人数）——**#4 域**：性能段已由**方案 C 闭环**（`510ef61` 最小探针 7/7 全绿，跨 10 轮挂账解除）；真机帧率体感主观项由 E-0 终审承接（#5 域）。
- [ ] 回归 `baseline_check`；产出 `docs/TEST_REPORT.md`——**#4 域**：TEST_REPORT 止于 **#40**（29 件套 759 断言，快照 HEAD=`1763f6c`）**早于其后 12 提交**（`e0490c2`/`908d1f5`/`72490cb`/`510ef61`/`9943437`/`675ef4b`/`e8ffc94`/`90c4a43`/`7273814`/`a5d180a`/`ae6b0cb`/`acaa2bf`）→ **请 #4 下轮（#41）正式纳入 day28_perf_check（7 断言）+ day29_elin_anim_check（14 断言）+ day29_attack_check（20 断言）= 三十二件套 ≥800 断言、快照覆盖 `acaa2bf`**（#55/#56/#57/#58/#59 累计请求，#2 第 41 轮已合并口径，本方案同口径确认）。

---

## 2) 风险与观察点（供 #4/#5/#1 参考，非 #3 执行输入）

| # | 观察点 | 归属 | 状态 |
|---|--------|------|------|
| 1 | TEST_REPORT #40 快照滞后（`1763f6c` → 需覆盖 `acaa2bf`，+12 提交含 Day29 全动画/迁移/F-32/F-33/F-34/性能方案C） | #4 #41 | ⚠️ 请下轮修复 |
| 2 | 三新探针未入 runner（day28_perf 7 / day29_elin 14 / day29_attack 20 = 41 断言） | #4 #41 | ⚠️ 请下轮并入 → 三十二件套 ≥800 |
| 3 | Day 28 性能段挂账（跨 10 轮） | #4/已闭环 | ✅ 方案 C 名义闭环（真机帧率交 E-0 主观承接） |
| 4 | U-1 艾琳全动画 🟢 已实装（含 F-32/F-33 修复） | 真人/用户 | 🟡 待真人目视（含 idle 重复帧判定 + 转向目视） |
| 5 | F-34 百分比双%修复 | 真人 | 🟢 待真人目视（商店悬停带百分比卡显示单 %） |
| 6 | F-31 真人回归面 3 子项（商店不再刷起始武器 / 升级面板纯属性+进化 / 铁砧 120G 闭环） | #5 真人 | 🟢 待真人回归 |
| 7 | E-0 阶段 E 首段终审完整局（含 15 关双 Boss + F-16~F-34 全链 + 局外 S-1/N-1/P-1） | #5 真人 | 🔴 真人侧最高优先 |
| 8 | R4 攻击力口径挂账 | Owner | ⏳ 第 31 轮维持 |

---

## 3) 展望（后续窗口）

- **Day 28**：F-31 已收口 + 性能段已闭环 → 剩余全为 #4 域（#41 正式覆盖三新探针 = 三十二件套 ≥800 断言）；方案师维持头部确认轮。
- **Day 29 人工试玩 + 修复** = 真人域（已由用户直派艾琳全动画/F-32/F-33/F-34 提前实质开工；#5 收真人反馈 + #3 按需修复）——若后续产生开发任务，方案师再定案。
- **Day 30 发布准备** = #3/#1 域（build_release.py / Steam 构建 / 资产上传）——若 #1 裁决需 #3 参与，方案师再写正式方案；当前 #2 已转维护模式零拆解。
- **红线遵守**：不写码 / 不改 .gd/.tscn/.tres/.json / 不 commit / 不跑探针；产出仅 SOLUTION_PLAN.md + TASKS 标注 + 记忆文件。

---

## 执行结果（2026-08-09 08:3x · #3 第 41 轮窗口）

**【合规等待】**

- 输入核验：方案第 16 轮（头部确认版 v7）= D28-F31-1~3 + EXIT 全 [x] 收口；剩余 [ ]（TASKS:2284-2285）= **#4 域**（TEST_REPORT #41 正式覆盖 day28_perf 7 / day29_elin 14 / day29_attack 20 = 三十二件套 ≥800 断言 + baseline），**无开发任务待 #3 执行**。
- P0 检查：PLAYTEST 追踪区增量 #59 最新（F-34 登记轮）+ 方案 §0 双一致 → 🔴 **机器可验证 P0 零命中**（F 系列全 🟢 已落地·待真人回归 = 主观项交 #5；E-0 终审完整局 = 真人侧最高优先）。
- 动作：零代码改动、零探针运行（无执行输入）；TASKS 无本岗可标记项；git 实测 HEAD=`acaa2bf`，工作区在途 4 份 docs（PROGRESS/TASKS/LOOP_HEALTH/本方案 = #1/#2/#4/方案师产出）零游戏代码 → 收尾同步一并提交推送。
- 后续轮次动作模板：#3 维持合规等待直至方案师落盘新开发任务方案（Day 30 发布准备候选 = #1 裁决；Day 29 真人反馈如有修复项 → 方案师定案后执行）。


---

## 阶段 F 技术债整改方案（2026-08-10 主窗口录入 · 供 #3 执行岗接手）

> 总方案/决策记录：docs/TECH_DEBT_PLAN.md（§7 决策表 · §8 状态机选型 · §8.6 能力上限清单）
> 债清单：docs/TECH_DEBT_ISSUES.md（T-001~T-053 逐条状态）
> **数据管线铁律**：改数只改 docs/GameData.xlsx → `python tools/excel_export.py`（校验不过禁止提交）→ 探针；data/*.json 为 generated 禁手改。
> **探针套件**：`python tools/_regression_run.py`（当前 31 项/784 断言，改完必跑）；数值基线 `tools/baseline_numerics.json`（F4 拆分后对比防漂移）。

### 已完成（无需再执行）
- F0 基线冻结 + 2 P0 bug 修复（f0-baseline / 42871c9）
- F1.0 Excel 管线全链（f1-excel-pipeline）
- F1-A enemies.scaling 参数化（T-001/002）、F1-B waves.generation + routes.boss_wave（T-003/014），day30_f1_scaling_check.gd 10 断言

### 任务 F1-C 护甲公式统一（T-006）【执行者按此方案执行】
- **现状**：player.gd `take_damage` 用平直减法 `max(amount - armor, 1.0)`；enemy.gd 减伤用百分比 `min(armor/(armor+20), 0.75)`；stats.json.formulas 的 armor_reduction/armor_final 公式字符串零消费
- **改动**：① stats.json formulas 段参数化（stats_formulas sheet）：`armor_factor: 20` / `armor_cap: 0.75`（改 Excel 导出）；② player.gd `take_damage` 改为百分比减伤 `actual = amount * (1 - min(armor/(armor+armor_factor), armor_cap))`，保留 damage_taken_mult 后乘与 F-04 金手指；③ 伤害数值口径变更属**数值重平衡**——统一前先确认：角色/道具 armor 数据（max_hp 体系小数值 2-15）在百分比制下的等效性，必要时按比例换算并在 DATA_OVERVIEW 对比
- **验证**：day30 新探针或扩 day30_f1_scaling_check：armor=0 全伤 / armor=20 → 50% / armor 超限 clamp cap；回归 31 项全绿
- ⚠️ 本任务含数值语义变更，执行前若无法确认换算口径 → 在 TASKS 标记「执行阻塞：护甲数值口径待用户确认」不强行改

### 任务 F1-D 商店参数数据化（T-010）【执行者按此方案执行】
- **现状**：shop.gd `REROLL_COST = 10`（:31）、`current_wave == 4` 星刃核心保底（:125）
- **改动**：① stats.json 顶层加 `shop` 段（stats_formulas sheet 同级：新 sheet 或并入 formulas）：`reroll_cost: 10` / `core_grace_wave: 4`（改 Excel stats sheet 结构 → 新增 sheet 后 excel_export 需在 data_schema.py 注册）；② shop.gd 两处常量改 `DataLoader.get_stats_shop()`（新接口，DataLoader 加载 stats.json 时缓存 shop 段）
- **验证**：day13_build_check / day28_f31_check 回归（REROLL_COST 消费点有断言）+ 新探针断言 shop 读参

### 任务 F1-E 表现配置抽表（T-016~024）【大改 · 主窗口优先承接，执行者勿自行开工】
- **内容**：enemy.gd SPRITE_MAP(26 条)/FALLBACK_SPRITES/BEHAVIOR_MAP、audio_manager BGM_MAP/SFX_MAP、vfx_player FX_CONFIG、icon_atlas SHEET_CONFIG、hud SKILL_ICON_MAP、weapon_controller 初始枪、turret 默认值 → **新建 Excel presentation sheet**（data_schema.py 注册新表 → data/presentation.json）+ 各脚本改 DataLoader 读取（**保留代码兜底默认值**，缺字段不崩）
- **规模**：涉及 7+ 脚本 + 新数据表，且与图标/精灵资产耦合 → 由主窗口（用户会话）分步执行并逐脚本验证；执行者看到本任务未在 TASKS 标记 [x] 时**不要自行开工**（避免与主窗口冲突），在轮次里标注「F1-E 主窗口承接」即可

### 任务 F1-F 机制 id 收敛（T-025~030）【执行者可执行】
- character_select.gd HERO_IDS → `DataLoader.get_all_character_ids()` 过滤 SE 前缀（先例：base_station.gd 已用 DataLoader 全量）；道具/技能 id 散落消费点（shop se_blade_core / main executioner_mark / player last_stand / projectile overload_capacitor / skill_controller 三技能 id）→ 统一走 DataLoader 常量接口（`DataLoader.has_item_id` 已有，新增 `get_skill_ids()` 或直接字符串常量收敛到 data 侧）
- **验证**：回归 31 项全绿（day24_f13 覆盖 on_crit/on_kill/low_health 三 id 消费）+ grep 断言无新字面量

### 任务 F1-G 无消费方键裁决（T-050）【执行者可执行，每键一个提交】
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

## 阶段 F 技术债整改方案（2026-08-10 主窗口录入 · 供 #3 执行岗接手）

> 总方案/决策记录：docs/TECH_DEBT_PLAN.md（§7 决策表 · §8 状态机选型 · §8.6 能力上限清单）
> 债清单：docs/TECH_DEBT_ISSUES.md（T-001~T-053 逐条状态）
> **数据管线铁律**：改数只改 docs/GameData.xlsx → `python tools/excel_export.py`（校验不过禁止提交）→ 探针；data/*.json 为 generated 禁手改。
> **探针套件**：`python tools/_regression_run.py`（当前 31 项/784 断言，改完必跑）；数值基线 `tools/baseline_numerics.json`（F4 拆分后对比防漂移）。

### 已完成（无需再执行）
- F0 基线冻结 + 2 P0 bug 修复（f0-baseline / 42871c9）
- F1.0 Excel 管线全链（f1-excel-pipeline）
- F1-A enemies.scaling 参数化（T-001/002）、F1-B waves.generation + routes.boss_wave（T-003/014），day30_f1_scaling_check.gd 10 断言

### 任务 F1-C 护甲公式统一（T-006）【执行者按此方案执行】
- **现状**：player.gd `take_damage` 用平直减法 `max(amount - armor, 1.0)`；enemy.gd 减伤用百分比 `min(armor/(armor+20), 0.75)`；stats.json.formulas 的 armor_reduction/armor_final 公式字符串零消费
- **改动**：① stats.json formulas 段参数化（stats_formulas sheet）：`armor_factor: 20` / `armor_cap: 0.75`（改 Excel 导出）；② player.gd `take_damage` 改为百分比减伤 `actual = amount * (1 - min(armor/(armor+armor_factor), armor_cap))`，保留 damage_taken_mult 后乘与 F-04 金手指；③ 伤害数值口径变更属**数值重平衡**——统一前先确认：角色/道具 armor 数据（max_hp 体系小数值 2-15）在百分比制下的等效性，必要时按比例换算并在 DATA_OVERVIEW 对比
- **验证**：day30 新探针或扩 day30_f1_scaling_check：armor=0 全伤 / armor=20 → 50% / armor 超限 clamp cap；回归 31 项全绿
- ⚠️ 本任务含数值语义变更，执行前若无法确认换算口径 → 在 TASKS 标记「执行阻塞：护甲数值口径待用户确认」不强行改

### 任务 F1-D 商店参数数据化（T-010）【执行者按此方案执行】
- **现状**：shop.gd `REROLL_COST = 10`（:31）、`current_wave == 4` 星刃核心保底（:125）
- **改动**：① stats.json 顶层加 `shop` 段（stats_formulas sheet 同级：新 sheet 或并入 formulas）：`reroll_cost: 10` / `core_grace_wave: 4`（改 Excel stats sheet 结构 → 新增 sheet 后 excel_export 需在 data_schema.py 注册）；② shop.gd 两处常量改 `DataLoader.get_stats_shop()`（新接口，DataLoader 加载 stats.json 时缓存 shop 段）
- **验证**：day13_build_check / day28_f31_check 回归（REROLL_COST 消费点有断言）+ 新探针断言 shop 读参

### 任务 F1-E 表现配置抽表（T-016~024）【大改 · 主窗口优先承接，执行者勿自行开工】
- **内容**：enemy.gd SPRITE_MAP(26 条)/FALLBACK_SPRITES/BEHAVIOR_MAP、audio_manager BGM_MAP/SFX_MAP、vfx_player FX_CONFIG、icon_atlas SHEET_CONFIG、hud SKILL_ICON_MAP、weapon_controller 初始枪、turret 默认值 → **新建 Excel presentation sheet**（data_schema.py 注册新表 → data/presentation.json）+ 各脚本改 DataLoader 读取（**保留代码兜底默认值**，缺字段不崩）
- **规模**：涉及 7+ 脚本 + 新数据表，且与图标/精灵资产耦合 → 由主窗口（用户会话）分步执行并逐脚本验证；执行者看到本任务未在 TASKS 标记 [x] 时**不要自行开工**（避免与主窗口冲突），在轮次里标注「F1-E 主窗口承接」即可

### 任务 F1-F 机制 id 收敛（T-025~030）【执行者可执行】
- character_select.gd HERO_IDS → `DataLoader.get_all_character_ids()` 过滤 SE 前缀（先例：base_station.gd 已用 DataLoader 全量）；道具/技能 id 散落消费点（shop se_blade_core / main executioner_mark / player last_stand / projectile overload_capacitor / skill_controller 三技能 id）→ 统一走 DataLoader 常量接口（`DataLoader.has_item_id` 已有，新增 `get_skill_ids()` 或直接字符串常量收敛到 data 侧）
- **验证**：回归 31 项全绿（day24_f13 覆盖 on_crit/on_kill/low_health 三 id 消费）+ grep 断言无新字面量

### 任务 F1-G 无消费方键裁决（T-050）【执行者可执行，每键一个提交】
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
