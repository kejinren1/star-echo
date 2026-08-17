#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""post_process_items.py — 道具图标后处理：抠底→bbox→32px 网格降采样→COLOR_DICT 量化→拼图集
输入: output_abc/items_20260815/<id>_item_*.png（aziibpixelmix 512 直出纯白底）
输出: assets/sprites/ui/items.png（54 帧 × 32px，按 items.json 顺序）+ 质量报告
用法: python post_process_items.py [--bg-tol 40] [--dry-run]
"""
import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, r"D:/30DAYS/tools")
from img2sprite import cutout_floodfill, auto_crop, downsample, quantize, load_palette
from PIL import Image

ITEMS_DIR = Path("D:/30DAYS/docs/art_ai/output_abc/items_20260815")
OUT_SHEET = Path("D:/30DAYS/assets/sprites/ui/items.png")
PALETTE_PATH = Path("D:/30DAYS/ART/COLOR_DICT.json")
FRAME = 32

# items.json 顺序（单一事实源）
ITEM_ORDER = json.loads(Path("D:/30DAYS/data/items.json").read_text(encoding="utf-8"))
if isinstance(ITEM_ORDER, dict):
    ITEM_ORDER = ITEM_ORDER["items"]


def center_frame(im: Image.Image) -> Image.Image:
    """垂直居中到 32×32 帧（横向已按比例缩放）。"""
    frame = Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))
    w, h = im.size
    frame.paste(im, ((FRAME - w) // 2, (FRAME - h) // 2), im)
    return frame


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--bg-tol", type=int, default=40, help="抠底容差（纯白底可小）")
    ap.add_argument("--dry-run", action="store_true", help="只分析不写盘")
    args = ap.parse_args()

    palette = load_palette(PALETTE_PATH)
    files = sorted(ITEMS_DIR.glob("*_item_*.png"))
    print(f"[input] {len(files)} 张道具原图")

    report = {}
    frames = []
    for f in files:
        iid = f.name.split("_item_")[0]
        im = Image.open(f).convert("RGBA")
        # 1) 抠底（floodfill 从角落，纯白底小容差）
        im = cutout_floodfill(im, tol=args.bg_tol)
        # 2) bbox 裁剪
        im = auto_crop(im)
        if im.size[0] < 4 or im.size[1] < 4:
            report[iid] = {"status": "EMPTY", "size": im.size}
            frames.append(center_frame(Image.new("RGBA", (8, 8), (0, 0, 0, 0))))
            continue
        # 3) 32px 网格降采样（保持比例）
        W, H = im.size
        out_h = max(1, round(H * FRAME / W))
        small = downsample(im, FRAME, out_h, "median")
        # 4) 量化
        small = quantize(small, palette)
        # 5) 居中成帧
        frame = center_frame(small)
        frames.append(frame)
        # 质量统计
        px = list(frame.getdata())
        n = len(px)
        opaque = sum(1 for p in px if p[3] >= 250)
        colors = len({(p[0], p[1], p[2]) for p in px if p[3] >= 250})
        white_op = sum(1 for p in px if p[3] >= 250 and p[0] > 240 and p[1] > 240 and p[2] > 240)
        report[iid] = {
            "src": f.name, "bbox": (W, H), "opaque%": round(100 * opaque / n, 1),
            "colors": colors, "white_op%": round(100 * white_op / n, 1),
            "status": "OK",
        }
        # 质量红灯：主体太小 / 疑似空白 / 白色残留过多
        if opaque / n < 0.04:
            report[iid]["status"] = "TOO_SMALL"
        elif white_op / n > 0.35:
            report[iid]["status"] = "WHITE_RESIDUE"

    # 按 items.json 顺序重排（补缺失为空格）
    by_id = {f.name.split("_item_")[0]: f for f in files}
    ordered_frames = []
    for it in ITEM_ORDER:
        iid = it["id"]
        if iid in by_id:
            idx = files.index(by_id[iid])
            ordered_frames.append(frames[idx])
        else:
            ordered_frames.append(center_frame(Image.new("RGBA", (8, 8), (0, 0, 0, 0))))
            report[iid] = {"status": "MISSING_SRC"}
    print(f"[order] 共 {len(ordered_frames)} 帧（items.json 顺序）")

    sheet = Image.new("RGBA", (FRAME * len(ordered_frames), FRAME), (0, 0, 0, 0))
    for i, fr in enumerate(ordered_frames):
        sheet.paste(fr, (i * FRAME, 0), fr)

    if not args.dry_run:
        sheet.save(OUT_SHEET)
        print(f"[write] {OUT_SHEET} ({sheet.size[0]}x{sheet.size[1]})")
    else:
        print(f"[dry-run] 图集规格 {sheet.size[0]}x{sheet.size[1]}")

    # 报告
    rep_path = ITEMS_DIR / "_quality_report.json"
    if not args.dry_run:
        rep_path.write_text(json.dumps(report, ensure_ascii=False, indent=1), encoding="utf-8")
    bad = [k for k, v in report.items() if v["status"] != "OK"]
    print(f"[report] {len(report)} 项，异常 {len(bad)} 项: {bad}")
    for k in bad:
        print(f"   {k}: {report[k]}")


if __name__ == "__main__":
    main()
