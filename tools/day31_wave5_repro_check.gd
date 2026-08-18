## Day31 复现探针：wave 5 全量生成完整性（用户 08-18 反馈「最后一个敌人死活不出现」）
## 目的：验证 spawn_wave(wave5) 后 60 只是否全部成功创建并入容器——
## 若某敌种 _create_enemy 返回 null（数据缺失/池空），队列会静默少一只且玩家不可见，
## HUD 分母（wave_total=60）不变 → 「差 1 只不出现、打不死、关卡卡住」的直接嫌疑
## 用法：tools/Godot_v4.3-stable_win64.exe --headless --path "D:/30DAYS" --script res://tools/day31_wave5_repro_check.gd
## 退出码 0 = 全部通过；非 0 = 失败项数。
extends SceneTree

var _sub: int = 0
var _ready_mocks: bool = false
var _spawner: Node = null
var _gm: Node = null
var _player: Node2D = null
var _container: Node = null
var _checked: int = 0
var _failures: int = 0

func _initialize() -> void:
	print("=== Day31 wave5 生成完整性复现 ===")

func _process(_delta: float) -> bool:
	if not _ready_mocks:
		_setup()
		return false
	if _sub > 1:
		_report()
		quit(_failures)
		return true
	_sub = _advance(_sub)
	return false

func _setup() -> void:
	_ready_mocks = true
	_gm = root.get_node_or_null("GameManager")
	# mock player（set_target 目标）
	_player = Node2D.new()
	_player.name = "MockPlayer"
	root.add_child(_player)
	_gm.set("player", _player)
	# mock 敌人容器
	_container = Node.new()
	_container.name = "MockEnemies"
	root.add_child(_container)
	# spawner 接线
	_spawner = load("res://scripts/enemy/enemy_spawner.gd").new()
	_spawner.name = "MockSpawner"
	root.add_child(_spawner)
	_spawner.call("set_container", _container)
	_spawner.set("enemy_scene", load("res://scenes/Enemy.tscn"))
	_gm.set("enemy_spawner", _spawner)
	_gm.set("enemies_container", _container)
	_gm.set("current_state", _gm.GameState.BATTLE)

func _ok(cond: bool, what: String) -> void:
	_checked += 1
	if not cond:
		_failures += 1
		print("  FAIL: " + what)
	else:
		print("  PASS: " + what)

func _report() -> void:
	print("=== Day31 wave5: %d checked, %d failures ===" % [_checked, _failures])

func _advance(sub: int) -> int:
	match sub:
		0:
			_part_wave5_full_spawn()
			return 1
		1:
			_part_spawn_position()
			_report()
			quit(_failures)
	return 2

## §1 wave 5 全量出队：60 只全部成功创建并入容器？
func _part_wave5_full_spawn() -> void:
	var loader: Node = root.get_node_or_null("DataLoader")
	var wave_config: Dictionary = loader.call("get_wave", 5) if loader else {}
	_ok(not wave_config.is_empty(), "§1: wave 5 配置存在")
	if wave_config.is_empty():
		return
	var comp_sum: int = 0
	for e in wave_config.get("composition", []):
		comp_sum += int(e.get("count", 0))
	var expect: int = comp_sum * (2 if wave_config.get("special") == "swarm_wave" else 1)
	_ok(expect == 60, "§1: wave5 swarm 翻倍后应生成 60 只（实算 %d）" % expect)
	_spawner.call("spawn_wave", wave_config, 5)
	var queue_size: int = _spawner.get("spawn_queue").size()
	_ok(queue_size == 60, "§1: spawn_queue 入队 60（实得 %d）" % queue_size)
	# 白盒全量出队（跳过 timer，等价逐帧 _process 驱动）
	for i in queue_size:
		_spawner.call("_spawn_next")
	# 统计实际入容器数
	var created: int = _container.get_child_count()
	_ok(created == 60, "§1: 60 只全部创建并入容器（实得 %d —— 若 <60 = 有敌种静默创建失败）" % created)
	_ok(_spawner.get("spawn_queue").is_empty(), "§1: 出队后队列为空")
	_ok(not _spawner.call("is_spawning"), "§1: 生成标志复位")
	# 容器内敌人全部 is_alive
	var all_alive: bool = true
	for c in _container.get_children():
		if c.get("is_alive") != true:
			all_alive = false
			print("  !! 非存活敌人: %s" % str(c.get("enemy_id")))
	_ok(all_alive, "§1: 全部敌人 is_alive（无生成即死）")
	# 清理
	for c in _container.get_children():
		c.queue_free()

## §2 生成位置视野内断言（F-48 · 用户「最后一个敌人不出现」根因回归）：
## 生成矩形 ±200×±120（对角 ≈233px）——任何生成点距玩家 ≤ 233.5，必在玩家视野
## （320 半宽×180 半高）内；配合 Aggro Leash 320，杜绝「视口外死角怪找不到」卡关
func _part_spawn_position() -> void:
	_player.global_position = Vector2(100.0, 100.0)  # 模拟玩家站竞技场角落
	var max_dist: float = 0.0
	var out_count: int = 0
	var spawner: Node = _spawner
	for i in 200:
		var pos: Vector2 = spawner.call("_get_random_spawn_position")
		var d: float = pos.distance_to(_player.global_position)
		if d > max_dist:
			max_dist = d
		if d > 233.5:
			out_count += 1
	_ok(out_count == 0, "§2: 200 次生成点全部在玩家 ±233px 内（超限 %d 次，最远 %.1f）" % [out_count, max_dist])
	_ok(max_dist <= 233.5, "§2: 最远生成点 %.1f ≤ 233.5（对角）——必在玩家视野内" % max_dist)
