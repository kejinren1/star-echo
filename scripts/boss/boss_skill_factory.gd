## BS-B1（BOSS_SKILL_SPEC §3.1 · 2026-08-13）：技能执行器工厂
## make(type) → 执行器实例（Boss 只挑 pattern 行，执行器由本工厂按 type 创建）
## 未知 type → push_warning + 返回 null（调用方判空降级旧路径，防回归）
## ⚠️ 无 class_name：探针 --script 兼容（preload 范式）
## PS-B1（PLAYER_SKILL_SPEC §5/§6 · 2026-08-16）：扩展 dash/blink/leap/spawn/buff
## （新增只加不改，既有 4 类型零触碰；玩家版参数口径见 §9.3 params 合成处）
extends Node

const CircleExecutorScript: GDScript = preload("res://scripts/boss/exec_circle.gd")
## BS-D2（2026-08-13）：fan/beam/charge 扩展执行器（同骨架换参数）
const FanExecutorScript: GDScript = preload("res://scripts/boss/exec_fan.gd")
const BeamExecutorScript: GDScript = preload("res://scripts/boss/exec_beam.gd")
const ChargeExecutorScript: GDScript = preload("res://scripts/boss/exec_charge.gd")
## PS-B2（2026-08-16）：位移三型 + 召唤 + 增益（玩家侧技能系统 §5/§6 扩展）
const DashExecutorScript: GDScript = preload("res://scripts/boss/exec_dash.gd")
const BlinkExecutorScript: GDScript = preload("res://scripts/boss/exec_blink.gd")
const LeapExecutorScript: GDScript = preload("res://scripts/boss/exec_leap.gd")
const SpawnExecutorScript: GDScript = preload("res://scripts/boss/exec_spawn.gd")
const BuffExecutorScript: GDScript = preload("res://scripts/boss/exec_buff.gd")

static func make(type: String) -> Node:
	match type:
		"circle":
			return CircleExecutorScript.new()
		"fan":
			return FanExecutorScript.new()
		"beam":
			return BeamExecutorScript.new()
		"charge":
			return ChargeExecutorScript.new()
		"dash":
			return DashExecutorScript.new()
		"blink":
			return BlinkExecutorScript.new()
		"leap":
			return LeapExecutorScript.new()
		"spawn":
			return SpawnExecutorScript.new()
		"buff":
			return BuffExecutorScript.new()
		_:
			push_warning("[BossSkillFactory] 未知技能类型: %s" % type)
			return null
