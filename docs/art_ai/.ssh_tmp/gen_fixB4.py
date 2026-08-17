#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_fixB4.py — 段2 全图放大精修版（艾琳+希亚）
段1: 方案B（img2img 0.75 + IPAdapter 0.3, CFG6.5/32步）
段2: 1.25x LANCZOS 放大(1280x1920) → img2img denoise 0.3 + 眼睛/发丝/复杂度词
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
         "detailed face, sharp facial features, fine facial details")

# 段2 细节强化词（眼睛/发丝/复杂度）
DETAIL = ("masterpiece, best quality, highly detailed, sharp focus, clean lineart, "
          "(detailed iris:1.15), (iris texture:1.1), (eye highlights:1.1), "
          "detailed hair strands, flowing hair strands, intricate hair texture, "
          "(detailed face:1.15), sharp facial features, "
          "intricate ornate detail, rich fabric texture, elaborate costume detail, "
          "professional illustration, refined rendering")

CHARS = {
    "elin": ("1girl, petite loli, short stature, deep crimson red long hair, red eyes, "
             "tall classic pointed wizard hat with wide brim, black and red mage robe "
             "with gold flame patterns, long flowing robe reaching to feet, "
             "wide billowing sleeves, small simple wooden wand, black red gold color scheme"),
    "siia": ("1girl, young adult woman, tall slender figure, elegant long legs, "
             "eight head tall, very long elegant legs, slim tall body, "
             "soft long blonde hair, gentle green eyes, "
             "platinum white priestess robe with light trims, healing staff, "
             "white gold green color scheme"),
}

NEG = ("worst quality, low quality, blurry, bad anatomy, extra fingers, watermark, text, logo, signature, "
       "bad eyes, deformed iris, ugly eyes, poor facial details, blurry face, distorted face, bad face, "
       "cluttered outfit, messy clothes, tangled hair, noisy background, "
       "effects, magic aura, glow, particles, floating objects, "
       "background scene, environment, scenery, gradient background, "
       "out of frame, cropped figure, pixel art, pixelated, mosaic, flat colors, "
       "large head, small body, short legs, tiny body, oversized head, "
       "chibi, loli, kid, childlike, baby face, petite, short stature, midget, "
       "plain face, featureless face, distorted face, warped face, deformed face, "
       "simple drawing, childish drawing, stick figure, crayon drawing")


def api(path, payload=None):
    url = HOST + path
    data = json.dumps(payload).encode() if payload else None
    req = urllib.request.Request(url, data=data, method="POST" if payload else "GET")
    req.add_header("Authorization", "Bearer " + TOKEN)
    req.add_header("Content-Type", "application/json")
    with urllib.request.urlopen(req, timeout=120) as r:
        return json.loads(r.read())


for key, feat in CHARS.items():
    pos = ("masterpiece, best quality, highly detailed, sharp focus, clean lineart, "
           f"{feat}, {POSEY}, {STYLE}, {EYE_F}")
    prefix = f"fixB4_{key}"
    wf = {
        "1": {"class_type": "LoadImage", "inputs": {"image": f"init_gray2/{key}_init_gray2.png"}},
        "2": {"class_type": "LoadImage", "inputs": {"image": f"refs_768/{key}_768.png"}},
        "3": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT}},
        "4": {"class_type": "easy ipadapterApply", "inputs": {
            "model": ["3", 0], "image": ["2", 0],
            "preset": "PLUS (high strength)", "lora_strength": 0.3, "provider": "CUDA",
            "weight": 0.3, "weight_faceidv2": 1.0, "start_at": 0.0, "end_at": 0.8,
            "cache_mode": "all", "use_tiled": False}},
        "5": {"class_type": "VAEEncode", "inputs": {"pixels": ["1", 0], "vae": ["3", 2]}},
        "6": {"class_type": "CLIPTextEncode", "inputs": {"text": pos, "clip": ["3", 1]}},
        "7": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG, "clip": ["3", 1]}},
        "8": {"class_type": "KSampler", "inputs": {"seed": 20260816, "steps": 32, "cfg": 6.5,
              "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 0.75,
              "model": ["4", 0], "positive": ["6", 0], "negative": ["7", 0], "latent_image": ["5", 0]}},
        "9": {"class_type": "VAEDecode", "inputs": {"samples": ["8", 0], "vae": ["3", 2]}},
        "10": {"class_type": "ImageScale", "inputs": {"image": ["9", 0], "upscale_method": "lanczos",
               "width": 1280, "height": 1920, "crop": "disabled"}},
        "11": {"class_type": "VAEEncode", "inputs": {"pixels": ["10", 0], "vae": ["3", 2]}},
        "12": {"class_type": "CLIPTextEncode", "inputs": {"text": DETAIL, "clip": ["3", 1]}},
        "13": {"class_type": "KSampler", "inputs": {"seed": 20260916, "steps": 30, "cfg": 6.0,
              "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 0.3,
              "model": ["4", 0], "positive": ["12", 0], "negative": ["7", 0], "latent_image": ["11", 0]}},
        "14": {"class_type": "VAEDecode", "inputs": {"samples": ["13", 0], "vae": ["3", 2]}},
        "15": {"class_type": "SaveImage", "inputs": {"filename_prefix": prefix, "images": ["14", 0]}},
    }
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
                        print(f"NODE_ERR {prefix}:", m[1].get("exception_message", "")[:200], flush=True)
            else:
                print(f"DONE {prefix} ({time.time()-t0:.0f}s)", flush=True)
            break
print("ALL_FINISHED", flush=True)
