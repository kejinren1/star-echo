## Day 14-15 出口校验：随机节点地图（D14-15-T1~T5 / EXIT 收口）
##
## 用法（无头，不需要编辑器）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day14_15_route_check.gd
##
## 校验内容（对应 docs/TASKS.md D14-15-T5 六段）：
##   1. 种子可复现：同 seed 两次 generate 逐层逐节点全等；seed 1 vs 2 差异；随机种子回传
##   2. 拓扑合法性：layers == routes.json.layers；每层节点数 == nodes_per_layer（末层 1 boss）；
##      首层含 battle；boss 仅末层；类型 ∈ 5 类；battle_count ≤ 19
##   3. 数据驱动：weights 归一化（和≈1.0）；default_seed 可读；weights 全空 → 默认权重兜底
##   4. 波次映射：battle/elite → wave_index ∈ [1,19] 且 DataLoader.get_wave 非空；boss → 20；
##      shop/event → 0
##   5. 模式兼容：route_enabled=false → start_game → BATTLE 且零面板（旧行为）；
##      _start_next_wave() 默认 -1 累加不变；route_enabled=true → ROUTE_SELECT
##   6. 路线模式端到端（白盒直驱动）：event 占位推进 / 战斗节点波次映射 / shop→close_shop 推进 /
##      boss 清 → victory；面板按钮数 == 本层节点数；按钮回调 → select_route_node + 面板销毁
##
## 退出码 0 = 全部通过；非 0 = 失败项数。
extends SceneTree

const ROUTE_GEN_PATH: String = "res://scripts/systems/route_generator.gd"
const PANEL_SCENE_PATH: String = "res://scenes/RouteSelectPanel.tscn"

const FIXED_SEED: int = 20260806   ## 固定复现种子（routes.json default_seed）
const SEED_A: int = 1
const SEED_B: int = 2

## 端到端固定路线：L0=[battle w1, shop, event] · L1=[battle w2] · L2=[boss w20]
const FIXED_ROUTE: Dictionary = {
	"seed": 999,
	"layers": [
		[
			{"type": "battle", "wave_index": 1},
			{"type": "shop", "wave_index": 0},
			{"type": "event", "wave_index": 0},
		],
		[
			{"type": "battle", "wave_index": 2},
		],
		[
			{"type": "boss", "wave_index": 20},
		],
	],
	"modifiers": {},
	"flags": {},
}

var _sub: int = 0
var _ready_mocks: bool = false
var _loader: Node = null
var _gm: Node = null
var _gen: GDScript = null
var _states: Dictionary = {}
var _route_same_a: Dictionary = {}
var _route_same_b: Dictionary = {}
var _route_diff_a: Dictionary = {}
var _route_diff_b: Dictionary = {}
var _route_rand: Dictionary = {}
var _checked: int = 0
var _failures: int = 0

func _initialize() -> void:
	print("=== Day 14-15 route map check ===")

func _process(_delta: float) -> bool:
	if not _ready_mocks:
		_load_mocks()
		return false
	if _sub > 40:
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
	_gen = load(ROUTE_GEN_PATH)
	# GameState 枚举读取（Godot 4 用 get_script_constant_map；get_constant 不存在）
	_states = _gm.get_script().get_script_constant_map().get("GameState", {})

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
	print("=== DAY14-15 ROUTE CHECK: %d assertions, %d failures ===" % [_checked, _failures])
	if _failures == 0:
		print("DAY14-15 ROUTE CHECK CLEAN")

## 深度对比两条路线（seed + 逐层逐节点 type/wave_index）
func _routes_equal(a: Dictionary, b: Dictionary) -> bool:
	if int(a.get("seed", -1)) != int(b.get("seed", -1)):
		return false
	var la: Array = a.get("layers", [])
	var lb: Array = b.get("layers", [])
	if la.size() != lb.size():
		return false
	for i in la.size():
		var na: Array = la[i]
		var nb: Array = lb[i]
		if na.size() != nb.size():
			return false
		for j in na.size():
			var da: Dictionary = na[j]
			var db: Dictionary = nb[j]
			if str(da.get("type")) != str(db.get("type")) or int(da.get("wave_index", -1)) != int(db.get("wave_index", -1)):
				return false
	return true

## 遍历全部节点
func _all_nodes(route: Dictionary) -> Array:
	var out: Array = []
	for layer in route.get("layers", []):
		for node in layer:
			out.append(node)
	return out

## 战斗类节点数（battle + elite）
func _battle_count(route: Dictionary) -> int:
	var c: int = 0
	for node in _all_nodes(route):
		var t: String = str(node.get("type", ""))
		if t == "battle" or t == "elite":
			c += 1
	return c

# ========== 主推进（线性子步骤） ==========

func _advance(sub: int) -> int:
	match sub:
		# ---------- §1 种子可复现 ----------
		0:
			_route_same_a = _gen.generate_from(FIXED_SEED, _loader.get_routes())
			_route_same_b = _gen.generate_from(FIXED_SEED, _loader.get_routes())
			return 1
		1:
			_ok(not _route_same_a.is_empty(), "固定 seed 生成非空")
			_ok(int(_route_same_a.get("seed")) == FIXED_SEED, "seed 回传一致")
			_ok(_routes_equal(_route_same_a, _route_same_b), "同 seed 两次生成逐层全等")
			_route_diff_a = _gen.generate_from(SEED_A, _loader.get_routes())
			_route_diff_b = _gen.generate_from(SEED_B, _loader.get_routes())
			return 2
		2:
			_ok(not _routes_equal(_route_diff_a, _route_diff_b), "seed 1 vs 2 中间层出现差异")
			_route_rand = _gen.generate_from(-1, _loader.get_routes())
			return 3
		3:
			# rng.seed 为 int64，randomize() 后可能 ≥2^63 溢出为负 → 断言「非 -1 哨兵」而非「>= 0」
			_ok(int(_route_rand.get("seed")) != -1, "随机种子已回传（非 -1 哨兵）")
			_ok(not _route_rand.is_empty(), "随机种子生成非空")
			return 4
		# ---------- §2 拓扑合法性 ----------
		4:
			var layers: Array = _route_same_a.get("layers", [])
			_ok(layers.size() == int(_loader.get_routes().get("layers", -1)), "层数 == routes.json.layers")
			var npl: int = int(_loader.get_routes().get("nodes_per_layer", -1))
			var middle_ok: bool = true
			for li in layers.size() - 1:
				if (layers[li] as Array).size() != npl:
					middle_ok = false
			_ok(middle_ok, "中间层每层节点数 == nodes_per_layer")
			var last_layer: Array = layers[layers.size() - 1]
			_ok(last_layer.size() == 1 and str(last_layer[0].get("type")) == "boss", "末层唯一 boss 节点")
			_ok(_layer_has_battle(layers[0]), "首层含 battle")
			var boss_only_last: bool = true
			for li in layers.size() - 1:
				for node in layers[li]:
					if str(node.get("type")) == "boss":
						boss_only_last = false
			_ok(boss_only_last, "boss 仅末层")
			var types_ok: bool = true
			var valid: Array = ["battle", "event", "elite", "shop", "boss"]
			for node in _all_nodes(_route_same_a):
				if not valid.has(str(node.get("type"))):
					types_ok = false
			_ok(types_ok, "节点类型 ∈ 5 类")
			_ok(_battle_count(_route_same_a) <= 19, "battle_count <= 19")
			return 5
		# ---------- §3 数据驱动 ----------
		5:
			var w: Dictionary = _loader.get_routes().get("weights", {})
			var total: float = 0.0
			for k in w:
				total += float(w[k])
			_ok(absf(total - 1.0) <= 0.05, "weights 归一化（和≈1.0，实为 %.2f）" % total)
			_ok(int(_loader.get_routes().get("default_seed", 0)) > 0, "default_seed 可读")
			_ok(int(_loader.get_routes().get("layers", 0)) * int(_loader.get_routes().get("nodes_per_layer", 0)) >= 5, "layers × nodes_per_layer ≥ 5")
			var no_w: Dictionary = _gen.generate_from(FIXED_SEED, {"layers": 3, "nodes_per_layer": 2})
			var nw_layers: Array = no_w.get("layers", [])
			var nw_ok: bool = nw_layers.size() == 3
			for li in 2:
				if (nw_layers[li] as Array).size() != 2:
					nw_ok = false
			_ok(nw_ok, "weights 全空 → 默认权重兜底（3 层 × 2 节点）")
			return 6
		# ---------- §4 波次映射 ----------
		6:
			var map_ok: bool = true
			var boss_ok: bool = true
			var zero_ok: bool = true
			for node in _all_nodes(_route_same_a):
				var t: String = str(node.get("type"))
				var wi: int = int(node.get("wave_index"))
				if t == "battle" or t == "elite":
					if wi < 1 or wi > 19 or _loader.call("get_wave", wi).is_empty():
						map_ok = false
				elif t == "boss":
					if wi != 20:
						boss_ok = false
				elif t == "shop" or t == "event":
					if wi != 0:
						zero_ok = false
			_ok(map_ok, "battle/elite → wave ∈ [1,19] 且 get_wave 非空")
			_ok(boss_ok, "boss → wave_index == 20")
			_ok(zero_ok, "shop/event → wave_index == 0")
			return 7
		# ---------- §5 模式兼容 ----------
		7:
			_gm.set("route_enabled", false)
			_gm.set("route", {})
			_gm.call("start_game")
			_ok(_gm.get("current_state") == _states.BATTLE, "route_enabled=false → start_game 后 BATTLE（旧行为）")
			_ok(int(_gm.get("current_wave")) == 1, "旧行为 current_wave == 1")
			_ok(_gm.get("_route_select_panel") == null, "旧行为零路线面板")
			return 8
		8:
			_gm.call("reset")
			_gm.set("current_wave", 5)
			_gm.set("route", {})
			_gm.call("_start_next_wave")
			_ok(int(_gm.get("current_wave")) == 6, "_start_next_wave() 默认 -1 累加不变")
			return 9
		9:
			_gm.call("reset")
			_gm.set("route_enabled", true)
			_gm.set("route", {})
			_gm.call("start_game")
			var st: Variant = _gm.get("current_state")
			_ok(st == _states.ROUTE_SELECT, "route_enabled=true → start_game 后 ROUTE_SELECT")
			_ok(not (_gm.get("route") as Dictionary).is_empty(), "start_game 默认 seed 生成路线非空")
			var panel: Node = _gm.get("_route_select_panel")
			_ok(panel != null and is_instance_valid(panel), "ROUTE_SELECT 状态下面板已实例化")
			if panel != null and is_instance_valid(panel):
				_ok(_panel_buttons(panel).size() == int(_loader.get_routes().get("nodes_per_layer", 0)), "面板按钮数 == nodes_per_layer")
			return 10
		# ---------- §6 路线模式端到端（白盒直驱动） ----------
		10:
			_gm.call("reset")
			_gm.set("route", FIXED_ROUTE)
			_gm.set("current_layer", 0)
			_gm.call("_start_route_select")
			var p0: Node = _gm.get("_route_select_panel")
			_ok(_gm.get("current_state") == _states.ROUTE_SELECT, "E2E: L0 → ROUTE_SELECT")
			_ok(p0 != null and is_instance_valid(p0), "E2E: L0 面板存在")
			_ok(_panel_buttons(p0).size() == 3, "E2E: L0 按钮数 == 3")
			return 11
		11:
			# event 节点（row 2）→ 占位推进到 L1
			_gm.call("select_route_node", 2)
			var p1: Node = _gm.get("_route_select_panel")
			_ok(str(_gm.get("current_node").get("type")) == "event", "E2E: 选中 event 节点")
			_ok(_gm.get("current_state") == _states.ROUTE_SELECT, "E2E: event 占位推进后仍 ROUTE_SELECT")
			_ok(int(_gm.get("current_layer")) == 1, "E2E: event 推进到 L1")
			_ok(_panel_buttons(p1).size() == 1, "E2E: L1 按钮数 == 1（battle w2）")
			return 12
		12:
			# 战斗节点（L1 row 0, battle w2）→ 真实按钮回调
			var p2: Node = _gm.get("_route_select_panel")
			var btn2: Button = _panel_buttons(p2)[0]
			btn2.pressed.emit()
			_ok(str(_gm.get("current_node").get("type")) == "battle", "E2E: 按钮回调选中 battle")
			_ok(_gm.get("current_state") == _states.BATTLE, "E2E: battle → BATTLE")
			_ok(int(_gm.get("current_wave")) == 2, "E2E: 波次映射 wave == 2")
			return 13
		13:
			# 面板按钮回调已 queue_free → 下一帧 tree_exited 清引用
			_ok(_gm.get("_route_select_panel") == null, "E2E: 按钮回调后面板销毁")
			_gm.call("on_wave_cleared")
			var p3: Node = _gm.get("_route_select_panel")
			_ok(int(_gm.get("current_layer")) == 2, "E2E: battle 清后推进到 L2")
			_ok(_gm.get("current_state") == _states.ROUTE_SELECT, "E2E: L2 → ROUTE_SELECT")
			_ok(_panel_buttons(p3).size() == 1, "E2E: L2 按钮数 == 1（boss）")
			return 14
		14:
			# boss 节点（L2 row 0, wave 20）
			var p4: Node = _gm.get("_route_select_panel")
			var btn4: Button = _panel_buttons(p4)[0]
			btn4.pressed.emit()
			_ok(str(_gm.get("current_node").get("type")) == "boss", "E2E: 选中 boss 节点")
			_ok(_gm.get("current_state") == _states.BATTLE, "E2E: boss → BATTLE")
			_ok(int(_gm.get("current_wave")) == 20, "E2E: boss 波次映射 wave == 20")
			_ok(_gm.get("is_boss_wave") == true, "E2E: is_boss_wave == true")
			return 15
		15:
			_gm.call("on_wave_cleared")
			_ok(_gm.get("current_state") == _states.GAME_OVER, "E2E: boss 清 → GAME_OVER 胜利")
			paused = false  # end_game 已暂停，复位防污染
			return 16
		16:
			# shop 节点 → close_shop 推进（白盒直驱动）
			_gm.call("reset")
			_gm.set("route", FIXED_ROUTE)
			_gm.set("current_layer", 0)
			_gm.call("select_route_node", 1)
			_ok(str(_gm.get("current_node").get("type")) == "shop", "E2E: 选中 shop 节点")
			_ok(_gm.get("current_state") == _states.SHOP, "E2E: shop → SHOP 状态")
			_gm.call("close_shop")
			_ok(int(_gm.get("current_layer")) == 1, "E2E: close_shop 推进到 L1")
			_ok(_gm.get("current_state") == _states.ROUTE_SELECT, "E2E: shop 后回 ROUTE_SELECT")
			return 17
		_:
			return 41  # 结束哨兵

# ========== 工具 ==========


## Array[Button]（typed）→ Array：Godot 4 禁止 `as Array` 强转 typed 数组，须隐式赋值
func _panel_buttons(panel: Node) -> Array:
	var btns: Array = panel.get("buttons")
	return btns

func _layer_has_battle(layer_nodes: Array) -> bool:
	for node in layer_nodes:
		var t: String = str(node.get("type"))
		if t == "battle" or t == "elite":
			return true
	return false
