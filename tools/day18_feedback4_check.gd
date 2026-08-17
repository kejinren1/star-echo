## Day 18-FB4 出口校验：F-22 星刃进化特效变色 + F-23 结算返回选角（2026-08-08 真人拍板）
##
## 用法（无头，不需要编辑器）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day18_feedback4_check.gd
##
## 校验内容（对应 docs/PLAYTEST_CHECKLIST.md 未解决问题追踪区）：
##   §1 F-22 数据透传：build_weapon_from_data 对 se_star_blade（基础）不带 evolution_result meta、
##      se_blade_storm（进化结果）带 evolution_result=true；storm arc_angle=150（PS 2026-08-17 星刃 orbit→扇形重构）
##   §2 F-22 渲染差异：基础星刃刀光蓝白 (0.65,0.85,1.0)；进化星刃风暴刀光金色
##      (1.0,0.78,0.2) + 扇形角 150° > 100°——「买核心进化无直观感受」修复
##   §3 F-23 面板接线：GameOverPanel 含 BackToSelectButton（文本「返回选角」+ pressed 信号连接），
##      重开按钮不受影响
##   §4 F-23 行为：_on_back_to_select_pressed 前半段 GameManager.reset()（paused 解除 + 状态清空）；
##      真实切换：临时 current_scene → 调按钮 → 下一帧 current_scene 变 CharacterSelect
##
## 退出码 0 = 全部通过；非 0 = 失败项数。
extends SceneTree

const GAME_OVER_SCENE: String = "res://scenes/GameOverPanel.tscn"
const BLADE_BASE_COLOR := Color(0.65, 0.85, 1.0)
const BLADE_EVOLVED_COLOR := Color(1.0, 0.78, 0.2)
const EVOLVED_SCALE: float = 1.25
const EPSILON: float = 0.001

var _sub: int = 0
var _ready_mocks: bool = false
var _loader: Node = null
var _gm: Node = null
var _checked: int = 0
var _failures: int = 0

func _initialize() -> void:
	print("=== Day 18-FB4 check (F-22 星刃进化变色 / F-23 结算返回选角) ===")

func _process(_delta: float) -> bool:
	if not _ready_mocks:
		_load_mocks()
		return false
	if _sub > 5:
		_report()
		quit(_failures)
		return true
	_sub = _advance(_sub)
	return false

func _load_mocks() -> void:
	_ready_mocks = true
	_loader = root.get_node_or_null("DataLoader")
	_gm = root.get_node_or_null("GameManager")
	if _loader == null or _gm == null:
		_fail("DataLoader/GameManager autoload 缺失")
		_report()
		quit(1)
		return

# ========== 断言工具 ==========

func _ok(cond: bool, what: String) -> void:
	_checked += 1
	if not cond:
		_failures += 1
		print("  FAIL: " + what)

func _fail(what: String) -> void:
	_checked += 1
	_failures += 1
	print("  FAIL: " + what)

func _pass(what: String) -> void:
	_checked += 1
	print("  PASS: " + what)

func _report() -> void:
	print("=== Day 18-FB4: %d checked, %d failed ===" % [_checked, _failures])

# ========== 分节驱动 ==========

func _advance(sub: int) -> int:
	match sub:
		0:
			_part_f22_data()
			return 1
		1:
			_part_f22_render()
			return 2
		2:
			_part_f23_panel()
			return 3
		3:
			_part_f23_reset()
			return 4
		4:
			_part_f23_switch()
			return 5
		5:
			_verify_switch()
			return 6
	return 6

# ========== §1 F-22 数据透传 ==========

func _part_f22_data() -> void:
	var wc_script: GDScript = load("res://scripts/weapons/weapon_controller.gd")
	var wc = wc_script.new()
	var blade_w: Resource = wc.call("build_weapon_from_data", "se_star_blade")
	var storm_w: Resource = wc.call("build_weapon_from_data", "se_blade_storm")
	if blade_w == null or storm_w == null:
		_fail("F-22/构建: se_star_blade / se_blade_storm 构建失败")
		return
	_ok(not bool(blade_w.get_meta("evolution_result", false)),
		"F-22/透传: 基础星刃 evolution_result meta = false")
	_ok(bool(storm_w.get_meta("evolution_result", false)),
		"F-22/透传: 进化星刃风暴 evolution_result meta = true")
	# Object.get() 只收 1 参（记忆坑：Object vs Dictionary），先 in 判定再取值
	var storm_arc: float = 0.0
	if "arc_angle" in storm_w:
		storm_arc = float(storm_w.get("arc_angle"))
	_ok(storm_arc == 150.0,
		"F-22/数据: 星刃风暴 arc_angle = 150（实得 %s）" % str(storm_arc))

# ========== §2 F-22 渲染差异 ==========

func _part_f22_render() -> void:
	var wc_script: GDScript = load("res://scripts/weapons/weapon_controller.gd")
	var wc = wc_script.new()
	var sweep_script: GDScript = load("res://scripts/weapons/melee_sweep.gd")
	var mock_player := Node2D.new()
	root.add_child(mock_player)
	# 基础星刃：蓝白刀光
	var blade_w: Resource = wc.call("build_weapon_from_data", "se_star_blade")
	var sweep1 = sweep_script.new()
	mock_player.add_child(sweep1)
	sweep1.set_process(false)  # 探针控时：进树后禁用自动处理
	sweep1.call("setup", blade_w, mock_player)
	sweep1.call("_do_slash")   # 挥砍 → 刷新刀光（无敌人容器则仅特效、无伤害）
	var fx1: Polygon2D = sweep1.get("_fx")
	_ok(fx1 != null and fx1.visible, "F-22/基础: 星刃已生成刀光")
	if fx1 != null:
		var c1: Color = fx1.color
		_ok(c1.r == BLADE_BASE_COLOR.r and c1.g == BLADE_BASE_COLOR.g and c1.b == BLADE_BASE_COLOR.b,
			"F-22/基础: 刀光颜色 = 蓝白 %s（实得 %s）" % [str(BLADE_BASE_COLOR), str(c1)])
		var pts1: PackedVector2Array = fx1.polygon
		_ok(pts1.size() >= 3 and pts1[1].length() > 0.0,
			"F-22/基础: 刀光扇形非退化（%d 点）" % pts1.size())
	# 进化星刃风暴：金色刀光 + 更大扇形角（范围质变）
	var storm_w: Resource = wc.call("build_weapon_from_data", "se_blade_storm")
	var sweep2 = sweep_script.new()
	mock_player.add_child(sweep2)
	sweep2.set_process(false)
	sweep2.call("setup", storm_w, mock_player)
	sweep2.call("_do_slash")
	var fx2: Polygon2D = sweep2.get("_fx")
	_ok(fx2 != null and fx2.visible, "F-22/进化: 星刃风暴已生成刀光")
	if fx2 != null:
		var c2: Color = fx2.color
		_ok(c2.r == BLADE_EVOLVED_COLOR.r and c2.g == BLADE_EVOLVED_COLOR.g and c2.b == BLADE_EVOLVED_COLOR.b,
			"F-22/进化: 刀光颜色 = 金色 %s（实得 %s）" % [str(BLADE_EVOLVED_COLOR), str(c2)])
		_ok(not c2.is_equal_approx(BLADE_BASE_COLOR),
			"F-22/差异: 进化金色 ≠ 基础蓝白（视觉可区分）")
		var pts2: PackedVector2Array = fx2.polygon
		_ok(pts2.size() >= 3 and float(storm_w.get("arc_angle")) > float(blade_w.get("arc_angle")),
			"F-22/进化: 扇形角 %.0f° > 基础 %.0f°（范围质变）" % [float(storm_w.get("arc_angle")), float(blade_w.get("arc_angle"))])
	# 清理
	sweep1.queue_free()
	sweep2.queue_free()
	mock_player.queue_free()

# ========== §3 F-23 面板接线 ==========

var _fb4_panel: Node = null

func _part_f23_panel() -> void:
	var panel_scene: PackedScene = load(GAME_OVER_SCENE)
	var panel: Node = panel_scene.instantiate()
	root.add_child(panel)
	_fb4_panel = panel
	var btn: Node = panel.get_node_or_null("CenterContainer/Panel/Margin/VBox/BackToSelectButton")
	_ok(btn != null, "F-23/接线: BackToSelectButton 存在")
	if btn != null:
		var label: Label = btn.get_node_or_null("BackToSelectLabel")
		_ok(label != null and label.text == "返回选角",
			"F-23/接线: 按钮文本 = 「返回选角」（实得 %s）" % (label.text if label else "<无>"))
		_ok(btn.pressed.get_connections().size() >= 1,
			"F-23/接线: pressed 信号已连接（%d 条）" % btn.pressed.get_connections().size())
	_ok(panel.get_node_or_null("CenterContainer/Panel/Margin/VBox/RestartButton") != null,
		"F-23/接线: 原「重新开始」按钮保留（零回归）")

# ========== §4 F-23 行为：reset 清态 ==========

func _part_f23_reset() -> void:
	# 白盒：直接验证 _on_back_to_select_pressed 前半段（GameManager.reset 语义）
	_gm.call("reset")
	_ok(not paused, "F-23/行为: reset 解除暂停")
	_ok(int(_gm.get("current_state")) == 0,
		"F-23/行为: reset 状态回 MENU（实得 %d）" % int(_gm.get("current_state")))
	_ok(_gm.get("_game_over_panel") == null,
		"F-23/行为: reset 清空 _game_over_panel 引用")

# ========== §5 F-23 行为：真实切换回 CharacterSelect ==========

func _part_f23_switch() -> void:
	# 临时 current_scene（change_scene_to_file 要求 current_scene 非空），面板挂其下
	var tmp := Node2D.new()
	tmp.name = "FB4TmpScene"
	root.add_child(tmp)
	current_scene = tmp
	_fb4_panel.reparent(tmp)
	var btn: Node = _fb4_panel.get_node("CenterContainer/Panel/Margin/VBox/BackToSelectButton")
	btn.emit_signal("pressed")
	# change_scene_to_file 为 deferred 切换 → 下一帧 _verify_switch 断言

func _verify_switch() -> void:
	var cs: Node = current_scene
	var ok_switch: bool = cs != null and cs.name == "CharacterSelect"
	_ok(ok_switch, "F-23/切换: 按钮按下 → current_scene 变为 CharacterSelect（实得 %s）" % (cs.name if cs else "<null>"))
	# 恢复现场：释放临时/切换产物并清 current_scene（探针即将退出，防泄漏）
	if cs != null:
		cs.queue_free()
	current_scene = null
