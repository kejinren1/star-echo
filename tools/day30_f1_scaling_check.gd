## Day 30-F1 数据层统一出口校验：scaling/generation 参数化后数值零漂移
##
## 用法（无头）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day30_f1_scaling_check.gd
##
## 校验内容（docs/TECH_DEBT_PLAN.md F1 · T-001/002/003/014）：
##   §1 敌人成长（enemies.json.scaling 参数化）：get_scaled_enemy 结果 == 旧公式期望
##      · chaser wave10：hp = base+growth*10；speed = base*(1+min(10*0.01,0.2))*0.5
##      · butcher(elite) wave10：hp/dmg 再乘 (1+10*0.15)/(1+10*0.08)
##      · boss(predator) wave10：speed 走同一速度公式（F-01 全局减速）
##   §2 生成间隔（waves.json.generation 参数化）：wave10 → max(0.3, 0.8-10*0.02)=0.6
##   §3 路线 boss 波（routes.json.boss_wave）：DataLoader 读取 ==10；生成路线 boss 节点 wave_index==10
##
## 退出码 0 = 全部通过；非 0 = 失败项数。
extends SceneTree

const EPSILON: float = 0.001

var _sub: int = 0
var _loader: Node = null
var _checked: int = 0
var _failures: int = 0

func _initialize() -> void:
	print("=== Day 30 F1 scaling/generation parameter check ===")

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
	if _loader == null:
		_fail("DataLoader autoload 缺失")
		return 1
	_part_enemy_scaling()
	_part_spawn_interval()
	_part_boss_wave()
	return 1

# ========== §1 敌人成长 ==========

func _part_enemy_scaling() -> void:
	# chaser（regular）wave 10
	var chaser: Dictionary = _loader.call("get_scaled_enemy", "chaser", 10)
	var base: Dictionary = _loader.call("get_enemy", "chaser")
	var expect_hp: float = float(base.get("hp", 1)) + float(base.get("hp_growth", 0)) * 10
	var base_speed: float = float(base.get("speed", 200))
	var expect_speed: float = base_speed * (1.0 + min(10 * 0.01, 0.2)) * 0.5
	_assert_near("chaser w10 hp", float(chaser.get("max_health")), expect_hp)
	_assert_near("chaser w10 speed(F-01 0.5)", float(chaser.get("move_speed")), expect_speed)

	# butcher（elite）wave 10：精英乘数 (1+10*0.15)/(1+10*0.08)
	var elite: Dictionary = _loader.call("get_scaled_enemy", "butcher", 10)
	var eb: Dictionary = _loader.call("get_enemy", "butcher")
	var e_hp: float = float(eb.get("hp", 1)) + float(eb.get("hp_growth", 0)) * 10
	var e_dmg: float = float(eb.get("damage", 1)) + float(eb.get("damage_growth", 0)) * 10
	_assert_near("butcher(elite) w10 hp", float(elite.get("max_health")), e_hp * (1.0 + 10 * 0.15))
	_assert_near("butcher(elite) w10 dmg", float(elite.get("damage")), e_dmg * (1.0 + 10 * 0.08))

	# predator（boss）wave 10：速度公式全敌人统一
	var boss: Dictionary = _loader.call("get_scaled_enemy", "predator", 10)
	var bb: Dictionary = _loader.call("get_enemy", "predator")
	var b_speed: float = float(bb.get("speed", 200))
	var expect_b_speed: float = b_speed * (1.0 + min(10 * 0.01, 0.2)) * 0.5
	_assert_near("predator(boss) w10 speed", float(boss.get("move_speed")), expect_b_speed)

# ========== §2 生成间隔 ==========

func _part_spawn_interval() -> void:
	var gen: Dictionary = _loader.call("get_wave_generation")
	var interval_min: float = float(gen.get("spawn_interval_min", 0.3))
	var interval_decay: float = float(gen.get("spawn_interval_decay", 0.02))
	_assert_near("generation.spawn_interval_min 参数化", interval_min, 0.3)
	_assert_near("generation.spawn_interval_decay 参数化", interval_decay, 0.02)
	# 公式: max(min, 0.8 - wave * decay) —— wave 10 → 0.6
	var interval: float = maxf(interval_min, 0.8 - 10 * interval_decay)
	_assert_near("生成间隔公式 w10 = 0.6", interval, 0.6)

# ========== §3 路线 boss 波 ==========

func _part_boss_wave() -> void:
	var routes: Dictionary = _loader.call("get_routes")
	var boss_wave: int = int(routes.get("boss_wave", 0))
	_assert_near("routes.boss_wave 参数化", float(boss_wave), 10.0)
	# 生成路线：boss 节点 wave_index == boss_wave
	var route: Dictionary = _loader.call("get_routes")
	var route_script: GDScript = load("res://scripts/systems/route_generator.gd")
	var gen: Dictionary = route_script.call("generate_from", 20260806, route)
	var boss_hit: bool = false
	var boss_wave_ok: bool = true
	for layer in gen.get("layers", []):
		for node in layer:
			if str(node.get("type", "")) == "boss":
				boss_hit = true
				if int(node.get("wave_index", -1)) != boss_wave:
					boss_wave_ok = false
	if boss_hit and boss_wave_ok:
		_checked += 1
		print("  PASS  路线 boss 节点 wave_index == %d" % boss_wave)
	else:
		_fail("路线 boss 节点 wave_index 应为 %d（hit=%s ok=%s）" % [boss_wave, boss_hit, boss_wave_ok])

# ========== 断言 ==========

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
	print("=== Day30-F1 result: %d checked, %d failures ===" % [_checked, _failures])
