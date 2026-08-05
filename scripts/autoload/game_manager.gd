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

# UI 面板实例引用（防止连升多级/重复弹窗叠加）
var _level_up_panel: Node = null
var _game_over_panel: Node = null

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
	# D4-T8（BUG-001-F2）：先清残敌、后发奖，避免商店期间残敌继续攻击玩家
	_clear_remaining_enemies()
	wave_cleared.emit(current_wave)
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

## 关闭商店，进入下一波
func close_shop() -> void:
	shop_closed.emit()
	_start_next_wave()

## 结束游戏
func end_game(victory: bool) -> void:
	current_state = GameState.GAME_OVER
	state_changed.emit(current_state)
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
	_level_up_panel = null
	_game_over_panel = null
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
	_level_up_panel.tree_exited.connect(func() -> void: _level_up_panel = null)
	_add_to_ui_layer(_level_up_panel)
	if _level_up_panel.has_method("setup"):
		_level_up_panel.setup()

## D4-T7（BUG-001-F1）：死亡/胜利结果面板
func _spawn_game_over_panel(victory: bool) -> void:
	if _game_over_panel != null and is_instance_valid(_game_over_panel):
		return
	var reason: String = "你在波次 %d 阵亡了" % current_wave if not victory else "你击败了星骸的异变！"
	_game_over_panel = GameOverPanelScene.instantiate()
	_game_over_panel.tree_exited.connect(func() -> void: _game_over_panel = null)
	# 先入树再 setup（@onready 节点引用须在 _ready 之后才可用）
	_add_to_ui_layer(_game_over_panel)
	if _game_over_panel.has_method("setup"):
		_game_over_panel.setup(victory, reason)

## 面板统一挂到 UI 层：优先当前场景（Main），无 current_scene（无头测试直接 add 到 root）时挂 root
func _add_to_ui_layer(panel: Node) -> void:
	var target: Node = get_tree().current_scene if get_tree().current_scene else get_tree().root
	target.add_child(panel)
