## BS-B2（BOSS_SKILL_SPEC §2.1/§3.1 · 2026-08-13）：circle 圈技能执行器（四拍子最小闭环）
##
## 流程：telegraph（预警收缩环，warn_style 数据驱动）→ resolve（resolve_delay 结算：
## 圈内伤害圈外无伤，effects 列表消费）→ recover（后摇）
## 参数全来自 params（radius/telegraph/resolve_delay/effects/cooldown/recover/warn_style）
##
## 判定：圈内/圈外距离判定（禁物理查询，F-19 范式）；VFX 占位（美术策略：色块/发光，豁免色号编码）
extends "res://scripts/boss/skill_executor.gd"

var _center: Vector2 = Vector2.ZERO
var _radius: float = 120.0
var _resolved: bool = false

func _spawn_telegraph() -> void:
	_center = _params.get("center", Vector2.ZERO)
	_radius = float(_params.get("radius", 120.0))
	_resolved = false
	# 预警环占位：CanvasLayer 挂 boss 场景容器（ColorRect 半透明圆环，简化 = 方形色块）
	# 美术策略：占位纯色图豁免色号编码（BS-B 阶段无真实 VFX）
	var container: Node = _params.get("fx_container", null)
	if container == null:
		return
	var ring := ColorRect.new()
	ring.name = "CircleTelegraph"
	ring.color = Color(1.0, 0.25, 0.15, 0.25)
	var size: float = _radius * 2.0
	ring.size = Vector2(size, size)
	ring.position = _center - Vector2(size * 0.5, size * 0.5)
	container.add_child(ring)
	set_meta("_telegraph_ring", ring)

func _resolve() -> void:
	phase = Phase.RESOLVE
	_do_resolve()

func _do_resolve() -> void:
	if _resolved:
		return
	_resolved = true
	var player: Node = _params.get("player", null)
	if player == null or not is_instance_valid(player):
		return
	# 圈内判定（距离，禁物理）：玩家在半径内 → 伤害 + effects 列表消费
	var dist: float = _center.distance_to(player.global_position)
	if dist <= _radius:
		var dmg: float = float(_params.get("damage", 0.0))
		if dmg > 0.0 and player.has_method("take_damage"):
			player.take_damage(dmg)
		# effects 列表消费（BOSS_SKILL_SPEC §4.3 effect 引用 → apply_effect 统一入口）
		var effects: Array = _params.get("effects", [])
		for e in effects:
			if e is Dictionary and player.has_method("apply_effect"):
				player.apply_effect(str(e.get("source", "boss")), str(e.get("id", "")),
					{"duration": e.get("duration", 1.0), "dps": e.get("dps", 0.0)})

func _recover() -> void:
	phase = Phase.RECOVER
	_remove_telegraph()

func _remove_telegraph() -> void:
	if not has_meta("_telegraph_ring"):
		return
	var ring: Node = get_meta("_telegraph_ring")
	if ring != null and is_instance_valid(ring) and ring.get_parent() != null:
		ring.queue_free()
	remove_meta("_telegraph_ring")

func _exit_internal() -> void:
	_remove_telegraph()
	phase = Phase.DONE

func exit(_p: Dictionary) -> void:
	_remove_telegraph()
