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
	# D13 收口：玩家攻速倍率消费点 —— 作用于武器冷却递减速率（delta × atk_mult）。
	# base 1.0 时行为与旧版完全一致（零回归）；升级「攻速+5%」/ 诺亚被动 / 莱恩 buff
	# / coffee 被动从此真实生效（此前仅装配无消费点）。炮台为独立攻击（turret.gd 自驱）
	# 不受攻速影响（召唤物不享攻速，设计内）。
	var atk_mult: float = 1.0
	if owner_node and "attack_speed" in owner_node:
		atk_mult = maxf(float(owner_node.attack_speed), 0.01)
	# 每帧检查所有武器是否可以攻击
	for weapon in equipped_weapons:
		if not weapon or not weapon.has_method("can_fire"):
			continue
		# 环绕武器不自发弹丸（D5-T4：由 OrbitWeapon 节点独立驱动旋转 + 接触伤害）
		if weapon.orbit_data and not weapon.orbit_data.is_empty():
			continue
		if weapon.can_fire(delta * atk_mult):
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
	# D13-T2：战斗副本变化 → 同步 inventory（HUD 读数源；进局/商店双写幂等）
	sync_inventory_weapons()
	return true

## 卸下武器
func unequip_weapon(weapon: Resource) -> void:
	equipped_weapons.erase(weapon)
	_sync_orbit_weapon()
	# D13-T2：同步 inventory（同上）
	sync_inventory_weapons()

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
	# D7-T2：装配消费补齐（crit_chance/crit_damage/pierce/icon_index），
	# 沿用 data.get(..., 默认) 兜底范式，字段缺失不崩；旧武器默认 0.0/1.0/0/0
	w.crit_chance = float(data.get("crit_chance", 0.0))
	w.crit_damage = float(data.get("crit_damage", 1.0))
	w.pierce = maxi(int(data.get("pierce", 0)), 0)
	w.icon_index = maxi(int(data.get("icon_index", 0)), 0)
	# D11-12-T4：商店价格透传（weapon.gd 新增 price 字段；商店卡片显示与购买扣费用）
	w.price = maxi(int(data.get("price", 0)), 0)
	# D10-T3：爆炸 AOE 字段（se_star_fall 陨石）；0 默认 = 不爆炸（projectile 既有逻辑天然跳过）
	w.explosion_radius = float(data.get("explosion_radius", 0.0))
	w.explosion_damage = float(data.get("explosion_damage", 0.0))
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
	# F-22（用户拍板 2026-08-08）：进化形态标志透传（weapons.json evolution_result 字段，
	# 仅结果武器为 true）——orbit_weapon 据此给进化武器换渲染色/尺寸，补「进化无直观感受」
	w.set_meta(&"evolution_result", bool(data.get("evolution_result", false)))
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

## 进化替换（D10-T3）：把已装备的 target 武器原子替换为 replacement_id 构建的新武器
## 1) 目标不在已装备列表 → null（不崩、不改任何武器）
## 2) build_weapon_from_data 失败（未知 id）→ null（原武器不动）
## 3) 新武器循环升级至满级（≤7 次，_on_upgrade 查表绝对覆盖；结果武器平曲线 = 进化强度）
## 4) 原位替换 + _sync_orbit_weapon() 一次（避免 equip/unequip 两次 sync）
## 返回新武器（成功）或 null（失败）；调用方在成功后才可消耗进化核心
func replace_weapon(target: Resource, replacement_id: String) -> Weapon:
	if target == null or replacement_id.is_empty():
		return null
	var idx: int = equipped_weapons.find(target)
	if idx < 0:
		push_warning("[WeaponController] replace_weapon: 目标武器不在已装备列表")
		return null
	var w := build_weapon_from_data(replacement_id)
	if w == null:
		return null
	while w.level < w.max_level:
		w.upgrade()
	equipped_weapons[idx] = w
	_sync_orbit_weapon()
	# D11-12-T5：同步 inventory.weapons（进化后 HUD 读 inventory 显示结果武器；无匹配跳过不崩）
	_sync_inventory_weapon(target, w)
	return w

## D11-12-T5：按 meta source_id 匹配 inventory.weapons 旧条目原位替换（直开 Main.tscn 调试路径无匹配 → 静默跳过）
func _sync_inventory_weapon(old_weapon: Resource, new_weapon: Resource) -> void:
	if GameManager.inventory == null:
		return
	var inv_weapons: Array = GameManager.inventory.get("weapons")
	if inv_weapons == null:
		return
	var old_id: String = ""
	if old_weapon and old_weapon.has_meta(META_SOURCE_ID):
		old_id = str(old_weapon.get_meta(META_SOURCE_ID))
	for i in inv_weapons.size():
		var w: Resource = inv_weapons[i]
		if w == null:
			continue
		var w_id: String = str(w.get_meta(META_SOURCE_ID, "")) if w.has_meta(META_SOURCE_ID) else ""
		if w == old_weapon or (not old_id.is_empty() and w_id == old_id):
			GameManager.inventory.call("replace_weapon_slot", i, new_weapon)
			return

## D13-T2：武器两套体系统一入口 —— 按 equipped_weapons 的 meta source_id 顺序
## 全量重建 inventory.weapons（HUD 读数源 = inventory，战斗实装 = equipped_weapons）。
## 无 source_id 条目（初始枪占位等）跳过；GameManager.inventory 为 null（直开 Main.tscn
## 早期 / 测试环境）静默返回不崩。幂等：重复调用无副作用（全量重建非追加）。
## 触发 HUD 刷新：清空前非空 → weapon_removed；重建后非空 → weapon_added。
func sync_inventory_weapons() -> void:
	if GameManager.inventory == null:
		return
	var inv: Node = GameManager.inventory
	if not ("weapons" in inv):
		return
	var inv_weapons: Array = inv.get("weapons")
	if inv_weapons == null:
		return
	var had_content: bool = not inv_weapons.is_empty()
	inv_weapons.clear()
	for w in equipped_weapons:
		if w == null or not w.has_meta(META_SOURCE_ID):
			continue
		inv_weapons.append(w)
	# HUD 刷新信号（存在才 emit；重绘全槽位，一次足够）
	if inv.has_signal("weapon_removed") and had_content:
		inv.weapon_removed.emit(0)
	if inv.has_signal("weapon_added") and not inv_weapons.is_empty():
		inv.weapon_added.emit(inv_weapons[0])

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
	# D21-22-T3：开火 → 播玩家 attack 动画（owner 无该方法/动画缺失时静默降级）
	if owner_node and owner_node.has_method("_play_attack_anim"):
		owner_node._play_attack_anim()

## 生成弹丸
func _spawn_projectile(weapon: Resource, aim_dir: Vector2) -> void:
	if not _projectile_container:
		return
	var proj := ProjectileScene.instantiate()
	# 套用玩家伤害倍率（初版只有 damage_multiplier 这一项，后续扩展更多）
	var dmg: float = weapon.base_damage
	if owner_node and "damage_multiplier" in owner_node:
		dmg *= owner_node.damage_multiplier
	# F-04（金手指）：debug_mult 攻击倍率（默认 1.0 零回归；toggle_debug_cheat 置 10）
	if owner_node and "debug_mult" in owner_node:
		dmg *= float(owner_node.debug_mult)
	# D13-T1：聚合暴击通道 —— 玩家属性为权威，武器 crit_chance 平加（clamp 0~0.9），
	# crit_mult 取玩家 crit_damage（weapon.crit_damage 字段保留登记、结算不叠加）
	var crit_chance: float = 0.0
	var crit_mult: float = 1.0
	if owner_node:
		var p_crit: float = float(owner_node.get("crit_chance")) if "crit_chance" in owner_node else 0.0
		crit_chance = clampf(p_crit + weapon.crit_chance, 0.0, 0.9)
		var p_cmult: float = float(owner_node.get("crit_damage")) if "crit_damage" in owner_node else 1.0
		crit_mult = maxf(p_cmult, 1.0)
	# 射程限制：弹丸存活时间 = 射程 / 弹速，保证子弹飞到半屏就消失
	var travel_time: float = weapon.attack_range / max(weapon.projectile_speed, 1.0)
	proj.initialize({
		"speed": weapon.projectile_speed,
		"damage": dmg,
		"lifetime": travel_time,
		"pierce": weapon.pierce,
		"knockback": weapon.knockback,
		# D10-T3：爆炸 AOE 透传（projectile.initialize 已支持 :155-158）；
		# explosion_damage 兜底 = base_damage；radius <= 0 时 projectile 不爆炸，零回归
		"explosion_radius": weapon.explosion_radius,
		"explosion_damage": weapon.explosion_damage if weapon.explosion_damage > 0.0 else dmg,
		# D13-T1：暴击透传（projectile 缺省 0/1.0 = 不暴击，技能弹丸等未透传路径零回归）
		"crit_chance": crit_chance,
		"crit_mult": crit_mult,
	})
	_projectile_container.add_child(proj)
	proj.global_position = owner_node.global_position
	proj.set_direction(aim_dir)
	# Day 23-T4：弹丸携带武器来源标记（D13-T2 meta 范式）——projectile._explode
	# 按 source_id 分派专属 VFX（se_star_fall 进化陨石 → "meteor"）；其余武器 meta
	# 虽带上但判定兜底 crit，零回归
	proj.set_meta(META_SOURCE_ID, str(weapon.get_meta(META_SOURCE_ID, "")))

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
