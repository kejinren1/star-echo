# 《星骸回响》Star Echo · 每日可执行任务清单（TASKS）

> 供自动化 #2（任务拆解）更新、#3（方案确定与执行）读取实现。
> 状态标记：`[ ]` 未开始 · `[~]` 进行中 · `[x]` 完成 · `[!]` 受阻/需人工。
> 护栏：未定义当日任务前不写游戏代码；改前 git commit；改后跑 `tools/baseline_check.py`。

> **🎯 当前目标开发日：Day 1**（最后拆解：2026-08-05 02:35 · 自动化 #2）
> Day 1 客观任务 1/4 完成，剩余 3 项已拆解为 `D1-T1 ~ D1-T3`（含实测核查结论，#3 可直接执行）。
> Day 2 已按并发冲刺实际交付回填真实状态，并预置 `D2-T1 ~ D2-T3` 供 Day 1 收口后立即衔接。

---

## 并发冲刺（starecho-sprint）已交付 · 2026-08-04

> 5 个并行 Agent（w1-code / w2-data / w3-art / w4-narrative / w5-qa）并发落盘，文件域隔离无冲突。
> 集成节点（team lead）完成 `project.godot` 接线（`run/main_scene` → `CharacterSelect.tscn`）与最终基线复验。

- [x] **集成基线复验**：`tools/baseline_check.py` → `BASELINE CLEAN`（import + runtime 双阶段，exit 0 / stderr 0）
- [x] w1-code：角色选择场景 `scenes/CharacterSelect.tscn` + `scripts/character_select.gd`（英雄 ID↔精灵别名 `PORTRAIT_ALIAS` 已桥接，缺图自动降级占位色块）
- [x] w2-data：`data/characters.json` +3 英雄（se_irene/noa/ren）、`weapons.json` +3 签名武器、`items.json` +2 进化核心
- [x] w3-art：`assets/sprites/characters/` 9 张英雄 PNG + `docs/ART_ANIME_SPEC.md`
- [x] w4-narrative：`data/events.json` 10 事件 + `docs/LORE.md`
- [x] w5-qa：`docs/TEST_REPORT.md`（baseline 双跑 CLEAN + 8/8 JSON 校验 + 交叉引用）
- [x] 数据缺陷修复：`gambler.starting_weapon` 悬空 `shuriken` → `dagger`（9/9 角色起始武器全部命中）

**冲刺遗留待办**：已于 2026-08-05 拆解并归位到 **Day 2 的 `D2-T1` / `D2-T3`**，此处不再重复维护（避免双源漂移）。

---

## 阶段 A · 核心循环对齐 & 手感打磨（Day 1–6）

### Day 1 — 框架基线 & 差异清单　🎯【本轮目标日 · 已拆解】

- [x] 跑 `python tools/baseline_check.py`，确认输出 `BASELINE CLEAN`（集成节点复验 2026-08-04）

#### D1-T1【W1 主责】核对大纲 §5 操作 vs 现有输入映射
- [x] 在 `project.godot` 的 `[input]` 段新增主动技能动作 `skill_cast`（建议 `Space` + 鼠标右键双绑定）✅ 已落地（Space 物理键码 32 + 鼠标右键 button_index 2）
- [x] `scripts/player/player.gd`：预留 `_unhandled_input` / `Input.is_action_just_pressed("skill_cast")` 空实现挂钩（Day 3 填充逻辑，本日仅打桩不实现技能）✅ `_try_cast_skill()` 空挂钩已加（player.gd:119-128）
- **实测现状（本轮已核查，勿重复排查）**：`[input]` 原仅 6 个动作 —— `move_up/move_down/move_left/move_right`(WASD) + `ui_accept`(Z/Enter) + `ui_cancel`(Esc)；本日新增 `skill_cast` 后为 7 个
- **差异结论**：移动 ✅ 已具备；自动攻击 ✅ 已具备（鼠标方向自动射击，无需输入动作）；**主动技能 ❌→🟡 缺口已打桩**（输入动作 + 空挂钩，逻辑归 Day 3）——大纲 §5 三项操作里唯一缺口已闭环输入层
- **测试点**：`InputMap.has_action("skill_cast") == true` ✅；4 向移动动作零回归 ✅；`baseline_check` → `BASELINE CLEAN` ✅（改动后复验 2026-08-05）

#### D1-T2【W2 主责 / W1 协作】产出 `docs/DIFF_FRAMEWORK_STARECHO.md`
- [x] 新建该文件，按 6 章成文（本轮核查结论已备齐，直接落笔即可）✅ 已产出 `docs/DIFF_FRAMEWORK_STARECHO.md`（8 章：导言+§1~§6+风险+交付物）
  - [x] §1 输入操作差异 —— 引用 D1-T1 结论（`skill_cast` 已打桩）
  - [x] §2 角色差异 —— 9 英雄（原框架 6 + Star Echo 3），`starting_weapon` 交叉引用 **9/9 全部命中**；`se_irene/se_noa/se_ren` 已带 `skill` 字段；**三者均无 `sprite` 字段**，`character_select.gd` 目前靠硬编码 `PORTRAIT_ALIAS` 映射 → 建议 Day 2 补 `sprite` 字段收敛
  - [x] §3 武器差异 —— `weapons.json` 共 **32 把**（melee 8 / ranged / elemental / engineering 四类）；条目字段为 `damage/cooldown/range/crit_chance/crit_damage/scaling/knockback/life_steal/special`；**se_ 签名武器已含 Lv1-8 `level[]` + `evolution`，29 把旧武器缺 `level` 升级表** → 阻塞 Day 5 / Day 7–9（Day 10 进化 schema 已可用）
  - [x] §4 属性差异 —— 大纲 10 属性 vs `stats.json`（basic/offensive/economy）：攻速`attack_speed`/范围`range`/移速`speed`/暴击率`crit_chance`/暴伤`crit_damage`/生命`max_hp`/护甲`armor`/吸血`life_steal`/幸运`luck` **9 项直接对应**；**「攻击力」为唯一口径冲突**——现框架拆成 `melee_damage`/`ranged_damage`/`elemental_damage` 三系，需决策「聚合为统一攻击力」或「保留三系并在 UI 聚合展示」（Day 4 强化面板依赖此决策）
  - [x] §5 被动/道具差异 —— `items.json` 共 **47 项**（字段 `id/name/rarity/price/effects/tags`）；进化核心已就位 `se_flame_core`/`se_mech_core`/`elemental_core`；**缺被动槽位标识**，6 被动槽装配（Day 11–12）需补 `slot`/`is_passive` 区分道具与被动
  - [x] §6 缺失系统清单 —— 主动技能系统、XP/升级面板、6+6 槽、武器进化、随机节点地图、事件节点、精英、两阶段 Boss、遗物、局外养成
- **测试点**：文件存在且 6 章齐全 ✅；文中引用的所有 id（`se_star_flame`/`se_flame_core` 等）在对应 JSON 中可检索命中 ✅

#### D1-T3【W2】确认现有数据结构可复用
- [x] 将本轮实测结论固化进 D1-T2 §2/§3/§4/§5（无需另起文件）✅ 已固化
- **实测结论**：`characters.json` = `{characters:[9]}`、`weapons.json` = `{weapons:{4 类, 共 32}}`、`items.json` = `{items:[47]}`、`stats.json` = `{stats,formulas(15),leveling}`
- **判定：结构可复用 ✅**，全部为「增字段」而非「改结构」，`DataLoader` 无需重写；武器仅旧 29 把需补 `level`，被动需补 `slot` 标识

#### D1-EXIT【W5】当日出口
- [x] `python tools/baseline_check.py` → `BASELINE CLEAN` ✅（2026-08-05 改动后复验）
- [x] `docs/DIFF_FRAMEWORK_STARECHO.md` 存在且非空 ✅
- 备注：`docs/PROGRESS.md` 目前尚未生成（属自动化 #1 交付物，不阻塞 Day 1 出口）

### Day 2 — 角色选择 + 3 英雄　【状态已按并发冲刺实际交付回填 · 预置拆解】

- [x] 实现角色选择场景/界面（3 英雄：艾琳 Mage / 诺亚 Summoner / 莱恩 Melee）
      → `scenes/CharacterSelect.tscn` + `scripts/character_select.gd` 已落盘，`project.godot` 入口已指向该场景
- [x] 初始武器**数据**就位：`se_star_flame` / `se_auto_turret` / `se_star_blade`（已实测：9/9 英雄 `starting_weapon` 交叉引用全部命中）
- [x] 专属技能**数据**占位：`se_irene` / `se_noa` / `se_ren` 三英雄的 `skill` 字段已存在于 `characters.json`
- [x] `baseline_check` 通过（2026-08-04 集成节点复验 `BASELINE CLEAN`）

> ⚠️ 上述为**数据侧**完成；**代码侧消费链路仍未打通**——已实测 `scripts/autoload/main.gd`（59 行）**零 hero/character 引用**。以下为 Day 2 真实剩余工作：

#### D2-T1【W1 主责】`Main` 侧消费 hero id（Day 2 核心剩余项）
- [ ] `scripts/autoload/main.gd`：调用 `CharacterSelect.get_selected_character_id(self)` 取回英雄 id
      （接口已就绪：`character_select.gd:48` 静态方法，经 `get_tree().root` 的 `SELECTION_META` 元数据跨场景传递，`:201` 写入）
- [ ] 空值兜底：未经选择直接跑 `Main.tscn`（调试路径）时回退默认英雄 `well_rounded`，禁止崩溃
- [ ] 由 `DataLoader` 按 id 取角色 → 将 `starting_weapon` 注入 `scripts/weapons/weapon_controller.gd`
- [ ] 将角色 `passive` 注入 `scripts/player/player.gd` 初始属性
- **测试点**：选艾琳进局，`WeaponController` 首武器 == `se_star_flame`；选诺亚 == `se_auto_turret`；选莱恩 == `se_star_blade`；直开 `Main.tscn` 不报错

#### D2-T2【W2】英雄精灵字段收敛
- [ ] `data/characters.json` 为 9 英雄补 `sprite` 字段，替换 `character_select.gd` 中硬编码的 `PORTRAIT_ALIAS` 映射
- **测试点**：删除硬编码映射后角色选择界面立绘仍正确显示；缺图仍走占位色块降级

#### D2-T3【W3 / 环境项】英雄 PNG `.import` 生成
- [!] 9 张英雄 PNG 的 `.import` 需引擎导入生成（无头 `--quit` 不生成）；代码已优雅降级，**编辑器打开或出包时自动补全**
- 判定：**非阻塞**，不计入 Day 2 客观出口，编辑器一开即消解

#### D2-EXIT【W5】当日出口
- [ ] `python tools/baseline_check.py` → `BASELINE CLEAN`
- [ ] 三英雄各进局一次，起始武器命中率 3/3

### Day 3 — 主动技能机制
- [ ] 主动技能释放（冷却 / 资源）框架
- [ ] 艾琳火球、诺亚召唤炮台、莱恩环绕星刃差异化实现
- [ ] `baseline_check` 通过

### Day 4 — 经验 / 升级 / Build 初版
- [ ] 击杀掉经验、升级触发强化选择面板
- [ ] 10 属性强化项：攻击/攻速/范围/移速/暴击率/暴伤/生命/护甲/吸血/幸运
- [ ] `baseline_check` 通过

### Day 5 — 武器 6 槽挂载
- [ ] 自动攻击 + 武器挂载 6 槽逻辑（对齐大纲上限）
- [ ] 武器 Lv1-8 升级（伤害/数量/范围/攻速）
- [ ] `baseline_check` 通过

### Day 6 — 阶段 A 集成测试
- [ ] `baseline_check` 全绿 + 手感冒烟
- [ ] 平衡初调（基础数值）
- [ ] 产出阶段 A 报告 → `docs/PROGRESS.md`

---

## 阶段 B · Build 系统（Day 7–13）

### Day 7–9 — 15 武器数据 + 精灵
- [ ] 3 英雄签名武器（炎星术/自动炮台/星刃）Lv1-8 数据 + 精灵
- [ ] 12 通用武器 Lv1-8 数据 + 精灵
- [ ] 武器升级数值曲线填 `data/weapons.json`
- [ ] 每日常规 `baseline_check`

### Day 10 — 武器进化
- [ ] 进化机制：Lv8 + 对应核心装备 = 进化武器
- [ ] 示例：炎星术Lv8 + 烈焰核心 → 炎星陨落（陨石 AOE）
- [ ] `baseline_check` 通过

### Day 11–12 — 20 被动
- [ ] 4 类被动：攻击/防御/属性/特殊（示例 红宝石 攻击+20%）
- [ ] 6 被动槽装配逻辑
- [ ] `baseline_check` 通过

### Day 13 — Build 系统集成 + 数值冒烟
- [ ] 10 属性公式校验（攻击/暴击/吸血/护甲…）
- [ ] 进化链路、被动叠加边界测试
- [ ] `baseline_check` 通过；产出阶段 B 报告

---

## 阶段 C · 肉鸽系统（Day 14–20）

### Day 14–15 — 随机节点地图
- [ ] 节点拓扑：战斗 / 事件 / 精英 / 商店 / Boss
- [ ] 种子可复现随机生成
- [ ] `baseline_check` 通过

### Day 16 — 事件节点　【数据侧已由 08-04 并发冲刺预交付】
- [x] 文本选择事件 ×10（描述 + 选择A 奖励 + 选择B 改线）—— w4 已落盘（f78e29e），实测 `events.json` = `{events:[10]}`
- [x] 事件数据填 `data/events.json` —— JSON 校验通过，`effect_on_route` 负值为设计内代价（`TEST_REPORT` §5）
- [ ] **W1 剩余**：事件节点**代码逻辑**（弹窗 UI / 选项分支 / 奖励结算 / 改线）—— `scripts/` 全域尚无事件节点消费方
- [ ] `baseline_check` 通过

### Day 17 — 精英战斗
- [ ] 精英敌人特殊能力 / 强化属性
- [ ] `baseline_check` 通过

### Day 18–19 — Boss 腐化巨树 两阶段
- [ ] 阶段1：召唤藤蔓限制移动
- [ ] 阶段2：全屏毒雨
- [ ] 奖励：解锁森林区域
- [ ] `baseline_check` 通过

### Day 20 — 遗物 + 阶段 C 回归
- [ ] 遗物：破碎王冠（攻击+50%/受伤+30%）、机械核心（机械伤害+100%）
- [ ] 阶段 C 平衡回归；产出阶段 C 报告

---

## 阶段 D · 美术·音频·剧情整合（Day 21–26）

### Day 21–22 — 美术资产落地　【部分已由 08-04 并发冲刺预交付】
- [x] 3 英雄 二次元像素 Sprite（立绘表现 + 战斗帧 strip）—— w3 已落盘（7d39e75）：`elin/noah/lain` × `portrait/idle/walk` 共 9 张 PNG
- [ ] 敌人 / Boss（腐化巨树）精灵 —— **未开工**，`assets/sprites/enemies/` 仍为框架遗留素材
- [x] 遵守 `ART_STYLE.md`：32px 网格 / 32 色 / Nearest / 1px 描边 —— 规范已成文 `docs/ART_ANIME_SPEC.md`（16137 B）
- [ ] anime 方向调和（高饱和幻想色 + 华丽特效预留）—— 规范已定，**素材侧待 Day 23 VFX 一并落地**
- [!] 承接 D2-T3：9 张英雄 PNG 中 6 张缺 `.import`（仅 `fighter_idle/walk` 有），本日统一验收

### Day 23 — 华丽技能特效
- [ ] 火球 / 召唤 / 环绕 / 进化陨石 / 毒雨 VFX（粒子 + 闪白 + 霓虹点缀）

### Day 24 — 音频接入
- [ ] BGM / SFX / 空间音（占位或 `tools` 资源）

### Day 25 — 剧情文本　【已由 08-04 并发冲刺预交付】
- [x] 世界观（星骸/回响者联盟/苏醒悬念）—— w4 已落盘 `docs/LORE.md`（14075 B，f78e29e）
- [x] 10 事件文本、角色剧情解锁文案 —— 随 `data/events.json` 一并交付
- [ ] **剩余**：角色剧情**解锁条件**接线（依赖 Day 27 局外养成的角色培养系统）

### Day 26 — 整合校验
- [ ] 美术/音频/剧情与玩法整合
- [ ] 主观项标记给人工（→ `docs/PLAYTEST_CHECKLIST.md`）

---

## 阶段 E · 长期养成 + 测试·发布（Day 27–30）

### Day 27 — 局外养成
- [ ] 方舟基地 + 研究系统（永久 攻击+5% / 生命+10% / 幸运+5%）
- [ ] 角色培养（等级 / 技能升级 / 潜能突破 / 剧情解锁）
- [ ] `baseline_check` 通过

### Day 28 — 全量测试 + 性能
- [ ] 自动化测试 + 性能（帧率/内存/同屏敌人数）
- [ ] 回归 `baseline_check`；产出 `docs/TEST_REPORT.md`

### Day 29 — 人工试玩 + 修复
- [ ] **人工试玩**（手感/难度/乐趣/UI/视听/剧情）
- [ ] 收集反馈 → 修复关键缺陷 + polish

### Day 30 — 发布准备
- [ ] `python tools/build_release.py --zip`
- [ ] Steam 构建 / 导出 pck+exe / 存档兼容
- [ ] 资产库上传 `build`

---

## 需人工介入标记（自动化 #5 汇总到 `docs/PLAYTEST_CHECKLIST.md`）
- [ ] 手感「跟手」度
- [ ] 难度曲线体感（难/肝/无聊）
- [ ] 数值「好玩」度（Build 流派趣味）
- [ ] UI/UX 顺畅度与可读性
- [ ] 视觉/听觉主观感受（Anime 像素、华丽特效、音频氛围）
- [ ] 剧情文本调性
- [ ] 崩溃复现需真人路径
