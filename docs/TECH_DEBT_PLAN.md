# 阶段 F：技术债整改方案（Tech Debt Refactor Plan）

- **状态**：待用户拍板（2026-08-10 立项，含 Excel 数据管线需求 08-10 补充）
- **依据**：全量代码审计（2026-08-10，34 脚本 / 7398 行 / 9 张 JSON 数据表）
- **总原则**：暂停新功能开发，优先清债。**逻辑进代码、数值进数据、映射表进数据、行为枚举表驱动**——绝不把行为逻辑塞进数据表（苹果闹钟 Excel 反面教材：数据表不能替代逻辑，只能承载可变内容）
- **编辑层升级（用户拍板方向）**：策划/用户改数统一走 **Excel 工作簿**，代码执行不靠硬编码，运行时统一读 DataLoader 缓存；Excel 同时承担"数据总览"职能

---

## 1. 现状诊断摘要

### 1.1 硬编码（最严重 15 处，详见审计）
| 类型 | 典型案例 | 后果 |
|---|---|---|
| 公式双源 | `data_loader.gd:198` 精英乘数 vs `enemies.json.scaling`（JSON 同值但改 JSON 不生效）| 策划改数无效，文档与逻辑漂移 |
| 公式零消费 | `waves.json.generation` 三公式、`stats.json.formulas` 全项目无调用方 | 数据表形同虚设 |
| 内联配置 | `weapon_controller.gd:50` 初始枪、`skill_controller.gd:118` 火球参数、`turret.gd:13` 炮台默认值 | 不在数据表，无处可改 |
| 机制 id 散落 | `"se_blade_core"`/`"executioner_mark"`/`"last_stand"` 等 4+ 文件各写各的 | 改名即坏，编译器不拦 |
| 表现映射 | `SPRITE_MAP`(26 条)/`BGM_MAP`/`SFX_MAP`/`FX_CONFIG`/`SHEET_CONFIG`/`STAT_MAP`(17 键) | 视觉/音频配置全在代码 |

### 1.2 状态机不规范
- `game_manager.gd`：`current_state=` 散落 **8 处**各自内联副作用，且"局状态"实际 = 枚举 × `route.is_empty()` × `_shop_from_battle` × `is_boss_wave` 四维乘积
- `player.gd`：无状态机，5 个 bool + 字符串动画态（`"attack"/"skill"/"hit"`）
- `enemy.gd`：Behavior 枚举规范，但 Boss 阶段机 = int 下标 + 3 个并行 bool；死亡双标志 `is_alive`+`_is_dying` 冗余
- 类型混乱：GameState 枚举（GM）/ 字符串（route 节点）/ int 字面量（`audio_manager.gd:90`）三套并存

### 1.3 边界违规
- **UI 直读核心字段**：`shop.gd:346` `economy.coins`、`:384` 手动回滚库存；`hud.gd:129` 轮询敌人容器；`base_station.gd:141` 直读存档字典
- **跨层节点树访问三份复制**：`skill_controller.gd:176` / `turret.gd:147` / `weapon_controller.gd:41` 各自 `get_parent().get_node_or_null("Projectiles")`
- **实体 new 实体**：`enemy.gd:735` / `weapon_controller.gd:376` / `skill_controller.gd:180` 直接实例化
- **上帝脚本**：`game_manager.gd` 754 行（状态机+存档+面板工厂+事件系统四合一）、`enemy.gd` 882 行（行为+元素+阶段机+受伤掉落+动画八合一）、`player.gd` 610 行

### 1.4 数据一致性隐患（含 2 个玩家可见 bug）
- **P0-Bug1**：`se_skill_holy_shield`（希亚）已配置且 HUD 图标齐备，但 `skill_controller.gd:73` 无该 id 分支 → 技能不可用
- **P0-Bug2**：`items.json` 39 个 effects 键，`STAT_MAP` 仅映射 17 键 → 部分被动购买后数值静默不生效（如 `se_flame_core`/`se_mech_core`）
- 死数据：`well_rounded` 的 `harvesting` 等键无消费方；`enemy_spawner.gd:126` 补的 `wave_number` 在 `get_scaled_enemy()` 返回值里不存在

---

## 2. 整改边界原则（写进规范的底线）

1. **可变数值/文案/映射 → 数据表（Excel → JSON）**；**行为逻辑/规则结构 → 代码**（枚举+match 表驱动）
2. 每张数据表必须有消费方，否则禁止存在（要么删表，要么接线）
3. 代码中禁止出现业务 id 字面量（武器/敌人/道具/技能），一律经 DataLoader 常量表或枚举引用
4. 状态变更只走统一 transition 入口；状态 = 单一枚举值 + 上下文
5. 引用方向单向：UI → 系统 → 实体；跨层一律信号/查询接口
6. **状态机仅两种形态（写死）**：① 扁平流程态 = `enum + match + _transition()`；② 行为/表现态 = `enum + 状态表 Dictionary`。禁止：多 bool 组合、字符串状态值、int 字面量状态、状态切换散落多处。单机状态 > 8 或出现层级/并发需求 → 触发评审（重新评估是否引入框架，候选 GDQuest state-chart）

---

## 3. 数据管线设计：Excel 编辑层（本次需求新增）

### 3.1 目标
- 策划/用户只碰 **一个 Excel 工作簿**：改数值、改描述、改条件参数，跑一次导出即生效
- 游戏运行时**零硬编码**：所有可变内容经 DataLoader 缓存读取
- Excel 自带"数据总览"能力：随时看全量数据分布（数量/稀有度/数值范围/未消费键）

### 3.2 三层架构（编辑层 / 传输层 / 运行时）

```
[编辑层]  docs/GameData.xlsx（唯一事实源，策划手改）
              │  tools/excel_export.py（校验 + 导出 + 总览）
              ▼
[传输层]  data/*.json（generated，禁手改，git 仍提交）
              │  DataLoader 启动加载（现有代码不动）
              ▼
[运行时]  Godot 游戏逻辑（只读 DataLoader 缓存）
```

- **Excel = 唯一事实源**：改数只改 Excel；JSON 由导出工具生成，标记为 generated（防双源漂移）
- **JSON 格式保持现状**：`excel_export.py` 输出的 JSON 与现在 `data/*.json` 结构完全一致 → DataLoader/现有代码/探针全部零改动，风险最小
- **反向迁移**：现有 9 张 JSON → 一次性导入生成 Excel 模板（保留所有现有字段，含武器 levels、事件 choices、item effects 等嵌套结构）

### 3.3 Excel 工作簿结构（`docs/GameData.xlsx`）

| Sheet | 内容 | 说明 |
|---|---|---|
| `说明` | 编辑规范、列说明、禁忌（不改 JSON、不写逻辑）| 每个列头可加批注 |
| `weapons` | 武器主表（id/名称/价格/基础属性/成长 scaling）| 一行一武器 |
| `weapons_levels` | 武器等级子表（weapon_id × level 1-8 × 数值×升级文案）| 长表，level 列公式自动填充 |
| `items` | 道具主表（id/名称/稀有度/价格/槽位/分类/图标）| |
| `items_effects` | 道具效果子表（item_id × effect_key × value）| 一行一条效果，筛 id 即看全部 |
| `enemies` | 敌人主表 + 成长参数（hp/damage/speed/成长率/行为/掉落）| 与 enemies.json scaling 合并为一张 |
| `characters` | 角色（属性/起始武器/技能/被动/成长）| |
| `waves` | 波次表（第 N 波 × 组成×时长×奖励）+ 生成规则 | 覆盖 waves.json generation/rewards |
| `events` | 事件表（标题/主题/描述/choiceA/B 文案与奖励）| choice 用宽列 + 列内 JSON 兜底 |
| `stats` | 属性定义 + 公式参数（统一护甲/移速/成长公式的系数）| 消灭 stats.json.formulas 零消费 |
| `elements` | 元素状态 + 反应表 | |
| `routes` | 路线参数（层数/权重/约束/BOSS_WAVE）| |
| `presentation` | **新增**：SPRITE_MAP/BEHAVIOR_MAP/BGM/SFX/FX/SHEET_CONFIG/初始枪/炮台默认值 | F1 抽表目标落点 |
| `总览` | 只读：每表行数、稀有度/分类分布、数值 min/max/均值、未消费键、死数据 | 由工具生成，勿手改 |

- **嵌套 JSON 的 Excel 映射规则**：主表一行一实体；数组（levels/choices/effects）拆子表或宽列；`effects` 字典拆 `items_effects` 子表（主表永不出现"效果写在文本里"的情况）

### 3.4 导出工具 `tools/excel_export.py`（openpyxl，Python 3.13 已有）

```
用法：python tools/excel_export.py [--check-only] [--overview]
--check-only 只校验不导出（CI/自动化用）
--overview   只重新生成总览报告
```

功能：
1. **校验**（导出前强制，失败即中断）：
   - 必填列缺失 / id 唯一 / 数字列类型 / 枚举值合法（rarity、category、behavior…）
   - **引用完整性**：起始武器 id 存在、进化核心 id 存在、items_effects 的 effect_key 在 STAT_MAP 全量清单内、event reward type 合法
   - **硬编码回归检测**：扫 scripts/ 是否存在新出现的业务数值/机制 id 字面量（F1 后应清零）
2. **导出**：9+1 张 JSON，格式与现状一致（含 `_category` 注入逻辑不变，仍由 DataLoader 做）
3. **总览**：生成 `docs/DATA_OVERVIEW.md`（自动化 #1 可引用）+ Excel `总览` sheet 刷新
4. **manifest**：导出时写 `data/.manifest.json`（内容指纹），Godot 启动可对比 mtime/指纹——**防"改了 Excel 忘了导出"**

### 3.5 护栏与衔接
- 自动化 `#3 执行` 的 git 护栏中追加：`excel_export.py --check-only`，校验不过禁止提交
- **触发条件边界**：Excel 承载"条件参数"（阈值/概率/权重/关卡号），**触发逻辑仍在代码**（如"第四关星刃保底"的 `current_wave == 4` 会数据化为 `core_grace_wave` 参数进表，但"到达该波触发"的 if 结构留在代码）
- 开发时机：放 F0 之后、F1 之前（约 1-2 天）。理由：F1 高频改数正好用上编辑层；presentation 抽表直接落进 Excel 模板；DataLoader 零改动，可先行交付给策划熟悉

---

## 4. 分阶段执行计划

### F0 基线冻结（0.5-1 天）｜git 收口：`f0-baseline`
**目标：锁定重构前基线，避免整改期间玩法数值漂移**
- [ ] 全量探针回归跑绿，保存结果快照
- [ ] 关键数值快照：伤害/掉率/波次节奏/成长曲线序列化存档（`tools/` 生成 `baseline_numerics.json`）
- [ ] 建立 `docs/TECH_DEBT_ISSUES.md` 单一事实源：审计发现全量登记（编号 T-001…），逐条状态跟踪
- [ ] 顺手修 2 个 P0 bug（不动架构）：希亚技能接线、STAT_MAP 补齐 22 键映射
- 验收：探针全绿；快照落盘；P0 修复回归通过

### F1.0 Excel 数据管线（1-2 天）｜git 收口：`f1-excel-pipeline`
**目标：交付策划编辑层 + 数据总览**
- [ ] `tools/json_to_excel.py`：现有 9 张 JSON 一次性导入生成 `docs/GameData.xlsx`（含说明/总览 sheet）
- [ ] `tools/excel_export.py`：校验 + 导出 + 总览 + manifest（规格见 §3.4）
- [ ] 自动化 #3 接入 `--check-only` 护栏；#1 引用 DATA_OVERVIEW.md
- [ ] 小验证：改 Excel 一个数值 → 导出 → 探针断言游戏内行为变化（"配置生效探针"首个用例）
- 验收：改 Excel → 导出 → 探针生效链路打通；总览报告可用

### F1 数据层统一（2-3 天）｜git 收口：`f1-data-driven`
**目标：消灭"改 Excel/JSON 不生效"**
- [ ] `enemies.json.scaling` 接入 `get_scaled_enemy()`（精英乘数/移速公式/F-01 减速 0.5 全部数据化）
- [ ] `waves.json.generation` 接入 `enemy_spawner`（生成间隔公式）；`max_waves`/`BOSS_WAVE`/`core_grace_wave` 等常量并入数据表
- [ ] `stats.json.formulas` 接入：统一护甲算法（现玩家平直减法 vs 敌人百分比两套并存）
- [ ] 表现映射抽表 → `presentation` sheet（SPRITE_MAP/BEHAVIOR_MAP/FALLBACK_SPRITES/BGM_MAP/SFX_MAP/FX_CONFIG/SHEET_CONFIG/初始枪/炮台默认值）——**保留 .gd 加载时兜底默认值**（缺字段不崩）
- [ ] 机制 id 收敛：`character_select.gd` HERO_IDS 改 DataLoader 全量；道具/技能 id 引用改常量表
- [ ] `data_schema_check.py` 合并进 `excel_export.py` 校验器（键与代码引用一致 + STAT_MAP 全覆盖）
- 验收：代码 grep 不到业务数值/机制 id 字面量；DataLoader 无零消费接口；探针全绿

### F2 代码边界收拢（3-4 天）｜git 收口：`f2-boundaries`
**目标：分层解耦，信号化**
- [ ] GameManager 状态变更发信号 `state_changed(state, context)`；UI 改订阅
- [ ] shop/hud/base_station 直读核心字段 → 查询接口 + 信号回推
- [ ] 跨层容器访问收口：World 服务定位（`world.get_container("projectiles")`），消灭三份复制
- [ ] 实体创建收口：`world.spawn_projectile/spawn_enemy/spawn_turret` 工厂，禁直接 new
- [ ] wave_manager ↔ spawner 互调改信号；系统间私有字段互读清零
- [ ] GameManager 首拆：面板工厂（`UIPanelFactory`）+ 事件系统（`EventManager`）独立成类
- 验收：依赖图无 UI→核心字段直读、无 `get_parent()` 跨层链、无直接 new 实体；探针全绿

### F3 状态机规范化（3-4 天）｜git 收口：`f3-state-machines`
**目标：单一事实状态（自研轻量模式，用户已拍板：状态机仅两种形态）**
- [ ] 制定状态机规范入 `docs/CODE_STYLE.md`：①扁平流程态 = enum+match+`_transition()`；②行为/表现态 = enum+状态表。禁多 bool/字符串状态/int 字面量/散落赋值
- [ ] GameManager：`current_state=` 8 处收口为 1 个 `_transition(next, context)`；正交维度合并进状态上下文
- [ ] enemy：Boss 阶段机 int+bool → 阶段枚举+状态表；删冗余 `_is_dying`
- [ ] player：5 bool + 字符串动画 → `PlayerState` 枚举 + 动画映射表
- [ ] audio_manager：int 字面量改 GameState 枚举引用；route 节点字符串改枚举
- [ ] 新增**状态机合规探针**（并入 excel_export.py 校验器同级）：自动扫描代码——`current_state=` 出现次数 > 预期、字符串状态字面量、新增 bool 标志 → 报警
- [ ] 新增**状态流探针**：固定序列驱动 GM 状态流转，断言序列合法（如 BATTLE→LEVEL_UP→BATTLE 合法、跳波非法）
- 验收：全项目状态切换经统一入口（grep 验证）；无字符串状态；无新增 bool 标志；探针全绿

### F4 上帝脚本拆分（3-5 天）｜git 收口：`f4-modularize`
**目标：最大脚本 < 400 行，职责单一**
- [ ] enemy.gd 882 行 → 拆：移动行为（behavior 表驱动类）/ 元素 DoT 组件 / Boss 阶段机 / 受伤掉落（伤害系统复用）
- [ ] game_manager.gd 754 行 → 事件系统已拆（F2）；再拆存档（`SaveSystem`）+ 金手指 + 面板工厂
- [ ] player.gd 610 行 → 拆：属性系统（`AttributeController`，接 STAT_MAP 全量映射）/ 动画推断
- [ ] 拆完跑数值快照对比：**玩法数值零漂移**
- 验收：所有脚本 < 400 行；依赖图无环；数值快照对比通过

### F5 回归与收口（2 天）｜git 收口：`f5-stabilize`
- [ ] 全量探针 + 真人试玩回归（PLAYTEST #56+）：节奏/数值/手感对比 F0 快照
- [ ] 性能对比（同场景 FPS/内存）
- [ ] 文档收口：`docs/CODE_STYLE.md` + `docs/DATA_DICT_GUIDE.md`（策划改数手册：改哪个 sheet、跑什么命令、看什么校验）
- [ ] 新功能开发恢复门槛：提交前过"配置化评审清单"
- 验收：全绿 + 文档齐备 + 策划可自助改数（改 Excel → 导出 → 校验通过 → 生效）

---

## 5. 防 AI 再犯的护栏（vibe coding 弊端对策）

1. **CODE_STYLE.md 入评审流程**：硬编码禁令（魔法数字/业务 id/状态字符串）列为提交前自检项
2. **扩展 `gdscript-codegen` skill**：AI 生成模板内置「数值必须走 DataLoader / 状态必须走枚举+transition / 跨层必须信号」三禁令
3. **excel_export.py 校验器接入自动化**：`#3 执行` 的 git 护栏里跑，硬编码新增/引用断裂即报警
4. **探针补位**：新增「配置生效探针」（改 Excel/JSON 数值 → 断言游戏内行为变化），从机制上防"数据是文档"
5. 周审：每阶段收口时对照 TECH_DEBT_ISSUES.md 勾销，新欠债必须当场登记

---

## 6. 风险与护栏

| 风险 | 对策 |
|---|---|
| 重构引入数值漂移 | F0 基线快照 + F4 后对比；探针断言关键数值 |
| 表现配置抽表后缺字段崩 | 一律带代码兜底默认值（沿用现有 `get(x, 默认)` 惯例）|
| Excel 嵌套映射出错（levels/effects）| 导入导出双向校验 + 单测；导出后 diff 与旧 JSON |
| 改了 Excel 忘导出 | manifest 指纹 + 自动化护栏强制 --check-only；导出工具校验 JSON 与 Excel 一致性 |
| 用户真实存档损坏 | 存档格式不动（本次不改 SaveSystem 存储结构）；探针白盒重置 meta_progress 惯例保持 |
| 拆分大脚本时行为走样 | 每拆一个跑一次该模块专属探针；禁止一次拆完再验证 |
| 整改期无限延长 | 每阶段硬性 git 收口 + 验收清单；F 总时长上限 ~18 天（含 F1.0） |

---

## 7. 决策记录（2026-08-10 用户拍板）

| # | 决策点 | 结论 |
|---|---|---|
| 1 | 唯一事实源 | ✅ **Excel 唯一编辑入口，JSON 标记 generated 禁手改** |
| 2 | 工具开发时机 | ✅ **F0 之后立即做 F1.0 Excel 管线** |
| 3 | 总览形态 | ✅ **Markdown 报告 + Excel 总览 sheet 双份** |
| 4 | 表现配置抽表 | ✅ **全抽进 presentation sheet** |
| 5 | 状态机实现 | ✅ **自研轻量（两种固定形态），受 §8.6 能力上限清单约束** |
| 6 | 执行节奏 | ✅ F0→F1.0→F1→…→F5 连续做完 |
| 7 | P0 两 bug | ✅ **F0 顺手修**（各约 1 小时，不动架构） |

## 8. 状态机选型论证：自研 vs 引框架（2026-08-10）

### 8.1 框架盘点（先摆事实）
- **Godot 4.3 无内置状态机节点**（内置 StateMachine 4.4 才进主线）——本项目锁定 4.3，引框架只能引第三方
- 第三方活跃候选仅两类：**GDQuest state-chart**（层级/并发状态图，SCXML 风格，维护最活跃）与 **HFSM 类轻插件**（质量参差，个人维护，停更风险高）
- 结论：如果引，唯一严肃选项是 state-chart——但它为**层级+并发状态图**设计

### 8.2 自研理由（按分量排序）
1. **规模不匹配**：本项目全部状态机共 4 个且全部扁平少态——GM 局流程（~6-8 态）、enemy 行为枚举、Boss 阶段机（3-4 态）、player 行为态。state-chart 的层级/并发/正交区域能力**零需求**。为用不到的能力付学习+依赖+迁移成本不划算
2. **引框架 = 新增外部依赖债**：4.3 兼容性风险、个人维护插件停更风险（新屎山的潜在来源）、AI 生成代码对框架 DSL 的错误率显著高于朴素枚举+match、调试心智负担
3. **审计病根是"无约定"不是"缺框架"**：现状问题（8 处散赋、四维正交、int/string 混用）任何方案下都存在，因为项目没有状态写法约定。自研模式 + 硬性规则（§2.6）直接固化约定；框架只是把约定外包给 API，项目自身约定缺失不会自动消失
4. **迁移风险差异**：GM 是全局流程核心，迁到框架需按节点/回调结构重写流程控制；自研原地收口（保留函数结构，只收敛赋值点），风险低一个量级。F2 之后（边界已收拢、信号已铺好）做更安全
5. **可控性**：自研 `_transition()` 内可天然挂探针钩子/断言/状态日志；框架状态流转不透明，探针只能观察外部

### 8.3 防"新屎山"的边界承诺（限制条件）
自研不自动安全，安全来自以下硬条款：
1. **模式锁定**：仅允许 §2.6 两种形态，禁令（多 bool/字符串/int 字面量/散落赋值）写入 CODE_STYLE + **状态机合规探针自动扫描**（F3 交付，并入校验器）
2. **验收硬性**：F3 收口 grep 验证单一入口、无字符串状态、无新增 bool 标志
3. **探针固化**：状态流探针用固定序列断言流转合法性——探针即文档
4. **规模触发线**：单机状态 > 8 或出现层级/并发需求 → 强制评审是否引入 state-chart（届时迁移面仅该处，其余不动）
5. **不混淆范围**：本次只规范现有 4 机；新增状态机必须过同样评审

### 8.4 结论
**自研轻量（两种固定形态）+ 上述五条边界**。若未来敌人 AI 演化出行为树/层级需求，触发线生效，届时定向引入 state-chart——这是"可撤销的自研"，不是"锁死的自研"。

### 8.5 能力验证：固定条件触发 AI（用户质询 08-10，范式已定）
需求：血量低于阈值 → 技能组与优先级变化。**自研第二形态（enum+状态表）教科书场景**：

```gdscript
enum BossPhase { P1_NORMAL, P2_ENRAGED, P3_FINAL }

# 阶段表 = 数据（技能组/权重/间隔可整体迁入 enemies.json.phases → Excel）
const PHASE_TABLE := {
	BossPhase.P1_NORMAL: { "skills": ["spread_shot","charge"],        "weights": [0.7,0.3], "ai_interval": 2.0 },
	BossPhase.P2_ENRAGED: { "skills": ["spread_shot","charge","summon"], "weights": [0.4,0.3,0.3], "ai_interval": 1.2 },
	BossPhase.P3_FINAL:   { "skills": ["spread_shot","barrage"],      "weights": [0.5,0.5], "ai_interval": 0.9 },
}
# 阈值 = 条件参数（可数据化 phase_thresholds: [0.6, 0.3]）
const PHASE_THRESHOLDS := { BossPhase.P2_ENRAGED: 0.6, BossPhase.P3_FINAL: 0.3 }

# 逻辑只剩这一个检查点 + 一个统一入口
func _check_phase_trigger() -> void:
	for phase in [BossPhase.P3_FINAL, BossPhase.P2_ENRAGED]:   # 从高到低
		if _hp_ratio < PHASE_THRESHOLDS[phase]:
			_transition(phase)
			return

func _transition(next: BossPhase) -> void:
	if next == _phase:
		return
	_phase = next
	_ai_timer = PHASE_TABLE[next]["ai_interval"]   # 进入钩子：换技能组节奏
```

要点：
- **技能组/权重/阈值/间隔 = 数据**（状态表内，可整体迁进 enemies.json.phases → Excel）；**"检查+转移" = 逻辑**（约 10 行，留在代码）——完全符合 §2 边界原则
- **优先级变化 = 权重数组**，复用现有 `route_generator._weighted_pick`；enemies.json 已有 `phases` 字段（get_scaled_enemy 透传），数据落点现成
- **正交维度不冲突**：冰冻/眩晕等 debuff 是独立系统（不进状态机），"狂暴+冰冻"同时存在天然成立
- **触发线依然有效**：本需求 3 阶段/2 阈值/每阶段 ≤3 技能，远在能力圈内；状态表 >20 行或转移条件 >10 个、或出现行为树/多步规划需求时，才触发 §8.3④ 评审

### 8.6 能力上限与质疑触发清单（用户拍板 08-10：踩线即停，先问再干）

**任何新 AI/状态类需求，先对照本表；命中「踩线信号」列 → 停止实现，向用户提出疑问并附建议方向，拍板后再动工。**

| # | 维度 | 支持区（直接按 §2.6 实现） | 踩线信号（停下质疑） | 应对动作 |
|---|---|---|---|---|
| 1 | 规模 | 单机 ≤8 状态 / 转移条件 ≤10 / 状态表 ≤20 行 | 超限；或同一状态来源（from）>5 | 先拆成多个独立状态机；仍超限 → 引 state-chart 评审 |
| 2 | 层级 | 分层但独立（GM 流程态 vs 敌人行为态，**不同对象**） | "状态内又有子状态、且受父状态约束"（真嵌套） | 评审引 state-chart（迁移面仅该处） |
| 3 | 并发 | **正交系统承载**：debuff/移动/攻击均为独立系统，不进状态机 | "同时处于两个状态"类表述 | 先拆解：90% 是正交系统 → 不进状态机；确属状态机并发 → 评审 |
| 4 | AI 决策 | 固定条件触发：阈值/事件/优先级权重（§8.5 范式） | 行为树 / 多步规划 / 预判走位 / "评估多个选项后决策" | **超出状态机范畴**（state-chart 也不够）→ 新架构评审：行为树/GOAP/Utility AI |
| 5 | 记忆 | 单层上下文 `_transition(next, context)` | "根据过去 N 次行为做决策" | 加决策历史组件，不改状态机 |
| 6 | 跨对象 | 单对象状态机 + 信号交互 | "多个敌人共享状态 / 协调行动" | 属 spawner/指挥官层职责，非状态机 |
| 7 | 回滚 | 不支持 | "回到之前状态 / 时间回溯类机制" | 快照系统，非状态机 |

**质疑流程（硬性，F3 写入 CODE_STYLE 与拆解模板）**：
1. 新需求先过此表 → 命中踩线信号 → 不实现，回复附「踩线维度 + 建议方向」→ 拍板后再动
2. 不确定是否踩线 → 一律按踩线处理（先问）
3. 未来若真有需求同时命中 #2+#4（层级 + 规划），不再自行扩自研，直接立项架构评审
