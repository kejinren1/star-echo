#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""C 路线多角色验证：IPAdapter(weight 0.8) + Neta Art XL，style_heroic_cel。"""
import sys, time
from pathlib import Path
sys.path.insert(0, r"D:/30DAYS/docs/art_ai")
from comfy_client import ComfyClient, load_library, build_prompt, split_sampler

TOKEN = "$2b$12$1kK2TTR/k/1FDPgDYheTDO3BuSlPdE6e.2cwz916eSiTWvJOLkoa."
HOST = "http://127.0.0.1:18001"
CKPT = "Neta Art XL 二次元角色 （更新V2）_V2.0.safetensors"
CLIP_VISION = "CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors"
lib = load_library()

def preprocess(src, dst):
    from PIL import Image
    im = Image.open(src)
    if im.mode == "RGBA":
        bg = Image.new("RGB", im.size, (255, 255, 255))
        bg.paste(im, mask=im.split()[3])
        im = bg
    im.thumbnail((1024, 1024), Image.LANCZOS)
    im.save(dst)
    print(f"[pre] {src.name} -> {im.size}")

def build_wf(image_name, prompt, negative, seed):
    sampler, scheduler = split_sampler(lib["params"]["portrait"]["sampler"])
    return {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT}},
        "2": {"class_type": "CLIPTextEncode", "inputs": {"text": prompt, "clip": ["1", 1]}},
        "3": {"class_type": "CLIPTextEncode", "inputs": {"text": negative, "clip": ["1", 1]}},
        "4": {"class_type": "LoadImage", "inputs": {"image": image_name, "upload": "image"}},
        "5": {"class_type": "CLIPVisionLoader", "inputs": {"clip_name": CLIP_VISION}},
        "6": {"class_type": "IPAdapterUnifiedLoader",
              "inputs": {"model": ["1", 0], "preset": "PLUS (high strength)"}},
        "7": {"class_type": "IPAdapter",
              "inputs": {"model": ["6", 0], "ipadapter": ["6", 1], "image": ["4", 0],
                         "weight": 0.8, "start_at": 0.0, "end_at": 1.0,
                         "weight_type": "standard"}},
        "8": {"class_type": "EmptyLatentImage",
              "inputs": {"width": 768, "height": 1024, "batch_size": 1}},
        "9": {"class_type": "KSampler",
              "inputs": {"seed": seed, "steps": 28, "cfg": 7.0,
                         "sampler_name": sampler, "scheduler": scheduler, "denoise": 1.0,
                         "model": ["7", 0], "positive": ["2", 0],
                         "negative": ["3", 0], "latent_image": ["8", 0]}},
        "10": {"class_type": "VAEDecode", "inputs": {"samples": ["9", 0], "vae": ["1", 2]}},
        "11": {"class_type": "SaveImage",
               "inputs": {"filename_prefix": "star_echo_c", "images": ["10", 0]}},
    }

def main():
    client = ComfyClient(HOST, token=TOKEN)
    roles = ["立绘_傀影_1", "立绘_若叶睦_1", "立绘_赤刃明霄陈_1", "立绘_龙舌兰_1"]
    prep_dir = Path("D:/30DAYS/docs/art_ai/output_abc/inputs_1024")
    prep_dir.mkdir(exist_ok=True)
    out_root = Path("D:/30DAYS/docs/art_ai/output_abc/C_ipadapter")
    seed = 12345

    for i, rname in enumerate(roles):
        src = Path(f"D:/30DAYS/测试立绘/{rname}.png")
        prep = prep_dir / f"{rname}.png"
        preprocess(src, prep)
        img_name = client.upload_image(prep)
        prompt, negative = build_prompt(
            lib, "character", "style_heroic_cel", None, None, None, None, None, None, "portrait")
        wf = build_wf(img_name, prompt, negative, seed + i)
        pid = client.submit(wf)
        print(f"[{i+1}/4] {rname} prompt_id={pid}")
        entry = client.wait_history(pid, timeout=900)
        saved = client.download_outputs(entry, out_root / rname, rname)
        # 降采样
        from PIL import Image
        raw = (out_root / rname / saved[0]["file"]) if saved else None
        if raw and raw.exists():
            im = Image.open(raw)
            for size in (128, 64, 32):
                im.resize((size, size), Image.NEAREST).save(out_root / rname / f"{size}px.png")
            print(f"  -> {len(saved)} 张 + 128/64/32 完成")
        else:
            print(f"  !! 下载失败: {saved}")

if __name__ == "__main__":
    main()
