#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""resolve_final.py — 解析用户最终选择编号 → 归档路径 + 生成定稿总览"""
import os, sys, shutil
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = r"D:/30DAYS/docs/art_ai/output_abc/final_完美像素"
FINAL = r"D:/30DAYS/docs/art_ai/output_abc/final_完美像素/定稿_20260816"
os.makedirs(FINAL, exist_ok=True)

def font(sz):
    for p in [r"C:/Windows/Fonts/msyh.ttc", r"C:/Windows/Fonts/simhei.ttf"]:
        if os.path.exists(p):
            return ImageFont.truetype(p, sz)
    return ImageFont.load_default()

GROUPS = {
    "艾琳": [("elin",)], "诺亚": [("noah",)], "莱恩": [("lain",)], "希亚": [("siia",)],
    "BOSS①魔族女战士": [("boss_01",), ("v8_boss_01",)],
    "BOSS②黑魔法师": [("boss_02",), ("v7_boss_02",), ("v8_boss_02",)],
    "BOSS③帮派首领": [("boss_03",), ("v8_boss_03",)],
    "BOSS④白蓝金骑士": [("boss_04",), ("v7_boss_04",), ("v8_boss_04",), ("v9_boss_04",), ("v10_boss_04",)],
    "BOSS⑤病态狼兽": [("boss_05",), ("v7_boss_05",), ("v8_boss_05",), ("v9_boss_05",), ("v10_boss_05",), ("v11_boss_05",), ("wolf",)],
    "BOSS⑥牛头人": [("boss_06",), ("v8_boss_06",)],
    "BOSS⑦空洞女神": [("boss_07",), ("v7_boss_07",)],
    "BOSS⑧不详之镜": [("boss_08",), ("v8_boss_08",)],
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
            if os.path.exists(p) and any(sub.startswith(pr) for pr in prefixes):
                found.append((ver, sub, p))
    return found

PICKS = {
    "艾琳": 54, "诺亚": 50, "莱恩": 17, "希亚": 12,
    "BOSS①魔族女战士": 3, "BOSS②黑魔法师": 4, "BOSS③帮派首领": 4,
    "BOSS④白蓝金骑士": 7, "BOSS⑤病态狼兽": 27, "BOSS⑥牛头人": 3,
    "BOSS⑦空洞女神": 4, "BOSS⑧不详之镜": 4,
}
# 用户挑图时参考的编号体系：默认分页矩阵黄字（0 起）；
# BOSS③⑤⑥⑧ 用户看的是第一版总览图（1 起），需按 1 起解析
BASE_ONE = {"BOSS③帮派首领", "BOSS⑤病态狼兽", "BOSS⑥牛头人", "BOSS⑧不详之镜"}

report = []
final_items = []
for zh, idx in PICKS.items():
    found = collect(GROUPS[zh])
    # 编号体系：0 起 = 分页矩阵图黄字（与 collect_final2.py 一致）；1 起 = 第一版总览图/编号清单
    if zh in BASE_ONE:
        # 1 起：第一版总览图/编号清单/编号对照 PNG
        if idx < 1 or idx > len(found):
            report.append(f"❌ {zh} 编号 {idx} 越界（1~{len(found)}）")
            continue
        ver, sub, p = found[idx - 1]
        base_tag = "1起"
    else:
        # 0 起：分页矩阵图黄字；边界 idx == len(found)（如希亚 12 在 12 张中）取最后一张
        if idx < 0 or idx >= len(found):
            if idx == len(found):
                ver, sub, p = found[-1]
            else:
                report.append(f"❌ {zh} 编号 {idx} 越界（0~{len(found)-1}）")
                continue
        else:
            ver, sub, p = found[idx]
        base_tag = "0起"
    dst = os.path.join(FINAL, zh)
    os.makedirs(dst, exist_ok=True)
    for tag in ["96px", "48px", "32px"]:
        src = os.path.join(os.path.dirname(p), f"{tag}.png")
        if os.path.exists(src):
            shutil.copy2(src, os.path.join(dst, f"{tag}.png"))
    report.append(f"✅ {zh} #{idx} [{base_tag}] → {ver} / {sub}")
    final_items.append((zh, os.path.join(dst, "96px.png")))
    print(f"{zh} #{idx} → {ver}/{sub}", flush=True)

with open(os.path.join(FINAL, "定稿清单.md"), "w", encoding="utf-8") as f:
    f.write("# 定稿角色像素模型 · 最终版（2026-08-16）\n\n")
    f.write("> ⚠️ 编号体系：主角+Boss①④⑦=分页矩阵黄字（0 起）；BOSS③⑤⑥⑧=第一版总览图（1 起）。混用不同文件编号会错位，以本清单为准。\n\n")
    f.write("\n".join(f"- {r}" for r in report))

# 定稿总览图
cell = 380
cols = 6
rows = (len(final_items) + cols - 1) // cols
W, H = cols * cell, rows * cell
canvas = Image.new("RGB", (W, H), (26, 26, 30))
d = ImageDraw.Draw(canvas)
f = font(24)
for i, (zh, path) in enumerate(final_items):
    r, c = divmod(i, cols)
    x, y = c * cell, r * cell
    im = Image.open(path).convert("RGB").resize((cell, cell), Image.NEAREST)
    canvas.paste(im, (x, y))
    d.text((x + 6, y + 6), zh[:6], fill=(255, 235, 60), font=f)
canvas.save(os.path.join(FINAL, "定稿总览_12角色.png"))
print("定稿总览:", canvas.size, flush=True)
