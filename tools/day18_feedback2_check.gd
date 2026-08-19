## Day 18-反馈批 2 出口校验（2026-08-07 真人整合局客观反馈三项）：
##   ① 商店买不起 → 根因 = 金币产出量级崩溃（data_loader 读 drop 键，杂兵 1G / Boss 1G，
##      核心 120G 永远攒不起）→ 修复：enemies.json 全 23 敌补 coin_value（2-200 数据化），
##      data_loader 消费键统一 coin_value（兜底旧键 drop）
##   ② Boss 无血条 → 修复：HUD.tscn 顶部 BossBar（名称 + HP 条）+ hud.gd 轮询扫描
##      is_boss 存活目标（兼容两制：路线 invoker wave10 / 旧制 predator wave20）
##   ③ 星刃离人物太远（orbit_radius 110-138）→ 修复：se_star_blade 40→68 紧贴人物环绕，
##      se_blade_storm 120→68（进化 6 刃风暴贴体）
##      → PS 2026-08-17 重构：orbit 环绕 → 扇形挥砍（arc_angle 100→135 递增 / 进化 150）
##   §6（2026-08-08 反馈专员 F-21）群星回应：第四关结算 + 升级两次技能 + 本商店无星刃核心
##      → 激活免费高亮刷新，点击刷新必出星刃核心（本局一次）
##
## 用法（无头）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day18_feedback2_check.gd
##
## 退出码 0 = 全部通过；非 0 = 失败项数。
extends SceneTree

const HUD_SCENE_PATH: String = "res://scenes/HUD.tscn"
const ENEMY_SCENE_PATH: String = "res://scenes/Enemy.tscn"
const SHOP_SCENE_PATH: String = "res://scenes/Shop.tscn"

var _sub: int = 0
var _ready_mocks: bool = false
var _loader: Node = null
var _gm: Node = null
var _world: Node2D = null
var _enemy_container: Node = null
var _hud: Node = null
var _boss_stub: Node = null
var _shop: Node = null
var _inv: Node = null
var _player_mock: Node = null
var _checked: int = 0
var _failures: int = 0

func _initialize() -> void:
	print("=== Day 18 feedback2 check (金币产出/Boss血条/星刃轨道/群星回应) ===")

func _process(_delta: float) -> bool:
	if not _ready_mocks:
		_load_mocks()
		return false
	if _sub > 30:
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
	_world = Node2D.new()
	_world.name = "MockWorld"
	root.add_child(_world)
	_enemy_container = Node.new()
	_enemy_container.name = "MockEnemies"
	_world.add_child(_enemy_container)
	# mock spawner（HUD _scan_boss_target 走 GameManager.enemies_container 优先；spawner 兜底同型）
	var spawner_mock = load("res://scripts/enemy/enemy_spawner.gd").new()
	spawner_mock.name = "MockSpawner"
	spawner_mock.set("enemies_container", _enemy_container)
	_gm.set("enemy_spawner", spawner_mock)
	_gm.set("enemies_container", _enemy_container)
	# mock economy（Main 场景挂载项，探针环境自建，仿 day11_12 范式）
	var econ: Node = load("res://scripts/systems/economy.gd").new()
	econ.name = "MockEconomy"
	_gm.set("economy", econ)
	# mock inventory（§5 商店购买入库需要；成员变量 _inv 持有防悬垂）
	_inv = load("res://scripts/systems/inventory.gd").new()
	_inv.name = "MockInventory"
	_gm.set("inventory", _inv)
	# mock player（§6 群星回应读 player.level；player.gd 脚本实例，不 add_child 不触发 _ready）
	_player_mock = load("res://scripts/player/player.gd").new()
	_player_mock.name = "MockPlayer"
	_gm.set("player", _player_mock)
	# HUD 实例（独立场景，_ready 的延迟连接与 SkillController 告警为主动预期）
	_hud = load(HUD_SCENE_PATH).instantiate()
	root.add_child(_hud)
	# Shop 实例（§5 真实点击购买：_ready 已接 shop_opened 信号）
	_shop = load(SHOP_SCENE_PATH).instantiate()
	root.add_child(_shop)

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

func _report() -> void:
	print("=== DAY18-FEEDBACK2 CHECK: %d assertions, %d failures ===" % [_checked, _failures])
	if _failures == 0:
		print("DAY18-FEEDBACK2 CHECK CLEAN")

# ========== 分节执行 ==========

func _advance(sub: int) -> int:
	match sub:
		0:
			_part1_coin_data()
		1:
			_part1_consume_key()
		2:
			_part2_star_blade_data()
		3:
			_part2_star_blade_weapon_resource()
		4:
			_part3_boss_bar_stub()
		5:
			_part3_boss_bar_visible()
		6:
			_part3_boss_bar_death_hidden()
		7:
			_part4_economy_buy()
		8:
			_part4_economy_insufficient()
		9:
			_part5_shop_open()
		10:
			_part5_click_purchase()
		11:
			_part6_star_grace_conditions()
		12:
			_part6_star_grace_reroll_guarantee()
	return sub + 1

# ---------- §1 金币数据（23 敌 coin_value 全定义 + 消费键统一） ----------

func _part1_coin_data() -> void:
	# 23 个敌人 coin_value 全部 > 0（杂兵 2-8 / 精英 20-25 / Boss 150-200）
	var ids: Array = _loader.call("get_all_enemy_ids")
	_ok(ids.size() >= 23, "敌人总数 >= 23（实际 %d）" % ids.size())
	var zero: Array = []
	var spot: Dictionary = {}
	for eid in ids:
		var ed: Dictionary = _loader.call("get_enemy", str(eid))
		var cv: int = int(ed.get("coin_value", 0))
		if cv <= 0:
			zero.append(eid)
		spot[str(eid)] = cv
	_ok(zero.is_empty(), "全部敌人 coin_value > 0（缺失/零值: %s）" % str(zero))
	_ok(spot.get("chaser", 0) == 2 and spot.get("slasher", 0) == 6, "杂兵分档: chaser 2 / slasher 6")
	_ok(spot.get("butcher", 0) == 20 and spot.get("colossus", 0) == 25, "精英分档: butcher 20 / colossus 25")
	_ok(spot.get("invoker", 0) == 150 and spot.get("predator", 0) == 200, "Boss 分档: invoker 150 / predator 200")

func _part1_consume_key() -> void:
	# data_loader 消费键统一：get_scaled_enemy 返回 coin_value 走新键（chaser→2 / butcher→20 / invoker→150）
	var c: Dictionary = _loader.call("get_scaled_enemy", "chaser", 1)
	_ok(int(c.get("coin_value", 0)) == 2, "get_scaled_enemy(chaser) coin_value == 2（实际 %s）" % str(c.get("coin_value")))
	var b: Dictionary = _loader.call("get_scaled_enemy", "butcher", 6)
	_ok(int(b.get("coin_value", 0)) == 20, "get_scaled_enemy(butcher) coin_value == 20（实际 %s）" % str(b.get("coin_value")))
	var iv: Dictionary = _loader.call("get_scaled_enemy", "invoker", 10)
	_ok(int(iv.get("coin_value", 0)) == 150, "get_scaled_enemy(invoker) coin_value == 150（实际 %s）" % str(iv.get("coin_value")))

# ---------- §2 星刃扇形挥砍（PS 2026-08-17 重构：orbit 环绕 → 扇形挥砍，扇形角递增） ----------

func _part2_star_blade_data() -> void:
	var wd: Dictionary = _loader.call("get_weapon", "se_star_blade")
	_ok(int(wd.get("arc_angle", 0)) == 100, "se_star_blade 顶层 arc_angle == 100（实际 %s）" % str(wd.get("arc_angle")))
	var levels: Array = wd.get("levels", [])
	_ok(levels.size() >= 8, "se_star_blade levels >= 8（实际 %d）" % levels.size())
	var expect: Dictionary = {1: 100, 2: 105, 3: 110, 4: 115, 5: 120, 6: 125, 7: 130, 8: 135}
	var bad: Array = []
	for lv in levels:
		var l: int = int(lv.get("level", 0))
		var a: int = int(lv.get("arc_angle", -1))
		if a != expect.get(l, -1):
			bad.append("Lv%d=%d" % [l, a])
	_ok(bad.is_empty(), "se_star_blade levels 扇形角 100→135 递增（异常: %s）" % str(bad))
	var storm: Dictionary = _loader.call("get_weapon", "se_blade_storm")
	_ok(int(storm.get("arc_angle", 0)) == 150, "se_blade_storm arc_angle == 150（实际 %s）" % str(storm.get("arc_angle")))

func _part2_star_blade_weapon_resource() -> void:
	# 武器资源 arc_angle 落地（WeaponController 纯函数构建）
	var wc: Node = load("res://scripts/weapons/weapon_controller.gd").new()
	var w: Resource = wc.call("build_weapon_from_data", "se_star_blade")
	var arc: float = float(w.get("arc_angle")) if w else 0.0
	_ok(w != null and arc > 0.0, "se_star_blade 武器资源 arc_angle 已落地（实得 %s）" % str(arc))
	_ok(arc == 100.0, "arc_angle == 100（实际 %s）" % str(arc))
	_ok(arc >= 90.0, "arc_angle >= 90（扇形挥砍判定阈值，实际 %s）" % str(arc))

# ---------- §3 HUD Boss 血条 ----------

func _part3_boss_bar_stub() -> void:
	# stub Boss（Enemy.tscn 实例 + initialize，invoker 召唤者）
	_boss_stub = load(ENEMY_SCENE_PATH).instantiate()
	_boss_stub.initialize({
		"id": "invoker", "category": "boss", "name": "召唤者",
		"max_health": 8000.0, "damage": 1.0, "move_speed": 100.0,
		"coin_value": 150, "exp_value": 400, "behavior": "chase",
		"phases": [],
	})
	_boss_stub.health = 8000.0
	_boss_stub.max_health = 8000.0
	_enemy_container.add_child(_boss_stub)
	_ok(_boss_stub.get("is_boss") == true, "stub Boss is_boss == true")
	_ok(_boss_stub.get("enemy_id") == "invoker", "stub Boss enemy_id == invoker")

func _part3_boss_bar_visible() -> void:
	_hud.call("_scan_boss_target")
	_hud.call("_update_boss_bar")
	var bar: Node = _hud.get("boss_bar")
	var name_label: Label = _hud.get("boss_name_label")
	var hp_bar: TextureProgressBar = _hud.get("boss_health_bar")
	_ok(bar != null and bar.get("visible") == true, "Boss 在场 → BossBar visible")
	_ok(name_label.text == "召唤者", "Boss 名称显示「召唤者」（实际 %s）" % name_label.text)
	_ok(hp_bar.max_value == 8000.0 and hp_bar.value == 8000.0, "Boss 血条满值 8000/8000")
	# 打掉一半 → 血条同步
	_boss_stub.health = 4000.0
	_hud.call("_update_boss_bar")
	_ok(hp_bar.value == 4000.0, "Boss 半血 → 血条 4000（实际 %s）" % str(hp_bar.value))

func _part3_boss_bar_death_hidden() -> void:
	# Boss 死亡 → 血条隐藏
	_boss_stub.is_alive = false
	_hud.call("_scan_boss_target")
	_hud.call("_update_boss_bar")
	var bar: Node = _hud.get("boss_bar")
	_ok(bar.get("visible") == false, "Boss 死亡 → BossBar 隐藏")
	_boss_stub.queue_free()
	_boss_stub = null

# ---------- §4 经济闭环（金币可积累 → 可购买核心） ----------

func _part4_economy_buy() -> void:
	var eco: Node = _gm.get("economy")
	_ok(eco != null, "economy 存在")
	eco.reset()
	eco.add_coins(200)
	_ok(int(eco.get("coins")) == 200, "击杀累计金币 200（实际 %d）" % int(eco.get("coins")))
	# 星刃核心 120G 可买
	_ok(eco.call("spend_coins", 120), "spend_coins(120) 购买核心成功")
	_ok(int(eco.get("coins")) == 80, "购后余额 80（实际 %d）" % int(eco.get("coins")))

func _part4_economy_insufficient() -> void:
	var eco: Node = _gm.get("economy")
	eco.reset()
	eco.add_coins(10)
	_ok(not eco.call("spend_coins", 120), "余额不足 → 拒绝购买（不扣费）")
	_ok(int(eco.get("coins")) == 10, "拒绝后余额不变 10（实际 %d）" % int(eco.get("coins")))

# ---------- §5 商店真实点击购买（08-07 修复：NinePatchRect 默认 mouse_filter=IGNORE
#              → 点击穿透全屏 BG「点卡片无反应」；显式 STOP 后真实点击可购买） ----------

func _part5_shop_open() -> void:
	_gm.get("economy").reset()
	_gm.get("economy").add_coins(500)
	_gm.emit_signal("shop_opened")
	var cards: int = _shop.get("shop_items").size()
	var container: Node = _shop.get("item_container")
	_ok(cards >= 1 and container.get_child_count() == cards, "商店打开渲染卡片 %d 张" % cards)
	if container.get_child_count() >= 1:
		var card: Control = container.get_child(0)
		_ok(card.mouse_filter == Control.MOUSE_FILTER_STOP, "卡片 mouse_filter == STOP（实际 %d，修复 08-07 点击穿透）" % card.mouse_filter)

func _part5_click_purchase() -> void:
	var container: Node = _shop.get("item_container")
	if container.get_child_count() < 1:
		_fail("无卡片可点")
		return
	# 2026-08-19（RELIC-0 轮）：随机池洗牌后首卡可能是 anvil 服务（无武器可升级时购买被拒
	# = 历史 flaky 源）→ 遍历选一张非 anvil 卡点击，保证稳定可买（零游戏逻辑改动）
	var card: Control = null
	var shop_items: Array = _shop.get("shop_items")
	for i in container.get_child_count():
		var c: Control = container.get_child(i)
		if i < shop_items.size():
			var it: Resource = shop_items[i]
			var sb: Variant = it.get("stat_bonuses")
			if sb is Dictionary and bool((sb as Dictionary).get("shop_weapon_upgrade", false)):
				continue
		card = c
		break
	if card == null:
		card = container.get_child(0)
	var center: Vector2 = card.get_global_rect().get_center()
	# push_input 同步派发 → 先记录点击前状态
	var coins_before: int = int(_gm.get("economy").get("coins"))
	var inv_before: int = _inv.get("weapons").size() + _inv.get("items").size()
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = center
	root.push_input(ev)
	var ev2 := InputEventMouseButton.new()
	ev2.button_index = MOUSE_BUTTON_LEFT
	ev2.pressed = false
	ev2.position = center
	root.push_input(ev2)
	var coins_after: int = int(_gm.get("economy").get("coins"))
	var inv_after: int = _inv.get("weapons").size() + _inv.get("items").size()
	_ok(coins_after < coins_before, "真实点击购买 → 金币扣减（%d → %d）" % [coins_before, coins_after])
	_ok(inv_after > inv_before, "真实点击购买 → 背包入库（%d → %d）" % [inv_before, inv_after])

# ---------- §6 群星回应（F-21 2026-08-08 用户拍板：第四关星刃核心保底） ----------

## 条件矩阵：第四关(current_wave==4) + 升级两次(player.level>=3) + 本商店无星刃核心 + 未用过
## → 激活 star_grace_available；任一条件不满足 → 不激活
func _part6_star_grace_conditions() -> void:
	var econ: Node = _gm.get("economy")
	var shop: Node = _shop
	# 环境复位：economy 清空 + player.level=3 + current_wave=4
	# 白盒直调 _check_star_grace（不经 shop_opened 信号 → 避免 _on_shop_opened 二次随机刷新引入 flaky）
	shop.set("star_grace_available", false)
	shop.set("star_grace_used", false)
	_player_mock.set("level", 3)
	_gm.set("current_wave", 4)
	econ.reset()
	econ.add_coins(500)
	# 循环刷新直到商店无星刃核心（force 不参与，纯随机多刷几次至无核心；上限 50 防死循环）
	var guard: int = 0
	while shop.call("_has_blade_core") and guard < 50:
		shop.call("_refresh_shop")
		guard += 1
	shop.call("_check_star_grace")
	_ok(shop.get("star_grace_available"), "条件全满足（wave4+level3+商店无核心+未用过）→ 群星回应激活")
	_ok(shop.get("star_grace_used") == false, "激活时未消费（star_grace_used == false）")
	# 已消费后 → 不再激活（关闭重开商店）
	shop.set("star_grace_used", true)
	shop.set("star_grace_available", false)
	shop.call("_check_star_grace")
	_ok(shop.get("star_grace_available") == false, "已用过 → 不再激活（一次性）")
	shop.set("star_grace_used", false)
	# level < 3 → 不激活
	shop.set("star_grace_available", false)
	_player_mock.set("level", 2)
	shop.call("_check_star_grace")
	_ok(shop.get("star_grace_available") == false, "level==2（未升级两次）→ 不激活")
	# current_wave != 4 → 不激活
	shop.set("star_grace_available", false)
	_player_mock.set("level", 3)
	_gm.set("current_wave", 3)
	shop.call("_check_star_grace")
	_ok(shop.get("star_grace_available") == false, "current_wave==3（非第四关）→ 不激活")

## 免费刷新 + 必出星刃核心：激活后 _on_reroll_pressed → 不扣费 + 商店含 se_blade_core
func _part6_star_grace_reroll_guarantee() -> void:
	var econ: Node = _gm.get("economy")
	var shop: Node = _shop
	# 复位到激活态：wave4 + level3 + 未用过，商店当前无核心（白盒直调防二次刷新）
	shop.set("star_grace_available", false)
	shop.set("star_grace_used", false)
	_player_mock.set("level", 3)
	_gm.set("current_wave", 4)
	econ.reset()
	econ.add_coins(500)
	var guard: int = 0
	while shop.call("_has_blade_core") and guard < 50:
		shop.call("_refresh_shop")
		guard += 1
	shop.call("_check_star_grace")
	_ok(shop.get("star_grace_available"), "前置：群星回应已激活")
	# 记录点击前金币 → 触发免费刷新
	var coins_before: int = int(econ.get("coins"))
	shop.call("_on_reroll_pressed")
	var coins_after: int = int(econ.get("coins"))
	_ok(coins_after == coins_before, "群星回应刷新免费（金币 %d → %d，不扣 10G）" % [coins_before, coins_after])
	_ok(shop.call("_has_blade_core"), "群星回应刷新后商店必含星刃核心 se_blade_core")
	_ok(shop.get("star_grace_available") == false, "刷新后 star_grace_available 复位 false")
	_ok(shop.get("star_grace_used") == true, "刷新后 star_grace_used == true（本局一次）")
