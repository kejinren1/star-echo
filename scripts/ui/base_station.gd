## 方舟基地（Day 27 · D27-T4：研究系统 + 角色培养 + D27-T5：剧情解锁接线）
## 仿 CharacterSelect 全屏 + LevelUpPanel 动态构建范式；W3 ◐ 占位主题（复用纯色/Label，P1 可延）
extends Control

## 返回角色选择
const CHARACTER_SELECT_SCENE: String = "res://scenes/CharacterSelect.tscn"

## 研究 3 项（key = GameManager research 键；1 级制即达大纲值——攻击 +5% / 生命 +10% / 幸运 +0.05）
const RESEARCH_ITEMS: Array = [
	{"key": "attack", "name": "攻击强化", "desc": "全英雄攻击 +5%"},
	{"key": "hp", "name": "生命强化", "desc": "全英雄生命 +10%"},
	{"key": "luck", "name": "幸运强化", "desc": "全英雄幸运 +0.05"},
]

@onready var _point_label: Label = $Root/PointLabel
@onready var _research_vbox: VBoxContainer = $Root/ResearchSection
@onready var _char_vbox: VBoxContainer = $Root/Scroll/CharRow
@onready var _story_label: Label = $Root/StoryLabel
@onready var _back_button: Button = $Root/BackButton

var _research_status: Dictionary = {}   ## key -> Label（已升级/未升级）
var _research_buttons: Dictionary = {}  ## key -> Button（升级）
var _char_cards: Array[Dictionary] = [] ## [{id, level_label, xp_label, story_btn, sul}]

func _ready() -> void:
	_build_research_section()
	_build_char_section()
	_back_button.pressed.connect(_on_back_pressed)
	_refresh_all()

# ========== 研究区（3 项 · 研究点余量 + 升级按钮） ==========

func _build_research_section() -> void:
	for item in RESEARCH_ITEMS:
		var key: String = str(item["key"])
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		_research_vbox.add_child(row)

		var name_label := Label.new()
		name_label.text = str(item["name"])
		name_label.custom_minimum_size = Vector2(76, 0)
		name_label.add_theme_font_size_override("font_size", 10)
		row.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = str(item["desc"])
		desc_label.add_theme_font_size_override("font_size", 8)
		row.add_child(desc_label)

		var status_label := Label.new()
		status_label.add_theme_font_size_override("font_size", 8)
		row.add_child(status_label)
		_research_status[key] = status_label

		var btn := Button.new()
		btn.text = "升级"
		btn.add_theme_font_size_override("font_size", 8)
		btn.pressed.connect(_on_research_pressed.bind(key))
		row.add_child(btn)
		_research_buttons[key] = btn

# ========== 角色区（D46：DataLoader 全量 10 英雄，非 character_select 的 4 SE 常量） ==========

func _build_char_section() -> void:
	var ids: Array = DataLoader.get_all_character_ids()
	for id in ids:
		var data: Dictionary = DataLoader.get_character(str(id))
		if data.is_empty():
			continue
		var card := _create_char_card(str(id), data)
		_char_vbox.add_child(card)

## 角色卡：名 / 等级 / XP 进度 / 剧情按钮（D47 纯函数判定解锁）
func _create_char_card(id: String, data: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

	var name_label := Label.new()
	name_label.text = str(data.get("name", id))
	name_label.custom_minimum_size = Vector2(120, 0)
	name_label.add_theme_font_size_override("font_size", 9)
	row.add_child(name_label)

	var lv_label := Label.new()
	lv_label.text = "Lv.0"
	lv_label.custom_minimum_size = Vector2(40, 0)
	lv_label.add_theme_font_size_override("font_size", 9)
	row.add_child(lv_label)

	var xp_label := Label.new()
	xp_label.text = "XP 0/3"
	xp_label.custom_minimum_size = Vector2(56, 0)
	xp_label.add_theme_font_size_override("font_size", 8)
	row.add_child(xp_label)

	var story_btn := Button.new()
	story_btn.text = "剧情"
	story_btn.add_theme_font_size_override("font_size", 8)
	story_btn.pressed.connect(_on_story_pressed.bind(id))
	row.add_child(story_btn)

	_char_cards.append({
		"id": id,
		"level_label": lv_label,
		"xp_label": xp_label,
		"story_btn": story_btn,
		"sul": int(data.get("story_unlock_level", 1)),
	})
	return row

# ========== 交互（D27-T5：剧情解锁接线） ==========

## 研究升级：GameManager 消耗 1 点 + 置位 + save_meta（upgrade_research 返回 false 不刷新）
func _on_research_pressed(key: String) -> void:
	if GameManager.upgrade_research(key):
		_refresh_all()

## 剧情按钮：get_char_level >= story_unlock_level 可读 story（D47 纯函数判定，
## 不实例化场景）；不足 → 详情区显示「Lv.N 解锁」提示
func _on_story_pressed(id: String) -> void:
	var data: Dictionary = DataLoader.get_character(id)
	if data.is_empty():
		return
	var story: String = str(data.get("story", ""))
	var sul: int = int(data.get("story_unlock_level", 1))
	var level: int = GameManager.get_char_level(id)
	if level >= sul:
		_story_label.text = "【%s】%s" % [str(data.get("name", id)), story]
	else:
		_story_label.text = "【%s】等级不足（当前 Lv.%d，Lv.%d 解锁）" % [str(data.get("name", id)), level, sul]

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(CHARACTER_SELECT_SCENE)

# ========== 刷新（研究点余量 / 研究项状态 / 角色卡等级·XP·剧情按钮） ==========

func _refresh_all() -> void:
	_point_label.text = "研究点：%d" % int(GameManager.meta_progress.get("research_points", 0))
	var points: int = int(GameManager.meta_progress.get("research_points", 0))
	for key in _research_status:
		var upgraded: bool = int(GameManager.meta_progress.get("research", {}).get(key, 0)) > 0
		(_research_status[key] as Label).text = "已升级" if upgraded else "未升级"
		(_research_buttons[key] as Button).disabled = upgraded or points <= 0
	for card in _char_cards:
		var cid: String = str(card["id"])
		var xp: int = GameManager.get_char_xp(cid)
		var level: int = GameManager.get_char_level(cid)
		(card["level_label"] as Label).text = "Lv.%d" % level
		(card["xp_label"] as Label).text = "XP %d/3" % (xp % 3)
		var story_btn: Button = card["story_btn"]
		var sul: int = int(card["sul"])
		if level >= sul:
			story_btn.disabled = false
			story_btn.tooltip_text = "查看剧情"
		else:
			story_btn.disabled = true
			story_btn.tooltip_text = "Lv.%d 解锁" % sul
