#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_v3_batch.py — 主角团 v3（用户 08-15 造型建议）+ 8 Boss 局内模型
主角团：艾琳=法师帽标志 / 诺亚=蒸汽朋克+黄铜护目镜标志 / 莱恩=黑色系 / 希亚微调；全角色去特效
Boss：8 方向（用户 08-15 提供），站姿骨架/自由形体
规格：aziibpixelmix 768×768 直出 + OpenPose + 纯白底（昨晚定案管线）
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
      "no rim light, no vignette, no floor, no decorations, no effects, no magic, no glow")
NEG = ("blurry, low quality, stiff pose, half body, portrait, close-up, crop, ugly, deformed, "
       "child, loli, flat chest, effects, particles, magic, aura, glow, background decoration, "
       "dark background, colored background, red background, gradient background, "
       "ground shadow, vignette, floor, multiple characters, text, watermark, modern clothes, "
       "jeans, t-shirt, hoodie, military uniform, modern machinery, gun, rifle")

# ===== 主角团 v3（用户建议落地）=====
HEROES = {
    "elin": ("炎术师艾琳", "待机叉腰骨架_v3_768.png", {
        "vA": "young woman, long crimson red hair, red eyes, classic pointed wizard hat, elegant black mage robe with crimson and gold flame embroidery, holding a simple wooden staff, dignified fire mage",
        "vB": "young woman, long crimson red hair, red eyes, wide-brimmed traveling wizard hat, crimson traveling robe with leather belt and satchel, holding a lantern staff, spirited fire mage",
        "vC": "young woman, long crimson red hair, red eyes, tall ornate pointed sorceress hat with golden filigree, luxurious black and crimson robe with golden trim, holding a fire tome, royal fire mage",
    }),
    "noah": ("魔导技师诺亚", "待机叉腰骨架_v4_768.png", {
        "vA": "young woman, short silver blue hair, blue eyes, vintage brass goggles on forehead, steampunk engineer outfit, dark navy leather coat with brass gears and copper pipes, holding a wrench, fantasy steampunk engineer",
        "vB": "young woman, short silver blue hair, blue eyes, vintage brass goggles, steampunk alchemist, leather apron over teal tunic, brass instruments on belt, holding a brass pocket watch, alchemist traveler",
        "vC": "young woman, short silver blue hair, blue eyes, brass goggles with ornate frame, royal steampunk scholar, white and gold academy robe with sapphire insignia, mechanical gauntlet, fantasy noble engineer",
    }),
    "lain": ("剑士莱恩", "待机叉腰骨架_v3_768.png", {
        "vA": "young man, short white hair, sharp blue eyes, black knight, dark obsidian full armor with black cape, longsword resting on shoulder, dark heroic knight",
        "vB": "young man, short white hair, sharp blue eyes, dark wandering swordsman, black leather armor with tattered dark cloak, black longsword at his side, calm lone swordsman",
        "vC": "young man, short white hair, sharp blue eyes, black royal guard, dark ceremonial armor with gold inlay, dark longsword held low, royal black guardian",
    }),
    "siia": ("医师希亚", "待机叉腰骨架_v4_768.png", {
        "vA": "young woman, long soft golden hair, gentle green eyes, white and gold priestess robe with light ornaments, simple healing staff in hand, warm healer",
        "vB": "young woman, long soft golden hair, gentle green eyes, cream tunic with green cross-stitched cape, herbal satchel, wooden staff with flower, kind apothecary",
        "vC": "young woman, long soft golden hair, gentle green eyes, elegant white ceremonial gown with golden halo ornament, crystal scepter, divine saint",
    }),
}

# ===== Boss 8 方向（用户 08-15 提供）=====
# (名字, 造型 desc, 骨架: None=自由/站姿)
BOSSES = [
    ("boss_01_demon_warrior", "mature dark-skinned demoness warrior, sexy revealing outfit, fit toned athletic body, confident battle stance, curved blade in hand, dark fantasy demon", "标准站姿骨架_768.png"),
    ("boss_02_dark_mage", "very thin gaunt male dark sorcerer, pale skin, sunken eyes, long black robe with tattered edges, bone staff in hand, sinister black magic caster", "标准站姿骨架_768.png"),
    ("boss_03_gang_leader", "flamboyant wild charismatic gang leader man, ornate fur-trimmed coat with gold chains, demon-contract power aura-free, confident sly smile, demonic sigil on chest", "标准站姿骨架_768.png"),
    ("boss_04_white_knight", "heroic-looking knight in shining pristine white full armor, noble kind face, white cape, holy longsword, looks exactly like a righteous protagonist", "标准站姿骨架_768.png"),
    ("boss_05_werewolf_beast", "abnormally muscular werewolf beast, wolf head, twisted infected corrupted body, hunched ferocious stance, claws, dark fur, monstrous", None),
    ("boss_06_minotaur", "massive strong minotaur warrior, bull head with large horns, muscular humanoid body, heavy axe in hand, fierce battle stance", None),
    ("boss_07_goddess", "tall elegant beautiful goddess, long flowing black hair, pale fair skin, slim tall figure, sleek black formal dress, serene divine expression", "标准站姿骨架_768.png"),
    ("boss_08_red_eye", "a single enormous intricate blood-red eye with detailed iris patterns, divine being peering through a tear in space, cosmic horror entity, dark void background", None),
]

def make_wf(desc, pose_name, seed, prefix):
    text = desc + BG
    nodes = {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT}},
        "2": {"class_type": "CLIPTextEncode", "inputs": {"text": text, "clip": ["1", 1]}},
        "3": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG, "clip": ["1", 1]}},
        "7": {"class_type": "EmptyLatentImage", "inputs": {"width": 768, "height": 768, "batch_size": 1}},
    }
    nid = 7
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
    seed = 20260901
    for hid, (zh, pose, variants) in HEROES.items():
        for vi, vk in enumerate(["vA", "vB", "vC"]):
            tasks.append((f"hero_{hid}_{vk}", variants[vk], pose, seed + vi))
    for bi, (bid, desc, pose) in enumerate(BOSSES):
        tasks.append((bid, desc, pose, seed + 100 + bi * 7))
    print(f"共 {len(tasks)} 张（主角 12 + Boss 8）", flush=True)
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
