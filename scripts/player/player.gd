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

# ========== 角色（Day 2：hero id 消费） ==========

## 英雄精灵目录（配合 characters.json 的 `sprite` 前缀字段拼装）
const SPRITE_DIR: String = "res://assets/sprites/characters/"

## characters.json 的 passive/penalty 键 → apply_stat_modifier 的合法 stat 名
## mode: "add" 直接加 / "percent" 百分数转倍率乘算 / "ratio" 百分数转 0~1 后加
const STAT_MAP: Dictionary = {
	"max_hp": {"stat": "max_health", "mode": "add"},
	"speed_percent": {"stat": "move_speed", "mode": "percent"},
	"armor": {"stat": "armor", "mode": "add"},
	"regen": {"stat": "regen", "mode": "add"},
	"hp_regen": {"stat": "regen", "mode": "add"},
	"dodge_percent": {"stat": "dodge", "mode": "ratio"},
	"crit_chance_percent": {"stat": "crit_chance", "mode": "ratio"},
	"attack_speed_percent": {"stat": "attack_speed", "mode": "percent"},
	"melee_attack_speed_percent": {"stat": "attack_speed", "mode": "percent"},
	"damage_percent": {"stat": "damage", "mode": "percent"},
	"range_percent": {"stat": "range", "mode": "percent"},
	"luck": {"stat": "luck", "mode": "add"},
	"pickup_range": {"stat": "pickup_range", "mode": "add"},
}

## 刻意不进 STAT_MAP 的键（进 bonus_stats 等后续系统消费），附不映射的原因
## `range`：JSON 里是「像素平直加减」（如 brawler -50），而 range_multiplier 是倍率，
##          直接加会把倍率打成负数使武器射程失效 —— 口径统一属 Day 4 强化面板的决策
const STAT_MAP_EXCLUDED: PackedStringArray = ["range"]

var character_id: String = ""                ## 当前英雄 id（空 = 未经角色选择）
var bonus_stats: Dictionary = {}             ## 引擎尚未实现的被动/惩罚键，Day 3 技能与 Day 4 面板读此字典

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

# ========== 角色装载（由 Main 在 _ready 中调用） ==========

## 应用 characters.json 中的一条英雄数据：被动 + 惩罚 + 精灵资源
## 空字典直接返回（调试直开 Main.tscn 时保持出厂属性）
func apply_character(char_data: Dictionary) -> void:
	if char_data.is_empty():
		return

	character_id = str(char_data.get("id", ""))
	bonus_stats.clear()
	# 惩罚与被动同表处理：值为负数走同一入口即可
	_apply_stat_dict(char_data.get("passive", {}))
	_apply_stat_dict(char_data.get("penalty", {}))
	_apply_character_sprite(str(char_data.get("sprite", "")))

	# 起始满血：被动/惩罚可能改动了上限
	health = max_health
	health_changed.emit(health, max_health)
	stats_changed.emit()

## 按 STAT_MAP 落实一组属性键；未映射的键原样收进 bonus_stats（禁止静默丢弃）
func _apply_stat_dict(source: Dictionary) -> void:
	if source.is_empty():
		return

	for key: String in source:
		var amount: float = float(source[key])
		if not STAT_MAP.has(key):
			# 同名键叠加而非覆盖（passive 与 penalty 可能命中同一键）
			bonus_stats[key] = float(bonus_stats.get(key, 0.0)) + amount
			continue

		var rule: Dictionary = STAT_MAP[key]
		var stat_name: String = str(rule["stat"])
		match str(rule["mode"]):
			"add":
				apply_stat_modifier(stat_name, amount)
			"percent":
				apply_stat_modifier(stat_name, 1.0 + amount / 100.0, true)
			"ratio":
				apply_stat_modifier(stat_name, amount / 100.0)

## 换上英雄专属精灵（`sprite` 为资源名前缀）；缺资源时保留 Player.tscn 预设素材
func _apply_character_sprite(prefix: String) -> void:
	if prefix.is_empty():
		return
	var idle_path: String = "%s%s_idle.png" % [SPRITE_DIR, prefix]
	var walk_path: String = "%s%s_walk.png" % [SPRITE_DIR, prefix]
	if not ResourceLoader.exists(idle_path) or not ResourceLoader.exists(walk_path):
		# 区分「文件不在」与「文件在但未生成 .import」，后者编辑器一开即消解，不算缺陷
		if FileAccess.file_exists(idle_path) and FileAccess.file_exists(walk_path):
			print_verbose("[Player] 英雄精灵尚未导入，沿用默认素材: %s" % character_id)
		else:
			push_warning("[Player] 英雄精灵缺失，沿用默认素材: %s" % character_id)
		return

	var idle_res := ResourceLoader.load(idle_path)
	var walk_res := ResourceLoader.load(walk_path)
	if not (idle_res is Texture2D) or not (walk_res is Texture2D):
		return
	idle_texture = idle_res as Texture2D
	walk_texture = walk_res as Texture2D
	_is_walking = false
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

# ========== 主动技能（大纲 §5：玩家控制的主动技能，带冷却/资源） ==========
# D1 打桩：输入动作 skill_cast 已注册；D3-T1 转发到 SkillController 统一释放。

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("skill_cast"):
		_try_cast_skill()

## 主动技能释放（转发给 SkillController；节点缺失时保留空实现分支防崩）
func _try_cast_skill() -> void:
	var controller: Node = get_node_or_null("SkillController")
	if controller and controller.has_method("try_cast"):
		controller.try_cast()
	# 无 SkillController 时静默 pass（Player.tscn 未更新路径防崩）

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
		"crit_damage":
			crit_damage = apply_value(crit_damage, value, is_multiplicative)
		"dodge":
			dodge = clampf(apply_value(dodge, value, is_multiplicative), 0.0, 0.9)
		"luck":
			luck = apply_value(luck, value, is_multiplicative)
		"coin_bonus":
			coin_bonus = apply_value(coin_bonus, value, is_multiplicative)
	stats_changed.emit()

func apply_value(base: float, mod: float, multiplicative: bool) -> float:
	if multiplicative:
		return base * mod
	else:
		return base + mod
