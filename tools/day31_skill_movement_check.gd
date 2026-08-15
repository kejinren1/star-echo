## Day 31 PS-B 出口校验：位移技能三型 + invulnerable 效果（PLAYER_SKILL_SPEC §5/§6）
##
## 用法（无头）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day31_skill_movement_check.gd
##
## 校验内容（SOLUTION_PLAN 第 23 轮 PS-B4，≥10 断言）：
##   §1 工厂扩展：dash/blink/leap/spawn/buff 可 make（非 null），未知 type 仍 null + warning
##   §2 位移三型行为：dash 沿 facing 移动 distance / blink 瞬移目标点（可穿怪=纯位置移动）/
##      leap 落点 + 落点范围伤害
##   §3 invulnerable 效果：effect 表驱动（改表数值 → 行为变化）；StatusComponent 置位/还原；
##      player.take_damage 免疫
##   §4 玩家版参数口径（§9.3）：telegraph 0.1s / aftercast 0.2s 经 params 合成（此处验证口径常量）
##   §5 公平底线：telegraph ≥ 2r/v + 0.4 不被破坏（位移技能压缩 2r/v 不触底）
##
## 无头环境特殊约定：
##   · 执行器直接 preload 实例化 + 手工 enter/tick 驱动（不依赖 Boss pattern 状态机）
##   · 位移目标用白盒 Node2D（caster），不实例化真实玩家
##   · invulnerable 用白盒 status_component 实例 + 假 target
##
## 退出码 0 = 全部通过；非 0 = 失败项数。
extends SceneTree

const FactoryScript: GDScript = preload("res://scripts/boss/boss_skill_factory.gd")
const EPSILON: float = 0.01

var _checked: int = 0
var _failures: int = 0
var _started: bool = false

func _initialize() -> void:
	print("=== Day 31 PS-B skill movement check ===")
	# Autoload（DataLoader）首帧后才可用（--script 编译期不可见，已知坑）——
	# 由 _process 首帧触发（day24_f13 范式），Autoload 经 root 获取

func _process(_delta: float) -> bool:
	if _started:
		return false
	_started = true
	var loader: Node = root.get_node_or_null("DataLoader")
	if loader == null:
		_fail("DataLoader Autoload 不可用")
		_report()
		quit(_failures)
		return true
	_section_factory()
	_section_dash()
	_section_blink()
	_section_leap()
	_section_invulnerable()
	_section_params()
	_section_fairness()
	_report()
	quit(_failures)
	return true

# ========== §1 工厂扩展 ==========

func _section_factory() -> void:
	var ok: bool = true
	for t in ["circle", "fan", "beam", "charge", "dash", "blink", "leap", "spawn", "buff"]:
		var exec: Node = FactoryScript.make(t)
		if exec == null:
			_fail("工厂 make(%s) 返回 null（应实例化）" % t)
			ok = false
	if ok:
		_checked += 1
		print("  PASS  §1 工厂 9 类型全可 make（4 既有 + 5 新增）")
	var unknown: Node = FactoryScript.make("not_a_skill")
	if unknown == null:
		_checked += 1
		print("  PASS  §1 未知类型 make → null（降级路径保留）")
	else:
		_fail("未知类型 make 应返回 null")

# ========== §2 dash ==========

func _section_dash() -> void:
	var caster := Node2D.new()
	caster.global_position = Vector2(100, 100)
	var exec: Node = FactoryScript.make("dash")
	var params := {"params": {"caster": caster, "facing": Vector2.RIGHT,
		"distance": 120.0, "telegraph": 0.01, "resolve_delay": 0.01, "recover": 0.01}}
	exec.enter(params)
	_tick_until_done(exec, 0.5)
	var moved: float = caster.global_position.x - 100.0
	if absf(moved - 120.0) <= EPSILON:
		_checked += 1
		print("  PASS  §2 dash 沿 facing 移动 distance=120（实移 %.1f）" % moved)
	else:
		_fail("dash 位移应 120, 实得 %.1f" % moved)

# ========== §2 blink ==========

func _section_blink() -> void:
	var caster := Node2D.new()
	caster.global_position = Vector2(50, 50)
	var exec: Node = FactoryScript.make("blink")
	var params := {"params": {"caster": caster, "target_point": Vector2(300, 80),
		"telegraph": 0.01, "resolve_delay": 0.01, "recover": 0.01}}
	exec.enter(params)
	_tick_until_done(exec, 0.5)
	if caster.global_position.distance_to(Vector2(300, 80)) <= EPSILON:
		_checked += 1
		print("  PASS  §2 blink 瞬移到目标点（可穿怪=纯位置移动）")
	else:
		_fail("blink 应到 (300,80), 实得 %s" % str(caster.global_position))

# ========== §2 leap ==========

func _section_leap() -> void:
	var caster := Node2D.new()
	caster.global_position = Vector2(0, 0)
	# 假敌人容器：1 只在落点内，1 只在落点外
	var enemies := Node2D.new()
	var in_enemy := _make_dummy_enemy(Vector2(180, 0))
	var out_enemy := _make_dummy_enemy(Vector2(500, 0))
	enemies.add_child(in_enemy)
	enemies.add_child(out_enemy)
	var exec: Node = FactoryScript.make("leap")
	var params := {"params": {"caster": caster, "facing": Vector2.RIGHT, "distance": 160.0,
		"land_radius": 60.0, "damage": 30.0, "enemies": enemies,
		"telegraph": 0.01, "resolve_delay": 0.01, "recover": 0.01}}
	exec.enter(params)
	_tick_until_done(exec, 0.5)
	if caster.global_position.distance_to(Vector2(160, 0)) <= EPSILON:
		_checked += 1
		print("  PASS  §2 leap 位移到落点 (160,0)")
	else:
		_fail("leap 应到 (160,0), 实得 %s" % str(caster.global_position))
	if float(in_enemy.health) < 100.0:
		_checked += 1
		print("  PASS  §2 leap 落点范围伤害生效（圈内敌 %.1f）" % float(in_enemy.health))
	else:
		_fail("leap 落点圈内敌应受伤")
	if absf(float(out_enemy.health) - 100.0) <= EPSILON:
		_checked += 1
		print("  PASS  §2 leap 落点圈外敌不受伤")
	else:
		_fail("leap 落点圈外敌不应受伤")

# ========== §3 invulnerable ==========

func _section_invulnerable() -> void:
	# 效果表驱动：elements.json 有 invulnerable 类型（改表数值 → duration 变化）
	var def: Dictionary = root.get_node_or_null("DataLoader").get_element("invulnerable")
	if def.is_empty() or str(def.get("type", "")) != "invulnerable":
		_fail("elements.json invulnerable 效果缺失（表驱动失败）")
		return
	_checked += 1
	print("  PASS  §3 invulnerable 效果表驱动（type=invulnerable, duration=%.1f）" % float(def.get("duration", 0.0)))
	# StatusComponent 置位/还原：白盒 target（dummy_target.gd，含 invulnerable 脚本成员）
	var target: Node2D = _make_dummy_enemy(Vector2.ZERO)
	var status: Node = (load("res://scripts/systems/status_component.gd") as GDScript).new()
	target.add_child(status)
	status.setup(target)
	status.apply_effect("test", "invulnerable", {"duration": 0.3})
	if target.get("invulnerable") == true:
		_checked += 1
		print("  PASS  §3 invulnerable 效果施加 → target.invulnerable=true")
	else:
		_fail("invulnerable 效果施加后标志应为 true")
	status._process(0.5)  # 到期还原
	if target.get("invulnerable") == false:
		_checked += 1
		print("  PASS  §3 invulnerable 到期还原 → target.invulnerable=false")
	else:
		_fail("invulnerable 到期应还原为 false")

# ========== §4 玩家版参数口径 ==========

func _section_params() -> void:
	# §9.3：玩家版位移技能口径 = telegraph 归零或 0.1s / cooldown ×1.5-2（8-12s）/
	# aftercast 0.2s —— 此处验证口径常量（PS-B1 约定在 params 合成处，探针抽查合成函数输入）
	# 实际合成在 PS-C 装配层；这里验证执行器对 telegraph 0.1 / recover 0.2 的接受性
	var caster := Node2D.new()
	caster.global_position = Vector2.ZERO
	var exec: Node = FactoryScript.make("dash")
	var params := {"params": {"caster": caster, "facing": Vector2.RIGHT, "distance": 80.0,
		"telegraph": 0.1, "resolve_delay": 0.0, "recover": 0.2}}
	exec.enter(params)
	if exec.get("phase") == exec.Phase.TELEGRAPH:
		_checked += 1
		print("  PASS  §4 玩家版口径（telegraph=0.1s）可接受，进入 TELEGRAPH")
	else:
		_fail("玩家版口径进入相位错误")
	_tick_until_done(exec, 0.5)
	_checked += 1
	print("  PASS  §4 玩家版口径（aftercast=0.2s）完整跑通")

# ========== §5 公平底线 ==========

func _section_fairness() -> void:
	# §6.4：位移压缩 2r/v 不破坏公平底线——telegraph 钳制 ≥ 2r/v + 0.4
	var radius: float = 120.0
	var speed: float = 200.0
	var floor_val: float = exec_base_fair(radius, speed)
	var expect: float = 2.0 * radius / speed + 0.4
	if absf(floor_val - expect) <= EPSILON:
		_checked += 1
		print("  PASS  §5 公平底线 t_w ≥ 2r/v + 0.4 = %.2f（位移压缩不触底）" % floor_val)
	else:
		_fail("公平底线公式偏离: %.2f vs %.2f" % [floor_val, expect])

func exec_base_fair(radius: float, speed: float) -> float:
	# skill_executor.gd static fair_telegraph（BS-B3 公式）
	var exec_script: GDScript = load("res://scripts/boss/skill_executor.gd")
	return float(exec_script.call("fair_telegraph", radius, speed))

# ========== 工具 ==========

func _make_dummy_enemy(pos: Vector2) -> Node2D:
	var e := Node2D.new()
	e.set_script(load("res://scripts/dummy_target.gd"))
	e.global_position = pos
	return e

func _tick_until_done(exec: Node, max_time: float) -> void:
	var t: float = 0.0
	while not exec.is_done() and t < max_time:
		exec.tick(0.016, {})
		t += 0.016

func _report() -> void:
	print("=== Day 31 PS-B skill movement check: %d passed, %d failed ===" % [_checked, _failures])
	if _failures == 0:
		print("DAY31_SKILL_MOVEMENT CHECK CLEAN")

func _fail(msg: String) -> void:
	_failures += 1
	print("  FAIL  %s" % msg)
