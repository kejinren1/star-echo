## Day 30 · F2 代码边界收拢探针（EXIT · 方案 §1 验收）
##
## 用法（无头）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day30_f2_boundary_check.gd
##
## 四段（≥18 断言）：
##   §1 静态 grep：get_parent().get_node_or_null 零残留 / world.gd 工厂三入口（含 instantiate
##      主路径）/ shop·hud·base_station 无 economy.coins·inventory.get("weapons")·meta_progress.get
##      直读 / current_state = 仅 _transition 内 / 原 5 处直接 instantiate 已收口为兜底路径
##   §2 行为：_transition 同值早退 + 状态变化 emit 值/次数 / can_afford·get_coins 边界 /
##      inventory get_weapons 浅拷贝 + remove_last_weapon / get_research_points·get_research_level /
##      player.get_weapon_controller
##   §3 容器/工厂：world.get_container("projectiles") 真实节点（_ready 预创建）/
##      spawn_projectile 挂 Projectiles + initialize 透传 / spawn_turret 挂 World / spawn_minion 挂 Enemies
##   §4 信号链：enemy died → wave_manager.check_wave_clear 通关判定（die 内调用点保留）/
##      boss_killed → GM.register_boss_killed（route.flags.boss_defeated 登记）/ spawner 显式接口
##
## 退出码 0 = 全部通过；非 0 = 失败项数。
extends SceneTree

const WORLD_SCRIPT: String = "res://scripts/world/world.gd"
const PROJECTILE_SCENE: String = "res://scenes/Projectile.tscn"
const TURRET_SCENE: String = "res://scenes/Turret.tscn"
const ENEMY_SCENE: String = "res://scenes/Enemy.tscn"
const SPAWNER_SCRIPT: String = "res://scripts/enemy/enemy_spawner.gd"
const WAVE_MANAGER_SCRIPT: String = "res://scripts/systems/wave_manager.gd"
## --script 模式 autoload 标识符编译期不可见（已知坑）：Weapon 用 preload 脚本引用，
## DataLoader 用运行期 root.get_node_or_null 获取
const WeaponScript: GDScript = preload("res://scripts/weapons/weapon.gd")

var _checked: int = 0
var _failures: int = 0
var _gm: Node = null
var _loader: Node = null

func _ok(cond: bool, msg: String) -> void:
	_checked += 1
	if cond:
		print("  PASS  %s" % msg)
	else:
		_failures += 1
		print("  FAIL  %s" % msg)

func _fail(msg: String) -> void:
	_checked += 1
	_failures += 1
	print("  FAIL  %s" % msg)

func _report() -> void:
	print("=== DAY30-F2-BOUNDARY CHECK: %d assertions, %d failures ===" % [_checked, _failures])
	print("DAY30-F2-BOUNDARY CHECK %s" % ("CLEAN" if _failures == 0 else "FAILED"))
	quit(_failures)

# ========== §1 静态 grep ==========

func _static_grep() -> void:
	print("-- §1 静态 grep --")
	# a. get_parent().get_node_or_null 全项目零残留（F2 验收：无 get_parent() 跨层链）
	var gp_count: int = 0
	for f in _list_gd_files():
		var lines: Array = _read_file_lines(f)
		for ln in lines:
			if ln.contains("get_parent().get_node_or_null") or ln.contains("get_parent() . get_node_or_null"):
				gp_count += 1
	_ok(gp_count == 0, "§1a: get_parent().get_node_or_null 全项目零残留（实得 %d）" % gp_count)

	# b. world.gd 工厂三入口（CONTAINER_MAP + get_container + spawn_projectile/spawn_turret/spawn_minion）
	var wsrc: String = FileAccess.get_file_as_string(WORLD_SCRIPT)
	_ok(wsrc.contains("CONTAINER_MAP"), "§1b: world.gd 含 CONTAINER_MAP 容器注册表")
	_ok(wsrc.contains("func get_container("), "§1b: world.gd 含 get_container()")
	_ok(wsrc.contains("func spawn_projectile(") and wsrc.contains("func spawn_turret(") and wsrc.contains("func spawn_minion("),
		"§1b: world.gd 含 spawn_projectile/spawn_turret/spawn_minion 工厂三入口")

	# c. shop/hud/base_station 无 economy.coins 字段直读（排除 coins_changed 信号连接子串）
	var ui_files: Array = ["res://scripts/ui/shop.gd", "res://scripts/ui/hud.gd", "res://scripts/ui/base_station.gd"]
	var coins_direct: int = 0
	for f in ui_files:
		for ln in _read_file_lines(f):
			# economy.coins 后跟非下划线字符 = 字段直读；coins_changed 信号连接豁免
			var idx: int = ln.find("economy.coins")
			if idx >= 0:
				var rest: String = ln.substr(idx + len("economy.coins"))
				if not rest.begins_with("_"):
					coins_direct += 1
	_ok(coins_direct == 0, "§1c: shop/hud/base_station 无 economy.coins 字段直读（实得 %d）" % coins_direct)

	# d. UI 层无 inventory.get("weapons") 直读
	var inv_direct: int = 0
	for f in ui_files:
		for ln in _read_file_lines(f):
			if ln.contains('inventory.get("weapons")') or ln.contains("inventory.get('weapons')"):
				inv_direct += 1
	_ok(inv_direct == 0, "§1d: UI 层无 inventory.get(\"weapons\") 直读（实得 %d）" % inv_direct)

	# e. base_station 无 meta_progress.get 直读（查询接口收口）
	var meta_direct: int = 0
	for f in ui_files:
		for ln in _read_file_lines(f):
			if ln.contains("meta_progress.get"):
				meta_direct += 1
	_ok(meta_direct == 0, "§1e: UI 层无 meta_progress.get 直读（实得 %d）" % meta_direct)

	# f. current_state = 赋值仅 _transition 内（GM 文件：注释行豁免）
	#    F3 同步（2026-08-13）：_set_state 升级 _transition，断言口径同步
	var gm_src: String = FileAccess.get_file_as_string("res://scripts/autoload/game_manager.gd")
	var assign_count: int = 0
	for ln in gm_src.split("\n"):
		if ln.contains("current_state = ") and not ln.strip_edges().begins_with("#") and not ln.strip_edges().begins_with("##"):
			assign_count += 1
	_ok(assign_count == 1, "§1f: current_state = 赋值仅 _transition 内 1 处（实得 %d）" % assign_count)

	# g. 原 5 处直接 instantiate 散点已收口：weapon_controller(1)/skill_controller(3)/turret(1)/enemy(1)
	#    均出现在兜底路径（文件含「兜底」注释标记），主路径走 world 工厂（world.gd 3 处 instantiate）
	#    F4-A 同步：enemy 兜底 instantiate 迁 enemy_boss.gd（_spawn_minion_node），enemy.gd 本体零 instantiate
	#    PS-C4 同步（2026-08-16）：skill_controller 剑气爆发兜底路径 +1（fireball/turret/sword_arc）→ sc=3
	var wc_count: int = _count_occ(FileAccess.get_file_as_string("res://scripts/weapons/weapon_controller.gd"), ".instantiate()")
	var sc_count: int = _count_occ(FileAccess.get_file_as_string("res://scripts/player/skill_controller.gd"), ".instantiate()")
	var tt_count: int = _count_occ(FileAccess.get_file_as_string("res://scripts/weapons/turret.gd"), ".instantiate()")
	var en_count: int = _count_occ(FileAccess.get_file_as_string("res://scripts/enemy/enemy.gd"), ".instantiate()") \
		+ _count_occ(FileAccess.get_file_as_string("res://scripts/enemy/enemy_boss.gd"), ".instantiate()")
	var wf_count: int = _count_occ(wsrc, ".instantiate()")
	_ok(wc_count == 1 and sc_count == 3 and tt_count == 1 and en_count == 1,
		"§1g: 实体 instantiate 收口为兜底单点（wc=%d sc=%d tt=%d en=%d）" % [wc_count, sc_count, tt_count, en_count])
	_ok(wf_count == 3, "§1g: world.gd 工厂内 instantiate == 3（实得 %d）" % wf_count)
	_ok(FileAccess.get_file_as_string("res://scripts/weapons/weapon_controller.gd").contains("兜底"),
		"§1g: weapon_controller 含兜底路径注释标记")

# ========== §2 行为 ==========

func _behavior() -> void:
	print("-- §2 行为 --")
	# a. _transition 同值早退：MENU→MENU 不 emit（数组引用捕获——lambda 值捕获不更新
	#    int 局部变量，GDScript 已知特性）
	#    F3 同步（2026-08-13）：_set_state 升级 _transition，调用点同步
	var state_emits: Array = [0]
	_gm.state_changed.connect(func(_s): state_emits[0] += 1)
	_gm.call("_transition", _gm.GameState.MENU)
	_ok(state_emits[0] == 0, "§2a: _transition 同值(MENU→MENU) 早退零 emit（实得 %d）" % state_emits[0])
	# b. MENU→BATTLE emit 1 次 + 值正确
	_gm.call("_transition", _gm.GameState.BATTLE)
	_ok(state_emits[0] == 1 and int(_gm.get("current_state")) == _gm.GameState.BATTLE,
		"§2a: MENU→BATTLE emit 1 次 + current_state==BATTLE（emits=%d）" % state_emits[0])

	# c. can_afford 边界（economy mock：真实 economy.gd 实例）
	var economy: Node = load("res://scripts/systems/economy.gd").new()
	economy.set("coins", 0)
	_ok(economy.call("can_afford", 0) == true and economy.call("can_afford", 1) == false,
		"§2c: can_afford 边界 coins=0 → 0 可付/1 不可付")
	economy.call("add_coins", 50)
	_ok(economy.call("can_afford", 50) == true and economy.call("get_coins") == 50,
		"§2c: add_coins(50) → can_afford(50) true + get_coins==50")

	# d. inventory get_weapons 浅拷贝 + remove_last_weapon（真实 inventory.gd 实例）
	var inv: Node = load("res://scripts/systems/inventory.gd").new()
	var w1: Resource = WeaponScript.new()
	var w2: Resource = WeaponScript.new()
	inv.call("add_weapon", w1)
	inv.call("add_weapon", w2)
	var copy: Array = inv.call("get_weapons")
	copy.clear()
	_ok(int(inv.call("get_weapon_count")) == 2, "§2d: get_weapons 浅拷贝——外部 clear 不影响内部（实得 %d）" % inv.call("get_weapon_count"))
	var removed: bool = inv.call("remove_last_weapon")
	_ok(removed == true and int(inv.call("get_weapon_count")) == 1, "§2d: remove_last_weapon 移除末位（剩 %d）" % inv.call("get_weapon_count"))
	_ok(inv.call("remove_last_weapon") == true and inv.call("remove_last_weapon") == false,
		"§2d: remove_last_weapon 空列表返回 false 不崩")

	# e. GM 查询接口（研究点/等级）
	_gm.set("meta_progress", {"research_points": 3, "research": {"attack": 1, "hp": 0, "luck": 1}})
	_ok(int(_gm.call("get_research_points")) == 3 and int(_gm.call("get_research_level", "attack")) == 1
		and int(_gm.call("get_research_level", "hp")) == 0,
		"§2e: get_research_points==3 / get_research_level attack==1 hp==0")

	# f. player.get_weapon_controller（真实 Player.tscn——player.gd 继承 CharacterBody2D，
	#    Node.new 无法挂载该脚本）
	var player: Node = (load("res://scenes/Player.tscn") as PackedScene).instantiate()
	root.add_child(player)
	_ok(player.call("get_weapon_controller") != null, "§2f: player.get_weapon_controller 返回 WeaponController 节点")
	player.queue_free()

	# g. get_alive_enemy_count（spawner mock + 容器遍历 is_alive 兜底语义）
	var container: Node = Node.new()
	var spawner: Node = load(SPAWNER_SCRIPT).new()
	spawner.set("enemies_container", container)
	_gm.set("enemy_spawner", spawner)
	_gm.set("wave_manager", null)
	_gm.set("enemies_container", container)
	var e1: Node = load(ENEMY_SCENE).instantiate()
	var e2: Node = load(ENEMY_SCENE).instantiate()
	container.add_child(e1)
	container.add_child(e2)
	e1.set("is_alive", false)  # 死亡未销毁 → is_alive 判定排除
	_ok(int(_gm.call("get_alive_enemy_count")) == 1,
		"§2g: get_alive_enemy_count is_alive 语义（1 死 1 活 → 1，实得 %d）" % _gm.call("get_alive_enemy_count"))
	e1.queue_free()
	e2.queue_free()

# ========== §3 容器/工厂 ==========

func _container_factory() -> void:
	print("-- §3 容器/工厂 --")
	var world: Node = (load(WORLD_SCRIPT) as GDScript).new()
	root.add_child(world)  # 触发 _ready → 预创建 Projectiles
	# a. get_container("projectiles") 返回真实节点（_ready 预创建）
	var proj_container: Node = world.call("get_container", "projectiles")
	_ok(proj_container != null and proj_container.name == "Projectiles",
		"§3a: get_container(\"projectiles\") 返回预创建 Projectiles 节点")
	# 未知 key → null
	_ok(world.call("get_container", "not_a_key") == null, "§3a: get_container 未知 key → null")

	# b. spawn_projectile 挂 Projectiles + initialize 透传（先 initialize 后 add_child 时序）
	var proj: Node2D = world.call("spawn_projectile", load(PROJECTILE_SCENE), {"pierce": 7, "speed": 999.0})
	_ok(proj != null and proj.get_parent() == proj_container,
		"§3b: spawn_projectile 弹丸挂 Projectiles 容器下")
	_ok(int(proj.get("pierce")) == 7 and float(proj.get("speed")) == 999.0,
		"§3b: spawn_projectile initialize 透传（pierce=7 speed=999）")
	proj.queue_free()

	# c. spawn_turret 挂 World 自身（方案 §3 验证口径）
	var turret: Node2D = world.call("spawn_turret", load(TURRET_SCENE), {"damage": 9.0}, 5.0, null)
	_ok(turret != null and turret.get_parent() == world,
		"§3c: spawn_turret 挂 World 下（parent==world）")
	_ok(float(turret.get("damage")) == 9.0 and float(turret.get("duration_left")) == 5.0,
		"§3c: spawn_turret setup 透传（damage=9 duration=5）")
	turret.queue_free()

	# d. spawn_minion 挂 Enemies（world 预置 Enemies 容器）
	var enemies_node: Node = Node.new()
	enemies_node.name = "Enemies"
	world.add_child(enemies_node)
	var minion: Node = world.call("spawn_minion", load(ENEMY_SCENE), {"max_health": 66.0})
	_ok(minion != null and minion.get_parent() == enemies_node,
		"§3d: spawn_minion 挂 Enemies 容器下")
	_ok(float(minion.get("max_health")) == 66.0, "§3d: spawn_minion initialize 透传（max_health=66）")
	minion.queue_free()
	enemies_node.queue_free()

	# e. GameManager.get_world 判空（未注入 → null；注入后返回）
	_gm.set("world", null)
	_ok(_gm.call("get_world") == null, "§3e: GM.get_world 未注入 → null")
	_gm.set("world", world)
	_ok(_gm.call("get_world") == world, "§3e: GM.get_world 注入后返回 world 节点")
	_gm.set("world", null)
	world.queue_free()

# ========== §4 信号链 ==========

func _signal_chain() -> void:
	print("-- §4 信号链 --")
	# a. enemy died → wave_manager.check_wave_clear 通关判定（die 内调用点保留；
	#    wave_manager mock：is_active + 无存活 → _end_wave → wave_cleared 信号）
	var wm: Node = load(WAVE_MANAGER_SCRIPT).new()
	_gm.set("wave_manager", wm)
	var cleared: Array = [0]
	wm.wave_cleared.connect(func(_n): cleared[0] += 1)
	wm.call("start_wave", 1)
	_gm.set("route", {})
	_gm.set("is_boss_wave", false)
	var enemies_container: Node = Node.new()
	_gm.set("enemy_spawner", null)
	_gm.set("enemies_container", enemies_container)
	root.add_child(enemies_container)
	var enemy: Node = load(ENEMY_SCENE).instantiate()
	enemies_container.add_child(enemy)
	enemy.call("die")
	_ok(cleared[0] == 1, "§4a: enemy died → check_wave_clear 通关判定（wave_cleared 计数 %d）" % cleared[0])
	enemies_container.queue_free()

	# b. boss_killed 信号 → GM.register_boss_killed（route.flags.boss_defeated 登记）
	_gm.call("reset")
	_gm.set("route", {"flags": {}})
	_gm.set("wave_manager", null)  # 清 §4a 残留（防 die 链误触 check_wave_clear）
	_gm.set("enemies_container", null)
	var inv_stats: Dictionary = _loader.call("get_scaled_enemy", "invoker", 10)
	var boss: Node = load(ENEMY_SCENE).instantiate()
	root.add_child(boss)  # 入树——die() 链内 get_tree() 依赖（未入树会 data.tree null）
	boss.call("initialize", inv_stats)
	boss.boss_killed.connect(_gm.register_boss_killed)
	boss.call("die")
	_ok(int(_gm.get("boss_killed")) == 1, "§4b: boss_killed → GM.register_boss_killed（boss_killed==%d）" % int(_gm.get("boss_killed")))
	var flags: Dictionary = _gm.get("route").get("flags", {})
	_ok(flags.get("boss_defeated", false) == true, "§4b: route.flags.boss_defeated == true")
	boss.queue_free()

	# c. spawner 显式接口（is_spawning/has_pending_spawns；类型化 Array[Dictionary]
	#    队列用 append 填充——直接 set 字面量 Array 会类型不匹配）
	var spawner: Node = load(SPAWNER_SCRIPT).new()
	spawner.set("_is_spawning", true)
	spawner.get("spawn_queue").append({"enemy_id": "chaser"})
	_ok(spawner.call("is_spawning") == true and spawner.call("has_pending_spawns") == true,
		"§4c: spawner.is_spawning/has_pending_spawns 显式接口返回")
	spawner.set("_is_spawning", false)
	spawner.get("spawn_queue").clear()
	_ok(spawner.call("is_spawning") == false and spawner.call("has_pending_spawns") == false,
		"§4c: 空闲态 is_spawning/has_pending_spawns 均 false")

# ========== 工具 ==========

func _list_gd_files() -> Array:
	var out: Array = []
	var dirs: Array = ["res://scripts"]
	for d in dirs:
		var dir: DirAccess = DirAccess.open(d)
		if dir == null:
			continue
		dir.list_dir_begin()
		var f: String = dir.get_next()
		while f != "":
			if not dir.current_is_dir() and f.ends_with(".gd"):
				out.append(d + "/" + f)
			f = dir.get_next()
		# 子目录
		var sub: DirAccess = DirAccess.open(d)
		if sub:
			sub.list_dir_begin()
			var s: String = sub.get_next()
			while s != "":
				if sub.current_is_dir() and not s.begins_with("."):
					var sd: DirAccess = DirAccess.open(d + "/" + s)
					if sd:
						sd.list_dir_begin()
						var sf: String = sd.get_next()
						while sf != "":
							if not sd.current_is_dir() and sf.ends_with(".gd"):
								out.append(d + "/" + s + "/" + sf)
							sf = sd.get_next()
				s = sub.get_next()
	return out

func _read_file_lines(path: String) -> Array:
	var content: String = FileAccess.get_file_as_string(path)
	if content.is_empty():
		return []
	return content.split("\n")

func _count_occ(src: String, needle: String) -> int:
	var n: int = 0
	var idx: int = src.find(needle)
	while idx >= 0:
		n += 1
		idx = src.find(needle, idx + 1)
	return n

# ========== 驱动 ==========

func _initialize() -> void:
	print("=== Day 30 F2 boundary check ===")

func _process(_delta: float) -> bool:
	if _gm == null:
		_gm = root.get_node_or_null("GameManager")
		_loader = root.get_node_or_null("DataLoader")
		if _gm == null or _loader == null:
			_fail("GameManager/DataLoader autoload 缺失")
			_report()
			return true
		_static_grep()
		_behavior()
		_container_factory()
		_signal_chain()
		_report()
		return true
	return false
