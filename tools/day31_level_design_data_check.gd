extends SceneTree
## LEVEL_DESIGN LD-A 数据地基校验（2026-08-19 #3 执行 · 规格 docs/LEVEL_DESIGN_SPEC.md）
## §1 spawn_points.json 结构：11 键（8 边缘 + boss_top + arena_center + ring_outer）三型齐全
## §2 boss_phase_events.json：按 boss_id 分组 + 组内 hp_threshold+seq 升序 + 6 类型覆盖 + param 解析
## §3 DataLoader 三接口：get_spawn_points / get_spawn_set / get_boss_phase_events（缺省回退 + 零崩）
## §4 FK 引用合法性：waves.spawn_set→point_id / boss_phase_events.boss_id→合法集
## §5 waves 示例填值（wave10 boss_top）+ 缺省（wave2 无 spawn_set 键）
## 驱动：_process 首帧执行 + 显式 quit（--script 探针三坑规避）
## 数据来源：excel_export.py 导出产物（data/*.json 为 generated，禁手改——改数据走 Excel）

var _checked := 0
var _failures := 0
var _started := false
var _loader: Node = null

func _check(cond: bool, msg: String) -> void:
	_checked += 1
	if not cond:
		_failures += 1
		print("XX " + msg)

func _process(_delta: float) -> bool:
	if not _started:
		_started = true
		_loader = root.get_node_or_null("DataLoader")
		_check(_loader != null, "§3 DataLoader Autoload 在位")
		_s1_spawn_points()
		_s2_boss_phase_events()
		_s3_interfaces()
		_s4_fk()
		_s5_waves()
		print("\n=== %d assertions, %d failures ===" % [_checked, _failures])
		quit(_failures)
		return true
	return false

func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	return JSON.parse_string(FileAccess.get_file_as_string(path))

func _s1_spawn_points() -> void:
	var raw: Variant = _read_json("res://data/spawn_points.json")
	var sp: Dictionary = {}
	if raw is Dictionary and (raw as Dictionary).get("spawn_points") is Dictionary:
		sp = (raw as Dictionary)["spawn_points"]
	_check(sp.size() == 11, "§1 spawn_points 键数 = 11（实得 %d）" % sp.size())
	var expect_keys := ["north", "south", "east", "west", "ne", "nw", "se", "sw",
			"boss_top", "arena_center", "ring_outer"]
	var keys_ok := true
	for k in expect_keys:
		if not sp.has(k):
			keys_ok = false
	_check(keys_ok, "§1 键集完整（8 边缘 + boss_top + arena_center + ring_outer）")
	var edges := ["north", "south", "east", "west", "ne", "nw", "se", "sw"]
	var edge_ok := true
	for k in edges:
		var p: Dictionary = sp.get(k, {})
		if str(p.get("type", "")) != "edge" or int(p.get("inset", -1)) != 40:
			edge_ok = false
	_check(edge_ok, "§1 8 边缘点 type=edge 且 inset=40（D1 拍板值）")
	var bt: Dictionary = sp.get("boss_top", {})
	_check(str(bt.get("type", "")) == "edge" and str(bt.get("direction", "")) == "north"
			and int(bt.get("inset", -1)) == 60, "§1 boss_top = edge/north/inset60（Boss 正上方登场）")
	var ac: Dictionary = sp.get("arena_center", {})
	_check(str(ac.get("type", "")) == "anchor"
			and absf(float(ac.get("x", -1.0)) - 0.5) < 0.001
			and absf(float(ac.get("y", -1.0)) - 0.45) < 0.001, "§1 arena_center = anchor(0.5,0.45)")
	var ro: Dictionary = sp.get("ring_outer", {})
	_check(str(ro.get("type", "")) == "ring" and int(ro.get("radius", -1)) == 300,
			"§1 ring_outer = ring(radius=300) 圆周均分示例")

func _s2_boss_phase_events() -> void:
	var raw: Variant = _read_json("res://data/boss_phase_events.json")
	var ev: Dictionary = {}
	if raw is Dictionary and (raw as Dictionary).get("events") is Dictionary:
		ev = (raw as Dictionary)["events"]
	_check(ev.size() == 2 and ev.has("invoker") and ev.has("predator"),
			"§2 events 分组 = invoker/predator（实得 %d 组）" % ev.size())
	var inv: Array = ev.get("invoker", [])
	var pre: Array = ev.get("predator", [])
	_check(inv.size() == 4 and pre.size() == 3,
			"§2 invoker %d 条 / predator %d 条" % [inv.size(), pre.size()])
	var sorted_ok := true
	var prev_hp := -1
	var prev_seq := -1
	for e in inv:
		var hp := int(e.get("hp_threshold_percent", -1))
		var sq := int(e.get("seq", -1))
		if hp < prev_hp or (hp == prev_hp and sq < prev_seq):
			sorted_ok = false
		prev_hp = hp
		prev_seq = sq
	_check(sorted_ok, "§2 invoker 组按 hp_threshold+seq 升序（导出侧排序生效）")
	var types: Dictionary = {}
	for bid in ev:
		for e in ev[bid]:
			types[str(e.get("event_type", ""))] = true
	var need := ["banner", "vfx", "sfx", "dialogue", "camera", "buff"]
	var type_ok := true
	for t in need:
		if not types.has(t):
			type_ok = false
	_check(type_ok, "§2 6 类型覆盖（banner/vfx/sfx/dialogue/camera/buff）")
	var b60: Dictionary = {}
	for e in inv:
		if int(e.get("hp_threshold_percent", -1)) == 60 and int(e.get("seq", -1)) == 1:
			b60 = e
	var p60: Variant = b60.get("param", null)
	_check(p60 is Dictionary and str((p60 as Dictionary).get("text", "")) == "狂怒！火力全开",
			"§2 60 阈值 banner param 解析为 Dictionary 且 text 正确")
	_check(int(b60.get("once", 0)) == 1, "§2 once=1 防重标记在位")

func _s3_interfaces() -> void:
	var sp: Variant = _loader.call("get_spawn_points")
	_check(sp is Dictionary and (sp as Dictionary).size() == 11,
			"§3 get_spawn_points() 11 键（实得 %d）" % (sp.size() if sp is Dictionary else -1))
	var set1: Dictionary = _loader.call("get_spawn_set", 1)
	var ss1: Variant = set1.get("spawn_set", null)
	_check(ss1 is Array and (ss1 as Array).size() == 3,
			"§3 get_spawn_set(1) 示例组 3 点位（north/east/ring_outer）")
	_check(str(set1.get("spawn_order", "")) == "sequence", "§3 get_spawn_set(1) spawn_order=sequence")
	var set2: Dictionary = _loader.call("get_spawn_set", 2)
	var ss2: Variant = set2.get("spawn_set", null)
	_check(ss2 is Array and (ss2 as Array).is_empty(),
			"§3 get_spawn_set(2) 无配置 → 空数组（缺省回退零行为变化）")
	_check(str(set2.get("spawn_order", "")) == "sequence", "§3 get_spawn_set(2) spawn_order 缺省 sequence")
	var inv: Variant = _loader.call("get_boss_phase_events", "invoker")
	_check(inv is Array and (inv as Array).size() == 4,
			"§3 get_boss_phase_events(invoker) 4 条（实得 %d）" % (inv.size() if inv is Array else -1))
	var ghost: Variant = _loader.call("get_boss_phase_events", "ghost_boss")
	_check(ghost is Array and (ghost as Array).is_empty(), "§3 get_boss_phase_events(未知) → 空数组零崩")

func _s4_fk() -> void:
	var sp: Dictionary = {}
	var raw_sp: Variant = _read_json("res://data/spawn_points.json")
	if raw_sp is Dictionary and (raw_sp as Dictionary).get("spawn_points") is Dictionary:
		sp = (raw_sp as Dictionary)["spawn_points"]
	var waves: Array = []
	var raw_w: Variant = _read_json("res://data/waves.json")
	if raw_w is Dictionary and (raw_w as Dictionary).get("waves") is Array:
		waves = (raw_w as Dictionary)["waves"]
	var ref_ok := true
	for w in waves:
		var ss: Variant = w.get("spawn_set", null)
		if ss is Array:
			for pid in ss:
				if not sp.has(str(pid)):
					ref_ok = false
	_check(ref_ok, "§4 waves.spawn_set 引用 point_id 全部合法（FK 数据侧）")
	var legal: Dictionary = {}
	var raw_bp: Variant = _read_json("res://data/boss_patterns.json")
	if raw_bp is Dictionary and (raw_bp as Dictionary).get("patterns") is Array:
		for p in (raw_bp as Dictionary)["patterns"]:
			legal[str(p.get("boss_id", ""))] = true
	var raw_en: Variant = _read_json("res://data/enemies.json")
	if raw_en is Dictionary and (raw_en as Dictionary).get("enemies") is Dictionary:
		var cats: Dictionary = (raw_en as Dictionary)["enemies"]
		if cats.has("boss"):
			for e in cats["boss"]:
				legal[str(e.get("id", ""))] = true
	var ev: Dictionary = {}
	var raw_ev: Variant = _read_json("res://data/boss_phase_events.json")
	if raw_ev is Dictionary and (raw_ev as Dictionary).get("events") is Dictionary:
		ev = (raw_ev as Dictionary)["events"]
	var boss_ok := true
	for bid in ev:
		if not legal.has(str(bid)):
			boss_ok = false
	_check(boss_ok, "§4 boss_phase_events boss_id 全部在合法集（boss_patterns ∪ enemies/boss）")

func _s5_waves() -> void:
	var waves: Array = []
	var raw_w: Variant = _read_json("res://data/waves.json")
	if raw_w is Dictionary and (raw_w as Dictionary).get("waves") is Array:
		waves = (raw_w as Dictionary)["waves"]
	var w10: Dictionary = {}
	var w2: Dictionary = {}
	for w in waves:
		var n := int(w.get("wave", -1))
		if n == 10:
			w10 = w
		if n == 2:
			w2 = w
	var ss10: Variant = w10.get("spawn_set", null)
	_check(ss10 is Array and (ss10 as Array).size() == 1 and str((ss10 as Array)[0]) == "boss_top",
			"§5 wave10 Boss 波 spawn_set=[boss_top]（Boss 正上方登场示例）")
	_check(not w2.has("spawn_set"), "§5 wave2 无 spawn_set 键（缺省边缘均匀组零行为变化）")
