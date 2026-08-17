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

## 当前开发日：Day 30（发布准备）

> **本轮状态：等待任务拆解。**
> 
> P0 调度硬性输入已检查：`docs/PLAYTEST_CHECKLIST.md`「未解决问题追踪区」截至增量 #70，无新增机器可验证的 🔴 P0 项或用户拍板调度指令；F-01~F-39 均为已落地、待真人回归的主观项。
>
> `docs/30DAY_PLAN.md` 对 Day 30 的目标是“发布准备（Steam 构建 / 导出 pck+exe / 存档兼容 / 资产库上传 build）”。但 `docs/TASKS.md` 当前仍只有三条高层发布项，尚未由 #2 拆成可执行批次，缺少文件清单、命令、输入输出、回滚点和验收判据。按项目纪律，本轮不擅自把高层目标转成执行方案。
>
> **红线遵守**：本轮不写代码、不改 `.gd/.tscn/.tres/.json` 游戏文件、不跑探针、不 git commit。仅覆盖本方案文档，并在 `TASKS.md` 对应台账项标注方案状态。

## 当前客观状态

- 玩家侧技能系统 PS-D 已收口：章节/路线/反馈/大地图相关探针分别为 11/11、54/54、28/28、20/20。
- 全量回归引用 `TEST_REPORT` #49：52/52 探针、1099 条登记期望断言、0 script_errors、`BASELINE CLEAN`。
- PS-EXIT 剩余为真人体验出口，不是新的代码任务；需由 #5 记录“通过 / 问题 / 未测”，不得以机器 PASS 替代真人结论。
- F1-E 表现配置抽表仍是阶段 F 唯一客观台账尾项，由主窗口按小批次承接；本轮不越权实施。
- `TEST_REPORT` 仍提示 `se_skill_sword_arc` 图标映射、MainMenu 主场景、Day 28 性能段与 PS-D 章末 Boss 映射等观察项；其中已由 PS-D 解决的机器侧内容不重新拆任务，真人确认项继续留在开放项清单。

## 任务1：PS-EXIT 真人体验出口（等待 #5 试玩记录）

- 文件：`docs/PLAYTEST_CHECKLIST.md` 未解决问题追踪区；`docs/TASKS.md` PS-EXIT 条目。
- 改动：不改游戏实现。一次完整局固定记录五组结论：
  1. 多技能位操作：空格/鼠标左键/鼠标右键触发已解锁槽位；各技能冷却独立；暂停菜单、商店、背包不误触发。
  2. 位移技能走位：dash/blink/leap 的距离、穿怪/落点、无敌帧、后摇是否形成可理解的走位解法。
  3. 技能遗物掉落节奏：精英掉落、20% 替代奖励、章 Boss 招牌技必掉、三选一装配/替换可读性。
  4. 章节节奏：章 1 末层 event 休整/奖励感；章 2-4 Boss 节奏与章界提示；`boss_layers=[6,10,14]` 与地图预见性一致。
  5. 剑士剑气：方向、范围、命中反馈和 Build 配合相较旧星刃是否形成可感知差异。
- 落地合理性：上述行为已有机器侧探针覆盖，剩余问题是手感、可读性和节奏判断；集中一次完整局可减少单项试玩偏差，且不把主观结果混入代码出口。
- 风险：低。只写试玩记录，不改变运行时行为。若发现确定功能缺陷，另建反馈条目交 #2 拆解，不在试玩记录中现场改码。
- 验证：#5 真人完整局记录；每组必须明确“通过 / 问题 / 未测”。五组全部有结论后才可关闭 PS-EXIT；“未测”不得标为通过。

## 任务2：PS-D 机器证据与主观开放项隔离（继续维持）

- 文件：`docs/TASKS.md` PS-D/PS-EXIT 条目；`docs/PLAYTEST_CHECKLIST.md` 未解决问题追踪区；`docs/TEST_REPORT.md` 顶部摘要由 #4 维护。
- 改动：本轮不修改 TEST_REPORT，不重复跑测试。台账继续引用 PS-D 已收口和 52/52 回归事实；PS-EXIT、E-0、F-16~F-39、F-37 UI、F-39 节点选择、MainMenu 主场景等保留为待真人确认，不标为机器阻塞。
- 落地合理性：TEST_REPORT #49 已覆盖当前机器面；重复增加探针或改断言口径会制造历史断言漂移。主观与客观分层符合既有护栏。
- 风险：低。并发岗位若刷新 PLAYTEST/TASKS，编辑前必须重读对应区块，避免覆盖最新增量。
- 验证：文档一致性检查：PS-D 四项保持 `[x]`；PS-EXIT 不声称真人已完成；开放项与 PLAYTEST 增量 #70 一致；机器证据只引用 TEST_REPORT #49。

## 任务3：F1-E 表现配置抽表（主窗口承接，本轮不执行）

- 文件：主窗口后续承接 `docs/GameData.xlsx` presentation sheet、`tools/data_schema.py`、`tools/excel_export.py`、相关表现消费脚本；本轮不改上述文件。
- 改动：仅确认小批次边界，继续按 `SPRITE_MAP` → `BEHAVIOR_MAP` → `BGM/SFX` → `FX` → `SHEET_CONFIG` → 初始武器 → 炮台默认配置的顺序承接；每批保留代码默认值作为缺省兜底。
- 落地合理性：F1-E 跨多个表现脚本、Excel schema、导出 JSON 和在途资产。一次性迁移会扩大回归面；由主窗口统一协调单一事实源更可控。
- 风险：中。表注册、导出、默认值和资产路径可能发生跨域漂移。替代方案：主窗口暂不承接时，保留当前默认值并明确登记延期，不为追求阶段完成度临时硬改。
- 验证：由主窗口后续逐批执行 Excel 导出检查、对应表现探针/场景 smoke、全量回归与 baseline；本轮不执行任何验证命令。
- 交接门槛：T-016~024 均有数据源、消费点和回归证据，且导出失败时旧默认值仍能启动；满足后再关闭 F1-E。

## 任务4：Day 30 发布准备（等待 #2 正式拆解）

- 文件：待 #2 在 `docs/TASKS.md` 补充可执行批次后再确定；当前不改 `build/`、`export_presets.cfg`、存档或上传目录。
- 当前高层目标：Steam 构建、导出 `pck+exe`、存档兼容、`build` 资产校验/上传。
- 本轮决策：**等待任务拆解**。#2 至少需要拆成以下三个可验收批次后，方案师再补文件级方案：
  1. 构建前检查与版本冻结：明确版本来源、工作区/资产快照、存档格式和构建输入。
  2. Windows/Steam 导出与存档兼容矩阵：明确 `pck+exe` 输出、启动路径、全新存档/旧存档/异常存档的兼容判据和回滚点。
  3. `build` 产物校验与上传：明确允许上传的文件清单、体积/哈希/启动检查、上传目标和失败回滚方式。
- 落地合理性：发布动作具有不可逆覆盖和用户存档风险；没有批次级输入时直接执行会把高层目标误当成授权，且可能覆盖现有 `build/` 或污染用户在途资产。
- 风险：高。风险包括错误版本导出、旧存档损坏、把调试/临时/敏感文件上传、覆盖现有发布产物。替代方案：先只做构建前只读盘点和临时目录导出，待兼容矩阵通过后再更新正式 `build`；但该替代方案也须在 #2 拆解后方可定案。
- 验证：待拆解后补充具体命令、输入输出、人工检查和可回滚证据。本轮不执行 `build_release.py`、Godot 导出、存档迁移测试或上传。
- 当前结论：Day 30 发布任务尚未达到可执行输入标准，#3 不得开工；方案师下一轮应在 #2 产出函数/批次级任务后重新覆盖本文件。

## 执行岗交接边界

- #3：本轮无 PS-EXIT 代码任务；不得为了关闭 PS-EXIT 新增功能、修改探针或把真人未测项标为通过。Day 30 发布未拆解前不得构建、覆盖 `build/` 或上传。
- #4：若无新的代码/数据提交，只维护 TEST_REPORT 摘要；不扩大回归套件，不把主观试玩结果写成机器 PASS/FAIL。
- #5：优先完成 PS-EXIT/E-0 真人完整局，并逐项记录五组结果；发现客观缺陷先交反馈岗和 #2，不现场改码。
- 主窗口：按小批次承接 F1-E；不与 PS-EXIT 或 Day 30 发布出口混为一项。
- #2：先补 Day 30 发布的批次级任务与验收输入；拆解完成后再由方案师确定文件、命令、回滚点和验证矩阵。

## 未解决开放项

- 等待 #2 拆解 Day 30 发布三批次：构建前检查与版本冻结、导出与存档兼容矩阵、`build` 产物校验与上传。
- PS-EXIT 五组真人体验：多技能位、位移走位、技能遗物掉落、章节节奏、剑士剑气。
- E-0 终审完整局及 F-16~F-39 全链真人回归；均为主观项，不阻塞机器侧。
- F-37 G 系列 UI、F-39 节点选择、MainMenu 主场景：待真人确认；确定功能缺陷另建反馈任务。
- F1-E 表现配置抽表：阶段 F 唯一客观尾项，由主窗口承接，本轮不实施。
- AI 美术在途目录与提交整理：非本岗范围，仅转述，不纳入本方案实现任务。

## 本轮结论

**等待任务拆解。** 当前没有可由方案师安全转交执行岗的 Day 30 发布代码任务；PS-D 已收口，PS-EXIT 只等待真人记录，F1-E 由主窗口承接。除本方案文档和 `TASKS.md` 标注外，不产生游戏文件改动。

## 执行结果

**执行结果：部分（等待方案）**：本轮已按精简岗纪律读取方案、TASKS 头部/相关任务段、PLAYTEST 未解决区及 PROGRESS/TEST_REPORT 顶部摘要。SOLUTION_PLAN 明确要求等待 #2 将 Day 30 发布准备拆为可执行批次；当前无覆盖方案的新增机器可验证 P0，也无可执行代码/数据任务。因此未修改游戏文件、未运行探针或导出、未改动任务状态、未提交或推送代码。

**执行结果（2026-08-17 21:1x · 第 52 轮 #3）**：**部分（等待方案）**。已复核方案与台账：① 方案第 26 轮仍为「等待任务拆解」，其任务 4 自述「方案师下一轮应在 #2 产出函数/批次级任务后重新覆盖本文件」；② **TASKS.md 第 50 轮（15:15 · #2）已完成 Day 30 三批次函数级拆解（D30-T1 构建前检查/版本冻结、D30-T2 Steam 导出与存档兼容矩阵、D30-T3 build 产物校验与上传 + D30-EXIT）**；③ **#2 第 51 轮（21:08 · f94cdca）进一步确认「Day 30 已拆待执行」**——门禁工具实测在位（tools/qa_validate.py / build_release.py / excel_export.py / export_presets.cfg 均存在），明确「交 #3 按 D30-T1→T2→T3→EXIT 直接执行（版本冻结 → 临时目录导出 → 产物校验 → Owner 确认后上传）」，并指示「若仍未开工：维持『已拆待执行』，按 D30 拆解直接执行勿再等」；④ 方案师尚未按 #2 拆解产出重新覆盖本文件 → **执行输入存在文档间信息差**（方案第 26 轮「不得开工」 vs #2 第 50/51 轮「直接执行」）。按纪律 0（执行依据 = 本文件，内容为「等待任务拆解」→ 输出等待方案）+ 红线「不擅自改方案」，本轮不越权开工 Day 30 发布链（涉及导出/上传等不可逆动作），零代码/零数据/零探针改动；未改动 TASKS 任务状态。**待办：方案师下一轮将本文件覆盖为「Day 30 已拆解可执行」或明确授权按 TASKS 第 50 轮拆解执行**，届时 #3 从 D30-T1 起直接执行（发布护栏：先临时目录导出、不覆盖现有 build/、上传需 Owner 确认）。转述 #2 顺手项：TEST_REPORT #51 观察「HUD 待补 se_skill_sword_arc 图标映射」（PS-C 剑气替换表现收尾）待方案覆盖后随批执行。

**执行结果（2026-08-17 23:1x · 第 53 轮 #3）**：**完成（本地部分 · 核实确认轮）**。总指挥第 27 轮方案（本文件头部）已覆盖 Day 30 发布链并将本地可执行部分全部落地（commit `285dc9e`），本轮 #3 为核实确认轮，产出如下：

1. **总指挥成果核实（trust but verify 全通过）**：
   - 临时导出目录 `%TEMP%\star_echo_release_20260817_2210\` 三件产物在盘且大小与方案记录逐字节一致（exe 132,918,392B / pck 1,836,016B / zip 59,061,343B）+ export_log×2 + release_manifest.json。
   - manifest 关键字段核对：version 0.9.0-d30-preview、frozen_commit=`70382e5`、godot 4.3.stable、main_scene MainMenu.tscn、preset Windows Desktop、三件 sha16 与方案一致、compat_matrix 14/14 PASS、gates 三连 PASS、**upload=PENDING 等待 Owner 明确确认与目标资产库**。
   - 打包卫生 2 修复已入库：export_presets.cfg exclude_filter=`addons/**, docs/**, tools/**, .godot/**`（`**` 跨目录，`285dc9e` 内）；`0815立绘风格、画风示例/.gdignore` 已建且已 git 跟踪。
   - `tools/day30_save_compat_check.gd` 已入库（git ls-files 命中）。
   - TASKS.md Day 30 区状态：D30-T1/T2 全 [x]、T3 剩「上传」[ ]（外部动作正确保留）、EXIT 剩 [~]/[ ] 均为 Owner 依赖项，台账状态合理。
2. **本轮动作**：
   - P0 检查：PLAYTEST 追踪区增量 #72（22:05 · 反馈专员）确认 🟠/🔴 无新增机器可验证 P0（F-01~F-39 全 🟢 待真人回归），无用户拍板调度指令。
   - 数据管线护栏：`python tools/excel_export.py --check-only` EXIT=0、13 文件导出完成，git 无 data 文件 diff = 数据层干净。
   - **顺手项评估（登记不实施）**：TEST_REPORT #51 观察「HUD 待补 se_skill_sword_arc 图标映射」——实测 `scripts/ui/hud.gd` SKILL_ICON_MAP 仍 4 键无 `se_skill_sword_arc`（剑士剑气爆发 PS-C4 无图标映射，旧日志 `regr_day2_hero_check_err.log` 有 WARNING 佐证）。**本轮不实施**，理由：① 方案第 27 轮（最新覆盖）未列此项，纪律 3 禁擅自改方案；② 改动牵动发布冻结链（改 hud.gd/skills.png → 需重导出 → 与 manifest frozen_commit 不一致），发布窗口内动代码会污染冻结基线；③ #2 转述为「顺手补」非硬性任务。**登记建议**：随「发布后第一轮迭代」或在 PS-D 总收口（PS-EXIT 真人记录后）时由方案师排期补 SKILL_ICON_MAP 键 + skills.png 第 5 帧占位图标。
3. **状态差异登记（重要）**：当前 HEAD=`44c4c34` ≠ manifest frozen_commit=`70382e5`——用户会话在冻结后追加了 3 提交（`31d03b8` PS 大包/`3460916` 立绘实装/`44c4c34` Day31 checkpoint），**导出的 exe/pck 不含这些最新内容**。若 Owner 要求发布产物包含用户会话内容，需重新冻结+重导出（届时 #3 按同一 D30-T2 流程重做）；否则以 `70382e5` 为发布基线。
4. **待 Owner（本岗不越权）**：① 上传目标资产库确认 + 上传动作 ② `build/` 替换（保留旧 build 回退副本）③ D30-EXIT 收口标记。TEST_REPORT 发布验证摘要由 #4 下轮落盘。
5. **收尾**：仅提交本文件执行结果记录；工作区唯一在途 `tools/day31_boss_fullpath_probe.gd`（用户会话，commit `44c4c34` 已注明「工作区在途为用户会话，仅建检查点不卷入」）按纪律不碰。

**执行结果（2026-08-18 01:2x · 第 54 轮 #3）**：**完成（探针锚点同步 · TEST_REPORT #53 action item 兑现）**。本轮按 TEST_REPORT #53（00:49）在途 action item 执行——**同步 9 个旧探针锚点恢复 52/52**，产出如下：

1. **P0 检查**：PLAYTEST 追踪区增量 #75（00:4x · 反馈专员）用户双反馈「关卡结束机制 + Boss 后不能选关」已由 `3f9dbe4` 修复落地 + 真实 GUI 探针 day31_boss_after_check 6/6，无新增机器可验证 P0 / 用户拍板调度指令。
2. **orbit → 扇形挥砍锚点同步（6 探针 15 条）**：PS 大包 `31d03b8` 星刃从 orbit 环绕重构为扇形挥砍（arc_angle 100→135° 递增 / 进化 150°），旧探针仍断言已清零的 orbit 数据 → 全部改为新语义：
   - `day5_weapon_check`（3 条）：OrbitWeapon 挂载/刃数/bonus 埋点 → MeleeSweep 挂载 + arc_angle≥100 + `_do_slash` 扇形伤害精确断言（踩坑：headless 下 `_get_aim_direction` 指向左上 → 敌人须摆瞄准方向；crit 波动 → 临时禁暴击 + 计入 melee_damage 8%）
   - `day8_weapon_data_check`（1 条）：Lv8 blade_count 4 → arc_angle 135
   - `day10_evolution_check`（2 条）：storm orbit_data.blade_count 6 → arc_angle 150；Lv8 blade_count → arc_angle 135
   - `day18_feedback2_check`（6 条）：§2 半径 40→68 递增 → 扇形角 100→135 递增 + 武器资源 arc_angle 落地
   - `day18_feedback4_check`（2 条）：storm blade_count 6 → arc_angle 150；F-22 渲染 orbit_weapon 手动实例 → melee_sweep 刀光颜色/扇形角断言（含 Object.get() 1 参坑修复）
   - `day18_feedback5_check`（1 条）：tooltip「环绕玩家旋转」→「周期性扇形挥砍」
3. **换装尺寸锚点同步（3 探针 4 条）**：8-16 定稿换装 walk 192×32/640×64 → 256×64·4 帧、idle → 768×64·12 帧（08-18 呼吸动画定稿）：
   - `day21_22_art_check`（1 条）：§3 4 角色 walk 256×64·4 帧 + idle 768×64·12 帧
   - `day26_integration_check`（1 条）：角色 walk 统一 256×64
   - `day29_elin_anim_check`（2 条）：SHEET_EXPECT idle 768×64·12 / walk/attack/skill 256×64·4 + §4 文本锚点同步
4. **验证**：9 探针单独全 CLEAN（day18_fb4 18/18、day29_elin 14/14、day5 16/16）；**全量回归 52/52 PASS**（回归前 43/52）；`excel_export.py --check-only` EXIT=0 数据层干净。
5. **收尾**：提交 9 探针 + 挂账 docs（PROGRESS/TEST_REPORT/GameData.xlsx/DATA_OVERVIEW/.manifest.json 为 #1/#4 导出与进度挂账一并入库）+ push；`.godot_bak×2` 用户会话缓存目录不提交不删除（建议下轮补 .gitignore 条目）。**顺手项维持登记**：HUD `se_skill_sword_arc` 图标映射仍待方案师排期（发布冻结窗口内不动代码的结论延续）。

**执行结果（2026-08-18 03:3x · 第 55 轮 #3）**：**完成（TEST_REPORT #54 观察项兑现 · 回归扩容 52→58 件套）**。本轮无新方案任务（第 27 轮方案剩余 = Owner/#4 域），实质动作 = 兑现 TEST_REPORT #54（02:49）观察「day31 五新探针（90 断言）未入 runner 建议 #3 并入」：

1. **P0 检查**：PLAYTEST 追踪区增量 #76（02:0x）确认 🔴 P0 无新增 / 🟠 无用户拍板调度指令 → 无新机器可验证 P0 需执行；F-40~F-43 均 🟢 已修复/落地待真人回归。
2. **6 个 day31 出口探针并入 runner**（`tools/_regression_run.py` PROBES +6 → 58 件套）：day31_boss_after(6) / charsel(12) / enemy_richness(5) / melee_sweep(9) / player_model(6) / items_atlas(58)（合计 96 = TEST_REPORT #54「五新探针 90 断言」+ player_model 6）。**扩展 run_one 断言解析**兼容三种汇总格式（"N assertions, M failures" / "N checked, M failed" / "检查 N 项，失败 M 项"），新探针断言计数真正生效。
3. **回归首跑 56/58 两 FAIL 定位修复**：
   - `day31_melee_sweep_check` §4 flaky：`melee_sweep._do_slash` 内 `randf()<crit_chance` 走全局 RNG，精确数值断言偶发暴击（14→28，7×2倍率×2暴击；同 day5 先例）→ 探针 §4 前白盒置 `crit_chance=0 / crit_damage=1`；连跑 3 次 9/9 稳定。
   - `day26_integration_check` §6 锚点过期：动态解析 runner PROBES 的硬编码期望 52 项/1099 → 同步 58 项/1195（含注释增量账）。
4. **验证**：全量回归 **58/58 PASS 0 FAIL**；`excel_export.py --check-only` EXIT=0 数据层干净（本轮零数据改动）。
5. **顺手收尾**：`.gitignore` 补 `.godot_bak*/` 排除（第 54 轮登记的观察点③，用户会话缓存目录勿提交勿删除）；probe 类 3 探针（boss_chain/flow/fullpath）维持不入 runner（一次性诊断探针，退出码语义，fullpath 打 15 关耗时）。
6. **维持登记**：HUD `se_skill_sword_arc` 图标映射仍待方案师排期（发布冻结窗口不动代码）；D30 剩余 = Owner 上传确认 + build/ 替换 + EXIT 收口；AUDIO_FEEL O-1~3 待用户拍板（#2 拍板后拆 P0 批）；F1-E 主窗口承接。

**执行结果（2026-08-18 05:4x · 第 56 轮 #3）**：**完成（F1-E 第二批 BEHAVIOR_MAP 抽表 · 回归 60/60 全绿）**。本轮方案 = 总指挥第 4 轮「后续批次（F1-E 剩余）· BEHAVIOR_MAP」，实质动作 = 回归确认（总指挥遗留项）+ 第二批抽表闭环：

1. **P0 检查**：PLAYTEST 追踪区增量 #77（03:5x）确认 🔴 P0 无新增 / 🟠 无用户拍板调度指令 → 无新机器可验证 P0 需执行。
2. **回归确认（总指挥第 4 轮遗留「全量回归后台跑，结果待本轮收尾确认；FAIL 则回退不硬合」）**：全量回归 **60/60 PASS**（1463 断言，含新并入 day31_presentation_check 246 + day31_skill_icon_check 22）→ **无需回退**。
3. **F1-E 第二批 BEHAVIOR_MAP 抽表闭环**：Excel `enemy_behavior` sheet（9 行：chase/charge/zigzag/ranged/heal/spawn/stationary/aoe_attack/self_heal → 枚举名 CHASE 等）→ `data_schema.py` 注册（COLUMN_ZH behavior=行为枚举 + SHEETS enemy_behavior root=behavior_map kind=dict）→ `excel_export.py` 构建段 → `data/presentation.json` 新增 `behavior_map` 9 条（**其余 13 JSON 零 diff**）→ `data_loader.gd` 新增 `get_enemy_behavior()`（懒加载 is_empty 重试标记 + `EnemyEnums.Behavior.get(枚举名)` 解析 + const BEHAVIOR_MAP 全量兜底 CHASE）→ `enemy.gd:371` 行为解析改读数据层（原 BEHAVIOR_MAP.get 兜底语义不变）。
4. **验证**：探针 day31_presentation_check **261/261 PASS**（+15 断言：条数一致/键集合双向/逐条枚举值对比/消费 3 项含未知行为兜底 CHASE）；全量回归 **60/60 PASS**；`excel_export.py --check-only` EXIT=0。
5. **收尾**：检查点 `b515e17`（挂账 docs #1/#4 在途一并入库）→ 批次 commit → push。
6. **维持登记**：F1-E 剩余批次 = BGM/SFX → FX → SHEET_CONFIG → 初始武器 → 炮台默认（每批 Excel→导出→消费→探针→回归，const 兜底）；D30 剩余 = Owner 上传确认 + build/ 替换 + EXIT 收口；AUDIO_FEEL O-1~3 已由总指挥拍板（M1+M2/近重远轻/H1 挂 P2）待 #2 拆 P0 批；PS-EXIT 五组真人观察待 #5。
