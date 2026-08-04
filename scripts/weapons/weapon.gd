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

@export_group("成长属性")
@export var level: int = 1                      ## 武器等级
@export var max_level: int = 5                  ## 最大等级

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

## 升级时的属性提升（子类重写）
func _on_upgrade() -> void:
	base_damage *= 1.25
	fire_rate *= 1.1

# ========== 属性查询 ==========

## 获取最终伤害（含等级加成）
func get_damage() -> float:
	return base_damage

## 获取实际攻击间隔
func get_attack_interval() -> float:
	return 1.0 / fire_rate
