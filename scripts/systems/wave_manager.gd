## 波次管理器
## 控制波次流程：开始波次 → 计时/杀敌目标 → 波次结束
## 从 DataLoader (data/waves.json) 加载波次配置
extends Node

# ========== 信号 ==========

signal wave_started(wave_number: int)
signal wave_cleared(wave_number: int)
signal wave_timer_tick(time_remaining: float)
signal all_waves_done

# ========== 导出属性 ==========

@export var default_wave_duration: float = 30.0  ## 默认波次持续时间（秒）

# ========== 内部状态 ==========

var current_wave: int = 0
var is_active: bool = false
var time_remaining: float = 0.0
var kill_count: int = 0
var max_waves: int = 20

# ========== 生命周期 ==========

func _ready() -> void:
	max_waves = DataLoader.get_max_waves()
	if max_waves <= 0:
		max_waves = 20

func _process(delta: float) -> void:
	if not is_active:
		return
	time_remaining -= delta
	wave_timer_tick.emit(time_remaining)
	if time_remaining <= 0.0:
		_end_wave()

# ========== 波次控制 ==========

## 开始指定波次
func start_wave(wave_number: int) -> void:
	current_wave = wave_number
	is_active = true
	kill_count = 0

	var config := load_wave_config(wave_number)
	time_remaining = config.get("duration", default_wave_duration)

	wave_started.emit(wave_number)

	# 通知生成器生成敌人
	if GameManager.enemy_spawner:
		GameManager.enemy_spawner.spawn_wave(config, wave_number)

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
