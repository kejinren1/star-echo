# 方案计划（2026-08-07 · 第 5 轮）

## 当前开发日：Day 23（技能特效 · 占位实现机制验证版）

### 0) P0 调度硬性输入检查（读 PLAYTEST_CHECKLIST 追踪区头部）

- 🚨 **用户拍板（2026-08-07 21:1x）· 美术资源策略（硬性调度指令）**：**不再投入精力生成美术资源**（AI 画图强人所难）；网上现成素材可随意用；**美术缺口一律用『占位纯色图』（单色/极简矩形贴图）填充，能检测功能已实现即可**；D21-22 已收口资产（`c091b73` 34 张）保留可用，**不扩展、不返工、不追加**；**D23 技能特效改拆为「占位特效（色块/简单发光/AnimatedSprite 复用）实现机制验证」**；纯色占位图不强制 ART_STYLE 色号编码。
- ⚠️ **口径冲突声明（本轮最重要）**：TASKS.md D23 区（:1908 起）仍为 #2 第 20 轮（03:1x）旧「华丽技能特效」拆解（D23-T2 要求「火球爆炸+焰尾环/蓝白光柱+齿轮/银蓝圆环+光点」等），**与用户 21:1x 拍板直接冲突**（#5 增量 #35 已请 #2 第 30 轮 22:5x 修正 TASKS 拆解）。**#3 执行以本方案（占位口径）为准**；TASKS 旧拆解中「机制层任务」（T1 配置扩展 / T3 接线 / T4 陨石替换 / T5 探针 / EXIT）内容仍然有效，仅 **T2 出图口径改为占位纯色图**。
- 其余 P0 四件套（F-01/F-02/F-04/F-15）+ P1 四修复 + 反馈专员六件套 + T-C + T-D 全部机器侧闭环 → **无其他新机器可验证 P0 需纳入本轮**。

### 目标日客观状态（本轮实测）

- git HEAD = `c091b73`（Day 21-22 美术资产收口：34 张 + SPRITE_MAP 换皮 + D16 hit_radius 解耦 + D17 scale 复位 + D19 动画三防 + day21_22 探针 38/38 + 回归十九件套 **490 断言**）；工作区在途仅 3 docs（30DAY_PLAN.md 已同步 L97/L100 新口径 / PLAYTEST_CHECKLIST.md / TASKS.md）**零游戏代码改动** → #3 21:35 窗口尚未启动 Day 23 实现。
- 回归基准：**十九件套 490 断言**（day2 32 / day3 16 / day4 21 / day5 16 / day6 14 / day7 13 / day8 19 / day10 20 / day11_12 24 / day13 36 / day14_15 54 / day16 41 / day17 39 / day17_p0 20 / day18_feedback 16 / day18_19 48 / day20 23 / day21_22 38 / day18_feedback2 32）
- 特效现状（本轮已实测源码）：`vfx_player.gd` FX_CONFIG **5 键**（:16-22）；`set_effect` :36-54 **已含 `if not tex: return` 判空守卫（:42-43）→ 缺图静默跳过零回归有代码支撑**；`spawn` :57-65。消费点：projectile.gd :127（crit 爆炸）/ enemy.gd :484 + :706（敌受暴击）/ enemy.gd :501（levelup）/ main.gd :150（death）；**hit 零调用方**（普通命中无特效，F-11 伤害数字已同处落地可叠加）；pickup 零调用方（T-B 掉落物系统未实现，登记不属本日）。
- 技能 id 4 个：se_skill_fireball / se_skill_deploy_turret / se_skill_blade_burst（try_cast 分派 :74/:76/:79）/ **se_skill_holy_shield 无 try_cast 分支**（希亚技能本体未实装 → 神圣庇护 VFX 顺延 P1，不臆造）。

### 新增设计决策（本轮方案师定案；D1-D9 为 D18-19、D10-D15 为 D20、D16-D20 为 D21-22 历史，均已收口）

| # | 决策 | 依据 |
|---|---|---|
| **D21（关键 · 用户拍板）** | **D23-T2 改「占位纯色图 5 枚」**：放弃华丽描述（焰尾环/齿轮/光点），改极简几何占位——`fx_fireball` 橙红实心圆+外扩环（爆炸）/ `fx_turret_deploy` 蓝白竖条光柱（部署）/ `fx_blade_burst` 银蓝圆环扩散（星刃爆发）/ `fx_meteor` 赤金实心圆+冲击环（陨石坠爆）/ `fx_shield` 白蓝半透明圆罩（护盾，P1 接线但先出图）。帧数 4-6 / 64px（meteor 128px），沿用 `gen_day21_22_art.py` 的 Canvas 范式新建 `tools/gen_day23_fx_art.py`（PIL 幂等） | 用户 21:1x 拍板：占位纯色图、能检测功能即可；机制验证不依赖表现力 |
| **D22** | **占位图豁免 ART_STYLE 强制项**（216 色/色号编码/字典登记），仅保留 PNG 透明背景（左上角 (0,0) 透明）保证 AnimatedSprite2D 渲染正确 | #5 增量 #35：纯色占位图不强制编码，仅在正式资产上强制 |
| **D23** | **FX_CONFIG 登记与出图并行不依赖顺序**：set_effect :42 判空守卫已实测存在 → 缺图期间 `spawn` 静默返回零回归；建议执行序仍为 T2（出图）→ T1（登记+hit 激活），保证首个窗口视觉可测 | vfx_player.gd:42-43 实测；D21 依赖链 |
| **D24** | **hit 消费点激活**：projectile.gd `_on_body_entered`（:74-90）`take_damage`（:79）后 spawn "hit"（线弹普通命中）——与 F-11 伤害数字（damage_numbers 同路径）视觉叠加；暴击仍走 enemy.gd:484/:706 crit 双轨并存。**注意穿透弹沿途命中（:104-127 AOE 分支）不重复 spawn hit（避免同帧多爆）** | hit 零调用方实测；F-11 已落地（:160 注释） |
| **D25** | **W5 不得判失败（主观/P1）**：VFX 华丽度/风格一致性/特效触发是否过度 → PLAYTEST #5 收口；holy_shield 技能 VFX（希亚技能未实装，P1）；pickup 特效（T-B 掉落物未实现，登记）；特效色 shader 机制（Backlog P1 决策，不建 GPU 基建，AnimatedSprite2D 图集最稳） | 主观验收隔离铁律；#2 第 20 轮实测边界 |

### 任务拆解（执行序：T2 → T1 → T3 → T4 → T5 → EXIT）

#### 任务1：D23-T2【W3 主责】占位特效 PNG 5 枚（机制可检测即可）

- 文件：新建 `tools/gen_day23_fx_art.py` + `assets/sprites/effects/` 5 文件
- 改动：新建生成脚本（复用 gen_day21_22_art.py 的 Canvas 原语：`Canvas.rect/ellipse/disc/rect_o` 等，纯 PIL 零第三方依赖）；输出 5 PNG——`fx_fireball.png`（6 帧 64px 橙红 #FF6A3D 实心圆半径递增 8→28 + 描边）/ `fx_turret_deploy.png`（4 帧 64px 蓝白 #4FC3F7 竖条 16×48 上下拉长 + 底部横条）/ `fx_blade_burst.png`（6 帧 64px 银蓝 #AFCBFF 圆环 stroke 4px 半径 10→30 扩散）/ `fx_meteor.png`（6 帧 128px 赤金 #FF8C2E 实心圆 + 外扩冲击环）/ `fx_shield.png`（6 帧 64px 白蓝 #D0E6FF 半透明圆罩，alpha 120）——帧序 = 由小到大/由内到外即「动画」，AnimatedSprite2D 播放天然形成扩散感
- 风险：**低**（纯新增资源零代码耦合；PIL 幂等先例 D21-22 已验证；不强制色号编码）。⚠️ `.import` 需 `godot --headless --import` 补（D21-T0 先例），否则探针 load 不到
- 验证：脚本运行零报错 + 5 PNG exists + 尺寸合规（64/64/64/128/64）+ 每张帧宽 = size.x×frames（如 64×6=384 宽）+ 左上角 (0,0) 透明

#### 任务2：D23-T1【W1】VfxPlayer FX_CONFIG 扩展 + hit 消费点激活

- 文件：`scripts/effects/vfx_player.gd` :16-22（FX_CONFIG）+ `scripts/weapons/projectile.gd` :74-90
- 改动：FX_CONFIG +5 键：`"fireball": {"path": "res://assets/sprites/effects/fx_fireball.png", "frames": 6, "size": Vector2i(64,64), "fps": 12.0}` / `"turret_deploy": {...4 帧 64px fps 10}` / `"blade_burst": {...6 帧 64px fps 12}` / `"meteor": {...6 帧 128px fps 12}` / `"shield": {...6 帧 64px fps 10}`（frames/size 与 T2 PNG 实际一致；**缺图零风险**——set_effect :42 判空守卫已实测）。projectile.gd `_on_body_entered`（:79 `body.take_damage` 后、:86 最后一次命中 `_explode` 前）：`if GameManager.vfx_container: VfxPlayer.spawn(GameManager.vfx_container, global_position, "hit")`；**穿透弹沿途 AOE（:104-127）不重复 spawn**（普通线弹已覆盖视觉）
- 风险：**中**——projectile.gd 是多探针回归锚点（day13 36 / day18_feedback 16 / day18_19 48 均涉及命中链），改动仅追加 spawn 一行不改伤害逻辑，回归重点验证零行为漂移；hit 与 F-11 伤害数字同帧生成，需确认 CanvasLayer 层级不互盖（damage_numbers 挂 HUD CanvasLayer，VfxPlayer 挂 vfx_container Node2D，天然上层，无冲突）
- 验证：白盒 spawn("fireball") 缺图 → null 不崩（:42 守卫实证）；FX_CONFIG 10 键；线弹命中 → hit spawn 计数 +1；回归十九件套零漂移

#### 任务3：D23-T3【W1】技能专属 VFX 接线（fireball 替换 crit / turret / blade）

- 文件：`scripts/player/skill_controller.gd`（_cast_fireball :91-149 / _cast_deploy_turret :151-186 / _cast_blade_burst :188+）+ `scripts/weapons/projectile.gd` :97-130
- 改动：① 火球来源识别：`_cast_fireball` 构建 proj 后 `proj.set_meta("source_id", "se_skill_fireball")`（D13-T2 meta 范式）；projectile.gd `_explode` :127 处判定 `get_meta("source_id", "") == "se_skill_fireball"` → spawn "fireball" 替换 crit（其余武器保持 crit 零回归）② `_cast_deploy_turret` 每台部署处（循环内）spawn "turret_deploy" ③ `_cast_blade_burst` 玩家身周 spawn "blade_burst"；**holy_shield 顺延 P1**（try_cast 无分支 :68-89，不臆造）
- 风险：**中**——source_id 判定在 `_explode` 热路径（每弹爆炸必经），get_meta 默认值兜底零影响；fireball 弹需确保 set_meta 在 `_cast_fireball` 全部分支（含 F-07 穿透）都覆盖，防部分弹无 meta 走 crit；回归重点 = 其余 52 武器爆炸仍 crit
- 验证：白盒 try_cast(fireball) → proj 有 source_id meta；_explode → vfx 名 == "fireball"；deploy_turret → turret_deploy 计数 == 台数；blade_burst → spawn 1 次；其余武器爆炸 → "crit" 不变（回归锚点）

#### 任务4：D23-T4【W1】进化陨石替换（se_star_fall → fx_meteor）

- 文件：`scripts/weapons/projectile.gd` :97-130（与 T3 同区，可合并实现）
- 改动：`_explode` 判定 `get_meta("source_id", "") == "se_star_fall"` → spawn "meteor"（替换 crit）；se_star_fall 的 source_id meta 由 weapon_controller D13-T2 sync 链路天然携带（白盒注入兜底）；**判定顺序建议：先 se_star_fall → 再 se_skill_fireball → 兜底 crit**（防 meta 叠加歧义）
- 风险：**低**（纯新增分支，默认值兜底）；⚠️ 若 weapon_controller 实际未带 se_star_fall 的 meta（D13-T2 sync 需复核），改在 weapon_controller 生成处补 set_meta 一行
- 验证：白盒 se_star_fall 弹丸爆炸 → vfx 名 == "meteor"；其余武器 → "crit" 不变

#### 任务5：D23-T5【W1】新建 `tools/day23_vfx_check.gd`（VFX 探针 ≥12 断言四段）

- 文件：新建 `tools/day23_vfx_check.gd`
- 改动：§1 配置层 = FX_CONFIG 10 键 + 5 新特效 path 对应资源 exists（T2 已出图；缺图 push_warning 不判失败 P1）+ set_effect 缺图 null 不崩（:42 守卫实证）；§2 消费层 = 白盒线弹命中 → hit spawn +1 / crit 路径仍 crit（双轨）/ fireball 爆炸 → "fireball" / se_star_fall 爆炸 → "meteor"；§3 技能层 = deploy_turret → turret_deploy == 台数 / blade_burst → spawn 1 次 / holy_shield → 静默 false 不崩不刷 warning（P1 登记）；§4 回归 = 既有 5 特效消费点不破坏（enemy crit :484/:706、levelup :501、main death :150）+ baseline 锚点。探针范式沿用：`extends SceneTree` + `_advance` 分发全部 sub + 白盒直构造（D11-12/13 flaky 修复记录：固定序列须 `seed(N)` 全局种子或白盒直构造）
- 风险：**低**（tools/ 域纯新增）；⚠️ 探针断言 vfx 名需 hook VfxPlayer.spawn（白盒注入计数数组），勿用真实父节点（防节点树污染）
- 验证：`godot --headless -s tools/day23_vfx_check.gd` CLEAN；回归十九件套 + day23 = **二十件套 490+ 断言**

#### 任务6：D23-EXIT【W5】阶段 D 续段收口

- 文件：docs/TASKS.md（收口标注）
- 改动：`python tools/baseline_check.py` → BASELINE CLEAN；day23_vfx_check CLEAN + 回归全套（十九件套 490 + day23 ≥12 = **≥502 断言**）；git commit 收口（**勿夹带** docs/pindou/、scripts/ui/*.bak、tools/pixel_to_pindou.py、docs/LOOP_HEALTH.md——沿用 D23-EXIT 既有清单）
- 风险：**低**；⚠️ commit 显式 add 变更文件防工作区丢失（第 2 轮教训）
- 验证：回归全套 + baseline CLEAN + 主观项登记（VFX 华丽度/触发频率 → PLAYTEST #5，不阻塞出口）

### 回归影响分析（供 #3 执行时对照）

| 改动文件 | 波及探针 | 影响 |
|---|---|---|
| vfx_player.gd（+5 键） | 全量回归（新键仅新增，既有 5 键零改动） | 低：只加不动 |
| projectile.gd（hit spawn + source_id 分支） | day13 / day18_feedback / day18_19 / day20 命中链相关 | **中**：纯追加不改伤害逻辑，断言数不变，重点防零漂移 |
| skill_controller.gd（3 处 spawn + set_meta） | day3 技能 / day13 / day18_feedback（F-07 火球） | 中：try_cast 返回路径不变，spawn 在返回后追加 |
| 新增 tools/day23_vfx_check.gd | 无（新探针入回归套） | 低 |

### 行号速查表（本轮实测，供 #3 免排查——TASKS 旧拆解行号已漂移，勿直接用）

- `scripts/effects/vfx_player.gd`：FX_CONFIG :16-22 / set_effect :36-54（判空 :42-43）/ spawn :57-65
- `scripts/weapons/projectile.gd`：_on_body_entered :74-90（take_damage :79 / 末次命中 _explode :86）/ _explode :97-130（crit spawn :127）/ 穿透 AOE :104-127 / _is_crit_hit F-11 :160
- `scripts/player/skill_controller.gd`：try_cast :68 / 分派 :74/:76/:79 / _cast_fireball :91-149（pierce 3 :121）/ _cast_deploy_turret :151-186（se_turret_array meta :168）/ _cast_blade_burst :188+
- `scripts/enemy/enemy.gd`：crit :484 / levelup :501 / crit（Boss 路径）:706
- `scripts/autoload/main.gd`：death VFX :150

### 执行状态标注

- TASKS.md D23 区标注「方案已定（SOLUTION_PLAN.md · 2026-08-07 第 5 轮 · 占位特效口径）」
- 下一轮观察点：若 #3 21:35 窗口已启动 Day 23（git HEAD 推进）→ 复核实现与占位口径一致性；若收口 → 目标日推进 Day 24 音频（已函数级预拆）

---

## 执行结果：【完成】2026-08-07 22:4x · #3 第 31 轮

**Day 23 占位技能特效全量落地，零阻塞，二十二件套 508 断言 + BASELINE CLEAN。**

- **T2（W3 出图）**：新建 `tools/gen_day23_fx_art.py`（复用 gen_day21_22_art.py Canvas 原语 + ring 圆环，纯 PIL 幂等）→ 5 PNG 全生成：fx_fireball（6×64 橙红实心圆 8→28 + 高光芯）/ fx_turret_deploy（4×64 蓝白竖条 16×48 + 底部横条）/ fx_blade_burst（6×64 银蓝圆环 stroke4 半径 10→30）/ fx_meteor（6×128 赤金实心圆 + 冲击环 20→45）/ fx_shield（6×64 白蓝半透明罩 alpha120 18→28）；左上角 (0,0) 透明合规；`godot --headless --import` 补 .import 5 个。
- **T1（FX_CONFIG + hit 激活）**：vfx_player.gd FX_CONFIG 5→10 键（frames/size 与 PNG 实测一致）+ `current_fx` 诊断字段（探针观测 spawn 名，零行为影响）；projectile.gd `_on_body_entered` take_damage 后 spawn "hit"（普通命中反馈，穿透沿途每个被命中敌人都触发，AOE 分支不重复）。
- **T3（技能专属 VFX）**：skill_controller.gd——`_cast_fireball` 构建 proj 后 `set_meta(&"source_id", "se_skill_fireball")`（覆盖 F-07 穿透全分支）；`_cast_deploy_turret` 循环内每台 spawn "turret_deploy"；`_cast_blade_burst` 玩家身周 spawn "blade_burst"；holy_shield 顺延 P1（不臆造）。
- **T4（进化陨石）**：projectile.gd `_do_explosion` VFX 分派——判定顺序 se_star_fall → "meteor" / se_skill_fireball → "fireball" / 兜底 "crit"（其余武器零回归）。**执行登记**：方案风险提示命中——`weapon_controller._spawn_projectile` 实测未透传武器 source_id meta → 在弹丸生成处补 `proj.set_meta(META_SOURCE_ID, str(weapon.get_meta(META_SOURCE_ID, "")))` 一行（全武器弹丸带 meta，兜底判 crit 零回归）。
- **T5（探针）**：新建 `tools/day23_vfx_check.gd` 18/18 CLEAN 四段（§1 配置层 5 断言 / §2 消费层 4 / §3 技能层 6 / §4 回归 4）。探针范式沿用 SceneTree + _advance 分派 + 白盒直构造；VfxPlayer.spawn 为静态方法无法直接 hook → 改「GameManager.vfx_container 指向探针自建 Node2D + 扫描 children 的 current_fx」观测（先 add_child 后 set_effect 时序保证同步可读）；mock enemy 走 inner class（is_in_group("enemies") + take_damage）。踩坑 1 处：同名炮台实例被 Godot 自动改名 @Node2D@N → 炮台计数改按特征方法 `_draw_placeholder` 而非 name 前缀。
- **EXIT（收口）**：回归全套 21/21（`_regression_run.py` 加 day23_vfx_check = 二十二件套，**508 断言**）+ baseline_check.py `BASELINE CLEAN`；TASKS.md D23 区 T1-T5+EXIT 全部 [x]；git commit 收口。
- **主观项登记（交 PLAYTEST #5，不阻塞）**：VFX 华丽度/风格一致性 / 特效触发频率（hit 全命中触发）/ F-19 升级冲击波真人回归。目标日推进 = **Day 24 音频接入**（已函数级预拆，等方案师落盘）。
