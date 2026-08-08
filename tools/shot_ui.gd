## 临时截图工具：渲染 CharacterSelect 并保存 PNG，验证 canvas_items + 系统字体后的文本清晰度
## 用法（窗口模式，勿加 --headless）:
##   tools/Godot_v4.3-stable_win64.exe --path . --script res://tools/shot_ui.gd --resolution 1280x720
extends SceneTree

const SHOT_PATH: String = "D:/30DAYS/tools/ui_shot.png"

var _frame: int = 0
var _inst: Node = null

func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		var packed: PackedScene = load("res://scenes/CharacterSelect.tscn") as PackedScene
		_inst = packed.instantiate()
		root.add_child(_inst)
	if _frame == 20:
		var img: Image = root.get_texture().get_image()
		img.save_png(SHOT_PATH)
		print("[shot_ui] saved: ", SHOT_PATH)
		quit(0)
		return true
	return false
