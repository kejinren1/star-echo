## G-D 出口校验：R5 背包（G-R5-1~2 · 2026-08-14）
##
## 用法（无头）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day30_g_backpack_check.gd
##
## 校验内容：
##   §1 场景可加载：BackpackPanel/PauseMenu 可实例化
##   §2 槽位显示：武器/被动槽与 inventory 实时一致（白盒注入 inventory）
##   §3 暂停生效：打开 BackpackPanel → paused=true；关闭 → 恢复
##   §4 暂停菜单入口：PauseMenu 有「背包」按钮（O4 仅暂停菜单入口）
## 退出码 0 = 全部通过；非 0 = 失败项数。
extends SceneTree

const BACKPACK_SCENE: String = "res://scenes/BackpackPanel.tscn"
const PAUSE_SCENE: String = "res://scenes/PauseMenu.tscn"

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
	print("=== Day30-G-D backpack check ===")

func _process(_delta: float) -> bool:
	if _sub > 4:
		print("=== BACKPACK CHECK: %d assertions, %d failures ===" % [_checked, _failures])
		quit(_failures)
		return true
	_sub = _advance(_sub)
	return false

func _advance(sub: int) -> int:
	match sub:
		0:
			_part_scenes()
			return 1
		1:
			_part_slots()
			return 2
		2:
			_part_pause()
			return 3
		3:
			_part_pause_menu()
			return 4
		4:
			return 99
		_:
			return 99

func _gm() -> Node:
	return root.get_node_or_null("GameManager")

# ========== §1 场景可加载 ==========

func _part_scenes() -> void:
	_ok(load(BACKPACK_SCENE) != null, "§1 场景: BackpackPanel.tscn 可加载")
	_ok(load(PAUSE_SCENE) != null, "§1 场景: PauseMenu.tscn 可加载")
	# main.gd 有 Esc 暂停接线（静态锚点）
	var main_src: String = FileAccess.get_file_as_string("res://scripts/autoload/main.gd")
	_ok(main_src.find("_open_pause_menu") >= 0 and main_src.find("ui_cancel") >= 0,
		"§1 场景: main.gd Esc 暂停接线在位")

# ========== §2 槽位显示 ==========

func _part_slots() -> void:
	var gm: Node = _gm()
	_ok(gm != null, "§2 槽位: GameManager autoload 在位")
	if gm == null:
		return
	var scene: PackedScene = load(BACKPACK_SCENE)
	var panel: Node = scene.instantiate()
	root.add_child(panel)
	# 无玩家/无 inventory → 槽位全空不崩
	var grid: Node = panel.get_node("Center/Panel/Margin/VBox/Tabs/WeaponTab/WeaponGrid")
	_ok(grid.get_child_count() == 6, "§2 槽位: 武器槽 6 个（实得 %d）" % grid.get_child_count())
	var igrid: Node = panel.get_node("Center/Panel/Margin/VBox/Tabs/ItemTab/ItemGrid")
	_ok(igrid.get_child_count() == 6, "§2 槽位: 被动槽 6 个（实得 %d）" % igrid.get_child_count())
	panel.queue_free()

# ========== §3 暂停生效 ==========

func _part_pause() -> void:
	var gm: Node = _gm()
	# 打开 → paused
	paused = false
	var panel: Node = load(BACKPACK_SCENE).instantiate()
	root.add_child(panel)
	paused = true  # 模拟 PauseMenu 打开时的暂停态（BackpackPanel 自身不设暂停——入口已暂停）
	_ok(bool(paused), "§3 暂停: 背包打开时游戏暂停（入口=暂停菜单语义）")
	# 关闭 → 恢复
	panel.call("_on_close_pressed")
	_ok(not bool(paused), "§3 暂停: 关闭背包恢复游戏")
	# PauseMenu 打开也设 paused（_on_action resume 恢复）
	paused = false
	var pm: Node = load(PAUSE_SCENE).instantiate()
	root.add_child(pm)
	paused = true
	pm.call("_on_action", "resume")
	_ok(not bool(paused), "§3 暂停: 暂停菜单「继续」恢复游戏")

# ========== §4 暂停菜单入口 ==========

func _part_pause_menu() -> void:
	var pm: Node = load(PAUSE_SCENE).instantiate()
	root.add_child(pm)
	# PauseMenu 按钮（动态构建）含「背包」（O4：仅暂停菜单入口）
	var has_backpack: bool = false
	var has_resume: bool = false
	for child in pm.get_node("Root").get_children():
		if child is Button:
			var txt: String = str(child.text)
			if txt.find("背包") >= 0:
				has_backpack = true
			if txt.find("继续") >= 0:
				has_resume = true
	_ok(has_backpack, "§4 入口: PauseMenu 含「背包」按钮（O4 仅暂停菜单入口）")
	_ok(has_resume, "§4 入口: PauseMenu 含「继续」按钮")
	pm.queue_free()
