## Day 24-F13 出口校验：机制型被动词条（F-13 · P0 用户拍板 · D24-F13-1~4）
##
## 用法（无头，不需要编辑器）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day24_f13_check.gd
##
## 校验内容（对应 docs/SOLUTION_PLAN.md 第 6 轮任务 4 四段）：
##   §1 数据层：items.json 54 项 / 23 被动 / 3 trigger 字段 + type 校验（on_crit/on_kill/low_health）
##      / icon_index 51/52/53 唯一（2026-08-15 图集重建，原 22/23/24）/ effects 全空
##   §2 on_crit 白盒（overload_capacitor）：暴击命中 → 目标周围 80px 敌连锁伤害 ≈ crit×0.3（含自身）；
##      80px 外不掉；非暴击零触发；未持有遗物零触发零报错
##   §3 on_kill + low_health 白盒：击杀 → player.heal(1.0)；低血（≤30%）→ damage×1.5 + attack_speed×1.2
##      乘算开；回血（>30%）→ 逆运算恢复；未持有 → 零变化
##   §4 回归抽样：商店池 58→49（F31 同步）/ icon_atlas items 54 / items.png 1728×32（2026-08-15 图集重建）
##
## 退出码 0 = 全部通过；非 0 = 失败项数。
extends SceneTree

const EPSILON: float = 0.001
const TRIGGER_EXPECTED: Dictionary = {
	"overload_capacitor": "on_crit",
	"executioner_mark": "on_kill",
	"last_stand": "low_health",
}

## 白盒 mock 敌人（projectile._on_body_entered 需要 is_in_group("enemies") + take_damage；
## _trigger_on_crit_chain 需要 is_alive + take_damage）
class MockEnemy:
	extends Node2D
	var health: float = 100.0
	var is_alive: bool = true
	var hits: Array = []   # [[damage, is_crit], ...]

	func _init() -> void:
		add_to_group("enemies")

	func take_damage(dmg: float, is_crit: bool = false) -> void:
		hits.append([dmg, is_crit])
		health -= dmg
		if health <= 0.0:
			is_alive = false

## 白盒 mock inventory（has_item_id 权威接口）
class MockInventory:
	extends Node
	var owned: Dictionary = {}
	func has_item_id(item_id: String) -> bool:
		return owned.has(item_id)

## 白盒 mock wave_manager（_on_enemy_died 调 register_kill）
class MockWave:
	extends Node
	var kills: int = 0
	func register_kill() -> void:
		kills += 1

## 白盒 mock player（on_kill heal 记录）
class MockPlayerHeal:
	extends Node
	var healed: float = 0.0
	func heal(v: float) -> void:
		healed += v

var _idx: int = 0
var _sub: int = 0
var _loader: Node = null
var _gm: Node = null
var _expect_loaded: bool = false
var _checked: int = 0
var _failures: int = 0


func _initialize() -> void:
	print("=== Day 24-F13 mechanism passive check ===")


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
		quit(_failures)


func _advance(sub: int) -> int:
	match sub:
		0:
			_part_data()
			return 1
		1:
			_part_on_crit()
			return 2
		2:
			_part_on_kill_lowhealth()
			return 3
		3:
			_part_regression()
			return 4
		4:
			_report()
			quit(_failures)
	return 4


# ========== §1 数据层 ==========

func _part_data() -> void:
	# 54 项 / 23 被动
	var all_ids: Array = _loader.call("get_all_item_ids")
	if all_ids.size() != 54:
		_fail("数据: items.json 应 54 项, 实得 %d" % all_ids.size())
	else:
		_pass("数据 / items.json 54 项（51 + 3 机制型）")
	var passive_count: int = 0
	for iid in all_ids:
		var it: Dictionary = _loader.call("get_item", iid)
		if it.get("is_passive", false):
			passive_count += 1
	if passive_count != 23:
		_fail("数据: 被动应 23, 实得 %d" % passive_count)
	else:
		_pass("数据 / 23 被动（20 + 3 机制型）")
	# 3 trigger 词条：type 校验 + effects 空 + icon_index 唯一
	var trigger_ok: bool = true
	var seen_icon: Dictionary = {}
	for iid in TRIGGER_EXPECTED:
		var expected_type: String = TRIGGER_EXPECTED[iid]
		var it: Dictionary = _loader.call("get_item", iid)
		if it.is_empty():
			_fail("数据: trigger 词条 %s 不存在" % iid)
			trigger_ok = false
			continue
		if str(it.get("trigger", {}).get("type", "")) != expected_type:
			_fail("数据: %s trigger.type 应 %s, 实得 %s" % [iid, expected_type, str(it.get("trigger", {}).get("type", ""))])
			trigger_ok = false
		if not it.get("effects", {}).is_empty():
			_fail("数据: %s effects 应空 {}（不入 STAT 白名单）" % iid)
			trigger_ok = false
		var icon_idx: int = int(it.get("icon_index", -1))
		if icon_idx < 51 or icon_idx > 53 or seen_icon.has(icon_idx):
			_fail("数据: %s icon_index %d 应 51/52/53 唯一（2026-08-15 图集重建：items.json 全 54 道具按序，机制型排 51-53）" % [iid, icon_idx])
			trigger_ok = false
		seen_icon[icon_idx] = true
	if trigger_ok:
		_pass("数据 / 3 trigger 词条 type 合法 + effects 空 + icon_index 51/52/53 唯一")
	# 验证 trigger 各键存在
	var oc: Dictionary = _loader.call("get_item", "overload_capacitor")
	if float(oc.get("trigger", {}).get("radius", 0.0)) == 80.0 and float(oc.get("trigger", {}).get("ratio", 0.0)) == 0.3:
		_pass("数据 / overload_capacitor trigger_config（radius=80, ratio=0.3）")
	else:
		_fail("数据: overload_capacitor trigger_config 不符")
	var em: Dictionary = _loader.call("get_item", "executioner_mark")
	if float(em.get("trigger", {}).get("heal", 0.0)) == 1.0:
		_pass("数据 / executioner_mark trigger_config（heal=1）")
	else:
		_fail("数据: executioner_mark trigger_config 不符")
	var ls: Dictionary = _loader.call("get_item", "last_stand")
	var ls_t: Dictionary = ls.get("trigger", {})
	if float(ls_t.get("threshold", 0.0)) == 0.3 and float(ls_t.get("attack_mult", 0.0)) == 1.5 and float(ls_t.get("speed_mult", 0.0)) == 1.2:
		_pass("数据 / last_stand trigger_config（threshold=0.3, attack×1.5, speed×1.2）")
	else:
		_fail("数据: last_stand trigger_config 不符")


# ========== §2 on_crit 白盒（overload_capacitor） ==========

func _part_on_crit() -> void:
	# 注入 mock 环境
	var inv: MockInventory = MockInventory.new()
	inv.owned = {"overload_capacitor": true}
	_gm.set("inventory", inv)
	var container: Node2D = Node2D.new()
	_gm.set("enemies_container", container)
	_gm.set("vfx_container", Node2D.new())
	_gm.set("player", null)
	root.add_child(container)

	var target: MockEnemy = MockEnemy.new()
	target.position = Vector2(0, 0)
	var near_e: MockEnemy = MockEnemy.new()
	near_e.position = Vector2(50, 0)
	var far_e: MockEnemy = MockEnemy.new()
	far_e.position = Vector2(200, 0)
	container.add_child(target)
	container.add_child(near_e)
	container.add_child(far_e)

	var proj_script: GDScript = load("res://scripts/weapons/projectile.gd")
	# 暴击命中 → 连锁（crit_mult=2 → final=20；连锁 = 20×0.3=6）
	var proj: Node = proj_script.new()
	proj.set("crit_chance", 1.0)
	proj.set("crit_mult", 2.0)
	proj.set("damage", 10.0)
	proj.set("explosion_radius", 0.0)
	proj.call("_on_body_entered", target)
	if target.hits.size() == 2 and near_e.hits.size() == 1 and far_e.hits.is_empty():
		var chain_ok: bool = absf(float(target.hits[1][0]) - 6.0) <= EPSILON and absf(float(near_e.hits[0][0]) - 6.0) <= EPSILON
		var crit_flag_ok: bool = target.hits[1][1] == false
		if chain_ok and crit_flag_ok:
			_pass("on_crit / 暴击命中 → 80px 内连锁 ≈crit×0.3（target+50px 敌受 6, 200px 敌零伤, 连锁 is_crit=false）")
		else:
			_fail("on_crit: 连锁伤害或 is_crit 标志不符 target=%s near=%s" % [str(target.hits), str(near_e.hits)])
	else:
		_fail("on_crit: 命中记录不符 target=%s near=%s far=%s" % [str(target.hits), str(near_e.hits), str(far_e.hits)])

	# 非暴击 → 零连锁
	var target2: MockEnemy = MockEnemy.new()
	target2.position = Vector2(0, 0)
	container.add_child(target2)
	var proj2: Node = proj_script.new()
	proj2.set("crit_chance", 0.0)
	proj2.set("damage", 5.0)
	proj2.set("explosion_radius", 0.0)
	proj2.call("_on_body_entered", target2)
	if target2.hits.size() == 1 and not _any_chain(target2.hits):
		_pass("on_crit / 非暴击命中 → 零连锁（仅 1 次普伤）")
	else:
		_fail("on_crit: 非暴击不应触发连锁 target2=%s" % str(target2.hits))

	# 未持有遗物 → 零触发零报错
	inv.owned = {}
	var target3: MockEnemy = MockEnemy.new()
	target3.position = Vector2(0, 0)
	container.add_child(target3)
	var proj3: Node = proj_script.new()
	proj3.set("crit_chance", 1.0)
	proj3.set("crit_mult", 2.0)
	proj3.set("damage", 10.0)
	proj3.set("explosion_radius", 0.0)
	proj3.call("_on_body_entered", target3)
	if target3.hits.size() == 1:
		_pass("on_crit / 未持有 overload_capacitor → 零连锁零报错")
	else:
		_fail("on_crit: 未持有时不应连锁 target3=%s" % str(target3.hits))

	_gm.set("enemies_container", null)
	_gm.set("inventory", null)


func _any_chain(hits: Array) -> bool:
	# 连锁记录 = [damage, is_crit] 中 is_crit==false 的后续命中
	for i in range(1, hits.size()):
		if hits[i][1] == false:
			return true
	return false


# ========== §3 on_kill + low_health 白盒 ==========

func _part_on_kill_lowhealth() -> void:
	# ---- on_kill（executioner_mark）：main._on_enemy_died → heal 1.0 ----
	# 权威访问 = GameManager.inventory（D28 口径），探针须注入 _gm.inventory 而非 main 侧字段
	var main_script: GDScript = load("res://scripts/autoload/main.gd")
	var main: Node2D = main_script.new()
	var inv: MockInventory = MockInventory.new()
	inv.owned = {"executioner_mark": true}
	_gm.set("inventory", inv)
	var p_heal: MockPlayerHeal = MockPlayerHeal.new()
	main.set("player", p_heal)
	main.set("wave_manager", MockWave.new())
	main.set("vfx_container", null)
	var dead: MockEnemy = MockEnemy.new()
	dead.is_alive = false
	main.call("_on_enemy_died", dead)
	if absf(p_heal.healed - 1.0) <= EPSILON:
		_pass("on_kill / 击杀 → player.heal(1.0) 生效")
	else:
		_fail("on_kill: 击杀应 heal 1.0, 实得 %f" % p_heal.healed)
	inv.owned = {}
	main.call("_on_enemy_died", dead)
	if absf(p_heal.healed - 1.0) <= EPSILON:
		_pass("on_kill / 未持有 executioner_mark → 零回血")
	else:
		_fail("on_kill: 未持有时不应回血, 实得 %f" % p_heal.healed)

	# ---- low_health（last_stand）：player._update_last_stand 乘算开/关 ----
	var player_script: GDScript = load("res://scripts/player/player.gd")
	var player: Node = player_script.new()
	var inv2: MockInventory = MockInventory.new()
	inv2.owned = {"last_stand": true}
	_gm.set("inventory", inv2)
	player.set("health", 30.0)
	player.set("max_health", 100.0)
	player.call("_update_last_stand")
	var dmg_mult: float = float(player.get("damage_multiplier"))
	var aspd: float = float(player.get("attack_speed"))
	if absf(dmg_mult - 1.5) <= EPSILON and absf(aspd - 1.2) <= EPSILON:
		_pass("low_health / 血量≤30% → damage×1.5 + attack_speed×1.2（乘算开）")
	else:
		_fail("low_health: 低血应 ×1.5/×1.2, 实得 %f/%f" % [dmg_mult, aspd])
	# 回血解除
	player.set("health", 50.0)
	player.call("_update_last_stand")
	dmg_mult = float(player.get("damage_multiplier"))
	aspd = float(player.get("attack_speed"))
	if absf(dmg_mult - 1.0) <= EPSILON and absf(aspd - 1.0) <= EPSILON:
		_pass("low_health / 回血>30% → 逆运算恢复 ×1.0/×1.0（单开/关闭环）")
	else:
		_fail("low_health: 回血后应恢复 1.0/1.0, 实得 %f/%f" % [dmg_mult, aspd])
	# 未持有 → 零变化
	var player2: Node = player_script.new()
	_gm.set("inventory", MockInventory.new())
	player2.set("health", 30.0)
	player2.set("max_health", 100.0)
	player2.call("_update_last_stand")
	if absf(float(player2.get("damage_multiplier")) - 1.0) <= EPSILON and absf(float(player2.get("attack_speed")) - 1.0) <= EPSILON:
		_pass("low_health / 未持有 last_stand → 零触发零变化")
	else:
		_fail("low_health: 未持有时不应加乘算")
	_gm.set("inventory", null)


# ========== §4 回归抽样 ==========

func _part_regression() -> void:
	var shop_script: GDScript = load("res://scripts/ui/shop.gd")
	var shop: Node = shop_script.new()
	shop.set("item_container", VBoxContainer.new())
	shop.set("coins_label", Label.new())
	var pool: Array = shop.call("_build_shop_pool")
	# F31-1/F31-3 同步（2026-08-08 用户拍板）：池 58 → 49（23 武器 + 23 被动 + 2 遗物 + 1 服务 anvil）
	if pool.size() == 49:
		_pass("回归 / 商店混合池 49（23 武器 + 23 被动 + 2 遗物 + 1 服务）")
	else:
		_fail("回归: 商店池应 49, 实得 %d" % pool.size())
	var atlas_script: GDScript = load("res://scripts/utils/icon_atlas.gd")
	var fc: int = int(atlas_script.call("get_frame_count", "items"))
	if fc > 0:
		_pass("回归 / icon_atlas items frame_count 动态读取 = %d（F5-T1 防再漂移）" % fc)
	else:
		_fail("回归: icon_atlas items frame_count 非法 %d（应 > 0）" % fc)
	var abs_path: String = ProjectSettings.globalize_path("res://assets/sprites/ui/items.png")
	var img: Image = Image.load_from_file(abs_path)
	if img != null and img.get_width() == fc * 32 and img.get_height() == 32:
		_pass("回归 / items.png %dx32（%d 帧）" % [fc * 32, fc])
	else:
		_fail("回归: items.png 应 %dx32（%d 帧）, 实得 %s" % [fc * 32, fc, ("%dx%d" % [img.get_width(), img.get_height()]) if img != null else "null"])


# ========== 汇总 ==========

func _report() -> void:
	print("=== Day 24-F13 check: %d passed, %d failed ===" % [_checked, _failures])
	if _failures == 0:
		print("DAY24-F13 CHECK CLEAN")


func _pass(msg: String) -> void:
	_checked += 1
	print("  PASS  %s" % msg)


func _fail(msg: String) -> void:
	_failures += 1
	_checked += 1
	print("  FAIL  %s" % msg)
