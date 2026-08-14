## 玩家共享枚举与常量表（F4-C · 2026-08-14 从 player.gd 拆出）
## ⚠️ 独立纯枚举文件（零 Autoload 引用）：player.gd 与拆分组件（attribute_controller/
## player_anim）共同引用。组件 preload 本文件在探针 --script 编译期可解析；不可 preload
## player.gd 本体（其引用 Autoload 标识符 → 探针编译期 "Identifier not found"，enemy 同坑）
extends RefCounted

## 行为态枚举（F3-T6 · T-034 · per CODE_STYLE §2.6 形态 A）——
## _transition_state 统一入口；_is_walking 布尔归并。保留项（不进状态机）：
## _last_stand_active（F-13 机制标志）/ _facing_left（F-33 朝向）
enum PlayerState { IDLE, WALK, ATTACK, SKILL, HIT, DEAD }

const ANIM_MAP := {
	PlayerState.ATTACK: "attack",
	PlayerState.SKILL: "skill",
	PlayerState.HIT: "hit",
	PlayerState.WALK: "walk",
	PlayerState.IDLE: "idle",
}
