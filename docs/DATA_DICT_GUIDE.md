# 策划改数手册（DATA_DICT_GUIDE）

> 建立：2026-08-16（阶段 F · F5 收口 · 唯一新交付物）
> 目标读者：策划 / 非程序岗，需要改游戏数值时按本手册操作。
> 单一事实源：`docs/GameData.xlsx`。`data/*.json` 全部为**导出产物（generated）**，禁止手改。
> 管线全貌：改 Excel → `tools/excel_export.py` 校验+导出 → 探针/回归确认 → git 提交。

---

## 0. 改数典型流程（5 步，全程照着做）

1. **打开** `docs/GameData.xlsx`（不要开第二个副本；如提示文件被占用说明有进程在编辑，关闭后再改）。
2. **改对应 sheet**（表清单见 §1；双行表头：第 1 行英文列名 = 程序解析依据，第 2 行中文注释 = 给你看的，数据从第 3 行起）。
3. **导出**：在项目根目录运行
   ```
   python tools/excel_export.py
   ```
   校验通过 → 自动写出 `data/*.json` + `data/.manifest.json`（指纹）+ 刷新 `docs/DATA_OVERVIEW.md` 与工作簿内「总览」sheet。
4. **看校验输出**：有 `ERR` 行 = 失败不导出，按提示改回；有 `WARN` 行 = 不阻塞但要注意（详见 §3）。
5. **回归确认**：跑相关探针或全量回归（命令见 §2），全部 `CLEAN` 后提交 git。

> ⚠️ 提交前护栏（自动化也会跑）：`python tools/excel_export.py --check-only`（只校验不写盘），通过才允许 commit。

---

## 1. 表清单（以 tools/data_schema.py SHEETS 注册表实测盘点，2026-08-16 共 26 张）

> 每张表对应「改哪个 sheet → 导出到哪个 JSON → 数据结构形态」。kind 说明：
> `category_map`=JSON 按分类分组（Excel 用 `_xlsx_category` 列归组）｜ `list`=JSON 数组
> `dict`=JSON 字典（键 = 主键列）｜ `child_*`=子表（父表删除后回填）｜ `flat_dict`=单行参数表

| # | sheet 名 | 导出 JSON | 形态 | 一句话用途 |
|---|---|---|---|---|
| 1 | weapons | weapons.json | category_map（+子表 weapons_levels） | 36 把武器基础属性（伤害/冷却/射程/暴击等） |
| 2 | weapons_levels | weapons.json | child_list | 每把武器 Lv1-8 升级表（weapon_id + level + 数值） |
| 3 | items | items.json | list（+子表 items_effects） | 54 个道具/被动/遗物/进化核心 |
| 4 | items_effects | items.json | child_dict | 道具效果键值对（key=效果键，value=数值） |
| 5 | enemies | enemies.json | category_map | 23 个敌人（regular/elite/boss）基础属性 |
| 6 | enemy_scaling | enemies.json | flat_dict | 全局敌人成长参数（每波生命/伤害/速度成长等） |
| 7 | characters | characters.json | list（+子表 passives/penalties） | 10 英雄（属性/起始武器/技能/剧情） |
| 8 | characters_passives | characters.json | child_dict | 角色被动加成（char_id + key + value） |
| 9 | characters_penalties | characters.json | child_dict | 角色惩罚项（如希亚） |
| 10 | waves | waves.json | list | 20 波波次配置（敌人数/组成 composition JSON） |
| 11 | wave_generation | waves.json | flat_dict | 波次生成参数（间隔/衰减/完成奖励） |
| 12 | wave_rewards | waves.json | flat_dict | 奖励结算参数（击杀奖励/收割加成） |
| 13 | events | events.json | list | 10 个随机事件（选项 A/B + 奖励/改线） |
| 14 | stats | stats.json | category_map | 属性定义（basic/offensive/economy 分组） |
| 15 | stats_formulas | stats.json | flat_dict | 战斗公式（暴击判定/护甲公式等） |
| 16 | stats_leveling | stats.json | flat_dict | 升级曲线（每级经验/每级选项数） |
| 17 | stats_shop | stats.json | flat_dict | 商店参数（重铸费/核心武器宽限波） |
| 18 | stats_combat | stats.json | flat_dict | 战斗手感参数（通关回血比/最大波次/无敌帧/闪避上限等） |
| 19 | stats_physics | stats.json | flat_dict | 弹丸物理（碰撞层/半径） |
| 20 | stats_skills | stats.json | flat_dict | 火球参数（速度/寿命/穿透/爆炸半径） |
| 21 | elements | elements.json | dict | 5 个元素状态（灼烧/中毒 DoT 参数 + 免疫表字段） |
| 22 | element_reactions | elements.json | list | 元素反应组合表 |
| 23 | reaction_rules | elements.json | flat_dict | 反应规则全局参数 |
| 24 | routes | routes.json | flat_dict | 路线地图（层数/每层节点/权重/Boss 层） |
| 25 | boss_skill | boss_skills.json | dict | Boss 技能表（id + 类型 + 参数 + 效果） |
| 26 | boss_pattern | boss_patterns.json | list | Boss 出招模式（阶段权重/解锁/override） |

> 📌 约定提醒：
> - **嵌套对象 = 点号列**：如 weapons 表的 `scaling.melee_damage`、characters 表的 `skill.effects.shield`、events 表的 `choiceA.reward.value`，直接改列即可，导出自动还原嵌套。
> - **JSON 文本列**（表中标「(JSON)」的列）：如 weapons `evolution`/`evolution_result`、enemies `phases`/`resist`、waves `composition`、events 部分 value、items `tags`，单元格内写合法 JSON 文本（形如 `{"weapon_id":"se_star_flame","requires_level":8}`），导出时校验可解析。
> - **新增行**：主表在主键列填新 id 即可，导出自动纳入；子表行需填父表主键（weapon_id/item_id/char_id）。
> - **删除行**：直接删整行；删除后跑导出，注意子表若残留父表引用会报错（ERR 会提示行号）。

---

## 2. 常用命令速查

| 命令 | 用途 | 何时用 |
|---|---|---|
| `python tools/excel_export.py` | 校验 + 导出全部 JSON + manifest + 总览 | 每次改数后 |
| `python tools/excel_export.py --check-only` | 只校验不写盘（git 提交前护栏） | 提交前必跑 |
| `python tools/excel_export.py --overview` | 只刷新总览（DATA_OVERVIEW.md + 总览 sheet） | 不动数据只想看统计 |
| `python tools/json_to_excel.py` | 从现有 data/*.json 重建整个工作簿（一次性） | 仅首次导入/结构大改，平时不用 |
| `python tools/_regression_run.py` | 全量回归（47 件套探针 + baseline + weapons verify） | 改动涉及游戏逻辑/数据后 |
| `python tools/baseline_check.py` | 仅基线检查（import + runtime） | 快速确认工程健康 |

探针（单探针验证）：`tools/Godot_v4.3-stable_win64.exe --headless --path "D:/30DAYS" --script res://tools/<探针名>.gd`

---

## 3. 校验规则速查（excel_export.py 内置，ERR 即失败）

- **枚举校验**：items.rarity ∈ {common, uncommon, rare, epic, legendary}；items.slot ∈ {passive, relic}；
  enemies.behavior ∈ {aoe_attack, charge, chase, heal, ranged, self_heal, spawn, stationary, zigzag}；
  enemies._xlsx_category ∈ {regular, elite, boss}；weapons._xlsx_category ∈ {melee, ranged, elemental, engineering}；
  events 奖励/改线类型 ∈ 固定枚举（见 tools/excel_export.py VALID_* 常量）。
- **引用完整性**：characters.starting_weapon 必须在 weapons 表存在。
- **items_effects 键白名单**：新效果键未在 `KNOWN_EFFECT_KEYS` 登记 → WARN（不阻塞）；若要新增效果键，需同步告知程序侧补消费点（否则改了没反应）。
- **JSON 列可解析**：点号列/JSON 文本列写非法 JSON → ERR。
- **roundtrip 自检**：导出结果与现有 JSON 有差异 → WARN「有差异（首次导入需人工确认）」，正常改数属预期。

> 判定：**有 ERR 行 = 导出中止**（数据文件不更新），必须改回后重跑；只有 WARN 可以带着走（但要读懂含义）。

---

## 4. 典型改数示例

**例 1：调低敌人血量成长**
1. 打开 GameData.xlsx → `enemy_scaling` sheet。
2. 找到 `hp_growth`（或对应成长列），改数值。
3. 运行 `python tools/excel_export.py` → 看到 `[out] data/enemies.json` 即成功。
4. 跑 `python tools/_regression_run.py` 确认回归全绿（涉及敌人相关探针会校验数值范围）。
5. `git add docs/GameData.xlsx data/enemies.json data/.manifest.json docs/DATA_OVERVIEW.md && git commit`。

**例 2：给商店加一件遗物**
1. `items` sheet 新增一行（id/name/rarity/price/slot="relic"/icon_index/description），在 `items_effects` sheet 加对应 `item_id` + key + value。
2. 导出 + 校验（注意 icon_index 不能与现有重复；稀有度/效果键枚举合法）。
3. 回归确认后提交。

**例 3：改 Boss 出招节奏**
1. `boss_pattern` sheet（出招模式：阶段权重/解锁层）或 `boss_skill` sheet（技能参数：冷却/半径/伤害）。
2. 导出 + 校验。
3. 跑 `day30_boss_skill_check` 探针确认 49/49。

**例 4：调整全局手感（无敌帧/闪避/火球）**
1. `stats_combat` sheet（无敌帧/闪避上限/通关回血/最大波次/金手指倍率）、`stats_physics`（弹丸）、`stats_skills`（火球）。
2. 导出 + 校验。
3. 相关探针：day30_f1_scaling / day30_f1_scatter 等。

---

## 5. 数据改动后必跑的探针/回归（锚点联动）

| 改动范围 | 重点探针 | 回归门槛 |
|---|---|---|
| weapons / weapons_levels | day5 / day7 / day8 / day10 / day30_f1_scaling | 47 件套全绿 |
| items / items_effects | day11_12 / day13 / day20 / day24_f13 / day30_f1d_shop | 47 件套全绿 |
| enemies / enemy_scaling | day17 / day18_19 / day18_feedback* | 47 件套全绿 |
| characters | day2 / day3 / day29_elin / day27_meta | 47 件套全绿 |
| waves | day6 / day14_15 | 47 件套全绿 |
| events | day16 / day18_feedback3 | 47 件套全绿 |
| stats* | day30_f1_scaling / day30_f1d_shop / day30_f1_scatter / day13 | 47 件套全绿 |
| elements | day30_effect / day30_boss_skill | 47 件套全绿 |
| routes | day14_15 / day30_g_map / day30_f1_scaling | 47 件套全绿 |
| boss_skill / boss_pattern | day30_boss_skill / day18_19 | 47 件套全绿 |

> 图集帧数锚点（items.png 帧数）：探针 day11_12/day20/day24_f13 已改为**动态读取** `icon_atlas.get_frame_count()`（F5-T1），
> 不再硬编码帧数——**加道具帧数不再需要同步探针**，只要 icon_index 不越界即可。

---

## 6. 红线与注意

- **data/*.json 禁手改**——改了也会被下次导出覆盖，且探针校验会红。
- **改数不跨系统**：本手册只管数据；涉及代码消费点（新效果键/新技能类型/新表结构）需先告知程序侧（#2 拆解 → #3 实现），数据先行只会「改了没反应」。
- **新增 sheet 需程序侧配合**：先让程序在 tools/data_schema.py 注册（SHEETS + COLUMN_ZH），再在 Excel 建表，否则导出不识别。
- **Excel 被占用**：改数前确认没有其他进程打开该文件（WPS/Office 锁），否则保存冲突。
- **回归基准**：全量回归当前为 47 件套 ≥1046 断言 + baseline `BASELINE CLEAN`（见 docs/TEST_REPORT.md 顶部摘要）。
