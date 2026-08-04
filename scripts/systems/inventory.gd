## 背包/库存系统
## 管理玩家持有的武器和道具
extends Node

# ========== 信号 ==========

signal weapon_added(weapon: Resource)
signal weapon_removed(index: int)
signal item_added(item: Resource)
signal item_removed(index: int)
signal inventory_full(category: String)

# ========== 常量 ==========

const MAX_WEAPONS: int = 6                    ## 最大武器槽
const MAX_ITEMS: int = 20                     ## 最大道具槽

# ========== 属性 ==========

var weapons: Array[Resource] = []             ## 武器列表
var items: Array[Resource] = []               ## 道具列表

# ========== 武器管理 ==========

## 添加武器，返回是否成功
func add_weapon(weapon: Resource) -> bool:
	if weapons.size() >= MAX_WEAPONS:
		inventory_full.emit("weapon")
		return false
	weapons.append(weapon)
	weapon_added.emit(weapon)
	return true

## 移除武器
func remove_weapon(index: int) -> void:
	if index >= 0 and index < weapons.size():
		var removed = weapons.pop_at(index)
		weapon_removed.emit(index)

# ========== 道具管理 ==========

## 添加道具，返回是否成功
func add_item(item: Resource) -> bool:
	if items.size() >= MAX_ITEMS:
		inventory_full.emit("item")
		return false
	items.append(item)
	item_added.emit(item)
	return true

## 移除道具
func remove_item(index: int) -> void:
	if index >= 0 and index < items.size():
		items.pop_at(index)
		item_removed.emit(index)

# ========== 属性计算 ==========

## 计算所有道具提供的某项属性加成总值
func get_stat_bonus(stat_name: String) -> float:
	var total: float = 0.0
	for item in items:
		if item and item.has_method("get_stat"):
			total += item.get_stat(stat_name)
	return total

## 获取所有道具的属性加成汇总
func get_all_stat_bonuses() -> Dictionary:
	var bonuses: Dictionary = {}
	for item in items:
		if not item:
			continue
		if item.has_method("get_all_stats"):
			var stats: Dictionary = item.get_all_stats()
			for key in stats:
				if bonuses.has(key):
					bonuses[key] += stats[key]
				else:
					bonuses[key] = stats[key]
	return bonuses

# ========== 查询 ==========

func get_weapon_count() -> int:
	return weapons.size()

func get_item_count() -> int:
	return items.size()

func is_weapon_slots_full() -> bool:
	return weapons.size() >= MAX_WEAPONS

func is_item_slots_full() -> bool:
	return items.size() >= MAX_ITEMS

## 重置背包
func reset() -> void:
	weapons.clear()
	items.clear()
