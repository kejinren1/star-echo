#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Day 20 技能图标集生成工具（T-D · P0 调度硬性输入）：skills.png 4 帧（128×32，每帧 32×32）。

对应 docs/TASKS.md D20-T7【W3 主责 + W1 协作】：
  · 4 帧实绘（帧序 = 映射 {se_skill_fireball:0, se_skill_deploy_turret:1, se_skill_blade_burst:2, se_skill_holy_shield:3}）：
      se_skill_fireball      炽星火球：橙红火球 + 焰尾（艾琳）
      se_skill_deploy_turret 机械矩阵：炮塔 + 齿轮（诺亚）
      se_skill_blade_burst   剑域绽放：剑刃圆环 + 光点（莱恩）
      se_skill_holy_shield   神圣庇护：白蓝护盾 + 十字光（希亚）
  · 像素风对齐 ART_STYLE v2（32px 图标基准同 weapons.png）：1px 描边 + 高饱和分类色
  · 透明键协议：背景全透明，左上角 (0,0) 保持透明键，图标关键位置不用透明色
  · 216 色上限（锚点色板容差归并 ΔRGB≤12 由 ART_STYLE 字典登记制管理，生成后全图色数校验）

用法：
    python tools/gen_skill_icons.py   # 生成 assets/sprites/skills/skills.png（新建目录）
    （.import 由 godot --headless --import 补）
"""

import os
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "sprites", "skills", "skills.png")

SIZE = 32
FRAMES = 4

# ---- 色板（对齐 ART_STYLE v2 锚点色板容差，同 gen_weapon_icons.py 分类色） ----
OUTLINE = (26, 30, 42, 255)      # 深蓝黑 1px 描边
WHITE = (240, 244, 255, 255)
RED = (232, 93, 58, 255)         # 火焰橙红
RED_D = (190, 60, 32, 255)
GOLD = (255, 215, 90, 255)       # 金
GOLD_D = (200, 160, 60, 255)
BLUE = (90, 150, 230, 255)       # 防御蓝
BLUE_D = (50, 100, 180, 255)
BLUE_L = (150, 200, 255, 255)
STEEL = (150, 160, 180, 255)     # 铁灰
STEEL_D = (100, 110, 130, 255)
DARK = (40, 46, 62, 255)         # 深蓝黑
PURPLE = (178, 102, 224, 255)    # 剑域紫
PURPLE_D = (128, 62, 176, 255)
CYAN = (127, 212, 245, 255)      # 机械青


class Icon:
    def __init__(self):
        self.px = [[None] * SIZE for _ in range(SIZE)]

    def set(self, x, y, c):
        if 0 <= x < SIZE and 0 <= y < SIZE:
            self.px[y][x] = c

    def rect(self, x, y, w, h, c):
        for j in range(y, y + h):
            for i in range(x, x + w):
                self.set(i, j, c)

    def rect_o(self, x, y, w, h, c, o=OUTLINE):
        """实心矩形 + 1px 描边（描边在外扩 1px）。"""
        self.rect(x - 1, y - 1, w + 2, h + 2, o)
        self.rect(x, y, w, h, c)

    def line(self, x0, y0, x1, y1, c, thick=1):
        dx, dy = abs(x1 - x0), abs(y1 - y0)
        sx, sy = (1 if x0 < x1 else -1), (1 if y0 < y1 else -1)
        err = dx - dy
        while True:
            for t in range(thick):
                self.set(x0 + t if sx > 0 else x0 - t, y0, c)
            if x0 == x1 and y0 == y1:
                break
            e2 = 2 * err
            if e2 > -dy:
                err -= dy
                x0 += sx
            if e2 < dx:
                err += dx
                y0 += sy

    def disc(self, cx, cy, r, c, o=OUTLINE):
        for dy in range(-r, r + 1):
            for dx in range(-r, r + 1):
                if dx * dx + dy * dy <= r * r:
                    self.set(cx + dx, cy + dy, c)
        for dy in range(-r - 1, r + 2):
            for dx in range(-r - 1, r + 2):
                ox, oy = cx + dx, cy + dy
                if 0 <= ox < SIZE and 0 <= oy < SIZE and dx * dx + dy * dy <= (r + 1) * (r + 1) and self.px[oy][ox] is None:
                    self.set(ox, oy, o)

    def tri(self, pts, c, o=OUTLINE):
        xs = [p[0] for p in pts]
        ys = [p[1] for p in pts]
        minx, maxx = min(xs), max(xs)
        miny, maxy = min(ys), max(ys)
        for y in range(miny, maxy + 1):
            for x in range(minx, maxx + 1):
                if self._in_tri(x, y, pts):
                    self.set(x, y, c)
        pts_o = []
        for (x, y) in pts:
            cx, cy = sum(xs) / 3, sum(ys) / 3
            dx, dy = x - cx, y - cy
            if abs(dx) + abs(dy) == 0:
                dx, dy = 1, 0
            ln = (dx * dx + dy * dy) ** 0.5
            pts_o.append((int(x + dx / ln), int(y + dy / ln)))
        for y in range(miny - 1, maxy + 2):
            for x in range(minx - 1, maxx + 2):
                if 0 <= x < SIZE and 0 <= y < SIZE and self._in_tri(x, y, pts_o) and self.px[y][x] is None:
                    self.set(x, y, o)

    @staticmethod
    def _in_tri(x, y, pts):
        def sign(a, b, c_):
            return (a[0] - c_[0]) * (b[1] - c_[1]) - (b[0] - c_[0]) * (a[1] - c_[1])
        d1 = sign((x, y), pts[0], pts[1])
        d2 = sign((x, y), pts[1], pts[2])
        d3 = sign((x, y), pts[2], pts[0])
        has_neg = d1 < 0 or d2 < 0 or d3 < 0
        has_pos = d1 > 0 or d2 > 0 or d3 > 0
        return not (has_neg and has_pos)

    def render(self):
        img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        for y in range(SIZE):
            for x in range(SIZE):
                c = self.px[y][x]
                if c is not None:
                    img.putpixel((x, y), c)
        return img


# ================= 4 帧实绘（帧序 = 技能 id 映射） =================

def ic_fireball():
    """炽星火球：橙红火球 + 焰尾 + 星点（艾琳·se_skill_fireball）。"""
    i = Icon()
    i.disc(17, 15, 8, RED)                  # 火球主体
    i.disc(17, 15, 8, None)
    i.disc(17, 15, 5, GOLD)                 # 内核
    i.disc(17, 15, 3, WHITE)                # 高光
    i.tri([(17, 4), (13, 12), (21, 12)], RED_D)   # 上焰
    i.tri([(8, 15), (2, 12), (9, 19)], RED_D)     # 左焰
    i.tri([(27, 13), (23, 20), (29, 20)], RED)    # 右小焰
    i.tri([(15, 20), (12, 26), (18, 25)], RED_D)  # 下焰
    i.set(12, 9, GOLD)                      # 焰星
    i.set(23, 8, GOLD)
    return i


def ic_deploy_turret():
    """机械矩阵：炮塔 + 齿轮 + 基座（诺亚·se_skill_deploy_turret）。"""
    i = Icon()
    i.rect_o(9, 18, 14, 8, STEEL)           # 基座
    i.rect(10, 19, 12, 6, (170, 180, 200, 255))
    i.rect_o(12, 13, 8, 6, STEEL)           # 塔身
    i.rect(13, 14, 6, 4, STEEL_D)
    i.rect_o(18, 8, 12, 6, RED)             # 炮管
    i.rect(19, 9, 10, 4, (245, 120, 90, 255))
    i.disc(8, 9, 4, STEEL)                  # 齿轮
    i.disc(8, 9, 4, None)
    i.disc(8, 9, 2, CYAN)                   # 齿轮蓝芯
    i.set(7, 7, WHITE)
    i.set(13, 11, WHITE)                    # 塔身高光
    return i


def ic_blade_burst():
    """剑域绽放：剑刃圆环 + 星点（莱恩·se_skill_blade_burst）。"""
    i = Icon()
    import math
    for a in range(0, 360, 12):             # 剑刃环
        x = 16 + int(12 * math.cos(math.radians(a)))
        y = 16 + int(12 * math.sin(math.radians(a)))
        i.set(x, y, PURPLE)
        i.set(x, y, None)
        i.set(16 + int(13 * math.cos(math.radians(a + 6))), 16 + int(13 * math.sin(math.radians(a + 6))), PURPLE)
    for a in range(0, 360, 12):
        x = 16 + int(8 * math.cos(math.radians(a)))
        y = 16 + int(8 * math.sin(math.radians(a)))
        i.set(x, y, BLUE_L)
    # 中央剑刃四向
    i.tri([(16, 3), (13, 12), (19, 12)], PURPLE)   # 上刃
    i.tri([(16, 29), (13, 20), (19, 20)], PURPLE_D)  # 下刃
    i.tri([(3, 16), (12, 13), (12, 19)], PURPLE)   # 左刃
    i.tri([(29, 16), (20, 13), (20, 19)], PURPLE_D)  # 右刃
    i.disc(16, 16, 3, GOLD)                 # 中心光核
    i.disc(16, 16, 1, WHITE)
    i.set(11, 8, WHITE)                     # 星点
    i.set(22, 24, WHITE)
    return i


def ic_holy_shield():
    """神圣庇护：白蓝护盾 + 十字光 + 光环（希亚·se_skill_holy_shield）。"""
    i = Icon()
    i.tri([(16, 4), (7, 9), (25, 9)], BLUE)       # 盾顶
    i.rect_o(7, 9, 18, 16, BLUE)            # 盾身
    i.rect(8, 10, 16, 14, (110, 170, 240, 255))
    i.rect(15, 11, 2, 12, WHITE)            # 十字竖
    i.rect(10, 15, 12, 2, WHITE)            # 十字横
    i.rect(7, 22, 18, 3, BLUE_D)            # 盾底
    i.disc(16, 12, 1, GOLD)                 # 十字顶光
    # 外圈光晕
    import math
    for a in range(0, 360, 20):
        x = 16 + int(15 * math.cos(math.radians(a)))
        y = 16 + int(15 * math.sin(math.radians(a)))
        i.set(x, y, WHITE if a % 40 == 0 else GOLD)
    return i


# ================= 帧表 =================

def build():
    frames = {
        0: ic_fireball,
        1: ic_deploy_turret,
        2: ic_blade_burst,
        3: ic_holy_shield,
    }
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    sheet = Image.new("RGBA", (SIZE * FRAMES, SIZE), (0, 0, 0, 0))
    for idx in range(FRAMES):
        if idx in frames:
            img = frames[idx]().render()
        else:
            img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        sheet.paste(img, (idx * SIZE, 0))
    sheet.save(OUT)
    print("已生成 %s: %dx%d（%d 帧 × %d×%d）" % (OUT, sheet.width, sheet.height, FRAMES, SIZE, SIZE))
    # 色数校验（ART_STYLE v2 216 色上限）
    colors = {sheet.getpixel((x, y)) for x in range(sheet.width) for y in range(SIZE) if sheet.getpixel((x, y))[3] > 0}
    print("全图唯一色数（含透明键背景不计）: %d（≤216 ✅）" % len(colors))
    assert len(colors) <= 216, "色数超限"


if __name__ == "__main__":
    build()
