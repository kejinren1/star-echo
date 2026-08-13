## Day 21-22 出口校验：美术资产落地（阶段 D 首段 · D21-22-T1~T5）
##
## 用法（无头，不需要编辑器）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day21_22_art_check.gd
##
## 校验内容（对应 docs/SOLUTION_PLAN.md 第 4 轮任务 5 五段）：
##   §1 敌人：SPRITE_MAP(23) + FALLBACK(3) 全路径 ResourceLoader.exists；
##      size/move_frames/death_frames 与 PNG 实切（Image.load_from_file）一致——防映射与资产脱节；
##      hit_radius 锚点（slime 28 / elite 36 / boss 56）+ 未知 id 走 FALLBACK 兜底行为
##   §2 Boss scale：get_scaled_enemy("invoker", 10) 白盒 → scale == Vector2(1.0, 1.0)（D17 复位）
##   §3 角色：4 walk 192×32 + 4 idle 128×32 存在 + 帧非空；_apply_character_sprite("siia") 白盒
##      → walk_texture 非 fighter；attack/skill 动画接线（skill_cast 信号 → "skill" → 播完回 "idle"；
##      开火 → "attack"；缺帧前缀 → 无 attack 动画走 idle 降级）
##   §4 图标/概念图：factions 5 + backgrounds 4 + 遗留头像 3 存在 + 尺寸合规 + (0,0) 透明键
##   §5 回归锚点：全部新/覆写资产 .import 齐全；day2 角色数据（elin sprite 前缀）；day17 精英
##      ability 数据（butcher aoe 可解析）；普通敌人接触伤害仍按 hit_radius 判定（charger 28）
##
## 退出码 0 = 全部通过；非 0 = 失败项数。
extends SceneTree

const ENEMY_SCENE_PATH: String = "res://scenes/Enemy.tscn"

# 期望映射：分类 → hit_radius
const HIT_EXPECT: Dictionary = {"regular": 28.0, "elite": 36.0, "boss": 56.0}
# 期望 sheet：文件名 → (宽, 高)
const SHEET_EXPECT: Dictionary = {
	"slime_move.png": Vector2i(192, 48), "slime_death.png": Vector2i(192, 48),
	"skeleton_move.png": Vector2i(192, 48), "skeleton_death.png": Vector2i(192, 48),
	"elite_move.png": Vector2i(256, 64), "elite_death.png": Vector2i(256, 64),
	"invoker_move.png": Vector2i(512, 128), "invoker_death.png": Vector2i(512, 128),
	"predator_move.png": Vector2i(512, 128), "predator_death.png": Vector2i(512, 128),
}
const FACTIONS: Array = ["echo_alliance", "star_cult", "abyss_council", "mech_empire", "free_mercs"]
const BACKGROUNDS: Array = ["wulan_workshop", "corrupted_forest", "lava_mine", "void_corridor"]
const PORTRAITS: Array = ["brawler", "ranger", "mage"]
const HEROES: Array = ["elin", "noah", "lain", "siia"]

var _idx: int = 0
var _sub: int = 0
var _loader: Node = null
var _player: Node = null
var _enemy: Node = null
var _checked: int = 0
var _failures: int = 0
var _expect_loaded: bool = false


func _initialize() -> void:
	print("=== Day 21-22 art asset check ===")


func _process(_delta: float) -> bool:
	if not _expect_loaded:
		_load_mocks()
	if _idx >= 1:
		_report()
		quit(_failures)
		return true
	_sub = _advance(_sub)
	return false


func _load_mocks() -> void:
	_expect_loaded = true
	_loader = root.get_node_or_null("DataLoader")
	if _loader == null:
		_fail("DataLoader autoload 缺失")
		_report()
		quit(_failures)
		return
	# mock vfx_container：真实游戏由 Main 场景装配（_resolve_fx_container 短路用）；
	# 缺省 null 会让 Boss initialize → _show_boss_phase_banner 走到 get_tree() 分支，
	# 在未入树节点上触发 C++ 层 "Parameter data.tree is null" ERROR 噪音（node.h:446）
	var gm: Node = root.get_node_or_null("GameManager")
	if gm != null and not gm.get("vfx_container"):
		gm.set("vfx_container", Node2D.new())
	# mock player（player.gd：_apply_character_sprite + 动画三防白盒）
	# 子节点必须先于 add_child 挂好：SkillController._ready 需 player 已就位，
	# player._ready 需 SkillController 已存在才能连接 skill_cast 信号
	_player = CharacterBody2D.new()
	_player.name = "MockPlayer"
	_player.set_script(load("res://scripts/player/player.gd"))
	_player.max_health = 1000.0
	_player.move_speed = 300.0
	var anim2d := AnimatedSprite2D.new()
	anim2d.name = "AnimatedSprite2D"
	_player.add_child(anim2d)
	var sc: Node = load("res://scripts/player/skill_controller.gd").new()
	sc.name = "SkillController"
	_player.add_child(sc)
	root.add_child(_player)


func _advance(sub: int) -> int:
	match sub:
		0:
			_part_enemies()
			return 1
		1:
			_part_boss_scale()
			return 2
		2:
			_part_characters()
			return 3
		3:
			_part_icons()
			return 4
		4:
			_part_regression()
			return 5
		_:
			_idx += 1
			return 0
	return sub + 1


# ========== 工具 ==========

func _ok(cond: bool, msg: String) -> void:
	_checked += 1
	if cond:
		print("  OK  %s" % msg)
	else:
		_failures += 1
		print("  XX  %s" % msg)


func _fail(msg: String) -> void:
	_checked += 1
	_failures += 1
	print("  XX  %s" % msg)


func _report() -> void:
	print("\n=== %d assertions, %d failures ===" % [_checked, _failures])


func _png_size(res_path: String) -> Vector2i:
	var abs_path: String = ProjectSettings.globalize_path(res_path)
	var img := Image.load_from_file(abs_path)
	if img == null:
		return Vector2i(-1, -1)
	return img.get_size()


func _png_frame_nonempty(res_path: String, frame_count: int, frame_size: Vector2i) -> bool:
	var abs_path: String = ProjectSettings.globalize_path(res_path)
	var img := Image.load_from_file(abs_path)
	if img == null:
		return false
	for i in frame_count:
		var empty: bool = true
		# 横排图：y 固定 [0, 帧高)，x 按帧号分段 [i*fw, (i+1)*fw)
		for y in range(frame_size.y):
			for x in range(i * frame_size.x, (i + 1) * frame_size.x):
				if img.get_pixel(x, y).a > 0.0:
					empty = false
					break
			if not empty:
				break
		if empty:
			return false
	return true


func _build_enemy(stats: Dictionary) -> Node:
	var scene: PackedScene = load(ENEMY_SCENE_PATH)
	var enemy: Node = scene.instantiate()
	if enemy.has_method("initialize"):
		enemy.initialize(stats)
	if enemy.has_method("set_target"):
		enemy.set_target(_player)
	root.add_child(enemy)
	return enemy


# ========== §1 敌人映射 ==========

func _part_enemies() -> void:
	var enemy_script: GDScript = load("res://scripts/enemy/enemy.gd")
	var sprite_map: Dictionary = enemy_script.SPRITE_MAP
	var fallback: Dictionary = enemy_script.FALLBACK_SPRITES
	_ok(sprite_map.size() == 23, "§1 数据: SPRITE_MAP 条目数 23（实得 %d）" % sprite_map.size())
	_ok(fallback.size() == 3, "§1 数据: FALLBACK_SPRITES 条目数 3")
	# 全路径 exists + 尺寸/帧数与 PNG 实切一致 + hit_radius 锚点
	var path_all_ok: bool = true
	var dim_ok: bool = true
	var hit_ok: bool = true
	var checked_dim: int = 0
	for id in sprite_map:
		var cfg: Dictionary = sprite_map[id]
		for key in ["move", "death"]:
			var p: String = str(cfg[key])
			if not ResourceLoader.exists(p):
				path_all_ok = false
				print("   缺失路径: %s (%s)" % [p, id])
		var size: Vector2i = cfg["size"]
		var mf: int = int(cfg["move_frames"])
		var df: int = int(cfg["death_frames"])
		for pair in [["move", mf], ["death", df]]:
			var key: String = str(pair[0])
			var frames: int = int(pair[1])
			var real: Vector2i = _png_size(str(cfg[key]))
			if real != Vector2i(size.x * frames, size.y):
				dim_ok = false
				print("   尺寸不符: %s %s 实切 %s != 期望 %s" % [id, key, real, Vector2i(size.x * frames, size.y)])
			checked_dim += 1
		# hit_radius 锚点：按 enemy_category 期望（用 FALLBACK 分类名近似）
		var expect: float = 0.0
		if cfg.has("hit_radius"):
			expect = float(cfg["hit_radius"])
			if expect != HIT_EXPECT.get("regular") and expect != HIT_EXPECT.get("elite") and expect != HIT_EXPECT.get("boss"):
				hit_ok = false
				print("   hit_radius 非锚点值: %s = %.1f" % [id, expect])
		else:
			hit_ok = false
			print("   缺 hit_radius 字段: %s" % id)
	_ok(path_all_ok, "§1 数据: SPRITE_MAP 全路径 exists（23 条 ×2）")
	_ok(dim_ok, "§1 数据: size/frames 与 PNG 实切一致（%d 项校验）" % checked_dim)
	# 分类 → hit_radius 抽样（chaser=slime 28 / butcher=elite 36 / invoker=boss 56）
	_ok(float(sprite_map["chaser"].get("hit_radius", -1.0)) == 28.0, "§1 锚点: chaser hit_radius == 28（slime 系）")
	_ok(float(sprite_map["slasher"].get("hit_radius", -1.0)) == 28.0, "§1 锚点: slasher hit_radius == 28（skeleton 系）")
	_ok(float(sprite_map["butcher"].get("hit_radius", -1.0)) == 36.0, "§1 锚点: butcher hit_radius == 36（精英）")
	_ok(float(sprite_map["invoker"].get("hit_radius", -1.0)) == 56.0, "§1 锚点: invoker hit_radius == 56（Boss）")
	_ok(float(sprite_map["predator"].get("hit_radius", -1.0)) == 56.0, "§1 锚点: predator hit_radius == 56（Boss）")
	_ok(hit_ok, "§1 数据: 全部条目 hit_radius ∈ {28, 36, 56} 锚点集")
	# FALLBACK 路径 exists + hit_radius
	var fb_ok: bool = true
	for cat in fallback:
		var cfg: Dictionary = fallback[cat]
		for key in ["move", "death"]:
			if not ResourceLoader.exists(str(cfg[key])):
				fb_ok = false
		var fb_expect: float = HIT_EXPECT.get(cat, -1.0)
		if absf(float(cfg.get("hit_radius", -1.0)) - fb_expect) > 0.001:
			fb_ok = false
			print("   FALLBACK %s hit_radius 不符: %s != %s" % [cat, cfg.get("hit_radius", "缺失"), fb_expect])
	_ok(fb_ok, "§1 数据: FALLBACK 3 条路径 exists + hit_radius 锚点（28/36/56）")
	# 未知 id → FALLBACK regular（行为兜底，hit_radius 28）
	var ghost: Node = _build_enemy({
		"id": "ghost_unknown", "category": "regular", "max_health": 30.0, "damage": 5.0,
		"move_speed": 120.0, "behavior": "chase", "armor": 0,
	})
	_ok(absf(float(ghost.get("hit_radius")) - 28.0) < 0.001, "§1 兜底: 未知 id → FALLBACK regular hit_radius 28（实得 %.1f）" % float(ghost.get("hit_radius")))
	ghost.queue_free()
	# sheet 尺寸硬校验（10 张敌人）
	var sheet_ok: bool = true
	for fname in SHEET_EXPECT:
		var real: Vector2i = _png_size("res://assets/sprites/enemies/" + fname)
		if real != SHEET_EXPECT[fname]:
			sheet_ok = false
			print("   sheet 尺寸不符: %s %s != %s" % [fname, real, SHEET_EXPECT[fname]])
	_ok(sheet_ok, "§1 资产: 敌人 10 sheet 尺寸全部符合预期")


# ========== §2 Boss scale 复位 ==========

func _part_boss_scale() -> void:
	var inv_stats: Dictionary = _loader.call("get_scaled_enemy", "invoker", 10)
	var boss: Node = _build_enemy(inv_stats)
	_ok(boss.get("is_boss") == true, "§2 状态机: invoker is_boss == true")
	_ok(boss.get("scale") == Vector2(1.0, 1.0), "§2 状态机: Boss scale 复位 ×1（D17·128px 真精灵，实得 %s）" % str(boss.get("scale")))
	_ok(float(boss.get("hit_radius")) == 56.0, "§2 判定: Boss hit_radius == 56（实得 %.1f）" % float(boss.get("hit_radius")))
	_ok(Vector2i(boss.get("frame_size")) == Vector2i(128, 128), "§2 精灵: Boss frame_size == 128×128（实得 %s）" % str(boss.get("frame_size")))
	boss.queue_free()


# ========== §3 角色 ==========

func _part_characters() -> void:
	# walk/idle 存在 + 尺寸 + 帧非空
	## D28：elin 已实装拼豆图纸真实动画（walk 640×64 = 10 帧 / idle 192×64 = 3 帧），
	## 其余角色仍为收口占位（walk 192×32 = 6 帧 / idle 128×32 = 4 帧）
	## D29：elin 换装 JPG 全动画实装（walk 640×64 = 10 帧 / idle 320×64 = 5 帧）
	var char_ok: bool = true
	for hero in HEROES:
		var w: Vector2i = _png_size("res://assets/sprites/characters/%s_walk.png" % hero)
		var idle: Vector2i = _png_size("res://assets/sprites/characters/%s_idle.png" % hero)
		var walk_frames: int = 6
		if hero == "elin":
			if w != Vector2i(640, 64):
				char_ok = false
				print("   %s_walk 尺寸 %s != 640×64" % [hero, w])
			if idle != Vector2i(320, 64):
				char_ok = false
				print("   %s_idle 尺寸 %s != 320×64" % [hero, idle])
			walk_frames = 10
		else:
			if w != Vector2i(192, 32):
				char_ok = false
				print("   %s_walk 尺寸 %s != 192×32" % [hero, w])
			if idle != Vector2i(128, 32):
				char_ok = false
				print("   %s_idle 尺寸 %s != 128×32" % [hero, idle])
		if not _png_frame_nonempty("res://assets/sprites/characters/%s_walk.png" % hero, walk_frames, Vector2i(64, 64) if hero == "elin" else Vector2i(32, 32)):
			char_ok = false
			print("   %s_walk 存在空帧" % hero)
	_ok(char_ok, "§3 资产: 4 角色 walk（elin 640×64·10 帧 / 其余 192×32·6 帧 非空）+ idle 全存在")
	# 白盒 _apply_character_sprite("siia") → walk_texture 非 fighter 兜底
	_player.call("_apply_character_sprite", "siia")
	var wt: Texture2D = _player.get("walk_texture")
	var is_siia: bool = wt != null and "siia_walk" in wt.resource_path
	_ok(is_siia, "§3 白盒: _apply_character_sprite(\"siia\") → walk_texture 为 siia_walk（实得 %s）" % (str(wt.resource_path) if wt else "null"))
	_ok(_player.get("_sprite_prefix") == "siia", "§3 白盒: _sprite_prefix == siia")
	# attack/skill 动画接线（缺帧 → 降级登记不判失败，但本日全量实绘应存在）
	var anim: AnimatedSprite2D = _player.get_node_or_null("AnimatedSprite2D")
	if anim == null:
		_fail("§3 白盒: MockPlayer 无 AnimatedSprite2D（动画接线无法验证）")
		return
	var sf: SpriteFrames = anim.sprite_frames
	var skill_missing: bool = false
	var attack_missing: bool = false
	for hero in HEROES:
		if not ResourceLoader.exists("res://assets/sprites/characters/%s_attack.png" % hero):
			attack_missing = true
			push_warning("[D21-22] %s_attack.png 缺失（P1 登记，不判失败）" % hero)
		if not ResourceLoader.exists("res://assets/sprites/characters/%s_skill.png" % hero):
			skill_missing = true
			push_warning("[D21-22] %s_skill.png 缺失（P1 登记，不判失败）" % hero)
	_ok(not attack_missing, "§3 资产: 4 角色 attack strip 128×32 全存在（缺失走 P1 登记不判失败）")
	_ok(not skill_missing, "§3 资产: 4 角色 skill strip 128×32 全存在（缺失走 P1 登记不判失败）")
	_ok(sf.has_animation("attack") and sf.has_animation("skill"), "§3 接线: siia 已注册 attack/skill 动画")
	# skill_cast 信号 → "skill"（_ready 已连接 SkillController；缺节点则失败）
	var sc: Node = _player.get_node_or_null("SkillController")
	if sc == null:
		_fail("§3 接线: MockPlayer 无 SkillController（skill_cast 信号路径无法验证）")
		return
	var sig_ok: bool = false
	for c in sc.skill_cast.get_connections():
		if "play_skill_anim" in str(c.get("callable", "")):
			sig_ok = true
	_ok(sig_ok, "§3 接线: skill_cast 信号已连接 _play_skill_anim（player._ready 接线）")
	sc.skill_cast.emit("se_skill_fireball")
	_ok(anim.animation == "skill", "§3 接线: skill_cast 信号 → animation == \"skill\"（实得 %s）" % anim.animation)
	_player.call("_on_anim_finished")
	_ok(anim.animation == "idle" and int(_player.get("_state")) == 0, "§3 接线: 播完 → 回 idle 且状态复位 IDLE（F3-T6 同步）")
	_player.call("_play_attack_anim")
	_ok(anim.animation == "attack", "§3 接线: _play_attack_anim → animation == \"attack\"（实得 %s）" % anim.animation)
	_player.call("_on_anim_finished")
	_ok(anim.animation == "idle", "§3 接线: attack 播完 → 回 idle")
	# 缺帧前缀 → 无 attack 动画走 idle 降级（D19① 守卫）
	_player.set("_sprite_prefix", "no_such_hero")
	_player.call("_setup_animation")
	_ok(not anim.sprite_frames.has_animation("attack") and not anim.sprite_frames.has_animation("skill"),
		"§3 降级: 缺帧前缀 → 无 attack/skill 动画（D19① 守卫）")
	_player.set("_sprite_prefix", "siia")
	_player.call("_setup_animation")


# ========== §4 图标/概念图 ==========

func _part_icons() -> void:
	var f_ok: bool = true
	for f in FACTIONS:
		var p: String = "res://assets/sprites/factions/%s.png" % f
		var sz: Vector2i = _png_size(p)
		if sz != Vector2i(32, 32):
			f_ok = false
			print("   阵营图标尺寸: %s %s != 32×32" % [f, sz])
	_ok(f_ok, "§4 资产: 阵营图标 5 张 32×32 全存在")
	var b_ok: bool = true
	for b in BACKGROUNDS:
		var p: String = "res://assets/sprites/backgrounds/%s.png" % b
		var sz: Vector2i = _png_size(p)
		if sz != Vector2i(320, 180):
			b_ok = false
			print("   背景尺寸: %s %s != 320×180" % [b, sz])
	_ok(b_ok, "§4 资产: 背景概念图 4 张 320×180 全存在")
	var p_ok: bool = true
	for h in PORTRAITS:
		var p: String = "res://assets/sprites/characters/%s_portrait.png" % h
		var sz: Vector2i = _png_size(p)
		if sz != Vector2i(64, 64):
			p_ok = false
			print("   头像尺寸: %s %s != 64×64" % [h, sz])
	_ok(p_ok, "§4 资产: 遗留头像 3 张 64×64 全存在")
	# 透明键（(0,0) 全透明）：抽查敌人/角色/阵营/背景各 1
	var key_ok: bool = true
	var key_targets: Array = [
		"res://assets/sprites/enemies/invoker_move.png",
		"res://assets/sprites/characters/siia_walk.png",
		"res://assets/sprites/factions/mech_empire.png",
		"res://assets/sprites/backgrounds/lava_mine.png",
	]
	for p in key_targets:
		var img := Image.load_from_file(ProjectSettings.globalize_path(p))
		if img == null or img.get_pixel(0, 0).a > 0.0:
			key_ok = false
			print("   透明键违规: %s" % p)
	_ok(key_ok, "§4 资产: 抽查 (0,0) 透明键合规（敌人/角色/阵营/背景）")


# ========== §5 回归锚点 ==========

func _part_regression() -> void:
	# .import 齐全：全部新/覆写资产 + 新目录
	var imp_ok: bool = true
	var imp_list: Array = []
	for fname in SHEET_EXPECT:
		imp_list.append("res://assets/sprites/enemies/" + fname)
	for hero in HEROES:
		for k in ["walk", "attack", "skill"]:
			imp_list.append("res://assets/sprites/characters/%s_%s.png" % [hero, k])
	for h in PORTRAITS:
		imp_list.append("res://assets/sprites/characters/%s_portrait.png" % h)
	for f in FACTIONS:
		imp_list.append("res://assets/sprites/factions/%s.png" % f)
	for b in BACKGROUNDS:
		imp_list.append("res://assets/sprites/backgrounds/%s.png" % b)
	for p in imp_list:
		if not FileAccess.file_exists(ProjectSettings.globalize_path(p) + ".import"):
			imp_ok = false
			print("   缺 .import: %s" % p)
	_ok(imp_ok, "§5 资产: 新/覆写 %d 张 PNG .import 齐全（godot --headless --import 已跑）" % imp_list.size())
	# day2 角色数据抽样（sprite 前缀存在；可玩角色 id = se_* 前缀）
	var elin: Dictionary = _loader.call("get_character", "se_irene")
	_ok(not elin.is_empty() and str(elin.get("sprite", "")) == "elin", "§5 回归: characters.json se_irene sprite 前缀 intact")
	# day17 精英 ability 数据抽样（原始数据 API，与 day17_elite_check 同口径）
	var butcher: Dictionary = _loader.call("get_enemy", "butcher")
	var ability: Dictionary = butcher.get("ability", {})
	_ok(not ability.is_empty() and str(ability.get("type", "")) == "aoe", "§5 回归: 精英 butcher ability(aoe) 数据 intact")
	# 普通敌人接触判定仍按 hit_radius（charger 28：距离 24 ≤ 28 → 命中掉血）
	var charger: Node = _build_enemy({
		"id": "charger", "category": "regular", "max_health": 30.0, "damage": 10.0,
		"move_speed": 120.0, "behavior": "chase", "armor": 0,
	})
	charger.global_position = Vector2.ZERO
	_player.global_position = Vector2(24.0, 0.0)
	_player.health = 100.0
	_player._invulnerable_timer = 0.0
	charger.call("_try_contact_damage")
	_ok(absf(float(_player.health) - 90.0) < 0.01, "§5 回归: charger 距离 24 ≤ hit_radius 28 → 命中掉 10（实得 %.1f）" % float(_player.health))
	charger.queue_free()
	# 波次数据 intact（DataLoader wave 键修复后的真实波次锚点）
	var wave: Dictionary = _loader.call("get_wave", 2)
	_ok(not wave.is_empty(), "§5 回归: waves.json wave2 数据 intact（fa077e0 修复锚点）")
