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

@export_group("暴击（Day 13 · D13-T1）")
## 暴击率（0~1；默认 0 = 不暴击，既有武器弹丸零回归）与暴击伤害倍率（默认 1.0 = 无加成）
## 由 weapon_controller._spawn_projectile 聚合玩家+武器通道透传；技能弹丸缺省 = 不暴击
@export var crit_chance: float = 0.0          ## 暴击率（0~1）
@export var crit_mult: float = 1.0            ## 暴击伤害倍率（1.0 = 无加成）

@export_group("外观（默认 = 既有基础子弹，技能可覆写）")
## 试玩反馈补强（2026-08-05）：技能弹丸与基础子弹共用同一纹理导致肉眼无法区分
## （用户反馈「怎么还是基础的子弹」）→ 新增颜色/半径参数化，默认值 = 原有霓虹黄 8px
@export var bullet_color: Color = Color(1.0, 0.92, 0.2)  ## 弹体颜色（默认霓虹黄）
@export var bullet_radius: float = 3.4                   ## 弹体半径（默认 3.4 = 8px 纹理）

# ========== 内部状态 ==========

var direction: Vector2 = Vector2.ZERO
var _hit_count: int = 0
var _lifetime_timer: float = 0.0
var _exploded: bool = false                   ## 防重复爆炸（命中 / 寿命耗尽两条路径都会触发）
var _last_crit: bool = false                  ## F-11：最近一次 _roll_crit 是否暴击（伤害数字样式用）

# ========== 生命周期 ==========

func _ready() -> void:
	# F-02（用户拍板 2026-08-06 · P0）：敌人移入 collision_layer 2（玩家层 1 不检测敌人层 →
	# 人物穿过怪物不围杀）；弹丸 Area2D mask 须指向敌人层 2 才能收到 body_entered
	# T-011（F1-散 2026-08-13）：mask/半径参数化 = stats.physics（缺表兜底 2 / 4.0）
	var physics: Dictionary = DataLoader.get_stats_physics()
	collision_mask = int(physics.get("projectile_mask", 2))
	# 运行时生成子弹精灵（初版不依赖外部美术资源）
	var sprite := Sprite2D.new()
	sprite.texture = _make_bullet_texture()
	sprite.centered = true
	add_child(sprite)
	# 碰撞形状
	var col_shape := CollisionShape2D.new()
	var col := CircleShape2D.new()
	col.radius = float(physics.get("projectile_radius", 4.0))
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
	# 命中敌人则造成伤害（D13-T1：暴击结算）
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		var final_damage: float = _roll_crit(damage)
		final_damage = _apply_boss_elite_bonus(final_damage, body)
		# F-11（用户拍板 2026-08-06）：伤害数字子系统——命中时透传暴击态（enemy 侧展示）
		body.take_damage(final_damage, _is_crit_hit())
		_apply_life_steal(final_damage)
		# D24-F13-2（F-13 on_crit）：暴击命中 → 连锁伤害（overload_capacitor，_is_crit_hit 依赖 _last_crit 须在 _roll_crit 后）
		if _is_crit_hit():
			_trigger_on_crit_chain(body.global_position, final_damage)
		_hit_count += 1
		# Day 23-T1：普通命中 VFX（线弹 + 穿透沿途每个被命中敌人都触发；
		# 与 F-11 伤害数字同帧叠加，VfxPlayer 挂 vfx_container(Node2D) 天然盖于
		# HUD CanvasLayer 之下无冲突；暴击仍走 _do_explosion crit 双轨并存）
		if GameManager.vfx_container:
			VfxPlayer.spawn(GameManager.vfx_container, global_position, "hit")
		AudioManager.play_sfx("hit")   # D24-T3-②：普通命中 SFX
		# F-07（用户拍板 2026-08-06）：穿透弹沿途每个敌人即时爆炸（含元素附着）——
		# 而非仅最后一次命中才爆。拆分 _do_explosion（无防重复标记）：穿透中段裸爆，
		# 最后一次命中走 _explode（防与 lifetime 到点双爆）
		if _hit_count > pierce:
			_explode()
			queue_free()
			return
		if explosion_radius > 0.0:
			_do_explosion()

# ========== 爆炸 AOE 与元素附着（Day 3 · D3-T2） ==========

## 在当前位置结算一次范围伤害 + 元素附着
## 判定方式为「遍历敌人容器算距离」而非物理查询：与 weapon_controller._find_nearest_enemy()
## 同一范式，且无头测试下不依赖物理帧，结果可复现
func _explode() -> void:
	if _exploded or explosion_radius <= 0.0:
		return
	_exploded = true
	_do_explosion()

## F-07（用户拍板 2026-08-06）：裸爆炸执行体（无防重复标记）
## 穿透弹命中沿途每个敌人时调用（一次命中 = 一次爆炸）；_explode 包装保留防重复
## （lifetime 到点路径 + 最后一次命中路径同帧双触发时只结算一次）
func _do_explosion() -> void:
	if explosion_radius <= 0.0:
		return

	if GameManager.enemy_spawner and GameManager.enemy_spawner.enemies_container:
		for enemy in GameManager.enemy_spawner.enemies_container.get_children():
			if not is_instance_valid(enemy) or not enemy.is_alive:
				continue
			if global_position.distance_to(enemy.global_position) > explosion_radius:
				continue
			if explosion_damage > 0.0 and enemy.has_method("take_damage"):
				# D13-T1：AOE 与线弹同口径暴击（暴击伤害同样走吸血）
				var final_damage: float = _roll_crit(explosion_damage)
				final_damage = _apply_boss_elite_bonus(final_damage, enemy)
				# F-11：AOE 暴击态透传（enemy 侧展示伤害数字）
				enemy.take_damage(final_damage, _is_crit_hit())
				_apply_life_steal(final_damage)
				# D24-F13-2（F-13 on_crit）：AOE 暴击命中 → 连锁伤害（overload_capacitor）
				if _is_crit_hit():
					_trigger_on_crit_chain(enemy.global_position, final_damage)
			# BS-A2（2026-08-13）：状态附着 → 统一效果组件（apply_effect 带 source_id——
			# 武器/技能经 meta source_id 透传（D13-T2 meta 范式）；O1 同源刷新/异源独立）
			if not status_type.is_empty() and enemy.has_method("apply_effect"):
				enemy.apply_effect(str(get_meta(&"source_id", "weapon")), status_type,
					{"duration": status_duration, "dps": status_dps})

	# Day 23-T3/T4：专属爆炸 VFX —— 按 source_id 分派（D13-T2 meta 范式；
	# weapon_controller._spawn_projectile 已统一打 meta，技能弹丸由 skill_controller 打）。
	# 判定顺序：se_star_fall（进化陨石）→ se_skill_fireball（炽星火球）→ 兜底 crit（其余 52 武器零回归）
	if GameManager.vfx_container:
		var fx_name: String = "crit"
		match str(get_meta(&"source_id", "")):
			"se_star_fall":
				fx_name = "meteor"
			"se_skill_fireball":
				fx_name = "fireball"
		VfxPlayer.spawn(GameManager.vfx_container, global_position, fx_name)
	AudioManager.play_sfx("crit")   # D24-T3-③：爆炸/暴击 SFX（陨石/火球/普爆共用，D30 收敛点 1/2）

# ========== 吸血结算（Day 4 · D4-T3） ==========

## 命中伤害生效后按玩家 life_steal 比例回血（线弹命中 / 爆炸 AOE 共用）
## 独立公开方法：无头测试可白盒直调，不依赖物理碰撞帧
func apply_life_steal(damage_dealt: float) -> void:
	var p: Node = GameManager.player
	if p == null or damage_dealt <= 0.0:
		return
	if not ("life_steal" in p) or float(p.life_steal) <= 0.0:
		return
	var heal_amount: float = damage_dealt * float(p.life_steal)
	if p.has_method("heal"):
		p.heal(heal_amount)
	else:
		p.health = minf(float(p.health) + heal_amount, float(p.max_health))

func _apply_life_steal(damage_dealt: float) -> void:
	apply_life_steal(damage_dealt)

## F1-G（T-050）：boss_elite_damage_percent 对精英/Boss 增伤（silver_bullet +25%）
## 线弹/AOE 统一口径：enemy.enemy_category ∈ {elite, boss} 时乘算；bonus_stats 默认 0 零回归
func _apply_boss_elite_bonus(dmg: float, enemy: Node) -> float:
	var player_node: Node = GameManager.player if GameManager else null
	if player_node == null or not ("bonus_stats" in player_node):
		return dmg
	if enemy == null or enemy.get("enemy_category") not in ["elite", "boss"]:
		return dmg
	var pct: float = float(player_node.bonus_stats.get("boss_elite_damage_percent", 0.0))
	if pct == 0.0:
		return dmg
	return dmg * (1.0 + pct / 100.0)

# ========== 暴击结算（Day 13 · D13-T1） ==========

## 按暴击率 roll 一次最终伤害：`randf() < crit_chance` → base × crit_mult；否则 base
## crit_chance <= 0 时恒不暴击（既有武器零回归）；crit_mult < 1.0 视为 1.0（无加成）
## 独立公开方法：无头测试可白盒直调，不依赖物理碰撞帧
## F-11：同步记录 _last_crit（伤害数字暴击样式读取，禁调用方二次 roll 导致显示与结算不一致）
func _roll_crit(base: float) -> float:
	_last_crit = crit_chance > 0.0 and randf() < crit_chance
	if _last_crit:
		return base * maxf(crit_mult, 1.0)
	return base

## F-11：最近一次 _roll_crit 是否暴击（线弹/AOE 命中后透传给 enemy.take_damage 展示样式）
func _is_crit_hit() -> bool:
	return _last_crit

## D24-F13-2（F-13 on_crit · overload_capacitor 过载电容）：暴击命中 → 目标周围 80px 敌人
## 受到该次暴击伤害 ×0.3 的连锁伤害（D27 语义：每次暴击命中触发一次，不额外防重；
## AOE 一次命中 N 敌暴击 → 最多 N 次连锁，接受）。
## F-19 升级冲击波容器遍历范式（禁物理查询）：GameManager.enemies_container.get_children()
## + is_alive 守卫 + has_method("take_damage") + 距离判断；连锁命中 is_crit=false（不再二次暴击）
func _trigger_on_crit_chain(target_pos: Vector2, crit_damage: float) -> void:
	if not (GameManager and GameManager.inventory and GameManager.inventory.has_item_id(DataLoader.ITEM_OVERLOAD_CAPACITOR)):
		return
	if GameManager.enemies_container == null or crit_damage <= 0.0:
		return
	const CHAIN_RADIUS: float = 80.0
	const CHAIN_RATIO: float = 0.3
	for enemy in GameManager.enemies_container.get_children():
		if enemy == null or not is_instance_valid(enemy):
			continue
		if not ("is_alive" in enemy and enemy.is_alive):
			continue
		if not enemy.has_method("take_damage"):
			continue
		if enemy.global_position.distance_to(target_pos) > CHAIN_RADIUS:
			continue
		enemy.take_damage(crit_damage * CHAIN_RATIO, false)

# ========== 工具 ==========

## 运行时绘制一颗圆形弹体纹理（颜色/半径可参数化，默认霓虹黄）
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
	if props.has("bullet_color"):
		bullet_color = props["bullet_color"]
	if props.has("bullet_radius"):
		bullet_radius = props["bullet_radius"]
	if props.has("crit_chance"):
		crit_chance = props["crit_chance"]
	if props.has("crit_mult"):
		crit_mult = props["crit_mult"]
