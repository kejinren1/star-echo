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
## D13-T6（BUG-002 修复）：用 weapon_controller 的 build_weapon_from_data 纯函数式构建
## 武器资源（实例不 add_child → 不触发 _ready → 无「初始枪」副作用）
const WeaponControllerScript: GDScript = preload("res://scripts/weapons/weapon_controller.gd")

# ========== 节点引用 ==========

@onready var item_container: VBoxContainer = $ShopPanel/Margin/VBox/ItemContainer
@onready var reroll_button: TextureButton = $ShopPanel/Margin/VBox/BottomBar/RerollButton
@onready var continue_button: TextureButton = $ShopPanel/Margin/VBox/BottomBar/ContinueButton
@onready var coins_label: Label = $ShopPanel/Margin/VBox/TopBar/CoinsLabel

# ========== 配置 ==========

const SHOP_ITEM_COUNT: int = 4                  ## 商店刷新物品数
const REROLL_COST_DEFAULT: int = 10             ## 刷新费用兜底默认（数据驱动 stats.json shop.reroll_cost）
const CORE_GRACE_WAVE_DEFAULT: int = 4          ## 星刃核心保底波兜底默认（数据驱动 stats.json shop.core_grace_wave）
const CARD_HEIGHT: int = 36                     ## 卡片高度
const CARD_PATCH_MARGIN: int = 12               ## 卡片 9-slice 边距

## F1-D（T-010）：商店参数数据化——_ready 从 DataLoader.get_stats_shop() 读参，缺字段用兜底默认
var reroll_cost: int = REROLL_COST_DEFAULT      ## 刷新费用
var core_grace_wave: int = CORE_GRACE_WAVE_DEFAULT  ## 星刃核心保底波（current_wave == 此值）

## 卡片面板纹理
const CARD_TEXTURE: Texture2D = preload("res://assets/sprites/ui/panel_card.png")

var shop_items: Array[Resource] = []            ## 当前商店商品

## F-21 群星回应（2026-08-08 用户拍板）：第四关结算时星刃核心保底机制——
## 星刃核心常在前几波刷出但没钱买 → 第四关（current_wave==4）结算进商店时，
## 若已升级两次技能（player.level>=3）且本商店无星刃核心，则激活「✨ 群星在回应你」：
## 刷新按钮高亮 + 一次免费刷新，点击刷新必定出现星刃核心（本局仅一次）
var star_grace_available: bool = false         ## 本商店是否激活群星回应（免费+必出核心）
var star_grace_used: bool = false              ## 本局是否已消费群星回应（一次性）

## 群星回应提示 Label（动态创建，挂 BottomBar 前；无则跳过不崩）
var _grace_label: Label = null

## D13-T6：武器资源懒构建器（WeaponController 未入树实例，仅调纯函数 build_weapon_from_data）
var _wc_builder: Node = null

# ========== 铁砧 anvil 面板（F31-3，动态构建零新 tscn） ==========

var _anvil_layer: CanvasLayer = null        ## 置顶层（含全屏遮罩 + 选择列表）
var _anvil_item: Resource = null            ## 当前购买的 anvil 商品（purchase_made 透传）
var _anvil_index: int = -1                  ## anvil 在 shop_items 中的索引（购买后移除）
var _anvil_price: int = 0                   ## 价格（数据驱动自 item.price，防硬编码漂移）

# ========== 生命周期 ==========

func _ready() -> void:
	visible = false
	# F1-D（T-010）：商店参数数据驱动读参（DataLoader 缺失/缺字段 → 兜底默认，零回归）
	if DataLoader:
		var shop_cfg: Dictionary = DataLoader.get_stats_shop()
		reroll_cost = int(shop_cfg.get("reroll_cost", REROLL_COST_DEFAULT))
		core_grace_wave = int(shop_cfg.get("core_grace_wave", CORE_GRACE_WAVE_DEFAULT))
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
	# F-21 群星回应：第四关结算时检测是否激活免费必出核心刷新（刷新后判断本商店是否缺核心）
	_check_star_grace()

func _on_shop_closed() -> void:
	visible = false
	_clear_star_grace_ui()

func _on_continue_pressed() -> void:
	shop_exited.emit()
	GameManager.close_shop()

func _on_reroll_pressed() -> void:
	# F-21 群星回应：激活时免费刷新且必定出现星刃核心（不扣费、消耗本次机会）
	if star_grace_available:
		star_grace_available = false
		star_grace_used = true
		_clear_star_grace_ui()
		_refresh_shop(true)
		return
	if GameManager.economy and GameManager.economy.spend_coins(reroll_cost):
		_refresh_shop()

# ========== 商品生成（D11-12-T4 真实商品） ==========

## 刷新商店商品：混合池（33 武器 + 20 被动 + 2 遗物）洗牌随机 4 卡
## F-21：force_blade_core=true（群星回应免费刷新）→ 结果强制含 1 张星刃核心
## （先正常随机，若结果无核心则把最后一张替换为 se_blade_core，幂等防重）
func _refresh_shop(force_blade_core: bool = false) -> void:
	shop_items.clear()
	var pool: Array = _build_shop_pool()
	pool.shuffle()
	var count: int = mini(SHOP_ITEM_COUNT, pool.size())
	for i in count:
		shop_items.append(pool[i])
	if force_blade_core and not _has_blade_core() and not shop_items.is_empty():
		var core: Resource = _build_item_resource(DataLoader.ITEM_BLADE_CORE)
		if core != null:
			shop_items[shop_items.size() - 1] = core
	_render_cards()
	# 更新金币显示（F2-T2：get_coins 查询接口收口，防 UI 直读 coins 字段）
	if GameManager.economy:
		coins_label.text = "%d" % GameManager.economy.get_coins()

## F-21 群星回应：检测是否激活（第四关结算 + 已升级两次技能 + 本商店无星刃核心 + 本局未用过）
func _check_star_grace() -> void:
	if star_grace_used or star_grace_available:
		return
	# 保底波：current_wave == core_grace_wave（route 模式 wave_index / 旧制第 N 波，商店打开时值保持）
	if GameManager == null or not ("current_wave" in GameManager) or int(GameManager.get("current_wave")) != core_grace_wave:
		return
	# 已升级两次技能：player.level >= 3（从 1 起升两次；player 缺失/未绑定 → 不激活）
	var p: Node = GameManager.get("player") if GameManager else null
	if p == null or not ("level" in p) or int(p.get("level")) < 3:
		return
	# 本商店已刷出星刃核心 → 无需保底
	if _has_blade_core():
		return
	star_grace_available = true
	_show_star_grace_ui()

## 当前商店 4 卡中是否有星刃核心（item_id == DataLoader.ITEM_BLADE_CORE）
func _has_blade_core() -> bool:
	for item in shop_items:
		if item and ("item_id" in item) and str(item.get("item_id")) == DataLoader.ITEM_BLADE_CORE:
			return true
	return false

## F-21 群星回应 UI：刷新按钮金闪高亮 + 提示文案「群星在回应你」
func _show_star_grace_ui() -> void:
	if reroll_button:
		reroll_button.modulate = Color(1.0, 0.85, 0.3)
		var tw := reroll_button.create_tween()
		tw.set_loops()
		tw.tween_property(reroll_button, "modulate", Color(1.0, 0.6, 0.15), 0.5)
		tw.tween_property(reroll_button, "modulate", Color(1.0, 0.85, 0.3), 0.5)
	# 提示文案：挂 BottomBar 前（VBox 顺序：TopBar/ItemContainer/BottomBar）
	var vbox: Node = $ShopPanel/Margin/VBox
	if vbox and _grace_label == null:
		_grace_label = Label.new()
		_grace_label.text = "✨ 群星在回应你 · 免费刷新（必出星刃核心）"
		_grace_label.add_theme_font_size_override("font_size", 8)
		_grace_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		vbox.add_child(_grace_label)
		vbox.move_child(_grace_label, vbox.get_child_count() - 2)  # BottomBar 前

## F-21 群星回应 UI 清理（关闭商店/刷新消费后复位）
func _clear_star_grace_ui() -> void:
	if reroll_button:
		reroll_button.modulate = Color.WHITE
	if _grace_label and is_instance_valid(_grace_label):
		_grace_label.queue_free()
		_grace_label = null

## 商品池：武器（排除 evolution_result 结果武器 + 初始武器）+ 被动（is_passive==true）+ 遗物（slot=="relic" 且 price>0）+ 服务（effects.shop_weapon_upgrade）
## D13-T6（BUG-002 修复）：返回**资源实例数组**（武器 Weapon / 被动 Item），
## 修复原实现把 String id 直接 push 进 `shop_items: Array[Resource]` 的类型冲突
## （每进商店 4 条恒定 ERROR + 0 卡）；口径 = 36 武器 − 3 结果武器 − 10 起始武器 + 23 被动 + 2 遗物 + 1 服务 = 49
## D20-T4：遗物第三池（resonant_shard price=0 天然排除 = 事件专属保持；2 遗物 price>0 入池）
## D24-F13-1：3 机制型被动入池（overload_capacitor/executioner_mark/last_stand，is_passive 全入）
## F31-1（2026-08-08 用户拍板）：初始武器出商店池（10 把 starting_weapon 跳过）
## F31-3：铁砧 anvil 服务池入池（effects.shop_weapon_upgrade true = 唯一服务商品）
func _build_shop_pool() -> Array:
	var pool: Array = []
	# 武器池：36 把 - 3 把结果武器 - 10 把初始武器 = 23 把（build_weapon_from_data 构建 Weapon 资源）
	var starting_ids: Array = DataLoader.get_starting_weapon_ids()
	for wid in DataLoader.get_all_weapon_ids():
		var wdata: Dictionary = DataLoader.get_weapon(wid)
		if wdata.is_empty() or wdata.has("evolution_result") or starting_ids.has(wid):
			continue
		var w: Resource = _build_weapon_resource(wid)
		if w != null:
			pool.append(w)
	# 被动池：23 项 is_passive（Item 资源，仿 inventory.add_item_from_data 字段装载）
	for iid in DataLoader.get_all_item_ids():
		var idata: Dictionary = DataLoader.get_item(iid)
		if idata.is_empty() or not idata.get("is_passive", false):
			continue
		var it: Resource = _build_item_resource(iid)
		if it != null:
			pool.append(it)
	# 遗物池：slot=="relic" 且 price>0（2 项：broken_crown / mech_engine；resonant_shard price=0 排除）
	for iid in DataLoader.get_all_item_ids():
		var idata: Dictionary = DataLoader.get_item(iid)
		if idata.is_empty() or str(idata.get("slot", "")) != "relic" or int(idata.get("price", 0)) <= 0:
			continue
		var relic: Resource = _build_item_resource(iid)
		if relic != null:
			pool.append(relic)
	# 服务池（F31-3）：effects.shop_weapon_upgrade true 的服务商品（实测仅 anvil 铁砧 120G）
	# anvil 无 is_passive / 无 slot=="relic" / 无 weapon_type → 前 3 池天然不收 = 真零消费点，本段入池
	for iid in DataLoader.get_all_item_ids():
		var idata: Dictionary = DataLoader.get_item(iid)
		if idata.is_empty() or not bool(idata.get("effects", {}).get("shop_weapon_upgrade", false)):
			continue
		var svc: Resource = _build_item_resource(iid)
		if svc != null:
			pool.append(svc)
	return pool

## 武器 id → Weapon 资源（懒加载纯函数构建器；未入树实例调用 build_weapon_from_data）
func _build_weapon_resource(weapon_id: String) -> Resource:
	if _wc_builder == null:
		_wc_builder = WeaponControllerScript.new()
	return _wc_builder.call("build_weapon_from_data", weapon_id)

## 被动 id → Item 资源（仿 inventory.gd:82-92 add_item_from_data 范式）
func _build_item_resource(item_id: String) -> Resource:
	var data: Dictionary = DataLoader.get_item(item_id)
	if data.is_empty():
		return null
	var item: Resource = Item.new()
	item.item_id = item_id
	item.item_name = str(data.get("name", item_id))
	item.price = int(data.get("price", 0))
	item.rarity = str(data.get("rarity", "common"))
	item.icon_index = maxi(int(data.get("icon_index", 0)), 0)
	item.slot = str(data.get("slot", ""))
	item.category = str(data.get("category", ""))
	item.stat_bonuses = data.get("effects", {})
	# F-24（2026-08-08 用户拍板）：机制型 trigger 配置透传（tooltip 说明文本消费）
	item.trigger = data.get("trigger", {})
	return item

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
	# 08-07 修复：NinePatchRect 默认 mouse_filter=IGNORE（TextureRect 系默认值），
	# 点击会穿透到全屏 BG 导致「点卡片无反应」——显式 STOP 启用 gui_input 购买
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

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

	# F-24（2026-08-08 用户拍板）：悬停显示效果说明——「购买前不知道为什么要买」修复
	# （武器 → 数值+描述+可进化提示；被动/遗物 → effects/trigger 中文说明；原生日志即可）
	panel.tooltip_text = DescBuilder.card_tooltip(item)

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
	# 钱不够 → 前置拒绝（不 add 不扣费；F2-T2：can_afford 查询接口收口）
	if not GameManager.economy.can_afford(price):
		var dn: Variant = item.get("item_name")
		if dn == null or str(dn).is_empty():
			dn = item.get("weapon_name")
		if dn == null:
			dn = "?"
		push_warning("[Shop] 金币不足，无法购买: %s（%dG 需 %dG）" % [str(dn), GameManager.economy.get_coins(), price])
		return

	# 铁砧购买（F31-3 用户拍板）：服务商品（effects.shop_weapon_upgrade = anvil）→ 弹武器升级选择 UI
	# anvil 无 weapon_type / 无 is_passive / 无 slot=="relic" → 只走本分支，不落入下方武器/被动逻辑
	var sb: Variant = item.get("stat_bonuses")
	if sb is Dictionary and bool(sb.get("shop_weapon_upgrade", false)):
		# F2-T2：get_weapon_controller 查询接口收口（直读 get_node_or_null 消灭）
		var wc: Node = GameManager.player.get_weapon_controller() if GameManager.player else null
		var ups: Array = []
		if wc:
			for w in wc.get("equipped_weapons"):
				# Resource.get 单参（Object.get 无默认值重载）——先取再判空
				var wlv: Variant = w.get("level")
				var wmx: Variant = w.get("max_level")
				if wlv != null and wmx != null and int(wlv) < int(wmx):
					ups.append(w)
		if ups.is_empty():
			# 无可升级武器 → 拒绝不扣费（商品保留，玩家可刷新/离开）
			push_warning("[Shop] 无可升级武器，铁砧购买失败")
			return
		_show_anvil_panel(ups, item, index)
		return

	# 武器购买：先入库，后装备（equip 失败回滚入库）
	if item.get("weapon_type") != null:
		if not GameManager.inventory.add_weapon(item):
			push_warning("[Shop] 武器槽已满，购买失败")
			return
		var wc: Node = GameManager.player.get_weapon_controller() if GameManager.player else null
		if wc and wc.has_method("equip_weapon"):
			if not wc.equip_weapon(item):
				# 回滚：移除刚入库的武器（F2-T2：remove_last_weapon 接口收口，
				# add_weapon 为 append → 刚入库武器必为末位，行为与原 remove_weapon(size-1) 等价）
				GameManager.inventory.remove_last_weapon()
				push_warning("[Shop] 装备失败，已回滚入库（武器槽已满）")
				return
		# 装备成功（或无 WeaponController 调试路径）→ 扣费
		if GameManager.economy.spend_coins(price):
			shop_items.remove_at(index)
			_render_cards()
			purchase_made.emit(item)
			AudioManager.play_sfx("shop")   # D24-T3-⑦：购买成功 SFX（武器）
		return

	# 被动购买：入库（item_added → 玩家装配生效）→ 扣费
	if GameManager.inventory.add_item(item):
		if GameManager.economy.spend_coins(price):
			shop_items.remove_at(index)
			_render_cards()
			purchase_made.emit(item)
			AudioManager.play_sfx("shop")   # D24-T3-⑦：购买成功 SFX（被动）
	else:
		push_warning("[Shop] 被动槽已满，购买失败")

# ========== 铁砧 anvil 升级选择 UI（F31-3 用户拍板 · 动态构建零新 tscn） ==========

## 弹武器升级选择面板：CanvasLayer 置顶 + 半透明全屏遮罩（STOP 防穿透）+ 居中 VBox
## 每可升级武器一行 Button（武器名 · Lv.X → Lv.X+1）+ 取消；仿 _create_card 动态构建先例
func _show_anvil_panel(ups: Array, item: Resource, index: int) -> void:
	if _anvil_layer != null:
		return
	_anvil_item = item
	_anvil_index = index
	_anvil_price = int(item.get("price")) if item.get("price") != null else 0

	var layer := CanvasLayer.new()
	_anvil_layer = layer

	# 全屏遮罩：半透明 + 吞点击（防穿透到商品卡）
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.0, 0.6)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(bg)

	# 居中容器
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(center)

	var panel := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.10, 0.14, 0.95)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "铁砧 · 武器升级（%dG）" % _anvil_price
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 10)
	vbox.add_child(title)

	for w in ups:
		var btn := Button.new()
		btn.text = "%s · Lv.%d → Lv.%d" % [str(w.weapon_name), int(w.level), int(w.level) + 1]
		btn.pressed.connect(_apply_anvil_upgrade.bind(w))
		vbox.add_child(btn)

	var cancel := Button.new()
	cancel.text = "取消"
	cancel.pressed.connect(_close_anvil_panel)
	vbox.add_child(cancel)

	add_child(layer)

## 应用铁砧升级：weapon.upgrade()（列表已过滤满级，不会 false）→ spend_coins(price 数据驱动)
## → 商品移除 + 渲染刷新 → purchase_made + SFX → 关闭面板（升级语义与 level_up_panel 武器路径一致）
func _apply_anvil_upgrade(weapon: Resource) -> void:
	if weapon == null or not weapon.has_method("upgrade"):
		_close_anvil_panel()
		return
	if not weapon.upgrade():
		push_warning("[Shop] 铁砧升级失败（武器已满级）")
		_close_anvil_panel()
		return
	if GameManager.economy and GameManager.economy.spend_coins(_anvil_price):
		if _anvil_index >= 0 and _anvil_index < shop_items.size():
			shop_items.remove_at(_anvil_index)
			_render_cards()
		purchase_made.emit(_anvil_item)
		AudioManager.play_sfx("shop")   # D24-T3-⑦：购买成功 SFX（铁砧）
	_close_anvil_panel()

## 关闭铁砧面板（取消 = 仅关闭不扣费不升级；购买成功后亦调用复位）
func _close_anvil_panel() -> void:
	if _anvil_layer and is_instance_valid(_anvil_layer):
		_anvil_layer.queue_free()
	_anvil_layer = null
	_anvil_item = null
	_anvil_index = -1
	_anvil_price = 0
