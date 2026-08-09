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
