# 方案计划（2026-08-07 · 第 6 轮）

## 当前开发日：Day 24（音频接入 + P0·用户拍板 F-13 机制型被动）

### 0) P0 调度硬性输入检查（读 PLAYTEST_CHECKLIST 追踪区头部）

- 🚨 **F-13 机制型被动（用户拍板「尽快落地方案」· 硬性调度指令）**：PLAYTEST 追踪区增量 #36（22:2x · 反馈专员执行 · 真人 8 条回执）——H-03「被动全是基础数值增加，没感觉到被动」→ 缺「质变型/机制型」词条 → 用户拍板「尽快落地方案」→ #2 第 30 轮（22:5x）已拆入 **Day 24 首段（D24-F13-1~4，显式标注 P0）**。**本轮方案必须纳入**。
- 🚨 **美术资源策略（2026-08-07 21:1x 拍板 · 硬性）**：不再生成美术资源；缺口一律占位纯色图（豁免 ART_STYLE 色号编码）→ **F-13 图标 3 帧按占位色块口径（D22/D23 先例）**；音频不涉图。
- 其余 P0 四件套（F-01/F-02/F-04/F-15）+ P1 四修复 + 反馈专员六件套 + T-C + T-D + F-19 升级冲击波全部机器侧闭环 → **无其他新机器可验证 P0 需纳入本轮**（#2 第 30 轮已确认同口径）。

### 目标日客观状态（本轮实测 23:50）

- git HEAD = `f5cd533`（Day 23 占位特效收口：22 件套 **508 断言** + baseline CLEAN）；工作区在途仅 6 docs（30DAY_PLAN / DAY_ROLE_ASSIGNMENTS / PLAYTEST_CHECKLIST / PROGRESS / TASKS / TEST_REPORT）**零游戏代码改动** → **#3 23:35 窗口尚未启动 Day 24 实现**（磁盘实测：`assets/audio/bgm/`+`sfx/` 目录在盘零文件 / `scripts/autoload/` 仅 data_loader·game_manager·main 三件、audio_manager.gd 未建 / `tools/day24*` 零文件 / items.json **51 项·20 被动·零 trigger 字段** / F-13 与音频线全 [ ]）。
- 回归基准：22 件套 **508 断言**（day2 32 / day3 16 / day4 21 / day5 16 / day6 14 / day7 13 / day8 19 / day10 20 / day11_12 24 / day13 36 / day14_15 54 / day16 41 / day17 39 / day17_p0 20 / day18_feedback 16 / day18_feedback2 32 / day18_feedback3 27 / day18_19 48 / day20 23 / day21_22 38 / day23 18 / = 508 口径含 fb2/fb3）→ **Day 24 落地后 = 24 件套 ≥534 断言**（508 + day24_audio ≥14 + day24_f13 ≥12）。
- Day 24 拆解状态：#2 第 21 轮（05:1x）音频线 T1~T5 + EXIT 函数级预拆 + #2 第 30 轮（22:5x）F-13 首段 D24-F13-1~4 → **全 [ ] 就绪，无需重拆**；#3 直接执行。

### 新增设计决策（本轮方案师定案；D1-D9 D18-19 / D10-D15 D20 / D16-D20 D21-22 / D21-D25 D23 均为历史，已收口）

| # | 决策 | 依据 |
|---|---|---|
| **D26（执行序）** | **两线并行：F-13 线（P0 优先）→ 音频线（T1~T5）→ 统一 EXIT**。F-13 内序 = F-13-1（数据）→ F-13-3（图标，与 -1 无依赖可交叉）→ F-13-2（机制消费，依赖数据）→ F-13-4（回归同步 + 探针）；音频线 T1（合成资源）→ T2（AudioManager 本体）→ T3（SFX 消费点）→ T4（Autoload 注册）→ T5（探针）。**两线各自完成后可分别 commit，EXIT 统一收口**（#2 第 30 轮建议口径 + 第 2 轮「收口 commit 显式 add」教训） | F-13 为 P0 硬性输入优先；两线文件域零重叠（F-13: items.json/icon_atlas/3 探针/player/projectile/main vs 音频: audio_manager/12 WAV/project.godot/10 消费点） |
| **D27** | **on_crit 触发语义 = 每次「暴击命中」触发一次连锁，不额外防重**（线弹一次命中一次；AOE 一次命中 N 敌暴击 → 最多 N 次连锁，接受）。理由：暴击本身低频（crit_chance clamp 0~0.9、多数武器 0.05-0.15），连锁伤害 ×0.3 为边际收益，多目标暴击触发 2-3 次连锁强度可接受；探针只验单次行为级不验次数上限 | #2 拆解字面语义「暴击命中时对目标周围 80px 敌人造成该次暴击伤害 ×30%」；防过度设计（D23 教训：接入点越小回归面越小） |
| **D28** | **on_crit AOE 实现 = F-19 升级冲击波容器遍历范式**（`GameManager.enemies_container.get_children()` + is_alive 守卫 + has_method("take_damage") + 距离判断，**禁物理查询**）：半径 80px、连锁伤害 = 该次暴击 final_damage × 0.3、连锁命中 is_crit=false（不再二次暴击）。新私有方法 `_trigger_on_crit_chain(target_pos: Vector2, crit_damage: float)`，`GameManager.inventory.has_item_id("overload_capacitor")` 短路（inventory 权威访问 = `GameManager.inventory`，game_manager.gd :65） | F-19 先例 player.gd:441-454 实测；D24-F13-2 拆解「F-19 容器遍历范式」 |
| **D29** | **low_health 用乘算开/关 + 逆运算回滚**（TASKS 口径）：`_last_stand_active: bool` 状态 + `_update_last_stand()` 统一入口（take_damage 尾部 + heal 后调用）；开 = `apply_stat_modifier("damage", 1.5, true)` + `("attack_speed", 1.2, true)`；关 = `("damage", 1.0/1.5, true)` + `("attack_speed", 1.0/1.2, true)`；**状态变化才切换一次防每帧重复应用**。⚠️ 边缘风险标注：开启期间若发生其它乘算 buff 变更（遗物装配/升级），关闭逆运算可能引入 ±小偏差——低血状态通常数秒即回血解除，期间装配/升级概率极低，可接受；探针只验单开/关闭环 | #2 第 30 轮拆解原文；apply_stat_modifier 乘算通道实测（player.gd :480-499 支持 damage/attack_speed 乘算） |
| **D30** | **crit 音收敛 2 处防双发**：① projectile.gd `_do_explosion` VFX 分派后统一播 `play_sfx("crit")`（爆炸音，陨石/火球/普爆共用）② enemy.gd :507（敌受暴击 crit VFX 旁，含 Boss AOE 路径 :729 按实现收敛取一或两处）——SFX 池 ×4 轮询天然防叠 | TASKS 拆解「三处按实现收敛，重复播放池轮询天然防叠」；**enemy.gd crit 现行行号 :507/:729（非拆解旧值 :393/:410，D23 后已漂移）** |
| **D31** | **AudioManager 判空/缺失双护栏**：`get_node_or_null("/root/GameManager")` 判空（纯单测场景跳过）；12 WAV `load()` 失败 push_warning + 跳过零崩溃（D23 set_effect :42 判空守卫同范式） | #2 第 21 轮拆解；headless Dummy audio driver 实测零崩溃 |
| **D32** | **回归同步面实测 = 6 文件 8 处（比拆解「4 处」多，全部列出防漏）**：① `scripts/utils/icon_atlas.gd` items frame_count 22→25 ② `tools/gen_item_icons.py` FRAMES 22→25 + 3 个 ic_ 函数 + 宽 704→800 ③ `day11_12_passive_check.gd` **4 处**（:351 池 55→58 / :370 被动 Item 数 22→25 / :479 frame_count 22→25 / :501 帧遍历 22→25 + :17 头注释同步）④ `day13_build_check.gd` :200 池 55→58（:198/:218 注释同步）⑤ `day16_event_check.gd` :414 池 55→58（:408 注释）⑥ `day20_relic_check.gd` :254/:373 池 55→58（:252/:365 注释）——**漏改必红**（D20 教训） | 本轮全量 grep 实测；TASKS D24-F13-4 只列 4 处（day11_12 计 1 处），实测 day11_12 内部 4 处独立断言 |
| **D33** | **两探针独立职责不混杂**：`day24_f13_check.gd`（≥12 断言四段：数据/on_crit/on_kill+low_health/回归抽样）+ `day24_audio_check.gd`（≥14 断言五段：资源/配置/状态机/播放/回归）——各自 CLEAN 后统一 EXIT | #2 拆解「独立探针防职责混杂」 |
| **D34** | **W5 主观隔离**：音频氛围感/音量平衡（程序合成占位，归 Day 26 人工）、机制型被动手感/强度体感 → PLAYTEST #5，不阻塞出口；F-13 词条数量级（3 个为最小质变验证集） | 主观验收隔离铁律；#2 拆解 W5 口径 |

### 任务拆解（执行序：F-13-1 → F-13-3 → F-13-2 → F-13-4 → T1 → T2 → T3 → T4 → T5 → EXIT；两线可交叉并行）

#### 任务1：D24-F13-1【W2】机制型被动数据落地（items.json 20→23 被动 / 51→54 项）

- 文件：`data/items.json`（+3 被动，结构仿现有项）
- 改动：新增 3 项（`is_passive:true` / `slot:"passive"` / icon_index 22/23/24 唯一）+ **新字段 `trigger` + `trigger_config`**（不入 effects 白名单；effects 保留空 `{}`）：① `overload_capacitor` 过载电容（epic/60/`{"type":"on_crit","radius":80,"ratio":0.3}`/tags["crit"]/category attack）② `executioner_mark` 处决印记（rare/40/`{"type":"on_kill","heal":1}`/tags["life_steal"]/category defense）③ `last_stand` 背水一战（rare/45/`{"type":"low_health","threshold":0.3,"attack_mult":1.5,"speed_mult":1.2}`/tags["damage"]/category stat）
- 风险：**低**（纯数据新增；effects 空对象零 STAT 消费，player.apply_item_bonuses 白名单口径零波及——D11-12 定案）
- 验证：Python 读 items.json → 54 项 / 23 被动 / 3 新词条 trigger.type ∈ {on_crit,on_kill,low_health} / icon_index 22/23/24 唯一 / effects 全 `{}`

#### 任务2：D24-F13-3【W3】图标 3 帧（占位色块，items.png 704→800×32 25 帧）

- 文件：`tools/gen_item_icons.py`（FRAMES 22→25 :24 + 3 个 ic_ 函数）+ `assets/sprites/items/items.png`
- 改动：新增 `ic_overload_capacitor`（青蓝闪电 #4FC3F7）/ `ic_executioner_mark`（暗红镰刃 #B71C1C）/ `ic_last_stand`（橙黄心火 #FFB300），复用既有 Canvas 原语（rect/ellipse/disc 等）+ 透明键（左上角 (0,0) 透明）+ **豁免 ART_STYLE 色号编码**（占位图口径）；`godot --headless --import` 补 .import
- 风险：**低**（纯新增资源 + FRAMES 常量改；D20-T5 704→800 先例）；⚠️ `icon_atlas.gd`（scripts/utils/）items frame_count 同步 22→25（D32 ①）
- 验证：items.png 800×32 exists + 帧 22/23/24 中心非空 + (0,0) 透明 + .import 在盘

#### 任务3：D24-F13-2【W1】机制消费点 3 处接入（on_crit / on_kill / low_health）

- 文件：`scripts/weapons/projectile.gd` + `scripts/autoload/main.gd` + `scripts/player/player.gd`
- 改动：
  1. **on_crit（overload_capacitor）**：projectile.gd 新私有方法 `_trigger_on_crit_chain(target_pos, crit_damage)`（`if not (GameManager and GameManager.inventory and GameManager.inventory.has_item_id("overload_capacitor")): return` → 遍历 `GameManager.enemies_container.get_children()` + is_alive + has_method("take_damage") + `distance_to(target_pos) <= 80.0` → `enemy.take_damage(crit_damage * 0.3, false)`，**禁物理查询**，容器缺失静默）。调用点 2 处：① 线弹 `_on_body_entered`（:77 `_roll_crit` → :79 `body.take_damage` 后、:81 `_hit_count += 1` 前）`if _is_crit_hit(): _trigger_on_crit_chain(body.global_position, final_damage)` ② AOE `_do_explosion` 循环内（:123 `_roll_crit` → :125 `enemy.take_damage` 后）`if _is_crit_hit(): _trigger_on_crit_chain(enemy.global_position, final_damage)`——**D27 语义：不额外防重**
  2. **on_kill（executioner_mark）**：main.gd `_on_enemy_died`（:167-172）：`if GameManager and GameManager.inventory and GameManager.inventory.has_item_id("executioner_mark") and player: player.heal(1.0)`（插在 :172 death VFX 之后）
  3. **low_health（last_stand）**：player.gd 新字段 `_last_stand_active: bool = false` + 新方法 `_update_last_stand()`（**D29 乘算开/关 + 逆运算回滚**；should = `is_alive and health > 0.0 and health <= max_health * 0.3 and GameManager and GameManager.inventory and GameManager.inventory.has_item_id("last_stand")`；状态变化才切换）；调用点 2 处：`take_damage` 尾部（:369 `_invulnerable_timer` 后、:371 `if health <= 0.0` 前）+ `heal`（:377 `health_changed.emit` 后）
- 风险：**中**——projectile.gd 是多探针回归锚点（day13/day18_feedback/day18_19/day23 命中链），on_crit 纯追加（新方法 + 2 处判定），不改伤害主链；⚠️ `_is_crit_hit()` 必须在 `_roll_crit` 之后调用（依赖 _last_crit 状态）；enemy.gd 侧**不改**（on_crit 走 projectile 侧，TASKS 拆解口径）
- 验证：白盒 3 触发点行为级——暴击命中 → 目标周围 80px 内敌掉血（记录 take_damage 调用 + 伤害 ≈ crit×0.3）+ 80px 外不掉；击杀 → heal +1 记录；health 降至 ≤30% → damage_multiplier ×1.5 生效 + 回血 >30% 恢复原值（单开/关闭环）；未持有对应遗物 → 零触发零报错

#### 任务4：D24-F13-4【W1】回归同步 + 新建 `tools/day24_f13_check.gd`

- 文件：6 个既有文件（**D32 全清单，勿漏**）+ 新建 `tools/day24_f13_check.gd`
- 改动：回归同步 8 处（见 D32）；新建探针 ≥12 断言四段：§1 数据层（54 项 / 23 被动 / 3 trigger 字段 + type 校验 / icon_index 22/23/24 唯一 / effects 空）/ §2 on_crit 白盒（mock 玩家+武器弹丸 → 暴击命中 → 连锁伤害记录 / 非暴击零触发）/ §3 on_kill heal + low_health 开关（击杀 → heal / 低血 ×1.5 生效 / 回血恢复）/ §4 回归抽样（商店池 58 + icon_atlas 25 + items.png 800×32）
- 风险：**低**（tools/ 域纯新增 + 断言数字同步）；⚠️ 探针 mock 敌人走 inner class（is_in_group("enemies") + take_damage 记录），on_crit 需 GameManager.enemies_container 注入 mock 容器（F-19/day23 先例）
- 验证：`godot --headless -s tools/day24_f13_check.gd` CLEAN

#### 任务5：D24-T1【W3】新建 `tools/gen_audio.py` 程序化合成 12 WAV

- 文件：新建 `tools/gen_audio.py` + `assets/audio/bgm/` 2 + `assets/audio/sfx/` 10
- 改动：纯 Python 标准库（wave/math/struct/random，禁第三方依赖）；`_tone(freq,dur,vol,attack,decay)`（正弦+包络）/ `_noise(dur,vol,lowpass)`（噪声+一阶低通）/ `_write_wav(path,samples)`（22050Hz 16bit mono）；**BGM 2 轨**：bgm_menu（C 大调琶音 8-12s 循环点对齐）/ bgm_battle（快节奏低音脉冲 + 主音 8-12s）；**SFX 10 类**：hit/crit/death/levelup/coin/shop/skill/heal/event/boss（0.1-1.5s，按 TASKS 拆解描述合成）；归一化峰值 ≤0.8；幂等（已存在覆盖）
- 风险：**低**（纯资源 + 工具脚本；D21-22/D23 gen 脚本先例）；⚠️ .import 需 `godot --headless --import` 补（T2 预加载依赖）
- 验证：脚本运行零报错 + 12 文件 exists + size>0 + WAV 头合法（RIFF/WAVE + 22050 + 16bit + mono）

#### 任务6：D24-T2【W1】新建 `scripts/autoload/audio_manager.gd`（AudioManager 本体）

- 文件：新建 `scripts/autoload/audio_manager.gd`
- 改动：`extends Node`（Autoload 名直调，class_name 不必须）；预加载 12 WAV（缺文件 push_warning + 跳过零崩溃 **D31**）；节点 `_bgm_player: AudioStreamPlayer`（loop_mode LOOP_FORWARD + finished→play 兜底）+ `_sfx_pool: Array[AudioStreamPlayer]` ×4（`_sfx_idx` 轮询）；接口 `play_bgm(name)`（同轨不重播）/ `play_sfx(name)`（池轮询返回是否播放）/ `set_bgm_volume(db)` / `set_sfx_volume(db)`（@export 默认 -3.0/-1.0）；`_process` 轮询 `GameManager.current_state`（`get_node_or_null("/root/GameManager")` 判空）→ MENU 播 bgm_menu / BATTLE·SHOP·ROUTE_SELECT 播 bgm_battle（已在播不重播）/ GAME_OVER stop
- 风险：**低**（全新系统零回归；Autoload 无场景零场景改动）；⚠️ headless Dummy audio driver play() 零崩溃（#2 第 21 轮实测锚点）
- 验证：白盒 play_bgm("menu") → playing + stream 名对；重复 → 不重播；play_sfx 连发 ×6 池轮询零崩溃；current_state 5 态切换 → BGM 正确（menu/battle/battle/battle/stop）

#### 任务7：D24-T3【W1】SFX 消费点接线（10 处，一行调用）

- 文件：main.gd / projectile.gd / enemy.gd / player.gd / economy.gd / shop.gd / skill_controller.gd / game_manager.gd（实际路径已 grep 确认）
- 改动（**现行行号见行号速查表，勿用 TASKS 旧值**）：① 敌人死亡 main.gd `_on_enemy_died` :172 旁 → `"death"` ② 普通命中 projectile.gd `_on_body_entered` :86（hit VFX 旁）→ `"hit"` ③ 爆炸/暴击 projectile.gd `_do_explosion` VFX 分派 :140 后 → `"crit"` + enemy.gd :507（敌受暴击，含 Boss AOE :729 按实现收敛）→ `"crit"`（**D30 收敛 2 处**）④ 受击 player.gd take_damage :367 `_play_hit_flash` 旁 → `"hit"` ⑤ 升级 player.gd `_check_level_up` :413 `level_up.emit` 后 → `"levelup"` ⑥ 金币 economy.gd `add_coins` :19 → `"coin"` ⑦ 购买 shop.gd `_purchase_item` :236 扣费成功后 → `"shop"` ⑧ 技能 skill_controller.gd `try_cast` :84-86（return true 前）→ `"skill"` ⑨ 事件 game_manager.gd `_start_event` :351 → `"event"` ⑩ Boss 波 game_manager.gd `_start_next_wave` :126 `is_boss_wave = true` 处 → `"boss"`——全部 `AudioManager.play_sfx("...")` 一行，**经 Autoload 名直调**
- 风险：**中**——8 个文件各追加一行（不动逻辑），多探针回归锚点（day3/day13/day18_19/day23 命中链）；零改动路径（未接线场景）不报错；⚠️ AudioManager 注册（T4）须先于 T3 接线验证，否则消费点调用报错——**执行序强制 T4 在 T3 验证前落盘**（或 T3 接线后立即补 T4 再跑探针）
- 验证：白盒各消费点触发 → AudioManager `_sfx_pool` 有播放记录（探针注入计数）；回归零漂移

#### 任务8：D24-T4【W1】project.godot Autoload 注册

- 文件：`project.godot` :19-22 `[autoload]` 段
- 改动：追加 `AudioManager="*res://scripts/autoload/audio_manager.gd"`（顺序：GameManager :21 → DataLoader :22 → AudioManager；读 current_state 依赖 GameManager 在前）；余不动
- 风险：**低**；⚠️ 一行追加防格式破坏（Godot 4.3 autoload 段语法）
- 验证：`godot --headless --quit` 零 ERROR + `get_node("/root/AudioManager")` 非空

#### 任务9：D24-T5【W1】新建 `tools/day24_audio_check.gd`（≥14 断言五段）

- 文件：新建 `tools/day24_audio_check.gd`
- 改动：§1 资源层（12 WAV exists + size>0 + 头合法：RIFF/WAVE 魔数 + fmt + mono + 22050 + 16bit）/ §2 配置层（project.godot [autoload] 含 AudioManager；SFX_MAP 键 ⊇ 10 类清单 + BGM_MAP 2 键）/ §3 状态机层（白盒 current_state MENU/BATTLE/SHOP/ROUTE_SELECT/GAME_OVER → menu/battle/battle/battle/stop）/ §4 播放层（play_bgm + play_sfx 不崩 + playing 标志 + 连发 ×6 池轮询 + 同轨不重播）/ §5 回归（抽样 day2/day17 + **新代码零 AudioStreamPlayer 场景引用**——纯代码 Autoload 防场景未挂节点）；范式：`extends SceneTree` + `_advance` 分发全部 sub + 白盒直构造（D11-12/13 flaky 修复记录）
- 风险：**低**（tools/ 域纯新增）；⚠️ 白盒构造 AudioManager 时用 `load()` 而非场景实例化；mock GameManager.current_state 逐态切换
- 验证：`godot --headless -s tools/day24_audio_check.gd` CLEAN

#### 任务10：D24-EXIT【W5】阶段 D 音频 + F-13 收口

- 文件：docs/TASKS.md（收口标注）
- 改动：`python tools/baseline_check.py` → BASELINE CLEAN；day24_audio_check CLEAN + day24_f13_check CLEAN + 回归全套（22 件套 508 + day24 两探针 = **24 件套 ≥534 断言**）；git commit 收口（**勿夹带** docs/pindou/、scripts/ui/*.bak、tools/pixel_to_pindou.py、docs/LOOP_HEALTH.md；显式 add 变更文件防工作区丢失——第 2 轮教训）
- 风险：**低**；⚠️ 断言数字以实测为准只增不减（F-13 回归同步仅改数字不改断言条数，day11_12 等断言数维持）；主观项登记（BGM/SFX 氛围感 / F-13 手感）→ PLAYTEST #5，不阻塞出口

### 回归影响分析（供 #3 执行时对照）

| 改动文件 | 波及探针 | 影响 |
|---|---|---|
| data/items.json（+3 被动 + trigger 字段） | day11_12 / day13 / day16 / day20（池 55→58 + Item 数 22→25）+ day20（icon_index 唯一域 0-21→0-24） | **中**：3 新被动入池 → 池大小断言全同步（D32 8 处）；effects `{}` 零 STAT 波及 |
| gen_item_icons.py + items.png（22→25 帧） | day11_12（frame_count :479 + 帧遍历 :501）/ day20（frame_count 锚点） | 中：FRAMES + 3 + icon_atlas frame_count 同步（漏改必红） |
| projectile.gd（on_crit 2 处 + sfx 2 处） | day13 / day18_feedback / day18_19 / day23 命中链 | **中**：纯追加不改伤害主链；`_is_crit_hit()` 顺序依赖 _last_crit |
| main.gd（on_kill + sfx death） | day18_feedback / day18_19 死亡链 | 中：register_kill/VFX 逻辑不动，heal 追加 |
| player.gd（low_health + sfx hit/levelup） | day2 / day4 / day11_12 / day18_feedback3 | 中：_update_last_stand 纯追加；乘算开关单开/关闭环 |
| enemy.gd（sfx crit） | day17 / day18_19 / day21_22 换皮 | 低：一行追加 |
| 新建 audio_manager.gd + project.godot | 全量回归（Autoload 新增） | 低：全新系统；Autoload 注册后 headless 零 ERROR 验证 |
| 新建 tools/day24_audio_check.gd / day24_f13_check.gd | 无（新探针入回归套） | 低 |

### 行号速查表（本轮实测 23:50，供 #3 免排查——TASKS 拆解旧行号已漂移，勿直接用）

- `data/items.json`：51 项 / 20 被动 / 零 trigger 字段（F-13 前置状态）
- `scripts/autoload/game_manager.gd`：GameState :29-34（MENU :30 / BATTLE :31 / GAME_OVER :34）/ current_state :39 / inventory :65 / BATTLE 进入 :104-107 / `_start_next_wave` :114-129（is_boss_wave=true :126）/ SHOP :149 / ROUTE_SELECT :186 / `_start_event` :351 / GAME_OVER :557
- `scripts/autoload/main.gd`：player @onready :8 / `_on_enemy_died` :167-172（register_kill :169 / death VFX :172）/ `_on_player_hit` :158
- `scripts/weapons/projectile.gd`：`_on_body_entered` :74-90（_roll_crit :77 / take_damage :79 / _hit_count :81 / hit VFX :86 / pierce 判定 :90-95）/ `_do_explosion` :111-140（AOE 循环 :121-125 / VFX 分派 se_star_fall→fireball→crit :132-140）/ `_roll_crit` :167-170（_last_crit :168）/ `_is_crit_hit` :173+
- `scripts/enemy/enemy.gd`：crit VFX :507 / levelup VFX :524 / Boss AOE crit :729 / take_damage(is_crit) :756 / die :774
- `scripts/player/player.gd`：take_damage :349-372（health 更新 :364 / took_damage.emit :366 / _play_hit_flash :367 / _invulnerable_timer :369 / die 判定 :371）/ heal :375-377 / _check_level_up :407-413（_trigger_level_impact :412 / level_up.emit :413）/ **F-19 敌人遍历范式 :441-454** / apply_stat_modifier :480-499（damage :492-493 / attack_speed :494-495 乘算支持）/ STAT_MAP :56-79 / _last_stand 插入区 :369-371 + :377
- `scripts/player/skill_controller.gd`：try_cast :68-86（_cd_left :84 / return true :86）
- `scripts/systems/economy.gd`：add_coins :19
- `scripts/ui/shop.gd`：_build_shop_pool :92（口径注释 :90「55」→58）/ _purchase_item :236
- `scripts/systems/inventory.gd`：has_item_id :112 ✅（D10-T2 已在）
- `project.godot`：[autoload] :19-22（GameManager :21 / DataLoader :22）
- `scripts/utils/icon_atlas.gd`：items frame_count（D32 ① 需同步 22→25）
- `tools/gen_item_icons.py`：FRAMES=22 :24 / OUT=items.png :21
- 回归同步 8 处：day11_12_passive_check.gd :351/:370/:479/:501（+头注释 :17）· day13_build_check.gd :200（:198/:218 注释）· day16_event_check.gd :414（:408 注释）· day20_relic_check.gd :254/:373（:252/:365 注释）

### 执行状态标注

- TASKS.md Day 24 区标注「方案已定（SOLUTION_PLAN.md · 2026-08-07 第 6 轮）」——F-13-1~4 + T1~T5 + EXIT 全部覆盖，不改 [ ] 标记
- 下一轮观察点：若 #3 01:35 窗口已启动/收口 Day 24 → 复核 F-13 机制行为 + 音频接线与定案一致性；若收口 → 目标日推进 Day 26 整合校验（Day 25 已预交付，剩接线归 Day 27 依赖）

---

### 执行结果：【完成】2026-08-08 00:5x · #3 第 33 轮执行（Day 24 全量收口）

- **F-13 线（P0 用户拍板）**：F-13-1 数据（items 51→54，3 trigger 词条 + trigger/trigger_config 字段，effects 空 {}）→ F-13-3 图标（gen_item_icons FRAMES 22→25 + items.png 800×32 + icon_atlas 25）→ F-13-2 机制消费点（projectile on_crit 连锁 / main on_kill heal / player low_health 乘算开关 D29）→ F-13-4 回归同步 + `day24_f13_check.gd` **17/17 CLEAN**
- **音频线**：T1 `gen_audio.py` 12 WAV（BGM 2×8s 循环 + SFX 10）→ T2 `audio_manager.gd`（第 3 Autoload + BGM 状态机 + SFX 池×4）→ T4 project.godot 注册 → T3 SFX 消费点 10 处 → T5 `day24_audio_check.gd` **14/14 CLEAN**
- **EXIT**：24 件套 **23/23 全绿 609 断言** + baseline **BASELINE CLEAN** + 7 commit + push 成功
- **执行登记 2 处**（方案风险命中，已按执行者规则处理并记录）：
  1. **shop.gd 行号漂移**：方案行号速查表基于 `f5cd533`（23:50），实际 HEAD=`be06af3`（反馈专员 F-20/F-21 00:0x 落地）→ `_build_shop_pool` :92→**168** / `_purchase_item` :236→**312**，已按现行行号执行（其余文件零漂移）
  2. **回归同步面 > D32 清单**：D32 列 8 处，实测还有 3 处必红——day11_12 被动数 20→23 + icon_index 范围 0-19→0-24（:196/:215-220）、day13 池 Item 22→25（:224）、day20 数据层 51→54 + is_passive 20→23（:122/:167）+ day23 锚点 51→54（:343）——全部同步补齐
- **执行中发现并解决**：headless Dummy audio driver 下 `AudioStreamPlayer.play()` 退出时 leak（baseline BROKEN）→ audio_manager 改**懒加载**（_ready 只建节点，流首次播放时加载）+ baseline BENIGN 白名单 4 条（真机零影响，注释已说明）；`--verbose` 时序相关（verbose 无警告 / 非 verbose 有）
- **主观项登记**：BGM/SFX 氛围感/音量平衡 + F-13 机制型被动手感 → PLAYTEST #5（D34 隔离口径）
