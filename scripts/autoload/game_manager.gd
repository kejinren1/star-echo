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

# ========== 枚举 ==========

enum GameState {
	MENU,       ## 主菜单
	BATTLE,     ## 战斗中
	SHOP,       ## 商店选购
	GAME_OVER,  ## 游戏结束（胜利或失败）
}

# ========== 属性 ==========

var current_state: GameState = GameState.MENU
var current_wave: int = 0          ## 当前波次 (从 1 开始)
var max_waves: int = 20            ## 总波次数 (启动时从 DataLoader 加载)
var is_boss_wave: bool = false     ## 当前是否为 Boss 波
var current_character_id: String = ""      ## 本局英雄 id（Main._ready 写入，供 Day 3 主动技能系统读取）

# 子系统引用 (由 Main.tscn 在 _ready 中赋值)
var player: Node = null
var wave_manager: Node = null
var enemy_spawner: Node = null
var economy: Node = null
var inventory: Node = null
var vfx_container: Node = null             ## 特效容器节点

# ========== 状态流转方法 ==========

## 开始新游戏
func start_game() -> void:
	current_wave = 0
	# 从 DataLoader 加载总波次数
	max_waves = DataLoader.get_max_waves()
	if max_waves <= 0:
		max_waves = 20
	current_state = GameState.BATTLE
	state_changed.emit(current_state)
	game_started.emit()
	_start_next_wave()

## 开始下一波
func _start_next_wave() -> void:
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
	current_state = GameState.BATTLE
	state_changed.emit(current_state)
	wave_started.emit(current_wave)
	if wave_manager:
		wave_manager.start_wave(current_wave)

## 波次完成，进入商店
func on_wave_cleared() -> void:
	wave_cleared.emit(current_wave)
	if current_wave >= max_waves:
		end_game(true)
		return
	current_state = GameState.SHOP
	state_changed.emit(current_state)
	shop_opened.emit()

## 关闭商店，进入下一波
func close_shop() -> void:
	shop_closed.emit()
	_start_next_wave()

## 结束游戏
func end_game(victory: bool) -> void:
	current_state = GameState.GAME_OVER
	state_changed.emit(current_state)
	game_over.emit(victory)

## 重置游戏状态
func reset() -> void:
	current_state = GameState.MENU
	current_wave = 0
	is_boss_wave = false
	state_changed.emit(current_state)
