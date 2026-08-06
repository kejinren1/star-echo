## 随机节点路线生成器（Day 14-15 · D14-15-T1）
## 层式分支拓扑（集成战略式）：L 层 × N 节点/层，末层固定 1 Boss 节点；
## 种子可复现：RandomNumberGenerator 实例（禁全局 RNG shuffle）；
## 事件改写预留：modifiers.reroute 可覆盖类型权重（消费归 Day 16）；
## 节点→波次映射：战斗类（battle/elite）按战斗序号映射 wave n（waves.json 6-19
## 天然含 elite 前缀 → elite 节点即取对应波），boss 固定 wave 20，shop/event 无战斗
## （wave_index=0）；首层保证含 battle；硬校验 battle_count <= 19。
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
## 硬约束：战斗类节点数上限（boss 占 wave 20，战斗类映射 wave 1-19）
const MAX_BATTLE_NODES: int = 19
const BOSS_WAVE: int = 20

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

	# 1) 中间层类型生成（末层固定 boss，单独追加）
	var layers: Array = []
	var battle_count: int = 0
	var middle_layers: int = layers_count - 1
	for _li in middle_layers:
		var layer_nodes: Array = []
		for _ni in nodes_per_layer:
			var node_type: String = _weighted_pick(rng, weights, battle_count, modifiers)
			if node_type == NODE_ELITE and battle_count < MIN_ELITE_WAVE:
				node_type = NODE_BATTLE  # 低层无精英波映射 → 降级为战斗
			if node_type == NODE_BATTLE or node_type == NODE_ELITE:
				battle_count += 1
			layer_nodes.append({"type": node_type, "wave_index": 0})
		layers.append(layer_nodes)

	# 2) 首层保证 battle（防进局无事可做）
	if not layers.is_empty() and not _layer_has_battle(layers[0]):
		var first_layer: Array = layers[0]
		var first_type: String = str(first_layer[0].get("type", ""))
		if first_type == NODE_EVENT or first_type == NODE_SHOP:
			first_layer[0] = {"type": NODE_BATTLE, "wave_index": 0}
			battle_count += 1

	# 3) 战斗序号分配（battle/elite 按生成顺序映射 wave n；shop/event 保持 0）
	battle_count = 0
	for li in layers.size():
		var layer_nodes: Array = layers[li]
		for ni in layer_nodes.size():
			var node_data: Dictionary = layer_nodes[ni]
			var node_type: String = str(node_data.get("type", ""))
			if node_type == NODE_BATTLE or node_type == NODE_ELITE:
				battle_count += 1
				node_data["wave_index"] = _resolve_wave(battle_count)

	# 4) 末层 boss
	layers.append([{"type": NODE_BOSS, "wave_index": BOSS_WAVE}])

	# 5) 硬校验：战斗类节点数 ≤ max_battle（boss 占 wave 20）
	if battle_count > max_battle:
		push_error("[RouteGenerator] 战斗节点数 %d 超过上限 %d（boss 占 wave 20）" % [battle_count, max_battle])
		return {}

	return {
		"seed": seed,
		"layers": layers,
		"modifiers": modifiers,
		"flags": routes.get("flags", {}),
	}

# ========== 内部工具 ==========

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
