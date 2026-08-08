## 环绕武器（Day 5 · D5-T4）：星刃类武器绕玩家旋转的独立驱动节点
## 由 WeaponController._sync_orbit_weapon 在装备 orbit 武器时创建，挂 Player 子节点
## （跟随玩家移动）。不自发弹丸；接触伤害用容器遍历（复用 _find_nearest_enemy 范式，
## 禁物理查询——无头测试下物理帧不可靠，D3 教训）。
##
## 实际刃数 = weapon.orbit_data.blade_count + player.bonus_stats.orbit_blade_count
## —— 莱恩「星刃爆发」技能（D3-T5）埋的键在此消费收口，只读不写。
extends Node2D
class_name OrbitWeapon

# ========== 常量 ==========

## 刃体占位三角形尺寸（像素；真精灵登记 Day 21-22 美术债）
const BLADE_SIZE: Vector2 = Vector2(8, 12)
## 刃接触判定半径（像素）
const HIT_RADIUS: float = 12.0
## F-08（用户拍板 2026-08-06）：玩家贴身必中半径（像素）——环绕刃视觉在 orbit_radius 外
## 旋转，贴身敌人若只靠刀刃圆环判定将「看得见打不着」；追加以玩家为中心的必中圆
## （覆盖玩家碰撞体 24×28 + 余量），贴身怪任意刃经过即命中 → 贴近必中
const PLAYER_HIT_RADIUS: float = 44.0

# ========== 状态 ==========

var weapon: Resource = null
var player: Node2D = null
var _blades: Array[Polygon2D] = []   ## 渲染的刃（子节点）
var _angles: Array[float] = []       ## 每刃当前角（度）
var _hit_cd: Array[float] = []       ## 每刃命中冷却计时

# ========== 生命周期 ==========

## 由 WeaponController 调用：绑定武器与玩家并重建刃（可重复调用以同步升级）
func setup(w: Resource, p: Node2D) -> void:
	weapon = w
	player = p
	_sync_blades()

func _process(delta: float) -> void:
	if not is_instance_valid(player) or not is_instance_valid(weapon):
		# 玩家已死/武器已释放 → 停驱动（节点清理由 _sync_orbit_weapon 负责）
		set_process(false)
		return
	# 刃数变化（升级 / 莱恩技能生效到期）→ 自动重建
	if _blades.size() != _current_blade_count():
		_sync_blades()
	if _blades.is_empty():
		return

	var radius: float = float(weapon.orbit_data.get("orbit_radius", 110.0))
	var speed: float = float(weapon.orbit_data.get("orbit_speed", 180.0))
	# 命中冷却递减
	for i in _hit_cd.size():
		_hit_cd[i] = maxf(_hit_cd[i] - delta, 0.0)
	# 旋转 + 摆位 + 命中判定
	for i in _blades.size():
		_angles[i] = fmod(_angles[i] + speed * delta, 360.0)
		_blades[i].position = Vector2.from_angle(deg_to_rad(_angles[i])) * radius
		_check_hit(i)

# ========== 刃管理 ==========

## 实际刃数 = 武器数据 + 技能/被动加成（D3-T5 埋点收口）
func _current_blade_count() -> int:
	var base: int = int(weapon.orbit_data.get("blade_count", 1))
	var bonus: int = 0
	if player and "bonus_stats" in player:
		bonus = int(float(player.bonus_stats.get("orbit_blade_count", 0.0)))
	return maxi(base + bonus, 1)

## 重建刃到当前数量（释放旧刃 → 按数量均布角度重建）
## F-22（用户拍板 2026-08-08）：进化形态（weapons.json evolution_result=true，如
## 星刃风暴）刃体换金色 + 放大 1.25x，与基础星刃蓝白形成直观差异——补「买核心进化
## 无直观感受」；沿用占位纯色机制（用户 08-07 美术策略，不强制色号编码）
func _sync_blades() -> void:
	for blade in _blades:
		if is_instance_valid(blade):
			blade.queue_free()
	_blades.clear()
	_angles.clear()
	_hit_cd.clear()
	var evolved: bool = bool(weapon.get_meta("evolution_result", false))
	var blade_color: Color = Color(1.0, 0.78, 0.2) if evolved else Color(0.65, 0.85, 1.0)
	var size_scale: float = 1.25 if evolved else 1.0
	var count: int = _current_blade_count()
	for i in count:
		var blade := Polygon2D.new()
		blade.polygon = PackedVector2Array([
			Vector2(0.0, -BLADE_SIZE.y / 2.0 * size_scale),
			Vector2(BLADE_SIZE.x / 2.0 * size_scale, BLADE_SIZE.y / 2.0 * size_scale),
			Vector2(-BLADE_SIZE.x / 2.0 * size_scale, BLADE_SIZE.y / 2.0 * size_scale),
		])
		blade.color = blade_color  # 基础星刃蓝白 / 进化星刃风暴金色
		add_child(blade)
		_blades.append(blade)
		_angles.append(float(i) * 360.0 / float(count))
		_hit_cd.append(0.0)

# ========== 命中 ==========

## 单刃接触判定：容器遍历（禁物理查询），命中后套玩家倍率并进入该刃冷却
## F-08（用户拍板 2026-08-06）：判定 = 刃位置命中 **或** 玩家贴身圆命中——贴身怪必中
func _check_hit(i: int) -> void:
	if _hit_cd[i] > 0.0:
		return
	if not GameManager.enemy_spawner or not GameManager.enemy_spawner.enemies_container:
		return
	var blade_pos: Vector2 = _blades[i].global_position
	for enemy in GameManager.enemy_spawner.enemies_container.get_children():
		if not is_instance_valid(enemy) or not enemy.is_alive:
			continue
		var on_blade: bool = blade_pos.distance_to(enemy.global_position) <= HIT_RADIUS
		var on_player_core: bool = false
		if is_instance_valid(player) and player.get("is_alive") != false:
			on_player_core = player.global_position.distance_to(enemy.global_position) <= PLAYER_HIT_RADIUS
		if on_blade or on_player_core:
			var dmg: float = weapon.get_damage()
			if player and "damage_multiplier" in player:
				dmg *= player.damage_multiplier
			enemy.take_damage(dmg)
			_hit_cd[i] = weapon.get_attack_interval()
			break
