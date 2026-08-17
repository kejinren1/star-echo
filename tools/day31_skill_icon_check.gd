extends SceneTree
## 技能图标映射闭环验证探针（总指挥 08-18 补 se_skill_sword_arc 后新增）：
## ① skills.png 图集 = 160×32 五帧 ② IconAtlas skills.frame_count==5 ③ 5 帧全可加载非空
## ④ 越界拦截 ⑤ hud.gd SKILL_ICON_MAP 覆盖 data 中全部 se_skill_* 技能 id（键↔帧索引有效）
## 驱动范式：_process 首帧执行 + 显式 quit（--script 探针三坑规避）

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
	# ① 图集物理尺寸：128×32(4帧) → 160×32(5帧)
	var cfg: Dictionary = IconAtlas.SHEET_CONFIG["skills"]
	var tex: Texture2D = load(cfg["path"])
	_check(tex != null, "skills.png 加载失败")
	var img: Image = null
	if tex != null:
		img = tex.get_image()
		_check(img != null and img.get_width() == 160 and img.get_height() == 32, \
			"skills.png 尺寸 %s != 160×32（应为 5 帧 32px）" % (str(img.get_size()) if img else "null"))
	# ② 帧数配置
	_check(int(cfg["frame_count"]) == 5, "IconAtlas skills.frame_count=%s != 5" % str(cfg.get("frame_count")))
	_check(IconAtlas.get_frame_count("skills") == 5, "get_frame_count(skills)=%d != 5" % IconAtlas.get_frame_count("skills"))
	# ③ 5 帧全部可加载非空
	if img != null:
		for i in range(5):
			var at: AtlasTexture = IconAtlas.get_icon("skills", i)
			_check(at != null, "skills[%d] 图标为 null" % i)
			if at != null:
				var frame := img.get_region(at.region)
				var has_pixel := false
				for y in range(frame.get_height()):
					for x in range(frame.get_width()):
						if frame.get_pixel(x, y).a > 0.5:
							has_pixel = true
							break
					if has_pixel:
						break
				_check(has_pixel, "skills[%d] 帧为空图" % i)
	# ④ 越界防护：索引 5 应返回 null
	_check(IconAtlas.get_icon("skills", 5) == null, "skills[5] 越界未拦截")
	# ⑤ hud.gd SKILL_ICON_MAP 覆盖 data 全部技能 id（se_skill_*）
	var hud_script: GDScript = load("res://scripts/ui/hud.gd")
	_check(hud_script != null, "hud.gd 加载失败")
	if hud_script != null:
		var icon_map: Dictionary = hud_script.SKILL_ICON_MAP
		var skill_ids: Array = []
		for f in ["res://data/characters.json"]:
			var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(f))
			for ch in (d.get("characters", []) as Array):
				var skill: Variant = ch.get("skill", null)
				if skill is Dictionary:
					var sid: String = str((skill as Dictionary).get("id", ""))
					if sid.begins_with("se_skill_") and not skill_ids.has(sid):
						skill_ids.append(sid)
		skill_ids.sort()
		var missing := []
		for sid in skill_ids:
			if not icon_map.has(sid):
				missing.append(sid)
		_check(missing.is_empty(), "SKILL_ICON_MAP 缺技能 id: %s" % str(missing))
		for sid in skill_ids:
			var idx := int(icon_map.get(sid, -1))
			_check(idx >= 0 and idx < int(cfg["frame_count"]), \
				"SKILL_ICON_MAP[%s]=%d 帧索引越界(共 %d 帧)" % [sid, idx, int(cfg["frame_count"])])
		_check(int(icon_map.get("se_skill_sword_arc", -1)) == 4, "se_skill_sword_arc 未映射到帧 4")
