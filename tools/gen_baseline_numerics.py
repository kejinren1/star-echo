#!/usr/bin/env python3
"""F0 基线数值快照：从 data/*.json 提取关键玩法数值序列化存档。

用途（docs/TECH_DEBT_PLAN.md F0/F4）：
- F0：锁定重构前数值基线
- F4 拆分大脚本后：diff 本快照，验证玩法数值零漂移
- F1 数据层统一后：diff 验证「改数据表生效」且未误伤其他表

用法：
    python tools/gen_baseline_numerics.py
输出：
    tools/baseline_numerics.json（含生成时间与数据指纹）
"""
import json
import hashlib
import datetime
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "data"
OUT = ROOT / "tools" / "baseline_numerics.json"


def load(name: str) -> dict:
    with open(DATA / name, encoding="utf-8") as f:
        return json.load(f)


def main() -> int:
    snap: dict = {"generated_at": datetime.datetime.now().isoformat(timespec="seconds")}
    tables: dict = {}

    # 武器：id/分类/基础属性/levels 全量
    weapons = load("weapons.json")
    w_list = []
    for cat, items in weapons.get("weapons", {}).items():
        for w in items:
            w_list.append({
                "id": w.get("id"), "category": cat, "tier": w.get("tier"),
                "price": w.get("price"), "damage": w.get("damage"),
                "cooldown": w.get("cooldown"), "range": w.get("range"),
                "crit_chance": w.get("crit_chance"), "crit_damage": w.get("crit_damage"),
                "knockback": w.get("knockback"), "life_steal": w.get("life_steal"),
                "scaling": w.get("scaling"),
                "levels": [{"level": lv.get("level"), "damage": lv.get("damage"),
                            "cooldown": lv.get("cooldown"), "range": lv.get("range"),
                            "upgrade": lv.get("upgrade")} for lv in w.get("levels", [])],
            })
    tables["weapons"] = w_list

    # 道具：effects 全量（含未映射键，供 F1 T-050 裁决对比）
    items = load("items.json")
    tables["items"] = [{"id": it.get("id"), "rarity": it.get("rarity"), "price": it.get("price"),
                        "is_passive": it.get("is_passive"), "slot": it.get("slot"),
                        "category": it.get("category"), "effects": it.get("effects"),
                        "tags": it.get("tags")} for it in items.get("items", [])]

    # 敌人：基础 + 成长 + 掉落
    enemies = load("enemies.json")
    e_list = []
    for cat in ("regular", "elite", "boss"):
        for e in enemies.get("enemies", {}).get(cat, []):
            e_list.append({"id": e.get("id"), "category": cat, "hp": e.get("hp"),
                           "hp_growth": e.get("hp_growth"), "damage": e.get("damage"),
                           "damage_growth": e.get("damage_growth"), "speed": e.get("speed"),
                           "behavior": e.get("behavior"), "coin_value": e.get("coin_value", e.get("drop")),
                           "exp_value": e.get("exp_value"), "armor": e.get("armor"),
                           "phases": e.get("phases")})
    tables["enemies"] = e_list
    tables["enemy_scaling"] = enemies.get("scaling", {})

    # 角色：被动 + 技能 + 起始武器
    chars = load("characters.json")
    tables["characters"] = [{"id": c.get("id"), "passive": c.get("passive"),
                             "penalty": c.get("penalty"), "skill": c.get("skill"),
                             "starting_weapon": c.get("starting_weapon")}
                            for c in chars.get("characters", [])]

    # 波次：构成 + 生成规则 + 奖励
    waves = load("waves.json")
    tables["waves"] = [{"wave": w.get("wave"), "duration": w.get("duration"),
                        "total_enemies": w.get("total_enemies"), "composition": w.get("composition"),
                        "special": w.get("special")} for w in waves.get("waves", [])]
    tables["wave_generation"] = waves.get("generation", {})
    tables["wave_rewards"] = waves.get("rewards", {})

    # 元素/属性/事件/路线
    elements = load("elements.json")
    tables["elemental_status"] = elements.get("elemental_status", {})
    tables["element_reactions"] = elements.get("element_reactions", [])
    stats = load("stats.json")
    tables["stats"] = stats.get("stats", {})
    tables["formulas"] = stats.get("formulas", {})
    tables["leveling"] = stats.get("leveling", {})
    events = load("events.json")
    tables["events"] = [{"id": e.get("id"), "theme": e.get("theme")} for e in events.get("events", [])]
    tables["routes"] = load("routes.json")

    snap["tables"] = tables
    # 指纹：仅用于快速判等（F4 对比），内容变化即变化
    snap["fingerprint"] = hashlib.sha256(
        json.dumps(tables, sort_keys=True, ensure_ascii=False).encode("utf-8")).hexdigest()[:16]

    OUT.write_text(json.dumps(snap, ensure_ascii=False, indent=1), encoding="utf-8")
    counts = {k: (len(v) if isinstance(v, list) else "obj") for k, v in tables.items()}
    print(f"[baseline] {OUT}")
    print(f"[baseline] fingerprint={snap['fingerprint']}")
    print(f"[baseline] counts={counts}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
