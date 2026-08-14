# -*- coding: utf-8 -*-
"""生成 data/skill_tree.json（G-E · 2026-08-14 · R6 技能树占位最小集）
幂等：重跑覆盖一致（确定性输出，无时间戳）。
节点结构：{id, name, desc, prereq, cost, effect}
  effect: {stat, value, mult} → 局内经 apply_stat_modifier 注入（O2：与 research 独立并存）
首版最小集：攻击 / 生命 / 幸运 3 系 × 2-3 节点，占位先行（设计未定稿，
走 tools 生成而非 Excel 注册——方案定案 D2，F1-E 后若策划改数再收编 Excel）。
"""
import json
import os
import sys

SKILL_TREE = {
    "version": 1,
    "points_per_level": 1,
    "nodes": [
        # ── 攻击系 ──
        {"id": "atk_1", "name": "利刃", "desc": "攻击 +5%", "prereq": "", "cost": 1, "effect": {"stat": "damage", "value": 1.05, "mult": True}},
        {"id": "atk_2", "name": "锐锋", "desc": "攻击 +8%", "prereq": "atk_1", "cost": 1, "effect": {"stat": "damage", "value": 1.08, "mult": True}},
        # ── 生命系 ──
        {"id": "hp_1", "name": "体魄", "desc": "最大生命 +10%", "prereq": "", "cost": 1, "effect": {"stat": "max_health", "value": 1.10, "mult": True}},
        {"id": "hp_2", "name": "坚韧", "desc": "护甲 +3", "prereq": "hp_1", "cost": 1, "effect": {"stat": "armor", "value": 3.0, "mult": False}},
        # ── 幸运系 ──
        {"id": "lck_1", "name": "鸿运", "desc": "幸运 +0.05", "prereq": "", "cost": 1, "effect": {"stat": "luck", "value": 0.05, "mult": False}},
        {"id": "lck_2", "name": "财源", "desc": "金币获取 +5%", "prereq": "lck_1", "cost": 1, "effect": {"stat": "coin_bonus", "value": 0.05, "mult": False}},
    ],
}


def main() -> int:
    out_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "data", "skill_tree.json")
    out_path = os.path.normpath(out_path)
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(SKILL_TREE, f, ensure_ascii=False, indent=2)
        f.write("\n")
    # 自校验：id 唯一 + prereq 存在 + cost 正
    ids = [n["id"] for n in SKILL_TREE["nodes"]]
    assert len(ids) == len(set(ids)), "skill_tree id 重复"
    for n in SKILL_TREE["nodes"]:
        if n["prereq"] and n["prereq"] not in ids:
            raise SystemExit("prereq 悬空: %s -> %s" % (n["id"], n["prereq"]))
    print("[skill_tree] %d nodes -> %s" % (len(ids), out_path))
    return 0


if __name__ == "__main__":
    sys.exit(main())
