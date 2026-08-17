#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_v8_all.py — v8：全都要版（体态组合全保留 + 版本补齐 + 立绘配套）
用户 08-15 拍板：不选组合、全都要、多跑不费事。
A. 局内模型：3 女 × 3 体态 × 补 3 seed（每组合 5 版）+ 莱恩补 3 seed（8 版）
B. 立绘：3 女 × 3 体态 × 2 seed + 莱恩 2 seed（Neta 白底全身）
输出：output_abc/v8_all_20260815/{models,portraits}
"""
import json
import sys
from pathlib import Path

sys.path.insert(0, r"D:/30DAYS/docs/art_ai")
from comfy_client import ComfyClient  # noqa

HOST = "http://61.157.218.59:31071"
TOKEN = "$2b$12$hJjmO84moQQWigWYsGH10O/yHLqLwBgIPZmwa10BSbTVoGQ6fi4ze"
CKPT_PIX = "aziibpixelmix_v10.safetensors"
CKPT_HD = "Neta Art XL 二次元角色 （更新V2）_V2.0.safetensors"
OUT = Path("D:/30DAYS/docs/art_ai/output_abc/v8_all_20260815")
OUT.mkdir(parents=True, exist_ok=True)

POS_3Q = ("three-quarter view, body angled toward the right side, face turned toward viewer, "
          "both eyes clearly visible, slight side profile, three-quarter angle")
BODY_OK = ("complete body, all limbs visible, both arms and both legs intact, standing upright, "
           "perfect anatomy, full body visible head to toe")
BG_PIX = (", crisp pixel art sprite, bold clean palette, clean silhouette, "
          "pure white background, solid flat uniform background, no gradient, no ground shadow, "
          "no rim light, no vignette, no floor, no decorations")

BODY_TYPES = {
    "mature": "mature adult woman, tall elegant figure, voluptuous adult proportions, large bust, long legs",
    "youth": "young woman, slim youthful figure, medium height, gentle curves",
    "loli": "small petite girl, tiny childlike proportions, short stature, cute little girl",
}

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
NEG_NO_LOLI_BAN = NEG_COMMON.replace(", child, loli,", ",")

STYLE_HD = ("masterpiece, best quality, highly detailed, sharp focus, clean lineart, "
            "vibrant but clean anime illustration, bright saturated colors, cheerful expression, "
            "crisp cel shading, full body, standing pose, "
            "pure white background, solid flat uniform background, no gradient, no shadow, "
            "no floor, no ground, no decorations, no background elements")
NEG_HD = ("blurry, low quality, deformed hands, extra fingers, bad anatomy, watermark, text, "
          "multiple characters, ugly, background details, gradient background, shadow, floor, ground, "
          "dark background, decorations, landscape, scenery, modern clothes, jeans, t-shirt, hoodie, "
          "military uniform, modern machinery, gun, rifle, half body, bust, close-up, crop, pure side view, "
          "missing limbs, amputee, extra limbs, disfigured")


def build_pix_wf(text, seed):
    wf = {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT_PIX}},
        "2": {"class_type": "CLIPTextEncode", "inputs": {"text": text, "clip": ["1", 1]}},
        "3": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG_COMMON, "clip": ["1", 1]}},
        "7": {"class_type": "EmptyLatentImage", "inputs": {"width": 768, "height": 768, "batch_size": 1}},
        "8": {"class_type": "KSampler", "inputs": {"seed": seed, "steps": 28, "cfg": 6.5,
             "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 1.0,
             "model": ["1", 0], "positive": ["2", 0], "negative": ["3", 0], "latent_image": ["7", 0]}},
        "9": {"class_type": "VAEDecode", "inputs": {"samples": ["8", 0], "vae": ["1", 2]}},
        "10": {"class_type": "SaveImage", "inputs": {"filename_prefix": "v8model", "images": ["9", 0]}},
    }
    return wf


def build_hd_wf(text, seed, w=768, h=1024):
    wf = {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT_HD}},
        "2": {"class_type": "CLIPTextEncode", "inputs": {"text": text, "clip": ["1", 1]}},
        "3": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG_HD, "clip": ["1", 1]}},
        "7": {"class_type": "EmptyLatentImage", "inputs": {"width": w, "height": h, "batch_size": 1}},
        "8": {"class_type": "KSampler", "inputs": {"seed": seed, "steps": 28, "cfg": 7.0,
             "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 1.0,
             "model": ["1", 0], "positive": ["2", 0], "negative": ["3", 0], "latent_image": ["7", 0]}},
        "9": {"class_type": "VAEDecode", "inputs": {"samples": ["8", 0], "vae": ["1", 2]}},
        "10": {"class_type": "SaveImage", "inputs": {"filename_prefix": "v8portrait", "images": ["9", 0]}},
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

    tasks = []  # (name, subdir, wf)
    seed = 2026082300
    # A. 局内模型补齐：9 组合 × seed3-5（避让 v7 的 s1/s2）
    for i, hid in enumerate(["elin", "noah", "siia"]):
        desc = HEROES[hid]
        for bi, (bkey, bword) in enumerate(BODY_TYPES.items()):
            text = f"{bword}, {desc}, {POS_3Q}, {BODY_OK}" + BG_PIX
            for k in range(3, 6):
                tasks.append((f"{hid}_{bkey}_s{k}", "models", build_pix_wf(text, seed + i * 100 + bi * 10 + k * 5)))
    # 莱恩补 3 seed（s6-s8）
    text_lain = f"{HEROES['lain']}, {POS_3Q}, {BODY_OK}" + BG_PIX
    for k in range(6, 9):
        tasks.append((f"lain_s{k}", "models", build_pix_wf(text_lain, seed + 900 + k * 17)))
    # B. 立绘：9 组合 × 2 seed + 莱恩 2 seed
    for i, hid in enumerate(["elin", "noah", "siia"]):
        desc = HEROES[hid]
        for bi, (bkey, bword) in enumerate(BODY_TYPES.items()):
            text = f"{STYLE_HD}, {bword}, {desc}"
            for k in range(1, 3):
                tasks.append((f"{hid}_{bkey}_p{k}", "portraits", build_hd_wf(text, seed + 2000 + i * 100 + bi * 10 + k * 5)))
    text_lain_p = f"{STYLE_HD}, {HEROES['lain']}"
    for k in range(1, 3):
        tasks.append((f"lain_p{k}", "portraits", build_hd_wf(text_lain_p, seed + 2900 + k * 17)))

    print(f"[plan] 共 {len(tasks)} 张（局内补 27+3 + 立绘 18+2）")
    ok, fail = 0, []
    for i, (name, sub, wf) in enumerate(tasks):
        if name in done:
            print(f"[{i+1}/{len(tasks)}] {name} 已存在，跳过")
            ok += 1
            continue
        try:
            gen(client, name, wf, OUT / sub)
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
