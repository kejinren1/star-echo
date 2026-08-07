# 方案计划（2026-08-08 · 第 8 轮）

## 当前开发日：Day 27（局外养成 · 阶段 E 首段：方舟基地 + 研究系统 + 角色培养 + 剧情解锁接线）

### 0) P0 调度硬性输入检查（读 PLAYTEST_CHECKLIST 追踪区头部 · 本轮实测 03:50）

- ✅ **增量 #42（03:5x · #5 标记岗）**：TEST_REPORT #31（02:16）= Day 24 正式覆盖（二十三件套 609 断言）；**Day 26 阶段 D 整合校验收口**（git HEAD=`6b7c942`，day26_integration_check 34/34 六段 + 回归 23/23 609 断言 + REPORT_PHASE_D.md 7266B 落盘 + 阶段 D 全五日机器闭环）→ **目标日推进 Day 27（局外养成）**。
- ✅ **增量 #41/#40（01:5x/01:4x）**：🔴P0 无 / 🟠 无新增用户拍板 / 🟡 仅 H-05 家族主观审阅域（交 #5）→ **无新机器可验证 P0 需纳入本轮**。
- 📋 **顺延项 6 条（#42 登记）**：F-11 接口偏差（语义等价非缺陷）/ vfx_container / 遗物 HUD 槽 P1 / 空间音 P1 / mech_heart 入池 P1 / **剧情解锁接线归 Day 27**——最后一项即本轮 D27-T5 承接，其余与局外养成无关，不纳入。
- 🚨 **美术资源策略（2026-08-07 21:1x 拍板 · 硬性）**：不再生成美术资源；基地 UI 用占位/复用现有主题（W3 ◐ P1 可延不阻塞）；纯色占位豁免色号编码。
- **P0 检查结论：无新机器可验证 P0 需纳入本轮方案**；剧情解锁接线为 D25/D26 登记的 Day 27 依赖，已并入 D27-T5。

### 目标日客观状态（本轮实测 03:50）

- git HEAD = `6b7c942`（#3 第 33 轮 Day 26 收口）；工作区在途 = docs 侧（#5/#1 同窗口产物，零游戏代码）。
- **D27 区任务状态**：PRE 9 条定案 + T1~T6 + EXIT 全 [ ]，函数级预拆就绪（#2 第 23 轮 09:1x），**#3 下一窗口 05:35 可直接执行，无需重拆**。
- **实测基线复核（与 #2 第 23 轮一致）**：scripts/ 全域零 `user://`（存档零实现）✅ / scenes/ 零 base/ark/hub 场景 ✅ / characters.json 10 英雄零 story/level/xp 字段 ✅ / `docs/LORE.md` 14075B 在盘 ✅ / `docs/REPORT_PHASE_D.md` 7266B 在盘 ✅。
- **回归基准**：Day 26 收口 = 23 探针 609 断言（#42 实测；day26_integration 34 断言待 #4 #32 正式纳入 → 二十四件套 643）→ Day 27 落地后 = **25 件套 ≥659 断言**（+day27 ≥16）。

### 本轮实测锚点（供 #3 免排查 · 2026-08-08 03:50 磁盘实测）

| 项 | 现行位置 | 说明 |
|---|---|---|
| game_manager.gd `game_over` 信号 | `scripts/autoload/game_manager.gd` :12 | victory: bool |
| game_manager.gd `current_character_id` | :43 | 跨局唯一候选（Main._ready 写入） |
| game_manager.gd `_ready` | :85-87 | 仅 `_event_rng.randomize()` → **load_meta() 插首行** |
| game_manager.gd `start_game` | :90-111 | 出场记录注入点 = 函数开头（route/旧制分支之前） |
| game_manager.gd `register_boss_killed` | :290 | **保持登记不改**（深消费 = end_game victory 统一，不删） |
| game_manager.gd `end_game` | :559-565 | 结算注入点 = :563 前（victory 分支，game_over.emit :565 之前完成） |
| game_manager.gd `reset` | :568-588 | **勿重置 meta_progress**（局外数据跨局） |
| main.gd `_setup_character` | `scripts/autoload/main.gd` :106-122 | `apply_character` :117 → `_setup_skill` :120 → `_equip_starting_weapon` :122 |
| player.gd `apply_character` | `scripts/player/player.gd` :117-131 | **:122 `bonus_stats.clear()`——永久增益注入必须在其后** |
| player.gd `apply_stat_modifier` | :507-545 | **damage→damage_multiplier 乘算 :519-520 / max_health 乘算 :509-514 / luck 加算 :535-536**——三项全覆盖 |
| player.gd STAT_MAP | :56-68 | luck = add 模式；damage/max_health 均在映射内 |
| character_select.gd | `scripts/character_select.gd`（**非 scripts/ui/**） | `HERO_IDS` :15 仅 4 SE 英雄；`_ready` :48-49 调 `_build_cards`；节点结构 `$Root/CardRow` + `$Root/DetailLabel`——入口按钮动态创建加 `$Root/` |
| characters.json | `data/characters.json` | 10 英雄：6 基础（well_rounded/brawler/ranger/mage/engineer/gambler 无 skill）+ 4 SE（se_irene/se_noa/se_ren/se_siia 有 skill/growth/star_echo）——**只增 story/story_unlock_level** |
| LORE.md / REPORT_PHASE_D.md | `docs/` | 14075B / 7266B 均在盘 ✅ |

### 新增设计决策（本轮方案师定案；D1-D41 为历史各轮决策，已收口）

| # | 决策 | 依据 |
|---|---|---|
| **D42（增益注入方式修正）** | **永久增益 ≠ 注入 bonus_stats 兜底字典**（拆解 T3 原文有歧义）——实测 `apply_character` :122 会 `bonus_stats.clear()` 且 bonus_stats 无攻击/生命消费方（仅技能/面板读）；**改为 main.gd 进局直调 `player.apply_stat_modifier`**：`damage`（乘算 ×(1+0.05×attack)）/ `max_health`（乘算 ×(1+0.10×hp)）/ `luck`（加算 +0.05×luck）——三项支持面已实证 :507-545 | 本轮实测 player.gd；拆解 T3「luck 键口径先核 STAT_MAP/apply_stat_modifier 支持面，不支持则走 bonus_stats」→ 支持面全覆盖，走直调更可靠 |
| **D43（注入点）** | `main.gd _setup_character` 内 `player.apply_character(data)`（:117）**之后**、`_setup_skill`（:120）**之前**插入 `_apply_meta_bonus(player)`——此时 `health == max_health`（:129 满血），max_health 乘算后 `health=min(health,max_health)` 无半血截断；research 全 0 → 零调用零回归 | apply_character :122 clear 时序；:129 满血态 |
| **D44（存档隔离）** | GameManager 存档路径 = **可覆写 var** `var meta_save_path: String = "user://save_meta.json"`（非 const）——探针覆写为独立档 `user://test_meta_<seed>.json` + 测试后删除，**防污染真实存档**（拆解 T6「独立临时档名」的实现载体） | 拆解 T6 §1 要求；GameManager 为全局 Autoload 单例，无注入点即无隔离 |
| **D45（探针判空）** | `start_game` 出场记录**必须判空**：`if current_character_id != ""` 才 `add_char_xp`——探针白盒直调 start_game 时 current_character_id 为空（未走 main._setup_character），不判空会写 `chars[""]` | 探针范式（白盒直构造）先例；end_game 结算同理读 `current_character_id` 前判空 |
| **D46（基地角色区口径）** | 基地角色区展示 **DataLoader 全量 10 英雄**（非 character_select 的 4 SE 常量）——6 基础英雄 LORE.md 无对应条目 → story 用既有 description 扩写一句并标注来源（拆解 T2 兜底已含）；解锁判定统一走 `GameManager.get_char_level(id)` | character_select.gd HERO_IDS :15 仅 4 SE（本轮实测）；局外档案 = 跨角色全量 |
| **D47（剧情解锁判定纯函数化）** | 解锁判定**不实例化 BaseStation 场景**：逻辑收敛为 `GameManager.get_char_level(id) >= story_unlock_level` 比较（+ base_station.gd 按钮 enable 消费同一判定）——day27 探针 §4 白盒直调 GameManager 接口断言，headless 零场景依赖 | headless 场景实例化脆弱性（tscn 手写风险）；拆解 T6 §4 测试点本身即纯逻辑 |
| **D48（执行序 + commit 护栏）** | **T2（数据先行）→ T1（存档核心）→ T3（增益注入）→ T4（基地场景）→ T5（剧情解锁，依赖 T2/T1）→ T6（探针）→ EXIT**——T1 是 T3/T5 的公共依赖；可分批 commit（数据/存档 → 场景/解锁 → 探针/收口）任一批次完成即提交（D18-19 分批先例）；**EXIT 勿夹带** docs/pindou/、scripts/ui/*.bak、tools/pixel_to_pindou.py、docs/LOOP_HEALTH.md（D41 沿用）；**user:// 存档为运行时文件不入库** | TASKS D27-EXIT 护栏；分批 commit 惯例 |
| **D49（回归口径修正）** | D27-EXIT 回归清单「day25 N / day26 N」占位**修正**：day25 无独立探针（剧情预交付）**不纳入**；day26 = `day26_integration_check` **34 断言**（#42 实测 34/34）纳入 → 基准 = **24 件套 643 断言**（#4 #32 正式纳入后），D27 落地 = **25 件套 ≥659**（+day27 ≥16） | #42 实测：回归 23/23 609 + day26 34 待纳入；TASKS :2215 占位修正 |

### 任务1：D27-T2【W2】characters.json 补角色培养数据（10 英雄）——数据先行

- 文件：`data/characters.json`（10 英雄，只增字段）
- 改动：
  - 每英雄补 `story: String`（1-2 句小传——**从 docs/LORE.md 对应角色条目提炼，不新写剧情**；LORE.md 无对应条目（6 基础英雄大概率无）→ 用既有 `description` 扩写一句，注释标注来源「LORE.md 无条目，description 扩写」）
  - 每英雄补 `story_unlock_level: int`（默认 1；SE 四英雄 se_irene/se_noa/se_ren/se_siia 可设 2——拆解定案，防臆造简单化）
  - `unlock_condition` **保持不动**（本日不做选人卡点，解锁 = 剧情查看门槛）
- 风险：**低**——只增字段；day2 探针 32 断言为消费链路非全键比对（#2 第 23 轮核），预计零波及；实施后跑 day2 确认，若红按「只增字段」原则修探针锚点（改探针不改数据语义）
- 验证：`day2_hero_check` 回归全绿 + day27 探针 §4 读 story/story_unlock_level

### 任务2：D27-T1【W1】GameManager 局外存档系统（核心）

- 文件：`scripts/autoload/game_manager.gd`（_ready :85 / start_game :90 / end_game :559）
- 改动：
  1. 新状态：`var meta_progress: Dictionary = {}`（`{"wins": int, "research_points": int, "research": {"attack": int, "hp": int, "luck": int}, "chars": {id: {"xp": int}}}`）+ **`var meta_save_path: String = "user://save_meta.json"`（D44，探针可覆写）**
  2. `load_meta()`：`_ready()` 首行（:87 前）调用；`FileAccess.open(meta_save_path, READ)` → 缺文件/解析失败/非 Dictionary → 默认零值 + push_warning 容错不崩；成功 → 逐键 `get()` 兜底（防旧档缺键）
  3. `save_meta()`：WRITE + `store_string(JSON.stringify(meta_progress, "  "))`
  4. 结算钩子：`start_game()` :90 开头（route/旧制分支之前）`if current_character_id != "": add_char_xp(current_character_id)`（D45 判空）；`end_game()` :559 victory==true 分支（:563 暂停前）→ `wins+1` + `research_points+1` + 当前角色 `xp+1` + `save_meta()`；**失败局不结算**（出场已在 start_game 记）
  5. 接口：`get_meta_bonus() -> Dictionary`（`{attack_mult, hp_mult, luck_add}` 按 research 档位换算，全 0 → 返回空字典）/ `add_research_point()` / `add_char_xp(id)` / `get_char_xp(id) -> int` / `get_char_level(id) -> int`（`xp/3` 向下取整）
- 风险：**中**——结算钩子位置（必须在 game_over.emit :565 前完成，防信号消费方读脏状态）；探针环境判空（D45）；`reset()` :568 **不得重置 meta_progress**（局外跨局数据）
- 验证：day27 探针 §1（读写一致 + 损坏容错）/ §3（XP 结算）

### 任务3：D27-T3【W1】永久增益装配链

- 文件：`scripts/autoload/main.gd`（_setup_character :106-122）
- 改动：`player.apply_character(data)`（:117）之后、`_setup_skill`（:120）之前插入 `_apply_meta_bonus(player)`：
  - `var bonus := GameManager.get_meta_bonus()` → 空字典直接 return（research 全 0 零注入零回归，D42）
  - `attack_mult > 1.0` → `player.apply_stat_modifier("damage", attack_mult, true)`（damage_multiplier 乘算 :519-520）
  - `hp_mult > 1.0` → `player.apply_stat_modifier("max_health", hp_mult, true)`（:509-514，health=min 满血态无截断 D43）
  - `luck_add > 0` → `player.apply_stat_modifier("luck", luck_add, false)`（:535-536 加算）
- 风险：**中**——注入点必须在 apply_character 后（:122 clear bonus_stats；D42 直调 apply_stat_modifier 不经 bonus_stats 故无清空险）；player 为 null 判空（探针/异常场景）
- 验证：day27 探针 §2（白盒设 meta_progress research=1/1/1 → 构造 player 白盒跑注入 → 断言 damage_multiplier==1.05 / max_health×1.10 / luck==+0.05）

### 任务4：D27-T4【W1 主责 + W3 ◐】方舟基地场景

- 文件：`scenes/BaseStation.tscn`（新建）+ `scripts/ui/base_station.gd`（新建）+ `scripts/character_select.gd`（入口）
- 改动：
  - **BaseStation.tscn**：仿 LevelUpPanel 弹窗/面板先例手写——顶部标题「方舟基地」+ 研究区（3 项：攻击强化/生命强化/幸运强化，每项「已升级/未升级」+ 研究点余量 + 升级按钮）+ 角色区（ScrollContainer 内 10 英雄卡片：名/等级/XP 进度/剧情按钮）+ 返回按钮；复用现有 NinePatchRect/主题色（W3 ◐ P1 可延不阻塞，占位口径）
  - **base_station.gd**：研究升级按钮 `research_points>0 且 research[key]==0` 才可点 → `GameManager` 消耗 1 点 + 置位 + `save_meta()`；角色卡 `get_char_level(id) >= story_unlock_level` → 剧情按钮启用（D47 纯函数判定），点击弹 story 文本（LevelUpPanel 范式）；返回 → `change_scene_to_file("res://scenes/CharacterSelect.tscn")`
  - **character_select.gd**：`_ready`（:48-49）动态创建「方舟基地」Button 加 `$Root/`（仿 _create_card 动态建节点先例，**不改 tscn**）→ pressed → `change_scene_to_file("res://scenes/BaseStation.tscn")`
- 风险：**中**——tscn 手写（节点路径/锚点错误 → headless 场景实例化校验兜底；探针 §4 不实例化场景已规避 D47）；CharacterSelect.tscn 场景名实现时确认（`res://scenes/CharacterSelect.tscn`，与 MAIN_SCENE_PATH 同目录惯例）
- 验证：headless 场景实例化零报错 + 真机/人工（基地 UI 观感 = #5 主观项不阻塞）

### 任务5：D27-T5【W1】剧情解锁接线（承接 D25/D26 + boss_defeated 消费）

- 文件：`scripts/ui/base_station.gd`（判定已纯函数化于 GameManager，D47）
- 改动：
  - 角色卡片剧情按钮：`GameManager.get_char_level(id) >= story_unlock_level` → 可点 → 弹 `story`；不足 → 禁用 + 「Lv.N 解锁」提示
  - **boss_defeated 深消费**：`end_game(victory)` 统一结算（T1 已含）——`register_boss_killed` :290 保持登记**不改**（局外只认胜利结局；TASKS D27-T5 写死线确认块说明）
  - `unlock_node`（game_manager.gd :433-478）**零改动**（事件改线策略保持，勿与剧情解锁混淆）
- 风险：**低**——纯 UI 消费 + 既有接口；唯一注意 = 勿误改 unlock_node
- 验证：day27 探针 §4（xp=6→lv2≥2 解锁 / xp=2→lv0 锁定，白盒 GameManager 接口断言）

### 任务6：D27-T6【W1】新建 `tools/day27_meta_check.gd`（≥16 断言五段）

- 文件：`tools/day27_meta_check.gd`（新建）
- 改动（范式沿用：`extends SceneTree` + `_advance` 分派全部 sub + 白盒直构造 + 固定 seed；**D44 覆写 meta_save_path 独立档 + 测试后删除防污染真实存档**）：
  - **§1 存档读写**：白盒构造 meta_progress → save_meta → 重载 load_meta 断言一致；损坏 JSON 字符串写入 → load_meta 默认零值不崩
  - **§2 研究升级与增益**：白盒 research_points=1 → 升级 attack → get_meta_bonus 断言 attack_mult==1.05 / hp_mult==1.10 / luck_add==0.05（D42 换算口径）；点数不足拒绝升级
  - **§3 角色 XP 结算**：白盒 start_game（判空 D45）→ end_game(victory) → chars[id].xp 累计 + wins/research_points+1；失败局（victory=false）不结算；等级换算 xp/3
  - **§4 剧情解锁门槛**：story_unlock_level 阈值 → `get_char_level(xp=6)==2 >= 2` 解锁 / `xp=2 → 0 < 1` 锁定（GameManager 纯函数断言，不实例化场景 D47）
  - **§5 回归抽样**：day2/day3 锚点 + baseline（characters.json 只增字段零波及验证）
- 风险：**中**——探针自身缺陷不阻塞 EXIT（沿用 D37 口径）；存档隔离（D44）；GameManager Autoload 单例状态污染（探针末段重置 meta_progress 防影响后续探针）
- 验证：`Godot --headless -s tools/day27_meta_check.gd` ≥16 断言全绿

### 任务7：D27-EXIT【W5】阶段 E 首段收口

- 文件：docs（PLAYTEST 追加）+ git commit
- 改动：
  1. `python tools/baseline_check.py` → `BASELINE CLEAN`
  2. `day27_meta_check` CLEAN（五段）+ **回归 25 件套 ≥659 断言**（D49 口径：24 件套 643 = 23 探针 609 + day26_integration 34，+day27 ≥16）
  3. `docs/PLAYTEST_CHECKLIST.md` 追加主观项：**基地 UI 观感 / 研究成长体感 / 剧情解锁趣味**（#5 收口不阻塞出口）
  4. git commit 收口（D48 护栏：勿夹带 4 项 + user:// 不入库 + 勿 push -u）
- 风险：**中**——回归全套任一红则阻塞（误红先复核探针锚点勿改游戏逻辑，D39 语义断言沿用）；TASKS 并发写入（#2/#5 同窗口）标注前重读
- 验证：EXIT 全 [x] + git log 收口提交 + 目标日推进 **Day 28（全量测试 + 性能，#4 域无需拆解）**

### 风险总表（本轮）

| 风险 | 等级 | 说明与缓解 |
|---|---|---|
| apply_character 清 bonus_stats | 中 | D42 直调 apply_stat_modifier（不经 bonus_stats）；注入点在 apply_character 之后（D43） |
| 探针环境 current_character_id 空 | 中 | D45 判空守卫（start_game 出场 / end_game 结算两处） |
| user:// 存档污染真实档 | 低 | D44 可覆写 meta_save_path + 探针独立档 + 测试后删除 |
| characters.json 只增字段波及 day2 | 低 | 实施后跑 day2 确认；红则修探针锚点不改数据语义 |
| BaseStation.tscn 手写节点错误 | 中 | 仿 LevelUpPanel 先例 + headless 场景实例化校验；探针 §4 纯函数不实例化（D47） |
| TASKS 并发写入（#2/#5 同窗口） | 低 | 核验以 git HEAD 已提交版本为准；标注前重读文件 |
| git 写 refs 间歇失败（Program Files） | 低 | 正常 commit 即可，勿 push -u（历史先例） |

---

## 执行结果：✅ 完成（2026-08-08 05:5x · #3 执行者第 34 轮）

- **T2→T1→T3→T4→T5→T6→EXIT 全量执行（D48 执行序，分批 commit×4）**：`97b2a53`（T2 数据）/ `e7057b8`（T1 存档 + T3 增益）/ `dbc2207`（T4 基地 + T5 解锁）/ `758c7bb`（T6 探针）+ 收口提交（docs + day26 锚点同步）。
- **机器护栏全绿**：day27_meta_check **35/35 CLEAN 五段**（≥16 目标达成）；回归 **25/25 全绿 678 断言**（≥659 基准，D49 口径 609+34+35）；baseline **BASELINE CLEAN**；headless 场景实例化零报错（BaseStation 3 研究行 + 10 角色卡 + 入口按钮实机校验）。
- **执行登记 2 处**：① 探针驱动范式——`extends SceneTree` 探针须 `_process` 驱动带参 `_advance(sub)`（无参 `_advance()` 非虚方法会空转）+ Autoload 首帧 `get_node_or_null` 获取（`_init` 时机过早）；② day26_integration §6 回归锚点 23/609 → 25/678（回归脚本扩容触发，改探针锚点不改游戏逻辑，D39 语义断言）。
- **主观项移交**：基地 UI 观感 / 研究成长体感 / 剧情解锁趣味 → PLAYTEST #5（不阻塞出口）。
- 下一目标日：**Day 28（全量自动化测试 + 性能，#4 域，无需方案）**。
