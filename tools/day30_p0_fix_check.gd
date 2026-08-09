## Day 30-P0 修复出口校验（F0 阶段 · P0-Bug1/P0-Bug2 修复验证）
##
## 用法（无头，不需要编辑器）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day30_p0_fix_check.gd
##
## 校验内容（docs/TECH_DEBT_PLAN.md F0 · P0 顺手修）：
##   §1 P0-Bug1 希亚「神圣庇护」（se_skill_holy_shield）：
##      1a 数据装载：_cd_total == 14.0（cooldown）
##      1b try_cast() 返回 true → player.shield == 30（effects.shield）
##      1c 受击护盾吸收：take_damage(10) → shield == 20、health 满血不变
##      1d 穿透伤害：take_damage(50) → shield == 0、health == 70（30 穿透，armor 0 / dodge 0）
##      1e 时长耗尽归零：_handle_shield(6.0) → shield == 0
##      1f 冷却生效：再次 try_cast() 立即调用 == false
##   §2 P0-Bug2 被动效果键收口（apply_item_bonuses）：
##      2a 有消费方键（elemental_damage/summon_count）进 bonus_stats 零警告
##      2b 无消费方键（harvesting）进 bonus_stats + push_warning 登记（不静默丢弃）
##      2c remove=true 对称还原归零
##
## 退出码 0 = 全部通过；非 0 = 失败项数。
extends SceneTree

const EPSILON: float = 0.001

var _sub: int = 0
var _loader: Node = null
var _gm: Node = null
var _player: Node = null
var _skill: Node = null
var _checked: int = 0
var _failures: int = 0
var _expect_loaded: bool = false


func _initialize() -> void:
	print("=== Day 30 P0 fix check (holy_shield + bonus_stats) ===")


## SceneTree 模式驱动：首帧装载 mock，逐段推进（day24_f13 范式）
func _process(_delta: float) -> bool:
	if not _expect_loaded:
		_load_mocks()
	if _sub >= 4:
		_report()
		quit(_failures)
		return true
	_sub = _advance(_sub)
	return false


func _load_mocks() -> void:
	_expect_loaded = true
	_loader = root.get_node_or_null("DataLoader")
	_gm = root.get_node_or_null("GameManager")
	if _loader == null or _gm == null:
		_fail("DataLoader/GameManager autoload 缺失")
		_report()
		quit(_failures)
		return

	# mock player（day28 范式：裸节点 + player.gd 脚本，装配齐属性字段）
	_player = CharacterBody2D.new()
	_player.name = "MockPlayer"
	_player.set_script(load("res://scripts/player/player.gd"))
	_player.attack_speed = 1.0
	_player.crit_damage = 2.0
	_player.crit_chance = 0.05
	_player.max_health = 100.0
	_player.move_speed = 300.0
	_player.armor = 0.0
	_player.regen = 0.0
	_player.dodge = 0.0
	_player.range_multiplier = 1.0
	_player.pickup_range = 80.0
	_player.life_steal = 0.0
	_player.luck = 0.0
	_player.damage_multiplier = 1.0
	root.add_child(_player)
	_player.health = _player.max_health

	# mock inventory（_update_last_stand 读 GameManager.inventory）
	var inv_script: GDScript = load("res://scripts/systems/inventory.gd")
	var inv: Node = inv_script.new()
	inv.name = "MockInventory"
	root.add_child(inv)
	_gm.set("inventory", inv)
	_gm.set("player", _player)

	# mock skill_controller（子节点，_ready 取 parent 为 player）
	_skill = Node.new()
	_skill.name = "SkillController"
	_skill.set_script(load("res://scripts/player/skill_controller.gd"))
	_player.add_child(_skill)


func _advance(sub: int) -> int:
	match sub:
		0:
			_part_holy_shield_cast()
			return 1
		1:
			_part_holy_shield_absorb()
			return 2
		2:
			_part_bonus_stats()
			return 3
		3:
			_report()
			return 4
	return 4


# ========== §1 希亚护盾：施放 ==========

func _part_holy_shield_cast() -> void:
	var char_data: Dictionary = _loader.call("get_character", "se_siia")
	if char_data.is_empty():
		_fail("se_siia 角色数据缺失")
		return
	_skill.call("setup", char_data)

	# 1a 冷却装载
	var cd: float = float(_skill.get("_cd_total"))
	_assert_near("1a 希亚 _cd_total", cd, 14.0)

	# 1b 施放 → 护盾 30
	var first: bool = bool(_skill.call("try_cast"))
	if not first:
		_fail("1b 希亚 try_cast 应返回 true")
	else:
		_checked += 1
		print("  PASS  1b 希亚 try_cast = true")
	var shield: float = float(_player.get("shield"))
	_assert_near("1b 施放后 shield", shield, 30.0)


# ========== §1 希亚护盾：受击吸收 ==========

func _part_holy_shield_absorb() -> void:
	# 1c 10 点伤害全吸收
	_player.call("take_damage", 10.0)
	var shield: float = float(_player.get("shield"))
	var health: float = float(_player.get("health"))
	_assert_near("1c 吸收后 shield", shield, 20.0)
	_assert_near("1c 吸收后 health", health, 100.0)

	# 1d 50 点伤害：护盾 20 全吃 + 30 穿透（先清 1c 留下的 0.4s 无敌帧）
	_player.set("_invulnerable_timer", 0.0)
	_player.call("take_damage", 50.0)
	shield = float(_player.get("shield"))
	health = float(_player.get("health"))
	_assert_near("1d 穿透后 shield", shield, 0.0)
	_assert_near("1d 穿透后 health", health, 70.0)

	# 1e 时长耗尽归零（模拟 6 秒后，时长 5 秒）
	_player.call("_handle_shield", 6.0)
	shield = float(_player.get("shield"))
	_assert_near("1e 时长耗尽 shield", shield, 0.0)

	# 1f 冷却生效（施放后 14 秒冷却，未走时间即再施放应为 false）
	var second: bool = bool(_skill.call("try_cast"))
	if second:
		_fail("1f 冷却未生效，再次 try_cast 仍 true")
	else:
		_checked += 1
		print("  PASS  1f 冷却生效，再次 try_cast = false")


# ========== §2 bonus_stats 收口 ==========

func _part_bonus_stats() -> void:
	# 构造 Item resource（item.gd 基类，get_all_stats 返回 stat_bonuses）
	var item_script: GDScript = load("res://scripts/items/item.gd")
	var item: Resource = item_script.new()
	item.set("stat_bonuses", {
		"elemental_damage": 8.0,
		"summon_count": 1.0,
		"harvesting": 3.0,
	})
	_player.call("apply_item_bonuses", item)

	var bs: Dictionary = _player.get("bonus_stats")
	# 2a 有消费方键进 bonus_stats（elemental_damage 燃烧 dps / summon_count 炮台数消费）
	_assert_near("2a bonus_stats.elemental_damage", float(bs.get("elemental_damage", 0.0)), 8.0)
	_assert_near("2a bonus_stats.summon_count", float(bs.get("summon_count", 0.0)), 1.0)
	# 2b 无消费方键也进 bonus_stats（数值不丢，warning 登记 TECH_DEBT_ISSUES）
	_assert_near("2b bonus_stats.harvesting", float(bs.get("harvesting", 0.0)), 3.0)

	# 2c remove 对称还原
	_player.call("apply_item_bonuses", item, true)
	bs = _player.get("bonus_stats")
	_assert_near("2c remove elemental_damage", float(bs.get("elemental_damage", 0.0)), 0.0)
	_assert_near("2c remove summon_count", float(bs.get("summon_count", 0.0)), 0.0)
	_assert_near("2c remove harvesting", float(bs.get("harvesting", 0.0)), 0.0)


# ========== 断言与报告 ==========

func _assert_near(label: String, actual: float, expect: float) -> void:
	if absf(actual - expect) <= EPSILON:
		_checked += 1
		print("  PASS  %s == %s" % [label, str(actual)])
	else:
		_fail("%s 期望 %s 实际 %s" % [label, str(expect), str(actual)])


func _fail(msg: String) -> void:
	_failures += 1
	print("  FAIL  %s" % msg)


func _report() -> void:
	print("=== Day30-P0 result: %d checked, %d failures ===" % [_checked, _failures])
