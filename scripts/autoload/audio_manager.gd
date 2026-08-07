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
	# 加载 12 WAV（load() 失败返回 null → push_warning + 跳过，零崩溃）
	for key in BGM_MAP:
		var s: AudioStream = load(BGM_MAP[key])
		if s == null:
			push_warning("[AudioManager] BGM 加载失败: %s (%s)" % [key, BGM_MAP[key]])
			continue
		_bgm_streams[key] = s
	for key in SFX_MAP:
		var s: AudioStream = load(SFX_MAP[key])
		if s == null:
			push_warning("[AudioManager] SFX 加载失败: %s (%s)" % [key, SFX_MAP[key]])
			continue
		_sfx_streams[key] = s

	# BGM 播放器（loop_mode LOOP_FORWARD + finished→play 兜底双保险）
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


func _process(_delta: float) -> void:
	# BGM 状态机：轮询 GameManager.current_state（D31：get_node_or_null 判空，纯单测场景跳过）
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm == null or not ("current_state" in gm):
		return
	var state: int = int(gm.current_state)
	match state:
		0:  # MENU
			_play_bgm_if_needed("menu")
		1, 2, 3:  # BATTLE / SHOP / ROUTE_SELECT
			_play_bgm_if_needed("battle")
		4:  # GAME_OVER
			_stop_bgm()
		_:
			pass


func _play_bgm_if_needed(track: String) -> void:
	if _current_bgm == track and _bgm_player.playing:
		return
	play_bgm(track)


## 播放 BGM（同轨不重播；未知轨 push_warning 零崩溃）
func play_bgm(track: String) -> void:
	if not _bgm_streams.has(track):
		push_warning("[AudioManager] 未知 BGM 轨: %s" % track)
		return
	if _current_bgm == track and _bgm_player.playing:
		return
	_bgm_player.stream = _bgm_streams[track]
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
	if not _sfx_streams.has(sfx_name):
		push_warning("[AudioManager] 未知 SFX: %s" % sfx_name)
		return false
	var p: AudioStreamPlayer = _sfx_pool[_sfx_idx]
	_sfx_idx = (_sfx_idx + 1) % SFX_POOL_SIZE
	p.stream = _sfx_streams[sfx_name]
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
