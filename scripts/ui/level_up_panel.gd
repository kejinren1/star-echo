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
			button.visible = true
			button.pressed.connect(_on_option_pressed.bind(i))
		else:
			button.visible = false

# ========== 选项生成 ==========

## 摊平 upgrade_options 四组 → shuffle → 取前 count 个（天然不重复）
func _roll_options(count: int) -> Array:
	var pool: Array = []
	var leveling: Dictionary = DataLoader.get_leveling()
	for group in leveling.get("upgrade_options", []):
		for opt in group.get("options", []):
			pool.append(opt)
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
func _apply_option(opt: Dictionary) -> void:
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
