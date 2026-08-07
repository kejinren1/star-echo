## 特效播放器
## 在指定位置播放一次性动画特效，播放完毕自动销毁
class_name VfxPlayer
extends Node2D

# ========== 导出属性 ==========

@export var autoplay: bool = true             ## 是否 _ready 时自动播放

# ========== 内部状态 ==========

var _anim: AnimatedSprite2D
var current_fx: String = ""      ## Day 23：最近一次 set_effect 的特效名（探针观测用，零行为影响）

# ========== 特效配置 ==========
## 特效名称 → 精灵配置
const FX_CONFIG: Dictionary = {
	"hit":      {"path": "res://assets/sprites/effects/fx_hit.png",      "frames": 4, "size": Vector2i(32, 32), "fps": 12.0},
	"crit":     {"path": "res://assets/sprites/effects/fx_crit.png",     "frames": 6, "size": Vector2i(32, 32), "fps": 12.0},
	"death":    {"path": "res://assets/sprites/effects/fx_death.png",    "frames": 4, "size": Vector2i(32, 32), "fps": 10.0},
	"levelup":  {"path": "res://assets/sprites/effects/fx_levelup.png",  "frames": 6, "size": Vector2i(32, 32), "fps": 10.0},
	"pickup":   {"path": "res://assets/sprites/effects/fx_pickup.png",   "frames": 4, "size": Vector2i(16, 16), "fps": 10.0},
	# Day 23（占位特效 · 用户 2026-08-07 拍板）：机制验证用，纯色占位图豁免色号编码
	"fireball":     {"path": "res://assets/sprites/effects/fx_fireball.png",      "frames": 6, "size": Vector2i(64, 64),   "fps": 12.0},
	"turret_deploy":{"path": "res://assets/sprites/effects/fx_turret_deploy.png", "frames": 4, "size": Vector2i(64, 64),   "fps": 10.0},
	"blade_burst":  {"path": "res://assets/sprites/effects/fx_blade_burst.png",   "frames": 6, "size": Vector2i(64, 64),   "fps": 12.0},
	"meteor":       {"path": "res://assets/sprites/effects/fx_meteor.png",        "frames": 6, "size": Vector2i(128, 128), "fps": 12.0},
	"shield":       {"path": "res://assets/sprites/effects/fx_shield.png",        "frames": 6, "size": Vector2i(64, 64),   "fps": 10.0},
}

# ========== 生命周期 ==========

func _ready() -> void:
	_anim = get_node_or_null("AnimatedSprite2D")
	if _anim and autoplay and _anim.sprite_frames:
		_anim.play("default")
		if not _anim.animation_finished.is_connected(queue_free):
			_anim.animation_finished.connect(queue_free)

# ========== 接口 ==========

## 设置特效类型并构建动画
func set_effect(fx_name: String) -> void:
	if not FX_CONFIG.has(fx_name):
		push_warning("[VfxPlayer] 未知特效类型: %s" % fx_name)
		return
	current_fx = fx_name
	var cfg: Dictionary = FX_CONFIG[fx_name]
	var tex := load(cfg["path"]) as Texture2D
	if not tex:
		return
	if not _anim:
		_anim = get_node_or_null("AnimatedSprite2D")
	if not _anim:
		return
	var sf := SpriteFrameFactory.create_from_sheet(
		tex, cfg["frames"], cfg["size"], cfg["fps"], false, "default"
	)
	_anim.sprite_frames = sf
	_anim.play("default")
	if not _anim.animation_finished.is_connected(queue_free):
		_anim.animation_finished.connect(queue_free)

## 在指定位置播放特效（静态便捷方法）
static func spawn(parent: Node, pos: Vector2, fx_name: String) -> Node:
	var vfx_scene := load("res://scenes/VfxPlayer.tscn") as PackedScene
	if not vfx_scene:
		return null
	var vfx := vfx_scene.instantiate()
	parent.add_child(vfx)
	vfx.global_position = pos
	vfx.set_effect(fx_name)
	return vfx
