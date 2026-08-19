extends SceneTree
## RELIC-A 属性命名去土豆兄弟化（方案师第 31 轮 · 拆解第 61 轮 · 2026-08-19 #3 执行）
## O-1 拍板：elemental_damage 元素伤害→魔法伤害 / engineering 工程学→机械学（id 零改动）
## §1 stats.json 两属性改名（id 零改动 + name 新值 + 全量文本零残留）
## §2 desc_builder STAT_CN 两键同步（统一「机械学」3 字，消除既有 2/3 字不一致）
## §3 attribute_controller CONSUMED_BONUS_KEYS id 锚点（属性 id 零改动）
## §4 characters 艾琳/诺亚 growth.description 文案同步
## §5 elements 燃烧/中毒 effect 属性名引用同步 + scaling_attr id 零改动
## 环境：纯白盒读 JSON + preload 常量，零 Autoload 依赖（--script 探针三坑规避）
## 驱动范式：_process 首帧执行 + 显式 quit（day24_f13 范式）

const DescBuilder: GDScript = preload("res://scripts/ui/desc_builder.gd")

var _checked := 0
var _failures := 0
var _started := false

func _check(cond: bool, msg: String) -> void:
	_checked += 1
	if not cond:
		_failures += 1
		print("XX " + msg)

func _load_json(path: String) -> Dictionary:
	var txt: String = FileAccess.get_file_as_string(path)
	if txt.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(txt)
	if parsed is Dictionary:
		return parsed
	return {}

func _process(_delta: float) -> bool:
	if _started:
		return false
	_started = true
	_s1_stats()
	_s2_desc_builder()
	_s3_attr_controller()
	_s4_characters()
	_s5_elements()
	print("\n=== %d assertions, %d failures ===" % [_checked, _failures])
	quit(_failures)
	return true

## §1 stats.json：offensive[2] elemental_damage name=魔法伤害 / economy[3] engineering name=机械学；全量文本零残留
func _s1_stats() -> void:
	var stats: Dictionary = _load_json("res://data/stats.json")
	var groups: Dictionary = stats.get("stats", {})
	var offensive: Array = groups.get("offensive", [])
	var economy: Array = groups.get("economy", [])
	var found_ed := false
	var found_eng := false
	for rec in offensive:
		if str(rec.get("id", "")) == "elemental_damage":
			found_ed = true
			_check(rec.get("name", "") == "魔法伤害",
				"§1/stats: elemental_damage name == 魔法伤害（实得 %s）" % str(rec.get("name")))
			_check(str(rec.get("base")) == "0", "§1/stats: elemental_damage base 保持 0（实得 %s）" % str(rec.get("base")))
	for rec in economy:
		if str(rec.get("id", "")) == "engineering":
			found_eng = true
			_check(rec.get("name", "") == "机械学",
				"§1/stats: engineering name == 机械学（实得 %s）" % str(rec.get("name")))
			_check(str(rec.get("base")) == "0", "§1/stats: engineering base 保持 0（实得 %s）" % str(rec.get("base")))
	_check(found_ed, "§1/stats: offensive 含 elemental_damage 行（id 零改动）")
	_check(found_eng, "§1/stats: economy 含 engineering 行（id 零改动）")
	var raw: String = FileAccess.get_file_as_string("res://data/stats.json")
	_check(not raw.contains("元素伤害") and not raw.contains("工程学"),
		"§1/stats: 全量文本无「元素伤害/工程学」残留")

## §2 desc_builder STAT_CN：elemental_damage→魔法伤害 / engineering→机械学（统一 3 字）
func _s2_desc_builder() -> void:
	var cn: Dictionary = DescBuilder.STAT_CN
	_check(str(cn.get("elemental_damage", "")) == "魔法伤害",
		"§2/desc_builder: elemental_damage → 魔法伤害（实得 %s）" % str(cn.get("elemental_damage")))
	_check(str(cn.get("engineering", "")) == "机械学",
		"§2/desc_builder: engineering → 机械学（实得 %s，统一 3 字）" % str(cn.get("engineering")))

## §3 attribute_controller CONSUMED_BONUS_KEYS：elemental_damage id 锚点保持（id 零改动）
##   ⚠️ 不 preload（attribute_controller 引用 Autoload DataLoader，--script 环境编译失败 = 探针三坑①）
##   → 改读源码文本断言 CONSUMED_BONUS_KEYS 数组含 "elemental_damage"
func _s3_attr_controller() -> void:
	var src: String = FileAccess.get_file_as_string("res://scripts/player/attribute_controller.gd")
	_check(src.contains("\"elemental_damage\""),
		"§3/attribute_controller: 源码仍含 \"elemental_damage\" id（CONSUMED_BONUS_KEYS 锚点，id 零改动）")

## §4 characters：艾琳 growth.description 含魔法伤害 / 诺亚含机械学，均无旧名
func _s4_characters() -> void:
	var chars: Dictionary = _load_json("res://data/characters.json")
	var d_irene := ""
	var d_noa := ""
	for rec in chars.get("characters", []):
		var gd: Dictionary = rec.get("growth", {})
		if str(rec.get("id", "")) == "se_irene":
			d_irene = str(gd.get("description", ""))
		elif str(rec.get("id", "")) == "se_noa":
			d_noa = str(gd.get("description", ""))
	_check(d_irene.contains("魔法伤害") and not d_irene.contains("元素伤害"),
		"§4/characters: 艾琳成长描述含「魔法伤害」且无「元素伤害」（实得 %s）" % d_irene)
	_check(d_noa.contains("机械学") and not d_noa.contains("工程学"),
		"§4/characters: 诺亚成长描述含「机械学」且无「工程学」（实得 %s）" % d_noa)

## §5 elements：燃烧/中毒 effect 属性名引用同步 + scaling_attr id 零改动
func _s5_elements() -> void:
	var els: Dictionary = _load_json("res://data/elements.json")
	var statuses: Dictionary = els.get("elemental_status", {})
	var burn_effect: String = ""
	var poison_effect: String = ""
	var burn_attr: String = ""
	for k in ["fire", "poison"]:
		var rec: Dictionary = statuses.get(k, {})
		var effect: String = str(rec.get("effect", ""))
		var attr: String = str(rec.get("scaling_attr", ""))
		if k == "fire":
			burn_effect = effect
			burn_attr = attr
		else:
			poison_effect = effect
	_check(burn_effect.contains("魔法伤害") and not burn_effect.contains("元素伤害"),
		"§5/elements: 燃烧 effect 含「魔法伤害」且无「元素伤害」（实得 %s）" % burn_effect)
	_check(poison_effect.contains("魔法伤害") and not poison_effect.contains("元素伤害"),
		"§5/elements: 中毒 effect 含「魔法伤害」且无「元素伤害」（实得 %s）" % poison_effect)
	_check(burn_attr == "elemental_damage",
		"§5/elements: 燃烧 scaling_attr 仍 == elemental_damage（id 零改动，实得 %s）" % burn_attr)
