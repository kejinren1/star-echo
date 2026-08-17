#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""run_action_frames.py — 动作帧小样验证：2 角色 x 6 动作帧
公式：固定描述 + 固定 seed + 换动作骨架（ControlNet）→ perfectPixel 精修
"""
import sys
from pathlib import Path

sys.path.insert(0, r"D:/30DAYS/docs/art_ai")
import numpy as np  # noqa
from PIL import Image  # noqa
from comfy_client import ComfyClient, load_library, split_sampler  # noqa
from perfect_pixel_noCV2 import get_perfect_pixel  # noqa

TOKEN = "$2b$12$1kK2TTR/k/1FDPgDYheTDO3BuSlPdE6e.2cwz916eSiTWvJOLkoa."
HOST = "http://127.0.0.1:18001"
CKPT = "aziibpixelmix_v10.safetensors"
CN = "control_v11p_sd15_openpose.pth"
LIB = load_library()
POSE_DIR = Path("D:/30DAYS/docs/art_ai/output_abc/pose")
OUT = Path("D:/30DAYS/docs/art_ai/output_abc/final_完美像素/动作帧小样")

NEG = ("blurry, low quality, stiff pose, half body, portrait, close-up, crop, ugly, deformed, "
       "child, loli, flat chest, no weapon, effects, particles, magic, aura, background decoration, "
       "multiple characters, text")
PIX = (", crisp pixel art sprite, bold clean color palette, dynamic action pose, clean silhouette, "
       "SOLID uniform plain light background, only the character, no props, no effects, "
       "full body visible head to toe with margin")

# 角色固定描述（与立绘版本一致保证一致性）
CHARS = {
    "若叶睦": ("teenage girl, green bob hair with small low twintails, green eyes, white collared shirt, "
              "red necktie, grey-green jacket, calm expression"),
    "云霓·中式古侠": ("mature woman, very long black straight hair in high ponytail tied with red ribbon, "
                    "black eyes, teardrop mole, chinese xia warrior hanfu dress with flowing white sleeves "
                    "and red sash, cold elegant beauty, empty hands, no weapon"),
}
FRAMES = ["idle_1", "idle_2", "attack_1", "attack_2", "hit_1", "skill_1"]


def main():
    client = ComfyClient(HOST, token=TOKEN)
    sampler, scheduler = split_sampler(LIB["params"]["pixel_direct"]["sampler"])
    OUT.mkdir(parents=True, exist_ok=True)
    pose_names = {}
    for f in FRAMES:
        pose_names[f] = client.upload_image(POSE_DIR / f"{f}_768.png")
    results = []
    for cname, desc in CHARS.items():
        d = OUT / cname
        d.mkdir(parents=True, exist_ok=True)
        for i, frame in enumerate(FRAMES):
            try:
                wf = {
                    "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT}},
                    "2": {"class_type": "CLIPTextEncode", "inputs": {"text": desc + PIX, "clip": ["1", 1]}},
                    "3": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG, "clip": ["1", 1]}},
                    "4": {"class_type": "ControlNetLoader", "inputs": {"control_net_name": CN}},
                    "5": {"class_type": "LoadImage", "inputs": {"image": pose_names[frame]}},
                    "6": {"class_type": "ControlNetApply", "inputs": {"conditioning": ["2", 0], "control_net": ["4", 0], "image": ["5", 0], "strength": 0.95}},
                    "7": {"class_type": "EmptyLatentImage", "inputs": {"width": 768, "height": 768, "batch_size": 1}},
                    "8": {"class_type": "KSampler", "inputs": {"seed": 90000 + i * 3, "steps": 28, "cfg": 6.5,
                         "sampler_name": sampler, "scheduler": scheduler, "denoise": 1.0,
                         "model": ["1", 0], "positive": ["6", 0], "negative": ["3", 0], "latent_image": ["7", 0]}},
                    "9": {"class_type": "VAEDecode", "inputs": {"samples": ["8", 0], "vae": ["1", 2]}},
                    "10": {"class_type": "SaveImage", "inputs": {"filename_prefix": "act", "images": ["9", 0]}},
                }
                pid = client.submit(wf)
                entry = client.wait_history(pid, timeout=600)
                saved = client.download_outputs(entry, OUT / "_raw", f"{cname}_{frame}")
                raw = OUT / "_raw" / saved[0]["file"]
                im = np.array(Image.open(raw).convert("RGB"))
                w, h, out = get_perfect_pixel(im, sample_method="median", min_size=4.0)
                if out is None:
                    raise RuntimeError("网格检测失败")
                img = Image.fromarray(out.astype(np.uint8))
                img.save(d / f"{frame}_96px.png")
                results.append((f"{cname}/{frame}", "OK"))
                print(f"[{cname}] {frame} ✅")
            except Exception as e:
                results.append((f"{cname}/{frame}", f"FAIL {str(e)[:60]}"))
                print(f"[{cname}] {frame} ❌ {str(e)[:60]}")
    (OUT / "_PROGRESS.md").write_text("\n".join(f"{n}: {s}" for n, s in results), encoding="utf-8")
    ok = sum(1 for _, s in results if s == "OK")
    print(f"=== 完成 {ok}/{len(results)} ===")


if __name__ == "__main__":
    main()
