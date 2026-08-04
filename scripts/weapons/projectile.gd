## 弹丸脚本
## 远程武器发射的弹丸，碰撞后造成对敌人伤害
extends Area2D

# ========== 导出属性 ==========

@export var speed: float = 400.0              ## 弹速
@export var damage: float = 10.0              ## 伤害
@export var lifetime: float = 2.0             ## 存活时间
@export var pierce: int = 0                   ## 穿透次数 (0 = 碰到即销毁)
@export var knockback: float = 0.0            ## 击退力

# ========== 内部状态 ==========

var direction: Vector2 = Vector2.ZERO
var _hit_count: int = 0
var _lifetime_timer: float = 0.0

# ========== 生命周期 ==========

func _ready() -> void:
	# 运行时生成子弹精灵（初版不依赖外部美术资源）
	var sprite := Sprite2D.new()
	sprite.texture = _make_bullet_texture()
	sprite.centered = true
	add_child(sprite)
	# 碰撞形状
	var col_shape := CollisionShape2D.new()
	var col := CircleShape2D.new()
	col.radius = 4.0
	col_shape.shape = col
	add_child(col_shape)
	# 碰撞信号
	body_entered.connect(_on_body_entered)

# ========== 移动 ==========

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_lifetime_timer += delta
	if _lifetime_timer >= lifetime:
		queue_free()

# ========== 碰撞处理 ==========

func _on_body_entered(body: Node) -> void:
	# 命中敌人则造成伤害
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage)
		_hit_count += 1
		if _hit_count > pierce:
			queue_free()

# ========== 工具 ==========

## 运行时绘制一颗霓虹黄小子弹纹理
func _make_bullet_texture() -> Texture2D:
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(8):
		for x in range(8):
			var d := Vector2(x + 0.5, y + 0.5).distance_to(Vector2(4.0, 4.0))
			if d <= 3.4:
				if d <= 1.6:
					img.set_pixel(x, y, Color(1.0, 1.0, 0.9, 1.0))
				else:
					img.set_pixel(x, y, Color(1.0, 0.92, 0.2, 1.0))
	return ImageTexture.create_from_image(img)

## 设置弹丸方向
func set_direction(dir: Vector2) -> void:
	direction = dir.normalized()
	rotation = direction.angle()

## 初始化弹丸属性
func initialize(props: Dictionary) -> void:
	if props.has("speed"):
		speed = props["speed"]
	if props.has("damage"):
		damage = props["damage"]
	if props.has("lifetime"):
		lifetime = props["lifetime"]
	if props.has("pierce"):
		pierce = props["pierce"]
	if props.has("knockback"):
		knockback = props["knockback"]
