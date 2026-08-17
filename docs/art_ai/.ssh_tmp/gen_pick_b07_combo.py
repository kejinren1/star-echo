#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_pick_b07_combo.py — 女神 下g2+上rest3_b07_1 融合重绘"""
import json, time, urllib.request

HOST = "http://127.0.0.1:18001"
TOKEN = "$2b$12$.TAugRmvKlv5LxFdgOXP4.7mFvhRY2GpvKmr2S8kvAVB9bP/ivSae"
CKPT = "NoobAI-XL-v1.1.safetensors"

POS = ("masterpiece, best quality, highly detailed, sharp focus, clean lineart, "
       "intricate details, rich fabric folds and shadows, detailed material texture, "
       "detailed hair strands with flowing direction, professional illustration, "
       "1girl, tall slender goddess, very long silky black hair, pale skin, "
       "black sleeveless dress with rich fabric texture, bare shoulders, no horns, "
       "intricate dress details, elegant shading, refined fabric folds, "
       "detailed hair strands with flowing direction, hair light reflection, "
       "cinematic lighting, luminous highlights, "
       "hollow void in her abdomen, cosmic emptiness, mysterious divine presence, "
       "full body, standing, three-quarter view, natural relaxed standing pose, "
       "both feet firmly planted on the ground, "
       "solid pure gray background, flat uniform background, "
       "low-key cinematic lighting, warm rim light, muted desaturated color palette, "
       "with margin, completely inside frame, no cropping, "
       "detailed eyes, detailed iris, elegant goddess face, refined features")
NEG = ("brown vest, layered vest, multiple vests, double vest, vest over vest, two vests, "
       "coat, jacket, outerwear, trench coat, open coat, long coat, shorts, short pants, hotpants, "
       "exposed skin, nude, scantily clad, skimpy outfit, revealing clothes, lewd, "
       "bare legs, exposed thighs, thigh exposure, skirt showing thighs, no pants, "
       "dual wielding, two swords, armored skirt, plate skirt, heavy armor skirt, "
       "blue armored skirt, blue metal skirt, armor plates at waist, metal hip armor, "
       "fauld, tassets, metal skirt armor, chainmail skirt, hip plate armor, "
       "metal belt armor, armored belt, "
       "elbow armor, forearm gauntlets, full sleeve armor, "
       "pale skin, pale white skin, albino, ghostly pale, very light skin, "
       "muscular body, bulky body, huge shoulders, bodybuilder, "
       "cape, cloak, mantle, long cape, flowing cape, ornate sword, decorative rapier, "
       "gold trim, gold edges, golden decorations, ornate trim, gilded armor, embroidered gold, "
       "dark blue armor, navy blue armor, deep blue armor, vivid blue armor, "
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
    seed_base = 20262416
    total = 0
    for n in range(6):
        seed = seed_base + n
        prefix = f"b07R3_{n+1}"
        wf = {
            "1": {"class_type": "LoadImage", "inputs": {"image": "micro3/b07_r2_3.png"}},
            "2": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT}},
            "3": {"class_type": "VAEEncode", "inputs": {"pixels": ["1", 0], "vae": ["2", 2]}},
            "4": {"class_type": "CLIPTextEncode", "inputs": {"text": POS, "clip": ["2", 1]}},
            "5": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG, "clip": ["2", 1]}},
            "6": {"class_type": "KSampler", "inputs": {"seed": seed, "steps": 34, "cfg": 7.0,
                  "sampler_name": "dpmpp_2m_sde", "scheduler": "karras", "denoise": 0.5,
                  "model": ["2", 0], "positive": ["4", 0], "negative": ["5", 0], "latent_image": ["3", 0]}},
            "7": {"class_type": "VAEDecode", "inputs": {"samples": ["6", 0], "vae": ["2", 2]}},
            "8": {"class_type": "SaveImage", "inputs": {"filename_prefix": prefix, "images": ["7", 0]}},
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
