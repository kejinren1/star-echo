## BS-B1（BOSS_SKILL_SPEC §3.1 · 2026-08-13）：技能执行器工厂
## make(type) → 执行器实例（Boss 只挑 pattern 行，执行器由本工厂按 type 创建）
## 未知 type → push_warning + 返回 null（调用方判空降级旧路径，防回归）
## ⚠️ 无 class_name：探针 --script 兼容（preload 范式）
extends Node

const CircleExecutorScript: GDScript = preload("res://scripts/boss/exec_circle.gd")

static func make(type: String) -> Node:
	match type:
		"circle":
			return CircleExecutorScript.new()
		_:
			push_warning("[BossSkillFactory] 未知技能类型: %s" % type)
			return null
