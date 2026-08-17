## 路线选择面板（Day 14-15 · D14-15-T4 + G-B · 2026-08-14 R1 大地图）
## 随机节点地图可视化：网格画布（杀戮尖塔式）——全层节点 + 路径连线 + 迷雾规则（O3：
## 前 2 层可见、之后模糊）+ 已走灰显 + 当前层可点选。
## 旧 route_generator 数据结构零改动（routes.json 15 层 × 3 节点仍为数据源）；
## 选本层节点 → GameManager.select_route_node(row)（原 _enter_node 分派零改动）。
## 不暂停游戏（spawner 非 BATTLE 状态自动停，与商店一致）。
extends CanvasLayer

# ========== 节点引用 ==========

@onready var title_label: Label = $CenterContainer/Panel/Margin/VBox/Title
@onready var canvas: Control = $CenterContainer/Panel/Margin/VBox/Canvas

# ========== 状态 ==========

var _route: Dictionary = {}      ## 本局路线（GameManager 传入）
var _layer: int = 0              ## 当前层索引
var buttons: Array[Button] = []  ## 当前层可点按钮（探针/测试可读）
var node_meta: Array = []        ## 全层节点状态（探针断言用）：{row, col, type, state}
var chapter_banners: Array = []  ## 章界横幅（PS-D3 · 探针断言用）：{layer, label}

## 迷雾规则（用户拍板 O3）：当前层 + 前 2 层可见，之后模糊
const FOG_VISIBLE_LAYERS: int = 2

# ========== 生命周期 ==========

func _ready() -> void:
	# 游戏结束（胜利/失败）时若面板仍开着 → 一并释放，防悬挂
	GameManager.game_over.connect(func(_victory: bool) -> void:
		if is_instance_valid(self):
			queue_free()
	)
	canvas.resized.connect(func() -> void: canvas.queue_redraw())

## 由 GameManager 在实例化后调用：渲染全层节点地图
func setup(route_data: Dictionary, layer: int) -> void:
	_route = route_data
	_layer = layer
	_render()

# ========== 渲染（网格画布） ==========

## 节点画布坐标（由数据层推导：行=层、列=节点索引，禁硬编码）
func _layout_pos(row: int, col: int, col_count: int) -> Vector2:
	var canvas_w: float = canvas.size.x if canvas.size.x > 0.0 else 600.0
	var canvas_h: float = canvas.size.y if canvas.size.y > 0.0 else 300.0
	var x: float = canvas_w * (0.5 + (float(col) - (float(col_count) - 1.0) * 0.5) * 0.15)
	var y: float = 24.0 + float(row) * (canvas_h - 40.0) / maxf(float(_route.get("layers", []).size() - 1), 1.0)
	return Vector2(x, y)

func _render() -> void:
	for child in canvas.get_children():
		child.queue_free()
	buttons.clear()
	node_meta.clear()
	chapter_banners.clear()
	var layers: Array = _route.get("layers", [])
	if _layer < 0 or _layer >= layers.size():
		push_warning("[RouteSelectPanel] 层索引越界: %d" % _layer)
		return
	title_label.text = "第 %d 层 · 选择路线（下方迷雾）" % (_layer + 1)
	# 连线（先画，节点盖其上；Line2D 而非 Control._draw——CanvasLayer 无 _draw）
	_draw_paths(layers)
	# 章界横幅（PS-D3：纯新增渲染层，_layout_pos/_render/_draw_paths 语义零改动）
	_render_chapter_banners(layers)
	# 节点
	for row in range(layers.size()):
		var layer_nodes: Array = layers[row]
		for col in range(layer_nodes.size()):
			var node_data: Dictionary = layer_nodes[col]
			_create_node(row, col, str(node_data.get("type", "?")), layer_nodes.size(), layers.size())

## 章界横幅（PS-D3 · 2026-08-17）：每章起始层上方「第 N 章」Label + Line2D 分隔线。
## 数据驱动 route.chapters（缺省空 → 零显示零改动兼容旧 routes.json）；占位标准 = 色块 + Label 零美术
## （08-07 美术策略遵守）。挂载时机 = _draw_paths 后、节点创建前（横幅在连线之上、节点之下，z 序不冲突）。
func _render_chapter_banners(layers: Array) -> void:
	var chapters: Array = _route.get("chapters", [])
	if chapters.is_empty():
		return
	var canvas_w: float = canvas.size.x if canvas.size.x > 0.0 else 600.0
	for ci in chapters.size():
		var ch: Dictionary = chapters[ci]
		var ch_layers: Array = ch.get("layers", [])
		if ch_layers.is_empty():
			continue
		var start_1based: int = int(ch_layers[0])  # 章起始层（1-based）
		var row: int = start_1based - 1            # 0-based
		if row < 0 or row >= layers.size():
			continue
		var col_count: int = (layers[row] as Array).size()
		var y: float = _layout_pos(row, 0, col_count).y - 14.0
		# 分隔线（章起始层上方）
		var line := Line2D.new()
		line.points = PackedVector2Array([Vector2(12, y), Vector2(canvas_w - 12, y)])
		line.width = 1.0
		line.default_color = Color(0.95, 0.85, 0.45, 0.7)
		canvas.add_child(line)
		# 章横幅 Label
		var lbl := Label.new()
		lbl.text = "第 %d 章" % (ci + 1)
		lbl.add_theme_font_size_override("font_size", 9)
		lbl.add_theme_color_override("font_color", Color(0.95, 0.9, 0.6))
		lbl.position = Vector2(12, y - 13)
		canvas.add_child(lbl)
		chapter_banners.append({"layer": row, "label": lbl})

## 路径连线：相邻层节点间细线（Line2D；已走区域熄灭）
func _draw_paths(layers: Array) -> void:
	for row in range(layers.size()):
		var cols: Array = layers[row]
		if row + 1 >= layers.size():
			continue
		var next_cols: Array = layers[row + 1]
		var line_color: Color = Color(0.5, 0.5, 0.55, 0.6)
		if row < _layer:
			line_color = Color(0.3, 0.3, 0.32, 0.4)  # 已走路径熄灭
		for col in range(cols.size()):
			var from: Vector2 = _layout_pos(row, col, cols.size()) + Vector2(0, 11)
			for nc in range(next_cols.size()):
				var to: Vector2 = _layout_pos(row + 1, nc, next_cols.size()) - Vector2(0, 11)
				var line := Line2D.new()
				line.points = PackedVector2Array([from, to])
				line.width = 1.0
				line.default_color = line_color
				canvas.add_child(line)

## 创建单个节点（状态推导：visited/current/visible/fogged）
func _create_node(row: int, col: int, node_type: String, col_count: int, row_count: int) -> void:
	var state: String = "visible"
	if row < _layer:
		state = "visited"
	elif row == _layer:
		state = "current"
	elif row > _layer + FOG_VISIBLE_LAYERS:
		state = "fogged"
	var pos: Vector2 = _layout_pos(row, col, col_count)
	var label_text: String = _type_label(node_type)
	# 当前层 → 可点 Button；其余 → 色块 + Label（灰显/迷雾）
	if state == "current":
		var btn := Button.new()
		btn.text = label_text
		btn.custom_minimum_size = Vector2(44, 22)
		btn.add_theme_font_size_override("font_size", 9)
		btn.add_theme_stylebox_override("normal", _make_style(_type_color(node_type)))
		btn.position = pos - Vector2(22, 11)
		btn.pressed.connect(_on_node_pressed.bind(col))
		canvas.add_child(btn)
		buttons.append(btn)
	else:
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(44, 22)
		panel.position = pos - Vector2(22, 11)
		panel.add_theme_stylebox_override("panel", _make_style(_state_color(state, node_type)))
		var lbl := Label.new()
		lbl.text = label_text
		lbl.add_theme_font_size_override("font_size", 8)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		# 迷雾/已走：标签灰显
		if state == "fogged" or state == "visited":
			lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
		panel.add_child(lbl)
		canvas.add_child(panel)
	node_meta.append({"row": row, "col": col, "type": node_type, "state": state})

## 占位样式：色块 + 1px 边框（类型色 / 灰显态色）
func _make_style(base_color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = base_color
	sb.set_border_width_all(1)
	sb.border_color = Color(1, 1, 1, 0.35)
	sb.set_corner_radius_all(3)
	return sb

## 状态着色：visited/fogged 灰显（迷雾层更深），visible 保留类型色
func _state_color(state: String, node_type: String) -> Color:
	var c: Color = _type_color(node_type)
	match state:
		"visited":
			return Color(0.32, 0.32, 0.34)
		"fogged":
			return Color(0.20, 0.20, 0.22)
		"visible":
			return c.darkened(0.25)
	return c

# ========== 交互 ==========
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
