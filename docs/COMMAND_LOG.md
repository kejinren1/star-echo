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
