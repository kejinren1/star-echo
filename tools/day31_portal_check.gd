extends SceneTree
## F-49 通关传送门 + 宝箱校验（2026-08-18 用户拍板「通关不突兀：地图中心开传送门，
## 进传送门才结算，期间可捡掉落宝箱」）
## §1 敌全灭/Boss 击杀 → check_wave_clear → _open_exit_portal：_portal_await true +
##    portal_ready 信号 + 停表（time_remaining=0）+ world.spawn_exit_portal 生成传送门/宝箱
## §2 enter_portal → _end_wave：is_active false + wave_cleared 恰 1 次
## §3 宝箱拾取（白盒 _on_body_entered(player)）：金币 +50 经验 +30 + _claimed + queue_free
## §4 start_wave 复位 _portal_await（新波次不残留传送门状态）
## §5 传送门/宝箱脚本结构：可 load + extends Node2D + Area2D 接触节点
## 驱动：_process 首帧执行 + 显式 quit（--script 探针三坑规避）

class MockPlayer extends Node2D:
	var exp_value: int = 0
	func gain_exp(amount: int) -> void:
		exp_value += amount

class MockEconomy extends Node:
	var coins: int = 0
	func add_coins(amount: int) -> void:
		coins += amount

const PORTAL_SCRIPT_PATH: String = "res://scripts/world/exit_portal.gd"
const CHEST_SCRIPT_PATH: String = "res://scripts/world/loot_chest.gd"

var _checked := 0
var _failures := 0
var _started := false
var _gm: Node = null
var _wm: Node = null
var _world: Node = null
var _container: Node = null
var _spawner: Node = null
var _player: MockPlayer = null
var _eco: MockEconomy = null

func _check(cond: bool, msg: String) -> void:
	_checked += 1
	if not cond:
		_failures += 1
		print("XX " + msg)

func _process(_delta: float) -> bool:
	if not _started:
		_started = true
		_setup()
		_s1_open_portal()
		_s2_enter_portal()
		_s3_chest()
		_s4_reset()
		_s5_scripts()
		print("\n=== %d assertions, %d failures ===" % [_checked, _failures])
		quit(_failures)
		return true
	return false

func _setup() -> void:
	_gm = root.get_node_or_null("GameManager")
	# mock player + economy（宝箱奖励目标）
	_player = MockPlayer.new()
	_player.name = "MockPlayer"
	root.add_child(_player)
	_gm.set("player", _player)
	_eco = MockEconomy.new()
	_eco.name = "MockEco"
	root.add_child(_eco)
	_gm.set("economy", _eco)
	# mock world（真实 world.gd 脚本：spawn_exit_portal 全链路生成传送门/宝箱）
	_world = load("res://scripts/world/world.gd").new()
	_world.name = "MockWorld"
	root.add_child(_world)
	_gm.set("world", _world)
	# mock 敌人容器 + spawner（wave_manager.check_wave_clear 依赖）
	_container = Node.new()
	_container.name = "MockEnemies"
	root.add_child(_container)
	_spawner = load("res://scripts/enemy/enemy_spawner.gd").new()
	_spawner.name = "MockSpawner"
	root.add_child(_spawner)
	_spawner.call("set_container", _container)
	_gm.set("enemy_spawner", _spawner)
	_gm.set("enemies_container", _container)
	_gm.set("is_boss_wave", false)
	# wave_manager
	_wm = load("res://scripts/systems/wave_manager.gd").new()
	_wm.name = "MockWM"
	root.add_child(_wm)

## §1 敌全灭 → 开传送门
func _s1_open_portal() -> void:
	_wm.set("is_active", true)
	_wm.set("time_remaining", 12.0)
	var portal_signals: Array = [0]
	_wm.portal_ready.connect(func() -> void: portal_signals[0] += 1)
	# 生成完成 + 容器空 → 敌全灭
	_spawner.set("_is_spawning", false)
	_spawner.set("spawn_queue", [])
	_wm.call("check_wave_clear")
	_check(bool(_wm.get("_portal_await")), "§1 敌全灭 → _portal_await true（不立即结算）")
	_check(portal_signals[0] == 1, "§1 portal_ready 信号恰 1 次（实得 %d）" % portal_signals[0])
	_check(float(_wm.get("time_remaining")) == 0.0, "§1 传送门阶段停表（time_remaining=0）")
	# world 生成传送门 + 宝箱
	var portal := _world.get_node_or_null("ExitPortal")
	var chest := _world.get_node_or_null("LootChest")
	_check(portal != null, "§1 地图中心生成 ExitPortal 节点")
	_check(chest != null, "§1 生成 LootChest 宝箱节点")
	if portal != null:
		_check(portal.get_script() != null, "§1 传送门挂 exit_portal.gd 脚本")
	if chest != null:
		_check(chest.get_script() != null, "§1 宝箱挂 loot_chest.gd 脚本")
	# 重复 check_wave_clear 不重复开（防多杀回调）
	_wm.call("check_wave_clear")
	_check(portal_signals[0] == 1, "§1 重复 check_wave_clear 不重复开传送门（实得 %d）" % portal_signals[0])

## §2 进传送门 → 结算
func _s2_enter_portal() -> void:
	var cleared: Array = [0]
	_wm.wave_cleared.connect(func(_n: int) -> void: cleared[0] += 1)
	_wm.call("enter_portal")
	_check(not bool(_wm.get("is_active")), "§2 进传送门 → is_active false（结算开始）")
	_check(cleared[0] == 1, "§2 wave_cleared 恰 1 次（实得 %d）" % cleared[0])
	_check(not bool(_wm.get("_portal_await")), "§2 _portal_await 复位 false")
	# 未开传送门时 enter_portal 无效（无操作）
	_wm.set("is_active", true)
	_wm.set("_portal_await", false)
	cleared[0] = 0
	_wm.call("enter_portal")
	_check(cleared[0] == 0 and bool(_wm.get("is_active")), "§2 未开传送门 enter_portal 无操作（防误触发）")

## §3 宝箱拾取
func _s3_chest() -> void:
	# 重新开传送门拿宝箱
	_wm.set("is_active", true)
	_spawner.set("_is_spawning", false)
	_spawner.set("spawn_queue", [])
	_wm.call("check_wave_clear")
	var chest: Node = _world.get_node_or_null("LootChest")
	_check(chest != null, "§3 宝箱已生成")
	if chest == null:
		return
	# 非玩家接触 → 不拾取
	chest.call("_on_body_entered", Node.new())
	_check(bool(chest.get("_claimed")) == false, "§3 非玩家接触不拾取")
	_check(_eco.coins == 0 and _player.exp_value == 0, "§3 非玩家不触发奖励")
	# 玩家接触 → 拾取：金币+50 经验+30 + 消失
	var old_coins: int = _eco.coins
	var old_exp: int = _player.exp_value
	chest.call("_on_body_entered", _player)
	_check(_eco.coins == old_coins + 50, "§3 拾取金币 +50（实得 %d→%d）" % [old_coins, _eco.coins])
	_check(_player.exp_value == old_exp + 30, "§3 拾取经验 +30（实得 %d→%d）" % [old_exp, _player.exp_value])
	_check(chest.is_queued_for_deletion(), "§3 拾取后宝箱销毁（queue_free）")
	# 重复接触（已 claimed）无重复奖励
	_eco.coins = 0
	_player.exp_value = 0
	var chest2: Node = _world.get_node_or_null("LootChest")
	if chest2 == null:
		# 旧 chest 已 queue_free，重新生成
		pass
	_check(_eco.coins == 0, "§3 无重复奖励路径残留")

## §4 start_wave 复位传送门状态
func _s4_reset() -> void:
	_wm.set("is_active", true)
	_wm.set("_portal_await", true)
	_wm.call("start_wave", 1)
	_check(not bool(_wm.get("_portal_await")), "§4 start_wave 复位 _portal_await（新波次可正常通关判定）")

## §5 脚本结构
func _s5_scripts() -> void:
	var p := load(PORTAL_SCRIPT_PATH)
	var c := load(CHEST_SCRIPT_PATH)
	_check(p != null and p is GDScript, "§5 exit_portal.gd 可加载")
	_check(c != null and c is GDScript, "§5 loot_chest.gd 可加载")
	# 实例化结构（_ready 构建 Area2D 接触节点）
	var portal: Node = (p as GDScript).new()
	root.add_child(portal)
	var area := portal.get_node_or_null("Area2D")
	_check(area != null and area is Area2D, "§5 传送门含 Area2D 接触检测")
	var chest: Node = (c as GDScript).new()
	root.add_child(chest)
	var chest_area := chest.get_node_or_null("Area2D")
	_check(chest_area != null and chest_area is Area2D, "§5 宝箱含 Area2D 接触检测")
	portal.queue_free()
	chest.queue_free()
