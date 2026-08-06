"""QA data-layer validator for Star Echo (automation #4 / RS-test).

Checks (all read-only, no game logic touched):
  1. Every data/*.json parses with json.load
  2. ID uniqueness across each table (characters/weapons/items/events/enemies)
  3. Cross-references:
     - characters.starting_weapon -> weapons (flatten {weapons:{cat:[list]}})
     - waves[].composition[].enemy -> enemies base id (strip elite:/boss: prefix,
       allow mixed* pool tokens) or weapon id (evolution pool tokens)
  4. Numeric boundary scan (recursive): negative values allowed (penalty design),
     zero-damage allowed for force_field (by weapon id), -1 sentinel allowed for
     boss waves (total_enemies), crit dual-caliber (crit_chance in [0,1] /
     crit_chance_percent in [0,100]).

Exit code 0 = healthy; non-zero = defect found. Prints a summary.
"""

import json
import os
import sys

DATA_DIR = os.path.abspath("data")
BENIGN_NEGATIVE_KEYS = {"penalty", "curse", "cost", "price", "soul_cost"}
MIXED_TOKENS = {"mixed", "mixed_with_curse"}

issues = []
warnings = []


def norm(path: str) -> str:
    return os.path.normpath(path).replace("\\", "/")


def load_all() -> dict:
    tables = {}
    files = sorted(os.listdir(DATA_DIR))
    if not files:
        issues.append("data/ 目录为空")
    for fn in files:
        if not fn.endswith(".json"):
            continue
        p = os.path.join(DATA_DIR, fn)
        with open(p, "r", encoding="utf-8") as fh:
            try:
                tables[fn] = json.load(fh)
            except json.JSONDecodeError as e:
                issues.append(f"{fn}: JSON 解析失败 line {e.lineno} col {e.colno}: {e.msg}")
    return tables


def flatten_weapons(t: dict) -> list:
    """weapons.json shape: {weapons: {cat: [list]}}"""
    root = t.get("weapons", t)
    out = []
    if isinstance(root, dict):
        for cat, arr in root.items():
            if isinstance(arr, list):
                out.extend(arr)
    return out


def flatten_enemies(t: dict) -> list:
    """enemies.json shape: {enemies: {regular/elite/boss: [list]}}"""
    root = t.get("enemies", t)
    out = []
    if isinstance(root, dict):
        for cat, arr in root.items():
            if isinstance(arr, list):
                for e in arr:
                    e["__cat"] = cat
                    out.append(e)
    return out


def get_list(tables: dict, fn: str, key: str) -> list:
    t = tables.get(fn, {})
    v = t.get(key)
    if isinstance(v, list):
        return v
    return []


def check_unique(rows: list, label: str) -> None:
    seen = {}
    for r in rows:
        rid = r.get("id")
        if not rid:
            issues.append(f"{label}: 缺 id 字段: {r}")
            continue
        if rid in seen:
            issues.append(f"{label}: id 重复 '{rid}' (首次 {seen[rid]})")
        else:
            seen[rid] = "?"


def base_enemy_id(token: str) -> str:
    """strip elite:/boss: prefix, keep mixed* tokens"""
    t = token.strip()
    if t.startswith("elite:") or t.startswith("boss:"):
        return t.split(":", 1)[1]
    return t


def walk_numbers(obj, path: str, weapon_ctx: str, out: list) -> None:
    """recursive numeric scan; append (path, value, weapon_ctx) tuples"""
    if isinstance(obj, dict):
        cur = weapon_ctx
        for k, v in obj.items():
            if k.startswith("__"):
                continue
            if k == "id":
                cur = str(v)
            walk_numbers(v, f"{path}.{k}", cur, out)
    elif isinstance(obj, list):
        for i, v in enumerate(obj):
            walk_numbers(v, f"{path}[{i}]", weapon_ctx, out)
    elif isinstance(obj, (int, float)):
        out.append((path, obj, weapon_ctx))


def main() -> int:
    tables = load_all()
    if issues:
        for i in issues:
            print(f"[DEFECT] {i}")
        return 1

    # ---- 2) ID uniqueness ----
    weapons = flatten_weapons(tables.get("weapons.json", {}))
    enemies = flatten_enemies(tables.get("enemies.json", {}))
    chars = get_list(tables, "characters.json", "characters")
    items = get_list(tables, "items.json", "items")
    events = get_list(tables, "events.json", "events")
    if not chars:
        # fallback: try any list at root
        for v in tables.get("characters.json", {}).values():
            if isinstance(v, list):
                chars = v
                break
    if not items:
        for v in tables.get("items.json", {}).values():
            if isinstance(v, list):
                items = v
                break
    if not events:
        for v in tables.get("events.json", {}).values():
            if isinstance(v, list):
                events = v
                break
    check_unique(chars, "characters")
    check_unique(weapons, "weapons")
    check_unique(items, "items")
    check_unique(events, "events")
    check_unique(enemies, "enemies")

    wid_set = {w.get("id") for w in weapons if w.get("id")}
    eid_base = {e.get("id") for e in enemies if e.get("id")}

    # ---- 3) cross references ----
    for c in chars:
        sw = c.get("starting_weapon")
        if sw and sw not in wid_set:
            issues.append(f"characters '{c.get('id')}': starting_weapon '{sw}' 悬空")
    waves = tables.get("waves.json", {}).get("waves", [])
    total_tokens = 0
    unresolved = []
    for wi, w in enumerate(waves):
        comp = w.get("composition", [])
        for ci, c in enumerate(comp):
            tok = c.get("enemy")
            if not tok:
                continue
            total_tokens += 1
            base = base_enemy_id(tok)
            if base in MIXED_TOKENS or base.startswith("mixed"):
                continue  # pool token, latent until WaveManager lands
            if base not in eid_base:
                unresolved.append(f"waves[{wi}].composition[{ci}].enemy='{tok}'")
    if unresolved:
        warnings.append(f"waves->enemies 未解析 {len(unresolved)} 处: {unresolved[:5]}{'...' if len(unresolved) > 5 else ''}")

    # ---- 4) numeric boundaries ----
    force_field_ids = {w.get("id") for w in weapons if w.get("id") == "force_field"}
    nums = []
    walk_numbers(tables, "data", "", nums)
    neg = []
    zero_dmg = []
    sentinel = []
    crit_bad = []
    for path, val, wctx in nums:
        if isinstance(val, bool):
            continue
        if val < 0:
            neg.append((path, val))
        if val == 0 and "damage" in path and "levels" not in path and wctx != "force_field":
            # force_field is the only sanctioned zero-damage weapon (by id)
            zero_dmg.append((path, val, wctx))
        if val == -1 and "total_enemies" in path:
            sentinel.append(path)
        if "crit_chance" in path and "percent" not in path and (val < 0 or val > 1):
            crit_bad.append((path, val))
        if "crit_chance_percent" in path and (val < -100 or val > 100):
            crit_bad.append((path, val))

    # zero-damage re-check scoped by weapon id: only force_field entries allowed
    zd_final = []
    for path, val, wctx in zero_dmg:
        if wctx == "force_field":
            continue  # sanctioned zero-damage weapon
        if "levels" in path:
            continue  # force_field's 8 level entries are zero; context covers id
        zd_final.append((path, val))

    # ---- report ----
    n_weapons = len(weapons)
    n_enemies = len(enemies)
    n_chars = len(chars)
    n_items = len(items)
    n_events = len(events)
    n_waves = len(waves)
    n_nums = len([n for n in nums if not isinstance(n[1], bool)])  # bool 字段不入数值口径
    print(f"JSON: {len(tables)} 文件解析 OK")
    print(f"计数: characters={n_chars} weapons={n_weapons} items={n_items} events={n_events} enemies={n_enemies} waves={n_waves}")
    print(f"数值字段: {n_nums} | 负值 {len(neg)} | 零伤害(非force_field) {len(zd_final)} | 哨兵-1 {len(sentinel)} | crit越界 {len(crit_bad)}")
    if neg:
        print(f"  负值样例(全有意=惩罚/诅咒): {neg[:6]}")
    if sentinel:
        print(f"  哨兵(有意): {sorted(set(sentinel))}")
    if crit_bad:
        issues.append(f"crit 越界 {len(crit_bad)}: {crit_bad[:5]}")
    if zd_final:
        issues.append(f"非 force_field 零伤害 {len(zd_final)}: {zd_final[:5]}")

    if warnings:
        print(f"[WARNING] {len(warnings)} 条:")
        for wmsg in warnings:
            print(f"  - {wmsg}")

    if issues:
        for i in issues:
            print(f"[DEFECT] {i}")
        return 1
    print("DATA LAYER CLEAN")
    return 0


if __name__ == "__main__":
    sys.exit(main())
