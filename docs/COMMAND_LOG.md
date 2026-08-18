# 总指挥决策日志（COMMAND_LOG）

> 由 **RS-总指挥（进度推动者）** 维护：每轮把全部自主决策 + 自主执行追加写入本文件（时间戳 + 决策内容 + 理由 + 动作 + 结果）。
> 纪律：不删除文件；不做外部世界动作；不推翻用户已拍板决策。用户未表态事项 → 总指挥自主拍板先干。
> 本文件是总指挥决策的单一事实源，供 #1/#2/#3 引用；追加不覆盖。

---

## 2026-08-17 22:1x · 第 1 轮

### 决策 D-001：Day 30 发布三批次按 #2 拆解直接执行（本地部分）

- **内容**：结束「方案等待拆解 vs #2 已拆待执行」信息差——按 #2 第 50/51 轮 D30-T1/T2/T3/EXIT 函数级拆解直接落地；**上传与 build/ 替换属外部动作，留 Owner 明确确认**。
- **理由**：用户 08-17 授权总指挥对未表态事项自主拍板；#2 已连拆两轮并明确「直接执行勿再等」；方案第 26 轮「不得开工」系未随 #2 拆解刷新的文档滞后；D30 拆解自带完整护栏（临时目录导出、不覆盖 build/、不删真实档、不写上传凭据）。
- **动作**：全流程执行见 D-002。
- **结果**：✅ 落地，D30-T1/T2/T3 本地部分全 [x]，D30-EXIT/T3 上传保持 [ ] 待 Owner。

### 决策 D-002：修复发布打包卫生问题（2 处）

- **内容**：① `export_presets.cfg` exclude_filter 由 `addons/*, docs/*, tools/*` 改为 `addons/**, docs/**, tools/**, .godot/**`——`*` 在 Godot glob 中不跨目录，addons/godot_mcp 脚本与部分缓存曾被打进 pck；② `0815立绘风格、画风示例/` 用户 AI 参考图目录补 `.gdignore`（21 个 webp 曾被打包，与 测试立绘/星骸回响_AI美术资产_v2 目录口径对齐）。
- **理由**：D30-T3 资产清单校验要求「不将 ART/RAW 输入区或无关目录纳入产物」；发布包含用户参考图与编辑器插件属于打包卫生缺陷，发布前必须修。
- **动作**：编辑 export_presets.cfg + touch .gdignore + 重新导出验证（复导出清单 400 文件全为游戏资源：scripts 134 / assets 99 / scenes 25 / data 15 + .godot 导入缓存 124）。
- **结果**：✅ pck 36.8MB → 1.8MB（排除 21 张高清立绘 webp 缓存），产物启动 EXIT 0 无 script_error。

### 决策 D-003：存档兼容矩阵以独立探针固化

- **内容**：新增 `tools/day30_save_compat_check.gd`（extends SceneTree 范式，沿用 day27_meta_check），覆盖 D30-T2 兼容矩阵五类：新档启动 / 旧档缺 skill_slots / 旧档缺 skill_points / 旧档缺 chapters（route 数据层）/ 损坏+空存档；独立临时档 `user://test_save_compat_d30.json` 隔离，测试后清理。
- **理由**：D30-T2 验收要求「每项验证启动不崩、字段自动补默认、失败不污染真实档」——需要机器可验证证据，且探针入库后可回归复用。
- **动作**：编写 + headless 运行。
- **结果**：✅ **14/14 PASS**（损坏/空档 JSON parse ERROR 为 push_warning 预期输出，非失败）。

### 决策 D-004：build_release.py 硬编码 build/ 输出的处理

- **内容**：build_release.py 存在但硬编码输出到 `build/`，与「不覆盖 build/」冲突 → 不运行该脚本，改用等价 Godot 原生命令 `--export-pack "Windows Desktop" <tmp>/RoguelikeStudio.pck` + 同法 zip + headless 启动检查，产出与 manifest 一致。
- **理由**：D30-T2 拆解明确「先导出到全新临时目录，不得直接覆盖 build/」；脚本参数与任务护栏冲突时以护栏为准，登记说明而非臆造替代命令。
- **结果**：✅ 临时目录产物 + manifest 生成，build/ 未触碰。

### 执行记录（本轮动作链）

1. 22:08 读全运行文档（PROGRESS/TEST_REPORT 摘要、TASKS 头部+Day30 区、SOLUTION_PLAN 全文、PLAYTEST 未解决区、LOOP_HEALTH）。
2. 22:10 岗位健康巡检：automation list = 7/7 全 ACTIVE（总指挥/反馈专员/方案执行/方案确定/自动化测试/任务拆解/进度分析），无 PAUSED。
3. 22:10-22:12 门禁三连：baseline_check BASELINE CLEAN / qa_validate DATA LAYER CLEAN / excel_export OK（13 JSON 与 manifest 哈希全一致）。
4. 22:12-22:20 临时目录导出 exe/pck/zip + 启动检查 + 打包卫生修复 + 复导出验证 + manifest 落盘。
5. 22:20 台账落档：TASKS.md D30 区逐条打勾/标注；SOLUTION_PLAN.md 覆盖第 27 轮含决策段；本文件创建。
6. git commit + push（提交号见 git log）。

### 遗留给 Owner（唯一需真人拍板项）

- **D30-T3 上传 + D30-EXIT 收口**：目标资产库/上传方式需 Owner 明确确认后执行；临时产物保留在 `%TEMP%\star_echo_release_20260817_2210\`（含 release_manifest.json），确认后复制到 build/（保留旧 build/ 回退副本）并上传。
- 主观回归面维持：E-0 终审完整局 / PS-EXIT 五组 / F-16~F-39 真人回归（#5 职责，不阻塞机器侧）。

---

## 2026-08-17 22:5x · 第 2 轮（用户反馈跟进：打完第一个 Boss 进不了关）

### 决策 D-005：用户反馈「打完第一个 Boss 后进不了关」——先机器侧全路径复现再定性

- **内容**：用户 22:21 反馈完整局审不了：打完第一个 Boss 进不了关；并问 D30 上传/收口是什么（答：发布打包动作，与游戏本身无关，见日报）。总指挥立即跟进——不猜、不复述，用全路径探针从第 1 关真实打到 15 关复现。
- **动作**：
  1. 排查 Boss 链路（boss_layers=[6,10,14] 0-based = 章 2/3/4 末层 = 1-based 第 7/11/15 关；wave 10=boss:invoker 持续生成；`_on_node_completed` Boss 后直进 ROUTE_SELECT 不弹商店——逻辑正确）。
  2. 既有 v2 探针（快进层 6）PASS → 但快进绕过了第 1-5 关真实路径 → 写 **v3 全路径探针** `tools/day31_boss_fullpath_probe.gd`：从层 0 逐层真实推进（event=resolve / shop=close / battle=清敌判通 / boss=击杀），自动处理升级面板暂停恢复，真死锁判定（BATTLE 下 queue 30s 未缩减）。
  3. 踩坑两处修复：① 探针自身 `Object.get("_spawn_timer", -1.0)` 两参会 SCRIPT ERROR → 相位回 0 → 假「场景重开」误判；② 升级面板弹出暂停导致 spawner 冻结的假死锁 → 自动点升级项恢复 + 非 BATTLE 状态豁免。
- **结果**：**v3 全路径探针 33 PASS / 0 FAIL**——第 1 关真实打到第 15 关，3 Boss 击杀（第 7/11/15 关），每个 Boss 后均进入 ROUTE_SELECT、路线面板可点，最终胜利结算。**最新代码（HEAD=31d03b8 用户会话大包）机器侧链路全通，「打完第一个 Boss 进不了关」未复现**。
- **结论与建议**：① 用户若玩的是 `build/` 里 08-04 旧包（无章节化/无技能系统/无三 Boss 映射，pck 146KB vs 新 1.8MB）→ 该版本旧 bug 早已在 PS-D 收口修复，**建议玩最新代码或等 D30 收口后替换 build/**；② 若玩最新代码仍复现 → 需用户提供触发细节（第几关 Boss、打完后的画面状态），补探针精确复现。**已登记 PLAYTEST 追踪区转 #5 真人确认**。

### 执行记录（第 2 轮动作链）

1. 22:21 读用户反馈 → 22:2x 排查 routes/waves/spawner/GM 链路。
2. 跑 v2 快进探针（PASS）→ 判断需全路径验证 → 写 v3。
3. v3 迭代 4 版（断言公式 / get 两参 SCRIPT ERROR / 升级暂停假死锁 / 非 BATTLE 豁免），最终 33 PASS / 0 FAIL 稳定。
4. 提交 `f27f3d3`（探针入库）；COMMAND_LOG 追加本段；PLAYTEST 追踪区登记（待 #5 真人确认项）。
5. 未推送（等与 TASKS/PLAYTEST 更新一起，或下轮收尾）。

---

## 2026-08-18 01:1x · 第 3 轮（Owner 指令：音乐重制 + 手感/打击感优化方案，只出方案不动工）

### 决策 D-006：音频重制与手感/打击感优化 → 规格文档先行，交 #2 拆解

- **内容**：Owner 明确「音乐重新制作 + 优化手感/打击感，多提几个方案，交下面人执行，总指挥不要直接做」。总指挥按「文档先行」纪律（G 系列 08-12 教训：只写规格交 #2 拆解→#3 执行，禁止单条对话直接动工）产出 **`docs/AUDIO_FEEL_SPEC.md`**，**零代码/零资产改动**。
- **方案清单（已落档）**：
  - **音乐重制 4 方案**：M1 免费 CC0 素材替换（推荐·低风险）/ M2 程序化合成分层 BGM（chiptune 升级，与 PS-D 章节化对齐）/ M3 AI 生成（需 Owner 拍板，红线仅约束美术未约束音乐）/ M4 外包（外部动作需 Owner 全程）
  - **打击感 5 方案**：F1 hitstop 顿帧（time_scale 微停帧）/ F2 相机震屏分级（命中/暴击/死亡四级）/ F3 命中粒子+暴击数字+击杀残影（复用 D 阶段特效管线）/ F4 敌人受击僵直+抖动+击退分级（Boss 豁免）/ F5 音画同步（命中音零延迟+暴击/击杀分层）
  - **手感 4 方案**：H1 移动加速-摩擦曲线+转向插值 / H2 自动射击命中反馈 / H3 技能释放前摇+微顿+专属音 / H4 攻速移速非线性档位（走 Excel 管线）
- **分批建议**：P0 = F1+F2+F5（打击感三支柱）；P1 = M1 素材 + F3 粒子；P2 = F4 僵直 + H1/H3 手感；P3 = M2 章节 BGM。
- **红线**：audio_manager 键名契约（SFX_MAP/BGM_MAP 只追加不删改，探针锚点）；time_scale 必须带恢复护栏（防 600 帧深探挂死）；Boss 豁免僵直/击退；数值走 Excel 管线；CC0 素材从 GitHub 生态采集并标注来源；每批验收 = 探针 + baseline + #5 真人主观项。
- **开放决策项（交 Owner）**：O-1 音乐选型（建议 M1+M2）/ O-2 hitstop 档位是否按武器系调整 / O-3 H1 移动曲线接受度。
- **动作**：写 `docs/AUDIO_FEEL_SPEC.md`（唯一事实源）；COMMAND_LOG 记录；git 提交（仅文档）。**未动任何 .gd/.tscn/.wav/.json**。
- **结果**：方案就绪，待 #2 按 P0→P1 拆解（#2 下轮 :05 窗口自动读取 TASKS/方案文档）；#3 未拆解前禁动工。

---

## 2026-08-18 04:5x · 第 4 轮（自动化第 2 轮 · F1-E 承接动工 + AUDIO_FEEL 拍板 + HUD 图标补丁）

### 决策 D-007：AUDIO_FEEL_SPEC O-1~3 总指挥自主拍板（用户未表态项，08-17 授权内）

- **O-1 音乐选型 = M1（免费 CC0 素材）先行 + M2（程序合成）并行长期**；M3 AI 生成 / M4 外包挂起留 Owner（M3 需外部工具账号、M4 涉及付款 = 外部动作，红线内）。
  - 理由一行：M1 从 GitHub 生态采集 CC0 曲目零成本零外部动作（08-07「网上素材随意用」先例），M2 与 PS-D 章节化对齐长期复用。
- **O-2 hitstop 档位 = 按武器系调整**（近战重 0.15s / 远程轻 0.05s），落地走 Excel 管线（F1-E 批次内）。
  - 理由一行：近战命中感密度低，重顿帧补偿；远程高频，轻顿帧防节奏碎裂——均为档位数据非结构改动。
- **O-3 H1 移动曲线 = 接受但降级实施**：H1 挂 P2 批（本轮不动曲线，避免体感回归面影响发布基线），先行 H2 命中反馈 / H3 技能前摇 / H4 数值档位。
  - 理由一行：H1 牵动全角色移动手感（体感回归面最大），发布窗口内优先级让位于 F1/F2/F5 打击感三支柱。
- **动作**：更新 `docs/AUDIO_FEEL_SPEC.md` 开放决策段（O-1~3 标注总指挥拍板结论）；#2 下轮可据此拆 P0 批。

### 决策 D-008：F1-E 表现配置抽表 = 总指挥直接承接（主窗口长期未动，阶段 F 唯一 [ ] 不再挂账）

- **内容**：F1-E（T-016~024）原定「主窗口承接」，但主窗口（用户会话）长期无动作；总指挥按 08-17 授权承接，按既定顺序分批落地。
- **第一批 = enemy SPRITE_MAP 抽表闭环（本轮完成）**：
  1. `docs/GameData.xlsx` 新增 `enemy_sprites` sheet（23 敌人，双行表头，数据源自 enemy_enums.gd SPRITE_MAP 逐条抄录）
  2. `tools/data_schema.py` 注册 SHEETS（file=presentation.json, root=enemy_sprites, kind=dict）+ COLUMN_ZH 列映射
  3. `tools/excel_export.py` build_json_files 新增 presentation 构建（size_w/size_h → {"x","y"} 组装，tint JSON 列）
  4. 导出 `data/presentation.json`（23 条）——其他 13 JSON 零 diff（管线稳定）
  5. 消费端：`data_loader.gd` 新增 `get_enemy_sprite_config()`（懒加载 presentation.json；size→Vector2i、tint→Color、scale→float；未命中按 category 兜底 enemy_enums.gd const——F 系列缺省兜底约定）；`enemy.gd` `_setup_animation` 改读 DataLoader
  6. 新探针 `tools/day31_presentation_check.gd`：246 断言全绿（23 条键集合一致 + 逐条 8 字段与 const 零漂移 + DataLoader 消费 Vector2i/Color/scale/兜底全对）
- **理由一行**：发布窗口已过冻结基线（HEAD 已 +31 提交漂移），抽表不再污染冻结产物；每批保留 const 兜底零回归。
- **后续批次**：BEHAVIOR_MAP → BGM/SFX → FX → SHEET_CONFIG → 初始武器 → 炮台默认，由总指挥/主窗口按批推进。

### 决策 D-009：HUD se_skill_sword_arc 图标映射立即补（TEST_REPORT 观察项，不再等排期）

- **内容**：`hud.gd` SKILL_ICON_MAP 补 `"se_skill_sword_arc": 4`；`skills.png` 扩至 160×32（第 5 帧 32×32 纯色占位，剑气紫）；`icon_atlas.gd` skills.frame_count 4→5。
- **理由一行**：#3 第 53 轮「发布冻结窗口不动代码」的顾虑已随冻结基线漂移解除（产物已导出完毕），补丁随现 HEAD 走，Owner 若补冻则重导出即可。
- **验证**：新探针 `tools/day31_skill_icon_check.gd` 22 断言全绿（5 帧全非空 + 图集配置 + 4 技能 id 全覆盖 + 越界拦截 + sword_arc=4）。
- **踩坑记录**：skills.png 修改后 Godot import 缓存未刷新 → 探针读旧 128×32 → `--headless --import` 触发重导后 22/22 全绿；`.import` 文件已随改（提交时一并入库）。

### 本轮执行链

1. 04:5x 读全局文档（PROGRESS/TASKS/SOLUTION_PLAN/LOOP_HEALTH 精简岗口径）+ git 实测（HEAD=c442abf）+ 自动化 7/7 ACTIVE。
2. HUD 图标补丁（hud.gd + icon_atlas.gd + skills.png 5 帧）→ 探针 22/22。
3. F1-E 第一批（Excel sheet + schema + export + presentation.json + DataLoader + enemy.gd）→ 探针 246/246。
4. 两探针并入 runner（58→60 件套）；全量回归后台跑（k595ma，预计 ~1.5-2h）。
5. 探针驱动范式修正：extends SceneTree 探针必须 `_process` 首帧驱动（Autoload 挂载后 root 可见）+ 显式 `quit()`——_init 直跑会拿不到 DataLoader 且进程挂起（工作记忆「--script 探针三坑」再踩，已内化）。
6. **待回归结果**：60/60 全绿后提交（Day31-xxx 摘要）+ push；若有 FAIL → 回退对应改动。

---

## 2026-08-18 19:3x · 第 5 轮

### 决策 D-010：F1-E 第三批 BGM/SFX 抽表 = 总指挥直接动工（跨 4 轮挂账，不再等承接方）

- **内容**：F1-E-3（BGM/SFX 路径抽表，拆解 `dc6a7c1` 自 #2 第 57 轮起已跨 4 轮零开工，方案师第 27~29 轮连续挂账观察「承接方持续未开工」）——按 08-17 授权由总指挥直接落地，不再等主窗口。
- **理由一行**：阶段 F 唯一 [~] 行内最后一个数据化批次，拆解/方案/锚点三方核实一致可立即执行；每步保留 const 兜底零回归，风险低。
- **动作与结果**：全链闭环见下方执行链。

### 本轮执行链（F1-E-3 全五子任务 + EXIT）

1. **F1-E-3-1 数据侧 ✅**：`docs/GameData.xlsx` 新增 `audio_config` sheet（12 行 × id/category/path，双行表头，值逐一抄自 audio_manager.gd BGM_MAP/SFX_MAP）；`tools/data_schema.py` 注册 `audio_config`（file=presentation.json / root=audio_map / kind=dict / key=id，仿 enemy_behavior）+ COLUMN_ZH（category/path）；`tools/excel_export.py` presentation 构建段追加 audio_map 解析（id 主键 → {category, path}）；导出 `data/presentation.json` +audio_map 12 键（2 bgm + 10 sfx），**其余 13 JSON 零 diff**。
2. **F1-E-3-2 DataLoader 接口 ✅**：`data_loader.gd` 新增 `get_audio_config() -> Dictionary`（懒加载 audio_map + `_audio_map` 空表重试标记——F3 §4 禁新增 bool）；缺表/损坏 → 空字典（消费端 const 兜底零崩）。
3. **F1-E-3-3 消费改读 ✅**：`audio_manager.gd` 新增私有 `_resolve_audio_path(key, fallback)`（get_audio_config 命中 audio_map[key].path → 用之；未命中/空表 → fallback const）；`play_bgm`/`play_sfx` 路径解析改走（**BGM_MAP/SFX_MAP const 保留为兜底**）；`play_sfx_delayed` 复用 play_sfx 自动继承；未知键 push_warning 行为不变。
4. **F1-E-3-4 探针 ✅**：`day31_presentation_check.gd` +§3 audio 段 **12 断言**（12 键齐 / category 2 bgm+10 sfx / path 与 const 逐一一致零漂移 / get_audio_config 白盒 / 数据缺键回退 const / 命中优先 / 未知 SFX false + 两源均缺失空串）→ **273/273 PASS**；端到端双跑（改 Excel hit path → 导出 → audio_map 变化 → 改回 → 恢复零残留）PASS；day24_audio_check **14/14 零改动**（硬门槛）。
5. **EXIT 收口 ✅**：全量回归 **61/61（1504 断言）** + baseline **BASELINE CLEAN**；TASKS F1-E-3-1~4+EXIT 全 [x] + F1-E 行 3/7 批；TECH_DEBT_ISSUES T-016/017/018 转已收口（三批全闭环，前两批台账滞后一并修正）；SOLUTION_PLAN 决策段本段。
6. **调度健康 ✅**：automation_update list = 7/7 岗位全部 ACTIVE，无 PAUSED 无异常。
7. 收尾：git commit（Day31-F1-E3-BGM/SFX 抽表收口）+ push。

### 遗留（维持）

- F1-E 剩余批次：**FX → SHEET_CONFIG → 初始武器 → 炮台默认**（总指挥/主窗口按批推进）。
- 待 Owner：D30-T3 上传 + build/ 替换 + D30-EXIT（外部动作）；E-0/PS-EXIT/AF-P0 真人回归（主观项）；AF-M1 CC0 采集（网络依赖）。
