#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""process_v7.py — v7 批量 perfectPixel 精修 + 拼版"""
import os, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, r"D:/30DAYS/docs/art_ai")
from perfect_pixel_noCV2 import get_perfect_pixel  # noqa

SRC = r"D:/30DAYS/docs/art_ai/output_comfy/style_test"
OUT = r"D:/30DAYS/docs/art_ai/output_abc/final_完美像素/v7_20260815"
os.makedirs(OUT, exist_ok=True)

def font(sz):
    for p in [r"C:/Windows/Fonts/msyh.ttc", r"C:/Windows/Fonts/simhei.ttf"]:
        if os.path.exists(p):
            return ImageFont.truetype(p, sz)
    return ImageFont.load_default()

def perfect(name, im_arr, sub):
    try:
        w, h, out = get_perfect_pixel(im_arr, sample_method="median", min_size=4.0)
        out_im = Image.fromarray(out)
    except Exception as e:
        out_im = Image.fromarray(im_arr)
    os.makedirs(os.path.join(OUT, sub), exist_ok=True)
    for scale, tag in [(96, "96px"), (48, "48px"), (32, "32px")]:
        if out_im.mode == "RGBA":
            bg = Image.new("RGBA", out_im.size, (255, 255, 255, 255))
            bg.alpha_composite(out_im)
            img = bg.convert("RGB")
        else:
            img = out_im
        img.resize((scale, scale), Image.NEAREST).save(os.path.join(OUT, sub, f"{tag}.png"))

def grid_view(items, cols, cell, label):
    rows = (len(items) + cols - 1) // cols
    W, H = cols * cell, rows * cell
    canvas = Image.new("RGB", (W, H), (30, 30, 34))
    d = ImageDraw.Draw(canvas)
    f = font(label)
    for i, (title, path) in enumerate(items):
        r, c = divmod(i, cols)
        x, y = c * cell, r * cell
        im = Image.open(path).convert("RGB").resize((cell, cell), Image.NEAREST)
        canvas.paste(im, (x, y))
        d.text((x + 6, y + 6), title, fill=(255, 255, 255), font=f)
    return canvas

# 艾琳 萝莉 3
elin_items = []
for k in [1, 2, 3]:
    p = os.path.join(SRC, f"v7_elin_loli_{k}.png")
    arr = np.array(Image.open(p).convert("RGBA"))
    perfect(f"v7_elin_loli_{k}", arr, f"elin_loli_{k}")
    elin_items.append((f"艾琳·萝莉#{k}", os.path.join(OUT, f"elin_loli_{k}", "96px.png")))
g = grid_view(elin_items, 3, 420, 24)
g.save(os.path.join(OUT, "筛选_艾琳_萝莉_v7.png"))
print("艾琳 v7", flush=True)

# 诺亚 魔法朋克 3体型×2
BODY_ZH = {"mature": "御姐", "youth": "青年", "loli": "少女"}
noah_items = []
for bkey in ["mature", "youth", "loli"]:
    for k in [1, 2]:
        p = os.path.join(SRC, f"v7_noah_{bkey}_{k}.png")
        arr = np.array(Image.open(p).convert("RGBA"))
        perfect(f"v7_noah_{bkey}_{k}", arr, f"noah_{bkey}_{k}")
        noah_items.append((f"诺亚·{BODY_ZH[bkey]}#{k}", os.path.join(OUT, f"noah_{bkey}_{k}", "96px.png")))
g = grid_view(noah_items, 3, 420, 24)
g.save(os.path.join(OUT, "筛选_诺亚_魔法朋克_v7.png"))
print("诺亚 v7", flush=True)

# 莱恩 3
lain_items = []
for vk, vz in [("vA", "侧身斑驳黑甲"), ("vB", "侧身斑驳旅装"), ("vC", "侧身斑驳仪仗")]:
    p = os.path.join(SRC, f"v7_lain_{vk}.png")
    arr = np.array(Image.open(p).convert("RGBA"))
    perfect(f"v7_lain_{vk}", arr, f"lain_{vk}")
    lain_items.append((f"莱恩·{vz}", os.path.join(OUT, f"lain_{vk}", "96px.png")))
g = grid_view(lain_items, 3, 420, 24)
g.save(os.path.join(OUT, "筛选_莱恩_侧身_v7.png"))
print("莱恩 v7", flush=True)

# Boss 修正 4
boss_items = [
    ("v7_boss_02_mage", "②消瘦黑魔法师v7"),
    ("v7_boss_04_light_knight", "④光系主角骑士v7"),
    ("v7_boss_05_wolf", "⑤修长狼兽v7"),
    ("v7_boss_07_goddess", "⑦全身空洞女神v7"),
]
items = []
for bid, bzh in boss_items:
    p = os.path.join(SRC, f"{bid}.png")
    arr = np.array(Image.open(p).convert("RGBA"))
    perfect(bid, arr, bid)
    items.append((bzh, os.path.join(OUT, bid, "96px.png")))
g = grid_view(items, 4, 420, 24)
g.save(os.path.join(OUT, "筛选_Boss_v7.png"))
print("Boss v7", g.size, flush=True)
