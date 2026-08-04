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

## 消费金币，返回是否成功
func spend_coins(amount: int) -> bool:
	if coins < amount:
		insufficient_funds.emit()
		return false
	coins -= amount
	coins_changed.emit(coins)
	coins_spent.emit(amount)
	return true

## 重置金币
func reset() -> void:
	coins = 0
	coins_changed.emit(coins)
