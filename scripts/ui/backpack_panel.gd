## 背包面板（G-D · 2026-08-14 · R5 局内查看装备）
## 半屏面板：6 武器槽 + 6 被动槽网格 + 属性一览（读 player/inventory 实时数据——
## F2-T2 接口 get_weapons/get_items/get_weapon_controller 直接消费）；打开时暂停；
## 入口 = 暂停菜单（O4）；关闭恢复
extends CanvasLayer

## 半屏面板尺寸（640×360 视口）
const PANEL_SIZE: Vector2 = Vector2(520, 300)

var _player: Node = null

@onready var weapon_grid: GridContainer = $Center/Panel/Margin/VBox/Tabs/WeaponTab/WeaponGrid
@onready var item_grid: GridContainer = $Center/Panel/Margin/VBox/Tabs/ItemTab/ItemGrid
@onready var stat_label: Label = $Center/Panel/Margin/VBox/StatLabel

func _ready() -> void:
	# 游戏结束（胜利/失败）时若面板仍开着 → 一并释放 + 恢复
	GameManager.game_over.connect(func(_victory: bool) -> void:
		if is_instance_valid(self):
			get_tree().paused = false
			queue_free()
	)
	# 关闭按钮 → 恢复游戏
	var close_btn := get_node_or_null("Center/Panel/Margin/VBox/CloseButton")
	if close_btn:
		close_btn.pressed.connect(_on_close_pressed)
	_player = GameManager.player if GameManager else null
	_build_slots()
	_build_stats()

## 6 武器槽 + 6 被动槽（未装备显示「空」）
func _build_slots() -> void:
	var weapons: Array = []
	var items: Array = []
	if GameManager and GameManager.inventory:
		weapons = GameManager.inventory.get_weapons()
		items = GameManager.inventory.get_items()
	for i in range(6):
		var slot := _make_slot(weapons[i] if i < weapons.size() else null)
		weapon_grid.add_child(slot)
	for i in range(6):
		var slot := _make_slot(items[i] if i < items.size() else null)
		item_grid.add_child(slot)

func _make_slot(res: Resource) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(96, 22)
	var label := Label.new()
	if res != null:
		# ⚠️ Resource.get() 只收 1 参（历史坑）——取回后 int/str 收敛
		var lv: int = int(res.get("level"))
		label.text = "%s Lv.%d" % [str(res.get("name")), lv]
	else:
		label.text = "（空）"
	label.add_theme_font_size_override("font_size", 9)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(label)
	return panel

## 属性一览（player 实时属性）
func _build_stats() -> void:
	if _player == null:
		stat_label.text = "（无玩家数据）"
		return
	stat_label.text = "生命 %d/%d  攻速 ×%.2f  暴击 %d%%  移速 %d  护甲 %d  闪避 %d%%" % [
		int(_player.get("health")), int(_player.get("max_health")),
		float(_player.get("attack_speed")),
		int(float(_player.get("crit_chance")) * 100.0),
		int(_player.get("move_speed")), int(_player.get("armor")),
		int(float(_player.get("dodge")) * 100.0),
	]

func _on_close_pressed() -> void:
	get_tree().paused = false
	queue_free()
