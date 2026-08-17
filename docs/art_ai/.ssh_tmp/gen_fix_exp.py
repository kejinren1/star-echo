#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_fix_exp.py — 画风成熟度修复实验（艾琳+希亚）
方案A: 段1 img2img 0.75(拉伸底图) → 段2 img2img 0.35(段1输出精修)   [两段式正确链路]
方案B: 段1 img2img 0.75 + IPAdapter低权重0.3(768原图参考) → 补服装还原  [组合方案]
对照: 单段 0.75（上版画质基准）
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
    "elin": ("1girl, petite loli, short stature, deep crimson red long hair, red eyes, "
             "tall classic pointed wizard hat with wide brim, black and red mage robe "
             "with gold flame patterns, long flowing robe reaching to feet, "
             "wide billowing sleeves, small simple wooden wand, black red gold color scheme", "F"),
    "siia": ("1girl, young adult woman, tall slender figure, elegant long legs, "
             "eight head tall, very long elegant legs, slim tall body, "
             "soft long blonde hair, gentle green eyes, "
             "platinum white priestess robe with light trims, healing staff, "
             "white gold green color scheme", "F"),
}
EYE_F = "detailed eyes, detailed iris, natural eyelashes, elegant mature face, fine detailed shading"

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


def wf_twostage(init, pos, neg, seed, prefix):
    return {
        "1": {"class_type": "LoadImage", "inputs": {"image": init}},
        "2": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT}},
        "3": {"class_type": "VAEEncode", "inputs": {"pixels": ["1", 0], "vae": ["2", 2]}},
        "4": {"class_type": "CLIPTextEncode", "inputs": {"text": pos, "clip": ["2", 1]}},
        "5": {"class_type": "CLIPTextEncode", "inputs": {"text": neg, "clip": ["2", 1]}},
        "6": {"class_type": "KSampler", "inputs": {"seed": seed, "steps": 32, "cfg": 6.5,
              "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 0.75,
              "model": ["2", 0], "positive": ["4", 0], "negative": ["5", 0], "latent_image": ["3", 0]}},
        "7": {"class_type": "VAEDecode", "inputs": {"samples": ["6", 0], "vae": ["2", 2]}},
        "8": {"class_type": "VAEEncode", "inputs": {"pixels": ["7", 0], "vae": ["2", 2]}},
        "9": {"class_type": "KSampler", "inputs": {"seed": seed + 1000, "steps": 32, "cfg": 6.5,
              "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 0.35,
              "model": ["2", 0], "positive": ["4", 0], "negative": ["5", 0], "latent_image": ["8", 0]}},
        "10": {"class_type": "VAEDecode", "inputs": {"samples": ["9", 0], "vae": ["2", 2]}},
        "11": {"class_type": "SaveImage", "inputs": {"filename_prefix": prefix, "images": ["10", 0]}},
    }


def wf_single_ipad(init, ref, pos, neg, seed, prefix):
    """img2img 0.75 + IPAdapter 低权重 0.3（参考 768 原图）"""
    return {
        "1": {"class_type": "LoadImage", "inputs": {"image": init}},
        "2": {"class_type": "LoadImage", "inputs": {"image": ref}},
        "3": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT}},
        "4": {"class_type": "easy ipadapterApply", "inputs": {
            "model": ["3", 0], "image": ["2", 0],
            "preset": "PLUS (high strength)", "lora_strength": 0.3, "provider": "CUDA",
            "weight": 0.3, "weight_faceidv2": 1.0, "start_at": 0.0, "end_at": 0.8,
            "cache_mode": "all", "use_tiled": False}},
        "5": {"class_type": "VAEEncode", "inputs": {"pixels": ["1", 0], "vae": ["3", 2]}},
        "6": {"class_type": "CLIPTextEncode", "inputs": {"text": pos, "clip": ["3", 1]}},
        "7": {"class_type": "CLIPTextEncode", "inputs": {"text": neg, "clip": ["3", 1]}},
        "8": {"class_type": "KSampler", "inputs": {"seed": seed, "steps": 32, "cfg": 6.5,
              "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 0.75,
              "model": ["4", 0], "positive": ["6", 0], "negative": ["7", 0], "latent_image": ["5", 0]}},
        "9": {"class_type": "VAEDecode", "inputs": {"samples": ["8", 0], "vae": ["3", 2]}},
        "10": {"class_type": "SaveImage", "inputs": {"filename_prefix": prefix, "images": ["9", 0]}},
    }


TASKS = []
for key, (feat, grp) in CHARS.items():
    eye = EYE_F
    pos = ("masterpiece, best quality, highly detailed, sharp focus, clean lineart, "
           f"{feat}, {POSEY}, {STYLE}, {eye}")
    init = f"init_gray2/{key}_init_gray2.png"
    TASKS.append(("twostage", key, init, None, pos, NEG, 20260816, f"fixA_{key}"))
    TASKS.append(("single_ipad", key, init, f"refs_768/{key}_768.png", pos, NEG, 20260816, f"fixB_{key}"))

for kind, key, init, ref, pos, neg, seed, prefix in TASKS:
    if kind == "twostage":
        wf = wf_twostage(init, pos, neg, seed, prefix)
    else:
        wf = wf_single_ipad(init, ref, pos, neg, seed, prefix)
    try:
        resp = api("/prompt", {"prompt": wf})
    except Exception as e:
        print(f"SUBMIT_FAIL {prefix}: {e}", flush=True)
        continue
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
                print(f"DONE {prefix} ({time.time()-t0:.0f}s)", flush=True)
            break
print("ALL_FINISHED", flush=True)
