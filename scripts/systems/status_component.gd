## BS-A2（BOSS_SKILL_SPEC §6.2-2 · 2026-08-13）：通用持续效果组件
## 玩家 / 敌人 / Boss 挂同一组件（setup(target) 后经 apply_effect 统一施放）。
##
## O1 叠加规则（用户 2026-08-12 拍板）：
##   同源（source_id + effect_id 相同）→ 刷新计时不叠层（先还原旧属性改动再重进）
##   异源 → 各自独立实例各自 tick；max_stacks 限制同 effect_id 实例总数（超出丢弃最新）
## 到期还原 target_attr（减速/减防/麻痹还原）；dot 无视护甲直扣 hp（不播受击闪烁）
##
## 效果类型（effect 表 type 字段，BOSS_SKILL_SPEC §4.3）：
##   dot   — 持续伤害（tick_interval 跳，dps = params.dps 优先，否则 def.value + 缩放）
##   slow  — 减速（move_speed × (1 - value/100)）
##   stun  — 麻痹/眩晕（禁行动，_target.stunned 标志）
##   armor — 减防（armor - value）
##   invulnerable — 无敌（PS-B3 2026-08-16 · PLAYER_SKILL_SPEC §5/§6：受击免疫窗口，
##                   _target.invulnerable 标志；位移技能 dash/blink/leap 共用通道）
## 免疫惯例（O3/O5）：硬控（stun/knockback）Boss 免疫，软控保留——免疫表放 boss 表（BS-C 消费）
## ⚠️ 无 class_name：无头 --script 模式（探针）不注册全局类名（enemy.gd DamageNumberScript 先例），
## 消费方用 preload 引用（enemy.gd / player.gd 各自 const StatusComponentScript）
extends Node

var _target: Node = null
var _effects: Array = []   ## 效果实例：{source_id, effect_id, time_left, duration, tick_timer, params}

func setup(target: Node) -> void:
	_target = target

func get_effect_def(effect_id: String) -> Dictionary:
	return DataLoader.get_element(effect_id)

func has_effect(effect_id: String) -> bool:
	for inst in _effects:
		if str(inst.effect_id) == effect_id:
			return true
	return false

## 某效果剩余秒数（多个实例取最长；未附着 0）
func get_remaining(effect_id: String) -> float:
	var longest: float = 0.0
	for inst in _effects:
		if str(inst.effect_id) == effect_id:
			longest = maxf(longest, float(inst.time_left))
	return longest

## 某效果当前实例数（层数语义：异源实例数）
func get_stacks(effect_id: String) -> int:
	var n: int = 0
	for inst in _effects:
		if str(inst.effect_id) == effect_id:
			n += 1
	return n

## 是否处于某类型效果（stun 查询用：_target.stunned 同步）
func is_type_active(etype: String) -> bool:
	for inst in _effects:
		if str(inst.effect_id) == etype:
			return true
	return false

## O1 统一施加入口：同源刷新 / 异源独立 + max_stacks
func apply_effect(source_id: String, effect_id: String, params: Dictionary = {}) -> void:
	if _target == null or effect_id.is_empty():
		return
	var def: Dictionary = get_effect_def(effect_id)
	if def.is_empty():
		return
	var duration: float = float(params.get("duration", def.get("duration", 1.0)))
	if duration <= 0.0:
		return
	# 同源 + 同效果 → 刷新（先还原旧改动再重进，防慢速/减防叠加污染）
	for inst in _effects:
		if str(inst.source_id) == source_id and str(inst.effect_id) == effect_id:
			_revert(inst)
			inst.time_left = duration
			inst.duration = duration
			inst.tick_timer = 0.0
			inst.params = params
			_apply(inst)
			_notify_changed()
			return
	# 异源：max_stacks 限制
	var same: int = 0
	for inst in _effects:
		if str(inst.effect_id) == effect_id:
			same += 1
	if same >= int(def.get("max_stacks", 1)):
		return
	var inst := {
		"source_id": str(source_id), "effect_id": str(effect_id),
		"time_left": duration, "duration": duration, "tick_timer": 0.0, "params": params,
	}
	_effects.append(inst)
	_apply(inst)
	_notify_changed()

func _process(delta: float) -> void:
	if _effects.is_empty() or _target == null:
		return
	var expired: Array = []
	for inst in _effects:
		var def: Dictionary = get_effect_def(str(inst.effect_id))
		var etype: String = str(def.get("type", "dot"))
		if etype == "dot":
			_tick_dot(inst, def, delta)
		inst.time_left = float(inst.time_left) - delta
		if float(inst.time_left) <= 0.0:
			expired.append(inst)
	for inst in expired:
		_revert(inst)
		_effects.erase(inst)
	if not expired.is_empty():
		_notify_changed()

## dot 跳伤：按 tick_interval 跳（dps = params.dps 优先，否则 def.value + 缩放）
func _tick_dot(inst: Dictionary, def: Dictionary, delta: float) -> void:
	if _target.get("is_alive") == false:
		return
	var interval: float = maxf(float(def.get("tick_interval", 1.0)), 0.05)
	inst.tick_timer = float(inst.tick_timer) + delta
	if float(inst.tick_timer) < interval:
		return
	var ticks: int = int(float(inst.tick_timer) / interval)
	inst.tick_timer = fmod(float(inst.tick_timer), interval)
	var dps: float = float(inst.params.get("dps", def.get("value", 0.0)))
	if dps <= 0.0:
		return
	var amount: float = dps * interval * ticks
	if amount <= 0.0:
		return
	if _target.has_method("take_status_damage"):
		_target.take_status_damage(amount)
	elif "health" in _target:
		_target.health = float(_target.health) - amount
		if _target.has_signal("health_changed"):
			# ⚠️ Node.get() 只收 1 参（Object.get 无默认值重载——历史教训）
			_target.health_changed.emit(_target.health, float(_target.get("max_health")))
		if float(_target.health) <= 0.0 and _target.has_method("die"):
			_target.die()

## 效果进入：应用属性改动（slow/armor/stun）；记录原值便于还原
func _apply(inst: Dictionary) -> void:
	var def: Dictionary = get_effect_def(str(inst.effect_id))
	var etype: String = str(def.get("type", "dot"))
	match etype:
		"slow":
			if "move_speed" in _target:
				inst["orig_move_speed"] = float(_target.move_speed)
				_target.move_speed = float(_target.move_speed) * (1.0 - float(def.get("value", 0.0)) / 100.0)
		"armor":
			if "armor" in _target:
				inst["orig_armor"] = float(_target.armor)
				_target.armor = maxf(float(_target.armor) - float(def.get("value", 0.0)), 0.0)
		"stun":
			_sync_stun_flag(true)
		"invulnerable":
			if "invulnerable" in _target:
				inst["orig_invulnerable"] = bool(_target.invulnerable)
				_target.invulnerable = true

## 效果到期/刷新还原：恢复原值
func _revert(inst: Dictionary) -> void:
	var def: Dictionary = get_effect_def(str(inst.effect_id))
	var etype: String = str(def.get("type", "dot"))
	match etype:
		"slow":
			if "orig_move_speed" in inst and "move_speed" in _target:
				_target.move_speed = float(inst["orig_move_speed"])
		"armor":
			if "orig_armor" in inst and "armor" in _target:
				_target.armor = float(inst["orig_armor"])
		"stun":
			_sync_stun_flag(false)
		"invulnerable":
			if "orig_invulnerable" in inst and "invulnerable" in _target:
				_target.invulnerable = bool(inst["orig_invulnerable"])

## stun 标志与实例数同步（多实例异源并存时任一在 → stunned=true；目标须有 stunned 属性）
func _sync_stun_flag(force: bool) -> void:
	if _target == null or not ("stunned" in _target):
		return
	var any_stun: bool = force
	if not any_stun:
		for inst in _effects:
			if str(inst.effect_id) == "stun":
				any_stun = true
				break
	_target.stunned = any_stun

func _notify_changed() -> void:
	if _target != null and _target.has_signal("status_changed"):
		_target.status_changed.emit()
