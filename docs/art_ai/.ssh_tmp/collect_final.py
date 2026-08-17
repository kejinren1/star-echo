#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""collect_final.py — 定稿角色像素模型整合编号（主角 4 + Boss 8，按版本时间序）"""
import os, sys, re
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

# 角色 → 组名前缀匹配（按版本时间序收集）
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
            if not os.path.exists(p):
                continue
            if any(sub.startswith(pr) for pr, _ in prefixes):
                found.append((ver, sub, p))
    return found

def grid_view(items, cell, title, label):
    cols = min(len(items), 5)
    rows = (len(items) + cols - 1) // cols
    W, H = cols * cell, rows * cell
    canvas = Image.new("RGB", (W, H), (26, 26, 30))
    d = ImageDraw.Draw(canvas)
    f = font(label)
    for i, (idx, path) in enumerate(items):
        r, c = divmod(i, cols)
        x, y = c * cell, r * cell
        im = Image.open(path).convert("RGB").resize((cell, cell), Image.NEAREST)
        canvas.paste(im, (x, y))
        d.text((x + 5, y + 5), f"{title}·{idx}", fill=(255, 235, 60), font=f)
    return canvas

lines = []
for zh, prefixes in GROUPS.items():
    found = collect(prefixes)
    if not found:
        print(f"[空] {zh}", flush=True)
        continue
    items = [(f"{i+1:02d}", p) for i, (_, _, p) in enumerate(found)]
    cell = 380
    g = grid_view(items, cell, zh.split("BOSS")[-1][:4], 26)
    fname = f"选_{zh[:6]}.png"
    g.save(os.path.join(OUT, fname))
    lines.append(f"## {zh}（{len(items)} 张）→ {fname}")
    for i, (ver, sub, p) in enumerate(found):
        lines.append(f"  {i+1:02d} | {ver} | {sub}")
    print(f"{zh}: {len(items)} 张 → {fname}", flush=True)

with open(os.path.join(OUT, "编号清单.md"), "w", encoding="utf-8") as f:
    f.write("# 定稿角色像素模型 · 最终选择编号清单（2026-08-16）\n\n")
    f.write("> 选择方式：每张总览图内编号，回复「角色名+编号」即可\n\n")
    f.write("\n".join(lines))
print("清单已生成", flush=True)
