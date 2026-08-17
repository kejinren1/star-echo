#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_portraits_batch.py — 12 角色定稿要素 → A/B 路线立绘批量生成（2026-08-16）
要素源：docs/art_ai/角色要素定稿表_20260816.md（用户定稿）
配置：NoobAI-XL-v1.1 · 1024×1536 直出 · 32步 CFG6.5 dpmpp_2m+karras（08-15 定稿）
路线 A：虹膜强化+衣物权重平衡；路线 B：基础眼部简洁版
每角色 × 2 路线 × 2 seed = 48 张
"""
import json, time, urllib.request

HOST = "http://127.0.0.1:18001"
TOKEN = "$2b$12$.TAugRmvKlv5LxFdgOXP4.7mFvhRY2GpvKmr2S8kvAVB9bP/ivSae"
CKPT = "NoobAI-XL-v1.1.safetensors"

# ---------- 画风通用块（WD14 反推）----------
STYLE = ("black background, simple background, low-key cinematic lighting, "
         "warm rim light, muted desaturated color palette, with margin, "
         "completely inside frame, no cropping")
POSEY = "full body, standing, three-quarter view, body turned slightly to the side"
EYE_A = ("(masterpiece iris:1.3), (detailed iris:1.35), (sparkling eyes:1.25), "
         "(iris reflection:1.2), specular highlights in eyes, (long eyelashes:1.25), "
         "(detailed face:1.2), sharp facial features")
EYE_B = ("detailed eyes, detailed iris, sparkling eyes, long eyelashes, "
         "detailed face, beautiful face, sharp facial features")

# ---------- 12 角色要素（中文定稿 → 英文 prompt）----------
CHARS = {
    "elin": {
        "zh": "艾琳", "kind": "human",
        "feat": ("1girl, petite loli, short stature, deep crimson red long hair, red eyes, "
                 "tall classic pointed wizard hat with wide brim, black and red mage robe "
                 "with gold flame patterns, long flowing robe reaching to feet, "
                 "wide billowing sleeves, small simple wooden wand, black red gold color scheme"),
    },
    "noah": {
        "zh": "诺亚", "kind": "human",
        "feat": ("1girl, youth, silver blue short hair, blue eyes, "
                 "vintage victorian scholarly outfit, dark blue tailcoat with rune embroidery, "
                 "white shirt, leather vest, striped trousers, high heel boots, "
                 "vintage round brass goggles with rivets and leather strap, "
                 "pocket watch chain, small wrench, dark blue brass white color scheme"),
    },
    "lain": {
        "zh": "莱恩", "kind": "human",
        "feat": ("1boy, young male, white hair, sharp blue eyes, "
                 "dark battle-worn mottled leather and steel armor, scratches and dents, "
                 "old worn cloak, holding a longsword at his side, "
                 "deep gray black dark steel color scheme"),
    },
    "siia": {
        "zh": "希亚", "kind": "human",
        "feat": ("1girl, youth, soft long blonde hair, gentle green eyes, "
                 "platinum white priestess robe with light trims, healing staff, "
                 "white gold green color scheme"),
    },
    "b01": {"zh": "BOSS①魔族女战士", "kind": "human",
            "feat": ("1girl, dark skin, muscular toned female warrior, "
                     "tight battle armor, seductive combat outfit, curved scimitar, "
                     "black red silver color scheme")},
    "b02": {"zh": "BOSS②黑魔法师", "kind": "human",
            "feat": ("1boy, extremely emaciated skeletal thin male mage, "
                     "sunken hollow eyes, gaunt haggard face, tattered black robe, "
                     "bone staff, dark purple black color scheme")},
    "b03": {"zh": "BOSS③帮派首领", "kind": "human",
            "feat": ("1boy, gang leader, ornate wild fur coat, gold chains, "
                     "confident smug smirk, flamboyant boss attire, "
                     "dark red gold black color scheme")},
    "b04": {"zh": "BOSS④白蓝金骑士", "kind": "human",
            "feat": ("1boy, young male knight, bare head, visible noble face, "
                     "white armor main color, blue and gold trims, "
                     "intricate fine armor engraving, holy sword, "
                     "righteous protagonist of light, white blue gold color scheme")},
    "b05": {"zh": "BOSS⑤病态狼兽", "kind": "animal",
            "feat": ("feral wolf beast, pure quadrupedal animal, all fours, "
                     "purple black fur, emaciated skeletal thin body, visible ribs, "
                     "crimson red eyes, long prominent tail, wounds and scars, "
                     "ferocious snarling")},
    "b06": {"zh": "BOSS⑥牛头人", "kind": "human",
            "feat": ("1boy, minotaur warrior, huge curved horns, bull head, "
                     "leather armor with fur, wielding heavy battle axe, "
                     "dark brown bronze color scheme")},
    "b07": {"zh": "BOSS⑦空洞女神", "kind": "human",
            "feat": ("1girl, tall slender goddess, very long black hair, pale skin, "
                     "black elegant dress, hollow void in her abdomen, "
                     "cosmic emptiness, mysterious divine presence")},
    "b08": {"zh": "BOSS⑧不详之镜", "kind": "item",
            "feat": ("ornate ancient hand mirror, antique elaborate golden frame, "
                     "intricate carvings, ominous, an eye peering from within the mirror, "
                     "dark mysterious atmosphere")},
}

NEG = ("worst quality, low quality, blurry, bad anatomy, extra fingers, "
       "watermark, text, logo, signature, "
       "bad eyes, deformed iris, ugly eyes, poor facial details, "
       "blurry face, distorted face, bad face, plain eyes, flat iris, dull eyes, "
       "cluttered outfit, messy clothes, tangled hair, noisy background, "
       "effects, magic aura, glow, particles, out of frame, cropped figure")

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


def build_prompt(c, route):
    feat = c["feat"]
    if c["kind"] == "human":
        pose = POSEY
    elif c["kind"] == "animal":
        pose = "full body quadrupedal animal, natural four-leg stance, all fours"
    else:
        pose = "a single ornate mirror centered, vertical composition"
    eye = EYE_A if route == "A" else EYE_B
    if c["kind"] == "item" and route == "A":
        eye = "(intricate fine detail:1.3), (ornate golden frame detail:1.3)"
    pos = ("masterpiece, best quality, highly detailed, sharp focus, clean lineart, "
           f"{feat}, {pose}, {STYLE}, {eye}")
    return pos


def main():
    seed_base = 20260816
    total = 0
    for i, (key, c) in enumerate(CHARS.items()):
        for route in ["A", "B"]:
            for n in range(2):
                seed = seed_base + i * 4 + (0 if route == "A" else 2) + n
                prefix = f"port_{key}_{route}_{n+1}"
                pos = build_prompt(c, route)
                neg = NEG_ANIMAL if c["kind"] == "animal" else (NEG_ITEM if c["kind"] == "item" else NEG)
                wf = {
                    "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT}},
                    "2": {"class_type": "EmptyLatentImage", "inputs": {"width": 1024, "height": 1536, "batch_size": 1}},
                    "3": {"class_type": "CLIPTextEncode", "inputs": {"text": pos, "clip": ["1", 1]}},
                    "4": {"class_type": "CLIPTextEncode", "inputs": {"text": neg, "clip": ["1", 1]}},
                    "5": {"class_type": "KSampler", "inputs": {"seed": seed, "steps": 32, "cfg": 6.5,
                          "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 1.0,
                          "model": ["1", 0], "positive": ["3", 0], "negative": ["4", 0], "latent_image": ["2", 0]}},
                    "6": {"class_type": "VAEDecode", "inputs": {"samples": ["5", 0], "vae": ["1", 2]}},
                    "7": {"class_type": "SaveImage", "inputs": {"filename_prefix": prefix, "images": ["6", 0]}},
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
                                print(f"DONE {prefix} seed{seed}: {img['filename']}", flush=True)
                                total += 1
                        break
    print(f"ALL_FINISHED total={total}", flush=True)


if __name__ == "__main__":
    main()
