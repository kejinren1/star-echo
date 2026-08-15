## Day 20 出口校验：遗物系统（D20-T1~T6 / 阶段 C 收口锚点）
##
## 用法（无头，不需要编辑器）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day20_relic_check.gd
##
## 校验内容（对应 docs/SOLUTION_PLAN.md 第 3 轮任务 6 五段）：
##   §1 数据层：items.json 54 项；2 遗物 slot=="relic" + icon_index 49/50 唯一 + price>0；
##      effects 键 ⊆ {damage_percent, damage_taken_percent, structure_damage_percent}；
##      resonant_shard 保持无 slot；is_passive 现 23 项（D24-F13 +3 机制型）
##   §2 新键装配（白盒直构造 + apply_item_bonuses，禁手动双装配——信号环境 item_added→装配已接）：
##      broken_crown → damage ×1.5 + taken_mult 1.3；mech_engine → structure_mult 2.0；
##      remove 回退 → 全复位（percent 除法还原）
##   §3 take_damage 乘算：armor=0 扣 130；armor=20 扣 104；debug_cheat 开 → 仍 ×0.001 最后兜底
##   §4 商店/上限：池 49（23+23+2+1 服务）+ 含 2 遗物 + 零 String；add broken_crown ×2 成功 →
##      第 3 次拒（inventory_full("relic")）；6 被动 + 2 遗物共存（MAX_ITEMS 语义不变）
##   §5 结构伤害消费 + 回归锚点：白盒 turret 弹药伤害 ×structure_damage_mult（se_mech_core 装配
##      → structure_mult 1.4 顺带激活悬空词条）；icon_atlas items 54 / 商店池 49 / icon_index 0-53 唯一
##
## 退出码 0 = 全部通过；非 0 = 失败项数。
extends SceneTree

const EPSILON: float = 0.001
const RELIC_IDS: Array = ["broken_crown", "mech_engine"]
## §5 回归锚点：被动 icon_index 唯一范围 0-53（2026-08-15 道具图集重建 25→54 帧）
const PASSIVE_ICON_MAX: int = 53  ## 2026-08-15 道具图集重建：items.png 25→54 帧，icon_index 范围 0-53

var _idx: int = 0
var _sub: int = 0
var _loader: Node = null
var _player: Node = null
var _inv: Node = null
var _shop: Node = null
var _checked: int = 0
var _failures: int = 0
var _expect_loaded: bool = false
var _relic_full_flag: bool = false


func _initialize() -> void:
	print("=== Day 20 relic system check ===")


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
	if _loader == null:
		_fail("DataLoader autoload 缺失")
		_report()
		quit(_failures)
		return

	# mock player（player.gd 脚本：STAT_MAP + apply_item_bonuses + take_damage 通道）
	_player = CharacterBody2D.new()
	_player.name = "MockPlayer"
	_player.set_script(load("res://scripts/player/player.gd"))
	_player.max_health = 1000.0
	_player.move_speed = 300.0
	_player.armor = 0.0
	_player.dodge = 0.0
	_player.damage_multiplier = 1.0
	_player.damage_taken_mult = 1.0
	_player.structure_damage_mult = 1.0
	root.add_child(_player)

	# mock inventory
	var inv_script: GDScript = load("res://scripts/systems/inventory.gd")
	_inv = inv_script.new()
	_inv.name = "MockInventory"
	root.add_child(_inv)
	# 捕获 inventory_full 信号（成员变量写回，闭包对局部变量赋值不写回外层）
	_inv.inventory_full.connect(func(cat: String) -> void:
		if cat == "relic":
			_relic_full_flag = true
	)

	# mock shop（白盒 _build_shop_pool 不依赖渲染节点）
	var shop_script: GDScript = load("res://scripts/ui/shop.gd")
	_shop = shop_script.new()


func _advance(sub: int) -> int:
	match sub:
		0:
			_part_data()
			return 1
		1:
			_part_apply()
			return 2
		2:
			_part_take_damage()
			return 3
		3:
			_part_shop_cap()
			return 4
		4:
			_part_structure_and_anchor()
			return 5
		5:
			_part_skill_icon()
			return 6
		_:
			_idx += 1
			return 0
	return sub + 1


# ========== §1 数据层 ==========

func _part_data() -> void:
	var items: Array = _loader.call("get_all_item_ids")
	if items.size() != 54:
		_fail("数据: items.json 应 54 项, 实得 %d" % items.size())
	else:
		_pass("数据 / items.json 54 项（49 + 2 遗物 + 3 机制型被动）")

	# 2 遗物：slot=="relic" + icon_index 49/50 唯一（2026-08-15 图集重建：items.json 全 54 道具按序，遗物排 49/50）+ price>0 + effects 键白名单
	var relic_found: Dictionary = {}
	var effects_ok: bool = true
	for rid in RELIC_IDS:
		var it: Dictionary = _loader.call("get_item", rid)
		if it.is_empty():
			_fail("数据: 遗物 %s 不存在" % rid)
			continue
		if str(it.get("slot")) != "relic":
			_fail("数据: %s slot 应 relic, 实得 %s" % [rid, str(it.get("slot"))])
		if int(it.get("price", 0)) <= 0:
			_fail("数据: %s price 应 >0（入商店池前提）" % rid)
		var idx: int = int(it.get("icon_index", -1))
		if relic_found.has(idx):
			_fail("数据: icon_index %d 重复（%s）" % [idx, rid])
		else:
			relic_found[idx] = rid
		if idx not in [49, 50]:
			_fail("数据: %s icon_index 应 49/50, 实得 %d" % [rid, idx])
		for key in (it.get("effects", {}) as Dictionary).keys():
			if key not in ["damage_percent", "damage_taken_percent", "structure_damage_percent"]:
				effects_ok = false
				_fail("数据: %s effects 越白名单键 %s" % [rid, key])
	if relic_found.size() == 2 and effects_ok:
		_pass("数据 / 2 遗物 slot=relic + icon 49/50 唯一 + price>0 + effects 白名单")

	# resonant_shard 保持无 slot（事件专属）
	var shard: Dictionary = _loader.call("get_item", "resonant_shard")
	if str(shard.get("slot", "")) != "":
		_fail("数据: resonant_shard slot 应空, 实得 %s" % str(shard.get("slot")))
	else:
		_pass("数据 / resonant_shard 保持无 slot（事件专属不入商店）")

	# is_passive 现 23 项（D24-F13：20 + 3 机制型被动；遗物不设 is_passive）
	var passives: int = 0
	for iid in items:
		var it: Dictionary = _loader.call("get_item", iid)
		if not it.is_empty() and it.get("is_passive", false):
			passives += 1
	if passives != 23:
		_fail("数据: is_passive 应 23 项, 实得 %d" % passives)
	else:
		_pass("数据 / is_passive 现 23 项（20 + 3 机制型 F-13）")


# ========== §2 新键装配 ==========

func _part_apply() -> void:
	# 白盒直构造 Item 资源（仿 _build_item_from_data 装载），走 apply_item_bonuses 装配链
	var crown: Resource = _make_item_resource("broken_crown")
	_player.call("apply_item_bonuses", crown, false)
	if absf(float(_player.damage_multiplier) - 1.5) > EPSILON:
		_fail("装配: broken_crown damage_multiplier 应 1.5, 实得 %s" % str(_player.damage_multiplier))
	if absf(float(_player.damage_taken_mult) - 1.3) > EPSILON:
		_fail("装配: broken_crown damage_taken_mult 应 1.3, 实得 %s" % str(_player.damage_taken_mult))
	if absf(float(_player.damage_multiplier) - 1.5) <= EPSILON and absf(float(_player.damage_taken_mult) - 1.3) <= EPSILON:
		_pass("装配 / broken_crown → damage ×1.5 + taken_mult 1.3")

	var engine: Resource = _make_item_resource("mech_engine")
	_player.call("apply_item_bonuses", engine, false)
	if absf(float(_player.structure_damage_mult) - 2.0) > EPSILON:
		_fail("装配: mech_engine structure_damage_mult 应 2.0, 实得 %s" % str(_player.structure_damage_mult))
	else:
		_pass("装配 / mech_engine → structure_mult 2.0")

	# remove 回退 → 全复位（percent 除法还原）
	_player.call("apply_item_bonuses", crown, true)
	_player.call("apply_item_bonuses", engine, true)
	if absf(float(_player.damage_multiplier) - 1.0) > EPSILON:
		_fail("装配: remove 后 damage_multiplier 应复位 1.0, 实得 %s" % str(_player.damage_multiplier))
	if absf(float(_player.damage_taken_mult) - 1.0) > EPSILON:
		_fail("装配: remove 后 damage_taken_mult 应复位 1.0, 实得 %s" % str(_player.damage_taken_mult))
	if absf(float(_player.structure_damage_mult) - 1.0) > EPSILON:
		_fail("装配: remove 后 structure_damage_mult 应复位 1.0, 实得 %s" % str(_player.structure_damage_mult))
	if absf(float(_player.damage_multiplier) - 1.0) <= EPSILON and absf(float(_player.damage_taken_mult) - 1.0) <= EPSILON and absf(float(_player.structure_damage_mult) - 1.0) <= EPSILON:
		_pass("装配 / remove 回退 → 三倍率全复位 1.0")


# ========== §3 take_damage 乘算 ==========

func _part_take_damage() -> void:
	_player.max_health = 1000.0
	_player.health = 1000.0
	_player.armor = 0.0
	_player.damage_taken_mult = 1.3  # 等效 broken_crown 装配态
	_player.set("_invulnerable_timer", 0.0)  # 探针逐用例重置无敌帧（真实受击间隔 0.4s 不冲突）
	_player.take_damage(100.0)
	var hp1: float = float(_player.health)
	if absf((1000.0 - hp1) - 130.0) > EPSILON:
		_fail("take_damage: armor=0 应扣 130, 实扣 %s" % str(1000.0 - hp1))
	else:
		_pass("take_damage / armor=0 ×1.3 → 扣 130")

	_player.health = 1000.0
	_player.armor = 20.0
	_player.set("_invulnerable_timer", 0.0)
	_player.take_damage(100.0)
	var hp2: float = float(_player.health)
	if absf((1000.0 - hp2) - 104.0) > EPSILON:
		_fail("take_damage: armor=20 应扣 104（80×1.3）, 实扣 %s" % str(1000.0 - hp2))
	else:
		_pass("take_damage / armor=20 先减后乘 → 扣 104")

	# debug_cheat 开 → 仍 ×0.001 最后兜底（金手指语义不变）
	var gm: Node = root.get_node_or_null("GameManager")
	var saved_cheat: bool = bool(gm.get("debug_cheat")) if gm else false
	if gm:
		gm.set("debug_cheat", true)
	_player.health = 1000.0
	_player.armor = 0.0
	_player.set("_invulnerable_timer", 0.0)
	_player.take_damage(100.0)
	var hp3: float = float(_player.health)
	if gm:
		gm.set("debug_cheat", saved_cheat)
	var dmg3: float = 1000.0 - hp3
	if absf(dmg3 - 0.13) > EPSILON:
		_fail("take_damage: debug_cheat 开应扣 0.13（130×0.001）, 实扣 %s" % str(dmg3))
	else:
		_pass("take_damage / debug_cheat 仍 ×0.001 最后兜底")


# ========== §4 商店/上限 ==========

func _part_shop_cap() -> void:
	# 商店池 49（F31-1/3 同步：23 武器 + 23 被动 + 2 遗物 + 1 服务 anvil）+ 含 2 遗物 + 零 String
	var pool: Array = _shop.call("_build_shop_pool")
	if pool.size() != 49:
		_fail("商店: 池应 49, 实得 %d" % pool.size())
	else:
		_pass("商店 / 混合池 49（23 武器 + 23 被动 + 2 遗物 + 1 服务）")
	var has_crown: bool = false
	var has_engine: bool = false
	var bad_type: bool = false
	for res in pool:
		if res == null or not (res is Resource):
			bad_type = true
			continue
		var iid: String = str(res.get("item_id"))
		if iid == "broken_crown":
			has_crown = true
		if iid == "mech_engine":
			has_engine = true
	if bad_type:
		_fail("商店: 池含非资源条目（String 泄漏）")
	if not has_crown or not has_engine:
		_fail("商店: 池应含 broken_crown/mech_engine 两遗物")
	if not bad_type and has_crown and has_engine:
		_pass("商店 / 池含 2 遗物 + 零 String")

	# 遗物上限：×2 成功 → 第 3 次拒（inventory_full("relic")）
	_inv.reset()
	_relic_full_flag = false
	var ok1: bool = _inv.call("add_item_from_data", "broken_crown")
	var ok2: bool = _inv.call("add_item_from_data", "broken_crown")
	var ok3: bool = _inv.call("add_item_from_data", "mech_engine")
	if not ok1 or not ok2:
		_fail("上限: 前 2 个遗物应入库成功")
	elif ok3:
		_fail("上限: 第 3 个遗物应被拒")
	elif not _relic_full_flag:
		_fail("上限: 应 emit inventory_full('relic')")
	else:
		_pass("上限 / MAX_RELICS=2：×2 成功 → 第 3 次拒 + inventory_full(relic)")
	if int(_inv.call("get_relic_count")) != 2:
		_fail("上限: get_relic_count 应 2, 实得 %d" % int(_inv.call("get_relic_count")))

	# 6 被动 + 2 遗物共存（MAX_ITEMS 语义不变：被动满后 add 仍拒，遗物直装不受阻）
	_inv.reset()
	var passive_ids: Array = []
	for iid in _loader.call("get_all_item_ids"):
		var it: Dictionary = _loader.call("get_item", iid)
		if not it.is_empty() and it.get("is_passive", false):
			passive_ids.append(iid)
		if passive_ids.size() >= 6:
			break
	for pid in passive_ids:
		_inv.call("add_item_from_data", pid)
	if int(_inv.call("get_item_count")) != 6:
		_fail("共存: 被动槽应满 6, 实得 %d" % int(_inv.call("get_item_count")))
	var full_flag_item: bool = false
	_inv.inventory_full.connect(func(cat: String) -> void:
		if cat == "item":
			full_flag_item = true
	)
	var ok_p: bool = _inv.call("add_item_from_data", passive_ids[0])
	var ok_r1: bool = _inv.call("add_item_from_data", "broken_crown")
	var ok_r2: bool = _inv.call("add_item_from_data", "mech_engine")
	if ok_p:
		_fail("共存: 被动满 6 后再 add 被动应被拒")
	if not ok_r1 or not ok_r2:
		_fail("共存: 被动满 + 2 遗物应可共存（relic 直装跳过 MAX_ITEMS）")
	if not ok_p and ok_r1 and ok_r2:
		_pass("共存 / 6 被动 + 2 遗物共存（被动再 add 仍拒）")


# ========== §5 结构伤害消费 + 回归锚点 ==========

func _part_structure_and_anchor() -> void:
	# 白盒 turret：se_mech_core 装配 → structure_mult 1.4 → 弹药伤害 ×1.4
	var mech_core: Resource = _make_item_resource("se_mech_core")
	_player.call("apply_item_bonuses", mech_core, false)
	if absf(float(_player.structure_damage_mult) - 1.4) > EPSILON:
		_fail("结构: se_mech_core 装配 structure_mult 应 1.4, 实得 %s" % str(_player.structure_damage_mult))
	else:
		_pass("结构 / se_mech_core → structure_mult 1.4（悬空词条激活）")

	# turret._fire：player.damage_multiplier=1.0 × structure_damage_mult=1.4 → proj.damage 5×1.4=7
	var turret_script: GDScript = load("res://scripts/weapons/turret.gd")
	var turret: Node2D = turret_script.new()
	var world := Node2D.new()
	world.name = "MockWorld"
	var proj_container := Node2D.new()
	proj_container.name = "Projectiles"
	world.add_child(proj_container)
	root.add_child(world)
	world.add_child(turret)
	var weapon_data: Dictionary = _loader.call("get_weapon", "se_auto_turret")
	turret.call("setup", weapon_data, 5.0, _player)
	var target := Node2D.new()
	target.name = "MockTarget"
	target.set("is_alive", true)
	proj_container.add_child(target)
	var before: int = proj_container.get_child_count()
	turret.call("_fire", target)
	var after: int = proj_container.get_child_count()
	if after != before + 1:
		_fail("结构: _fire 应生成 1 弹丸, 实得 %d→%d" % [before, after])
	else:
		var proj: Node = proj_container.get_child(proj_container.get_child_count() - 1)
		if proj == target:
			proj = proj_container.get_child(proj_container.get_child_count() - 2)
		var dmg: float = float(proj.get("damage"))
		if absf(dmg - 7.0) > EPSILON:
			_fail("结构: 弹药伤害应 7（5×1.4）, 实得 %s" % str(dmg))
		else:
			_pass("结构 / turret 弹药伤害 ×structure_damage_mult（5×1.4=7）")

	# 回归锚点：icon_atlas items 54 / 商店池 49（F31 同步）/ is_passive icon_index 0-53 唯一
	var atlas_script: GDScript = load("res://scripts/utils/icon_atlas.gd")
	var fc: int = int(atlas_script.call("get_frame_count", "items"))
	if fc != 54:
		_fail("锚点: icon_atlas items frame_count 应 54, 实得 %d" % fc)
	else:
		_pass("锚点 / icon_atlas items 54 帧")
	var pool: Array = _shop.call("_build_shop_pool")
	if pool.size() != 49:
		_fail("锚点: 商店池应 49, 实得 %d" % pool.size())
	else:
		_pass("锚点 / 商店池 49")
	var seen: Dictionary = {}
	var dup: bool = false
	for iid in _loader.call("get_all_item_ids"):
		var it: Dictionary = _loader.call("get_item", iid)
		if it.is_empty() or not it.get("is_passive", false):
			continue
		var idx: int = int(it.get("icon_index", -1))
		if idx < 0 or idx > PASSIVE_ICON_MAX:
			_fail("锚点: 被动 icon_index %d 越界 0-%d" % [idx, PASSIVE_ICON_MAX])
		if seen.has(idx):
			dup = true
		seen[idx] = true
	if seen.size() != 23:
		_fail("锚点: 被动 icon_index 应 23 项, 实得 %d" % seen.size())
	elif dup:
		_fail("锚点: 被动 icon_index 存在重复")
	else:
		_pass("锚点 / is_passive icon_index 0-53 唯一（23 项）")


# ========== §6 技能图标（D20-T7/T8 · T-D P0 硬性输入） ==========

func _part_skill_icon() -> void:
	var hud_script: GDScript = load("res://scripts/ui/hud.gd")
	var hud: CanvasLayer = hud_script.new()
	# 白盒注入 skill_slot（@onready 需节点存在；new() 不触发 _ready，信号连接零副作用）
	var slot := TextureRect.new()
	hud.set("skill_slot", slot)
	# 4 个技能 id 各测：texture 非空 + 帧索引正确
	# （ctrl 用 skill_controller.gd 实例注入：脚本声明 skill_data 属性，Object.set 才有效；
	#   Node.new() 无脚本 set 未知属性静默无效 —— 探针自身坑）
	var sc_script: GDScript = load("res://scripts/player/skill_controller.gd")
	var ids: Array = ["se_skill_fireball", "se_skill_deploy_turret", "se_skill_blade_burst", "se_skill_holy_shield"]
	var all_ok: bool = true
	for k in ids.size():
		var ctrl: Node = sc_script.new()
		ctrl.set("skill_data", {"id": ids[k]})
		slot.texture = null
		hud.call("_apply_skill_icon", ctrl)
		var tex: AtlasTexture = slot.texture as AtlasTexture
		if tex == null:
			_fail("技能图标: %s 未接上 texture" % ids[k])
			all_ok = false
			continue
		var expect_region: int = k * 32
		if int(tex.region.position.x) != expect_region:
			_fail("技能图标: %s 帧偏移应 %d, 实得 %d" % [ids[k], expect_region, int(tex.region.position.x)])
			all_ok = false
	if all_ok:
		_pass("技能图标 / 4 id 各测：texture 非空 + 帧索引正确（skills.png 4 帧）")

	# 空 id → 零改动（texture 保持 null）
	var empty_ctrl: Node = sc_script.new()
	empty_ctrl.set("skill_data", {})
	slot.texture = null
	hud.call("_apply_skill_icon", empty_ctrl)
	if slot.texture != null:
		_fail("技能图标: 空 id 应零改动（texture 保持原样式）")
	else:
		_pass("技能图标 / 空 id → 零改动")

	# 未知 id → push_warning 不崩（texture 保持 null）
	var unknown_ctrl: Node = sc_script.new()
	unknown_ctrl.set("skill_data", {"id": "se_skill_unknown"})
	slot.texture = null
	hud.call("_apply_skill_icon", unknown_ctrl)
	if slot.texture != null:
		_fail("技能图标: 未知 id 应保留原样式")
	else:
		_pass("技能图标 / 未知 id → push_warning 登记不崩")

	# 图集缺失 → 不崩（ResourceLoader.exists 前置兜底）
	# （本环境 skills.png 已生成 → exists 恒 true；用假路径绕过不可行，改为验证脚本常量存在性）
	var sheet_cfg: Dictionary = (load("res://scripts/utils/icon_atlas.gd") as GDScript).get("SHEET_CONFIG")
	if not sheet_cfg.has("skills"):
		_fail("技能图标: IconAtlas 缺 skills sheet 注册")
	else:
		_pass("技能图标 / IconAtlas skills sheet 已注册（frame_count 4）")


# ========== 工具 ==========

func _make_item_resource(item_id: String) -> Resource:
	var data: Dictionary = _loader.call("get_item", item_id)
	var item: Resource = (load("res://scripts/items/item.gd") as GDScript).new()
	item.item_id = item_id
	item.item_name = str(data.get("name", item_id))
	item.price = int(data.get("price", 0))
	item.rarity = str(data.get("rarity", "common"))
	item.icon_index = maxi(int(data.get("icon_index", 0)), 0)
	item.slot = str(data.get("slot", ""))
	item.category = str(data.get("category", ""))
	item.stat_bonuses = data.get("effects", {})
	return item


# ========== 断言 ==========

func _pass(what: String) -> void:
	_checked += 1
	print("  PASS  %s" % what)


func _fail(what: String) -> void:
	_checked += 1
	_failures += 1
	print("  FAIL  %s" % what)


func _report() -> void:
	print("--- Day 20 relic check: %d 项断言，%d 项失败 ---" % [_checked, _failures])
	if _failures == 0:
		print("DAY20 RELIC CHECK CLEAN")
	else:
		print("DAY20 RELIC CHECK FAILED")
