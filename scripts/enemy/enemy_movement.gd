## 敌人移动行为组件（F4-T1 · 2026-08-14 从 enemy.gd 拆出）
## 职责：行为枚举分派（_update_behavior）+ 六种移动（chase/charge/zigzag/ranged/heal/spawn）
##      + 击退（_process_knockback/apply_knockback）+ 接触伤害（_try_contact_damage）
##      + 精英能力（_elite_aoe/_elite_self_heal/_elite_spawn）
## 范式：无 class_name preload 范式（探针 --script 不注册全局类名，StatusComponent 先例）；
##      setup(enemy) 注入宿主引用，组件内全部经 _enemy 访问——行为零改动迁移
## F-46（2026-08-18 用户反馈「怪物越跑越远找不到→无法通关」）：追踪逻辑参考成熟方案
## （Godot 社区标准做法：Seek + Aggro Leash + Circle-Strafing with inward bias）：
##   · Aggro Leash 战斗锁链：所有行为统一——与玩家距离 > LEASH_RADIUS 强制直追（_move_chase），
##     无视 ranged/zigzag 等绕圈行为，保证怪永远在玩家可战视野内。根治「怪漂出屏幕 →
##     找不到 → 普通关永不判通死锁」（F-44 只兜竞技场边界，但竞技场 1536×864 比屏幕
##     640×360 大 2.4 倍，场内远端仍不可见不可打）
##   · Orbit 收敛环绕（ranged）：切向绕圈 ×0.7 + 指向玩家 ×0.3 归一化——保持距离同时
##     趋势收敛，不再纯切向漂移（原实现被边界 clamp 后贴边滑动 = 观感「厌倦玩家越跑越远」）
##   · Seek 直追保留（chase/charge 等）；行为状态机保留（behavior 枚举 = 成熟 FSM 范式）
extends Node

## 宿主脚本引用（取 Behavior 枚举/BEHAVIOR_MAP 常量——纯枚举文件零 Autoload 引用，
## 探针 --script 编译期可解析；不可 preload enemy.gd 本体，其引用 Autoload 标识符）
const EnemyEnums: GDScript = preload("res://scripts/enemy/enemy_enums.gd")

## F-46：Aggro Leash 战斗锁链半径（px）——与玩家距离超过此值 → 无视行为强制直追。
## 420px ≈ 屏幕半宽(320)+余量，保证怪永不出玩家视野可战范围（成熟方案：aggro leash）
const LEASH_RADIUS: float = 420.0

## 宿主 enemy 实例（enemy._ensure_components 挂载时注入）
var _enemy: CharacterBody2D = null

func setup(enemy: CharacterBody2D) -> void:
	_enemy = enemy

## 行为主循环（原 enemy._physics_process 中段：软控 → 行为 → 接触伤害 → 击退）
func tick(delta: float) -> void:
	if _enemy == null or not _enemy.is_alive:
		return
	# O2 软控（BS-A3）：麻痹禁行动（跳过行为/接触伤害；击退仍结算）
	if _enemy.stunned:
		_enemy.velocity = Vector2.ZERO
		_process_knockback()
		return
	_update_behavior(delta)
	# 接触伤害（带冷却）
	if _enemy._contact_cd > 0.0:
		_enemy._contact_cd -= delta
	_try_contact_damage()
	# 击退结算（行为移动后覆盖 velocity 推离，随帧衰减；零向量时零开销）
	_process_knockback()

# ========== 行为系统 ==========

## 根据行为模式更新移动（原 enemy._update_behavior）
## F-46：行为分派前先过 Aggro Leash——超战斗半径强制直追（含 Boss 移动段，Boss 追击
## 玩家属直追语义零回归；防击退/绕圈漂移把怪推出玩家可战视野 → 找不到 → 无法通关）
func _update_behavior(delta: float) -> void:
	if not _enemy.is_target_valid():
		return
	# F-46 Aggro Leash：距离 > LEASH_RADIUS → 无视行为直追玩家（成熟方案：战斗锁链）
	if _enemy.global_position.distance_to(_enemy.target.global_position) > LEASH_RADIUS:
		_move_chase(delta)
		return
	# Day 18-19 · T1/T2：Boss 阶段模式（优先于行为枚举；普通/精英零影响——双条件守卫）
	# BS-C2（2026-08-13）：新 pattern 循环优先接管技能释放；旧 attacks 指令保留为降级
	# （无 pattern 数据 → 完全旧行为，day18_19 回归兜底）
	if _enemy.is_boss and not _enemy.phases.is_empty():
		if not _enemy._patterns.is_empty():
			_enemy._boss_ctrl._process_boss_patterns(delta)
		else:
			_enemy._boss_ctrl._process_boss_attacks(delta)
		if _enemy._boss_charge:
			_move_charge(delta)
		else:
			_move_chase(delta)
		return
	match int(_enemy.behavior):
		EnemyEnums.Behavior.CHASE:
			_move_chase(delta)
		EnemyEnums.Behavior.CHARGE:
			_move_charge(delta)
		EnemyEnums.Behavior.ZIGZAG:
			_move_zigzag(delta)
		EnemyEnums.Behavior.RANGED:
			_move_ranged(delta)
		EnemyEnums.Behavior.HEAL:
			_move_heal(delta)
		EnemyEnums.Behavior.SPAWN:
			_move_spawn(delta)
			# Day 17 · D17-T2：精英产卵（mom）；ability 空 → 立即 return 零影响（regular 产卵者）
			_elite_spawn(delta)
		EnemyEnums.Behavior.STATIONARY:
			pass  # 不移动
		EnemyEnums.Behavior.AOE_ATTACK:
			_move_chase(delta)  # 精英 AOE 近身
			_elite_aoe(delta)   # Day 17 · D17-T2：butcher 周期 AOE
		EnemyEnums.Behavior.SELF_HEAL:
			_move_chase(delta)  # 精英自愈近身
			_elite_self_heal(delta)  # Day 17 · D17-T2：monk 低血周期自愈

## 直追玩家
func _move_chase(_delta: float) -> void:
	var direction := _enemy.global_position.direction_to(_enemy.target.global_position)
	_enemy.velocity = direction * _enemy.move_speed
	_enemy.move_and_slide()

## 冲锋：周期性蓄力后高速冲向玩家
func _move_charge(delta: float) -> void:
	_enemy._charge_timer -= delta
	if _enemy._is_charging:
		# F-15（用户拍板 2026-08-06 · P0）：冲锋倍率 ×2.5 → ×1.5（配合 F-01 移速×0.5，
		# 冲速 425×1.5×0.5≈319，恢复可反应区间，消除「被冲脸瞬秒」围杀体验）
		# T-009（F1-散 2026-08-13）：倍率参数化 = scaling.charge_speed_mult
		_enemy.velocity = _enemy._charge_dir * _enemy.move_speed * _enemy._charge_speed_mult
		_enemy.move_and_slide()
		if _enemy._charge_timer <= 0.0:
			_enemy._is_charging = false
			_enemy._charge_timer = _enemy._charge_windup  # 蓄力间隔（T-009）
	else:
		# 蓄力期间缓慢移动
		var direction := _enemy.global_position.direction_to(_enemy.target.global_position)
		_enemy.velocity = direction * _enemy.move_speed * 0.3
		_enemy.move_and_slide()
		if _enemy._charge_timer <= 0.0:
			_enemy._is_charging = true
			_enemy._charge_dir = _enemy.global_position.direction_to(_enemy.target.global_position)
			_enemy._charge_timer = _enemy._charge_duration  # 冲锋持续（T-009）

## Z 形移动
func _move_zigzag(delta: float) -> void:
	_enemy._zigzag_timer -= delta
	if _enemy._zigzag_timer <= 0.0:
		_enemy._zigzag_dir *= -1.0
		_enemy._zigzag_timer = 0.5
	var direction := _enemy.global_position.direction_to(_enemy.target.global_position)
	# 在追踪方向上叠加垂直偏移（_zigzag_dir 经宿主访问为 Variant → 显式 float 防 := 推断失败）
	var perp: Vector2 = Vector2(-direction.y, direction.x) * float(_enemy._zigzag_dir)
	_enemy.velocity = (direction + perp * 0.6).normalized() * _enemy.move_speed
	_enemy.move_and_slide()

## 远程：保持距离（F-44 + F-46 2026-08-18 用户拍板：常规绝不逃离主角——
## 原「dist<200 反向逃跑」会被玩家追击一路推出地图外 → 怪在屏幕外 wave 永远清不完无法通关；
## F-44 改永不后退（太远靠近 / 中近距横向绕圈）；F-46 再改 **Orbit 收敛环绕**：
## 绕圈速度 = 切向×0.7 + 指向玩家×0.3（归一化）——保持距离同时趋势收敛，
## 不再纯切向漂移（纯切向被边界 clamp 后贴边滑动 = 观感「厌倦玩家越跑越远」）；
## 叠加 tick 末边界钳制 + _update_behavior 层 Aggro Leash 双保险）
func _move_ranged(_delta: float) -> void:
	var dist := _enemy.global_position.distance_to(_enemy.target.global_position)
	var direction := _enemy.global_position.direction_to(_enemy.target.global_position)
	var perp := Vector2(-direction.y, direction.x)
	if dist > 300.0:
		# 太远，靠近
		_enemy.velocity = direction * _enemy.move_speed * 0.5
	else:
		# 中近距：Orbit 收敛环绕（切向绕圈 ×0.7 + 指向玩家 ×0.3 归一化）
		_enemy.velocity = (perp * 0.7 + direction * 0.3).normalized() * _enemy.move_speed * 0.8
	_enemy.move_and_slide()

## 治疗：跟随友军并治疗
func _move_heal(_delta: float) -> void:
	# 简单跟随玩家附近
	var direction := _enemy.global_position.direction_to(_enemy.target.global_position)
	var dist := _enemy.global_position.distance_to(_enemy.target.global_position)
	if dist > 250.0:
		_enemy.velocity = direction * _enemy.move_speed
	else:
		_enemy.velocity = Vector2.ZERO
	_enemy.move_and_slide()

## 产卵：缓慢移动
func _move_spawn(_delta: float) -> void:
	var direction := _enemy.global_position.direction_to(_enemy.target.global_position)
	_enemy.velocity = direction * _enemy.move_speed * 0.5
	_enemy.move_and_slide()

# ========== 击退与接触伤害 ==========

## 击退结算：覆盖 velocity 推离一帧 + 衰减 50%/帧，小于阈值清零（原 enemy._process_knockback）
func _process_knockback() -> void:
	if _enemy._knockback == Vector2.ZERO:
		return
	_enemy.velocity = _enemy._knockback
	_enemy.move_and_slide()
	# T-015（F1-散 2026-08-13）：衰减率参数化 = stats.combat.knockback_decay
	_enemy._knockback = _enemy._knockback * _enemy._knockback_decay
	if _enemy._knockback.length() < 8.0:
		_enemy._knockback = Vector2.ZERO

## 受击击退接口（升级冲击波等外部施加）：dir 为方向（无需归一化）、force 为初速
func apply_knockback(dir: Vector2, force: float) -> void:
	if not _enemy.is_alive:
		return
	if dir.length_squared() <= 0.0001 or force <= 0.0:
		return
	_enemy._knockback = dir.normalized() * force

## 当敌人贴近玩家时造成伤害（初版：所有行为通用）
func _try_contact_damage() -> void:
	if not _enemy.is_target_valid() or _enemy._contact_cd > 0.0:
		return
	var dist := _enemy.global_position.distance_to(_enemy.target.global_position)
	# D21-22-T1（决策 D16）：接触判定用 hit_radius（换皮解耦），缺省 = 旧公式
	var contact_range: float = _enemy.hit_radius if _enemy.hit_radius > 0.0 else (_enemy.frame_size.x * 0.5 + 12.0)
	if dist <= contact_range and _enemy.target.has_method("take_damage"):
		# D18-19-T2（决策 D2）：Boss 冲锋命中伤害 × _boss_charge_mult（普通敌人恒 ×1.0）
		_enemy.target.take_damage(_enemy.damage * (_enemy._boss_charge_mult if (_enemy.is_boss and _enemy._boss_charge) else 1.0))
		# T-015（F1-散 2026-08-13）：接触冷却参数化 = stats.combat.contact_cooldown
		_enemy._contact_cd = _enemy._contact_cooldown

# ========== 精英特殊能力（Day 17 · D17-T2） ==========
## 三能力全部用距离判断 + 容器遍历，禁物理查询（无头稳定铁律，D3 火球物理先例）。
## ability 空（colossus/rhino/croc 缺省）→ 立即 return，零行为回归。

## AOE 攻击（butcher）：周期对 radius 内玩家造成 damage × damage_mult
func _elite_aoe(delta: float) -> void:
	if _enemy.ability.is_empty():
		return
	_enemy._ability_timer -= delta
	if _enemy._ability_timer > 0.0:
		return
	var radius: float = float(_enemy.ability.get("radius", 0.0))
	var damage_mult: float = float(_enemy.ability.get("damage_mult", 1.0))
	if radius > 0.0 and _enemy.is_target_valid() and _enemy.target.has_method("take_damage"):
		if _enemy.global_position.distance_to(_enemy.target.global_position) <= radius:
			_enemy.target.take_damage(_enemy.damage * damage_mult)
			var fx_container: Node = _enemy._resolve_fx_container()
			if fx_container:
				VfxPlayer.spawn(fx_container, _enemy.target.global_position, "crit")
			AudioManager.play_sfx("crit")   # D24-T3-③：精英 AOE 命中 SFX（D30 收敛点 2/2）
	_enemy._ability_timer = float(_enemy.ability.get("interval", 1.0))

## 自愈（monk）：血量 < max_health × threshold 时周期恢复 heal_percent% 最大生命
func _elite_self_heal(delta: float) -> void:
	if _enemy.ability.is_empty():
		return
	_enemy._ability_timer -= delta
	if _enemy._ability_timer > 0.0:
		return
	var threshold: float = float(_enemy.ability.get("threshold", 0.5))
	var heal_percent: float = float(_enemy.ability.get("heal_percent", 0.0))
	if heal_percent > 0.0 and _enemy.health < _enemy.max_health * threshold:
		_enemy.health = min(_enemy.max_health, _enemy.health + _enemy.max_health * heal_percent)
		_enemy.health_changed.emit(_enemy.health, _enemy.max_health)
		var fx_container: Node = _enemy._resolve_fx_container()
		if fx_container:
			VfxPlayer.spawn(fx_container, _enemy.global_position, "levelup")
	_enemy._ability_timer = float(_enemy.ability.get("interval", 1.0))

## 产卵（mom）：周期生成 count 只 minion（用自身 wave_number 同波缩放）
func _elite_spawn(delta: float) -> void:
	if _enemy.ability.is_empty():
		return
	_enemy._ability_timer -= delta
	if _enemy._ability_timer > 0.0:
		return
	var minion: String = str(_enemy.ability.get("minion", ""))
	var count: int = maxi(int(_enemy.ability.get("count", 0)), 0)
	if minion.is_empty() or count <= 0:
		_enemy._ability_timer = float(_enemy.ability.get("interval", 1.0))
		return
	# 容器：优先 GameManager.enemies_container（main 接线）；缺失静默跳过不崩
	var container: Node = null
	if GameManager and GameManager.enemies_container:
		container = GameManager.enemies_container
	elif GameManager and GameManager.enemy_spawner and GameManager.enemy_spawner.enemies_container:
		container = GameManager.enemy_spawner.enemies_container
	if container == null:
		return
	# 敌人场景：优先 spawner 已加载资源，否则延迟 load（避免脚本 preload 自身场景循环）
	var scene: PackedScene = null
	if GameManager and GameManager.enemy_spawner and GameManager.enemy_spawner.enemy_scene:
		scene = GameManager.enemy_spawner.enemy_scene
	else:
		scene = load("res://scenes/Enemy.tscn")
	if scene == null:
		return
	for _i in count:
		var stats: Dictionary = DataLoader.get_scaled_enemy(minion, _enemy.wave_number)
		if stats.is_empty():
			break
		# F2-T4：召唤物统一经 boss 组件 _spawn_minion_node 工厂（instantiate + initialize + 挂容器）
		var minion_node: Node = _enemy._boss_ctrl._spawn_minion_node(scene, stats)
		if minion_node == null:
			# 容器/工厂不可用（异常环境）→ 中止本次召唤（与原「容器 null → return」同语义）
			_enemy._ability_timer = float(_enemy.ability.get("interval", 1.0))
			return
		if GameManager and GameManager.player and minion_node.has_method("set_target"):
			minion_node.set_target(GameManager.player)
	_enemy._ability_timer = float(_enemy.ability.get("interval", 1.0))
