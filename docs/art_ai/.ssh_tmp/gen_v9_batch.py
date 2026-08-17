#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_v9_batch.py — v9 修正批量（用户 08-16 00:08 反馈）
艾琳强化魔法师特征(高尖帽+长袍) / 诺亚去蓝色球体(删水晶核心+禁 orbs) / Boss4 白+蓝金副色精细露脸 / Boss5 长而突出尾巴
莱恩 vB 已定稿（本批不跑）
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

BG = (", crisp pixel art sprite, bold clean palette, clean silhouette, "
      "body turned slightly to the side, three-quarter view, natural relaxed stance, "
      "full body visible head to toe with margin, completely inside frame, no cropping, safe margins, "
      "pure white background, solid flat uniform background, no gradient, no ground shadow, "
      "no rim light, no vignette, no floor, no decorations, no effects, no magic, no glow, "
      "no particles, no magic aura, no background objects")
NEG = ("blurry, low quality, stiff pose, symmetrical pose, half body, portrait, close-up, crop, "
       "bust, headshot, ugly, deformed, effects, particles, magic, aura, glow, "
       "background decoration, background objects, floating gears, gears in background, "
       "floating rings, rings in background, circular objects in background, machinery background, "
       "floating orbs, glowing orbs, spheres, blue orbs, crystal orbs in background, "
       "dark background, colored background, red background, gradient background, "
       "ground shadow, vignette, floor, out of frame, cropped figure, cropped hat, hat out of frame, "
       "multiple figures, small figures, tiny people, companions, multiple characters, text, watermark, "
       "familiar, spirit companion, fairy, floating creature, small creature, pet, "
       "modern clothes, jeans, t-shirt, hoodie, military uniform, modern machinery, gun, rifle, "
       "modern glasses, eyeglasses, thin frame glasses, exposed torso, bare chest, shirtless, nude")

ELIN_MAGE = ("petite young girl, loli, short, tiny frame, small stature, "
             "long crimson red hair, red eyes, "
             "tall classic pointed wizard hat with wide brim, completely inside frame with headroom above, "
             "long flowing black mage robe with crimson and gold flame embroidery, reaching to feet, "
             "wide billowing sleeves, classic wizard silhouette, holding a simple wooden staff, fire mage")

NOAH_MAGICPUNK = ("short silver blue hair, blue eyes, "
                  "rune-engraved vintage brass goggles with leather strap on forehead, "
                  "magicpunk engineer, arcane dark blue coat etched with rune patterns, "
                  "brass clockwork shoulder ornaments, leather tool belt with rune tools, "
                  "holding a wrench, alone, solo, no companions, fantasy magicpunk engineer")

def make_wf(desc, seed, prefix):
    text = desc + BG
    return {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT}},
        "2": {"class_type": "CLIPTextEncode", "inputs": {"text": text, "clip": ["1", 1]}},
        "3": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG, "clip": ["1", 1]}},
        "7": {"class_type": "EmptyLatentImage", "inputs": {"width": 768, "height": 768, "batch_size": 1}},
        "8": {"class_type": "KSampler", "inputs": {"seed": seed, "steps": 28, "cfg": 6.5,
              "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 1.0,
              "model": ["1", 0], "positive": ["2", 0], "negative": ["3", 0], "latent_image": ["7", 0]}},
        "9": {"class_type": "VAEDecode", "inputs": {"samples": ["8", 0], "vae": ["1", 2]}},
        "10": {"class_type": "SaveImage", "inputs": {"filename_prefix": prefix, "images": ["9", 0]}},
    }

def main():
    tasks = []
    seed = 20261201
    for k in range(3):
        tasks.append((f"v9_elin_mage_{k+1}", ELIN_MAGE, seed + k))
    BODY = [
        ("mature", "mature woman, adult woman, tall, long legs, voluptuous curvy figure, large breasts, single figure, solo"),
        ("youth", "young woman, medium breasts, youthful slim figure, moderate height, single figure, solo"),
        ("loli", "petite young girl, loli, short, tiny frame, youthful, single figure, solo"),
    ]
    for bi, (bkey, btag) in enumerate(BODY):
        tasks.append((f"v9_noah_{bkey}", f"{btag}, {NOAH_MAGICPUNK}", seed + 20 + bi * 10))
    tasks.append(("v9_boss_04_light_knight",
                  "pristine white full plate armor, white as primary color, blue and gold as secondary accents, "
                  "intricate fine armor engraving, helmet off, bare head, noble heroic face, "
                  "golden trim, blue cape, holy longsword, righteous protagonist of light",
                  seed + 100))
    tasks.append(("v9_boss_05_wolf",
                  "quadrupedal werewolf beast on all fours, lean slender elongated body, "
                  "long prominent thick tail raised and curved, long tail clearly visible, "
                  "stretched slender limbs, twisted distorted infected form, wolf head, feral, dark fur",
                  seed + 107))

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
