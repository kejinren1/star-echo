#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""process_v4.py — v4 批量 perfectPixel 精修 + 5 张筛选拼版"""
import os, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, r"D:/30DAYS/docs/art_ai")
from perfect_pixel_noCV2 import get_perfect_pixel  # noqa

SRC = r"D:/30DAYS/docs/art_ai/output_comfy/style_test"
OUT = r"D:/30DAYS/docs/art_ai/output_abc/final_完美像素/v4_20260815"
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
        grid = f"{out_im.size[0]}x{out_im.size[1]}"
    except Exception as e:
        out_im = Image.fromarray(im_arr)
        grid = f"fb:{str(e)[:30]}"
    os.makedirs(os.path.join(OUT, sub), exist_ok=True)
    for scale, tag in [(96, "96px"), (48, "48px"), (32, "32px")]:
        if out_im.mode == "RGBA":
            bg = Image.new("RGBA", out_im.size, (255, 255, 255, 255))
            bg.alpha_composite(out_im)
            img = bg.convert("RGB")
        else:
            img = out_im
        img.resize((scale, scale), Image.NEAREST).save(os.path.join(OUT, sub, f"{tag}.png"))
    return grid

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
GIRL_ZH = {"elin": "艾琳", "noah": "诺亚", "siia": "希亚"}

for hid, zh in GIRL_ZH.items():
    items = []
    for bkey in ["mature", "youth", "loli"]:
        for k in [1, 2, 3]:
            p = os.path.join(SRC, f"girl_{hid}_{bkey}_{k}.png")
            if not os.path.exists(p):
                continue
            arr = np.array(Image.open(p).convert("RGBA"))
            grid = perfect(f"girl_{hid}_{bkey}_{k}", arr, f"{hid}_{bkey}_{k}")
            items.append((f"{zh}·{BODY_ZH[bkey]}#{k}", os.path.join(OUT, f"{hid}_{bkey}_{k}", "96px.png")))
    g = grid_view(items, 3, 420, 24)
    g.save(os.path.join(OUT, f"筛选_{zh}_3体型x3.png"))
    print(f"{zh} 总览 {len(items)} 张 {g.size}", flush=True)

lain_items = []
for vk, vz in [("vA", "黑甲骑士"), ("vB", "黑衣剑客"), ("vC", "黑金卫")]:
    p = os.path.join(SRC, f"hero_lain_{vk}.png")
    arr = np.array(Image.open(p).convert("RGBA"))
    grid = perfect(f"hero_lain_{vk}", arr, f"lain_{vk}")
    lain_items.append((f"莱恩·{vz}", os.path.join(OUT, f"lain_{vk}", "96px.png")))
g = grid_view(lain_items, 3, 420, 24)
g.save(os.path.join(OUT, "筛选_莱恩_3造型.png"))
print("莱恩总览", g.size, flush=True)

BOSS_ZH = [
    ("boss_01_demon_warrior_v2", "①魔族女战士"),
    ("boss_02_dark_mage_v2", "②黑魔法师"),
    ("boss_03_gang_leader_v2", "③帮派首领"),
    ("boss_04_white_knight_v2", "④白铠骑士"),
    ("boss_05_werewolf_beast_v2", "⑤狼魔兽"),
    ("boss_06_minotaur_v2", "⑥牛头人"),
    ("boss_07_goddess_v2", "⑦黑礼服女神"),
    ("boss_08_red_eye_v2", "⑧血色巨眼"),
]
boss_items = []
for bid, bzh in BOSS_ZH:
    p = os.path.join(SRC, f"{bid}.png")
    arr = np.array(Image.open(p).convert("RGBA"))
    grid = perfect(bid, arr, bid)
    boss_items.append((bzh, os.path.join(OUT, bid, "96px.png")))
g = grid_view(boss_items, 4, 420, 24)
g.save(os.path.join(OUT, "筛选_Boss_v2.png"))
print("Boss 总览", g.size, flush=True)
