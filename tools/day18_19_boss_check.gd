## Day 18-19 出口校验：Boss 多阶段（D18-19-T1~T5 / D18-19-EXIT 收口）
##
## 用法（无头，不需要编辑器）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day18_19_boss_check.gd
##
## 校验内容（对应 docs/SOLUTION_PLAN.md 四·任务5 五段）：
##   1. 数据层：boss[2]（invoker 2 phases / predator 3 phases / exp_value 齐）；
##      hp_threshold_percent 单调递减；attacks 全量可被 _parse_attack 解析（未知指令 = 0）
##   2. 阶段状态机（白盒直构造 stats）：初始 phase 0 / _attack_timers 键数 == attacks 数 /
##      非 boss 零新行为；take_damage 压过阈值 → 阶段切换（attacks 更新 / move_speed ×speed_multiplier /
##      横幅出现）；全阶段走完不再切（die 先行 D6）
##   3. 指令执行（固定 _rng.seed）：summon_2_enemies_every_5s → Enemies 容器 +2（id ∈ regular 池）；
##      summon_1_elite → +1（is_elite）；3_projectile_spread → Boss 子节点 +3 EnemyProjectile（D1 口径）；
##      aoe_every_8s → 玩家掉血（damage×mult）；charge_attack_2x 置位 → 接触伤害 ×2；
##      all_attacks_2x → _attack_mult == 2.0
##   4. 弹丸（enemy_projectile 白盒）：命中玩家掉血 + 销毁；lifetime 耗尽销毁；damage 透传
##   5. 回归：wave 10 boss:invoker / wave 20 boss:predator 白盒 spawn → is_boss + category=boss +
##      phases 透传非空 + scale 复位 ×1（D17）；route 末层 boss wave_index == 10；boss 波击杀 → boss_killed 登记
##
## 退出码 0 = 全部通过；非 0 = 失败项数。
extends SceneTree

const ENEMY_SCENE_PATH: String = "res://scenes/Enemy.tscn"
const ROUTE_GEN_PATH: String = "res://scripts/systems/route_generator.gd"
## ⚠️ enemy_projectile.gd 引用 autoload 标识符（GameManager），--script 探针编译期 preload 会
## 报 "Identifier not found"（编译期 autoload 未注册）→ 必须运行期 load（同 enemy.gd 运行期 load 范式）
const ENEMY_PROJ_PATH: String = "res://scripts/enemy/enemy_projectile.gd"

var _sub: int = 0
var _ready_mocks: bool = false
var _loader: Node = null
var _gm: Node = null
var _gen: GDScript = null
var _proj_script: GDScript = null
var _player: Node = null
var _fx_container: Node = null
var _enemy_container: Node = null
var _checked: int = 0
var _failures: int = 0

func _initialize() -> void:
	print("=== Day 18-19 boss check ===")

func _process(_delta: float) -> bool:
	if not _ready_mocks:
		_load_mocks()
		return false
	if _sub > 25:
		_report()
		quit(_failures)
		return true
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
	_gen = load(ROUTE_GEN_PATH)
	# 弹丸脚本运行期 load（编译期 preload 会因 autoload 标识符未注册失败）
	_proj_script = load(ENEMY_PROJ_PATH)
	if _proj_script == null:
		_fail("enemy_projectile.gd 加载失败")
		_report()
		quit(1)
		return

	# mock player（player.gd 脚本：take_damage/heal/gain_exp 齐备）
	_player = CharacterBody2D.new()
	_player.name = "MockPlayer"
	_player.set_script(load("res://scripts/player/player.gd"))
	_player.max_health = 100.0
	_player.armor = 0.0
	_player.dodge = 0.0
	_player.life_steal = 0.0
	_player.regen = 0.0
	_player.attack_speed = 1.0
	_player.move_speed = 300.0
	root.add_child(_player)
	_player.max_health = 100.0
	_player.health = 100.0
	_player._invulnerable_timer = 0.0
	_gm.set("player", _player)

	# 特效容器（横幅断言用；GameManager.vfx_container）
	_fx_container = Node2D.new()
	_fx_container.name = "FxContainer"
	root.add_child(_fx_container)
	_gm.set("vfx_container", _fx_container)
	# 敌人容器（召唤断言用；GameManager.enemies_container）
	_enemy_container = Node2D.new()
	_enemy_container.name = "EnemyContainer"
	root.add_child(_enemy_container)
	_gm.set("enemies_container", _enemy_container)

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
	print("=== DAY18-19 BOSS CHECK: %d assertions, %d failures ===" % [_checked, _failures])
	if _failures == 0:
		print("DAY18-19 BOSS CHECK CLEAN")

## 重置玩家到出厂（AOE/接触伤害断言用：清无敌帧/闪避/血量）
func _reset_player() -> void:
	_player.max_health = 100.0
	_player.health = 100.0
	_player._invulnerable_timer = 0.0
	_player.dodge = 0.0
	_player.armor = 0.0

## 白盒构造敌人：instantiate + initialize(stats) + set_target + 入树
func _build_enemy(stats: Dictionary) -> Node:
	var scene: PackedScene = load(ENEMY_SCENE_PATH)
	var enemy: Node = scene.instantiate()
	if enemy.has_method("initialize"):
		enemy.initialize(stats)
	if enemy.has_method("set_target"):
		enemy.set_target(_player)
	root.add_child(enemy)
	return enemy

## 清空敌人容器（立即销毁防 queue_free 延迟污染跨段断言）
func _clear_enemy_container() -> void:
	for child in _enemy_container.get_children():
		_enemy_container.remove_child(child)
		child.free()

# ========== 主推进（线性子步骤） ==========

func _advance(sub: int) -> int:
	match sub:
		# ---------- §1 数据层 ----------
		0:
			var inv: Dictionary = _loader.call("get_scaled_enemy", "invoker", 10)
			var pred: Dictionary = _loader.call("get_scaled_enemy", "predator", 20)
			_ok(not inv.is_empty() and str(inv.get("category", "")) == "boss", "数据: invoker 存在且 category=boss")
			_ok(not pred.is_empty() and str(pred.get("category", "")) == "boss", "数据: predator 存在且 category=boss")
			var inv_phases: Array = inv.get("phases", [])
			var pred_phases: Array = pred.get("phases", [])
			_ok(inv_phases.size() == 2, "数据: invoker 2 phases（实得 %d）" % inv_phases.size())
			_ok(pred_phases.size() == 3, "数据: predator 3 phases（实得 %d）" % pred_phases.size())
			_ok(int(inv.get("exp_value", 0)) == 400 and int(pred.get("exp_value", 0)) == 500, "数据: exp_value 400/500")
			# threshold 单调递减
			var mono_ok: bool = true
			for ph_arr in [inv_phases, pred_phases]:
				var prev: float = 999.0
				for ph in ph_arr:
					var t: float = float(ph.get("hp_threshold_percent", 0.0))
					if t >= prev:
						mono_ok = false
					prev = t
			_ok(mono_ok, "数据: hp_threshold_percent 单调递减（100→60 / 100→66→33）")
			# attacks 全量可被 _parse_attack 解析（未知指令 = 0）—— 用白盒 enemy 实例调用纯函数
			var parser: Node = _build_enemy({
				"id": "chaser", "category": "regular", "max_health": 30.0, "damage": 5.0,
				"move_speed": 120.0, "behavior": "chase", "armor": 0,
			})
			var unknown: int = 0
			var total_cmds: int = 0
			for ph_arr in [inv_phases, pred_phases]:
				for ph in ph_arr:
					for cmd in ph.get("attacks", []):
						total_cmds += 1
						if parser.call("_parse_attack", str(cmd)).is_empty():
							unknown += 1
							print("  未知指令: %s" % cmd)
			_ok(total_cmds == 11 and unknown == 0, "数据: 11 条 attacks 全量可解析，未知 = 0（实得 %d/%d）" % [total_cmds, unknown])
			# 未知指令兜底：返回 {} 不崩
			_ok(parser.call("_parse_attack", "unknown_attack_x").is_empty(), "数据: 未知指令返回 {}（不崩）")
			parser.queue_free()
			return 1
		# ---------- §2 阶段状态机 ----------
		1:
			# invoker 白盒（真实 phases 副本）→ 初始 phase 0 / _attack_timers 键数 == P1 attacks 数
			var inv_stats: Dictionary = _loader.call("get_scaled_enemy", "invoker", 10)
			var boss: Node = _build_enemy(inv_stats)
			_ok(boss.get("is_boss") == true, "状态机: invoker is_boss == true")
			_ok(boss.get("scale") == Vector2(1.0, 1.0), "状态机: scale 复位 ×1（D17·128px 真精灵，实得 %s）" % str(boss.get("scale")))
			_ok(int(boss.get("_current_phase_idx")) == 0, "状态机: 初始 phase 0")
			var timers: Dictionary = boss.get("_attack_timers")
			_ok(timers.size() == 2, "状态机: _attack_timers 键数 == P1 attacks 数 2（实得 %d）" % timers.size())
			_ok(timers.has("summon_2_enemies_every_5s") and timers.has("3_projectile_spread"), "状态机: P1 指令键已缓存")
			_ok(absf(float(boss.get("_attack_mult")) - 1.0) < 0.001, "状态机: P1 无修饰符 _attack_mult == 1.0")
			# 非 boss（regular 无 phases）→ 零新行为
			var plain: Node = _build_enemy({
				"id": "chaser", "category": "regular", "max_health": 30.0, "damage": 5.0,
				"move_speed": 120.0, "behavior": "chase", "armor": 0,
			})
			_ok(plain.get("is_boss") == false and plain.get("phases").is_empty(), "状态机: 非 boss phases 空 → 零新行为")
			_ok(int(plain.get("_current_phase_idx")) == 0 and plain.get("_attack_timers").is_empty(), "状态机: 非 boss _attack_timers 空")
			plain.queue_free()
			boss.queue_free()
			return 2
		2:
			# take_damage 压过 60% 阈值 → phase 1（attacks 更新 / move_speed ×1.2 / 横幅出现）
			var inv_stats2: Dictionary = _loader.call("get_scaled_enemy", "invoker", 10)
			var boss2: Node = _build_enemy(inv_stats2)
			var hp0: float = float(boss2.get("max_health"))   # wave10: 8000
			var speed0: float = float(boss2.get("move_speed")) # wave10: 200*1.1*0.5 = 110
			boss2.call("take_damage", hp0 * 0.41)  # 8000-3280 = 4720 ≤ 4800 → 切 P2
			_ok(int(boss2.get("_current_phase_idx")) == 1, "状态机: 压过 60%% 阈值 → phase 1（实得 %d）" % int(boss2.get("_current_phase_idx")))
			var timers2: Dictionary = boss2.get("_attack_timers")
			_ok(timers2.size() == 2 and timers2.has("summon_4_enemies_every_2.5s") and timers2.has("6_projectile_spread"),
				"状态机: P2 指令键更新（summon_4/6_spread）")
			_ok(absf(float(boss2.get("move_speed")) - speed0 * 1.2) < 0.01, "状态机: move_speed ×speed_multiplier 1.2（%.1f→%.1f）" % [speed0, float(boss2.get("move_speed"))])
			# 横幅出现（_gm.vfx_container 已挂 → BossPhaseBanner spawn 到容器）
			_ok(_fx_container.get_node_or_null("BossPhaseBanner") != null, "状态机: 阶段切换横幅「BossPhaseBanner」出现")
			# 全阶段走完不再切（压到 0 → die 先行 D6，不触发相位检查）
			boss2.call("take_damage", hp0 * 0.59)
			_ok(boss2.get("is_alive") == false, "状态机: 血量归零 → die（D6 先行）")
			_ok(int(boss2.get("_current_phase_idx")) == 1, "状态机: 死亡不触发额外相位切换（保持 1）")
			boss2.queue_free()
			return 3
		# ---------- §3 指令执行（固定 _rng.seed） ----------
		3:
			_clear_enemy_container()
			var summon_stats: Dictionary = _loader.call("get_scaled_enemy", "invoker", 10)
			var boss3: Node = _build_enemy(summon_stats)
			boss3.set("_rng", RandomNumberGenerator.new())
			boss3._rng.seed = 20260807
			# summon_2_enemies_every_5s：白盒直调 → Enemies 容器 +2（id ∈ regular 池）
			boss3.call("_boss_summon", 2, false)
			var kids: Array = _enemy_container.get_children()
			_ok(kids.size() == 2, "指令/召唤: 容器 +2 只（实得 %d）" % kids.size())
			var id_ok: bool = true
			for kid in kids:
				# 注意：kid 是 Node（Object.get 单参），勿用 Dictionary 双参默认值写法
				var kcat: String = str(kid.get("enemy_category"))
				if kcat != "regular":
					id_ok = false
					print("  summon regular 池异常: %s" % kid.get("enemy_id"))
			_ok(id_ok, "指令/召唤: 子代 ∈ regular 池")
			# summon_1_elite → +1（is_elite）
			boss3.call("_boss_summon", 1, true)
			var kids2: Array = _enemy_container.get_children()
			_ok(kids2.size() == 3, "指令/召唤: elite +1 → 容器 3（实得 %d）" % kids2.size())
			_ok(kids2[2].get("is_elite") == true, "指令/召唤: 子代 is_elite == true")
			# 容器缺失 → 静默跳过不崩
			_gm.set("enemies_container", null)
			boss3.call("_boss_summon", 2, false)
			_ok(true, "指令/召唤: 容器缺失静默跳过不崩")
			_gm.set("enemies_container", _enemy_container)
			boss3.queue_free()
			return 4
		4:
			# 3_projectile_spread → Boss 子节点 +3 EnemyProjectile（D1 容器断言口径）
			_clear_enemy_container()  # 清空 sub 3 召唤残留，验证弹丸零入容器
			var spread_stats: Dictionary = _loader.call("get_scaled_enemy", "invoker", 10)
			var boss4: Node = _build_enemy(spread_stats)
			var before_count: int = boss4.get_child_count()
			boss4.call("_boss_spread", 3)
			var proj_count: int = 0
			for child in boss4.get_children():
				if child.is_in_group("enemy_projectiles"):
					proj_count += 1
			_ok(proj_count == 3, "指令/spread: Boss 子节点 +3 EnemyProjectile（实得 %d）" % proj_count)
			# 弹丸不入 Enemies 容器（get_alive_count 防污染核心断言）
			_ok(_enemy_container.get_child_count() == 0, "指令/spread: Enemies 容器零新增（D1 防 alive-count 污染）")
			# aoe_every_8s → 玩家掉血 damage×mult（invoker dmg 15 ×1.0 = 15）
			_reset_player()
			_player.global_position = boss4.global_position  # 距离 0 ≤ 120
			boss4.call("_boss_aoe")
			_ok(absf(_player.health - 85.0) < 0.01, "指令/aoe: 玩家掉 15（实得 %.1f）" % _player.health)
			_reset_player()
			_player.global_position = boss4.global_position + Vector2(200.0, 0.0)  # 200 > 120
			boss4.call("_boss_aoe")
			_ok(absf(_player.health - 100.0) < 0.01, "指令/aoe: 距离 200 > 120 → 不掉血")
			boss4.queue_free()
			return 5
		5:
			# charge_attack_2x 置位 → 接触伤害 ×2（predator dmg 20 → 40）
			_reset_player()
			var charge_stats := {
				"id": "predator", "category": "boss", "max_health": 15000.0, "damage": 20.0,
				"move_speed": 110.0, "behavior": "chase", "armor": 0,
				"phases": [{"hp_threshold_percent": 100, "speed_multiplier": 1.0, "attacks": ["charge_attack_2x"]}],
			}
			var boss5: Node = _build_enemy(charge_stats)
			_ok(boss5.get("_boss_charge") == true and absf(float(boss5.get("_boss_charge_mult")) - 2.0) < 0.001,
				"指令/charge: charge_attack_2x 置位 mult 2.0")
			boss5.global_position = Vector2.ZERO
			_player.global_position = Vector2(20.0, 0.0)  # 20 ≤ contact_range(28)
			boss5.call("_try_contact_damage")
			_ok(absf(_player.health - 60.0) < 0.01, "指令/charge: 接触伤害 ×2 → 掉 40（实得 %.1f）" % _player.health)
			# 普通敌人（非 boss）接触伤害恒 ×1.0（守卫回归）
			_reset_player()
			var plain5: Node = _build_enemy({
				"id": "charger", "category": "regular", "max_health": 30.0, "damage": 10.0,
				"move_speed": 120.0, "behavior": "chase", "armor": 0,
			})
			plain5.global_position = Vector2.ZERO
			_player.global_position = Vector2(20.0, 0.0)
			plain5.call("_try_contact_damage")
			_ok(absf(_player.health - 90.0) < 0.01, "指令/charge: 普通敌人恒 ×1.0 → 掉 10（实得 %.1f）" % _player.health)
			# all_attacks_2x → _attack_mult == 2.0
			var mult_stats := {
				"id": "predator", "category": "boss", "max_health": 15000.0, "damage": 20.0,
				"move_speed": 110.0, "behavior": "chase", "armor": 0,
				"phases": [{"hp_threshold_percent": 100, "speed_multiplier": 1.0, "attacks": ["all_attacks_2x"]}],
			}
			var boss5b: Node = _build_enemy(mult_stats)
			_ok(absf(float(boss5b.get("_attack_mult")) - 2.0) < 0.001, "指令/mult: all_attacks_2x → _attack_mult == 2.0")
			boss5.queue_free()
			boss5b.queue_free()
			plain5.queue_free()
			return 6
		# ---------- §4 弹丸（enemy_projectile 白盒） ----------
		6:
			# 命中玩家掉血 + 销毁（speed 220 × 0.3s = 66px；玩家摆 60px → 命中）
			_reset_player()
			_player.global_position = Vector2(60.0, 0.0)
			var p1: Node = _proj_script.new()
			root.add_child(p1)
			p1.call("initialize", {"speed": 220.0, "damage": 10.0, "lifetime": 2.0})
			p1.call("set_direction", Vector2.RIGHT)
			p1.global_position = Vector2.ZERO
			p1.call("_physics_process", 0.3)
			_ok(absf(_player.health - 90.0) < 0.01, "弹丸/命中: 玩家掉 10（实得 %.1f）" % _player.health)
			_ok(p1.is_queued_for_deletion(), "弹丸/命中: 命中即毁 queue_free")
			p1.queue_free()
			# lifetime 耗尽销毁（lifetime 0.5，推进 0.6 → 超时）
			_reset_player()
			_player.global_position = Vector2(500.0, 0.0)
			var p2: Node = _proj_script.new()
			root.add_child(p2)
			p2.call("initialize", {"speed": 220.0, "damage": 10.0, "lifetime": 0.5})
			p2.call("set_direction", Vector2.RIGHT)
			p2.global_position = Vector2.ZERO
			p2.call("_physics_process", 0.6)
			_ok(p2.is_queued_for_deletion(), "弹丸/lifetime: 超时销毁")
			_ok(absf(_player.health - 100.0) < 0.01, "弹丸/lifetime: 未命中玩家不掉血")
			p2.queue_free()
			# damage 透传（damage 25 → 掉 25）
			_reset_player()
			_player.global_position = Vector2(60.0, 0.0)
			var p3: Node = _proj_script.new()
			root.add_child(p3)
			p3.call("initialize", {"speed": 220.0, "damage": 25.0, "lifetime": 2.0})
			p3.call("set_direction", Vector2.RIGHT)
			p3.global_position = Vector2.ZERO
			p3.call("_physics_process", 0.3)
			_ok(absf(_player.health - 75.0) < 0.01, "弹丸/damage: 透传 25 → 掉 25（实得 %.1f）" % _player.health)
			p3.queue_free()
			# 玩家无效（GameManager.player = null）→ 不崩
			_gm.set("player", null)
			var p4: Node = _proj_script.new()
			root.add_child(p4)
			p4.call("initialize", {"speed": 220.0, "damage": 10.0, "lifetime": 2.0})
			p4.call("set_direction", Vector2.RIGHT)
			p4.global_position = Vector2.ZERO
			p4.call("_physics_process", 0.3)
			_ok(true, "弹丸/玩家无效: 不崩")
			p4.queue_free()
			_gm.set("player", _player)
			return 7
		# ---------- §5 回归 ----------
		7:
			# wave 10 invoker / wave 20 predator 白盒 spawn → is_boss + category=boss + phases 非空
			var inv5: Dictionary = _loader.call("get_scaled_enemy", "invoker", 10)
			var pred5: Dictionary = _loader.call("get_scaled_enemy", "predator", 20)
			var b_inv: Node = _build_enemy(inv5)
			var b_pred: Node = _build_enemy(pred5)
			_ok(b_inv.get("is_boss") == true and str(b_inv.get("enemy_category")) == "boss" and not b_inv.get("phases").is_empty(),
				"回归: invoker wave10 spawn → is_boss/boss/phases 非空")
			_ok(b_pred.get("is_boss") == true and str(b_pred.get("enemy_category")) == "boss" and not b_pred.get("phases").is_empty(),
				"回归: predator wave20 spawn → is_boss/boss/phases 非空")
			b_inv.queue_free()
			b_pred.queue_free()
			# route 末层 boss wave_index == 10（勿写 20；路线模式终局 Boss = invoker）
			var route: Dictionary = _gen.generate_from(20260806, _loader.get_routes())
			var boss_wi_ok: bool = true
			var boss_found: bool = false
			for layer in route.get("layers", []):
				for node in layer:
					if str(node.get("type", "")) == "boss":
						boss_found = true
						if int(node.get("wave_index", -1)) != 10:
							boss_wi_ok = false
			_ok(boss_found and boss_wi_ok, "回归: 路线 boss 节点 wave_index == 10（实含 %s）" % ("是" if boss_found else "否"))
			return 8
		8:
			# boss 波击杀 → boss_killed 登记 + route flags boss_defeated（T4）
			_gm.call("reset")
			_gm.set("route", {"flags": {}})
			var inv6: Dictionary = _loader.call("get_scaled_enemy", "invoker", 10)
			var b_kill: Node = _build_enemy(inv6)
			_ok(int(_gm.get("boss_killed")) == 0, "回归/前置: reset 后 boss_killed == 0")
			b_kill.call("die")
			_ok(int(_gm.get("boss_killed")) == 1, "回归: boss 击杀 → boss_killed == 1（实得 %d）" % int(_gm.get("boss_killed")))
			var flags: Dictionary = _gm.route.get("flags", {})
			_ok(flags.get("boss_defeated", false) == true, "回归: route.flags.boss_defeated == true")
			# 非 boss 击杀不登记
			var plain_kill: Node = _build_enemy({
				"id": "chaser", "category": "regular", "max_health": 30.0, "damage": 5.0,
				"move_speed": 120.0, "behavior": "chase", "armor": 0,
			})
			plain_kill.call("die")
			_ok(int(_gm.get("boss_killed")) == 1, "回归: 非 boss 击杀不登记（保持 1）")
			b_kill.queue_free()
			plain_kill.queue_free()
			return 9
		_:
			return 99  # 结束哨兵
