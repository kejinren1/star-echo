# 方案计划（2026-08-08 · 第 7 轮）

## 当前开发日：Day 26（整合校验 · 阶段 D 收口日 · 纯校验零新功能）

### 0) P0 调度硬性输入检查（读 PLAYTEST_CHECKLIST 追踪区头部 · 本轮实测 01:50）

- ✅ **增量 #41（01:5x · #5 标记岗）**：TEST_REPORT #30 = Day 23 占位特效 + F-20 进化保底 + H-01 升级冲击波正式覆盖（二十一件套 568 断言）；**Day 24 已收口（`e748d8e` @ 00:43 = TASKS Day24 区 47 处 [x]）**，实现链 7 提交齐全（gen_audio 12 WAV / audio_manager 第 3 Autoload / SFX 10 消费点 / day24_audio 14/14 / F-13 三机制 / day24_f13 17/17）。F-13 / T-D / F-20 / F-21 行全部 🟢 已落地 · 待真人回归（主观项）。
- 🚨 **美术资源策略（2026-08-07 21:1x 拍板 · 硬性）**：不再生成美术资源；缺口一律占位纯色图；**D26 整合校验主观项（视觉/听觉观感）全部交 #5，不阻塞出口**。
- **P0 检查结论：无新机器可验证 P0 需纳入本轮**（P0 四件套 + P1 四修复 + 反馈专员六件套 + T-C/T-D/F-13/F-19/F-20/F-21 全部闭环或已落地，剩余动作 = 真人回归主观项）。本轮为阶段 D 收口校验，无功能开发。

### 目标日客观状态（本轮实测 01:50）

- git HEAD = `135be10`（反馈专员 #40 docs @ 01:0x）；Day 24 收口提交 `e748d8e` 在链。工作区在途仅 3 docs M（DAY_ROLE_ASSIGNMENTS / PLAYTEST_CHECKLIST / TASKS）**零游戏代码改动**。
- **D26 区任务状态**：T1~T3 + EXIT 全 [ ]，函数级预拆就绪（#2 第 22 轮 07:1x + 第 31 轮 00:5x 更新），**#3 下一窗口 03:35 可直接执行，无需重拆**。
- **阶段 D 前序日全部收口**：D21-22 美术 `c091b73` / D23 特效 `f5cd533` / D24 音频+F-13 `e748d8e` / D25 剧情（LORE.md 14075B 在盘预交付，剩接线归 Day 27）→ **探针降级口径不再触发，§1~§4 全量断言**。
- 回归基准：24 件套 **609 断言**（day24 收口实际值；含 day24_f13 17 + day24_audio 14）→ Day 26 落地后 = **25 件套 ≥629 断言**（+day26_integration ≥20，以探针实际输出为准）。

### 本轮实测锚点（供 #3 免排查 · 2026-08-08 01:50 磁盘实测）

| 项 | 现行位置 | 说明 |
|---|---|---|
| enemy.gd SPRITE_MAP | `scripts/enemy/enemy.gd` :76 起 | **23 键**（chaser→predator 实测，含 invoker/predator；FALLBACK :101-104） |
| enemy.gd is_boss | :56 | Boss 判定字段 |
| **Boss scale 复位锚点** | **enemy.gd :872** `scale = Vector2(1.0, 1.0)` | D21-22 复位（D17 决策）；day18_19 探针 :194 断言同步 1.0 |
| vfx_player.gd FX_CONFIG | `scripts/effects/vfx_player.gd` :17-33 | **10 键**（hit/crit/death/levelup/pickup + fireball/turret_deploy/blade_burst/meteor/shield）；set_effect :36-54 判空守卫 :42-43 |
| 5 新特效 PNG | `assets/sprites/effects/fx_{fireball,turret_deploy,blade_burst,meteor,shield}.png` | 实测全在盘 ✅（+ .import 齐全，effects 目录 .import 共 12 个 = 10 特效 +2） |
| audio_manager.gd | `scripts/autoload/audio_manager.gd` | BGM_MAP :8 / **SFX_MAP :12（10 键）** / `_poll_bgm` 状态机 :85-89（判空 :86-87）/ play_bgm :108 / play_sfx :134 |
| project.godot autoload | :19-23 | GameManager :21 / DataLoader :22 / **AudioManager :23** |
| 12 WAV | `assets/audio/bgm/`（2）+ `assets/audio/sfx/`（10） | 实测全在盘 ✅ |
| weapons.json | `data/weapons.json` | **⚠️ 分类嵌套结构**：`weapons` = {melee:9, ranged:9, elemental:10, engineering:8} **共 36 把**——**勿写扁平 len()==36 断言**，须分类累加或递归统计 |
| items.json | `data/items.json` | **54 项**（顶层 `{"items":[...]}`） |
| events.json | `data/events.json` | **10 事件**（顶层 `{"events":[...]}`） |
| LORE.md | `docs/LORE.md` | 14075B 在盘 ✅ |
| REPORT_PHASE_C.md | `docs/REPORT_PHASE_C.md` | 5237B 在盘（阶段报告先例）✅；**REPORT_PHASE_D.md 未建（待产）** |
| day26_integration_check.gd | `tools/` | **未建（待 T1 新建）** |

### 新增设计决策（本轮方案师定案；D1-D34 为历史各轮决策，已收口）

| # | 决策 | 依据 |
|---|---|---|
| **D35（探针降级已解除）** | **前序日 D21-22/23/24 全部收口 → §1~§4 资产断言全量正常执行，不触发「push_warning + 跳过」降级**；但保留「顺延项存在则验、缺失登记不判失败」原则（D26-T2 抽查项 / D26-T3 顺延项汇总） | #2 第 31 轮（00:5x）明确「降级口径不再触发」；TASKS D26 区 :2091 |
| **D36（weapons 统计口径）** | **weapons.json 断言须按分类嵌套累加**：`weapons: {melee:9, ranged:9, elemental:10, engineering:8} 合计 36`——禁止 `len(weapons_json["weapons"]) == 36`（会得 4，dict 键数）；GDScript 侧 `for cat in data["weapons"]: total += data["weapons"][cat].size()` | 本轮实测 weapons.json 顶层是 4 分类 dict；TASKS D26-T3 交叉引用「weapons.json 36 把」 |
| **D37（探针纯只读）** | **day26_integration_check.gd 为纯只读校验**：ResourceLoader.exists / FileAccess 读 WAV 头 / JSON 解析 / 白盒调用只读方法——**零资产写入、零数据修改、零场景实例化副作用**（探针自身崩溃/挂起 = 自身缺陷，不得阻塞 EXIT，参照 D7 探针降级口径） | Day 26 纯校验日定位；探针自身缺陷先例（D19 格式串 / D21 fb3 死循环） |
| **D38（执行序）** | **T1（探针五段）→ T2（接线抽查）→ T3（收口清单核对）→ EXIT（回归 + REPORT_PHASE_D + commit）**——探针日无跨任务依赖交叉，文件域均 `tools/` + docs，**可单 commit 收口**；REPORT_PHASE_D 由 #3 产出（W5 域，仿 A/B/C 先例） | #2 第 22 轮拆解；D26-T1/T2/T3/EXIT 全 [ ] 就绪 |
| **D39（行号漂移防护）** | 探针内部**锚定语义而非行号**：Boss scale 断言用 `enemy.is_boss and scale == Vector2(1,1)`（白盒实例化敌方后读属性，勿依赖 :872 行号）；AudioManager 状态机白盒用 `get_node_or_null` 判空后调 `_poll_bgm()` 读 current_bgm；VfxPlayer 消费点用 `get_children()` 记录 spawn 计数 | Day 24 收口后各文件行号已再漂移（D23→D24 期间 shop/enemy 行号实测 +N 处）；探针语义断言防回归脆弱 |
| **D40（W5 主观移交）** | 主观项（精灵风格/动画流畅度/Boss 辨识度/VFX 观感/BGM-SFX 氛围/音量平衡/整合整体观感）**全量移交 #5 → PLAYTEST_CHECKLIST**，REPORT_PHASE_D 列出清单，**不阻塞阶段 D 收口出口** | 主观验收隔离铁律；TASKS D26-EXIT「主观项汇总 → PLAYTEST」 |
| **D41（commit 护栏）** | EXIT commit **勿夹带** `docs/pindou/`、`scripts/ui/*.bak`、`tools/pixel_to_pindou.py`、`docs/LOOP_HEALTH.md`；先 `git status` 检视再 `git add` 白名单 | TASKS D26-EXIT 既有护栏；Program Files 下 git 写 refs 间歇失败先例（勿 push -u，正常 commit 即可） |

### 任务1：D26-T1 新建 `tools/day26_integration_check.gd`（阶段 D 整合探针 ≥20 断言五段）

- 文件：`tools/day26_integration_check.gd`（新建，W1 域）
- 改动（按 TASKS 拆解 §1~§5，锚点用上文实测表）：
  - **§1 美术**：SPRITE_MAP 23 键全部 `ResourceLoader.exists(path)`（slime/skeleton/elite/invoker/predator 及其余 18 键）+ Boss 实例化白盒断言 `scale == Vector2(1,1)`（invoker/predator 各 1）+ 4 角色 walk/attack/skill strip 存在（`assets/sprites/characters/` 下 ailin/nowa/ryan/siia）+ factions 5 + backgrounds 4 + 头像 3 + `.import` 齐全（Image 读像素需 `ProjectSettings.globalize_path()`——已踩坑先例）
  - **§2 特效**：`vfx_player.gd` FX_CONFIG 键数 == 10（或白盒读 const 断言 10 键含 5 新特效）+ 5 新特效 PNG `ResourceLoader.exists` + hit 消费点激活（projectile 普通命中 spawn "hit"——白盒实例化弹丸触发或静态断言 `"hit"` 在 spawn 调用点）+ source_id 识别接线（se_star_fall → fx_meteor 映射存在）
  - **§3 音频**：12 WAV exists + WAV 头合法（FileAccess 二进制读 RIFF/WAVE + 22050Hz 16bit mono 声道/位深字段）+ project.godot `[autoload]` 含 AudioManager（正则读文本）+ BGM 状态机 5 态（白盒直调 `_poll_bgm()` 依 GameManager.current_state 断言 bgm 名——判空防单测场景崩溃）+ SFX_MAP 10 键
  - **§4 剧情**：`docs/LORE.md` exists + size > 0 + events.json 10 事件 + 角色剧情解锁文案数据存在（events.json 字段核验）——**解锁逻辑接线 = Day 27 依赖，缺失不判失败**
  - **§5 回归全套**：day2 32 / day3 16 / day4 21 / day5 16 / day6 14 / day7 13 / day8 19 / day10 21（F-20 保底后实际）/ day11_12 25 / day13 36 / day14_15 54 / day16 41 / day17 39 / day17_p0 20 / day18_feedback 16 / day18_feedback2 32 / day18_feedback3 27 / day18_19 48 / day20 23 / day21_22 38 / day23 18 / day24_f13 17 / day24_audio 14（**24 件套 609 断言**）
- 探针范式：`extends SceneTree` + `_advance` 分派全部 sub（勿漏段跳 part）+ 白盒直构造 + 固定 seed；**纯只读**（D37）
- 风险：**中**——断言行号/结构依赖当前实现（D39 已防）；weapons 嵌套结构统计（D36）；探针自身缺陷不阻塞 EXIT（D37 兜底）
- 验证：`Godot --headless -s tools/day26_integration_check.gd`（或项目既有探针运行方式）；目标 ≥20 断言全绿

### 任务2：D26-T2 接线完整性抽查（白盒，存在则验缺失登记）

- 文件：并入 `tools/day26_integration_check.gd` §2 或独立段（W1 域，同探针）
- 改动：
  - **AudioManager 状态机**：白盒 `current_state` 依次 MENU/BATTLE/SHOP/ROUTE_SELECT/GAME_OVER → BGM 名断言（menu/battle/battle/battle/stop）；GameManager 未加载判空零报错（:86-87 已有判空，探针调用前 `get_node_or_null` 双保险）
  - **VfxPlayer 四消费点**：hit 普通命中 / crit 暴击 / death 死亡 / levelup 升级——白盒触发 → 特效 spawn 记录非空（前序日已收口则断言；未收口 push_warning 登记）
  - **GameManager.hud 赋值**（F-11 伤害数字依赖）：`GameManager.hud` 非空 + `has_method("show_damage_number")`
  - **SPRITE_MAP 命中**：`_apply_character_sprite("siia")` → walk_texture 非 fighter 兜底（T-E 机器侧关闭断言）
- 测试点：上述抽查项缺失一律 push_warning + 登记到探针输出尾部「顺延项清单」，**不判失败**（阻塞判定归 #1）
- 风险：**低**——纯只读白盒；风险 = 状态机轮询依赖 GameManager 状态枚举值（5 态），若实现用字符串态则断言需匹配（先读 audio_manager.gd :8-24 BGM_MAP/SFX_MAP 再定断言）
- 验证：并入 day26_integration_check 运行输出

### 任务3：D26-T3 阶段 D 收口清单核对（只读核验，不写数据）

- 文件：只读 `docs/TASKS.md` + `data/*.json` + `assets/`（W2 域，禁写）
- 改动：
  - 对照 TASKS.md 各日回执：D21-22-T1~T5 / D23-T1~T5 / D24-T1~T5 / D25 条目 [x] 状态核验（未收口 → 登记缺失清单）
  - 数据/资产交叉引用核验：events.json 10 事件 id 与 LORE.md 主题对应 / items.json **54** 项 / weapons.json **36 把（嵌套分类累加，D36）** / 12 WAV 命名与 AudioManager SFX_MAP 键一致（bgm_menu/bgm_battle vs SFX 10 键）
  - 顺延项登记汇总：F 系列 P1（F-03/F-05/F-06/F-07/F-11 若顺延——实测均已由反馈专员落地，应无顺延）/ 遗物 HUD 槽 / 空间音 / 音量 UI / mech_heart 入池 / 剧情解锁接线（Day 27）→ 输出到探针尾部清单供 W5 写入 REPORT_PHASE_D 与 PLAYTEST
- 风险：**低**——只读核对；风险 = TASKS 并发写入（#2/#5 同窗口可能改 TASKS.md），核验以 git HEAD 已提交版本为准（工作区在途 docs 不纳入）
- 验证：并入探针尾部清单段，人工/机器复核输出

### 任务4：D26-EXIT 阶段 D 收口

- 文件：docs（REPORT_PHASE_D.md 新建）+ git commit
- 改动：
  1. `python tools/baseline_check.py` → `BASELINE CLEAN`
  2. `day26_integration_check` CLEAN（五段全绿或顺延项已登记）+ 回归全套 24 件套 609 断言（day2~day24_audio 全清单见 §5）+ verify 36/36
  3. 产出 `docs/REPORT_PHASE_D.md`（仿 A/B/C 先例：四域交付清单 = 美术 34 张/特效 10 键/音频 12 WAV/剧情 LORE+events；探针断言数；回归结论；主观项移交清单；顺延项登记）
  4. 主观项汇总 → `docs/PLAYTEST_CHECKLIST.md`（#5 收口：精灵风格/动画流畅度/Boss 辨识度/VFX 观感/BGM-SFX 氛围/音量平衡/整合整体观感）——**不阻塞出口**
  5. git commit 收口（勿夹带 docs/pindou/、scripts/ui/*.bak、tools/pixel_to_pindou.py、docs/LOOP_HEALTH.md；D41）
- 风险：**中**——回归全套 24 件套任一红则阻塞（若探针或回归因行号漂移误红，先按 D39 语义断言修正探针自身，勿改游戏逻辑）；baseline BENIGN 白名单（headless Dummy 音频驱动）已由 D24 收口建立，真机零影响
- 验证：EXIT 全 [x] + git log 收口提交 + 目标日推进 **Day 27（局外养成：方舟基地 + 研究系统 + 角色培养 + 剧情解锁接线承接 D25/D26）**——Day 27 已函数级预拆（#2 第 23 轮），#2 下轮可确认

### 风险总表（本轮）

| 风险 | 等级 | 说明与缓解 |
|---|---|---|
| 探针断言行号漂移 | 中 | D39 语义断言锚定；若误红先修探针自身勿改游戏逻辑 |
| weapons.json 扁平统计误判 | 中 | D36 嵌套累加口径（melee9+ranged9+elemental10+engineering8=36） |
| 回归全套 24 件套误红 | 中 | 前序日已全收口 609 断言基准；误红先复核探针锚点 |
| TASKS 并发写入（#2/#5 同窗口） | 低 | 核验以 git HEAD 已提交版本为准；方案标注前重读文件 |
| git 写 refs 间歇失败（Program Files） | 低 | 正常 commit 即可，勿 push -u（历史先例） |
| 音频 WAV 头解析越界 | 低 | FileAccess.get_buffer 长度守卫（读取前 get_length() 检查） |

---

## 执行结果：✅ 完成（2026-08-08 03:4x · #3 执行者第 33 轮 · 阶段 D 收口日全量执行）

- **T1 探针**：`tools/day26_integration_check.gd` 新建（582 行）——§1 美术（SPRITE_MAP 23 键 46 路径 + FALLBACK 6 + Boss scale 白盒复位 ×1 + 角色 walk 192×32 + factions/backgrounds/头像 + .import）/ §2 特效（FX_CONFIG 10 键 + 5 新特效 PNG + hit 消费点 + source_id）/ §3 音频（12 WAV 头合法 + autoload + BGM 状态机 5 态白盒 + SFX_MAP 10 键）/ §4 剧情（LORE.md + events 10 + 解锁文案载体）/ §5 数据交叉（items 54 / weapons 36 嵌套累加 D36 / WAV-MAP 一致）/ §6 回归（PROBES 23 项 + 期望合计 609 + 5 探针 load + day18_19 scale 锚点）——**34/34 CLEAN**。
- **T2 接线抽查**：并入探针——AudioManager 5 态白盒 ✓ / VfxPlayer 四消费点键在册 ✓ / SPRITE_MAP 命中链路 ✓ / **F-11 接口偏差登记**（GameManager.hud 实测不存在，实际 = enemy.gd `_spawn_damage_number` 直接 spawn，按语义断言，非缺陷）。
- **T3 收口清单核对**：items 54 / weapons 36（D36 嵌套累加）/ events 10 / 12 WAV 与 MAP 键一致 / 顺延项清单输出探针尾部（遗物 HUD 槽 / 空间音 / 音量 UI / mech_heart 入池 / 剧情解锁接线 → Day 27）。
- **EXIT**：baseline **BASELINE CLEAN** + 回归 **23/23 PASS（609 断言）** + verify **36/36** + `docs/REPORT_PHASE_D.md` 产出（§6 主观项移交清单，不阻塞出口）+ TASKS Day 26 区 23 处 [x] + 收口记录追加。**总断言 643**。git commit 收口后 push。
- 执行登记 2 处：① 回归 PROBES 实为 23 项（「24 件套」= 23 探针 + baseline）——期望合计 609 与方案基准吻合；② T2 GameManager.hud 接口偏差（见上）。
- **目标日推进：Day 27（局外养成）**——已函数级预拆（#2 第 23 轮），等待方案师第 8 轮落盘。
