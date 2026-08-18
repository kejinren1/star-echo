## DataLoader 自动加载单例
## 游戏启动时加载所有 JSON 数据表到内存缓存，提供统一访问接口
extends Node

## F1-E（2026-08-18 总指挥第一批）：敌人精灵表现 const 兜底（enemy_enums 纯常量文件零 Autoload 引用，
## preload 范式同 enemy.gd —— 探针 --script 编译期可解析；presentation.json 未命中时按 category 回退）
const EnemyEnums: GDScript = preload("res://scripts/enemy/enemy_enums.gd")

# ========== 机制 id 常量（F1-F T-025~030：数据侧 id 单一事实源，消费点禁散落字面量） ==========

## 机制型被动 id（D24-F13-1 三机制被动；消费点 main/player/projectile 读此常量防改名即坏）
const ITEM_EXECUTIONER_MARK: String = "executioner_mark"
const ITEM_LAST_STAND: String = "last_stand"
const ITEM_OVERLOAD_CAPACITOR: String = "overload_capacitor"
## 星刃核心（F-21 群星回应保底 / 进化链关键道具）
const ITEM_BLADE_CORE: String = "se_blade_core"
## 主动技能 id（与 characters.json skill.id 对齐；skill_controller 消费点读此常量）
const SKILL_FIREBALL: String = "se_skill_fireball"
const SKILL_DEPLOY_TURRET: String = "se_skill_deploy_turret"
const SKILL_BLADE_BURST: String = "se_skill_blade_burst"
const SKILL_HOLY_SHIELD: String = "se_skill_holy_shield"
## PS-C4（2026-08-16 · PLAYER_SKILL_SPEC §9.4）：剑士星刃替换 → 剑气爆发
const SKILL_SWORD_ARC: String = "se_skill_sword_arc"
## 武器 id（进化/机制识别消费点：炮台常驻多台判定等）
const WEAPON_TURRET_ARRAY: String = "se_turret_array"

# ========== 数据缓存 ==========

var _enemies: Dictionary = {}           ## 敌人数据 { id → data } (含 category 标记)
var _enemy_sprites: Dictionary = {}     ## F1-E：敌人精灵表现（presentation.json enemy_sprites，懒加载；
                                        ## 空字典 = 未加载/缺失，is_empty() 即重试标记——F3 §4 禁新增 bool 行为标志）
var _behavior_map: Dictionary = {}      ## F1-E：行为字符串→枚举名映射（presentation.json behavior_map，懒加载；
                                        ## 空字典 = 未加载/缺失，is_empty() 即重试标记）
var _audio_map: Dictionary = {}         ## F1-E-3：BGM/SFX 路径抽表（presentation.json audio_map，懒加载；
                                        ## 空字典 = 未加载/缺失，is_empty() 即重试标记——F3 §4 禁新增 bool 行为标志）
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
var _shop: Dictionary = {}              ## 商店参数（stats.json shop 段，F1-D T-010）
## F1-散（2026-08-13 T-007/008/013/015/011/012）：战斗/物理/技能参数段（stats.json 顶层键）
var _combat: Dictionary = {}            ## 战斗参数（通关回血/无敌帧/闪避上限等）
var _physics: Dictionary = {}           ## 弹丸物理参数（碰撞层/半径）
var _skills: Dictionary = {}            ## 技能参数（火球 speed/lifetime/pierce/radius）
var _routes: Dictionary = {}            ## 随机节点路线参数（routes.json）
var _events: Array = []                 ## 事件列表（events.json，Day 16：GameManager 随机取）
## AUDIO_FEEL（2026-08-18 AF-P0）：打击感参数段（stats.json feel 键——hitstop 顿帧 + 震屏分级）
var _feel: Dictionary = {}
## BS-C1（2026-08-13）：Boss 技能表 + pattern 引用表（boss_skills.json / boss_patterns.json）
var _boss_skills: Dictionary = {}       ## { skill_id → 技能定义 }
var _boss_patterns: Array = []          ## [{boss_id, skill_id, weight, phase, override, min_interval}]
## G-E（2026-08-14）：技能树表（data/skill_tree.json；gen_skill_tree.py 生成）
var _skill_tree: Dictionary = {}
## PS-C1/PS-E1（2026-08-16 · PLAYER_SKILL_SPEC §9.2/§3 D6）：掉落技能遗物表 + 局外等级奖励门槛表
var _skill_relics: Array = []            ## [{id, name, desc, base_type, drop_source, per_character}]
var _skill_unlocks: Array = []           ## [{char_level, unlocks:{slot:int}}]

# ========== F1-散 参数段兜底（缺段时接口返回的默认值 = 现硬编码值，防 Excel 未导出行为漂移） ==========
const COMBAT_DEFAULTS: Dictionary = {
	"wave_clear_heal_ratio": 0.5,    # T-007 game_manager._apply_wave_heal
	"max_waves": 20,                 # T-008 game_manager/wave_manager 兜底字面量
	"i_frames": 0.4,                 # T-013 player.take_damage 无敌帧
	"dodge_cap": 0.9,                # T-013 player 闪避 clamp 上限
	"debug_damage_mult": 0.001,      # T-013 F-04 金手指受伤倍率
	"knockback_decay": 0.5,          # T-015 enemy._process_knockback 每帧衰减
	"contact_cooldown": 0.5,         # T-015 enemy._try_contact_damage 冷却
	"armor_cap": 0.75,               # T-015 保留参数（F1-C 平直减公式无钳制语义，无消费点）
}
const PHYSICS_DEFAULTS: Dictionary = {
	"projectile_mask": 2,            # T-011 projectile.collision_mask
	"projectile_radius": 4.0,        # T-011 projectile 碰撞圆半径
}
const SKILLS_DEFAULTS: Dictionary = {
	"fireball_speed": 280.0,         # T-012 skill_controller 火球速度
	"fireball_lifetime": 1.4,        # T-012 火球寿命
	"fireball_pierce": 3,            # T-012 火球穿透（F-07）
	"fireball_radius": 90.0,         # T-012 火球爆炸半径兜底
}
## AUDIO_FEEL（2026-08-18 AF-P0 批 A/B · 08-18 F-45 用户拍板「顿帧能多小多小」）：打击感参数兜底
## （缺段时 get_stats_feel 返回的默认值 = 方案拍板值，防 Excel 未导出行为漂移；
##  批 A 先 4 键 hitstop，批 B 扩展 6 键 shake——键齐后 Excel 与 const 双向一致）
## F-45（2026-08-18 用户反馈）：顿帧大幅调小——0.02~0.03s ≈ 1~2 帧，低频攻击（1-2 次/秒）
## 单次顿帧占比 2-3% 肉眼不可感知；1s 5 次+ 高频攻击时连续顿帧占比 10-15% 才见节奏顿挫；
## Boss 击杀 0.06s 保留相对重感（击杀为低频事件不频发）
const FEEL_DEFAULTS: Dictionary = {
	"hitstop_melee": 0.03,           # F-45 近战顿帧（0.15→0.03，1 秒 5 击+才可见）
	"hitstop_ranged": 0.02,          # F-45 远程顿帧（0.05→0.02）
	"hitstop_crit_bonus": 0.02,      # F-45 暴击追加顿帧（0.1→0.02，不再显著加长）
	"hitstop_boss_kill": 0.06,       # F-45 Boss 击杀顿帧（0.15→0.06，保留相对重感）
	"shake_light_duration": 0.15,    # AF-P0-B1 震屏轻档时长（= F-03 现值零漂移）
	"shake_light_magnitude": 4.0,    # AF-P0-B1 震屏轻档幅度（= F-03 现值零漂移）
	"shake_medium_duration": 0.2,    # AF-P0-B1 震屏中档时长（暴击/普通击杀）
	"shake_medium_magnitude": 6.0,   # AF-P0-B1 震屏中档幅度
	"shake_heavy_duration": 0.3,     # AF-P0-B1 震屏重档时长（Boss 死亡）
	"shake_heavy_magnitude": 9.0,    # AF-P0-B1 震屏重档幅度
}

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
	_load_boss_tables()
	_load_skill_tree()
	_load_skill_relics()
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
	_shop = data.get("shop", {})
	_combat = data.get("combat", {})
	_physics = data.get("physics", {})
	_skills = data.get("skills", {})
	_feel = data.get("feel", {})

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

## BS-C1（2026-08-13）：Boss 技能/pattern 表（缺失 → 空表，Boss 走旧 attacks 指令降级路径）
func _load_boss_tables() -> void:
	var data = _load_json("res://data/boss_skills.json")
	if data:
		_boss_skills = data.get("skills", {})
	var data2 = _load_json("res://data/boss_patterns.json")
	if data2:
		_boss_patterns = data2.get("patterns", [])

## G-E（2026-08-14）：技能树表（data/skill_tree.json，tools/gen_skill_tree.py 生成；
## 缺失 → 空表，SkillTreePanel 空态零崩）
func _load_skill_tree() -> void:
	var data = _load_json("res://data/skill_tree.json")
	if data:
		_skill_tree = data

## PS-C1（2026-08-16）：掉落技能遗物表 + 局外等级奖励门槛表（缺失 → 空表，装配零崩）
func _load_skill_relics() -> void:
	var data = _load_json("res://data/skill_relics.json")
	if data:
		_skill_relics = data.get("skill_relics", [])
	var data2 = _load_json("res://data/skill_unlocks.json")
	if data2:
		_skill_unlocks = data2.get("skill_unlocks", [])

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

	# T-009（F1-散 2026-08-13）：冲锋参数透传（enemy._move_charge 消费；
	# 默认值 = 现硬编码值 1.5/2.0/0.8，行为零改动）
	var charge_speed_mult: float = float(_enemy_scaling.get("charge_speed_mult", 1.5))
	var charge_windup: float = float(_enemy_scaling.get("charge_windup", 2.0))
	var charge_duration: float = float(_enemy_scaling.get("charge_duration", 0.8))

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
		# T-053（F1-散 2026-08-13）：wave_number 补键——Boss 召唤物路径
		# （enemy.gd _boss_summon/_elite_spawn → get_scaled_enemy(minion, wave)）
		# 直接可读；enemy_spawner 手动补键 :130 变为冗余但同值（零改动）
		"wave_number": wave,
		# T-009：冲锋参数（enemy.initialize 透传存储，_move_charge 消费）
		"charge_speed_mult": charge_speed_mult,
		"charge_windup": charge_windup,
		"charge_duration": charge_duration,
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

## 获取全部技能 ID（characters.json skill.id 去重；F1-F 数据侧收敛，skill_controller 可校验）
func get_skill_ids() -> Array[String]:
	var ids: Array[String] = []
	for cid in _characters:
		var sid: String = str(_characters[cid].get("skill", {}).get("id", ""))
		if not sid.is_empty() and not ids.has(sid):
			ids.append(sid)
	return ids

## PS-C1（2026-08-16）：全部掉落技能遗物（skill_relics.json；缺失 → 空表）
func get_all_skill_relics() -> Array:
	return _skill_relics

## PS-C1：按掉落源筛遗物（drop_source ∈ elite/chapter_boss；缺失 → 空表）
func get_skill_relics_by_source(source: String) -> Array:
	var out: Array = []
	for relic in _skill_relics:
		if str(relic.get("drop_source", "")) == source:
			out.append(relic)
	return out

## PS-C1：单遗物数据（id 命中；缺失 → 空字典）
func get_skill_relic(relic_id: String) -> Dictionary:
	for relic in _skill_relics:
		if str(relic.get("id", "")) == relic_id:
			return relic
	return {}

## PS-C1（§9.2/§9.4）：按角色解析遗物实际技能（per_character[char_id] → {type, params}；
## 无该角色条目 → 通用兜底 base_type（params 空））
func resolve_relic_skill(relic: Dictionary, char_id: String) -> Dictionary:
	var per_char: Dictionary = relic.get("per_character", {})
	if per_char.has(char_id):
		return per_char[char_id]
	var out: Dictionary = {"type": str(relic.get("base_type", ""))}
	if not out["type"].is_empty():
		out["params"] = {}
	return out

## PS-E1（2026-08-16）：角色等级 → 已解锁槽位列表（skill_unlocks.json；门槛表驱动）
func get_unlocked_slots_for_level(level: int) -> Array:
	var out: Array = []
	for row in _skill_unlocks:
		if int(row.get("char_level", 999)) <= level:
			var unlocks: Dictionary = row.get("unlocks", {})
			if unlocks.has("slot"):
				var s: int = int(unlocks["slot"])
				if s > 0 and not out.has(s):
					out.append(s)
	return out

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

## 获取商店参数（stats.json shop 段；缺段返回 {} → 消费方 get(key, 默认) 兜底）
func get_stats_shop() -> Dictionary:
	return _shop

## F1-散（2026-08-13 T-007/008/013/015）：战斗参数（stats.json combat 段）
## 缺段/缺键 → 兜底默认值 = 现硬编码值（防 Excel 未导出时行为漂移）
func get_stats_combat() -> Dictionary:
	var out: Dictionary = COMBAT_DEFAULTS.duplicate()
	for k in _combat:
		out[k] = _combat[k]
	return out

## F1-散（2026-08-13 T-011）：弹丸物理参数（stats.json physics 段）
func get_stats_physics() -> Dictionary:
	var out: Dictionary = PHYSICS_DEFAULTS.duplicate()
	for k in _physics:
		out[k] = _physics[k]
	return out

## F1-散（2026-08-13 T-012）：技能参数（stats.json skills 段）
func get_stats_skills() -> Dictionary:
	var out: Dictionary = SKILLS_DEFAULTS.duplicate()
	for k in _skills:
		out[k] = _skills[k]
	return out

## AUDIO_FEEL（2026-08-18 AF-P0）：打击感参数（stats.json feel 段——hitstop 顿帧 + 震屏分级）
## 缺段/缺键 → 兜底默认值 = 方案拍板值（O-2 近重远轻 / F-03 现值），防 Excel 未导出时行为漂移
func get_stats_feel() -> Dictionary:
	var out: Dictionary = FEEL_DEFAULTS.duplicate()
	for k in _feel:
		out[k] = _feel[k]
	return out

# ========== 路线接口（Day 14-15 · D14-15-T3） ==========

## 获取随机节点路线参数（空字典 = 未定义 → 生成器走默认参数）
func get_routes() -> Dictionary:
	return _routes

# ========== 事件接口（Day 16 · D16-T2） ==========

## 获取全部事件（事件节点随机取用；缺失返回 []）
func get_events() -> Array:
	return _events

# ========== Boss 技能接口（BS-C1 · 2026-08-13） ==========

## 获取 Boss 技能定义（boss_skills.json；缺失返回 {}）
func get_boss_skill(skill_id: String) -> Dictionary:
	return _boss_skills.get(skill_id, {})

## 获取某 Boss 的 pattern 行（boss_patterns.json 按 boss_id 过滤；缺失返回 [] → 旧 attacks 降级）
func get_boss_patterns(boss_id: String) -> Array:
	var out: Array = []
	for p in _boss_patterns:
		if str(p.get("boss_id", "")) == boss_id:
			out.append(p)
	return out

# ========== 敌人精灵表现接口（F1-E 第一批 · 2026-08-18 总指挥承接） ==========

## 获取敌人精灵表现配置（presentation.json enemy_sprites 优先；未命中按 category 回退
## enemy_enums.gd const SPRITE_MAP/FALLBACK_SPRITES —— F 系列缺省兜底约定，表现抽表后旧值仍可启动）。
## 返回字段与旧 SPRITE_MAP 条目一致：move/death/size(Vector2i)/move_frames/death_frames/
## move_fps/death_fps/hit_radius/tint(Color)/scale(float)；数据表缺失或损坏 → 全量 const 兜底。
func get_enemy_sprite_config(enemy_id: String, category: String) -> Dictionary:
	if _enemy_sprites.is_empty():
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/presentation.json"))
		if raw is Dictionary and (raw as Dictionary).get("enemy_sprites") is Dictionary:
			_enemy_sprites = (raw as Dictionary)["enemy_sprites"]
	var cfg: Variant = _enemy_sprites.get(enemy_id, null)
	if cfg is Dictionary:
		var out: Dictionary = (cfg as Dictionary).duplicate()
		var size: Variant = out.get("size", null)
		if size is Dictionary:
			out["size"] = Vector2i(int((size as Dictionary).get("x", 0)), int((size as Dictionary).get("y", 0)))
		var tint: Variant = out.get("tint", null)
		if tint is Array and (tint as Array).size() >= 3:
			out["tint"] = Color(float(tint[0]), float(tint[1]), float(tint[2]))
		return out
	return EnemyEnums.SPRITE_MAP.get(enemy_id, EnemyEnums.FALLBACK_SPRITES.get(category, EnemyEnums.FALLBACK_SPRITES["regular"]))

## 获取行为字符串对应的 Behavior 枚举（presentation.json behavior_map 优先；未命中/非法
## 回退 enemy_enums.gd const BEHAVIOR_MAP —— F 系列缺省兜底约定，抽表后旧值仍可启动）。
## 返回 EnemyEnums.Behavior 枚举 int；数据表缺失/损坏 → const 全量兜底 CHASE。
func get_enemy_behavior(behav_str: String) -> int:
	if _behavior_map.is_empty():
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/presentation.json"))
		if raw is Dictionary and (raw as Dictionary).get("behavior_map") is Dictionary:
			_behavior_map = (raw as Dictionary)["behavior_map"]
	var mapped: Variant = _behavior_map.get(behav_str, null)
	if mapped is Dictionary:
		var ename: Variant = (mapped as Dictionary).get("behavior", null)
		if ename is String:
			return int(EnemyEnums.Behavior.get(ename, EnemyEnums.Behavior.CHASE))
	return int(EnemyEnums.BEHAVIOR_MAP.get(behav_str, EnemyEnums.Behavior.CHASE))

# ========== 音频路径接口（F1-E-3 第三批 · 2026-08-18 总指挥承接） ==========

## 获取音频路径抽表（presentation.json audio_map 优先——原 audio_manager.gd const
## BGM_MAP/SFX_MAP 数据化；未命中/空表由消费端 audio_manager 回退 const 兜底，
## F 系列缺省兜底约定，抽表后旧值仍可启动）。
## 返回 {音频id: {"category": "bgm|sfx", "path": "res://..."}} 整表字典；
## 数据表缺失或损坏 → 空字典（消费端 const 兜底，零崩）。
func get_audio_config() -> Dictionary:
	if _audio_map.is_empty():
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/presentation.json"))
		if raw is Dictionary and (raw as Dictionary).get("audio_map") is Dictionary:
			_audio_map = (raw as Dictionary)["audio_map"]
	return _audio_map

# ========== 技能树接口（G-E · 2026-08-14） ==========

## 技能树全表（缺失 → {} → SkillTreePanel 空态零崩）
func get_skill_tree() -> Dictionary:
	return _skill_tree
