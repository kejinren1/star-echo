#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""主线角色像素直出演示：aziibpixelmix txt2img 512×512"""
import json, time, urllib.request

HOST = "http://127.0.0.1:18001"
TOKEN = "$2b$12$.TAugRmvKlv5LxFdgOXP4.7mFvhRY2GpvKmr2S8kvAVB9bP/ivSae"
CKPT = "aziibpixelmix_v10.safetensors"

def api(path, payload=None):
    url = HOST + path
    data = json.dumps(payload).encode() if payload else None
    req = urllib.request.Request(url, data=data, method="POST" if payload else "GET")
    req.add_header("Authorization", "Bearer " + TOKEN)
    req.add_header("Content-Type", "application/json")
    with urllib.request.urlopen(req, timeout=90) as r:
        return json.loads(r.read())

ELIN = ("masterpiece, best quality, pixel art, sprite, 1girl, solo, "
        "red hair, long hair, side braid, red eyes, "
        "elegant black mage robe with crimson flame embroidery, gold trim, "
        "wide billowing sleeves, holding a floating glowing flame orb, "
        "full body, standing, looking at viewer, black background, "
        "detailed pixel shading, retro game style, crisp pixels, high contrast")

NEG = ("worst quality, low quality, blurry, bad anatomy, watermark, text, "
       "photorealistic, 3d render, smooth shading, anti-aliasing")

def make_wf(seed, prefix):
    return {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT}},
        "2": {"class_type": "EmptyLatentImage", "inputs": {"width": 512, "height": 512, "batch_size": 1}},
        "3": {"class_type": "CLIPTextEncode", "inputs": {"text": ELIN, "clip": ["1", 1]}},
        "4": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG, "clip": ["1", 1]}},
        "5": {"class_type": "KSampler", "inputs": {"seed": seed, "steps": 28, "cfg": 7.0,
              "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 1.0,
              "model": ["1", 0], "positive": ["3", 0], "negative": ["4", 0], "latent_image": ["2", 0]}},
        "6": {"class_type": "VAEDecode", "inputs": {"samples": ["5", 0], "vae": ["1", 2]}},
        "7": {"class_type": "SaveImage", "inputs": {"filename_prefix": prefix, "images": ["6", 0]}},
    }

for i, seed in enumerate([881, 882]):
    prefix = f"elin_pixel_{i+1}"
    wf = make_wf(seed, prefix)
    try:
        resp = api("/prompt", {"prompt": wf})
    except Exception as e:
        print(f"FAIL {prefix}: {e}", flush=True)
        continue
    pid = resp.get("prompt_id")
    while True:
        time.sleep(4)
        try:
            h = api(f"/history/{pid}")
        except Exception:
            time.sleep(8)
            continue
        if pid in h:
            for nid, o in h[pid]["outputs"].items():
                for img in o.get("images", []):
                    print(f"DONE {prefix}: {img['filename']}", flush=True)
            break
print("FINISHED", flush=True)
