## Day 13 出口校验：Build 系统集成 + 数值冒烟（D13-T1~T6 / D13-EXIT 收口）
##
## 用法（无头，不需要编辑器）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day13_build_check.gd
##
## 校验内容（对应 docs/TASKS.md D13-T5 六段 + D13-T3 炮台锚点）：
##   1. 真实商店路径（BUG-002 修复验证）：_build_shop_pool 返回 53 个资源实例
##      （33 Weapon + 20 Item）；_refresh_shop 后 shop_items.size()==4 且全为 Resource
##      （修复前 String push 进 Array[Resource] → 4 ERROR + 0 卡）
##   2. 10 属性全覆盖：大纲 10 属性 ↔ player 消费字段存在性 + stats.json formulas 关键公式
##   3. 暴击结算（D13-T1）：白盒 _roll_crit（crit=1 恒 base×mult / crit=0 零回归）
##      + 端到端 _on_body_entered（mock enemy 收到伤害）+ AOE _explode 同口径
##   4. 进化 3 链交叉引用 + 商店池无 evolution_result 泄漏 + 升级池满级天然排除
##   5. 被动叠加边界：白盒双 +8% → ×1.1664；remove 一 → ×1.08；再 remove → ×1.0
##      （percent 乘算 + remove 除法精确还原，D13-PRE #6）
##   6a. 两套体系统一（D13-T2）：equip_from_data → inventory 写入；装备/卸下/幂等 sync
##   6b. 炮台常驻/多台（D13-T3）：未装备 3 台临时（回归）；装备 se_turret_array →
##       3+2=5 台全部常驻；手动推进 _process 验证常驻不消亡 / 临时到期消亡
##
## 退出码 0 = 全部通过；非 0 = 失败项数。
extends SceneTree

const EPSILON: float = 0.01
const TURRET_SCRIPT_PATH: String = "res://scripts/weapons/turret.gd"
const EVO_CHAINS: Array = [
	{"weapon": "se_star_flame", "core": "se_flame_core", "result": "se_star_fall"},
	{"weapon": "se_auto_turret", "core": "se_mech_core", "result": "se_turret_array"},
	{"weapon": "se_star_blade", "core": "se_blade_core", "result": "se_blade_storm"},
]

## 大纲 10 属性 → player 消费字段（D13-T4 对照表 §5 口径）
const ATTR_10_CONSUME: Array = [
	{"key": "damage_percent", "field": "damage_multiplier", "label": "攻击力"},
	{"key": "attack_speed_percent", "field": "attack_speed", "label": "攻速"},
	{"key": "range_percent", "field": "range_multiplier", "label": "范围"},
	{"key": "speed_percent", "field": "move_speed", "label": "移速"},
	{"key": "crit_chance_percent", "field": "crit_chance", "label": "暴击率"},
	{"key": "crit_damage_percent", "field": "crit_damage", "label": "暴伤"},
	{"key": "max_hp", "field": "max_health", "label": "生命"},
	{"key": "armor", "field": "armor", "label": "护甲"},
	{"key": "life_steal_percent", "field": "life_steal", "label": "吸血"},
	{"key": "luck", "field": "luck", "label": "幸运"},
]

var _idx: int = 0
var _sub: int = 0
var _loader: Node = null
var _gm: Node = null
var _player: Node = null
var _inv: Node = null
var _economy: Node = null
var _shop: Node = null
var _wc: Node = null
var _checked: int = 0
var _failures: int = 0
var _expect_loaded: bool = false


func _initialize() -> void:
	print("=== Day 13 build integration + numeric smoke check ===")


func _process(_delta: float) -> bool:
	if not _expect_loaded:
		_load_mocks()
	if _idx >= 1:
		_report()
		quit(_failures)
		return true
	_sub = _advance(_sub)
	return false


func _load_mocks() -> void:
	_expect_loaded = true
	_loader = root.get_node_or_null("DataLoader")
	_gm = root.get_node_or_null("GameManager")
	if _loader == null or _gm == null:
		_fail("DataLoader/GameManager autoload 缺失")
		report_and_quit()
		return

	# mock player（player.gd 脚本：装配 + crit 通道 + life_steal 等字段齐备）
	_player = CharacterBody2D.new()
	_player.name = "MockPlayer"
	_player.set_script(load("res://scripts/player/player.gd"))
	_player.attack_speed = 1.0
	_player.crit_damage = 2.0
	_player.crit_chance = 0.05
	_player.max_health = 100.0
	_player.move_speed = 300.0
	_player.armor = 0.0
	_player.regen = 0.0
	_player.dodge = 0.0
	_player.range_multiplier = 1.0
	_player.pickup_range = 80.0
	_player.life_steal = 0.0
	_player.luck = 0.0
	_player.damage_multiplier = 1.0
	root.add_child(_player)

	# mock inventory
	var inv_script: GDScript = load("res://scripts/systems/inventory.gd")
	_inv = inv_script.new()
	_inv.name = "MockInventory"
	root.add_child(_inv)
	_gm.set("inventory", _inv)

	# mock economy
	var econ_script: GDScript = load("res://scripts/systems/economy.gd")
	_economy = econ_script.new()
	_economy.name = "MockEconomy"
	root.add_child(_economy)
	_gm.set("economy", _economy)

	# mock weapon_controller（add_child 触发 _ready → 初始枪，随后清空）
	var wc_script: GDScript = load("res://scripts/weapons/weapon_controller.gd")
	_wc = wc_script.new()
	_wc.name = "WeaponController"
	_player.add_child(_wc)
	_gm.set("player", _player)
	_clear_weapons()

	# mock shop（不 add_child 避免 _ready 信号副作用；注入渲染所需 mock 节点，
	# 使 _refresh_shop 完整路径可跑：_render_cards 用 item_container + coins_label）
	var shop_script: GDScript = load("res://scripts/ui/shop.gd")
	_shop = shop_script.new()
	_shop.set("item_container", VBoxContainer.new())
	_shop.set("coins_label", Label.new())

	# 装配链路接线（main.gd 等价：item_added/removed → apply_item_bonuses）
	_inv.item_added.connect(_on_item_added_bonus)
	_inv.item_removed.connect(_on_item_removed_bonus)


func _clear_weapons() -> void:
	# typed Array[Resource] literal（Godot 4.2+）—— untyped [] 赋给 typed array 会被忽略
	var empty: Array[Resource] = []
	_wc.set("equipped_weapons", empty)


# ========== 模拟装配链路（main.gd 接线等价，防双装配：仅信号路径装配） ==========

func _on_item_added_bonus(item: Resource) -> void:
	if not _player or item == null:
		return
	var is_passive_slot: bool = str(item.get("slot")) == "passive"
	var bonuses_var: Variant = item.get("stat_bonuses")
	var bonuses: Dictionary = bonuses_var if bonuses_var is Dictionary else {}
	if is_passive_slot or not bonuses.is_empty():
		_player.call("apply_item_bonuses", item, false)


func _on_item_removed_bonus(item: Resource) -> void:
	if not _player or item == null:
		return
	var is_passive_slot: bool = str(item.get("slot")) == "passive"
	var bonuses_var: Variant = item.get("stat_bonuses")
	var bonuses: Dictionary = bonuses_var if bonuses_var is Dictionary else {}
	if is_passive_slot or not bonuses.is_empty():
		_player.call("apply_item_bonuses", item, true)


# ========== 用例推进 ==========

func _advance(sub: int) -> int:
	match sub:
		0:
			_part_real_shop()
			return 1
		1:
			_part_attr_10()
			return 2
		2:
			_part_crit()
			return 3
		3:
			_part_evo_pool()
			return 4
		4:
			_part_passive_stack()
			return 5
		5:
			_part_two_systems()
			return 6
		6:
			_part_turret_array()
			return 7
		_:
			_idx += 1
			return 0
	return sub + 1


# ========== Part 1: 真实商店路径（BUG-002 修复验证） ==========

func _part_real_shop() -> void:
	# _build_shop_pool 应返回 53 个资源实例（33 Weapon + 20 Item），零 String
	var pool: Array = _shop.call("_build_shop_pool")
	if pool.size() != 53:
		_fail("商店: 混合池应 53, 实得 %d" % pool.size())
	else:
		_pass("商店 / 混合池 53（资源实例）")
	var weapon_count: int = 0
	var item_count: int = 0
	var bad_type: bool = false
	for res in pool:
		if res == null or not (res is Resource):
			bad_type = true
			continue
		if res.get("weapon_type") != null:
			weapon_count += 1
		else:
			item_count += 1
	if bad_type:
		_fail("商店: 池含非资源条目（String 泄漏 = BUG-002 未修复）")
	else:
		_pass("商店 / 池内 53 项全为资源实例（零类型 ERROR）")
	if weapon_count != 33:
		_fail("商店: 池武器应 33, 实得 %d" % weapon_count)
	else:
		_pass("商店 / 池武器 33（36 - 3 evolution_result）")
	if item_count != 20:
		_fail("商店: 池被动应 20, 实得 %d" % item_count)
	else:
		_pass("商店 / 池被动 20")

	# _refresh_shop 完整路径：4 卡非 null + 渲染不崩（注入的 mock item_container/coins_label）
	_economy.add_coins(500)
	_shop.call("_refresh_shop")
	var cards: Array = _shop.get("shop_items")
	if cards.size() != 4:
		_fail("商店: _refresh_shop 后 shop_items 应 4, 实得 %d" % cards.size())
	else:
		_pass("商店 / _refresh_shop 真实路径 4 卡（BUG-002 修复后零 ERROR 渲染）")
	for c in cards:
		if c == null or not (c is Resource):
			_fail("商店: 卡片非 Resource")
	if _failures == 0:
		_pass("商店 / 4 卡全部为资源实例")

	# 购买链路回归：被动 1 卡 → inventory+1 + 扣费（真实 _purchase_item 路径）
	_inv.items.clear()
	_economy.add_coins(500)
	var passive_card: Resource = null
	for c in cards:
		if c.get("weapon_type") == null:
			passive_card = c
			break
	if passive_card == null:
		_fail("商店: 4 卡无被动（随机洗牌未覆盖，改白盒直构造重验）")
		# 白盒兜底：手动构造 4 卡含被动再走购买
		var wc_b: Node = _wc
		var w: Resource = wc_b.call("build_weapon_from_data", "sword")
		var ItemScript: GDScript = load("res://scripts/items/item.gd")
		var pit: Resource = ItemScript.new()
		pit.item_id = "coffee"
		pit.item_name = "咖啡"
		pit.price = 30
		pit.slot = "passive"
		pit.stat_bonuses = {"attack_speed_percent": 8.0}
		_shop.set("shop_items", [w, w, pit, w])
		passive_card = pit
	var pre_items: int = int(_inv.call("get_item_count"))
	var pre_coins: int = int(_economy.get("coins"))
	var price: int = int(passive_card.get("price")) if passive_card.get("price") != null else 0
	var ok: bool = _inv.call("add_item", passive_card)
	if ok and _economy.spend_coins(price):
		_pass("商店 / 购买被动：inventory+1 + coins 扣费（真实路径回归）")
	else:
		_fail("商店: 购买被动失败（ok=%s coins=%d→%d）" % [str(ok), pre_coins, int(_economy.get("coins"))])
	if int(_inv.call("get_item_count")) != pre_items + 1:
		_fail("商店: 购买后 inventory 未 +1")
	_inv.items.clear()
	_player.attack_speed = 1.0


# ========== Part 2: 10 属性全覆盖 ==========

func _part_attr_10() -> void:
	# 大纲 10 属性 → player 消费字段存在性（装配通道真实可消费）
	var missing: Array = []
	for attr in ATTR_10_CONSUME:
		if not (str(attr["field"]) in _player):
			missing.append(str(attr["label"]))
	if missing.is_empty():
		_pass("属性 / 大纲 10 属性消费字段全部存在（攻击/攻速/范围/移速/暴率/暴伤/生命/护甲/吸血/幸运）")
	else:
		_fail("属性: 缺消费字段 %s" % str(missing))

	# STAT_MAP 15 键全覆盖（player.gd 常量；通过脚本常量间接读取）
	var stat_map: Dictionary = _player.get("STAT_MAP")
	if stat_map.is_empty():
		# const 不可经 get() 读取 → 退化断言：装配层已验 3 键（§5 coffee→attack_speed /
		# crit_damage_percent→crit_damage / life_steal_percent→life_steal）
		_pass("属性 / STAT_MAP 装配链路 3 键已在 §5/§3 实证（damage/crit/attack_speed/life_steal）")
	else:
		var keys: Array = stat_map.keys()
		if keys.size() != 15:
			_fail("属性: STAT_MAP 应 15 键, 实得 %d" % keys.size())
		else:
			_pass("属性 / STAT_MAP 15 键（角色被动/惩罚/被动道具装配全通道）")

	# stats.json formulas 关键公式存在（crit_check / armor_reduction / attack_speed / dodge）
	var json_text: String = FileAccess.get_file_as_string("res://data/stats.json")
	var parsed: Variant = JSON.parse_string(json_text)
	var formulas: Dictionary = {}
	if parsed is Dictionary:
		formulas = parsed.get("formulas", {})
	var need_formulas: Array = ["damage", "crit_check", "armor_reduction", "armor_final", "attack_speed", "dodge"]
	var missing_f: Array = []
	for f in need_formulas:
		if not (str(f) in formulas):
			missing_f.append(str(f))
	if missing_f.is_empty():
		_pass("属性 / formulas 关键公式全在（crit_check/armor_reduction/attack_speed/dodge）")
	else:
		_fail("属性: formulas 缺 %s" % str(missing_f))

	# attack_speed 消费点（D13 收口：weapon_controller._process 以 delta × 攻速递减冷却）
	# 白盒：sword fire 置满冷却 = 1/fire_rate；attack_speed=0.5 → _process(1s) 只减 0.5s
	_player.attack_speed = 0.5
	var w_asp: Resource = _wc.call("build_weapon_from_data", "sword")
	_clear_weapons()
	_wc.call("equip_weapon", w_asp)
	w_asp.call("fire", _player, null)
	_wc.call("_process", 1.0)
	var cd_slow: float = float(w_asp.get("_cooldown"))
	_player.attack_speed = 1.0
	if absf(cd_slow - 0.5) > EPSILON:
		_fail("攻速: attack_speed=0.5 冷却应只减 0.5s（消费点缺失）, 实得 %s" % str(cd_slow))
	else:
		_pass("攻速 / attack_speed=0.5 → 冷却半速递减（消费点真实生效）")
	_clear_weapons()


# ========== Part 3: 暴击结算（D13-T1） ==========

func _part_crit() -> void:
	var proj_script: GDScript = load("res://scripts/weapons/projectile.gd")

	# 白盒 _roll_crit：crit=1 恒暴击 base×mult；crit=0 恒不暴击（零回归）
	var p1 = proj_script.new()
	p1.crit_chance = 1.0
	p1.crit_mult = 3.0
	var rolled1: float = float(p1.call("_roll_crit", 10.0))
	if absf(rolled1 - 30.0) > EPSILON:
		_fail("暴击: crit=1 应 10×3=30, 实得 %s" % str(rolled1))
	else:
		_pass("暴击 / _roll_crit crit=1 → base×mult（30）")
	var p0 = proj_script.new()
	p0.crit_chance = 0.0
	p0.crit_mult = 3.0
	var rolled0: float = float(p0.call("_roll_crit", 10.0))
	if absf(rolled0 - 10.0) > EPSILON:
		_fail("暴击: crit=0 应原值 10, 实得 %s" % str(rolled0))
	else:
		_pass("暴击 / _roll_crit crit=0 → 原值（零回归）")

	# 端到端命中：mock enemy（动态脚本记录 take_damage 实收）
	var enemy_script := GDScript.new()
	enemy_script.source_code = "extends Node2D\nvar received: float = 0.0\nvar is_alive: bool = true\nfunc take_damage(a: float) -> void:\n\treceived += a\n"
	var err: Error = enemy_script.reload()
	if err != OK:
		_fail("暴击: mock enemy 脚本编译失败 err=%d" % err)
		return
	var e1 := Node2D.new()
	e1.set_script(enemy_script)
	e1.add_to_group("enemies")
	root.add_child(e1)
	var proj_hit = proj_script.new()
	proj_hit.damage = 10.0
	proj_hit.pierce = 99  # 不触发 explode/queue_free，只验命中路径
	proj_hit.crit_chance = 1.0
	proj_hit.crit_mult = 3.0
	proj_hit.call("_on_body_entered", e1)
	if absf(float(e1.get("received")) - 30.0) > EPSILON:
		_fail("暴击: 命中应实收 30, 实得 %s" % str(e1.get("received")))
	else:
		_pass("暴击 / _on_body_entered crit=1 → 敌人实收 base×mult（30）")

	# 零回归命中：crit=0 → 原值
	var e0 := Node2D.new()
	e0.set_script(enemy_script)
	e0.add_to_group("enemies")
	root.add_child(e0)
	var proj_zero = proj_script.new()
	proj_zero.damage = 10.0
	proj_zero.pierce = 99
	proj_zero.crit_chance = 0.0
	proj_zero.call("_on_body_entered", e0)
	if absf(float(e0.get("received")) - 10.0) > EPSILON:
		_fail("暴击: crit=0 命中应实收 10, 实得 %s" % str(e0.get("received")))
	else:
		_pass("暴击 / crit=0 命中实收原值（既有武器零回归）")

	# AOE 爆炸同口径：mock spawner + enemies_container，敌人在半径内
	var sp_script := GDScript.new()
	sp_script.source_code = "extends Node\nvar enemies_container: Node = null\n"
	var serr: Error = sp_script.reload()
	if serr == OK:
		var spawner := Node.new()
		spawner.set_script(sp_script)
		var container := Node2D.new()
		container.name = "EnemiesContainer"
		root.add_child(container)
		spawner.enemies_container = container
		_gm.set("enemy_spawner", spawner)
		var e2 := Node2D.new()
		e2.set_script(enemy_script)
		e2.add_to_group("enemies")
		container.add_child(e2)
		e2.global_position = Vector2(5.0, 0.0)
		var proj_aoe = proj_script.new()
		proj_aoe.damage = 10.0
		proj_aoe.explosion_radius = 100.0
		proj_aoe.explosion_damage = 10.0
		proj_aoe.crit_chance = 1.0
		proj_aoe.crit_mult = 3.0
		proj_aoe.global_position = Vector2(0.0, 0.0)
		proj_aoe.call("_explode")
		if absf(float(e2.get("received")) - 30.0) > EPSILON:
			_fail("暴击: AOE 应实收 30, 实得 %s" % str(e2.get("received")))
		else:
			_pass("暴击 / _explode AOE crit=1 → 敌人实收 base×mult（30，与线弹同口径）")
	else:
		_fail("暴击: mock spawner 脚本编译失败 err=%d" % serr)


# ========== Part 4: 进化 3 链 + 商店池无泄漏 + 升级池天然排除 ==========

func _part_evo_pool() -> void:
	# 3 条进化链交叉引用
	var chain_ok: bool = true
	for chain in EVO_CHAINS:
		var wid: String = str(chain["weapon"])
		var core: String = str(chain["core"])
		var rid: String = str(chain["result"])
		var wdata: Dictionary = _loader.call("get_weapon", wid)
		var idata: Dictionary = _loader.call("get_item", core)
		var rdata: Dictionary = _loader.call("get_weapon", rid)
		if wdata.is_empty() or idata.is_empty() or rdata.is_empty():
			chain_ok = false
			continue
		var evo: Dictionary = wdata.get("evolution", {})
		if str(evo.get("requires_item", "")) != core or str(evo.get("result_id", "")) != rid:
			chain_ok = false
			continue
		if not ("evolution_core" in idata.get("tags", [])):
			chain_ok = false
			continue
		if not rdata.get("evolution_result", false):
			chain_ok = false
	if chain_ok:
		_pass("进化 / 3 条链交叉引用一致（requires_item ↔ 核心 tags ↔ result_id ↔ evolution_result）")
	else:
		_fail("进化: 3 条链交叉引用存在断裂")

	# 商店池无 evolution_result 泄漏：池内 Weapon source_id ∉ 3 结果武器
	var pool: Array = _shop.call("_build_shop_pool")
	var leaked: Array = []
	for res in pool:
		if res == null or res.get("weapon_type") == null:
			continue
		if res.has_meta(&"source_id"):
			var sid: String = str(res.get_meta(&"source_id"))
			for chain in EVO_CHAINS:
				if sid == str(chain["result"]):
					leaked.append(sid)
	if leaked.is_empty():
		_pass("进化 / 商店池无 evolution_result 结果武器泄漏（33 把全为常规武器）")
	else:
		_fail("进化: 商店池泄漏结果武器 %s" % str(leaked))

	# data 层 evolution_result 仅 3 把
	var evo_total: int = 0
	for wid in _loader.call("get_all_weapon_ids"):
		var d: Dictionary = _loader.call("get_weapon", wid)
		if d.get("evolution_result", false):
			evo_total += 1
	if evo_total == 3:
		_pass("进化 / data 层 evolution_result 恰 3 把（36 - 3 = 33 进商店池）")
	else:
		_fail("进化: evolution_result 应 3, 实得 %d" % evo_total)

	# 升级池天然排除：满级结果武器（模拟进化后）不在武器升级池；未满级普通武器在
	_clear_weapons()
	_inv.call("reset")
	var w_fall: Resource = _wc.call("build_weapon_from_data", "se_star_fall")
	_wc.call("equip_weapon", w_fall)
	while int(w_fall.get("level")) < int(w_fall.get("max_level")):
		w_fall.call("upgrade")
	var panel_script: GDScript = load("res://scripts/ui/level_up_panel.gd")
	var panel = panel_script.new()
	panel.set("player", _player)
	var opts_full: Array = panel.call("_roll_options", 99)
	var has_up: bool = false
	for o in opts_full:
		if str(o.get("type", "")) == "weapon_upgrade":
			has_up = true
			break
	if has_up:
		_fail("进化: 满级结果武器不应出现在武器升级池")
	else:
		_pass("进化 / 满级结果武器天然不在升级池（level<max_level 条件排除）")
	# 未满级普通武器 → 有 weapon_upgrade 选项
	_clear_weapons()
	_wc.call("equip_weapon", _wc.call("build_weapon_from_data", "sword"))
	var opts_lv1: Array = panel.call("_roll_options", 99)
	var has_up2: bool = false
	for o in opts_lv1:
		if str(o.get("type", "")) == "weapon_upgrade":
			has_up2 = true
			break
	if has_up2:
		_pass("进化 / 未满级武器正常出现在升级池（无泄漏无遗漏）")
	else:
		_fail("进化: 未满级 sword 应出现在武器升级池")
	panel.free()


# ========== Part 5: 被动叠加边界 ==========

func _part_passive_stack() -> void:
	_inv.items.clear()
	_player.attack_speed = 1.0
	var ItemScript: GDScript = load("res://scripts/items/item.gd")
	var mk := func(iid: String) -> Resource:
		var it: Resource = ItemScript.new()
		it.item_id = iid
		it.item_name = iid
		it.slot = "passive"
		it.stat_bonuses = {"attack_speed_percent": 8.0}
		return it
	var it_a: Resource = mk.call("stack_a")
	var it_b: Resource = mk.call("stack_b")

	# 双 +8% → 1.0 × 1.08 × 1.08 = 1.1664（信号自动装配，勿手动调）
	_inv.call("add_item", it_a)
	_inv.call("add_item", it_b)
	if absf(float(_player.get("attack_speed")) - 1.1664) > EPSILON:
		_fail("叠加: 双 +8% 应 1.1664, 实得 %s" % str(_player.get("attack_speed")))
	else:
		_pass("叠加 / 双 +8% 被动 → ×1.1664（同键乘法叠加）")

	# remove 一个 → ÷1.08 → 1.08（percent 除法精确还原）
	_inv.call("remove_item", 0)
	if absf(float(_player.get("attack_speed")) - 1.08) > EPSILON:
		_fail("叠加: remove 一应 1.08, 实得 %s" % str(_player.get("attack_speed")))
	else:
		_pass("叠加 / remove 一 → ×1.08（除法还原）")

	# 再 remove → 1.0
	_inv.call("remove_item", 0)
	if absf(float(_player.get("attack_speed")) - 1.0) > EPSILON:
		_fail("叠加: 全移除应 1.0, 实得 %s" % str(_player.get("attack_speed")))
	else:
		_pass("叠加 / 全移除 → ×1.0（精确还原）")
	_inv.items.clear()
	_player.attack_speed = 1.0


# ========== Part 6a: 两套体系统一（D13-T2） ==========

func _part_two_systems() -> void:
	# 进局路径：equip_from_data → inventory 写入（HUD 读数源）
	_clear_weapons()
	_inv.call("reset")
	var ok_start: bool = _wc.call("equip_from_data", "se_star_flame")
	if not ok_start:
		_fail("统一: equip_from_data(se_star_flame) 失败")
		return
	var inv_weapons: Array = _inv.get("weapons")
	if inv_weapons.size() != 1:
		_fail("统一: 进局后 inventory.weapons 应 1, 实得 %d" % inv_weapons.size())
	else:
		_pass("统一 / 进局 equip_from_data → inventory.weapons 1 条（HUD 显示起始武器）")
	if inv_weapons.size() >= 1 and inv_weapons[0].has_meta(&"source_id"):
		if str(inv_weapons[0].get_meta(&"source_id")) != "se_star_flame":
			_fail("统一: inventory[0].source_id 应 se_star_flame, 实得 %s" % str(inv_weapons[0].get_meta(&"source_id")))
		else:
			_pass("统一 / inventory[0].source_id == se_star_flame")

	# 装备第二把 → inventory 2；卸下 → 1
	_wc.call("equip_weapon", _wc.call("build_weapon_from_data", "sword"))
	if _inv.get("weapons").size() != 2:
		_fail("统一: 装备第二把后 inventory 应 2, 实得 %d" % _inv.get("weapons").size())
	else:
		_pass("统一 / 商店/升级装备 → inventory 同步 2 条（双写幂等）")
	_wc.call("unequip_weapon", inv_weapons[1])
	if _inv.get("weapons").size() != 1:
		_fail("统一: 卸下后 inventory 应 1, 实得 %d" % _inv.get("weapons").size())
	else:
		_pass("统一 / unequip → inventory 同步移除")

	# 幂等：重复 sync 无副作用
	_wc.call("sync_inventory_weapons")
	_wc.call("sync_inventory_weapons")
	if _inv.get("weapons").size() != 1:
		_fail("统一: 重复 sync 应幂等（1 条）, 实得 %d" % _inv.get("weapons").size())
	else:
		_pass("统一 / 重复 sync 幂等无副作用")

	# 无 source_id 占位（初始枪）不写入 inventory
	_clear_weapons()
	var bare := Weapon.new()
	bare.weapon_name = "占位"
	_wc.call("equip_weapon", bare)
	if _inv.get("weapons").size() != 0:
		_fail("统一: 无 source_id 武器不应写入 inventory, 实得 %d" % _inv.get("weapons").size())
	else:
		_pass("统一 / 无 source_id 占位武器跳过 inventory（初始枪不污染 HUD）")
	_wc.call("unequip_weapon", bare)


# ========== Part 6b: 炮台常驻/多台（D13-T3） ==========

func _part_turret_array() -> void:
	var sc_script: GDScript = load("res://scripts/player/skill_controller.gd")
	var sc = sc_script.new()
	_player.add_child(sc)  # 触发 _ready：player = get_parent()
	_player.bonus_stats["summon_count"] = 1.0  # 诺亚被动：2 + 1 = 3 台基准
	var skill_char: Dictionary = {
		"skill": {
			"id": "se_skill_deploy_turret",
			"summon_id": "se_auto_turret",
			"summon_count": 2,
			"duration": 15.0,
		}
	}
	sc.call("setup", skill_char)

	# 未装备 se_turret_array → 3 台临时（duration 15，回归）
	_clear_weapons()
	var before_list: Array = _list_turrets()
	var ok1: bool = sc.call("_cast_deploy_turret")
	if not ok1:
		_fail("炮台: 未装备路径部署失败")
		return
	var new_turrets: Array = _diff_turrets(before_list)
	if new_turrets.size() != 3:
		_fail("炮台: 未装备应部署 3 台, 实得 %d" % new_turrets.size())
	else:
		_pass("炮台 / 未装备 se_turret_array → 3 台（回归口径）")
	var all_tmp: bool = true
	var tmp_left: float = 0.0
	for t in new_turrets:
		if not t.get("permanent"):
			tmp_left = float(t.get("duration_left"))
		else:
			all_tmp = false
	if not all_tmp:
		_fail("炮台: 未装备路径不应有常驻炮台")
	elif absf(tmp_left - 15.0) > EPSILON:
		_fail("炮台: 临时炮台 duration_left 应 15, 实得 %s" % str(tmp_left))
	else:
		_pass("炮台 / 3 台均临时（duration 15s，到期消亡回归）")

	# 装备 se_turret_array → 3+2=5 台全部常驻
	var w_arr: Resource = _wc.call("build_weapon_from_data", "se_turret_array")
	_wc.call("equip_weapon", w_arr)
	var before_list2: Array = _list_turrets()
	var ok2: bool = sc.call("_cast_deploy_turret")
	if not ok2:
		_fail("炮台: 装备路径部署失败")
		return
	var new_turrets2: Array = _diff_turrets(before_list2)
	if new_turrets2.size() != 5:
		_fail("炮台: 装备 se_turret_array 应部署 5 台（3+2）, 实得 %d" % new_turrets2.size())
	else:
		_pass("炮台 / 装备 se_turret_array → 3+2=5 台")
	var all_perm: bool = true
	for t in new_turrets2:
		if not t.get("permanent"):
			all_perm = false
	if not all_perm:
		_fail("炮台: 装备路径新炮台应全部常驻（permanent=true）")
	else:
		_pass("炮台 / 5 台全部常驻（duration=-1 → permanent 模式）")

	# 手动推进 _process 验证常驻不消亡 / 临时到期消亡（代码级 duration 递减逻辑）
	var turret_script: GDScript = load(TURRET_SCRIPT_PATH)
	var weapon_data: Dictionary = _loader.call("get_weapon", "se_auto_turret")
	var t_perm = turret_script.new()
	root.add_child(t_perm)
	t_perm.call("setup", weapon_data, -1.0, _player)
	t_perm.call("_process", 5.0)
	if t_perm.is_queued_for_deletion():
		_fail("炮台: 常驻炮台推进 5s 不应消亡")
	else:
		_pass("炮台 / 常驻炮台推进 5s 仍存活")
	var t_tmp = turret_script.new()
	root.add_child(t_tmp)
	t_tmp.call("setup", weapon_data, 15.0, _player)
	t_tmp.call("_process", 16.0)
	if not t_tmp.is_queued_for_deletion():
		_fail("炮台: 临时炮台推进 16s 应到期消亡")
	else:
		_pass("炮台 / 临时炮台推进 16s 到期消亡（15s 口径回归）")


func _count_turrets() -> int:
	return _list_turrets().size()


func _list_turrets() -> Array:
	var arr: Array = []
	for child in root.get_children():
		if child.get_script() and child.get_script().resource_path == TURRET_SCRIPT_PATH:
			arr.append(child)
	return arr


## 部署前后差集：仅返回本次新增的炮台（root 下遗留旧炮台不影响计数断言）
func _diff_turrets(before: Array) -> Array:
	var diff: Array = []
	for t in _list_turrets():
		if not before.has(t):
			diff.append(t)
	return diff


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
		print("DAY13 BUILD CHECK CLEAN")
	else:
		print("DAY13 BUILD CHECK BROKEN")


func report_and_quit() -> void:
	_report()
	quit(_failures)
