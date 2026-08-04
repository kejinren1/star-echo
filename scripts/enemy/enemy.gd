## 敌人基类脚本
## 所有敌人类型（普通/精英/Boss）继承此类
## 数据由 DataLoader.get_scaled_enemy() 提供并传入 initialize()
extends CharacterBody2D

# ========== 信号 ==========

signal died(enemy: Node)
signal health_changed(current_hp: float, max_hp: float)

# ========== 行为枚举 ==========

enum Behavior {
	CHASE,       ## 直追玩家
	CHARGE,      ## 冲锋：蓄力后高速冲向玩家
	ZIGZAG,      ## Z 形移动
	RANGED,      ## 远程：保持距离射击
	HEAL,        ## 治疗：治疗附近友军
	SPAWN,       ## 产卵：定期生成小怪
	STATIONARY,  ## 静止：不移动
	AOE_ATTACK,  ## AOE 攻击 (精英)
	SELF_HEAL,   ## 自愈 (精英)
}

## 行为字符串 → 枚举映射
const BEHAVIOR_MAP: Dictionary = {
	"chase": Behavior.CHASE,
	"charge": Behavior.CHARGE,
	"zigzag": Behavior.ZIGZAG,
	"ranged": Behavior.RANGED,
	"heal": Behavior.HEAL,
	"spawn": Behavior.SPAWN,
	"stationary": Behavior.STATIONARY,
	"aoe_attack": Behavior.AOE_ATTACK,
	"self_heal": Behavior.SELF_HEAL,
}

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
@export var move_fps: float = 6.0             ## 移动动画 FPS
@export var death_fps: float = 8.0            ## 死亡动画 FPS
@export var move_frame_count: int = 4         ## 移动动画帧数
@export var death_frame_count: int = 4        ## 死亡动画帧数

# ========== 精灵类型映射 ==========
## 敌人 ID → 精灵配置
## 未命中时按 category 回退: regular→slime, elite/boss→skeleton
const SPRITE_MAP: Dictionary = {
	# 普通敌人 → slime 精灵
	"chaser":           {"move": "res://assets/sprites/enemies/slime_move.png",   "death": "res://assets/sprites/enemies/slime_death.png",   "size": Vector2i(24, 24), "move_frames": 2, "death_frames": 4, "move_fps": 6.0, "death_fps": 8.0},
	"charger":          {"move": "res://assets/sprites/enemies/slime_move.png",   "death": "res://assets/sprites/enemies/slime_death.png",   "size": Vector2i(24, 24), "move_frames": 2, "death_frames": 4, "move_fps": 8.0, "death_fps": 8.0},
	"fly":              {"move": "res://assets/sprites/enemies/slime_move.png",   "death": "res://assets/sprites/enemies/slime_death.png",   "size": Vector2i(24, 24), "move_frames": 2, "death_frames": 4, "move_fps": 8.0, "death_fps": 8.0},
	"bruiser":          {"move": "res://assets/sprites/enemies/slime_move.png",   "death": "res://assets/sprites/enemies/slime_death.png",   "size": Vector2i(32, 32), "move_frames": 2, "death_frames": 4, "move_fps": 5.0, "death_fps": 8.0},
	"spitter":          {"move": "res://assets/sprites/enemies/slime_move.png",   "death": "res://assets/sprites/enemies/slime_death.png",   "size": Vector2i(24, 24), "move_frames": 2, "death_frames": 4, "move_fps": 6.0, "death_fps": 8.0},
	"healer":           {"move": "res://assets/sprites/enemies/slime_move.png",   "death": "res://assets/sprites/enemies/slime_death.png",   "size": Vector2i(24, 24), "move_frames": 2, "death_frames": 4, "move_fps": 6.0, "death_fps": 8.0},
	"spawner":          {"move": "res://assets/sprites/enemies/slime_move.png",   "death": "res://assets/sprites/enemies/slime_death.png",   "size": Vector2i(32, 32), "move_frames": 2, "death_frames": 4, "move_fps": 4.0, "death_fps": 8.0},
	"horned_charger":   {"move": "res://assets/sprites/enemies/slime_move.png",   "death": "res://assets/sprites/enemies/slime_death.png",   "size": Vector2i(24, 24), "move_frames": 2, "death_frames": 4, "move_fps": 8.0, "death_fps": 8.0},
	"pursuer":          {"move": "res://assets/sprites/enemies/slime_move.png",   "death": "res://assets/sprites/enemies/slime_death.png",   "size": Vector2i(32, 32), "move_frames": 2, "death_frames": 4, "move_fps": 5.0, "death_fps": 8.0},
	"slasher":          {"move": "res://assets/sprites/enemies/skeleton_move.png", "death": "res://assets/sprites/enemies/skeleton_death.png", "size": Vector2i(32, 32), "move_frames": 4, "death_frames": 4, "move_fps": 6.0, "death_fps": 8.0},
	"helmet_alien":     {"move": "res://assets/sprites/enemies/slime_move.png",   "death": "res://assets/sprites/enemies/slime_death.png",   "size": Vector2i(24, 24), "move_frames": 2, "death_frames": 4, "move_fps": 6.0, "death_fps": 8.0},
	"horned_fly":       {"move": "res://assets/sprites/enemies/slime_move.png",   "death": "res://assets/sprites/enemies/slime_death.png",   "size": Vector2i(24, 24), "move_frames": 2, "death_frames": 4, "move_fps": 8.0, "death_fps": 8.0},
	"corrupted_tree":   {"move": "res://assets/sprites/enemies/slime_move.png",   "death": "res://assets/sprites/enemies/slime_death.png",   "size": Vector2i(32, 32), "move_frames": 2, "death_frames": 4, "move_fps": 2.0, "death_fps": 8.0},
	"mad_slasher":      {"move": "res://assets/sprites/enemies/skeleton_move.png", "death": "res://assets/sprites/enemies/skeleton_death.png", "size": Vector2i(32, 32), "move_frames": 4, "death_frames": 4, "move_fps": 8.0, "death_fps": 8.0},
	"lamprey":          {"move": "res://assets/sprites/enemies/slime_move.png",   "death": "res://assets/sprites/enemies/slime_death.png",   "size": Vector2i(24, 24), "move_frames": 2, "death_frames": 4, "move_fps": 8.0, "death_fps": 8.0},
	# 精英敌人 → skeleton 精灵
	"butcher":          {"move": "res://assets/sprites/enemies/skeleton_move.png", "death": "res://assets/sprites/enemies/skeleton_death.png", "size": Vector2i(32, 32), "move_frames": 4, "death_frames": 4, "move_fps": 6.0, "death_fps": 8.0},
	"colossus":         {"move": "res://assets/sprites/enemies/skeleton_move.png", "death": "res://assets/sprites/enemies/skeleton_death.png", "size": Vector2i(32, 32), "move_frames": 4, "death_frames": 4, "move_fps": 5.0, "death_fps": 8.0},
	"rhino":            {"move": "res://assets/sprites/enemies/skeleton_move.png", "death": "res://assets/sprites/enemies/skeleton_death.png", "size": Vector2i(32, 32), "move_frames": 4, "death_frames": 4, "move_fps": 6.0, "death_fps": 8.0},
	"monk":             {"move": "res://assets/sprites/enemies/skeleton_move.png", "death": "res://assets/sprites/enemies/skeleton_death.png", "size": Vector2i(32, 32), "move_frames": 4, "death_frames": 4, "move_fps": 6.0, "death_fps": 8.0},
	"croc":             {"move": "res://assets/sprites/enemies/skeleton_move.png", "death": "res://assets/sprites/enemies/skeleton_death.png", "size": Vector2i(32, 32), "move_frames": 4, "death_frames": 4, "move_fps": 7.0, "death_fps": 8.0},
	"mom":              {"move": "res://assets/sprites/enemies/skeleton_move.png", "death": "res://assets/sprites/enemies/skeleton_death.png", "size": Vector2i(32, 32), "move_frames": 4, "death_frames": 4, "move_fps": 5.0, "death_fps": 8.0},
	# Boss → skeleton 精灵 (放大)
	"invoker":          {"move": "res://assets/sprites/enemies/skeleton_move.png", "death": "res://assets/sprites/enemies/skeleton_death.png", "size": Vector2i(32, 32), "move_frames": 4, "death_frames": 4, "move_fps": 6.0, "death_fps": 8.0},
	"predator":         {"move": "res://assets/sprites/enemies/skeleton_move.png", "death": "res://assets/sprites/enemies/skeleton_death.png", "size": Vector2i(32, 32), "move_frames": 4, "death_frames": 4, "move_fps": 6.0, "death_fps": 8.0},
}

## 分类回退精灵: regular→slime, elite→skeleton, boss→skeleton
const FALLBACK_SPRITES: Dictionary = {
	"regular": {"move": "res://assets/sprites/enemies/slime_move.png",   "death": "res://assets/sprites/enemies/slime_death.png",   "size": Vector2i(24, 24), "move_frames": 2, "death_frames": 4, "move_fps": 6.0, "death_fps": 8.0},
	"elite":   {"move": "res://assets/sprites/enemies/skeleton_move.png", "death": "res://assets/sprites/enemies/skeleton_death.png", "size": Vector2i(32, 32), "move_frames": 4, "death_frames": 4, "move_fps": 6.0, "death_fps": 8.0},
	"boss":    {"move": "res://assets/sprites/enemies/skeleton_move.png", "death": "res://assets/sprites/enemies/skeleton_death.png", "size": Vector2i(32, 32), "move_frames": 4, "death_frames": 4, "move_fps": 6.0, "death_fps": 8.0},
}

# ========== 内部状态 ==========

var health: float
var target: Node2D                           ## 追踪目标（玩家）
var is_alive: bool = true
var enemy_id: String = "chaser"             ## 敌人 ID (对应 DataLoader)
var enemy_category: String = "regular"      ## 敌人分类: regular/elite/boss
var behavior: Behavior = Behavior.CHASE     ## 行为模式

# 动画
var _anim: AnimatedSprite2D
var _is_dying: bool = false

# 行为状态
var _zigzag_timer: float = 0.0
var _zigzag_dir: float = 1.0
var _charge_timer: float = 0.0
var _is_charging: bool = false
var _charge_dir: Vector2 = Vector2.ZERO

# 接触伤害冷却（避免每帧对玩家造成伤害）
var _contact_cd: float = 0.0

# ========== 生命周期 ==========

func _ready() -> void:
	health = max_health
	health_changed.emit(health, max_health)
	_setup_animation()

func _physics_process(delta: float) -> void:
	if not is_alive or _is_dying:
		return
	_update_behavior(delta)
	# 接触伤害（带冷却）
	if _contact_cd > 0.0:
		_contact_cd -= delta
	_try_contact_damage()

## 当敌人贴近玩家时造成伤害（初版：所有行为通用）
func _try_contact_damage() -> void:
	if not is_target_valid() or _contact_cd > 0.0:
		return
	var dist := global_position.distance_to(target.global_position)
	var contact_range: float = frame_size.x * 0.5 + 12.0
	if dist <= contact_range and target.has_method("take_damage"):
		target.take_damage(damage)
		_contact_cd = 0.5

# ========== 动画 ==========

func _setup_animation() -> void:
	_anim = get_node_or_null("AnimatedSprite2D")
	if not _anim:
		return
	# 从 SPRITE_MAP 加载纹理，未命中时按分类回退
	var cfg: Dictionary = SPRITE_MAP.get(enemy_id, FALLBACK_SPRITES.get(enemy_category, FALLBACK_SPRITES["regular"]))
	move_texture = load(cfg["move"])
	death_texture = load(cfg["death"])
	frame_size = cfg["size"]
	move_frame_count = cfg["move_frames"]
	death_frame_count = cfg["death_frames"]
	move_fps = cfg["move_fps"]
	death_fps = cfg["death_fps"]
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

## 受击闪烁
func _play_hit_flash() -> void:
	if not _anim:
		return
	_anim.modulate = Color(1, 0.4, 0.4)
	var tw := create_tween()
	tw.tween_property(_anim, "modulate", Color.WHITE, 0.1)

# ========== 行为系统 ==========

## 根据行为模式更新移动
func _update_behavior(delta: float) -> void:
	if not is_target_valid():
		return
	match behavior:
		Behavior.CHASE:
			_move_chase(delta)
		Behavior.CHARGE:
			_move_charge(delta)
		Behavior.ZIGZAG:
			_move_zigzag(delta)
		Behavior.RANGED:
			_move_ranged(delta)
		Behavior.HEAL:
			_move_heal(delta)
		Behavior.SPAWN:
			_move_spawn(delta)
		Behavior.STATIONARY:
			pass  # 不移动
		Behavior.AOE_ATTACK:
			_move_chase(delta)  # 精英 AOE 近身
		Behavior.SELF_HEAL:
			_move_chase(delta)  # 精英自愈近身

## 直追玩家
func _move_chase(_delta: float) -> void:
	var direction := global_position.direction_to(target.global_position)
	velocity = direction * move_speed
	move_and_slide()

## 冲锋：周期性蓄力后高速冲向玩家
func _move_charge(delta: float) -> void:
	_charge_timer -= delta
	if _is_charging:
		velocity = _charge_dir * move_speed * 2.5
		move_and_slide()
		if _charge_timer <= 0.0:
			_is_charging = false
			_charge_timer = 2.0  # 蓄力间隔
	else:
		# 蓄力期间缓慢移动
		var direction := global_position.direction_to(target.global_position)
		velocity = direction * move_speed * 0.3
		move_and_slide()
		if _charge_timer <= 0.0:
			_is_charging = true
			_charge_dir = global_position.direction_to(target.global_position)
			_charge_timer = 0.8  # 冲锋持续

## Z 形移动
func _move_zigzag(delta: float) -> void:
	_zigzag_timer -= delta
	if _zigzag_timer <= 0.0:
		_zigzag_dir *= -1.0
		_zigzag_timer = 0.5
	var direction := global_position.direction_to(target.global_position)
	# 在追踪方向上叠加垂直偏移
	var perp := Vector2(-direction.y, direction.x) * _zigzag_dir
	velocity = (direction + perp * 0.6).normalized() * move_speed
	move_and_slide()

## 远程：保持距离
func _move_ranged(_delta: float) -> void:
	var dist := global_position.distance_to(target.global_position)
	var direction := global_position.direction_to(target.global_position)
	if dist < 200.0:
		# 太近，后退
		velocity = -direction * move_speed
	elif dist > 300.0:
		# 太远，靠近
		velocity = direction * move_speed * 0.5
	else:
		# 在射程内，横向移动
		var perp := Vector2(-direction.y, direction.x)
		velocity = perp * move_speed * 0.8
	move_and_slide()

## 治疗：跟随友军并治疗
func _move_heal(_delta: float) -> void:
	# 简单跟随玩家附近
	var direction := global_position.direction_to(target.global_position)
	var dist := global_position.distance_to(target.global_position)
	if dist > 250.0:
		velocity = direction * move_speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()

## 产卵：缓慢移动
func _move_spawn(_delta: float) -> void:
	var direction := global_position.direction_to(target.global_position)
	velocity = direction * move_speed * 0.5
	move_and_slide()

func is_target_valid() -> bool:
	if not is_instance_valid(target):
		return false
	if target.get("is_alive") != null:
		return target.is_alive
	return true

# ========== 受伤与死亡 ==========

## 受到伤害 (考虑护甲减伤)
func take_damage(amount: float) -> void:
	if not is_alive:
		return
	# 护甲减伤: reduction = min(armor / (armor + 20), 0.75)
	var reduction: float = min(armor / (armor + 20.0), 0.75)
	var actual_damage: float = amount * (1.0 - reduction)
	health -= actual_damage
	health_changed.emit(health, max_health)
	_play_hit_flash()
	if health <= 0.0:
		die()

## 死亡处理：播放死亡动画，掉落金币/经验，发射信号
func die() -> void:
	is_alive = false
	health = 0.0
	_is_dying = true
	_drop_rewards()
	died.emit(self)
	# 播放死亡动画后销毁
	if _anim and _anim.sprite_frames and _anim.sprite_frames.has_animation("death"):
		_anim.play("death")
		_anim.animation_finished.connect(func(): queue_free())
	else:
		queue_free()

## 掉落奖励
func _drop_rewards() -> void:
	if GameManager.economy:
		GameManager.economy.add_coins(coin_value)

# ========== 初始化接口 ==========

## 从 DataLoader.get_scaled_enemy() 返回的字典初始化敌人属性
func initialize(stats: Dictionary) -> void:
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
	if stats.has("behavior"):
		var behav_str: String = stats["behavior"]
		behavior = BEHAVIOR_MAP.get(behav_str, Behavior.CHASE)
	# 根据 category 设置标记
	match enemy_category:
		"elite":
			is_elite = true
		"boss":
			is_boss = true
	health = max_health
	health_changed.emit(health, max_health)

## 设置追踪目标
func set_target(t: Node2D) -> void:
	target = t
