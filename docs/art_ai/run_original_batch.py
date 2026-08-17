#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""run_original_batch.py — 原创女角色批量：图鉴要素组合 → 文字直出 → perfectPixel 精修
10 角色 x 风格差异化，全部御姐/巨乳向，像素风管线（aziibpixelmix + v3 骨架 + 768）。
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
POSE = Path("D:/30DAYS/docs/art_ai/output_abc/pose/待机叉腰骨架_v4_768.png")
OUT = Path("D:/30DAYS/docs/art_ai/output_abc/final_完美像素/原创女角色")

NEG = ("blurry, low quality, stiff pose, symmetrical pose, boring, half body, portrait, "
       "close-up, crop, bust, headshot, ugly, deformed, child, loli, flat chest, "
       "no weapon, no props, empty hands, no sword, no staff")
PIX = (", crisp pixel art sprite, bold clean color palette, confident idle stance, "
       "one hand on hip, relaxed casual pose, natural weight shift, clean silhouette, "
       "plain light background, full body visible head to toe with margin, mature curvy woman, "
       "large bust, hourglass figure, long legs, empty hands, no weapon")

# 10 原创角色（图鉴要素组合 x 风格差异化；名称=原创；去武器化）
ROLES = [
    ("云霓·中式古侠", "mature woman, very long black straight hair in high ponytail tied with red ribbon, black eyes, teardrop mole, chinese xia warrior hanfu dress with flowing white sleeves and red sash, cold elegant beauty"),
    ("银薇·西幻法师", "mature elf woman, long silver white hair, purple eyes, pointy ears, ornate purple mage robe with golden runes and star patterns, mystical noble aura"),
    ("绯月·日式巫女", "mature shrine maiden woman, black hime cut hair with white hair ribbon, fox amber eyes, red and white miko outfit with large sleeves, fox ears and fluffy tail, serene mysterious smile"),
    ("蜜糖·西海岸辣妹", "mature woman, long wavy golden blonde hair with pink gradient highlights, green eyes, tan skin, crop top and high-waist shorts, fishnet stockings, sunglasses on head, confident beach babe smile"),
    ("奈芙·埃及祭司", "mature woman, straight black hair with golden beads and headdress, golden amber eyes, heavy eyeliner, egyptian priestess outfit with gold collar and sheer white fabric, arm bands, regal exotic look"),
    ("零·赛博义体", "mature woman, silver blue gradient hair with neon cyan highlights, heterochromatic eyes blue and cyan, cyberpunk bodysuit with glowing circuit lines, choker, cool detached expression"),
    ("冰霜·维京女武神", "mature woman, long silver white braided hair with beads, ice blue eyes, leather armor with fur mantle, rune tattoos on arm, fierce warrior queen"),
    ("芙蕾雅·英伦大小姐", "mature noblewoman, long curly golden blonde hair, blue eyes, elegant victorian dress with lace and corset, pearl necklace, haughty refined pose"),
    ("影·忍者暗杀者", "mature kunoichi woman, black long hair in high ponytail with red ribbon, crimson red eyes, dark navy ninja outfit with mesh, face scarf pulled down, deadly graceful stance"),
    ("夜莺·哥特女王", "mature gothic woman, long wavy black purple hair, crimson red eyes, black gothic lolita dress with lace and roses, choker with cross, pale skin, fang smile, dark elegant aura"),
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
                "8": {"class_type": "KSampler", "inputs": {"seed": 70000 + i * 11, "steps": 28, "cfg": 6.5,
                     "sampler_name": sampler, "scheduler": scheduler, "denoise": 1.0,
                     "model": ["1", 0], "positive": ["6", 0], "negative": ["3", 0], "latent_image": ["7", 0]}},
                "9": {"class_type": "VAEDecode", "inputs": {"samples": ["8", 0], "vae": ["1", 2]}},
                "10": {"class_type": "SaveImage", "inputs": {"filename_prefix": "orig", "images": ["9", 0]}},
            }
            pid = client.submit(wf)
            entry = client.wait_history(pid, timeout=600)
            saved = client.download_outputs(entry, OUT / "_raw", name)
            raw = OUT / "_raw" / saved[0]["file"]
            # perfectPixel 精修
            im = np.array(Image.open(raw).convert("RGB"))
            w, h, out = get_perfect_pixel(im, sample_method="median", min_size=4.0)
            if out is None:
                raise RuntimeError("网格检测失败")
            d = OUT / name
            d.mkdir(parents=True, exist_ok=True)
            img = Image.fromarray(out.astype(np.uint8))
            img.save(d / "96px.png")
            img.resize((48, 48), Image.NEAREST).save(d / "48px.png")
            img.resize((32, 32), Image.NEAREST).save(d / "32px.png")
            img.resize((288, 288), Image.NEAREST).save(d / "96px_x3预览.png")
            results.append((name, f"OK grid={w}x{h}"))
            print(f"[{i+1}/10] {name} ✅ grid={w}x{h}")
        except Exception as e:
            results.append((name, f"FAIL {str(e)[:80]}"))
            print(f"[{i+1}/10] {name} ❌ {str(e)[:80]}")
    (OUT / "_PROGRESS.md").write_text("\n".join(f"{n}: {s}" for n, s in results), encoding="utf-8")
    print("=== 完成 ===")
    for n, s in results:
        print(f"  {n}: {s}")


if __name__ == "__main__":
    main()
