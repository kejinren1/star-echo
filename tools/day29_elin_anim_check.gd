## Day 29 出口校验：艾琳 JPG 全动画实装（idle 5 / walk 10 / attack 5 / skill 6 / hit 2）
##
## 用法（无头，不需要编辑器）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day29_elin_anim_check.gd
##
## 校验内容（用户 2026-08-08 21:0x 直派：ART/RAW/elin 28 帧 JPG → 5 sheet）：
##   §1 资产：elin_idle 320×64(5) / elin_walk 640×64(10) / elin_attack 320×64(5) /
##      elin_skill 384×64(6) / elin_hit 128×64(2) 尺寸 + 每帧非空 + (0,0) 透明键
##   §2 接线：_apply_character_sprite("elin") 白盒 → SpriteFrames 注册 5 动画
##      （idle/walk/attack/skill/hit），帧数 = 5/10/5/6/2，attack/skill/hit 非循环
##   §3 hit 状态机：take_damage → animation == "hit"（红闪保留）→ 播完 _on_anim_finished
##      → 回 idle；攻击中受击不打断 attack（降级）；缺帧前缀 → 无 hit 动画
##   §4 回归锚点：day21_22 探针 §3 尺寸断言已同步（elin idle 320×64）；player.gd
##      _update_animation/_on_anim_finished 含 "hit" 分支（grep 文本锚点）
##
## 退出码 0 = 全部通过；非 0 = 失败项数。
extends SceneTree

var _idx: int = 0
var _sub: int = 0
var _player: Node = null
var _checked: int = 0
var _failures: int = 0
var _expect_loaded: bool = false

# 期望 sheet：(宽, 高, 帧数)
const SHEET_EXPECT: Dictionary = {
	"idle": Vector3i(320, 64, 5),
	"walk": Vector3i(640, 64, 10),
	"attack": Vector3i(320, 64, 5),
	"skill": Vector3i(384, 64, 6),
	"hit": Vector3i(128, 64, 2),
}


func _initialize() -> void:
	print("=== Day 29 elin JPG full-anim check ===")


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
	if root.get_node_or_null("DataLoader") == null:
		_fail("DataLoader autoload 缺失")
		_report()
		quit(_failures)
		return
	# mock player（同 day21_22 范式：子节点先挂再 add_child）
	_player = CharacterBody2D.new()
	_player.name = "MockPlayer"
	_player.set_script(load("res://scripts/player/player.gd"))
	_player.max_health = 1000.0
	_player.move_speed = 300.0
	var anim2d := AnimatedSprite2D.new()
	anim2d.name = "AnimatedSprite2D"
	_player.add_child(anim2d)
	var sc: Node = load("res://scripts/player/skill_controller.gd").new()
	sc.name = "SkillController"
	_player.add_child(sc)
	root.add_child(_player)


func _advance(sub: int) -> int:
	match sub:
		0:
			_part_assets()
			return 1
		1:
			_part_animations()
			return 2
		2:
			_part_hit_state()
			return 3
		3:
			_part_regression()
			return 4
		_:
			_idx += 1
			return 0
	return sub + 1


# ========== 工具 ==========

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


func _png_size(res_path: String) -> Vector2i:
	var abs_path: String = ProjectSettings.globalize_path(res_path)
	var img := Image.load_from_file(abs_path)
	if img == null:
		return Vector2i(-1, -1)
	return img.get_size()


func _frame_nonempty(res_path: String, frames: int, fsize: Vector2i) -> bool:
	var abs_path: String = ProjectSettings.globalize_path(res_path)
	var img := Image.load_from_file(abs_path)
	if img == null:
		return false
	for i in frames:
		var nonempty := false
		for y in fsize.y:
			for x in fsize.x:
				if img.get_pixel(i * fsize.x + x, y).a > 0.0:
					nonempty = true
					break
			if nonempty:
				break
		if not nonempty:
			print("    %s 第 %d 帧全空" % [res_path.get_file(), i + 1])
			return false
	return true


# ========== §1 资产 ==========

func _part_assets() -> void:
	var ok_all: bool = true
	for name: String in SHEET_EXPECT:
		var e: Vector3i = SHEET_EXPECT[name]
		var path: String = "res://assets/sprites/characters/elin_%s.png" % name
		var size: Vector2i = _png_size(path)
		if size != Vector2i(e.x, e.y):
			ok_all = false
			print("    elin_%s 尺寸 %s != %dx%d" % [name, size, e.x, e.y])
		if not _frame_nonempty(path, e.z, Vector2i(64, 64)):
			ok_all = false
		# 透明键协议：左上角 (0,0) 透明
		var abs_path: String = ProjectSettings.globalize_path(path)
		var img := Image.load_from_file(abs_path)
		if img == null or img.get_pixel(0, 0).a > 0.0:
			ok_all = false
			print("    elin_%s 左上角 (0,0) 非透明（透明键协议违反）" % name)
	_ok(ok_all, "§1 资产: elin 5 sheet 尺寸/帧非空/透明键全合规（idle 320×64·5 / walk 640×64·10 / attack 320×64·5 / skill 384×64·6 / hit 128×64·2）")


# ========== §2 动画接线 ==========

func _part_animations() -> void:
	_player.call("_apply_character_sprite", "elin")
	var anim: AnimatedSprite2D = _player.get_node_or_null("AnimatedSprite2D")
	if anim == null or anim.sprite_frames == null:
		_fail("§2 接线: MockPlayer 无 AnimatedSprite2D / SpriteFrames")
		return
	var sf: SpriteFrames = anim.sprite_frames
	var names: Array = []
	for n in sf.get_animation_names():
		names.append(n)
	var expect_names: Array = ["idle", "walk", "attack", "skill", "hit"]
	var all_have: bool = true
	for n in expect_names:
		if not sf.has_animation(n):
			all_have = false
			print("    缺动画: %s" % n)
	_ok(all_have, "§2 接线: SpriteFrames 注册 5 动画 idle/walk/attack/skill/hit（实得 %s）" % str(names))
	# 帧数：idle 5 / walk 10 / attack 5 / skill 6 / hit 2
	var frames_ok: bool = true
	for n: String in SHEET_EXPECT:
		var expect_frames: int = SHEET_EXPECT[n].z
		if sf.get_frame_count(n) != expect_frames:
			frames_ok = false
			print("    %s 帧数 %d != %d" % [n, sf.get_frame_count(n), expect_frames])
	_ok(frames_ok, "§2 接线: 5 动画帧数 = 5/10/5/6/2（_sheet_meta 自动推断）")
	# 循环标志：attack/skill/hit 非循环，idle/walk 循环
	var loop_ok: bool = true
	for n in ["attack", "skill", "hit"]:
		if sf.get_animation_loop(n):
			loop_ok = false
			print("    %s 应为非循环" % n)
	for n in ["idle", "walk"]:
		if not sf.get_animation_loop(n):
			loop_ok = false
			print("    %s 应为循环" % n)
	_ok(loop_ok, "§2 接线: attack/skill/hit 非循环 + idle/walk 循环")


# ========== §3 hit 状态机 ==========

func _part_hit_state() -> void:
	var anim: AnimatedSprite2D = _player.get_node_or_null("AnimatedSprite2D")
	if anim == null:
		_fail("§3 hit: 无 AnimatedSprite2D")
		return
	# 受击 → hit 动画（红闪由 _play_hit_flash 保留，此处验证动画切换）
	_player.set("health", 1000.0)
	_player.set("is_alive", true)
	_player.set("_invulnerable_timer", 0.0)
	_player.call("_play_attack_anim")
	if anim.animation != "attack":
		_fail("§3 hit: 前置 attack 动画未生效（实得 %s）" % anim.animation)
		return
	# 攻击中受击 → 不打断 attack（降级规则）
	_player.call("_play_hit_anim")
	_ok(anim.animation == "attack", "§3 hit: 攻击中受击不打断（_play_hit_anim 降级跳过，实得 %s）" % anim.animation)
	_player.call("_on_anim_finished")
	if anim.animation != "idle":
		_fail("§3 hit: attack 播完未回 idle（实得 %s）" % anim.animation)
		return
	# 静止受击 → hit 动画
	_player.call("_play_hit_anim")
	_ok(anim.animation == "hit", "§3 hit: 静止受击 → animation == \"hit\"（实得 %s）" % anim.animation)
	# 播完 → 回 idle 且状态复位 IDLE（F3-T6：_is_walking 归并 _state）
	_player.call("_on_anim_finished")
	_ok(anim.animation == "idle" and int(_player.get("_state")) == 0,
		"§3 hit: hit 播完 → 回 idle 且状态复位 IDLE（F3-T6 同步）")
	# 再受击 → 重新播 hit（重复受击不卡死）
	_player.call("_play_hit_anim")
	_ok(anim.animation == "hit", "§3 hit: 重复受击可重播 hit（实得 %s）" % anim.animation)
	_player.call("_on_anim_finished")
	# 缺帧前缀 → 无 hit 动画（D19① 守卫同 attack/skill）
	_player.set("_sprite_prefix", "no_such_hero")
	_player.call("_setup_animation")
	var sf: SpriteFrames = anim.sprite_frames
	_ok(not sf.has_animation("hit") and not sf.has_animation("attack") and not sf.has_animation("skill"),
		"§3 hit: 缺帧前缀 → 无 hit/attack/skill 动画（D19① 守卫）")
	_player.set("_sprite_prefix", "elin")
	_player.call("_setup_animation")


# ========== §4 回归锚点 ==========

func _part_regression() -> void:
	# day21_22 探针 §3 已同步 elin idle 320×64
	var d2122: String = FileAccess.get_file_as_string("res://tools/day21_22_art_check.gd")
	_ok(d2122.find("Vector2i(320, 64)") >= 0, "§4 回归: day21_22 探针 §3 elin idle 断言已同步 320×64")
	# F4-C 拆分：状态机迁 player_anim.gd（player.gd 保留薄委托）——双文件文本锚点
	var pg: String = FileAccess.get_file_as_string("res://scripts/player/player.gd")
	var panim: String = FileAccess.get_file_as_string("res://scripts/player/player_anim.gd")
	_ok(pg.find("\"attack\", \"skill\", \"hit\"") >= 0 or panim.find("\"attack\", \"skill\", \"hit\"") >= 0,
		"§4 回归: player_anim.gd _update_animation 含 hit 禁打断分支")
	_ok(pg.find("func _play_hit_anim") >= 0, "§4 回归: player.gd 含 _play_hit_anim 方法")
	_ok(pg.find("_play_hit_anim()") > pg.find("func _play_hit_anim"), "§4 回归: take_damage 调用 _play_hit_anim（触发点接线）")
	# 生成管线在册（用户直派工具）
	var tool: String = FileAccess.get_file_as_string("res://tools/gen_elin_anim_jpg.py")
	_ok(tool.find("BG_TOL = 100") >= 0, "§4 回归: gen_elin_anim_jpg.py 抠底容差 100（用户拍板默认）")
