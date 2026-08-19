extends SceneTree
## RELIC-0 数据层地基（方案师第 31 轮 · 拆解第 61 轮 · 2026-08-19 #3 执行）
## SPEC §3/§4/§5.3：items relic 条目字段扩展（rarity/tag/tier/set_id/set_tier/set_effects/
## unlock_condition）+ DataLoader 接口 + meta_progress 两新键（兼容旧档）
## §1 字段键齐全（12 条 relic：tag/tier 全覆盖；套装 4 件 set_* 齐；unlock 有值条目在位）
## §2 套装分组（get_relic_set_ids：starbound_gamble/deadline_dancer 各 2 件 + set_effects 档位表）
## §3 池过滤基础（get_relic_defs 12 条 + 新占位 price=0 不进商店池 = slot=relic 且 price>0 仅 2 件既有）
## §4 存档兼容（_default_meta 两新键 + 旧档缺键加载零崩，day30_save_compat 14/14 范式）
## §5 回归抽样（items.json 64 条 + 新条目 id/rarity/effects 子表解析正确）
## 驱动范式：_process 首帧执行（Autoload 挂载后 root 可见）+ 显式 quit（--script 探针三坑规避）
## ⚠️ 不 preload save_system.gd（其 load_meta 引用 Autoload DataLoader，--script 编译失败
## = 探针三坑①）→ §4 存档兼容走源码文本断言（RELIC-A §3 同款范式）

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
	_s1_fields()
	_s2_sets()
	_s3_pool()
	_s4_save()
	_s5_sampling()
	print("\n=== %d assertions, %d failures ===" % [_checked, _failures])
	quit(_failures)
	return true

func _relics() -> Array:
	var loader: Node = root.get_node_or_null("DataLoader")
	if loader == null:
		return []
	return loader.call("get_relic_defs")

## §1 字段键齐全：12 条 relic 全有 tag/tier；套装 4 件 set_id/set_tier/set_effects 齐；
##    unlock_condition 有值条目 ≥4（套装 2 解锁 + 流派 T2/T3 3 件）
func _s1_fields() -> void:
	var relics: Array = _relics()
	_check(relics.size() == 12, "§1/relic_defs: 全量属性遗物 12 条（实得 %d）" % relics.size())
	var missing_tag := 0
	var missing_tier := 0
	var set_items := 0
	for r in relics:
		if not r.has("tag") or str(r.get("tag", "")).is_empty():
			missing_tag += 1
		if not r.has("tier"):
			missing_tier += 1
		if not str(r.get("set_id", "")).is_empty():
			set_items += 1
			var se: Variant = r.get("set_effects", [])
			_check(se is Array and (se as Array).size() == 2,
				"§1/set_effects: %s 套装档位表数组长 2（实得 %s）" % [str(r.get("id")), str(se)])
			var tiers_ok := (se is Array and (se as Array).size() == 2 \
				and int((se as Array)[0].get("tier", 0)) == 1 \
				and int((se as Array)[1].get("tier", 0)) == 2)
			_check(tiers_ok, "§1/set_effects: %s 档位键 1/2 有序（实得 %s）" % [str(r.get("id")), str(se)])
			var eff1: Dictionary = (se as Array)[0].get("effects", {})
			var eff2: Dictionary = (se as Array)[1].get("effects", {})
			_check(not eff1.is_empty() and not eff2.is_empty(),
				"§1/set_effects: %s 两档 effects 均非空" % str(r.get("id")))
	_check(missing_tag == 0, "§1/relic_defs: tag 全覆盖（缺失 %d）" % missing_tag)
	_check(missing_tier == 0, "§1/relic_defs: tier 全覆盖（缺失 %d）" % missing_tier)
	_check(set_items == 4, "§1/relic_defs: 套装件 4 条（实得 %d）" % set_items)
	var unlocked := 0
	for r in relics:
		if not str(r.get("unlock_condition", "")).is_empty():
			unlocked += 1
	_check(unlocked >= 5, "§1/relic_defs: unlock_condition 有值条目 ≥5（实得 %d：套装4+动能+冲刺+音速）" % unlocked)

## §2 套装分组：get_relic_set_ids → 两套装各 2 件 + set_tier=2 + set_effects 档位表结构
func _s2_sets() -> void:
	var loader: Node = root.get_node_or_null("DataLoader")
	if loader == null:
		_check(false, "§2/sets: DataLoader Autoload 缺失")
		return
	var sets: Dictionary = loader.call("get_relic_set_ids")
	_check(sets.size() == 2, "§2/sets: 套装数 2（实得 %d：%s）" % [sets.size(), str(sets.keys())])
	for sid in ["starbound_gamble", "deadline_dancer"]:
		_check(sets.has(sid), "§2/sets: %s 在位" % sid)
		if sets.has(sid):
			var g: Dictionary = sets[sid]
			_check(int(g.get("count", 0)) == 2, "§2/sets: %s 件数 2（实得 %d）" % [sid, int(g.get("count", 0))])
			_check(int(g.get("set_tier", 0)) == 2, "§2/sets: %s set_tier 2 档（实得 %d）" % [sid, int(g.get("set_tier", 0))])
			var se: Array = g.get("set_effects", [])
			_check(se.size() == 2, "§2/sets: %s set_effects 档位表 2 档（实得 %d）" % [sid, se.size()])
	if sets.has("starbound_gamble"):
		var sb: Dictionary = sets["starbound_gamble"]
		var eff1: Dictionary = (sb.get("set_effects", []) as Array)[0].get("effects", {})
		_check(int(eff1.get("max_hp_percent", 0)) == -90,
			"§2/sets: 星骸孤注 tier1 max_hp_percent == -90（实得 %s）" % str(eff1.get("max_hp_percent")))
		var eff2: Dictionary = (sb.get("set_effects", []) as Array)[1].get("effects", {})
		_check(int(eff2.get("damage_percent", 0)) == 100,
			"§2/sets: 星骸孤注 tier2 damage_percent == 100（实得 %s）" % str(eff2.get("damage_percent")))
	if sets.has("deadline_dancer"):
		var dd: Dictionary = sets["deadline_dancer"]
		var e1: Dictionary = (dd.get("set_effects", []) as Array)[0].get("effects", {})
		_check(int(e1.get("speed_percent", 0)) == 30,
			"§2/sets: 死线舞者 tier1 speed_percent == 30（实得 %s）" % str(e1.get("speed_percent")))

## §3 池过滤基础：新占位条目 price=0（天然不进商店池 = slot=relic 且 price>0 仅 2 件既有，
##    resonant_shard 先例）；商店可见遗物仍 2 件，行为零变化
func _s3_pool() -> void:
	var data: Dictionary = _load_json("res://data/items.json")
	var shop_relics := 0
	var zero_price := 0
	for it in data.get("items", []):
		if str(it.get("slot", "")) != "relic":
			continue
		if int(it.get("price", 0)) > 0:
			shop_relics += 1
		else:
			zero_price += 1
	_check(shop_relics == 2, "§3/pool: 商店可见遗物仍 2 件（实得 %d，新占位 price=0 天然排除）" % shop_relics)
	_check(zero_price == 10, "§3/pool: 新占位遗物 10 件 price=0（实得 %d）" % zero_price)

## §4 存档兼容：_default_meta 两新键 + 旧档缺键加载零崩
##    ⚠️ 不 preload save_system.gd（其 load_meta 引用 Autoload DataLoader = 探针三坑①，
##    --script 环境编译失败）→ 源码文本断言（RELIC-A §3 同款范式）；行为面由
##    day30_save_compat 14/14 + day27_meta 35/35 硬门槛探针兜底（零改动）
func _s4_save() -> void:
	var src: String = FileAccess.get_file_as_string("res://scripts/systems/save_system.gd")
	var def_seg: String = src.substr(src.find("func _default_meta"), src.find("func load_meta") - src.find("func _default_meta"))
	_check(def_seg.contains("\"relic_affinity\": {}"), "§4/save: _default_meta 含 relic_affinity 空字典")
	_check(def_seg.contains("\"relic_codex\": []"), "§4/save: _default_meta 含 relic_codex 空数组")
	_check(src.contains("data.get(\"relic_affinity\", {})"), "§4/save: load_meta 旧档缺键 relic_affinity → 空字典零崩")
	_check(src.contains("data.get(\"relic_codex\", [])"), "§4/save: load_meta 旧档缺键 relic_codex → 空数组零崩")
	# 缺省值容错锚点：默认 meta 是 load_meta 兜底起点（缺文件/解析失败 → 两键默认在位）
	_check(def_seg.contains("relic_affinity") and def_seg.contains("relic_codex"),
		"§4/save: 缺档兜底路径两键在位")

## §5 回归抽样：items.json 64 条 + 新 10 条 id/rarity/effects 子表解析正确
func _s5_sampling() -> void:
	var data: Dictionary = _load_json("res://data/items.json")
	var items: Array = data.get("items", [])
	_check(items.size() == 64, "§5/sample: items.json 64 条（实得 %d）" % items.size())
	var ids: Array = []
	for it in items:
		ids.append(str(it.get("id")))
	for nid in ["relic_starbound_heart", "relic_starbound_core", "relic_deadline_boots",
			"relic_deadline_heels", "relic_swift_feet", "relic_swift_trade", "relic_swift_dodge",
			"relic_swift_kinetic", "relic_swift_rush", "relic_swift_split"]:
		_check(ids.has(nid), "§5/sample: 新条目 %s 在位" % nid)
	for it in items:
		if str(it.get("id", "")).begins_with("relic_swift"):
			var rarity: String = str(it.get("rarity", ""))
			_check(rarity in ["common", "uncommon", "rare"],
				"§5/sample: %s rarity 合法（实得 %s）" % [str(it.get("id")), rarity])
	var feet := {}
	for it in items:
		if str(it.get("id")) == "relic_swift_feet":
			feet = it.get("effects", {})
	_check(int(feet.get("speed_percent", 0)) == 10,
		"§5/sample: 疾行靴 speed_percent == 10（实得 %s）" % str(feet.get("speed_percent")))
	var split := {}
	for it in items:
		if str(it.get("id")) == "relic_swift_split":
			split = it.get("effects", {})
	_check(int(split.get("move_speed_threshold", 0)) == 450 and int(split.get("projectile_split", 0)) == 1,
		"§5/sample: 音速分裂 threshold 450 + split 1（实得 %s）" % str(split))
