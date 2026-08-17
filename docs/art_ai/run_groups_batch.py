#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""run_groups_batch.py — 局内角色批量（少女10/成年男5/萝莉5/正太5）
规定：只保留主体、统一纯色背景（特效分开做）；文字直出 → perfectPixel 精修 96px。
用法: python run_groups_batch.py [girl|man|loli|shota]  默认全部
"""
import sys
from pathlib import Path

sys.path.insert(0, r"D:/30DAYS/docs/art_ai")
import numpy as np  # noqa
from PIL import Image  # noqa
from comfy_client import ComfyClient, load_library, split_sampler  # noqa
from perfect_pixel_noCV2 import get_perfect_pixel  # noqa

TOKEN = "$2b$12$1kK2TTR/k/1FDPgDYheTDO3BuSlPdE6e.2cwz916eSiTWvJOLkoa."
HOST = "http://127.0.0.1:18001"
CKPT = "aziibpixelmix_v10.safetensors"
CN = "control_v11p_sd15_openpose.pth"
LIB = load_library()
POSE = Path("D:/30DAYS/docs/art_ai/output_abc/pose/待机叉腰骨架_v4_768.png")
OUT = Path("D:/30DAYS/docs/art_ai/output_abc/final_完美像素/局内角色")

BASE_PIX = (", crisp pixel art sprite, bold clean color palette, confident idle stance, "
            "one hand on hip, relaxed casual pose, natural weight shift, clean silhouette, "
            "SOLID uniform plain light background, only the character, no props, no effects, "
            "no particles, no magic aura, no background decoration, full body visible head to toe with margin")
BASE_NEG = ("blurry, low quality, stiff pose, symmetrical pose, boring, half body, portrait, "
            "close-up, crop, bust, headshot, ugly, deformed, background details, props, scenery, "
            "multiple characters, text, watermark, effects, particles, magic, aura, sparkles, background decoration")

GROUPS = {
    "girl": ("少女", "teenage girl, slim young girl, modest bust, ", [  # 10
        ("元气粉发双马尾", "pink twin tails hair, pink eyes, sporty jacket and shorts, energetic smile, athletic girl"),
        ("文静黑长直", "very long black straight hair, black eyes, neat school uniform with skirt, gentle shy expression"),
        ("三无银发少女", "silver white hair, purple eyes, hooded sweatshirt and skirt, emotionless calm face"),
        ("傲娇金发大小姐", "golden blonde twin drill hair, blue eyes, aristocratic dress with ribbons, tsundere pout"),
        ("森林系绿发少女", "green wavy hair with flower clip, green eyes, nature fairy dress with leaves, soft smile"),
        ("冷面蓝发剑士", "short blue hair, blue eyes, knight training outfit with small sword, cool determined look"),
        ("活力橙发网球少女", "orange high ponytail, brown eyes, tennis sportswear and skirt, cheerful grin"),
        ("神秘紫发占卜师", "long purple hair, purple eyes, witch hat and star-patterned dress, mystical smile"),
        ("邻家棕发少女", "brown bob hair, hazel eyes, casual hoodie and jeans, warm friendly smile"),
        ("红发辣妹系少女", "red wavy hair with sunglasses on head, green eyes, denim shorts and crop top, confident smirk"),
    ]),
    "man": ("成年男性", "adult man, ", [  # 5 自编
        ("黑发冷酷剑士", "black short hair, red eyes, dark warrior outfit with long coat, holding katana at side, cold sharp gaze, lean muscular build"),
        ("金发骑士", "golden blond short hair, blue eyes, silver knight armor with cape, broad shoulders, heroic stance"),
        ("白发军装男", "white short hair, amber eyes, dark military greatcoat with medals, stern face, tall imposing"),
        ("壮汉酒馆老板", "brown short hair, brown eyes, rugged tavern keeper apron over shirt, big muscular arms, hearty grin"),
        ("银发法师男", "silver long hair, green eyes, dark blue mage robe with runes, holding staff, wise calm expression"),
    ]),
    "loli": ("萝莉", "loli girl, petite small girl, small child-like girl, flat chest, ", [  # 5
        ("粉发双马尾萝莉", "pink twin tails, pink eyes, frilly lolita dress with ribbons, cute innocent smile"),
        ("白毛兽耳萝莉", "white hair with cat ears and tail, amber eyes, cute dress with paw pattern, playful wink"),
        ("黑发哥特萝莉", "black long hair, crimson eyes, black gothic lace dress with bow, mysterious cute face"),
        ("金发公主萝莉", "golden blonde curls, blue eyes, princess dress with tiny crown, graceful cute pose"),
        ("蓝发水手服萝莉", "blue short hair, blue eyes, sailor uniform, cheerful energetic smile, waving hand"),
    ]),
    "shota": ("正太", "young boy, small cute boy, ", [  # 5 自编
        ("棕发元气正太", "brown short hair, brown eyes, overalls and t-shirt, big bright smile, energetic pose"),
        ("金发贵族正太", "golden blond neat hair, green eyes, small vest and bowtie suit, proper cute noble pose"),
        ("黑发忍者正太", "black short hair, dark eyes, small ninja outfit with scarf, determined cute face"),
        ("红发冒险家正太", "red short spiky hair, amber eyes, tiny explorer outfit with cape and satchel, adventurous grin"),
        ("银发魔法正太", "silver messy hair, blue eyes, small mage robe with star hat, holding tiny wand, curious smile"),
    ]),
}


# 战士特征角色保留武器（其余空手）
WEAPON_ROLES = {"冷面蓝发剑士", "黑发冷酷剑士", "金发骑士"}


def run_group(client, sampler, scheduler, pose_name, gkey, gname, body_desc, roles, seed_base):
    results = []
    d = OUT / gname
    d.mkdir(parents=True, exist_ok=True)
    for i, (rname, desc) in enumerate(roles):
        try:
            neg = BASE_NEG + (", adult, mature, large bust, curvy" if gkey in ("loli", "shota") else
                              (", child, loli, shota, flat chest, small" if gkey == "man" else ""))
            prompt = body_desc + desc + BASE_PIX
            if rname not in WEAPON_ROLES:
                prompt += ", empty hands, no weapon"
            wf = {
                "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT}},
                "2": {"class_type": "CLIPTextEncode", "inputs": {"text": prompt, "clip": ["1", 1]}},
                "3": {"class_type": "CLIPTextEncode", "inputs": {"text": neg, "clip": ["1", 1]}},
                "4": {"class_type": "ControlNetLoader", "inputs": {"control_net_name": CN}},
                "5": {"class_type": "LoadImage", "inputs": {"image": pose_name}},
                "6": {"class_type": "ControlNetApply", "inputs": {"conditioning": ["2", 0], "control_net": ["4", 0], "image": ["5", 0], "strength": 0.9}},
                "7": {"class_type": "EmptyLatentImage", "inputs": {"width": 768, "height": 768, "batch_size": 1}},
                "8": {"class_type": "KSampler", "inputs": {"seed": seed_base + i * 13, "steps": 28, "cfg": 6.5,
                     "sampler_name": sampler, "scheduler": scheduler, "denoise": 1.0,
                     "model": ["1", 0], "positive": ["6", 0], "negative": ["3", 0], "latent_image": ["7", 0]}},
                "9": {"class_type": "VAEDecode", "inputs": {"samples": ["8", 0], "vae": ["1", 2]}},
                "10": {"class_type": "SaveImage", "inputs": {"filename_prefix": "grp", "images": ["9", 0]}},
            }
            pid = client.submit(wf)
            entry = client.wait_history(pid, timeout=600)
            saved = client.download_outputs(entry, OUT / "_raw", f"{gname}_{rname}")
            raw = OUT / "_raw" / saved[0]["file"]
            im = np.array(Image.open(raw).convert("RGB"))
            w, h, out = get_perfect_pixel(im, sample_method="median", min_size=4.0)
            if out is None:
                raise RuntimeError("网格检测失败")
            dd = d / rname
            dd.mkdir(parents=True, exist_ok=True)
            img = Image.fromarray(out.astype(np.uint8))
            img.save(dd / "96px.png")
            img.resize((48, 48), Image.NEAREST).save(dd / "48px.png")
            img.resize((32, 32), Image.NEAREST).save(dd / "32px.png")
            img.resize((288, 288), Image.NEAREST).save(dd / "96px_x3预览.png")
            results.append((f"{gname}/{rname}", "OK"))
            print(f"[{gname}] {rname} ✅")
        except Exception as e:
            results.append((f"{gname}/{rname}", f"FAIL {str(e)[:60]}"))
            print(f"[{gname}] {rname} ❌ {str(e)[:60]}")
    return results


def main():
    args = sys.argv[1:] or list(GROUPS.keys())
    client = ComfyClient(HOST, token=TOKEN)
    sampler, scheduler = split_sampler(LIB["params"]["pixel_direct"]["sampler"])
    pose_name = client.upload_image(POSE)
    OUT.mkdir(parents=True, exist_ok=True)
    all_res = []
    seed_base = 80000
    for gkey in args:
        if gkey not in GROUPS:
            continue
        gname, body_desc, roles = GROUPS[gkey]
        all_res += run_group(client, sampler, scheduler, pose_name, gkey, gname,
                             body_desc, roles, seed_base)
        seed_base += 1000
    (OUT / "_PROGRESS.md").write_text("\n".join(f"{n}: {s}" for n, s in all_res), encoding="utf-8")
    ok = sum(1 for _, s in all_res if s == "OK")
    print(f"=== 完成 {ok}/{len(all_res)} ===")
    for n, s in all_res:
        print(f"  {n}: {s}")


if __name__ == "__main__":
    main()
