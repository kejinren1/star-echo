## 地面与墙体生成器
## 程序化创建 TileSet，填充地面 4 变体，放置墙体边界，添加碰撞
## PS（2026-08-17 用户拍板）：视口 960×540 + 大地图——竞技场 48×27 格（1536×864 ≈ 1.6 屏），
## 相机跟随玩家（world.gd），玩家可走出视野与敌人拉开距离（Boss 战不再贴脸绕圈）
extends Node2D

# ========== 导出属性 ==========

@export var arena_width: int = 48                ## 竞技场宽度（格）
@export var arena_height: int = 27               ## 竞技场高度（格）
@export var tile_size: int = 32                  ## 单格尺寸（像素）

# ========== 内部常量 ==========

const GROUND_PATH := "res://assets/sprites/effects/tileset_ground.png"
const WALL_PATH := "res://assets/sprites/effects/tileset_wall.png"

# 地面变体权重: basic 60% / cracked 20% / blood 10% / moss 10%
const GROUND_WEIGHTS := [0.6, 0.2, 0.1, 0.1]

# ========== 内部状态 ==========

var _tile_map: TileMap
var _ground_source_id: int
var _wall_source_id: int

# ========== 生命周期 ==========

func _ready() -> void:
	_create_tileset()
	_fill_ground()
	_place_walls()
	_add_border_collision()
	# 将竞技场居中于视口
	var viewport_size := get_viewport_rect().size
	global_position = Vector2(
		(viewport_size.x - arena_width * tile_size) / 2.0,
		(viewport_size.y - arena_height * tile_size) / 2.0
	)

# ========== TileSet 创建 ==========

func _create_tileset() -> void:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(tile_size, tile_size)

	# 地面图集源
	var ground_source := TileSetAtlasSource.new()
	var ground_tex := load(GROUND_PATH) as Texture2D
	ground_source.texture = ground_tex
	ground_source.texture_region_size = Vector2i(tile_size, tile_size)
	for i in range(4):
		ground_source.create_tile(Vector2i(i, 0))
	_ground_source_id = tileset.add_source(ground_source)

	# 墙体图集源
	var wall_source := TileSetAtlasSource.new()
	var wall_tex := load(WALL_PATH) as Texture2D
	wall_source.texture = wall_tex
	wall_source.texture_region_size = Vector2i(tile_size, tile_size)
	for i in range(4):
		wall_source.create_tile(Vector2i(i, 0))
	_wall_source_id = tileset.add_source(wall_source)

	# 创建 TileMap 并设置 TileSet
	_tile_map = TileMap.new()
	_tile_map.tile_set = tileset
	_tile_map.name = "TileMap"
	add_child(_tile_map)

# ========== 地面填充 ==========

func _fill_ground() -> void:
	for x in range(arena_width):
		for y in range(arena_height):
			var variant := _pick_ground_variant()
			_tile_map.set_cell(0, Vector2i(x, y), _ground_source_id, Vector2i(variant, 0))

func _pick_ground_variant() -> int:
	var r := randf()
	var cumulative: float = 0.0
	for i in range(GROUND_WEIGHTS.size()):
		cumulative += GROUND_WEIGHTS[i]
		if r < cumulative:
			return i
	return 0

# ========== 墙体放置 ==========

func _place_walls() -> void:
	# 墙体变体: 0=顶, 1=左, 2=底, 3=右
	for x in range(arena_width):
		_tile_map.set_cell(0, Vector2i(x, -1), _wall_source_id, Vector2i(0, 0))           # 顶边
		_tile_map.set_cell(0, Vector2i(x, arena_height), _wall_source_id, Vector2i(2, 0))  # 底边
	for y in range(arena_height):
		_tile_map.set_cell(0, Vector2i(-1, y), _wall_source_id, Vector2i(1, 0))           # 左边
		_tile_map.set_cell(0, Vector2i(arena_width, y), _wall_source_id, Vector2i(3, 0))  # 右边
	# 四角用顶边变体
	_tile_map.set_cell(0, Vector2i(-1, -1), _wall_source_id, Vector2i(0, 0))
	_tile_map.set_cell(0, Vector2i(arena_width, -1), _wall_source_id, Vector2i(0, 0))
	_tile_map.set_cell(0, Vector2i(-1, arena_height), _wall_source_id, Vector2i(2, 0))
	_tile_map.set_cell(0, Vector2i(arena_width, arena_height), _wall_source_id, Vector2i(2, 0))

# ========== 边界碰撞 ==========

func _add_border_collision() -> void:
	var w: float = arena_width * tile_size
	var h: float = arena_height * tile_size
	var t: float = tile_size  # 墙厚

	# 上墙
	_add_wall_body(Vector2(-t, -t), Vector2(w + t * 2, t))
	# 下墙
	_add_wall_body(Vector2(-t, h), Vector2(w + t * 2, t))
	# 左墙
	_add_wall_body(Vector2(-t, 0), Vector2(t, h))
	# 右墙
	_add_wall_body(Vector2(w, 0), Vector2(t, h))

func _add_wall_body(pos: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = pos + size / 2.0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	add_child(body)

# ========== 查询接口 ==========

## 获取竞技场中心坐标（世界坐标）
func get_arena_center() -> Vector2:
	return global_position + Vector2(arena_width * tile_size, arena_height * tile_size) / 2.0

## 获取竞技场矩形（世界坐标）
func get_arena_rect() -> Rect2:
	return Rect2(global_position, Vector2(arena_width * tile_size, arena_height * tile_size))
