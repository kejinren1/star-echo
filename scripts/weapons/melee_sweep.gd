## 近战扇形挥砍（PS · 2026-08-17 用户拍板：莱恩普攻从「环绕小三角」改为周期性扇形 AOE）
## 由 WeaponController 在装备 arc_angle>0 的武器时创建，挂 Player 子节点（跟随移动）。
## 周期挥砍：按武器 fire_rate 冷却；面向鼠标方向；扇形（角度 ±arc_angle/2、距离 attack_range）
## 内所有敌人同时受到伤害（套玩家倍率/暴击/近战加成——伤害通道对齐 weapon_controller
## _spawn_projectile 口径）；挥砍时播放扇形刀光特效（Polygon2D 弧形，展开 + 淡出）。
## 判定用容器遍历（禁物理查询——无头测试下物理帧不可靠，D3 教训，同 orbit_weapon 范式）。
extends Node2D

# ========== 常量 ==========

## 刀光弧线分段数（像素弧线平滑度）
const ARC_SEGMENTS: int = 14
## 刀光总时长（展开 + 淡出，秒）
const SLASH_DURATION: float = 0.24
## 展开占比（前段时间完成扇形展开，后段纯淡出）
const EXPAND_RATIO: float = 0.55
## 射程门控判定用（对齐 F-32：无敌人在射程内不空挥）
const AIM_DEADZONE: float = 6.0

# ========== 状态 ==========

var weapon: Resource = null
var player: Node2D = null
var _cooldown: float = 0.0
var _slash_t: float = -1.0                 ## 当前刀光动画进度（<0 = 无）
var _slash_dir: Vector2 = Vector2.RIGHT    ## 本次挥砍方向
var _slash_angle: float = 100.0            ## 本次挥砍角度（度）
var _fx: Polygon2D = null                  ## 刀光扇形节点

# ========== 生命周期 ==========

## 由 WeaponController 调用：绑定武器与玩家（可重复调用以同步升级/换武器）
func setup(w: Resource, p: Node2D) -> void:
	weapon = w
	player = p
	_cooldown = 0.0
	_slash_t = -1.0
	if _fx == null:
		_fx = Polygon2D.new()
		_fx.z_index = 5
		add_child(_fx)
		_fx.visible = false

func _process(delta: float) -> void:
	if not is_instance_valid(player) or not is_instance_valid(weapon):
		set_process(false)
		return
	_cooldown -= delta
	# 刀光动画推进（展开 → 淡出）
	if _slash_t >= 0.0:
		_slash_t += delta
		if _slash_t >= SLASH_DURATION:
			_slash_t = -1.0
			if _fx:
				_fx.visible = false
		else:
			_update_fx()
	# 冷却完成且射程内有存活敌人 → 挥砍（F-32 门控：无目标不空挥）
	if _cooldown <= 0.0 and _has_enemy_in_range():
		_do_slash()

# ========== 挥砍 ==========

## 执行一次扇形挥砍：刷新刀光 + 判定扇形内全部敌人
## 冷却守卫（防御性）：_process 调度与外部直调双路径安全，防重复挥砍
func _do_slash() -> void:
	if _cooldown > 0.0:
		return
	_cooldown = weapon.get_attack_interval()
	_slash_dir = _get_aim_direction()
	_slash_angle = maxf(weapon.arc_angle, 45.0)
	_slash_t = 0.0
	_update_fx()
	# 播玩家攻击动画（对齐弹丸开火 D21-22-T3 行为；无该方法/动画缺失时静默降级）
	if player and player.has_method("_play_attack_anim"):
		player._play_attack_anim()
	var dmg: float = _compute_damage()
	var crit_chance: float = _compute_crit_chance()
	var crit_mult: float = _compute_crit_mult()
	var container: Node = _enemy_container()
	if container == null:
		return
	var any_crit: bool = false
	for enemy in container.get_children():
		if not is_instance_valid(enemy) or enemy.get("is_alive") != true:
			continue
		if not _enemy_in_arc(enemy):
			continue
		var is_crit: bool = randf() < crit_chance
		any_crit = any_crit or is_crit
		var final_dmg: float = dmg * (crit_mult if is_crit else 1.0)
		enemy.call("take_damage", final_dmg, is_crit)
	# AUDIO_FEEL（AF-P0-A2/B2 · O-2 近战重 + F2 分级）：近战挥砍命中 → hitstop + 震屏
	# （扇内至少命中 1 敌；暴击追加取 max 合并）；控制器/场景缺失 = 零顿帧零回归
	var hs: Node = GameManager.hitstop_controller if GameManager else null
	if hs != null and is_instance_valid(hs):
		var feel: Dictionary = DataLoader.get_stats_feel()
		var dur: float = float(feel.get("hitstop_melee", 0.15))
		if any_crit:
			dur = maxf(dur, float(feel.get("hitstop_crit_bonus", 0.1)))
		hs.call("trigger", dur)
	# ⚠️ get_node_or_null 是 Node 方法（get_tree() 返回 SceneTree 无此方法——踩坑登记）
	var main_node: Node = player.get_node_or_null("/root/Main") if player else null
	if main_node != null and main_node.has_method("_trigger_camera_shake"):
		main_node.call("_trigger_camera_shake", "medium" if any_crit else "light")

## 伤害计算：base × 玩家伤害倍率 × 近战加成 × 金手指（对齐 weapon_controller._spawn_projectile）
func _compute_damage() -> float:
	var dmg: float = weapon.get_damage()
	if player and "damage_multiplier" in player:
		dmg *= float(player.damage_multiplier)
	if player and "bonus_stats" in player:
		dmg *= 1.0 + float(player.bonus_stats.get("melee_damage", 0.0)) / 100.0
	if player and "debug_mult" in player:
		dmg *= float(player.debug_mult)
	return dmg

## 暴击率：玩家属性为权威，武器 crit_chance 平加（clamp 0~0.9，同 D13-T1 口径）
func _compute_crit_chance() -> float:
	var p_crit: float = float(player.get("crit_chance")) if player and "crit_chance" in player else 0.0
	return clampf(p_crit + weapon.crit_chance, 0.0, 0.9)

## 暴击倍率：取玩家 crit_damage（同 D13-T1 口径）
func _compute_crit_mult() -> float:
	var p_cmult: float = float(player.get("crit_damage")) if player and "crit_damage" in player else 1.0
	return maxf(p_cmult, 1.0)

## 敌人是否在扇形内：距离 <= attack_range + 敌人体积余量；方向夹角 <= arc_angle/2
func _enemy_in_arc(enemy: Node) -> bool:
	var dist: float = player.global_position.distance_to(enemy.global_position)
	var range_allow: float = weapon.attack_range + 14.0
	if dist > range_allow:
		return false
	var to_enemy: Vector2 = player.global_position.direction_to(enemy.global_position)
	var half: float = deg_to_rad(_slash_angle) * 0.5
	return _slash_dir.angle_to(to_enemy) <= half and _slash_dir.angle_to(to_enemy) >= -half

## 射程门控：扇形半径内是否有存活敌人（F-32 同款：spawner 缺失视为无目标）
func _has_enemy_in_range() -> bool:
	var container: Node = _enemy_container()
	if container == null:
		return false
	for enemy in container.get_children():
		if not is_instance_valid(enemy) or enemy.get("is_alive") != true:
			continue
		if player.global_position.distance_to(enemy.global_position) <= weapon.attack_range + 14.0:
			return true
	return false

## 敌人容器（GameManager.enemies_container 兜底，同 orbit_weapon 范式）
func _enemy_container() -> Node:
	if GameManager and GameManager.enemy_spawner and GameManager.enemy_spawner.enemies_container:
		return GameManager.enemy_spawner.enemies_container
	if GameManager and GameManager.enemies_container:
		return GameManager.enemies_container
	return null

## 瞄准方向：鼠标世界坐标优先；鼠标贴身未动时回退最近敌人方向（同 weapon_controller）
func _get_aim_direction() -> Vector2:
	if player == null:
		return Vector2.RIGHT
	var mouse_pos := player.get_global_mouse_position()
	if player.global_position.distance_to(mouse_pos) >= AIM_DEADZONE:
		return player.global_position.direction_to(mouse_pos)
	var near := _find_nearest_enemy()
	if near:
		return player.global_position.direction_to(near.global_position)
	return Vector2.RIGHT

func _find_nearest_enemy() -> Node:
	var container: Node = _enemy_container()
	if container == null:
		return null
	var nearest: Node = null
	var nearest_dist: float = INF
	for enemy in container.get_children():
		if not is_instance_valid(enemy) or enemy.get("is_alive") != true:
			continue
		var dist := player.global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy
	return nearest

# ========== 刀光特效 ==========

## 刷新刀光扇形 Polygon2D：展开进度 = t/EXPAND 段，透明度 = 1 - t/DURATION
## 进化形态（evolution_result meta）金色、基础蓝白（对齐 orbit_weapon F-22 视觉）
func _update_fx() -> void:
	if _fx == null:
		return
	var t: float = maxf(_slash_t, 0.0)
	var expand: float = clampf(t / (SLASH_DURATION * EXPAND_RATIO), 0.05, 1.0)
	var alpha: float = 1.0 - t / SLASH_DURATION
	var radius: float = maxf(weapon.attack_range, 40.0) * (0.85 + 0.15 * expand)
	var show_angle: float = deg_to_rad(_slash_angle) * expand
	var evolved: bool = bool(weapon.get_meta("evolution_result", false))
	var color: Color = Color(1.0, 0.78, 0.2) if evolved else Color(0.65, 0.85, 1.0)
	color.a = alpha * 0.55
	var base_angle: float = _slash_dir.angle()
	var pts := PackedVector2Array()
	pts.append(Vector2.ZERO)
	for i in ARC_SEGMENTS + 1:
		var a: float = base_angle - show_angle * 0.5 + show_angle * float(i) / float(ARC_SEGMENTS)
		pts.append(Vector2.from_angle(a) * radius)
	_fx.polygon = pts
	_fx.color = color
	_fx.visible = true
