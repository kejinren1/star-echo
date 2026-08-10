## Day 30-F1D 商店参数数据化校验（T-010）
##
## 用法（无头）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day30_f1d_shop_check.gd
##
## 校验内容（SOLUTION_PLAN 阶段 F · F1-D）：
##   §1 数据源：stats.json.shop 段（Excel stats_shop sheet 导出）= reroll_cost 10 / core_grace_wave 4
##   §2 读参接线：shop.gd 兜底默认与数据源一致（行为零变化），reroll_cost 变量 == 数据源
##   §3 消费点静态：spend_coins(reroll_cost) 与 current_wave != core_grace_wave 仍为读参（防回退硬编码）
##
## 退出码 0 = 全部通过；非 0 = 失败项数。
extends SceneTree

var _sub: int = 0
var _loader: Node = null
var _checked: int = 0
var _failures: int = 0

func _initialize() -> void:
	print("=== Day 30 F1-D shop params parameterized check ===")

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
	_part_data_source()
	_part_read_param()
	_part_consumers()
	return 1

# ========== §1 数据源（Excel stats_shop sheet → stats.json.shop → DataLoader） ==========

func _part_data_source() -> void:
	var shop_cfg: Dictionary = _loader.call("get_stats_shop")
	_assert_int("shop.reroll_cost 数据源 == 10", int(shop_cfg.get("reroll_cost", -1)), 10)
	_assert_int("shop.core_grace_wave 数据源 == 4", int(shop_cfg.get("core_grace_wave", -1)), 4)
	# 兜底默认常量与数据源一致（行为零变化前提）
	var shop_script: GDScript = load("res://scripts/ui/shop.gd")
	var shop: Node = shop_script.new()
	_assert_int("shop 默认 reroll_cost == 10", int(shop.get("reroll_cost")), 10)
	_assert_int("shop 默认 core_grace_wave == 4", int(shop.get("core_grace_wave")), 4)

# ========== §2 读参推导（shop._ready 读参逻辑语义等价复现：数据源 → 变量值） ==========

func _part_read_param() -> void:
	var shop_cfg: Dictionary = _loader.call("get_stats_shop")
	var reroll_cost: int = int(shop_cfg.get("reroll_cost", 10))
	var core_grace_wave: int = int(shop_cfg.get("core_grace_wave", 4))
	_assert_int("读参推导 reroll_cost（get 默认 10 兜底）", reroll_cost, 10)
	_assert_int("读参推导 core_grace_wave（get 默认 4 兜底）", core_grace_wave, 4)

# ========== §3 消费点静态断言（防回退硬编码） ==========

func _part_consumers() -> void:
	var src: String = _read_file("res://scripts/ui/shop.gd")
	if src.contains("spend_coins(reroll_cost)") and not src.contains("spend_coins(REROLL_COST)"):
		_checked += 1
		print("  PASS  刷新扣费消费点 = reroll_cost（读参）")
	else:
		_fail("刷新扣费消费点应读 reroll_cost（发现 REROLL_COST 硬编码残留）")
	if src.contains("!= core_grace_wave") and not src.contains("!= 4"):
		_checked += 1
		print("  PASS  星刃核心保底波消费点 = core_grace_wave（读参）")
	else:
		_fail("星刃核心保底波消费点应读 core_grace_wave（发现 != 4 硬编码残留）")

func _read_file(path: String) -> String:
	if not FileAccess.file_exists(path):
		_fail("文件不存在: %s" % path)
		return ""
	var f := FileAccess.open(path, FileAccess.READ)
	if not f:
		_fail("无法打开: %s" % path)
		return ""
	var text: String = f.get_as_text()
	f.close()
	return text

# ========== 断言 ==========

func _assert_int(label: String, actual: int, expect: int) -> void:
	if actual == expect:
		_checked += 1
		print("  PASS  %s == %d" % [label, actual])
	else:
		_fail("%s 期望 %d 实际 %d" % [label, expect, actual])

func _fail(msg: String) -> void:
	_failures += 1
	print("  FAIL  %s" % msg)

func _report() -> void:
	print("=== Day30-F1D result: %d checked, %d failures ===" % [_checked, _failures])
