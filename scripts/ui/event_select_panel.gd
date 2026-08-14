## 事件选择面板（Day 16 · D16-T1）
## 随机节点地图事件节点：展示事件描述 + 选项 A/B，玩家抉择后由 GameManager 结算。
## 暂停式弹窗（同 LevelUpPanel：paused=true + PROCESS_MODE_WHEN_PAUSED + game_over 防悬挂）：
## 事件是阅读+抉择，必须暂停（与商店/选层「不暂停」范式区分，D14-15 已定）。
extends CanvasLayer

# ========== 节点引用 ==========

@onready var title_label: Label = $CenterContainer/Panel/Margin/VBox/Title
@onready var theme_label: Label = $CenterContainer/Panel/Margin/VBox/Theme
@onready var description_label: Label = $CenterContainer/Panel/Margin/VBox/Description
@onready var choice_a_button: Button = $CenterContainer/Panel/Margin/VBox/OptionA/ChoiceA
@onready var reward_label: Label = $CenterContainer/Panel/Margin/VBox/OptionA/RewardLabel
@onready var choice_b_button: Button = $CenterContainer/Panel/Margin/VBox/OptionB/ChoiceB
@onready var effect_label: Label = $CenterContainer/Panel/Margin/VBox/OptionB/EffectLabel

# ========== 状态 ==========

var _event_data: Dictionary = {}   ## 当前事件（GameManager 传入）

# ========== 生命周期 ==========

func _ready() -> void:
	# 游戏结束（胜利/失败）时若面板仍开着 → 一并释放，防悬挂（配合 GameManager 的 paused）
	GameManager.game_over.connect(func(_victory: bool) -> void:
		if is_instance_valid(self):
			queue_free()
	)
	choice_a_button.pressed.connect(_on_choice_pressed.bind("A"))
	choice_b_button.pressed.connect(_on_choice_pressed.bind("B"))

## 由 GameManager 在实例化后调用：渲染事件内容（长文本 description 由 tscn 的
## autowrap_mode=WORD_SMART 自动换行，面板 ~540×300 内可读，视口 640×360）
func setup(event_data: Dictionary) -> void:
	_event_data = event_data
	# G-C（R3 图鉴）：事件展示即记录（去重零开销）
	GameManager.record_codex("event", str(event_data.get("id", "")))
	title_label.text = str(event_data.get("title", "事件"))
	theme_label.text = str(event_data.get("theme", ""))
	description_label.text = str(event_data.get("description", ""))
	var choice_a: Dictionary = event_data.get("choiceA", {})
	var choice_b: Dictionary = event_data.get("choiceB", {})
	choice_a_button.text = str(choice_a.get("text", "选择"))
	var reward: Dictionary = choice_a.get("reward", {})
	if not reward.is_empty():
		reward_label.text = str(reward.get("label", ""))
	else:
		reward_label.text = ""
	choice_b_button.text = str(choice_b.get("text", "选择"))
	var effect: Dictionary = choice_b.get("effect_on_route", {})
	if not effect.is_empty():
		effect_label.text = str(effect.get("label", ""))
	else:
		effect_label.text = ""

# ========== 交互 ==========

## 选项点击 → GameManager 结算 + 推进；面板自行释放（GameManager 不重复 free，防双释放）
func _on_choice_pressed(choice: String) -> void:
	GameManager.resolve_event_choice(choice)
	queue_free()
