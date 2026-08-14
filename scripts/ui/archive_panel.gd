## 回廊面板（G-C · 2026-08-14 · R4 角色档案，从简 O6）
## 角色列表（色块占位）→ 选中显示 characters.json story 文本；
## 解锁判定 = 角色等级达标（get_char_level >= story_unlock_level，D27 链路，零新增存档字段）；
## 未解锁角色显示解锁条件不显示内容
extends Control

const MAIN_MENU_SCENE: String = "res://scenes/MainMenu.tscn"

var _character_buttons: Array[Button] = []
var _char_ids: Array[String] = []

@onready var list_box: VBoxContainer = $Root/HBox/List
@onready var detail_panel: PanelContainer = $Root/HBox/Detail
@onready var detail_label: Label = $Root/HBox/Detail/Margin/VBox/DetailLabel
@onready var name_label: Label = $Root/HBox/Detail/Margin/VBox/NameLabel

func _ready() -> void:
	# 返回主菜单
	var back_btn := Button.new()
	back_btn.text = "← 返回主菜单"
	back_btn.add_theme_font_size_override("font_size", 10)
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)
	)
	$Root.add_child(back_btn)
	_build_list()

func _build_list() -> void:
	_char_ids.clear()
	if DataLoader:
		for cid in DataLoader.get_all_character_ids():
			_char_ids.append(str(cid))
	for cid in _char_ids:
		var btn := Button.new()
		btn.text = cid
		btn.add_theme_font_size_override("font_size", 10)
		btn.custom_minimum_size = Vector2(120, 26)
		btn.pressed.connect(_show_detail.bind(cid))
		list_box.add_child(btn)
		_character_buttons.append(btn)

## 显示角色档案：已解锁 → story；未解锁 → 解锁条件
func _show_detail(cid: String) -> void:
	var data: Dictionary = DataLoader.get_character(cid) if DataLoader else {}
	if data.is_empty():
		detail_label.text = "（数据缺失）"
		return
	var unlock_level: int = int(data.get("story_unlock_level", 1))
	var level: int = GameManager.get_char_level(cid) if GameManager else 0
	name_label.text = str(data.get("name", cid))
	if level >= unlock_level:
		detail_label.text = str(data.get("story", "（暂无档案）"))
	else:
		detail_label.text = "（未解锁 · 角色等级 %d 解锁）" % unlock_level
