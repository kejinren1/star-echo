# 数据分布总览（DATA_OVERVIEW）

- 生成时间：2026-08-10 00:56
- 来源：docs/GameData.xlsx（tools/excel_export.py 导出时自动刷新）

## weapons（36 行）
- 分类分布：{'melee': 9, 'ranged': 9, 'elemental': 10, 'engineering': 8}
- 等级条目：288（36 把 × 8 级）
- 基础 damage：min 0.0 / max 45.0 / 均值 11.9
- 基础 cooldown：min 0.05 / max 2.0 / 均值 0.6
- 基础 range：min 100.0 / max 400.0 / 均值 214.4

## items（54 行）
- 稀有度分布：{'common': 15, 'uncommon': 12, 'rare': 12, 'legendary': 13, 'epic': 2}
- 效果键 Top（共 39 种）：damage_percent×14, max_hp×8, attack_speed_percent×7, armor×7, speed_percent×7, dodge_percent×6, elemental_damage×6, melee_damage×6
- price：min 0.0 / max 120.0 / 均值 57.2

## enemies（23 行）
- 分类分布：{'regular': 15, 'elite': 6, 'boss': 2}

## characters（10 行）
- 起始武器 10 把：pistol, fist, slingshot, wand, turret, dagger, se_star_flame, se_auto_turret, se_star_blade, se_holy_staff

## waves（20 行）
- 波次范围：1 – 20

## events（10 行）

## stats（20 行）

## elements（5 行）

## element_reactions（10 行）

## routes（1 行）

## 关注项
- 无消费方效果键 23 个（T-050，待 F1 逐键裁决）：attack_speed_per_different_weapon_percent, auto_turret_per_wave, boss_elite_damage_percent, burn_duration_percent, damage_reduction_on_hit_percent, dodge_heal_amount, dodge_heal_chance, element_duration_percent, element_reaction_damage_percent, engineering, fire_damage_percent, harvesting, knockback, melee_damage, miss_chance_percent, no_weapon_armor_bonus, range, ranged_damage, reaction_heal, shop_weapon_upgrade, special_enemies_next_wave, structure_duration_percent, xp_gain_percent
