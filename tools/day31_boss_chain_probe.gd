## Day31 全场景 Boss 链探针 v2：真实 Main.tscn 装配（用户反馈「过第一个 Boss 后节点没法选」）
## 模拟：选莱恩 → 进 Main → 快进层 6（第一个 Boss）→ 杀 Boss → 断言第 8 关路线面板可点
##      → 逐层处理（event=resolve / shop=close / battle=清敌判通 / boss=击杀）
##      → 打穿 15 层到胜利。退出码 0 = 全链通；非 0 = 失败项数。
extends SceneTree

const ROUTE_LAYER_BOSS1: int = 6
const ROUTE_LAYER_BOSS2: int = 10
const ROUTE_LAYER_BOSS3: int = 14

var _gm: Node = null
var _frame: int = 0
var _sim_time: float = 0.0   ## 游戏内时间累计（headless 帧率≠60，等待一律按游戏秒）
var _failures: int = 0
var _checked: int = 0
var _main: Node = null
var _phase: int = 0
var _cur: int = 6          ## 当前要进入的层索引
var _wait_until: float = 0.0  ## 等待游戏秒阈值（防无限循环）
var _checked_battle: bool = false  ## 本层战斗已确认开始（防重复 PASS）

func _initialize() -> void:
	print("=== Day31 full Boss chain probe v2 ===")

func _process(_delta: float) -> bool:
	_frame += 1
	_sim_time += _delta
	_gm = root.get_node_or_null("GameManager")
	if _gm == null and _frame < 30:
		return false
	if _gm == null:
		_fail("GameManager autoload 不可用")
		quit(_failures)
		return true
	match _phase:
		0:
			_phase = _load_main()
		1:
			_phase = _setup_boss()
		2:
			_phase = _wait_boss_spawn()
		3:
			_phase = _kill_boss()
		4:
			_phase = _verify_after_boss()
		5:
			_phase = _wait_spawn()
		6:
			_phase = _after_advance()
		7:
			_phase = _verify_advance()
		8:
			_phase = _verify_shop_close()
		_:
			quit(_failures)
			return true
	return false

# ========== 阶段 0：加载 Main（真实装配） ==========

func _load_main() -> int:
	root.set_meta(&"se_selected_character", "se_ren")
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	_main = main_scene.instantiate()
	root.add_child(_main)
	return 1

# ========== 阶段 1：快进到第一个 Boss 层 ==========

func _setup_boss() -> int:
	var route: Dictionary = _gm.route
	if route.is_empty():
		_fail("route 未生成（route_enabled=%s）" % str(_gm.route_enabled))
		return 99
	var layers: Array = route.get("layers", [])
	_checked += 1
	if layers.size() == 15 and str(layers[ROUTE_LAYER_BOSS1][0].get("type")) == "boss":
		print("  PASS  路线 15 层, 层 6 = Boss 层")
	else:
		_fail("路线拓扑异常: layers=%d 层6类型=%s" % [layers.size(), str(layers[ROUTE_LAYER_BOSS1][0].get("type"))])
	_gm.current_layer = ROUTE_LAYER_BOSS1
	_gm.select_route_node(0)
	_wait_until = _sim_time + 6.0
	return 2

# ========== 阶段 2：等 invoker 生成 ==========

func _wait_boss_spawn() -> int:
	if _sim_time < _wait_until:
		return 2
	var container: Node = _gm.enemies_container
	var boss: Node = null
	if container:
		for e in container.get_children():
			if e.get("is_boss") == true and e.get("is_alive") == true:
				boss = e
				break
	if boss == null:
		_fail("Boss 未生成（enemies=%d, state=%s, is_boss_wave=%s）" % [
			container.get_child_count() if container else -1,
			str(_gm.current_state), str(_gm.is_boss_wave)])
		return 99
	print("  Boss1 已生成: %s hp=%.0f" % [boss.get("enemy_id"), float(boss.get("health"))])
	_checked += 1
	return 3

# ========== 阶段 3：击杀 Boss ==========

func _kill_boss() -> int:
	var container: Node = _gm.enemies_container
	for e in container.get_children():
		if e.get("is_boss") == true and e.get("is_alive") == true:
			e.call("take_damage", 999999.0)
	_wait_until = _sim_time + 6.0
	return 4

# ========== 阶段 4：断言 Boss 后进入路线选择，然后逐层打穿 ==========

func _verify_after_boss() -> int:
	if _sim_time < _wait_until:
		return 4
	var layers: Array = _gm.route.get("layers", [])
	# ① Boss 后进入第 8 层
	_checked += 1
	if _gm.current_layer == 7:
		print("  PASS  Boss1 后进入第 8 层")
	else:
		_fail("Boss1 后 current_layer 应为 7, 实得 %d" % _gm.current_layer)
		return 99
	_checked += 1
	if _gm.current_state == _gm.GameState.ROUTE_SELECT:
		print("  PASS  状态 = ROUTE_SELECT")
	else:
		_fail("状态应为 ROUTE_SELECT, 实得 %s" % str(_gm.current_state))
		return 99
	var panel: Node = _gm.get("_route_select_panel")
	var btn_count: int = 0
	if panel != null and is_instance_valid(panel) and panel.get("buttons") != null:
		btn_count = (panel.get("buttons") as Array).size()
	_checked += 1
	if btn_count == 3:
		print("  PASS  第 8 层路线面板 3 按钮可点")
	else:
		_fail("路线面板按钮数应为 3, 实得 %d" % btn_count)
		return 99
	# ② 逐层打穿：层 7 → 14
	_cur = 7
	return _advance_layer()

## 进入 _cur 层节点 0，按类型处理；返回下一阶段号
func _advance_layer() -> int:
	var layers: Array = _gm.route.get("layers", [])
	if _cur >= layers.size():
		# 全部打穿 → 应已胜利
		_checked += 1
		if _gm.current_state == _gm.GameState.GAME_OVER and _gm.boss_killed >= 3:
			print("  PASS  全链打穿，3 Boss 击杀，胜利结算")
		else:
			_fail("打穿后状态异常: state=%s boss_killed=%d" % [str(_gm.current_state), _gm.boss_killed])
		return 99
	# 检查当前是否已处于该层路线面板
	if _gm.current_layer != _cur:
		_fail("当前层 %d 与目标 %d 不一致" % [_gm.current_layer, _cur])
		return 99
	var node: Dictionary = layers[_cur][0]
	var ntype: String = str(node.get("type"))
	_checked_battle = false
	print("  层 %d（第 %d 关）: 选节点 %s →" % [_cur, _cur + 1, ntype], "")
	_gm.select_route_node(0)
	match ntype:
		"event":
			# 事件节点：模拟真实用户点击面板 A 按钮（面板自行 queue_free → 引用清除）
			var epanel: Node = _gm.get("_event_panel")
			if epanel == null or not is_instance_valid(epanel):
				_fail("第 %d 关 event 面板未弹出（_event_panel=%s）" % [_cur + 1, str(epanel)])
				return 99
			epanel.call("_on_choice_pressed", "A")
			_cur += 1
			return _after_advance()
		"shop":
			_gm.close_shop()
			_cur += 1
			return _after_advance()
		"battle", "elite":
			_wait_until = _sim_time + 4.0
			return 5
		"boss":
			_wait_until = _sim_time + 4.0
			return 5
		_:
			_fail("未知节点类型 %s" % ntype)
			return 99

## event/shop 即时推进后：等一帧让 _on_node_completed 生效，再进下一层
func _after_advance() -> int:
	if _sim_time < _wait_until:
		return 6
	_checked += 1
	if _gm.current_layer == _cur:
		print("  PASS  层 %d（%s）推进到第 %d 层" % [_cur - 1, "event/shop", _cur + 1])
	else:
		_fail("event/shop 推进异常: current_layer=%d 期望 %d" % [_gm.current_layer, _cur])
		return 99
	return _advance_layer()

# ========== 阶段 5：战斗层等生成完毕 + 击杀清场 ==========

## 无头探针保护：玩家不操作会被围殴致死 → 每帧回满血
func _heal_player() -> void:
	if _gm.player != null and is_instance_valid(_gm.player):
		_gm.player.call("heal", 99999.0)

func _wait_spawn() -> int:
	_heal_player()
	var container: Node = _gm.enemies_container
	var layers: Array = _gm.route.get("layers", [])
	var ntype: String = str(layers[_cur][0].get("type"))
	if ntype == "boss":
		if _sim_time < _wait_until:
			return 5
		var boss: Node = null
		if container:
			for e in container.get_children():
				if e.get("is_boss") == true and e.get("is_alive") == true:
					boss = e
					break
		if boss == null:
			_fail("第 %d 关 Boss 未生成（enemies=%d）" % [_cur + 1, container.get_child_count() if container else -1])
			return 99
		boss.call("take_damage", 999999.0)
		_wait_until = _sim_time + 6.0
		return 7
	# battle/elite：先等首敌出现（战斗确实开始），再等全部生成完
	if _sim_time < _wait_until:
		return 5
	var count: int = container.get_child_count() if container else -1
	if not _checked_battle:
		_checked_battle = true
		_checked += 1
		if count > 0 and _gm.current_state == _gm.GameState.BATTLE:
			print("  PASS  第 %d 关战斗正常开打（敌人 %d）" % [_cur + 1, count])
		else:
			_fail("第 %d 关战斗未正常开始（敌人 %d, state=%s）" % [_cur + 1, count, str(_gm.current_state)])
			return 99
	# 有敌人就击杀（生成中不断补刀）
	if container:
		for e in container.get_children():
			if is_instance_valid(e) and e.get("is_alive") == true:
				e.call("take_damage", 999999.0)
	# 等 spawner 生成完毕（分批生成，需 ~15-25s；安全阀防死等）
	if _gm.enemy_spawner.is_spawning():
		if _sim_time > _wait_until + 60.0:
			_fail("第 %d 关敌人生成超时（仍在生成）" % (_cur + 1))
			return 99
		return 5
	# 生成完毕且容器清空 → 最后一只 die 已触发判通；给一帧余量
	if count > 0:
		return 5
	_wait_until = _sim_time + 6.0
	return 7

# ========== 阶段 7：战斗/Boss 后验证推进 ==========

func _verify_advance() -> int:
	if _sim_time < _wait_until:
		return 7
	_checked += 1
	if _gm.current_layer == _cur + 1:
		print("  PASS  第 %d 关打完 → 进入第 %d 层" % [_cur + 1, _cur + 2])
	else:
		_fail("第 %d 关打完 current_layer 应为 %d, 实得 %d（state=%s）" % [_cur + 1, _cur + 1, _gm.current_layer, str(_gm.current_state)])
		return 99
	# 战斗节点后弹商店 → 关店进下一层路线
	if _gm.current_state == _gm.GameState.SHOP:
		_gm.close_shop()
		_wait_until = _sim_time + 2.0
		return 8
	_cur += 1
	return _advance_layer()

## 商店关闭后进入下一层路线选择
func _verify_shop_close() -> int:
	if _sim_time < _wait_until:
		return 8
	_checked += 1
	if _gm.current_state == _gm.GameState.ROUTE_SELECT:
		print("  PASS  商店关闭 → 第 %d 层路线选择" % (_cur + 2))
	else:
		_fail("商店关闭后 state 应为 ROUTE_SELECT, 实得 %s" % str(_gm.current_state))
		return 99
	_cur += 1
	return _advance_layer()

func _fail(msg: String) -> void:
	_failures += 1
	print("  FAIL  %s" % msg)
