#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""第二轮 A/B 测试：参考立绘风格（纯黑背景/低饱和/暖光）· NoobAI vs Neta · 生成留服务器"""
import json, sys, time, urllib.request

HOST = "http://127.0.0.1:18001"
TOKEN = "$2b$12$.TAugRmvKlv5LxFdgOXP4.7mFvhRY2GpvKmr2S8kvAVB9bP/ivSae"

def api(path, payload=None):
    url = HOST + path
    data = json.dumps(payload).encode() if payload else None
    req = urllib.request.Request(url, data=data, method="POST" if payload else "GET")
    req.add_header("Authorization", "Bearer " + TOKEN)
    req.add_header("Content-Type", "application/json")
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.loads(r.read())

def make_wf(ckpt, pos, neg, seed, prefix):
    return {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": ckpt}},
        "2": {"class_type": "EmptyLatentImage", "inputs": {"width": 768, "height": 1024, "batch_size": 1}},
        "3": {"class_type": "CLIPTextEncode", "inputs": {"text": pos, "clip": ["1", 1]}},
        "4": {"class_type": "CLIPTextEncode", "inputs": {"text": neg, "clip": ["1", 1]}},
        "5": {"class_type": "KSampler", "inputs": {"seed": seed, "steps": 28, "cfg": 7.0,
              "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 1.0,
              "model": ["1", 0], "positive": ["3", 0], "negative": ["4", 0], "latent_image": ["2", 0]}},
        "6": {"class_type": "VAEDecode", "inputs": {"samples": ["5", 0], "vae": ["1", 2]}},
        "7": {"class_type": "SaveImage", "inputs": {"filename_prefix": prefix, "images": ["6", 0]}},
    }

POS = ("masterpiece, best quality, highly detailed, sharp focus, clean lineart, "
       "1girl, solo, long hair, blue hair, blue eyes, full body, standing, "
       "looking at viewer, black background, simple background, elegant dress, "
       "thighhighs, gloves, low-key cinematic lighting, warm rim light, "
       "muted desaturated color palette, subtle rim lighting")
NEG = ("worst quality, low quality, blurry, bad anatomy, extra fingers, "
       "watermark, text, logo, signature")

GROUPS = [
    ("NoobAI-XL-v1.1.safetensors", "style3_noobai"),
    ("Neta Art XL 二次元角色 （更新V2）_V2.0.safetensors", "style3_neta"),
]

for ckpt, tag in GROUPS:
    for i, seed in enumerate([12345, 12346, 12347]):
        wf = make_wf(ckpt, POS, NEG, seed, f"{tag}_{i+1}")
        try:
            resp = api("/prompt", {"prompt": wf})
        except Exception as e:
            print(f"SUBMIT_FAIL {tag} seed{seed}: {e}", flush=True)
            continue
        pid = resp.get("prompt_id")
        print(f"SUBMITTED {tag} seed{seed} id={pid}", flush=True)
        while True:
            time.sleep(5)
            try:
                h = api(f"/history/{pid}")
            except Exception as e:
                print(f"POLL_ERR {tag} seed{seed}: {e}", flush=True)
                time.sleep(10)
                continue
            if pid in h:
                for nid, o in h[pid]["outputs"].items():
                    for img in o.get("images", []):
                        print(f"DONE {tag} seed{seed}: {img['filename']}", flush=True)
                break
print("ALL_FINISHED", flush=True)
