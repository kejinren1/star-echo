#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_portraits_prod.py — 12 角色立绘量产（2026-08-16 02:15 定稿管线）
管线：768原图 floodfill 抠白 → 灰底(#808080)竖版化 1024x1536 → img2img denoise 0.75
配置：NoobAI-XL-v1.1 · 32步 CFG6.5 dpmpp_2m+karras · 灰底纯色背景词
每角色 2 张变体 seed
"""
import json, time, urllib.request

HOST = "http://127.0.0.1:18001"
TOKEN = "$2b$12$.TAugRmvKlv5LxFdgOXP4.7mFvhRY2GpvKmr2S8kvAVB9bP/ivSae"
CKPT = "NoobAI-XL-v1.1.safetensors"

STYLE = ("solid pure gray background, flat uniform background, "
         "low-key cinematic lighting, warm rim light, muted desaturated color palette, "
         "with margin, completely inside frame, no cropping")
POSEY = "full body, standing, three-quarter view, body turned slightly to the side"
# 按角色分组眼部词（2026-08-16 02:28 修复：去掉通用长睫毛/闪亮眼——狗都长睫毛违和）
EYE_FEMALE = "detailed eyes, detailed iris, natural eyelashes, elegant refined face"
EYE_MALE = ("detailed eyes, detailed iris, mature masculine face, "
            "defined jawline, sharp focused gaze")
EYE_BEAST = "fierce menacing eyes, sharp detailed iris, ferocious gaze, detailed fur texture"
EYE_ITEM = "detailed ominous eye, sharp detailed iris, fine gold frame detail"

GROUPS = {"elin": "F", "noah": "F", "siia": "F", "b01": "F", "b07": "F",
          "lain": "M", "b02": "M", "b03": "M", "b04": "M",
          "b05": "B", "b06": "B", "b08": "I"}

CHARS = {
    "elin": ("1girl, petite loli, short stature, deep crimson red long hair, red eyes, "
             "tall classic pointed wizard hat with wide brim, black and red mage robe "
             "with gold flame patterns, long flowing robe reaching to feet, "
             "wide billowing sleeves, small simple wooden wand, black red gold color scheme"),
    "noah": ("1girl, young adult woman, silver blue short hair, blue eyes, "
             "vintage victorian scholarly outfit, dark blue tailcoat with rune embroidery, "
             "white shirt, leather vest, striped trousers, high heel boots, "
             "vintage round brass goggles with rivets and leather strap, "
             "pocket watch chain, small wrench, dark blue brass white color scheme"),
    "lain": ("1boy, adult male warrior, white hair, sharp blue eyes, "
             "dark battle-worn mottled leather and steel armor, scratches and dents, "
             "old worn cloak, holding a longsword at his side, "
             "deep gray black dark steel color scheme"),
    "siia": ("1girl, young adult woman, soft long blonde hair, gentle green eyes, "
             "platinum white priestess robe with light trims, healing staff, "
             "white gold green color scheme"),
    "b01": ("1girl, dark skin, muscular toned female warrior, "
            "tight battle armor, seductive combat outfit, curved scimitar, "
            "black red silver color scheme"),
    "b02": ("1boy, extremely emaciated skeletal thin male mage, "
            "sunken hollow eyes, gaunt haggard face, tattered black robe, "
            "bone staff, dark purple black color scheme"),
    "b03": ("1boy, gang leader, ornate wild fur coat, gold chains, "
            "confident smug smirk, flamboyant boss attire, "
            "dark red gold black color scheme"),
    "b04": ("1boy, young adult male knight, bare head, visible noble face, "
            "white armor main color, blue and gold trims, "
            "intricate fine armor engraving, holy sword, "
            "righteous protagonist of light, white blue gold color scheme"),
    "b05": ("feral wolf beast, pure quadrupedal animal, all fours, "
            "purple black fur, emaciated skeletal thin body, visible ribs, "
            "crimson red eyes, long prominent tail, wounds and scars, "
            "ferocious snarling"),
    "b06": ("1boy, minotaur warrior, huge curved horns, bull head, "
            "leather armor with fur, wielding heavy battle axe, "
            "dark brown bronze color scheme"),
    "b07": ("1girl, tall slender goddess, very long black hair, pale skin, "
            "black elegant dress, hollow void in her abdomen, "
            "cosmic emptiness, mysterious divine presence"),
    "b08": ("ornate ancient hand mirror, antique elaborate golden frame, "
            "intricate carvings, ominous, an eye peering from within the mirror, "
            "dark mysterious atmosphere"),
}

NEG = ("worst quality, low quality, blurry, bad anatomy, extra fingers, watermark, text, logo, signature, "
       "bad eyes, deformed iris, ugly eyes, poor facial details, blurry face, distorted face, bad face, "
       "cluttered outfit, messy clothes, tangled hair, noisy background, "
       "effects, magic aura, glow, particles, floating objects, "
       "background scene, environment, scenery, gradient background, "
       "out of frame, cropped figure, pixel art, pixelated, mosaic, flat colors")
NEG_ANIMAL = NEG + ", humanoid, anthropomorphic, bipedal, werewolf humanoid, cute, fluffy, puppy"
NEG_ITEM = NEG + ", person, human, character, girl, boy, face, portrait"


def api(path, payload=None):
    url = HOST + path
    data = json.dumps(payload).encode() if payload else None
    req = urllib.request.Request(url, data=data, method="POST" if payload else "GET")
    req.add_header("Authorization", "Bearer " + TOKEN)
    req.add_header("Content-Type", "application/json")
    with urllib.request.urlopen(req, timeout=90) as r:
        return json.loads(r.read())


def main():
    seed_base = 20260816
    total = 0
    for i, (key, feat) in enumerate(CHARS.items()):
        if key == "b05":
            pose = "full body quadrupedal animal, natural four-leg stance, all fours"
        elif key == "b08":
            pose = "a single ornate mirror centered, vertical composition"
        else:
            pose = POSEY
        eye_map = {"F": EYE_FEMALE, "M": EYE_MALE, "B": EYE_BEAST, "I": EYE_ITEM}
        eye = eye_map[GROUPS[key]]
        pos = ("masterpiece, best quality, highly detailed, sharp focus, clean lineart, "
               f"{feat}, {pose}, {STYLE}, {eye}")
        neg = NEG_ANIMAL if key == "b05" else (NEG_ITEM if key == "b08" else NEG)
        if GROUPS[key] == "M":
            neg = NEG + ", long eyelashes, feminine face, delicate face, pretty boy"
        elif GROUPS[key] == "B":
            neg = neg + ", long eyelashes, feminine face, cute face"
        init = f"init_gray/{key}_init_gray.png"
        for n in range(2):
            seed = seed_base + i * 2 + n
            prefix = f"prod_{key}_g{n+1}"
            wf = {
                "1": {"class_type": "LoadImage", "inputs": {"image": init}},
                "2": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT}},
                "3": {"class_type": "VAEEncode", "inputs": {"pixels": ["1", 0], "vae": ["2", 2]}},
                "4": {"class_type": "CLIPTextEncode", "inputs": {"text": pos, "clip": ["2", 1]}},
                "5": {"class_type": "CLIPTextEncode", "inputs": {"text": neg, "clip": ["2", 1]}},
                "6": {"class_type": "KSampler", "inputs": {"seed": seed, "steps": 32, "cfg": 6.5,
                      "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 0.75,
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
