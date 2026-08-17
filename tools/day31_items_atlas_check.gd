extends SceneTree
## items 图集 54 帧验证探针（2026-08-15 道具重建）：IconAtlas.get_icon("items", 0..53)
## 每帧 AtlasTexture 有效 + 纹理区域非空（有图标内容）→ 防止图集与 icon_index 脱节

var _checked := 0
var _failures := 0

func _init() -> void:
	# 数据层：items.json 54 项 icon_index 0-53 连续
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/items.json"))
	var arr: Array = data["items"]
	_checked += 1
	if arr.size() != 54:
		_failures += 1
		print("XX items.json 条目数 %d != 54" % arr.size())
	var idxs := []
	for it in arr:
		idxs.append(int(it.get("icon_index", -1)))
	var expect := []
	for i in range(54):
		expect.append(i)
	_checked += 1
	if idxs != expect:
		_failures += 1
		print("XX icon_index 非 0-53 连续: %s" % str(idxs))
	# IconAtlas 层：54 帧全部可加载且非空
	var cfg: Dictionary = IconAtlas.SHEET_CONFIG["items"]
	var tex: Texture2D = load(cfg["path"])
	_checked += 1
	if tex == null:
		_failures += 1
		print("XX items.png 加载失败")
	else:
		var img := tex.get_image()
		for i in range(54):
			var at: AtlasTexture = IconAtlas.get_icon("items", i)
			_checked += 1
			if at == null:
				_failures += 1
				print("XX items[%d] 图标为 null" % i)
				continue
			var region := at.region
			var frame := img.get_region(region)
			var has_pixel := false
			for y in range(region.size.y):
				for x in range(region.size.x):
					if frame.get_pixel(x, y).a > 0.5:
						has_pixel = true
						break
				if has_pixel:
					break
			if not has_pixel:
				_failures += 1
				print("XX items[%d] 帧为空图" % i)
	# 越界防护：55 应返回 null
	_checked += 1
	if IconAtlas.get_icon("items", 54) != null:
		_failures += 1
		print("XX items[54] 越界未拦截")
	print("\n=== %d assertions, %d failures ===" % [_checked, _failures])
	quit(1 if _failures > 0 else 0)
