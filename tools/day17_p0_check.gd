## Day 17-P0 出口校验：用户拍板四项（F-01/F-02/F-04 机器实现 + F-15 根因复核）
##
## 用法（无头）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day17_p0_check.gd
##
## 校验内容（对应 docs/TASKS.md Day 17-P0 区）：
##   §1 F-01 怪物移速 50%：get_scaled_enemy move_speed = 原始 ×0.5（chaser wave1
##      320×1.01×0.5=161.6；elite/boss 同乘）
##   §2 F-02 碰撞穿过：Enemy layer=2/mask=2（敌间互碰）；Player layer=1/mask=1
##      （不检测敌人层 → 穿过）；Projectile Area2D mask=2（检测敌人层，武器伤害不破坏）
##   §3 F-04 金手指：toggle → debug_cheat true + player.debug_mult 10 + 跳关；
##      再 toggle → 全还原；攻击聚合消费（weapon_controller proj.damage ×debug_mult）；
##      受伤 0.1%（player.take_damage ×0.001）；技能聚合消费（skill_controller）
##   §4 回归锚点：F-02 后敌人接触伤害仍生效（距离判断与物理无关，穿过≠无敌）；
##      F-01 后精英 scaling 乘数不受影响（elite 仍 ×(1+wave×0.15)）
##
## 退出码 0 = 全部通过；非 0 = 失败项数。
extends SceneTree

const PLAYER_SCENE_PATH: String = "res://scenes/Player.tscn"
const ENEMY_SCENE_PATH: String = "res://scenes/Enemy.tscn"
const PROJECTILE_SCENE_PATH: String = "res://scenes/Projectile.tscn"

var _sub: int = 0
var _ready_mocks: bool = false
var _loader: Node = null
var _gm: Node = null
var _player: Node = null
var _wc: Node = null
var _checked: int = 0
var _failures: int = 0

func _initialize() -> void:
	print("=== Day 17 P0 check (F-01/F-02/F-04) ===")

func _process(_delta: float) -> bool:
	if not _ready_mocks:
		_load_mocks()
		return false
	if _sub > 20:
		_report()
		quit(_failures)
		return true
	_sub = _advance(_sub)
	return false

func _load_mocks() -> void:
	_ready_mocks = true
	_loader = root.get_node_or_null("DataLoader")
	_gm = root.get_node_or_null("GameManager")
	if _loader == null or _gm == null:
		_fail("DataLoader/GameManager autoload 缺失")
		_report()
		quit(1)
		return
	# mock player（player.gd 脚本）——挂在 Node2D MockWorld 下（_find_container 需
	# player.get_parent() 为 Node2D，否则返回 Window 类型错误；位置 (100,100) 保证
	# _get_aim_direction 非零 → 火球真实生成）
	var world := Node2D.new()
	world.name = "MockWorld"
	root.add_child(world)
	var proj_container := Node2D.new()
	proj_container.name = "Projectiles"
	world.add_child(proj_container)
	_player = CharacterBody2D.new()
	_player.name = "MockPlayer"
	_player.set_script(load("res://scripts/player/player.gd"))
	_player.max_health = 100.0
	_player.armor = 0.0
	_player.dodge = 0.0
	_player.damage_multiplier = 1.0
	_player.debug_mult = 1.0
	world.add_child(_player)
	_player.global_position = Vector2(100, 100)
	_player.max_health = 100.0
	_player.health = 100.0
	_player._invulnerable_timer = 0.0
	_gm.set("player", _player)
	# mock weapon_controller
	var wc_script: GDScript = load("res://scripts/weapons/weapon_controller.gd")
	_wc = wc_script.new()
	_wc.name = "WeaponController"
	_player.add_child(_wc)
	# 弹丸容器（_spawn_projectile 白盒需要）
	_wc.set("_projectile_container", proj_container)
	# 清空初始武器（_ready 装备的初始枪）
	var empty: Array[Resource] = []
	_wc.set("equipped_weapons", empty)

# ========== 断言工具 ==========

func _ok(cond: bool, what: String) -> void:
	_checked += 1
	if not cond:
		_failures += 1
		print("  FAIL: " + what)

func _fail(what: String) -> void:
	_checked += 1
	_failures += 1
	print("  FAIL: " + what)

func _report() -> void:
	print("=== DAY17-P0 CHECK: %d assertions, %d failures ===" % [_checked, _failures])
	if _failures == 0:
		print("DAY17-P0 CHECK CLEAN")

func _reset_player() -> void:
	_player.max_health = 100.0
	_player.health = 100.0
	_player._invulnerable_timer = 0.0
	_player.dodge = 0.0
	_player.armor = 0.0

# ========== 主推进 ==========

func _advance(sub: int) -> int:
	match sub:
		# ---------- §1 F-01 移速 50% ----------
		0:
			# chaser wave1: 320 × (1+0.01) × 0.5 = 161.6
			var c1: Dictionary = _loader.call("get_scaled_enemy", "chaser", 1)
			var exp_c1: float = 320.0 * 1.01 * 0.5
			_ok(absf(float(c1.get("move_speed", -1.0)) - exp_c1) < 0.01,
				"F-01/移速: chaser wave1 = 161.6（实得 %.2f）" % float(c1.get("move_speed", -1.0)))
			# charger wave3: 400 × (1+0.03) × 0.5 = 206
			var c3: Dictionary = _loader.call("get_scaled_enemy", "charger", 3)
			var exp_c3: float = 400.0 * 1.03 * 0.5
			_ok(absf(float(c3.get("move_speed", -1.0)) - exp_c3) < 0.01,
				"F-01/移速: charger wave3 = 206（实得 %.2f）" % float(c3.get("move_speed", -1.0)))
			# elite butcher wave6: 200 × 1.06 × 0.5 = 106
			var e6: Dictionary = _loader.call("get_scaled_enemy", "butcher", 6)
			var exp_e6: float = 200.0 * 1.06 * 0.5
			_ok(absf(float(e6.get("move_speed", -1.0)) - exp_e6) < 0.01,
				"F-01/移速: elite butcher wave6 = 106（实得 %.2f）" % float(e6.get("move_speed", -1.0)))
			# boss invoker wave10: 200 × (1+0.1) × 0.5 = 110
			var b10: Dictionary = _loader.call("get_scaled_enemy", "invoker", 10)
			var exp_b10: float = 200.0 * 1.1 * 0.5
			_ok(absf(float(b10.get("move_speed", -1.0)) - exp_b10) < 0.01,
				"F-01/移速: boss invoker wave10 = 110（实得 %.2f）" % float(b10.get("move_speed", -1.0)))
			return 1
		# ---------- §2 F-02 碰撞穿过 ----------
		1:
			var player_scene: PackedScene = load(PLAYER_SCENE_PATH)
			var enemy_scene: PackedScene = load(ENEMY_SCENE_PATH)
			var proj_scene: PackedScene = load(PROJECTILE_SCENE_PATH)
			var p: Node = player_scene.instantiate()
			var e: Node = enemy_scene.instantiate()
			_ok(int(p.get("collision_layer")) == 1 and int(p.get("collision_mask")) == 1,
				"F-02/玩家: layer=1 mask=1（不检测敌人层 2）")
			_ok(int(e.get("collision_layer")) == 2 and int(e.get("collision_mask")) == 2,
				"F-02/敌人: layer=2 mask=2（敌间互碰，不挡玩家）")
			# 玩家 mask 不含敌人层：1 & 2 == 0
			_ok((int(p.get("collision_mask")) & int(e.get("collision_layer"))) == 0,
				"F-02/穿过: 玩家 mask & 敌人 layer == 0（物理不阻挡）")
			var proj: Node = proj_scene.instantiate()
			root.add_child(proj)
			_ok(int(proj.get("collision_mask")) == 2,
				"F-02/弹丸: Area2D mask=2（检测敌人层，武器伤害不破坏）")
			proj.queue_free()
			p.queue_free()
			e.queue_free()
			return 2
		# ---------- §3 F-04 金手指 ----------
		2:
			# 初始状态：debug_cheat false + debug_mult 1
			_ok(_gm.get("debug_cheat") == false and absf(_player.debug_mult - 1.0) < 0.001,
				"F-04/初始: debug_cheat=false + debug_mult=1（零残留）")
			# toggle ON：debug_cheat true + debug_mult 10 + 跳关（current_wave 3→4）
			_gm.set("current_wave", 3)
			_gm.call("toggle_debug_cheat")
			_ok(_gm.get("debug_cheat") == true, "F-04/toggle: ON → debug_cheat=true")
			_ok(absf(_player.debug_mult - 10.0) < 0.001, "F-04/toggle: ON → debug_mult=10")
			_ok(int(_gm.get("current_wave")) == 4, "F-04/toggle: ON → 跳关（wave 3→4，实得 %d）" % int(_gm.get("current_wave")))
			# 再 toggle OFF：全还原
			_gm.call("toggle_debug_cheat")
			_ok(_gm.get("debug_cheat") == false, "F-04/toggle: OFF → debug_cheat=false")
			_ok(absf(_player.debug_mult - 1.0) < 0.001, "F-04/toggle: OFF → debug_mult=1（全还原）")
			return 3
		3:
			# 攻击聚合消费：debug_mult=10 → _spawn_projectile 弹丸 damage ×10（sword base 12）
			var w: Resource = _wc.call("build_weapon_from_data", "sword")  # base 12
			_player.damage_multiplier = 1.0
			_player.debug_mult = 10.0
			_wc.call("_spawn_projectile", w, Vector2.RIGHT)
			var container: Node = _wc.get("_projectile_container")
			if container and container.get_child_count() > 0:
				var proj: Node = container.get_child(container.get_child_count() - 1)
				_ok(absf(float(proj.get("damage")) - 120.0) < 0.001,
					"F-04/攻击聚合: sword base12 × debug_mult10 = 120（实得 %.1f）" % float(proj.get("damage")))
				proj.queue_free()
			else:
				_fail("F-04/攻击聚合: _spawn_projectile 未生成弹丸")
			_player.debug_mult = 1.0
			# 技能聚合消费：skill_controller 火球 damage 也乘 debug_mult（对齐口径）
			var sc_script: GDScript = load("res://scripts/player/skill_controller.gd")
			var sc = sc_script.new()
			_player.add_child(sc)
			sc.setup({"skill": {"id": "se_skill_fireball", "damage": 30.0, "radius": 90.0, "element_type": "fire", "burn_duration": 4.0}})
			_player.debug_mult = 10.0
			sc.call("_cast_fireball")
			# 火球容器 = MockWorld/Projectiles（_find_container 返回）
			var fire_container: Node = _player.get_parent().get_node_or_null("Projectiles")
			if fire_container and fire_container.get_child_count() > 0:
				var proj2: Node = fire_container.get_child(fire_container.get_child_count() - 1)
				_ok(absf(float(proj2.get("damage")) - 300.0) < 0.001,
					"F-04/技能聚合: 火球 30 × debug_mult10 = 300（实得 %.1f）" % float(proj2.get("damage")))
				proj2.queue_free()
			else:
				_fail("F-04/技能聚合: 火球未生成")
			_player.debug_mult = 1.0
			return 4
		4:
			# 受伤 0.1%%：debug_cheat=true → take_damage(10) → actual 10×0.001=0.01
			_reset_player()
			_gm.set("debug_cheat", true)
			_player.call("take_damage", 10.0)
			_ok(absf(_player.health - 99.99) < 0.01,
				"F-04/受伤0.1%%: take_damage(10) → health 99.99（实得 %.2f）" % _player.health)
			# 关闭后恢复正常
			_gm.set("debug_cheat", false)
			_reset_player()
			_player.call("take_damage", 10.0)
			_ok(absf(_player.health - 90.0) < 0.01,
				"F-04/关闭还原: take_damage(10) → health 90（实得 %.1f）" % _player.health)
			return 5
		# ---------- §4 回归锚点 ----------
		5:
			# F-02 后敌人接触伤害仍生效（距离判断与物理无关，穿过≠无敌）
			_reset_player()
			_gm.set("debug_cheat", false)
			var e: Node = (load(ENEMY_SCENE_PATH) as PackedScene).instantiate()
			e.call("initialize", {"id": "chaser", "category": "regular", "max_health": 30.0,
				"damage": 5.0, "move_speed": 120.0, "behavior": "chase", "armor": 0})
			e.call("set_target", _player)
			root.add_child(e)
			e.global_position = Vector2(5, 0)  # 距离 5 < contact_range（frame 24×0.5+12=24）
			_player.global_position = Vector2.ZERO
			e.call("_try_contact_damage")
			_ok(absf(_player.health - 95.0) < 0.01,
				"回归/F-02: 敌人接触伤害仍生效（穿过≠无敌，health 100→95）")
			e.queue_free()
			# F-01 后 elite scaling 乘数不受影响（hp 仍 ×(1+wave×0.15)）
			var butcher_w6: Dictionary = _loader.call("get_scaled_enemy", "butcher", 6)
			var exp_hp: float = (200.0 + 100.0 * 6) * (1.0 + 6 * 0.15)
			_ok(absf(float(butcher_w6.get("max_health")) - exp_hp) < 0.01,
				"回归/F-01: elite butcher wave6 hp=1040（scaling 不受移速改动影响）")
			return 6
		_:
			return 21  # 结束哨兵
