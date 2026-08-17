#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_v5_threeq.py — v5：3/4 侧身局内模型 + 高清立绘（固定要素词）
用户 08-15 把关：① 朝向=3/4 侧（两只眼可见），完全侧视不行；
② 立绘换高清模型（counterfeitxl 明亮风），人物要素提示词固定保持一致性；像素轨画像素时再切回。
输出：output_abc/v5_threeq_20260815/{models,portraits,group}
"""
import json
import sys
from pathlib import Path

sys.path.insert(0, r"D:/30DAYS/docs/art_ai")
from comfy_client import ComfyClient  # noqa

HOST = "http://61.157.218.59:31071"
TOKEN = "$2b$12$hJjmO84moQQWigWYsGH10O/yHLqLwBgIPZmwa10BSbTVoGQ6fi4ze"
CKPT_PIX = "aziibpixelmix_v10.safetensors"
CKPT_HD = "counterfeitxl_v10.safetensors"
OUT = Path("D:/30DAYS/docs/art_ai/output_abc/v5_threeq_20260815")
OUT.mkdir(parents=True, exist_ok=True)

# ===== 局内模型：3/4 侧身（两只眼可见）=====
POS_3Q = ("three-quarter view, body angled toward the right side, face turned toward viewer, "
          "both eyes clearly visible, slight side profile, three-quarter angle")
BG_PIX = (", crisp pixel art sprite, bold clean palette, clean silhouette, full body visible head to toe, "
          "pure white background, solid flat uniform background, no gradient, no ground shadow, "
          "no rim light, no vignette, no floor, no decorations")
# 注意：NEG 不再禁 front facing（3/4 需要轻微正面成分，v4 禁词把姿势推成纯侧）
NEG_PIX = ("blurry, low quality, stiff pose, half body, portrait, close-up, crop, ugly, deformed, "
           "child, loli, flat chest, effects, particles, magic, aura, background decoration, "
           "dark background, colored background, red background, gradient background, "
           "ground shadow, vignette, floor, multiple characters, text, watermark, modern clothes, "
           "jeans, t-shirt, hoodie, military uniform, modern machinery, gun, rifle, "
           "pure side view, complete profile, one eye visible")

# ===== 人物要素（固定，立绘/像素共用；造型 = v2 的 vA 经典版）=====
HEROES = {
    "elin": "young woman, long crimson red hair, red eyes, elegant classic fantasy mage, long black robe with crimson and gold flame embroidery, holding a floating glowing flame orb, dignified fire mage",
    "noah": "young woman, short silver blue hair, blue eyes, magitech tinkerer of a fantasy workshop, ornate dark navy coat with brass rune gears and copper clockwork ornaments, small floating cogwork fairy companion, holding a glowing rune device, fantasy engineer",
    "lain": "young man, short white hair, sharp blue eyes, knight errant of a fantasy kingdom, silver and white full armor with blue cape, rune-carved longsword resting on shoulder, heroic knight",
    "siia": "young woman, long soft golden hair, gentle green eyes, gentle cleric of a fantasy church, white and gold priestess robe with light ornaments, radiant healing staff in hand, warm healer",
}

# ===== 立绘风格（固定）：明亮活力动画风 =====
STYLE_HD = ("masterpiece, best quality, highly detailed, sharp focus, clean lineart, "
            "vibrant bright cheerful anime illustration, warm sunlight, rich saturated colors, "
            "sparkling eyes, lively energetic atmosphere, colorful soft glow, cel shading")
NEG_HD = ("blurry, low quality, deformed hands, extra fingers, bad anatomy, watermark, text, "
          "multiple characters, ugly, background details, gradient background, shadow, "
          "dark background, decorations, modern clothes, jeans, t-shirt, hoodie, military uniform, "
          "modern machinery, gun, rifle, pure side view, complete profile")


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
        "10": {"class_type": "SaveImage", "inputs": {"filename_prefix": "v5model", "images": ["9", 0]}},
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
        "10": {"class_type": "SaveImage", "inputs": {"filename_prefix": "v5portrait", "images": ["9", 0]}},
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
    seed = 2026082000
    # 1) 局内模型 3/4：4 角色 × 2 seed
    for i, (hid, desc) in enumerate(HEROES.items()):
        text = f"{desc}, {POS_3Q}" + BG_PIX
        for k in range(2):
            tasks.append((f"model_{hid}_s{k+1}", "models", build_pix_wf(text, seed + i * 10 + k * 5)))
    # 2) 立绘高清轨：4 角色（固定要素 + 固定风格）
    for i, (hid, desc) in enumerate(HEROES.items()):
        text = f"{STYLE_HD}, {desc}, full body character concept art, standing pose, three-quarter view, pure white background, solid flat uniform background, no gradient, no shadow, no decorations"
        tasks.append((f"portrait_{hid}", "portraits", build_hd_wf(text, seed + 300 + i * 13)))
    # 3) 团体立绘：4 人并排（1024×1024）
    group = (f"{STYLE_HD}, group illustration of four fantasy adventurers standing together in a row, "
             f"from left to right: {HEROES['elin']}; {HEROES['noah']}; {HEROES['lain']}; {HEROES['siia']}, "
             f"each character full body, pure white background, solid flat uniform background, no gradient, no shadow, no decorations")
    tasks.append(("group_4heroes", "group", build_hd_wf(group, seed + 700, 1024, 1024)))

    print(f"[plan] 共 {len(tasks)} 张（8 局内 3/4 + 4 立绘 + 1 团体）")
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
