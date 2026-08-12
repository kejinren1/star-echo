## 经济系统
## 管理金币的获取和消耗
extends Node

# ========== 信号 ==========

signal coins_changed(amount: int)
signal coins_gained(amount: int)
signal coins_spent(amount: int)
signal insufficient_funds

# ========== 属性 ==========

var coins: int = 0                            ## 当前金币数

# ========== 接口方法 ==========

## 增加金币
func add_coins(amount: int) -> void:
	if amount <= 0:
		return
	coins += amount
	coins_changed.emit(coins)
	coins_gained.emit(amount)
	AudioManager.play_sfx("coin")   # D24-T3-⑥：金币 SFX

## 消费金币，返回是否成功
func spend_coins(amount: int) -> bool:
	if coins < amount:
		insufficient_funds.emit()
		return false
	coins -= amount
	coins_changed.emit(coins)
	coins_spent.emit(amount)
	return true

## F2-T2（T-037）：能否支付（shop 购买前置拒绝查询接口，消灭 UI 直读 coins 字段）
func can_afford(price: int) -> bool:
	return price >= 0 and coins >= price

## F2-T2（T-037）：金币余额查询（shop label 显示 / push_warning 文案读余额收口；
## grep 口径禁止 UI 层 economy.coins 直读）
func get_coins() -> int:
	return coins

## 重置金币
func reset() -> void:
	coins = 0
	coins_changed.emit(coins)
