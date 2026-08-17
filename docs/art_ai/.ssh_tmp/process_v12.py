#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""process_v12.py — v12 批量 perfectPixel 精修 + 拼版"""
import os, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, r"D:/30DAYS/docs/art_ai")
from perfect_pixel_noCV2 import get_perfect_pixel  # noqa

SRC = r"D:/30DAYS/docs/art_ai/output_comfy/style_test"
OUT = r"D:/30DAYS/docs/art_ai/output_abc/final_完美像素/v12_20260816"
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
    p = os.path.join(SRC, f"v12_elin_mage_{k}.png")
    arr = np.array(Image.open(p).convert("RGBA"))
    perfect(f"v12_elin_mage_{k}", arr, f"elin_mage_{k}")
    elin_items.append((f"艾琳·#{k}", os.path.join(OUT, f"elin_mage_{k}", "96px.png")))
g = grid_view(elin_items, 3, 420, 24)
g.save(os.path.join(OUT, "筛选_艾琳_魔法师_v12.png"))
print("艾琳 v12", flush=True)

wolf_items = []
for k in [1, 2, 3, 4]:
    p = os.path.join(SRC, f"v12_wolf_{k}.png")
    arr = np.array(Image.open(p).convert("RGBA"))
    perfect(f"v12_wolf_{k}", arr, f"wolf_{k}")
    wolf_items.append((f"狼·#{k}", os.path.join(OUT, f"wolf_{k}", "96px.png")))
g = grid_view(wolf_items, 2, 420, 24)
g.save(os.path.join(OUT, "筛选_狼_四肢修正_v12.png"))
print("狼 v12", flush=True)
