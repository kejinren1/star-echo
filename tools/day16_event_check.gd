## Day 16 出口校验：事件节点系统（D16-T1~T5 / D16-EXIT 收口）
##
## 用法（无头，不需要编辑器）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day16_event_check.gd
##
## 校验内容（对应 docs/TASKS.md D16-T5 五段）：
##   1. 数据层：events.json 10 事件结构完整（id/title/description/choiceA.text/choiceB.text
##      全非空）；reward type ∈ 10 型枚举；effect_on_route type ∈ 5 型枚举
##   2. reward 结算 10 型（白盒直构造 → _apply_event_reward）：gold→coins+150；
##      max_hp→+20；luck→+15；attack_speed_percent→×1.08；attack_percent→damage×1.12；
##      heal_percent→回 40%；level_up→升 2 级；trade→max_health×0.85+damage×1.30 双键；
##      weapon_upgrade→随机武器 +1（seed 固定）；item→resonant_shard 装配 crit_damage×1.25
##   3. effect 改线 5 型：reroute(silent_corridor/shattered_path)→modifiers 生效+类型变化；
##      flag→route.flags 登记；unlock_node 三策略（rib_layer_shortcut 强制精英 /
##      boss_early 跳层 / archive flag）；add_node→层+2 追加 event；difficulty→flags 登记
##   4. 端到端（白盒直驱动）：进入 event 节点 → 暂停 + 面板出现 → resolve "A"(gold) →
##      coins+150 + paused=false + 面板释放 + 层推进；resolve "B"(reroute) → 改线生效
##   5. 回归锚点：商店池 53（resonant_shard 不入池）；被动池 20；_event_rng.seed 固定
##
## 退出码 0 = 全部通过；非 0 = 失败项数。
extends SceneTree

const ROUTE_GEN_PATH: String = "res://scripts/systems/route_generator.gd"
const EVENT_PANEL_SCENE_PATH: String = "res://scenes/EventSelectPanel.tscn"
const FIXED_SEED: int = 20260806

## reward 10 型枚举（D16-PRE 定案表）
const REWARD_TYPES: Array = [
	"attack_speed_percent", "max_hp", "gold", "item", "weapon_upgrade",
	"luck", "attack_percent", "heal_percent", "trade", "level_up",
]
## effect_on_route 5 型枚举
const EFFECT_TYPES: Array = ["reroute", "flag", "unlock_node", "add_node", "difficulty"]

## 端到端固定路线：L0=[battle w1, shop, event] · L1=[battle w2] · L2=[boss w10]
const FIXED_ROUTE: Dictionary = {
	"seed": 999,
	"layers": [
		[
			{"type": "battle", "wave_index": 1},
			{"type": "shop", "wave_index": 0},
			{"type": "event", "wave_index": 0},
		],
		[
			{"type": "battle", "wave_index": 2},
		],
		[
			{"type": "boss", "wave_index": 10},
		],
	],
	"modifiers": {},
	"flags": {},
}

## 端到端白盒事件（gold 奖励，确定可断言）
const FIXED_EVENT_GOLD: Dictionary = {
	"id": "probe_gold", "title": "探针·金", "theme": "测试",
	"description": "白盒直构造事件（gold 奖励）",
	"choiceA": {"text": "拿钱", "reward": {"type": "gold", "value": 150, "label": "星尘 +150"}},
	"choiceB": {"text": "改线", "effect_on_route": {"type": "flag", "value": "probe_flag", "label": "登记 flag"}},
}

## 端到端白盒事件（reroute 改线，确定可断言）
const FIXED_EVENT_REROUTE: Dictionary = {
	"id": "probe_reroute", "title": "探针·改线", "theme": "测试",
	"description": "白盒直构造事件（reroute 改线）",
	"choiceA": {"text": "拿钱", "reward": {"type": "gold", "value": 150, "label": "星尘 +150"}},
	"choiceB": {"text": "静默走廊", "effect_on_route": {"type": "reroute", "value": "silent_corridor", "label": "事件减战斗增"}},
}

var _sub: int = 0
var _ready_mocks: bool = false
var _loader: Node = null
var _gm: Node = null
var _gen: GDScript = null
var _player: Node = null
var _economy: Node = null
var _wc: Node = null
var _checked: int = 0
var _failures: int = 0

func _initialize() -> void:
	print("=== Day 16 event node check ===")

func _process(_delta: float) -> bool:
	if not _ready_mocks:
		_load_mocks()
		return false
	if _sub > 40:
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
	_gen = load(ROUTE_GEN_PATH)

	# 事件随机源固定种子（禁 flaky：Array.shuffle/pick_random 走全局 RNG 不可控，
	# _event_rng 为 RandomNumberGenerator 实例，seed 可控）
	_gm._event_rng.seed = 12345

	# mock player（player.gd 脚本：apply_stat_modifier/gain_exp/heal/apply_item_bonuses 齐备）
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
	print("=== DAY16 EVENT CHECK: %d assertions, %d failures ===" % [_checked, _failures])
	if _failures == 0:
		print("DAY16 EVENT CHECK CLEAN")

## 清空武器槽（typed array 须用 typed literal，D10 坑）
func _clear_weapons() -> void:
	if _wc:
		var empty: Array[Resource] = []
		_wc.set("equipped_weapons", empty)

## 重置玩家到出厂（health 同步 max_health）
func _reset_player() -> void:
	_player.max_health = 100.0
	_player.health = 100.0
	_player.attack_speed = 1.0
	_player.damage_multiplier = 1.0
	_player.crit_damage = 2.0
	_player.luck = 0.0
	_player.level = 1
	_player.exp = 0.0
	_economy.coins = 0

## 从 from_layer（含）起的战斗节点数
func _count_battles_from(route: Dictionary, from_layer: int) -> int:
	var c: int = 0
	var layers: Array = route.get("layers", [])
	for li in range(from_layer, layers.size()):
		for node in layers[li]:
			var t: String = str(node.get("type", ""))
			if t == "battle" or t == "elite":
				c += 1
	return c

## 全路线 wave_index 合法性（battle/elite ∈ [1,19]；boss==10；shop/event==0）
func _wave_indices_ok(route: Dictionary) -> bool:
	var layers: Array = route.get("layers", [])
	for li in layers.size():
		for node in layers[li]:
			var t: String = str(node.get("type", ""))
			var wi: int = int(node.get("wave_index", -1))
			if (t == "battle" or t == "elite") and (wi < 1 or wi > 19):
				return false
			if t == "boss" and wi != 10:
				return false
			if (t == "shop" or t == "event") and wi != 0:
				return false
	return true

# ========== 主推进（线性子步骤） ==========

func _advance(sub: int) -> int:
	match sub:
		# ---------- §1 数据层 ----------
		0:
			var events: Array = _loader.call("get_events")
			_ok(events.size() == 10, "数据: events.json 10 事件（实得 %d）" % events.size())
			var struct_ok: bool = true
			var reward_types_ok: bool = true
			var effect_types_ok: bool = true
			for ev in events:
				if str(ev.get("id", "")).is_empty() or str(ev.get("title", "")).is_empty() or str(ev.get("description", "")).is_empty():
					struct_ok = false
				var ca: Dictionary = ev.get("choiceA", {})
				var cb: Dictionary = ev.get("choiceB", {})
				if str(ca.get("text", "")).is_empty() or str(cb.get("text", "")).is_empty():
					struct_ok = false
				var rt: String = str(ca.get("reward", {}).get("type", ""))
				if not REWARD_TYPES.has(rt):
					reward_types_ok = false
				var et: String = str(cb.get("effect_on_route", {}).get("type", ""))
				if not EFFECT_TYPES.has(et):
					effect_types_ok = false
			_ok(struct_ok, "数据: 10 事件 id/title/description/choiceA.text/choiceB.text 全非空")
			_ok(reward_types_ok, "数据: reward type ∈ 10 型枚举")
			_ok(effect_types_ok, "数据: effect_on_route type ∈ 5 型枚举")
			return 1
		# ---------- §2 reward 结算（白盒直构造，逐型重置玩家） ----------
		1:
			_reset_player()
			_gm.call("_apply_event_reward", {"type": "gold", "value": 150})
			_ok(_economy.coins == 150, "reward/gold: coins +150（实得 %d）" % _economy.coins)
			_reset_player()
			_gm.call("_apply_event_reward", {"type": "max_hp", "value": 20})
			_ok(absf(_player.max_health - 120.0) < 0.01, "reward/max_hp: max_health +20（实得 %.1f）" % _player.max_health)
			_reset_player()
			_gm.call("_apply_event_reward", {"type": "luck", "value": 15})
			_ok(absf(_player.luck - 15.0) < 0.01, "reward/luck: +15（实得 %.1f）" % _player.luck)
			return 2
		2:
			_reset_player()
			_gm.call("_apply_event_reward", {"type": "attack_speed_percent", "value": 8})
			_ok(absf(_player.attack_speed - 1.08) < 0.001, "reward/attack_speed_percent: ×1.08（实得 %.3f）" % _player.attack_speed)
			_reset_player()
			_gm.call("_apply_event_reward", {"type": "attack_percent", "value": 12})
			_ok(absf(_player.damage_multiplier - 1.12) < 0.001, "reward/attack_percent: damage ×1.12（实得 %.3f）" % _player.damage_multiplier)
			_reset_player()
			_player.health = 50.0
			_gm.call("_apply_event_reward", {"type": "heal_percent", "value": 40})
			_ok(absf(_player.health - 90.0) < 0.01, "reward/heal_percent: 回 40%% → 90（实得 %.1f）" % _player.health)
			return 3
		3:
			_reset_player()
			_gm.call("_apply_event_reward", {"type": "level_up", "value": 2})
			_ok(int(_player.level) == 3, "reward/level_up: 升 2 级 → level 3（实得 %d）" % _player.level)
			_reset_player()
			_gm.call("_apply_event_reward", {"type": "trade", "value": {"max_hp_percent": -15, "damage_percent": 30}})
			_ok(absf(_player.max_health - 85.0) < 0.01 and absf(_player.damage_multiplier - 1.30) < 0.001,
				"reward/trade: max_health×0.85 + damage×1.30（实得 %.1f / %.3f）" % [_player.max_health, _player.damage_multiplier])
			return 4
		4:
			# weapon_upgrade：装备 1 把 sword → randi_range(0,0) 恒 0 → sword +1 级
			_reset_player()
			var ok_equip: bool = _wc.call("equip_from_data", "sword")
			_ok(ok_equip, "reward/weapon_upgrade 前置: 装备 sword 成功")
			_gm.call("_apply_event_reward", {"type": "weapon_upgrade", "value": 1})
			var weapons: Array = _wc.get("equipped_weapons")
			if weapons.size() > 0 and weapons[0] != null:
				_ok(int(weapons[0].level) == 2, "reward/weapon_upgrade: 随机武器 +1 级 → Lv2（实得 Lv%d）" % weapons[0].level)
			else:
				_fail("reward/weapon_upgrade: 无已装备武器")
			_clear_weapons()
			# item：resonant_shard 直装 → crit_damage ×1.25（2.0→2.5）
			_reset_player()
			_gm.call("_apply_event_reward", {"type": "item", "value": "resonant_shard"})
			_ok(absf(_player.crit_damage - 2.5) < 0.001, "reward/item: resonant_shard 装配 crit_damage ×1.25（实得 %.3f）" % _player.crit_damage)
			# 未知 item id → 兜底不崩（push_warning 登记）
			_gm.call("_apply_event_reward", {"type": "item", "value": "ghost_relic"})
			_ok(true, "reward/item: 未知 id 兜底不崩")
			return 5
		# ---------- §3 effect 改线 ----------
		5:
			# reroute 白盒（route_generator 直测）：
			# 1) 确定性构造：未访问层全 shop + 增量权重把 event/elite/shop 全清零
			#    （battle 0.5+0.4=0.9 为唯一正权重 → roll ∈ [0,0.9) 恒中 battle，零 RNG 偶然）
			var r3: Dictionary = {
				"seed": 42,
				"layers": [
					[{"type": "battle", "wave_index": 1}],
					[{"type": "shop", "wave_index": 0}, {"type": "shop", "wave_index": 0}, {"type": "shop", "wave_index": 0}],
					[{"type": "boss", "wave_index": 10}],
				],
				"modifiers": {},
				"flags": {},
			}
			var before2: int = _count_battles_from(r3, 1)
			_gen.reroute_remaining(r3, 1, {"battle": 0.4, "event": -0.2, "elite": -0.15, "shop": -0.15})
			var after2: int = _count_battles_from(r3, 1)
			_ok(before2 == 0 and after2 == 3, "改线/reroute: 全 shop 层按新权重重抽 → 全 battle（%d → %d）" % [before2, after2])
			_ok(_wave_indices_ok(r3), "改线/reroute: 重抽后 wave_index 合法（重映射）")
			# 2) 真实路线 reroute：modifiers.reroute 权重登记 + 全路线 wave_index 合法
			var big_route: Dictionary = _gen.generate_from(FIXED_SEED, _loader.get_routes())
			_gen.reroute_remaining(big_route, 2, {"battle": 0.4, "event": -0.15, "shop": -0.1})
			var modifiers: Dictionary = big_route.get("modifiers", {})
			_ok(not modifiers.get("reroute", {}).is_empty(), "改线/reroute: modifiers.reroute 权重已登记")
			_ok(_wave_indices_ok(big_route), "改线/reroute: 真实路线重抽后 wave_index 合法")
			# 3) 末层 boss 保护
			_gen.reroute_remaining(big_route, big_route.get("layers", []).size() - 1, {"battle": 0.4})
			_ok(true, "改线/reroute: 末层越界拒绝不崩")
			return 6
		6:
			# reroute via GM：shattered_path → 下一节点强制精英
			_gm.set("route", FIXED_ROUTE.duplicate(true))
			_gm.set("current_layer", 0)
			_gm.call("_apply_route_effect", {"type": "reroute", "value": "shattered_path"})
			var l1: Array = _gm.get("route").get("layers")[1]
			_ok(str(l1[0].get("type")) == "elite", "改线/reroute(shattered_path): 下一节点强制精英")
			# flag 登记
			_gm.set("route", FIXED_ROUTE.duplicate(true))
			_gm.call("_apply_route_effect", {"type": "flag", "value": "alliance_report_filed"})
			var flags: Dictionary = _gm.get("route").get("flags", {})
			_ok(flags.get("alliance_report_filed", false) == true, "改线/flag: route.flags 登记")
			return 7
		7:
			# unlock_node rib_layer_shortcut → 下一层首个战斗节点强制精英
			_gm.set("route", FIXED_ROUTE.duplicate(true))
			_gm.set("current_layer", 0)
			_gm.call("_apply_route_effect", {"type": "unlock_node", "value": "rib_layer_shortcut"})
			var l1b: Array = _gm.get("route").get("layers")[1]
			_ok(str(l1b[0].get("type")) == "elite", "改线/unlock_node(rib_layer_shortcut): 下一层首战斗强制精英")
			# unlock_node boss_corrupted_tree_early → 跳 Boss 前一层 + flag
			_gm.set("route", FIXED_ROUTE.duplicate(true))
			_gm.set("current_layer", 0)
			_gm.call("_apply_route_effect", {"type": "unlock_node", "value": "boss_corrupted_tree_early"})
			_ok(int(_gm.get("current_layer")) == 1, "改线/unlock_node(boss_early): current_layer 跳 Boss 前一层")
			var flags2: Dictionary = _gm.get("route").get("flags", {})
			_ok(flags2.get("boss_early", false) == true, "改线/unlock_node(boss_early): flags boss_early 登记")
			# unlock_node awakening_archive → flag
			_gm.set("route", FIXED_ROUTE.duplicate(true))
			_gm.call("_apply_route_effect", {"type": "unlock_node", "value": "awakening_archive"})
			var flags3: Dictionary = _gm.get("route").get("flags", {})
			_ok(flags3.get("archive_unlocked", false) == true, "改线/unlock_node(awakening_archive): flags archive_unlocked 登记")
			return 8
		8:
			# add_node → 当前层+2 追加 event（5 层路线，target = 0+2 = 层 2）
			var r5: Dictionary = _gen.generate_from(FIXED_SEED, _loader.get_routes())
			_gm.set("route", r5)
			_gm.set("current_layer", 0)
			_gm.call("_apply_route_effect", {"type": "add_node", "value": "rescue_signal"})
			var l2: Array = r5.get("layers")[2]
			_ok(l2.size() == 4 and str(l2[3].get("type")) == "event", "改线/add_node: 当前层+2 追加 event 节点（层2 → 4 节点）")
			# difficulty → flags 登记
			_gm.set("route", FIXED_ROUTE.duplicate(true))
			_gm.call("_apply_route_effect", {"type": "difficulty", "value": -1})
			var flags4: Dictionary = _gm.get("route").get("flags", {})
			_ok(int(flags4.get("difficulty_delta", 0)) == -1, "改线/difficulty: flags difficulty_delta == -1 登记")
			return 9
		# ---------- §4 端到端（白盒直驱动） ----------
		## 铁律：paused=true 会停探针自身 _process（SceneTree 回调同受 paused 影响）——
		## 「进入事件 → 按钮回调 → resolve（paused=false）」必须在同一 sub 内同步完成；
		## 面板释放（queue_free 帧尾）放下一帧（paused 已恢复）断言。
		9:
			_gm.call("reset")
			_gm.set("route", FIXED_ROUTE.duplicate(true))
			_gm.set("current_layer", 0)
			_gm.call("select_route_node", 2)   # → _start_event 同步执行（paused=true 期间无帧依赖）
			_ok(str(_gm.get("current_node").get("type")) == "event", "E2E: 选中 event 节点")
			_ok(paused == true, "E2E: 进入事件 → 游戏暂停")
			var panel: Node = _gm.get("_event_panel")
			_ok(panel != null and is_instance_valid(panel), "E2E: 事件面板已实例化")
			if panel != null and is_instance_valid(panel):
				var a_btn: Button = panel.get_node("CenterContainer/Panel/Margin/VBox/OptionA/ChoiceA")
				var b_btn: Button = panel.get_node("CenterContainer/Panel/Margin/VBox/OptionB/ChoiceB")
				_ok(a_btn != null and b_btn != null, "E2E: 面板选项按钮 A/B 存在")
				_ok(not str(panel.get("title_label").text).is_empty(), "E2E: 面板标题非空")
				# 覆盖当前事件为 gold 白盒事件 → 真实按钮回调（resolve + 面板自释放）→ 同步断言结算
				_gm.set("_current_event", FIXED_EVENT_GOLD)
				a_btn.pressed.emit()
				_ok(_economy.coins == 150, "E2E: resolve A(gold) → coins +150（实得 %d）" % _economy.coins)
				_ok(paused == false, "E2E: resolve 后取消暂停")
				_ok(int(_gm.get("current_layer")) == 1, "E2E: resolve 后推进到 L1")
			else:
				_fail("E2E: 事件面板丢失，无法按钮回调")
			return 10
		10:
			# 面板释放（上帧 resolve 已 queue_free → 帧尾 tree_exited → 本帧引用已清）
			_ok(_gm.get("_event_panel") == null, "E2E: 面板已释放（tree_exited 清引用）")
			# 端到端 B：resolve "B"(reroute) → 改线生效（不经过面板，同步）
			_gm.call("reset")
			_gm.set("route", FIXED_ROUTE.duplicate(true))
			_gm.set("current_layer", 0)
			_gm.set("_current_event", FIXED_EVENT_REROUTE)
			_gm.call("resolve_event_choice", "B")
			var mods: Dictionary = _gm.get("route").get("modifiers", {})
			_ok(not mods.get("reroute", {}).is_empty(), "E2E: resolve B(reroute) → modifiers.reroute 生效")
			_ok(paused == false, "E2E: resolve B 后取消暂停")
			_ok(int(_gm.get("current_layer")) == 1, "E2E: resolve B 后推进到 L1")
			return 11
		# ---------- §5 回归锚点 ----------
		12:
			# 商店池 58（33 武器 − 3 结果 + 23 被动 + 2 遗物）；resonant_shard 不入池
			var shop_script: GDScript = load("res://scripts/ui/shop.gd")
			var shop: Node = shop_script.new()
			shop.set("item_container", VBoxContainer.new())
			shop.set("coins_label", Label.new())
			var pool: Array = shop.call("_build_shop_pool")
			_ok(pool.size() == 58, "回归: 商店池 58（实得 %d）" % pool.size())
			var has_shard: bool = false
			for item in pool:
				if item and str(item.get("item_id")) == "resonant_shard":
					has_shard = true
			_ok(not has_shard, "回归: resonant_shard 不入商店池（不设 is_passive）")
			# 被动池 20
			var passives: int = 0
			for iid in _loader.call("get_all_item_ids"):
				var it: Dictionary = _loader.call("get_item", iid)
				if not it.is_empty() and it.get("is_passive", false):
					passives += 1
			_ok(passives == 20, "回归: 被动池 20（实得 %d）" % passives)
			# DataLoader.get_item("resonant_shard") 非空
			_ok(not _loader.call("get_item", "resonant_shard").is_empty(), "回归: DataLoader.get_item(resonant_shard) 非空")
			# _event_rng seed 固定（禁 flaky）
			_ok(_gm._event_rng.seed == 12345, "回归: _event_rng.seed 固定（禁 flaky）")
			return 13
		_:
			return 41  # 结束哨兵
