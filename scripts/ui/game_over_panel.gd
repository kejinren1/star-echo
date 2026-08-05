## Game Over 结果面板（Day 4 · D4-T7，BUG-001-F1 收口）
## 玩家死亡/胜利时由 GameManager 实例化；显示结果标题与说明，
## 「重新开始」→ 解除暂停并重载当前场景（回 Main 重开本局）。
## 节点 process_mode = WHEN_PAUSED（游戏暂停期间可交互）。
extends CanvasLayer

# ========== 节点引用 ==========

@onready var title_label: Label = $CenterContainer/Panel/Margin/VBox/Title
@onready var reason_label: Label = $CenterContainer/Panel/Margin/VBox/Reason
@onready var restart_button: TextureButton = $CenterContainer/Panel/Margin/VBox/RestartButton

# ========== 生命周期 ==========

func _ready() -> void:
	restart_button.pressed.connect(_on_restart_pressed)

## 由 GameManager._spawn_game_over_panel 调用
func setup(victory: bool, reason: String) -> void:
	title_label.text = "胜利！" if victory else "你已阵亡"
	reason_label.text = reason

# ========== 交互 ==========

## 重新开始：解除暂停 → 重载当前场景（Main 重开本局）
## 无头测试场景 current_scene 可能为 null（直接 add 到 root）→ 仅解除暂停并销毁自身，零 error
func _on_restart_pressed() -> void:
	get_tree().paused = false
	if get_tree().current_scene:
		get_tree().reload_current_scene()
	else:
		queue_free()
