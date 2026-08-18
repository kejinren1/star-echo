## Day 30-F3 状态机合规探针（静态扫描 · T-031~036 收口验收）
##
## 用法（无头）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day30_f3_compliance_check.gd
##
## 校验内容（docs/SOLUTION_PLAN.md §2 F3-T8）：
##   §1 `current_state = ` 赋值仅 _transition 内 1 处（其余零残留）
##   §2 `_set_state` 项目零残留（已改 _transition）
##   §3 状态赋值处无字符串字面量（route_type_from_string 单点白名单）
##   §4 禁新增 bool 行为标志（20 个成员 bool 白名单基线实测，白名单外新增 → 失败）
##   §5 CODE_STYLE.md 存在且含两形态 + 禁令关键词
##   §6 audio match 无 int 字面量（GameState 枚举化）
##
## 退出码 0 = 全部通过；非 0 = 失败项数。
extends SceneTree

const BOOL_WHITELIST: Dictionary = {
	"scripts/autoload/data_loader.gd": ["_loaded"],
	"scripts/autoload/game_manager.gd": ["_shop_from_battle", "debug_cheat", "is_boss_wave", "route_enabled"],
	"scripts/autoload/main.gd": ["_debug_keys_prev"],
	"scripts/enemy/enemy.gd": ["_boss_charge", "_is_charging", "is_alive", "stunned"],
	"scripts/enemy/enemy_spawner.gd": ["_is_spawning"],
	"scripts/player/player.gd": ["_facing_left", "_last_stand_active", "is_alive", "stunned", "invulnerable"],
	"scripts/player/skill_controller.gd": ["_warned_not_impl"],
	"scripts/systems/wave_manager.gd": ["is_active", "_portal_await"],
	"scripts/ui/shop.gd": ["star_grace_available", "star_grace_used"],
	"scripts/weapons/projectile.gd": ["_exploded", "_last_crit"],
	"scripts/weapons/turret.gd": ["permanent"],
	"scripts/boss/exec_circle.gd": ["_resolved"],
	"scripts/boss/exec_fan.gd": ["_resolved"],
	"scripts/boss/exec_beam.gd": ["_resolved"],
	"scripts/boss/exec_charge.gd": ["_resolved"],
	# PS-B（2026-08-16 · PLAYER_SKILL_SPEC §5/§6）：位移/召唤/增益执行器同款骨架
	"scripts/boss/exec_dash.gd": ["_resolved"],
	"scripts/boss/exec_blink.gd": ["_resolved"],
	"scripts/boss/exec_leap.gd": ["_resolved"],
	"scripts/boss/exec_spawn.gd": ["_resolved"],
	"scripts/boss/exec_buff.gd": ["_resolved"],
	# PS-B4 探针辅助：dummy_target（测试桩，非游戏逻辑）
	"scripts/dummy_target.gd": ["is_alive", "invulnerable"],
	# AUDIO_FEEL（2026-08-18 AF-P0 批 A）：hitstop 顿帧冻结标记（防旧 timer 回调误恢复，
	# time_scale=0 恢复链的必要状态；非行为分支开关）
	"scripts/systems/hitstop_controller.gd": ["_freezing"],
	# F-49（2026-08-18 用户拍板「通关不突兀」）：通关传送门等待标记——敌全灭 → true
	# （停表 + 防重复开传送门），玩家进传送门 → false → _end_wave 正常结算；流程状态非分支开关
	"scripts/world/loot_chest.gd": ["_claimed"],
}

var _sub: int = 0
var _checked: int = 0
var _failures: int = 0

func _initialize() -> void:
	print("=== Day 30 F3 状态机合规检查 ===")

func _process(_delta: float) -> bool:
	if _sub == 0:
		_sub = _advance(_sub)
	elif _sub == 1:
		_report()
		quit(_failures)
		return true
	return false

func _advance(sub: int) -> int:
	_part_state_assign()
	_part_set_state_gone()
	_part_no_string_states()
	_part_bool_whitelist()
	_part_code_style()
	_part_audio_enum()
	return 1

func _file(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)

func _non_comment_lines(src: String) -> PackedStringArray:
	var out := PackedStringArray()
	for ln in src.split("\n"):
		var t: String = ln.strip_edges()
		if t.is_empty() or t.begins_with("#") or t.begins_with("##"):
			continue
		out.append(t)
	return out

# ========== §1 current_state 赋值单点 ==========

func _part_state_assign() -> void:
	var src: String = _file("res://scripts/autoload/game_manager.gd")
	var count: int = 0
	for ln in _non_comment_lines(src):
		if ln.contains("current_state = "):
			count += 1
	_ok(count == 1, "§1 current_state = 赋值仅 _transition 内 1 处（实得 %d）" % count)

# ========== §2 _set_state 零残留 ==========

func _part_set_state_gone() -> void:
	var hits: int = 0
	for f in _all_scripts():
		var src: String = _file(f)
		for ln in _non_comment_lines(src):
			if ln.contains("_set_state"):
				hits += 1
	_ok(hits == 0, "§2 _set_state 项目零残留（实得 %d）" % hits)
	# 探针层同步检查：tools/day*.gd 探针也不得残留 _set_state（F3 后接口已更名；
	# 排除本合规探针自身——函数名/消息字符串含 _set_state 字样属自指）
	var probe_hits: int = 0
	var pd := DirAccess.open("res://tools")
	if pd:
		pd.list_dir_begin()
		var pf: String = pd.get_next()
		while pf != "":
			if not pd.current_is_dir() and pf.begins_with("day") and pf.ends_with(".gd") \
					and pf != "day30_f3_compliance_check.gd":
				for ln in _non_comment_lines(_file("res://tools/" + pf)):
					if ln.contains("_set_state"):
						probe_hits += 1
			pf = pd.get_next()
		pd.list_dir_end()
	_ok(probe_hits == 0, "§2 探针层 _set_state 零残留（实得 %d）" % probe_hits)

# ========== §3 状态赋值处无字符串字面量 ==========

func _part_no_string_states() -> void:
	var src: String = _file("res://scripts/autoload/game_manager.gd")
	# 节点类型字符串仅允许出现在 route_type_from_string 白名单（各 1 处）+ 注释豁免
	var battle_count: int = 0
	var elite_count: int = 0
	var shop_count: int = 0
	var event_count: int = 0
	var boss_count: int = 0
	for ln in _non_comment_lines(src):
		if ln.contains('"battle"'):
			battle_count += 1
		if ln.contains('"elite"'):
			elite_count += 1
		if ln.contains('"shop"'):
			shop_count += 1
		if ln.contains('"event"'):
			event_count += 1
		if ln.contains('"boss"'):
			boss_count += 1
	# 白名单 = route_type_from_string 内各 1 处；boss 例外 2 = 转换函数 1 + 波次前缀/SFX 轨名
	# "boss" 1（_start_next_wave enemy_id.begins_with("boss:") + play_sfx("boss")，合法非状态用法）
	var white_ok: bool = battle_count <= 1 and elite_count <= 1 and shop_count <= 1 \
		and event_count <= 1 and boss_count <= 2
	_ok(white_ok, "§3 节点类型字符串仅 route_type_from_string 白名单（battle=%d elite=%d shop=%d event=%d boss=%d）"
		% [battle_count, elite_count, shop_count, event_count, boss_count])
	# 状态 match 处无字符串分支（_enter_node 已枚举化）
	_ok(not src.contains("match node_type:") or src.contains("route_type_from_string(node_type)"),
		"§3 _enter_node match 走枚举转换")

# ========== §4 bool 行为标志白名单 ==========

func _part_bool_whitelist() -> void:
	var violations: Array[String] = []
	for f in _all_scripts():
		# 白名单键不带 res:// 前缀（与仓库相对路径一致）
		var allowed: Array = BOOL_WHITELIST.get(f.trim_prefix("res://"), [])
		var src: String = _file(f)
		for ln in src.split("\n"):
			# 仅顶层成员声明（raw 行列首 var 无缩进）——函数内局部变量不在此扫描范围
			# （strip_edges 会误捕函数内 `var is_relic: bool` 等局部声明）
			if not ln.begins_with("var "):
				continue
			if not ln.contains(": bool"):
				continue
			var name: String = ln.substr(4, ln.find(": bool") - 4).strip_edges()
			if not allowed.has(name):
				violations.append("%s:%s" % [f, name])
	_ok(violations.is_empty(), "§4 无新增 bool 行为标志（白名单 26 个外零新增；违规=%s）" % str(violations))

# ========== §5 CODE_STYLE.md ==========

func _part_code_style() -> void:
	if not FileAccess.file_exists("res://docs/CODE_STYLE.md"):
		_fail("§5 CODE_STYLE.md 不存在")
		return
	var md: String = _file("res://docs/CODE_STYLE.md")
	_ok(md.contains("_transition(next:") and md.contains("状态表 Dictionary"),
		"§5 CODE_STYLE.md 含两形态（扁平流程态/行为表现态）")
	_ok(md.contains("禁多 bool") and md.contains("禁字符串状态值") and md.contains("禁 int 字面量状态"),
		"§5 CODE_STYLE.md 含四条禁令关键词")
	_ok(md.contains("能力上限") and md.contains("8") and md.contains("20"),
		"§5 CODE_STYLE.md 含 §8.6 能力上限")

# ========== §6 audio 枚举化 ==========

func _part_audio_enum() -> void:
	var src: String = _file("res://scripts/autoload/audio_manager.gd")
	var has_enum: bool = src.contains("GameManager.GameState.MENU") and src.contains("GameManager.GameState.GAME_OVER") \
		and src.contains("GameManager.GameState.BATTLE")
	_ok(has_enum, "§6 audio match 使用 GameState 枚举（经 Autoload 实例名 GameManager.GameState.X）")
	_ok(src.contains("var state: int = int(gm.current_state)"), "§6 audio 状态读取 int 归一（枚举常量匹配）")
	var int_arm: bool = false
	for ln in _non_comment_lines(src):
		if ln.contains("match state:") or ln.contains("match gm.current_state") or ln.contains("match state_value"):
			pass
		# int 字面量 match 臂：`0:` / `1, 2, 3:` 模式
		var t: String = ln.strip_edges()
		if t.begins_with("0:") or t.begins_with("4:") or t.begins_with("1, 2, 3:"):
			int_arm = true
	_ok(not int_arm, "§6 audio match 无 int 字面量分支")

# ========== 工具 ==========

func _all_scripts() -> Array[String]:
	var out: Array[String] = []
	var dirs := ["res://scripts"]
	for d in dirs:
		_collect_gd(d, out)
	return out

func _collect_gd(dir_path: String, out: Array[String]) -> void:
	var d := DirAccess.open(dir_path)
	if d == null:
		return
	d.list_dir_begin()
	var f: String = d.get_next()
	while f != "":
		if d.current_is_dir():
			if f != "." and f != "..":
				_collect_gd(dir_path + "/" + f, out)
		elif f.ends_with(".gd"):
			out.append(dir_path + "/" + f)
		f = d.get_next()
	d.list_dir_end()

func _ok(cond: bool, label: String) -> void:
	if cond:
		_checked += 1
		print("  PASS  %s" % label)
	else:
		_fail(label)

func _fail(msg: String) -> void:
	_failures += 1
	print("  FAIL  %s" % msg)

func _report() -> void:
	print("=== Day30-F3 合规 result: %d checked, %d failures ===" % [_checked, _failures])
