## Day 24 音频管理器（D24-T2）：第 3 个 Autoload（GameManager → DataLoader → AudioManager）
## BGM 状态机：轮询 GameManager.current_state → MENU 播 bgm_menu / BATTLE·SHOP·ROUTE_SELECT 播
## bgm_battle（已在播不重播）/ GAME_OVER stop；SFX 池 ×4 轮询防叠。
## 判空/缺失双护栏（D31）：GameManager 判空（纯单测场景跳过）；12 WAV load() 失败 push_warning + 跳过零崩溃。
extends Node

## 音效资源路径表（与 tools/gen_audio.py 输出一致）
const BGM_MAP: Dictionary = {
	"menu": "res://assets/audio/bgm/bgm_menu.wav",
	"battle": "res://assets/audio/bgm/bgm_battle.wav",
}
const SFX_MAP: Dictionary = {
	"hit": "res://assets/audio/sfx/hit.wav",
	"crit": "res://assets/audio/sfx/crit.wav",
	"death": "res://assets/audio/sfx/death.wav",
	"levelup": "res://assets/audio/sfx/levelup.wav",
	"coin": "res://assets/audio/sfx/coin.wav",
	"shop": "res://assets/audio/sfx/shop.wav",
	"skill": "res://assets/audio/sfx/skill.wav",
	"heal": "res://assets/audio/sfx/heal.wav",
	"event": "res://assets/audio/sfx/event.wav",
	"boss": "res://assets/audio/sfx/boss.wav",
}

const SFX_POOL_SIZE: int = 4

## 音量（dB 默认值；@export 便于项目内调优）
@export var bgm_volume_db: float = -3.0
@export var sfx_volume_db: float = -1.0

var _bgm_player: AudioStreamPlayer = null
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_idx: int = 0
var _current_bgm: String = ""           ## 当前 BGM 轨名（"" = 停止）

## 预加载资源表（name → stream；缺失 push_warning + 跳过零崩溃 D31）
var _bgm_streams: Dictionary = {}
var _sfx_streams: Dictionary = {}


func _ready() -> void:
	# 懒加载设计：_ready 只建播放器节点，流在首次 play 时按需加载——
	# headless `--quit`（0 帧立即退出，baseline import 阶段）零音频活动，防 Dummy AudioServer leak
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.volume_db = bgm_volume_db
	add_child(_bgm_player)
	_bgm_player.finished.connect(_on_bgm_finished)

	# SFX 池 ×4（轮询复用，天然防同帧叠音爆）
	for i in range(SFX_POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.volume_db = sfx_volume_db
		add_child(p)
		_sfx_pool.append(p)


## 按需加载流（缓存；load 失败 push_warning + 返回 null，零崩溃 D31）
func _ensure_stream(cache: Dictionary, path: String, key: String) -> AudioStream:
	if cache.has(key):
		return cache[key]
	var s: AudioStream = load(path)
	if s == null:
		push_warning("[AudioManager] 资源加载失败: %s (%s)" % [key, path])
		return null
	cache[key] = s
	return s


func _exit_tree() -> void:
	# 退出时立即释放播放器与资源引用（queue_free 延迟到帧末，--quit 无下一帧会 leak）
	if _bgm_player != null:
		_bgm_player.stop()
		_bgm_player.free()
		_bgm_player = null
	for p in _sfx_pool:
		if p != null:
			p.stop()
			p.free()
	_sfx_pool.clear()
	_bgm_streams.clear()
	_sfx_streams.clear()


func _process(_delta: float) -> void:
	# BGM 状态机：轮询 GameManager.current_state（D31：get_node_or_null 判空，纯单测场景跳过）
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm == null or not ("current_state" in gm):
		return
	# F3-T7（T-005/T-036 · 2026-08-13）：int 字面量 → GameState 枚举
	# ⚠️ 枚举经 Autoload 实例名访问（GameManager.GameState.X，hud.gd:102 先例）——
	# 独立编译的 Autoload 脚本无法直接引用他脚本内嵌枚举（方案「编译期可见」假设修正登记）
	var state: int = int(gm.current_state)
	match state:
		GameManager.GameState.MENU:  # MENU
			_play_bgm_if_needed("menu")
		GameManager.GameState.BATTLE, GameManager.GameState.SHOP, GameManager.GameState.ROUTE_SELECT:  # BATTLE / SHOP / ROUTE_SELECT
			_play_bgm_if_needed("battle")
		GameManager.GameState.GAME_OVER:  # GAME_OVER
			_stop_bgm()
		_:
			pass


func _play_bgm_if_needed(track: String) -> void:
	if _current_bgm == track and _bgm_player.playing:
		return
	play_bgm(track)


## 播放 BGM（同轨不重播；未知轨 push_warning 零崩溃）
func play_bgm(track: String) -> void:
	if not BGM_MAP.has(track):
		push_warning("[AudioManager] 未知 BGM 轨: %s" % track)
		return
	if _current_bgm == track and _bgm_player.playing:
		return
	var stream: AudioStream = _ensure_stream(_bgm_streams, BGM_MAP[track], track)
	if stream == null:
		return
	_bgm_player.stream = stream
	_bgm_player.play()
	_current_bgm = track


## 停止 BGM
func stop_bgm() -> void:
	_stop_bgm()


func _stop_bgm() -> void:
	if _bgm_player != null:
		_bgm_player.stop()
	_current_bgm = ""


## 播放 SFX（池轮询；返回是否实际播放）
func play_sfx(sfx_name: String) -> bool:
	if not SFX_MAP.has(sfx_name):
		push_warning("[AudioManager] 未知 SFX: %s" % sfx_name)
		return false
	var stream: AudioStream = _ensure_stream(_sfx_streams, SFX_MAP[sfx_name], sfx_name)
	if stream == null:
		return false
	var p: AudioStreamPlayer = _sfx_pool[_sfx_idx]
	_sfx_idx = (_sfx_idx + 1) % SFX_POOL_SIZE
	p.stream = stream
	p.play()
	return true


func set_bgm_volume(db: float) -> void:
	bgm_volume_db = db
	if _bgm_player != null:
		_bgm_player.volume_db = db


func set_sfx_volume(db: float) -> void:
	sfx_volume_db = db
	for p in _sfx_pool:
		p.volume_db = db


func _on_bgm_finished() -> void:
	# 兜底：非手动 stop 情况下循环重播（loop_mode 之外的第二保险）
	if _current_bgm != "" and _bgm_streams.has(_current_bgm):
		_bgm_player.play()
