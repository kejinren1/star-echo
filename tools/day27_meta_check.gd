## Day 27 · D27-T6：局外养成五段探针（存档读写 / 研究升级与增益 / 角色 XP 结算 / 剧情解锁门槛 / 回归抽样）
## 范式沿用：extends SceneTree + _advance 分派全部 sub + 白盒直构造；
## D44：覆写 GameManager.meta_save_path 独立临时档（user://test_meta_d27.json），测试后删除防污染真实存档；
## --script 编译期 Autoload 标识符未注册（day18_19 坑）→ 运行期 root.get_node_or_null 获取 GameManager/DataLoader
extends SceneTree

var _pass_count: int = 0
var _fail_count: int = 0
var _sub: int = 0

const TEST_SAVE_PATH: String = "user://test_meta_d27.json"

var _gm: Node = null
var _dl: Node = null
var _inited: bool = false

## 每帧驱动：首帧初始化（Autoload 挂载后），随后 _advance 推进 sub（day24_f13 范式）
func _process(_delta: float) -> bool:
	if not _inited:
		_inited = true
		_gm = root.get_node_or_null("GameManager")
		_dl = root.get_node_or_null("DataLoader")
		if _gm == null or _dl == null:
			print("FAIL: GameManager/DataLoader 未加载")
			quit(1)
			return true
		# D44：存档隔离——覆写独立档 + 清理残留 + 初始化为零值
		_gm.meta_save_path = TEST_SAVE_PATH
		_cleanup_test_save()
		_gm.meta_progress = _zero_meta()
		_gm.load_meta()
		return false
	_sub = _advance(_sub)
	return false

func _advance(sub: int) -> int:
	match sub:
		0:
			_part1_save_io()
			return 1
		1:
			_part2_research()
			return 2
		2:
			_part3_xp_settle()
			return 3
		3:
			_part4_story_unlock()
			return 4
		4:
			_part5_regression_sample()
			return 5
		_:
			_finish()
			return 5
	return 5
func _zero_meta() -> Dictionary:
	return {
		"wins": 0,
		"research_points": 0,
		"research": {"attack": 0, "hp": 0, "luck": 0},
		"chars": {},
	}

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

# ========== §1 存档读写 ==========

func _part1_save_io() -> void:
	print("== §1 存档读写 ==")
	# 白盒构造 → save_meta → 清空重载 → 断言一致
	_gm.meta_progress = {
		"wins": 3,
		"research_points": 1,
		"research": {"attack": 1, "hp": 0, "luck": 0},
		"chars": {"se_irene": {"xp": 5}},
	}
	_gm.save_meta()
	_gm.meta_progress = {}
	_gm.load_meta()
	var mp: Dictionary = _gm.meta_progress
	_ok(int(mp.get("wins", -1)) == 3, "S1 存档读写 wins 一致 (3)")
	_ok(int(mp.get("research_points", -1)) == 1, "S1 存档读写 research_points 一致 (1)")
	var research: Dictionary = mp.get("research", {})
	_ok(int(research.get("attack", -1)) == 1, "S1 存档读写 research.attack 一致 (1)")
	_ok(int(research.get("hp", -1)) == 0, "S1 存档读写 research.hp 一致 (0)")
	var chars: Dictionary = mp.get("chars", {})
	_ok(int(chars.get("se_irene", {}).get("xp", -1)) == 5, "S1 存档读写 chars.se_irene.xp 一致 (5)")
	# 损坏 JSON → 默认零值容错不崩
	var f := FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	f.store_string("这不是合法 JSON {{{")
	f.close()
	_gm.meta_progress = {}
	_gm.load_meta()
	_ok(int(_gm.meta_progress.get("wins", -1)) == 0, "S1 损坏档容错 wins=0 不崩")
	_ok(int(_gm.meta_progress.get("research", {}).get("attack", -1)) == 0, "S1 损坏档容错 research.attack=0 不崩")

# ========== §2 研究升级与增益 ==========

func _part2_research() -> void:
	print("== §2 研究升级与增益 ==")
	_gm.meta_progress = _zero_meta()
	_gm.meta_progress["research_points"] = 1
	var ok_up: bool = _gm.upgrade_research("attack")
	_ok(ok_up, "S2 research_points=1 升级 attack 成功")
	_ok(int(_gm.meta_progress.get("research_points", -1)) == 0, "S2 升级后研究点扣至 0")
	_ok(int(_gm.meta_progress.get("research", {}).get("attack", -1)) == 1, "S2 research.attack 置位 1")
	var bonus: Dictionary = _gm.get_meta_bonus()
	_ok(absf(float(bonus.get("attack_mult", 0.0)) - 1.05) < 0.001, "S2 attack_mult==1.05 (+5%/级)")
	_ok(absf(float(bonus.get("hp_mult", 0.0)) - 1.0) < 0.001, "S2 hp_mult==1.0（未升级）")
	_ok(absf(float(bonus.get("luck_add", 1.0)) - 0.0) < 0.001, "S2 luck_add==0.0（未升级）")
	_ok(not _gm.upgrade_research("hp"), "S2 点数不足拒绝升级 hp（不扣点）")
	# hp/luck 换算补测（2 点）
	_gm.meta_progress = _zero_meta()
	_gm.meta_progress["research_points"] = 2
	_gm.upgrade_research("hp")
	_gm.upgrade_research("luck")
	bonus = _gm.get_meta_bonus()
	_ok(absf(float(bonus.get("hp_mult", 0.0)) - 1.10) < 0.001, "S2 hp_mult==1.10 (+10%/级)")
	_ok(absf(float(bonus.get("luck_add", 0.0)) - 0.05) < 0.001, "S2 luck_add==0.05 (+0.05/级)")
	# 全 0 → 空字典（零注入零回归）
	_gm.meta_progress = _zero_meta()
	_ok(_gm.get_meta_bonus().is_empty(), "S2 research 全 0 → get_meta_bonus 空字典")

# ========== §3 角色 XP 结算 ==========

func _part3_xp_settle() -> void:
	print("== §3 角色 XP 结算 ==")
	_gm.meta_progress = _zero_meta()
	# D45：current_character_id 空 → start_game 出场记录跳过不崩（探针白盒直调场景）
	_gm.current_character_id = ""
	var old_route: bool = _gm.route_enabled
	_gm.route_enabled = false   # 旧制分支最小副作用（无面板/无 wave_manager）
	_gm.start_game()
	_ok(int(_gm.meta_progress.get("chars", {}).size()) == 0, "S3 D45 判空：空 id 不出场记录")
	# 出场 + 胜利结算
	_gm.current_character_id = "se_irene"
	_gm.start_game()
	_ok(_gm.get_char_xp("se_irene") == 1, "S3 出场 +1 XP")
	_gm.end_game(true)
	_ok(_gm.get_char_xp("se_irene") == 2, "S3 胜利结算 +1 XP（累计 2）")
	_ok(int(_gm.meta_progress.get("wins", -1)) == 1, "S3 wins+1")
	_ok(int(_gm.meta_progress.get("research_points", -1)) == 1, "S3 research_points+1（研究点=胜利局数）")
	# 失败局不结算
	var xp_before: int = _gm.get_char_xp("se_irene")
	_gm.end_game(false)
	_ok(_gm.get_char_xp("se_irene") == xp_before, "S3 失败局不结算 XP")
	_ok(int(_gm.meta_progress.get("wins", -1)) == 1, "S3 失败局 wins 不变")
	# 等级换算 xp/3
	_gm.add_char_xp("se_irene", 4)
	_ok(_gm.get_char_level("se_irene") == 2, "S3 xp=6 → level=2（6/3 向下取整）")
	_gm.route_enabled = old_route

# ========== §4 剧情解锁门槛（D47 纯函数判定，不实例化场景） ==========

func _part4_story_unlock() -> void:
	print("== §4 剧情解锁门槛 ==")
	var irene: Dictionary = _dl.get_character("se_irene")
	var sul: int = int(irene.get("story_unlock_level", 0))
	_ok(sul == 2, "S4 se_irene story_unlock_level==2（SE 四英雄定案）")
	_gm.meta_progress = _zero_meta()
	_gm.meta_progress["chars"] = {"se_irene": {"xp": 6}}
	_ok(_gm.get_char_level("se_irene") == 2, "S4 xp=6 → level=2")
	_ok(_gm.get_char_level("se_irene") >= sul, "S4 level2 >= sul2 → 剧情解锁")
	_gm.meta_progress["chars"] = {"se_irene": {"xp": 2}}
	_ok(_gm.get_char_level("se_irene") == 0, "S4 xp=2 → level=0")
	_ok(_gm.get_char_level("se_irene") < sul, "S4 level0 < sul2 → 剧情锁定")
	_ok(not str(irene.get("story", "")).is_empty(), "S4 se_irene story 非空（LORE.md §2.1 提炼）")

# ========== §5 回归抽样（characters.json 只增字段零波及验证） ==========

func _part5_regression_sample() -> void:
	print("== §5 回归抽样 ==")
	var ids: Array = _dl.get_all_character_ids()
	_ok(ids.size() == 10, "S5 全量 10 英雄")
	var all_story: bool = true
	var all_sul: bool = true
	for id in ids:
		var d: Dictionary = _dl.get_character(str(id))
		if str(d.get("story", "")).is_empty():
			all_story = false
		if int(d.get("story_unlock_level", 0)) < 1:
			all_sul = false
	_ok(all_story, "S5 10 英雄 story 全量非空")
	_ok(all_sul, "S5 10 英雄 story_unlock_level 全量 ≥1")
	var well: Dictionary = _dl.get_character("well_rounded")
	_ok(str(well.get("unlock_condition", "")) == "默认解锁", "S5 unlock_condition 保持默认解锁（未做选人卡点）")

# ========== 收尾 ==========

func _finish() -> void:
	# 状态复位防污染后续探针（GameManager Autoload 单例）
	_gm.meta_progress = {}
	_gm.meta_save_path = "user://save_meta.json"
	_cleanup_test_save()
	paused = false
	print("day27_meta_check: %d PASS / %d FAIL（断言）" % [_pass_count, _fail_count])
	print("DAY27 META CHECK: %s" % ("CLEAN" if _fail_count == 0 else "FAIL"))
	quit(0 if _fail_count == 0 else 1)
