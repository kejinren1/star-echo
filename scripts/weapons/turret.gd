## 临时炮台（Day 4 · D4-T5，承接 D3-T4）
## 由诺亚「紧急部署」技能生成，挂载 World（player.get_parent()），不随玩家移动。
## 数值全部来自 DataLoader.get_weapon("se_auto_turret")（damage:5 / cooldown:0.5 / range:220），
## 禁止硬编码；真精灵登记 Day 21-22 美术债（本日 Polygon2D 运行时绘制占位）。
extends Node2D

# ========== 资源引用 ==========

const ProjectileScene: PackedScene = preload("res://scenes/Projectile.tscn")

## F1-E-7（2026-08-19 #3 执行 · T-024）：炮台默认值兜底——原 :13-15 字段声明
## 默认值 + setup() 装载兜底两处散落硬编码的收敛事实源；现值与 weapons 表
## se_auto_turret 行（damage 5 / cooldown 0.5 / range 220）一致，实际运行时
## 默认值优先读 Excel turret_config 表（DataLoader.get_turret_config 命中），
## 未命中/空表/无 DataLoader → 本 const 兜底（F 系列缺省兜底约定）。
const TURRET_DEFAULTS := {"damage": 5.0, "fire_interval": 0.5, "attack_range": 220.0}

# ========== 属性（setup 时从武器数据装载） ==========

var damage: float = TURRET_DEFAULTS["damage"]              ## 单发伤害
var fire_interval: float = TURRET_DEFAULTS["fire_interval"] ## 开火间隔（= cooldown）
var attack_range: float = TURRET_DEFAULTS["attack_range"]   ## 射程
var duration_left: float = 15.0      ## 存活剩余（技能 duration）
var duration_max: float = 15.0       ## T-C：初始存活时长（生命周期进度条比例基准）
var permanent: bool = false          ## D13-T3：常驻模式（duration <= 0，不消亡）

var player: Node2D = null            ## 施法玩家（读 damage_multiplier）

var _cd: float = 0.0                 ## 开火冷却计时
var _life_bg: Polygon2D = null       ## T-C：生命周期进度条背景（仅临时炮台）
var _life_fg: Polygon2D = null       ## T-C：生命周期进度条前景（剩余比例宽度）
var _warn_timer: float = 0.0         ## T-C：最后 3 秒闪烁计时

# ========== 初始化 ==========

## 由 SkillController._cast_deploy_turret 调用：装载数值 + 绘制占位外观
## D13-T3：duration <= 0 → 常驻模式（permanent=true，不递减时长不消亡）
func setup(weapon_data: Dictionary, duration: float, owner_player: Node2D) -> void:
	var defaults: Dictionary = _resolve_turret_defaults()
	damage = float(weapon_data.get("damage", defaults.get("damage", TURRET_DEFAULTS["damage"])))
	var cooldown: float = maxf(float(weapon_data.get("cooldown", defaults.get("fire_interval", TURRET_DEFAULTS["fire_interval"]))), 0.01)
	fire_interval = cooldown
	attack_range = float(weapon_data.get("range", defaults.get("attack_range", TURRET_DEFAULTS["attack_range"])))
	permanent = duration <= 0.0
	if not permanent:
		duration_left = maxf(duration, 0.1)
		duration_max = duration_left
	player = owner_player
	_draw_placeholder()

## F1-E-7（2026-08-19 #3 执行 · T-024）：炮台默认值解析——presentation.json
## turret_config（经 DataLoader.get_turret_config）命中 se_auto_turret 优先；
## 未命中/空表/无 DataLoader → 回退 TURRET_DEFAULTS const 兜底
## （F 系列缺省兜底约定，仿 vfx_player._resolve_fx_config 范式）。
func _resolve_turret_defaults() -> Dictionary:
	var loader: Node = get_node_or_null("/root/DataLoader")
	if loader != null and loader.has_method("get_turret_config"):
		var cfg: Variant = loader.get_turret_config().get("se_auto_turret", null)
		if cfg is Dictionary and not (cfg as Dictionary).is_empty():
			return cfg
	return TURRET_DEFAULTS

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
	# T-C（用户反馈 2026-08-06）：生命周期视觉提示——底部 20×2px 进度条
	# （临时炮台到点即消失，此前无任何视觉信号 → 真人「没看到实际效果」）
	# 常驻模式（permanent）永不消亡，不显示进度条
	if not permanent:
		_life_bg = Polygon2D.new()
		_life_bg.polygon = PackedVector2Array([Vector2(-10, 11), Vector2(10, 11), Vector2(10, 13), Vector2(-10, 13)])
		_life_bg.color = Color(0.08, 0.08, 0.1, 0.65)
		add_child(_life_bg)
		_life_fg = Polygon2D.new()
		_life_fg.polygon = PackedVector2Array([Vector2(-10, 11), Vector2(10, 11), Vector2(10, 13), Vector2(-10, 13)])
		_life_fg.color = Color(0.35, 0.95, 0.6, 0.95)
		add_child(_life_fg)

# ========== 行为 ==========

func _process(delta: float) -> void:
	# 存活计时（禁用 Timer 节点：无头下 SceneTree 计时更易漂，直接每帧递减）
	# D13-T3：常驻模式跳过时长递减与消亡分支（se_turret_array 进化后炮台不消失）
	if not permanent:
		duration_left -= delta
		_update_life_bar(delta)
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
	var dmg: float = damage
	if player and "damage_multiplier" in player:
		dmg *= float(player.damage_multiplier)
	# D20-T6 §5：结构伤害倍率消费（se_mech_core/se_mech_engine 装配后弹药伤害放大；
	# 默认 1.0 零回归，顺带激活 mech_heart/se_mech_core 悬空 structure_damage_percent 词条）
	if player and "structure_damage_mult" in player:
		dmg *= float(player.structure_damage_mult)
	var props := {
		"speed": 400.0,
		"damage": dmg,
		"lifetime": attack_range / 400.0,
		"pierce": 0,
		"knockback": 0.0,
	}
	# F2-T4：优先经 World.spawn_projectile 工厂（统一挂 Projectiles 容器）；
	# World 缺失环境（探针白盒）→ 兜底旧路径（initialize + 缓存容器 add_child）
	var proj: Node2D = null
	if GameManager and is_instance_valid(GameManager.world) and GameManager.world.has_method("spawn_projectile"):
		proj = GameManager.world.spawn_projectile(ProjectileScene, props)
	else:
		var container: Node2D = _resolve_projectile_container()
		if container == null:
			return
		proj = ProjectileScene.instantiate() as Node2D
		proj.initialize(props)
		container.add_child(proj)
	if proj == null:
		return
	proj.global_position = global_position
	proj.set_direction(global_position.direction_to(target.global_position))

## T-C（用户反馈 2026-08-06）：更新生命周期进度条——前景宽度 = 剩余比例；
## 最后 3 秒前景变红 + 闪烁（感知「即将消失」，防突然消失无提示）
func _update_life_bar(delta: float) -> void:
	if _life_fg == null:
		return
	var ratio: float = clampf(duration_left / duration_max, 0.0, 1.0)
	var warn: bool = duration_left <= 3.0
	if warn:
		_warn_timer += delta
		var blink_on: bool = int(_warn_timer * 6.0) % 2 == 0
		_life_fg.color = Color(0.95, 0.3, 0.3, 0.95 if blink_on else 0.35)
	else:
		_life_fg.color = Color(0.35, 0.95, 0.6, 0.95)
	_life_fg.polygon = PackedVector2Array([
		Vector2(-10, 11),
		Vector2(-10 + 20.0 * ratio, 11),
		Vector2(-10 + 20.0 * ratio, 13),
		Vector2(-10, 13),
	])

## F2-T3：容器访问统一走 World.get_container（消灭复制粘贴 _find_container）。
## 回退链：GameManager.world（main._ready 注入）→ 父级 World（turret 挂 World 下；
## Projectiles 不存在时返回 World = 原 _find_container 语义）
func _resolve_projectile_container() -> Node2D:
	if GameManager and is_instance_valid(GameManager.world) and GameManager.world.has_method("get_container"):
		var c: Node = GameManager.world.get_container("projectiles")
		if c is Node2D:
			return c
	var world_node := get_parent()
	if world_node:
		var c: Node = world_node.get_node_or_null("Projectiles")
		if c is Node2D:
			return c
		return world_node
	return null
