## 暂停菜单（G-D · 2026-08-14 · R5 背包入口 O4）
## Esc 打开（main._unhandled_input）；paused=true 期间可交互（WHEN_PAUSED）；
## 按钮：继续 / 背包（→BackpackPanel）/ 返回主菜单
extends CanvasLayer

const BACKPACK_SCENE: String = "res://scenes/BackpackPanel.tscn"
const MAIN_MENU_SCENE: String = "res://scenes/MainMenu.tscn"

func _ready() -> void:
	_build_buttons()

func _build_buttons() -> void:
	var root := get_node_or_null("Root")
	if root == null:
		return
	var entries: Array = [
		{"text": "▶ 继续", "action": "resume"},
		{"text": "🎒 背包", "action": "backpack"},
		{"text": "🏠 返回主菜单", "action": "main_menu"},
	]
	for e in entries:
		var btn := Button.new()
		btn.text = str(e["text"])
		btn.custom_minimum_size = Vector2(160, 34)
		btn.add_theme_font_size_override("font_size", 12)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.pressed.connect(_on_action.bind(str(e["action"])))
		root.add_child(btn)

func _on_action(action: String) -> void:
	match action:
		"resume":
			get_tree().paused = false
			queue_free()
		"backpack":
			# 打开背包（保持暂停；BackpackPanel 关闭时恢复）
			var panel: Node = load(BACKPACK_SCENE).instantiate()
			get_tree().current_scene.add_child(panel)
			queue_free()
		"main_menu":
			get_tree().paused = false
			get_tree().change_scene_to_file(MAIN_MENU_SCENE)
			queue_free()
