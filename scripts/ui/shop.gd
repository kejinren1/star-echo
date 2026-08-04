## 商店界面脚本
## 波次间购买武器和道具
## 使用 NinePatchRect 面板 + IconAtlas 图标
extends CanvasLayer

# ========== 信号 ==========

signal purchase_made(item: Resource)
signal shop_exited

# ========== 节点引用 ==========

@onready var item_container: VBoxContainer = $ShopPanel/Margin/VBox/ItemContainer
@onready var reroll_button: TextureButton = $ShopPanel/Margin/VBox/BottomBar/RerollButton
@onready var continue_button: TextureButton = $ShopPanel/Margin/VBox/BottomBar/ContinueButton
@onready var coins_label: Label = $ShopPanel/Margin/VBox/TopBar/CoinsLabel

# ========== 配置 ==========

const SHOP_ITEM_COUNT: int = 4                  ## 商店刷新物品数
const REROLL_COST: int = 10                     ## 刷新费用
const CARD_HEIGHT: int = 36                     ## 卡片高度
const CARD_PATCH_MARGIN: int = 12               ## 卡片 9-slice 边距

## 卡片面板纹理
const CARD_TEXTURE: Texture2D = preload("res://assets/sprites/ui/panel_card.png")

var shop_items: Array[Resource] = []            ## 当前商店商品

# ========== 生命周期 ==========

func _ready() -> void:
	visible = false
	GameManager.shop_opened.connect(_on_shop_opened)
	GameManager.shop_closed.connect(_on_shop_closed)
	continue_button.pressed.connect(_on_continue_pressed)
	reroll_button.pressed.connect(_on_reroll_pressed)

	if GameManager.economy:
		GameManager.economy.coins_changed.connect(_on_coins_changed)

# ========== 商店流程 ==========

func _on_shop_opened() -> void:
	visible = true
	_refresh_shop()

func _on_shop_closed() -> void:
	visible = false

func _on_continue_pressed() -> void:
	shop_exited.emit()
	GameManager.close_shop()

func _on_reroll_pressed() -> void:
	if GameManager.economy and GameManager.economy.spend_coins(REROLL_COST):
		_refresh_shop()

# ========== 商品生成 ==========

## 刷新商店商品（骨架：后续从数据表加载）
func _refresh_shop() -> void:
	shop_items.clear()
	for child in item_container.get_children():
		child.queue_free()

	# TODO: 从 data/items/ 加载随机道具和武器
	# 目前创建 4 个占位卡片
	for i in SHOP_ITEM_COUNT:
		var card := _create_card(null, i)
		item_container.add_child(card)

	# 更新金币显示
	if GameManager.economy:
		coins_label.text = "%d" % GameManager.economy.coins

## 创建商品卡片
## item: Weapon 或 Item 资源 (null 时为占位)
## index: 在 shop_items 中的索引
func _create_card(item: Resource, index: int) -> Control:
	# 九宫格面板背景
	var panel := NinePatchRect.new()
	panel.texture = CARD_TEXTURE
	panel.patch_margin_left = CARD_PATCH_MARGIN
	panel.patch_margin_top = CARD_PATCH_MARGIN
	panel.patch_margin_right = CARD_PATCH_MARGIN
	panel.patch_margin_bottom = CARD_PATCH_MARGIN
	panel.custom_minimum_size = Vector2(0, CARD_HEIGHT)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# 内部 margin
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(margin)

	# 水平布局: 图标 + 名称 + 价格
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	hbox.add_theme_constant_override("separation", 6)
	margin.add_child(hbox)

	# 图标
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(16, 16)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if item:
		var sheet_name := "items"
		var icon_index: int = item.get("icon_index") if item else 0
		if item.has_method("get") and item.get("weapon_type"):
			sheet_name = "weapons"
		icon.texture = IconAtlas.get_icon(sheet_name, icon_index)
	hbox.add_child(icon)

	# 名称
	var name_label := Label.new()
	name_label.text = item.get("item_name") if item and item.has_method("get") else "???"
	name_label.theme_override_font_sizes["font_size"] = 8
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(name_label)

	# 价格
	var price_label := Label.new()
	var price = item.get("price") if item and item.has_method("get") else 0
	price_label.text = "%dG" % price
	price_label.theme_override_font_sizes["font_size"] = 8
	hbox.add_child(price_label)

	# 点击购买
	panel.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_purchase_item(index)
	)

	return panel

func _on_coins_changed(amount: int) -> void:
	coins_label.text = "%d" % amount

## 购买商品
func _purchase_item(index: int) -> void:
	if index < 0 or index >= shop_items.size():
		return
	var item: Resource = shop_items[index]
	if not GameManager.economy:
		return
	# TODO: 判断类型，添加到武器或道具栏
	# if item is WeaponResource and GameManager.inventory.add_weapon(item):
	#     ...
	# elif item is ItemResource and GameManager.inventory.add_item(item):
	#     ...
	purchase_made.emit(item)
