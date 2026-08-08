## Day 28-F31 出口校验：武器升级体系（F-31 · P0 用户拍板 · D28-F31-1~3 + EXIT）
##
## 用法（无头，不需要编辑器）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day28_f31_check.gd
##
## 校验内容（对应 docs/SOLUTION_PLAN.md 第 14 轮，池口径 = 23 武器 + 23 被动 + 2 遗物 + 1 服务 = 49）：
##   §1 商店池（F31-1/F31-3）：总池 49 / 武器段 23 / 10 起始 id 零出现 / 被动 23 / 遗物 2 /
##      anvil 服务 1（price 120）/ 零 String 泄漏
##   §2 升级面板（F31-2）：_roll_options(99) 无武器/未满级武器场景 → 零 weapon_upgrade +
##      属性池可 roll（非空）；满级+持核心 → 必含 evolution（F-20 保底不回归）
##   §3 铁砧闭环（F31-3）：无可升级武器 → 拒绝不扣费且商品保留；可升级 →
##      _apply_anvil_upgrade +1 级 + 扣 120G + 商品移除 + 面板关闭；满级武器不在可升级列表
##   §4 回归抽样：desc_builder shop_weapon_upgrade 中文映射保留 / GameManager 事件奖励
##      weapon_upgrade 路径保留 / get_starting_weapon_ids 10 把含 se_holy_staff
##
## 退出码 0 = 全部通过；非 0 = 失败项数。
extends SceneTree

const EPSILON: float = 0.001

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
	print("=== Day 28-F31 weapon upgrade system check ===")


## SceneTree 模式驱动：首帧装载 mock，逐段推进（day24_f13 范式，无无参 _advance）
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
		_report()
		quit(_failures)
		return

	# mock player（player.gd 脚本：装配 + 属性字段齐备）
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

	# mock shop（不 add_child 避免 _ready 信号副作用；注入渲染所需 mock 节点）
	var shop_script: GDScript = load("res://scripts/ui/shop.gd")
	_shop = shop_script.new()
	_shop.set("item_container", VBoxContainer.new())
	_shop.set("coins_label", Label.new())


func _clear_weapons() -> void:
	# typed Array[Resource] literal（Godot 4.2+）—— untyped [] 赋给 typed array 会被忽略
	var empty: Array[Resource] = []
	_wc.set("equipped_weapons", empty)


func _advance(sub: int) -> int:
	match sub:
		0:
			_part_shop_pool()
			return 1
		1:
			_part_level_panel()
			return 2
		2:
			_part_anvil()
			return 3
		3:
			_part_regression()
			return 4
		4:
			_report()
			quit(_failures)
	return 4


# ========== §1 商店池口径（F31-1 初始武器出池 + F31-3 服务池） ==========

func _part_shop_pool() -> void:
	var pool: Array = _shop.call("_build_shop_pool")
	_ok(pool.size() == 49,
		"§1/总池: 应 49（23 武器 + 23 被动 + 2 遗物 + 1 服务）, 实得 %d" % pool.size())

	var weapons: int = 0
	var passives: int = 0
	var relics: int = 0
	var services: int = 0
	var bad_type: bool = false
	var starting_leaked: Array = []
	var starting_ids: Array = _loader.call("get_starting_weapon_ids")
	for res in pool:
		if res == null or not (res is Resource):
			bad_type = true
			continue
		if res.get("weapon_type") != null:
			weapons += 1
			if res.has_meta(&"source_id"):
				var sid: String = str(res.get_meta(&"source_id"))
				if starting_ids.has(sid):
					starting_leaked.append(sid)
		else:
			var iid: String = _gstr(res, "item_id")
			if iid.is_empty():
				continue
			var idata: Dictionary = _loader.call("get_item", iid)
			if idata.is_empty():
				continue
			if bool(idata.get("is_passive", false)):
				passives += 1
			elif str(idata.get("slot", "")) == "relic":
				relics += 1
			elif bool(idata.get("effects", {}).get("shop_weapon_upgrade", false)):
				services += 1
	_ok(not bad_type, "§1/类型: 池内全为 Resource 实例（零 String 泄漏 = BUG-002 不回归）")
	_ok(weapons == 23, "§1/武器段: 应 23（36 - 3 结果 - 10 起始）, 实得 %d" % weapons)
	_ok(starting_leaked.is_empty(), "§1/起始武器: 商店池应零出现（泄漏: %s）" % str(starting_leaked))
	_ok(passives == 23, "§1/被动: 应 23, 实得 %d" % passives)
	_ok(relics == 2, "§1/遗物: 应 2, 实得 %d" % relics)
	_ok(services == 1, "§1/服务: 应 1（anvil）, 实得 %d" % services)

	# anvil 商品细节：price 120 + stat_bonuses.shop_weapon_upgrade true
	var anvil_found: bool = false
	for res in pool:
		if res and _gstr(res, "item_id") == "anvil":
			anvil_found = true
			_ok(_gint(res, "price") == 120, "§1/anvil price: 应 120, 实得 %d" % _gint(res, "price"))
			var sb: Variant = res.get("stat_bonuses")
			_ok(sb is Dictionary and bool((sb as Dictionary).get("shop_weapon_upgrade", false)),
				"§1/anvil effects: stat_bonuses.shop_weapon_upgrade == true")
	_ok(anvil_found, "§1/anvil: 应在商店池")


# ========== §2 升级面板（F31-2 移除武器升级 + F-20 进化保底不回归） ==========

func _part_level_panel() -> void:
	var panel_script: GDScript = load("res://scripts/ui/level_up_panel.gd")
	var panel = panel_script.new()
	panel.set("player", _player)

	# 场景 A：无武器 → 零 weapon_upgrade + 属性池可 roll
	_clear_weapons()
	var opts_empty: Array = panel.call("_roll_options", 99)
	_ok(not _contains_type(opts_empty, "weapon_upgrade") and opts_empty.size() > 0,
		"§2/无武器: 零 weapon_upgrade + 属性池可 roll（%d 项）" % opts_empty.size())

	# 场景 B：未满级普通武器 → 零 weapon_upgrade + 属性池可 roll
	_wc.call("equip_weapon", _wc.call("build_weapon_from_data", "sword"))
	var opts_lv1: Array = panel.call("_roll_options", 99)
	_ok(not _contains_type(opts_lv1, "weapon_upgrade") and opts_lv1.size() > 0,
		"§2/未满级: 零 weapon_upgrade + 属性池可 roll（%d 项）" % opts_lv1.size())

	# 场景 C：满级 + 持核心 → 必含 evolution（F-20 方案 A 保底不回归）
	_clear_weapons()
	_inv.call("reset")
	var w_flame: Resource = _wc.call("build_weapon_from_data", "se_star_flame")
	_wc.call("equip_weapon", w_flame)
	while int(w_flame.get("level")) < int(w_flame.get("max_level")):
		w_flame.call("upgrade")
	_inv.call("add_item_from_data", "se_flame_core")   # 白盒持核心（se_star_flame 进化链核心）
	var opts_evo: Array = panel.call("_roll_options", 99)
	_ok(_contains_type(opts_evo, "evolution"),
		"§2/进化保底: 满级+持核心必含 evolution（F-20 不回归, 实得 %s）" % _opt_types(opts_evo))
	panel.free()


func _contains_type(opts: Array, opt_type: String) -> bool:
	for o in opts:
		if str(o.get("type", "")) == opt_type:
			return true
	return false


func _opt_types(opts: Array) -> String:
	var types: Array = []
	for o in opts:
		var t: String = str(o.get("type", "?"))
		if not types.has(t):
			types.append(t)
	return str(types)


# ========== §3 铁砧 anvil 闭环（F31-3） ==========

func _part_anvil() -> void:
	# 前置：anvil 商品构建（复用 shop._build_item_resource）
	var anvil: Resource = _shop.call("_build_item_resource", "anvil")
	_ok(anvil != null, "§3/前置: _build_item_resource(\"anvil\") 非空")
	if anvil == null:
		return

	# 场景 1：无可升级武器 → 拒绝不扣费（商品保留）
	_clear_weapons()
	_inv.call("reset")
	_economy.set("coins", 500)
	var arr1: Array[Resource] = [anvil]   # typed literal（untyped [] 赋 typed array 会被忽略）
	_shop.set("shop_items", arr1)
	var coins1: int = int(_economy.get("coins"))
	_shop.call("_purchase_item", 0)
	_ok(int(_economy.get("coins")) == coins1, "§3/无武器拒绝: 金币不变（%dG）" % coins1)
	var items_after_reject: Array = _shop.get("shop_items")
	_ok(items_after_reject.size() == 1, "§3/无武器拒绝: 商品保留（size=%d）" % items_after_reject.size())

	# 场景 2：可升级 → _apply_anvil_upgrade +1 级 + 扣 120G + 商品移除 + 面板关闭
	_wc.call("equip_weapon", _wc.call("build_weapon_from_data", "sword"))
	var w_sword: Resource = _wc.get("equipped_weapons")[0]
	var lv_before: int = int(w_sword.get("level"))
	var coins2: int = int(_economy.get("coins"))
	# 先验 UI 构建不崩（CanvasLayer 置顶面板）——未入树节点立即 free 防 RID leak
	_shop.call("_show_anvil_panel", [_wc.get("equipped_weapons")[0]], anvil, 0)
	var al: CanvasLayer = _shop.get("_anvil_layer")
	_ok(al != null, "§3/UI: _show_anvil_panel 构建选择面板（CanvasLayer 置顶）")
	if al != null:
		al.free()
	_shop.set("_anvil_layer", null)
	# 白盒直设状态驱动业务断言（UI 构建已验，避免 queue_free 延迟节点干扰后续场景）
	_shop.set("_anvil_index", 0)
	_shop.set("_anvil_price", 120)
	_shop.set("_anvil_item", anvil)
	_shop.call("_apply_anvil_upgrade", w_sword)
	_ok(int(w_sword.get("level")) == lv_before + 1, "§3/升级: 武器 Lv%d → Lv%d" % [lv_before, int(w_sword.get("level"))])
	_ok(int(_economy.get("coins")) == coins2 - 120, "§3/扣费: 120G 数据驱动（%d → %d）" % [coins2, int(_economy.get("coins"))])
	var items_after_buy: Array = _shop.get("shop_items")
	_ok(items_after_buy.size() == 0, "§3/移除: 商品已移除（size=%d）" % items_after_buy.size())
	_ok(_shop.get("_anvil_layer") == null, "§3/面板: _apply_anvil_upgrade 后已关闭")

	# 场景 3：满级武器不在可升级列表（白盒走 _purchase_item 分支 → 拒绝不扣费）
	_clear_weapons()
	var w_full: Resource = _wc.call("build_weapon_from_data", "sword")
	_wc.call("equip_weapon", w_full)
	while int(w_full.get("level")) < int(w_full.get("max_level")):
		w_full.call("upgrade")
	_economy.set("coins", 500)
	var arr3: Array[Resource] = [_shop.call("_build_item_resource", "anvil")]   # typed literal
	_shop.set("shop_items", arr3)
	var coins3: int = int(_economy.get("coins"))
	_shop.call("_purchase_item", 0)
	_ok(int(_economy.get("coins")) == coins3, "§3/满级: 无可升级 → 拒绝不扣费（%dG）" % coins3)
	_shop.call("_close_anvil_panel")


# ========== §4 回归抽样（保留不红 3 处） ==========

func _part_regression() -> void:
	# ① desc_builder STAT_CN 中文映射保留（F-24 tooltip 面）
	var cn: Variant = DescBuilder.STAT_CN.get("shop_weapon_upgrade", "")
	_ok(str(cn) == "商店武器升级", "§4/desc_builder: shop_weapon_upgrade → 「商店武器升级」（实得 %s）" % str(cn))

	# ② GameManager 事件奖励 weapon_upgrade 路径保留（day16 事件面，与升级面板无关）
	_ok(_gm.has_method("_apply_event_reward"), "§4/事件: GameManager._apply_event_reward 保留")

	# ③ get_starting_weapon_ids 口径：10 把去重 + 含 se_holy_staff（希亚）
	var starting_ids: Array = _loader.call("get_starting_weapon_ids")
	_ok(starting_ids.size() == 10, "§4/起始武器: 应 10 把去重, 实得 %d" % starting_ids.size())
	_ok(starting_ids.has("se_holy_staff"), "§4/起始武器: 含 se_holy_staff（希亚, 反馈专员汇报漏项已补）")


# ========== 基础设施 ==========

## Resource/Object.get 单参（Object.get 无默认值重载）+ null 兜底取 String
func _gstr(obj: Object, key: String, def: String = "") -> String:
	var v: Variant = obj.get(key)
	return str(v) if v != null else def

## Resource/Object.get 单参 + null 兜底取 int
func _gint(obj: Object, key: String, def: int = 0) -> int:
	var v: Variant = obj.get(key)
	return int(v) if v != null else def


func _ok(cond: bool, msg: String) -> void:
	if cond:
		_checked += 1
		print("  PASS  %s" % msg)
	else:
		_failures += 1
		print("  FAIL  %s" % msg)


func _fail(msg: String) -> void:
	_failures += 1
	print("  FAIL  %s" % msg)


func _report() -> void:
	print("=== Day 28-F31: %d 断言, %d 失败 ===" % [_checked, _failures])
	if _failures == 0:
		print("DAY28-F31 CHECK CLEAN")
	else:
		print("DAY28-F31 CHECK FAILED")
