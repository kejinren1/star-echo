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

# ========== 生命周期 ==========

func _ready() -> void:
	# 绑定子系统引用到 GameManager
	GameManager.player = player
	GameManager.enemy_spawner = enemy_spawner
	GameManager.wave_manager = wave_manager
	GameManager.economy = economy
	GameManager.inventory = inventory
	GameManager.vfx_container = vfx_container

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

# ========== 信号处理 ==========

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
