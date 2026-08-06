## 主动技能控制器（Day 3 · D3-T1/T3/T4/T5）
## 挂载在玩家身上（Player.tscn 内、WeaponController 同层），负责：
##   · 英雄技能数据的装载（setup，由 Main 在角色装载完成后调用）
##   · 冷却计时与 cooldown_changed 信号（供 Day 6 HUD 冷却指示读取）
##   · 按 skill.id 分派差异化释放：艾琳火球 / 诺亚炮台 / 莱恩星刃
## 设计约定（见 docs/TASKS.md Day 3 定案表）：
##   · 本日只做冷却，不做法力（三技能均无 cost/mana 字段，不臆造数值）
extends Node

# ========== 信号 ==========

signal cooldown_changed(left: float, total: float)  ## 冷却变化（left <= 0 即就绪）
signal skill_cast(skill_id: String)                 ## 成功释放一次技能

# ========== 资源引用 ==========

const ProjectileScene: PackedScene = preload("res://scenes/Projectile.tscn")
const TurretScene: PackedScene = preload("res://scenes/Turret.tscn")

# ========== 状态 ==========

var skill_data: Dictionary = {}   ## 当前英雄的 skill 字段（setup 时装载）
var player                     ## 父节点（玩家）。刻意不加类型标注：Player.gd 的
                                ## bonus_stats/apply_stat_modifier 等成员不在 Node2D 基类上，
                                ## 加类型会触发编译期成员解析风险（与 weapon_controller 的
                                ## owner_node 动态访问策略一致）

var _cd_left: float = 0.0       ## 剩余冷却
var _cd_total: float = 0.0      ## 总冷却
var _warned_not_impl: bool = false  ## 未实现技能只提示一次（防玩家狂按刷屏）

# ========== 生命周期 ==========

func _ready() -> void:
	# 注意：子节点 _ready 先于父节点执行，此刻 player.character_id 尚未装载
	# （与 Day 2 踩过的执行顺序坑同源），禁止在此读英雄数据 ——
	# 数据装载统一由 Main 在角色装载完成后调 setup()
	player = get_parent()

func _process(delta: float) -> void:
	if _cd_left > 0.0:
		_cd_left = maxf(_cd_left - delta, 0.0)  # 归零 clamp，禁止负数
		cooldown_changed.emit(_cd_left, _cd_total)

# ========== 装载 ==========

## 由 Main._setup_skill 调用：装载英雄技能数据并复位冷却
func setup(char_data: Dictionary) -> void:
	skill_data = char_data.get("skill", {})
	_cd_total = float(skill_data.get("cooldown", 0.0))
	_cd_left = 0.0
	cooldown_changed.emit(0.0, _cd_total)

## 兜底自查：直开 Main.tscn（未经 Main._setup_skill）时技能仍可用
func _ensure_loaded() -> void:
	if not skill_data.is_empty():
		return
	var char_data: Dictionary = DataLoader.get_character(GameManager.current_character_id)
	if not char_data.is_empty():
		setup(char_data)

# ========== 释放入口 ==========

func can_cast() -> bool:
	return _cd_left <= 0.0 and not skill_data.is_empty()

## 尝试释放技能：冷却中 / 无技能 / 未实现 返回 false（静默，玩家会狂按，不刷 warning）
func try_cast() -> bool:
	_ensure_loaded()
	if not can_cast():
		return false
	var skill_id: String = str(skill_data.get("id", ""))
	match skill_id:
		"se_skill_fireball":
			_cast_fireball()
		"se_skill_deploy_turret":
			if not _cast_deploy_turret():
				return false
		"se_skill_blade_burst":
			_cast_blade_burst()
		_:
			push_warning("[SkillController] 未知技能 id: %s" % skill_id)
			return false
	_cd_left = _cd_total
	skill_cast.emit(skill_id)
	return true

# ========== 技能实现 ==========

## 艾琳「炽星火球」（D3-T3）：朝瞄准方向抛射巨型火球，命中爆炸 + 燃烧
func _cast_fireball() -> void:
	var base_damage: float = float(skill_data.get("damage", 30.0))
	var radius: float = float(skill_data.get("radius", 90.0))
	# 技能覆写通用 3s 基准（elements.json.fire.duration=3），见 TASKS D3-T7b 方案 A：
	# 英雄技能 4 秒属特权加成；通用元素武器后续仍按 elements.json 的 3 秒读
	var burn_duration: float = float(skill_data.get("burn_duration", 4.0))
	var dps: float = _calc_burn_dps()

	# 伤害套玩家倍率（对齐 weapon_controller._spawn_projectile 口径）
	var dmg: float = base_damage
	if player and "damage_multiplier" in player:
		dmg *= player.damage_multiplier

	var container: Node2D = _find_container()
	if container == null:
		push_warning("[SkillController] 无弹丸容器，火球未生成")
		return
	var aim_dir: Vector2 = _get_aim_direction()
	if aim_dir == Vector2.ZERO:
		return

	var proj := ProjectileScene.instantiate()
	proj.initialize({
		"speed": 280.0,
		"damage": dmg,
		"lifetime": 1.4,
		"pierce": 0,
		"explosion_radius": radius,
		"explosion_damage": dmg,
		"status_type": str(skill_data.get("element_type", "fire")),
		"status_duration": burn_duration,
		"status_dps": dps,
		# 试玩反馈补强（2026-08-05）：火球须肉眼可辨（红色大弹体），否则与基础子弹混同
		"bullet_color": Color(1.0, 0.35, 0.15),
		"bullet_radius": 6.0,
	})
	container.add_child(proj)
	proj.global_position = player.global_position
	proj.set_direction(aim_dir)

## 燃烧 dps 唯一口径（D3-T7b）：dot / dot_scaling 只从 elements.json 读，
## 禁止在技能数据里另写一份 —— 艾琳 passive elemental_damage:8 → dps = 3 + 8*0.2 = 4.6
func _calc_burn_dps() -> float:
	var fire: Dictionary = DataLoader.get_element("fire")
	var dot: float = float(fire.get("dot", 3.0))
	var dot_scaling: float = float(fire.get("dot_scaling", 0.2))
	var elemental_damage: float = 0.0
	if player and "bonus_stats" in player:
		elemental_damage = float(player.bonus_stats.get("elemental_damage", 0.0))
	return dot + elemental_damage * dot_scaling

## 诺亚「紧急部署」（D4-T5，承接 D3-T4）：在身侧部署 `summon_count + bonus_stats.summon_count` 台
## 临时炮台（skill summon_count=2 + 诺亚 passive summon_count=1 → 3 台），持续 duration 秒。
## 数值全部来自 DataLoader.get_weapon(summon_id)，禁止硬编码。
## D13-T3：玩家装备 se_turret_array（进化「机械炮阵」）→ 炮台常驻（duration=-1）+ 部署台数 +2
## 返回 true = 部署成功进入冷却；数据缺失/无 World = false（不进冷却，零 stderr 噪音）
func _cast_deploy_turret() -> bool:
	var summon_id: String = str(skill_data.get("summon_id", "se_auto_turret"))
	var weapon_data: Dictionary = DataLoader.get_weapon(summon_id)
	if weapon_data.is_empty():
		push_warning("[SkillController] 炮台武器数据缺失: %s" % summon_id)
		return false
	var base_count: int = int(skill_data.get("summon_count", 2))
	var bonus_count: int = 0
	if player and "bonus_stats" in player:
		bonus_count = int(float(player.bonus_stats.get("summon_count", 0.0)))
	var count: int = maxi(base_count + bonus_count, 1)
	var duration: float = float(skill_data.get("duration", 15.0))
	# D13-T3：检测已装备武器是否含 se_turret_array → 常驻 + 多台（meta 键与 META_SOURCE_ID 一致）
	if player and player.has_node("WeaponController"):
		var wc: Node = player.get_node("WeaponController")
		var equipped: Array = wc.get("equipped_weapons")
		for w in equipped:
			if w and w.has_meta(&"source_id") and str(w.get_meta(&"source_id")) == "se_turret_array":
				duration = -1.0
				count += 2
				break
	var world: Node = player.get_parent()
	if world == null:
		return false
	for i in count:
		var turret: Node2D = TurretScene.instantiate()
		if turret.has_method("setup"):
			turret.setup(weapon_data, duration, player)
		world.add_child(turret)
		# 摆位：玩家为心、半径 40px 圆周均布（不挂 Player 子节点，炮台不随玩家移动）
		var angle: float = TAU * float(i) / float(count)
		turret.global_position = player.global_position + Vector2.from_angle(angle) * 40.0
	return true

## 莱恩「星刃爆发」（D3-T5）：攻速 buff + 环绕刃数字段埋点
## 本日可见性边界：环绕刃渲染机制尚不存在（属 Day 5 武器 6 槽挂载），
## 本日只做「攻速 buff 可见 + bonus_stats.orbit_blade_count 埋点」
func _cast_blade_burst() -> void:
	var effects: Dictionary = skill_data.get("effects", {})
	var duration: float = float(skill_data.get("duration", 5.0))
	var atk_percent: float = float(effects.get("attack_speed_percent", 0.0))
	var orbit_count: int = int(effects.get("orbit_blade_count", 0))

	var atk_mult: float = 1.0
	if atk_percent > 0.0 and player:
		atk_mult = 1.0 + atk_percent / 100.0
		player.apply_stat_modifier("attack_speed", atk_mult, true)
	if orbit_count > 0 and player:
		# Day 5 环绕武器机制消费此键（D3-T5 埋点，届时自动生效）
		player.bonus_stats["orbit_blade_count"] = float(player.bonus_stats.get("orbit_blade_count", 0.0)) + orbit_count

	_restore_blade_burst(duration, atk_mult, orbit_count)

## 到期还原：乘法逆元（禁止加减还原 —— attack_speed 是乘法通道，
## 加减会导致反复释放后数值漂移，见 player.gd apply_stat_modifier）
func _restore_blade_burst(duration: float, atk_mult: float, orbit_count: int) -> void:
	await get_tree().create_timer(duration).timeout
	if not is_instance_valid(player):
		return
	if atk_mult != 1.0:
		player.apply_stat_modifier("attack_speed", 1.0 / atk_mult, true)
	if orbit_count > 0:
		player.bonus_stats["orbit_blade_count"] = float(player.bonus_stats.get("orbit_blade_count", 0.0)) - orbit_count

# ========== 工具（与 weapon_controller 同一口径，避免两套瞄准/容器逻辑） ==========

## 弹丸容器：World/Projectiles 优先，回退 World（复用 WeaponController._find_container 策略）
func _find_container() -> Node2D:
	var world = player.get_parent()
	if world:
		var c = world.get_node_or_null("Projectiles")
		if c:
			return c
		return world
	return null

## 最近敌人（鼠标贴身时回退瞄准）
func _find_nearest_enemy() -> Node2D:
	if not GameManager.enemy_spawner or not GameManager.enemy_spawner.enemies_container:
		return null
	var nearest: Node2D = null
	var nearest_dist: float = INF
	for enemy in GameManager.enemy_spawner.enemies_container.get_children():
		if not is_instance_valid(enemy) or not enemy.is_alive:
			continue
		var dist: float = player.global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy
	return nearest

## 瞄准方向：鼠标世界坐标为准；鼠标贴身（< 6px）回退最近敌人，再回退朝上
func _get_aim_direction() -> Vector2:
	var mouse_pos: Vector2 = player.get_global_mouse_position()
	var to_mouse: Vector2 = player.global_position.direction_to(mouse_pos)
	if player.global_position.distance_to(mouse_pos) < 6.0:
		var near: Node2D = _find_nearest_enemy()
		if near:
			return player.global_position.direction_to(near.global_position)
		return Vector2.UP
	return to_mouse
