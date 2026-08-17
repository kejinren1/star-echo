## PS · 莱恩普攻扇形挥砍出口校验（2026-08-17 用户拍板：替代环绕小三角）
##
## 用法（无头）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day31_melee_sweep_check.gd
##
## 校验内容：
##   §1 数据层：se_star_blade 主表无 orbit 键、arc_angle=100；levels L1/L8 100/135；
##      se_blade_storm arc_angle=150（DataLoader 已加载口径）
##   §2 装配层：build_weapon_from_data(se_star_blade) → orbit_data 空 + arc_angle=100；
##      equip_from_data 后 WeaponController.sweep_node 创建
##   §3 白盒判定：MeleeSweep 扇形内敌人受击 / 扇形外不受击 / 冷却内不重复挥砍
##   §4 伤害通道：套玩家 damage_multiplier（×2 验证）
##
## 退出码 0 = 全部通过；非 0 = 失败项数。
extends SceneTree

const EPS: float = 0.01
var _checked: int = 0
var _failures: int = 0
var _started: bool = false
var _player: Node = null
var _controller: Node = null
var _sweep: Node = null
var _container: Node = null

## 白盒敌人（take_damage 扣血，健康检查用）
class MockEnemy:
	extends Node2D
	var health: float = 100.0
	var max_health: float = 100.0
	var is_alive: bool = true
	var is_boss: bool = false
	var armor: float = 0.0
	var enemy_id: String = "probe"

	func take_damage(amount: float, _is_crit: bool = false) -> void:
		health -= maxf(amount - armor, 1.0)
		if health <= 0.0:
			is_alive = false

func _initialize() -> void:
	print("=== Day31 melee sweep check ===")

func _process(_delta: float) -> bool:
	if _started:
		return false
	_started = true
	_section_data()
	_section_build()
	_section_sweep_logic()
	_section_damage_channel()
	print("检查 %d 项，失败 %d 项" % [_checked, _failures])
	quit(_failures)
	return true

func _ok(msg: String) -> void:
	_checked += 1
	print("  PASS  %s" % msg)

func _fail(msg: String) -> void:
	_failures += 1
	print("  FAIL  %s" % msg)

# ========== §1 数据层 ==========

func _section_data() -> void:
	var loader: Node = root.get_node_or_null("DataLoader")
	if loader == null:
		_fail("DataLoader 不可用")
		return
	var star: Dictionary = loader.call("get_weapon", "se_star_blade")
	var storm: Dictionary = loader.call("get_weapon", "se_blade_storm")
	if star.is_empty() or storm.is_empty():
		_fail("weapons.json 缺少星刃/星刃风暴")
		return
	var orbit_keys := ["blade_count", "orbit_radius", "orbit_speed"]
	var star_has_orbit: bool = false
	for k in orbit_keys:
		if star.has(k) and star[k] != null:
			star_has_orbit = true
	if not star_has_orbit and float(star.get("arc_angle", 0.0)) == 100.0:
		_ok("§1 se_star_blade: 无 orbit 键 + arc_angle=100")
	else:
		var debug := {}
		for k in orbit_keys + ["arc_angle"]:
			debug[k] = star.get(k)
		_fail("§1 se_star_blade 数据异常: %s" % str(debug))
	var levels: Array = star.get("levels", [])
	if levels.size() == 8 and float(levels[0].get("arc_angle", 0.0)) == 100.0 \
			and float(levels[7].get("arc_angle", 0.0)) == 135.0:
		_ok("§1 levels L1/L8 arc_angle = 100/135")
	else:
		_fail("§1 levels arc_angle 异常: %s" % str(levels))
	if float(storm.get("arc_angle", 0.0)) == 150.0:
		_ok("§1 se_blade_storm arc_angle=150")
	else:
		_fail("§1 se_blade_storm arc_angle 应为 150: %s" % str(storm.get("arc_angle")))

# ========== §2 装配层 ==========

func _section_build() -> void:
	var pscene: PackedScene = load("res://scenes/Player.tscn")
	_player = pscene.instantiate()
	root.add_child(_player)
	_controller = _player.get_node_or_null("WeaponController")
	if _controller == null:
		_fail("Player 无 WeaponController")
		return
	if not _controller.call("equip_from_data", "se_star_blade"):
		_fail("equip_from_data(se_star_blade) 失败")
		return
	var w: Resource = _controller.get("equipped_weapons")[0]
	if w.orbit_data.is_empty() and absf(w.arc_angle - 100.0) < EPS:
		_ok("§2 构建武器: orbit_data 空 + arc_angle=100")
	else:
		_fail("§2 武器构建异常: orbit=%s arc=%s" % [str(w.orbit_data), str(w.arc_angle)])
		return
	_sweep = _controller.get("sweep_node")
	if _sweep != null and is_instance_valid(_sweep):
		_ok("§2 sweep_node 已创建并挂载")
	else:
		_fail("§2 sweep_node 未创建")

# ========== §3 扇形判定白盒 ==========

func _section_sweep_logic() -> void:
	if _sweep == null:
		return
	_container = Node2D.new()
	_container.name = "ProbeEnemies"
	root.add_child(_container)
	var gm: Node = root.get_node_or_null("GameManager")
	if gm:
		gm.enemies_container = _container
	# 敌人：正前方 60px（扇内）与 侧后方 80px（扇外）
	var e1 := MockEnemy.new()
	e1.enemy_id = "probe_in"
	_container.add_child(e1)
	e1.global_position = _player.global_position + Vector2(60, 0)
	var e2 := MockEnemy.new()
	e2.enemy_id = "probe_out"
	_container.add_child(e2)
	e2.global_position = _player.global_position + Vector2(-80, 0)
	# 强制挥砍：停掉自动调度（防 _process 与手动调用双重触发）+ 冷却清零 + 方向朝右
	_sweep.set_process(false)
	_sweep.set("_cooldown", 0.0)
	_sweep.set("_slash_dir", Vector2.RIGHT)
	_sweep.set("_slash_angle", 100.0)
	_sweep.call("_do_slash")
	if e1.health < 100.0 - EPS:
		_ok("§3 扇形内敌人受击（hp → %.0f）" % e1.health)
	else:
		_fail("§3 扇形内敌人未受击（hp=%.0f）" % e1.health)
	if e2.health > 100.0 - EPS:
		_ok("§3 扇形外敌人未受击")
	else:
		_fail("§3 扇形外敌人被误击（hp=%.0f）" % e2.health)
	# 冷却周期：挥砍后冷却 > 0 → 立即再挥砍不重复伤害
	var cd: float = _sweep.get("_cooldown")
	if cd > 0.0:
		var before: float = e1.health
		_sweep.call("_do_slash")
		if absf(e1.health - before) < EPS:
			_ok("§3 冷却内不重复挥砍（冷却 %.2fs）" % cd)
		else:
			_fail("§3 冷却内重复伤害（%.0f → %.0f）" % [before, e1.health])
	else:
		_fail("§3 挥砍后冷却未置位")

# ========== §4 伤害通道 ==========

func _section_damage_channel() -> void:
	if _sweep == null:
		return
	if not _player.has_method("apply_stat_modifier"):
		_fail("玩家无 apply_stat_modifier")
		return
	# 禁暴击：_do_slash 内 randf()<crit_chance 走全局 RNG，精确数值断言会 flaky（同 day5 先例）
	_player.set("crit_chance", 0.0)
	_player.set("crit_damage", 1.0)
	_player.call("apply_stat_modifier", "damage", 2.0, true)
	var e3 := MockEnemy.new()
	e3.enemy_id = "probe_dmg"
	e3.health = 1000.0
	e3.max_health = 1000.0
	_container.add_child(e3)
	e3.global_position = _player.global_position + Vector2(50, 0)
	var w: Resource = _controller.get("equipped_weapons")[0]
	var base_dmg: float = w.get_damage()
	_sweep.set("_cooldown", 0.0)
	_sweep.set("_slash_dir", Vector2.RIGHT)
	_sweep.set("_slash_angle", 100.0)
	_sweep.call("_do_slash")
	var dmg: float = 1000.0 - e3.health
	if absf(dmg - base_dmg * 2.0) < EPS:
		_ok("§4 伤害套玩家倍率（base %.0f × 2.0 = %.0f）" % [base_dmg, dmg])
	else:
		_fail("§4 倍率异常: 期望 %.1f 实得 %.1f" % [base_dmg * 2.0, dmg])
