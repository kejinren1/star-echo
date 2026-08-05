## 武器基类 (Resource)
## 所有武器数据继承此类：近战/远程/范围/召唤
## 武器逻辑由 WeaponController 驱动自动攻击
extends Resource
class_name Weapon

# ========== 信号 ==========

signal weapon_fired

# ========== 导出属性 ==========

@export_group("基本信息")
@export var weapon_name: String = "未命名武器"   ## 武器名称
@export var weapon_type: String = "melee"      ## 武器类型: melee/ranged/area/summon
@export var description: String = ""            ## 描述文本
@export var icon: Texture2D                     ## 图标 (备用, 优先使用 icon_index)
@export var icon_index: int = 0                  ## 图标在 sprite sheet 中的索引 (IconAtlas 用)
@export var rarity: String = "common"           ## 稀有度: common/uncommon/rare/epic/legendary

@export_group("战斗属性")
@export var base_damage: float = 10.0           ## 基础伤害
@export var fire_rate: float = 1.0              ## 攻击频率 (次/秒)
@export var projectile_speed: float = 400.0     ## 弹速 (远程武器)
@export var projectile_count: int = 1           ## 弹丸数量
@export var attack_range: float = 200.0         ## 攻击范围
@export var pierce: int = 0                     ## 穿透次数
@export var knockback: float = 0.0              ## 击退力
@export var spread_angle: float = 0.0           ## 散射角度 (度)
@export var lifetime: float = 2.0               ## 弹丸存活时间
## 暴击率 (0~1) / 暴击伤害倍率（D7-T2：build 时从 JSON 读，旧武器默认 0.0/1.0）
## 暴击结算判定归 Day 13 公式统一，本字段仅装配层透传
@export var crit_chance: float = 0.0
@export var crit_damage: float = 1.0

@export_group("成长属性")
@export var level: int = 1                      ## 武器等级
@export var max_level: int = 5                  ## 最大等级

# ========== 逐级数据（Day 5 · D5-T2） ==========

## JSON `levels[]` 逐级状态表（8 条 = Lv1~Lv8 的绝对状态值，非 delta）；
## 为空时升级走通用成长兜底（×1.25 / ×1.1，旧武器）
var level_table: Array = []
## 环绕武器数据（blade_count/orbit_radius/orbit_speed），仅在 JSON 带 blade_count 时非空；
## 升级时由 levels 表覆写（D5-T2）
var orbit_data: Dictionary = {}

# ========== 内部状态 ==========

var _cooldown: float = 0.0                      ## 冷却计时器

# ========== 攻击逻辑 ==========

## 检查是否可以攻击
func can_fire(delta: float) -> bool:
	_cooldown -= delta
	return _cooldown <= 0.0

## 执行攻击（由 WeaponController 调用）
## 返回是否成功攻击
func fire(origin: Node2D, _target: Node2D) -> bool:
	if _cooldown > 0.0:
		return false
	_cooldown = 1.0 / fire_rate
	_perform_attack(origin, _target)
	weapon_fired.emit()
	return true

## 实际攻击逻辑（子类重写）
func _perform_attack(_origin: Node2D, _target: Node2D) -> void:
	pass

# ========== 升级 ==========

## 升级武器，返回是否成功
func upgrade() -> bool:
	if level >= max_level:
		return false
	level += 1
	_on_upgrade()
	return true

## 升级时的属性提升（D5-T2 改查表）：
## 优先读 `levels[level-1]`（upgrade() 已先 level += 1，故 level-1 恰为新等级索引），
## 逐键绝对覆盖底层字段；表空时回退旧武器通用成长（×1.25 / ×1.1）
func _on_upgrade() -> void:
	if level_table.is_empty():
		base_damage *= 1.25
		fire_rate *= 1.1
		return
	var idx: int = level - 1
	if idx < 0 or idx >= level_table.size():
		return
	var entry: Dictionary = level_table[idx]
	if entry.has("damage"):
		base_damage = float(entry["damage"])
	if entry.has("cooldown"):
		# JSON 用「冷却秒数」，Weapon 用「每秒次数」（D2 同款口径：取倒数）
		fire_rate = 1.0 / maxf(float(entry["cooldown"]), 0.01)
	if entry.has("projectiles"):
		projectile_count = maxi(int(entry["projectiles"]), 1)
	if entry.has("range"):
		attack_range = float(entry["range"])
	if entry.has("blade_count") or entry.has("orbit_radius") or entry.has("orbit_speed"):
		orbit_data["blade_count"] = int(entry.get("blade_count", orbit_data.get("blade_count", 1)))
		orbit_data["orbit_radius"] = float(entry.get("orbit_radius", orbit_data.get("orbit_radius", 110.0)))
		orbit_data["orbit_speed"] = float(entry.get("orbit_speed", orbit_data.get("orbit_speed", 180.0)))
	# D7-T2：消费 levels 中可选进阶键（crit_chance/crit_damage/pierce）——
	# 本日 11 把 levels 未放进阶键，兼容未来 Day 8-9 放键不漏消费（2 行级低风险）
	if entry.has("crit_chance"):
		crit_chance = float(entry["crit_chance"])
	if entry.has("crit_damage"):
		crit_damage = float(entry["crit_damage"])
	if entry.has("pierce"):
		pierce = maxi(int(entry["pierce"]), 0)

# ========== 属性查询 ==========

## 获取最终伤害（含等级加成）
func get_damage() -> float:
	return base_damage

## 获取实际攻击间隔
func get_attack_interval() -> float:
	return 1.0 / fire_rate
