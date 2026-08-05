# 《星骸回响》Star Echo · 阶段 A 核心循环集成报告（REPORT_PHASE_A）

> 生成：2026-08-06 01:5x（自动化 #3 Day 6 收口轮）｜文件域：W5（docs）
> 阶段 A = Day 1–6：框架基线 → 角色选择 → 主动技能 → 经验/升级/Build 初版 → 武器 6 槽 → 集成测试

---

## §1 阶段 A 六日回顾

| 开发日 | 主题 | 收口提交 | 状态 |
|---|---|---|---|
| Day 1 | 框架基线 & 差异清单（输入层打桩 `skill_cast` + `DIFF_FRAMEWORK_STARECHO.md`） | `7597d0b` | ✅ 收口 |
| Day 2 | 角色选择 + 3 英雄（hero id 消费 / 起始武器注入 / passive+penalty） | `edd0e9a`（32 断言 0 失败） | ✅ 收口 |
| Day 3 | 主动技能机制（SkillController：火球 / 炮台占位 / 星刃爆发） | `0dc2ece`（16/16 CLEAN） | ✅ 收口 |
| Day 4 | 经验/升级/Build 初版（经验曲线 / 升级面板 / 吸血 / 炮台 / HUD / GameOver / BUG-001 F1/F2） | `eb8e2f5`（21/21 CLEAN） | ✅ 收口 |
| Day 5 | 武器 6 槽挂载（查表升级 Lv1-8 / 环绕武器 / 混合升级面板） | `5092874`（15/15 CLEAN） | ✅ 收口 |
| Day 6 | **阶段 A 集成测试（T-A 经验链路数据化 + 端到端探针 + 平衡初调 + 报告）** | 见 §2 | ✅ 收口 |

**D6 集成结论**：阶段 A 核心循环（选角 → 进局 → 武器 → 击杀 → 经验 → 升级 → 技能 → 6 槽 → 死亡/重开）经端到端探针全链路验证通过（14/14），基线双阶段 CLEAN，无阻塞性缺陷。

---

## §2 集成测试结果

### D6-T3 端到端探针（`tools/day6_integration_check.gd`）

**14 项断言 0 失败 → `DAY6 INTEGRATION CHECK CLEAN`（exit 0）**

| 链路段 | 断言内容 | 结果 |
|---|---|---|
| 回归 D2-T1a | 无 meta 直开 Main → 兜底 well_rounded 进局零 error | ✅ |
| 回归 D4-T7 | die() → GameOver 面板 + paused == true | ✅ |
| 重开链路 | teardown 重开 → 新实例零 error | ✅ |
| D2 链路 | se_irene 首武器炎星术 + exp==0 + level==1 | ✅ |
| **T-A 收口** | 杀 chaser → exp == JSON exp_value（3，非 1）；杀 fly → 累计 6 | ✅ |
| D4 链路 | 累计跨 30 → level == 2 + level_up 信号触发 | ✅ |
| D3 链路 | try_cast 火球成功 + 二次进入冷却（false） | ✅ |
| D5 链路 | 6 槽装满 is_full + 第 7 把被拒 | ✅ |
| D4-T7 回归 | die → GameOver + paused | ✅ |

### 全量回归四件套（D6-T6 复验）

| 探针 | 断言 | 结果 |
|---|---|---|
| `day2_hero_check.gd` | 32 | ✅ 0 失败 |
| `day3_skill_check.gd` | 16 | ✅ 0 失败 |
| `day4_level_check.gd` | 21 | ✅ 0 失败（exp_value 数据化后断言兼容） |
| `day5_weapon_check.gd` | 15 | ✅ 0 失败 |

### 基线护栏

`python tools/baseline_check.py` → **BASELINE CLEAN**（import PASS + runtime PASS，exit 0 / stderr 0）

---

## §3 平衡结论（D6-T5 平衡对照表）

### 3.1 首升节奏（✅ 已校准，本日唯一数值调整）

**发现**：`stats.json.leveling.xp_per_level = "20 + current_level * 10"`，`current_level` 绑**当前等级** → **Lv1→2 实际需求 = 30**（不是拆解文案误读的 20）。数据化前 wave1 12 敌 × exp=1 = 12 经验，打满首波升不了级；按 20 定案补值后 wave1 = 28 仍 < 30，目标不成立。

**调整**（`data/enemies.json`）：

| 敌人 | 前值 | 后值 | 依据 |
|---|---|---|---|
| chaser | 2 | **3** | wave1 主力（8 只），首升目标 wave1 ≥ 30 的最小满足量 |
| charger | 3 | **4** | 保持「HP/威胁正相关」（hp 6 > chaser 3，不可同级） |

**校准后校验**：wave1 = 8×3 + 4×3 = **36 ≥ 30** ✓（首波结束升 1 级）；wave1+wave2 = 36 + (10×3+5×4+3×3=59) = **95 ≥ 30+40=70** ✓（第 2 波内升至 level 3）。梯度保持威胁/HP 正相关（chaser 3 … mad_slasher 15；elite 30–40；boss 400/500）。

### 3.2 敌人 scaling vs 玩家成长（登记观察项，不动数据）

四型常规敌 HP（`base + growth*wave`）：

| 敌人 | wave1 | wave6 | wave11 | wave16 | 玩家单武器 DPS 对照 | 判定 |
|---|---|---|---|---|---|---|
| chaser | 5 | 15 | 25 | 35 | Lv1 手枪 11.1 | ✅ 全程 <2s |
| fly | 11 | 26 | 41 | 56 | 同上 | ✅ 全程 <5s |
| bruiser | 30 | 80 | 130 | 180 | Lv4 签名 ≈ 20-25 | ⚠️ wave11+ 单武器口径 >5s |
| slasher | 70 | 170 | 270 | 370 | Lv8 签名 ≈ 40+ | ⚠️ wave11+ 单武器口径 ~10s |

**结论**：wave1–3 无断层（wave3 最厚 bruiser 30/11.1 ≈ 2.7s < 5s ✓ 测试点满足）。wave11+ 高 HP 敌在「单武器口径」下 >5s，但**未计入** 6 槽多武器齐射 + 属性加成 + 技能爆发 → 合成 DPS 远超单武器，无实测证据确证失衡，**登记为观察项**（归 Day 13 公式统一决策时复核），不臆造调值。

### 3.3 Boss 数值（登记观察项，不动数据）

| Boss | 出场波 | HP | 玩家合成 DPS 粗估 | 击杀时间 | 判定 |
|---|---|---|---|---|---|
| invoker 召唤者 | wave 10 | 8000 | 4-5 槽 ≈ 80-100 | 60-90s | ⚠️ 边缘，可接受 |
| predator 掠食者 | wave 20 | 15000 | 6 槽 Lv8 ≈ 240 | ~62s | ✅ 合理 |

**结论**：Boss HP 与出场波次匹配，击杀时间在 60-90s 区间（无硬时限失败机制，可接受），不调。

### 3.4 三英雄 penalty 后基准（✅ 可接受）

| 英雄 | penalty 后基准 | 对照 | 判定 |
|---|---|---|---|
| 艾琳 | max_hp 90 | 普通敌伤害 3-8 → 可承受 11-30 次 | ✅ |
| 诺亚 | attack_speed 0.85 | 换召唤流上限（3 炮台 ≈ 30 DPS） | ✅ |
| 莱恩 | range -20 | 换近战高伤（星刃 7/0.5s ≈ 14 + 环绕） | ✅ |

### 3.5 经济（登记观察项，不动数据）

`items.json` 47 项 price 8–120（最便宜 8）；wave 波间金币 `5+wave*2`（wave1 结束 7 金币 < 8 → 首购需等 wave2 后）。**登记**：开局首波结束买不起商店最便宜道具（属可接受的「先打后买」节奏，若试玩反馈差归 Day 13 经济统一调整）。

---

## §4 遗留风险

1. **经验曲线后续校准**：`20 + current_level*10` 在 level 10 后需求陡增（20+10×10=120）——是否需二次校准归 Day 13 数值体系统一决策（本日只校准了首升段）。
2. **29 把旧武器缺 `level` 升级表**（仅 3 签名武器 + pistol 有/无表）：Day 7–9 批量补数据。
3. **Boss 击杀时间复核**：invoker 边缘（60-90s），待实际试玩确认（→ PLAYTEST）。
4. **wave11+ 高 HP 敌击杀时间**：单武器口径 >5s，待合成 DPS 实测定论。
5. **主观项指针**：手感冒烟 / 阶段 A 整体手感 / 升级节奏体感 → `PLAYTEST_CHECKLIST.md`（H-01/H-02/H-03 已在），不阻塞本日出口。
6. **D6-T4（经验可见性）已实装**：击杀经验飘字「+N」（方案 A，0.6s 上浮淡出），容器缺失静默跳过——供试玩验证体感。

---

*报告域：W5（docs/REPORT_PHASE_A.md 独立成文，避免与 #1 独占的 PROGRESS.md 双写冲突）*
