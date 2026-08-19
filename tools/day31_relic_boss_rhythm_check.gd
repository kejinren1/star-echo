extends SceneTree
## RELIC-F Boss 行为节奏（方案师第 31 轮 · 拆解第 61 轮 · 2026-08-19 #3 执行）
## SPEC §7：施法站定态（cast_slowdown）+ 时间分配倒置（chase_ratio/skill_window）
## + 大范围技能权重主导 + 走走停停节奏（F4 追踪射程即停）
## §1 数据键（boss_patterns.json 3 行全含 cast_slowdown/chase_ratio/skill_window + 数值范围）
## §2 施放站定（真实 Boss pick → executor 运行中 movement tick → velocity 归零；缺省 1.0 满速兜底）
## §3 时间分配倒置（白盒统计：追踪段 = cd×chase_ratio < 施放段+走位段；circle_aoe 占比 30-40%）
## §4 大范围权重（circle 系 3 行 > 贴身追击 0 行）
## §5 公平底线零破坏（fair_telegraph 锚点 + 每 skill telegraph ≥ 底线 + 难度钳制）
## §6 节奏状态机（executor done → cooldown=cd×ratio + window 入位；window 期不 pick；
##    归零 → 新 pick；rhythm 空字典缺省零变化）
## 驱动范式：_process 首帧执行（Autoload 挂载后 root 可见）+ 显式 quit
## ⚠️ 不 preload enemy.gd/enemy_boss.gd/enemy_movement.gd（引用 Autoload = 探针三坑①）
## → 真实 Enemy.tscn 实例化 + boss._boss_ctrl/_movement 组件白盒驱动

var _checked := 0
var _failures := 0
var _started := false

func _check(cond: bool, msg: String) -> void:
	_checked += 1
	if not cond:
		_failures += 1
		print("XX " + msg)

func _load_json(path: String) -> Dictionary:
	var txt: String = FileAccess.get_file_as_string(path)
	if txt.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(txt)
	if parsed is Dictionary:
		return parsed
	return {}

func _process(_delta: float) -> bool:
	if _started:
		return false
	_started = true
	_s1_data_keys()
	_s2_cast_stationary()
	_s3_time_split()
	_s4_wide_weight()
	_s5_fair_telegraph()
	_s6_state_machine()
	print("\n=== Day31 RELIC-F boss rhythm: %d checked, %d failures ===" % [_checked, _failures])
	quit(_failures)
	return true

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

## 构造真实 Boss（invoker）+ mock 玩家（距离 < LEASH 320px）
func _mk_boss_and_player() -> Array:
	var p: Node = MockPlayer.new()
	p.global_position = Vector2(100, 0)
	root.add_child(p)
	var loader: Node = root.get_node_or_null("DataLoader")
	var stats: Dictionary = loader.call("get_scaled_enemy", "invoker", 10)
	var scene: PackedScene = load("res://scenes/Enemy.tscn")
	var boss: Node = scene.instantiate()
	root.add_child(boss)
	boss.call("initialize", stats)
	boss.call("set_target", p)
	boss.set("_active_executor", null)
	boss.set("_pattern_cooldown", 0.0)
	boss.set("_pattern_window_timer", 0.0)
	boss.set("_pattern_rhythm", {})
	boss.set("_rng", RandomNumberGenerator.new())
	boss._rng.seed = 20260819
	return [boss, p]

## §1 数据键：3 行全含 3 节奏键 + 数值范围 + invoker circle_aoe 具体锚点
func _s1_data_keys() -> void:
	print("-- §1 数据键 --")
	var data: Dictionary = _load_json("res://data/boss_patterns.json")
	var patterns: Array = data.get("patterns", [])
	_check(patterns.size() == 3, "§1/keys: boss_patterns 3 行（实得 %d）" % patterns.size())
	var missing := 0
	var bad_range := 0
	for p in patterns:
		for key in ["cast_slowdown", "chase_ratio", "skill_window"]:
			if not p.has(key):
				missing += 1
		var cs: float = float(p.get("cast_slowdown", -1.0))
		var cr: float = float(p.get("chase_ratio", -1.0))
		var sw: float = float(p.get("skill_window", -1.0))
		if cs < 0.0 or cs > 1.0 or cr <= 0.0 or cr > 1.0 or sw < 0.0:
			bad_range += 1
	_check(missing == 0, "§1/keys: 3 行节奏键全覆盖（缺失 %d）" % missing)
	_check(bad_range == 0, "§1/keys: 数值范围合法（cast_slowdown∈[0,1] / chase_ratio∈(0,1] / skill_window≥0）")
	var first: Dictionary = patterns[0]
	_check(absf(float(first.get("cast_slowdown", -1.0))) < 0.001, "§1/keys: invoker circle_aoe cast_slowdown=0（站定）")
	_check(absf(float(first.get("chase_ratio", 0.0)) - 0.2) < 0.001, "§1/keys: chase_ratio=0.2（追踪段系数）")
	_check(absf(float(first.get("skill_window", 0.0)) - 1.0) < 0.001, "§1/keys: skill_window=1.0s（走位窗口）")

## §2 施放站定：pick → executor 运行中 → movement tick → velocity == ZERO（cast_slowdown=0）
func _s2_cast_stationary() -> void:
	print("-- §2 施放站定 --")
	var pair: Array = _mk_boss_and_player()
	var boss: Node = pair[0]
	var p: Node = pair[1]
	# 强制就绪并 pick（种子固定）
	boss.call("_pick_and_cast")
	var exec: Variant = boss.get("_active_executor")
	_check(exec != null and is_instance_valid(exec), "§2/cast: pick 后执行器已创建")
	_check(boss.get("_pattern_rhythm").get("cast_slowdown", 1.0) == 0.0, "§2/cast: rhythm.cast_slowdown 已缓存 0.0")
	# movement tick 一帧（executor 运行中，未 done）→ 施放期站定
	boss._movement.call("tick", 0.1)
	_check(boss.velocity == Vector2.ZERO, "§2/cast: 施放期移速归零站定（velocity=%s）" % str(boss.velocity))
	# 缺省兜底：rhythm 空 → cast_slowdown=1.0 满速（旧数据零变化）
	boss.set("_pattern_rhythm", {})
	boss._movement.call("tick", 0.1)
	_check(boss.velocity.length() > 0.0, "§2/cast: 缺省 rhythm → 满速追踪（velocity len=%.1f）" % boss.velocity.length())
	_cleanup_boss(boss, p)

func _cleanup_boss(boss: Node, p: Node) -> void:
	if is_instance_valid(boss.get("_active_executor")):
		boss.get("_active_executor").queue_free()
	boss.queue_free()
	p.queue_free()

## §3 时间分配倒置（白盒统计）：追踪段 = cd×chase_ratio vs 施放段（telegraph+resolve+recover）+ 走位段
func _s3_time_split() -> void:
	print("-- §3 时间分配倒置 --")
	var pat_data: Dictionary = _load_json("res://data/boss_patterns.json")
	var sk_data: Dictionary = _load_json("res://data/boss_skills.json")
	var patterns: Array = pat_data.get("patterns", [])
	var skills: Dictionary = sk_data.get("skills", {})
	var invoker_ok := 0
	var strict_ok := 0
	for pat in patterns:
		var skill: Dictionary = skills.get(str(pat.get("skill_id", "")), {})
		if skill.is_empty():
			continue
		var cd: float = maxf(float(skill.get("cooldown", 4.0)), float(pat.get("min_interval", 0.0)))
		var chase: float = cd * float(pat.get("chase_ratio", 1.0))
		var cast: float = float(skill.get("telegraph", 0.8)) + float(skill.get("resolve_delay", 0.5)) \
			+ float(skill.get("recover", 0.3))
		var window: float = float(pat.get("skill_window", 0.0))
		var total: float = chase + cast + window
		# 倒置硬断言：追踪段 < 技能+走位段
		if chase < cast + window:
			strict_ok += 1
		var ratio: float = chase / total if total > 0.0 else 1.0
		# circle_aoe（phase 100 主循环）目标占比 30-40%；eruption 大招间隔长允许略高但 <50%
		if str(pat.get("skill_id")) == "circle_aoe" and ratio >= 0.30 and ratio <= 0.40:
			invoker_ok += 1
		print("     %s: chase=%.2f cast=%.2f window=%.2f → 追踪占比 %.0f" % [
			str(pat.get("skill_id")), chase, cast, window, ratio * 100.0])
	_check(strict_ok == 3, "§3/split: 3 行全部追踪段 < 技能+走位段（时间分配倒置，实得 %d）" % strict_ok)
	_check(invoker_ok == 2, "§3/split: circle_aoe×2（invoker/predator）追踪占比 ∈[30,40]（实得 %d）" % invoker_ok)
	_check(strict_ok >= 3 and invoker_ok >= 2, "§3/split: 综合倒置达标（数据可调，方向正确）")

## §4 大范围技能权重主导：circle 系 > 贴身追击（charge/突进）
func _s4_wide_weight() -> void:
	print("-- §4 大范围权重 --")
	var data: Dictionary = _load_json("res://data/boss_patterns.json")
	var patterns: Array = data.get("patterns", [])
	var circle_weight := 0.0
	var melee_weight := 0.0
	for p in patterns:
		var sid: String = str(p.get("skill_id", ""))
		var w: float = float(p.get("weight", 1.0))
		if sid.begins_with("circle") or sid.begins_with("fan") or sid.begins_with("beam"):
			circle_weight += w
		elif sid.begins_with("charge") or sid.begins_with("dash") or sid.begins_with("rush"):
			melee_weight += w
	_check(circle_weight > 0.0, "§4/wide: 大范围（circle/fan/beam）总权重 > 0（实得 %.1f）" % circle_weight)
	_check(melee_weight == 0.0, "§4/wide: 贴身追击（charge/突进）零权重（实得 %.1f）" % melee_weight)

## §5 公平底线零破坏（BOSS_SKILL_SPEC §2.2：t_w > 2r/v + 0.4s）
func _s5_fair_telegraph() -> void:
	print("-- §5 公平底线 --")
	var exec_script: GDScript = load("res://scripts/boss/skill_executor.gd")
	if exec_script == null:
		_check(false, "§5/fair: skill_executor 加载失败")
		return
	var floor_120: float = float(exec_script.call("fair_telegraph", 120.0, 300.0))
	_check(floor_120 >= 1.2 - 0.001, "§5/fair: fair_telegraph(120,300) = %.3f ≥ 1.2s 锚点" % floor_120)
	var sk_data: Dictionary = _load_json("res://data/boss_skills.json")
	var skills: Dictionary = sk_data.get("skills", {})
	var all_ok := true
	for sid in skills:
		var skill: Dictionary = skills[sid]
		var r: float = float(skill.get("radius", 120.0))
		var tw: float = float(skill.get("telegraph", 0.8))
		var floor: float = float(exec_script.call("fair_telegraph", r, 300.0))
		if tw + 0.001 < floor:
			all_ok = false
	_check(all_ok, "§5/fair: 全部技能 telegraph ≥ 公平底线（circle_aoe 1.2≥1.2 / circle_eruption 1.5≥1.4）")
	# 难度缩放钳制：coeff 2.0 → telegraph 缩短但不破底线
	var params: Dictionary = {"damage": 30.0, "radius": 120.0, "telegraph": 1.2}
	exec_script.call("scale_params_by_difficulty", params, 2.0, 300.0)
	var scaled_floor: float = float(exec_script.call("fair_telegraph", float(params.get("radius", 120.0)), 300.0))
	_check(float(params.get("telegraph", 0.0)) >= scaled_floor - 0.001,
		"§5/fair: 难度×2 缩短 telegraph 受底线钳制（%.2f ≥ %.2f）" % [float(params.get("telegraph", 0.0)), scaled_floor])

## §6 节奏状态机：executor done → cooldown=cd×chase_ratio + window 入位；window 不 pick；归零新 pick
func _s6_state_machine() -> void:
	print("-- §6 节奏状态机 --")
	var pair: Array = _mk_boss_and_player()
	var boss: Node = pair[0]
	var p: Node = pair[1]
	boss.call("_pick_and_cast")
	_check(boss.get("_active_executor") != null, "§6/sm: pick 后执行器创建")
	# 驱动 executor 至 done（施放总长 ≈ 1.2+0.5+0.3 = 2.0s；0.1×40 = 4.0s 足够）
	for i in range(40):
		boss.call("_process_boss_patterns", 0.1)
		if boss.get("_active_executor") == null:
			break
	var cd_val: float = float(boss.get("_pattern_cooldown"))
	var win_val: float = float(boss.get("_pattern_window_timer"))
	_check(absf(cd_val - 1.6) < 0.001, "§6/sm: done → 追踪冷却 = 8×0.2 = 1.6s（实得 %.3f）" % cd_val)
	_check(absf(win_val - 1.0) < 0.001, "§6/sm: done → 走位窗口 = 1.0s（实得 %.3f）" % win_val)
	# 走位期推进（窗口内不 pick）
	boss.call("_process_boss_patterns", 0.4)
	_check(absf(float(boss.get("_pattern_window_timer")) - 0.6) < 0.001,
		"§6/sm: 走位期递减（1.0→0.6，实得 %.2f）" % float(boss.get("_pattern_window_timer")))
	_check(boss.get("_active_executor") == null, "§6/sm: 走位期内不 pick（executor 保持 null）")
	# 走位归零 → 追踪冷却递减 → 归零 → 新 pick
	while float(boss.get("_pattern_window_timer")) > 0.0:
		boss.call("_process_boss_patterns", 0.1)
	var cd_before: float = float(boss.get("_pattern_cooldown"))
	boss.call("_process_boss_patterns", 0.1)
	_check(float(boss.get("_pattern_cooldown")) < cd_before,
		"§6/sm: 追踪冷却递减（%.2f → %.2f）" % [cd_before, float(boss.get("_pattern_cooldown"))])
	while float(boss.get("_pattern_cooldown")) > 0.0 and boss.get("_active_executor") == null:
		boss.call("_process_boss_patterns", 0.1)
	# cooldown 恰好递减到 0 的那帧 return（原冷却门禁语义），下一帧才 pick
	boss.call("_process_boss_patterns", 0.1)
	_check(boss.get("_active_executor") != null, "§6/sm: 追踪归零 → 重新施放（新 executor 创建）")
	# 保底不连续回归抽样：推进 P2（双技能池）后 pick 换技能
	boss.call("_transition_phase", 1)
	var last: String = str(boss.get("_last_pattern_skill"))
	boss.set("_active_executor", null)
	boss.set("_pattern_cooldown", 0.0)
	boss.set("_pattern_window_timer", 0.0)
	boss.call("_pick_and_cast")
	_check(str(boss.get("_last_pattern_skill")) != last,
		"§6/sm: 保底不连续（P2 双池：%s → %s）" % [last, str(boss.get("_last_pattern_skill"))])
	_cleanup_boss(boss, p)
