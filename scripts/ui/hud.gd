## HUD 界面脚本
## 显示生命值、经验值、金币、波次、计时器等信息
## 底部显示武器槽 (6) 和道具槽 (6)（D11-12-T2：被动槽 4→6）
extends CanvasLayer

# ========== 节点引用 ==========

@onready var health_bar: TextureProgressBar = $MarginContainer/VBoxContainer/StatsBar/HealthBar
@onready var xp_bar: TextureProgressBar = $MarginContainer/VBoxContainer/StatsBar/XpBar
@onready var health_label: Label = $MarginContainer/VBoxContainer/StatsBar/HealthLabel
@onready var wave_label: Label = $MarginContainer/VBoxContainer/TopBar/CenterSection/WaveLabel
## F-06（用户拍板 2026-08-06）：剩余怪物数量 Label（倒计时 timer_label 已有）
@onready var enemy_count_label: Label = $MarginContainer/VBoxContainer/TopBar/CenterSection/EnemyCountLabel
@onready var timer_label: Label = $MarginContainer/VBoxContainer/TopBar/RightSection/TimerLabel
@onready var coins_label: Label = $MarginContainer/VBoxContainer/TopBar/RightSection/CoinsLabel

## 技能冷却槽（D4-T6 + PS-A3 2026-08-16 1→3 格）：SkillSlot 整体压暗 + 子 Label 显示剩余秒数
## 槽 0 = 英雄默认技能（SkillSlot）；槽 1/2 = 掉落技能（SkillSlot1/2，空槽灰显占位）
@onready var skill_slot: TextureRect = $MarginContainer/VBoxContainer/BottomBar/SkillBar/SkillSlot
@onready var skill_label: Label = $MarginContainer/VBoxContainer/BottomBar/SkillBar/SkillSlot/SkillLabel
@onready var skill_slot1: TextureRect = $MarginContainer/VBoxContainer/BottomBar/SkillBar/SkillSlot1
@onready var skill_label1: Label = $MarginContainer/VBoxContainer/BottomBar/SkillBar/SkillSlot1/SkillLabel1
@onready var skill_slot2: TextureRect = $MarginContainer/VBoxContainer/BottomBar/SkillBar/SkillSlot2
@onready var skill_label2: Label = $MarginContainer/VBoxContainer/BottomBar/SkillBar/SkillSlot2/SkillLabel2
## PS-A3 槽位映射：slot 序号 → {slot, label} 对（供 slot_cooldown_changed 统一路由）
var _skill_slots: Array = []

## 08-07 反馈：Boss 血条（顶部中央 名称 + HP 条；轮询敌人容器找 is_boss 存活目标，
## 天然兼容两制 Boss：路线模式 invoker(wave10) / 旧制 predator(wave20)）
@onready var boss_bar: VBoxContainer = $MarginContainer/VBoxContainer/BossBar
@onready var boss_name_label: Label = $MarginContainer/VBoxContainer/BossBar/BossNameLabel
@onready var boss_health_bar: TextureProgressBar = $MarginContainer/VBoxContainer/BossBar/BossHealthBar
var _boss_target: Node = null
var _boss_scan_timer: float = 0.0

## 武器槽位背景节点 (6 个 TextureRect, texture = slot_weapon.png)
@onready var weapon_slots: Array[TextureRect] = [
	$MarginContainer/VBoxContainer/BottomBar/WeaponBar/WeaponSlot0,
	$MarginContainer/VBoxContainer/BottomBar/WeaponBar/WeaponSlot1,
	$MarginContainer/VBoxContainer/BottomBar/WeaponBar/WeaponSlot2,
	$MarginContainer/VBoxContainer/BottomBar/WeaponBar/WeaponSlot3,
	$MarginContainer/VBoxContainer/BottomBar/WeaponBar/WeaponSlot4,
	$MarginContainer/VBoxContainer/BottomBar/WeaponBar/WeaponSlot5,
]

## 道具槽位背景节点 (6 个 TextureRect, texture = slot_item.png)（D11-12-T2：4→6 对齐大纲 6 被动槽）
@onready var item_slots: Array[TextureRect] = [
	$MarginContainer/VBoxContainer/BottomBar/ItemBar/ItemSlot0,
	$MarginContainer/VBoxContainer/BottomBar/ItemBar/ItemSlot1,
	$MarginContainer/VBoxContainer/BottomBar/ItemBar/ItemSlot2,
	$MarginContainer/VBoxContainer/BottomBar/ItemBar/ItemSlot3,
	$MarginContainer/VBoxContainer/BottomBar/ItemBar/ItemSlot4,
	$MarginContainer/VBoxContainer/BottomBar/ItemBar/ItemSlot5,
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

	# 连接玩家信号（P1 Fix-3：延迟一帧——HUD 是 Main 子节点，_ready 先于 Main._ready 执行，
	# 此时 GameManager.player 尚未赋值；与 _connect_skill_controller 同范式）
	_connect_player_signals()

	# F-24（2026-08-08 用户拍板）：背包信号延迟连接——inventory 由 main._ready 注入
	# GameManager（@onready $Inventory），HUD._ready 先于 main._ready 执行时为 null，
	# 直接连接会静默失败 → 购买后 HUD 槽位不刷新（「买了不进下方物品栏」根因）
	_connect_inventory_signals()

	# 收集图标子节点
	for slot in weapon_slots:
		weapon_icons.append(slot.get_node("Icon") as TextureRect)
	for slot in item_slots:
		item_icons.append(slot.get_node("Icon") as TextureRect)

	# D4-T6：延迟一帧连接 SkillController（Main._ready 装载英雄数据需先完成）
	_connect_skill_controller()

	# BS-A4（O4 · 2026-08-13）：玩家状态栏——实时显示 StatusComponent 剩余秒数/层数
	# （可读性原则，仿 Boss 血条挂 UI 先例；640×360 视口左下角，2 行血条/经验条之下）
	_player_status_bar = VBoxContainer.new()
	_player_status_bar.name = "PlayerStatusBar"
	_player_status_bar.position = Vector2(4, 120)
	_player_status_bar.add_theme_constant_override("separation", 2)
	add_child(_player_status_bar)

	# BS-D3（O3/O5 · 2026-08-13）：Boss 免疫可视化——Boss 血条下挂免疫标签
	# （resist 列消费：硬控免疫软控保留；图标占位 = 文本标签，豁免色号编码）
	_boss_immunity_label = Label.new()
	_boss_immunity_label.name = "BossImmunityLabel"
	_boss_immunity_label.add_theme_font_size_override("font_size", 10)
	_boss_immunity_label.add_theme_color_override("font_color", Color(0.95, 0.55, 0.35))
	_boss_immunity_label.position = Vector2(4, 22)
	_boss_immunity_label.visible = false
	boss_bar.add_child(_boss_immunity_label)

# ========== 信号处理 ==========

func _on_wave_started(wave_number: int) -> void:
	# F-26（2026-08-08 用户拍板）：删波次改关卡制——路线模式关 = 层（current_layer+1，
	# 第 10/15 关为 Boss 关）；旧波次制保留 wave_number 作为关号；Boss 关加后缀
	var stage: int = wave_number
	if GameManager != null and not GameManager.route.is_empty():
		# Node.get() 只收 1 参（无默认值），先判存在
		stage = int(GameManager.get("current_layer")) + 1 if "current_layer" in GameManager else 1
	var boss_suffix: String = ""
	if GameManager != null and GameManager.is_boss_wave:
		boss_suffix = " · BOSS"
	wave_label.text = "第 %d 关%s" % [stage, boss_suffix]

func _on_state_changed(new_state) -> void:
	visible = (new_state == GameManager.GameState.BATTLE)

## F-06（用户拍板 2026-08-06）：剩余怪计数 —— 0.25s 低频轮询 enemies_container 存活敌数
## （杀敌/精英产卵/清残敌都会即时反映；不用 total-kill 差值，天然免疫产卵与生成批次偏差）
var _enemy_count_timer: float = 0.0
## BS-A4（2026-08-13）：玩家状态栏节点 + 0.25s 刷新节流
var _player_status_bar: VBoxContainer = null
var _player_status_timer: float = 0.0
## BS-D3（2026-08-13）：Boss 免疫标签（resist 列消费；硬控免疫软控保留的可读化）
var _boss_immunity_label: Label = null
## 免疫类型 → 中文名（resist 列值映射；元素 id 走 effect 表 name 兜底）
const IMMUNITY_CN: Dictionary = {
	"stun": "眩晕", "knockback": "击退", "slow": "减速", "paralyze": "麻痹",
}

func _process(delta: float) -> void:
	# Boss 血条：血量每帧刷新（单目标开销可忽略），目标扫描 0.25s 节流
	_boss_scan_timer -= delta
	if _boss_scan_timer <= 0.0:
		_boss_scan_timer = 0.25
		_scan_boss_target()
	_update_boss_bar()
	_enemy_count_timer -= delta
	if _enemy_count_timer > 0.0:
		return
	_enemy_count_timer = 0.25
	_refresh_enemy_count()
	# BS-A4：玩家状态栏随 0.25s 节流同刷（效果剩余秒数/层数）
	_player_status_timer -= delta
	if _player_status_timer <= 0.0:
		_player_status_timer = 0.25
		_update_player_status_bar()

## BS-A4（O4 · 2026-08-13）：玩家状态栏刷新——每活动效果一行「名 剩余s ×层数」
## 效果 id 列表数据驱动（DataLoader.get_all_element_ids）；无玩家/无组件/全空 → 清空
func _update_player_status_bar() -> void:
	if _player_status_bar == null:
		return
	for ch in _player_status_bar.get_children():
		ch.queue_free()
	var player: Node = GameManager.player if GameManager != null else null
	if player == null or not is_instance_valid(player):
		return
	var comp: Node = player.get_node_or_null("StatusComponent")
	if comp == null:
		return
	for eid in DataLoader.get_all_element_ids():
		var remaining: float = float(comp.call("get_remaining", str(eid)))
		if remaining <= 0.0:
			continue
		var def: Dictionary = DataLoader.get_element(str(eid))
		var stacks: int = int(comp.call("get_stacks", str(eid)))
		var label := Label.new()
		label.text = "%s %.1fs ×%d" % [str(def.get("name", str(eid))), remaining, stacks]
		label.add_theme_font_size_override("font_size", 10)
		label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
		_player_status_bar.add_child(label)

## 敌人容器获取（Boss 扫描 / 剩余怪计数共用；GameManager.enemies_container 优先）
func _get_enemy_container() -> Node:
	var container: Node = GameManager.enemies_container if GameManager.enemies_container else null
	if container == null and GameManager.enemy_spawner:
		container = GameManager.enemy_spawner.get("enemies_container")
	return container

## 扫描存活 Boss（首个 is_boss && is_alive；Boss 出场/死亡时 0.25s 内切换）
func _scan_boss_target() -> void:
	var target: Node = null
	var container: Node = _get_enemy_container()
	if container != null:
		for enemy in container.get_children():
			if is_instance_valid(enemy) and enemy.get("is_boss") == true and enemy.get("is_alive") != false:
				target = enemy
				break
	_boss_target = target

## Boss 血条显示：名称 + health/max_health 比例；无目标/死亡 → 隐藏
func _update_boss_bar() -> void:
	if _boss_target == null or not is_instance_valid(_boss_target):
		boss_bar.visible = false
		if _boss_immunity_label:
			_boss_immunity_label.visible = false
		return
	var max_hp: float = float(_boss_target.get("max_health"))
	var hp: float = float(_boss_target.get("health"))
	if max_hp <= 0.0:
		boss_bar.visible = false
		if _boss_immunity_label:
			_boss_immunity_label.visible = false
		return
	var nm: String = "BOSS"
	var eid: Variant = _boss_target.get("enemy_id")
	if eid != null and not str(eid).is_empty():
		var ed: Dictionary = DataLoader.get_enemy(str(eid))
		if not ed.is_empty():
			var nm2: Variant = ed.get("name")
			if nm2 != null and not str(nm2).is_empty():
				nm = str(nm2)
	boss_name_label.text = nm
	boss_health_bar.max_value = max_hp
	boss_health_bar.value = hp
	boss_bar.visible = true
	# BS-D3（O3/O5）：免疫可视化——resist 列表 → 免疫标签（可读性：避免玩家带无效 build 打到一半才发现）
	if _boss_immunity_label:
		# ⚠️ Node.get() 只收 1 参（Object.get 无默认值重载——历史教训）
		var resist: Variant = _boss_target.get("resist") if "resist" in _boss_target else null
		if resist is Array and not (resist as Array).is_empty():
			var parts: Array[String] = []
			for r in resist:
				var rn: String = str(r)
				parts.append(str(IMMUNITY_CN.get(rn, DataLoader.get_element(rn).get("name", rn))))
			_boss_immunity_label.text = "免疫: %s" % "、".join(parts)
			_boss_immunity_label.visible = true
		else:
			_boss_immunity_label.visible = false

func _refresh_enemy_count() -> void:
	# F-46（用户 2026-08-18 拍板）：怪物计数改分数制「已击杀 / 本关总生成」——
	# 左侧 = wave_manager.kill_count（每击杀 +1），右侧 = 本关生成总数（Excel wave 表固定值）；
	# 替换原「剩余 N」存活数显示（生成批次/mom 召唤物不再造成读数跳变误解）
	var kill: int = 0
	var total: int = 0
	if GameManager != null and GameManager.wave_manager != null:
		var wm: Node = GameManager.wave_manager
		kill = int(wm.call("get_kill_count")) if wm.has_method("get_kill_count") else int(wm.get("kill_count"))
		total = int(wm.call("get_wave_total")) if wm.has_method("get_wave_total") else 0
	# mom 等召唤物击杀可能使 kill > total（总数不含召唤物）→ clamp 显示满格防「负数/超格」
	enemy_count_label.text = "%d / %d" % [mini(kill, total), total]

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

## D4-T1：经验变化刷新 XpBar（update_xp 原有接口接上调用方）
func _on_xp_changed(current: float, need: float) -> void:
	update_xp(current, need)

# ========== 技能冷却指示（Day 4 · D4-T6） ==========

## P1 Fix-3：延迟一帧连接玩家信号（HUD _ready 先于 Main _ready，player 尚未赋值）
func _connect_player_signals() -> void:
	await get_tree().process_frame
	if GameManager.player == null:
		return
	GameManager.player.health_changed.connect(_on_health_changed)
	if GameManager.player.has_signal("xp_changed"):
		GameManager.player.xp_changed.connect(_on_xp_changed)
	# 首次刷新（连接时 player 已完成 apply_character，取实时值）
	_on_health_changed(GameManager.player.health, GameManager.player.max_health)
	if GameManager.player.has_method("get_xp_to_next_level"):
		_on_xp_changed(GameManager.player.exp, GameManager.player.get_xp_to_next_level())

## F-24（2026-08-08 用户拍板）：延迟一帧连接背包信号（inventory 由 main._ready 注入，
## HUD._ready 先于 main._ready → 直接连接静默失败 = 购买后槽位不刷新根因）
func _connect_inventory_signals() -> void:
	await get_tree().process_frame
	if GameManager.inventory == null:
		push_warning("[HUD] inventory 未就绪，槽位刷新信号未连接")
		return
	GameManager.inventory.weapon_added.connect(_on_weapon_added)
	GameManager.inventory.weapon_removed.connect(_on_weapon_removed)
	GameManager.inventory.item_added.connect(_on_item_added)
	GameManager.inventory.item_removed.connect(_on_item_removed)

## 延迟连接 SkillController（Main._ready 需先装载英雄数据；取不到只告警不崩）
func _connect_skill_controller() -> void:
	await get_tree().process_frame
	if GameManager.player == null:
		return
	var controller: Node = GameManager.player.get_node_or_null("SkillController")
	if controller == null:
		push_warning("[HUD] 未找到 SkillController，技能冷却指示不可用")
		return
	# PS-A3：槽位映射初始化（槽 0/1/2）
	_skill_slots = [
		{"slot": skill_slot, "label": skill_label},
		{"slot": skill_slot1, "label": skill_label1},
		{"slot": skill_slot2, "label": skill_label2},
	]
	if controller.has_signal("slot_cooldown_changed"):
		controller.slot_cooldown_changed.connect(_on_slot_cooldown_changed)
	if controller.has_signal("cooldown_changed"):
		controller.cooldown_changed.connect(_on_skill_cooldown_changed)
	# 初始：槽 0 读 _cd_total；槽 1/2 空槽灰显（SkillSlot1/2 已 modulate 0.35 占位）
	var total: float = 0.0
	if controller.get("_cd_total") != null:
		total = float(controller.get("_cd_total"))
	_on_skill_cooldown_changed(0.0, total)
	_on_slot_cooldown_changed(1, 0.0, 0.0)
	_on_slot_cooldown_changed(2, 0.0, 0.0)
	# D20-T8（T-D · P0 硬性输入）：技能图标接线（同延迟帧环境，controller 已就绪）
	_apply_skill_icon(controller)
	for i in range(1, 3):
		_apply_skill_slot_icon(controller, i)

## D20-T8（T-D）：技能图标 —— 按 SkillController.skill_data.id 映射 skills.png 帧索引，
## 无图/空 id/节点缺失 → 静默降级（保持现有样式零回归）；未知 id → push_warning 登记不崩
const SKILL_ICON_MAP: Dictionary = {
	"se_skill_fireball": 0,
	"se_skill_deploy_turret": 1,
	"se_skill_blade_burst": 2,
	"se_skill_holy_shield": 3,
	"se_skill_sword_arc": 4,   ## PS-C4 剑士剑气爆发（总指挥 08-18 补映射，skills.png 第 5 帧占位）
}
func _apply_skill_icon(controller: Node) -> void:
	if controller == null or skill_slot == null:
		return
	var sd: Variant = controller.get("skill_data")
	var skill_id: String = ""
	if sd is Dictionary and not (sd as Dictionary).is_empty():
		skill_id = str((sd as Dictionary).get("id", ""))
	if skill_id.is_empty():
		return
	if not ResourceLoader.exists("res://assets/sprites/skills/skills.png"):
		return  # 图集缺失：降级保留现有样式
	var idx: int = int(SKILL_ICON_MAP.get(skill_id, -1))
	if idx < 0:
		push_warning("[HUD] 未知技能 id（无图标映射，保留原样式）: %s" % skill_id)
		return
	var frame: AtlasTexture = IconAtlas.get_icon("skills", idx)
	if frame != null:
		skill_slot.texture = frame

## 冷却显示：left <= 0 就绪满亮度；否则显示剩余秒数并压暗
func _on_skill_cooldown_changed(left: float, _total: float) -> void:
	if left <= 0.0:
		skill_label.text = "就绪"
		skill_slot.modulate = Color.WHITE
	else:
		skill_label.text = "%.1f" % left
		skill_slot.modulate = Color(1, 1, 1, 0.4)

## PS-A3：按槽冷却显示（槽 1/2 空槽 = total 0 且数据空 → 灰显占位不动）
func _on_slot_cooldown_changed(slot: int, left: float, total: float) -> void:
	if slot < 0 or slot >= _skill_slots.size():
		return
	var pair: Dictionary = _skill_slots[slot]
	var slot_node: TextureRect = pair.get("slot")
	var label_node: Label = pair.get("label")
	if slot_node == null or label_node == null:
		return
	if left <= 0.0:
		label_node.text = "就绪" if total > 0.0 else "—"
		slot_node.modulate = Color.WHITE if total > 0.0 else Color(1, 1, 1, 0.35)
	else:
		label_node.text = "%.1f" % left
		slot_node.modulate = Color(1, 1, 1, 0.4)

## PS-A3：掉落技能槽图标（槽 1/2 按装配 data.id 映射 skills.png；空槽灰显占位）
func _apply_skill_slot_icon(controller: Node, slot: int) -> void:
	if slot < 0 or slot >= _skill_slots.size():
		return
	var slot_node: TextureRect = _skill_slots[slot].get("slot")
	if controller == null or slot_node == null:
		return
	var skills: Variant = controller.get("skills")
	if not (skills is Array) or (skills as Array).size() <= slot:
		return
	var entry: Dictionary = (skills as Array)[slot]
	if entry.is_empty() or str(entry.get("id", "")) == "":
		return  # 空槽保持灰显
	var skill_id: String = str(entry.get("id", ""))
	if not ResourceLoader.exists("res://assets/sprites/skills/skills.png"):
		return
	var idx: int = int(SKILL_ICON_MAP.get(skill_id, -1))
	if idx < 0:
		return
	var frame: AtlasTexture = IconAtlas.get_icon("skills", idx)
	if frame != null:
		slot_node.texture = frame
		slot_node.modulate = Color.WHITE

# ========== 背包槽位更新 ==========

func _on_weapon_added(weapon: Resource) -> void:
	_refresh_weapon_slots()

func _on_weapon_removed(_index: int) -> void:
	_refresh_weapon_slots()

func _on_item_added(_item: Resource) -> void:
	_refresh_item_slots()

func _on_item_removed(_item: Resource) -> void:
	_refresh_item_slots()

## 刷新武器槽位显示（F2-T2：get_weapons 浅拷贝查询接口收口，防 UI 直读内部数组）
func _refresh_weapon_slots() -> void:
	var inv := GameManager.inventory
	if not inv or not inv.has_method("get_weapons"):
		return
	var weapons: Array = inv.get_weapons()
	for i in weapon_icons.size():
		if i < weapons.size():
			var weapon = weapons[i]
			var icon_index: int = weapon.get("icon_index") if weapon else 0
			weapon_icons[i].texture = IconAtlas.get_icon("weapons", icon_index)
		else:
			weapon_icons[i].texture = null

## 刷新道具槽位显示（F2-T2：get_items 浅拷贝查询接口收口，同上）
func _refresh_item_slots() -> void:
	var inv := GameManager.inventory
	if not inv or not inv.has_method("get_items"):
		return
	var items: Array = inv.get_items()
	for i in item_icons.size():
		if i < items.size():
			var item = items[i]
			var icon_index: int = item.get("icon_index") if item else 0
			item_icons[i].texture = IconAtlas.get_icon("items", icon_index)
		else:
			item_icons[i].texture = null

# ========== 外部接口 ==========

## 更新经验条 (供外部调用)
func update_xp(current: float, maximum: float) -> void:
	xp_bar.max_value = maximum
	xp_bar.value = current
