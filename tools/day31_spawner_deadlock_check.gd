## Day31 死锁复现探针：enemy_spawner._spawn_next pop 最后一只后 _is_spawning 不复位
## 背景（2026-08-15 真人反馈）：第 10 关 Boss 后第 11 层战斗/精英节点"没法选择"——
## 根因链：_process 短路 `if not _is_spawning or spawn_queue.is_empty(): return`
##         → 队列空时永不调 _spawn_next → _spawn_next 空队列分支永不执行
##         → _is_spawning 永久 true → wave_manager.check_wave_clear._spawning_incomplete()
##           永久 true → 普通关永不判通 → 干等 30s 超时兜底（Boss 关不走此检查故秒通，
##           用户感知"第 10 关 boss 之后节点没法选"）
## 用法：tools/Godot_v4.3-stable_win64.exe --headless --path "D:/30DAYS" --script res://tools/day31_spawner_deadlock_check.gd
## 退出码 0 = 全部通过（复现成功）；非 0 = 失败项数。
extends SceneTree

var _sub: int = 0
var _ready_mocks: bool = false
var _spawner: Node = null
var _checked: int = 0
var _failures: int = 0

func _initialize() -> void:
	print("=== Day31 spawner 死锁复现探针 ===")

func _process(_delta: float) -> bool:
	if not _ready_mocks:
		_setup()
		return false
	if _sub > 2:
		_report()
		quit(_failures)
		return true
	_sub = _advance(_sub)
	return false

func _setup() -> void:
	_ready_mocks = true
	_spawner = load("res://scripts/enemy/enemy_spawner.gd").new()
	root.add_child(_spawner)

func _ok(cond: bool, what: String) -> void:
	_checked += 1
	if not cond:
		_failures += 1
		print("  FAIL: " + what)
	else:
		print("  PASS: " + what)

func _report() -> void:
	print("=== Day31: %d checked, %d failed ===" % [_checked, _failures])

func _advance(sub: int) -> int:
	match sub:
		0:
			_part_deadlock_repro()
			return 1
		1:
			_part_process_short_circuit()
			return 2
		2:
			_report()
			quit(_failures)
	return 3

## §1 核心复现：spawn_wave 填队列 → _spawn_next 逐个出队 → 最后一只出队后 _is_spawning 应复位
func _part_deadlock_repro() -> void:
	# 真实 wave 11 配置（waves.json 数据源直取）
	var wave_config: Dictionary = {}
	if root.get_node_or_null("DataLoader") != null:
		wave_config = root.get_node("DataLoader").call("get_wave", 11)
	_ok(not wave_config.is_empty(), "§1: wave 11 配置存在")
	if wave_config.is_empty():
		wave_config = {"composition": [{"enemy": "chaser", "count": 3}]}
	_spawner.call("spawn_wave", wave_config, 11)
	var queue: Array = _spawner.get("spawn_queue")
	_ok(not queue.is_empty(), "§1: spawn_wave 后队列非空（%d 只）" % queue.size())
	var total: int = queue.size()
	# 白盒循环出队（等价 _process 逐帧驱动，跳过真实时间）
	for i in total:
		_spawner.call("_spawn_next")
	_ok(_spawner.get("spawn_queue").is_empty(), "§1: 全部出队后队列为空")
	_ok(not _spawner.call("is_spawning"), "§1: 生成标志应复位为 false（复现：实际仍 true → 死锁）")

## §2 自愈验证：队列空 + _is_spawning true 时 _process 应立即复位并发完成信号
func _part_process_short_circuit() -> void:
	_spawner.set("_is_spawning", true)
	_spawner.set("spawn_queue", [])
	var gm: Node = root.get_node_or_null("GameManager")
	if gm != null:
		gm.set("current_state", gm.GameState.BATTLE)
	# 修复后：队列空 → _process 自愈复位（_is_spawning true → false + spawn_complete）
	# ⚠️ lambda 按值捕获 int 局部变量（+= 只改副本）→ 用数组引用捕获计数
	var completed: Array = [0]
	_spawner.spawn_complete.connect(func() -> void: completed[0] += 1)
	_spawner.call("_process", 0.016)
	_ok(not _spawner.call("is_spawning"), "§2: 队列空时 _process 自愈复位（旧版死锁确认点）")
	_ok(completed[0] == 1, "§2: spawn_complete 恰好发 1 次（实得 %d）" % completed[0])
	# 再跑一帧 → 已复位短路，不重复发
	_spawner.call("_process", 0.016)
	_ok(completed[0] == 1, "§2: 后续帧不重复发（实得 %d）" % completed[0])
