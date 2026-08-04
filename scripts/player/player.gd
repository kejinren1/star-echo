## 玩家角色脚本
## 处理移动、属性、受伤、自动攻击触发
extends CharacterBody2D

# ========== 信号 ==========

signal died
signal health_changed(current_hp: float, max_hp: float)
signal stats_changed
signal took_damage(amount: float)

# ========== 导出属性 ==========

@export_group("基本属性")
@export var max_health: float = 100.0       ## 最大生命值
@export var move_speed: float = 300.0        ## 移动速度 (像素/秒)
@export var armor: float = 0.0               ## 护甲 (减伤)
@export var dodge: float = 0.0               ## 闪避率 (0~1)
@export var regen: float = 0.0               ## 每秒回复生命

@export_group("战斗属性")
@export var damage_multiplier: float = 1.0   ## 伤害倍率
@export var attack_speed: float = 1.0        ## 攻速倍率
@export var crit_chance: float = 0.05        ## 暴击率
@export var crit_damage: float = 2.0         ## 暴击伤害倍率
@export var range_multiplier: float = 1.0    ## 攻击范围倍率
@export var pickup_range: float = 80.0       ## 拾取范围

@export_group("经济属性")
@export var coin_bonus: float = 0.0          ## 金币加成 (0~1)
@export var luck: float = 0.0                ## 幸运值 (影响商店品质)

@export_group("精灵资源")
@export var idle_texture: Texture2D          ## idle 动画 sprite sheet
@export var walk_texture: Texture2D          ## walk 动画 sprite sheet
@export var frame_size: Vector2i = Vector2i(32, 32)  ## 单帧尺寸
@export var idle_fps: float = 6.0            ## idle 动画 FPS
@export var walk_fps: float = 10.0           ## walk 动画 FPS

# ========== 内部状态 ==========

var health: float                            ## 当前生命值
var is_alive: bool = true
var _invulnerable_timer: float = 0.0         ## 无敌帧计时

# 动画
var _anim: AnimatedSprite2D
var _is_walking: bool = false

# ========== 生命周期 ==========

func _ready() -> void:
	health = max_health
	health_changed.emit(health, max_health)
	_setup_animation()

# ========== 动画 ==========

func _setup_animation() -> void:
	_anim = get_node_or_null("AnimatedSprite2D")
	if not _anim:
		return
	# 如果未通过 @export 指定纹理，尝试从默认路径加载
	if not idle_texture:
		idle_texture = load("res://assets/sprites/characters/fighter_idle.png")
	if not walk_texture:
		walk_texture = load("res://assets/sprites/characters/fighter_walk.png")
	if not idle_texture or not walk_texture:
		return
	# 构建 SpriteFrames
	var sf := SpriteFrameFactory.create_multi([
		{"texture": idle_texture, "frame_count": 4, "frame_size": frame_size, "fps": idle_fps, "loop": true, "name": "idle"},
		{"texture": walk_texture, "frame_count": 6, "frame_size": frame_size, "fps": walk_fps, "loop": true, "name": "walk"},
	])
	_anim.sprite_frames = sf
	_anim.play("idle")

func _update_animation() -> void:
	if not _anim:
		return
	var moving := velocity.length() > 10.0
	if moving and not _is_walking:
		_is_walking = true
		_anim.play("walk")
	elif not moving and _is_walking:
		_is_walking = false
		_anim.play("idle")

## 受击闪烁特效
func _play_hit_flash() -> void:
	if not _anim:
		return
	_anim.modulate = Color(1, 0.3, 0.3)
	var tw := create_tween()
	tw.tween_property(_anim, "modulate", Color.WHITE, 0.15)

func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	_handle_movement()
	_handle_regeneration(delta)

	if _invulnerable_timer > 0.0:
		_invulnerable_timer -= delta

# ========== 移动 ==========

func _handle_movement() -> void:
	var input_vector := Vector2.ZERO
	input_vector.x = Input.get_axis("move_left", "move_right")
	input_vector.y = Input.get_axis("move_up", "move_down")
	input_vector = input_vector.normalized()

	velocity = input_vector * move_speed
	move_and_slide()
	_update_animation()

# ========== 生命与受伤 ==========

func _handle_regeneration(delta: float) -> void:
	if regen > 0.0 and health < max_health:
		heal(regen * delta)

## 受到伤害
func take_damage(amount: float) -> void:
	if not is_alive or _invulnerable_timer > 0.0:
		return

	# 闪避判定
	if randf() < dodge:
		return

	# 护甲减伤
	var actual_damage: float = max(amount - armor, 1.0)
	health -= actual_damage
	health_changed.emit(health, max_health)
	took_damage.emit(actual_damage)
	_play_hit_flash()
	# 短无敌帧，避免被群体敌人每帧叠伤
	_invulnerable_timer = 0.4

	if health <= 0.0:
		die()

## 治疗
func heal(amount: float) -> void:
	health = min(health + amount, max_health)
	health_changed.emit(health, max_health)

## 死亡
func die() -> void:
	is_alive = false
	health = 0.0
	health_changed.emit(health, max_health)
	died.emit()
	GameManager.end_game(false)

# ========== 属性修改接口 ==========

## 应用属性修改 (供道具系统调用)
func apply_stat_modifier(stat_name: String, value: float, is_multiplicative: bool = false) -> void:
	match stat_name:
		"max_health":
			if is_multiplicative:
				max_health *= value
			else:
				max_health += value
			health = min(health, max_health)
		"move_speed":
			move_speed = apply_value(move_speed, value, is_multiplicative)
		"armor":
			armor = apply_value(armor, value, is_multiplicative)
		"damage":
			damage_multiplier = apply_value(damage_multiplier, value, is_multiplicative)
		"attack_speed":
			attack_speed = apply_value(attack_speed, value, is_multiplicative)
		"crit_chance":
			crit_chance = apply_value(crit_chance, value, is_multiplicative)
		"range":
			range_multiplier = apply_value(range_multiplier, value, is_multiplicative)
		"regen":
			regen = apply_value(regen, value, is_multiplicative)
		"pickup_range":
			pickup_range = apply_value(pickup_range, value, is_multiplicative)
	stats_changed.emit()

func apply_value(base: float, mod: float, multiplicative: bool) -> float:
	if multiplicative:
		return base * mod
	else:
		return base + mod
