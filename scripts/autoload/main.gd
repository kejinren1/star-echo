## 主场景控制器
## 负责初始化各子系统、连接信号、绑定 GameManager 引用
extends Node2D

# ========== 节点路径 ==========

@onready var ground: Node = $World/Ground
@onready var world: Node = $World
@onready var player: Node = $World/Player
@onready var enemies_container: Node = $World/Enemies
@onready var vfx_container: Node = $World/VfxContainer
@onready var enemy_spawner: Node = $World/EnemySpawner
@onready var wave_manager: Node = $WaveManager
@onready var economy: Node = $Economy
@onready var inventory: Node = $Inventory
@onready var hud: Node = $HUD
@onready var shop: Node = $Shop
## F-03（用户拍板 2026-08-06）：固定相机（320,180 视口中心，不跟随）——受伤时 offset 抖动
@onready var camera: Camera2D = $World/MainCamera

# ========== 常量 ==========

## 直接 preload 而非依赖 class_name：无头 `--script` 模式不注册全局类名
const CharacterSelectScript: GDScript = preload("res://scripts/character_select.gd")
## AUDIO_FEEL（AF-P0-A1）：hitstop 顿帧控制器（系统级挂载，同 preload 策略）
const HitstopControllerScript: GDScript = preload("res://scripts/systems/hitstop_controller.gd")

## 未经角色选择直接运行 Main.tscn（调试路径）时的兜底英雄
const FALLBACK_CHARACTER_ID: String = "well_rounded"

# ========== 状态 ==========

var current_character_id: String = ""    ## 本局英雄 id
## F-04（金手指）：↑+↓ 同按边缘触发检测（上一帧状态防按住连发）
var _debug_keys_prev: bool = false
## F-03（用户拍板 2026-08-06）+ AF-P0-B1（2026-08-18）：相机震动状态（分级参数表化——
## light 命中·玩家受伤 / medium 暴击·普通击杀 / heavy Boss 死亡；light = F-03 现值零漂移）
var _shake_time: float = 0.0
var _shake_duration: float = 0.15
var _shake_magnitude: float = 4.0

# ========== 生命周期 ==========

func _process(delta: float) -> void:
	# F-04（用户拍板 2026-08-06 · P0）：↑+↓ 同按 → 金手指 toggle
	# （跳关 + 攻击×10 + 受伤0.1%；边缘触发，按住不连发）
	var both: bool = Input.is_action_pressed("move_up") and Input.is_action_pressed("move_down")
	if both and not _debug_keys_prev:
		GameManager.toggle_debug_cheat()
	_debug_keys_prev = both
	# G-D（2026-08-14）：Esc 暂停菜单（已暂停时跳过——升级/商店/事件弹窗均为暂停式）
	if Input.is_action_just_pressed("ui_cancel") and not get_tree().paused:
		_open_pause_menu()
	# F-03（用户拍板 2026-08-06）+ AF-P0-B1：相机震动衰减（每帧随机偏移 × 剩余强度；
	# 时长/幅度为实例变量 = _trigger_camera_shake 按级别表化赋值）
	if _shake_time > 0.0:
		_shake_time -= delta
		if camera and is_instance_valid(camera):
			var t: float = maxf(_shake_time / maxf(_shake_duration, 0.001), 0.0)
			camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_magnitude * t
			if _shake_time <= 0.0:
				camera.offset = Vector2.ZERO

## G-D：Esc 弹暂停菜单（防重复叠加；战斗场景专属——选角/基地无 main 不触发）
func _open_pause_menu() -> void:
	if get_tree().paused:
		return
	if get_tree().current_scene == null or not get_tree().current_scene.has_node("PauseMenu"):
		get_tree().paused = true
		var menu: Node = load("res://scenes/PauseMenu.tscn").instantiate()
		get_tree().current_scene.add_child(menu)

func _ready() -> void:
	# 装载本局英雄（须在子系统绑定前完成，保证属性/武器在开局即生效）
	_setup_character()

	# 绑定子系统引用到 GameManager
	GameManager.player = player
	GameManager.enemy_spawner = enemy_spawner
	GameManager.wave_manager = wave_manager
	GameManager.economy = economy
	GameManager.inventory = inventory
	GameManager.vfx_container = vfx_container
	# Day 17 · D17-T2：敌人容器（mom 产卵 add_child 目标；缺失静默跳过不崩）
	GameManager.enemies_container = enemies_container
	# F2-T0：World 容器服务（弹丸/炮台/召唤物工厂 + 统一容器注册表）
	GameManager.world = world
	# AUDIO_FEEL（AF-P0-A1 · F2 边界原则系统级）：挂载 hitstop 顿帧控制器（幂等防重）
	var hitstop: Node = get_node_or_null("HitstopController")
	if hitstop == null:
		hitstop = HitstopControllerScript.new()
		hitstop.name = "HitstopController"
		add_child(hitstop)
	GameManager.hitstop_controller = hitstop

	# PS（2026-08-17 用户拍板 · 大地图）：玩家出生移到竞技场中心 + 相机初始位
	# （Ground._ready 已完成居中；无 Ground 时保持场景预设位置）
	var ground: Node = world.get_node_or_null("Ground") if world else null
	if player and ground != null and ground.has_method("get_arena_center"):
		var center: Vector2 = ground.get_arena_center()
		player.global_position = center
		var camera := world.get_node_or_null("MainCamera") as Camera2D
		if camera:
			camera.global_position = center

	# D4-T1：升级 → 暂停 + 弹强化面板（GameManager 侧消费）
	if player and player.has_signal("level_up") and not player.level_up.is_connected(GameManager._on_player_level_up):
		player.level_up.connect(GameManager._on_player_level_up)

	# F-03（用户拍板 2026-08-06）：玩家受伤 → 相机震动（红闪在 player._play_hit_flash 已有）
	if player and player.has_signal("took_damage") and not player.took_damage.is_connected(_on_player_hit):
		player.took_damage.connect(_on_player_hit)

	# D11-12-T3：被动装配链路 —— inventory 道具增减 → player.apply_item_bonuses（买了必生效 / 移除回退）
	# 接线放 Main（GameManager 是 autoload，其 _ready 早于 Main 场景子节点就绪）
	if inventory and player:
		if not inventory.item_added.is_connected(_on_item_added_bonus):
			inventory.item_added.connect(_on_item_added_bonus)
		if not inventory.item_removed.is_connected(_on_item_removed_bonus):
			inventory.item_removed.connect(_on_item_removed_bonus)

	# 配置敌人生成器
	enemy_spawner.set_container(enemies_container)

	# 连接敌人死亡信号到波次管理器
	enemy_spawner.enemy_spawned.connect(_on_enemy_spawned)

	# 初始化金币显示
	economy.reset()

	# 开始游戏（测试用，后续由菜单触发）
	_start_game_delayed()

## 延迟一帧启动游戏，确保所有节点 ready
func _start_game_delayed() -> void:
	await get_tree().process_frame
	GameManager.start_game()

# ========== 角色装载（Day 2） ==========

## 取回 CharacterSelect 的选择结果 → 注入玩家被动 + 起始武器
func _setup_character() -> void:
	current_character_id = _resolve_character_id()
	GameManager.current_character_id = current_character_id

	var data: Dictionary = DataLoader.get_character(current_character_id)
	if data.is_empty():
		push_warning("[Main] 未知英雄 id: %s，沿用出厂属性" % current_character_id)
		return

	# 被动 / 惩罚 / 精灵三项由 Player 内部统一消费，保持单一入口
	if player and player.has_method("apply_character"):
		player.apply_character(data)

	# D27-T3（D42/D43）：局外研究永久增益注入——必须 apply_character 之后
	# （其会 bonus_stats.clear()；本注入直调 apply_stat_modifier 不经 bonus_stats 故无清空险）、
	# _setup_skill 之前；research 全 0 → get_meta_bonus 返回空字典零注入零回归
	if player and player.has_method("apply_stat_modifier"):
		_apply_meta_bonus(player)

	# 技能数据装载：须在 apply_character 之后（技能可能读 bonus_stats），起始武器之前
	_setup_skill(data)

	_equip_starting_weapon(str(data.get("starting_weapon", "")))

## D27-T3：局外研究永久增益装配（damage/max_health 乘算 + luck 加算；三项支持面
## player.apply_stat_modifier :507-545 已实证——damage→damage_multiplier / max_health 乘算 /
## luck 加算；max_health 乘算后 health=min(health,max_health) 满血态无半血截断 D43）
func _apply_meta_bonus(player_node: Node) -> void:
	if player_node == null or not is_instance_valid(player_node):
		return
	var bonus: Dictionary = GameManager.get_meta_bonus()
	if bonus.is_empty():
		return
	if float(bonus.get("attack_mult", 1.0)) > 1.0:
		player_node.apply_stat_modifier("damage", float(bonus["attack_mult"]), true)
	if float(bonus.get("hp_mult", 1.0)) > 1.0:
		player_node.apply_stat_modifier("max_health", float(bonus["hp_mult"]), true)
	if float(bonus.get("luck_add", 0.0)) > 0.0:
		player_node.apply_stat_modifier("luck", float(bonus["luck_add"]), false)
	# G-E（R6 技能树 · O2 独立并存 research）：已解锁节点效果全量注入（与 research 同链路）
	_apply_skill_tree_bonus(player_node)

## G-E：技能树已解锁节点效果注入（meta_progress.skill_tree.unlocked → 节点 effect → apply_stat_modifier）
func _apply_skill_tree_bonus(player_node: Node) -> void:
	var unlocked: Array = GameManager.get_unlocked_skills()
	if unlocked.is_empty():
		return
	var nodes: Array = DataLoader.get_skill_tree().get("nodes", []) if DataLoader else []
	for nid in unlocked:
		for n in nodes:
			if str(n.get("id", "")) != str(nid):
				continue
			var effect: Dictionary = n.get("effect", {})
			var stat: String = str(effect.get("stat", ""))
			if stat != "":
				player_node.apply_stat_modifier(stat, float(effect.get("value", 0.0)), bool(effect.get("mult", false)))
			break

## 把角色 skill 数据注入 SkillController（节点缺失只告警，不阻断开局）
func _setup_skill(char_data: Dictionary) -> void:
	var controller: Node = player.get_node_or_null("SkillController") if player else null
	if controller == null or not controller.has_method("setup"):
		push_warning("[Main] 未找到 SkillController，主动技能未装载")
		return
	controller.setup(char_data)

## 决定本局英雄 id：优先角色选择结果，其次兜底英雄
func _resolve_character_id() -> String:
	var selected: String = CharacterSelectScript.get_selected_character_id(self)
	if not selected.is_empty() and not DataLoader.get_character(selected).is_empty():
		return selected
	return FALLBACK_CHARACTER_ID

## 把角色起始武器装到 WeaponController（节点缺失/未知武器均不阻断开局）
func _equip_starting_weapon(weapon_id: String) -> void:
	if weapon_id.is_empty():
		return
	var controller: Node = player.get_node_or_null("WeaponController") if player else null
	if controller == null or not controller.has_method("equip_from_data"):
		push_warning("[Main] 未找到 WeaponController，起始武器未装载: %s" % weapon_id)
		return
	if not controller.equip_from_data(weapon_id):
		push_warning("[Main] 起始武器装载失败，沿用默认武器: %s" % weapon_id)
		return
	# D13-T2：进局同步 inventory（equip_weapon 尾部已 sync，此处显式补调保持单点语义；
	# 幂等无副作用）→ HUD 读 inventory 显示起始武器
	if controller.has_method("sync_inventory_weapons"):
		controller.sync_inventory_weapons()

# ========== 信号处理 ==========

## F-03（用户拍板 2026-08-06）+ AF-P0-B2：玩家受伤 → 触发相机震动（light 档 = 0.15s/4.0 现值）
func _on_player_hit(_amount: float) -> void:
	_trigger_camera_shake("light")

## AF-P0-B1（2026-08-18 · SPEC F2 震屏分级）：按级别设置相机震动
## light=命中·玩家受伤（0.15s/4.0 = F-03 现值零漂移）/ medium=暴击·普通击杀 / heavy=Boss 死亡
## 参数读 DataLoader.get_stats_feel() 缺键兜底默认（Excel stats_feel 段 → 数据驱动）
func _trigger_camera_shake(level: String) -> void:
	var feel: Dictionary = DataLoader.get_stats_feel()
	match level:
		"medium":
			_shake_duration = float(feel.get("shake_medium_duration", 0.2))
			_shake_magnitude = float(feel.get("shake_medium_magnitude", 6.0))
		"heavy":
			_shake_duration = float(feel.get("shake_heavy_duration", 0.3))
			_shake_magnitude = float(feel.get("shake_heavy_magnitude", 9.0))
		_:  # light 兜底（含未知级别）
			_shake_duration = float(feel.get("shake_light_duration", 0.15))
			_shake_magnitude = float(feel.get("shake_light_magnitude", 4.0))
	_shake_time = _shake_duration

## 敌人生成时连接死亡信号
func _on_enemy_spawned(enemy: Node) -> void:
	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died)
	# F2-T5（T-045）：Boss 击杀信号 → GameManager 登记（boss_killed 计数 + route flags；
	# 装配随 enemy_spawned 完成于 _ready 阶段，Boss 波在游戏开始后生成 → 不漏接）
	if enemy.has_signal("boss_killed"):
		enemy.boss_killed.connect(GameManager.register_boss_killed)

## 敌人死亡时通知波次管理器并播放死亡特效
func _on_enemy_died(enemy: Node) -> void:
	if wave_manager.has_method("register_kill"):
		wave_manager.register_kill()
	# 播放死亡特效
	if vfx_container and enemy is Node2D:
		VfxPlayer.spawn(vfx_container, enemy.global_position, "death")
	AudioManager.play_sfx("death")   # D24-T3-①：敌人死亡 SFX
	# D24-F13-2（F-13 on_kill · executioner_mark 处决印记）：击杀 → 回血 1（插在 death VFX 之后）
	if GameManager and GameManager.inventory and GameManager.inventory.has_item_id(DataLoader.ITEM_EXECUTIONER_MARK) and player:
		player.heal(1.0)

# ========== 被动装配（D11-12-T3） ==========

## 道具入库 → 装配到玩家（只装配 slot=="passive" 或 stat_bonuses 非空的道具，
## 防进化核心移除等无 stat 场景误装配；add_item_from_data 构建的 Item 均带 stat_bonuses）
func _on_item_added_bonus(item: Resource) -> void:
	if not player or item == null:
		return
	var bonuses: Dictionary = item.get("stat_bonuses") if item.has_method("get") else {}
	var is_passive_slot: bool = str(item.get("slot")) == "passive"
	if is_passive_slot or not bonuses.is_empty():
		player.call("apply_item_bonuses", item, false)

## 道具移除 → 回退装配（item_removed 信号已改传 item 本体）
func _on_item_removed_bonus(item: Resource) -> void:
	if not player or item == null:
		return
	var bonuses: Dictionary = item.get("stat_bonuses") if item.has_method("get") else {}
	var is_passive_slot: bool = str(item.get("slot")) == "passive"
	if is_passive_slot or not bonuses.is_empty():
		player.call("apply_item_bonuses", item, true)
