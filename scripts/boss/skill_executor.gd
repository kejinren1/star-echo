## BS-B1（BOSS_SKILL_SPEC §3.1 · 2026-08-13）：技能执行器接口框架
##
## 四拍子态机（idle→telegraph→resolve→recover）的执行体抽象：
##   enter(p)   — 进入技能（读 params，发起 telegraph 预警）
##   tick(d, p) — 逐帧推进（telegraph 倒计时 → resolve 结算 → recover 后摇）
##   exit(p)    — 退出清理（自动走，子类可覆写）
##
## 设计要点：
##   · Boss 不认识技能——只挑 pattern 行（BS-C），执行器由 boss_skill_factory 按 type 创建
##   · 参数全来自 params（radius/telegraph/resolve_delay/effects/cooldown），禁硬编码
##   · 圈内/圈外判定禁物理查询（沿用 F-19 距离判定范式）
##   · ⚠️ 无 class_name：探针 --script 不注册全局类名（StatusComponent 先例），preload 范式
extends Node

enum Phase { TELEGRAPH, RESOLVE, RECOVER, DONE }

var phase: Phase = Phase.DONE
var _elapsed: float = 0.0
var _params: Dictionary = {}

## 公平底线公式（§2.2 · BS-B3）：预警时长不得低于「玩家逃出圈所需时间 + 0.4s」
## t_w ≥ 2r/v + 0.4 —— 难度缩放缩短 t_w 时钳制不得低于底线（防技能不可躲）
static func fair_telegraph(radius: float, player_speed: float) -> float:
	return 2.0 * radius / maxf(player_speed, 1.0) + 0.4

func is_done() -> bool:
	return phase == Phase.DONE

## 进入：解析 params + 发起 telegraph 预警（子类实现 _spawn_telegraph）
func enter(p: Dictionary) -> void:
	_params = p.get("params", {})
	_elapsed = 0.0
	phase = Phase.TELEGRAPH
	_spawn_telegraph()

## 逐帧推进（子类在 _resolve/_recover 处实现结算与后摇）
func tick(delta: float, _p: Dictionary) -> void:
	if phase == Phase.DONE:
		return
	_elapsed += delta
	match phase:
		Phase.TELEGRAPH:
			if _elapsed >= float(_params.get("telegraph", 0.8)):
				_resolve()
		Phase.RESOLVE:
			if _elapsed >= float(_params.get("resolve_delay", 0.5)) + float(_params.get("telegraph", 0.8)):
				_recover()
		Phase.RECOVER:
			if _elapsed >= float(_params.get("telegraph", 0.8)) + float(_params.get("resolve_delay", 0.5)) \
					+ float(_params.get("recover", 0.3)):
				_exit_internal()

## 子类钩子
func _spawn_telegraph() -> void:
	pass
func _resolve() -> void:
	phase = Phase.RESOLVE
func _recover() -> void:
	phase = Phase.RECOVER
func _exit_internal() -> void:
	exit({})
	phase = Phase.DONE

## 退出清理（Boss pattern 切技能时调用；子类可覆写移除占位节点）
func exit(_p: Dictionary) -> void:
	pass
