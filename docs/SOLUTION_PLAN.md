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
