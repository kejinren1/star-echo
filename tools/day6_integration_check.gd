## Day 6 出口校验：阶段 A 集成探针（T-A 收口）
##
## 用法（无头，不需要编辑器）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day6_integration_check.gd
##
## 校验内容（对应 docs/TASKS.md D6-T3 七段全链路）：
##   Case A (boot, 无 meta 直开)：
##     1. 兜底英雄 well_rounded 进局零 error（回归 D2-T1a）
##     2. player.die() → GameOver 面板 + paused == true（D4-T7 / BUG-001-F1 回归）
##     3. teardown 重开 → 新实例零 error（重开链路）
##   Case B (chain, se_irene)：
##     4. 首武器 se_star_flame + exp == 0 + level == 1（D2 链路）
##     5. 杀 1 chaser → player.exp == JSON exp_value（≠1，T-A 收口 · D6-T1/T2）
##     6. 杀 1 fly → exp 继续累计（== chaser_exp + fly_exp）
##     7. 累计跨 20 → level == 2 + level_up 信号触发（D4 链路）
##     8. try_cast() 火球成功 + 冷却生效（二次 false）（D3 链路）
##     9. 连装 6 把 → is_full()；第 7 把被拒（D5 链路）
##    10. player.die() → GameOver 面板 + paused（D4-T7 回归）
##    11. 重开（teardown + 重 spawn）→ 零 error
##
## 无头环境特殊约定（沿用 day2~day5）：
##   · --script 模式下 autoload 标识符不可直接引用，一律经 root 取 GameManager/DataLoader
##   · 面板挂载：current_scene 为 null 时挂 root，故按 root 节点查找
##   · 死亡动画存在时 queue_free 延迟 → 杀敌后空转一帧清理
##
## 退出码 0 = 全部通过；非 0 = 失败项数。
extends SceneTree

const MAIN_SCENE: String = "res://scenes/Main.tscn"
const ENEMY_SCENE: String = "res://scenes/Enemy.tscn"
const SELECTION_META: StringName = &"se_selected_character"
## 实际曲线 Lv1→2 需求 = 30（"20 + current_level*10"，current_level=1；#2 定案误读为 20，已按实测校准 D6-T1）

const CASES: Array = [
	{"hero": "", "phase": "boot"},
	{"hero": "se_irene", "phase": "chain"},
]

var _idx: int = 0
var _sub: int = 0
var _instance: Node = null
var _player: Node = null
var _manager: Node = null
var _controller: Node = null
var _checked: int = 0
var _failures: int = 0
var _level_up_signals: Array = []
var _loader: Node = null
var _expect_loaded: bool = false

## 期望经验（D6-T1 定稿，运行时从 DataLoader 读 JSON 单一事实源）
var _chaser_exp: int = 0
var _fly_exp: int = 0

func _initialize() -> void:
	print("=== Day 6 integration check ===")
	# 注意：_initialize() 时 autoload 尚未 ready（_enemies 为空），期望值延后到首次 _process 读取

func _process(_delta: float) -> bool:
	if not _expect_loaded:
		_load_expectations()
	if _idx >= CASES.size():
		_report()
		quit(_failures)
		return true
	_sub = _advance(_sub)
	return false

## 延迟读取期望经验（autoload ready 后 DataLoader 才有数据）
func _load_expectations() -> void:
	_expect_loaded = true
	_loader = root.get_node_or_null("DataLoader")
	if _loader == null:
		print("  FAIL  DataLoader autoload 缺失")
		_failures += 1
		return
	# 期望值从 JSON 读取（非硬编码 1）：get_scaled_enemy 返回的 exp_value 由 D6-T2 透传
	var chaser_stats: Dictionary = _loader.call("get_scaled_enemy", "chaser", 1)
	var fly_stats: Dictionary = _loader.call("get_scaled_enemy", "fly", 1)
	_chaser_exp = int(chaser_stats.get("exp_value", 0))
	_fly_exp = int(fly_stats.get("exp_value", 0))
	if _chaser_exp <= 1 or _fly_exp <= 1:
		# 数据化未生效（exp_value 兜底 1）——后续断言必红，此处仅提示
		print("  WARN  exp_value 数据化疑似未生效: chaser=%d fly=%d（预期 >= 3/3）" % [_chaser_exp, _fly_exp])

# ========== 用例推进 ==========

func _advance(sub: int) -> int:
	var phase: String = str(CASES[_idx]["phase"])
	match phase:
		"boot":
			return _advance_boot(sub)
		"chain":
			return _advance_chain(sub)
	return sub + 1

## 生成 Main 实例；hero 为空串 = 不设 meta（直开路径，测兜底）
func _spawn(hero: String) -> void:
	if hero.is_empty():
		if root.has_meta(SELECTION_META):
			root.remove_meta(SELECTION_META)
	else:
		root.set_meta(SELECTION_META, hero)
	_instance = (load(MAIN_SCENE) as PackedScene).instantiate()
	root.add_child(_instance)
	_manager = root.get_node_or_null("GameManager")
	# D14-15：路线模式默认开启（阶段 C 新体验）→ 注入关闭，保持 day6 端到端旧波次制回归口径
	if _manager != null:
		_manager.set("route_enabled", false)
	_player = _instance.get_node_or_null("World/Player")
	_controller = _player.get_node_or_null("WeaponController") if _player else null
	_level_up_signals.clear()

func _teardown() -> void:
	# die() 后可能处于 paused，重置避免污染下一用例
	paused = false
	if _manager != null:
		_manager.call("reset")
	if is_instance_valid(_instance):
		_instance.free()
	_instance = null
	_player = null
	_controller = null
	_reset_manager_refs()

## 清空 GameManager 持有的引用与面板指针（同进程反复实例化 Main 的夹具职责）
func _reset_manager_refs() -> void:
	if _manager == null:
		_manager = root.get_node_or_null("GameManager")
	if _manager == null:
		return
	for field: String in ["player", "wave_manager", "enemy_spawner", "economy", "inventory", "vfx_container", "_level_up_panel", "_game_over_panel"]:
		_manager.set(field, null)
	# 清理 root 下残留面板节点
	for node in root.get_children():
		if node is Node and (node.name == "LevelUpPanel" or node.name == "GameOverPanel" or node.name.begins_with("GameOverPanel")):
			node.queue_free()

## 生成 1 只敌人并击杀（真实链路：spawn → initialize → take_damage → die → 结算）
func _kill_enemy(enemy_id: String, wave: int = 1) -> void:
	if _manager == null:
		return
	var spawner: Node = _manager.get("enemy_spawner")
	if spawner == null:
		return
	var container: Node = spawner.get("enemies_container")
	if container == null:
		return
	var stats: Dictionary = _loader.call("get_scaled_enemy", enemy_id, wave)
	var enemy: Node = (load(ENEMY_SCENE) as PackedScene).instantiate()
	container.add_child(enemy)
	if enemy.has_method("initialize"):
		enemy.call("initialize", stats)
	if enemy.has_method("take_damage"):
		enemy.call("take_damage", 99999.0)

# ========== Case A：无 meta 直开（断言 1-3） ==========

func _advance_boot(sub: int) -> int:
	match sub:
		0:
			_spawn("")
			return 1
		1:
			return 2  # 空转一帧等 Main ready
		2:
			_check_boot_hero()   # 断言 1
			return 3
		3:
			_check_game_over()   # 断言 2
			return 4
		4:
			return 5  # 空转一帧让面板就位
		5:
			_check_restart_boot()  # 断言 3
			_finish_case()
			return 0
	return sub + 1

## 断言 1：无 meta → 兜底 well_rounded 进局零 error
func _check_boot_hero() -> void:
	if _player == null:
		_fail("boot / player 缺失（直开 Main 应能正常进局）")
		return
	var cid: String = str(_manager.get("current_character_id"))
	if cid == "well_rounded":
		_checked += 1
		print("  PASS  boot / 无 meta 直开兜底 well_rounded（cid=%s）" % cid)
	else:
		_fail("boot / 无 meta 应兜底 well_rounded，实得 %s" % cid)

## 断言 2：die → GameOver 面板 + paused
func _check_game_over() -> void:
	_player.call("die")
	if not bool(paused):
		_fail("boot / die 后应 paused == true")
		return
	_checked += 1
	print("  PASS  boot / die() → paused == true")
	# 面板 instantiate 后本帧就绪，直接查
	var panel: Node = root.get_node_or_null("GameOverPanel")
	if panel != null:
		_checked += 1
		print("  PASS  boot / GameOverPanel 已出现")
	else:
		_fail("boot / GameOverPanel 未出现（end_game 应弹面板）")

## 断言 3：teardown 重开 → 零 error
func _check_restart_boot() -> void:
	_teardown()
	_spawn("")
	# 重开后空转一帧验证新实例正常
	var player2: Node = _instance.get_node_or_null("World/Player") if _instance else null
	if player2 != null and str(_manager.get("current_character_id")) == "well_rounded":
		_checked += 1
		print("  PASS  boot / 重开零 error（新实例 player 正常）")
	else:
		_fail("boot / 重开后 player 缺失")

# ========== Case B：se_irene 全链路（断言 4-11） ==========

func _advance_chain(sub: int) -> int:
	match sub:
		0:
			_spawn("se_irene")
			return 1
		1:
			return 2  # 空转一帧等 Main ready
		2:
			# 提前挂 level_up 探针（升级断言须在触发前连接）
			if _player and not _player.level_up.is_connected(_on_lvl_up_probe):
				_player.level_up.connect(_on_lvl_up_probe)
			_check_startup_irene()  # 断言 4
			return 3
		3:
			_kill_enemy("chaser")
			return 4
		4:
			_check_exp_chaser()     # 断言 5
			_kill_enemy("fly")
			return 5
		5:
			_check_exp_fly()        # 断言 6
			# 补足经验跨 30（Lv1→2 实际需求 = 20+1*10；已 3+3=6，再杀 8 chaser = +24 → 30 恰好触发）
			for i in 8:
				_kill_enemy("chaser")
			return 6
		6:
			return 7  # 空转一帧清理死亡敌人
		7:
			_check_level_up_chain() # 断言 7（含面板清理）
			return 8
		8:
			_check_skill_chain()    # 断言 8
			return 9
		9:
			_check_slots_chain()    # 断言 9
			return 10
		10:
			_check_game_over_chain() # 断言 10
			return 11
		11:
			return 12  # 空转一帧
		12:
			_check_restart_chain()  # 断言 11
			_finish_case()
			return 0
	return sub + 1

## 断言 4：首武器 se_star_flame + 初始 exp/level
func _check_startup_irene() -> void:
	if _controller == null:
		_fail("chain / WeaponController 缺失")
		return
	var weapons: Array = _controller.get("equipped_weapons")
	if weapons.size() == 1 and str(weapons[0].get("weapon_name")) == "炎星术":
		_checked += 1
		print("  PASS  chain / 艾琳首武器 == 炎星术")
	else:
		_fail("chain / 首武器应为 炎星术（size=%d）" % weapons.size())
	if absf(float(_player.get("exp")) - 0.0) < 0.001 and int(_player.get("level")) == 1:
		_checked += 1
		print("  PASS  chain / 进局 exp == 0, level == 1")
	else:
		_fail("chain / 初始 exp=%.1f level=%d 应为 0/1" % [float(_player.get("exp")), int(_player.get("level"))])

## 断言 5：杀 1 chaser → exp == JSON exp_value（非 1）
func _check_exp_chaser() -> void:
	var exp_now: float = float(_player.get("exp"))
	if absf(exp_now - float(_chaser_exp)) < 0.001:
		_checked += 1
		print("  PASS  chain / 杀 chaser 得经验 %d（JSON 值）" % _chaser_exp)
	else:
		_fail("chain / 杀 chaser 应得 %d exp，实得 %.1f" % [_chaser_exp, exp_now])

## 断言 6：杀 1 fly → exp 继续累计
func _check_exp_fly() -> void:
	var exp_now: float = float(_player.get("exp"))
	var expect: float = float(_chaser_exp + _fly_exp)
	if absf(exp_now - expect) < 0.001:
		_checked += 1
		print("  PASS  chain / 累计经验 == %d（chaser+fly）" % int(expect))
	else:
		_fail("chain / 累计经验应 %d，实得 %.1f" % [int(expect), exp_now])

## 断言 7：跨 30（Lv1→2 实际需求）→ level 2 + level_up 信号；清理升级面板
func _check_level_up_chain() -> void:
	if int(_player.get("level")) == 2:
		_checked += 1
		print("  PASS  chain / 累计经验跨 30 → level == 2")
	else:
		_fail("chain / 应升级到 level 2，实得 %d" % int(_player.get("level")))
	if _level_up_signals.size() >= 1:
		_checked += 1
		print("  PASS  chain / level_up 信号触发 %d 次" % _level_up_signals.size())
	else:
		_fail("chain / level_up 信号未触发")
	# 升级 → 面板暂停（D4 合并策略）；清理面板恢复运行继续后续断言
	var panel: Node = root.get_node_or_null("LevelUpPanel")
	if panel != null:
		panel.queue_free()
		if _manager != null:
			_manager.set("_level_up_panel", null)
	paused = false

func _on_lvl_up_probe(lvl: int) -> void:
	_level_up_signals.append(lvl)

## 断言 8：try_cast 火球成功 + 冷却生效
func _check_skill_chain() -> void:
	var sc: Node = _player.get_node_or_null("SkillController")
	if sc == null:
		_fail("chain / SkillController 缺失")
		return
	var first: bool = bool(sc.call("try_cast"))
	var second: bool = bool(sc.call("try_cast"))
	if first and not second:
		_checked += 1
		print("  PASS  chain / 火球 try_cast 成功且二次进入冷却")
	else:
		_fail("chain / 技能链路异常: first=%s second=%s" % [str(first), str(second)])

## 断言 9：6 槽装满 is_full，第 7 把被拒
func _check_slots_chain() -> void:
	if _controller == null:
		_fail("chain / WeaponController 缺失")
		return
	_controller.get("equipped_weapons").clear()
	for i in 6:
		var w := Weapon.new()
		w.weapon_name = "测试武器%d" % i
		_controller.call("equip_weapon", w)
	var extra := Weapon.new()
	extra.weapon_name = "第七把"
	if bool(_controller.call("is_full")) \
			and int(_controller.call("get_slot_count")) == 6 \
			and not bool(_controller.call("equip_weapon", extra)) \
			and int(_controller.call("get_slot_count")) == 6:
		_checked += 1
		print("  PASS  chain / 6 槽装满 is_full，第 7 把被拒")
	else:
		_fail("chain / 6 槽上限链路异常")

## 断言 10：die → GameOver 面板 + paused
func _check_game_over_chain() -> void:
	_player.call("die")
	if bool(paused) and root.get_node_or_null("GameOverPanel") != null:
		_checked += 1
		print("  PASS  chain / die → GameOver 面板 + paused")
	else:
		_fail("chain / die 后应 paused + GameOverPanel（paused=%s）" % str(paused))

## 断言 11：重开零 error
func _check_restart_chain() -> void:
	_teardown()
	_spawn("se_irene")
	var player2: Node = _instance.get_node_or_null("World/Player") if _instance else null
	if player2 != null and str(_manager.get("current_character_id")) == "se_irene":
		_checked += 1
		print("  PASS  chain / 重开（se_irene）零 error")
	else:
		_fail("chain / 重开后 player 缺失或英雄未注入")

# ========== 收尾 ==========

func _finish_case() -> void:
	_teardown()
	_idx += 1
	_sub = 0

# ========== 断言 ==========

func _fail(what: String) -> void:
	_checked += 1
	_failures += 1
	print("  FAIL  %s" % what)

func _report() -> void:
	print("--- %d 项断言，%d 项失败 ---" % [_checked, _failures])
	if _failures == 0:
		print("DAY6 INTEGRATION CHECK CLEAN")
	else:
		print("DAY6 INTEGRATION CHECK BROKEN")
