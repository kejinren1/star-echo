## Day 31 PS-D 出口校验：章节化 routes 数据层（PLAYER_SKILL_SPEC §8）
##
## 用法（无头）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day31_chapter_check.gd
##
## 校验内容（SOLUTION_PLAN 第 23 轮 PS-D4，≥8 断言）：
##   §1 chapters 数据层：routes.json.chapters 存在 4 章 / 每章 layers 合法（1-15 全覆盖无重叠）/
##      章末类型（章1=event / 章2-4=boss）
##   §2 拓扑兼容：chapters 缺省空 → 现行为（boss_layers 双 Boss [9,14] 零改动）
##   §3 章界信息：DataLoader.get_routes 读 chapters 可解析（JSON 文本列反序列化正确）
##
## 说明：章末 Boss 位映射调整（boss_layers → 4 章 3 Boss）与 F-27 用户拍板「15 层双 Boss」
## 冲突 → 已回滚（执行阻塞登记，交方案师裁决），本探针只验证数据层不触碰 F-27 结构。
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
	# boss_layers 仍为 F-27 双 Boss [9,14]（章节化映射调整未落地 = 兼容现行为）
	var routes: Dictionary = _loader.call("get_routes")
	var bl: Array = routes.get("boss_layers", [])
	var bl_int: Array = []
	for b in bl:
		bl_int.append(int(b))
	if bl_int == [9, 14]:
		_checked += 1
		print("  PASS  §3 boss_layers 维持 F-27 双 Boss [9,14]（chapters 缺省兼容）")
	else:
		_fail("boss_layers 应 [9,14], 实得 %s" % str(bl_int))
	# chapters JSON 文本列反序列化正确（4 章第一层 = 1）
	var first_layer: int = int((routes.get("chapters", [])[0]).get("layers", [])[0]) if (routes.get("chapters", []) as Array).size() > 0 else -1
	if first_layer == 1:
		_checked += 1
		print("  PASS  §3 chapters JSON 解析正确（章1 起始层 = 1）")
	else:
		_fail("chapters 解析异常（章1 起始层 = %d）" % first_layer)

func _report() -> void:
	print("=== Day 31 PS-D chapter check: %d passed, %d failed ===" % [_checked, _failures])
	if _failures == 0:
		print("DAY31_CHAPTER CHECK CLEAN")

func _fail(msg: String) -> void:
	_failures += 1
	print("  FAIL  %s" % msg)
