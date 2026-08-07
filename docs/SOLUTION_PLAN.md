# 方案计划（2026-08-07 · 第 3 轮 · 17:5x）

## 当前开发日：Day 20 —— 遗物系统 + 阶段 C 收口 + T-D 技能图标（P0 调度硬性输入）

> 执行者（#3）按本方案实现；本方案只定案，不写代码。

---

## §0 P0 调度硬性输入（本轮检查结论）

- **追踪区增量 #32（17:5x）**：D18-19 Boss 多阶段**全收口**（HEAD `2d8bdd2`，实现提交 `d3b95a0`/`afe5ef7`/`740cb9e` + T-C `c470761`；十六件套 429 断言全绿首跑；day18_19_boss_check 48/48 首纳入）→ 阶段 C 前四节（路线/事件/精英/Boss）机器全闭环 → **目标日 = Day 20（遗物）**，#3 下一窗口 19:35 可直接执行。
- P0 四件套（F-01/F-02/F-04/F-15）+ P1 四修复 + T-C 炮台提示 = **全部闭环**，**无新增机器可验证 P0 需拆**。剩余动作 = 真人「超级整合局」（主观项交 #5，不阻塞）。
- **🔴 T-D 技能图标（用户 08-06 拍板「两个工作日内」）**：08-08 = 时限最后一天，已排入本日 D20-T7/T8。**若本日（08-07）未能启动，D20-T7/T8 最迟 08-08 必须落地，勿顺延**——这是硬性时限，优先级高于普通任务。

## §1 实测核验（D18-19 收口后重测，替代预拆旧行号）

| 位置 | 预拆行号 | 实测行号 | 状态 |
|---|---|---|---|
| player.gd STAT_MAP | :53-69 | :53 | ✅ 一致 |
| player.gd take_damage | :281-300 | :281（actual_damage :290 / debug_cheat :292-293） | ✅ 一致 |
| inventory.gd MAX_ITEMS | — | :21 | ✅ |
| inventory.gd add_item_from_data | :75-92 | :75（末尾走 add_item :57-63） | ✅ 一致 |
| shop.gd _build_shop_pool | :91-110 | :91（武器循环 :94 / 被动循环 :102 / return :109） | ✅ 一致 |
| icon_atlas.gd items frame_count | :16 | :16（=20） | ✅ 一致 |
| turret.gd 伤害链 | :89-94 | **:108-109** | ⚠️ 漂移（T-C `c470761` 进度条致后移，改前读 :100-120） |
| hud.gd skill_slot | :16-17 | **:18** | ⚠️ 漂移 1-2 行 |
| skill_controller.gd skill_data | — | :22 声明 / :49 setup 装载 / :72 `get("id","")` | ✅ T8 消费路径可行 |
| items.json | 49 项 | 49 项 / 零 slot=="relic" / is_passive 20 / broken_crown 不存在 / mech_heart 悬空（price 105 不入任何池） | ✅ 一致 |

**🔴 回归同步点补齐（预拆遗漏 2 处，漏改必红）：**
1. `day13_build_check.gd` :200 `pool.size() != 53` → **55**（预拆已列）
2. `day11_12_passive_check.gd` :351 `pool.size() != 53`（33+20 拆分断言）→ **55**；:366 武器 33 / :370 被动 20 **零改动**（预拆遗漏 :351）
3. `day11_12_passive_check.gd` :476-482 `frame_count == 20` → **22**（预拆已列）
4. `day16_event_check.gd` :414 `_ok(pool.size() == 53)` → **55**；:426 passives == 20 **零改动**（**预拆遗漏，新增**）

---

### 任务1：D20-T1【W2】items.json +2 遗物条目（数据）
- 文件：`data/items.json`（追加 2 项，总 49→51）
- 改动：
  - `broken_crown` 破碎王冠：`{id, name, rarity:"legendary", price:120, effects:{damage_percent:50, damage_taken_percent:30}, tags:["relic","damage"], slot:"relic", icon_index:20}`
  - `mech_engine` 机械引擎：`{id, name, rarity:"legendary", price:120, effects:{structure_damage_percent:100}, tags:["relic","engineering"], slot:"relic", icon_index:21}`
  - **不设 is_passive**（不入被动池，day11_12 20 被动断言零波及）；effects 3 键 ⊂ 白名单（damage_percent 已有 / damage_taken_percent + structure_damage_percent 为 D20-T2 新注册）
- 风险：**低**（纯数据追加；3 核心 effects 豁免先例，新键注册后白名单校验自动通过；无 slot 既有项零波及）
- 验证：JSON 可解析 + 51 项 + 2 项 slot=="relic" + icon_index 20/21 唯一 + price>0（day20 探针 §1）

### 任务2：D20-T2【W1】player.gd 新装配键（damage_taken_mult / structure_damage_mult）
- 文件：`scripts/player/player.gd` STAT_MAP :53-69 / take_damage :290-293
- 改动：
  1. STAT_MAP 注册 2 键：`"damage_taken_percent": {"stat": "damage_taken_mult", "mode": "percent"}` + `"structure_damage_percent": {"stat": "structure_damage_mult", "mode": "percent"}`
  2. 新属性 `var damage_taken_mult: float = 1.0` / `var structure_damage_mult: float = 1.0`（`reset()` 复位 1.0）
  3. take_damage **:290 与 :292 之间**插入 `actual_damage *= damage_taken_mult`（armor 平直减伤**先减后乘**；debug_cheat ×0.001 保持 :293 最后兜底，金手指语义不变）
- 风险：**中**（插入点必须严格在 :290 后 / :292 前，防金手指兜底顺序变化；装配链路 percent 乘算已由 apply_item_bonuses :133-159 规则覆盖，**零新装配代码**，不得手写装配逻辑防双装配）
- 验证：day20 探针 §2/§3 —— broken_crown 装配 → damage ×1.5 + damage_taken_mult == 1.3；take_damage(100) armor=0 → 扣 130；armor=20 → 扣 104（`max(80,1)×1.3`）；debug_cheat 开 → 仍 ×0.001 最后

### 任务3：D20-T3【W1】inventory 遗物上限（MAX_RELICS=2 直装不占被动槽）
- 文件：`scripts/systems/inventory.gd` :21 附近 / add_item_from_data :75-92
- 改动：
  1. `const MAX_RELICS: int = 2` + `func get_relic_count() -> int`（遍历 items 统计 `slot == "relic"`）
  2. `add_item_from_data` :78 取得 data 后判 `var is_relic := str(data.get("slot","")) == "relic"`：
     - **relic 分支（关键）**：`get_relic_count() >= MAX_RELICS → inventory_full.emit("relic") + return false`；否则构造 Item 资源（复用 :82-91 装载代码）→ `items.append(item)` + `item_added.emit(item)` + `return true` —— **必须跳过 `add_item` 的 MAX_ITEMS 检查（:58）**，否则 6 被动满时 items.size()=6 ≥ 6 → 遗物被误拒（**违反「6 被动 + 2 遗物共存」定案**）
     - 非 relic → 走原路径 `add_item(item)`（:92 不变，MAX_ITEMS 语义零波及）
- 风险：**中**（⚠️ `add_item` :58 是全量 items 数组检查，relic 分支若不短路则遗物永远进不了满槽被动玩家的背包——**预拆「其余走原路径」措辞有歧义，本方案定案 = relic 直装路径**；`add_item` 本身零改动防其他消费方波及）
- 验证：day20 探针 §4 —— 白盒 add broken_crown ×2 → 成功 2 + 计数 2；第 3 次 → false + inventory_full("relic")；6 被动满 + 2 遗物共存 → 被动再 add 仍拒（MAX_ITEMS 语义不变）

### 任务4：D20-T4【W1】商店第三池（遗物）
- 文件：`scripts/ui/shop.gd` _build_shop_pool :91-109（第三循环追加在 :108 后）+ `tools/day13_build_check.gd` :200 + `tools/day11_12_passive_check.gd` :351 + `tools/day16_event_check.gd` :414
- 改动：
  1. :108 后追加第三循环：`idata.get("slot") == "relic" and int(idata.get("price",0)) > 0` → `_build_item_resource(iid)` 入池；:88-90 注释「口径不变 = 53」同步改 55
  2. **回归同步 3 处**（§1 表）：day13 :200 / day11_12 :351 / day16_event :414 → 55；day11_12 :366/:370 与 day16 :426 零改动
- 风险：**低**（D13-T6 资源实例范式复用；resonant_shard price 0 天然排除 = 事件专属保持；4 卡含遗物 ≈3.6% 不保底防过度设计；同步点已在 §1 列出防漏）
- 验证：白盒 `_build_shop_pool().size() == 55` + 全资源实例 + 含 broken_crown/mech_engine + 零 String（day20 探针 §4 + 三探针回归全绿）

### 任务5：D20-T5【W3+W1】遗物图标 2 帧 + 图集扩容
- 文件：`tools/gen_item_icons.py`（+2 实绘函数）/ `assets/sprites/ui/items.png` 640×32→704×32 / `scripts/utils/icon_atlas.gd` :16 frame_count 20→22 / `tools/day11_12_passive_check.gd` :476-482
- 改动：broken_crown 金色王冠（icon 20）/ mech_engine 银蓝齿轮（icon 21）；PIL 像素原语 + bounds check（描边越界 IndexError 坑）；透明键协议（左上角(0,0)=背景色全图镂空，禁用于关键位置）
- 风险：**低**（PIL 原语先例成熟；⚠️ 生成后放大 4 倍目视整体效果再 commit——图标生成先例铁律）
- 验证：items.png 704×32 + 帧 20/21 中心非空 + 透明键合规；icon_atlas get_frame_count("items")==22（day20 探针 §5 回归锚点 + day11_12 :480 同步 22 后全绿）

### 任务6：D20-T6【W1】新建 `tools/day20_relic_check.gd`（≥18 断言五段）
- 文件：`tools/day20_relic_check.gd`（新建）
- 改动（探针范式沿用：`extends SceneTree` + `_advance` 分派全部 sub + 固定 seed + **白盒直构造**——D11-12/13 flaky 修复记录）：
  - §1 数据层：51 项；2 遗物 slot=="relic" + icon_index 20/21 唯一 + price>0 + effects 键 ∈ {damage_percent, damage_taken_percent, structure_damage_percent}；resonant_shard 保持无 slot；is_passive 仍 20 项
  - §2 新键装配（白盒直构造 + apply_item_bonuses，**禁手动双装配**——信号环境 item_added→apply_item_bonuses 已接）：broken_crown → damage ×1.5 + taken_mult 1.3；mech_engine → structure_mult 2.0；remove 回退 → 全复位
  - §3 take_damage 乘算：armor=0 扣 130；armor=20 扣 104；debug_cheat 开 → 仍 ×0.001 最后兜底
  - §4 商店/上限：池 55（33+20+2）+ 含 2 遗物 + 零 String；add broken_crown ×2 成功 → 第 3 次拒（inventory_full("relic")）；6 被动 + 2 遗物共存
  - §5 结构伤害消费 + 回归锚点：白盒 turret 弹药伤害 ×structure_damage_mult（se_mech_core 装配 → structure_mult == 1.4 顺带激活悬空词条）；day11_12 frame_count 22 / day13 池 55 / icon_index 0-19 唯一仍成立
- 风险：**中**（探针自身坑：Array.shuffle/pick_random 走全局 RNG → 白盒直构造或全局 seed(N)，勿用 rng.seed 控 shuffle；信号环境防双装配）
- 验证：探针自证 CLEAN + 回归十五件套全绿

### 任务7：D20-T7【W3 主责 + W1 协作】技能图标 4 枚 + skills.png 图集（T-D · P0 调度硬性输入）
- 文件：`tools/gen_skill_icons.py`（新建，仿 gen_weapon_icons.py PIL 原语）/ `assets/sprites/skills/skills.png`（**新建目录**，128×32 = 4 帧，32px 图标基准同 weapons.png）
- 改动：4 实绘函数 —— `se_skill_fireball`（炽星火球：橙红火球+焰尾，帧 0）/ `se_skill_deploy_turret`（机械矩阵：炮塔+齿轮，帧 1）/ `se_skill_blade_burst`（剑域绽放：剑刃圆环+光点，帧 2）/ `se_skill_holy_shield`（神圣庇护：白蓝护盾+十字光，帧 3）；透明键协议 + 216 色上限 + 锚点色板容差归并（ΔRGB≤12）；`.import` 由 `godot --headless --import` 补（D21-T0 先例）
- 风险：**低**（新目录零冲突；W1 本任务零改动）
- 验证：skills.png 128×32 + 4 帧中心非空 + 透明键合规 + 色数合规（静态脚本/探针）

### 任务8：D20-T8【W1】SkillSlot 图标接线 + 美化（T-D · 无图零回归）
- 文件：`scripts/ui/hud.gd` :18 skill_slot / 新增 `_apply_skill_icon()`
- 改动：从 `GameManager.player.get_node_or_null("SkillController").skill_data.get("id","")` 取技能 id（skill_controller.gd :22/:72 结构已核验）→ `ResourceLoader.exists("res://assets/sprites/skills/skills.png")` 兜底 → `IconAtlas.get_frame("skills", idx)` → `skill_slot.texture = frame`；映射 `{se_skill_fireball:0, se_skill_deploy_turret:1, se_skill_blade_burst:2, se_skill_holy_shield:3}`；id 空/图缺失/节点缺失 → 静默跳过（保持现有样式零回归）；未知 id → push_warning 登记不崩；`_ready` **延迟一帧调用**（HUD _ready 先于 Main _ready 先例，P1-Fix3）
- 风险：**低**（无图降级设计；IconAtlas 对未知 sheet 有 push_warning 不崩，但前置 ResourceLoader.exists 更稳）
- 验证：白盒注入 skill_data（4 个 id 各测）→ skill_slot.texture 非空且帧索引正确；空 id → 零改动；skills.png 缺失 → 不崩

### 任务9：D20-EXIT【W5】阶段 C 收口
- 文件：`docs/REPORT_PHASE_C.md`（新建）+ git commit
- 改动：baseline CLEAN + day20 探针 + **回归十六件套**（day2 32 / day3 16 / day4 21 / day5 16 / day6 14 / day7 13 / day8 19 / day10 20 / day11_12 22 / day13 36 / day14_15 53 / day16 41 / day17 39 / day17_p0 20 / day18_19 48 / day20 N）+ `gen_weapons_day7.py verify` 36/36 + REPORT_PHASE_C.md（§1 阶段 C 七日回顾 / §2 各系统集成结论 / §3 平衡对照：F-01 移速×0.5 后曲线 + 遗物叠加边界 damage_percent 乘算链 / §4 遗留：R4 攻击力口径、森林区域深消费 Day 27、遗物 HUD 槽 P1、进化选项加权待决策）+ 主观项登记（遗物平衡体感 / Build 质变感知 / 阶段 C 整体流程 → #5）
- 风险：**中**（回归 3 处同步点漏改必红——§1 表清单执行；commit 勿夹带 docs/pindou/、scripts/ui/*.bak、tools/pixel_to_pindou.py、docs/LOOP_HEALTH.md——各自动化/第三方自主提交）
- 验证：十六件套全绿 + baseline CLEAN + verify 36/36

---

## §2 全局风险表

| 风险 | 级 | 缓解 |
|---|---|---|
| inventory relic 分支短路遗漏 → 满被动玩家遗物误拒 | **高** | 本方案任务3 定案：relic 直装路径跳过 MAX_ITEMS 检查；探针 §4 专测 6 被动 + 2 遗物共存 |
| 回归同步点漏改（day13 :200 / day11_12 :351 / day16_event :414）→ 三探针红 | **中** | §1 表 4 处同步点清单化；D20-EXIT 十六件套收口强制全跑 |
| turret.gd 行号漂移（:89-94 → :108-109）→ 改错位置 | 中 | 方案已给现行行号；改前读 :100-120 上下文确认 |
| take_damage 插入点错位 → 金手指兜底语义变化 | 中 | 插入点定死 :290 与 :292 之间；探针 §3 专测 debug_cheat 仍 ×0.001 最后 |
| 探针 flaky（shuffle 全局 RNG / 双装配） | 中 | 白盒直构造 + 禁手动 apply_item_bonuses（D11-12/13 修复先例） |
| T-D 时限顺延（08-08 = 最后一天） | 高 | T7/T8 排 T1-T6 后同日完成；若 #3 未启动，下轮方案师/执行者优先推进 T7/T8 |
| 遗物 HUD 槽 / VFX / mech_heart 入池 | 低 | W5 不得判失败（P1 顺延 / Day 23 / 登记可选）——明确排除出本日验收 |

## §3 执行顺序建议

T1（数据 49→51）→ T2（装配键）→ T3（上限，含 relic 短路）→ T4（商店 + 3 处回归同步）→ T5（图标）→ T6（探针五段）→ T7/T8（T-D 硬性）→ EXIT（十六件套 + REPORT_PHASE_C + commit）。

**任一批次完成即 commit 勿等全量**（#1 裁决惯例，防工作区丢失）；**T7/T8 优先保障**（08-08 硬性时限，若时间不够优先 T-D 后补遗物余项，但本日排期足，正常并行即可）。

## §4 红线声明

本方案仅产出 SOLUTION_PLAN.md + TASKS.md 标注；不写代码、不改 .gd/.tscn/.tres/.json、不 git commit、不跑探针。

---

## 执行结果（#3 执行者 · 2026-08-07 18:0x · 第 27 轮）

**状态：[完成]** —— Day 20 遗物系统 + 阶段 C 收口 + T-D 技能图标全量落地，零阻塞。

- **批次 A（`494f18e`）**：T1 items.json 49→51（broken_crown/mech_engine，slot="relic" icon 20/21）；T2 player.gd STAT_MAP +damage_taken_percent/structure_damage_percent + 两属性 + take_damage armor 后乘 + apply_stat_modifier 两分支；T3 inventory MAX_RELICS=2 + get_relic_count + add_item_from_data relic 直装短路；turret.gd _fire 消费 structure_damage_mult。
- **批次 B（`54fd498`）**：T4 shop.gd 第三池 53→55（resonant_shard price0 天然排除）；T5 items.png 640→704×32 22 帧 + icon_atlas 20→22；回归同步 5 处（方案 §1 表 4 处 + **实测补 1 处**：day13 :223-226 item_count 20→22 —— 遗物同为 Item 资源计入 item_count，方案「零改动」判定不准，探针同步后三件套全绿）。
- **批次 C（`0ba7c7f`）**：T6 探针 day20_relic_check.gd 23/23 CLEAN（§1-§5 遗物五段 + §6 技能图标段；探针自身坑：take_damage 无敌帧逐用例重置、skill_controller 实例注入方可行）。
- **批次 D（`b9f815a`）**：T7 gen_skill_icons.py + skills.png 128×32 4 帧（全图 16 色 ≤216）；T8 hud.gd `_apply_skill_icon`（skill_data.id → 4 帧映射，无图降级/未知 id push_warning）。**T-D P0 硬性时限 08-08 前一日完成**。
- **批次 E（本轮收口 commit）**：**十七件套 452 断言全绿**（day2 32 / day3 16 / day4 21 / day5 16 / day6 14 / day7 13 / day8 19 / day10 20 / day11_12 24 / day13 36 / day14_15 54 / day16 41 / day17 39 / day17_p0 20 / day18_feedback 16 / day18_19 48 / day20 23）+ baseline **BASELINE CLEAN** + verify 36/36 + **REPORT_PHASE_C.md** + TASKS 收口标记。

- **执行中登记（非阻塞）**：① 方案 §1「day11_12 :370 / day13 :223 零改动」实测必红（遗物 Item 计入被动/Item 池统计），按回归同步惯例补改探针（验证工具非游戏系统）；② T8 需 IconAtlas 注册 skills sheet（方案 T8 文件清单未列 icon_atlas.gd，属接线必要最小补充）。
- **遗留（归口）**：遗物 HUD 槽 P1（Day 23+）/ 遗物 VFX（Day 23）/ mech_heart 入池登记可选 / 进化选项加权待决策；主观项（遗物平衡体感 / Build 质变 / 阶段 C 流程 / 技能图标辨识度）→ PLAYTEST（#5）。
- **下一目标日**：Day 21-22 美术资产落地（阶段 D 首段，D18-19 已预拆，等方案师落盘）。
