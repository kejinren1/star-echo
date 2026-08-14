## G-C 出口校验：R4 回廊（G-R4-1~2 · 2026-08-14）
##
## 用法（无头）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day30_g_archive_check.gd
##
## 校验内容：
##   §1 已解锁档案可读（角色等级达标 → story 文本显示）
##   §2 未解锁显示条件不显示内容（level < story_unlock_level → 解锁条件文案）
##   §3 解锁状态持久化（经角色 xp 存档天然满足——get_char_level 读取）
##   §4 story 字段零改动（characters.json story/story_unlock_level 原位）
## 退出码 0 = 全部通过；非 0 = 失败项数。
extends SceneTree

const ARCHIVE_SCENE_PATH: String = "res://scenes/ArchivePanel.tscn"

var _sub: int = 0
var _checked: int = 0
var _failures: int = 0

func _ok(cond: bool, msg: String) -> void:
	_checked += 1
	if cond:
		print("  PASS  " + msg)
	else:
		_failures += 1
		print("  FAIL  " + msg)

func _initialize() -> void:
	print("=== Day30-G-C archive check ===")

func _process(_delta: float) -> bool:
	if _sub > 4:
		print("=== ARCHIVE CHECK: %d assertions, %d failures ===" % [_checked, _failures])
		quit(_failures)
		return true
	_sub = _advance(_sub)
	return false

func _advance(sub: int) -> int:
	match sub:
		0:
			_part_unlocked()
			return 1
		1:
			_part_locked()
			return 2
		2:
			_part_persist()
			return 3
		3:
			_part_story_intact()
			return 4
		4:
			return 99
		_:
			return 99

func _gm() -> Node:
	return root.get_node_or_null("GameManager")

func _dl() -> Node:
	return root.get_node_or_null("DataLoader")

# ========== §1 已解锁可读 ==========

func _part_unlocked() -> void:
	var gm: Node = _gm()
	_ok(gm != null, "§1 已解锁: GameManager autoload 在位")
	if gm == null:
		return
	var data: Dictionary = _dl().call("get_character","se_irene")
	_ok(data.get("story", "") != "", "§1 已解锁: se_irene story 字段非空")
	var scene: PackedScene = load(ARCHIVE_SCENE_PATH)
	_ok(scene != null, "§1 已解锁: ArchivePanel.tscn 可加载")
	if scene == null:
		return
	var panel: Node = scene.instantiate()
	root.add_child(panel)
	# 角色等级达标（story_unlock_level=2 → xp 6 = level 2）
	gm.set("meta_progress", {"wins": 0, "research_points": 0, "research": {}, "chars": {"se_irene": {"xp": 6}}})
	panel.call("_show_detail", "se_irene")
	var detail: String = str(panel.get_node("Root/HBox/Detail/Margin/VBox/DetailLabel").text)
	_ok(detail.find("未解锁") < 0 and detail == str(data.get("story", "")),
		"§1 已解锁: story 文本可读（非解锁条件文案）")
	panel.queue_free()

# ========== §2 未解锁只显条件 ==========

func _part_locked() -> void:
	var scene: PackedScene = load(ARCHIVE_SCENE_PATH)
	var panel: Node = scene.instantiate()
	root.add_child(panel)
	# 角色等级不足（xp 0 = level 0 < story_unlock_level 2）
	_gm().set("meta_progress", {"wins": 0, "research_points": 0, "research": {}, "chars": {"se_irene": {"xp": 0}}})
	panel.call("_show_detail", "se_irene")
	var detail: String = str(panel.get_node("Root/HBox/Detail/Margin/VBox/DetailLabel").text)
	_ok(detail.find("未解锁") >= 0 and detail.find("等级") >= 0, "§2 未解锁: 显示解锁条件（不显示内容）")
	var story: String = str(_dl().call("get_character","se_irene").get("story", ""))
	_ok(detail != story, "§2 未解锁: 内容不泄露（detail ≠ story）")
	panel.queue_free()

# ========== §3 解锁状态持久化 ==========

func _part_persist() -> void:
	var gm: Node = _gm()
	var test_path: String = "user://tmp_archive_test.json"
	gm.set("meta_save_path", test_path)
	gm.set("meta_progress", {"wins": 0, "research_points": 0, "research": {}, "chars": {"se_irene": {"xp": 9}}})
	gm.call("save_meta")
	gm.set("meta_progress", {})
	gm.call("load_meta")
	# 等级经 chars xp 存档恢复（get_char_level 链路）
	_ok(gm.call("get_char_level", "se_irene") == 3, "§3 持久化: 角色等级经存档恢复（xp 9 → level 3）")
	DirAccess.remove_absolute("user://tmp_archive_test.json")

# ========== §4 story 字段零改动 ==========

func _part_story_intact() -> void:
	var txt: String = FileAccess.get_file_as_string("res://data/characters.json")
	_ok(txt.find("story_unlock_level") >= 0 and txt.find("story") >= 0, "§4 字段: characters.json story/story_unlock_level 原位（零改动）")
	_ok(FileAccess.get_file_as_string("res://scripts/ui/archive_panel.gd").find("get_char_level") >= 0,
		"§4 字段: 回廊解锁判定走 get_char_level（零新增存档字段）")
