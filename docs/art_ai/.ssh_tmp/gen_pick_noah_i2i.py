#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_pick_noah_i2i.py — 诺亚 img2img 治本版（继承定稿形态，防裸腿）
底图 init_gray2（拉伸灰底）→ img2img 0.75 + IPAdapter 0.3 + QUALITY + 8头身 + 长裤锁定
"""
import json, time, urllib.request

HOST = "http://127.0.0.1:18001"
TOKEN = "$2b$12$.TAugRmvKlv5LxFdgOXP4.7mFvhRY2GpvKmr2S8kvAVB9bP/ivSae"
CKPT = "NoobAI-XL-v1.1.safetensors"

POS = ("masterpiece, best quality, highly detailed, sharp focus, clean lineart, "
       "intricate details, rich fabric folds and shadows, detailed material texture, "
       "detailed hair strands with flowing direction, professional illustration, "
       "rich color depth, refined shading, cinematic lighting, elegant detail rendering, "
       "1girl, teenage girl, youthful young woman, between girl and young woman, "
       "slim slender delicate figure, seven head tall, long legs, "
       "silver blue short hair, blue eyes, "
       "a single long open-front blue vest with gold trims, "
       "only one vest, open vest revealing white shirt, "
       "single vest only, no layered vests, "
       "wearing full-length striped trousers, long striped pants, "
       "legs fully covered by long trousers, no bare legs, "
       "bowtie, puffy sleeves, high heel boots, "
       "vintage round brass goggles with rivets and leather strap, blue vest only, "
       "pocket watch chain, blue gold white color scheme, "
       "full body, standing, three-quarter view, body turned slightly to the side, "
       "solid pure gray background, flat uniform background, "
       "low-key cinematic lighting, warm rim light, muted desaturated color palette, "
       "with margin, completely inside frame, no cropping, "
       "detailed eyes, detailed iris, natural eyelashes, youthful face, fresh soft features, detailed face")

NEG = ("brown vest, layered vest, multiple vests, double vest, vest over vest, two vests, "
       "coat, jacket, outerwear, trench coat, open coat, long coat, shorts, short pants, hotpants, "
       "exposed skin, nude, scantily clad, skimpy outfit, revealing clothes, lewd, "
       "bare legs, exposed thighs, thigh exposure, skirt showing thighs, no pants, "
       "worst quality, low quality, blurry, bad anatomy, extra fingers, watermark, text, logo, signature, "
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


def main():
    seed_base = 20261616
    total = 0
    for n in range(6):
        seed = seed_base + n
        prefix = f"pick_noahI2I7_{n+1}"
        wf = {
            "1": {"class_type": "LoadImage", "inputs": {"image": "init_gray2/noah_init_gray2.png"}},
            "2": {"class_type": "LoadImage", "inputs": {"image": "refs_768/noah_768.png"}},
            "3": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT}},
            "4": {"class_type": "easy ipadapterApply", "inputs": {
                "model": ["3", 0], "image": ["2", 0],
                "preset": "STANDARD (medium strength)", "lora_strength": 0.3, "provider": "CUDA",
                "weight": 0.3, "weight_faceidv2": 1.0, "start_at": 0.0, "end_at": 0.7,
                "cache_mode": "all", "use_tiled": False}},
            "5": {"class_type": "VAEEncode", "inputs": {"pixels": ["1", 0], "vae": ["3", 2]}},
            "6": {"class_type": "CLIPTextEncode", "inputs": {"text": POS, "clip": ["3", 1]}},
            "7": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG, "clip": ["3", 1]}},
            "8": {"class_type": "KSampler", "inputs": {"seed": seed, "steps": 32, "cfg": 6.5,
                  "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 0.75,
                  "model": ["4", 0], "positive": ["6", 0], "negative": ["7", 0], "latent_image": ["5", 0]}},
            "9": {"class_type": "VAEDecode", "inputs": {"samples": ["8", 0], "vae": ["3", 2]}},
            "10": {"class_type": "SaveImage", "inputs": {"filename_prefix": prefix, "images": ["9", 0]}},
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
