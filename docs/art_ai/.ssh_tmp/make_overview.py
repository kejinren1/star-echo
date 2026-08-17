#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""拼 B_pixel 筛选总览图：12 角色 × 64px 放大 + 512 像素缩略"""
import os
from PIL import Image, ImageDraw, ImageFont

ROOT = r"D:/30DAYS/docs/art_ai/output_abc/B_pixel"
OUT = os.path.join(ROOT, "筛选总览")
os.makedirs(OUT, exist_ok=True)
CHARS = ["安洁莉娜", "傀影", "棘刺", "狮蝎", "维什戴尔", "若叶睦",
         "莱欧斯", "赫拉格", "遥", "重岳", "陈", "龙舌兰"]

def font(sz):
    for p in [r"C:/Windows/Fonts/msyh.ttc", r"C:/Windows/Fonts/simhei.ttf"]:
        if os.path.exists(p):
            return ImageFont.truetype(p, sz)
    return ImageFont.load_default()

def grid(imgs, titles, cols, cell, label):
    rows = (len(imgs) + cols - 1) // cols
    W, H = cols * cell, rows * cell
    canvas = Image.new("RGB", (W, H), (24, 24, 26))
    d = ImageDraw.Draw(canvas)
    f = font(label)
    for i, (im, t) in enumerate(zip(imgs, titles)):
        r, c = divmod(i, cols)
        x, y = c * cell, r * cell
        im = im.convert("RGBA")
        bg = Image.new("RGBA", (cell, cell), (24, 24, 26, 255))
        if im.size != (cell, cell):
            im = im.resize((cell, cell), Image.NEAREST)
        bg.alpha_composite(im)
        canvas.paste(bg.convert("RGB"), (x, y))
        d.text((x + 6, y + 6), t, fill=(240, 240, 240), font=f)
    return canvas

g1 = grid([Image.open(f"{ROOT}/{c}/64px.png") for c in CHARS], CHARS, 4, 384, 30)
g1.save(f"{OUT}/筛选总览_64px放大6x.png")
print("图1 OK:", g1.size)

g2 = grid([Image.open(f"{ROOT}/{c}/512_pixel.png") for c in CHARS], CHARS, 4, 160, 22)
g2.save(f"{OUT}/筛选总览_512像素缩略.png")
print("图2 OK:", g2.size)

g3 = grid([Image.open(f"{ROOT}/{c}/64px_quant.png") for c in CHARS], CHARS, 4, 384, 30)
g3.save(f"{OUT}/筛选总览_64px量化放大6x.png")
print("图3 OK:", g3.size)
