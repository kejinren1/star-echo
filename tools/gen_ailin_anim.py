## gen_ailin_anim.py — 艾琳拼豆图纸 → 游戏 sprite sheet 实装管线（v3 修正版）
##
## ⚠️ v3 关键修正（2026-08-08 17:2x 用户反馈「实现的不是很好」根因排查）：
##    实测源图纸画框 = 2400×2400px，网格细线间隔 = 40px → 画框实为 60×60 格 × 40px。
##    v1 误把整张图纸版面当角色图处理（floodfill + bbox）→ 产出是图纸模糊缩放，已废弃。
##    v2 误判格子 25px（64×64）→ 采样窗错位（豆色被板色/网格线污染）+ 只取画框左上
##    64 格（2400px 画框只取 1600px，角色右侧 + 下半身被裁掉），已废弃。
##
## 处理链（v3）：
##   1. 自动定位画框（深色主线检测 → (118, 298)，区间可调）
##   2. 自动测量格子尺寸（画框内纯板行的细线间隔众数 → 40px）
##   3. 自动计算格数（画框尺寸 ÷ 格尺寸 → 60×60）
##   4. 逐格提取豆色：格中心采样（避开网格线），排除板色（ΔRGB≤15，板色 (237,237,237)）
##      后取众数；采样区全板 = 空格 → 透明
##   5. 最大连通域剔除图纸装饰点（顶部/左侧的孤立灰点，与角色隔开）
##   6. 全帧角色 bbox 并集 = 统一裁剪窗口（画框坐标全帧一致 → 动画天然稳定）
##   7. 每帧窗口内容 → 64×64 画布（水平居中 + 脚底对齐）→ 横排合成 sheet：
##      elin_walk.png = 640×64（10 帧）/ elin_idle.png = 192×64（3 帧）
##      （输出帧保持 64×64 → player.gd _sheet_meta 自适应 + day21_22/day26 探针断言零改动）
##
## 用法：python tools/gen_ailin_anim.py
import os
from collections import Counter, deque
from PIL import Image

SRC_DIR = r"D:\Program Files\30DAYS\ART\CHARA\AILIN"
OUT_DIR = r"D:\Program Files\30DAYS\assets\sprites\characters"
WALK_FILES = ["WALK%d.png" % i for i in range(1, 11)]   # 帧序 = 文件名序
IDLE_FILES = ["idle%d.png" % i for i in range(1, 4)]
BOARD = (237, 237, 237)   # 图纸板色（实测）
BOARD_TOL = 15             # 板色容差（ΔRGB）
FRAME = 64                 # 输出帧尺寸（画布 64×64，sheet 高 64 兼容既有断言）

Y0_MIN, Y0_MAX = 150, 500  # 画框顶边搜索区间
X0_MIN, X0_MAX = 50, 300   # 画框左边搜索区间
X1_MIN, X1_MAX = 2200, 2600  # 画框右边搜索区间
Y1_MIN, Y1_MAX = 2500, 2900  # 画框底边搜索区间


def _load_rgb(p):
    im = Image.open(p).convert("RGB")
    return im, im.load(), im.size


def find_frame(p):
    """自动检测画框 (x0, y0, x1, y1)。返回 None 表示未找到。"""
    im, px, (w, h) = _load_rgb(p)

    def hline(y):
        return sum(1 for x in range(0, w, 2) if sum(px[x, y]) < 250) > w / 4

    def vline(x):
        return sum(1 for y in range(0, h, 2) if sum(px[x, y]) < 250) > h / 4

    y0 = next((y for y in range(Y0_MIN, Y0_MAX) if hline(y)), None)
    x0 = next((x for x in range(X0_MIN, X0_MAX) if vline(x)), None)
    x1 = next((x for x in range(X1_MIN, X1_MAX) if vline(x)), None)
    y1 = next((y for y in range(Y1_MIN, Y1_MAX) if hline(y)), None)
    if None in (x0, y0, x1, y1):
        return None
    return (x0, y0, x1, y1)


def measure_cell(p, frame):
    """测量格子尺寸：画框内一条纯板行上的细线间隔众数。"""
    im, px, _ = _load_rgb(p)
    x0, y0, x1, _ = frame
    # 找纯板行：画框顶边下第一条「非板色占比 < 5%」的行（允许细网格线穿过）
    probe = None
    for y in range(y0 + 4, y0 + 80):
        nonboard = 0
        total = 0
        for x in range(x0, x1, 5):
            total += 1
            c = px[x, y]
            if max(abs(c[0] - BOARD[0]), abs(c[1] - BOARD[1]), abs(c[2] - BOARD[2])) > BOARD_TOL:
                nonboard += 1
        if total and nonboard / total < 0.05:
            probe = y
            break
    if probe is None:
        raise SystemExit("未找到纯板行: %s" % p)
    # 该行细线位置（非板色线段）
    segs = []
    cur = None
    for x in range(x0, x1):
        c = px[x, probe]
        if max(abs(c[0] - BOARD[0]), abs(c[1] - BOARD[1]), abs(c[2] - BOARD[2])) > BOARD_TOL:
            if cur is None:
                cur = [x, x]
            else:
                cur[1] = x
        else:
            if cur:
                segs.append(tuple(cur))
                cur = None
    if cur:
        segs.append(tuple(cur))
    # 细线 = 非主线（主线是最大段，间距 = 10 格）；细线间隔众数（起点-起点，含线宽）
    gaps = [segs[i + 1][0] - segs[i][0] for i in range(len(segs) - 1)]
    if not gaps:
        raise SystemExit("纯板行无细线: %s" % p)
    cell = Counter(gaps).most_common(1)[0][0]
    if cell < 10 or cell > 80:
        raise SystemExit("格子尺寸异常 %dpx: %s" % (cell, p))
    return cell


def extract_bead_grid(p, frame, cell):
    """提取 N×N 格豆色 → (grid, n_grid)。grid[j][i] = rgb tuple 或 None（空格）。"""
    im, px, _ = _load_rgb(p)
    x0, y0, x1, y1 = frame
    n_grid = (x1 - x0) // cell
    off = max(4, cell // 7)          # 采样区偏移（避网格线：主线 4px + 细线 2px）
    sample = cell - 2 * off          # 采样区边长（格中心，实测豆子满格方形）
    grid = []
    for j in range(n_grid):
        row = []
        for i in range(n_grid):
            beads = Counter()
            for dy in range(sample):
                for dx in range(sample):
                    c = px[x0 + i * cell + off + dx, y0 + j * cell + off + dy]
                    if max(abs(c[0] - BOARD[0]), abs(c[1] - BOARD[1]), abs(c[2] - BOARD[2])) > BOARD_TOL:
                        beads[c] += 1
            row.append(beads.most_common(1)[0][0] if beads else None)
        grid.append(row)
    return grid, n_grid


def largest_component(grid):
    """最大 4-连通域（剔除图纸装饰点）。返回 comp 矩阵 + 主域 id + 各域尺寸。"""
    n = len(grid)
    comp = [[-1] * n for _ in range(n)]
    sizes = {}
    cid = 0
    for j in range(n):
        for i in range(n):
            if grid[j][i] is None or comp[j][i] >= 0:
                continue
            q = deque([(i, j)])
            comp[j][i] = cid
            size = 0
            while q:
                x, y = q.popleft()
                size += 1
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < n and 0 <= ny < n and grid[ny][nx] is not None and comp[ny][nx] < 0:
                        comp[ny][nx] = cid
                        q.append((nx, ny))
            sizes[cid] = size
            cid += 1
    if not sizes:
        return comp, -1, sizes
    return comp, max(sizes, key=sizes.get), sizes


def component_bbox(grid, comp, main):
    n = len(grid)
    cells = [(i, j) for j in range(n) for i in range(n) if comp[j][i] == main]
    if not cells:
        return None
    return (min(j for _, j in cells), max(j for _, j in cells),
            min(i for i, _ in cells), max(i for i, _ in cells))


def render_frame(grid, comp, main, win, frame_size=FRAME):
    """窗口内容 → frame_size×frame_size 画布（水平居中 + 脚底对齐）。"""
    n = len(grid)
    r0, r1, c0, c1 = win
    w, h = c1 - c0 + 1, r1 - r0 + 1
    off_x = (frame_size - w) // 2
    off_y = frame_size - 1 - r1          # 脚底（窗口底行）贴画布底
    fr = Image.new("RGBA", (frame_size, frame_size), (0, 0, 0, 0))
    fp = fr.load()
    for j in range(r0, r1 + 1):
        for i in range(c0, c1 + 1):
            if comp[j][i] == main and grid[j][i] is not None:
                c = grid[j][i]
                fp[off_x + (i - c0), off_y + (j - r0)] = (c[0], c[1], c[2], 255)
    return fr


def process(files, label):
    frames = []
    all_boxes = []
    for f in files:
        p = os.path.join(SRC_DIR, f)
        frame = find_frame(p)
        if frame is None:
            raise SystemExit("画框未找到: %s" % p)
        cell = measure_cell(p, frame)
        grid, n_grid = extract_bead_grid(p, frame, cell)
        comp, main, sizes = largest_component(grid)
        box = component_bbox(grid, comp, main)
        if box is None:
            raise SystemExit("角色为空: %s" % p)
        all_boxes.append(box)
        frames.append((f, grid, comp, main, box, cell, n_grid, sizes))
    # 统一窗口 = 全帧 bbox 并集（画框坐标全帧一致 → 动画稳定）
    win = (min(b[0] for _, _, _, _, b, _, _, _ in frames),
           max(b[1] for _, _, _, _, b, _, _, _ in frames),
           min(b[2] for _, _, _, _, b, _, _, _ in frames),
           max(b[3] for _, _, _, _, b, _, _, _ in frames))
    print("  %s: 画框 %s 格=%.1fpx N=%d 统一窗口(行%d..%d 列%d..%d)" % (
        label, "已检测", frames[0][5], frames[0][6], win[0], win[1], win[2], win[3]))
    out = [(f, render_frame(g, c, m, win)) for f, g, c, m, _, _, _, _ in frames]
    return out, win


def sheet(frames):
    n = len(frames)
    fh = frames[0][1].size[1]
    out = Image.new("RGBA", (fh * n, fh), (0, 0, 0, 0))
    for i, (name, fr) in enumerate(frames):
        out.paste(fr, (i * fh, 0), fr)
    return out


def stats(frames, label):
    total = 0
    for name, fr in frames:
        px = fr.load()
        n = sum(1 for y in range(fr.size[1]) for x in range(fr.size[0]) if px[x, y][3] > 0)
        total += n
    print("  %s: %d 帧，每帧豆格≈%d" % (label, len(frames), total // len(frames)))


def main():
    print("== 艾琳拼豆图纸实装管线 v3（60×60 格 × 40px 修正） ==")
    walk, w_win = process(WALK_FILES, "walk")
    idle, i_win = process(IDLE_FILES, "idle")
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
    for label, s in (("walk", w_sheet), ("idle", i_sheet)):
        p = s.load()
        if p[0, 0][3] > 0:
            print("!! WARN: %s sheet 左上角 (0,0) 有色 %s —— 该色会被引擎镂空" % (label, str(p[0, 0])))


if __name__ == "__main__":
    main()
