## 升级强化选择面板（Day 4 · D4-T4）
## 玩家升级时由 GameManager 实例化并暂停游戏；从 stats.json.leveling.upgrade_options
## 随机取 3 个不重复选项，点击后应用属性、恢复运行、销毁自身。
## 样式对齐 ShopPanel（NinePatchRect 面板 + 数据驱动）；节点 process_mode = WHEN_PAUSED。
extends CanvasLayer

# ========== 节点引用 ==========

@onready var title_label: Label = $CenterContainer/Panel/Margin/VBox/Title
@onready var option_buttons: Array[Button] = [
	$CenterContainer/Panel/Margin/VBox/Option0,
	$CenterContainer/Panel/Margin/VBox/Option1,
	$CenterContainer/Panel/Margin/VBox/Option2,
]

# ========== 状态 ==========

var player: Node = null
var _options: Array = []          ## 本窗 3 个选项（D4-T2 schema: {label, stat, mode, value}）

# ========== 生命周期 ==========

func _ready() -> void:
	# 玩家死亡时若面板仍开着 → 一并释放，防悬挂（配合 GameManager 的 paused）
	GameManager.game_over.connect(func(_victory: bool) -> void:
		if is_instance_valid(self):
			queue_free()
	)

## 由 GameManager 在实例化后调用：摊平选项 → 随机取 3 个不重复 → 渲染按钮
func setup() -> void:
	player = GameManager.player
	_options = _roll_options(3)
	for i in option_buttons.size():
		var button: Button = option_buttons[i]
		if i < _options.size():
			button.text = str(_options[i].get("label", "???"))
			# F-25（2026-08-08 用户拍板）：悬停显示效果说明——武器升级/进化选项此前
			# 只能看到「升级『X』」，看不到升完什么样；属性选项显示加成通道
			button.tooltip_text = DescBuilder.option_tooltip(_options[i])
			button.visible = true
			button.pressed.connect(_on_option_pressed.bind(i))
		else:
			button.visible = false

# ========== 选项生成 ==========

## 选项池 = 属性池（stats.json.upgrade_options 摊平，现状保留）
## F31-2（2026-08-08 用户拍板）：武器升级移出升级面板（经济类 → 商店铁砧闭环，
## 见 shop.gd F31-3）——删除原武器升级池段；weapon_controller 获取 + `var weapons`
## 保留（进化池 :74 复用）；_apply_option 的 weapon_upgrade 分支保留（铁砧/兼容路径）
## + 进化池（D10-T4：满级武器 + 持有对应进化核心 → 「进化『result_name』」选项；
## 满级武器天然不满足升级池 `level < max_level` 条件 → 进化/升级选项互斥）
## → shuffle → 取前 count 个（天然不重复）
func _roll_options(count: int) -> Array:
	var pool: Array = []
	# 2026-08-08 反馈专员·方案A（用户拍板）：进化选项单独收集 → 保底入选
	var evolutions: Array = []
	var leveling: Dictionary = DataLoader.get_leveling()
	for group in leveling.get("upgrade_options", []):
		for opt in group.get("options", []):
			pool.append(opt)
	var weapon_controller: Node = null
	if player:
		weapon_controller = player.get_node_or_null("WeaponController")
	if weapon_controller:
		var weapons: Array = weapon_controller.get("equipped_weapons")
		# D10-T4 进化池：满级 + 有 source_id + JSON evolution 存在 + 背包持核心
		if GameManager.inventory:
			for weapon in weapons:
				if not weapon or weapon.level < weapon.max_level:
					continue
				# weapon_controller.gd 无 class_name，用字面量 meta 键（与 META_SOURCE_ID 一致）
				if not weapon.has_meta(&"source_id"):
					continue
				var source_id: String = str(weapon.get_meta(&"source_id"))
				var wdata: Dictionary = DataLoader.get_weapon(source_id)
				if wdata.is_empty():
					continue
				var evolution: Dictionary = wdata.get("evolution", {})
				var requires_item: String = str(evolution.get("requires_item", ""))
				if requires_item.is_empty():
					continue
				if GameManager.inventory.has_item_id(requires_item):
					# F-25（2026-08-08 用户拍板）：结果武器数值注入（tooltip「伤害 N」展示；
					# desc_builder 禁引用 Autoload，改走选项字段）
					var result_damage: int = 0
					var res_id: String = str(evolution.get("result_id", ""))
					if not res_id.is_empty():
						var rdata: Dictionary = DataLoader.get_weapon(res_id)
						if not rdata.is_empty():
							result_damage = int(rdata.get("damage", 0))
					evolutions.append({
						"label": "进化『%s』" % str(evolution.get("result_name", "")),
						"type": "evolution",
						"weapon": weapon,
						"evolution": evolution,
						"result_damage": result_damage,
					})
	# 2026-08-08 反馈专员·方案A（用户拍板「开发期优先质变闭环，暂不考虑玩法丰富度限制」）：
	# 满级 + 持核心时进化选项【保底入选】——进化选项全部放入结果（至 count 上限），
	# 剩余位置由属性/升级池随机补足；无进化可做时保持原随机 3 选 1 逻辑。
	if not evolutions.is_empty():
		var result: Array = evolutions.duplicate()
		if result.size() < count:
			pool.shuffle()
			for opt in pool:
				if result.size() >= count:
					break
				result.append(opt)
		result.shuffle()
		return result
	pool.shuffle()
	return pool.slice(0, count)

# ========== 交互 ==========

func _on_option_pressed(index: int) -> void:
	if index < 0 or index >= _options.size():
		return
	_apply_option(_options[index])
	get_tree().paused = false
	queue_free()

## 按 D4-T2 schema 应用强化（对齐 STAT_MAP._apply_stat_dict 三档写法）：
##   percent → 传 1.0 + value/100 并标记 multiplicative（乘算通道）
##   ratio   → 传 value/100（百分数转 0~1 后加算）
##   add     → 直传 value（加算）
## D5-T3：新增 weapon_upgrade 分支（升级武器本身，不调 apply_stat_modifier）
## D10-T4：新增 evolution 分支（先替换成功、后消耗核心，防不可逆损失）
func _apply_option(opt: Dictionary) -> void:
	if str(opt.get("type", "")) == "weapon_upgrade":
		var weapon: Resource = opt.get("weapon")
		if weapon and weapon.has_method("upgrade"):
			weapon.upgrade()
		return
	if str(opt.get("type", "")) == "evolution":
		var evo: Dictionary = opt.get("evolution", {})
		var wc: Node = player.get_node_or_null("WeaponController") if player else null
		if wc and wc.has_method("replace_weapon"):
			var replaced: Resource = wc.replace_weapon(opt.get("weapon"), str(evo.get("result_id", "")))
			if replaced != null:
				GameManager.inventory.remove_item_id(str(evo.get("requires_item", "")))  # 替换成功才消耗核心
			else:
				push_warning("[LevelUpPanel] 进化替换失败，核心未消耗: %s" % evo.get("result_id", ""))
		return
	if player == null or not player.has_method("apply_stat_modifier"):
		return
	var stat: String = str(opt.get("stat", ""))
	var mode: String = str(opt.get("mode", "add"))
	var value: float = float(opt.get("value", 0.0))
	match mode:
		"percent":
			player.apply_stat_modifier(stat, 1.0 + value / 100.0, true)
		"ratio":
			player.apply_stat_modifier(stat, value / 100.0)
		_:
			player.apply_stat_modifier(stat, value)
