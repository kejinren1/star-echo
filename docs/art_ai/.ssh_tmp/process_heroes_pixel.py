#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""process_heroes_pixel.py — 主线角色 768 直出 → perfectPixel 96×96 精修 → 48/32 档 + 筛选拼版"""
import os, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, r"D:/30DAYS/docs/art_ai")
from perfect_pixel_noCV2 import get_perfect_pixel  # noqa

SRC = r"D:/30DAYS/docs/art_ai/output_comfy/style_test"
OUT = r"D:/30DAYS/docs/art_ai/output_abc/final_完美像素/主角团_20260815"
os.makedirs(OUT, exist_ok=True)

ROLES = [
    ("elin", "炎术师·艾琳", ["vA", "vB", "vC"]),
    ("noah", "魔导技师·诺亚", ["vA", "vB", "vC"]),
    ("lain", "剑士·莱恩", ["vA", "vB", "vC"]),
    ("siia", "医师·希亚", ["vA", "vB", "vC"]),
]

def font(sz):
    for p in [r"C:/Windows/Fonts/msyh.ttc", r"C:/Windows/Fonts/simhei.ttf"]:
        if os.path.exists(p):
            return ImageFont.truetype(p, sz)
    return ImageFont.load_default()

results = []
for hid, zh, variants in ROLES:
    for vk in variants:
        p = os.path.join(SRC, f"hero_{hid}_{vk}.png")
        if not os.path.exists(p):
            print(f"MISS {p}", flush=True)
            continue
        im = np.array(Image.open(p).convert("RGBA"))
        w, h, out = get_perfect_pixel(im, sample_method="median", min_size=4.0)
        out_im = Image.fromarray(out)
        for scale, tag in [(96, "96px"), (48, "48px"), (32, "32px")]:
            sz = (scale, scale)
            # 有透明则合成白底再缩，否则直接
            if out_im.mode == "RGBA":
                bg = Image.new("RGBA", out_im.size, (255, 255, 255, 255))
                bg.alpha_composite(out_im)
                out_im2 = bg.convert("RGB")
            else:
                out_im2 = out_im
            im_small = out_im2.resize(sz, Image.NEAREST)
            sub = os.path.join(OUT, hid, vk)
            os.makedirs(sub, exist_ok=True)
            im_small.save(os.path.join(sub, f"{tag}.png"))
        results.append((zh, vk, os.path.join(OUT, hid, vk, "96px.png")))
        print(f"OK {zh} {vk}: 精修 {out.shape}", flush=True)

# 拼版：4 角色 × 3 造型，96px 放大 5x = 480 格
CELL = 480
cols, rows = 3, 4
W, H = cols * CELL, rows * CELL
canvas = Image.new("RGB", (W, H), (30, 30, 34))
d = ImageDraw.Draw(canvas)
f = font(30)
for i, (zh, vk, path) in enumerate(results):
    r, c = divmod(i, cols)
    x, y = c * CELL, r * CELL
    im = Image.open(path).convert("RGB").resize((CELL, CELL), Image.NEAREST)
    canvas.paste(im, (x, y))
    d.text((x + 8, y + 8), f"{zh} {vk}", fill=(255, 255, 255), font=f)
canvas.save(os.path.join(OUT, "筛选总览_96px_x5.png"))
print("总览图:", canvas.size, flush=True)
