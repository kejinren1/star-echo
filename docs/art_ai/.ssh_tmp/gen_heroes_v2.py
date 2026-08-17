#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_heroes_v2.py — 主线角色局内模型批量（昨晚定案管线：aziibpixelmix 768×768 + OpenPose 骨架 + 纯白底）
4 主角 × 3 造型（redesign v2 定义）· 生成留服务器 · SSH 拉回由外部 bash 执行
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
      "full body visible head to toe, "
      "pure white background, solid flat uniform background, no gradient, no ground shadow, "
      "no rim light, no vignette, no floor, no decorations")
NEG = ("blurry, low quality, stiff pose, half body, portrait, close-up, crop, ugly, deformed, "
       "child, loli, flat chest, effects, particles, magic, aura, background decoration, "
       "dark background, colored background, red background, gradient background, "
       "ground shadow, vignette, floor, multiple characters, text, watermark, modern clothes, "
       "jeans, t-shirt, hoodie, military uniform, modern machinery, gun, rifle")

HEROES = {
    "elin": ("炎术师艾琳", "待机叉腰骨架_v3_768.png", {
        "vA": "young woman, elegant classic fantasy mage, long crimson red hair, red eyes, long black robe with crimson and gold flame embroidery, holding a floating glowing flame orb, dignified fire mage",
        "vB": "young woman, traveling adventurer mage, long crimson red hair, red eyes, crimson hooded robe with leather belt and small satchel, holding a lit lantern-staff, spirited fire mage",
        "vC": "young woman, high sorceress of a magic kingdom, long crimson red hair, red eyes, luxurious black and crimson robe with golden filigree, glowing flame crown motif, holding a radiant fire tome, royal fire mage",
    }),
    "noah": ("魔导技师诺亚", "待机叉腰骨架_v4_768.png", {
        "vA": "young woman, magitech tinkerer of a fantasy workshop, short silver blue hair, blue eyes, ornate dark navy coat with brass rune gears and copper clockwork ornaments, holding a glowing rune device, fantasy engineer",
        "vB": "young woman, alchemist traveler, short silver blue hair, blue eyes, leather apron over teal tunic, glass vials and brass instruments on belt, holding a staff with swirling blue rune crystals",
        "vC": "young woman, royal magitech scholar, short silver blue hair, blue eyes, white and gold academy robe with sapphire insignia, ornate mechanical gauntlet etched with runes, fantasy noble scholar",
    }),
    "lain": ("剑士莱恩", "待机叉腰骨架_v3_768.png", {
        "vA": "young man, knight errant of a fantasy kingdom, short white hair, sharp blue eyes, silver and white full armor with blue cape, rune-carved longsword resting on shoulder, heroic knight",
        "vB": "young man, wandering swordsman, short white hair, sharp blue eyes, light leather armor with worn dark cloak, simple elegant fantasy longsword at his side, calm lone traveler",
        "vC": "young man, royal sword guard, short white hair, sharp blue eyes, ornate white and gold ceremonial armor with sapphire gem inlay, glowing holy longsword held low, royal guardian knight",
    }),
    "siia": ("医师希亚", "待机叉腰骨架_v4_768.png", {
        "vA": "young woman, gentle cleric of a fantasy church, long soft golden hair, gentle green eyes, white and gold priestess robe with light ornaments, radiant healing staff in hand, warm healer",
        "vB": "young woman, traveling field medic of fantasy lands, long soft golden hair, gentle green eyes, cream tunic with green cross-stitched cape, herbal satchel, wooden staff with glowing flower, kind apothecary",
        "vC": "young woman, holy saint of light, long soft golden hair, gentle green eyes, elegant white ceremonial gown with golden halo ornament, brilliant crystal scepter, divine saint",
    }),
}

def make_wf(desc, pose_name, seed, prefix):
    text = desc + BG
    return {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT}},
        "2": {"class_type": "CLIPTextEncode", "inputs": {"text": text, "clip": ["1", 1]}},
        "3": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG, "clip": ["1", 1]}},
        "4": {"class_type": "ControlNetLoader", "inputs": {"control_net_name": CN}},
        "5": {"class_type": "LoadImage", "inputs": {"image": f"pose/{pose_name}"}},
        "6": {"class_type": "ControlNetApply", "inputs": {"conditioning": ["2", 0], "control_net": ["4", 0],
             "image": ["5", 0], "strength": 0.9}},
        "7": {"class_type": "EmptyLatentImage", "inputs": {"width": 768, "height": 768, "batch_size": 1}},
        "8": {"class_type": "KSampler", "inputs": {"seed": seed, "steps": 28, "cfg": 6.5,
             "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 1.0,
             "model": ["1", 0], "positive": ["6", 0], "negative": ["3", 0], "latent_image": ["7", 0]}},
        "9": {"class_type": "VAEDecode", "inputs": {"samples": ["8", 0], "vae": ["1", 2]}},
        "10": {"class_type": "SaveImage", "inputs": {"filename_prefix": prefix, "images": ["9", 0]}},
    }

def main():
    tasks = []
    seed = 20260826
    for hid, (zh, pose, variants) in HEROES.items():
        for vi, vkey in enumerate(["vA", "vB", "vC"]):
            tasks.append((f"hero_{hid}_{vkey}", variants[vkey], pose, seed + vi))
    print(f"共 {len(tasks)} 张（4 主角 × 3 造型）", flush=True)
    for prefix, desc, pose, seed in tasks:
        wf = make_wf(desc, pose, seed, prefix)
        try:
            resp = api("/prompt", {"prompt": wf})
        except Exception as e:
            print(f"FAIL {prefix}: {e}", flush=True)
            continue
        pid = resp.get("prompt_id")
        print(f"SUBMITTED {prefix} seed{seed}", flush=True)
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
                        print(f"DONE {prefix}: {img['filename']}", flush=True)
                break
    print("ALL_FINISHED", flush=True)

if __name__ == "__main__":
    main()
