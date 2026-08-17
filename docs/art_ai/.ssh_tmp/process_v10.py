#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""process_v10.py — v10 批量 perfectPixel 精修 + 拼版"""
import os, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, r"D:/30DAYS/docs/art_ai")
from perfect_pixel_noCV2 import get_perfect_pixel  # noqa

SRC = r"D:/30DAYS/docs/art_ai/output_comfy/style_test"
OUT = r"D:/30DAYS/docs/art_ai/output_abc/final_完美像素/v10_20260816"
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

elin_items = []
for k in [1, 2, 3, 4, 5, 6]:
    p = os.path.join(SRC, f"v10_elin_mage_{k}.png")
    arr = np.array(Image.open(p).convert("RGBA"))
    perfect(f"v10_elin_mage_{k}", arr, f"elin_mage_{k}")
    elin_items.append((f"艾琳·#{k}", os.path.join(OUT, f"elin_mage_{k}", "96px.png")))
g = grid_view(elin_items, 3, 420, 24)
g.save(os.path.join(OUT, "筛选_艾琳_魔法师_v10.png"))
print("艾琳 v10 6 张", flush=True)

BODY_ZH = {"mature": "御姐", "youth": "青年", "loli": "少女"}
noah_items = []
for bkey in ["mature", "youth", "loli"]:
    p = os.path.join(SRC, f"v10_noah_{bkey}.png")
    arr = np.array(Image.open(p).convert("RGBA"))
    perfect(f"v10_noah_{bkey}", arr, f"noah_{bkey}")
    noah_items.append((f"诺亚·{BODY_ZH[bkey]}", os.path.join(OUT, f"noah_{bkey}", "96px.png")))
g = grid_view(noah_items, 3, 420, 24)
g.save(os.path.join(OUT, "筛选_诺亚_科研服_v10.png"))
print("诺亚 v10", flush=True)

boss_items = [
    ("v10_boss_04_light_knight", "④青年白蓝金骑士"),
    ("v10_boss_05_wolf", "⑤紫黑红眼长尾狼"),
]
items = []
for bid, bzh in boss_items:
    p = os.path.join(SRC, f"{bid}.png")
    arr = np.array(Image.open(p).convert("RGBA"))
    perfect(bid, arr, bid)
    items.append((bzh, os.path.join(OUT, bid, "96px.png")))
g = grid_view(items, 2, 420, 24)
g.save(os.path.join(OUT, "筛选_Boss_v10.png"))
print("Boss v10", g.size, flush=True)
