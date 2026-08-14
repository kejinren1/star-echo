## 图鉴面板（G-C · 2026-08-14 · R3 收集系统）
## 分类标签（武器/角色/敌人/道具/事件）→ 网格卡片（色块+名称）；
## 未见条目显示「？？？」占位不泄露名称（meta_progress.codex 记录已见 id）
extends Control

const MAIN_MENU_SCENE: String = "res://scenes/MainMenu.tscn"

## 分类定义：label / DataLoader 全量 id 接口 / codex 键
const CATEGORIES: Array = [
	{"label": "武器", "key": "weapon", "ids": "get_all_weapon_ids"},
	{"label": "角色", "key": "character", "ids": "get_all_character_ids"},
	{"label": "敌人", "key": "enemy", "ids": "get_all_enemy_ids"},
	{"label": "道具", "key": "item", "ids": "get_all_item_ids"},
	{"label": "事件", "key": "event", "ids": "get_events"},
]

var _current_key: String = "weapon"
var _tab_buttons: Array[Button] = []

@onready var grid: GridContainer = $Root/Grid
@onready var tab_row: HBoxContainer = $Root/Tabs

func _ready() -> void:
	_build_tabs()
	# 返回主菜单
	var back_btn := Button.new()
	back_btn.text = "← 返回主菜单"
	back_btn.add_theme_font_size_override("font_size", 10)
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)
	)
	$Root.add_child(back_btn)
	_switch_category("weapon")

func _build_tabs() -> void:
	for cat in CATEGORIES:
		var btn := Button.new()
		btn.text = str(cat["label"])
		btn.add_theme_font_size_override("font_size", 10)
		btn.pressed.connect(_switch_category.bind(str(cat["key"])))
		tab_row.add_child(btn)
		_tab_buttons.append(btn)

func _switch_category(key: String) -> void:
	_current_key = key
	for child in grid.get_children():
		child.queue_free()
	var codex: Dictionary = GameManager.get_codex() if GameManager else {}
	var seen: Array = codex.get(key, [])
	var cat: Dictionary = {}
	for c in CATEGORIES:
		if str(c["key"]) == key:
			cat = c
			break
	var ids: Array = []
	if cat.has("ids"):
		var method: String = str(cat["ids"])
		ids = DataLoader.call(method) if DataLoader else []
	# 事件分类：get_events 返回数组 → 取 id 列表
	if key == "event":
		var event_ids: Array = []
		for ev in ids:
			event_ids.append(str(ev.get("id", "")))
		ids = event_ids
	for cid in ids:
		var cid_s: String = str(cid)
		var card := _make_card(cid_s, seen.has(cid_s))
		grid.add_child(card)

## 卡片：色块 + 名称（未见 = 「？？？」不泄露名称）
func _make_card(id: String, is_seen: bool) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(96, 26)
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	var rect := ColorRect.new()
	rect.custom_minimum_size = Vector2(12, 12)
	rect.color = Color(0.6, 0.6, 0.65) if is_seen else Color(0.3, 0.3, 0.32)
	box.add_child(rect)
	var label := Label.new()
	if is_seen:
		label.text = _display_name(id)
	else:
		label.text = "？？？"
	label.add_theme_font_size_override("font_size", 9)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	box.add_child(label)
	panel.add_child(box)
	return panel

## 已见条目名称（DataLoader 数据；武器/角色/道具/敌人 name，事件 title）
func _display_name(id: String) -> String:
	var name: String = id
	if DataLoader:
		match _current_key:
			"weapon":
				name = str(DataLoader.get_weapon(id).get("name", id))
			"character":
				name = str(DataLoader.get_character(id).get("name", id))
			"enemy":
				name = str(DataLoader.get_enemy(id).get("name", id))
			"item":
				name = str(DataLoader.get_item(id).get("name", id))
			"event":
				var evs: Array = DataLoader.get_events() if DataLoader else []
				for ev in evs:
					if str(ev.get("id", "")) == id:
						name = str(ev.get("title", id))
						break
	return name
