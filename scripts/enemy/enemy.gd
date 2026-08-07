## 敌人基类脚本
## 所有敌人类型（普通/精英/Boss）继承此类
## 数据由 DataLoader.get_scaled_enemy() 提供并传入 initialize()
extends CharacterBody2D

# ========== 信号 ==========

signal died(enemy: Node)
signal health_changed(current_hp: float, max_hp: float)

## F-11（用户拍板 2026-08-06）：伤害数字飘字脚本。preload 而非依赖 class_name——
## 无头 --script 模式（探针）不注册全局类名（main.gd:20 同策略），静态方法经脚本引用调用
const DamageNumberScript: GDScript = preload("res://scripts/effects/damage_number.gd")

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

# 元素状态机（Day 3 · D3-T2b）：status_type -> {"time_left": float, "dps": float}
var _status: Dictionary = {}

# 精英能力（Day 17 · D17-T2）：由 enemies.json 精英 ability 字段数据驱动
# {type: "aoe"/"self_heal"/"spawn", ...参数}；缺省 = 无特殊能力（零行为回归）
var ability: Dictionary = {}
## 自身波次（产卵用同波缩放：DataLoader.get_scaled_enemy(minion, wave_number)）
var wave_number: int = 1
var _ability_timer: float = 0.0

# ========== 生命周期 ==========

func _ready() -> void:
	health = max_health
	health_changed.emit(health, max_health)
	_setup_animation()

func _physics_process(delta: float) -> void:
	if not is_alive or _is_dying:
		return
	_update_status(delta)
	# 持续伤害可能直接击杀，后续行为逻辑不应再跑
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

# ========== 元素状态机（Day 3 · D3-T2b） ==========
# 承载「燃烧/冰冻/中毒…」一类持续状态。本日只落地最小可用形态：
#   · 单一状态不叠层，重复附着取「更长剩余时间 + 更高 dps」，避免无上限滚雪球
#   · DoT 伤害不走 take_damage()：一是元素持续伤害按设计无视护甲，
#     二是 take_damage() 每次都 create_tween() 播受击闪烁，逐帧调用会爆 tween

## 附着一个元素状态（由弹丸/技能调用）
func apply_status(status_type: String, duration: float, dps: float) -> void:
	if not is_alive or _is_dying:
		return
	if status_type.is_empty() or duration <= 0.0:
		return
	var existing: Dictionary = _status.get(status_type, {})
	_status[status_type] = {
		"time_left": maxf(float(existing.get("time_left", 0.0)), duration),
		"dps": maxf(float(existing.get("dps", 0.0)), dps),
	}

## 查询是否处于某状态（供 UI / 测试断言）
func has_status(status_type: String) -> bool:
	return _status.has(status_type)

## 查询某状态剩余时间，未附着返回 0
func get_status_time_left(status_type: String) -> float:
	if not _status.has(status_type):
		return 0.0
	return float(_status[status_type].get("time_left", 0.0))

## 逐帧结算所有状态的持续伤害与剩余时间
func _update_status(delta: float) -> void:
	if _status.is_empty():
		return
	var expired: Array[String] = []
	for status_type: String in _status:
		var entry: Dictionary = _status[status_type]
		var dps: float = float(entry.get("dps", 0.0))
		if dps > 0.0:
			_apply_status_damage(dps * delta)
		entry["time_left"] = float(entry.get("time_left", 0.0)) - delta
		if entry["time_left"] <= 0.0:
			expired.append(status_type)
		if not is_alive:
			break
	for status_type in expired:
		_status.erase(status_type)

## 持续伤害入口：无视护甲、不播受击闪烁，仅在致死时走正常死亡流程
func _apply_status_damage(amount: float) -> void:
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

# ========== Boss attacks 指令解析（D18-19-T2 · 纯函数） ==========
## enemies.json phases[].attacks 字符串指令 → 结构化字典（决策 D8：禁物理查询，全距离/容器遍历）
## 输出统一含 5 键 {kind, count, interval, mult, elite}；未知指令 push_warning + 返回 {}（不崩）
## 指令表（定案 T2-A）：
##   summon_N_enemies_every_Xs → {kind:"summon", count:N, interval:X, elite:false}
##   summon_N_elite            → {kind:"summon", count:N, interval:0.0, elite:true}（一次性）
##   N_projectile_spread       → {kind:"spread", count:N, interval:4.0}（决策 D4）
##   projectile_barrage        → {kind:"barrage", interval:4.0}（决策 D4）
##   aoe_every_Xs              → {kind:"aoe", interval:X}
##   charge_attack / _2x       → {kind:"charge", mult:1.0/2.0, interval:-1.0}（永续置位无计时）
##   all_attacks_2x            → {kind:"mult", mult:2.0, interval:-1.0}（阶段修饰符无计时）

func _parse_attack(cmd: String) -> Dictionary:
	var parts: PackedStringArray = cmd.split("_")
	if parts.is_empty():
		push_warning("[Boss] 未知攻击指令: %s" % cmd)
		return {}
	var head: String = parts[0]
	# 召唤系: summon_N_enemies_every_Xs / summon_N_elite
	if head == "summon":
		if parts.size() >= 3:
			var count: int = maxi(int(parts[1]), 0)
			if parts[2] == "elite":
				return {"kind": "summon", "count": count, "interval": 0.0, "mult": 1.0, "elite": true}
			if parts.size() >= 5 and parts[3] == "every":
				var interval: float = float(parts[4].trim_suffix("s"))
				return {"kind": "summon", "count": count, "interval": interval, "mult": 1.0, "elite": false}
	# 弹幕系: N_projectile_spread / projectile_barrage
	elif head == "projectile":
		if parts.size() >= 2 and parts[1] == "barrage":
			return {"kind": "barrage", "count": 0, "interval": 4.0, "mult": 1.0, "elite": false}
	# AOE: aoe_every_Xs
	elif head == "aoe":
		if parts.size() >= 3 and parts[1] == "every":
			var interval: float = float(parts[2].trim_suffix("s"))
			return {"kind": "aoe", "count": 0, "interval": interval, "mult": 1.0, "elite": false}
	# 冲锋: charge_attack / charge_attack_2x
	elif head == "charge":
		if parts.size() == 2 and parts[1] == "attack":
			return {"kind": "charge", "count": 0, "interval": -1.0, "mult": 1.0, "elite": false}
		if parts.size() == 3 and parts[1] == "attack" and parts[2] == "2x":
			return {"kind": "charge", "count": 0, "interval": -1.0, "mult": 2.0, "elite": false}
	# 阶段修饰符: all_attacks_2x
	elif head == "all":
		if parts.size() >= 3 and parts[1] == "attacks" and parts[2] == "2x":
			return {"kind": "mult", "count": 0, "interval": -1.0, "mult": 2.0, "elite": false}
	# 数字开头: N_projectile_spread（int 转换须回验防 "abc"→0 误判）
	elif parts.size() >= 3 and parts[1] == "projectile" and parts[2] == "spread":
		var count: int = int(head)
		if str(count) == head:
			return {"kind": "spread", "count": count, "interval": 4.0, "mult": 1.0, "elite": false}
	push_warning("[Boss] 未知攻击指令: %s" % cmd)
	return {}

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
			# Day 17 · D17-T2：精英产卵（mom）；ability 空 → 立即 return 零影响（regular 产卵者）
			_elite_spawn(delta)
		Behavior.STATIONARY:
			pass  # 不移动
		Behavior.AOE_ATTACK:
			_move_chase(delta)  # 精英 AOE 近身
			_elite_aoe(delta)   # Day 17 · D17-T2：butcher 周期 AOE
		Behavior.SELF_HEAL:
			_move_chase(delta)  # 精英自愈近身
			_elite_self_heal(delta)  # Day 17 · D17-T2：monk 低血周期自愈

## 直追玩家
func _move_chase(_delta: float) -> void:
	var direction := global_position.direction_to(target.global_position)
	velocity = direction * move_speed
	move_and_slide()

## 冲锋：周期性蓄力后高速冲向玩家
func _move_charge(delta: float) -> void:
	_charge_timer -= delta
	if _is_charging:
		# F-15（用户拍板 2026-08-06 · P0）：冲锋倍率 ×2.5 → ×1.5（配合 F-01 移速×0.5，
		# 冲速 425×1.5×0.5≈319，恢复可反应区间，消除「被冲脸瞬秒」围杀体验）
		velocity = _charge_dir * move_speed * 1.5
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

# ========== 精英特殊能力（Day 17 · D17-T2） ==========
## 三能力全部用距离判断 + 容器遍历，禁物理查询（无头稳定铁律，D3 火球物理先例）。
## ability 空（colossus/rhino/croc 缺省）→ 立即 return，零行为回归。

## 特效容器解析：vfx_container → current_scene → null（无容器静默跳过不崩）
func _resolve_fx_container() -> Node:
	if GameManager and GameManager.vfx_container:
		return GameManager.vfx_container
	if get_tree() and get_tree().current_scene:
		return get_tree().current_scene
	return null

## AOE 攻击（butcher）：周期对 radius 内玩家造成 damage × damage_mult
func _elite_aoe(delta: float) -> void:
	if ability.is_empty():
		return
	_ability_timer -= delta
	if _ability_timer > 0.0:
		return
	var radius: float = float(ability.get("radius", 0.0))
	var damage_mult: float = float(ability.get("damage_mult", 1.0))
	if radius > 0.0 and is_target_valid() and target.has_method("take_damage"):
		if global_position.distance_to(target.global_position) <= radius:
			target.take_damage(damage * damage_mult)
			var fx_container: Node = _resolve_fx_container()
			if fx_container:
				VfxPlayer.spawn(fx_container, target.global_position, "crit")
	_ability_timer = float(ability.get("interval", 1.0))

## 自愈（monk）：血量 < max_health × threshold 时周期恢复 heal_percent% 最大生命
func _elite_self_heal(delta: float) -> void:
	if ability.is_empty():
		return
	_ability_timer -= delta
	if _ability_timer > 0.0:
		return
	var threshold: float = float(ability.get("threshold", 0.5))
	var heal_percent: float = float(ability.get("heal_percent", 0.0))
	if heal_percent > 0.0 and health < max_health * threshold:
		health = min(max_health, health + max_health * heal_percent)
		health_changed.emit(health, max_health)
		var fx_container: Node = _resolve_fx_container()
		if fx_container:
			VfxPlayer.spawn(fx_container, global_position, "levelup")
	_ability_timer = float(ability.get("interval", 1.0))

## 产卵（mom）：周期生成 count 只 minion（用自身 wave_number 同波缩放）
func _elite_spawn(delta: float) -> void:
	if ability.is_empty():
		return
	_ability_timer -= delta
	if _ability_timer > 0.0:
		return
	var minion: String = str(ability.get("minion", ""))
	var count: int = maxi(int(ability.get("count", 0)), 0)
	if minion.is_empty() or count <= 0:
		_ability_timer = float(ability.get("interval", 1.0))
		return
	# 容器：优先 GameManager.enemies_container（main 接线）；缺失静默跳过不崩
	var container: Node = null
	if GameManager and GameManager.enemies_container:
		container = GameManager.enemies_container
	elif GameManager and GameManager.enemy_spawner and GameManager.enemy_spawner.enemies_container:
		container = GameManager.enemy_spawner.enemies_container
	if container == null:
		return
	# 敌人场景：优先 spawner 已加载资源，否则延迟 load（避免脚本 preload 自身场景循环）
	var scene: PackedScene = null
	if GameManager and GameManager.enemy_spawner and GameManager.enemy_spawner.enemy_scene:
		scene = GameManager.enemy_spawner.enemy_scene
	else:
		scene = load("res://scenes/Enemy.tscn")
	if scene == null:
		return
	for _i in count:
		var stats: Dictionary = DataLoader.get_scaled_enemy(minion, wave_number)
		if stats.is_empty():
			break
		var minion_node: Node = scene.instantiate()
		if minion_node.has_method("initialize"):
			minion_node.initialize(stats)
		if GameManager and GameManager.player and minion_node.has_method("set_target"):
			minion_node.set_target(GameManager.player)
		container.add_child(minion_node)
	_ability_timer = float(ability.get("interval", 1.0))

func is_target_valid() -> bool:
	if not is_instance_valid(target):
		return false
	if target.get("is_alive") != null:
		return target.is_alive
	return true

# ========== 受伤与死亡 ==========

## 受到伤害 (考虑护甲减伤)
## F-11（用户拍板 2026-08-06）：新增可选 is_crit 参数——默认 false 零回归（DoT/接触/旧调用
## 不传即普通伤害数字）；projectile 线弹/AOE 透传真实暴击态 → 金色大字号「N!」
func take_damage(amount: float, is_crit: bool = false) -> void:
	if not is_alive:
		return
	# 护甲减伤: reduction = min(armor / (armor + 20), 0.75)
	var reduction: float = min(armor / (armor + 20.0), 0.75)
	var actual_damage: float = amount * (1.0 - reduction)
	health -= actual_damage
	health_changed.emit(health, max_health)
	_play_hit_flash()
	_spawn_damage_number(actual_damage, is_crit)
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
	# D4-T1：经验直接结算（不造磁吸宝石实体，见 TASKS Day 4 总定案）
	if GameManager.player and GameManager.player.has_method("gain_exp"):
		GameManager.player.gain_exp(exp_value)
		# D6-T4（T-B · P1）：击杀经验飘字「+N」（方案 A；容器缺失时静默跳过不崩）
		_spawn_exp_popup(exp_value)

## D6-T4：击杀经验飘字（0.6s 上浮 + 淡出后消失）
func _spawn_exp_popup(amount: int) -> void:
	var container: Node = GameManager.vfx_container if GameManager.vfx_container else null
	if container == null:
		container = get_tree().current_scene
	if container == null:
		return  # 无容器（如纯数据测试）静默跳过
	var label := Label.new()
	label.text = "+%d" % amount
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.45, 0.85, 1.0))
	container.add_child(label)
	label.global_position = global_position + Vector2(randf_range(-10.0, 10.0), -28.0)
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position:y", label.global_position.y - 26.0, 0.6)
	tween.tween_property(label, "modulate:a", 0.0, 0.6)
	tween.chain().tween_callback(label.queue_free)

## F-11（用户拍板 2026-08-06）：受击伤害数字飘字（普通浅黄 / 暴击金色大字号「N!」）
## 容器解析复用 _spawn_exp_popup 范式：vfx_container → current_scene → 无容器跳过不崩
func _spawn_damage_number(amount: float, is_crit: bool) -> void:
	var container: Node = GameManager.vfx_container if GameManager.vfx_container else null
	if container == null:
		container = get_tree().current_scene
	if container == null:
		return
	DamageNumberScript.spawn(container, global_position, amount, is_crit)

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
	if stats.has("exp_value"):
		exp_value = int(stats["exp_value"])
	if stats.has("behavior"):
		var behav_str: String = stats["behavior"]
		behavior = BEHAVIOR_MAP.get(behav_str, Behavior.CHASE)
	# Day 17 · D17-T2：精英能力 + 波次（产卵缩放）
	if stats.has("ability"):
		ability = stats["ability"]
	if stats.has("wave_number"):
		wave_number = int(stats["wave_number"])
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
