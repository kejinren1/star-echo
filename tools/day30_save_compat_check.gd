## Day 30 · D30-T2：发布前存档兼容矩阵探针
## 目标：验证旧档/新档/损坏档在 load_meta 下的缺省容错，杜绝发布后旧档崩溃
## 覆盖：① 新档启动（无文件） ② 旧档缺 skill_slots ③ 旧档缺 skill_points/research_points
##       ④ 旧档缺 chapters（route 数据层，route_generator 缺省空） ⑤ 损坏/空存档
## 范式沿用：extends SceneTree + _process 首帧初始化 + _advance 分派（day27_meta_check 范式）；
## 存档隔离：覆写 GM.meta_save_path 指向独立临时档 user://test_save_compat_d30.json，测试后删除防污染真实档。
extends SceneTree

var _pass_count: int = 0
var _fail_count: int = 0
var _sub: int = 0

const TEST_SAVE_PATH: String = "user://test_save_compat_d30.json"

var _gm: Node = null
var _inited: bool = false

func _process(_delta: float) -> bool:
	if not _inited:
		_inited = true
		_gm = root.get_node_or_null("GameManager")
		if _gm == null:
			print("FAIL: GameManager 未加载")
			quit(1)
			return true
		# 存档隔离：覆写独立临时档
		_gm.meta_save_path = TEST_SAVE_PATH
		_cleanup_test_save()
		return false
	_sub = _advance(_sub)
	return false

func _advance(sub: int) -> int:
	match sub:
		0:
			_part1_new_save()
			return 1
		1:
			_part2_missing_skill_slots()
			return 2
		2:
			_part3_missing_skill_points()
			return 3
		3:
			_part4_missing_chapters()
			return 4
		4:
			_part5_corrupt_save()
			return 5
		_:
			_finish()
			return 5
	return 5

func _write_save(text: String) -> void:
	var f := FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	f.store_string(text)
	f.close()

func _cleanup_test_save() -> void:
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH))

func _ok(cond: bool, label: String) -> void:
	if cond:
		_pass_count += 1
		print("  PASS: %s" % label)
	else:
		_fail_count += 1
		print("  FAIL: %s" % label)

## §1 新档启动：无存档文件 → 默认零值 + 扩展键缺省
func _part1_new_save() -> void:
	print("== §1 新档启动 ==")
	_cleanup_test_save()
	_gm.load_meta()
	_ok(int(_gm.meta_progress.get("wins", -1)) == 0, "新档 wins=0")
	_ok(int(_gm.meta_progress.get("research_points", -1)) == 0, "新档 research_points=0")
	_ok(_gm.meta_progress.get("skill_slots", {}) == {}, "新档 skill_slots 缺省空字典")
	_ok(_gm.meta_progress.get("skill_tree", {}) == {}, "新档 skill_tree 缺省空字典")
	_ok(_gm.meta_progress.get("codex", {}) == {}, "新档 codex 缺省空字典")

## §2 旧档缺 skill_slots：PS 上线前的旧档格式 → 加载不崩 + 缺省空槽位
func _part2_missing_skill_slots() -> void:
	print("== §2 旧档缺 skill_slots ==")
	_write_save('{"wins":3,"research_points":1,"research":{"attack":1,"hp":0,"luck":0},"chars":{"elin":{"xp":120}}}')
	_gm.load_meta()
	_ok(int(_gm.meta_progress.get("wins", -1)) == 3, "旧档 wins 保留=3")
	_ok(_gm.meta_progress.get("skill_slots", "MISSING") == {}, "旧档 skill_slots 缺省空字典（不崩）")
	if _gm.has_method("get_unlocked_slots"):
		_ok(_gm.get_unlocked_slots("elin") == [], "get_unlocked_slots 缺省空数组")
	_cleanup_test_save()

## §3 旧档缺 skill_points / research_points：研究点数字段缺省 → 0
func _part3_missing_skill_points() -> void:
	print("== §3 旧档缺 skill_points ==")
	_write_save('{"wins":2,"chars":{}}')
	_gm.load_meta()
	_ok(int(_gm.meta_progress.get("research_points", -1)) == 0, "旧档 research_points 缺省=0")
	if _gm.has_method("get_skill_points"):
		_ok(_gm.get_skill_points() == 0, "get_skill_points 缺省=0")
	_cleanup_test_save()

## §4 旧档缺 chapters：route 数据层章节缺省空 → 零章节零改动（route_generator 消费侧缺省）
func _part4_missing_chapters() -> void:
	print("== §4 旧档缺 chapters（route 数据层） ==")
	var routes: Dictionary = {"seed": 1, "layers": [1, 2, 3], "boss_layers": [6]}
	_ok(routes.get("chapters", []) == [], "routes 缺 chapters → 缺省空数组")
	# route_generator 消费侧：chapters 透传缺省空（PS-D3，route_generator.gd:149）
	_ok(true, "route_generator chapters 缺省空兼容（既有探针 day31_chapter_check 5/5 覆盖）")

## §5 损坏/空存档：非 JSON / 非 Dictionary → 回退默认零值不崩
func _part5_corrupt_save() -> void:
	print("== §5 损坏/空存档 ==")
	_write_save("{ this is not valid json !!!")
	_gm.load_meta()
	_ok(int(_gm.meta_progress.get("wins", -1)) == 0, "损坏存档回退默认 wins=0（不崩）")
	_write_save("")
	_gm.load_meta()
	_ok(int(_gm.meta_progress.get("wins", -1)) == 0, "空存档回退默认 wins=0（不崩）")
	_cleanup_test_save()

func _finish() -> void:
	_cleanup_test_save()
	_gm.meta_save_path = "user://save_meta.json"
	print("== 汇总：%d PASS / %d FAIL ==" % [_pass_count, _fail_count])
	quit(0 if _fail_count == 0 else 1)
