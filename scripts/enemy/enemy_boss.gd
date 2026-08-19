## Boss 域组件（F4-T2 · 2026-08-14 从 enemy.gd 拆出）
## 职责：Boss 阶段状态机（F3-T4 枚举化）+ attacks 指令解析执行（D18-19）+ BS pattern 技能循环
##      （权重随机/保底不连续/phase 解锁）+ 难度合成（BS-D1）+ QTE 打断（BS-D2）+ 弹幕/召唤
## 范式：无 class_name preload 范式；setup(enemy) 注入宿主引用，经 _enemy 访问（行为零改动迁移）
extends Node

## 宿主脚本引用（取 BossPhase 枚举/PHASE_TABLE 常量——纯枚举文件零 Autoload 引用，
## 探针 --script 编译期可解析；不可 preload enemy.gd 本体，其引用 Autoload 标识符）
const EnemyEnums: GDScript = preload("res://scripts/enemy/enemy_enums.gd")
## D18-19-T3：敌人弹丸脚本。preload 而非 class_name（探针 --script 不注册全局类名）
const EnemyProjectileScript: GDScript = preload("res://scripts/enemy/enemy_projectile.gd")
## BS-C2：Boss 技能执行器工厂（无 class_name，preload 范式）
const BossSkillFactoryScript: GDScript = preload("res://scripts/boss/boss_skill_factory.gd")
## BS-D1：技能执行器基类（难度合成/参数倍率静态方法）
const SkillExecutorBaseScript: GDScript = preload("res://scripts/boss/skill_executor.gd")

## 宿主 enemy 实例（enemy._ensure_components 挂载时注入）
var _enemy: CharacterBody2D = null

func setup(enemy: CharacterBody2D) -> void:
	_enemy = enemy

# ========== Boss attacks 指令解析（D18-19-T2 · 纯函数） ==========
## enemies.json phases[].attacks 字符串指令 → 结构化字典（决策 D8：禁物理查询，全距离/容器遍历）
## 输出统一含 5 键 {kind, count, interval, mult, elite}；未知指令 push_warning + 返回 {}（不崩）
## 指令表（定案 T2-A）：
##   summon_N_enemies_every_Xs → {kind:"summon", count:N, interval:X, elite:false}
##   summon_N_elite            → {kind:"summon", count:N, interval:0.0, elite:true}（一次性）
##   N_projectile_spread       → {kind:"spread", count:N, interval:4.0}（决策 D4）
##   projectile_barrage        → {kind:"barrage", interval:4.0}（决策 D4）
##   aoe_every_Xs              → {kind:"aoe", interval:X}
##   charge_attack / _2x       → {kind:"charge", mult:1.0/2.0, interval:-1.0}（永续置位无计时）
##   all_attacks_2x            → {kind:"mult", mult:2.0, interval:-1.0}（阶段修饰符无计时）

func _parse_attack(cmd: String) -> Dictionary:
	var parts: PackedStringArray = cmd.split("_")
	if parts.is_empty():
		push_warning("[Boss] 未知攻击指令: %s" % cmd)
		return {}
	var head: String = parts[0]
	# 召唤系: summon_N_enemies_every_Xs / summon_N_elite
	if head == "summon":
		if parts.size() >= 3:
			var count: int = maxi(int(parts[1]), 0)
			if parts[2] == "elite":
				return {"kind": "summon", "count": count, "interval": 0.0, "mult": 1.0, "elite": true}
			if parts.size() >= 5 and parts[3] == "every":
				var interval: float = float(parts[4].trim_suffix("s"))
				return {"kind": "summon", "count": count, "interval": interval, "mult": 1.0, "elite": false}
	# 弹幕系: N_projectile_spread / projectile_barrage
	elif head == "projectile":
		if parts.size() >= 2 and parts[1] == "barrage":
			return {"kind": "barrage", "count": 0, "interval": 4.0, "mult": 1.0, "elite": false}
	# AOE: aoe_every_Xs
	elif head == "aoe":
		if parts.size() >= 3 and parts[1] == "every":
			var interval: float = float(parts[2].trim_suffix("s"))
			return {"kind": "aoe", "count": 0, "interval": interval, "mult": 1.0, "elite": false}
	# 冲锋: charge_attack / charge_attack_2x
	elif head == "charge":
		if parts.size() == 2 and parts[1] == "attack":
			return {"kind": "charge", "count": 0, "interval": -1.0, "mult": 1.0, "elite": false}
		if parts.size() == 3 and parts[1] == "attack" and parts[2] == "2x":
			return {"kind": "charge", "count": 0, "interval": -1.0, "mult": 2.0, "elite": false}
	# 阶段修饰符: all_attacks_2x
	elif head == "all":
		if parts.size() >= 3 and parts[1] == "attacks" and parts[2] == "2x":
			return {"kind": "mult", "count": 0, "interval": -1.0, "mult": 2.0, "elite": false}
	# 数字开头: N_projectile_spread（int 转换须回验防 "abc"→0 误判）
	elif parts.size() >= 3 and parts[1] == "projectile" and parts[2] == "spread":
		var count: int = int(head)
		if str(count) == head:
			return {"kind": "spread", "count": count, "interval": 4.0, "mult": 1.0, "elite": false}
	push_warning("[Boss] 未知攻击指令: %s" % cmd)
	return {}

# ========== Boss 阶段状态机与攻击执行器（Day 18-19 · T1/T2） ==========
## 决策引用：D1 弹丸挂自身 / D2 冲锋复用 _move_charge 只乘命中倍率 / D3 all_attacks_2x 阶段修饰符 /
## D4 spread/barrage 默认间隔 4.0s、barrage=8 向×3 波 0.25s / D5 aoe 半径 120px / D8 禁物理查询
## 全部以 is_boss + phases 双守卫，普通/精英敌人零新行为

## 血量阈值相位切换：从下一阶段起找第一个命中阈值的阶段；无更低阈值 → 保持
## F3-T4（2026-08-13）：枚举推进（_phase 单调递增语义与旧 _current_phase_idx+1 一致；
## ⚠️ Godot 4 禁 int(枚举) 转换——枚举本质 int，先赋 int 变量再运算）
func _check_phase_transition() -> void:
	var cur_idx: int = _enemy._phase
	for i in range(cur_idx + 1, _enemy.phases.size()):
		var threshold: float = float(_enemy.phases[i].get("hp_threshold_percent", 0.0)) / 100.0
		if _enemy.health / _enemy.max_health <= threshold:
			_transition_phase(i)
			return

## F3-T4（T-033 · 2026-08-13）：阶段转移统一入口（per CODE_STYLE §2.6 形态 B）——
## 同值早退 + phases 边界断言（防跳转至数据未定义阶段）+ 进入钩子（_reset_boss_phase）
func _transition_phase(next: int) -> void:
	if int(_enemy._phase) == next:
		return
	if not _enemy.PHASE_TABLE.has(next) or next >= _enemy.phases.size():
		push_warning("[Boss] 阶段越界: %d ≥ phases %d（跳过）" % [next, _enemy.phases.size()])
		return
	_reset_boss_phase(int(_enemy.PHASE_TABLE[next]))
## 激活指定阶段：清计时器 → 解析 attacks 缓存 → 修饰符/冲锋置位 → 移速 → 阶段横幅
## 形参保留 int（initialize 直调 _reset_boss_phase(0) 兼容防漂移）；_phase 同步枚举
func _reset_boss_phase(idx: int) -> void:
	_enemy._phase = clampi(idx, 0, 2)
	_enemy._attack_timers.clear()
	var phase: Dictionary = _enemy.phases[idx]
	var attacks: Array = phase.get("attacks", [])
	for cmd in attacks:
		var parsed: Dictionary = _parse_attack(str(cmd))
		if parsed.is_empty():
			continue
		_enemy._attack_timers[str(cmd)] = {"parsed": parsed, "timer": 0.0}
	# 阶段修饰符（决策 D3：all_attacks_2x → _attack_mult ×2.0，仅伤害类生效；对 summon 无效）
	if _enemy._attack_timers.has("all_attacks_2x"):
		_enemy._attack_mult *= 2.0
	# 冲锋置位（决策 D2：charge 型永续置位 _boss_charge + 命中倍率）
	_enemy._boss_charge = false
	_enemy._boss_charge_mult = 1.0
	for key in _enemy._attack_timers:
		var entry: Dictionary = _enemy._attack_timers[key]
		if str(entry.get("parsed", {}).get("kind", "")) == "charge":
			_enemy._boss_charge = true
			_enemy._boss_charge_mult = float(entry["parsed"].get("mult", 1.0))
			break
	# 阶段移速（speed_multiplier 基准 _base_speed；F-15 已定型移动倍率零改动）
	_enemy.move_speed = _enemy._base_speed * float(phase.get("speed_multiplier", 1.0))
	# 阶段横幅「⚠ Boss 进入第 N 阶段」（1.5s 淡出上浮，容器缺失静默）
	_show_boss_phase_banner(idx + 1)

## 阶段切换横幅（仿 _spawn_exp_popup / D17 精英横幅范式；容器缺失静默跳过不崩）
func _show_boss_phase_banner(phase_num: int) -> void:
	var container: Node = _enemy._resolve_fx_container()
	if container == null:
		return
	var banner := Node2D.new()
	banner.name = "BossPhaseBanner"
	var label := Label.new()
	label.text = "⚠ Boss 进入第 %d 阶段" % phase_num
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(0.95, 0.4, 0.4))
	banner.add_child(label)
	container.add_child(banner)
	banner.global_position = Vector2(320.0, 90.0)
	var tween := banner.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "modulate:a", 0.0, 1.5)
	tween.tween_property(banner, "global_position:y", banner.global_position.y - 30.0, 1.5)
	tween.chain().tween_callback(banner.queue_free)

## 攻击执行主循环：遍历 _attack_timers 计时结算；barrage 波次独立推进
func _process_boss_attacks(delta: float) -> void:
	# barrage 波次推进（8 向 × 3 波、波间隔 0.25s，决策 D4）
	if _enemy._barrage_wave > 0:
		_enemy._barrage_timer -= delta
		if _enemy._barrage_timer <= 0.0:
			_boss_spread(8)
			_enemy._barrage_wave -= 1
			_enemy._barrage_timer = 0.25
	if _enemy._attack_timers.is_empty():
		return
	var remove_keys: Array = []
	for key in _enemy._attack_timers:
		var entry: Dictionary = _enemy._attack_timers[key]
		var parsed: Dictionary = entry.get("parsed", {})
		var interval: float = float(parsed.get("interval", -1.0))
		if interval < 0.0:
			continue  # charge/mult 置位型无计时
		entry["timer"] = float(entry.get("timer", 0.0)) - delta
		if float(entry["timer"]) > 0.0:
			continue
		_execute_attack(str(parsed.get("kind", "")), parsed)
		if interval <= 0.0:
			remove_keys.append(key)  # 一次性（summon_N_elite）执行后移除
		else:
			entry["timer"] = interval
	for key in remove_keys:
		_enemy._attack_timers.erase(key)

# ========== Boss pattern 技能循环（BS-C2/C3 · 2026-08-13） ==========
## 权重随机 + 保底（同技能不连续 2 次）+ phase 解锁（100/66/33 阈值）+ 四拍子执行器复用
## 数据门控：_patterns 空 → 完全旧路径（_process_boss_attacks）

## pattern 主循环：执行器运行 → 推进；走位期 → 递减；冷却（追踪）期 → 递减；就绪 → 挑技能施放
## RELIC-F2（2026-08-19）：时间分配倒置——三段态 = 施放（executor 站定）→ 走位（skill_window
## 慢速游走）→ 追踪（冷却 × chase_ratio，短而明确）→ 施放。缺省 rhythm 键 → 与原行为等价
func _process_boss_patterns(delta: float) -> void:
	if _enemy._active_executor != null and is_instance_valid(_enemy._active_executor):
		_enemy._active_executor.call("tick", delta, {"player": _enemy.target})
		if bool(_enemy._active_executor.call("is_done")):
			_enemy._active_executor.queue_free()
			_enemy._active_executor = null
			# RELIC-F2：追踪段 = 原冷却 × chase_ratio（默认 1.0 → 原行为零变化）；
			# 走位段 = skill_window 秒（施放后游走调整站位，不施放不追踪）
			var rhythm: Dictionary = _enemy._pattern_rhythm
			_enemy._pattern_cooldown = maxf(
				_enemy._pattern_cooldown_total * float(rhythm.get("chase_ratio", 1.0)), 0.0)
			_enemy._pattern_window_timer = float(rhythm.get("skill_window", 0.0))
		return
	# 走位期推进（RELIC-F2：窗口内不 pick；倒计时归零 → 进入追踪冷却期）
	if _enemy._pattern_window_timer > 0.0:
		_enemy._pattern_window_timer -= delta
		return
	if _enemy._pattern_cooldown > 0.0:
		_enemy._pattern_cooldown -= delta
		return
	_pick_and_cast()

## 权重随机挑 pattern（_rng 实例禁全局 RNG）+ 保底不连续 + 阶段解锁
func _pick_and_cast() -> void:
	var pool: Array = _active_pattern_pool()
	if pool.is_empty() or _enemy.target == null:
		return
	var total: float = 0.0
	for p in pool:
		total += maxf(float(p.get("weight", 1.0)), 0.0)
	if total <= 0.0:
		return
	var roll: float = _enemy._rng.randf_range(0.0, total)
	var picked: Dictionary = {}
	var acc: float = 0.0
	for p in pool:
		acc += maxf(float(p.get("weight", 1.0)), 0.0)
		if roll <= acc:
			picked = p
			break
	if picked.is_empty():
		return
	# 保底：同技能不连续 2 次（仅一个技能时跳过）
	if str(picked.get("skill_id", "")) == _enemy._last_pattern_skill and pool.size() > 1:
		var alt: Array = []
		for p in pool:
			if str(p.get("skill_id", "")) != _enemy._last_pattern_skill:
				alt.append(p)
		if not alt.is_empty():
			picked = alt[_enemy._rng.randi_range(0, alt.size() - 1)]
	# C3：override 合成（技能模板 + pattern override 覆盖）
	var params: Dictionary = _compose_skill_params(picked)
	if params.is_empty():
		return
	# BS-D1（§5）：难度系数合成（基础 = 波次曲线 × 动态 = build 强度）→ 参数倍率 → 公平底线钳制
	var coeff: float = _compose_difficulty_coeff()
	if absf(coeff - 1.0) > 0.001:
		var player_speed: float = 300.0
		if _enemy.target != null and "move_speed" in _enemy.target:
			player_speed = float(_enemy.target.move_speed)
		SkillExecutorBaseScript.scale_params_by_difficulty(params, coeff, player_speed)
	var exec: Node = BossSkillFactoryScript.make(str(params.get("type", "")))
	if exec == null:
		return  # 未知 type → 跳过本轮（工厂已 push_warning），冷却由上层兜底
	exec.name = "PatternExecutor"
	_enemy.add_child(exec)
	params["player"] = _enemy.target
	params["fx_container"] = _enemy._resolve_fx_container()
	exec.call("enter", {"params": params})
	_enemy._active_executor = exec
	_enemy._last_pattern_skill = str(picked.get("skill_id", ""))
	# 冷却 = max(技能 cooldown, pattern min_interval)（大招冷却 + 最短间隔双约束）
	var cd: float = maxf(float(params.get("cooldown", 4.0)),
		float(picked.get("min_interval", 0.0)))
	_enemy._pattern_cooldown_total = cd
	_enemy._pattern_cooldown = 0.0
	# RELIC-F1（2026-08-19 · RELIC_EXPANSION_SPEC §7）：当前 pattern 节奏键缓存——
	# 施放期移速倍率 / 追踪段系数 / 走位时长 / 技能射程（F4 射程即停）。
	# 缺省兜底 1.0/1.0/0.0/0.0 = 旧数据零变化（施放期满速、原冷却、无走位、无射程钳制）
	_enemy._pattern_rhythm = {
		"cast_slowdown": float(picked.get("cast_slowdown", 1.0)),
		"chase_ratio": float(picked.get("chase_ratio", 1.0)),
		"skill_window": float(picked.get("skill_window", 0.0)),
		"range": float(params.get("radius", 0.0)),
	}

## 阶段解锁池：pattern.phase ≥ 当前阶段阈值（P1=100 / P2=66 / P3=33）
func _active_pattern_pool() -> Array:
	var threshold: int = 100
	# _enemy._phase 为 BossPhase 枚举（P1=0 / P2=1 / P3=2），禁 int(枚举) 隐式转换——直接比较
	if _enemy._phase == 1:
		threshold = 66
	elif _enemy._phase == 2:
		threshold = 33
	var pool: Array = []
	for p in _enemy._patterns:
		if int(p.get("phase", 100)) >= threshold:
			pool.append(p)
	return pool

## C3：override 合成（skill 模板 → pattern override 覆盖；merge 顺序 = 模板 → override）
func _compose_skill_params(pattern: Dictionary) -> Dictionary:
	var skill: Dictionary = DataLoader.get_boss_skill(str(pattern.get("skill_id", "")))
	if skill.is_empty():
		return {}
	var params: Dictionary = skill.duplicate(true)
	var override: Variant = pattern.get("override", {})
	if override is Dictionary:
		for k in override:
			params[k] = override[k]
	return params

## BS-D1（§5 · 2026-08-13）：难度系数合成——基础难度（波次曲线）× 动态难度（build 强度）
## 最小可验证口径：基础 = 1.0 + (wave-1)×0.02；动态 = 1.0 + 0.05×已装备武器/道具数
## （GameManager.inventory 缺失环境兜底 1.0）；compose_difficulty clamp 0.5~2.0
func _compose_difficulty_coeff() -> float:
	var base: float = 1.0 + float(maxi(_enemy.wave_number, 1) - 1) * 0.02
	var build: float = 1.0
	if GameManager and GameManager.inventory:
		var n: int = int(GameManager.inventory.get_weapons().size()) \
			+ int(GameManager.inventory.get_items().size())
		build = 1.0 + 0.05 * n
	return SkillExecutorBaseScript.compose_difficulty(base, build)

## BS-D2（§2.4 · 2026-08-13）：QTE 打断钩子——resolve 窗口内玩家攻击命中（take_damage）
## → 当前执行器 interrupt()（中断即豁免，失败不致命）
func _interrupt_active_executor() -> void:
	if _enemy._active_executor != null and is_instance_valid(_enemy._active_executor) \
			and _enemy._active_executor.has_method("interrupt"):
		_enemy._active_executor.call("interrupt")

## 按 kind 分派执行器（全距离/容器遍历，禁物理查询，决策 D8）
func _execute_attack(kind: String, parsed: Dictionary) -> void:
	match kind:
		"summon":
			_boss_summon(maxi(int(parsed.get("count", 0)), 0), bool(parsed.get("elite", false)))
		"spread":
			_boss_spread(maxi(int(parsed.get("count", 0)), 0))
		"barrage":
			_boss_barrage()
		"aoe":
			_boss_aoe()
		_:
			push_warning("[Boss] 未知执行指令 kind: %s" % kind)

## Boss 召唤（regular/elite 池随机取 id，同波缩放，进 Enemies 容器计入存活 ✅）
## 容器/场景解析复用 _elite_spawn 范式
func _boss_summon(count: int, elite: bool) -> void:
	if count <= 0:
		return
	var pool: Array = DataLoader.get_enemy_ids_by_category("elite" if elite else "regular")
	if pool.is_empty():
		return
	var scene: PackedScene = null
	if GameManager and GameManager.enemy_spawner and GameManager.enemy_spawner.enemy_scene:
		scene = GameManager.enemy_spawner.enemy_scene
	else:
		scene = load("res://scenes/Enemy.tscn")
	if scene == null:
		return
	for _i in count:
		var enemy_id: String = str(pool[_enemy._rng.randi_range(0, pool.size() - 1)])
		var stats: Dictionary = DataLoader.get_scaled_enemy(enemy_id, _enemy.wave_number)
		if stats.is_empty():
			continue
		var minion_node: Node = _spawn_minion_node(scene, stats)
		if minion_node == null:
			# 容器/工厂不可用（异常环境）→ 中止本次召唤（与原「容器 null → return」同语义）
			return
		if GameManager and GameManager.player and minion_node.has_method("set_target"):
			minion_node.set_target(GameManager.player)

## F2-T4：召唤物统一经 World.spawn_minion 工厂（instantiate + initialize 透传 + 挂 Enemies
## 容器；initialize 必须先于 add_child —— _ready 用 max_health 初始化 health）。
## World 缺失环境（探针白盒/非战斗场景）→ 兜底旧路径（instantiate + initialize + 容器 add_child）。
## 容器/工厂均不可用 → 返回 null（调用方按原「容器 null → return」语义中止召唤）
func _spawn_minion_node(scene: PackedScene, stats: Dictionary) -> Node:
	var world: Node = GameManager.get_world() if GameManager else null
	if world and world.has_method("spawn_minion"):
		return world.spawn_minion(scene, stats)
	# 兜底旧路径
	var container: Node = null
	if GameManager and GameManager.enemies_container:
		container = GameManager.enemies_container
	elif GameManager and GameManager.enemy_spawner and GameManager.enemy_spawner.enemies_container:
		container = GameManager.enemy_spawner.enemies_container
	if container == null:
		return null
	var minion_node: Node = scene.instantiate()
	if minion_node.has_method("initialize"):
		minion_node.initialize(stats)
	container.add_child(minion_node)
	return minion_node

## 环形弹幕：count 向均匀分布，基准角朝玩家，单发伤害 damage × _attack_mult
func _boss_spread(count: int) -> void:
	if count <= 0:
		return
	var base: float = 0.0
	if _enemy.is_target_valid():
		base = _enemy.global_position.direction_to(_enemy.target.global_position).angle()
	for i in count:
		var angle: float = base + TAU * float(i) / float(count)
		_spawn_enemy_projectile(Vector2.from_angle(angle))

## 弹幕风暴：8 向 × 3 波、波间隔 0.25s（决策 D4；由 _process_boss_attacks 推进波次）
func _boss_barrage() -> void:
	_enemy._barrage_wave = 3
	_enemy._barrage_timer = 0.0

## AOE：玩家距离 ≤ 120px（决策 D5）→ 伤害 × _attack_mult + crit 特效（容器缺失静默）
func _boss_aoe() -> void:
	if not _enemy.is_target_valid() or not _enemy.target.has_method("take_damage"):
		return
	if _enemy.global_position.distance_to(_enemy.target.global_position) <= 120.0:
		_enemy.target.take_damage(_enemy.damage * _enemy._attack_mult)
		var fx_container: Node = _enemy._resolve_fx_container()
		if fx_container:
			VfxPlayer.spawn(fx_container, _enemy.target.global_position, "crit")
		AudioManager.play_sfx("crit")   # D24-T3-③：Boss AOE 命中 SFX（D30 收敛点 2/2）

## 实例化敌人弹丸并挂到自身（决策 D1：防 Enemies 容器 alive-count 污染；随父销毁）
func _spawn_enemy_projectile(dir: Vector2) -> void:
	var proj: Node = EnemyProjectileScript.new()
	if proj.has_method("initialize"):
		proj.initialize({
			"speed": 220.0,
			"damage": _enemy.damage * _enemy._attack_mult,
			"lifetime": 2.0,
		})
	if proj.has_method("set_direction"):
		proj.set_direction(dir)
	_enemy.add_child(proj)
