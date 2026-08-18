## Day 18-FB6 出口校验：F-30 生成判定（反馈 1）+ 第 11 层精英节点链路（反馈 3 复现）
##
## 用法：tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day18_feedback6_check.gd
##
## §1 F-30：普通关生成未完成不判通（wave1 12 敌分批：杀 1 个 → 不通过；队列清空+敌全灭 → 通过）
## §2 反馈 3 复现：15 层 route → 第 10 关 boss 清（on_wave_cleared）→ current_layer==10 →
##    _start_route_select 面板渲染第 11 层 → select_route_node(精英 row) → BATTLE + wave 11 生成 +
##    面板销毁（复现「点精英没反应/选项卡死」是否为我方改动引入）
##
## 退出码 0 = 全部通过；非 0 = 失败项数。
extends SceneTree

var _sub: int = 0
var _ready_mocks: bool = false
var _gm: Node = null
var _loader: Node = null
var _checked: int = 0
var _failures: int = 0

func _initialize() -> void:
	print("=== Day 18-FB6 check (F-30 生成判定 / 第 11 层精英链路) ===")

func _process(_delta: float) -> bool:
	if not _ready_mocks:
		_load_mocks()
		return false
	if _sub > 3:
		_report()
		quit(_failures)
		return true
	_sub = _advance(_sub)
	return false

func _load_mocks() -> void:
	_ready_mocks = true
	_gm = root.get_node_or_null("GameManager")
	_loader = root.get_node_or_null("DataLoader")
	if _gm == null or _loader == null:
		_fail("Autoload 缺失")
		_report()
		quit(1)

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
	print("=== Day 18-FB6: %d checked, %d failed ===" % [_checked, _failures])

func _advance(sub: int) -> int:
	match sub:
		0:
			_part_spawn_check()
			return 1
		1:
			_part_elite_link()
			return 2
		2:
			# queue_free 延迟帧 → 本帧检查面板销毁（反馈 3「选项卡卡死」= F-30 秒通回弹，非面板残留）
			_ok(_gm.get("_route_select_panel") == null, "链路: 面板已销毁（不卡选项）")
			_report()
			quit(_failures)
	return 3

# ========== §1 F-30 生成判定 ==========

class MockEnemy:
	extends Node2D
	var is_alive: bool = true
	var is_boss: bool = false

func _part_spawn_check() -> void:
	var wm_script: GDScript = load("res://scripts/systems/wave_manager.gd")
	var wm = wm_script.new()
	root.add_child(wm)
	var container := Node2D.new()
	root.add_child(container)
	var spawner_mock = load("res://scripts/enemy/enemy_spawner.gd").new()
	spawner_mock.set("enemies_container", container)
	var wm_backup: Variant = _gm.get("wave_manager")
	var spawner_backup: Variant = _gm.get("enemy_spawner")
	var cont_backup: Variant = _gm.get("enemies_container")
	var boss_backup: Variant = _gm.get("is_boss_wave")
	_gm.set("wave_manager", wm)
	_gm.set("enemy_spawner", spawner_mock)
	_gm.set("enemies_container", container)
	_gm.set("is_boss_wave", false)
	wm.set("is_active", true)
	var ev: Array = []
	wm.wave_cleared.connect(func(_n: int) -> void: ev.append(_n))
	# 场景：wave1 12 敌分批生成——容器 1 个活敌，spawn_queue 还有 11 个
	spawner_mock.set("_is_spawning", true)
	var queue: Array = []
	for i in 11:
		queue.append({"enemy_id": "chaser", "wave": 1})
	spawner_mock.set("spawn_queue", queue)
	var e1: MockEnemy = MockEnemy.new()
	e1.is_alive = true
	container.add_child(e1)
	wm.call("check_wave_clear")
	_ok(ev.is_empty(), "F-30/生成中: 队列未空 + 1 存活 → 不判通")
	# 杀 1 个 → 容器空但队列还有 → 仍不通（F-30 核心：生成未完成不判通）
	e1.is_alive = false
	wm.call("check_wave_clear")
	_ok(ev.is_empty(), "F-30/核心: 杀完已生成 1 个但队列 11 个未出 → 不判通（修复「第一关 1 怪就通关」）")
	# 队列清空（生成完成）→ 敌全灭 → 开传送门（F-49），进传送门才通关
	spawner_mock.set("_is_spawning", false)
	spawner_mock.set("spawn_queue", [])
	wm.call("check_wave_clear")
	_ok(bool(wm.get("_portal_await")), "F-49/完成: 队列空 + 敌全灭 → 开传送门（不立即结算）")
	wm.call("enter_portal")
	_ok(ev.size() == 1 and not bool(wm.get("is_active")), "F-30/完成: 进传送门 → 通关")
	# 恢复
	_gm.set("wave_manager", wm_backup)
	_gm.set("enemy_spawner", spawner_backup)
	_gm.set("enemies_container", cont_backup)
	_gm.set("is_boss_wave", boss_backup)
	container.queue_free()
	wm.queue_free()

# ========== §2 反馈 3 复现：第 11 层精英链路 ==========

func _part_elite_link() -> void:
	# 15 层 route 生成
	var gen: GDScript = load("res://scripts/systems/route_generator.gd")
	var route: Dictionary = gen.call("generate", 20260806)
	# 第 10 关（layer 9）Boss 清 → 推进到第 11 层（layer 10）
	var state_backup: Variant = _gm.get("current_state")
	var layer_backup: Variant = _gm.get("current_layer")
	var route_backup: Variant = _gm.get("route")
	_gm.set("route", route)
	_gm.set("current_layer", 9)
	_gm.set("current_node", {"type": "boss"})
	_gm.call("on_wave_cleared")
	_ok(int(_gm.get("current_layer")) == 10, "链路: Boss 清 → current_layer 10（第 11 层）")
	# 面板应实例化并渲染第 11 层
	var panel: Node = _gm.get("_route_select_panel")
	_ok(panel != null and is_instance_valid(panel), "链路: 第 11 层路线面板已实例化")
	if panel == null or not is_instance_valid(panel):
		_gm.set("current_state", state_backup)
		_gm.set("current_layer", layer_backup)
		_gm.set("route", route_backup)
		return
	var btns: Array = panel.get("buttons")
	_ok(btns.size() >= 1, "链路: 第 11 层按钮 %d 个（实得 %d）" % [int(route.get("layers", [])[10].size()), btns.size()])
	# 找一个精英节点按钮点击（无精英则找第 1 个 battle）
	var click_idx: int = -1
	for i in route.get("layers", [])[10].size():
		if str(route.get("layers", [])[10][i].get("type", "")) == "elite":
			click_idx = i
			break
	if click_idx < 0:
		click_idx = 0
	_ok(click_idx >= 0 and click_idx < btns.size(), "链路: 目标节点索引 %d 在按钮范围内" % click_idx)
	if click_idx >= 0 and click_idx < btns.size():
		btns[click_idx].pressed.emit()
		_ok(_gm.get("current_state") == _gm.GameState.BATTLE, "链路: 点击节点 → BATTLE（实得 %s）" % str(_gm.get("current_state")))
		# wave 11 生成配置解析（composition 敌 id 全存在？）
		var w11: Dictionary = _loader.call("get_wave", 11)
		var missing: Array = []
		if not w11.is_empty():
			for entry in w11.get("composition", []):
				var eid: String = str(entry.get("enemy", ""))
				if eid.contains(":"):
					eid = eid.split(":")[1]
				if eid == "mixed":
					continue
				if _loader.call("get_enemy", eid).is_empty():
					missing.append(eid)
		_ok(missing.is_empty(), "链路: wave 11 敌 id 全部存在（缺: %s）" % str(missing))
	# 恢复（面板 queue_free 延迟帧，探针退出时清理）
	_gm.set("current_state", state_backup)
	_gm.set("current_layer", layer_backup)
	_gm.set("route", route_backup)
	if panel != null and is_instance_valid(panel):
		panel.queue_free()
