## 随机节点路线生成器（Day 14-15 · D14-15-T1）
## 层式分支拓扑（集成战略式）：L 层 × N 节点/层；boss 层（routes.json boss_layers，
## 缺省末层）为单 Boss 节点层——F-27（2026-08-08 用户拍板）15 关双 Boss：第 10 关、第 15 关；
## 种子可复现：RandomNumberGenerator 实例（禁全局 RNG shuffle）；
## 事件改写预留：modifiers.reroute 可覆盖类型权重（消费归 Day 16）；
## 节点→波次映射：P1 Fix-2 改为按层号分配（layer_index+1），
## 玩家每层只选1节点 → 波次连续不跳号；boss 固定 wave 10（invoker 2阶段，双 Boss 同配置 =
## F-27 用户拍板「第二个 Boss 形象数值与第一个一模一样，不做新美术数值」），
## shop/event 无战斗（wave_index=0）；首层保证含 battle。
extends RefCounted

# ========== 类型常量 ==========

const NODE_BATTLE: String = "battle"
const NODE_EVENT: String = "event"
const NODE_ELITE: String = "elite"
const NODE_SHOP: String = "shop"
const NODE_BOSS: String = "boss"

const NODE_TYPES: Array[String] = [NODE_BATTLE, NODE_EVENT, NODE_ELITE, NODE_SHOP, NODE_BOSS]

# ========== 默认参数（routes.json 缺失/为空时兜底） ==========

const DEFAULT_LAYERS: int = 5
const DEFAULT_NODES_PER_LAYER: int = 3
const DEFAULT_WEIGHTS: Dictionary = {
	NODE_BATTLE: 0.5,
	NODE_EVENT: 0.2,
	NODE_ELITE: 0.15,
	NODE_SHOP: 0.15,
}

## 精英禁抽阈值：当前战斗序号 < 6 时禁抽 elite（waves.json 前 5 波无 elite 前缀敌人）
const MIN_ELITE_WAVE: int = 6
## 硬约束：战斗类节点数上限（boss 占 wave 10；15 关 13 普通层 × 3 节点上限 39）
const MAX_BATTLE_NODES: int = 36
## P1 试玩反馈 Fix-2：Boss 波次从 20 改为 10（invoker 2阶段），
## 配合层制 wave_index 分配消除跳号（4→10 远好于 4→20）
## F-27：双 Boss 关（第 10/15 关）共用 wave 10 配置（第二个 Boss 复用 invoker 形象数值）
const BOSS_WAVE: int = 10

# ========== 生成入口 ==========

## 生成路线（数据驱动：routes.json；seed<0 → 随机种子并回传实际 seed）
## DataLoader 为 autoload 单例（全局常量），运行时/探针均可解析
static func generate(seed: int = -1) -> Dictionary:
	var routes: Dictionary = {}
	if DataLoader != null:
		routes = DataLoader.get_routes()
	return generate_from(seed, routes)

## 白盒生成（routes 参数直传，供探针/事件改写消费方使用；空 routes → 默认参数兜底）
static func generate_from(seed: int = -1, routes: Dictionary = {}) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	if seed >= 0:
		rng.seed = seed
	else:
		rng.randomize()
		seed = int(rng.seed)  # 回传实际种子（可复现）

	var layers_count: int = maxi(2, int(routes.get("layers", DEFAULT_LAYERS)))
	var nodes_per_layer: int = maxi(1, int(routes.get("nodes_per_layer", DEFAULT_NODES_PER_LAYER)))
	var weights: Dictionary = routes.get("weights", {})
	if weights.is_empty():
		weights = DEFAULT_WEIGHTS.duplicate()
	var modifiers: Dictionary = routes.get("modifiers", {})
	var constraints: Dictionary = routes.get("constraints", {})
	var max_battle: int = int(constraints.get("max_battle_nodes", MAX_BATTLE_NODES))
	# F-27（2026-08-08 用户拍板）：boss 层（单 Boss 节点）数据驱动，缺省末层；
	# 15 关配置 = [9, 14]（第 10 关、第 15 关各 1 Boss）
	# ⚠️ JSON 数值解析为 float——`li in boss_layers`（int vs float）严格比较会 miss，
	# 归一化 int 数组（Godot `in` 对数组元素按 Variant 比较，int/float 不等）
	var boss_layers: Array = []
	for bl in routes.get("boss_layers", []):
		boss_layers.append(int(bl))
	if boss_layers.is_empty():
		boss_layers = [layers_count - 1]

	# 1) 层类型生成：普通层随机 N 节点；boss 层单 Boss 节点（跳过随机）
	var layers: Array = []
	var battle_count: int = 0
	for li in layers_count:
		if li in boss_layers:
			layers.append([{"type": NODE_BOSS, "wave_index": 0}])
			continue
		var layer_nodes: Array = []
		for _ni in nodes_per_layer:
			var node_type: String = _weighted_pick(rng, weights, battle_count, modifiers)
			if node_type == NODE_ELITE and battle_count < MIN_ELITE_WAVE:
				node_type = NODE_BATTLE  # 低层无精英波映射 → 降级为战斗
			if node_type == NODE_BATTLE or node_type == NODE_ELITE:
				battle_count += 1
			layer_nodes.append({"type": node_type, "wave_index": 0})
		layers.append(layer_nodes)

	# 2) 首层保证 battle（防进局无事可做；首层为 boss 层时天然跳过）
	if not layers.is_empty() and not _layer_has_battle(layers[0]):
		var first_layer: Array = layers[0]
		var first_type: String = str(first_layer[0].get("type", ""))
		if first_type == NODE_EVENT or first_type == NODE_SHOP:
			first_layer[0] = {"type": NODE_BATTLE, "wave_index": 0}
			battle_count += 1

	# 3) 波次分配（P1 Fix-2：按层号分配 wave_index，玩家每层只选1节点 → 不跳号）
	# battle/elite → wave = layer_index + 1；boss → BOSS_WAVE(10，双 Boss 同配置)；shop/event → 0
	battle_count = 0
	for li in layers.size():
		var layer_nodes: Array = layers[li]
		for ni in layer_nodes.size():
			var node_data: Dictionary = layer_nodes[ni]
			var node_type: String = str(node_data.get("type", ""))
			if node_type == NODE_BATTLE or node_type == NODE_ELITE:
				node_data["wave_index"] = li + 1
				battle_count += 1
			elif node_type == NODE_BOSS:
				node_data["wave_index"] = BOSS_WAVE

	# 4) 硬校验：战斗类节点数 ≤ max_battle
	if battle_count > max_battle:
		push_error("[RouteGenerator] 战斗节点数 %d 超过上限 %d（boss 占 wave 10）" % [battle_count, max_battle])
		return {}

	return {
		"seed": seed,
		"layers": layers,
		"modifiers": modifiers,
		"flags": routes.get("flags", {}),
		"boss_layers": boss_layers,
	}

# ========== 改线接口（Day 16 · D16-T3：事件 effect_on_route 消费落点） ==========

## 重抽未访问层节点类型（事件 reroute：改变后续路线走向）。
## from_layer: 从此层（含）开始重抽；weights_delta: 类型权重增量（叠加到基准权重，负值合法但 clamp ≥0；
##             silent_corridor = {"event":-0.1,"battle":+0.1}）。
## 边界：末层 boss 层不可改写；elite 低层禁抽保持；重抽后战斗序号 → wave_index 全量重映射；
##       重抽结果 battle_count > 上限则回滚（保持原路线）+ push_warning。
## 随机性：派生种子（seed + 7919）的 RNG 实例，禁 Array.shuffle（全局 RNG 种子不可控）。
static func reroute_remaining(route: Dictionary, from_layer: int, weights_delta: Dictionary) -> void:
	var layers: Array = route.get("layers", [])
	# F-27：boss 层（第 10/15 关）保护——含末层；from_layer 越界或指向 boss 层 → 拒绝
	var boss_layers: Array = []
	for bl in route.get("boss_layers", []):
		boss_layers.append(int(bl))
	if boss_layers.is_empty():
		boss_layers = [layers.size() - 1]
	if from_layer < 0 or from_layer >= layers.size() or from_layer in boss_layers:
		push_warning("[RouteGenerator] reroute_remaining 层越界或指向 Boss 层: %d（boss 层不可改写）" % from_layer)
		return
	# 基准权重 = 默认权重 + 已登记 modifiers.reroute（绝对覆盖键值）
	var weights: Dictionary = DEFAULT_WEIGHTS.duplicate()
	var modifiers: Dictionary = route.get("modifiers", {})
	var existing: Dictionary = modifiers.get("reroute", {})
	for key in existing:
		weights[key] = float(existing[key])
	# 叠加增量（clamp ≥0）
	for key in weights_delta:
		weights[key] = maxf(0.0, float(weights.get(key, 0.0)) + float(weights_delta[key]))

	# 保存原类型快照（回滚用）
	var original_types: Array = []
	for li in range(from_layer, layers.size() - 1):
		var snapshot: Array = []
		for node in layers[li]:
			snapshot.append(str(node.get("type", "")))
		original_types.append(snapshot)

	# 重抽（派生种子 RNG；battle_count 从已访问层的战斗数继续累计）
	var rng := RandomNumberGenerator.new()
	rng.seed = int(route.get("seed", 0)) + 7919
	var battle_count: int = _count_battles_before(layers, from_layer)
	for li in range(from_layer, layers.size() - 1):
		if li in boss_layers:
			continue  # F-27：Boss 层（第 10/15 关）不改写
		var layer_nodes: Array = layers[li]
		for ni in layer_nodes.size():
			var node: Dictionary = layer_nodes[ni]
			var node_type: String = _weighted_pick(rng, weights, battle_count, modifiers)
			if node_type == NODE_ELITE and battle_count < MIN_ELITE_WAVE:
				node_type = NODE_BATTLE
			if node_type == NODE_BATTLE or node_type == NODE_ELITE:
				battle_count += 1
			node["type"] = node_type

	# 战斗数上限校验：超限回滚原类型
	if battle_count > int(route.get("constraints", {}).get("max_battle_nodes", MAX_BATTLE_NODES)):
		push_warning("[RouteGenerator] reroute_remaining 重抽后战斗数 %d 超上限，已回滚" % battle_count)
		for li in original_types.size():
			var layer_nodes: Array = layers[from_layer + li]
			for ni in layer_nodes.size():
				layer_nodes[ni]["type"] = original_types[li][ni]

	# 战斗序号 → wave_index 全量重映射（类型变化影响战斗序号）
	_reassign_wave_indices(route)
	# 最终权重登记回 modifiers.reroute（可观察 + 后续生成/重抽消费同一权重）
	modifiers["reroute"] = weights
	route["modifiers"] = modifiers

## 单点强制节点类型（事件 unlock_node：rib_layer_shortcut 强制精英等）。
## 边界：层/节点越界、末层 boss、非法类型（含 boss）→ push_warning 拒绝；
## 强制后 wave_index 全量重映射（战斗序号变化）；不改 route.seed/modifiers/flags。
static func force_node_type(route: Dictionary, layer_index: int, node_index: int, new_type: String) -> void:
	var layers: Array = route.get("layers", [])
	# F-27：boss 层（第 10/15 关）保护（含末层）
	var boss_layers: Array = []
	for bl in route.get("boss_layers", []):
		boss_layers.append(int(bl))
	if boss_layers.is_empty():
		boss_layers = [layers.size() - 1]
	if layer_index < 0 or layer_index >= layers.size():
		push_warning("[RouteGenerator] force_node_type 层越界: %d" % layer_index)
		return
	if layer_index in boss_layers:
		push_warning("[RouteGenerator] force_node_type Boss 层不可改写: %d" % layer_index)
		return
	var layer_nodes: Array = layers[layer_index]
	if node_index < 0 or node_index >= layer_nodes.size():
		push_warning("[RouteGenerator] force_node_type 节点越界: %d/%d" % [node_index, layer_nodes.size()])
		return
	if new_type == NODE_BOSS or not NODE_TYPES.has(new_type):
		push_warning("[RouteGenerator] force_node_type 非法类型: %s" % new_type)
		return
	layer_nodes[node_index]["type"] = new_type
	_reassign_wave_indices(route)

# ========== 内部工具 ==========

## 从层 0 到 from_layer-1 的战斗类节点数（重抽时精英禁抽阈值的累计基数）
static func _count_battles_before(layers: Array, from_layer: int) -> int:
	var count: int = 0
	for li in mini(from_layer, layers.size()):
		for node in layers[li]:
			var node_type: String = str(node.get("type", ""))
			if node_type == NODE_BATTLE or node_type == NODE_ELITE:
				count += 1
	return count

## 全路线 wave_index 重映射（P1 Fix-2：按层号分配，与生成主路径一致）
## battle/elite → wave = layer_index + 1；boss → BOSS_WAVE(10)；shop/event → 0
## 生成器主路径与改线接口共用同一套映射逻辑（D16-T3）
static func _reassign_wave_indices(route: Dictionary) -> void:
	var layers: Array = route.get("layers", [])
	for li in layers.size():
		var layer_nodes: Array = layers[li]
		for ni in layer_nodes.size():
			var node: Dictionary = layer_nodes[ni]
			var node_type: String = str(node.get("type", ""))
			if node_type == NODE_BATTLE or node_type == NODE_ELITE:
				node["wave_index"] = li + 1
			elif node_type == NODE_BOSS:
				node["wave_index"] = BOSS_WAVE
			else:
				node["wave_index"] = 0

## 权重随机抽类型（RandomNumberGenerator 实例 + 自实现区间采样，禁 Array.shuffle）
## modifiers.reroute 可覆盖类型权重（事件改写预留，消费归 Day 16）
static func _weighted_pick(rng: RandomNumberGenerator, weights: Dictionary, battle_count: int, modifiers: Dictionary) -> String:
	var w: Dictionary = weights.duplicate()
	var reroute: Dictionary = modifiers.get("reroute", {})
	for key in reroute:
		w[key] = float(reroute[key])
	var total: float = 0.0
	for key in w:
		total += maxf(0.0, float(w[key]))
	if total <= 0.0:
		return NODE_BATTLE
	var roll: float = rng.randf() * total
	var acc: float = 0.0
	for key in w:
		if key == NODE_ELITE and battle_count < MIN_ELITE_WAVE:
			continue  # 低层禁抽精英（权重重分配）
		acc += maxf(0.0, float(w[key]))
		if roll < acc:
			return str(key)
	return NODE_BATTLE  # 兜底

## 首层是否含战斗节点
static func _layer_has_battle(layer_nodes: Array) -> bool:
	for node in layer_nodes:
		var node_type: String = str(node.get("type", ""))
		if node_type == NODE_BATTLE or node_type == NODE_ELITE:
			return true
	return false

## 波次只读校验：DataLoader.get_wave(n) 存在则用，否则回退上一可用波
static func _resolve_wave(index: int) -> int:
	var w: int = index
	while w > 0:
		if DataLoader != null and not DataLoader.get_wave(w).is_empty():
			return w
		w -= 1
	return index
