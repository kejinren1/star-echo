## BS-D2（BOSS_SKILL_SPEC §2.3 · 2026-08-13）：beam 光束技能执行器（同骨架换参数）
## 四拍子：telegraph（光束预警线）→ resolve（玩家到 beam 线段距离 ≤ width 命中）→ recover
## 参数：origin / dir / length / width / telegraph / resolve_delay / damage / effects
extends "res://scripts/boss/skill_executor.gd"

var _origin: Vector2 = Vector2.ZERO
var _dir: Vector2 = Vector2.RIGHT
var _length: float = 400.0
var _width: float = 40.0
var _resolved: bool = false

func _spawn_telegraph() -> void:
	_origin = _params.get("center", Vector2.ZERO)
	_dir = _params.get("facing", Vector2.RIGHT).normalized()
	_length = float(_params.get("length", 400.0))
	_width = float(_params.get("width", 40.0))
	_resolved = false

## 进入 RESOLVE（伤害在 _do_resolve——resolve_delay 后落地，QTE 窗口）
func _resolve() -> void:
	pass

func _do_resolve() -> void:
	if _resolved:
		return
	_resolved = true
	var player: Node = _params.get("player", null)
	if player == null or not is_instance_valid(player):
		return
	# 点到线段距离判定（禁物理）
	var v: Vector2 = player.global_position - _origin
	var t: float = clampf(v.dot(_dir), 0.0, _length)
	var closest: Vector2 = _origin + _dir * t
	if closest.distance_to(player.global_position) <= _width:
		var dmg: float = float(_params.get("damage", 0.0))
		if dmg > 0.0 and player.has_method("take_damage"):
			player.take_damage(dmg)
		var effects: Array = _params.get("effects", [])
		for e in effects:
			if e is Dictionary and player.has_method("apply_effect"):
				player.apply_effect(str(e.get("source", "boss")), str(e.get("id", "")),
					{"duration": e.get("duration", 1.0), "dps": e.get("dps", 0.0)})

func _recover() -> void:
	phase = Phase.RECOVER
