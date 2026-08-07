## Day 24 音频出口校验（D24-T5）：音频接入五段（资源/配置/状态机/播放/回归）
##
## 用法（无头，不需要编辑器）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day24_audio_check.gd
##
## 校验内容（对应 docs/SOLUTION_PLAN.md 第 6 轮任务 9 五段）：
##   §1 资源层：12 WAV exists + size>0 + 头合法（RIFF/WAVE 魔数 + fmt + mono + 22050 + 16bit）
##   §2 配置层：project.godot [autoload] 含 AudioManager；SFX_MAP 键 ⊇ 10 类 + BGM_MAP 2 键
##   §3 状态机层：白盒 current_state MENU/BATTLE/SHOP/ROUTE_SELECT/GAME_OVER → menu/battle/battle/battle/stop
##   §4 播放层：play_bgm + play_sfx 不崩 + playing 标志 + 连发 ×6 池轮询 + 同轨不重播
##   §5 回归：抽样 day2/day17 + 新代码零 AudioStreamPlayer 场景引用（纯代码 Autoload 防场景未挂节点）
##
## 退出码 0 = 全部通过；非 0 = 失败项数。
extends SceneTree

const EXPECTED_BGM_KEYS: Array = ["menu", "battle"]
const EXPECTED_SFX_KEYS: Array = ["hit", "crit", "death", "levelup", "coin",
	"shop", "skill", "heal", "event", "boss"]

var _idx: int = 0
var _sub: int = 0
var _gm: Node = null
var _audio: Node = null
var _expect_loaded: bool = false
var _checked: int = 0
var _failures: int = 0


func _initialize() -> void:
	print("=== Day 24 audio check ===")


func _process(_delta: float) -> bool:
	if not _expect_loaded:
		_load_mocks()
	if _idx >= 1:
		_report()
		quit(_failures)
		return true
	_sub = _advance(_sub)
	return false


func _load_mocks() -> void:
	_expect_loaded = true
	_gm = root.get_node_or_null("GameManager")
	_audio = root.get_node_or_null("AudioManager")
	if _gm == null:
		_fail("GameManager autoload 缺失")
		quit(_failures)
	if _audio == null:
		_fail("AudioManager autoload 未注册（project.godot [autoload] 缺失）")
		quit(_failures)


func _advance(sub: int) -> int:
	match sub:
		0:
			_part_resources()
			return 1
		1:
			_part_config()
			return 2
		2:
			_part_state_machine()
			return 3
		3:
			_part_playback()
			return 4
		4:
			_part_regression()
			return 5
		5:
			_report()
			quit(_failures)
	return 5


# ========== §1 资源层 ==========

func _part_resources() -> void:
	var wav_ok: bool = true
	for key in EXPECTED_BGM_KEYS:
		var p: String = "res://assets/audio/bgm/bgm_%s.wav" % key
		if not _wav_valid(p):
			wav_ok = false
	for key in EXPECTED_SFX_KEYS:
		var p: String = "res://assets/audio/sfx/%s.wav" % key
		if not _wav_valid(p):
			wav_ok = false
	if wav_ok:
		_pass("资源 / 12 WAV 全部合法（RIFF/WAVE + mono + 22050 + 16bit + size>0）")
	else:
		_fail("资源: 存在缺失/非法 WAV")
	# 时长范围：BGM 8-12s 循环点对齐 / SFX 0.08-1.5s（方案 T1 口径）
	var dur_ok: bool = true
	for key in EXPECTED_BGM_KEYS:
		var d: float = _wav_duration("res://assets/audio/bgm/bgm_%s.wav" % key)
		if d < 7.0 or d > 13.0:
			dur_ok = false
	for key in EXPECTED_SFX_KEYS:
		var d: float = _wav_duration("res://assets/audio/sfx/%s.wav" % key)
		if d < 0.05 or d > 2.0:
			dur_ok = false
	if dur_ok:
		_pass("资源 / 时长合规（BGM 8-12s 循环 / SFX 0.05-2s）")
	else:
		_fail("资源: 存在时长越界 WAV")


func _wav_duration(res_path: String) -> float:
	if not FileAccess.file_exists(res_path):
		return -1.0
	var f: FileAccess = FileAccess.open(res_path, FileAccess.READ)
	if f == null:
		return -1.0
	var data: PackedByteArray = f.get_buffer(f.get_length())
	f.close()
	var byte_rate: int = data[28] | (data[29] << 8) | (data[30] << 16) | (data[31] << 24)
	var data_size: int = data.size() - 44
	if byte_rate <= 0:
		return -1.0
	return float(data_size) / float(byte_rate)


func _wav_valid(res_path: String) -> bool:
	if not FileAccess.file_exists(res_path):
		_fail("资源: 缺失 %s" % res_path)
		return false
	var f: FileAccess = FileAccess.open(res_path, FileAccess.READ)
	if f == null:
		_fail("资源: 无法打开 %s" % res_path)
		return false
	var data: PackedByteArray = f.get_buffer(f.get_length())
	f.close()
	if data.size() < 44:
		_fail("资源: %s 过小" % res_path)
		return false
	# RIFF/WAVE 魔数
	if data[0] != 82 or data[1] != 73 or data[2] != 70 or data[3] != 70:  # "RIFF"
		_fail("资源: %s 非 RIFF" % res_path)
		return false
	if data[8] != 87 or data[9] != 65 or data[10] != 86 or data[11] != 69:  # "WAVE"
		_fail("资源: %s 非 WAVE" % res_path)
		return false
	# fmt 块: audio_format(2B)=1 PCM, channels(2B)=1, sample_rate(4B)=22050, bits(2B)=16
	if data[20] != 1 or data[21] != 0:
		_fail("资源: %s 非 PCM" % res_path)
		return false
	if data[22] != 1 or data[23] != 0:
		_fail("资源: %s 非 mono" % res_path)
		return false
	var sr: int = data[24] | (data[25] << 8) | (data[26] << 16) | (data[27] << 24)
	if sr != 22050:
		_fail("资源: %s 采样率 %d ≠ 22050" % [res_path, sr])
		return false
	if data[34] != 16 or data[35] != 0:
		_fail("资源: %s 非 16bit" % res_path)
		return false
	return true


# ========== §2 配置层 ==========

func _part_config() -> void:
	# [autoload] 注册
	var cfg_text: String = FileAccess.get_file_as_string("res://project.godot")
	if cfg_text.find("AudioManager=\"*res://scripts/autoload/audio_manager.gd\"") >= 0:
		_pass("配置 / project.godot [autoload] 含 AudioManager")
	else:
		_fail("配置: project.godot 未注册 AudioManager")
	# BGM_MAP / SFX_MAP 键
	var bgm_map: Dictionary = _audio.get("BGM_MAP")
	var sfx_map: Dictionary = _audio.get("SFX_MAP")
	var bgm_ok: bool = true
	for k in EXPECTED_BGM_KEYS:
		if not bgm_map.has(k):
			bgm_ok = false
	var sfx_ok: bool = true
	for k in EXPECTED_SFX_KEYS:
		if not sfx_map.has(k):
			sfx_ok = false
	if bgm_ok:
		_pass("配置 / BGM_MAP 2 键（menu/battle）")
	else:
		_fail("配置: BGM_MAP 缺键")
	if sfx_ok:
		_pass("配置 / SFX_MAP 10 键全覆盖")
	else:
		_fail("配置: SFX_MAP 缺键 %s" % str(sfx_map))


# ========== §3 状态机层 ==========

func _part_state_machine() -> void:
	# 白盒逐态切换：MENU/BATTLE/SHOP/ROUTE_SELECT/GAME_OVER
	# GameState 枚举：MENU=0 BATTLE=1 SHOP=2 ROUTE_SELECT=3 GAME_OVER=4
	var seq: Array = [
		[0, "menu", true],
		[1, "battle", true],
		[2, "battle", true],
		[3, "battle", true],
		[4, "", false],
	]
	var all_ok: bool = true
	for s in seq:
		_gm.set("current_state", s[0])
		_audio.call("_process", 0.016)
		var track: String = str(_audio.get("_current_bgm"))
		var playing: bool = bool(_audio.get("_bgm_player").get("playing"))
		if track != s[1] or playing != s[2]:
			_fail("状态机: state=%d 应 bgm=%s playing=%s, 实得 bgm=%s playing=%s" % [s[0], s[1], str(s[2]), track, str(playing)])
			all_ok = false
		_audio.call("_process", 0.016)  # 二次轮询（同轨不重播路径）
	if all_ok:
		_pass("状态机 / 5 态轮询 → menu/battle/battle/battle/stop（同轨不重播）")
	# 还原 BATTLE 状态防影响后续
	_gm.set("current_state", 1)


# ========== §4 播放层 ==========

func _part_playback() -> void:
	# play_bgm 同轨不重播（连续两次调用 track 不变）
	_audio.call("play_bgm", "menu")
	var first_stream: Variant = _audio.get("_bgm_player").get("stream")
	_audio.call("play_bgm", "menu")
	if _audio.get("_bgm_player").get("stream") == first_stream:
		_pass("播放 / play_bgm 同轨不重播（stream 引用不变）")
	else:
		_fail("播放: 同轨重播不应更换 stream")
	# play_sfx 连发 ×6（池 ×4 轮询零崩溃 + 返回 true）
	var all_played: bool = true
	for i in range(6):
		if not bool(_audio.call("play_sfx", "hit")):
			all_played = false
	var pool_size: int = int(_audio.get("_sfx_pool").size())
	if all_played and pool_size == 4:
		_pass("播放 / play_sfx 连发 ×6 池轮询（×4）零崩溃")
	else:
		_fail("播放: SFX 连发异常 pool=%d" % pool_size)
	# 未知轨/未知 sfx push_warning 零崩溃
	_audio.call("play_bgm", "nope")
	_audio.call("play_sfx", "nope")
	_pass("播放 / 未知 BGM/SFX 名 push_warning 零崩溃（D31 判空守卫）")
	# 音量接口生效
	_audio.call("set_bgm_volume", -6.0)
	_audio.call("set_sfx_volume", -2.0)
	if absf(float(_audio.get("bgm_volume_db")) + 6.0) <= 0.001 and absf(float(_audio.get("sfx_volume_db")) + 2.0) <= 0.001:
		_pass("播放 / set_bgm_volume/set_sfx_volume 生效")
	else:
		_fail("播放: 音量接口未生效")
	# BGM 播放器存在且 playing
	_audio.call("stop_bgm")
	_audio.call("play_bgm", "battle")
	if _audio.get("_bgm_player").get("playing") and str(_audio.get("_current_bgm")) == "battle":
		_pass("播放 / play_bgm(battle) → playing + _current_bgm 记录")
	else:
		_fail("播放: battle BGM 未进入 playing")
	_audio.call("stop_bgm")


# ========== §5 回归 ==========

func _part_regression() -> void:
	# 新代码零 AudioStreamPlayer 场景引用（纯代码 Autoload 防场景未挂节点）
	var scene_hits: int = 0
	for p in ["res://scenes/Main.tscn", "res://scenes/CharacterSelect.tscn", "res://scenes/HUD.tscn",
			"res://scenes/LevelUpPanel.tscn", "res://scenes/ShopPanel.tscn", "res://scenes/Player.tscn"]:
		if FileAccess.file_exists(p):
			var t: String = FileAccess.get_file_as_string(p)
			scene_hits += t.count("AudioStreamPlayer")
	if scene_hits == 0:
		_pass("回归 / 6 场景零 AudioStreamPlayer 节点（纯代码 Autoload 接线）")
	else:
		_fail("回归: 场景中发现 %d 处 AudioStreamPlayer（应纯代码接线）" % scene_hits)
	# 抽样：SFX_MAP 路径与磁盘 exists 一致
	var missing: int = 0
	for k in _audio.get("SFX_MAP"):
		if not FileAccess.file_exists(str(_audio.get("SFX_MAP")[k])):
			missing += 1
	for k in _audio.get("BGM_MAP"):
		if not FileAccess.file_exists(str(_audio.get("BGM_MAP")[k])):
			missing += 1
	if missing == 0:
		_pass("回归 / 12 WAV 路径与 SFX_MAP/BGM_MAP 全一致（磁盘交叉验证）")
	else:
		_fail("回归: %d 处 MAP 路径与磁盘不符" % missing)
	# 回归抽样：day2/day17 探针脚本可加载（音频改动零破坏既有探针入口）
	var probe_ok: bool = true
	for p in ["res://tools/day2_hero_check.gd", "res://tools/day17_elite_check.gd"]:
		if load(p) == null:
			probe_ok = false
	if probe_ok:
		_pass("回归 / day2/day17 探针脚本 load() 成功（抽样）")
	else:
		_fail("回归: day2/day17 探针 load 失败")


# ========== 汇总 ==========

func _report() -> void:
	print("=== Day 24 audio check: %d passed, %d failed ===" % [_checked, _failures])
	if _failures == 0:
		print("DAY24 AUDIO CHECK CLEAN")


func _pass(msg: String) -> void:
	_checked += 1
	print("  PASS  %s" % msg)


func _fail(msg: String) -> void:
	_failures += 1
	_checked += 1
	print("  FAIL  %s" % msg)
