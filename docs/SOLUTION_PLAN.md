# 方案计划（2026-08-19 20:4x · 方案师第 39 轮 · RELIC-A 收口确认（RELIC 首批落地 · 跨 8 轮挂账部分解除）+ 无新任务需方案化 + RELIC 剩余 7 批 / LD-C 跨 4 轮挂账观察 + 回归硬门槛 65 件套 1692 锚点）

## 📌 本轮判定（方案师第 39 轮）

> **高峰检查**：20:37 不在 09-12/14-18 高峰 → 正常执行。
>
> **P0 检查（PLAYTEST 追踪区增量 #89 之后无新增量 · 反馈专员 4h 轮 06:38/10:38/14:38/18:38 全空转零产出符合 D-018，git 无 #90 提交）**：F-45~F-49/AF-P0 全 🟢 已修复·待真人回归；🟡 仅 H-05 家族主观审阅域（非机器可执行）→ **🔴P0 无新增 / 🟠 无用户拍板调度指令 → 无新机器可验证 P0 需纳入本轮**。
>
> **git 实测**：HEAD=`39662ba`（#2 第 69 轮拆解回执 · 20:00；第 38 轮方案后 +4 = **#3 执行者第 69 轮 RELIC-A 全收口 2 commits**：`765e3bc` A1+A2（**Excel stats 两行 name 改名——元素伤害→魔法伤害 / 工程学→机械学，id 零改动** + characters/elements 文案同步 + desc_builder STAT_CN 两键同步统一机械学 + data_schema label 同步 + 导出三 JSON 仅文案变其余零 diff；执行登记：elements effect 文本属性名引用同属展示残留实测补一处）+ `74ad1fd` A3+EXIT（**day31_relic_name_check 15/15**：§1 stats 两 name 新值 + base 保持 + 全量零残留 / §2 desc_builder STAT_CN / §3 attribute_controller 源码 id 锚点（不 preload 引用 Autoload = 探针三坑①）/ §4 characters 两处 / §5 elements effect+scaling_attr id 零改动 + **runner 64→65 件套** expect15 + **day26 锚点 1677→1692** + **回归 60/65（5 FAIL = D-26 用户会话在途零新增）** + RELIC-A1~EXIT 全 [x] + SOLUTION_PLAN 第 69 轮执行结果））+ `7aa89fa` #1 进度分析第 73 轮（RELIC-A 收口确认 + 跨 7 轮挂账部分解除 + 摘要刷新）+ `39662ba` #2 第 69 轮回执（RELIC-A 收口确认 + RELIC-0/F/E/B/C/D/EXIT 与 LD-C/E/D 已拆已定案待 #3 + 登记无待拆不空转 + Day30 区第 69 轮确认块 + 回归硬门槛 65 件套 1692 锚点））；**工作区在途 = 用户会话美术资产（lain 动画帧 ×8 + art_ai 工具 ×5 + `player_anim.gd`/`sprite_frame_factory.gd` M = **D-26 回归阻塞源** + 人物动画/ 摩托车/ 未跟踪目录）+ `docs/TEST_REPORT.md` M（#4 在途）——非本岗改动面，红线内不碰**。
>
> **本轮核心产出 = RELIC-A 收口确认（RELIC 首批落地 · 跨 8 轮挂账部分解除）+ 无新任务需方案化 + 挂账刷新**：
> 1. **RELIC-A 收口确认**（`765e3bc`+`74ad1fd` 全 [x]）：stats 两 name 新值（**魔法伤害/机械学**）+ id 零改动 + 全量零残留（§1 base 保持）+ desc_builder STAT_CN 两键同步（统一机械学 = 第 31 轮方案「硬编码映射改名两处同步」兑现，消除「工程」vs「工程学」2/3 字不一致）+ day31_relic_name_check **15/15** + 回归 65 件套 60/65 挂 D-26 零新增 → **RELIC 首批落地，第 31 轮方案 RELIC-A 部分兑现**（方案锚点：stats.json .stats.offensive[2]/.stats.economy[3] + desc_builder.gd:32-33 硬编码映射全部按方案执行）；
> 2. **回归硬门槛口径更新 = 65 件套 · 1692 锚点**（RELIC-A3 runner 扩容；**当前 60/65 5 FAIL = D-26 用户会话在途 `set_frame_offset`（Godot 4.4 API · 4.3 无此方法）误用**，D-020 不代修待收口，与 #63~#68 同根因零新增——**所有挂账批次 EXIT 门槛统一挂 D-26 复跑恢复 65/65 后全绿**）；
> 3. **无新任务需方案化**：RELIC 剩余 7 批（0/F/E/B/C/D/EXIT）+ LEVEL_DESIGN LD-C/E/D 均为「拆解+方案齐备」状态**不重写**；阶段 F 真全闭（7/7）无后续批次；D30 尾项纯 Owner/#4 域无方案 → **本轮为状态确认轮 + 挂账刷新**（与第 28/29/38 轮先例一致）。

## 当前开发日：Day 31（RELIC + LEVEL_DESIGN 同窗口 · 承接方 #3 · 方案已定不重写）

### 任务1：RELIC 遗物扩展——RELIC-A 已收口 · 剩余 7 批挂账观察（跨 8 轮挂账部分解除）

- **现状**：RELIC-A1/A2/A3/EXIT 全 [x]（`765e3bc`+`74ad1fd`，见上）→ **跨 8 轮零开工挂账部分解除（RELIC 首批落地）**；**剩余 RELIC-0（数据地基）/ F（Boss 行为节奏）/ E（Boss 宝箱收获）/ B（套装遗物）/ C（遗物图鉴+条件解锁）/ D（流派遗物树+动态权重）/ EXIT 仍 [ ] 待执行**（全部已拆已定案，承接方 = #3 执行者直接执行，方案 = SOLUTION_PLAN 第 31 轮不重写）。
- **执行序**（第 31 轮定案不变）：RELIC-0 先行（B/C/D 依赖）→ RELIC-F/E（P0 独立）→ RELIC-B/C/D → RELIC-EXIT；⚠️ F-49 传送门+宝箱地基已落地（`4f1e791`），RELIC-E 落地时宝箱奖励升级三选一零重做（#2 第 66 轮已加注 RELIC-E1 行衔接）。
- **风险**：低-中（方案已定；RELIC-A 收口证明 #3 已在推进本窗口，剩余批按执行序推进即可，唯一变数 = 执行排期节奏）。

### 任务2：LEVEL_DESIGN LD-C/E/D——挂账观察（LD-C 跨 4 轮）

- **现状**：LD-A（`96e4cd5`）+ LD-B（`b213296`）双收口；**LD-C（Boss 演出）/ LD-E（attr）/ LD-D（可选）仍 [ ] 零开工**（git 无 boss_phase_player.gd/attr 分支提交）→ **挂账观察（LD-C 跨 4 轮）**，承接方 = #3 执行者（方案已定 SOLUTION_PLAN 第 32 轮，锚点复核 9 项一致不重写）。
- **执行序**（第 32 轮定案不变）：LD-C Boss 演出（boss_phase_events 表消费，硬门槛 day18_19 48/48 + day30_boss_skill 49/49 零改动）→ LD-E attr 正向状态（5 旧类型行为零漂移 + attr 纯新增分支）→ LD-D 特殊波可选挂 TECH_DEBT_PLAN（D-014 拍板）。
- **风险**：中（消费端 + 演出面）；方案已定不重写；RELIC 执行序排前时 LD-C 顺延属正常调度。

### 任务3：D30-T3 上传 + D30-EXIT 发布收口——纯 Owner/#4 域，无需方案

- **改动**：无（本岗红线：外部动作 + 测试岗产出）。D30-T3 上传 [ ] = 等 Owner 明确确认（目标资产库，上传属真正外部动作红线不变）；D30-EXIT [~]/[ ] = TEST_REPORT 发布摘要待 #4 落盘 + 最终标记。
- ⚠️ **build/ 观察维持**：08-18 23:22 产物（`2aeb717`：含 F-45~48 + F1-E-4-1，**不含其后 F-49 + F1-E-4 消费端 + LD-A/B + 批五/六/七 + RELIC-A**）→ 传送门/宝箱/批四抽表/LD/批五~七/RELIC-A 验证需最新代码或下次打包（D-016 授权自动替换已生效，等 #3/总指挥产出新版本后归档重导出，全程不再询问）。

### 风险总表（本轮）

| 任务 | 风险 | 说明 / 替代方案 |
|---|---|---|
| RELIC-A 收口确认 | 低 | `765e3bc`+`74ad1fd` 全 [x]（15/15 + 65 件套 1692 锚点）；RELIC 首批落地，跨 8 轮挂账部分解除 |
| RELIC 剩余 7 批 | 低-中 | 方案已定（第 31 轮）；执行序 0→F/E→B/C/D→EXIT，承接方 #3 |
| LD-C/E/D | 中 | 方案已定（第 32 轮）；唯一风险 = 承接方未开工（**LD-C 跨 4 轮挂账观察**） |
| D-26 回归阻塞 | 低 | 60/65 5 FAIL 与 #63~#68 同根因（用户会话在途 4.4 API 误用）零新增；D-020 不代修待收口，复跑恢复 65/65 后各批 EXIT 门槛解冻 |
| D30-T3/EXIT | 低 | Owner/#4 域；build/ 08-18 23:22 不含 F-49 + F1-E-4 消费端 + LD-A/B + 批五~七 + RELIC-A 交 Owner/总指挥 |

### 维持已定方案边界（不重复写）

- **F1-E 全 7 批**：已收口（阶段 F 真全闭 7/7）——非本岗方案对象。
- **RELIC / LD-C·E·D 方案**：已定（SOLUTION_PLAN 31/32 轮）不重写，执行按 31/32 轮执行序。
- **F-49（传送门+宝箱）**：已落地（`4f1e791`）——非本岗方案对象；RELIC-E 落地时宝箱奖励升级三选一（本机制为地基）。
- **F-45~F-49 主观回归面 / E-0 终审完整局 / AF-P0 / PS-EXIT**：交 #5 真人（主观项不阻塞机器侧）。
- **F-16~F-44 真人回归 / MainMenu 待真人确认 / Day 28 性能段 / 章节 Boss 映射（已拍板三 Boss [6,10,14]）**：开放项清单维持（见 PLAYTEST 追踪区）。

## 🔴 红线遵守（本轮）

不写代码、不改 `.gd/.tscn/.tres/.json` 游戏文件、不 git commit、不跑探针。仅覆盖写 `docs/SOLUTION_PLAN.md`（顶部新第 39 轮段，历史段完整保留）+ 在 `docs/TASKS.md` 标注（Day 30 区第 69 轮确认块后补方案师第 39 轮确认块，RELIC 区块头「A 批已收口」标注已由 #2 第 69 轮落位不重复）。工作区在途用户会话美术资产（lain 帧/AI 美术工具/2 脚本 M = D-26 阻塞源）+ #4 TEST_REPORT.md 不碰（本轮仅 SOLUTION_PLAN/TASKS 两 docs 挂账，交下一岗入库）。

---

# 方案计划（2026-08-19 18:4x · 方案师第 38 轮 · 阶段 F 实测真全闭确认（7/7 🎉 · 第 37 轮「6/7 更正」挂账解除）+ 无新任务需方案化 + RELIC 跨 8 轮 / LD-C·E 跨 4 轮挂账观察 + D-26 回归阻塞/build 观察维持）

## 📌 本轮判定（方案师第 38 轮）

> **高峰检查**：18:37 不在 09-12/14-18 高峰 → 正常执行。
>
> **P0 检查（PLAYTEST 追踪区增量 #89 之后无新增量 · 反馈专员 4h 轮 14:38 轮 git 无 #90 提交 = 空转零产出符合 D-018）**：F-45~F-49/AF-P0 全 🟢 已修复·待真人回归；🟡 仅 H-05 家族主观审阅域（非机器可执行）→ **🔴P0 无新增 / 🟠 无用户拍板调度指令 → 无新机器可验证 P0 需纳入本轮**。
>
> **git 实测**：HEAD=`e31e0bc`（#1 进度分析第 72 轮 · 18:0x；第 37 轮方案后 +5 = `899c526` #2 第 68 轮回执（**F1-E 批五收口确认 + 阶段 F 真全闭 🎉 + T-020 转已收口 + 349/349 + RELIC 跨 7 轮/LD-C·E 挂账维持 + D-26 回归阻塞维持 + 登记无待拆不空转**）+ **#3 执行者 F1-E 批五全收口 5 commits**：`d990eca` 5-1（GameData.xlsx +icon_config sheet 3 行 + data_schema 注册 + excel_export presentation 第 7 键，其余 15 JSON 零 diff）/ `057e493` 5-2（get_icon_config 懒加载 + _icon_map 缓存，仿 get_fx_config 范式）/ `3388901` 5-3（IconAtlas _resolve_icon_config 静态新范式消费改读 + SHEET_CONFIG const 兜底）/ `5b92fd3` 5-4（day31_presentation +§10 icon 段 15 断言 → **334→349/349** + runner expect 334→349 + day26 锚点 1662→**1677**）/ `d03750e` 5-EXIT（**F1-E 行 7/7 批 = 阶段 F 真全闭 🎉 + T-020 转已收口** + SOLUTION_PLAN 底部第 68 轮执行结果：回归 59/64 挂 D-26 零新增 + BASELINE CLEAN））+ `e31e0bc` #1 第 72 轮确认（批五补做全收口确认 + 磁盘实测 7 键齐 + 消费端 5 文件命中 + 阶段 F 实测真全闭🎉 + 第 71 轮 6/7 计数偏差挂账解除））；**工作区在途 = 用户会话美术资产（lain 动画帧 ×8 + art_ai 工具 ×5 + `player_anim.gd`/`sprite_frame_factory.gd` M = **D-26 回归阻塞源** + 人物动画/ 未跟踪目录）+ `docs/TEST_REPORT.md` M（#4 在途）——非本岗改动面，红线内不碰**。
>
> **本轮核心产出 = 阶段 F 实测真全闭确认（无新任务需方案化）**：
> 1. **F1-E 批五 SHEET_CONFIG 收口确认（上轮「名义 7/7 实为 6/7」更正挂账解除）→ 阶段 F 实测真全闭 7/7 🎉**：`d990eca`~`d03750e` 5 commits 全 [x]（icon_config 3 行抽表 + get_icon_config 懒加载 + IconAtlas 消费改读 + §10 探针 15 断言 349/349 + EXIT）；**方案师第 37 轮 5 处锚点更新全部由实际执行兑现**（files dict 第 7 键 / data_schema 注册 :285+ / data_loader _icon_map :41+·get_icon_config :716+ / 探针段号 §10 / 回归 64 件套 1662→1677）；#1 第 72 轮磁盘实测确认（presentation.json 7 键齐 + 消费端 5 文件命中）→ **30 天计划 Day 1-30 客观任务 + 阶段 F 技术债全部客观收口，F1-E 行 7/7 批标记成立**；
> 2. **回归硬门槛口径更新 = 64 件套 · 1677 锚点**（批五收口 day26 1662→1677；**当前 59/64 5 FAIL = D-26 用户会话在途 `set_frame_offset`（Godot 4.4 API · 4.3 无此方法）误用**，D-020 不代修待收口，TEST_REPORT #68（18:00）确认与 #63~#67 同根因零新增——**所有挂账批次 EXIT 门槛统一挂 D-26 复跑恢复 64/64 后全绿**）；
> 3. **无新任务需方案化**：F1-E 全 7 批收口无后续批次；RELIC（方案已定第 31 轮）+ LEVEL_DESIGN（方案已定第 32 轮）均为「拆解+方案齐备」状态**不重写**；D30 尾项纯 Owner/#4 域无方案 → **本轮为状态确认轮 + 挂账刷新**（与第 28/29 轮先例一致）。

## 当前开发日：Day 31（RELIC + LEVEL_DESIGN 同窗口 · 承接方 #3 · 方案已定不重写）

### 任务1：RELIC 遗物扩展全批——挂账观察（跨 8 轮）

- **现状**：方案已定（SOLUTION_PLAN 第 31 轮，锚点实测复核：stats.json .stats.offensive[2]/.stats.economy[3] + desc_builder.gd:32-33 硬编码映射 + items relic 2 件 + data_loader:437 范式 + save_system 缺省容错）；**本轮 git 实测确认仍零开工**（HEAD=`e31e0bc` 无 day31_relic_*/stats 改名提交）→ **挂账观察（跨 8 轮）**，承接方 = #3 执行者（D-015 交接 + 用户 08-18 23:1x 拍板「拆解+方案齐备即开工」）。
- **执行序**（第 31 轮定案不变）：RELIC-A（独立低成本先行）→ RELIC-0（数据地基）→ RELIC-F/E（P0 独立）→ RELIC-B/C/D（依赖 0）→ RELIC-EXIT；⚠️ F-49 传送门+宝箱地基已落地（`4f1e791`），RELIC-E 落地时宝箱奖励升级三选一零重做（#2 第 66 轮已加注 RELIC-E1 行衔接）。
- **风险**：低-中（方案已定；唯一风险 = 承接方持续未开工——#3 近 8 轮优先推进 LD-A/B + F1-E 批五~七且已全收口，本窗口 RELIC 与 LD-C 均解锁可直接开工，执行序由 #3 排）。

### 任务2：LEVEL_DESIGN LD-C/E/D——挂账观察（LD-C 跨 4 轮）

- **现状**：LD-A（`96e4cd5`）+ LD-B（`b213296`）双收口（LD-A-EXIT/LD-B-EXIT [~] 仅回归挂 D-26）；**LD-C（Boss 演出）/ LD-E（attr）/ LD-D（可选）仍 [ ] 零开工**（git 无 boss_phase_player.gd/attr 分支提交）→ **挂账观察（LD-C 跨 4 轮）**，承接方 = #3 执行者（方案已定 SOLUTION_PLAN 第 32 轮，锚点复核 9 项一致不重写）。
- **执行序**（第 32 轮定案不变）：LD-C Boss 演出（boss_phase_events 表消费，硬门槛 day18_19 48/48 + day30_boss_skill 49/49 零改动）→ LD-E attr 正向状态（5 旧类型行为零漂移 + attr 纯新增分支）→ LD-D 特殊波可选挂 TECH_DEBT_PLAN（D-014 拍板）。
- **风险**：中（消费端 + 演出面）；方案已定不重写。

### 任务3：D30-T3 上传 + D30-EXIT 发布收口——纯 Owner/#4 域，无需方案

- **改动**：无（本岗红线：外部动作 + 测试岗产出）。D30-T3 上传 [ ] = 等 Owner 明确确认（目标资产库，上传属真正外部动作红线不变）；D30-EXIT [~]/[ ] = TEST_REPORT 发布摘要待 #4 落盘 + 最终标记。
- ⚠️ **build/ 观察维持**：08-18 23:22 产物（`2aeb717`：含 F-45~48 + F1-E-4-1，**不含其后 F-49 + F1-E-4 消费端 + LD-A/B + 批五/六/七**）→ 传送门/宝箱/批四抽表/LD/批五~七验证需最新代码或下次打包（D-016 授权自动替换已生效，等 #3/总指挥产出新版本后归档重导出，全程不再询问）。

### 风险总表（本轮）

| 任务 | 风险 | 说明 / 替代方案 |
|---|---|---|
| 阶段 F 全闭确认 | 低 | 7/7 批实测收口（`d990eca`~`d03750e` + 磁盘 7 键齐 + 349/349）；上轮 6/7 更正挂账解除 |
| RELIC 全批 | 低-中 | 方案已定（第 31 轮）；唯一风险 = 承接方未开工（**跨 8 轮挂账观察**） |
| LD-C/E/D | 中 | 方案已定（第 32 轮）；唯一风险 = 承接方未开工（**LD-C 跨 4 轮挂账观察**） |
| D-26 回归阻塞 | 低 | 59/64 5 FAIL 与 #63~#68 同根因（用户会话在途 4.4 API 误用）零新增；D-020 不代修待收口，复跑恢复 64/64 后各批 EXIT 门槛解冻 |
| D30-T3/EXIT | 低 | Owner/#4 域；build/ 08-18 23:22 不含 F-49 + F1-E-4 消费端 + LD-A/B + 批五~七 交 Owner/总指挥 |

### 维持已定方案边界（不重复写）

- **F1-E 全 7 批**：已收口（批五 `d03750e` EXIT 后阶段 F 真全闭 7/7）——非本岗方案对象。
- **RELIC / LD-C·E·D 方案**：已定（SOLUTION_PLAN 31/32 轮）不重写，执行按 31/32 轮执行序。
- **F-49（传送门+宝箱）**：已落地（`4f1e791` 闭环 + day31_portal_check 24/24）——非本岗方案对象；RELIC-E 落地时宝箱奖励升级三选一（本机制为地基）。
- **F-45~F-49 主观回归面 / E-0 终审完整局 / AF-P0 / PS-EXIT**：交 #5 真人（主观项不阻塞机器侧）。
- **F-16~F-44 真人回归 / MainMenu 待真人确认 / Day 28 性能段 / 章节 Boss 映射（已拍板三 Boss [6,10,14]）**：开放项清单维持（见 PLAYTEST 追踪区）。

## 🔴 红线遵守（本轮）

不写代码、不改 `.gd/.tscn/.tres/.json` 游戏文件、不 git commit、不跑探针。仅覆盖写 `docs/SOLUTION_PLAN.md`（顶部新第 38 轮段，历史段完整保留）+ 在 `docs/TASKS.md` 标注（Day 30 区第 68 轮确认块后补方案师第 38 轮确认块 + F1-E-5 段头补第 38 轮收口确认）。工作区在途用户会话美术资产（lain 帧/AI 美术工具/2 脚本 M = D-26 阻塞源）+ #4 TEST_REPORT.md 不碰（本轮仅 SOLUTION_PLAN/TASKS 两 docs 挂账，交下一岗入库）。

---

# 方案计划（2026-08-19 12:4x · 方案师第 37 轮 · F1-E 批七收口确认（阶段 F 名义全闭更正 6/7）+ 批五 SHEET_CONFIG 方案锚点复核更新（批六/七收口后 5 处漂移修正 · files dict 现 6 根键 → icon_config = 第 7 键）+ RELIC 跨 6 轮/LD-C·E 挂账观察）

## 📌 本轮判定（方案师第 37 轮）

> **高峰检查**：12:37 不在 09-12/14-18 高峰 → 正常执行。
>
> **P0 检查（PLAYTEST 追踪区增量 #89 之后无新增量 · 反馈专员 4h 轮：10:38 轮 git 无 #90/#91 提交 = 空转零产出符合 D-018）**：F-45~F-49/AF-P0 全 🟢 已修复·待真人回归；🟡 仅 H-05 家族主观审阅域（非机器可执行）→ **🔴P0 无新增 / 🟠 无用户拍板调度指令 → 无新机器可验证 P0 需纳入本轮**。
>
> **🟠 关键调度输入（两个互相矛盾的标记需本轮裁决）**：① `86b583a` #2 第 67 轮（12:00）确认 **F1-E 批七全收口 = 阶段 F 全闭 🎉**（`60a4e96` EXIT：T-024 转已收口 + 334/334 + day26 锚点 1662）；② `fe471a0` #1 第 71 轮（12:2x）⚠️ **实测更正：「7/7 批」标记仍为 6/7——批五 SHEET_CONFIG 跨 4 轮未落地（get_icon_config 零命中 / presentation.json 无 icon_config 键）→ 交总指挥核实**。→ **本轮方案师 4 次独立实证（excel_export/data_schema/data_loader/icon_atlas 四文件）确认批五确实未落地 → #2 第 67 轮「阶段 F 全闭🎉」标记不实，实际 6/7；批七收口本身成立**。
>
> **git 实测**：HEAD=`fe471a0`（#1 第 71 轮 · 12:2x；第 36 轮方案后 +8 = **#3 执行者 F1-E 批七全收口 5 commits**：`8f6ecff` 7-1 数据侧（GameData.xlsx +turret_config sheet 1 行 5.0/0.5/220.0 + data_schema 注册 + excel_export presentation 第 6 键，其余 16 JSON 零 diff）/ `c0606e1` 7-2 get_turret_config 懒加载接口（白盒 9/9）/ `c8ad1b7` 7-3 turret 消费改读（TURRET_DEFAULTS const 收敛 :13-15 + _resolve_turret_defaults + setup 三处装载兜底，day13 炮台段 6b 零改动 36/36）/ `afce477` 7-4 探针 +§9 turret 段 **18 断言**（316→**334/334** + runner expect 316→334 + day26 锚点 1644→1662）/ `60a4e96` EXIT（7/7 批标记 + T-024 转已收口））+ `77d7928` 方案师第 36 轮挂账入库 + `9a6fb40` #1 第 70 轮（5/7 修正）+ `86b583a` #2 第 67 轮（阶段 F 全闭🎉）+ `fe471a0` #1 第 71 轮（**6/7 实测更正**））；**工作区在途 = 用户会话美术资产（lain 动画帧 ×8 + art_ai 工具 ×5 + `player_anim.gd`/`sprite_frame_factory.gd` M = **D-26 回归阻塞源** + 人物动画/ 未跟踪目录）+ `docs/TEST_REPORT.md` M（#4 在途）——非本岗改动面，红线内不碰**。
>
> **锚点实测复核结论（本轮核心产出 = F1-E 批五 SHEET_CONFIG 方案锚点复核更新 · 第 33 轮方案为唯一事实源 + 批六/批七收口后 5 处漂移修正，供 #3 直接执行）**：
> 1. **批五未落地第 4 次实证（4 文件逐一确认）**：① `tools/excel_export.py:543` files["presentation.json"] **现 6 根键** `{"enemy_sprites", "behavior_map", "audio_map", "fx_config", "skill_icon_map", "turret_config"}`——**无 icon_config**（批六 skill_icon_map + 批七 turret_config 已入）→ **icon_config = 追加第 7 键（第 33 轮方案「第 6 键」作废）** ② `tools/data_schema.py` 有 fx_config :261-262 / skill_icon_map :270-271 / turret_config :281-282 三注册，**无 icon_config 注册** → **注册追加在 turret_config 后（现约 :285+），仿 fx_config :261-262 范式** ③ `scripts/autoload/data_loader.gd` 有 get_skill_icon_index :691 + get_turret_config :709（缓存字段 _fx_map :36 → _skill_icon_map :38 → _turret_map :40），**无 get_icon_config** → **仿写位置 = get_turret_config 后（现约 :716+），缓存字段 _icon_map 追加 :41+** ④ `scripts/utils/icon_atlas.gd` SHEET_CONFIG const **:8-24 原样**（weapons 40 / items 54 / skills 5，各含 path/frame_count/frame_size Vector2i(32,32)）——**零改动 = 硬门槛锚点保持**；
> 2. **day31_presentation_check 段号修正**：第 33 轮拆解定 icon 段为「§7」，但批六已用 §7（T-004 17 断言）+ §8（skill_icon 13 断言）、批七用 §9（turret 18 断言）→ **icon 段 = §10 追加文件尾（§9 后 :429 起）**；当前探针 **334/334**（316+18）→ 批五 +icon 段 ≥13 断言 → **≥347/347**；runner expect 同步 334→**347**；
> 3. **回归硬门槛口径更新 = 64 件套 · 1662 锚点**（批七收口 day26 1644→1662；当前 59/64 5 FAIL = D-26 用户会话在途 `set_frame_offset` 4.4 API 误用，D-020 不代修待收口，批五 EXIT 以 D-26 复跑恢复 64/64 全绿为准）；
> 4. **零漂移保持 3 项（硬门槛）**：icon_atlas.gd SHEET_CONFIG :8-24 原样 / day31_items_atlas_check.gd:27 + day31_skill_icon_check.gd:28/:37-38 直接读 const 零改动 / get_frame_count 三探针（day11_12 :482 / day20 :369 / day24_f13 :338）行为保持；
> 5. **static 类访问 Autoload 技术要点维持**（第 33 轮确认）：IconAtlas 为 `class_name extends RefCounted` 全静态工具类（:4-5），实例节点路径不可用 → `_resolve_icon_config` 须 `Engine.get_main_loop().root.get_node_or_null("DataLoader")`；`--script` 探针环境返回 null → 回退 const 兜底天然兼容。
>
> **结论**：① **F1-E 批七收口确认**（`8f6ecff..60a4e96` 5 commits 全 [x]：T-024 转已收口 + 334/334 + files dict 第 6 键 turret_config 落地）→ 上轮「批七待执行」挂账**解除**；② **阶段 F 名义全闭更正**：#2 第 67 轮「7/7 全闭🎉」vs #1 第 71 轮「实测 6/7」矛盾 → 本轮 4 次实证批五未落地 → **实际 6/7，F1-E 行「阶段 F 全闭 🎉」标记不实，交总指挥核实 F1-E 行 :2580 标记并更正**；③ **F1-E 批五 SHEET_CONFIG = 本轮方案主产出**（第 33 轮方案唯一事实源 + 本轮 5 处漂移修正，承接方 = #3 执行者，执行序 5-1→5-2→5-3→5-4→EXIT 每任务一收口 commit 带 F1-E-5 编号，**批五收口 = 阶段 F 真全闭 7/7**）；④ **RELIC 全批零开工（跨 6 轮）**挂账维持；⑤ **LD-C/E/D 已拆已定案（第 32 轮）待 #3**（LD-C 跨 2 轮）维持；⑥ D30-T3 上传 + D30-EXIT = 纯 Owner/#4 域维持；⚠️ **build/ = 08-18 23:22 产物（`2aeb717`：含 F-45~48 + F1-E-4-1，不含其后 F-49 + F1-E-4 消费端 + LD-A/B + 批六/批七）** → 交 Owner/总指挥（传送门/宝箱/批四抽表/LD/批六/批七验证需最新代码或下次打包）。

## 当前开发日：Day 31（LEVEL_DESIGN + RELIC 同窗口 · F1-E 批五承接方 #3 · 拆解 `95752eb` F1-E-5 段唯一事实源 · 方案 = 第 33 轮 + 本轮锚点修正）

### 任务1：F1-E-5-1【W2】Excel 抽表（数据侧）· 风险：低-中

- **改动**：① `docs/GameData.xlsx` 新增 `icon_config` sheet（**3 行 × id/path/frame_count/frame_size_w/frame_size_h 双行表头**：id = weapons/items/skills（与 SHEET_CONFIG 键一致）；path = `res://assets/sprites/ui/weapons.png` / `res://assets/sprites/ui/items.png` / `res://assets/sprites/skills/skills.png` **与 const 现值逐一一致**；frame_count = 40/54/5；frame_size_w/h = 32/32 三行（拆列仿 fx_config size_w/size_h 先例））② `tools/data_schema.py` 注册 `icon_config`（file: presentation.json / root: "icon_config" / kind: "dict" / key: id / json_cols: []，仿 fx_config :261-262）——**⚠️ 锚点修正：现 fx_config :261-262 + skill_icon_map :270-271 + turret_config :281-282 三注册在位，icon_config 追加在 turret_config 后（现约 :285+），按实位追加勿覆盖** ③ `tools/excel_export.py` presentation 构建段（turret_config 段 :531 后）追加 icon_map 解析（id 主键 → {path, frame_count, frame_size: {"x": int(frame_size_w), "y": int(frame_size_h)}}，仿 fx_config 段）+ **⚠️ 锚点修正：files dict 现于 :543 且 6 根键（enemy_sprites/behavior_map/audio_map/fx_config/skill_icon_map/turret_config，无 icon_config）→ icon_config = 追加第 7 键（勿覆盖既有键）** ④ 导出 → presentation.json +icon_config 3 项，**其余 16 JSON 零 diff 断言**。
- **风险**：**低-中**。数据面常规（3 行 sheet + 注册 + 构建三小点）；**硬门槛 = 其余 16 JSON 零 diff**（前六批先例）+ icon_config 3 键 path/frame_count/frame_size 与 IconAtlas const 现值**零漂移**（漏一项 = §10 探针红）。⚠️ **WPS 锁坑**：Excel 被 WPS 打开时导出写回总览报 PermissionError（F1-G-尾教训），执行者注意。
- **验证**：excel_export --check-only EXIT=0 + JSON 校验通过 + icon_config 3 键齐 + 与 const 现值一致（零漂移）+ 其余 16 JSON 零 diff。

### 任务2：F1-E-5-2【W1】DataLoader 接口 · 风险：低

- **改动**：`scripts/autoload/data_loader.gd` 新增 `get_icon_config(sheet_name: String) -> Dictionary`（**仿 get_fx_config :661-673 范式，⚠️ 锚点修正：现 get_skill_icon_index :691 + get_turret_config :709 已在其后，get_icon_config 追加在 get_turret_config 后约 :716+**）：字段区补 `var _icon_map: Dictionary = {}`（:40 附近 `_turret_map` 后，注释 F1-E-5）；懒加载 presentation.json icon_config 缓存（is_empty 重试标记）+ 命中 → duplicate + frame_size JSON → Vector2i 组装（**仿 :670-671 先例**）+ 未命中/损坏 → 空字典（消费端 const 兜底零崩）。
- **风险**：**低**。纯新增函数零连锁（不触碰既有接口）；`_icon_map` 命名与拆解一致，勿与既有 `_fx_map`/`_audio_map`/`_skill_icon_map`/`_turret_map` 混淆。
- **验证**：白盒读 get_icon_config("items") → 键齐全（path/frame_count/frame_size: Vector2i(32,32)）；改 Excel frame_count 一例 → 导出 → 返回值变化（**端到端双跑**，F1-散 §1 先例）。

### 任务3：F1-E-5-3【W1】IconAtlas 消费改读 · 风险：低-中（static 类访问 Autoload 新范式）

- **改动**：`scripts/utils/icon_atlas.gd` 新增静态私有 `_resolve_icon_config(sheet_name: String) -> Dictionary`：`Engine.get_main_loop().root.get_node_or_null("DataLoader")` → 非空则 `get_icon_config(sheet_name)` 命中（非空 + has path/frame_count/frame_size）优先返回；未命中/空表/无 DataLoader → `SHEET_CONFIG.get(sheet_name, {})` const 兜底；`get_icon` :41 `SHEET_CONFIG[sheet_name]` → `_resolve_icon_config(sheet_name)`（**前置 :37 SHEET_CONFIG.has 未知 sheet push_warning 保留**，_resolve 空字典分支按原样 warn+return）；`get_frame_count` :72-73 改走（SHEET_CONFIG.has → `_resolve_icon_config` 取 frame_count / 未知 0）；**SHEET_CONFIG const 保留为兜底**。
- **风险**：**低-中**。双硬门槛：① **day31_items_atlas_check.gd:27 + day31_skill_icon_check.gd:28/:37-38 直接读 const 零改动**（const 保留即满足，本轮实测 :8-24 原样确认）；② **get_frame_count 行为保持**（day11_12 :482 / day20 :369 / day24_f13 :338 动态读，抽表命中返回现值 = 行为一致）。⚠️ **唯一新增风险 = static 类经 Engine.get_main_loop() 访问 Autoload 为新范式**（无现成先例）：若特定环境（如 --script 探针）Engine 主循环不可达 → get_node_or_null 返回 null → 回退 const 零崩（**拆解已注明天然兼容**）。**替代方案**：若实测 Engine 访问在消费场景异常，退回仅 const（现状即等价零回归，抽表只走数据侧探针验证）。
- **验证**：白盒 get_icon("items", 0) 走 icon_config 路径（返回值非空）；_icon_map 清空 → 回退 const 仍可 get_icon（load 不崩）；未知 sheet 仍 push_warning；get_frame_count 未知 sheet 仍 0；**外部调用方（hud/shop/level_up_panel 等经 IconAtlas.get_icon）零改动**（解析内聚在 icon_atlas 内部，拆解定案）。

### 任务4：F1-E-5-4【W1】探针扩展 · 风险：低

- **改动**：`tools/day31_presentation_check.gd` 尾部（§9 turret 段 :429 后）**+§10 icon 段 ≥13 断言**（仿 ⑥ fx 段模式；**⚠️ 段号修正：原拆解定 §7，但 §7/§8 已被批六占用、§9 被批七占用 → icon 段 = §10**）：icon_config 3 键齐 / 键集合与 SHEET_CONFIG 一致（零多余零缺失）/ 逐键 path·frame_count·frame_size 与 const 现值逐一一致（**抽表零漂移**）/ get_icon_config 消费（items 键齐 + frame_size == Vector2i(32,32) + 未知名空字典）/ 白盒改 _icon_map frame_count → 返回值变化（E2E 双跑还原）/ 空表兜底 const 仍可 get_icon（白盒 IconAtlas）/ 未知 sheet_name push_warning 保留 / get_frame_count 行为一致。
- **风险**：**低**。纯探针扩展；**回归硬门槛 = day31_items_atlas_check + day31_skill_icon_check 零改动** + 64 件套 1662 锚点 + baseline CLEAN。
- **验证**：day31_presentation_check **≥347/347**（334+13，**runner expect 同步 334→347**）。

### 任务5：F1-E-5-EXIT【W5】收口 · 风险：低

- **验证**：回归 **64 件套（1662 锚点）**（当前 59/64 5 FAIL 挂 D-26，**收口以 D-26 复跑恢复后全绿为准**）+ day31_presentation ≥347 + baseline **BASELINE CLEAN** + excel_export --check-only EXIT=0 + F1-E 行 **7/7 批标记（阶段 F 真全闭）** + TECH_DEBT_ISSUES **T-020（SHEET_CONFIG 抽表）转已收口**。

### 任务6：RELIC 全批 + LD-C/E/D——挂账观察（RELIC 跨 6 轮 / LD-C 跨 2 轮）

- **RELIC**：方案已定（SOLUTION_PLAN 第 31 轮）；**本轮 git 实测确认仍零开工**（HEAD 无 day31_relic_*/stats 改名提交）→ **挂账观察（跨 6 轮）**，承接方 = #3 执行者；执行序 = RELIC-A（独立低成本先行）→ RELIC-0（数据地基）→ RELIC-F/E → RELIC-B/C/D → EXIT；⚠️ F-49 传送门+宝箱地基已落地（`4f1e791`），RELIC-E 落地时宝箱奖励升级三选一零重做（#2 第 66 轮已加注 RELIC-E1 行衔接）。
- **LD-C/E/D**：方案已定（SOLUTION_PLAN 第 32 轮）；LD-B 收口（`b213296`）后已解锁，仍 [ ] 待 #3 → 挂账维持（LD-C 跨 2 轮）；执行序 = LD-C Boss 演出（boss_phase_events 表消费）→ LD-E attr 正向状态 → LD-D 特殊波可选挂 TECH_DEBT_PLAN。
- **风险提示**：三块均为「拆解+方案齐备」状态，唯一风险 = 承接方持续未开工（#3 第 64-67 轮优先做 LD-A/B + 批六/批七且已收口，本窗口可连续推进**批五 → RELIC-A → LD-C**，执行序由 #3 排）。

### 任务7：D30-T3 上传 + D30-EXIT 发布收口——纯 Owner/#4 域，无需方案

- **改动**：无（本岗红线：外部动作 + 测试岗产出）。D30-T3 上传 [ ] = 等 Owner 明确确认（目标资产库）；D30-EXIT [~]/[ ] = TEST_REPORT 发布摘要待 #4 落盘 + 最终标记。⚠️ **build/ 观察维持：08-18 23:22 产物（`2aeb717`）含 F-45~48 + F1-E-4-1，不含其后 F-49 + F1-E-4 消费端 + LD-A/B + 批六/批七** → 传送门/宝箱/批四抽表/LD/批六/批七验证需最新代码或下次打包（交 Owner/总指挥，D-016 授权自动替换已生效，等 #3/总指挥产出新版本后归档重导出）。

### 风险总表（本轮）

| 任务 | 风险 | 说明 / 替代方案 |
|---|---|---|
| F1-E-5-1 数据侧 | 低-中 | 3 行 sheet + 注册 + 构建；16 JSON 零 diff + 3 键零漂移硬门槛；**files dict 现 6 根键 → 加第 7 键 icon_config**；WPS 锁坑 |
| F1-E-5-2 DataLoader 接口 | 低 | 仿 get_fx_config 纯新增函数；_icon_map 追加 :41+ 勿混四既有缓存 |
| F1-E-5-3 IconAtlas 改读 | 低-中 | const 兜底双硬门槛（items_atlas/skill_icon 直读 const 零改动 + get_frame_count 行为保持）；**static 类 Engine 访问新范式**，异常回退 const 零崩；替代 = 仅 const 现状等价 |
| F1-E-5-4 探针扩展 | 低 | §10 icon 段仿 ⑥ 模式；**≥347/347（334+13）** + runner expect 334→347 |
| F1-E-5-EXIT | 低 | **7/7 批标记（阶段 F 真全闭）** + T-020 转收口；EXIT 挂 D-26 复跑 |
| RELIC / LD-C·E | 低-中 | 方案已定（31/32 轮）；唯一风险 = 承接方未开工（RELIC 跨 6 轮 / LD-C 跨 2 轮） |
| D30-T3/EXIT | 低 | Owner/#4 域；build/ 不含 F-49 + F1-E-4 消费端 + LD-A/B + 批六/批七 交 Owner/总指挥核实 |

### 维持已定方案边界（不重复写）

- **批七（turret_config）**：已收口（`8f6ecff..60a4e96`，T-024 转已收口）——非本岗方案对象。
- **批五/批六方案**：已定（SOLUTION_PLAN 33/34 轮），批六已收口；批五按第 33 轮方案 + 本轮锚点修正执行，不重写。
- **LD-A/B 收口 + LD-C/E/D**：方案已定（SOLUTION_PLAN 第 32 轮）不重写，执行按 32 轮执行序；LD-B 已收口。
- **F-49（传送门+宝箱）**：已落地（`4f1e791` 闭环 + day31_portal_check 24/24）——非本岗方案对象；RELIC-E 落地时宝箱奖励升级三选一（本机制为地基）。
- **F-45~F-49 主观回归面 / E-0 终审完整局 / AF-P0 / PS-EXIT**：交 #5 真人（主观项不阻塞机器侧）。
- **F-16~F-44 真人回归 / MainMenu 待真人确认 / Day 28 性能段 / 章节 Boss 映射（已拍板三 Boss [6,10,14]）**：开放项清单维持（见 PLAYTEST 追踪区）。

## 🔴 红线遵守（本轮）

不写代码、不改 `.gd/.tscn/.tres/.json` 游戏文件、不 git commit、不跑探针。仅覆盖写 `docs/SOLUTION_PLAN.md`（顶部新第 37 轮段，历史段完整保留）+ 在 `docs/TASKS.md` 标注（F1-E-5 段补第 37 轮锚点复核标注 + F1-E 行 :2580「阶段 F 全闭」标记更正 6/7 + Day 30 区第 67 轮确认块后补方案师第 37 轮确认块）。工作区在途用户会话美术资产（lain 帧/AI 美术工具/2 脚本 M = D-26 阻塞源）+ #4 TEST_REPORT.md 不碰（本轮仅 SOLUTION_PLAN/TASKS 两 docs 挂账，交下一岗入库）。

---

# 方案计划（2026-08-19 08:4x · 方案师第 36 轮 · F1-E 批七 炮台默认值方案锚点复核更新（批六收口后 4 处漂移修正 · files dict 现 5 根键 → 批七 = 第 6 键）+ 批六收口确认 + 批五实锤未落地（跨 3 轮）+ RELIC/LD-C·E 挂账观察）

## 📌 本轮判定（方案师第 36 轮）

> **P0 检查（PLAYTEST 追踪区增量 #89 之后无新增量 · 反馈专员 4h 轮：02:38 空转零产出符合 D-018，06:38 轮 git 无 #90/#91 提交 = 同样空转零产出）**：F-45~F-49/AF-P0 全 🟢 已修复·待真人回归；🟡 仅 H-05 家族主观审阅域（非机器可执行）→ **🔴P0 无新增 / 🟠 无用户拍板调度指令 → 无新机器可验证 P0 需纳入本轮**。
>
> **🟠 关键调度输入（批七方案第 35 轮已入库 · 本轮 = 锚点复核更新）**：`15390de` 已把方案师第 35 轮批七正式方案挂账入库（F1-E-7 段「✅ 方案已定（SOLUTION_PLAN.md 第 35 轮）」）；其后 `9a6fb40` #1 第 70 轮实测修正 **F1-E 批标记 6/7→5/7**（批五 SHEET_CONFIG 未落地：get_icon_config 零命中 / presentation.json 无 icon_config 键）；`6df9f8a` #2 第 66 轮确认批六收口 + 批七已拆已定案待 #3（跨 1 轮挂账）+ RELIC 跨 5 轮/LD-C·E 挂账维持 + F-49 地基衔接加注（RELIC-E1 行）。→ **本轮方案师按纪律对批七方案做批六收口后的锚点复核更新（漂移 4 处修正，方案本身仍以第 35 轮为唯一事实源），供 #3 直接执行**。
>
> **git 实测**：HEAD=`6df9f8a`（#2 第 66 轮 · 08:05；第 35 轮方案后 +6 = **#3 执行者 F1-E 批六全收口 6 commits**：`38f7c2e` 6-1 T-004 数据侧（starting_gun 行入表，projectile_speed/lifetime 两键不进表按第 34 轮裁决）/ `80fc19d` 6-2 T-004 消费端（build_weapon_from_data 装配 + 补设 360/1.5 + shop.gd 排除 starting_gun 防商店池 23→24）/ `3b3aff8` 6-3 T-022 skill_icon_map 数据侧（5 行 + data_schema 注册 + files dict 第 6 键）/ `20b03f9` 6-4 T-022 消费端（get_skill_icon_index + hud 改读 const 兜底）/ `c2b5a0e` 6-5 探针（§7 +17 + §8 +13 → **316/316**，runner expect 286→316，**day26 锚点 1614→1644**，day7/day8 豁免占位初始枪）/ `15390de` EXIT（6/7 批标记 + T-004/T-022 转收口 + 第 35 轮方案挂账入库））+ `9a6fb40` #1 第 70 轮（5/7 修正）+ `6df9f8a` #2 第 66 轮）；**工作区在途 = 用户会话美术资产（lain 动画帧 ×8 + art_ai 工具 ×4 + `player_anim.gd`/`sprite_frame_factory.gd` M = **D-26 回归阻塞源**）+ `docs/TEST_REPORT.md` M（#4 在途）——非本岗改动面，红线内不碰**。
>
> **锚点实测复核结论（本轮核心产出 · 与第 35 轮方案对照，批六收口后漂移 4 处修正 + 路径 1 处补全）**：
> 1. **零漂移确认 5 项**：① `scripts/weapons/turret.gd` 字段声明默认值 **:13-15**（damage=5.0 / fire_interval=0.5 / attack_range=220.0）+ `setup()` 装载兜底 **:31-35**（:32 damage / :33 cooldown **`maxf(..., 0.01)` 钳制** / :34 fire_interval=cooldown / :35 range），:3 注释「禁止硬编码」原样 ② `scripts/player/skill_controller.gd` `_cast_deploy_turret` **:243-280**（:245 summon_id 默认 se_auto_turret / :246 get_weapon / :255 duration skill 域 / :268/:277 world.spawn_turret 透传）③ **world.gd 路径补全 = `scripts/world/world.gd`** `spawn_turret` :104-112（第 35 轮方案未带完整路径，:104 声明 / :109-110 setup 透传，一致）④ `tools/day13_build_check.gd` 炮台段 6b **:629-657**（:631 函数体 + :654-657 3 台临时/常驻断言）⑤ weapons se_auto_turret 数值 **damage=5 / cooldown=0.5 / range=220 零漂移**；
> 2. **漂移修正 4 处（批六落地所致）**：① **weapons.json se_auto_turret 行号 :2668-2673 → :2680-2690**（starting_gun 行插入 +12；id :2680 / damage 5 :2685 / cooldown 0.5 :2686 / range 220 :2687）② **data_schema.py fx_config 注册 :261-262 保持** + **skill_icon_map 注册 :270-271 已落地（批六）** → **turret_config 注册追加在 skill_icon_map 后（现约 :272+）**，按实位追加勿覆盖 ③ **excel_export.py files dict 现于 :525（非 :512）· 现 5 根键** `{"enemy_sprites", "behavior_map", "audio_map", "fx_config", "skill_icon_map"}`（**无 icon_config = 批五未落地实锤**；skill_icon_map 构建段 :513-523 仿写范式）→ **批七 turret_config = 第 6 键（非第 35 轮方案的「第 7 键」——该假设基于批五先落地，实际批五未落地）**；⚠️ 若 #3 在批七前先行补批五（icon_config），files dict 先变 6 键，批七再追加第 7 键，两种顺序均按「追加勿覆盖既有键」执行 ④ **day31_presentation_check 当前 316/316（批六收口后，非 307）** → 批七 +§9 turret 段 ≥8 断言 → **≥324/324**；runner expect 同步 316→324；
> 3. **回归硬门槛口径更新 = 64 件套 · 1644 锚点**（批六收口 day26 锚点 1614→1644；当前 59/64 5 FAIL = D-26 用户会话在途 `set_frame_offset` Godot 4.4 API 误用，D-020 不代修待收口，批七 EXIT 以 D-26 复跑恢复 64/64 全绿为准）。
>
> **结论**：① **F1-E 批七 = 本轮锚点复核更新主产出**（方案唯一事实源 = SOLUTION_PLAN 第 35 轮 + 本轮 4 处漂移修正，承接方 = #3 执行者，执行序 7-1→7-2→7-3→7-4→EXIT 每任务一收口 commit 带 F1-E-7 编号，**批七收口 = 阶段 F 全闭 7/7**）；② **F1-E 批六收口确认**（`38f7c2e..15390de` 6 commits 全 [x]，316/316，T-004/T-022 转已收口）→ 上轮「跨 1 轮挂账」**解除**；③ **F1-E 批五 SHEET_CONFIG 实锤未落地**（#1 第 70 轮修正 5/7 + 本轮 data_schema/excel_export 实测无 icon_config）→ 挂账观察（**跨 3 轮**，自第 33 轮方案起）；④ **RELIC 全批零开工（跨 5 轮）**挂账维持；⑤ **LD-C/E/D 已拆已定案（第 32 轮）待 #3** 维持；⑥ D30-T3 上传 + D30-EXIT = 纯 Owner/#4 域维持；⚠️ **build/ = 08-18 23:22 产物（`2aeb717`：含 F-45~48 + F1-E-4-1，不含其后 F-49 + F1-E-4 消费端 + LD-A/B + 批六）** → 交 Owner/总指挥（传送门/宝箱/批四抽表/LD/批六验证需最新代码或下次打包）。

## 当前开发日：Day 31（LEVEL_DESIGN + RELIC 同窗口 · F1-E 批七承接方 #3 · 拆解 `5981262` F1-E-7 段唯一事实源 · 方案 = 第 35 轮 + 本轮锚点修正）

### 任务1：F1-E-7-1【W2】turret_config 抽表（数据侧）· 风险：低

- **改动**：① `docs/GameData.xlsx` 新增 `turret_config` sheet（**1 行 × id/damage/fire_interval/attack_range 双行表头**：id = se_auto_turret（与 weapons 表炮台武器键一致）；**damage = 5.0 / fire_interval = 0.5 / attack_range = 220.0 与 turret.gd:13-15 现值逐一一致**；⚠️ fire_interval 语义 = cooldown（= 开火间隔），Excel 列名与 TURRET_DEFAULTS const 键一致防消费端映射漂移）② `tools/data_schema.py` 注册 `turret_config`（file: presentation.json / root: "turret_config" / kind: "dict" / key: id / json_cols: []，仿 fx_config 实位 :261-262 先例）——**⚠️ 锚点修正：现 fx_config :261-262 后已有 skill_icon_map 注册 :270-271（批六落地），turret_config 追加在其后（现约 :272+），按实位追加勿覆盖** ③ `tools/excel_export.py` presentation 构建段（skill_icon_map 段 :513-523 后）追加 turret_config 解析（id 主键 → {damage, fire_interval, attack_range} **数值 coerce float**，仿 fx_config 段）——**⚠️ 锚点修正：files dict 现于 :525 且 5 根键（enemy_sprites/behavior_map/audio_map/fx_config/skill_icon_map，无 icon_config = 批五未落地）→ 批七 turret_config = 追加第 6 键（非第 7 键；若先行补批五 icon_config 则第 7 键，追加勿覆盖既有键）** ④ 导出 → presentation.json +turret_config 1 项，**其余 16 JSON 零 diff 断言**（前六批先例）。
- **风险**：**低**。数据面常规（1 行 sheet + 注册 + 构建三小点）；硬门槛 = turret_config 三键数值与 turret const 现值零漂移 + 其余 16 JSON 零 diff。⚠️ **WPS 锁坑**：Excel 被 WPS 打开时导出写回总览报 PermissionError（F1-G-尾教训），执行者注意。
- **验证**：excel_export --check-only EXIT=0 + JSON 校验通过 + turret_config 1 键齐 + 三键数值与 turret.gd:13-15 现值一致（零漂移）+ 其余 16 JSON 零 diff。

### 任务2：F1-E-7-2【W1】DataLoader 接口 · 风险：低

- **改动**：`scripts/autoload/data_loader.gd` 新增 `get_turret_config() -> Dictionary`（懒加载 presentation.json turret_config 缓存 + `_turret_map` 空表标记仿缓存字段区（:36 后，**is_empty 重试标记 F3 §4 禁新增 bool**）；命中 → 整表返回 {id: {damage, fire_interval, attack_range}}；未命中/损坏 → 空字典，仿 get_fx_config :661-683 范式）。
- **风险**：**低**。纯新增接口，无既有消费面。
- **验证**：白盒读 get_turret_config → "se_auto_turret" 键齐 + 三值正确（5.0/0.5/220.0）；改 Excel fire_interval → 导出 → 返回值变化（端到端双跑，F1-散 §1 先例）→ 强制改回重导出；删表行/损坏 → 空字典零崩。

### 任务3：F1-E-7-3【W1】turret.gd 消费改读 · 风险：低-中

- **改动**：① 新增 `const TURRET_DEFAULTS := {"damage": 5.0, "fire_interval": 0.5, "attack_range": 220.0}`（**收敛 :13-15 字段声明默认值**——字段声明改 `var damage: float = TURRET_DEFAULTS["damage"]` 等 3 处，const 编译期求值合法零行为变化，:16-18 duration/permanent 等零改动）② 新增私有 `_resolve_turret_defaults() -> Dictionary`（`get_node_or_null("/root/DataLoader")` → 非空则 `get_turret_config().get("se_auto_turret", {})` 命中优先返回；未命中/空表/无 DataLoader → `TURRET_DEFAULTS` const 兜底；turret 为实例节点 → 直接引用先例 vfx_player :97，非 IconAtlas static 类无需 Engine.get_main_loop）③ `setup()` :32-35 三处装载兜底改走（`weapon_data.get("damage", _resolve_turret_defaults().get("damage", 5.0))` 或方法顶部一次性取 defaults 局部复用）；**⚠️ :33 `maxf(..., 0.01)` 钳制保留**（防 0 除，行为不变）④ **TURRET_DEFAULTS const 保留为兜底**（→ day13_build_check 炮台段 6b :629-657 零改动硬门槛）⑤ duration_left/duration_max/permanent 逻辑零改动（duration 属 skill 域不拆入本批）。**⚠️ 零行为变化**（仅默认值来源数据化：Excel turret_config 命中 → 用表值；缺表/未导出 → const 现值）。
- **风险**：**低-中**。唯一新增风险 = turret 装配链行为漂移（炮台是玩家召唤物，数值走 skill_controller → world.spawn_turret → setup 透传链）；硬门槛 = **day13_build_check 炮台段 6b :629-657 零改动**（3 台临时/常驻断言）。**替代方案**：若 _resolve_turret_defaults 实测与 setup 语义冲突（如 DataLoader 时序不可达导致兜底链异常），退回纯 const 现状等价零回归（数据侧 turret_config 表与探针仍保留，抽表价值不损）。
- **验证**：白盒 turret.setup 空 weapon_data → 三字段 = 现值（5.0/0.5/220.0）；turret_config 清空 → 回退 const 仍可 setup 不崩；改 Excel 值 → 导出 → setup 空 weapon_data 字段变化（端到端双跑）→ 强制改回重导出；三字段声明值 = const（编译期一致）；day13 :631-657 零改动复跑。

### 任务4：F1-E-7-4【W1】探针扩展 · 风险：低

- **改动**：`tools/day31_presentation_check.gd` 尾部（批六 §8 skill_icon 段后）+§9 turret 段 ≥8 断言（仿 ⑥ fx 段模式）：turret_config 1 键齐 / 键集合与 TURRET_DEFAULTS 一致（零多余零缺失）/ 逐键数值与 const 现值逐一一致（抽表零漂移）/ 改 Excel 一例 fire_interval → 导出 → get_turret_config 变化（端到端双跑）/ 空表兜底 const 仍可 setup（白盒）/ 未知武器 id 回退 const / 字段声明值 = const 编译期一致 / day13 炮台段 6b 行为保持复跑。
- **风险**：**低**。纯探针扩展；**回归硬门槛 = day13_build_check（炮台段 6b）零改动** + 64 件套 1644 锚点 + baseline CLEAN。
- **验证**：day31_presentation_check **≥324/324**（316+8，**runner expect 同步 316→324**）+ 全量回归（当前 59/64 挂 D-26，EXIT 门槛统一挂等复跑）。

### 任务5：F1-E-7-EXIT【W5】收口 · 风险：低

- **验证**：回归 **64 件套（1644 锚点）**（当前 59/64 5 FAIL 挂 D-26，**收口以 D-26 复跑恢复后全绿为准**）+ day31_presentation ≥324（316+8）+ baseline **BASELINE CLEAN** + excel_export --check-only EXIT=0 + F1-E 行 **7/7 批标记（阶段 F 全闭）** + TECH_DEBT_ISSUES **T-024 转已收口**。

### 任务6：F1-E 批五 + RELIC 全批 + LD-C/E/D——挂账观察（批五跨 3 轮 / RELIC 跨 5 轮）

- **批五**（SHEET_CONFIG/icon_config）：方案已定（SOLUTION_PLAN 第 33 轮）；**本轮 git + 数据面实测双证实未落地**（HEAD 无 icon_config 提交 / data_schema.py 无 icon_config 注册 / excel_export files dict 无 icon_config 键 / get_icon_config 零命中，#1 第 70 轮已修正 5/7）→ **挂账观察（跨 3 轮）**，承接方 = #3 执行者；硬门槛 = day31_items_atlas/skill_icon 直接读 const 零改动 + get_frame_count 三探针行为保持 + 64 件套口径。
- **RELIC**：方案已定（SOLUTION_PLAN 第 31 轮）；**本轮 git 实测确认仍零开工**（HEAD 无 day31_relic_*/stats 改名提交）→ **挂账观察（跨 5 轮）**，承接方 = #3 执行者；执行序 = RELIC-A（独立低成本先行）→ RELIC-0（数据地基）→ RELIC-F/E → RELIC-B/C/D → EXIT；⚠️ F-49 传送门+宝箱地基已落地（`4f1e791`），RELIC-E 落地时宝箱奖励升级三选一零重做（#2 第 66 轮已加注 RELIC-E1 行衔接）。
- **LD-C/E/D**：方案已定（SOLUTION_PLAN 第 32 轮）；LD-B 收口（`b213296`）后已解锁，仍 [ ] 待 #3 → 挂账维持；执行序 = LD-C Boss 演出（boss_phase_events 表消费）→ LD-E attr 正向状态 → LD-D 特殊波可选挂 TECH_DEBT_PLAN。
- **风险提示**：三块均为「拆解+方案齐备」状态，唯一风险 = 承接方持续未开工（#3 第 65/66 轮优先做 LD-B + 批六且已收口，本窗口可连续推进批七→批五→RELIC-A→LD-C，执行序由 #3 排）。

### 任务7：D30-T3 上传 + D30-EXIT 发布收口——纯 Owner/#4 域，无需方案

- **改动**：无（本岗红线：外部动作 + 测试岗产出）。D30-T3 上传 [ ] = 等 Owner 明确确认（目标资产库）；D30-EXIT [~]/[ ] = TEST_REPORT 发布摘要待 #4 落盘 + 最终标记。⚠️ **build/ 观察维持：08-18 23:22 产物（`2aeb717`）含 F-45~48 + F1-E-4-1，不含其后 F-49 + F1-E-4 消费端 + LD-A/B + 批六** → 传送门/宝箱/批四抽表/LD/批六验证需最新代码或下次打包（交 Owner/总指挥）。

### 风险总表（本轮）

| 任务 | 风险 | 说明 / 替代方案 |
|---|---|---|
| F1-E-7-1 turret_config 数据侧 | 低 | 1 行 sheet + 注册 + 构建；**files dict 现 5 根键 → 加第 6 键（非第 7）**；三键零漂移 + 16 JSON 零 diff；WPS 锁坑 |
| F1-E-7-2 get_turret_config | 低 | 纯新增接口；空表/损坏 → 空字典零崩 |
| F1-E-7-3 turret 消费改读 | 低-中 | TURRET_DEFAULTS const 兜底 = day13 炮台段 6b 零改动硬门槛；:33 maxf 钳制保留；替代 = 纯 const 现状等价零回归 |
| F1-E-7-4 探针扩展 | 低 | ≥8 断言 → **≥324/324**（316+8）；runner expect 316→324；day13 零改动 + 64 件套 1644 锚点 |
| F1-E-7-EXIT | 低 | 7/7 批标记（阶段 F 全闭）+ T-024 转收口；EXIT 挂 D-26 复跑 |
| 批五 / RELIC / LD-C·E | 低-中 | 方案已定（33/31/32 轮）；唯一风险 = 承接方未开工（批五跨 3 轮实锤 / RELIC 跨 5 轮 / LD-C·E 维持） |
| D30-T3/EXIT | 低 | Owner/#4 域；build/ 不含 F-49 + F1-E-4 消费端 + LD-A/B + 批六 交 Owner/总指挥核实 |

### 维持已定方案边界（不重复写）

- **F1-E 批七 EXIT 后**：阶段 F 全闭（7/7 批），无后续批次待拆。
- **批五/批六/批七方案**：已定（SOLUTION_PLAN 33/34/35 轮），批六已收口；批七按第 35 轮方案 + 本轮锚点修正执行，不重写。
- **LD-B/C/E/D**：方案已定（SOLUTION_PLAN 第 32 轮）不重写，执行按 32 轮执行序；LD-B 已收口。
- **F-49（传送门+宝箱）**：已落地（`4f1e791` 闭环 + day31_portal_check 24/24）——非本岗方案对象；RELIC-E 落地时宝箱奖励升级三选一（本机制为地基）。
- **F-45~F-49 主观回归面 / E-0 终审完整局 / AF-P0 / PS-EXIT**：交 #5 真人（主观项不阻塞机器侧）。
- **F-16~F-44 真人回归 / MainMenu 待真人确认 / Day 28 性能段 / 章节 Boss 映射（已拍板三 Boss [6,10,14]）**：开放项清单维持（见 PLAYTEST 追踪区）。

## 🔴 红线遵守（本轮）

不写代码、不改 `.gd/.tscn/.tres/.json` 游戏文件、不 git commit、不跑探针。仅覆盖写 `docs/SOLUTION_PLAN.md`（顶部新第 36 轮段，历史段完整保留）+ 在 `docs/TASKS.md` 标注（F1-E-7 段「方案已定」标注补第 36 轮锚点修正 + Day 30 区第 66 轮确认块后补方案师第 36 轮确认块）。工作区在途用户会话美术资产（lain 帧/AI 美术工具/2 脚本 M = D-26 阻塞源）+ #4 TEST_REPORT.md 不碰（本轮仅 SOLUTION_PLAN/TASKS 两 docs 挂账，交下一岗入库）。

---

# 方案计划（2026-08-19 06:4x · 方案师第 35 轮 · F1-E 批七 炮台默认值正式方案（#2 第 65 轮拆解完成兑现 · F1-E 最后一批 7/7）+ LD-B 收口确认 + 批五/批六/RELIC 挂账观察）

## 📌 本轮判定（方案师第 35 轮）

> **P0 检查（PLAYTEST 追踪区增量 #89 之后无新增量 · 反馈专员 4h 轮 02:38 空转零产出符合 D-018，下一轮 06:38 未到）**：F-45~F-49/AF-P0 全 🟢 已修复·待真人回归；🟡 仅 H-05 家族主观审阅域（非机器可执行）→ **🔴P0 无新增 / 🟠 无用户拍板调度指令 → 无新机器可验证 P0 需纳入本轮**。
>
> **🟠 关键调度输入（本轮兑现 #2 第 65 轮拆解）**：`docs/TASKS.md` F1-E-7 段（**#2 第 65 轮 `5981262` 06:00 函数级拆解**）——F1-E 第七批（最后一批 7/7）**炮台默认值抽表**（T-024「炮台默认值与 se_auto_turret 数据重复」）：turret.gd:13-15 字段声明默认值 + setup() :31-35 装载兜底两处散落 → **turret_config 独立表 1 行**（id=se_auto_turret，dict 形仿 fx_config 先例，不直接消费 weapons.json——turret 的 weapon_data 本就由 setup 传入，turret_config 管「字段声明 + 装载兜底」这份重复默认值的唯一事实源）→ data_schema 注册 → excel_export 构建 presentation.json 第 7 键 → DataLoader `get_turret_config`（懒加载）→ turret.gd `_resolve_turret_defaults` 消费改读（**TURRET_DEFAULTS const 兜底** = day13 炮台段 6b 零改动硬门槛）→ day31_presentation_check +§9 turret 段 → 回归 64 件套。**duration 不拆入本批**（临时炮台存活 15s = skill 域 skill_controller :255 `sd.get("duration", 15.0)`；weapons se_auto_turret `duration=20` 未消费键 = build_weapon_from_data 不消费先例，登记观察）。承接方 = #3 执行者（D-015 交接，拆解+方案齐备即开工）。→ **本轮方案师按拆解写批七正式方案（实测复核锚点 6 项 + 1 处行号微差修正 + 1 处细节补充，见任务 1-5）**。
>
> **git 实测**：HEAD=`5981262`（#2 第 65 轮 · 06:00；第 34 轮方案后 +3 = `b213296` **#3 执行者 LEVEL_DESIGN LD-B 固定出生点生成收口**（`_get_spawn_position` 表驱动主路径：edge/anchor/ring 三型解析 + sequence 轮换/random 组内随机 + min_dist 过近原样生成 + `_clamp_to_ground` 钳制 + `_get_random_spawn_position` 原函数保留缺省回退 = **F-48 零回归（flee_bound 22/22 零改动）** + wave_manager spawn_wave 透传 spawn_set/spawn_order（可选参数缺省空兼容旧调用）+ day31_level_design +§6 出生点 12 断言 **36/36** + runner 64 件套 **1614 锚点** + 回归 59/64 5 FAIL = D-26 用户会话在途零新增）/ `2d02016` #1 第 69 轮 / `5981262` **批七拆解**）；**工作区在途 = 用户会话美术资产（lain 动画帧 ×8 + art_ai 工具 ×4 + `player_anim.gd`/`sprite_frame_factory.gd` M = **D-26 回归阻塞源**）+ `docs/TEST_REPORT.md` M（#4 在途）——非本岗改动面，红线内不碰**。
>
> **锚点实测复核结论（本轮核心产出，供执行者直接使用）**——与 #2 第 65 轮拆解文本**逐一一致（1 处行号微差修正 + 1 处细节补充）**：
> 1. **turret.gd**（`scripts/weapons/turret.gd`）：**字段声明默认值 :13-15**（`damage: float = 5.0` / `fire_interval: float = 0.5` / `attack_range: float = 220.0`）+ **setup() 装载兜底 :31-35**（:32 `weapon_data.get("damage", 5.0)` / :33 `get("cooldown", 0.5)` **带 `maxf(..., 0.01)` 钳制** / :35 `get("range", 220.0)`）——**两处散落与拆解一致**；⚠️ **细节补充**：:3 头部注释已明示「数值全部来自 DataLoader.get_weapon("se_auto_turret")（damage:5 / cooldown:0.5 / range:220），**禁止硬编码**」——即 T-024 债务本质 = 字段声明 + 装载兜底硬编码与 weapons 表重复，turret_config 表 = 这份默认值的唯一事实源，方案成立；
> 2. **weapons.json se_auto_turret :2668-2675**（id :2668 / name 自动炮台 :2669 / price 15 :2672 / **damage 5 :2673 / cooldown 0.5 :2674 / range 220 :2675** / crit_chance 0.05 :2676 后续）——与拆解一致（拆解写 :2668-2673 为关键行）；⚠️ 注意 weapons 表列名为 damage/cooldown/range，而 turret_config 表列名为 damage/**fire_interval**/attack_range（语义同一对，Excel 列名与 TURRET_DEFAULTS const 键一致防消费端映射漂移——拆解已明确）；
> 3. **调用链**：`skill_controller.gd` `_cast_deploy_turret` **:243-280**（:245 `summon_id` 默认 "se_auto_turret" / :246 `DataLoader.get_weapon(summon_id)` / :255 `sd.get("duration", 15.0)` skill 域 / :268/:277 `world.spawn_turret(TurretScene, weapon_data, duration, player)` 透传）+ `world.gd` `spawn_turret` **:104-112**（:104 声明 / :109-110 `turret.setup(weapon_data, duration, owner_player)` 透传）——**与拆解一致**；
> 4. **硬门槛探针（炮台行为零改动确认）**：`day13_build_check.gd` 炮台段 6b **:629-657**（:629-630 段头注释「Part 6b: 炮台常驻/多台（D13-T3）」+ :631 函数体 `_part_turret_array` + :654-657 未装备 se_turret_array → **3 台临时**断言 + 装备 → 常驻多台断言）——**与拆解一致**（拆解写 :629-654，实测断言延伸至 :657，语义零差异）；**关键**：炮台行为断言不直接读字段默认值（走 skill_controller 装配链）→ TURRET_DEFAULTS const 保留 = 该探针零改动硬门槛成立；
> 5. **data_schema.py 注册范式**：`fx_config` 注册**实位 :261-262**（file: presentation.json / root: "fx_config" / kind: "dict" / key: id）——**行号微差修正：拆解写 :255-258，实测 :261-262**（icon_config/skill_icon_map 两批未落地故未再漂移，两批落地后行号将后移，执行者按批五/批六实位追加勿覆盖），turret_config 注册仿此；
> 6. **excel_export.py presentation 构建段**：fx_config 构建 :502-511 + **files["presentation.json"] :512 现 4 根键** `{"enemy_sprites", "behavior_map", "audio_map", "fx_config"}`——与第 34 轮口径一致（LD-A 两新表走独立文件 spawn_points.json/boss_phase_events.json 不并入）；**批七 turret_config 构建追加 :511 后 + :512 加第 7 键**（批五 icon_config 第 5 + 批六 skill_icon_map 第 6 后，追加勿覆盖既有键）。
>
> **结论**：① **F1-E 批七 = 本轮方案主产出**（拆解完成即解锁，方案师按纪律写正式方案，承接方 = #3 执行者，执行序 7-1→7-2→7-3→7-4→EXIT 每任务一收口 commit 带 F1-E-7 编号）；② **LEVEL_DESIGN LD-B 收口确认**（`b213296`：LD-B1/B2/B3 [x] + LD-B-EXIT [~] 仅回归挂 D-26，flee_bound 22/22 零改动 = F-48 不回归）→ 上轮「LD-B 待执行」挂账**解除**，**LD-C（Boss 演出）/ LD-E（attr）/ LD-D（可选）已拆已定案（第 32 轮）解锁待 #3**；③ **F1-E 批五 SHEET_CONFIG（方案已定第 33 轮）git 实测仍零开工**（HEAD 无 icon_config/get_icon_config/§7 icon 段提交）→ 挂账观察（**跨 2 轮**）；④ **F1-E 批六 初始武器+SKILL_ICON_MAP（方案已定第 34 轮）git 实测仍零开工**（HEAD 无 starting_gun/skill_icon_map/get_skill_icon_index 提交）→ 挂账观察（**跨 1 轮**）；⑤ **RELIC 全批方案已定（第 31 轮）git 实测仍零开工** → 挂账观察（**跨 4 轮**）；⑥ D30-T3 上传 + D30-EXIT = 纯 Owner/#4 域维持；⚠️ **build/ = 08-18 23:22 产物（`2aeb717` 授权导出：含 F-45~48 + F1-E-4-1，不含其后 F-49 + F1-E-4 消费端 + LD-A/B）→ 传送门/宝箱/批四抽表/LD 验证需最新代码或下次打包**（交 Owner/总指挥）。

## 当前开发日：Day 31（LEVEL_DESIGN + RELIC 同窗口 · F1-E 批七承接方 #3 · 拆解 `5981262` F1-E-7 段唯一事实源）

### 任务1：F1-E-7-1【W2】turret_config 抽表（数据侧）· 风险：低

- **改动**：① `docs/GameData.xlsx` 新增 `turret_config` sheet（**1 行 × id/damage/fire_interval/attack_range 双行表头**：id = se_auto_turret（与 weapons 表炮台武器键一致）；**damage = 5.0 / fire_interval = 0.5 / attack_range = 220.0 与 turret.gd:13-15 现值逐一一致**；⚠️ fire_interval 语义 = cooldown（= 开火间隔），Excel 列名与 TURRET_DEFAULTS const 键一致防消费端映射漂移）② `tools/data_schema.py` 注册 `turret_config`（file: presentation.json / root: "turret_config" / kind: "dict" / key: id / json_cols: []，仿 fx_config 实位 :261-262 先例）③ `tools/excel_export.py` presentation 构建段（fx_config 段 :502-511 后）追加 turret_config 解析（id 主键 → {damage, fire_interval, attack_range} **数值 coerce float**，仿 fx_config 段）+ **:512 files dict 追加第 7 键 "turret_config"（勿覆盖既有 4 键 + 批五 icon_config 第 5 键 + 批六 skill_icon_map 第 6 键）** ④ 导出 → presentation.json +turret_config 1 项，**其余 16 JSON 零 diff 断言**（前六批先例）。
- **风险**：**低**。数据面常规（1 行 sheet + 注册 + 构建三小点）；硬门槛 = turret_config 三键数值与 turret const 现值零漂移 + 其余 16 JSON 零 diff。⚠️ **WPS 锁坑**：Excel 被 WPS 打开时导出写回总览报 PermissionError（F1-G-尾教训），执行者注意。
- **验证**：excel_export --check-only EXIT=0 + JSON 校验通过 + turret_config 1 键齐 + 三键数值与 turret.gd:13-15 现值一致（零漂移）+ 其余 16 JSON 零 diff。

### 任务2：F1-E-7-2【W1】DataLoader 接口 · 风险：低

- **改动**：`scripts/autoload/data_loader.gd` 新增 `get_turret_config() -> Dictionary`（懒加载 presentation.json turret_config 缓存 + `_turret_map` 空表标记仿缓存字段区（:36 后，**is_empty 重试标记 F3 §4 禁新增 bool**）；命中 → 整表返回 {id: {damage, fire_interval, attack_range}}；未命中/损坏 → 空字典，仿 get_fx_config :661-678 范式）。
- **风险**：**低**。纯新增接口，无既有消费面。
- **验证**：白盒读 get_turret_config → "se_auto_turret" 键齐 + 三值正确（5.0/0.5/220.0）；改 Excel fire_interval → 导出 → 返回值变化（端到端双跑，F1-散 §1 先例）→ 强制改回重导出；删表行/损坏 → 空字典零崩。

### 任务3：F1-E-7-3【W1】turret.gd 消费改读 · 风险：低-中

- **改动**：① 新增 `const TURRET_DEFAULTS := {"damage": 5.0, "fire_interval": 0.5, "attack_range": 220.0}`（**收敛 :13-15 字段声明默认值**——字段声明改 `var damage: float = TURRET_DEFAULTS["damage"]` 等 3 处，const 编译期求值合法零行为变化，:16-18 duration/permanent 等零改动）② 新增私有 `_resolve_turret_defaults() -> Dictionary`（`get_node_or_null("/root/DataLoader")` → 非空则 `get_turret_config().get("se_auto_turret", {})` 命中优先返回；未命中/空表/无 DataLoader → `TURRET_DEFAULTS` const 兜底；turret 为实例节点 → 直接引用先例 vfx_player :97，非 IconAtlas static 类无需 Engine.get_main_loop）③ `setup()` :32-35 三处装载兜底改走（`weapon_data.get("damage", _resolve_turret_defaults().get("damage", 5.0))` 或方法顶部一次性取 defaults 局部复用）；**⚠️ :33 `maxf(..., 0.01)` 钳制保留**（防 0 除，行为不变）④ **TURRET_DEFAULTS const 保留为兜底**（→ day13_build_check 炮台段 6b 零改动硬门槛）⑤ duration_left/duration_max/permanent 逻辑零改动（duration 属 skill 域不拆入本批）。**⚠️ 零行为变化**（仅默认值来源数据化：Excel turret_config 命中 → 用表值；缺表/未导出 → const 现值）。
- **风险**：**低-中**。唯一新增风险 = turret 装配链行为漂移（炮台是玩家召唤物，数值走 skill_controller → world.spawn_turret → setup 透传链）；硬门槛 = **day13_build_check 炮台段 6b :629-657 零改动**（3 台临时/常驻断言）。**替代方案**：若 _resolve_turret_defaults 实测与 setup 语义冲突（如 DataLoader 时序不可达导致兜底链异常），退回纯 const 现状等价零回归（数据侧 turret_config 表与探针仍保留，抽表价值不损）。
- **验证**：白盒 turret.setup 空 weapon_data → 三字段 = 现值（5.0/0.5/220.0）；turret_config 清空 → 回退 const 仍可 setup 不崩；改 Excel 值 → 导出 → setup 空 weapon_data 字段变化（端到端双跑）→ 强制改回重导出；三字段声明值 = const（编译期一致）；day13 :631-657 零改动复跑。

### 任务4：F1-E-7-4【W1】探针扩展 · 风险：低

- **改动**：`tools/day31_presentation_check.gd` 尾部（批五 §7 icon 段 + 批六 §8 skill_icon 段后，若未先行则按当前尾段追加）**+§9 turret 段 ≥8 断言**（仿 ⑥ fx 段模式）：turret_config 1 键齐 / 键集合与 TURRET_DEFAULTS 一致（零多余零缺失）/ 逐键数值与 const 现值逐一一致（抽表零漂移）/ 改 Excel 一例 fire_interval → 导出 → get_turret_config 变化（端到端双跑）/ 空表兜底 const 仍可 setup（白盒）/ 未知武器 id 回退 const / 字段声明值 = const 编译期一致 / day13 炮台段 6b 行为保持复跑。
- **风险**：**低**。纯探针扩展；**回归硬门槛 = day13_build_check（炮台段 6b）零改动** + 64 件套 1614 锚点 + baseline CLEAN。
- **验证**：day31_presentation_check **≥315/315**（307+8，批五/批六未先行时按实际尾段计数）+ 全量回归（当前 59/64 挂 D-26，EXIT 门槛统一挂等复跑）。

### 任务5：F1-E-7-EXIT【W5】收口 · 风险：低

- **验证**：回归 **64 件套（1614 锚点）**（当前 59/64 5 FAIL 挂 D-26，**收口以 D-26 复跑恢复后全绿为准**）+ day31_presentation ≥315（307+8）+ baseline **BASELINE CLEAN** + excel_export --check-only EXIT=0 + F1-E 行 **7/7 批标记（阶段 F 全闭）** + TECH_DEBT_ISSUES **T-024 转已收口**。

### 任务6：LEVEL_DESIGN LD-C/E/D——LD-B 收口解锁，挂账观察

- **现状**：LD-B1/B2/B3 [x]（`b213296` 固定出生点生成：表驱动主路径 + spawn_set/spawn_order 透传 + 探针 36/36 + flee_bound 22/22 零改动 = F-48 不回归）+ LD-B-EXIT [~]（仅回归挂 D-26，D-020 不代修待收口）→ **LD-C（Boss 演出）/ LD-E（attr）/ LD-D（可选）仍 [ ] 待 #3 执行**（方案已定 SOLUTION_PLAN 第 32 轮，锚点复核 9 项一致）。
- **执行序**（第 32 轮定案不变）：LD-C Boss 演出（boss_phase_events 表消费）→ LD-E attr 正向状态 → LD-D 特殊波可选挂 TECH_DEBT_PLAN。
- **风险**：中（消费端与 Boss 演出面）；方案已定不重写。

### 任务7：F1-E 批五/批六 + RELIC 全批——挂账观察（批五跨 2 轮 / 批六跨 1 轮 / RELIC 跨 4 轮）

- **批五**（SHEET_CONFIG）：方案已定（SOLUTION_PLAN 第 33 轮，锚点复核 6 项一致）；**本轮 git 实测确认仍未开工**（HEAD=`5981262` 无 icon_config/get_icon_config/§7 icon 段提交）→ **挂账观察（跨 2 轮）**，承接方 = #3 执行者；硬门槛 = day31_items_atlas/skill_icon 直接读 const 零改动 + get_frame_count 三探针行为保持 + 64 件套口径。
- **批六**（初始武器 + SKILL_ICON_MAP）：方案已定（SOLUTION_PLAN 第 34 轮，含 projectile_speed/lifetime 两键不进表裁决）；**本轮 git 实测确认仍未开工**（HEAD 无 starting_gun/skill_icon_map/get_skill_icon_index 提交）→ **挂账观察（跨 1 轮）**，承接方 = #3 执行者；硬门槛 = day31_skill_icon_check §5 直接读 const + day13 :617-625 source_id 留空零改动。
- **RELIC**：方案已定（SOLUTION_PLAN 第 31 轮）；**本轮 git 实测确认仍零开工**（HEAD 无 day31_relic_*/stats 改名提交）→ **挂账观察（跨 4 轮）**，承接方 = #3 执行者；执行序 = RELIC-A（独立低成本先行）→ RELIC-0（数据地基）→ RELIC-F/E → RELIC-B/C/D → EXIT。
- **风险提示**：三批均为「拆解+方案齐备」状态，唯一风险 = 承接方持续未开工（#3 第 65 轮优先做 LD-B 且已收口，本窗口可连续推进 LD-C→批五→批六→批七→RELIC-A，执行序由 #3 排）。

### 任务8：D30-T3 上传 + D30-EXIT 发布收口——纯 Owner/#4 域，无需方案

- **改动**：无（本岗红线：外部动作 + 测试岗产出）。D30-T3 上传 [ ] = 等 Owner 明确确认（目标资产库）；D30-EXIT [~]/[ ] = TEST_REPORT 发布摘要待 #4 落盘 + 最终标记。⚠️ **build/ 观察维持：08-18 23:22 产物（`2aeb717`）含 F-45~48 + F1-E-4-1，不含其后 F-49 + F1-E-4 消费端 + LD-A/B** → 传送门/宝箱/批四抽表/LD 验证需最新代码或下次打包（交 Owner/总指挥）。

### 风险总表（本轮）

| 任务 | 风险 | 说明 / 替代方案 |
|---|---|---|
| F1-E-7-1 turret_config 数据侧 | 低 | 1 行 sheet + 注册 + 构建；三键零漂移 + 16 JSON 零 diff；WPS 锁坑 |
| F1-E-7-2 get_turret_config | 低 | 纯新增接口；空表/损坏 → 空字典零崩 |
| F1-E-7-3 turret 消费改读 | 低-中 | TURRET_DEFAULTS const 兜底 = day13 炮台段 6b 零改动硬门槛；:33 maxf 钳制保留；替代 = 纯 const 现状等价零回归 |
| F1-E-7-4 探针扩展 | 低 | ≥8 断言；day13 零改动 + 64 件套 1614 锚点 |
| F1-E-7-EXIT | 低 | 7/7 批标记（阶段 F 全闭）+ T-024 转收口；EXIT 挂 D-26 复跑 |
| LD-C/E/D | 中 | 方案已定第 32 轮；LD-B 收口已解锁；风险 = Boss 演出消费端 |
| 批五 / 批六 / RELIC | 低-中 | 方案已定（33/34/31 轮）；唯一风险 = 承接方未开工（跨 2/1/4 轮挂账观察） |
| D30-T3/EXIT | 低 | Owner/#4 域；build/ 不含 F-49 + F1-E-4 消费端 + LD-A/B 交 Owner/总指挥核实 |

### 维持已定方案边界（不重复写）

- **F1-E 批七 EXIT 后**：阶段 F 全闭（7/7 批），无后续批次待拆。
- **LD-B/C/E/D**：方案已定（SOLUTION_PLAN 第 32 轮）不重写，执行按 32 轮执行序。
- **F-49（传送门+宝箱）**：已落地（`4f1e791` 闭环 + day31_portal_check 24/24）——非本岗方案对象；真人回归面交 #5；RELIC-E 落地时宝箱奖励升级三选一（本机制为地基）。
- **F-45~F-49 主观回归面 / E-0 终审完整局 / AF-P0 / PS-EXIT**：交 #5 真人（主观项不阻塞机器侧）。
- **F-16~F-44 真人回归 / MainMenu 待真人确认 / Day 28 性能段 / 章节 Boss 映射（已拍板三 Boss [6,10,14]）**：开放项清单维持（见 PLAYTEST 追踪区）。

## 🔴 红线遵守（本轮）

不写代码、不改 `.gd/.tscn/.tres/.json` 游戏文件、不 git commit、不跑探针。仅覆盖写 `docs/SOLUTION_PLAN.md`（顶部新第 35 轮段，历史段完整保留）+ 在 `docs/TASKS.md` 标注（F1-E-7 段「方案已定（SOLUTION_PLAN.md 第 35 轮）」+ LD-B 收口确认 + 批五/批六/RELIC 挂账观察 + 第 65 轮状态块后补方案师第 35 轮确认块）。工作区在途用户会话美术资产（lain 帧/AI 美术工具/2 脚本 M = D-26 阻塞源）+ #4 TEST_REPORT.md 不碰（本轮仅 SOLUTION_PLAN/TASKS 两 docs 挂账，交下一岗入库）。

---

# 方案计划（2026-08-19 04:3x · 方案师第 34 轮 · F1-E 批六 初始武器+SKILL_ICON_MAP 正式方案（#2 第 64 轮拆解完成兑现 · 含 1 处新阻塞点裁决）+ LD-A 收口确认 + 批五/RELIC 挂账观察）

## 📌 本轮判定（方案师第 34 轮）

> **P0 检查（PLAYTEST 追踪区增量 #89 之后无新增量 · 反馈专员已改 4h 一轮，02:38 轮空转零产出符合 D-018「无反馈轮不写增量不 commit」）**：F-45~F-49/AF-P0 全 🟢 已修复·待真人回归；🟡 仅 H-05 家族主观审阅域（非机器可执行）→ **🔴P0 无新增 / 🟠 无用户拍板调度指令 → 无新机器可验证 P0 需纳入本轮**。
>
> **🟠 关键调度输入（本轮兑现 #2 第 64 轮拆解）**：`docs/TASKS.md` F1-E-6 段（**#2 第 64 轮 `6636889` 04:00 函数级拆解**）——F1-E 第六批 **初始武器 + SKILL_ICON_MAP 抽表**（两子项合并批）：T-004 `_equip_default_weapon` 内联初始枪抽表（weapons sheet +starting_gun 行，**source_id 留空保 day13 硬门槛**）+ T-022 hud SKILL_ICON_MAP 抽表（**独立 skill_icon_map 表 5 行**，否决 characters 点号列备选 = blade_burst 历史键无主 + 掉落技能槽覆盖不全；**SKILL_ICON_MAP const 保留兜底** = day31_skill_icon_check §5 直接读 const 零改动硬门槛）→ day31_presentation_check +§8 skill_icon 段 → 回归 64 件套。承接方 = #3 执行者（D-015 交接，拆解+方案齐备即开工）。→ **本轮方案师按拆解写批六正式方案（实测复核锚点 8 项 + 1 处新阻塞点裁决，见任务 1-6）**。
>
> **git 实测**：HEAD=`6636889`（#2 第 64 轮 · 04:00；第 33 轮方案后 +6 = `96e4cd5` **LD-A1~A3+EXIT LEVEL_DESIGN 数据地基收口**（spawn_points 11 行三型 + boss_phase_events 7 行 6 类型 + waves spawn_set/spawn_order 列 + FK 校验三态 + **--check-only 只读缺陷顺手修** + DataLoader 三接口 + day31_level_design_data_check **24/24** + runner 63→**64 件套**/day26 1578→**1602 锚点**）/ `3509b74` 执行者第 64 轮收口（**回归阻塞登记 59/64：5 FAIL = 用户会话在途 D-26 `set_frame_offset` Godot 4.4 API 误用**，与 LD-A 零关联）/ `5c306b1` 总指挥第 7 轮（**D-020 处置：不代修待收口，EXIT 门槛统一挂等复跑**）/ `c32a13f` #1 第 68 轮 / `6636889` **批六拆解**）；**工作区在途 = 用户会话美术资产（lain 动画帧 ×8 + art_ai 工具 ×4 + `player_anim.gd`/`sprite_frame_factory.gd` M = **D-26 回归阻塞源**）+ `docs/TEST_REPORT.md` M（#4 在途）——非本岗改动面，红线内不碰**。
>
> **锚点实测复核结论（本轮核心产出，供执行者直接使用）**——与 #2 第 64 轮拆解文本**逐一一致（2 处微差修正 + 1 处新阻塞点裁决）**：
> 1. **weapon_controller.gd**（`scripts/weapons/weapon_controller.gd`）：`_equip_default_weapon()` **:59-71**（拆解写 :59-76，实测函数体 :59-71 + 字段实为 **9 项**非 7：weapon_name=初始枪/weapon_type=ranged/base_damage=8.0/fire_rate=2.5/projectile_speed=360.0/attack_range=180.0/lifetime=1.5/pierce=0/knockback=0.0），调用点 :40 `_ready`；`equip_from_data(weapon_id)` :187（:185 注释「按 id 装备数据驱动武器，覆盖 _ready() 装上的占位『初始枪』」= 数据驱动装配语义已有）；
> 2. **⭐ 新阻塞点裁决（拆解未覆盖）**：`build_weapon_from_data(weapon_id)` :134-166 实际消费键 = **name→weapon_name / category→weapon_type（DataLoader.get_weapon_category）/ damage→base_damage / cooldown→fire_rate（fire_rate=1.0/cooldown 换算，:146-147）/ range→attack_range / knockback / pierce / crit_chance / crit_damage / icon_index / price / max_level / levels**；而 **:162 注释明确「projectile_speed 保留 Weapon 默认 400；lifetime 由 _spawn_projectile() 按 range/speed 推导，不手设」= 数据驱动路径下 projectile_speed=360.0 与 lifetime=1.5 两项不会装配**（weapons.json 实测 36 武器零 projectile_speed/lifetime 键，非历史遗漏而是设计如此）→ **拆解「starting_gun 数值零变化 8.0/2.5/360/180/1.5/0/0 逐键断言零漂移」隐含的两键可装配假设不成立**。**裁决（方案师）**：① starting_gun 表行**只填可消费键**（name/weapon_type/damage=8/cooldown=0.4（↔fire_rate 2.5）/range=180/knockback=0/pierce=0/max_level=1，**projectile_speed/lifetime 两键不进表**——进了即 F1-G 无消费方死键先例违规）② 消费端改走 `build_weapon_from_data("starting_gun")` 命中后**补两句 `w.projectile_speed = 360.0; w.lifetime = 1.5`（对齐内联现值零行为变化）**再 equip_weapon；null/异常 → 保留现内联构造兜底（拆解已定）③ 探针断言 9 键逐一对等（含补设后两键相等）+ E2E 改 damage=9 → 导出 → base_damage=9 → 强制改回 8 重导出。**备选 C（不强制）**：build_weapon_from_data :162 补 `projectile_speed` 消费键（默认 400 兜底 + 其他 36 武器零漂移）→ 两键可全进表，更彻底数据驱动；影响面 = 共享构建函数，风险可控但非必须，执行者二选一登记；
> 3. **hud.gd**：`SKILL_ICON_MAP` const **:336-342**（**5 键**：se_skill_fireball=0/deploy_turret=1/blade_burst=2/holy_shield=3/sword_arc=4，sword_arc 带 PS-C4 注释）+ `_apply_skill_icon` :343-360（**消费点 :354** `int(SKILL_ICON_MAP.get(skill_id, -1))` + 未知 id push_warning :356-357）/ `_apply_skill_slot_icon` :388-409（**消费点 :403** + 未映射 :404-405 灰显）——**与拆解一致**；
> 4. **硬门槛探针（const 直读确认）**：`day31_skill_icon_check.gd` §5 **:57-81**（:61 `hud_script.SKILL_ICON_MAP` 直接读 const + :73-80 data 全 se_skill_* id 覆盖/帧索引有效 + :81 sword_arc==4）——**SKILL_ICON_MAP const 保留 = 该探针零改动**；`day13_build_check.gd:617-625`「无 source_id 占位武器跳过 inventory」（初始枪不污染 HUD）——**starting_gun source_id 留空 = 该断言零改动**；
> 5. **data_schema.py**：`weapons` 注册 :199-204（category_map + child weapons_levels）——**T-004 零新注册**；`fx_config` :261-265 注册范式（file: presentation.json / root: fx_config / kind: dict / key: id / json_cols: []）——**icon_config/skill_icon_map 注册仿此**；`characters` :286-292（:290 注释「skill 为 dict → 点号宽列自动」= 拆解否决的备选确实存在，否决成立）；
> 6. **excel_export.py**：presentation 构建段 :462-512（enemy_sprites :464-474 / behavior_map :479-485 / audio_map :490-496 / fx_config :502-511），**files dict 现于 :512 且仅 4 根键** `{"enemy_sprites","behavior_map","audio_map","fx_config"}`（LD-A 两新表走独立文件 spawn_points.json :438-445 / boss_phase_events.json :450-460，不并入 presentation.json）→ **行号修正：第 33 轮方案记「:449 现 5 根键」已随 LD-A 插入漂移 → 现 :512 4 根键**（批五加 icon_config 成 5 → 批六加 skill_icon_map 成 6，追加勿覆盖既有键）；skill_icon_map 构建仿 fx_config 段（id 主键 → int(icon_index)，无 size 组装）；
> 7. **data_loader.gd**（`scripts/autoload/data_loader.gd`）：缓存字段区 :29-42（`_fx_map` :36 / `_spawn_points` :38-40 / `_boss_phase_events` :41-42，空字典 = is_empty 重试标记范式）——**`_icon_map`/`_skill_icon_map` 仿此加在 :36 后**；`get_fx_config` :666-678 懒加载范式（raw parse → 命中缓存 → 组装 Vector2i）——**get_skill_icon_index 仿此（无 Vector2i，命中 → int 值 / 未命中 → -1）**；`get_icon_config`（批五）+ `get_skill_icon_index`（批六）两接口同域可合并建段；
> 8. **回归硬门槛口径 = 64 件套 · 1602 锚点**（LD-A runner 扩容；**当前 59/64 5 FAIL 挂 D-26 用户会话在途，D-020 处置 = 不代修待收口，批六 EXIT 门槛统一挂等 D-26 复跑恢复 64/64 后全绿**）。
>
> **结论**：① **F1-E 批六 = 本轮方案主产出**（拆解完成即解锁，方案师按纪律写正式方案，承接方 = #3 执行者，执行序 6-1→6-2→6-3→6-4→6-5→EXIT 每任务一收口 commit 带 F1-E-6 编号）；② **LEVEL_DESIGN LD-A 收口确认**（`96e4cd5`：LD-A1/A2/A3 [x] + LD-A-EXIT [~] 仅回归挂 D-26）→ 上轮「LD-A 待执行」挂账解除，**LD-B（固定出生点）/LD-C（Boss 演出）/LD-E（attr）/LD-D（可选）已拆已定案（第 32 轮）待 #3 续做**；③ **F1-E 批五 SHEET_CONFIG 方案已定（第 33 轮）git 实测仍零开工**（HEAD 无 icon_config/get_icon_config/§7 icon 段提交）→ 挂账观察（**跨 1 轮**）；④ **RELIC 全批方案已定（第 31 轮）git 实测仍零开工** → 挂账观察（**跨 3 轮**）；⑤ D30-T3 上传 + D30-EXIT = 纯 Owner/#4 域维持；⚠️ **build/ = 08-18 23:22 产物（`2aeb717` 授权导出：含 F-45~48 + F1-E-4-1，不含其后 F-49 + F1-E-4 消费端 + LD-A）→ 传送门/宝箱/批四抽表/LD 验证需最新代码或下次打包**（交 Owner/总指挥）。

## 当前开发日：Day 31（LEVEL_DESIGN + RELIC 同窗口 · F1-E 批六承接方 #3 · 拆解 `6636889` F1-E-6 段唯一事实源）

### 任务1：F1-E-6-1【W2】T-004 初始枪抽表（数据侧）· 风险：低

- **改动**：① `docs/GameData.xlsx` weapons sheet 加 1 行 `starting_gun`（**9 字段与 `_equip_default_weapon()` 内联现值逐一一致**：id=starting_gun / name=初始枪 / weapon_type=ranged（category 归 ranged 列）/ **damage=8**（消费键为 damage 非 base_damage）/ **cooldown=0.4**（↔ fire_rate 2.5，消费端 1.0/cooldown 换算）/ **range=180**（消费键为 range 非 attack_range）/ knockback=0 / pierce=0 / max_level=1 单级（levels 子表可不填或填 Lv1 行与基础字段一致）；**projectile_speed/lifetime 两键不进表**（build_weapon_from_data :162 无消费点，进了即死键——F1-G 先例违规）；**source_id 留空** = day13 硬门槛）② data_schema **零新注册**（weapons :199-204 已有）③ excel_export **零改动**（weapons 构建已有）④ 导出 → weapons.json +starting_gun 条目（ranged 分类），**其余 JSON 零 diff 断言**（前五批先例）。
- **风险**：**低**。数据面常规（1 行 sheet）；硬门槛 = starting_gun 9 键与内联现值零漂移（漏一项 = 探针红）+ source_id 缺失 + 其余 JSON 零 diff。⚠️ **WPS 锁坑**：Excel 被 WPS 打开时导出写回总览报 PermissionError（F1-G-尾教训），执行者注意。
- **验证**：excel_export --check-only EXIT=0 + JSON 校验通过 + weapons.json ranged 类含 starting_gun 且键与内联现值一致（零漂移）+ source_id 缺失 + 其余 JSON 零 diff。

### 任务2：F1-E-6-2【W1】T-004 消费端改读 · 风险：低-中（⭐ 新阻塞点裁决落地）

- **改动**：`scripts/weapons/weapon_controller.gd` `_equip_default_weapon()`（:59-71）改走：`var w := build_weapon_from_data("starting_gun")`（:134 同文件方法，内部 DataLoader.get_weapon 读表 :135）→ **非 null：补 `w.projectile_speed = 360.0` + `w.lifetime = 1.5`（对齐内联现值零行为变化，⭐第 34 轮裁决）** → `equip_weapon(w)`；**null/异常 → 保留现内联构造兜底**（防 Excel 未导出/数据缺失零崩，F 系列缺省兜底约定）；⚠️ 装配后 9 键逐键核对（与内联现值一致，抽表零数值变化）。**备选 C（可选）**：build_weapon_from_data :162 补 `projectile_speed`/`lifetime` 消费键（默认 400/推导兜底，其他 36 武器零漂移）→ 两键可进表，执行者二选一登记。
- **风险**：**低-中**。唯一新增风险 = **build_weapon_from_data 数据驱动路径不装配 projectile_speed/lifetime（:162 实证）** → 已裁决补设两键；硬门槛 = **day13_build_check :617-625 零改动**（starting_gun source_id 留空 → 无 source_id 占位武器不写 inventory）。⚠️ fire_rate 换算注意：表 cooldown=0.4 → 装配 fire_rate=2.5（断言按换算后值）；未装配数据缺失 → 内联兜底 weapon_name 仍「初始枪」。**替代方案**：若实测 build_weapon_from_data 返回异常（如 DataLoader.get_weapon 对 starting_gun 分类解析失败），退回纯内联现状 + 仅数据侧探针验证（等价零回归）。
- **验证**：白盒 `_equip_default_weapon` → weapon 9 键与内联现值逐一相等（含补设两键）；Excel 改 damage=9 → 导出 → 装配 base_damage=9（端到端双跑，F1-散 §1 先例）→ 强制改回 8 重导出；删表行/未知 id → 内联兜底仍可装备（weapon_name 仍「初始枪」）；day13 :617-625 零改动复跑。

### 任务3：F1-E-6-3【W2】T-022 skill_icon_map 抽表（数据侧）· 风险：低

- **改动**：① `docs/GameData.xlsx` 新增 `skill_icon_map` sheet（**5 行 × id/icon_index 双行表头**：id = se_skill_fireball/se_skill_deploy_turret/se_skill_blade_burst/se_skill_holy_shield/se_skill_sword_arc，icon_index = 0/1/2/3/4 **与 SKILL_ICON_MAP const 现值逐一一致**）② `tools/data_schema.py` 注册 `skill_icon_map`（file: presentation.json / root: "skill_icon_map" / kind: "dict" / key: id / json_cols: []，仿 fx_config :261-265 先例）③ `tools/excel_export.py` presentation 构建段（fx_config 段 :502-511 后）追加 skill_icon_map 解析（id 主键 → int(icon_index)，仿 fx_config 段模式）+ **:512 files dict 追加第 6 键 "skill_icon_map"（勿覆盖既有 4 键 + 批五 icon_config 第 5 键）** ④ 导出 → presentation.json +skill_icon_map 5 项，**其余 16 JSON 零 diff 断言**。
- **风险**：**低**。数据面常规（5 行 sheet + 注册 + 构建三小点）；硬门槛 = skill_icon_map 5 键 icon_index 与 const 现值零漂移 + 其余 JSON 零 diff。⚠️ 执行序注意：批五（icon_config）尚未收口 → 若 #3 先做批六再补批五，:512 files dict 键序会先 5 后 6，两批各自 commit 各自断言，勿混批。
- **验证**：excel_export --check-only EXIT=0 + JSON 校验通过 + skill_icon_map 5 键齐 + icon_index 与 const 现值一致（零漂移）+ 其余 16 JSON 零 diff。

### 任务4：F1-E-6-4【W1】T-022 消费端改读 · 风险：低

- **改动**：① `scripts/autoload/data_loader.gd` 新增 `get_skill_icon_index(skill_id: String) -> int`（懒加载 presentation.json skill_icon_map 缓存 + `_skill_icon_map` 空表标记仿 :36 后字段区，**is_empty 重试标记 F3 §4 禁新增 bool**；命中 → int 值 / 未命中·空表 → -1，仿 get_fx_config :666-678 范式）；② `scripts/ui/hud.gd` `_apply_skill_icon` :354 与 `_apply_skill_slot_icon` :403 的 `SKILL_ICON_MAP.get(skill_id, -1)` 改走 `get_skill_icon_index(skill_id)`（**DataLoader 接口命中优先，未命中 → 回退 `SKILL_ICON_MAP.get(skill_id, -1)` const 兜底**；hud 为实例节点 → `get_node_or_null("/root/DataLoader")` 先例 vfx_player :97，不可达 → 直接 const 查值）；**SKILL_ICON_MAP const 保留为兜底**（day31_skill_icon_check §5 :57-81 直接读 const 零改动硬门槛）；未知 id push_warning（:356-357 槽 0 路径）行为不变。**⚠️ 零行为变化**（仅映射来源数据化）。槽 1/2 掉落技能未映射 → 灰显现状不变（T-022 只抽现 const 5 键，掉落技能图标 = 技能遗物扩展域，登记 TECH_DEBT 或留 PS-EXIT）。
- **风险**：**低**。纯新增接口 + 两处消费点替换；硬门槛 = day31_skill_icon_check 零改动 + 未知 id 行为不变。
- **验证**：白盒 `_apply_skill_icon` 走 skill_icon_map 路径（帧纹理非空）；表清空 → 回退 const 仍映射（帧纹理非空）；未知 id 仍 push_warning（槽 0）；槽 1/2 掉落技能未映射 → 灰显不变；get_skill_icon_index("se_skill_fireball")==0 / 未知名==-1。

### 任务5：F1-E-6-5【W1】探针扩展 · 风险：低

- **改动**：`tools/day31_presentation_check.gd` 尾部（批五 §7 icon 段后，若批五未先行则按当前尾段追加）**+§8 skill_icon 段 ≥8 断言**（仿 ⑥ fx 段模式）：skill_icon_map 5 键齐 / 键集合与 SKILL_ICON_MAP 一致（零多余零缺失）/ 逐键 icon_index 与 const 现值一致（抽表零漂移）/ 改 Excel 一例 icon_index → 导出 → get_skill_icon_index 变化（端到端双跑）/ 空表兜底 const 仍映射（白盒）/ 未知 id push_warning 保留 / 槽 1/2 掉落技能灰显不变 / T-004 侧：weapons.json starting_gun 9 键零漂移 + source_id 缺失断言（可并入 §8 或独立段，执行者定）。
- **风险**：**低**。纯探针扩展；**回归硬门槛 = day31_skill_icon_check（直接读 const）+ day13_build_check :617-625（无 source_id 不污染 inventory）零改动** + 64 件套 1602 锚点 + baseline CLEAN。
- **验证**：day31_presentation_check **≥307/307**（299+8，批五未先行时按实际尾段计数）+ 全量回归（当前 59/64 挂 D-26，EXIT 门槛统一挂等复跑）。

### 任务6：F1-E-6-EXIT【W5】收口 · 风险：低

- **验证**：回归 **64 件套（1602 锚点）**（当前 59/64 5 FAIL 挂 D-26，**收口以 D-26 复跑恢复后全绿为准**）+ day31_presentation ≥307（299+8）+ baseline **BASELINE CLEAN** + excel_export --check-only EXIT=0 + F1-E 行 **6/7 批**标记 + TECH_DEBT_ISSUES **T-004/T-022 转已收口**。

### 任务7：LEVEL_DESIGN LD-B/C/E/D——LD-A 已收口解锁，挂账观察（拆解后首轮起算）

- **现状**：LD-A1/A2/A3 [x]（`96e4cd5` 数据地基 + FK 三态 + --check-only 修复 + 三接口 + 探针 24/24）+ LD-A-EXIT [~]（仅回归挂 D-26，D-020 不代修待收口）→ **LD-B（固定出生点）/ LD-C（Boss 演出）/ LD-E（attr）/ LD-D（可选）仍 [ ] 待 #3 执行**（方案已定 SOLUTION_PLAN 第 32 轮，锚点复核 9 项一致）；**本轮 git 实测确认 LD-B 仍未开工**（HEAD 无 spawn 消费点/_get_spawn_position 提交）→ 挂账观察（LD-A 收口后首轮），承接方 = #3 执行者。
- **执行序**（第 32 轮定案不变）：LD-B 出生点（F-48 不回归：day31_flee_bound 18/18 零改动）→ LD-C Boss 演出 → LD-E attr → LD-D 可选挂 TECH_DEBT_PLAN。

### 任务8：F1-E 批五 SHEET_CONFIG + RELIC 全批——挂账观察（批五跨 1 轮 / RELIC 跨 3 轮）

- **批五**：方案已定（SOLUTION_PLAN 第 33 轮，锚点复核 6 项一致）；**本轮 git 实测确认仍未开工**（HEAD=`6636889` 无 icon_config/get_icon_config/§7 icon 段提交）→ **挂账观察（跨 1 轮）**，承接方 = #3 执行者；硬门槛 = day31_items_atlas/skill_icon 直接读 const 零改动 + get_frame_count 三探针行为保持 + 63 件套口径（现 64 件套）。
- **RELIC**：方案已定（SOLUTION_PLAN 第 31 轮）；**本轮 git 实测确认仍零开工**（HEAD 无 day31_relic_*/stats 改名提交）→ **挂账观察（跨 3 轮）**，承接方 = #3 执行者；执行序 = RELIC-A（独立低成本先行）→ RELIC-0（数据地基）→ RELIC-F/E → RELIC-B/C/D → EXIT。
- **风险提示**：两批均为「拆解+方案齐备」状态，唯一风险 = 承接方持续未开工（#3 第 64 轮优先做 LD-A，本窗口可连续推进 LD-B→批五/批六→RELIC-A，执行序由 #3 排）。

### 任务9：D30-T3 上传 + D30-EXIT 发布收口——纯 Owner/#4 域，无需方案

- **改动**：无（本岗红线：外部动作 + 测试岗产出）。D30-T3 上传 [ ] = 等 Owner 明确确认（目标资产库）；D30-EXIT [~]/[ ] = TEST_REPORT 发布摘要待 #4 落盘 + 最终标记。⚠️ **build/ 观察维持：08-18 23:22 产物（`2aeb717`）含 F-45~48 + F1-E-4-1，不含其后 F-49 + F1-E-4 消费端 + LD-A** → 传送门/宝箱/批四抽表/LD 验证需最新代码或下次打包（交 Owner/总指挥）。

### 风险总表（本轮）

| 任务 | 风险 | 说明 / 替代方案 |
|---|---|---|
| F1-E-6-1 T-004 数据侧 | 低 | 1 行 sheet + 零注册零构建改动；9 键零漂移 + source_id 缺失 + 其余 JSON 零 diff；WPS 锁坑 |
| F1-E-6-2 T-004 消费端 | 低-中 | ⭐ build_weapon_from_data :162 不消费 projectile_speed/lifetime = 新阻塞点已裁决（两键不进表 + 消费端补设 360/1.5）；备选 C（builder 补消费键默认兜底）可选；替代 = 纯内联现状等价零回归 |
| F1-E-6-3 T-022 数据侧 | 低 | 5 行 sheet + 注册 + 构建；零漂移 + 16 JSON 零 diff；勿与批五 icon_config 混批 |
| F1-E-6-4 T-022 消费端 | 低 | get_skill_icon_index 纯新增 + 两处替换；day31_skill_icon_check 零改动硬门槛 |
| F1-E-6-5 探针扩展 | 低 | ≥8 断言；两探针零改动 + 64 件套 1602 锚点 |
| F1-E-6-EXIT | 低 | 6/7 批标记 + T-004/T-022 转收口；EXIT 挂 D-26 复跑 |
| LD-B/C/E/D | 中 | 方案已定第 32 轮；LD-A 收口已解锁；风险 = LD-B 消费端与 F-48 不回归面（flee_bound 18/18 零改动） |
| 批五 / RELIC | 低-中 | 方案已定（33/31 轮）；唯一风险 = 承接方未开工（跨 1/3 轮挂账观察） |
| D30-T3/EXIT | 低 | Owner/#4 域；build/ 不含 F-49 + F1-E-4 消费端 + LD-A 交 Owner/总指挥核实 |

### 维持已定方案边界（不重复写）

- **F1-E 批七**（炮台默认）：沿前六批范式 + 各批先例推进，承接方开工时按需拆解（批六收口后再拆批七）。
- **LD-B/C/E/D**：方案已定（SOLUTION_PLAN 第 32 轮）不重写，执行按 32 轮执行序。
- **F-49（传送门+宝箱）**：已落地（`4f1e791` 闭环 + day31_portal_check 24/24）——非本岗方案对象；真人回归面交 #5；RELIC-E 落地时宝箱奖励升级三选一（本机制为地基）。
- **F-45~F-49 主观回归面 / E-0 终审完整局 / AF-P0 / PS-EXIT**：交 #5 真人（主观项不阻塞机器侧）。
- **F-16~F-44 真人回归 / MainMenu 待真人确认 / Day 28 性能段 / 章节 Boss 映射（已拍板三 Boss [6,10,14]）**：开放项清单维持（见 PLAYTEST 追踪区）。

## 🔴 红线遵守（本轮）

不写代码、不改 `.gd/.tscn/.tres/.json` 游戏文件、不 git commit、不跑探针。仅覆盖写 `docs/SOLUTION_PLAN.md`（顶部新第 34 轮段，历史段完整保留）+ 在 `docs/TASKS.md` 标注（F1-E-6 段「方案已定（SOLUTION_PLAN.md 第 34 轮）」+ LD-A 收口确认 + 批五/RELIC 挂账观察 + 第 64 轮状态块后补方案师第 34 轮确认块）。工作区在途用户会话美术资产（lain 帧/AI 美术工具/2 脚本 M = D-26 阻塞源）+ #4 TEST_REPORT.md 不碰（本轮仅 SOLUTION_PLAN/TASKS 两 docs 挂账，交下一岗入库）。

---

# 方案计划（2026-08-19 02:4x · 方案师第 33 轮 · F1-E 批五 SHEET_CONFIG 正式方案（#2 第 63 轮拆解完成兑现）+ RELIC/LD 挂账观察 + build 观察）

## 📌 本轮判定（方案师第 33 轮）

> **P0 检查（PLAYTEST 追踪区增量 #89 之后无新增量 · 反馈专员已改 2h→4h 一轮，下一轮 02:38）**：F-45~F-49/AF-P0 全 🟢 已修复·待真人回归；🟡 仅 H-05 家族主观审阅域（非机器可执行）→ **🔴P0 无新增 / 🟠 无用户拍板调度指令 → 无新机器可验证 P0 需纳入本轮**。
>
> **🟠 关键调度输入（本轮兑现上轮承诺）**：`docs/TASKS.md` F1-E-5 段（**#2 第 63 轮 `95752eb` 02:0x 函数级拆解**）——F1-E 第五批 **SHEET_CONFIG 图标配置抽表**（T-020）：icon_config sheet 3 行（weapons 40 / items 54 / skills 5）→ data_schema 注册 → excel_export 构建 presentation.json icon_config → DataLoader `get_icon_config`（懒加载 + Vector2i 组装）→ IconAtlas.get_icon/get_frame_count 消费改读（**SHEET_CONFIG const 保留兜底** = day31_items_atlas_check/day31_skill_icon_check 直接读 const 零改动硬门槛）+ **static 类经 `Engine.get_main_loop()` 访问 Autoload 技术要点** + day31_presentation_check +§7 icon 段 13 断言 → 回归 63 件套。承接方 = #3 执行者（D-015 交接）。→ **本轮方案师按拆解写批五正式方案（实测复核锚点，见任务 1-5）**。
>
> **git 实测**：HEAD=`95752eb`（#2 第 63 轮 · 02:0x；第 62 轮后 +3 = `f67630b` **F1-E-4-2~4-4 消费端收口**（get_fx_config 懒加载 + vfx_player.set_effect 改读 + day31_presentation +§6 fx 段 13 断言 286/286）/ `681ab36` **第 63 轮收口**（回归 **63/63 · 1578 断言**全绿 + T-019 转已收口 + **F1-E 4/7 批** + portal 并入 runner = TEST_REPORT #62 观察兑现）/ `95752eb` **批五拆解**）；**工作区在途 = 用户会话美术资产（lain 动画帧 ×8 + tools/make_*_frame.py + player_anim.gd + sprite_frame_factory.gd M + 人物动画/）——美术域非本岗改动面，红线内不碰**。
>
> **锚点实测复核结论（本轮核心产出，供执行者直接使用）**——与 #2 第 63 轮拆解文本**逐一一致（3 处路径/行号细化已确认）**：
> 1. **icon_atlas.gd**（`scripts/utils/icon_atlas.gd`）：SHEET_CONFIG 3 键 **:8-24**（weapons 40 / items 54 / skills 5，各含 path/frame_count/frame_size **Vector2i(32,32)** 三行同值）——与拆解一致；`get_icon` 函数体 :32-57（拆解写 :37-49 为关键行为行：:37-39 SHEET_CONFIG.has 未知 sheet push_warning / :41 `var config: Dictionary = SHEET_CONFIG[sheet_name]`（**改造落点**）/ :42-44 _get_texture load(path) null 返回 / :46-49 index 越界 push_warning）/ `get_frame_count` :71-74（:72 SHEET_CONFIG.has → frame_count / 未知 0，**改造落点**）/ `clear_cache` :77-79——**全链一致**；
> 2. **硬门槛探针（const 直读确认）**：`day31_items_atlas_check.gd:27` `IconAtlas.SHEET_CONFIG["items"]`（+ :36 get_icon 54 帧遍历 + :57 越界 54 拦截）/ `day31_skill_icon_check.gd:28` `IconAtlas.SHEET_CONFIG["skills"]` + :37 `cfg["frame_count"]==5` + :38 `get_frame_count("skills")==5`——**SHEET_CONFIG const 保留 = 两探针零改动**；**get_frame_count 动态读消费面 3 探针**：day11_12_passive_check.gd:482 / day20_relic_check.gd:369 / day24_f13_check.gd:338（`atlas_script.call("get_frame_count", "items")`，抽表命中返回现值 54 = 行为保持，改 Excel 帧数则三探针自动跟随）；`day7_weapon_data_check.gd:240-250` 仅注释提及类常量（零影响）；
> 3. **data_loader.gd 实际路径 = `scripts/autoload/data_loader.gd`**（拆解文本省略子目录）：`_fx_map` 缓存字段 :36 / `get_fx_config` **:661-673** 仿写范式（:662 is_empty 懒加载重试标记 → :666 cfg 取用 → :668 duplicate → :670-671 size JSON → Vector2i 组装 → :673 未命中空字典）——**get_icon_config 仿此（frame_size 组装同 :670-671 先例）**；
> 4. **excel_export.py :435-449** fx_config 构建段（:440-448 id 主键 + size_w/size_h → `{"x","y"}` 组装）+ **:449 `files["presentation.json"]` 现 5 根键**（enemy_sprites/behavior_map/audio_map/fx_config）——**批五追加 icon_map 构建 + :449 加第 6 键 "icon_config"（勿覆盖既有键）**；**data_schema.py :252-258** fx_config 注册范式（file: presentation.json / root: fx_config / kind: dict / key: id / json_cols: []）——icon_config 注册仿此；
> 5. **day31_presentation_check.gd 结构确认**：单 `_run()` 顺序执行 + 注释分段（① 键集一致 :33-50 / ② 逐条零漂移 :52-82 / ③ DataLoader 消费 :84-105 / ④ behavior_map :107-135 / ⑤ audio_map :137-16x / ⑥ fx_config :202-尾，**286/286**）——**+§7 icon 段直接仿 ⑥ fx 段模式**（键集一致/逐键 path·frame_count·frame_size 零漂移/get_icon_config 消费/白盒 E2E 双跑/空表兜底/未知键 push_warning）；
> 6. **static 类访问 Autoload 技术要点确认**：vfx_player（实例节点）用 `get_node_or_null("/root/DataLoader")`（:97）；**IconAtlas 为 `class_name extends RefCounted` 全静态工具类（:4-5），实例节点路径不可用 → 须 `Engine.get_main_loop().root.get_node_or_null("DataLoader")`**（拆解技术要点成立，无现成 static 先例 = 新范式）；`--script` 探针环境 get_node_or_null 返回 null → 回退 const 兜底天然兼容（直接读 const 的 day31_items_atlas/skill_icon 两探针不受影响）。
>
> **结论**：① **F1-E 批五 SHEET_CONFIG = 本轮方案主产出**（拆解完成即解锁，方案师按纪律写正式方案，承接方 = #3 执行者，执行序 5-1→5-2→5-3→5-4→EXIT 每任务一收口 commit 带 F1-E-5 编号）；② **F1-E 批四 FX 全收口确认**（`681ab36`：4/7 批，T-019 转已收口）→ 上轮「4-2~4-4 待 #3」挂账**全解除**；③ **RELIC 方案已定（第 31 轮）git 实测仍零开工**（HEAD 无 day31_relic_*/stats 改名提交）→ 挂账观察维持（**跨 2 轮**）；④ **LEVEL_DESIGN 方案已定（第 32 轮）拆解后首轮观察仍零开工**（HEAD 无 spawn_points/boss_phase_events sheet / get_spawn_points / day31_level_design_* 提交）→ 新挂账（跨 1 轮）；⑤ D30-T3 上传 + D30-EXIT = 纯 Owner/#4 域维持；⚠️ **build/ = 08-18 23:22 产物（HEAD=`2aeb717` 授权导出：含 F-45~48 + F1-E-4-1，不含其后 F-49 传送门 + F1-E-4 消费端）→ 传送门/宝箱/批四抽表验证需最新代码或下次打包**（交 Owner/总指挥）。**回归硬门槛口径 = 63 件套 · 1578 断言**（`681ab36` 实证，批五 EXIT 以 63/1578 为准）。

## 当前开发日：Day 31（LEVEL_DESIGN + RELIC 同窗口 · F1-E 批五承接方 #3 · 拆解 `95752eb` F1-E-5 段唯一事实源）

### 任务1：F1-E-5-1【W2】Excel 抽表（数据侧）· 风险：低-中

- **改动**：① `docs/GameData.xlsx` 新增 `icon_config` sheet（**3 行 × id/path/frame_count/frame_size_w/frame_size_h 双行表头**：id = weapons/items/skills（与 SHEET_CONFIG 键一致）；path = `res://assets/sprites/ui/weapons.png` / `res://assets/sprites/ui/items.png` / `res://assets/sprites/skills/skills.png` **与 const 现值逐一一致**；frame_count = 40/54/5；frame_size_w/h = 32/32 三行（拆列仿 fx_config size_w/size_h 先例 :445-447））② `tools/data_schema.py` 注册 `icon_config`（file: presentation.json / root: "icon_config" / kind: "dict" / key: id / json_cols: []，仿 fx_config :255-258）③ `tools/excel_export.py` presentation 构建段（:435-449 后）追加 icon_map 解析（id 主键 → {path, frame_count, frame_size: {"x": int(frame_size_w), "y": int(frame_size_h)}}，仿 fx_config 段 :440-448）+ **:449 files dict 追加第 6 键 "icon_config": icon_map** ④ 导出 → presentation.json +icon_config 3 项，**其余 16 JSON 零 diff 断言**。
- **风险**：**低-中**。数据面常规（3 行 sheet + 注册 + 构建三小点）；**硬门槛 = 其余 16 JSON 零 diff**（前四批先例）+ icon_config 3 键 path/frame_count/frame_size 与 IconAtlas const 现值**零漂移**（漏一项 = §7 探针红）。⚠️ **WPS 锁坑**：Excel 被 WPS 打开时导出写回总览报 PermissionError（F1-G-尾教训），执行者注意。
- **验证**：excel_export --check-only EXIT=0 + JSON 校验通过 + icon_config 3 键齐 + 与 const 现值一致（零漂移）+ 其余 16 JSON 零 diff。

### 任务2：F1-E-5-2【W1】DataLoader 接口 · 风险：低

- **改动**：`scripts/autoload/data_loader.gd` 新增 `get_icon_config(sheet_name: String) -> Dictionary`（**仿 get_fx_config :661-673 范式**）：字段区补 `var _icon_map: Dictionary = {}`（:36 附近，注释 F1-E-5）；懒加载 presentation.json icon_config 缓存（is_empty 重试标记）+ 命中 → duplicate + frame_size JSON → Vector2i 组装（**仿 :670-671 先例**）+ 未命中/损坏 → 空字典（消费端 const 兜底零崩）。
- **风险**：**低**。纯新增函数零连锁（不触碰既有接口）；`_icon_map` 命名与拆解一致，勿与既有 `_fx_map`/`_audio_map` 混淆。
- **验证**：白盒读 get_icon_config("items") → 键齐全（path/frame_count/frame_size: Vector2i(32,32)）；改 Excel frame_count 一例 → 导出 → 返回值变化（**端到端双跑**，F1-散 §1 先例）。

### 任务3：F1-E-5-3【W1】IconAtlas 消费改读 · 风险：低-中（static 类访问 Autoload 新范式）

- **改动**：`scripts/utils/icon_atlas.gd` 新增静态私有 `_resolve_icon_config(sheet_name: String) -> Dictionary`：`Engine.get_main_loop().root.get_node_or_null("DataLoader")` → 非空则 `get_icon_config(sheet_name)` 命中（非空 + has path/frame_count/frame_size）优先返回；未命中/空表/无 DataLoader → `SHEET_CONFIG.get(sheet_name, {})` const 兜底；`get_icon` :41 `SHEET_CONFIG[sheet_name]` → `_resolve_icon_config(sheet_name)`（**前置 :37 SHEET_CONFIG.has 未知 sheet push_warning 保留**，_resolve 空字典分支按原样 warn+return）；`get_frame_count` :72-73 改走（SHEET_CONFIG.has → `_resolve_icon_config` 取 frame_count / 未知 0）；**SHEET_CONFIG const 保留为兜底**。
- **风险**：**低-中**。双硬门槛：① **day31_items_atlas_check.gd:27 + day31_skill_icon_check.gd:28/:37-38 直接读 const 零改动**（const 保留即满足）；② **get_frame_count 行为保持**（day11_12 :482 / day20 :369 / day24_f13 :338 动态读，抽表命中返回现值 = 行为一致）。⚠️ **唯一新增风险 = static 类经 Engine.get_main_loop() 访问 Autoload 为新范式**（无现成先例）：若特定环境（如 --script 探针）Engine 主循环不可达 → get_node_or_null 返回 null → 回退 const 零崩（**拆解已注明天然兼容**）。**替代方案**：若实测 Engine 访问在消费场景异常，退回仅 const（现状即等价零回归，抽表只走数据侧探针验证）。
- **验证**：白盒 get_icon("items", 0) 走 icon_config 路径（返回值非空）；_icon_map 清空 → 回退 const 仍可 get_icon（load 不崩）；未知 sheet 仍 push_warning；get_frame_count 未知 sheet 仍 0；**外部调用方（hud/shop/level_up_panel 等经 IconAtlas.get_icon）零改动**（解析内聚在 icon_atlas 内部，拆解定案）。

### 任务4：F1-E-5-4【W1】探针扩展 · 风险：低

- **改动**：`tools/day31_presentation_check.gd` 尾部（⑥ fx 段后）**+§7 icon 段 ≥13 断言**（仿 ⑥ 模式）：icon_config 3 键齐 / 键集合与 SHEET_CONFIG 一致（零多余零缺失）/ 逐键 path·frame_count·frame_size 与 const 现值逐一一致（**抽表零漂移**）/ get_icon_config 消费（items 键齐 + frame_size == Vector2i(32,32) + 未知名空字典）/ 白盒改 _icon_map frame_count → 返回值变化（E2E 双跑还原）/ 空表兜底 const 仍可 get_icon（白盒 IconAtlas）/ 未知 sheet_name push_warning 保留 / get_frame_count 行为一致。
- **风险**：**低**。纯探针扩展；**回归硬门槛 = day31_items_atlas_check + day31_skill_icon_check 零改动** + 63 件套 1578 断言 + baseline CLEAN。
- **验证**：day31_presentation_check **≥299/299**（286+13）。

### 任务5：F1-E-5-EXIT【W5】收口 · 风险：低

- **验证**：回归 **63 件套（1578 断言）** + day31_presentation ≥299 + baseline **BASELINE CLEAN** + excel_export --check-only EXIT=0 + F1-E 行 **5/7 批**标记 + TECH_DEBT_ISSUES **T-020（SHEET_CONFIG 抽表）转已收口**。

### 任务6：RELIC 遗物扩展（全批已拆 + 方案已定第 31 轮）——挂账观察维持（跨 2 轮）

- **现状**：方案已定（SOLUTION_PLAN 第 31 轮，锚点实测复核：stats.json .stats.offensive[2]/.stats.economy[3] + desc_builder.gd:32-33 + items relic 2 件 + data_loader:437 + save_system 缺省容错）；**本轮 git 实测确认仍未开工**（HEAD=`95752eb` 无 day31_relic_*/stats 改名提交）→ **挂账观察维持（跨 2 轮）**，承接方 = #3 执行者（D-015 交接，拆解+方案齐备即开工）。
- **执行序**（第 31 轮定案不变）：RELIC-A（独立低成本先行）→ RELIC-0（数据地基）→ RELIC-F/RELIC-E（P0 独立）→ RELIC-B/C/D（依赖 0）→ RELIC-EXIT。

### 任务7：LEVEL_DESIGN 关卡设计扩展（全批已拆 + 方案已定第 32 轮）——挂账观察（拆解后首轮）

- **现状**：方案已定（SOLUTION_PLAN 第 32 轮，锚点实测复核 9 项一致）；**本轮 git 实测确认仍未开工**（HEAD=`95752eb` 无 spawn_points/boss_phase_events sheet / get_spawn_points / day31_level_design_* 探针提交）→ **挂账观察（跨 1 轮）**，承接方 = #3 执行者（D-015 交接）。
- **执行序**（第 32 轮定案不变）：LD-A 数据地基（前置）→ LD-B 出生点 → LD-C Boss 演出 → LD-E attr（D 可选挂 TECH_DEBT_PLAN）。

### 任务8：D30-T3 上传 + D30-EXIT 发布收口——纯 Owner/#4 域，无需方案

- **改动**：无（本岗红线：外部动作 + 测试岗产出）。D30-T3 上传 [ ] = 等 Owner 明确确认（目标资产库）；D30-EXIT [~]/[ ] = TEST_REPORT 发布摘要待 #4 落盘 + 最终标记。⚠️ **build/ 观察维持：08-18 23:22 产物（`2aeb717`）含 F-45~48 + F1-E-4-1，不含其后 F-49 + F1-E-4 消费端** → 传送门/宝箱/批四抽表验证需最新代码或下次打包（交 Owner/总指挥）。

### 风险总表（本轮）

| 任务 | 风险 | 说明 / 替代方案 |
|---|---|---|
| F1-E-5-1 数据侧 | 低-中 | 3 行 sheet + 注册 + 构建；16 JSON 零 diff + 3 键零漂移硬门槛；WPS 锁坑 |
| F1-E-5-2 DataLoader 接口 | 低 | 仿 get_fx_config :661-673 纯新增函数；_icon_map 命名勿混 |
| F1-E-5-3 IconAtlas 改读 | 低-中 | const 兜底双硬门槛（items_atlas/skill_icon 直读 const + get_frame_count 行为保持）；**static 类 Engine 访问新范式**，异常回退 const 零崩；替代 = 仅 const 现状等价 |
| F1-E-5-4 探针扩展 | 低 | 仿 ⑥ fx 段；两图标探针零改动 + 63 件套 1578 断言 |
| F1-E-5-EXIT | 低 | 5/7 批标记 + T-020 转收口 |
| RELIC 全批 | 低-中 | 方案已定第 31 轮；**唯一风险 = 承接方持续未开工（跨 2 轮挂账观察）** |
| LEVEL_DESIGN 全批 | 中 | 方案已定第 32 轮；**风险 = 承接方未开工（拆解后首轮观察）+ LD-A 数据地基前置依赖** |
| D30-T3/EXIT | 低 | Owner/#4 域；build/ 不含 F-49 + F1-E-4 消费端交 Owner/总指挥核实 |

### 维持已定方案边界（不重复写）

- **F1-E 批六~七**（初始武器 → 炮台默认）：沿前五批范式 + 各批先例推进，承接方开工时按需拆解（批五收口后再拆批六）。
- **F-49（传送门+宝箱）**：已落地（`4f1e791` 闭环 + day31_portal_check 24/24）——非本岗方案对象；真人回归（传送门显眼度 / 先捡宝箱再进 / Boss 关同流程）交 #5。
- **F-45~F-49 主观回归面 / E-0 终审完整局 / AF-P0 / PS-EXIT**：交 #5 真人（主观项不阻塞机器侧）。
- **F-16~F-44 真人回归 / MainMenu 待真人确认 / Day 28 性能段 / 章节 Boss 映射（已拍板三 Boss [6,10,14]）**：开放项清单维持（见 PLAYTEST 追踪区）。

## 🔴 红线遵守（本轮）

不写代码、不改 `.gd/.tscn/.tres/.json` 游戏文件、不 git commit、不跑探针。仅覆盖写 `docs/SOLUTION_PLAN.md`（顶部新第 33 轮段，历史段完整保留）+ 在 `docs/TASKS.md` 标注（F1-E-5 段「方案已定（SOLUTION_PLAN.md 第 33 轮）」+ 批四收口确认 + RELIC/LD 挂账观察 + 第 63 轮状态块后补方案师第 33 轮确认块）。工作区在途用户会话美术资产（lain 帧/AI 美术工具/2 脚本 M）不碰（本轮仅 SOLUTION_PLAN/TASKS 两 docs 挂账，交下一岗入库）。

---

# 方案计划（2026-08-19 00:4x · 方案师第 32 轮 · LEVEL_DESIGN 关卡设计扩展正式方案（#2 第 62 轮拆解完成兑现）+ F1-E 批四 4-1 收口确认 + RELIC 挂账观察）

## 📌 本轮判定（方案师第 32 轮）

> **P0 检查（PLAYTEST 追踪区增量 #89 · 08-18 23:4x 反馈专员 · F-49 通关传送门+宝箱落地登记）**：无新增机器可验证 P0（F-01~F-49/AF-P0 全 🟢 已修复·待真人回归；🟡 仅 H-05 家族主观审阅域）；F-49（`4f1e791` 传送门延迟结算 + loot_chest 宝箱占位金币 50/经验 30，day31_portal_check 24/24 + 回归 62/62 全绿）→ **🔴P0 无新增**。
>
> **🟠 关键调度输入（本轮兑现上轮承诺）**：`docs/LEVEL_DESIGN_SPEC.md`（08-18 22:57 用户拍板 · 规格 15.8KB）已由 **#2 第 62 轮（`9ebbf5f` 00:05）完成函数级拆解**——三主目标：① 固定出生点 **spawn_points 表**（根治 F-48 随机死角 → 点位固定可读可控可设计演出感）② 独立 **boss_phase_events 演出表**（横幅/特效/音效/台词/震屏/buff 一表打通）③ **正向属性状态 attr**（通用 buff，金手指 = +900% 整局 attr 概念成立但本期记 TECH_DEBT）；总指挥 D-014 已拍板 §8 五决策点（inset 40 / Boss 登场 anchor(0.5,0.3) / dialogue 横幅占位 / 特殊波挂 TECH_DEBT / attr 白名单实测登记制）→ **本轮方案师按规格 + 拆解写 LEVEL_DESIGN 正式方案（实测复核锚点，见任务 1-8）**。
>
> **git 实测**：HEAD=`9ebbf5f`（#2 第 62 轮 · 00:05；第 61 轮后 +5 = `4f1e791` **F-49 传送门+宝箱** / `144321a` 增量 #89 / `a9a8c6f` D-019 复用铁律 / `e49eb5b` #1 第 66 轮 / `9ebbf5f` **LEVEL_DESIGN 函数级拆解**）；**工作区 = docs/TEST_REPORT.md M（#4 在途）+ `??` docs/art_ai/ref_sheets/ + tools/make_char_ref_sheet.py + tools/make_final_ref_sheet.py（美术辅助工具，非本岗域）——零游戏代码在途，红线内不碰**。
>
> **锚点实测复核结论（本轮核心产出，供执行者直接使用）**——与 #2 第 62 轮拆解文本**逐一一致（2 处行号微差已修正）**：
> 1. **enemy_spawner.gd**（实际路径 `scripts/enemy/enemy_spawner.gd`，拆解文本省略子目录）：`:81-82` swarm count×2 / `:147-148` swarm HP×0.5 / `:163` 生成调用点 / `:172` `_get_random_spawn_position()`（min_dist 110 / 40 次尝试 / `_clamp_to_ground` 兜底）/ `:196` `_clamp_to_ground()`——**B 批改造落点确认**；
> 2. **phase 链**：`enemy_damage.gd:36` `_enemy._boss_ctrl._check_phase_transition()`（存活命中路径）/ `enemy_boss.gd:85` `_check_phase_transition()`——**C 批钩子接线点确认**（拆解写 :35-36，实测存活命中调用在 :36，微差 1 行）；
> 3. **演出消费端**：`game_manager.gd:392` `_show_elite_banner()`（Label + tween 淡出上浮 1.5s 自毁范式）/ `main.gd:240` `_trigger_camera_shake(level)`（light/medium/heavy 表化）——**LD-C1 banner/camera 复用范式确认**；
> 4. **status_component.gd**（实际路径 `scripts/systems/status_component.gd`）：`:140` `_apply()`（slow 分支 :144）/ `:160` `_revert()`（slow 分支 :164）——**E 批 attr 分支落点确认**（拆解写 _revert :157，实测 :160，微差 3 行）；
> 5. **DataLoader 接口范式**：`data_loader.gd:482` `get_wave()` / `:605` `get_enemy_sprite_config()`（懒加载 + 空表标记）/ `:644` `get_audio_config()`——**LD-A3 三接口仿写范式确认**（拆解写 :600-604，实测函数体 :605 起，微差 1 行）；
> 6. **data_schema.py**：`:192` SHEETS dict / `:277` waves 注册（root "waves"）/ `:345` elements 注册（root "elemental_status"）/ `:246` audio_config / `:255` fx_config（近三批注册先例）——**LD-A2 注册范式确认**；**elements 无 type 枚举白名单硬校验**（拆解「若校验白名单需加 attr」实测 = 无校验 → attr 类型可直接入表，探针断言兜底）；
> 7. **excel_export.py**：`:155-169` 子表 FK 校验段（child_list/child_dict parent 键存在性，如 skill_relics→skills）——**LD-A2 FK 校验仿写段确认**；`:544` `check_only = "--check-only" in sys.argv` 确认存在但**参数未消费**（已知缺陷复认，拆解建议顺手修或登记 TECH_DEBT）；
> 8. **boss_id 合法集合**：`data/boss_patterns.json` patterns boss_id = **invoker / predator 两枚**（boss_phase_events FK 校验的合法目标来源确认）；`boss_skills.json` 顶层 = skills；`enemies.json` 顶层 = enemies/scaling（**无独立 boss 数组**——boss_id 权威来源 = boss_patterns.json 或 enemies 表 category=boss 行，FK 校验实现时以 boss_patterns 为准或双源取并，建议执行者实测登记）；
> 9. **waves.json 现状**：wave 行 keys = wave/duration/total_enemies/composition（**无 spawn_set/spawn_order 列**，待 LD-A1 新增，与拆解一致）；elements.json elemental_status 现有 type 枚举 = armor/dot/invulnerable/slow/stun（**attr 为新增第 6 类**，消费端 status_component slow 分支完全同构）。
>
> **结论**：① **LEVEL_DESIGN = 本轮方案主产出**（拆解完成即解锁，方案师按纪律写正式方案，承接方 = #3 执行者 D-015 交接，执行序 A→B→C→E→D 可选→EXIT）；② **F1-E 批四 4-1 已收口**（`2aeb717`/`716a9d8` fx_config sheet 数据侧：10 行 × 6 列 + schema 注册 + export 构建，13+1 JSON 零 diff）→ 上轮「批四零开工」挂账**部分解除**（数据侧 [x]），**剩余 4-2~4-4/EXIT 消费端仍 [ ] 待 #3 续做**；③ **RELIC 方案已定（第 31 轮）git 实测仍未开工**（HEAD 无 day31_relic_* / stats 改名提交）→ 挂账观察维持（跨 1 轮）；④ D30-T3 上传 + D30-EXIT = 纯 Owner/#4 域维持；⚠️ build/ 已含 F-45/46/47/48 + F1-E-4-1（`2aeb717` 产物）但不含 F-49 → 传送门/宝箱验证需最新代码或下次打包。**回归硬门槛口径维持 = 62 件套 · 1534 断言**。

## 当前开发日：Day 30 收尾 → 新目标日 Day 31（LEVEL_DESIGN 关卡设计扩展 · 独立目标日 · 拆解 `9ebbf5f` + 规格 `LEVEL_DESIGN_SPEC.md` 唯一事实源 · 与 RELIC 同窗口）

### 任务1：LD-A 数据地基（两新 sheet + 管线 + 接口 · 前置批 · B/C/E 全依赖 · ⭐ 本轮实测复核新增确认）

- **实测复核结论（本轮新增 4 点，供执行者直接使用）**：
  1. **waves.json 现无 spawn_set/spawn_order 列**（wave keys = wave/duration/total_enemies/composition）→ LD-A1 为纯新增列，无既有键冲突；20 波全部留空 = 缺省边缘组零行为变化（缺省回退语义清晰）。
  2. **elements 表无 type 枚举白名单校验**（data_schema elements 注册 :345 仅 root/kind/key，无 VALID_TYPE 检查）→ `attr` 新类型可直接入表零阻塞；探针断言 type=attr 行兜底（拆解「若校验白名单需加 attr」实测 = 无需加）。
  3. **boss_id 合法集合 = boss_patterns.json patterns 的 invoker/predator 两枚**（enemies.json 无独立 boss 数组）→ FK 校验 boss_phase_events.boss_id 的实现建议：以 boss_patterns.json boss_id 并集为准（或 enemies 表 category=boss 行），执行者实测登记后定（D5 实测登记制延伸）。
  4. **FK 校验仿写段** = excel_export.py:155-169（child_list/child_dict parent 键存在性循环）——spawn_set 引用 point_id 属跨 sheet 引用，需新写校验段（非既有 child 机制），改 Excel 时 FK 报错语义与既有 rep.err 一致。
- **改动**：Excel 两新 sheet（spawn_points ≥9 行 8 列 / boss_phase_events ≥6 行 6 列）+ waves 表 +2 列 + data_schema 注册 + excel_export 构建（spawn_points 平铺 dict / boss_phase_events 按 boss_id 分组排序）+ FK 校验新段 + **顺手修 `--check-only` 已知缺陷（check_only 参数未消费 = 校验路径仍全量导出）或登记 TECH_DEBT** + DataLoader 三接口 + 新探针 `day31_level_design_data_check.gd` ≥12 断言。
- **风险**：**中**。数据面最广（两新 sheet + waves 列 + schema + export + FK + 三接口 + 探针七点）；**硬门槛 = 其余 16 JSON 零 diff**（新文件生成不得碰既有文件）+ FK 校验三态（合法/坏 point_id/坏 boss_id）；--check-only 缺陷修复涉既有校验路径行为（建议只修「check_only 时跳过导出写盘」语义，防误伤，或先登记 TECH_DEBT 不阻塞本批）。
- **验证**：day31_level_design_data_check ≥12 + 回归 **62 件套 · 1534 断言** + baseline **BASELINE CLEAN** + Excel --check-only 通过（FK 新逻辑生效）。

### 任务2：LD-B 固定出生点生成（enemy_spawner 按点位生成 · 依赖 LD-A · ⭐ 锚点复核确认）

- **实测复核结论**：`enemy_spawner.gd:172 _get_random_spawn_position()`（min_dist 110 / 40 次尝试 / :196 `_clamp_to_ground` 兜底）/ `:163` 生成调用点——**改造落点与拆解一致**；`wave_manager` spawn_wave 透传链待执行者按 LD-B2 扩展（参数 Dictionary 缺省空 = 兼容旧调用零回归）。
- **改动**：enemy_spawner 新增 `_get_spawn_position(entry)`（edge/anchor/ring 三型解析 + sequence/random 轮换 + min_dist 3 次兜底 + _clamp_to_ground）+ wave_manager 透传 spawn_set/spawn_order + 探针扩展 §出生点段 ≥8 断言。
- **风险**：**中**（生成逻辑核心改动，最大隐患 = F-48 修复回归）。**硬门槛 = day31_flee_bound 18/18 零改动**（inset 40 点位 + Aggro Leash 320 双保险 = 生成点必在视野内）+ **缺省回退必须保留现 `_get_random_spawn_position` 路径**（spawn_set 空/点位表空/point_id 不存在 → 原随机兜底零回归）。**替代方案**：两阶段灰度——先只加表驱动主路径 + 全波留空走缺省（零行为变化验证回归），再 1-2 波填值端到端验证。
- **验证**：day31_level_design_data_check §出生点段 ≥8 + day31_flee_bound 18/18 零改动 + 回归 62 件套 + PLAYTEST 主观项登记（怪从视野边缘涌入的可预判感，交 #5）。

### 任务3：LD-C Boss 阶段演出（boss_phase_events 触发 + 演出执行器 · 依赖 LD-A · ⭐ 锚点复核确认）

- **实测复核结论**：`enemy_damage.gd:36`（存活命中 _check_phase_transition 调用）/ `enemy_boss.gd:85`（_check_phase_transition 函数体）——**C2 钩子接线点确认**；`game_manager.gd:392 _show_elite_banner()`（Label + tween 淡出上浮 1.5s 自毁）/ `main.gd:240 _trigger_camera_shake(level)`——**C1 banner/camera 复用范式确认**。
- **改动**：新建 `scripts/boss/boss_phase_player.gd`（注册表驱动 play_events：banner/vfx/sfx/dialogue/camera/buff 六类型 + once 语义 + 未知名 push_warning 跳过）+ enemy_damage/enemy_boss 相位链接线（阈值语义 > 上一阈值 ≤ 本阈值 / 击杀不触发 / once 防重 / 100 开局登场）。
- **风险**：**中**（演出执行器新脚本 + 相位链接线）。**硬门槛 = day18_19_boss_check 48/48 + day30_boss_skill 49/49 零改动**（相位/技能链不动，演出为纯叠加层）+ 击杀瞬间零触发（防死亡帧残留横幅）。**替代方案**：执行器先独立白盒验证六类型，再接相位链（两阶段）。
- **验证**：day31_level_design_data_check §演出段 ≥8 + day18_19/day30_boss_skill 零改动 + 回归 62 件套 + PLAYTEST 主观项登记（Boss 血线演出观感，交 #5）。

### 任务4：LD-E attr 正向属性状态（status_component 扩展 + elements 示例行 + buff 联动 · 依赖 LD-A · ⭐ 锚点复核确认）

- **实测复核结论**：`status_component.gd:140 _apply()`（slow 分支 :144-155 范式：记录 orig → 乘算 → 到期还原）/ `:160 _revert()`（slow 分支 :164）——**attr 分支完全同构落点确认**（拆解写 _revert :157，实测 :160 微差 3 行，执行者按 :160）；elements.json elemental_status 现有 5 类型（armor/dot/invulnerable/slow/stun），attr = 第 6 类。
- **改动**：status_component `_apply`/`_revert` match 新增 `"attr"` 分支（target_attr 白名单按 D5 实测登记：damage_multiplier/move_speed/armor 消费点已验证；crit_chance/crit_damage/attack_speed 若缺失挂 TECH_DEBT）+ elements sheet 新增 ≥2 行 type=attr 示例（frenzy 狂暴 / swift 迅捷）+ buff 事件联动（LD-C1 执行器 → status_component 消费）。
- **风险**：**中**（状态组件核心，**叠加/免疫/max_stacks/同源刷新/异源独立必须沿用现有组件规则零新增**——拆解已定，执行者不得另起炉灶）。**硬门槛 = 既有 slow/dot/stun/armor 行为零漂移**（attr 为纯新增分支，探针断言 5 旧类型行为不变）+ target_attr 不存在 warn + 跳过（防脏数据崩游戏）。
- **验证**：新探针 `day31_level_design_attr_check.gd` ≥10 断言 + 回归 62 件套 + PLAYTEST 主观项登记（Boss 狂暴时玩家应对体感，交 #5）。

### 任务5：LD-D 特殊波参数化（可选批 · 成本 >0.5 天则降级记 TECH_DEBT）

- **改动**：wave_generation 表扩展（special/count_mult/hp_mult/damage_mult）+ enemy_spawner:82/:148 读表替换 if/else（缺省 1/1/1 零行为变化）+ curse/high_pressure/chest_enemy 语义核清（评估成本）。
- **风险**：**低-中**（F-47 已修 swarm 翻倍口径一致，swarm 现行为 = count×2 + HP×0.5 探针断言零漂移；其余语义散落核清成本未知）。**总指挥 D-014 已拍板：特殊波参数化本期不纳入 → 优先登记 TECH_DEBT_PLAN**，若执行者评估 <0.5 天可顺带收 swarm 主项。
- **验证**：day31_level_design_data_check +§特殊波段 ≥6（若做）/ 降级则 TECH_DEBT_PLAN 登记不做 EXIT。

### 任务6：LD-EXIT 总收口

- **验证**：全批探针全绿（day31_level_design_data_check + attr_check）+ 全量回归 **62 件套 ≥1534 断言** + baseline **BASELINE CLEAN** + Excel --check-only 通过（含 FK 新逻辑）+ DATA_DICT_GUIDE.md 补两新表说明 + PLAYTEST 主观项登记（点位可预判感 / Boss 血线演出 / attr 狂暴体感，交 #5）+ TECH_DEBT_ISSUES 新债登记（--check-only 缺陷未修则登记 / crit·攻速属性缺失）。

### 任务7：F1-E 第四批 FX 表现抽表（F1-E-4-1~4 + EXIT）——4-1 已收口 · 消费端待 #3 续做

- **现状更新**：**F1-E-4-1 [x]**（总指挥第 6 轮 `2aeb717`/`716a9d8`：fx_config sheet 10 行 × id/frames/fps/path/size_w/size_h + data_schema 注册 + excel_export 构建 fx_map，13+1 JSON 零 diff）→ **上轮「批四零开工」挂账部分解除**；**剩余 4-2（DataLoader.get_fx_config）~4-4（vfx_player.set_effect 改读）+ EXIT 仍 [ ]，承接方 = #3 执行者**（D-015 交接）。
- **硬门槛**（不变）：day23_vfx_check §1 零改动（FX_CONFIG const 兜底）+ 抽表零数值变化 + 回归 **62 件套 · 1534 断言**；EXIT 口径 = day31_presentation ≥286（273+13）+ baseline CLEAN。
- **验证/承接**：沿用前三批范式（get_fx_config 懒加载 + Vector2i 组装 → vfx_player.set_effect 消费改读 const 兜底 → day31_presentation +§6 fx 段），每任务一收口 commit 带 F1-E-4 编号。

### 任务8：RELIC 遗物扩展（全批已拆解 + 方案已定第 31 轮）——挂账观察维持

- **现状**：方案已定（SOLUTION_PLAN 第 31 轮，锚点实测复核：stats.json .stats.offensive[2]/.stats.economy[3] + desc_builder.gd:32-33 + items relic 2 件 + data_loader:437 + save_system 缺省容错）；**本轮 git 实测确认仍未开工**（HEAD=`9ebbf5f` 无 day31_relic_* / stats 改名提交）→ **挂账观察维持（跨 1 轮）**，承接方 = #3 执行者（D-015 交接）。
- **执行序**（第 31 轮定案不变）：RELIC-A（低成本独立先行）→ RELIC-0（数据地基）→ RELIC-F/RELIC-E（P0 独立）→ RELIC-B/C/D（依赖 0）→ RELIC-EXIT。
- **验证**：按第 31 轮方案逐批执行（day31_relic_name/data/boss_rhythm/harvest/affinity 五探针 + 回归 62 件套 1534 断言 + baseline CLEAN）。

### 任务9：D30-T3 上传 + D30-EXIT 发布收口——纯 Owner/#4 域，无需方案

- **改动**：无（本岗红线：外部动作 + 测试岗产出）。D30-T3 上传 [ ] = 等 Owner 明确确认（目标资产库）；D30-EXIT [~]/[ ] = TEST_REPORT 发布摘要待 #4 落盘 + 最终标记。**⚠️ build/ 观察更新：D-016 授权后 build/ 已自动替换为 HEAD=`2aeb717` 产物（含 F-45/46/47/48 + F1-E-4-1）但不含其后 F-49（`4f1e791`）→ 传送门/宝箱需等下次打包验证**（交 Owner/总指挥）。
- **风险**：低（无机器侧开发任务）。**验证**：Owner 确认后由 #3/#4 收口，回归 62 件套 + baseline CLEAN 为发布门禁口径。

### 风险总表（本轮）

| 任务 | 风险 | 说明 / 替代方案 |
|---|---|---|
| LD-A 数据地基 | 中 | 七点数据面最广；16 JSON 零 diff 硬门槛；FK 校验三态；--check-only 缺陷修复保守（只改语义或登记 TECH_DEBT） |
| LD-B 固定出生点 | 中 | 生成逻辑核心改动；day31_flee_bound 18/18 零改动硬门槛；缺省回退保留现随机路径；替代 = 两阶段灰度（全波留空先验零回归） |
| LD-C Boss 演出 | 中 | 新执行器 + 相位链接线；day18_19 48/48 + day30_boss_skill 49/49 零改动；击杀不触发；替代 = 执行器独立白盒先验再接线 |
| LD-E attr 状态 | 中 | 状态组件核心；5 旧类型行为零漂移 + attr 纯新增分支；叠加/免疫规则沿用零新增；target_attr 缺失 warn 跳过 |
| LD-D 特殊波 | 低-中 | D-014 拍板挂 TECH_DEBT_PLAN 优先；<0.5 天可顺带收 swarm 主项（swarm 现值 2/0.5 探针断言零漂移） |
| F1-E-4 消费端 | 低 | day23_vfx_check 零改动 + 抽表零数值；4-1 数据侧已收口，剩 4-2~4-4/EXIT 待 #3 |
| RELIC 全批 | 低-中 | 方案已定第 31 轮；**唯一风险 = 承接方持续未开工（跨 1 轮挂账观察）** |
| D30-T3/EXIT | 低 | Owner/#4 域；build/ 不含 F-49 交 Owner/总指挥核实 |

### 维持已定方案边界（不重复写）

- **F1-E 批五~七**（SHEET_CONFIG → 初始武器 → 炮台默认）：沿前四批范式 + 各批先例推进，承接方开工时按需拆解（批四消费端收口后再拆批五）。
- **F-49（传送门+宝箱）**：用户 08-18 23:3x 直派已落地（`4f1e791` 闭环：portal 24/24 + 回归 62/62 全绿，RELIC-E 三选一地基）——非本岗方案对象；真人回归（传送门显眼度 / 先捡宝箱再进 / Boss 关同流程）交 #5。
- **F-45/F-46/F-47/F-48/F-49 主观回归面 / E-0 终审完整局 / AF-P0 / PS-EXIT**：交 #5 真人（主观项不阻塞机器侧）。
- **F-16~F-44 真人回归 / MainMenu 待真人确认 / Day 28 性能段 / 章节 Boss 映射（已拍板三 Boss [6,10,14]）**：开放项清单维持（见 PLAYTEST 追踪区）。

## 🔴 红线遵守（本轮）

不写代码、不改 `.gd/.tscn/.tres/.json` 游戏文件、不 git commit、不跑探针。仅覆盖写 `docs/SOLUTION_PLAN.md`（顶部新第 32 轮段，历史段完整保留）+ 在 `docs/TASKS.md` 标注（LEVEL_DESIGN 区块「方案已定」+ F1-E-4 状态刷新 + 第 62 轮状态块后补方案师第 32 轮确认块）。工作区在途 docs/TEST_REPORT.md（#4）+ art_ai 工具（美术域）不碰（本轮仅 SOLUTION_PLAN/TASKS 两 docs 挂账，交下一岗入库）。

---

# 方案计划（2026-08-18 23:3x · 总指挥第 6 轮 · LEVEL_DESIGN_SPEC §8 五决策点拍板 + F1-E-4-1 收口交接）

## 📌 总指挥拍板决策段（2026-08-18 23:3x · 第 6 轮）

> **总指挥拍板 D-014（LEVEL_DESIGN_SPEC §8 五细节决策点，用户 08-18 22:57 已拍板三项核心决策，细节点未表态 → 08-17 授权内自主拍板）：**
> ① **默认 8 边缘点 inset = 40**（采纳规格推荐：点位在竞技场内且玩家视野内可预判，与 F-48 修复口径 leash 320 / 生成收紧 ±200×±120 一致）；
> ② **Boss 登场点 = anchor(0.5, 0.3)**（采纳：中上登场、视野内可预判，配合现 Boss 波 composition 单 boss 语义）；
> ③ **dialogue 台词框本期用 banner 样式占位**（不新增 UI 资产，复用 GameManager._show_elite_banner 范式，param.text 显示在横幅上；后续独立台词框挂 TECH_DEBT）；
> ④ **特殊波参数化本期不纳入，挂 TECH_DEBT_PLAN**（规格 §5 自评成本 >0.5 天；F-47 已修 swarm 翻倍口径一致，用户三项核心诉求 ①②③ 已全覆盖）；
> ⑤ **attr target_attr 白名单拆解时实测登记制**（damage_multiplier/move_speed/armor 消费点已验证存在；crit_chance/crit_damage/attack_speed 若实测缺失则挂 TECH_DEBT 不阻塞）。
> 理由一行：均为规格「推荐值/可选范围」内选择，不触碰用户已拍板的三项核心决策，选保守可逆项，解 #2 下一轮（00:05）拆解阻塞。

> **总指挥拍板 D-015（用户 08-18 23:1x 新指令交接）：用户拍板解除「#3 勿自行开工」历史约定（F1-E 剩余批次 + RELIC 全批次承接方 = #3 执行者，总指挥回归调度/兜底角色，仅挂账超轮时介入）→ 总指挥遵令交接：本轮 F1-E-4-1（Excel fx_config sheet + schema 注册 + export 构建）已在决策落地前动工完成，按检查点提交收口（数据已入库、13+1 JSON 零 diff），F1-E-4-2~EXIT 交接 #3 执行者续做；总指挥不再直接执行拆解+方案齐备的任务。**

# 方案计划（2026-08-18 22:4x · 方案师第 31 轮 · RELIC 遗物扩展正式方案（#2 第 61 轮拆解完成兑现）+ F1-E 批四挂账观察）

## 📌 本轮判定（方案师第 31 轮）

> **P0 检查（PLAYTEST 追踪区增量 #85 · 08-18 22:4x 反馈专员 · F-46 怪物追踪重写+HUD 分数制落地登记）**：无新增待处理反馈（F-01~F-46/AF-P0 全 🟢 已修复·待真人回归；🟡 仅 H-05 家族主观审阅域）；TEST_REPORT #61（22:00 · HEAD=`980aa7d`）= **62/62 全绿 · 1534 断言 · BASELINE CLEAN · 0 阻断 / 0 action item**（F-45 手感三连验证轮）→ **🔴P0 无新增**。
>
> **🟠 关键调度输入（本轮兑现上轮承诺）**：`docs/RELIC_EXPANSION_SPEC.md`（08-18 晚用户拍板 · 规格 215 行）已由 **#2 第 61 轮（`f19447c`）完成函数级拆解**——**O-1~O-4 全拍板**（O-1：元素伤害→**魔法伤害** / 工程学→**机械学**，id 零改动；O-2：不做控血 → **玻璃大炮构筑转换**；O-3：affinity 默认不可改 + 开放事件洗点；O-4：流派**不限于移速**）。拆解批次 = RELIC-A（独立先行）→ RELIC-0（数据地基前置）→ RELIC-F / RELIC-E（P0 独立）→ RELIC-B / RELIC-C / RELIC-D（依赖 0）→ RELIC-EXIT；**独立目标日 Day 31+ 不插入 D30 收尾窗口** → **本轮方案师按规格 + 拆解写 RELIC 正式方案（实测复核锚点，见任务 1-8）**。
>
> **git 实测**：HEAD=`144b2bb`（反馈专员 #85 · 08-18 22:4x；#2 第 61 轮后 +6 = `f19447c` RELIC 函数级拆解 / `310a412` #1 第 65 轮 / `bdd3ed5` **F-45 手感三连修复**（顿帧四档调小 + 普攻命中零震屏 + 命中特效 scale0.6/alpha0.55/0.25s 渐隐，回归 62/62 1534 全绿）/ `ebdac5e` **F-45 震屏二次调档**（用户直改 Excel：light/medium/heavy 三档整体调小，feel 26/26 + 回归全绿）/ `700f728` F-45 导出补同步 / `5556cb3` **F-46 怪物追踪重写 + HUD 分数制（用户 08-18 直派 · 已落地闭环）**（Aggro Leash 420px 战斗锁链根治怪漂出屏幕判通死锁 + ranged Orbit 收敛环绕 + HUD「已击杀/本关总生成」分数制 + 探针 flee §5 22/22 + day18 §4 17/17 + 回归 62/62 全绿）/ `144b2bb` #85 登记）；**工作区在途 = 仅 `docs/TEST_REPORT.md` M（#4 在途）零游戏代码，红线内不碰**。
>
> **结论**：① **RELIC 遗物扩展 = 本轮方案主产出**（拆解完成即解锁，方案师按纪律写正式方案，承接方 = 总指挥/主窗口按 RELIC 编号批推进，勿插入 D30 收尾窗口）；② **F1-E 批四 FX 仍未开工**（git 实测最近 12 提交无 fx_config/get_fx_config/vfx_player 改读）→ 方案锚定维持、挂账观察继续；③ D30-T3 上传 + D30-EXIT = 纯 Owner/#4 域维持（build/ 已补冻，旧观察关闭）；④ **F-46 已由用户直派落地（`5556cb3`）非本岗方案对象**，仅登记确认。**回归硬门槛口径维持 = 62 件套 · 1534 断言**（TEST_REPORT #61 全绿实证）。

## 当前开发日：Day 30 收尾 → 新目标日 Day 31（RELIC 遗物扩展 · 独立目标日 · 拆解 `f19447c` + 规格 `RELIC_EXPANSION_SPEC.md` 唯一事实源）

### 任务1：RELIC-A 属性命名去土豆兄弟化（P1 · 独立低成本先行 · ⭐ 本轮实测复核新增确认）

- **实测复核结论（本轮新增 3 点，供执行者直接使用）**：
  1. **stats.json 锚点定位** = `.stats.offensive[2]`（`elemental_damage`「元素伤害」base 0）/ `.stats.economy[3]`（`engineering`「工程学」base 0）——确认由 Excel stats sheet 导出（JSON generated 禁手改，走 Excel 两行 name）。
  2. **⚠️ desc_builder.gd:32-33 硬编码映射实测确认存在**：`"elemental_damage": "元素伤害"` / `"engineering": "工程"`——**注意 desc_builder 现值「工程」2 字与 stats.json「工程学」3 字不一致** → 改名必须两处同步且统一为「机械学」（拆解 RELIC-A2「核对 STAT_CN 是否另有硬编码，有则同步」的实测结论：**确有硬编码，需同步**；顺带消除既有 2/3 字不一致）。
  3. **引用面 4 脚本实测**：data_loader.gd:371（注释「melee/ranged/elemental/engineering」= 白名单不动）/ attribute_controller.gd:36,42（`orbit_blade_count`/`elemental_damage`/`summon_count` 属性 id 列表 = **不可改**）/ skill_controller.gd:227-236（燃烧 dps 机制 id = **不可改**）——与拆解「属性 id 零改动」一致；数据侧文案残留（characters.json / items.json / weapons.json:485 等）按拆解 A2 grep 替换展示名/描述文案。
- **改动**：Excel stats sheet 两行 name →「魔法伤害」「机械学」+ desc_builder STAT_CN 两键同步（统一「机械学」）+ 导出 stats.json（仅两 name 变，其余 JSON 零 diff）+ 数据文案替换 + `tools/day31_relic_name_check.gd` 新建（≥8 断言）。
- **风险**：**低**。属性 id 零改动 = 存档/探针/数据层零连锁；唯二坑 = ① desc_builder「工程」≠ stats「工程学」需先统一 ② 数据侧文案 grep 必须覆盖 characters/items/weapons 三 JSON（漏一处 = 展示残留「元素伤害」）。
- **验证**：day31_relic_name_check ≥8 + 回归 **62 件套 · 1534 断言** + baseline **BASELINE CLEAN**。可**独立先行**（不依赖 RELIC-0，可直接开工）。

### 任务2：RELIC-0 数据层地基（前置批 · B/C/D 全依赖 · ⭐ 本轮实测复核新增确认）

- **实测复核结论（本轮新增）**：① items.json **54 条 · slot="relic" 仅 2 条**（broken_crown 破碎王冠 / mech_engine 机械引擎，D20 直装先例）——B/C/D 池扩展落点确认；② data_loader.gd:437-438 `get_all_skill_relics()` 范式在位（:441 `get_skill_relics_by_source` 同源，RELIC-0-2 仿此）；③ save_system.gd `_default_meta()` + load 逐键 clean（wins/research_points/research/chars/codex）缺省容错范式在位 → RELIC-0-3 两新键（`relic_affinity`/`relic_codex`）照此办理；④ **skill_relics.json 顶层 = dict（键 `skill_relics`）**——拆解「技能遗物不在本次字段扩展范围」确认正确。
- **改动**：Excel items sheet relic 条目 +5 列（`rarity` common/uncommon/rare / `tag` 流派打标 / `tier` 1/2/3 / `set_id`+`set_tier`+`set_effects`（Excel 分隔串 → 导出 JSON 数组，**最小实现**）/ `unlock_condition` 字符串表达式）+ 套装 2 套 4 件占位（星骸孤注 / 死线舞者）+ 流派示例 ≥6 件（T1 common ×3 / T2 uncommon ×2 / T3 rare ×1，移速流示例；其余流派同构，方案师按 O-4 自由规划留给执行批 D 扩展）+ data_schema 注册 + excel_export 导出（items.json relic +5 键，其余 JSON 零 diff）+ DataLoader `get_relic_defs()`/`get_relic_set_ids()` + save_system meta 两键（缺省零值容错）。
- **风险**：**中**。数据面最广（Excel→schema→export→JSON→DataLoader→存档六点）；**硬门槛 = day30_save_compat 14/14 + day27_meta 35/35 零改动**（旧档缺新键零崩）；set_effects 存储格式以「分隔串 + 导出解析数组」定案，禁自由发明格式。
- **验证**：新建 `tools/day31_relic_data_check.gd`（≥15 断言：字段键齐全 / 套装分组 / 池过滤基础 / 存档兼容 / 回归抽样）+ 回归 62 件套 + baseline CLEAN。

### 任务3：RELIC-F Boss 行为节奏（P0 · 独立可先行 · 承接 BS-A~D 已实装底座）

- **改动**：enemy_boss.gd 行为循环（施法站定态 + 时间分配倒置：追踪 30-40% / 技能+走位 60-70% + 大范围技能权重提升）+ enemy_movement.gd（追踪减速/站定，F4-T1 拆分产物）+ 参数数据化（enemies.json phases 或 boss_pattern 表扩展 `cast_slowdown`/`chase_ratio`/`skill_window` 键，**禁硬编码，数据管线铁律**）。
- **风险**：**中**（直接改手感，最可能破坏既有 BS 探针）。**硬门槛 = 公平底线公式（BOSS_SKILL_SPEC §2.2 t_w>2r/v+0.4s）零破坏 + day30_boss_skill 49/49 + day18_19_boss_check 48/48 零改动**。**替代方案**：先数据灰度（只调 boss_pattern 权重表 + chase_ratio/skill_window 键，不动代码循环）→ 探针验证节奏变化 → 不足再动站定逻辑（两阶段降风险）。
- **验证**：新建 `tools/day31_relic_boss_rhythm_check.gd`（≥12 断言：施放期移速下降或站定 / 时间分配比例白盒统计 / 大范围技能次数 > 贴身追击 / 公平底线公式零破坏）+ 回归 + PLAYTEST 主观项登记（走走停停 / 躲技能反打手感，交 #5）。

### 任务4：RELIC-E Boss 宝箱收获 + 通关成就感（P0 · 独立可先行 · G 项并入）

- **改动**：GameManager._on_node_completed 分支（boss 节点 → 收获房间）+ 宝箱开启演出（占位色块/复用 VfxPlayer 特效 + 开启音效 + 光效，美术占位口径）+ 遗物三选一（**复用 enemy_damage.gd :89-104 精英三选一先例**）+ 可停留查看属性 → 手动进入下一层/结算（**可跳过不打断**）+ 结算页增强（GameOverPanel F-23 先例：击杀数/波次/最终 Build 流派标签/收集遗物列表 + 解锁提示联动 relic_codex）+ 新音效（**audio_config sheet 扩键 → audio_map，SFX_MAP 键契约零删改（AUDIO_FEEL 红线 2 先例）+ day24_audio_check 14/14 零改动硬门槛**；商店购买成功 = 音效 + 高亮 + 金币 -N 跳字，现状已有则只补音效）。
- **风险**：**中**（流程分支改动，最大隐患 = 影响判通链路——**F-39 生成状态复位教训**：宝箱环节必须可跳过、不得阻塞普通关/Boss 关判通）。**方案定案：宝箱环节做成纯叠加层（overlay），不动波次状态机** → 判通零影响；另需明确 **MAX_RELICS=2 满槽时三选一的处理**（替换确认/跳过提示，防静默失败）。
- **验证**：新建 `tools/day31_relic_harvest_check.gd`（≥12 断言：章 Boss 战后必见宝箱且可三选一 / 可跳过不打断 / 结算页含统计+解锁提示 / 新音效 audio_map 键在位 + SFX_MAP 零删改）+ 回归 62 件套 + PLAYTEST 主观项登记（宝箱收获成就感 / 结算页观感，交 #5）。

### 任务5：RELIC-B 套装遗物（P1 · 依赖 RELIC-0 · O-2 玻璃大炮拍板）

- **改动**：inventory.gd 同 set_id 计数 → 激活 set_tier（1/2 件档位）+ set_effects 应用/移除（装配卸下切换防重复）+ 消费点（attribute_controller/player apply_stat_modifier + take_damage 减伤兜底）+ 装备反馈（HUD 状态图标/颜色 + 音效并入 E3 + 占位纯色视觉）。
- **风险**：**中**。**⚠️ max_health 削减 = 比例乘法非减法**（防负值/零值崩溃，探针断言边界，拆解已定）；「星骸孤注」单件 -90% 血 + 减伤 40% / 2 件 +100% 伤害 +50% 攻速 + 被摸 2s 减伤再 +30%；「死线舞者」单件 -70% 血 +30% 移速 / 2 件移动叠层停下清零——数值占位可调（规格 §3.1），禁做「特别爆炸」数值。
- **验证**：day31_relic_data_check +§套装段 ≥10 断言 + 回归 62 件套 + PLAYTEST 主观登记（玻璃大炮手感）。

### 任务6：RELIC-C 遗物图鉴 + 条件解锁（P1 · 依赖 RELIC-0 + R3 图鉴范式）

- **改动**：R3 codex 新增「遗物」分类（relics 列表，record_codex 4 记录点先例，未见条目「？？？」）+ unlock_condition 消费（first_kill_boss:<chapter_id> / fail_count>=N / codex_count>=N / affinity_tag>=N，**解锁判定函数集中一处**（DataLoader 或独立模块）禁散落）+ 掉落池过滤（enemy_damage 精英/Boss 三选一池 + 商店第三池 D20-T4 55 池先例，只含已解锁）+ 池子目标 ≥60 件（items relic 2 件 + 扩展新增，3 档稀有度）；skill_relics 技能遗物顺带纳入「遗物」分类展示（可选，标注不阻塞）。
- **风险**：**中**。解锁判定集中防散落；掉落池过滤双池同步（漏一处 = 未解锁遗物泄露）。
- **验证**：day31_relic_data_check +§图鉴段 ≥10 断言（未解锁不掉落不泄露名称 / 达成条件解锁 / 白盒注入 fail_count / 持久化）+ 回归 62 件套。

### 任务7：RELIC-D 流派遗物树 + 动态权重引导（P0 · 核心新机制 · 依赖 RELIC-0 · O-3/O-4 拍板）

- **改动**：end_game 结算钩子按本局实际装配遗物流派打标 → `meta_progress.relic_affinity`（D27-T1 先例）+ `DataLoader.get_relic_pool()` 扩展权重计算（基础权重 ×（1 + 0.15 × affinity 计数），上限钳制 + **双向保护：非主流流派基础权重不归零**；**权重模块收敛数据层，禁散落各调用点**）+ T3 开放条件（流派已解锁 ≥6 件 T1/T2 才开放 T3 概率，与 C 项 affinity_tag>=N 联动）+ 洗点事件（10 事件池新增 1-2 节点：重置/转移亲和，events.json 扩展 + Day 16 事件面板消费）。流派规划：移速流为示例，攻速流/肉坦流（耗死 Boss）/元素流/召唤流同构，由执行批按 O-4 自由规划（池子分层收敛天然规避稀释）。
- **风险**：**中高**（核心新机制，横切数据/权重/事件/存档多域）。双向保护与上限钳制为必选项（防玩家锁死单一流派 / 防权重单调爆炸）；affinity 默认不可改（选择有重量），仅事件洗点可动。
- **验证**：新建 `tools/day31_relic_affinity_check.gd`（≥14 断言：白盒注入 affinity 断言权重排序 / 未解锁 T3 时 T3 权重≈0 / 解锁后恢复 / 非主流不掉出池 / 洗点事件在位）+ 回归 + PLAYTEST 主观登记（「选择塑造掉落池」体感）。

### 任务8：RELIC-EXIT 总收口

- **验证**：全批探针全绿（day31_relic_name/data/boss_rhythm/harvest/affinity）+ 全量回归 **62 件套 ≥1534 断言** + baseline **BASELINE CLEAN** + Excel --check-only 通过 + PLAYTEST 主观项登记（套装手感 / 图鉴收集动力 / 流派树体感 / 宝箱成就感 / Boss 节奏，交 #5）+ TECH_DEBT_ISSUES 新债登记（如有）。

### 任务9：F1-E 第四批 FX 表现抽表（F1-E-4-1~4 + EXIT）——方案锚定维持 · 挂账观察

- **现状**：拆解就绪（#2 第 60 轮 `afc5ba6`）+ 方案锚定（方案师第 30 轮实测复核锚点逐一一致）；**本轮 git 实测确认批四仍未开工**（最近 12 提交 = RELIC 拆解 / F-45×3 / F-46 / 各岗 docs，无 fx_config sheet / get_fx_config / vfx_player 改读）→ **挂账观察维持（跨 2 轮）**，承接方 = 🏠 主窗口/总指挥。
- **硬门槛**（不变）：day23_vfx_check §1 零改动（FX_CONFIG const 兜底）+ 抽表零数值变化 + 回归 **62 件套 · 1534 断言**；EXIT 口径 = day31_presentation ≥286（273+13）+ baseline CLEAN。
- **验证/承接**：沿用前三批范式（Excel fx_config 10 行 × 6 列 → data_schema 注册 → excel_export 构建 → get_fx_config → vfx_player.set_effect 改读 const 兜底），每任务一收口 commit 带 F1-E-4 编号。

### 任务10：D30-T3 上传 + D30-EXIT 发布收口——纯 Owner/#4 域，无需方案

- **改动**：无（本岗红线：外部动作 + 测试岗产出）。D30-T3 上传 [ ] = 等 Owner 明确确认（目标资产库 + build/ 替换）；D30-EXIT [~]/[ ] = TEST_REPORT 发布摘要待 #4 落盘（#61 已在途）+ 最终标记。build/ 已由 `5fd5bda` 补冻，旧观察关闭；**⚠️ F-45/F-46 未进 build/**（pck 仍 08-18 19:56 早于 `bdd3ed5`/`5556cb3` → 手感/追踪验证需最新代码或下次打包，交 Owner/总指挥核实）。
- **风险**：低（无机器侧开发任务）。**验证**：Owner 确认后由 #3/#4 收口，回归 62 件套 + baseline CLEAN 为发布门禁口径。

### 风险总表（本轮）

| 任务 | 风险 | 说明 / 替代方案 |
|---|---|---|
| RELIC-A | 低 | id 零改动零连锁；desc_builder「工程」≠stats「工程学」先统一；数据文案三 JSON grep 全覆盖 |
| RELIC-0 | 中 | 六点数据面最广；day30_save_compat 14/14 + day27_meta 35/35 零改动硬门槛；set_effects 分隔串定案 |
| RELIC-F | 中 | 公平底线公式 + BS 探针 49/49/48/48 零改动；替代 = 数据灰度先行（权重/比率键）再动站定逻辑 |
| RELIC-E | 中 | 判通零影响（overlay 叠加层替代，F-39 教训）；MAX_RELICS=2 满槽三选一处理明确；SFX_MAP 零删改红线 |
| RELIC-B | 中 | max_health 比例乘法防负值；装备反馈不可缺（否则玩家感知不到构筑转换） |
| RELIC-C | 中 | 解锁判定集中一处；掉落池过滤双池同步防泄露 |
| RELIC-D | 中高 | 核心新机制横切多域；权重模块收敛 + 双向保护 + 上限钳制必选；替代 = 分两阶段（先权重后事件洗点） |
| F1-E-4 | 低 | day23_vfx_check 零改动 + 抽表零数值；**唯一风险 = 承接方持续未开工（跨 2 轮挂账观察）** |
| D30-T3/EXIT | 低 | Owner/#4 域；F-45/F-46 未进 build 交 Owner/总指挥核实 |

### 维持已定方案边界（不重复写）

- **F1-E 批五~七**（SHEET_CONFIG → 初始武器 → 炮台默认）：沿前四批范式 + 各批先例推进，承接方开工时按需拆解。
- **F-46（怪物追踪重写 + HUD 分数制）**：用户直派已落地（`5556cb3` 闭环：探针 22/22 + 17/17 + 回归 62/62 全绿）——非本岗方案对象；真人回归（Leash 锁链手感 / Orbit 环绕观感 / 分数制 UI）交 #5。
- **PS-EXIT / E-0 终审完整局 / AF-P0 主观回归 / F-45 手感三面 / F-40~F-46 目视**：交 #5 真人（主观项不阻塞机器侧）。
- **F-16~F-43 真人回归 / MainMenu 待真人确认 / Day 28 性能段 / 章节 Boss 映射（已拍板三 Boss [6,10,14]）**：开放项清单维持（见 PLAYTEST 追踪区）。

## 🔴 红线遵守（本轮）

不写代码、不改 `.gd/.tscn/.tres/.json` 游戏文件、不 git commit、不跑探针。仅覆盖写 `docs/SOLUTION_PLAN.md`（顶部新第 31 轮段，历史段完整保留）+ 在 `docs/TASKS.md` 标注（RELIC 区块「方案已定」+ F1-E-4 第 31 轮观察 + Day 30 标题 + 第 31 轮）。工作区在途 docs/TEST_REPORT.md（#4）不碰（本轮仅 SOLUTION_PLAN/TASKS 两 docs 挂账，交下一岗入库）。

---

# 方案计划（2026-08-18 20:4x · 方案师第 30 轮 · F1-E 批四 FX 方案锚定 + 遗物扩展新规格登记）

## 📌 本轮判定（方案师第 30 轮）

> **P0 检查（PLAYTEST 追踪区增量 #81 · 08-18 19:2x 反馈专员）**：无待处理反馈（F-01~F-43/AF-P0 全 🟢 已修复·待真人回归；🟡 仅 H-05 家族主观审阅域）；TEST_REPORT #59（18:22 · HEAD=`af6b24e`）= **61/61 全绿 · 1489 断言 · BASELINE CLEAN · 0 action item**（空轮次，#59 观察两条已由 `498a836` 兑现：runner presentation 246→261 + day5 flaky 根治 → 全量回归 **61/61 · 1504 断言**首跑全绿）→ **🔴P0 无新增**。
>
> **🟠 新用户拍板调度指令（本轮关键输入）**：`docs/RELIC_EXPANSION_SPEC.md`（**2026-08-18 20:3x 落档 · 用户 20:0x-20:3x 连续讨论拍板**，工作区 `??` 未跟踪）+ 配套调研底稿 `docs/ROGUELIKE_SWEETSPOT_ANALYSIS.md`——**遗物系统扩展 7 大块**（A 属性命名去土豆兄弟化 ⭐P1 / B 套装遗物 ⭐P1 / C 遗物图鉴+条件解锁（池子做大）/ D 流派遗物树+动态权重引导 / E Boss 战后宝箱收获环节+通关成就感 / F Boss 行为节奏（走走停停/大范围技能主导）/ G 通关·购买·获得音效特效）+ 范围声明（纳入/不纳入见规格 §1.3：不纳入 = 元素反应内部机制名 / 手感数值平衡 / 新 Boss 新武器 / 美术终稿）+ **A 项含开放决策 O-1 待用户拍板**（元素伤害→异能伤害(推荐)/能量/奥能 · 工程学→构造学(推荐)/召唤强化/机械精通）。状态 = 📋 **规格待拆解 · 文档明示「交 #2 拆解、#3 执行；禁止跳过拆解流程直接动工」** → **方案师本轮仅登记（P0 调度输入），不写方案**（08-12「未拆解禁动工」惯例）。
>
> **git 实测**：HEAD=`afc5ba6`（#2 第 60 轮回执 · 20:0x；第 59 轮后 +3 = 总指挥第 5 轮三连收口：`3d6ee4f` **F1-E 批三 BGM/SFX 抽表闭环**（F1-E-3-1~4+EXIT 全 [x]，探针 273/273 + 回归 61/61 1504 断言 + day24_audio 14/14 零改动）/ `03da9f9` **AF-M1 CC0 音乐替换落地**（bgm_menu←Illusionist / bgm_battle←Fury，文件名不变零代码改动，AUDIO_CREDITS.md 来源标注）/ `5fd5bda` **F-44 小怪逃离修复 + build 补冻**（ranged 横向绕圈 + 边界钳制 + 出界即死，探针 18/18 + runner 62 件套 + **全量回归 62/62 · 1534 断言** + baseline CLEAN + 旧产物归档重导出 RELEASE OK））；**工作区在途 4 项 docs** = `M docs/BOSS_SKILL_SPEC.md`（用户会话，规格关联更新）+ `M docs/TEST_REPORT.md`（#4 第 60 轮在途）+ `?? docs/RELIC_EXPANSION_SPEC.md` + `?? docs/ROGUELIKE_SWEETSPOT_ANALYSIS.md`——**全部非游戏代码，红线内不碰**。
>
> **结论**：Day 30 剩余客观任务 = ① **F1-E 批四 FX（F1-E-4-1~4+EXIT，#2 第 60 轮 `afc5ba6` 已函数级拆解）→ 本轮实测复核锚点与拆解文本逐一一致，方案锚定直接可执行**（承接方 = 🏠 主窗口/总指挥）；② D30-T3 上传 + D30-EXIT = 纯 Owner/#4 域无方案（build/ 已由 `5fd5bda` 补冻，旧「产物早于最新代码」观察关闭）；③ **RELIC_EXPANSION_SPEC = 新拍板规格，待 #2 拆解，非 Day 30 客观任务**（发布收尾窗口零数据改动口径）→ 建议独立目标日。**回归硬门槛口径 = 62 件套 · 1534 断言**（`5fd5bda` runner 62 件套，批四 EXIT 以 62/1534 为准）。

## 当前开发日：Day 30（发布准备 · 收尾）

### 任务1：F1-E 第四批 FX 表现抽表（F1-E-4-1~4 + EXIT）——方案锚定（#2 第 60 轮已拆，勿重复拆）

- **现状**：拆解就绪（#2 第 60 轮 `afc5ba6`，TECH_DEBT_ISSUES T-019 转已拆解）；本轮实测复核锚点与拆解文本**逐一一致**。
- **锚点**（实测复核）：`scripts/effects/vfx_player.gd:17-29` FX_CONFIG **10 键**（5 旧 hit/crit/death/levelup/pickup + 5 新 fireball/turret_deploy/blade_burst/meteor/shield，各含 path/frames/size(Vector2i)/fps）/ `set_effect` :43-62（FX_CONFIG.has 未知键 push_warning → cfg 取用 → load(path) null 静默跳过 → create_from_sheet 构建）/ `spawn` :65-73 静态；`tools/data_schema.py:241-245` audio_config 注册范式（file: presentation.json / root: audio_map / key: id / kind: dict）；`tools/excel_export.py:399-434` presentation 构建段（enemy_sprites size_w/h → {"x","y"} 组装 :408-410 先例 + audio_map :424-434 先例）；`tools/day23_vfx_check.gd` §1 配置层 :138-143（FX_CONFIG 10 键 + 白名单 + 5 新特效资源 exists）+ :164-171（set_effect 未知键静默/命中 current_fx 白盒）。
- **改动**（沿用前三批范式，勿重复拆）：Excel `fx_config` sheet（10 行 × id/frames/fps/path/size_w/size_h 6 列）→ data_schema 注册 → excel_export 构建 presentation.json `fx_config`（size_w/h → {"x","y"} 仿 enemy_sprites 先例）→ DataLoader `get_fx_config()` 懒加载 + Vector2i 组装（仿 get_enemy_sprite_config）→ vfx_player.set_effect 消费改读（**FX_CONFIG const 保留兜底**）。
- **风险**：**低**。双硬门槛：① `day23_vfx_check` §1 零改动（FX_CONFIG const 保留兜底，仿批三 day24_audio 14/14 先例）；② 抽表零数值变化（path/frames/fps/size 与 const 现值逐一一致，仅帧配置来源数据化）。
- **验证**：`day31_presentation_check` ≥286（273+13）+ `day23_vfx_check` 零改动 + 回归 **62 件套 · 1534 断言** + baseline **BASELINE CLEAN** + 端到端双跑（改 Excel 一例 frames → 导出 → get_fx_config 变化）+ 空表兜底白盒（set_effect 回退 const 仍可播）。
- **承接**：🏠 主窗口/总指挥按批推进（每任务一收口 commit 带 F1-E-4 编号）。**本轮观察 = 批四尚未开工（HEAD 无 fx_config 提交）**，维持挂账观察。

### 任务2：D30-T3 上传 + D30-EXIT 发布收口——纯 Owner/#4 域，无需方案

- **改动**：无（本岗红线：外部动作 + 测试岗产出，方案师不写执行方案）。
  - D30-T3 上传 [ ] = 外部动作，等 Owner 明确确认（目标资产库 + build/ 替换与否）；本地部分已由总指挥第 1 轮 ✅ + `5fd5bda` **build/ 补冻 ✅**（旧产物归档 `RoguelikeStudio_20260818_archive.*` + 最新代码重导出 RELEASE OK）→ 旧「build/ 产物早于最新代码」观察**关闭**
  - D30-EXIT [~]/[ ] = TEST_REPORT 发布摘要待 #4 落盘（#60 在途）+ build/ 替换（待 Owner）+ 最终标记
- **风险**：低（无机器侧开发任务）。
- **验证**：Owner 确认后由 #3/#4 收口，回归 62 件套（1534 断言）+ baseline CLEAN 为发布门禁口径。

### 任务3：RELIC_EXPANSION_SPEC 遗物系统扩展（08-18 晚用户拍板）——待 #2 拆解，本轮仅登记不写方案

- **性质**：🟠 新用户拍板调度输入（用户 20:0x-20:3x 连续讨论 → 20:3x 落档）。唯一规格来源 = `docs/RELIC_EXPANSION_SPEC.md`（状态 📋 待拆解 · 禁止跳过拆解流程直接动工）+ 调研底稿 `docs/ROGUELIKE_SWEETSPOT_ANALYSIS.md`（死亡细胞/哈迪斯/土豆兄弟/吸血鬼幸存者/方舟集成战略爽点拆解）。
- **范围**（规格 §1.3）：纳入 = A 属性命名去土豆兄弟化（⭐P1，元素伤害/工程学展示名改世界观化，**O-1 命名候选待用户拍板**，属性 id 零改动）/ B 套装遗物（⭐P1，濒死触发·国王系列式）/ C 遗物图鉴 + 条件解锁（池子做大）/ D 流派遗物树 + 动态权重引导（低稀有基础 → 流派倾向 → 高稀有质变道具）/ E Boss 战后宝箱收获环节 + 通关成就感（仿杀戮尖塔收获环节）/ F Boss 行为节奏（走走停停、大范围技能主导，BOSS_SKILL_SPEC F 项补充）/ G 通关·购买·获得音效特效；不纳入 = 元素反应内部机制名 / 手感数值平衡 / 新 Boss 新武器内容设计 / 美术终稿（占位纯色/文字即可）。
- **方案师预判**（供 #2/#1/总指挥参考，非替拆解）：量级大——横切 items/商店/图鉴(meta_progress.codex)/存档/GameData.xlsx/展示名/音效多域，且含 4 处用户拍板确认的现状基线（遗物 2 槽已实装 / stats.json 两属性名 / AF-P0 反馈质感已实装 / R3 图鉴未含遗物）→ **与 Day 30 发布收尾窗口「发布阶段默认零数据改动」口径冲突 → 建议排独立目标日（Day 31+ 遗物扩展）而非插入收尾窗口**；A 项 O-1 命名拍板可先行收集（拆解时可列两态实现防阻塞）。
- **风险**：中（若插入发布收尾窗口 = 破坏冻结口径；数据/展示名改动面大；需回归 62 件套不破）。**替代方案**：维持 Day 30 收尾 → 拆解后按独立目标日推进。
- **动作**：交 #2 下轮（22:05）优先拆解评估排期；方案师在拆解产出后（下一轮）按规格写正式方案。

### 风险总表（本轮）

| 任务 | 风险 | 说明 / 替代方案 |
|---|---|---|
| F1-E-4 FX 抽表 | 低 | day23_vfx_check §1 零改动 + 抽表零数值变化双硬门槛；FX_CONFIG const 兜底；替代方案 = 回退仅保留 const（现状即等价）；**唯一风险 = 承接方持续未开工（跨轮挂账观察）** |
| D30-T3/EXIT | 低 | 外部动作等 Owner；无替代方案（权限边界）；build/ 已补冻（`5fd5bda`） |
| RELIC_EXPANSION_SPEC | 中 | 新拍板规格量大；插入发布窗口会破坏冻结口径 → 建议独立目标日；A 项 O-1 命名待拍板；替代方案 = 收尾后按新目标日推进 |
| AF-M1（已落地） | 低 | `03da9f9` 闭环（CC0 替换 + AUDIO_CREDITS.md 来源标注 + day24 14/14 + 回归全绿），挂账关闭 |

### 维持已定方案边界（不重复写）

- **F1-E 批五~七**（SHEET_CONFIG → 初始武器 → 炮台默认）：沿第 26/27 轮范式 + 各批先例（SPRITE_MAP/BEHAVIOR_MAP/BGM-SFX/FX）推进，承接方开工时按需拆解。
- **PS-EXIT / E-0 终审完整局 / AF-P0 主观回归 / F-44 真人回归 / F-40~F-43 目视**：交 #5 真人（主观项不阻塞机器侧）。
- **F-16~F-43 真人回归 / MainMenu 待真人确认 / Day 28 性能段 / 章节 Boss 映射（已拍板三 Boss [6,10,14]）**：开放项清单维持（见 PLAYTEST 追踪区）。

## 🔴 红线遵守（本轮）

不写代码、不改 `.gd/.tscn/.tres/.json` 游戏文件、不 git commit、不跑探针。仅覆盖写 `docs/SOLUTION_PLAN.md` + 在 `docs/TASKS.md` 对应任务旁补「方案已定（SOLUTION_PLAN.md 第 30 轮）」标注。工作区 4 项在途 docs（#4 在途 TEST_REPORT + 用户会话 BOSS_SKILL_SPEC M + 新规格×2 未跟踪）一律不碰（本轮仅 SOLUTION_PLAN/TASKS 两 docs 挂账，交下一岗入库）。

---

# 方案计划（2026-08-18 19:3x · 总指挥第 5 轮 · F1-E 第三批 BGM/SFX 抽表闭环）

## 📌 总指挥拍板决策段（2026-08-18 19:3x · 第 5 轮）

> **总指挥拍板：F1-E 第三批 BGM/SFX 抽表不再等承接方——总指挥直接动工，本轮全链闭环（F1-E-3-1~4 + EXIT）。**
> 理由一行：该批自 #2 第 57 轮拆解（`dc6a7c1`）起跨 4 轮零开工、方案师连续 3 轮挂账观察「承接方持续未开工」，拆解/方案/锚点三方已核实一致、const 兜底零回归，属用户未表态事项（08-17 授权内自主拍板先干）。

**本轮已执行（总指挥第 5 轮 · 19:3x）：**
- **F1-E-3-1 ✅**：`docs/GameData.xlsx` 新增 `audio_config` sheet（12 行 × id/category/path 双行表头）+ `data_schema.py` 注册（presentation.json / audio_map / dict / id）+ `excel_export.py` presentation 段追加 audio_map 构建 → 导出 audio_map 12 键（2 bgm + 10 sfx）零漂移、其余 13 JSON 零 diff。
- **F1-E-3-2 ✅**：`data_loader.gd` 新增 `get_audio_config()`（懒加载 + _audio_map 空表重试标记，仿 get_enemy_sprite_config/get_enemy_behavior 范式；缺表 → 空字典零崩）。
- **F1-E-3-3 ✅**：`audio_manager.gd` 新增 `_resolve_audio_path(key, fallback)`（audio_map 命中优先 / 未命中·空表回退 const）；`play_bgm`/`play_sfx` 改走（BGM_MAP/SFX_MAP const 保留兜底，AUDIO_FEEL 红线 2 键契约零破坏）；`play_sfx_delayed` 复用 play_sfx 自动继承；未知键 push_warning 不变。
- **F1-E-3-4 ✅**：`day31_presentation_check.gd` +§3 audio 段 12 断言 → **273/273 PASS**（261+12）；day24_audio_check **14/14 零改动**（硬门槛）；端到端双跑（改 Excel → 导出 → 变化 → 恢复零残留）PASS。
- **F1-E-3-EXIT ✅**：全量回归 **61/61（1504 断言）** + baseline **BASELINE CLEAN**；TASKS F1-E-3 全 [x] + F1-E 行 3/7 批；TECH_DEBT_ISSUES T-016/017/018 转已收口。
- **遗留**：F1-E 剩余批次 = FX → SHEET_CONFIG → 初始武器 → 炮台默认（总指挥/主窗口按批推进）；D30-T3/EXIT 待 Owner（外部动作）。

---

# 方案计划（2026-08-18 19:2x · 方案师第 29 轮 · 无新任务需方案 · 状态与第 28 轮一致，F1-E 批三仍待开工观察·跨 3 轮）

## 📌 本轮判定（方案师第 29 轮）

> **P0 检查（PLAYTEST 追踪区增量 #81 · 08-18 19:2x 反馈专员）**：无待处理反馈（F-01~F-43/AF-P0 全 🟢 已修复·待真人回归；🟡 仅 H-05 家族主观审阅域）；TEST_REPORT #59（18:22 · HEAD=`af6b24e`）= **61/61 全绿 · 1489 断言 · BASELINE CLEAN · 0 阻断 / 0 功能缺陷 / 0 action item**（空轮次：HEAD 仅 4 个 docs/回执提交，无游戏代码改动）→ **#59 观察两条已由其后 `498a836` 兑现 ✅**（① runner 元数据 presentation expect 246→261 同步 ② day5 flaky 根治：melee_sweep 暴击 = player+weapon 双源，星刃 crit 0.08 走全局 RNG 偶发 ×1.8 → 补 crit_damage=1.0 双保险对齐 day31 §4 先例，全量回归 **61/61 · 1504 断言**首跑全绿）→ **🔴P0 无新增 / 🟠 无用户拍板调度指令 → 无新机器可验证 P0 需拆。**
>
> **git 实测**：HEAD=`b26fffa`（反馈专员 #81，08-18 19:2x；#80 `d45ad36` 后 +4：`af6b24e` #2 第 58 轮回执 / `c45f011` #1 进度第 63 轮 / `498a836` 执行者第 59 轮（runner 同步 + day5 flaky 根治 + WPS 锁卫生 + TEST_REPORT #59 入库）/ `b26fffa` 增量 #81）；**工作区 CLEAN 零在途**。
>
> **结论：无新任务需方案化。** 与方案师第 28 轮判定完全一致：当前目标日 Day 30 剩余客观项 = 纯 Owner/#4 域（上传/发布收口）无需方案；**F1-E 第三批 BGM/SFX（F1-E-3-1~4 + EXIT）自拆解（#2 第 57 轮 `dc6a7c1`）起已跨 3 轮未开工**——本轮 git log 仍无 audio_config sheet / audio_map / get_audio_config 提交（HEAD 全为反馈/进度/执行者 docs + 工具侧提交）→ 方案锚定维持，继续挂账观察，承接方 = 🏠 主窗口/总指挥。⚠️ **口径更新 1 处**：`498a836` 已将 runner/day26 锚点同步（presentation expect 246→261 / 回归 1489→1504）→ **F1-E-3-EXIT 回归硬门槛以 61 件套 · 1504 断言为准**（拆解文本中的 1489 为同步前口径，不阻塞执行）。

## 当前开发日：Day 30（发布准备 · 收尾）

### 任务1：F1-E 第三批 BGM/SFX 表现抽表（F1-E-3-1~4 + EXIT）——方案已锚定（第 27 轮），本轮维持，待承接方开工

- **现状**：拆解就绪（#2 第 57 轮 `dc6a7c1`）+ 方案锚定（方案师第 27 轮实测复核锚点一致）+ 三方核实一致（执行者第 58 轮 `bd9ad83`）；**git 实测确认批三零开工（跨 3 轮）**（HEAD=`b26fffa` 无 audio_config/audio_map/get_audio_config 相关提交；`498a836` 为工具侧兑现非本批）。
- **锚点**（不变）：`audio_manager.gd:8-11` BGM_MAP（2 键）/ `:12-23` SFX_MAP（10 键）/ `:112-114` `:138-140` push_warning / `:155` play_sfx_delayed；`data_schema.py:218-231` 注册范式；`excel_export.py:399-423` presentation 构建段；`docs/GameData.xlsx` 新建 `audio_config` sheet（12 行 × id/category/path）；`day31_presentation_check` +§3 audio 段（≥12 断言）。
- **改动**（沿用第 26/27 轮范式，勿重复拆）：Excel → 导出 → `get_audio_config()` 消费 → const 兜底 → 探针 → 回归 61 件套。
- **风险**：**低**。双硬门槛不变：① `day24_audio_check` 14/14 §2 配置层断言（BGM_MAP 2 键 + SFX_MAP 10 类）→ const 保留兜底即零改动；② AUDIO_FEEL 红线 2（SFX_MAP 键契约零新增零删改）→ 仅路径来源数据化。
- **验证**：`day31_presentation_check` ≥273（261+12）+ `day24_audio_check` 14/14 零改动 + 回归 **61 件套 1504 断言**（`498a836` 锚点同步后口径）+ baseline **BASELINE CLEAN** + 端到端双跑（改 Excel 一例路径 → 导出 → get_audio_config 变化）。
- **承接**：🏠 主窗口/总指挥按批推进（每任务一收口 commit 带 F1-E-3 编号）。**本轮观察 = 仍未开工，跨 3 轮挂账观察项**。

### 任务2：D30-T3 上传 + D30-EXIT 发布收口——纯 Owner/#4 域，无需方案

- **改动**：无（本岗红线：外部动作 + 测试岗产出，方案师不写执行方案）。
  - D30-T3 上传 [ ] = 外部动作，等 Owner 明确确认（目标资产库 + build/ 替换 + 冻结 HEAD 补冻与否）；本地部分（冻结/门禁/导出/manifest）总指挥第 1 轮已 ✅ 落地
  - D30-EXIT [~]/[ ] = TEST_REPORT 发布摘要待 #4 落盘 + build/ 替换 + 最终标记
- **风险**：低（无机器侧开发任务；build/ 08-18 00:13/00:14 产物仍早于 `3f9dbe4`/`defe1cf`/`498a836` 的交办观察维持，交 Owner/总指挥核实）。
- **验证**：Owner 确认后由 #3/#4 收口，回归 61 件套（1504 断言）+ baseline CLEAN 为发布门禁口径。

### 任务3：AF-M1（CC0 音乐替换 · P1 已拍板）——待执行，网络依赖登记维持

- **改动**：无（总指挥采集 GitHub 生态或登记阻塞；M1 替换 = assets/audio 文件名不变零代码改动）。
- **风险**：低（不阻塞 P0；网络依赖）。
- **验证**：替换后 day24_audio_check 14/14 零改动 + 回归 61 件套。

### 风险总表（本轮）

| 任务 | 风险 | 说明 / 替代方案 |
|---|---|---|
| F1-E-3 BGM/SFX 抽表 | 低 | day24_audio 14/14 + AUDIO_FEEL 红线 2 双硬门槛；const 兜底防空表崩；替代方案 = 回退仅保留 const（现状即等价）；**唯一风险 = 承接方持续未开工（跨 3 轮挂账观察）** |
| D30-T3/EXIT | 低 | 外部动作等 Owner；无替代方案（权限边界） |
| AF-M1 | 低 | 网络依赖；登记阻塞不阻塞 P0 |

### 维持已定方案边界（不重复写）

- **F1-E 批四~七**（FX → SHEET_CONFIG → 初始武器 → 炮台默认）：沿第 26/27 轮范式 + 各批先例（SPRITE_MAP/BEHAVIOR_MAP/F1-E-3）推进，承接方开工时按需拆解。
- **PS-EXIT / E-0 终审完整局 / AF-P0 主观回归**：交 #5 真人（主观项不阻塞机器侧）。
- **F-16~F-43 真人回归 / MainMenu 待真人确认 / Day 28 性能段 / 章节 Boss 映射（已拍板三 Boss [6,10,14]）**：开放项清单维持（见 PLAYTEST 追踪区）。

## 🔴 红线遵守（本轮）

不写代码、不改 `.gd/.tscn/.tres/.json` 游戏文件、不 git commit、不跑探针。仅覆盖写 `docs/SOLUTION_PLAN.md` + 在 `docs/TASKS.md` 对应任务旁补「方案已定（SOLUTION_PLAN.md 第 29 轮）」标注。工作区 CLEAN 零在途（本轮仅 docs 两文件挂账，交下一岗入库）。

---

# 执行结果（2026-08-18 19:2x · 执行者第 59 轮 · 兑现 #4 观察项 + flaky 根治）

## 📌 本轮判定（执行者第 59 轮）

> **P0 检查（PLAYTEST 追踪区增量 #80 · 13:3x 反馈专员）**：无待处理反馈（F-01~F-43/AF-P0 全 🟢 已修复·待真人回归；🟡 仅 H-05 家族主观审阅域）；TEST_REPORT #58（12:45）/ #59（18:22 #4 已落盘）= **61/61 全绿 · 1489 断言 · BASELINE CLEAN · 0 阻断 / 0 action item** → **🔴P0 无新增 / 🟠 无用户拍板调度指令 → 无新机器可验证 P0 需执行**。
>
> **方案核实**：方案师第 28 轮「无新任务需方案化」维持（F1-E 批三 BGM/SFX 已拆解+锚定，承接方 = 🏠 主窗口/总指挥，#3 勿自行开工；D30-T3/EXIT 纯 Owner/#4 域；AF-M1 网络依赖维持）——**本轮无方案任务**，执行内容 = **TEST_REPORT #57/#58/#59 连续三份挂 #3 域的观察项兑现**（runner 元数据同步 + #59 首跑间歇 flaky 真凶根治）。

**执行结果：[完成]（纯工具侧 3 文件 + 卫生 2 项 · 零游戏代码/零数据改动）**

1. **runner 元数据同步（#4 观察项兑现）**：`tools/_regression_run.py` day31_presentation_check expect **246→261**（探针实测 261 assertions/0 failures，此前滞后 15 断言）。
2. **day26 锚点连锁同步**：`day26_integration_check.gd` 回归期望合计 **1489→1504**（1489 + presentation 15；动态解析 runner PROBES 合计与硬编码锚点比对，改 runner 必须同步，历史第 55/57 轮同类先例）。
3. **day5 flaky 根治（#59 首跑 60/61 真凶）**：`day5_weapon_check.gd` sweep 伤害断言补双保险——原只 `_player.set("crit_chance", 0.0)`，但 `melee_sweep._compute_crit_chance()` = **player + weapon 双源**（星刃 se_star_blade crit_chance=0.08），全局 RNG `randf()<0.08` 偶发暴击 ×1.8 破坏精确断言（实测 15.9 vs 期望 7.9，间歇出现）；对齐 day31_melee_sweep §4 已验证先例补 `_player.set("crit_damage", 1.0)`（偶发判定暴击也 ×1.0 零伤害变化）。
4. **WPS 锁文件卫生**：`docs/~$T_REQUEST_20260816.md`（WPS 临时锁，曾被误入库）移出 git 跟踪 + `.gitignore` 补 `~\$*` 模式防再犯（历史 F1-G-尾 WPS 锁教训）。
5. **挂账入库**：#4 在途 `docs/TEST_REPORT.md` §7.59（18:22 #59 完整报告）一并提交。

**验证**：day5 **16/16 CLEAN**（伤害精确 7.9）+ day26 **34/34 CLEAN** + **全量回归 61/61 PASS（1504 断言，EXIT=0）**——修复后全量首跑即全绿，无残留 flaky。

**下轮观察点**：① 总指挥/主窗口是否开工 F1-E 批三 BGM/SFX（git log 出现 audio_config sheet / audio_map / get_audio_config / day31_presentation_check +§3）② Owner 是否确认 D30-T3 上传 + build/ 替换 + D30-EXIT ③ 总指挥是否推进 AF-M1 CC0 采集 ④ #4 #60 快照刷新（含 1504 断言新口径）后 runner/day26 锚点是否漂移。

---

# 方案计划（2026-08-18 · 第 4 轮 · 总指挥承接 F1-E 第一批 + AUDIO_FEEL 拍板 + HUD 图标补丁）

## 📌 总指挥拍板决策段（2026-08-18 04:5x · 第 4 轮）

> **总指挥拍板：① AUDIO_FEEL O-1~3 不再等 Owner——O-1 音乐选型=M1 CC0 先行+M2 并行、O-2 hitstop 按武器系（近重远轻）、O-3 H1 挂 P2 降级实施；② F1-E 表现抽表由总指挥直接承接（主窗口长期未动），第一批 enemy SPRITE_MAP 抽表本轮闭环；③ HUD se_skill_sword_arc 图标映射立即补（发布冻结顾虑已随基线漂移解除）。**
> 理由一行：三项均属用户未表态事项（08-17 授权内自主拍板），且每项都有「const/缺省兜底零回归」护栏，推进阶段 F 唯一 [ ] 不再挂账。

**本轮已执行（总指挥第 4 轮 · 04:5x）：**
- **HUD 图标补丁 ✅**：`hud.gd` SKILL_ICON_MAP 补 `se_skill_sword_arc:4`；`skills.png` 128×32→160×32（第 5 帧占位）；`icon_atlas.gd` frame_count 4→5。探针 `day31_skill_icon_check.gd` **22/22 PASS**。
- **F1-E 第一批（enemy SPRITE_MAP 抽表）✅ 闭环**：GameData.xlsx 新增 `enemy_sprites` sheet（23 敌）；data_schema.py 注册（presentation.json/enemy_sprites/dict）+ COLUMN_ZH；excel_export.py 构建逻辑（size_w/h→{"x","y"} + tint JSON 列）；导出 `data/presentation.json` 23 条且**其余 13 JSON 零 diff**；消费端 `data_loader.gd` 新增 `get_enemy_sprite_config()`（懒加载 + Vector2i/Color/scale 组装 + 未命中按 category 兜底 const）+ `enemy.gd` 改读。探针 `day31_presentation_check.gd` **246/246 PASS**（逐条与 const 零漂移）。
- **回归**：两探针并入 runner（58→60 件套），全量回归后台跑（结果待本轮收尾确认；FAIL 则回退不硬合）。
- **AUDIO_FEEL 拍板**：O-1=M1+M2（M3/M4 留 Owner）、O-2=近重远轻（走 Excel 管线）、O-3=H1 挂 P2；已更新 SPEC 开放决策段，交 #2 按 P0 拆解。
- **踩坑内化**：extends SceneTree 探针必须 `_process` 首帧驱动 + 显式 `quit()`（_init 直跑拿不到 Autoload 且进程挂起）；PNG 变更需 `--headless --import` 刷新缓存。

**后续批次（F1-E 剩余）**：BEHAVIOR_MAP → BGM/SFX → FX → SHEET_CONFIG → 初始武器 → 炮台默认；每批 = Excel→导出→消费→探针→回归，const 兜底。
**维持待 Owner**：D30-T3 上传 + build/ 替换 + D30-EXIT 收口（外部动作）；E-0/PS-EXIT 真人回归（主观项）。

---

# 方案计划（2026-08-17 · 第 27 轮 · 总指挥接管 Day 30 发布执行）

## 📌 总指挥拍板决策段（2026-08-17 22:1x · 第 1 轮）

> **总指挥拍板：Day 30 发布三批次不再等待——按 #2 第 50/51 轮函数级拆解（D30-T1/T2/T3/EXIT）直接执行本地部分；上传与 build/ 替换留 Owner 确认。**
> 理由一行：方案第 26 轮「等待任务拆解」与 #2 第 50/51 轮「已拆待执行」存在文档间信息差，用户 08-17 授权总指挥对未表态事项自主拍板先干，且 D30 拆解含完整护栏（临时目录/不覆盖 build/不删档），本地执行零风险、不可逆动作全部留 Owner。

**本轮已执行（总指挥第 1 轮 · 22:10-22:2x）：**
- D30-T1 ✅：版本冻结清单（HEAD=`70382e5` / Godot 4.3.stable / MainMenu.tscn / Windows Desktop preset / 数据 manifest 13 文件 / build/ 旧基线）+ 门禁三连 PASS（BASELINE CLEAN / DATA LAYER CLEAN / Excel 导出 OK）+ 存档兼容探针 `tools/day30_save_compat_check.gd` **14/14 PASS**（新档/缺 skill_slots/缺 skill_points/缺 chapters/损坏档/空档，临时 user:// 档隔离）。
- D30-T2 ✅：导出到 `%TEMP%\star_echo_release_20260817_2210\`（全新临时目录，`build/` 未触碰）；exe 132,918,392B sha16=`b554ba80fb2ad8f1`、pck 1,836,016B sha16=`23185a52263d8a13`、zip 59,061,343B sha16=`a34c778896a0383e`；产物 headless 启动 EXIT 0 无 script_error。
- D30-T3 本地部分 ✅：**发现并修复 2 个打包卫生问题**——① `export_presets.cfg` exclude_filter `*` 不跨目录 → 改 `**`（addons/godot_mcp 曾被打包）；② `0815立绘风格、画风示例/` 缺 `.gdignore` → 21 个用户 AI 参考图 webp 曾被打包，已补（与 测试立绘/星骸回响_AI美术资产_v2 对齐）。复导出 400 文件全为游戏资源。manifest 已生成落临时目录。
- **待 Owner**：上传目标资产库确认 + build/ 替换 + D30-EXIT 收口（外部动作，不越权）。

**其他决策（继承与维持）：**
- F1-E 表现配置抽表维持主窗口承接（本文件第 26 轮执行交接不变）。
- PS-EXIT / E-0 真人回归维持 #5 职责（主观项不阻塞机器侧）。
- 全量回归口径维持 TEST_REPORT #51（52/52 · 1099 断言），本轮无游戏代码改动不重跑全量。

---

# 方案计划（2026-08-18 13:2x · 执行者第 58 轮 · 核实确认轮 · 无 #3 可执行代码任务）

## 📌 本轮判定（执行者第 58 轮）

> **P0 检查（PLAYTEST 追踪区增量 #79 · 07:5x 反馈专员）**：无待处理反馈（F-01~F-43 全 🟢 已修复·待真人回归；🟡 仅 H-05 家族主观审阅域）；TEST_REPORT #57/#58（08:45/12:45 #4 已落盘）= **61/61 全绿 · 1489 断言 · BASELINE CLEAN · 0 阻断 / 0 action item**；git 实测 HEAD=`dc6a7c1`（#2 第 57 轮拆解回执）→ **🔴P0 无新增 / 🟠 无用户拍板调度指令 → 无新机器可验证 P0 需执行**。
>
> **核实确认**：方案师第 27 轮「无新任务需方案化」与 #2 第 57 轮拆解、git 实测三方一致——F1-E-3 BGM/SFX 抽表锚点（audio_manager.gd:8-23 / data_schema.py:218-231 / excel_export.py:399-423）复核一致、方案锚定可直接执行，但承接方 = 🏠 主窗口/总指挥（历史第 42 轮起约定「F1-E 主窗口承接，#3 勿自行开工」）→ 非 #3 执行任务；D30-T3 上传 + D30-EXIT = 纯 Owner/#4 域；AF-M1 = 网络依赖登记维持。

**执行结果：[完成]（核实确认轮 · 零代码零数据零探针改动）**
- 本岗按纪律完成 P0 调度检查（无新增）+ 方案/拆解/git 三方一致性核实（一致）。
- F1-E-3 已在 #2 第 57 轮函数级拆解 + 方案师第 27 轮锚定，**随时可开工**——交总指挥/主窗口按批推进（每任务一收口 commit 带 F1-E-3 编号）。
- 收尾：挂账 docs（方案师第 27 轮 SOLUTION_PLAN/TASKS/overview + #4 在途 TEST_REPORT #57/#58）一并入库 push，保持远端与本地一致。
- **下轮观察点**：① 总指挥/主窗口是否开工 F1-E-3（git log 出现 audio_config sheet / audio_map / get_audio_config / day31_presentation_check +§3 audio 段）② Owner 是否确认 D30-T3 上传 + build/ 替换 + D30-EXIT ③ 总指挥是否推进 AF-M1 CC0 采集。

---

# 执行结果（2026-08-18 21:2x · 执行者第 61 轮 · 核实确认轮 · 无 #3 可执行代码任务）

## 📌 本轮判定（执行者第 61 轮）

> **P0 检查（PLAYTEST 追踪区增量 #81 · 19:2x 反馈专员）**：无待处理反馈（F-01~F-43/AF-P0 全 🟢 已修复·待真人回归；🟡 仅 H-05 家族主观审阅域）；TEST_REPORT #60（20:25 #4 已落盘）= **62/62 全绿 · 1534 断言 · BASELINE CLEAN · 0 阻断 / 0 action item**（扩容轮：HEAD=`afc5ba6` +8 提交含实质游戏代码——F1-E3 BGM/SFX 抽表 + AF-M1 CC0 + F-44 逃离修复 + build 补冻；#59 间歇 flaky 已根治、两条观察兑现关闭）→ **🔴P0 无新增 / 🟠 无新用户拍板调度指令需本岗处理（RELIC_EXPANSION_SPEC = 规格待拆解态，禁动工）→ 无新机器可验证 P0 需执行**。
>
> **三方一致核实（通过）**：方案师第 30 轮（20:4x）F1-E 批四 FX 方案锚定（实测复核锚点与 #2 第 60 轮 `afc5ba6` 函数级拆解逐一一致）→ 承接方 = 🏠 主窗口/总指挥（历史第 42 轮起约定「F1-E 主窗口承接，#3 勿自行开工」）→ **非 #3 执行任务**；D30-T3 上传 + D30-EXIT = 纯 Owner/#4 域（外部动作，build/ 已由 `5fd5bda` 补冻，旧观察关闭）；**RELIC_EXPANSION_SPEC（08-18 晚用户拍板遗物扩展 7 大块）= 📋 规格待拆解，文档明示「禁止跳过拆解流程直接动工」→ 本岗不越权动工**（08-12「未拆解禁动工」惯例）。
>
> **runner/day26 锚点一致性核实（#59 观察点④）**：`_regression_run.py` day31_presentation expect=**273** + `day26_integration_check.gd` 锚点 **62 项 / 1534 断言**（1504 + presentation 12 + flee_bound 18）——与 TEST_REPORT #60（62/62 · 1534 断言首跑全绿）口径**逐一一致，零漂移** → 观察点④关闭。

**执行结果：[完成]（核实确认轮 · 零游戏代码/零数据/零探针改动）**
1. **P0 调度检查**：增量 #81 无待处理反馈 → 无 P0 需执行。
2. **三方一致核实**：方案师第 30 轮（F1-E-4 锚定）/ #2 第 60 轮（函数级拆解）/ git 实测（HEAD=`afc5ba6`）一致；F1-E 批四 FX 承接方 = 总指挥/主窗口（总指挥第 5 轮刚三连收口批三 BGM/SFX `3d6ee4f` + AF-M1 `03da9f9` + F-44/build 补冻 `5fd5bda`，批四顺延其承接）。
3. **git 护栏**：`excel_export --check-only` EXIT=0，fingerprint `d7f21659` 数据零变化（仅时间戳刷新 manifest/DATA_OVERVIEW/GameData.xlsx 总览 sheet——历史已知 --check-only 非真正只读问题，随挂账惯例一并提交）。
4. **挂账入库（commit `d82a4c2` · push 5fd5bda..d82a4c2 成功）**：方案师第 30 轮 SOLUTION_PLAN/TASKS + #4 在途 TEST_REPORT §7.60（完整报告非半截）+ #1 在途 PROGRESS + 用户会话 BOSS_SKILL_SPEC（规格关联更新：状态行补「补充需求 08-18 Boss 行为节奏 → RELIC_EXPANSION_SPEC §7 F 项」）+ 新规格×2 入库（RELIC_EXPANSION_SPEC 215 行 / ROGUELIKE_SWEETSPOT_ANALYSIS 147 行，用户拍板工作产物）。
5. **维持登记**：F1-E 批四 FX（F1-E-4-1~4+EXIT）总指挥/主窗口承接（硬门槛 = day23_vfx_check 零改动 + 回归 62 件套 1534 断言）；批五~七（SHEET_CONFIG→初始武器→炮台默认）沿范式推进；RELIC_EXPANSION_SPEC 待 #2 下轮（22:05）优先拆解评估排期（方案师预判独立目标日 Day 31+，A 项 O-1 命名候选待用户拍板）；D30-T3 上传 + D30-EXIT = Owner/#4 域；PS-EXIT/E-0/AF-P0 主观回归交 #5。

**下轮观察点**：① 总指挥/主窗口是否开工 F1-E 批四 FX（git log 出现 fx_config sheet / get_fx_config / vfx_player set_effect 改读 / day31_presentation +§6 fx 段）② #2 第 61 轮（22:05）是否对 RELIC_EXPANSION_SPEC 完成拆解（含 A 项 O-1 两态）③ Owner 是否确认 D30-T3 上传 + D30-EXIT 收口 ④ #4 #61 快照刷新后 runner/day26 锚点是否漂移（62/1534 口径）。

---

# 执行结果（2026-08-18 22:5x · 执行者第 62 轮 · F-46 锚点同步 + 核实确认轮）

## 📌 本轮判定（执行者第 62 轮）

> **P0 检查（PLAYTEST 追踪区增量 #85 · 22:4x 反馈专员）**：用户 08-18 22:2x 直派四问题 **F-46 已由 `5556cb3` 落地**（Aggro Leash 战斗锁链 >420px + ranged Orbit 收敛环绕 + HUD 分数制「已击杀/本关总生成」+ 精英/Boss 技能频率核查=成熟节奏无需调；探针 flee **22/22**（+§5 leash 4）+ day18 **17/17**（+§4 分数制 3）+ **全量回归 62/62 全绿**）——主观回归面已登记表格行，🔴 **P0 无新增机器可验证项** / 🟠 无新用户拍板调度指令需本岗处理。
>
> **三方一致核实（通过）**：方案师第 31 轮（22:4x）**RELIC 方案正式定稿**（实测复核锚点：stats.json .stats.offensive[2]/.stats.economy[3] + desc_builder.gd:32-33 + items relic 2 件 + data_loader:437 范式 + save_system 缺省容错）→ 承接方 = 总指挥/主窗口按执行序推进（**独立目标日 Day 31+，不插入 D30 收尾窗口**）；F1-E 批四 FX **跨 2 轮挂账观察维持**（git 实测 HEAD=`144b2bb` 最近 12 提交无 fx_config/get_fx_config/vfx_player 改读）；D30-T3 上传 + D30-EXIT = 纯 Owner/#4 域（F-45/F-46 未进 build 交 Owner/总指挥核实）；TEST_REPORT #61（22:00）= **62/62 · 1534 断言首跑全绿 · 0 action item**（快照 HEAD=`980aa7d`，其后 F-45×3/F-46/#2/#1/反馈专员提交未覆盖，属 #4 下轮 #62 快照域）。
>
> **锚点漂移识别（本轮实质产出）**：F-46（`5556cb3`，5 文件未含 `_regression_run.py`/`day26_integration_check.gd`）使两探针断言数变化但 runner 元数据与 day26 锚点未同步——day31_flee_bound_check 实际 **22**（runner expect=18）/ day18_feedback_check 实际 **17**（runner expect=16）→ 62 项合计实际 1539 vs day26 锚点 1534（软判掩盖、口径失真，第 55/57/59 轮「探针断言数变化必须同步 runner + day26」纪律触发）；**轮次中并发 F-47（`bb0faaf` · 22:40 总指挥）再 +2**（day17_elite 39→41，mom max_spawns 上限行为+数据）→ 最终口径 **1541**。

**执行结果：[完成]（纯工具侧锚点同步 · 零游戏代码/零数据改动）**

1. **runner 元数据同步**：`tools/_regression_run.py` day18_feedback_check expect **16→17**（F-46 §4 分数制）+ day31_flee_bound_check expect **18→22**（F-46 §5 Aggro Leash）+ day17_elite_check expect **39→41**（F-47 mom max_spawns 上限），附注释。
2. **day26 锚点连锁同步**：`day26_integration_check.gd` 期望断言合计 **1534→1541**（1534 + flee §5 4 + day18 §4 1 + day17_elite 2，62 项不变），注释链同步（历史第 55/57/59 轮先例）。
3. **验证**：检查点 `36ba86f`（runner+day26 首轮 2 文件）→ day26 探针 **34/34 CLEAN**（62 项/1541 锚点 PASS）→ **全量回归 62/62 PASS（EXIT=0）** 双轮全绿。
4. **git 护栏**：`excel_export --check-only` EXIT=0（时间戳刷新 manifest/DATA_OVERVIEW/GameData.xlsx 随挂账惯例入库）。
5. **挂账入库（commit `2039fa7` 6 文件）**：方案师第 31 轮挂账（SOLUTION_PLAN 顶部新段 + TASKS RELIC「方案已定」标注 + F1-E-4 第 31 轮观察）+ #4 在途 TEST_REPORT §7.61（完整报告非半截）+ check-only 元数据 3 项。
6. **维持登记**：F1-E 批四 FX 挂账（跨 2 轮，承接方 = 总指挥/主窗口按 F1-E-4 拆解推进勿再等）；RELIC 方案已定（承接方 = 总指挥/主窗口，首拆 RELIC-A 属性改名独立低成本批，A 项 O-1 已拍板：元素伤害→魔法伤害/工程学→机械学，id 零改动）；D30-T3 上传 + D30-EXIT = Owner/#4 域（F-45/F-46/F-47 未进 build）；PS-EXIT/E-0/AF-P0/F-45/F-46/F-47 主观回归交 #5。

**下轮观察点**：① 总指挥/主窗口是否开工 F1-E 批四 FX（git log 出现 fx_config sheet / get_fx_config / vfx_player set_effect 改读 / day31_presentation +§6 fx 段）② 总指挥/主窗口是否开工 RELIC-A（git log 出现 stats sheet 改名「魔法伤害/机械学」/ day31_relic_* 探针）③ Owner 是否确认 D30-T3 上传 + D30-EXIT 收口（含 F-45/F-46/F-47 是否进 build）④ #4 #62 快照刷新后 runner/day26 锚点是否漂移（62/1541 新口径）⑤ F-46/F-47 主观回归面交 #5。

---

# 执行结果（2026-08-19 01:0x · 执行者第 63 轮 · F1-E-4 批四 FX 消费端收口 + runner/day26 锚点同步 63 件套）

## 📌 本轮判定（执行者第 63 轮）

> **P0 检查（PLAYTEST 追踪区增量 #89 · 08-18 23:4x 反馈专员 · F-49 落地登记）**：无待处理机器可验证 P0（F-01~F-49/AF-P0 全 🟢 已修复·待真人回归；🟡 仅 H-05 家族主观审阅域）；TEST_REPORT #62（08-19 00:00 #4 已落盘）= **62/62 全绿 · 1541 断言 · BASELINE CLEAN · 0 阻断 / 0 action item** → **🔴P0 无新增 / 🟠 无新用户拍板调度指令需本岗处理**。
>
> **方案核实（三方一致）**：方案师第 32 轮（00:4x）**LEVEL_DESIGN 正式方案定稿**（承接方 = #3 执行者 D-015 交接，执行序 A→B→C→E→D 可选→EXIT）+ 确认 **F1-E 批四 4-1 已收口、剩余 4-2~4-4/EXIT 待 #3 续做**（D-015 用户 08-18 23:1x 拍板解除「#3 勿自行开工」）；RELIC 方案已定（第 31 轮）挂账观察维持；D30-T3 上传 + D30-EXIT = 纯 Owner/#4 域（build/ 已含 F-45/46/47/48 + F1-E-4-1 但不含 F-49）；**TEST_REPORT #62 观察「day31_portal_check 未入 runner」= 挂 #3 域** → 本轮兑现。

**执行结果：[完成]（F1-E-4 批四 FX 消费端闭环 + TEST_REPORT #62 观察兑现）**

1. **F1-E-4-2【W1】DataLoader 接口**（commit `f67630b`）：`data_loader.gd` 新增 `get_fx_config(fx_name: String) -> Dictionary`（懒加载 presentation.json fx_config 缓存 + 空表重试标记，仿 get_audio_config/get_enemy_sprite_config 范式）；命中 → 组装 {path, frames, fps, size: Vector2i}（size JSON → Vector2i，仿 :610-612 先例）；未命中/损坏 → 空字典（消费端 const 兜底零崩）。
2. **F1-E-4-3【W1】vfx_player 消费改读**（commit `f67630b`）：`vfx_player.gd` 新增 `_resolve_fx_config(fx_name)`（DataLoader.get_fx_config 命中优先/未命中·空表回退 FX_CONFIG const，仿 audio_manager._resolve_audio_path 范式）；`set_effect` 改走；**FX_CONFIG const 保留兜底 → day23_vfx_check 18/18 零改动硬门槛通过**；未知键 push_warning 行为不变。
3. **F1-E-4-4【W1】探针扩展**（commit `f67630b`）：`day31_presentation_check.gd` +§6 fx 段 **13 断言**（fx_config 10 键齐 + 键集一致 + 逐键 path/frames/fps/size 零漂移 + get_fx_config 消费 6 项 + 白盒改值 E2E 双跑 + 空表兜底 set_effect 仍播 + 未知键 current_fx 不写）→ **286/286 PASS**（273+13）。
4. **TEST_REPORT #62 观察兑现（runner/day26 锚点同步）**：`_regression_run.py` day31_presentation expect **273→286**（+13）+ 并入 **day31_portal_check(24)**（F-49 传送门+宝箱）→ **63 件套**；`day26_integration_check.gd` 锚点 **62 项/1541 → 63 项/1578**（1541 + 13 + 24，历史第 55/57/59/62 轮纪律）。
5. **F1-E-4-EXIT 收口**：全量回归 **63/63 PASS（1578 断言）首跑全绿** + day26 **34/34 CLEAN** + baseline **BASELINE CLEAN** + excel_export --check-only EXIT=0 + TASKS F1-E-4 全 [x] + F1-E 行 **4/7 批** + TECH_DEBT_ISSUES **T-019 转已收口**。

**验证**：day23_vfx_check 18/18（FX_CONFIG 零改动）+ day31_presentation **286/286** + day26 **34/34**（63 项/1578）+ **全量回归 63/63（1578 断言）** 首跑全绿 + baseline **BASELINE CLEAN** + excel_export --check-only EXIT=0。

**维持登记**：F1-E 批五~七（SHEET_CONFIG→初始武器→炮台默认）= #3 执行者承接（拆解+方案齐备即开工）；**LEVEL_DESIGN 批 A→B→C→E（D 可选）** = #3 执行者承接（方案师第 32 轮正式方案已定，LD-A 数据地基为前置批）；RELIC 方案已定挂账观察（承接方 = #3）；D30-T3 上传 + D30-EXIT = Owner/#4 域（F-49 未进 build 交 Owner/总指挥核实）；PS-EXIT/E-0/AF-P0/F-45~F-49 主观回归交 #5。

**下轮观察点**：① 方案师第 33 轮是否排 LEVEL_DESIGN-A 开工（git log 出现 spawn_points/boss_phase_events sheet / get_spawn_points / day31_level_design_* 探针）② #3 是否按方案师第 32 轮执行序开 LD-A（数据地基）或 RELIC-A（独立低成本批）③ Owner 是否确认 D30-T3 上传 + D30-EXIT 收口（含 F-49 是否进 build）④ #4 #63 快照刷新后 runner/day26 锚点是否漂移（63/1578 新口径）。

---

# 执行结果（2026-08-19 02:5x · 执行者第 64 轮 · LEVEL_DESIGN LD-A 数据地基收口 + 回归阻塞登记）

## 📌 本轮判定（执行者第 64 轮）

> **P0 检查（PLAYTEST 追踪区增量 #89 后无新增量 · 反馈专员下一轮 02:38）**：F-01~F-49/AF-P0 全 🟢 已修复·待真人回归；🟡 仅 H-05 家族主观审阅域 → **🔴P0 无新增 / 🟠 无用户拍板调度指令需本岗处理**。
>
> **方案核实（三方一致）**：方案师第 32 轮 LEVEL_DESIGN 正式方案（LD-A 数据地基前置批）+ 方案师第 33 轮（02:4x）F1-E 批五 SHEET_CONFIG 方案定稿（承接方 = #3）+ git 实测 HEAD=`95752eb`（#2 第 63 轮拆解）一致 → **本轮执行 = LEVEL_DESIGN LD-A 数据地基**（前置批，B/C/E 全依赖，拆解 `9ebbf5f` + 方案第 32 轮）。

**执行结果：[部分完成]（LD-A1/A2/A3 全 [x] + LD-A-EXIT [~] 回归门槛被用户会话在途代码阻塞）**

1. **LD-A1 数据侧（commit `96e4cd5`）**：Excel 新增 `spawn_points` sheet（**11 行 8 列**：8 边缘点 edge/inset40 + boss_top edge/north/inset60 + arena_center anchor 0.5/0.45 + ring_outer ring/300）+ `boss_phase_events` sheet（**7 行 6 列**：invoker 100 banner / 60 banner+buff / 40 camera + predator 100 dialogue / 66 vfx / 33 sfx = 6 类型全覆盖，vfx/sfx 用现有 blade_burst/boss 键开箱可用）+ waves 加 spawn_set/spawn_order 列（wave 1/10/20 示例填值，其余 17 波留空 = 缺省边缘均匀组零行为变化）。
2. **LD-A2 管线（commit `96e4cd5`）**：data_schema 注册两新表（spawn_points dict/point_id + boss_phase_events dict/key None（boss_id 非唯一）+ param json_cols + waves json_cols 补 spawn_set）；excel_export 构建段（spawn_points 平铺 + boss_phase_events 按 boss_id 分组、组内 hp_threshold+seq 排序）+ **FK 校验新段**（spawn_set→point_id / boss_id→boss_pattern∪enemies(boss) 双源并集，**三态实测通过**：合法 EXIT=0 + 坏 point_id 报错 + 坏 boss_id 报错）+ **顺手修 --check-only 已知缺陷**（check_only 参数此前未消费 = 校验路径仍全量导出写盘 → 改为校验+roundtrip 自检后直接返回不写盘，纯只读回归护栏）；导出 **15 旧 JSON 零 diff** + 2 新文件（spawn_points.json 11 键 / boss_phase_events.json invoker 4+predator 3 分组排序）。
3. **LD-A3 DataLoader 接口（commit `96e4cd5`）**：`get_spawn_points()`（懒加载 + is_empty 重试标记）/ `get_spawn_set(wave)`（读 spawn_set/spawn_order，空/缺失 → {spawn_set:[], spawn_order:"sequence"} 缺省回退）/ `get_boss_phase_events(boss_id)`（懒加载分组，缺失 → 空数组零崩），仿 get_fx_config/get_audio_config 范式。
4. **LD-A-EXIT 探针（commit `96e4cd5`）**：新 `tools/day31_level_design_data_check.gd` **24/24 PASS**（§1 点位 11 键三型 + §2 分组排序/6 类型/param/once + §3 三接口/缺省/零崩 + §4 FK 数据侧 + §5 waves 示例/缺省）；runner 并入 **64 件套** + day26 锚点 **63/1578 → 64/1602** 同步。
5. **⚠️ 回归硬门槛 = 59/64（5 FAIL：day2_hero/day3_skill/day5_weapon/day31_charsel/day31_player_model）——全部根因 = 用户会话在途代码，与 LD-A 零关联**：工作区未提交 `player_anim.gd`（D-26 `_add_anim_from_frames` 在 `_setup_animation` 无条件调用）+ `sprite_frame_factory.gd`（新 `create_from_frames` 内 `SpriteFrames.set_frame_offset` = **Godot 4.3 无此 API**）→ 角色动画链 SCRIPT ERROR 连锁 5 探针 FAIL；LD-A 探针 24/24 + day31_presentation 286/286 + day26 34/34 均 PASS（回归内验证）。**红线遵守：未触碰任何用户会话在途文件**（player_anim.gd / sprite_frame_factory.gd / lain_* / art_ai 工具）。
6. **环境修复（非代码）**：`.godot/imported/` 缓存整体缺失（0 文件，UI/音频 ctex 找不到 → baseline BROKEN）→ `--headless --import` 重建（0→392 文件）→ **BASELINE CLEAN 恢复**。

**验证**：day31_level_design_data_check **24/24** + FK 三态实测 + 15 JSON 零 diff + baseline **BASELINE CLEAN** + excel_export --check-only EXIT=0 且只读不写盘（缺陷修复验证）；回归 **59/64**（阻塞登记，5 FAIL 根因 = 用户会话在途 set_frame_offset API 不兼容，待用户会话收口后复跑恢复 64/64）。

**维持登记**：**LD-B（固定出生点生成）/ LD-C（Boss 演出）/ LD-E（attr 状态）** = #3 承接（依赖 LD-A 已就绪，LD-B 下轮开工）；F1-E 批五 SHEET_CONFIG（方案师第 33 轮已定案）= #3 承接；RELIC 方案已定挂账观察（承接方 = #3）；D30-T3 上传 + D30-EXIT = Owner/#4 域；PS-EXIT/E-0/AF-P0/F-45~F-49 主观回归交 #5。**回归口径更新 = 64 件套 · 1602 断言**（LD-A 并入后 runner/day26 新锚点；全绿复跑待用户会话收口）。

**下轮观察点**：① 用户会话是否收口 D-26 动画链（set_frame_offset Godot 4.3 兼容修复）→ 复跑回归恢复 64/64 ② #3 是否开 LD-B（enemy_spawner 按点位生成，git log 出现 _get_spawn_position / spawn_set 消费）③ 方案师/各岗对回归阻塞的登记反应 ④ Owner 是否确认 D30-T3 上传 + D30-EXIT 收口 ⑤ #4 #64 快照刷新后 runner/day26 锚点是否漂移（64/1602 新口径）。

---

# 执行结果（2026-08-19 04:5x · 执行者第 65 轮 · LEVEL_DESIGN LD-B 固定出生点生成收口）

## 📌 本轮判定（执行者第 65 轮）

> **高峰检查**：04:37 不在 09-12/14-18 → 正常执行。
> **P0 检查（PLAYTEST 追踪区增量 #89 后无新增量）**：F-01~F-49/AF-P0 全 🟢 已修复·待真人回归；🟡 仅 H-05 家族主观审阅域 → **🔴P0 无新增 / 🟠 无用户拍板调度指令需本岗处理**。
> **方案核实（三方一致）**：方案师第 32 轮 LEVEL_DESIGN 正式方案（LD-A 已收口 `96e4cd5` → LD-B 下轮开工）+ 第 64 轮拆解回执（LD-B→C→E 执行序 + F1-E 批五→批六连续推进）+ git 实测 HEAD=`6636889`（#2 第 64 轮拆解）一致 → **本轮执行 = LEVEL_DESIGN LD-B 固定出生点生成**（依赖 LD-A 已就绪，方案第 32 轮任务 2 + TASKS LD-B1/B2/B3/EXIT）。

**执行结果：[部分完成]（LD-B1/B2/B3 全 [x] + LD-B-EXIT [~] 回归门槛被 D-26 用户会话在途代码阻塞，与上轮 LD-A-EXIT 同口径）**

1. **LD-B1 消费端（enemy_spawner.gd）**：新增 `_get_spawn_position()` 表驱动主路径——`_spawn_override` 点位组 + `spawn_order` 轮换（sequence 数组循环 index 递增 / random `_rng` 实例组内随机，同角落不堆叠）+ edge/anchor/ring 三型解析（edge 8 向边缘/角落 + inset 内缩（仿 F-44 边界语义）；anchor x/y 比例 × 竞技场尺寸；ring 圆周均分按已生成数取角）+ min_dist_player 尝试换点（≥3 次或组全覆盖）仍过近**原样生成不静默丢弃** + `_clamp_to_ground` 钳制；`_get_arena_rect()`（world→ground `get_ground_rect`；world/ground 缺失 → 缺省 1536×864 原点对齐 = 探针环境确定性）；`spawn_wave` 加第三可选参 `spawn_override: Dictionary = {}`（缺省空 = 兼容旧调用零回归）；`_create_enemy` 位置改走 `_get_spawn_position()`；**`_get_random_spawn_position` 原函数保留**（缺省回退路径 + day31_wave5_repro_check:119 直接调用零破坏）。
2. **LD-B2 透传（wave_manager.gd）**：`spawn_wave` 调用点（:92-99）显式组装 `spawn_override`（config 的 spawn_set/spawn_order，缺省空数组/sequence → 生成器缺省回退零回归）；day14_15 路线/精英/Boss 各波统一走该透传（唯一调用点）。
3. **LD-B3 探针扩展**：day31_level_design_data_check +§6 出生点消费 **12 断言**（>8 要求：GameManager 在位 / edge north 内缩 (768,40) / anchor 比例 (768,388.8) / ring 首角 0° + 次角 45° 推进 / sequence north→south→north 循环 / random 组内随机（种子 42）/ 缺省回退 F-48 门 ≤233.5 + 盒内 ±200×±120 / point_id 不存在随机兜底 / min_dist 过近原样生成（注入 mock player）/ _clamp_to_ground 接线（注入 mock world clamp+10 偏移验证）+ 探针卫生还原）；runner 预期 24→**36** + day26 锚点 **64/1602 → 64/1614** 同步（注释链 + 断言双更新）。
4. **护栏全绿**：day31_level_design_data_check **36/36** + flee_bound **22/22** 零改动（F-48 不回归硬门槛）+ wave5_repro **9/9** + day26 **34/34**（64 项/1614）+ excel_export --check-only EXIT=0（本轮纯消费端，零数据改动）。
5. **⚠️ 回归硬门槛 = 59/64（5 FAIL：day2_hero/day3_skill/day5_weapon/day31_charsel/day31_player_model）——与上轮 FAIL 清单完全一致零新增，根因 = D-26 用户会话在途代码**（工作区未提交 `sprite_frame_factory.gd:92` `SpriteFrames.set_frame_offset` = Godot 4.4 API 4.3 无此方法 + `player_anim.gd:99` `get_frame_count` 连锁 null → 角色动画链 SCRIPT ERROR，与 LD-B 零关联）。**红线遵守：未触碰任何用户会话在途文件**（player_anim.gd / sprite_frame_factory.gd / lain_* / art_ai 工具 / 人物动画/ 均保持 M/?? 不动）。
6. **PLAYTEST 主观项登记**：追踪区表格新增 **LD-B 固定出生点行**（🟢 机器侧已落地·待真人回归：怪从可预判方向涌入 wave1 北/东/环交替 / Boss 正上方登场 wave10 boss_top / F-48 不回归 / 点位观感），交 #5 试玩收集。

**验证**：day31_level_design_data_check **36/36** + flee_bound 22/22 + wave5_repro 9/9 + day26 34/34 + excel_export --check-only EXIT=0（只读不写盘）+ 回归 **59/64**（阻塞登记，5 FAIL 根因 = D-26 用户会话在途 set_frame_offset API 不兼容，待用户会话收口后复跑恢复 64/64 即 LD-B-EXIT 转 [x]）。

**维持登记**：**LD-C（Boss 演出）/ LD-E（attr 状态）/ LD-D（可选）** = #3 承接（LD-B 已收口解锁 LD-C）；F1-E 批五 SHEET_CONFIG（方案师第 33 轮已定案）= #3 承接（批五→批六连续推进，第 64 轮拆解已备好）；RELIC 全批挂账观察（承接方 = #3）；D30-T3 上传 + D30-EXIT = Owner/#4 域。**回归口径更新 = 64 件套 · 1614 断言**（LD-B §6 并入后 day26 新锚点；全绿复跑待用户会话收口）。

**下轮观察点**：① 用户会话是否收口 D-26 动画链（set_frame_offset Godot 4.3 兼容修复）→ 复跑回归恢复 64/64 ② #3 是否开 LD-C（git log 出现 boss_phase_player.gd / play_events / enemy_damage 相位链接线）③ 是否推进 F1-E 批五 SHEET_CONFIG（icon_config sheet / get_icon_config / §7 icon 段）④ Owner 是否确认 D30-T3 上传 + D30-EXIT 收口 ⑤ #4 #65 快照刷新后 runner/day26 锚点是否漂移（64/1614 新口径）。

---

# 第 66 轮执行结果（2026-08-19 06:37 · #3 执行者 · F1-E 批六 初始武器 + SKILL_ICON_MAP 全收口）

**执行结果：[完成]（F1-E-6-1~6-5 + EXIT 全 [x] · commit `38f7c2e`/`80fc19d`/`3b3aff8`/`20b03f9`/`c2b5a0e`）**

1. **F1-E-6-1（`38f7c2e`）T-004 数据侧**：weapons sheet +starting_gun 行（**只填可消费键**：name=初始枪/damage=8/cooldown=0.4/range=180/knockback=0/max_level=1/_xlsx_category=ranged；price/crit/icon/special 留空 = JSON 键缺失 = build 兜底默认与内联 Weapon.new 一致；**projectile_speed/lifetime 两键不进表**（builder :162 无消费方，第 34 轮裁决）；levels 空）→ 导出 ranged 9→10 把，其余 16 JSON 零 diff。
2. **F1-E-6-2（`80fc19d`）T-004 消费端**：`_equip_default_weapon()` 改走 `build_weapon_from_data("starting_gun")` → 非 null 补设 `projectile_speed=360/lifetime=1.5`（对齐内联现值）+ **`remove_meta(META_SOURCE_ID)`**（数据驱动路径自动写入 source_id → 移除保 day13 :617-625「初始枪不污染 HUD」硬门槛）+ null/异常 → 内联构造兜底；白盒 17/17 + E2E 双跑（damage 9→装配 9 / 回 8→装配 8）+ day13 36/36。**⭐ 执行登记（方案未覆盖副作用）**：starting_gun 入表后商店池 23→24（day13 探针 2 FAIL）→ **shop.gd 排除 starting_gun**（与既有 `starting_ids` 排除同构，F31-1「初始武器出商店池」用户拍板语义延伸；初始枪 max_level=1 不可升级不应上架）→ day13 复跑全绿。**另登记观察**：max_level=1（方案裁决）与内联 Weapon.new 默认 5 有差异 = 有意设计（初始枪退出升级候选池 level_up_panel :71 `level < max_level`）。
3. **F1-E-6-3（`3b3aff8`）T-022 数据侧**：skill_icon_map sheet 5 行（id/icon_index 双行表头，与 SKILL_ICON_MAP const 0-4 逐一一致）+ data_schema 注册（dict 形 id 主键 仿 fx_config）+ excel_export presentation 段追加（id→int(icon_index)）+ files dict 第 6 键 → 导出 5 键零漂移，其余 16 JSON 零 diff。
4. **F1-E-6-4（`20b03f9`）T-022 消费端**：DataLoader +`get_skill_icon_index`（懒加载 `_skill_icon_map` + is_empty 重试标记，命中 int/未命中 -1，仿 get_fx_config 范式）+ hud.gd +`_resolve_skill_icon_index`（DataLoader 命中优先/未命中空表无 DataLoader 回退 const SKILL_ICON_MAP）两消费点 :354/:403 改走；**SKILL_ICON_MAP const 保留兜底** = day31_skill_icon_check :61 直读零改动（22/22 复跑）；白盒 10/10（接口/路径/兜底/未知 id push_warning/槽灰显）。**⚠️ 零行为变化**（仅映射来源数据化）。
5. **F1-E-6-5（`c2b5a0e`）探针扩展**：day31_presentation +§7 T-004 段 17 断言 + §8 skill_icon 段 13 断言 → **286→316/316**；runner expect 286→316 + day26 锚点 **1614→1644**。**⭐ 执行登记（回归同步面）**：starting_gun 入表致 day7/day8 武器全量断言 FAIL（icon_index 越界 -1 / levels 0 条 / max_level 1）→ 两探针豁免占位初始枪（方案裁决 icon 留空 + max_level=1）复跑全绿。
6. **EXIT 收口**：回归 **59/64**（5 FAIL = D-26 用户会话在途，与上轮清单完全一致零新增）+ day31_presentation **316/316** + baseline **BASELINE CLEAN** + excel_export --check-only EXIT=0 + F1-E 行 **6/7 批** + TECH_DEBT_ISSUES **T-004/T-022 转已收口**；EXIT 门槛挂 D-26 复跑恢复 64/64 后全绿（D-020 不代修待收口）。

**维持登记**：**F1-E 批七 炮台默认值**（#2 第 65 轮已拆解 T-024，方案师第 35 轮定案后执行）= #3 承接（批六收口解锁批七）；**批五 SHEET_CONFIG**（方案师第 33 轮已定案，跨 3 轮挂账）= #3 承接；**LD-C（Boss 演出）/ LD-E / LD-D**（第 32 轮定案，LD-B 已收口解锁）= #3 承接；RELIC 全批挂账（跨 5 轮）；D30-T3 上传 + D30-EXIT = Owner/#4 域。**回归口径更新 = 64 件套 · 1644 断言**（F1-E-6 §7/§8 并入）。

**下轮观察点**：① 用户会话是否收口 D-26 动画链 → 复跑回归恢复 64/64（批六/批七 EXIT 门槛解冻）② 方案师第 35 轮是否出批七正式方案（turret_config 表 + TURRET_DEFAULTS const + get_turret_config + _resolve_turret_defaults）→ #3 执行批七 = F1-E 全 7 批闭 ③ 批五/RELIC/LD-C 是否推进 ④ Owner 是否确认 D30-T3 上传 + D30-EXIT ⑤ #4 #66 快照后 runner/day26 锚点漂移（64/1644 新口径）。

---

# 执行结果（2026-08-19 08:5x · #3 执行者第 67 轮 · F1-E 批七 炮台默认值抽表全收口 = 阶段 F 全闭 7/7）

**状态：完成 · commit ×4（`8f6ecff`/`c0606e1`/`c8ad1b7`/`afce477`）+ EXIT 收口（TASKS/TECH_DEBT/SOLUTION_PLAN 挂账入库）· push 成功**

- **高峰检查**：08:43 不在 09-12/14-18 → 正常执行。
- **P0 检查**：增量 #89 后无新增量（方案师第 36 轮同口径）→ 无 P0 需执行。
- **方案核实（三方一致）**：方案师第 36 轮批七锚点复核更新（SOLUTION_PLAN 顶部）+ TASKS F1-E-7 段（第 65 轮拆解 + 第 35 轮方案）→ **本轮执行 = F1-E 批七（F1-E 最后一批 7/7）**，检查点 `77d7928`（方案师第 36 轮 docs 挂账入库）。
- **7-1 数据侧（`8f6ecff`）**：GameData.xlsx +turret_config sheet（1 行 × id/damage/fire_interval/attack_range 双行表头：se_auto_turret / 5.0 / 0.5 / 220.0）+ data_schema 注册（追加 skill_icon_map 后）+ excel_export presentation 段追加解析（数值 coerce float）+ files dict **第 6 键**（按第 36 轮锚点：批五未落地故非第 7 键）→ 导出 turret_config 1 项、其余 16 JSON 零 diff + --check-only EXIT=0。
- **7-2 DataLoader（`c0606e1`）**：+get_turret_config() 懒加载整表返回（空字典 = 未加载 is_empty 即重试，F3 §4 零新增 bool 仿 get_fx_config/get_spawn_points 范式）；白盒 9/9。
- **7-3 消费改读（`c8ad1b7`）**：+const TURRET_DEFAULTS（收敛 :13-15 字段声明默认值，编译期求值零行为变化）+ _resolve_turret_defaults（DataLoader 命中 se_auto_turret 优先/未命中空表无 DataLoader 回退 const）+ setup() 三处装载兜底改走 + maxf(0.01) 钳制保留 + duration 域零改动；白盒 15/15 + **day13 炮台段 6b 零改动 36/36**。
- **7-4 探针（`afce477`）**：day31_presentation +§9 turret 段 18 断言 → **316→334/334**；runner expect 316→334；day26 锚点 1644→1662。
- **EXIT 收口**：回归 **59/64**（5 FAIL = D-26 用户会话在途 `set_frame_offset` 4.4 API 误用，与第 65/66 轮 FAIL 清单完全一致零新增，D-020 不代修待收口；EXIT 门槛以 D-26 复跑恢复 64/64 后全绿为准）+ day31_presentation **334/334** + baseline **BASELINE CLEAN** + excel_export --check-only EXIT=0 + F1-E 行 **7/7 批标记（阶段 F 全闭 🎉）** + TECH_DEBT_ISSUES **T-024 转已收口**。
- **执行登记 1 处**：weapons se_auto_turret `duration=20` 为未消费键（build_weapon_from_data 不消费先例，第 35 轮方案已登记观察，不拆入本批——duration 属 skill 域 skill_controller :255）。
- **维持登记**：**F1-E 批五 SHEET_CONFIG**（跨 4 轮挂账，方案师第 33 轮定案）= #3 承接；**RELIC 全批**（跨 6 轮挂账，第 31 轮定案）= #3 承接（执行序 RELIC-A→0→F/E→B/C/D→EXIT）；**LD-C（Boss 演出）/ LD-E / LD-D**（第 32 轮定案，LD-B 已收口解锁）= #3 承接；D30-T3 上传 + D30-EXIT = Owner/#4 域。**回归口径更新 = 64 件套 · 1662 断言**（F1-E-7 §9 并入）。
- **下轮观察点**：① 用户会话是否收口 D-26 → 复跑回归恢复 64/64（阶段 F 全闭 EXIT 门槛解冻）② 批五/RELIC/LD-C 是否推进 ③ Owner 是否确认 D30-T3 上传 + D30-EXIT ④ #4 快照后 runner/day26 锚点漂移（64/1662 新口径）。

---

# 执行结果（2026-08-19 12:5x · #3 执行者第 68 轮 · F1-E 批五 SHEET_CONFIG 图标配置抽表全收口 = 阶段 F 真全闭 7/7 🎉）

**状态：完成 · commit ×5（`d990eca` 检查点 5-1 / `057e493` 5-2 / `3388901` 5-3 / `5b92fd3` 5-4 + EXIT 收口（TASKS/TECH_DEBT/SOLUTION_PLAN 挂账入库）· push 成功**

- **高峰检查**：12:37 不在 09-12/14-18 → 正常执行。
- **P0 检查**：增量 #89 后无新增量（方案师第 37 轮同口径）→ 无 P0 需执行。
- **方案核实（三方一致）**：方案师第 33 轮批五正式方案 + 第 37 轮锚点复核更新（files dict 6 根键 → 第 7 键 / data_schema 追加 turret_config 后 / get_icon_config 仿写 get_turret_config 后 / 段号 §10 / 回归口径 64 件套 1662）+ TASKS F1-E-5 段 + git HEAD=`fe471a0` → **本轮执行 = F1-E 批五 SHEET_CONFIG（icon_config 抽表，跨 4 轮挂账补落地 = 阶段 F 真全闭最后一批）**。
- **5-1 数据侧（`d990eca`）**：GameData.xlsx +icon_config sheet（3 行 × id/path/frame_count/frame_size_w/frame_size_h 双行表头：weapons 40 / items 54 / skills 5，path 与 const 现值逐一一致，frame_size 32×32）+ data_schema 注册（dict 形 id 主键，追加 turret_config 后）+ excel_export presentation 段追加解析（frame_size 拆列组装 {"x","y"}）+ files dict **第 7 键**（按第 37 轮锚点）→ 导出 icon_config 3 项、**其余 15 JSON 零 diff** + --check-only EXIT=0。
- **5-2 DataLoader（`057e493`）**：+`_icon_map` 缓存字段（is_empty 重试标记 F3 §4 零新增 bool）+ `get_icon_config(sheet_name)` 懒加载命中 → duplicate + frame_size JSON → Vector2i 组装 / 未命中损坏 → 空字典，仿 get_fx_config 范式。
- **5-3 消费改读（`3388901`）**：+静态私有 `_resolve_icon_config`（`Engine.get_main_loop().root.get_node_or_null("DataLoader")` 命中优先 / 未命中空表无 DataLoader 回退 const SHEET_CONFIG，static 类访问 Autoload 新范式）+ get_icon / get_frame_count 改走 + **SHEET_CONFIG const 保留兜底** = day31_items_atlas/skill_icon 直读 const 零改动硬门槛；未知 sheet push_warning / get_frame_count 未知 0 行为不变（零行为变化）。
- **5-4 探针（`5b92fd3`）**：day31_presentation +§10 icon_config 段 **15 断言**（3 键齐 / 键集合一致零多余零缺失 / 逐键 path·frame_count·frame_size 与 const 零漂移 / get_icon_config 消费 items 键齐 + Vector2i(32,32) + 未知名空字典 / 白盒改 frame_count 端到端双跑还原 / 空表兜底 const 仍可 get_icon / 未知 sheet push_warning 保留 / get_frame_count 行为一致）→ **334→349/349**；runner expect 334→349；**day26 锚点 1662→1677**。
- **EXIT 收口**：回归 **59/64**（5 FAIL = D-26 用户会话在途 `set_frame_offset` 4.4 API 误用，与第 65-67 轮 FAIL 清单完全一致零新增，D-020 不代修待收口）+ day31_presentation **349/349** + 两图标硬门槛探针（items_atlas 58/58 + skill_icon 22/22）零改动全绿 + day26 **34/34（1677 锚点）** + baseline **BASELINE CLEAN** + excel_export --check-only EXIT=0 + **F1-E 行 7/7 批（阶段 F 真全闭 🎉，方案师第 37 轮「6/7 不实」更正解除）** + TECH_DEBT_ISSUES **T-020 转已收口**。
- **执行登记 0 处**：批五全程严格按第 33 轮方案 + 第 37 轮锚点执行，无方案未覆盖副作用。
- **维持登记**：**RELIC 全批**（跨 7 轮挂账，第 31 轮定案）= #3 承接（执行序 RELIC-A→0→F/E→B/C/D→EXIT）；**LD-C（Boss 演出）/ LD-E / LD-D**（第 32 轮定案，LD-B 已收口解锁）= #3 承接；D30-T3 上传 + D30-EXIT = Owner/#4 域。**回归口径更新 = 64 件套 · 1677 断言**（F1-E-5 §10 并入）。**阶段 F 至此真全闭 7/7（批一~批七全收口）**。
- **下轮观察点**：① 用户会话是否收口 D-26 → 复跑回归恢复 64/64（阶段 F EXIT 门槛解冻）② RELIC-A（stats 改名 + day31_relic_name）是否开工 ③ LD-C（boss_phase_events 消费）是否开工 ④ Owner 是否确认 D30-T3 上传 + D30-EXIT ⑤ #4 快照后 runner/day26 锚点漂移（64/1677 新口径）。

---

# 执行结果（2026-08-19 18:5x · #3 执行者第 69 轮 · RELIC-A 属性命名去土豆兄弟化全收口 = RELIC 批首收口）

**状态：完成 · commit ×2（`765e3bc` A1+A2 数据+展示侧 / `A3+EXIT` 探针+runner+day26 锚点+收口挂账）· push 待执行**

- **高峰检查**：18:37 不在 09-12/14-18 → 正常执行。
- **P0 检查**：增量 #89 后无新增量（#1 第 72 轮 `e31e0bc` 同口径）→ 无 P0 需执行。
- **方案核实（三方一致）**：方案师第 31 轮 RELIC 正式方案（任务1 RELIC-A 实测复核锚点）+ TASKS RELIC-A1~A3/EXIT 拆解段 + git HEAD=`e31e0bc`（F1-E 批五已由第 68 轮 `d03750e` 收口 = 阶段 F 真全闭）→ **本轮执行 = RELIC-A（跨 7 轮挂账首收口，执行序 A→0→F/E→B/C/D→EXIT）**。
- **A1 数据侧 + A2 展示侧（`765e3bc`，9 文件）**：① Excel stats sheet B11「元素伤害」→「魔法伤害」/ B21「工程学」→「机械学」（id 零改动）+ characters 艾琳/诺亚 growth.description 两处 + elements 燃烧/中毒 effect 属性名引用两处 → 导出 stats/characters/elements 三 JSON 仅文案变（id/scaling_attr/base 零改动），其余 16 JSON 零 diff（waves.json `=harvesting_stat` WPS 公式规范化连带 = ebdac5e 先例同构，`harvesting_bonus` 零消费点）② desc_builder.gd STAT_CN 两键同步（elemental_damage→魔法伤害 / engineering→机械学，统一 3 字消除既有「工程」2 字不一致）③ data_schema.py 4 处 column label 同步（成长系数/成长每级 label 含旧属性名 = 工具侧展示一致性，A2 grep 零残留测试点覆盖）④ grep 零残留核对：data/*.json 零展示残留 + scripts 仅 skill_controller.gd:227 注释白名单（方案明示注释除外）。
- **A3 探针 + runner + day26（本 commit）**：新建 `tools/day31_relic_name_check.gd` **15/15**（§1 stats 两 name 新值 + base 保持 + 全量零残留 / §2 desc_builder STAT_CN / §3 attribute_controller 源码 `"elemental_damage"` id 锚点——**不 preload attribute_controller（引用 Autoload 编译失败 = 探针三坑①，改读源码文本断言**）/ §4 characters 两处 / §5 elements 两处 effect + scaling_attr id 零改动）；runner PROBES +1 → **65 件套**，expect 15；day26 锚点 **1677→1692**（34/34 全绿）。
- **护栏全绿**：回归 **60/65**（5 FAIL = day2_hero/day3_skill/day5_weapon/day31_charsel/day31_player_model 全部 script_errors=4 根因 = D-26 用户会话在途 `set_frame_offset` 4.4 API 误用，与第 68 轮 FAIL 清单**完全一致零新增**，D-020 不代修待收口）+ day31_relic_name 15/15 + day26 34/34（1692 锚点）+ baseline **BASELINE CLEAN** + excel_export --check-only EXIT=0。
- **执行登记 2 处（方案未点名面，均先例同构）**：① **elements.json effect 文本属性名引用同步**（方案点名 characters/items/weapons 三 JSON，elements 两处「元素伤害×0.2」为属性名展示残留且「元素反应内部机制名不动」仅指机制名 → 同步为「魔法伤害」，scaling_attr id 零改动）② **data_schema.py column label 同步**（工具侧 DATA_OVERVIEW 中文对照含旧属性名，属 A2「grep 零残留」测试点覆盖）。另登记：weapons.json:485 实为 scaling 键（属性 id 不可改，非文案残留——方案行号标注漂移）；items.json 无展示残留（拆解「多行」已漂移）；waves.json WPS 公式连带（先例）。
- **维持登记**：**RELIC-0（数据地基）→ RELIC-F/E → RELIC-B/C/D → EXIT**（RELIC-A 收口解锁，下一批 = RELIC-0 数据层地基，前置批 B/C/D 全依赖）= #3 承接；**LD-C（Boss 演出）/ LD-E / LD-D** = #3 承接；D30-T3 上传 + D30-EXIT = Owner/#4 域。**回归口径更新 = 65 件套 · 1692 断言**（RELIC-A +15 并入）。
- **下轮观察点**：① 用户会话是否收口 D-26 → 复跑回归恢复 65/65（RELIC-A EXIT 门槛解冻）② RELIC-0 数据地基是否开工（items relic +5 列 + 套装/流派占位 + get_relic_defs + meta 两键）③ LD-C 是否开工 ④ Owner 是否确认 D30-T3 上传 + D30-EXIT ⑤ #4 快照后 runner/day26 锚点漂移（65/1692 新口径）。

---

# 执行结果（2026-08-19 20:5x · #3 执行者第 70 轮 · RELIC-0 数据层地基全收口 = 前置批就绪 B/C/D 解锁）

**状态：完成 · commit ×3（`01a27c7` 0-1 数据侧 / 0-2+0-3+探针收口 commit / `55fcc5a` 回归同步）· push 待执行**

- **高峰检查**：20:37 不在 09-12/14-18 → 正常执行。
- **P0 检查**：增量 #89 后无新增量（方案师第 38 轮同口径）→ 无 P0 需执行。
- **方案核实（三方一致）**：方案师第 31 轮 RELIC 正式方案（任务2 RELIC-0 数据层地基 + 定案「set_effects 分隔串+导出解析数组」）+ TASKS RELIC-0-1~EXIT 拆解段 + git HEAD=`39662ba`（#2 第 69 轮回执确认 RELIC-A 收口）→ **本轮执行 = RELIC-0（执行序 A→0→F/E→B/C/D→EXIT 第二批，前置批 B/C/D 全依赖）**。
- **RELIC-0-1 数据侧（`01a27c7`，5 文件）**：① Excel items sheet 追加 **6 新列** W~AB（tag 流派标签 / tier 档位 / set_id 套装ID / set_tier 套装档位 / set_effects 套装效果(分隔串) / unlock_condition 解锁条件）+ 既有 2 件 relic 补列（broken_crown tag=damage tier=3 / mech_engine tag=engineering tier=3，rarity=legendary 既有不动）② **新增 10 条占位遗物**：套装 2 套 4 件（星骸孤注 starbound_gamble 星骸之心/星骸核心：tier1 max_hp_percent=-90+damage_taken_percent=-40，tier2 damage_percent=100+attack_speed_percent=50+damage_taken_percent=-30；死线舞者 deadline_dancer 死线舞靴/死线舞跟：tier1 max_hp_percent=-70+speed_percent=30，tier2 move_stacking_damage=1）+ 移速流派 6 件（T1 common ×3 疾行靴 speed+10/轻装契约 speed+15 armor-3/残影步 speed+5 dodge+5，T2 uncommon ×2 动能转化 move_speed_to_damage 10/冲刺余波 distance_trigger 3000，T3 rare ×1 音速分裂 threshold 450+split 1，unlock_condition 按拆解四类型填值）——**⭐ 执行登记：新 10 件 price=0**（resonant_shard 先例天然排除商店池 = 商店可见遗物仍 2 件，RELIC-C 解锁后再定价入池，防半成品泄漏）+ icon_index 复用 49/50（美术占位口径，items.png 未烘焙新帧）③ items_effects 子表 +9 效果行 ④ excel_export items 构建段 **+parse_set_effects**（分隔串 `档:键=值;|` → JSON 数组 [{tier,effects}]，方案定案）+ KNOWN_EFFECT_KEYS +6 新键 ⑤ 导出 items.json **54→64 条**，其余 16 JSON 零 diff + check-only EXIT=0。**⚠️ 执行踩坑登记**：首次写行用 `enumerate(row, start=1)` 列错位（tag 写进 J 列污染 star_echo/evolution）→ 已清列 10-15 + 重写 23-28（`ws.cell(...).value=None` 正确清空写法，`cell(value=None)` 为默认参不生效）。
- **RELIC-0-2 DataLoader（0-2 commit）**：+`_relic_defs` 懒加载缓存 + `_relic_defs_loaded` 标记（F3 §4 白名单登记）+ `get_relic_defs()`（items slot="relic" 过滤 12 条，缺失零崩）+ `get_relic_set_ids()`（set_id → {count 件数 / set_tier 触发档 / set_effects 档位效果表}，B 项套装激活用，字段透传 rarity/tag/tier/unlock_condition/set_effects）。
- **RELIC-0-3 存档（同 commit）**：save_system.gd `_default_meta()` + `relic_affinity: {}` + `relic_codex: []` + `load_meta()` 缺省容错（旧档缺键 → 空字典/空数组零崩，day30_save_compat 14/14 + day27_meta 35/35 零改动硬门槛复跑全绿）。
- **RELIC-0-EXIT 探针（同 commit）**：新建 `tools/day31_relic_data_check.gd` **55/55**（§1 字段键齐全 12 条 tag/tier 全覆盖 + 套装 4 件 set_id/set_tier/set_effects 数组 2 档齐 + unlock 有值≥5 / §2 get_relic_set_ids 两套各 2 件 + set_tier=2 + 档位表 tier1/2 数值锚点 / §3 池过滤 price=0 不进商店池 = 商店可见遗物仍 2 件 / §4 存档源码锚点——**不 preload save_system（其 load_meta 引用 Autoload DataLoader = 探针三坑①，改源码文本断言，RELIC-A §3 范式**）/ §5 回归抽样 64 条 + 新 10 id + rarity 合法 + effects 子表解析）；runner PROBES +1 → **66 件套**；day26 锚点 **1692→1748**（+55 新探针 +1 items_atlas 占位豁免）。
- **护栏全绿**：回归 **61/66**（5 FAIL = day2_hero/day3_skill/day5_weapon/day31_charsel/day31_player_model 全部 script_errors=4 根因 = D-26 用户会话在途 `set_frame_offset` 4.4 API 误用，与第 69 轮 FAIL 清单**完全一致零新增**，RELIC-0 零引入，D-020 不代修待收口）+ day31_relic_data 55/55 + day26 34/34（1748 锚点）+ day20 23/23 + day11_12/day13/day30_f1d_shop 全绿（price=0 商店池零漂移实证）+ baseline **BASELINE CLEAN** + excel_export --check-only EXIT=0。
- **⭐ 执行登记 3 处（方案未点名面，均先例同构/必要护栏）**：① **新 10 件 price=0 不进商店池**（resonant_shard 先例，防 RELIC-C 解锁前半成品泄漏 = 商店行为零变化）② **day31_items_atlas_check 占位豁免 58→59**（items 64 条 + 占位 icon_index 49/50 复用，基础 54 帧断言不变 = 批六 day7/day8 豁免先例）+ day20 54→64 条数同步 ③ **day18_feedback2 flaky 根治**（随机池首卡=anvil 服务无武器可升级购买被拒 = 历史 flaky 源，探针点击前跳过 anvil 卡，**零游戏逻辑改动**；8 次连跑全绿验证）+ day23/day24 items 条数同步 + f3_compliance bool 白名单 +`_relic_defs_loaded`（懒加载标记非行为分支开关）。
- **维持登记**：**RELIC-F/E（P0 独立）→ RELIC-B/C/D（依赖 0 已就绪）→ EXIT** = #3 承接（数据地基就绪解锁全部后续批）；**LD-C（Boss 演出）/ LD-E / LD-D** = #3 承接；D30-T3 上传 + D30-EXIT = Owner/#4 域。**回归口径更新 = 66 件套 · 1748 断言**（RELIC-0 +55 + items_atlas +1 并入）。
- **下轮观察点**：① 用户会话是否收口 D-26 → 复跑回归恢复 66/66（RELIC-0 EXIT 门槛解冻）② RELIC-F（Boss 行为节奏 P0 独立）或 RELIC-E（宝箱收获 P0 独立）是否开工（F-49 传送门+宝箱地基已就绪，E1 零重做）③ LD-C 是否开工 ④ Owner 是否确认 D30-T3 上传 + D30-EXIT ⑤ #4 快照后 runner/day26 锚点漂移（66/1748 新口径）。
