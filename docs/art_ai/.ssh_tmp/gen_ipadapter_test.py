#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_ipadapter_test.py — IPAdapter 角色一致性验证（1 张）
用定稿 96px 像素图做角色参考 + 纯黑背景强化，NoobAI 1024×1536
"""
import json, time, urllib.request

HOST = "http://127.0.0.1:18001"
TOKEN = "$2b$12$.TAugRmvKlv5LxFdgOXP4.7mFvhRY2GpvKmr2S8kvAVB9bP/ivSae"
CKPT = "NoobAI-XL-v1.1.safetensors"

POS = ("masterpiece, best quality, highly detailed, sharp focus, clean lineart, "
       "1girl, petite loli, short stature, deep crimson red long hair, red eyes, "
       "tall classic pointed wizard hat with wide brim, black and red mage robe "
       "with gold flame patterns, long flowing robe reaching to feet, "
       "wide billowing sleeves, small simple wooden wand, black red gold color scheme, "
       "full body, standing, three-quarter view, body turned slightly to the side, "
       "solid pure black background, flat uniform background, "
       "low-key cinematic lighting, warm rim light, muted desaturated color palette, "
       "with margin, completely inside frame, no cropping, "
       "(masterpiece iris:1.3), (detailed iris:1.35), (sparkling eyes:1.25), "
       "(long eyelashes:1.25), (detailed face:1.2), sharp facial features")

NEG = ("worst quality, low quality, blurry, bad anatomy, extra fingers, watermark, text, logo, signature, "
       "bad eyes, deformed iris, ugly eyes, poor facial details, blurry face, distorted face, bad face, "
       "cluttered outfit, messy clothes, tangled hair, noisy background, "
       "effects, magic aura, glow, particles, floating objects, "
       "background scene, environment, scenery, gradient background, "
       "out of frame, cropped figure, pixel art, pixelated, mosaic")

WF = {
    "1": {"class_type": "LoadImage", "inputs": {"image": "refs_px/elin_ref.png"}},
    "2": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT}},
    "3": {"class_type": "easy ipadapterApply", "inputs": {
        "model": ["2", 0], "image": ["1", 0],
        "preset": "PLUS (high strength)", "lora_strength": 0.6, "provider": "CUDA",
        "weight": 0.85, "weight_faceidv2": 1.0, "start_at": 0.0, "end_at": 1.0,
        "cache_mode": "all", "use_tiled": False}},
    "4": {"class_type": "CLIPTextEncode", "inputs": {"text": POS, "clip": ["2", 1]}},
    "5": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG, "clip": ["2", 1]}},
    "6": {"class_type": "EmptyLatentImage", "inputs": {"width": 1024, "height": 1536, "batch_size": 1}},
    "7": {"class_type": "KSampler", "inputs": {"seed": 20260816, "steps": 32, "cfg": 6.5,
          "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 1.0,
          "model": ["3", 0], "positive": ["4", 0], "negative": ["5", 0], "latent_image": ["6", 0]}},
    "8": {"class_type": "VAEDecode", "inputs": {"samples": ["7", 0], "vae": ["2", 2]}},
    "9": {"class_type": "SaveImage", "inputs": {"filename_prefix": "ipad_test_elin_A1", "images": ["8", 0]}},
}


def api(path, payload=None):
    url = HOST + path
    data = json.dumps(payload).encode() if payload else None
    req = urllib.request.Request(url, data=data, method="POST" if payload else "GET")
    req.add_header("Authorization", "Bearer " + TOKEN)
    req.add_header("Content-Type", "application/json")
    with urllib.request.urlopen(req, timeout=90) as r:
        return json.loads(r.read())


resp = api("/prompt", {"prompt": WF})
pid = resp.get("prompt_id")
print("PID:", pid, flush=True)
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
                    print("NODE_ERR:", m[1].get("exception_message", "")[:300], flush=True)
                    for tb in (m[1].get("traceback") or [])[-6:]:
                        print("  TB:", tb[:200], flush=True)
        else:
            print(f"SUCCESS {time.time()-t0:.0f}s", flush=True)
        break
