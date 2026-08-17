#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""run_batch_d2p.py — 正式批量：文字直出像素图（定案方案）
aziibpixelmix + OpenPose v3 待机叉腰骨架 + 768 直出 + 新词 → 64px 规范化
"""
import sys
from pathlib import Path

sys.path.insert(0, r"D:/30DAYS/docs/art_ai")
from comfy_client import ComfyClient, load_library, split_sampler  # noqa

TOKEN = "$2b$12$1kK2TTR/k/1FDPgDYheTDO3BuSlPdE6e.2cwz916eSiTWvJOLkoa."
HOST = "http://127.0.0.1:18001"
CKPT = "aziibpixelmix_v10.safetensors"
CN = "control_v11p_sd15_openpose.pth"
LIB = load_library()
POSE = Path("D:/30DAYS/docs/art_ai/output_abc/pose/待机叉腰骨架_v3_768.png")
OUT = Path("D:/30DAYS/docs/art_ai/output_abc/txt2pixel/批量")

NEG = ("blurry, low quality, stiff pose, symmetrical pose, boring, half body, portrait, "
       "close-up, crop, bust, headshot, ugly, deformed")
PIX = (", crisp pixel art sprite, bold clean color palette, confident idle stance, "
       "one hand on hip, relaxed casual pose, natural weight shift, clean silhouette, "
       "plain light background, full body visible head to toe")

# 12 角色文字描述（特征直写）
ROLES = [
    ("安洁莉娜", "young woman, long wavy white pink hair, purple eyes, white coat over purple dress, elegant mage outfit, gentle smile"),
    ("傀影", "young man, messy black medium hair, red eyes, black hooded cloak, dark assassin coat with red accents, pale skin, sharp gaze"),
    ("棘刺", "young man, short dark blue black hair, blue eyes, black jacket over white shirt, black pants, swordsman, cool expression"),
    ("狮蝎", "young woman, long purple hair, purple eyes, purple cape and dress, dark exotic outfit, mysterious look"),
    ("维什戴尔", "young woman, long red hair, red eyes, red and black military uniform coat, confident smirk, fierce look"),
    ("若叶睦", "teenage girl, green bob hair with small low twintails, green eyes, white collared shirt, red necktie, grey-green jacket, calm expression"),
    ("莱欧斯", "young man, short golden blond hair, blue green eyes, dark red armor with cape, knight, adventurous look"),
    ("陈", "young woman, short blue hair, blue eyes, dark blue military officer coat, long sword at side, sharp confident look"),
    ("赫拉格", "older man, short white hair, red eyes, black and red military greatcoat, battle-worn veteran, stern expression"),
    ("遥", "young woman, long dark hair, amber eyes, dark cloak and scarf, wanderer outfit, calm distant look"),
    ("重岳", "young man, short white grey hair, red eyes, ornate asian armor with tassels, martial artist, focused expression"),
    ("龙舌兰", "young man, short golden blond hair, amber eyes, dark suit and tie, bartender style, relaxed smile"),
]


def main():
    client = ComfyClient(HOST, token=TOKEN)
    sampler, scheduler = split_sampler(LIB["params"]["pixel_direct"]["sampler"])
    pose_name = client.upload_image(POSE)
    OUT.mkdir(parents=True, exist_ok=True)
    results = []
    for i, (name, desc) in enumerate(ROLES):
        try:
            wf = {
                "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT}},
                "2": {"class_type": "CLIPTextEncode", "inputs": {"text": desc + PIX, "clip": ["1", 1]}},
                "3": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG, "clip": ["1", 1]}},
                "4": {"class_type": "ControlNetLoader", "inputs": {"control_net_name": CN}},
                "5": {"class_type": "LoadImage", "inputs": {"image": pose_name}},
                "6": {"class_type": "ControlNetApply", "inputs": {"conditioning": ["2", 0], "control_net": ["4", 0], "image": ["5", 0], "strength": 0.9}},
                "7": {"class_type": "EmptyLatentImage", "inputs": {"width": 768, "height": 768, "batch_size": 1}},
                "8": {"class_type": "KSampler", "inputs": {"seed": 66000 + i * 7, "steps": 28, "cfg": 6.5,
                     "sampler_name": sampler, "scheduler": scheduler, "denoise": 1.0,
                     "model": ["1", 0], "positive": ["6", 0], "negative": ["3", 0], "latent_image": ["7", 0]}},
                "9": {"class_type": "VAEDecode", "inputs": {"samples": ["8", 0], "vae": ["1", 2]}},
                "10": {"class_type": "SaveImage", "inputs": {"filename_prefix": "d2p", "images": ["9", 0]}},
            }
            pid = client.submit(wf)
            entry = client.wait_history(pid, timeout=600)
            saved = client.download_outputs(entry, OUT, name)
            if saved:
                from PIL import Image
                im = Image.open(OUT / saved[0]["file"]).convert("RGB")
                im.resize((64, 64), Image.NEAREST).save(OUT / f"{name}_64px.png")
                im.resize((32, 32), Image.NEAREST).save(OUT / f"{name}_32px.png")
            results.append((name, "OK"))
            print(f"[{i+1}/12] {name} ✅")
        except Exception as e:
            results.append((name, f"FAIL {str(e)[:80]}"))
            print(f"[{i+1}/12] {name} ❌ {str(e)[:80]}")
    (OUT / "_PROGRESS.md").write_text("\n".join(f"{n}: {s}" for n, s in results), encoding="utf-8")
    print("=== 完成 ===")
    for n, s in results:
        print(f"  {n}: {s}")


if __name__ == "__main__":
    main()
