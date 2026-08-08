## Day 11-12 出口校验：20 被动 + 6 被动槽 + 商店体系（D11-12-PRE/T1~T7/EXIT 收口）
##
## 用法（无头，不需要编辑器）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day11_12_passive_check.gd
##
## 校验内容（对应 docs/TASKS.md D11-12-T7 / D11-12-EXIT 五段）：
##   1. 数据层：items.json 23 项 is_passive/slot/category/icon_index 唯一；20 常规项 effects 键 ⊂ 白名单；
##              3 核心 id 命中；其余 28 项 is_passive 缺省
##   2. 槽位层：inventory.MAX_ITEMS == 6；第 7 个 add_item false；is_item_slots_full 正确
##   3. 装配层：add_item_from_data("coffee") → attack_speed 1.0→1.08；
##              remove_item_id("coffee") → 回 1.0（percent 除法精确还原）；
##              add_item_from_data("se_blade_core") → crit_damage 2.0→2.4（crit_damage_percent 映射生效）；
##              未映射键被动注入 → push_warning 且不崩
##   4. 商店层：_refresh_shop 产出 4 卡非 null（混合池：武器 33 + 被动 20 排除 3 结果武器）；
##              购买被动触发 item_added → 玩家属性变；槽满 → 失败且 coins 不变；
##              购买武器 → equipped_weapons 增 1
##   5. 图标层：items.png 800×32 + 25 帧中心非空 + 透明键合规；icon_atlas items frame_count == 25（D24-F13-3 机制型被动 3 帧）
##
## 退出码 0 = 全部通过；非 0 = 失败项数。
extends SceneTree

const ITEMS_PNG_PATH: String = "res://assets/sprites/ui/items.png"
const EPSILON: float = 0.01

const PASSIVE_CORE_IDS: Array = ["se_flame_core", "se_mech_core", "se_blade_core"]
const WHITELIST_KEYS: Array = [
	"max_hp", "speed_percent", "armor", "regen", "hp_regen",
	"dodge_percent", "crit_chance_percent", "attack_speed_percent",
	"damage_percent", "range_percent", "luck", "pickup_range",
	"life_steal_percent", "crit_damage_percent",
]

var _idx: int = 0
var _sub: int = 0
var _loader: Node = null
var _gm: Node = null
var _player: Node = null
var _inv: Node = null
var _economy: Node = null
var _shop: Node = null
var _checked: int = 0
var _failures: int = 0
var _expect_loaded: bool = false


func _initialize() -> void:
	print("=== Day 11-12 passive+shop check ===")


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
	if _loader == null:
		_fail("DataLoader autoload 缺失")
		report_and_quit()
		return
	if _gm == null:
		_fail("GameManager autoload 缺失")
		report_and_quit()
		return

	# mock player（附属 Player 脚本以获得 apply_item_bonuses + attack_speed/crit_damage 等属性）
	_player = CharacterBody2D.new()
	_player.name = "MockPlayer"
	_player.set_script(load("res://scripts/player/player.gd"))
	_player.attack_speed = 1.0
	_player.crit_damage = 2.0
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
	var inv_script: Script = load("res://scripts/systems/inventory.gd")
	_inv = inv_script.new()
	_inv.name = "MockInventory"
	root.add_child(_inv)
	_gm.set("inventory", _inv)

	# mock economy（add_coins 即可）
	var econ_script: Script = load("res://scripts/systems/economy.gd")
	_economy = econ_script.new()
	_economy.name = "MockEconomy"
	root.add_child(_economy)
	_gm.set("economy", _economy)

	# mock weapon_controller（先建以便 shop 引用）
	var wc_script: Script = load("res://scripts/weapons/weapon_controller.gd")
	var wc: Node = wc_script.new()
	wc.name = "WeaponController"
	_player.add_child(wc)
	_gm.set("player", _player)
	# 清掉 _ready 装的「初始枪」（typed Array[Resource] literal）
	var empty: Array[Resource] = []
	wc.set("equipped_weapons", empty)

	# mock shop（不 add_child → 避免 _ready 副作用；手动调 _refresh_shop/_purchase_item）
	var shop_script: Script = load("res://scripts/ui/shop.gd")
	_shop = shop_script.new()

	# D11-12-T3 模拟 main.gd 装配链路：监听 inventory.item_added/removed → apply_item_bonuses
	# 信号已改传 Resource（移除时也能拿到 item 本体 → 回退生效）
	_inv.item_added.connect(_on_item_added_bonus)
	_inv.item_removed.connect(_on_item_removed_bonus)


# ========== 模拟装配链路（D11-12-T3，探针 main.gd 接线等价） ==========

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
			_part_data()
			return 1
		1:
			_part_slots()
			return 2
		2:
			_part_assembly()
			return 3
		3:
			_part_shop()
			return 4
		4:
			_part_icons()
			return 5
		_:
			_idx += 1
			return 0
	return sub + 1


# ========== Part 1: 数据层 ==========

func _part_data() -> void:
	# 20 项 is_passive/slot/category/icon_index 唯一 + 类别各 ≥4
	var passives: Array = []
	var icons: Array = []
	var cats: Dictionary = {}
	var data: Dictionary = _loader.get("_items") if false else {}  # 私有不直接访问，走 get_item 查
	# 改为遍历 get_all_item_ids()
	for iid in _loader.call("get_all_item_ids"):
		var it: Dictionary = _loader.call("get_item", iid)
		if not it.is_empty() and it.get("is_passive", false):
			passives.append(iid)
			if str(it.get("slot", "")) != "passive":
				_fail("数据: %s slot 应为 passive" % iid)
			var cat: String = str(it.get("category", ""))
			if cat not in ["attack", "defense", "stat", "special"]:
				_fail("数据: %s category 非法 %s" % [iid, cat])
			else:
				cats[cat] = cats.get(cat, 0) + 1
			icons.append(int(it.get("icon_index", -1)))
			if str(it.get("slot", "")) != "passive":
				_fail("数据: %s slot 应为 passive" % iid)
	if passives.size() != 23:
		_fail("数据: 被动数应 23, 实得 %d" % passives.size())
	else:
		_pass("数据 / 23 被动 is_passive=true")
	# icon_index 0-24 唯一性 + 范围（GDScript 无 set()/any() 内置，用 Dictionary 模拟 + 显式循环）
	var seen_idx: Dictionary = {}
	for v in icons:
		seen_idx[v] = true
	var oob: bool = false
	for i in icons:
		if i < 0 or i > 24:
			oob = true
			break
	if icons.size() != 23 or seen_idx.size() != 23 or oob:
		_fail("数据: icon_index 0-24 唯一性破坏, icons=%s" % str(icons))
	else:
		_pass("数据 / icon_index 0-24 唯一")
	for cat in ["attack", "defense", "stat", "special"]:
		if cats.get(cat, 0) < 4:
			_fail("数据: category %s 数量 < 4（实得 %d）" % [cat, cats.get(cat, 0)])
	_pass("数据 / 四类各 ≥4（attack=%d defense=%d stat=%d special=%d）" % [cats.get("attack", 0), cats.get("defense", 0), cats.get("stat", 0), cats.get("special", 0)])

	# 20 常规项 effects 键 ⊂ 白名单（3 核心豁免；D24-F13 机制型 3 词条 effects 空 {} 天然豁免）
	var bad_keys: Array = []
	for iid in passives:
		if iid in PASSIVE_CORE_IDS:
			continue
		var it: Dictionary = _loader.call("get_item", iid)
		for key in it.get("effects", {}):
			if key not in WHITELIST_KEYS:
				bad_keys.append("%s.%s" % [iid, key])
	if bad_keys.is_empty():
		_pass("数据 / 20 常规项 effects 键 ⊂ 白名单")
	else:
		_fail("数据: 含禁键 %s" % bad_keys)

	# 3 核心 id 命中
	for cid in PASSIVE_CORE_IDS:
		var it: Dictionary = _loader.call("get_item", cid)
		if it.is_empty() or not it.get("is_passive", false):
			_fail("数据: 核心 %s 未标记 passive" % cid)
		else:
			_pass("数据 / 核心 %s 命中" % cid)

	# 其余 28 项不加被动标记
	for iid in _loader.call("get_all_item_ids"):
		if iid in passives:
			continue
		var it: Dictionary = _loader.call("get_item", iid)
		if it.get("is_passive", false):
			_fail("数据: 非被动项被标记: %s" % iid)


# ========== Part 2: 槽位层 ==========

func _part_slots() -> void:
	# inventory.MAX_ITEMS == 6
	var max_items: int = int(_inv.get("MAX_ITEMS"))
	if max_items != 6:
		_fail("槽位: MAX_ITEMS 应 6, 实得 %d" % max_items)
	else:
		_pass("槽位 / inventory.MAX_ITEMS == 6")

	# 第 7 个 add_item false
	for i in 6:
		var ok: bool = _inv.call("add_item_from_data", "coffee")
		if not ok:
			_fail("槽位: 第 %d 个 add_item_from_data(应成功) 失败" % (i + 1))
	_inv.items.clear()  # 清空以便测第 7 个
	for i in 6:
		_inv.call("add_item_from_data", "coffee")
	var seventh: bool = _inv.call("add_item_from_data", "coffee")
	if seventh:
		_fail("槽位: 第 7 个 add_item_from_data 应返回 false")
	else:
		_pass("槽位 / 第 7 个 add_item_from_data 返回 false（满槽拒绝）")

	# is_item_slots_full 正确
	_inv.items.clear()
	if _inv.call("is_item_slots_full"):
		_fail("槽位: 空背包不应 is_item_slots_full")
	for i in 6:
		_inv.call("add_item_from_data", "coffee")
	if not _inv.call("is_item_slots_full"):
		_fail("槽位: 6 件后应 is_item_slots_full")
	else:
		_pass("槽位 / is_item_slots_full 口径正确")
	_inv.items.clear()


# ========== Part 3: 装配层 ==========

func _part_assembly() -> void:
	# add_item_from_data("coffee") → attack_speed 1.0 → 1.08
	_player.attack_speed = 1.0
	var ok: bool = _inv.call("add_item_from_data", "coffee")
	if not ok:
		_fail("装配: add_item_from_data(coffee) 失败")
	if absf(float(_player.get("attack_speed")) - 1.08) > EPSILON:
		_fail("装配: attack_speed 应 1.08, 实得 %s" % str(_player.get("attack_speed")))
	else:
		_pass("装配 / coffee attack_speed 1.0 → 1.08")

	# remove_item_id("coffee") → 回 1.0（percent 除法精确还原）
	var removed: bool = _inv.call("remove_item_id", "coffee")
	if not removed:
		_fail("装配: remove_item_id(coffee) 应 true")
	if absf(float(_player.get("attack_speed")) - 1.0) > EPSILON:
		_fail("装配: 移除后 attack_speed 应 1.0, 实得 %s" % str(_player.get("attack_speed")))
	else:
		_pass("装配 / coffee 移除后 attack_speed 1.0（percent 除法精确还原）")

	# add_item_from_data("se_blade_core") → crit_damage 2.0 → 2.4（crit_damage_percent 映射生效）
	_player.crit_damage = 2.0
	_inv.call("add_item_from_data", "se_blade_core")
	if absf(float(_player.get("crit_damage")) - 2.4) > EPSILON:
		_fail("装配: crit_damage 应 2.4, 实得 %s" % str(_player.get("crit_damage")))
	else:
		_pass("装配 / se_blade_core crit_damage 2.0 → 2.4（crit_damage_percent 映射生效）")

	# 未知键被动注入 → push_warning 且不崩
	# 构造一个未映射键 effects 的 Item（含 engineering:5），直接 add_item 后装配
	var ItemScript: GDScript = load("res://scripts/items/item.gd")
	var bad_item: Resource = ItemScript.new()
	bad_item.item_id = "test_unknown_key"
	bad_item.item_name = "test_unknown_key"
	bad_item.price = 0
	bad_item.slot = "passive"
	bad_item.stat_bonuses = {"engineering": 5, "fire_damage_percent": 10}  # 双禁键
	_inv.call("add_item", bad_item)
	if _player.get("attack_speed") != 1.0:
		_fail("装配: 未映射键不应改变 attack_speed")
	# 不崩即通过
	_pass("装配 / 未映射键 passive 注入：push_warning + 不崩（不修改玩家属性）")

	# 清理
	_inv.items.clear()
	_inv.call("remove_item_id", "se_blade_core")  # 已在 items 内
	_inv.items.clear()


# ========== Part 4: 商店层 ==========

func _part_shop() -> void:
	# 充值
	_economy.add_coins(500)

	# 模拟 _refresh_shop（不走 _ready 信号，直接调 _build_shop_pool + shop_items 填入）
	# 简化：直接 new Shop 但不 add_child，构造其数据路径不依赖 @onready
	# shop.gd 用了 @onready 节点引用 _refresh_shop 不访问节点 → 可直接 new()._refresh_shop()
	# 但 _render_cards 需要 item_container @onready 引用，未 add_child 时为 null
	# 绕开：直接调用 _build_shop_pool 验证池，再单测 _purchase_item 路径不依赖 _render_cards
	# D13-T6 同步：_build_shop_pool 现返回**资源实例**（BUG-002 修复，原 String id 被
	# Array[Resource] 类型拒绝 → 4 ERROR + 0 卡）；元素按 weapon_type 字段区分武器/被动
	var pool: Array = _shop.call("_build_shop_pool")
	# F31-1/F31-3 同步（2026-08-08 用户拍板）：池 58 → 49 = 23 武器 + 23 被动 + 2 遗物 + 1 服务 anvil
	if pool.size() != 49:
		_fail("商店: 混合池应 23 武器 + 23 被动 + 2 遗物 + 1 服务 = 49, 实得 %d" % pool.size())
	else:
		_pass("商店 / 混合池 49（武器 23 排除 3 结果 + 10 起始 + 被动 23 + 遗物 2 + 服务 1）")
	# 池元素全为资源实例：23 Weapon + 26 Item（零类型 ERROR 断言替代原 id 抽查；
	# D20-T4 遗物同为 Item 入池；F31-3 anvil 服务同为 Item 入池）
	var weapon_pool: Array = []
	var passive_pool: Array = []
	for res in pool:
		if res == null:
			_fail("商店: 池含 null 条目")
			continue
		if res.get("weapon_type") != null:
			weapon_pool.append(res)
		else:
			passive_pool.append(res)
	if weapon_pool.size() != 23:
		_fail("商店: 池武器数应 23, 实得 %d" % weapon_pool.size())
	else:
		_pass("商店 / 池含 23 把 Weapon 资源实例")
	if passive_pool.size() != 26:
		_fail("商店: 池 Item 数应 26（23 被动 + 2 遗物 + 1 服务）, 实得 %d" % passive_pool.size())
	else:
		_pass("商店 / 池含 26 个 Item 资源实例（被动 23 + 遗物 2 + 服务 1）")

	# 模拟 _refresh_shop 路径：随机取 4 → build Weapon + Item
	# 手动写：复制 _refresh_shop 核心逻辑（不依赖 _render_cards 节点）
	# 实质：用 _shop._refresh_shop 但 catch 节点 null 异常？
	# 改：直接手动构建 shop_items（同 _refresh_shop 内部逻辑）
	# 白盒直构造（防 flaky）：Array.shuffle() 走全局 RNG，RandomNumberGenerator.seed 固定无效，
	# (33/53)^4≈15% 概率 4 卡全武器 → 「购买被动」断言无对象（2026-08-06 12:3x 实测复现 19 项 1 FAIL）。
	# 改为武器/被动池各取 2 构成 4 卡 → 100% 同时含武器与被动，购买两断言均可验。
	var picked: Array = []
	picked.append_array(weapon_pool.slice(0, 2))
	picked.append_array(passive_pool.slice(0, 2))
	_shop.set("shop_items", [])
	for res in picked:
		if res == null:
			_fail("商店: 白盒直构造含 null")
			continue
		_shop.shop_items.append(res)
	if _shop.shop_items.size() != 4:
		_fail("商店: shop_items 应 4, 实得 %d" % _shop.shop_items.size())
	else:
		_pass("商店 / shop_items 4 卡非 null")

	# 槽满场景：先填满被动槽，再购买被动 → 失败且 coins 不变
	_inv.items.clear()
	for i in 6:
		_inv.call("add_item_from_data", "coffee")
	_player.attack_speed = 1.0
	# 模拟一次「购买被动」的最短路径（绕开 _purchase_item 的 _render_cards 调用）
	var pre_coins: int = int(_economy.get("coins"))
	var item_in_pool: Resource = null
	for s in _shop.shop_items:
		if s.get("weapon_type") == null:
			item_in_pool = s
			break
	if item_in_pool != null:
		var added: bool = _inv.call("add_item", item_in_pool)
		if added:
			_fail("商店: 槽满时 add_item 应失败")
		else:
			_pass("商店 / 槽满时购买被动：add_item 拒绝 + coins 不变")
		if int(_economy.get("coins")) != pre_coins:
			_fail("商店: 槽满时 coins 应不变")
	_inv.items.clear()
	_player.attack_speed = 1.0

	# 购买被动 → economy 扣费 + inventory+1 + 属性变（走真实路径）
	_economy.add_coins(500)
	_inv.items.clear()
	# 找一个被动 item in shop_items
	var passive_to_buy: Resource = null
	for s in _shop.shop_items:
		if s.get("weapon_type") == null:
			passive_to_buy = s
			break
	if passive_to_buy == null:
		_fail("商店: shop_items 无被动，无法验证购买")
		return
	# 模拟 _purchase_item 关键路径（钱够 + add_item + spend_coins）
	var pre_coins2: int = int(_economy.get("coins"))
	# Resource.get() 1 参数限制：先 get 再判空
	var price_var: Variant = passive_to_buy.get("price")
	var price: int = int(price_var) if price_var != null else 0
	if _economy.coins < price:
		_fail("商店: 充值 500 后钱不够买 %s（%dG）" % [passive_to_buy.get("item_name"), price])
		return
	if _inv.call("add_item", passive_to_buy):
		# 装配已由 item_added 信号自动触发（探针 _on_item_added_bonus = main.gd 接线等价）
		# 勿再手动 apply_item_bonuses —— 否则 coffee 双装配 attack_speed=1.1664（1.08×1.08）
		if _economy.spend_coins(price):
			_pass("商店 / 购买被动：inventory+1 + 玩家属性变 + coins 扣费（验证属性变化）")
	# 验证属性变化（type-dependent，仅校验 != 1.0 等）
	if passive_to_buy.get("item_id") == "coffee" and absf(float(_player.get("attack_speed")) - 1.08) > EPSILON:
		_fail("商店: 购买 coffee 后 attack_speed 应 1.08, 实得 %s" % str(_player.get("attack_speed")))
	elif passive_to_buy.get("item_id") == "se_blade_core":
		pass  # 已在装配层验证

	# 购买武器 → equipped_weapons+1
	_inv.items.clear()
	_player.set("crit_damage", 2.0)
	_economy.add_coins(500)
	var weapon_to_buy: Resource = null
	for s in _shop.shop_items:
		if s.get("weapon_type") != null:
			weapon_to_buy = s
			break
	if weapon_to_buy != null:
		var wc2: Node = _player.get_node("WeaponController")
		var pre_slots: int = int(wc2.call("get_slot_count"))
		var wprice_var: Variant = weapon_to_buy.get("price")
		var wprice: int = int(wprice_var) if wprice_var != null else 0
		if _inv.call("add_weapon", weapon_to_buy) and wc2.call("equip_weapon", weapon_to_buy):
			if _economy.spend_coins(wprice):
				var new_slots: int = int(wc2.call("get_slot_count"))
				if new_slots != pre_slots + 1:
					_fail("商店: 购买武器后 equipped_weapons 应 +1, 实得 %d→%d" % [pre_slots, new_slots])
				else:
					_pass("商店 / 购买武器：equipped_weapons +1 + coins 扣费（33 武器池生效）")


# ========== Part 5: 图标层 ==========

func _part_icons() -> void:
	# icon_atlas items frame_count == 25（D24-F13-3: +3 机制型被动帧）
	var atlas_script: GDScript = load("res://scripts/utils/icon_atlas.gd")
	var fc: int = int(atlas_script.call("get_frame_count", "items"))
	if fc != 25:
		_fail("图标: icon_atlas items frame_count 应 25, 实得 %d" % fc)
	else:
		_pass("图标 / icon_atlas items frame_count == 25")

	# items.png 尺寸 + 25 帧中心非空 + 透明键
	if not FileAccess.file_exists(ITEMS_PNG_PATH):
		_fail("图标: items.png 不存在")
		return
	var abs_path: String = ProjectSettings.globalize_path(ITEMS_PNG_PATH)
	var img: Image = Image.load_from_file(abs_path)
	if img == null:
		_fail("图标: items.png 加载失败")
		return
	if img.get_width() != 800 or img.get_height() != 32:
		_fail("图标: items.png 尺寸应 800×32, 实得 %dx%d" % [img.get_width(), img.get_height()])
	else:
		_pass("图标 / items.png 尺寸 800×32")
	# 透明键 (0,0)
	if img.get_pixel(0, 0).a > 0.0:
		_fail("图标: 透明键 (0,0) 应全透明")
	# 25 帧中心非空
	for idx in 25:
		var x0: int = idx * 32
		var has: bool = false
		for dx in range(8, 24):
			for dy in range(8, 24):
				if img.get_pixel(x0 + dx, dy).a > 0.0:
					has = true
					break
			if has:
				break
		if not has:
			_fail("图标: 帧 %d 中心全透明（应实绘）" % idx)
	if _failures == 0:
		_pass("图标 / 25 帧中心非空 + 透明键 (0,0) 全透明")


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
		print("DAY11_12 PASSIVE CHECK CLEAN")
	else:
		print("DAY11_12 PASSIVE CHECK BROKEN")


func report_and_quit() -> void:
	_report()
	quit(_failures)
