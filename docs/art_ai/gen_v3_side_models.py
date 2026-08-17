#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_v3_side_models.py — v3：局内模型侧身化 + 立绘风格对比小样
用户 08-15 把关：① 局内模型必须有朝向（3/4 侧身，正面直线平移没法用）
② 立绘风格太寡淡高冷，要活力日式西幻；③ 画风统一（4 人团体图校验）。
本脚本：
  A. 程序化生成 3/4 侧身 OpenPose 待机骨架（面朝右，右手叉腰）→ 上传 → 4 主角局内模型
  B. 立绘风格小样：艾琳 × 2 风格（counterfeitxl 明亮经典二次元 / Neta 活力词）供用户定风格
输出：output_abc/v3_side_20260815/
"""
import json
import sys
from pathlib import Path

sys.path.insert(0, r"D:/30DAYS/docs/art_ai")
from comfy_client import ComfyClient  # noqa
from PIL import Image, ImageDraw

HOST = "http://61.157.218.59:31071"
TOKEN = "$2b$12$hJjmO84moQQWigWYsGH10O/yHLqLwBgIPZmwa10BSbTVoGQ6fi4ze"
CKPT_PIX = "aziibpixelmix_v10.safetensors"
CKPT_XL = "Neta Art XL 二次元角色 （更新V2）_V2.0.safetensors"
CKPT_BRIGHT = "counterfeitxl_v10.safetensors"
CN = "control_v11p_sd15_openpose.pth"
OUT = Path("D:/30DAYS/docs/art_ai/output_abc/v3_side_20260815_v2")
OUT.mkdir(parents=True, exist_ok=True)

BG_POS = (", crisp pixel art sprite, bold clean palette, clean silhouette, "
          "three-quarter side view, character turned facing right, side profile visible, "
          "full body visible head to toe, "
          "pure white background, solid flat uniform background, no gradient, no ground shadow, "
          "no rim light, no vignette, no floor, no decorations")
NEG_PIX = ("blurry, low quality, stiff pose, half body, portrait, close-up, crop, ugly, deformed, "
           "child, loli, flat chest, effects, particles, magic, aura, background decoration, "
           "dark background, colored background, red background, gradient background, "
           "ground shadow, vignette, floor, multiple characters, text, watermark, modern clothes, "
           "jeans, t-shirt, hoodie, military uniform, modern machinery, gun, rifle")

# ===== 3/4 侧身待机骨架（面朝右，右手叉腰，重心微偏）=====
# COCO-18 点序：0nose 1neck 2Rsh 3Relb 4Rwri 5Lsh 6Lelb 7Lwri 8Rhip 9Rknee 10Rankle 11Lhip 12Lknee 13Lankle 14Reye 15Leye 16Rear 17Lear
SKEL = {
    0: (0.600, 0.100), 1: (0.585, 0.185), 2: (0.665, 0.205), 3: (0.700, 0.330),
    4: (0.645, 0.435),  5: (0.505, 0.205), 6: (0.465, 0.320), 7: (0.475, 0.440),
    8: (0.585, 0.500),  9: (0.600, 0.660), 10: (0.615, 0.860), 11: (0.505, 0.500),
    12: (0.480, 0.650), 13: (0.450, 0.860), 14: (0.625, 0.092), 15: (0.565, 0.092),
    16: (0.660, 0.115), 17: (0.520, 0.115),
}
BONES = [(0,1),(1,2),(1,5),(2,3),(3,4),(5,6),(6,7),(1,8),(1,11),(8,9),(9,10),(11,12),(12,13),(0,14),(0,15),(14,16),(15,17)]
COLORS = {
    "head": (255, 0, 0), "torso": (0, 255, 0), "r_arm": (255, 165, 0), "l_arm": (255, 255, 0),
    "r_leg": (0, 0, 255), "l_leg": (255, 0, 255),
}


def draw_skeleton(size=768) -> Image.Image:
    """OpenPose 风格骨架：彩色光晕圆点（heatmap 式）+ 粗肢体线，贴近 controlnet 训练分布"""
    im = Image.new("RGB", (size, size), (0, 0, 0))
    d = ImageDraw.Draw(im)
    pts = {k: (int(v[0] * size), int(v[1] * size)) for k, v in SKEL.items()}
    bone_color = {
        (0, 1): COLORS["head"], (0, 14): COLORS["head"], (0, 15): COLORS["head"],
        (14, 16): COLORS["head"], (15, 17): COLORS["head"],
        (1, 2): COLORS["r_arm"], (2, 3): COLORS["r_arm"], (3, 4): COLORS["r_arm"],
        (1, 5): COLORS["l_arm"], (5, 6): COLORS["l_arm"], (6, 7): COLORS["l_arm"],
        (1, 8): COLORS["torso"], (1, 11): COLORS["torso"],
        (8, 9): COLORS["r_leg"], (9, 10): COLORS["r_leg"],
        (11, 12): COLORS["l_leg"], (12, 13): COLORS["l_leg"],
    }
    for a, b in BONES:
        d.line([pts[a], pts[b]], fill=bone_color[(a, b)], width=14)
    # heatmap 式光晕点：多层圆模拟高斯
    for k, (x, y) in pts.items():
        for r, a in [(28, 40), (20, 80), (13, 150), (9, 255)]:
            d.ellipse([x - r, y - r, x + r, y + r], fill=(a, a, a) if r == 9 else (255, 255, 255))
    return im


HEROES = {
    "elin": "young woman, long crimson red hair, red eyes, elegant classic fantasy mage, long black robe with crimson and gold flame embroidery, holding a floating glowing flame orb, dignified fire mage",
    "noah": "young woman, short silver blue hair, blue eyes, magitech tinkerer of a fantasy workshop, ornate dark navy coat with brass rune gears and copper clockwork ornaments, small floating cogwork fairy companion, holding a glowing rune device, fantasy engineer",
    "lain": "young man, short white hair, sharp blue eyes, knight errant of a fantasy kingdom, silver and white full armor with blue cape, rune-carved longsword resting on shoulder, heroic knight",
    "siia": "young woman, long soft golden hair, gentle green eyes, gentle cleric of a fantasy church, white and gold priestess robe with light ornaments, radiant healing staff in hand, warm healer",
}


def build_model_wf(desc, pose_name, seed):
    text = desc + BG_POS
    wf = {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT_PIX}},
        "2": {"class_type": "CLIPTextEncode", "inputs": {"text": text, "clip": ["1", 1]}},
        "3": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG_PIX, "clip": ["1", 1]}},
        "4": {"class_type": "ControlNetLoader", "inputs": {"control_net_name": CN}},
        "5": {"class_type": "LoadImage", "inputs": {"image": pose_name}},
        "6": {"class_type": "ControlNetApply", "inputs": {"conditioning": ["2", 0], "control_net": ["4", 0],
             "image": ["5", 0], "strength": 0.9}},
        "7": {"class_type": "EmptyLatentImage", "inputs": {"width": 768, "height": 768, "batch_size": 1}},
        "8": {"class_type": "KSampler", "inputs": {"seed": seed, "steps": 28, "cfg": 6.5,
             "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 1.0,
             "model": ["1", 0], "positive": ["6", 0], "negative": ["3", 0], "latent_image": ["7", 0]}},
        "9": {"class_type": "VAEDecode", "inputs": {"samples": ["8", 0], "vae": ["1", 2]}},
        "10": {"class_type": "SaveImage", "inputs": {"filename_prefix": "v3model", "images": ["9", 0]}},
    }
    return wf


def build_portrait_wf(desc, seed, ckpt, style_words):
    text = (f"masterpiece, best quality, highly detailed, sharp focus, clean lineart, "
            f"{style_words}, {desc}, full body character concept art, standing pose, "
            f"pure white background, solid flat uniform background, no gradient, no shadow, "
            f"no decorations, no effects")
    neg = ("blurry, low quality, deformed hands, extra fingers, bad anatomy, watermark, text, "
           "multiple characters, ugly, background details, gradient background, shadow, "
           "dark background, decorations, modern clothes, jeans, t-shirt, hoodie, military uniform, "
           "modern machinery, gun, rifle")
    wf = {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": ckpt}},
        "2": {"class_type": "CLIPTextEncode", "inputs": {"text": text, "clip": ["1", 1]}},
        "3": {"class_type": "CLIPTextEncode", "inputs": {"text": neg, "clip": ["1", 1]}},
        "7": {"class_type": "EmptyLatentImage", "inputs": {"width": 768, "height": 1024, "batch_size": 1}},
        "8": {"class_type": "KSampler", "inputs": {"seed": seed, "steps": 28, "cfg": 7.0,
             "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 1.0,
             "model": ["1", 0], "positive": ["2", 0], "negative": ["3", 0], "latent_image": ["7", 0]}},
        "9": {"class_type": "VAEDecode", "inputs": {"samples": ["8", 0], "vae": ["1", 2]}},
        "10": {"class_type": "SaveImage", "inputs": {"filename_prefix": "v3portrait", "images": ["9", 0]}},
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

    # 1) 侧身骨架：本地生成 → 上传
    skel = draw_skeleton()
    skel_path = OUT / "侧身待机骨架_v2_768.png"
    skel.save(skel_path)
    pose_name = client.upload_image(skel_path)
    print(f"[pose] 侧身骨架已上传: {pose_name}")

    tasks = []
    seed = 2026081700
    # 2) 4 主角局内模型（侧身）
    for i, (hid, desc) in enumerate(HEROES.items()):
        tasks.append((f"model_{hid}", f"models", build_model_wf(desc, pose_name, seed + i * 13)))
    # 3) 立绘风格小样：艾琳 × 2 风格
    elin_desc = HEROES["elin"]
    tasks.append(("portrait_elin_bright", "portraits",
                  build_portrait_wf(elin_desc, seed + 300, CKPT_BRIGHT,
                                    "vibrant bright cheerful anime illustration, warm sunlight, "
                                    "rich saturated colors, sparkling eyes, lively energetic atmosphere, "
                                    "colorful soft glow, cel shading")))
    tasks.append(("portrait_elin_neta_vivid", "portraits",
                  build_portrait_wf(elin_desc, seed + 400, CKPT_XL,
                                    "vivid lively anime illustration, bright warm palette, "
                                    "energetic cheerful mood, luminous colors, sparkling highlights, "
                                    "cel shading with vibrant finish")))

    print(f"[plan] 共 {len(tasks)} 张（4 局内模型 + 2 立绘风格小样）")
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
    print("=== 完成 ===")
    print(f"成功 {ok}/{len(tasks)}，失败 {len(fail)}")
    for n, e in fail:
        print(f"  {n}: {e}")


if __name__ == "__main__":
    main()
