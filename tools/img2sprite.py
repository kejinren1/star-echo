#!/usr/bin/env python3
"""
img2sprite.py —— 图片降维成像素画（拼豆核心功能保留版）· Star Echo 2026-08-08 沉淀

背景：拼豆网站的核心功能 = 「把任意图片降维成像素画 + 有限色板」，色号/水印/版面
是服务「人按图拼豆」的附加物。本项目不需要色号表，只要像素画 sprite。
本工具 = 纯白背景美术素材 → 游戏可用像素画 sprite 的单文件零依赖管线（PIL only）。

管线（对应 docs/ART_STYLE.md 像素化转制 SOP，纯白底场景强化）：
  1. 抠白底 → 透明（色度判据：max-min 小 且 亮度高 = 背景白；角色浅色带色相不受影响）
  2. 自动 bbox 裁剪（透明边，角色紧贴；可 --no-crop 关闭）
  3. 网格降采样到目标尺寸（每输出像素 = 原图一块区域，取代表色；透明像素不参与）
  4. 可选色板量化（--palette：内置 32 色 / .hex / .png / color_dict JSON）
  5. alpha 硬化 + 透明键协议（左上角 (0,0) 透明 → 引擎全图镂空该色）

用法（Windows, managed python venv）：
  python tools/img2sprite.py --input 素材.png --output out.png --size 64x64
  python tools/img2sprite.py --input 素材目录 --output out_dir --size 32 --batch
  python tools/img2sprite.py --input x.png --output y.png --palette ART/COLOR_DICT.json

参数：
  --input    输入图片或目录（png/jpg/jpeg/webp/bmp）
  --output   输出路径（文件或目录）
  --size     输出尺寸：'64'（宽=64，高按比例）或 '64x48'（宽x高）
  --mode     代表色算法: mean(默认) | median | mode
  --palette  色板：省略=不量化；内置32色；.hex 文件；.png 色板图；color_dict JSON
  --bg       背景判定颜色（默认自动：白 = 高亮低饱和）；'keep'=不抠底（输入已透明）
  --bg-tol   背景容差（默认 12：max-min 差；背景若为浅灰可调大）
  --crop     自动裁剪透明边（默认开；--no-crop 关闭）
  --upscale  最近邻放大倍数（预览用；0=不放大）
"""
import argparse
import glob
import json
import os
import sys
from collections import Counter

from PIL import Image

# 内置 32 色调色板（ART_STYLE.md 锚点，去重后 29 色）
_PALETTE = [
    (0x0d, 0x0d, 0x12), (0x1a, 0x1a, 0x2e), (0x16, 0x21, 0x3e), (0x0f, 0x34, 0x60),
    (0x2d, 0x2d, 0x3f), (0x3d, 0x3d, 0x4f), (0x4a, 0x4a, 0x5f),
    (0xe9, 0x45, 0x60), (0xf3, 0x81, 0x81), (0xf6, 0xc9, 0x0e), (0x6b, 0xc8, 0x6b),
    (0x4e, 0x89, 0xde), (0x9d, 0x4e, 0xdd), (0xff, 0x6b, 0x35), (0x2e, 0xc4, 0xb6),
    (0x00, 0xf5, 0xff), (0xff, 0x00, 0xff), (0xff, 0xfd, 0x00), (0x39, 0xff, 0x14),
    (0xff, 0x5e, 0x00), (0xb0, 0x26, 0xff), (0xff, 0x07, 0x3a), (0xff, 0xff, 0xff),
    (0x1e, 0x1e, 0x2f), (0x2a, 0x2a, 0x3f), (0x7a, 0x7a, 0x8f), (0xcc, 0xcc, 0xcc),
    (0x5c, 0x5c, 0x73), (0x3a, 0x3a, 0x4f),
]


def load_palette(spec):
    """加载色板：None→不量化；True/内置→32色；.hex；.png；color_dict JSON。"""
    if spec is None or str(spec).lower() == "none":
        return None
    if spec is True or str(spec).lower() in ("32", "内置", "default"):
        return _PALETTE
    p = str(spec)
    if p.lower().endswith(".hex"):
        cols = []
        with open(p, encoding="utf-8") as f:
            for line in f:
                line = line.strip().lstrip("#")
                if len(line) >= 6:
                    cols.append((int(line[0:2], 16), int(line[2:4], 16), int(line[4:6], 16)))
        return cols or _PALETTE
    if p.lower().endswith(".json"):
        with open(p, encoding="utf-8") as f:
            data = json.load(f)
        cols = []
        for key, entry in data.items() if isinstance(data, dict) else []:
            if isinstance(entry, dict) and "rgb" in entry:
                cols.append(tuple(entry["rgb"]))
        if not cols:
            for v in data.values() if isinstance(data, dict) else []:
                if isinstance(v, list) and len(v) == 3:
                    cols.append(tuple(v))
        return cols or _PALETTE
    im = Image.open(p).convert("RGB")
    return list({px for px in im.getdata()})


def nearest_color(rgb, palette):
    best, bd = None, 1 << 60
    for c in palette:
        d = (rgb[0] - c[0]) ** 2 + (rgb[1] - c[1]) ** 2 + (rgb[2] - c[2]) ** 2
        if d < bd:
            bd, best = d, c
    return best


def cutout_white(im, tol=12, lum_thr=235):
    """色度判据抠白底：max-min < tol 且 亮度 > lum_thr → 透明。返回 RGBA。"""
    im = im.convert("RGBA")
    px = im.load()
    w, h = im.size
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    op = out.load()
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            mx, mn = max(r, g, b), min(r, g, b)
            lum = (r + g + b) / 3
            if mx - mn < tol and lum > lum_thr:
                continue  # 白/浅灰 → 透明
            op[x, y] = (r, g, b, 255 if a > 128 else a)
    return out


def auto_crop(im):
    """裁剪透明边。返回裁后图或原图。"""
    bbox = im.getbbox()
    if bbox is None:
        return im
    return im.crop(bbox)


def block_rep(block, mode):
    n = len(block)
    if n == 0:
        return None
    if mode == "mean":
        return (sum(p[0] for p in block) // n, sum(p[1] for p in block) // n,
                sum(p[2] for p in block) // n)
    if mode == "median":
        rs = sorted(p[0] for p in block)
        gs = sorted(p[1] for p in block)
        bs = sorted(p[2] for p in block)
        m = n // 2
        return (rs[m], gs[m], bs[m])
    return Counter(block).most_common(1)[0][0]


def downsample(im, out_w, out_h, mode):
    """网格降采样：每输出像素 = 原图一块区域代表色；透明块 → 全透明。"""
    W, H = im.size
    px = im.load()
    out = Image.new("RGBA", (out_w, out_h), (0, 0, 0, 0))
    op = out.load()
    bw, bh = W / out_w, H / out_h
    for oy in range(out_h):
        for ox in range(out_w):
            x0, x1 = int(ox * bw), max(int((ox + 1) * bw), int(ox * bw) + 1)
            y0, y1 = int(oy * bh), max(int((oy + 1) * bh), int(oy * bh) + 1)
            block = []
            for yy in range(y0, y1):
                for xx in range(x0, x1):
                    r, g, b, a = px[xx, yy]
                    if a > 10:  # 忽略近透明，防白色/黑色污染代表色
                        block.append((r, g, b))
            col = block_rep(block, mode)
            if col is None:
                continue  # 整块透明 → 输出透明
            op[ox, oy] = (col[0], col[1], col[2], 255)
    return out


def quantize(im, palette):
    if palette is None:
        return im
    px = im.load()
    w, h = im.size
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    op = out.load()
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            nc = nearest_color((r, g, b), palette)
            op[x, y] = (nc[0], nc[1], nc[2], 255)
    return out


def process(im, size, mode, palette, do_crop, bg, bg_tol):
    # 1) 抠底（默认自动白底；--bg keep = 输入已透明）
    im = im.convert("RGBA")
    if str(bg).lower() != "keep":
        im = cutout_white(im, tol=bg_tol)
    # 2) bbox 裁剪
    if do_crop:
        im = auto_crop(im)
    # 3) 目标尺寸（'64' → 宽 64 按比例；'64x48' → 固定）
    W, H = im.size
    if "x" in str(size):
        out_w, out_h = (int(s) for s in str(size).lower().split("x"))
    else:
        out_w = int(size)
        out_h = max(1, round(H * out_w / W))
    # 4) 降采样 + 5) 量化
    small = downsample(im, out_w, out_h, mode)
    small = quantize(small, palette)
    return small, (W, H)


def main():
    ap = argparse.ArgumentParser(description="图片降维成像素画（纯白背景素材 → 游戏 sprite）")
    ap.add_argument("--input", required=True)
    ap.add_argument("--output", required=True)
    ap.add_argument("--size", default="64", help="输出尺寸 '64' 或 '64x48'")
    ap.add_argument("--mode", choices=["mean", "median", "mode"], default="mean")
    ap.add_argument("--palette", nargs="?", const=True, default=None,
                    help="色板：省略=不量化 / 内置32色 / .hex / .png / color_dict JSON")
    ap.add_argument("--bg", default="auto", help="背景：auto(自动白底) / keep(输入已透明)")
    ap.add_argument("--bg-tol", type=int, default=12, help="白底容差(max-min)")
    ap.add_argument("--no-crop", dest="crop", action="store_false", default=True)
    ap.add_argument("--upscale", type=int, default=0, help="最近邻放大倍数（预览）")
    ap.add_argument("--batch", action="store_true")
    args = ap.parse_args()

    palette = load_palette(args.palette if args.palette is not None else None)
    pal_info = "off" if palette is None else f"on({len(palette)}色)"

    files = []
    if os.path.isdir(args.input):
        for e in ("*.png", "*.jpg", "*.jpeg", "*.webp", "*.bmp"):
            files += glob.glob(os.path.join(args.input, "**", e), recursive=True)
        os.makedirs(args.output, exist_ok=True)
    else:
        files = [args.input]
    if not files:
        print("未找到输入图片")
        sys.exit(1)

    for f in files:
        im = Image.open(f)
        small, src_size = process(im, args.size, args.mode, palette, args.crop, args.bg, args.bg_tol)
        if os.path.isdir(args.input):
            base = os.path.splitext(os.path.basename(f))[0]
            dst = os.path.join(args.output, base + ".png")
        else:
            dst = args.output
        if args.upscale > 0:
            small = small.resize((small.size[0] * args.upscale, small.size[1] * args.upscale), Image.NEAREST)
            dst = dst.replace(".png", "_x%d.png" % args.upscale)
        small.save(dst)
        # 透明键协议检查
        tl = small.convert("RGBA").load()[0, 0]
        warn = "  !! 左上角不透明，该色会被引擎镂空" if tl[3] > 0 else ""
        print("%s (%dx%d) -> %s (%dx%d) mode=%s palette=%s%s" % (
            f, src_size[0], src_size[1], dst, small.size[0], small.size[1], args.mode, pal_info, warn))


if __name__ == "__main__":
    main()
