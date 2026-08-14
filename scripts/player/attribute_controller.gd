## 属性系统组件（F4-T6 · 2026-08-14 从 player.gd 拆出）
## 职责：STAT_MAP 全量映射 + bonus_stats 白名单收拢（P0-Bug2 核心）+ apply_stat_modifier
## 范式：无 class_name；player preload 本组件（组件被 player 运行期编译，Autoload 已注册）；
##      setup(player) 注入宿主引用——STAT_MAP/bonus_stats 等经宿主保留（探针直接读写）
extends Node

# ========== 属性映射（原 player.gd STAT_MAP，F4-C 迁出） ==========
## characters.json 的 passive/penalty 键 → apply_stat_modifier 的合法 stat 名
## mode: "add" 直接加 / "percent" 百分数转倍率乘算 / "ratio" 百分数转 0~1 后加
const STAT_MAP: Dictionary = {
	"max_hp": {"stat": "max_health", "mode": "add"},
	"speed_percent": {"stat": "move_speed", "mode": "percent"},
	"armor": {"stat": "armor", "mode": "add"},
	"regen": {"stat": "regen", "mode": "add"},
	"hp_regen": {"stat": "regen", "mode": "add"},
	"dodge_percent": {"stat": "dodge", "mode": "ratio"},
	"crit_chance_percent": {"stat": "crit_chance", "mode": "ratio"},
	"attack_speed_percent": {"stat": "attack_speed", "mode": "percent"},
	"melee_attack_speed_percent": {"stat": "attack_speed", "mode": "percent"},
	"damage_percent": {"stat": "damage", "mode": "percent"},
	"range_percent": {"stat": "range", "mode": "percent"},
	"luck": {"stat": "luck", "mode": "add"},
	"pickup_range": {"stat": "pickup_range", "mode": "add"},
	"life_steal_percent": {"stat": "life_steal", "mode": "ratio"},  ## D4-T3：莱恩 passive 5 → 0.05 进通道
	"crit_damage_percent": {"stat": "crit_damage", "mode": "percent"},  ## D11-12-T3：se_blade_core 20 → ×1.2（2.0→2.4）
	"damage_taken_percent": {"stat": "damage_taken_mult", "mode": "percent"},      ## D20-T2：破碎王冠 30 → ×1.3（take_damage armor 后乘）
	"structure_damage_percent": {"stat": "structure_damage_mult", "mode": "percent"},  ## D20-T2：机械引擎 100 → ×2.0（turret 弹药消费，D20-T6 §5）
}

## 刻意不进 STAT_MAP 的键（进 bonus_stats 等后续系统消费），附不映射的原因
## `range`：JSON 里是「像素平直加减」（如 brawler -50），而 range_multiplier 是倍率，
##          直接加会把倍率打成负数使武器射程失效 —— 口径统一属 Day 4 强化面板的决策
const STAT_MAP_EXCLUDED: PackedStringArray = ["range"]

## P0-Bug2 修复（2026-08-10）：未映射键中「已有消费方」的白名单 —— 收进 bonus_stats 即生效，不警告
## 消费方：orbit_blade_count → orbit_weapon.gd；elemental_damage → skill_controller 燃烧 dps；
##         summon_count → skill_controller 炮台数量。
## F1-G（2026-08-10）：xp_gain_percent → gain_exp；melee_damage/ranged_damage/knockback/
##         boss_elite_damage_percent → weapon_controller 伤害/击退计算。其余未映射键无消费方 →
##         收进 bonus_stats + 警告登记
const CONSUMED_BONUS_KEYS: PackedStringArray = [
	"orbit_blade_count", "elemental_damage", "summon_count",
	"xp_gain_percent", "melee_damage", "ranged_damage", "knockback",
	"boss_elite_damage_percent",
]

## 宿主 player 实例（player._ensure_components 挂载时注入）
var _player: CharacterBody2D = null

func setup(player: CharacterBody2D) -> void:
	_player = player

# ========== 角色属性装载（apply_character 属性段迁入） ==========

## 应用被动/惩罚两表（bonus_stats 由宿主持有，组件经 _player 访问）
func apply_character_stats(char_data: Dictionary) -> void:
	_apply_stat_dict(char_data.get("passive", {}))
	_apply_stat_dict(char_data.get("penalty", {}))

## 按 STAT_MAP 落实一组属性键；未映射的键原样收进 bonus_stats（禁止静默丢弃）
func _apply_stat_dict(source: Dictionary) -> void:
	if source.is_empty():
		return
	for key: String in source:
		var amount: float = float(source[key])
		if not STAT_MAP.has(key):
			# 同名键叠加而非覆盖（passive 与 penalty 可能命中同一键）
			_player.bonus_stats[key] = float(_player.bonus_stats.get(key, 0.0)) + amount
			continue
		var rule: Dictionary = STAT_MAP[key]
		var stat_name: String = str(rule["stat"])
		match str(rule["mode"]):
			"add":
				apply_stat_modifier(stat_name, amount)
			"percent":
				apply_stat_modifier(stat_name, 1.0 + amount / 100.0, true)
			"ratio":
				apply_stat_modifier(stat_name, amount / 100.0)

## D11-12-T3：被动道具装配（买了必生效）/ 回退（remove=true 反向还原）
## P0-Bug2 修复（2026-08-10）：未映射键不再静默跳过 —— 一律收进 bonus_stats（与角色
## _apply_stat_dict 同口径）；已有消费方的键（CONSUMED_BONUS_KEYS）零噪音生效，
## 无消费方的键 push_warning 显式暴露。percent 模式 remove 用除法精确还原。
func apply_item_bonuses(item: Resource, remove: bool = false) -> void:
	if item == null or not item.has_method("get_stat"):
		return
	var bonuses: Dictionary = item.call("get_all_stats")
	if bonuses.is_empty():
		return
	for key: String in bonuses:
		var amount: float = float(bonuses[key])
		if not STAT_MAP.has(key):
			# P0-Bug2：收进 bonus_stats（数值不丢，remove 对称还原）
			if remove:
				_player.bonus_stats[key] = float(_player.bonus_stats.get(key, 0.0)) - amount
			else:
				_player.bonus_stats[key] = float(_player.bonus_stats.get(key, 0.0)) + amount
			# 无消费方的键仍显式暴露（有消费方 = 白名单零噪音）
			if not CONSUMED_BONUS_KEYS.has(key):
				push_warning("[Player] 被动效果键无消费方，仅登记 bonus_stats: %s" % key)
			continue
		var rule: Dictionary = STAT_MAP[key]
		var stat_name: String = str(rule["stat"])
		if remove:
			amount = -amount
		match str(rule["mode"]):
			"add":
				apply_stat_modifier(stat_name, amount)
			"percent":
				if remove:
					# amount 已取负，absf 还原原倍率分母 → 除法撤销
					apply_stat_modifier(stat_name, 1.0 / (1.0 + absf(amount) / 100.0), true)
				else:
					apply_stat_modifier(stat_name, 1.0 + amount / 100.0, true)
			"ratio":
				apply_stat_modifier(stat_name, amount / 100.0)

# ========== 属性修改接口（原 player.apply_stat_modifier） ==========

## 应用属性修改（供道具系统/增益注入/技能树调用；签名保留——main D42 / G-R6 消费）
func apply_stat_modifier(stat_name: String, value: float, is_multiplicative: bool = false) -> void:
	match stat_name:
		"max_health":
			if is_multiplicative:
				_player.max_health *= value
			else:
				_player.max_health += value
			_player.health = min(_player.health, _player.max_health)
		"move_speed":
			_player.move_speed = apply_value(_player.move_speed, value, is_multiplicative)
		"armor":
			_player.armor = apply_value(_player.armor, value, is_multiplicative)
		"damage":
			_player.damage_multiplier = apply_value(_player.damage_multiplier, value, is_multiplicative)
		"attack_speed":
			_player.attack_speed = apply_value(_player.attack_speed, value, is_multiplicative)
		"crit_chance":
			_player.crit_chance = apply_value(_player.crit_chance, value, is_multiplicative)
		"range":
			_player.range_multiplier = apply_value(_player.range_multiplier, value, is_multiplicative)
		"regen":
			_player.regen = apply_value(_player.regen, value, is_multiplicative)
		"pickup_range":
			_player.pickup_range = apply_value(_player.pickup_range, value, is_multiplicative)
		"crit_damage":
			_player.crit_damage = apply_value(_player.crit_damage, value, is_multiplicative)
		"dodge":
			# T-013（F1-散 2026-08-13）：闪避上限参数化 = stats.combat.dodge_cap（缺表兜底 0.9）
			_player.dodge = clampf(apply_value(_player.dodge, value, is_multiplicative), 0.0,
				float(DataLoader.get_stats_combat().get("dodge_cap", 0.9)))
		"luck":
			_player.luck = apply_value(_player.luck, value, is_multiplicative)
		"life_steal":
			_player.life_steal = clampf(apply_value(_player.life_steal, value, is_multiplicative), 0.0, 1.0)
		"damage_taken_mult":  ## D20-T2：受伤倍率（percent 键乘算；remove 走除法还原）
			_player.damage_taken_mult = apply_value(_player.damage_taken_mult, value, is_multiplicative)
		"structure_damage_mult":  ## D20-T2：结构伤害倍率（turret 弹药消费）
			_player.structure_damage_mult = apply_value(_player.structure_damage_mult, value, is_multiplicative)
		"coin_bonus":
			_player.coin_bonus = apply_value(_player.coin_bonus, value, is_multiplicative)
	_player.stats_changed.emit()

func apply_value(base: float, mod: float, multiplicative: bool) -> float:
	if multiplicative:
		return base * mod
	else:
		return base + mod
