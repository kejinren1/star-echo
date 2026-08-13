## BS-D2（BOSS_SKILL_SPEC §2.3 · 2026-08-13）：charge 冲锋技能执行器（同骨架换参数）
## 四拍子：telegraph（蓄力）→ resolve（沿 facing 冲向玩家路径，路径命中判距）→ recover
## 参数：center / facing / charge_distance / hit_radius / telegraph / resolve_delay / damage
## QTE（§2.4）：resolve 窗口内玩家攻击命中 → interrupt() 中断（失败不致命：中断即豁免）
extends "res://scripts/boss/skill_executor.gd"

var _start: Vector2 = Vector2.ZERO
var _dir: Vector2 = Vector2.RIGHT
var _distance: float = 200.0
var _hit_radius: float = 40.0
var _resolved: bool = false

func _spawn_telegraph() -> void:
	_start = _params.get("center", Vector2.ZERO)
	_dir = _params.get("facing", Vector2.RIGHT).normalized()
	_distance = float(_params.get("charge_distance", 200.0))
	_hit_radius = float(_params.get("hit_radius", 40.0))
	_resolved = false

## 进入 RESOLVE（伤害在 _do_resolve——resolve_delay 后落地，窗口期可 interrupt）
func _resolve() -> void:
	pass

func _do_resolve() -> void:
	if _resolved:
		return
	_resolved = true
	var player: Node = _params.get("player", null)
	if player == null or not is_instance_valid(player):
		return
	# 冲锋路径 = 线段（start → start+dir×distance）；玩家到线段距离 ≤ hit_radius → 命中
	var v: Vector2 = player.global_position - _start
	var t: float = clampf(v.dot(_dir), 0.0, _distance)
	var closest: Vector2 = _start + _dir * t
	if closest.distance_to(player.global_position) <= _hit_radius:
		var dmg: float = float(_params.get("damage", 0.0))
		if dmg > 0.0 and player.has_method("take_damage"):
			player.take_damage(dmg)

func _recover() -> void:
	phase = Phase.RECOVER

## QTE：resolve 窗口内被打断 → 立即结束（豁免伤害；勿调 _recover——会覆写 DONE）
func interrupt() -> void:
	if phase == Phase.RESOLVE:
		phase = Phase.DONE
