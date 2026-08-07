## 伤害数字飘字（F-11 · 用户拍板 2026-08-06）
## 由 enemy.take_damage 在受击时调用（所有伤害来源汇聚点：线弹/爆炸/炮台/环绕刃）。
## 普通伤害 = 浅黄小字上浮淡出；暴击 = 更大字号 + 金色 + 「!」（用户反馈「暴击无特殊
## 字体/颜色，数值感知为零」）。
##
## 实现范式与 enemy._spawn_exp_popup 一致：Label 挂 vfx 容器 → tween 上浮淡出 → queue_free。
## 容器缺失（纯数据无头测试）静默跳过不崩——测试环境零副作用。
class_name DamageNumber
extends RefCounted

const DURATION: float = 0.7   ## 上浮淡出总时长（秒）

## 生成一个伤害数字。amount 四舍五入取整显示；is_crit → 暴击样式（字号 18 金色 + 后缀 !）
## 返回生成的 Label（容器缺失返回 null，测试可断言）
static func spawn(container: Node, world_pos: Vector2, amount: float, is_crit: bool = false) -> Label:
	if container == null:
		return null
	var label := Label.new()
	var display: int = maxi(int(round(amount)), 1)
	if is_crit:
		label.text = "%d!" % display
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.2))
	else:
		label.text = "%d" % display
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", Color(1.0, 0.94, 0.7))
	container.add_child(label)
	label.global_position = world_pos + Vector2(randf_range(-8.0, 8.0), -16.0)
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position:y", label.global_position.y - 24.0, DURATION)
	tween.tween_property(label, "modulate:a", 0.0, DURATION)
	tween.chain().tween_callback(label.queue_free)
	return label
