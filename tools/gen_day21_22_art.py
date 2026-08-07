#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Day 21-22 美术资产批量生成（阶段 D 首段 · W3 职责落地）。

对应 docs/SOLUTION_PLAN.md 第 4 轮 T1/T2/T3/T4：
  T1 敌人/Boss 精灵换皮 10 张：slime/skeleton 48px 4+4（覆盖旧文件）、
     elite 64px 4+4（新）、invoker/predator 128px 4+4（新）
  T2 角色 walk 6 帧 192×32：elin/noah/lain 重绘（覆盖）+ siia 新建
  T3 攻击/技能 strip 4 帧 128×32 ×4 角色（attack 实绘；skill 复用 pose + 特效色）
  T4 brawler/ranger/mage 头像 64×64 + 阵营图标 5×32px + 背景概念图 4×320×180

规范（ART_STYLE v2）：1px 深色描边；每张 sheet 全图唯一色数 ≤216；
透明键 = 左上角 (0,0) 保持全透明，图标/角色关键位置不用透明色。

用法：python tools/gen_day21_22_art.py
"""
import math
import os
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPR = os.path.join(ROOT, "assets", "sprites")

OUTLINE = (13, 13, 18, 255)      # 深蓝黑 1px 描边（同现有精灵 #0d0d12）
WHITE = (255, 255, 255, 255)
BLACK = (10, 10, 14, 255)

# ============ 基础绘制工具（任意尺寸 Canvas） ============

class Canvas:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.px = [[None] * w for _ in range(h)]

    def set(self, x, y, c):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.px[y][x] = c

    def rect(self, x, y, w, h, c):
        for j in range(y, y + h):
            for i in range(x, x + w):
                self.set(i, j, c)

    def rect_o(self, x, y, w, h, c, o=OUTLINE):
        self.rect(x - 1, y - 1, w + 2, h + 2, o)
        self.rect(x, y, w, h, c)

    def ellipse(self, cx, cy, rx, ry, c, o=OUTLINE):
        """实心椭圆 + 描边（含 dx*dx/(rx+1)^2 外扩环）。"""
        for dy in range(-ry - 1, ry + 2):
            for dx in range(-rx - 1, rx + 2):
                xx, yy = cx + dx, cy + dy
                if 0 <= xx < self.w and 0 <= yy < self.h:
                    if (dx * dx) / ((rx + 1) * (rx + 1)) + (dy * dy) / ((ry + 1) * (ry + 1)) <= 1.0:
                        if (dx * dx) / (rx * rx) + (dy * dy) / (ry * ry) <= 1.0:
                            self.set(xx, yy, c)
                        elif self.px[yy][xx] is None:
                            self.set(xx, yy, o)

    def disc(self, cx, cy, r, c, o=OUTLINE):
        self.ellipse(cx, cy, r, r, c, o)

    def line(self, x0, y0, x1, y1, c, thick=1):
        dx, dy = abs(x1 - x0), abs(y1 - y0)
        sx, sy = (1 if x0 < x1 else -1), (1 if y0 < y1 else -1)
        err = dx - dy
        while True:
            for t in range(thick):
                self.set(x0, y0 + t, c)
            if x0 == x1 and y0 == y1:
                break
            e2 = 2 * err
            if e2 > -dy:
                err -= dy
                x0 += sx
            if e2 < dx:
                err += dx
                y0 += sy

    def tri(self, pts, c, o=OUTLINE):
        xs = [p[0] for p in pts]
        ys = [p[1] for p in pts]
        minx, maxx = min(xs), max(xs)
        miny, maxy = min(ys), max(ys)
        for y in range(miny, maxy + 1):
            for x in range(minx, maxx + 1):
                if self._in_tri(x, y, pts):
                    self.set(x, y, c)
        cx, cy = sum(xs) / 3, sum(ys) / 3
        pts_o = []
        for (x, y) in pts:
            dx, dy = x - cx, y - cy
            ln = math.hypot(dx, dy) or 1.0
            pts_o.append((int(x + dx / ln), int(y + dy / ln)))
        for y in range(miny - 1, maxy + 2):
            for x in range(minx - 1, maxx + 2):
                if 0 <= x < self.w and 0 <= y < self.h and self._in_tri(x, y, pts_o) and self.px[y][x] is None:
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

    def render(self, scale=1):
        img = Image.new("RGBA", (self.w * scale, self.h * scale), (0, 0, 0, 0))
        for y in range(self.h):
            for x in range(self.w):
                c = self.px[y][x]
                if c is not None:
                    for j in range(scale):
                        for i in range(scale):
                            img.putpixel((x * scale + i, y * scale + j), c)
        return img


def sheet(frames, size, out_path):
    """frames: list[Canvas] → 横向 sheet 保存；返回 (sheet, colors)。"""
    fw, fh = size
    s = Image.new("RGBA", (fw * len(frames), fh), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        s.paste(f.render(), (i * fw, 0))
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    s.putpixel((0, 0), (0, 0, 0, 0))  # 透明键协议：左上角恒透明（满幅概念图也强制）
    s.save(out_path)
    colors = len({p for p in s.getdata() if p[3] > 0})
    assert colors <= 216, "%s 色数超限: %d" % (out_path, colors)
    print("  %s: %dx%d 色数=%d ✅" % (os.path.relpath(out_path, ROOT), s.width, s.height, colors))
    return s, colors


# ============ 色板 ============

SLIME = {"main": (107, 200, 107), "dark": (70, 150, 70), "light": (140, 220, 140),
         "eye": (240, 250, 240), "pupil": (20, 30, 25)}
SKEL = {"bone": (204, 204, 204), "bone_d": (122, 122, 143), "eye": (255, 7, 58),
        "blade": (150, 160, 180), "blade_d": (95, 105, 130)}
ELITE_ACC = {"plate": (74, 32, 32), "trim": (255, 60, 60), "gold": (230, 190, 90)}
INVOKER = {"robe": (106, 74, 154), "robe_d": (58, 42, 90), "robe_l": (138, 90, 192),
           "orb": (224, 192, 255), "staff": (86, 62, 40), "hood": (70, 50, 110)}
PREDATOR = {"fur": (122, 42, 42), "fur_d": (76, 26, 30), "fur_l": (160, 70, 60),
            "horn": (216, 216, 216), "eye": (255, 200, 60)}


def char_palette(hero):
    """角色配色（对齐各 idle 提取色板 + 概念色）。"""
    return {
        "elin": {"hair": (96, 40, 40), "skin": (238, 196, 160), "out": (150, 60, 48),
                 "out_d": (100, 36, 32), "acc": (255, 214, 90)},
        "noah": {"hair": (48, 54, 74), "skin": (238, 196, 160), "out": (92, 100, 116),
                 "out_d": (40, 46, 60), "acc": (127, 212, 245)},
        "lain": {"hair": (62, 42, 34), "skin": (238, 196, 160), "out": (96, 82, 76),
                 "out_d": (52, 38, 34), "acc": (110, 200, 110)},
        "siia": {"hair": (232, 226, 240), "skin": (238, 196, 160), "out": (196, 186, 214),
                 "out_d": (138, 128, 162), "acc": (150, 200, 255)},
    }[hero]


# ============ T1 敌人 ============

def slime_frame(phase, dying=False, t=0):
    """48px 史莱姆：phase 0-3 走（压/弹/压/弹）；death t=0-3 摊平溶解。"""
    c = Canvas(48, 48)
    cx, gy = 24, 36
    if dying:
        # 摊平：高度递减 + 溅滴
        h = [20, 13, 8, 4][t]
        w = [16, 18, 16, 12][t]
        c.ellipse(cx, gy - h // 2, w, h, SLIME["main"])
        c.ellipse(cx - 6, gy - h // 2 - 3, 3, 2, SLIME["light"])
        if t == 0:
            c.ellipse(cx, gy - 14, 9, 7, SLIME["main"])
            c.ellipse(cx - 8, gy - 10, 4, 3, SLIME["dark"])
        elif t == 1:
            c.disc(cx + 10, gy - 12, 3, SLIME["light"])
            c.disc(cx - 11, gy - 9, 2, SLIME["main"])
        elif t == 2:
            c.disc(cx + 12, gy - 8, 2, SLIME["dark"])
            c.disc(cx - 12, gy - 6, 2, SLIME["light"])
        if t < 3:
            c.ellipse(cx, gy, 3, 2, SLIME["dark"])  # 残留渍
        return c
    # 走：squash/stretch
    squash = phase % 2
    ry = 14 - 2 * squash
    rx = 15 + 2 * squash
    by = gy - ry + (1 if squash else 0)
    c.ellipse(cx, by, rx, ry, SLIME["main"])
    c.ellipse(cx - rx // 3, by - 2, rx // 3, ry // 3, SLIME["light"])
    c.ellipse(cx + rx // 4, by + ry // 2, rx // 3, 4, SLIME["dark"])  # 底部阴影
    # 眼睛（跟随相位左右微移）
    ex = cx + (1 if phase >= 2 else -1)
    for dx in (-4, 3):
        c.disc(ex + dx, by - 6, 2, SLIME["eye"])
        c.set(ex + dx, by - 5, SLIME["pupil"])
    # 顶部小气泡（相位 1/3）
    if phase in (1, 3):
        c.disc(cx + 9, by - ry - 2, 2, SLIME["light"])
    return c


def skeleton_frame(phase, dying=False, t=0, elite=False, boss=False):
    """48/64px 骷髅兵；elite=True 加红甲；boss 用 128 单独实现。"""
    size = 64 if elite else 48
    c = Canvas(size, size)
    cx, gy = size // 2, size - 10
    u = size / 48.0  # 缩放系数
    sk = dict(SKEL)
    if elite:
        sk.update(ELITE_ACC)  # 精英在骷髅基础上换红甲 accent
    bone = sk["bone"]
    bone_d = sk["bone_d"]
    if dying:
        # 散架：t=0 完整 → t=3 倒地骨堆
        c.rect(cx - 1, gy - 22, 3, 14, bone)          # 腿柱
        c.ellipse(cx, gy - 28, 8, 7, bone)            # 头
        c.ellipse(cx, gy - 18, 5, 4, bone_d)          # 胸
        c.line(cx + 5, gy - 20, cx + 11, gy - 8, bone, 2)  # 手骨
        if t >= 1:
            c.px = [[None] * size for _ in range(size)]
            c.ellipse(cx - 2, gy - 6, 7, 3, bone_d)   # 骨盆散落
            c.ellipse(cx + 3, gy - 3, 5, 2, bone)
        if t >= 2:
            c.ellipse(cx - 8, gy - 4, 4, 2, bone)
            c.ellipse(cx + 8, gy - 5, 4, 2, bone_d)
        if t >= 3:
            c.ellipse(cx, gy - 2, 6, 2, bone)
        if elite:
            c.rect(cx - 4, gy - 24, 8, 3, sk["plate"])
        return c
    # 行走：腿相位
    leg_phase = [0, -1, -2, -1][phase] if not elite else [0, -1, -3, -1][phase]
    bob = int(abs(leg_phase) * 0.4)
    by = gy - bob
    # 腿
    for lx in (cx - 3, cx + 3):
        c.rect(lx - 1, by - 8, 3, 8, bone)
        c.set(lx, by - 8, bone_d)
    # 骨盆
    c.rect(cx - 4, by - 10, 8, 3, bone)
    # 肋骨胸
    for r in range(3):
        c.rect(cx - 3, by - 15 + r * 2, 6, 1, bone)
        c.rect(cx - 1, by - 15 + r * 2, 2, 1, bone_d)
    # 肩
    c.rect(cx - 5, by - 16, 10, 2, bone_d)
    # 头骨
    c.ellipse(cx, by - 23, 6, 6, bone)
    c.set(cx - 2, by - 23, BLACK)   # 左眼窝
    c.set(cx + 2, by - 23, BLACK)
    c.set(cx, by - 20, bone_d)      # 鼻
    if elite:
        # 红甲：肩甲 + 头饰 + 眼
        c.rect(cx - 6, by - 18, 12, 3, sk["plate"])
        c.rect(cx - 6, by - 17, 2, 2, sk["trim"])
        c.rect(cx + 4, by - 17, 2, 2, sk["trim"])
        c.tri([(cx, by - 29), (cx - 2, by - 25), (cx + 2, by - 25)], sk["trim"])
        c.set(cx - 2, by - 23, sk["trim"])
        c.set(cx + 2, by - 23, sk["trim"])
    # 持刀臂（相位摆动）
    arm_s = 1 if phase % 2 == 0 else -1
    c.line(cx + 5, by - 15, cx + 9 + arm_s, by - 7, bone, 2)
    # 骨刀（灰刃对角）
    bx0, by0 = cx + 9 + arm_s, by - 7
    c.line(bx0, by0, bx0 + 4 * arm_s + 4, by0 - 8, sk.get("blade", (150, 160, 180)), 2)
    c.set(bx0 + 4 * arm_s + 4, by0 - 8, sk.get("blade_d", (95, 105, 130)))
    return c


def invoker_frame(phase, dying=False, t=0):
    """128px 法袍召唤者：飘浮 + 袍摆摇曳 + 法杖辉光。"""
    c = Canvas(128, 128)
    cx, gy = 64, 108
    sway = (phase - 1) * 3 if phase > 1 else (phase * 3 - 3)
    bob = [0, -2, -3, -1][phase]
    robe, robe_d, robe_l = INVOKER["robe"], INVOKER["robe_d"], INVOKER["robe_l"]
    if dying:
        # 法袍塌落 + 法杖倒地 + 辉光消散
        h = [76, 48, 26, 10][t]
        c.tri([(cx, gy - h), (cx - 24, gy), (cx + 24, gy)], robe_d)
        c.tri([(cx, gy - h + 6), (cx - 14, gy), (cx + 14, gy)], robe)
        c.ellipse(cx, gy - h - 10, 12, 10, INVOKER["hood"])
        if t >= 1:
            c.line(cx - 26, gy - 20, cx - 44, gy - 2, INVOKER["staff"], 3)
        if t < 3:
            c.disc(cx + 30, gy - 30 - 8 * t, 6 - t, INVOKER["orb"])
        else:
            c.ellipse(cx, gy - 2, 16, 4, (60, 44, 94, 255))
        return c
    # 光环（脚底）
    c.ellipse(cx, gy + 2, 18, 4, (80, 60, 120, 255))
    # 袍身（A 形，底部摇曳）
    base_w = 26 + sway
    c.tri([(cx, gy - 72 + bob), (cx - base_w, gy), (cx + base_w, gy)], robe_d)
    c.tri([(cx, gy - 62 + bob), (cx - base_w + 6, gy), (cx + base_w - 6, gy)], robe)
    c.tri([(cx - 10, gy - 40 + bob), (cx - base_w + 8, gy), (cx - 2, gy - 14)], robe_l)
    # 袖臂（持杖）
    c.ellipse(cx + 20, gy - 52 + bob, 9, 12, robe)
    c.ellipse(cx + 24, gy - 56 + bob, 7, 6, robe_d)
    # 法杖
    c.line(cx + 24, gy - 96 + bob, cx + 30, gy - 30, INVOKER["staff"], 4)
    c.set(cx + 22, gy - 80 + bob, INVOKER["staff"])
    # 杖顶辉光（相位脉动）
    pr = 8 + phase % 2
    c.disc(cx + 24, gy - 104 + bob, pr, INVOKER["orb"])
    c.disc(cx + 24, gy - 104 + bob, pr - 3, (250, 240, 255, 255))
    # 兜帽 + 面容
    c.ellipse(cx, gy - 78 + bob, 15, 12, INVOKER["hood"])
    c.ellipse(cx, gy - 80 + bob, 12, 9, (84, 62, 130, 255))
    c.set(cx - 4, gy - 80 + bob, (220, 120, 190, 255))   # 眼
    c.set(cx + 4, gy - 80 + bob, (220, 120, 190, 255))
    return c


def predator_frame(phase, dying=False, t=0):
    """128px 四足掠食者：四肢交替小跑 + 尾摆 + 红眼。"""
    c = Canvas(128, 128)
    cx, gy = 64, 100
    bob = [0, -3, -2, -3][phase]
    if dying:
        # 侧倒
        lean = t * 10
        body = [(cx - lean, gy - 30 + lean), (cx + 30 - lean, gy - 26 + lean),
                (cx + 24 - lean, gy - 6 + lean), (cx - 24 - lean, gy - 10 + lean)]
        c.tri(body, PREDATOR["fur"])
        c.ellipse(cx - lean - 4, gy - 36 + lean, 9, 8, PREDATOR["fur_d"])
        c.line(cx - 8 - lean, gy - 36 + lean, cx - 26 - lean, gy - 30 + lean, PREDATOR["horn"], 3)
        if t >= 2:
            c.px = [[None] * 128 for _ in range(128)]
            c.ellipse(cx, gy - 6, 18, 4, PREDATOR["fur_d"])
            c.ellipse(cx - 16, gy - 8, 10, 4, PREDATOR["fur"])
        return c
    # 四腿（前 F / 后 H 交替相位）
    legs = [0, 1, 2, 3]  # LF RF LH RH
    ly = [0, -3, -3, 0][phase]  # 简化对角步态
    for i, (lx, f) in enumerate([(cx - 18, True), (cx - 6, True), (cx + 6, False), (cx + 18, False)]):
        lift = ly if (i % 2 == 0) == (phase < 2) else -ly
        c.rect(lx - 2, gy - 12 + bob + lift * 2, 5, 12 - lift, PREDATOR["fur_d"])
    # 躯干
    c.ellipse(cx, gy - 34 + bob, 32, 16, PREDATOR["fur"])
    c.ellipse(cx + 8, gy - 40 + bob, 18, 10, PREDATOR["fur_l"])
    # 尾（摆动）
    tx = 34 + (phase - 1) * 2
    c.line(cx + 30, gy - 34 + bob, cx + tx + 8, gy - 24 + bob, PREDATOR["fur"], 5)
    c.tri([(cx + tx + 8, gy - 26 + bob), (cx + tx + 16, gy - 20 + bob), (cx + tx + 8, gy - 18 + bob)], PREDATOR["fur_d"])
    # 头
    c.ellipse(cx - 34, gy - 42 + bob, 13, 10, PREDATOR["fur_d"])
    c.ellipse(cx - 36, gy - 44 + bob, 9, 6, PREDATOR["fur_l"])
    # 角 + 眼
    c.line(cx - 42, gy - 48 + bob, cx - 50, gy - 58 + bob, PREDATOR["horn"], 3)
    c.line(cx - 34, gy - 50 + bob, cx - 40, gy - 62 + bob, PREDATOR["horn"], 3)
    c.set(cx - 39, gy - 43 + bob, PREDATOR["eye"])
    return c


def build_enemies():
    print("[T1] 敌人/Boss 精灵 10 张")
    e_dir = os.path.join(SPR, "enemies")
    # slime 48px 4+4
    sheet([slime_frame(p) for p in range(4)], (48, 48), os.path.join(e_dir, "slime_move.png"))
    sheet([slime_frame(0, True, t) for t in range(4)], (48, 48), os.path.join(e_dir, "slime_death.png"))
    # skeleton 48px 4+4
    sheet([skeleton_frame(p) for p in range(4)], (48, 48), os.path.join(e_dir, "skeleton_move.png"))
    sheet([skeleton_frame(0, True, t) for t in range(4)], (48, 48), os.path.join(e_dir, "skeleton_death.png"))
    # elite 64px 4+4
    sheet([skeleton_frame(p, elite=True) for p in range(4)], (64, 64), os.path.join(e_dir, "elite_move.png"))
    sheet([skeleton_frame(0, True, t, elite=True) for t in range(4)], (64, 64), os.path.join(e_dir, "elite_death.png"))
    # invoker 128px 4+4
    sheet([invoker_frame(p) for p in range(4)], (128, 128), os.path.join(e_dir, "invoker_move.png"))
    sheet([invoker_frame(0, True, t) for t in range(4)], (128, 128), os.path.join(e_dir, "invoker_death.png"))
    # predator 128px 4+4
    sheet([predator_frame(p) for p in range(4)], (128, 128), os.path.join(e_dir, "predator_move.png"))
    sheet([predator_frame(0, True, t) for t in range(4)], (128, 128), os.path.join(e_dir, "predator_death.png"))


# ============ T2/T3 角色 ============

def char_body(c, pal, phase, pose=0):
    """32px 角色身体绘制。pose: 0=走 1=攻击 2=技能。"""
    cx, gy = 16, 29
    skin, hair, out, out_d, acc = pal["skin"], pal["hair"], pal["out"], pal["out_d"], pal["acc"]
    leg_off = [0, -1, -2, -1, 0, -1][phase % 6]
    bob = abs(leg_off) // 2
    by = gy - bob
    # 腿（交替抬腿）
    for i, lx in enumerate((cx - 3, cx + 3)):
        lift = leg_off if i == phase % 2 else -leg_off
        c.rect(lx - 1, by - 6 - lift, 3, 7 + lift, out_d if i == 0 else out)
    # 靴
    c.rect(cx - 4, by - 2 - leg_off, 4, 3, (40, 34, 44, 255))
    c.rect(cx + 1, by - 2 + leg_off, 4, 3, (40, 34, 44, 255))
    # 躯干
    if pose == 1:  # 攻击：前倾
        c.tri([(cx, by - 14), (cx - 5, by - 4), (cx + 6, by - 4)], out)
        c.rect(cx - 1, by - 13, 2, 8, out_d)
    elif pose == 2:  # 技能：抬手挺立
        c.rect(cx - 5, by - 15, 10, 11, out)
        c.rect(cx - 3, by - 13, 6, 7, out_d)
    else:
        c.rect(cx - 5, by - 15, 10, 11, out)
        c.rect(cx - 3, by - 13, 6, 7, out_d)
    # 腰带（accent）
    c.rect(cx - 5, by - 7, 10, 2, acc)
    c.rect(cx - 1, by - 6, 2, 2, (240, 240, 255, 255))
    # 头
    hx, hy = cx, by - 22
    c.ellipse(hx, hy, 5, 5, skin)
    # 发
    if pal is not None and hair:
        c.ellipse(hx, hy - 2, 5, 4, hair)
        c.rect(hx - 5, hy - 2, 2, 4, hair)   # 侧发
        c.rect(hx + 3, hy - 2, 2, 4, hair)
        c.rect(hx - 3, hy - 5, 6, 2, hair)
    # 眼
    c.set(hx - 2, hy, (30, 26, 34, 255))
    c.set(hx + 2, hy, (30, 26, 34, 255))
    return (hx, hy)


def build_character_sheets():
    print("[T2/T3] 角色 walk/attack/skill 12 张")
    c_dir = os.path.join(SPR, "characters")
    # walk：6 帧（leg_off 序列 0,-1,-2,-1,0,-1）
    for hero in ("elin", "noah", "lain", "siia"):
        pal = char_palette(hero)
        frames = []
        for p in range(6):
            c = Canvas(32, 32)
            char_body(c, pal, p)
            frames.append(c)
        sheet(frames, (32, 32), os.path.join(c_dir, "%s_walk.png" % hero))
    # attack：4 帧（回旋 → 前挥 + 弹幕/刃光 → 收势 ×2）
    attack_style = {
        "elin":  {"c1": (232, 93, 58), "c2": (255, 214, 90)},
        "noah": {"c1": (127, 212, 245), "c2": (150, 160, 180)},
        "lain": {"c1": (120, 200, 120), "c2": (230, 190, 90)},
        "siia": {"c1": (150, 200, 255), "c2": (240, 244, 255)},
    }
    skill_style = {
        "elin":  "fireball", "noah": "deploy", "lain": "blade", "siia": "shield",
    }
    for hero in ("elin", "noah", "lain", "siia"):
        pal = char_palette(hero)
        a_frames = []
        for p in range(4):
            c = Canvas(32, 32)
            cx, gy = 16, 29
            char_body(c, pal, p, pose=1 if p > 0 else 0)
            col = attack_style[hero]
            if p == 0:      # 回旋蓄力
                c.line(cx + 5, gy - 20, cx + 11, gy - 14, (150, 150, 170, 255), 2)
                c.disc(cx + 12, gy - 15, 2, col["c1"])
            elif p == 1:    # 前挥 + 弹幕
                c.line(cx + 5, gy - 20, cx + 12, gy - 12, (150, 150, 170, 255), 2)
                c.disc(cx + 15, gy - 13, 3, col["c1"])
                c.disc(cx + 19, gy - 12, 2, col["c2"])
            elif p == 2:    # 弹幕飞行
                c.disc(cx + 17, gy - 13, 3, col["c1"])
                c.disc(cx + 21, gy - 12, 2, col["c2"])
            else:           # 收势
                c.line(cx + 5, gy - 20, cx + 9, gy - 14, (150, 150, 170, 255), 2)
                c.set(cx + 12, gy - 12, col["c2"])
            a_frames.append(c)
        sheet(a_frames, (32, 32), os.path.join(c_dir, "%s_attack.png" % hero))
        # skill：4 帧（手势 + 特效渐进，各角色专属）
        s_frames = []
        kind = skill_style[hero]
        for p in range(4):
            c = Canvas(32, 32)
            cx, gy = 16, 29
            char_body(c, pal, p, pose=2)
            if kind == "fireball":
                r = 2 + p
                c.disc(cx + 2, gy - 28 - p, r, (232, 93, 58))
                if p >= 2:
                    c.disc(cx + 2, gy - 28 - p, r - 1, (255, 214, 90))
                    c.tri([(cx + 2, gy - 28 - p + r + 2), (cx - 1, gy - 28 - p + r + 5), (cx + 5, gy - 28 - p + r + 5)], (190, 60, 32))
            elif kind == "deploy":
                c.rect_o(cx - 3, gy - 6, 7, 5, (150, 160, 180))
                c.disc(cx + 6, gy - 14 - p // 2, 2, (127, 212, 245))
                if p >= 2:
                    c.set(cx + 8, gy - 16, (240, 244, 255))
            elif kind == "blade":
                for a in range(0, 360, 60):
                    ang = math.radians(a + p * 15)
                    x = cx + int(10 * math.cos(ang))
                    y = gy - 12 + int(10 * math.sin(ang))
                    c.set(x, y, (120, 200, 120))
                    c.set(cx + int(12 * math.cos(ang)), gy - 12 + int(12 * math.sin(ang)), (230, 190, 90) if p >= 2 else (200, 220, 200))
            else:  # shield
                c.disc(cx, gy - 10, 8 + p, None)  # 外圈
                for a in range(0, 360, 45):
                    ang = math.radians(a)
                    x = cx + int((8 + p) * math.cos(ang))
                    y = gy - 10 + int((8 + p) * math.sin(ang))
                    c.set(x, y, (150, 200, 255))
                c.rect(cx - 1, gy - 14 - p, 2, 8, (240, 244, 255))
            s_frames.append(c)
        sheet(s_frames, (32, 32), os.path.join(c_dir, "%s_skill.png" % hero))


# ============ T4 头像 / 阵营 / 背景 ============

def build_portraits():
    print("[T4] 遗留头像 3 张")
    p_dir = os.path.join(SPR, "characters")
    specs = {
        "brawler": {"skin": (222, 168, 130), "band": (232, 120, 60), "coat": (120, 74, 52), "acc": (220, 190, 120)},
        "ranger":  {"skin": (212, 170, 140), "band": (90, 160, 90), "coat": (66, 96, 62), "acc": (150, 190, 130)},
        "mage":    {"skin": (224, 178, 150), "band": (140, 100, 190), "coat": (82, 58, 120), "acc": (210, 180, 255)},
    }
    for name, pal in specs.items():
        c = Canvas(64, 64)
        # 肩
        c.ellipse(32, 52, 26, 14, pal["coat"])
        c.rect(6, 44, 52, 14, pal["coat"])
        c.rect(6, 44, 52, 3, (30, 26, 34, 255))  # 领
        c.rect(24, 44, 16, 4, pal["acc"])        # 领饰
        # 颈
        c.rect(28, 38, 8, 6, pal["skin"])
        # 头
        c.ellipse(32, 26, 14, 15, pal["skin"])
        # 发
        c.ellipse(32, 20, 14, 11, pal["band"])
        c.rect(18, 18, 4, 12, pal["band"])
        c.rect(42, 18, 4, 12, pal["band"])
        c.rect(20, 14, 24, 5, pal["band"])
        # 眼 + 眉
        c.set(26, 28, (30, 26, 34, 255))
        c.set(38, 28, (30, 26, 34, 255))
        c.rect(24, 24, 4, 1, (60, 50, 55, 255))
        c.rect(36, 24, 4, 1, (60, 50, 55, 255))
        # 嘴
        c.set(30, 34, (150, 90, 70, 255))
        c.set(34, 34, (150, 90, 70, 255))
        sheet([c], (64, 64), os.path.join(p_dir, "%s_portrait.png" % name))


def build_factions():
    print("[T4] 阵营图标 5 张")
    f_dir = os.path.join(SPR, "factions")
    os.makedirs(f_dir, exist_ok=True)
    def star(c, cx, cy, r, col):
        for a in range(0, 360, 36):
            ang = math.radians(a)
            c.tri([(cx + int(r * 0.35 * math.cos(ang)), cy + int(r * 0.35 * math.sin(ang))),
                   (cx + int(r * math.cos(ang + 0.15)), cy + int(r * math.sin(ang + 0.15))),
                   (cx + int(r * math.cos(ang - 0.15)), cy + int(r * math.sin(ang - 0.15)))], col)
    icons = {
        "echo_alliance": lambda c: (star(c, 16, 16, 12, (255, 215, 90)), c.disc(16, 16, 5, (240, 244, 255))),
        "star_cult": lambda c: (c.ellipse(19, 14, 8, 8, (178, 102, 224)),
                                c.ellipse(15, 14, 8, 8, (40, 30, 60, 255)),
                                c.disc(15, 15, 2, (240, 244, 255))),
        "abyss_council": lambda c: (c.ellipse(16, 14, 9, 7, (60, 120, 120)),
                                    c.tri([(9, 20), (13, 28), (17, 20)], (30, 70, 74)),
                                    c.tri([(15, 22), (18, 30), (22, 22)], (90, 160, 150))),
        "mech_empire": lambda c: (c.disc(16, 16, 9, (150, 160, 180)),
                                  c.disc(16, 16, 4, (127, 212, 245)),
                                  c.tri([(16, 3), (13, 10), (19, 10)], (90, 100, 120)),
                                  c.tri([(16, 29), (13, 22), (19, 22)], (90, 100, 120))),
        "free_mercs": lambda c: (c.line(7, 7, 25, 25, (232, 120, 60), 3),
                                 c.line(25, 7, 7, 25, (200, 160, 60), 3),
                                 c.rect(14, 15, 4, 2, (240, 244, 255))),
    }
    for name, draw in icons.items():
        c = Canvas(32, 32)
        draw(c)
        sheet([c], (32, 32), os.path.join(f_dir, "%s.png" % name))


def build_backgrounds():
    print("[T4] 背景概念图 4 张（320×180）")
    b_dir = os.path.join(SPR, "backgrounds")
    os.makedirs(b_dir, exist_ok=True)

    def bg_wulan():
        c = Canvas(320, 180)
        # 墙
        c.rect(0, 0, 320, 140, (74, 58, 44))
        c.rect(0, 140, 320, 40, (52, 40, 30))
        for i in range(0, 320, 40):  # 木板缝
            c.line(i, 0, i, 140, (58, 44, 34), 1)
        # 窗（暖光）
        c.rect_o(40, 30, 60, 48, (120, 96, 60))
        c.rect(42, 32, 56, 44, (255, 214, 120))
        c.rect(70, 32, 2, 44, (90, 70, 44))
        c.rect(42, 52, 56, 2, (90, 70, 44))
        # 工作台
        c.rect_o(150, 100, 140, 26, (96, 74, 50))
        c.rect(152, 102, 136, 22, (120, 92, 60))
        # 台面物件：齿轮 + 扳手
        c.disc(180, 110, 6, (150, 160, 180))
        c.disc(180, 110, 2, (100, 110, 130))
        c.line(210, 104, 224, 116, (150, 160, 180), 2)
        # 地面油灯
        c.rect_o(276, 128, 24, 30, (90, 70, 50))
        c.disc(288, 124, 8, (255, 190, 90))
        c.disc(288, 124, 4, (255, 240, 200))
        # 齿轮装饰
        for (gx, gy, gr) in ((300, 40, 8), (20, 100, 6), (260, 20, 5)):
            c.disc(gx, gy, gr, (110, 120, 140))
            c.disc(gx, gy, gr - 2, (150, 160, 180))
        return c

    def bg_forest():
        c = Canvas(320, 180)
        c.rect(0, 0, 320, 180, (30, 26, 46))          # 夜空
        c.rect(0, 120, 320, 60, (24, 30, 34))          # 腐地
        for i in range(0, 320, 26):                    # 腐化树
            x = i + 8
            c.rect(x, 60, 8, 64, (48, 34, 58))
            c.rect(x - 4, 52, 16, 10, (48, 34, 58))
            for b in range(4):
                c.line(x + 4, 56 + b * 14, x - 12 + b * 8, 30 + b * 12, (70, 50, 84), 3)
            c.set(x + 4, 66, (178, 60, 120, 255))      # 腐眼
            c.set(x + 4, 92, (178, 60, 120, 255))
        # 月光 + 飘点
        c.disc(280, 30, 14, (150, 200, 255))
        c.disc(280, 30, 10, (220, 240, 255))
        for (mx, my) in ((60, 40), (140, 80), (230, 60), (110, 100), (190, 120)):
            c.set(mx, my, (178, 120, 220, 255))
        return c

    def bg_lava():
        c = Canvas(320, 180)
        c.rect(0, 0, 320, 180, (26, 20, 30))           # 洞壁
        c.rect(0, 120, 320, 60, (40, 26, 30))          # 岩层
        for x in range(0, 320, 40):                    # 岩柱
            c.rect(x, 40, 14, 90, (52, 38, 44))
        # 熔岩池
        for (lx, lw) in ((30, 80), (150, 100), (260, 50)):
            c.ellipse(lx + lw // 2, 150, lw // 2, 16, (120, 40, 30))
            c.ellipse(lx + lw // 2, 148, lw // 2 - 8, 10, (232, 93, 58))
            c.ellipse(lx + lw // 2 - 6, 146, 10, 5, (255, 190, 90))
        # 火星
        for (mx, my) in ((60, 110), (180, 100), (280, 116), (120, 96), (240, 108)):
            c.set(mx, my, (255, 214, 120, 255))
        return c

    def bg_void():
        c = Canvas(320, 180)
        c.rect(0, 0, 320, 180, (20, 18, 40))
        for i in range(6):                             # 走廊渐变
            y0 = 40 + i * 18
            w0 = 30 + i * 20
            c.rect(160 - w0 // 2, y0, w0, 16, (40 + i * 10, 34 + i * 8, 70 + i * 12))
        # 传送门
        c.ellipse(160, 60, 34, 44, (90, 60, 140))
        c.ellipse(160, 60, 26, 36, (150, 100, 200))
        c.ellipse(160, 60, 16, 24, (230, 200, 255))
        c.disc(160, 60, 8, (250, 240, 255))
        # 两侧能量柱
        for sx in (60, 260):
            c.rect(sx, 40, 8, 90, (70, 50, 110))
            c.rect(sx + 2, 44, 4, 82, (150, 100, 200))
        # 星点
        for (mx, my) in ((90, 30), (220, 24), (120, 110), (200, 100), (70, 130)):
            c.set(mx, my, (220, 220, 255, 255))
        return c

    for name, fn in (("wulan_workshop", bg_wulan), ("corrupted_forest", bg_forest),
                     ("lava_mine", bg_lava), ("void_corridor", bg_void)):
        sheet([fn()], (320, 180), os.path.join(b_dir, "%s.png" % name))


# ============ 主入口 ============

def main():
    build_enemies()
    build_character_sheets()
    build_portraits()
    build_factions()
    build_backgrounds()
    print("全部生成完成 ✅")


if __name__ == "__main__":
    main()
