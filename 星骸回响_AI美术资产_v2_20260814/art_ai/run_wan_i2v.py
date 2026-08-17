#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""run_wan_i2v.py — Wan2.2 I2V 本地图生视频（prompt 指令动作，Lightning 4 步）"""
import sys
from pathlib import Path

sys.path.insert(0, r"D:/30DAYS/docs/art_ai")
from comfy_client import ComfyClient  # noqa

TOKEN = "$2b$12$1kK2TTR/k/1FDPgDYheTDO3BuSlPdE6e.2cwz916eSiTWvJOLkoa."
client = ComfyClient("http://127.0.0.1:18001", token=TOKEN)

IMG = sys.argv[1] if len(sys.argv) > 1 else "D:/30DAYS/docs/art_ai/output_abc/final_完美像素/动作帧小样/_raw/云霓·中式古侠_idle_1_act_00007_.png"
PROMPT = sys.argv[2] if len(sys.argv) > 2 else "The woman gently raises her right hand to wave hello, subtle smile, natural breathing motion"
PREFIX = sys.argv[3] if len(sys.argv) > 3 else "wan_wave"

img_name = client.upload_image(Path(IMG))
wf = {
    "1": {"class_type": "UNETLoader", "inputs": {
        "unet_name": "wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors",
        "weight_dtype": "fp8_e4m3fn"}},
    "2": {"class_type": "CLIPLoader", "inputs": {
        "clip_name": "umt5_xxl_fp8_e4m3fn_scaled.safetensors", "type": "wan"}},
    "3": {"class_type": "VAELoader", "inputs": {"vae_name": "wan2.2_vae.safetensors"}},
    "4": {"class_type": "LoadImage", "inputs": {"image": img_name}},
    "5": {"class_type": "CLIPVisionLoader", "inputs": {"clip_name": "clip_vision_h.safetensors"}},
    "6": {"class_type": "CLIPVisionEncode", "inputs": {"clip_vision": ["5", 0], "image": ["4", 0], "crop": "center"}},
    "7": {"class_type": "CLIPTextEncode", "inputs": {"text": PROMPT, "clip": ["2", 0]}},
    "8": {"class_type": "CLIPTextEncode", "inputs": {"text": "blurry, distorted, deformed, flickering, jitter", "clip": ["2", 0]}},
    "9": {"class_type": "WanImageToVideo", "inputs": {
        "positive": ["7", 0], "negative": ["8", 0], "vae": ["3", 0],
        "width": 768, "height": 768, "length": 41, "batch_size": 1,
        "clip_vision_output": ["6", 0], "start_image": ["4", 0]}},
    "10": {"class_type": "LoraLoader", "inputs": {
        "model": ["1", 0], "clip": ["2", 0],
        "lora_name": "Wan2.2-Lightning_I2V-A14B-4steps-lora_HIGH_fp16.safetensors",
        "strength_model": 1.0, "strength_clip": 1.0}},
    "11": {"class_type": "KSampler", "inputs": {
        "seed": 96001, "steps": 4, "cfg": 5.0,
        "sampler_name": "euler", "scheduler": "simple", "denoise": 1.0,
        "model": ["10", 0], "positive": ["9", 0], "negative": ["9", 1], "latent_image": ["9", 2]}},
    "12": {"class_type": "VAEDecode", "inputs": {"samples": ["11", 0], "vae": ["3", 0]}},
    "13": {"class_type": "SaveAnimatedPNG", "inputs": {"images": ["12", 0], "filename_prefix": PREFIX, "fps": 10.0, "compress_level": 4}},
}
pid = client.submit(wf)
print("Wan pid:", pid)
entry = client.wait_history(pid, timeout=1800)
saved = client.download_outputs(entry, Path("D:/30DAYS/docs/art_ai/output_abc/final_完美像素/动作帧小样"), PREFIX)
print("DONE", saved)
