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
## Day 17 · D17-T3（BUG-003 收口）：mixed 家族池解析专用 RNG 实例
## （探针可注 _rng.seed 固定序列；禁全局 RNG 洗牌——D11-12/D14-15 铁律；
##  仅影响「抽哪个敌人」，不影响位置随机 randf_range）
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
## LD-B（2026-08-19 · LEVEL_DESIGN 规格 docs/LEVEL_DESIGN_SPEC.md）：本波固定出生点组
## （wave_manager 从 waves 行透传 spawn_set/spawn_order；空字典 = 缺省回退原随机路径，
##  F-48 修复零回归）
var _spawn_override: Dictionary = {}
## LD-B：点位轮换/圆周均分游标——sequence 按组循环推进防同角落堆叠；
## ring 圆周均分按已生成数取角（与轮换游标同源）
var _spawn_index: int = 0

# ========== 生命周期 ==========

func _ready() -> void:
	_rng.randomize()

func _process(delta: float) -> void:
	# D4-T8（BUG-001-F2）：商店/结算期间禁止继续生成（波次定时结束但队列未清空时
	# 残留队列会在 SHOP 状态继续刷怪 → 商店中玩家被围殴）
	if GameManager.current_state != GameManager.GameState.BATTLE:
		return
	if not _is_spawning:
		return
	# F-39（2026-08-15 真人反馈）：队列已空但标志未复位——旧逻辑
	# `if not _is_spawning or spawn_queue.is_empty(): return` 短路：队列空时永不调
	# _spawn_next → 空队列分支（置 false + spawn_complete）永不执行 → _is_spawning 永久 true
	# → wave_manager.check_wave_clear 的 _spawning_incomplete() 永久 true → 普通关永不判通，
	# 干等 30s 超时兜底（Boss 关不走该检查故秒通）→ 用户感知「第 10 关 Boss 后第 11 层
	# 战斗/精英节点没法选择」→ 此处自愈复位（仅一次：复位后下帧 _is_spawning false 短路）
	if spawn_queue.is_empty():
		_is_spawning = false
		spawn_complete.emit()
		return
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_next()
		# 生成间隔随波次递减（F1-B 参数化 2026-08-10：waves.json.generation）
		# 公式: max(spawn_interval_min, base_spawn_interval - wave * spawn_interval_decay)
		var gen: Dictionary = DataLoader.get_wave_generation()
		var interval_min: float = float(gen.get("spawn_interval_min", 0.3))
		var interval_decay: float = float(gen.get("spawn_interval_decay", 0.02))
		_spawn_timer = max(interval_min, base_spawn_interval - _current_wave * interval_decay)

# ========== 生成逻辑 ==========

## 设置敌人容器
func set_container(container: Node) -> void:
	enemies_container = container

## 根据波次配置开始生成敌人
## wave_config: DataLoader.get_wave() 返回的字典
## wave_number: 当前波次号 (用于敌人成长计算)
## spawn_override: LD-B 固定出生点组（{"spawn_set": Array, "spawn_order": String}；
## 缺省空 = 兼容旧调用 + 缺省随机路径零回归）
func spawn_wave(wave_config: Dictionary, wave_number: int = 1, spawn_override: Dictionary = {}) -> void:
	_current_wave = wave_number
	_spawn_override = spawn_override
	_spawn_index = 0
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
	# F-39（2026-08-15）：pop 最后一只后队列变空 → 立即复位生成标志 + 发完成信号
	# （此前仅依赖 _process 空队列分支触发——该分支被短路逻辑挡死永不执行 → 死锁）
	if spawn_queue.is_empty():
		_is_spawning = false
		spawn_complete.emit()

## 创建敌人实例并初始化
## enemy_id 可以是 "chaser", "elite:butcher", "boss:invoker"
func _create_enemy(enemy_id_raw: String, wave: int, special: Variant) -> Node:
	if not enemy_scene:
		push_warning("[EnemySpawner] enemy_scene 未设置！")
		return null

	# 解析前缀: "elite:butcher" → id="butcher", prefix="elite"；
	# "elite:mixed" → prefix="elite", id="mixed"（池令牌，走下方分支）
	var enemy_id := enemy_id_raw
	var prefix := ""
	if ":" in enemy_id_raw:
		var parts := enemy_id_raw.split(":")
		# parts[0] 是 "elite" 或 "boss"；parts[1] 是 id（或池令牌 "mixed"）
		prefix = parts[0]
		enemy_id = parts[1]

	# Day 17 · D17-T3（BUG-003 收口）：mixed 家族池令牌 → 前缀决定抽哪个池
	# mixed / mixed_with_curse → regular 池随机；elite:mixed → elite 池随机
	# （waves.json wave 15/17/19 此前「精英+普通敌全部静默不生成」，本分支修复；
	#  未知 id 仍走下方 push_warning + null，不静默扩池）
	if enemy_id == "mixed" or enemy_id == "mixed_with_curse":
		var pool_category: String = "elite" if prefix == "elite" else "regular"
		var pool: Array = DataLoader.get_enemy_ids_by_category(pool_category)
		if pool.is_empty():
			push_warning("[EnemySpawner] 池分类为空: %s" % pool_category)
			return null
		enemy_id = str(pool[_rng.randi_range(0, pool.size() - 1)])

	# 从 DataLoader 获取缩放后的敌人数据
	var stats := DataLoader.get_scaled_enemy(enemy_id, wave)
	if stats.is_empty():
		push_warning("[EnemySpawner] 无法找到敌人数据: %s" % enemy_id)
		return null

	# Day 17 · D17-T2：自身波次透传（mom 产卵用同波缩放；池解析先、缩放后顺序兼容）
	stats["wave_number"] = wave

	# swarm_wave 特殊: HP 减半（池解析之后缩放——wave 15 的 swarm 语义保持）
	if special == "swarm_wave":
		stats["max_health"] = stats["max_health"] * 0.5

	# Day 17 · D17-T4：difficulty_delta 消费（Day 16 事件登记 → ±1 档 ±10% hp/damage）
	if GameManager and GameManager.difficulty_delta != 0:
		var dd: int = GameManager.difficulty_delta
		stats["max_health"] = stats["max_health"] * (1.0 + 0.1 * dd)
		stats["damage"] = stats["damage"] * (1.0 + 0.1 * dd)

	var enemy: Node = enemy_scene.instantiate()
	if enemy.has_method("initialize"):
		enemy.initialize(stats)

	# 设置生成位置
	if enemy is Node2D:
		enemy.global_position = _get_spawn_position()
	# 设置追踪目标
	if GameManager.player and enemy.has_method("set_target"):
		enemy.set_target(GameManager.player)
	return enemy

## 在玩家周围随机位置生成（尽量在可视区域内，且离玩家保持最小距离，避免刷脸）
## PS（2026-08-17 用户拍板 · 大地图）：原「全视口随机」在玩家远离竞技场中心时会把敌人
## 生成到墙外 → 改为以玩家为中心、±半视口矩形内随机，并钳制回竞技场内
func _get_random_spawn_position() -> Vector2:
	var min_dist: float = 110.0   # 离玩家的最小刷新距离，防止一出生就贴脸
	var player_pos := Vector2.ZERO
	if GameManager.player:
		player_pos = GameManager.player.global_position
	# F-48（2026-08-18 用户反馈「最后一个敌人死活不出现」）：生成矩形收紧为 ±200×±120
	# （原 ±半视口 320×180：玩家站竞技场角落时生成点落在「视口外但 < 原 leash 420」的
	#  死角 → 玩家找不到 → 打不死 → 关卡卡死）。收紧后生成点必在玩家视野内
	# （320 半宽 × 180 半高内），配合 Aggro Leash 320 双保险：任何离玩家 >320px 的怪
	# （生成/被击退/漂移）都强制直追回视野
	for i in range(40):
		var pos := Vector2(
			player_pos.x + randf_range(-200.0, 200.0),
			player_pos.y + randf_range(-120.0, 120.0)
		)
		if pos.distance_to(player_pos) >= min_dist:
			return _clamp_to_ground(pos)
	# 兜底：直接玩家周围随机一个点（极端情况下可能偏近，但仍在场内）
	return _clamp_to_ground(Vector2(
		player_pos.x + randf_range(-160.0, 160.0),
		player_pos.y + randf_range(-160.0, 160.0)
	))

## LD-B（2026-08-19 · LEVEL_DESIGN 规格）：本波按固定出生点表驱动生成——表驱动主路径。
## 点位队列按 spawn_order 轮换（sequence = 数组循环 index 递增 / random = 组内随机）；
## 单只连续生成多只时 index 推进防同一角落堆叠；ring 圆周均分按已生成数取角。
## min_dist_player 兜底：尝试换点（sequence 循环覆盖 / random 重抽），仍过近则原样生成
## 不静默丢弃（沿用现兜底语义）。缺省回退：override 空 / 点位表空 / point_id 不存在 →
## 保留现 _get_random_spawn_position（±200×±120）路径零回归（F-48 视野内双保险：
## inset 40 点位 + Aggro Leash 320）。
func _get_spawn_position() -> Vector2:
	var points_raw: Variant = _spawn_override.get("spawn_set", [])
	var points: Array = points_raw if points_raw is Array else []
	if points.is_empty():
		return _get_random_spawn_position()
	var order: String = str(_spawn_override.get("spawn_order", "sequence"))
	var spawn_table: Dictionary = DataLoader.get_spawn_points()
	var player_pos := Vector2.ZERO
	if GameManager.player:
		player_pos = GameManager.player.global_position
	var last_resolved: Vector2 = Vector2.ZERO
	var resolved_any := false
	# 尝试换点（sequence 轮换全覆盖，至少 3 次；全部过近 → 原样生成不静默丢弃）
	for attempt in range(max(3, points.size())):
		var point_id: String
		if order == "random":
			point_id = str(points[_rng.randi_range(0, points.size() - 1)])
		else:
			point_id = str(points[_spawn_index % points.size()])
		var cfg: Dictionary = spawn_table.get(point_id, {})
		if cfg.is_empty():
			_spawn_index += 1  # 无效点位：推进轮换游标（sequence 防卡死同点）
			continue  # point_id 不存在 → 换下一个（全无效 → 随机兜底）
		var pos := _resolve_point(cfg)  # ring 角度 = 本次生成序（当前 _spawn_index）
		_spawn_index += 1
		last_resolved = pos
		resolved_any = true
		if pos.distance_to(player_pos) >= float(cfg.get("min_dist_player", 110.0)):
			return _clamp_to_ground(pos)
	# 兜底：尝试后仍过近 → 原样生成不静默丢弃；无有效点位 → 原随机路径
	if resolved_any:
		return _clamp_to_ground(last_resolved)
	return _get_random_spawn_position()

## LD-B：点位类型解析——edge（direction 8 向映射竞技场边缘/角落 + inset 内缩，
## 仿 F-44 _clamp_to_arena 边界语义）/ anchor（x/y 比例 × 竞技场尺寸）/
## ring（center + radius 圆周均分，按已生成数取角）。
func _resolve_point(cfg: Dictionary) -> Vector2:
	var ptype := str(cfg.get("type", "edge"))
	var arena := _get_arena_rect()
	if ptype == "anchor":
		return Vector2(
			arena.position.x + float(cfg.get("x", 0.5)) * arena.size.x,
			arena.position.y + float(cfg.get("y", 0.5)) * arena.size.y
		)
	if ptype == "ring":
		var radius := float(cfg.get("radius", 300.0))
		var angle := float(_spawn_index % 8) * TAU / 8.0
		return arena.get_center() + Vector2(cos(angle), sin(angle)) * radius
	# edge（缺省）：方向 → 边缘/角落 + inset 内缩
	var dir := str(cfg.get("direction", "north"))
	var inset := float(cfg.get("inset", 40.0))
	var cx: float = arena.position.x + arena.size.x * 0.5
	var cy: float = arena.position.y + arena.size.y * 0.5
	match dir:
		"south":
			return Vector2(cx, arena.end.y - inset)
		"east":
			return Vector2(arena.end.x - inset, cy)
		"west":
			return Vector2(arena.position.x + inset, cy)
		"ne":
			return Vector2(arena.end.x - inset, arena.position.y + inset)
		"nw":
			return Vector2(arena.position.x + inset, arena.position.y + inset)
		"se":
			return Vector2(arena.end.x - inset, arena.end.y - inset)
		"sw":
			return Vector2(arena.position.x + inset, arena.end.y - inset)
		_:
			return Vector2(cx, arena.position.y + inset)  # north 及未知方向

## LD-B：竞技场矩形（world → ground 查询接口；world/ground 缺失 → 默认 1536×864
## 原点对齐——探针环境确定性 + 真实世界零影响）
func _get_arena_rect() -> Rect2:
	if GameManager and GameManager.world and GameManager.world.has_method("get_ground_rect"):
		return GameManager.world.get_ground_rect()
	return Rect2(Vector2.ZERO, Vector2(1536.0, 864.0))

## 钳制到竞技场内（World 缺失时原样返回）
func _clamp_to_ground(pos: Vector2) -> Vector2:
	if GameManager and GameManager.world and GameManager.world.has_method("clamp_to_ground"):
		return GameManager.world.clamp_to_ground(pos)
	return pos

## 获取当前存活敌人数量
func get_alive_count() -> int:
	if not enemies_container:
		return 0
	return enemies_container.get_child_count()

## F2-T5（T-042）：生成是否进行中（wave_manager 显式接口——此前 _spawning_incomplete 用
## get("_is_spawning")/get("spawn_queue") 私有字段动态访问 = 隐性耦合，收口为显式方法）
func is_spawning() -> bool:
	return _is_spawning

## F2-T5（T-042）：待生成队列是否非空（同上）
func has_pending_spawns() -> bool:
	return not spawn_queue.is_empty()
