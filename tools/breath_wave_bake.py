#!/usr/bin/env python3
"""
breath_wave_bake.py —— 波浪式呼吸帧烘焙（Star Echo 2026-08-14 沉淀）

背景：用户反馈帧序列呼吸"头/胸/肩三部分同时抖、太扭曲"——正确形态应是
**单波传递**（涟漪式）：波峰从脚底往上平滑移动，某一时刻只有波峰所在部位
明显在动，其余部位接近静止（"像波浪一样"）。

方法（像素画标准波浪做法）：
  1. 输入 96px 透明静态帧
  2. 对每帧 t，对每一行 y 计算垂直位移：
       dy(y,t) = A * sin(2π·t/T − 2π·(y_bottom−y)/λ) * 渐入窗(y)
     - 波长 λ ≈ 全身高 → 同一时刻全身只有一个波峰（"只有一部分在动"）
     - 相位随时间 t 增大 → 波峰自下而上移动（波浪传递）
     - 底部 freeze 行 dy=0（脚底冻结，与 build_anim_sheet --freeze 呼应）
     - 渐入窗：脚底向上 20px 内振幅线性爬升，避免脚部突变
     - λ 大 → 相邻行 dy 差 < 0.2px → 行搬移平滑无台阶
  3. 行搬移重采样（最近邻）：输出 y 行 ← 输入 (y−dy) 行
  4. 输出 12 帧 PNG 到目标目录，再由 build_anim_sheet.py 拼 sheet

用法：
  python tools/breath_wave_bake.py --base assets/sprites/characters/yunni_idle.png --frame 0 --out docs/tmp_breath_wave/ --frames 12 --amp 1.5
参数：
  --base     基准 sheet 路径（取其中一帧作静态图）
  --frame    取第几帧作基准（默认 0）
  --out      输出帧目录
  --frames   帧数（默认 12，与 6fps=2s 循环对齐）
  --amp      振幅 px（默认 1.5，与原烘焙一致）
  --lambda   波长 px（默认 96 ≈ 全身，单波峰）
  --freeze   脚底冻结行数（默认 5）
"""
import argparse
import math
import os
import sys

from PIL import Image


def bake_wave(base: Image.Image, frames: int = 12, amp: float = 1.5,
              wavelength: float = 96.0, freeze: int = 5, head_line: int = -1) -> list:
    """波浪呼吸帧烘焙。head_line>=0 时，该行以上为头部刚性区（整体平移、不逐行拉伸，
    头发/脸保持一体；分界线处 blend 过渡带平滑衔接）。"""
    base = base.convert("RGBA")
    w, h = base.size
    px = base.load()
    ys = [y for y in range(h) for x in range(w) if px[x, y][3] > 0]
    if not ys:
        sys.exit("[ERROR] 基准帧无内容")
    y_bottom = max(ys)
    y_top = min(ys)
    body_h = max(y_bottom - y_top, 1)

    # 头部分界线：默认身体上部 30% 高度（≈颈部），可 --head-line 覆盖
    if head_line < 0:
        head_line = y_top + int(body_h * 0.30)
    blend = 6  # 分界线过渡带宽度（px）

    def wave_dy(y: int, t: int) -> float:
        if y >= y_bottom - freeze:
            return 0.0
        dist = y_bottom - freeze - y
        phase = 2.0 * math.pi * t / frames - 2.0 * math.pi * dist / wavelength
        ramp = min(dist / 20.0, 1.0)
        return amp * ramp * math.sin(phase)

    out_frames = []
    for t in range(frames):
        # 头部刚性区整体位移 = 分界线处的波浪值（保证分界线处连续）
        dy_head = wave_dy(head_line, t)
        img = Image.new("RGBA", base.size, (0, 0, 0, 0))
        op = img.load()
        for y in range(h):
            if y < head_line:
                # 头部刚性区：整体位移，blend 过渡带内从波浪 lerp 到刚体
                if y >= head_line - blend:
                    w_mix = (y - (head_line - blend)) / blend
                    dy = wave_dy(y, t) * w_mix + dy_head * (1.0 - w_mix)
                else:
                    dy = dy_head
            else:
                dy = wave_dy(y, t)
            src_y = int(round(y - dy))
            if 0 <= src_y < h:
                for x in range(w):
                    op[x, y] = px[x, src_y]
        out_frames.append(img)
    return out_frames


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--base", required=True)
    ap.add_argument("--frame", type=int, default=0)
    ap.add_argument("--out", required=True)
    ap.add_argument("--frames", type=int, default=12)
    ap.add_argument("--amp", type=float, default=1.5)
    ap.add_argument("--wavelength", type=float, default=96.0)
    ap.add_argument("--freeze", type=int, default=5)
    ap.add_argument("--head-line", type=int, default=-1,
                    help="头部分界线 y（默认 -1=自动：身体上部 30% 处；该行以上为刚性区，头/发/脸整体平移不拉伸）")
    args = ap.parse_args()

    sheet = Image.open(args.base).convert("RGBA")
    fw = sheet.height
    base = sheet.crop((args.frame * fw, 0, (args.frame + 1) * fw, fw))
    os.makedirs(args.out, exist_ok=True)
    frames = bake_wave(base, args.frames, args.amp, args.wavelength, args.freeze, args.head_line)
    for i, im in enumerate(frames, 1):
        im.save(os.path.join(args.out, "帧%02d.png" % i))
    print("波浪呼吸 %d 帧输出: %s（amp=%.1f λ=%.0f freeze=%d head_line=%d）" % (
        len(frames), args.out, args.amp, args.wavelength, args.freeze, args.head_line))


if __name__ == "__main__":
    main()
