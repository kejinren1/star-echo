## UI 面板工厂（阶段 F · F2-T6 从 GameManager 拆分 · 2026-08-12）
## 职责：面板实例化 + 挂载 UI 层（原 GM._spawn_game_over_panel / _add_to_ui_layer）。
## 由 GameManager._ready 创建并持有；GameOver 面板实例状态（_game_over_panel 防重复）
## 迁至本节点；stage/reason 文案由 GM.end_game 算好传入（依赖 current_wave/current_layer/
## route 状态，工厂不依赖 GM 保持职责单一——F2-T6 拆分语义）。
extends Node

# ========== 资源引用 ==========

const GameOverPanelScene: PackedScene = preload("res://scenes/GameOverPanel.tscn")

# ========== 状态 ==========

var _game_over_panel: Node = null   ## GameOver 面板引用（防重复实例化）

# ========== 挂载 ==========

## 面板挂载到 UI 层（原 GM._add_to_ui_layer：优先当前场景（Main），无 current_scene
## （无头测试直接 add 到 root）时挂 root）。静态方法供 GM/EventManager 通用复用
static func add_to_ui_layer(tree: SceneTree, panel: Node) -> void:
	var target: Node = tree.current_scene if tree.current_scene else tree.root
	target.add_child(panel)

# ========== 面板工厂 ==========

## D4-T7（BUG-001-F1）：死亡/胜利结果面板（原 GM._spawn_game_over_panel）。
## reason 文案（含 F-26 关卡制「第 N 关阵亡」）由 GM 计算传入
func spawn_game_over_panel(ui_layer: Node, victory: bool, reason: String) -> void:
	if _game_over_panel != null and is_instance_valid(_game_over_panel):
		return
	_game_over_panel = GameOverPanelScene.instantiate()
	var panel: Node = _game_over_panel
	panel.tree_exited.connect(func() -> void:
		if _game_over_panel == panel:
			_game_over_panel = null
	)
	# 先入树再 setup（@onready 节点引用须在 _ready 之后才可用）
	ui_layer.add_child(panel)
	if panel.has_method("setup"):
		panel.setup(victory, reason)
