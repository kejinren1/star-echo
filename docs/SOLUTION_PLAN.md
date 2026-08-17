# 方案计划（2026-08-17 · 第 24 轮 · PS 批 D 收口：boss_layers 裁决已拍板方案② + D2a 章末事件 + D3 章界）

## 当前开发日：玩家侧技能系统批 D（章节化收尾）

> **git 实测**：HEAD=`e8a8cf1`（#2 第 48 轮拆解提交：PS-D2 细化拆 D2a/D2b + D3 章界函数级 + 头部状态块）。工作区在途 = 52 资产文件 M（assets/sprites/** + data/items.json + icon_atlas.gd 等，**AI 美术资产 v2 实装期用户会话在途**，非本岗产物不碰；docs 4 M 含 GameData.xlsx = #1/#2 在途）。
> **PS 系列状态**：批 A `ce1cc0c` / 批 B `36bf5e1` / 批 C+E `e0e27b0` 全 [x] ✅ ｜ 批 D `e9f4289` 部分落地（chapters 4 章定义 3/4/4/4 + 章末类型章1=event 章2-4=boss 数据层 ✅ + day31_chapter_check 5/5 + runner 51→52 + 回归 **52/52 全绿 BASELINE CLEAN**）｜ **⛔ boss_layers 映射调整执行阻塞 = 本轮方案核心**（F-27 双 Boss [9,14] vs 章节化三 Boss [6,10,14] 冲突，交方案师裁决）。
> **F 区块状态**：F0~F5 全 [x] ✅（阶段 F 全闭）｜ F1-E [ ] 🏠 主窗口承接 ｜ **PS 批 D 为全局唯一剩余 [~]**。
> **P0 检查（P0 调度硬性输入）**：追踪区增量 #69（08-16 00:5x · 反馈专员：无待处理反馈轮）= F-01~F-39 全 🟢 已落地·待真人回归（主观项交 #5）+ PS 主观项按约定归 PS-EXIT 登记 → **🔴 P0 无新增 / 🟠 无用户拍板调度指令 → 无新机器可验证 P0 需拆**。
> **本轮判定**：#2 第 48 轮已函数级细化拆解 D2a/D3（零裁决依赖可先行）+ D2b（阻塞标注）→ 方案师职责 = **① 对 boss_layers 冲突给出裁决 ② D2a/D3 落地方案定案**。**裁决已获用户拍板（2026-08-17 00:3x 主窗口）：方案② 三 Boss [6,10,14] ✅ → D2b 阻塞解除，全批 D 解锁**；用户同时确认前瞻兼容性（章节转场 / 事件跳关 / 关卡拉长均不受影响，见 §1.4）。规则 5 合规（任务已拆解）。

---

## §0 状态快照（本轮各观察点）

| 观察点 | 状态 |
|---|---|
| 回归基准 | **52 件套 · ≥1046 断言**（runner 52 项全绿；TEST_REPORT #47 3 FAIL 已由 F5-T1 动态读取修复） |
| PS 批 D | [~] chapters 数据层已落地；D2a 章末事件 [ ] / D2b Boss 位 [ ]（阻塞）/ D3 章界 [ ] / D4 探针 §4 待扩 / EXIT [ ] |
| 裁决点 | **boss_layers 双 Boss [9,14] vs 三 Boss [6,10,14] → ✅ 用户已拍板方案②（三 Boss）**（2026-08-17 00:3x 主窗口）→ D2b 解锁 |
| F1-E | 🏠 主窗口承接维持（阶段 F 唯一保留项） |
| 在途资产 | 52 个 assets/sprites/** + 游戏代码 M（用户会话）——D2a/D3 纯代码层零 items 锚点耦合，不受阻 |
| P0 | 无新机器可验证项（F-01~F-39 全 🟢 待真人回归 = 主观项交 #5） |

---

## §1 boss_layers 冲突裁决（✅ 已拍板方案② 三 Boss · 2026-08-17 00:3x 用户主窗口确认）

### 1.1 冲突事实

- **F-27（2026-08-08 用户拍板）**：15 层双 Boss，`boss_layers=[9,14]`（第 10/15 关），双 Boss 共用 wave 10 invoker 配置（「第二个 Boss 形象数值与第一个一模一样」）。
- **PLAYER_SKILL_SPEC §8（2026-08-14 用户拍板 D1-D7）**：4 章 3/4/4/4 层（章1=1-3 / 章2=4-7 / 章3=8-11 / 章4=12-15），章 1 章末事件无 Boss、章 2-4 章末 Boss → 三 Boss 位 = 1-based 第 7/11/15 关 = **0-based [6,10,14]**。
- chapters 数据已落地（`e9f4289`，routes.json 实测：layers=15 / nodes_per_layer=3 / boss_layers=[9,14] / boss_wave=10 / chapters 4 章 end_type 章1=event 章2-4=boss）。

### 1.2 裁决结论：**✅ 已拍板方案② 改三 Boss [6,10,14]**（2026-08-17 00:3x 用户主窗口确认：「方案②吧。本质就是 3BOSS」）——D2b 阻塞解除，落地路径见 §4。

论证（按权重排序）：

1. **数据自洽性（决定性）**：chapters 数据已声明章 2-4 以 Boss 收尾。保留双 Boss [9,14] 时——章 2/3 末层（层 7/11）声明 boss 但实际无 Boss，章 4 内层 14 有 Boss 但非末层 = **数据层自相矛盾**。D2a 消费 chapters 强制末层类型时：层 7/11/15 被强制 boss 而 boss_layers 仍含 9/14 → **5 个 Boss 节点**（且层 7/11/15 为 3 节点层内嵌 boss，语义混乱）。方案① 唯一修补路径 = 重划章节边界（违背 §8 层数 3/4/4/4）或改 chapters end_type（违背规格）——两路都是结构妥协。
2. **时间线**：§8 为 08-14 更新的用户拍板，章节化是更完整的框架（章节节奏/章 Boss 掉落教学闭环），boss_layers 属于其落地数据细节，应服从新框架。
3. **F-27 核心诉求保持**：15 关不变；Boss 数 2→3（新增第 7 关、第 10 关移至第 11 关）；**第 14 层 Boss 保留**（F-27 的 [9,14] 中 14 ∈ 三 Boss 位 [6,10,14]）；「复用同一 Boss 配置」精神扩展 = 3 个 Boss 层共享 `boss_wave=10` invoker 配置（**route_generator.gd :118 `node_data["wave_index"] = boss_wave` 天然支持多 boss 层共享 wave**，零代码改动）。
4. **教学闭环**：PS-C2「章 Boss 必掉招牌技」已实现——三 Boss 提供 3 个掉落落点（每章一个位移技），双 Boss 只有 2 个且第 10 关 Boss 落在章 3 中间语义错位。
5. **节奏递进**：Boss 间隔 6/5/4 关渐进缩短（第 7→11→15 关），比双 Boss（间隔 9/6 关）更符合 roguelike 压力递进；E-0 终审局长度不变（15 关）。

### 1.3 兜底（若用户坚持双 Boss）

~~方案① 落地路径~~ —— **已弃用**：用户已拍板方案②，本节保留仅作决策记录。方案① = 保留 boss_layers [9,14] + **chapters end_type 修正**（章 2/3 end_type 改非 boss 标记，如 `"elite"`；章 4 保持 boss）→ D2a 只对 end_type 匹配层生效。代价：章 2/3 无 Boss 收尾（章节节奏感弱）、与 §8 规格文字偏离、章 Boss 掉落落点仅 1 个。**不推荐，数据矛盾与规格偏离成本大于三 Boss 收益**。

### 1.4 前瞻兼容性确认（用户 00:3x 提问 · 方案师核答）

用户确认方案②同时问：「后期章节转场 / 事件影响跳关 / 关卡长度进一步拉长，会不会受影响？」——**核答：均不受影响，且数据驱动架构下更稳**：

1. **章节转场（后期）**：零影响。转场消费 chapters 数据（D3 章界已铺路：每章起始层横幅；章末转场同理读 end_type），与 Boss 数量无关；三 Boss 对齐后 chapters 结构完整（4 章 × layers + end_type），转场逻辑只需读 chapters，天然成立。
2. **事件影响跳关（后期）**：零影响且受益。route_generator reroute 接口（:144-149）已内置「Boss 层不可跳」守卫（`from_layer in boss_layers` 拒绝）——三 Boss 后守卫自动覆盖 3 个 Boss 层（第 7/11/15 关不可被事件跳过），比双 Boss 覆盖更全。**若未来要设计「事件可跳 Boss 关」的高级事件，那是显式的设计决策，需改 reroute 守卫逻辑，与当前方案无冲突**（登记 T 债备查）。
3. **关卡长度拉长（后期）**：零影响且受益。15 层 → N 层只需改 routes.json layers + chapters 定义（如加第 5 章），boss_layers 随章节末层同步即可——**前提 = §4 新增 D2b-0 一致性校验护栏**（见下），杜绝本次「boss_layers 与 chapters 不同步」类冲突复发。
4. **结构收益**：三 Boss 后「Boss 位」与「章节结构」完全对齐，未来任何章节级机制（转场/整备节点/章节奖励）都只依赖 chapters 单一数据源，Boss 数不再是与章节逻辑耦合的独立变量。

---

## §2 PS-D2a 章末事件节点（分两段：D2a-1 零裁决依赖可先行 / D2a-2 依赖裁决）

> ⚠️ **方案师修正 #2 拆解粒度**：拆解把整个 D2a 标「不依赖裁决」，**不成立**——「章 2-4 末层强制 boss」在 boss_layers 未裁决前落地会制造 5 Boss 冲突（见 §1.2 论证 1）。修正为：**D2a-1 章 1 末层事件 = 零依赖可先行；D2a-2 章 2-4 末层 Boss = 依赖 D2b 裁决**（裁决方案②后由 boss_layers 数据驱动天然生效，零代码）。

### 任务1：D2a-1【W1】章 1 末层事件节点（零裁决依赖 · 可先行）
- 文件：scripts/systems/route_generator.gd（实测：生成主循环 :84-96 / 波次分配 :109-118 / boss 层单节点先例 :85-87）
- 改动：
  ① 生成前置读 `routes.get("chapters", [])` → 构建 `chapter_end_map: Dictionary = {层号: end_type}`（chapters 缺省空 → 空字典，旧 routes.json 零改动兼容）；
  ② 生成循环 :84-96 内新增分支（boss 层分支 :85-87 同构）：`if chapter_end_map.has(li) and chapter_end_map[li] == "event": layers.append([{"type": NODE_EVENT, "wave_index": 0}]); continue` —— **章 1 末层（层 3）= 单 event 节点层**（与 boss 层单节点同构，符合「章末节点」语义）；end_type=="boss" 的层**不在此分支处理**（归 D2a-2/boss_layers）；
  ③ 波次分配 :109-118：event 节点 wave_index 保持 0（现有逻辑已覆盖，零改动）；
  ④ 章末事件内容 = 复用现有事件面板/奖励结算 10 型（GameManager `_start_event` 链路 D16 已通）——章末事件语义「休息 + 奖励」：heal 全量 or 金币 or 属性，**优先复用 events.json 现有条目**（零新数据）；如需专属条目走 Excel events sheet（data_schema.py 注册）→ excel_export.py，**禁手改 data/events.json**。
- 风险：中——**章 1 末层节点数 3→1 触及 day14_15 探针「普通层节点数 == nodes_per_layer」断言（:176-191 实测仅豁免 boss 层）** → 必须同步豁免章末 event 层（见 §5 探针清单）；battle_count 上限 :121（36）不受影响（减少 2 战斗节点只会更安全）。
- 验证：day31_chapter_check §4a 新增断言（章 1 末层单 event + wave_index==0）+ day14_15 53/53（豁免同步后）+ 回归 52 件套。

### 任务2：D2a-2【W2】章 2-4 末层 Boss（依赖裁决 · 阻塞标注）
- 文件：docs/GameData.xlsx routes sheet（数据层，零代码）
- 改动：**裁决方案②落地后** = boss_layers [9,14]→[6,10,14]（Excel 改列 → excel_export.py → data/routes.json），层 7/11/15 由 route_generator :85 boss 层分支天然生成单 Boss 节点 → **D2a-2 零代码，纯数据驱动**；3 Boss 层共享 boss_wave=10（:118 天然支持）。
- 风险：见 §4 D2b（同任务，探针锚点同步 4 处）。
- 验证：见 §4。

---

## §3 PS-D3 大地图章界（零裁决依赖 · 可先行）

### 任务3：D3【W1】章界横幅/分隔线
- 文件：scripts/ui/route_select_panel.gd（G-R1 已落地 183 行，实测 setup/网格画布/_layout_pos/_render/_draw_paths 结构）
- 改动：`setup()` 读 `route.chapters`（DataLoader.get_routes 已解析，缺省空 → 零显示零改动兼容旧 routes.json）→ 每章起始层（1/4/8/12）上方渲染**章界横幅**（Label「第 N 章」+ Line2D 分隔线，数据驱动）。
- **硬门槛（G-R1 承接）**：不动画布架构/布局函数——`_layout_pos` / `_render` / `_draw_paths` 语义零改动；**day30_g_map 20/20 零改动**（实测 grep 确认 day30_g_map 无 boss_layers 硬引用，章界为纯新增渲染层）。
- 占位标准 = 色块 + Label 零美术（08-07 策略遵守）。
- 风险：低——纯新增渲染层；唯一坑 = 章界节点挂载时机（setup 后/渲染前，防与已有节点 z 序冲突）。
- 验证：day31_chapter_check §4b 新增断言（章界横幅节点数 == chapters 数 + 起始层位置正确）+ day30_g_map 20/20 零改动实证 + 回归 52 件套。

---

## §4 PS-D2b 章 Boss 位映射落地路径（✅ 已拍板方案② · 阻塞解除 · 可执行）

### 任务4：D2b-0【W1】一致性校验护栏（防复发 · 本次冲突根因教训）
- 文件：tools/day31_chapter_check.gd（新增 §5 断言）或 tools/excel_export.py（--check-only 校验）
- 改动：新增机器校验「**boss_layers 数组 == 由 chapters 推导的章末 Boss 层集合**」（chapters 中 end_type=="boss" 的章末层 → 0-based 集合；两处数据不一致即红）。推荐放 day31_chapter_check §5（探针域，免动 Excel 管线）；若放 excel_export --check-only 则登记 data_schema 校验链。
- 风险：低——纯新增校验，零行为影响。
- 验证：改坏一个数据 → 探针红；恢复 → 绿。

### 任务4：D2b【W2】boss_layers → [6,10,14]（✅ 已拍板 · 可执行）
- 文件：docs/GameData.xlsx routes sheet boss_layers 列 + tools/excel_export.py（唯一事实源管线，data/*.json 禁手改）
- 改动：boss_layers 列 [9,14] → [6,10,14] → excel_export --check-only → 导出 → data/routes.json。
- **探针锚点同步清单（实测 4 处，供 #3 免排查）**：
  1. **tools/day31_chapter_check.gd**：:91-101 §3 boss_layers 断言 `[9,14]` → `[6,10,14]` + 注释 :12/:99 更新（「维持 F-27 双 Boss」→「章节化三 Boss」）；
  2. **tools/day14_15_route_check.gd**：:178-201 boss_layers 读取 +「boss 仅 boss_layers 层」断言（:193-201 注释「第 10/15 关」→「第 7/11/15 关」）+ :247「boss → wave_index == 10」（保持，3 Boss 共享 wave10 不变）+ 注释 :176 更新；
  3. **tools/day18_feedback5_check.gd**：Boss 关判定锚点（15 关拓扑 + 双 Boss wave10 断言）——#3 grep `boss\|wave_index\|10\|15` 核实行号后同步（第 10 关 Boss → 第 7/11/15 关三处）；
  4. **tools/day30_g_map_check.gd**：实测无 boss_layers 硬引用（本轮 grep 零命中）——#3 复核一遍，若仅引用节点类型则零改动。
- **wave_index**：3 boss 层共享 boss_wave=10（route_generator :118 天然支持）→ 零改动；F-28 通关判定（Boss 关击杀即通）按 node.type 判断不依赖数组长度 → 零改动。
- 风险：高（触及 day14_15/fb5/g_map 三探针 + F-27 拍板**已由用户复核同意**）——**兜底**：① 先改数据 → 逐探针验证（禁一次改完再验，第 23 轮 R5 口径）② 探针红 → 回滚 Excel 改回重导出（代码零改动）。
- 验证：day14_15 53/53 + day18_feedback5 27/27 + day30_g_map 20/20 + day31_chapter_check（§3 锚点更新后）全绿 + 回归 52 件套 ≥1046 + baseline **BASELINE CLEAN**。

---

## §5 探针扩展（day31_chapter_check §4）

### 任务5：D4 扩展【W1】§4 章末事件 + 章界断言（≥5 断言，D2a-1 + D3 落地后）
- 文件：tools/day31_chapter_check.gd（现有 5/5：§1 数据层 / §2 拓扑 / §3 兼容）
- 改动：新增 §4a 章末事件（章 1 末层单 event 节点 + wave_index==0 + 类型 ∈ 合法集；白盒直构造 route 或调 route_generator 生成后断言）、§4b 章界显示（route_select_panel 实例化后断言章界节点数 == chapters 数 / 首章起始层 1 横幅在场）。
- 风险：低——纯探针扩展；白盒范式沿用 day14_15 端到端先例。
- 验证：探针全绿 + 回归 52 件套。

---

## §6 执行序汇总（#3 每批一收口 commit）+ 风险表

### 执行序
1. **批 1（零裁决依赖，可立即开工）**：D2a-1 章 1 末层事件（route_generator 分支 + day14_15 探针豁免同步 + day31_chapter §4a）→ D3 章界（route_select_panel + day31_chapter §4b + day30_g_map 20/20 零改动实证）→ 探针扩展 §4 → 回归 52 件套 + baseline 收口 commit。
2. **批 2（✅ 已拍板，可立即执行）**：D2b-0 一致性校验护栏（day31_chapter §5）→ D2b boss_layers → [6,10,14]（Excel → 导出 → 4 探针锚点同步）→ 逐探针验证 → 回归 52 件套 → **PS-D-EXIT**（52 件套 ≥1046 + BASELINE CLEAN）。
3. **PS-EXIT 总收口**：批 A-E 全 [x] + PLAYTEST 主观项登记（多技能位手感 / 位移走位 / 掉落节奏 / 章节节奏 / 剑士剑气）+ 新债登记（如有）。
4. **裁决登记（已完成）**：boss_layers 三 Boss 方案② 已获用户主窗口拍板（2026-08-17 00:3x），论证与前瞻兼容性核答见 §1.2/§1.4——**D2b 无阻塞，批 1/批 2 可并行推进**。

### 风险表

| # | 级别 | 风险 | 缓解/兜底 |
|---|---|---|---|
| R1 | 🟠 中 | D2a-1 章 1 末层 3→1 节点触及 day14_15「普通层节点数」断言（:176-191 仅豁免 boss 层） | 探针同步豁免章末 event 层（与 boss 层同构）；battle_count 只减不增无上限风险 |
| R2 | 🟢 低 | ~~D2b 裁决未决~~ **已拍板方案②**（2026-08-17 00:3x） | 阻塞解除；D2b-0 一致性校验护栏防复发（本次冲突根因教训） |
| R3 | 🟢 低 | D3 章界动画布架构 | 硬门槛：_layout_pos/_render/_draw_paths 语义零改动 + day30_g_map 20/20 零改动实证 |
| R4 | 🟢 低 | 工作区 52 资产在途耦合 | D2a/D3 纯代码层零 items 锚点引用，无耦合；锚点同步类任务避让资产文件 |
| R5 | 🟠 中 | 探针锚点同步遗漏（day18_feedback5 行号待 #3 grep 实测） | §4 已列 4 处清单 + 逐探针验证 + 红即回滚数据 |

---

## §7 回归基准与观察点

- 回归基准：**52 件套 ≥1046 断言** 维持（批 1 收口）→ 批 2 后 52 件套（探针数量不变，锚点值变化）→ **PS-EXIT 52 件套 + PLAYTEST 主观项登记** = 玩家侧技能系统全闭。
- 观察点（下轮）：#3 是否按批 1 + 批 2 开工 D2a-1/D3/D2b（git HEAD 实测 + route_generator 章末分支在盘 + day31_chapter §4/§5 扩展 + boss_layers 落 [6,10,14]）；资产 52 在途是否入库。
- 工作流硬性：只按 PLAYER_SKILL_SPEC.md + 本方案 + TASKS 拆解执行，禁止单条对话动工（08-12 教训）；数据改动一律 Excel → excel_export.py（--check-only 校验）。
- 红线遵守：本方案不写码 / 不改 .gd/.tscn/.tres/.json / 不 commit / 不跑探针；产出仅 SOLUTION_PLAN.md + TASKS 标注 + 记忆文件。

## 执行结果：完成
- D2a-1 章1末层 event、D3 章界横幅、D2b-0 章节 Boss 一致性护栏已落地；Excel routes 的 `boss_layers` 已按拍板方案导出为 `[6,10,14]`。
- 验证：`excel_export.py --check-only` 通过；章节探针 11/11；路线探针 54/54；反馈探针 28/28；大地图探针 20/20；全量回归 52/52，无脚本错误。
- 本轮未触碰用户会话在途的美术/资产文件；PS-D 后续仅剩主观试玩项登记与 PS-EXIT 文档收口。