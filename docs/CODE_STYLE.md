# 代码风格规范（CODE_STYLE）

> 建立：2026-08-13（阶段 F · F3 状态机规范化批 A 首步）
> 单一事实源：本文档 + docs/TECH_DEBT_PLAN.md §2.6/§8。F5 收口批将复用本章节作为评审清单。
> 适用范围：scripts/ 下全部 GDScript（自动加载、场景脚本、工具探针除外——探针属测试代码，
> 允许白盒直驱，不受状态机形态约束，但不得在探针中定义游戏逻辑状态）。

---

## §2.6 状态机规范（两种固定形态）

项目中**一切状态机必须二选一**，禁止第三种形态：

### 形态 A：扁平流程态（enum + match + 统一转移入口）

适用于「游戏流程 / 面板流程」这类**一次只有一个状态**、转移由外部事件驱动的场景
（例：GameManager 的 GameState）。

```gdscript
enum GameState { MENU, BATTLE, SHOP, ROUTE_SELECT, GAME_OVER }

func _transition(next: GameState, context: Dictionary = {}) -> void:
    if current_state == next:
        return                     # 同值早退（幂等，防重复 emit）
    current_state = next
    _state_context = context       # 正交维度数据由 context 承载，不另立状态
    state_changed.emit(current_state)
```

要点：
1. 枚举值**必须有类型标注**（`GameState` 而非 `int`）。
2. 状态赋值**只允许出现在 `_transition` 内**（grep 验收：`current_state = ` 全局仅 1 处）。
3. 正交维度（is_boss_wave、_shop_from_battle、route 模式等）**不是状态**——用布尔/查询函数
   承载，进入/退出状态时在转移点统一置位复位，禁止散落多处赋值。
4. context 字典透传本次转移的附加数据（如 `{"from_battle": true}`）。

### 形态 B：行为/表现态（enum + 状态表 Dictionary）

适用于「实体行为 / 动画 / 阶段」这类**状态与状态行为一一对应**、每态有专属参数的场景
（例：enemy BossPhase、player PlayerState）。

```gdscript
enum BossPhase { P1, P2, P3 }
const PHASE_TABLE: Dictionary = {
    BossPhase.P1: {"skills": [...], "weights": [...], "ai_interval": 4.0},
    BossPhase.P2: {...},
}

func _transition_phase(next: BossPhase) -> void:
    if _phase == next:
        return
    _phase = next
    _enter_phase_hook(PHASE_TABLE[_phase])   # 进入钩子：读状态表、清计时器、播横幅等
```

要点：
1. 状态表是 Dictionary（**状态 → 行为参数**），禁止散落的 if/elif 判断行为。
2. 状态表数据优先从数据驱动构建（enemy phases 来自 enemies.json），禁硬编码重复数据。
3. 每态进入钩子统一入口，退出动作集中在转移入口。

## 四条禁令（grep 验收项）

1. **禁多 bool 组合**模拟状态（如 `is_x and not is_y` 判定状态）——用枚举。
2. **禁字符串状态值**（`state = "battle"`）——用枚举常量。
3. **禁 int 字面量状态**（`match state: 0:`）——用枚举名。
4. **禁状态切换散落多处**——必须走统一转移入口（`_transition` / `_transition_phase`）。

## §8.6 能力上限（超限停手先问）

| 维度 | 上限 | 超限动作 |
|---|---|---|
| 单机状态数（枚举值数） | ≤ 8 | 停手，先问（拆状态机或合并正交维度） |
| 状态转移条件（_transition 内分支） | ≤ 10 | 停手，先问（抽转移矩阵或拆分） |
| 状态表行数（PHASE_TABLE 条目） | ≤ 20 | 停手，先问（拆表或数据化） |

> 超限不自行扩——先记录问题并询问，防状态机膨胀回屎山。

## 其他代码风格基线（沿用既有约定）

- GDScript 缩进 = Tab；类型标注优先（`var x: int` 而非 `var x`）。
- 信号命名 = 过去式（`state_changed` / `died`）；布尔属性命名 = 疑问/状态式（`is_alive`）。
- 私有成员（`_` 前缀）仅限本脚本访问；跨脚本访问必须走公开接口或信号。
- 数据驱动优先：数值/参数禁硬编码（读 DataLoader / stats.* 表，缺表兜底 = 现状值）。
- 注释中文，关键决策注明来源（用户拍板日期 / T 编号 / F 系列编号）。
