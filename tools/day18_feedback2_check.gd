## Day 18-反馈批 2 出口校验（2026-08-07 真人整合局客观反馈三项）：
##   ① 商店买不起 → 根因 = 金币产出量级崩溃（data_loader 读 drop 键，杂兵 1G / Boss 1G，
##      核心 120G 永远攒不起）→ 修复：enemies.json 全 23 敌补 coin_value（2-200 数据化），
##      data_loader 消费键统一 coin_value（兜底旧键 drop）
##   ② Boss 无血条 → 修复：HUD.tscn 顶部 BossBar（名称 + HP 条）+ hud.gd 轮询扫描
##      is_boss 存活目标（兼容两制：路线 invoker wave10 / 旧制 predator wave20）
##   ③ 星刃离人物太远（orbit_radius 110-138）→ 修复：se_star_blade 40→68 紧贴人物环绕，
##      se_blade_storm 120→68（进化 6 刃风暴贴体）
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
var _checked: int = 0
var _failures: int = 0

func _initialize() -> void:
	print("=== Day 18 feedback2 check (金币产出/Boss血条/星刃轨道) ===")

func _process(_delta: float) -> bool:
	if not _ready_mocks:
		_load_mocks()
		return false
	if _sub > 24:
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

# ---------- §2 星刃轨道半径（紧贴人物环绕） ----------

func _part2_star_blade_data() -> void:
	var wd: Dictionary = _loader.call("get_weapon", "se_star_blade")
	_ok(int(wd.get("orbit_radius", 0)) == 40, "se_star_blade 顶层 orbit_radius == 40（实际 %s）" % str(wd.get("orbit_radius")))
	var levels: Array = wd.get("levels", [])
	_ok(levels.size() >= 8, "se_star_blade levels >= 8（实际 %d）" % levels.size())
	var expect: Dictionary = {1: 40, 2: 44, 3: 48, 4: 52, 5: 56, 6: 60, 7: 64, 8: 68}
	var bad: Array = []
	for lv in levels:
		var l: int = int(lv.get("level", 0))
		var r: int = int(lv.get("orbit_radius", -1))
		if r != expect.get(l, -1):
			bad.append("Lv%d=%d" % [l, r])
	_ok(bad.is_empty(), "se_star_blade levels 半径 40→68 紧贴递增（异常: %s）" % str(bad))
	var storm: Dictionary = _loader.call("get_weapon", "se_blade_storm")
	_ok(int(storm.get("orbit_radius", 0)) == 68, "se_blade_storm orbit_radius == 68（实际 %s）" % str(storm.get("orbit_radius")))

func _part2_star_blade_weapon_resource() -> void:
	# 武器资源 orbit_data 落地（WeaponController 纯函数构建）
	var wc: Node = load("res://scripts/weapons/weapon_controller.gd").new()
	var w: Resource = wc.call("build_weapon_from_data", "se_star_blade")
	var od: Dictionary = w.get("orbit_data") if w else {}
	_ok(w != null and not od.is_empty(), "se_star_blade 武器资源 orbit_data 非空")
	_ok(float(od.get("orbit_radius", 0.0)) == 40.0, "orbit_data.orbit_radius == 40（实际 %s）" % str(od.get("orbit_radius")))
	_ok(int(od.get("blade_count", 0)) >= 1, "orbit_data.blade_count >= 1（实际 %s）" % str(od.get("blade_count")))

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
	var card: Control = container.get_child(0)
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
