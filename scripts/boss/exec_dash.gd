## PS-B2（PLAYER_SKILL_SPEC §5 · 2026-08-16）：dash 冲刺执行器（位移三型 · 最通用）
## 四拍子：telegraph（极短蓄力）→ resolve（沿 facing 位移 distance）→ recover（后摇）
## 参数（数据驱动，禁硬编码）：caster / facing / distance / telegraph / recover / aftercast
## 位移口径：起点 → 起点 + facing×distance（瞬时到位；穿怪不结算接触伤害由 invulnerable 窗口覆盖）
## 玩家版参数口径（§9.3）在 params 合成处统一封装，本文件不散落
## ⚠️ 无 class_name：preload 范式（BOSS_SKILL_SPEC 中立层惯例）
extends "res://scripts/boss/skill_executor.gd"

var _caster: Node = null
var _start: Vector2 = Vector2.ZERO
var _dir: Vector2 = Vector2.RIGHT
var _distance: float = 120.0
var _resolved: bool = false

func _spawn_telegraph() -> void:
	_caster = _params.get("caster", null)
	_dir = (_params.get("facing", Vector2.RIGHT) as Vector2).normalized()
	_distance = float(_params.get("distance", 120.0))
	_start = _caster.global_position if _caster else Vector2.ZERO
	_resolved = false

func _resolve() -> void:
	pass  # 无预警节点可清

func _do_resolve() -> void:
	if _resolved or _caster == null or not is_instance_valid(_caster):
		return
	_resolved = true
	_caster.global_position = _start + _dir * _distance

func _recover() -> void:
	phase = Phase.RECOVER
