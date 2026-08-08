## Day 29 反馈 1 探针：自动攻击索敌门控 + SKILL 动画守卫（F-32 · 用户 2026-08-09 直派）
## 背景：用户「艾琳几乎全程都是攻击动画」→ 根因 = weapon_controller 无索敌，射程内无敌人也
##       持续开火 → attack 动画占满；SKILL（空格技能）动画不明显 = 同根因（attack 每帧抢占 skill）。
## 修复：① _process 开火前 _has_enemy_in_range 门控（冷却仍递减，敌人进射程立即响应）
##       ② _play_attack_anim 在 skill 播放中禁止抢占（技能 6 帧可完整播放）
## §1 索敌门控矩阵（白盒 WeaponController + mock spawner/敌人/武器）
## §2 skill 动画守卫（真实 player + elin SpriteFrames）
## §3 回归锚点（文本 grep + 冷却语义白盒 = day13 兼容锚点）
## 用法（新路径铁律 --path "D:/30DAYS"）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path "D:/30DAYS" --script res://tools/day29_attack_check.gd
extends SceneTree

var _setup_done: bool = false
var _sub: int = 0
var _checked: int = 0
var _failures: int = 0

# §1 对象
var _wc: Node = null
var _owner: Node2D = null
var _fire_count: int = 0
var _mock_spawner: Node = null
var _container: Node2D = null
var _weapon: Resource = null

# §2 对象
var _player: Node = null


func _initialize() -> void:
	print("=== Day 29 fb1 check (attack gate + skill guard) ===")


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
	_ok(root.get_node_or_null("GameManager") != null, "GameManager autoload 在位")
	# ---- §1 白盒 WeaponController（不进树：避免 _ready 依赖真实父节点；手动推进 _process） ----
	_owner = Node2D.new()
	_owner.name = "MockOwner"
	_owner.global_position = Vector2.ZERO
	root.add_child(_owner)
	_wc = load("res://scripts/weapons/weapon_controller.gd").new()
	_wc.name = "MockWC"
	_wc.owner_node = _owner
	var pc := Node2D.new()
	pc.name = "ProjC"
	root.add_child(pc)
	_wc._projectile_container = pc
	_wc.weapon_fired.connect(_on_weapon_fired)
	# 武器：fire_rate 10（冷却 0.1s）/ 射程 100
	_weapon = load("res://scripts/weapons/weapon.gd").new()
	_weapon.fire_rate = 10.0
	_weapon.attack_range = 100.0
	_wc.equip_weapon(_weapon)
	# mock spawner（enemy_spawner.gd 脚本实例 extends Node2D，仅用 enemies_container）
	_mock_spawner = Node2D.new()
	_mock_spawner.set_script(load("res://scripts/enemy/enemy_spawner.gd"))
	_container = Node2D.new()
	_container.name = "MockEnemies"
	root.add_child(_container)
	_mock_spawner.enemies_container = _container
	root.get_node("GameManager").set("enemy_spawner", _mock_spawner)
	# ---- §2 真实 player（day29 范式） ----
	_player = CharacterBody2D.new()
	_player.name = "MockPlayer"
	_player.set_script(load("res://scripts/player/player.gd"))
	_player.max_health = 100000.0
	_player.move_speed = 300.0
	var anim2d := AnimatedSprite2D.new()
	anim2d.name = "AnimatedSprite2D"
	_player.add_child(anim2d)
	var sc: Node = load("res://scripts/player/skill_controller.gd").new()
	sc.name = "SkillController"
	_player.add_child(sc)
	root.add_child(_player)
	_player.call("_apply_character_sprite", "elin")


func _on_weapon_fired(_weapon: Resource) -> void:
	_fire_count += 1


func _advance(sub: int) -> int:
	match sub:
		0:
			_part_gate()
			return 1
		1:
			_part_skill_guard()
			return 2
		2:
			_part_regression()
			return 3
		3:
			_part_facing()
			return 10
		_:
			return 10
	return sub + 1


# ========== §1 索敌门控矩阵 ==========

func _add_enemy(pos: Vector2) -> Node2D:
	var e := Node2D.new()
	var s := GDScript.new()
	s.source_code = "extends Node2D\nvar is_alive: bool = true"
	s.reload()
	e.set_script(s)
	e.global_position = pos
	_container.add_child(e)
	return e


func _part_gate() -> void:
	# m1 无敌人 → 推进 3 次不开火
	_wc.call("_process", 0.5)
	_wc.call("_process", 0.5)
	_wc.call("_process", 0.5)
	_ok(_fire_count == 0, "§1 无敌人: _process×3 零开火（动画可回 idle/walk）")
	# m2 射程外敌人（300px > 100 射程）→ 不开火
	var far := _add_enemy(Vector2(0.0, 300.0))
	_wc.call("_process", 0.5)
	_wc.call("_process", 0.5)
	_ok(_fire_count == 0, "§1 射程外(300>100): 零开火")
	# m3 射程内敌人（50px）→ 立即开火
	far.global_position = Vector2(0.0, 50.0)
	_wc.call("_process", 0.5)
	_ok(_fire_count == 1, "§1 射程内(50<=100): 开火 1 次（实得 %d）" % _fire_count)
	_wc.call("_process", 0.5)
	_ok(_fire_count == 2, "§1 射程内持续: 开火 2 次（实得 %d）" % _fire_count)
	# m4 冷却语义（day13 兼容锚点）：无敌人时冷却照常递减（can_fire 先于门控执行）
	_weapon.set("_cooldown", 1.0)
	for c in _container.get_children():
		_container.remove_child(c)
		c.free()
	_wc.call("_process", 0.5)
	var cd_left: float = float(_weapon.get("_cooldown"))
	_ok(absf(cd_left - 0.5) < 0.001, "§1 冷却语义: 无敌人 _process(0.5) 冷却 1.0→%.2f（递减保留，day13 锚点）" % cd_left)


# ========== §2 SKILL 动画守卫 ==========

func _part_skill_guard() -> void:
	var anim: AnimatedSprite2D = _player.get_node_or_null("AnimatedSprite2D")
	if anim == null or anim.sprite_frames == null:
		_fail("§2: 无 AnimatedSprite2D / SpriteFrames")
		return
	# 播 skill → attack 不抢占
	_player.call("_play_skill_anim", "fireball")
	if anim.animation != "skill":
		_fail("§2 skill 动画未生效（实得 %s）" % anim.animation)
		return
	_player.call("_play_attack_anim")
	_ok(anim.animation == "skill", "§2 skill 播放中 _play_attack_anim 不抢占（实得 %s，SKILL 6 帧可完整播放）" % anim.animation)
	# skill 播完回 idle 后 attack 正常
	anim.play("idle")
	_player.call("_play_attack_anim")
	_ok(anim.animation == "attack", "§2 skill 结束后 attack 正常播放（实得 %s）" % anim.animation)
	# attack 播放中重复调用不重播（原守卫保留）
	_player.call("_play_attack_anim")
	_ok(anim.animation == "attack", "§2 attack 播放中重复调用不重播（实得 %s）" % anim.animation)
	# hit 降级不受影响：attack 播放中受击 → 仍 attack（day29 逻辑保留）
	_player.set("health", 1000.0)
	_player.set("is_alive", true)
	_player.set("_invulnerable_timer", 0.0)
	_player.call("_play_hit_anim")
	_ok(anim.animation == "attack", "§2 attack 播放中 _play_hit_anim 降级跳过（实得 %s，day29 逻辑保留）" % anim.animation)


# ========== §3 回归锚点 ==========

func _part_regression() -> void:
	var wc_txt: String = FileAccess.get_file_as_string("res://scripts/weapons/weapon_controller.gd")
	_ok(wc_txt.contains("_has_enemy_in_range"), "§3 文本: weapon_controller 含 _has_enemy_in_range")
	_ok(wc_txt.contains("if not _has_enemy_in_range(weapon.attack_range)"), "§3 文本: _process 索敌门控行在位（can_fire 之后）")
	var pl_txt: String = FileAccess.get_file_as_string("res://scripts/player/player.gd")
	_ok(pl_txt.contains('if _anim.animation in ["attack", "skill"]:'), "§3 文本: player _play_attack_anim 含 skill 守卫")
	_ok(pl_txt.contains("func _play_skill_anim"), "§3 文本: _play_skill_anim 保留")


# ========== §4 左右转向（F-33） ==========

func _part_facing() -> void:
	var anim: AnimatedSprite2D = _player.get_node_or_null("AnimatedSprite2D")
	if anim == null:
		_fail("§4 转向: 无 AnimatedSprite2D")
		return
	# 初始：原图默认朝左（flip_h false）
	_ok(not anim.flip_h, "§4 转向: 初始 flip_h=false（原图朝左）")
	# 向右移动 → 镜像朝右
	_player.velocity = Vector2(120.0, 0.0)
	_player.call("_update_facing")
	_ok(anim.flip_h, "§4 转向: 向右移动 → flip_h=true（镜像朝右）")
	# 向左移动 → 恢复原图朝左
	_player.velocity = Vector2(-120.0, 0.0)
	_player.call("_update_facing")
	_ok(not anim.flip_h, "§4 转向: 向左移动 → flip_h=false（原图朝左）")
	# 竖直移动 → 保持最后朝向
	_player.velocity = Vector2(0.0, 120.0)
	_player.call("_update_facing")
	_ok(not anim.flip_h, "§4 转向: 竖直移动保持最后朝向（flip_h 不变）")
	# _facing_left 状态同步
	_ok(bool(_player.get("_facing_left")) == (not anim.flip_h), "§4 转向: _facing_left 与 flip_h 状态一致")


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
