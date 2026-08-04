#!/usr/bin/env python3
"""
pixelate_batch.py — 一键批量像素化工具

把"非像素风"图片按网格切开，每个网格取一个代表色（mean / median / mode），
可选量化到项目 32 色调色板，再用最近邻放大回目标尺寸。
对应 docs/ART_STYLE.md 第十三章「像素化转制 SOP」。

算法本质 = 网格降采样 (block downsampling) + 代表色：
  把图切成 NxM 个格子，每个格子用「平均色 / 中位数色 / 众数色」代表，
  得到一个缩小的小图（1 像素 = 1 个原格子），即像素化结果。

用法示例（Windows, managed python venv）：
  ..\\..\\binaries\\python\\envs\\default\\Scripts\\python.exe tools\\pixelate_batch.py ^
      --input assets\\raw ^
      --output assets\\sprites\\enemies ^
      --width 32 --mode mean --palette

常用参数：
  --input   输入图片或目录（目录会递归扫描 png/jpg/jpeg/webp/bmp）
  --output  输出目录（自动创建）
  --width   输出宽度（像素）。与 --scale 二选一
  --scale   网格块大小（像素）。设此项则按块切，忽略 --width
  --mode    代表色算法: mean(默认, 最平滑) | median(折中) | mode(最强像素感)
  --palette 量化到调色板: 省略=内置32色; --palette 路径(.hex/.png) 用外部板; --no-palette 关闭
  --upscale 最近邻放大倍数(0=不放大, 用于直接出可显示的大图)
"""

import argparse
import glob
import os
import sys
from collections import Counter

from PIL import Image

# 内置 32 色调色板（取自 ART_STYLE.md 第二章，去重后 29 色）
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


def load_palette(path):
    """从 .hex（每行 #rrggbb）或图片提取调色板。"""
    if path is None:
        return _PALETTE
    if path.lower().endswith(".hex"):
        cols = []
        with open(path, encoding="utf-8") as f:
            for line in f:
                line = line.strip().lstrip("#")
                if len(line) >= 6:
                    cols.append((int(line[0:2], 16), int(line[2:4], 16), int(line[4:6], 16)))
        return cols or _PALETTE
    im = Image.open(path).convert("RGB")
    return list({p for p in im.getdata()})


def nearest_color(px, palette):
    r, g, b = px
    best, bd = None, 1e18
    for c in palette:
        dr, dg, db = r - c[0], g - c[1], b - c[2]
        d = dr * dr + dg * dg + db * db
        if d < bd:
            bd, best = d, c
    return best


def block_representative(pixels, mode):
    """对一块像素集合取代表色。"""
    n = len(pixels)
    if n == 0:
        return (0, 0, 0)
    if mode == "mean":
        r = sum(p[0] for p in pixels) // n
        g = sum(p[1] for p in pixels) // n
        b = sum(p[2] for p in pixels) // n
        return (r, g, b)
    if mode == "median":
        rs = sorted(p[0] for p in pixels)
        gs = sorted(p[1] for p in pixels)
        bs = sorted(p[2] for p in pixels)
        m = n // 2
        return (rs[m], gs[m], bs[m])
    # mode: 最频繁颜色，最强像素感，但块内分散时可能跳变
    return Counter(pixels).most_common(1)[0][0]


def pixelate(img, out_w, out_h, mode, palette):
    """网格降采样 + 代表色 + 调色板量化。"""
    src = img.convert("RGBA")
    W, H = src.size
    px = src.load()
    out = Image.new("RGBA", (out_w, out_h))
    opx = out.load()
    bw = W / out_w
    bh = H / out_h
    for oy in range(out_h):
        for ox in range(out_w):
            x0, x1 = int(ox * bw), max(int((ox + 1) * bw), int(ox * bw) + 1)
            y0, y1 = int(oy * bh), max(int((oy + 1) * bh), int(oy * bh) + 1)
            block = []
            for yy in range(y0, y1):
                for xx in range(x0, x1):
                    r, g, b, a = px[xx, yy]
                    if a > 10:  # 忽略近透明像素，避免半透明污染代表色
                        block.append((r, g, b))
            if not block:
                block = [(0, 0, 0)]
            col = block_representative(block, mode)
            if palette is not None:
                col = nearest_color(col, palette)
            opx[ox, oy] = (col[0], col[1], col[2], 255)
    return out


def resolve_palette(args):
    if getattr(args, "no_palette", False):
        return None
    if args.palette is True:
        return _PALETTE
    if isinstance(args.palette, str):
        return load_palette(args.palette)
    return _PALETTE  # 默认量化到内置 32 色


def main():
    ap = argparse.ArgumentParser(description="批量像素化：网格降采样 + 代表色 + 调色板量化")
    ap.add_argument("--input", required=True, help="输入图片或目录")
    ap.add_argument("--output", required=True, help="输出目录（自动创建）")
    ap.add_argument("--width", type=int, default=32, help="输出宽度（像素），与 --scale 二选一")
    ap.add_argument("--height", type=int, default=0, help="输出高度，0=按比例")
    ap.add_argument("--scale", type=int, default=0, help="网格块大小（像素），设此项忽略 --width")
    ap.add_argument("--mode", choices=["mean", "median", "mode"], default="mean", help="代表色算法")
    ap.add_argument("--palette", nargs="?", const=True, default=None,
                    help="量化调色板：省略=内置32色；--palette 路径(.hex/.png)；--no-palette 关闭")
    ap.add_argument("--no-palette", dest="no_palette", action="store_true", help="关闭调色板量化")
    ap.add_argument("--upscale", type=int, default=0, help="最近邻放大倍数，0=不放大")
    ap.add_argument("--ext", default="png", help="输出扩展名")
    args = ap.parse_args()

    palette = resolve_palette(args)

    files = []
    if os.path.isdir(args.input):
        for e in ("*.png", "*.jpg", "*.jpeg", "*.webp", "*.bmp"):
            files += glob.glob(os.path.join(args.input, "**", e), recursive=True)
    else:
        files = [args.input]
    if not files:
        print("没有找到输入图片")
        sys.exit(1)
    os.makedirs(args.output, exist_ok=True)

    for f in files:
        im = Image.open(f)
        W, H = im.size
        if args.scale > 0:
            out_w = max(1, W // args.scale)
            out_h = max(1, H // args.scale)
        else:
            out_w = args.width
            out_h = args.height if args.height > 0 else max(1, round(H * out_w / W))
        small = pixelate(im, out_w, out_h, args.mode, palette)
        base = os.path.splitext(os.path.basename(f))[0]
        if args.upscale > 0:
            small = small.resize((out_w * args.upscale, out_h * args.upscale), Image.NEAREST)
            suffix = f"_x{args.upscale}"
        else:
            suffix = ""
        dst = os.path.join(args.output, f"{base}_px{out_w}{suffix}.{args.ext}")
        small.save(dst)
        pal_info = "off" if palette is None else f"on({len(palette)}色)"
        print(f"{f}  ({W}x{H}) -> {dst}  ({out_w}x{out_h})  mode={args.mode} palette={pal_info}")


if __name__ == "__main__":
    main()
