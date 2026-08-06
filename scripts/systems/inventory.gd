## 背包/库存系统
## 管理玩家持有的武器和道具
extends Node

# ========== 信号 ==========

signal weapon_added(weapon: Resource)
signal weapon_removed(index: int)
signal item_added(item: Resource)
signal item_removed(item: Resource)   ## D11-12-T3：改传被移除道具本体（被动回退装配需读 stat_bonuses）
signal inventory_full(category: String)

# ========== 资源引用 ==========

## preload 而非依赖 class_name：item.gd 暂无 class_name Item，preload 更稳
const Item: GDScript = preload("res://scripts/items/item.gd")

# ========== 常量 ==========

const MAX_WEAPONS: int = 6                    ## 最大武器槽
const MAX_ITEMS: int = 6                      ## 最大被动槽（大纲 6 被动槽；D11-12-T2 原 20→6）

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

## D11-12-T5：原位替换武器条目（weapon_controller.replace_weapon 同步用，进化后 HUD 显示结果武器）
## 返回是否成功；成功时 emit weapon_added 让 HUD 槽位刷新
func replace_weapon_slot(index: int, weapon: Resource) -> bool:
	if index < 0 or index >= weapons.size():
		return false
	weapons[index] = weapon
	weapon_added.emit(weapon)
	return true

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
		var removed: Resource = items.pop_at(index)
		item_removed.emit(removed)

# ========== 属性计算 ==========

## 按 items.json id 构造道具并入库（D10-T2）
## 未知 id → push_warning + false；道具槽满（>= MAX_ITEMS）→ false
func add_item_from_data(item_id: String) -> bool:
	if item_id.is_empty():
		return false
	var data: Dictionary = DataLoader.get_item(item_id)
	if data.is_empty():
		push_warning("[Inventory] items.json 无此道具: %s" % item_id)
		return false
	var item: Resource = Item.new()
	item.item_id = item_id
	item.item_name = str(data.get("name", item_id))
	item.price = int(data.get("price", 0))
	item.rarity = str(data.get("rarity", "common"))
	item.icon_index = maxi(int(data.get("icon_index", 0)), 0)
	# D11-12-T3：槽位/分类透传（装配链路判断 slot=="passive" 用）
	item.slot = str(data.get("slot", ""))
	item.category = str(data.get("category", ""))
	item.stat_bonuses = data.get("effects", {})
	return add_item(item)

## 按 id 查询是否持有（D10-T2）
func has_item_id(item_id: String) -> bool:
	for item in items:
		if item and item.get("item_id") == item_id:
			return true
	return false

## 按 id 移除首个匹配道具（D10-T2）；找到并移除返回 true，无则 false
func remove_item_id(item_id: String) -> bool:
	for i in items.size():
		var item: Resource = items[i]
		if item and item.get("item_id") == item_id:
			remove_item(i)
			return true
	return false

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
