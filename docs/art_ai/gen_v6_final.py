#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_v6_final.py — v6：服装具体化 + 白底立绘 + 全身像 + 团体图
用户 08-15 把关：① 立绘必须白/灰底（可抠图），不要廉价背景；② 立绘必须全身像；
③ 服装种类与造型固定进提示词（每角色具体服装清单）；④ 局内 3/4 方向已 OK。
立绘轨 = Neta Art XL（白底稳定）+ 活力干净词；像素轨 = aziibpixelmix 3/4。
输出：output_abc/v6_final_20260815/
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
OUT = Path("D:/30DAYS/docs/art_ai/output_abc/v6_final_20260815")
OUT.mkdir(parents=True, exist_ok=True)

# ===== 局内模型 3/4 =====
POS_3Q = ("three-quarter view, body angled toward the right side, face turned toward viewer, "
          "both eyes clearly visible, slight side profile, three-quarter angle")
BG_PIX = (", crisp pixel art sprite, bold clean palette, clean silhouette, full body visible head to toe, "
          "pure white background, solid flat uniform background, no gradient, no ground shadow, "
          "no rim light, no vignette, no floor, no decorations")
NEG_PIX = ("blurry, low quality, stiff pose, half body, portrait, close-up, crop, ugly, deformed, "
           "child, loli, flat chest, effects, particles, magic, aura, background decoration, "
           "dark background, colored background, red background, gradient background, "
           "ground shadow, vignette, floor, multiple characters, text, watermark, modern clothes, "
           "jeans, t-shirt, hoodie, military uniform, modern machinery, gun, rifle, "
           "pure side view, complete profile, one eye visible")

# ===== 人物要素 v2（服装具体化固定）=====
# 结构：发型瞳色 + 服装清单（种类/造型具体）+ 手持物 + 气质
HEROES = {
    "elin": (
        "young woman, long crimson red hair with side braid, red eyes, "
        "long black mage robe with crimson flame embroidery and gold trim, wide billowing sleeves, "
        "black shoulder cape with gold clasp, red ribbon sash tied at waist, long flowing robe skirt, "
        "holding a floating glowing flame orb in one hand, dignified fire mage, confident expression"),
    "noah": (
        "young woman, short silver blue bob hair with gear hairpin, blue eyes, "
        "dark navy blue magitech long coat with brass gear buttons and copper clockwork shoulder ornaments, "
        "rune-engraved mechanical gauntlet on left arm, brown leather tool belt with small pouches and vials, "
        "knee-length coat with silver trim, holding a glowing blue rune device in one hand, "
        "fantasy magitech engineer, focused expression"),
    "lain": (
        "young man, short white hair, sharp blue eyes, "
        "full silver-white plate armor with round shoulder pauldrons and engraved chest plate with sapphire gem, "
        "blue cape draped over one shoulder, armored gauntlets and greaves, "
        "rune-carved longsword resting on shoulder, heroic knight, calm expression"),
    "siia": (
        "young woman, long soft golden hair, gentle green eyes, "
        "white and gold priestess robe with gold trim and cross emblem, white hood and shoulder mantle, "
        "layered robe skirt with light golden ornaments, "
        "holding a radiant golden healing staff with crystal top, warm cleric, gentle smile"),
}

# ===== 立绘轨：白底 + 全身 + 干净活力 =====
STYLE_HD = ("masterpiece, best quality, highly detailed, sharp focus, clean lineart, "
            "vibrant but clean anime illustration, bright saturated colors, cheerful expression, "
            "crisp cel shading, full body, standing pose, "
            "pure white background, solid flat uniform background, no gradient, no shadow, "
            "no floor, no ground, no decorations, no background elements")
NEG_HD = ("blurry, low quality, deformed hands, extra fingers, bad anatomy, watermark, text, "
          "multiple characters, ugly, background details, gradient background, shadow, floor, ground, "
          "dark background, decorations, landscape, scenery, modern clothes, jeans, t-shirt, hoodie, "
          "military uniform, modern machinery, gun, rifle, half body, bust, close-up, crop, pure side view")


def build_pix_wf(text, seed):
    wf = {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT_PIX}},
        "2": {"class_type": "CLIPTextEncode", "inputs": {"text": text, "clip": ["1", 1]}},
        "3": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG_PIX, "clip": ["1", 1]}},
        "7": {"class_type": "EmptyLatentImage", "inputs": {"width": 768, "height": 768, "batch_size": 1}},
        "8": {"class_type": "KSampler", "inputs": {"seed": seed, "steps": 28, "cfg": 6.5,
             "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 1.0,
             "model": ["1", 0], "positive": ["2", 0], "negative": ["3", 0], "latent_image": ["7", 0]}},
        "9": {"class_type": "VAEDecode", "inputs": {"samples": ["8", 0], "vae": ["1", 2]}},
        "10": {"class_type": "SaveImage", "inputs": {"filename_prefix": "v6model", "images": ["9", 0]}},
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
        "10": {"class_type": "SaveImage", "inputs": {"filename_prefix": "v6portrait", "images": ["9", 0]}},
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

    tasks = []
    seed = 2026082100
    # 1) 局内模型 3/4（新服装词）：4 角色 × 2 seed
    for i, (hid, desc) in enumerate(HEROES.items()):
        text = f"{desc}, {POS_3Q}" + BG_PIX
        for k in range(2):
            tasks.append((f"model_{hid}_s{k+1}", "models", build_pix_wf(text, seed + i * 10 + k * 5)))
    # 2) 立绘（Neta 白底全身）：4 角色 × 2 seed（多给一版选）
    for i, (hid, desc) in enumerate(HEROES.items()):
        text = f"{STYLE_HD}, {desc}"
        for k in range(2):
            tasks.append((f"portrait_{hid}_s{k+1}", "portraits", build_hd_wf(text, seed + 400 + i * 10 + k * 5)))
    # 3) 团体立绘：4 人并排全身（Neta 白底 1024²）
    group = (f"{STYLE_HD}, group illustration of four fantasy adventurers standing in a row, "
             f"from left to right: {HEROES['elin']}; {HEROES['noah']}; {HEROES['lain']}; {HEROES['siia']}, "
             f"each character full body, same art style, consistent lineart, pure white background")
    tasks.append(("group_4heroes", "group", build_hd_wf(group, seed + 900, 1024, 1024)))

    print(f"[plan] 共 {len(tasks)} 张（8 局内 + 8 立绘 + 1 团体）")
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
