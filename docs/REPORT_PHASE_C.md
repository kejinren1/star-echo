# 《星骸回响》阶段 C 收口报告（REPORT_PHASE_C）

> 阶段 C：肉鸽系统（随机节点地图 → 事件 → 精英 → Boss → 遗物收口）
> 收口日：2026-08-07（第 27 轮执行窗口 · #3 执行者）
> 收口提交：`b9f815a`（T-D 批次D）前序 `494f18e`/`54fd498`/`0ba7c7f`；阶段 C 全量实现自 `fa077e0`（D14-15）起
> 验证基线：**十七件套 452 断言全绿 + baseline BASELINE CLEAN + weapons verify 36/36**

---

## §1 阶段 C 七日回顾（2026-08-06 15:1x → 2026-08-07 18:0x）

| 开发日 | 内容 | 收口 commit | 探针 |
|---|---|---|---|
| Day 14-15 | 随机节点地图（层式分支拓扑 + RNG 实例种子 + 路线选择面板 + **DataLoader wave 键修复**） | `fa077e0` | day14_15 54/54 |
| Day 16 | 事件节点（弹窗 UI + 10 奖励型 + 5 改线型 + resonant_shard 补齐） | `748d2b7` | day16 41/41 |
| Day 17 | 精英战斗（3 ability 数据化 + enemy 三行为 + **BUG-003 mixed 池解析收口** + difficulty_delta） | `2abba3c` | day17 39/39 |
| Day 17-P0 | 用户拍板四件套（F-01 移速×0.5 / F-02 碰撞层分离 / F-04 金手指 / F-15 围杀根因） | `6e84751`/`1bc0255` | day17_p0 20/20 |
| Day 18-19 | Boss 多阶段（phases 状态机 + 8 型 attacks 指令 + enemy_projectile 弹幕 + 击杀登记） | `d3b95a0`/`afe5ef7`/`740cb9e`/`2d8bdd2` | day18_19 48/48 |
| Day 20 | 遗物系统（2 遗物 + 2 新装配键 + MAX_RELICS=2 + 商店第三池 + 22 帧图标）+ **T-D 技能图标** | `494f18e`/`54fd498`/`0ba7c7f`/`b9f815a` | day20 23/23 |

## §2 各系统集成结论

- **随机节点地图**：`route_generator.gd` 纯 RNG 实例（禁全局 RNG 洗牌），routes.json 5 层×3 节点默认种子 20260806；GameManager 路线模式与旧波次制双轨（route 空=旧制，回归零破坏）；改线 5 型（reroute/flag/unlock_node/add_node/difficulty）由事件节点驱动。
- **事件节点**：暂停式弹窗 + 10 奖励型分派（含 attack_percent→damage 代码层别名）+ 5 改线型；`_event_rng` 实例种子防 flaky；resonant_shard 事件专属（price=0 天然不入商店池）。
- **精英战斗**：3 精英 ability 数据驱动（butcher aoe / monk self_heal / mom spawn）；mixed 池令牌解析收口（wave 15/17/19 此前静默不生成，现全量生成）；difficulty_delta ±10%/档。
- **Boss 多阶段**：phases 状态机（take_damage 存活命中阈值切换 + scale×2 视觉过渡 + 阶段横幅）；attacks 8 型指令纯函数解析（summon/spread/barrage/aoe/charge/mult，未知指令 push_warning 不崩）；`enemy_projectile.gd` 纯 Node2D 距离判定禁物理查询；boss_killed/register_boss_killed + route.flags 登记。
- **遗物系统**：2 遗物（破碎王冠 damage+50% / 受伤×1.3，机械引擎 structure×2.0）slot="relic" 直装不占被动槽（MAX_RELICS=2 独立上限，6 被动 + 2 遗物共存）；商店第三池 53→55；items.png 22 帧 + icon_atlas 同步。
- **T-D 技能图标（P0 硬性时限）**：skills.png 4 帧（fireball/deploy_turret/blade_burst/holy_shield）+ hud 按 skill_data.id 映射接线，无图降级零回归。**08-08 时限前一日完成**。

## §3 平衡对照

- **F-01 移速×0.5 后曲线**：全敌基础移速减半（data_loader final_speed ×0.5），冲锋类 charger/horned_charger 冲速 1062→531；配合 F-02 碰撞层分离（玩家穿过怪物不围杀），「波次上限前围杀致死」三因（真实波次上线 + 高移速 + 碰撞阻挡）已全部机器侧解除。
- **遗物叠加边界**：damage_percent 为乘算链（percent 模式乘算、remove 除法还原）；破碎王冠 +50% 与被动/角色被动 damage 加成乘算叠乘（如 +50% 被动 + 破碎王冠 = ×1.5×1.5=×2.25）；受伤倍率 damage_taken_mult 在 armor 平直减伤**之后**乘（armor=20 受 100 → max(80,1)×1.3=104），与金手指 ×0.001 兜底顺序固定（先遗物后金手指）。
- **DPS 参照（Day 10 决策延续）**：minigun Lv8≈345 > flamethrower≈250 > hammer≈155 ≈ rocket_launcher≈130；遗物不直接给 DPS 平铺数值，走百分比乘算放大链，Build 质变感知交 #5 真人回归。

## §4 遗留事项（不阻塞收口）

| 项 | 状态 | 归口 |
|---|---|---|
| R4 攻击力口径（passive damage vs 武器面板） | [!] 待 Owner 拍板 | Day 21-22 F 系列 |
| 森林区域解锁（events.json flag 深消费） | 登记 | Day 27 |
| 遗物 HUD 槽（当前遗物不显示独立槽位） | P1 顺延 | Day 23+ |
| mech_heart 入池（price 105 悬空不入任何池） | 登记可选 | P1 |
| 进化选项加权/必出（满级+持核心可能刷不出进化） | 待决策 | Day 13 遗留 |
| Boss「腐化巨树藤蔓/毒雨」vs 数据 invoker/predator 差异 | 以数据为准已登记 | 不臆造指令 |

## §5 主观项登记（交 #5 试玩反馈收集）

- 遗物平衡体感：破碎王冠 30% 受伤惩罚 vs 50% 输出是否划算（风险/收益曲线）
- Build 质变感知：遗物叠加后伤害数字跳变是否明显、是否有趣
- 阶段 C 整体流程：路线选择→事件→精英→Boss 的节奏、信息密度、难度曲线
- T-D 技能图标辨识度：4 图标与角色/技能语义匹配度
