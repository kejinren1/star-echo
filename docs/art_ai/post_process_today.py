#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""post_process_today.py — 今日批量后处理：抠底 → 降采样 → spritesheet → 进游戏 assets
产物对齐游戏现有命名：{hero}_{frame}.png(320×64) / {mon}_move.png(192×48) / fx_*.png(64)
立绘原图 → ART/CHARA/ 备份；色板量化用游戏调色板 ART/COLOR_DICT.json
"""
import shutil
import subprocess
import sys
from pathlib import Path

PY = sys.executable
BASE = Path("D:/30DAYS/docs/art_ai/output_abc/today_20260815")
SPRITES = Path("D:/30DAYS/assets/sprites")
CHARA_OUT = Path("D:/30DAYS/ART/CHARA/AI_20260815")
BACKUP = Path("D:/30DAYS/.godot_tmp_backup/ai_20260815")
IMG2SPRITE = "D:/30DAYS/tools/img2sprite.py"
PALETTE = "D:/30DAYS/ART/COLOR_DICT.json"

from PIL import Image  # noqa
import os


def try_unlink(p: Path):
    """临时文件清理：沙箱回收站不可用时走 os.remove 兜底，仍失败则静默保留。"""
    try:
        p.unlink(missing_ok=True)
    except OSError:
        try:
            os.remove(p)
        except OSError:
            pass


def backup_existing(dst):
    """覆盖前把目标现有文件备份到 .godot_tmp_backup（可回退）。"""
    if dst.exists():
        BACKUP.mkdir(parents=True, exist_ok=True)
        b = BACKUP / dst.name
        if not b.exists():
            shutil.copy2(dst, b)
            print(f"  [backup] {dst.name} → .godot_tmp_backup/ai_20260815/")


def run_img2sprite(src, dst, size, palette=True):
    dst.parent.mkdir(parents=True, exist_ok=True)
    cmd = [PY, IMG2SPRITE, "--input", str(src), "--output", str(dst),
           "--size", size, "--bg", "auto", "--bg-tol", "100"]
    if palette:
        cmd += ["--palette", PALETTE]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        print(f"  [FAIL] {src.name}: {r.stderr[:200]}")
        return False
    return True


def make_sheet(frame_path, dst, frame_w, cols):
    """单帧 → 横向 spritesheet（cols 列重复帧，游戏循环用）。"""
    im = Image.open(frame_path)
    w, h = im.size
    sheet = Image.new("RGBA", (frame_w * cols, h), (0, 0, 0, 0))
    for i in range(cols):
        sheet.paste(im, (i * frame_w, 0))
    sheet.save(dst)
    print(f"  sheet: {dst.name} ({sheet.size[0]}x{h})")


def main():
    CHARA_OUT.mkdir(parents=True, exist_ok=True)

    # 1. 立绘 → ART/CHARA/AI_20260815/
    portraits = sorted((BASE / "portraits").glob("*.png"))
    print(f"[1] 立绘 {len(portraits)} 张")
    for p in portraits:
        shutil.copy2(p, CHARA_OUT / p.name)
        print(f"  {p.name} → ART/CHARA/AI_20260815/")

    # 2. 局内帧 → 抠底 64px → 4 帧 sheet（对齐 elin_idle.png 320×64）
    print("[2] 主角局内帧")
    heroes = ["elin", "noah", "lain", "siia"]
    frames = ["idle", "attack", "skill", "hit"]
    for hid in heroes:
        hdir = BASE / "heroes" / hid
        if not hdir.exists():
            continue
        for f in frames:
            cands = sorted(hdir.glob(f"{hid}_{f}_*.png"))
            if not cands:
                print(f"  ! 缺 {hid}_{f}")
                continue
            src = cands[0]
            clean = hdir / f"{hid}_{f}_clean64.png"
            if run_img2sprite(src, clean, "64x64"):
                sheet = SPRITES / "characters" / f"{hid}_{f}.png"
                backup_existing(sheet)
                make_sheet(clean, sheet, 64, 4)
                try_unlink(clean)

    # 3. 怪物 → 48px → 4 帧 sheet（对齐 skeleton_move.png 192×48）
    print("[3] 怪物")
    mdir = BASE / "monsters"
    for src in sorted(mdir.glob("*.png")) if mdir.exists() else []:
        stem = src.stem
        if stem.startswith("mon_"):
            stem = stem[4:]
        mid = stem.split("_today")[0]
        clean = mdir / f"{mid}_clean48.png"
        if run_img2sprite(src, clean, "48x48"):
            sheet = SPRITES / "enemies" / f"{mid}_move.png"
            backup_existing(sheet)
            make_sheet(clean, sheet, 48, 4)
            try_unlink(clean)

    # 4. 特效 → 按游戏 FX_CONFIG（vfx_player.gd）规格生成横排 sheet
    #    {eid: (frame_size_px, frame_count)}：单帧复制 N 份（静态帧动画，先保证显示）
    print("[4] 特效")
    FX_SHEET = {
        "fx_hit": (32, 4), "fx_crit": (32, 6), "fx_death": (32, 4),
        "fx_levelup": (32, 6), "fx_pickup": (16, 4), "fx_fireball": (64, 6),
        "fx_meteor": (128, 6), "fx_shield": (64, 6),
    }
    edir = BASE / "effects"
    for src in sorted(edir.glob("*.png")) if edir.exists() else []:
        eid = src.stem.split("_today")[0]
        cfg = FX_SHEET.get(eid)
        if not cfg:
            print(f"  ! 无配置跳过: {src.name}")
            continue
        fsize, fcount = cfg
        clean = edir / f"{eid}_clean.png"
        if not run_img2sprite(src, clean, f"{fsize}x{fsize}"):
            continue
        im = Image.open(clean)
        w, h = im.size
        sheet = Image.new("RGBA", (w * fcount, h), (0, 0, 0, 0))
        for i in range(fcount):
            sheet.paste(im, (i * w, 0))
        dst = SPRITES / "effects" / f"{eid}.png"
        backup_existing(dst)
        sheet.save(dst)
        try_unlink(clean)
        print(f"  {eid} → {sheet.size[0]}x{sheet.size[1]} ({fcount}×{fsize}px)")

    # 5. 头像：从立绘裁头部（顶部 18%-45% 区域）→ 128px
    print("[5] 头像（立绘裁切）")
    for p in portraits:
        hid = p.stem.replace("portrait_", "").split("_today")[0]
        im = Image.open(p)
        w, h = im.size
        crop = im.crop((int(w * 0.22), int(h * 0.14), int(w * 0.78), int(h * 0.50)))
        tmp = p.parent / f"{hid}_bust_tmp.png"
        crop.save(tmp)
        dst = SPRITES / "characters" / f"{hid}_portrait.png"
        backup_existing(dst)
        run_img2sprite(tmp, dst, "128x128")
        try_unlink(tmp)

    print("=== 后处理完成 ===")


if __name__ == "__main__":
    main()
