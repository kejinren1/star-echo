#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""cleanup_sheet_edges.py — 已透明 sheet 的白色/浅灰背景残留清理
规则：alpha≥250 且 近似白/浅灰（低饱和+高亮度）且 4-邻域存在透明像素 → 置透明
安全：主体内部同色像素不与透明区相邻，不受影响；dry-run 先看影响面。
用法: python cleanup_sheet_edges.py [--apply] [--files f1 f2 ...]
"""
import argparse
import glob
import sys
from pathlib import Path

from PIL import Image

SPRITES = Path("D:/30DAYS/assets/sprites")


def is_white_gray(p, tol=18, lum=190):
    r, g, b = p[0], p[1], p[2]
    return max(r, g, b) - min(r, g, b) < tol and (r + g + b) / 3 > lum


def clean(im: Image.Image) -> tuple[Image.Image, int]:
    im = im.convert("RGBA")
    w, h = im.size
    px = im.load()
    removed = 0
    for y in range(h):
        for x in range(w):
            p = px[x, y]
            if p[3] < 250:
                continue
            if not is_white_gray(p):
                continue
            # 4-邻域有透明像素？
            neighbors = []
            if x > 0: neighbors.append(px[x - 1, y])
            if x < w - 1: neighbors.append(px[x + 1, y])
            if y > 0: neighbors.append(px[x, y - 1])
            if y < h - 1: neighbors.append(px[x, y + 1])
            if any(n[3] < 250 for n in neighbors):
                px[x, y] = (0, 0, 0, 0)
                removed += 1
    return im, removed


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true", help="写盘（默认 dry-run）")
    ap.add_argument("--files", nargs="*", default=None, help="指定文件，默认全 sprite 目录")
    args = ap.parse_args()

    if args.files:
        files = [Path(f) for f in args.files]
    else:
        files = []
        for d in ("characters", "enemies", "effects", "ui", "skills"):
            files += sorted((SPRITES / d).glob("*.png"))
        files = [f for f in files if "tileset" not in f.name]  # 贴图本就该不透明

    total = 0
    for f in files:
        im = Image.open(f).convert("RGBA")
        w, h = im.size
        # 只处理有透明区的 sheet
        px = list(im.getdata())
        if not any(p[3] < 250 for p in px):
            continue
        cleaned, removed = clean(im)
        if removed > 0:
            total += removed
            flag = "写盘" if args.apply else "dry"
            print(f"[{flag}] {f.relative_to(SPRITES)}: 清除 {removed} 像素")
            if args.apply:
                cleaned.save(f)
    print(f"=== 共清理 {total} 像素（{'已写盘' if args.apply else 'dry-run 未写盘'}） ===")


if __name__ == "__main__":
    main()
