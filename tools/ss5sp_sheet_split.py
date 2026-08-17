#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
ss5sp_sheet_split.py — spriters-resource 整条 sprite sheet 自动切帧工具

适用：Neo Geo 系格斗游戏 sheet（如《侍魂 5SP》），特征：
  - 整条竖长条 PNG（宽约 1176-1190，高 1.2 万 - 2.4 万 px）
  - 每行 = 一个动作（idle/walk/attack...），帧等宽横排
  - 帧间有空白/描边间隙

原理：像素投影法
  1. alpha（或非白）掩码 → 行投影找动作行，列投影找帧边界
  2. 逐行逐帧裁剪，可选 NEAREST 降采样到目标高度（保持像素感）

用法：
  python ss5sp_sheet_split.py <sheet.png> [--out 输出目录] [--target-h 64] [--cols N]

示例：
  python tools/ss5sp_sheet_split.py "ART/RAW/ss5sp/Haohmaru.png" --target-h 64
"""
import argparse
import os
import sys
import traceback


def load_image(path):
    try:
        from PIL import Image
    except ImportError:
        sys.exit("[ERR] 需要 Pillow：pip install Pillow（或使用项目 venv 的 python）")
    img = Image.open(path)
    if img.mode != "RGBA":
        img = img.convert("RGBA")
    return img


def alpha_mask(img):
    """返回 alpha 强度二维数组（0-255）；无 alpha 时用非白判定（白底 sheet）"""
    a = img.getchannel("A")
    flat = list(a.getdata(0))
    return [flat[y * img.width:(y + 1) * img.width] for y in range(img.height)]


def find_bands(proj, min_gap_px=2, min_band_px=1):
    """把一维投影切成连续非零段，返回 [(start, end), ...]（end 不包含）"""
    bands = []
    start = None
    for i, v in enumerate(proj):
        if v > 0:
            if start is None:
                start = i
        else:
            if start is not None:
                # 消除过窄的空隙噪声（把 <= min_gap_px 的空隙并入段）
                if i - start >= min_band_px:
                    bands.append((start, i))
                start = None
    if start is not None:
        bands.append((start, len(proj)))
    # 合并被噪声空隙打断的相邻段
    merged = []
    for b in bands:
        if merged and b[0] - merged[-1][1] <= min_gap_px:
            merged[-1] = (merged[-1][0], b[1])
        else:
            merged.append(list(b))
    return [(int(s), int(e)) for s, e in merged]


def col_proj_in_rows(mask, y0, y1):
    """在 [y0,y1) 行带内计算每列非空像素数（行带内任一行有像素即计入该列）"""
    w = len(mask[0]) if mask else 0
    proj = [0] * w
    for y in range(y0, y1):
        row = mask[y]
        for x in range(w):
            if row[x] > 0:
                proj[x] += 1
    return proj


def row_proj(mask):
    return [sum(1 for v in row if v > 0) for row in mask]


def split_sheet(img, mask, cols_hint=None):
    """返回 [(y0,y1,x0,x1), ...] 帧框列表，按行分组 [[(x0,x1),...], ...]"""
    rows = row_proj(mask)
    row_bands = find_bands(rows, min_gap_px=2, min_band_px=3)

    if not row_bands:
        return []

    # 用第一行段探测帧列边界（帧等宽，各行共享）
    y0, y1 = row_bands[0]
    colp = col_proj_in_rows(mask, y0, y1)
    col_bands = find_bands(colp, min_gap_px=2, min_band_px=3)

    # 若列带为空或异常（全宽连续），尝试用户 hint
    if cols_hint and (len(col_bands) != cols_hint or not col_bands):
        cw = img.width // cols_hint
        col_bands = [(i * cw, min((i + 1) * cw, img.width)) for i in range(cols_hint)]

    return row_bands, col_bands


def main():
    ap = argparse.ArgumentParser(description="sprite sheet 自动切帧")
    ap.add_argument("sheet", help="输入整条 sheet PNG")
    ap.add_argument("--out", default=None, help="输出目录（默认 <sheet 目录>/<名>_frames/）")
    ap.add_argument("--target-h", type=int, default=0, help="降采样目标高度（0=不缩放，保持原像素）")
    ap.add_argument("--cols", type=int, default=0, help="每行帧数 hint（投影失效时使用）")
    args = ap.parse_args()

    sheet = os.path.abspath(args.sheet)
    if not os.path.exists(sheet):
        sys.exit(f"[ERR] 文件不存在: {sheet}")
    base = os.path.splitext(os.path.basename(sheet))[0]
    out_dir = args.out or os.path.join(os.path.dirname(sheet), base + "_frames")
    os.makedirs(out_dir, exist_ok=True)

    img = load_image(sheet)
    mask = alpha_mask(img)
    w, h = img.size
    print(f"[OK] 载入 {sheet}  ({w}x{h})")

    row_bands, col_bands = split_sheet(img, mask, args.cols or None)
    if not row_bands:
        sys.exit("[ERR] 未检测到内容行（图可能全透明或纯色）")

    print(f"[OK] 检测到动作行 {len(row_bands)} 行，帧列 {len(col_bands)} 列")
    from PIL import Image
    total = 0
    for ri, (y0, y1) in enumerate(row_bands):
        # 对每行重新精算列边界（个别行动作裁剪位置可能不同）
        colp = col_proj_in_rows(mask, y0, y1)
        cb = find_bands(colp, min_gap_px=2, min_band_px=3)
        if not cb or (args.cols and len(cb) != args.cols):
            cb = col_bands  # 回退到全局帧列
        for ci, (x0, x1) in enumerate(cb):
            frame = img.crop((x0, y0, x1, y1))
            if args.target_h > 0:
                th = args.target_h
                tw = max(1, round(frame.width * th / frame.height))
                frame = frame.resize((tw, th), Image.NEAREST)
            fname = f"{base}_r{ri:02d}_c{ci:02d}.png"
            frame.save(os.path.join(out_dir, fname))
            total += 1
    print(f"[DONE] 共切出 {total} 帧 → {out_dir}")
    if args.target_h:
        print(f"[INFO] 已降采样到目标高度 {args.target_h}px（NEAREST）")


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except Exception:
        traceback.print_exc()
        sys.exit(1)
