#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_v11_strawberry.py — v11：Strawberry 主模型 + Hires fix（用户 08-15 选定 B 组合，补分辨率）
管线：Strawberry-α（SD1.5）512×768 → LatentUpscale 2x → KSampler denoise 0.4 → 1024×1536
VAE：kl-f8-anime2（SD1.5 专用，勿配 sdxl_vae）
范围：女 3 体态 × 3 角色 + 莱恩 = 10 组合 × 2 seed = 20 张立绘
"""
import json
import sys
from pathlib import Path

sys.path.insert(0, r"D:/30DAYS/docs/art_ai")
from comfy_client import ComfyClient  # noqa

HOST = "http://61.157.218.59:31071"
TOKEN = "$2b$12$hJjmO84moQQWigWYsGH10O/yHLqLwBgIPZmwa10BSbTVoGQ6fi4ze"
CKPT = " Strawberry-α_v1.safetensors"  # 注意前导空格（软链名）
OUT = Path("D:/30DAYS/docs/art_ai/output_abc/v11_strawberry_20260815")
OUT.mkdir(parents=True, exist_ok=True)

BODY_TAGS = {
    "mature": "mature female, adult woman, large breasts, tall, long legs, voluptuous",
    "youth": "young woman, medium breasts, youthful, slim, moderate height",
    "loli": "loli, petite, small breasts, childlike, short, tiny",
}
HEROES = {
    "elin": ("red hair, long hair, side braid, red eyes, "
             "wearing an elegant long black mage robe with crimson flame embroidery and gold trim, "
             "wide billowing sleeves, black shoulder cape with gold clasp, red ribbon sash at waist, "
             "holding a floating glowing flame orb in one hand"),
    "noah": ("silver hair, bob cut, short hair, blue eyes, gear hairpin, "
             "wearing a dark navy blue magitech long coat with brass gear buttons, copper clockwork "
             "shoulder ornaments, rune-engraved mechanical gauntlet on left arm, brown leather tool belt, "
             "holding a glowing blue rune device in one hand"),
    "siia": ("blonde hair, long hair, green eyes, "
             "wearing a white and gold priestess robe with gold trim and cross emblem, white hood "
             "and shoulder mantle, layered robe skirt with light golden ornaments, "
             "holding a radiant golden healing staff with crystal top"),
    "lain": ("young man, white hair, short hair, blue eyes, "
             "wearing full silver-white plate armor with round shoulder pauldrons, engraved chest "
             "plate with sapphire gem, blue cape draped over one shoulder, armored gauntlets and "
             "greaves, rune-carved longsword resting on shoulder"),
}
BG = ("full body, standing, three-quarter view, looking at viewer, "
      "simple background, (plain white background:1.2), white background, monochrome background")
NEG = ("worst quality, low quality, bad anatomy, bad hands, missing fingers, extra digits, watermark, "
       "text, signature, cropped, half body, bust, close-up, multiple views, jpeg artifacts, blurry, "
       "ugly, deformed, background decoration, gradient background, dark background, colored background, "
       "scenery, landscape, ground shadow, floor, modern clothes, jeans, t-shirt, hoodie, "
       "military uniform, gun, rifle, modern machinery, pure side view, missing limbs, amputee, extra limbs")


def build_wf(pos, seed, hires=True):
    wf = {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT}},
        "2": {"class_type": "CLIPTextEncode", "inputs": {"text": pos, "clip": ["1", 1]}},
        "3": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG, "clip": ["1", 1]}},
        "7": {"class_type": "EmptyLatentImage", "inputs": {"width": 512, "height": 768, "batch_size": 1}},
        "8": {"class_type": "KSampler", "inputs": {"seed": seed, "steps": 28, "cfg": 7.0,
             "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 1.0,
             "model": ["1", 0], "positive": ["2", 0], "negative": ["3", 0], "latent_image": ["7", 0]}},
        "11": {"class_type": "VAELoader", "inputs": {"vae_name": "kl-f8-anime2.ckpt"}},
        "9": {"class_type": "VAEDecode", "inputs": {"samples": ["8", 0], "vae": ["11", 0]}},
        "10": {"class_type": "SaveImage", "inputs": {"filename_prefix": "v11", "images": ["9", 0]}},
    }
    if hires:
        wf["12"] = {"class_type": "LatentUpscale", "inputs": {"samples": ["8", 0],
                     "upscale_method": "nearest-exact", "width": 1024, "height": 1536, "crop": "disabled"}}
        wf["13"] = {"class_type": "KSampler", "inputs": {"seed": seed + 1, "steps": 20, "cfg": 6.0,
             "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 0.4,
             "model": ["1", 0], "positive": ["2", 0], "negative": ["3", 0], "latent_image": ["12", 0]}}
        wf["9"] = {"class_type": "VAEDecode", "inputs": {"samples": ["13", 0], "vae": ["11", 0]}}
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
    seed = 2026082600
    # 女 3 体态 × 3 角色 + 莱恩 = 10 组合 × 2 seed
    for i, hid in enumerate(["elin", "noah", "siia"]):
        for bi, (bkey, btag) in enumerate(BODY_TAGS.items()):
            pos = f"masterpiece, best quality, {btag}, 1girl, solo, {HEROES[hid]}, {BG}"
            for k in range(2):
                tasks.append((f"{hid}_{bkey}_p{k+1}", build_wf(pos, seed + i * 100 + bi * 10 + k * 5)))
    pos_lain = f"masterpiece, best quality, young man, 1boy, solo, {HEROES['lain']}, {BG}"
    for k in range(2):
        tasks.append((f"lain_p{k+1}", build_wf(pos_lain, seed + 900 + k * 17)))

    print(f"[plan] 共 {len(tasks)} 张（Strawberry + Hires 2x → 1024×1536）")
    ok, fail = 0, []
    for i, (name, wf) in enumerate(tasks):
        if name in done:
            print(f"[{i+1}/{len(tasks)}] {name} 已存在，跳过")
            ok += 1
            continue
        try:
            gen(client, name, wf, OUT)
            done.add(name)
            try:
                progress.write_text(json.dumps(sorted(done)), encoding="utf-8")
            except PermissionError:
                pass
            ok += 1
            print(f"[{i+1}/{len(tasks)}] {name} ✅ ({len(done)}/{len(tasks)})")
        except Exception as e:
            fail.append((name, str(e)[:150]))
            print(f"[{i+1}/{len(tasks)}] {name} ❌ {str(e)[:150]}")
    print(f"=== 完成：成功 {ok}/{len(tasks)}，失败 {len(fail)} ===")
    for n, e in fail:
        print(f"  {n}: {e}")


if __name__ == "__main__":
    main()
