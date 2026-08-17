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
