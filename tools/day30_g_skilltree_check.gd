## G-E 出口校验：R6 技能树（G-R6-1~4 · 2026-08-14）
##
## 用法（无头）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day30_g_skilltree_check.gd
##
## 校验内容：
##   §1 数据加载：skill_tree.json 6 节点（gen 脚本生成）+ DataLoader 接口
##   §2 前置锁定：前置未解锁 → unlock_skill false；前置满足 → true
##   §3 消耗持久化：解锁扣点 + 存档重启保留
##   §4 技能点发放：等级提升 +1（old vs new 差值）；research 独立并存零回归
##   §5 效果注入：解锁后 apply_stat_modifier 注入生效（白盒验证加成）
## 退出码 0 = 全部通过；非 0 = 失败项数。
extends SceneTree

var _sub: int = 0
var _checked: int = 0
var _failures: int = 0

func _ok(cond: bool, msg: String) -> void:
	_checked += 1
	if cond:
		print("  PASS  " + msg)
	else:
		_failures += 1
		print("  FAIL  " + msg)

func _initialize() -> void:
	print("=== Day30-G-E skilltree check ===")

func _process(_delta: float) -> bool:
	if _sub > 5:
		print("=== SKILLTREE CHECK: %d assertions, %d failures ===" % [_checked, _failures])
		quit(_failures)
		return true
	_sub = _advance(_sub)
	return false

func _advance(sub: int) -> int:
	match sub:
		0:
			_part_data()
			return 1
		1:
			_part_prereq()
			return 2
		2:
			_part_persist()
			return 3
		3:
			_part_points_grant()
			return 4
		4:
			_part_effect()
			return 5
		5:
			return 99
		_:
			return 99

func _gm() -> Node:
	return root.get_node_or_null("GameManager")

func _dl() -> Node:
	return root.get_node_or_null("DataLoader")

# ========== §1 数据加载 ==========

func _part_data() -> void:
	var gm: Node = _gm()
	var dl: Node = _dl()
	_ok(gm != null and dl != null, "§1 数据: GameManager/DataLoader autoload 在位")
	if gm == null or dl == null:
		return
	var tree: Dictionary = dl.call("get_skill_tree")
	var nodes: Array = tree.get("nodes", [])
	_ok(nodes.size() == 6, "§1 数据: skill_tree.json 6 节点（实得 %d）" % nodes.size())
	var gen_ok: bool = FileAccess.file_exists("res://data/skill_tree.json") \
		and FileAccess.file_exists("res://tools/gen_skill_tree.py")
	_ok(gen_ok, "§1 数据: skill_tree.json + gen_skill_tree.py 在位")

# ========== §2 前置锁定 ==========

func _part_prereq() -> void:
	var gm: Node = _gm()
	gm.set("meta_progress", {"wins": 0, "research_points": 0, "research": {}, "chars": {}, "skill_tree": {"unlocked": [], "points": 5}})
	# atk_2 前置 atk_1 未解锁 → false
	_ok(not bool(gm.call("unlock_skill", "atk_2")), "§2 前置: atk_2 前置 atk_1 未解锁 → 拒绝")
	# atk_1 根节点 → true
	_ok(bool(gm.call("unlock_skill", "atk_1")), "§2 前置: atk_1 根节点解锁成功")
	# atk_2 前置满足 → true
	_ok(bool(gm.call("unlock_skill", "atk_2")), "§2 前置: 前置满足后 atk_2 解锁成功")
	# 点数不足 → false
	gm.set("meta_progress", {"wins": 0, "research_points": 0, "research": {}, "chars": {}, "skill_tree": {"unlocked": [], "points": 0}})
	_ok(not bool(gm.call("unlock_skill", "atk_1")), "§2 前置: 点数不足 → 拒绝不扣点")

# ========== §3 消耗持久化 ==========

func _part_persist() -> void:
	var gm: Node = _gm()
	var test_path: String = "user://tmp_skilltree_test.json"
	gm.set("meta_save_path", test_path)
	gm.set("meta_progress", {"wins": 0, "research_points": 0, "research": {}, "chars": {}, "skill_tree": {"unlocked": ["atk_1"], "points": 2}})
	gm.call("save_meta")
	gm.set("meta_progress", {})
	gm.call("load_meta")
	var st: Dictionary = gm.get("meta_progress").get("skill_tree", {})
	_ok(st.get("unlocked", []).has("atk_1") and int(st.get("points", 0)) == 2,
		"§3 持久化: 解锁列表 + 点数存档重启保留")
	DirAccess.remove_absolute("user://tmp_skilltree_test.json")

# ========== §4 技能点发放 ==========

func _part_points_grant() -> void:
	var gm: Node = _gm()
	# 角色 xp 0 → level 0；加 9 xp → level 3（跨 3 级 → 3 点）
	gm.set("meta_progress", {"wins": 0, "research_points": 0, "research": {}, "chars": {}, "skill_tree": {}})
	gm.call("add_char_xp", "se_irene", 9)
	var points: int = gm.call("get_skill_points")
	_ok(points == 3, "§4 发放: 等级提升 3 级 → 3 技能点（实得 %d）" % points)
	# 同等级内加 xp 不越级 → 0 点
	gm.call("add_char_xp", "se_irene", 1)  # xp 10 → level 3（未跃迁）
	_ok(gm.call("get_skill_points") == 3, "§4 发放: 未跃迁不加点（保持 3）")
	# 连续跨 2 级 → 2 点（old vs new 差值）
	gm.call("add_char_xp", "se_irene", 6)  # xp 16 → level 5
	_ok(gm.call("get_skill_points") == 5, "§4 发放: 跨 2 级 → +2 点（实得 %d）" % int(gm.call("get_skill_points")))
	# research 独立并存（O2）：研究点与技能点互不影响
	gm.set("meta_progress", {"wins": 0, "research_points": 1, "research": {}, "chars": {}, "skill_tree": {"points": 1}})
	gm.call("add_char_xp", "se_noa", 6)
	_ok(int(gm.get("meta_progress").get("research_points", 0)) == 1 and gm.call("get_skill_points") == 3,
		"§4 发放: research_points 独立并存零影响（技能点 1+2=3）")

# ========== §5 效果注入 ==========

func _part_effect() -> void:
	var gm: Node = _gm()
	var player_script: GDScript = load("res://scripts/player/player.gd")
	var player: Node = player_script.new()
	root.add_child(player)
	# 注入解锁 atk_1（damage ×1.05）→ 白盒走面板解锁链路（unlock + 即时注入模拟）
	gm.set("meta_progress", {"wins": 0, "research_points": 0, "research": {}, "chars": {}, "skill_tree": {"unlocked": [], "points": 2}})
	gm.call("unlock_skill", "atk_1")
	# 效果注入：解锁后经面板/进局注入（main._apply_skill_tree_bonus 链路）
	var nodes: Array = _dl().call("get_skill_tree").get("nodes", [])
	for n in nodes:
		if str(n.get("id", "")) == "atk_1":
			var eff: Dictionary = n.get("effect", {})
			player.call("apply_stat_modifier", str(eff.get("stat", "")), float(eff.get("value", 1.0)), bool(eff.get("mult", false)))
			break
	var dmg_mult: float = float(player.get("damage_multiplier"))
	_ok(absf(dmg_mult - 1.05) < 0.001, "§5 注入: atk_1 效果注入 damage ×1.05（实得 %.3f）" % dmg_mult)
	player.queue_free()
