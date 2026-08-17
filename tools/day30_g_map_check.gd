## G-B 出口校验：R1 大地图模式（G-R1-1~3 · 2026-08-14）
##
## 用法（无头）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day30_g_map_check.gd
##
## 校验内容：
##   §1 数据兼容：routes.json 15 层 × 3 节点零改动（旧 route_generator 数据结构）
##   §2 迷雾规则（O3）：当前层可点 + 前 2 层 visible + 之后 fogged + 已走 visited
##   §3 类型色块映射：战斗红/事件蓝/精英紫/商店金/Boss 深红
##   §4 选节点进入：当前层按钮 → select_route_node 分派正确节点类型
## 退出码 0 = 全部通过；非 0 = 失败项数。
extends SceneTree

const PANEL_SCENE_PATH: String = "res://scenes/RouteSelectPanel.tscn"
const ROUTE_GEN_PATH: String = "res://scripts/systems/route_generator.gd"

var _sub: int = 0
var _checked: int = 0
var _failures: int = 0

func _ok(cond: bool, msg: String) -> void:
	_checked += 1
	if cond:
		print("  PASS  " + msg)
	else:
		_failures += 1
		print("  FAIL  " + msg)

func _initialize() -> void:
	print("=== Day30-G-B map check ===")

func _process(_delta: float) -> bool:
	if _sub > 4:
		print("=== G-MAP CHECK: %d assertions, %d failures ===" % [_checked, _failures])
		quit(_failures)
		return true
	_sub = _advance(_sub)
	return false

func _advance(sub: int) -> int:
	match sub:
		0:
			_part_data_compat()
			return 1
		1:
			_part_fog_rules()
			return 2
		2:
			_part_type_colors()
			return 3
		3:
			_part_select_node()
			return 4
		4:
			return 99
		_:
			return 99

## 构造测试路线（仿 routes.json 结构：layers[i] = [{type, wave_index}]）
func _make_route(layer_count: int = 6, nodes_per_layer: int = 3) -> Dictionary:
	var layers: Array = []
	var wave: int = 1
	for i in range(layer_count):
		var layer: Array = []
		for j in range(nodes_per_layer):
			var ntype: String = "battle"
			if i == layer_count - 1:
				ntype = "boss"
			elif j == 1 and i % 2 == 1:
				ntype = "event"
			elif j == 2 and i == 2:
				ntype = "shop"
			layer.append({"type": ntype, "wave_index": wave})
			wave += 1
		layers.append(layer)
	return {"seed": 20260814, "layers": layers, "flags": {}}

# ========== §1 数据兼容 ==========

func _part_data_compat() -> void:
	var gen: GDScript = load(ROUTE_GEN_PATH)
	_ok(gen != null, "§1 数据: route_generator.gd 可加载")
	if gen == null:
		return
	var route: Dictionary = gen.call("generate", 20260814)
	var layers: Array = route.get("layers", [])
	_ok(layers.size() >= 15, "§1 数据: routes.json 生成 15 层（实得 %d）" % layers.size())
	# 章末 event 层（0-based；chapters 缺省空 → 空数组）。⚠️ 不能按「首节点类型==event」判断——
	# 普通 3 节点层的首节点也可能恰好为 event（真实路线 li=13 先例），须用 chapters 数据驱动判据
	var chapter_event_layers: Array = []
	for ch in route.get("chapters", []):
		var ch_layers: Array = ch.get("layers", [])
		if ch_layers.is_empty():
			continue
		if str(ch.get("end_type", "")) == "event":
			chapter_event_layers.append(int(ch_layers[ch_layers.size() - 1]) - 1)
	var all_3: bool = true
	for i in range(mini(layers.size(), 15)):
		# Boss 层（含 boss 类型）/ 章末 event 层（PS-D2a-1 单 event 节点）= 单节点；
		# 普通层 = 3 节点（routes.json boss_layers + chapters 驱动）
		var first_type: String = str(layers[i][0].get("type", ""))
		var expect: int = 1 if (first_type == "boss" or i in chapter_event_layers) else 3
		if int(layers[i].size()) != expect:
			all_3 = false
	_ok(all_3, "§1 数据: 普通层 3 节点 + 单节点层（boss/章末 event，routes.json 结构零改动）")

# ========== §2 迷雾规则 ==========

func _part_fog_rules() -> void:
	var scene: PackedScene = load(PANEL_SCENE_PATH)
	_ok(scene != null, "§2 迷雾: RouteSelectPanel.tscn 可加载")
	if scene == null:
		return
	var panel: Node = scene.instantiate()
	root.add_child(panel)
	var route: Dictionary = _make_route(6, 3)
	panel.call("setup", route, 2)  # 当前层 = 2（0 起）
	var meta: Array = panel.get("node_meta")
	_ok(meta.size() == 18, "§2 迷雾: 全层 6×3=18 节点均渲染（实得 %d）" % meta.size())
	# 状态分布：row0-1 visited / row2 current / row3-4 visible / row5 fogged
	var states: Dictionary = {}
	for m in meta:
		var r: int = int(m.get("row", -1))
		var st: String = str(m.get("state", "?"))
		if not states.has(r):
			states[r] = []
		states[r].append(st)
	_ok(states.get(0, []).size() == 3 and states[0][0] == "visited", "§2 迷雾: 已走层(0) visited 灰显")
	_ok(states.get(2, []).size() == 3 and states[2][0] == "current", "§2 迷雾: 当前层(2) current 可点")
	_ok(states.get(3, []).size() == 3 and states[3][0] == "visible", "§2 迷雾: 前 1 层(3) visible")
	_ok(states.get(4, []).size() == 3 and states[4][0] == "visible", "§2 迷雾: 前 2 层(4) visible")
	_ok(states.get(5, []).size() == 3 and states[5][0] == "fogged", "§2 迷雾: 第 3 层起(5) fogged 模糊")
	var buttons: Array = panel.get("buttons")
	_ok(buttons.size() == 3, "§2 迷雾: 仅当前层 3 按钮可点（实得 %d）" % buttons.size())
	panel.queue_free()

# ========== §3 类型色块 ==========

func _part_type_colors() -> void:
	var scene: PackedScene = load(PANEL_SCENE_PATH)
	var panel: Node = scene.instantiate()
	root.add_child(panel)
	# 白盒调用 _type_color（类型→色）
	var colors: Dictionary = {}
	for t in ["battle", "event", "elite", "shop", "boss"]:
		var c: Color = panel.call("_type_color", t)
		colors[t] = c
	_ok(colors["battle"].r > 0.6 and colors["battle"].b < 0.5, "§3 色块: battle 红系")
	_ok(colors["event"].b > 0.6, "§3 色块: event 蓝系")
	_ok(colors["elite"].r > 0.5 and colors["elite"].b > 0.6, "§3 色块: elite 紫系")
	_ok(colors["shop"].r > 0.6 and colors["shop"].g > 0.6, "§3 色块: shop 金系")
	_ok(colors["boss"].r > 0.7 and colors["boss"].g < 0.4, "§3 色块: boss 深红系")
	# 各类型标签文本
	_ok(str(panel.call("_type_label", "elite")) == "精英", "§3 色块: elite 标签「精英」")
	panel.queue_free()

# ========== §4 选节点进入 ==========

func _part_select_node() -> void:
	var gm: Node = root.get_node_or_null("GameManager")
	_ok(gm != null, "§4 选节点: GameManager autoload 在位")
	if gm == null:
		return
	var scene: PackedScene = load(PANEL_SCENE_PATH)
	var panel: Node = scene.instantiate()
	root.add_child(panel)
	var route: Dictionary = _make_route(4, 3)
	# 注入 GM 路线态（select_route_node 读 route.layers + current_layer）
	gm.set("route", route)
	gm.set("current_layer", 1)
	panel.call("setup", route, 1)
	# 白盒选当前层 col=2（route[1][2] 为 event）
	var target_type: String = str(route["layers"][1][2]["type"])
	panel.call("_on_node_pressed", 2)
	var cn: Dictionary = gm.get("current_node")
	_ok(cn != null and not cn.is_empty(), "§4 选节点: select_route_node 写入 current_node")
	var got_type: String = str(cn.get("type", "?"))
	_ok(got_type == target_type, "§4 选节点: 选中节点类型一致（实得 %s / 期望 %s）" % [got_type, target_type])
	gm.set("current_node", {})
	panel.queue_free()
