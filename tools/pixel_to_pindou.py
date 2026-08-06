#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
pixel_to_pindou.py — 像素精灵 → 拼豆风格图纸生成器
====================================================
输入任意 PNG（单帧或帧序列），输出：
  1) SVG 图纸（网格 + 坐标轴 + 色块 + 可选格内色号 + 底部图例）
  2) 色板清单 TSV + JSON（色号 | HEX | RGB | 用量 | 占比）
  3) 可选放大位图 PNG（纯色块，透明键镂空）

与 ART_STYLE.md 对齐：
  - 色板字典：216 色上限，色号 = 前缀字母 + 两位数字（B/S/H/M/C/E/U/N）
  - 容差归并：ΔRGB <= tolerance 的邻近色自动归并到已有色号
  - 透明键协议：左上角 (0,0) 像素 = 背景色，全图同色一律镂空

核心流程（与美术管线一致）：
  读像素 RGB → 透明键镂空 → 查映射表(RGB↔色号) → 容差归并 → 输出

用法示例：
  python pixel_to_pindou.py --input assets/sprites/characters/elin_idle.png --frames 4
  python pixel_to_pindou.py --input a.png --output docs/pindou/a --labels --scale 12 --tolerance 8 --prefix S
"""
import argparse
import json
import math
import sys
from pathlib import Path

from PIL import Image

PREFIX_ORDER = ["B", "S", "H", "M", "C", "E", "U", "N"]  # ART_STYLE.md 前缀表
MAX_COLORS = 216  # ART_STYLE.md 色数上限
LEGEND_PER_ROW = 8


def dist(a, b):
    return math.sqrt((a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2 + (a[2] - b[2]) ** 2)


def hex_of(rgb):
    return "#%02x%02x%02x" % rgb


def build_svg(w, h, grid, palette, args, stats):
    """grid: 2D 数组，每格为 color_code 或 None(镂空)。返回 SVG 字符串。"""
    cell = args.cell
    pad = 8
    margin_x = 40          # 左侧坐标轴
    margin_top = 28        # 顶部坐标轴
    legend_h = (len(palette) + LEGEND_PER_ROW - 1) // LEGEND_PER_ROW * 30 + 20
    W = margin_x + w * cell + pad
    H = margin_top + h * cell + pad + legend_h
    s = []
    s.append(f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" '
             f'viewBox="0 0 {W} {H}" font-family="monospace">')
    s.append(f'<rect width="{W}" height="{H}" fill="#ffffff"/>')

    # ---- 顶部坐标轴（每 8 格标注数字） ----
    for x in range(w):
        if x % 8 == 0:
            s.append(f'<text x="{margin_x + x * cell + cell / 2}" y="{margin_top - 6}" '
                     f'font-size="8" text-anchor="middle" fill="#666">{x + 1}</text>')
    # ---- 左侧坐标轴 ----
    for y in range(h):
        if y % 8 == 0:
            s.append(f'<text x="{margin_x - 4}" y="{margin_top + y * cell + cell / 2 + 3}" '
                     f'font-size="8" text-anchor="end" fill="#666">{y + 1}</text>')

    # ---- 色块 ----
    for y in range(h):
        for x in range(w):
            code = grid[y][x]
            if code is None:
                continue
            rx = margin_x + x * cell
            ry = margin_top + y * cell
            e = palette[code]
            s.append(f'<rect x="{rx}" y="{ry}" width="{cell}" height="{cell}" fill="{e["hex"]}"/>')
            if args.labels:
                s.append(f'<text x="{rx + cell / 2}" y="{ry + cell / 2 + 3}" '
                         f'font-size="{max(5, cell // 3)}" text-anchor="middle" '
                         f'fill="{"#fff" if e["dark"] else "#222"}">{code}</text>')

    # ---- 网格线 ----
    s.append('<g stroke="#cccccc" stroke-width="0.5">')
    for x in range(w + 1):
        xx = margin_x + x * cell
        s.append(f'<line x1="{xx}" y1="{margin_top}" x2="{xx}" y2="{margin_top + h * cell}"/>')
    for y in range(h + 1):
        yy = margin_top + y * cell
        s.append(f'<line x1="{margin_x}" y1="{yy}" x2="{margin_x + w * cell}" y2="{yy}"/>')
    s.append('</g>')

    # ---- 图例（色号 | HEX | 用量） ----
    gy = margin_top + h * cell + pad + 4
    for i, (code, e) in enumerate(palette.items()):
        col = i % LEGEND_PER_ROW
        row = i // LEGEND_PER_ROW
        gx = margin_x + col * 68
        yy = gy + row * 30
        s.append(f'<rect x="{gx}" y="{yy}" width="16" height="16" fill="{e["hex"]}" stroke="#999"/>')
        s.append(f'<text x="{gx + 20}" y="{yy + 13}" font-size="10" fill="#222">{code}</text>')
        s.append(f'<text x="{gx + 54}" y="{yy + 13}" font-size="9" fill="#666">×{e["count"]}</text>')

    # ---- 底部统计行 ----
    s.append(f'<text x="{margin_x}" y="{H - 8}" font-size="10" fill="#999">'
             f'宽 {w} / 高 {h} / 颜色数 {len(palette)} / 透明键镂空 {stats["key_hits"]}px / '
             f'pixel_to_pindou.py (Star Echo)</text>')
    s.append('</svg>')
    return "".join(s)


def build_bitmap(w, h, grid, palette, scale):
    """放大位图：每格 scale×scale 纯色块，透明键为透明。"""
    bmp = Image.new("RGBA", (w * scale, h * scale), (0, 0, 0, 0))
    bp = bmp.load()
    for y in range(h):
        for x in range(w):
            code = grid[y][x]
            if code is None:
                continue
            c = palette[code]["rgb"]
            for dy in range(scale):
                for dx in range(scale):
                    bp[x * scale + dx, y * scale + dy] = (c[0], c[1], c[2], 255)
    return bmp


def process_image(img, out_prefix, args, tag=""):
    """处理单帧图像并输出全部产物。返回 palette。"""
    w, h = img.size
    px = img.load()
    print(f"[INFO] {tag or '帧'}: {w}x{h}")

    # 透明键协议：左上角 (0,0) 像素颜色 = 背景色
    tl = px[0, 0]
    key_rgb = (tl[0], tl[1], tl[2]) if tl[3] > 0 else None
    print(f"[INFO] 透明键(左上角): {hex_of(key_rgb) if key_rgb else '原生透明(alpha=0)'}")

    palette = []          # 有序列表: {code, hex, rgb, count, dark}
    key_hits = 0

    def lookup(rgb):
        for e in palette:
            if e["rgb"] == rgb:
                return e
            if dist(e["rgb"], rgb) <= args.tolerance:
                return e
        n = len(palette)
        if n >= MAX_COLORS:
            sys.exit(f"[ERR] 色数超过 {MAX_COLORS} 上限，请提高 --tolerance 或检查素材")
        lum = 0.299 * rgb[0] + 0.587 * rgb[1] + 0.114 * rgb[2]
        e = {"code": f"{args.prefix}{n:02d}", "hex": hex_of(rgb), "rgb": rgb,
             "count": 0, "dark": lum < 140}
        palette.append(e)
        return e

    grid = []
    for y in range(h):
        row = []
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0 or (key_rgb is not None and (r, g, b) == key_rgb):
                key_hits += 1
                row.append(None)
            else:
                e = lookup((r, g, b))
                e["count"] += 1
                row.append(e["code"])
        grid.append(row)

    total_px = w * h - key_hits
    stats = {"key_hits": key_hits, "total": total_px}
    print(f"[INFO] 镂空 {key_hits}/{w * h}  有效 {total_px}  色号 {len(palette)}（上限 {MAX_COLORS}）")
    for e in sorted(palette, key=lambda x: -x["count"])[:5]:
        print(f"   {e['code']} {e['hex']} ×{e['count']} ({e['count'] / total_px * 100:.1f}%)")

    pdir = {e["code"]: e for e in palette}
    svg = build_svg(w, h, grid, pdir, args, stats)
    svg_path = out_prefix.with_suffix(".svg")
    svg_path.write_text(svg, encoding="utf-8")
    print(f"[OK] 图纸: {svg_path}")

    rows = ["code\thex\trgb\tcount\tpct"]
    for e in palette:
        rows.append(f"{e['code']}\t{e['hex']}\t{e['rgb'][0]},{e['rgb'][1]},{e['rgb'][2]}\t"
                    f"{e['count']}\t{e['count'] / total_px * 100:.2f}")
    (out_prefix.with_suffix(".tsv")).write_text("\n".join(rows) + "\n", encoding="utf-8")
    (out_prefix.with_suffix(".json")).write_text(
        json.dumps({"source": str(out_prefix), "width": w, "height": h, "key_hits": key_hits,
                    "colors": [{"code": e["code"], "hex": e["hex"], "rgb": list(e["rgb"]),
                                "count": e["count"]} for e in palette]},
                   ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[OK] 色板: {out_prefix.with_suffix('.tsv')} / {out_prefix.with_suffix('.json')}")

    if args.bitmap:
        bmp = build_bitmap(w, h, grid, pdir, args.scale)
        bmp_path = out_prefix.with_suffix(".png")
        bmp.save(bmp_path)
        print(f"[OK] 位图: {bmp_path} ({w * args.scale}x{h * args.scale})")
    return palette


def main():
    ap = argparse.ArgumentParser(description="像素精灵 → 拼豆风格图纸")
    ap.add_argument("--input", required=True, help="输入 PNG 路径")
    ap.add_argument("--output", default=None, help="输出前缀（不含扩展名），默认与输入同名")
    ap.add_argument("--prefix", default="C", help="色号前缀（B/S/H/M/C/E/U/N，默认 C）")
    ap.add_argument("--tolerance", type=int, default=12, help="容差归并阈值 ΔRGB（默认 12）")
    ap.add_argument("--labels", action="store_true", help="在格内标注色号文字")
    ap.add_argument("--cell", type=int, default=16, help="SVG 图纸每格像素（默认 16）")
    ap.add_argument("--scale", type=int, default=8, help="位图版放大倍数（默认 8）")
    ap.add_argument("--bitmap", action="store_true", help="同时输出放大位图 PNG（纯色块）")
    ap.add_argument("--frames", type=int, default=1, help="横向帧序列数，>1 时逐帧输出（默认 1）")
    args = ap.parse_args()

    src = Path(args.input)
    if not src.exists():
        sys.exit(f"[ERR] 输入文件不存在: {src}")
    args.prefix = args.prefix.upper()
    out_prefix = Path(args.output) if args.output else src.with_suffix("")
    out_prefix.parent.mkdir(parents=True, exist_ok=True)

    img = Image.open(src).convert("RGBA")
    w, h = img.size
    frames = args.frames
    if frames < 1 or w % frames != 0:
        sys.exit(f"[ERR] --frames={frames} 无法整除宽度 {w}")

    if frames == 1:
        process_image(img, out_prefix, args, tag=src.name)
    else:
        fw = w // frames
        for i in range(frames):
            box = (i * fw, 0, (i + 1) * fw, h)
            frame_img = img.crop(box)
            process_image(frame_img, Path(f"{out_prefix}_{i + 1:02d}"), args, tag=f"帧{i + 1}")
    print("[DONE] 全部完成")


if __name__ == "__main__":
    main()
