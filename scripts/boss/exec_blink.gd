## PS-B2（PLAYER_SKILL_SPEC §5 · 2026-08-16）：blink 闪现执行器（位移三型 · 可穿怪 · CD 最长）
## 四拍子：telegraph（极短）→ resolve（瞬移到目标点，无视障碍/敌人）→ recover
## 参数：caster / target_point（缺省 = 起点 + facing×distance）/ distance / telegraph / recover
## ⚠️ 无 class_name：preload 范式
extends "res://scripts/boss/skill_executor.gd"

var _caster: Node = null
var _target: Vector2 = Vector2.ZERO
var _resolved: bool = false

func _spawn_telegraph() -> void:
	_caster = _params.get("caster", null)
	var dir: Vector2 = (_params.get("facing", Vector2.RIGHT) as Vector2).normalized()
	var dist: float = float(_params.get("distance", 200.0))
	var tp: Variant = _params.get("target_point", null)
	_target = tp if tp is Vector2 else (_caster.global_position if _caster else Vector2.ZERO) + dir * dist
	_resolved = false

func _resolve() -> void:
	pass

func _do_resolve() -> void:
	if _resolved or _caster == null or not is_instance_valid(_caster):
		return
	_resolved = true
	_caster.global_position = _target

func _recover() -> void:
	phase = Phase.RECOVER
