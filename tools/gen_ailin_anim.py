## gen_ailin_anim.py — 艾琳 13 帧原图 → 游戏 sprite sheet 实装管线
## 输入：ART/CHARA/AILIN/{WALK1..10, idle1..3}.png（~2800×35xx 高清 AI 图，纯色背景）
## 输出：assets/sprites/characters/elin_walk.png（320×32，10 帧）+ elin_idle.png（96×32，3 帧）
##
## 处理链：
##   1. 抠背景：ImageDraw.floodfill 从四边连通域去除背景色（ΔRGB 容差），防误删角色内部相近色
##   2. bbox 裁剪：各帧非透明像素包围盒
##   3. 统一缩放：全部帧按同一比例缩到角色高 30px（LANCZOS），帧内比例一致
##   4. 对齐：脚底（bbox 底边）贴帧底 1px，水平居中
##   5. 合成横排 sheet 并落盘
##
## 用法：python tools/gen_ailin_anim.py
import os
from collections import deque
from PIL import Image, ImageDraw

SRC_DIR = r"D:\Program Files\30DAYS\ART\CHARA\AILIN"
OUT_DIR = r"D:\Program Files\30DAYS\assets\sprites\characters"
WALK_FILES = ["WALK%d.png" % i for i in range(1, 11)]   # 帧序 = 文件名序
IDLE_FILES = ["idle%d.png" % i for i in range(1, 4)]
FRAME = 32          # 帧边长
CHAR_H = 30         # 角色统一高度（底边距 1px）
BG_THRESH = 25      # 背景容差（ΔRGB 每通道最大差）

def load_frame(path):
    im = Image.open(path).convert("RGBA")
    return im

def cut_bg(im):
    """flood fill 从四边去除与 (0,0) 色相近的连通背景，返回新图"""
    im = im.copy()
    w, h = im.size
    seed = im.getpixel((0, 0))[:3]
    for sx, sy in [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1),
                   (w // 2, 0), (w // 2, h - 1), (0, h // 2), (w - 1, h // 2)]:
        p = im.getpixel((sx, sy))
        if p[3] > 0 and max(abs(p[0] - seed[0]), abs(p[1] - seed[1]), abs(p[2] - seed[2])) <= BG_THRESH:
            ImageDraw.floodfill(im, (sx, sy), (0, 0, 0, 0), thresh=BG_THRESH)
    return im

def bbox(im):
    """非透明像素包围盒 (x0, y0, x1, y1)；无内容返回 None"""
    w, h = im.size
    px = im.load()
    x0, y0, x1, y1 = w, h, -1, -1
    for y in range(h):
        for x in range(w):
            if px[x, y][3] > 8:
                if x < x0: x0 = x
                if x > x1: x1 = x
                if y < y0: y0 = y
                if y > y1: y1 = y
    if x1 < x0:
        return None
    return (x0, y0, x1 + 1, y1 + 1)

def alpha_floor(im, thr=40):
    """去除抠图残留的半透明噪点：alpha < thr 清零"""
    im = im.copy()
    px = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a < thr:
                px[x, y] = (r, g, b, 0)
    return im

def process(files):
    """返回 [(name, 32×32 帧 Image)]"""
    frames = []
    raw = []
    for f in files:
        im = cut_bg(load_frame(os.path.join(SRC_DIR, f)))
        im = alpha_floor(im)
        raw.append((f, im))
    # 统一缩放基准：所有帧 bbox 高度最大值 → 角色高度统一 CHAR_H
    heights = []
    boxes = []
    for f, im in raw:
        b = bbox(im)
        boxes.append(b)
        if b:
            heights.append(b[3] - b[1])
    if not heights:
        raise SystemExit("ERROR: 无有效帧内容")
    scale = CHAR_H / max(heights)
    for f, (_, im), b in zip(files, raw, boxes):
        if b is None:
            print("  WARN %s 无内容" % f)
            frames.append((f, Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))))
            continue
        bw, bh = b[2] - b[0], b[3] - b[1]
        crop = im.crop(b)
        nw, nh = max(1, int(round(bw * scale))), max(1, int(round(bh * scale)))
        crop = crop.resize((nw, nh), Image.LANCZOS)
        frame = Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))
        # 脚底对齐（bbox 底边 → y = FRAME-1），水平居中
        tx = (FRAME - nw) // 2
        ty = FRAME - 1 - nh
        frame.paste(crop, (tx, ty), crop)
        frames.append((f, frame))
    return frames

def sheet(frames):
    """合成横排 sheet"""
    n = len(frames)
    out = Image.new("RGBA", (FRAME * n, FRAME), (0, 0, 0, 0))
    for i, (name, fr) in enumerate(frames):
        out.paste(fr, (i * FRAME, 0), fr)
    return out

def stats(frames, label):
    total_px = 0
    colors = set()
    for name, fr in frames:
        cnt = len(fr.getcolors(maxcolors=1 << 24))
        colors |= set(fr.getcolors(maxcolors=1 << 24) or [])
        print("    %s: 色数 %d" % (name, cnt))
    print("  %s: 帧数 %d" % (label, len(frames)))

def main():
    print("== 艾琳动画实装管线 ==")
    walk = process(WALK_FILES)
    idle = process(IDLE_FILES)
    os.makedirs(OUT_DIR, exist_ok=True)
    w_sheet = sheet(walk)
    i_sheet = sheet(idle)
    w_path = os.path.join(OUT_DIR, "elin_walk.png")
    i_path = os.path.join(OUT_DIR, "elin_idle.png")
    w_sheet.save(w_path)
    i_sheet.save(i_path)
    print("walk sheet: %s (%dx%d)" % (w_path, w_sheet.size[0], w_sheet.size[1]))
    print("idle sheet: %s (%dx%d)" % (i_path, i_sheet.size[0], i_sheet.size[1]))
    stats(walk, "walk")
    stats(idle, "idle")

if __name__ == "__main__":
    main()
