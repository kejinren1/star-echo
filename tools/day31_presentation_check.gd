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

	# ④ behavior_map（F1-E 第二批：行为字符串→枚举名映射抽表，原 enemy_enums.gd BEHAVIOR_MAP 数据化）
	var bm_map: Dictionary = {}
	if raw is Dictionary and (raw as Dictionary).get("behavior_map") is Dictionary:
		bm_map = (raw as Dictionary)["behavior_map"]
	var const_bm: Dictionary = EnemyEnums.BEHAVIOR_MAP
	_check(bm_map.size() == const_bm.size(), "behavior_map 条数 %d != const BEHAVIOR_MAP %d" % [bm_map.size(), const_bm.size()])
	var missing_bm := []
	for k in const_bm.keys():
		if not bm_map.has(k):
			missing_bm.append(k)
	_check(missing_bm.is_empty(), "behavior_map 缺 const 键: %s" % str(missing_bm))
	var extra_bm := []
	for k in bm_map.keys():
		if not const_bm.has(k):
			extra_bm.append(k)
	_check(extra_bm.is_empty(), "behavior_map 多余键: %s" % str(extra_bm))
	for k in const_bm.keys():
		var cval: int = int(const_bm[k])
		var pv: Variant = bm_map.get(k, null)
		if not (pv is Dictionary):
			_check(false, "%s behavior_map 条目非字典" % k)
			continue
		var ename: String = str((pv as Dictionary).get("behavior", ""))
		_check(int(EnemyEnums.Behavior.get(ename, -1)) == cval, "%s 枚举名 %s != const %d" % [k, ename, cval])
	# 消费路径：已知行为正确解析 / 未知行为兜底 CHASE / 数据表缺失兜底 const
	if loader != null:
		_check(int(loader.call("get_enemy_behavior", "chase")) == int(EnemyEnums.Behavior.CHASE), "消费 chase 行为错误")
		_check(int(loader.call("get_enemy_behavior", "aoe_attack")) == int(EnemyEnums.Behavior.AOE_ATTACK), "消费 aoe_attack 行为错误")
		_check(int(loader.call("get_enemy_behavior", "unknown_behavior")) == int(EnemyEnums.Behavior.CHASE), "未知行为未兜底 CHASE")

	# ⑤ audio_map（F1-E-3 第三批 2026-08-18 总指挥：BGM/SFX 路径抽表，原 audio_manager.gd
	# BGM_MAP/SFX_MAP 数据化 → presentation.json audio_map；category bgm(2)/sfx(10)；
	# path 与 const 现值逐一一致（抽表零漂移）；消费端 DataLoader.get_audio_config +
	# audio_manager._resolve_audio_path（命中优先/空表回退 const/未知键 push_warning 保留））
	var am_map: Dictionary = {}
	if raw is Dictionary and (raw as Dictionary).get("audio_map") is Dictionary:
		am_map = (raw as Dictionary)["audio_map"]
	var audio_node: Node = root.get_node_or_null("AudioManager")
	var const_bgm2: Dictionary = {}
	var const_sfx: Dictionary = {}
	if audio_node != null:
		const_bgm2 = audio_node.get("BGM_MAP")
		const_sfx = audio_node.get("SFX_MAP")
	_check(audio_node != null, "AudioManager Autoload 缺失（path 零漂移对比不可用）")
	_check(am_map.size() == 12, "audio_map 条数 %d != 12" % am_map.size())
	var bgm_keys: Array = ["menu", "battle"]
	var sfx_keys: Array = ["hit", "crit", "death", "levelup", "coin",
		"shop", "skill", "heal", "event", "boss"]
	var bgm_cat_ok: bool = true
	for k in bgm_keys:
		if not (am_map.has(k) and str(am_map[k].get("category", "")) == "bgm"):
			bgm_cat_ok = false
	_check(bgm_cat_ok, "audio_map 缺 bgm 键或类别错: menu/battle")
	var sfx_cat_ok: bool = true
	for k in sfx_keys:
		if not (am_map.has(k) and str(am_map[k].get("category", "")) == "sfx"):
			sfx_cat_ok = false
	_check(sfx_cat_ok, "audio_map 缺 sfx 键或类别错（10 键）")
	if audio_node != null:
		var drift_bgm := []
		for k in bgm_keys:
			if str(am_map.get(k, {}).get("path", "")) != str(const_bgm2.get(k, "")):
				drift_bgm.append("bgm/%s" % k)
		_check(drift_bgm.is_empty(), "audio_map bgm path 与 const 漂移: %s" % str(drift_bgm))
		var drift_sfx := []
		for k in sfx_keys:
			if str(am_map.get(k, {}).get("path", "")) != str(const_sfx.get(k, "")):
				drift_sfx.append("sfx/%s" % k)
		_check(drift_sfx.is_empty(), "audio_map sfx path 与 const 漂移: %s" % str(drift_sfx))
	# 消费接口：get_audio_config 白盒 12 键
	if loader != null:
		var am_cfg: Dictionary = loader.call("get_audio_config")
		_check(am_cfg.size() == 12, "get_audio_config 键数 %d != 12" % am_cfg.size())
		_check(str(am_cfg.get("hit", {}).get("path", "")) == "res://assets/audio/sfx/hit.wav", "get_audio_config hit path 错误")
		# 兜底语义：_audio_map 仅含 1 键（模拟数据表缺 menu）→ 未命中回退 const；
		# 命中键优先走 audio_map（两分支各一断言）
		var am_partial: Dictionary = {"hit": {"category": "sfx", "path": "res://assets/audio/sfx/hit.wav"}}
		loader.set("_audio_map", am_partial)
		if audio_node != null:
			var fb: String = audio_node.call("_resolve_audio_path", "menu", const_bgm2)
			_check(fb == "res://assets/audio/bgm/bgm_menu.wav", "数据缺键兜底回退 const 失败: %s" % fb)
			var fb_ok: String = audio_node.call("_resolve_audio_path", "hit", const_sfx)
			_check(fb_ok == "res://assets/audio/sfx/hit.wav", "数据命中应优先 audio_map: %s" % fb_ok)
		loader.set("_audio_map", am_cfg)  # 还原缓存防污染
		# 未知键 push_warning 保留（play_sfx 未知名返回 false）
		if audio_node != null:
			_check(not bool(audio_node.call("play_sfx", "no_such_sfx")), "未知 SFX 应返回 false（push_warning 保留）")
			# 两源均缺失 → 空串（_ensure_stream load("") 失败 push_warning 零崩兜底路径）
			var fb_miss: String = audio_node.call("_resolve_audio_path", "no_such_key", {})
			_check(fb_miss == "", "两源均缺失应返回空串: %s" % fb_miss)

	# ⑥ fx_config（F1-E-4 第四批 2026-08-19 #3 执行：特效帧配置抽表，原 vfx_player.gd
	# const FX_CONFIG 数据化 → presentation.json fx_config（size_w/size_h → size 组装）；
	# path/frames/fps/size 与 const 现值逐一一致（抽表零漂移）；消费端
	# DataLoader.get_fx_config + vfx_player.set_effect（命中优先/空表回退 const/
	# 未知键 push_warning 保留）；FX_CONFIG const 保留兜底 = day23_vfx_check §1 零改动）
	var fx_map: Dictionary = {}
	if raw is Dictionary and (raw as Dictionary).get("fx_config") is Dictionary:
		fx_map = (raw as Dictionary)["fx_config"]
	var vfx_script: GDScript = load("res://scripts/effects/vfx_player.gd")
	var const_fx: Dictionary = vfx_script.FX_CONFIG
	_check(fx_map.size() == const_fx.size(), "fx_config 条数 %d != const FX_CONFIG %d" % [fx_map.size(), const_fx.size()])
	var missing_fx := []
	for k in const_fx.keys():
		if not fx_map.has(k):
			missing_fx.append(k)
	_check(missing_fx.is_empty(), "fx_config 缺 const 键: %s" % str(missing_fx))
	var extra_fx := []
	for k in fx_map.keys():
		if not const_fx.has(k):
			extra_fx.append(k)
	_check(extra_fx.is_empty(), "fx_config 多余键: %s" % str(extra_fx))
	var drift_fx := []
	for k in const_fx.keys():
		var c: Dictionary = const_fx[k]
		var p: Dictionary = fx_map.get(k, {})
		if str(p.get("path", "")) != str(c.get("path", "")):
			drift_fx.append("%s/path" % k)
		if int(p.get("frames", -1)) != int(c.get("frames", -1)):
			drift_fx.append("%s/frames" % k)
		if not is_equal_approx(float(p.get("fps", -1.0)), float(c.get("fps", -1.0))):
			drift_fx.append("%s/fps" % k)
		var psz: Variant = p.get("size", null)
		var csz: Vector2i = c.get("size")
		if not (psz is Dictionary and int(psz.get("x", -1)) == csz.x and int(psz.get("y", -1)) == csz.y):
			drift_fx.append("%s/size" % k)
	_check(drift_fx.is_empty(), "fx_config 与 const 漂移: %s" % str(drift_fx))
	# 消费接口：get_fx_config 命中 → {path, frames, fps, size: Vector2i} 组装
	if loader != null:
		var fx_hit: Dictionary = loader.call("get_fx_config", "hit")
		_check(fx_hit.size() >= 4, "get_fx_config('hit') 键不齐: %s" % str(fx_hit))
		_check(str(fx_hit.get("path", "")) == "res://assets/sprites/effects/fx_hit.png", "get_fx_config hit path 错误")
		_check(int(fx_hit.get("frames", -1)) == 4, "get_fx_config hit frames 错误: %s" % str(fx_hit.get("frames")))
		_check(fx_hit.get("size") is Vector2i and fx_hit["size"] == Vector2i(32, 32), \
			"get_fx_config hit size 非 Vector2i(32,32): %s" % str(fx_hit.get("size")))
		_check(loader.call("get_fx_config", "meteor").get("size") == Vector2i(128, 128), "get_fx_config meteor size 错误")
		_check(loader.call("get_fx_config", "no_such_fx").is_empty(), "未知名 get_fx_config 应返回空字典")
		# 端到端双跑（白盒等价）：_fx_map 注入改值 → 返回值变化 → 还原
		var fx_orig: Dictionary = loader.get("_fx_map")
		var fx_mut: Dictionary = (fx_orig.duplicate(true))
		var hit_cfg: Dictionary = (fx_mut.get("hit", {}) as Dictionary).duplicate()
		hit_cfg["frames"] = 99
		fx_mut["hit"] = hit_cfg
		loader.set("_fx_map", fx_mut)
		_check(int(loader.call("get_fx_config", "hit").get("frames", -1)) == 99, "白盒改 frames 未生效（端到端双跑失败）")
		loader.set("_fx_map", fx_orig)  # 还原缓存防污染
		# 空表兜底：_fx_map 清空 → set_effect 回退 const 仍可播（VfxPlayer 白盒）
		var vfx: Node = (load("res://scenes/VfxPlayer.tscn") as PackedScene).instantiate()
		root.add_child(vfx)
		loader.set("_fx_map", {})
		vfx.call("set_effect", "hit")
		_check(str(vfx.get("current_fx")) == "hit", "空表兜底 set_effect('hit') current_fx 应写入")
		loader.set("_fx_map", fx_orig)  # 还原缓存防污染
		vfx.queue_free()
		# 未知键 push_warning 保留（set_effect 未知名 current_fx 不写）
		var vfx2: Node = (load("res://scenes/VfxPlayer.tscn") as PackedScene).instantiate()
		root.add_child(vfx2)
		vfx2.call("set_effect", "definitely_not_a_fx")
		_check(str(vfx2.get("current_fx")) == "", "未知特效名不应写 current_fx（push_warning 保留）")
		vfx2.queue_free()

	# ⑦ T-004 starting_gun 数据侧（F1-E-6 第六批 2026-08-19 #3 执行：weapons.json 抽表
	#    —— 与 _equip_default_weapon 内联现值 9 键零漂移 + source_id 缺失 +
	#    projectile_speed/lifetime 两键不进表（build_weapon_from_data :162 无消费方）；
	#    max_level=1 方案裁决（初始枪不升级、退出升级候选池））
	var sg_data: Dictionary = loader.call("get_weapon", "starting_gun")
	_check(not sg_data.is_empty(), "weapons.json 缺 starting_gun")
	if not sg_data.is_empty():
		_check(str(sg_data.get("name", "")) == "初始枪", "starting_gun name 漂移: %s" % str(sg_data.get("name")))
		_check(float(sg_data.get("damage", -1)) == 8.0, "starting_gun damage != 8: %s" % str(sg_data.get("damage")))
		_check(float(sg_data.get("cooldown", -1)) == 0.4, "starting_gun cooldown != 0.4（↔ fire_rate 2.5）")
		_check(float(sg_data.get("range", -1)) == 180.0, "starting_gun range != 180")
		_check(float(sg_data.get("knockback", -1)) == 0.0, "starting_gun knockback != 0")
		_check(int(sg_data.get("max_level", -1)) == 1, "starting_gun max_level != 1（方案裁决单级）")
		_check(not sg_data.has("projectile_speed") and not sg_data.has("lifetime"), \
			"starting_gun 不应含 projectile_speed/lifetime 两键（builder :162 无消费方，F1-G 死键先例）")
		_check(not sg_data.has("source_id"), "starting_gun 不应含 source_id 键（day13 硬门槛）")
		# 装配 9 键等价（build_weapon_from_data + 补设两键 = 内联现值，⭐第 34 轮裁决）
		var wc9: Node = (load("res://scripts/weapons/weapon_controller.gd") as GDScript).new()
		var w9: Resource = wc9.call("build_weapon_from_data", "starting_gun")
		_check(w9 != null, "build_weapon_from_data(starting_gun) 返回 null")
		if w9 != null:
			w9.projectile_speed = 360.0
			w9.lifetime = 1.5
			_check(str(w9.weapon_name) == "初始枪", "装配 weapon_name 漂移")
			_check(str(w9.weapon_type) == "ranged", "装配 weapon_type != ranged")
			_check(is_equal_approx(float(w9.base_damage), 8.0), "装配 base_damage != 8")
			_check(is_equal_approx(float(w9.fire_rate), 2.5), "装配 fire_rate != 2.5")
			_check(is_equal_approx(float(w9.projectile_speed), 360.0), "装配 projectile_speed != 360（补设）")
			_check(is_equal_approx(float(w9.attack_range), 180.0), "装配 attack_range != 180")
			_check(is_equal_approx(float(w9.lifetime), 1.5), "装配 lifetime != 1.5（补设）")
			_check(int(w9.pierce) == 0, "装配 pierce != 0")
			_check(is_equal_approx(float(w9.knockback), 0.0), "装配 knockback != 0")

	# ⑧ skill_icon_map（F1-E-6 第六批 2026-08-19 #3 执行：技能图标映射抽表，
	#    原 hud.gd const SKILL_ICON_MAP 数据化 → presentation.json skill_icon_map；
	#    icon_index 与 const 现值逐一一致（抽表零漂移）；消费端 DataLoader.get_skill_icon_index
	#    + hud._resolve_skill_icon_index（命中优先/空表回退 const/未知 id push_warning 保留）；
	#    SKILL_ICON_MAP const 保留兜底 = day31_skill_icon_check §5 直读零改动硬门槛）
	var sim_map: Dictionary = {}
	if raw is Dictionary and (raw as Dictionary).get("skill_icon_map") is Dictionary:
		sim_map = (raw as Dictionary)["skill_icon_map"]
	var hud_script2: GDScript = load("res://scripts/ui/hud.gd")
	var icon_const: Dictionary = hud_script2.SKILL_ICON_MAP
	_check(sim_map.size() == icon_const.size(), "skill_icon_map 条数 %d != const SKILL_ICON_MAP %d" % [sim_map.size(), icon_const.size()])
	var sim_missing := []
	for k in icon_const.keys():
		if not sim_map.has(k):
			sim_missing.append(k)
	_check(sim_missing.is_empty(), "skill_icon_map 缺 const 键: %s" % str(sim_missing))
	var sim_extra := []
	for k in sim_map.keys():
		if not icon_const.has(k):
			sim_extra.append(k)
	_check(sim_extra.is_empty(), "skill_icon_map 多余键: %s" % str(sim_extra))
	var sim_drift := []
	for k in icon_const.keys():
		if int(sim_map.get(k, -1)) != int(icon_const.get(k, -1)):
			sim_drift.append(k)
	_check(sim_drift.is_empty(), "skill_icon_map 与 const 不一致: %s" % str(sim_drift))
	# 消费接口白盒
	_check(int(loader.call("get_skill_icon_index", "se_skill_fireball")) == 0, "get_skill_icon_index(fireball) != 0")
	_check(int(loader.call("get_skill_icon_index", "se_skill_sword_arc")) == 4, "get_skill_icon_index(sword_arc) != 4")
	_check(int(loader.call("get_skill_icon_index", "relic_dash")) == -1, "get_skill_icon_index(未知名) != -1")
	# 端到端双跑（白盒等价）：_skill_icon_map 注入改值 → 返回值变化 → 还原
	var sim_orig: Dictionary = loader.get("_skill_icon_map")
	var sim_mut: Dictionary = (sim_orig.duplicate(true))
	sim_mut["se_skill_fireball"] = 3
	loader.set("_skill_icon_map", sim_mut)
	_check(int(loader.call("get_skill_icon_index", "se_skill_fireball")) == 3, "白盒改 icon_index 未生效（端到端双跑失败）")
	loader.set("_skill_icon_map", sim_orig)  # 还原缓存防污染
	# 空表兜底：_skill_icon_map 清空 → _resolve_skill_icon_index 回退 const 仍映射
	var hud3: Node = hud_script2.new()
	loader.set("_skill_icon_map", {})
	_check(int(hud3.call("_resolve_skill_icon_index", "se_skill_fireball")) == 0, "空表兜底 const 仍映射 fireball==0")
	loader.set("_skill_icon_map", sim_orig)
	# 未知 id push_warning 保留（_apply_skill_icon 槽 0：texture 保持 null）
	var hud4: Node = hud_script2.new()
	hud4.set("skill_slot", TextureRect.new())
	var sc4: Node = (load("res://scripts/player/skill_controller.gd") as GDScript).new()
	sc4.set("skill_data", {"id": "relic_dash"})
	hud4.call("_apply_skill_icon", sc4)
	_check(hud4.get("skill_slot").texture == null, "未知 id 槽 0 图标保持 null（push_warning 保留）")
	# 槽 1/2 掉落技能未映射 → 灰显不变
	var hud5: Node = hud_script2.new()
	var slots5: Array = [{"slot": TextureRect.new(), "label": Label.new()}]
	hud5.set("_skill_slots", slots5)
	var sc5: Node = (load("res://scripts/player/skill_controller.gd") as GDScript).new()
	sc5.set("skills", [{"id": "relic_dash"}])
	hud5.call("_apply_skill_slot_icon", sc5, 0)
	_check(slots5[0].get("slot").texture == null, "掉落技能未映射 → 灰显不变（texture null）")

	# ⑨ turret_config（F1-E-7 第七批 2026-08-19 #3 执行：炮台默认值抽表，
	#    原 turret.gd 字段声明默认值 + setup() 装载兜底两处散落数据化 →
	#    presentation.json turret_config；三键数值与 const TURRET_DEFAULTS
	#    现值逐一一致（抽表零漂移）；消费端 DataLoader.get_turret_config +
	#    turret._resolve_turret_defaults（命中优先/空表回退 const/weapon_data 优先）；
	#    TURRET_DEFAULTS const 保留兜底 = day13 炮台段 6b 零改动硬门槛）
	var tc_map: Dictionary = {}
	if raw is Dictionary and (raw as Dictionary).get("turret_config") is Dictionary:
		tc_map = (raw as Dictionary)["turret_config"]
	var turret_script9: GDScript = load("res://scripts/weapons/turret.gd")
	var tc_const: Dictionary = turret_script9.TURRET_DEFAULTS
	# 外层 1 键齐（se_auto_turret = 唯一炮台武器键）
	_check(tc_map.size() == 1 and tc_map.has("se_auto_turret"), \
		"turret_config 外层应恰 1 键 se_auto_turret: %s" % str(tc_map.keys()))
	var tc_cfg: Dictionary = tc_map.get("se_auto_turret", {})
	# 内层键集合与 TURRET_DEFAULTS 一致（零多余零缺失）
	var tc_missing := []
	for k in tc_const.keys():
		if not tc_cfg.has(k):
			tc_missing.append(k)
	_check(tc_missing.is_empty(), "se_auto_turret 缺 const 键: %s" % str(tc_missing))
	var tc_extra := []
	for k in tc_cfg.keys():
		if not tc_const.has(k):
			tc_extra.append(k)
	_check(tc_extra.is_empty(), "se_auto_turret 多余键: %s" % str(tc_extra))
	# 三键数值与 const 逐一一致（抽表零漂移）
	var tc_drift := []
	for k in tc_const.keys():
		if not is_equal_approx(float(tc_cfg.get(k, -1.0)), float(tc_const[k])):
			tc_drift.append("%s/%s" % ["se_auto_turret", k])
	_check(tc_drift.is_empty(), "turret_config 与 const 漂移: %s" % str(tc_drift))
	_check(tc_cfg.size() == tc_const.size(), "se_auto_turret 三键不齐: %s" % str(tc_cfg))
	# 消费接口白盒：get_turret_config 命中 → 整表返回 + 三值正确
	_check(loader.call("get_turret_config").has("se_auto_turret"), "get_turret_config 缺 se_auto_turret")
	_check(is_equal_approx(float(loader.call("get_turret_config").get("se_auto_turret", {}).get("fire_interval", -1.0)), 0.5), \
		"get_turret_config fire_interval != 0.5")
	# 端到端双跑（白盒等价）：_turret_map 注入改值 → 返回值变化 → 还原
	var tc_orig: Dictionary = loader.get("_turret_map")
	var tc_mut: Dictionary = (tc_orig.duplicate(true))
	var tc_cfg_mut: Dictionary = (tc_mut.get("se_auto_turret", {}) as Dictionary).duplicate()
	tc_cfg_mut["fire_interval"] = 0.9
	tc_mut["se_auto_turret"] = tc_cfg_mut
	loader.set("_turret_map", tc_mut)
	_check(is_equal_approx(float(loader.call("get_turret_config").get("se_auto_turret", {}).get("fire_interval", -1.0)), 0.9), \
		"白盒改 fire_interval 未生效（端到端双跑失败）")
	loader.set("_turret_map", tc_orig)  # 还原缓存防污染
	# 空表兜底：_turret_map 清空重载 → turret.setup 空 weapon_data 回退 const 现值仍可跑不崩
	var turret9: Node = turret_script9.new()
	root.add_child(turret9)
	loader.set("_turret_map", {})
	turret9.call("setup", {}, 5.0, null)
	_check(is_equal_approx(float(turret9.get("damage")), 5.0), "空表兜底 setup damage != 5.0")
	_check(is_equal_approx(float(turret9.get("fire_interval")), 0.5), "空表兜底 setup fire_interval != 0.5")
	_check(is_equal_approx(float(turret9.get("attack_range")), 220.0), "空表兜底 setup attack_range != 220.0")
	loader.set("_turret_map", tc_orig)  # 还原缓存防污染
	# 未知武器 id 回退 const（表内无该武器键 → _resolve_turret_defaults 回退 TURRET_DEFAULTS）
	loader.set("_turret_map", {"no_such_turret": {"damage": 1.0}})
	var d9: Dictionary = turret9.call("_resolve_turret_defaults")
	_check(is_equal_approx(float(d9.get("damage", -1.0)), 5.0), "未知武器 id 未回退 const: %s" % str(d9))
	loader.set("_turret_map", tc_orig)  # 还原缓存防污染
	# 字段声明值 = const（编译期一致）
	var turret10: Node = turret_script9.new()
	_check(is_equal_approx(float(turret10.get("damage")), float(tc_const["damage"])), "字段声明 damage != const")
	_check(is_equal_approx(float(turret10.get("fire_interval")), float(tc_const["fire_interval"])), "字段声明 fire_interval != const")
	_check(is_equal_approx(float(turret10.get("attack_range")), float(tc_const["attack_range"])), "字段声明 attack_range != const")
	# weapon_data 优先（表值被 setup 传入数据覆盖）
	var turret11: Node = turret_script9.new()
	root.add_child(turret11)
	turret11.call("setup", {"damage": 9.0, "cooldown": 0.3, "range": 150.0}, 5.0, null)
	_check(is_equal_approx(float(turret11.get("damage")), 9.0), "weapon_data.damage 9.0 未优先")
	_check(is_equal_approx(float(turret11.get("fire_interval")), 0.3), "weapon_data.cooldown 0.3 未优先")
	_check(is_equal_approx(float(turret11.get("attack_range")), 150.0), "weapon_data.range 150 未优先")

	# ⑩ icon_config（F1-E-5 第五批 2026-08-19 #3 执行：图标集帧配置抽表，
	#    原 icon_atlas.gd const SHEET_CONFIG 数据化 → presentation.json icon_config；
	#    path/frame_count/frame_size 与 const 现值逐一一致（抽表零漂移）；消费端
	#    DataLoader.get_icon_config + IconAtlas._resolve_icon_config（命中优先/
	#    空表回退 const/未知 sheet push_warning 保留）；SHEET_CONFIG const 保留兜底
	#    = day31_items_atlas_check/day31_skill_icon_check 直读 const 零改动硬门槛）
	var ic_map: Dictionary = {}
	if raw is Dictionary and (raw as Dictionary).get("icon_config") is Dictionary:
		ic_map = (raw as Dictionary)["icon_config"]
	var icon_script5: GDScript = load("res://scripts/utils/icon_atlas.gd")
	var ic_const: Dictionary = icon_script5.SHEET_CONFIG
	_check(ic_map.size() == ic_const.size(), "icon_config 条数 %d != const SHEET_CONFIG %d" % [ic_map.size(), ic_const.size()])
	var ic_missing := []
	for k in ic_const.keys():
		if not ic_map.has(k):
			ic_missing.append(k)
	_check(ic_missing.is_empty(), "icon_config 缺 const 键: %s" % str(ic_missing))
	var ic_extra := []
	for k in ic_map.keys():
		if not ic_const.has(k):
			ic_extra.append(k)
	_check(ic_extra.is_empty(), "icon_config 多余键: %s" % str(ic_extra))
	# 逐键 path/frame_count/frame_size 与 const 现值逐一一致（抽表零漂移）
	var ic_drift := []
	for k in ic_const.keys():
		var c: Dictionary = ic_const[k]
		var p: Dictionary = ic_map.get(k, {})
		if str(p.get("path", "")) != str(c.get("path", "")):
			ic_drift.append("%s/path" % k)
		if int(p.get("frame_count", -1)) != int(c.get("frame_count", -1)):
			ic_drift.append("%s/frame_count" % k)
		var pfs: Variant = p.get("frame_size", null)
		var cfs: Vector2i = c.get("frame_size")
		if not (pfs is Dictionary and int(pfs.get("x", -1)) == cfs.x and int(pfs.get("y", -1)) == cfs.y):
			ic_drift.append("%s/frame_size" % k)
	_check(ic_drift.is_empty(), "icon_config 与 const 漂移: %s" % str(ic_drift))
	# 消费接口：get_icon_config 命中 → {path, frame_count, frame_size: Vector2i} 组装
	if loader != null:
		var ic_hit: Dictionary = loader.call("get_icon_config", "items")
		_check(ic_hit.size() >= 3, "get_icon_config('items') 键不齐: %s" % str(ic_hit))
		_check(str(ic_hit.get("path", "")) == "res://assets/sprites/ui/items.png", "get_icon_config items path 错误")
		_check(int(ic_hit.get("frame_count", -1)) == 54, "get_icon_config items frame_count 错误: %s" % str(ic_hit.get("frame_count")))
		_check(ic_hit.get("frame_size") is Vector2i and ic_hit["frame_size"] == Vector2i(32, 32), \
			"get_icon_config items frame_size 非 Vector2i(32,32): %s" % str(ic_hit.get("frame_size")))
		_check(loader.call("get_icon_config", "no_such_sheet").is_empty(), "未知名 get_icon_config 应返回空字典")
		# 端到端双跑（白盒等价）：_icon_map 注入改值 → 返回值变化 → 还原
		var ic_orig: Dictionary = loader.get("_icon_map")
		var ic_mut: Dictionary = (ic_orig.duplicate(true))
		var items_cfg: Dictionary = (ic_mut.get("items", {}) as Dictionary).duplicate()
		items_cfg["frame_count"] = 99
		ic_mut["items"] = items_cfg
		loader.set("_icon_map", ic_mut)
		_check(int(loader.call("get_icon_config", "items").get("frame_count", -1)) == 99, "白盒改 frame_count 未生效（端到端双跑失败）")
		loader.set("_icon_map", ic_orig)  # 还原缓存防污染
		# 空表兜底：_icon_map 清空 → IconAtlas 回退 const 仍可 get_icon（load 不崩）
		loader.set("_icon_map", {})
		IconAtlas.clear_cache()
		var ic_at: AtlasTexture = IconAtlas.get_icon("items", 0)
		_check(ic_at != null, "空表兜底 get_icon('items',0) 应回退 const 非空")
		loader.set("_icon_map", ic_orig)  # 还原缓存防污染
		# 未知 sheet push_warning 保留（get_icon 未知名返回 null）
		var ic_unknown: AtlasTexture = IconAtlas.get_icon("no_such_sheet", 0)
		_check(ic_unknown == null, "未知 sheet get_icon 应返回 null（push_warning 保留）")
		# get_frame_count 行为一致（抽表命中 = const 现值）
		_check(IconAtlas.get_frame_count("items") == 54, "get_frame_count('items') != 54")
		_check(IconAtlas.get_frame_count("skills") == 5, "get_frame_count('skills') != 5")
		_check(IconAtlas.get_frame_count("no_such_sheet") == 0, "get_frame_count 未知 sheet != 0")
