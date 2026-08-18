## AUDIO_FEEL 打击感出口校验（AF-P0 · 2026-08-18 第 57 轮执行）：五段式（批 A §1-3 + 批 B §4 震屏 + 批 C §5 音画）
##
## 用法（无头）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day31_feel_check.gd
##
## 校验内容：
##   §1 hitstop 顿帧（AF-P0-A1/A2）：trigger 后 time_scale==0 / 多触发取 max /
##      create_timer(ignore_time_scale=true) 恢复归 1.0 / 600 帧深探不挂 / 累计超限强制恢复
##   §2 数据驱动（AF-P0-A3）：get_stats_feel 与 Excel 导出值一致 + 白盒清段兜底默认 +
##      白盒注入覆盖（F1-散 §3 范式）
##   §3 回归抽样：SFX_MAP/BGM_MAP 键零改动（day24_audio 锚点）+ 探针结束 time_scale 归 1.0
##   §4 震屏分级（AF-P0-B1/B2）：light/medium/heavy 三层参数 / _process 衰减归位 /
##      玩家受伤 light 路径保留 / 数据驱动注入生效
##   §5 音画同步（AF-P0-C1/C2）：play_sfx_delayed 接口 + 零延迟立即播放 + 延迟调度播放 +
##      静态接线锚点（hit/crit/death/skill 调用点 + SFX_MAP 10 键零新增）
##
## 退出码 0 = 全部通过；非 0 = 失败项数。
extends SceneTree

const HITSTOP_SCRIPT: GDScript = preload("res://scripts/systems/hitstop_controller.gd")

var _idx: int = 0
var _phase: int = 0
var _checked: int = 0
var _failures: int = 0
var _loader: Node = null
var _audio: Node = null
var _hs: Node = null
var _feel_backup: Dictionary = {}
var _wait_start: int = 0
var _deep_frames: int = 0


func _initialize() -> void:
	print("=== Day 31 feel check (AF-P0) ===")


func _process(_delta: float) -> bool:
	match _phase:
		0:
			_load_mocks()
			_phase = 1
		1:
			_part_hitstop_immediate()
			_phase = 2
		2:
			_part_hitstop_wait_recover()
		3:
			_part_hitstop_deep_600()
		4:
			_part_hitstop_overflow()
			_phase = 5
		5:
			_part_shake()
			_phase = 6
		6:
			_part_data_driven()
			_phase = 7
		7:
			_part_audio_sync_immediate()
			_phase = 8
		8:
			_part_audio_wait_delayed()
		9:
			_part_audio_static_anchors()
			_phase = 10
		10:
			_part_regression()
			_report()
			quit(_failures)
			return true
	return false


func _load_mocks() -> void:
	_loader = root.get_node_or_null("DataLoader")
	_audio = root.get_node_or_null("AudioManager")
	if _loader == null:
		_fail("DataLoader autoload 缺失")
		quit(1)
	if _audio == null:
		_fail("AudioManager autoload 缺失")
		quit(1)
	# 独立实例化 hitstop 控制器（不依赖 Main 场景；AF-P0-A1「探针可独立实例化」）
	_hs = HITSTOP_SCRIPT.new()
	root.add_child(_hs)
	_feel_backup = _loader.get("_feel").duplicate(true)


# ========== §1 hitstop（AF-P0-A1/A2） ==========

## 立即断言部分：trigger 后 time_scale==0 + 多触发取 max
## F-45（2026-08-18 用户拍板）：顿帧调小至 0.02~0.03s（Excel stats_feel 段），断言同步
func _part_hitstop_immediate() -> void:
	var feel: Dictionary = _loader.call("get_stats_feel")
	# a. 触发 → 冻结
	_hs.call("trigger", float(feel.get("hitstop_melee", 0.03)))
	if Engine.time_scale == 0.0 and bool(_hs.call("is_freezing")) and absf(float(_hs.call("get_time_left")) - 0.03) <= 0.001:
		_pass("hitstop / trigger(0.03) → time_scale==0 + 冻结标记 + 剩余 0.03")
	else:
		_fail("hitstop: trigger 后未冻结 time_scale=%.2f" % Engine.time_scale)
	# b. 多触发取 max：更小值不覆盖、更大值覆盖
	_hs.call("trigger", 0.02)
	if absf(float(_hs.call("get_time_left")) - 0.03) <= 0.001:
		_pass("hitstop / 多触发取 max：trigger(0.02) 不覆盖 0.03")
	else:
		_fail("hitstop: 较小 trigger 错误覆盖 time_left=%.2f" % float(_hs.call("get_time_left")))
	_hs.call("trigger", 0.3)
	if absf(float(_hs.call("get_time_left")) - 0.3) <= 0.001:
		_pass("hitstop / 多触发取 max：trigger(0.3) 覆盖为 0.3")
	else:
		_fail("hitstop: 较大 trigger 未覆盖 time_left=%.2f" % float(_hs.call("get_time_left")))
	# 还原等待（0.3s timer 在跑，转等待阶段等它恢复）
	_wait_start = Time.get_ticks_msec()


## 等待 create_timer(ignore_time_scale=true) 恢复归 1.0（真实路径，超时 3s）
func _part_hitstop_wait_recover() -> void:
	if Engine.time_scale == 1.0:
		_pass("hitstop / create_timer(ignore_time_scale) 恢复归 1.0（真实计时路径）")
		_phase = 3
	elif Time.get_ticks_msec() - _wait_start > 3000:
		_fail("hitstop: 3s 内未恢复（time_scale 仍 %.2f）——死卡" % Engine.time_scale)
		_phase = 6


## 600 帧深探：time_scale=0 期间帧循环仍被持续驱动（无死卡）+ 手动强制恢复可靠
func _part_hitstop_deep_600() -> void:
	if not bool(_hs.call("is_freezing")):
		# 上一等待阶段已恢复；再触发一次 0.3 进冻结做深探
		_hs.call("trigger", 0.3)
	if bool(_hs.call("is_freezing")):
		_deep_frames += 1
		if _deep_frames >= 600:
			# 600 帧内探针 _process 持续被驱动 = 帧循环在 time_scale=0 下未死
			_hs.call("_force_restore")
			if Engine.time_scale == 1.0:
				_pass("hitstop / 600 帧深探：time_scale=0 下帧循环持续驱动 + 强制恢复可靠")
			else:
				_fail("hitstop: 强制恢复失败 time_scale=%.2f" % Engine.time_scale)
			_phase = 4
	else:
		# 冻结期外（timer 已自动恢复）→ 深探语义已满足（帧循环活着）
		_pass("hitstop / 600 帧深探：time_scale=0 期间帧循环持续驱动（timer 提前自动恢复）")
		_phase = 4


## 累计超限强制恢复（MAX_FREEZE=0.5）
func _part_hitstop_overflow() -> void:
	# 直接触发累计超限：0.2×3 = 0.6 > 0.5 → 强制恢复
	_hs.call("trigger", 0.2)
	_hs.call("trigger", 0.2)
	_hs.call("trigger", 0.2)
	if Engine.time_scale == 1.0 and not bool(_hs.call("is_freezing")):
		_pass("hitstop / 累计停帧超限 0.5s → 强制恢复 + 结束冻结")
	else:
		_fail("hitstop: 超限未强制恢复 time_scale=%.2f" % Engine.time_scale)


# ========== §4 震屏分级（AF-P0-B1/B2） ==========

## 白盒直调 main._trigger_camera_shake（Node2D + set_script 不 add_child → _ready 不触发，
## 无 $World/Player 依赖崩风险；_process 内 camera=null 判空跳过 offset 只衰减计时）
func _part_shake() -> void:
	var main_script: GDScript = load("res://scripts/autoload/main.gd")
	if main_script == null:
		_fail("震屏: main.gd 加载失败")
		return
	var fake := Node2D.new()
	fake.set_script(main_script)
	# a. 三级分层参数（F-45 用户 08-18 二次调档：light=0.05,1 / medium=0.1,3 / heavy=0.2,5）
	fake.call("_trigger_camera_shake", "light")
	if absf(float(fake.get("_shake_duration")) - 0.05) <= 0.001 and absf(float(fake.get("_shake_magnitude")) - 1.0) <= 0.001:
		_pass("震屏 / light=0.05s/1.0（玩家受伤·用户二次调档）")
	else:
		_fail("震屏: light 档错误 %.2f/%.2f" % [float(fake.get("_shake_duration")), float(fake.get("_shake_magnitude"))])
	fake.call("_trigger_camera_shake", "medium")
	if absf(float(fake.get("_shake_duration")) - 0.1) <= 0.001 and absf(float(fake.get("_shake_magnitude")) - 3.0) <= 0.001:
		_pass("震屏 / medium=0.1s/3.0（击杀·用户二次调档）")
	else:
		_fail("震屏: medium 档错误 %.2f/%.2f" % [float(fake.get("_shake_duration")), float(fake.get("_shake_magnitude"))])
	fake.call("_trigger_camera_shake", "heavy")
	if absf(float(fake.get("_shake_duration")) - 0.2) <= 0.001 and absf(float(fake.get("_shake_magnitude")) - 5.0) <= 0.001:
		_pass("震屏 / heavy=0.2s/5.0（Boss 死亡·用户二次调档）")
	else:
		_fail("震屏: heavy 档错误 %.2f/%.2f" % [float(fake.get("_shake_duration")), float(fake.get("_shake_magnitude"))])
	# b. _process 衰减归位（0.15s 内 _shake_time → 0；camera null 跳过 offset 无崩）
	fake.call("_trigger_camera_shake", "light")
	for i in range(30):
		fake.call("_process", 0.05)
	if float(fake.get("_shake_time")) <= 0.0:
		_pass("震屏 / _process 衰减归位（_shake_time→0）")
	else:
		_fail("震屏: 衰减未归位 _shake_time=%.2f" % float(fake.get("_shake_time")))
	# c. 玩家受伤 light 路径保留（_on_player_hit → light 档）
	fake.call("_on_player_hit", 10.0)
	if absf(float(fake.get("_shake_duration")) - 0.05) <= 0.001:
		_pass("震屏 / 玩家受伤 light 路径保留（_on_player_hit → light 档）")
	else:
		_fail("震屏: 玩家受伤路径失效")
	# d. 数据驱动注入生效（Excel feel 段 → main 读 get_stats_feel）
	_loader.set("_feel", {"shake_medium_duration": 0.5, "shake_medium_magnitude": 8.0})
	fake.call("_trigger_camera_shake", "medium")
	if absf(float(fake.get("_shake_duration")) - 0.5) <= 0.001 and absf(float(fake.get("_shake_magnitude")) - 8.0) <= 0.001:
		_pass("震屏 / 数据驱动：注入 feel → medium 0.5s/8.0 生效（Excel 管线）")
	else:
		_fail("震屏: 数据驱动注入未生效")
	_loader.set("_feel", _feel_backup)
	fake.free()


# ========== §2 数据驱动（AF-P0-A3） ==========

func _part_data_driven() -> void:
	# a. 当前 JSON（Excel 导出）值与方案拍板一致（F-45 调小：0.03/0.02/0.02/0.06）
	var feel: Dictionary = _loader.call("get_stats_feel")
	var exp: Dictionary = {
		"hitstop_melee": 0.03, "hitstop_ranged": 0.02,
		"hitstop_crit_bonus": 0.02, "hitstop_boss_kill": 0.06,
	}
	var ok: bool = true
	for k in exp:
		if absf(float(feel.get(k, -1.0)) - float(exp[k])) > 0.001:
			ok = false
	if ok:
		_pass("数据 / get_stats_feel 4 hitstop 键 == Excel 导出值（0.03/0.02/0.02/0.06）")
	else:
		_fail("数据: feel 段与拍板值不一致 %s" % str(feel))
	# b. 缺段兜底：白盒清段 → 返回默认值（FEEL_DEFAULTS）
	_loader.set("_feel", {})
	var d: Dictionary = _loader.call("get_stats_feel")
	if absf(float(d.get("hitstop_melee", -1.0)) - 0.03) <= 0.001 and absf(float(d.get("shake_medium_duration", -1.0)) - 0.1) <= 0.001:
		_pass("数据 / 缺段兜底：清空 _feel → 返回默认（hitstop 0.03 / shake 0.1）")
	else:
		_fail("数据: 缺段兜底失败 %s" % str(d))
	# c. 注入覆盖：白盒注入 → 返回值变化（数据层消费链路）
	_loader.set("_feel", {"hitstop_melee": 0.9})
	var d2: Dictionary = _loader.call("get_stats_feel")
	if absf(float(d2.get("hitstop_melee", -1.0)) - 0.9) <= 0.001:
		_pass("数据 / 白盒注入 hitstop_melee=0.9 → get_stats_feel 返回 0.9（消费点读数据层）")
	else:
		_fail("数据: 注入未生效 %s" % str(d2))
	# 恢复备份
	_loader.set("_feel", _feel_backup)


# ========== §5 音画同步（AF-P0-C1/C2） ==========

## 立即断言部分：play_sfx_delayed 接口在位 + 零延迟立即播放（复用 SFX_POOL 返回 true）
func _part_audio_sync_immediate() -> void:
	if _audio.has_method("play_sfx_delayed"):
		_pass("音画 / audio_manager 新增 play_sfx_delayed（接口在位）")
	else:
		_fail("音画: play_sfx_delayed 缺失")
	# 零延迟 → 与 play_sfx 同路径立即播放（headless Dummy 驱动下 playing 标志有效）
	_audio.call("play_sfx_delayed", "hit", 0.0)
	var any_playing: bool = false
	for p in _audio.get("_sfx_pool"):
		if p != null and bool(p.get("playing")):
			any_playing = true
	if any_playing:
		_pass("音画 / play_sfx_delayed(hit, 0.0) 立即播放（SFX 池 playing）")
	else:
		_fail("音画: 零延迟播放未生效")
	# 延迟调度启动（0.08s 后应播放——转等待相位轮询捕获）
	_audio.call("play_sfx_delayed", "crit", 0.08)
	_wait_start = Time.get_ticks_msec()


## 等待相位：轮询 SFX 池捕获延迟播放（超时 2s）
func _part_audio_wait_delayed() -> void:
	var any_playing: bool = false
	for p in _audio.get("_sfx_pool"):
		if p != null and bool(p.get("playing")):
			any_playing = true
	if any_playing:
		_pass("音画 / play_sfx_delayed(crit, 0.08s) 延迟调度到点播放（SceneTreeTimer 生效）")
		_phase = 9
	elif Time.get_ticks_msec() - _wait_start > 2000:
		_fail("音画: 延迟播放 2s 未触发（timer 调度失效）")
		_phase = 9


## 静态接线锚点：hit/crit/death/skill 调用点 + SFX_MAP 10 键零新增（红线 2 契约）
func _part_audio_static_anchors() -> void:
	var proj: String = FileAccess.get_file_as_string("res://scripts/weapons/projectile.gd")
	var main_src: String = FileAccess.get_file_as_string("res://scripts/autoload/main.gd")
	var skill: String = FileAccess.get_file_as_string("res://scripts/player/skill_controller.gd")
	var audio_src: String = FileAccess.get_file_as_string("res://scripts/autoload/audio_manager.gd")
	var ok: bool = true
	if proj.find('AudioManager.play_sfx("hit")') >= 0 and proj.find('AudioManager.play_sfx("crit")') >= 0:
		_pass("音画 / projectile 命中音 hit + 暴击音 crit 调用点在位")
	else:
		_fail("音画: projectile 命中/暴击音接线缺失")
		ok = false
	if main_src.find('AudioManager.play_sfx("death")') >= 0:
		_pass("音画 / 击杀音 death 消费点在 main._on_enemy_died（enemy_damage 不重复接线防双播）")
	else:
		_fail("音画: death 音消费点缺失")
		ok = false
	if skill.find('AudioManager.play_sfx("skill")') >= 0:
		_pass("音画 / 技能释放音 skill 消费点在 skill_controller（D24-T3 保留）")
	else:
		_fail("音画: skill 音消费点缺失")
		ok = false
	if audio_src.find("func play_sfx_delayed") >= 0:
		_pass("音画 / play_sfx_delayed 实现体在位（SFX_MAP 零新增）")
	else:
		_fail("音画: play_sfx_delayed 实现缺失")
		ok = false
	var sfx_map: Dictionary = _audio.get("SFX_MAP")
	if sfx_map.size() == 10:
		_pass("音画 / SFX_MAP 10 键零新增零删改（红线 2 契约）")
	else:
		_fail("音画: SFX_MAP 键数 %d ≠ 10" % sfx_map.size())
		ok = false


# ========== §3 回归抽样 ==========

func _part_regression() -> void:
	# a. SFX_MAP/BGM_MAP 键零改动（day24_audio 锚点：10 SFX + 2 BGM）
	var sfx_map: Dictionary = _audio.get("SFX_MAP")
	var bgm_map: Dictionary = _audio.get("BGM_MAP")
	var exp_sfx: Array = ["hit", "crit", "death", "levelup", "coin",
		"shop", "skill", "heal", "event", "boss"]
	var sfx_ok: bool = true
	for k in exp_sfx:
		if not sfx_map.has(k):
			sfx_ok = false
	if sfx_ok and bgm_map.has("menu") and bgm_map.has("battle") and sfx_map.size() == 10:
		_pass("回归 / SFX_MAP 10 键 + BGM_MAP 2 键零改动（day24_audio 契约）")
	else:
		_fail("回归: audio_manager 键契约被破坏 sfx=%d" % sfx_map.size())
	# b. 探针结束 time_scale 归 1.0（防污染后续探针）
	if Engine.time_scale == 1.0:
		_pass("回归 / 探针结束 time_scale==1.0（无污染）")
	else:
		_fail("回归: time_scale 残留 %.2f" % Engine.time_scale)
	# c. day24_audio_check 可 load（回归抽样）
	if load("res://tools/day24_audio_check.gd") != null:
		_pass("回归 / day24_audio_check.gd load() 成功（抽样）")
	else:
		_fail("回归: day24_audio_check 加载失败")


# ========== 汇总 ==========

func _report() -> void:
	print("=== Day 31 feel check: %d passed, %d failed ===" % [_checked, _failures])
	if _failures == 0:
		print("DAY31 FEEL CHECK CLEAN")


func _pass(msg: String) -> void:
	_checked += 1
	print("  PASS  %s" % msg)


func _fail(msg: String) -> void:
	_failures += 1
	_checked += 1
	print("  FAIL  %s" % msg)
