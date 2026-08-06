# 《星骸回响》Star Echo · 阶段 B Build 系统集成报告（REPORT_PHASE_B）

> 生成：2026-08-06 14:5x（自动化 #3 Day 13 收口轮）｜文件域：W5（docs）
> 阶段 B = Day 7–13：武器数据与图标 → 进化机制 → 被动+商店 → **Build 系统集成 + 数值冒烟（收口）**
> 数据只读核验：`data/*.json` 全程只读，本报告仅登记口径与结论

---

## §1 阶段 B 七日回顾

| 开发日 | 主题 | 收口提交 | 状态 |
|---|---|---|---|
| Day 7 | 15 武器数据（11 把补 levels 8 条 + 33 把 icon_index）+ 装配消费（crit/pierce/icon）+ 图标集 40 帧 | `fc2a636`（13/13 CLEAN） | ✅ 收口 |
| Day 8-9 | 18 把全量武器 levels + 18 帧图标实绘替换 + 全量数据回归（33/33 Lv1-8） | `d1e72f1`（19/19 CLEAN） | ✅ 收口 |
| Day 10 | 武器进化机制（3 签名进化链 + 3 结果武器 + 进化池 + 爆炸 AOE + replace_weapon） | `ca7c0a2`（20/20 CLEAN） | ✅ 收口 |
| Day 11-12 | 20 被动四类 + 6 被动槽 + 装配链路 + 商店真实商品 + 图标 20 帧 | `4bc79df`（22/22 CLEAN） | ✅ 收口 |
| Day 13 | **Build 集成收口：暴击结算点 / 两套体系统一 / 炮台常驻多台 / BUG-002 / 攻速消费 / 数值冒烟** | 本轮 commit（36/36 CLEAN） | ✅ 收口 |

**D13 集成结论**：阶段 B 五大缺口全部闭环 —— 暴击通道从「装配但不结算」到真实出伤；武器两套体系（战斗 equipped_weapons vs HUD inventory.weapons）统一为 inventory 权威源；商店真实路径修复（BUG-002：String push 进 Array[Resource] 类型冲突 → 4 ERROR + 0 卡）；攻速通道补上消费点（升级/被动/buff 从此生效）；回归十件套全绿 + 基线双阶段 CLEAN，无阻塞性缺陷。

---

## §2 武器数据（36 把全量 Lv1-8 + 3 结果武器）

### 2.1 全量口径（Day 7-9 数据收口）

- `data/weapons.json` **36 把**：melee 9 / ranged 9 / elemental 10 / engineering 8（33 常规 + 3 evolution_result 结果武器）
- **33 把常规武器全部 `levels` 8 条 + `max_level: 8`**（Lv1 条与顶层一致，damage 单调不减 / cooldown 单调不增）
- `icon_index` 分类内顺序索引（melee 0-7 / ranged 8-16 / elemental 17-25 / eng 26-32）+ 结果武器 33/34/35；`weapons.png` 40 帧（36 实绘 + 4 空余）
- 特例：`force_field` damage 恒 0（护盾只升 cd/range）；`minigun` Lv1 cd 0.08（全表最低射速上限）
- 生成工具 `tools/gen_weapons_day7.py`（幂等 apply/verify）+ `tools/gen_weapon_icons.py`（PIL 像素原语）

### 2.2 DPS 上限参照（Lv8，不含暴击/攻速倍率）

| 武器 | Lv8 DPS | 定位 |
|---|---|---|
| minigun | ≈345（19 / 0.055） | 单体速射上限 |
| flamethrower | ≈250（10 / 0.04） | 群体持续 |
| hammer | ≈155（140 / 0.90） | 高伤低频 |
| rocket_launcher | ≈130（117 / 0.90） | AOE 型控 |

### 2.3 进局/装卸/替换统一（D13-T2）

- **权威源 = `inventory.weapons`**（HUD 读数源），`equipped_weapons` = 战斗执行副本
- `sync_inventory_weapons()` 按 equipped 的 meta source_id 全量重建；进局（main._equip_starting_weapon）/ 装备 / 卸下 / 重复 sync 幂等无副作用；无 source_id 占位（初始枪）不写入
- 商店购买双写（add_weapon + equip_weapon）+ 进化替换（replace_weapon_slot 原位）沿用既有单点

---

## §3 进化机制（Day 10）

| 武器 | 核心（items.json） | 结果武器 | 机制 |
|---|---|---|---|
| se_star_flame 炎星术 | se_flame_core 烈焰核心 | se_star_fall 炎星陨落 | 大型火焰陨石 AOE（explosion_radius 90） |
| se_auto_turret 自动炮台 | se_mech_core 机械核心 | se_turret_array 机械炮阵 | 炮台常驻 + 部署 +2（D13-T3 实装） |
| se_star_blade 星刃 | se_blade_core 剑刃核心 | se_blade_storm 星刃风暴 | 环绕刃数 6（orbit_data） |

- 进化链路：Lv8 武器 + 持核心 → 升级面板进化选项（**先替换成功、后消耗核心**，失败不消耗）
- 结果武器平曲线（Lv1==Lv8==顶层），`evolution_result` 标记 3 把 —— 商店池排除、升级池满级天然排除（D13 复算：无泄漏）

---

## §4 被动 + 商店（Day 11-12 + D13 收口）

### 4.1 被动 20（四类 5+5+5+5）

- `items.json` 48 项中 20 项 `is_passive=true`：attack 5 / defense 5 / stat 5 / special 5；`icon_index` 0-19 唯一；17 常规项 effects 键 ⊂ 白名单（3 进化核心豁免）
- 6 被动槽（inventory.MAX_ITEMS=6 + HUD ItemSlot0-5）；被动只从商店获取（不进升级池）
- 装配链路：inventory.item_added/removed 信号 → player.apply_item_bonuses（percent 乘算 / remove 除法精确还原）

### 4.2 商店闭环（BUG-002 修复后）

- 商店池 = **53**：33 武器（36 − 3 evolution_result）+ 20 被动；随机 4 卡
- **D13-T6 修复**：`_build_shop_pool()` 原返回 String id 列表直接 append 进 `shop_items: Array[Resource]` → 类型冲突每进商店 4 ERROR + 0 卡（#4 实测 BUG-002）；现返回资源实例（武器 build_weapon_from_data / 被动 Item.new 填四字段），`_refresh_shop` 真实路径 4 卡渲染零 ERROR
- 购买：先入库后扣费；武器装备失败回滚入库；槽满拒绝不扣费

---

## §5 数值冒烟结论（D13-T4/T5 定案）

### 5.1 10 属性公式对照表（大纲 ↔ formulas ↔ STAT_MAP ↔ 消费点）

| 大纲属性 | stats.json formulas | STAT_MAP 键 | 消费点（代码） | 通道/口径 |
|---|---|---|---|---|
| 攻击力 | `damage` | `damage_percent` | weapon_controller._spawn_projectile | player.damage_multiplier 倍率 |
| 攻速 | `attack_speed`（cd / (1+%)） | `attack_speed_percent` | **weapon_controller._process（D13 补）** | delta × player.attack_speed 冷却递减；炮台不享（召唤物设计内） |
| 范围 | `range` | `range_percent` | range_multiplier（200px 基准） | 弹丸 lifetime = range/speed |
| 移速 | `speed` | `speed_percent` | player._handle_movement | move_speed 像素/秒 |
| 暴击率 | `crit_check` | `crit_chance_percent` | **projectile._roll_crit（D13-T1 补）** | 玩家+武器平加 clamp 0~0.9 |
| 暴伤 | `crit_check` | `crit_damage_percent` | **projectile._roll_crit（D13-T1 补）** | max(player.crit_damage, 1.0)，玩家为权威 |
| 生命 | — | `max_hp` | player.max_health / heal / take_damage | 加算 |
| 护甲 | `armor_reduction` min(armor/(armor+20),0.75) | `armor` | **player.take_damage 平直式** `max(amount-armor,1.0)` | **平直式为权威，formulas 标参考公式**（D13-PRE #4 定案，防平衡崩塌） |
| 吸血 | — | `life_steal_percent` | projectile.apply_life_steal（命中/AOE 共用） | 伤害 × life_steal 回血 |
| 幸运 | `luck_shop`/`luck_chest` | `luck` | player.luck 字段（装配到位） | 影响商店品质/宝箱（框架扩展公式仅登记） |

**说明**：`harvesting / luck_shop / luck_chest / curse_*` 为框架扩展公式仅登记不消费；`melee/ranged/elemental_damage` 三系键（characters.json penalty）收集进 bonus_stats 未消费 —— **见 §6 遗留风险 R4（标 [!] 待 Owner 拍板）**。

### 5.2 暴击结算定案（D13-PRE #1 + D13-T1）

- 结算点 = projectile 弹丸：命中（_on_body_entered）与 AOE（_explode）同口径
- `crit_chance = clampf(player.crit_chance + weapon.crit_chance, 0, 0.9)`；`crit_mult = maxf(player.crit_damage, 1.0)`（weapon.crit_damage 保留登记不叠加）
- 暴击伤害同样走吸血结算；crit=0 零回归（既有武器弹丸不暴击）

### 5.3 被动叠加边界定案（D13-PRE #6）

- **同键乘法叠加**：双 +8% → ×1.1664；remove 用除法精确还原（÷1.08），全移除 → ×1.0（无漂移）

### 5.4 商店池/升级池口径复算（D13-PRE #5）

- 商店池 = 53（33 武器 + 20 被动，脚本实算）；升级池只遍历「已装备且 level<max_level」→ 满级/进化结果天然排除，**无 evolution_result 泄漏**（36 把仅 3 evolution_result 标记）

### 5.5 数值冒烟探针（D13-T5：`tools/day13_build_check.gd`）

**36 项断言 0 失败 → `DAY13 BUILD CHECK CLEAN`（exit 0 / 零 SCRIPT ERROR）**

| 段 | 覆盖 | 结果 |
|---|---|---|
| 1 真实商店 | 池 53 资源实例（33+20）· _refresh_shop 4 卡零 ERROR · 购买链路 | ✅ |
| 2 10 属性 | 消费字段全在 · formulas 关键公式 · STAT_MAP 15 键 · **攻速消费点** | ✅ |
| 3 暴击 | 白盒 crit=1/0 · 命中端到端 · AOE 同口径 | ✅ |
| 4 进化+池 | 3 链交叉引用 · 商店池无泄漏 · evolution_result 恰 3 · 升级池天然排除 | ✅ |
| 5 被动叠加 | 双 +8% → 1.1664 → remove → 1.08 → 1.0 | ✅ |
| 6a 两套统一 | 进局 sync · 装备/卸下/幂等 · 无 source_id 跳过 | ✅ |
| 6b 炮台 | 未装备 3 台临时 · 装备 5 台常驻 · 常驻不消亡/临时到期消亡 | ✅ |

### 5.6 全量回归十件套 + 护栏

| 探针 | 断言 | 结果 |
|---|---|---|
| day2_hero_check / day3_skill_check / day4_level_check / day5_weapon_check / day6_integration_check | 32 / 16 / 21 / 16 / 14 | ✅ 全 0 失败 |
| day7_weapon_data_check / day8_weapon_data_check / day10_evolution_check / day11_12_passive_check / day13_build_check | 13 / 19 / 20 / 22 / 36 | ✅ 全 0 失败 |

`python tools/baseline_check.py` → **BASELINE CLEAN**（import + runtime 双阶段，exit 0 / stderr 0）｜ `gen_weapons_day7.py verify` → **36/36 CLEAN**

---

## §6 遗留风险与主观项

### 遗留风险

| # | 级别 | 描述 | 建议 |
|---|---|---|---|
| R1 | P1 | **攻击力口径（R4）**：player 统一 `damage_percent→damage` 通道实际运作，但 characters.json penalty 三系键（melee/ranged/elemental_damage，如 mage 近战/远程 -100%）收集进 bonus_stats **未消费** | **标 [!] 交 Owner 拍板**：统一攻击力 vs 保留三系 + UI 聚合（影响角色差异化与数值平衡） |
| R2 | P2 | 经验飘字/暴击弹字等 VFX 观感（华丽度）未达 anime 规格 | 归 Day 23 技能特效 / #5 PLAYTEST |
| R3 | P2 | 武器图标观感 / 升级曲线体感（36 把） | #5 PLAYTEST_CHECKLIST 追踪区（H-06 等） |
| R4 | P2 | 探针退出 RID/资源泄漏（W-2 同款）—— 探针实例化未完全 free，非游戏缺陷 | 不阻塞；如需可在探针尾部统一 free |

### 主观项（#5 收集，不阻塞阶段 B 出口）

- 进化爽感 / 陨石特效观感；炮台常驻后的召唤流体感（D13 机制已实装，观感待真人）
- 商店 UI 手感 / 被动搭配趣味 / 价格节奏
- 攻速 buff 生效后的手感变化（此前为静默 bug，现真实生效）
- 暴击反馈（弹字/闪光）是否「爽」

---

*追加条目生成：自动化 #3（方案确定与执行）· 唯一写入文件：`docs/REPORT_PHASE_B.md`（data/*.json 只读）*
