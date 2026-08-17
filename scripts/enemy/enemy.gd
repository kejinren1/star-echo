## 敌人基类脚本（所有敌人类型继承；数据由 DataLoader.get_scaled_enemy() 提供并传入 initialize()）
## F4-A（2026-08-14 · T-047）：移动/Boss/受伤掉落三域拆分（enemy_movement/enemy_boss/enemy_damage）
extends CharacterBody2D

# ========== 信号 ==========

signal died(enemy: Node)
signal health_changed(current_hp: float, max_hp: float)
## F2-T5（T-045）：Boss 击杀信号（die 内 is_boss 时 emit；main 装配订阅 GM.register_boss_killed）
signal boss_killed
## BS-A2（2026-08-13）：持续效果变化（HUD 状态栏/探针订阅）
signal status_changed

## BS-A2（2026-08-13）：通用持续效果组件（无 class_name，preload 范式——探针 --script 兼容）
const StatusComponentScript: GDScript = preload("res://scripts/systems/status_component.gd")
## F4-A（2026-08-14）：共享枚举/常量（纯枚举文件零 Autoload 引用——组件经此引用，探针可编译）
const EnemyEnums: GDScript = preload("res://scripts/enemy/enemy_enums.gd")

## 行为字符串 → 枚举映射（定义见 enemy_enums.gd，F4-A 迁出）
const BEHAVIOR_MAP: Dictionary = EnemyEnums.BEHAVIOR_MAP

# ========== 导出属性 ==========

@export_group("基础属性")
@export var max_health: float = 30.0         ## 最大生命值
@export var move_speed: float = 120.0        ## 移动速度
@export var damage: float = 10.0             ## 接触伤害
@export var coin_value: int = 1              ## 死亡掉落金币
@export var exp_value: int = 1               ## 死亡掉落经验
@export var armor: float = 0.0               ## 敌人护甲

@export_group("高级属性")
@export var is_elite: bool = false           ## 是否精英怪
@export var is_boss: bool = false            ## 是否 Boss
@export var detection_range: float = 600.0   ## 检测玩家范围

@export_group("精灵配置")
@export var move_texture: Texture2D           ## 移动动画 sprite sheet
@export var death_texture: Texture2D          ## 死亡动画 sprite sheet
@export var frame_size: Vector2i = Vector2i(32, 32)  ## 单帧尺寸
## D21-22-T1（决策 D16）：接触判定半径（换皮解耦；_setup_animation 按 SPRITE_MAP/FALLBACK 覆盖）
@export var hit_radius: float = -1.0          ## 接触伤害判定半径（缺省 = frame_size.x*0.5+12.0）
@export var move_fps: float = 6.0             ## 移动动画 FPS
@export var death_fps: float = 8.0            ## 死亡动画 FPS
@export var move_frame_count: int = 4         ## 移动动画帧数
@export var death_frame_count: int = 4        ## 死亡动画帧数

# ========== 精灵类型映射（定义见 enemy_enums.gd，F4-A 迁出；外部引用兼容别名） ==========
const SPRITE_MAP: Dictionary = EnemyEnums.SPRITE_MAP
const FALLBACK_SPRITES: Dictionary = EnemyEnums.FALLBACK_SPRITES

# ========== 内部状态 ==========

var health: float
var target: Node2D                           ## 追踪目标（玩家）
var is_alive: bool = true
var enemy_id: String = "chaser"             ## 敌人 ID (对应 DataLoader)
var enemy_category: String = "regular"      ## 敌人分类: regular/elite/boss
var behavior: EnemyEnums.Behavior = EnemyEnums.Behavior.CHASE     ## 行为模式

# 动画
var _anim: AnimatedSprite2D

# 行为状态
var _zigzag_timer: float = 0.0
var _zigzag_dir: float = 1.0
var _charge_timer: float = 0.0
var _is_charging: bool = false
var _charge_dir: Vector2 = Vector2.ZERO
## T-009（F1-散 2026-08-13）：冲锋参数（initialize 从 get_scaled_enemy 透传，
## 默认值 = 现硬编码值 1.5/2.0/0.8，行为零改动；enemies.json scaling 扩展键）
var _charge_speed_mult: float = 1.5   ## 冲锋速度倍率（原 _move_charge :424 字面量 1.5）
var _charge_windup: float = 2.0       ## 蓄力间隔秒（原 :428 字面量 2.0）
var _charge_duration: float = 0.8     ## 冲锋持续秒（原 :437 字面量 0.8）

# 接触伤害冷却（避免每帧对玩家造成伤害）
var _contact_cd: float = 0.0
## T-015（F1-散 2026-08-13）：战斗参数（initialize 取表缓存一次；默认 = 现硬编码值）
var _knockback_decay: float = 0.5     ## 击退每帧衰减（原 _process_knockback 字面量 0.5）
var _contact_cooldown: float = 0.5    ## 接触伤害冷却秒（原 _try_contact_damage 字面量 0.5）

## 受击击退（H-01 升级体验反馈 2026-08-07：升级冲击波等外部施加，每帧衰减）
var _knockback: Vector2 = Vector2.ZERO

# 持续效果（BS-A2 · 2026-08-13）：通用 StatusComponent 组件（enemy._ready 挂载，
# O1 叠加规则：同源刷新/异源独立 + max_stacks；dot/slow/stun/armor 四类型统一）
var _status_component: Node = null
## O2 软控运行时（BS-A3 · 2026-08-13）：麻痹标志（StatusComponent stun 效果置位；
## 禁行动——_physics_process 跳过行为 + _try_contact_damage 跳过；玩家侧 _handle_movement 跳过）
var stunned: bool = false

# 精英能力（Day 17 · D17-T2）：由 enemies.json 精英 ability 字段数据驱动
# {type: "aoe"/"self_heal"/"spawn", ...参数}；缺省 = 无特殊能力（零行为回归）
var ability: Dictionary = {}
## 自身波次（产卵用同波缩放：DataLoader.get_scaled_enemy(minion, wave_number)）
var wave_number: int = 1
var _ability_timer: float = 0.0

# ========== Boss 阶段（Day 18-19 · T1/T2 + F3-T4 枚举化） ==========
## phases 状态机（take_damage 阈值切换 + attacks 指令执行）；`is_boss and not phases.is_empty()`
## 双条件守卫——普通/精英零新行为；BossPhase/PHASE_TABLE 定义见 enemy_enums.gd（F3-T4 枚举化）
var phases: Array = []                       ## Boss 阶段定义（get_scaled_enemy 恒返回 phases 键透传）
const PHASE_TABLE: Dictionary = EnemyEnums.PHASE_TABLE
var _phase: EnemyEnums.BossPhase = EnemyEnums.BossPhase.P1   ## 当前阶段（P1 起；_transition_phase 统一推进）
var _attack_timers: Dictionary = {}          ## 攻击计时器: cmd -> {parsed: Dictionary, timer: float}
var _attack_mult: float = 1.0                ## 阶段修饰符（决策 D3：all_attacks_2x → ×2.0，仅伤害类生效）
var _boss_charge: bool = false               ## 冲锋置位（决策 D2：charge 型指令置位后 _move_charge 自动生效）
var _boss_charge_mult: float = 1.0           ## 冲锋命中伤害倍率（_try_contact_damage 消费，普通敌人恒 1.0）
var _base_speed: float = 120.0               ## 基础移速（阶段 speed_multiplier 基准，F-15 移动倍率零改动）
var _rng := RandomNumberGenerator.new()      ## 攻击随机源（探针可注 _rng.seed；禁 Array.shuffle/pick_random 全局 RNG）
var _barrage_wave: int = 0                   ## barrage 剩余波次（决策 D4：8 向 × 3 波）
var _barrage_timer: float = 0.0              ## barrage 波间隔计时（0.25s）
## BS-C2（BOSS_SKILL_SPEC §7-3）：Boss pattern 技能循环优先接管，旧 attacks 降级
## （无 pattern 数据 → 行为完全等价，day18_19 回归兜底）
var _patterns: Array = []                    ## 本 Boss pattern 行（initialize 按 enemy_id 取）
var _pattern_cooldown: float = 0.0           ## pattern 释放冷却（min_interval/技能 cooldown 最大值）
var _pattern_cooldown_total: float = 0.0     ## 本次冷却总量（探针观测用）
var _last_pattern_skill: String = ""         ## 保底：同技能不连续 2 次
var _active_executor: Node = null            ## 当前四拍子执行器（boss_skill_factory 创建）

# ========== F4-A 拆分组件（2026-08-14 · T-047） ==========
## 三域组件（movement/boss/damage）_ensure_components 挂载；宿主 load() 创建
## （组件 preload enemy_enums.gd 取枚举——enemy.gd 引用 Autoload 不可被组件 preload）
var _movement: Node = null
var _boss_ctrl: Node = null
var _damage: Node = null

# ========== 生命周期 ==========

func _ready() -> void:
	health = max_health
	health_changed.emit(health, max_health)
	_setup_animation()
	_ensure_components()
	# BS-A2：挂载通用持续效果组件
	_status_component = StatusComponentScript.new()
	_status_component.name = "StatusComponent"
	add_child(_status_component)
	_status_component.setup(self)

## F4-A：组件懒挂载（initialize 先于 _ready → 此处保证组件就绪；幂等）
func _ensure_components() -> void:
	if _movement == null:
		_movement = (load("res://scripts/enemy/enemy_movement.gd") as GDScript).new()
		_movement.name = "MovementController"
		add_child(_movement)
		_movement.setup(self)
	if _boss_ctrl == null:
		_boss_ctrl = (load("res://scripts/enemy/enemy_boss.gd") as GDScript).new()
		_boss_ctrl.name = "BossController"
		add_child(_boss_ctrl)
		_boss_ctrl.setup(self)
	if _damage == null:
		_damage = (load("res://scripts/enemy/enemy_damage.gd") as GDScript).new()
		_damage.name = "DamageController"
		add_child(_damage)
		_damage.setup(self)

func _physics_process(delta: float) -> void:
	if not is_alive:
		return
	# BS-A2：StatusComponent 自 tick（dot 可能同帧击杀）
	if not is_alive:
		return
	# F4-A：行为/接触/击退 → movement 组件
	if _movement:
		_movement.tick(delta)

# ========== 动画 ==========

func _setup_animation() -> void:
	_anim = get_node_or_null("AnimatedSprite2D")
	if not _anim:
		return
	# F1-E（2026-08-18 总指挥第一批）：精灵表现配置数据化——presentation.json 优先，
	# 未命中按分类回退 enemy_enums.gd const SPRITE_MAP/FALLBACK（缺省兜底零回归）
	var cfg: Dictionary = DataLoader.get_enemy_sprite_config(enemy_id, enemy_category)
	move_texture = load(cfg["move"])
	death_texture = load(cfg["death"])
	frame_size = cfg["size"]
	# D21-22-T1（决策 D16）：接触半径从配置读，缺省 = 旧公式兜底零回归
	hit_radius = float(cfg.get("hit_radius", frame_size.x * 0.5 + 12.0))
	move_frame_count = cfg["move_frames"]
	death_frame_count = cfg["death_frames"]
	move_fps = cfg["move_fps"]
	death_fps = cfg["death_fps"]
	# PS（2026-08-17 丰富性）：tint 色调区分 / scale 体型区分（Boss 保持 ×1 零回归）
	if cfg.has("tint"):
		_anim.modulate = cfg["tint"]
	if cfg.has("scale"):
		scale = Vector2(float(cfg["scale"]), float(cfg["scale"]))
	if not move_texture:
		return
	# 构建 SpriteFrames
	var sf := SpriteFrameFactory.create_multi([
		{"texture": move_texture, "frame_count": move_frame_count, "frame_size": frame_size, "fps": move_fps, "loop": true, "name": "move"},
		{"texture": death_texture, "frame_count": death_frame_count, "frame_size": frame_size, "fps": death_fps, "loop": false, "name": "death"},
	])
	_anim.sprite_frames = sf
	_anim.play("move")
	# 根据精灵尺寸动态调整碰撞体（比精灵略小，避免"没碰到就被打到"）
	_resize_collision_shape()

## 根据当前 frame_size 调整碰撞体尺寸
func _resize_collision_shape() -> void:
	var col := get_node_or_null("CollisionShape2D")
	if not col:
		return
	# 碰撞体比精灵略小（80%），居中
	var col_size := Vector2(frame_size.x * 0.8, frame_size.y * 0.8)
	var shape := RectangleShape2D.new()
	shape.size = col_size
	col.shape = shape

# ========== 持续效果（BS-A2 · 元素状态机迁入 StatusComponent） ==========
# O1 叠加规则（用户 2026-08-12 拍板）：同源刷新不叠层/异源独立/max_stacks 上限；
# DoT 不走 take_damage()（无视护甲 + 免逐帧受击闪烁）；旧「取更长+dps」行为变化交 #5 登记

## 统一施加入口（BS-A3）：source_id = 来源标识（武器 id / 技能 id / "legacy:" 兜底）
func apply_effect(source_id: String, effect_id: String, params: Dictionary = {}) -> void:
	if not is_alive:
		return
	if effect_id.is_empty():
		return
	if _status_component:
		_status_component.apply_effect(source_id, effect_id, params)

## 旧接口兼容（兜底 source = "legacy:"+effect_id → 同源刷新语义）
func apply_status(status_type: String, duration: float, dps: float) -> void:
	if not is_alive:
		return
	if status_type.is_empty() or duration <= 0.0:
		return
	if _status_component:
		_status_component.apply_effect("legacy:" + status_type, status_type, {"duration": duration, "dps": dps})

## 查询是否处于某状态（供 UI / 测试断言；day3 探针 has_status("fire") 兼容）
func has_status(status_type: String) -> bool:
	if _status_component:
		return _status_component.has_effect(status_type)
	return false

## 查询某状态剩余时间，未附着返回 0
func get_status_time_left(status_type: String) -> float:
	if _status_component:
		return _status_component.get_remaining(status_type)
	return 0.0

## 持续伤害入口（StatusComponent dot 调用）：无视护甲、不播受击闪烁，致死走正常死亡流程
func take_status_damage(amount: float) -> void:
	if not is_alive or amount <= 0.0:
		return
	health -= amount
	health_changed.emit(health, max_health)
	if health <= 0.0:
		die()

## 受击闪烁
func _play_hit_flash() -> void:
	if not _anim:
		return
	_anim.modulate = Color(1, 0.4, 0.4)
	var tw := create_tween()
	tw.tween_property(_anim, "modulate", Color.WHITE, 0.1)

# ========== 通用工具（movement/boss 组件共用） ==========

## 目标有效性检查（target 无效或已死 → false）
func is_target_valid() -> bool:
	if not is_instance_valid(target):
		return false
	if target.get("is_alive") != null:
		return target.is_alive
	return true

## 特效容器解析：vfx_container → current_scene → null（无容器静默跳过不崩；组件共用）
func _resolve_fx_container() -> Node:
	if GameManager and GameManager.vfx_container:
		return GameManager.vfx_container
	if get_tree() and get_tree().current_scene:
		return get_tree().current_scene
	return null

# ========== 薄委托（F4-A：组件方法转发——探针白盒动态调用点零改动硬门槛） ==========
# → enemy_movement
func _try_contact_damage() -> void:
	if _movement: _movement._try_contact_damage()

func apply_knockback(dir: Vector2, force: float) -> void:  # player.gd 升级冲击波消费
	if _movement: _movement.apply_knockback(dir, force)

func _elite_aoe(delta: float) -> void:  # day17_elite 探针
	if _movement: _movement._elite_aoe(delta)

func _elite_self_heal(delta: float) -> void:  # day17_elite 探针
	if _movement: _movement._elite_self_heal(delta)

func _elite_spawn(delta: float) -> void:  # day17_elite 探针
	if _movement: _movement._elite_spawn(delta)

func _process_knockback() -> void:  # day18_feedback3 探针（升级冲击波击退）
	if _movement: _movement._process_knockback()

# → enemy_boss
func _parse_attack(cmd: String) -> Dictionary:  # day18_19 探针
	if _boss_ctrl: return _boss_ctrl._parse_attack(cmd)
	return {}

func _transition_phase(next: int) -> void:  # day30_boss_skill 探针（int = BossPhase 枚举值）
	if _boss_ctrl: _boss_ctrl._transition_phase(next)

func _process_boss_patterns(delta: float) -> void:  # day30_boss_skill 探针
	if _boss_ctrl: _boss_ctrl._process_boss_patterns(delta)

func _pick_and_cast() -> void:  # day30_boss_skill 探针
	if _boss_ctrl: _boss_ctrl._pick_and_cast()

func _active_pattern_pool() -> Array:  # day30_boss_skill 探针
	if _boss_ctrl: return _boss_ctrl._active_pattern_pool()
	return []

func _compose_skill_params(pattern: Dictionary) -> Dictionary:  # day30_boss_skill 探针
	if _boss_ctrl: return _boss_ctrl._compose_skill_params(pattern)
	return {}

func _boss_summon(count: int, elite: bool) -> void:  # day18_19 探针
	if _boss_ctrl: _boss_ctrl._boss_summon(count, elite)

func _boss_spread(count: int) -> void:  # day18_19 探针
	if _boss_ctrl: _boss_ctrl._boss_spread(count)

func _boss_aoe() -> void:  # day18_19 探针
	if _boss_ctrl: _boss_ctrl._boss_aoe()

func _compose_difficulty_coeff() -> float:  # day30_boss_skill 探针
	if _boss_ctrl:
		return _boss_ctrl._compose_difficulty_coeff()
	return 1.0

# → enemy_damage
func take_damage(amount: float, is_crit: bool = false) -> void:  # player/探针 取血消费
	if _damage: _damage.take_damage(amount, is_crit)

func die() -> void:  # day4/day18_19 探针
	if _damage: _damage.die()

# ========== 初始化接口 ==========

## 从 DataLoader.get_scaled_enemy() 返回的字典初始化敌人属性
func initialize(stats: Dictionary) -> void:
	# F4-A：组件先挂载（initialize 先于 _ready；_reset_boss_phase 需 _boss_ctrl 就绪）
	_ensure_components()
	if stats.has("id"):
		enemy_id = stats["id"]
	if stats.has("category"):
		enemy_category = stats["category"]
	if stats.has("max_health"):
		max_health = stats["max_health"]
	if stats.has("move_speed"):
		move_speed = stats["move_speed"]
	if stats.has("damage"):
		damage = stats["damage"]
	if stats.has("coin_value"):
		coin_value = stats["coin_value"]
	if stats.has("armor"):
		armor = stats["armor"]
	if stats.has("exp_value"):
		exp_value = int(stats["exp_value"])
	if stats.has("behavior"):
		var behav_str: String = stats["behavior"]
		behavior = DataLoader.get_enemy_behavior(behav_str)
	# Day 17 · D17-T2：精英能力 + 波次（产卵缩放）
	if stats.has("ability"):
		ability = stats["ability"]
	if stats.has("wave_number"):
		wave_number = int(stats["wave_number"])
	# T-009（F1-散 2026-08-13）：冲锋参数透传（get_scaled_enemy 返回键；缺键保持默认）
	if stats.has("charge_speed_mult"):
		_charge_speed_mult = float(stats["charge_speed_mult"])
	if stats.has("charge_windup"):
		_charge_windup = float(stats["charge_windup"])
	if stats.has("charge_duration"):
		_charge_duration = float(stats["charge_duration"])
	# T-015（F1-散 2026-08-13）：战斗参数取表缓存（击退衰减/接触冷却；
	# 缺表兜底 = 现硬编码值；armor_cap 为保留参数无消费点——F1-C 平直减公式无钳制语义）
	var combat: Dictionary = DataLoader.get_stats_combat()
	_knockback_decay = float(combat.get("knockback_decay", 0.5))
	_contact_cooldown = float(combat.get("contact_cooldown", 0.5))
	# 根据 category 设置标记
	match enemy_category:
		"elite":
			is_elite = true
		"boss":
			is_boss = true
	# Day 18-19 · T1：Boss 阶段初始化（phases 透传 + 激活初始阶段）
	# D21-22-T1（决策 D17）：128px 真精灵 → scale 复位 ×1（旧 skeleton 32px ×2 视觉过渡废弃）
	if stats.has("phases"):
		phases = stats["phases"]
	# BS-C2：Boss pattern 行加载（enemy_id 匹配 boss_patterns.json；无 → 旧 attacks 降级）
	if is_boss:
		_patterns = DataLoader.get_boss_patterns(enemy_id)
	_base_speed = move_speed
	if is_boss and not phases.is_empty():
		_boss_ctrl._reset_boss_phase(0)
		scale = Vector2(1.0, 1.0)
	health = max_health
	health_changed.emit(health, max_health)

## 设置追踪目标
func set_target(t: Node2D) -> void:
	target = t
