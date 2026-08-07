## Day 18-反馈批 3 出口校验（2026-08-07 · H-01 升级体验用户拍板新需求）：
##   升级时「有光效 + 对周围敌人击退 + 造成和普攻差不多的伤害」：
##   ① enemy.gd 新增受击击退（apply_knockback + _process_knockback，每帧衰减 50%）
##   ② player.gd 新增升级冲击波（_trigger_level_impact）：
##      - 光效：复用现成 fx_levelup 6 帧（VfxPlayer 占位特效机制）
##      - 伤害：当前武器 base_damage × damage_multiplier × debug_mult（对齐普攻口径）
##      - 击退：半径 140px 内存活敌人背离玩家推开（force 500）
##
## 用法（无头）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day18_feedback3_check.gd
##
## 退出码 0 = 全部通过；非 0 = 失败项数。
extends SceneTree

const ENEMY_SCENE_PATH: String = "res://scenes/Enemy.tscn"
const WEAPON_CONTROLLER_PATH: String = "res://scripts/weapons/weapon_controller.gd"
const ENEMY_HP: float = 500.0  ## 高血量防连锁死亡（升级冲击打死敌人 → 掉经验 → 重入升级）

var _sub: int = 0
var _ready_mocks: bool = false
var _loader: Node = null
var _gm: Node = null
var _player: Node = null
var _wc: Node = null
var _fx_container: Node = null
var _enemy_container: Node = null
var _checked: int = 0
var _failures: int = 0

func _initialize() -> void:
	print("=== Day 18 feedback3 check (升级冲击波: 光效+击退+普攻级伤害) ===")

func _process(_delta: float) -> bool:
	if not _ready_mocks:
		_load_mocks()
		return false
	if _sub >= 13:
		_report()
		quit(_failures)
		return true
	print("  -- sub %d --" % _sub)
	_sub = _advance(_sub)
	return false

func _load_mocks() -> void:
	_ready_mocks = true
	_loader = root.get_node_or_null("DataLoader")
	_gm = root.get_node_or_null("GameManager")
	if _loader == null or _gm == null:
		_fail("DataLoader/GameManager autoload 缺失")
		_report()
		quit(1)
		return
	# 敌人容器（升级冲击波遍历目标；GameManager.enemies_container）——先建容器再 mock spawner
	_enemy_container = Node2D.new()
	_enemy_container.name = "EnemyContainer"
	root.add_child(_enemy_container)
	_gm.set("enemies_container", _enemy_container)
	# mock spawner（敌人死亡处理 GameManager 走 enemy_spawner；缺失会 NPE）
	var spawner_mock = load("res://scripts/enemy/enemy_spawner.gd").new()
	spawner_mock.name = "MockSpawner"
	spawner_mock.set("enemies_container", _enemy_container)
	_gm.set("enemy_spawner", spawner_mock)
	# mock player（player.gd 脚本：gain_exp/_trigger_level_impact 齐备）
	_player = CharacterBody2D.new()
	_player.name = "MockPlayer"
	_player.set_script(load("res://scripts/player/player.gd"))
	_player.max_health = 100.0
	_player.armor = 0.0
	_player.damage_multiplier = 1.0
	_player.debug_mult = 1.0
	_player.level = 1
	_player.exp = 0.0
	_player.global_position = Vector2(200.0, 200.0)
	root.add_child(_player)
	_player.health = 100.0
	_player._invulnerable_timer = 0.0
	_gm.set("player", _player)
	# mock WeaponController 子节点（_ready 自动装备初始枪 base_damage 8.0 = 普攻基准）
	_wc = load(WEAPON_CONTROLLER_PATH).new()
	_wc.name = "WeaponController"
	_player.add_child(_wc)
	_wc.set_process(false)  # 禁自动开火，纯数据 mock
	# 特效容器（VfxPlayer.spawn 落点；GameManager.vfx_container）
	_fx_container = Node2D.new()
	_fx_container.name = "FxContainer"
	root.add_child(_fx_container)
	_gm.set("vfx_container", _fx_container)

# ========== 断言工具 ==========

func _ok(cond: bool, what: String) -> void:
	_checked += 1
	if not cond:
		_failures += 1
		print("  FAIL: " + what)

func _fail(what: String) -> void:
	_checked += 1
	_failures += 1
	print("  FAIL: " + what)

func _report() -> void:
	print("=== DAY18-FEEDBACK3 CHECK: %d assertions, %d failures ===" % [_checked, _failures])
	if _failures == 0:
		print("DAY18-FEEDBACK3 CHECK CLEAN")

## 白盒构造敌人：instantiate + initialize(stats) + set_target + 入容器（禁引擎物理帧，控时手动）
func _build_enemy(stats: Dictionary) -> Node:
	var scene: PackedScene = load(ENEMY_SCENE_PATH)
	var enemy: Node = scene.instantiate()
	if enemy.has_method("initialize"):
		enemy.initialize(stats)
	if enemy.has_method("set_target"):
		enemy.set_target(_player)
	_enemy_container.add_child(enemy)
	enemy.set_physics_process(false)
	return enemy

## 清空敌人容器（立即销毁防 queue_free 延迟污染跨段断言）
func _clear_enemy_container() -> void:
	for child in _enemy_container.get_children():
		_enemy_container.remove_child(child)
		child.free()

# ========== 主推进（线性子步骤） ==========

func _advance(sub: int) -> int:
	match sub:
		# ---------- §1 击退白盒（enemy.gd） ----------
		0:
			# apply_knockback 写入：方向归一 + 初速
			var e1: Node = _build_enemy({
				"id": "chaser", "category": "regular", "max_health": ENEMY_HP, "damage": 5.0,
				"move_speed": 100.0, "behavior": "chase", "armor": 0,
			})
			e1.global_position = Vector2(300.0, 200.0)
			e1.call("apply_knockback", Vector2(2.0, 0.0), 500.0)
			var kb: Vector2 = e1.get("_knockback")
			_ok(absf(kb.length() - 500.0) < 0.001, "击退/写入: 归一化初速 500（实得 %.1f）" % kb.length())
			_ok(kb.x > 0.0 and absf(kb.y) < 0.001, "击退/写入: 方向背离（x+，y=0）")
			return 1
		1:
			# _process_knockback 推进 1 帧：位移 + 衰减 50%
			var e1: Node = _enemy_container.get_child(0)
			var x0: float = e1.global_position.x
			e1.call("_process_knockback")
			_ok(e1.global_position.x > x0 + 1.0, "击退/推进: 敌人被推开（x %.1f → %.1f）" % [x0, e1.global_position.x])
			_ok(absf(e1.get("_knockback").length() - 250.0) < 0.001, "击退/衰减: 50%%/帧 → 250（实得 %.1f）" % e1.get("_knockback").length())
			return 2
		2:
			# 连续推进至归零（阈值 < 8 清零）
			var e1: Node = _enemy_container.get_child(0)
			var steps: int = 0
			while e1.get("_knockback") != Vector2.ZERO and steps < 20:
				e1.call("_process_knockback")
				steps += 1
			_ok(e1.get("_knockback") == Vector2.ZERO, "击退/归零: %d 帧内衰减清零" % steps)
			_clear_enemy_container()
			return 3
		3:
			# 死亡敌人免疫击退；零向量/零力免疫
			var e2: Node = _build_enemy({
				"id": "chaser", "category": "regular", "max_health": ENEMY_HP, "damage": 5.0,
				"move_speed": 100.0, "behavior": "chase", "armor": 0,
			})
			e2.set("is_alive", false)
			e2.call("apply_knockback", Vector2.RIGHT, 500.0)
			_ok(e2.get("_knockback") == Vector2.ZERO, "击退/死亡: is_alive=false 免疫击退")
			e2.set("is_alive", true)
			e2.call("apply_knockback", Vector2.ZERO, 500.0)
			_ok(e2.get("_knockback") == Vector2.ZERO, "击退/零方向: 零向量不写入")
			e2.call("apply_knockback", Vector2.RIGHT, 0.0)
			_ok(e2.get("_knockback") == Vector2.ZERO, "击退/零力: force<=0 不写入")
			e2.set("is_alive", false)
			e2.call("take_damage", 999.0)
			_ok(true, "击退/死亡敌人: take_damage 不崩")
			_clear_enemy_container()
			return 4
		# ---------- §2 升级冲击（黑盒 gain_exp） ----------
		4:
			# 布局：玩家 (200,200)；敌 B 半径内 60px 右 / 敌 C 半径外 250px 右
			var b: Node = _build_enemy({
				"id": "chaser", "category": "regular", "max_health": ENEMY_HP, "damage": 5.0,
				"move_speed": 100.0, "behavior": "chase", "armor": 0,
			})
			b.global_position = Vector2(260.0, 200.0)
			var c: Node = _build_enemy({
				"id": "chaser", "category": "regular", "max_health": ENEMY_HP, "damage": 5.0,
				"move_speed": 100.0, "behavior": "chase", "armor": 0,
			})
			c.global_position = Vector2(450.0, 200.0)
			_ok(b.get("health") == ENEMY_HP and c.get("health") == ENEMY_HP, "升级/布局: 敌人初始满血")
			return 5
		5:
			# 触发升级（exp 加满当前阈值）→ 冲击波（倍率 1.0 · 初始枪 8.0 → 掉 8）
			var b: Node = _enemy_container.get_child(0)
			var c: Node = _enemy_container.get_child(1)
			var fx_before: int = _fx_container.get_child_count()
			_player.call("gain_exp", _player.call("get_xp_to_next_level"))
			_ok(_player.get("level") == 2, "升级/触发: gain_exp 满阈值 → level 2（实得 %d）" % _player.get("level"))
			_ok(absf(b.get("health") - (ENEMY_HP - 8.0)) < 0.01, "升级/伤害: 半径内普攻级 8 伤（初始枪 base 8.0 → 实得 %.1f）" % b.get("health"))
			_ok(c.get("health") == ENEMY_HP, "升级/范围: 半径外 140px 不受伤（实得 %.1f）" % c.get("health"))
			var kb_b: Vector2 = b.get("_knockback")
			_ok(kb_b != Vector2.ZERO and kb_b.x > 0.0, "升级/击退: 半径内敌被推开（方向背离玩家 x+）")
			_ok(c.get("_knockback") == Vector2.ZERO, "升级/击退: 半径外敌不击退")
			_ok(_fx_container.get_child_count() >= fx_before + 1, "升级/光效: fx_levelup 实例入容器")
			return 6
		6:
			# 伤害倍率生效（damage_multiplier 2.0 → 冲击 16）
			var b: Node = _enemy_container.get_child(0)
			_player.set("damage_multiplier", 2.0)
			_player.call("gain_exp", _player.call("get_xp_to_next_level"))
			_ok(_player.get("level") == 3, "升级/倍率: level 3")
			_ok(absf(b.get("health") - (ENEMY_HP - 24.0)) < 0.01, "升级/倍率: ×2.0 → 掉 16（实得 %.1f）" % b.get("health"))
			return 7
		7:
			# 自定义武器伤害透传（base_damage 12 → ×2.0 = 24）
			# 注：equipped_weapons 为类型化 Array[Resource]，就地修改数组（clear+append）绕开 setter 替换语义
			var b: Node = _enemy_container.get_child(0)
			var custom_w: Resource = load("res://scripts/weapons/weapon.gd").new()
			custom_w.set("base_damage", 12.0)
			var w_arr: Array = _wc.get("equipped_weapons")
			w_arr.clear()
			w_arr.append(custom_w)
			_ok(w_arr.size() == 1 and float(w_arr[0].get("base_damage")) == 12.0,
				"升级/武器: 装配生效（size=%d base=%.1f）" % [w_arr.size(), float(w_arr[0].get("base_damage"))])
			_player.call("gain_exp", _player.call("get_xp_to_next_level"))
			_ok(absf(b.get("health") - (ENEMY_HP - 48.0)) < 0.01, "升级/武器: 自定义 base 12 ×2.0 → 掉 24（实得 %.1f）" % b.get("health"))
			return 8
		# ---------- §3 无武器兜底 + 连升多级 ----------
		8:
			# 移除 WeaponController → 兜底 10 × 2.0 = 20
			var b: Node = _enemy_container.get_child(0)
			_player.remove_child(_wc)
			_wc.free()
			_player.call("gain_exp", _player.call("get_xp_to_next_level"))
			_ok(absf(b.get("health") - (ENEMY_HP - 68.0)) < 0.01, "升级/兜底: 无武器 → 10 ×2.0 = 掉 20（实得 %.1f）" % b.get("health"))
			return 9
		9:
			# 连升多级：一次满 3 级经验 → 上涨曲线下实际升 2 级（level5 need=70，210 = 70+80 后剩 60 < 90）
			var c: Node = _enemy_container.get_child(1)
			var fx_before: int = _fx_container.get_child_count()
			var need: float = _player.call("get_xp_to_next_level")
			_player.call("gain_exp", need * 3.0)
			_ok(_player.get("level") == 7, "升级/连升: 一次经验曲线下升 2 级 → level 7（实得 %d）" % _player.get("level"))
			_ok(_fx_container.get_child_count() >= fx_before + 2, "升级/连升: 每级光效各 1 次（+2）")
			return 10
		# ---------- §4 边界/回归 ----------
		10:
			# 死亡敌人跳过（半径内 is_alive=false 不受伤不击退不崩）；B 仍受冲击（radius 内）
			var b: Node = _enemy_container.get_child(0)
			var d: Node = _build_enemy({
				"id": "chaser", "category": "regular", "max_health": ENEMY_HP, "damage": 5.0,
				"move_speed": 100.0, "behavior": "chase", "armor": 0,
			})
			d.global_position = Vector2(210.0, 200.0)
			d.set("is_alive", false)
			_player.call("gain_exp", _player.call("get_xp_to_next_level"))
			_ok(d.get("health") == ENEMY_HP and d.get("_knockback") == Vector2.ZERO, "升级/死亡: 半径内死亡敌不受伤不击退")
			_ok(b.get("_knockback") != Vector2.ZERO, "升级/边界: 存活敌 B 仍被击退")
			_clear_enemy_container()
			return 11
		11:
			# 敌人容器为空 → 不崩
			_player.call("gain_exp", _player.call("get_xp_to_next_level"))
			_ok(true, "升级/空容器: 零敌人不崩")
			return 12
		12:
			# 升级等级推进记录（终态 sanity：sub5-10 累计升 8 级 → level ≥ 8）
			_ok(_player.get("level") >= 8, "升级/终态: 连串升级后 level ≥ 8（实得 %d）" % _player.get("level"))
			return 13
		_:
			return 13
