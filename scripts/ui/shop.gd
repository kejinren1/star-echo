## 商店界面脚本
## 波次间购买武器和道具
## 使用 NinePatchRect 面板 + IconAtlas 图标
## D11-12-T4：真实商品 —— 商品池 = 武器池（33 把，排除 3 把 evolution_result 结果武器）
##           + 被动池（20 项 is_passive）随机 SHOP_ITEM_COUNT(4) 卡；购买先入库后扣费。
extends CanvasLayer

# ========== 信号 ==========

signal purchase_made(item: Resource)
signal shop_exited

# ========== 资源引用 ==========

## preload 而非依赖 class_name（item.gd 无 class_name，inventory.gd 同款策略）
const Item: GDScript = preload("res://scripts/items/item.gd")

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

# ========== 商品生成（D11-12-T4 真实商品） ==========

## 刷新商店商品：混合池（33 武器 + 20 被动）洗牌随机 4 卡
func _refresh_shop() -> void:
	shop_items.clear()
	var pool: Array = _build_shop_pool()
	pool.shuffle()
	var count: int = mini(SHOP_ITEM_COUNT, pool.size())
	for i in count:
		shop_items.append(pool[i])
	_render_cards()
	# 更新金币显示
	if GameManager.economy:
		coins_label.text = "%d" % GameManager.economy.coins

## 商品池：武器（排除 evolution_result 结果武器）+ 被动（is_passive==true）
func _build_shop_pool() -> Array:
	var pool: Array = []
	# 武器池：36 把 - 3 把结果武器 = 33 把
	for wid in DataLoader.get_all_weapon_ids():
		var wdata: Dictionary = DataLoader.get_weapon(wid)
		if wdata.is_empty() or wdata.has("evolution_result"):
			continue
		pool.append(wid)
	# 被动池：20 项 is_passive
	for iid in DataLoader.get_all_item_ids():
		var idata: Dictionary = DataLoader.get_item(iid)
		if idata.is_empty() or not idata.get("is_passive", false):
			continue
		pool.append(iid)
	return pool

## 把 shop_items 渲染成卡片（清空容器后重建；购买/刷新共用）
func _render_cards() -> void:
	for child in item_container.get_children():
		child.queue_free()
	for i in shop_items.size():
		var card := _create_card(shop_items[i], i)
		item_container.add_child(card)

## 创建商品卡片
## item: Weapon 或 Item 资源
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

	# 图标（武器表 or 道具表，按 weapon_type 字段区分；D11-12-T6 后被动图标 20 帧可用）
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(16, 16)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if item:
		var sheet_name := "items"
		var icon_index: int = 0
		if item.get("icon_index") != null:
			icon_index = int(item.get("icon_index"))
		if item.get("weapon_type") != null:
			sheet_name = "weapons"
		icon.texture = IconAtlas.get_icon(sheet_name, icon_index)
	hbox.add_child(icon)

	# 名称（武器读 weapon_name / 道具读 item_name）
	var name_label := Label.new()
	var display_name: String = "???"
	if item:
		var wn: Variant = item.get("weapon_name")
		var iname: Variant = item.get("item_name")
		if wn != null and not str(wn).is_empty():
			display_name = str(wn)
		elif iname != null and not str(iname).is_empty():
			display_name = str(iname)
	name_label.text = display_name
	name_label.add_theme_font_size_override("font_size", 8)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(name_label)

	# 价格
	var price_label := Label.new()
	var price: int = 0
	if item and item.get("price") != null:
		price = int(item.get("price"))
	price_label.text = "%dG" % price
	price_label.add_theme_font_size_override("font_size", 8)
	hbox.add_child(price_label)

	# 点击购买
	panel.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_purchase_item(index)
	)

	return panel

func _on_coins_changed(amount: int) -> void:
	coins_label.text = "%d" % amount

# ========== 购买（D11-12-T4 闭环：先入库后扣费） ==========

## 购买商品：钱不够前置拒绝；武器 → inventory.add_weapon + WeaponController.equip_weapon
## （equip 失败回滚 add）；被动 → inventory.add_item（触发 item_added → 玩家装配）；
## 全部成功后 economy.spend_coins；任一失败 push_warning 不扣费不崩。
func _purchase_item(index: int) -> void:
	if index < 0 or index >= shop_items.size():
		return
	var item: Resource = shop_items[index]
	if not GameManager.economy or not GameManager.inventory:
		return
	var price: int = int(item.get("price")) if item.get("price") != null else 0
	# 钱不够 → 前置拒绝（不 add 不扣费）
	if GameManager.economy.coins < price:
		var dn: Variant = item.get("item_name")
		if dn == null or str(dn).is_empty():
			dn = item.get("weapon_name")
		if dn == null:
			dn = "?"
		push_warning("[Shop] 金币不足，无法购买: %s（%dG 需 %dG）" % [str(dn), GameManager.economy.coins, price])
		return

	# 武器购买：先入库，后装备（equip 失败回滚入库）
	if item.get("weapon_type") != null:
		if not GameManager.inventory.add_weapon(item):
			push_warning("[Shop] 武器槽已满，购买失败")
			return
		var wc: Node = GameManager.player.get_node_or_null("WeaponController") if GameManager.player else null
		if wc and wc.has_method("equip_weapon"):
			if not wc.equip_weapon(item):
				# 回滚：移除刚入库的武器（inventory 与 WeaponController 槽位不同步边界）
				var inv_weapons: Array = GameManager.inventory.get("weapons")
				if inv_weapons.size() > 0:
					GameManager.inventory.call("remove_weapon", inv_weapons.size() - 1)
				push_warning("[Shop] 装备失败，已回滚入库（武器槽已满）")
				return
		# 装备成功（或无 WeaponController 调试路径）→ 扣费
		if GameManager.economy.spend_coins(price):
			shop_items.remove_at(index)
			_render_cards()
			purchase_made.emit(item)
		return

	# 被动购买：入库（item_added → 玩家装配生效）→ 扣费
	if GameManager.inventory.add_item(item):
		if GameManager.economy.spend_coins(price):
			shop_items.remove_at(index)
			_render_cards()
			purchase_made.emit(item)
	else:
		push_warning("[Shop] 被动槽已满，购买失败")
