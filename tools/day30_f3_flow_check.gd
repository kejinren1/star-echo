## Day 30-F3 状态流探针（白盒驱动 GM · T-031 收口验收）
##
## 用法（无头）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day30_f3_flow_check.gd
##
## 校验内容（docs/SOLUTION_PLAN.md §2 F3-T9）：
##   §1 合法序列 MENU→ROUTE_SELECT→BATTLE→SHOP→BATTLE→GAME_OVER→MENU（current_state + context）
##   §2 同值早退幂等（重复转移零 emit）+ state_changed 信号次数/值核对
##   §3 非法序列安全（GAME_OVER→BATTLE 跳态调用不崩 / 状态不损坏 / 可继续合法流转——
##      T9 定案：不做硬拒绝，_transition 保持任意态可切现状语义）
##   §4 get_state_context() 读取（context 透传）
##   §5 route 模式 vs 旧波次制双路径等价（_is_route_mode 派生 + _enter_node 双路径）
##
## 退出码 0 = 全部通过；非 0 = 失败项数。
extends SceneTree

var _sub: int = 0
var _gm: Node = null
var _checked: int = 0
var _failures: int = 0

func _initialize() -> void:
	print("=== Day 30 F3 状态流检查 ===")

func _process(_delta: float) -> bool:
	if _sub == 0:
		_sub = _advance(_sub)
	elif _sub == 1:
		_report()
		quit(_failures)
		return true
	return false

func _advance(sub: int) -> int:
	_gm = root.get_node_or_null("GameManager")
	if _gm == null:
		_fail("GameManager autoload 缺失")
		return 1
	_part_legal_sequence()
	_part_idempotent_and_signal()
	_part_illegal_safe()
	_part_context()
	_part_route_dual_path()
	return 1

func _st() -> int:
	return int(_gm.get("current_state"))

# ========== §1 合法序列 ==========

func _part_legal_sequence() -> void:
	print("-- §1 合法序列 --")
	_gm.call("_transition", _gm.GameState.MENU)  # 同值早退（初始 MENU）
	_ok(_st() == _gm.GameState.MENU, "§1 初始 MENU")
	_gm.call("_transition", _gm.GameState.ROUTE_SELECT, {"from_battle": false})
	_ok(_st() == _gm.GameState.ROUTE_SELECT, "§1 MENU→ROUTE_SELECT")
	_gm.call("_transition", _gm.GameState.BATTLE)
	_ok(_st() == _gm.GameState.BATTLE, "§1 ROUTE_SELECT→BATTLE")
	_gm.call("_transition", _gm.GameState.SHOP, {"from_battle": true})
	_ok(_st() == _gm.GameState.SHOP, "§1 BATTLE→SHOP")
	_gm.call("_transition", _gm.GameState.BATTLE)
	_ok(_st() == _gm.GameState.BATTLE, "§1 SHOP→BATTLE")
	_gm.call("_transition", _gm.GameState.GAME_OVER)
	_ok(_st() == _gm.GameState.GAME_OVER, "§1 BATTLE→GAME_OVER")
	_gm.call("_transition", _gm.GameState.MENU)
	_ok(_st() == _gm.GameState.MENU, "§1 GAME_OVER→MENU")

# ========== §2 同值早退 + 信号 ==========

func _part_idempotent_and_signal() -> void:
	print("-- §2 同值早退 + 信号 --")
	var emits: Array = [0]
	var last_val: Array = [-1]
	_gm.state_changed.connect(func(s): emits[0] += 1; last_val[0] = int(s))
	_gm.call("_transition", _gm.GameState.MENU)  # 当前 MENU → 同值早退
	_ok(emits[0] == 0, "§2 同值(MENU→MENU)早退零 emit（实得 %d）" % emits[0])
	_gm.call("_transition", _gm.GameState.BATTLE)
	_ok(emits[0] == 1 and last_val[0] == _gm.GameState.BATTLE,
		"§2 MENU→BATTLE emit 1 次 + 值正确（emits=%d val=%d）" % [emits[0], last_val[0]])
	_gm.call("_transition", _gm.GameState.BATTLE)
	_ok(emits[0] == 1, "§2 重复 BATTLE→BATTLE 不重复 emit（实得 %d）" % emits[0])
	_gm.call("_transition", _gm.GameState.SHOP)
	_ok(emits[0] == 2, "§2 BATTLE→SHOP emit 累计 2（实得 %d）" % emits[0])

# ========== §3 非法序列安全 ==========

func _part_illegal_safe() -> void:
	print("-- §3 非法序列安全 --")
	# 当前 SHOP；跳态 GAME_OVER→BATTLE 语义：任意态可切（T9 定案不做硬拒绝）
	_gm.call("_transition", _gm.GameState.GAME_OVER)
	_gm.call("_transition", _gm.GameState.BATTLE)  # 跳态调用
	_ok(_st() == _gm.GameState.BATTLE, "§3 跳态 GAME_OVER→BATTLE 不崩（状态已切，现状语义）")
	# 状态不损坏：可继续合法流转
	_gm.call("_transition", _gm.GameState.MENU)
	_ok(_st() == _gm.GameState.MENU, "§3 跳态后状态不损坏（→MENU 正常）")

# ========== §4 context 透传 ==========

func _part_context() -> void:
	print("-- §4 context --")
	_gm.call("_transition", _gm.GameState.SHOP, {"from_battle": true, "wave": 5})
	var ctx: Dictionary = _gm.call("get_state_context")
	_ok(bool(ctx.get("from_battle", false)) == true and int(ctx.get("wave", -1)) == 5,
		"§4 context 透传（from_battle=%s wave=%s）" % [str(ctx.get("from_battle")), str(ctx.get("wave"))])
	_gm.call("_transition", _gm.GameState.BATTLE)
	var ctx2: Dictionary = _gm.call("get_state_context")
	_ok(ctx2.is_empty(), "§4 无 context 转移 → 空字典")
	_gm.call("_transition", _gm.GameState.MENU)

# ========== §5 双路径等价 ==========

func _part_route_dual_path() -> void:
	print("-- §5 route 双路径 --")
	# 旧波次制：route 空 → _is_route_mode false
	_gm.route = {}
	_ok(_gm.call("_is_route_mode") == false, "§5 旧制 route 空 → _is_route_mode false")
	# 路线制：route 非空 → true
	_gm.route = {"layers": [[{"type": "battle", "wave_index": 1}]], "flags": {}}
	_ok(_gm.call("_is_route_mode") == true, "§5 路线制 route 非空 → _is_route_mode true")
	# 旧制路径：route 空 + _enter_node("battle") → BATTLE + difficulty_delta 0
	_gm.route = {}
	_gm.difficulty_delta = 99
	_gm.call("_enter_node", "battle", 3)
	_ok(_st() == _gm.GameState.BATTLE and _gm.current_wave == 3 and int(_gm.get("difficulty_delta")) == 0,
		"§5 旧制 _enter_node(battle,3) → BATTLE + wave 3 + difficulty 0")
	# 路线制路径：route 非空 + _enter_node("shop") → SHOP
	_gm.route = {"layers": [[{"type": "shop", "wave_index": 0}]], "flags": {"difficulty_delta": 1}}
	_gm.call("_enter_node", "shop", 0)
	_ok(_st() == _gm.GameState.SHOP, "§5 路线制 _enter_node(shop) → SHOP")
	_gm.call("_transition", _gm.GameState.MENU)
	# start_game 双路径（F3-A 曾反转条件，day14_15 §5 暴露——此处固化防回归）
	_gm.route_enabled = false
	_gm.route = {}
	_gm.call("start_game")
	_ok(_st() == _gm.GameState.BATTLE, "§5 旧制 start_game → BATTLE")
	_gm.call("reset")
	_gm.route_enabled = true
	_gm.route = {}
	_gm.call("start_game")
	_ok(_st() == _gm.GameState.ROUTE_SELECT, "§5 路线制 start_game → ROUTE_SELECT")
	_gm.call("reset")

# ========== 断言 ==========

func _ok(cond: bool, label: String) -> void:
	if cond:
		_checked += 1
		print("  PASS  %s" % label)
	else:
		_fail(label)

func _fail(msg: String) -> void:
	_failures += 1
	print("  FAIL  %s" % msg)

func _report() -> void:
	print("=== Day30-F3 状态流 result: %d checked, %d failures ===" % [_checked, _failures])
