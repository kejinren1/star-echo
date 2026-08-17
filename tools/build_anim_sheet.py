#!/usr/bin/env python3
"""
build_anim_sheet.py —— 动画帧序列 → 游戏 sprite sheet（Star Echo 2026-08-14 沉淀）

背景：AI 素材管线（docs/art_ai）产出的动画帧序列（帧01.png…帧NN.png，白底 RGB）
要接入 Godot 前必须：抠底成透明 → 锚点对齐 → 横排拼接成 sheet（引擎约定：横排、
正方形帧，帧数 = 宽÷高，见 player_anim._sheet_meta）。

管线：
  1. floodfill 抠白底 → 透明（色距判据，从四角种子扩散）
  2. 锚点对齐：默认以第一帧 bbox 为基准统一裁剪（--align none=仅报告 / first=对齐首帧 / center=逐帧居中）
  3. bbox 漂移报告（对齐前诊断用）
  4. 横排拼接 sheet（帧序 01→NN，透明画布）
  5. 输出 sheet.png + meta JSON（帧数/帧尺寸/建议 fps）

用法（Windows, managed python venv）：
  python tools/build_anim_sheet.py --frames docs/.../动画/云霓·中式古侠 --out assets/sprites/characters/yunni_idle.png
参数：
  --frames  帧目录（帧01.png…帧NN.png，按文件名排序）
  --out     输出 sheet 路径
  --bg-tol  抠底容差（色距，默认 45：抠净白/浅灰渐变且不伤浅色角色；纯白底可调小）
  --align   none(只报告) / first(默认,对齐首帧bbox) / center(逐帧居中到画布)
  --meta    额外输出 meta JSON 路径（默认 out 同名 .json）
"""
import argparse
import json
import os
import sys
from collections import deque

from PIL import Image

_BG_TOL_DEFAULT = 6


def detect_bg_color(im: Image.Image):
    """背景参考色 = 四边采样众数（借鉴拼豆网站 floodfillCutout）"""
    from collections import Counter
    im = im.convert("RGBA")
    px = im.load()
    w, h = im.size
    cnt: Counter = Counter()
    step = max(1, w // 48)
    for x in range(0, w, step):
        cnt[px[x, 0][:3]] += 1
        cnt[px[x, h - 1][:3]] += 1
    for y in range(0, h, step):
        cnt[px[0, y][:3]] += 1
        cnt[px[w - 1, y][:3]] += 1
    return cnt.most_common(1)[0][0]


def floodfill_alpha(im: Image.Image, tol: int) -> Image.Image:
    """floodfill 抠背景 → 透明（切比雪夫距离；容差必须小——只抠与背景几乎相同的像素，
    浅色角色/白衣/同色系角色不被误抠，见 2026-08-14 用户反馈：若叶睦浅绿背景抠掉绿衣 75%）"""
    im = im.convert("RGBA")
    bg = detect_bg_color(im)
    px = im.load()
    w, h = im.size

    def is_bg(c):
        return max(abs(c[0] - bg[0]), abs(c[1] - bg[1]), abs(c[2] - bg[2])) <= tol

    visited = [[False] * w for _ in range(h)]
    stack = []
    for x in range(w):
        stack.append((x, 0))
        stack.append((x, h - 1))
    for y in range(h):
        stack.append((0, y))
        stack.append((w - 1, y))
    while stack:
        x, y = stack.pop()
        if x < 0 or y < 0 or x >= w or y >= h or visited[y][x]:
            continue
        visited[y][x] = True
        c = px[x, y]
        if c[3] == 0 or not is_bg(c):
            continue
        px[x, y] = (c[0], c[1], c[2], 0)
        stack.extend([(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)])
    return im


def erode_edge_near(im: Image.Image, bg, tol: int = 18, iters: int = 3) -> Image.Image:
    """背景色 halo 侵蚀：从透明边缘向内，凡"距背景色 切比雪夫 ≤ tol"的像素 → 透明。
    清背景渐变带/毛刺，同时保护角色主体（主体色距背景 > tol 不抠）。"""
    im = im.convert("RGBA")
    px = im.load()
    w, h = im.size
    for _ in range(iters):
        to_remove = []
        for y in range(h):
            for x in range(w):
                r, g, b, a = px[x, y]
                if a == 0 or max(abs(r - bg[0]), abs(g - bg[1]), abs(b - bg[2])) > tol:
                    continue
                for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                    if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] == 0:
                        to_remove.append((x, y))
                        break
        for x, y in to_remove:
            px[x, y] = (0, 0, 0, 0)
        if not to_remove:
            break
    return im


def clean_small_blobs_near(im: Image.Image, bg, min_size: int = 100, tol: int = 12) -> Image.Image:
    """近背景色小连通块清理（floodfill 进不去的封闭环背景缝隙残留）。
    距背景色 切比雪夫 ≤ tol 且连通块 < min_size → 抠成透明。角色主体色不受影响。"""
    im = im.convert("RGBA")
    px = im.load()
    w, h = im.size
    near_bg = [[False] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            near_bg[y][x] = (a > 0 and max(abs(r - bg[0]), abs(g - bg[1]), abs(b - bg[2])) <= tol)
    visited = [[False] * w for _ in range(h)]
    remove = set()
    for y in range(h):
        for x in range(w):
            if not near_bg[y][x] or visited[y][x]:
                continue
            stack = [(x, y)]
            visited[y][x] = True
            blob = []
            while stack:
                cx, cy = stack.pop()
                blob.append((cx, cy))
                for nx in (cx - 1, cx, cx + 1):
                    for ny in (cy - 1, cy, cy + 1):
                        if (nx, ny) == (cx, cy):
                            continue
                        if 0 <= nx < w and 0 <= ny < h and not visited[ny][nx] and near_bg[ny][nx]:
                            visited[ny][nx] = True
                            stack.append((nx, ny))
            if len(blob) < min_size:
                remove.update(blob)
    for x, y in remove:
        px[x, y] = (0, 0, 0, 0)
    return im


def clean_white_median(im: Image.Image, tol: int = 30) -> Image.Image:
    """近白孤立像素 3×3 中值替换（perfectPixel/拼豆"干净"的关键：降采样/采样环节抹掉孤立白斑）。
    仅对距纯白 < tol 的非透明像素做 3×3 非透明邻域 RGB 中值 → 孤立白斑被周围彩色替换，
    大片白衣（邻域也是白）中值仍为白、彩色细节（1px 线）不受影响；alpha 不动。"""
    import statistics
    im = im.convert("RGBA")
    px = im.load()
    w, h = im.size
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    op = out.load()
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0 or abs(r - 255) + abs(g - 255) + abs(b - 255) >= tol:
                op[x, y] = (r, g, b, a)
                continue
            cols = []
            for ny in (y - 1, y, y + 1):
                for nx in (x - 1, x, x + 1):
                    if 0 <= nx < w and 0 <= ny < h:
                        c = px[nx, ny]
                        if c[3] > 0:
                            cols.append((c[0], c[1], c[2]))
            if not cols:
                op[x, y] = (r, g, b, a)
                continue
            med = tuple(int(statistics.median([c[i] for c in cols])) for i in range(3))
            op[x, y] = (med[0], med[1], med[2], a)
    return out


def freeze_bottom(imgs, n: int = 5) -> list:
    """脚底冻结：所有帧底部 n 行像素统一为基准帧（bbox 底边最下者）对应区域 →
    脚底水平线完全静止，呼吸起伏全部保留在脚底以上（用户 08-14 反馈）。"""
    boxes = [im.getbbox() for im in imgs]
    max_bottom = max(b[3] for b in boxes if b)
    base_i = 0
    for i, b in enumerate(boxes):
        if b and b[3] == max_bottom:
            base_i = i
            break
    base = imgs[base_i]
    region = base.crop((0, max_bottom - n, base.width, max_bottom))
    for i, im in enumerate(imgs):
        if i != base_i:
            im.paste(region, (0, max_bottom - n))
    return imgs


def clean_small_blobs(im: Image.Image, min_size: int = 100, tol: int = 15) -> Image.Image:
    """清理近白小连通块（floodfill 进不去的封闭环背景缝隙残留）。
    近白(距纯白曼哈顿 < tol) 且 连通块 < min_size → 抠成透明。
    角色白衣（大块）不受影响。"""
    im = im.convert("RGBA")
    px = im.load()
    w, h = im.size
    near_white = [[False] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            near_white[y][x] = (a > 0 and abs(r - 255) + abs(g - 255) + abs(b - 255) < tol)
    visited = [[False] * w for _ in range(h)]
    remove = set()
    for y in range(h):
        for x in range(w):
            if not near_white[y][x] or visited[y][x]:
                continue
            # BFS 收集连通块
            stack = [(x, y)]
            visited[y][x] = True
            blob = []
            while stack:
                cx, cy = stack.pop()
                blob.append((cx, cy))
                for nx in (cx - 1, cx, cx + 1):
                    for ny in (cy - 1, cy, cy + 1):
                        if (nx, ny) == (cx, cy):
                            continue
                        if 0 <= nx < w and 0 <= ny < h and not visited[ny][nx] and near_white[ny][nx]:
                            visited[ny][nx] = True
                            stack.append((nx, ny))
            if len(blob) < min_size:
                remove.update(blob)
    for x, y in remove:
        px[x, y] = (0, 0, 0, 0)
    return im


def erode_edge_white(im: Image.Image, tol: int = 60, iters: int = 2) -> Image.Image:
    """边缘白圈侵蚀：与透明像素相邻的近白像素 → 透明（去毛刺/白边），迭代 iters 轮。"""
    im = im.convert("RGBA")
    px = im.load()
    w, h = im.size
    for _ in range(iters):
        to_remove = []
        for y in range(h):
            for x in range(w):
                r, g, b, a = px[x, y]
                if a == 0 or abs(r - 255) + abs(g - 255) + abs(b - 255) >= tol:
                    continue
                for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                    if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] == 0:
                        to_remove.append((x, y))
                        break
        for x, y in to_remove:
            px[x, y] = (0, 0, 0, 0)
        if not to_remove:
            break
    return im


def load_frames(frames_dir: str):
    names = sorted(f for f in os.listdir(frames_dir)
                   if f.lower().endswith((".png", ".jpg", ".jpeg")) and not f.startswith("_"))
    if not names:
        sys.exit("[ERROR] 帧目录无图片: %s" % frames_dir)
    imgs = [Image.open(os.path.join(frames_dir, n)).convert("RGBA") for n in names]
    sizes = {im.size for im in imgs}
    if len(sizes) != 1:
        sys.exit("[ERROR] 帧尺寸不一致: %s（%s）" % (frames_dir, sorted(sizes)))
    return names, imgs


def report_bboxes(imgs):
    print("帧 | 尺寸 | 透明bbox(x,y,w,h) | 锚点(左上)")
    boxes = []
    for i, im in enumerate(imgs, 1):
        bbox = im.getbbox()
        boxes.append(bbox)
        print("帧%02d | %s | %s" % (i, im.size, bbox))
    xs = [b[0] for b in boxes if b]
    ys = [b[1] for b in boxes if b]
    if xs:
        print("锚点漂移: x∈[%d,%d] 幅度%d | y∈[%d,%d] 幅度%d" % (
            min(xs), max(xs), max(xs) - min(xs), min(ys), max(ys), max(ys) - min(ys)))
    return boxes


def align(imgs, mode, size):
    """对齐帧：first=统一裁到首帧bbox并居中；center=逐帧居中；bottom=底部对齐(脚底不动，呼吸起伏留在脚底以上)；none=不动"""
    if mode == "none":
        return imgs
    boxes = [im.getbbox() for im in imgs]
    if mode == "first":
        base = boxes[0]
        bw, bh = base[2] - base[0], base[3] - base[1]
        for im, b in zip(imgs, boxes):
            if not b:
                continue
            # 裁首帧区域
            crop = im.crop((base[0], base[1], base[2], base[3]))
            im2 = Image.new("RGBA", size, (0, 0, 0, 0))
            im2.paste(crop, ((size[0] - bw) // 2, (size[1] - bh) // 2))
            imgs[imgs.index(im)] = im2
    elif mode == "center":
        for i, im in enumerate(imgs):
            b = boxes[i]
            if not b:
                continue
            crop = im.crop(b)
            im2 = Image.new("RGBA", size, (0, 0, 0, 0))
            im2.paste(crop, ((size[0] - (b[2] - b[0])) // 2, (size[1] - (b[3] - b[1])) // 2))
            imgs[i] = im2
    elif mode == "bottom":
        # 底部锚定：所有帧 bbox 底边对齐到最底帧，x 水平居中；变化保留在脚底以上
        max_bottom = max(b[3] for b in boxes if b)
        for i, im in enumerate(imgs):
            b = boxes[i]
            if not b:
                continue
            bw, bh = b[2] - b[0], b[3] - b[1]
            crop = im.crop(b)
            im2 = Image.new("RGBA", size, (0, 0, 0, 0))
            x_off = (size[0] - bw) // 2
            y_off = max_bottom - bh  # 底边对齐：y_off + bh == max_bottom（勿漏减 b[1]，见 08-14 修正）
            im2.paste(crop, (x_off, y_off))
            imgs[i] = im2
    return imgs


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--frames", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--bg-tol", type=int, default=_BG_TOL_DEFAULT)
    ap.add_argument("--erode-tol", type=int, default=10,
                    help="背景 halo 侵蚀判据（距背景色切比雪夫，默认 10：只清紧贴背景的渐变带，不伤同色系主体）")
    ap.add_argument("--erode-iters", type=int, default=2)
    ap.add_argument("--align", choices=["none", "first", "center", "bottom"], default="bottom")
    ap.add_argument("--clean-blobs", action="store_true", default=True,
                    help="清理近背景色小连通块（封闭环背景缝隙残留，默认开；--no-clean-blobs 关闭）")
    ap.add_argument("--no-clean-blobs", dest="clean_blobs", action="store_false")
    ap.add_argument("--blob-min-size", type=int, default=100)
    ap.add_argument("--erode-edge", action="store_true", default=True,
                    help="背景 halo 侵蚀去渐变带/毛刺（默认开；--no-erode-edge 关闭）")
    ap.add_argument("--no-erode-edge", dest="erode_edge", action="store_false")
    ap.add_argument("--freeze", type=int, default=5,
                    help="脚底冻结行数（0=关；默认 5：底部 5 行像素跨帧统一，脚底水平线静止）")
    ap.add_argument("--meta", default="")
    args = ap.parse_args()

    names, imgs = load_frames(args.frames)
    print("载入 %d 帧，尺寸 %s" % (len(imgs), imgs[0].size))

    # 1. 抠底（floodfill 背景 → 透明；借鉴拼豆网站：四边众数参考色 + 切比雪夫小容差——
    #    只抠与背景几乎相同的像素，浅色角色/白衣/同色系角色不误抠，见 08-14 反馈）
    bg = detect_bg_color(imgs[0])
    print("背景参考色: %s，floodfill 容差 %d" % (bg, args.bg_tol))
    imgs = [floodfill_alpha(im, args.bg_tol) for im in imgs]
    # 1b. 背景 halo 侵蚀（清渐变带/毛刺，参考背景色）+ 封闭环背景缝隙清理
    if args.erode_edge:
        imgs = [erode_edge_near(im, bg, args.erode_tol, args.erode_iters) for im in imgs]
    if args.clean_blobs:
        imgs = [clean_small_blobs_near(im, bg, args.blob_min_size) for im in imgs]
    # 2. 对齐前诊断
    print("== 抠底清理后 bbox（对齐前） ==")
    boxes = report_bboxes(imgs)
    # 3. 对齐（默认 bottom：脚底锚定，呼吸起伏保留在脚底以上）
    imgs = align(imgs, args.align, imgs[0].size)
    if args.align != "none":
        print("== 对齐后 bbox（%s） ==" % args.align)
        report_bboxes(imgs)
    # 3b. 脚底冻结：底部 n 行像素跨帧统一（脚底水平线完全静止）
    if args.freeze > 0:
        imgs = freeze_bottom(imgs, args.freeze)
        print("== 脚底冻结 %d 行 ==" % args.freeze)

    # 4. 拼接 sheet（横排）
    fw, fh = imgs[0].size
    sheet = Image.new("RGBA", (fw * len(imgs), fh), (0, 0, 0, 0))
    for i, im in enumerate(imgs):
        sheet.paste(im, (i * fw, 0))
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    sheet.save(args.out)
    print("sheet 输出: %s（%dx%d，%d 帧 × %dpx，横排）" % (args.out, sheet.size[0], sheet.size[1], len(imgs), fw))

    # 5. meta
    meta_path = args.meta or (os.path.splitext(args.out)[0] + ".json")
    meta = {
        "sheet": args.out,
        "frames": len(imgs),
        "frame_size": [fw, fh],
        "fps_suggest": 8.0,
        "loop": True,
        "source": args.frames,
        "align": args.align,
        "bg_tol": args.bg_tol,
    }
    with open(meta_path, "w", encoding="utf-8") as f:
        json.dump(meta, f, ensure_ascii=False, indent=2)
    print("meta 输出: %s" % meta_path)


if __name__ == "__main__":
    main()
