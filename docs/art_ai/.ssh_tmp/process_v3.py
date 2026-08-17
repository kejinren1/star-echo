#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""process_v3.py — 主角团 v3 + Boss 8：perfectPixel 96×96 精修 + 48/32 + 双拼版"""
import os, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, r"D:/30DAYS/docs/art_ai")
from perfect_pixel_noCV2 import get_perfect_pixel  # noqa

SRC = r"D:/30DAYS/docs/art_ai/output_comfy/style_test"
OUT = r"D:/30DAYS/docs/art_ai/output_abc/final_完美像素/v3_20260815"
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
        grid = f"fallback:{str(e)[:40]}"
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
        d.text((x + 8, y + 8), title, fill=(255, 255, 255), font=f)
    return canvas

# 主角 12
HERO_TITLES = {
    ("elin", "vA"): "艾琳vA 经典尖帽", ("elin", "vB"): "艾琳vB 旅行宽檐", ("elin", "vC"): "艾琳vC 华丽高帽",
    ("noah", "vA"): "诺亚vA 蒸汽工程师", ("noah", "vB"): "诺亚vB 炼金旅人", ("noah", "vC"): "诺亚vC 皇家学者",
    ("lain", "vA"): "莱恩vA 黑曜骑士", ("lain", "vB"): "莱恩vB 黑衣剑客", ("lain", "vC"): "莱恩vC 黑金卫",
    ("siia", "vA"): "希亚vA 牧师", ("siia", "vB"): "希亚vB 旅医", ("siia", "vC"): "希亚vC 圣徒",
}
hero_items = []
for hid in ["elin", "noah", "lain", "siia"]:
    for vk in ["vA", "vB", "vC"]:
        p = os.path.join(SRC, f"hero_{hid}_{vk}.png")
        if not os.path.exists(p):
            print(f"MISS {p}", flush=True)
            continue
        arr = np.array(Image.open(p).convert("RGBA"))
        grid = perfect(f"hero_{hid}_{vk}", arr, f"{hid}_{vk}")
        hero_items.append((HERO_TITLES[(hid, vk)], os.path.join(OUT, f"{hid}_{vk}", "96px.png")))
        print(f"hero_{hid}_{vk}: {grid}", flush=True)

# Boss 8
BOSS_TITLES = [
    ("boss_01_demon_warrior", "①魔族女战士"),
    ("boss_02_dark_mage", "②消瘦黑魔法师"),
    ("boss_03_gang_leader", "③恶魔契约帮派首领"),
    ("boss_04_white_knight", "④白色铠甲骑士"),
    ("boss_05_werewolf_beast", "⑤扭曲狼魔兽"),
    ("boss_06_minotaur", "⑥牛头人战士"),
    ("boss_07_goddess", "⑦黑礼服女神"),
    ("boss_08_red_eye", "⑧血色巨眼"),
]
boss_items = []
for bid, bzh in BOSS_TITLES:
    p = os.path.join(SRC, f"{bid}.png")
    if not os.path.exists(p):
        print(f"MISS {p}", flush=True)
        continue
    arr = np.array(Image.open(p).convert("RGBA"))
    grid = perfect(bid, arr, bid)
    boss_items.append((bzh, os.path.join(OUT, bid, "96px.png")))
    print(f"{bid}: {grid}", flush=True)

g1 = grid_view(hero_items, 3, 480, 30)
g1.save(os.path.join(OUT, "筛选_主角团_96px_x5.png"))
print("主角团总览:", g1.size, flush=True)
g2 = grid_view(boss_items, 4, 420, 26)
g2.save(os.path.join(OUT, "筛选_Boss_96px_x4p4.png"))
print("Boss 总览:", g2.size, flush=True)
