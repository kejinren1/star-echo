## 主菜单（G-A · 2026-08-14 · R2 集成战略式入口）
## 动态构建按钮列（仿 CharacterSelect 范式）；占位标准 = 全屏 Control + 色块 + Label
## 入口：开始游戏→CharacterSelect / 方舟基地→BaseStation / 图鉴→CodexPanel /
##       回廊→ArchivePanel / 技能树→SkillTreePanel（后三者面板 G-C/G-E 就绪后接线）
extends Control

# ========== 场景路径 ==========

const CHARACTER_SELECT_SCENE: String = "res://scenes/CharacterSelect.tscn"
const BASE_STATION_SCENE: String = "res://scenes/BaseStation.tscn"
const CODEX_SCENE: String = "res://scenes/CodexPanel.tscn"
const ARCHIVE_SCENE: String = "res://scenes/ArchivePanel.tscn"
const SKILL_TREE_SCENE: String = "res://scenes/SkillTreePanel.tscn"

# ========== 入口定义（探针可读：名称/目标场景） ==========
## 图鉴/回廊 G-C 就绪已接线；技能树 G-E 批次接线
var entries: Array = [
	{"label": "⚔ 开始游戏", "scene": CHARACTER_SELECT_SCENE, "ready": true},
	{"label": "🏛 方舟基地", "scene": BASE_STATION_SCENE, "ready": true},
	{"label": "📖 图鉴", "scene": CODEX_SCENE, "ready": true},
	{"label": "🏺 回廊", "scene": ARCHIVE_SCENE, "ready": true},
	{"label": "🌳 技能树", "scene": SKILL_TREE_SCENE, "ready": false},
]

var buttons: Array[Button] = []  ## 探针可读

# ========== 生命周期 ==========

func _ready() -> void:
	_build_entries()

func _build_entries() -> void:
	var root := get_node_or_null("Root")
	if root == null:
		return
	for entry in entries:
		var btn := Button.new()
		btn.text = str(entry["label"])
		btn.custom_minimum_size = Vector2(0, 40)
		btn.add_theme_font_size_override("font_size", 16)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.pressed.connect(_on_entry_pressed.bind(str(entry["scene"]), bool(entry["ready"])))
		root.add_child(btn)
		buttons.append(btn)

func _on_entry_pressed(scene_path: String, ready: bool) -> void:
	if not ready:
		# 占位先行：面板未就绪 → 提示不跳转（G-C/G-E 批次接线后置 ready=true）
		print("[MainMenu] 入口 %s 开发中（占位）" % scene_path)
		return
	get_tree().change_scene_to_file(scene_path)
