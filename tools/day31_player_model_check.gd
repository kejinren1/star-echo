## PS · 局内模型定稿实装出口校验（2026-08-18：8-16 定稿 96px → 64px 帧动画）
## 校验：Player 实例化 → apply_character(se_ren) → AnimatedSprite2D 的
## idle/walk/attack/skill/hit 5 动画在位（player_anim 缺帧文件不追加），帧 64px
extends SceneTree

var _failures: int = 0
var _checked: int = 0
var _started: bool = false

func _initialize() -> void:
	print("=== Day31 player model (定稿) check ===")

func _process(_delta: float) -> bool:
	if _started:
		return false
	_started = true
	var scene: PackedScene = load("res://scenes/Player.tscn")
	if scene == null:
		_fail("Player.tscn 加载失败")
		quit(_failures)
		return true
	var p: Node = scene.instantiate()
	root.add_child(p)
	var loader: Node = root.get_node_or_null("DataLoader")
	var data: Dictionary = loader.call("get_character", "se_ren")
	if p.has_method("apply_character"):
		p.call("apply_character", data)
	var anim: Node = p.get_node_or_null("AnimatedSprite2D")
	if anim == null or anim.get("sprite_frames") == null:
		_fail("AnimatedSprite2D 未就绪（sprite_frames=null）")
		quit(_failures)
		return true
	var sf: SpriteFrames = anim.get("sprite_frames")
	var expect := ["idle", "walk", "attack", "skill", "hit"]
	for name in expect:
		if sf.has_animation(name):
			_ok("动画 %s 在位（%d 帧）" % [name, sf.get_frame_count(name)])
		else:
			_fail("动画 %s 缺失" % name)
	# 帧尺寸校验：idle 第一帧应为 64×64
	var tex: Texture2D = sf.get_frame_texture("idle", 0)
	if tex != null:
		if tex.get_width() == 64 and tex.get_height() == 64:
			_ok("idle 帧尺寸 64×64（定稿 64px 帧规格）")
		else:
			_fail("idle 帧尺寸 %dx%d，应为 64×64" % [tex.get_width(), tex.get_height()])
	print("检查 %d 项，失败 %d 项" % [_checked, _failures])
	quit(_failures)
	return true

func _ok(msg: String) -> void:
	_checked += 1
	print("  PASS  %s" % msg)

func _fail(msg: String) -> void:
	_failures += 1
	print("  FAIL  %s" % msg)
