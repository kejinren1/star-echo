#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_v16_batch.py — v16 狼重画×5：病态瘦拉回 + 结构保留 + 禁可爱
v14 瘦但崩坏 / v15 结构好但不瘦 → 合并：emaciated 强瘦词 + well-proportioned 结构词
"""
import json, time, urllib.request

HOST = "http://127.0.0.1:18001"
TOKEN = "$2b$12$.TAugRmvKlv5LxFdgOXP4.7mFvhRY2GpvKmr2S8kvAVB9bP/ivSae"
CKPT = "aziibpixelmix_v10.safetensors"

def api(path, payload=None):
    url = HOST + path
    data = json.dumps(payload).encode() if payload else None
    req = urllib.request.Request(url, data=data, method="POST" if payload else "GET")
    req.add_header("Authorization", "Bearer " + TOKEN)
    req.add_header("Content-Type", "application/json")
    with urllib.request.urlopen(req, timeout=90) as r:
        return json.loads(r.read())

BG = (", crisp pixel art sprite, bold clean palette, clean silhouette, highly detailed, fine pixel shading, "
      "full body visible with margin, completely inside frame, no cropping, safe margins, "
      "pure white background, solid flat uniform background, no gradient, no ground shadow, "
      "no rim light, no vignette, no floor, no decorations, no effects, no magic, no glow, "
      "no particles, no magic aura, no background objects")
NEG = ("blurry, low quality, ugly, deformed, broken anatomy, bad proportions, disproportionate, "
       "stretched limbs, elongated body, broken joints, dislocated joints, extra limbs, wrong leg joints, "
       "humanoid, anthropomorphic, bipedal, werewolf humanoid, standing upright, half-man, "
       "healthy muscular, plump, well-fed, thick body, bulky, "
       "cute, adorable, fluffy, round, chubby, puppy, puppy-like, soft, plump, cartoonish, "
       "effects, particles, magic, aura, glow, background decoration, background objects, "
       "dark background, colored background, red background, gradient background, "
       "ground shadow, vignette, floor, out of frame, cropped figure, multiple characters, text, watermark, "
       "modern clothes, machinery, gun, rifle, exposed torso, nude")

WOLF = ("feral wolf beast, pure quadrupedal animal form, natural wolf anatomy, well-proportioned body, "
        "not anthropomorphic, not bipedal, "
        "sickly emaciated body, skeletal thin frame, visible ribs, sunken flanks, "
        "haggard starving look, wasting away, gaunt hollow chest, "
        "natural length legs with correct joints, proper stance on all fours, "
        "purple-black fur color scheme, long prominent tail raised, "
        "blood-red eyes, ferocious vicious snarling expression, bared fangs, "
        "fresh wounds and scars on body, wild feral dark fantasy beast")

def make_wf(desc, seed, prefix):
    text = desc + BG
    return {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT}},
        "2": {"class_type": "CLIPTextEncode", "inputs": {"text": text, "clip": ["1", 1]}},
        "3": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG, "clip": ["1", 1]}},
        "7": {"class_type": "EmptyLatentImage", "inputs": {"width": 768, "height": 768, "batch_size": 1}},
        "8": {"class_type": "KSampler", "inputs": {"seed": seed, "steps": 32, "cfg": 6.5,
              "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 1.0,
              "model": ["1", 0], "positive": ["2", 0], "negative": ["3", 0], "latent_image": ["7", 0]}},
        "9": {"class_type": "VAEDecode", "inputs": {"samples": ["8", 0], "vae": ["1", 2]}},
        "10": {"class_type": "SaveImage", "inputs": {"filename_prefix": prefix, "images": ["9", 0]}},
    }

def main():
    tasks = []
    seed = 20261601
    for k in range(5):
        tasks.append((f"v16_wolf_{k+1}", WOLF, seed + k))
    print(f"共 {len(tasks)} 张", flush=True)
    for prefix, desc, seed in tasks:
        wf = make_wf(desc, seed, prefix)
        try:
            resp = api("/prompt", {"prompt": wf})
        except Exception as e:
            print(f"FAIL {prefix}: {e}", flush=True)
            continue
        pid = resp.get("prompt_id")
        print(f"SUBMITTED {prefix}", flush=True)
        while True:
            time.sleep(3)
            try:
                h = api(f"/history/{pid}")
            except Exception:
                time.sleep(7)
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
                        print(f"DONE {prefix}: {img['filename']}", flush=True)
                break
    print("ALL_FINISHED", flush=True)

if __name__ == "__main__":
    main()
