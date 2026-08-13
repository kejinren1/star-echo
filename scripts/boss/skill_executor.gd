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

## BS-D1（§5 · 2026-08-13）：难度系数合成 = 基础难度 × 动态难度，clamp 0.5~2.0
## 基础难度（关卡/波次已有）× 动态难度（build 强度——装备越好系数越高，防胡了碾压无趣）
static func compose_difficulty(base_difficulty: float, build_strength: float) -> float:
	return clampf(base_difficulty * build_strength, 0.5, 2.0)

## BS-D1：难度系数 → 技能参数倍率（预警↓ 伤害↑ 半径↑；公平底线钳制由调用方 fair_telegraph 兜底）
## coeff = 1.0 → 参数不变；>1 更难（伤害↑ 预警↓ 半径↑）；<1 更易
static func scale_params_by_difficulty(params: Dictionary, coeff: float, player_speed: float) -> void:
	if absf(coeff - 1.0) < 0.001:
		return
	if params.has("damage"):
		params["damage"] = float(params["damage"]) * coeff
	if params.has("radius"):
		params["radius"] = float(params["radius"]) * (1.0 + (coeff - 1.0) * 0.5)
	if params.has("telegraph"):
		var r: float = float(params.get("radius", 120.0))
		var floor: float = fair_telegraph(r, player_speed)
		params["telegraph"] = maxf(float(params["telegraph"]) / coeff, floor)

## BS-D2（§2.4 · 2026-08-13）：打断 QTE = 行为条件（星骸不做按键时机型 QTE）——
## 打断窗口内玩家攻击命中 → interrupt() 中断技能（失败不致命：中断即豁免，无惩罚）
## 基类空实现；exec_* 视窗口覆写（默认中断 = 立即结束）
func interrupt() -> void:
	pass

func is_done() -> bool:
	return phase == Phase.DONE

## 进入：解析 params + 发起 telegraph 预警（子类实现 _spawn_telegraph）
func enter(p: Dictionary) -> void:
	_params = p.get("params", {})
	_elapsed = 0.0
	phase = Phase.TELEGRAPH
	_spawn_telegraph()

## 逐帧推进（子类在 _do_resolve/_recover 处实现结算与后摇；伤害在 resolve_delay 后落地，
## RESOLVE 相位 = QTE 打断窗口——窗口内 interrupt() 可豁免）
func tick(delta: float, _p: Dictionary) -> void:
	if phase == Phase.DONE:
		return
	_elapsed += delta
	match phase:
		Phase.TELEGRAPH:
			if _elapsed >= float(_params.get("telegraph", 0.8)):
				phase = Phase.RESOLVE
				_resolve()
		Phase.RESOLVE:
			if _elapsed >= float(_params.get("telegraph", 0.8)) + float(_params.get("resolve_delay", 0.5)):
				_do_resolve()
				_recover()
		Phase.RECOVER:
			if _elapsed >= float(_params.get("telegraph", 0.8)) + float(_params.get("resolve_delay", 0.5)) \
					+ float(_params.get("recover", 0.3)):
				_exit_internal()

## 子类钩子
func _spawn_telegraph() -> void:
	pass
## 进入 RESOLVE 相位钩子（清理预警等；伤害在 _do_resolve）
func _resolve() -> void:
	pass
## 结算：伤害/效果落地（resolve_delay 后）
func _do_resolve() -> void:
	pass
func _recover() -> void:
	phase = Phase.RECOVER
func _exit_internal() -> void:
	exit({})
	phase = Phase.DONE

## 退出清理（Boss pattern 切技能时调用；子类可覆写移除占位节点）
func exit(_p: Dictionary) -> void:
	pass
