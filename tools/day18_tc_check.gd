## Day 18 反馈专员 T-C 出口校验：炮台生命周期视觉提示（turret.gd 底部进度条）
##
## 用法（无头）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day18_tc_check.gd
##
## 校验内容（对应 docs/PLAYTEST_CHECKLIST.md 未解决问题追踪区 T-C）：
##   §1 临时炮台 setup：permanent=false + duration_max==duration_left==15 + 进度条节点存在
##   §2 进度条初始全宽（前景 polygon 右端 x==10）
##   §3 _process 递减后前景按比例收缩（右端 x 向 -10 移动且未缩到 0）
##   §4 最后 3 秒 warn：前景变红（r 显著）+ 6Hz 闪烁 alpha 交替
##   §5 常驻模式（permanent）：无进度条节点 + 时长不递减 + 不消亡
##   §6 回归：临时炮台仍可开火（射程内敌人 → Projectiles 容器产生弹丸）
##
## 退出码 0 = 全部通过；非 0 = 失败项数。
extends SceneTree

const ENEMY_SCENE_PATH: String = "res://scenes/Enemy.tscn"

var _sub: int = 0
var _ready_mocks: bool = false
var _gm: Node = null
var _world: Node2D = null
var _proj_container: Node2D = null
var _enemy_container: Node = null
var _turret_script: GDScript = null
var _turret: Node2D = null
var _checked: int = 0
var _failures: int = 0

func _initialize() -> void:
	print("=== Day 18 feedback T-C check (炮台生命周期视觉提示) ===")

func _process(_delta: float) -> bool:
	if not _ready_mocks:
		_load_mocks()
		return false
	if _sub > 6:
		_report()
		quit(_failures)
		return true
	_sub = _advance(_sub)
	return false

func _load_mocks() -> void:
	_ready_mocks = true
	_gm = root.get_node_or_null("GameManager")
	if _gm == null:
		_fail("GameManager autoload 缺失")
		_report()
		quit(1)
		return
	# mock 世界：Node2D World + Projectiles 容器 + 敌人容器
	_world = Node2D.new()
	_world.name = "MockWorld"
	root.add_child(_world)
	_proj_container = Node2D.new()
	_proj_container.name = "Projectiles"
	_world.add_child(_proj_container)
	_enemy_container = Node.new()
	_enemy_container.name = "MockEnemies"
	_world.add_child(_enemy_container)
	# mock player（炮台 _fire 读 damage_multiplier）
	var player := CharacterBody2D.new()
	player.name = "MockPlayer"
	player.set_script(load("res://scripts/player/player.gd"))
	player.damage_multiplier = 1.0
	_world.add_child(player)
	player.global_position = Vector2(100, 100)
	_gm.set("player", player)
	# mock spawner（_find_target 走 GameManager.enemy_spawner.enemies_container；
	# 纯 Node 无法 set 动态属性 → 用 enemy_spawner.gd 脚本实例）
	var spawner_mock = load("res://scripts/enemy/enemy_spawner.gd").new()
	spawner_mock.name = "MockSpawner"
	spawner_mock.set("enemies_container", _enemy_container)
	_gm.set("enemy_spawner", spawner_mock)
	_turret_script = load("res://scripts/weapons/turret.gd")

func _advance(sub: int) -> int:
	match sub:
		0: _s1_temp_setup()
		1: _s2_full_width()
		2: _s3_shrink()
		3: _s4_warn_blink()
		4: _s5_permanent()
		5: _s6_fire_regression()
	return sub + 1

# ---------- §1 临时炮台 setup ----------
func _s1_temp_setup() -> void:
	var wd := {"damage": 5.0, "cooldown": 0.5, "range": 220.0}
	_turret = _turret_script.new()
	_world.add_child(_turret)
	_turret.set_process(false)  # 禁自动处理：探针手动 _process 精确控时（须进树后再禁）
	_turret.setup(wd, 15.0, _gm.player)
	_ok(_turret.permanent == false, "T-C/§1: 临时炮台 permanent=false")
	_ok(absf(_turret.duration_max - 15.0) < 0.001 and absf(_turret.duration_left - 15.0) < 0.001,
		"T-C/§1: duration_max==duration_left==15（%.1f/%.1f）" % [_turret.duration_max, _turret.duration_left])
	_ok(_turret._life_bg != null, "T-C/§1: 进度条背景节点存在")
	_ok(_turret._life_fg != null, "T-C/§1: 进度条前景节点存在")

# ---------- §2 初始全宽 ----------
func _s2_full_width() -> void:
	var poly: PackedVector2Array = _turret._life_fg.polygon
	_ok(absf(poly[1].x - 10.0) < 0.001, "T-C/§2: 进度条初始全宽（右端 x==10，实得 %.2f）" % poly[1].x)

# ---------- §3 递减收缩 ----------
func _s3_shrink() -> void:
	_turret._process(5.0)  # 15 → 10
	_ok(absf(_turret.duration_left - 10.0) < 0.001,
		"T-C/§3: 剩余 10s（%.1f）" % _turret.duration_left)
	var poly: PackedVector2Array = _turret._life_fg.polygon
	var right_x: float = poly[1].x  # = -10 + 20 * (10/15) ≈ 3.333
	_ok(absf(right_x - (-10.0 + 20.0 * 10.0 / 15.0)) < 0.01,
		"T-C/§3: 前景按比例收缩（右端 x≈3.33，实得 %.2f）" % right_x)
	_ok(right_x > -10.0, "T-C/§3: 前景未缩到 0")

# ---------- §4 最后 3 秒 warn 红闪 ----------
func _s4_warn_blink() -> void:
	_turret._process(7.0)  # 10 → 3，进入 warn 区间（<= 3）
	_ok(_turret.duration_left <= 3.0, "T-C/§4: 剩余 %.2fs 进入 warn 区间" % _turret.duration_left)
	var c1: Color = _turret._life_fg.color
	_ok(c1.r > 0.7 and c1.g < 0.5, "T-C/§4: warn 变红（r=%.2f g=%.2f）" % [c1.r, c1.g])
	_turret._process(1.0 / 6.0)  # 6Hz 闪烁翻转到暗态
	var c2: Color = _turret._life_fg.color
	_ok(absf(c2.a - c1.a) > 0.3, "T-C/§4: 闪烁 alpha 交替（%.2f → %.2f）" % [c1.a, c2.a])

# ---------- §5 常驻模式零提示不消亡 ----------
func _s5_permanent() -> void:
	var wd := {"damage": 5.0, "cooldown": 0.5, "range": 220.0}
	var perm = _turret_script.new()
	_world.add_child(perm)
	perm.set_process(false)
	perm.setup(wd, -1.0, _gm.player)
	_ok(perm.permanent == true, "T-C/§5: 常驻 permanent=true")
	_ok(perm._life_bg == null and perm._life_fg == null, "T-C/§5: 常驻无进度条节点")
	perm._process(60.0)
	_ok(absf(perm.duration_left - 15.0) < 0.001, "T-C/§5: 常驻时长不递减（%.1f）" % perm.duration_left)
	_ok(perm.is_inside_tree(), "T-C/§5: 常驻不消亡")
	perm.queue_free()

# ---------- §6 回归：仍可开火 ----------
func _s6_fire_regression() -> void:
	var enemy = load(ENEMY_SCENE_PATH).instantiate()
	_enemy_container.add_child(enemy)
	enemy.global_position = _turret.global_position + Vector2(60, 0)
	var kids_before: int = _proj_container.get_child_count()
	_turret._process(0.01)  # 冷却已深负 → 立即开火
	_ok(_proj_container.get_child_count() > kids_before,
		"T-C/§6: 临时炮台仍可开火（弹丸 %d→%d）" % [kids_before, _proj_container.get_child_count()])

# ========== 断言工具 ==========

func _ok(cond: bool, what: String) -> void:
	_checked += 1
	if cond:
		print("  [PASS] ", what)
	else:
		_failures += 1
		print("  [FAIL] ", what)

func _fail(what: String) -> void:
	_checked += 1
	_failures += 1
	print("  [FAIL] ", what)

func _report() -> void:
	print("=== DAY18-TC CHECK: %d assertions, %d failures ===" % [_checked, _failures])
