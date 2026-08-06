#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Day 11-12 被动数据工具：items.json 20 被动落地（幂等 apply）+ 校验（verify）。

对应 docs/TASKS.md D11-12-PRE / D11-12-T1【W2】：
  · 从 items.json 48 项选 20 项为被动池（3 进化核心必选，其余 28 项不动）
  · 入选 20 项补 4 字段：is_passive/slot/category/icon_index（0-19 全局唯一）
  · 17 常规项 effects 白名单化（改键不造数）：ball_and_chain 去 knockback、
    banner 裸 range:15 → range_percent:8（200px 基准换算 15/200*100 ≈ 8，附依据）
  · 3 核心例外：effects 保留禁键（机制未实现占位登记），核心价值在 evolution 字段

用法：
    python tools/gen_passives_day11.py          # apply（幂等）到 data/items.json
    python tools/gen_passives_day11.py verify   # 校验（不写盘）
"""

import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ITEMS_PATH = os.path.join(ROOT, "data", "items.json")

# ---- 20 被动清单：id → (category, icon_index) ----
# 四类各 5 项：attack / defense / stat / special（3 进化核心在 special，必选）
PASSIVES = [
    # attack (5)
    ("coffee", "attack", 0),
    ("injection", "attack", 1),
    ("medal", "attack", 2),
    ("glass_cannon", "attack", 3),
    ("bone_dice", "attack", 4),
    # defense (5)
    ("helmet", "defense", 5),
    ("alien_worm", "defense", 6),
    ("jelly", "defense", 7),
    ("mushroom", "defense", 8),
    ("guardian_shield", "defense", 9),
    # stat (5)
    ("sneakers", "stat", 10),
    ("insanity", "stat", 11),
    ("potato", "stat", 12),
    ("adrenaline_shot", "stat", 13),
    ("ball_and_chain", "stat", 14),
    # special (5)
    ("blood_leech", "special", 15),
    ("banner", "special", 16),
    ("se_flame_core", "special", 17),
    ("se_mech_core", "special", 18),
    ("se_blade_core", "special", 19),
]

PASSIVE_IDS = [p[0] for p in PASSIVES]
CORE_IDS = ["se_flame_core", "se_mech_core", "se_blade_core"]

# 17 常规项 effects 白名单修正（改键不造数；None = 删除该键）
EFFECTS_FIX = {
    "ball_and_chain": {
        "knockback": None,  # 禁键：击退机制未实装，删除防静默失效
    },
    "banner": {
        "range": "range_percent",  # 裸 range 像素键 → range_percent（200px 基准：15/200*100 ≈ 8）
    },
}

# 白名单键集（player.gd STAT_MAP 15+1：扩展 crit_damage_percent）
WHITELIST = {
    "max_hp", "speed_percent", "armor", "regen", "hp_regen",
    "dodge_percent", "crit_chance_percent", "attack_speed_percent",
    "melee_attack_speed_percent", "damage_percent", "range_percent",
    "luck", "pickup_range", "life_steal_percent", "crit_damage_percent",
}


def _load_items():
    with open(ITEMS_PATH, encoding="utf-8") as f:
        return json.load(f)


def _save_items(data):
    with open(ITEMS_PATH, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")


def apply():
    data = _load_items()
    items = data["items"]
    by_id = {it["id"]: it for it in items}
    changed = 0

    for pid, cat, idx in PASSIVES:
        if pid not in by_id:
            print("  WARN  items.json 缺被动条目: %s" % pid)
            continue
        it = by_id[pid]
        if it.get("is_passive") != True:
            changed += 1
        it["is_passive"] = True
        it["slot"] = "passive"
        it["category"] = cat
        it["icon_index"] = idx

        # effects 修正（仅常规项；核心保留禁键占位登记）
        if pid not in CORE_IDS and pid in EFFECTS_FIX:
            effects = it.setdefault("effects", {})
            for key, new_key in EFFECTS_FIX[pid].items():
                if key in effects:
                    val = effects.pop(key)
                    changed += 1
                    if new_key is not None:
                        # 换算：range 15 → range_percent 8（200px 基准）
                        if pid == "banner" and key == "range":
                            effects[new_key] = 8
                            print("  FIX  banner: range:15 → range_percent:8（200px 基准 15/200*100 ≈ 8）")
                        else:
                            effects[new_key] = val

    _save_items(data)
    print("已写入 %s（改动 %d 项）" % (ITEMS_PATH, changed))


def verify():
    data = _load_items()
    items = data["items"]
    by_id = {it["id"]: it for it in items}
    errors = []

    # 1. 20 项四字段齐 + 唯一 icon_index + 类别各 ≥4
    for pid, cat, idx in PASSIVES:
        it = by_id.get(pid)
        if it is None:
            errors.append("缺被动条目: %s" % pid)
            continue
        if it.get("is_passive") != True:
            errors.append("%s is_passive 缺省" % pid)
        if it.get("slot") != "passive":
            errors.append("%s slot 应为 passive" % pid)
        if it.get("category") != cat:
            errors.append("%s category 应为 %s" % (pid, cat))
        if it.get("icon_index") != idx:
            errors.append("%s icon_index 应为 %d" % (pid, idx))

    idxs = [by_id[pid].get("icon_index", -1) for pid, _, _ in PASSIVES]
    if len(set(idxs)) != 20 or any(i < 0 or i > 19 for i in idxs):
        errors.append("icon_index 0-19 唯一性破坏: %s" % sorted(idxs))

    cats = {}
    for _, cat, _ in PASSIVES:
        cats[cat] = cats.get(cat, 0) + 1
    for cat in ("attack", "defense", "stat", "special"):
        if cats.get(cat, 0) < 4:
            errors.append("category %s 数量 < 4（实得 %d）" % (cat, cats.get(cat, 0)))

    # 2. 17 常规项 effects 键 ⊂ 白名单（3 核心豁免）
    for pid, _, _ in PASSIVES:
        if pid in CORE_IDS:
            continue
        effects = by_id[pid].get("effects", {})
        for key in effects:
            if key not in WHITELIST:
                errors.append("%s effects 含禁键 %s" % (pid, key))

    # 3. 3 核心 id 命中
    for cid in CORE_IDS:
        if cid not in by_id or not by_id[cid].get("is_passive"):
            errors.append("核心 %s 未标记 passive" % cid)

    # 4. 其余 28 项不加被动标记（商店池自然排除）
    non_passive = [it["id"] for it in items if it["id"] not in PASSIVE_IDS and it.get("is_passive")]
    if non_passive:
        errors.append("非被动项被误标记: %s" % non_passive)

    if errors:
        print("DAY11-12 PASSIVES VERIFY BROKEN（%d 项）:" % len(errors))
        for e in errors:
            print("  - %s" % e)
        return 1
    print("DAY11-12 PASSIVES VERIFY CLEAN（20 被动 / 四类各5 / 白名单 / 唯一 icon_index）")
    return 0


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "verify":
        sys.exit(verify())
    apply()
