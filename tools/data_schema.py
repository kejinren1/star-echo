#!/usr/bin/env python3
"""数据管线共享 schema：Excel 表结构 ↔ JSON 结构的双向映射规则（单一事实源）。

设计约定（docs/TECH_DEBT_PLAN.md §3.3）：
- 主表一行一实体；列 = 该表数据键并集（自动发现，数据加键工具自动跟随）
- 一层 dict → 点号宽列（如 scaling.melee_damage、skill.effects.shield）
- 高频修改的 list → 子表（weapons.levels → weapons_levels；items.effects → items_effects；
  characters.passive/penalty → characters_passives/penalties）
- 低频/结构复杂的嵌套 → JSON 文本列（weapons.evolution 等、waves.composition/special、
  enemies.phases）
- 分类数组外层（weapons/enemies/stats 的 category 分组）→ 辅助列 _xlsx_category
  （导入时填写、导出时用于归组后剔除，DataLoader 侧自行注入 _category）

用法：json_to_excel.py / excel_export.py 均 import 本模块。
"""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = ROOT / "data"
XLSX_PATH = ROOT / "docs" / "GameData.xlsx"
MANIFEST_PATH = DATA_DIR / ".manifest.json"
OVERVIEW_PATH = ROOT / "docs" / "DATA_OVERVIEW.md"

# ========== 双行表头约定（F1.0 增强 2026-08-10） ==========
# 每张数据表：第 1 行 = 英文列名（程序解析依据，外部工具兼容），
#              第 2 行 = 中文注释（策划阅读用，导出时整行忽略），数据从第 3 行开始。
HEADER_ROWS = 2
DATA_START_ROW = HEADER_ROWS + 1  # 3


# ========== 列名中英映射（策划可读层；未收录列名回显英文） ==========
# key = 英文列名（含点号列全名），value = 中文注释。新增列无映射时显示英文原名。
COLUMN_ZH = {
    # ---- 通用列 ----
    "id": "ID", "name": "名称", "name_en": "英文名", "description": "描述",
    "level": "等级", "price": "价格", "tier": "阶数", "slot": "槽位",
    "category": "分类", "icon_index": "图标序号", "star_echo": "星骸词条(JSON)",
    "key": "效果键", "value": "数值", "unit": "单位", "wave": "波次",
    "type": "类型", "text": "文本", "title": "标题", "theme": "主题",
    "max": "上限", "base": "基础值", "index": "序号", "special": "特殊说明",
    "_xlsx_category": "分类(导出归组用)",
    # ---- weapons / weapons_levels ----
    "damage": "伤害", "cooldown": "冷却(秒)", "range": "射程",
    "crit_chance": "暴击率", "crit_damage": "暴击伤害", "knockback": "击退",
    "life_steal": "吸血", "max_level": "最大等级", "upgrade": "升级描述",
    "duration": "持续(秒)", "projectiles": "弹幕数", "blade_count": "剑刃数",
    "orbit_radius": "环绕半径", "orbit_speed": "环绕速度", "summon_count": "召唤数",
    "explosion_radius": "爆炸半径", "element_type": "元素类型", "signature_of": "专属来源",
    "evolution": "进化链(JSON)", "evolution_result": "进化结果(JSON)",
    "scaling.melee_damage": "成长系数.近战伤害", "scaling.ranged_damage": "成长系数.远程伤害",
    "scaling.elemental_damage": "成长系数.元素伤害", "scaling.engineering": "成长系数.工程伤害",
    "weapon_id": "武器ID",
    # ---- items / items_effects ----
    "rarity": "稀有度", "tags": "标签(JSON)", "is_passive": "是否被动",
    "item_id": "道具ID",
    "evolution.weapon_id": "进化.武器ID", "evolution.requires_level": "进化.需求等级",
    "evolution.result_id": "进化.结果ID", "evolution.result_name": "进化.结果名",
    "evolution.description": "进化.描述",
    "trigger.type": "触发.类型", "trigger.radius": "触发.半径", "trigger.ratio": "触发.比例",
    "trigger.heal": "触发.治疗", "trigger.threshold": "触发.阈值",
    "trigger.attack_mult": "触发.攻击倍率", "trigger.speed_mult": "触发.速度倍率",
    # ---- enemies / enemy_scaling ----
    "hp": "生命值", "hp_growth": "生命成长", "speed": "速度", "drop": "掉落",
    "behavior": "行为", "exp_value": "经验值", "coin_value": "金币值", "armor": "护甲",
    "phases": "阶段(JSON)", "damage_growth": "伤害成长",
    "ability.type": "技能.类型", "ability.radius": "技能.半径", "ability.interval": "技能.间隔",
    "ability.damage_mult": "技能.伤害倍率", "ability.threshold": "技能.阈值",
    "ability.heal_percent": "技能.治疗%", "ability.minion": "技能.召唤物", "ability.count": "技能.数量",
    "speed_growth_per_wave": "速度每波成长", "speed_growth_cap": "速度成长上限",
    "speed_reduction": "速度削减", "elite_hp_mult_per_wave": "精英生命每波倍率",
    "elite_dmg_mult_per_wave": "精英伤害每波倍率",
    # ---- characters ----
    "sprite": "精灵", "starting_weapon": "起始武器", "weapon_restrictions": "武器限制(JSON)",
    "unlock_condition": "解锁条件", "story": "背景故事", "story_unlock_level": "解锁等级",
    "class": "职业", "char_id": "角色ID",
    "skill.id": "技能.ID", "skill.name": "技能.名称", "skill.name_en": "技能.英文名",
    "skill.type": "技能.类型", "skill.cooldown": "技能.冷却", "skill.damage": "技能.伤害",
    "skill.radius": "技能.范围", "skill.element_type": "技能.元素类型",
    "skill.burn_duration": "技能.灼烧时长", "skill.description": "技能.描述",
    "skill.summon_id": "技能.召唤物ID", "skill.summon_count": "技能.召唤数",
    "skill.duration": "技能.持续",
    "skill.effects.orbit_blade_count": "技能.效果.环绕剑刃数",
    "skill.effects.attack_speed_percent": "技能.效果.攻速%",
    "skill.effects.shield": "技能.效果.护盾", "skill.effects.heal": "技能.效果.治疗",
    "growth.type": "成长.类型", "growth.description": "成长.描述",
    "growth.per_level.elemental_damage": "成长.每级.元素伤害",
    "growth.per_level.fire_damage_percent": "成长.每级.火焰伤害%",
    "growth.per_level.engineering": "成长.每级.工程伤害",
    "growth.per_level.crit_chance_percent": "成长.每级.暴击率%",
    "growth.per_level.life_steal_percent": "成长.每级.吸血%",
    "growth.per_level.hp_regen": "成长.每级.回血", "growth.per_level.luck": "成长.每级.幸运",
    "growth.per_5_levels.summon_count": "成长.每5级.召唤数",
    # ---- waves / wave_generation / wave_rewards ----
    "total_enemies": "敌人数", "composition": "组成(JSON)", "special_note": "特殊备注",
    "spawn_interval_min": "生成间隔下限", "spawn_interval_decay": "生成间隔衰减",
    "wave_complete_base": "波次完成基础奖励", "harvesting_bonus": "收割加成",
    "kill_bonus": "击杀奖励",
    # ---- events ----
    "choiceA.text": "选项A.文本", "choiceA.reward.type": "选项A.奖励.类型",
    "choiceA.reward.value": "选项A.奖励.数值", "choiceA.reward.label": "选项A.奖励.标签",
    "choiceB.text": "选项B.文本", "choiceB.effect_on_route.type": "选项B.路线效果.类型",
    "choiceB.effect_on_route.value": "选项B.路线效果.数值",
    "choiceB.effect_on_route.label": "选项B.路线效果.标签",
    # ---- stats / stats_formulas / stats_leveling / stats_shop ----
    "crit_check": "暴击判定", "armor_reduction": "护甲减伤", "armor_final": "最终护甲",
    "attack_speed": "攻速公式", "attack_speed_min": "攻速下限", "dodge": "闪避",
    "harvesting": "收割", "luck_shop": "幸运(商店)", "luck_chest": "幸运(宝箱)",
    "curse_hp": "诅咒-生命", "curse_damage": "诅咒-伤害", "curse_speed": "诅咒-速度",
    "curse_drop": "诅咒-掉落",
    "xp_per_level": "每级经验", "choices_per_level": "每级选项数",
    "upgrade_options": "升级选项(JSON)", "reroll_cost": "重铸费用",
    "core_grace_wave": "核心武器宽限波",
    # ---- stats_combat（F1-散 T-007/008/013/015 战斗参数） ----
    "wave_clear_heal_ratio": "通关回血比例", "max_waves": "最大波次(兜底)",
    "i_frames": "受击无敌帧(秒)", "dodge_cap": "闪避上限", "debug_damage_mult": "金手指受伤倍率",
    "knockback_decay": "击退衰减(每帧)", "contact_cooldown": "接触伤害冷却(秒)",
    "armor_cap": "护甲减伤上限(保留参数)",
    # ---- stats_physics（F1-散 T-011 弹丸物理参数） ----
    "projectile_mask": "弹丸碰撞层", "projectile_radius": "弹丸碰撞半径",
    # ---- stats_skills（F1-散 T-012 火球参数） ----
    "fireball_speed": "火球速度", "fireball_lifetime": "火球寿命(秒)",
    "fireball_pierce": "火球穿透数", "fireball_radius": "火球爆炸半径",
    # ---- enemy_scaling 扩展（F1-散 T-009 冲锋参数） ----
    "charge_speed_mult": "冲锋倍率", "charge_windup": "蓄力间隔(秒)",
    "charge_duration": "冲锋持续(秒)",
    # ---- elements / element_reactions / reaction_rules ----
    "effect": "效果", "dot": "持续伤害", "dot_scaling": "持续伤害成长",
    "slow_percent": "减速%", "stun": "眩晕",
    "combination": "组合(JSON)", "damage_scaling": "伤害成长", "aoe_radius": "范围半径",
    "extra_effect": "附加效果", "chain_count": "连锁数", "chain_falloff": "连锁衰减",
    "element_id": "元素ID",
    "trigger_condition": "触发条件", "post_reaction": "反应后", "damage_type": "伤害类型",
    "scales_with": "成长属性",
    # ---- routes ----
    "layers": "层数", "nodes_per_layer": "每层节点数", "boss_layers": "Boss层(JSON)",
    "default_seed": "默认种子", "boss_wave": "Boss波次",
    "weights.battle": "权重.战斗", "weights.event": "权重.事件",
    "weights.elite": "权重.精英", "weights.shop": "权重.商店",
    "constraints.first_layer_has_battle": "约束.首层必有战斗",
    "constraints.final_layer_boss": "约束.末层Boss",
    "constraints.max_battle_nodes": "约束.最大战斗节点",
}


def col_zh(name: str | None) -> str:
    """英文列名 → 中文注释；无映射或空列名回显英文原样（新列自动兜底）。"""
    if name is None:
        return ""
    return COLUMN_ZH.get(name, str(name))

# ========== 表定义 ==========

# 每张 sheet：{sheet, file(来源 JSON 文件名), root(JSON 内根键), key(实体 id 列名),
#              category(分类列名或 None), kind: list | dict, sub_of(子表父表) | None,
#              json_cols(保持 JSON 文本的列), child(子表列表)}
# kind: "list" = root 是数组；"dict" = root 是 {key: data}
# category_map: JSON 形如 {root: {category: [ ... ]}}
SHEETS = {
    "weapons": {
        "sheet": "weapons", "file": "weapons.json", "root": "weapons",
        "key": "id", "category": "_xlsx_category", "kind": "category_map",
        "json_cols": ["evolution", "evolution_result", "star_echo"],
        "child": "weapons_levels",
    },
    "weapons_levels": {
        "sheet": "weapons_levels", "file": "weapons.json", "root": "levels",
        "key": "weapon_id", "category": None, "kind": "child_list",
        "json_cols": [], "parent_sheet": "weapons", "unique_with": "level",
    },
    "items": {
        "sheet": "items", "file": "items.json", "root": "items",
        "key": "id", "category": None, "kind": "list",
        "json_cols": ["tags"], "child": "items_effects",
    },
    "items_effects": {
        "sheet": "items_effects", "file": "items.json", "root": "effects",
        "key": "item_id", "category": None, "kind": "child_dict",
        "json_cols": [], "parent_sheet": "items", "unique_with": "key",
    },
    "enemies": {
        "sheet": "enemies", "file": "enemies.json", "root": "enemies",
        "key": "id", "category": "_xlsx_category", "kind": "category_map",
        "json_cols": ["phases"], "child": None,
    },
    "enemy_scaling": {
        "sheet": "enemy_scaling", "file": "enemies.json", "root": "scaling",
        "key": None, "category": None, "kind": "flat_dict",
        "json_cols": [], "child": None,
    },
    "characters": {
        "sheet": "characters", "file": "characters.json", "root": "characters",
        "key": "id", "category": None, "kind": "list",
        "json_cols": ["weapon_restrictions"], "child": None,
        # skill 为 dict → 点号宽列自动；passive/penalty 拆子表
        "dict_sub_cols": ["characters_passives", "characters_penalties"],
    },
    "characters_passives": {
        "sheet": "characters_passives", "file": "characters.json", "root": "passive",
        "key": "char_id", "category": None, "kind": "child_dict",
        "json_cols": [], "parent_sheet": "characters", "unique_with": "key",
    },
    "characters_penalties": {
        "sheet": "characters_penalties", "file": "characters.json", "root": "penalty",
        "key": "char_id", "category": None, "kind": "child_dict",
        "json_cols": [], "parent_sheet": "characters", "unique_with": "key",
    },
    "waves": {
        "sheet": "waves", "file": "waves.json", "root": "waves",
        "key": "wave", "category": None, "kind": "list",
        "json_cols": ["composition"], "child": None,
    },
    "wave_generation": {
        "sheet": "wave_generation", "file": "waves.json", "root": "generation",
        "key": None, "category": None, "kind": "flat_dict",
        "json_cols": [], "child": None,
    },
    "wave_rewards": {
        "sheet": "wave_rewards", "file": "waves.json", "root": "rewards",
        "key": None, "category": None, "kind": "flat_dict",
        "json_cols": [], "child": None,
    },
    "events": {
        "sheet": "events", "file": "events.json", "root": "events",
        "key": "id", "category": None, "kind": "list",
        # choiceA/choiceB 为嵌套 dict → 点号宽列自动展开；
        # value 列存在异构（标量 / dict），声明为双形态列：标量原样、dict/list JSON 文本
        "json_cols": ["choiceA.reward.value", "choiceB.effect_on_route.value"], "child": None,
    },
    "stats": {
        "sheet": "stats", "file": "stats.json", "root": "stats",
        "key": "id", "category": "_xlsx_category", "kind": "category_map",
        "json_cols": [], "child": None,
    },
    "stats_formulas": {
        "sheet": "stats_formulas", "file": "stats.json", "root": "formulas",
        "key": None, "category": None, "kind": "flat_dict",
        "json_cols": [], "child": None,
    },
    "stats_leveling": {
        "sheet": "stats_leveling", "file": "stats.json", "root": "leveling",
        "key": None, "category": None, "kind": "flat_dict",
        "json_cols": ["upgrade_options"], "child": None,
    },
    "stats_shop": {
        "sheet": "stats_shop", "file": "stats.json", "root": "shop",
        "key": None, "category": None, "kind": "flat_dict",
        "json_cols": [], "child": None,
    },
    # F1-散（2026-08-13 T-007/008/013/015/011/012）：战斗/物理/技能参数表（flat_dict 单行，
    # 仿 stats_shop F1-D 先例；stats.json 顶层新增 combat/physics/skills 三键，消费点
    # DataLoader.get_stats_combat/physics/skills 读，缺段兜底 = 现硬编码值防行为漂移）
    "stats_combat": {
        "sheet": "stats_combat", "file": "stats.json", "root": "combat",
        "key": None, "category": None, "kind": "flat_dict",
        "json_cols": [], "child": None,
    },
    "stats_physics": {
        "sheet": "stats_physics", "file": "stats.json", "root": "physics",
        "key": None, "category": None, "kind": "flat_dict",
        "json_cols": [], "child": None,
    },
    "stats_skills": {
        "sheet": "stats_skills", "file": "stats.json", "root": "skills",
        "key": None, "category": None, "kind": "flat_dict",
        "json_cols": [], "child": None,
    },
    "elements": {
        "sheet": "elements", "file": "elements.json", "root": "elemental_status",
        "key": "element_id", "category": None, "kind": "dict",
        "json_cols": [], "child": None,
    },
    "element_reactions": {
        "sheet": "element_reactions", "file": "elements.json", "root": "element_reactions",
        "key": "index", "category": None, "kind": "list", "auto_key": True,
        "json_cols": ["combination"], "child": None,
    },
    "reaction_rules": {
        "sheet": "reaction_rules", "file": "elements.json", "root": "reaction_rules",
        "key": None, "category": None, "kind": "flat_dict",
        "json_cols": [], "child": None,
    },
    "routes": {
        "sheet": "routes", "file": "routes.json", "root": None,
        "key": None, "category": None, "kind": "flat_dict",
        "json_cols": ["boss_layers"], "child": None,
    },
}

# ========== 工具函数 ==========

def dumps_json(v) -> str:
    """JSON 文本列序列化（Excel 单元格内可编辑）"""
    return json.dumps(v, ensure_ascii=False, separators=(",", ":"))


def loads_json(s) -> object:
    """JSON 文本列反序列化；空/非法返回 None（导出时校验器会报）"""
    if s is None:
        return None
    if isinstance(s, str):
        s = s.strip()
        if not s:
            return None
        try:
            return json.loads(s)
        except json.JSONDecodeError:
            return None
    return s  # 单元格里直接放了对象（少见）


def flatten(prefix: str, value, json_cols: set, out: dict) -> None:
    """把嵌套值展平为点号列（一层 dict 递归；list/json_cols 保持 JSON 文本）"""
    if isinstance(value, dict):
        for k, v in value.items():
            col = f"{prefix}.{k}" if prefix else str(k)
            if col in json_cols or isinstance(v, (list, dict)) and col not in json_cols and not isinstance(v, dict):
                # json_cols 显式列 → JSON 文本；list 值 → JSON 文本
                if isinstance(v, (list, dict)):
                    out[col] = dumps_json(v)
                else:
                    out[col] = v
            elif isinstance(v, dict):
                flatten(col, v, json_cols, out)
            else:
                out[col] = v
    else:
        out[prefix] = value


def unflatten(row: dict, json_cols: set) -> dict:
    """点号列还原嵌套 dict；JSON 文本列反序列化。
    约定：空单元格 = 键缺失（与原 JSON 的 null 值语义等价，DataLoader get() 兜底）。"""
    out: dict = {}
    for col, val in row.items():
        if val is None or col.startswith("_"):
            continue
        parts = col.split(".")
        if len(parts) == 1:
            if val is None:
                out[col] = None
            elif col in json_cols:
                parsed = loads_json(val)
                out[col] = parsed if parsed is not None else val
            else:
                out[col] = val
            continue
        node = out
        for p in parts[:-1]:
            node = node.setdefault(p, {})
        if col in json_cols:
            parsed = loads_json(val)
            node[parts[-1]] = parsed if parsed is not None else val
        else:
            node[parts[-1]] = val
    return out
