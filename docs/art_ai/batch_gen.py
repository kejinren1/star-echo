#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
batch_gen.py — 《星骸回响》AI 美术资产库批量生成脚本骨架
=============================================================
读 prompt_library.json → 按「画风 x 要素」组合 prompt → 调 SD.Next/WebUI
txt2img API → 按素材分类落盘 + 写 manifest。

用法（等云主机部署好后）:
    python batch_gen.py --host http://<IP>:7860 --category character --style style_military_cold --count 100
    python batch_gen.py --verify          # 验证模式：每个要素抽 5 张测命中率
    python batch_gen.py --category item --track pixel     # 指定像素直出轨

依赖：仅 Python 标准库（urllib）。
"""
import argparse
import json
import os
import random
import sys
import time
import urllib.request
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
LIBRARY = BASE_DIR / "prompt_library.json"
OUT_ROOT = BASE_DIR / "output"


def load_library() -> dict:
    with open(LIBRARY, encoding="utf-8") as f:
        return json.load(f)


def build_prompt(lib: dict, category: str, style_id: str, world: str,
                 cls: str, outfit: str, hair: str, color: str,
                 accessory: str, track: str) -> str:
    """按 rules.build_template 组合 prompt。传 None 的要素跳过。"""
    base = lib["base"]
    style = lib["styles"][style_id]
    cat = lib["categories"][category]
    cat_block = cat["extra"]

    # 参数槽位名 -> 词库集合键名
    SLOT_TO_COLLECTION = {
        "world": "worlds", "cls": "classes", "outfit": "outfits",
        "hair": "hairstyles", "color": "colors", "accessory": "accessories",
    }

    def pick(collection, key):
        for item in lib[collection]:
            if item["id"] == key:
                return item["en"]
        return None

    parts = [base["quality"], style["prompt_block"]]
    slots = {"world": world, "cls": cls, "outfit": outfit,
             "hair": hair, "color": color, "accessory": accessory}
    for slot, key in slots.items():
        en = pick(SLOT_TO_COLLECTION[slot], key) if key else None
        if en:
            parts.append(en)
    parts.append(cat_block)
    prompt = ", ".join(parts)

    negative = base["negative_pixel"] if track == "pixel" else base["negative"]
    return prompt, negative


def get_params(lib: dict, track: str, prompt: str, negative: str,
               seed: int, extra_loras: bool) -> dict:
    """组装 txt2img API 请求体（SD.Next/WebUI 兼容字段）。"""
    p = lib["params"][track]
    payload = {
        "prompt": prompt,
        "negative_prompt": negative,
        "width": p["width"],
        "height": p["height"],
        "steps": p["steps"],
        "cfg_scale": p["cfg"],
        "sampler_name": p["sampler"],
        "seed": seed,
        "batch_size": lib["params"]["batch"]["size"],
        "save_images": True,
    }
    if track == "pixel" and extra_loras:
        loras = lib["params"]["loras"]
        payload["prompt"] = (
            f"<lora:{loras['pixel_art_xl']['name']}:{loras['pixel_art_xl']['weight']}>, "
            f"<lora:{loras['no_anti_aliasing']['name']}:{loras['no_anti_aliasing']['weight']}>, "
            + payload["prompt"]
        )
    return payload


def call_api(host: str, payload: dict, lib: dict) -> list:
    """POST /sdapi/v1/txt2img，返回 base64 图像列表。"""
    url = host.rstrip("/") + lib["params"]["batch"]["api_path"]
    req = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
    )
    with urllib.request.urlopen(req, timeout=300) as resp:
        return json.loads(resp.read().decode("utf-8"))["images"]


def save_images(images: list, out_dir: Path, prefix: str, start_seed: int) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    manifest = []
    for i, b64 in enumerate(images):
        import base64
        fname = f"{prefix}_seed{start_seed + i:08d}.png"
        (out_dir / fname).write_bytes(base64.b64decode(b64))
        manifest.append({"file": fname, "seed": start_seed + i})
    return manifest


def run_batch(args, lib: dict) -> None:
    """正式批量：按组合规则循环生成，每批独立 seed。"""
    rules = lib["rules"]
    base_seed = args.seed if args.seed is not None else rules["consistency"]["base_seed"]
    out_dir = OUT_ROOT / args.category
    style = lib["styles"][args.style]
    track = args.track or lib["categories"][args.category]["track"]
    prefix = f"{args.category}_{args.style}"
    log = []

    total = args.count
    batch = lib["params"]["batch"]["size"]
    done = 0
    while done < total:
        seed = base_seed + done
        prompt, negative = build_prompt(
            lib, args.category, args.style, args.world, args.cls,
            args.outfit, args.hair, args.color, args.accessory, track,
        )
        payload = get_params(lib, track, prompt, negative, seed,
                             extra_loras=(track == "pixel"))
        images = call_api(args.host, payload, lib)
        saved = save_images(images, out_dir, prefix, seed)
        log.extend(saved)
        done += len(saved)
        print(f"[batch] seed={seed} 批次完成 {done}/{total}")
        time.sleep(0.5)

    (out_dir / "manifest.json").write_text(
        json.dumps({"category": args.category, "track": track,
                    "prompt": prompt, "negative": negative, "items": log},
                   ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"完成：{len(log)} 张 → {out_dir}")


def run_verify(args, lib: dict) -> None:
    """验证模式：每个要素字典项抽 N 张，输出到 verify/<要素名>/，用于人工判命中率。"""
    n = args.count or 5
    out_root = OUT_ROOT / "verify"
    # 待验证集合 -> 对应 build_prompt 槽位
    COLLECTIONS = {
        "hairstyles": "hair", "outfits": "outfit", "classes": "cls",
        "colors": "color", "accessories": "accessory",
    }
    for collection, slot in COLLECTIONS.items():
        for item in lib[collection]:
            kwargs = {slot: item["id"]}
            prompt, negative = build_prompt(
                lib, args.category, args.style,
                kwargs.get("world"), kwargs.get("cls"), kwargs.get("outfit"),
                kwargs.get("hair"), kwargs.get("color"), kwargs.get("accessory"),
                "portrait",
            )
            payload = get_params(lib, "portrait", prompt, negative,
                                 random.randint(1, 999999), extra_loras=False)
            images = call_api(args.host, payload, lib)
            d = out_root / collection / item["id"]
            save_images(images, d, item["id"], 0)
            print(f"[verify] {collection}/{item['zh']} 抽 {len(images)} 张")
    print(f"验证完成 → {out_root}（人工检查命中率，<60% 改词）")


def main():
    global lib_holder
    lib_holder = load_library()
    ap = argparse.ArgumentParser(description="《星骸回响》AI 美术批量生成")
    ap.add_argument("--host", default=lib_holder["params"]["batch"]["host_placeholder"],
                    help="SD.Next/WebUI 地址，如 http://127.0.0.1:7860")
    ap.add_argument("--category", default="character",
                    choices=list(lib_holder["categories"].keys()))
    ap.add_argument("--style", default="style_military_cold",
                    choices=list(lib_holder["styles"].keys()))
    ap.add_argument("--track", choices=["portrait", "pixel"], default=None)
    ap.add_argument("--world", default=None)
    ap.add_argument("--cls", default=None)
    ap.add_argument("--outfit", default=None)
    ap.add_argument("--hair", default=None)
    ap.add_argument("--color", default=None)
    ap.add_argument("--accessory", default=None)
    ap.add_argument("--count", type=int, default=100)
    ap.add_argument("--seed", type=int, default=None)
    ap.add_argument("--verify", action="store_true", help="验证模式：要素抽测")
    args = ap.parse_args()

    if args.verify:
        run_verify(args, lib_holder)
    else:
        run_batch(args, lib_holder)


if __name__ == "__main__":
    main()
