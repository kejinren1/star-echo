## PS-B1/B2（PLAYER_SKILL_SPEC §5 · 2026-08-16）：buff 增益执行器
## 四拍子：telegraph → resolve（对 caster 施加 effects 列表：护盾/回血/攻速%等）→ recover
## 参数：caster / effects（Dictionary：shield/heal/attack_speed_percent + duration）
## 消费点：caster.add_shield / heal / apply_stat_modifier（玩家侧方法）；缺失方法静默跳过
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
	var effects: Dictionary = _params.get("effects", {})
	var duration: float = float(_params.get("duration", 5.0))
	var shield: float = float(effects.get("shield", 0.0))
	var heal: float = float(effects.get("heal", 0.0))
	var atk_pct: float = float(effects.get("attack_speed_percent", 0.0))
	if shield > 0.0 and _caster.has_method("add_shield"):
		_caster.add_shield(shield, duration)
	if heal > 0.0 and _caster.has_method("heal"):
		_caster.heal(heal)
	if atk_pct > 0.0 and _caster.has_method("apply_stat_modifier"):
		_caster.apply_stat_modifier("attack_speed", 1.0 + atk_pct / 100.0, true)

func _recover() -> void:
	phase = Phase.RECOVER
