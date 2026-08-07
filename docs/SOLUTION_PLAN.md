# 方案计划（2026-08-07 · 第 4 轮）

## 当前开发日：Day 21-22（美术资产落地 · 阶段 D 首段）

### 0) P0 调度硬性输入检查（读 PLAYTEST_CHECKLIST 追踪区头部）

- 增量 #34（19:5x #5）：Day 20 收口确认（十七件套 452 断言）→ **T-D 技能图标已落地**（08-08 时限前一天完成 ✅）；F-16 追加真人回归（商店点击购买，主观项交 #5）
- P0 四件套（F-01/F-02/F-04/F-15）+ P1 四修复 + 反馈专员六件套 + T-C 全部机器侧闭环 → **无新机器可验证 P0 需纳入本轮方案**
- ⚠️ 旁注（#4 域，非本岗）：TEST_REPORT 止于 #27，未覆盖其后 5 提交（02fa9c1/e2bcf40/97021b3/2d99053）→ 请 #4 下轮纳入 day18_feedback2（32 断言）

### 目标日客观状态（本轮实测）

- git HEAD = `2d99053`（19:37 docs）——**#3 第 28 轮（19:35）尚未启动 Day 21-22 实现**；工作区在途仅 docs 3 文件（README.md / PLAYTEST_CHECKLIST.md / GIT_COLLAB.md），**零游戏代码改动**
- `assets/sprites/enemies/` 实测 = 仅 slime_move/death + skeleton_move/death 4 文件（框架遗留，24/32px 帧）；**无精英/Boss 专属精灵**
- `assets/sprites/characters/` = elin/noah/lain/siia idle+portrait + 三英雄旧 walk（Aug 4 占位）+ fighter；**无 siia_walk**（T-E 复现）
- 无 skills/ factions/ backgrounds/ 目录（T-D 已收口：skills.png 128×32 4 帧在盘，HUD 接线已实装 = D21-T0 C 段 [x]）
- 回归基准：**十七件套 452 断言**（day2 32 / day3 16 / day4 21 / day5 16 / day6 14 / day7 13 / day8 19 / day10 20 / day11_12 24 / day13 36 / day14_15 54 / day16 41 / day17 39 / day17_p0 20 / day18_feedback 16 / day18_19 48 / day20 23）

### 新增设计决策（本轮方案师定案，D1-D9 为 D18-19 历史、D10-D15 为 D20 历史，均已收口）

| # | 决策 | 依据 |
|---|---|---|
| **D16（新·关键）** | **换皮判定解耦：SPRITE_MAP/FALLBACK 条目新增可选 `hit_radius` 字段**，接触判定改用实例变量（缺省 = 旧公式 `frame_size.x*0.5+12.0` 兜底零回归）。建议值：杂兵 28 / 骷髅 28 / 精英 36 / Boss 56（均 ≥ 旧等效 24/28，视觉合理且不爆炸）。**Boss 128px 若走旧公式 = 接触距离 76px → Boss 战近身判定暴增 2.7 倍，必解耦** | enemy.gd:179 `contact_range = frame_size.x*0.5+12.0` 实测；F-01 围杀修复不可回归 |
| **D17（TASKS 已定）** | **Boss scale 复位 ×1 双点同步**：enemy.gd:839 `scale=Vector2(2.0,2.0)` → `(1.0,1.0)`（128px 真精灵 + ×1 = 正确视觉）+ day18_19_boss_check.gd:194 断言值 `Vector2(2.0,2.0)` → `Vector2(1.0,1.0)`（**断言数不变仍 48**） | #2 第 28 轮已实测两落点 |
| **D18** | **碰撞体保持 frame_size×0.8 公式（不额外解耦）**：换大帧 → 弹丸命中框自动放大 = 大目标好打（合理利好）；接触伤害由 D16 hit_radius 独立控制 → 视觉大 ≠ 判定凶 | enemy.gd:218 实测；F-02 协议不变 |
| **D19** | **player.gd 动画追加三防**：① `ResourceLoader.exists` 守卫——缺 attack/skill 帧文件则不追加该动画（防 create_multi 吃 null 纹理未知行为）② `_update_animation` 头部加 `if _anim.animation in ["attack","skill"]: return`（防 move_and_slide 立即切回 idle 打断）③ `animation_finished` 信号 → 回 "idle"（`_is_walking` 状态同步） | player.gd:224-233 实测只认 idle/walk；T3 预拆「缺帧走 idle 降级」 |
| **D20** | **W5 不得判失败**：精灵风格审美 / 动画流畅度 / Boss 辨识度 / 阵营与背景概念图美学 → PLAYTEST #5 收口；attack/skill 动画缺帧走降级登记 P1 | 主观验收隔离铁律 |

### 任务1：D21-22-T1 敌人/Boss 精灵换皮（W3 主责 + W1 协作）——【最高优先级 · 出图先行】

- **文件（W3 新建）**：`assets/sprites/enemies/` 下
  - `slime_move.png` / `slime_death.png`（**覆盖旧文件**，48px 基准 4+4 帧 sheet）
  - `skeleton_move.png` / `skeleton_death.png`（覆盖旧文件，48px 4+4）
  - `elite_move.png` / `elite_death.png`（新，64px 4+4，骨架 + 特征色 modulate 区分，D17 先例）
  - `invoker_move.png` / `invoker_death.png`（新，128px 法袍施法者 4+4）+ `predator_move.png` / `predator_death.png`（新，128px 四足掠食 4+4）
- **文件（W1 改）**：
  - `scripts/enemy/enemy.gd` SPRITE_MAP :71-97：slime 系 13 条（:73-87 除 skeleton 2 条）→ 新 slime 路径，size 按 sheet 实切（48px 帧 → `Vector2i(48,48)`）+ `"hit_radius": 28.0`；skeleton 2 条（:82/:86）→ 新 skeleton + hit_radius 28；elite 6 条（:89-94）→ elite_move/death + size `Vector2i(64,64)` + hit_radius 36；boss 2 条（:96-97）→ invoker/predator 专属 + size `Vector2i(128,128)` + hit_radius 56
  - FALLBACK_SPRITES :101-104 同步：elite（:103）→ elite 路径 + hit_radius 36；boss（:104）→ invoker 路径兜底 + hit_radius 56（boss 无专属 id 时）
  - enemy.gd 判定解耦：_setup_animation :195 `frame_size = cfg["size"]` 后加 1 行 `hit_radius = float(cfg.get("hit_radius", frame_size.x * 0.5 + 12.0))`（新实例变量 @export 声明于 :62 frame_size 旁，默认 -1 由 _setup 覆盖）；:179 改 `var contact_range: float = hit_radius`
  - enemy.gd:839 `scale = Vector2(2.0, 2.0)` → `Vector2(1.0, 1.0)`（D17）
  - `tools/day18_19_boss_check.gd:194` 断言 `Vector2(2.0, 2.0)` → `Vector2(1.0, 1.0)`（D17，断言数不变）
- **风险**：【高】SPRITE_MAP size/frames/fps 与 PNG 实切不符 → AnimatedSprite2D 花屏 + 探针红（W3 出图与 W1 映射必须同轮对表）；【中】hit_radius 判定链改动——默认值=旧公式兜底零回归，已确认无探针断言 contact_range 具体值；【中】覆盖旧 slime/skeleton PNG 影响框架遗留引用（无其他消费方，grep 已确认仅 SPRITE_MAP）
- **验证**：`ResourceLoader.exists` 全部路径命中（W1 后新探针 §1）；day18_19 探针回归（scale 断言同步后 48/48）；若 scale 断言漏改 → 探针红为哨兵即发现

### 任务2：D21-22-T2 角色 walk 真多帧 + 希亚 walk（W3 主责 + W1 协作）

- **文件（W3）**：`{elin|noah|lain}_walk.png` 重绘 6 帧 192×32（覆盖 Aug 4 旧文件）；`siia_walk.png` 新建 6 帧 192×32（白蓝紫对齐 siia_idle）
- **文件（W1）**：`scripts/player/player.gd` **零改动预期**（:181 `_apply_character_sprite` idle+walk 齐全即生效，:119 调用链已通）
- **风险**：【低】帧尺寸与 Player.tscn export frame_size（32×32）不符 → 切帧错位（W3 严格 32px 帧宽）
- **验证**：新探针 §3 白盒 `_apply_character_sprite("siia")` → walk_texture 非 fighter 兜底（T-E 机器侧关闭）；4 文件存在 + 192×32 + 6 帧非空 + 透明键

### 任务3：D21-22-T3 攻击/技能帧 strip + 动画接线（W3 主责 + W1 协作）

- **文件（W3）**：`{elin|noah|lain|siia}_attack.png`（4 帧 128×32）+ `{elin|noah|lain|siia}_skill.png`（4 帧 128×32：火球施法/部署手势/剑域挥斩/神圣庇护抬手）——产能不足时 skill 用 attack 帧替代（PRE #4 降级）
- **文件（W1）**：
  - `scripts/player/player.gd` _setup_animation :217-220 后追加 attack/skill 动画（fps 10-12、loop false），**每动画先 `ResourceLoader.exists` 守卫**（D19①）
  - `_update_animation` :224 头部：`if _anim.animation in ["attack", "skill"]: return`（D19②）
  - 新函数 `_play_attack_anim()` / `_play_skill_anim()` + `_anim.animation_finished` 连接（D19③，回 idle 且 `_is_walking=false` 下次 move 自动 walk）
  - 触发点：WeaponController 开火 → `_play_attack_anim()`（W1 在开火循环加一行调用，经 player 引用或信号，按 main.gd 现有接线范式）；skill_controller 信号 `skill_cast` → `_play_skill_anim()`（player 已有 :223 转发链）
- **风险**：【中】动画追加后 move_and_slide 立即切回 idle 打断 attack/skill → 三防必须同时落地（漏任一 → 动画不可见但零崩溃，W5 观察）；【低】skill_controller 信号名/时序不符 → 白盒探针兜底
- **验证**：新探针白盒触发 skill_cast → `_anim.animation == "skill"` → 播完回 "idle"；开火 → "attack"；缺帧文件 → 动画缺失走 idle 降级（W5 不得判失败）

### 任务4：D21-22-T4 遗留头像 + 阵营图标 + 背景概念图（W3）

- **文件（W3）**：`{brawler|ranger|mage}_portrait.png` 64×64（3 张代表；well_rounded/engineer/gambler 接受 fighter 占位登记 P1）；`assets/sprites/factions/{echo_alliance|star_cult|abyss_council|mech_empire|free_mercs}.png` 32px ×5；`assets/sprites/backgrounds/{wulan_workshop|corrupted_forest|lava_mine|void_corridor}.png` ×4（供 Day 23+ 参考，不做 TileMap 消费）
- **风险**：【低】纯新增资产零代码消费；216 色/透明键违规 → 探针 §4 断言红
- **验证**：新探针 §4 文件存在 + 尺寸合规 + (0,0) 透明键；`.import` 用 `godot --headless --import` 补（D2-T3 先例）

### 任务5：D21-22-T5 新建 `tools/day21_22_art_check.gd`（W1 · ≥15 断言五段）

- **文件**：`tools/day21_22_art_check.gd`（新建）
- **改动**：五段设计——§1 敌人：SPRITE_MAP/FALLBACK 全路径 exists + size/frames/fps 与 PNG 实切一致（slime 4+4 / skeleton 4+4 / elite 4+4 / invoker·predator 4+4，**用 Image 读 PNG 实际尺寸比对，防映射与资产脱节**）＋ **hit_radius 断言**（elite 36 / boss 56 / 未指定条目 == frame_size 公式值，零回归锚点）；§2 Boss scale：is_boss scale == Vector2(1.0,1.0)（复位断言）；§3 角色：4 walk 192×32 + 4 idle 存在 + `_apply_character_sprite("siia")` 白盒 → walk_texture 非 fighter + attack/skill strip 存在（缺失 → push_warning 登记不判失败，P1）；§4 图标/概念图：factions 5 + backgrounds 4 + 遗留头像 3 存在 + 尺寸 + 透明键；§5 回归：day18_19 探针（scale 同步后）+ day2/day17 抽样 + `.import` 齐全
- **风险**：【中】探针读 PNG 需 `Image.load_from_file` + `ProjectSettings.globalize_path()`（已踩坑先例，memory 有记录）；【低】hit_radius 锚点断言若 W1 忘记给某条目加 → 探针红即发现（防漏）
- **验证**：探针自身 CLEAN + 回归全套（见 EXIT）

### 任务6：D21-22-EXIT 收口（W5）

- **改动**：`python tools/baseline_check.py` → BASELINE CLEAN；`day21_22_art_check` CLEAN + **回归全套十七件套**（day2 32 / day3 16 / day4 21 / day5 16 / day6 14 / day7 13 / day8 19 / day10 20 / day11_12 24 / day13 36 / day14_15 54 / day16 41 / day17 39 / day17_p0 20 / day18_feedback 16 / **day18_19 48（scale 断言值已同步）** / day20 23）；git commit 收口（**勿夹带** docs/pindou/、scripts/ui/*.bak、tools/pixel_to_pindou.py、docs/LOOP_HEALTH.md）
- **风险**：【低】收口夹带第三方文件 → 按 EXIT 清单白名单 add
- **验证**：探针日志 + git status 复核

### 风险总表

| 风险 | 级 | 说明 | 替代方案 |
|---|---|---|---|
| SPRITE_MAP 与 PNG 实切脱节（花屏/探针红） | 高 | size/move_frames/fps 任一不符 → AnimatedSprite2D 帧错位 | 探针 §1 用 Image 实测尺寸比对强制对表；W3/W1 同轮对表 |
| Boss scale 复位漏改单点 | 高 | :839 或 :194 只改一处 → 探针红或 256px 超框 | day18_19 探针回归即哨兵；T1 内两处同改 |
| 接触判定解耦（D16） | 中 | 判定链改动波及全部敌人 | 默认值=旧公式零回归；无探针断言 contact_range 具体值（已查） |
| Boss hit_radius=56 仍偏高/偏低 | 中 | 主观体感 | Owner 可调：偏凶 → 44；视觉违和（穿过 Boss 不掉血）→ 64；默认 56 |
| player.gd 动画三防遗漏 | 中 | 动画不可见但零崩溃，W5 主观观察 | 三防同时落地（D19 ①②③） |
| 出图违规（色数/透明键） | 低 | 探针 §4 断言红 | 按 ART_STYLE v2 字典登记制自查 |

### 执行顺序（#3 参考）

1. **W3 出图先行**（T1 敌人 10 PNG → T2 walk 4 → T3 attack/skill 8 → T4 头像/阵营/背景 12）——T1 敌人图与 W1 映射同轮对表
2. **W1 接线**：T1（SPRITE_MAP + hit_radius 解耦 + scale 复位双点）→ T3（动画三防 + 触发接线）→ T5（探针五段）
3. **EXIT**：回归全套 → commit 收口
4. 主观项登记 → PLAYTEST #5 收口（精灵风格 / 动画流畅度 / Boss 辨识度 / 换皮后体感）

---

## 执行结果：完成（2026-08-07 20:2x · #3 第 29 轮执行窗口）

- **T1 敌人/Boss 换皮** ✅：`tools/gen_day21_22_art.py` 新建（幂等）生成 10 张（slime/skeleton 48px 4+4 覆写、elite 64px、invoker/predator 128px 新建）；enemy.gd SPRITE_MAP 23 条 + FALLBACK 3 条全换新路径 + hit_radius 解耦（D16，缺省旧公式零回归）+ scale 复位 ×1（D17 双点：enemy.gd:839 / day18_19_boss_check.gd:194）
- **T2 角色 walk** ✅：elin/noah/lain 重绘 6 帧 + siia_walk 新建（T-E 机器侧关闭）；player.gd 零改动生效（4 文件 192×32 6 帧非空 + 透明键）
- **T3 攻击/技能动画** ✅：D19 三防全落地（exists 守卫 / 短路 / finished 回 idle）+ weapon_controller 开火触发 + player._ready 直连 skill_cast 信号；探针白盒验证 skill→idle、attack、缺帧降级
- **T4 头像/阵营/背景** ✅：3 头像 64×64 + 5 阵营 32×32 + 4 背景 320×180，全透明键合规
- **T5 探针** ✅：`tools/day21_22_art_check.gd` 38/38 CLEAN 五段（含 Image 实切对表 + hit_radius 锚点 + siia 白盒）
- **EXIT** ✅：baseline CLEAN + **回归十九件套 19/19**（原十七件套 452 断言持平 + day21_22 38 新增 = 490）
- **执行登记 2 处（见 TASKS.md 收口块）**：① slime move_frames 2→4（方案 §1 未列但 T5 探针实切口径要求，映射与 PNG 同轮对表）；② T3「player 已有 :223 转发链」实测不存在 → 改 _ready 直连信号（未改 SkillController）
- 遗留：精灵风格/动画流畅度/Boss 辨识度 → PLAYTEST #5 收口；TEST_REPORT #28 待 #4 纳入新探针
