## Day 3 出口校验：主动技能系统（D3-T1/T2/T2b/T3/T5/T7）
##
## 用法（无头，不需要编辑器）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day3_skill_check.gd
##
## 校验内容（对应 docs/TASKS.md D3-EXIT P0 收口口径，断言 1·2·4·5·6）：
##   1. 三英雄 SkillController._cd_total 分别 == 8.0 / 12.0 / 10.0
##   2. try_cast() 首次返回 true，紧接第二次返回 false（冷却生效）
##   4. 莱恩释放后 attack_speed == 基线 × 1.5，且到期精确还原（误差 < 0.001）
##   5. 艾琳火球爆炸后半径内敌人 health 下降，且 has_status("fire") == true
##   6. well_rounded（无 skill）零 error、can_cast() 恒 false
## 断言 3（Turret 数 == 3）随 D3-T4 顺延 Day 4，本日不判。
##
## 无头环境特殊约定：
##   · --script 模式下 autoload 标识符不可直接引用，一律经 root 取 GameManager
##   · headless 下 get_global_mouse_position() 恒返回 (0,0)：玩家在 (320,180) 时
##     该方向会被 `_get_aim_direction()` 当作「有效鼠标方向」。故艾琳用例的敌人
##     必须摆在「玩家朝鼠标 (0,0) 方向 60px」处，火球才会命中。
##
## 退出码 0 = 全部通过；非 0 = 失败项数。
extends SceneTree

const MAIN_SCENE: String = "res://scenes/Main.tscn"
const ENEMY_SCENE: String = "res://scenes/Enemy.tscn"
const SELECTION_META: StringName = &"se_selected_character"
const EPSILON: float = 0.01

const CASES: Array = [
	{"hero": "se_irene", "expect_cd": 8.0, "special": "fireball"},
	{"hero": "se_noa", "expect_cd": 12.0, "special": "noa"},
	{"hero": "se_ren", "expect_cd": 10.0, "special": "blade"},
	{"hero": "well_rounded", "expect_cd": 0.0, "special": "noskill"},
]

var _idx: int = 0
var _sub: int = 0              # 用例内阶段
var _elapsed: float = 0.0      # 阶段计时
var _armed: bool = false       # 特殊动作是否已触发
var _instance: Node = null
var _player: Node = null
var _skill: Node = null
var _enemy: Node = null
var _baseline_atk: float = 0.0
var _enemy_hp_before: float = 0.0
var _checked: int = 0
var _failures: int = 0

func _initialize() -> void:
	print("=== Day 3 skill pipeline check ===")

func _process(delta: float) -> bool:
	if _idx >= CASES.size():
		_report()
		quit(_failures)
		return true
	_elapsed += delta
	match _sub:
		0:
			_spawn()
			_sub = 1
		1:
			_check_cd()
			_sub = 2
			_elapsed = 0.0
			_armed = false
		2:
			_run_special(delta)
	return false

# ========== 用例流程 ==========

func _spawn() -> void:
	var hero: String = str(CASES[_idx]["hero"])
	root.set_meta(SELECTION_META, hero)
	var packed: PackedScene = load(MAIN_SCENE) as PackedScene
	_instance = packed.instantiate()
	root.add_child(_instance)

## 断言 1：_cd_total（skill 数据正确装载）
func _check_cd() -> void:
	var hero: String = str(CASES[_idx]["hero"])
	var expect_cd: float = float(CASES[_idx]["expect_cd"])
	_player = _instance.get_node_or_null("World/Player")
	_skill = _instance.get_node_or_null("World/Player/SkillController")
	if _player == null or _skill == null:
		_fail("%s / Player 或 SkillController 节点缺失" % hero)
		return
	_assert_near("%s / _cd_total" % hero, float(_skill.get("_cd_total")), expect_cd)

func _run_special(delta: float) -> void:
	var hero: String = str(CASES[_idx]["hero"])
	var special: String = str(CASES[_idx]["special"])
	match special:
		"fireball":
			if not _armed:
				_armed = true
				_arm_fireball_case()
			if _elapsed >= 2.0:
				_check_fireball_case()
				_finish_case()
		"noa":
			# D4-T5 起炮台已真实实现（顺延收口见 day4_level_check 断言 7）：
			# 首次 try_cast 应返回 true（部署成功进冷却），紧接第二次 false
			var first: bool = bool(_skill.call("try_cast"))
			if first:
				_checked += 1
				print("  PASS  noa / 紧急部署 try_cast = true（D4-T5 已实现）")
			else:
				_fail("noa / 紧急部署 try_cast 应为 true")
			var second: bool = bool(_skill.call("try_cast"))
			if second:
				_fail("noa / 冷却未生效，第二次 try_cast 仍返回 true")
			else:
				_checked += 1
				print("  PASS  noa / 冷却生效，第二次 = false")
			_finish_case()
		"blade":
			if not _armed:
				_armed = true
				_arm_blade_case()
			if _elapsed >= 5.4:
				_check_blade_case()
				_finish_case()
		"noskill":
			var can: bool = bool(_skill.call("can_cast"))
			if can:
				_fail("well_rounded / can_cast 应为 false")
			else:
				_checked += 1
				print("  PASS  well_rounded / can_cast = false")
			var first: bool = bool(_skill.call("try_cast"))
			if first:
				_fail("well_rounded / try_cast 应为 false")
			else:
				_checked += 1
				print("  PASS  well_rounded / try_cast = false（零 error）")
			_finish_case()

# ========== 艾琳火球用例 ==========

func _arm_fireball_case() -> void:
	# 敌人摆在「玩家朝鼠标 (0,0) 方向 60px」处，保证火球飞行路径命中
	_skill.set("_cd_left", 0.0)
	var manager: Node = root.get_node_or_null("GameManager")
	var spawner: Node = manager.get("enemy_spawner") if manager else null
	var container: Node = null
	if spawner and spawner.get("enemies_container"):
		container = spawner.enemies_container
	if container == null:
		_fail("irene / enemies_container 缺失，无法摆敌人")
		return
	_enemy = (load(ENEMY_SCENE) as PackedScene).instantiate()
	container.add_child(_enemy)
	var to_mouse: Vector2 = _player.global_position.direction_to(Vector2.ZERO)
	# 敌人摆在玩家朝鼠标 (0,0) 方向 60px 处（探针实测：headless 下 Area2D
	# body_entered 物理碰撞可靠，弹丸飞行途中即命中爆炸；392px 摆位反而超出
	# 实际爆炸点（headless 物理帧率偏低，lifetime×speed 飞不满 392px）→ FAIL）
	_enemy.global_position = _player.global_position + to_mouse * 60.0
	_enemy.max_health = 1000.0
	_enemy.health = 1000.0
	_enemy_hp_before = float(_enemy.health)

	# 断言 2：首次 true，紧接第二次 false（冷却生效）
	var first: bool = bool(_skill.call("try_cast"))
	if first:
		_checked += 1
		print("  PASS  irene / try_cast 首次 = true")
	else:
		_fail("irene / try_cast 首次应为 true")
	var second: bool = bool(_skill.call("try_cast"))
	if second:
		_fail("irene / 冷却未生效，第二次 try_cast 仍返回 true")
	else:
		_checked += 1
		print("  PASS  irene / 冷却生效，第二次 = false")

func _check_fireball_case() -> void:
	if _enemy == null or not is_instance_valid(_enemy):
		_fail("irene / 敌人已失效，无法断言爆炸")
		return
	var hp_now: float = float(_enemy.health)
	if hp_now < _enemy_hp_before - EPSILON:
		_checked += 1
		print("  PASS  irene / 爆炸伤害生效 health %.1f -> %.1f" % [_enemy_hp_before, hp_now])
	else:
		_fail("irene / 火球爆炸后敌人 health 未下降（%.1f -> %.1f）" % [_enemy_hp_before, hp_now])
	if _enemy.has_method("has_status") and bool(_enemy.call("has_status", "fire")):
		_checked += 1
		print("  PASS  irene / 敌人 has_status(fire) = true")
	else:
		_fail("irene / 燃烧状态未附着（D3-T2b 状态机未生效）")

# ========== 莱恩星刃爆发用例 ==========

func _arm_blade_case() -> void:
	_baseline_atk = float(_player.attack_speed)
	_skill.set("_cd_left", 0.0)
	# 断言 2：首次 true，紧接第二次 false（冷却生效）
	var first: bool = bool(_skill.call("try_cast"))
	if first:
		_checked += 1
		print("  PASS  ren / 星刃爆发释放 = true")
	else:
		_fail("ren / 星刃爆发 try_cast 应为 true")
	var second: bool = bool(_skill.call("try_cast"))
	if second:
		_fail("ren / 冷却未生效，第二次 try_cast 仍返回 true")
	else:
		_checked += 1
		print("  PASS  ren / 冷却生效，第二次 = false")
	# 断言 4a：释放瞬间攻速 == 基线 × 1.5
	var atk_after: float = float(_player.attack_speed)
	_assert_near("ren / 释放瞬间 attack_speed == 基线×1.5", atk_after, _baseline_atk * 1.5)

func _check_blade_case() -> void:
	var atk_now: float = float(_player.attack_speed)
	if absf(atk_now - _baseline_atk) <= 0.001:
		_checked += 1
		print("  PASS  ren / 5.01s 后 attack_speed 精确还原 %.4f" % atk_now)
	else:
		_fail("ren / 还原失败：期望 %.4f，实得 %.4f" % [_baseline_atk, atk_now])

# ========== 收尾 ==========

func _finish_case() -> void:
	_teardown()
	_idx += 1
	_sub = 0
	_elapsed = 0.0

func _teardown() -> void:
	if is_instance_valid(_instance):
		_instance.free()
	_instance = null
	_player = null
	_skill = null
	_enemy = null
	_reset_manager_refs()

## 同进程反复实例化 Main 的测试夹具职责：清空 GameManager 持有的已释放子系统引用
func _reset_manager_refs() -> void:
	var manager: Node = root.get_node_or_null("GameManager")
	if manager == null:
		return
	for field: String in ["player", "wave_manager", "enemy_spawner", "economy", "inventory", "vfx_container"]:
		manager.set(field, null)

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
		print("DAY3 SKILL CHECK CLEAN")
	else:
		print("DAY3 SKILL CHECK BROKEN")
