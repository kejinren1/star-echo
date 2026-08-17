## 图标图集工具 (静态工具类)
## 从横向排列的 icon sprite sheet 按索引获取单帧 AtlasTexture
## 用法: IconAtlas.get_icon("weapons", 0)  → 返回 weapons.png 第 0 帧的 AtlasTexture
class_name IconAtlas
extends RefCounted

## 图集配置: sheet 名称 → { texture, frame_count, frame_size }
const SHEET_CONFIG: Dictionary = {
	"weapons": {
		"path": "res://assets/sprites/ui/weapons.png",
		"frame_count": 40,                       ## D7-T4: 4 → 40（33 把武器 + 7 帧空余）
		"frame_size": Vector2i(32, 32),
	},
	"items": {
		"path": "res://assets/sprites/ui/items.png",
		"frame_count": 54,                       ## 2026-08-15 道具图集重建：25 → 54（items.json 全 54 道具按序）
		"frame_size": Vector2i(32, 32),
	},
	"skills": {
		"path": "res://assets/sprites/skills/skills.png",
		"frame_count": 5,                        ## D20-T7（T-D）：4 技能图标（fireball/deploy_turret/blade_burst/holy_shield）+ 1 占位（se_skill_sword_arc 剑气爆发，总指挥 F1-E 期补）
		"frame_size": Vector2i(32, 32),
	},
}

## 缓存已加载的纹理，避免重复加载
static var _texture_cache: Dictionary = {}
## 缓存已创建的 AtlasTexture，避免重复创建
static var _atlas_cache: Dictionary = {}

## 获取指定图集指定索引的图标 AtlasTexture
static func get_icon(sheet_name: String, index: int) -> AtlasTexture:
	var cache_key := "%s_%d" % [sheet_name, index]
	if _atlas_cache.has(cache_key):
		return _atlas_cache[cache_key]

	if not SHEET_CONFIG.has(sheet_name):
		push_warning("[IconAtlas] 未知图集: %s" % sheet_name)
		return null

	var config: Dictionary = SHEET_CONFIG[sheet_name]
	var tex: Texture2D = _get_texture(sheet_name, config["path"])
	if not tex:
		return null

	var frame_count: int = config["frame_count"]
	if index < 0 or index >= frame_count:
		push_warning("[IconAtlas] 索引越界: %s[%d] (共 %d 帧)" % [sheet_name, index, frame_count])
		return null

	var frame_size: Vector2i = config["frame_size"]
	var atlas := AtlasTexture.new()
	atlas.atlas = tex
	atlas.region = Rect2i(index * frame_size.x, 0, frame_size.x, frame_size.y)

	_atlas_cache[cache_key] = atlas
	return atlas

## 获取图集的原始纹理 (带缓存)
static func _get_texture(sheet_name: String, path: String) -> Texture2D:
	if _texture_cache.has(sheet_name):
		return _texture_cache[sheet_name]
	var tex := load(path) as Texture2D
	if not tex:
		push_warning("[IconAtlas] 无法加载纹理: %s" % path)
		return null
	_texture_cache[sheet_name] = tex
	return tex

## 获取图集中图标的总帧数
static func get_frame_count(sheet_name: String) -> int:
	if SHEET_CONFIG.has(sheet_name):
		return SHEET_CONFIG[sheet_name]["frame_count"]
	return 0

## 清除缓存 (场景切换时可选调用)
static func clear_cache() -> void:
	_texture_cache.clear()
	_atlas_cache.clear()
