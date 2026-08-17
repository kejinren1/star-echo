## Day 5 出口校验：武器 6 槽挂载（D5-T1~T4 收口）
##
## 用法（无头，不需要编辑器）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day5_weapon_check.gd
##
## 校验内容（对应 docs/TASKS.md D5-EXIT 七项断言）：
##   1. 连装 6 把 → is_full() == true；第 7 把被拒（size() == 6）
##   2. se_star_flame 连续 upgrade() Lv1→Lv8 全 true，再升 false；Lv2 后 base_damage == levels[1].damage（查表生效）
##   3. pistol（无 levels 表）升级走通用成长（base_damage == 5 * 1.25）
##   4. 升级面板选项池含武器升级项；注入「升级『星刃』」→ 星刃 level == 2；真实按钮点击恢复运行
##   5. 装备星刃 → Player 下 MeleeSweep 存在且 Lv1 arc_angle >= 100（PS 2026-08-17 星刃 orbit→扇形挥砍重构）
##   6. 扇形挥砍命中前方敌人 → 敌人掉血 7 × damage_multiplier
##   7. 卸下星刃 → Player 下无 MeleeSweep 节点
##
## 无头环境特殊约定（沿用 day2/day3/day4）：
##   · --script 模式下 autoload 标识符不可直接引用，一律经 root 取 GameManager/DataLoader
##   · 面板挂载：current_scene 为 null 时 GameManager._add_to_ui_layer 挂 root，故按 root 节点查找
##   · 扇形挥砍驱动用「直接调 sweep._do_slash()」（冷却 0 守卫放行，真实逻辑与引擎回调一致）
##
## 退出码 0 = 全部通过；非 0 = 失败项数。
extends SceneTree

const MAIN_SCENE: String = "res://scenes/Main.tscn"
const ENEMY_SCENE: String = "res://scenes/Enemy.tscn"
const LEVELUP_PANEL_SCENE: String = "res://scenes/LevelUpPanel.tscn"
const SELECTION_META: StringName = &"se_selected_character"
const EPSILON: float = 0.01

const CASES: Array = [
	{"hero": "well_rounded", "phase": "slots"},
	{"hero": "se_ren", "phase": "orbit"},
]

var _idx: int = 0
var _sub: int = 0
var _instance: Node = null
var _player: Node = null
var _controller: Node = null
var _manager: Node = null
var _panel: Node = null
var _checked: int = 0
var _failures: int = 0

func _initialize() -> void:
	print("=== Day 5 weapon / 6-slot check ===")

func _process(_delta: float) -> bool:
	if _idx >= CASES.size():
		_report()
		quit(_failures)
		return true
	_sub = _advance(_sub)
	return false

# ========== 用例推进 ==========

func _advance(sub: int) -> int:
	var phase: String = str(CASES[_idx]["phase"])
	match phase:
		"slots":
			return _advance_slots(sub)
		"orbit":
			return _advance_orbit(sub)
	return sub + 1

func _spawn() -> void:
	var hero: String = str(CASES[_idx]["hero"])
	root.set_meta(SELECTION_META, hero)
	_instance = (load(MAIN_SCENE) as PackedScene).instantiate()
	root.add_child(_instance)
	_manager = root.get_node_or_null("GameManager")
	_player = _instance.get_node_or_null("World/Player")
	_controller = _player.get_node_or_null("WeaponController") if _player else null

func _teardown() -> void:
	if is_instance_valid(_instance):
		_instance.free()
	_instance = null
	_player = null
	_controller = null
	_panel = null
	_reset_manager_refs()

## 同进程反复实例化 Main 的测试夹具职责：清空 GameManager 持有的引用与面板指针
func _reset_manager_refs() -> void:
	if _manager == null:
		_manager = root.get_node_or_null("GameManager")
	if _manager == null:
		return
	for field: String in ["player", "wave_manager", "enemy_spawner", "economy", "inventory", "vfx_container", "_level_up_panel", "_game_over_panel"]:
		_manager.set(field, null)

# ========== Case A：well_rounded（断言 1-4） ==========

func _advance_slots(sub: int) -> int:
	match sub:
		0:
			_spawn()
			return 1
		1:
			return 2  # 空转一帧等 Main ready
		2:
			_check_slot_limit()    # 断言 1
			return 3
		3:
			_check_level_table()   # 断言 2
			_check_generic_growth() # 断言 3
			return 4
		4:
			_check_panel_pool()    # 断言 4a + 4b（白盒）
			return 5
		5:
			_check_panel_real()    # 断言 4c（真实升级交互）
			return 6
		6:
			_finish_case()
			return 0
	return sub + 1

## 断言 1：连装 6 把 → is_full；第 7 把被拒
func _check_slot_limit() -> void:
	if _controller == null:
		_fail("slots / WeaponController 缺失")
		return
	_controller.get("equipped_weapons").clear()
	# 手动构造 6 把占位武器（不同名，避免查重误判）
	for i in 6:
		var w := Weapon.new()
		w.weapon_name = "测试武器%d" % i
		if not bool(_controller.call("equip_weapon", w)):
			_fail("slots / 第 %d 把应装成功" % (i + 1))
			return
	if bool(_controller.call("is_full")) and int(_controller.call("get_slot_count")) == 6:
		_checked += 1
		print("  PASS  slots / 6 把装满 is_full == true")
	else:
		_fail("slots / 6 把后 is_full 应为 true（count=%d）" % int(_controller.call("get_slot_count")))
	# 第 7 把 → 拒绝
	var extra := Weapon.new()
	extra.weapon_name = "第七把"
	if not bool(_controller.call("equip_weapon", extra)) \
			and int(_controller.call("get_slot_count")) == 6:
		_checked += 1
		print("  PASS  slots / 第 7 把被拒，size 保持 6")
	else:
		_fail("slots / 第 7 把应被拒且 size == 6")

## 断言 2：se_star_flame 查表升级（8 级全 true，再升 false；Lv2 后 base_damage == levels[1].damage）
func _check_level_table() -> void:
	var w: Resource = _controller.call("build_weapon_from_data", "se_star_flame")
	if w == null or w.level_table.is_empty():
		_fail("slots / se_star_flame 未读入 level_table")
		return
	var expected_lv2_dmg: float = float(w.level_table[1].get("damage", 0.0))
	# Lv1→Lv8 需 7 次成功升级
	var ok_count: int = 0
	for i in 7:
		if bool(w.call("upgrade")):
			ok_count += 1
	if ok_count == 7 and int(w.level) == 8:
		_checked += 1
		print("  PASS  slots / se_star_flame 连升 7 次到 Lv8（全部 true）")
	else:
		_fail("slots / 连升应 7 次全 true 且到 Lv8（实得 %d 次, level=%d）" % [ok_count, int(w.level)])
	# 第 8 次 → false（已达 max_level 8）
	if not bool(w.call("upgrade")):
		_checked += 1
		print("  PASS  slots / Lv8 后再升级被拒")
	else:
		_fail("slots / Lv8 后 upgrade 应返回 false")
	# Lv2 后 base_damage == levels[1].damage（查表绝对覆盖，非 6*1.25）
	var probe: Resource = _controller.call("build_weapon_from_data", "se_star_flame")
	probe.call("upgrade")
	var actual_dmg: float = float(probe.get("base_damage"))
	if absf(actual_dmg - expected_lv2_dmg) <= EPSILON:
		_checked += 1
		print("  PASS  slots / Lv2 base_damage == levels[1].damage = %.1f" % actual_dmg)
	else:
		_fail("slots / Lv2 查表失败：期望 %.1f，实得 %.1f" % [expected_lv2_dmg, actual_dmg])

## 断言 3：合成裸武器（无 level_table）→ 通用成长兜底（base_damage×1.25 / fire_rate×1.1）
## Day 7 改动：旧版用 pistol 测兜底，Day 7 给 pistol 补了 8 条 levels → 改用合成裸 Weapon.new()
## 验证升级链路对无 levels 表数据仍走通用成长（不崩）
func _check_generic_growth() -> void:
	var w := Weapon.new()
	w.base_damage = 5.0
	w.fire_rate = 2.0
	if not w.level_table.is_empty():
		_fail("slots / 合成裸武器不应有 level_table")
		return
	w.call("upgrade")
	if absf(float(w.get("base_damage")) - 5.0 * 1.25) > EPSILON:
		_fail("slots / 通用成长 base_damage 期 6.25，实得 %.2f" % float(w.get("base_damage")))
		return
	_checked += 1
	print("  PASS  slots / 裸武器 base_damage 通用成长 5 → 6.25（×1.25 兜底）")
	if absf(float(w.get("fire_rate")) - 2.0 * 1.1) > EPSILON:
		_fail("slots / 通用成长 fire_rate 期 2.2，实得 %.2f" % float(w.get("fire_rate")))
		return
	_checked += 1
	print("  PASS  slots / 裸武器 fire_rate 通用成长 2.0 → 2.2（×1.1 兜底）")

## 断言 4a + 4b：面板选项池零武器升级项（F31-2）+ 注入式应用升级（分支保留）
func _check_panel_pool() -> void:
	var panel: Node = (load(LEVELUP_PANEL_SCENE) as PackedScene).instantiate()
	root.add_child(panel)
	panel.set("player", _player)
	# 4a：白盒 roll 全量池 → 必须【零】weapon_upgrade（F31-2 用户拍板：武器升级移出升级面板）
	# 顺带验证属性池仍可 roll（结果非空）；4b 注入分支保留（铁砧/兼容路径）
	var rolled: Array = panel.call("_roll_options", 20)
	var has_weapon_opt: bool = false
	for opt in rolled:
		if str(opt.get("type", "")) == "weapon_upgrade":
			has_weapon_opt = true
			break
	if not has_weapon_opt and rolled.size() > 0:
		_checked += 1
		print("  PASS  slots / 选项池零「升级『X』」武器项（F31-2）+ 属性池可 roll（%d 项）" % rolled.size())
	else:
		_fail("slots / 选项池应零 weapon_upgrade 且非空，实得 has=%s size=%d" % [has_weapon_opt, rolled.size()])
	# 4b：注入式应用「升级『星刃』」→ level 1→2
	var blade: Resource = _controller.call("build_weapon_from_data", "se_star_blade")
	panel.call("_apply_option", {"label": "升级「星刃」", "type": "weapon_upgrade", "weapon": blade})
	if int(blade.get("level")) == 2:
		_checked += 1
		print("  PASS  slots / 注入升级武器 → 星刃 level == 2")
	else:
		_fail("slots / 武器升级应到 Lv2，实得 %d" % int(blade.get("level")))
	panel.queue_free()

## 断言 4c：真实升级交互（gain_exp → 面板 → 点击按钮 → 恢复运行）
func _check_panel_real() -> void:
	# 先清空武器再装 1 把未满级星刃，保证真实按钮点击路径无异常
	_controller.get("equipped_weapons").clear()
	var blade: Resource = _controller.call("build_weapon_from_data", "se_star_blade")
	_controller.call("equip_weapon", blade)
	# well_rounded level=1 → +30 经验升级（1→2 需求 30）
	_player.call("gain_exp", 30.0)
	_panel = root.get_node_or_null("LevelUpPanel")
	if _panel == null:
		_fail("slots / 升级后面板未出现")
		return
	if not bool(paused):
		_fail("slots / 升级后应暂停")
		return
	_checked += 1
	print("  PASS  slots / 升级 → 面板出现且 paused == true")
	# 点击第 0 个按钮 → 恢复
	_panel.call("_on_option_pressed", 0)
	if not bool(paused):
		_checked += 1
		print("  PASS  slots / 点击选项后游戏恢复（paused = false）")
	else:
		_fail("slots / 点击后应恢复运行")

# ========== Case B：se_ren（断言 5-7 · 扇形挥砍，PS 2026-08-17 星刃 orbit→扇形重构） ==========

func _advance_orbit(sub: int) -> int:
	match sub:
		0:
			_spawn()
			return 1
		1:
			return 2  # 空转一帧等 Main ready
		2:
			_check_sweep_exists()    # 断言 5a
			return 3
		3:
			_check_sweep_ready()     # 断言 5b（arc_angle 驱动就绪）
			return 4
		4:
			_check_sweep_hit()       # 断言 6
			return 5
		5:
			return 6  # 空转一帧
		6:
			_do_sweep_cleanup()      # 卸下星刃（queue_free 延迟生效）
			return 7
		7:
			return 8  # 空转一帧让 queue_free 生效
		8:
			_check_sweep_cleanup()   # 断言 7
			_finish_case()
			return 0
	return sub + 1

func _sweep_node() -> Node2D:
	return _player.get_node_or_null("MeleeSweep") as Node2D

## 断言 5a：装备星刃 → MeleeSweep 存在且 weapon.arc_angle >= 100（Lv1 扇形角）
func _check_sweep_exists() -> void:
	var sweep: Node2D = _sweep_node()
	if sweep == null:
		_fail("sweep / Player 下无 MeleeSweep（起始星刃应自动挂载）")
		return
	_checked += 1
	print("  PASS  sweep / MeleeSweep 已自动挂载（挂 Player 子节点）")
	var w: Resource = sweep.get("weapon")
	if w != null and float(w.arc_angle) >= 100.0:
		_checked += 1
		print("  PASS  sweep / Lv1 扇形角 == %.0f°" % float(w.arc_angle))
	else:
		_fail("sweep / Lv1 arc_angle 应 >= 100，实得 %s" % str(w.arc_angle if w else "null"))

## 断言 5b：MeleeSweep 已 setup 且武器 arc_angle > 0（冷却/刀光就绪可挥砍）
func _check_sweep_ready() -> void:
	var sweep: Node2D = _sweep_node()
	if sweep == null:
		_fail("sweep / MeleeSweep 缺失")
		return
	var w: Resource = sweep.get("weapon")
	if w != null and float(w.arc_angle) > 0.0 and float(sweep.get("_cooldown")) <= 0.0:
		_checked += 1
		print("  PASS  sweep / setup 就绪（arc_angle=%.0f° 冷却已清）" % float(w.arc_angle))
	else:
		_fail("sweep / 武器未绑定或冷却未就绪")

## 断言 6：扇形挥砍命中前方敌人 → 敌人掉血 7 × damage_multiplier
func _check_sweep_hit() -> void:
	var sweep: Node2D = _sweep_node()
	if sweep == null:
		_fail("sweep / MeleeSweep 缺失")
		return
	var spawner: Node = _manager.get("enemy_spawner") if _manager else null
	var container: Node = spawner.get("enemies_container") if spawner else null
	if container == null:
		_fail("sweep / enemies_container 缺失")
		return
	# 摆敌人在挥砍瞄准方向上 40px（射程 110 内；_do_slash 用 _get_aim_direction
	# 实时取方向，headless 下鼠标贴原点 → 敌人必须摆到该方向才在扇形内）
	var dir: Vector2 = sweep.call("_get_aim_direction")
	var enemy: Node = (load(ENEMY_SCENE) as PackedScene).instantiate()
	container.add_child(enemy)
	enemy.global_position = _player.global_position + dir * 40.0
	# 临时禁暴击（se_ren crit 23% 波动会破坏精确断言）；期望 = 7 × 倍率 × 近战加成
	_player.set("crit_chance", 0.0)
	var hp_before: float = float(enemy.get("health"))
	sweep.call("_do_slash")   # 直接挥砍（冷却 0 守卫放行，方向默认 RIGHT）
	var hp_after: float = float(enemy.get("health"))
	var dmg_mult: float = float(_player.get("damage_multiplier"))
	var melee_pct: float = float(_player.get("bonus_stats").get("melee_damage", 0.0))
	var expected: float = 7.0 * dmg_mult * (1.0 + melee_pct / 100.0)
	if absf(hp_before - hp_after - expected) <= EPSILON:
		_checked += 1
		print("  PASS  sweep / 扇形挥砍伤害 = %.1f（%.1f → %.1f）" % [expected, hp_before, hp_after])
	else:
		_fail("sweep / 挥砍伤害应 %.1f（%.1f → %.1f）" % [expected, hp_before, hp_after])

## 卸下星刃（触发 _sync_melee_sweep → sweep_node.queue_free）
func _do_sweep_cleanup() -> void:
	var star_blade: Resource = null
	var weapons: Array = _controller.get("equipped_weapons")
	for w in weapons:
		# meta key 为 StringName（weapon_controller.gd META_SOURCE_ID）
		if w.has_meta(&"source_id") and str(w.get_meta(&"source_id")) == "se_star_blade":
			star_blade = w
			break
	if star_blade != null:
		_controller.call("unequip_weapon", star_blade)

## 断言 7：卸下星刃后 Player 下无 MeleeSweep
func _check_sweep_cleanup() -> void:
	if _sweep_node() == null:
		_checked += 1
		print("  PASS  sweep / 卸下星刃后 MeleeSweep 被清理")
	else:
		_fail("sweep / 卸下后 Player 下仍存在 MeleeSweep")

# ========== 收尾 ==========

func _finish_case() -> void:
	_teardown()
	_idx += 1
	_sub = 0

# ========== 断言 ==========

func _fail(what: String) -> void:
	_checked += 1
	_failures += 1
	print("  FAIL  %s" % what)

func _report() -> void:
	print("--- %d 项断言，%d 项失败 ---" % [_checked, _failures])
	if _failures == 0:
		print("DAY5 WEAPON CHECK CLEAN")
	else:
		print("DAY5 WEAPON CHECK BROKEN")
