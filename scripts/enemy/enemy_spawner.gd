## 敌人生成器
## 负责在波次中按配置生成敌人，管理生成位置和节奏
## 使用 DataLoader 提供的成长公式按波次缩放敌人属性
extends Node2D

# ========== 信号 ==========

signal enemy_spawned(enemy: Node)
signal spawn_complete

# ========== 导出属性 ==========

@export var enemy_scene: PackedScene          ## 敌人场景引用
@export var spawn_margin: float = 100.0       ## 生成位置距屏幕边缘的偏移
@export var base_spawn_interval: float = 0.8  ## 基础生成间隔（秒）

# ========== 内部状态 ==========

var enemies_container: Node                   ## 敌人容器节点
var spawn_queue: Array[Dictionary] = []       ## 待生成队列 [{ enemy_id, wave }]
var _spawn_timer: float = 0.0
var _is_spawning: bool = false
var _current_wave: int = 1

# ========== 生命周期 ==========

func _process(delta: float) -> void:
	if not _is_spawning or spawn_queue.is_empty():
		return
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_next()
		# 生成间隔随波次递减: max(0.3, base - wave * 0.02)
		_spawn_timer = max(0.3, base_spawn_interval - _current_wave * 0.02)

# ========== 生成逻辑 ==========

## 设置敌人容器
func set_container(container: Node) -> void:
	enemies_container = container

## 根据波次配置开始生成敌人
## wave_config: DataLoader.get_wave() 返回的字典
## wave_number: 当前波次号 (用于敌人成长计算)
func spawn_wave(wave_config: Dictionary, wave_number: int = 1) -> void:
	_current_wave = wave_number
	spawn_queue.clear()

	var composition: Array = wave_config.get("composition", [])
	var special: Variant = wave_config.get("special", null)

	for entry in composition:
		var enemy_id: String = entry.get("enemy", "chaser")
		var count: int = entry.get("count", 1)

		# swarm_wave 特殊: 数量翻倍, HP减半 (由生成器在创建时处理)
		if special == "swarm_wave":
			count *= 2

		for i in count:
			spawn_queue.append({"enemy_id": enemy_id, "wave": wave_number, "special": special})

	_is_spawning = true
	_spawn_timer = 0.0

## 生成下一个敌人
func _spawn_next() -> void:
	if spawn_queue.is_empty():
		_is_spawning = false
		spawn_complete.emit()
		return

	var entry: Dictionary = spawn_queue.pop_front()
	var enemy: Node = _create_enemy(entry.enemy_id, entry.wave, entry.get("special", null))
	if enemy and enemies_container:
		enemies_container.add_child(enemy)
		enemy_spawned.emit(enemy)

## 创建敌人实例并初始化
## enemy_id 可以是 "chaser", "elite:butcher", "boss:invoker"
func _create_enemy(enemy_id_raw: String, wave: int, special: Variant) -> Node:
	if not enemy_scene:
		push_warning("[EnemySpawner] enemy_scene 未设置！")
		return null

	# 解析前缀: "elite:butcher" → id="butcher", category="elite"
	var enemy_id := enemy_id_raw
	if ":" in enemy_id_raw:
		var parts := enemy_id_raw.split(":")
		# parts[0] 是 "elite" 或 "boss"，但 DataLoader 已经按 id 索引
		# 所以直接用 parts[1] 作为 id
		enemy_id = parts[1]

	# 从 DataLoader 获取缩放后的敌人数据
	var stats := DataLoader.get_scaled_enemy(enemy_id, wave)
	if stats.is_empty():
		push_warning("[EnemySpawner] 无法找到敌人数据: %s" % enemy_id)
		return null

	# swarm_wave 特殊: HP 减半
	if special == "swarm_wave":
		stats["max_health"] = stats["max_health"] * 0.5

	var enemy: Node = enemy_scene.instantiate()
	if enemy.has_method("initialize"):
		enemy.initialize(stats)

	# 设置生成位置
	if enemy is Node2D:
		enemy.global_position = _get_random_spawn_position()
	# 设置追踪目标
	if GameManager.player and enemy.has_method("set_target"):
		enemy.set_target(GameManager.player)
	return enemy

## 在屏幕内随机位置生成（尽量在可视区域内，且离玩家保持最小距离，避免刷脸）
func _get_random_spawn_position() -> Vector2:
	var viewport_size := get_viewport_rect().size
	var min_dist: float = 110.0   # 离玩家的最小刷新距离，防止一出生就贴脸
	var player_pos := Vector2.ZERO
	if GameManager.player:
		player_pos = GameManager.player.global_position
	# 多次尝试找一个既在屏幕内、又离玩家足够远的点
	for i in range(40):
		var pos := Vector2(
			randf_range(16.0, viewport_size.x - 16.0),
			randf_range(16.0, viewport_size.y - 16.0)
		)
		if pos.distance_to(player_pos) >= min_dist:
			return pos
	# 兜底：直接随机一个点（极端情况下可能偏近，但仍在屏幕内）
	return Vector2(
		randf_range(16.0, viewport_size.x - 16.0),
		randf_range(16.0, viewport_size.y - 16.0)
	)

## 获取当前存活敌人数量
func get_alive_count() -> int:
	if not enemies_container:
		return 0
	return enemies_container.get_child_count()
