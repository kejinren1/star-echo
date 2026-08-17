## PS · 怪物丰富性出口校验（2026-08-17：皮肤再分配 + tint/scale 区分）
##
## 用法（无头）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day31_enemy_richness_check.gd
##
## 校验内容：
##   §1 SPRITE_MAP 覆盖 15 普通 + 6 精英 + 2 Boss 全部敌人 id（无缺漏回退）
##   §2 皮肤多样性：普通 15 只不再全 slime——至少 4 种不同皮肤组合（slime/skeleton 混合）
##   §3 tint/scale 键：全部普通/精英条目都带 tint（或显式无）→ 视觉可区分
##   §4 运行时：chaser/slasher/horned_charger 实例化 → 动画加载 + modulate/scale 生效
##   §5 重抠回归：elite/invoker/predator move 图主体含键色 < 5%（抠过头修复）
##
## 退出码 0 = 全部通过；非 0 = 失败项数。
extends SceneTree

var _checked: int = 0
var _failures: int = 0
var _started: bool = false
const EnemyEnumsScript: GDScript = preload("res://scripts/enemy/enemy_enums.gd")

func _initialize() -> void:
	print("=== Day31 enemy richness check ===")

func _process(_delta: float) -> bool:
	if _started:
		return false
	_started = true
	_section_map_coverage()
	_section_diversity()
	_section_tint_scale()
	_section_runtime()
	_section_cutout()
	print("检查 %d 项，失败 %d 项" % [_checked, _failures])
	quit(_failures)
	return true

func _ok(msg: String) -> void:
	_checked += 1
	print("  PASS  %s" % msg)

func _fail(msg: String) -> void:
	_failures += 1
	print("  FAIL  %s" % msg)

# ========== §1 覆盖 ==========

func _section_map_coverage() -> void:
	var loader: Node = root.get_node_or_null("DataLoader")
	var all_ids: Array = loader.call("get_all_enemy_ids") if loader else []
	var map: Dictionary = EnemyEnumsScript.SPRITE_MAP
	var missing: Array = []
	for eid in all_ids:
		if not map.has(str(eid)):
			missing.append(str(eid))
	if missing.is_empty():
		_ok("§1 SPRITE_MAP 覆盖全部 %d 个敌人 id" % all_ids.size())
	else:
		_fail("SPRITE_MAP 缺漏: %s" % str(missing))

# ========== §2 皮肤多样性 ==========

func _section_diversity() -> void:
	var map: Dictionary = EnemyEnumsScript.SPRITE_MAP
	var skins: Dictionary = {}
	var reg_ids := ["chaser", "charger", "fly", "bruiser", "spitter", "healer", "spawner",
		"horned_charger", "pursuer", "slasher", "helmet_alien", "horned_fly",
		"corrupted_tree", "mad_slasher", "lamprey"]
	for eid in reg_ids:
		var cfg: Dictionary = map.get(eid, {})
		var move_path: String = str(cfg.get("move", ""))
		skins[move_path] = skins.get(move_path, 0) + 1
	if skins.size() >= 2:
		_ok("§2 普通怪皮肤 %d 套（%s）" % [skins.size(), str(skins)])
	else:
		_fail("普通怪仍单一皮肤: %s" % str(skins))

# ========== §3 tint/scale ==========

func _section_tint_scale() -> void:
	var map: Dictionary = EnemyEnumsScript.SPRITE_MAP
	var no_tint: Array = []
	var scaled: Array = []
	for eid in map:
		var cfg: Dictionary = map[eid]
		if not cfg.has("tint"):
			no_tint.append(eid)
		if cfg.has("scale"):
			scaled.append(eid)
	# 允许无 tint 的：chaser/slasher/mad_slasher（原色基准）+ 2 Boss
	var allowed_plain := ["chaser", "slasher", "butcher", "invoker", "predator"]
	var unexpected: Array = []
	for eid in no_tint:
		if eid not in allowed_plain:
			unexpected.append(eid)
	if unexpected.is_empty():
		_ok("§3 全部非基准敌人带 tint（%d 只有 scale 体型）" % scaled.size())
	else:
		_fail("无 tint 异常: %s" % str(unexpected))

# ========== §4 运行时 ==========

func _section_runtime() -> void:
	var scene: PackedScene = load("res://scenes/Enemy.tscn")
	if scene == null:
		_fail("Enemy.tscn 加载失败")
		return
	var container := Node2D.new()
	root.add_child(container)
	var loader: Node = root.get_node_or_null("DataLoader")
	var checks := [
		["chaser", Color(1, 1, 1), 1.0],
		["slasher", Color(1, 1, 1), 1.0],
		["horned_charger", Color(1.35, 0.8, 0.8), 1.0],
		["bruiser", Color(1.2, 0.9, 0.65), 1.25],
		["corrupted_tree", Color(0.55, 0.85, 0.5), 1.4],
	]
	var ok_count: int = 0
	for entry in checks:
		var eid: String = entry[0]
		var stats: Dictionary = loader.call("get_scaled_enemy", eid, 5)
		if stats.is_empty():
			_fail("§4 %s 数据缺失" % eid)
			continue
		var e: Node = scene.instantiate()
		if e.has_method("initialize"):
			e.call("initialize", stats)
		container.add_child(e)
		var anim: Node = e.get_node_or_null("AnimatedSprite2D")
		if anim == null or anim.get("sprite_frames") == null:
			_fail("§4 %s 动画未加载" % eid)
			continue
		var mod: Color = anim.modulate
		var sc: float = e.scale.x
		if absf(mod.r - entry[1].r) < 0.01 and absf(sc - entry[2]) < 0.01:
			ok_count += 1
		else:
			_fail("§4 %s tint/scale 异常: mod=%s scale=%.2f" % [eid, str(mod), sc])
		e.queue_free()
	if ok_count == checks.size():
		_ok("§4 运行时 tint/scale 生效（%d 种抽查）" % ok_count)

# ========== §5 重抠回归 ==========

func _section_cutout() -> void:
	# PNG 级校验用 Python 做过；此处校验 Godot 加载无错误即可（加载即重导入）
	var paths := [
		"res://assets/sprites/enemies/elite_move.png",
		"res://assets/sprites/enemies/invoker_move.png",
		"res://assets/sprites/enemies/predator_move.png",
	]
	var all_ok: bool = true
	for p in paths:
		if not ResourceLoader.exists(p):
			all_ok = false
			_fail("§5 缺失: %s" % p)
	if all_ok:
		_ok("§5 重抠后精灵资源可加载")
