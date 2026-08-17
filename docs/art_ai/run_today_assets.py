#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""run_today_assets.py — 2026-08-15 量产：4主角(立绘/头像/局内帧) + 5怪物 + 8特效
管线：Neta Art XL 立绘轨（768×1024）/ aziibpixelmix 像素轨（768×768 + OpenPose 骨架）
串行逐张，断点续跑（_PROGRESS 记录成功项），完成后触发后处理脚本。
"""
import json
import sys
import time
from pathlib import Path

sys.path.insert(0, r"D:/30DAYS/docs/art_ai")
from comfy_client import ComfyClient, split_sampler  # noqa

HOST = "http://61.157.218.59:31071"
TOKEN = "$2b$12$hJjmO84moQQWigWYsGH10O/yHLqLwBgIPZmwa10BSbTVoGQ6fi4ze"
CKPT_XL = "Neta Art XL 二次元角色 （更新V2）_V2.0.safetensors"
CKPT_PIX = "aziibpixelmix_v10.safetensors"
CN = "control_v11p_sd15_openpose.pth"
POSE_DIR = Path("D:/30DAYS/docs/art_ai/output_abc/pose")
OUT = Path("D:/30DAYS/docs/art_ai/output_abc/today_20260815")
OUT.mkdir(parents=True, exist_ok=True)

NEG_PIX = ("blurry, low quality, stiff pose, half body, portrait, close-up, crop, ugly, deformed, "
           "child, loli, flat chest, no weapon, effects, particles, magic, aura, background decoration, "
           "multiple characters, text, watermark")
NEG_XL = ("blurry, low quality, deformed hands, extra fingers, bad anatomy, watermark, text, "
          "multiple characters, ugly")
PIX_TAIL = (", crisp pixel art sprite, bold clean color palette, dynamic action pose, clean silhouette, "
            "SOLID uniform plain light background, only the character, no props, no effects, "
            "full body visible head to toe with margin")

# ---------------- 资产清单 ----------------
# 四主角：固定描述（立绘与局内帧共用，保证一致性）
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

# 怪物：描述 + 标准站姿骨架
MONSTERS = {
    "skeleton": "skeleton soldier, bone body with tattered dark armor, glowing eye sockets, rusted sword in hand, undead",
    "slime": "cute round slime monster, translucent green gel body with glossy highlight, small eyes and mouth",
    "predator": "feral predator beast, quadrupedal dark red creature with spikes and glowing eyes, sharp claws",
    "invoker": "hooded invoker mage, dark purple robe, glowing arcane runes, floating skull staff, sinister",
    "elite": "elite heavy armored soldier, black and gold full plate armor with glowing red core, large warhammer",
}

# 特效：无骨架 txt2img（512 直出）
EFFECTS = {
    "fx_fireball": "fireball explosion effect, blazing orange and yellow flames with white hot core, circular burst, centered composition",
    "fx_hit": "impact hit effect, white and cyan star burst, sharp radiating lines, circular shockwave, centered",
    "fx_crit": "critical strike effect, golden and red star explosion, dramatic sparks and flash, centered",
    "fx_levelup": "level up effect, golden rising light pillar with sparkles and orbiting stars, centered",
    "fx_pickup": "pickup collect effect, small blue and green glowing orb with light rays and sparkle, centered",
    "fx_shield": "shield barrier effect, translucent blue hexagonal energy dome with glowing edges, centered",
    "fx_meteor": "meteor impact effect, massive fireball with trail and explosion debris, flaming rocks, centered",
    "fx_death": "death burst effect, dark purple smoke puff with fading bones and soul wisps, centered",
}
FX_TAIL = (", game VFX sprite, bold clean pixel art, plain light background, "
           "single effect centered, no character, no text")

FRAMES = {"idle": "idle_1_768.png", "attack": "attack_1_768.png",
          "skill": "skill_1_768.png", "hit": "hit_1_768.png"}


def build_pixel_wf(client, desc, pose_name, w, h, seed, ckpt=CKPT_PIX, tail=None):
    text = desc + (tail if tail is not None else PIX_TAIL)
    wf = {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": ckpt}},
        "2": {"class_type": "CLIPTextEncode", "inputs": {"text": text, "clip": ["1", 1]}},
        "3": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG_PIX, "clip": ["1", 1]}},
    }
    pos = ["2", 0]
    nid = 8
    if pose_name:
        wf["4"] = {"class_type": "ControlNetLoader", "inputs": {"control_net_name": CN}}
        wf["5"] = {"class_type": "LoadImage", "inputs": {"image": pose_name}}
        wf["6"] = {"class_type": "ControlNetApply", "inputs": {"conditioning": ["2", 0], "control_net": ["4", 0],
             "image": ["5", 0], "strength": 0.9}}
        pos = ["6", 0]
        nid = 8
    wf["7"] = {"class_type": "EmptyLatentImage", "inputs": {"width": w, "height": h, "batch_size": 1}}
    wf["8"] = {"class_type": "KSampler", "inputs": {"seed": seed, "steps": 28, "cfg": 6.5,
         "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 1.0,
         "model": ["1", 0], "positive": pos, "negative": ["3", 0], "latent_image": ["7", 0]}}
    wf["9"] = {"class_type": "VAEDecode", "inputs": {"samples": ["8", 0], "vae": ["1", 2]}}
    wf["10"] = {"class_type": "SaveImage", "inputs": {"filename_prefix": "today", "images": ["9", 0]}}
    return wf


def build_xl_wf(desc, w, h, seed):
    wf = {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT_XL}},
        "2": {"class_type": "CLIPTextEncode", "inputs": {"text": desc, "clip": ["1", 1]}},
        "3": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG_XL, "clip": ["1", 1]}},
        "7": {"class_type": "EmptyLatentImage", "inputs": {"width": w, "height": h, "batch_size": 1}},
        "8": {"class_type": "KSampler", "inputs": {"seed": seed, "steps": 28, "cfg": 7.0,
             "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 1.0,
             "model": ["1", 0], "positive": ["2", 0], "negative": ["3", 0], "latent_image": ["7", 0]}},
        "9": {"class_type": "VAEDecode", "inputs": {"samples": ["8", 0], "vae": ["1", 2]}},
        "10": {"class_type": "SaveImage", "inputs": {"filename_prefix": "today", "images": ["9", 0]}},
    }
    return wf


def gen(client, name, wf, out_dir):
    """提交-等待-下载，返回成功与否。"""
    pid = client.submit(wf)
    entry = client.wait_history(pid, timeout=900)
    saved = client.download_outputs(entry, out_dir, name)
    return bool(saved)


def main():
    client = ComfyClient(HOST, token=TOKEN)
    progress = OUT / "_PROGRESS.json"
    done = set()
    if progress.exists():
        done = set(json.loads(progress.read_text(encoding="utf-8")))

    # 上传骨架
    pose_names = {}
    for f in POSE_DIR.glob("*_768.png"):
        pose_names[f.name] = client.upload_image(f)
    print(f"[pose] 上传 {len(pose_names)} 张骨架")

    tasks = []  # (name, out_subdir, wf)
    seed = 20260815

    # 1. 立绘（SDXL 768×1024）
    for hid, hero in HEROES.items():
        d = hero["desc"]
        prompt = (f"masterpiece, best quality, highly detailed, sharp focus, clean lineart, "
                  f"high quality anime illustration, cel shading with painterly finish, {d}, "
                  f"full body character concept art, standing pose, clean silhouette, "
                  f"industrial post-apocalyptic atmosphere, muted lighting, subtle glowing crystal fragments")
        tasks.append((f"portrait_{hid}", "portraits", build_xl_wf(prompt, 768, 1024, seed)))

    # 2. 局内动作帧（像素轨 768×768 + 骨架）
    for hid, hero in HEROES.items():
        for fname, pose in FRAMES.items():
            pn = pose_names[pose]
            tasks.append((f"{hid}_{fname}", f"heroes/{hid}",
                          build_pixel_wf(client, hero["desc"], pn, 768, 768, seed + len(tasks))))

    # 3. 怪物（像素轨 + 标准站姿）
    pose_std = pose_names["标准站姿骨架_768.png"]
    for mid, desc in MONSTERS.items():
        tasks.append((f"mon_{mid}", "monsters", build_pixel_wf(client, desc, pose_std, 768, 768, seed + 500 + len(tasks))))

    # 4. 特效（像素轨 512 无骨架）
    for eid, desc in EFFECTS.items():
        tasks.append((eid, "effects", build_pixel_wf(client, desc + FX_TAIL, None, 512, 512, seed + 900 + len(tasks), tail="")))

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
