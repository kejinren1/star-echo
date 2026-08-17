#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_ratio_test.py — 头身比映射验证（siia/lain/noah 单段 0.75 + 7头身强制词）
像素画 4 头身容忍 → 立绘 7 头身：prompt 强指定高挑成年比例，负面锁大头小身体
"""
import json, time, urllib.request

HOST = "http://127.0.0.1:18001"
TOKEN = "$2b$12$.TAugRmvKlv5LxFdgOXP4.7mFvhRY2GpvKmr2S8kvAVB9bP/ivSae"
CKPT = "NoobAI-XL-v1.1.safetensors"

STYLE = ("solid pure gray background, flat uniform background, "
         "low-key cinematic lighting, warm rim light, muted desaturated color palette, "
         "with margin, completely inside frame, no cropping")
POSEY = "full body, standing, three-quarter view, body turned slightly to the side"

CHARS = {
    "siia": ("1girl, young adult woman, tall slender figure, elegant long legs, "
             "seven head tall, adult body proportions, "
             "soft long blonde hair, gentle green eyes, "
             "platinum white priestess robe with light trims, healing staff, "
             "white gold green color scheme", "F"),
    "lain": ("1boy, adult male warrior, tall masculine body, seven head tall, "
             "broad shoulders, rugged mature face, white hair, sharp blue eyes, "
             "dark battle-worn mottled leather and steel armor, scratches and dents, "
             "old worn cloak, holding a longsword at his side, "
             "deep gray black dark steel color scheme", "M"),
    "noah": ("1girl, young adult woman, tall slender figure, elegant long legs, "
             "seven head tall, adult body proportions, "
             "silver blue short hair, blue eyes, "
             "vintage victorian scholarly outfit, dark blue tailcoat with rune embroidery, "
             "white shirt, leather vest, striped trousers, high heel boots, "
             "vintage round brass goggles with rivets and leather strap, "
             "pocket watch chain, small wrench, dark blue brass white color scheme", "F"),
}

EYE_F = "detailed eyes, detailed iris, natural eyelashes, elegant mature face"
EYE_M = "detailed eyes, detailed iris, mature masculine face, defined jawline, sharp focused gaze"

NEG = ("worst quality, low quality, blurry, bad anatomy, extra fingers, watermark, text, logo, signature, "
       "bad eyes, deformed iris, ugly eyes, poor facial details, blurry face, distorted face, bad face, "
       "cluttered outfit, messy clothes, tangled hair, noisy background, "
       "effects, magic aura, glow, particles, floating objects, "
       "background scene, environment, scenery, gradient background, "
       "out of frame, cropped figure, pixel art, pixelated, mosaic, flat colors, "
       "large head, small body, short legs, tiny body, oversized head, "
       "chibi, loli, kid, childlike, baby face, petite, short stature, midget")


def api(path, payload=None):
    url = HOST + path
    data = json.dumps(payload).encode() if payload else None
    req = urllib.request.Request(url, data=data, method="POST" if payload else "GET")
    req.add_header("Authorization", "Bearer " + TOKEN)
    req.add_header("Content-Type", "application/json")
    with urllib.request.urlopen(req, timeout=90) as r:
        return json.loads(r.read())


for key, (feat, grp) in CHARS.items():
    eye = EYE_F if grp == "F" else EYE_M
    pos = ("masterpiece, best quality, highly detailed, sharp focus, clean lineart, "
           f"{feat}, {POSEY}, {STYLE}, {eye}")
    neg = NEG + (", long eyelashes, feminine face, pretty boy" if grp == "M" else "")
    init = f"init_gray/{key}_init_gray.png"
    prefix = f"ratio_{key}"
    wf = {
        "1": {"class_type": "LoadImage", "inputs": {"image": init}},
        "2": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT}},
        "3": {"class_type": "VAEEncode", "inputs": {"pixels": ["1", 0], "vae": ["2", 2]}},
        "4": {"class_type": "CLIPTextEncode", "inputs": {"text": pos, "clip": ["2", 1]}},
        "5": {"class_type": "CLIPTextEncode", "inputs": {"text": neg, "clip": ["2", 1]}},
        "6": {"class_type": "KSampler", "inputs": {"seed": 20260816, "steps": 32, "cfg": 6.5,
              "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 0.75,
              "model": ["2", 0], "positive": ["4", 0], "negative": ["5", 0], "latent_image": ["3", 0]}},
        "7": {"class_type": "VAEDecode", "inputs": {"samples": ["6", 0], "vae": ["2", 2]}},
        "8": {"class_type": "SaveImage", "inputs": {"filename_prefix": prefix, "images": ["7", 0]}},
    }
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
                print(f"DONE {prefix} ({time.time()-t0:.0f}s)", flush=True)
            break
print("ALL_FINISHED", flush=True)
