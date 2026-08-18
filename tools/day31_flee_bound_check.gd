extends SceneTree
## F-44 逃逸与边界校验（总指挥 2026-08-18 · 用户拍板「常规绝不逃离主角 + 不出地图 + 出界即死」）
## §1 ranged 怪不逃离：velocity 方向断言——近/中/远三距离点均无「远离玩家」分量
##   （原逻辑 dist<200 反向后退 = 纯逃离；新逻辑横向绕圈/靠近 = 距离不增）
## §2 边界钳制：界外钳回界内、界内零位移、grow 内夹回界边、不误杀
## §3 出界即死：rect.grow(64) 外 → die（is_alive false + health 归零）；四边全验；grow 内不误杀
## §4 常规不误杀：界内 chase/贴边/ranged 均存活
## §5 Aggro Leash（F-46 · 2026-08-18 用户拍板）：超战斗半径(420px)强制直追——
##   ranged 超距也直追不绕圈；界内 ranged 保持收敛环绕；chase 超距直追
## 环境：--script 物理不步进（move_and_slide 无效果，实测验证）→ 全部白盒测逻辑层；
##       无 Ground → 注入 _arena_rect 缓存（探针自包含）
## 驱动范式：_process 首帧执行（Autoload 挂载后 root 可见）+ 显式 quit（--script 探针三坑规避）

const EnemyEnums: GDScript = preload("res://scripts/enemy/enemy_enums.gd")

const ARENA: Rect2 = Rect2(0.0, 0.0, 1536.0, 864.0)
const FRAME: float = 0.016

var _checked := 0
var _failures := 0
var _started := false

func _check(cond: bool, msg: String) -> void:
	_checked += 1
	if not cond:
		_failures += 1
		print("XX " + msg)

func _process(_delta: float) -> bool:
	if _started:
		return false
	_started = true
	_s1_ranged_no_flee()
	_s2_bound_clamp()
	_s3_out_of_bounds_die()
	_s4_no_false_kill()
	_s5_leash()
	print("\n=== %d assertions, %d failures ===" % [_checked, _failures])
	quit(_failures)
	return true

## 构造敌人：instantiate + initialize + set_target + 入树 + 注入竞技场
func _spawn_enemy(behavior_val: int, pos: Vector2, target: Node2D) -> Node:
	var scene: PackedScene = load("res://scenes/Enemy.tscn")
	var e: Node = scene.instantiate()
	e.call("initialize", {"id": "chaser", "category": "regular", "max_health": 100.0,
		"move_speed": 120.0, "damage": 10.0, "wave_number": 1})
	e.set("behavior", behavior_val)
	e.set("_arena_rect", ARENA)
	if target != null:
		e.call("set_target", target)
	root.add_child(e)
	e.global_position = pos
	return e

func _mk_target(pos: Vector2) -> Node2D:
	var t := Node2D.new()
	t.position = pos
	root.add_child(t)
	return t

# ========== §1 ranged 不逃离（velocity 方向语义，物理无关） ==========

func _s1_ranged_no_flee() -> void:
	var t := _mk_target(Vector2(500, 400))
	var e := _spawn_enemy(int(EnemyEnums.Behavior.RANGED), Vector2(400, 400), t)
	var mv: Node = e.get("_movement")
	# 三距离点：100（原「太近后退」区）/ 250（横向绕圈区）/ 400（太远靠近区）
	for dist_val in [100.0, 250.0, 400.0]:
		var pos: Vector2 = Vector2(500 - dist_val, 400)
		e.global_position = pos
		mv.call("_move_ranged", FRAME)
		var vel: Vector2 = e.velocity
		var dir_to_target: Vector2 = pos.direction_to(t.global_position)
		var away: Vector2 = -dir_to_target  # 远离玩家的方向
		var away_component: float = vel.dot(away)
		_check(away_component <= 0.5, "§1 dist=%d 无远离分量（away=%.2f，原后退=-%.0f）" \
			% [int(dist_val), away_component, e.get("move_speed")])
	# 中距横向绕圈 ≠ 静止（怪仍在活动）
	e.global_position = Vector2(250, 400)
	mv.call("_move_ranged", FRAME)
	_check(e.velocity.length() > 0.0, "§1 中距横向绕圈非静止")
	_check(bool(e.get("is_alive")), "§1 ranged 怪存活")
	e.queue_free()
	t.queue_free()

# ========== §2 边界钳制 ==========

func _s2_bound_clamp() -> void:
	var t := _mk_target(Vector2(500, 400))
	var e := _spawn_enemy(int(EnemyEnums.Behavior.CHASE), Vector2(-100, -100), t)
	e.call("_clamp_to_arena")
	var p: Vector2 = e.global_position
	_check(p.x >= ARENA.position.x - 0.5 and p.x <= ARENA.end.x + 0.5, "§2 钳制 x 在界内: %f" % p.x)
	_check(p.y >= ARENA.position.y - 0.5 and p.y <= ARENA.end.y + 0.5, "§2 钳制 y 在界内: %f" % p.y)
	# 界内钳制零位移
	e.global_position = Vector2(400, 400)
	e.call("_clamp_to_arena")
	_check(e.global_position == Vector2(400, 400), "§2 界内钳制零位移")
	# grow 内（rect 外 30px）夹回界边
	e.global_position = Vector2(-30, 400)
	e.call("_clamp_to_arena")
	_check(e.global_position.x == 0.0, "§2 grow 内夹回界边: %f" % e.global_position.x)
	_check(bool(e.get("is_alive")), "§2 钳制不误杀")
	e.queue_free()
	t.queue_free()

# ========== §3 出界即死 ==========

func _s3_out_of_bounds_die() -> void:
	var t := _mk_target(Vector2(500, 400))
	# 左出界（grow64 外）
	var e1 := _spawn_enemy(int(EnemyEnums.Behavior.CHASE), Vector2(-200, 400), t)
	e1.call("_check_out_of_bounds_die")
	_check(not bool(e1.get("is_alive")), "§3 左出界（grow64 外）即死")
	_check(float(e1.get("health")) == 0.0, "§3 出界即死 health 归零")
	# 右/上/下出界全验
	var edges := [Vector2(ARENA.end.x + 100, 400), Vector2(400, -100), Vector2(400, ARENA.end.y + 100)]
	var all_dead: bool = true
	for ep in edges:
		var e3 := _spawn_enemy(int(EnemyEnums.Behavior.CHASE), ep, t)
		e3.call("_check_out_of_bounds_die")
		if bool(e3.get("is_alive")):
			all_dead = false
		e3.queue_free()
	_check(all_dead, "§3 右/上/下出界均即死")
	# grow 内（rect 外 30px）不误杀
	var e2 := _spawn_enemy(int(EnemyEnums.Behavior.CHASE), Vector2(-30, 400), t)
	e2.call("_check_out_of_bounds_die")
	_check(bool(e2.get("is_alive")), "§3 grow 内不误杀")
	e1.queue_free()
	e2.queue_free()
	t.queue_free()

# ========== §5 Aggro Leash（F-46 · 2026-08-18 用户拍板） ==========

## 所有行为统一：与玩家距离 > LEASH_RADIUS(420) → 强制直追（velocity ≈ 指向玩家）。
## 根治「怪漂出屏幕找不到 → 普通关永不判通死锁」（竞技场 1536×864 比屏幕大 2.4 倍，
## 场内远端不可见不可打——F-44 只兜了出界，F-46 补战斗锁链）。
func _s5_leash() -> void:
	var t := _mk_target(Vector2(900, 400))  # 玩家在远端
	# a. ranged 超距（dist=600 > 420）→ 强制直追不绕圈
	var e := _spawn_enemy(int(EnemyEnums.Behavior.RANGED), Vector2(300, 400), t)
	var mv: Node = e.get("_movement")
	e.global_position = Vector2(300, 400)
	mv.call("_update_behavior", FRAME)
	var dir_to_target: Vector2 = Vector2(300, 400).direction_to(t.global_position)
	var toward: float = e.velocity.normalized().dot(dir_to_target)
	_check(toward > 0.9, "§5 超距 ranged 强制直追（toward=%.2f）" % toward)
	# b. 界内 ranged（dist=100 < 420）→ 正常行为分派 = 收敛环绕（非直追）
	e.global_position = Vector2(800, 400)
	mv.call("_update_behavior", FRAME)
	var toward2: float = e.velocity.normalized().dot(Vector2(800, 400).direction_to(t.global_position))
	_check(toward2 < 0.9 and toward2 > 0.1, "§5 界内 ranged 收敛环绕（toward=%.2f，非直追非逃离）" % toward2)
	_check(bool(e.get("is_alive")), "§5 leash 不误杀")
	# c. chase 超距同样直追
	var e2 := _spawn_enemy(int(EnemyEnums.Behavior.CHASE), Vector2(300, 400), t)
	var mv2: Node = e2.get("_movement")
	e2.global_position = Vector2(300, 400)
	mv2.call("_update_behavior", FRAME)
	var toward3: float = e2.velocity.normalized().dot(Vector2(300, 400).direction_to(t.global_position))
	_check(toward3 > 0.9, "§5 超距 chase 直追（toward=%.2f）" % toward3)
	e.queue_free()
	e2.queue_free()
	t.queue_free()

# ========== §4 常规不误杀 ==========

func _s4_no_false_kill() -> void:
	var t := _mk_target(Vector2(500, 400))
	var e1 := _spawn_enemy(int(EnemyEnums.Behavior.CHASE), Vector2(400, 400), t)
	e1.call("_check_out_of_bounds_die")
	_check(bool(e1.get("is_alive")), "§4 界内 chase 不误杀")
	e1.call("_clamp_to_arena")
	_check(e1.global_position == Vector2(400, 400), "§4 界内 chase 钳制零位移")
	# 贴右边缘内 5px
	var e2 := _spawn_enemy(int(EnemyEnums.Behavior.CHASE), Vector2(ARENA.end.x - 5.0, 400), t)
	e2.call("_check_out_of_bounds_die")
	_check(bool(e2.get("is_alive")), "§4 贴边怪存活")
	# 界内 ranged 不误杀
	var e3 := _spawn_enemy(int(EnemyEnums.Behavior.RANGED), Vector2(300, 300), t)
	e3.call("_check_out_of_bounds_die")
	_check(bool(e3.get("is_alive")), "§4 界内 ranged 存活")
	e1.queue_free()
	e2.queue_free()
	e3.queue_free()
	t.queue_free()
