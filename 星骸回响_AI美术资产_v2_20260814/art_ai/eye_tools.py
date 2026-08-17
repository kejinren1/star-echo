#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""eye_tools.py — 像素眼睛增强工具（A 道 inpaint mask 生成 + B 道高光绘制）
瞳孔检测：512 图上上部 15-55% 区域扫描暗色簇，聚类为左右眼。
"""
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw


def detect_eyes(img: Image.Image, debug_dir=None, tag="") -> list:
    """返回 [(cx, cy), (cx, cy)] 左右眼中心（图像坐标）。失败返回 []。"""
    g = np.asarray(img.convert("L"), dtype=np.int16)
    h, w = g.shape
    # 脸部区域：上部 15%-55%，宽度中部 90%
    y0, y1 = int(h * 0.15), int(h * 0.55)
    x0, x1 = int(w * 0.05), int(w * 0.95)
    region = g[y0:y1, x0:x1]
    dark = region < 70  # 深色像素（瞳孔/头发边缘）
    if dark.sum() < 5:
        return []
    ys, xs = np.nonzero(dark)
    pts = np.stack([xs + x0, ys + y0], axis=1).astype(np.float64)
    # 简单聚类：按 x 分左右（用中位数切分）
    med_x = np.median(pts[:, 0])
    left = pts[pts[:, 0] <= med_x]
    right = pts[pts[:, 0] > med_x]
    eyes = []
    for grp in (left, right):
        if len(grp) >= 3:
            cx, cy = grp.mean(axis=0)
            eyes.append((float(cx), float(cy)))
    if len(eyes) == 2 and eyes[0][0] > eyes[1][0]:
        eyes = [eyes[1], eyes[0]]
    if debug_dir:
        dbg = img.convert("RGB")
        d = ImageDraw.Draw(dbg)
        for cx, cy in eyes:
            d.ellipse([cx - 12, cy - 12, cx + 12, cy + 12], outline=(255, 0, 0), width=3)
        Path(debug_dir).mkdir(parents=True, exist_ok=True)
        dbg.save(Path(debug_dir) / f"eyes_{tag}.png")
    return eyes


def make_inpaint_image(img: Image.Image, eyes: list, out_path: Path,
                       radius_scale: float = 0.05) -> Path:
    """生成 RGBA：RGB=原图，A=mask（眼睛区域白色）。用于 LoadImage 双输出。"""
    w, h = img.size
    mask = Image.new("L", (w, h), 0)
    dm = ImageDraw.Draw(mask)
    r = max(8, int(w * radius_scale))
    for cx, cy in eyes:
        dm.ellipse([cx - r, cy - r, cx + r, cy + r], fill=255)
    rgba = img.convert("RGBA")
    rgba.putalpha(mask)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    rgba.save(out_path)
    return out_path


def draw_highlight(sprite: Image.Image, eyes_512: list, scale_512: int = 512,
                   color=(255, 255, 255), dark=(20, 20, 30)) -> Image.Image:
    """B 道：64/32 sprite 上补眼睛高光。eyes_512 为 512 图坐标，映射到 sprite。"""
    out = sprite.convert("RGB")
    w, h = out.size
    d = ImageDraw.Draw(out)
    k = w / scale_512  # 缩放系数
    for cx, cy in eyes_512:
        px, py = int(cx * k), int(cy * k)
        if not (0 <= px < w and 0 <= py < h):
            continue
        # 深色勾边 + 白色高光（左上 1-2px）
        for dx, dy in ((0, 0), (1, 0), (0, 1), (-1, 0), (0, -1), (1, 1)):
            if 0 <= px + dx < w and 0 <= py + dy < h:
                d.point((px + dx, py + dy), fill=dark)
        d.point((px, py), fill=color)
        d.point((px + 1, py), fill=color)
    return out


if __name__ == "__main__":
    import sys
    # 测试：对指定 512 像素化图做眼睛检测
    base = Path("D:/30DAYS/docs/art_ai/output_abc/CB_组合")
    for name in sys.argv[1:] or ["若叶睦", "傀影", "安洁莉娜"]:
        p = base / name / "2_像素化.png"
        if not p.exists():
            print(f"跳过 {name}（无 2_像素化.png）")
            continue
        im = Image.open(p)
        eyes = detect_eyes(im, debug_dir="D:/30DAYS/docs/art_ai/output_abc/_preview/eyes_debug", tag=name)
        print(f"{name}: 检测到 {len(eyes)} 只眼 {[tuple(map(int, e)) for e in eyes]}")
