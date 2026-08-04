## 道具基类 (Resource)
## 被动增益道具数据，提供属性加成和特殊效果
extends Resource

# ========== 导出属性 ==========

@export_group("基本信息")
@export var item_name: String = "未知道具"       ## 道具名称
@export var description: String = ""            ## 描述文本
@export var icon: Texture2D                     ## 图标 (备用, 优先使用 icon_index)
@export var icon_index: int = 0                  ## 图标在 sprite sheet 中的索引 (IconAtlas 用)
@export var rarity: String = "common"           ## 稀有度
@export var price: int = 50                     ## 商店价格

@export_group("属性加成")
@export var stat_bonuses: Dictionary = {}       ## 属性加成 { "max_health": 20.0, "move_speed": 10.0, ... }

# ========== 属性查询 ==========

## 获取指定属性的加成值
func get_stat(stat_name: String) -> float:
	return stat_bonuses.get(stat_name, 0.0)

## 获取所有属性加成
func get_all_stats() -> Dictionary:
	return stat_bonuses

## 是否有指定属性加成
func has_stat(stat_name: String) -> bool:
	return stat_bonuses.has(stat_name)
