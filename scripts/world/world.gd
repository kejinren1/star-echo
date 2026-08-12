## World 容器服务（阶段 F · F2-T0/T3/T4 · 2026-08-12）
## 挂在 scenes/Main.tscn 的 World 节点上（Main.tscn :16）：
##   · 统一容器注册表 get_container —— 消灭 weapon_controller / skill_controller / turret
##     三处复制粘贴的 _find_container（此前 Projectiles 容器不存在 → 全部回退 World；
##     建容器后弹丸真实挂 World/Projectiles，即 _find_container 注释的原始语义收口）
##   · 实体创建工厂 spawn_projectile / spawn_turret / spawn_minion —— 消灭直接 instantiate
##     散落 5 处（weapon_controller:318 / skill_controller:118,181-185 / enemy:560,699）
## 工厂职责边界（F2-T0 方案定案）：仅 instantiate + setup 透传 + 挂载正确容器；
## 位置/朝向/初始化细节留消费点，防工厂上帝化。
## ⚠️ 时序铁律：setup/initialize 必须先于 add_child —— projectile._ready 用 bullet_color
## 生成弹体纹理 / enemy._ready 用 max_health 初始化 health，后置会导致默认值渲染/血量错误。
extends Node2D

# ========== 容器注册表（F2-T0） ==========

## key → World 子节点名（_ready 预创建缺失容器；Enemies/VfxContainer 已由 Main.tscn 提供）
const CONTAINER_MAP: Dictionary = {
	"projectiles": "Projectiles",
	"enemies": "Enemies",
	"vfx": "VfxContainer",
}

func _ready() -> void:
	# 预创建 Projectiles 容器（此前不存在，三处 _find_container 因此全部回退 World）
	if not has_node(str(CONTAINER_MAP["projectiles"])):
		var c := Node2D.new()
		c.name = str(CONTAINER_MAP["projectiles"])
		add_child(c)

## 按 key 取容器节点；未知 key / 节点缺失 → null + push_warning（消费点判空防崩）
func get_container(key: String) -> Node:
	var child_name: String = str(CONTAINER_MAP.get(key, ""))
	if child_name.is_empty():
		push_warning("[World] 未知容器 key: %s" % key)
		return null
	var c := get_node_or_null(child_name)
	if c == null:
		push_warning("[World] 容器节点缺失: %s" % child_name)
	return c

# ========== 实体创建工厂（F2-T4） ==========

## 弹丸：挂 Projectiles 容器；init_props 透传 projectile.initialize（先 initialize 后
## add_child —— _ready 生成弹体纹理须读到 bullet_color/bullet_radius 已赋值）
func spawn_projectile(scene: PackedScene, init_props: Dictionary) -> Node2D:
	var container: Node = get_container("projectiles")
	if container == null:
		return null
	var proj := scene.instantiate() as Node2D
	if proj == null:
		push_warning("[World] spawn_projectile: 场景实例化失败")
		return null
	if proj.has_method("initialize"):
		proj.initialize(init_props)
	container.add_child(proj)
	return proj

## 炮台：挂 World 自身（F2-T0 §3 验证口径「spawn_turret 挂 World 下」）；
## weapon_data/duration/owner 透传 turret.setup（数值装载 + 占位绘制，无入树依赖）
func spawn_turret(scene: PackedScene, weapon_data: Dictionary, duration: float, owner_player: Node2D) -> Node2D:
	var turret := scene.instantiate() as Node2D
	if turret == null:
		push_warning("[World] spawn_turret: 场景实例化失败")
		return null
	if turret.has_method("setup"):
		turret.setup(weapon_data, duration, owner_player)
	add_child(turret)
	return turret

## 召唤物（敌人）：挂 Enemies 容器；stats 透传 enemy.initialize（先 initialize 后
## add_child —— _ready 用 max_health 初始化 health，后置会血量错配）
func spawn_minion(scene: PackedScene, stats: Dictionary) -> Node:
	var container: Node = get_container("enemies")
	if container == null:
		return null
	var minion := scene.instantiate()
	if minion == null:
		push_warning("[World] spawn_minion: 场景实例化失败")
		return null
	if minion.has_method("initialize"):
		minion.initialize(stats)
	container.add_child(minion)
	return minion
