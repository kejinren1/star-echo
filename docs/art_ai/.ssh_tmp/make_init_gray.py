#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""make_init_gray.py — 12 角色 768 原图抠白底换灰底 + 竖版化 1024x1536"""
import os
from collections import deque
from PIL import Image
import numpy as np

SRC_DIR = r"D:/30DAYS/docs/art_ai/output_comfy/style_test"
OUT_DIR = r"D:/30DAYS/docs/art_ai/.ssh_tmp/init_gray"
os.makedirs(OUT_DIR, exist_ok=True)

CHARS = {
    "elin": "v12_elin_mage_4", "noah": "v11_noah_youth", "lain": "v8_lain_vC",
    "siia": "girl_siia_youth_3",
    "b01": "v8_boss_01_demon", "b02": "v8_boss_02_mage", "b03": "boss_03_gang_leader_v4",
    "b04": "v10_boss_04_light_knight", "b05": "v16_wolf_1", "b06": "boss_06_minotaur_v4",
    "b07": "v7_boss_07_goddess", "b08": "boss_08_ominous_mirror_v4",
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
    # 膨胀 2px：清掉抠图残留的白/灰描边
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

for key, fname in CHARS.items():
    p = os.path.join(SRC_DIR, f"{fname}.png")
    if not os.path.exists(p):
        print(f"[缺] {key}")
        continue
    arr = np.array(Image.open(p).convert("RGB"))
    mask = floodfill_bg(arr)
    arr2 = arr.copy()
    arr2[mask] = (128, 128, 128)
    h, w = arr2.shape[:2]
    # 竖版画布：高 2h、宽 h，人物贴中间 → resize 1024x1536
    canvas = np.zeros((h * 2, h, 3), dtype=np.uint8) + 128
    cy = (h * 2 - h) // 2
    canvas[cy:cy + h, 0:w] = arr2
    im = Image.fromarray(canvas).resize((1024, 1536), Image.LANCZOS)
    im.save(os.path.join(OUT_DIR, f"{key}_init_gray.png"))
    print(f"[OK] {key} 背景 {mask.mean()*100:.0f}% -> {key}_init_gray.png", flush=True)
print("ALL_DONE", flush=True)
