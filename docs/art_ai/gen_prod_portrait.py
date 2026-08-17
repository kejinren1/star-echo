#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_prod_portrait.py — 《星骸回响》立绘轨生产脚本（2026-08-15 定稿）
============================================================
两条路线（用户 08-15 拍板固化）：
  路线 A：虹膜强化 + 衣物权重平衡（细节优先）——style7_balance 验证版
  路线 B：基础眼部词简洁版（构图优先）——style7_plain seed888 验证版
公共配置（08-15 定稿）：
  - 模型：NoobAI-XL-v1.1.safetensors（立绘轨主模型）
  - 分辨率：1024×1536 直出（禁用 latent nearest hires——糊，见 HANDBOOK 踩坑）
  - 画风：WD14 反推参考立绘共性（black background/solo/full_body/looking_at_viewer/低饱和暖光）
  - 采样：dpmpp_2m+karras · 32 步 · CFG 6.5
用法：
  python gen_prod_portrait.py --route A --count 3 --seed-base 20260815
  python gen_prod_portrait.py --route B --count 5
产物：生成留服务器 /root/ComfyUI/output/（SSH cat 拉取，勿走公网 /view 下载）
"""
import argparse
import json
import sys
import time
import urllib.request

HOST = "http://127.0.0.1:18001"
TOKEN = "$2b$12$.TAugRmvKlv5LxFdgOXP4.7mFvhRY2GpvKmr2S8kvAVB9bP/ivSae"
CKPT = "NoobAI-XL-v1.1.safetensors"

STYLE_BLOCK = ("1girl, solo, long hair, blue hair, blue eyes, full body, standing, "
               "looking at viewer, black background, simple background, "
               "elegant dress, thighhighs, gloves, "
               "low-key cinematic lighting, warm rim light, muted desaturated color palette")

# 路线 A：虹膜强化 + 衣物权重平衡
ROUTE_A_POS = ("masterpiece, best quality, highly detailed, sharp focus, clean lineart, "
               "1girl, solo, (long hair:1.2), blue hair, blue eyes, full body, standing, "
               "looking at viewer, black background, simple background, "
               "(elegant dress:1.25), (clean detailed outfit:1.2), thighhighs, gloves, "
               "low-key cinematic lighting, warm rim light, muted desaturated color palette, "
               "(masterpiece iris:1.3), (detailed iris:1.35), (sparkling eyes:1.25), "
               "(iris reflection:1.2), specular highlights in eyes, (long eyelashes:1.25), "
               "(detailed face:1.2), sharp facial features")

# 路线 B：基础眼部词简洁版
ROUTE_B_POS = ("masterpiece, best quality, highly detailed, sharp focus, clean lineart, "
               "1girl, solo, long hair, blue hair, blue eyes, full body, standing, "
               "looking at viewer, black background, simple background, elegant dress, "
               "thighhighs, gloves, low-key cinematic lighting, warm rim light, "
               "muted desaturated color palette, "
               "detailed eyes, detailed iris, sparkling eyes, long eyelashes, "
               "detailed face, beautiful face, sharp facial features")

NEG = ("worst quality, low quality, blurry, bad anatomy, extra fingers, "
       "watermark, text, logo, signature, "
       "bad eyes, deformed iris, ugly eyes, poor facial details, "
       "blurry face, distorted face, bad face, plain eyes, flat iris, dull eyes, "
       "cluttered outfit, messy clothes, tangled hair, noisy background")


def api(path, payload=None):
    url = HOST + path
    data = json.dumps(payload).encode() if payload else None
    req = urllib.request.Request(url, data=data, method="POST" if payload else "GET")
    req.add_header("Authorization", "Bearer " + TOKEN)
    req.add_header("Content-Type", "application/json")
    with urllib.request.urlopen(req, timeout=90) as r:
        return json.loads(r.read())


def make_wf(pos, seed, prefix):
    return {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT}},
        "2": {"class_type": "EmptyLatentImage", "inputs": {"width": 1024, "height": 1536, "batch_size": 1}},
        "3": {"class_type": "CLIPTextEncode", "inputs": {"text": pos, "clip": ["1", 1]}},
        "4": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG, "clip": ["1", 1]}},
        "5": {"class_type": "KSampler", "inputs": {"seed": seed, "steps": 32, "cfg": 6.5,
              "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 1.0,
              "model": ["1", 0], "positive": ["3", 0], "negative": ["4", 0], "latent_image": ["2", 0]}},
        "6": {"class_type": "VAEDecode", "inputs": {"samples": ["5", 0], "vae": ["1", 2]}},
        "7": {"class_type": "SaveImage", "inputs": {"filename_prefix": prefix, "images": ["6", 0]}},
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--route", choices=["A", "B"], required=True)
    ap.add_argument("--count", type=int, default=3)
    ap.add_argument("--seed-base", type=int, default=20260815)
    args = ap.parse_args()

    pos = ROUTE_A_POS if args.route == "A" else ROUTE_B_POS
    print(f"[{args.route}] 路线启动 count={args.count} seed_base={args.seed_base}", flush=True)
    for i in range(args.count):
        seed = args.seed_base + i
        prefix = f"prod_{args.route}_{i+1}"
        wf = make_wf(pos, seed, prefix)
        try:
            resp = api("/prompt", {"prompt": wf})
        except Exception as e:
            print(f"SUBMIT_FAIL {prefix}: {e}", flush=True)
            continue
        pid = resp.get("prompt_id")
        while True:
            time.sleep(5)
            try:
                h = api(f"/history/{pid}")
            except Exception:
                time.sleep(10)
                continue
            if pid in h:
                st = h[pid]["status"].get("status_str", "")
                if st == "error":
                    for m in h[pid]["status"].get("messages", []):
                        if m[0] == "execution_error":
                            print("NODE_ERR:", m[1].get("exception_message", "")[:200], flush=True)
                    break
                for nid, o in h[pid]["outputs"].items():
                    for img in o.get("images", []):
                        print(f"DONE {prefix} seed{seed}: {img['filename']}", flush=True)
                break
    print("ALL_FINISHED", flush=True)


if __name__ == "__main__":
    main()
