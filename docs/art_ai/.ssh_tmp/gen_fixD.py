#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_fixC2.py — IPAdapter 一致性梯度实验（艾琳 3 变体）
V1: STANDARD w0.35 end0.6   V2: STANDARD w0.45 end0.7   V3: PLUS w0.3 end0.7
txt2img 直出 + 8头身 + 灰底（fixC 画质基线保留）
"""
import json, time, urllib.request

HOST = "http://127.0.0.1:18001"
TOKEN = "$2b$12$.TAugRmvKlv5LxFdgOXP4.7mFvhRY2GpvKmr2S8kvAVB9bP/ivSae"
CKPT = "NoobAI-XL-v1.1.safetensors"

STYLE = ("solid pure gray background, flat uniform background, "
         "low-key cinematic lighting, warm rim light, muted desaturated color palette, "
         "with margin, completely inside frame, no cropping")
POSEY = "full body, standing, three-quarter view, body turned slightly to the side"
EYE_F = ("detailed eyes, detailed iris, natural eyelashes, elegant mature face, "
         "detailed face, sharp facial features")
QUALITY = ("masterpiece, best quality, highly detailed, sharp focus, clean lineart, "
           "intricate details, rich fabric folds and shadows, detailed material texture, "
           "detailed hair strands with flowing direction, professional illustration")

ELIN = ("1girl, petite loli, short stature, deep crimson red long hair, red eyes, "
        "tall classic pointed witch hat with wide brim, black witch robe "
        "with red flame patterns, pleated knee-length skirt, short dress, "
        "long sleeves, wide billowing sleeves, black boots, "
        "small simple wooden wand, black red gold color scheme")

NEG = ("worst quality, low quality, blurry, bad anatomy, extra fingers, watermark, text, logo, signature, "
       "bad eyes, deformed iris, ugly eyes, poor facial details, blurry face, distorted face, bad face, "
       "cluttered outfit, messy clothes, tangled hair, noisy background, "
       "effects, magic aura, glow, particles, floating objects, "
       "background scene, environment, scenery, gradient background, "
       "out of frame, cropped figure, pixel art, pixelated, mosaic, flat colors, "
       "large head, small body, short legs, tiny body, oversized head, "
       "chibi, loli, kid, childlike, baby face, petite, short stature, midget, "
       "plain face, featureless face, distorted face, warped face, deformed face, "
       "simple drawing, childish drawing, stick figure, crayon drawing, flat shading, no shading")


def api(path, payload=None):
    url = HOST + path
    data = json.dumps(payload).encode() if payload else None
    req = urllib.request.Request(url, data=data, method="POST" if payload else "GET")
    req.add_header("Authorization", "Bearer " + TOKEN)
    req.add_header("Content-Type", "application/json")
    with urllib.request.urlopen(req, timeout=120) as r:
        return json.loads(r.read())


def make_wf(preset, weight, end_at, seed, prefix):
    pos = f"{QUALITY}, {ELIN}, {POSEY}, {STYLE}, {EYE_F}"
    return {
        "1": {"class_type": "LoadImage", "inputs": {"image": "refs_768/elin_768.png"}},
        "2": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT}},
        "3": {"class_type": "easy ipadapterApply", "inputs": {
            "model": ["2", 0], "image": ["1", 0],
            "preset": preset, "lora_strength": 0.3, "provider": "CUDA",
            "weight": weight, "weight_faceidv2": 1.0, "start_at": 0.0, "end_at": end_at,
            "cache_mode": "all", "use_tiled": False}},
        "4": {"class_type": "CLIPTextEncode", "inputs": {"text": pos, "clip": ["2", 1]}},
        "5": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG, "clip": ["2", 1]}},
        "6": {"class_type": "EmptyLatentImage", "inputs": {"width": 1024, "height": 1536, "batch_size": 1}},
        "7": {"class_type": "KSampler", "inputs": {"seed": seed, "steps": 32, "cfg": 6.5,
              "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 1.0,
              "model": ["3", 0], "positive": ["4", 0], "negative": ["5", 0], "latent_image": ["6", 0]}},
        "8": {"class_type": "VAEDecode", "inputs": {"samples": ["7", 0], "vae": ["2", 2]}},
        "9": {"class_type": "SaveImage", "inputs": {"filename_prefix": prefix, "images": ["8", 0]}},
    }


VARIANTS = [
    ("STANDARD (medium strength)", 0.45, 0.7, "fixE_elin_wd"),
]

for preset, weight, end_at, prefix in VARIANTS:
    wf = make_wf(preset, weight, end_at, 20260816, prefix)
    resp = api("/prompt", {"prompt": wf})
    pid = resp.get("prompt_id")
    t0 = time.time()
    while True:
        time.sleep(5)
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
                        print(f"NODE_ERR {prefix}:", m[1].get("exception_message", "")[:180], flush=True)
            else:
                print(f"DONE {prefix} w={weight} end={end_at} ({time.time()-t0:.0f}s)", flush=True)
            break
print("ALL_FINISHED", flush=True)
