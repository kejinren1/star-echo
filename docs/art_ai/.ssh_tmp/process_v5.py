#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""process_v5.py — v5 批量 perfectPixel 精修 + 4 张筛选拼版"""
import os, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, r"D:/30DAYS/docs/art_ai")
from perfect_pixel_noCV2 import get_perfect_pixel  # noqa

SRC = r"D:/30DAYS/docs/art_ai/output_comfy/style_test"
OUT = r"D:/30DAYS/docs/art_ai/output_abc/final_完美像素/v5_20260815"
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

BODY_ZH = {"mature": "御姐", "youth": "青年", "loli": "少女"}
for hid, zh in [("elin", "艾琳"), ("noah", "诺亚")]:
    items = []
    for bkey in ["mature", "youth", "loli"]:
        for k in [1, 2, 3]:
            p = os.path.join(SRC, f"v5_{hid}_{bkey}_{k}.png")
            if not os.path.exists(p):
                continue
            arr = np.array(Image.open(p).convert("RGBA"))
            perfect(f"v5_{hid}_{bkey}_{k}", arr, f"{hid}_{bkey}_{k}")
            items.append((f"{zh}·{BODY_ZH[bkey]}#{k}", os.path.join(OUT, f"{hid}_{bkey}_{k}", "96px.png")))
    g = grid_view(items, 3, 420, 24)
    g.save(os.path.join(OUT, f"筛选_{zh}_v5.png"))
    print(f"{zh} v5 {len(items)} 张", flush=True)

lain_items = []
for vk, vz in [("vA", "斑驳黑甲"), ("vB", "斑驳旅装"), ("vC", "斑驳仪仗")]:
    p = os.path.join(SRC, f"v5_lain_{vk}.png")
    arr = np.array(Image.open(p).convert("RGBA"))
    perfect(f"v5_lain_{vk}", arr, f"lain_{vk}")
    lain_items.append((f"莱恩·{vz}", os.path.join(OUT, f"lain_{vk}", "96px.png")))
g = grid_view(lain_items, 3, 420, 24)
g.save(os.path.join(OUT, "筛选_莱恩_v5.png"))
print("莱恩 v5", flush=True)

boss_items = [
    ("boss_03_gang_leader_v3", "③帮派首领v3"),
    ("boss_04_white_knight_v3", "④白铠骑士v3·露脸"),
    ("boss_05_werewolf_v3", "⑤四脚狼兽v3"),
    ("boss_07_goddess_v3", "⑦空洞女神v3"),
    ("boss_08_red_eye_v3", "⑧精细巨眼v3"),
]
items = []
for bid, bzh in boss_items:
    p = os.path.join(SRC, f"{bid}.png")
    arr = np.array(Image.open(p).convert("RGBA"))
    perfect(bid, arr, bid)
    items.append((bzh, os.path.join(OUT, bid, "96px.png")))
g = grid_view(items, 5, 420, 24)
g.save(os.path.join(OUT, "筛选_Boss_v3.png"))
print("Boss v3", g.size, flush=True)
