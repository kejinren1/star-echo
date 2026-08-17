#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""make_prod_overview.py — 24 张量产立绘拼版：总览 + 每角色对照"""
import os
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

def load(key, n):
    p = os.path.join(SRC, f"prod_{key}_g{n}.png")
    return Image.open(p).convert("RGB") if os.path.exists(p) else None

# 每角色 g1/g2 对照（1×2）
CELL = 400
for key, zh in CHARS:
    im1, im2 = load(key, 1), load(key, 2)
    if not im1 or not im2:
        print(f"[缺] {zh}", flush=True)
        continue
    canvas = Image.new("RGB", (CELL * 2 + 40, CELL + 70), (22, 22, 26))
    d = ImageDraw.Draw(canvas)
    d.text((12, 10), f"{zh}  |  变体 g1 / g2", fill=(255, 235, 60), font=font(28))
    canvas.paste(im1.resize((CELL, CELL), Image.LANCZOS), (10, 60))
    canvas.paste(im2.resize((CELL, CELL), Image.LANCZOS), (CELL + 30, 60))
    d.text((10, 66), "g1", fill=(255, 255, 255), font=font(22))
    d.text((CELL + 30, 66), "g2", fill=(255, 255, 255), font=font(22))
    canvas.save(os.path.join(OUT, f"量产_{key}_{zh[:8]}.png"))
    print(f"[OK] {zh}", flush=True)

# 总览 4x6：12 角色 × g1（第一列 g1，第二列 g2 → 8列×3行）
cell = 250
cols, rows = 8, 3
W, H = cols * cell, rows * cell
canvas = Image.new("RGB", (W, H), (20, 20, 24))
d = ImageDraw.Draw(canvas)
for i, (key, zh) in enumerate(CHARS):
    for n in (1, 2):
        im = load(key, n)
        if im is None:
            continue
        r, c = divmod(i * 2 + (n - 1), cols)
        x, y = c * cell, r * cell
        canvas.paste(im.resize((cell, cell), Image.LANCZOS), (x, y))
        if n == 1:
            d.text((x + 4, y + 4), zh[:8], fill=(255, 235, 60), font=font(18))
canvas.save(os.path.join(OUT, "总览_12角色x2变体.png"))
print("总览:", canvas.size, flush=True)
print("ALL_DONE", flush=True)
