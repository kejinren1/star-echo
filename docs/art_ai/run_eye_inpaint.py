#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""run_eye_inpaint.py — A 道：眼部 inpaint 重绘（512 像素化图 + 眼睛 mask）。
LoadImage(RGBA) 双输出 → VAEEncode + SetLatentNoiseMask → KSampler(denoise 0.4)。
"""
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, r"D:/30DAYS/docs/art_ai")
from comfy_client import ComfyClient, load_library, build_prompt, split_sampler  # noqa
from eye_tools import detect_eyes, make_inpaint_image  # noqa
import numpy as np

TOKEN = "$2b$12$1kK2TTR/k/1FDPgDYheTDO3BuSlPdE6e.2cwz916eSiTWvJOLkoa."
HOST = "http://127.0.0.1:18001"
CKPT = "aziibpixelmix_v10.safetensors"
LIB = load_library()

BASE = Path("D:/30DAYS/docs/art_ai/output_abc/CB_组合")
MASK_DIR = Path("D:/30DAYS/docs/art_ai/output_abc/eyes_fix/inpaint_input")
OUT_DIR = Path("D:/30DAYS/docs/art_ai/output_abc/eyes_fix/inpaint_result")


def build_wf(image_name, mask_name, prompt, negative, seed):
    sampler, scheduler = split_sampler(LIB["params"]["portrait"]["sampler"])
    return {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT}},
        "4": {"class_type": "LoadImage", "inputs": {"image": image_name, "upload": "image"}},
        "12": {"class_type": "LoadImage", "inputs": {"image": mask_name, "upload": "image"}},
        "13": {"class_type": "ImageToMask",
               "inputs": {"image": ["12", 0], "channel": "red"}},
        "5": {"class_type": "VAEEncode", "inputs": {"pixels": ["4", 0], "vae": ["1", 2]}},
        "6": {"class_type": "SetLatentNoiseMask",
              "inputs": {"samples": ["5", 0], "mask": ["13", 0]}},
        "7": {"class_type": "CLIPTextEncode",
              "inputs": {"text": prompt + ", detailed pixel art eyes, bright white eye highlight, shiny sparkling eyes",
                         "clip": ["1", 1]}},
        "8": {"class_type": "CLIPTextEncode", "inputs": {"text": negative, "clip": ["1", 1]}},
        "9": {"class_type": "KSampler",
              "inputs": {"seed": seed, "steps": 25, "cfg": 6.5,
                         "sampler_name": sampler, "scheduler": scheduler, "denoise": 0.4,
                         "model": ["1", 0], "positive": ["7", 0],
                         "negative": ["8", 0], "latent_image": ["6", 0]}},
        "10": {"class_type": "VAEDecode", "inputs": {"samples": ["9", 0], "vae": ["1", 2]}},
        "11": {"class_type": "SaveImage",
               "inputs": {"filename_prefix": "star_echo_eye", "images": ["10", 0]}},
    }


def main():
    roles = sys.argv[1:] or ["若叶睦", "傀影", "安洁莉娜"]
    client = ComfyClient(HOST, token=TOKEN)
    for i, name in enumerate(roles):
        d = BASE / name
        im512 = Image.open(d / "2_像素化.png")
        eyes = detect_eyes(im512)
        if len(eyes) != 2:
            print(f"[{name}] 眼睛检测失败 {eyes}，跳过")
            continue
        inp = make_inpaint_image(im512, eyes, MASK_DIR / f"{name}.png")
        img_name = client.upload_image(inp)
        # mask 白图（单独上传，ImageToMask 用）
        arr = np.array(Image.open(inp))[:, :, 3]
        mask_img = Image.fromarray(arr).convert("L")
        mask_path = MASK_DIR / f"{name}_mask.png"
        mask_img.save(mask_path)
        mask_name = client.upload_image(mask_path)
        prompt, negative = build_prompt(
            LIB, "character", "style_heroic_cel", None, None, None,
            None, None, None, "portrait")
        pid = client.submit(build_wf(img_name, mask_name, prompt, negative, 30000 + i))
        print(f"[{name}] inpaint prompt_id={pid}")
        entry = client.wait_history(pid, timeout=600)
        saved = client.download_outputs(entry, OUT_DIR, name)
        print(f"[{name}] ✅ {len(saved)} 张")


if __name__ == "__main__":
    main()
