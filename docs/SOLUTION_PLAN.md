# 方案计划（2026-08-11 · 第 18 轮）

## 当前开发日：阶段 F 技术债整改（F1 区收尾）

> **本轮性质：阶段 F 收尾方案轮**（第 17 轮正式方案 → 第 18 轮刷新）。
> 触发：#2 第 43 轮（08-11 07:2x）确认 **F1-C 执行阻塞解除**（用户 08-10 主窗口已拍板口径）+ **新拆 F1-G-尾**（T-050 收尾：3 键删数据落 Excel）；#3 第 43 轮（08-10 08:3x）执行轮已收口 F1-D/F1-F/F1-G 主键。方案师本岗职责 = 覆盖写 SOLUTION_PLAN.md 为第 18 轮（保留阶段 F 权威章节单份 + #3 第 43 轮执行结果登记），为 F1-G-尾 出正式方案，刷新 F1-C 为「待执行」状态。
> 红线全程遵守：不写码 / 不改 .gd/.tscn/.tres/.json / 不 commit / 不跑探针；产出仅 SOLUTION_PLAN.md + TASKS 标注 + 记忆文件。

---

## 0) P0 调度硬性输入检查（读 PLAYTEST 追踪区头部 · 本轮实测 08:00）

- ✅ **增量 #61（08-11 00:4x · 反馈专员：无待处理反馈轮）= 无新机器可验证 P0**：F-35 机器侧双确认（#4 #42 已正式纳入 day30_p0_fix 等，32/32 · 792 断言全绿首跑）+ **F1-G 接线 5 键主观回归面扩展**（xp_gain_percent / melee+ranged / knockback / boss_elite_damage_percent 并入 F-35 ② = 真人回归面：接线后「买了有感觉」）——主观项交 #5，无机器侧缺口。
- 🔴 **F1-C 执行阻塞解除（本轮最重要动态）**：**用户 2026-08-10 主窗口拍板「简单一些，伤害-护甲=最终伤害」→ 统一平直减法，不做百分比制**（#2 第 43 轮 07:2x 已在 TASKS:2360 刷新为「执行阻塞解除 · 方案定稿待执行」）——第 17 轮方案的「执行阻塞兜底」消解，F1-C 从 ⛔ 转 ✅ 待 #3 执行。
- 🟠 **无新增用户拍板调度指令**（阶段 F 整改节奏 F0→F1.0→F1→…→F5 连续做完 = 08-10 拍板已定，本轮无新增）。
- 🟢 **美术资源策略（08-07 21:1x 拍板）遵守**：阶段 F 剩余任务（F1-C 公式统一 / F1-G-尾 删数据）零美术生成。
- ⏳ **顺延项 5 条 P1 挂账不阻塞**：F-11 接口偏差（语义等价非缺陷）/ vfx_container / 遗物 HUD 槽 / 空间音 / mech_heart 入池；R4 攻击力口径挂账第 33 轮维持。
- 📋 **观察点（供 #3/#4）**：TEST_REPORT #42（08-10 18:40 · HEAD=`640ce5f`）已产出 = 32/32 · 792 断言全绿 + day29_elin 14/14 + day29_attack 20/20（单独运行）= **34 探针 826 断言全 CLEAN**；**在途 action item 1 项 = day29_elin/day29_attack 仍未入 `_regression_run.py` PROBES → 请求 #3 并入 = 34 件套 826 一键跑通**（#3/#4 域）。工作区在途 = docs 5（LOOP_HEALTH/PROGRESS/SOLUTION_PLAN/TASKS/TEST_REPORT）+ tools 3（data_schema/excel_export/json_to_excel = F1.0 管线余项）+ perfect-pixels 工具 + `~$GameData.xlsx` 临时锁——**零游戏代码在途**。

---

## 1) 任务方案（TASKS 阶段 F 区 · TASKS:2338-2370）

### 任务 F1-C 护甲公式统一（T-006）【✅ 方案已定 · 用户 08-10 拍板 · 执行阻塞解除 · 待 #3 执行】

- **现状（落地合理性，本轮实测确认）**：enemy.gd `take_damage` :755 注释「考虑护甲减伤」、**:761-763 百分比公式** `var reduction = min(armor / (armor + 20.0), 0.75)`（实测现行 :762，行号与第 17 轮一致未漂移）；player.gd `take_damage` :466 平直减法 `max(amount - armor, 1.0)`——两套口径并存，改 Excel 护甲数据对敌我行为不对称；stats.json.formulas 的 armor_reduction/armor_final 公式字符串零消费（公式双源债）。
- **用户拍板口径（2026-08-10 主窗口）：「伤害-护甲=最终伤害」平直减法，不做百分比制**。
- **实现方式（改动收敛到 1 处）**：① enemy.gd :761-763 百分比公式改平直减法 `actual_damage = max(amount - armor, 1.0)`（与 player.gd :466 完全同式）；② player.gd 零改动（玩家承伤数值零漂移）；③ stats.json formulas 段 `armor_reduction`/`armor_final` 两个死公式字符串 → 标记删除（并入 F1-G-尾 同轮在 T-050 注记或 TECH_DEBT_ISSUES 登记「已删除」，原 armor_factor=20/armor_cap=0.75 参数化**作废**）。⚠️ #3 以 **`min(armor / (armor + 20.0), 0.75)` 字符串搜索锚定**（D39 语义锚定原则），勿死记行号。
- **风险评估**：**低**（第 17 轮「高」→ 拍板后降级）——玩家侧零改动 = 玩家数值零漂移；敌人侧 armor 数据实测 **23 敌仅 `helmet_alien`=3、其余全 0** → 改式后仅 helmet_alien 受 3 点平直减（原百分比制约 13% → 平直减 3 点，量级微乎其微）。
- **验证方式**：day30 新探针或扩 day30_f1_scaling_check——enemy 侧 armor=0 全伤 / armor=3 → 减 3（保底 ≥1.0）/ 大 armor 保底 1.0 不归零 + **player 侧回归锚点**（day4/day18_feedback 受击数值断言不变 = 玩家零漂移实证）+ 回归 32 项全绿 + baseline_numerics.json 对比。

### 任务 F1-G-尾 删数据 3 键落 Excel（T-050 收尾 · #2 第 43 轮新拆）【✅ 本轮方案已定 · 待 #3 执行】

- **落地合理性（本轮实测全确认）**：3 键 = `no_weapon_armor_bonus`（anvil 铁砧 items.json:574）/ `special_enemies_next_wave`（bait 诱饵 :351）/ `auto_turret_per_wave`（mech_heart 机械之心 :683）——**F1-G 主键 `112e6a9` 已裁决「删数据」（grep 零机制消费），当时因「下次改 Excel 时移除」挂账**；本轮实测 scripts/ 全域**零机制消费**（仅 desc_builder.gd 中文映射 3 处 :20/:44/:50 = 显示层死映射，非消费方）。**只删键不删条目**：bait 剩 `damage_percent:8`、anvil 剩 `shop_weapon_upgrade:true`（F31-3 服务键，已消费）、mech_heart 剩 `engineering:10 + structure_damage_percent:50`——其余键零影响。⚠️ TASKS:2363 旧注「3 键删数据（anvil/bait/mech_heart…）」为**笔误**，anvil/bait/mech_heart 是**保留条目**，以 TECH_DEBT_ISSUES T-050 登记为准（删的是 3 个 effect 键）。
- **实现方式（数据管线铁律：改 Excel → excel_export.py → 探针；data/*.json 禁手改）**：
  ① **docs/GameData.xlsx items_effects 子表**（长表结构，data_schema.py:165-169：key=item_id、unique_with=key、每键一行）**删除 3 行**：`bait + special_enemies_next_wave` / `anvil + no_weapon_armor_bonus` / `mech_heart + auto_turret_per_wave`；
  ② `python tools/excel_export.py --check-only`（**校验不过禁提交**）→ 全量导出 → data/items.json 更新（3 键消失，条目保留）；
  ③ **desc_builder.gd 3 行中文映射（:20/:44/:50）本轮不删**——死映射永不命中、无害，避免动 .gd 扩大回归面；登记「F5 收口清理或 F1-E 一并处理」；
  ④ **TECH_DEBT_ISSUES.md T-050 条目状态 → 已收口**（3 键删除完成 + F1-G 行整体转 [x]）。
- **风险评估**：**低**——纯数据删除；**CONSUMED_BONUS_KEYS 白名单（player.gd:87-91）实测不含 3 键** → 白名单零改动（F1-G `112e6a9` 已同步过）；唯一注意 = Excel items_effects 删行后 roundtrip 校验（9 表零差异口径）须过，若 excel_export 校验含 effect 键全集断言需确认 3 键不在断言内（实测 data_schema 无此类断言）；`~$GameData.xlsx` 临时锁在盘 → **改 Excel 前先确认无用户打开实例**。
- **验证方式**：① excel_export.py --check-only 零错误 + 导出后 items.json grep 3 键零命中（条目 bait/anvil/mech_heart 仍在）；② 回归 32 项/792 全绿（`python tools/_regression_run.py`）；③ 轻验：day20/day28_f31 中 anvil 服务池/购买断言仍绿 = 条目与 shop_weapon_upgrade 键未受影响；④ TECH_DEBT_ISSUES T-050 状态更新。

### 任务 F1-E 表现配置抽表（T-016~024）【🏠 主窗口承接 · #3 勿自行开工 · 维持】

- 内容/规模/执行约定与第 17 轮一致（7+ 脚本 + 新 Excel presentation sheet + 代码兜底默认值）；#3 轮次标注「F1-E 主窗口承接」即可，不自行开工。

### 已收口登记（无需方案动作）

- **F0** `42871c9` 基线冻结 + 2 P0 bug ｜ **F1.0** `9c1440e` Excel 管线 ｜ **F1-A/B** `438295d` 参数化 ｜ **F1-D** `b6e0177` 商店参数数据化（day30_f1d_shop_check 8/8）｜ **F1-F** `162fa52` 机制 id 收敛（grep 零残留）｜ **F1-G 主键** `112e6a9` 22/22 裁决（接线 5 + 实为已消费 1 + 保留 13 + 删数据 3 = F1-G-尾 承接）。

---

## 2) 风险与观察点（供 #4/#5/#1/主窗口参考）

| # | 观察点 | 归属 | 状态 |
|---|--------|------|------|
| 1 | TEST_REPORT #42 已产出（32/32 · 792 全绿 + elin/attack 单独 = 34 探针 826 全 CLEAN）；**剩余 action item = day29_elin(14)/day29_attack(20) 未入 `_regression_run.py`** | #3/#4 | ⚠️ 请 #3 并入 runner = 34 件套 826 一键跑通（#4 #43 覆盖确认） |
| 2 | **F1-C 护甲口径** | 用户已拍板 | ✅ 08-10 主窗口拍板平直减法 → 阻塞解除 → 本轮待 #3 执行（enemy.gd :761-763 语义锚定） |
| 3 | **F1-G-尾 3 键删数据落 Excel** | #3 | ✅ 本轮方案已定（items_effects 子表删 3 行 → excel_export → 回归）——**#2 第 43 轮新拆首个方案，勿重复拆解** |
| 4 | F1-E 表现抽表大改 | 主窗口 | 🏠 #3 勿自行开工，轮次标注「F1-E 主窗口承接」 |
| 5 | 工作区在途 = docs 5 + tools 3（F1.0 管线余项）+ perfect-pixels + `~$GameData.xlsx` 锁 | #2/#3 | ⏳ 改 Excel 前 `git status` + 确认无 Excel 打开实例；#3 动 data/*.json 前同样确认 |
| 6 | F-35 主观回归面 ② 扩展（F1-G 接线 5 键生效感） | #5 真人 | 🟡 待真人回归 |
| 7 | F2~F5（边界收拢/状态机/拆分/收口） | #2 待拆 | ⏳ F1 全收口（含 F1-G-尾 + F1-C 落地）后按 TECH_DEBT_PLAN §4 拆解，本轮不拆 |

---

## 3) 展望（后续窗口）

- **阶段 F 当前批（#3 下一执行窗口）**：① **F1-C**（enemy.gd :761-763 平直减，player 零改动，回归 32 项）→ ② **F1-G-尾**（Excel items_effects 删 3 行 → excel_export --check-only → 导出 → 回归 32 项 → T-050 收口）——**每任务一收口 commit，提交信息带 T 编号**；③ 顺手并入 day29_elin/day29_attack 入 runner（34 件套 826，#4 #43 可确认）。
- **F1-E**：主窗口承接（#3 轮次标注「F1-E 主窗口承接」合规）。
- **F2 代码边界收拢（T-037~045）**：待 F1 全收口后 #2 拆解 + 方案师定案——本轮不拆。
- **F3 状态机规范化 / F4 拆分 / F5 收口**：范式已定（TECH_DEBT_PLAN §8.5/8.6 + 数值快照零漂移 + CODE_STYLE/DATA_DICT_GUIDE），逐序推进。
- **红线遵守**：不写码 / 不改 .gd/.tscn/.tres/.json / 不 commit / 不跑探针；产出仅 SOLUTION_PLAN.md + TASKS 标注 + 记忆文件。

---

## 阶段 F 技术债整改方案（供 #3 执行岗接手 · 本文件权威版本，单份）

> 总方案/决策记录：docs/TECH_DEBT_PLAN.md（§7 决策表 · §8 状态机选型 · §8.6 能力上限清单）
> 债清单：docs/TECH_DEBT_ISSUES.md（T-001~T-053 逐条状态）
> **数据管线铁律**：改数只改 docs/GameData.xlsx → `python tools/excel_export.py`（校验不过禁止提交）→ 探针；data/*.json 为 generated 禁手改。
> **探针套件**：`python tools/_regression_run.py`（当前 **32 项/792 断言**，改完必跑）；数值基线 `tools/baseline_numerics.json`（F4 拆分后对比防漂移）。

### 已完成（无需再执行）
- F0 基线冻结 + 2 P0 bug 修复（f0-baseline / 42871c9）
- F1.0 Excel 管线全链（f1-excel-pipeline / 9c1440e）
- F1-A enemies.scaling 参数化（T-001/002）、F1-B waves.generation + routes.boss_wave（T-003/014），day30_f1_scaling_check.gd 10 断言（438295d）
- F1-D 商店参数数据化（b6e0177，day30_f1d_shop_check 8/8）、F1-F 机制 id 收敛（162fa52，grep 零残留）、F1-G 主键裁决（112e6a9，22/22）

### 任务 F1-C 护甲公式统一（T-006）【✅ 方案已定 · 用户 08-10 拍板口径：平直减法 · 执行阻塞解除 · 待 #3 执行】
- **现状**：player.gd `take_damage` :466 平直减法 `max(amount - armor, 1.0)`；enemy.gd :762 百分比 `min(armor/(armor+20), 0.75)`（本轮实测确认未漂移）；stats.json.formulas armor_reduction/armor_final 零消费
- **改动（用户拍板「伤害-护甲=最终伤害」，收敛 1 处）**：① enemy.gd :761-763 改 `actual_damage = max(amount - armor, 1.0)` 对齐 player（语义锚定 `min(armor / (armor + 20.0), 0.75)`）；② player.gd 零改动（玩家数值零漂移）；③ stats.formulas armor_reduction/armor_final 死公式标记删（随 F1-G-尾 同轮 T-050 注记）
- **验证**：day30 新探针或扩 day30_f1_scaling_check：enemy armor=0 全伤 / armor=3 → 减 3 / 大 armor 保底 1.0 + player 受击回归锚点（day4/day18_feedback 不变）+ 回归 32 项全绿
- ✅ 执行阻塞已解除（用户 08-10 主窗口拍板，TASKS:2360 已刷新）；风险降级：高 → 低（敌 armor 仅 helmet_alien=3 受影响）

### 任务 F1-G-尾 删数据 3 键落 Excel（T-050 收尾 · #2 第 43 轮拆解）【✅ 方案已定 · 待 #3 执行 · 见 §1 详情】
- **3 键**：`no_weapon_armor_bonus`（anvil :574）/ `special_enemies_next_wave`（bait :351）/ `auto_turret_per_wave`（mech_heart :683）——scripts/ 零机制消费（仅 desc_builder 中文映射 3 处，本轮不删）
- **操作**：GameData.xlsx items_effects 子表删 3 行（item_id+key）→ excel_export.py --check-only（校验不过禁提交）→ 导出 items.json → 回归 32 项全绿 → TECH_DEBT_ISSUES T-050 已收口 → F1-G 行整体转 [x]
- **风险**：低——只删键不删条目（anvil/bait/mech_heart 保留）；CONSUMED_BONUS_KEYS 白名单实测不含 3 键零改动

### 任务 F1-E 表现配置抽表（T-016~024）【大改 · 主窗口优先承接，执行者勿自行开工】
- **内容**：enemy.gd SPRITE_MAP(26 条)/FALLBACK_SPRITES/BEHAVIOR_MAP、audio_manager BGM_MAP/SFX_MAP、vfx_player FX_CONFIG、icon_atlas SHEET_CONFIG、hud SKILL_ICON_MAP、weapon_controller 初始枪、turret 默认值 → **新建 Excel presentation sheet**（data_schema.py 注册新表 → data/presentation.json）+ 各脚本改 DataLoader 读取（**保留代码兜底默认值**，缺字段不崩）
- **规模**：涉及 7+ 脚本 + 新数据表，且与图标/精灵资产耦合 → 由主窗口（用户会话）分步执行并逐脚本验证；执行者看到本任务未在 TASKS 标记 [x] 时**不要自行开工**（避免与主窗口冲突），在轮次里标注「F1-E 主窗口承接」即可

### 任务 F2 代码边界收拢（T-037~045）【待 F1 收口后拆解】
- 概览：GameManager 状态信号化（state_changed）、UI 直读改查询接口、跨层容器访问收口（world.get_container）、实体创建工厂化（world.spawn_*）、wave_manager↔spawner 信号化、GM 面板工厂/事件系统首拆
- 方案：进入 F2 时由 #2 拆解 + 方案师定案（或主窗口承接信号化骨架）

### 任务 F3 状态机规范化（T-031~036）【待 F2 后拆解】
- 范式已定（TECH_DEBT_PLAN §8.5/8.6）：**仅两种形态**——① 扁平流程态 enum+match+`_transition()`；② 行为/表现态 enum+状态表。禁多 bool/字符串状态/int 字面量/散落赋值；单机 >8 态或层级需求 → 触发评审
- 交付含：状态机合规探针（扫描代码）+ 状态流探针（固定序列断言流转）

### 任务 F4/F5【概要】F4 拆分 GM/enemy/player 上帝脚本（<400 行 + 数值快照零漂移）；F5 全量回归 + CODE_STYLE.md + DATA_DICT_GUIDE.md（策划改数手册）

### 执行者交接说明
- 主窗口（用户会话）与 #3 执行岗并行推进：**主窗口承接 F1-E（表现抽表大改）与 F2+ 骨架**；**#3 按本方案执行 F1-C + F1-G-尾**（每任务一个收口 commit，提交信息带 T 编号）
- 冲突规避：动 data/*.json 前先 `git status` 确认无他人未提交改动；改 Excel 前同样检查（Excel 是共享文件，`~$GameData.xlsx` 锁文件在盘时确认无打开实例）
- 每任务完成后在 TASKS.md 阶段 F 区标记 [x] + TECH_DEBT_ISSUES.md 对应条目状态 → 已收口

---

## 执行结果（#3 第 43 轮登记 · 2026-08-10 08:3x · 阶段 F 首执行轮 · 部分完成 · 保留归档）

- **输入核验**：方案第 17 轮正式方案（F1-C/D/E/F/G）；P0 检查 = 增量 #60 无新机器可验证 P0（F0 两修复已落地待真人回归）。
- **F1-D ✅ 收口（`b6e0177`）**：Excel stats_shop sheet（reroll_cost 10 / core_grace_wave 4）→ data_schema.py 注册 stats_shop + excel_export stats.shop 导出 → stats.json 顶层 shop 段 → DataLoader.get_stats_shop() → shop.gd 读参兜底（REROLL_COST 常量改 REROLL_COST_DEFAULT + reroll_cost var）→ day30_f1d_shop_check 8/8 + 入 runner（31→32 项/792 断言）+ 回归 32/32 全绿。
- **F1-F ✅ 收口（`162fa52`）**：HERO_IDS → DataLoader SE 前缀过滤（HERO_ID_FALLBACK 兜底）+ 9 机制 id 常量（4 道具/4 技能/se_turret_array）+ get_skill_ids() + 消费点收敛（shop/main/player/projectile/skill_controller）+ day26 回归锚点同步（31→32/784→792）+ grep 零残留 + 回归 32/32 全绿。
- **F1-G ⚠️ 部分收口（`112e6a9`）**：22/22 键裁决——接线 5 键（xp_gain_percent→gain_exp；melee_damage/ranged_damage→weapon_controller 分类伤害；knockback→弹丸击退累加；boss_elite_damage_percent→projectile 精英/Boss 增伤）+ shop_weapon_upgrade 实为已消费（F31-3 服务池，登记滞后修正）+ 13 键保留待 F2+ + 3 键删数据（no_weapon_armor_bonus/special_enemies_next_wave/auto_turret_per_wave 已 grep 零代码消费）= **F1-G-尾 承接**；CONSUMED_BONUS_KEYS 白名单 + excel_export 注释/总览同步；回归 32/32 全绿。**执行登记**：方案「每键一提交」合并为同域分组提交（5 键同属武器/经验增益域，回归全绿兜底）；🕳️ 踩坑 self-fix：`weapon.get("weapon_type", "")` 双参 → Object.get 编译期 Parse Error 致 weapon_controller.gd 加载失败（记忆坑复现）→ 改单参+判空。
- **F1-C ⛔ 曾执行阻塞（历史登记）→ ✅ 已解除（用户 08-10 主窗口拍板，见 §1）**：armor 数据实测（道具 -3~+4 / 角色 passive 零 / stats base 0 max 20「减免物理伤害, 上限75%减伤」）——平直制↔百分比制换算口径待用户确认 → 按方案兜底标记阻塞不强行改；用户 08-10 已拍板「伤害-护甲=最终伤害」平直减法 → **阻塞解除，F1-C 待本轮方案后执行**。
- **F1-E 🏠 主窗口承接**（未开工，标注不执行）。
- **观察点**：#4 #42 已按 runner 现 **32 项/792 断言**口径正式纳入（day30_p0_fix 15 + day30_f1_scaling 10 + day30_f1d_shop 8），快照覆盖至 `112e6a9` 后 = TEST_REPORT #42（HEAD=`640ce5f`）已兑现 ✅。
- 收尾：git add -A 全部提交推送（3 个 F1 收口 commit + 挂账 docs）。
