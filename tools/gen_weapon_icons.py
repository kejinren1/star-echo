#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Day 7 图标集生成工具：weapons.png 4 帧 → 40 帧（1280×32，每帧 32×32）。

对应 docs/TASKS.md D7-T3【W3】：
  · 15 帧实绘（MVP 15 把武器，像素风对齐 ART_STYLE v2：1-2px 描边 / 高饱和分类色）
  · 18 帧分类色占位（Day 8-9 逐帧替换为实绘）+ 7 帧空余（33-39）
  · 帧序 = D7-T5 定案映射：melee 0-7 / ranged 8-16 / elemental 17-25 / engineering 26-32
  · 透明键协议：背景全透明，左上角 (0,0) = 背景色（透明键），图标关键位置不用透明色

用法：
    python tools/gen_weapon_icons.py   # 生成 assets/sprites/ui/weapons.png
"""

import os
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "sprites", "ui", "weapons.png")

SIZE = 32
FRAMES = 40

# ---- 色板（高饱和分类色系 + 深色描边） ----
OUTLINE = (26, 30, 42, 255)      # 深蓝黑 1px 描边
MELEE = (198, 208, 226, 255)     # 银灰
MELEE_D = (150, 160, 180, 255)
RANGED = (176, 137, 104, 255)    # 棕
RANGED_D = (122, 90, 62, 255)
ELEM = (139, 123, 216, 255)      # 蓝紫
ELEM_D = (94, 80, 160, 255)
ENG = (232, 163, 61, 255)        # 橙黄
ENG_D = (198, 128, 32, 255)
RED = (232, 93, 58, 255)         # 火焰红
RED_D = (190, 60, 32, 255)
GOLD = (255, 215, 90, 255)       # 星辉金（签名武器点缀）
ICE = (127, 212, 245, 255)       # 冰蓝
ICE_D = (70, 150, 190, 255)
GREEN = (120, 200, 120, 255)     # 毒绿
GREEN_D = (60, 140, 80, 255)
LT = (255, 230, 100, 255)        # 闪电黄
WHITE = (240, 244, 255, 255)
BROWN = (150, 100, 62, 255)      # 木柄
PURPLE = (178, 102, 224, 255)    # 等离子紫（D8 新增）
PURPLE_D = (128, 62, 176, 255)
SHIELD = (90, 150, 230, 255)     # 力场蓝（D8 新增）
SHIELD_L = (150, 200, 255, 255)


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
        """Bresenham 直线。"""
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

    def diamond(self, cx, cy, r, c, o=OUTLINE):
        """菱形（带描边），r = 顶点半距。"""
        for dy in range(-r, r + 1):
            half = r - abs(dy)
            for dx in range(-half, half + 1):
                self.set(cx + dx, cy + dy, c)
        # 外描边
        for dy in range(-r - 1, r + 2):
            half = r + 1 - abs(dy)
            for dx in range(-half, half + 1):
                if self.px[cy + dy][cx + dx] is None:
                    self.set(cx + dx, cy + dy, o)

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
        """三角形（pts 顺时针/逆时针均可），带 1px 描边（外扩近似：先画放大三角）。"""
        xs = [p[0] for p in pts]
        ys = [p[1] for p in pts]
        minx, maxx = min(xs), max(xs)
        miny, maxy = min(ys), max(ys)
        for y in range(miny, maxy + 1):
            for x in range(minx, maxx + 1):
                if self._in_tri(x, y, pts):
                    self.set(x, y, c)
        # 描边：外扩 1px 三角
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


# ================= 15 帧实绘（MVP） =================

def ic_sword():
    """剑：银灰剑身 + 金色护手 + 棕柄（melee）。"""
    i = Icon()
    # 剑身（竖直，带 1px 描边）
    i.rect_o(14, 2, 4, 14, MELEE)
    i.rect(15, 3, 2, 12, WHITE)          # 高光
    # 护手
    i.rect_o(9, 16, 14, 2, GOLD)
    i.rect(10, 17, 12, 1, (200, 160, 60, 255))
    # 柄
    i.rect_o(14, 18, 4, 8, BROWN)
    i.rect(15, 20, 2, 5, (120, 74, 40, 255))
    # 剑尖
    i.tri([(16, 1), (13, 5), (19, 5)], MELEE)
    return i


def ic_chainsaw():
    """电锯：灰色机体 + 锯齿刃 + 橙色引擎（melee）。"""
    i = Icon()
    # 机体
    i.rect_o(4, 14, 16, 10, MELEE)
    i.rect(6, 16, 6, 6, MELEE_D)          # 引擎盖
    i.rect_o(20, 14, 6, 10, ENG)          # 引擎
    # 锯刃（前伸带齿）
    i.rect_o(8, 4, 16, 6, MELEE_D)
    for t in range(5):
        i.rect(10 + t * 3, 10, 2, 2, MELEE)  # 齿
    i.rect(9, 5, 14, 4, WHITE)             # 刃面高光
    # 把手
    i.rect_o(6, 24, 10, 3, (120, 74, 40, 255))
    return i


def ic_star_blade():
    """星刃：四角星 + 轨道圆环（melee·签名）。"""
    i = Icon()
    # 轨道环
    i.disc(16, 16, 13, None if False else (40, 50, 70, 255))
    for a in range(0, 360, 15):
        import math
        x = 16 + int(12 * math.cos(math.radians(a)))
        y = 16 + int(12 * math.sin(math.radians(a)))
        i.set(x, y, (90, 110, 150, 255))
    # 四角星（中心）
    i.tri([(16, 5), (13, 13), (19, 13)], GOLD)
    i.tri([(16, 27), (13, 19), (19, 19)], GOLD)
    i.tri([(5, 16), (13, 13), (13, 19)], GOLD)
    i.tri([(27, 16), (19, 13), (19, 19)], GOLD)
    i.rect_o(14, 14, 4, 4, WHITE)
    return i


def ic_pistol():
    """手枪：侧视小手枪（ranged）。"""
    i = Icon()
    # 枪管 + 套筒
    i.rect_o(3, 12, 18, 5, MELEE)
    i.rect(4, 13, 16, 3, WHITE)
    # 握把
    i.rect_o(12, 17, 7, 9, RANGED)
    i.rect(13, 19, 5, 6, RANGED_D)
    # 扳机护圈
    i.rect(12, 17, 2, 3, OUTLINE)
    i.rect(15, 15, 4, 2, OUTLINE)
    return i


def ic_smg():
    """冲锋枪：紧凑枪身 + 弹匣（ranged）。"""
    i = Icon()
    i.rect_o(2, 12, 20, 6, MELEE)          # 枪身
    i.rect(3, 13, 18, 4, WHITE)
    i.rect_o(4, 18, 5, 8, RANGED)          # 弹匣
    i.rect(5, 19, 3, 6, RANGED_D)
    i.rect_o(18, 10, 3, 3, MELEE_D)        # 瞄具
    i.rect_o(8, 26, 8, 3, (120, 74, 40, 255))  # 前握
    return i


def ic_shotgun():
    """霰弹枪：长枪管 + 泵动护木（ranged）。"""
    i = Icon()
    i.rect_o(2, 11, 24, 4, MELEE)          # 枪管
    i.rect(3, 12, 22, 2, WHITE)
    i.rect_o(2, 15, 10, 7, RANGED)         # 泵动护木
    i.rect(3, 16, 8, 5, RANGED_D)
    i.rect_o(12, 15, 12, 9, MELEE)         # 枪托/机匣
    i.rect(13, 17, 10, 5, MELEE_D)
    return i


def ic_sniper():
    """狙击枪：超长枪管 + 瞄准镜（ranged）。"""
    i = Icon()
    i.rect_o(2, 13, 26, 3, MELEE)          # 枪管
    i.rect(3, 14, 24, 1, WHITE)
    i.rect_o(10, 10, 8, 5, RANGED)         # 镜筒
    i.rect(11, 11, 6, 3, (30, 90, 140, 255))  # 镜片
    i.rect_o(14, 16, 12, 7, MELEE)         # 机匣+托
    i.rect(15, 18, 10, 3, MELEE_D)
    i.rect_o(4, 16, 6, 4, RANGED)          # 脚架
    return i


def ic_holy_staff():
    """光耀法杖：法杖 + 金色光环 + 圣光（ranged·签名）。"""
    i = Icon()
    i.rect_o(14, 2, 3, 22, BROWN)          # 杖身
    i.rect(15, 3, 1, 20, (120, 74, 40, 255))
    i.rect_o(12, 24, 7, 4, GOLD)           # 杖尾
    i.disc(16, 7, 6, GOLD)                 # 光环
    i.rect_o(14, 4, 4, 6, WHITE)           # 圣光核心
    i.rect(15, 1, 1, 3, WHITE)             # 顶部辉光
    return i


def ic_wand():
    """魔杖：短杖 + 蓝紫辉光尖端（elemental）。"""
    i = Icon()
    i.rect_o(13, 10, 3, 14, BROWN)         # 杖身
    i.rect(14, 11, 1, 12, (120, 74, 40, 255))
    i.tri([(14, 3), (11, 10), (17, 10)], ELEM)   # 尖端
    i.rect_o(14, 4, 4, 4, ELEM)            # 辉光宝石
    i.rect(15, 5, 2, 2, WHITE)
    i.set(15, 1, ELEM)
    return i


def ic_icicle():
    """冰锥：冰晶柱 + 高光（elemental）。"""
    i = Icon()
    i.tri([(16, 2), (10, 26), (22, 26)], ICE)
    i.rect(14, 8, 3, 12, WHITE)            # 高光
    i.line(10, 20, 13, 22, ICE_D)
    i.line(22, 20, 19, 22, ICE_D)
    return i


def ic_flamethrower():
    """火焰喷射器：喷口 + 火焰（elemental）。"""
    i = Icon()
    i.rect_o(3, 16, 16, 8, MELEE)          # 机身
    i.rect(4, 17, 14, 6, MELEE_D)
    i.rect_o(19, 15, 4, 10, ENG)           # 喷口
    i.rect(20, 16, 2, 8, ENG_D)
    # 火焰
    i.tri([(26, 14), (21, 20), (26, 22)], RED)
    i.tri([(29, 11), (24, 18), (29, 21)], GOLD)
    i.tri([(24, 17), (22, 20), (26, 20)], WHITE)
    i.rect_o(3, 24, 12, 4, (120, 74, 40, 255))  # 握把
    return i


def ic_star_flame():
    """炎星术：火球 + 四角星辉（elemental·签名）。"""
    i = Icon()
    i.disc(16, 17, 8, RED)
    i.disc(16, 17, 5, GOLD)
    i.rect(14, 15, 4, 4, WHITE)
    # 星辉
    i.tri([(16, 3), (13, 9), (19, 9)], GOLD)
    i.tri([(16, 31), (13, 25), (19, 25)], GOLD)
    i.tri([(3, 17), (9, 14), (9, 20)], GOLD)
    i.tri([(29, 17), (23, 14), (23, 20)], GOLD)
    # 外焰
    i.tri([(13, 9), (11, 12), (15, 11)], RED_D)
    i.tri([(19, 9), (21, 12), (17, 11)], RED_D)
    return i


def ic_turret():
    """炮台：基座 + 炮管（engineering）。"""
    i = Icon()
    i.rect_o(10, 20, 12, 6, ENG)           # 基座
    i.rect(11, 21, 10, 4, ENG_D)
    i.rect_o(13, 14, 6, 6, ENG)            # 转台
    i.rect(14, 15, 4, 4, (255, 220, 130, 255))
    i.rect_o(9, 8, 14, 4, ENG)             # 炮管
    i.rect(10, 9, 12, 2, (255, 220, 130, 255))
    i.rect(21, 10, 2, 1, OUTLINE)          # 炮口
    return i


def ic_landmine():
    """地雷：圆盘 + 尖刺（engineering）。"""
    i = Icon()
    i.disc(16, 18, 9, ENG)
    i.disc(16, 18, 5, ENG_D)
    i.disc(16, 18, 2, (255, 230, 160, 255))
    for (sx, sy) in [(1, 1), (-1, 1), (1, -1), (-1, -1)]:
        i.line(16, 18, 16 + sx * 13, 18 + sy * 13, OUTLINE, 2)
        i.line(16 + sx * 9, 18 + sy * 9, 16 + sx * 13, 18 + sy * 13, MELEE, 2)
    i.line(16, 18, 16, 4, OUTLINE, 2)
    i.line(16, 12, 16, 4, MELEE, 1)
    return i


def ic_auto_turret():
    """自动炮台：双管 + 天线（engineering·签名）。"""
    i = Icon()
    i.rect_o(8, 22, 16, 7, ENG)            # 基座
    i.rect(9, 23, 14, 5, ENG_D)
    i.rect_o(12, 16, 8, 6, ENG)            # 转台
    i.rect(13, 17, 6, 4, (255, 220, 130, 255))
    i.rect_o(6, 10, 10, 4, ENG)            # 双管
    i.rect(7, 11, 8, 2, (255, 220, 130, 255))
    i.rect_o(16, 10, 10, 4, ENG)
    i.rect(17, 11, 8, 2, (255, 220, 130, 255))
    i.line(14, 16, 13, 7, OUTLINE, 1)      # 天线
    i.set(13, 6, RED)
    return i


# ================= 18 帧实绘（D8-9 全量） =================

def ic_fist():
    """拳套：拳面 + 指节 + 腕带（melee·t1 攻速极快）。"""
    i = Icon()
    i.disc(16, 14, 8, MELEE)             # 拳面
    i.disc(16, 14, 5, MELEE_D)           # 内凹
    for k in range(4):                   # 指节
        i.rect(11 + k * 3, 7, 2, 2, WHITE)
    i.rect_o(11, 22, 10, 5, BROWN)       # 腕带
    i.rect(12, 23, 8, 3, (120, 74, 40, 255))
    return i


def ic_stick():
    """木棍：斜棍 + 深色端头（melee·t1 高击退）。"""
    i = Icon()
    i.line(4, 26, 24, 6, BROWN, 3)       # 斜棍
    i.line(6, 24, 23, 8, (120, 74, 40, 255), 1)  # 暗部
    i.line(8, 23, 22, 10, (180, 140, 96, 255), 1)  # 高光
    i.rect_o(22, 4, 8, 6, (170, 130, 90, 255))   # 端头
    return i


def ic_dagger():
    """匕首：细刃 + 金色护手 + 短柄（melee·t1 高暴击）。"""
    i = Icon()
    i.tri([(16, 2), (11, 16), (21, 16)], MELEE)  # 刃
    i.line(13, 8, 18, 12, WHITE, 1)              # 刃面高光
    i.rect_o(10, 16, 12, 2, GOLD)                # 护手
    i.rect(11, 17, 10, 1, (200, 160, 60, 255))
    i.rect_o(13, 18, 6, 9, BROWN)                # 柄
    i.rect(14, 20, 4, 6, (120, 74, 40, 255))
    return i


def ic_hammer():
    """大锤：重锤头 + 高光 + 长柄（melee·t3 范围AOE）。"""
    i = Icon()
    i.rect_o(7, 5, 18, 11, MELEE)        # 锤头
    i.rect(8, 6, 16, 9, MELEE_D)
    i.rect(10, 7, 6, 2, WHITE)           # 高光
    i.rect(9, 12, 14, 2, MELEE)
    i.rect_o(14, 16, 4, 12, BROWN)       # 柄
    i.rect(15, 18, 2, 9, (120, 74, 40, 255))
    return i


def ic_flaming_knuckles():
    """烈焰拳套：拳套 + 红焰（melee·t3 燃烧）。"""
    i = Icon()
    i.disc(13, 17, 7, MELEE)
    i.disc(13, 17, 4, MELEE_D)
    i.rect(11, 10, 2, 3, WHITE)          # 指节
    i.rect(14, 10, 2, 3, WHITE)
    i.tri([(22, 20), (26, 12), (29, 22)], RED)   # 外焰
    i.tri([(24, 19), (27, 13), (29, 20)], GOLD)  # 内焰
    i.tri([(23, 14), (26, 10), (28, 16)], RED_D)
    return i


def ic_slingshot():
    """弹弓：Y 叉 + 皮筋 + 弹丸（ranged·t1 弹射）。"""
    i = Icon()
    i.line(16, 26, 10, 8, BROWN, 2)      # 左叉
    i.line(16, 26, 22, 8, BROWN, 2)      # 右叉
    i.rect_o(13, 26, 6, 4, (120, 74, 40, 255))  # 握柄
    i.line(10, 8, 22, 8, RANGED_D, 2)    # 皮筋
    i.disc(16, 5, 3, RANGED)             # 弹丸
    i.rect(15, 4, 2, 2, RANGED_D)
    return i


def ic_crossbow():
    """弩：弩臂 + 弓弦 + 箭（ranged·t2 穿透3）。"""
    i = Icon()
    i.rect_o(12, 10, 8, 12, RANGED)      # 弩身
    i.rect(13, 11, 6, 10, RANGED_D)
    i.line(6, 8, 12, 12, MELEE, 2)       # 左弩臂
    i.line(26, 8, 20, 12, MELEE, 2)      # 右弩臂
    i.line(6, 8, 26, 8, OUTLINE, 1)      # 弓弦
    i.line(16, 22, 16, 3, MELEE_D, 1)    # 箭杆
    i.tri([(16, 2), (13, 7), (19, 7)], MELEE)    # 箭头
    return i


def ic_rocket_launcher():
    """火箭筒：筒身 + 红弹头 + 瞄具（ranged·t3 爆炸AOE）。"""
    i = Icon()
    i.rect_o(3, 12, 20, 8, MELEE)        # 筒身
    i.rect(4, 13, 18, 6, MELEE_D)
    i.rect_o(23, 11, 6, 10, RED)         # 弹头
    i.rect(24, 12, 4, 8, RED_D)
    i.tri([(30, 16), (27, 13), (27, 19)], GOLD)  # 弹头尖
    i.rect_o(10, 20, 8, 5, RANGED)       # 握把
    i.rect(11, 21, 6, 3, RANGED_D)
    i.rect_o(19, 8, 4, 3, ENG)           # 瞄具
    return i


def ic_minigun():
    """多管机枪：3 管 + 机匣 + 弹链匣（ranged·t4 极限射速）。"""
    i = Icon()
    i.rect_o(3, 11, 9, 10, MELEE)        # 机匣
    i.rect(4, 12, 7, 8, MELEE_D)
    i.rect_o(12, 8, 17, 4, MELEE)        # 上管
    i.rect_o(12, 12, 17, 4, MELEE_D)     # 中管
    i.rect_o(12, 16, 17, 4, MELEE)       # 下管
    i.rect(13, 9, 15, 2, WHITE)          # 管口高光
    i.rect_o(8, 21, 8, 5, RANGED)        # 弹链匣
    i.rect(9, 22, 6, 3, RANGED_D)
    return i


def ic_lightning_shiv():
    """雷刃：短刃 + 闪电黄纹（elemental·t2 连锁3）。"""
    i = Icon()
    i.tri([(16, 2), (11, 18), (21, 18)], ELEM)   # 刃
    i.line(14, 6, 16, 12, LT, 1)                 # 闪电纹
    i.line(16, 9, 14, 13, LT, 1)
    i.line(15, 4, 13, 8, LT, 1)
    i.rect_o(11, 18, 10, 2, ELEM_D)              # 护手
    i.rect_o(14, 20, 4, 7, BROWN)                # 柄
    i.rect(15, 21, 2, 5, (120, 74, 40, 255))
    return i


def ic_venom_staff():
    """毒杖：杖 + 绿滴尖端（elemental·t2 中毒5秒）。"""
    i = Icon()
    i.rect_o(14, 8, 3, 16, BROWN)        # 杖身
    i.rect(15, 9, 1, 14, (120, 74, 40, 255))
    i.disc(15, 6, 4, GREEN)              # 毒珠
    i.disc(15, 6, 2, GREEN_D)
    i.rect(14, 3, 2, 2, (180, 255, 160, 255))    # 高光
    i.rect_o(12, 24, 7, 4, (120, 74, 40, 255))   # 杖尾
    return i


def ic_storm_staff():
    """风暴杖：杖 + 闪电球（elemental·t3 范围闪电）。"""
    i = Icon()
    i.rect_o(14, 12, 3, 12, BROWN)       # 杖身
    i.rect(15, 13, 1, 10, (120, 74, 40, 255))
    i.disc(15, 7, 6, ELEM)               # 雷球
    i.disc(15, 7, 3, ELEM_D)
    i.line(9, 7, 21, 7, LT, 1)           # 电弧
    i.line(15, 1, 15, 13, LT, 1)
    i.line(11, 3, 19, 11, LT, 1)
    return i


def ic_frost_nova():
    """冰霜新星：冰晶六芒 + 光环（elemental·t3 冻结AOE）。"""
    import math
    i = Icon()
    i.disc(16, 16, 5, ICE)               # 中心
    i.disc(16, 16, 3, WHITE)
    i.tri([(16, 3), (13, 10), (19, 10)], ICE)    # 六芒上
    i.tri([(16, 29), (13, 22), (19, 22)], ICE)   # 六芒下
    i.tri([(3, 16), (10, 13), (10, 19)], ICE)    # 六芒左
    i.tri([(29, 16), (22, 13), (22, 19)], ICE)   # 六芒右
    for a in range(0, 360, 20):          # 光环
        x = 16 + int(13 * math.cos(math.radians(a)))
        y = 16 + int(13 * math.sin(math.radians(a)))
        i.set(x, y, ICE_D)
    return i


def ic_plasma_cannon():
    """等离子炮：炮管 + 紫球（elemental·t4 穿透所有）。"""
    i = Icon()
    i.rect_o(3, 13, 16, 6, MELEE)        # 炮管
    i.rect(4, 14, 14, 4, MELEE_D)
    i.disc(22, 16, 6, PURPLE)            # 等离子球
    i.disc(22, 16, 3, PURPLE_D)
    i.rect(21, 13, 2, 2, WHITE)          # 高光
    i.rect_o(18, 9, 5, 3, MELEE)         # 散热片
    i.rect_o(6, 19, 8, 5, BROWN)         # 握把
    i.rect(7, 20, 6, 3, (120, 74, 40, 255))
    return i


def ic_wrench():
    """扳手：开口头 + 柄（engineering·t2 修复结构物）。"""
    i = Icon()
    i.disc(10, 10, 6, ENG)               # 开口环
    i.disc(10, 10, 3, OUTLINE)           # 开口（深孔）
    i.rect_o(12, 13, 11, 4, ENG)         # 柄
    i.rect(13, 14, 9, 2, ENG_D)
    i.rect_o(20, 17, 5, 8, ENG)          # 尾部
    i.rect(21, 18, 3, 6, ENG_D)
    i.rect(9, 7, 2, 2, WHITE)            # 环高光
    return i


def ic_laser_turret():
    """激光炮台：基座 + 炮管 + 红激光（engineering·t2 持续激光）。"""
    i = Icon()
    i.rect_o(10, 22, 12, 6, ENG)         # 基座
    i.rect(11, 23, 10, 4, ENG_D)
    i.rect_o(13, 16, 6, 6, ENG)          # 转台
    i.rect(14, 17, 4, 4, (255, 220, 130, 255))
    i.rect_o(11, 8, 10, 6, ENG)          # 炮管
    i.rect(12, 9, 8, 4, (255, 220, 130, 255))
    i.line(4, 11, 9, 11, RED, 1)         # 激光束
    i.disc(11, 11, 2, RED)               # 激光源
    i.set(4, 11, GOLD)                   # 光点
    return i


def ic_mech_arm():
    """机械臂：关节臂 + 钳爪（engineering·t3 挥击+导弹）。"""
    i = Icon()
    i.rect_o(6, 16, 12, 5, ENG)          # 上臂
    i.rect(7, 17, 10, 3, ENG_D)
    i.disc(18, 18, 4, MELEE)             # 关节
    i.disc(18, 18, 2, MELEE_D)
    i.rect_o(19, 13, 8, 5, ENG)          # 前臂
    i.rect(20, 14, 6, 3, (255, 220, 130, 255))
    i.tri([(28, 10), (24, 13), (28, 14)], MELEE)  # 上钳
    i.tri([(28, 22), (24, 19), (28, 18)], MELEE)  # 下钳
    i.rect(8, 15, 3, 1, WHITE)           # 臂高光
    return i


def ic_force_field():
    """力场护盾：蓝球 + 光晕（engineering·t3 减伤50%）。"""
    import math
    i = Icon()
    i.disc(16, 16, 8, SHIELD)            # 护盾球
    i.disc(16, 16, 5, SHIELD_L)
    i.disc(16, 16, 2, WHITE)
    for a in range(0, 360, 15):          # 光晕环
        x = 16 + int(11 * math.cos(math.radians(a)))
        y = 16 + int(11 * math.sin(math.radians(a)))
        i.set(x, y, (70, 120, 200, 255))
    return i


# ================= 占位帧（分类色 + 类别简形） =================

def ic_placeholder(cat):
    """分类色占位：深底 + 类别简形（Day 8-9 逐帧替换为实绘）。"""
    i = Icon()
    if cat == "melee":
        body, shape = MELEE_D, "sword_s"
    elif cat == "ranged":
        body, shape = RANGED_D, "gun_s"
    elif cat == "elemental":
        body, shape = ELEM_D, "wand_s"
    else:
        body, shape = ENG_D, "gear_s"
    i.rect(1, 1, 30, 30, (0, 0, 0, 0))
    # 四角小圆点装饰
    for (x, y) in [(4, 4), (27, 4), (4, 27), (27, 27)]:
        i.set(x, y, body)
    # 居中简形
    if shape == "sword_s":
        i.rect_o(14, 5, 3, 14, body)
        i.rect_o(11, 19, 9, 2, body)
        i.tri([(15, 3), (13, 7), (17, 7)], body)
    elif shape == "gun_s":
        i.rect_o(5, 13, 18, 4, body)
        i.rect_o(16, 17, 6, 7, body)
    elif shape == "wand_s":
        i.rect_o(14, 8, 3, 14, body)
        i.disc(15, 7, 3, body)
    else:  # gear_s
        i.disc(16, 16, 5, body)
        i.rect_o(8, 15, 16, 3, body)
        i.rect_o(15, 8, 3, 16, body)
    return i


# ================= 帧表 =================

def build():
    # id → 绘制函数；None = 分类色占位
    frames = {
        # melee 0-7
        0: ic_fist,
        1: ic_stick,
        2: ic_dagger,
        3: ic_sword,
        4: ic_hammer,
        5: ic_chainsaw,
        6: ic_flaming_knuckles,
        7: ic_star_blade,
        # ranged 8-16
        8: ic_pistol,
        9: ic_slingshot,
        10: ic_crossbow,
        11: ic_smg,
        12: ic_shotgun,
        13: ic_sniper,
        14: ic_rocket_launcher,
        15: ic_minigun,
        16: ic_holy_staff,
        # elemental 17-25
        17: ic_wand,
        18: ic_icicle,
        19: ic_lightning_shiv,
        20: ic_flamethrower,
        21: ic_venom_staff,
        22: ic_storm_staff,
        23: ic_frost_nova,
        24: ic_plasma_cannon,
        25: ic_star_flame,
        # engineering 26-32
        26: ic_turret,
        27: ic_landmine,
        28: ic_wrench,
        29: ic_laser_turret,
        30: ic_mech_arm,
        31: ic_force_field,
        32: ic_auto_turret,
    }
    cat_of = {}
    for idx in range(0, 8):
        cat_of[idx] = "melee"
    for idx in range(8, 17):
        cat_of[idx] = "ranged"
    for idx in range(17, 26):
        cat_of[idx] = "elemental"
    for idx in range(26, 33):
        cat_of[idx] = "engineering"

    sheet = Image.new("RGBA", (SIZE * FRAMES, SIZE), (0, 0, 0, 0))
    for idx in range(FRAMES):
        if idx in frames and frames[idx] is not None:
            img = frames[idx]().render()
        elif idx in cat_of:
            img = ic_placeholder(cat_of[idx]).render()
        else:
            img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))  # 33-39 空余
        sheet.paste(img, (idx * SIZE, 0))
    sheet.save(OUT)
    print("已生成 %s: %dx%d（%d 帧 × %d×%d）" % (OUT, sheet.width, sheet.height, FRAMES, SIZE, SIZE))


if __name__ == "__main__":
    build()
