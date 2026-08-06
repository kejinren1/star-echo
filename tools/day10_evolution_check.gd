## Day 10 出口校验：武器进化机制（D10-PRE/T1~T6 收口）
##
## 用法（无头，不需要编辑器）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day10_evolution_check.gd
##
## 校验内容（对应 docs/TASKS.md D10-T6 / D10-EXIT 五段）：
##   1. 数据层：3 条进化链齐全（se_star_flame/se_auto_turret/se_star_blade 均有 evolution）；
##      requires_item ∈ items.json 且 tags 含 evolution_core；result_id ∈ weapons.json 且带 evolution_result；
##      3 把结果武器 levels 8 条 + max_level 8 + Lv1==顶层 + Lv8==顶层（平曲线）
##   2. 装配层：build_weapon_from_data("se_star_fall") → explosion_radius 90；
##              build_weapon_from_data("se_blade_storm") → orbit_data.blade_count 6；
##              build_weapon_from_data("se_turret_array") → 正常装配
##   3. 背包层：add_item_from_data("se_flame_core") → has_item_id true → remove_item_id true → false；
##              未知 id → false 且不抛错
##   4. 进化链路层：满级 se_star_flame（build + 循环 upgrade）→ replace_weapon("se_star_fall")
##              → 槽位数不变 + level == max_level + source_id == "se_star_fall"；
##              inventory 注入核心 → panel._roll_options 含 evolution 选项 →
##              panel._apply_option → 武器替换 + 核心消耗
##   5. 回归层：sword Lv8 damage 50；se_star_flame Lv8 projectiles 3；se_star_blade Lv8 blade_count 4；
##              36 把 icon_index（33 既有 + 3 结果）边界合法
##
## 退出码 0 = 全部通过；非 0 = 失败项数。
extends SceneTree

const WEAPONS_PNG_PATH: String = "res://assets/sprites/ui/weapons.png"
const SELECTION_META: StringName = &"se_selected_character"
const EPSILON: float = 0.01

const EVO_CHAINS: Array = [
	{"weapon": "se_star_flame", "core": "se_flame_core", "result": "se_star_fall"},
	{"weapon": "se_auto_turret", "core": "se_mech_core", "result": "se_turret_array"},
	{"weapon": "se_star_blade", "core": "se_blade_core", "result": "se_blade_storm"},
]

var _idx: int = 0
var _sub: int = 0
var _loader: Node = null
var _gm: Node = null
var _wc: Node = null
var _inv: Node = null
var _player: Node = null
var _checked: int = 0
var _failures: int = 0
var _expect_loaded: bool = false


func _initialize() -> void:
	print("=== Day 10 evolution check ===")


func _process(_delta: float) -> bool:
	if not _expect_loaded:
		_load_expectations()
	if _idx >= 1:
		_report()
		quit(_failures)
		return true
	_sub = _advance(_sub)
	return false


func _load_expectations() -> void:
	_expect_loaded = true
	_loader = root.get_node_or_null("DataLoader")
	_gm = root.get_node_or_null("GameManager")
	if _loader == null:
		_fail("DataLoader autoload 缺失")
		report_and_quit()
		return
	if _gm == null:
		_fail("GameManager autoload 缺失")
		report_and_quit()
		return
	# mock player 用 Node2D（D10 武器逻辑依赖 Node2D 的 owner_node + global_position + get_global_mouse_position）
	_player = Node2D.new()
	_player.name = "MockPlayer"
	root.add_child(_player)
	# Inventory（新脚本实例 + 挂 root + 写入 GameManager.inventory）
	var inv_script: GDScript = load("res://scripts/systems/inventory.gd")
	_inv = inv_script.new()
	_inv.name = "MockInventory"
	root.add_child(_inv)
	_gm.set("inventory", _inv)
	# WeaponController（new → add_child 触发 _ready → 装默认枪「初始枪」）
	var wc_script: GDScript = load("res://scripts/weapons/weapon_controller.gd")
	_wc = wc_script.new()
	_wc.name = "WeaponController"
	_player.add_child(_wc)
	# 清掉 _ready 装的「初始枪」（用 typed Array[Resource] = [] 避免类型不兼容）
	_clear_weapons()


func _clear_weapons() -> void:
	# typed Array[Resource] literal（Godot 4.2+）—— untyped [] 赋给 typed array 会被忽略
	var empty: Array[Resource] = []
	_wc.set("equipped_weapons", empty)


# ========== 用例推进 ==========

func _advance(sub: int) -> int:
	match sub:
		0:
			_part_data()
			return 1
		1:
			_part_assembly()
			return 2
		2:
			_part_inventory()
			return 3
		3:
			_part_evolution_chain()
			return 4
		4:
			_part_regression()
			return 5
		_:
			_idx += 1
			return 0
	return sub + 1


# ========== Part 1: 数据层 ==========

func _part_data() -> void:
	for chain in EVO_CHAINS:
		var wid: String = str(chain["weapon"])
		var core: String = str(chain["core"])
		var rid: String = str(chain["result"])
		var wdata: Dictionary = _loader.call("get_weapon", wid)
		var idata: Dictionary = _loader.call("get_item", core)
		var rdata: Dictionary = _loader.call("get_weapon", rid)
		if wdata.is_empty():
			_fail("数据: %s 缺失" % wid)
			continue
		var evo: Dictionary = wdata.get("evolution", {})
		if evo.is_empty():
			_fail("数据: %s 缺 evolution" % wid)
			continue
		if str(evo.get("requires_item", "")) != core:
			_fail("数据: %s evolution.requires_item 应 %s" % [wid, core])
		if str(evo.get("result_id", "")) != rid:
			_fail("数据: %s evolution.result_id 应 %s" % [wid, rid])
		if not (idata.has("effects") or idata.has("tags")):
			_fail("数据: 核心 %s 缺失" % core)
		elif not ("evolution_core" in idata.get("tags", [])):
			_fail("数据: 核心 %s tags 缺 evolution_core" % core)
		if rdata.is_empty():
			_fail("数据: 结果武器 %s 缺失" % rid)
		elif not rdata.get("evolution_result"):
			_fail("数据: 结果武器 %s 缺 evolution_result" % rid)
		var lv: Array = rdata.get("levels", [])
		if lv.size() != 8:
			_fail("数据: %s levels 应 8 条, 实得 %d" % [rid, lv.size()])
		elif int(rdata.get("max_level", 0)) < 8:
			_fail("数据: %s max_level 应 >= 8" % rid)
		else:
			# 平曲线 Lv1==Lv8==顶层
			var l1_d: float = float(lv[0].get("damage", -1))
			var l8_d: float = float(lv[-1].get("damage", -1))
			var top_d: float = float(rdata.get("damage", -1))
			if absf(l1_d - top_d) > EPSILON or absf(l8_d - top_d) > EPSILON:
				_fail("数据: %s 平曲线破坏 (Lv1=%s Lv8=%s top=%s)" % [rid, str(l1_d), str(l8_d), str(top_d)])
	if _failures == 0:
		_pass("数据 / 3 条进化链 + 交叉引用 + 平曲线全部合法")


# ========== Part 2: 装配层 ==========

func _part_assembly() -> void:
	_clear_weapons()

	# se_star_fall → explosion_radius 90
	var w_fall: Resource = _wc.call("build_weapon_from_data", "se_star_fall")
	if w_fall == null:
		_fail("装配: build se_star_fall 返回 null")
	else:
		if absf(float(w_fall.get("explosion_radius")) - 90.0) > EPSILON:
			_fail("装配: se_star_fall explosion_radius 应 90, 实得 %s" % str(w_fall.get("explosion_radius")))
		else:
			_pass("装配 / se_star_fall explosion_radius == 90")
		if int(w_fall.get("icon_index")) != 33:
			_fail("装配: se_star_fall icon_index 应 33, 实得 %d" % int(w_fall.get("icon_index")))

	# se_blade_storm → orbit_data.blade_count 6
	var w_storm: Resource = _wc.call("build_weapon_from_data", "se_blade_storm")
	if w_storm == null:
		_fail("装配: build se_blade_storm 返回 null")
	else:
		var od: Dictionary = w_storm.get("orbit_data")
		if int(od.get("blade_count", 0)) != 6:
			_fail("装配: se_blade_storm orbit_data.blade_count 应 6, 实得 %s" % str(od.get("blade_count")))
		else:
			_pass("装配 / se_blade_storm orbit_data.blade_count == 6")

	# se_turret_array → 正常装配
	var w_arr: Resource = _wc.call("build_weapon_from_data", "se_turret_array")
	if w_arr == null:
		_fail("装配: build se_turret_array 返回 null")
	else:
		if absf(float(w_arr.get("base_damage")) - 30.0) > EPSILON:
			_fail("装配: se_turret_array base_damage 应 30, 实得 %s" % str(w_arr.get("base_damage")))
		else:
			_pass("装配 / se_turret_array base_damage == 30")

	_clear_weapons()


# ========== Part 3: 背包层 ==========

func _part_inventory() -> void:
	_inv.call("reset")
	# add_item_from_data("se_flame_core") → has_item_id true → remove_item_id true → false
	var ok: bool = _inv.call("add_item_from_data", "se_flame_core")
	if not ok:
		_fail("背包: add_item_from_data(se_flame_core) 失败")
	if not _inv.call("has_item_id", "se_flame_core"):
		_fail("背包: add 后 has_item_id(se_flame_core) 应 true")
	else:
		_pass("背包 / add_item_from_data + has_item_id 验证通过")
	if not _inv.call("remove_item_id", "se_flame_core"):
		_fail("背包: remove_item_id(se_flame_core) 应 true")
	else:
		_pass("背包 / remove_item_id 消耗成功")
	if _inv.call("has_item_id", "se_flame_core"):
		_fail("背包: remove 后 has_item_id 应 false")
	else:
		_pass("背包 / remove 后 has_item_id == false")

	# 未知 id → false（不抛错；DataLoader.push_warning 静默）
	var bad: bool = _inv.call("add_item_from_data", "non_existent_core_xyz")
	if bad:
		_fail("背包: add_item_from_data(未知 id) 应返回 false")


# ========== Part 4: 进化链路层 ==========
## 拆 4a（replace_weapon 白盒）+ 4b（panel._roll_options + _apply_option 链路）独立环境

func _part_evolution_chain() -> void:
	_part_evolution_replace_whitebox()
	_part_evolution_apply_panel()


func _part_evolution_replace_whitebox() -> void:
	# 独立环境：清空 + 装备 se_star_flame + 升级满级 + replace_weapon
	_clear_weapons()
	_inv.call("reset")

	var w_flame: Resource = _wc.call("build_weapon_from_data", "se_star_flame")
	if w_flame == null:
		_fail("链路: build se_star_flame 失败")
		return
	_wc.call("equip_weapon", w_flame)
	while int(w_flame.get("level")) < int(w_flame.get("max_level")):
		w_flame.call("upgrade")
	if not (int(w_flame.get("level")) == int(w_flame.get("max_level")) and int(w_flame.get("max_level")) == 8):
		_fail("链路: 循环升级未到 Lv8/max=8（level=%d max=%d）" % [int(w_flame.get("level")), int(w_flame.get("max_level"))])
	else:
		_pass("链路 / 满级 se_star_flame（Lv8/max=8）")

	var slots_before: int = int(_wc.call("get_slot_count"))
	var replaced: Resource = _wc.call("replace_weapon", w_flame, "se_star_fall")
	if replaced == null:
		_fail("链路: replace_weapon 返回 null")
		return
	var slots_after: int = int(_wc.call("get_slot_count"))
	if slots_after != slots_before:
		_fail("链路: 替换后槽位数变化 %d→%d" % [slots_before, slots_after])
	if slots_after != 1:
		_fail("链路: 替换后槽位数应 1, 实得 %d" % slots_after)
	else:
		_pass("链路 / replace_weapon 槽位数不变（满级→满级 1 把）")
	var src_id: String = str(replaced.get_meta(&"source_id", ""))
	if src_id != "se_star_fall":
		_fail("链路: 替换后 source_id 应 se_star_fall, 实得 %s" % src_id)
	else:
		_pass("链路 / replace_weapon → source_id == se_star_fall")
	if int(replaced.get("level")) != int(replaced.get("max_level")):
		_fail("链路: 替换后未升满级 level=%d max=%d" % [int(replaced.get("level")), int(replaced.get("max_level"))])
	else:
		_pass("链路 / 替换后 level == max_level（平曲线即满级）")


func _part_evolution_apply_panel() -> void:
	# 独立环境：清空 + 装备 se_star_flame 满级 + 注入核心 + panel._roll_options/_apply_option
	_clear_weapons()
	_inv.call("reset")

	var w_flame2: Resource = _wc.call("build_weapon_from_data", "se_star_flame")
	_wc.call("equip_weapon", w_flame2)
	while int(w_flame2.get("level")) < int(w_flame2.get("max_level")):
		w_flame2.call("upgrade")

	var panel_script: GDScript = load("res://scripts/ui/level_up_panel.gd")
	var panel = panel_script.new()
	panel.set("player", _player)

	# 持核心 → _roll_options 应含 evolution 选项
	# 防 flaky：_roll_options(count) 内部 pool.shuffle() 后取前 count —— 池≈11 项取 8 时
	# evolution 抽不中概率 ≈27%（C(10,8)/C(11,8)），断言随机红。count 传 99 → 返回全量池
	# → evolution 持核心时必出现、无核心时必不出现（2026-08-06 12:3x 实测复现 19 项 3 失败）。
	_inv.call("add_item_from_data", "se_flame_core")
	var opts: Array = panel.call("_roll_options", 99)
	var has_evo_opt: bool = false
	var evo_opt: Dictionary = {}
	for o in opts:
		if str(o.get("type", "")) == "evolution":
			has_evo_opt = true
			evo_opt = o
			break
	if not has_evo_opt:
		_fail("链路: _roll_options 缺 evolution 选项（满级 + 持核心）")
	else:
		var label: String = str(evo_opt.get("label", ""))
		if not ("炎星陨落" in label):
			_fail("链路: evolution 选项 label 缺「炎星陨落」, 实得 %s" % label)
		else:
			_pass("链路 / _roll_options 含 evolution「炎星陨落」选项")

	# 无核心 → 进化选项应不存在（同防 flaky：count 99 返回全量池）
	_inv.call("remove_item_id", "se_flame_core")
	var opts2: Array = panel.call("_roll_options", 99)
	var has_evo_opt2: bool = false
	for o in opts2:
		if str(o.get("type", "")) == "evolution":
			has_evo_opt2 = true
			break
	if has_evo_opt2:
		_fail("链路: 无核心时 _roll_options 不应含 evolution 选项")
	else:
		_pass("链路 / 无核心时 _roll_options 不含 evolution（互斥验证）")

	# 注入核心 → _apply_option → 武器替换 + 核心消耗
	_inv.call("add_item_from_data", "se_flame_core")
	panel.call("_apply_option", evo_opt)
	var new_weapon: Resource = _wc.get("equipped_weapons")[0]
	var new_src: String = str(new_weapon.get_meta(&"source_id", ""))
	if new_src != "se_star_fall":
		_fail("链路: _apply_option 后 equipped source_id 应 se_star_fall, 实得 %s" % new_src)
	else:
		_pass("链路 / _apply_option 后武器替换为 se_star_fall")
	if _inv.call("has_item_id", "se_flame_core"):
		_fail("链路: _apply_option 后核心应被消耗（has_item_id 应 false）")
	else:
		_pass("链路 / _apply_option 后核心已消耗")

	panel.free()


# ========== Part 5: 回归层 ==========

func _part_regression() -> void:
	# sword Lv8 damage 50
	var sword: Dictionary = _loader.call("get_weapon", "sword")
	var sword_lv: Array = sword.get("levels", [])
	if sword_lv.size() >= 8:
		if absf(float(sword_lv[7].get("damage")) - 50.0) > EPSILON:
			_fail("回归: sword Lv8 damage 应 50, 实得 %s" % str(sword_lv[7].get("damage")))
		else:
			_pass("回归 / sword Lv8 damage == 50（day7 未破坏）")

	# se_star_flame Lv8 projectiles 3
	var ssf: Dictionary = _loader.call("get_weapon", "se_star_flame")
	var ssf_lv: Array = ssf.get("levels", [])
	if ssf_lv.size() >= 8:
		if int(ssf_lv[7].get("projectiles", -1)) != 3:
			_fail("回归: se_star_flame Lv8 projectiles 应 3, 实得 %s" % str(ssf_lv[7].get("projectiles")))
		else:
			_pass("回归 / se_star_flame Lv8 projectiles == 3")

	# se_star_blade Lv8 blade_count 4
	var ssb: Dictionary = _loader.call("get_weapon", "se_star_blade")
	var ssb_lv: Array = ssb.get("levels", [])
	if ssb_lv.size() >= 8:
		if int(ssb_lv[7].get("blade_count", -1)) != 4:
			_fail("回归: se_star_blade Lv8 blade_count 应 4, 实得 %s" % str(ssb_lv[7].get("blade_count")))
		else:
			_pass("回归 / se_star_blade Lv8 blade_count == 4")

	# 36 把 icon_index 越界检查（0-35）
	var cats: Array = ["melee", "ranged", "elemental", "engineering"]
	var bad_idx: int = -1
	var bad_id: String = ""
	for cat in cats:
		var ids: Array = _loader.call("get_weapon_ids_by_category", cat)
		for wid in ids:
			var d: Dictionary = _loader.call("get_weapon", wid)
			var v: int = int(d.get("icon_index", -1))
			if v < 0 or v > 35:
				bad_idx = v
				bad_id = str(wid)
	if bad_idx >= 0:
		_fail("回归: %s icon_index 越界 %d（应 0-35）" % [bad_id, bad_idx])
	else:
		_pass("回归 / 36 把 icon_index 边界合法（0-35）")

	# 图标 PNG 帧 33/34/35 中心非全透明 + 36-39 全透明
	if FileAccess.file_exists(WEAPONS_PNG_PATH):
		var abs_path: String = ProjectSettings.globalize_path(WEAPONS_PNG_PATH)
		var img: Image = Image.load_from_file(abs_path)
		if img != null:
			for idx in [33, 34, 35]:
				var x0: int = idx * 32
				var has_center: bool = false
				for dx in range(8, 24):
					for dy in range(8, 24):
						if img.get_pixel(x0 + dx, dy).a > 0.0:
							has_center = true
							break
					if has_center:
						break
				if not has_center:
					_fail("回归: 帧 %d 中心全透明（应实绘）" % idx)
			for idx in range(36, 40):
				var x0: int = idx * 32
				var any_px: bool = false
				for dx in range(32):
					for dy in range(32):
						if img.get_pixel(x0 + dx, dy).a > 0.0:
							any_px = true
							break
					if any_px:
						break
				if any_px:
					_fail("回归: 帧 %d 应全透明空余但有像素" % idx)
			if _failures == 0:
				_pass("回归 / PNG 帧 33/34/35 实绘 + 36-39 全透明")


# ========== 断言 ==========

func _pass(what: String) -> void:
	_checked += 1
	print("  PASS  %s" % what)


func _fail(what: String) -> void:
	_checked += 1
	_failures += 1
	print("  FAIL  %s" % what)


func _report() -> void:
	print("--- %d 项断言，%d 项失败 ---" % [_checked, _failures])
	if _failures == 0:
		print("DAY10 EVOLUTION CHECK CLEAN")
	else:
		print("DAY10 EVOLUTION CHECK BROKEN")


func report_and_quit() -> void:
	_report()
	quit(_failures)