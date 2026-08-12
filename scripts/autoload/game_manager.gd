## 全局游戏管理器 (Autoload 单例)
## 管理游戏状态流转：菜单 → 战斗 → 商店 → 战斗 → ... → 游戏结束
extends Node

# ========== 信号 ==========

signal game_started
signal wave_started(wave_number: int)
signal wave_cleared(wave_number: int)
signal shop_opened
signal shop_closed
signal game_over(victory: bool)
signal state_changed(new_state: GameState)

# ========== 资源引用（D4-T4 / D4-T7 面板） ==========

const LevelUpPanelScene: PackedScene = preload("res://scenes/LevelUpPanel.tscn")
const GameOverPanelScene: PackedScene = preload("res://scenes/GameOverPanel.tscn")
## D14-15-T3：路线生成器（无 class_name，preload 仿 shop.gd 范式）
const RouteGeneratorScript: GDScript = preload("res://scripts/systems/route_generator.gd")
const RouteSelectPanelScene: PackedScene = preload("res://scenes/RouteSelectPanel.tscn")
## D16-T2：事件面板（暂停式弹窗，同 LevelUpPanel 范式）
const EventSelectPanelScene: PackedScene = preload("res://scenes/EventSelectPanel.tscn")
## D16-T2：事件道具直装构造（item.gd 无 class_name，preload 仿 inventory.gd 范式）
const Item: GDScript = preload("res://scripts/items/item.gd")

# ========== 枚举 ==========

enum GameState {
	MENU,       ## 主菜单
	BATTLE,     ## 战斗中
	SHOP,       ## 商店选购
	ROUTE_SELECT,  ## 路线选择（D14-15：随机节点地图选层节点）
	GAME_OVER,  ## 游戏结束（胜利或失败）
}

# ========== 属性 ==========

var current_state: GameState = GameState.MENU
var current_wave: int = 0          ## 当前波次 (从 1 开始)
var max_waves: int = 20            ## 总波次数 (启动时从 DataLoader 加载)
var is_boss_wave: bool = false     ## 当前是否为 Boss 波
var current_character_id: String = ""      ## 本局英雄 id（Main._ready 写入，供 Day 3 主动技能系统读取）
## Day 17 · D17-T4：难度档（Day 16 事件 difficulty 型登记 → 战斗节点入口消费 ±10%/档）
var difficulty_delta: int = 0
## F-04（用户拍板 2026-08-06 · P0）：调试金手指开关（↑+↓ toggle）
## 开启 = 跳关 + 攻击力 ×10 + 受伤 0.1%（约等于无敌），关闭 = 全还原零残留
var debug_cheat: bool = false
## Day 18-19 · T4：本局 Boss 击杀数（register_boss_killed 登记；Day 27 局外养成胜利局数消费源）
var boss_killed: int = 0

# ========== 局外养成（Day 27 · D27-T1） ==========
## 局外元进度（跨局持久化；reset() 不重置——局外数据跨局）
## 结构：{"wins": int, "research_points": int, "research": {"attack": int, "hp": int, "luck": int},
##        "chars": {id: {"xp": int}}}
var meta_progress: Dictionary = {}
## D44：存档路径可覆写（探针注入独立临时档防污染真实存档；默认 user://save_meta.json）
var meta_save_path: String = "user://save_meta.json"

# D14-15-T3：路线模式状态（route 空 = 旧波次制；非空 = 随机节点地图模式）
var route: Dictionary = {}                 ## 本局路线（{seed, layers, modifiers, flags}）
var route_enabled: bool = true             ## 路线模式开关（默认开启；注入 false = 完全旧行为）
var current_layer: int = 0                 ## 当前层索引（0 起）
var current_node: Dictionary = {}          ## 当前节点（{type, wave_index}）
## P1 Fix-1：战后商店标志（区分"战后自动弹商店"与"shop节点商店"的关闭后流向）
var _shop_from_battle: bool = false

# 子系统引用 (由 Main.tscn 在 _ready 中赋值)
var player: Node = null
var wave_manager: Node = null
var enemy_spawner: Node = null
var economy: Node = null
var inventory: Node = null
var vfx_container: Node = null             ## 特效容器节点
## Day 17 · D17-T2：敌人容器（mom 产卵 add_child 目标；main 接线，缺失静默跳过）
var enemies_container: Node = null
## F2-T0：World 容器服务（main._ready 注入；get_world() 是敌人等无 World 父级实体
## 获取 world 的唯一途径——enemy 挂 Enemies 容器下 get_parent()≠World）
var world: Node = null

## F2-T0：取 World 容器服务节点（未注入/已释放 → null，调用方判空兜底；
## 探针实例化 Main 场景后释放时 world 悬空，is_instance_valid 防 freed instance 调用）
func get_world() -> Node:
	if is_instance_valid(world):
		return world
	return null

# UI 面板实例引用（防止连升多级/重复弹窗叠加）
var _level_up_panel: Node = null
var _game_over_panel: Node = null
var _route_select_panel: Node = null      ## 路线选择面板（D14-15）
var _event_panel: Node = null             ## 事件面板（D16）

# ========== 事件节点状态（Day 16 · D16-T2） ==========

## 事件随机性管控：RandomNumberGenerator 实例（种子可复现，探针注入 seed）；
## 禁 Array.shuffle/pick_random（走全局 RNG，D11-12/D14-15 铁律）
var _event_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _current_event: Dictionary = {}       ## 当前事件（_start_event 随机取，resolve 后清空）

# ========== 状态流转方法 ==========

func _ready() -> void:
	# D27-T1：首行加载局外存档（缺失/损坏容错默认零值不崩）
	load_meta()
	# 事件随机源：默认随机化（探针可在调用前覆盖 seed 固定序列）
	_event_rng.randomize()

## 开始新游戏（D14-15：route_enabled → 生成路线；route 空 → 旧波次制回归零破坏）
func start_game() -> void:
	# D27-T1 · D45：出场记录（current_character_id 判空——探针白盒直调时未走
	# main._setup_character，不判空会写 chars[""]）
	if current_character_id != "":
		add_char_xp(current_character_id)
	current_wave = 0
	# 从 DataLoader 加载总波次数
	max_waves = DataLoader.get_max_waves()
	if max_waves <= 0:
		max_waves = 20
	current_layer = 0
	current_node = {}
	route = {}
	if route_enabled:
		var default_seed: int = int(DataLoader.get_routes().get("default_seed", -1))
		route = RouteGeneratorScript.generate(default_seed)
	if route.is_empty():
		# 旧波次制（路线生成失败/被禁用 → 完全旧行为）
		current_state = GameState.BATTLE
		state_changed.emit(current_state)
		game_started.emit()
		_start_next_wave()
		return
	# 路线模式：先发局开始信号，再进入第 1 层路线选择
	game_started.emit()
	_start_route_select()

## 开始下一波（D14-15：wave_number < 0 → 旧累加行为；≥1 → 指定波次）
func _start_next_wave(wave_number: int = -1) -> void:
	if wave_number >= 1:
		current_wave = wave_number
	else:
		current_wave += 1
	# 检查是否为 Boss 波 (wave 10 和 20 有 boss: 前缀敌人)
	var wave_data := DataLoader.get_wave(current_wave)
	is_boss_wave = false
	if not wave_data.is_empty():
		for comp in wave_data.get("composition", []):
			var enemy_id: String = comp.get("enemy", "")
			if enemy_id.begins_with("boss:"):
				is_boss_wave = true
				break
	if is_boss_wave:
		AudioManager.play_sfx("boss")   # D24-T3-⑩：Boss 波 SFX（is_boss_wave 置位处）
	current_state = GameState.BATTLE
	state_changed.emit(current_state)
	wave_started.emit(current_wave)
	if wave_manager:
		wave_manager.start_wave(current_wave)

## 波次完成（D14-15：首行保留清残敌——day4 断言 10；路线模式 → 节点完成推进）
func on_wave_cleared() -> void:
	# D4-T8（BUG-001-F2）：先清残敌、后发奖，避免商店期间残敌继续攻击玩家
	_clear_remaining_enemies()
	# F-05（用户拍板 2026-08-06）：每通一关回复最大生命 50%——清残敌后、发信号前
	# （路线模式 battle/elite 与旧制每波统一生效；event/shop 节点不经过本入口天然豁免；
	# 防 P1-1 商店弹出前玩家已带伤进场）
	_apply_wave_heal()
	wave_cleared.emit(current_wave)
	if not route.is_empty():
		_on_node_completed()
		return
	if current_wave >= max_waves:
		end_game(true)
		return
	current_state = GameState.SHOP
	state_changed.emit(current_state)
	shop_opened.emit()

## D4-T8：波次切换清理残敌（直接 queue_free，最简且无残留状态）
func _clear_remaining_enemies() -> void:
	if enemy_spawner == null or enemy_spawner.enemies_container == null:
		return
	for enemy in enemy_spawner.enemies_container.get_children():
		if is_instance_valid(enemy):
			enemy.queue_free()

## F-05（用户拍板 2026-08-06）：通关回血 50% 最大生命
## 独立方法便于探针白盒直调；玩家未绑定/已死时静默跳过不崩
func _apply_wave_heal() -> void:
	if player == null or not is_instance_valid(player):
		return
	if not player.has_method("heal") or not ("max_health" in player):
		return
	player.heal(float(player.max_health) * 0.5)

## 关闭商店（P1 Fix-1：战后商店 → 路线选择；shop节点商店 → 节点完成推进；旧模式 → 下一波）
func close_shop() -> void:
	shop_closed.emit()
	if not route.is_empty():
		if _shop_from_battle:
			_shop_from_battle = false
			_start_route_select()
			return
		_on_node_completed()
		return
	_start_next_wave()

# ========== 路线模式（Day 14-15 · D14-15-T3） ==========

## 进入第 current_layer 层路线选择：状态 + 面板（复用已有面板实例防叠加）
func _start_route_select() -> void:
	current_state = GameState.ROUTE_SELECT
	state_changed.emit(current_state)
	if _route_select_panel == null or not is_instance_valid(_route_select_panel):
		_route_select_panel = RouteSelectPanelScene.instantiate()
		# 身份校验防误清：旧面板 tree_exited 时 _route_select_panel 可能已指向新面板
		# （reset() 先 queue_free 旧面板、后建新面板的时序 → 旧回调不得清新引用）
		_route_select_panel.tree_exited.connect(func() -> void:
			if _route_select_panel == self:
				_route_select_panel = null
		)
		_add_to_ui_layer(_route_select_panel)
	if _route_select_panel.has_method("setup"):
		_route_select_panel.setup(route, current_layer)

## 玩家选中本层某节点（row = 本层内索引）→ 进入对应节点
func select_route_node(row: int) -> void:
	var layers: Array = route.get("layers", [])
	if current_layer < 0 or current_layer >= layers.size():
		push_warning("[Route] 层索引越界: %d" % current_layer)
		return
	var layer_nodes: Array = layers[current_layer]
	if row < 0 or row >= layer_nodes.size():
		push_warning("[Route] 节点索引越界: %d/%d" % [row, layer_nodes.size()])
		return
	current_node = layer_nodes[row]
	_enter_node(str(current_node.get("type", "")), int(current_node.get("wave_index", 0)))

## 按节点类型进入：战斗类 → 波次；shop → 商店段；event → Day 16 事件流程
func _enter_node(node_type: String, wave_index: int) -> void:
	match node_type:
		"battle", "elite", "boss":
			# Day 17 · D17-T4：difficulty_delta 消费（Day 16 事件登记 → 本波敌人 ±10%/档；
			# 空 route / 无 flags → 0 零影响）
			difficulty_delta = int(route.get("flags", {}).get("difficulty_delta", 0)) if not route.is_empty() else 0
			# Day 17 · D17-T4：精英节点进入提示横幅（不暂停，与选层/商店同范式）
			if node_type == "elite":
				_show_elite_banner()
			# Day 18-19 · T4：Boss 节点进入提示横幅 + flags 登记（route 空旧制零影响）
			if node_type == "boss":
				_show_boss_banner()
				route["flags"] = route.get("flags", {})
				route["flags"]["boss_encountered"] = true
			_start_next_wave(wave_index)
		"shop":
			current_state = GameState.SHOP
			state_changed.emit(current_state)
			shop_opened.emit()
		"event":
			# D16：事件节点 → 随机取事件 + 暂停式弹窗（交互逻辑本日实装，D14-15 占位已替换）
			_start_event()
		_:
			push_warning("[Route] 未知节点类型: %s，按已完成处理" % node_type)
			_on_node_completed()

## Day 17 · D17-T4：精英节点进入轻量横幅「⚔ 精英来袭」（1.5s 淡出上浮后自毁，
## 仿 enemy.gd _spawn_exp_popup 范式；容器缺失静默跳过不崩）
func _show_elite_banner() -> void:
	var container: Node = vfx_container if vfx_container else null
	if container == null:
		container = get_tree().current_scene
	if container == null:
		return
	var banner := Node2D.new()
	banner.name = "EliteBanner"
	var label := Label.new()
	label.text = "⚔ 精英来袭"
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(0.95, 0.75, 0.35))
	banner.add_child(label)
	container.add_child(banner)
	banner.global_position = Vector2(320.0, 90.0)
	var tween := banner.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "modulate:a", 0.0, 1.5)
	tween.tween_property(banner, "global_position:y", banner.global_position.y - 30.0, 1.5)
	tween.chain().tween_callback(banner.queue_free)

## Day 18-19 · T4：Boss 节点进入横幅「⚠ 最终 Boss」（仿 _show_elite_banner 范式；
## 容器缺失静默跳过不崩）
func _show_boss_banner() -> void:
	var container: Node = vfx_container if vfx_container else null
	if container == null:
		container = get_tree().current_scene
	if container == null:
		return
	var banner := Node2D.new()
	banner.name = "BossBanner"
	var label := Label.new()
	label.text = "⚠ 最终 Boss"
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", Color(0.95, 0.35, 0.35))
	banner.add_child(label)
	container.add_child(banner)
	banner.global_position = Vector2(320.0, 90.0)
	var tween := banner.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "modulate:a", 0.0, 1.5)
	tween.tween_property(banner, "global_position:y", banner.global_position.y - 30.0, 1.5)
	tween.chain().tween_callback(banner.queue_free)

## Day 18-19 · T4：Boss 击杀登记（enemy.gd die() 调用；boss_killed 计数 + route flags 标记；
## route 空（旧波次制）仅计数零影响；boss_defeated 由 Day 27 end_game(victory) 统一消费）
func register_boss_killed() -> void:
	boss_killed += 1
	if not route.is_empty():
		route["flags"] = route.get("flags", {})
		route["flags"]["boss_defeated"] = true

# ========== 调试金手指（F-04 · 用户拍板 2026-08-06） ==========
## ↑+↓ 同按 → toggle：跳关 + 攻击 ×10 + 受伤 0.1%。机器可验证（探针白盒直调）。
## 攻击倍率走 player.debug_mult（weapon_controller/skill_controller 聚合消费）；
## 受伤 0.1% 走 player.take_damage 消费。关闭全还原（debug_mult 1.0 / 无残留状态）。
func toggle_debug_cheat() -> void:
	debug_cheat = not debug_cheat
	if player and "debug_mult" in player:
		player.debug_mult = 10.0 if debug_cheat else 1.0
	if debug_cheat and current_state == GameState.BATTLE:
		# 跳关：清残敌 + 直接进入下一波（仅战斗状态可跳，防路线选择/商店误触）
		_clear_remaining_enemies()
		_start_next_wave(current_wave + 1)
	_show_debug_banner()

## 金手指状态横幅（1.5s 淡出，复用精英横幅范式；容器缺失静默跳过）
func _show_debug_banner() -> void:
	var container: Node = vfx_container if vfx_container else null
	if container == null:
		container = get_tree().current_scene
	if container == null:
		return
	var banner := Node2D.new()
	banner.name = "DebugBanner"
	var label := Label.new()
	label.text = "🛠 金手指 %s（攻击×10 · 受伤0.1%%）" % ("ON" if debug_cheat else "OFF")
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.6, 0.95, 0.6))
	banner.add_child(label)
	container.add_child(banner)
	banner.global_position = Vector2(320.0, 130.0)
	var tween := banner.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "modulate:a", 0.0, 1.5)
	tween.tween_property(banner, "global_position:y", banner.global_position.y - 30.0, 1.5)
	tween.chain().tween_callback(banner.queue_free)

## 当前节点完成 → 下一层选择；末层完成 → 胜利
## P1 Fix-1：battle/elite 完成后先弹商店（玩家需要花战斗赚的金币），关闭后再进路线选择
func _on_node_completed() -> void:
	current_layer += 1
	if current_layer >= route.get("layers", []).size():
		end_game(true)
		return
	# 战斗类节点完成后自动弹商店（Brotato 式每波后购物）
	var prev_type: String = str(current_node.get("type", ""))
	if prev_type == "battle" or prev_type == "elite":
		_shop_from_battle = true
		current_state = GameState.SHOP
		state_changed.emit(current_state)
		shop_opened.emit()
		return
	_start_route_select()

# ========== 事件节点（Day 16 · D16-T2） ==========

## 事件节点进入：随机取 1 条事件（可重复符合肉鸽；零 route_generator 改动）→
## 暂停游戏 + 实例化面板渲染。事件数据缺失 → 告警并按已完成推进（不卡死）。
func _start_event() -> void:
	if _event_panel != null and is_instance_valid(_event_panel):
		return  # 面板已在显示，防重复实例化
	AudioManager.play_sfx("event")   # D24-T3-⑨：事件节点 SFX
	var events: Array = DataLoader.get_events()
	if events.is_empty():
		push_warning("[GameManager] 事件数据为空，事件节点按已完成处理")
		_on_node_completed()
		return
	var idx: int = _event_rng.randi_range(0, events.size() - 1)
	_current_event = events[idx]
	get_tree().paused = true
	_event_panel = EventSelectPanelScene.instantiate()
	_event_panel.tree_exited.connect(func() -> void:
		if _event_panel == self:
			_event_panel = null
	)
	_add_to_ui_layer(_event_panel)
	if _event_panel.has_method("setup"):
		_event_panel.setup(_current_event)

## 玩家选择事件选项：A → 奖励结算；B → 改线；随后恢复运行 + 节点完成推进。
## 面板释放由面板自身 queue_free（GameManager 不重复 free，防双释放）。
func resolve_event_choice(choice: String) -> void:
	if _current_event.is_empty():
		push_warning("[GameManager] resolve_event_choice 无当前事件")
		return
	if choice == "A":
		_apply_event_reward(_current_event.get("choiceA", {}).get("reward", {}))
	else:
		_apply_route_effect(_current_event.get("choiceB", {}).get("effect_on_route", {}))
	_current_event = {}
	get_tree().paused = false
	_on_node_completed()

## 事件奖励结算（D16-PRE 定案表 10 型；STAT_MAP 无 attack_percent/max_hp_percent →
## 代码层别名 attack_percent→damage / max_hp_percent→max_health，禁改 STAT_MAP 防波及 D4/D11-12 探针）
func _apply_event_reward(reward: Dictionary) -> void:
	if reward.is_empty():
		push_warning("[GameManager] 事件奖励为空")
		return
	if player == null:
		push_warning("[GameManager] 玩家未绑定，事件奖励结算跳过")
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
			if economy:
				economy.add_coins(int(value))
			else:
				push_warning("[GameManager] 经济系统未绑定，金币奖励失效")
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
			push_warning("[GameManager] 未知事件奖励类型: %s（已登记）" % rtype)

## 事件奖励 item：遗物语义直装生效（不进 inventory 6 被动槽；完整遗物槽归 Day 20）。
## id 未知 → push_warning 登记兜底不崩（resonant_shard 已由 D16-T4 补齐）。
func _apply_event_item(item_id: String) -> void:
	if item_id.is_empty():
		return
	var data: Dictionary = DataLoader.get_item(item_id)
	if data.is_empty():
		push_warning("[GameManager] 事件奖励道具缺失: %s" % item_id)
		return
	var item: Resource = _build_event_item(item_id)
	if item != null and player.has_method("apply_item_bonuses"):
		player.apply_item_bonuses(item)

## 事件奖励 weapon_upgrade：随机抽 1 把已装备武器升级（禁 Array.pick_random，走 _event_rng）
func _apply_event_weapon_upgrade(times: int) -> void:
	var wc: Node = player.get_node_or_null("WeaponController") if player else null
	if wc == null:
		push_warning("[GameManager] 无 WeaponController，武器升级事件失效")
		return
	var weapons: Array = wc.get("equipped_weapons")
	if weapons.is_empty():
		push_warning("[GameManager] 无已装备武器，武器升级事件失效")
		return
	var idx: int = _event_rng.randi_range(0, weapons.size() - 1)
	var weapon: Resource = weapons[idx]
	if weapon and weapon.has_method("upgrade"):
		for _i in maxi(times, 1):
			weapon.upgrade()
	else:
		push_warning("[GameManager] 抽中武器无效，升级跳过")

## 事件改线（D16-PRE 定案表 5 型；深消费——flag 折扣/难度缩放/局外档案——仅登记，
## 实际消费归 Day 17/20/25/27，W5 不得判失败）
func _apply_route_effect(effect: Dictionary) -> void:
	if effect.is_empty() or route.is_empty():
		push_warning("[GameManager] 事件改线效果为空或无路线")
		return
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
			push_warning("[GameManager] 未知改线类型: %s" % etype)

## reroute 策略：silent_corridor = 事件减战斗增（增量权重重抽未访问层）；
## shattered_path = 下一节点强制精英。
func _apply_reroute(strategy: String) -> void:
	var layers: Array = route.get("layers", [])
	if strategy == "shattered_path":
		if current_layer + 1 < layers.size() and not (layers[current_layer + 1] as Array).is_empty():
			RouteGeneratorScript.force_node_type(route, current_layer + 1, 0, "elite")
		return
	# 默认 silent_corridor：事件 -0.1 / 战斗 +0.1（增量，D16-T2 定案）
	RouteGeneratorScript.reroute_remaining(route, current_layer + 1, {"event": -0.1, "battle": 0.1})

## unlock_node 策略分派：rib_layer_shortcut 跳战斗直通精英 / boss_corrupted_tree_early 直达 Boss 层 /
## awakening_archive 局外档案标记。
func _apply_unlock_node(strategy: String) -> void:
	var layers: Array = route.get("layers", [])
	match strategy:
		"rib_layer_shortcut":
			# 下一层首个战斗节点 → 精英
			if current_layer + 1 < layers.size():
				var next_layer: Array = layers[current_layer + 1]
				for i in next_layer.size():
					var t: String = str(next_layer[i].get("type", ""))
					if t == "battle" or t == "elite":
						RouteGeneratorScript.force_node_type(route, current_layer + 1, i, "elite")
						break
		"boss_corrupted_tree_early":
			# 跳到 Boss 前一层（_on_node_completed 会再 +1 → 进入末层 Boss）+ 登记 flag
			if layers.size() >= 3:
				current_layer = layers.size() - 2
			route["flags"] = route.get("flags", {})
			route["flags"]["boss_early"] = true
		"awakening_archive":
			route["flags"] = route.get("flags", {})
			route["flags"]["archive_unlocked"] = true
		_:
			push_warning("[GameManager] 未知 unlock_node 策略: %s" % strategy)

## add_node：当前层 +2 追加 event 节点（不超末层前一层；末层 boss 层不可追加）
func _apply_add_node() -> void:
	var layers: Array = route.get("layers", [])
	if layers.size() < 2:
		return
	var target: int = mini(current_layer + 2, layers.size() - 2)
	(layers[target] as Array).append({"type": "event", "wave_index": 0})

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

## 结束游戏
func end_game(victory: bool) -> void:
	current_state = GameState.GAME_OVER
	state_changed.emit(current_state)
	# D27-T1：胜利结算（wins+1 / 研究点+1 / 当前角色 xp+1 + 存档）——须在
	# game_over.emit 前完成（防信号消费方读脏状态）；失败局不结算（出场已在 start_game 记）
	if victory:
		meta_progress["wins"] = int(meta_progress.get("wins", 0)) + 1
		meta_progress["research_points"] = int(meta_progress.get("research_points", 0)) + 1
		if current_character_id != "":
			add_char_xp(current_character_id)
		save_meta()
	# D4-T7（BUG-001-F1）：死亡/胜利后暂停，防敌人继续攻击连锁异常
	get_tree().paused = true
	_spawn_game_over_panel(victory)
	game_over.emit(victory)

## 重置游戏状态
func reset() -> void:
	get_tree().paused = false
	current_state = GameState.MENU
	current_wave = 0
	is_boss_wave = false
	difficulty_delta = 0
	boss_killed = 0
	route = {}
	current_layer = 0
	current_node = {}
	_shop_from_battle = false
	_level_up_panel = null
	_game_over_panel = null
	if _route_select_panel != null and is_instance_valid(_route_select_panel):
		_route_select_panel.queue_free()
	_route_select_panel = null
	if _event_panel != null and is_instance_valid(_event_panel):
		_event_panel.queue_free()
	_event_panel = null
	_current_event = {}
	state_changed.emit(current_state)

# ========== 升级面板（Day 4 · D4-T1/D4-T4） ==========

## 玩家升级处理器：暂停游戏并弹出三选一强化面板
## 连升多级（+60 经验一次弹 2+ 级）时同步触发多次：面板已存在则跳过（合并策略，
## 见 TASKS D4-T4 测试点「逐级弹窗或合并二选一」），避免多面板叠加
func _on_player_level_up(_new_level: int) -> void:
	if _level_up_panel != null and is_instance_valid(_level_up_panel):
		return
	get_tree().paused = true
	_level_up_panel = LevelUpPanelScene.instantiate()
	_level_up_panel.tree_exited.connect(func() -> void:
		if _level_up_panel == self:
			_level_up_panel = null
	)
	_add_to_ui_layer(_level_up_panel)
	if _level_up_panel.has_method("setup"):
		_level_up_panel.setup()

## D4-T7（BUG-001-F1）：死亡/胜利结果面板
func _spawn_game_over_panel(victory: bool) -> void:
	if _game_over_panel != null and is_instance_valid(_game_over_panel):
		return
	# F-26（2026-08-08 用户拍板）：删波次改关卡制——阵亡文案显示「第 N 关」而非波次号
	# （路线模式关 = 层+1；旧波次制 = current_wave）
	var stage: int = current_wave
	if not route.is_empty():
		stage = current_layer + 1
	var reason: String = "你在第 %d 关阵亡了" % stage if not victory else "你击败了星骸的异变！"
	_game_over_panel = GameOverPanelScene.instantiate()
	_game_over_panel.tree_exited.connect(func() -> void:
		if _game_over_panel == self:
			_game_over_panel = null
	)
	# 先入树再 setup（@onready 节点引用须在 _ready 之后才可用）
	_add_to_ui_layer(_game_over_panel)
	if _game_over_panel.has_method("setup"):
		_game_over_panel.setup(victory, reason)

## 面板统一挂到 UI 层：优先当前场景（Main），无 current_scene（无头测试直接 add 到 root）时挂 root
func _add_to_ui_layer(panel: Node) -> void:
	var target: Node = get_tree().current_scene if get_tree().current_scene else get_tree().root
	target.add_child(panel)

# ========== 局外养成接口（Day 27 · D27-T1） ==========

## 默认零值元进度（load_meta 兜底与 reset 复用）
func _default_meta() -> Dictionary:
	return {
		"wins": 0,
		"research_points": 0,
		"research": {"attack": 0, "hp": 0, "luck": 0},
		"chars": {},
	}

## 加载局外存档：缺文件/打开失败/非 Dictionary → 默认零值 + push_warning 容错不崩；
## 成功 → 逐键 int() 收敛（Godot 4.3 JSON 全数字 float 的已知特性，DataLoader 先例）
func load_meta() -> void:
	meta_progress = _default_meta()
	if not FileAccess.file_exists(meta_save_path):
		return
	var f := FileAccess.open(meta_save_path, FileAccess.READ)
	if f == null:
		push_warning("[GameManager] 存档打开失败(%s)，使用默认元进度" % meta_save_path)
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if not (parsed is Dictionary):
		push_warning("[GameManager] 存档解析失败(%s)，使用默认元进度" % meta_save_path)
		return
	var data: Dictionary = parsed as Dictionary
	meta_progress["wins"] = int(data.get("wins", 0))
	meta_progress["research_points"] = int(data.get("research_points", 0))
	var research: Dictionary = data.get("research", {})
	meta_progress["research"] = {
		"attack": int(research.get("attack", 0)),
		"hp": int(research.get("hp", 0)),
		"luck": int(research.get("luck", 0)),
	}
	var chars: Dictionary = data.get("chars", {})
	var clean_chars: Dictionary = {}
	for cid in chars.keys():
		var cdata: Variant = chars[cid]
		var xp: int = int(cdata.get("xp", 0)) if cdata is Dictionary else 0
		clean_chars[str(cid)] = {"xp": xp}
	meta_progress["chars"] = clean_chars

## 保存局外存档（每次结算/研究升级后调用）
func save_meta() -> void:
	var f := FileAccess.open(meta_save_path, FileAccess.WRITE)
	if f == null:
		push_warning("[GameManager] 存档写入失败(%s)" % meta_save_path)
		return
	f.store_string(JSON.stringify(meta_progress, "  "))

## 局外永久增益换算：attack ×(1+0.05/级) / max_health ×(1+0.10/级) / luck +0.05/级
## research 全 0 → 返回空字典（调用方零注入零回归）
func get_meta_bonus() -> Dictionary:
	var research: Dictionary = meta_progress.get("research", {})
	var atk: int = int(research.get("attack", 0))
	var hp: int = int(research.get("hp", 0))
	var lck: int = int(research.get("luck", 0))
	if atk <= 0 and hp <= 0 and lck <= 0:
		return {}
	return {
		"attack_mult": 1.0 + 0.05 * float(atk),
		"hp_mult": 1.0 + 0.10 * float(hp),
		"luck_add": 0.05 * float(lck),
	}

## 研究升级（消耗 1 点）：成功 true；键非法/已满级/点数不足 → false 不扣点
func upgrade_research(key: String) -> bool:
	if key != "attack" and key != "hp" and key != "luck":
		return false
	var research: Dictionary = meta_progress.get("research", {})
	if int(research.get(key, 0)) > 0:
		return false
	var points: int = int(meta_progress.get("research_points", 0))
	if points <= 0:
		return false
	research[key] = 1
	meta_progress["research"] = research
	meta_progress["research_points"] = points - 1
	save_meta()
	return true

## 增加研究点（胜利结算调用）
func add_research_point(amount: int = 1) -> void:
	meta_progress["research_points"] = int(meta_progress.get("research_points", 0)) + maxi(amount, 0)

## 角色 XP 累计（出场/胜场各 +1；id 空判空跳过）
func add_char_xp(id: String, amount: int = 1) -> void:
	if id.is_empty():
		return
	var chars: Dictionary = meta_progress.get("chars", {})
	var cdata: Dictionary = chars.get(id, {})
	chars[id] = {"xp": int(cdata.get("xp", 0)) + maxi(amount, 0)}
	meta_progress["chars"] = chars

func get_char_xp(id: String) -> int:
	return int(meta_progress.get("chars", {}).get(id, {}).get("xp", 0))

## 角色等级 = xp/3 向下取整（仅驱动剧情解锁 + 展示，无属性收益）
func get_char_level(id: String) -> int:
	return int(get_char_xp(id) / 3)
