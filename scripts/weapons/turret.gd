## 临时炮台（Day 4 · D4-T5，承接 D3-T4）
## 由诺亚「紧急部署」技能生成，挂载 World（player.get_parent()），不随玩家移动。
## 数值全部来自 DataLoader.get_weapon("se_auto_turret")（damage:5 / cooldown:0.5 / range:220），
## 禁止硬编码；真精灵登记 Day 21-22 美术债（本日 Polygon2D 运行时绘制占位）。
extends Node2D

# ========== 资源引用 ==========

const ProjectileScene: PackedScene = preload("res://scenes/Projectile.tscn")

# ========== 属性（setup 时从武器数据装载） ==========

var damage: float = 5.0              ## 单发伤害
var fire_interval: float = 0.5       ## 开火间隔（= cooldown）
var attack_range: float = 220.0      ## 射程
var duration_left: float = 15.0      ## 存活剩余（技能 duration）
var permanent: bool = false          ## D13-T3：常驻模式（duration <= 0，不消亡）

var player: Node2D = null            ## 施法玩家（读 damage_multiplier）

var _cd: float = 0.0                 ## 开火冷却计时

# ========== 初始化 ==========

## 由 SkillController._cast_deploy_turret 调用：装载数值 + 绘制占位外观
## D13-T3：duration <= 0 → 常驻模式（permanent=true，不递减时长不消亡）
func setup(weapon_data: Dictionary, duration: float, owner_player: Node2D) -> void:
	damage = float(weapon_data.get("damage", 5.0))
	var cooldown: float = maxf(float(weapon_data.get("cooldown", 0.5)), 0.01)
	fire_interval = cooldown
	attack_range = float(weapon_data.get("range", 220.0))
	permanent = duration <= 0.0
	if not permanent:
		duration_left = maxf(duration, 0.1)
	player = owner_player
	_draw_placeholder()

## 运行时绘制占位方块 + 炮管（对齐 projectile._make_bullet_texture 的运行时生成范式）
func _draw_placeholder() -> void:
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([Vector2(-9, -9), Vector2(9, -9), Vector2(9, 9), Vector2(-9, 9)])
	body.color = Color(0.42, 0.72, 0.98, 0.92)
	add_child(body)
	var barrel := Polygon2D.new()
	barrel.polygon = PackedVector2Array([Vector2(0, -4), Vector2(14, -2), Vector2(14, 2), Vector2(0, 4)])
	barrel.color = Color(0.85, 0.92, 1.0, 1.0)
	add_child(barrel)

# ========== 行为 ==========

func _process(delta: float) -> void:
	# 存活计时（禁用 Timer 节点：无头下 SceneTree 计时更易漂，直接每帧递减）
	# D13-T3：常驻模式跳过时长递减与消亡分支（se_turret_array 进化后炮台不消失）
	if not permanent:
		duration_left -= delta
		if duration_left <= 0.0:
			queue_free()
			return
	_cd -= delta
	if _cd > 0.0:
		return
	var target: Node2D = _find_target()
	if target == null:
		return  # 无敌人空转不开火
	_cd = fire_interval
	_fire(target)

## 射程内最近敌人（复用 enemy_spawner.enemies_container 遍历范式，同 skill_controller）
func _find_target() -> Node2D:
	if GameManager.enemy_spawner == null or GameManager.enemy_spawner.enemies_container == null:
		return null
	var nearest: Node2D = null
	var nearest_dist: float = INF
	for enemy in GameManager.enemy_spawner.enemies_container.get_children():
		if not is_instance_valid(enemy) or not enemy.get("is_alive"):
			continue
		var dist: float = global_position.distance_to(enemy.global_position)
		if dist <= attack_range and dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy
	return nearest

## 向目标开火（弹速 400，寿命 = 射程/弹速，与 weapon_controller 同一口径）
func _fire(target: Node2D) -> void:
	var container: Node2D = _find_container()
	if container == null:
		return
	var proj := ProjectileScene.instantiate()
	var dmg: float = damage
	if player and "damage_multiplier" in player:
		dmg *= float(player.damage_multiplier)
	proj.initialize({
		"speed": 400.0,
		"damage": dmg,
		"lifetime": attack_range / 400.0,
		"pierce": 0,
		"knockback": 0.0,
	})
	container.add_child(proj)
	proj.global_position = global_position
	proj.set_direction(global_position.direction_to(target.global_position))

## 弹丸容器：World/Projectiles 优先，回退 World（复用 WeaponController._find_container 策略）
func _find_container() -> Node2D:
	var world := get_parent()
	if world:
		var c: Node = world.get_node_or_null("Projectiles")
		if c is Node2D:
			return c
		return world
	return null
