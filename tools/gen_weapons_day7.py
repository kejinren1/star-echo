#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Day 7–10 数据工具：weapons.json levels 补全 + icon_index 补全 + 结果武器插入（幂等，可重复运行）。

对应 docs/TASKS.md：
  · D7-T1【W2】11 把通用武器补 `levels` 8 条 + `max_level: 8`
  · D7-T5【W2】33 把全部补 `icon_index`（分类内顺序索引 melee 0-7 / ranged 8-16 / elemental 17-25 / engineering 26-32）
  · D8-T1【W2】18 把全量武器补 `levels` 8 条 + `max_level: 8`（fist/stick/dagger/hammer/flaming_knuckles/
    slingshot/crossbow/rocket_launcher/minigun/lightning_shiv/venom_staff/storm_staff/frost_nova/
    plasma_cannon/wrench/laser_turret/mech_arm/force_field）→ 33/33 全量齐
  · D10-T1【W2】3 把结果武器插入（se_star_fall / se_turret_array / se_blade_storm，evolution_result 标记 +
    平曲线 levels 8 条 + icon_index 33/34/35）→ 36/36 全量齐（33 既有 + 3 结果）

定案要点（与 TASKS D7/D8-9 定案表一致）：
  · levels 字段集 = {level, damage, cooldown, range, projectiles?, upgrade}（绝对状态值）
  · Lv1 条与顶层字段完全一致（防首装偏差）
  · damage 逐级 ×1.18–1.32（t1 轻快型 ×1.25 附近 / t3-4 重击型 ×1.22 附近控 DPS）；cooldown 每 2 级 −5–8%；
    range 每 2-3 级 +3–6% 取整；projectiles 特定级 +1
  · 特例 force_field（t3 engineering）：顶层 damage:0（护盾无伤害）→ levels damage 恒 0，只升 cd(2.0→1.5) 与 rng(120→160)
  · 4 把签名武器（se_star_flame / se_auto_turret / se_star_blade / se_holy_staff）只核验不改
  · 不改顶层 damage/cooldown/range/scaling/special（商店/首装口径保持）

用法：
    python tools/gen_weapons_day7.py apply   # 写入 weapons.json
    python tools/gen_weapons_day7.py verify  # 只校验不写入（exit 0 = 通过）
"""

import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
W_PATH = os.path.join(ROOT, "data", "weapons.json")

# ---- 11 把通用武器 levels（8 条，绝对状态值；Lv1 与顶层字段一致） ----
LEVELS = {
    "sword": {
        "dmg": [12, 15, 19, 23, 28, 34, 41, 50],
        "cd": [0.50, 0.50, 0.47, 0.47, 0.44, 0.44, 0.40, 0.36],
        "rng": [180, 185, 190, 196, 202, 208, 214, 220],
        "up": ["基础形态", "伤害 +3", "攻速提升", "伤害 +4", "攻速提升, 射程扩展", "伤害 +6", "伤害 +7, 攻速提升", "满级: 劈砍范围最大化"],
    },
    "chainsaw": {
        "dmg": [8, 10, 12, 15, 18, 22, 27, 33],
        "cd": [0.10, 0.10, 0.095, 0.095, 0.09, 0.09, 0.085, 0.08],
        "rng": [150, 154, 158, 162, 166, 170, 175, 180],
        "up": ["基础形态", "伤害 +2", "攻速提升", "伤害 +3", "攻速提升", "伤害 +4", "伤害 +5, 攻速提升", "满级: 电锯切割最大化"],
    },
    "pistol": {
        "dmg": [5, 6, 8, 10, 12, 15, 18, 22],
        "cd": [0.45, 0.45, 0.42, 0.42, 0.39, 0.39, 0.36, 0.33],
        "rng": [250, 258, 266, 274, 282, 290, 298, 308],
        "up": ["基础形态", "伤害 +1", "攻速提升", "伤害 +2", "伤害 +2, 攻速提升", "伤害 +3", "伤害 +3, 攻速提升", "满级: 穿透强化"],
    },
    "smg": {
        "dmg": [3, 4, 5, 6, 8, 10, 12, 15],
        "cd": [0.12, 0.12, 0.11, 0.11, 0.10, 0.10, 0.09, 0.085],
        "rng": [240, 247, 254, 261, 268, 275, 282, 290],
        "up": ["基础形态", "伤害 +1", "攻速提升", "伤害 +1", "伤害 +2, 攻速提升", "伤害 +2", "伤害 +2, 攻速提升", "满级: 极限射速"],
    },
    "shotgun": {
        "dmg": [4, 5, 6, 8, 10, 12, 15, 18],
        "cd": [0.80, 0.80, 0.75, 0.75, 0.70, 0.70, 0.65, 0.60],
        "rng": [180, 185, 190, 195, 200, 205, 210, 218],
        "proj": [5, 5, 6, 6, 6, 7, 7, 8],
        "up": ["基础形态", "伤害 +1", "弹丸数 +1", "伤害 +2", "伤害 +2, 攻速提升", "弹丸数 +1", "伤害 +3, 攻速提升", "满级: 弹幕最大化"],
    },
    "sniper": {
        "dmg": [40, 50, 62, 76, 92, 110, 132, 158],
        "cd": [1.50, 1.50, 1.42, 1.42, 1.34, 1.34, 1.26, 1.18],
        "rng": [400, 410, 420, 430, 440, 450, 462, 475],
        "up": ["基础形态", "伤害 +10", "攻速提升", "伤害 +14", "伤害 +16, 攻速提升", "伤害 +18", "伤害 +22, 攻速提升", "满级: 致命一击"],
    },
    "wand": {
        "dmg": [3, 4, 5, 6, 8, 10, 12, 15],
        "cd": [0.40, 0.40, 0.37, 0.37, 0.35, 0.35, 0.32, 0.30],
        "rng": [240, 248, 256, 264, 272, 280, 288, 298],
        "up": ["基础形态", "伤害 +1", "攻速提升", "伤害 +1", "伤害 +2, 攻速提升", "伤害 +2", "伤害 +2, 攻速提升", "满级: 燃烧强化"],
    },
    "icicle": {
        "dmg": [5, 6, 8, 10, 12, 15, 18, 22],
        "cd": [0.50, 0.50, 0.47, 0.47, 0.44, 0.44, 0.41, 0.38],
        "rng": [250, 258, 266, 274, 282, 290, 298, 308],
        "up": ["基础形态", "伤害 +1", "攻速提升", "伤害 +2", "伤害 +2, 攻速提升", "伤害 +3", "伤害 +3, 攻速提升", "满级: 减速强化"],
    },
    "flamethrower": {
        "dmg": [2, 3, 4, 5, 6, 7, 8, 10],
        "cd": [0.05, 0.05, 0.048, 0.048, 0.045, 0.045, 0.042, 0.04],
        "rng": [160, 165, 170, 175, 180, 185, 190, 198],
        "up": ["基础形态", "伤害 +1", "攻速提升", "伤害 +1", "伤害 +1, 攻速提升", "伤害 +1", "伤害 +1, 攻速提升", "满级: 持续喷焰"],
    },
    "turret": {
        "dmg": [4, 5, 6, 8, 10, 12, 15, 18],
        "cd": [0.50, 0.50, 0.47, 0.47, 0.44, 0.44, 0.40, 0.37],
        "rng": [200, 206, 212, 218, 224, 230, 238, 246],
        "up": ["基础形态", "伤害 +1", "攻速提升", "伤害 +2", "伤害 +2, 攻速提升", "伤害 +2", "伤害 +3, 攻速提升", "满级: 炮台火力最大化"],
    },
    "landmine": {
        "dmg": [20, 25, 31, 38, 46, 56, 67, 80],
        "cd": [1.00, 1.00, 0.94, 0.94, 0.88, 0.88, 0.82, 0.76],
        "rng": [100, 103, 106, 109, 112, 115, 119, 124],
        "up": ["基础形态", "伤害 +5", "攻速提升", "伤害 +7", "伤害 +8, 攻速提升", "伤害 +10", "伤害 +11, 攻速提升", "满级: 爆炸范围最大化"],
    },
    # ============ D8-T1：18 把全量武器（Lv1 与顶层一致，damage 单调不减 / cooldown 单调不增） ============
    # melee 5（t1 轻快型 ×1.25 附近 / t3 重击型 ×1.22 附近控 DPS）
    "fist": {
        "dmg": [3, 4, 5, 6, 8, 10, 12, 14],
        "cd": [0.30, 0.30, 0.28, 0.28, 0.26, 0.26, 0.24, 0.22],
        "rng": [120, 124, 128, 132, 136, 140, 145, 150],
        "up": ["基础形态", "伤害 +1", "攻速提升", "伤害 +1", "伤害 +2, 攻速提升", "伤害 +2", "伤害 +2, 攻速提升", "满级: 极致连打"],
    },
    "stick": {
        "dmg": [6, 8, 10, 12, 15, 19, 23, 28],
        "cd": [0.55, 0.55, 0.52, 0.52, 0.49, 0.49, 0.45, 0.41],
        "rng": [160, 166, 172, 178, 184, 190, 195, 200],
        "up": ["基础形态", "伤害 +2", "攻速提升", "伤害 +2", "伤害 +3, 攻速提升", "伤害 +4", "伤害 +4, 攻速提升", "满级: 强力击退"],
    },
    "dagger": {
        "dmg": [4, 5, 6, 8, 10, 12, 15, 19],
        "cd": [0.25, 0.25, 0.23, 0.23, 0.22, 0.22, 0.20, 0.19],
        "rng": [130, 134, 138, 142, 146, 150, 155, 160],
        "up": ["基础形态", "伤害 +1", "攻速提升", "伤害 +2", "伤害 +2, 攻速提升", "伤害 +2", "伤害 +3, 攻速提升", "满级: 暴击强化"],
    },
    "hammer": {
        "dmg": [30, 37, 45, 55, 68, 84, 105, 140],
        "cd": [1.20, 1.20, 1.13, 1.13, 1.06, 1.06, 0.98, 0.90],
        "rng": [200, 207, 214, 221, 228, 235, 243, 250],
        "up": ["基础形态", "伤害 +7", "攻速提升", "伤害 +10", "伤害 +13, 攻速提升", "伤害 +16", "伤害 +21, 攻速提升", "满级: 范围重击"],
    },
    "flaming_knuckles": {
        "dmg": [10, 12, 15, 19, 23, 28, 36, 47],
        "cd": [0.30, 0.30, 0.28, 0.28, 0.26, 0.26, 0.24, 0.22],
        "rng": [130, 134, 138, 142, 146, 150, 155, 160],
        "up": ["基础形态", "伤害 +2", "攻速提升", "伤害 +4", "伤害 +4, 攻速提升", "伤害 +5", "伤害 +8, 攻速提升", "满级: 烈焰连打"],
    },
    # ranged 4
    "slingshot": {
        "dmg": [4, 5, 6, 8, 10, 12, 15, 19],
        "cd": [0.35, 0.35, 0.33, 0.33, 0.31, 0.31, 0.28, 0.26],
        "rng": [220, 227, 234, 241, 248, 255, 262, 270],
        "up": ["基础形态", "伤害 +1", "攻速提升", "伤害 +2", "伤害 +2, 攻速提升", "伤害 +2", "伤害 +3, 攻速提升", "满级: 弹射强化"],
    },
    "crossbow": {
        "dmg": [15, 18, 22, 27, 33, 41, 52, 70],
        "cd": [0.90, 0.90, 0.85, 0.85, 0.80, 0.80, 0.74, 0.68],
        "rng": [300, 310, 320, 330, 340, 350, 360, 370],
        "up": ["基础形态", "伤害 +3", "攻速提升", "伤害 +5", "伤害 +6, 攻速提升", "伤害 +8", "伤害 +11, 攻速提升", "满级: 强力穿透"],
    },
    "rocket_launcher": {
        "dmg": [25, 31, 38, 47, 58, 72, 90, 117],
        "cd": [1.20, 1.20, 1.13, 1.13, 1.06, 1.06, 0.98, 0.90],
        "rng": [280, 289, 298, 307, 316, 325, 333, 340],
        "up": ["基础形态", "伤害 +6", "攻速提升", "伤害 +9", "伤害 +11, 攻速提升", "伤害 +14", "伤害 +18, 攻速提升", "满级: 爆裂弹幕"],
    },
    "minigun": {
        "dmg": [4, 5, 6, 8, 10, 12, 15, 19],
        "cd": [0.08, 0.08, 0.076, 0.076, 0.07, 0.07, 0.062, 0.055],
        "rng": [260, 267, 274, 281, 288, 295, 302, 310],
        "up": ["基础形态", "伤害 +1", "攻速提升", "伤害 +2", "伤害 +2, 攻速提升", "伤害 +2", "伤害 +3, 攻速提升", "满级: 极限射速"],
    },
    # elemental 5
    "lightning_shiv": {
        "dmg": [6, 8, 10, 12, 15, 19, 23, 28],
        "cd": [0.35, 0.35, 0.33, 0.33, 0.31, 0.31, 0.28, 0.26],
        "rng": [220, 227, 234, 241, 248, 255, 262, 270],
        "up": ["基础形态", "伤害 +2", "攻速提升", "伤害 +2", "伤害 +3, 攻速提升", "伤害 +4", "伤害 +4, 攻速提升", "满级: 连锁强化"],
    },
    "venom_staff": {
        "dmg": [4, 5, 6, 8, 10, 12, 15, 19],
        "cd": [0.60, 0.60, 0.57, 0.57, 0.53, 0.53, 0.49, 0.45],
        "rng": [200, 207, 214, 221, 228, 235, 243, 250],
        "up": ["基础形态", "伤害 +1", "攻速提升", "伤害 +2", "伤害 +2, 攻速提升", "伤害 +2", "伤害 +3, 攻速提升", "满级: 剧毒强化"],
    },
    "storm_staff": {
        "dmg": [12, 15, 19, 23, 28, 35, 44, 56],
        "cd": [0.80, 0.80, 0.75, 0.75, 0.70, 0.70, 0.65, 0.60],
        "rng": [300, 310, 320, 330, 340, 350, 360, 370],
        "up": ["基础形态", "伤害 +3", "攻速提升", "伤害 +4", "伤害 +5, 攻速提升", "伤害 +7", "伤害 +9, 攻速提升", "满级: 风暴范围最大化"],
    },
    "frost_nova": {
        "dmg": [8, 10, 12, 15, 19, 23, 28, 37],
        "cd": [1.00, 1.00, 0.95, 0.95, 0.89, 0.89, 0.82, 0.76],
        "rng": [180, 186, 192, 198, 204, 210, 215, 220],
        "up": ["基础形态", "伤害 +2", "攻速提升", "伤害 +3", "伤害 +4, 攻速提升", "伤害 +4", "伤害 +5, 攻速提升", "满级: 冻结强化"],
    },
    "plasma_cannon": {
        "dmg": [20, 25, 31, 38, 47, 58, 72, 94],
        "cd": [1.00, 1.00, 0.95, 0.95, 0.89, 0.89, 0.82, 0.76],
        "rng": [350, 361, 372, 383, 394, 405, 418, 430],
        "up": ["基础形态", "伤害 +5", "攻速提升", "伤害 +7", "伤害 +9, 攻速提升", "伤害 +11", "伤害 +14, 攻速提升", "满级: 贯穿强化"],
    },
    # engineering 4（wrench/laser_turret/mech_arm 无 crit 字段；force_field damage 恒 0）
    "wrench": {
        "dmg": [8, 10, 12, 15, 19, 23, 28, 37],
        "cd": [0.50, 0.50, 0.47, 0.47, 0.44, 0.44, 0.41, 0.38],
        "rng": [150, 155, 160, 165, 170, 175, 180, 185],
        "up": ["基础形态", "伤害 +2", "攻速提升", "伤害 +3", "伤害 +4, 攻速提升", "伤害 +4", "伤害 +5, 攻速提升", "满级: 修复强化"],
    },
    "laser_turret": {
        "dmg": [3, 4, 5, 6, 8, 10, 12, 14],
        "cd": [0.15, 0.15, 0.14, 0.14, 0.13, 0.13, 0.12, 0.11],
        "rng": [250, 258, 266, 274, 282, 290, 300, 310],
        "up": ["基础形态", "伤害 +1", "攻速提升", "伤害 +1", "伤害 +2, 攻速提升", "伤害 +2", "伤害 +2, 攻速提升", "满级: 激光持续强化"],
    },
    "mech_arm": {
        "dmg": [15, 18, 22, 27, 33, 41, 52, 70],
        "cd": [0.60, 0.60, 0.56, 0.56, 0.52, 0.52, 0.48, 0.45],
        "rng": [180, 186, 192, 198, 204, 210, 217, 225],
        "up": ["基础形态", "伤害 +3", "攻速提升", "伤害 +5", "伤害 +6, 攻速提升", "伤害 +8", "伤害 +11, 攻速提升", "满级: 机械强化"],
    },
    "force_field": {
        "dmg": [0, 0, 0, 0, 0, 0, 0, 0],
        "cd": [2.00, 2.00, 1.90, 1.90, 1.78, 1.78, 1.63, 1.50],
        "rng": [120, 126, 132, 138, 144, 150, 155, 160],
        "up": ["基础形态", "护盾范围扩大", "冷却缩短", "护盾范围扩大", "冷却缩短, 范围扩大", "护盾范围扩大", "冷却缩短, 范围扩大", "满级: 护盾领域最大化"],
    },
    # ============ D10-T1：3 把结果武器（平曲线：8 条全 == 顶层四维，进化即满级） ============
    "se_star_fall": {
        "dmg": [45, 45, 45, 45, 45, 45, 45, 45],
        "cd": [1.20, 1.20, 1.20, 1.20, 1.20, 1.20, 1.20, 1.20],
        "rng": [320, 320, 320, 320, 320, 320, 320, 320],
        "proj": [3, 3, 3, 3, 3, 3, 3, 3],
        "up": ["进化形态", "进化形态", "进化形态", "进化形态", "进化形态", "进化形态", "进化形态", "进化形态（满级）"],
    },
    "se_turret_array": {
        "dmg": [30, 30, 30, 30, 30, 30, 30, 30],
        "cd": [0.50, 0.50, 0.50, 0.50, 0.50, 0.50, 0.50, 0.50],
        "rng": [320, 320, 320, 320, 320, 320, 320, 320],
        "proj": [3, 3, 3, 3, 3, 3, 3, 3],
        "up": ["进化形态", "进化形态", "进化形态", "进化形态", "进化形态", "进化形态", "进化形态", "进化形态（满级）"],
    },
    "se_blade_storm": {
        "dmg": [45, 45, 45, 45, 45, 45, 45, 45],
        "cd": [0.90, 0.90, 0.90, 0.90, 0.90, 0.90, 0.90, 0.90],
        "rng": [150, 150, 150, 150, 150, 150, 150, 150],
        "up": ["进化形态", "进化形态", "进化形态", "进化形态", "进化形态", "进化形态", "进化形态", "进化形态（满级）"],
    },
}

# ---- 36 把 icon_index（分类内顺序索引 + 结果武器 33/34/35，与 weapons.json 数组顺序一致） ----
ICON_INDEX = {
    # melee 0-7
    "fist": 0, "stick": 1, "dagger": 2, "sword": 3, "hammer": 4,
    "chainsaw": 5, "flaming_knuckles": 6, "se_star_blade": 7,
    # ranged 8-16
    "pistol": 8, "slingshot": 9, "crossbow": 10, "smg": 11, "shotgun": 12,
    "sniper": 13, "rocket_launcher": 14, "minigun": 15, "se_holy_staff": 16,
    # elemental 17-25
    "wand": 17, "icicle": 18, "lightning_shiv": 19, "flamethrower": 20,
    "venom_staff": 21, "storm_staff": 22, "frost_nova": 23, "plasma_cannon": 24,
    "se_star_flame": 25,
    # engineering 26-32
    "turret": 26, "landmine": 27, "wrench": 28, "laser_turret": 29,
    "mech_arm": 30, "force_field": 31, "se_auto_turret": 32,
    # 结果武器 33-35（D10-T1，占用原空余帧）
    "se_star_fall": 33, "se_turret_array": 34, "se_blade_storm": 35,
}

# ---- 3 把结果武器顶层定义（D10-T1；levels 平曲线由 LEVELS 表生成；evolution_result 标记） ----
EVO_WEAPONS = {
    "se_star_fall": {
        "cat": "elemental", "name": "炎星陨落", "tier": 4,
        "damage": 45, "cooldown": 1.2, "range": 320, "projectiles": 3,
        "explosion_radius": 90, "element_type": "fire",
        "special": "召唤大型火焰陨石, 命中爆炸 AOE",
    },
    "se_turret_array": {
        "cat": "engineering", "name": "机械炮阵", "tier": 4,
        "damage": 30, "cooldown": 0.5, "range": 320, "projectiles": 3,
        "special": "诺亚机械强化: 炮台常驻不消失并同时部署多台（机制归 Day 13）",
    },
    "se_blade_storm": {
        "cat": "melee", "name": "星刃风暴", "tier": 4,
        "damage": 45, "cooldown": 0.9, "range": 150,
        "blade_count": 6, "orbit_radius": 120, "orbit_speed": 220,
        "special": "环绕刃群强化: 6 刃环绕",
    },
}

# 4 把签名武器（已有 levels，只核验不改）
SIGNATURE = ["se_star_flame", "se_auto_turret", "se_star_blade", "se_holy_staff"]


def build_levels(wid: str, top: dict) -> list:
    """按 LEVELS 表生成 8 条绝对状态值 levels；Lv1 强制与顶层字段一致。"""
    spec = LEVELS[wid]
    rows = []
    for i in range(8):
        row = {"level": i + 1}
        if i == 0:
            row["damage"] = int(top.get("damage", spec["dmg"][0]))
            row["cooldown"] = float(top.get("cooldown", spec["cd"][0]))
            row["range"] = int(top.get("range", spec["rng"][0]))
            if "proj" in spec and top.get("projectiles") is not None:
                row["projectiles"] = int(top.get("projectiles"))
        else:
            row["damage"] = int(spec["dmg"][i])
            row["cooldown"] = float(spec["cd"][i])
            row["range"] = int(spec["rng"][i])
            if "proj" in spec:
                row["projectiles"] = int(spec["proj"][i])
        row["upgrade"] = spec["up"][i]
        rows.append(row)
    return rows


def verify(weapons: dict, errors: list) -> None:
    """数据层校验（D7-T1 / D7-T5 测试点）。"""
    all_w = []
    for cat, arr in weapons.items():
        for w in arr:
            all_w.append((cat, w))

    # 1) 36 把全部有 icon_index 且 0 <= v <= 35（33 既有 + 3 结果武器 33/34/35）
    for cat, w in all_w:
        if "icon_index" not in w:
            errors.append("缺 icon_index: %s" % w.get("id"))
        else:
            v = int(w["icon_index"])
            if not (0 <= v <= 35):
                errors.append("icon_index 越界: %s=%d" % (w.get("id"), v))

    # 1b) 3 把结果武器：evolution_result + star_echo + tier 4 + Lv1 == 顶层（D10-T1）
    for wid, spec in EVO_WEAPONS.items():
        w = next((x[1] for x in all_w if x[1].get("id") == wid), None)
        if w is None:
            errors.append("结果武器缺失: %s" % wid)
            continue
        if not w.get("evolution_result"):
            errors.append("结果武器 %s 缺 evolution_result 标记" % wid)
        if not w.get("star_echo"):
            errors.append("结果武器 %s 缺 star_echo" % wid)
        if int(w.get("tier", 0)) != 4:
            errors.append("结果武器 %s tier 应 4, 实得 %s" % (wid, w.get("tier")))
        lv = w.get("levels", [])
        if len(lv) == 8:
            if float(lv[0].get("damage", -1)) != float(w.get("damage")):
                errors.append("结果武器 %s Lv1.damage != 顶层" % wid)
            if float(lv[-1].get("damage", -1)) != float(w.get("damage")):
                errors.append("结果武器 %s Lv8.damage != 顶层（平曲线破坏）" % wid)
            if int(w.get("icon_index", -1)) not in (33, 34, 35):
                errors.append("结果武器 %s icon_index 应 33/34/35, 实得 %s" % (wid, w.get("icon_index")))
        if wid == "se_blade_storm" and int(w.get("blade_count", 0)) != 6:
            errors.append("se_blade_storm blade_count 应 6, 实得 %s" % w.get("blade_count"))
        if wid == "se_star_fall" and float(w.get("explosion_radius", 0)) != 90:
            errors.append("se_star_fall explosion_radius 应 90, 实得 %s" % w.get("explosion_radius"))

    # 2) 32 把 LEVELS 表武器（11 + 18 + 3 结果）levels 8 条 + max_level >= 8
    for wid in LEVELS.keys():
        w = next((x[1] for x in all_w if x[1].get("id") == wid), None)
        if w is None:
            errors.append("LEVELS 表武器不存在: %s" % wid)
            continue
        lv = w.get("levels", [])
        if len(lv) != 8:
            errors.append("%s levels 应为 8 条, 实得 %d" % (wid, len(lv)))
        if int(w.get("max_level", 0)) < 8:
            errors.append("%s max_level 应 >= 8, 实得 %s" % (wid, w.get("max_level")))

    # 3) 抽查 7 把 Lv1 与顶层一致 + levels 单调性（D7 三把 + D8 三把 + D10 se_star_fall）
    for wid in ["sword", "pistol", "turret", "fist", "rocket_launcher", "force_field", "se_star_fall"]:
        w = next((x[1] for x in all_w if x[1].get("id") == wid), None)
        if w is None:
            continue
        lv = w.get("levels", [])
        if not lv:
            continue
        if float(lv[0].get("damage", -1)) != float(w.get("damage")):
            errors.append("%s Lv1.damage != 顶层 damage" % wid)
        if float(lv[0].get("cooldown", -1)) != float(w.get("cooldown")):
            errors.append("%s Lv1.cooldown != 顶层 cooldown" % wid)
        if float(lv[0].get("range", -1)) != float(w.get("range")):
            errors.append("%s Lv1.range != 顶层 range" % wid)
        prev_d = prev_c = None
        for row in lv:
            d, c = float(row.get("damage", 0)), float(row.get("cooldown", 0))
            if prev_d is not None and d < prev_d:
                errors.append("%s levels.damage 单调递减: Lv%d" % (wid, int(row.get("level"))))
            if prev_c is not None and c > prev_c:
                errors.append("%s levels.cooldown 单调递增: Lv%d" % (wid, int(row.get("level"))))
            prev_d, prev_c = d, c

    # 4) 全量 levels 单调性（damage 不减 / cooldown 不增）
    for wid in LEVELS.keys():
        w = next((x[1] for x in all_w if x[1].get("id") == wid), None)
        if w is None:
            continue
        lv = w.get("levels", [])
        prev_d = prev_c = None
        for row in lv:
            d, c = float(row.get("damage", 0)), float(row.get("cooldown", 0))
            if prev_d is not None and d < prev_d:
                errors.append("%s damage 单调递减 Lv%d" % (wid, int(row.get("level"))))
            if prev_c is not None and c > prev_c:
                errors.append("%s cooldown 单调递增 Lv%d" % (wid, int(row.get("level"))))
            prev_d, prev_c = d, c

    # 5) 签名武器只核验不改（levels 8 条 + Lv1 与顶层一致）
    for wid in SIGNATURE:
        w = next((x[1] for x in all_w if x[1].get("id") == wid), None)
        if w is None:
            errors.append("签名武器缺失: %s" % wid)
            continue
        lv = w.get("levels", [])
        if len(lv) != 8:
            errors.append("签名 %s levels 应 8 条, 实得 %d" % (wid, len(lv)))
        if lv and (float(lv[0].get("damage", -1)) != float(w.get("damage")) or float(lv[0].get("cooldown", -1)) != float(w.get("cooldown"))):
            errors.append("签名 %s Lv1 与顶层不一致" % wid)

    # 5b) 特例 force_field：levels damage 恒 0（护盾无伤害），cd 递减且 Lv8 == 1.5 / rng 递增且 Lv8 == 160
    ff = next((x[1] for x in all_w if x[1].get("id") == "force_field"), None)
    if ff is not None:
        lv = ff.get("levels", [])
        if lv:
            for row in lv:
                if float(row.get("damage", -1)) != 0.0:
                    errors.append("force_field levels damage 应恒 0, Lv%d 实得 %s" % (int(row.get("level")), row.get("damage")))
            if float(lv[-1].get("cooldown", 0)) > 1.5001 or float(lv[-1].get("cooldown", 0)) <= 0:
                errors.append("force_field Lv8 cooldown 应 ~1.5, 实得 %s" % lv[-1].get("cooldown"))
            if float(lv[-1].get("range", 0)) != 160.0:
                errors.append("force_field Lv8 range 应 160, 实得 %s" % lv[-1].get("range"))

    # 6) MVP 15 把 icon_index 互不重复（实绘帧唯一）
    mvp = ["sword", "chainsaw", "se_star_blade", "pistol", "smg", "shotgun",
           "sniper", "se_holy_staff", "wand", "icicle", "flamethrower",
           "se_star_flame", "turret", "landmine", "se_auto_turret"]
    seen = {}
    for wid in mvp:
        w = next((x[1] for x in all_w if x[1].get("id") == wid), None)
        if w is None:
            errors.append("MVP 武器缺失: %s" % wid)
            continue
        v = int(w.get("icon_index", -1))
        if v in seen:
            errors.append("MVP icon_index 重复: %s 与 %s 同为 %d" % (seen[v], wid, v))
        seen[v] = wid


def _ensure_evo_weapons(weapons: dict) -> None:
    """幂等插入 3 把结果武器（已存在则跳过；levels/icon_index 由 apply 主流程补全）。"""
    for wid, spec in EVO_WEAPONS.items():
        exists = any(w.get("id") == wid for arr in weapons.values() for w in arr)
        if exists:
            continue
        entry = {
            "id": wid,
            "name": spec["name"],
            "tier": spec["tier"],
            "damage": spec["damage"],
            "cooldown": spec["cooldown"],
            "range": spec["range"],
            "special": spec["special"],
            "star_echo": True,
            "evolution_result": True,
        }
        for key in ("projectiles", "blade_count", "orbit_radius", "orbit_speed",
                    "explosion_radius", "element_type"):
            if key in spec:
                entry[key] = spec[key]
        weapons[spec["cat"]].append(entry)


def apply() -> int:
    """内存中生成 → 校验 → 通过才写盘（失败不落盘）。"""
    with open(W_PATH, "r", encoding="utf-8") as fh:
        data = json.load(fh)
    weapons = data["weapons"]

    _ensure_evo_weapons(weapons)

    for cat, arr in weapons.items():
        for w in arr:
            wid = w.get("id", "")
            # D7-T5: 36 把全部补 icon_index（幂等：已有且一致则不覆盖）
            if wid in ICON_INDEX:
                w["icon_index"] = ICON_INDEX[wid]
            # D7-T1/D8-T1/D10-T1: 补 levels + max_level（幂等：已有则不重写）
            if wid in LEVELS and "levels" not in w:
                w["levels"] = build_levels(wid, w)
                w["max_level"] = 8

    errors = []
    verify(weapons, errors)
    if errors:
        for e in errors:
            print("  ERROR  %s" % e)
        return 1

    with open(W_PATH, "w", encoding="utf-8") as fh:
        json.dump(data, fh, ensure_ascii=False, indent=2)
        fh.write("\n")
    print("weapons.json 已更新: 36 把 levels 8 条 + icon_index 全量, 校验通过")
    return 0


def main() -> int:
    cmd = sys.argv[1] if len(sys.argv) > 1 else "verify"
    if cmd == "verify":
        with open(W_PATH, "r", encoding="utf-8") as fh:
            data = json.load(fh)
        weapons = data["weapons"]
        errors = []
        verify(weapons, errors)
        if errors:
            for e in errors:
                print("  ERROR  %s" % e)
            return 1
        print("DAY7 WEAPONS JSON VERIFY CLEAN")
        return 0
    if cmd == "apply":
        return apply()
    print("用法: python tools/gen_weapons_day7.py [apply|verify]")
    return 2


if __name__ == "__main__":
    sys.exit(main())
