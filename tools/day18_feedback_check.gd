## Day 18 反馈专员出口校验：用户拍板五项（F-03/F-05/F-06/F-07/F-11）+ F-08 星刃判定
##
## 用法（无头）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day18_feedback_check.gd
##
## 校验内容（对应 docs/PLAYTEST_CHECKLIST.md 未解决问题追踪区）：
##   §1 F-05 通关回血 50%：_apply_wave_heal 白盒（30/100 → 80）；on_wave_cleared 全链路回血
##   §2 F-07 火球穿透：_cast_fireball 生成弹丸 pierce==3；穿透中段 _do_explosion 可重复爆炸；
##      最后一次 _explode 防重复（与 lifetime 到点不双爆）
##   §3 F-08 星刃贴身必中：敌人贴身（20px，远离刀刃轨道 110px）→ 任一刃 _process 命中；
##      回归锚点：非贴身非轨道敌人不命中
##   §4 F-06 剩余怪 Label：_refresh_enemy_count 读 enemies_container 存活数 → "剩余 N"
##   §5 F-11 伤害数字：take_damage(10, true) → vfx 容器 Label「10!」+ health 下降；
##      普通伤害 → 普通数字「10」
##   §6 F-03 受伤反馈：Main.tscn 含 MainCamera；took_damage → main._on_player_hit → 震动计时置位
##
## 退出码 0 = 全部通过；非 0 = 失败项数。
extends SceneTree

const ENEMY_SCENE_PATH: String = "res://scenes/Enemy.tscn"
const PROJECTILE_SCENE_PATH: String = "res://scenes/Projectile.tscn"
const HUD_SCENE_PATH: String = "res://scenes/HUD.tscn"
const MAIN_SCENE_PATH: String = "res://scenes/Main.tscn"

var _sub: int = 0
var _ready_mocks: bool = false
var _loader: Node = null
var _gm: Node = null
var _player: Node = null
var _world: Node2D = null
var _proj_container: Node2D = null
var _enemy_container: Node = null
var _vfx_container: Node = null
var _checked: int = 0
var _failures: int = 0

func _initialize() -> void:
	print("=== Day 18 feedback check (F-03/F-05/F-06/F-07/F-08/F-11) ===")

func _process(_delta: float) -> bool:
	if not _ready_mocks:
		_load_mocks()
		return false
	if _sub > 24:
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
	# mock 世界（仿 day17_p0）：Node2D World + Projectiles 容器
	_world = Node2D.new()
	_world.name = "MockWorld"
	root.add_child(_world)
	_proj_container = Node2D.new()
	_proj_container.name = "Projectiles"
	_world.add_child(_proj_container)
	# mock 敌人容器
	_enemy_container = Node.new()
	_enemy_container.name = "MockEnemies"
	_world.add_child(_enemy_container)
	# mock vfx 容器
	_vfx_container = Node.new()
	_vfx_container.name = "MockVfx"
	_world.add_child(_vfx_container)
	# mock spawner（_do_explosion/orbit_weapon 走 GameManager.enemy_spawner.enemies_container；
	# 纯 Node 无法 set 动态属性 → 用 enemy_spawner.gd 脚本实例，属性类型一致）
	var spawner_mock = load("res://scripts/enemy/enemy_spawner.gd").new()
	spawner_mock.name = "MockSpawner"
	spawner_mock.set("enemies_container", _enemy_container)
	_gm.set("enemy_spawner", spawner_mock)
	# mock player
	_player = CharacterBody2D.new()
	_player.name = "MockPlayer"
	_player.set_script(load("res://scripts/player/player.gd"))
	_player.max_health = 100.0
	_player.armor = 0.0
	_player.dodge = 0.0
	_player.damage_multiplier = 1.0
	_player.debug_mult = 1.0
	_world.add_child(_player)
	_player.global_position = Vector2(100, 100)
	_player.max_health = 100.0
	_player.health = 100.0
	_player._invulnerable_timer = 0.0
	_gm.set("player", _player)
	_gm.set("enemies_container", _enemy_container)
	_gm.set("vfx_container", _vfx_container)

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
	print("=== DAY18-FEEDBACK CHECK: %d assertions, %d failures ===" % [_checked, _failures])
	if _failures == 0:
		print("DAY18-FEEDBACK CHECK CLEAN")

func _reset_player() -> void:
	_player.max_health = 100.0
	_player.health = 100.0
	_player._invulnerable_timer = 0.0
	_player.dodge = 0.0
	_player.armor = 0.0

## 生成一只 mock 敌人（默认 chaser 30hp）
func _spawn_enemy(pos: Vector2, hp: float = 30.0) -> Node:
	var e: Node = (load(ENEMY_SCENE_PATH) as PackedScene).instantiate()
	e.call("initialize", {"id": "chaser", "category": "regular", "max_health": hp,
		"damage": 5.0, "move_speed": 120.0, "behavior": "chase", "armor": 0})
	_enemy_container.add_child(e)
	e.global_position = pos
	return e

# ========== 主推进 ==========

func _advance(sub: int) -> int:
	match sub:
		# ---------- §1 F-05 通关回血 50% ----------
		0:
			# 白盒：_apply_wave_heal（30/100 → +50 = 80）
			_reset_player()
			_player.health = 30.0
			_gm.call("_apply_wave_heal")
			_ok(absf(_player.health - 80.0) < 0.01,
				"F-05/白盒: 30/100 → heal(50) → 80（实得 %.1f）" % _player.health)
			# 满血时不溢出上限
			_player.health = 100.0
			_gm.call("_apply_wave_heal")
			_ok(absf(_player.health - 100.0) < 0.01,
				"F-05/上限: 满血回血不溢出（100）")
			return 1
		1:
			# 全链路：on_wave_cleared → 清残敌 → 回血 → 发信号（route 空 = 旧制）
			_reset_player()
			_player.health = 40.0
			_gm.set("route", {})
			_gm.set("current_wave", 1)
			_gm.call("on_wave_cleared")
			_ok(absf(_player.health - 90.0) < 0.01,
				"F-05/链路: on_wave_cleared 后 40 → 90（清残敌后回血 50%%）")
			return 2
		# ---------- §2 F-07 火球穿透 ----------
		2:
			# _cast_fireball 生成弹丸 pierce == 3
			var sc_script: GDScript = load("res://scripts/player/skill_controller.gd")
			var sc = sc_script.new()
			_player.add_child(sc)
			sc.setup({"skill": {"id": "se_skill_fireball", "damage": 30.0, "radius": 90.0, "element_type": "fire", "burn_duration": 4.0}})
			sc.call("_cast_fireball")
			if _proj_container.get_child_count() > 0:
				var proj: Node = _proj_container.get_child(_proj_container.get_child_count() - 1)
				_ok(int(proj.get("pierce")) == 3,
					"F-07/pierce: 火球 pierce == 3（实得 %d）" % int(proj.get("pierce")))
				proj.queue_free()
			else:
				_fail("F-07/pierce: 火球未生成")
			return 3
		3:
			# 穿透中段 _do_explosion 可重复（无防重复标记）：摆 2 敌在爆炸半径内，
			# 连续裸爆两次 → 两敌各掉 2 次爆炸伤害
			var p: Node = (load(PROJECTILE_SCENE_PATH) as PackedScene).instantiate()
			_world.add_child(p)
			p.global_position = Vector2(0, 0)
			p.set("damage", 10.0)
			p.set("explosion_radius", 80.0)
			p.set("explosion_damage", 10.0)
			var e1: Node = _spawn_enemy(Vector2(30, 0), 100.0)
			var e2: Node = _spawn_enemy(Vector2(-30, 0), 100.0)
			p.call("_do_explosion")
			p.call("_do_explosion")
			_ok(absf(float(e1.get("health")) - 80.0) < 0.01 and absf(float(e2.get("health")) - 80.0) < 0.01,
				"F-07/沿途爆炸: 双裸爆 ×2 敌 = 各掉 20（实得 %.1f/%.1f）" % [float(e1.get("health")), float(e2.get("health"))])
			# _explode 包装防重复：再调两次 _explode → 只结算一次（_exploded 标记）
			e1.set("health", 100.0)
			p.call("_explode")
			p.call("_explode")
			_ok(absf(float(e1.get("health")) - 90.0) < 0.01,
				"F-07/防重复: _explode ×2 只爆一次（100 → 90，实得 %.1f）" % float(e1.get("health")))
			p.queue_free()
			e1.queue_free()
			e2.queue_free()
			return 4
		# ---------- §3 F-08 星刃贴身必中 ----------
		4:
			# 摆敌人贴身（20px，远于刀刃轨道 110px）→ 任一刃命中
			var wc_script: GDScript = load("res://scripts/weapons/weapon_controller.gd")
			var wc = wc_script.new()
			wc.name = "WeaponController"
			_player.add_child(wc)
			var blade_w: Resource = wc.call("build_weapon_from_data", "se_star_blade")  # 星刃 Lv1
			# 手动建 OrbitWeapon（仿 day5 探针）
			var orbit_script: GDScript = load("res://scripts/weapons/orbit_weapon.gd")
			var orbit = orbit_script.new()
			_player.add_child(orbit)
			orbit.call("setup", blade_w, _player)
			var e_near: Node = _spawn_enemy(_player.global_position + Vector2(20, 0), 100.0)
			var hp_before: float = float(e_near.get("health"))
			orbit.call("_process", 0.016)
			var hp_after: float = float(e_near.get("health"))
			_ok(hp_after < hp_before - 0.01,
				"F-08/贴身: 贴身敌（20px）被命中（%.1f → %.1f）" % [hp_before, hp_after])
			# 回归锚点：远敌（300px，非轨道非贴身）不命中
			var e_far: Node = _spawn_enemy(_player.global_position + Vector2(300, 0), 100.0)
			var far_before: float = float(e_far.get("health"))
			orbit.call("_process", 0.016)
			var far_after: float = float(e_far.get("health"))
			_ok(absf(far_after - far_before) < 0.01,
				"F-08/远敌: 300px 远敌不被命中（不误伤）")
			e_near.queue_free()
			e_far.queue_free()
			orbit.queue_free()
			return 5
		# ---------- §4 F-06 剩余怪 Label ----------
		5:
			var hud_scene: PackedScene = load(HUD_SCENE_PATH)
			var hud: Node = hud_scene.instantiate()
			root.add_child(hud)
			# 清空敌人容器，摆 2 存活
			for c in _enemy_container.get_children():
				c.queue_free()
			var alive1: Node = _spawn_enemy(Vector2(10, 0))
			var alive2: Node = _spawn_enemy(Vector2(20, 0))
			hud.call("_refresh_enemy_count")
			var label: Label = hud.get_node("MarginContainer/VBoxContainer/TopBar/CenterSection/EnemyCountLabel")
			_ok(label.text == "剩余 2",
				"F-06/计数: 2 存活 → 「剩余 2」（实得 %s）" % label.text)
			# 击杀一个后 → 剩余 1
			alive1.call("die")
			hud.call("_refresh_enemy_count")
			_ok(label.text == "剩余 1",
				"F-06/递减: 击杀后 → 「剩余 1」（实得 %s）" % label.text)
			# 清理
			for c in _enemy_container.get_children():
				c.queue_free()
			hud.queue_free()
			return 6
		# ---------- §5 F-11 伤害数字 ----------
		6:
			# 暴击：take_damage(10, true) → vfx 容器出现「10!」Label + health 下降
			var e_c: Node = _spawn_enemy(Vector2(0, 0), 100.0)
			_vfx_container.queue_free()  # 先清旧容器引用重建（防 label 残留干扰计数）
			_vfx_container = Node.new()
			_vfx_container.name = "MockVfx"
			_world.add_child(_vfx_container)
			_gm.set("vfx_container", _vfx_container)
			var kids_before: int = _vfx_container.get_child_count()
			e_c.call("take_damage", 10.0, true)
			var kids_after: int = _vfx_container.get_child_count()
			var crit_label: String = ""
			if kids_after > kids_before:
				crit_label = (_vfx_container.get_child(kids_after - 1) as Label).text
			_ok(kids_after > kids_before and crit_label == "10!",
				"F-11/暴击: 数字 Label「10!」（实得 %s，容器 %d→%d）" % [crit_label, kids_before, kids_after])
			_ok(absf(float(e_c.get("health")) - 90.0) < 0.01,
				"F-11/伤害: 10 点真实结算（health 100→90）")
			# 普通：take_damage(5) → 「5」
			var kids_b2: int = _vfx_container.get_child_count()
			e_c.call("take_damage", 5.0, false)
			var kids_a2: int = _vfx_container.get_child_count()
			var normal_label: String = ""
			if kids_a2 > kids_b2:
				normal_label = (_vfx_container.get_child(kids_a2 - 1) as Label).text
			_ok(kids_a2 > kids_b2 and normal_label == "5",
				"F-11/普通: 数字 Label「5」（实得 %s）" % normal_label)
			e_c.queue_free()
			return 7
		# ---------- §6 F-03 受伤反馈 ----------
		7:
			# Main.tscn 含固定相机（World/MainCamera）
			var main_scene: PackedScene = load(MAIN_SCENE_PATH)
			var main_tree: Node = main_scene.instantiate()
			var cam: Node = main_tree.get_node_or_null("World/MainCamera")
			_ok(cam != null and cam is Camera2D,
				"F-03/相机: Main.tscn 含 World/MainCamera（Camera2D）")
			_ok(absf(cam.get("position").x - 320.0) < 0.01 and absf(cam.get("position").y - 180.0) < 0.01,
				"F-03/相机: 固定视口中心 (320,180)（不跟随零渲染行为变更）")
			main_tree.queue_free()
			return 8
		8:
			# took_damage → main._on_player_hit → 震动计时置位（白盒直调，无需真实 Main 场景）
			var main_script: GDScript = load("res://scripts/autoload/main.gd")
			var m = main_script.new()
			_player.took_damage.connect(m._on_player_hit)
			_reset_player()
			_player.call("take_damage", 5.0)
			_ok(float(m.get("_shake_time")) > 0.0,
				"F-03/震动: 受伤 → 相机震动计时置位（%.2f）" % float(m.get("_shake_time")))
			m.free()
			return 9
		_:
			return 25  # 结束哨兵
