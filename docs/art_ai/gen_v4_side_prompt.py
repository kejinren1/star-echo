#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_v4_side_prompt.py — v4：姿势词驱动侧身局内模型（弃用 ControlNet 骨架，用户拍板）
试词 → 本地 L/R 分析选有效姿势词 → 全量 4 主角。
"""
import json
import sys
from pathlib import Path

sys.path.insert(0, r"D:/30DAYS/docs/art_ai")
from comfy_client import ComfyClient  # noqa

HOST = "http://61.157.218.59:31071"
TOKEN = "$2b$12$hJjmO84moQQWigWYsGH10O/yHLqLwBgIPZmwa10BSbTVoGQ6fi4ze"
CKPT_PIX = "aziibpixelmix_v10.safetensors"
OUT = Path("D:/30DAYS/docs/art_ai/output_abc/v4_side_20260815")
OUT.mkdir(parents=True, exist_ok=True)

NEG = ("blurry, low quality, stiff pose, half body, portrait, close-up, crop, ugly, deformed, "
       "child, loli, flat chest, effects, particles, magic, aura, background decoration, "
       "dark background, colored background, red background, gradient background, "
       "ground shadow, vignette, floor, multiple characters, text, watermark, modern clothes, "
       "jeans, t-shirt, hoodie, military uniform, modern machinery, gun, rifle, front facing, "
       "facing viewer, straight on")

# 姿势词候选（3 组常见表达，测哪组能驱动侧身）
POSES = {
    "side": "side view, character standing sideways facing right, side-facing sprite",
    "threeq": "three-quarter view, body angled toward the right side, face turned slightly toward viewer",
    "turn": "character turned to the right, body rotated sideways, side profile, facing right",
}
BG = (", crisp pixel art sprite, bold clean palette, clean silhouette, full body visible head to toe, "
      "pure white background, solid flat uniform background, no gradient, no ground shadow, "
      "no rim light, no vignette, no floor, no decorations")

HEROES = {
    "elin": "young woman, long crimson red hair, red eyes, elegant classic fantasy mage, long black robe with crimson and gold flame embroidery, holding a floating glowing flame orb, dignified fire mage",
    "noah": "young woman, short silver blue hair, blue eyes, magitech tinkerer of a fantasy workshop, ornate dark navy coat with brass rune gears and copper clockwork ornaments, small floating cogwork fairy companion, holding a glowing rune device, fantasy engineer",
    "lain": "young man, short white hair, sharp blue eyes, knight errant of a fantasy kingdom, silver and white full armor with blue cape, rune-carved longsword resting on shoulder, heroic knight",
    "siia": "young woman, long soft golden hair, gentle green eyes, gentle cleric of a fantasy church, white and gold priestess robe with light ornaments, radiant healing staff in hand, warm healer",
}


def build_wf(text, seed):
    wf = {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT_PIX}},
        "2": {"class_type": "CLIPTextEncode", "inputs": {"text": text, "clip": ["1", 1]}},
        "3": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG, "clip": ["1", 1]}},
        "7": {"class_type": "EmptyLatentImage", "inputs": {"width": 768, "height": 768, "batch_size": 1}},
        "8": {"class_type": "KSampler", "inputs": {"seed": seed, "steps": 28, "cfg": 6.5,
             "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 1.0,
             "model": ["1", 0], "positive": ["2", 0], "negative": ["3", 0], "latent_image": ["7", 0]}},
        "9": {"class_type": "VAEDecode", "inputs": {"samples": ["8", 0], "vae": ["1", 2]}},
        "10": {"class_type": "SaveImage", "inputs": {"filename_prefix": "v4side", "images": ["9", 0]}},
    }
    return wf


def gen(client, name, wf, out_dir):
    pid = client.submit(wf)
    entry = client.wait_history(pid, timeout=900)
    return client.download_outputs(entry, out_dir, name)


def side_score(path):
    """侧身度：主体像素左右分布偏差（0=完全对称正面，越偏离 1 越侧）"""
    from PIL import Image
    im = Image.open(path).convert("RGBA")
    w, h = im.size
    px = im.load()
    L = R = 0
    for y in range(h):
        for x in range(w):
            if px[x, y][3] > 128:
                if x < w * 0.42:
                    L += 1
                elif x > w * 0.58:
                    R += 1
    return (L / R) if R else 1.0


def main():
    client = ComfyClient(HOST, token=TOKEN)
    progress = OUT / "_PROGRESS.json"
    done = set()
    if progress.exists() and "--force" not in sys.argv:
        done = set(json.loads(progress.read_text(encoding="utf-8")))

    seed = 2026081800
    tasks = []
    # 1) 试词：艾琳 × 3 姿势词
    for pi, (pk, pw) in enumerate(POSES.items()):
        text = f"{HEROES['elin']}, {pw}" + BG
        tasks.append((f"test_elin_{pk}", "tests", text, seed + pi))
    # 2) 全量（用全部词各出一张，本地择优——词不同出图不同，让用户挑朝向也行）
    for i, (hid, desc) in enumerate(HEROES.items()):
        for pi, (pk, pw) in enumerate(POSES.items()):
            text = f"{desc}, {pw}" + BG
            tasks.append((f"{hid}_{pk}", "models", text, seed + 100 + i * 10 + pi))

    print(f"[plan] 共 {len(tasks)} 张（艾琳 3 试词 + 4 主角 × 3 词）")
    ok, fail = 0, []
    for i, (name, sub, text, sd) in enumerate(tasks):
        if name in done:
            print(f"[{i+1}/{len(tasks)}] {name} 已存在，跳过")
            ok += 1
            continue
        try:
            gen(client, name, build_wf(text, sd), OUT / sub)
            done.add(name)
            progress.write_text(json.dumps(sorted(done)), encoding="utf-8")
            ok += 1
            print(f"[{i+1}/{len(tasks)}] {name} ✅ ({len(done)}/{len(tasks)})")
        except Exception as e:
            fail.append((name, str(e)[:120]))
            print(f"[{i+1}/{len(tasks)}] {name} ❌ {str(e)[:120]}")

    # 3) 侧身度报告
    print("\n=== 侧身度报告（L/R 越偏离 1 越侧身）===")
    from PIL import Image
    for f in sorted((OUT / "models").glob("*.png")):
        r = side_score(f)
        mark = "侧身✓" if (r < 0.85 or r > 1.18) else "≈正面"
        print(f"  {f.name}: L/R={r:.2f} {mark}")
    for f in sorted((OUT / "tests").glob("*.png")):
        r = side_score(f)
        print(f"  test {f.name}: L/R={r:.2f}")

    print(f"=== 完成：成功 {ok}/{len(tasks)}，失败 {len(fail)} ===")
    for n, e in fail:
        print(f"  {n}: {e}")


if __name__ == "__main__":
    main()
