## gen_ailin_anim.py — 艾琳拼豆图纸 → 游戏 sprite sheet 实装管线（v2 修正版）
##
## ⚠️ v2 关键修正（2026-08-08 用户纠正）：用户提供的 PNG 是【拼豆图纸】，不是角色原图！
##    真正的图像在【中间带坐标的画框】内：64×64 格 × 每格 25px，画框起点 (118, 298)。
##    v1 误把整张图纸版面当角色图处理（floodfill 抠背景 + bbox 裁剪），产出是图纸的
##    模糊缩放而非拼豆图像 —— 已废弃。
##
## 处理链（v2）：
##   1. 定位画框（自动检测主线：深色线间距 400px → 每 16 格主线 → 每格 25px）
##   2. 逐格提取豆色：排除板色（ΔRGB≤15，板色 #ededed 系）后取众数；无剩余 = 空格 → 透明
##   3. 输出 64×64 帧（每格 1px）→ 横排合成 sheet：
##      elin_walk.png = 640×64（10 帧）/ elin_idle.png = 192×64（3 帧）
##
## 用法：python tools/gen_ailin_anim.py
import os
from collections import Counter
from PIL import Image

SRC_DIR = r"D:\Program Files\30DAYS\ART\CHARA\AILIN"
OUT_DIR = r"D:\Program Files\30DAYS\assets\sprites\characters"
WALK_FILES = ["WALK%d.png" % i for i in range(1, 11)]   # 帧序 = 文件名序
IDLE_FILES = ["idle%d.png" % i for i in range(1, 4)]
GRID = 64            # 拼豆图纸格数（64×64）
CELL = 25            # 图纸每格像素
SAMPLE_OFF = 5       # 采样区偏移（避开格边界网格线：主线 4px + 细线 1px）
SAMPLE = 15          # 采样区边长（中心 15×15）
BOARD_TOL = 15       # 板色容差（ΔRGB）
Y0_MIN, Y0_MAX = 200, 400   # 画框顶边搜索区间
X0_MIN, X0_MAX = 50, 250    # 画框左边搜索区间


def find_frame_origin(p):
    """自动检测画框起点 (x0, y0)。返回 None 表示未找到。"""
    im = Image.open(p).convert("RGB")
    w, h = im.size
    px = im.load()

    def hline(y):
        return sum(1 for x in range(0, w, 2) if sum(px[x, y]) < 250) > w / 4

    def vline(x):
        return sum(1 for y in range(0, h, 2) if sum(px[x, y]) < 250) > h / 4

    y0 = next((y for y in range(Y0_MIN, Y0_MAX) if hline(y)), None)
    x0 = next((x for x in range(X0_MIN, X0_MAX) if vline(x)), None)
    return (x0, y0) if (y0 is not None and x0 is not None) else None


def extract_bead_grid(p):
    """提取 64×64 格豆色 → (grid, palette_stats)。grid[j][i] = rgb tuple 或 None。"""
    im = Image.open(p).convert("RGB")
    w, h = im.size
    px = im.load()
    origin = find_frame_origin(p)
    if origin is None:
        raise SystemExit("画框未找到: %s" % p)
    x0, y0 = origin
    # 校验：画框 64 格 × 25px 是否在画布内
    if x0 + GRID * CELL > w or y0 + GRID * CELL > h:
        raise SystemExit("画框越界: %s (%d,%d)" % (p, x0, y0))
    grid = []
    for j in range(GRID):
        row = []
        for i in range(GRID):
            # 板色系合并为一个桶（板色有渲染阴影微变，不能当独立色参与众数竞争）
            # 采样取格中心 SAMPLE×SAMPLE 区域，避开格边界网格线（主线 4px / 细线 1px）
            board = 0
            beads = Counter()
            for dy in range(SAMPLE):
                for dx in range(SAMPLE):
                    c = px[x0 + i * CELL + SAMPLE_OFF + dx, y0 + j * CELL + SAMPLE_OFF + dy]
                    if max(abs(c[0] - 237), abs(c[1] - 237), abs(c[2] - 237)) <= BOARD_TOL:
                        board += 1
                    else:
                        beads[c] += 1
            if not beads:
                row.append(None)
            else:
                row.append(beads.most_common(1)[0][0])
        grid.append(row)
    return grid, origin


def render_frame(grid):
    """64×64 格 → 64×64 RGBA 帧（每格 1px；空格透明）"""
    fr = Image.new("RGBA", (GRID, GRID), (0, 0, 0, 0))
    fp = fr.load()
    for j in range(GRID):
        for i in range(GRID):
            c = grid[j][i]
            if c is not None:
                fp[i, j] = (c[0], c[1], c[2], 255)
    return fr


def process(files, label):
    frames = []
    origins = set()
    for f in files:
        p = os.path.join(SRC_DIR, f)
        grid, origin = extract_bead_grid(p)
        origins.add(origin)
        frames.append((f, render_frame(grid)))
    print("  %s: 画框起点 %s（全部一致=%s）" % (label, origins, len(origins) == 1))
    return frames


def sheet(frames):
    n = len(frames)
    out = Image.new("RGBA", (GRID * n, GRID), (0, 0, 0, 0))
    for i, (name, fr) in enumerate(frames):
        out.paste(fr, (i * GRID, 0), fr)
    return out


def stats(frames, label):
    total_beads = 0
    for name, fr in frames:
        px = fr.load()
        n = sum(1 for y in range(GRID) for x in range(GRID) if px[x, y][3] > 0)
        total_beads += n
    print("  %s: %d 帧，每帧豆数=%s" % (label, len(frames), total_beads // len(frames)))


def main():
    print("== 艾琳拼豆图纸实装管线 v2 ==")
    walk = process(WALK_FILES, "walk")
    idle = process(IDLE_FILES, "idle")
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
    # 透明键协议检查：左上角 (0,0) 若有色 → 该色会成为透明键被镂空，须警告
    wp = w_sheet.load()
    ip = i_sheet.load()
    if wp[0, 0][3] > 0:
        print("!! WARN: walk sheet 左上角 (0,0) 有色 %s —— 该色会被引擎镂空" % str(wp[0, 0]))
    if ip[0, 0][3] > 0:
        print("!! WARN: idle sheet 左上角 (0,0) 有色 %s —— 该色会被引擎镂空" % str(ip[0, 0]))


if __name__ == "__main__":
    main()
