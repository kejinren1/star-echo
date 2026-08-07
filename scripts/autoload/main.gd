## 主场景控制器
## 负责初始化各子系统、连接信号、绑定 GameManager 引用
extends Node2D

# ========== 节点路径 ==========

@onready var ground: Node = $World/Ground
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

## 未经角色选择直接运行 Main.tscn（调试路径）时的兜底英雄
const FALLBACK_CHARACTER_ID: String = "well_rounded"

# ========== 状态 ==========

var current_character_id: String = ""    ## 本局英雄 id
## F-04（金手指）：↑+↓ 同按边缘触发检测（上一帧状态防按住连发）
var _debug_keys_prev: bool = false
## F-03（用户拍板 2026-08-06）：相机震动状态（took_damage 触发；随时间衰减归位）
var _shake_time: float = 0.0
const _SHAKE_DURATION: float = 0.15
const _SHAKE_MAGNITUDE: float = 4.0

# ========== 生命周期 ==========

func _process(delta: float) -> void:
	# F-04（用户拍板 2026-08-06 · P0）：↑+↓ 同按 → 金手指 toggle
	# （跳关 + 攻击×10 + 受伤0.1%；边缘触发，按住不连发）
	var both: bool = Input.is_action_pressed("move_up") and Input.is_action_pressed("move_down")
	if both and not _debug_keys_prev:
		GameManager.toggle_debug_cheat()
	_debug_keys_prev = both
	# F-03（用户拍板 2026-08-06）：相机震动衰减（每帧随机偏移 × 剩余强度）
	if _shake_time > 0.0:
		_shake_time -= delta
		if camera and is_instance_valid(camera):
			var t: float = maxf(_shake_time / _SHAKE_DURATION, 0.0)
			camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _SHAKE_MAGNITUDE * t
			if _shake_time <= 0.0:
				camera.offset = Vector2.ZERO

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

	# 技能数据装载：须在 apply_character 之后（技能可能读 bonus_stats），起始武器之前
	_setup_skill(data)

	_equip_starting_weapon(str(data.get("starting_weapon", "")))

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

## F-03（用户拍板 2026-08-06）：玩家受伤 → 触发相机震动（0.15s 随机抖动后归位）
func _on_player_hit(_amount: float) -> void:
	_shake_time = _SHAKE_DURATION

## 敌人生成时连接死亡信号
func _on_enemy_spawned(enemy: Node) -> void:
	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died)

## 敌人死亡时通知波次管理器并播放死亡特效
func _on_enemy_died(enemy: Node) -> void:
	if wave_manager.has_method("register_kill"):
		wave_manager.register_kill()
	# 播放死亡特效
	if vfx_container and enemy is Node2D:
		VfxPlayer.spawn(vfx_container, enemy.global_position, "death")

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
