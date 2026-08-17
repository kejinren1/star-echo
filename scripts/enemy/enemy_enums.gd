## 敌人共享枚举与常量表（F4-A · 2026-08-14 从 enemy.gd 拆出）
## ⚠️ 独立纯枚举文件（零 Autoload 引用）：enemy.gd 与拆分组件（enemy_movement/enemy_boss）
## 共同引用。组件 preload 本文件在探针 --script 编译期可解析；不可 preload enemy.gd 本体
## （其引用 Autoload 标识符 → 探针编译期 "Identifier not found"，历史坑 enemy_projectile.gd）
extends RefCounted

## 行为枚举
enum Behavior {
	CHASE,       ## 直追玩家
	CHARGE,      ## 冲锋：蓄力后高速冲向玩家
	ZIGZAG,      ## Z 形移动
	RANGED,      ## 远程：保持距离射击
	HEAL,        ## 治疗：治疗附近友军
	SPAWN,       ## 产卵：定期生成小怪
	STATIONARY,  ## 静止：不移动
	AOE_ATTACK,  ## AOE 攻击 (精英)
	SELF_HEAL,   ## 自愈 (精英)
}

## 行为字符串 → 枚举映射
const BEHAVIOR_MAP: Dictionary = {
	"chase": Behavior.CHASE,
	"charge": Behavior.CHARGE,
	"zigzag": Behavior.ZIGZAG,
	"ranged": Behavior.RANGED,
	"heal": Behavior.HEAL,
	"spawn": Behavior.SPAWN,
	"stationary": Behavior.STATIONARY,
	"aoe_attack": Behavior.AOE_ATTACK,
	"self_heal": Behavior.SELF_HEAL,
}

## Boss 阶段枚举（F3-T4 枚举化；PHASE_TABLE 只维护 枚举→phases 索引 映射，
## 行为参数 attacks/speed_multiplier 仍读 enemies.json phases 数据，禁硬编码重复数据）
enum BossPhase { P1, P2, P3 }

const PHASE_TABLE: Dictionary = {
	BossPhase.P1: 0,
	BossPhase.P2: 1,
	BossPhase.P3: 2,
}

# ========== 精灵类型映射（F4-A 从 enemy.gd 迁出：纯常量零 Autoload 引用） ==========
## 敌人 ID → 精灵配置；未命中时按 category 回退: regular→slime, elite→elite, boss→invoker
## D21-22-T1：全敌换皮（slime/skeleton 48px · elite 64px · invoker/predator 128px），
## 各条目带可选 hit_radius（缺省 = 旧公式 frame_size.x*0.5+12.0 零回归）
const SPRITE_MAP: Dictionary = {
	# 普通敌人（PS 2026-08-17 丰富性：皮肤再分配 + tint 色调/scale 体型区分，零新素材）
	"chaser": {"move": "res://assets/sprites/enemies/slime_move.png",   "death": "res://assets/sprites/enemies/slime_death.png",   "size": Vector2i(48, 48), "move_frames": 4, "death_frames": 4, "move_fps": 6.0, "death_fps": 8.0, "hit_radius": 28.0},
	"charger": {"move": "res://assets/sprites/enemies/slime_move.png",   "death": "res://assets/sprites/enemies/slime_death.png",   "size": Vector2i(48, 48), "move_frames": 4, "death_frames": 4, "move_fps": 8.0, "death_fps": 8.0, "hit_radius": 28.0, "tint": Color(0.75, 0.85, 1.35)},
	"fly": {"move": "res://assets/sprites/enemies/slime_move.png",   "death": "res://assets/sprites/enemies/slime_death.png",   "size": Vector2i(48, 48), "move_frames": 4, "death_frames": 4, "move_fps": 8.0, "death_fps": 8.0, "hit_radius": 28.0, "tint": Color(1.4, 1.2, 0.65)},
	"bruiser": {"move": "res://assets/sprites/enemies/slime_move.png",   "death": "res://assets/sprites/enemies/slime_death.png",   "size": Vector2i(48, 48), "move_frames": 4, "death_frames": 4, "move_fps": 5.0, "death_fps": 8.0, "hit_radius": 28.0, "tint": Color(1.2, 0.9, 0.65), "scale": 1.25},
	"spitter": {"move": "res://assets/sprites/enemies/slime_move.png",   "death": "res://assets/sprites/enemies/slime_death.png",   "size": Vector2i(48, 48), "move_frames": 4, "death_frames": 4, "move_fps": 6.0, "death_fps": 8.0, "hit_radius": 28.0, "tint": Color(0.8, 1.1, 1.1)},
	"healer": {"move": "res://assets/sprites/enemies/slime_move.png",   "death": "res://assets/sprites/enemies/slime_death.png",   "size": Vector2i(48, 48), "move_frames": 4, "death_frames": 4, "move_fps": 6.0, "death_fps": 8.0, "hit_radius": 28.0, "tint": Color(1.15, 1.25, 1.05)},
	"spawner": {"move": "res://assets/sprites/enemies/slime_move.png",   "death": "res://assets/sprites/enemies/slime_death.png",   "size": Vector2i(48, 48), "move_frames": 4, "death_frames": 4, "move_fps": 4.0, "death_fps": 8.0, "hit_radius": 28.0, "tint": Color(1.25, 0.8, 1.35)},
	"horned_charger": {"move": "res://assets/sprites/enemies/skeleton_move.png", "death": "res://assets/sprites/enemies/skeleton_death.png", "size": Vector2i(48, 48), "move_frames": 4, "death_frames": 4, "move_fps": 8.0, "death_fps": 8.0, "hit_radius": 28.0, "tint": Color(1.35, 0.8, 0.8)},
	"pursuer": {"move": "res://assets/sprites/enemies/slime_move.png",   "death": "res://assets/sprites/enemies/slime_death.png",   "size": Vector2i(48, 48), "move_frames": 4, "death_frames": 4, "move_fps": 5.0, "death_fps": 8.0, "hit_radius": 28.0, "tint": Color(1.35, 0.7, 1.0)},
	"slasher": {"move": "res://assets/sprites/enemies/skeleton_move.png", "death": "res://assets/sprites/enemies/skeleton_death.png", "size": Vector2i(48, 48), "move_frames": 4, "death_frames": 4, "move_fps": 6.0, "death_fps": 8.0, "hit_radius": 28.0},
	"helmet_alien": {"move": "res://assets/sprites/enemies/skeleton_move.png", "death": "res://assets/sprites/enemies/skeleton_death.png", "size": Vector2i(48, 48), "move_frames": 4, "death_frames": 4, "move_fps": 6.0, "death_fps": 8.0, "hit_radius": 28.0, "tint": Color(0.7, 1.0, 0.8)},
	"horned_fly": {"move": "res://assets/sprites/enemies/skeleton_move.png", "death": "res://assets/sprites/enemies/skeleton_death.png", "size": Vector2i(48, 48), "move_frames": 4, "death_frames": 4, "move_fps": 8.0, "death_fps": 8.0, "hit_radius": 28.0, "tint": Color(1.35, 1.15, 0.6)},
	"corrupted_tree": {"move": "res://assets/sprites/enemies/slime_move.png",   "death": "res://assets/sprites/enemies/slime_death.png",   "size": Vector2i(48, 48), "move_frames": 4, "death_frames": 4, "move_fps": 2.0, "death_fps": 8.0, "hit_radius": 28.0, "tint": Color(0.55, 0.85, 0.5), "scale": 1.4},
	"mad_slasher": {"move": "res://assets/sprites/enemies/skeleton_move.png", "death": "res://assets/sprites/enemies/skeleton_death.png", "size": Vector2i(48, 48), "move_frames": 4, "death_frames": 4, "move_fps": 8.0, "death_fps": 8.0, "hit_radius": 28.0, "tint": Color(1.4, 0.75, 0.75)},
	"lamprey": {"move": "res://assets/sprites/enemies/slime_move.png",   "death": "res://assets/sprites/enemies/slime_death.png",   "size": Vector2i(48, 48), "move_frames": 4, "death_frames": 4, "move_fps": 8.0, "death_fps": 8.0, "hit_radius": 28.0, "tint": Color(0.7, 0.8, 1.2)},
	# 精英敌人 → elite 精灵（64px 4+4，红甲特征色 + tint 微差）
	"butcher": {"move": "res://assets/sprites/enemies/elite_move.png",   "death": "res://assets/sprites/enemies/elite_death.png",   "size": Vector2i(64, 64), "move_frames": 4, "death_frames": 4, "move_fps": 6.0, "death_fps": 8.0, "hit_radius": 36.0},
	"colossus": {"move": "res://assets/sprites/enemies/elite_move.png",   "death": "res://assets/sprites/enemies/elite_death.png",   "size": Vector2i(64, 64), "move_frames": 4, "death_frames": 4, "move_fps": 5.0, "death_fps": 8.0, "hit_radius": 36.0, "tint": Color(1.2, 1.05, 0.8), "scale": 1.15},
	"rhino": {"move": "res://assets/sprites/enemies/elite_move.png",   "death": "res://assets/sprites/enemies/elite_death.png",   "size": Vector2i(64, 64), "move_frames": 4, "death_frames": 4, "move_fps": 6.0, "death_fps": 8.0, "hit_radius": 36.0, "tint": Color(1.1, 0.85, 0.9)},
	"monk": {"move": "res://assets/sprites/enemies/elite_move.png",   "death": "res://assets/sprites/enemies/elite_death.png",   "size": Vector2i(64, 64), "move_frames": 4, "death_frames": 4, "move_fps": 6.0, "death_fps": 8.0, "hit_radius": 36.0, "tint": Color(0.85, 1.05, 0.9)},
	"croc": {"move": "res://assets/sprites/enemies/elite_move.png",   "death": "res://assets/sprites/enemies/elite_death.png",   "size": Vector2i(64, 64), "move_frames": 4, "death_frames": 4, "move_fps": 7.0, "death_fps": 8.0, "hit_radius": 36.0, "tint": Color(0.9, 1.15, 0.75)},
	"mom": {"move": "res://assets/sprites/enemies/elite_move.png",   "death": "res://assets/sprites/enemies/elite_death.png",   "size": Vector2i(64, 64), "move_frames": 4, "death_frames": 4, "move_fps": 5.0, "death_fps": 8.0, "hit_radius": 36.0, "tint": Color(1.1, 0.8, 1.1)},
	# Boss → 专属精灵（128px 4+4；D17：scale 复位 ×1）
	"invoker":          {"move": "res://assets/sprites/enemies/invoker_move.png",   "death": "res://assets/sprites/enemies/invoker_death.png",   "size": Vector2i(128, 128), "move_frames": 4, "death_frames": 4, "move_fps": 6.0, "death_fps": 8.0, "hit_radius": 56.0},
	"predator":         {"move": "res://assets/sprites/enemies/predator_move.png", "death": "res://assets/sprites/enemies/predator_death.png", "size": Vector2i(128, 128), "move_frames": 4, "death_frames": 4, "move_fps": 6.0, "death_fps": 8.0, "hit_radius": 56.0},
}

## 分类回退精灵: regular→slime, elite→elite, boss→invoker（D21-22-T1：同步换皮 + hit_radius）
const FALLBACK_SPRITES: Dictionary = {
	"regular": {"move": "res://assets/sprites/enemies/slime_move.png",   "death": "res://assets/sprites/enemies/slime_death.png",   "size": Vector2i(48, 48), "move_frames": 4, "death_frames": 4, "move_fps": 6.0, "death_fps": 8.0, "hit_radius": 28.0},
	"elite":   {"move": "res://assets/sprites/enemies/elite_move.png",   "death": "res://assets/sprites/enemies/elite_death.png",   "size": Vector2i(64, 64), "move_frames": 4, "death_frames": 4, "move_fps": 6.0, "death_fps": 8.0, "hit_radius": 36.0},
	"boss":    {"move": "res://assets/sprites/enemies/invoker_move.png", "death": "res://assets/sprites/enemies/invoker_death.png", "size": Vector2i(128, 128), "move_frames": 4, "death_frames": 4, "move_fps": 6.0, "death_fps": 8.0, "hit_radius": 56.0},
}
