## 顿帧（hitstop）控制器（AUDIO_FEEL AF-P0 批 A · F1 · 2026-08-18 第 57 轮执行）
## 职责：命中/暴击/Boss 击杀瞬间 `Engine.time_scale = 0.0` 微停帧，恢复由
##      `create_timer(ignore_time_scale=true)` 回调强制归 1.0（防 time_scale=0 下
##      所有基于 delta 的恢复递减停摆死卡——SPEC 红线 3）。
## 设计：
##   · trigger(duration) 多触发取 max 防无限叠加；时长参数读 DataLoader.get_stats_feel()
##     （Excel stats_feel 段 → stats.json feel 键；缺段兜底 = 默认值防漂移）
##   · 累计停帧 > MAX_FREEZE(0.5s) 强制归 1.0 + push_warning（超时兜底护栏）
##   · 退出/析构前强制归 1.0（防 time_scale 污染后续探针）
## 挂载：main.gd `$HitstopController` 子节点（代码创建；F2 边界原则系统级）；
##      探针可独立 new() + add_child 不依赖场景（本脚本 extends Node 无场景依赖）。
extends Node

## 累计停帧上限（秒）：超过即强制恢复（防高频率连击把时间轴冻结成死局）
const MAX_FREEZE: float = 0.5

## 剩余停帧时间（秒；>0 = 当前处于顿帧中）
var _time_left: float = 0.0
## 累计停帧总量（跨多次 trigger 累积；超 MAX_FREEZE → 强制恢复）
var _total_frozen: float = 0.0
## 是否处于顿帧冻结态（旧 timer 到点回调的防重标记）
var _freezing: bool = false


## 触发一次停帧（时长取 max 合并：已有更长停帧在计时 → 忽略本次）
## duration 读 DataLoader.get_stats_feel()（O-2 拍板：近战重 0.15 / 远程轻 0.05 / 暴击 +0.1 / Boss 击杀 0.15）
func trigger(duration: float) -> void:
	if duration <= 0.0:
		return
	_total_frozen += duration
	if _total_frozen > MAX_FREEZE:
		push_warning("[Hitstop] 停帧累计 %.2fs 超限 %.2fs，强制恢复" % [_total_frozen, MAX_FREEZE])
		_force_restore()
		return
	if _time_left >= duration:
		return  # 已有更长/相等的停帧在计时（多触发取 max）
	_time_left = duration
	# 重新安排恢复：time_scale=0 时普通 timer 停摆 → 必须 ignore_time_scale=true（第 4 参）
	_freezing = true
	Engine.time_scale = 0.0
	get_tree().create_timer(_time_left, true, false, true).timeout.connect(_on_freeze_end)


## 停帧到期回调（ignore_time_scale 计时器到点 → 强制恢复 1.0）
func _on_freeze_end() -> void:
	if not _freezing:
		return  # 已被更新 trigger / 强制恢复接管（旧 timer 到点忽略）
	_freezing = false
	_time_left = 0.0
	_total_frozen = 0.0
	Engine.time_scale = 1.0


## 超时兜底强制恢复（累计超限或外部调用）
func _force_restore() -> void:
	_freezing = false
	_time_left = 0.0
	_total_frozen = 0.0
	Engine.time_scale = 1.0


## 暴露当前状态（探针白盒断言用）
func get_time_left() -> float:
	return _time_left


func is_freezing() -> bool:
	return _freezing


func _exit_tree() -> void:
	# 退出/场景卸载前归 1.0（防 time_scale 污染后续探针/场景）
	Engine.time_scale = 1.0
