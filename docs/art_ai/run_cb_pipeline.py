#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""C+B 组合完整管线：IPAdapter 重构母图 → 像素模型 img2img → 128/64/32 降采样。
用法: python run_cb_pipeline.py [--roles 傀影,若叶睦] [--skip-c] [--quant]
"""
import argparse
import shutil
import sys
from pathlib import Path

sys.path.insert(0, r"D:/30DAYS/docs/art_ai")
from comfy_client import ComfyClient, load_library, build_prompt, split_sampler  # noqa

TOKEN = "$2b$12$1kK2TTR/k/1FDPgDYheTDO3BuSlPdE6e.2cwz916eSiTWvJOLkoa."
HOST = "http://127.0.0.1:18001"
CKPT_XL = "Neta Art XL 二次元角色 （更新V2）_V2.0.safetensors"
CKPT_PIXEL = "aziibpixelmix_v10.safetensors"
CLIP_VISION = "CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors"
LIB = load_library()

ROLES = [  # (角色名, 源立绘文件名)
    ("安洁莉娜", "立绘_予愿安洁莉娜_1"), ("傀影", "立绘_傀影_1"),
    ("棘刺", "立绘_棘刺_1"), ("狮蝎", "立绘_狮蝎_1"),
    ("维什戴尔", "立绘_维什戴尔_1"), ("若叶睦", "立绘_若叶睦_1"),
    ("莱欧斯", "立绘_莱欧斯_1"), ("陈", "立绘_赤刃明霄陈_1"),
    ("赫拉格", "立绘_赫拉格_1"), ("遥", "立绘_遥_1"),
    ("重岳", "立绘_重岳_1"), ("龙舌兰", "立绘_龙舌兰_1"),
]

OUT_ROOT = Path("D:/30DAYS/docs/art_ai/output_abc/CB_组合")
SRC_DIR = Path("D:/30DAYS/测试立绘")


def build_c_wf(image_name, prompt, negative, seed):
    sampler, scheduler = split_sampler(LIB["params"]["portrait"]["sampler"])
    return {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT_XL}},
        "2": {"class_type": "CLIPTextEncode", "inputs": {"text": prompt, "clip": ["1", 1]}},
        "3": {"class_type": "CLIPTextEncode", "inputs": {"text": negative, "clip": ["1", 1]}},
        "4": {"class_type": "LoadImage", "inputs": {"image": image_name, "upload": "image"}},
        "6": {"class_type": "IPAdapterUnifiedLoader",
              "inputs": {"model": ["1", 0], "preset": "PLUS (high strength)"}},
        "7": {"class_type": "IPAdapter",
              "inputs": {"model": ["6", 0], "ipadapter": ["6", 1], "image": ["4", 0],
                         "weight": 0.8, "start_at": 0.0, "end_at": 1.0,
                         "weight_type": "standard"}},
        "8": {"class_type": "EmptyLatentImage",
              "inputs": {"width": 768, "height": 1024, "batch_size": 1}},
        "9": {"class_type": "KSampler",
              "inputs": {"seed": seed, "steps": 28, "cfg": 7.0,
                         "sampler_name": sampler, "scheduler": scheduler, "denoise": 1.0,
                         "model": ["7", 0], "positive": ["2", 0],
                         "negative": ["3", 0], "latent_image": ["8", 0]}},
        "10": {"class_type": "VAEDecode", "inputs": {"samples": ["9", 0], "vae": ["1", 2]}},
        "11": {"class_type": "SaveImage",
               "inputs": {"filename_prefix": "star_echo_c", "images": ["10", 0]}},
    }


def prep_512(src_img: Path, dst: Path) -> None:
    from PIL import Image
    im = Image.open(src_img).convert("RGB")
    im.thumbnail((512, 512), Image.LANCZOS)
    canvas = Image.new("RGB", (512, 512), (255, 255, 255))
    canvas.paste(im, ((512 - im.size[0]) // 2, (512 - im.size[1]) // 2))
    canvas.save(dst)


def downsample(src: Path, dst_dir: Path) -> None:
    from PIL import Image
    im = Image.open(src)
    for size in (128, 64, 32):
        im.resize((size, size), Image.NEAREST).save(dst_dir / f"{size}px.png")


def quant64(src: Path, dst: Path) -> None:
    """img2sprite 调色板量化（COLOR_DICT）。"""
    import subprocess
    py = r"C:/Users/Administrator/.workbuddy/binaries/python/envs/default/Scripts/python.exe"
    r = subprocess.run([py, "D:/30DAYS/tools/img2sprite.py",
                        "--input", str(src), "--output", str(dst),
                        "--size", "64", "--bg", "keep",
                        "--palette", "D:/30DAYS/ART/COLOR_DICT.json"],
                       capture_output=True, text=True, timeout=120)
    if r.returncode != 0:
        print(f"  [quant] 失败: {r.stderr[-200:]}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--roles", default=None, help="逗号分隔角色名，默认全部 12")
    ap.add_argument("--skip-c", action="store_true", help="跳过 C 重构（已有母图）")
    ap.add_argument("--quant", action="store_true", help="64px 调色板量化")
    ap.add_argument("--seed", type=int, default=12345)
    args = ap.parse_args()

    roles = [r for r, _ in ROLES] if not args.roles else [x.strip() for x in args.roles.split(",")]
    client = ComfyClient(HOST, token=TOKEN)
    results = []

    for name in roles:
        rname = dict(ROLES)[name]
        d = OUT_ROOT / name
        d.mkdir(parents=True, exist_ok=True)
        try:
            if not args.skip_c or not (d / "1_母图.png").exists():
                prep = Path(f"D:/30DAYS/docs/art_ai/output_abc/inputs_1024/{rname}.png")
                if not prep.exists():
                    from PIL import Image
                    im = Image.open(SRC_DIR / f"{rname}.png")
                    if im.mode == "RGBA":
                        bg = Image.new("RGB", im.size, (255, 255, 255))
                        bg.paste(im, mask=im.split()[3])
                        im = bg
                    im.thumbnail((1024, 1024), Image.LANCZOS)
                    prep.parent.mkdir(exist_ok=True)
                    im.save(prep)
                img_name = client.upload_image(prep)
                prompt, negative = build_prompt(
                    LIB, "character", "style_heroic_cel", None, None, None,
                    None, None, None, "portrait")
                pid = client.submit(build_c_wf(img_name, prompt, negative, args.seed))
                print(f"[{name}] C 重构 prompt_id={pid}")
                entry = client.wait_history(pid, timeout=900)
                saved = client.download_outputs(entry, d, name)
                if saved:
                    shutil.move(d / saved[0]["file"], d / "1_母图.png")
                print(f"[{name}] C 母图 OK")
            # 像素化
            prep512 = Path(f"D:/30DAYS/docs/art_ai/output_abc/inputs_512/CB_{name}.png")
            prep_512(d / "1_母图.png", prep512)
            img_name2 = client.upload_image(prep512)
            prompt2, negative2 = build_prompt(
                LIB, "character", "style_heroic_cel", None, None, None,
                None, None, None, "portrait")
            # 用 comfy_client 的 img2img workflow
            from comfy_client import make_img2img_workflow
            wf = make_img2img_workflow(LIB, "portrait", prompt2, negative2,
                                       args.seed + 1, img_name2, 0.4,
                                       checkpoint=CKPT_PIXEL)
            pid2 = client.submit(wf)
            print(f"[{name}] 像素化 prompt_id={pid2}")
            entry2 = client.wait_history(pid2, timeout=900)
            saved2 = client.download_outputs(entry2, d, name)
            if saved2:
                shutil.move(d / saved2[0]["file"], d / "2_像素化.png")
            downsample(d / "2_像素化.png", d)
            if args.quant:
                quant64(d / "64px.png", d / "64px_quant.png")
            results.append((name, "OK"))
            print(f"[{name}] ✅ 完成")
        except Exception as e:
            results.append((name, f"FAIL: {e}"))
            print(f"[{name}] ❌ {e}")

    (OUT_ROOT / "_PROGRESS.md").write_text(
        "\n".join(f"{n}: {s}" for n, s in results), encoding="utf-8")
    print("=== 结果 ===")
    for n, s in results:
        print(f"  {n}: {s}")


if __name__ == "__main__":
    main()
