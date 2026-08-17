#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""run_items_batch.py — 2026-08-15 道具图标量产：items.json 全 54 道具
管线：aziibpixelmix 像素直出 512×512 + 纯白背景强化（用户规范：无背景/纯色背景/与本体反差大）
断点续跑（_PROGRESS），完成后由 post_process_items.py 做抠底→32px→量化→拼图集。
"""
import json
import sys
import time
from pathlib import Path

sys.path.insert(0, r"D:/30DAYS/docs/art_ai")
from comfy_client import ComfyClient  # noqa

HOST = "http://61.157.218.59:31071"
TOKEN = "$2b$12$hJjmO84moQQWigWYsGH10O/yHLqLwBgIPZmwa10BSbTVoGQ6fi4ze"
CKPT_PIX = "aziibpixelmix_v10.safetensors"
OUT = Path("D:/30DAYS/docs/art_ai/output_abc/items_20260815")
OUT.mkdir(parents=True, exist_ok=True)

# 用户 08-15 拍板规范：素材图零背景/纯白灰背景、与本体色大反差、便于抠图
BG_POS = (", crisp pixel art game item icon, centered single object, bold clean flat colors, "
          "pure white background, solid flat uniform white background, no gradient, no shadow, "
          "no ground plane, object only, clean silhouette, high contrast against background")
NEG = ("blurry, low quality, background details, gradient, shadow, ground, floor, table, pedestal, "
       "crate, multiple objects, extra props, text, watermark, frame, border, decoration, letters, "
       "numbers, character, person, hand, body part, vignette")

# id -> (中文名, 英文描述) —— 对齐 items.json 全 54 项
ITEMS = {
    "coffee": ("咖啡", "cup of hot black coffee with rising steam"),
    "helmet": ("头盔", "steel combat helmet with visor"),
    "head_injury": ("创伤", "white bandage wrap around head injury"),
    "injection": ("注射器", "syringe filled with blue liquid"),
    "sneakers": ("速跑鞋", "pair of red running sneakers"),
    "glasses": ("望远镜", "military binoculars"),
    "fertilizer": ("肥料", "green fertilizer spray bottle"),
    "alien_worm": ("外星虫", "alien worm creature with rows of teeth"),
    "feather": ("羽毛", "single white feather"),
    "charcoal": ("木炭", "piece of black charcoal"),
    "boxing_glove": ("拳击手套", "red boxing glove"),
    "lens": ("透镜", "magnifying glass lens"),
    "insanity": ("疯狂", "spiral eye symbol of madness"),
    "jelly": ("果冻", "cup of colorful jelly"),
    "book": ("书本", "ancient closed spell book with clasp"),
    "adrenaline": ("肾上腺素", "small red adrenaline vial"),
    "black_belt": ("黑带", "rolled black martial arts belt"),
    "banner": ("旗帜", "war banner flag on pole"),
    "blood_leech": ("血蛭", "blood leech parasite creature"),
    "bone_dice": ("骰子", "pair of bone dice"),
    "campfire": ("营火", "campfire with flames and logs"),
    "compass": ("罗盘", "brass compass"),
    "blindfold": ("眼罩", "black blindfold cloth"),
    "bait": ("诱饵", "fishing bait worm on hook"),
    "medal": ("奖章", "golden star medal with ribbon"),
    "mushroom": ("蘑菇", "red spotted mushroom"),
    "saw": ("锯子", "hand saw with wooden handle"),
    "alloy": ("合金", "shiny metal alloy ingot"),
    "ball_and_chain": ("铁球链", "iron ball and chain"),
    "glass_cannon": ("玻璃大炮", "mini glass cannon toy"),
    "silver_bullet": ("银弹", "silver bullet with casing"),
    "triangle_of_power": ("力量三角", "glowing golden triangle amulet"),
    "adrenaline_shot": ("肾上腺素注射", "adrenaline shot auto-injector"),
    "guardian_shield": ("护卫盾", "round guardian shield emblem"),
    "radar": ("雷达", "radar device with antenna"),
    "elemental_core": ("元素核心", "glowing elemental core crystal"),
    "blueprint": ("工程图", "rolled blueprint paper"),
    "anvil": ("铁砧", "blacksmith anvil"),
    "ashes": ("灰烬", "pile of gray ashes"),
    "focus": ("焦点", "glowing purple focus gem"),
    "heavy_bullets": ("重型子弹", "stack of heavy rifle bullets"),
    "spider": ("蜘蛛", "black spider"),
    "potato": ("土豆", "brown potato"),
    "elemental_master": ("元素大师徽章", "elemental master badge with four gems"),
    "mech_heart": ("机械之心", "mechanical heart with gears"),
    "se_flame_core": ("烈焰核心", "flaming core orb"),
    "se_mech_core": ("机械核心", "mechanical core with gears"),
    "se_blade_core": ("星刃核心", "star blade core crystal"),
    "resonant_shard": ("共鸣碎晶", "resonant crystal shard"),
    "broken_crown": ("破碎王冠", "broken golden crown"),
    "mech_engine": ("机械引擎", "mechanical engine block"),
    "overload_capacitor": ("过载电容", "overload capacitor with sparks"),
    "executioner_mark": ("处决印记", "executioner axe mark sigil"),
    "last_stand": ("背水一战", "cracked shield last stand emblem"),
}


def build_wf(desc, seed):
    text = desc + BG_POS
    return {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT_PIX}},
        "2": {"class_type": "CLIPTextEncode", "inputs": {"text": text, "clip": ["1", 1]}},
        "3": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG, "clip": ["1", 1]}},
        "7": {"class_type": "EmptyLatentImage", "inputs": {"width": 512, "height": 512, "batch_size": 1}},
        "8": {"class_type": "KSampler", "inputs": {"seed": seed, "steps": 28, "cfg": 6.5,
             "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 1.0,
             "model": ["1", 0], "positive": ["2", 0], "negative": ["3", 0], "latent_image": ["7", 0]}},
        "9": {"class_type": "VAEDecode", "inputs": {"samples": ["8", 0], "vae": ["1", 2]}},
        "10": {"class_type": "SaveImage", "inputs": {"filename_prefix": "item", "images": ["9", 0]}},
    }


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

    seed = 2026081500
    total = len(ITEMS)
    ok, fail = 0, []
    for i, (iid, (zh, desc)) in enumerate(ITEMS.items(), 1):
        if iid in done:
            print(f"[{i}/{total}] {iid} {zh} 已存在，跳过")
            ok += 1
            continue
        try:
            gen(client, iid, build_wf(desc, seed + i), OUT)
            done.add(iid)
            progress.write_text(json.dumps(sorted(done)), encoding="utf-8")
            ok += 1
            print(f"[{i}/{total}] {iid} {zh} ✅ ({len(done)}/{total})")
        except Exception as e:
            fail.append((iid, str(e)[:150]))
            print(f"[{i}/{total}] {iid} {zh} ❌ {str(e)[:150]}")
    print("=== 完成 ===")
    print(f"成功 {ok}/{total}，失败 {len(fail)}")
    for n, e in fail:
        print(f"  {n}: {e}")


if __name__ == "__main__":
    main()
