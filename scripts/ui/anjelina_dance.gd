## 安杰丽娜 sit-dance 演示（2026-08-14 · 豆包视频逐帧截图 → 游戏素材）
## 用途：展示"视频截图 → 去水印 → perfectPixel median → 抠底 → sheet → 引擎"管线成果
## 源：星骸回响_AI美术资产_v2_20260814/ai动画/（10 帧 720×720 JPG，豆包 sit dance）
## 处理：角带净化去水印 → perfectPixel median（复用首帧网格，帧间锁定）→ floodfill 抠底 → anjelina_dance.png
## 帧尺寸动态取 sheet 高度（引擎 _sheet_meta 同规则），不写死
extends Control

const SPRITE_DIR: String = "res://assets/sprites/characters/"

@onready var dancer: AnimatedSprite2D = $Stage/Dancer
@onready var status: Label = $Status

func _ready() -> void:
	var tex: Texture2D = load(SPRITE_DIR + "anjelina_dance.png")
	if tex == null:
		tex = _load_raw(SPRITE_DIR + "anjelina_dance.png")
	if tex == null:
		status.text = "缺少资源: anjelina_dance.png（先跑一次 Godot 编辑器导入）"
		return
	var fh: int = tex.get_height()
	var sf := SpriteFrameFactory.create_from_sheet(
		tex, tex.get_width() / fh, Vector2i(fh, fh), 5.0, true, "dance")
	dancer.sprite_frames = sf
	dancer.play("dance")
	status.text = "安杰丽娜 · sit dance（10 帧 @5fps · 透明底 · 去水印 · 复用网格）"

## Image.load 直读原始 PNG（不经导入管线）；兼容 res:// 路径
func _load_raw(path: String) -> Texture2D:
	var img := Image.new()
	if img.load(path) != OK:
		return null
	return ImageTexture.create_from_image(img)
