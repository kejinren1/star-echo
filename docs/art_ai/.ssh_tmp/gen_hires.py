#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""第四轮：hires fix（latent 2x 二次采样）+ 眼部细节 prompt 强化 · NoobAI"""
import json, sys, time, urllib.request

HOST = "http://127.0.0.1:18001"
TOKEN = "$2b$12$.TAugRmvKlv5LxFdgOXP4.7mFvhRY2GpvKmr2S8kvAVB9bP/ivSae"

def api(path, payload=None):
    url = HOST + path
    data = json.dumps(payload).encode() if payload else None
    req = urllib.request.Request(url, data=data, method="POST" if payload else "GET")
    req.add_header("Authorization", "Bearer " + TOKEN)
    req.add_header("Content-Type", "application/json")
    with urllib.request.urlopen(req, timeout=90) as r:
        return json.loads(r.read())

CKPT = "NoobAI-XL-v1.1.safetensors"
POS = ("masterpiece, best quality, highly detailed, sharp focus, clean lineart, "
       "1girl, solo, long hair, blue hair, blue eyes, full body, standing, "
       "looking at viewer, black background, simple background, elegant dress, "
       "thighhighs, gloves, low-key cinematic lighting, warm rim light, "
       "muted desaturated color palette, "
       "detailed eyes, detailed iris, sparkling eyes, long eyelashes, "
       "detailed face, beautiful face, sharp facial features")
NEG = ("worst quality, low quality, blurry, bad anatomy, extra fingers, "
       "watermark, text, logo, signature, "
       "bad eyes, deformed iris, ugly eyes, poor facial details, "
       "blurry face, distorted face, bad face")

def make_wf(seed, prefix):
    return {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT}},
        "2": {"class_type": "EmptyLatentImage", "inputs": {"width": 768, "height": 1024, "batch_size": 1}},
        "3": {"class_type": "CLIPTextEncode", "inputs": {"text": POS, "clip": ["1", 1]}},
        "4": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG, "clip": ["1", 1]}},
        "5": {"class_type": "KSampler", "inputs": {"seed": seed, "steps": 28, "cfg": 7.0,
              "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 1.0,
              "model": ["1", 0], "positive": ["3", 0], "negative": ["4", 0], "latent_image": ["2", 0]}},
        "6": {"class_type": "LatentUpscale", "inputs": {"samples": ["5", 0], "upscale_method": "nearest-exact", "width": 1536, "height": 2048, "crop": "disabled"}},
        "7": {"class_type": "KSampler", "inputs": {"seed": seed + 1000, "steps": 20, "cfg": 7.0,
              "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 0.4,
              "model": ["1", 0], "positive": ["3", 0], "negative": ["4", 0], "latent_image": ["6", 0]}},
        "8": {"class_type": "VAEDecode", "inputs": {"samples": ["7", 0], "vae": ["1", 2]}},
        "9": {"class_type": "SaveImage", "inputs": {"filename_prefix": prefix, "images": ["8", 0]}},
    }

for i, seed in enumerate([12345, 12346, 12347]):
    prefix = f"style4_hires_{i+1}"
    wf = make_wf(seed, prefix)
    try:
        resp = api("/prompt", {"prompt": wf})
    except Exception as e:
        print(f"SUBMIT_FAIL seed{seed}: {e}", flush=True)
        continue
    pid = resp.get("prompt_id")
    print(f"SUBMITTED {prefix} seed{seed} id={pid}", flush=True)
    while True:
        time.sleep(5)
        try:
            h = api(f"/history/{pid}")
        except Exception:
            time.sleep(10)
            continue
        if pid in h:
            st = h[pid]["status"].get("status_str", "")
            if st == "error":
                for m in h[pid]["status"].get("messages", []):
                    if m[0] == "execution_error":
                        print("NODE_ERR:", m[1].get("exception_message", "")[:200], flush=True)
                break
            for nid, o in h[pid]["outputs"].items():
                for img in o.get("images", []):
                    print(f"DONE {prefix}: {img['filename']}", flush=True)
            break
print("ALL_FINISHED", flush=True)
