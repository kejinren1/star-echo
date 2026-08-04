# 《星骸回响》Star Echo · 框架差异清单（Framework vs Star Echo Diff）

> 产出日：Day 1（2026-08-05）· 自动化 #3 执行
> 配套文档：`docs/30DAY_PLAN.md`（规划/风格）、`docs/TASKS.md`（每日任务，D1-T1/T2/T3 已拆解）、`docs/GDD.md`（*旧* Astral Spud 框架文档，仅作现状参考，非 Star Echo 内容源）
> 方法：核对「大纲/规划要求」与「现有代码与数据现状」，列出差异与缺口，标注归属开发日。
> 本日动作：Day 1 为分析 + 文档 + 主动技能输入打桩（D1-T1），**不实现技能逻辑**（归 Day 3）。

---

## 0. 结论速览

| 维度 | 结论 |
|---|---|
| 框架 baseline | 健康：`baseline_check` → `BASELINE CLEAN`（集成节点 f528756 复验）；导入/实例化/运行时零错误 |
| 操作映射（大纲 §5） | 移动 ✓、自动攻击 ✓、**主动技能 ✗（缺口，本日已打桩 `skill_cast`）**、路线选择（UI 原语具备，地图 Day 14+） |
| 数据层可复用性 | **可复用**。全部为「增字段」而非「改结构」，`DataLoader` 无需重写 |
| 当前数据计数 | `characters.json`=9、`weapons.json`=32、`items.json`=47、`stats.json` 完整（注：TASKS.md 旧标注 6/29/39 为并发冲刺前原始值，已过期） |

---

## 1. 输入操作差异（大纲 §5：移动 / 主动技能 / 自动攻击 / 路线选择）

大纲 §5 原文：*操作 = 移动（玩家控制）+ 主动技能释放（玩家控制，带冷却/资源）+ 路线选择（玩家控制）；攻击自动释放。*

### 1.1 移动（玩家控制）— ✅ 已对齐
- 现状：`scripts/player/player.gd:109-117` `_handle_movement()` 经 `Input.get_axis("move_left","move_right")` / `("move_up","move_down")` 读 8 向输入，归一化后 `move_and_slide()`。
- 映射：`project.godot` 已定义 `move_up/down/left/right` → WASD（物理键码 87/83/65/68）。
- 判定：符合大纲。无需改动。

### 1.2 自动攻击（自动释放）— ✅ 已对齐
- 现状：`scripts/weapons/weapon_controller.gd:43-56` 按 `fire_rate` 冷却自动触发；`:86-105` `_get_aim_direction()` 用 `owner_node.get_global_mouse_position()` 朝鼠标射击。
- 判定：符合大纲「攻击自动释放」（玩家不按攻击键）。无需改动。

### 1.3 主动技能释放（玩家控制，带冷却/资源）— ❌→🟡 本日打桩（逻辑归 Day 3）
- 缺口（D1-T1 已修复输入层）：
  - `project.godot` 原 `[input]` 仅 6 动作（`move_*`×4 + `ui_accept`(Z/Enter) + `ui_cancel`(Esc)），**缺主动技能动作**。
  - 本日已在 `project.godot` 新增 `skill_cast`（Space + 鼠标右键双绑定），并在 `player.gd` 预留 `_unhandled_input` / `is_action_pressed("skill_cast")` 空挂钩 `_try_cast_skill()`（仅打桩，Day 3 填充「读 hero.skill → 冷却 → 差异化释放」）。
- 测试点：`InputMap.has_action("skill_cast") == true`；4 向移动零回归；`baseline_check` 仍 `BASELINE CLEAN`。

### 1.4 路线选择（玩家控制）— ⏳ UI 原语具备，地图未建（Day 14+）
- `ui_accept`(Z/Enter)、`ui_cancel`(Esc) 可作节点地图确认/返回原语；随机节点地图（战斗/事件/精英/商店/Boss + 种子复现）尚未实现，归属 **Day 14–15**。

---

## 2. 角色差异

- **计数**：`data/characters.json` = `{characters:[9]}`（旧 6 角色 + Star Echo 3 英雄 `se_irene`/`se_noa`/`se_ren`）。
- **起始武器交叉引用**：9/9 全部命中（`starting_weapon` 指向 `weapons.json` 有效 id，含 se_ 签名武器 `se_star_flame`/`se_auto_turret`/`se_star_blade`），无悬空引用（gambler 悬空已在集成节点 f528756 修复为 `dagger`）。
- **技能数据就绪**：三英雄均含 `skill{id,type:"active",cooldown,...}`（艾琳 8s 火球 / 诺亚 12s 部署炮台 / 莱恩 10s 星刃爆发）与 `growth{type,per_level,...}` 养成曲线。
- **⚠️ 缺口（建议 Day 2 收敛）**：三英雄**均无 `sprite` 字段**，`scripts/character_select.gd:27` 当前靠硬编码 `PORTRAIT_ALIAS`（elin/noah/lain）映射立绘 → 建议 Day 2 在 `characters.json` 补 `sprite` 字段，使立绘解析数据驱动、去硬编码。
- **消费方就绪**：`character_select.gd` 经 `DataLoader.get_character(hero_id)` 读取，`HERO_IDS=["se_irene","se_noa","se_ren"]`；选择结果存 `root` meta，待 Day 2 由 Main/Player 消费。
- **判定：结构可复用 ✅**，无需重建。

---

## 3. 武器差异

- **计数**：`data/weapons.json` = `{weapons:{4 类, 共 32}}`（melee 8 / ranged / elemental / engineering）。
- **条目字段**：`damage/cooldown/range/crit_chance/crit_damage/scaling/knockback/life_steal/special` + 签名武器附加 `level[]` / `evolution`。
- **升级曲线现状**：
  - ✅ **3 把 se_ 签名武器已含完整 Lv1–8 `level` 数组 + `evolution` 字段**（例 `se_star_flame` Lv8 可进化炎星陨落，配 `se_flame_core`）。
  - ⚠️ **29 把旧武器多为单级数值，缺 Lv1–8 `level` 升级表** → 阻塞 Day 5（6 槽挂载）/ Day 7–9（15 武器 Lv1-8 数据）/ Day 10（进化需 Lv8 判定）。需按 se_ 模式补 `level[]`。
- **判定：结构可复用 ✅**，仅「增 `level` 字段」；evolution schema 已验证可用。

---

## 4. 属性差异（大纲 10 属性 vs `stats.json`）

大纲 10 属性：攻击力 / 攻速 / 范围 / 移速 / 暴击率 / 暴伤 / 生命 / 护甲 / 吸血 / 幸运。

| 大纲属性 | stats.json 对应 | 状态 |
|---|---|---|
| 攻速 | `attack_speed` | ✅ |
| 范围 | `range` | ✅ |
| 移速 | `speed` | ✅ |
| 暴击率 | `crit_chance` | ✅ |
| 暴伤 | `crit_damage` | ✅ |
| 生命 | `max_hp` | ✅ |
| 护甲 | `armor` | ✅ |
| 吸血 | `life_steal` | ✅ |
| 幸运 | `luck` | ✅ |
| **攻击力** | — | ❌ **口径冲突** |

- **9/10 直接对应**，`stats.json` 另含 `hp_regen/dodge/pickup_range/harvesting/xp_gain/engineering/curse` 等扩展。
- **唯一冲突：「攻击力」**。现框架拆为 `melee_damage` / `ranged_damage` / `elemental_damage` 三系，无统一「攻击力」口径。
- **决策点（Day 4 强化面板依赖）**：A) 聚合为统一攻击力；或 B) 保留三系、UI 聚合展示。需在 Day 4 前拍板，影响升级面板（stats.json `leveling.upgrade_options` 当前用 `+5 melee_damage` 等三系写法，已倾向方案 B）。
- 判定：属性层可复用 ✅，仅「攻击力」需 Day 4 决策。

---

## 5. 被动 / 道具差异

- **计数**：`data/items.json` = `{items:[47]}`（common 15 / uncommon 12 / rare 10 / legendary 8 / 进化核心 2）。
- **进化核心就位**：`se_flame_core`(烈焰核心) / `se_mech_core`(机械核心) / `elemental_core`，均含 `evolution{weapon_id,requires_level:8,result_id,result_name,description}` → 直接支撑 Day 10 进化。
- **⚠️ 缺口（Day 11–12 需补）**：条目字段 `id/name/rarity/price/effects/tags`，**缺被动槽位标识**（如 `slot` / `is_passive`）以区分「道具」与「被动」。20 被动 + 6 被动槽装配需补标识字段。
- 判定：结构可复用 ✅，仅「增 `slot`/`is_passive` 字段」。

---

## 6. 缺失系统清单（按归属开发日）

| # | 系统 | 大纲/规划要求 | 现状 | 缺口 | 归属日 |
|---|---|---|---|---|---|
| 1 | 主动技能系统 | 火球/召唤/环绕（CD/资源） | 输入已打桩 `skill_cast`；数据 `skill{}` 就位 | 缺技能状态机 + 差异化释放 | **Day 3** |
| 2 | XP / 升级面板 | 击杀掉经验→强化选择（10 属性） | GameManager 波次/商店信号存在；`apply_stat_modifier` 接口存在 | 缺经验积累 + 3 选 1 面板 | **Day 4** |
| 3 | 武器 6 槽 + Lv1-8 | 6 槽挂载 + 升级曲线 | `weapon_controller` 支持多武器；se_ 含 `level[]` | 旧武器补 `level[]` + 槽位上限对齐 | **Day 5 / 7–9** |
| 4 | 武器进化 | Lv8 + 核心 = 进化 | `items.json` 含 `evolution` 数据 | 缺进化判定与切换逻辑 | **Day 10** |
| 5 | 20 被动 + 6 槽 | 4 类被动 + 6 槽 | 被动模式可用（effects） | 补数量 + `slot` 标识 + 装配逻辑 | **Day 11–12** |
| 6 | 随机节点地图 | 5 类节点 + 种子复现 | 无 | 全新系统 | **Day 14–15** |
| 7 | 事件节点 | 10 文本抉择 | `events.json` 已含 10 事件 | 缺触发/结算 UI | **Day 16** |
| 8 | 精英战斗 | 特殊能力/强化 | 敌人数据基础 | 缺精英生成规则 | **Day 17** |
| 9 | 两阶段 Boss | 腐化巨树（藤蔓/毒雨） | 无 | 全新 Boss 系统 | **Day 18–19** |
| 10 | 遗物 | 破碎王冠/机械核心 | 核心数据就位 | 缺遗物规则与效果 | **Day 20** |
| 11 | 局外养成 | 方舟基地 + 研究系统 | 无 | 全新 Meta 系统 | **Day 27** |

> 注：Day 2 前置（hero id 消费 + 初始武器挂载 + `sprite` 字段收敛）见 TASKS.md「待办（Day 2 起）」与本文 §2。

---

## 7. 风险与护栏

1. **数据计数漂移**：TASKS.md 旧标注 (6)/(29)/(39) 已过期，任务拆解（#2）应改用实际值 9/32/47。
2. **旧 GDD 与新大纲冲突**：`docs/GDD.md` 仍为 Astral Spud（6 角色 / 39 道具 / 元素反应），与 Star Echo 三英雄 / 20 被动 / 进化不一致。**以 `30DAY_PLAN.md` + `游戏设计大纲.docx` 为权威**，GDD.md 仅作框架现状参考。
3. **攻击力口径决策**：必须在 Day 4 前拍板（见 §4），否则升级面板与 Build 数值地基不稳。
4. **Hero id 消费是 Day 2 关键前置**：CharacterSelect 已写 `root` meta，但 Main/Player 未读；Day 2 不打通则 Day 3 技能无法按英雄差异化。
5. **不擅自写码原则**：本日仅新增 `skill_cast` 输入动作 + 空挂钩（打桩），未实现任何技能逻辑、未删文件、未改无关系统；baseline 维持 `CLEAN`。

---

## 8. 本日交付物（Day 1）

- ✅ `docs/DIFF_FRAMEWORK_STARECHO.md`（本文档，6 章 + 结论/风险/交付物）
- ✅ D1-T1：`project.godot` 新增 `skill_cast` 输入动作 + `player.gd` 预留 `_try_cast_skill()` 空挂钩（打桩）
- ✅ D1-T3：数据结构可复用结论固化（§2/§3/§4/§5）
- ✅ `baseline_check` → `BASELINE CLEAN`（改动后复验通过）
- ⏭️ 待 #2 推进至 **Day 2**：hero id 消费 + 初始武器挂载 + `sprite` 字段收敛
