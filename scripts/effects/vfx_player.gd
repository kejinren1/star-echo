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

## F-45（2026-08-18 用户拍板）：特效手感覆盖——不动 FX_CONFIG 键结构
## （day23_vfx_check 10 键硬门槛），仅对指定特效叠加视觉手感：
##   scale  整体缩放（调小）
##   alpha  初始透明度（半透明）
##   fade   动画播完后的渐隐时长（秒；>0 = 渐变消失，不再突然消失）
const FX_FEEL_OVERRIDE: Dictionary = {
	"hit": {"scale": 0.6, "alpha": 0.55, "fade": 0.25},
}

## 渐隐时长（秒；0 = 播完直接销毁，原行为）
var _fade_time: float = 0.0

# ========== 生命周期 ==========

func _ready() -> void:
	_anim = get_node_or_null("AnimatedSprite2D")
	if _anim and autoplay and _anim.sprite_frames:
		_anim.play("default")
		if not _anim.animation_finished.is_connected(_on_anim_finished):
			_anim.animation_finished.connect(_on_anim_finished)

# ========== 接口 ==========

## 设置特效类型并构建动画
func set_effect(fx_name: String) -> void:
	if not FX_CONFIG.has(fx_name):
		push_warning("[VfxPlayer] 未知特效类型: %s" % fx_name)
		return
	current_fx = fx_name
	# F1-E-4（2026-08-19 #3 执行）：帧配置改读 DataLoader.get_fx_config（presentation.json
	# fx_config 优先；未命中/空表回退 FX_CONFIG const 兜底——F 系列缺省兜底约定，抽表后旧值仍可启动）
	var cfg: Dictionary = _resolve_fx_config(fx_name)
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
	# F-45（2026-08-18 用户拍板）：特效手感覆盖——调小/半透明/渐隐（hit 普攻命中特效）
	var feel: Dictionary = FX_FEEL_OVERRIDE.get(fx_name, {})
	if not feel.is_empty():
		scale = Vector2.ONE * float(feel.get("scale", 1.0))
		modulate = Color(1.0, 1.0, 1.0, float(feel.get("alpha", 1.0)))
	_fade_time = float(feel.get("fade", 0.0))
	if not _anim.animation_finished.is_connected(_on_anim_finished):
		_anim.animation_finished.connect(_on_anim_finished)

## 动画播完：fade>0 → 渐隐后销毁（渐变消失，不突然消失，F-45）；否则直接销毁（原行为）
func _on_anim_finished() -> void:
	if _fade_time > 0.0:
		var tween := create_tween()
		tween.tween_property(self, "modulate:a", 0.0, _fade_time)
		tween.chain().tween_callback(queue_free)
	else:
		queue_free()

## F1-E-4（2026-08-19 #3 执行）：帧配置解析——presentation.json fx_config（经
## DataLoader.get_fx_config）命中优先；未命中/空表/无 DataLoader → 回退 FX_CONFIG
## const 兜底（F 系列缺省兜底约定，仿 audio_manager._resolve_audio_path 范式）。
func _resolve_fx_config(fx_name: String) -> Dictionary:
	var loader: Node = get_node_or_null("/root/DataLoader")
	if loader != null and loader.has_method("get_fx_config"):
		var cfg: Dictionary = loader.get_fx_config(fx_name)
		if not cfg.is_empty() and cfg.has("path") and cfg.has("frames"):
			return cfg
	return FX_CONFIG[fx_name]

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
