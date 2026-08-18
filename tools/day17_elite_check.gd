## Day 17 出口校验：精英战斗（D17-T1~T5 / D17-EXIT 收口）
##
## 用法（无头，不需要编辑器）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day17_elite_check.gd
##
## 校验内容（对应 docs/TASKS.md D17-T5 五段）：
##   1. 数据层：6 精英 id/name/behavior/exp_value/drop 齐；3 只有 ability 且
##      type ∈ {aoe, self_heal, spawn} + 数值 > 0；mom minion 存在；colossus/rhino/croc 缺省无 ability
##   2. 能力行为（白盒直构造 stats + 固定 delta）：butcher AOE → 玩家掉 damage×mult 且 timer 重置；
##      monk 低血自愈 → health 回升不超上限；mom 产卵 → 容器 +count 只 chaser（wave_number 缩放正确）；
##      无 ability → 零新行为
##   3. mixed 池解析（BUG-003 收口）：固定 _rng.seed → wave15 白盒 config（无 special）→
##      精英 4 只（id ∈ 6 精英）+ regular 56 只零 null；wave17（mixed_with_curse）同法；
##      真实 wave15（swarm_wave）→ spawn_queue 120 = count×2 与池解析顺序兼容；elite:mixed 不抽 boss/regular
##   4. difficulty_delta：route.flags +1 → 敌人 max_health ×1.1 / damage ×1.1；0 → 零影响
##   5. 回归锚点：6 精英 behavior ∈ 9 枚举；is_elite 标记正确；elite 节点 wave_index ∈ [6,19]
##
## 退出码 0 = 全部通过；非 0 = 失败项数。
extends SceneTree

const ENEMY_SCENE_PATH: String = "res://scenes/Enemy.tscn"
const SPAWNER_SCENE_PATH: String = "res://scenes/EnemySpawner.tscn"
const ROUTE_GEN_PATH: String = "res://scripts/systems/route_generator.gd"
const FIXED_SEED: int = 20260806
const ELITE_IDS: Array = ["butcher", "colossus", "rhino", "monk", "croc", "mom"]
const BEHAVIOR_KEYS: Array = [
	"chase", "charge", "zigzag", "ranged", "heal", "spawn", "stationary", "aoe_attack", "self_heal",
]

var _sub: int = 0
var _ready_mocks: bool = false
var _loader: Node = null
var _gm: Node = null
var _gen: GDScript = null
var _player: Node = null
var _checked: int = 0
var _failures: int = 0

func _initialize() -> void:
	print("=== Day 17 elite check ===")

func _process(_delta: float) -> bool:
	if not _ready_mocks:
		_load_mocks()
		return false
	if _sub > 30:
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
	print("=== DAY17 ELITE CHECK: %d assertions, %d failures ===" % [_checked, _failures])
	if _failures == 0:
		print("DAY17 ELITE CHECK CLEAN")

## 重置玩家到出厂（AOE 断言用：清无敌帧/闪避/血量）
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

# ========== 主推进（线性子步骤） ==========

func _advance(sub: int) -> int:
	match sub:
		# ---------- §1 数据层 ----------
		0:
			var ok_all: bool = true
			for eid in ELITE_IDS:
				var data: Dictionary = _loader.call("get_enemy", eid)
				if data.is_empty():
					ok_all = false
					print("  data 缺失: " + eid)
					continue
				if str(data.get("name", "")).is_empty() or str(data.get("behavior", "")).is_empty():
					ok_all = false
				if int(data.get("exp_value", 0)) <= 0 or int(data.get("coin_value", 0)) <= 0:
					ok_all = false
			_ok(ok_all, "数据: 6 精英 id/name/behavior/exp_value/coin_value 齐")
			# 3 只有 ability 且 type ∈ {aoe, self_heal, spawn} + 数值 > 0
			var ability_map: Dictionary = {
				"butcher": "aoe", "monk": "self_heal", "mom": "spawn",
			}
			var ab_ok: bool = true
			for eid in ability_map:
				var data: Dictionary = _loader.call("get_enemy", eid)
				var ab: Dictionary = data.get("ability", {})
				if ab.get("type", "") != ability_map[eid]:
					ab_ok = false
					print("  %s ability.type 异常: %s" % [eid, ab.get("type", "")])
				for k in ab:
					var v = ab[k]
					if k == "type" or v is String:
						continue
					if float(v) <= 0.0:
						ab_ok = false
						print("  %s ability.%s 应 > 0: %s" % [eid, k, v])
			_ok(ab_ok, "数据: butcher/monk/mom 有 ability 且 type/数值合法")
			# mom minion 存在
			var mom_data: Dictionary = _loader.call("get_enemy", "mom")
			var minion: String = str(mom_data.get("ability", {}).get("minion", ""))
			_ok(not _loader.call("get_enemy", minion).is_empty(), "数据: mom minion=%s 在 enemies.json 存在" % minion)
			# colossus/rhino/croc 缺省无 ability
			var no_ab: bool = true
			for eid in ["colossus", "rhino", "croc"]:
				if _loader.call("get_enemy", eid).has("ability"):
					no_ab = false
			_ok(no_ab, "数据: colossus/rhino/croc 缺省无 ability")
			return 1
		# ---------- §2 能力行为（白盒直构造） ----------
		1:
			# butcher AOE：damage=10, mult=1.2 → 玩家掉 12；timer 重置为 interval 3.0
			_reset_player()
			var butcher_stats := {
				"id": "butcher", "category": "elite", "max_health": 200.0, "damage": 10.0,
				"move_speed": 200.0, "behavior": "aoe_attack", "armor": 0,
				"ability": {"type": "aoe", "radius": 90.0, "interval": 3.0, "damage_mult": 1.2},
			}
			var butcher: Node = _build_enemy(butcher_stats)
			# 敌人与玩家同点（距离 0 ≤ radius 90）
			butcher.global_position = Vector2.ZERO
			_player.global_position = Vector2.ZERO
			butcher.call("_elite_aoe", 4.0)
			_ok(absf(_player.health - 88.0) < 0.01, "能力/AOE: 玩家掉 damage×mult=12 → 88（实得 %.1f）" % _player.health)
			_ok(absf(float(butcher.get("_ability_timer")) - 3.0) < 0.01, "能力/AOE: timer 重置为 interval 3.0（实得 %.2f）" % float(butcher.get("_ability_timer")))
			# timer 未到点 → 无副作用
			_reset_player()
			butcher.call("_elite_aoe", 1.0)  # 3.0-1.0 = 2.0 > 0
			_ok(absf(_player.health - 100.0) < 0.01, "能力/AOE: timer 未到点 → 玩家不掉血")
			butcher.queue_free()
			return 2
		2:
			# monk 自愈：max_health 200, threshold 0.5 → 打伤到 80 → 自愈 15% → 110
			var monk_stats := {
				"id": "monk", "category": "elite", "max_health": 200.0, "damage": 6.0,
				"move_speed": 300.0, "behavior": "self_heal", "armor": 0,
				"ability": {"type": "self_heal", "threshold": 0.5, "heal_percent": 0.15, "interval": 4.0},
			}
			var monk: Node = _build_enemy(monk_stats)
			monk.call("take_damage", 120.0)
			_ok(absf(float(monk.get("health")) - 80.0) < 0.01, "能力/自愈前置: 打伤后 health 80（实得 %.1f）" % float(monk.get("health")))
			monk.call("_elite_self_heal", 5.0)
			var healed: float = float(monk.get("health"))
			_ok(absf(healed - 110.0) < 0.01, "能力/自愈: 低血自愈 +30 → 110（实得 %.1f）" % healed)
			_ok(healed <= float(monk.get("max_health")), "能力/自愈: 不超上限")
			_ok(absf(float(monk.get("_ability_timer")) - 4.0) < 0.01, "能力/自愈: timer 重置为 interval 4.0")
			# 血量高于阈值 → 不治疗（timer ≤ 0 但条件不满足）
			monk.set("health", 150.0)
			monk.call("_elite_self_heal", 5.0)
			_ok(absf(float(monk.get("health")) - 150.0) < 0.01, "能力/自愈: 血量高于阈值 → 不治疗")
			monk.queue_free()
			return 3
		3:
			# mom 产卵：wave_number=15 → +2 只 chaser（chaser wave15 hp=3+2*15=33）
			var mom_stats := {
				"id": "mom", "category": "elite", "max_health": 250.0, "damage": 6.0,
				"move_speed": 200.0, "behavior": "spawn", "armor": 0, "wave_number": 15,
				"ability": {"type": "spawn", "minion": "chaser", "count": 2, "interval": 5.0},
			}
			var spawn_container := Node2D.new()
			spawn_container.name = "SpawnContainer"
			root.add_child(spawn_container)
			_gm.set("enemies_container", spawn_container)
			var mom: Node = _build_enemy(mom_stats)
			mom.call("_elite_spawn", 6.0)
			var kids: Array = spawn_container.get_children()
			_ok(kids.size() == 2, "能力/产卵: 容器 +2 只（实得 %d）" % kids.size())
			if kids.size() == 2:
				var wave_ok: bool = true
				for kid in kids:
					var kid_id: String = kid.get("enemy_id")
					var hp: float = float(kid.get("max_health"))
					if kid_id != "chaser":
						wave_ok = false
						print("  minion id 异常: %s" % kid_id)
					if absf(hp - 33.0) > 0.01:
						wave_ok = false
						print("  minion max_health 异常: %.1f（期望 33 = chaser wave15）" % hp)
				_ok(wave_ok, "能力/产卵: 子代为 chaser 且 wave_number 缩放正确（hp 33）")
				# 子代 set_target 已接（target == _player）
				_ok(kids[0].get("target") == _player, "能力/产卵: 子代 target == GameManager.player")
			_ok(absf(float(mom.get("_ability_timer")) - 5.0) < 0.01, "能力/产卵: timer 重置为 interval 5.0")
			# 容器缺失 → 静默跳过不崩（产卵不执行）
			_gm.set("enemies_container", null)
			mom.call("_elite_spawn", 6.0)
			_ok(true, "能力/产卵: 容器缺失静默跳过不崩")
			mom.queue_free()
			spawn_container.queue_free()
			_gm.set("enemies_container", null)
			# F-47（2026-08-18 用户拍板「每关怪物固定」）：max_spawns 产卵批数上限——
			# 达上限停止产卵（防召唤物无限产 → 敌全灭永不成立 → 关卡永不结束）
			var mom_cap_stats := {
				"id": "mom", "category": "elite", "max_health": 250.0, "damage": 6.0,
				"move_speed": 200.0, "behavior": "spawn", "armor": 0, "wave_number": 15,
				"ability": {"type": "spawn", "minion": "chaser", "count": 2, "interval": 1.0, "max_spawns": 2},
			}
			var cap_container := Node2D.new()
			cap_container.name = "CapContainer"
			root.add_child(cap_container)
			_gm.set("enemies_container", cap_container)
			var mom_cap: Node = _build_enemy(mom_cap_stats)
			mom_cap.call("_elite_spawn", 1.1)  # 第 1 批（timer 1.0 到点）
			mom_cap.call("_elite_spawn", 1.1)  # 第 2 批（达上限）
			mom_cap.call("_elite_spawn", 1.1)  # 第 3 批（超上限 → 停止）
			_ok(cap_container.get_child_count() == 4, "能力/产卵上限: max_spawns=2 → 共 4 只（实得 %d）" % cap_container.get_child_count())
			# 数据断言：Excel 导出 mom 含 max_spawns=4
			var mom_data2: Dictionary = _loader.call("get_enemy", "mom")
			_ok(int(mom_data2.get("ability", {}).get("max_spawns", 0)) == 4, "数据: Excel 导出 mom ability.max_spawns == 4")
			mom_cap.queue_free()
			cap_container.queue_free()
			_gm.set("enemies_container", null)
			return 4
		4:
			# 无 ability → 零新行为（AOE/自愈/产卵全部立即 return）
			_reset_player()
			var plain_stats := {
				"id": "chaser", "category": "regular", "max_health": 30.0, "damage": 5.0,
				"move_speed": 120.0, "behavior": "aoe_attack", "armor": 0,
			}
			var plain: Node = _build_enemy(plain_stats)
			plain.call("_elite_aoe", 4.0)
			_ok(absf(_player.health - 100.0) < 0.01, "能力/无ability: AOE 零行为（玩家不掉血）")
			var plain2: Node = _build_enemy({"id": "chaser", "category": "regular", "max_health": 30.0, "damage": 5.0, "move_speed": 120.0, "behavior": "self_heal", "armor": 0})
			plain2.set("health", 10.0)
			plain2.call("_elite_self_heal", 5.0)
			_ok(absf(float(plain2.get("health")) - 10.0) < 0.01, "能力/无ability: 自愈零行为（health 不变）")
			var plain3: Node = _build_enemy({"id": "chaser", "category": "regular", "max_health": 30.0, "damage": 5.0, "move_speed": 120.0, "behavior": "spawn", "armor": 0})
			plain3.call("_elite_spawn", 6.0)
			_ok(true, "能力/无ability: 产卵零行为（不崩）")
			plain.queue_free()
			plain2.queue_free()
			plain3.queue_free()
			return 5
		# ---------- §3 mixed 池解析（BUG-003 收口） ----------
		5:
			var spawner: Node = (load(SPAWNER_SCENE_PATH) as PackedScene).instantiate()
			spawner.name = "MockSpawner"
			root.add_child(spawner)
			var container := Node2D.new()
			container.name = "PoolContainer"
			root.add_child(container)
			spawner.call("set_container", container)
			spawner.set("_rng", RandomNumberGenerator.new())
			spawner._rng.seed = 12345
			# 白盒直构造 wave15 同款 composition（无 special → 无 swarm 翻倍，纯池解析验证）
			var cfg15 := {
				"wave": 15, "duration": 50, "total_enemies": 60,
				"composition": [
					{"enemy": "mixed", "count": 56},
					{"enemy": "elite:mixed", "count": 4},
				],
				"special": null,
			}
			spawner.call("spawn_wave", cfg15, 15)
			while spawner.spawn_queue.size() > 0:
				spawner.call("_spawn_next")
			var total: int = container.get_child_count()
			var elites: Array = []
			var regulars: Array = []
			for e in container.get_children():
				if e.get("is_elite"):
					elites.append(e)
				else:
					regulars.append(e)
			_ok(total == 60, "池解析/wave15: 容器 60 只零 null（实得 %d）" % total)
			_ok(elites.size() == 4, "池解析/wave15: 精英 4 只（实得 %d）" % elites.size())
			_ok(regulars.size() == 56, "池解析/wave15: regular 56 只（实得 %d）" % regulars.size())
			var elite_id_ok: bool = true
			for e in elites:
				if not ELITE_IDS.has(str(e.get("enemy_id"))):
					elite_id_ok = false
					print("  elite:mixed 抽到非精英: %s" % e.get("enemy_id"))
			_ok(elite_id_ok, "池解析/wave15: elite:mixed 只抽 6 精英（不抽 boss/regular）")
			# 清场
			container.queue_free()
			return 6
		6:
			# wave17（mixed_with_curse）同法
			var spawner: Node = (load(SPAWNER_SCENE_PATH) as PackedScene).instantiate()
			spawner.name = "MockSpawner2"
			root.add_child(spawner)
			var container2 := Node2D.new()
			container2.name = "PoolContainer2"
			root.add_child(container2)
			spawner.call("set_container", container2)
			spawner.set("_rng", RandomNumberGenerator.new())
			spawner._rng.seed = 999
			var cfg17 := {
				"wave": 17, "duration": 55, "total_enemies": 65,
				"composition": [
					{"enemy": "mixed_with_curse", "count": 61},
					{"enemy": "elite:mixed", "count": 4},
				],
				"special": null,
			}
			spawner.call("spawn_wave", cfg17, 17)
			while spawner.spawn_queue.size() > 0:
				spawner.call("_spawn_next")
			var total2: int = container2.get_child_count()
			var elites2: int = 0
			var regulars2: int = 0
			for e in container2.get_children():
				if e.get("is_elite"):
					elites2 += 1
				else:
					regulars2 += 1
			_ok(total2 == 65, "池解析/wave17(mixed_with_curse): 容器 65 只零 null（实得 %d）" % total2)
			_ok(elites2 == 4 and regulars2 == 61, "池解析/wave17: 精英 4 + regular 61（实得 %d/%d）" % [elites2, regulars2])
			container2.queue_free()
			return 7
		7:
			# 真实 wave15（special=swarm_wave）→ 队列 120 = count×2 与池解析顺序兼容
			var spawner: Node = (load(SPAWNER_SCENE_PATH) as PackedScene).instantiate()
			spawner.name = "MockSpawner3"
			root.add_child(spawner)
			spawner.set("_rng", RandomNumberGenerator.new())
			spawner._rng.seed = 42
			var real15: Dictionary = _loader.call("get_wave", 15)
			_ok(not real15.is_empty(), "池解析/前置: waves.json wave15 非空")
			spawner.call("spawn_wave", real15, 15)
			_ok(spawner.spawn_queue.size() == 120, "池解析/真实wave15(swarm): 队列 120 = (56+4)×2（实得 %d）" % spawner.spawn_queue.size())
			# 队列条目 enemy 字段为池令牌（未展开 → 数据零破坏）
			var tokens_ok: bool = true
			for entry in spawner.spawn_queue:
				var eid: String = entry.get("enemy_id", "")
				if eid != "mixed" and eid != "elite:mixed":
					tokens_ok = false
			_ok(tokens_ok, "池解析/真实wave15: 队列保留池令牌（swarm 语义与池解析顺序兼容）")
			spawner.queue_free()
			return 8
		# ---------- §4 difficulty_delta 消费 ----------
		8:
			var spawner: Node = (load(SPAWNER_SCENE_PATH) as PackedScene).instantiate()
			spawner.name = "MockSpawner4"
			root.add_child(spawner)
			spawner.set("_rng", RandomNumberGenerator.new())
			spawner._rng.seed = 7
			# dd = 0 → chaser wave1: hp 3+2*1=5, dmg 3+0.6*1=3.6
			_gm.set("difficulty_delta", 0)
			var e0: Node = spawner.call("_create_enemy", "chaser", 1, null)
			_ok(e0 != null, "difficulty/前置: chaser 生成成功")
			if e0:
				_ok(absf(float(e0.get("max_health")) - 5.0) < 0.001 and absf(float(e0.get("damage")) - 3.6) < 0.001,
					"difficulty/dd=0: hp 5 / dmg 3.6 零影响（实得 %.2f/%.2f）" % [float(e0.get("max_health")), float(e0.get("damage"))])
				e0.queue_free()
			# dd = +1 → ×1.1
			_gm.set("difficulty_delta", 1)
			var e1: Node = spawner.call("_create_enemy", "chaser", 1, null)
			if e1:
				_ok(absf(float(e1.get("max_health")) - 5.5) < 0.001 and absf(float(e1.get("damage")) - 3.96) < 0.001,
					"difficulty/dd=+1: hp 5.5 / dmg 3.96 = ×1.1（实得 %.2f/%.2f）" % [float(e1.get("max_health")), float(e1.get("damage"))])
				e1.queue_free()
			# dd = -1 → ×0.9
			_gm.set("difficulty_delta", -1)
			var e2: Node = spawner.call("_create_enemy", "chaser", 1, null)
			if e2:
				_ok(absf(float(e2.get("max_health")) - 4.5) < 0.001, "difficulty/dd=-1: hp 4.5 = ×0.9（实得 %.2f）" % float(e2.get("max_health")))
				e2.queue_free()
			_gm.set("difficulty_delta", 0)
			spawner.queue_free()
			return 9
		# ---------- §5 回归锚点 ----------
		9:
			# 6 精英 behavior ∈ 9 枚举
			var behav_ok: bool = true
			for eid in ELITE_IDS:
				var data: Dictionary = _loader.call("get_enemy", eid)
				if not BEHAVIOR_KEYS.has(str(data.get("behavior", ""))):
					behav_ok = false
					print("  %s behavior 非法: %s" % [eid, data.get("behavior", "")])
			_ok(behav_ok, "回归: 6 精英 behavior ∈ 9 枚举")
			# is_elite 标记正确（initialize match category）
			var elite_stats := {
				"id": "butcher", "category": "elite", "max_health": 200.0, "damage": 8.0,
				"move_speed": 200.0, "behavior": "aoe_attack", "armor": 0,
			}
			var e3: Node = _build_enemy(elite_stats)
			_ok(e3.get("is_elite") == true and e3.get("is_boss") == false, "回归: elite 标记 is_elite=true / is_boss=false")
			# 精英数据 coin_value/exp 一致性抽查（08-07 金币产出数据化：coin_value 取代 drop 消费键）
			var butcher_d: Dictionary = _loader.call("get_enemy", "butcher")
			_ok(int(butcher_d.get("coin_value")) == 20 and int(butcher_d.get("exp_value")) == 30, "回归: butcher coin_value 20 / exp 30")
			e3.queue_free()
			return 10
		10:
			# elite 节点 wave_index ∈ [6,19]（生成路径：battle_count≥6 才可抽 elite →
			# 天然 ∈ [6,19]；种子随机可能全程无精英 → 条件断言，对齐 day14_15 口径）
			# F-27（2026-08-08 用户拍板）：15 关后普通层 1-14，精英可出现在 wave 11-14
			var route: Dictionary = _gen.generate_from(FIXED_SEED, _loader.get_routes())
			var elite_wi_ok: bool = true
			var boss_ok: bool = true
			var elite_found: bool = false
			var layers: Array = route.get("layers", [])
			for layer in layers:
				for node in layer:
					var t: String = str(node.get("type", ""))
					var wi: int = int(node.get("wave_index", -1))
					if t == "elite":
						elite_found = true
						if wi < 1 or wi > 14:
							elite_wi_ok = false
					if t == "boss" and wi != 10:
						boss_ok = false
			_ok(elite_wi_ok, "回归: 路线 elite 节点 wave_index ∈ [1,14]（条件断言，实含 %s）" % ("是" if elite_found else "否"))
			_ok(boss_ok, "回归: 路线 boss 节点 wave_index == 10")
			# 确定性覆盖：白盒构造路线 → force_node_type 强制精英 → wave_index 重映射 ∈ [1,19]（合法战斗映射）
			var route2: Dictionary = _gen.generate_from(1234, _loader.get_routes())
			var l1: Array = route2.get("layers")[1]
			var type_before: String = str(l1[0].get("type", ""))
			_gen.force_node_type(route2, 1, 0, "elite")
			var wi2: int = int(l1[0].get("wave_index"))
			_ok(str(l1[0].get("type")) == "elite" and wi2 >= 1 and wi2 <= 19,
				"回归: 强制 elite 后 wave_index 合法（%s→elite, wave=%d）" % [type_before, wi2])
			return 11
		_:
			return 31  # 结束哨兵
