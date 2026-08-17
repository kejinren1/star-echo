#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""run_heroes_bg_fix.py — 人物/怪物背景规范重跑（用户 08-15 拍板：局内素材零背景/纯白灰底/反差大）
用 run_today_assets.py 同款描述+骨架，但 prompt 强化纯白背景、negative 封堵杂色背景。
产出 output_abc/heroes_bgfix_20260815/，后处理走既有 img2sprite 抠底→试装管线。
"""
import json
import sys
from pathlib import Path

sys.path.insert(0, r"D:/30DAYS/docs/art_ai")
from comfy_client import ComfyClient  # noqa

HOST = "http://61.157.218.59:31071"
TOKEN = "$2b$12$hJjmO84moQQWigWYsGH10O/yHLqLwBgIPZmwa10BSbTVoGQ6fi4ze"
CKPT_PIX = "aziibpixelmix_v10.safetensors"
CN = "control_v11p_sd15_openpose.pth"
POSE_DIR = Path("D:/30DAYS/docs/art_ai/output_abc/pose")
OUT = Path("D:/30DAYS/docs/art_ai/output_abc/heroes_bgfix_20260815")
OUT.mkdir(parents=True, exist_ok=True)

# 背景规范（用户拍板）：纯白/纯灰 + 与本体反差大 + 零杂物
BG_POS = (", crisp pixel art sprite, bold clean palette, clean silhouette, full body visible head to toe, "
          "pure white background, solid flat uniform background, no gradient, no ground shadow, "
          "no rim light, no vignette, no floor, no decorations")
NEG_PIX = ("blurry, low quality, stiff pose, half body, portrait, close-up, crop, ugly, deformed, "
           "child, loli, flat chest, effects, particles, magic, aura, background decoration, "
           "dark background, colored background, red background, gradient background, "
           "ground shadow, vignette, floor, multiple characters, text, watermark")

HEROES = {
    "elin": {
        "zh": "炎术师·艾琳",
        "desc": ("young woman, long crimson red hair, red eyes, black and red mage robe with "
                 "golden flame trim, glowing fire orb in hand, flame mage, confident expression"),
        "pose": "待机叉腰骨架_v3_768.png",
    },
    "noah": {
        "zh": "机械师·诺亚",
        "desc": ("young woman, short silver blue hair, blue eyes, blue and gray mechanic jumpsuit "
                 "with tool belt and goggles, wrench in hand, engineer, calm focused expression"),
        "pose": "待机叉腰骨架_v4_768.png",
    },
    "lain": {
        "zh": "剑士·莱恩",
        "desc": ("young man, short white hair, sharp blue eyes, black and silver blademaster outfit "
                 "with dark blue scarf, glowing star sword in hand, swordsman, cool expression"),
        "pose": "待机叉腰骨架_v3_768.png",
    },
    "siia": {
        "zh": "医师·希亚",
        "desc": ("young woman, long soft golden hair, gentle green eyes, white and gold priestess robe "
                 "with light ornaments, radiant healing staff in hand, cleric, warm gentle smile"),
        "pose": "待机叉腰骨架_v4_768.png",
    },
}
MONSTERS = {
    "skeleton": "skeleton soldier, bone body with tattered dark armor, glowing eye sockets, rusted sword in hand, undead",
    "slime": "cute round slime monster, translucent green gel body with glossy highlight, small eyes and mouth",
    "predator": "feral predator beast, quadrupedal dark red creature with spikes and glowing eyes, sharp claws",
    "invoker": "hooded invoker mage, dark purple robe, glowing arcane runes, floating skull staff, sinister",
    "elite": "elite heavy armored soldier, black and gold full plate armor with glowing red core, large warhammer",
}
FRAMES = {"idle": "idle_1_768.png", "attack": "attack_1_768.png",
          "skill": "skill_1_768.png", "hit": "hit_1_768.png"}


def build_wf(desc, pose_name, seed):
    text = desc + BG_POS
    wf = {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT_PIX}},
        "2": {"class_type": "CLIPTextEncode", "inputs": {"text": text, "clip": ["1", 1]}},
        "3": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG_PIX, "clip": ["1", 1]}},
    }
    pos = ["2", 0]
    if pose_name:
        wf["4"] = {"class_type": "ControlNetLoader", "inputs": {"control_net_name": CN}}
        wf["5"] = {"class_type": "LoadImage", "inputs": {"image": pose_name}}
        wf["6"] = {"class_type": "ControlNetApply", "inputs": {"conditioning": ["2", 0], "control_net": ["4", 0],
             "image": ["5", 0], "strength": 0.9}}
        pos = ["6", 0]
    wf["7"] = {"class_type": "EmptyLatentImage", "inputs": {"width": 768, "height": 768, "batch_size": 1}}
    wf["8"] = {"class_type": "KSampler", "inputs": {"seed": seed, "steps": 28, "cfg": 6.5,
         "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 1.0,
         "model": ["1", 0], "positive": pos, "negative": ["3", 0], "latent_image": ["7", 0]}}
    wf["9"] = {"class_type": "VAEDecode", "inputs": {"samples": ["8", 0], "vae": ["1", 2]}}
    wf["10"] = {"class_type": "SaveImage", "inputs": {"filename_prefix": "herofix", "images": ["9", 0]}}
    return wf


def gen(client, name, wf, out_dir):
    pid = client.submit(wf)
    entry = client.wait_history(pid, timeout=900)
    return client.download_outputs(entry, out_dir, name)


def main():
    client = ComfyClient(HOST, token=TOKEN)
    progress = OUT / "_PROGRESS.json"
    done = set()
    if progress.exists():
        done = set(json.loads(progress.read_text(encoding="utf-8")))

    pose_names = {}
    for f in POSE_DIR.glob("*_768.png"):
        pose_names[f.name] = client.upload_image(f)
    print(f"[pose] 上传 {len(pose_names)} 张骨架")

    tasks = []
    seed = 2026081501
    for hid, hero in HEROES.items():
        for fname, pose in FRAMES.items():
            pn = pose_names[hero["pose"]]
            tasks.append((f"{hid}_{fname}", f"heroes/{hid}",
                          build_wf(hero["desc"], pn, seed + len(tasks))))
    pose_std = pose_names["标准站姿骨架_768.png"]
    for mid, desc in MONSTERS.items():
        tasks.append((f"mon_{mid}", "monsters",
                      build_wf(desc, pose_std, seed + 500 + len(tasks))))

    print(f"[plan] 共 {len(tasks)} 张待生成")
    ok, fail = 0, []
    for i, (name, sub, wf) in enumerate(tasks):
        if name in done:
            print(f"[{i+1}/{len(tasks)}] {name} 已存在，跳过")
            ok += 1
            continue
        try:
            gen(client, name, wf, OUT / sub)
            done.add(name)
            progress.write_text(json.dumps(sorted(done)), encoding="utf-8")
            ok += 1
            print(f"[{i+1}/{len(tasks)}] {name} ✅ ({len(done)}/{len(tasks)})")
        except Exception as e:
            fail.append((name, str(e)[:120]))
            print(f"[{i+1}/{len(tasks)}] {name} ❌ {str(e)[:120]}")
    print("=== 完成 ===")
    print(f"成功 {ok}/{len(tasks)}，失败 {len(fail)}")
    for n, e in fail:
        print(f"  {n}: {e}")


if __name__ == "__main__":
    main()
