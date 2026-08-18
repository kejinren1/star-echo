## 通关传送门（F-49 · 2026-08-18 用户拍板：通关后不立即结算——进传送门才结算）
## 敌全灭/Boss 击杀 → wave_manager._open_exit_portal() → world.spawn_exit_portal()
## 在地图中心生成本节点 + 宝箱；玩家接触传送门 → wave_manager.enter_portal() → 正常结算
## 视觉：占位纯色（紫色圆环旋转 + 深紫内芯），项目美术占位口径（08-07 拍板）
## 探针：Area2D body_entered 依赖物理不步进 → 白盒直调 _on_body_entered 测逻辑
extends Node2D

var _ring: Polygon2D = null
var _spin: float = 0.0

func _ready() -> void:
	# 占位视觉：外环（紫色半透明）+ 内芯（深紫）
	_ring = Polygon2D.new()
	_ring.polygon = _circle_points(34.0, 20)
	_ring.color = Color(0.6, 0.3, 0.9, 0.35)
	add_child(_ring)
	var core := Polygon2D.new()
	core.polygon = _circle_points(18.0, 14)
	core.color = Color(0.35, 0.12, 0.65, 0.9)
	add_child(core)
	# 接触检测（玩家触碰 → 进入结算）
	var area := Area2D.new()
	area.name = "Area2D"
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 40.0
	shape.shape = circle
	area.add_child(shape)
	area.body_entered.connect(_on_body_entered)
	add_child(area)

func _process(delta: float) -> void:
	_spin += delta * 2.0
	if _ring:
		_ring.rotation = _spin

func _circle_points(radius: float, segments: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in segments:
		var a: float = TAU * i / segments
		pts.append(Vector2(cos(a), sin(a)) * radius)
	return pts

## 玩家接触 → 通知 wave_manager 进入结算（玩家无 group，用 GameManager.player 引用比对；
## 探针无物理 → 白盒直调本方法测玩家判定 + enter_portal 链路）
func _on_body_entered(body: Node) -> void:
	if GameManager == null or GameManager.player == null or GameManager.wave_manager == null:
		return
	if body != GameManager.player:
		return
	GameManager.wave_manager.call("enter_portal")
