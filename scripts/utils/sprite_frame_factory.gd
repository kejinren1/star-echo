## 精灵帧工厂 (静态工具类)
## 从横向排列的 sprite sheet 程序化生成 SpriteFrames 资源
## 用法: SpriteFrameFactory.create_from_sheet(texture, 4, Vector2i(32, 32), 6, true, "idle")
class_name SpriteFrameFactory
extends RefCounted

## 从单张 sprite sheet 创建包含单个动画的 SpriteFrames
## texture: sprite sheet 纹理
## frame_count: 横向帧数
## frame_size: 单帧尺寸 (像素)
## fps: 动画播放速度
## loop: 是否循环
## anim_name: 动画名称
static func create_from_sheet(
	texture: Texture2D,
	frame_count: int,
	frame_size: Vector2i,
	fps: float,
	loop: bool,
	anim_name: String
) -> SpriteFrames:
	var sf := SpriteFrames.new()
	# 移除 SpriteFrames 自带的 "default" 动画，避免与自定义动画名冲突
	if sf.has_animation("default"):
		sf.remove_animation("default")
	sf.add_animation(anim_name)
	sf.set_animation_loop(anim_name, loop)
	sf.set_animation_speed(anim_name, fps)
	for i in frame_count:
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(i * frame_size.x, 0, frame_size.x, frame_size.y)
		sf.add_frame(anim_name, atlas)
	return sf

## 从多张 sprite sheet 创建包含多个动画的 SpriteFrames
## animations: Array[Dictionary] 每项格式:
##   { texture, frame_count, frame_size, fps, loop, name }
static func create_multi(animations: Array[Dictionary]) -> SpriteFrames:
	var sf := SpriteFrames.new()
	# 移除 SpriteFrames 自带的 "default" 动画，避免与自定义动画名冲突
	if sf.has_animation("default"):
		sf.remove_animation("default")
	for anim in animations:
		var tex: Texture2D = anim["texture"]
		var count: int = anim["frame_count"]
		var size: Vector2i = anim["frame_size"]
		var fps: float = anim.get("fps", 8.0)
		var loop: bool = anim.get("loop", true)
		var name: String = anim["name"]
		sf.add_animation(name)
		sf.set_animation_loop(name, loop)
		sf.set_animation_speed(name, fps)
		for i in count:
			var atlas := AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = Rect2(i * size.x, 0, size.x, size.y)
			sf.add_frame(name, atlas)
	return sf

## 从路径加载纹理并创建单动画 SpriteFrames
static func create_from_path(
	path: String,
	frame_count: int,
	frame_size: Vector2i,
	fps: float,
	loop: bool,
	anim_name: String
) -> SpriteFrames:
	var tex := load(path) as Texture2D
	if not tex:
		push_warning("[SpriteFrameFactory] 无法加载纹理: %s" % path)
		return null
	return create_from_sheet(tex, frame_count, frame_size, fps, loop, anim_name)

## 创建空 SpriteFrames（用于后续手动添加动画）
static func create_empty() -> SpriteFrames:
	return SpriteFrames.new()
