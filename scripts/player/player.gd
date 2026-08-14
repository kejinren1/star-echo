## 玩家角色脚本（移动/属性/受伤/自动攻击触发；F4-C 属性→attribute_controller、动画→player_anim）
extends CharacterBody2D

# ========== 信号 ==========

signal died
signal health_changed(current_hp: float, max_hp: float)
signal stats_changed
signal took_damage(amount: float)
signal level_up(new_level: int)                 ## 升级（D4-T1：经验满触发）
signal xp_changed(current: float, need: float)  ## 经验变化（D4-T1：HUD 刷新用）
signal status_changed

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
@export var life_steal: float = 0.0          ## 吸血：命中伤害回血比例 (0~1)（D4-T3）
## F-04（用户拍板 2026-08-06 · P0）：金手指攻击倍率（toggle_debug_cheat 写入；默认 1.0 零回归）
var debug_mult: float = 1.0
## D20-T2：遗物装配倍率（percent 键乘算目标；默认 1.0 零回归，新实例即复位）
var damage_taken_mult: float = 1.0        ## 受伤倍率（take_damage armor 减伤后乘，破碎王冠 +30%）
var structure_damage_mult: float = 1.0    ## 结构伤害倍率（turret 弹药消费，机械引擎 +100%）

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
## BS-A2（2026-08-13）：通用持续效果组件（无 class_name，preload 范式——探针 --script 兼容）
const StatusComponentScript: GDScript = preload("res://scripts/systems/status_component.gd")
## F4-C（2026-08-14 · T-048）：属性/动画组件 + 共享枚举（组件不 preload player 本体防循环）
const AttributeControllerScript: GDScript = preload("res://scripts/player/attribute_controller.gd")
const PlayerAnimScript: GDScript = preload("res://scripts/player/player_anim.gd")
const PlayerEnums: GDScript = preload("res://scripts/player/player_enums.gd")

# ========== 属性映射（定义见 attribute_controller.gd，F4-C 迁出；外部引用兼容别名） ==========
## day13 探针 `_player.get("STAT_MAP")` 直接读宿主 → 别名保留单一事实源在组件
const STAT_MAP: Dictionary = AttributeControllerScript.STAT_MAP
const STAT_MAP_EXCLUDED: PackedStringArray = AttributeControllerScript.STAT_MAP_EXCLUDED
const CONSUMED_BONUS_KEYS: PackedStringArray = AttributeControllerScript.CONSUMED_BONUS_KEYS
## 行为态枚举/动画表（定义见 player_enums.gd，F4-C 迁出）
const ANIM_MAP: Dictionary = PlayerEnums.ANIM_MAP

var character_id: String = ""                ## 当前英雄 id（空 = 未经角色选择）
var bonus_stats: Dictionary = {}             ## 引擎尚未实现的被动/惩罚键，Day 3 技能与 Day 4 面板读此字典

# ========== 内部状态 ==========

var health: float                            ## 当前生命值
## P0-Bug1 修复（2026-08-10）：希亚「神圣庇护」护盾 —— 受击优先吸收，时长到自动归零
var shield: float = 0.0                      ## 护盾值（神圣庇护等技能来源）
var _shield_timer: float = 0.0               ## 护盾剩余时长（<=0 归零）
var _shield_duration: float = 0.0            ## 护盾总时长
var is_alive: bool = true
var _invulnerable_timer: float = 0.0         ## 无敌帧计时
var _last_stand_active: bool = false         ## D24-F13-2（F-13 low_health · last_stand 背水一战）当前是否生效

# 经验与升级（D4-T1）
var exp: float = 0.0                         ## 当前经验值
var level: int = 1                           ## 当前等级（1 起）
var _xp_curve_cache: Expression = null       ## 经验曲线表达式缓存（解析一次，避免逐级重复 parse）

# 动画
var _anim: AnimatedSprite2D
var _state: PlayerEnums.PlayerState = PlayerEnums.PlayerState.IDLE  ## 行为态（F3-T6，定义见 player_enums.gd）
## F-33（08-09 用户反馈）：朝向 —— true=朝左（原图默认），false=朝右（flip_h 镜像）
var _facing_left: bool = true
var _sprite_prefix: String = ""              ## D21-22-T3：角色精灵前缀（空 = 默认 fighter 无 attack/skill）
## BS-A2/A3：持续效果组件 + 麻痹标志（StatusComponent stun 置位 → _handle_movement 跳过输入）
var _status_component: Node = null
var stunned: bool = false
## F4-C：属性/动画组件实例（探针直接读写宿主字段，组件引用注入）
var _attr_ctrl: Node = null
var _anim_ctrl: Node = null

# ========== 生命周期 ==========

func _ready() -> void:
	health = max_health
	health_changed.emit(health, max_health)
	_ensure_components()
	_setup_animation()
	# BS-A2：挂载通用持续效果组件（玩家/Boss/怪物同一组件；preload 范式探针兼容）
	_status_component = StatusComponentScript.new()
	_status_component.name = "StatusComponent"
	add_child(_status_component)
	_status_component.setup(self)
	# D21-22-T3：连接技能释放信号 → 播技能动画（SkillController 子节点 _ready 先执行）
	var sc: Node = get_node_or_null("SkillController")
	if sc and sc.has_signal("skill_cast"):
		sc.skill_cast.connect(_play_skill_anim)

## F4-C：组件懒挂载（initialize/apply_character 先于 _ready → 保证组件就绪；幂等）
func _ensure_components() -> void:
	if _attr_ctrl == null:
		_attr_ctrl = AttributeControllerScript.new()
		_attr_ctrl.name = "AttributeController"
		add_child(_attr_ctrl)
		_attr_ctrl.setup(self)
	if _anim_ctrl == null:
		_anim_ctrl = PlayerAnimScript.new()
		_anim_ctrl.name = "PlayerAnimController"
		add_child(_anim_ctrl)
		_anim_ctrl.setup(self)

# ========== 角色装载（由 Main 在 _ready 中调用） ==========

## 应用 characters.json 中的一条英雄数据：被动 + 惩罚 + 精灵资源（空字典直接返回）
func apply_character(char_data: Dictionary) -> void:
	if char_data.is_empty():
		return

	character_id = str(char_data.get("id", ""))
	bonus_stats.clear()
	# 惩罚与被动同表处理：值为负数走同一入口即可（F4-C 经 AttributeController 组件）
	if _attr_ctrl:
		_attr_ctrl.apply_character_stats(char_data)
	_apply_character_sprite(str(char_data.get("sprite", "")))

	# 起始满血：被动/惩罚可能改动了上限
	health = max_health
	health_changed.emit(health, max_health)
	stats_changed.emit()

# ========== 属性系统薄委托（F4-C · 定义见 attribute_controller.gd） ==========
# 探针 day30_p0_fix call("apply_item_bonuses") / main D42 直调 apply_stat_modifier → 转发组件
func apply_item_bonuses(item: Resource, remove: bool = false) -> void:
	if _attr_ctrl: _attr_ctrl.apply_item_bonuses(item, remove)

func apply_stat_modifier(stat_name: String, value: float, is_multiplicative: bool = false) -> void:
	if _attr_ctrl: _attr_ctrl.apply_stat_modifier(stat_name, value, is_multiplicative)

# ========== 动画薄委托（F4-C · 定义见 player_anim.gd） ==========
# 探针 day29_elin/day29_attack 动态调用同名方法 → 转发 PlayerAnim 组件
# （_state/_anim/_sprite_prefix/_facing_left 字段仍由宿主持有，探针 get/set 兼容）
func _apply_character_sprite(prefix: String) -> void:
	if _anim_ctrl: _anim_ctrl.apply_character_sprite(prefix)

func _setup_animation() -> void:
	if _anim_ctrl: _anim_ctrl._setup_animation()

func _play_attack_anim() -> void:
	if _anim_ctrl: _anim_ctrl._play_attack_anim()

func _play_skill_anim(_skill_id: String = "") -> void:
	if _anim_ctrl: _anim_ctrl._play_skill_anim()

func _on_anim_finished() -> void:
	if _anim_ctrl: _anim_ctrl._on_anim_finished()

func _play_hit_anim() -> void:
	if _anim_ctrl: _anim_ctrl._play_hit_anim()

func _play_hit_flash() -> void:
	if _anim_ctrl: _anim_ctrl._play_hit_flash()

func _update_facing() -> void:
	if _anim_ctrl: _anim_ctrl._update_facing()

func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	_handle_movement()
	_handle_regeneration(delta)
	_handle_shield(delta)

	if _invulnerable_timer > 0.0:
		_invulnerable_timer -= delta


func _handle_movement() -> void:
	# O2 软控（BS-A3）：麻痹禁行动——跳过输入（velocity 归零），受击/技能仍可用
	if stunned:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var input_vector := Vector2.ZERO
	input_vector.x = Input.get_axis("move_left", "move_right")
	input_vector.y = Input.get_axis("move_up", "move_down")
	input_vector = input_vector.normalized()

	velocity = input_vector * move_speed
	move_and_slide()
	# F-33（08-09 用户反馈）：左右转向 —— 原图默认朝左，按水平移动方向镜像翻转
	_update_facing()

# ========== 主动技能（大纲 §5：玩家控制的主动技能，带冷却/资源） ==========

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("skill_cast"):
		_try_cast_skill()

## 主动技能释放（转发给 SkillController；节点缺失时保留空实现分支防崩）
func _try_cast_skill() -> void:
	var controller: Node = get_node_or_null("SkillController")
	if controller and controller.has_method("try_cast"):
		controller.try_cast()

# ========== 生命与受伤 ==========

func _handle_regeneration(delta: float) -> void:
	if regen > 0.0 and health < max_health:
		heal(regen * delta)

func _handle_shield(delta: float) -> void:
	if _shield_timer <= 0.0:
		return
	_shield_timer -= delta
	if _shield_timer <= 0.0:
		shield = 0.0

func add_shield(amount: float, duration: float) -> void:
	shield += maxf(amount, 0.0)
	_shield_duration = maxf(duration, 0.0)
	_shield_timer = _shield_duration

func take_damage(amount: float) -> void:
	if not is_alive or _invulnerable_timer > 0.0:
		return
		return
	# T-013（F1-散 2026-08-13）：无敌帧/金手指受伤倍率参数化（单次取表，缺表兜底现值）
	var combat: Dictionary = DataLoader.get_stats_combat()
	# 护盾吸收（P0-Bug1）：护盾优先于闪避/护甲；全吸收时仅受击反馈 + 无敌帧
	if shield > 0.0:
		var absorbed: float = minf(shield, amount)
		shield -= absorbed
		amount -= absorbed
		if amount <= 0.0:
			_play_hit_flash()
			_invulnerable_timer = float(combat.get("i_frames", 0.4))
			return
	# 闪避判定
	if randf() < dodge:
		return
	# 护甲减伤（F1-C 平直减）+ 受伤倍率（D20-T2 破碎王冠） + 金手指 0.1%（F-04/T-013）
	var actual_damage: float = max(amount - armor, 1.0)
	actual_damage *= damage_taken_mult
	if GameManager and GameManager.debug_cheat:
		actual_damage *= float(combat.get("debug_damage_mult", 0.001))
	health -= actual_damage
	health_changed.emit(health, max_health)
	took_damage.emit(actual_damage)
	_play_hit_flash()
	_play_hit_anim()   # D29：受击动画（无 hit 帧时静默降级仅红闪）
	AudioManager.play_sfx("hit")   # D24-T3-④：受击 SFX
	# 短无敌帧，避免被群体敌人每帧叠伤
	_invulnerable_timer = float(combat.get("i_frames", 0.4))
	# D24-F13-2（F-13 low_health · last_stand 背水一战）：受击后统一刷新低血状态
	_update_last_stand()
	if health <= 0.0:
		die()

## BS-A3（2026-08-13）：统一效果施加入口（武器/被动/技能/Boss 技能全走它；O1 叠加 + 四类型）
func apply_effect(source_id: String, effect_id: String, params: Dictionary = {}) -> void:
	if not is_alive or effect_id.is_empty():
		return
	if _status_component:
		_status_component.apply_effect(source_id, effect_id, params)

func heal(amount: float) -> void:
	health = min(health + amount, max_health)
	health_changed.emit(health, max_health)
	# D24-F13-2（F-13 low_health · last_stand 背水一战）：回血后刷新低血状态（回血 >30% 自动解除）
	_update_last_stand()

## D24-F13-2（F-13 low_health · last_stand 背水一战）：低血爆发统一入口
## 持有 last_stand 且 ≤30% → damage ×1.5 + attack_speed ×1.2；解除 → 逆运算回滚；状态变化才切换
func _update_last_stand() -> void:
	var should: bool = false
	if is_alive and health > 0.0 and GameManager and GameManager.inventory \
			and GameManager.inventory.has_item_id(DataLoader.ITEM_LAST_STAND) \
			and health <= max_health * 0.3:
		should = true
	if should and not _last_stand_active:
		apply_stat_modifier("damage", 1.5, true)
		apply_stat_modifier("attack_speed", 1.2, true)
		_last_stand_active = true
	elif not should and _last_stand_active:
		apply_stat_modifier("damage", 1.0 / 1.5, true)
		apply_stat_modifier("attack_speed", 1.0 / 1.2, true)
		_last_stand_active = false

func die() -> void:
	is_alive = false
	health = 0.0
	health_changed.emit(health, max_health)
	died.emit()
	GameManager.end_game(false)

# ========== 经验与升级（Day 4 · D4-T1） ==========
## 经验曲线唯一权威：stats.json.leveling.xp_per_level 表达式（Godot Expression 求值，
## 禁代码硬编码第二份曲线防双源漂移）

func gain_exp(amount: float) -> void:
	if not is_alive or amount <= 0.0:
		return
	var xp_mult: float = 1.0 + float(bonus_stats.get("xp_gain_percent", 0.0)) / 100.0
	exp += amount * xp_mult
	_check_level_up()
	xp_changed.emit(exp, get_xp_to_next_level())
	stats_changed.emit()

func get_xp_to_next_level() -> float:  # 当前等级升到下一级所需经验（HUD / 测试读取）
	var need: float = _eval_xp_curve()
	return maxf(need, 1.0)

func get_weapon_controller() -> Node:  # F2-T2（T-038）：shop UI 直读收口；未挂载返回 null
	return get_node_or_null("WeaponController")

func _check_level_up() -> void:
	while exp >= get_xp_to_next_level():
		exp -= get_xp_to_next_level()
		level += 1
		# H-01 升级体验（反馈专员 2026-08-07 用户拍板）：升级光效 + 击退 + 普攻级伤害
		_trigger_level_impact()
		level_up.emit(level)
		AudioManager.play_sfx("levelup")   # D24-T3-⑤：升级 SFX

# ========== 升级冲击波（H-01 升级体验反馈 2026-08-07 · 用户拍板） ==========
## 升级光效 + 周围敌人击退 + 普攻级伤害（占位特效机制验证；伤害对齐普攻口径）
const LEVEL_IMPACT_RADIUS: float = 140.0      ## 冲击半径（640×360 视口约 1/3 屏宽）
const LEVEL_IMPACT_KNOCKBACK: float = 500.0   ## 击退初速（px/s，衰减 50%/帧 ≈ 15-20px 推离）
const LEVEL_IMPACT_DAMAGE_FALLBACK: float = 10.0  ## 无武器兜底（对齐普攻基准）

## 触发升级冲击：光效 + 范围内敌人击退并造成普攻级伤害（容器缺失静默跳过不崩）
func _trigger_level_impact() -> void:
	var container: Node = null
	if GameManager and GameManager.vfx_container:
		container = GameManager.vfx_container
	elif get_tree() and get_tree().current_scene:
		container = get_tree().current_scene
	if container:
		VfxPlayer.spawn(container, global_position, "levelup")
	var dmg: float = LEVEL_IMPACT_DAMAGE_FALLBACK * damage_multiplier * debug_mult
	var wc: Node = get_node_or_null("WeaponController")
	if wc and "equipped_weapons" in wc:
		var weapons: Array = wc.equipped_weapons
		if not weapons.is_empty() and weapons[0] and "base_damage" in weapons[0]:
			dmg = float(weapons[0].base_damage) * damage_multiplier * debug_mult
	# 击退 + 伤害：遍历存活敌人容器，半径内伤害 + 背离玩家方向击退
	if GameManager and GameManager.enemies_container:
		for enemy in GameManager.enemies_container.get_children():
			if enemy == null or not is_instance_valid(enemy):
				continue
			if not ("is_alive" in enemy and enemy.is_alive):
				continue
			if not enemy.has_method("take_damage"):
				continue
			var dist := global_position.distance_to(enemy.global_position)
			if dist > LEVEL_IMPACT_RADIUS:
				continue
			enemy.take_damage(dmg)
			if enemy.has_method("apply_knockback") and dist > 1.0:
				enemy.apply_knockback(enemy.global_position - global_position, LEVEL_IMPACT_KNOCKBACK)

func _eval_xp_curve() -> float:
	var expr_text: String = ""
	var leveling: Dictionary = DataLoader.get_leveling()
	if not leveling.is_empty():
		expr_text = str(leveling.get("xp_per_level", ""))
	if expr_text.is_empty():
		expr_text = "20 + current_level * 10"
	if _xp_curve_cache == null:
		_xp_curve_cache = Expression.new()
		var err: Error = _xp_curve_cache.parse(expr_text, ["current_level"])
		if err != OK:
			push_warning("[Player] 经验曲线表达式解析失败(%s): %s，回退默认曲线" % [err, expr_text])
			_xp_curve_cache = null
			return 20.0 + float(level) * 10.0
	var result: Variant = _xp_curve_cache.execute([float(level)], _xp_curve_cache)
	if _xp_curve_cache.has_execute_failed():
		push_warning("[Player] 经验曲线求值失败，回退默认曲线")
		return 20.0 + float(level) * 10.0
	return float(result)

