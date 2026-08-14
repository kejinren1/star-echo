## 技能树面板（G-E · 2026-08-14 · R6 跨局养成）
## 树状分层按钮（占位：分层布局 + 前置锁定态——前置未解锁节点灰显不可点）；
## 解锁消耗技能点并持久化；效果注入局内 = 与 meta research 同链路（apply_stat_modifier，
## O2 拍板独立并存 research 保留）；MainMenu 技能树入口接线
extends Control

const MAIN_MENU_SCENE: String = "res://scenes/MainMenu.tscn"

var _nodes: Array = []
var _node_buttons: Dictionary = {}  ## node_id → Button

@onready var tree_box: VBoxContainer = $Root/TreeBox
@onready var points_label: Label = $Root/PointsLabel

func _ready() -> void:
	# 返回主菜单
	var back_btn := Button.new()
	back_btn.text = "← 返回主菜单"
	back_btn.add_theme_font_size_override("font_size", 10)
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)
	)
	$Root.add_child(back_btn)
	# 数据：DataLoader.get_skill_tree（gen_skill_tree.py 生成；缺失空态零崩）
	_nodes = DataLoader.get_skill_tree().get("nodes", []) if DataLoader else []
	_build_tree()
	_refresh()

## 树状分层：每节点一行（indent = 层级深度，pre 挂链推导）
func _build_tree() -> void:
	# 按前置深度排序（根节点 0，其后代 +1）
	var depth: Dictionary = {}
	for n in _nodes:
		depth[str(n.get("id", ""))] = _calc_depth(str(n.get("id", "")), {})
	for n in _nodes:
		var nid: String = str(n.get("id", ""))
		var btn := Button.new()
		btn.text = "%s %s（%d 点）" % [str(n.get("name", nid)), str(n.get("desc", "")), int(n.get("cost", 1))]
		btn.add_theme_font_size_override("font_size", 10)
		btn.custom_minimum_size = Vector2(0, 28)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.pressed.connect(_on_node_pressed.bind(nid))
		var indent: int = int(depth.get(nid, 0))
		var wrap := HBoxContainer.new()
		wrap.add_theme_constant_override("separation", 8)
		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(30 * indent, 1)
		wrap.add_child(spacer)
		wrap.add_child(btn)
		tree_box.add_child(wrap)
		_node_buttons[nid] = btn

func _calc_depth(nid: String, memo: Dictionary) -> int:
	if memo.has(nid):
		return int(memo[nid])
	var node: Dictionary = {}
	for n in _nodes:
		if str(n.get("id", "")) == nid:
			node = n
			break
	var prereq: String = str(node.get("prereq", ""))
	if prereq == "":
		memo[nid] = 0
		return 0
	memo[nid] = 1 + _calc_depth(prereq, memo)
	return int(memo[nid])

## 刷新按钮态：已解锁置灰不可点 / 前置未解锁灰显 / 点数不足置灰
func _refresh() -> void:
	var points: int = GameManager.get_skill_points() if GameManager else 0
	var unlocked: Array = GameManager.get_unlocked_skills() if GameManager else []
	points_label.text = "技能点：%d" % points
	for n in _nodes:
		var nid: String = str(n.get("id", ""))
		var btn: Button = _node_buttons.get(nid)
		if btn == null:
			continue
		var prereq: String = str(n.get("prereq", ""))
		var prereq_ok: bool = prereq == "" or unlocked.has(prereq)
		var can_unlock: bool = prereq_ok and int(n.get("cost", 1)) <= points
		if unlocked.has(nid):
			btn.disabled = true
			btn.text = "✓ " + btn.text
		elif prereq_ok:
			btn.disabled = not can_unlock
		else:
			btn.disabled = true

## 解锁：前置满足 + 点数足够 → 扣点持久化 + 效果注入当前局（apply_stat_modifier 链路）
func _on_node_pressed(nid: String) -> void:
	if not GameManager.unlock_skill(nid):
		return
	# 效果注入局内（与 meta research 同链路；玩家未在局（主菜单打开）→ 静默跳过，进局经
	# main._apply_meta_bonus 读取 skill_tree 全量注入——见 main.gd 扩展）
	if GameManager.player and GameManager.player.has_method("apply_stat_modifier"):
		var node: Dictionary = {}
		for n in _nodes:
			if str(n.get("id", "")) == nid:
				node = n
				break
		var effect: Dictionary = node.get("effect", {})
		var stat: String = str(effect.get("stat", ""))
		if stat != "":
			GameManager.player.apply_stat_modifier(stat, float(effect.get("value", 0.0)), bool(effect.get("mult", false)))
	_refresh()
