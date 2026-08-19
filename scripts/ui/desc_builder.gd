## 物品/选项说明文案生成器（2026-08-08 反馈专员 · F-24/F-25 用户拍板）
## 商店卡片 tooltip 与升级面板选项 tooltip 共用：把数据（effects/trigger/special/level_table）
## 转成中文说明文本——「购买前/升级前不知道效果」修复。
## 纯静态函数 + 只读 DataLoader，无状态无副作用（探针可白盒直调）。
class_name DescBuilder
extends RefCounted

## effects stat 键 → 中文名（items.json 全 37 键覆盖）

## Object.get() 只收 1 参（Dictionary 才有默认值重载）——Resource/Node 取属性带默认值用本函数
static func _val(obj: Object, key: String, default: Variant = null) -> Variant:
	if obj == null or not (key in obj):
		return default
	return obj.get(key)

const STAT_CN: Dictionary = {
	"armor": "护甲",
	"attack_speed_per_different_weapon_percent": "每把不同武器攻速",
	"attack_speed_percent": "攻速",
	"boss_elite_damage_percent": "对精英/Boss 伤害",
	"burn_duration_percent": "燃烧时长",
	"crit_chance_percent": "暴击率",
	"crit_damage_percent": "暴击伤害",
	"damage_percent": "伤害",
	"damage_reduction_on_hit_percent": "受击减伤",
	"damage_taken_percent": "受到伤害",
	"dodge_heal_amount": "闪避回血",
	"dodge_heal_chance": "闪避回血概率",
	"dodge_percent": "闪避率",
	"element_duration_percent": "元素状态时长",
	"element_reaction_damage_percent": "元素反应伤害",
	"elemental_damage": "魔法伤害",
	"engineering": "机械学",
	"fire_damage_percent": "火焰伤害",
	"harvesting": "收割",
	"hp_regen": "生命回复",
	"knockback": "击退力",
	"life_steal_percent": "吸血",
	"luck": "幸运",
	"max_hp": "最大生命",
	"melee_damage": "近战伤害",
	"miss_chance_percent": "敌人失手率",
	"range": "攻击范围",
	"range_percent": "攻击范围",
	"ranged_damage": "远程伤害",
	"reaction_heal": "反应回血",
	"shop_weapon_upgrade": "商店武器升级",
	"speed_percent": "移速",
	"structure_damage_percent": "炮台伤害",
	"structure_duration_percent": "炮台时长",
	"summon_count": "召唤数量",
	"xp_gain_percent": "经验获取",
}

## effects 字典 → 中文描述（「近战伤害 +8 · 暴击伤害 +20%」）
## percent 后缀键 → +N%；布尔/无后缀数值键 → +N（整数化）
static func effects_text(effects: Dictionary) -> String:
	var parts: Array[String] = []
	for key in effects:
		var cn: String = str(STAT_CN.get(key, key))
		var v: float = float(effects[key])
		if v == 0.0:
			continue
		var suffix: String = ""
		if str(key).ends_with("_percent"):
			# 值变量原样插入（非格式串），"%s" 仅一个：%% 转义只适用于格式串本身
			suffix = "%" if v != 0.0 else ""
		elif str(key) == "shop_weapon_upgrade":
			parts.append("%s" % cn)
			continue
		var num: String = ("%d" % int(v)) if v == floorf(v) else ("%.1f" % v)
		parts.append("%s %s%s" % [cn, ("+" if v > 0 else ""), num + suffix])
	return " · ".join(parts)

## trigger 机制型被动词条 → 中文说明（F-13 三机制）
static func trigger_text(trigger: Dictionary) -> String:
	if trigger.is_empty():
		return ""
	var ttype: String = str(trigger.get("type", ""))
	match ttype:
		"on_crit":
			return "暴击命中时：周围 %dpx 内敌人连锁 %d%% 暴击伤害" % [int(trigger.get("radius", 0)), int(float(trigger.get("ratio", 0.0)) * 100.0)]
		"on_kill":
			return "击杀敌人时：回复 %s 生命" % ("%d" % int(trigger.get("heal", 0)) if float(trigger.get("heal", 0)) == floorf(float(trigger.get("heal", 0))) else "%.1f" % float(trigger.get("heal", 0)))
		"low_health":
			return "生命低于 %d%% 时：伤害 ×%.1f、攻速 ×%.1f" % [int(float(trigger.get("threshold", 0.0)) * 100.0), float(trigger.get("attack_mult", 1.0)), float(trigger.get("speed_mult", 1.0))]
	return ""

## 商店卡片 tooltip：Item（被动/遗物）→ 名称 + effects/trigger；Weapon → 名称 + 数值 + special
static func card_tooltip(item: Resource) -> String:
	if item == null:
		return ""
	if item.get("weapon_type") != null:
		return weapon_tooltip(item)
	return item_tooltip(item)

## Item（被动/遗物/核心）tooltip：名称 + effects 中文 + trigger 机制说明
static func item_tooltip(item: Resource) -> String:
	var name: String = str(_val(item, "item_name", "???"))
	var lines: Array[String] = [name]
	var effects: Dictionary = _val(item, "stat_bonuses", {})
	if effects is Dictionary and not effects.is_empty():
		var txt: String = effects_text(effects)
		if not txt.is_empty():
			lines.append(txt)
	var trigger: Dictionary = _val(item, "trigger", {})
	if trigger is Dictionary and not trigger.is_empty():
		var tt: String = trigger_text(trigger)
		if not tt.is_empty():
			lines.append(tt)
	if item.get("slot") == "relic":
		lines.append("遗物（装备即生效）")
	return "\n".join(lines)

## Weapon tooltip：名称 + 基础数值行 + special + 可进化提示
static func weapon_tooltip(w: Resource) -> String:
	var name: String = str(_val(w, "weapon_name", "???"))
	var lines: Array[String] = [name]
	var stats: Array[String] = []
	stats.append("伤害 %d" % int(_val(w, "base_damage", 0)))
	var fr: float = float(_val(w, "fire_rate", 0.0))
	if fr > 0.0:
		stats.append("攻速 %.1f/s" % fr)
	var rng: int = int(_val(w, "attack_range", 0))
	if rng > 0:
		stats.append("范围 %d" % rng)
	if float(_val(w, "crit_chance", 0.0)) > 0.0:
		stats.append("暴击 %d%%" % int(float(_val(w, "crit_chance", 0.0)) * 100.0))
	if int(_val(w, "pierce", 0)) > 0:
		stats.append("穿透 %d" % int(_val(w, "pierce", 0)))
	lines.append(" · ".join(stats))
	var sp: String = str(_val(w, "description", ""))
	if sp.is_empty():
		var s2: Variant = w.get("special_desc")
		sp = str(s2) if s2 != null else ""
	if not sp.is_empty():
		lines.append(sp)
	# 可进化提示（build_weapon_from_data 注入的 evolution_result_name meta；
	# 本类禁引用 Autoload 标识符——preload 编译期不可见）
	var ev_name: String = str(w.get_meta("evolution_result_name", "")) if w.has_meta(&"evolution_result_name") else ""
	if not ev_name.is_empty():
		lines.append("满级可进化『%s』（需对应核心）" % ev_name)
	return "\n".join(lines)

## 升级面板选项 tooltip（F-25）：属性/武器升级/进化三型
static func option_tooltip(opt: Dictionary) -> String:
	var otype: String = str(opt.get("type", ""))
	if otype == "weapon_upgrade":
		var weapon: Resource = opt.get("weapon")
		if weapon == null:
			return str(opt.get("label", "升级武器"))
		var lines: Array[String] = ["升级「%s」→ Lv.%d" % [str(_val(weapon, "weapon_name", "?")), int(_val(weapon, "level", 1)) + 1]]
		var table: Array = _val(weapon, "level_table", [])
		var next_idx: int = int(_val(weapon, "level", 1))
		if next_idx >= 1 and next_idx < table.size():
			var entry: Dictionary = table[next_idx]
			var up: Variant = entry.get("upgrade", "")
			if up != null and not str(up).is_empty():
				lines.append(str(up))
			lines.append("伤害 %d · 攻速 %.1f/s" % [int(entry.get("damage", 0)), 1.0 / maxf(float(entry.get("cooldown", 1.0)), 0.01)])
		else:
			lines.append("武器等级提升")
		return "\n".join(lines)
	if otype == "evolution":
		var ev: Dictionary = opt.get("evolution", {})
		var lines2: Array[String] = ["进化『%s』" % str(ev.get("result_name", ""))]
		var desc: Variant = ev.get("description", "")
		if desc != null and not str(desc).is_empty():
			lines2.append(str(desc))
		# 结果武器数值由 level_up_panel 注入（result_damage；本类禁引用 Autoload）
		var rd: Variant = opt.get("result_damage", 0)
		if int(rd) > 0:
			lines2.append("伤害 %d" % int(rd))
		lines2.append("武器被替换为进化形态（核心消耗）")
		return "\n".join(lines2)
	# 属性选项：label + 加成通道说明
	var label: String = str(opt.get("label", "强化"))
	var mode: String = str(opt.get("mode", "add"))
	var mode_cn: String = {"percent": "乘算加成", "ratio": "比例加成", "add": "固定加成"}.get(mode, "")
	return "%s（%s）" % [label, mode_cn] if not mode_cn.is_empty() else label
