## Day 30-F1.0 配置生效探针：Excel → 导出 → DataLoader 链路验证
##
## 用法（无头，不需要编辑器）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day30_data_effect_check.gd
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day30_data_effect_check.gd -- --expect-coffee=9
##
## 校验内容：
##   1. DataLoader 能读到 items.json coffee 的效果值（默认期望 8）
##   2. 传 --expect-coffee=N 时断言实际值 == N —— 用于验证「改 Excel → 导出 → 游戏生效」
##      （配合 tools/excel_export.py；Excel 改数后此探针期望值应随导出变化）
##   3. manifest 存在且 fingerprint 非空（导出护栏产物）
##
## 退出码 0 = 全部通过；非 0 = 失败项数。
extends SceneTree

var _sub: int = 0
var _expect_coffee: float = 8.0
var _loader: Node = null
var _checked: int = 0
var _failures: int = 0

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--expect-coffee="):
			_expect_coffee = float(arg.split("=")[1])
	print("=== Day 30 F1.0 data-effect check (expect coffee attack_speed_percent = %s) ===" % str(_expect_coffee))

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
	var item: Dictionary = _loader.call("get_item", "coffee")
	if item.is_empty():
		_fail("coffee 数据缺失")
		return 1
	var effects: Dictionary = item.get("effects", {})
	var actual: float = float(effects.get("attack_speed_percent", -1.0))
	if absf(actual - _expect_coffee) <= 0.001:
		_checked += 1
		print("  PASS  coffee.attack_speed_percent == %s（Excel 配置已生效）" % str(actual))
	else:
		_fail("coffee.attack_speed_percent 期望 %s 实际 %s（Excel 未导出或导出未生效）" % [_expect_coffee, actual])
	# manifest 存在性
	if FileAccess.file_exists("res://data/.manifest.json"):
		var mf: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/.manifest.json"))
		if mf is Dictionary and not str(mf.get("fingerprint", "")).is_empty():
			_checked += 1
			print("  PASS  manifest fingerprint = %s" % str(mf.get("fingerprint")))
		else:
			_fail("manifest fingerprint 缺失")
	else:
		_fail("data/.manifest.json 不存在（未运行 excel_export.py）")
	return 1

func _fail(msg: String) -> void:
	_failures += 1
	print("  FAIL  %s" % msg)

func _report() -> void:
	print("=== Day30-F1.0 result: %d checked, %d failures ===" % [_checked, _failures])
