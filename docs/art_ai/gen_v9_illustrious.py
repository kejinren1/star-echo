#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_v9_illustrious.py — v9：Illustrious XL 立绘管线（画质升级，用户 08-15 拍板换模型）
抄作业来源：Illustrious 官方推荐 + 社区最佳实践（booru 标签 + 自然语言混合 / dpmpp_2m_cfg_pp+karras
/ steps 26 / CFG 6 / 质量标签 masterpiece,best quality,very aesthetic,absurdres / Hires fix 4x-UltraSharp 2x denoise 0.35）
用法：等模型下载完（/root/ComfyUI/models/checkpoints/Illustrious-XL-v2.0.safetensors）再跑
"""
import json
import sys
from pathlib import Path

sys.path.insert(0, r"D:/30DAYS/docs/art_ai")
from comfy_client import ComfyClient  # noqa

HOST = "http://61.157.218.59:31071"
TOKEN = "$2b$12$hJjmO84moQQWigWYsGH10O/yHLqLwBgIPZmwa10BSbTVoGQ6fi4ze"
CKPT = "Illustrious-XL-v2.0.safetensors"
OUT = Path("D:/30DAYS/docs/art_ai/output_abc/v9_illustrious_20260815_v2")
OUT.mkdir(parents=True, exist_ok=True)

# ===== Illustrious 质量标签 + 负面模板（社区抄作业） =====
QPOS = "masterpiece, best quality, very aesthetic, absurdres"
# 背景强约束（Illustrious 需加权 + 负面封堵，社区经验）
BG_STRONG = ("(white background:1.4), (plain background:1.2), solid white background, "
             "monochrome background, single color background, empty background")
NEG = ("worst quality, low quality, bad anatomy, bad hands, missing fingers, extra digits, "
       "watermark, text, signature, username, logo, cropped, half body, bust, close-up, "
       "multiple views, jpeg artifacts, blurry, ugly, deformed, disfigured, "
       "background decoration, gradient background, dark background, colored background, "
       "scenery, landscape, detailed background, complex background, indoors, outdoors, "
       "forest, room, city, sky, ground shadow, floor, "
       "modern clothes, jeans, t-shirt, hoodie, "
       "military uniform, gun, rifle, modern machinery, pure side view, complete profile")

# 体态标签（booru 体系）
BODY_TAGS = {
    "mature": "mature female, adult woman, large breasts, tall, long legs, voluptuous",
    "youth": "young woman, medium breasts, youthful, slim, moderate height",
    "loli": "loli, petite, small breasts, childlike, short, tiny",
}

# 角色：booru 属性标签 + 服装自然语言（Illustrious 混合提示）
HEROES = {
    "elin": {
        "tags": "1girl, solo, red hair, long hair, side braid, red eyes",
        "outfit": ("wearing an elegant long black mage robe with crimson flame embroidery and gold trim, "
                   "wide billowing sleeves, black shoulder cape with gold clasp, red ribbon sash at waist, "
                   "long flowing robe skirt, holding a floating glowing flame orb in one hand"),
    },
    "noah": {
        "tags": "1girl, solo, silver hair, bob cut, short hair, blue eyes, gear hairpin",
        "outfit": ("wearing a dark navy blue magitech long coat with brass gear buttons, copper clockwork "
                   "shoulder ornaments, rune-engraved mechanical gauntlet on left arm, brown leather tool "
                   "belt with pouches and vials, knee-length coat with silver trim, holding a glowing blue "
                   "rune device in one hand"),
    },
    "lain": {
        "tags": "1boy, solo, white hair, short hair, blue eyes",
        "outfit": ("wearing full silver-white plate armor with round shoulder pauldrons, engraved chest "
                   "plate with sapphire gem, blue cape draped over one shoulder, armored gauntlets and "
                   "greaves, rune-carved longsword resting on shoulder"),
    },
    "siia": {
        "tags": "1girl, solo, blonde hair, long hair, green eyes",
        "outfit": ("wearing a white and gold priestess robe with gold trim and cross emblem, white hood "
                   "and shoulder mantle, layered robe skirt with light golden ornaments, holding a radiant "
                   "golden healing staff with crystal top"),
    },
}
# 服装补丁：立绘的领口/全身完整度（Illustrious 对服装自然语言理解强）
POSE_TAG = "full body, standing, three-quarter view, looking at viewer, " + BG_STRONG


def build_wf(pos_text, seed, hires=True):
    wf = {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT}},
        "2": {"class_type": "CLIPTextEncode", "inputs": {"text": pos_text, "clip": ["1", 1]}},
        "3": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG, "clip": ["1", 1]}},
        "7": {"class_type": "EmptyLatentImage", "inputs": {"width": 832, "height": 1216, "batch_size": 1}},
        "8": {"class_type": "KSampler", "inputs": {"seed": seed, "steps": 26, "cfg": 6.0,
             "sampler_name": "dpmpp_2m_cfg_pp", "scheduler": "karras", "denoise": 1.0,
             "model": ["1", 0], "positive": ["2", 0], "negative": ["3", 0], "latent_image": ["7", 0]}},
        "9": {"class_type": "VAEDecode", "inputs": {"samples": ["8", 0], "vae": ["1", 2]}},
        "10": {"class_type": "SaveImage", "inputs": {"filename_prefix": "v9p", "images": ["9", 0]}},
    }
    if hires:
        wf["11"] = {"class_type": "LatentUpscale", "inputs": {"samples": ["8", 0],
                     "upscale_method": "nearest-exact", "width": 1664, "height": 2432, "crop": "disabled"}}
        wf["12"] = {"class_type": "KSampler", "inputs": {"seed": seed + 1, "steps": 18, "cfg": 5.5,
             "sampler_name": "dpmpp_2m_cfg_pp", "scheduler": "karras", "denoise": 0.35,
             "model": ["1", 0], "positive": ["2", 0], "negative": ["3", 0], "latent_image": ["11", 0]}}
        wf["9"] = {"class_type": "VAEDecode", "inputs": {"samples": ["12", 0], "vae": ["1", 2]}}
    return wf


def gen(client, name, wf, out_dir):
    pid = client.submit(wf)
    entry = client.wait_history(pid, timeout=900)
    return client.download_outputs(entry, out_dir, name)


def main():
    force = "--force" in sys.argv
    client = ComfyClient(HOST, token=TOKEN)
    progress = OUT / "_PROGRESS.json"
    done = set()
    if progress.exists() and not force:
        done = set(json.loads(progress.read_text(encoding="utf-8")))

    tasks = []  # (name, wf)
    seed = 2026082400
    # 试跑：艾琳少女 / 诺亚御姐 / 莱恩 各 1（hires）
    samples = [("elin", "youth"), ("noah", "mature"), ("lain", None)]
    for i, (hid, bkey) in enumerate(samples):
        hero = HEROES[hid]
        if bkey:
            body = BODY_TAGS[bkey] + ", "
        else:
            body = ""
        pos = f"{QPOS}, {body}{hero['tags']}, {hero['outfit']}, {POSE_TAG}"
        tasks.append((f"{hid}_{bkey or 'base'}_hires", build_wf(pos, seed + i * 17)))

    print(f"[plan] 共 {len(tasks)} 张试跑（Illustrious XL v2.0 + Hires fix）")
    ok, fail = 0, []
    for i, (name, wf) in enumerate(tasks):
        if name in done:
            print(f"[{i+1}/{len(tasks)}] {name} 已存在，跳过")
            ok += 1
            continue
        try:
            gen(client, name, wf, OUT / "portraits")
            done.add(name)
            try:
                progress.write_text(json.dumps(sorted(done)), encoding="utf-8")
            except PermissionError:
                pass  # 进度文件偶发锁定不中断生成本身
            ok += 1
            print(f"[{i+1}/{len(tasks)}] {name} ✅ ({len(done)}/{len(tasks)})")
        except Exception as e:
            fail.append((name, str(e)[:200]))
            print(f"[{i+1}/{len(tasks)}] {name} ❌ {str(e)[:200]}")
    print(f"=== 完成：成功 {ok}/{len(tasks)}，失败 {len(fail)} ===")
    for n, e in fail:
        print(f"  {n}: {e}")


if __name__ == "__main__":
    main()
