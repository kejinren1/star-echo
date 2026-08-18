# 方案计划（2026-08-18 13:3x · 方案师第 28 轮 · 无新任务需方案 · 状态与第 27 轮一致，F1-E 批三仍待开工观察）

## 📌 本轮判定（方案师第 28 轮）

> **P0 检查（PLAYTEST 追踪区增量 #80 · 08-18 13:3x 反馈专员）**：无待处理反馈（F-01~F-43/AF-P0 全 🟢 已修复·待真人回归；🟡 仅 H-05 家族主观审阅域）；TEST_REPORT #58（12:45 · HEAD=`dc6a7c1`）= **61/61 全绿 · 1489 断言 · BASELINE CLEAN · 0 阻断 / 0 功能缺陷 / 0 action item**（空轮次：HEAD 无新游戏提交，计数与 #57 持平）→ **🔴P0 无新增 / 🟠 无用户拍板调度指令 → 无新机器可验证 P0 需拆。**
>
> **git 实测**：HEAD=`d45ad36`（反馈专员 #80，08-18 13:3x；#79 `f7c6445` 后 +3：`dc6a7c1` #2 第 57 轮 F1-E-3 拆解 / `bd9ad83` 执行者第 58 轮核实 / `6e200b3` #1 进度第 62 轮 / `d45ad36` 增量 #80）；**工作区 CLEAN 零在途**。
>
> **结论：无新任务需方案化。** 与方案师第 27 轮判定完全一致（三方： #2 第 57 轮拆解 + 方案师第 27 轮锚定 + 执行者第 58 轮核实，状态零变化）：当前目标日 Day 30 剩余客观项 = 纯 Owner/#4 域（上传/发布收口）无需方案；F1-E 第三批 BGM/SFX（F1-E-3-1~4 + EXIT）已函数级拆解 + 方案锚定，**本轮观察：git log 仍无 audio_config sheet / audio_map / get_audio_config / day31_presentation_check +§3 提交 → 批三尚未开工，仍待 🏠 主窗口/总指挥承接**。

## 当前开发日：Day 30（发布准备 · 收尾）

### 任务1：F1-E 第三批 BGM/SFX 表现抽表（F1-E-3-1~4 + EXIT）——方案已锚定（第 27 轮），本轮维持，待承接方开工

- **现状**：拆解就绪（#2 第 57 轮 `dc6a7c1`）+ 方案锚定（方案师第 27 轮实测复核锚点一致）+ 核实一致（执行者第 58 轮 `bd9ad83`）；**git 实测确认批三零开工**（HEAD 无 audio_config/audio_map/get_audio_config 相关提交）。
- **锚点**（不变）：`audio_manager.gd:8-11` BGM_MAP（2 键）/ `:12-23` SFX_MAP（10 键）/ `:112-114` `:138-140` push_warning / `:155` play_sfx_delayed；`data_schema.py:218-231` 注册范式；`excel_export.py:399-423` presentation 构建段；`docs/GameData.xlsx` 新建 `audio_config` sheet（12 行 × id/category/path）；`day31_presentation_check` +§3 audio 段（≥12 断言）。
- **改动**（沿用第 26/27 轮范式，勿重复拆）：Excel → 导出 → `get_audio_config()` 消费 → const 兜底 → 探针 → 回归 61 件套。
- **风险**：**低**。双硬门槛不变：① `day24_audio_check` 14/14 §2 配置层断言（BGM_MAP 2 键 + SFX_MAP 10 类）→ const 保留兜底即零改动；② AUDIO_FEEL 红线 2（SFX_MAP 键契约零新增零删改）→ 仅路径来源数据化。
- **验证**：`day31_presentation_check` ≥273（261+12）+ `day24_audio_check` 14/14 零改动 + 回归 61 件套 1489 断言 + baseline **BASELINE CLEAN** + 端到端双跑（改 Excel 一例路径 → 导出 → get_audio_config 变化）。
- **承接**：🏠 主窗口/总指挥按批推进（每任务一收口 commit 带 F1-E-3 编号）。**本轮观察 = 仍未开工，持续挂账观察项**。

### 任务2：D30-T3 上传 + D30-EXIT 发布收口——纯 Owner/#4 域，无需方案

- **改动**：无（本岗红线：外部动作 + 测试岗产出，方案师不写执行方案）。
  - D30-T3 上传 [ ] = 外部动作，等 Owner 明确确认（目标资产库 + build/ 替换 + 冻结 HEAD 补冻与否）；本地部分（冻结/门禁/导出/manifest）总指挥第 1 轮已 ✅ 落地
  - D30-EXIT [~]/[ ] = TEST_REPORT 发布摘要待 #4 落盘 + build/ 替换 + 最终标记
- **风险**：低（无机器侧开发任务；build/ 08-18 00:13/00:14 产物仍早于 `3f9dbe4`/`defe1cf` 的交办观察维持，交 Owner/总指挥核实）。
- **验证**：Owner 确认后由 #3/#4 收口，回归 61 件套 + baseline CLEAN 为发布门禁口径。

### 任务3：AF-M1（CC0 音乐替换 · P1 已拍板）——待执行，网络依赖登记维持

- **改动**：无（总指挥采集 GitHub 生态或登记阻塞；M1 替换 = assets/audio 文件名不变零代码改动）。
- **风险**：低（不阻塞 P0；网络依赖）。
- **验证**：替换后 day24_audio_check 14/14 零改动 + 回归 61 件套。

### 风险总表（本轮）

| 任务 | 风险 | 说明 / 替代方案 |
|---|---|---|
| F1-E-3 BGM/SFX 抽表 | 低 | day24_audio 14/14 + AUDIO_FEEL 红线 2 双硬门槛；const 兜底防空表崩；替代方案 = 回退仅保留 const（现状即等价）；**唯一风险 = 承接方持续未开工（挂账观察）** |
| D30-T3/EXIT | 低 | 外部动作等 Owner；无替代方案（权限边界） |
| AF-M1 | 低 | 网络依赖；登记阻塞不阻塞 P0 |

### 维持已定方案边界（不重复写）

- **F1-E 批四~七**（FX → SHEET_CONFIG → 初始武器 → 炮台默认）：沿第 26/27 轮范式 + 各批先例（SPRITE_MAP/BEHAVIOR_MAP/F1-E-3）推进，承接方开工时按需拆解。
- **PS-EXIT / E-0 终审完整局 / AF-P0 主观回归**：交 #5 真人（主观项不阻塞机器侧）。
- **F-16~F-43 真人回归 / MainMenu 待真人确认 / Day 28 性能段 / 章节 Boss 映射（已拍板三 Boss [6,10,14]）**：开放项清单维持（见 PLAYTEST 追踪区）。

## 🔴 红线遵守（本轮）

不写代码、不改 `.gd/.tscn/.tres/.json` 游戏文件、不 git commit、不跑探针。仅覆盖写 `docs/SOLUTION_PLAN.md` + 在 `docs/TASKS.md` 对应任务旁补「方案已定（SOLUTION_PLAN.md 第 28 轮）」标注。工作区 CLEAN 零在途。

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
