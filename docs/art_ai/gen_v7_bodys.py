#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_v7_bodys.py — v7：体态轮换版 + 质量优化（肢体完整/全身/纯白）
用户 08-15 把关：① v6 方案成熟，进一步优化：控制缺胳膊少腿、严格执行全身像/纯白背景；
② 每角色多跑 ~5 版本；③ 三女角色（艾琳/诺亚/希亚）轮换「巨乳御姐/少女/萝莉」三体态要素。
产出：女角色 3 体态 × 2 seed = 18 张 + 莱恩 5 seed = 5 张（局内模型 3/4，纯白底）
输出：output_abc/v7_bodys_20260815/models/
"""
import json
import sys
from pathlib import Path

sys.path.insert(0, r"D:/30DAYS/docs/art_ai")
from comfy_client import ComfyClient  # noqa

HOST = "http://61.157.218.59:31071"
TOKEN = "$2b$12$hJjmO84moQQWigWYsGH10O/yHLqLwBgIPZmwa10BSbTVoGQ6fi4ze"
CKPT_PIX = "aziibpixelmix_v10.safetensors"
OUT = Path("D:/30DAYS/docs/art_ai/output_abc/v7_bodys_20260815")
OUT.mkdir(parents=True, exist_ok=True)

POS_3Q = ("three-quarter view, body angled toward the right side, face turned toward viewer, "
          "both eyes clearly visible, slight side profile, three-quarter angle")
# 肢体完整 + 全身 + 纯白 强化
BODY_OK = ("complete body, all limbs visible, both arms and both legs intact, standing upright, "
           "perfect anatomy, full body visible head to toe")
BG_PIX = (", crisp pixel art sprite, bold clean palette, clean silhouette, "
          "pure white background, solid flat uniform background, no gradient, no ground shadow, "
          "no rim light, no vignette, no floor, no decorations")

# 体态要素（三女角色轮换）
BODY_TYPES = {
    "mature": "mature adult woman, tall elegant figure, voluptuous adult proportions, large bust, long legs",
    "youth": "young woman, slim youthful figure, medium height, gentle curves",
    "loli": "small petite girl, tiny childlike proportions, short stature, cute little girl",
}

# 服装（v6 定型，去掉性别/年龄词避免与体态冲突——只留服装+发型+瞳色）
HEROES = {
    "elin": ("long crimson red hair with side braid, red eyes, "
             "long black mage robe with crimson flame embroidery and gold trim, wide billowing sleeves, "
             "black shoulder cape with gold clasp, red ribbon sash tied at waist, long flowing robe skirt, "
             "holding a floating glowing flame orb in one hand, dignified fire mage"),
    "noah": ("short silver blue bob hair with gear hairpin, blue eyes, "
             "dark navy blue magitech long coat with brass gear buttons and copper clockwork shoulder ornaments, "
             "rune-engraved mechanical gauntlet on left arm, brown leather tool belt with small pouches and vials, "
             "knee-length coat with silver trim, holding a glowing blue rune device in one hand, "
             "fantasy magitech engineer"),
    "siia": ("long soft golden hair, gentle green eyes, "
             "white and gold priestess robe with gold trim and cross emblem, white hood and shoulder mantle, "
             "layered robe skirt with light golden ornaments, "
             "holding a radiant golden healing staff with crystal top, warm cleric"),
    "lain": ("young man, short white hair, sharp blue eyes, "
             "full silver-white plate armor with round shoulder pauldrons and engraved chest plate with sapphire gem, "
             "blue cape draped over one shoulder, armored gauntlets and greaves, "
             "rune-carved longsword resting on shoulder, heroic knight"),
}

NEG_COMMON = ("blurry, low quality, stiff pose, half body, portrait, close-up, crop, ugly, deformed, "
              "flat chest, effects, particles, magic, aura, background decoration, "
              "dark background, colored background, red background, gradient background, "
              "ground shadow, vignette, floor, multiple characters, text, watermark, modern clothes, "
              "jeans, t-shirt, hoodie, military uniform, modern machinery, gun, rifle, "
              "pure side view, complete profile, one eye visible, "
              "missing limbs, missing arm, missing leg, amputee, disfigured, broken body, "
              "extra limbs, extra arms, extra legs, no legs, no arms, cropped body")
# 萝莉体态不禁 child/loli（角色即萝莉）；御姐/少女正常禁
NEG_NO_LOLI_BAN = NEG_COMMON.replace(", child, loli,", ",")


def build_wf(text, seed):
    wf = {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT_PIX}},
        "2": {"class_type": "CLIPTextEncode", "inputs": {"text": text, "clip": ["1", 1]}},
        "3": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG_COMMON, "clip": ["1", 1]}},
        "7": {"class_type": "EmptyLatentImage", "inputs": {"width": 768, "height": 768, "batch_size": 1}},
        "8": {"class_type": "KSampler", "inputs": {"seed": seed, "steps": 28, "cfg": 6.5,
             "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 1.0,
             "model": ["1", 0], "positive": ["2", 0], "negative": ["3", 0], "latent_image": ["7", 0]}},
        "9": {"class_type": "VAEDecode", "inputs": {"samples": ["8", 0], "vae": ["1", 2]}},
        "10": {"class_type": "SaveImage", "inputs": {"filename_prefix": "v7model", "images": ["9", 0]}},
    }
    return wf


def gen(client, name, wf, out_dir):
    pid = client.submit(wf)
    entry = client.wait_history(pid, timeout=900)
    return client.download_outputs(entry, out_dir, name)


def main():
    force = "--force" in sys.argv
    client = ComfyClient(HOST, token=TOKEN)
    progress = OUT / "_PROGRESS.json"
    done = set()
    if progress.exists() and not force:
        done = set(json.loads(progress.read_text(encoding="utf-8")))

    tasks = []  # (name, wf)
    seed = 2026082200
    # 女角色 × 3 体态 × 2 seed（轮换要素）
    for i, hid in enumerate(["elin", "noah", "siia"]):
        desc = HEROES[hid]
        for bi, (bkey, bword) in enumerate(BODY_TYPES.items()):
            for k in range(2):
                text = f"{bword}, {desc}, {POS_3Q}, {BODY_OK}" + BG_PIX
                tasks.append((f"{hid}_{bkey}_s{k+1}", build_wf(text, seed + i * 100 + bi * 10 + k * 5)))
    # 莱恩 5 seed
    text_lain = f"{HEROES['lain']}, {POS_3Q}, {BODY_OK}" + BG_PIX
    for k in range(5):
        tasks.append((f"lain_s{k+1}", build_wf(text_lain, seed + 900 + k * 17)))

    print(f"[plan] 共 {len(tasks)} 张（女 3×3 体态×2 seed + 莱恩 5 seed）")
    ok, fail = 0, []
    for i, (name, wf) in enumerate(tasks):
        if name in done:
            print(f"[{i+1}/{len(tasks)}] {name} 已存在，跳过")
            ok += 1
            continue
        try:
            gen(client, name, wf, OUT / "models")
            done.add(name)
            progress.write_text(json.dumps(sorted(done)), encoding="utf-8")
            ok += 1
            print(f"[{i+1}/{len(tasks)}] {name} ✅ ({len(done)}/{len(tasks)})")
        except Exception as e:
            fail.append((name, str(e)[:120]))
            print(f"[{i+1}/{len(tasks)}] {name} ❌ {str(e)[:120]}")
    print(f"=== 完成：成功 {ok}/{len(tasks)}，失败 {len(fail)} ===")
    for n, e in fail:
        print(f"  {n}: {e}")


if __name__ == "__main__":
    main()
