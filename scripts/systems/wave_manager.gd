## 波次管理器
## 控制波次流程：开始波次 → 计时/杀敌目标 → 波次结束
## 从 DataLoader (data/waves.json) 加载波次配置
extends Node

# ========== 信号 ==========

signal wave_started(wave_number: int)
signal wave_cleared(wave_number: int)
signal wave_timer_tick(time_remaining: float)
signal all_waves_done
signal portal_ready  ## F-49：通关传送门已开启（敌全灭 → 玩家进传送门结算，期间可捡宝箱）

# ========== 导出属性 ==========

@export var default_wave_duration: float = 30.0  ## 默认波次持续时间（秒）

# ========== 内部状态 ==========

var current_wave: int = 0
var is_active: bool = false
var time_remaining: float = 0.0
var kill_count: int = 0
## F-46（用户 2026-08-18 拍板）：本关总生成数（Excel wave 表固定值，start_wave 缓存）——
## HUD 分数制「已击杀/总数」右侧分母；召唤物（mom 产卵）不计入，击杀可能超出 → HUD clamp
var _wave_total: int = 0
## F-49（2026-08-18 用户拍板）：等待进传送门状态——敌全灭后 true（停表 + 不重复开传送门），
## 玩家 enter_portal() 后 false → _end_wave 正常结算
var _portal_await: bool = false
## T-008（F1-散 2026-08-13）：max_waves 兜底参数化（主源 = get_max_waves waves 键推导）
var max_waves: int = 20

# ========== 生命周期 ==========

func _ready() -> void:
	max_waves = DataLoader.get_max_waves()
	if max_waves <= 0:
		max_waves = int(DataLoader.get_stats_combat().get("max_waves", 20))

func _process(delta: float) -> void:
	if not is_active:
		return
	# F-49：传送门阶段停表（敌全灭已开传送门，玩家进传送门才结算；不再续时/倒计时）
	if _portal_await:
		return
	time_remaining -= delta
	wave_timer_tick.emit(time_remaining)
	if time_remaining <= 0.0:
		# F-28（2026-08-08 用户拍板）：Boss 关不因倒计时通关——通关判定 = Boss 击杀
		# （此前倒计时到点强制通关导致「Boss 没死就提示通关」）；普通关保留超时兜底。
		# 防死锁：超时且容器已无任何存活敌人（生成异常）→ 放行通关
		# 08-18 用户反馈修复：普通关超时不再无条件强制通关——通关判定 = 生成完成 + 敌全灭，
		# 玩家没清完怪不得被送进选关界面（wave 1-6 duration 仅 20-35s，超时强制通关导致
		# 「打了一半突然就结束」）；仅生成异常/无存活敌人时超时兜底放行防卡关
		if GameManager != null and GameManager.is_boss_wave:
			if _alive_enemy_count() > 0:
				time_remaining = 5.0  # 续时继续等 Boss 击杀
				return
			_end_wave()
			return
		# 普通关：生成未完成或仍有存活敌人 → 续时等待（不强制通关）
		if _spawning_incomplete() or _alive_enemy_count() > 0:
			time_remaining = 5.0
			return
		_end_wave()

# ========== 波次控制 ==========

## 开始指定波次
func start_wave(wave_number: int) -> void:
	current_wave = wave_number
	is_active = true
	kill_count = 0

	var config := load_wave_config(wave_number)
	time_remaining = config.get("duration", default_wave_duration)
	# F-49：新波次复位传送门状态（上一关未进传送门残留清理由 world.spawn_exit_portal 负责）
	_portal_await = false
	# F-47（2026-08-18 用户反馈「打完 32 还出新怪」）：本关总生成数 = composition 合计 ×
	# swarm 倍率——与 spawner.spawn_wave 同口径（swarm_wave 翻倍），HUD 分母永远 = 实际生成数。
	# （Excel total_enemies 手填曾未翻倍：wave5 32 vs 实际 60 → 打完表定数还分批出新怪）
	var _total_calc: int = 0
	var _special: Variant = config.get("special", null)
	for entry in config.get("composition", []):
		var c: int = int(entry.get("count", 0))
		_total_calc += c * (2 if _special == "swarm_wave" else 1)
	_wave_total = _total_calc

	wave_started.emit(wave_number)

	# 通知生成器生成敌人
	if GameManager.enemy_spawner:
		GameManager.enemy_spawner.spawn_wave(config, wave_number)

## F-28（2026-08-08 用户拍板）+ F-49（2026-08-18 用户拍板「通关不突兀」）：
## 通关判定——敌人击杀时由 enemy.die() 调用。
## 普通关：容器内所有敌人死亡（is_alive==false）→ 开传送门（不再立即结算）
## Boss 关：Boss 死亡 → 开传送门（不等 Boss 召唤物/精英——此前「Boss 死了还要缠斗
## 精英一会儿才通」）；**玩家走进传送门（enter_portal）才 _end_wave 正常结算进选关，
## 期间可捡地图上的宝箱**（F-49：通关后不立即结算 = 宝箱收获窗口）
func check_wave_clear() -> void:
	if not is_active:
		return
	if GameManager == null:
		return
	if _portal_await:
		return  # F-49：传送门已开，等待玩家进入（重复击杀回调忽略）
	if GameManager.is_boss_wave:
		var container := _enemy_container()
		if container == null:
			return
		for enemy in container.get_children():
			if is_instance_valid(enemy) and enemy.get("is_boss") == true and enemy.get("is_alive") != false:
				return  # 仍有存活 Boss → 未通关
		_open_exit_portal()
		return
	# 普通关：生成完成 + 敌全灭才通关（F-30，2026-08-08 真人反馈）
	# 「第一关只有 1 个怪就通关」= 敌全灭判定没检查生成队列——wave 1 有 12 敌分批生成，
	# 玩家杀掉已生成的 1 个时其余 11 个还在 spawn_queue 未出 → 误判敌全灭
	if _spawning_incomplete():
		return
	if _alive_enemy_count() == 0:
		_open_exit_portal()

## F-49（2026-08-18 用户拍板）：敌全灭/Boss 击杀 → 不立即结算——地图中心开传送门
## + 宝箱（world.spawn_exit_portal），玩家进入传送门（enter_portal）才 _end_wave；
## 传送门阶段停表（玩家随时可进，宝箱可先捡）。探针白盒直调。
func _open_exit_portal() -> void:
	if _portal_await:
		return
	_portal_await = true
	time_remaining = 0.0
	wave_timer_tick.emit(0.0)  # HUD 倒计时归零提示
	portal_ready.emit()
	if GameManager and GameManager.world and GameManager.world.has_method("spawn_exit_portal"):
		GameManager.world.call("spawn_exit_portal")

## F-49：玩家进入传送门 → 正常结算（_end_wave 原链路：回血/清残敌/进选关）
func enter_portal() -> void:
	if not is_active or not _portal_await:
		return
	_portal_await = false
	_end_wave()

## F-30：生成是否未完成（spawn_queue 非空或生成中）——敌全灭判定必须等全部敌人生成完
## F2-T5（T-042）：改走 spawner 显式接口（is_spawning/has_pending_spawns），
## 消灭 get("_is_spawning")/get("spawn_queue") 私有字段动态访问的隐性耦合
func _spawning_incomplete() -> bool:
	if GameManager == null or GameManager.enemy_spawner == null:
		return false
	var spawner: Node = GameManager.enemy_spawner
	if spawner.has_method("is_spawning") and spawner.is_spawning():
		return true
	if spawner.has_method("has_pending_spawns") and spawner.has_pending_spawns():
		return true
	return false

## 敌人容器获取（enemy_spawner.enemies_container 优先，GameManager.enemies_container 兜底）
func _enemy_container() -> Node:
	if GameManager == null:
		return null
	if GameManager.enemy_spawner != null:
		var c: Variant = GameManager.enemy_spawner.get("enemies_container")
		if c != null:
			return c
	if GameManager.enemies_container != null:
		return GameManager.enemies_container
	return null

## 容器内存活敌人数（is_alive != false 为存活）
func _alive_enemy_count() -> int:
	var container := _enemy_container()
	if container == null:
		return 0
	var alive: int = 0
	for enemy in container.get_children():
		if is_instance_valid(enemy) and enemy.get("is_alive") != false:
			alive += 1
	return alive

## 结束当前波次
func _end_wave() -> void:
	is_active = false
	wave_cleared.emit(current_wave)
	if current_wave >= max_waves:
		all_waves_done.emit()
	if GameManager:
		GameManager.on_wave_cleared()

## 从 DataLoader 加载波次配置
## 返回 { wave, duration, total_enemies, composition, special, special_note }
func load_wave_config(wave: int) -> Dictionary:
	var config := DataLoader.get_wave(wave)
	if config.is_empty():
		return _generate_default_wave(wave)
	return config

## 动态生成默认配置（当 DataLoader 无数据时使用）
func _generate_default_wave(wave: int) -> Dictionary:
	var enemy_count := 5 + wave * 3
	return {
		"wave": wave,
		"duration": default_wave_duration,
		"total_enemies": enemy_count,
		"composition": [
			{ "enemy": "chaser", "count": enemy_count }
		],
		"special": null,
	}

## 记录击杀（供外部调用）
func register_kill() -> void:
	kill_count += 1

## F-46：本关总生成数（HUD 分数制分母；未开始波次 → 0）
func get_wave_total() -> int:
	return _wave_total

## F-46：当前击杀数（HUD 分数制分子；Boss 召唤物击杀也计入 → HUD clamp）
func get_kill_count() -> int:
	return kill_count
