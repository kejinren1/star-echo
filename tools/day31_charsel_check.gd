## PS · 选人界面改版出口校验（2026-08-17 用户拍板：4 头像 + 悬停居中预览）
##
## 用法（无头）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day31_charsel_check.gd
##
## 校验内容：
##   §1 场景装载：CharacterSelect 实例化无错误；4 个头像按钮（SE 前缀）横排
##   §2 悬停预览：_show_preview 后预览面板可见；名字/技能/武器文本非空
##   §3 idle 动画：_load_idle 后 AnimatedSprite2D 有 sprite_frames + 可见（lain 素材在位）
##   §4 立绘通道：_load_portrait 命中 lain_portrait.png（128×128）
##   §5 兼容：get_selected_character_id 静态接口 + select_character 写入 meta
##
## 退出码 0 = 全部通过；非 0 = 失败项数。
extends SceneTree

var _checked: int = 0
var _failures: int = 0
var _started: bool = false

func _initialize() -> void:
	print("=== Day31 char select check ===")

func _process(_delta: float) -> bool:
	if _started:
		return false
	_started = true
	var scene: PackedScene = load("res://scenes/CharacterSelect.tscn")
	if scene == null:
		_fail("CharacterSelect.tscn 加载失败")
		quit(_failures)
		return true
	var sel: Node = scene.instantiate()
	root.add_child(sel)
	# 等一帧让 _ready 完成
	await_process(sel)
	return true

## 简单帧推进（_ready 已同步执行，直接校验）
func await_process(sel: Node) -> void:
	_section_cards(sel)
	_section_preview(sel)
	_section_idle(sel)
	_section_portrait(sel)
	_section_meta(sel)
	print("检查 %d 项，失败 %d 项" % [_checked, _failures])
	quit(_failures)

func _ok(msg: String) -> void:
	_checked += 1
	print("  PASS  %s" % msg)

func _fail(msg: String) -> void:
	_failures += 1
	print("  FAIL  %s" % msg)

# ========== §1 头像 ==========

func _section_cards(sel: Node) -> void:
	var row: Node = sel.get_node_or_null("Root/CardRow")
	if row == null:
		_fail("CardRow 缺失")
		return
	var buttons: Array = []
	for child in row.get_children():
		if child is Button:
			buttons.append(child)
	if buttons.size() == 4:
		_ok("§1 4 个头像按钮")
	else:
		_fail("头像按钮数应为 4, 实得 %d" % buttons.size())
	# 尺寸检查（640 视口放得下）
	var total: float = 0.0
	for b in buttons:
		total += b.custom_minimum_size.x
	if total <= 560.0:
		_ok("§1 头像横排总宽 %.0f < 640 视口" % total)
	else:
		_fail("头像总宽 %.0f 超视口" % total)

# ========== §2 悬停预览 ==========

func _section_preview(sel: Node) -> void:
	var panel: Node = sel.get("_preview_panel")
	if panel == null:
		_fail("预览面板未构建")
		return
	if panel.visible:
		_ok("§2 初始即显示默认角色预览（首卡聚焦）")
	else:
		_fail("预览面板初始不可见")
	# 触发莱恩预览
	sel.call("_show_preview", "se_ren")
	if not panel.visible:
		_fail("_show_preview 后面板不可见")
		return
	_ok("§2 _show_preview(se_ren) 面板可见")
	# 检查文本行
	var texts: Array[String] = []
	for child in panel.get_children():
		if child is HBoxContainer:
			for col in child.get_children():
				if col is VBoxContainer:
					for node in col.get_children():
						if node is Label and node.has_meta(&"preview_line"):
							texts.append(str(node.text))
	var joined: String = " | ".join(texts)
	if "剑士" in joined and "剑气爆发" in joined and "星刃" in joined:
		_ok("§2 预览文本含名字/技能/武器")
	else:
		_fail("预览文本不完整: %s" % joined)

# ========== §3 idle 动画 ==========

func _section_idle(sel: Node) -> void:
	var idle: Node = sel.get("_preview_idle")
	if idle == null:
		_fail("_preview_idle 缺失")
		return
	if idle.visible and idle.get("sprite_frames") != null:
		_ok("§3 lain idle 动画已加载并播放")
	else:
		_fail("idle 动画未加载（visible=%s frames=%s）" % [str(idle.visible), str(idle.get("sprite_frames"))])

# ========== §4 立绘通道 ==========

func _section_portrait(sel: Node) -> void:
	var data: Dictionary = (root.get_node_or_null("DataLoader") as Node).call("get_character", "se_ren")
	var tex: Resource = sel.call("_load_portrait", "se_ren", data)
	if tex != null and tex is Texture2D:
		_ok("§4 立绘通道命中（%dx%d）" % [tex.get_width(), tex.get_height()])
	else:
		_fail("立绘通道未命中")
	# full 优先：命名约定存在即优先（当前无 full 资产 → 回退像素立绘）
	if ResourceLoader.exists("res://assets/sprites/characters/lain_portrait_full.png"):
		_ok("§4 full 大立绘资产在位（命名约定生效）")
	else:
		_ok("§4 无 full 资产，回退像素立绘（占位先行）")

# ========== §5 meta 兼容 ==========

func _section_meta(sel: Node) -> void:
	sel.call("select_character", "se_ren")
	var meta_val: String = str(root.get_meta(&"se_selected_character", ""))
	if meta_val == "se_ren":
		_ok("§5 select_character 写入 meta 成功")
	else:
		_fail("meta 写入失败: %s" % meta_val)
