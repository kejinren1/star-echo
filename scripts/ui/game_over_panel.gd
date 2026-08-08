## Game Over 结果面板（Day 4 · D4-T7，BUG-001-F1 收口）
## 玩家死亡/胜利时由 GameManager 实例化；显示结果标题与说明，
## 「重新开始」→ 解除暂停并重载当前场景（回 Main 重开本局）；
## 「返回选角」（F-23，用户拍板 2026-08-08）→ 清局内状态并切回
## CharacterSelect——局外成长（研究/角色XP/剧情）从选角页进基地验证。
## 节点 process_mode = WHEN_PAUSED（游戏暂停期间可交互）。
extends CanvasLayer

# ========== 节点引用 ==========

@onready var title_label: Label = $CenterContainer/Panel/Margin/VBox/Title
@onready var reason_label: Label = $CenterContainer/Panel/Margin/VBox/Reason
@onready var restart_button: TextureButton = $CenterContainer/Panel/Margin/VBox/RestartButton
@onready var back_to_select_button: TextureButton = $CenterContainer/Panel/Margin/VBox/BackToSelectButton

# ========== 生命周期 ==========

func _ready() -> void:
	restart_button.pressed.connect(_on_restart_pressed)
	back_to_select_button.pressed.connect(_on_back_to_select_pressed)

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

## F-23：返回选角——reset 清局内状态（含解除暂停/清引用），随后切换回选角场景。
## 面板挂 current_scene（Main）子节点，切场景时随 Main 一并释放，无需手动清理。
## reset() 会 queue_free 可能残留的路选/事件面板并置空 _game_over_panel 引用，防悬空。
func _on_back_to_select_pressed() -> void:
	GameManager.reset()
	var err := get_tree().change_scene_to_file("res://scenes/CharacterSelect.tscn")
	if err != OK:
		push_error("[GameOverPanel] 切回选角场景失败 (错误码 %d)" % err)
