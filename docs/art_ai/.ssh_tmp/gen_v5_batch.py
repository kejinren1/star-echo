#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_v5_batch.py — v5 修正批量（用户 08-15 23:10 反馈）
艾琳更多变体 / 诺亚去背景齿轮 / 莱恩深色斑驳甲 / Boss3 去特效 / Boss4 露脸
Boss5 四脚纤细扭曲 / Boss7 腹部空洞 / Boss8 眼睛更精细
"""
import json, time, urllib.request

HOST = "http://127.0.0.1:18001"
TOKEN = "$2b$12$.TAugRmvKlv5LxFdgOXP4.7mFvhRY2GpvKmr2S8kvAVB9bP/ivSae"
CKPT = "aziibpixelmix_v10.safetensors"
CN = "control_v11p_sd15_openpose.pth"

def api(path, payload=None):
    url = HOST + path
    data = json.dumps(payload).encode() if payload else None
    req = urllib.request.Request(url, data=data, method="POST" if payload else "GET")
    req.add_header("Authorization", "Bearer " + TOKEN)
    req.add_header("Content-Type", "application/json")
    with urllib.request.urlopen(req, timeout=90) as r:
        return json.loads(r.read())

BG = (", crisp pixel art sprite, bold clean palette, clean silhouette, "
      "three-quarter view, slight body rotation, not facing directly forward, "
      "full body visible head to toe with margin, completely inside frame, no cropping, safe margins, "
      "pure white background, solid flat uniform background, no gradient, no ground shadow, "
      "no rim light, no vignette, no floor, no decorations, no effects, no magic, no glow, "
      "no particles, no magic aura, no background objects")
NEG = ("blurry, low quality, stiff pose, symmetrical pose, half body, portrait, close-up, crop, "
       "bust, headshot, ugly, deformed, child, loli, flat chest, effects, particles, magic, aura, glow, "
       "background decoration, background objects, floating gears, gears in background, machinery background, "
       "dark background, colored background, red background, gradient background, "
       "ground shadow, vignette, floor, out of frame, cropped figure, multiple characters, text, watermark, "
       "modern clothes, jeans, t-shirt, hoodie, military uniform, modern machinery, gun, rifle, exposed torso, "
       "bare chest, shirtless, nude")

BODY = {
    "mature": "mature woman, adult woman, tall, long legs, voluptuous curvy figure, large breasts",
    "youth": "young woman, medium breasts, youthful slim figure, moderate height",
    "loli": "petite young girl, small breasts, short, tiny frame, youthful",
}

GIRLS = {
    "elin": ("炎术师艾琳", "待机叉腰骨架_v3_768.png",
             "long crimson red hair, red eyes, classic pointed wizard hat, elegant black mage robe with crimson and gold flame embroidery, holding a simple wooden staff, fire mage"),
    "noah": ("魔导技师诺亚", "待机叉腰骨架_v4_768.png",
             "short silver blue hair, blue eyes, vintage brass goggles on forehead, steampunk engineer outfit, dark navy leather coat with brass gear buttons and copper trims, leather tool belt, holding a wrench, fantasy steampunk engineer"),
}

LAIN = ("剑士莱恩", "待机叉腰骨架_v3_768.png", {
    "vA": "young man, short white hair, sharp blue eyes, dark worn mottled plate armor with scratches and dents, aged dark steel, black cape, longsword resting on shoulder, battle-hardened knight",
    "vB": "young man, short white hair, sharp blue eyes, dark worn mottled leather and steel armor, weathered dark cloak, battle-worn longsword at his side, lone veteran swordsman",
    "vC": "young man, short white hair, sharp blue eyes, dark mottled ceremonial armor with aged gold inlay, battle-worn details, dark longsword held low, royal veteran guardian",
})

BOSSES = [
    ("boss_03_gang_leader_v3", "flamboyant charismatic gang leader man, fully clothed ornate fur-trimmed coat with gold chains, confident sly smile, plain clean background", "标准站姿骨架_768.png"),
    ("boss_04_white_knight_v3", "heroic-looking knight in shining pristine white full armor, helmet off, bare head, visible handsome noble face with kind expression, white cape, holy longsword, righteous protagonist look", "标准站姿骨架_768.png"),
    ("boss_05_werewolf_v3", "quadrupedal werewolf beast on all fours, lean slender twisted distorted body, elongated limbs, corrupted infected form, wolf head, feral, dark fur, monstrous creature", None),
    ("boss_07_goddess_v3", "tall elegant beautiful goddess, long flowing black hair, pale fair skin, slim tall figure, sleek black formal dress, hollow void in her abdomen, cosmic emptiness inside her body, serene divine expression", None),
    ("boss_08_red_eye_v3", "a single extremely intricate blood-red eye, detailed iris patterns, visible veins, sharp pupil, fine detail, cosmic horror entity, pure black void background, no particles, no light rays", None),
]

def make_wf(desc, pose_name, seed, prefix):
    text = desc + BG
    nodes = {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT}},
        "2": {"class_type": "CLIPTextEncode", "inputs": {"text": text, "clip": ["1", 1]}},
        "3": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG, "clip": ["1", 1]}},
        "7": {"class_type": "EmptyLatentImage", "inputs": {"width": 768, "height": 768, "batch_size": 1}},
    }
    if pose_name:
        nodes["4"] = {"class_type": "ControlNetLoader", "inputs": {"control_net_name": CN}}
        nodes["5"] = {"class_type": "LoadImage", "inputs": {"image": f"pose/{pose_name}"}}
        nodes["6"] = {"class_type": "ControlNetApply", "inputs": {"conditioning": ["2", 0], "control_net": ["4", 0],
                     "image": ["5", 0], "strength": 0.85}}
        pos_in = ["6", 0]
    else:
        pos_in = ["2", 0]
    nodes["8"] = {"class_type": "KSampler", "inputs": {"seed": seed, "steps": 28, "cfg": 6.5,
                  "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 1.0,
                  "model": ["1", 0], "positive": pos_in, "negative": ["3", 0], "latent_image": ["7", 0]}}
    nodes["9"] = {"class_type": "VAEDecode", "inputs": {"samples": ["8", 0], "vae": ["1", 2]}}
    nodes["10"] = {"class_type": "SaveImage", "inputs": {"filename_prefix": prefix, "images": ["9", 0]}}
    return nodes

def main():
    tasks = []
    seed = 20261001
    for hid in ["elin", "noah"]:
        zh, pose, base_desc = GIRLS[hid]
        for bi, (bkey, btag) in enumerate(BODY.items()):
            for k in range(3):
                prefix = f"v5_{hid}_{bkey}_{k+1}"
                desc = f"{btag}, {base_desc}"
                tasks.append((prefix, desc, pose, seed + bi * 10 + k))
    zh, pose, variants = LAIN
    for vi, (vk, extra) in enumerate(variants.items()):
        tasks.append((f"v5_lain_{vk}", extra, pose, seed + 300 + vi))
    for bi, (bid, desc, pose) in enumerate(BOSSES):
        tasks.append((bid, desc, pose, seed + 400 + bi * 7))

    print(f"共 {len(tasks)} 张", flush=True)
    for prefix, desc, pose, seed in tasks:
        wf = make_wf(desc, pose, seed, prefix)
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
