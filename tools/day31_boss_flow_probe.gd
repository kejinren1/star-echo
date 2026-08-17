## Day 31 PS-D 复现探针：打完第一个 Boss（层 6 = 0-based，wave 10 invoker）后
## 是否正常进入第 7 层路线选择（用户反馈「过了第一个 Boss 召唤者后节点没法选」）
##
## 用法（无头）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day31_boss_flow_probe.gd
##
## 流程：GM.reset → 注入 wave_manager/enemy_spawner（白盒，不依赖 Main 场景）
##      → route=生成(固定种子) → current_layer=6 → select_route_node(0)
##      → 等 spawner 生成 invoker → take_damage 击杀 → 断言层推进到 7 + ROUTE_SELECT
## 退出码 0 = 链路通；非 0 = 失败项数。
extends SceneTree

var _gm: Node = null
var _frame: int = 0
var _phase: int = 0
var _failures: int = 0
var _checked: int = 0

func _initialize() -> void:
	print("=== Day31 Boss flow probe ===")

func _process(_delta: float) -> bool:
	_frame += 1
	if _frame < 3:
		return false
	_gm = root.get_node_or_null("GameManager")
	if _gm == null:
		_fail("GameManager autoload 不可用")
		quit(_failures)
		return true
	match _phase:
		0:
			_setup()
			_phase = 1
		1:
			_wait_spawn()
			_phase = 2
		2:
			_kill_boss()
			_phase = 3
		3:
			_verify()
			quit(_failures)
			return true
	return false

## 注入 wave_manager / enemy_spawner，生成路线并进入第一个 Boss 层节点
func _setup() -> void:
	_gm.reset()
	var wm_scene: PackedScene = load("res://scenes/WaveManager.tscn")
	var wm: Node = wm_scene.instantiate()
	root.add_child(wm)
	_gm.wave_manager = wm
	var sp_scene: PackedScene = load("res://scenes/EnemySpawner.tscn")
	var sp: Node = sp_scene.instantiate()
	root.add_child(sp)
	var container := Node2D.new()
	container.name = "ProbeEnemies"
	root.add_child(container)
	sp.call("set_container", container)
	_gm.enemy_spawner = sp
	_gm.enemies_container = container
	# 路线：固定种子（层 6 = 0-based 第一个 Boss 层，boss_layers=[6,10,14] 数据驱动）
	var gen: GDScript = load("res://scripts/systems/route_generator.gd")
	var loader: Node = root.get_node_or_null("DataLoader")
	var routes: Dictionary = loader.call("get_routes") if loader else {}
	_gm.route = gen.call("generate_from", 20260806, routes)
	var layers: Array = _gm.route.get("layers", [])
	print("  route layers=%d boss_layers=%s 层6类型=%s" % [layers.size(), str(_gm.route.get("boss_layers")), str(layers[6][0].get("type"))])
	_gm.current_layer = 6
	_gm.select_route_node(0)
	_checked += 1

## 等 spawner 把 invoker 生成出来（1-2 帧内）
func _wait_spawn() -> void:
	var container: Node = _gm.enemies_container
	var boss: Node = null
	if container:
		for e in container.get_children():
			if e.get("is_boss") == true:
				boss = e
				break
	if boss == null:
		_fail("Boss 未生成（enemies=%d, spawning=%s）" % [container.get_child_count() if container else -1, str(_gm.enemy_spawner.is_spawning())])
		quit(_failures)
		return
	print("  Boss 已生成: %s hp=%.0f wave_state=%s" % [boss.get("enemy_id"), float(boss.get("health")), str(_gm.wave_manager.get("is_active"))])
	_checked += 1
	boss.set_meta("probe_boss", boss)

## 击杀 Boss → 应触发 check_wave_clear → _end_wave → on_wave_cleared → _on_node_completed
func _kill_boss() -> void:
	var boss: Node = _gm.enemies_container.get_child(0) if _gm.enemies_container else null
	if boss == null or boss.get("is_alive") == false:
		_fail("Boss 引用丢失")
		return
	boss.call("take_damage", 999999.0)
	print("  Boss 击杀完成, is_alive=%s" % str(boss.get("is_alive")))

## 断言：层推进 + 状态 + 面板按钮
func _verify() -> void:
	var layers: Array = _gm.route.get("layers", [])
	var layer_ok: bool = _gm.current_layer == 7
	var state_ok: bool = _gm.current_state == _gm.GameState.ROUTE_SELECT
	var panel: Node = _gm.get("_route_select_panel")
	var panel_ok: bool = panel != null and is_instance_valid(panel) and panel.get("buttons") != null and (panel.get("buttons") as Array).size() > 0
	_checked += 1
	if layer_ok:
		print("  PASS  current_layer=7（进入第 8 关）")
	else:
		_fail("current_layer 应为 7，实得 %d" % _gm.current_layer)
	_checked += 1
	if state_ok:
		print("  PASS  状态 = ROUTE_SELECT")
	else:
		_fail("状态应为 ROUTE_SELECT，实得 %s" % str(_gm.current_state))
	_checked += 1
	if panel_ok:
		print("  PASS  路线面板已 setup，按钮数=%d" % (panel.get("buttons") as Array).size())
	else:
		_fail("路线面板缺失或无可点按钮")
	print("  检查 %d 项，失败 %d 项" % [_checked, _failures])

func _fail(msg: String) -> void:
	_failures += 1
	print("  FAIL  %s" % msg)
