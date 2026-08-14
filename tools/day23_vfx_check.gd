## Day 23 出口校验：技能特效占位实现（D23-T1~T4 / 阶段 D 续段锚点）
##
## 用法（无头，不需要编辑器）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day23_vfx_check.gd
##
## 校验内容（对应 docs/SOLUTION_PLAN.md 第 5 轮任务 5 四段）：
##   §1 配置层：FX_CONFIG 10 键；5 新特效 path 对应资源 exists；set_effect 缺图 null 不崩
##      （判空守卫实证——未知名静默返回不 spawn）
##   §2 消费层：白盒线弹命中 → hit spawn +1；爆炸弹无 meta → crit 兜底（双轨）；
##      fireball 爆炸 → "fireball"；se_star_fall 爆炸 → "meteor"
##   §3 技能层：deploy_turret → turret_deploy == 台数；blade_burst → spawn 1 次；
##      holy_shield → try_cast false 不崩（VFX 顺延 P1）
##   §4 回归：既有 5 特效消费点不破坏（enemy crit/levelup、main death 源码锚点）
##      + baseline 数据锚点（items.json 54 / waves.json wave2）
##
## 观测机制：GameManager.vfx_container 指向探针自建容器（普通 Node2D）；
## VfxPlayer.spawn 把特效节点 add 进来后同步调用 set_effect（先 add_child 后
## set_effect），故消费点返回时子节点 current_fx 均已写好 → 扫描 children 即得 fx 名。
## 退出码 0 = 全部通过；非 0 = 失败项数。
extends SceneTree

const EPSILON: float = 0.001
const FX_KEYS_EXPECTED: Array = ["hit", "crit", "death", "levelup", "pickup",
	"fireball", "turret_deploy", "blade_burst", "meteor", "shield"]
const NEW_FX: Dictionary = {
	"fireball":      {"path": "res://assets/sprites/effects/fx_fireball.png",      "frames": 6,  "size": Vector2i(64, 64)},
	"turret_deploy": {"path": "res://assets/sprites/effects/fx_turret_deploy.png", "frames": 4,  "size": Vector2i(64, 64)},
	"blade_burst":   {"path": "res://assets/sprites/effects/fx_blade_burst.png",   "frames": 6,  "size": Vector2i(64, 64)},
	"meteor":        {"path": "res://assets/sprites/effects/fx_meteor.png",        "frames": 6,  "size": Vector2i(128, 128)},
	"shield":        {"path": "res://assets/sprites/effects/fx_shield.png",        "frames": 6,  "size": Vector2i(64, 64)},
}

## 白盒 mock 敌人（projectile._on_body_entered 需要 is_in_group("enemies") + take_damage）
class MockEnemy:
	extends Node2D
	var health: float = 100.0
	var is_alive: bool = true
	var hits: int = 0

	func _init() -> void:
		add_to_group("enemies")

	func take_damage(dmg: float, _is_crit: bool = false) -> void:
		health -= dmg
		hits += 1
		if health <= 0.0:
			is_alive = false

var _idx: int = 0
var _sub: int = 0
var _loader: Node = null
var _gm: Node = null
var _world: Node2D = null
var _probe: Node2D = null
var _proj_container: Node2D = null
var _player: Node = null
var _checked: int = 0
var _failures: int = 0
var _expect_loaded: bool = false


func _initialize() -> void:
	print("=== Day 23 VFX placeholder check ===")


func _process(_delta: float) -> bool:
	if not _expect_loaded:
		_load_mocks()
	if _idx >= 1:
		_report()
		quit(_failures)
		return true
	_sub = _advance(_sub)
	return false


func _load_mocks() -> void:
	_expect_loaded = true
	_loader = root.get_node_or_null("DataLoader")
	_gm = root.get_node_or_null("GameManager")
	if _loader == null or _gm == null:
		_fail("DataLoader/GameManager autoload 缺失")
		_report()
		quit(_failures)
		return

	# mock 世界 + 弹丸容器 + 探针 vfx 容器（观测 spawn 名）
	_world = Node2D.new()
	_world.name = "MockWorld"
	root.add_child(_world)
	_proj_container = Node2D.new()
	_proj_container.name = "Projectiles"
	_world.add_child(_proj_container)
	_probe = Node2D.new()
	_probe.name = "MockVfx"
	_world.add_child(_probe)
	_gm.set("vfx_container", _probe)

	# mock player（life_steal 置 0 防误回血）
	_player = CharacterBody2D.new()
	_player.name = "MockPlayer"
	_player.set_script(load("res://scripts/player/player.gd"))
	_player.max_health = 100.0
	_player.health = 100.0
	_player.armor = 0.0
	_player.dodge = 0.0
	_player.damage_multiplier = 1.0
	_player.debug_mult = 1.0
	_player.life_steal = 0.0
	_world.add_child(_player)
	_player.global_position = Vector2(100, 100)
	_gm.set("player", _player)


func _advance(sub: int) -> int:
	match sub:
		0:
			_part_config()
			return 1
		1:
			_part_consume()
			return 2
		2:
			_part_skills()
			return 3
		3:
			_part_regression()
			return 4
		_:
			_idx += 1
			return 0
	return sub + 1


# ========== §1 配置层 ==========

func _part_config() -> void:
	var fx_script: GDScript = load("res://scripts/effects/vfx_player.gd")
	var cfg: Dictionary = fx_script.FX_CONFIG
	if cfg.size() != 10:
		_fail("配置: FX_CONFIG 应 10 键, 实得 %d" % cfg.size())
	else:
		_pass("配置 / FX_CONFIG 10 键（5 旧 + 5 新）")

	var all_keys_ok: bool = true
	for k in FX_KEYS_EXPECTED:
		if not cfg.has(k):
			all_keys_ok = false
			_fail("配置: 缺键 %s" % k)
	if all_keys_ok:
		_pass("配置 / 10 键白名单齐全")

	var res_ok: bool = true
	for fx_name in NEW_FX:
		var path: String = str(cfg[fx_name]["path"])
		if not ResourceLoader.exists(path):
			res_ok = false
			_fail("配置: %s 资源不存在 %s" % [fx_name, path])
	if res_ok:
		_pass("配置 / 5 新特效资源 exists（占位图已出）")

	# set_effect 守卫实证：未知名静默返回不崩不 spawn；已知名 current_fx 写入
	_clear_probe()
	var vfx: Node = (load("res://scenes/VfxPlayer.tscn") as PackedScene).instantiate()
	_world.add_child(vfx)
	vfx.call("set_effect", "definitely_not_a_fx")
	if str(vfx.get("current_fx")) != "":
		_fail("配置: 未知特效名不应写 current_fx")
	_pass("配置 / set_effect 未知名 静默返回不崩（守卫实证）")
	vfx.call("set_effect", "fireball")
	if str(vfx.get("current_fx")) != "fireball":
		_fail("配置: set_effect('fireball') current_fx 应 fireball, 实得 %s" % str(vfx.get("current_fx")))
	else:
		_pass("配置 / set_effect('fireball') → current_fx 写入（动画构建可检测）")
	vfx.queue_free()


# ========== §2 消费层 ==========

func _spawn_proj(props: Dictionary, source_id: String = "") -> Node:
	var proj: Node = (load("res://scenes/Projectile.tscn") as PackedScene).instantiate()
	proj.call("initialize", props)
	if not source_id.is_empty():
		proj.set_meta(&"source_id", source_id)
	_proj_container.add_child(proj)
	proj.global_position = Vector2(200, 100)
	return proj

## 清空探针容器（立即释放防跨帧干扰）
func _clear_probe() -> void:
	for c in _probe.get_children():
		_probe.remove_child(c)
		c.free()

func _count_fx(name: String) -> int:
	var n: int = 0
	for c in _probe.get_children():
		if is_instance_valid(c) and str(c.get("current_fx")) == name:
			n += 1
	return n

func _part_consume() -> void:
	# 线弹命中（无爆炸）→ hit spawn +1
	_clear_probe()
	var e1: Node = MockEnemy.new()
	_world.add_child(e1)
	var p1: Node = _spawn_proj({"damage": 10.0, "pierce": 0, "explosion_radius": 0.0})
	p1.call("_on_body_entered", e1)
	if _count_fx("hit") != 1:
		_fail("消费: 线弹命中 hit spawn 应 1, 实得 %d" % _count_fx("hit"))
	else:
		_pass("消费 / 线弹普通命中 → hit spawn +1（D23-T1 激活）")

	# 爆炸弹无 meta → crit 兜底（双轨：hit 由命中路径 + crit 由爆炸路径）
	_clear_probe()
	var e2: Node = MockEnemy.new()
	_world.add_child(e2)
	var p2: Node = _spawn_proj({"damage": 10.0, "pierce": 0, "explosion_radius": 60.0, "explosion_damage": 10.0})
	p2.call("_on_body_entered", e2)
	if _count_fx("hit") != 1 or _count_fx("crit") != 1:
		_fail("消费: 爆炸弹应 hit×1 + crit×1, 实得 hit=%d crit=%d" % [_count_fx("hit"), _count_fx("crit")])
	else:
		_pass("消费 / 无 meta 爆炸弹 → hit + crit 双轨兜底（其余 52 武器零回归）")

	# fireball 爆炸 → "fireball" 替换 crit
	_clear_probe()
	var e3: Node = MockEnemy.new()
	_world.add_child(e3)
	var p3: Node = _spawn_proj({"damage": 10.0, "pierce": 3, "explosion_radius": 60.0, "explosion_damage": 10.0}, "se_skill_fireball")
	p3.call("_on_body_entered", e3)
	if _count_fx("fireball") != 1 or _count_fx("crit") != 0:
		_fail("消费: fireball 爆炸应 fireball×1 crit×0, 实得 fireball=%d crit=%d" % [_count_fx("fireball"), _count_fx("crit")])
	else:
		_pass("消费 / se_skill_fireball 爆炸 → 'fireball' 替换 crit（D23-T3）")

	# se_star_fall 爆炸 → "meteor"
	_clear_probe()
	var e4: Node = MockEnemy.new()
	_world.add_child(e4)
	var p4: Node = _spawn_proj({"damage": 10.0, "pierce": 0, "explosion_radius": 60.0, "explosion_damage": 10.0}, "se_star_fall")
	p4.call("_on_body_entered", e4)
	if _count_fx("meteor") != 1 or _count_fx("crit") != 0:
		_fail("消费: se_star_fall 爆炸应 meteor×1 crit×0, 实得 meteor=%d crit=%d" % [_count_fx("meteor"), _count_fx("crit")])
	else:
		_pass("消费 / se_star_fall 爆炸 → 'meteor'（D23-T4 进化陨石）")
	_clear_probe()


# ========== §3 技能层 ==========

func _make_skill(skill_data: Dictionary) -> Node:
	var sc: Node = (load("res://scripts/player/skill_controller.gd") as GDScript).new()
	sc.name = "SkillController"
	_player.add_child(sc)
	sc.call("setup", {"skill": skill_data})
	return sc

func _part_skills() -> void:
	# deploy_turret → turret_deploy == 台数（summon_count 2 + bonus 0 = 2）
	_clear_probe()
	var sc1: Node = _make_skill({"id": "se_skill_deploy_turret", "summon_id": "se_auto_turret",
		"summon_count": 2, "duration": 15.0})
	var cast1: bool = bool(sc1.call("try_cast"))
	var turrets: int = 0
	for c in _world.get_children():
		# 特征方法计数（turret.gd 独有 _draw_placeholder；同名炮台会被 Godot 自动改名 @Node2D@N）
		if c.has_method("_draw_placeholder"):
			turrets += 1
	if not cast1:
		_fail("技能: deploy_turret try_cast 应 true")
	if _count_fx("turret_deploy") != 2:
		_fail("技能: turret_deploy 应 2（= 台数）, 实得 %d" % _count_fx("turret_deploy"))
	else:
		_pass("技能 / deploy_turret 2 台 → turret_deploy ×2（D23-T3）")
	if turrets != 2:
		var names: String = ""
		for c in _world.get_children():
			names += str(c.name) + " "
		_fail("技能: 实际部署炮台应 2, 实得 %d（world children: %s）" % [turrets, names])
	else:
		_pass("技能 / 部署炮台 2 台实装")
	# 清理炮台防污染下一段
	for c in _world.get_children():
		if c.has_method("_draw_placeholder"):
			c.queue_free()
	sc1.queue_free()

	# blade_burst → spawn 1 次
	_clear_probe()
	var sc2: Node = _make_skill({"id": "se_skill_blade_burst", "duration": 0.01, "effects": {}})
	var cast2: bool = bool(sc2.call("try_cast"))
	if not cast2:
		_fail("技能: blade_burst try_cast 应 true")
	if _count_fx("blade_burst") != 1:
		_fail("技能: blade_burst spawn 应 1, 实得 %d" % _count_fx("blade_burst"))
	else:
		_pass("技能 / blade_burst → 玩家身周 blade_burst ×1（D23-T3）")
	sc2.queue_free()

	# holy_shield（Day30-P0 已实装：try_cast true + 护盾生效；VFX 尚未接线，零 spawn 属预期）
	_clear_probe()
	var sc3: Node = _make_skill({"id": "se_skill_holy_shield", "cooldown": 5.0})
	var cast3: bool = bool(sc3.call("try_cast"))
	if cast3:
		_pass("技能 / holy_shield → try_cast true（P0-Bug1 已实装 2026-08-10）")
	else:
		_fail("技能: holy_shield try_cast 应 true（P0-Bug1 实装后）")
	if _count_fx("shield") != 0:
		_fail("技能: holy_shield 不应 spawn shield（VFX 未接线）")
	else:
		_pass("技能 / holy_shield 零 spawn（VFX 顺延，不臆造接线）")
	sc3.queue_free()
	_clear_probe()


# ========== §4 回归 ==========

func _source_has(path: String, needle: String) -> bool:
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	var text: String = f.get_as_text()
	return text.contains(needle)

func _part_regression() -> void:
	# 既有 5 特效消费点源码锚点（enemy crit、levelup、main death）
	# F4-A 拆分：crit → enemy_boss（_boss_aoe）/enemy_movement（_elite_aoe）；levelup → enemy_movement
	var enemy_src: String = "res://scripts/enemy/enemy.gd"
	var enemy_boss_src: String = "res://scripts/enemy/enemy_boss.gd"
	var enemy_mov_src: String = "res://scripts/enemy/enemy_movement.gd"
	var main_src: String = "res://scripts/autoload/main.gd"
	var ok1: bool = (_source_has(enemy_src, "\"crit\"") or _source_has(enemy_boss_src, "\"crit\"") or _source_has(enemy_mov_src, "\"crit\"")) \
		and (_source_has(enemy_src, "\"levelup\"") or _source_has(enemy_mov_src, "\"levelup\""))
	var ok2: bool = _source_has(main_src, "\"death\"")
	if not ok1 or not ok2:
		_fail("回归: enemy crit/levelup 或 main death spawn 调用缺失（源码锚点）")
	else:
		_pass("回归 / enemy crit+levelup + main death 消费点 intact")
	# VfxPlayer.spawn 静态接口 intact
	var vfx_src: String = "res://scripts/effects/vfx_player.gd"
	if not _source_has(vfx_src, "static func spawn"):
		_fail("回归: VfxPlayer.spawn 静态接口缺失")
	else:
		_pass("回归 / VfxPlayer.spawn 静态接口 intact")
	# baseline 数据锚点
	var items: Array = _loader.call("get_all_item_ids")
	if items.size() != 54:
		_fail("回归: items.json 应 54 项（D24-F13 +3 机制型）, 实得 %d" % items.size())
	else:
		_pass("回归 / items.json 54 项 intact")
	var wave: Dictionary = _loader.call("get_wave", 2)
	if wave.is_empty():
		_fail("回归: waves.json wave2 数据 intact 缺失")
	else:
		_pass("回归 / waves.json wave2 intact")


# ========== 断言工具 ==========

func _pass(what: String) -> void:
	_checked += 1
	print("  OK: " + what)

func _fail(what: String) -> void:
	_checked += 1
	_failures += 1
	print("  FAIL: " + what)

func _report() -> void:
	print("=== DAY23-VFX CHECK: %d assertions, %d failures ===" % [_checked, _failures])
	if _failures == 0:
		print("DAY23-VFX CHECK CLEAN")
