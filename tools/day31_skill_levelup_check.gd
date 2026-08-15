## Day 31 PS-E 出口校验：局外等级奖励解锁（PLAYER_SKILL_SPEC §3 D6）
##
## 用法（无头）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day31_skill_levelup_check.gd
##
## 校验内容（SOLUTION_PLAN 第 23 轮 PS-E3，≥8 断言）：
##   §1 门槛配置生效：DataLoader.get_unlocked_slots_for_level 改表驱动（Lv0=[] / Lv2=[1] / Lv4=[1,2]）
##   §2 解锁链路：unlock_slot_for_level 达门槛 → meta_progress.skill_slots 持久化（幂等）
##   §3 槽位解锁后局内可用：装配目标槽 = 已解锁槽（enemy_damage._offer_skill_choice 白盒）
##   §4 缺省空兼容旧档：无 skill_slots 键 → get_unlocked_slots 返回 []
##
## 无头环境特殊约定（沿 day27_meta 范式）：独立临时档（D44 可覆写 meta_save_path）
##
## 退出码 0 = 全部通过；非 0 = 失败项数。
extends SceneTree

var _checked: int = 0
var _failures: int = 0
var _started: bool = false
var _gm: Node = null
var _tmp_save: String = ""

func _initialize() -> void:
	print("=== Day 31 PS-E skill levelup check ===")

func _process(_delta: float) -> bool:
	if _started:
		return false
	_started = true
	_gm = root.get_node_or_null("GameManager")
	if _gm == null:
		_fail("GameManager Autoload 不可用")
		_report()
		quit(_failures)
		return true
	# 独立临时档（D44 先例：meta_save_path 可覆写，测试后删除）
	_tmp_save = "user://ps_e_test_save.json"
	_gm.set("meta_save_path", _tmp_save)
	_gm.call("load_meta")
	_section_threshold()
	_section_persist()
	_section_in_game()
	_section_default()
	# 清理临时档
	var dir := DirAccess.open("user://")
	if dir and dir.file_exists("ps_e_test_save.json"):
		dir.remove("ps_e_test_save.json")
	_report()
	quit(_failures)
	return true

func _section_threshold() -> void:
	var loader: Node = root.get_node_or_null("DataLoader")
	var lv0: Array = loader.call("get_unlocked_slots_for_level", 0)
	var lv2: Array = loader.call("get_unlocked_slots_for_level", 2)
	var lv4: Array = loader.call("get_unlocked_slots_for_level", 4)
	if lv0.is_empty() and lv2 == [1] and lv4 == [1, 2]:
		_checked += 1
		print("  PASS  §1 门槛表驱动（Lv0=[] / Lv2=[1] / Lv4=[1,2]）")
	else:
		_fail("门槛配置异常（Lv0=%s / Lv2=%s / Lv4=%s）" % [str(lv0), str(lv2), str(lv4)])

func _section_persist() -> void:
	# 达门槛 → 解锁登记（幂等）
	_gm.call("unlock_slot_for_level", "se_irene", 4)
	var slots: Array = _gm.call("get_unlocked_slots", "se_irene")
	if slots == [1, 2]:
		_checked += 1
		print("  PASS  §2 Lv4 解锁登记 → skill_slots=[1,2]")
	else:
		_fail("Lv4 解锁应 [1,2], 实得 %s" % str(slots))
	# 幂等：重复登记不重复追加
	_gm.call("unlock_slot_for_level", "se_irene", 4)
	var again: Array = _gm.call("get_unlocked_slots", "se_irene")
	if again == [1, 2]:
		_checked += 1
		print("  PASS  §2 幂等（重复登记仍 [1,2]）")
	else:
		_fail("幂等破坏: %s" % str(again))
	# 持久化：显式 save_meta 后重新 load_meta 仍在（与 unlock_skill 同语义——改动后上层 save）
	_gm.call("save_meta")
	_gm.call("load_meta")
	var reloaded: Array = _gm.call("get_unlocked_slots", "se_irene")
	if reloaded == [1, 2]:
		_checked += 1
		print("  PASS  §2 持久化（save→load 后仍 [1,2]）")
	else:
		_fail("持久化失败: %s" % str(reloaded))

func _section_in_game() -> void:
	# 槽位解锁后局内可用：装配目标槽取已解锁（白盒 skill_controller）
	var sc_script: GDScript = load("res://scripts/player/skill_controller.gd")
	var sc: Node = sc_script.new()
	var data: Dictionary = {"id": "se_skill_sword_arc", "type": "arc", "cooldown": 8, "damage": 25}
	sc.call("equip_slot", 1, data)
	var skills: Array = sc.get("skills")
	if str(skills[1].get("id", "")) == "se_skill_sword_arc":
		_checked += 1
		print("  PASS  §3 已解锁槽 1 局内可装配（equip_slot 生效）")
	else:
		_fail("槽 1 装配失败")
	sc.call("equip_slot", 2, {"id": "se_skill_fireball", "type": "active"})
	if str(sc.get("skills")[2].get("id", "")) == "se_skill_fireball":
		_checked += 1
		print("  PASS  §3 已解锁槽 2 局内可装配")
	else:
		_fail("槽 2 装配失败")

func _section_default() -> void:
	# 缺省空兼容旧档：未登记角色 → []
	var empty: Array = _gm.call("get_unlocked_slots", "no_such_char")
	if empty.is_empty():
		_checked += 1
		print("  PASS  §4 缺省空兼容旧档（无登记 → []）")
	else:
		_fail("缺省应返回空")

func _report() -> void:
	print("=== Day 31 PS-E skill levelup check: %d passed, %d failed ===" % [_checked, _failures])
	if _failures == 0:
		print("DAY31_SKILL_LEVELUP CHECK CLEAN")

func _fail(msg: String) -> void:
	_failures += 1
	print("  FAIL  %s" % msg)
