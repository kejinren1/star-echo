## G-C 出口校验：R3 图鉴（G-R3-1~3 · 2026-08-14）
##
## 用法（无头）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day30_g_codex_check.gd
##
## 校验内容：
##   §1 记录接口：白盒注入五分类（weapon/character/enemy/item/event）去重
##   §2 持久化：meta_progress.codex 存档重启保留（save/load 往返）
##   §3 未见条目不泄露名称（CodexPanel 卡片「？？？」）
##   §4 UI 卡片与记录同步（已见显示名称 / 未见占位）
## 退出码 0 = 全部通过；非 0 = 失败项数。
extends SceneTree

const CODEX_SCENE_PATH: String = "res://scenes/CodexPanel.tscn"

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
	print("=== Day30-G-C codex check ===")

func _process(_delta: float) -> bool:
	if _sub > 4:
		print("=== CODEX CHECK: %d assertions, %d failures ===" % [_checked, _failures])
		quit(_failures)
		return true
	_sub = _advance(_sub)
	return false

func _advance(sub: int) -> int:
	match sub:
		0:
			_part_record_api()
			return 1
		1:
			_part_persist()
			return 2
		2:
			_part_placeholder()
			return 3
		3:
			_part_ui_sync()
			return 4
		4:
			return 99
		_:
			return 99

func _gm() -> Node:
	return root.get_node_or_null("GameManager")

# ========== §1 记录接口 ==========

func _part_record_api() -> void:
	var gm: Node = _gm()
	_ok(gm != null, "§1 接口: GameManager autoload 在位")
	if gm == null:
		return
	# 白盒注入五分类
	gm.set("meta_progress", {"wins": 0, "research_points": 0, "research": {}, "chars": {}})
	gm.call("record_codex", "weapon", "pistol")
	gm.call("record_codex", "character", "se_irene")
	gm.call("record_codex", "enemy", "chaser")
	gm.call("record_codex", "item", "iron_ring")
	gm.call("record_codex", "event", "echo_cradle")
	var codex: Dictionary = gm.get("meta_progress").get("codex", {})
	_ok(codex.get("weapon", []).has("pistol"), "§1 接口: weapon 记录")
	_ok(codex.get("character", []).has("se_irene"), "§1 接口: character 记录")
	_ok(codex.get("enemy", []).has("chaser"), "§1 接口: enemy 记录")
	_ok(codex.get("item", []).has("iron_ring"), "§1 接口: item 记录")
	_ok(codex.get("event", []).has("echo_cradle"), "§1 接口: event 记录")
	# 去重：重复记录不叠加
	gm.call("record_codex", "enemy", "chaser")
	_ok(codex.get("enemy", []).size() == 1, "§1 接口: 重复记录去重（enemy 仍 1 条）")

# ========== §2 持久化 ==========

func _part_persist() -> void:
	var gm: Node = _gm()
	var test_path: String = "user://tmp_codex_test.json"
	gm.set("meta_save_path", test_path)
	gm.set("meta_progress", {"wins": 0, "research_points": 0, "research": {}, "chars": {}, "codex": {"weapon": ["pistol"], "enemy": ["chaser"]}})
	gm.call("save_meta")
	gm.set("meta_progress", {})
	gm.call("load_meta")
	var codex: Dictionary = gm.get("meta_progress").get("codex", {})
	_ok(codex.get("weapon", []).has("pistol") and codex.get("enemy", []).has("chaser"),
		"§2 持久化: codex 存档重启保留（save→load 往返）")
	# 旧档无 codex 键 → 零值兼容（load_meta 不崩）
	gm.set("meta_save_path", "user://tmp_codex_old.json")
	DirAccess.remove_absolute("user://tmp_codex_old.json")
	var f := FileAccess.open("user://tmp_codex_old.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"wins": 2, "research_points": 1, "research": {"attack": 1, "hp": 0, "luck": 0}, "chars": {}}))
	f.close()
	gm.call("load_meta")
	_ok(gm.get("meta_progress").get("codex", {}) is Dictionary, "§2 持久化: 旧档无 codex 键 → 零值兼容不崩")
	DirAccess.remove_absolute("user://tmp_codex_test.json")
	DirAccess.remove_absolute("user://tmp_codex_old.json")

# ========== §3 未见条目不泄露名称 ==========

func _part_placeholder() -> void:
	var scene: PackedScene = load(CODEX_SCENE_PATH)
	_ok(scene != null, "§3 占位: CodexPanel.tscn 可加载")
	if scene == null:
		return
	var panel: Node = scene.instantiate()
	root.add_child(panel)
	# 无记录 → 全部「？？？」
	_gm().set("meta_progress", {"wins": 0, "research_points": 0, "research": {}, "chars": {}})
	panel.call("_switch_category", "weapon")
	var all_hidden: bool = true
	for child in panel.get_node("Root/Grid").get_children():
		var txt: String = _collect_labels(child)
		if txt.find("？？？") < 0:
			all_hidden = false
	_ok(all_hidden, "§3 占位: 未见条目不泄露名称（全部「？？？」）")
	panel.queue_free()

# ========== §4 UI 卡片与记录同步 ==========

func _part_ui_sync() -> void:
	var scene: PackedScene = load(CODEX_SCENE_PATH)
	var panel: Node = scene.instantiate()
	root.add_child(panel)
	var gm: Node = _gm()
	# 注入已见 1 条武器
	gm.set("meta_progress", {"wins": 0, "research_points": 0, "research": {}, "chars": {}, "codex": {"weapon": ["pistol"]}})
	panel.call("_switch_category", "weapon")
	var seen_count: int = 0
	var hidden_count: int = 0
	for child in panel.get_node("Root/Grid").get_children():
		var txt: String = _collect_labels(child)
		if txt.find("？？？") >= 0:
			hidden_count += 1
		else:
			seen_count += 1
	_ok(seen_count == 1, "§4 同步: 已见 1 条显示名称（实得 %d）" % seen_count)
	_ok(hidden_count > 0, "§4 同步: 其余条目「？？？」占位（实得 %d）" % hidden_count)
	panel.queue_free()

## 递归收集节点下 Label 文本
func _collect_labels(node: Node) -> String:
	var out: String = ""
	if node is Label:
		out += str(node.text)
	for child in node.get_children():
		out += _collect_labels(child)
	return out
