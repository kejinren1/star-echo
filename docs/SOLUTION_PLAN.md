# 方案计划（2026-08-08 · 第 14 轮）

## 当前开发日：Day 28（F-31 武器升级体系 · P0 用户拍板首段 + #4 测试域）

> **本轮性质：正式任务方案**（第 13 轮「头部确认版」→ 第 14 轮「F-31 正式方案」）。
> 触发：**#2 第 38 轮（14:05）已把反馈 2 三子项 F-31 函数级拆入 TASKS Day 28 区**（D28-F31-1~3 + EXIT，TASKS.md:2232-2265，显式标注「P0 · 用户拍板」）；#3 第 39 轮（14:35）登记「下一执行窗口（16:35）恢复执行，以方案第 14 轮为准」——**本方案即 #3 16:35 窗口的执行依据**。
> 用户原话（反馈 2）：「人物等级提升带来的技能提升本质应是人物基础性能提升（属性选项），武器升级是经济类，不应混入人物升级」→ 武器升级移出升级面板，改走商店铁砧经济闭环。
> ⚠️ **强耦合红线（#2 第 38 轮定）**：子项 b 与 c **必须同批 EXIT**（c 先行或同步）——武器唯一升级途径从面板 → 铁砧；进化需满级 Lv8，若 b 先落地而 c 未就绪 → 进化链断裂、F-20 进化保底失效。**禁 b 单独 commit 收口。**

---

## 0) P0 调度硬性输入检查（读 PLAYTEST 追踪区头部 · 本轮实测 15:26）

- 🚨 **P0 硬性输入命中 = F-31 武器升级体系**（增量 #50 13:0x 反馈专员汇报 + #51 13:3x 请拆解 + #2 第 38 轮 14:05 函数级拆入 Day 28 首段，TASKS 显式标注「P0 · 用户拍板」）——**本轮方案主体，全部纳入**。
- ✅ **增量 #52（15:2x · 最新）= F-31 拆解确认 + 艾琳动画实装登记轮**：TEST_REPORT #37（14:02）= **二十八件套 28/28（733 断言）全绿首跑**（fb4/fb5/fb6 并入 runner = #51 请求兑现 ✅）、0 功能缺陷 / 0 阻断；HEAD=`788af22`（14:58 艾琳动画实装）+ `9f2dbb9`（14:33 合规等待）+ `6c98ad9`（#52 入库）。工作区在途 = 用户侧 elin 二次修改 + 色彩字典工具（M elin_idle/walk.png + ART_STYLE.md + ?? COLOR_DICT/gen_color_dict/color_dict/pindou_editor）——**非本岗产物，不碰不提交**。
- 🔴 **Day 28 性能段（#4 域）跨第 7 轮零开工维持**：裁决态②「交 Owner 三选」未决，**不属 #3/#方案师**。
- 🔴 **P0 其余检查**：F 系列（F-01~F-30 + T-C/T-D）全 🟢「已落地 · 待真人回归」= 主观项交 #5；E-0 阶段 E 终审完整局 = 真人侧最高优先；无其他新机器可验证 P0。
- 🟠 **美术资源策略（08-07 21:1x 拍板）遵守**：F-31 零美术生成（anvil 无专属图标 → icon_index 0 兜底/复用现有帧，占位纯色口径）。

---

## 1) 任务方案（TASKS Day 28 区 D28-F31-1~3 + EXIT · 全部实测行号核验）

### 任务 F31-1【W1】初始武器出商店池（子项 a）

- **文件 A**：`scripts/autoload/data_loader.gd` 角色接口区（:279 `get_all_character_ids()` 之后，:281「波次接口」注释前）新增纯函数。
  - **改动**：新增 `func get_starting_weapon_ids() -> Array[String]:`——遍历 `_characters` 字典（:11 私有成员），收集 `starting_weapon` 字段**去重**返回（实测 10 把：pistol/fist/slingshot/wand/turret/dagger/se_star_flame/se_auto_turret/se_star_blade/se_holy_staff；零数据改动，characters.json 为单一事实源）。
  - **实现细节**：用 `str(_characters[cid].get("starting_weapon", ""))` 取值 + `not sw.is_empty() and not ids.has(sw)` 判重；返回类型 `Array[String]` 与武器 id 口径一致。
  - ⚠️ **修正 #2 拆解笔误**：拆解写「遍历 get_all_characters()」——实测现有 API 为 **`get_all_character_ids()`（:278-279）**，无 `get_all_characters()`；本函数直接读私有 `_characters` 字典即可（同文件无跨类问题），不依赖该 API 名。
- **文件 B**：`scripts/ui/shop.gd` `_build_shop_pool()` 武器池段（:172-178）。
  - **改动**：:171 注释行下方、:172 `for wid in ...` **之前**收集一次 `var starting_ids: Array = DataLoader.get_starting_weapon_ids()`；:174 跳过条件改为 `if wdata.is_empty() or wdata.has("evolution_result") or starting_ids.has(wid): continue`（起始跳过置于 evolution_result 跳过同处，`starting_ids.has(wid)` 对 Array[String] 可用）。
  - **池口径（落地后）**：武器 36 − 3 结果 − **10 起始** = **23 把**；+ 被动 23 + 遗物 2 = 48；**+ 服务池 anvil 1 = 总 49**（见 F31-3）。
- **文件 C**（W2 ◐只读核验，零写）：characters.json 10 把 starting_weapon ↔ weapons.json 36 把交叉命中（#2 已实测 10/10 零悬空，执行时复核即可）。
- **风险**：[低] 纯函数 + 单条件跳过，零副作用；`starting_ids.has(wid)` 为 O(n) 但 n=10 忽略。
- **验证**：day28_f31_check §1（武器段 == 23 / 10 起始零出现）；回归：day13_build_check :223-226 池计数断言（`item_count` 20→22→？——**⚠️ 需执行者实测**：day13 :223-226 曾因遗物 20→22 同步，本次池总 58→49 属**逻辑排除非数据增删**，池断言若以武器/被动/遗物分段计数则 33→23 必红、以总数计数则 58→49 必红——**无论何种写法，day13 池计数断言必须实测核对并同步**，此为本方案回归同步清单之外的第 3 处候选，执行者逐条 grep `_build_shop_pool`/`item_count` 核验）。

### 任务 F31-2【W1】升级面板移除「武器升级」选项（子项 b）

- **文件**：`scripts/ui/level_up_panel.gd` `_roll_options()` 武器升级池段（**现行实测 :66-72**）。
  - **改动**：**删除 :66-72 的武器升级池 for 段**（`for weapon in weapons:` + `if weapon and weapon.level < weapon.max_level:` + `pool.append({label 升级「X」/type weapon_upgrade/weapon})` 整块）。**保留 :61-65**（weapon_controller 获取 + `var weapons: Array = weapon_controller.get("equipped_weapons")`——进化池 :74 复用 `weapons`，删了必崩）。
  - **保留不动**：属性池（:57-60，stats.json upgrade_options 12 项 ≥3 → 删武器段后 3 选 1 恒成立）；进化池（:73-104）；方案 A 保底（:105-117）；`_apply_option` weapon_upgrade 分支（**:137-141 保留**，防御性 + 铁砧升级 UI 复用 `weapon.upgrade()` 语义）；注释同步（:48-52 头注释「属性 + 武器升级 + 进化」→ 面板实际两型，weapon_upgrade 分支留作铁砧/兼容路径）。
  - ⚠️ **修正 #2 拆解行号**：拆解写「:64-72 删整段」——实测 :64 是 `if weapon_controller:`（进化池入口依赖，**不能删**），:65 是 `var weapons`（进化池依赖，**不能删**），真正删除范围 = **:66-72 for 段**。
- **风险**：[中] 强耦合 c（见红线，执行序保障）；[低] 删段后属性池仍 ≥3 项，3 选 1 恒成立（:57-60 实证）。
- **验证**：day28_f31_check §2（`_roll_options(99)` 零 weapon_upgrade + 属性池可 roll + 满级持核心必含 evolution）；回归同步 2 处（见 EXIT 清单）。

### 任务 F31-3【W1】铁砧 anvil 120G 零消费点闭环（子项 c）

- **文件 A**：`scripts/ui/shop.gd` `_build_shop_pool()` 遗物池后新增「服务池」段（:194 遗物循环结束后、:195 `return pool` 前）。
  - **改动**：新增循环——遍历 `DataLoader.get_all_item_ids()`，条件 `not idata.is_empty() and bool(idata.get("effects", {}).get("shop_weapon_upgrade", false))`（实测仅 anvil，items.json:567-575：price 120 + effects.shop_weapon_upgrade true）→ `_build_item_resource(iid)`（:204-219 复用，自动带 icon_index 0 兜底 + trigger 透传）入池。
  - **池口径**：23 武器 + 23 被动 + 2 遗物 + **1 anvil** = **49 总池**（**修正 #2 拆解「=48 商品」口径**——拆解漏算 anvil 自身入池，探针/测试点按 49）。
  - anvil 天然不冲突：无 `is_passive`（被动池不收）、无 `slot=="relic"`（遗物池不收）、无 `weapon_type`（武器池不收）——现池 58 中零出现 = 真零消费点现状佐证。
- **文件 B**：`scripts/ui/shop.gd` `_purchase_item()` 第三分支（**:335 钱检查 return 后、:337 武器分支之前**插入）。
  - **改动**：新增分支——判定 `var sb: Variant = item.get("stat_bonuses"); if sb is Dictionary and bool(sb.get("shop_weapon_upgrade", false)):`：
    1. 收集可升级武器：`var wc: Node = GameManager.player.get_node_or_null("WeaponController") if GameManager.player else null`（shop.gd:341 已有同款先例）→ `var ups: Array = []`，遍历 `wc.get("equipped_weapons")`，`weapon.level < weapon.max_level` 则收集。
    2. **空 → 拒绝不扣费**：`push_warning("[Shop] 无可升级武器，铁砧购买失败")` + `return`（商品保留）。
    3. **有 → 弹武器升级选择 UI**：shop.gd 内新增 `_show_anvil_panel(ups: Array, item: Resource, index: int) -> void` + `_close_anvil_panel() -> void`——**动态构建**（零新 tscn，复用 `_create_card` :232 动态构建先例 + CARD_TEXTURE 九宫格样式）：CanvasLayer（置顶）+ 半透明全屏 Panel（mouse_filter STOP 防穿透，:242-244 先例）+ 居中 VBox + 标题「铁砧 · 武器升级（120G）」+ 每可升级武器一行 Button（文本：`武器名 · Lv.X → Lv.X+1`）+ 取消按钮。点选 → `_apply_anvil_upgrade(weapon)`：`weapon.upgrade()`（weapon.gd:82 确认存在，满级返回 false 不会发生——列表已过滤）→ `GameManager.economy.spend_coins(price)`（**用 :325 已取的 price 数据驱动 = 120，不用字面量**）→ `shop_items.remove_at(index)` → `_render_cards()` → `purchase_made.emit(item)` → `AudioManager.play_sfx("shop")`（D24 接线 :355/:364 同款）→ `_close_anvil_panel()`。取消 → 仅关闭（不扣费不升级）。
    4. 升级语义与 level_up_panel 武器升级路径一致（直接 `weapon.upgrade()` 改资源，攻击逻辑每帧读取天然生效，**零额外信号接线、零 HUD 改动——不臆造新刷新链路**）。
    5. anvil 为一次性商品卡：购买后 `remove_at(index)`（刷新重随机，:351-355 武器分支同款）。
  - **图标/tooltip**：anvil `icon_index` 0 兜底（items sheet 帧 0，占位纯色口径零新图）；`desc_builder.gd` :49/:70 `shop_weapon_upgrade` 中文映射已就绪（「商店武器升级」）→ 卡片 tooltip 自然生效（:307 `DescBuilder.card_tooltip` 复用）。
- **风险**：[中] 动态构建 UI 无场景文件先例——全部代码构建，探针无法实例化 tscn 时须走「临时场景 + --quit-after」或 SceneTree 模式白盒直调方法（day24_f13 范式）；鼠标层（置顶 + STOP）须显式；[低] spend_coins 用 price 数据驱动防硬编码漂移。
- **验证**：day28_f31_check §3 白盒（anvil 在池 / 无可升级 → 拒绝且金币不变 / 可升级 → 选 1 把 +1 级 + 扣 120G + 商品移除 / 满级后不再列）。

### 任务 F31-EXIT【W5】回归 + 探针

- **新探针**：`tools/day28_f31_check.gd` 四段（≥16 断言）：
  - §1 商店池口径：`_build_shop_pool()` 武器段 == 23 / 10 起始 id 零出现 / 被动 == 23 / 遗物 == 2 / anvil 在池 / 总池 == 49。
  - §2 升级面板：白盒 `_roll_options(99)`（无武器/未满级武器场景）零 `weapon_upgrade` / 结果非空（属性池可 roll）/ 满级+持核心（白盒构造 source_id meta + inventory 持核心，day13:488 先例）必含 evolution（F-20 保底不回归）。
  - §3 铁砧闭环白盒（day13/day18_feedback2 白盒直构造先例）：economy 金币前置构造 → 无可升级武器拒绝不扣费 / 可升级 → `_apply_anvil_upgrade` +1 级 + 扣 120G + 商品移除 / 满级武器不在可升级列表。
  - §4 回归抽样（day5 反向 + day16 事件 weapon_upgrade 保留 + desc_builder tooltip 保留）。
  - **探针驱动坑**：`--script` 模式三坑照旧——Autoload（GameManager/DataLoader/AudioManager）首帧 `root.get_node_or_null` 获取（_init 太早）；shop.gd 引用 Autoload → 场景实例化须临时测试场景 + `--quit-after` 或 SceneTree + `_process` 驱动带参 `_advance(sub)`（day24_f13 范式，无无参 `_advance()`）。
- **回归同步清单（全量 grep 实测 · 精确到断言）**：
  - 🔴 **反向 2 处**：① `tools/day5_weapon_check.gd` :208-222 4a 断言（`_roll_options(20)` 必须含 weapon_upgrade → **反向**为「零 weapon_upgrade」，顺带验证属性池仍可 roll；:218-222 4b `_apply_option` 注入分支**保留不红**——分支保留；:228-253 4c 真实交互只点「第 0 个按钮」不断言类型**不红**）；② `tools/day13_build_check.gd` :502-511 第二断言（未满级普通武器 → 有 weapon_upgrade → **反向**为「零」；:494-500 第一断言「满级结果武器不在升级池」天然继续成立**不红**）。
  - 🟡 **池计数候选 1 处（实测核对，勿漏）**：day13_build_check 池计数断言（历史 :223-226 `item_count` 20→22 同步先例）——F-31 池 58→49 后无论分段/总数写法必红，**执行者逐条 grep `_build_shop_pool`/`item_count` 核验同步**（第 7 轮教训：D32 清单不全实测多 3 处）。
  - ✅ **保留不红 3 处**：`tools/day16_event_check.gd` :269-278（事件奖励 = GameManager `_apply_event_weapon_upgrade` :438-439/:469-470 路径，与面板无关）；`tools/day18_feedback5_check.gd` :142（option_tooltip weapon_upgrade 纯函数分支保留）；`scripts/ui/desc_builder.gd` :150（同保留）。
- **EXIT 出口**：`python tools/baseline_check.py` → `BASELINE CLEAN`；回归基准 = **二十八件套 ≥733 断言 + day28_f31 新增**（#37 14:02 已兑现 733 全绿首跑；F-31 落地后 runner 增为 29 项）；git commit 收口（**b + c 同批**，禁 b 单独收口；改前 commit、改后 baseline 护栏）；收口后交 #5 登记真人回归（升级面板只剩属性/进化 / 商店不再刷起始武器 / 铁砧 120G 买武器升级 / 进化链经铁砧升满仍可达）。
- **风险**：[中] 回归同步面 3 处候选（2 反向 + 1 池计数）漏改必红——已全量 grep 闭环；[中] 进化保底 §2 白盒构造复杂度（day13 :488 先例可循）。

---

## 2) 执行序（#3 第 40 轮 · 16:35 窗口）

| 批次 | 内容 | commit 护栏 |
|---|---|---|
| 批次 A | F31-1（data_loader 纯函数 + shop 池跳过） | 独立可 commit（a 不影响 b/c 耦合） |
| 批次 B | F31-3（anvil 服务池 + 购买分支 + 选择 UI）→ F31-2（删 :66-72 + 注释）→ 回归反向 2 处 + 池计数核验 → 探针 day28_f31 → EXIT | **b+c 同批收口，禁 b 单独 commit**；改前 commit 工作区（用户在途 elin/色彩字典**勿夹带**） |

> ⚠️ 工作区在途 = 用户侧 `elin_idle.png`/`elin_walk.png`/`ART_STYLE.md` + 未跟踪 `ART/COLOR_DICT.json`/`tools/color_dict.py`/`tools/gen_color_dict.py`/`tools/pindou_editor.html`——**#3 commit 时只 add 本批次文件，禁止 `git add -A` 夹带用户在途资产**。

## 3) 关键实测行号表（供 #3 免排查 · 均为 15:2x 现行实测，TASKS 拆解行号已漂移勿直接用）

| 位置 | 现行行号 | 说明 |
|---|---|---|
| data_loader.gd `_characters` 字典 / get_all_character_ids / get_character | :11 / :278-279 / :274-275 | 纯函数插入点 = :279 后（:281 波次接口注释前） |
| shop.gd `_build_shop_pool()` | :169-195 | 武器循环 :172-178（跳过条件 :174）· 被动 :180-186 · 遗物 :188-194 · return :195 |
| shop.gd `_purchase_item()` | :319-366 | 钱检查 :327-334 · 武器分支 :337-356 · 被动分支 :359-366 · **anvil 第三分支插入点 = :336 前** |
| shop.gd `_build_item_resource()` | :204-219 | anvil 复用（icon_index 0 兜底 + trigger 透传 :218） |
| shop.gd 卡片动态构建 / tooltip | :232-309 / :307 | `_create_card` 为 anvil 选择 UI 构建范式；mouse_filter STOP 先例 :242-244 |
| level_up_panel.gd `_roll_options()` | :53-119 | 属性池 :57-60 · weapon_controller 获取 :61-65（保留）· **删除段 = :66-72** · 进化池 :73-104 · 保底 :105-117 |
| level_up_panel.gd `_apply_option` weapon_upgrade 分支 | :137-141 | 保留（铁砧语义复用） |
| weapon_controller.gd `equipped_weapons` | :28 | anvil 可升级列表来源 |
| weapon.gd `upgrade()` | :82 | 满级返回 false（列表已过滤不会触发） |
| items.json anvil | :567-575 | price 120 + effects.shop_weapon_upgrade true（零数据改动） |
| 回归反向 ① day5 | :208-222（4a）| 4b :222 / 4c :228-253 不红 |
| 回归反向 ② day13 | :502-511 | :494-500 不红 |
| 池计数候选 day13 | 历史 :223-226（grep 核验现行）| 58→49 必红候选 |
| 保留 3 处 | day16 :269-278 / fb5 :142 / desc_builder :49/:70/:150 | 零改动 |

## 4) 风险表

| 风险 | 级 | 说明与替代 |
|---|---|---|
| b/c 强耦合（进化链断裂） | 高 | 红线执行序保障：c 先落地，b 不得单独收口；若 B 批中途失败 → 保留 c 提交不提交 b，下轮续 |
| 回归同步面漏改 | 中 | 全量 grep 闭环 3 处候选（2 反向 + 1 池计数），执行者按清单逐条核对 |
| anvil 选择 UI 无场景先例 | 中 | 全部代码动态构建（_create_card 范式），探针走白盒直调方法；若构建卡壳 → 降级为「直接升级随机 1 把已装备武器」（拆解备注的简化路径）并登记 |
| 探针 Autoload 依赖 | 中 | day24_f13 范式（SceneTree + _process 驱动 + 首帧获取 Autoload） |
| 升级面板 3 选 1 恒成立 | 低 | 属性池 12 项 ≥3（:57-60 实证），删武器段后不触发空池 |
| 事件奖励 weapon_upgrade 保留 | 低 | GameManager 路径独立，与面板无关（不红） |

---

## 5) 开放项（供 #5 追踪区刷新）

| 开放项 | 状态 | 建议下一动作 |
|---|---|---|
| **F-31 武器升级体系** | 📋 方案第 14 轮已落盘（本轮） | #3 第 40 轮（16:35）按本方案批次 A→B 执行；收口后交 #5 登记真人回归 |
| Day 28 性能段（帧率/内存/同屏敌人数） | 🔴 零开工跨第 7 轮；裁决态②交 Owner 三选未决 | Owner 三选（核查 #4 / 降级 D30 兜底 / 授权补登记口径） |
| 工作区用户在途资产（elin 二次修改 + 色彩字典工具） | ⚠️ 未提交 | 用户/主会话尽快 commit 防覆盖；#3 收口时勿夹带 |
| F 系列 12+ 项真人回归（含 F-31 落地后新增 4 项主观回归面） | 🟢 已落地·待真人回归 | Day 29 人工试玩一次性验收（E-0 终审完整局最高优先） |
| 主观维度（基地 UI 观感 / 研究成长体感 / 剧情解锁趣味 + U-1 艾琳动画观感 + F-31 主观回归面 3 子项） | 预登记/待转正 | #5 试玩收集 |
| 顺延项 5 条（F-11 接口偏差 / vfx_container / 遗物 HUD 槽 / 空间音 / mech_heart 入池） | P1·不阻塞 | 维持追踪，Day 29 polish 评估 |
| R4 攻击力口径 | 挂账第 28 轮 | 维持（Day 29 前不阻断） |

---

## 6) 执行结果（#3 第 40 轮 · 2026-08-08 16:5x）

**【完成】** F-31 武器升级体系全量落地（P0 用户拍板首段），批次 A + 批次 B 全闭环，零阻塞：

- **批次 A（`f30d402`）**：F31-1 初始武器出商店池——`data_loader.gd` 新增 `get_starting_weapon_ids()` 纯函数（实测 10 把去重，含 se_holy_staff；weapons.json 交叉 10/10 零悬空）+ `shop.gd` 武器循环跳过条件追加 `starting_ids.has(wid)`。
- **批次 B（b+c 同批收口，未单独 commit）**：
  - **F31-3** `shop.gd`：服务池段（anvil 入池，池口径 23+23+2+1 = **49**）+ `_purchase_item` 第三分支（无可升级拒绝不扣费 / 有 → `_show_anvil_panel` 动态构建选择 UI：CanvasLayer 置顶 + 遮罩 STOP + 居中 VBox + 每武器一行「武器名 · Lv.X → Lv.X+1」+ 取消）+ `_apply_anvil_upgrade`（`weapon.upgrade()` + `spend_coins(price=120 数据驱动)` + 商品移除 + `purchase_made.emit` + SFX）+ `_close_anvil_panel`；零新 tscn / 零新图（icon_index 0 兜底，美术策略遵守）。
  - **F31-2** `level_up_panel.gd`：删除 :66-72 武器升级池 for 段（weapon_controller 获取 + `var weapons` 保留 = 进化池依赖）；`_apply_option` weapon_upgrade 分支保留（铁砧/兼容路径）；头注释同步。
  - **回归同步 7 处**（方案清单 3 处 + 实测补 4 处 = 第 7 轮教训复现，已全量闭环）：day5 反向 + day13 反向/池计数 + day11_12 池 + day20 池 ×2 + day24_f13 池 + day26 §6 锚点（28→29 / 733→749）。
  - **探针 `day28_f31_check.gd` 26/26 CLEAN 四段** + runner 28→29 项。
- **护栏**：`python tools/baseline_check.py` → **BASELINE CLEAN**；回归 **29/29 全绿（759 断言）**。
- **执行登记 2 处**：① 生产代码缺陷修复——F31-3 第三分支初版 `w.get("level", 0)` 双参（Resource.get 单参）在满级武器场景报 SCRIPT ERROR，已改单参+判空（探针场景 3 实证）；② 探针 RID leak（未入树 mock 节点，仅 `--script` 模式，不影响 PASS 判定，真实游戏零影响）。
- **交 #5 登记真人回归 4 项**：升级面板只剩属性/进化 / 商店不再刷起始武器 / 铁砧 120G 买武器升级 / 进化链经铁砧升满仍可达。
