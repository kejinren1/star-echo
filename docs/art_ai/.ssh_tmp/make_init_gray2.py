#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""make_init_gray2.py — 底图 v2：768 原图抠白 → 纵向拉伸(头身比修正) → 灰底竖版化
拉伸系数：人类角色 1.3（像素 4 头身→底图 5.5 头身）；狼 1.2；物品 1.0
"""
import os
from collections import deque
from PIL import Image
import numpy as np

SRC_DIR = r"D:/30DAYS/docs/art_ai/output_comfy/style_test"
OUT_DIR = r"D:/30DAYS/docs/art_ai/.ssh_tmp/init_gray2"
os.makedirs(OUT_DIR, exist_ok=True)

CHARS = {
    "elin": ("v12_elin_mage_4", 1.3), "noah": ("v11_noah_youth", 1.3), "lain": ("v8_lain_vC", 1.3),
    "siia": ("girl_siia_youth_3", 1.3),
    "b01": ("v8_boss_01_demon", 1.3), "b02": ("v8_boss_02_mage", 1.3), "b03": ("boss_03_gang_leader_v4", 1.3),
    "b04": ("v10_boss_04_light_knight", 1.3), "b05": ("v16_wolf_1", 1.2), "b06": ("boss_06_minotaur_v4", 1.3),
    "b07": ("v7_boss_07_goddess", 1.3), "b08": ("boss_08_ominous_mirror_v4", 1.0),
}

def floodfill_bg(arr, tol=64):
    h, w = arr.shape[:2]
    mask = np.zeros((h, w), dtype=bool)
    edge = arr[0, 0].astype(int)
    q = deque()
    for x in range(w):
        q.append((0, x)); q.append((h - 1, x))
    for y in range(h):
        q.append((y, 0)); q.append((y, w - 1))
    while q:
        y, x = q.popleft()
        if mask[y, x]:
            continue
        if np.abs(arr[y, x].astype(int) - edge).max() > tol:
            continue
        mask[y, x] = True
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            ny, nx = y + dy, x + dx
            if 0 <= ny < h and 0 <= nx < w and not mask[ny, nx]:
                q.append((ny, nx))
    dil = mask.copy()
    for _ in range(2):
        nxt = dil.copy()
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                if dy == 0 and dx == 0:
                    continue
                sh = np.roll(np.roll(dil, dy, 0), dx, 1)
                if dy > 0: sh[dy:] = False
                if dy < 0: sh[:dy] = False
                if dx > 0: sh[:, dx:] = False
                if dx < 0: sh[:, :dx] = False
                nxt |= sh
        dil = nxt
    return dil

for key, (fname, stretch) in CHARS.items():
    p = os.path.join(SRC_DIR, f"{fname}.png")
    if not os.path.exists(p):
        print(f"[缺] {key}")
        continue
    arr = np.array(Image.open(p).convert("RGB"))
    mask = floodfill_bg(arr)
    arr[mask] = (128, 128, 128)
    im = Image.fromarray(arr)
    w, h = im.size
    # 纵向拉伸 → 高度修正为 h*stretch
    im2 = im.resize((w, int(h * stretch)), Image.LANCZOS)
    # 灰底竖版画布 768x1536，人物贴中间
    canvas = np.zeros((1536, 768, 3), dtype=np.uint8) + 128
    h2 = im2.size[1]
    cy = (1536 - h2) // 2
    canvas[cy:cy + h2, 0:768] = np.array(im2)
    Image.fromarray(canvas).resize((1024, 1536), Image.LANCZOS).save(
        os.path.join(OUT_DIR, f"{key}_init_gray2.png"))
    print(f"[OK] {key} 拉伸x{stretch} {h}->{h2}", flush=True)
print("ALL_DONE", flush=True)
