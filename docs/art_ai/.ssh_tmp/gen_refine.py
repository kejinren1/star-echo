#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_refine.py — img2img 二段精修实验（艾琳 3 变体）
变体1: 段2 denoise 0.35（温和精修）   变体2: 段2 denoise 0.45（加强精修）
变体3: 单段 denoise 0.75（对照：一步到位提画质）
"""
import json, time, urllib.request

HOST = "http://127.0.0.1:18001"
TOKEN = "$2b$12$.TAugRmvKlv5LxFdgOXP4.7mFvhRY2GpvKmr2S8kvAVB9bP/ivSae"
CKPT = "NoobAI-XL-v1.1.safetensors"

POS = ("masterpiece, best quality, highly detailed, sharp focus, clean lineart, "
       "intricate details, fine fabric texture, "
       "1girl, petite loli, short stature, deep crimson red long hair, red eyes, "
       "tall classic pointed wizard hat with wide brim, black and red mage robe "
       "with gold flame patterns, long flowing robe reaching to feet, "
       "wide billowing sleeves, small simple wooden wand, black red gold color scheme, "
       "full body, standing, three-quarter view, body turned slightly to the side, "
       "solid pure gray background, flat uniform background, "
       "low-key cinematic lighting, warm rim light, muted desaturated color palette, "
       "with margin, completely inside frame, no cropping, "
       "(masterpiece iris:1.3), (detailed iris:1.35), (sparkling eyes:1.25), "
       "(long eyelashes:1.25), (detailed face:1.2), sharp facial features")

NEG = ("worst quality, low quality, blurry, bad anatomy, extra fingers, watermark, text, logo, signature, "
       "bad eyes, deformed iris, ugly eyes, poor facial details, blurry face, distorted face, bad face, "
       "cluttered outfit, messy clothes, tangled hair, noisy background, "
       "effects, magic aura, glow, particles, floating objects, "
       "background scene, environment, scenery, gradient background, "
       "out of frame, cropped figure, pixel art, pixelated, mosaic, flat colors")


def api(path, payload=None):
    url = HOST + path
    data = json.dumps(payload).encode() if payload else None
    req = urllib.request.Request(url, data=data, method="POST" if payload else "GET")
    req.add_header("Authorization", "Bearer " + TOKEN)
    req.add_header("Content-Type", "application/json")
    with urllib.request.urlopen(req, timeout=90) as r:
        return json.loads(r.read())


def wf_img2img(init, denoise, seed, prefix):
    return {
        "1": {"class_type": "LoadImage", "inputs": {"image": init}},
        "2": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT}},
        "3": {"class_type": "VAEEncode", "inputs": {"pixels": ["1", 0], "vae": ["2", 2]}},
        "4": {"class_type": "CLIPTextEncode", "inputs": {"text": POS, "clip": ["2", 1]}},
        "5": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG, "clip": ["2", 1]}},
        "6": {"class_type": "KSampler", "inputs": {"seed": seed, "steps": 32, "cfg": 6.5,
              "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": denoise,
              "model": ["2", 0], "positive": ["4", 0], "negative": ["5", 0], "latent_image": ["3", 0]}},
        "7": {"class_type": "VAEDecode", "inputs": {"samples": ["6", 0], "vae": ["2", 2]}},
        "8": {"class_type": "SaveImage", "inputs": {"filename_prefix": prefix, "images": ["7", 0]}},
    }


VARIANTS = [
    ("init_gray/elin_init_gray.png",      0.75, 20260816, "refine_v5_gray"),
    ("init_gray/elin_init_gray.png",      0.35, 20260816, "refine_v5b_gray035"),
    ("init_gray/elin_init_gray.png",      0.45, 20260816, "refine_v5c_gray045"),
]

for init, denoise, seed, prefix in VARIANTS:
    wf = wf_img2img(init, denoise, seed, prefix)
    resp = api("/prompt", {"prompt": wf})
    pid = resp.get("prompt_id")
    t0 = time.time()
    while True:
        time.sleep(4)
        try:
            h = api(f"/history/{pid}")
        except Exception:
            time.sleep(8)
            continue
        if pid in h:
            st = h[pid]["status"].get("status_str", "")
            if st == "error":
                for m in h[pid]["status"].get("messages", []):
                    if m[0] == "execution_error":
                        print(f"NODE_ERR {prefix}:", m[1].get("exception_message", "")[:150], flush=True)
            else:
                print(f"DONE {prefix} denoise={denoise} ({time.time()-t0:.0f}s)", flush=True)
            break
print("ALL_FINISHED", flush=True)
