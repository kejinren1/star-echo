#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
cutout_bg.py —— 角色素材抠透明底工具（Star Echo 项目常备，2026-08-05 沉淀）

适用：从「带浅色/纯色方块背景」的角色截图/合成图中抠出透明底素材。
核心方法（经多轮实测，见 .workbuddy/memory/2026-08-05.md）：
  1. 色度判据：R≈G≈B（无色相）且亮度高 的像素 = 背景（角色即使浅色也带色相）
  2. 自适应阈值扫描：对 (sat_thr, lum_thr) 组合扫描，选「边缘残留 ≤15% 且覆盖最高」者
     —— 角色浅色与浅灰背景颜色接近时，这是颜色类算法的物理极限
  3. 管线：抠出 → 缩放 → alpha 硬化 → 32 色 MEDIANCUT 量化 → 1px 深色描边

可选 --backend rembg：对「纯角色图/透明底友好图」可用语义分割（isnet-anime/u2net/silueta，
模型缓存 ~/.u2net/）；但对「UI 截图式方块」实测无效（模型把方块整体当前景）。

用法：
  python tools/cutout_bg.py <input.png> -o out.png [--size 64 64] [--backend color|rembg]
  python tools/cutout_bg.py <input_dir> -o out_dir --batch
"""
import argparse
import os
import sys

import cv2
import numpy as np
from PIL import Image


def find_content_boxes(im_bgr, min_area=5000):
    """在白色背景上找内容方块（用于截图批量切块），返回 [(x,y,w,h)] 按 y 排序。"""
    rgb = cv2.cvtColor(im_bgr, cv2.COLOR_BGR2RGB)
    mask = ((rgb[:, :, 0] < 245) | (rgb[:, :, 1] < 245) | (rgb[:, :, 2] < 245)).astype(np.uint8) * 255
    k = np.ones((12, 12), np.uint8)
    mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, k)
    mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, k)
    contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    boxes = []
    for c in contours:
        x, y, w, h = cv2.boundingRect(c)
        if 60 < w < 260 and 60 < h < 260 and w * h > min_area:
            boxes.append((x, y, w, h))
    boxes.sort(key=lambda b: b[1])
    return boxes


def color_cutout(crop_bgr, sat_thr=12, lum_thr=170):
    """色度判据抠图：无色相且亮 = 背景。返回 RGBA uint8。"""
    rgb = cv2.cvtColor(crop_bgr, cv2.COLOR_BGR2RGB).astype(int)
    mx, mn = rgb.max(axis=2), rgb.min(axis=2)
    lum = rgb.mean(axis=2)
    is_bg = (mx - mn < sat_thr) & (lum > lum_thr)
    alpha = np.where(is_bg, 0, 255).astype(np.uint8)
    return np.dstack([rgb.astype(np.uint8), alpha])


def best_threshold(crop_bgr):
    """扫描 (sat, lum)，返回边缘残留 ≤15% 且覆盖最高的参数。"""
    rgb = cv2.cvtColor(crop_bgr, cv2.COLOR_BGR2RGB).astype(int)
    mx, mn = rgb.max(axis=2), rgb.min(axis=2)
    lum = rgb.mean(axis=2)
    h, w = rgb.shape[:2]
    ring = np.zeros((h, w), bool)
    ring[0:4, :] = ring[-4:, :] = ring[:, 0:4] = ring[:, -4:] = True
    best = None
    for sat_thr in range(8, 25):
        for lum_thr in range(140, 190, 10):
            keep = ~((mx - mn < sat_thr) & (lum > lum_thr))
            edge = (keep & ring).sum() / ring.sum() * 100
            cov = keep.mean() * 100
            score = cov if edge <= 15 else cov * 0.3
            if best is None or score > best[0]:
                best = (score, edge, cov, sat_thr, lum_thr)
    return best[3], best[4]


def rembg_cutout(crop_bgr, model='u2net'):
    """语义抠图（可选后端；对 UI 截图式方块无效，仅适用于纯角色图）。"""
    from rembg import remove, new_session
    session = new_session(model)
    pil = Image.fromarray(cv2.cvtColor(crop_bgr, cv2.COLOR_BGR2RGB))
    return np.array(remove(pil, session=session).convert('RGBA'))


def quantize_32(pil_rgba):
    rgb = np.array(pil_rgba.convert('RGB'))
    q = Image.fromarray(rgb).quantize(colors=32, method=Image.Quantize.MEDIANCUT).convert('RGB')
    a = np.array(pil_rgba)[:, :, 3]
    return Image.fromarray(np.dstack([np.array(q), a]), 'RGBA')


def add_1px_outline(pil_rgba):
    a = np.array(pil_rgba)
    rgb, alpha = a[:, :, :3], a[:, :, 3]
    mask = alpha > 128
    if not mask.any():
        return pil_rgba
    pixels = rgb[mask]
    lum = pixels.mean(axis=1)
    dark = pixels[lum < np.percentile(lum, 8)]
    if len(dark) == 0:
        dark = pixels
    darkest = dark.mean(axis=0).astype(int)
    pad = np.pad(mask, 1, mode='constant', constant_values=False)
    outline = np.zeros(alpha.shape, bool)
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            if dy == 0 and dx == 0:
                continue
            outline |= np.roll(np.roll(pad, dy, 0), dx, 1)[1:-1, 1:-1]
    add = (alpha <= 128) & outline
    nr, na = rgb.copy(), alpha.copy()
    nr[add], na[add] = darkest, 255
    return Image.fromarray(np.dstack([nr, na]), 'RGBA')


def process_crop(crop_bgr, out_size, backend='color', model='u2net'):
    if backend == 'rembg':
        rgba = rembg_cutout(crop_bgr, model)
    else:
        rgba = color_cutout(crop_bgr, *best_threshold(crop_bgr))
    pil = Image.fromarray(rgba, 'RGBA').resize(out_size, Image.LANCZOS)
    a = np.array(pil)
    a[:, :, 3] = np.where(a[:, :, 3] > 150, 255, 0).astype(np.uint8)
    pil = Image.fromarray(a, 'RGBA')
    pil = quantize_32(pil)
    return add_1px_outline(pil)


def main():
    ap = argparse.ArgumentParser(description='角色素材抠透明底（色度判据自适应 / 可选 rembg）')
    ap.add_argument('input', help='图片路径或目录')
    ap.add_argument('-o', '--out', default='out', help='输出路径（文件或目录）')
    ap.add_argument('--size', nargs=2, type=int, default=[64, 64], help='输出尺寸 W H')
    ap.add_argument('--backend', choices=['color', 'rembg'], default='color')
    ap.add_argument('--model', default='u2net', help='rembg 模型: u2net/silueta/isnet-anime')
    ap.add_argument('--batch', action='store_true', help='输入为目录时批量处理')
    args = ap.parse_args()

    size = (args.size[0], args.size[1])
    if os.path.isdir(args.input):
        os.makedirs(args.out, exist_ok=True)
        files = [f for f in os.listdir(args.input) if f.lower().endswith(('.png', '.jpg', '.jpeg'))]
        for f in files:
            im = cv2.imread(os.path.join(args.input, f))
            if im is None:
                continue
            out = process_crop(im, size, args.backend, args.model)
            out.save(os.path.join(args.out, os.path.splitext(f)[0] + '.png'))
            print(f'{f} -> {os.path.join(args.out, os.path.splitext(f)[0] + ".png")}')
    else:
        im = cv2.imread(args.input)
        if im is None:
            print('cannot read', args.input)
            sys.exit(1)
        out = process_crop(im, size, args.backend, args.model)
        out.save(args.out)
        print(f'{args.input} -> {args.out} {out.size}')


if __name__ == '__main__':
    main()
