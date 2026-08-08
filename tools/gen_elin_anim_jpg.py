## gen_elin_anim_jpg.py — 艾琳 JPG 动画帧 → 游戏 sprite sheet 实装管线
##
## 输入：ART/RAW/elin/*.jpg（720×960 浅灰底 AI 动画帧，命名 动作+帧号）
##    idle1-5 / walk1-10 / attack1-5 / skill1-6 / hit1-2（28 帧）
## 输出：assets/sprites/characters/elin_{idle,walk,attack,skill,hit}.png
##    帧 64×64（与 D28 拼豆版帧规格一致 → player.gd _sheet_meta 自动推断帧数）
##    帧数：idle 5 / walk 10 / attack 5 / skill 6 / hit 2
##
## 处理链（用户拍板参数：抠底容差 100；不量化保 AI 原色）：
##   1. floodfill 抠底（边缘种子，容差 100）→ 背景透明
##   2. bbox 裁剪（角色紧贴；透明边）
##   3. 每动作组全帧 bbox 并集 = 统一窗口（动画稳定，防跳动）
##   4. 统一缩放：窗口高 → 目标角色高（默认 54px，与 D28 拼豆版接近）
##   5. 64×64 画布：水平居中 + 脚底对齐
##   6. 横排合成 sheet + 透明键检查（左上角 (0,0) 必须透明）
##
## 用法：python tools/gen_elin_anim_jpg.py [--target-h 54]
import argparse
import os
import sys
from collections import deque

from PIL import Image

SRC_DIR = r"D:\30DAYS\ART\RAW\elin"
OUT_DIR = r"D:\30DAYS\assets\sprites\characters"
GROUPS = [
    ("idle", 5),
    ("walk", 10),
    ("attack", 5),
    ("skill", 6),
    ("hit", 2),
]
BG_TOL = 100            # 抠底容差（用户拍板默认：抠净渐变/多色背景）
FRAME = 64              # 输出帧边长（sheet 高 = 64 → player.gd 自动推断帧数 = 宽÷高）
TARGET_H = 54           # 目标角色高（帧内，D28 拼豆版实测 54~59px）


def load_rgb(p):
    im = Image.open(p).convert("RGB")
    return im, im.load(), im.size


def floodfill_alpha(im, px, w, h, tol):
    """边缘种子 floodfill：连通背景 → 透明。返回 RGBA 图像。"""
    out = im.convert("RGBA")
    op = out.load()
    bg = px[0, 0]
    visited = [[False] * w for _ in range(h)]
    q = deque()
    for x in range(w):
        q.append((x, 0)); q.append((x, h - 1))
    for y in range(1, h - 1):
        q.append((0, y)); q.append((w - 1, y))
    for (x, y) in q:
        if not visited[y][x]:
            visited[y][x] = True
    while q:
        x, y = q.popleft()
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < w and 0 <= ny < h and not visited[ny][nx]:
                c = px[nx, ny]
                if max(abs(c[0] - bg[0]), abs(c[1] - bg[1]), abs(c[2] - bg[2])) <= tol:
                    visited[ny][nx] = True
                    q.append((nx, ny))
    for y in range(h):
        for x in range(w):
            if visited[y][x]:
                op[x, y] = (0, 0, 0, 0)
    return out


def bbox(im):
    px = im.load(); w, h = im.size
    xs = []; ys = []
    for y in range(h):
        for x in range(w):
            if px[x, y][3] > 0:
                xs.append(x); ys.append(y)
    if not xs:
        return None
    return (min(xs), min(ys), max(xs), max(ys))


def crop(im, box):
    return im.crop(box)


def process_group(name, count):
    """处理一组动作 → (frames: list[RGBA 已缩放 64×64], win, warns)。"""
    files = ["%s%d.jpg" % (name, i) for i in range(1, count + 1)]
    cutouts = []   # (fname, 裁剪后 RGBA, box)
    for f in files:
        p = os.path.join(SRC_DIR, f)
        if not os.path.exists(p):
            raise SystemExit("素材缺失: %s" % p)
        im, px, (w, h) = load_rgb(p)
        alpha = floodfill_alpha(im, px, w, h, BG_TOL)
        box = bbox(alpha)
        if box is None:
            raise SystemExit("角色为空: %s" % f)
        cutouts.append((f, crop(alpha, box), box))
    # 统一窗口 = 全帧 bbox 并集（原图坐标 → 裁剪后偏移换算）
    all_boxes = [b for _, _, b in cutouts]
    win = (min(b[0] for b in all_boxes), min(b[1] for b in all_boxes),
           max(b[2] for b in all_boxes), max(b[3] for b in all_boxes))
    win_w = win[2] - win[0] + 1
    win_h = win[3] - win[1] + 1
    scale = TARGET_H / win_h
    out_w = max(1, int(round(win_w * scale)))
    out_h = TARGET_H
    frames = []
    for f, cut, box in cutouts:
        # 以统一窗口为基准裁剪（窗口外的帧内容也保留，裁剪范围取窗口∩画布）
        cx0 = max(0, win[0] - box[0]); cy0 = max(0, win[1] - box[1])
        cx1 = min(cut.size[0], win[2] - box[0] + 1)
        cy1 = min(cut.size[1], win[3] - box[1] + 1)
        sub = cut.crop((cx0, cy0, cx1, cy1))
        # LANCZOS 缩放（AI 动画帧 → 像素画；不量化保原色）
        sub = sub.resize((out_w, out_h), Image.LANCZOS)
        # 64×64 画布：水平居中 + 脚底对齐
        canvas = Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))
        ox = (FRAME - out_w) // 2
        oy = FRAME - out_h
        canvas.paste(sub, (ox, oy), sub)
        frames.append((f, canvas))
    return frames, win, scale


def build_sheet(frames):
    n = len(frames)
    out = Image.new("RGBA", (FRAME * n, FRAME), (0, 0, 0, 0))
    for i, (fname, fr) in enumerate(frames):
        out.paste(fr, (i * FRAME, 0), fr)
    return out


def check_key(frame, label):
    """透明键协议：左上角 (0,0) 必须透明，否则全图镂空该色。"""
    px = frame.load()
    if px[0, 0][3] > 0:
        print("  !! WARN: %s 左上角 (0,0) 有色 %s —— 引擎会全图镂空该色！" % (label, str(px[0, 0])))


def stats(frames, label):
    total = 0
    max_op = 0
    for fname, fr in frames:
        px = fr.load()
        n = sum(1 for y in range(FRAME) for x in range(FRAME) if px[x, y][3] > 0)
        total += n
        max_op = max(max_op, n)
    print("  %s: %d 帧，每帧不透明像素≈%d（最大 %d）" % (label, len(frames), total // len(frames), max_op))


def main():
    global TARGET_H
    ap = argparse.ArgumentParser()
    ap.add_argument("--target-h", type=int, default=TARGET_H)
    args = ap.parse_args()
    TARGET_H = args.target_h
    print("== 艾琳 JPG 动画实装管线（抠底容差 %d · 目标角色高 %dpx · 帧 %d×%d）==" % (BG_TOL, TARGET_H, FRAME, FRAME))
    os.makedirs(OUT_DIR, exist_ok=True)
    ok = True
    for name, count in GROUPS:
        frames, win, scale = process_group(name, count)
        print("  %s: 统一窗口 %s → 缩放 %.3f → %dx%d 帧" % (
            name, str(win), scale, int(round((win[2] - win[0] + 1) * scale)), TARGET_H))
        sheet = build_sheet(frames)
        path = os.path.join(OUT_DIR, "elin_%s.png" % name)
        sheet.save(path)
        print("  %s sheet: %s (%dx%d)" % (name, path, sheet.size[0], sheet.size[1]))
        stats(frames, name)
        check_key(sheet, name)
        # 帧非空检查
        px = sheet.load()
        for i in range(count):
            nonempty = any(px[x, y][3] > 0 for y in range(FRAME) for x in range(i * FRAME, (i + 1) * FRAME))
            if not nonempty:
                print("  !! WARN: %s 第 %d 帧全空" % (name, i + 1))
    print("== 完成 ==")


if __name__ == "__main__":
    main()
