## 探针假目标（PS-B4 位移落点伤害 + invulnerable 用例）：极简 Node2D
extends Node2D
var health: float = 100.0
var is_alive: bool = true
## PS-B3：invulnerable 效果标志（status_component _apply/_revert 读写）
var invulnerable: bool = false
func take_damage(amount: float) -> void:
	if not is_alive or invulnerable:
		return
	health -= amount
	if health <= 0.0:
		is_alive = false
func apply_knockback(_v: Vector2) -> void:
	pass
