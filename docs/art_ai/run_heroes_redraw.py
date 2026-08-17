#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""run_heroes_redraw.py — 主角团图像资源重绘（用户 08-15 拍板：只画图，试装走另一条线）
主角团：艾琳 elin / 诺亚 noah / 莱恩 lain / 希亚 siia
产出（全部纯白背景规范）：
  A. 像素轨局内帧 20 张：4 主角 × (idle/walk/attack/skill/hit) 768×768 + OpenPose 骨架
  B. 立绘 4 张：Neta Art XL 768×1024 纯白底
输出：output_abc/heroes_redraw_20260815/（原图；抠底/降采样/试装由试装线处理）
"""
import json
import sys
from pathlib import Path

sys.path.insert(0, r"D:/30DAYS/docs/art_ai")
from comfy_client import ComfyClient  # noqa

HOST = "http://61.157.218.59:31071"
TOKEN = "$2b$12$hJjmO84moQQWigWYsGH10O/yHLqLwBgIPZmwa10BSbTVoGQ6fi4ze"
CKPT_PIX = "aziibpixelmix_v10.safetensors"
CKPT_XL = "Neta Art XL 二次元角色 （更新V2）_V2.0.safetensors"
CN = "control_v11p_sd15_openpose.pth"
POSE_DIR = Path("D:/30DAYS/docs/art_ai/output_abc/pose")
OUT = Path("D:/30DAYS/docs/art_ai/output_abc/heroes_redraw_20260815")
OUT.mkdir(parents=True, exist_ok=True)

# ===== 背景规范（用户 08-15 拍板：局内素材零背景/纯白灰底/与本体反差大） =====
BG_POS = (", crisp pixel art sprite, bold clean palette, clean silhouette, full body visible head to toe, "
          "pure white background, solid flat uniform background, no gradient, no ground shadow, "
          "no rim light, no vignette, no floor, no decorations")
NEG_PIX = ("blurry, low quality, stiff pose, half body, portrait, close-up, crop, ugly, deformed, "
           "child, loli, flat chest, effects, particles, magic, aura, background decoration, "
           "dark background, colored background, red background, gradient background, "
           "ground shadow, vignette, floor, multiple characters, text, watermark")
NEG_XL = ("blurry, low quality, deformed hands, extra fingers, bad anatomy, watermark, text, "
          "multiple characters, ugly, background details, gradient background, shadow, "
          "dark background, decorations")

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

# 动作帧：骨架 + 动作词（walk 无专用骨架：同 idle 骨架 + 行走描述 + 降低 CN 强度）
FRAMES = {
    "idle":   ("idle_1_768.png",    "standing idle pose", 0.9),
    "walk":   ("待机叉腰骨架_v4_768.png", "walking stride forward, one leg forward, dynamic walking motion", 0.7),
    "attack": ("attack_1_768.png",  "attack pose, casting strike motion", 0.9),
    "skill":  ("skill_1_768.png",   "casting skill pose, hands raised channeling power", 0.9),
    "hit":    ("hit_1_768.png",     "hit reaction pose, knocked back, leaning", 0.9),
}


def build_pixel_wf(desc, pose_name, action_word, strength, seed):
    text = f"{desc}, {action_word}" + BG_POS
    wf = {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT_PIX}},
        "2": {"class_type": "CLIPTextEncode", "inputs": {"text": text, "clip": ["1", 1]}},
        "3": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG_PIX, "clip": ["1", 1]}},
        "4": {"class_type": "ControlNetLoader", "inputs": {"control_net_name": CN}},
        "5": {"class_type": "LoadImage", "inputs": {"image": pose_name}},
        "6": {"class_type": "ControlNetApply", "inputs": {"conditioning": ["2", 0], "control_net": ["4", 0],
             "image": ["5", 0], "strength": strength}},
        "7": {"class_type": "EmptyLatentImage", "inputs": {"width": 768, "height": 768, "batch_size": 1}},
        "8": {"class_type": "KSampler", "inputs": {"seed": seed, "steps": 28, "cfg": 6.5,
             "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 1.0,
             "model": ["1", 0], "positive": ["6", 0], "negative": ["3", 0], "latent_image": ["7", 0]}},
        "9": {"class_type": "VAEDecode", "inputs": {"samples": ["8", 0], "vae": ["1", 2]}},
        "10": {"class_type": "SaveImage", "inputs": {"filename_prefix": "heroredraw", "images": ["9", 0]}},
    }
    return wf


def build_portrait_wf(desc, seed):
    text = (f"masterpiece, best quality, highly detailed, sharp focus, clean lineart, "
            f"high quality anime illustration, cel shading with painterly finish, {desc}, "
            f"full body character concept art, standing pose, clean silhouette, "
            f"pure white background, solid flat uniform background, no gradient, no shadow, "
            f"no decorations, no effects")
    wf = {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT_XL}},
        "2": {"class_type": "CLIPTextEncode", "inputs": {"text": text, "clip": ["1", 1]}},
        "3": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG_XL, "clip": ["1", 1]}},
        "7": {"class_type": "EmptyLatentImage", "inputs": {"width": 768, "height": 1024, "batch_size": 1}},
        "8": {"class_type": "KSampler", "inputs": {"seed": seed, "steps": 28, "cfg": 7.0,
             "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 1.0,
             "model": ["1", 0], "positive": ["2", 0], "negative": ["3", 0], "latent_image": ["7", 0]}},
        "9": {"class_type": "VAEDecode", "inputs": {"samples": ["8", 0], "vae": ["1", 2]}},
        "10": {"class_type": "SaveImage", "inputs": {"filename_prefix": "heroportrait", "images": ["9", 0]}},
    }
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

    pose_names = {f.name: client.upload_image(f) for f in POSE_DIR.glob("*_768.png")}
    print(f"[pose] 上传 {len(pose_names)} 张骨架")

    tasks = []  # (name, subdir, wf)
    seed = 2026081502
    for hid, hero in HEROES.items():
        for fname, (pose, action, strength) in FRAMES.items():
            pn = pose_names[pose]
            tasks.append((f"{hid}_{fname}", f"heroes/{hid}",
                          build_pixel_wf(hero["desc"], pn, action, strength, seed + len(tasks))))
        # 立绘
        tasks.append((f"portrait_{hid}", "portraits",
                      build_portrait_wf(hero["desc"], seed + 1000 + len(tasks))))

    print(f"[plan] 共 {len(tasks)} 张待生成（4 主角 × 5 动作帧 + 4 立绘）")
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
