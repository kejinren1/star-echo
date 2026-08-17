## Day31 Boss 后选关 · 真人路径探针 v4（08-18 用户反馈「打完第一个 Boss 不能选关」依旧复现）
## 根因：Boss 击杀瞬间 die() 内 _drop_rewards()（可能触发升级 → 升级面板弹出 + paused=true）
## → 之后 check_wave_clear() → _start_route_select() 创建路线面板。两个 CanvasLayer 若同 layer，
## 后创建的路线面板盖住升级面板；路线面板 process_mode 默认 INHERIT → paused 态按钮不可点
## → 用户看到路线面板但点不了 = 「不能选关」（探针 v3 直接 emit 信号绕过真实点击，未发现）。
## 修复：升级面板 CanvasLayer.layer = 10（模态置顶）→ 升级面板盖住路线面板且可点，
## 点完恢复暂停后路线面板可见可点。
## v4：直接读取 CanvasLayer.layer 断言置顶；路线面板真实 GUI 点击验证选关链路（未暂停态）。
extends SceneTree

var _checked: int = 0
var _failures: int = 0
var _frame: int = 0
var _phase: int = 0
var _sub: int = 0
var _route_panel: Node = null

func _initialize() -> void:
	print("=== Day31 boss-after overlay / real-GUI click check v4 ===")

func _ok(cond: bool, msg: String) -> void:
	_checked += 1
	if cond:
		print("  PASS  %s" % msg)
	else:
		_failures += 1
		print("  FAIL  %s" % msg)

func _fail(msg: String) -> void:
	_failures += 1
	print("  FAIL  %s" % msg)

func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 50:
		print("=== Day31 boss-after v4: %d checked, %d failed ===" % [_checked, _failures])
		quit(_failures)
		return true
	match _phase:
		0:
			if _frame >= 10:
				_phase = 1
				_test_layer_order()
		1:
			_phase = 2
			_setup_route_panel()
		2:
			_phase = 3
			_click_route_button()
		3:
			if _frame >= _sub:
				_phase = 4
				_verify_route_clicked()
	return false

## §1 升级面板 layer 必须高于路线面板（模态置顶修复生效）
func _test_layer_order() -> void:
	_phase = 1
	var lv: PackedScene = load("res://scenes/LevelUpPanel.tscn")
	var up: CanvasLayer = lv.instantiate()
	root.add_child(up)
	var rsp: PackedScene = load("res://scenes/RouteSelectPanel.tscn")
	var rt: CanvasLayer = rsp.instantiate()
	root.add_child(rt)
	_ok(int(up.layer) >= 10, "升级面板 CanvasLayer.layer = %d ≥ 10（模态置顶，修复 08-18）" % int(up.layer))
	_ok(int(rt.layer) < 10, "路线面板 CanvasLayer.layer = %d < 10（不会盖住升级面板）" % int(rt.layer))
	_ok(int(up.process_mode) == 3, "升级面板 process_mode = 3（暂停态可交互）")
	_ok(int(up.layer) > int(rt.layer), "升级面板 layer(%d) > 路线面板 layer(%d) → 升级面板在上层可点" % [int(up.layer), int(rt.layer)])
	up.queue_free()
	rt.queue_free()

## §2 构造路线面板（模拟 Boss 后 ROUTE_SELECT）
func _setup_route_panel() -> void:
	_phase = 2
	var rsp: PackedScene = load("res://scenes/RouteSelectPanel.tscn")
	_route_panel = rsp.instantiate()
	root.add_child(_route_panel)
	var layers: Array = []
	for li in 15:
		if li == 6:
			layers.append([{"type": "boss", "wave_index": 10}])
		else:
			layers.append([
				{"type": "battle", "wave_index": li + 1},
				{"type": "shop", "wave_index": 0},
				{"type": "event", "wave_index": 0},
			])
	_route_panel.call("setup", {"layers": layers, "boss_layers": [6, 10, 14], "flags": {}}, 7)
	var btns: Array = _route_panel.get("buttons")
	_ok(btns.size() == 3, "路线面板层 8（index 7）3 按钮生成")

## §3 真实 GUI 点击路线面板按钮（未暂停态——真实场景点完升级面板后才到这里）
func _click_route_button() -> void:
	_phase = 3
	var btns: Array = _route_panel.get("buttons")
	if btns.size() < 1:
		_fail("路线面板无按钮")
		return
	var btn: Button = btns[0]
	var pos: Vector2 = btn.get_global_rect().get_center()
	_send_click(pos)
	_sub = _frame + 5

## §4 点击后面板应自毁（_on_node_pressed → select_route_node + queue_free）
func _verify_route_clicked() -> void:
	_phase = 4
	_ok(not is_instance_valid(_route_panel) or _route_panel.is_queued_for_deletion(),
		"路线面板按钮真实 GUI 点击 → 面板自毁（select_route_node 被触发，选关链路通）")
	if is_instance_valid(_route_panel):
		_route_panel.queue_free()

func _send_click(pos: Vector2) -> void:
	var ev_p := InputEventMouseButton.new()
	ev_p.button_index = MOUSE_BUTTON_LEFT
	ev_p.pressed = true
	ev_p.position = pos
	ev_p.global_position = pos
	root.push_input(ev_p)
	var ev_r := InputEventMouseButton.new()
	ev_r.button_index = MOUSE_BUTTON_LEFT
	ev_r.pressed = false
	ev_r.position = pos
	ev_r.global_position = pos
	root.push_input(ev_r)
