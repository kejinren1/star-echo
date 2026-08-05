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
| 5 | A | 武器 6 槽挂载 | ●自动攻击 + 6 槽 + 升级逻辑 | ●武器 Lv1-8 曲线 | — | — | ●baseline |
| 6 | A | 阶段 A 集成测试 | ●集成 | ●平衡初调 | — | — | ●全量 baseline + 手感冒烟 + 报告 |
| 7–9 | B | 15 武器数据 + 精灵 | ◐武器装配逻辑 | ●15 武器 Lv1-8 数据 + 曲线 | ●武器精灵 | — | ●每日 baseline |
| 10 | B | 武器进化 | ●进化机制代码 | ●Lv8 + 核心数据 | — | — | ●baseline |
| 11–12 | B | 20 被动 | ●6 被动槽装配 | ●4 类 20 被动数据 | — | — | ●baseline |
| 13 | B | Build 集成 + 数值冒烟 | ●10 属性公式校验 | ●进化/被动叠加边界 | — | — | ●边界测试 + 报告 |
| 14–15 | C | 随机节点地图 | ●节点拓扑 + 种子 RNG | — | — | — | ●baseline |
| 16 | C | 事件节点 | ●事件节点逻辑 | — | — | ●10 文本事件(`events.json`) | ●baseline |
| 17 | C | 精英战斗 | ●精英逻辑 | ●精英属性 | — | — | ●baseline |
| 18–19 | C | Boss 两阶段 | ●两阶段逻辑 | ●Boss 数值 | ●Boss 精灵 | — | ●baseline |
| 20 | C | 遗物 + 阶段 C 回归 | ●遗物逻辑 | ●遗物数据 | — | — | ●回归 + 报告 |
| 21–22 | D | 美术资产落地 | ◐接入场景 | — | ●英雄/敌人/Boss 二次元像素精灵 | — | ●baseline |
| 23 | D | 华丽技能特效 | — | — | ●VFX(火球/召唤/环绕/陨石/毒雨) | — | ●baseline |
| 24 | D | 音频接入 | — | — | ●BGM/SFX | — | ●baseline |
| 25 | D | 剧情文本 | — | — | — | ●世界观 + 10 事件 + 角色剧情 | ●baseline |
| 26 | D | 整合校验 | ●整合 | — | ◐整合 | ◐整合 | ●主观项 → `PLAYTEST_CHECKLIST.md` |
| 27 | E | 局外养成 | ●方舟基地 + 研究 + 角色培养 | ●局外数值 | — | — | ●baseline |
| 28 | E | 全量测试 + 性能 | — | — | — | — | ●自动化测试 + 性能 + `TEST_REPORT.md` |
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
- **Day 2 遗留收敛（06:35）**：`D2-T5`（星刃 `evolution`）原为 `[~]` 在进行中，会导致目标日定位被永久钉死在已完工的 Day 2 → **改标 `[!]` 并转出为 Day 10 `D10-PRE`**，单一来源。
- **主观验收隔离**：手感/难度曲线/数值趣味/UI/视听/剧情调性等主观项不进关键路径，由 W5 汇总至 `docs/PLAYTEST_CHECKLIST.md`，Day 29 集中人工试玩，不拖慢自动化。
- **动态调度权**：本表为快照；【项目进度管理专家】依据 `docs/TASKS.md` 实际进度与阻塞，每轮可重排上表（例如把滞后的 W2 任务临时借 W1 协作），并回写 `TASKS.md` 对应日。
- **验收口径**：客观（能跑/不崩/数据合法）= W5 baseline + 自动化测试自动通过；主观（好不好玩/像不像）= 仅人工，隔离到清单 + Day 29。
