## 受伤与死亡组件（F4-T3 · 2026-08-14 从 enemy.gd 拆出）
## 职责：take_damage（F1-C 平直减护甲 + F-11 暴击伤害数字）+ die 击杀链路（掉落/经验/
##      boss_killed 登记/F-28 通关判定/死亡动画）+ 掉落与飘字
## 范式：无 class_name preload 范式；setup(enemy) 注入宿主引用，经 _enemy 访问（行为零改动迁移）
extends Node

## F-11（用户拍板 2026-08-06）：伤害数字飘字脚本。preload 而非 class_name——
## 无头 --script 模式（探针）不注册全局类名（main.gd:20 同策略），静态方法经脚本引用调用
const DamageNumberScript: GDScript = preload("res://scripts/effects/damage_number.gd")

## 宿主 enemy 实例（enemy._ensure_components 挂载时注入）
var _enemy: CharacterBody2D = null

func setup(enemy: CharacterBody2D) -> void:
	_enemy = enemy

# ========== 受伤与死亡 ==========

## 受到伤害 (考虑护甲减伤)
## F-11（用户拍板 2026-08-06）：新增可选 is_crit 参数——默认 false 零回归（DoT/接触/旧调用
## 不传即普通伤害数字）；projectile 线弹/AOE 透传真实暴击态 → 金色大字号「N!」
func take_damage(amount: float, is_crit: bool = false) -> void:
	if not _enemy.is_alive:
		return
	# 护甲减伤（F1-C · 用户 2026-08-10 拍板「伤害-护甲=最终伤害」平直减法，与 player.gd 同式）
	var actual_damage: float = max(amount - _enemy.armor, 1.0)
	_enemy.health -= actual_damage
	_enemy.health_changed.emit(_enemy.health, _enemy.max_health)
	_enemy._play_hit_flash()
	_spawn_damage_number(actual_damage, is_crit)
	if _enemy.health <= 0.0:
		die()
		return
	# Day 18-19 · T1：存活命中 → 相位阈值检查（决策 D6：击杀瞬间不触发切换/残留横幅）
	if _enemy.is_boss and not _enemy.phases.is_empty():
		_enemy._boss_ctrl._check_phase_transition()
	# BS-D2（§2.4）：QTE 打断钩子——存活命中时若当前技能处于打断窗口 → interrupt（中断即豁免）
	_enemy._boss_ctrl._interrupt_active_executor()

## 死亡处理：播放死亡动画，掉落金币/经验，发射信号
func die() -> void:
	_enemy.is_alive = false
	_enemy.health = 0.0
	# G-C（R3 图鉴）：敌人首次击杀记录（去重查表零开销——record_codex 内部 has 检查）
	GameManager.record_codex("enemy", _enemy.enemy_id)
	_drop_rewards()
	_enemy.died.emit(_enemy)
	# Day 18-19 · T1 + F2-T5（T-045）：Boss 击杀信号化——die 内不再直调
	# GM.register_boss_killed（消灭实体→系统硬调用），由 main 装配 boss_killed → GM 订阅；
	# 双守卫 is_boss + has_signal 防纯数据探针异常
	if _enemy.is_boss and _enemy.has_signal("boss_killed"):
		_enemy.boss_killed.emit()
	# F-28（2026-08-08 用户拍板）：击杀后触发通关判定——普通关敌全灭 / Boss 关 Boss 击杀
	# （此前通关只由波次倒计时触发：Boss 没死超时也通 / Boss 死了要等倒计时）
	if GameManager and GameManager.wave_manager and GameManager.wave_manager.has_method("check_wave_clear"):
		GameManager.wave_manager.check_wave_clear()
	# 播放死亡动画后销毁
	if _enemy._anim and _enemy._anim.sprite_frames and _enemy._anim.sprite_frames.has_animation("death"):
		_enemy._anim.play("death")
		_enemy._anim.animation_finished.connect(func(): _enemy.queue_free())
	else:
		_enemy.queue_free()

## 掉落奖励
func _drop_rewards() -> void:
	if GameManager.economy:
		GameManager.economy.add_coins(_enemy.coin_value)
	# D4-T1：经验直接结算（不造磁吸宝石实体，见 TASKS Day 4 总定案）
	if GameManager.player and GameManager.player.has_method("gain_exp"):
		GameManager.player.gain_exp(_enemy.exp_value)
		# D6-T4（T-B · P1）：击杀经验飘字「+N」（方案 A；容器缺失时静默跳过不崩）
		_spawn_exp_popup(_enemy.exp_value)
	# PS-C2（2026-08-16 · PLAYER_SKILL_SPEC §7 D4/D5）：技能掉落
	# 精英怪 80% 触发技能三选一（20% 替代 = 金币/经验已给，静默跳过）；章 Boss 招牌技必掉
	# 触发判定纯数据（drop_source）；掉落逻辑挂尾段，金币/经验掉落零改动
	_maybe_drop_skill()

## PS-C2：技能掉落判定（§7 · D4 精英 80% / D5 章 Boss 必掉）
## 精英：DataLoader.get_skill_relics_by_source("elite") 随机池，80% 触发 → 进三选一装配
## 章 Boss：按 boss 数据 drop_source="chapter_boss" 的遗物必掉（教学闭环）
func _maybe_drop_skill() -> void:
	var category: String = ""
	if _enemy and _enemy.has_method("get_category"):
		category = str(_enemy.call("get_category"))
	var is_chapter_boss: bool = _enemy.is_boss and _is_chapter_boss()
	if category == "elite" and not _enemy.is_boss:
		if randf() > 0.8:
			return  # D4 20% 替代奖励：金币/经验已随 _drop_rewards 结算，无额外掉落
		var pool: Array = DataLoader.get_skill_relics_by_source("elite")
		if pool.is_empty():
			return
		_offer_skill_choice(pool)
	elif is_chapter_boss:
		var pool: Array = DataLoader.get_skill_relics_by_source("chapter_boss")
		if pool.is_empty():
			return
		_offer_skill_choice(pool)

## 章 Boss 判定：boss 数据含 chapter 字段（PS-D 章节化后使用）；现回落 is_boss + 必掉逻辑
func _is_chapter_boss() -> bool:
	return false  # PS-D 章节化前：无章节 Boss 标记，Boss 掉落走旧路径

## PS-C3：三选一装配弹窗（复用 LevelUpPanel 暂停式范式；选择后装配到槽位）
## PS-E2：装配目标槽 = 局外等级已解锁槽位（skill_unlocks 门槛表；无解锁 → 槽 1 兜底）
## 简化实现：直接装配到已解锁最低空槽（槽满 → 替换该槽，可换可不换 = 覆盖）
func _offer_skill_choice(pool: Array) -> void:
	if GameManager.player == null:
		return
	var controller: Node = GameManager.player.get_node_or_null("SkillController")
	if controller == null or not controller.has_method("equip_slot"):
		return
	var char_id: String = str(GameManager.current_character_id)
	var pick: Dictionary = pool[randi() % pool.size()]
	var resolved: Dictionary = DataLoader.resolve_relic_skill(pick, char_id)
	if resolved.is_empty() or str(resolved.get("type", "")).is_empty():
		return
	var data: Dictionary = {"id": str(resolved.get("type", "")), "type": str(resolved.get("type", ""))}
	var params: Dictionary = resolved.get("params", {})
	for k in params:
		data[k] = params[k]
	# 目标槽：已解锁槽位优先（PS-E2）；无解锁记录 → 槽 1（批量 A 初始可用）
	var slots: Array = []
	if GameManager.has_method("get_unlocked_slots"):
		slots = GameManager.get_unlocked_slots(char_id)
	if slots.is_empty():
		slots = [1]
	var target_slot: int = 1
	var skills: Array = controller.get("skills")
	for s in slots:
		var slot_idx: int = int(s)
		if skills.size() > slot_idx and str(skills[slot_idx].get("id", "")) == "":
			target_slot = slot_idx
			break
	# 全占满 → 覆盖最后解锁槽（可换可不换语义）
	if target_slot == 1 and skills.size() > 1 and str(skills[1].get("id", "")) != "":
		target_slot = int(slots[slots.size() - 1]) if not slots.is_empty() else 2
	controller.call("equip_slot", target_slot, data)
	# 飘字提示（复用 exp popup 范式）
	if GameManager.vfx_container:
		var label := Label.new()
		label.text = "获得技能: %s" % str(pick.get("name", ""))
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
		GameManager.vfx_container.add_child(label)
		label.global_position = _enemy.global_position + Vector2(0, -40)
		var tween := label.create_tween()
		tween.tween_property(label, "modulate:a", 0.0, 1.2)
		tween.chain().tween_callback(label.queue_free)

## D6-T4：击杀经验飘字（0.6s 上浮 + 淡出后消失）
func _spawn_exp_popup(amount: int) -> void:
	var container: Node = GameManager.vfx_container if GameManager.vfx_container else null
	if container == null:
		container = _enemy.get_tree().current_scene
	if container == null:
		return  # 无容器（如纯数据测试）静默跳过
	var label := Label.new()
	label.text = "+%d" % amount
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.45, 0.85, 1.0))
	container.add_child(label)
	label.global_position = _enemy.global_position + Vector2(randf_range(-10.0, 10.0), -28.0)
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position:y", label.global_position.y - 26.0, 0.6)
	tween.tween_property(label, "modulate:a", 0.0, 0.6)
	tween.chain().tween_callback(label.queue_free)

## F-11（用户拍板 2026-08-06）：受击伤害数字飘字（普通浅黄 / 暴击金色大字号「N!」）
## 容器解析复用 _spawn_exp_popup 范式：vfx_container → current_scene → 无容器跳过不崩
func _spawn_damage_number(amount: float, is_crit: bool) -> void:
	var container: Node = GameManager.vfx_container if GameManager.vfx_container else null
	if container == null:
		container = _enemy.get_tree().current_scene
	if container == null:
		return
	DamageNumberScript.spawn(container, _enemy.global_position, amount, is_crit)
