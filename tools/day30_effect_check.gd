## Day 30-BS-A 效果系统统一校验（BOSS_SKILL_SPEC §11 验收 3/4/5 机器侧）
##
## 用法（无头）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day30_effect_check.gd
##
## 校验内容（docs/SOLUTION_PLAN.md §3 BS-A5 · ≥16 断言四段）：
##   §1 DoT 跳数符合 interval（poison tick_interval=1，3s → 3 跳 10/跳）
##   §2 O1 叠加规则：同源刷新不叠层（stacks 恒 1 + 剩余刷新）/ 异源独立各自 tick（stacks=2 双跳）/
##      max_stacks 上限（fire=1，第三异源被丢弃）
##   §3 到期还原 + O2 软控三类型：减速（move_speed ×0.6 到期还原）/ 麻痹（stunned 置位到期还原）/
##      减防（armor-5 到期还原）
##   §4 免疫表惯例（O3/O5）：StatusComponent 接口在位 + 免疫表放 boss 表（BS-C 消费，resist 列）
##      —— 硬控免疫软控保留的运行时门禁随 BS-C/D 落地，本段仅登记接口/惯例锚点
##
## 退出码 0 = 全部通过；非 0 = 失败项数。
extends SceneTree

const EPSILON: float = 0.001
## ⚠️ --script 探针：Autoload 标识符（DataLoader）在树初始化前不可见——
## 脚本须在 _advance（树已就绪）内 load()，顶层 var 初始化时机过早（历史教训）
var _status_script: GDScript = null

var _sub: int = 0
var _checked: int = 0
var _failures: int = 0

## 隔离 mock（不依赖 enemy.gd，纯组件单测）
class MockTarget:
	extends Node
	var health: float = 100.0
	var max_health: float = 100.0
	var is_alive: bool = true
	var move_speed: float = 100.0
	var armor: float = 10.0
	var stunned: bool = false
	var dot_damage: float = 0.0
	signal health_changed(current_hp: float, max_hp: float)
	func take_status_damage(amount: float) -> void:
		dot_damage += amount
		health -= amount
		if health <= 0.0:
			is_alive = false

func _initialize() -> void:
	print("=== Day 30 BS-A effect system check ===")

func _process(_delta: float) -> bool:
	if _sub == 0:
		_sub = _advance(_sub)
	elif _sub == 1:
		_report()
		quit(_failures)
		return true
	return false

func _advance(sub: int) -> int:
	_status_script = load("res://scripts/systems/status_component.gd")
	if _status_script == null:
		_fail("StatusComponent 脚本加载失败")
		return 1
	_part_dot_interval()
	_part_stack_rules()
	_part_soft_control()
	_part_immunity_convention()
	return 1

func _make_comp(target: Node) -> Node:
	var comp: Node = _status_script.new()
	root.add_child(comp)
	comp.set_process(false)   # 手动驱动，防树帧自动 tick 双计
	comp.call("setup", target)
	return comp

func _free_comp(comp: Node, target: Node) -> void:
	if is_instance_valid(target):
		target.queue_free()
	if is_instance_valid(comp):
		root.remove_child(comp)
		comp.free()

# ========== §1 DoT 跳数符合 interval ==========

func _part_dot_interval() -> void:
	print("-- §1 DoT interval --")
	var target: Node = MockTarget.new()
	root.add_child(target)
	var comp: Node = _make_comp(target)
	# poison：tick_interval=1 → 3s 持续 = 3 跳 × 10
	comp.call("apply_effect", "src_a", "poison", {"duration": 3.0, "dps": 10.0})
	comp.call("_process", 1.0)
	_ok_near("§1 1s 后 1 跳", target.dot_damage, 10.0)
	comp.call("_process", 1.0)
	comp.call("_process", 1.0)
	_ok_near("§1 3s 共 3 跳（interval 符合）", target.dot_damage, 30.0)
	# 剩余时间耗尽 → 实例移除
	_ok(comp.call("get_remaining", "poison") <= 0.0 and comp.call("get_stacks", "poison") == 0,
		"§1 到期实例移除")
	_free_comp(comp, target)

# ========== §2 O1 叠加规则 ==========

func _part_stack_rules() -> void:
	print("-- §2 叠加规则 --")
	var target: Node = MockTarget.new()
	root.add_child(target)
	var comp: Node = _make_comp(target)
	# 同源刷新：stacks 恒 1 + 剩余时间刷新为最新
	comp.call("apply_effect", "src_a", "fire", {"duration": 2.0, "dps": 5.0})
	comp.call("apply_effect", "src_a", "fire", {"duration": 4.0, "dps": 8.0})
	_ok(comp.call("get_stacks", "fire") == 1, "§2 同源刷新不叠层（stacks=1）")
	_ok_near("§2 同源刷新剩余时间=4s", comp.call("get_remaining", "fire"), 4.0)
	comp.call("_process", 1.0)
	_ok_near("§2 同源刷新后 dps=8 生效（1s 跳 8）", target.dot_damage, 8.0)
	# 异源独立（poison max_stacks=2）：src_a（已用于 fire，不同效果独立）+ src_b → stacks=2 各自 tick
	comp.call("apply_effect", "src_a", "poison", {"duration": 3.0, "dps": 8.0})
	comp.call("apply_effect", "src_b", "poison", {"duration": 3.0, "dps": 2.0})
	_ok(comp.call("get_stacks", "poison") == 2, "§2 异源独立实例（poison stacks=2，max_stacks=2）")
	var dmg_before: float = target.dot_damage
	comp.call("_process", 1.0)
	# 三实例并存各自 tick：fire(dps 8) + poison_a(8) + poison_b(2) = 18/跳
	_ok_near("§2 异源独立各自 tick（fire 8+poison 8+2=18/跳）", target.dot_damage - dmg_before, 18.0)
	# max_stacks 上限门禁：fire max_stacks=1 → 第二异源被丢弃（stacks 恒 1）
	comp.call("apply_effect", "src_c", "fire", {"duration": 1.0, "dps": 99.0})
	_ok(comp.call("get_stacks", "fire") == 1, "§2 max_stacks=1 异源丢弃（stacks 恒 1）")
	_free_comp(comp, target)

# ========== §3 到期还原 + 三类型软控 ==========

func _part_soft_control() -> void:
	print("-- §3 软控三类型 --")
	var target: Node = MockTarget.new()
	root.add_child(target)
	var comp: Node = _make_comp(target)
	# 减速：ice value=40 → move_speed ×0.6；到期还原
	comp.call("apply_effect", "s1", "ice", {"duration": 1.0})
	_ok_near("§3 减速 move_speed ×0.6", target.move_speed, 60.0)
	comp.call("_process", 1.1)
	_ok_near("§3 减速到期还原 100", target.move_speed, 100.0)
	# 麻痹：lightning → stunned=true；到期还原
	comp.call("apply_effect", "s2", "lightning", {"duration": 1.0})
	_ok(bool(target.stunned) == true, "§3 麻痹 stunned=true（禁行动）")
	comp.call("_process", 1.1)
	_ok(bool(target.stunned) == false, "§3 麻痹到期 stunned 还原 false")
	# 减防：plasma value=5 → armor-5；到期还原
	comp.call("apply_effect", "s3", "plasma", {"duration": 1.0})
	_ok_near("§3 减防 armor 10→5", target.armor, 5.0)
	comp.call("_process", 1.1)
	_ok_near("§3 减防到期还原 armor 10", target.armor, 10.0)
	_free_comp(comp, target)

# ========== §4 免疫表惯例（O3/O5 锚点） ==========

func _part_immunity_convention() -> void:
	print("-- §4 免疫惯例 --")
	var src: String = FileAccess.get_file_as_string("res://scripts/systems/status_component.gd")
	_ok(src.contains("func apply_effect") and src.contains("func has_effect")
		and src.contains("func get_remaining") and src.contains("func get_stacks"),
		"§4 StatusComponent 接口在位（apply/has/get_remaining/get_stacks）")
	# 免疫表惯例：硬控免疫软控保留 → resist 列放 boss 表（BS-C 拆解 §4.1 boss 表 + §6.4）
	var spec: String = ""
	if FileAccess.file_exists("res://docs/BOSS_SKILL_SPEC.md"):
		spec = FileAccess.get_file_as_string("res://docs/BOSS_SKILL_SPEC.md")
	_ok(spec.contains("resist") and spec.contains("软控"),
		"§4 免疫表惯例登记（boss 表 resist 列 + 硬控免疫软控保留，BS-C/D 消费）")
	# 玩家侧统一入口在位（Boss 技能软控挂点，BS-D 接入）
	var psrc: String = FileAccess.get_file_as_string("res://scripts/player/player.gd")
	_ok(psrc.contains("func apply_effect") and psrc.contains("var stunned: bool"),
		"§4 玩家 apply_effect + stunned 挂点在位")

# ========== 断言 ==========

func _ok_near(label: String, actual: Variant, expect: float) -> void:
	if absf(float(actual) - expect) <= EPSILON:
		_checked += 1
		print("  PASS  %s == %s" % [label, str(actual)])
	else:
		_fail("%s 期望 %s 实际 %s" % [label, str(expect), str(actual)])

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
	print("=== Day30-BS-A effect result: %d checked, %d failures ===" % [_checked, _failures])
