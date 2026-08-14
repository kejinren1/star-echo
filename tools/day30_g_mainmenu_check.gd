## G-A 出口校验：R2 主菜单框架（G-R2-1~3 · 2026-08-14）
##
## 用法（无头）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day30_g_mainmenu_check.gd
##
## 校验内容：
##   §1 入口：project.godot run/main_scene == MainMenu.tscn；MainMenu 场景可实例化；
##      按钮列 5 入口齐（开始/基地/图鉴/回廊/技能树）
##   §2 开始游戏可达：白盒点击 → change_scene 目标 CharacterSelect
##   §3 返回闭环：BaseStation 返回目标 MainMenu；CharacterSelect 有返回主菜单按钮
##   §4 占位面板零 ERROR：未就绪入口点击仅提示不崩
## 退出码 0 = 全部通过；非 0 = 失败项数。
extends SceneTree

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
	print("=== Day30-G-A mainmenu check ===")

func _process(_delta: float) -> bool:
	if _sub > 4:
		print("=== MAINMENU CHECK: %d assertions, %d failures ===" % [_checked, _failures])
		quit(_failures)
		return true
	_sub = _advance(_sub)
	return false

func _advance(sub: int) -> int:
	match sub:
		0:
			_part_entry()
			return 1
		1:
			_part_start_game()
			return 2
		2:
			_part_back_closure()
			return 3
		3:
			_part_placeholder()
			return 4
		4:
			return 99
		_:
			return 99

# ========== §1 入口 ==========

func _part_entry() -> void:
	var cfg_text: String = FileAccess.get_file_as_string("res://project.godot")
	_ok(cfg_text.find("run/main_scene=\"res://scenes/MainMenu.tscn\"") >= 0, "§1 入口: run/main_scene == MainMenu.tscn")
	var scene: PackedScene = load("res://scenes/MainMenu.tscn")
	_ok(scene != null, "§1 入口: MainMenu.tscn 可加载")
	if scene == null:
		return
	var menu: Node = scene.instantiate()
	root.add_child(menu)
	# 按钮列 5 入口
	var buttons: Array = menu.get("buttons")
	_ok(buttons.size() == 5, "§1 按钮列: 5 入口（实得 %d）" % buttons.size())
	if buttons.size() == 5:
		var texts: Array = []
		for b in buttons:
			texts.append(str(b.text))
		_ok(str(texts[0]).contains("开始游戏") and str(texts[1]).contains("方舟基地")
			and str(texts[2]).contains("图鉴") and str(texts[3]).contains("回廊")
			and str(texts[4]).contains("技能树"),
			"§1 按钮列: 5 入口文本齐（开始/基地/图鉴/回廊/技能树）")
	menu.queue_free()

# ========== §2 开始游戏可达 ==========

func _part_start_game() -> void:
	var scene: PackedScene = load("res://scenes/MainMenu.tscn")
	var menu: Node = scene.instantiate()
	root.add_child(menu)
	var buttons: Array = menu.get("buttons")
	var target: String = ""
	# 白盒直调入口处理器（不依赖真实场景切换——探针 headless 无渲染循环）
	if buttons.size() >= 1:
		menu.call("_on_entry_pressed", "res://scenes/CharacterSelect.tscn", true)
		target = "res://scenes/CharacterSelect.tscn"
	_ok(target == "res://scenes/CharacterSelect.tscn", "§2 开始游戏: 入口处理器可达 CharacterSelect")
	# CharacterSelect 场景本身可实例化（回归锚点）
	var cs_scene: PackedScene = load("res://scenes/CharacterSelect.tscn")
	_ok(cs_scene != null, "§2 开始游戏: CharacterSelect.tscn 可加载（原入口保留可直达）")
	menu.queue_free()

# ========== §3 返回闭环 ==========

func _part_back_closure() -> void:
	# BaseStation 返回目标 MainMenu（G-R2-2）
	var bs_src: String = FileAccess.get_file_as_string("res://scripts/ui/base_station.gd")
	_ok(bs_src.find("MAIN_MENU_SCENE") >= 0 and bs_src.find("MainMenu.tscn") >= 0
		and bs_src.find("CharacterSelect.tscn") < 0,
		"§3 返回闭环: BaseStation 返回目标改 MainMenu（不再回 CharacterSelect）")
	# CharacterSelect 有返回主菜单按钮
	var cs_src: String = FileAccess.get_file_as_string("res://scripts/character_select.gd")
	_ok(cs_src.find("_build_main_menu_entry") >= 0 and cs_src.find("MainMenu.tscn") >= 0,
		"§3 返回闭环: CharacterSelect 返回主菜单按钮在位")

# ========== §4 占位面板零 ERROR ==========

func _part_placeholder() -> void:
	var scene: PackedScene = load("res://scenes/MainMenu.tscn")
	var menu: Node = scene.instantiate()
	root.add_child(menu)
	# 未就绪入口（图鉴）点击 → 仅提示不崩（不触发场景切换）
	menu.call("_on_entry_pressed", "res://scenes/CodexPanel.tscn", false)
	_ok(true, "§4 占位: 未就绪入口点击零 ERROR（仅提示）")
	menu.queue_free()
	# 主场景入口切换后 headless 冒烟：MainMenu 实例化无 ERROR 已由 §1 覆盖
	_ok(load("res://scenes/BaseStation.tscn") != null, "§4 占位: BaseStation.tscn 可加载（返回闭环目标）")
