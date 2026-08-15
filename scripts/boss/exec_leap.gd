## PS-B2（PLAYER_SKILL_SPEC §5 · 2026-08-16）：leap 跃击执行器（位移三型 · 落点范围伤害/击退）
## 四拍子：telegraph（起跳蓄力）→ resolve（位移到落点 + 落点小范围伤害/击退）→ recover（落地后摇）
## 参数：caster / target_point（缺省 = 起点 + facing×distance）/ distance / land_radius /
##       damage / knockback / telegraph / recover
## 判定：落点半径内敌人距离判定（禁物理查询，F-19 范式）；enemies 参数 = 敌人容器
## ⚠️ 无 class_name：preload 范式
extends "res://scripts/boss/skill_executor.gd"

var _caster: Node = null
var _target: Vector2 = Vector2.ZERO
var _land_radius: float = 60.0
var _resolved: bool = false

func _spawn_telegraph() -> void:
	_caster = _params.get("caster", null)
	var dir: Vector2 = (_params.get("facing", Vector2.RIGHT) as Vector2).normalized()
	var dist: float = float(_params.get("distance", 160.0))
	var tp: Variant = _params.get("target_point", null)
	_target = tp if tp is Vector2 else (_caster.global_position if _caster else Vector2.ZERO) + dir * dist
	_land_radius = float(_params.get("land_radius", 60.0))
	_resolved = false

func _resolve() -> void:
	pass

func _do_resolve() -> void:
	if _resolved or _caster == null or not is_instance_valid(_caster):
		return
	_resolved = true
	_caster.global_position = _target
	# 落点范围伤害/击退（enemies 容器遍历，禁物理查询）
	var enemies: Node = _params.get("enemies", null)
	if enemies == null:
		return
	var dmg: float = float(_params.get("damage", 0.0))
	var knockback: float = float(_params.get("knockback", 0.0))
	for enemy in enemies.get_children():
		if not is_instance_valid(enemy) or not enemy.is_alive:
			continue
		var dist_sq: float = enemy.global_position.distance_squared_to(_target)
		if dist_sq <= _land_radius * _land_radius:
			if dmg > 0.0 and enemy.has_method("take_damage"):
				enemy.take_damage(dmg)
			if knockback > 0.0 and enemy.has_method("apply_knockback"):
				enemy.apply_knockback(enemy.global_position.direction_to(_target) * knockback)

func _recover() -> void:
	phase = Phase.RECOVER
