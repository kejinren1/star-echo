#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""统计 32px 白底图的非白色前景占比。用法: python _fg_ratio.py <png...>"""
import sys
from PIL import Image

def fg_ratio(path):
    img = Image.open(path).convert("RGB")
    px = img.getdata()
    total = len(px)
    nonwhite = sum(1 for r, g, b in px if (r, g, b) != (255, 255, 255))
    return nonwhite / total

if __name__ == "__main__":
    for p in sys.argv[1:]:
        print(f"{p}\t{fg_ratio(p)*100:.1f}%")
