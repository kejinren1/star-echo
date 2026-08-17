extends SceneTree
## F1-E 第一批验证探针（总指挥 2026-08-18）：敌人精灵表现抽表闭环
## ① presentation.json enemy_sprites 23 条且键集合 = enemy_enums.gd const SPRITE_MAP
## ② 逐条数据与 const 完全一致（move/death/size/帧数/fps/hit_radius/tint/scale，防抽表漂移）
## ③ DataLoader.get_enemy_sprite_config 消费：命中转 Vector2i/Color/scale；未知 id 按 category 兜底 const
## 驱动范式：_process 首帧执行（Autoload 挂载后 root 可见）+ 显式 quit（--script 探针三坑规避）

const EnemyEnums: GDScript = preload("res://scripts/enemy/enemy_enums.gd")

var _checked := 0
var _failures := 0
var _started := false

func _check(cond: bool, msg: String) -> void:
	_checked += 1
	if not cond:
		_failures += 1
		print("XX " + msg)

func _process(_delta: float) -> bool:
	if _started:
		return false
	_started = true
	_run()
	print("\n=== %d assertions, %d failures ===" % [_checked, _failures])
	quit(_failures)
	return true

func _run() -> void:
	var loader: Node = root.get_node_or_null("DataLoader")
	_check(loader != null, "DataLoader Autoload 缺失")

	# ① 键集合一致性
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/presentation.json"))
	_check(raw is Dictionary and not (raw as Dictionary).is_empty(), "presentation.json 缺失或空")
	var ps_map: Dictionary = {}
	if raw is Dictionary and (raw as Dictionary).get("enemy_sprites") is Dictionary:
		ps_map = (raw as Dictionary)["enemy_sprites"]
	var const_map: Dictionary = EnemyEnums.SPRITE_MAP
	_check(ps_map.size() == const_map.size(), "enemy_sprites 条数 %d != const SPRITE_MAP %d" % [ps_map.size(), const_map.size()])
	var missing_keys := []
	for k in const_map.keys():
		if not ps_map.has(k):
			missing_keys.append(k)
	_check(missing_keys.is_empty(), "presentation.json 缺 const 键: %s" % str(missing_keys))
	var extra_keys := []
	for k in ps_map.keys():
		if not const_map.has(k):
			extra_keys.append(k)
	_check(extra_keys.is_empty(), "presentation.json 多余键: %s" % str(extra_keys))

	# ② 逐条对比（JSON 原始数据 vs const）
	for eid in const_map.keys():
		var c: Dictionary = const_map[eid]
		var p: Dictionary = ps_map[eid]
		_check(str(p.get("move", "")) == str(c.get("move", "")), "%s move 不一致" % eid)
		_check(str(p.get("death", "")) == str(c.get("death", "")), "%s death 不一致" % eid)
		var psz: Variant = p.get("size", null)
		var csz: Vector2i = c.get("size")
		_check(psz is Dictionary and int(psz.get("x", -1)) == csz.x and int(psz.get("y", -1)) == csz.y, \
			"%s size 不一致: %s vs %s" % [eid, str(psz), str(csz)])
		_check(int(p.get("move_frames", -1)) == int(c.get("move_frames", -1)), "%s move_frames 不一致" % eid)
		_check(int(p.get("death_frames", -1)) == int(c.get("death_frames", -1)), "%s death_frames 不一致" % eid)
		_check(float(p.get("move_fps", -1.0)) == float(c.get("move_fps", -1.0)), "%s move_fps 不一致" % eid)
		_check(float(p.get("death_fps", -1.0)) == float(c.get("death_fps", -1.0)), "%s death_fps 不一致" % eid)
		_check(float(p.get("hit_radius", -1.0)) == float(c.get("hit_radius", -1.0)), "%s hit_radius 不一致" % eid)
		var ct: Variant = c.get("tint", null)
		var pt: Variant = p.get("tint", null)
		if ct == null:
			_check(pt == null, "%s tint: const 无但数据有 %s" % [eid, str(pt)])
		else:
			var ok_tint := pt is Array and (pt as Array).size() >= 3 \
				and is_equal_approx(float(pt[0]), (ct as Color).r) \
				and is_equal_approx(float(pt[1]), (ct as Color).g) \
				and is_equal_approx(float(pt[2]), (ct as Color).b)
			_check(ok_tint, "%s tint 不一致: %s vs %s" % [eid, str(pt), str(ct)])
		var cs: Variant = c.get("scale", null)
		var ps2: Variant = p.get("scale", null)
		if cs == null:
			_check(ps2 == null, "%s scale: const 无但数据有 %s" % [eid, str(ps2)])
		else:
			_check(ps2 != null and is_equal_approx(float(ps2), float(cs)), "%s scale 不一致: %s vs %s" % [eid, str(ps2), str(cs)])

	# ③ DataLoader 消费路径
	if loader != null:
		var cfg: Dictionary = loader.call("get_enemy_sprite_config", "chaser", "regular")
		_check(str(cfg.get("move", "")) == "res://assets/sprites/enemies/slime_move.png", "消费 chaser move 错误: %s" % str(cfg.get("move")))
		_check(cfg.get("size") is Vector2i and cfg["size"] == Vector2i(48, 48), "消费 chaser size 非 Vector2i(48,48): %s" % str(cfg.get("size")))
		_check(not cfg.has("tint"), "消费 chaser 不应有 tint")
		var cfg2: Dictionary = loader.call("get_enemy_sprite_config", "charger", "regular")
		_check(cfg2.get("tint") is Color, "消费 charger tint 非 Color: %s" % str(cfg2.get("tint")))
		if cfg2.get("tint") is Color:
			var tc: Color = cfg2["tint"]
			_check(is_equal_approx(tc.r, 0.75) and is_equal_approx(tc.g, 0.85) and is_equal_approx(tc.b, 1.35), \
				"消费 charger tint 值错误: %s" % str(tc))
		var cfg3: Dictionary = loader.call("get_enemy_sprite_config", "bruiser", "regular")
		_check(is_equal_approx(float(cfg3.get("scale", 0.0)), 1.25), "消费 bruiser scale 错误: %s" % str(cfg3.get("scale")))
		_check(cfg3.get("size") is Vector2i and cfg3["size"] == Vector2i(48, 48), "消费 bruiser size 错误")
		var cfg_boss: Dictionary = loader.call("get_enemy_sprite_config", "invoker", "boss")
		_check(cfg_boss.get("size") is Vector2i and cfg_boss["size"] == Vector2i(128, 128), "消费 invoker size 错误: %s" % str(cfg_boss.get("size")))
		var cfg_fb: Dictionary = loader.call("get_enemy_sprite_config", "no_such_enemy", "regular")
		_check(str(cfg_fb.get("move", "")) == "res://assets/sprites/enemies/slime_move.png", "兜底 regular 错误: %s" % str(cfg_fb.get("move")))
		_check(cfg_fb.get("size") is Vector2i and cfg_fb["size"] == Vector2i(48, 48), "兜底 regular size 错误: %s" % str(cfg_fb.get("size")))
		var cfg_fb2: Dictionary = loader.call("get_enemy_sprite_config", "no_such_enemy2", "boss")
		_check(cfg_fb2.get("size") is Vector2i and cfg_fb2["size"] == Vector2i(128, 128), "兜底 boss size 错误: %s" % str(cfg_fb2.get("size")))
