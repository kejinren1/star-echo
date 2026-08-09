# 技术债登记清单（TECH_DEBT_ISSUES）

- **单一事实源**：阶段 F 全部技术债逐条追踪，编号 T-001 起
- **状态流转**：待处理 → 处理中 → 已收口（含 git 提交）/ 已接受（设计如此）
- **归属阶段**：F1 数据层统一 / F2 边界收拢 / F3 状态机 / F4 拆分 / F5 收口 / 已修（F0）
- 依据：2026-08-10 全量审计（docs/TECH_DEBT_PLAN.md §1）

## 硬编码（数值/公式）

| 编号 | 位置 | 问题 | 状态 | 阶段 |
|---|---|---|---|---|
| T-001 | data_loader.gd:198-199 | 精英 HP/伤害乘数硬编码，enemies.json.scaling 同值但零消费（改 JSON 不生效） | 待处理 | F1 |
| T-002 | data_loader.gd:191,194 | 移速公式 + F-01 减速 0.5 硬编码（scaling.speed_formula 零消费） | 待处理 | F1 |
| T-003 | enemy_spawner.gd:45 | 生成间隔公式硬编码（waves.json.generation 零消费） | 待处理 | F1 |
| T-004 | weapon_controller.gd:50-62 | 初始枪内联配置，不在 weapons.json | 待处理 | F1 |
| T-005 | audio_manager.gd:89-96 | int 字面量匹配 GameState，枚举增删即静默错乱 | 待处理 | F3 |
| T-006 | player.gd:417 / enemy.gd:762 | 护甲两套算法并存（平直减 vs 百分比），stats.json.formulas 零消费 | 待处理 | F1 |
| T-007 | game_manager.gd:184 | F-05 通关回血 50% 硬编码 | 待处理 | F1 |
| T-008 | game_manager.gd:109 / wave_manager.gd:30 | max_waves=20 双处重复 | 待处理 | F1 |
| T-009 | enemy.gd:421,425,434 | 冲锋倍率/蓄力/冲锋时长硬编码 | 待处理 | F1 |
| T-010 | shop.gd:31,125 | REROLL_COST=10 / 星刃保底 current_wave==4 硬编码 | 待处理 | F1 |
| T-011 | projectile.gd:47,56 | collision_mask=2 / 半径 4.0 魔法数字 | 待处理 | F1 |
| T-012 | skill_controller.gd:118-130 | 火球 speed/lifetime/pierce/radius 硬编码（damage 部分已数据化） | 待处理 | F1 |
| T-013 | player.gd:430,422,593 | 无敌帧 0.4 / 金手指 0.001 / 闪避上限 0.9 | 待处理 | F1 |
| T-014 | route_generator.gd:34-40 | MIN_ELITE_WAVE=6/MAX_BATTLE_NODES=36/BOSS_WAVE=10 写死 | 待处理 | F1 |
| T-015 | enemy.gd:190,212,762 | 击退衰减 0.5 / 接触冷却 0.5 / 护甲上限 0.75 | 待处理 | F1 |

## 配置型数据结构（.gd 内建配置，应抽表）

| 编号 | 位置 | 问题 | 状态 | 阶段 |
|---|---|---|---|---|
| T-016 | enemy.gd:76-110 | SPRITE_MAP（26 条敌人精灵路径/尺寸/FPS/hit_radius）+ FALLBACK_SPRITES | 待处理 | F1 |
| T-017 | enemy.gd:32-42 | BEHAVIOR_MAP（行为字符串→枚举） | 待处理 | F1 |
| T-018 | audio_manager.gd:8-23 | BGM_MAP / SFX_MAP | 待处理 | F1 |
| T-019 | vfx_player.gd:17-29 | FX_CONFIG（特效帧配置） | 待处理 | F1 |
| T-020 | icon_atlas.gd:8-24 | SHEET_CONFIG（图标帧数） | 待处理 | F1 |
| T-021 | player.gd:56-74 | STAT_MAP 17 键 vs items.json 39 键（P0-Bug2 已修收口，余无消费方键另登记） | 已收口(F0) | 已修 |
| T-022 | hud.gd:240-245 | SKILL_ICON_MAP（技能 id→图标帧索引） | 待处理 | F1 |
| T-023 | route_generator.gd:24-40 / base_station.gd:9-13 | 默认参数 + RESEARCH_ITEMS（研究倍率与 game_manager.gd:705-718 重复） | 待处理 | F1 |
| T-024 | turret.gd:13-15 | 炮台默认值与 se_auto_turret 数据重复 | 待处理 | F1 |

## 硬编码字符串（业务 id/路径/组名）

| 编号 | 位置 | 问题 | 状态 | 阶段 |
|---|---|---|---|---|
| T-025 | character_select.gd:15 | HERO_IDS 与 characters.json 重复（base_station 已改 DataLoader，两处口径不一） | 待处理 | F1 |
| T-026 | shop.gd:112,140 / main.gd:197 / player.gd:452 / projectile.gd:191 | 机制道具 id 散落 4 文件（se_blade_core/executioner_mark/last_stand/overload_capacitor） | 待处理 | F1 |
| T-027 | skill_controller.gd:74-79,137,156,172 | 技能/武器 id 字面量（se_skill_fireball/se_auto_turret/se_turret_array） | 待处理 | F1 |
| T-028 | hud.gd:241-244 | 技能 id→图标帧索引映射 | 待处理 | F1 |
| T-029 | projectile.gd:143,145 | se_star_fall/se_skill_fireball 特效分派 | 待处理 | F1 |
| T-030 | enemy.gd:117 / enemy_spawner.gd:64 / wave_manager.gd:150 | 默认敌人 id "chaser" 多处 | 待处理 | F1 |

## 状态机

| 编号 | 位置 | 问题 | 状态 | 阶段 |
|---|---|---|---|---|
| T-031 | game_manager.gd:118,144,165,202,246,357,574,592 | current_state= 8 处散赋，各自内联副作用，无统一 transition | 待处理 | F3 |
| T-032 | game_manager.gd | 局状态四维正交：current_state × route.is_empty × _shop_from_battle × is_boss_wave | 待处理 | F3 |
| T-033 | enemy.gd:152-159,378-384 | Boss 阶段机 int 下标 + 4 个并行 bool | 待处理 | F3 |
| T-034 | player.gd:87-100,300,315,332 | 5 bool + 字符串动画态（attack/skill/hit）无状态机 | 待处理 | F3 |
| T-035 | enemy.gd:116,123,170,777 | is_alive + _is_dying 双标志冗余 | 待处理 | F3 |
| T-036 | game_manager.gd:231 / audio_manager.gd:90 | 状态类型混乱：route 节点字符串 match + audio int 字面量 | 待处理 | F3 |

## 边界与职责

| 编号 | 位置 | 问题 | 状态 | 阶段 |
|---|---|---|---|---|
| T-037 | shop.gd:346 | UI 直读 economy.coins | 待处理 | F2 |
| T-038 | shop.gd:359,380 | UI 直读 player.get_node_or_null("WeaponController") | 待处理 | F2 |
| T-039 | shop.gd:384-386 | UI 手动回滚 inventory（remove_weapon 直调） | 待处理 | F2 |
| T-040 | hud.gd:294,307,129-136 | UI 直读 inv.weapons/items + 轮询敌人容器 | 待处理 | F2 |
| T-041 | base_station.gd:141-144 | UI 直读 meta_progress 内部字典 | 待处理 | F2 |
| T-042 | player.gd:470 / enemy.gd:784-802 | 实体直调核心系统（end_game/register_boss_killed/add_coins/gain_exp） | 待处理 | F2 |
| T-043 | skill_controller.gd:176 / turret.gd:147 / weapon_controller.gd:41 | 跨层节点树访问三份复制（get_parent→Projectiles） | 待处理 | F2 |
| T-044 | enemy.gd:735 / weapon_controller.gd:376 / skill_controller.gd:180 | 实体直接 new 实体（弹丸/环绕刃/炮台） | 待处理 | F2 |
| T-045 | wave_manager.gd:61-62,96-100 | 系统直调 spawner 私有字段（_is_spawning/spawn_queue） | 待处理 | F2 |
| T-046 | game_manager.gd（754 行） | 上帝脚本：状态机+存档+面板工厂+事件系统四合一 | 待处理 | F2/F4 |
| T-047 | enemy.gd（882 行） | 上帝脚本：行为+元素+阶段机+受伤掉落+动画八合一 | 待处理 | F4 |
| T-048 | player.gd（610 行） | 上帝脚本：移动+属性+被动+经验+动画五职责 | 待处理 | F4 |

## 数据一致性

| 编号 | 位置 | 问题 | 状态 | 阶段 |
|---|---|---|---|---|
| T-049 | data_loader.gd | get_wave_generation()/get_formulas() 全项目零消费（并入 T-002/003/006 处理） | 待处理 | F1 |
| T-050 | items.json / player.gd | 无消费方效果键 22 个（harvesting/engineering/melee_damage/ranged_damage/knockback/xp_gain_percent/fire_damage_percent/burn_duration_percent/structure_duration_percent/miss_chance_percent/dodge_heal_* 等）：P0-Bug2 已收进 bonus_stats 不丢数，需逐键决定「接线 or 删死数据」 | 待处理 | F1 |
| T-051 | skill_controller.gd:73 | se_skill_holy_shield 未实装（P0-Bug1 已修 ✓） | 已收口(F0) | 已修 |
| T-052 | characters.json well_rounded | harvesting:3 死数据（无消费方） | 待处理 | F1 |
| T-053 | enemy_spawner.gd:126 | 补 stats.wave_number 但 get_scaled_enemy() 返回值不含该键，Boss 召唤物路径拿不到 | 待处理 | F1 |

## 处理顺序备注
1. F0 已修：T-021（P0-Bug2 收口）、T-051（P0-Bug1 实装）；新探针 day30_p0_fix_check.gd（15 断言）
2. F1 按 T-001→T-015（公式接数据）+ T-016→T-024（抽表）+ T-025→T-030（id 收敛）+ T-050 逐键裁决
3. T-050 裁决原则：有潜在消费点（如 knockback→武器击退、xp_gain_percent→gain_exp）优先接线；纯设计残留（harvesting）删表或留档
