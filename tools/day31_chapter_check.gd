## Day 31 PS-D 出口校验：章节化 routes 数据层（PLAYER_SKILL_SPEC §8）
##
## 用法（无头）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day31_chapter_check.gd
##
## 校验内容（SOLUTION_PLAN 第 24 轮 PS-D4，≥11 断言）：
##   §1 chapters 数据层：routes.json.chapters 存在 4 章 / 每章 layers 合法（1-15 全覆盖无重叠）/
##      章末类型（章1=event / 章2-4=boss）
##   §2 拓扑兼容：chapters 缺省空 → 现行为（boss_layers 三 Boss [6,10,14] 零改动）
##   §3 章界信息：DataLoader.get_routes 读 chapters 可解析（JSON 文本列反序列化正确）
##   §4a 章末事件（D2a-1）：route_generator 真实生成 → 章 1 末层（0-based li=2）= 单 event 节点 +
##      wave_index==0 + 类型 ∈ 合法集
##   §4b 章界显示（D3）：RouteSelectPanel 实例化 + setup → 章界横幅数 == chapters 数 +
##      首章起始层 0 横幅在场
##   §5 一致性护栏（D2b-0）：boss_layers 数组 == chapters 推导的章末 Boss 层集合（两处不同步即红）
##
## 说明：章节化三 Boss 位（boss_layers=[6,10,14] = 章 2/3/4 末层 7/11/15 关）已获用户拍板
## （2026-08-17 00:3x 主窗口「方案②吧。本质就是 3BOSS」），§3 断言随数据同步。
##
## 无头环境特殊约定（沿 day31_skill_* 范式）：Autoload 首帧后经 root 获取
##
## 退出码 0 = 全部通过；非 0 = 失败项数。
extends SceneTree

var _checked: int = 0
var _failures: int = 0
var _started: bool = false
var _loader: Node = null

func _initialize() -> void:
	print("=== Day 31 PS-D chapter check ===")

func _process(_delta: float) -> bool:
	if _started:
		return false
	_started = true
	_loader = root.get_node_or_null("DataLoader")
	if _loader == null:
		_fail("DataLoader Autoload 不可用")
		_report()
		quit(_failures)
		return true
	_section_data()
	_section_layers()
	_section_compat()
	_section_chapter_event()
	_section_chapter_banner()
	_section_consistency()
	_report()
	quit(_failures)
	return true

func _section_data() -> void:
	var routes: Dictionary = _loader.call("get_routes")
	var chapters: Variant = routes.get("chapters", null)
	if chapters is Array and (chapters as Array).size() == 4:
		_checked += 1
		print("  PASS  §1 chapters 4 章定义（数据层）")
	else:
		_fail("chapters 应 4 章, 实得 %s" % str(chapters))
		return
	# 章末类型：章 1 = event（无 Boss），章 2-4 = boss
	var ch: Array = chapters as Array
	if str(ch[0].get("end_type", "")) == "event" \
			and str(ch[1].get("end_type", "")) == "boss" \
			and str(ch[2].get("end_type", "")) == "boss" \
			and str(ch[3].get("end_type", "")) == "boss":
		_checked += 1
		print("  PASS  §1 章末类型（章1=event / 章2-4=boss）")
	else:
		_fail("章末类型异常: %s" % str(ch))

func _section_layers() -> void:
	var routes: Dictionary = _loader.call("get_routes")
	var chapters: Array = routes.get("chapters", [])
	# 层范围合法性：每章 layers 递增且 1-15 全覆盖无重叠
	var seen: Dictionary = {}
	var ok: bool = true
	for ch in chapters:
		var lrs: Array = ch.get("layers", [])
		if lrs.is_empty():
			ok = false
			continue
		for l in lrs:
			var li: int = int(l)
			if li < 1 or li > 15:
				ok = false
			if seen.has(li):
				ok = false
			seen[li] = true
	# 4 章层数 3/4/4/4 = 15 层全覆盖
	if ok and seen.size() == 15:
		_checked += 1
		print("  PASS  §2 4 章层数 3/4/4/4 全覆盖 15 层无重叠")
	else:
		_fail("章节层数拓扑异常（seen=%d）" % seen.size())

func _section_compat() -> void:
	# boss_layers = 章节化三 Boss [6,10,14]（2026-08-17 用户拍板方案②；章 2/3/4 末层 = 第 7/11/15 关）
	var routes: Dictionary = _loader.call("get_routes")
	var bl: Array = routes.get("boss_layers", [])
	var bl_int: Array = []
	for b in bl:
		bl_int.append(int(b))
	if bl_int == [6, 10, 14]:
		_checked += 1
		print("  PASS  §3 boss_layers = 章节化三 Boss [6,10,14]（章 2/3/4 末层）")
	else:
		_fail("boss_layers 应 [6,10,14], 实得 %s" % str(bl_int))
	# chapters JSON 文本列反序列化正确（4 章第一层 = 1）
	var first_layer: int = int((routes.get("chapters", [])[0]).get("layers", [])[0]) if (routes.get("chapters", []) as Array).size() > 0 else -1
	if first_layer == 1:
		_checked += 1
		print("  PASS  §3 chapters JSON 解析正确（章1 起始层 = 1）")
	else:
		_fail("chapters 解析异常（章1 起始层 = %d）" % first_layer)

func _section_chapter_event() -> void:
	# §4a 章末事件（PS-D2a-1）：route_generator 真实生成 → 章 1 末层（0-based li=2）
	# = 单 event 节点层 + wave_index==0 + 类型 ∈ 合法集
	var gen: GDScript = load("res://scripts/systems/route_generator.gd")
	if gen == null:
		_fail("route_generator.gd 不可加载")
		return
	var route: Dictionary = gen.call("generate_from", 20260806, _loader.call("get_routes"))
	var layers: Array = route.get("layers", [])
	if layers.size() < 3:
		_fail("生成路线层数不足（%d）" % layers.size())
		return
	var ch1_end: Array = layers[2]
	if ch1_end.size() == 1:
		_checked += 1
		print("  PASS  §4a 章 1 末层单节点")
	else:
		_fail("章 1 末层应单节点, 实得 %d 节点" % ch1_end.size())
	var ev_type: String = str(ch1_end[0].get("type", ""))
	if ev_type == "event" and int(ch1_end[0].get("wave_index", -1)) == 0:
		_checked += 1
		print("  PASS  §4a 章 1 末层 = event 节点（wave_index==0）")
	else:
		_fail("章 1 末层应为 event wave=0, 实得 %s" % str(ch1_end))
	var valid: Array = ["battle", "event", "elite", "shop", "boss"]
	if valid.has(ev_type):
		_checked += 1
		print("  PASS  §4a 章末事件类型 ∈ 合法集")
	else:
		_fail("章末事件类型非法: %s" % ev_type)

func _section_consistency() -> void:
	# §5 一致性护栏（PS-D2b-0 · 2026-08-17）：boss_layers 数组 == chapters 推导的章末 Boss 层集合
	# （end_type=="boss" 的章末层 → 0-based）。两处数据不同步即红——防「双 Boss vs 章节化」
	# 类冲突复发（用户前瞻关卡拉长/改章节时靠它兜底）；chapters 缺省空 → 仅校验非空场景
	var routes: Dictionary = _loader.call("get_routes")
	var bl: Array = []
	for b in routes.get("boss_layers", []):
		bl.append(int(b))
	var derived: Array = []
	for ch in routes.get("chapters", []):
		var ch_layers: Array = ch.get("layers", [])
		if ch_layers.is_empty():
			continue
		if str(ch.get("end_type", "")) == "boss":
			derived.append(int(ch_layers[ch_layers.size() - 1]) - 1)
	derived.sort()
	if not derived.is_empty() and bl == derived:
		_checked += 1
		print("  PASS  §5 一致性: boss_layers == chapters 推导章末 Boss 层集合（%s）" % str(bl))
	else:
		_fail("boss_layers %s ≠ chapters 推导 %s（两处数据不同步，D2b-0 护栏拦截）" % [str(bl), str(derived)])

func _section_chapter_banner() -> void:
	# §4b 章界显示（PS-D3）：RouteSelectPanel 实例化 + setup → 章界横幅数 == chapters 数 +
	# 首章起始层 0 横幅在场
	var scene: PackedScene = load("res://scenes/RouteSelectPanel.tscn")
	if scene == null:
		_fail("RouteSelectPanel.tscn 不可加载")
		return
	var gen: GDScript = load("res://scripts/systems/route_generator.gd")
	if gen == null:
		_fail("route_generator.gd 不可加载")
		return
	var routes: Dictionary = _loader.call("get_routes")
	var route_data: Dictionary = gen.call("generate_from", 20260806, routes)
	var panel: Node = scene.instantiate()
	root.add_child(panel)
	panel.call("setup", route_data, 0)
	var banners: Array = panel.get("chapter_banners")
	var ch_count: int = (routes.get("chapters", []) as Array).size()
	if banners.size() == ch_count:
		_checked += 1
		print("  PASS  §4b 章界横幅数 == chapters 数（%d）" % ch_count)
	else:
		_fail("章界横幅数应 %d, 实得 %d" % [ch_count, banners.size()])
	# 首章起始层 0 横幅在场
	var first_ok: bool = false
	for b in banners:
		if int(b.get("layer", -1)) == 0:
			var lbl: Variant = b.get("label", null)
			if lbl != null and is_instance_valid(lbl):
				first_ok = true
	if first_ok:
		_checked += 1
		print("  PASS  §4b 首章起始层 0 横幅在场")
	else:
		_fail("首章起始层横幅缺失")
	panel.queue_free()

func _report() -> void:
	print("=== Day 31 PS-D chapter check: %d passed, %d failed ===" % [_checked, _failures])
	if _failures == 0:
		print("DAY31_CHAPTER CHECK CLEAN")

func _fail(msg: String) -> void:
	_failures += 1
	print("  FAIL  %s" % msg)
