#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_boss_elite_move.py — 精英/Boss move 规格修复（一次性）
背景：08-15 试装误把 elite/invoker/predator 的 move 降成 48px，SPRITE_MAP 声明仍是 64/128。
本脚本：新背景规范（纯白底）重跑 3 张 → 抠底 → 降采样 64/128 → 量化 → 拼 4 帧 sheet → 直接替换。
"""
import json
import sys
from pathlib import Path

sys.path.insert(0, r"D:/30DAYS/docs/art_ai")
sys.path.insert(0, r"D:/30DAYS/tools")
from comfy_client import ComfyClient  # noqa
from img2sprite import cutout_floodfill, auto_crop, downsample, quantize, load_palette  # noqa
from PIL import Image

HOST = "http://61.157.218.59:31071"
TOKEN = "$2b$12$hJjmO84moQQWigWYsGH10O/yHLqLwBgIPZmwa10BSbTVoGQ6fi4ze"
CKPT_PIX = "aziibpixelmix_v10.safetensors"
CN = "control_v11p_sd15_openpose.pth"
POSE_DIR = Path("D:/30DAYS/docs/art_ai/output_abc/pose")
OUT_DIR = Path("D:/30DAYS/docs/art_ai/output_abc/boss_elite_fix_20260815")
PALETTE = load_palette(Path("D:/30DAYS/ART/COLOR_DICT.json"))

BG_POS = (", crisp pixel art sprite, bold clean palette, clean silhouette, full body visible head to toe, "
          "pure white background, solid flat uniform background, no gradient, no ground shadow, "
          "no rim light, no vignette, no floor, no decorations")
NEG = ("blurry, low quality, stiff pose, half body, portrait, close-up, crop, ugly, deformed, "
       "child, loli, flat chest, effects, particles, magic, aura, background decoration, "
       "dark background, colored background, red background, gradient background, "
       "ground shadow, vignette, floor, multiple characters, text, watermark")

TARGETS = {
    # id: (描述, 帧尺寸, 输出路径)
    "elite": ("elite heavy armored soldier, black and gold full plate armor with glowing red core, large warhammer",
              64, Path("D:/30DAYS/assets/sprites/enemies/elite_move.png")),
    "invoker": ("hooded invoker mage, dark purple robe, glowing arcane runes, floating skull staff, sinister",
                128, Path("D:/30DAYS/assets/sprites/enemies/invoker_move.png")),
    "predator": ("feral predator beast, quadrupedal dark red creature with spikes and glowing eyes, sharp claws",
                 128, Path("D:/30DAYS/assets/sprites/enemies/predator_move.png")),
}


def build_wf(desc, pose_name, seed):
    wf = {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT_PIX}},
        "2": {"class_type": "CLIPTextEncode", "inputs": {"text": desc + BG_POS, "clip": ["1", 1]}},
        "3": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG, "clip": ["1", 1]}},
        "4": {"class_type": "ControlNetLoader", "inputs": {"control_net_name": CN}},
        "5": {"class_type": "LoadImage", "inputs": {"image": pose_name}},
        "6": {"class_type": "ControlNetApply", "inputs": {"conditioning": ["2", 0], "control_net": ["4", 0],
             "image": ["5", 0], "strength": 0.9}},
        "7": {"class_type": "EmptyLatentImage", "inputs": {"width": 768, "height": 768, "batch_size": 1}},
        "8": {"class_type": "KSampler", "inputs": {"seed": seed, "steps": 28, "cfg": 6.5,
             "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 1.0,
             "model": ["1", 0], "positive": ["6", 0], "negative": ["3", 0], "latent_image": ["7", 0]}},
        "9": {"class_type": "VAEDecode", "inputs": {"samples": ["8", 0], "vae": ["1", 2]}},
        "10": {"class_type": "SaveImage", "inputs": {"filename_prefix": "beboss", "images": ["9", 0]}},
    }
    return wf


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    client = ComfyClient(HOST, token=TOKEN)
    pose_names = {f.name: client.upload_image(f) for f in POSE_DIR.glob("*_768.png")}
    pose_std = pose_names["标准站姿骨架_768.png"]

    for i, (mid, (desc, frame_px, out_path)) in enumerate(TARGETS.items()):
        seed = 2026081600 + i
        pid = client.submit(build_wf(desc, pose_std, seed))
        entry = client.wait_history(pid, timeout=900)
        saved = client.download_outputs(entry, OUT_DIR, f"{mid}_src")
        src = OUT_DIR / saved[0]["file"]
        print(f"[{mid}] 生成 {src.name}")

        # 后处理：抠底 → bbox → 降采样 → 量化 → 4 帧拼 sheet
        im = Image.open(src).convert("RGBA")
        im = cutout_floodfill(im, tol=40)
        im = auto_crop(im)
        W, H = im.size
        out_h = max(1, round(H * frame_px / W))
        small = downsample(im, frame_px, out_h, "median")
        small = quantize(small, PALETTE)
        frame = Image.new("RGBA", (frame_px, frame_px), (0, 0, 0, 0))
        frame.paste(small, ((frame_px - frame_px) // 2, (frame_px - small.size[1]) // 2), small)
        sheet = Image.new("RGBA", (frame_px * 4, frame_px), (0, 0, 0, 0))
        for fi in range(4):
            sheet.paste(frame, (fi * frame_px, 0), frame)
        sheet.save(out_path)
        print(f"[{mid}] 已替换 {out_path.name} {sheet.size} (bbox {W}x{H})")

    print("=== 完成 ===")


if __name__ == "__main__":
    main()
