#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""run_heroes_redesign.py — 主角团造型重设计 v2（用户 08-15 把关：日式西幻风格）
每个角色 3 个造型版本（A 经典奇幻 / B 冒险旅人 / C 高魔华丽），每版 = 局内模型（待机单帧）+ 立绘。
不画动作帧（动作由引擎程序化，避免 AI 多帧漂移导致人物统一性差）。
局内模型：aziibpixelmix 768×768 + 待机叉腰骨架；立绘：Neta Art XL 768×1024 纯白底。
输出：output_abc/heroes_redesign_20260815/<角色>/{vA,vB,vC}/model_*.png + portrait_*.png
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
OUT = Path("D:/30DAYS/docs/art_ai/output_abc/heroes_redesign_20260815")
OUT.mkdir(parents=True, exist_ok=True)

# ===== 背景规范（纯白/纯灰、零杂物、与本体反差大） =====
BG_POS = (", crisp pixel art sprite, bold clean palette, clean silhouette, full body visible head to toe, "
          "pure white background, solid flat uniform background, no gradient, no ground shadow, "
          "no rim light, no vignette, no floor, no decorations")
NEG_PIX = ("blurry, low quality, stiff pose, half body, portrait, close-up, crop, ugly, deformed, "
           "child, loli, flat chest, effects, particles, magic, aura, background decoration, "
           "dark background, colored background, red background, gradient background, "
           "ground shadow, vignette, floor, multiple characters, text, watermark, modern clothes, "
           "jeans, t-shirt, hoodie, military uniform, modern machinery, gun, rifle")
NEG_XL = ("blurry, low quality, deformed hands, extra fingers, bad anatomy, watermark, text, "
          "multiple characters, ugly, background details, gradient background, shadow, "
          "dark background, decorations, modern clothes, jeans, t-shirt, hoodie, military uniform, "
          "modern machinery, gun, rifle")

# ===== 主角团造型 v2（日式西幻）=====
# 每角色 3 版：A 经典奇幻 / B 冒险旅人 / C 高魔华丽
# 关键：诺亚去现代机械感→魔导技师；莱恩去黑魂武侠感→日式奇幻骑士；全员 fantasy 语境
HEROES = {
    "elin": {
        "zh": "炎术师·艾琳",
        "hair": "long crimson red hair, red eyes",
        "vA": ("young woman, elegant classic fantasy mage, long black robe with crimson and gold flame embroidery, "
               "holding a floating glowing flame orb, dignified fire mage"),
        "vB": ("young woman, traveling adventurer mage, crimson hooded robe with leather belt and small satchel, "
               "holding a lit lantern-staff, spirited fire mage"),
        "vC": ("young woman, high sorceress of a magic kingdom, luxurious black and crimson robe with golden filigree, "
               "glowing flame crown motif, holding a radiant fire tome, royal fire mage"),
        "pose": "待机叉腰骨架_v3_768.png",
    },
    "noah": {
        "zh": "魔导技师·诺亚",
        "hair": "short silver blue hair, blue eyes",
        "vA": ("young woman, magitech tinkerer of a fantasy workshop, ornate dark navy coat with brass rune gears "
               "and copper clockwork ornaments, small floating cogwork fairy companion, holding a glowing rune device, "
               "fantasy engineer"),
        "vB": ("young woman, alchemist traveler, leather apron over teal tunic, glass vials and brass instruments "
               "on belt, holding a staff with swirling blue rune crystals, alchemy workshop style"),
        "vC": ("young woman, royal magitech scholar, white and gold academy robe with sapphire insignia, "
               "ornate mechanical gauntlet etched with runes, floating arcane compass behind her, "
               "fantasy noble scholar"),
        "pose": "待机叉腰骨架_v4_768.png",
    },
    "lain": {
        "zh": "剑士·莱恩",
        "hair": "short white hair, sharp blue eyes",
        "vA": ("young man, knight errant of a fantasy kingdom, silver and white full armor with blue cape, "
               "rune-carved longsword resting on shoulder, heroic knight"),
        "vB": ("young man, wandering swordsman, light leather armor with worn dark cloak, "
               "a simple but elegant fantasy longsword at his side, calm lone traveler"),
        "vC": ("young man, royal sword guard, ornate white and gold ceremonial armor with sapphire gem inlay, "
               "glowing holy longsword held low, royal guardian knight"),
        "pose": "待机叉腰骨架_v3_768.png",
    },
    "siia": {
        "zh": "医师·希亚",
        "hair": "long soft golden hair, gentle green eyes",
        "vA": ("young woman, gentle cleric of a fantasy church, white and gold priestess robe with light ornaments, "
               "radiant healing staff in hand, warm healer"),
        "vB": ("young woman, traveling field medic of fantasy lands, cream tunic with green cross-stitched cape, "
               "herbal satchel and a wooden staff with glowing flower, kind apothecary"),
        "vC": ("young woman, holy saint of light, elegant white ceremonial gown with golden halo ornament, "
               "brilliant crystal scepter, divine saint"),
        "pose": "待机叉腰骨架_v4_768.png",
    },
}
VARIANTS = ["vA", "vB", "vC"]


def build_model_wf(desc, pose_name, seed):
    text = desc + BG_POS
    wf = {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT_PIX}},
        "2": {"class_type": "CLIPTextEncode", "inputs": {"text": text, "clip": ["1", 1]}},
        "3": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG_PIX, "clip": ["1", 1]}},
        "4": {"class_type": "ControlNetLoader", "inputs": {"control_net_name": CN}},
        "5": {"class_type": "LoadImage", "inputs": {"image": pose_name}},
        "6": {"class_type": "ControlNetApply", "inputs": {"conditioning": ["2", 0], "control_net": ["4", 0],
             "image": ["5", 0], "strength": 0.9}},
        "7": {"class_type": "EmptyLatentImage", "inputs": {"width": 768, "height": 768, "batch_size": 1}},
        "8": {"class_type": "KSampler", "inputs": {"seed": seed, "steps": 28, "cfg": 6.5,
             "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 1.0,
             "model": ["1", 0], "positive": ["6", 0], "negative": ["3", 0], "latent_image": ["7", 0]}},
        "9": {"class_type": "VAEDecode", "inputs": {"samples": ["8", 0], "vae": ["1", 2]}},
        "10": {"class_type": "SaveImage", "inputs": {"filename_prefix": "herov2model", "images": ["9", 0]}},
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
        "10": {"class_type": "SaveImage", "inputs": {"filename_prefix": "herov2portrait", "images": ["9", 0]}},
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

    tasks = []  # (name, out_subdir, wf)
    seed = 2026081600
    for hid, hero in HEROES.items():
        pn = pose_names[hero["pose"]]
        for vi, var in enumerate(VARIANTS):
            desc = f"{hero['hair']}, {hero[var]}"
            sub = f"{hid}/{var}"
            tasks.append((f"{hid}_{var}_model", sub,
                          build_model_wf(desc, pn, seed + len(tasks) * 7 + vi)))
            tasks.append((f"{hid}_{var}_portrait", sub,
                          build_portrait_wf(desc, seed + 500 + len(tasks) * 7 + vi)))

    print(f"[plan] 共 {len(tasks)} 张待生成（4 角色 × 3 造型版 × [局内模型+立绘]）")
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
