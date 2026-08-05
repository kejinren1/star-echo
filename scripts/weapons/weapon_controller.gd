## 武器控制器
## 挂载在玩家身上，管理所有武器的自动攻击逻辑
## 初版测试武器：朝鼠标方向自动开火，射程限制为半屏，命中敌人造成伤害
extends Node

# ========== 信号 ==========

signal weapon_fired(weapon: Resource)

# ========== 资源引用 ==========

const ProjectileScene: PackedScene = preload("res://scenes/Projectile.tscn")
## preload 而非依赖 class_name：无头 `--script` 模式（main.gd:20 同策略）对新类
## 首次引入更稳；orbit_weapon.gd 的 class_name OrbitWeapon 保留供其它引用
const OrbitWeaponScript: GDScript = preload("res://scripts/weapons/orbit_weapon.gd")

# ========== 常量 ==========

## 由 JSON 构建的武器打在 meta 上的来源 id key（供测试/UI 反查）
const META_SOURCE_ID: StringName = &"source_id"

## 武器槽上限（大纲：最多 6 槽；D5-T1）
const MAX_SLOTS: int = 6

# ========== 属性 ==========

var owner_node: Node2D                        ## 武器所有者（玩家）
var equipped_weapons: Array[Resource] = []    ## 已装备武器列表
var _projectile_container: Node2D             ## 弹丸容器
var orbit_node: Node2D = null                 ## 环绕武器节点（D5-T4，运行时创建，挂 Player 子节点）

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
		if not weapon or not weapon.has_method("can_fire"):
			continue
		# 环绕武器不自发弹丸（D5-T4：由 OrbitWeapon 节点独立驱动旋转 + 接触伤害）
		if weapon.orbit_data and not weapon.orbit_data.is_empty():
			continue
		if weapon.can_fire(delta):
			_fire_weapon(weapon)

# ========== 武器管理 ==========

## 装备武器（D5-T1 返回 bool）：
## 已在列表 / 槽位已满（>= MAX_SLOTS）→ 拒绝返回 false，已装备不受影响；
## 「替换旧武器」交互归 Day 11-12 商店体系，本日不做
func equip_weapon(weapon: Resource) -> bool:
	if weapon in equipped_weapons or equipped_weapons.size() >= MAX_SLOTS:
		return false
	equipped_weapons.append(weapon)
	_sync_orbit_weapon()
	return true

## 卸下武器
func unequip_weapon(weapon: Resource) -> void:
	equipped_weapons.erase(weapon)
	_sync_orbit_weapon()

## 当前已装备武器数
func get_slot_count() -> int:
	return equipped_weapons.size()

## 槽位是否已满
func is_full() -> bool:
	return equipped_weapons.size() >= MAX_SLOTS

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
	# D5-T2：逐级状态表 + max_level 口径（防 levels 表 8 条而 max_level 缺省时只能升到 5）
	w.level_table = data.get("levels", []) as Array
	w.max_level = maxi(int(data.get("max_level", 5)), w.level_table.size())
	# D5-T2：环绕武器（se_star_blade 类）→ 存 orbit 数据；升级时由 levels 表覆写
	if data.has("blade_count"):
		w.orbit_data = {
			"blade_count": int(data.get("blade_count", 1)),
			"orbit_radius": float(data.get("orbit_radius", 110.0)),
			"orbit_speed": float(data.get("orbit_speed", 180.0)),
		}
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

# ========== 环绕武器（D5-T4） ==========

## 扫描已装备武器，维护 OrbitWeapon 节点（挂 Player 子节点，跟随移动）：
##   无 orbit 武器 → 清理已有节点；有 → 创建/复用节点并 setup
## 由 equip_weapon / unequip_weapon 末尾调用；Player.tscn 无需预置该节点
func _sync_orbit_weapon() -> void:
	var orbit_weapon: Resource = null
	for weapon in equipped_weapons:
		if weapon and weapon.orbit_data and not weapon.orbit_data.is_empty():
			orbit_weapon = weapon
			break
	if orbit_weapon == null:
		if orbit_node and is_instance_valid(orbit_node):
			orbit_node.queue_free()
		orbit_node = null
		return
	if orbit_node == null or not is_instance_valid(orbit_node):
		orbit_node = OrbitWeaponScript.new()
		owner_node.add_child(orbit_node)
		orbit_node.name = "OrbitWeapon"
	orbit_node.setup(orbit_weapon, owner_node)
