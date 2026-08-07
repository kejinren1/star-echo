#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Day 23 技能特效占位图批量生成（阶段 D 续段 · W3 职责落地）。

对应 docs/SOLUTION_PLAN.md 第 5 轮 T2（用户 2026-08-07 21:1x 拍板：
美术缺口一律用『占位纯色图』实现机制验证，不做华丽 VFX）：

  fx_fireball.png      6 帧 64px   橙红 #FF6A3D 实心圆 半径 8→28 + 描边（火球爆炸）
  fx_turret_deploy.png 4 帧 64px   蓝白 #4FC3F7 竖条 16×48 上下拉长 + 底部横条（炮台部署光柱）
  fx_blade_burst.png   6 帧 64px   银蓝 #AFCBFF 圆环 stroke 4px 半径 10→30 扩散（星刃爆发）
  fx_meteor.png        6 帧 128px  赤金 #FF8C2E 实心圆 + 外扩冲击环（进化陨石坠爆）
  fx_shield.png        6 帧 64px   白蓝 #D0E6FF 半透明圆罩 alpha 120（神圣庇护，P1 接线先出图）

帧序 = 由小到大/由内到外，AnimatedSprite2D 播放天然形成扩散感。
占位图豁免 ART_STYLE 强制项（216 色/色号编码/字典登记，D22 定案），
仅保留 PNG 透明背景（左上角 (0,0) 透明）保证渲染正确。

复用 gen_day21_22_art.py 的 Canvas 原语（纯 PIL 零第三方依赖，幂等）。

用法：python tools/gen_day23_fx_art.py
"""
import os
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FX = os.path.join(ROOT, "assets", "sprites", "effects")

# ============ 基础绘制工具（复制自 gen_day21_22_art.py，+ring 圆环原语） ============

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

    def rect_o(self, x, y, w, h, c, o=(13, 13, 18, 255)):
        self.rect(x - 1, y - 1, w + 2, h + 2, o)
        self.rect(x, y, w, h, c)

    def ellipse(self, cx, cy, rx, ry, c, o=(13, 13, 18, 255)):
        """实心椭圆 + 描边。"""
        for dy in range(-ry - 1, ry + 2):
            for dx in range(-rx - 1, rx + 2):
                xx, yy = cx + dx, cy + dy
                if 0 <= xx < self.w and 0 <= yy < self.h:
                    if (dx * dx) / ((rx + 1) * (rx + 1)) + (dy * dy) / ((ry + 1) * (ry + 1)) <= 1.0:
                        if (dx * dx) / (rx * rx) + (dy * dy) / (ry * ry) <= 1.0:
                            self.set(xx, yy, c)
                        elif self.px[yy][xx] is None:
                            self.set(xx, yy, o)

    def disc(self, cx, cy, r, c, o=(13, 13, 18, 255)):
        self.ellipse(cx, cy, r, r, c, o)

    def ring(self, cx, cy, r, stroke, c, o=(13, 13, 18, 255)):
        """空心圆环：半径 r ± stroke/2 环带填色 + 外缘描边。"""
        for dy in range(-r - stroke - 1, r + stroke + 2):
            for dx in range(-r - stroke - 1, r + stroke + 2):
                xx, yy = cx + dx, cy + dy
                if 0 <= xx < self.w and 0 <= yy < self.h:
                    d = (dx * dx + dy * dy) ** 0.5
                    if abs(d - r) <= stroke * 0.5:
                        # 外缘 1px = 描边色，其余 = 主体色
                        if d > r + stroke * 0.5 - 1.0:
                            self.set(xx, yy, o)
                        else:
                            self.set(xx, yy, c)

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
    s.putpixel((0, 0), (0, 0, 0, 0))  # 透明键协议：左上角恒透明
    s.save(out_path)
    colors = len({p for p in s.getdata() if p[3] > 0})
    print("  %s: %dx%d 不透明色=%d ✅" % (os.path.relpath(out_path, ROOT), s.width, s.height, colors))
    return s, colors


# ============ T2 特效 5 枚 ============

FIREBALL_C = (255, 106, 61, 255)      # #FF6A3D 橙红
FIREBALL_O = (140, 50, 20, 255)       # 深橙红描边
TURRET_C = (79, 195, 247, 255)        # #4FC3F7 蓝白
TURRET_O = (20, 90, 130, 255)
BLADE_C = (175, 203, 255, 255)        # #AFCBFF 银蓝
BLADE_O = (70, 100, 170, 255)
METEOR_C = (255, 140, 46, 255)        # #FF8C2E 赤金
METEOR_O = (150, 60, 10, 255)
METEOR_RING = (255, 210, 142, 255)    # 浅金冲击环
SHIELD_C = (208, 230, 255, 120)       # #D0E6FF 半透明 alpha 120
SHIELD_EDGE = (230, 244, 255, 220)    # 罩沿亮白弧


def fx_fireball_frame(i):
    """橙红实心圆半径 8→28 递增 + 描边（帧 0 最小 → 帧 5 最大 = 扩散）。"""
    c = Canvas(64, 64)
    r = 8 + i * 4
    c.disc(32, 32, r, FIREBALL_C, FIREBALL_O)
    c.disc(32, 32, max(r - 8, 3), (255, 190, 130, 255))  # 高光芯
    return c


def fx_turret_frame(i):
    """蓝白竖条 16×48 上下拉长（帧 0 短 → 帧 3 全高）+ 底部横条。"""
    c = Canvas(64, 64)
    h = 12 + i * 12
    c.rect_o(24, 32 - h // 2, 16, h, TURRET_C, TURRET_O)
    c.rect_o(20, 32 + h // 2 + 4, 24, 6, TURRET_C, TURRET_O)  # 底部横条（落点）
    return c


def fx_blade_frame(i):
    """银蓝圆环 stroke 4px 半径 10→30 扩散。"""
    c = Canvas(64, 64)
    r = 10 + i * 4
    c.ring(32, 32, r, 4, BLADE_C, BLADE_O)
    return c


def fx_meteor_frame(i):
    """赤金实心圆（固定 r16）+ 冲击环半径 20→45 递增。"""
    c = Canvas(128, 128)
    c.disc(64, 64, 16, METEOR_C, METEOR_O)
    c.disc(64, 64, 7, (255, 220, 160, 255))  # 高光芯
    r_ring = 20 + i * 5
    c.ring(64, 64, r_ring, 6, METEOR_RING, METEOR_O)
    return c


def fx_shield_frame(i):
    """白蓝半透明圆罩 alpha 120 半径 18→28 递增 + 罩沿亮弧。"""
    c = Canvas(64, 64)
    r = 18 + i * 2
    # 半透明实心圆（罩体）
    for dy in range(-r, r + 1):
        for dx in range(-r, r + 1):
            xx, yy = 32 + dx, 32 + dy
            if 0 <= xx < 64 and 0 <= yy < 64 and dx * dx + dy * dy <= r * r:
                c.set(xx, yy, SHIELD_C)
    # 罩沿：上半圆亮弧 2px
    for dx in range(-r - 1, r + 2):
        d2 = r * r - dx * dx
        if d2 >= 0:
            yy = 32 - int(d2 ** 0.5)
            c.set(32 + dx, yy, SHIELD_EDGE)
            c.set(32 + dx, yy + 1, SHIELD_EDGE)
    return c


def main():
    jobs = [
        ("fx_fireball.png", [fx_fireball_frame(i) for i in range(6)], (64, 64)),
        ("fx_turret_deploy.png", [fx_turret_frame(i) for i in range(4)], (64, 64)),
        ("fx_blade_burst.png", [fx_blade_frame(i) for i in range(6)], (64, 64)),
        ("fx_meteor.png", [fx_meteor_frame(i) for i in range(6)], (128, 128)),
        ("fx_shield.png", [fx_shield_frame(i) for i in range(6)], (64, 64)),
    ]
    for name, frames, size in jobs:
        sheet(frames, size, os.path.join(FX, name))
    print("Day23 占位特效 5 枚生成完毕 ✅")


if __name__ == "__main__":
    main()
