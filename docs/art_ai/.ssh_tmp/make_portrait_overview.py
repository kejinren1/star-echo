#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""make_portrait_overview.py — 12 角色立绘 A/B 路线对照拼版 + 总览"""
import os, sys
from PIL import Image, ImageDraw, ImageFont

SRC = r"D:/30DAYS/docs/art_ai/output_comfy/style_test"
OUT = r"D:/30DAYS/docs/art_ai/output_comfy/portraits_20260816"
os.makedirs(OUT, exist_ok=True)

CHARS = [
    ("elin", "艾琳·炎术师"), ("noah", "诺亚·魔导技师"), ("lain", "莱恩·剑士"), ("siia", "希亚·医师"),
    ("b01", "BOSS①魔族女战士"), ("b02", "BOSS②黑魔法师"), ("b03", "BOSS③帮派首领"), ("b04", "BOSS④白蓝金骑士"),
    ("b05", "BOSS⑤病态狼兽"), ("b06", "BOSS⑥牛头人"), ("b07", "BOSS⑦空洞女神"), ("b08", "BOSS⑧不详之镜"),
]

def font(sz):
    for p in [r"C:/Windows/Fonts/msyh.ttc", r"C:/Windows/Fonts/simhei.ttf"]:
        if os.path.exists(p):
            return ImageFont.truetype(p, sz)
    return ImageFont.load_default()

def load(key, route, n):
    p = os.path.join(SRC, f"port_{key}_{route}_{n}.png")
    return Image.open(p).convert("RGB") if os.path.exists(p) else None

# 每角色一张对照图：标题 + A1 A2 / B1 B2（2×2）
CELL = 400
for key, zh in CHARS:
    imgs = {}
    for route in ["A", "B"]:
        for n in [1, 2]:
            imgs[f"{route}{n}"] = load(key, route, n)
    ok = [v for v in imgs.values() if v]
    if not ok:
        print(f"[缺] {zh} 无图", flush=True)
        continue
    canvas = Image.new("RGB", (CELL * 2 + 60, CELL * 2 + 90), (22, 22, 26))
    d = ImageDraw.Draw(canvas)
    d.text((12, 10), f"{zh}  |  A=虹膜强化  B=简洁", fill=(255, 235, 60), font=font(28))
    for idx, (tag, im) in enumerate(imgs.items()):
        if im is None:
            continue
        r, c = divmod(idx, 2)
        x, y = 10 + c * (CELL + 20), 60 + r * (CELL + 20)
        canvas.paste(im.resize((CELL, CELL), Image.LANCZOS), (x, y))
        d.text((x + 6, y + 6), tag, fill=(255, 255, 255), font=font(22))
    canvas.save(os.path.join(OUT, f"立绘_{key}_{zh[:8]}.png"))
    print(f"[OK] {zh}", flush=True)

# 总览：12 角色 × 路线 B（A 或 B 取 1 号）网格
grid = []
for key, zh in CHARS:
    im = load(key, "B", 1) or load(key, "A", 1)
    if im:
        grid.append((zh, im))
cols = 4
rows = (len(grid) + cols - 1) // cols
cell = 340
W, H = cols * cell, rows * cell
canvas = Image.new("RGB", (W, H), (20, 20, 24))
d = ImageDraw.Draw(canvas)
for i, (zh, im) in enumerate(grid):
    r, c = divmod(i, cols)
    x, y = c * cell, r * cell
    canvas.paste(im.resize((cell, cell), Image.LANCZOS), (x, y))
    d.text((x + 6, y + 6), zh[:10], fill=(255, 235, 60), font=font(22))
canvas.save(os.path.join(OUT, "总览_12角色_路线B.png"))
print("总览:", canvas.size, flush=True)
print("ALL_DONE", flush=True)
