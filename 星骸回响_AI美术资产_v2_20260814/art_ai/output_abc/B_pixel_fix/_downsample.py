#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""对 B_pixel_fix/<角色>/d0X/512_pixel.png 做 nearest 降采样 128/64/32，并统计 32px 前景占比。"""
import sys
from pathlib import Path
from PIL import Image

ROOT = Path(r"D:/30DAYS/docs/art_ai/output_abc/B_pixel_fix")
ROLES = ["龙舌兰", "陈", "维什戴尔"]
DENOISES = ["d06", "d07"]

def fg_ratio(path):
    img = Image.open(path).convert("RGB")
    px = list(img.getdata())
    total = len(px)
    nonwhite = sum(1 for r, g, b in px if (r, g, b) != (255, 255, 255))
    return nonwhite / total

for role in ROLES:
    for dn in DENOISES:
        src = ROOT / role / dn / "512_pixel.png"
        if not src.exists():
            print(f"[缺失] {src}")
            continue
        img = Image.open(src).convert("RGB")
        for size in (128, 64, 32):
            small = img.resize((size, size), Image.Resampling.NEAREST)
            small.save(ROOT / role / dn / f"{size}px.png")
        ratio = fg_ratio(ROOT / role / dn / "32px.png")
        print(f"{role}/{dn}: 32px 前景占比 {ratio*100:.1f}%")
print("DONE")
