# 《星骸回响》逐日逐人任务总表（Day × Role Assignments）

> 权威规划：`docs/30DAY_PLAN.md` ｜ 每日任务：`docs/TASKS.md` ｜ 分工矩阵：`docs/CONCURRENCY_PLAN.md`
> **本表由【项目进度管理专家】每轮动态调整**：当某工作日出现阻塞/滞后，专家重新切分 W1–W5 任务并回写 `TASKS.md`。
> 护栏：每个开发日结束必须 `python tools/baseline_check.py` → `BASELINE CLEAN`（由 W5 验收）。

## 角色 → 文件域矩阵

| 工作流 | 负责专家 | 独占文件域 | 主要职责 |
|--------|----------|------------|----------|
| W1 玩法代码 | godot-dev | `scripts/` `scenes/` | 场景/UI/技能/武器/Build/肉鸽系统逻辑 |
| W2 数值数据 | GameDesigner | `data/*.json`(战斗/数值) | 平衡数值/成长公式/武器被动/遗物数据 |
| W3 美术资产 | pixel-artist | `assets/sprites/` | 英雄/敌人/Boss 精灵、技能 VFX、音频 |
| W4 剧情文案 | NarrativeDesigner | `data/events.json` + 叙事 doc | 10 事件文本/世界观/角色剧情 |
| W5 QA 测试 | 自动化 | 只读 + `TEST_REPORT.md` | baseline 校验/回归/性能/收口主观项 |

## 逐日任务矩阵

图例：● 主责　◐ 协作　— 无

| Day | 阶段 | 关键交付 | W1 | W2 | W3 | W4 | W5 |
|-----|------|----------|----|----|----|----|----|
| 1 | A | 框架基线 & 差异清单 | ◐核对输入映射 | ●`DIFF_FRAMEWORK_STARECHO.md` | — | — | ●baseline 复验 |
| 2 | A | 角色选择 + 3 英雄 | ●角色选择场景/UI + hero id 消费 | ●绑定起始武器数据 | ●3 英雄精灵 | — | ●baseline |
| 3 | A | 主动技能机制 | ●技能框架+火球/炮台/爆发+HUD | ◐补 `burn_duration` | — | — | ●baseline + `day3_skill_check` |
| 4 | A | 经验/升级/Build 初版 | ●XP/升级/强化面板/炮台(承接D3-T4) | ●10 属性强化口径重写 | — | — | ●baseline + `day4_level_check` |
| 5 | A | 武器 6 槽挂载 | ●6 槽上限 + 查表升级 + 混合选项池 + 环绕武器 | ◐核验签名武器 levels 表 | — | — | ●baseline + `day5_weapon_check` |
| 6 | A | 阶段 A 集成测试 | ●集成 | ●平衡初调 | — | — | ●全量 baseline + 手感冒烟 + 报告 |
| 7–9 | B | 33 武器数据 + 精灵（D7 MVP15 已收口，D8-9 补全 18） | ◐装配消费(已通)+探针 | ●33 把 Lv1-8 levels 数据 + 曲线 | ●33 帧武器图标实绘 | — | ●每日 baseline + 回归六件套 |
| 10 | B | 武器进化 | ●进化机制（替换/进化池/背包装配/探针） | ●3 结果武器 + se_blade_core 数据 | ◐结果武器图标 3 帧 | — | ●baseline + 回归七件套 |
| 11–12 | B | 20 被动 + 商店体系 | ●6 被动槽 + 装配 + 商店 | ●20 被动数据(白名单) | ◐items.png 4→20 帧 | — | ●baseline + 探针 + 回归八件套 |
| 13 | B | Build 集成 + 数值冒烟 | ●暴击结算+两套统一+炮台常驻+探针 | ●10 属性公式对照+口径定案 | — | — | ●回归十件套+阶段 B 报告 |
| 14–15 | C | 随机节点地图 | ●路线生成器 + 路线模式集成 + 选择面板 + 探针 | ◐`routes.json` 拓扑参数 | — | — | ●baseline + 回归十件套 |
| 16 | C | 事件节点 | ●事件弹窗+结算+改线+探针 | ◐`resonant_shard` 数据+回归同步 | — | ●10 文本事件(已预交付) | ●baseline + 回归十一件套 |
| 17 | C | 精英战斗 | ●精英能力+池解析+难度消费+探针 | ◐`ability` 字段 | — | — | ●baseline + 回归十一件套 |
| 18–19 | C | Boss 多阶段（phases 状态机 + attacks 指令映射） | ●阶段状态机+指令解析+敌人弹丸+接入+探针 | ◐核验 Boss phases 数据（只读） | —（精灵归 21-22） | — | ●baseline + 回归十二件套 |
| 20 | C | 遗物 + 阶段 C 回归 | ●遗物装配键+上限+商店第三池+探针+SkillSlot 接线 | ●2 遗物数据 + 回归同步 | ◐items.png 20→22 帧 + **技能图标 4 枚(skills.png)** | — | ●回归十五件套 + 阶段 C 报告 |
| 21–22 | D | 美术资产落地 | ●精灵接线(SPRITE_MAP/scale复位/动画)+探针+F 系列 P1 | ◐核验 | ●英雄/敌人/Boss 二次元像素精灵+walk/attack strip+阵营/背景 | — | ●baseline + 回归全套 |
| 23 | D | 华丽技能特效 | ●消费点接线+hit激活+探针 | — | ●VFX PNG 5 枚(火球/部署/爆发/陨石/护盾) | — | ●baseline + 回归全套 |
| 24 | D | 音频接入 | ●AudioManager 骨架 + 状态机 + SFX 接线 + 探针 | — | ●BGM/SFX 资源生成（`gen_audio.py`） | — | ●baseline + 回归全套 |
| 25 | D | 剧情文本 | — | — | — | ●世界观 + 10 事件 + 角色剧情 | ●baseline |
| 26 | D | 整合校验 | ●探针+接线抽查 | ◐收口清单核对（只读） | ◐资产核验 | ◐剧情载体核验 | ●baseline + REPORT_PHASE_D |
| 27 | E | 局外养成 | ●存档+研究+培养+剧情解锁接线 | ●角色培养数据(story/unlock_level) | ◐基地占位主题(P1) | ◐LORE.md 提炼核验 | ●baseline + day27 探针 + 回归全套 |
| 28 | E | **F-31 武器升级体系（P0 用户拍板）+ 全量测试/性能** | ●F-31（DataLoader 起始武器集合 + 商店池排除 + 升级面板移除武器升级 + 铁砧闭环/升级选择 UI + 回归同步 + 探针） | ◐只读核验（10 把起始武器交叉命中 + anvil 数据就绪） | ◐anvil 图标占位复用现有帧（P1 可延） | — | ●自动化测试 + 性能 + `TEST_REPORT.md` + baseline + day28_f31 探针 |
| 29 | E | 人工试玩 + 修复 | ◐修复 | ◐平衡修复 | ◐素材修复 | ◐文本修复 | ●回归 baseline |
| 30 | E | 发布准备 | ●`build_release --zip` | — | — | — | ●导出校验 |

## 备注

- **Day 2 延续项**：`Main` 侧消费 hero id（初始武器/被动/精灵接入 `Player`/`WeaponController`）——W1 主责，W2 配数据，属 Day 2 交付的自然延伸。
- **Day 2 切分细化（2026-08-05 04:35 · #2 重排）**：Day 2 数据侧已由 08-04 冲刺预交付，剩余全部为代码侧消费链路，故本日重心从「W2 数据」上移至「W1 代码」——
  - W1（●加重）：`D2-T1a` 取 id+兜底 · `D2-T1b` 起始武器注入 · `D2-T1c` 被动/惩罚注入 · `D2-T4` 玩家精灵切换 · `D2-T2` 中 `character_select.gd` 去硬编码
  - W2（◐减轻）：仅 `D2-T2` 的 `characters.json` 补 9× `sprite` 前缀字段（单文件、无跨域）
  - W3（◐）：`D2-T3` 为环境项 `[!]`，编辑器打开即消解，**不计入本日出口**，顺延 Day 21–22 统一验收
  - W5（●）：`D2-EXIT` 由「人工三英雄进局」改为**无头 meta 注入冒烟**，保证客观可验、不卡人工
  - 文件域校验：W1 只写 `scripts/`、W2 只写 `data/characters.json`，**无跨域写冲突**
- **Day 3 切分细化（2026-08-05 06:35 · #2 重排）**：Day 3 为**近乎纯代码日**，W2/W3/W4 产能极低，故本日 W1 承担 6 项中的 5 项——
  - W1（●重载）：`D3-T1` 技能控制器骨架（新建 `skill_controller.gd` + `Player.tscn` 加节点）· `D3-T2` `projectile.gd` 扩展爆炸/元素 · `D3-T3` 艾琳火球 · `D3-T4` 诺亚炮台（新建 `turret.gd`+`Turret.tscn`）· `D3-T5` 莱恩 buff · `D3-T6` HUD 冷却条（P1）
  - W2（◐轻）：仅 `D3-T7` —— `characters.json` 给 `se_irene.skill` 补 `burn_duration: 4.0`（该数值当前只存在于 `description` 文本，代码读不到，是真实缺口）
  - W3（—）：技能专属 VFX **不在本日**，复用现有 `crit`/`hit` 占位，专属特效归 Day 23；炮台占位图走运行时绘制（对齐 `projectile.gd` 范式），真精灵登记 Day 21–22
  - W5（●）：`D3-EXIT` = `baseline_check` + 新建 `tools/day3_skill_check.gd`（6 类断言）+ **回归 `day2_hero_check.gd`**（防 `projectile.gd` 改动波及既有武器）
  - 文件域校验：W1 只写 `scripts/` `scenes/`、W2 只写 `data/characters.json`，**无跨域写冲突**
  - ⚠️ 已知可见性边界：莱恩「+3 环绕刃」本日仅埋点进 `bonus_stats`，**环绕刃渲染属 Day 5 武器挂载**，W5 验收不得以「看不到刃」判失败
- **Day 4 切分细化（2026-08-05 19:08 · #2 第 4 轮预拆解）**：Day 4 = 承接 Day 3 顺延项（`D3-T4` 炮台 / `D3-T6` HUD 冷却）+ 经验/升级/Build 初版本体，W1 仍为主力——
  - W1（●）：`D4-T1` 经验获取与升级核心（`enemy._drop_rewards` 补 `exp_value` 消费 + `player.gain_exp/_check_level_up` + GameManager 暂停）· `D4-T3` 吸血属性通道（大纲 10 属性补齐）· `D4-T4` LevelUpPanel 三选一强化 UI（新建场景+脚本）· `D4-T5` 承接炮台实体（`turret.gd`+`Turret.tscn`，Day 3 顺延断言 3 在此收口）· `D4-T6` HUD 冷却指示（P1）
  - W2（◐轻）：仅 `D4-T2` —— 重写 `stats.json.leveling.upgrade_options` 为大纲 10 属性档（现为框架旧口径 melee/ranged/elemental 三系 + dodge/harvesting/engineering，与 `apply_stat_modifier` 实际支持键不符）
  - W3（—）：炮台占位图走运行时绘制，真精灵归 Day 21–22；VFX 归 Day 23
  - W5（●）：`D4-EXIT` = `baseline_check` + 新建 `tools/day4_level_check.gd`（8 类断言，含炮台数 == 3 收口）+ 回归 `day3_skill_check` / `day2_hero_check`
  - 关键决策（已在 TASKS.md Day 4 定案表）：经验直接结算不造宝石实体｜经验曲线用 `Expression` 解析 `stats.json` 字符串｜升级暂停游戏（`paused=true` + `PROCESS_MODE_WHEN_PAUSED` 面板）｜range 口径统一走倍率通道｜吸血为 10 属性唯一新增通道
  - 文件域校验：W1 只写 `scripts/` `scenes/`、W2 只写 `data/stats.json`，**无跨域写冲突**
- **Day 5 切分细化（2026-08-05 23:1x · #2 第 6 轮）**：Day 5 = 武器 6 槽挂载（W1 近乎纯代码日；W2 退为核验）——
  - W1（●重载）：`D5-T1` 6 槽上限 + 装备管理（`equip_weapon` 返回 bool + `MAX_SLOTS=6`）· `D5-T2` 武器 Lv1-8 升级机制（`_on_upgrade` 改 `levels[]` 查表，表空回退通用成长；`build_weapon_from_data` 补 `level_table/orbit_data` + max_level 防短表）· `D5-T3` 升级入口（LevelUpPanel 混合选项池：属性 + 武器升级）· `D5-T4` 环绕武器机制（新建 `orbit_weapon.gd` 挂 Player 子节点，WeaponController 分流跳过弹丸发射，**消费 `bonus_stats.orbit_blade_count` = Day 3 埋点收口**）
  - W2（◐轻）：仅 `D5-T5` —— 核验 3 把签名武器 `max_level==8` + `levels` 8 条（`se_star_blade` 已实测 8/8）；**不批量给旧武器补 levels**（归 Day 7-9）
  - W3（—）：环绕刃占位图运行时绘制（Polygon2D），真精灵登记 Day 21-22 美术债
  - W5（●）：`D5-EXIT` = `baseline_check` + 新建 `tools/day5_weapon_check.gd`（7 类断言，含 D3 埋点收口断言 5）+ 回归三件套（`day4_level_check` 21/0 **注意 D5-T3 的注入式改造联动** + `day3_skill_check` 16/0 + `day2_hero_check` 32/0）
  - 关键决策（已在 TASKS.md Day 5 定案表）：6 槽满则拒（替换 UI 归 Day 11-12）｜升级查表优先（`levels[level-1]` 绝对覆盖）｜max_level 取表长与字段最大值｜升级入口 = LevelUpPanel 混合池｜环绕接触伤害用容器遍历禁物理查询｜刃数 = `orbit_data.blade_count + bonus_stats.orbit_blade_count`
  - 文件域校验：W1 只写 `scripts/` `scenes/`、W2 只写 `data/weapons.json`（核验），**无跨域写冲突**
- **Day 6 切分细化（2026-08-06 01:1x · #2 第 7 轮）**：Day 6 = 阶段 A 集成测试 + 平衡初调 + 阶段 A 报告，**优先纳入 T-A 经验链路**（#1 第 8 轮建议 + PLAYTEST 追踪区 T-A 双指针）——
  - W1（●集成）：`D6-T2` 消费 `exp_value`（`get_scaled_enemy()` 返回值补键 + `enemy.initialize()` 读取，T-A-2）· `D6-T3` 端到端集成探针（新建 `tools/day6_integration_check.gd`，T-A-3，≥12 断言覆盖选角→进局→击杀→升级→技能→6槽→死亡重开全链路）· `D6-T4` T-B 经验可见性（**P1 顺延项**，三选一最小闭环，可顺延 Day 7 首段）
  - W2（●平衡初调）：`D6-T1` `enemies.json` 23 敌补 `exp_value`（T-A-1，首升目标 = wave1 打满升 1 级）· `D6-T5` 平衡对照表（敌人 scaling vs 玩家 DPS / Boss 数值 / penalty 后基准；**只动数值字段，公式不改**，全部改动附依据禁臆造）
  - W5（●全量回归 + 报告）：`D6-T6` 回归四件套（day2 32 / day3 16 / day4 21 / day5 15）+ 新建 `docs/REPORT_PHASE_A.md`（§1 六日回顾 / §2 集成结论 / §3 平衡对照表 / §4 遗留风险）——**不写 PROGRESS.md**（#1 独占追加，防双写冲突）
  - 关键决策（已在 TASKS.md Day 6 定案表）：exp_value 数据落点 = enemies.json → get_scaled_enemy → initialize｜首升配比目标 wave1 结束前升 1 级｜阶段 A 报告独立成文｜手感冒烟为主观项不阻塞出口｜T-C/T-D 不进本日
  - 文件域校验：W1 写 `scripts/` + `tools/`（探针）、W2 写 `data/enemies.json`/`weapons.json`/`waves.json`（数值）、W5 写 `docs/REPORT_PHASE_A.md` + `TEST_REPORT.md`，**无跨域写冲突**
- **Day 7 切分细化（2026-08-06 03:1x · #2 第 8 轮）**：Day 7 = 阶段 B 首段（MVP 15 武器数据 + 装配消费 + 图标集），矩阵原「W1 ◐」上调为「W1 ●装配消费」，W3 从「◐」升为「●图标扩容」，W4 无职责——
  - W1（●装配消费 + 探针）：`D7-T2` 装配消费补齐（`weapon.gd` 补 `crit_chance/crit_damage` 字段 + `build_weapon_from_data` 消费 `crit_chance/crit_damage/pierce/icon_index` + `_on_upgrade` 兼容 crit/pierce 键）· `D7-T4` IconAtlas 帧数 4→40 + HUD 越界验证 · `D7-T6` 新建 `tools/day7_weapon_data_check.gd`（≥10 断言：JSON 层 15 把 levels 齐 + 装配层消费生效 + 图标层不越界 + 签名武器回归）
  - W2（●数据补全）：`D7-T1` 11 把通用武器补 `levels` 8 条 + `max_level:8`（sword/chainsaw/pistol/smg/shotgun/sniper/wand/icicle/flamethrower/turret/landmine，字段集 `{level, damage, cooldown, range, projectiles?, upgrade}`，Lv1 与顶层一致）· `D7-T5` 33 把补 `icon_index`（melee 0-7 / ranged 8-16 / elemental 17-25 / engineering 26-32）
  - W3（●图标扩容）：`D7-T3` `weapons.png` 4 帧→40 帧（1280×32，15 帧实绘 + 25 帧分类色占位，ART_STYLE v2 32px 图标基准）
  - W5（●回归）：`D7-EXIT` baseline + `day7_weapon_data_check` + 回归五件套（day2/3/4/5 + day6 14 断言）
  - 关键决策（已在 TASKS.md Day 7 定案表）：MVP 15 武器清单（4 已备 + 11 补）｜levels 字段集只放 weapon.gd 会消费的键｜levels 成长规范（Lv1==顶层 / damage ×1.2-1.35 / 参照签名曲线）｜召唤类 summon_count/duration 成长归 Day 13｜升级池范围统一归 Day 13
  - 文件域校验：W1 写 `scripts/` + `tools/`、W2 只写 `data/weapons.json`、W3 只写 `assets/sprites/ui/weapons.png`，**无跨域写冲突**
- **Day 8-9 切分细化（2026-08-06 05:1x · #2 第 9 轮）**：Day 7 已收口（`fc2a636`，MVP 15 levels + 40 帧图标），本区间 = **18 把全量补全 + 图标实绘 + 全量回归**，纯数据/美术/探针日（装配代码 D7-T2 已铺路，零代码改动）——
  - W1（◐探针）：`D8-T3` 新建 `tools/day8_weapon_data_check.gd`（≥13 断言：JSON 全量 33 把 + force_field/minigun 特例 + 装配抽查 3 把 + 图标 18 帧非透明 + 回归 day7 15 把）；**day7 探针不动**（历史锚点 13/13）
  - W2（●数据）：`D8-T1` 扩展 `tools/gen_weapons_day7.py` LEVELS 表 +18 把（fist/stick/dagger/hammer/flaming_knuckles/slingshot/crossbow/rocket_launcher/minigun/lightning_shiv/venom_staff/storm_staff/frost_nova/plasma_cannon/wrench/laser_turret/mech_arm/force_field），幂等 apply + verify 覆盖 33/33；levels 字段集 `{level, damage, cooldown, range, upgrade}` 5 键；force_field damage 恒 0 特例
  - W3（●美术）：`D8-T2` 扩展 `tools/gen_weapon_icons.py` 18 帧占位替换实绘（idx 0/1/2/4/6/9/10/14/15/19/21/22/23/24/28/29/30/31），细节 ≥2-3 色阶（PLAYTEST D7 偏简 backlog）；**不动已收口 15 帧**；预览图放大 4 倍查整体再 commit
  - W5（●回归）：`D8-EXIT` baseline + `day8_weapon_data_check` + 回归六件套（day2 32 / day3 16 / day4 21 / day5 16 / day6 14 / day7 13）
  - 关键决策（已在 TASKS.md Day 8-9 定案表）：18 把清单修正（原「14 把」文字矛盾）｜levels 无 projectiles 键（顶层均无）｜Lv8 建议目标表（W2 照此生成可微调）｜工具扩展而非新建（防双源漂移）｜回归六件套口径
  - 文件域校验：W1 写 `tools/`、W2 写 `data/weapons.json` + `tools/gen_weapons_day7.py`、W3 写 `assets/sprites/ui/weapons.png` + `tools/gen_weapon_icons.py`，**无跨域写冲突**
- **Day 11-12 切分细化（2026-08-06 09:1x · #2 第 11 轮）**：Day 10 已收口（`ca7c0a2`），本区间 = **20 被动 + 6 被动槽 + 商店真实商品闭环**（矩阵原「W1 ●6 被动槽装配 / W2 ●4 类 20 被动数据」细化，W3 由「—」升为「◐图标扩容」）——
  - W1（●重载）：`D11-12-T2` 6 被动槽（`inventory.MAX_ITEMS` 20→6 + `hud.gd` item_slots 4→6 + HUD.tscn ItemBar 加 ItemSlot4/5）· `D11-12-T3` 被动装配链路（`player.gd` 加 `apply_item_bonuses(item, remove)` 复用 STAT_MAP 三档 + STAT_MAP 扩展 `crit_damage_percent` + GameManager/Main 监听 `inventory.item_added/item_removed` 应用/回退）· `D11-12-T4` 商店真实商品（`shop.gd` `_refresh_shop` 从武器 33 池 + 被动 20 池随机 4 卡 + `_purchase_item` 先 add 后扣费闭环；build 建议提静态工厂防双源）· `D11-12-T5` `replace_weapon` 补 sync inventory（进化后 HUD 显示结果武器）· `D11-12-T7` 新建 `tools/day11_12_passive_check.gd`（≥16 断言：数据/槽位/装配/商店/回归五段）
  - W2（●数据）：`D11-12-PRE` 20 被动清单定案（从现有 48 项筛 20 项，3 进化核心必选，四类划分建议表）· `D11-12-T1` items.json 落地（20 项加 `is_passive/slot/category/icon_index` 四字段 + 17 常规项 effects 白名单化 + 3 核心禁键占位登记）
  - W3（◐图标）：`D11-12-T6` items.png 4→20 帧实绘（新建 `tools/gen_item_icons.py` 仿 gen_weapon_icons 范式，帧序对齐 icon_index 0-19）+ W1 协作 `icon_atlas.gd` items frame_count 4→20
  - W5（●回归）：`D11-12-EXIT` baseline + `day11_12_passive_check` + 回归八件套（day2 32 / day3 16 / day4 21 / day5 16 / day6 14 / day7 13 / day8 19 / day10 20）
  - 关键决策（已在 TASKS.md Day 11-12 定案表）：20 被动 = 现有 48 项筛选（不臆造新条目）｜被动效果键白名单化（禁框架旧口径键，杜绝静默失效；裸 range → range_percent 200px 基准）｜3 进化核心例外（effects 禁键仅占位登记，核心价值在 evolution）｜6 被动槽 = inventory MAX_ITEMS 20→6 + HUD ItemBar 4→6｜被动只从商店获取（不进升级选项池）｜装配 = GameManager 监听 inventory 信号 → player.apply_item_bonuses（remove 走负值同入口）｜商店先 add 成功再扣费（槽满/钱不够拒绝）｜武器购买双写（inventory + equipped_weapons）+ replace 补 sync inventory（两套完整统一归 Day 13）｜se_turret_array 常驻机制仍归 Day 13
  - 文件域校验：W1 写 `scripts/` + `scenes/HUD.tscn` + `tools/`、W2 写 `data/items.json`、W3 写 `assets/sprites/ui/items.png` + `tools/gen_item_icons.py`，**无跨域写冲突**
- **Day 13 切分细化（2026-08-06 13:1x · #2 第 13 轮）**：Day 11-12 已收口（`4bc79df` + 回执 `d631e7b`），本日 = **Build 系统集成 + 数值冒烟（阶段 B 收口）**，矩阵原「W1 ●10 属性公式校验 / W2 ●进化/被动叠加边界」细化，本轮实测新发现 3 个集成缺口（暴击零结算 / 进局不同步 / 护甲口径冲突）——
  - W1（●重载）：`D13-T1` 暴击结算点补全（projectile.gd 增 crit_chance/crit_mult + 命中/爆炸结算 + _spawn_projectile 聚合玩家+武器暴击）· `D13-T2` 武器两套体系统一入口（weapon_controller 增 `sync_inventory_weapons()` + main.gd 进局起始武器 sync + equip/unequip 补 sync）· `D13-T3` se_turret_array 炮台常驻/多台（turret.gd duration<=0 常驻 + skill_controller 装备检测 +2 台）· `D13-T5` 新建 `tools/day13_build_check.gd`（≥20 断言六段含真实进商店）· `D13-T6` **BUG-002（P1）** shop.gd `_build_shop_pool` 改返回资源实例（武器 build_weapon_from_data / 被动 Item.new 填四字段），真实商店 4 卡可用
  - W2（●定案）：`D13-T4` 10 属性公式对照表（大纲 10 属性 ↔ formulas(15) ↔ STAT_MAP(15 键) ↔ 消费点）+ 护甲口径定案（沿用 player 平直式，formulas 标参考）+ 3 进化链交叉引用 + 商店池 53 复算 + **R4 攻击力口径登记标 [!] 交 Owner**——**data/*.json 只读**，产出写 docs/
  - W3（—）：美术资产归 Day 21-22，特效归 Day 23，本日无职责
  - W5（●收口）：`D13-EXIT` baseline + `day13_build_check` + **回归十件套**（day2 32 / day3 16 / day4 21 / day5 16 / day6 14 / day7 13 / day8 19 / day10 20 / day11_12 22 / day13）+ `gen_weapons_day7 verify` 36/36 + 产出 `docs/REPORT_PHASE_B.md`（§1 阶段 B 回顾 / §2 武器 36 把+DPS / §3 进化 3 链 / §4 被动 20+6 槽+商店 53 / §5 数值冒烟结论 / §6 遗留风险）+ git commit（勿夹带 pindou/、level_up_panel.gd.bak、pixel_to_pindou.py，W3 自主提交）
  - 关键决策（已在 TASKS.md Day 13 定案表）：暴击结算点 = projectile（玩家 crit 为权威，武器 crit 加成 clamp 0.9）｜权威源 = inventory.weapons（统一 sync 入口）｜se_turret_array 常驻 +2 台｜护甲沿用平直式（formulas 标参考）｜商店池 53（修正「30 可购」笔误）｜被动叠加同键乘法 + 除法还原｜BUG-002 商店池改资源实例（真实 4 卡）｜R4 攻击力口径 [!] 交 Owner 不阻塞
  - 文件域校验：W1 写 `scripts/` + `tools/`、W2 写 `docs/`（只读 data/）、W5 写 `docs/REPORT_PHASE_B.md`，**无跨域写冲突**
- **Day 14-15 切分细化（2026-08-06 15:1x · #2 第 14 轮）**：Day 13 已收口（`a082457`），本区间 = **随机节点地图（阶段 C 首段）**——矩阵原「W1 ●节点拓扑 + 种子 RNG / W2 — / W5 ●baseline」细化，W2 由「—」上调为「◐拓扑参数数据」——
  - W1（●重载）：`D14-15-T1` 新建 `scripts/systems/route_generator.gd`（`static generate(seed)`：RNG 实例种子可复现，层式分支拓扑 5 层×3 节点末层 Boss，`_weighted_pick` 禁 Array.shuffle，战斗序号→wave 映射 ≤19，modifiers/flags 事件改写预留）· `D14-15-T3` GameManager 路线模式（GameState +ROUTE_SELECT；`route`/`route_enabled`；`_start_next_wave(wave_number=-1)` 指定波次；on_wave_cleared/close_shop 按 route 分派；`_clear_remaining_enemies` 保留首行；DataLoader 补 `get_routes()` 3 行）· `D14-15-T4` 新建 `scenes/RouteSelectPanel.tscn` + `scripts/ui/route_select_panel.gd`（CanvasLayer + 动态按钮，仿 ShopPanel 范式）· `D14-15-T5` 新建 `tools/day14_15_route_check.gd`（≥20 断言六段）
  - W2（◐数据）：`D14-15-T2` 新建 `data/routes.json`（layers/nodes_per_layer/default_seed/weights/constraints，仿 waves.json 参数表）
  - W3（—）：节点图标美术归 Day 21-23（本日类型色块/文本）；W4（—）：事件逻辑归 Day 16（events.json 已预交付）
  - W5（●收口）：`D14-15-EXIT` baseline + `day14_15_route_check` + **回归十件套**（day6 探针注入 `route_enabled=false` 同步更新 1-2 行，其余断言不动）+ git commit（勿夹带 pindou/、level_up_panel.gd.bak、pixel_to_pindou.py、LOOP_HEALTH.md）
  - 关键决策（已在 TASKS.md Day 14-15 定案表）：节点类型 5 类｜层式分支拓扑（每层 3 选 1，末层 Boss）｜种子可复现（RNG 实例，禁全局 RNG 洗牌）｜节点→波次映射（战斗类按战斗序号→wave n，waves.json 6-19 天然含 elite；boss→20；战斗类 ≤19 硬约束）｜**模式兼容 route 空=旧波次制**（回归零破坏，day4/day6 锚点保护）｜事件改写预留 modifiers/flags（消费归 Day 16）｜event/elite/boss 交互归后续日，W5 不得判失败
  - 文件域校验：W1 写 `scripts/` + `scenes/` + `tools/`、W2 只写 `data/routes.json`、W5 只读 + `TEST_REPORT.md`，**无跨域写冲突**
- **Day 16 切分细化（2026-08-06 17:1x · #2 第 15 轮预拆）**：Day 14-15 实现已 100% 落地（待 EXIT 收口，git 仍停 `a082457`）→ 预拆 Day 16 = **事件节点系统**（阶段 C 第二节）——数据已由 08-04 冲刺预交付（events.json 10 事件），`scripts/` 全域零事件消费方，纯代码日 + 1 条数据补齐——
  - W1（●重载）：`D16-T1` 新建 `scenes/EventSelectPanel.tscn` + `scripts/ui/event_select_panel.gd`（**暂停式**弹窗，仿 LevelUpPanel：CanvasLayer + NinePatchRect + 长文本 autowrap + 2 选项按钮 + game_over 防悬挂）· `D16-T2` GameManager 事件接入（`_enter_node(event)` 占位 → `_start_event` 随机取事件 + `resolve_event_choice` + `_apply_event_reward` **10 型分派**（attack_speed_percent/max_hp/gold/item/weapon_upgrade/luck/attack_percent→damage 别名/heal_percent/trade 复合/level_up）+ `_apply_route_effect` **5 型改线**（reroute/flag/unlock_node/add_node/difficulty）+ `_event_rng` RNG 实例 + DataLoader `get_events()`）· `D16-T3` route_generator 扩展改线静态方法（`reroute_remaining` 未访问层重抽 + `force_node_type` 单点强制，RNG 实例禁 Array.shuffle）· `D16-T5` 新建 `tools/day16_event_check.gd`（≥18 断言五段）
  - W2（◐轻）：`D16-T4` items.json +1 条 `resonant_shard`（共鸣碎晶，effects={crit_damage_percent:25}，tags=[relic]，**不设 is_passive** 不入被动/商店池）+ **回归同步** day11_12 探针 items 总项数 48→49（20 被动/icon 0-19 断言不动）
  - W3（—）：items.png 第 21 帧实绘 = `[!]` 美术项（归 Day 21-22，icon_atlas 越界兜底帧 0 不阻塞）；W4（—）：10 文本事件已预交付，仅核验
  - W5（●收口）：`D16-EXIT` baseline + `day16_event_check` + **回归十一件套**（+day14_15）+ git commit（勿夹带 pindou/、.bak、pixel_to_pindou.py、LOOP_HEALTH.md）
  - 关键决策（已在 TASKS.md Day 16 定案表）：事件弹窗暂停式（阅读+抉择）｜事件随机绑定（零 route_generator 改动，肉鸽可重复）｜attack_percent/max_hp_percent 代码层别名禁改 STAT_MAP（防 D4/D11-12 探针波及）｜item 直装 apply_item_bonuses（获得即生效不占 6 槽，遗物语义归 Day 20）｜reroute/flag/difficulty 深消费（商店折扣/Boss 护盾/强度档）登记后归 Day 17/20/25，W5 不得判失败｜随机性一律 `_event_rng` 实例（禁全局 RNG）
  - 文件域校验：W1 写 `scripts/` + `scenes/` + `tools/`、W2 只写 `data/items.json`，**无跨域写冲突**
- **Day 17 切分细化（2026-08-06 19:1x · #2 第 16 轮预拆）**：Day 14-15 已收口（`fa077e0`）→ 预拆 Day 17 = **精英战斗**（阶段 C 第三节）——waves.json 6-19 天然含 elite 前缀（精英节点/波次映射零数据改动），6 精英 = 3 只既有行为（rhino charge / colossus+croc chase）+ 3 只新能力（butcher AOE / monk 自愈 / mom 产卵）——
  - W1（●重载）：`D17-T2` enemy.gd 精英能力消费（`AOE_ATTACK`/`SELF_HEAL`/`SPAWN` 三行为真实实现：周期 AOE 距离判断禁物理查询 / 低血自愈 / 产卵 count 只 minion 同波缩放 `wave_number`；VfxPlayer 复用 crit/levelup）· `D17-T3` **BUG-003（P1）mixed 池令牌解析收口**（spawner `_create_enemy` 支持 `mixed`→regular 池 / `elite:mixed`→elite 池 / `mixed_with_curse`→regular 池，`_rng` 实例可注 seed，wave 15/17/19 此前全部静默不生成）· `D17-T4` difficulty_delta 消费（`route.flags["difficulty_delta"]` → 敌人 hp/damage ×(1+0.1×档)，Day 16 事件登记收口）+ 精英节点横幅提示 · `D17-T5` 新建 `tools/day17_elite_check.gd`（≥18 断言五段）
  - W2（◐轻）：`D17-T1` enemies.json 6 精英中 3 只补 `ability` 字段（butcher aoe / monk self_heal / mom spawn，数据驱动仿 burn_duration 先例；colossus/rhino/croc 缺省无能力不臆造）
  - W3（—）：精英专属精灵归 Day 21-22、VFX 归 Day 23（本日 modulate 区分色 + 横幅）；W4（—）：无职责
  - W5（●收口）：`D17-EXIT` baseline + `day17_elite_check` + **回归十一件套**（+day16 若已收口）+ git commit（勿夹带 pindou/、.bak、pixel_to_pindou.py、LOOP_HEALTH.md）
  - 关键决策（已在 TASKS.md Day 17 定案表）：精英 = 强化属性（scaling 已消费）+ 特殊能力（3 新实现）｜ability 数据驱动缺省即无能力｜**BUG-003 mixed 池 spawner 解析**（waves.json 池令牌保留，非数据展开，防断言波及）｜difficulty_delta ±10%/档｜产卵同波缩放（wave_number 注入）｜无头稳禁物理查询｜Boss phases 归 Day 18-19、curse 效果不臆造，W5 不得判失败
  - 文件域校验：W1 写 `scripts/` + `tools/`、W2 只写 `data/enemies.json`，**无跨域写冲突**
- **Day 18-19 切分细化（2026-08-06 21:1x · #2 第 17 轮预拆）**：Day 16 已收口（`ee7603b`/`748d2b7`）→ 预拆 Day 18-19 = **Boss 多阶段（phases 状态机 + attacks 指令映射）**（阶段 C 第四节）——数据层**零改动**（enemies.json boss[2] 的 phases/attacks/exp_value 已完备，get_scaled_enemy 12 键 phases 透传 ✅），纯代码日——
  - W1（●重载）：`D18-19-T1` enemy.gd Boss phases 状态机（`phases` 消费 + `_current_phase_idx` + `take_damage` 尾部阈值检查 → 切阶段：重置攻击计时器 + `move_speed = _base_speed × speed_multiplier` + 阶段横幅）· `D18-19-T2` attacks 字符串指令解析器（summon_N_enemies_every_Xs / N_projectile_spread / aoe_every_Xs / charge_attack(_2x) / projectile_barrage / summon_N_elite / all_attacks_2x → {kind, interval, params} + 行为执行器：召唤池随机 / N 向弹幕 / 周期 AOE / 冲锋模式 / 弹幕 8×3 / 修饰符 _attack_mult）· `D18-19-T3` 新建 `scripts/enemy/enemy_projectile.gd`（敌人弹幕独立弹丸，Node2D 纯代码 + 距离判断命中玩家，**player projectile.gd 零改动**）· `D18-19-T4` GameManager Boss 接入（boss 节点横幅 + `boss_killed`/`route.flags["boss_defeated"]` 登记，深消费归 Day 27）· `D18-19-T5` 新建 `tools/day18_19_boss_check.gd`（≥20 断言五段）
  - W2（◐核验·只读）：Boss phases 数据完整性核验（invoker 2 阶段 / predator 3 阶段 / hp_threshold_percent 单调递减 / attacks 可解析 / exp_value 齐）——**data/*.json 零改动**（数据已完备，不臆造新指令）
  - W3（—）：Boss 专属精灵归 Day 21-22（本日 scale ×2 过渡 + 阶段横幅）、Boss VFX 归 Day 23；W4（—）：无职责
  - W5（●收口）：`D18-19-EXIT` baseline + `day18_19_boss_check` + **回归十二件套**（day2 32 / day3 16 / day4 21 / day5 16 / day6 14 / day7 13 / day8 19 / day10 20 / day11_12 22 / day13 36 / day14_15 53 / day16 41）+ day17（若收口）+ verify 36/36 + git commit（勿夹带 pindou/、.bak、pixel_to_pindou.py、LOOP_HEALTH.md）
  - 关键决策（已在 TASKS.md Day 18-19 定案表）：**大纲「腐化巨树藤蔓/毒雨」vs 数据 invoker/predator phases 差异 → 以数据为准**（希亚先例：数据先行、大纲为方向）｜指令解析规则（every_Xs 周期 / 无 every 发射类默认 4s / charge 状态置位 / summon_elite 一次性 / all_attacks_2x 阶段修饰符）｜敌人弹幕独立弹丸禁复用玩家 projectile｜路线模式末层 boss 恒 wave20=predator（invoker 仅旧模式，两 Boss 均实现）｜「森林区域解锁」最小落地 = boss_killed 登记，深消费归 Day 27｜无头稳禁物理查询｜W5 不得以「藤蔓/毒雨缺失」「区域未解锁」判失败
  - 文件域校验：W1 写 `scripts/` + `tools/`、W2 只读 `data/enemies.json`（核验产出写 docs/），**无跨域写冲突**
- **Day 20 切分细化（2026-08-06 23:1x · #2 第 18 轮预拆）**：Day 17（`2abba3c`）+ Day 17-P0（`6e84751`/`1bc0255`）已收口 → 预拆 Day 20 = **遗物系统 + 阶段 C 回归（阶段 C 收口）**——矩阵原「W1 ●遗物逻辑 / W2 ●遗物数据 / W5 ●回归+报告」细化，W3 由「—」升「◐图标扩容」——
  - W1（●重载）：`D20-T2` player.gd 2 新装配键（**damage_taken_percent** 受伤倍率：take_damage armor 平直减伤后乘、debug_cheat 最后兜底 / **structure_damage_percent** 结构伤害：STAT_MAP 注册 + `structure_damage_mult`，**turret.gd:89-94 补消费点顺带激活 se_mech_core/mech_heart 悬空词条**）· `D20-T3` inventory 遗物上限（`MAX_RELICS=2` + `get_relic_count()` + `add_item_from_data` slot=="relic" 分支直装不占被动槽，6 被动+2 遗物共存）· `D20-T4` shop.gd 第三池（slot=="relic" 且 price>0 → 池 53→55，resonant_shard price 0 事件专属保持）+ **回归同步 day13 探针 53→55** · `D20-T6` 新建 `tools/day20_relic_check.gd`（≥18 断言五段）
  - W2（●数据）：`D20-T1` items.json 49→51 +2 遗物（**破碎王冠 broken_crown** `{damage_percent:50, damage_taken_percent:30}` / **机械引擎 mech_engine** `{structure_damage_percent:100}`，各带 slot:"relic" + icon_index 20/21；**⚠️ 大纲「机械核心」与 se_mech_core 进化核心重名 → 改名「机械引擎」**；不设 is_passive → 被动 20 断言零波及）
  - W3（◐轻）：`D20-T5` items.png 20→22 帧（640×32→704×32）+ `gen_item_icons.py` +2 函数（broken_crown 金王冠 / mech_engine 银蓝齿轮）+ **回归同步 day11_12 探针 frame_count 20→22**（icon 0-19 唯一断言只查 is_passive 项零改动）
  - W5（●收口）：`D20-EXIT` baseline + `day20_relic_check` + **回归十五件套**（day2 32 / day3 16 / day4 21 / day5 16 / day6 14 / day7 13 / day8 19 / day10 20 / day11_12 22 / day13 36 / day14_15 53 / day16 41 / day17 39 / day17_p0 20 / day18_19 N）+ `REPORT_PHASE_C.md`（仿 A/B）+ verify 36/36 + git commit（勿夹带 pindou/、.bak、pixel_to_pindou.py、LOOP_HEALTH.md）
  - 关键决策（已在 TASKS.md Day 20 定案表）：遗物 = slot:"relic" 直装不占被动槽（D16 resonant_shard 先例统一）｜持有上限 2（防无限叠）｜机械核心重名 → 机械引擎（不臆造不与进化核心混淆）｜受伤倍率 = armor 先减后乘｜结构伤害消费点 = turret.gd（顺带激活悬空词条）｜商店第三池不保底不加权（≈3.6% 自然稀有）｜W5 不得以「遗物 HUD 槽 / 遗物 VFX / mech_heart 未入池」判失败（P1/登记）
  - **T-D 追加（2026-08-07 01:1x · #2 第 19 轮 · P0 调度硬性输入）**：用户 08-06 拍板「两个工作日内」（= 08-07/08-08）→ 拆入本日——W3 加 `D20-T7`（4 技能图标 skills.png + gen_skill_icons.py）、W1 加 `D20-T8`（hud.gd skill_slot.texture 按 skill_data.id 查图，无图降级零回归）
  - 文件域校验：W1 写 `scripts/` + `tools/`、W2 写 `data/items.json`、W3 写 `assets/sprites/ui/items.png` + `assets/sprites/skills/skills.png` + `tools/gen_item_icons.py` + `tools/gen_skill_icons.py`，**无跨域写冲突**
- **Day 21-22 切分细化（2026-08-07 01:1x · #2 第 19 轮预拆）**：Day 18-19（已预拆）+ Day 20（已预拆）→ 预拆 Day 21-22 = **美术资产落地（阶段 D 首段）**——矩阵原「W1 ◐接入场景」上调「●接线」，W3 保持「●精灵」主责，W5 补「回归全套」——
  - W1（●接线）：`D21-22-T1` 中 SPRITE_MAP/FALLBACK 更新（slime/skeleton/elite/boss 路径 + size/frames/fps 与 PNG 实切一致）· **Boss scale ×2 → ×1 复位**（D18-19 过渡收口 + day18_19 探针断言同步）· `D21-22-T3` 攻击/技能动画接线（player.gd create_multi 追加 attack/skill + skill_controller skill_cast → 播放）· `D21-22-T5` 新建 `tools/day21_22_art_check.gd`（≥15 断言五段，含 T-E 机器侧关闭：`_apply_character_sprite("siia")` walk 命中非 fighter）· **F 系列 P1 排期段**（F-03 受击反馈 / F-05 通关回血 50% / F-06 倒计时+剩余怪 / F-07 火球穿透 / F-11 伤害数字——**已由 #2 第 20 轮实测函数级细化**，见 TASKS.md F 系列段，不阻塞美术主段）
  - W2（◐核验）：素材尺寸/帧数与 SPRITE_MAP 一致性核验（只读）
  - W3（●主责）：`D21-22-T1` 敌人/Boss 精灵（**类别代表制**：slime 系共用 48px + skeleton 48px + elite 64px + **invoker/predator 专属 128px**，不逐种画 23 个）· `D21-22-T2` 三英雄 walk 6 帧真多帧 + **希亚 siia_walk 新建（T-E 承接，补素材即自动接线）** · `D21-22-T3` attack/skill strip 4 英雄 · `D21-22-T4` 遗留头像 3 张（brawler/ranger/mage）+ 阵营 5 + 背景概念图 4
  - W5（●收口）：`D21-22-EXIT` baseline + `day21_22_art_check` + **回归全套**（day2 32 / day3 16 / day4 21 / day5 16 / day6 14 / day7 13 / day8 19 / day10 20 / day11_12 24 / day13 36 / day14_15 54 / day16 41 / day17 39 / day17_p0 20 / day18_feedback 16 / day18_19 48 / day20 23）+ git commit（勿夹带 pindou/、.bak、pixel_to_pindou.py、LOOP_HEALTH.md）
  - 关键决策（已在 TASKS.md Day 21-22 定案表）：敌人精灵类别代表制（13 slime 共用 1 精灵 + 精英 modulate 区分）｜**Boss 128px 换皮后 scale 复位 ×1**｜希亚 walk 补素材零代码接线｜attack/skill strip 产能不足可降级（skill 用 attack 帧）｜遗留头像先补 3 张代表（well_rounded/engineer/gambler 接受占位 P1）｜透明键 + 216 色字典登记制硬规格｜F 系列 P1 为排期不阻塞美术主段
  - 文件域校验：W3 写 `assets/sprites/`（enemies/ + characters/ + factions/ + backgrounds/）、W1 写 `scripts/` + `tools/`，**无跨域写冲突**（W3 不碰代码、W1 不画图）
- **Day 23 切分细化（2026-08-07 03:1x · #2 第 20 轮预拆）**：Day 18-19（已预拆）+ Day 20（已预拆）+ Day 21-22（已预拆）→ 预拆 Day 23 = **华丽技能特效**——矩阵原「W1 —」上调「●消费点接线」，W3 保持「●VFX PNG」——
  - W1（●接线 + 探针）：`D23-T1` FX_CONFIG 5→10 键扩展 + **hit 命中特效激活**（projectile 线弹命中 spawn "hit"，补零消费点缺口）· `D23-T3` 技能专属 VFX 接线（fireball 爆炸改 fx_fireball 替换 crit / deploy_turret 部署光柱 / blade_burst 身周爆发；holy_shield 顺延 P1——希亚技能本体未实装）· `D23-T4` 进化陨石替换（source_id=="se_star_fall" → fx_meteor）· `D23-T5` 新建 `tools/day23_vfx_check.gd`（≥12 断言四段）
  - W3（●主责）：`D23-T2` 新特效 PNG 5 枚（fx_fireball 火球爆炸 64px / fx_turret_deploy 部署光柱 64px / fx_blade_burst 剑刃圆环 64px / fx_meteor 陨石坠爆 128px / fx_shield 护盾罩 64px，P1 先出图接线待技能实装）——ART_STYLE v2 216 色 + 透明键
  - W5（●收口）：`D23-EXIT` baseline + `day23_vfx_check` + **回归全套**（day2 32 / day3 16 / day4 21 / day5 16 / day6 14 / day7 13 / day8 19 / day10 20 / day11_12 22 / day13 36 / day14_15 53 / day16 41 / day17 39 / day17_p0 20 / day18_19 N / day20 N / day21_22 N）+ git commit
  - 关键决策（已在 TASKS.md Day 23 定案表）：FX_CONFIG 扩展登记先行（缺图静默跳过零回归）｜hit 与 crit 双轨并存（普通命中 hit / 暴击 crit）｜fireball 用 source_id meta 识别替换 crit（其余武器零回归）｜大纲「毒雨/腐化」以数据为准不做（D18-19 已登记）｜pickup 特效零消费点属 T-B 掉落物系统（登记不属本日）｜特效色 shader 机制 = Backlog P1 决策（不建 GPU 基建）
  - 文件域校验：W3 写 `assets/sprites/effects/`（5 PNG）、W1 写 `scripts/effects/vfx_player.gd` + `scripts/weapons/projectile.gd` + `scripts/player/skill_controller.gd` + `tools/`，**无跨域写冲突**
- **Day 24 切分细化（2026-08-07 05:1x · #2 第 21 轮预拆）**：Day 18-19（已预拆）+ Day 20（已预拆）+ Day 21-22（已预拆）+ Day 23（已预拆）→ 预拆 Day 24 = **音频接入（阶段 D 收尾前段）**——矩阵原「W3 ●BGM/SFX」细化，W1 由「—」上调「●AudioManager + 接线 + 探针」，W2/W4 无职责——
  - W1（●重载）：`D24-T2` 新建 `scripts/autoload/audio_manager.gd`（第 3 Autoload：`_bgm_player` 循环 + `_sfx_pool` ×4 轮询防重叠 + `play_bgm/play_sfx/set_bgm_volume/set_sfx_volume` 接口 + `_process` 轮询 `GameManager.current_state` 5 态 → MENU menu / BATTLE·SHOP·ROUTE_SELECT battle / GAME_OVER stop；GameManager 未加载判空兜底）· `D24-T3` SFX 消费点最小集 10 处（main.gd:150 death / projectile 命中 hit + 爆炸 crit / enemy.gd:393 crit / player 受击 hit + 升级 levelup / economy 金币 coin / shop 购买 shop / skill_controller 技能 skill / GameManager 事件 event + Boss 波 boss，一行调用）· `D24-T4` project.godot `[autoload]` +1 行（AudioManager 在 GameManager 之后）· `D24-T5` 新建 `tools/day24_audio_check.gd`（≥14 断言五段：资源 WAV 头合法 / 配置 Autoload + 键完整 / 状态机 BGM 切换 / 播放层无头 Dummy 不崩 + 池轮询 / 回归抽样）
  - W3（●主责）：`D24-T1` 新建 `tools/gen_audio.py`（**纯 Python 标准库** wave+math+struct，零第三方依赖）程序化合成 WAV——BGM 2 轨（bgm_menu 琶音 8-12s / bgm_battle 脉冲 8-12s，循环点对齐）+ SFX 10 类（hit/crit/death/levelup/coin/shop/skill/heal/event/boss，0.1-1.5s）；22050Hz 16bit mono + 归一化峰值 0.8
  - W5（●收口）：`D24-EXIT` baseline + `day24_audio_check` + **回归全套**（day2 32 / day3 16 / day4 21 / day5 16 / day6 14 / day7 13 / day8 19 / day10 20 / day11_12 22 / day13 36 / day14_15 53 / day16 41 / day17 39 / day17_p0 20 / day18_19 N / day20 N / day21_22 N / day23 N）+ git commit（勿夹带 pindou/、.bak、pixel_to_pindou.py、LOOP_HEALTH.md）
  - 关键决策（已在 TASKS.md Day 24 定案表）：资源 = tools 程序合成占位（30DAY_PLAN D24 明示「用 tools 资源或占位」）｜架构 = 第 3 Autoload（读 GameManager.current_state，零侵入状态机）｜SHOP/ROUTE_SELECT 沿用 battle 轨不打断（战斗间态）｜SFX 最小集 10 处一行调用（零架构侵入）｜Boss 波提示 = is_boss_wave 判定处 SFX｜无头 Dummy audio driver 零崩溃｜W5 不得以「好不好听/空间音/音量 UI」判失败（主观归 Day 26 / P1 登记）
  - 文件域校验：W3 写 `tools/gen_audio.py` + `assets/audio/`（12 WAV）、W1 写 `scripts/autoload/` + 消费点 8 文件 + `project.godot` + `tools/`，**无跨域写冲突**
  - **F-13 追加切分（2026-08-07 22:5x · #2 第 30 轮 · 🔴 P0 用户拍板「尽快落地方案」· 拆入 Day 24 首段）**：机制型被动词条（追踪区增量 #36：被动全基础数值「没感觉到」→ 补质变型/触发类词条）——W2 由「—」上调「●items.json +3 机制型被动」、W3 追加「●图标 3 帧占位色块」、W1 追加「●机制消费点 3 处 + 回归同步 + 探针」——
  - W2（●新增）：`D24-F13-1` items.json 20→23 被动（**overload_capacitor 过载电容** on_crit 暴击 AOE / **executioner_mark 处决印记** on_kill 击杀回血 / **last_stand 背水一战** low_health 低血狂暴；effects 全 `{}` 走新 `trigger/trigger_config` 字段，**不入 D11-12 effects 白名单**）
  - W1（●追加）：`D24-F13-2` 机制消费点 3 处（projectile 暴击结算成功路径 AOE（**F-19 容器遍历范式**）/ main.gd:150 击杀回血 heal(1) / player.take_damage+heal 低血阈值动态开/关）· `D24-F13-4` 回归同步 4 处（icon_atlas 22→25 + day11_12/day13/day16/day20 探针口径）+ 新建 `tools/day24_f13_check.gd`（≥12 断言四段）
  - W3（●追加）：`D24-F13-3` 图标 3 帧占位色块（gen_item_icons.py +3 → items.png 704→800×32，豁免色号编码，D22/D23 先例）
  - 文件域校验：W2 写 `data/items.json`、W3 写 `assets/sprites/items/` + gen 工具、W1 写 `scripts/`（projectile/main/player）+ `tools/`，**无跨域写冲突**（与音频线并行，两线完成后统一 EXIT；数据+图标批次可先行 commit）
- **Day 26 切分细化（2026-08-07 07:1x · #2 第 22 轮预拆）**：Day 18-19/20/21-22/23/24（已预拆）+ Day 25（已预交付）→ 预拆 Day 26 = **阶段 D 整合校验（纯校验日，零新功能）**——矩阵原「W1 ●整合」细化，W2 由「—」上调「◐收口清单核对（只读）」——
  - W1（●重载）：`D26-T1` 新建 `tools/day26_integration_check.gd`（≥20 断言五段：§1 美术资产齐备（SPRITE_MAP 全路径 + Boss scale==1.0 + 4 角色 walk/attack/skill + factions/backgrounds/头像 + .import）/ §2 特效（FX_CONFIG 10 键 + 5 新特效 PNG + hit 消费点 + source_id）/ §3 音频（12 WAV 头合法 + AudioManager Autoload + BGM 状态机 + SFX_MAP 10 键）/ §4 剧情载体（LORE.md + events.json 10 + 解锁文案数据存在性）/ §5 回归全套）· `D26-T2` 接线完整性抽查（AudioManager 状态机 / VfxPlayer 消费点 / GameManager.hud 赋值（F-11）/ SPRITE_MAP siia 命中（T-E 关闭）——**存在则验、缺失 push_warning 登记不判失败**）
  - W2（◐只读核验）：`D26-T3` 阶段 D 收口清单核对（TASKS 各日回执 [x] 对照 + events/items/weapons/音频交叉引用 + 顺延项登记汇总：F 系列 P1 / 遗物 HUD 槽 / 空间音 / 音量 UI / mech_heart 入池 / 剧情解锁接线（Day 27））——**data/*.json 只读，产出写 docs/ 与探针尾部清单**
  - W3（◐核验）：阶段 D 美术/音频资产与预拆清单一致性核验（只读 assets/）；W4（◐核验）：LORE.md / events.json 剧情载体核验（只读）
  - W5（●收口）：`D26-EXIT` baseline + `day26_integration_check` + **回归全套**（day2 32 / day3 16 / day4 21 / day5 16 / day6 14 / day7 13 / day8 19 / day10 20（F-20 后 21）/ day11_12 25 / day13 36 / day14_15 54 / day16 41 / day17 39 / day17_p0 20 / day18_feedback 16 / day18_feedback2 32 / day18_feedback3 27 / day18_19 48 / day20 23 / day21_22 38 / day23 18 / day24_f13 17 / day24_audio 14）+ verify 36/36 + 产出 `docs/REPORT_PHASE_D.md`（仿 A/B/C）+ 主观项汇总 → PLAYTEST_CHECKLIST（#5 收口，不阻塞出口）+ git commit（勿夹带 pindou/、.bak、pixel_to_pindou.py、LOOP_HEALTH.md）
  - 关键决策（已在 TASKS.md Day 26 定案表）：纯校验日（机器可验证 = 资产齐备 + 接线 + 回归 + 报告；主观项全交 #5）｜探针降级口径（前序日未收口 → push_warning + 跳过不判失败，防探针阻塞收口链）｜Day 25 剩余（角色剧情解锁接线）= 登记 Day 27 依赖（实测 scripts/scenes 零接线点，game_manager.gd:433 unlock_node = 事件改线非剧情解锁）｜顺延项存在则验缺失登记｜REPORT_PHASE_D 独立成文（PROGRESS.md 为 #1 独占）｜W5 不得以「视觉审美 / 音频氛围 / F 系列 P1 / 遗物 HUD 槽 / 空间音 / 音量 UI / mech_heart 入池 / 剧情解锁不可玩」判失败｜收口后目标日 → Day 27（局外养成）
  - 文件域校验：W1 写 `tools/`、W2 只读 `data/` + 写 `docs/`、W3/W4 只读、W5 写 `docs/REPORT_PHASE_D.md` + `TEST_REPORT.md`，**无跨域写冲突**
- **Day 27 切分细化（2026-08-07 09:1x · #2 第 23 轮预拆）**：Day 26（已预拆）收口后 → 阶段 E 首段 = **局外养成（方舟基地 + 研究系统 + 角色培养 + 剧情解锁接线）**——矩阵原「W1 ●方舟基地+研究+角色培养 / W2 ●局外数值」细化，W3 由「—」升「◐基地占位主题（P1）」、W4 由「—」升「◐LORE.md 提炼核验（只读）」；**实测存档/基地/研究/培养全域零实现**（全新系统零回归，characters.json unlock_condition 数据在零消费方）——
  - W1（●重载）：`D27-T1` GameManager 局外存档（`meta_progress` + `load_meta/save_meta` `user://save_meta.json` + `get_meta_bonus` + 结算钩子：start_game 记出场 / end_game(victory) 记胜场+研究点+角色 xp）· `D27-T3` 永久增益装配（main.gd 进局 `get_meta_bonus()` → bonus_stats 注入：attack ×(1+0.05×档) / max_health ×(1+0.10×档) / luck +0.05×档，research 全 0 零注入）· `D27-T4` 方舟基地场景（`scenes/BaseStation.tscn` + `scripts/ui/base_station.gd`：研究 3 项升级按钮 + 角色卡片等级/XP/剧情查看 + 返回；入口 = character_select.gd 加按钮）· `D27-T5` 剧情解锁接线（角色卡片 `xp/3 >= story_unlock_level` 解锁 story 文本；**game_manager.gd unlock_node 事件改线零改动**）· `D27-T6` 新建 `tools/day27_meta_check.gd`（≥16 断言五段：存档读写/研究增益/角色 XP/剧情门槛/回归抽样）
  - W2（●数据）：`D27-T2` characters.json 10 英雄补 `story`（**从 docs/LORE.md 提炼 1-2 句，不新写剧情**）+ `story_unlock_level`（默认 1）；`unlock_condition` 现状保持零改动
  - W3（◐轻）：`D27-T4` 基地 UI 占位主题（复用现有 NinePatchRect/主题色，P1 可延不阻塞功能）
  - W4（◐只读）：LORE.md 角色小传条目与 characters.json `story` 一致性核验（提炼来源可追溯）
  - W5（●收口）：`D27-EXIT` baseline + `day27_meta_check` + **回归全套**（day2 32 / day3 16 / day4 21 / day5 16 / day6 14 / day7 13 / day8 19 / day10 20（F-20 后 21）/ day11_12 25 / day13 36 / day14_15 54 / day16 41 / day17 39 / day17_p0 20 / day18_feedback 16 / day18_feedback2 32 / day18_feedback3 27 / day18_19 48 / day20 23 / day21_22 38 / day23 18 / day24_f13 17 / day24_audio 14 / day25 N / day26 N）+ git commit（勿夹带 pindou/、.bak、pixel_to_pindou.py、LOOP_HEALTH.md；**user:// 存档为运行时文件不入库**）
  - 关键决策（已在 TASKS.md Day 27 定案表）：存档并入 GameManager（零新 Autoload，规避 D24 并发）｜研究点 = 胜利局数（零新货币防臆造）｜研究 3 项各 1 级即达大纲值（攻击+5% / 生命+10% / 幸运+5%）｜角色 XP = 出场+1/胜利+1、等级 = xp/3（仅驱动剧情解锁不造属性收益）｜剧情文案从 LORE.md 提炼不新写｜boss_defeated 由 end_game(victory) 统一消费（局外只认胜利结局）｜技能升级/潜能突破 = P1 登记不臆造（无数据支撑）｜research 全 0 零注入零回归
  - 文件域校验：W1 写 `scripts/` + `scenes/` + `tools/`、W2 只写 `data/characters.json`、W3 写 `assets/sprites/ui/`（可选 P1）、W4 只读 `docs/LORE.md`，**无跨域写冲突**
- **Day 10 切分细化（2026-08-06 07:1x · #2 第 10 轮）**：Day 8-9 已收口（`d1e72f1`），33/33 武器 Lv1-8 全量就绪 → 本日 = **武器进化机制**（scripts/ 全域零 evolution 引用，全新实现）——
  - W1（●重载）：`D10-T2` Inventory id 维度装配（`item.gd` +`item_id` 字段；`inventory.gd` +`add_item_from_data/has_item_id/remove_item_id`）· `D10-T3` WeaponController `replace_weapon`（build→升满级→原子替换→`_sync_orbit_weapon` 一次）+ 爆炸透传（`weapon.gd` +`explosion_radius/explosion_damage`，projectile 已支持）· `D10-T4` LevelUpPanel 进化池（满级 + `inventory.has_item_id(requires_item)` → 进化选项；**先替换成功再消耗核心**）· `D10-T6` 新建 `tools/day10_evolution_check.gd`（≥15 断言 + 回归锚点）
  - W2（●数据）：`D10-PRE` 定案新增 `se_blade_core` 补齐星刃链（3 签名链对齐）· `D10-T1` 3 把结果武器（`se_star_fall` 炎星陨落/爆炸 AOE / `se_turret_array` 机械炮阵 / `se_blade_storm` 星刃风暴 6 刃环绕）加入 weapons.json（带 `evolution_result: true`、平曲线 levels、icon 33/34/35）+ `se_blade_core` 入 items.json（扩展 `gen_weapons_day7.py` LEVELS +3）
  - W3（◐轻）：`D10-T5` 结果武器图标 3 帧（帧 33/34/35 实绘，36-39 空余；不动 0-32 已收口帧）
  - W5（●回归）：`D10-EXIT` baseline + `day10_evolution_check` + 回归七件套（day2 32 / day3 16 / day4 21 / day5 16 / day6 14 / day7 13 / day8 19）+ `gen_weapons_day7.py verify` 36/36
  - 关键决策（已在 TASKS.md Day 10 定案表）：星刃链补齐 se_blade_core（禁挂 elemental_core）｜结果武器入 weapons.json 带 evolution_result 标记（Day 13 武器池范围统一时排除）｜结果武器平曲线 + 进化即满级（循环 upgrade ≤7 次）｜触发点 = 升级面板进化池（零新 UI）｜核心消耗时序 = 先替换成功再 remove_item_id｜se_turret_array「常驻/多台」机制归 Day 13｜核心获取途径（商店）归 Day 11-12
  - 文件域校验：W1 写 `scripts/` + `tools/`、W2 写 `data/weapons.json` + `data/items.json` + `tools/gen_weapons_day7.py`、W3 写 `assets/sprites/ui/weapons.png` + `tools/gen_weapon_icons.py`，**无跨域写冲突**
- **Day 2 遗留收敛（06:35）**：`D2-T5`（星刃 `evolution`）原为 `[~]` 在进行中，会导致目标日定位被永久钉死在已完工的 Day 2 → **改标 `[!]` 并转出为 Day 10 `D10-PRE`**，单一来源。
- **主观验收隔离**：手感/难度曲线/数值趣味/UI/视听/剧情调性等主观项不进关键路径，由 W5 汇总至 `docs/PLAYTEST_CHECKLIST.md`，Day 29 集中人工试玩，不拖慢自动化。
- **动态调度权**：本表为快照；【项目进度管理专家】依据 `docs/TASKS.md` 实际进度与阻塞，每轮可重排上表（例如把滞后的 W2 任务临时借 W1 协作），并回写 `TASKS.md` 对应日。
- **验收口径**：客观（能跑/不崩/数据合法）= W5 baseline + 自动化测试自动通过；主观（好不好玩/像不像）= 仅人工，隔离到清单 + Day 29。
