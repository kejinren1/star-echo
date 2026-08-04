## 武器控制器
## 挂载在玩家身上，管理所有武器的自动攻击逻辑
## 初版测试武器：朝鼠标方向自动开火，射程限制为半屏，命中敌人造成伤害
extends Node

# ========== 信号 ==========

signal weapon_fired(weapon: Resource)

# ========== 资源引用 ==========

const ProjectileScene: PackedScene = preload("res://scenes/Projectile.tscn")

# ========== 常量 ==========

## 由 JSON 构建的武器打在 meta 上的来源 id key（供测试/UI 反查）
const META_SOURCE_ID: StringName = &"source_id"

# ========== 属性 ==========

var owner_node: Node2D                        ## 武器所有者（玩家）
var equipped_weapons: Array[Resource] = []    ## 已装备武器列表
var _projectile_container: Node2D             ## 弹丸容器

# ========== 生命周期 ==========

func _ready() -> void:
	owner_node = get_parent() as Node2D
	_projectile_container = _find_container()
	_equip_default_weapon()

## 查找弹丸容器：优先 World/Projectiles，回退到父节点（World）
func _find_container() -> Node2D:
	var world := owner_node.get_parent()
	if world:
		var c := world.get_node_or_null("Projectiles")
		if c:
			return c
		return world
	return null

## 初版固定给玩家一把初始远程武器（武器/道具系统完善后由 Inventory 接管）
func _equip_default_weapon() -> void:
	var w := Weapon.new()
	w.weapon_name = "初始枪"
	w.weapon_type = "ranged"
	w.base_damage = 8.0
	w.fire_rate = 2.5
	w.projectile_speed = 360.0
	# 测试武器射程 = 半屏左右（内部分辨率 640x360，取短边一半 ≈ 180）
	w.attack_range = 180.0
	w.lifetime = 1.5
	w.pierce = 0
	w.knockback = 0.0
	equip_weapon(w)

func _process(delta: float) -> void:
	# 每帧检查所有武器是否可以攻击
	for weapon in equipped_weapons:
		if weapon and weapon.has_method("can_fire") and weapon.can_fire(delta):
			_fire_weapon(weapon)

# ========== 武器管理 ==========

## 装备武器
func equip_weapon(weapon: Resource) -> void:
	if weapon not in equipped_weapons:
		equipped_weapons.append(weapon)

## 卸下武器
func unequip_weapon(weapon: Resource) -> void:
	equipped_weapons.erase(weapon)

# ========== 数据驱动装备（Day 2：角色起始武器接线） ==========

## 按 data/weapons.json 的条目构建一把 Weapon 资源，未知 id 返回 null
## 字段映射：name→weapon_name / _category→weapon_type / damage→base_damage
##          cooldown→fire_rate(取倒数) / range→attack_range / projectiles→projectile_count
func build_weapon_from_data(weapon_id: String) -> Weapon:
	var data: Dictionary = DataLoader.get_weapon(weapon_id)
	if data.is_empty():
		push_warning("[WeaponController] weapons.json 无此武器: %s" % weapon_id)
		return null

	var w := Weapon.new()
	w.weapon_name = str(data.get("name", weapon_id))
	w.weapon_type = DataLoader.get_weapon_category(weapon_id)
	w.description = str(data.get("special", ""))
	w.base_damage = float(data.get("damage", 5.0))
	# JSON 用「冷却秒数」，Weapon 用「每秒次数」
	var cooldown: float = maxf(float(data.get("cooldown", 1.0)), 0.01)
	w.fire_rate = 1.0 / cooldown
	w.attack_range = float(data.get("range", 200.0))
	w.projectile_count = maxi(int(data.get("projectiles", 1)), 1)
	w.knockback = float(data.get("knockback", 0.0))
	# projectile_speed 保留 Weapon 默认 400；lifetime 由 _spawn_projectile() 按 range/speed 推导，不手设
	w.level = 1
	w.max_level = int(data.get("max_level", 5))
	w.set_meta(META_SOURCE_ID, weapon_id)
	return w

## 按 id 装备数据驱动武器，覆盖 _ready() 装上的占位「初始枪」
## 返回是否成功（未知 id 时保留默认武器，保证仍可开火，不崩溃）
func equip_from_data(weapon_id: String) -> bool:
	if weapon_id.is_empty():
		return false
	var w := build_weapon_from_data(weapon_id)
	if w == null:
		return false

	equipped_weapons.clear()
	equip_weapon(w)
	return true

## 取回首把武器的数据来源 id（无来源标记时返回空串，供测试断言）
func get_primary_weapon_id() -> String:
	if equipped_weapons.is_empty():
		return ""
	var first: Resource = equipped_weapons[0]
	if first == null or not first.has_meta(META_SOURCE_ID):
		return ""
	return str(first.get_meta(META_SOURCE_ID))

## 获取最近敌人作为目标（仅用于鼠标未移动时的回退瞄准）
func _find_nearest_enemy() -> Node2D:
	if not GameManager.enemy_spawner or not GameManager.enemy_spawner.enemies_container:
		return null
	var nearest: Node2D = null
	var nearest_dist: float = INF
	for enemy in GameManager.enemy_spawner.enemies_container.get_children():
		if not is_instance_valid(enemy) or not enemy.is_alive:
			continue
		var dist := owner_node.global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy
	return nearest

## 计算瞄准方向：以鼠标世界坐标为准（玩家手动索敌）
## 鼠标未移动（几乎在玩家身上）时回退到最近敌人方向
func _get_aim_direction() -> Vector2:
	var mouse_pos := owner_node.get_global_mouse_position()
	var to_mouse := owner_node.global_position.direction_to(mouse_pos)
	# 鼠标就在玩家身上（还没动过）→ 回退到最近敌人方向，否则朝上
	if owner_node.global_position.distance_to(mouse_pos) < 6.0:
		var near := _find_nearest_enemy()
		if near:
			return owner_node.global_position.direction_to(near.global_position)
		return Vector2.UP
	return to_mouse

## 执行武器攻击（朝鼠标方向自动开火）
func _fire_weapon(weapon: Resource) -> void:
	var aim_dir := _get_aim_direction()
	if aim_dir == Vector2.ZERO:
		return
	# 武器自身的冷却与信号处理（_perform_attack 为各武器子类扩展点）
	weapon.fire(owner_node, null)
	_spawn_projectile(weapon, aim_dir)
	weapon_fired.emit(weapon)

## 生成弹丸
func _spawn_projectile(weapon: Resource, aim_dir: Vector2) -> void:
	if not _projectile_container:
		return
	var proj := ProjectileScene.instantiate()
	# 套用玩家伤害倍率（初版只有 damage_multiplier 这一项，后续扩展更多）
	var dmg: float = weapon.base_damage
	if owner_node and "damage_multiplier" in owner_node:
		dmg *= owner_node.damage_multiplier
	# 射程限制：弹丸存活时间 = 射程 / 弹速，保证子弹飞到半屏就消失
	var travel_time: float = weapon.attack_range / max(weapon.projectile_speed, 1.0)
	proj.initialize({
		"speed": weapon.projectile_speed,
		"damage": dmg,
		"lifetime": travel_time,
		"pierce": weapon.pierce,
		"knockback": weapon.knockback,
	})
	_projectile_container.add_child(proj)
	proj.global_position = owner_node.global_position
	proj.set_direction(aim_dir)
