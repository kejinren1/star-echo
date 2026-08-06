## 路线选择面板（Day 14-15 · D14-15-T4）
## 随机节点地图：每层显示本层全部节点（数量 = nodes_per_layer，末层 1 Boss），
## 玩家点击按钮 → GameManager.select_route_node(row) → 进入对应节点并销毁自身。
## 样式对齐 LevelUpPanel/ShopPanel（NinePatchRect 面板）；不暂停游戏
## （spawner 非 BATTLE 状态自动停，与商店一致）。
extends CanvasLayer

# ========== 节点引用 ==========

@onready var title_label: Label = $CenterContainer/Panel/Margin/VBox/Title
@onready var node_container: VBoxContainer = $CenterContainer/Panel/Margin/VBox/NodeContainer

# ========== 状态 ==========

var _route: Dictionary = {}      ## 本局路线（GameManager 传入）
var _layer: int = 0              ## 当前层索引
var buttons: Array[Button] = []  ## 本层节点按钮（探针/测试可读）

# ========== 生命周期 ==========

func _ready() -> void:
	# 游戏结束（胜利/失败）时若面板仍开着 → 一并释放，防悬挂
	GameManager.game_over.connect(func(_victory: bool) -> void:
		if is_instance_valid(self):
			queue_free()
	)

## 由 GameManager 在实例化后调用：渲染当前层节点按钮
func setup(route_data: Dictionary, layer: int) -> void:
	_route = route_data
	_layer = layer
	_render()

# ========== 渲染 ==========

func _render() -> void:
	var layers: Array = _route.get("layers", [])
	if _layer < 0 or _layer >= layers.size():
		push_warning("[RouteSelectPanel] 层索引越界: %d" % _layer)
		return
	for child in node_container.get_children():
		child.queue_free()
	buttons.clear()
	var nodes: Array = layers[_layer]
	title_label.text = "第 %d 层 · 选择路线" % (_layer + 1)
	for i in nodes.size():
		var node_data: Dictionary = nodes[i]
		var node_type: String = str(node_data.get("type", "?"))
		# 行容器：类型色块 + 按钮（首版不依赖新美术图标）
		var row_box := HBoxContainer.new()
		row_box.add_theme_constant_override("separation", 8)
		var color_rect := ColorRect.new()
		color_rect.custom_minimum_size = Vector2(14, 14)
		color_rect.color = _type_color(node_type)
		row_box.add_child(color_rect)
		var btn := Button.new()
		btn.text = _type_label(node_type)
		btn.custom_minimum_size = Vector2(0, 30)
		btn.add_theme_font_size_override("font_size", 10)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(_on_node_pressed.bind(i))
		row_box.add_child(btn)
		node_container.add_child(row_box)
		buttons.append(btn)

## 节点类型 → 中文名
func _type_label(node_type: String) -> String:
	match node_type:
		"battle":
			return "战斗"
		"event":
			return "事件"
		"elite":
			return "精英"
		"shop":
			return "商店"
		"boss":
			return "Boss"
	return node_type

## 节点类型 → 色块（类型识别，非美术终稿）
func _type_color(node_type: String) -> Color:
	match node_type:
		"battle":
			return Color(0.85, 0.35, 0.30)   # 红
		"event":
			return Color(0.35, 0.60, 0.90)   # 蓝
		"elite":
			return Color(0.75, 0.50, 0.90)   # 紫
		"shop":
			return Color(0.90, 0.80, 0.35)   # 金
		"boss":
			return Color(0.90, 0.20, 0.20)   # 深红
	return Color(0.6, 0.6, 0.6)

# ========== 交互 ==========

func _on_node_pressed(row: int) -> void:
	GameManager.select_route_node(row)
	queue_free()
