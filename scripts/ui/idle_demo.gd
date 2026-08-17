## L1 引擎动画演示（2026-08-14 · 帧序列呼吸 vs 程序化呼吸 对照）
## 用途：验证 AI 动画帧序列（docs/art_ai → build_anim_sheet.py → sheet）接入引擎
##       + 演示 L1 程序化动画（单帧 + sin 位移）。非游戏流程场景，零侵入。
## 运行：tools/Godot_v4.3-stable_win64.exe --path D:/30DAYS res://scenes/IdleDemo.tscn
extends Control

const SPRITE_DIR: String = "res://assets/sprites/characters/"

## 帧序列角色表：{prefix: {"frames": N, "size": Vector2i, "fps": F}}
## fps 6.0 = 12 帧 2 秒一个呼吸循环（用户 08-14 反馈：播放再慢一点；与 player.gd idle_fps=6.0 对齐）
const SEQUENCES: Dictionary = {
	"yunni": {"frames": 12, "size": Vector2i(96, 96), "fps": 6.0},
	"ruoyemu": {"frames": 12, "size": Vector2i(96, 96), "fps": 6.0},
}
## 程序化呼吸参数（与帧序列同频同幅：12 帧 @6fps = 2.0s 周期，±1.5px）
const BREATH_AMPLITUDE: float = 1.5
const BREATH_PERIOD: float = 2.0

@onready var yunni_seq: AnimatedSprite2D = $Stage/YunniSeq
@onready var yunni_proc: Sprite2D = $Stage/YunniProc
@onready var ruo_seq: AnimatedSprite2D = $Stage/RuoSeq

var _t: float = 0.0
var _proc_base_y: float = 0.0

func _ready() -> void:
	_build_seq(yunni_seq, "yunni")
	_build_seq(ruo_seq, "ruoyemu")
	# 程序化对照组：取帧序列第一帧作为静态图，引擎 sin 位移模拟呼吸
	var sf := _make_frames("yunni")
	if sf and sf.get_frame_count("idle") > 0:
		yunni_proc.texture = sf.get_frame_texture("idle", 0)
	_proc_base_y = yunni_proc.position.y

func _make_frames(prefix: String) -> SpriteFrames:
	var tex: Texture2D = load(SPRITE_DIR + prefix + "_idle.png")
	# headless/沙箱环境未跑编辑器导入时，.import 缺失 → load 返回 null，
	# fallback 用 Image.load 直读原始 PNG（绕过导入管线；正式接入后走正常导入）
	if tex == null:
		tex = _load_raw(SPRITE_DIR + prefix + "_idle.png")
	if tex == null:
		push_warning("[IdleDemo] 缺少资源: %s_idle.png（先跑一次 Godot 编辑器导入）" % prefix)
		return null
	var cfg: Dictionary = SEQUENCES[prefix]
	return SpriteFrameFactory.create_from_sheet(
		tex, int(cfg["frames"]), cfg["size"], float(cfg["fps"]), true, "idle")

## Image.load 直读原始文件（不经导入管线）；兼容 res:// 路径
func _load_raw(path: String) -> Texture2D:
	var img := Image.new()
	if img.load(path) != OK:
		return null
	return ImageTexture.create_from_image(img)

func _build_seq(anim: AnimatedSprite2D, prefix: String) -> void:
	var sf := _make_frames(prefix)
	if sf == null:
		return
	anim.sprite_frames = sf
	anim.play("idle")

func _process(delta: float) -> void:
	_t += delta
	# 程序化呼吸：同频同幅正弦，模拟帧序列呼吸的整体位移分量
	if yunni_proc.texture != null:
		yunni_proc.position.y = _proc_base_y + sin(_t * TAU / BREATH_PERIOD) * BREATH_AMPLITUDE
