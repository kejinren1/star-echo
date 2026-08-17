#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_fixC.py — 回归 txt2img 直出（艾琳+希亚 × 2 方案）
C1: 纯 txt2img（AB路线画质）+ 8头身 + 灰底 + 分组眼 + 材质细节词
C2: C1 + IPAdapter 0.25 低权重(END preset, end_at 0.5) 软一致性
"""
import json, time, urllib.request

HOST = "http://127.0.0.1:18001"
TOKEN = "$2b$12$.TAugRmvKlv5LxFdgOXP4.7mFvhRY2GpvKmr2S8kvAVB9bP/ivSae"
CKPT = "NoobAI-XL-v1.1.safetensors"

STYLE = ("solid pure gray background, flat uniform background, "
         "low-key cinematic lighting, warm rim light, muted desaturated color palette, "
         "with margin, completely inside frame, no cropping")
POSEY = "full body, standing, three-quarter view, body turned slightly to the side"

# 分组眼部词
EYE_F = ("detailed eyes, detailed iris, natural eyelashes, elegant mature face, "
         "detailed face, sharp facial features")

# 材质/细节词（对标 style7 AB 精致感，精简不杂）
QUALITY = ("masterpiece, best quality, highly detailed, sharp focus, clean lineart, "
           "intricate details, rich fabric folds and shadows, detailed material texture, "
           "detailed hair strands with flowing direction, professional illustration")

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
       "simple drawing, childish drawing, stick figure, crayon drawing, flat shading, no shading")


def api(path, payload=None):
    url = HOST + path
    data = json.dumps(payload).encode() if payload else None
    req = urllib.request.Request(url, data=data, method="POST" if payload else "GET")
    req.add_header("Authorization", "Bearer " + TOKEN)
    req.add_header("Content-Type", "application/json")
    with urllib.request.urlopen(req, timeout=120) as r:
        return json.loads(r.read())


def make_wf(use_ipad, key, feat, seed, prefix):
    pos = f"{QUALITY}, {feat}, {POSEY}, {STYLE}, {EYE_F}"
    n = 1
    wf = {}
    if use_ipad:
        wf["1"] = {"class_type": "LoadImage", "inputs": {"image": f"refs_768/{key}_768.png"}}
        wf["2"] = {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT}}
        wf["3"] = {"class_type": "easy ipadapterApply", "inputs": {
            "model": ["2", 0], "image": ["1", 0],
            "preset": "STANDARD (medium strength)", "lora_strength": 0.3, "provider": "CUDA",
            "weight": 0.25, "weight_faceidv2": 1.0, "start_at": 0.0, "end_at": 0.5,
            "cache_mode": "all", "use_tiled": False}}
        wf["4"] = {"class_type": "CLIPTextEncode", "inputs": {"text": pos, "clip": ["2", 1]}}
        wf["5"] = {"class_type": "CLIPTextEncode", "inputs": {"text": NEG, "clip": ["2", 1]}}
        wf["6"] = {"class_type": "EmptyLatentImage", "inputs": {"width": 1024, "height": 1536, "batch_size": 1}}
        wf["7"] = {"class_type": "KSampler", "inputs": {"seed": seed, "steps": 32, "cfg": 6.5,
              "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 1.0,
              "model": ["3", 0], "positive": ["4", 0], "negative": ["5", 0], "latent_image": ["6", 0]}}
        wf["8"] = {"class_type": "VAEDecode", "inputs": {"samples": ["7", 0], "vae": ["2", 2]}}
        wf["9"] = {"class_type": "SaveImage", "inputs": {"filename_prefix": prefix, "images": ["8", 0]}}
    else:
        wf["1"] = {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT}}
        wf["2"] = {"class_type": "CLIPTextEncode", "inputs": {"text": pos, "clip": ["1", 1]}}
        wf["3"] = {"class_type": "CLIPTextEncode", "inputs": {"text": NEG, "clip": ["1", 1]}}
        wf["4"] = {"class_type": "EmptyLatentImage", "inputs": {"width": 1024, "height": 1536, "batch_size": 1}}
        wf["5"] = {"class_type": "KSampler", "inputs": {"seed": seed, "steps": 32, "cfg": 6.5,
              "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 1.0,
              "model": ["1", 0], "positive": ["2", 0], "negative": ["3", 0], "latent_image": ["4", 0]}}
        wf["6"] = {"class_type": "VAEDecode", "inputs": {"samples": ["5", 0], "vae": ["1", 2]}}
        wf["7"] = {"class_type": "SaveImage", "inputs": {"filename_prefix": prefix, "images": ["6", 0]}}
    return wf


for key, feat in CHARS.items():
    for c, use_ipad in (("C1", False), ("C2", True)):
        prefix = f"fixC_{key}_{c}"
        wf = make_wf(use_ipad, key, feat, 20260816, prefix)
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
