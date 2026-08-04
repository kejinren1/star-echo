# 《星骸回响》Star Echo · 每日可执行任务清单（TASKS）

> 供自动化 #2（任务拆解）更新、#3（方案确定与执行）读取实现。
> 状态标记：`[ ]` 未开始 · `[~]` 进行中 · `[x]` 完成 · `[!]` 受阻/需人工。
> 护栏：未定义当日任务前不写游戏代码；改前 git commit；改后跑 `tools/baseline_check.py`。

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

**待办（Day 2 起）**：
- [ ] `Main` 侧消费 hero id：把选中英雄的初始武器/被动/精灵接入 `Player` / `WeaponController`（w1 已预留 `CharacterSelect.get_selected_character_id()` 读取 meta）
- [ ] 英雄 PNG 的 `.import` 由引擎导入生成（无头 `--quit` 不生成；代码已优雅降级，编辑器打开或出包时自动补全，portrait 即显示）

---

## 阶段 A · 核心循环对齐 & 手感打磨（Day 1–6）

### Day 1 — 框架基线 & 差异清单
- [x] 跑 `python tools/baseline_check.py`，确认输出 `BASELINE CLEAN`（集成节点复验 2026-08-04）
- [ ] 核对大纲 §5 操作（移动 / 主动技能 / 自动攻击）与现有输入映射
- [ ] 产出 `docs/DIFF_FRAMEWORK_STARECHO.md`（框架 vs Star Echo 差异清单）
- [ ] 确认 `data/characters.json`(6) / `weapons.json`(29) / `items.json`(39) 现有结构可复用

### Day 2 — 角色选择 + 3 英雄
- [ ] 实现角色选择场景/界面（3 英雄：艾琳 Mage / 诺亚 Summoner / 莱恩 Melee）
- [ ] 绑定初始武器：炎星术 / 自动炮台 / 星刃（数据驱动，帧 strip PNG）
- [ ] 专属技能占位：火球 / 召唤炮台 / 环绕星刃
- [ ] `baseline_check` 通过

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
- [ ] 产出阶段 A 报告 → `docs/PROGRESS_LOG.md`

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

### Day 16 — 事件节点
- [ ] 文本选择事件 ×10（描述 + 选择A 奖励 + 选择B 改线）
- [ ] 事件数据填 `data/events.json`
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

### Day 21–22 — 美术资产落地
- [ ] 3 英雄 二次元像素 Sprite（立绘表现 + 战斗帧 strip）
- [ ] 敌人 / Boss（腐化巨树）精灵
- [ ] 遵守 `ART_STYLE.md`：32px 网格 / 32 色 / Nearest / 1px 描边
- [ ] anime 方向调和（高饱和幻想色 + 华丽特效预留）

### Day 23 — 华丽技能特效
- [ ] 火球 / 召唤 / 环绕 / 进化陨石 / 毒雨 VFX（粒子 + 闪白 + 霓虹点缀）

### Day 24 — 音频接入
- [ ] BGM / SFX / 空间音（占位或 `tools` 资源）

### Day 25 — 剧情文本
- [ ] 世界观（星骸/回响者联盟/苏醒悬念）
- [ ] 10 事件文本、角色剧情解锁文案

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
