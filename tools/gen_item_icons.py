#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Day 11-12 被动图标集生成工具：items.png 4 帧 → 20 帧（640×32，每帧 32×32）。

对应 docs/TASKS.md D11-12-T6【W3 / W1 协作】：
  · 20 帧实绘（帧序与 D11-12-PRE 的 icon_index 分配一致，见 gen_passives_day11.py PASSIVES）
  · 含 3 进化核心特征图标：se_flame_core 烈焰红 / se_mech_core 机械蓝灰 / se_blade_core 星刃青紫
  · 像素风对齐 ART_STYLE v2（32px 图标基准）：1px 描边 + 高饱和分类色
  · 透明键协议：背景全透明，左上角 (0,0) 保持透明键，图标关键位置不用透明色

用法：
    python tools/gen_item_icons.py   # 生成 assets/sprites/ui/items.png
"""

import os
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "sprites", "ui", "items.png")

SIZE = 32
FRAMES = 20

# ---- 色板 ----
OUTLINE = (26, 30, 42, 255)      # 深蓝黑 1px 描边
WHITE = (240, 244, 255, 255)
RED = (232, 93, 58, 255)         # 攻击红
RED_D = (190, 60, 32, 255)
GOLD = (255, 215, 90, 255)       # 金
GOLD_D = (200, 160, 60, 255)
BLUE = (90, 150, 230, 255)       # 防御蓝
BLUE_D = (50, 100, 180, 255)
BLUE_L = (150, 200, 255, 255)
GREEN = (120, 200, 120, 255)     # 生命绿
GREEN_D = (60, 140, 80, 255)
BROWN = (150, 100, 62, 255)      # 木/棕
BROWN_D = (110, 70, 40, 255)
BROWN_L = (198, 158, 108, 255)
PINK = (240, 140, 190, 255)      # 果冻粉
PURPLE = (178, 102, 224, 255)    # 星刃紫
PURPLE_D = (128, 62, 176, 255)
CYAN = (127, 212, 245, 255)      # 机械青
STEEL = (150, 160, 180, 255)     # 铁灰
STEEL_D = (100, 110, 130, 255)
DARK = (40, 46, 62, 255)         # 深蓝黑（机械核心底）


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


# ================= 20 帧实绘（帧序 = icon_index） =================

def ic_coffee():
    """咖啡：马克杯 + 热气（attack·攻速）。"""
    i = Icon()
    i.rect_o(9, 14, 12, 11, BROWN)          # 杯身
    i.rect(10, 15, 10, 9, (170, 130, 90, 255))
    i.rect(12, 17, 5, 3, BROWN_D)           # 咖啡面
    i.rect_o(21, 16, 4, 5, BROWN)           # 杯把
    i.rect(22, 17, 2, 3, (170, 130, 90, 255))
    i.set(12, 9, WHITE)                     # 热气
    i.set(14, 7, WHITE)
    i.set(16, 9, WHITE)
    i.set(13, 5, WHITE)
    i.rect(11, 25, 10, 1, WHITE)            # 桌面高光
    return i


def ic_injection():
    """注射器：水平针筒 + 红液 + 活塞（attack·伤害）。"""
    i = Icon()
    i.rect_o(4, 12, 14, 6, WHITE)           # 筒身
    i.rect(5, 13, 12, 4, (210, 225, 245, 255))
    i.rect(6, 14, 8, 2, RED)                # 红液
    i.rect_o(18, 13, 5, 2, STEEL)           # 针头
    i.rect(23, 13, 2, 2, STEEL_D)           # 针尖
    i.rect_o(2, 13, 3, 5, GOLD)             # 活塞
    i.rect(3, 14, 1, 3, GOLD_D)
    i.rect(6, 11, 3, 1, WHITE)              # 筒高光
    return i


def ic_medal():
    """奖章：圆形金牌 + 绶带（attack·全能小幅）。"""
    i = Icon()
    i.line(10, 24, 14, 16, RED_D, 2)        # 左绶带
    i.line(22, 24, 18, 16, RED_D, 2)        # 右绶带
    i.disc(16, 12, 7, GOLD)                 # 奖章
    i.disc(16, 12, 4, GOLD_D)
    i.rect(15, 9, 2, 6, WHITE)              # 十字纹
    i.rect(12, 11, 8, 2, WHITE)
    i.set(14, 6, GOLD)                      # 顶部亮点
    return i


def ic_glass_cannon():
    """玻璃大炮：透明炮管 + 高光 + 支架（attack·高风险高收益）。"""
    i = Icon()
    i.rect_o(4, 12, 20, 7, BLUE_L)          # 玻璃炮管
    i.rect(5, 13, 18, 5, (200, 225, 250, 255))
    i.rect(7, 14, 12, 2, WHITE)             # 玻璃高光
    i.rect_o(24, 13, 5, 5, RED)             # 炮口
    i.rect(25, 14, 3, 3, GOLD)
    i.rect_o(10, 21, 8, 5, STEEL)           # 支架
    i.rect(11, 22, 6, 3, STEEL_D)
    return i


def ic_bone_dice():
    """骰子：白方 + 5 点（attack·幸运）。"""
    i = Icon()
    i.rect_o(9, 9, 14, 14, WHITE)
    i.rect(10, 10, 12, 12, (225, 230, 240, 255))
    i.rect(13, 13, 2, 2, OUTLINE)           # 5 点
    i.rect(19, 13, 2, 2, OUTLINE)
    i.rect(13, 19, 2, 2, OUTLINE)
    i.rect(19, 19, 2, 2, OUTLINE)
    i.rect(16, 16, 2, 2, OUTLINE)           # 中心点
    i.set(11, 10, WHITE)                    # 高光
    return i


def ic_helmet():
    """头盔：金属盔 + 面甲缝（defense·护甲）。"""
    i = Icon()
    i.disc(16, 14, 9, STEEL)                # 盔体
    i.disc(16, 14, 9, None)
    i.rect(7, 14, 18, 6, STEEL)
    i.rect(8, 15, 16, 5, STEEL_D)           # 面甲
    i.rect(14, 15, 4, 5, DARK)              # 面甲缝
    i.rect(8, 16, 6, 1, DARK)
    i.rect(18, 16, 6, 1, DARK)
    i.set(10, 9, WHITE)                     # 盔顶高光
    i.rect(14, 5, 4, 2, RED)                # 盔缨
    return i


def ic_alien_worm():
    """外星虫：绿虫身 + 复眼（defense·生命回血）。"""
    i = Icon()
    i.disc(14, 20, 5, GREEN)                # 尾段
    i.disc(17, 16, 5, GREEN)
    i.disc(20, 12, 5, GREEN)                # 头段
    i.disc(18, 10, 2, WHITE)                # 眼白
    i.disc(19, 10, 1, OUTLINE)              # 瞳孔
    i.disc(23, 12, 1, WHITE)
    i.set(15, 21, GREEN_D)                  # 背部纹
    i.set(18, 17, GREEN_D)
    i.set(13, 15, GREEN_D)
    return i


def ic_jelly():
    """果冻：粉方块 + 高光（defense·生命）。"""
    i = Icon()
    i.rect_o(9, 10, 14, 13, PINK)
    i.rect(10, 11, 12, 11, (250, 170, 210, 255))
    i.tri([(12, 13), (16, 9), (14, 15)], WHITE)   # 顶部高光
    i.rect(11, 21, 10, 1, PINK)             # 底部内阴影
    i.set(25, 12, WHITE)                    # 侧高光
    i.set(24, 16, WHITE)
    return i


def ic_mushroom():
    """蘑菇：红伞 + 白点 + 白柄（defense·回血）。"""
    i = Icon()
    i.tri([(16, 4), (6, 17), (26, 17)], RED)      # 伞
    i.rect(7, 16, 18, 3, RED_D)             # 伞沿
    i.set(12, 10, WHITE)                    # 伞点
    i.set(18, 8, WHITE)
    i.set(16, 13, WHITE)
    i.rect_o(13, 19, 6, 8, WHITE)           # 柄
    i.rect(14, 20, 4, 7, (210, 215, 225, 255))
    i.rect(13, 25, 6, 2, (180, 185, 195, 255))
    return i


def ic_guardian_shield():
    """护卫盾：蓝盾 + 金边 + 十字（defense·护甲生命）。"""
    i = Icon()
    i.tri([(16, 5), (8, 10), (24, 10)], BLUE)     # 盾顶
    i.rect_o(8, 10, 16, 14, BLUE)           # 盾身
    i.rect(9, 11, 14, 12, (110, 170, 240, 255))
    i.rect(15, 12, 2, 10, WHITE)            # 十字竖
    i.rect(11, 15, 10, 2, WHITE)            # 十字横
    i.rect(8, 21, 16, 3, BLUE_D)            # 盾底
    return i


def ic_sneakers():
    """速跑鞋：侧视运动鞋 + 鞋带（stat·移速）。"""
    i = Icon()
    i.rect_o(4, 16, 22, 6, BLUE)            # 鞋身
    i.rect(5, 17, 20, 5, (120, 180, 245, 255))
    i.rect_o(5, 22, 20, 3, WHITE)           # 鞋底
    i.rect(6, 23, 18, 1, (200, 205, 215, 255))
    i.rect(10, 14, 2, 3, WHITE)             # 鞋带
    i.rect(14, 14, 2, 3, WHITE)
    i.rect(18, 14, 2, 3, WHITE)
    i.set(23, 18, BLUE_D)                   # 鞋头
    i.rect(5, 19, 4, 1, WHITE)              # 高光
    return i


def ic_insanity():
    """疯狂：裂瞳眼（stat·暴击闪避）。"""
    i = Icon()
    i.rect_o(8, 12, 16, 9, WHITE)           # 眼眶
    i.rect(9, 13, 14, 7, (225, 228, 238, 255))
    i.disc(16, 16, 4, RED)                  # 红瞳
    i.disc(16, 16, 2, DARK)                 # 瞳孔
    i.line(10, 13, 14, 17, RED_D, 1)        # 裂痕
    i.line(22, 14, 17, 19, RED_D, 1)
    i.set(12, 10, WHITE)                    # 上睫毛
    i.set(20, 10, WHITE)
    return i


def ic_potato():
    """土豆：棕椭圆 + 斑点 + 芽（stat·全能小幅）。"""
    i = Icon()
    i.disc(16, 17, 9, BROWN)                # 土豆身
    i.disc(16, 17, 9, None)
    i.rect(7, 17, 18, 9, BROWN)
    i.set(12, 15, BROWN_D)                  # 斑点
    i.set(18, 13, BROWN_D)
    i.set(14, 20, BROWN_D)
    i.set(20, 21, BROWN_D)
    i.rect(15, 5, 3, 4, GREEN)              # 芽
    i.rect(16, 8, 1, 2, GREEN_D)
    i.set(10, 12, BROWN_L)                  # 高光
    return i


def ic_adrenaline_shot():
    """肾上腺素注射：针管 + 闪电标记（stat·攻速移速）。"""
    i = Icon()
    i.rect_o(4, 14, 13, 5, WHITE)           # 筒身
    i.rect(5, 15, 11, 3, (210, 225, 245, 255))
    i.rect(6, 15, 7, 3, RED)                # 红液
    i.rect_o(17, 15, 4, 2, STEEL)           # 针头
    i.rect_o(2, 14, 3, 5, GOLD)             # 活塞
    i.tri([(24, 10), (20, 18), (23, 18)], GOLD)   # 闪电
    i.tri([(24, 18), (20, 24), (23, 22)], GOLD)
    i.tri([(22, 15), (25, 12), (25, 15)], WHITE)
    return i


def ic_ball_and_chain():
    """铁球链：铁球 + 链环（stat·伤害护甲）。"""
    i = Icon()
    i.line(6, 9, 14, 17, STEEL, 2)          # 链一段
    i.line(14, 17, 18, 21, STEEL, 2)
    i.disc(22, 23, 6, STEEL)                # 铁球
    i.disc(22, 23, 6, None)
    i.disc(22, 23, 3, STEEL_D)
    i.set(20, 20, WHITE)                    # 球高光
    i.rect(8, 8, 4, 2, STEEL_D)             # 锚点
    return i


def ic_blood_leech():
    """血蛭：红虫 + 吸盘（special·吸血回血）。"""
    i = Icon()
    i.disc(14, 20, 5, RED)                  # 尾
    i.disc(17, 16, 5, RED)
    i.disc(20, 12, 5, RED)                  # 头
    i.disc(19, 11, 2, RED_D)                # 吸盘
    i.disc(19, 11, 1, DARK)
    i.set(13, 21, RED_D)                    # 背部环纹
    i.set(16, 17, RED_D)
    i.set(20, 14, GOLD)                     # 高光
    i.set(23, 10, GOLD)
    return i


def ic_banner():
    """旗帜：杆 + 飘旗（special·范围攻速）。"""
    i = Icon()
    i.rect_o(6, 4, 3, 24, BROWN)            # 旗杆
    i.rect(7, 5, 1, 22, BROWN_D)
    i.rect_o(9, 5, 14, 9, RED)              # 旗面
    i.rect(10, 6, 12, 7, (245, 120, 90, 255))
    i.tri([(23, 8), (27, 10), (23, 12)], RED)     # 旗尾缺口
    i.rect(11, 8, 8, 2, GOLD)               # 旗纹
    i.set(4, 6, GOLD)                       # 杆顶
    return i


def ic_flame_core():
    """烈焰核心：红宝石 + 外焰（special·进化核心）。"""
    i = Icon()
    i.disc(16, 17, 7, RED)                  # 核心球
    i.disc(16, 17, 7, None)
    i.rect(9, 17, 14, 7, RED)
    i.disc(16, 17, 4, GOLD)                 # 内核
    i.disc(16, 17, 2, WHITE)                # 高光
    i.tri([(16, 4), (12, 10), (20, 10)], RED_D)   # 顶焰
    i.tri([(7, 14), (4, 20), (10, 18)], RED_D)    # 左焰
    i.tri([(25, 14), (28, 20), (22, 18)], RED_D)  # 右焰
    i.set(12, 12, GOLD)
    i.set(20, 12, GOLD)
    return i


def ic_mech_core():
    """机械核心：齿轮 + 蓝灰（special·进化核心）。"""
    i = Icon()
    i.disc(16, 16, 8, STEEL)                # 齿轮体
    i.disc(16, 16, 8, None)
    for (dx, dy) in [(0, -1), (1, 0), (0, 1), (-1, 0), (1, -1), (1, 1), (-1, 1), (-1, -1)]:
        i.rect_o(15 + dx * 5, 15 + dy * 5, 3, 3, STEEL)  # 齿
    i.disc(16, 16, 5, DARK)                 # 内孔
    i.disc(16, 16, 5, None)
    i.disc(16, 16, 3, CYAN)                 # 蓝芯
    i.disc(16, 16, 1, WHITE)
    i.set(13, 13, WHITE)                    # 齿高光
    return i


def ic_blade_core():
    """星刃核心：青紫刃星 + 环（special·进化核心）。"""
    i = Icon()
    import math
    for a in range(0, 360, 15):             # 外环
        x = 16 + int(13 * math.cos(math.radians(a)))
        y = 16 + int(13 * math.sin(math.radians(a)))
        i.set(x, y, PURPLE)
    i.tri([(16, 4), (13, 13), (19, 13)], PURPLE)   # 四角星
    i.tri([(16, 28), (13, 19), (19, 19)], PURPLE)
    i.tri([(4, 16), (13, 13), (13, 19)], PURPLE)
    i.tri([(28, 16), (19, 13), (19, 19)], PURPLE)
    i.disc(16, 16, 4, GOLD)                 # 星核
    i.disc(16, 16, 2, WHITE)
    i.set(10, 10, WHITE)
    return i


# ================= 帧表 =================

def build():
    frames = {
        0: ic_coffee,
        1: ic_injection,
        2: ic_medal,
        3: ic_glass_cannon,
        4: ic_bone_dice,
        5: ic_helmet,
        6: ic_alien_worm,
        7: ic_jelly,
        8: ic_mushroom,
        9: ic_guardian_shield,
        10: ic_sneakers,
        11: ic_insanity,
        12: ic_potato,
        13: ic_adrenaline_shot,
        14: ic_ball_and_chain,
        15: ic_blood_leech,
        16: ic_banner,
        17: ic_flame_core,
        18: ic_mech_core,
        19: ic_blade_core,
    }
    sheet = Image.new("RGBA", (SIZE * FRAMES, SIZE), (0, 0, 0, 0))
    for idx in range(FRAMES):
        if idx in frames:
            img = frames[idx]().render()
        else:
            img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        sheet.paste(img, (idx * SIZE, 0))
    sheet.save(OUT)
    print("已生成 %s: %dx%d（%d 帧 × %d×%d）" % (OUT, sheet.width, sheet.height, FRAMES, SIZE, SIZE))


if __name__ == "__main__":
    build()
