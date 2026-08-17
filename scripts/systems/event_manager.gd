## 事件系统（阶段 F · F2-T6 从 GameManager 拆分 · 2026-08-12）
## 职责：事件节点流程（_start_event / resolve_event_choice）+ 奖励结算 10 型
## + 改线 5 型 + _event_rng 随机源。由 GameManager._ready 创建并注入 gm 引用；
## GameManager 保留同名薄委托（day16 探针白盒 `_gm.call("_apply_event_reward", ...)`
## / `_gm._event_rng.seed` 兼容——探针零改动，方案 T6 探针兼容约束）。
## 状态字段 _current_event / _event_panel 保留在 GameManager（探针 set/get + reset 清理）。
extends Node

# ========== 资源引用 ==========

const EventSelectPanelScene: PackedScene = preload("res://scenes/EventSelectPanel.tscn")
## 事件道具直装构造（item.gd 无 class_name，preload 仿 inventory.gd 范式）
const Item: GDScript = preload("res://scripts/items/item.gd")
## 路线生成器（无 class_name，preload 仿 shop.gd 范式）
const RouteGeneratorScript: GDScript = preload("res://scripts/systems/route_generator.gd")
## UI 面板工厂（_start_event 挂载事件面板到 UI 层）
const UIPanelFactoryScript: GDScript = preload("res://scripts/ui/ui_panel_factory.gd")

# ========== 依赖 ==========

var gm: Node = null   ## GameManager 引用（_ready 注入；事件段原访问 GM 字段经此转发）

# ========== 状态 ==========

## 事件随机性管控：RandomNumberGenerator 实例（种子可复现，探针经 GM._event_rng
## getter 注入 seed）；禁 Array.shuffle/pick_random（走全局 RNG，D11-12/D14-15 铁律）
var _event_rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	_event_rng.randomize()

# ========== 事件节点流程（Day 16 · D16-T2） ==========

## 事件节点进入：随机取 1 条事件（可重复符合肉鸽；零 route_generator 改动）→
## 暂停游戏 + 实例化面板渲染。事件数据缺失 → 告警并按已完成推进（不卡死）。
func _start_event() -> void:
	if gm == null:
		return
	if gm._event_panel != null:
		# 防悬挂：引用已失效（面板异常释放）→ 清理后继续；仅有效面板才拦截（防重复实例化）
		if is_instance_valid(gm._event_panel):
			return
		gm._event_panel = null
	AudioManager.play_sfx("event")   # D24-T3-⑨：事件节点 SFX
	var events: Array = DataLoader.get_events()
	if events.is_empty():
		push_warning("[EventManager] 事件数据为空，事件节点按已完成处理")
		gm._on_node_completed()
		return
	var idx: int = _event_rng.randi_range(0, events.size() - 1)
	gm._current_event = events[idx]
	gm.get_tree().paused = true
	var panel: Node = EventSelectPanelScene.instantiate()
	gm._event_panel = panel
	panel.tree_exited.connect(func() -> void:
		if gm._event_panel == panel:
			gm._event_panel = null
	)
	UIPanelFactoryScript.add_to_ui_layer(gm.get_tree(), panel)
	if panel.has_method("setup"):
		panel.setup(gm._current_event)

## 玩家选择事件选项：A → 奖励结算；B → 改线；随后恢复运行 + 节点完成推进。
## 面板释放由面板自身 queue_free（GameManager 不重复 free，防双释放）。
func resolve_event_choice(choice: String) -> void:
	if gm == null:
		return
	if gm._current_event.is_empty():
		push_warning("[EventManager] resolve_event_choice 无当前事件")
		return
	if choice == "A":
		_apply_event_reward(gm._current_event.get("choiceA", {}).get("reward", {}))
	else:
		_apply_route_effect(gm._current_event.get("choiceB", {}).get("effect_on_route", {}))
	gm._current_event = {}
	gm.get_tree().paused = false
	gm._on_node_completed()

## 事件奖励结算（D16-PRE 定案表 10 型；STAT_MAP 无 attack_percent/max_hp_percent →
## 代码层别名 attack_percent→damage / max_hp_percent→max_health，禁改 STAT_MAP 防波及 D4/D11-12 探针）
func _apply_event_reward(reward: Dictionary) -> void:
	if gm == null:
		return
	if reward.is_empty():
		push_warning("[EventManager] 事件奖励为空")
		return
	var player: Node = gm.player
	if player == null:
		push_warning("[EventManager] 玩家未绑定，事件奖励结算跳过")
		return
	var rtype: String = str(reward.get("type", ""))
	var value: Variant = reward.get("value", 0)
	match rtype:
		"attack_speed_percent":
			player.apply_stat_modifier("attack_speed", 1.0 + float(value) / 100.0, true)
		"attack_percent":
			# 别名：事件层 attack_percent → damage（STAT_MAP 无此键）
			player.apply_stat_modifier("damage", 1.0 + float(value) / 100.0, true)
		"max_hp":
			player.apply_stat_modifier("max_health", float(value))
		"max_hp_percent":
			# trade 复合键之一：乘算（负值乘算已验证：max_health 0.85）
			player.apply_stat_modifier("max_health", 1.0 + float(value) / 100.0, true)
		"damage_percent":
			# trade 复合键之一
			player.apply_stat_modifier("damage", 1.0 + float(value) / 100.0, true)
		"gold":
			if gm.economy:
				gm.economy.add_coins(int(value))
			else:
				push_warning("[EventManager] 经济系统未绑定，金币奖励失效")
		"luck":
			player.apply_stat_modifier("luck", float(value))
		"heal_percent":
			player.heal(player.max_health * float(value) / 100.0)
		"item":
			_apply_event_item(str(value))
		"weapon_upgrade":
			_apply_event_weapon_upgrade(int(value))
		"trade":
			# value 为复合 dict {max_hp_percent, damage_percent}
			var tvalue: Dictionary = reward.get("value", {})
			if tvalue.has("max_hp_percent"):
				player.apply_stat_modifier("max_health", 1.0 + float(tvalue["max_hp_percent"]) / 100.0, true)
			if tvalue.has("damage_percent"):
				player.apply_stat_modifier("damage", 1.0 + float(tvalue["damage_percent"]) / 100.0, true)
		"level_up":
			# 升 value 级：逐级 gain_exp(当前阈值)（曲线阈值随等级上涨——一次性给
			# 阈值×value 只够升 1 级，实测 Lv1 需 30+40=70 才升 2 级；D6 教训：数值先实测）
			var levels: int = maxi(int(value), 1)
			for _li in levels:
				player.gain_exp(player.get_xp_to_next_level())
		_:
			push_warning("[EventManager] 未知事件奖励类型: %s（已登记）" % rtype)

## 事件奖励 item：遗物语义直装生效（不进 inventory 6 被动槽；完整遗物槽归 Day 20）。
## id 未知 → push_warning 登记兜底不崩（resonant_shard 已由 D16-T4 补齐）。
func _apply_event_item(item_id: String) -> void:
	if gm == null:
		return
	if item_id.is_empty():
		return
	var data: Dictionary = DataLoader.get_item(item_id)
	if data.is_empty():
		push_warning("[EventManager] 事件奖励道具缺失: %s" % item_id)
		return
	var item: Resource = _build_event_item(item_id)
	if item != null and gm.player and gm.player.has_method("apply_item_bonuses"):
		gm.player.apply_item_bonuses(item)

## 事件奖励 weapon_upgrade：随机抽 1 把已装备武器升级（禁 Array.pick_random，走 _event_rng）
func _apply_event_weapon_upgrade(times: int) -> void:
	if gm == null or gm.player == null:
		return
	var wc: Node = gm.player.get_node_or_null("WeaponController")
	if wc == null:
		push_warning("[EventManager] 无 WeaponController，武器升级事件失效")
		return
	var weapons: Array = wc.get("equipped_weapons")
	if weapons.is_empty():
		push_warning("[EventManager] 无已装备武器，武器升级事件失效")
		return
	var idx: int = _event_rng.randi_range(0, weapons.size() - 1)
	var weapon: Resource = weapons[idx]
	if weapon and weapon.has_method("upgrade"):
		for _i in maxi(times, 1):
			weapon.upgrade()
	else:
		push_warning("[EventManager] 抽中武器无效，升级跳过")

## 事件改线（D16-PRE 定案表 5 型；深消费——flag 折扣/难度缩放/局外档案——仅登记，
## 实际消费归 Day 17/20/25/27，W5 不得判失败）
func _apply_route_effect(effect: Dictionary) -> void:
	if gm == null:
		return
	if effect.is_empty() or gm.route.is_empty():
		push_warning("[EventManager] 事件改线效果为空或无路线")
		return
	var route: Dictionary = gm.route
	var etype: String = str(effect.get("type", ""))
	var value: Variant = effect.get("value", "")
	match etype:
		"reroute":
			_apply_reroute(str(value))
		"flag":
			route["flags"] = route.get("flags", {})
			route["flags"][str(value)] = true
		"unlock_node":
			_apply_unlock_node(str(value))
		"add_node":
			_apply_add_node()
		"difficulty":
			route["flags"] = route.get("flags", {})
			route["flags"]["difficulty_delta"] = int(value)
		_:
			push_warning("[EventManager] 未知改线类型: %s" % etype)

## reroute 策略：silent_corridor = 事件减战斗增（增量权重重抽未访问层）；
## shattered_path = 下一节点强制精英。
func _apply_reroute(strategy: String) -> void:
	if gm == null:
		return
	var layers: Array = gm.route.get("layers", [])
	if strategy == "shattered_path":
		if gm.current_layer + 1 < layers.size() and not (layers[gm.current_layer + 1] as Array).is_empty():
			RouteGeneratorScript.force_node_type(gm.route, gm.current_layer + 1, 0, "elite")
		return
	# 默认 silent_corridor：事件 -0.1 / 战斗 +0.1（增量，D16-T2 定案）
	RouteGeneratorScript.reroute_remaining(gm.route, gm.current_layer + 1, {"event": -0.1, "battle": 0.1})

## unlock_node 策略分派：rib_layer_shortcut 跳战斗直通精英 / boss_corrupted_tree_early 直达 Boss 层 /
## awakening_archive 局外档案标记。
func _apply_unlock_node(strategy: String) -> void:
	if gm == null:
		return
	var layers: Array = gm.route.get("layers", [])
	match strategy:
		"rib_layer_shortcut":
			# 下一层首个战斗节点 → 精英
			if gm.current_layer + 1 < layers.size():
				var next_layer: Array = layers[gm.current_layer + 1]
				for i in next_layer.size():
					var t: String = str(next_layer[i].get("type", ""))
					if t == "battle" or t == "elite":
						RouteGeneratorScript.force_node_type(gm.route, gm.current_layer + 1, i, "elite")
						break
		"boss_corrupted_tree_early":
			# 跳到 Boss 前一层（_on_node_completed 会再 +1 → 进入末层 Boss）+ 登记 flag
			if layers.size() >= 3:
				gm.current_layer = layers.size() - 2
			gm.route["flags"] = gm.route.get("flags", {})
			gm.route["flags"]["boss_early"] = true
		"awakening_archive":
			gm.route["flags"] = gm.route.get("flags", {})
			gm.route["flags"]["archive_unlocked"] = true
		_:
			push_warning("[EventManager] 未知 unlock_node 策略: %s" % strategy)

## add_node：当前层 +2 追加 event 节点（不超末层前一层；末层 boss 层不可追加）
## PS-D2a-1（2026-08-17）：boss 层 / 章末 event 层（单节点特殊层）一律拒绝追加——
## 与 reroute/force_node_type 对特殊层的保护同构（防章末「休息+奖励」层被破坏）
func _apply_add_node() -> void:
	if gm == null:
		return
	var layers: Array = gm.route.get("layers", [])
	if layers.size() < 2:
		return
	var target: int = mini(gm.current_layer + 2, layers.size() - 2)
	if _is_special_layer(target):
		push_warning("[EventManager] add_node 目标层 %d 为特殊层（boss/章末 event），拒绝追加" % target)
		return
	(layers[target] as Array).append({"type": "event", "wave_index": 0})

## 特殊层判定：boss_layers 或章末 event 层（0-based；与 route_generator 守卫同构）
func _is_special_layer(li: int) -> bool:
	var boss_layers: Array = []
	for bl in gm.route.get("boss_layers", []):
		boss_layers.append(int(bl))
	if li in boss_layers:
		return true
	if RouteGeneratorScript != null and RouteGeneratorScript.has_method("get_chapter_event_layers"):
		return li in RouteGeneratorScript.get_chapter_event_layers(gm.route)
	return false

## 事件道具 id → Item 资源（仿 shop._build_item_resource / inventory.add_item_from_data 字段装载）
func _build_event_item(item_id: String) -> Resource:
	var data: Dictionary = DataLoader.get_item(item_id)
	if data.is_empty():
		return null
	var item: Resource = Item.new()
	item.item_id = item_id
	item.item_name = str(data.get("name", item_id))
	item.price = int(data.get("price", 0))
	item.rarity = str(data.get("rarity", "common"))
	item.icon_index = maxi(int(data.get("icon_index", 0)), 0)
	item.slot = str(data.get("slot", ""))
	item.category = str(data.get("category", ""))
	item.stat_bonuses = data.get("effects", {})
	return item
