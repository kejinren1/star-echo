## DataLoader 自动加载单例
## 游戏启动时加载所有 JSON 数据表到内存缓存，提供统一访问接口
extends Node

# ========== 数据缓存 ==========

var _enemies: Dictionary = {}           ## 敌人数据 { id → data } (含 category 标记)
var _enemy_scaling: Dictionary = {}     ## 敌人成长公式参数
var _weapons: Dictionary = {}           ## 武器数据 { id → data } (含 category 标记)
var _items: Dictionary = {}             ## 道具数据 { id → data }
var _characters: Dictionary = {}        ## 角色数据 { id → data }
var _waves: Dictionary = {}             ## 波次数据 { wave_number → data }
var _wave_generation: Dictionary = {}   ## 波次生成规则
var _wave_rewards: Dictionary = {}      ## 波次奖励规则
var _elemental_status: Dictionary = {}  ## 元素状态 { element_id → data }
var _element_reactions: Array = []      ## 元素反应列表
var _stats: Dictionary = {}             ## 属性定义
var _formulas: Dictionary = {}          ## 公式定义
var _leveling: Dictionary = {}          ## 升级定义
var _routes: Dictionary = {}            ## 随机节点路线参数（routes.json）
var _events: Array = []                 ## 事件列表（events.json，Day 16：GameManager 随机取）

var _loaded: bool = false               ## 是否已加载

# ========== 生命周期 ==========

func _ready() -> void:
	load_all()

# ========== 数据加载 ==========

## 加载所有数据表
func load_all() -> void:
	if _loaded:
		return
	_load_enemies()
	_load_weapons()
	_load_items()
	_load_characters()
	_load_waves()
	_load_elements()
	_load_stats()
	_load_routes()
	_load_events()
	_loaded = true

## 加载敌人数据
func _load_enemies() -> void:
	var data = _load_json("res://data/enemies.json")
	if not data:
		return
	var enemies: Dictionary = data.get("enemies", {})
	_enemy_scaling = data.get("scaling", {})
	# 普通敌人
	for enemy in enemies.get("regular", []):
		enemy["_category"] = "regular"
		_enemies[enemy["id"]] = enemy
	# 精英敌人
	for enemy in enemies.get("elite", []):
		enemy["_category"] = "elite"
		_enemies[enemy["id"]] = enemy
	# Boss
	for enemy in enemies.get("boss", []):
		enemy["_category"] = "boss"
		_enemies[enemy["id"]] = enemy

## 加载武器数据
func _load_weapons() -> void:
	var data = _load_json("res://data/weapons.json")
	if not data:
		return
	var weapons: Dictionary = data.get("weapons", {})
	for category in weapons:
		for weapon in weapons[category]:
			weapon["_category"] = category
			_weapons[weapon["id"]] = weapon

## 加载道具数据
func _load_items() -> void:
	var data = _load_json("res://data/items.json")
	if not data:
		return
	for item in data.get("items", []):
		_items[item["id"]] = item

## 加载角色数据
func _load_characters() -> void:
	var data = _load_json("res://data/characters.json")
	if not data:
		return
	for char in data.get("characters", []):
		_characters[char["id"]] = char

## 加载波次数据
## 注：Godot 4.3 JSON.parse 把数字全部解析为 float（typeof=3）——wave 号键必须
## 显式转 int，否则 get_wave(int) 永远命中空（waves.json 运行时被旁路，2026-08-06 实测发现）
func _load_waves() -> void:
	var data = _load_json("res://data/waves.json")
	if not data:
		return
	for wave in data.get("waves", []):
		_waves[int(wave["wave"])] = wave
	_wave_generation = data.get("generation", {})
	_wave_rewards = data.get("rewards", {})

## 加载元素数据
func _load_elements() -> void:
	var data = _load_json("res://data/elements.json")
	if not data:
		return
	_elemental_status = data.get("elemental_status", {})
	_element_reactions = data.get("element_reactions", [])

## 加载属性数据
func _load_stats() -> void:
	var data = _load_json("res://data/stats.json")
	if not data:
		return
	var stats: Dictionary = data.get("stats", {})
	for category in stats:
		for stat in stats[category]:
			stat["_category"] = category
			_stats[stat["id"]] = stat
	_formulas = data.get("formulas", {})
	_leveling = data.get("leveling", {})

## 加载路线参数（routes.json；缺失返回空字典 → 生成器走默认参数）
func _load_routes() -> void:
	var data = _load_json("res://data/routes.json")
	if data:
		_routes = data

## 加载事件数据（events.json；缺失返回空数组 → GameManager 事件节点按已完成处理）
func _load_events() -> void:
	var data = _load_json("res://data/events.json")
	if data:
		_events = data.get("events", [])

# ========== JSON 工具 ==========

## 加载 JSON 文件并返回解析后的字典/数组
func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_warning("[DataLoader] 文件不存在: %s" % path)
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_warning("[DataLoader] 无法打开: %s" % path)
		return null
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		push_warning("[DataLoader] JSON 解析错误 %s: %s (行 %d)" % [path, json.get_error_message(), json.get_error_line()])
		return null
	return json.data

# ========== 敌人接口 ==========

## 获取敌人原始数据
func get_enemy(enemy_id: String) -> Dictionary:
	return _enemies.get(enemy_id, {})

## 获取敌人分类 (regular/elite/boss)
func get_enemy_category(enemy_id: String) -> String:
	var data = _enemies.get(enemy_id, {})
	return data.get("_category", "regular")

## 根据波次号计算敌人最终属性
## 返回 { max_health, damage, move_speed, coin_value, behavior, armor, name, id, category }
func get_scaled_enemy(enemy_id: String, wave: int) -> Dictionary:
	var data = _enemies.get(enemy_id, {})
	if data.is_empty():
		push_warning("[DataLoader] 未知敌人 ID: %s" % enemy_id)
		return {}

	var category: String = data.get("_category", "regular")
	var base_hp: float = float(data.get("hp", 1))
	var hp_growth: float = float(data.get("hp_growth", 0))
	var base_damage: float = float(data.get("damage", 1))
	var damage_growth: float = float(data.get("damage_growth", 0))
	var base_speed: float = float(data.get("speed", 200))
	# 金币掉落：优先 coin_value（08-07 反馈修复，数值 2-200 数据化），兜底旧键 drop（历史数据兼容）
	var drop: int = int(data.get("coin_value", data.get("drop", 1)))

	# 成长公式: base + growth * wave（结构在代码；系数全部数据化自 enemies.json.scaling）
	var final_hp := base_hp + hp_growth * wave
	var final_damage := base_damage + damage_growth * wave
	# 速度公式: base * (1 + min(wave * speed_growth_per_wave, speed_growth_cap)) * speed_reduction
	# F-01（用户拍板 2026-08-06 · P0）：怪物移速降至 50% —— 围杀体验修复
	# （真人反馈「怪物移速没有削弱」；全敌人含普通/精英/Boss 统一减速）
	# 参数化（F1-A 2026-08-10）：speed_growth_per_wave=0.01 / speed_growth_cap=0.2 / speed_reduction=0.5
	var speed_growth_per_wave: float = float(_enemy_scaling.get("speed_growth_per_wave", 0.01))
	var speed_growth_cap: float = float(_enemy_scaling.get("speed_growth_cap", 0.2))
	var speed_reduction: float = float(_enemy_scaling.get("speed_reduction", 0.5))
	var final_speed: float = base_speed * (1.0 + min(wave * speed_growth_per_wave, speed_growth_cap)) * speed_reduction

	# 精英乘数（F1-A 参数化：enemies.json.scaling.elite_*_mult_per_wave）
	if category == "elite":
		var elite_hp_mult_per_wave: float = float(_enemy_scaling.get("elite_hp_mult_per_wave", 0.15))
		var elite_dmg_mult_per_wave: float = float(_enemy_scaling.get("elite_dmg_mult_per_wave", 0.08))
		var elite_hp_mult := 1.0 + wave * elite_hp_mult_per_wave
		var elite_dmg_mult := 1.0 + wave * elite_dmg_mult_per_wave
		final_hp *= elite_hp_mult
		final_damage *= elite_dmg_mult

	return {
		"id": data.get("id", enemy_id),
		"name": data.get("name", enemy_id),
		"category": category,
		"max_health": final_hp,
		"damage": final_damage,
		"move_speed": final_speed,
		"coin_value": drop,
		"behavior": data.get("behavior", "chase"),
		"armor": data.get("armor", 0),
		"phases": data.get("phases", []),
		# D6-T2：经验值透传（T-A 收口；缺字段兜底 1 = 历史行为，不崩）
		"exp_value": int(data.get("exp_value", 1)),
	}

## 获取所有敌人 ID
func get_all_enemy_ids() -> Array:
	return _enemies.keys()

## 获取指定分类的敌人 ID 列表
func get_enemy_ids_by_category(category: String) -> Array:
	var result: Array = []
	for id in _enemies:
		if _enemies[id].get("_category") == category:
			result.append(id)
	return result

# ========== 武器接口 ==========

## 获取武器数据
func get_weapon(weapon_id: String) -> Dictionary:
	return _weapons.get(weapon_id, {})

## 获取武器分类 (melee/ranged/elemental/engineering)
func get_weapon_category(weapon_id: String) -> String:
	var data = _weapons.get(weapon_id, {})
	return data.get("_category", "melee")

## 获取所有武器 ID
func get_all_weapon_ids() -> Array:
	return _weapons.keys()

## 获取指定分类的武器 ID 列表
func get_weapon_ids_by_category(category: String) -> Array:
	var result: Array = []
	for id in _weapons:
		if _weapons[id].get("_category") == category:
			result.append(id)
	return result

# ========== 道具接口 ==========

## 获取道具数据
func get_item(item_id: String) -> Dictionary:
	return _items.get(item_id, {})

## 获取所有道具 ID
func get_all_item_ids() -> Array:
	return _items.keys()

## 获取指定稀有度的道具 ID 列表
func get_item_ids_by_rarity(rarity: String) -> Array:
	var result: Array = []
	for id in _items:
		if _items[id].get("rarity") == rarity:
			result.append(id)
	return result

# ========== 角色接口 ==========

## 获取角色数据
func get_character(char_id: String) -> Dictionary:
	return _characters.get(char_id, {})

## 获取所有角色 ID
func get_all_character_ids() -> Array:
	return _characters.keys()

## F-31（2026-08-08 用户拍板）：所有角色的初始武器 ID（去重）
## 单一事实源 = characters.json starting_weapon 字段；商店池跳过这些武器
## （武器升级改走铁砧经济闭环后，初始武器不应在商店可买）
func get_starting_weapon_ids() -> Array[String]:
	var ids: Array[String] = []
	for cid in _characters:
		var sw: String = str(_characters[cid].get("starting_weapon", ""))
		if not sw.is_empty() and not ids.has(sw):
			ids.append(sw)
	return ids

# ========== 波次接口 ==========

## 获取波次数据
## 返回 { wave, duration, total_enemies, composition, special, special_note }
func get_wave(wave_number: int) -> Dictionary:
	return _waves.get(wave_number, {})

## 获取最大波次数
func get_max_waves() -> int:
	var max_wave := 0
	for w in _waves:
		if w > max_wave:
			max_wave = w
	return max_wave

## 获取波次生成规则
func get_wave_generation() -> Dictionary:
	return _wave_generation

## 获取波次奖励规则
func get_wave_rewards() -> Dictionary:
	return _wave_rewards

# ========== 元素接口 ==========

## 获取元素状态数据
func get_element(element_id: String) -> Dictionary:
	return _elemental_status.get(element_id, {})

## 获取两种元素的反应结果
## 返回反应字典，若无反应返回空字典
func get_element_reaction(elem1: String, elem2: String) -> Dictionary:
	for reaction in _element_reactions:
		var combo: Array = reaction.get("combination", [])
		if combo.size() == 2:
			if (combo[0] == elem1 and combo[1] == elem2) or (combo[0] == elem2 and combo[1] == elem1):
				return reaction
	return {}

## 获取所有元素 ID
func get_all_element_ids() -> Array:
	return _elemental_status.keys()

# ========== 属性接口 ==========

## 获取属性定义
func get_stat(stat_id: String) -> Dictionary:
	return _stats.get(stat_id, {})

## 获取所有属性 ID
func get_all_stat_ids() -> Array:
	return _stats.keys()

## 获取公式定义
func get_formulas() -> Dictionary:
	return _formulas

## 获取升级定义
func get_leveling() -> Dictionary:
	return _leveling

# ========== 路线接口（Day 14-15 · D14-15-T3） ==========

## 获取随机节点路线参数（空字典 = 未定义 → 生成器走默认参数）
func get_routes() -> Dictionary:
	return _routes

# ========== 事件接口（Day 16 · D16-T2） ==========

## 获取全部事件（事件节点随机取用；缺失返回 []）
func get_events() -> Array:
	return _events
