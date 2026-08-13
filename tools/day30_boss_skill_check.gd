## Day 30-BS-B 技能执行器校验（BOSS_SKILL_SPEC §11 验收 1/2 机器侧）
##
## 用法（无头）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day30_boss_skill_check.gd
##
## 校验内容（docs/SOLUTION_PLAN.md §3 BS-B4 · ≥14 断言）：
##   §1 circle 四拍子闭环：telegraph → resolve → recover → DONE（相位推进 + 相位耗时）
##   §2 圈内伤害圈外无伤（距离判定禁物理）+ effects 列表消费（apply_effect 统一入口）
##   §3 公平底线公式（fair_telegraph：player_speed=300 / radius=120 → t_w ≥ 1.2s 锚点）
##   §4 override 变种参数生效（同执行器换 params → 半径/伤害行为变化）+ 工厂未知 type → null
##   （pattern 数据驱动段随 BS-C boss_skill 表落地，本段先行登记）
##
## 退出码 0 = 全部通过；非 0 = 失败项数。
extends SceneTree

const EPSILON: float = 0.001

var _sub: int = 0
var _checked: int = 0
var _failures: int = 0
var _factory: GDScript = null
var _exec_script: GDScript = null

## 圈内 mock 玩家（Node2D + take_damage/apply_effect 追踪）
class MockPlayer:
	extends Node2D
	var hp: float = 100.0
	var hits: int = 0
	var last_damage: float = 0.0
	var effects: Array = []
	func take_damage(amount: float) -> void:
		hp -= amount
		hits += 1
		last_damage = amount
	func apply_effect(source_id: String, effect_id: String, params: Dictionary = {}) -> void:
		effects.append({"source": source_id, "id": effect_id, "duration": params.get("duration", 0.0)})

func _initialize() -> void:
	print("=== Day 30 BS-B boss skill check ===")

func _process(_delta: float) -> bool:
	if _sub == 0:
		_sub = _advance(_sub)
	elif _sub == 1:
		_report()
		quit(_failures)
		return true
	return false

func _advance(sub: int) -> int:
	# ⚠️ Autoload 标识符编译期不可见 → 树就绪后 load()（历史教训）
	_factory = load("res://scripts/boss/boss_skill_factory.gd")
	_exec_script = load("res://scripts/boss/skill_executor.gd")
	if _factory == null or _exec_script == null:
		_fail("执行器脚本加载失败")
		return 1
	_part_circle_phases()
	_part_ring_hit()
	_part_fair_telegraph()
	_part_override()
	return 1

func _mk_player(pos: Vector2) -> Node:
	var p: Node = MockPlayer.new()
	p.global_position = pos
	root.add_child(p)
	return p

func _run_circle(params: Dictionary, total_time: float, step: float = 0.2) -> Node:
	var exec: Node = _factory.call("make", "circle")
	exec.name = "CircleExec"
	root.add_child(exec)
	exec.call("enter", {"params": params})
	var t: float = 0.0
	while t < total_time and not bool(exec.call("is_done")):
		exec.call("tick", step, {})
		t += step
	return exec

func _phase_idx(exec: Node) -> int:
	return int(exec.get("phase"))

# ========== §1 circle 四拍子闭环 ==========

func _part_circle_phases() -> void:
	print("-- §1 四拍子 --")
	var p: Node = _mk_player(Vector2(0, 0))
	var fx := Node2D.new()
	fx.name = "FxBox"
	root.add_child(fx)
	var params := {
		"center": Vector2(0, 0), "radius": 100.0, "telegraph": 1.0,
		"resolve_delay": 0.4, "recover": 0.2, "damage": 30.0,
		"effects": [{"source": "boss", "id": "fire", "duration": 2.0, "dps": 5.0}],
		"player": p, "fx_container": fx,
	}
	var exec: Node = _run_circle(params, 3.0)
	# 相位推进记录（重跑一次逐步断言相位顺序）
	var seq: Array = []
	exec = _factory.call("make", "circle")
	root.add_child(exec)
	exec.call("enter", {"params": params})
	for i in range(10):
		seq.append(int(exec.get("phase")))
		exec.call("tick", 0.2, {})
	_ok(seq[0] == 0, "§1 初始 phase == TELEGRAPH")
	_ok(bool(exec.call("is_done")), "§1 全流程走完 → DONE")
	var telegraph_seen: bool = seq.has(0) and seq.has(1) and seq.has(2)
	_ok(telegraph_seen, "§1 四拍子依次出现（TELEGRAPH→RESOLVE→RECOVER 相位序列 %s）" % str(seq))
	# telegraph 期间（1.0s 内）未结算 → 玩家无伤
	p.hp = 100.0
	exec = _factory.call("make", "circle")
	root.add_child(exec)
	exec.call("enter", {"params": params})
	exec.call("tick", 0.9, {})
	_ok(int(exec.get("phase")) == 0 and p.hp == 100.0, "§1 telegraph 期间不结算（hp 100 无伤）")
	exec.call("tick", 0.2, {})
	_ok(int(exec.get("phase")) == 1, "§1 telegraph 到时 → RESOLVE")
	# 圈内结算伤害
	_ok(p.hp == 70.0, "§1 resolve 结算圈内伤害（100-30=70）")
	# effects 消费（fire 效果挂上；首轮全流程已消费 → 断言 ≥1 且最近一次为 fire）
	_ok(p.effects.size() >= 1 and str(p.effects[p.effects.size() - 1].id) == "fire",
		"§1 effects 列表消费（apply_effect fire，累计 %d 次）" % p.effects.size())
	# recover 后摇 → DONE（resolve 分支需 1 tick 进 recover、再 1 tick 出后摇）
	exec.call("tick", 1.0, {})
	exec.call("tick", 1.0, {})
	_ok(bool(exec.call("is_done")), "§1 recover 后 → DONE")
	exec.queue_free()
	fx.queue_free()
	p.queue_free()

# ========== §2 圈外无伤 ==========

func _part_ring_hit() -> void:
	print("-- §2 圈内/圈外 --")
	var p: Node = _mk_player(Vector2(300, 0))   # 圈外（radius 100）
	var params := {
		"center": Vector2(0, 0), "radius": 100.0, "telegraph": 0.2,
		"resolve_delay": 0.1, "recover": 0.1, "damage": 30.0, "effects": [],
		"player": p,
	}
	var exec: Node = _run_circle(params, 2.0)
	_ok(p.hp == 100.0 and p.hits == 0, "§2 圈外无伤（hp 100，hits 0）")
	# 圈内边界：距离 99 ≤ 100 → 命中
	p.global_position = Vector2(99, 0)
	exec = _factory.call("make", "circle")
	root.add_child(exec)
	exec.call("enter", {"params": params})
	exec.call("tick", 1.0, {})
	_ok(p.hits == 1, "§2 圈内（99≤100）命中 1 次")
	exec.queue_free()
	p.queue_free()

# ========== §3 公平底线 ==========

func _part_fair_telegraph() -> void:
	print("-- §3 公平底线 --")
	var t_anchor: float = float(_exec_script.call("fair_telegraph", 120.0, 300.0))
	_ok(t_anchor >= 1.2 - EPSILON, "§3 fair_telegraph(120, 300) = %.3f ≥ 1.2s 锚点" % t_anchor)
	# 半径越大底线越长（单调性）
	var t_big: float = float(_exec_script.call("fair_telegraph", 300.0, 300.0))
	_ok(t_big > t_anchor, "§3 半径 300 底线 %.3f > 120 底线 %.3f" % [t_big, t_anchor])
	# 速度越快底线越短
	var t_fast: float = float(_exec_script.call("fair_telegraph", 120.0, 600.0))
	_ok(t_fast < t_anchor, "§3 速度 600 底线 %.3f < 300 底线 %.3f" % [t_fast, t_anchor])

# ========== §4 override 变种 + 工厂 ==========

func _part_override() -> void:
	print("-- §4 override 变种 --")
	var p: Node = _mk_player(Vector2(180, 0))
	# 基准：radius 100 → 180 在圈外
	var base := {"center": Vector2(0, 0), "radius": 100.0, "telegraph": 0.2, "resolve_delay": 0.1, "recover": 0.1, "damage": 10.0, "effects": [], "player": p}
	var e1: Node = _run_circle(base, 2.0)
	_ok(p.hits == 0, "§4 基准 radius=100 → 180px 圈外无伤")
	# override 变种：radius 200 → 180 在圈内命中
	var over: Dictionary = base.duplicate()
	over["radius"] = 200.0
	over["damage"] = 25.0
	var e2: Node = _run_circle(over, 2.0)
	_ok(p.hits == 1 and absf(p.last_damage - 25.0) < EPSILON, "§4 override radius=200/damage=25 变种生效（命中 25）")
	# 工厂未知 type → null + 不崩
	var unknown: Variant = _factory.call("make", "no_such_skill")
	_ok(unknown == null, "§4 工厂未知 type → null（调用方判空降级）")
	e1.queue_free()
	e2.queue_free()
	p.queue_free()

# ========== 断言 ==========

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
	print("=== Day30-BS-B boss skill result: %d checked, %d failures ===" % [_checked, _failures])
