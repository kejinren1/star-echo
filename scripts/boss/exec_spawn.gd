## PS-B1/B2（PLAYER_SKILL_SPEC §5 · 2026-08-16）：spawn 召唤执行器
## 四拍子：telegraph → resolve（在 caster 身周生成 minion 复数）→ recover
## 参数：caster / minion_scene（PackedScene）/ minion_count / spawn_radius / telegraph / recover
## 生成物挂 enemies 容器（params.enemies），摆位 caster 为心圆周均布
## 数据缺失（无 minion_scene/enemies）→ resolve 静默跳过（零 stderr 噪音）
## ⚠️ 无 class_name：preload 范式
extends "res://scripts/boss/skill_executor.gd"

var _caster: Node = null
var _resolved: bool = false

func _spawn_telegraph() -> void:
	_caster = _params.get("caster", null)
	_resolved = false

func _resolve() -> void:
	pass

func _do_resolve() -> void:
	if _resolved or _caster == null or not is_instance_valid(_caster):
		return
	_resolved = true
	var scene: Variant = _params.get("minion_scene", null)
	if not (scene is PackedScene):
		return
	var container: Node = _params.get("enemies", null)
	if container == null:
		return
	var count: int = maxi(int(_params.get("minion_count", 1)), 1)
	var radius: float = float(_params.get("spawn_radius", 40.0))
	for i in count:
		var minion: Node = (scene as PackedScene).instantiate()
		var angle: float = TAU * float(i) / float(count)
		minion.global_position = _caster.global_position + Vector2.from_angle(angle) * radius
		container.add_child(minion)

func _recover() -> void:
	phase = Phase.RECOVER
