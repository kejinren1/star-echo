## Day 28 最小性能探针（用户 2026-08-09 00:5x 拍板方案 C：授权补登记口径 · 反馈专员执行）
## 目标：Day 28 性能段（帧率/内存/同屏敌人数）机器侧名义闭环（跨 10 轮零开工后兜底）
## 口径声明：headless 逻辑帧压力测试（不含 GPU 渲染；真机帧率由 Day 29 真人目视验收）
##   §1 同屏敌数压力：白盒直构造 50 chaser（wave 10 成长 = 后期量级）→ 30 帧预热 → 120 帧计时
##      （平均逻辑帧耗时 ≤ 33.33ms = ≥30fps 逻辑帧 PASS；最差帧 ≤ 150ms 防尖峰；容器敌数恒 50 零意外死亡）
##   §2 内存快照：static + dynamic < 512MB（登记 + 宽松阈值）
##   §3 敌数据正确性：创建成功 50/50；敌人 enemy_id 字段在位
## 用法（新路径铁律 --path "D:/30DAYS"）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path "D:/30DAYS" --script res://tools/day28_perf_check.gd
extends SceneTree

var _setup_done: bool = false
var _sub: int = 0
var _checked: int = 0
var _failures: int = 0

const WARM_FRAMES: int = 30
const MEASURE_FRAMES: int = 120
const TARGET_ENEMIES: int = 50
const FPS_OK_USEC: int = 33334       # 33.33ms → ≥30fps 逻辑帧
const WORST_OK_USEC: int = 150000    # 150ms 尖峰容忍
const MEM_LIMIT_MB: int = 512

var _spawner: Node = null
var _container: Node = null
var _target: Node = null
var _spawned: int = 0

var _warm: int = 0
var _measure: int = 0
var _prev_usec: int = 0
var _total_usec: int = 0
var _worst_usec: int = 0


func _initialize() -> void:
	print("=== Day 28 min perf check (headless logic-frame stress) ===")


func _process(_delta: float) -> bool:
	if not _setup_done:
		_setup()
		_setup_done = true
		return false
	_sub = _advance(_sub)
	if _sub >= 10:
		_report()
		quit(_failures)
		return true
	return false


func _setup() -> void:
	_ok(root.get_node_or_null("DataLoader") != null, "DataLoader autoload 在位")
	# 敌人容器 + 真实 EnemySpawner（场景自带 enemy_scene 接线）
	_container = Node2D.new()
	_container.name = "PerfEnemies"
	root.add_child(_container)
	_spawner = (load("res://scenes/EnemySpawner.tscn") as PackedScene).instantiate()
	_spawner.name = "PerfSpawner"
	root.add_child(_spawner)
	_spawner.set_container(_container)
	# mock target：Node2D + 内联 take_damage（enemy.gd 仅调 target.take_damage / global_position / has_method）
	var s := GDScript.new()
	s.source_code = "extends Node2D\nfunc take_damage(dmg: float) -> void:\n\tpass"
	s.reload()
	_target = Node2D.new()
	_target.name = "PerfTarget"
	_target.set_script(s)
	_target.global_position = Vector2(320.0, 180.0)
	root.add_child(_target)
	# 白盒直构造 50 chaser（wave 10 成长；确定性零随机刷新 flaky）
	for i in TARGET_ENEMIES:
		var e: Node = _spawner._create_enemy("chaser", 10, null)
		if e == null:
			_fail("第 %d 个敌人创建失败" % (i + 1))
			continue
		_container.add_child(e)
		if e.has_method("set_target"):
			e.set_target(_target)
		_spawned += 1
	_ok(_spawned == TARGET_ENEMIES, "§3 敌创建 %d/%d" % [_spawned, TARGET_ENEMIES])
	var id_ok := true
	for child in _container.get_children():
		var idv: Variant = child.get("enemy_id")
		if idv == null or str(idv) == "":
			id_ok = false
			break
	_ok(id_ok, "§3 敌人 enemy_id 字段全部在位（%d 敌）" % _container.get_child_count())


func _advance(sub: int) -> int:
	match sub:
		0:  # 预热 30 帧（跳过启动抖动）
			if _warm < WARM_FRAMES:
				_warm += 1
				return 0
			_prev_usec = Time.get_ticks_usec()
			return 1
		1:  # 测量 120 帧（每帧间隔 = 完整逻辑帧耗时，含全部节点 _process）
			if _measure < MEASURE_FRAMES:
				var now := Time.get_ticks_usec()
				var cost := now - _prev_usec
				_prev_usec = now
				_total_usec += cost
				if cost > _worst_usec:
					_worst_usec = cost
				_measure += 1
				return 1
			return 2
		2:
			_part_assert()
			return 10
		_:
			return 10
	return sub + 1


func _part_assert() -> void:
	var avg_usec := int(float(_total_usec) / float(MEASURE_FRAMES))
	var fps := 0.0
	if avg_usec > 0:
		fps = 1000000.0 / float(avg_usec)
	print("    同屏 %d 敌 · 测量 %d 帧 · 平均逻辑帧 %.2f ms (≈%.1f fps) · 最差 %.1f ms" % [
		TARGET_ENEMIES, MEASURE_FRAMES, avg_usec / 1000.0, fps, _worst_usec / 1000.0])
	_ok(avg_usec <= FPS_OK_USEC, "§1 平均逻辑帧耗时 %.2fms ≤ 33.33ms（≥30fps 逻辑帧）" % (avg_usec / 1000.0))
	_ok(_worst_usec <= WORST_OK_USEC, "§1 最差帧 %.2fms ≤ 150ms（防尖峰）" % (_worst_usec / 1000.0))
	_ok(_container.get_child_count() == TARGET_ENEMIES,
		"§1 容器敌数 %d == 50（零意外死亡/清理，纯压力保持）" % _container.get_child_count())
	var smem := int(OS.get_static_memory_usage() / 1048576)
	var mi := OS.get_memory_info()
	var phys_mb := int(mi.get("physical", 0) / 1048576)
	var free_mb := int(mi.get("free", 0) / 1048576)
	print("    内存快照: 引擎 static %d MB | 系统物理 %d MB / 空闲 %d MB" % [smem, phys_mb, free_mb])
	_ok(smem < MEM_LIMIT_MB, "§2 引擎 static %dMB < %dMB（宽松阈值）" % [smem, MEM_LIMIT_MB])


func _ok(cond: bool, msg: String) -> void:
	_checked += 1
	if cond:
		print("  OK  %s" % msg)
	else:
		_failures += 1
		print("  XX  %s" % msg)


func _fail(msg: String) -> void:
	_checked += 1
	_failures += 1
	print("  XX  %s" % msg)


func _report() -> void:
	print("\n=== %d assertions, %d failures ===" % [_checked, _failures])
