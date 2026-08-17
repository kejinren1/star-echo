## 角色选择界面（《星骸回响》3+1 英雄 · PS 2026-08-17 用户拍板改版）
## 底部 4 头像（不再是一排大卡）；鼠标悬停 → 屏幕正中心预览面板：
## 像素立绘 + 局内像素模型 idle 动画（占位）+ 介绍 + 主动技能 + 起始武器 + 被动/惩罚。
## 立绘通道数据驱动：优先 `<sprite>_portrait_full.png`（未来抠底大立绘，放同名资产即升级），
## 缺失回退 `<sprite>_portrait.png`（128×128 像素立绘），再缺失占位色块。
## 从 DataLoader 按 id 读取英雄并列卡，点击头像选定后携带 hero id 进入 Main.tscn。
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

## 角色素材目录（立绘/动画）
const SPRITE_DIR: String = "res://assets/sprites/characters/"

## 头像尺寸（PS：4 头像横排站得下，视口 640×360）
const AVATAR_SIZE: Vector2 = Vector2(56, 56)
## 预览面板尺寸
const PREVIEW_SIZE: Vector2 = Vector2(560, 232)
## 像素立绘展示尺寸（128×128 放大 1.25 保持像素感）
const PORTRAIT_SHOW_SIZE: Vector2 = Vector2(160, 160)
## 局内模型 idle 动画展示倍率（64px 帧 → 96px 显示）
const IDLE_SCALE: float = 1.5

# ========== 节点引用 ==========

@onready var card_row: HBoxContainer = $Root/CardRow

# ========== 状态 ==========

var _cards: Array[Button] = []
var _preview_panel: Panel = null
var _preview_idle: AnimatedSprite2D = null

# ========== 静态接口 ==========

## 读取已选英雄 id（未选择时返回空串）
static func get_selected_character_id(node: Node) -> String:
	if node == null or not node.is_inside_tree():
		return ""
	return str(node.get_tree().root.get_meta(SELECTION_META, ""))

# ========== 生命周期 ==========

func _ready() -> void:
	_build_preview_panel()
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

# ========== 预览面板（PS 2026-08-17） ==========

## 屏幕正中心预览面板：左立绘 + 局内 idle 动画，右介绍/技能/武器/被动
## 全代码构建（不动 tscn）；初始隐藏，悬停头像时显示
func _build_preview_panel() -> void:
	_preview_panel = Panel.new()
	_preview_panel.custom_minimum_size = PREVIEW_SIZE
	_preview_panel.set_anchors_preset(Control.PRESET_CENTER)
	_preview_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_preview_panel.visible = false
	add_child(_preview_panel)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 12.0
	hbox.offset_top = 12.0
	hbox.offset_right = -12.0
	hbox.offset_bottom = -12.0
	hbox.add_theme_constant_override("separation", 14)
	_preview_panel.add_child(hbox)

	# 左列：立绘 + 局内 idle 动画
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(170, 0)
	left.add_theme_constant_override("separation", 6)
	hbox.add_child(left)

	var portrait := TextureRect.new()
	portrait.custom_minimum_size = PORTRAIT_SHOW_SIZE
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	portrait.set_meta(&"probe_portrait", portrait)
	left.add_child(portrait)

	var idle_holder := Control.new()
	idle_holder.custom_minimum_size = Vector2(96, 72)
	idle_holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	left.add_child(idle_holder)
	_preview_idle = AnimatedSprite2D.new()
	_preview_idle.position = Vector2(48, 36)
	idle_holder.add_child(_preview_idle)

	# 右列：文字信息
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 3)
	hbox.add_child(right)

	for spec in [
		{"key": &"name_line", "size": 14, "color": Color(1.0, 0.9, 0.6)},
		{"key": &"class_line", "size": 9, "color": Color(0.75, 0.8, 0.9)},
		{"key": &"desc_line", "size": 8, "color": Color(0.85, 0.87, 0.9)},
		{"key": &"skill_line", "size": 8, "color": Color(0.7, 0.85, 1.0)},
		{"key": &"weapon_line", "size": 8, "color": Color(0.8, 0.8, 0.7)},
		{"key": &"growth_line", "size": 8, "color": Color(0.75, 0.9, 0.75)},
	]:
		var lbl := Label.new()
		lbl.set_meta(&"preview_line", spec["key"])
		lbl.add_theme_font_size_override("font_size", spec["size"])
		lbl.add_theme_color_override("font_color", spec["color"])
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL if spec["key"] == &"desc_line" else 0
		right.add_child(lbl)

## 悬停头像 → 填充预览面板并居中显示
func _show_preview(hero_id: String) -> void:
	if _preview_panel == null:
		return
	var data: Dictionary = DataLoader.get_character(hero_id)
	if data.is_empty():
		_preview_panel.visible = false
		return
	# 立绘（full 优先 → 像素立绘回退 → 占位）
	var portrait_rect: TextureRect = null
	var name_label: Label = null
	var class_label: Label = null
	var desc_label: Label = null
	var skill_label: Label = null
	var weapon_label: Label = null
	var growth_label: Label = null
	for child in _preview_panel.get_children():
		if child is HBoxContainer:
			for col in child.get_children():
				if col is VBoxContainer:
					for node in col.get_children():
						if node is TextureRect:
							portrait_rect = node
						elif node is Label and node.has_meta(&"preview_line"):
							match node.get_meta(&"preview_line"):
								&"name_line": name_label = node
								&"class_line": class_label = node
								&"desc_line": desc_label = node
								&"skill_line": skill_label = node
								&"weapon_line": weapon_label = node
								&"growth_line": growth_label = node
	if portrait_rect:
		var tex := _load_portrait(hero_id, data)
		portrait_rect.texture = tex
	# 局内 idle 动画（64px 帧 sheet → AnimatedSprite2D；缺资产隐藏）
	_load_idle(hero_id, data)
	# 文字
	if name_label:
		name_label.text = "%s  %s" % [str(data.get("name", "")), str(data.get("name_en", ""))]
	if class_label:
		class_label.text = "定位: %s" % str(data.get("class", "-"))
	if desc_label:
		desc_label.text = str(data.get("description", ""))
	if skill_label:
		skill_label.text = _describe_skill(data)
	if weapon_label:
		weapon_label.text = _describe_weapon(data)
	if growth_label:
		growth_label.text = _describe_growth(data)
	_preview_panel.visible = true

## 加载 idle 动画：正方形帧约定（帧尺寸 = sheet 高，帧数 = 宽÷高，同 player_anim）
func _load_idle(hero_id: String, data: Dictionary) -> void:
	var prefix: String = str(data.get("sprite", ""))
	var path: String = ""
	if not prefix.is_empty():
		path = "%s%s_idle.png" % [SPRITE_DIR, prefix]
	if path.is_empty() or not ResourceLoader.exists(path):
		path = "%s%s_idle.png" % [SPRITE_DIR, hero_id]
	if not ResourceLoader.exists(path):
		if _preview_idle:
			_preview_idle.visible = false
		return
	var tex := ResourceLoader.load(path) as Texture2D
	if tex == null:
		if _preview_idle:
			_preview_idle.visible = false
		return
	var fh: int = tex.get_height()
	var count: int = maxi(1, tex.get_width() / fh)
	var sf := SpriteFrameFactory.create_from_sheet(tex, count, Vector2i(fh, fh), 8.0, true, "idle")
	_preview_idle.sprite_frames = sf
	_preview_idle.scale = Vector2(IDLE_SCALE, IDLE_SCALE)
	_preview_idle.visible = true
	_preview_idle.play("idle")

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
		# G-C（R3 图鉴）：角色可见即记录（选角页加载批量；去重零开销）
		GameManager.record_codex("character", hero_id)
		var card := _create_avatar(hero_id, data)
		card_row.add_child(card)
		_cards.append(card)

	if _cards.is_empty():
		return

	_cards[0].grab_focus()
	_show_preview(str(_cards[0].get_meta("character_id")))

## 生成一个头像按钮（PS：小头像 + 名字，悬停预览，点击出战）
func _create_avatar(hero_id: String, data: Dictionary) -> Button:
	var card := Button.new()
	card.custom_minimum_size = AVATAR_SIZE
	card.focus_mode = Control.FOCUS_ALL
	card.set_meta("character_id", hero_id)
	card.tooltip_text = str(data.get("name", hero_id))
	# 头像底：小立绘缩略（像素立绘缩到 48×48 居中）
	var tex := _load_portrait(hero_id, data)
	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 3.0
	vbox.offset_top = 3.0
	vbox.offset_right = -3.0
	vbox.offset_bottom = -3.0
	vbox.add_theme_constant_override("separation", 1)
	card.add_child(vbox)
	if tex != null:
		var pv := TextureRect.new()
		pv.texture = tex
		pv.custom_minimum_size = Vector2(48, 42)
		pv.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pv.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pv.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vbox.add_child(pv)
	else:
		var ph := ColorRect.new()
		ph.custom_minimum_size = Vector2(48, 42)
		ph.color = Color(0.18, 0.20, 0.30, 1.0)
		ph.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vbox.add_child(ph)
	var name_cn := Label.new()
	name_cn.text = str(data.get("name", ""))
	name_cn.add_theme_font_size_override("font_size", 7)
	name_cn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_cn)

	card.focus_entered.connect(_on_card_focused.bind(hero_id))
	card.mouse_entered.connect(_on_card_focused.bind(hero_id))
	card.mouse_exited.connect(_on_card_mouse_exited)
	card.pressed.connect(_on_card_pressed.bind(hero_id))
	return card

# ========== 立绘 ==========

## 按候选路径查找立绘，全部缺失返回 null
## 主路径 = characters.json 的 `sprite` 前缀；PS：full 大立绘优先（放同名资产即升级），
## 像素立绘回退；Day 2 起硬编码 PORTRAIT_ALIAS 已收敛进数据层
func _load_portrait(hero_id: String, data: Dictionary) -> Texture2D:
	var candidates: Array[String] = []
	var prefix: String = str(data.get("sprite", ""))
	if not prefix.is_empty():
		candidates.append("%s%s_portrait_full.png" % [SPRITE_DIR, prefix])
		candidates.append("%s%s_portrait.png" % [SPRITE_DIR, prefix])
		candidates.append("%s%s_idle.png" % [SPRITE_DIR, prefix])
	# 数据未配 sprite 时，最后按 id 同名资产兜底
	candidates.append("%s%s_portrait.png" % [SPRITE_DIR, hero_id])

	for path in candidates:
		if ResourceLoader.exists(path):
			var res := ResourceLoader.load(path)
			if res is Texture2D:
				return res as Texture2D
	return null

# ========== 描述 ==========

## 主动技能行
func _describe_skill(data: Dictionary) -> String:
	var skill: Dictionary = data.get("skill", {})
	if skill.is_empty():
		return ""
	var cd: float = float(skill.get("cooldown", 0.0))
	var type: String = str(skill.get("type", ""))
	return "主动技能: %s（%s） CD %.1fs  %s" % [
		str(skill.get("name", "")),
		str(skill.get("name_en", "")),
		cd,
		str(skill.get("description", "")),
	]

## 起始武器行
func _describe_weapon(data: Dictionary) -> String:
	var wid: String = str(data.get("starting_weapon", "-"))
	var wdata: Dictionary = DataLoader.get_weapon(wid) if DataLoader else {}
	var wname: String = str(wdata.get("name", wid))
	var wdmg: float = float(wdata.get("damage", 0.0))
	var wcd: float = float(wdata.get("cooldown", 0.0))
	var special: String = str(wdata.get("special", ""))
	return "起始武器: %s（伤害 %d · 冷却 %.2fs）%s" % [wname, int(wdmg), wcd, special]

## 被动/成长行
func _describe_growth(data: Dictionary) -> String:
	var passive: Dictionary = data.get("passive", {})
	var parts: Array[String] = []
	if float(passive.get("melee_damage", 0.0)) != 0.0:
		parts.append("近战伤害 +%d%%" % int(passive.get("melee_damage", 0.0)))
	if float(passive.get("crit_chance_percent", 0.0)) != 0.0:
		parts.append("暴击率 +%d%%" % int(passive.get("crit_chance_percent", 0.0)))
	if float(passive.get("life_steal_percent", 0.0)) != 0.0:
		parts.append("生命偷取 +%d%%" % int(passive.get("life_steal_percent", 0.0)))
	var penalty: Dictionary = data.get("penalty", {})
	if float(penalty.get("ranged_damage_percent", 0.0)) != 0.0:
		parts.append("远程伤害 %d%%" % int(penalty.get("ranged_damage_percent", 0.0)))
	var growth: Dictionary = data.get("growth", {})
	var growth_desc: String = str(growth.get("description", ""))
	if parts.is_empty():
		return "成长: %s" % growth_desc
	return "被动: %s   成长: %s" % [" · ".join(parts), growth_desc]

# ========== 输入回调 ==========

func _on_card_focused(hero_id: String) -> void:
	_show_preview(hero_id)

func _on_card_mouse_exited() -> void:
	# 仅当鼠标未落在其它头像上时隐藏（focus 状态保留预览）
	if not _preview_panel:
		return
	# 延迟隐藏：鼠标移动到其它头像会先触发 mouse_entered 重新显示，
	# 直接隐藏会导致闪烁 —— 用 get_viewport 检查当前悬停控件
	var hovered: Control = get_viewport().gui_get_hovered_control()
	if hovered == null or hovered.get_meta("character_id", "") == "":
		_preview_panel.visible = false

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
