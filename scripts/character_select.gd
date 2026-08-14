## 角色选择界面（《星骸回响》3 英雄）
## 从 DataLoader 按 id 读取 Star Echo 英雄并列卡，玩家选定后携带 hero id 进入 Main.tscn。
## 约定：不写入任何现有脚本/Autoload —— 选择结果挂在场景树根节点的 meta 上，
##       跨场景存活；后续 Main/Player 用 CharacterSelect.get_selected_character_id(self) 读取。
class_name CharacterSelect
extends Control

# ========== 信号 ==========

signal character_chosen(character_id: String)

# ========== 配置 ==========

## F1-F（T-025）：英雄列表单一事实源 = DataLoader 全量角色过滤 SE 前缀
## （先例 base_station.gd；数据侧新增 SE 英雄自动上架，DataLoader 缺失时兜底 4 SE 防冷启动崩）
const HERO_ID_PREFIX: String = "se_"
const HERO_ID_FALLBACK: Array[String] = ["se_irene", "se_noa", "se_ren", "se_siia"]

## 选择结果存放的 meta key（挂在 get_tree().root 上）
const SELECTION_META: StringName = &"se_selected_character"

## 战斗主场景
const MAIN_SCENE_PATH: String = "res://scenes/Main.tscn"

## 立绘目录（仅用于 id 同名资产的最后兜底，主路径走 characters.json 的 sprite 字段）
const PORTRAIT_DIR: String = "res://assets/sprites/characters/"

const CARD_SIZE: Vector2 = Vector2(180, 176)
const PORTRAIT_SIZE: Vector2 = Vector2(64, 64)

# ========== 节点引用 ==========

@onready var card_row: HBoxContainer = $Root/CardRow
@onready var detail_label: Label = $Root/DetailLabel

# ========== 状态 ==========

var _cards: Array[Button] = []

# ========== 静态接口 ==========

## 读取已选英雄 id（未选择时返回空串）
static func get_selected_character_id(node: Node) -> String:
	if node == null or not node.is_inside_tree():
		return ""
	return str(node.get_tree().root.get_meta(SELECTION_META, ""))

# ========== 生命周期 ==========

func _ready() -> void:
	_build_cards()
	_build_base_station_entry()
	_build_main_menu_entry()

## D27-T4：方舟基地入口按钮（动态创建加 $Root/，不改 tscn）
func _build_base_station_entry() -> void:
	var base_btn := Button.new()
	base_btn.text = "🏛 方舟基地"
	base_btn.add_theme_font_size_override("font_size", 10)
	base_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	base_btn.pressed.connect(_on_base_station_pressed)
	$Root.add_child(base_btn)

func _on_base_station_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/BaseStation.tscn")

## G-A（2026-08-14）：返回主菜单按钮（主场景入口已改 MainMenu，选角页补返回）
func _build_main_menu_entry() -> void:
	var mm_btn := Button.new()
	mm_btn.text = "← 返回主菜单"
	mm_btn.add_theme_font_size_override("font_size", 10)
	mm_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mm_btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	$Root.add_child(mm_btn)

# ========== 卡片构建 ==========

## F1-F（T-025）：英雄 id 列表 = DataLoader 全量角色过滤 SE 前缀（数据侧单一事实源）
func _get_hero_ids() -> Array[String]:
	var ids: Array[String] = []
	if DataLoader:
		for cid in DataLoader.get_all_character_ids():
			if str(cid).begins_with(HERO_ID_PREFIX):
				ids.append(str(cid))
	if ids.is_empty():
		ids = HERO_ID_FALLBACK
	return ids

func _build_cards() -> void:
	for child in card_row.get_children():
		child.queue_free()
	_cards.clear()

	for hero_id in _get_hero_ids():
		var data: Dictionary = DataLoader.get_character(hero_id)
		if data.is_empty():
			push_warning("[CharacterSelect] characters.json 缺少英雄: %s" % hero_id)
			continue
		var card := _create_card(hero_id, data)
		card_row.add_child(card)
		_cards.append(card)

	if _cards.is_empty():
		detail_label.text = "No Star Echo hero found in data/characters.json"
		return

	_cards[0].grab_focus()

## 生成一张英雄卡片
func _create_card(hero_id: String, data: Dictionary) -> Button:
	var card := Button.new()
	card.custom_minimum_size = CARD_SIZE
	card.focus_mode = Control.FOCUS_ALL
	card.set_meta("character_id", hero_id)
	card.tooltip_text = str(data.get("name", hero_id))

	# 内容层（不吃鼠标事件，点击透传给 Button）
	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 6.0
	vbox.offset_top = 6.0
	vbox.offset_right = -6.0
	vbox.offset_bottom = -6.0
	vbox.add_theme_constant_override("separation", 3)
	card.add_child(vbox)

	# 立绘（缺资产时用占位色块）
	vbox.add_child(_create_portrait(hero_id, data))

	# 英文名（默认字体无 CJK 字形，英文名保证可读）
	var name_en := Label.new()
	name_en.text = str(data.get("name_en", hero_id))
	name_en.add_theme_font_size_override("font_size", 10)
	name_en.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_en.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(name_en)

	# 中文名
	var name_cn := Label.new()
	name_cn.text = str(data.get("name", ""))
	name_cn.add_theme_font_size_override("font_size", 8)
	name_cn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_cn)

	# 定位 + id
	var class_label := Label.new()
	class_label.text = "%s · %s" % [str(data.get("class", "-")), hero_id]
	class_label.add_theme_font_size_override("font_size", 7)
	class_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(class_label)

	card.focus_entered.connect(_on_card_focused.bind(hero_id))
	card.mouse_entered.connect(_on_card_focused.bind(hero_id))
	card.pressed.connect(_on_card_pressed.bind(hero_id))
	return card

# ========== 立绘 ==========

## 生成立绘节点：有资产用 TextureRect，无资产用占位 ColorRect
func _create_portrait(hero_id: String, data: Dictionary) -> Control:
	var tex := _load_portrait(hero_id, data)
	if tex != null:
		var portrait := TextureRect.new()
		portrait.texture = tex
		portrait.custom_minimum_size = PORTRAIT_SIZE
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		return portrait

	var placeholder := ColorRect.new()
	placeholder.custom_minimum_size = PORTRAIT_SIZE
	placeholder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	placeholder.color = Color(0.18, 0.20, 0.30, 1.0)
	return placeholder

## 按候选路径查找立绘，全部缺失返回 null
## 主路径 = characters.json 的 `sprite` 前缀（Day 2 起硬编码 PORTRAIT_ALIAS 已收敛进数据层）
func _load_portrait(hero_id: String, data: Dictionary) -> Texture2D:
	var candidates: Array[String] = []
	var prefix: String = str(data.get("sprite", ""))
	if not prefix.is_empty():
		candidates.append("%s%s_portrait.png" % [PORTRAIT_DIR, prefix])
		candidates.append("%s%s_idle.png" % [PORTRAIT_DIR, prefix])
	# 数据未配 sprite 时，最后按 id 同名资产兜底
	candidates.append("%s%s_portrait.png" % [PORTRAIT_DIR, hero_id])

	for path in candidates:
		if ResourceLoader.exists(path):
			var res := ResourceLoader.load(path)
			if res is Texture2D:
				return res as Texture2D
	return null

# ========== 详情 ==========

## 组装底部详情文本
func _describe(data: Dictionary) -> String:
	var lines: Array[String] = []
	var desc: String = str(data.get("description", ""))
	if desc != "":
		lines.append(desc)

	var skill: Dictionary = data.get("skill", {})
	if not skill.is_empty():
		lines.append("SKILL %s / %s  ·  CD %.1fs" % [
			str(skill.get("name_en", "")),
			str(skill.get("name", "")),
			float(skill.get("cooldown", 0.0)),
		])

	lines.append("WEAPON  %s" % str(data.get("starting_weapon", "-")))
	return "\n".join(lines)

# ========== 输入回调 ==========

func _on_card_focused(hero_id: String) -> void:
	detail_label.text = _describe(DataLoader.get_character(hero_id))

func _on_card_pressed(hero_id: String) -> void:
	select_character(hero_id)

# ========== 选择 ==========

## 选定英雄并进入战斗主场景
func select_character(hero_id: String) -> void:
	if DataLoader.get_character(hero_id).is_empty():
		push_error("[CharacterSelect] 未知英雄 id: %s" % hero_id)
		return

	get_tree().root.set_meta(SELECTION_META, hero_id)
	character_chosen.emit(hero_id)

	var err := get_tree().change_scene_to_file(MAIN_SCENE_PATH)
	if err != OK:
		push_error("[CharacterSelect] 切换场景失败 %s (错误码 %d)" % [MAIN_SCENE_PATH, err])
