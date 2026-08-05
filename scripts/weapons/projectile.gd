## 弹丸脚本
## 远程武器发射的弹丸，碰撞后造成对敌人伤害
extends Area2D

# ========== 导出属性 ==========

@export var speed: float = 400.0              ## 弹速
@export var damage: float = 10.0              ## 伤害
@export var lifetime: float = 2.0             ## 存活时间
@export var pierce: int = 0                   ## 穿透次数 (0 = 碰到即销毁)
@export var knockback: float = 0.0            ## 击退力

@export_group("爆炸与元素附着（Day 3）")
## 以下 5 项默认值即「现有行为」：explosion_radius = 0 表示不爆炸，
## status_type = "" 表示不附着状态 —— 既有武器弹丸零回归
@export var explosion_radius: float = 0.0     ## 爆炸半径（0 = 不爆炸）
@export var explosion_damage: float = 0.0     ## 爆炸范围伤害
@export var status_type: String = ""          ## 附着的元素状态 id（"" = 不附着）
@export var status_duration: float = 0.0      ## 状态持续时间（秒）
@export var status_dps: float = 0.0           ## 状态每秒伤害

# ========== 内部状态 ==========

var direction: Vector2 = Vector2.ZERO
var _hit_count: int = 0
var _lifetime_timer: float = 0.0
var _exploded: bool = false                   ## 防重复爆炸（命中 / 寿命耗尽两条路径都会触发）

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
		# 打空也要炸（火球落地爆炸）
		_explode()
		queue_free()

# ========== 碰撞处理 ==========

func _on_body_entered(body: Node) -> void:
	# 命中敌人则造成伤害
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage)
		_hit_count += 1
		if _hit_count > pierce:
			_explode()
			queue_free()

# ========== 爆炸 AOE 与元素附着（Day 3 · D3-T2） ==========

## 在当前位置结算一次范围伤害 + 元素附着
## 判定方式为「遍历敌人容器算距离」而非物理查询：与 weapon_controller._find_nearest_enemy()
## 同一范式，且无头测试下不依赖物理帧，结果可复现
func _explode() -> void:
	if _exploded or explosion_radius <= 0.0:
		return
	_exploded = true

	if GameManager.enemy_spawner and GameManager.enemy_spawner.enemies_container:
		for enemy in GameManager.enemy_spawner.enemies_container.get_children():
			if not is_instance_valid(enemy) or not enemy.is_alive:
				continue
			if global_position.distance_to(enemy.global_position) > explosion_radius:
				continue
			if explosion_damage > 0.0 and enemy.has_method("take_damage"):
				enemy.take_damage(explosion_damage)
			if not status_type.is_empty() and enemy.has_method("apply_status"):
				enemy.apply_status(status_type, status_duration, status_dps)

	# 专属爆炸 VFX 属 Day 23，本日复用现成 crit 特效
	if GameManager.vfx_container:
		VfxPlayer.spawn(GameManager.vfx_container, global_position, "crit")

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
	if props.has("explosion_radius"):
		explosion_radius = props["explosion_radius"]
	if props.has("explosion_damage"):
		explosion_damage = props["explosion_damage"]
	if props.has("status_type"):
		status_type = props["status_type"]
	if props.has("status_duration"):
		status_duration = props["status_duration"]
	if props.has("status_dps"):
		status_dps = props["status_dps"]
