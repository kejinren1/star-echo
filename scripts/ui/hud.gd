## HUD 界面脚本
## 显示生命值、经验值、金币、波次、计时器等信息
## 底部显示武器槽 (6) 和道具槽 (4)
extends CanvasLayer

# ========== 节点引用 ==========

@onready var health_bar: TextureProgressBar = $MarginContainer/VBoxContainer/TopBar/LeftSection/HealthBar
@onready var xp_bar: TextureProgressBar = $MarginContainer/VBoxContainer/TopBar/LeftSection/XpBar
@onready var health_label: Label = $MarginContainer/VBoxContainer/TopBar/LeftSection/HealthLabel
@onready var wave_label: Label = $MarginContainer/VBoxContainer/TopBar/CenterSection/WaveLabel
@onready var timer_label: Label = $MarginContainer/VBoxContainer/TopBar/RightSection/TimerLabel
@onready var coins_label: Label = $MarginContainer/VBoxContainer/TopBar/RightSection/CoinsLabel

## 武器槽位背景节点 (6 个 TextureRect, texture = slot_weapon.png)
@onready var weapon_slots: Array[TextureRect] = [
	$MarginContainer/VBoxContainer/BottomBar/WeaponBar/WeaponSlot0,
	$MarginContainer/VBoxContainer/BottomBar/WeaponBar/WeaponSlot1,
	$MarginContainer/VBoxContainer/BottomBar/WeaponBar/WeaponSlot2,
	$MarginContainer/VBoxContainer/BottomBar/WeaponBar/WeaponSlot3,
	$MarginContainer/VBoxContainer/BottomBar/WeaponBar/WeaponSlot4,
	$MarginContainer/VBoxContainer/BottomBar/WeaponBar/WeaponSlot5,
]

## 道具槽位背景节点 (4 个 TextureRect, texture = slot_item.png)
@onready var item_slots: Array[TextureRect] = [
	$MarginContainer/VBoxContainer/BottomBar/ItemBar/ItemSlot0,
	$MarginContainer/VBoxContainer/BottomBar/ItemBar/ItemSlot1,
	$MarginContainer/VBoxContainer/BottomBar/ItemBar/ItemSlot2,
	$MarginContainer/VBoxContainer/BottomBar/ItemBar/ItemSlot3,
]

## 武器图标节点 (槽位子节点, 显示武器图标)
@onready var weapon_icons: Array[TextureRect] = []
## 道具图标节点 (槽位子节点, 显示道具图标)
@onready var item_icons: Array[TextureRect] = []

# ========== 生命周期 ==========

func _ready() -> void:
	# 连接 GameManager 信号
	GameManager.wave_started.connect(_on_wave_started)
	GameManager.state_changed.connect(_on_state_changed)

	# 连接波次管理器信号
	if GameManager.wave_manager:
		GameManager.wave_manager.wave_timer_tick.connect(_on_timer_tick)

	# 连接经济系统信号
	if GameManager.economy:
		GameManager.economy.coins_changed.connect(_on_coins_changed)

	# 连接玩家信号
	if GameManager.player:
		GameManager.player.health_changed.connect(_on_health_changed)

	# 连接背包信号
	if GameManager.inventory:
		GameManager.inventory.weapon_added.connect(_on_weapon_added)
		GameManager.inventory.weapon_removed.connect(_on_weapon_removed)
		GameManager.inventory.item_added.connect(_on_item_added)
		GameManager.inventory.item_removed.connect(_on_item_removed)

	# 收集图标子节点
	for slot in weapon_slots:
		weapon_icons.append(slot.get_node("Icon") as TextureRect)
	for slot in item_slots:
		item_icons.append(slot.get_node("Icon") as TextureRect)

# ========== 信号处理 ==========

func _on_wave_started(wave_number: int) -> void:
	wave_label.text = "波次 %d/%d" % [wave_number, GameManager.max_waves]

func _on_state_changed(new_state) -> void:
	visible = (new_state == GameManager.GameState.BATTLE)

func _on_timer_tick(time: float) -> void:
	timer_label.text = "%d" % ceil(time)
	# 最后 10 秒变红
	if time <= 10.0:
		timer_label.modulate = Color(1, 0.2, 0.2)
	else:
		timer_label.modulate = Color.WHITE

func _on_coins_changed(amount: int) -> void:
	coins_label.text = "%d" % amount

func _on_health_changed(current_hp: float, max_hp: float) -> void:
	health_bar.max_value = max_hp
	health_bar.value = current_hp
	health_label.text = "%d/%d" % [int(current_hp), int(max_hp)]

# ========== 背包槽位更新 ==========

func _on_weapon_added(weapon: Resource) -> void:
	_refresh_weapon_slots()

func _on_weapon_removed(_index: int) -> void:
	_refresh_weapon_slots()

func _on_item_added(_item: Resource) -> void:
	_refresh_item_slots()

func _on_item_removed(_index: int) -> void:
	_refresh_item_slots()

## 刷新武器槽位显示
func _refresh_weapon_slots() -> void:
	var inv := GameManager.inventory
	if not inv:
		return
	for i in weapon_icons.size():
		if i < inv.weapons.size():
			var weapon = inv.weapons[i]
			var icon_index: int = weapon.get("icon_index") if weapon else 0
			weapon_icons[i].texture = IconAtlas.get_icon("weapons", icon_index)
		else:
			weapon_icons[i].texture = null

## 刷新道具槽位显示
func _refresh_item_slots() -> void:
	var inv := GameManager.inventory
	if not inv:
		return
	for i in item_icons.size():
		if i < inv.items.size():
			var item = inv.items[i]
			var icon_index: int = item.get("icon_index") if item else 0
			item_icons[i].texture = IconAtlas.get_icon("items", icon_index)
		else:
			item_icons[i].texture = null

# ========== 外部接口 ==========

## 更新经验条 (供外部调用)
func update_xp(current: float, maximum: float) -> void:
	xp_bar.max_value = maximum
	xp_bar.value = current
