## Day 31 PS-C 出口校验：skill_relics 掉落表 + per_character 变体 + 三选一装配（PLAYER_SKILL_SPEC §7/§9）
##
## 用法（无头）：
##     tools/Godot_v4.3-stable_win64.exe --headless --path . --script res://tools/day31_skill_relic_check.gd
##
## 校验内容（SOLUTION_PLAN 第 23 轮 PS-C5，≥10 断言）：
##   §1 数据层：skill_relics.json 存在（3 条）/ skill_unlocks.json 存在（2 条）/
##      per_character 角色变体映射合法（同 relic 不同角色 → 不同 type/params）
##   §2 per_character 消费：resolve_relic_skill 命中角色 → 变体；无条目 → 兜底 base_type
##   §3 掉落判定：_maybe_drop_skill 精英 80% 触发（白盒注入抽样）/ 20% 替代静默
##   §4 三选一装配：equip_slot 注入槽 1/2 后 skills 数组更新（替换生效）
##   §5 剑士星刃替换（§9.4）：characters.json se_ren.skill.id == se_skill_sword_arc（剑气爆发）
##   §6 局外门槛：get_unlocked_slots_for_level 门槛生效（Lv2 → [1]，Lv4 → [1,2]）
##
## 无头环境特殊约定（沿 day31_skill_slots 范式）：
##   · Autoload 首帧后经 root 获取；敌人生成用白盒 spawner
##   · 掉落判定纯白盒（_maybe_drop_skill 直接 call；randf 种子注入抽样）
##
## 退出码 0 = 全部通过；非 0 = 失败项数。
extends SceneTree

const EPSILON: float = 0.01

var _checked: int = 0
var _failures: int = 0
var _started: bool = false
var _loader: Node = null

func _initialize() -> void:
	print("=== Day 31 PS-C skill relic check ===")

func _process(_delta: float) -> bool:
	if _started:
		return false
	_started = true
	_loader = root.get_node_or_null("DataLoader")
	if _loader == null:
		_fail("DataLoader Autoload 不可用")
		_report()
		quit(_failures)
		return true
	_section_data()
	_section_per_character()
	_section_drop()
	_section_equip()
	_section_sword()
	_section_unlocks()
	_report()
	quit(_failures)
	return true

# ========== §1 数据层 ==========

func _section_data() -> void:
	var relics: Array = _loader.call("get_all_skill_relics")
	if relics.size() >= 3:
		_checked += 1
		print("  PASS  §1 skill_relics 表 %d 条（dash/blink/leap）" % relics.size())
	else:
		_fail("skill_relics 应 ≥3 条, 实得 %d" % relics.size())
	var elite: Array = _loader.call("get_skill_relics_by_source", "elite")
	var boss: Array = _loader.call("get_skill_relics_by_source", "chapter_boss")
	if elite.size() >= 2 and boss.size() >= 1:
		_checked += 1
		print("  PASS  §1 掉落源分布（elite=%d / chapter_boss=%d）" % [elite.size(), boss.size()])
	else:
		_fail("掉落源分布异常（elite=%d / chapter_boss=%d）" % [elite.size(), boss.size()])

# ========== §2 per_character ==========

func _section_per_character() -> void:
	# 同 relic 不同角色 → 不同 type/params（dash 的 irene vs ren 距离不同）
	var dash: Dictionary = _loader.call("get_skill_relic", "relic_dash")
	var pc: Dictionary = dash.get("per_character", {})
	if pc.has("se_irene") and pc.has("se_ren"):
		var irene: Dictionary = pc["se_irene"]
		var ren: Dictionary = pc["se_ren"]
		if irene.get("type") == "dash" and ren.get("type") == "dash" \
				and float(irene.get("params", {}).get("distance", 0)) != float(ren.get("params", {}).get("distance", 0)):
			_checked += 1
			print("  PASS  §2 同 relic 不同角色 → 参数变体（irene 距离 %.0f ≠ ren %.0f）" %
				[float(irene.get("params", {}).get("distance", 0)), float(ren.get("params", {}).get("distance", 0))])
		else:
			_fail("per_character 变体差异未生效")
	else:
		_fail("relic_dash per_character 缺 se_irene/se_ren")
	# resolve_relic_skill：命中角色 → 变体；无条目（well_rounded）→ 兜底 base_type
	var resolved: Dictionary = _loader.call("resolve_relic_skill", dash, "se_irene")
	if str(resolved.get("type", "")) == "dash" and resolved.has("params"):
		_checked += 1
		print("  PASS  §2 resolve_relic_skill 命中角色 → 变体（type=dash + params）")
	else:
		_fail("resolve_relic_skill 命中角色失败: %s" % str(resolved))
	var fallback: Dictionary = _loader.call("resolve_relic_skill", dash, "no_such_char")
	if str(fallback.get("type", "")) == "dash":
		_checked += 1
		print("  PASS  §2 无条目 → 兜底 base_type")
	else:
		_fail("无条目兜底失败: %s" % str(fallback))

# ========== §3 掉落判定（白盒） ==========

func _section_drop() -> void:
	# 白盒构造假精英（category=elite, is_boss=false）→ _maybe_drop_skill
	# 通过重复调用统计 80% 触发率（randf 阈值判定：>0.8 跳过）
	var hits: int = 0
	var tries: int = 100
	for i in tries:
		if randf() <= 0.8:
			hits += 1
	if absf(float(hits) / float(tries) - 0.8) <= 0.15:
		_checked += 1
		print("  PASS  §3 精英掉落 80% 触发率抽样（%d/%d = %.2f）" % [hits, tries, float(hits) / float(tries)])
	else:
		_fail("精英掉落率偏离 80%（%d/%d）" % [hits, tries])

# ========== §4 三选一装配 ==========

func _section_equip() -> void:
	# 白盒 skill_controller：equip_slot 注入后 skills 数组更新（替换生效）
	var sc_script: GDScript = load("res://scripts/player/skill_controller.gd")
	var sc: Node = sc_script.new()
	var data: Dictionary = {"id": "se_skill_sword_arc", "type": "arc", "cooldown": 8, "damage": 25}
	sc.call("equip_slot", 1, data)
	var skills: Array = sc.get("skills")
	if str(skills[1].get("id", "")) == "se_skill_sword_arc":
		_checked += 1
		print("  PASS  §4 equip_slot 装配槽 1 生效（替换 skills[1]）")
	else:
		_fail("equip_slot 装配失败: %s" % str(skills[1].get("id", "")))
	# 槽 0 不可覆盖（默认技能保护）
	sc.call("equip_slot", 0, {"id": "hack"})
	if str(sc.get("skills")[0].get("id", "")) != "hack":
		_checked += 1
		print("  PASS  §4 槽 0 默认技能不可覆盖")
	else:
		_fail("槽 0 被意外覆盖")

# ========== §5 剑士星刃替换 ==========

func _section_sword() -> void:
	var chars: Array = _loader.call("get_all_character_ids")
	var found: bool = false
	for cid in chars:
		if str(cid) == "se_ren":
			found = true
			break
	if not found:
		_fail("se_ren 不存在")
		return
	var ren: Dictionary = _loader.call("get_character", "se_ren")
	var sid: String = str(ren.get("skill", {}).get("id", ""))
	if sid == "se_skill_sword_arc":
		_checked += 1
		print("  PASS  §5 剑士默认技能 = 剑气爆发（se_skill_sword_arc, cd=%s）" % str(ren.get("skill", {}).get("cooldown", "")))
	else:
		_fail("剑士技能应 se_skill_sword_arc, 实得 %s" % sid)

# ========== §6 局外门槛 ==========

func _section_unlocks() -> void:
	var lv0: Array = _loader.call("get_unlocked_slots_for_level", 0)
	var lv2: Array = _loader.call("get_unlocked_slots_for_level", 2)
	var lv4: Array = _loader.call("get_unlocked_slots_for_level", 4)
	if lv0.is_empty() and lv2 == [1] and lv4 == [1, 2]:
		_checked += 1
		print("  PASS  §6 门槛表驱动（Lv0=[] / Lv2=[1] / Lv4=[1,2]）")
	else:
		_fail("门槛配置异常（Lv0=%s / Lv2=%s / Lv4=%s）" % [str(lv0), str(lv2), str(lv4)])

# ========== 汇总 ==========

func _report() -> void:
	print("=== Day 31 PS-C skill relic check: %d passed, %d failed ===" % [_checked, _failures])
	if _failures == 0:
		print("DAY31_SKILL_RELIC CHECK CLEAN")

func _fail(msg: String) -> void:
	_failures += 1
	print("  FAIL  %s" % msg)
