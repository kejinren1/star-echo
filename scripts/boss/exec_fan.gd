## BS-D2（BOSS_SKILL_SPEC §2.3 · 2026-08-13）：fan 扇形技能执行器（同 circle 骨架换参数）
## 四拍子：telegraph（扇形预警）→ resolve（arc 角内玩家命中，禁物理距离+角度判定）→ recover
## 参数：radius / arc（度，0=全圈）/ telegraph / resolve_delay / damage / effects
extends "res://scripts/boss/skill_executor.gd"

var _center: Vector2 = Vector2.ZERO
var _radius: float = 120.0
var _arc_deg: float = 90.0
var _facing: Vector2 = Vector2.RIGHT
var _resolved: bool = false

func _spawn_telegraph() -> void:
	_center = _params.get("center", Vector2.ZERO)
	_radius = float(_params.get("radius", 120.0))
	_arc_deg = float(_params.get("arc", 90.0))
	_facing = _params.get("facing", Vector2.RIGHT)
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
	var to_player: Vector2 = player.global_position - _center
	var dist: float = to_player.length()
	if dist > _radius:
		return
	# 扇形角度判定（arc=0 或 360 → 全向）
	if _arc_deg > 0.0 and _arc_deg < 360.0:
		var ang: float = rad_to_deg(_facing.angle_to(to_player.normalized()))
		if absf(ang) > _arc_deg * 0.5:
			return
	_damage_player(player)

func _damage_player(player: Node) -> void:
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
