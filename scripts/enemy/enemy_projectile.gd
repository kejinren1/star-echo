## 敌人弹丸脚本（D18-19-T3 · Boss 多阶段）
## 由 Boss 攻击执行器（enemy.gd _boss_spread/_boss_barrage）生成，命中玩家造成伤害
## 关键设计（方案决策 D8）：
##   · 纯 Node2D + 距离判断，无任何物理碰撞节点（无头稳定铁律，禁物理查询）
##   · 挂载点 = Boss 节点自身（决策 D1，防 get_alive_count 容器污染），随父销毁
##   · player projectile.gd 零改动（回归保护）
class_name EnemyProjectile
extends Node2D

# ========== 导出属性 ==========

@export var speed: float = 220.0             ## 弹速
@export var damage: float = 10.0             ## 命中伤害（由 Boss 执行器透传 damage × _attack_mult）
@export var lifetime: float = 2.0            ## 存活时间（秒）
@export var bullet_color: Color = Color(0.75, 0.3, 0.9)  ## 弹体颜色（暗紫，区分玩家霓虹黄）
@export var bullet_radius: float = 4.0       ## 弹体半径

# ========== 内部状态 ==========

var direction: Vector2 = Vector2.ZERO
var _lifetime_timer: float = 0.0

# ========== 生命周期 ==========

func _ready() -> void:
	# 探针批量断言分组（Boss 子节点口径，D1）
	add_to_group("enemy_projectiles")
	# 运行时生成弹体精灵（仿 projectile.gd _make_bullet_texture 范式，含核心亮色）
	var sprite := Sprite2D.new()
	sprite.texture = _make_bullet_texture()
	sprite.centered = true
	add_child(sprite)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_lifetime_timer += delta
	if _lifetime_timer >= lifetime:
		queue_free()
		return
	# 距离判断命中玩家（禁物理查询，D8）；玩家无效/无 take_damage → 跳过不崩
	var p: Node = GameManager.player if GameManager else null
	if p == null or not p.has_method("take_damage"):
		return
	var hit_range: float = bullet_radius + 12.0
	if global_position.distance_to(p.global_position) <= hit_range:
		p.take_damage(damage)
		# 命中特效（容器缺失静默跳过）
		var container: Node = GameManager.vfx_container if GameManager and GameManager.vfx_container else null
		if container:
			VfxPlayer.spawn(container, global_position, "hit")
		queue_free()

# ========== 接口 ==========

## 初始化弹丸属性（逐键可选覆盖，缺省用导出默认值）
func initialize(props: Dictionary) -> void:
	if props.has("speed"):
		speed = props["speed"]
	if props.has("damage"):
		damage = props["damage"]
	if props.has("lifetime"):
		lifetime = props["lifetime"]
	if props.has("bullet_color"):
		bullet_color = props["bullet_color"]
	if props.has("bullet_radius"):
		bullet_radius = props["bullet_radius"]

## 设置飞行方向（归一化 + 旋转对齐）
func set_direction(dir: Vector2) -> void:
	direction = dir.normalized()
	rotation = direction.angle()

# ========== 工具 ==========

## 运行时绘制一颗圆形弹体纹理（暗紫 + 亮核心，仿 projectile.gd :144-158 范式）
func _make_bullet_texture() -> Texture2D:
	var size := maxi(int(ceil(bullet_radius * 2.0)) + 2, 8)
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var center := Vector2(size * 0.5, size * 0.5)
	var core_color := bullet_color.lightened(0.45)
	for y in range(size):
		for x in range(size):
			var d := Vector2(x + 0.5, y + 0.5).distance_to(center)
			if d <= bullet_radius:
				if d <= bullet_radius * 0.47:
					img.set_pixel(x, y, core_color)
				else:
					img.set_pixel(x, y, bullet_color)
	return ImageTexture.create_from_image(img)
