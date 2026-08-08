## Day 4 出口校验：经验 / 升级 / Build 初版（D4-T1~T8 收口）
##
## 用法（无头，不需要编辑器）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day4_level_check.gd
##
## 校验内容（对应 docs/TASKS.md D4-EXIT 十项断言）：
##   1. 击杀 1 敌 → player.exp == exp_value（enemy 数据 exp_value:1）
##   2. 经验曲线：0→1 级需求 20、1→2 级需求 30（`20 + current_level * 10`）
##   3. 升级触发 level_up 信号 + 面板出现 + get_tree().paused == true
##   4. 选「攻击 +10%」→ damage_multiplier == 1.1；真实按钮点击后面板消失、游戏恢复
##   5. 选「范围 +8%」→ range_multiplier == 1.08（range 口径定案验证）
##   6. life_steal = 0.2 命中 10 伤害 → 回 2 血
##   7. 诺亚释放 → World 下 Turret == 3、到期（15s）后归 0（Day 3 顺延断言 3 收口）
##   8. 连升多级（+90 经验）信号次数与级数正确；well_rounded 直升不崩
##   9. player.die() → GameOver 面板出现 + paused == true + 标题「你已阵亡」；点重开零 error
##  10. 波次清空进商店 → enemies_container.get_child_count() == 0（BUG-001-F2 收口）
##
## 无头环境特殊约定（沿用 day2/day3）：
##   · --script 模式下 autoload 标识符不可直接引用，一律经 root 取 GameManager/DataLoader
##   · 面板挂载：current_scene 为 null 时 GameManager._add_to_ui_layer 挂 root，故按 root 节点查找
##   · 炮台到期用「手动调 turret._process(16.0)」加速模拟（真实逻辑与引擎回调一致）
##
## 退出码 0 = 全部通过；非 0 = 失败项数。
extends SceneTree

const MAIN_SCENE: String = "res://scenes/Main.tscn"
const ENEMY_SCENE: String = "res://scenes/Enemy.tscn"
const PROJECTILE_SCENE: String = "res://scenes/Projectile.tscn"
const SELECTION_META: StringName = &"se_selected_character"
const EPSILON: float = 0.01

const CASES: Array = [
	{"hero": "se_irene", "phase": "irene"},
	{"hero": "se_noa", "phase": "noa"},
	{"hero": "well_rounded", "phase": "wr"},
]

var _idx: int = 0
var _sub: int = 0                # 用例内阶段
var _instance: Node = null
var _player: Node = null
var _manager: Node = null
var _spawner: Node = null
var _level_up_count: int = 0     # 连升信号计数（Case A）
var _panel: Node = null
var _checked: int = 0
var _failures: int = 0

func _initialize() -> void:
	print("=== Day 4 level / build pipeline check ===")

func _process(_delta: float) -> bool:
	if _idx >= CASES.size():
		_report()
		quit(_failures)
		return true
	_sub = _advance(_sub)
	return false

# ========== 用例推进 ==========

func _advance(sub: int) -> int:
	var phase: String = str(CASES[_idx]["phase"])
	match phase:
		"irene":
			return _advance_irene(sub)
		"noa":
			return _advance_noa(sub)
		"wr":
			return _advance_wr(sub)
	return sub + 1

func _spawn() -> void:
	var hero: String = str(CASES[_idx]["hero"])
	root.set_meta(SELECTION_META, hero)
	# F-22/F-23 轮（2026-08-08）局部增益隔离：main._apply_meta_bonus 实时读
	# GameManager.meta_progress，真实存档（用户游玩产生，含研究 ×1.05）会污染数值断言
	# （期望 1.100 实得 1.155）；白盒重置默认（不写盘——探针不触发 end_game(victory)，真实存档安全）
	var gm: Node = root.get_node_or_null("GameManager")
	if gm:
		gm.set("meta_progress", gm.call("_default_meta"))
	_instance = (load(MAIN_SCENE) as PackedScene).instantiate()
	root.add_child(_instance)
	_manager = root.get_node_or_null("GameManager")
	_player = _instance.get_node_or_null("World/Player")
	_spawner = _manager.get("enemy_spawner") if _manager else null

func _teardown() -> void:
	if is_instance_valid(_instance):
		_instance.free()
	_instance = null
	_player = null
	_spawner = null
	_panel = null
	_reset_manager_refs()

## 同进程反复实例化 Main 的测试夹具职责：清空 GameManager 持有的引用与面板指针
func _reset_manager_refs() -> void:
	if _manager == null:
		_manager = root.get_node_or_null("GameManager")
	if _manager == null:
		return
	for field: String in ["player", "wave_manager", "enemy_spawner", "economy", "inventory", "vfx_container", "_level_up_panel", "_game_over_panel"]:
		_manager.set(field, null)

# ========== Case A：se_irene（断言 1-6、8a） ==========

func _advance_irene(sub: int) -> int:
	match sub:
		0:
			_spawn()
			# 连升信号计数
			_player.level_up.connect(func(_n: int) -> void: _level_up_count += 1)
			return 1
		1:
			return 2  # 空转一帧等 Main ready
		2:
			_check_kill_exp()          # 断言 1
			return 3
		3:
			_check_xp_curve()          # 断言 2
			return 4
		4:
			_check_level_up_panel()    # 断言 3
			return 5
		5:
			_check_panel_apply()       # 断言 4 + 5（白盒 + 真实按钮）
			return 6
		6:
			# 等面板释放
			return 7
		7:
			_check_multi_levelup()     # 断言 8a
			return 8
		8:
			_check_life_steal()        # 断言 6
			_finish_case()
			return 0
	return sub + 1

## 断言 1：击杀 1 敌 → exp == exp_value（1）
func _check_kill_exp() -> void:
	var container: Node = _spawner.get("enemies_container") if _spawner else null
	if container == null:
		_fail("irene / enemies_container 缺失")
		return
	var enemy: Node = (load(ENEMY_SCENE) as PackedScene).instantiate()
	container.add_child(enemy)
	# 默认 chaser：exp_value = 1（Enemy.tscn 默认导出值，initialize 不覆盖）
	enemy.die()
	var exp_now: float = float(_player.get("exp"))
	if absf(exp_now - 1.0) <= EPSILON:
		_checked += 1
		print("  PASS  irene / 击杀 1 敌 → exp = %.1f" % exp_now)
	else:
		_fail("irene / 击杀后 exp 应为 1，实得 %.1f" % exp_now)

## 断言 2：经验曲线 0→1 需 20、1→2 需 30（`20 + current_level * 10`）
func _check_xp_curve() -> void:
	# 起始 level=1 → 1→2 需求 = 20 + 1*10 = 30
	var need_l1: float = float(_player.call("get_xp_to_next_level"))
	_assert_near("irene / 1→2 级需求", need_l1, 30.0)
	# 临时 level=0 → 0→1 需求 = 20 + 0*10 = 20（验证表达式绑定 current_level）
	_player.set("level", 0)
	var need_l0: float = float(_player.call("get_xp_to_next_level"))
	_player.set("level", 1)
	_assert_near("irene / 0→1 级需求", need_l0, 20.0)

## 断言 3：gain_exp(30) 升级 → level_up 信号 + LevelUpPanel 出现 + paused == true
func _check_level_up_panel() -> void:
	var count_before: int = _level_up_count
	_player.call("gain_exp", 30.0)
	if _level_up_count == count_before + 1:
		_checked += 1
		print("  PASS  irene / level_up 信号触发 1 次")
	else:
		_fail("irene / level_up 信号次数 %d（期望 %d）" % [_level_up_count - count_before, 1])
	_panel = root.get_node_or_null("LevelUpPanel")
	if _panel != null:
		_checked += 1
		print("  PASS  irene / LevelUpPanel 已出现")
	else:
		_fail("irene / LevelUpPanel 未出现")
	if bool(paused):
		_checked += 1
		print("  PASS  irene / get_tree().paused == true")
	else:
		_fail("irene / 升级后面板未暂停游戏")

## 断言 4 + 5：白盒验证攻击/范围口径 + 真实按钮点击恢复
func _check_panel_apply() -> void:
	if _panel == null or not is_instance_valid(_panel):
		_fail("irene / 面板已失效，跳过强化断言")
		return
	# 断言 4：攻击 +10%（percent → ×1.10 乘算）
	_panel.call("_apply_option", {"label": "攻击 +10%", "stat": "damage", "mode": "percent", "value": 10})
	_assert_near("irene / 攻击 +10% → damage_multiplier", float(_player.get("damage_multiplier")), 1.1)
	# 断言 5：范围 +8%（percent → range_multiplier ×1.08，口径定案）
	_panel.call("_apply_option", {"label": "范围 +8%", "stat": "range", "mode": "percent", "value": 8})
	_assert_near("irene / 范围 +8% → range_multiplier", float(_player.get("range_multiplier")), 1.08)
	# 真实交互路径：点击第 0 个按钮 → paused 恢复 false + 面板 queue_free
	_panel.call("_on_option_pressed", 0)
	if bool(paused):
		_fail("irene / 选择后面板未恢复游戏（paused 仍 true）")
	else:
		_checked += 1
		print("  PASS  irene / 选择后游戏恢复（paused = false）")

## 断言 8a：连升多级（+90 经验，level 2→4）信号次数与级数正确
func _check_multi_levelup() -> void:
	var count_before: int = _level_up_count
	var level_before: int = int(_player.get("level"))
	_player.call("gain_exp", 90.0)
	var level_after: int = int(_player.get("level"))
	if level_after == level_before + 2:
		_checked += 1
		print("  PASS  irene / 连升多级 level %d -> %d（+2 级）" % [level_before, level_after])
	else:
		_fail("irene / +90 经验应连升 2 级（%d -> %d）" % [level_before, level_after])
	if _level_up_count == count_before + 2:
		_checked += 1
		print("  PASS  irene / level_up 信号连发 2 次")
	else:
		_fail("irene / 连升信号次数 %d（期望 2）" % [_level_up_count - count_before])

## 断言 6：life_steal = 0.2 命中 10 伤害 → 回 2 血
func _check_life_steal() -> void:
	_player.set("life_steal", 0.2)
	_player.set("health", 50.0)
	var proj: Node = (load(PROJECTILE_SCENE) as PackedScene).instantiate()
	root.add_child(proj)
	proj.call("apply_life_steal", 10.0)
	var hp_now: float = float(_player.get("health"))
	if absf(hp_now - 52.0) <= EPSILON:
		_checked += 1
		print("  PASS  irene / life_steal 0.2 × 10 伤害 → 回血至 %.1f" % hp_now)
	else:
		_fail("irene / 吸血回血失败：health 应 52，实得 %.1f" % hp_now)
	if is_instance_valid(proj):
		proj.queue_free()

# ========== Case B：se_noa（断言 7） ==========

func _advance_noa(sub: int) -> int:
	match sub:
		0:
			_spawn()
			return 1
		1:
			return 2
		2:
			var skill: Node = _player.get_node_or_null("SkillController")
			var cast_ok: bool = bool(skill.call("try_cast"))
			if cast_ok:
				_checked += 1
				print("  PASS  noa / 紧急部署 try_cast = true")
			else:
				_fail("noa / 紧急部署 try_cast 应为 true")
			return 3
		3:
			var turret_count: int = _count_turrets()
			if turret_count == 3:
				_checked += 1
				print("  PASS  noa / World 下 Turret == 3（summon 2 + passive 1）")
			else:
				_fail("noa / Turret 数应为 3，实得 %d" % turret_count)
			return 4
		4:
			# 手动推进 16s（> duration 15s）加速到期验证；queue_free 延迟到帧尾
			for turret: Node2D in _world_turrets():
				turret.call("_process", 16.0)
			return 5
		5:
			if _count_turrets() == 0:
				_checked += 1
				print("  PASS  noa / 15s 到期后 Turret 归 0")
			else:
				_fail("noa / 到期后 Turret 未清空（剩 %d）" % _count_turrets())
			_finish_case()
			return 0
	return sub + 1

func _world_turrets() -> Array[Node2D]:
	var world: Node = _instance.get_node_or_null("World")
	if world == null:
		return []
	var result: Array[Node2D] = []
	for child in world.get_children():
		# Godot 对重名子节点自动改名（Turret / @Node2D@17 ...），按脚本路径识别最可靠
		if child is Node2D and child.get_script() \
				and str(child.get_script().resource_path).ends_with("turret.gd"):
			result.append(child)
	return result

func _count_turrets() -> int:
	return _world_turrets().size()

# ========== Case C：well_rounded（断言 8b、9、10） ==========

func _advance_wr(sub: int) -> int:
	match sub:
		0:
			_spawn()
			return 1
		1:
			return 2
		2:
			# 断言 8b：well_rounded 直升大量经验不崩（level > 1）
			_player.call("gain_exp", 200.0)
			if int(_player.get("level")) > 1:
				_checked += 1
				print("  PASS  wr / well_rounded 直升不崩（level = %d）" % int(_player.get("level")))
			else:
				_fail("wr / well_rounded 直升后 level 仍为 1")
			return 3
		3:
			return 4  # 空转一帧（面板弹出）
		4:
			_setup_wave_cleanup()      # 摆 2 敌 + 触发 on_wave_cleared
			return 5
		5:
			return 6  # 空转一帧：queue_free 生效
		6:
			_check_wave_cleanup()      # 断言 10
			return 7
		7:
			_check_game_over()         # 断言 9
			_finish_case()
			return 0
	return sub + 1

## 断言 10（BUG-001-F2）：波次清空进商店 → enemies_container == 0
func _setup_wave_cleanup() -> void:
	var container: Node = _spawner.get("enemies_container") if _spawner else null
	if container == null:
		_fail("wr / enemies_container 缺失")
		return
	for i in 2:
		var enemy: Node = (load(ENEMY_SCENE) as PackedScene).instantiate()
		container.add_child(enemy)
	_manager.call("on_wave_cleared")

func _check_wave_cleanup() -> void:
	var container: Node = _spawner.get("enemies_container") if _spawner else null
	if container == null:
		_fail("wr / enemies_container 缺失")
		return
	if container.get_child_count() == 0:
		_checked += 1
		print("  PASS  wr / 波次切换后敌人清空（BUG-001-F2 收口）")
	else:
		_fail("wr / 波次切换后残留 %d 敌" % container.get_child_count())

## 断言 9（BUG-001-F1）：player.die() → GameOver 面板 + paused + 标题；点重开零 error
func _check_game_over() -> void:
	# 若上一断言已清空敌人则先确认（在 _advance 的帧间隙处理）
	_player.call("die")
	var panel: Node = root.get_node_or_null("GameOverPanel")
	if panel != null:
		_checked += 1
		print("  PASS  wr / GameOverPanel 已出现")
	else:
		_fail("wr / GameOverPanel 未出现")
	if bool(paused):
		_checked += 1
		print("  PASS  wr / die 后 paused == true")
	else:
		_fail("wr / die 后未暂停")
	var title: Label = panel.get_node_or_null("CenterContainer/Panel/Margin/VBox/Title") if panel else null
	if title and title.text == "你已阵亡":
		_checked += 1
		print("  PASS  wr / 标题 == 你已阵亡")
	else:
		_fail("wr / 标题应为「你已阵亡」，实得 %s" % (title.text if title else "<null>"))
	# 点重开（current_scene 为 null 的测试环境 → 仅解除暂停+释放，零 error）
	var restart: TextureButton = panel.get_node_or_null("CenterContainer/Panel/Margin/VBox/RestartButton") if panel else null
	if restart:
		restart.pressed.emit()
	if bool(paused):
		_fail("wr / 点重开后仍暂停")
	else:
		_checked += 1
		print("  PASS  wr / 点重开 → 解除暂停（场景重载零 error）")

# ========== 收尾 ==========

func _finish_case() -> void:
	_teardown()
	_idx += 1
	_sub = 0
	_level_up_count = 0

# ========== 断言 ==========

func _assert_near(what: String, actual: float, expected: float) -> void:
	_checked += 1
	if absf(actual - expected) <= EPSILON:
		print("  PASS  %s = %.3f" % [what, actual])
	else:
		_failures += 1
		print("  FAIL  %s : 期望 %.3f，实得 %.3f" % [what, expected, actual])

func _fail(what: String) -> void:
	_checked += 1
	_failures += 1
	print("  FAIL  %s" % what)

func _report() -> void:
	print("--- %d 项断言，%d 项失败 ---" % [_checked, _failures])
	if _failures == 0:
		print("DAY4 LEVEL CHECK CLEAN")
	else:
		print("DAY4 LEVEL CHECK BROKEN")
