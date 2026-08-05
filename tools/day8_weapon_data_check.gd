## Day 8-9 出口校验：18 把武器全量补全 + 图标实绘 端到端探针
##
## 用法（无头，不需要编辑器）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day8_weapon_data_check.gd
##
## 校验内容（对应 docs/TASKS.md D8-T3 / D8-EXIT）：
##   1. JSON 全量层：36/36 把 levels 8 条 + max_level >= 8（D7+D10：33 既有 + 3 结果武器）；
##      18 把 Lv1 与顶层 damage/cooldown/range 一致（抽查 fist/rocket_launcher/force_field）；
##      18 把 damage 单调不减 + cooldown 单调不增（全扫）
##   2. 特例层：force_field levels damage 全 0；minigun Lv1 cooldown == 0.08
##   3. 装配层：build_weapon_from_data("fist") → damage 3 / icon_index 0；
##              build_weapon_from_data("force_field") → damage 0 / icon_index 31；
##              build_weapon_from_data("rocket_launcher") → icon_index 14；
##              force_field upgrade() 后 damage 仍 0
##   4. 图标层：18 帧（0/1/2/4/6/9/10/14/15/19/21/22/23/24/28/29/30/31）中心 16×16 非全透明；
##              (0,0) 透明键；帧 36-39 全透明（D10-T5 占 33/34/35）
##   5. 回归层：day7 15 把 levels 未被破坏（sword Lv8 damage 50 / se_star_flame Lv8 projectiles 3 /
##              se_star_blade Lv8 blade_count 4）；36 把 icon_index 与 D7-T5+D10-T1 映射表一致
##
## 退出码 0 = 全部通过；非 0 = 失败项数。
extends SceneTree

## D8 新增 18 把武器
const NEW_EIGHTEEN: Array = [
	"fist", "stick", "dagger", "hammer", "flaming_knuckles",
	"slingshot", "crossbow", "rocket_launcher", "minigun",
	"lightning_shiv", "venom_staff", "storm_staff", "frost_nova", "plasma_cannon",
	"wrench", "laser_turret", "mech_arm", "force_field",
]
## D8 新增 18 帧对应 icon_index
const NEW_ICON_INDEXES: Array = [0, 1, 2, 4, 6, 9, 10, 14, 15, 19, 21, 22, 23, 24, 28, 29, 30, 31]
## 11 把 D7 通用武器（确认未被 D8-T1 破坏）
const ELEVEN_LEVELS: Array = [
	"sword", "chainsaw", "pistol", "smg", "shotgun", "sniper",
	"wand", "icicle", "flamethrower", "turret", "landmine",
]
## 4 把签名武器（D7 锚点）
const SIGNATURE: Array = ["se_star_flame", "se_auto_turret", "se_star_blade", "se_holy_staff"]
## D7-T5 + D10-T1 完整 36 把 icon_index 映射表（回归层；D10 +3 把结果武器 33/34/35）
const ICON_INDEX_MAP: Dictionary = {
	"fist": 0, "stick": 1, "dagger": 2, "sword": 3, "hammer": 4,
	"chainsaw": 5, "flaming_knuckles": 6, "se_star_blade": 7,
	"pistol": 8, "slingshot": 9, "crossbow": 10, "smg": 11, "shotgun": 12,
	"sniper": 13, "rocket_launcher": 14, "minigun": 15, "se_holy_staff": 16,
	"wand": 17, "icicle": 18, "lightning_shiv": 19, "flamethrower": 20,
	"venom_staff": 21, "storm_staff": 22, "frost_nova": 23, "plasma_cannon": 24,
	"se_star_flame": 25,
	"turret": 26, "landmine": 27, "wrench": 28, "laser_turret": 29,
	"mech_arm": 30, "force_field": 31, "se_auto_turret": 32,
	# 结果武器（D10-T1，占用原空余帧 33/34/35）
	"se_star_fall": 33, "se_turret_array": 34, "se_blade_storm": 35,
}
## PNG 路径（headless 下用 ProjectSettings.globalize_path 转绝对路径）
const WEAPONS_PNG_PATH: String = "res://assets/sprites/ui/weapons.png"

var _idx: int = 0
var _sub: int = 0
var _checked: int = 0
var _failures: int = 0
var _loader: Node = null
var _expect_loaded: bool = false


func _initialize() -> void:
	print("=== Day 8-9 weapon data check ===")


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
	if _loader == null:
		_fail("DataLoader autoload 缺失（未就绪）")
		report_and_quit()
		return


# ========== 用例推进 ==========

func _advance(sub: int) -> int:
	match sub:
		0:
			_part_json_full()
			return 1
		1:
			_part_special()
			return 2
		2:
			_part_assembly()
			return 3
		3:
			_part_icons()
			return 4
		4:
			_part_regression()
			return 5
		_:
			_pass("done")
			_idx += 1
			return 0
	return sub + 1


# ========== Part 1: JSON 全量层 ==========

func _part_json_full() -> void:
	# 36/36 把 levels 8 条 + max_level >= 8
	var cats: Array = ["melee", "ranged", "elemental", "engineering"]
	var total: int = 0
	for cat in cats:
		var ids: Array = _loader.call("get_weapon_ids_by_category", cat)
		for wid in ids:
			total += 1
			var data: Dictionary = _loader.call("get_weapon", wid)
			var lv: Array = data.get("levels", [])
			if lv.size() != 8:
				_fail("JSON: %s levels 应 8 条, 实得 %d" % [str(wid), lv.size()])
			if int(data.get("max_level", 0)) < 8:
				_fail("JSON: %s max_level 应 >= 8, 实得 %s" % [str(wid), str(data.get("max_level"))])
	if total == 36 and _failures == 0:
		_pass("JSON / 36 把 levels 8 条 + max_level≥8 全部满足（D7+D10 合并：33 既有 + 3 结果武器）")

	# 抽查 3 把（fist/rocket_launcher/force_field）Lv1 == 顶层
	for wid in ["fist", "rocket_launcher", "force_field"]:
		var data: Dictionary = _loader.call("get_weapon", wid)
		var lv: Array = data.get("levels", [])
		if lv.is_empty():
			_fail("抽查 %s levels 为空" % wid)
			continue
		var l1: Dictionary = lv[0]
		if float(l1.get("damage", -1)) != float(data.get("damage")):
			_fail("JSON: %s Lv1.damage(%s) != 顶层(%s)" % [wid, str(l1.get("damage")), str(data.get("damage"))])
		if float(l1.get("cooldown", -1)) != float(data.get("cooldown")):
			_fail("JSON: %s Lv1.cooldown 不一致" % wid)
		if float(l1.get("range", -1)) != float(data.get("range")):
			_fail("JSON: %s Lv1.range 不一致" % wid)
	if _failures == 0:
		_pass("JSON / 3 把 Lv1==顶层（fist/rocket_launcher/force_field）")

	# 18 把 damage 单调不减 + cooldown 单调不增（全扫）
	for wid in NEW_EIGHTEEN:
		var data: Dictionary = _loader.call("get_weapon", wid)
		var lv: Array = data.get("levels", [])
		if lv.is_empty():
			continue
		var prev_d: float = -1.0
		var prev_c: float = 99.0
		for row in lv:
			var d: float = float(row.get("damage", 0))
			var c: float = float(row.get("cooldown", 0))
			if prev_d >= 0.0 and d < prev_d:
				_fail("JSON: %s damage 单调递减 Lv%d" % [wid, int(row.get("level"))])
			if prev_c < 99.0 and c > prev_c:
				_fail("JSON: %s cooldown 单调递增 Lv%d" % [wid, int(row.get("level"))])
			prev_d = d
			prev_c = c
	if _failures == 0:
		_pass("JSON / 18 把 levels damage 单调不减 + cooldown 单调不增")


# ========== Part 2: 特例层 ==========

func _part_special() -> void:
	# force_field levels damage 全 0（护盾无伤害）
	var ff: Dictionary = _loader.call("get_weapon", "force_field")
	var ff_lv: Array = ff.get("levels", [])
	var ff_dmg_zero: bool = true
	for row in ff_lv:
		if float(row.get("damage", -1)) != 0.0:
			_fail("特例: force_field Lv%d damage 应 0, 实得 %s" % [int(row.get("level")), str(row.get("damage"))])
			ff_dmg_zero = false
	if ff_dmg_zero:
		_pass("特例 / force_field levels damage 恒 0（护盾放行）")
	# minigun Lv1 cooldown == 0.08
	var mg: Dictionary = _loader.call("get_weapon", "minigun")
	var mg_lv: Array = mg.get("levels", [])
	if mg_lv.size() >= 1:
		if absf(float(mg_lv[0].get("cooldown")) - 0.08) > 0.001:
			_fail("特例: minigun Lv1 cooldown 应 0.08, 实得 %s" % str(mg_lv[0].get("cooldown")))
		else:
			_pass("特例 / minigun Lv1 cooldown == 0.08（顶层一致）")


# ========== Part 3: 装配层 ==========

func _part_assembly() -> void:
	var wc_script: GDScript = load("res://scripts/weapons/weapon_controller.gd")
	if wc_script == null:
		_fail("装配: 加载 weapon_controller.gd 失败")
		return
	var wc: Node = wc_script.new()
	if wc == null:
		_fail("装配: 实例化 WeaponController 失败")
		return

	# fist → damage 3 / icon_index 0
	var w_fist: Resource = wc.call("build_weapon_from_data", "fist")
	if w_fist == null:
		_fail("装配: build_weapon_from_data('fist') 返回 null")
	else:
		if absf(float(w_fist.get("base_damage")) - 3.0) > 0.001:
			_fail("装配: fist 装配后 base_damage 应 3, 实得 %s" % str(w_fist.get("base_damage")))
		else:
			_pass("装配 / fist base_damage == 3")
		if int(w_fist.get("icon_index")) != 0:
			_fail("装配: fist icon_index 应 0, 实得 %d" % int(w_fist.get("icon_index")))
		else:
			_pass("装配 / fist icon_index == 0")

	# force_field → damage 0 不崩 / icon_index 31
	var w_ff: Resource = wc.call("build_weapon_from_data", "force_field")
	if w_ff == null:
		_fail("装配: build_weapon_from_data('force_field') 返回 null")
	else:
		if absf(float(w_ff.get("base_damage"))) > 0.001:
			_fail("装配: force_field base_damage 应 0, 实得 %s" % str(w_ff.get("base_damage")))
		else:
			_pass("装配 / force_field base_damage == 0（护盾不崩）")
		if int(w_ff.get("icon_index")) != 31:
			_fail("装配: force_field icon_index 应 31, 实得 %d" % int(w_ff.get("icon_index")))
		else:
			_pass("装配 / force_field icon_index == 31")
		# upgrade 后 damage 仍 0
		var up_ok: bool = bool(w_ff.call("upgrade"))
		if not up_ok:
			_fail("装配: force_field upgrade() 失败（护盾应能升级）")
		else:
			if absf(float(w_ff.get("base_damage"))) > 0.001:
				_fail("装配: force_field upgrade() 后 base_damage 应仍 0, 实得 %s" % str(w_ff.get("base_damage")))
			else:
				_pass("装配 / force_field upgrade() 后 damage 仍 0")

	# rocket_launcher → icon_index 14
	var w_rl: Resource = wc.call("build_weapon_from_data", "rocket_launcher")
	if w_rl == null:
		_fail("装配: build_weapon_from_data('rocket_launcher') 返回 null")
	else:
		if int(w_rl.get("icon_index")) != 14:
			_fail("装配: rocket_launcher icon_index 应 14, 实得 %d" % int(w_rl.get("icon_index")))
		else:
			_pass("装配 / rocket_launcher icon_index == 14")

	wc.free()


# ========== Part 4: 图标层 ==========

func _part_icons() -> void:
	var abs_path: String = ProjectSettings.globalize_path(WEAPONS_PNG_PATH)
	if not FileAccess.file_exists(WEAPONS_PNG_PATH):
		_fail("图标: %s 不存在" % WEAPONS_PNG_PATH)
		return
	var img: Image = Image.load_from_file(abs_path)
	if img == null:
		_fail("图标: 加载 %s 失败" % abs_path)
		return
	if img.get_width() != 1280 or img.get_height() != 32:
		_fail("图标: PNG 尺寸应为 1280×32, 实得 %d×%d" % [img.get_width(), img.get_height()])
	else:
		_pass("图标 / PNG 尺寸 1280×32 不变")

	# 18 帧中心 16×16 非全透明 + (0,0) 透明键
	for idx in NEW_ICON_INDEXES:
		var x0: int = idx * 32
		var has_center: bool = false
		for dx in range(8, 24):
			for dy in range(8, 24):
				var px: Color = img.get_pixel(x0 + dx, dy)
				if px.a > 0.0:
					has_center = true
					break
			if has_center:
				break
		if not has_center:
			_fail("图标: 帧 %d 中心 16×16 全透明（应实绘）" % idx)
		var tl: Color = img.get_pixel(x0, 0)
		if tl.a > 0.0:
			_fail("图标: 帧 %d (0,0) 非透明键（alpha=%f）" % [idx, tl.a])
	if _failures == 0:
		_pass("图标 / 18 帧中心 16×16 非全透明 + (0,0) 透明键")

	# 帧 36-39 全透明（D10-T5：33/34/35 被 3 把结果武器占用为实绘帧）
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
			_fail("图标: 帧 %d 应为全透明空余帧但有像素" % idx)
	if _failures == 0:
		_pass("图标 / 帧 36-39 全透明（空余帧）")


# ========== Part 5: 回归层 ==========

func _part_regression() -> void:
	# day7 15 把 levels 未被破坏
	# sword Lv8 damage 50
	var sword: Dictionary = _loader.call("get_weapon", "sword")
	var sword_lv: Array = sword.get("levels", [])
	if sword_lv.size() >= 8:
		if absf(float(sword_lv[7].get("damage")) - 50.0) > 0.001:
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
			_pass("回归 / se_star_flame Lv8 projectiles == 3（day7 未破坏）")

	# se_star_blade Lv8 blade_count 4
	var ssb: Dictionary = _loader.call("get_weapon", "se_star_blade")
	var ssb_lv: Array = ssb.get("levels", [])
	if ssb_lv.size() >= 8:
		if int(ssb_lv[7].get("blade_count", -1)) != 4:
			_fail("回归: se_star_blade Lv8 blade_count 应 4, 实得 %s" % str(ssb_lv[7].get("blade_count")))
		else:
			_pass("回归 / se_star_blade Lv8 blade_count == 4（day7 未破坏）")

	# 36 把 icon_index 与 D7-T5+D10-T1 映射表一致
	for wid in ICON_INDEX_MAP.keys():
		var data: Dictionary = _loader.call("get_weapon", wid)
		var expected: int = int(ICON_INDEX_MAP[wid])
		var actual: int = int(data.get("icon_index", -1))
		if actual != expected:
			_fail("回归: %s icon_index 应 %d, 实得 %d" % [str(wid), expected, actual])
	if _failures == 0:
		_pass("回归 / 36 把 icon_index 与 D7-T5+D10-T1 映射表一致")


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
		print("DAY8 WEAPON DATA CHECK CLEAN")
	else:
		print("DAY8 WEAPON DATA CHECK BROKEN")


func report_and_quit() -> void:
	_report()
	quit(_failures)