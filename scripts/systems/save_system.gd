## 存档系统组件（F4-T4 · 2026-08-14 从 game_manager.gd 拆出）
## 职责：局外元进度（meta_progress）读写/换算/研究升级/角色 XP（纯逻辑，存档格式零改动）
## 范式：无 class_name；GM preload 本组件（组件不引用 Autoload 标识符，无循环 preload）；
##      setup(gm) 注入宿主引用——meta_progress/meta_save_path 字段仍由 GM 持有
##      （探针 day27_meta 直接读写 _gm.meta_progress / _gm.meta_save_path，字段不可迁走）
extends Node

## 宿主 GameManager 实例（GM._ready 挂载时注入）
var _gm: Node = null

func setup(gm: Node) -> void:
	_gm = gm

## 默认零值元进度（load_meta 兜底与 reset 复用）
func _default_meta() -> Dictionary:
	return {
		"wins": 0,
		"research_points": 0,
		"research": {"attack": 0, "hp": 0, "luck": 0},
		"chars": {},
	}

## 加载局外存档：缺文件/打开失败/非 Dictionary → 默认零值 + push_warning 容错不崩；
## 成功 → 逐键 int() 收敛（Godot 4.3 JSON 全数字 float 的已知特性，DataLoader 先例）
func load_meta() -> void:
	_gm.meta_progress = _default_meta()
	if not FileAccess.file_exists(_gm.meta_save_path):
		return
	var f := FileAccess.open(_gm.meta_save_path, FileAccess.READ)
	if f == null:
		push_warning("[GameManager] 存档打开失败(%s)，使用默认元进度" % _gm.meta_save_path)
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if not (parsed is Dictionary):
		push_warning("[GameManager] 存档解析失败(%s)，使用默认元进度" % _gm.meta_save_path)
		return
	var data: Dictionary = parsed as Dictionary
	_gm.meta_progress["wins"] = int(data.get("wins", 0))
	_gm.meta_progress["research_points"] = int(data.get("research_points", 0))
	var research: Dictionary = data.get("research", {})
	_gm.meta_progress["research"] = {
		"attack": int(research.get("attack", 0)),
		"hp": int(research.get("hp", 0)),
		"luck": int(research.get("luck", 0)),
	}
	var chars: Dictionary = data.get("chars", {})
	var clean_chars: Dictionary = {}
	for cid in chars.keys():
		var cdata: Variant = chars[cid]
		var xp: int = int(cdata.get("xp", 0)) if cdata is Dictionary else 0
		clean_chars[str(cid)] = {"xp": xp}
	_gm.meta_progress["chars"] = clean_chars
	# G-C/G-E（2026-08-14）：codex/skill_tree 扩展键（缺省空兼容旧档）
	var codex_data: Variant = data.get("codex", {})
	if codex_data is Dictionary:
		var clean_codex: Dictionary = {}
		for cat in codex_data.keys():
			var lst: Variant = codex_data[cat]
			var clean_list: Array = []
			if lst is Array:
				for cid in lst:
					clean_list.append(str(cid))
			clean_codex[str(cat)] = clean_list
		_gm.meta_progress["codex"] = clean_codex
	var st_data: Variant = data.get("skill_tree", {})
	if st_data is Dictionary:
		_gm.meta_progress["skill_tree"] = st_data
	# PS-E2（2026-08-16）：skill_slots 扩展键（char_id → [槽位]，缺省空兼容旧档）
	var slots_data: Variant = data.get("skill_slots", {})
	if slots_data is Dictionary:
		var clean_slots: Dictionary = {}
		for cid in slots_data.keys():
			var lst: Variant = slots_data[cid]
			var clean_list: Array = []
			if lst is Array:
				for s in lst:
					var si: int = int(s)
					if si > 0 and not clean_list.has(si):
						clean_list.append(si)
			clean_slots[str(cid)] = clean_list
		_gm.meta_progress["skill_slots"] = clean_slots

## 保存局外存档（每次结算/研究升级后调用）
func save_meta() -> void:
	var f := FileAccess.open(_gm.meta_save_path, FileAccess.WRITE)
	if f == null:
		push_warning("[GameManager] 存档写入失败(%s)" % _gm.meta_save_path)
		return
	f.store_string(JSON.stringify(_gm.meta_progress, "  "))

## 局外永久增益换算：attack ×(1+0.05/级) / max_health ×(1+0.10/级) / luck +0.05/级
## research 全 0 → 返回空字典（调用方零注入零回归）
func get_meta_bonus() -> Dictionary:
	var research: Dictionary = _gm.meta_progress.get("research", {})
	var atk: int = int(research.get("attack", 0))
	var hp: int = int(research.get("hp", 0))
	var lck: int = int(research.get("luck", 0))
	if atk <= 0 and hp <= 0 and lck <= 0:
		return {}
	return {
		"attack_mult": 1.0 + 0.05 * float(atk),
		"hp_mult": 1.0 + 0.10 * float(hp),
		"luck_add": 0.05 * float(lck),
	}

## 研究升级（消耗 1 点）：成功 true；键非法/已满级/点数不足 → false 不扣点
func upgrade_research(key: String) -> bool:
	if key != "attack" and key != "hp" and key != "luck":
		return false
	var research: Dictionary = _gm.meta_progress.get("research", {})
	if int(research.get(key, 0)) > 0:
		return false
	var points: int = int(_gm.meta_progress.get("research_points", 0))
	if points <= 0:
		return false
	research[key] = 1
	_gm.meta_progress["research"] = research
	_gm.meta_progress["research_points"] = points - 1
	save_meta()
	return true

## 增加研究点（胜利结算调用）
func add_research_point(amount: int = 1) -> void:
	_gm.meta_progress["research_points"] = int(_gm.meta_progress.get("research_points", 0)) + maxi(amount, 0)

## 角色 XP 累计（出场/胜场各 +1；id 空判空跳过）
## G-E（R6 技能树 · O1 用户拍板 2026-08-12）：等级跃迁发放技能点——
## old vs new 差值 = n 点（D4 定案防连升少计/多计；skill_tree 缺省空兼容旧档）
func add_char_xp(id: String, amount: int = 1) -> void:
	if id.is_empty():
		return
	var old_level: int = get_char_level(id)
	var chars: Dictionary = _gm.meta_progress.get("chars", {})
	var cdata: Dictionary = chars.get(id, {})
	chars[id] = {"xp": int(cdata.get("xp", 0)) + maxi(amount, 0)}
	_gm.meta_progress["chars"] = chars
	var new_level: int = get_char_level(id)
	if new_level > old_level:
		var st: Dictionary = _gm.meta_progress.get("skill_tree", {})
		st["points"] = int(st.get("points", 0)) + (new_level - old_level)
		_gm.meta_progress["skill_tree"] = st

func get_char_xp(id: String) -> int:
	return int(_gm.meta_progress.get("chars", {}).get(id, {}).get("xp", 0))

## 角色等级 = xp/3 向下取整（仅驱动剧情解锁 + 展示，无属性收益）
func get_char_level(id: String) -> int:
	return int(get_char_xp(id) / 3)

## G-C（R3 图鉴 · 2026-08-14）：记录已见过条目（去重入 meta_progress.codex；
## 缺省空兼容旧档——load_meta 不读 codex 键，首次记录自动建）
## category ∈ "weapon"/"character"/"enemy"/"item"/"event"
func record_codex(category: String, id: String) -> void:
	if category.is_empty() or id.is_empty():
		return
	var codex: Dictionary = _gm.meta_progress.get("codex", {})
	var list: Array = codex.get(category, [])
	if not list.has(id):
		list.append(id)
		codex[category] = list
		_gm.meta_progress["codex"] = codex

## 图鉴查询（CodexPanel 展示；无记录返回空字典）
func get_codex() -> Dictionary:
	return _gm.meta_progress.get("codex", {})

## G-E（R6 技能树 · 2026-08-14）：meta_progress.skill_tree 读写（缺省空兼容旧档）
func get_skill_tree() -> Dictionary:
	return _gm.meta_progress.get("skill_tree", {})

func set_skill_tree(data: Dictionary) -> void:
	_gm.meta_progress["skill_tree"] = data

## 技能点余额（缺省 0）
func get_skill_points() -> int:
	return int(_gm.meta_progress.get("skill_tree", {}).get("points", 0))

## 解锁技能节点：前置满足 + 点数足够 → 扣点持久化返回 true；否则 false 不扣
func unlock_skill(node_id: String) -> bool:
	var st: Dictionary = _gm.meta_progress.get("skill_tree", {})
	var unlocked: Array = st.get("unlocked", [])
	if unlocked.has(node_id):
		return false
	var nodes: Array = DataLoader.get_skill_tree().get("nodes", []) if DataLoader else []
	var node: Dictionary = {}
	for n in nodes:
		if str(n.get("id", "")) == node_id:
			node = n
			break
	if node.is_empty():
		return false
	# 前置校验（prereq 空 = 根节点免前置）
	var prereq: String = str(node.get("prereq", ""))
	if prereq != "" and not unlocked.has(prereq):
		return false
	var cost: int = int(node.get("cost", 1))
	var points: int = int(st.get("points", 0))
	if points < cost:
		return false
	unlocked.append(node_id)
	st["unlocked"] = unlocked
	st["points"] = points - cost
	_gm.meta_progress["skill_tree"] = st
	return true

## 已解锁节点列表
func get_unlocked_skills() -> Array:
	return _gm.meta_progress.get("skill_tree", {}).get("unlocked", [])

## PS-E2（2026-08-16 · PLAYER_SKILL_SPEC §3 D6）：角色等级解锁技能槽位——
## meta_progress.skill_slots = {char_id: [槽位…]}（缺省空兼容旧档；进局装配时查询）
func get_unlocked_slots(id: String) -> Array:
	return _gm.meta_progress.get("skill_slots", {}).get(id, [])

## 达门槛 → 登记解锁槽位（幂等：已解锁不重复追加）
func unlock_slot_for_level(id: String, level: int) -> void:
	var slots_data: Dictionary = _gm.meta_progress.get("skill_slots", {})
	var existing: Array = slots_data.get(id, [])
	var unlocked: Array = DataLoader.get_unlocked_slots_for_level(level) if DataLoader else []
	for s in unlocked:
		if not existing.has(s):
			existing.append(s)
	slots_data[id] = existing
	_gm.meta_progress["skill_slots"] = slots_data
