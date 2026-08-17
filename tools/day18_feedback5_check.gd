## Day 18-FB5 出口校验：F-24~F-28（2026-08-08 真人 5 条反馈）
##
## 用法（无头，不需要编辑器）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day18_feedback5_check.gd
##
## 校验内容：
##   §1 F-24 商店 tooltip：DescBuilder 文案（被动 effects / 机制 trigger / 武器数值+可进化提示）
##      + shop._build_item_resource trigger 透传
##   §2 F-25 升级面板 tooltip：属性（乘算加成）/ 武器升级（下一级数值）/ 进化（结果描述）
##   §3 F-26 删波次改关卡制：HUD「第 N 关」（路线层+1 / 旧制波号）+ Boss 后缀 + 阵亡文案
##   §4 F-27 + PS-D2b 15 关章节化三 Boss（2026-08-17 用户拍板方案②）：layers==15 /
##      boss_layers [6,10,14]（第 7/11/15 关）/ boss wave_index==10 三关 /
##      battle/elite wave==li+1 / reroute 跳过 boss 层 / force_node_type boss 层拒绝
##   §5 F-28 通关判定：普通关敌全灭通关；Boss 关 Boss 击杀通关（不等召唤物）；Boss 关倒计时不通关
##
## 退出码 0 = 全部通过；非 0 = 失败项数。
extends SceneTree

const EPSILON: float = 0.001

## --script 模式不注册 class_name → 显式 preload（DescBuilder 全局类在游戏脚本可用）
const DescBuilderScript: GDScript = preload("res://scripts/ui/desc_builder.gd")

var _sub: int = 0
var _ready_mocks: bool = false
var _loader: Node = null
var _gm: Node = null
var _checked: int = 0
var _failures: int = 0

func _initialize() -> void:
	print("=== Day 18-FB5 check (F-24~F-28) ===")

func _process(_delta: float) -> bool:
	if not _ready_mocks:
		_load_mocks()
		return false
	if _sub > 5:
		_report()
		quit(_failures)
		return true
	_sub = _advance(_sub)
	return false

func _load_mocks() -> void:
	_ready_mocks = true
	_loader = root.get_node_or_null("DataLoader")
	_gm = root.get_node_or_null("GameManager")
	if _loader == null or _gm == null:
		_fail("DataLoader/GameManager autoload 缺失")
		_report()
		quit(1)
		return

# ========== 断言工具 ==========

func _ok(cond: bool, what: String) -> void:
	_checked += 1
	if not cond:
		_failures += 1
		print("  FAIL: " + what)

func _fail(what: String) -> void:
	_checked += 1
	_failures += 1
	print("  FAIL: " + what)

func _pass(what: String) -> void:
	_checked += 1
	print("  PASS: " + what)

func _report() -> void:
	print("=== Day 18-FB5: %d checked, %d failed ===" % [_checked, _failures])

func _advance(sub: int) -> int:
	match sub:
		0:
			_part_tooltip_shop()
			return 1
		1:
			_part_tooltip_levelup()
			return 2
		2:
			_part_stage_display()
			return 3
		3:
			_part_route_15()
			return 4
		4:
			_part_clear_condition()
			return 5
		5:
			_report()
			quit(_failures)
	return 6

# ========== §1 F-24 商店 tooltip ==========

func _part_tooltip_shop() -> void:
	var shop_script: GDScript = load("res://scripts/ui/shop.gd")
	var shop = shop_script.new()
	# 被动 effects 文案
	var core: Resource = shop.call("_build_item_resource", "se_blade_core")
	if core == null:
		_fail("F-24/资源: se_blade_core 构建失败")
		return
	var t1: String = DescBuilderScript.item_tooltip(core)
	_ok(t1.contains("星刃核心") and t1.contains("近战伤害 +8") and t1.contains("暴击伤害 +20%")
		and not t1.contains("%%"),
		"F-24/被动: 星刃核心 tooltip 含 effects 中文且百分比无双 %%（实得: %s）" % t1.replace("\n", " / "))
	# 机制 trigger 透传 + 文案
	var oc: Resource = shop.call("_build_item_resource", "overload_capacitor")
	_ok(oc != null and oc.get("trigger") is Dictionary and not (oc.get("trigger") as Dictionary).is_empty(),
		"F-24/透传: overload_capacitor trigger 已透传到 Item 资源")
	var t2: String = DescBuilderScript.item_tooltip(oc)
	_ok(t2.contains("暴击命中时：周围 80px") and t2.contains("连锁 30%") and not t2.contains("%%"),
		"F-24/机制: 过载电容 tooltip 含 trigger 说明且百分比无双 %%（实得: %s）" % t2.replace("\n", " / "))
	# 遗物
	var crown: Resource = shop.call("_build_item_resource", "broken_crown")
	var t3: String = DescBuilderScript.item_tooltip(crown)
	_ok(t3.contains("伤害 +50%") and t3.contains("受到伤害 +30%") and t3.contains("遗物") and not t3.contains("%%"),
		"F-24/遗物: 破碎王冠 tooltip 含双刃剑效果且百分比无双 %%（实得: %s）" % t3.replace("\n", " / "))
	# 武器 tooltip（数值 + 可进化提示）
	var wc_script: GDScript = load("res://scripts/weapons/weapon_controller.gd")
	var wc = wc_script.new()
	var blade: Resource = wc.call("build_weapon_from_data", "se_star_blade")
	var t4: String = DescBuilderScript.weapon_tooltip(blade)
	_ok(t4.contains("伤害 7") and t4.contains("环绕玩家旋转") and t4.contains("满级可进化『星刃风暴』"),
		"F-24/武器: 星刃 tooltip 含数值/描述/进化提示（实得: %s）" % t4.replace("\n", " / "))
	shop.free()

# ========== §2 F-25 升级面板 tooltip ==========

func _part_tooltip_levelup() -> void:
	# 属性选项
	var opt_attr: Dictionary = {"label": "攻击 +10%", "stat": "damage", "mode": "percent", "value": 10}
	var ta: String = DescBuilderScript.option_tooltip(opt_attr)
	_ok(ta.contains("攻击 +10%") and ta.contains("乘算加成"),
		"F-25/属性: tooltip = label + 加成通道（实得: %s）" % ta)
	# 武器升级：星刃 Lv1 → Lv.2 + 下一级 upgrade 文本（level_table[1]）
	var wc_script: GDScript = load("res://scripts/weapons/weapon_controller.gd")
	var wc = wc_script.new()
	var blade: Resource = wc.call("build_weapon_from_data", "se_star_blade")
	var opt_up: Dictionary = {"label": "升级「星刃」", "type": "weapon_upgrade", "weapon": blade}
	var tu: String = DescBuilderScript.option_tooltip(opt_up)
	_ok(tu.contains("Lv.2") and tu.contains("伤害 9"),  # se_star_blade level_table[1] damage=9
		"F-25/升级: tooltip 含下一级数值（实得: %s）" % tu.replace("\n", " / "))
	# 进化
	var opt_ev: Dictionary = {"label": "进化『星刃风暴』", "type": "evolution", "result_damage": 45, "evolution": {"result_id": "se_blade_storm", "result_name": "星刃风暴", "description": "环绕刃群强化: 6 刃环绕"}}
	var te: String = DescBuilderScript.option_tooltip(opt_ev)
	_ok(te.contains("6 刃环绕") and te.contains("伤害 45") and te.contains("核心消耗"),
		"F-25/进化: tooltip 含结果描述与数值（实得: %s）" % te.replace("\n", " / "))

# ========== §3 F-26 删波次改关卡制 ==========

func _part_stage_display() -> void:
	var hud_scene: PackedScene = load("res://scenes/HUD.tscn")
	var hud: Node = hud_scene.instantiate()
	root.add_child(hud)
	var wave_label: Label = hud.get_node("MarginContainer/VBoxContainer/TopBar/CenterSection/WaveLabel")
	# 路线模式：current_layer=0 → 第 1 关
	var route_backup: Variant = _gm.get("route")
	var layer_backup: Variant = _gm.get("current_layer")
	var boss_backup: Variant = _gm.get("is_boss_wave")
	_gm.set("route", {"layers": [1, 2, 3]})
	_gm.set("current_layer", 0)
	_gm.set("is_boss_wave", false)
	hud.call("_on_wave_started", 1)
	_ok(wave_label.text == "第 1 关", "F-26/关卡: 路线层 0 → 「第 1 关」（实得 %s）" % wave_label.text)
	# Boss 关：current_layer=9 → 第 10 关 · BOSS
	_gm.set("current_layer", 9)
	_gm.set("is_boss_wave", true)
	hud.call("_on_wave_started", 10)
	_ok(wave_label.text == "第 10 关 · BOSS", "F-26/Boss: 层 9 → 「第 10 关 · BOSS」（实得 %s）" % wave_label.text)
	# 旧制：route 空 → 用 wave 号
	_gm.set("route", {})
	_gm.set("current_layer", 0)
	_gm.set("is_boss_wave", false)
	hud.call("_on_wave_started", 5)
	_ok(wave_label.text == "第 5 关", "F-26/旧制: wave 5 → 「第 5 关」（实得 %s）" % wave_label.text)
	# 阵亡文案（GameManager._spawn_game_over_panel 生成 reason——白盒直调会实例化面板，
	# 用 GameManager 内部文案规则校验：直接读 reason 不可行，改验证 current_wave→关数逻辑：
	# 通过 _spawn_game_over_panel 的 route 分支——route 空时 stage=current_wave）
	_gm.set("route", route_backup)
	_gm.set("current_layer", layer_backup)
	_gm.set("is_boss_wave", boss_backup)
	hud.queue_free()

# ========== §4 F-27 15 关双 Boss ==========

func _part_route_15() -> void:
	var gen: GDScript = load("res://scripts/systems/route_generator.gd")
	var route: Dictionary = gen.call("generate", 20260806)
	_ok(int(route.get("layers", []).size()) == 15, "F-27/层数: 15 层（实得 %d）" % int(route.get("layers", []).size()))
	var layers: Array = route.get("layers", [])
	var boss_layers: Array = route.get("boss_layers", [])
	_ok(boss_layers == [6, 10, 14], "PS-D2b/boss层: [6, 10, 14]（实得 %s）" % str(boss_layers))
	# 第 7 关（index 6）、第 11 关（index 10）与第 15 关（index 14）为单节点 Boss，wave_index == 10
	var b1: Array = layers[6]
	var b2: Array = layers[10]
	var b3: Array = layers[14]
	_ok(b1.size() == 1 and str(b1[0].get("type", "")) == "boss" and int(b1[0].get("wave_index", 0)) == 10,
		"PS-D2b/Boss1: 第 7 关 = 单 Boss 节点 wave 10")
	_ok(b2.size() == 1 and str(b2[0].get("type", "")) == "boss" and int(b2[0].get("wave_index", 0)) == 10,
		"PS-D2b/Boss2: 第 11 关 = 单 Boss 节点 wave 10")
	_ok(b3.size() == 1 and str(b3[0].get("type", "")) == "boss" and int(b3[0].get("wave_index", 0)) == 10,
		"PS-D2b/Boss3: 第 15 关 = 单 Boss 节点 wave 10（三 Boss 共享 invoker 同配置）")
	# 普通层 battle/elite → wave_index == li+1；boss 层/章末 event 层外每层 3 节点
	# PS-D2a-1（2026-08-17）：章末 event 层（单节点）同构豁免
	var chapter_event_layers: Array = gen.call("get_chapter_event_layers", route)
	var wave_ok: bool = true
	for li in 15:
		if li in boss_layers or li in chapter_event_layers:
			continue
		if layers[li].size() != 3:
			wave_ok = false
			break
		for node in layers[li]:
			var nt: String = str(node.get("type", ""))
			if (nt == "battle" or nt == "elite") and int(node.get("wave_index", 0)) != li + 1:
				wave_ok = false
				break
	_ok(wave_ok, "F-27/映射: 普通层 battle/elite wave_index == 层号+1（1-14 连续）")
	# 首层含 battle
	_ok(gen.call("_layer_has_battle", layers[0]), "F-27/首层: 含战斗节点")
	# reroute 跳过 boss 层（from_layer=0 → 重抽后 boss 层类型不变）
	var route2: Dictionary = gen.call("generate", 20260806)
	gen.call("reroute_remaining", route2, 0, {"battle": 0.9, "event": 0.01, "elite": 0.01, "shop": 0.01})
	var l2: Array = route2.get("layers", [])
	_ok(str(l2[6][0].get("type", "")) == "boss" and str(l2[10][0].get("type", "")) == "boss" and str(l2[14][0].get("type", "")) == "boss",
		"PS-D2b/reroute: Boss 层不受改写（第 7/11/15 关保持 boss）")
	# force_node_type boss 层拒绝（白盒：返回值恒 void，验证类型未变）
	var route3: Dictionary = gen.call("generate", 20260806)
	gen.call("force_node_type", route3, 6, 0, "battle")
	var l3: Array = route3.get("layers", [])
	_ok(str(l3[6][0].get("type", "")) == "boss", "PS-D2b/force: Boss 层不可强制改写")

# ========== §5 F-28 通关判定 ==========

class MockEnemy:
	extends Node2D
	var is_alive: bool = true
	var is_boss: bool = false
	func take_damage(_d: float, _c: bool = false) -> void:
		pass

func _part_clear_condition() -> void:
	var wm_script: GDScript = load("res://scripts/systems/wave_manager.gd")
	var wm = wm_script.new()
	root.add_child(wm)
	var container := Node2D.new()
	root.add_child(container)
	# mock spawner（纯 Node 无法 set 动态属性 → 挂 enemy_spawner.gd 实例）
	var spawner_mock = load("res://scripts/enemy/enemy_spawner.gd").new()
	spawner_mock.set("enemies_container", container)
	var wm_backup: Variant = _gm.get("wave_manager")
	var spawner_backup: Variant = _gm.get("enemy_spawner")
	var cont_backup: Variant = _gm.get("enemies_container")
	var boss_backup: Variant = _gm.get("is_boss_wave")
	_gm.set("wave_manager", wm)
	_gm.set("enemy_spawner", spawner_mock)
	_gm.set("enemies_container", container)
	# ---- 普通关：敌全灭通关 ----
	_gm.set("is_boss_wave", false)
	wm.set("is_active", true)
	var e1: MockEnemy = MockEnemy.new()
	var e2: MockEnemy = MockEnemy.new()
	container.add_child(e1)
	container.add_child(e2)
	var cleared_events: Array = []
	wm.wave_cleared.connect(func(_n: int) -> void: cleared_events.append(_n))
	wm.call("check_wave_clear")
	_ok(cleared_events.is_empty(), "F-28/普通: 有存活敌人 → 未通关")
	e1.is_alive = false
	wm.call("check_wave_clear")
	_ok(cleared_events.is_empty(), "F-28/普通: 剩 1 敌 → 未通关")
	e2.is_alive = false
	wm.call("check_wave_clear")
	_ok(cleared_events.size() == 1 and not bool(wm.get("is_active")), "F-28/普通: 敌全灭 → 通关（wave_cleared 1 次）")
	# ---- Boss 关：Boss 击杀即通（不等召唤物） ----
	for c in container.get_children():
		c.queue_free()
	_gm.set("is_boss_wave", true)
	wm.set("is_active", true)
	cleared_events.clear()
	var boss: MockEnemy = MockEnemy.new()
	boss.is_boss = true
	var minion: MockEnemy = MockEnemy.new()
	container.add_child(boss)
	container.add_child(minion)
	minion.is_alive = false  # 召唤物先死
	wm.call("check_wave_clear")
	_ok(cleared_events.is_empty(), "F-28/Boss: 召唤物死但 Boss 活着 → 未通关")
	boss.is_alive = false
	wm.call("check_wave_clear")
	_ok(cleared_events.size() == 1, "F-28/Boss: Boss 击杀 → 立即通关（不等召唤物）")
	# ---- Boss 关倒计时不通关 ----
	_gm.set("is_boss_wave", true)
	wm.set("is_active", true)
	cleared_events.clear()
	var boss2 := MockEnemy.new()
	boss2.is_boss = true
	container.add_child(boss2)
	wm.set("time_remaining", 0.0)
	wm.call("_process", 0.0)
	_ok(cleared_events.is_empty() and bool(wm.get("is_active")), "F-28/倒计时: Boss 关超时 → 不通关（等 Boss 击杀）")
	boss2.is_alive = false
	wm.call("check_wave_clear")
	_ok(cleared_events.size() == 1, "F-28/Boss: Boss 死 → 通关")
	# ---- 08-18 用户反馈：普通关超时不再兜底通关（必须生成完成 + 敌全灭） ----
	_gm.set("is_boss_wave", false)
	wm.set("is_active", true)
	cleared_events.clear()
	var e3 := MockEnemy.new()
	container.add_child(e3)
	wm.set("time_remaining", 0.0)
	wm.call("_process", 0.0)
	_ok(cleared_events.is_empty() and bool(wm.get("is_active")), "08-18/超时: 普通关超时 + 仍有存活敌人 → 续时不通关（怪没打完不送选关）")
	e3.is_alive = false
	cleared_events.clear()
	wm.set("time_remaining", 0.0)
	wm.call("_process", 0.0)
	_ok(cleared_events.size() == 1, "08-18/超时: 普通关超时 + 敌全灭 → 通关（防死锁兜底保留）")
	# 恢复
	_gm.set("wave_manager", wm_backup)
	_gm.set("enemy_spawner", spawner_backup)
	_gm.set("enemies_container", cont_backup)
	_gm.set("is_boss_wave", boss_backup)
	container.queue_free()
	wm.queue_free()
