#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_b08_smooth.py — BOSS⑧ 锯齿打磨：放大 1152 + img2img 平滑"""
import json, time, urllib.request

HOST = "http://127.0.0.1:18001"
TOKEN = "$2b$12$.TAugRmvKlv5LxFdgOXP4.7mFvhRY2GpvKmr2S8kvAVB9bP/ivSae"
CKPT = "NoobAI-XL-v1.1.safetensors"

POS = ("masterpiece, best quality, highly detailed, sharp focus, clean lineart, "
       "intricate details, professional illustration, "
       "ornate ancient hand mirror with twisted branch-like golden frame, "
       "gnarled wooden branch frame, interwoven branch structure, "
       "structure clearly defined branches, distinct branch segments, "
       "a prominent eye shape in the center of the mirror, bold clear eye, "
       "intricate carvings, antique mirror, "
       "dark mysterious atmosphere, cinematic lighting")

NEG = ("worst quality, low quality, blurry, watermark, text, logo, signature, "
       "flat colors, simple drawing, childish drawing, "
       "person, human, character, girl, boy, face, portrait, "
       "plain round frame, simple circle frame, featureless mirror, "
       "jagged edges, pixelated, mosaic, aliasing")


def api(path, payload=None):
    url = HOST + path
    data = json.dumps(payload).encode() if payload else None
    req = urllib.request.Request(url, data=data, method="POST" if payload else "GET")
    req.add_header("Authorization", "Bearer " + TOKEN)
    req.add_header("Content-Type", "application/json")
    with urllib.request.urlopen(req, timeout=120) as r:
        return json.loads(r.read())


def main():
    seed_base = 20262216
    total = 0
    for n in range(6):
        seed = seed_base + n
        prefix = f"b08_sm_{n+1}"
        wf = {
            "1": {"class_type": "LoadImage", "inputs": {"image": "refs_768/b08_768.png"}},
            "2": {"class_type": "ImageScale", "inputs": {"image": ["1", 0], "upscale_method": "lanczos", "width": 1152, "height": 1152, "crop": "disabled"}},
            "3": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT}},
            "4": {"class_type": "VAEEncode", "inputs": {"pixels": ["2", 0], "vae": ["3", 2]}},
            "5": {"class_type": "CLIPTextEncode", "inputs": {"text": POS, "clip": ["3", 1]}},
            "6": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG, "clip": ["3", 1]}},
            "7": {"class_type": "KSampler", "inputs": {"seed": seed, "steps": 34, "cfg": 7.0,
                  "sampler_name": "dpmpp_2m_sde", "scheduler": "karras", "denoise": 0.5,
                  "model": ["3", 0], "positive": ["5", 0], "negative": ["6", 0], "latent_image": ["4", 0]}},
            "8": {"class_type": "VAEDecode", "inputs": {"samples": ["7", 0], "vae": ["3", 2]}},
            "9": {"class_type": "SaveImage", "inputs": {"filename_prefix": prefix, "images": ["8", 0]}},
        }
        try:
            resp = api("/prompt", {"prompt": wf})
        except Exception as e:
            print(f"SUBMIT_FAIL {prefix}: {e}", flush=True)
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
                st = h[pid]["status"].get("status_str", "")
                if st == "error":
                    for m in h[pid]["status"].get("messages", []):
                        if m[0] == "execution_error":
                            print("NODE_ERR:", m[1].get("exception_message", "")[:150], flush=True)
                    break
                for nid, o in h[pid]["outputs"].items():
                    for img in o.get("images", []):
                        print(f"DONE {prefix} seed{seed}", flush=True)
                        total += 1
                break
    print(f"ALL_FINISHED total={total}", flush=True)


if __name__ == "__main__":
    main()
