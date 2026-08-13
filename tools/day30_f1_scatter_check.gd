## Day 30-F1-散 数值参数化校验（T-007/008/009/011/012/013/015/053）
##
## 用法（无头）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day30_f1_scatter_check.gd
##
## 校验内容（docs/SOLUTION_PLAN.md §1 F1-散）：
##   §1 端到端生效（T-007）：_apply_wave_heal 回血量 == combat.wave_clear_heal_ratio × max_health
##      （外部流程先改 Excel 0.5→0.6 导出跑一次 → 强制改回 0.5 重导出再跑——本探针
##       读表值断言，若消费点仍硬编码则两跑必有一红）
##   §2 读表锚点：max_waves / 火球参数 / 冲锋倍率透传 / wave_number 补键在位
##   §3 缺表兜底（T-007/008/013/015/011/012）：白盒清段 → get_stats_combat/physics/skills
##      返回兜底默认值（= 现硬编码值）；部分缺键 → 仅该键兜底
##   §4 回归抽样：projectile 物理参数消费（mask/radius 读表）+ enemy 冲锋参数 initialize 存储
##
## 退出码 0 = 全部通过；非 0 = 失败项数。
extends SceneTree

const EPSILON: float = 0.001

var _sub: int = 0
var _loader: Node = null
var _gm: Node = null
var _checked: int = 0
var _failures: int = 0

# §3 白盒恢复用快照
var _combat_backup: Dictionary = {}
var _physics_backup: Dictionary = {}
var _skills_backup: Dictionary = {}

func _initialize() -> void:
	print("=== Day 30 F1-散 scatter parameter check ===")

func _process(_delta: float) -> bool:
	if _sub == 0:
		_sub = _advance(_sub)
	elif _sub == 1:
		_report()
		quit(_failures)
		return true
	return false

func _advance(sub: int) -> int:
	_loader = root.get_node_or_null("DataLoader")
	_gm = root.get_node_or_null("GameManager")
	if _loader == null:
		_fail("DataLoader autoload 缺失")
		return 1
	_snapshot()
	_part_end_to_end_heal()
	_part_read_anchors()
	_part_fallback()
	_restore()
	_part_regression()
	return 1

# ========== §1 端到端生效（T-007 通关回血） ==========

class MockPlayer:
	extends Node
	var max_health: float = 100.0
	var healed: float = 0.0
	func heal(amount: float) -> void:
		healed = amount

func _part_end_to_end_heal() -> void:
	var combat: Dictionary = _loader.call("get_stats_combat")
	var ratio: float = float(combat.get("wave_clear_heal_ratio", -1.0))
	_assert_true("§1 读表 wave_clear_heal_ratio=%s 在位" % str(ratio), ratio > 0.0)
	# 白盒驱动：GM.player 挂 MockPlayer → _apply_wave_heal 应回血 ratio × max_health
	var old_player: Node = _gm.player
	var mock: Node = MockPlayer.new()
	mock.name = "MockScatterPlayer"
	root.add_child(mock)
	_gm.player = mock
	_gm.call("_apply_wave_heal")
	_assert_near("§1 _apply_wave_heal 回血 == ratio×max_health(%.3f×100)" % ratio,
		float(mock.healed), 100.0 * ratio)
	# 恢复（GameManager.player 置回原值，防污染后续）
	_gm.player = old_player
	_finalize_node(mock)

# ========== §2 读表锚点（T-008/012/009/053） ==========

func _part_read_anchors() -> void:
	var combat: Dictionary = _loader.call("get_stats_combat")
	_assert_true("§2 combat.max_waves 读表", int(combat.get("max_waves", 0)) == 20)
	var skills: Dictionary = _loader.call("get_stats_skills")
	_assert_near("§2 skills.fireball_speed 读表", float(skills.get("fireball_speed", 0.0)), 280.0)
	_assert_near("§2 skills.fireball_lifetime 读表", float(skills.get("fireball_lifetime", 0.0)), 1.4)
	_assert_true("§2 skills.fireball_pierce 读表", int(skills.get("fireball_pierce", 0)) == 3)
	# T-009：get_scaled_enemy 返回冲锋参数（charger wave 10）
	var st: Dictionary = _loader.call("get_scaled_enemy", "charger", 10)
	_assert_near("§2 scaling.charge_speed_mult 透传", float(st.get("charge_speed_mult", 0.0)), 1.5)
	_assert_near("§2 scaling.charge_windup 透传", float(st.get("charge_windup", 0.0)), 2.0)
	_assert_near("§2 scaling.charge_duration 透传", float(st.get("charge_duration", 0.0)), 0.8)
	# T-053：wave_number 补键在位（Boss 召唤物路径可读）
	_assert_true("§2 get_scaled_enemy wave_number 补键", int(st.get("wave_number", -1)) == 10)
	# 冲锋参数消费点代码在位（enemy.gd _move_charge 用实例变量，不再硬编码 1.5）
	var esrc: String = FileAccess.get_file_as_string("res://scripts/enemy/enemy.gd")
	_assert_true("§2 enemy.gd 冲锋参数消费锚点", esrc.contains("_charge_speed_mult"))

# ========== §3 缺表兜底（T-007/008/013/015/011/012） ==========

func _part_fallback() -> void:
	# 白盒清段：接口应返回完整兜底默认值（= 现硬编码值）
	_loader._combat = {}
	var c: Dictionary = _loader.call("get_stats_combat")
	var expect_c: Dictionary = {
		"wave_clear_heal_ratio": 0.5, "max_waves": 20, "i_frames": 0.4,
		"dodge_cap": 0.9, "debug_damage_mult": 0.001, "knockback_decay": 0.5,
		"contact_cooldown": 0.5, "armor_cap": 0.75,
	}
	var c_ok: bool = c.size() == expect_c.size()
	for k in expect_c:
		if float(c.get(k, -999.0)) != float(expect_c[k]):
			c_ok = false
	_assert_true("§3 combat 缺表兜底 8 键全齐", c_ok)
	_loader._physics = {}
	var p: Dictionary = _loader.call("get_stats_physics")
	_assert_true("§3 physics 缺表兜底", float(p.get("projectile_mask", -1)) == 2.0
		and float(p.get("projectile_radius", -1)) == 4.0)
	_loader._skills = {}
	var s: Dictionary = _loader.call("get_stats_skills")
	_assert_true("§3 skills 缺表兜底", float(s.get("fireball_speed", -1)) == 280.0
		and float(s.get("fireball_lifetime", -1)) == 1.4
		and float(s.get("fireball_pierce", -1)) == 3.0
		and float(s.get("fireball_radius", -1)) == 90.0)
	# 部分缺键：仅该键兜底，其余保留加载值
	_loader._combat = {"max_waves": 30}
	var c2: Dictionary = _loader.call("get_stats_combat")
	_assert_true("§3 部分缺键兜底(仅 max_waves 覆盖)",
		int(c2.get("max_waves", -1)) == 30 and float(c2.get("i_frames", -1)) == 0.4)

# ========== §4 回归抽样（消费点实际生效） ==========

func _part_regression() -> void:
	# T-011：实例化 projectile → collision_mask / 碰撞半径读表生效
	var proj: Area2D = Area2D.new()
	proj.name = "MockScatterProj"
	proj.set_script(load("res://scripts/weapons/projectile.gd"))
	root.add_child(proj)
	# 碰撞体为代码 add_child 自动命名（@CollisionShape2D@N），按类型遍历查找
	var col_shape: CollisionShape2D = null
	for ch in proj.get_children():
		if ch is CollisionShape2D:
			col_shape = ch
			break
	if col_shape != null and col_shape.shape is CircleShape2D:
		var r: float = float(col_shape.shape.radius)
		_assert_near("§4 projectile 碰撞半径读表 4.0", r, 4.0)
	else:
		_fail("§4 projectile CollisionShape2D 缺失")
	_assert_true("§4 projectile collision_mask 读表 2", int(proj.collision_mask) == 2)
	_finalize_node(proj)
	# T-009：enemy.initialize 存储冲锋参数（charger stats 透传）
	var e: CharacterBody2D = CharacterBody2D.new()
	e.name = "MockScatterCharger"
	e.set_script(load("res://scripts/enemy/enemy.gd"))
	root.add_child(e)
	var st: Dictionary = _loader.call("get_scaled_enemy", "charger", 10)
	e.call("initialize", st)
	_assert_near("§4 enemy.initialize 存储 charge_speed_mult", float(e.get("_charge_speed_mult")), 1.5)
	_assert_near("§4 enemy.initialize 存储 charge_duration", float(e.get("_charge_duration")), 0.8)
	_finalize_node(e)

## 立即从树移除并释放（queue_free 延迟到退出 → ObjectDB leak 警告）
func _finalize_node(n: Node) -> void:
	if is_instance_valid(n):
		if n.get_parent() != null:
			n.get_parent().remove_child(n)
		n.free()

# ========== 白盒快照/恢复 ==========

func _snapshot() -> void:
	_combat_backup = _loader._combat.duplicate(true)
	_physics_backup = _loader._physics.duplicate(true)
	_skills_backup = _loader._skills.duplicate(true)

func _restore() -> void:
	_loader._combat = _combat_backup
	_loader._physics = _physics_backup
	_loader._skills = _skills_backup

# ========== 断言 ==========

func _assert_true(label: String, cond: bool) -> void:
	if cond:
		_checked += 1
		print("  PASS  %s" % label)
	else:
		_fail(label)

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
	print("=== Day30-F1-散 result: %d checked, %d failures ===" % [_checked, _failures])
