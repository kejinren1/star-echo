#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""collect_final2.py — 主角团+Boss 像素模型分页矩阵（每页≤12格）+ 可视化编号对照 PNG"""
import os, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = r"D:/30DAYS/docs/art_ai/output_abc/final_完美像素"
OUT = r"D:/30DAYS/docs/art_ai/output_abc/final_完美像素/最终选择_20260816"
os.makedirs(OUT, exist_ok=True)

def font(sz):
    for p in [r"C:/Windows/Fonts/msyh.ttc", r"C:/Windows/Fonts/simhei.ttf"]:
        if os.path.exists(p):
            return ImageFont.truetype(p, sz)
    return ImageFont.load_default()

GROUPS = {
    "艾琳": [("elin", "艾琳")],
    "诺亚": [("noah", "诺亚")],
    "莱恩": [("lain", "莱恩")],
    "希亚": [("siia", "希亚")],
    "BOSS①魔族女战士": [("boss_01", "B1"), ("v8_boss_01", "B1")],
    "BOSS②黑魔法师": [("boss_02", "B2"), ("v7_boss_02", "B2"), ("v8_boss_02", "B2")],
    "BOSS③帮派首领": [("boss_03", "B3"), ("v8_boss_03", "B3")],
    "BOSS④白蓝金骑士": [("boss_04", "B4"), ("v7_boss_04", "B4"), ("v8_boss_04", "B4"), ("v9_boss_04", "B4"), ("v10_boss_04", "B4")],
    "BOSS⑤病态狼兽": [("boss_05", "B5"), ("v7_boss_05", "B5"), ("v8_boss_05", "B5"), ("v9_boss_05", "B5"), ("v10_boss_05", "B5"), ("v11_boss_05", "B5"), ("wolf", "B5")],
    "BOSS⑥牛头人": [("boss_06", "B6"), ("v8_boss_06", "B6")],
    "BOSS⑦空洞女神": [("boss_07", "B7"), ("v7_boss_07", "B7")],
    "BOSS⑧不详之镜": [("boss_08", "B8"), ("v8_boss_08", "B8")],
}
VER_ORDER = ["主角团_20260815", "v3_20260815", "v4_20260815", "v5_20260815", "v6_20260815",
             "v7_20260815", "v8_20260815", "v9_20260816", "v10_20260816", "v11_20260816",
             "v12_20260816", "v13_20260816", "v14_20260816", "v15_20260816", "v16_20260816"]

def collect(prefixes):
    found = []
    for ver in VER_ORDER:
        vp = os.path.join(ROOT, ver)
        if not os.path.isdir(vp):
            continue
        for sub in sorted(os.listdir(vp)):
            p = os.path.join(vp, sub, "96px.png")
            if os.path.exists(p) and any(sub.startswith(pr) for pr, _ in prefixes):
                found.append((ver, sub, p))
    return found

CELL = 460
PER_PAGE = 12
COLS = 4

def page_grid(items, page_items, title, start_idx):
    rows = (len(page_items) + COLS - 1) // COLS
    W, H = COLS * CELL, rows * CELL
    canvas = Image.new("RGB", (W, H), (26, 26, 30))
    d = ImageDraw.Draw(canvas)
    f = font(30)
    for j, (ver, sub, p) in enumerate(page_items):
        r, c = divmod(j, COLS)
        x, y = c * CELL, r * CELL
        idx = start_idx + j
        im = Image.open(p).convert("RGB").resize((CELL, CELL), Image.NEAREST)
        canvas.paste(im, (x, y))
        d.text((x + 8, y + 8), f"{title[:5]}·{idx:02d}", fill=(255, 235, 60), font=f)
    return canvas

# 清单矩阵：编号 → 版本/组名（PNG）
def make_index_png(rows, title):
    cols = 2
    cell_h = 44
    W = 900
    canvas = Image.new("RGB", (W, cell_h * len(rows) + 30), (20, 20, 24))
    d = ImageDraw.Draw(canvas)
    f = font(22)
    d.text((12, 6), title, fill=(255, 235, 60), font=font(26))
    for i, (idx, ver, sub) in enumerate(rows):
        y = 30 + i * cell_h
        d.text((14, y + 8), f"{idx:02d}", fill=(255, 235, 60), font=f)
        d.text((90, y + 8), f"{ver}  {sub}", fill=(220, 220, 220), font=f)
    return canvas

all_index = []
for zh, prefixes in GROUPS.items():
    found = collect(prefixes)
    if not found:
        continue
    pages = (len(found) + PER_PAGE - 1) // PER_PAGE
    for pi in range(pages):
        chunk = found[pi * PER_PAGE:(pi + 1) * PER_PAGE]
        g = page_grid(found, chunk, zh, pi * PER_PAGE)
        fname = f"选_{zh[:5]}_p{pi+1}.png"
        g.save(os.path.join(OUT, fname))
        print(f"{zh} p{pi+1}: {len(chunk)} 张 → {fname}", flush=True)
    for i, (ver, sub, p) in enumerate(found):
        all_index.append((i + 1, ver, sub, zh))
    print(f"  [{zh}] 共 {len(found)} 张, {pages} 页", flush=True)

# 生成可视化编号对照 PNG（分页，每页 40 行）
idx_pages = (len(all_index) + 39) // 40
for pi in range(idx_pages):
    chunk = all_index[pi * 40:(pi + 1) * 40]
    g = make_index_png([(i, v, s) for i, v, s, _ in chunk], f"编号对照 p{pi+1}/{idx_pages}")
    g.save(os.path.join(OUT, f"编号对照_p{pi+1}.png"))
print(f"编号对照 {idx_pages} 页", flush=True)
