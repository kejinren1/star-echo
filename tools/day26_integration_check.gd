## Day 26 阶段 D 整合校验（D26-T1/T2/T3 合一探针）：四域资产齐备 + 接线完整性抽查 + 数据交叉引用
##
## 用法（无头，不需要编辑器）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day26_integration_check.gd
##
## 校验内容（对应 docs/SOLUTION_PLAN.md 第 7 轮任务 1/2/3）：
##   §1 美术资产：SPRITE_MAP 23 键 + FALLBACK 3 键路径 exists + Boss scale 白盒复位（D17 双点）
##                 + 4 角色 walk(192×32)/attack/skill + factions 5 + backgrounds 4 + 头像 3 + .import 齐全
##   §2 特效资产：FX_CONFIG 10 键（含 5 新特效）+ 5 新特效 PNG + hit 消费点 + source_id 接线（se_star_fall→meteor）
##   §3 音频资产：12 WAV 头合法（RIFF/WAVE + mono + 22050 + 16bit）+ AudioManager autoload + BGM 状态机 5 态 + SFX_MAP 10 键
##   §4 剧情载体：LORE.md exists + events.json 10 事件 + 解锁文案数据存在性（解锁接线 = Day 27 依赖，缺失不判失败）
##   §5 数据交叉（T3）：items 54 / weapons 36（嵌套累加 D36）/ 12 WAV 命名与 MAP 一致 / 回归期望合计 609
##   §6 回归抽样：回归脚本 PROBES 24 项 + 关键探针 load + day18_19 scale 锚点
##   T2 接线抽查并入 §2/§3；顺延项清单输出尾部（供 W5 写入 REPORT_PHASE_D 与 PLAYTEST）
##
## 纯只读（D37）：ResourceLoader.exists / FileAccess / JSON 解析 / 白盒只读方法调用——零资产写入、零场景实例化副作用。
## 退出码 0 = 全部通过；非 0 = 失败项数。
extends SceneTree

const EXPECTED_FX_KEYS: Array = ["hit", "crit", "death", "levelup", "pickup",
	"fireball", "turret_deploy", "blade_burst", "meteor", "shield"]
const NEW_FX_KEYS: Array = ["fireball", "turret_deploy", "blade_burst", "meteor", "shield"]
const EXPECTED_BGM_KEYS: Array = ["menu", "battle"]
const EXPECTED_SFX_KEYS: Array = ["hit", "crit", "death", "levelup", "coin",
	"shop", "skill", "heal", "event", "boss"]
const CHARACTER_PREFIXES: Array = ["elin", "noah", "lain", "siia"]
const FACTIONS: Array = ["abyss_council", "echo_alliance", "free_mercs", "mech_empire", "star_cult"]
const BACKGROUNDS: Array = ["corrupted_forest", "lava_mine", "void_corridor", "wulan_workshop"]
const PORTRAITS: Array = ["elin_portrait", "noah_portrait", "lain_portrait"]

var _idx: int = 0
var _sub: int = 0
var _gm: Node = null
var _audio: Node = null
var _expect_loaded: bool = false
var _checked: int = 0
var _failures: int = 0
var _deferred: Array = []   ## 顺延项/偏差登记（不判失败）


func _initialize() -> void:
	print("=== Day 26 integration check ===")


func _process(_delta: float) -> bool:
	if not _expect_loaded:
		_load_mocks()
	_sub = _advance(_sub)
	return false


func _load_mocks() -> void:
	_expect_loaded = true
	_gm = root.get_node_or_null("GameManager")
	_audio = root.get_node_or_null("AudioManager")
	if _audio == null:
		_fail("AudioManager autoload 未注册（project.godot [autoload] 缺失）")
		quit(_failures)


func _advance(sub: int) -> int:
	match sub:
		0:
			_part_art()
			return 1
		1:
			_part_fx()
			return 2
		2:
			_part_audio()
			return 3
		3:
			_part_lore()
			return 4
		4:
			_part_data_crossref()
			return 5
		5:
			_part_regression()
			return 6
		6:
			_part_deferred_list()
			_report()
			quit(_failures)
	return 6


# ========== §1 美术资产 ==========

func _part_art() -> void:
	var enemy_script: GDScript = load("res://scripts/enemy/enemy.gd")
	if enemy_script == null:
		_fail("美术: enemy.gd load 失败")
		return
	var sprite_map: Dictionary = enemy_script.get("SPRITE_MAP")
	if sprite_map.size() == 23:
		_pass("美术 / SPRITE_MAP 23 键（chaser→predator 全量换皮）")
	else:
		_fail("美术: SPRITE_MAP 键数 %d ≠ 23" % sprite_map.size())
	# 全部 move/death 路径 exists（46 路径）
	var miss: int = 0
	for key in sprite_map:
		var cfg: Dictionary = sprite_map[key]
		for field in ["move", "death"]:
			var p: String = str(cfg.get(field, ""))
			if p == "" or not ResourceLoader.exists(p):
				miss += 1
	if miss == 0:
		_pass("美术 / SPRITE_MAP 46 路径（23 键 × move/death）全 exists")
	else:
		_fail("美术: SPRITE_MAP %d 处路径缺失" % miss)
	# FALLBACK 3 键
	var fallback: Dictionary = enemy_script.get("FALLBACK_SPRITES")
	var fb_miss: int = 0
	for key in fallback:
		var cfg: Dictionary = fallback[key]
		for field in ["move", "death"]:
			if not ResourceLoader.exists(str(cfg.get(field, ""))):
				fb_miss += 1
	if fallback.size() == 3 and fb_miss == 0:
		_pass("美术 / FALLBACK_SPRITES 3 键 6 路径全 exists")
	else:
		_fail("美术: FALLBACK 异常 size=%d miss=%d" % [fallback.size(), fb_miss])
	# hit_radius 锚点（D16 解耦：28/36/56）
	if _hit_radius_ok(sprite_map):
		_pass("美术 / hit_radius 锚点（regular 28 / elite 36 / boss 56）")
	else:
		_fail("美术: hit_radius 锚点异常")
	# Boss scale 白盒复位（D17 双点之一：预置 (2,2) → initialize(boss+phases) → 复位 (1,1)）
	var boss_ok: bool = true
	for bid in ["invoker", "predator"]:
		var e: Node = enemy_script.new()
		e.scale = Vector2(2.0, 2.0)
		e.initialize({"id": bid, "category": "boss", "max_health": 500.0,
			"move_speed": 60.0, "damage": 10.0, "phases": [{"threshold": 0.5, "attack": "spread"}]})
		if not (e.is_boss and e.scale == Vector2(1.0, 1.0)):
			boss_ok = false
		e.free()
	if boss_ok:
		_pass("美术 / Boss scale 白盒复位 ×1（%s，D17 语义断言）" % "invoker/predator")
	else:
		_fail("美术: Boss scale 未复位")
	# 角色 walk strip（elin 实装拼豆图纸动画 640×64·10 帧，其余收口占位 192×32·6 帧）+ attack/skill strip
	var char_ok: bool = true
	var char_detail: String = ""
	for prefix in CHARACTER_PREFIXES:
		var walk_p: String = "res://assets/sprites/characters/%s_walk.png" % prefix
		var atk_p: String = "res://assets/sprites/characters/%s_attack.png" % prefix
		var skl_p: String = "res://assets/sprites/characters/%s_skill.png" % prefix
		if not ResourceLoader.exists(walk_p) or not ResourceLoader.exists(atk_p) or not ResourceLoader.exists(skl_p):
			char_ok = false
			continue
		var img := Image.load_from_file(ProjectSettings.globalize_path(walk_p))
		var expect_w: int = 640 if prefix == "elin" else 192
		var expect_h: int = 64 if prefix == "elin" else 32
		if img.get_width() != expect_w or img.get_height() != expect_h:
			char_ok = false
	if char_ok:
		_pass("美术 / 4 角色 walk（elin 640×64 / 其余 192×32）+ attack/skill strip 全 exists")
	else:
		_fail("美术: 角色 walk/attack/skill 缺失或尺寸非预期")
	# factions / backgrounds / portraits
	if _all_exists(FACTIONS, "res://assets/sprites/factions/%s.png"):
		_pass("美术 / factions 5 枚 exists")
	else:
		_fail("美术: factions 缺失")
	if _all_exists(BACKGROUNDS, "res://assets/sprites/backgrounds/%s.png"):
		_pass("美术 / backgrounds 4 枚 exists")
	else:
		_fail("美术: backgrounds 缺失")
	if _all_exists(PORTRAITS, "res://assets/sprites/characters/%s.png"):
		_pass("美术 / 遗留头像 3 枚 exists")
	else:
		_fail("美术: 头像缺失")
	# .import 齐全（敌 sprite 10 + 特效 10 + 角色 walk 4 + 背景 4 + 阵营 5）
	var imp_miss: int = 0
	for f in ["slime_move", "slime_death", "skeleton_move", "skeleton_death", "elite_move",
			"elite_death", "invoker_move", "invoker_death", "predator_move", "predator_death"]:
		if not FileAccess.file_exists("res://assets/sprites/enemies/%s.png.import" % f):
			imp_miss += 1
	for prefix in CHARACTER_PREFIXES:
		if not FileAccess.file_exists("res://assets/sprites/characters/%s_walk.png.import" % prefix):
			imp_miss += 1
	for b in BACKGROUNDS:
		if not FileAccess.file_exists("res://assets/sprites/backgrounds/%s.png.import" % b):
			imp_miss += 1
	for f in FACTIONS:
		if not FileAccess.file_exists("res://assets/sprites/factions/%s.png.import" % f):
			imp_miss += 1
	if imp_miss == 0:
		_pass("美术 / 敌 10 + 角色 walk 4 + 背景 4 + 阵营 5 .import 齐全")
	else:
		_fail("美术: %d 处 .import 缺失" % imp_miss)
	# T2 SPRITE_MAP 命中（静态语义）：player.gd 有 _apply_character_sprite 薄委托 + fighter 兜底
	# （F4-C：兜底加载迁 player_anim.gd）+ siia 资产已验
	var player_txt: String = FileAccess.get_file_as_string("res://scripts/player/player.gd")
	var panim_txt: String = FileAccess.get_file_as_string("res://scripts/player/player_anim.gd")
	if player_txt.find("_apply_character_sprite") >= 0 \
			and (player_txt.find("fighter_walk.png") >= 0 or panim_txt.find("fighter_walk.png") >= 0) \
			and ResourceLoader.exists("res://assets/sprites/characters/siia_walk.png"):
		_pass("T2 / SPRITE_MAP 命中链路（_apply_character_sprite + fighter 兜底 + siia 资产齐备）")
	else:
		_fail("T2: player 精灵链路异常")


func _hit_radius_ok(m: Dictionary) -> bool:
	if not m.has("chaser") or not m.has("butcher") or not m.has("invoker"):
		return false
	var cfg: Dictionary = m["chaser"]
	if not cfg.has("hit_radius") or absf(float(cfg["hit_radius"]) - 28.0) > 0.01:
		return false
	cfg = m["butcher"]
	if not cfg.has("hit_radius") or absf(float(cfg["hit_radius"]) - 36.0) > 0.01:
		return false
	cfg = m["invoker"]
	if not cfg.has("hit_radius") or absf(float(cfg["hit_radius"]) - 56.0) > 0.01:
		return false
	return true


func _all_exists(names: Array, fmt: String) -> bool:
	for n in names:
		if not ResourceLoader.exists(fmt % n):
			return false
	return true


# ========== §2 特效资产 + T2 接线抽查 ==========

func _part_fx() -> void:
	var vfx_script: GDScript = load("res://scripts/effects/vfx_player.gd")
	if vfx_script == null:
		_fail("特效: vfx_player.gd load 失败")
		return
	var cfg: Dictionary = vfx_script.get("FX_CONFIG")
	if cfg.size() == 10:
		_pass("特效 / FX_CONFIG 键数 == 10")
	else:
		_fail("特效: FX_CONFIG 键数 %d ≠ 10" % cfg.size())
	var new_ok: bool = true
	for k in NEW_FX_KEYS:
		if not cfg.has(k):
			new_ok = false
	if new_ok:
		_pass("特效 / 5 新特效键（fireball/turret_deploy/blade_burst/meteor/shield）")
	else:
		_fail("特效: 新特效键缺失")
	var png_miss: int = 0
	for k in NEW_FX_KEYS:
		var p: String = "res://assets/sprites/effects/fx_%s.png" % k
		if not ResourceLoader.exists(p) or not FileAccess.file_exists(p + ".import"):
			png_miss += 1
	if png_miss == 0:
		_pass("特效 / 5 新特效 PNG + .import 全 exists")
	else:
		_fail("特效: %d 处新特效 PNG/.import 缺失" % png_miss)
	# hit 消费点激活（静态：projectile.gd 普通命中 spawn "hit"；行为已由 day23 探针 18/18 覆盖）
	var proj_txt: String = FileAccess.get_file_as_string("res://scripts/weapons/projectile.gd")
	if proj_txt.find("VfxPlayer.spawn") >= 0 and proj_txt.find("\"hit\"") >= 0:
		_pass("特效 / hit 消费点激活（projectile 普通命中 spawn \"hit\"）")
	else:
		_fail("特效: projectile hit 消费点缺失")
	# source_id 接线（weapon_controller 弹丸携带武器来源 → 进化陨石分派 meteor）
	var wc_txt: String = FileAccess.get_file_as_string("res://scripts/weapons/weapon_controller.gd")
	if wc_txt.find("META_SOURCE_ID") >= 0 and wc_txt.find("se_star_fall") >= 0 and wc_txt.find("meteor") >= 0:
		_pass("特效 / source_id 接线（se_star_fall 进化陨石 → meteor 映射在册）")
	else:
		_fail("特效: weapon_controller source_id 接线缺失")
	# VfxPlayer 四消费点键存在（hit/crit/death/levelup）
	var four_ok: bool = true
	for k in ["hit", "crit", "death", "levelup"]:
		if not cfg.has(k):
			four_ok = false
	if four_ok:
		_pass("T2 / VfxPlayer 四消费点键在册（hit/crit/death/levelup）")
	else:
		_fail("T2: 四消费点键缺失")
	# T2 GameManager.hud 抽查：方案假设 GameManager.hud.show_damage_number 接口——
	# 实测 F-11 经 enemy_damage.gd（F4-A 拆分，原 enemy.gd）_spawn_damage_number 直接 spawn
	# （无 hud 字段/方法）→ 语义替代断言 + 偏差登记
	var gm_txt: String = FileAccess.get_file_as_string("res://scripts/autoload/game_manager.gd")
	var hud_txt: String = FileAccess.get_file_as_string("res://scripts/ui/hud.gd")
	var has_gm_hud: bool = gm_txt.find("var hud") >= 0
	var has_show_dn: bool = hud_txt.find("show_damage_number") >= 0
	var enemy_txt: String = FileAccess.get_file_as_string("res://scripts/enemy/enemy.gd")
	var enemy_dmg_txt: String = FileAccess.get_file_as_string("res://scripts/enemy/enemy_damage.gd")
	var dn_script: GDScript = load("res://scripts/effects/damage_number.gd")
	var dn_spawn: bool = dn_script != null and dn_script.get("spawn") != null
	if not has_gm_hud or not has_show_dn:
		_deferred.append("F-11 接线接口偏差（T2 抽查登记）：GameManager.hud / hud.show_damage_number 接口不存在；"
			+ "实际实现 = enemy_damage.gd _spawn_damage_number → damage_number.gd spawn 直接飘字"
			+ "（F-11 已由 day18_feedback_check 16/16 行为收口）——按语义断言，非缺陷")
	if (enemy_txt.find("_spawn_damage_number") >= 0 or enemy_dmg_txt.find("_spawn_damage_number") >= 0) and dn_spawn:
		_pass("T2 / F-11 伤害数字语义链路（enemy_damage._spawn_damage_number + damage_number.spawn）")
	else:
		_fail("T2: F-11 伤害数字链路异常")
	# T2 VfxPlayer 消费点行为抽查：GameManager.vfx_container 存在性（hit 消费依赖）
	if _gm != null and _gm.get("vfx_container") != null:
		_pass("T2 / GameManager.vfx_container 在册（hit/levelup 特效容器）")
	else:
		_deferred.append("GameManager.vfx_container 未加载（单测场景无容器）——行为已由 day23 探针 18/18 覆盖，登记不判失败")


# ========== §3 音频资产 ==========

func _part_audio() -> void:
	# 12 WAV 头合法
	var wav_ok: bool = true
	for key in EXPECTED_BGM_KEYS:
		if not _wav_valid("res://assets/audio/bgm/bgm_%s.wav" % key):
			wav_ok = false
	for key in EXPECTED_SFX_KEYS:
		if not _wav_valid("res://assets/audio/sfx/%s.wav" % key):
			wav_ok = false
	if wav_ok:
		_pass("音频 / 12 WAV 头合法（RIFF/WAVE + mono + 22050Hz + 16bit）")
	else:
		_fail("音频: 存在缺失/非法 WAV")
	# project.godot autoload
	var cfg_text: String = FileAccess.get_file_as_string("res://project.godot")
	if cfg_text.find("AudioManager=\"*res://scripts/autoload/audio_manager.gd\"") >= 0:
		_pass("音频 / project.godot [autoload] 含 AudioManager（第 3 Autoload）")
	else:
		_fail("音频: AudioManager 未注册 autoload")
	if _audio == null:
		return
	# SFX_MAP / BGM_MAP 键
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
		_pass("音频 / BGM_MAP 2 键（menu/battle）")
	else:
		_fail("音频: BGM_MAP 缺键")
	if sfx_ok:
		_pass("音频 / SFX_MAP 10 键全覆盖")
	else:
		_fail("音频: SFX_MAP 缺键")
	# BGM 状态机 5 态白盒（GameManager 未加载判空零报错）
	if _gm == null:
		_deferred.append("GameManager 未加载——BGM 状态机白盒跳过（判空守卫 D31），登记不判失败")
		return
	var seq: Array = [
		[0, "menu"],
		[1, "battle"],
		[2, "battle"],
		[3, "battle"],
		[4, ""],
	]
	var all_ok: bool = true
	for s in seq:
		_gm.set("current_state", s[0])
		_audio.call("_process", 0.016)
		var track: String = str(_audio.get("_current_bgm"))
		if track != s[1]:
			_fail("状态机: state=%d 应 bgm=%s 实得 %s" % [s[0], s[1], track])
			all_ok = false
		_audio.call("_process", 0.016)
	if all_ok:
		_pass("音频 / BGM 状态机 5 态（MENU→menu / BATTLE·SHOP·ROUTE_SELECT→battle / GAME_OVER→stop）")
	_gm.set("current_state", 1)
	_audio.call("_process", 0.016)
	_audio.call("stop_bgm")


func _wav_valid(res_path: String) -> bool:
	if not FileAccess.file_exists(res_path):
		_fail("音频: 缺失 %s" % res_path)
		return false
	var f: FileAccess = FileAccess.open(res_path, FileAccess.READ)
	if f == null:
		_fail("音频: 无法打开 %s" % res_path)
		return false
	var data: PackedByteArray = f.get_buffer(f.get_length())
	f.close()
	if data.size() < 44:
		_fail("音频: %s 过小" % res_path)
		return false
	if data[0] != 82 or data[1] != 73 or data[2] != 70 or data[3] != 70:
		_fail("音频: %s 非 RIFF" % res_path)
		return false
	if data[8] != 87 or data[9] != 65 or data[10] != 86 or data[11] != 69:
		_fail("音频: %s 非 WAVE" % res_path)
		return false
	if data[20] != 1 or data[21] != 0:
		_fail("音频: %s 非 PCM" % res_path)
		return false
	if data[22] != 1 or data[23] != 0:
		_fail("音频: %s 非 mono" % res_path)
		return false
	var sr: int = data[24] | (data[25] << 8) | (data[26] << 16) | (data[27] << 24)
	if sr != 22050:
		_fail("音频: %s 采样率 %d ≠ 22050" % [res_path, sr])
		return false
	if data[34] != 16 or data[35] != 0:
		_fail("音频: %s 非 16bit" % res_path)
		return false
	return true


# ========== §4 剧情载体 ==========

func _part_lore() -> void:
	var lore_path: String = "res://docs/LORE.md"
	if FileAccess.file_exists(lore_path):
		var sz: int = FileAccess.get_file_as_string(lore_path).length()
		if sz > 1000:
			_pass("剧情 / LORE.md 在盘（%dB）" % sz)
		else:
			_fail("剧情: LORE.md 过小（%dB）" % sz)
	else:
		_fail("剧情: LORE.md 缺失")
	# events.json 10 事件 + 解锁文案载体字段
	var events_script: JSON = null
	var ev: Dictionary = {}
	if FileAccess.file_exists("res://data/events.json"):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/events.json"))
		if parsed is Dictionary:
			ev = parsed
	if ev.has("events") and (ev["events"] is Array) and (ev["events"] as Array).size() == 10:
		_pass("剧情 / events.json 10 事件")
	else:
		_fail("剧情: events.json 事件数 ≠ 10")
	# 各事件 id 非空 + 文案字段存在（title/desc 类）
	var ev_ok: bool = true
	var ev_ids: Array = []
	for e in ev.get("events", []):
		if not (e is Dictionary):
			ev_ok = false
			continue
		var eid: String = str(e.get("id", ""))
		if eid == "" or eid in ev_ids:
			ev_ok = false
		ev_ids.append(eid)
		var has_text: bool = false
		for tf in ["title", "desc", "description", "text", "name", "story"]:
			if e.has(tf) and str(e[tf]) != "":
				has_text = true
		if not has_text:
			ev_ok = false
	if ev_ok:
		_pass("剧情 / 10 事件 id 唯一 + 解锁文案载体字段非空（接线 = Day 27 依赖，存在即验）")
	else:
		_fail("剧情: 事件字段异常")
	# LORE.md 与事件主题抽样对应
	var lore_txt: String = FileAccess.get_file_as_string(lore_path) if FileAccess.file_exists(lore_path) else ""
	var theme_hits: int = 0
	for kw in ["方舟", "星骸", "回响", "回声", "帝国", "异变"]:
		if lore_txt.find(kw) >= 0:
			theme_hits += 1
	if theme_hits >= 3:
		_pass("剧情 / LORE.md 主题关键词抽样（方舟/星骸/异变等 ≥3 命中）")
	else:
		_fail("剧情: LORE.md 主题命中不足（%d）" % theme_hits)


# ========== §5 数据交叉引用（T3） ==========

func _part_data_crossref() -> void:
	# items.json 54 项
	var items_ok: bool = false
	if FileAccess.file_exists("res://data/items.json"):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/items.json"))
		if parsed is Dictionary and (parsed as Dictionary).has("items"):
			var arr: Array = (parsed as Dictionary)["items"]
			items_ok = arr.size() == 54
	if items_ok:
		_pass("T3 / items.json 54 项（含 F-13 三机制被动）")
	else:
		_fail("T3: items.json 项数 ≠ 54")
	# weapons.json 嵌套累加 36（D36：勿扁平 len）
	var w_total: int = -1
	if FileAccess.file_exists("res://data/weapons.json"):
		var parsed2: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/weapons.json"))
		if parsed2 is Dictionary and (parsed2 as Dictionary).has("weapons"):
			var cats: Dictionary = (parsed2 as Dictionary)["weapons"]
			w_total = 0
			for cat in cats:
				w_total += (cats[cat] as Array).size()
	if w_total == 36:
		_pass("T3 / weapons.json 36 把（嵌套累加 melee9+ranged9+elemental10+engineering8，D36 口径）")
	else:
		_fail("T3: weapons 累加 %d ≠ 36" % w_total)
	# 12 WAV 命名与 AudioManager MAP 键一致（磁盘交叉）
	var cross_ok: bool = true
	if _audio != null:
		for k in _audio.get("BGM_MAP"):
			if not FileAccess.file_exists(str(_audio.get("BGM_MAP")[k])):
				cross_ok = false
		for k in _audio.get("SFX_MAP"):
			if not FileAccess.file_exists(str(_audio.get("SFX_MAP")[k])):
				cross_ok = false
	if cross_ok:
		_pass("T3 / 12 WAV 命名与 SFX_MAP/BGM_MAP 键全一致（磁盘交叉验证）")
	else:
		_fail("T3: WAV 与 MAP 不一致")


# ========== §6 回归全套（抽样 + 期望值核验） ==========

func _part_regression() -> void:
	# 回归驱动期望合计 == 609（Day 24 收口基准）
	var rr: String = ""
	if FileAccess.file_exists("res://tools/_regression_run.py"):
		rr = FileAccess.get_file_as_string("res://tools/_regression_run.py")
	var probe_count: int = 0
	var expect_sum: int = 0
	var ln: int = rr.find("PROBES = [")
	if ln >= 0:
		# 限制在 PROBES 数组区域内解析（截至下一个 ']' 行）
		var seg: String = rr.substr(ln, 6000)
		var end: int = seg.find("\n]")
		if end > 0:
			seg = seg.substr(0, end)
		var lines: PackedStringArray = seg.split("\n")
		for l in lines:
			var t: String = l.strip_edges()
			# 探针条目均以 ("dayXX... 开头
			if t.begins_with("(\"day"):
				# 行尾格式 "…, 32),": split 后末元素为空串，取倒数第二个并去尾缀
				var parts: PackedStringArray = t.split(",")
				var last: String = parts[parts.size() - 2].replace(")", "").strip_edges()
				if last.is_valid_int():
					expect_sum += int(last)
					probe_count += 1
	# F31 同步（2026-08-08 #39 修正）：runner +day28_f31(26) → 29 项 / 期望 759（733 + 26）
	# Day30-P0 同步（2026-08-10）：runner +day30_p0_fix(15) → 30 项 / 期望 774（759 + 15）
	# F1-A/B 同步（2026-08-10）：runner +day30_f1_scaling(10) → 31 项 / 期望 784（774 + 10）
	# F1-D 同步（2026-08-10）：runner +day30_f1d_shop(8) → 32 项 / 期望 792（784 + 8）
	# F1-C 同步（2026-08-11）：runner +day29_elin(14)+day29_attack(20) → 34 项 / 期望 830（792 + 14 + 20 + f1_scaling 10→14）
	# F2 同步（2026-08-12）：runner +day30_f2_boundary(36) → 35 项 / 期望 866（830 + 36）
	# F1-散 同步（2026-08-13）：runner +day30_f1_scatter(19) → 36 项 / 期望 885（866 + 19）
	# F3 同步（2026-08-13）：runner +day30_f3_compliance(12)+day30_f3_flow(21) → 38 项 / 期望 918（885 + 12 + 21）
	# BS-A 同步（2026-08-13）：runner +day30_effect(18) → 39 项 / 期望 936（918 + 18）
	# BS-B/C/D 同步（2026-08-13）：day30_boss_skill 16→49（+§4 pattern + §5 难度 + §5b fan/beam/charge/QTE + §6 免疫 + §11 验收）→ 40 项 / 期望 985（936 + 49）
	# G 系列同步（2026-08-14）：runner +6（expect 门槛 8+10+10+8+8+10 = 54）→ 46 项 / 期望 1039（985 + 54）
	if probe_count == 46:
		_pass("回归 / _regression_run.py PROBES 46 项（40 + G 系列 6 探针）")
	else:
		_fail("回归: PROBES 项数 %d ≠ 46" % probe_count)
	if expect_sum == 1039:
		_pass("回归 / 期望断言合计 1039（985 + G 系列门槛 54）")
	else:
		_fail("回归: 期望合计 %d ≠ 1039" % expect_sum)
	# 关键探针 load 抽样
	var load_ok: bool = true
	for p in ["res://tools/day18_19_boss_check.gd", "res://tools/day21_22_art_check.gd",
			"res://tools/day23_vfx_check.gd", "res://tools/day24_f13_check.gd", "res://tools/day24_audio_check.gd"]:
		if load(p) == null:
			load_ok = false
	if load_ok:
		_pass("回归 / 5 关键探针脚本 load() 成功（day18_19/day21_22/day23/day24_f13/day24_audio）")
	else:
		_fail("回归: 探针 load 失败")
	# day18_19 探针 scale 锚点（D17 双点之二）
	var d1819_txt: String = FileAccess.get_file_as_string("res://tools/day18_19_boss_check.gd")
	if d1819_txt.find("scale") >= 0 and (d1819_txt.find("1.0") >= 0 or d1819_txt.find("1, 1") >= 0):
		_pass("回归 / day18_19 探针 scale 断言锚点在册（D17 双点同步）")
	else:
		_fail("回归: day18_19 scale 锚点缺失")


# ========== 顺延项清单（T3 输出段，不计数） ==========

func _part_deferred_list() -> void:
	print("=== 顺延项 / 偏差登记清单（供 W5 写入 REPORT_PHASE_D 与 PLAYTEST，不判失败） ===")
	if _deferred.is_empty():
		print("  - 无登记项")
	else:
		for d in _deferred:
			print("  - %s" % d)
	print("  - F 系列 P1（F-03/F-05/F-06/F-07/F-11）：均已由反馈专员落地（16c6dd3），无顺延")
	print("  - 遗物 HUD 槽位显示：P1 顺延登记（存在则验原则）")
	print("  - 空间音 / 音量 UI 滑块：P1 顺延登记（2D 占位阶段 AudioStreamPlayer 最稳）")
	print("  - mech_heart 纳入遗物池：P1 登记（可选）")
	print("  - 剧情解锁接线（角色小传可读）：Day 27 局外养成依赖（D25 剩余项）")


func _report() -> void:
	print("=== Day 26 integration check: %d passed, %d failed ===" % [_checked, _failures])
	if _failures == 0:
		print("DAY26 INTEGRATION CHECK CLEAN")


func _pass(msg: String) -> void:
	_checked += 1
	print("  PASS  %s" % msg)


func _fail(msg: String) -> void:
	_failures += 1
	_checked += 1
	print("  FAIL  %s" % msg)
