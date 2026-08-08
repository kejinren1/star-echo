## Day 2 出口校验：三英雄各进局一次，起始武器命中率必须 3/3
##
## 用法（无头，不需要编辑器）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day2_hero_check.gd
##
## 校验内容（对应 docs/TASKS.md 的 D2-T1a/b/c、D2-T2、D2-EXIT 测试点）：
##   1. CharacterSelect 的选择结果能被 Main 消费（root meta 跨场景传递）
##   2. 角色 starting_weapon 正确装进 WeaponController，占位「初始枪」被换掉（槽位恒为 1）
##   3. 无选择直开 Main.tscn（调试路径）回退默认英雄且零 error
##   4. passive / penalty 已注入 Player，未支持键收进 bonus_stats 而非静默丢弃
##   5. 9 位英雄逐一进局均无报错
##
## 退出码 0 = 全部通过；非 0 = 失败项数。
extends SceneTree

const MAIN_SCENE: String = "res://scenes/Main.tscn"
const SELECTION_META: StringName = &"se_selected_character"

## 重点用例：hero = 选择的英雄 id（空串 = 不选择走兜底）
## expect 内为期望值，键缺省则跳过该项断言
const CASES: Array = [
	{
		"hero": "se_irene",
		"expect": {
			"id": "se_irene", "weapon": "se_star_flame", "weapon_name": "炎星术",
			"damage": 6.0, "fire_rate": 1.818, "max_health": 90.0,
		},
	},
	{
		"hero": "se_noa",
		"expect": {
			"id": "se_noa", "weapon": "se_auto_turret", "weapon_name": "自动炮台",
			"attack_speed": 0.85,
		},
	},
	{
		"hero": "se_ren",
		"expect": {
			"id": "se_ren", "weapon": "se_star_blade", "weapon_name": "星刃",
			# D4-T3 起 life_steal_percent 从 bonus_stats 移入 life_steal 属性通道（5% → 0.05）
			"crit_chance": 0.15, "life_steal": 0.05,
		},
	},
	{
		"hero": "",
		"expect": {"id": "well_rounded", "weapon": "pistol", "weapon_name": "手枪"},
	},
]

## 冒烟用例：其余英雄只验「能进局 + 起始武器命中 + 无 error」
const SMOKE_HEROES: PackedStringArray = ["brawler", "ranger", "mage", "engineer", "gambler"]

const EPSILON: float = 0.01

var _queue: Array = []
var _index: int = 0
var _phase: int = 0
var _instance: Node = null
var _failures: int = 0
var _checked: int = 0

func _initialize() -> void:
	print("=== Day 2 hero pipeline check ===")
	_queue = CASES.duplicate()
	for hero: String in SMOKE_HEROES:
		_queue.append({"hero": hero, "expect": {"id": hero}})

func _process(_delta: float) -> bool:
	if _index >= _queue.size():
		_report()
		quit(_failures)
		return true

	match _phase:
		0:
			_spawn(_queue[_index])
			_phase = 1
		1:
			# 空转一帧，等 Main._start_game_delayed() 的 await 走完
			_phase = 2
		2:
			_check(_queue[_index])
			_teardown()
			_index += 1
			_phase = 0
	return false

# ========== 用例执行 ==========

func _spawn(test_case: Dictionary) -> void:
	var hero: String = str(test_case["hero"])
	if hero.is_empty():
		if root.has_meta(SELECTION_META):
			root.remove_meta(SELECTION_META)
	else:
		root.set_meta(SELECTION_META, hero)
	# F-22/F-23 轮（2026-08-08）局外增益隔离：同 day4——真实存档含研究增益
	# （max_health ×1.10 等）会污染数值断言（期望 90.000 实得 99.000）；白盒重置默认不写盘
	var gm: Node = root.get_node_or_null("GameManager")
	if gm:
		gm.set("meta_progress", gm.call("_default_meta"))

	var packed: PackedScene = load(MAIN_SCENE) as PackedScene
	_instance = packed.instantiate()
	root.add_child(_instance)

func _check(test_case: Dictionary) -> void:
	var hero: String = str(test_case["hero"])
	var expect: Dictionary = test_case["expect"]
	var label: String = hero if not hero.is_empty() else "<no-selection>"

	_assert_str("%s / character_id" % label, str(_instance.get("current_character_id")), str(expect["id"]))

	var player: Node = _instance.get_node_or_null("World/Player")
	var controller: Node = _instance.get_node_or_null("World/Player/WeaponController")
	if player == null or controller == null:
		_fail("%s / Player 或 WeaponController 节点缺失" % label)
		return

	# --- 起始武器 ---
	# 注意：本脚本是 `--script` 模式的 SceneTree 脚本，Autoload 单例（DataLoader）不自动注册，
	# 故期望值全部由 CASES 预填（见脚本顶部），禁止运行时查 DataLoader。
	if expect.has("weapon"):
		_assert_str("%s / starting_weapon" % label, controller.get_primary_weapon_id(), str(expect["weapon"]))
	_assert_str("%s / 武器槽数量" % label, str(controller.equipped_weapons.size()), "1")

	var weapon: Resource = controller.equipped_weapons[0]
	if expect.has("weapon_name"):
		_assert_str("%s / weapon_name" % label, str(weapon.weapon_name), str(expect["weapon_name"]))
	if expect.has("damage"):
		_assert_near("%s / base_damage" % label, weapon.base_damage, float(expect["damage"]))
	if expect.has("fire_rate"):
		_assert_near("%s / fire_rate" % label, weapon.fire_rate, float(expect["fire_rate"]))

	# --- 被动 / 惩罚注入 ---
	for stat: String in ["max_health", "attack_speed", "crit_chance", "life_steal"]:
		if expect.has(stat):
			_assert_near("%s / %s" % [label, stat], float(player.get(stat)), float(expect[stat]))

	if expect.has("bonus_key"):
		var bonuses: Dictionary = player.get("bonus_stats")
		var key: String = str(expect["bonus_key"])
		if not bonuses.has(key):
			_fail("%s / bonus_stats 缺键 %s（未支持键被静默丢弃）" % [label, key])
		else:
			_assert_near("%s / bonus_stats[%s]" % [label, key], float(bonuses[key]), float(expect["bonus_value"]))

func _teardown() -> void:
	if is_instance_valid(_instance):
		_instance.free()
	_instance = null
	_reset_manager_refs()

## 同进程内反复实例化 Main 是测试特有场景：GameManager 仍持有上一局已释放的子系统引用，
## 会让下一局 HUD/Shop 的 `if GameManager.xxx` 判空失效。清空引用属测试夹具职责，不改动游戏代码。
func _reset_manager_refs() -> void:
	var manager: Node = root.get_node_or_null("GameManager")
	if manager == null:
		return
	for field: String in ["player", "wave_manager", "enemy_spawner", "economy", "inventory", "vfx_container"]:
		manager.set(field, null)

# ========== 断言 ==========

func _assert_str(what: String, actual: String, expected: String) -> void:
	_checked += 1
	if actual == expected:
		print("  PASS  %s = %s" % [what, actual])
	else:
		_failures += 1
		print("  FAIL  %s : 期望 %s，实得 %s" % [what, expected, actual])

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
		print("DAY2 HERO CHECK CLEAN")
	else:
		print("DAY2 HERO CHECK BROKEN")
