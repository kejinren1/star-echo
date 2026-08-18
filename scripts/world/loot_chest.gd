## 通关宝箱（F-49 · 2026-08-18 用户拍板：进传送门结算前可捡掉落宝箱）
## 敌全灭 → world.spawn_exit_portal() 与传送门一同生成；玩家接触拾取 → 奖励 + 光效 + 消失
## 奖励占位：金币 50 + 经验 30（固定值；RELIC-E「Boss 宝箱遗物三选一」Day31+ 拆解中，
## 落地后替换本奖励——本节点为通关收获流程地基）
## 视觉：占位纯色金色方块（项目美术占位口径）
## 探针：body_entered 依赖物理 → 白盒直调 _on_body_entered 测拾取链路
extends Node2D

var _claimed: bool = false

func _ready() -> void:
	# 占位视觉：金色方块
	var box := ColorRect.new()
	box.size = Vector2(26, 26)
	box.position = Vector2(-13, -13)
	box.color = Color(0.95, 0.75, 0.2)
	add_child(box)
	# 接触检测（玩家触碰 → 拾取）
	var area := Area2D.new()
	area.name = "Area2D"
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(44, 44)
	shape.shape = rect
	area.add_child(shape)
	area.body_entered.connect(_on_body_entered)
	add_child(area)

## 玩家接触 → 奖励 + 光效 + 音效 + 消失（探针无物理 → 白盒直调）
func _on_body_entered(body: Node) -> void:
	if _claimed or GameManager == null or GameManager.player == null:
		return
	if body != GameManager.player:
		return
	_claimed = true
	if GameManager.economy and GameManager.economy.has_method("add_coins"):
		GameManager.economy.call("add_coins", 50)
	if GameManager.player and GameManager.player.has_method("gain_exp"):
		GameManager.player.call("gain_exp", 30)
	if GameManager.vfx_container:
		VfxPlayer.spawn(GameManager.vfx_container, global_position, "levelup")
	AudioManager.play_sfx("coin")
	queue_free()
