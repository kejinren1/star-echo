#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_v10_existing.py — v10：现成模型组合对比（用户拍板：不下载，用现成组合跑两轮）
组合 A：Ming_全能人物光影模型_V1_sdxl（SDXL 画质派，832×1216 + hires 2x）
组合 B：Strawberry-α_v1（经典二次元 SD1.5，512×768 + hires 2x）
各跑 艾琳少女 / 诺亚御姐 各 1 张 → 对比画质/要素/背景。
"""
import json
import sys
from pathlib import Path

sys.path.insert(0, r"D:/30DAYS/docs/art_ai")
from comfy_client import ComfyClient  # noqa

HOST = "http://61.157.218.59:31071"
TOKEN = "$2b$12$hJjmO84moQQWigWYsGH10O/yHLqLwBgIPZmwa10BSbTVoGQ6fi4ze"
OUT = Path("D:/30DAYS/docs/art_ai/output_abc/v10_existing_20260815")
OUT.mkdir(parents=True, exist_ok=True)

CKPT_A = "Ming_全能人物光影模型_V1_sdxl_V1.safetensors"
CKPT_B = "Strawberry-α_v1.safetensors"

BODY_TAGS = {
    "youth": "young woman, medium breasts, youthful, slim, moderate height",
    "mature": "mature female, adult woman, large breasts, tall, long legs, voluptuous",
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
}
BG = ("full body, standing, three-quarter view, looking at viewer, "
      "simple background, (plain white background:1.2), white background, monochrome background")
NEG = ("worst quality, low quality, bad anatomy, bad hands, missing fingers, extra digits, watermark, "
       "text, signature, cropped, half body, bust, close-up, multiple views, jpeg artifacts, blurry, "
       "ugly, deformed, background decoration, gradient background, dark background, colored background, "
       "scenery, landscape, ground shadow, floor, modern clothes, jeans, t-shirt, hoodie, "
       "military uniform, gun, rifle, modern machinery, pure side view")


def build_wf(ckpt, pos, seed, w, h, hires_w, hires_h):
    wf = {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": ckpt}},
        "2": {"class_type": "CLIPTextEncode", "inputs": {"text": pos, "clip": ["1", 1]}},
        "3": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG, "clip": ["1", 1]}},
        "7": {"class_type": "EmptyLatentImage", "inputs": {"width": w, "height": h, "batch_size": 1}},
        "8": {"class_type": "KSampler", "inputs": {"seed": seed, "steps": 28, "cfg": 7.0,
             "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 1.0,
             "model": ["1", 0], "positive": ["2", 0], "negative": ["3", 0], "latent_image": ["7", 0]}},
        "11": {"class_type": "VAELoader", "inputs": {"vae_name": "sdxl_vae.safetensors"}},
        "9": {"class_type": "VAEDecode", "inputs": {"samples": ["8", 0], "vae": ["11", 0]}},
        "10": {"class_type": "SaveImage", "inputs": {"filename_prefix": "v10", "images": ["9", 0]}},
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
    seed = 2026082500
    # A: Ming SDXL 832×1216
    for i, (hid, body_key) in enumerate([("elin", "youth"), ("noah", "mature")]):
        tags = HEROES[hid]
        pos = f"masterpiece, best quality, very aesthetic, {BODY_TAGS[body_key]}, 1girl, solo, {tags}, {BG}"
        tasks.append((f"A_{hid}_{body_key}", build_wf(CKPT_A, pos, seed + i * 17, 832, 1216, 1664, 2432)))
    # B: Strawberry SD1.5 512×768
    for i, (hid, body_key) in enumerate([("elin", "youth"), ("noah", "mature")]):
        tags = HEROES[hid]
        pos = f"masterpiece, best quality, {BODY_TAGS[body_key]}, 1girl, solo, {tags}, {BG}"
        tasks.append((f"B_{hid}_{body_key}", build_wf(CKPT_B, pos, seed + 500 + i * 17, 512, 768, 1024, 1536)))

    print(f"[plan] 共 {len(tasks)} 张（A: Ming×2 + B: Strawberry×2）")
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
