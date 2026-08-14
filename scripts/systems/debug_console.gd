## 调试金手指组件（F4-T5 · 2026-08-14 从 game_manager.gd 拆出）
## 职责：F-04 ↑+↓ toggle（跳关 + 攻击 ×10 + 受伤 0.1%）+ 状态横幅
## 范式：无 class_name；GM preload 本组件（组件不引用 Autoload 标识符，无循环 preload）；
##      setup(gm) 注入宿主引用——debug_cheat 字段由 GM 持有（探针 day17_p0 直接 get/set）
extends Node

## 宿主 GameManager 实例（GM._ready 挂载时注入）
var _gm: Node = null

func setup(gm: Node) -> void:
	_gm = gm

## ↑+↓ 同按 → toggle：跳关 + 攻击 ×10 + 受伤 0.1%。机器可验证（探针白盒直调）。
## 攻击倍率走 player.debug_mult（weapon_controller/skill_controller 聚合消费）；
## 受伤 0.1% 走 player.take_damage 消费。关闭全还原（debug_mult 1.0 / 无残留状态）。
func toggle_debug_cheat() -> void:
	_gm.debug_cheat = not _gm.debug_cheat
	if _gm.player and "debug_mult" in _gm.player:
		_gm.player.debug_mult = 10.0 if _gm.debug_cheat else 1.0
	if _gm.debug_cheat and int(_gm.current_state) == 1:  # 1 = GameState.BATTLE（枚举经宿主访问）
		# 跳关：清残敌 + 直接进入下一波（仅战斗状态可跳，防路线选择/商店误触）
		_gm._clear_remaining_enemies()
		_gm._start_next_wave(int(_gm.current_wave) + 1)
	_show_debug_banner()

## 金手指状态横幅（1.5s 淡出，复用精英横幅范式；容器缺失静默跳过）
func _show_debug_banner() -> void:
	var container: Node = _gm.vfx_container if _gm.vfx_container else null
	if container == null:
		container = _gm.get_tree().current_scene
	if container == null:
		return
	var banner := Node2D.new()
	banner.name = "DebugBanner"
	var label := Label.new()
	label.text = "🛠 金手指 %s（攻击×10 · 受伤0.1%%）" % ("ON" if _gm.debug_cheat else "OFF")
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.6, 0.95, 0.6))
	banner.add_child(label)
	container.add_child(banner)
	banner.global_position = Vector2(320.0, 130.0)
	var tween := banner.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "modulate:a", 0.0, 1.5)
	tween.tween_property(banner, "global_position:y", banner.global_position.y - 30.0, 1.5)
	tween.chain().tween_callback(banner.queue_free)
