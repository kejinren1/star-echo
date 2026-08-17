## Day31 全路径 Boss 链探针 v3：从第 1 关真实打到第一个 Boss（用户 08-17 反馈「打完第一个 Boss 进不了关」）
## 与 v2 差异：v2 快进到层 6（绕过了第 1-5 关真实路径）；v3 从层 0 逐层真实推进
## （battle/elite=清敌判通、event=resolve、shop=close、boss=击杀），到第一个 Boss(层6) 击杀后
## 断言进入层 7（第 8 关）路线面板可点 → 继续打穿 15 层到胜利。退出码 0 = 全链通。
extends SceneTree

const ROUTE_LAYER_BOSS1: int = 6

var _gm: Node = null
var _frame: int = 0
var _sim_time: float = 0.0
var _failures: int = 0
var _checked: int = 0
var _main: Node = null
var _phase: int = 0
var _cur: int = 0          ## 当前层索引（0-based，从第 1 关开始）
var _wait_until: float = 0.0
var _checked_battle: bool = false
var _boss_killed_here: bool = false  ## 当前 boss 层已击杀标记
var _cur_pre_advanced: bool = false  ## event/shop 分支已提前 _cur+1（断言公式差异）
var _last_ok_layer: int = 0  ## 最近一次确认推进的层（重载监视）
var _stall_since: float = -1.0  ## queue 停止缩减的起始 sim（真死锁判定）
var _last_q: int = -1  ## 上次观测 queue 大小

func _initialize() -> void:
	print("=== Day31 full-path Boss chain probe v3 (start from layer 0) ===")

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
	# 重载监视：route 若被重新生成（current_layer 回退/state 回 ROUTE_SELECT）→ 记录
	if _frame > 60 and _gm.route != null and not _gm.route.is_empty():
		var cl: int = _gm.current_layer
		var st: int = _gm.current_state
		if st == 3 and cl == 0 and _phase > 2 and _last_ok_layer > 0:
			printerr("  [dbg] 场景重载疑似 frame=%d sim=%.1f _cur=%d phase=%d route_layers=%d" % [
				_frame, _sim_time, _cur, _phase, (_gm.route.get("layers", []) as Array).size()])
			_last_ok_layer = -1  # 只报一次
	match _phase:
		0:
			_phase = _load_main()
			printerr("  [dbg] phase 0->", _phase, " frame=", _frame, " sim=", _sim_time)
		1:
			_phase = _verify_route_generated()
		2:
			_phase = _advance_layer()
		3:
			_phase = _wait_spawn()
		4:
			_phase = _verify_advance()
		5:
			_phase = _verify_shop_close()
		_:
			printerr("  [dbg] quit phase", _phase, "failures", _failures, " frame=", _frame)
			quit(_failures)
			return true
	return false

# ========== 阶段 0：加载 Main（真实装配，选莱恩） ==========

func _load_main() -> int:
	root.set_meta(&"se_selected_character", "se_ren")
	# 监听游戏信号定位重载源
	if not _gm.game_started.is_connected(_on_game_started):
		_gm.game_started.connect(_on_game_started)
	if not _gm.game_over.is_connected(_on_game_over):
		_gm.game_over.connect(_on_game_over)
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	_main = main_scene.instantiate()
	root.add_child(_main)
	_wait_until = _sim_time + 3.0
	return 1

func _on_game_started() -> void:
	printerr("  [dbg] !! game_started 再次触发 frame=%d sim=%.1f cur_layer=%d" % [_frame, _sim_time, _gm.current_layer])

func _on_game_over(victory: bool) -> void:
	printerr("  [dbg] !! game_over 触发 victory=%s frame=%d sim=%.1f cur_layer=%d" % [str(victory), _frame, _sim_time, _gm.current_layer])

# ========== 阶段 1：等路线生成（GM._ready 生成 route） ==========

func _verify_route_generated() -> int:
	if _sim_time < _wait_until:
		return 1
	if _gm.route.is_empty():
		_fail("route 未生成")
		return 99
	var layers: Array = _gm.route.get("layers", [])
	_checked += 1
	if layers.size() == 15:
		print("  PASS  路线 15 层生成")
	else:
		_fail("路线层数应为 15, 实得 %d" % layers.size())
		return 99
	_checked += 1
	if str(layers[ROUTE_LAYER_BOSS1][0].get("type")) == "boss":
		print("  PASS  层 6 = 第一个 Boss 层")
	else:
		_fail("层 6 类型应为 boss, 实得 %s" % str(layers[ROUTE_LAYER_BOSS1][0].get("type")))
		return 99
	return 2

# ========== 阶段 2：进入 _cur 层节点 0，按类型处理 ==========

func _advance_layer() -> int:
	var layers: Array = _gm.route.get("layers", [])
	if _cur >= layers.size():
		_checked += 1
		if _gm.current_state == _gm.GameState.GAME_OVER and _gm.boss_killed >= 3:
			print("  PASS  全链打穿，3 Boss 击杀，胜利结算")
		else:
			_fail("打穿后状态异常: state=%s boss_killed=%d" % [str(_gm.current_state), _gm.boss_killed])
		return 99
	if _gm.current_layer != _cur:
		_fail("当前层 %d 与目标 %d 不一致（state=%s）" % [_gm.current_layer, _cur, str(_gm.current_state)])
		return 99
	var node: Dictionary = layers[_cur][0]
	var ntype: String = str(node.get("type"))
	_checked_battle = false
	_boss_killed_here = false
	print("  层 %d（第 %d 关）: 选节点 %s →" % [_cur, _cur + 1, ntype], "")
	_gm.select_route_node(0)
	match ntype:
		"event":
			var epanel: Node = _gm.get("_event_panel")
			if epanel == null or not is_instance_valid(epanel):
				_fail("第 %d 关 event 面板未弹出" % (_cur + 1))
				return 99
			epanel.call("_on_choice_pressed", "A")
			_cur += 1
			_cur_pre_advanced = true
			_wait_until = _sim_time + 1.5
			return 4
		"shop":
			_gm.close_shop()
			_cur += 1
			_cur_pre_advanced = true
			_wait_until = _sim_time + 1.5
			return 4
		"battle", "elite", "boss":
			_cur_pre_advanced = false
			_wait_until = _sim_time + 4.0
			return 3
		_:
			_fail("未知节点类型 %s" % ntype)
			return 99

# ========== 阶段 3：战斗/Boss 层等待生成 + 击杀清场 ==========

func _heal_player() -> void:
	if _gm.player != null and is_instance_valid(_gm.player):
		_gm.player.call("heal", 99999.0)

func _wait_spawn() -> int:
	_heal_player()
	# 升级面板弹出（玩家杀敌升级触发）→ 自动点第一项恢复暂停（真实玩家会选）
	if paused:
		var lp: Node = _gm.get("_level_up_panel")
		if lp != null and is_instance_valid(lp):
			var btns: Variant = lp.get("option_buttons")
			if btns != null and (btns as Array).size() > 0:
				(btns as Array)[0].pressed.emit()
				printerr("  [dbg] 自动选择升级项（恢复暂停）frame=%d" % _frame)
		return 3
	var container: Node = _gm.enemies_container
	var layers: Array = _gm.route.get("layers", [])
	var ntype: String = str(layers[_cur][0].get("type"))
	# 观测 spawner 推进（每 5 帧打印一次，直到生成完）
	if _frame % 5 == 0 and _frame > 60:
		var sq: int = 0
		if _gm.enemy_spawner.get("spawn_queue") != null:
			sq = (_gm.enemy_spawner.get("spawn_queue") as Array).size()
		var st: float = -1.0
		if _gm.enemy_spawner.get("_spawn_timer") != null:
			st = float(_gm.enemy_spawner.get("_spawn_timer"))
		printerr("  [obs] frame=%d sim=%.1f queue=%d timer=%.2f spawning=%s state=%d layer=%d" % [
			_frame, _sim_time, sq, st, str(_gm.enemy_spawner.is_spawning()),
			int(_gm.current_state), _cur])
	if ntype == "boss":
		if _sim_time < _wait_until:
			return 3
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
		_wait_until = _sim_time + 8.0
		return 4
	# battle/elite
	if _sim_time < _wait_until:
		return 3
	var count: int = container.get_child_count() if container else -1
	if not _checked_battle:
		_checked_battle = true
		_checked += 1
		if count > 0 and _gm.current_state == _gm.GameState.BATTLE:
			print("  PASS  第 %d 关战斗正常开打（敌人 %d）" % [_cur + 1, count])
		else:
			_fail("第 %d 关战斗未正常开始（敌人 %d, state=%s）" % [_cur + 1, count, str(_gm.current_state)])
			return 99
	if container:
		for e in container.get_children():
			if is_instance_valid(e) and e.get("is_alive") == true:
				e.call("take_damage", 999999.0)
	# 杀完后再取容器数量（避免旧 count 死循环）
	count = container.get_child_count() if container else -1
	if _gm.enemy_spawner.is_spawning():
		var q: int = 0
		if _gm.enemy_spawner.get("spawn_queue") != null:
			q = (_gm.enemy_spawner.get("spawn_queue") as Array).size()
		# 真死锁判定：queue 停止缩减超过 30 游戏秒（暂停期不算——paused 时 sim 仍走但
		# spawner 冻结属正常，升级面板处理后才恢复）
		if q < _last_q:
			_stall_since = _sim_time
		_last_q = q
		if _stall_since < 0.0:
			_stall_since = _sim_time
		if _sim_time - _stall_since > 30.0 and not paused:
			var st: float = -1.0
			if _gm.enemy_spawner.get("_spawn_timer") != null:
				st = float(_gm.enemy_spawner.get("_spawn_timer"))
			_fail("第 %d 关敌人生成真死锁（queue 30s 未缩减）queue=%d spawn_timer=%.2f state=%d paused=%s" % [
				_cur + 1, q, st, int(_gm.current_state), str(paused)])
			return 99
		return 3
	if count > 0:
		return 3
	_wait_until = _sim_time + 6.0
	return 4

# ========== 阶段 4：战斗/Boss 后验证推进 ==========

func _verify_advance() -> int:
	if _sim_time < _wait_until:
		return 4
	_checked += 1
	var expected: int = _cur if _cur_pre_advanced else _cur + 1
	if _gm.current_layer == expected:
		var label: String = "Boss" if str(_gm.route.get("layers", [])[_cur if _cur_pre_advanced else maxi(0, _cur)][0].get("type")) == "boss" else "战斗"
		print("  PASS  第 %d 关（%s）打完 → 进入第 %d 层" % [_cur + 1, label, _cur + 2])
	else:
		_fail("第 %d 关打完 current_layer 应为 %d, 实得 %d（state=%s, 6 秒内未判通？）" % [
			_cur + 1, expected, _gm.current_layer, str(_gm.current_state)])
		return 99
	# 第一个 Boss 层（层 6）后专项断言：路线面板可点
	if _cur == ROUTE_LAYER_BOSS1:
		_checked += 1
		if _gm.current_state == _gm.GameState.ROUTE_SELECT:
			print("  PASS  第一个 Boss 后状态 = ROUTE_SELECT（可进下一关）")
		else:
			_fail("第一个 Boss 后状态应为 ROUTE_SELECT, 实得 %s" % str(_gm.current_state))
			return 99
		var panel: Node = _gm.get("_route_select_panel")
		var btn_count: int = 0
		if panel != null and is_instance_valid(panel) and panel.get("buttons") != null:
			btn_count = (panel.get("buttons") as Array).size()
		_checked += 1
		if btn_count >= 1:
			print("  PASS  第一个 Boss 后路线面板 %d 按钮可点" % btn_count)
		else:
			_fail("第一个 Boss 后路线面板按钮数为 0")
			return 99
	# 战斗节点后弹商店 → 关店进下一层路线；boss/event 直接进下一层
	if _gm.current_state == _gm.GameState.SHOP:
		_gm.close_shop()
		_wait_until = _sim_time + 2.0
		return 5
	if not _cur_pre_advanced:
		_cur += 1
	return 2

# ========== 阶段 5：商�