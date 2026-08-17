#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_v7_batch.py — v7 修正批量（用户 08-15 23:46 反馈）
艾琳固定萝莉(矮个帽入框) / 莱恩去骨架自由侧身+深色斑驳甲强化 / 诺亚改魔法朋克+禁环装道具
Boss2 重绘 / Boss4 光系主角气质 / Boss5 修长消瘦长尾 / Boss7 全身(回归站姿骨架)
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
      "three-quarter view, slight body rotation, "
      "full body visible head to toe with margin, completely inside frame, no cropping, safe margins, "
      "pure white background, solid flat uniform background, no gradient, no ground shadow, "
      "no rim light, no vignette, no floor, no decorations, no effects, no magic, no glow, "
      "no particles, no magic aura, no background objects")
NEG = ("blurry, low quality, stiff pose, symmetrical pose, half body, portrait, close-up, crop, "
       "bust, headshot, ugly, deformed, effects, particles, magic, aura, glow, "
       "background decoration, background objects, floating gears, gears in background, "
       "floating rings, rings in background, circular objects in background, machinery background, "
       "dark background, colored background, red background, gradient background, "
       "ground shadow, vignette, floor, out of frame, cropped figure, cropped hat, hat out of frame, "
       "multiple figures, small figures, tiny people, companions, multiple characters, text, watermark, "
       "modern clothes, jeans, t-shirt, hoodie, military uniform, modern machinery, gun, rifle, "
       "modern glasses, eyeglasses, thin frame glasses, exposed torso, bare chest, shirtless, nude")

# 艾琳：固定萝莉体型（用户定稿）
ELIN_LOLI = ("petite young girl, loli, short, tiny frame, small stature, "
             "long crimson red hair, red eyes, "
             "short classic pointed wizard hat fully visible inside frame, "
             "elegant black mage robe with crimson and gold flame embroidery, "
             "holding a simple wooden staff, fire mage")

# 莱恩：去骨架自由侧身 + 深色斑驳甲强化
LAIN_VARIANTS = {
    "vA": ("young man, short white hair, sharp blue eyes, "
           "dark battle-worn mottled steel armor, deep dark tones, aged scratched metal, "
           "black cape, wielding a longsword, battle-hardened knight, "
           "body turned to the side, side profile"),
    "vB": ("young man, short white hair, sharp blue eyes, "
           "dark battle-worn mottled leather and steel armor, deep dark tones, "
           "weathered dark cloak, holding a longsword, lone veteran swordsman, "
           "body turned to the side, side profile"),
    "vC": ("young man, short white hair, sharp blue eyes, "
           "dark mottled ceremonial armor with aged dark gold inlay, deep dark tones, "
           "holding a longsword, royal veteran guardian, "
           "body turned to the side, side profile"),
}

# 诺亚：魔法朋克风格（用户定稿方向）
NOAH_MAGICPUNK = ("short silver blue hair, blue eyes, "
                  "rune-engraved vintage brass goggles with leather strap on forehead, "
                  "magicpunk engineer, arcane dark blue coat etched with glowing runes, "
                  "crystal power core on chest, brass clockwork shoulder ornaments, "
                  "leather tool belt with rune tools, holding a wrench, fantasy magicpunk engineer")

def make_wf(desc, pose_name, seed, prefix, neg=None):
    text = desc + BG
    nodes = {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT}},
        "2": {"class_type": "CLIPTextEncode", "inputs": {"text": text, "clip": ["1", 1]}},
        "3": {"class_type": "CLIPTextEncode", "inputs": {"text": neg or NEG, "clip": ["1", 1]}},
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
    seed = 20261101
    # 艾琳 固定萝莉 × 3 seed
    for k in range(3):
        tasks.append((f"v7_elin_loli_{k+1}", ELIN_LOLI, "待机叉腰骨架_v4_768.png", seed + k))
    # 诺亚 魔法朋克 3 体型 × 2 seed
    BODY = [
        "mature woman, adult woman, tall, long legs, voluptuous curvy figure, large breasts, single figure, solo",
        "young woman, medium breasts, youthful slim figure, moderate height, single figure, solo",
        "petite young girl, loli, short, tiny frame, youthful, single figure, solo",
    ]
    for bi, btag in enumerate(BODY):
        for k in range(2):
            tasks.append((f"v7_noah_{['mature','youth','loli'][bi]}_{k+1}", f"{btag}, {NOAH_MAGICPUNK}",
                          "待机叉腰骨架_v4_768.png", seed + 20 + bi * 10 + k))
    # 莱恩 去骨架自由侧身 × 3 造型
    for vi, (vk, extra) in enumerate(LAIN_VARIANTS.items()):
        tasks.append((f"v7_lain_{vk}", extra, None, seed + 100 + vi))
    # Boss 修正
    BOSSES = [
        ("v7_boss_02_mage", "very thin gaunt male dark sorcerer, skeletal thin frail body, pale skin, sunken hollow eyes, fully clothed in long tattered black robe covering body, bone staff in hand, sinister", "标准站姿骨架_768.png"),
        ("v7_boss_04_light_knight", "pristine white full armor knight, helmet off, visible noble heroic face, golden trims, white cape, holy longsword, righteous protagonist of light, looks like the hero of a light fantasy story", "标准站姿骨架_768.png"),
        ("v7_boss_05_wolf", "quadrupedal werewolf beast on all fours, lean slender elongated body, long thin tail, stretched slender limbs, twisted distorted infected form, wolf head, feral, dark fur", None),
        ("v7_boss_07_goddess", "tall elegant beautiful goddess, long flowing black hair, pale fair skin, slim tall figure, sleek black formal dress, hollow void in her abdomen, cosmic emptiness, serene divine expression, full body visible completely", "标准站姿骨架_768.png"),
    ]
    for bi, (bid, desc, pose) in enumerate(BOSSES):
        tasks.append((bid, desc, pose, seed + 200 + bi * 7))

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
