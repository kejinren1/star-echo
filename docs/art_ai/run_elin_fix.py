#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""run_elin_fix.py — 补跑 elin 4 帧（glob bug 修复：显式指定 _today_ 源文件，不扫目录）
只处理 elin idle/attack/skill/hit：抠底 64px → 4 帧 sheet → 覆盖 assets/sprites/characters/
"""
import shutil
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, r"D:/30DAYS/docs/art_ai")
from PIL import Image  # noqa

PY = sys.executable
SRC_DIR = Path("D:/30DAYS/docs/art_ai/output_abc/today_20260815/heroes/elin")
SPRITES = Path("D:/30DAYS/assets/sprites/characters")
BACKUP = Path("D:/30DAYS/.godot_tmp_backup/ai_20260815")
IMG2SPRITE = "D:/30DAYS/tools/img2sprite.py"
PALETTE = "D:/30DAYS/ART/COLOR_DICT.json"
FRAMES = ["idle", "attack", "skill", "hit"]


def run_img2sprite(src, dst):
    cmd = [PY, IMG2SPRITE, "--input", str(src), "--output", str(dst),
           "--size", "64x64", "--bg", "auto", "--bg-tol", "100", "--palette", PALETTE]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        print(f"  [FAIL] {src.name}: {r.stderr[:200]}")
        return False
    return True


def main():
    BACKUP.mkdir(parents=True, exist_ok=True)
    for f in FRAMES:
        # 显式指定源文件：只匹配 _today_ 原始下载图，绝不碰 *_clean64.png
        cands = sorted(SRC_DIR.glob(f"elin_{f}_today_*.png"))
        if not cands:
            print(f"! 缺源文件 elin_{f}_today_*.png")
            continue
        src = cands[0]
        clean = SRC_DIR / f"elin_{f}_fix_clean64.png"
        if not run_img2sprite(src, clean):
            continue
        im = Image.open(clean)
        w, h = im.size
        sheet = Image.new("RGBA", (w * 4, h), (0, 0, 0, 0))
        for i in range(4):
            sheet.paste(im, (i * w, 0))
        dst = SPRITES / f"elin_{f}.png"
        if dst.exists() and not (BACKUP / dst.name).exists():
            shutil.copy2(dst, BACKUP / dst.name)
            print(f"  [backup] {dst.name} → .godot_tmp_backup/ai_20260815/")
        sheet.save(dst)
        print(f"  elin_{f} → {sheet.size[0]}x{sheet.size[1]} (4×64px) ✅")
    print("=== elin 补跑完成 ===")


if __name__ == "__main__":
    main()
