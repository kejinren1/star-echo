#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_portraits_final.py — 12 角色立绘最终量产（2026-08-16 15:40 定稿管线）
管线：txt2img 直出 1024×1536 + IPAdapter 0.45(STANDARD, end0.7) + 灰底 + 8头身 + 分组眼部
服装词 = WD14 反推定稿图标签对齐（艾琳已验证 ✅）
每角色 2 变体 seed
"""
import json, time, urllib.request

HOST = "http://127.0.0.1:18001"
TOKEN = "$2b$12$.TAugRmvKlv5LxFdgOXP4.7mFvhRY2GpvKmr2S8kvAVB9bP/ivSae"
CKPT = "NoobAI-XL-v1.1.safetensors"

STYLE = ("solid pure gray background, flat uniform background, "
         "low-key cinematic lighting, warm rim light, muted desaturated color palette, "
         "with margin, completely inside frame, no cropping")
POSEY = "full body, standing, three-quarter view, body turned slightly to the side"
QUALITY = ("masterpiece, best quality, highly detailed, sharp focus, clean lineart, "
           "intricate details, rich fabric folds and shadows, detailed material texture, "
           "detailed hair strands with flowing direction, professional illustration")

EYE_F = "detailed eyes, detailed iris, natural eyelashes, elegant mature face, detailed face, sharp facial features"
EYE_M = "detailed eyes, detailed iris, mature masculine face, defined jawline, sharp focused gaze"
EYE_B = "fierce menacing eyes, sharp detailed iris, ferocious gaze, detailed fur texture"
EYE_I = "detailed ominous eye, sharp detailed iris, fine gold frame detail"

# 服装词 = WD14 反推对齐（结构标签采纳，颜色以定稿为准）
CHARS = {
    "b07": ("F", "human",
             "1girl, tall slender goddess, very long silky black hair, pale skin, "
             "black sleeveless dress with high slit, thigh-high slit dress, "
             "deep side slit, long high slit skirt, "
             "high collar covering the neck, turtleneck collar, "
             "high turtleneck collar, tall collar covering the neck, "
             "closed modest neckline, high-neck dress, "
             "exposed long bare legs, elegant long legs, "
             "bare shoulders, no horns, "
             "intricate dress details, elegant shading, refined fabric folds, "
             "detailed hair strands with flowing direction, hair light reflection, "
             "cinematic lighting, luminous highlights, "
             "hollow void in her abdomen, cosmic emptiness, mysterious divine presence"),
}

NEG = ("worst quality, low quality, blurry, bad anatomy, extra fingers, watermark, text, logo, signature, "
       "bad eyes, deformed iris, ugly eyes, poor facial details, blurry face, distorted face, bad face, "
       "cluttered outfit, messy clothes, tangled hair, noisy background, "
       "effects, magic aura, glow, particles, floating objects, "
       "background scene, environment, scenery, gradient background, "
       "background texture, wall, floor, ground shadow, props, furniture, objects, "
       "background details, decorative background, scene elements, "
       "out of frame, cropped figure, pixel art, pixelated, mosaic, flat colors, "
       "large head, small body, short legs, tiny body, oversized head, "
       "chibi, loli, kid, childlike, baby face, petite, short stature, midget, "
       "plain face, featureless face, distorted face, warped face, deformed face, "
       "simple drawing, childish drawing, stick figure, crayon drawing, flat shading, no shading")







def api(path, payload=None):
    url = HOST + path
    data = json.dumps(payload).encode() if payload else None
    req = urllib.request.Request(url, data=data, method="POST" if payload else "GET")
    req.add_header("Authorization", "Bearer " + TOKEN)
    req.add_header("Content-Type", "application/json")
    with urllib.request.urlopen(req, timeout=120) as r:
        return json.loads(r.read())

def main():
    seed_base = 20263016
    total = 0
    for i, (key, (grp, kind, feat)) in enumerate(CHARS.items()):
        eye = {"F": EYE_F, "M": EYE_M, "B": EYE_B, "I": EYE_I}[grp]
        if kind == "human":
            pose = POSEY
        elif kind == "stand":
            pose = "full body standing upright, standing on two legs, "
            "upright posture, full body view"
        elif kind == "animal":
            pose = "full body quadrupedal animal, natural four-leg stance, all fours"
        else:
            pose = "a single ornate mirror centered, vertical composition"
        pos = f"{QUALITY}, {feat}, {pose}, {STYLE}, {eye}"
        neg = NEG
        if key == "b07":
            neg += ", horns, antlers, horned headdress"
        elif key == "b04":
            neg += ", childlike, youthful face, baby face, cute face, teenager, boyish, young boy, childish features, short legs"
        if grp == "M":
            neg += ", long eyelashes, feminine face, pretty boy"
        elif grp == "B":
            neg += ", long eyelashes, feminine face, cute face"
        elif grp == "I":
            neg += ", person, human, character, girl, boy, face, portrait"
        variants = [
            ("standing with hands gently clasped in front, serene pose, calm eyes looking forward",
             "straight flowing hair, long straight hair"),
            ("one hand raised in blessing, elegant gesture, gentle eyes looking slightly down",
             "hair in a high ponytail, flowing ponytail"),
            ("arms crossed gently, dignified serene pose, calm eyes looking to the side",
             "half up half down hair, elegant updo"),
            ("hands resting at sides, gentle breeze effect, soft eyes looking forward",
             "loose flowing hair, slightly wavy"),
        ]
        cnt = 8
        for n in range(cnt):
            weight = 0.3
            var = variants[n % 4]
            var_pos = (f"{pos}, {var[0]}, {var[1]}, "
            "perfectly clean flat gray background, solid uniform gray backdrop, "
            "absolutely plain background, no background detail, no texture, no gradient")
            seed = seed_base + i * 10 + n
            prefix = f"b07V7_{key}_{n+1}"
            wf = {
                "1": {"class_type": "LoadImage", "inputs": {"image": f"refs_768/{key}_768.png"}},
                "2": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT}},
                "3": {"class_type": "easy ipadapterApply", "inputs": {
                    "model": ["2", 0], "image": ["1", 0],
                    "preset": "STANDARD (medium strength)", "lora_strength": 0.3, "provider": "CUDA",
                    "weight": weight, "weight_faceidv2": 1.0, "start_at": 0.0, "end_at": 0.7,
                    "cache_mode": "all", "use_tiled": False}},
                "4": {"class_type": "CLIPTextEncode", "inputs": {"text": var_pos, "clip": ["2", 1]}},
                "5": {"class_type": "CLIPTextEncode", "inputs": {"text": neg, "clip": ["2", 1]}},
                "6": {"class_type": "EmptyLatentImage", "inputs": {"width": 1024, "height": 1536, "batch_size": 1}},
                "7": {"class_type": "KSampler", "inputs": {"seed": seed, "steps": 32, "cfg": 6.5,
                      "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 1.0,
                      "model": ["3", 0], "positive": ["4", 0], "negative": ["5", 0], "latent_image": ["6", 0]}},
                "8": {"class_type": "VAEDecode", "inputs": {"samples": ["7", 0], "vae": ["2", 2]}},
                "9": {"class_type": "SaveImage", "inputs": {"filename_prefix": prefix, "images": ["8", 0]}},
            }
            try:
                resp = api("/prompt", {"prompt": wf})
            except Exception as e:
                print(f"SUBMIT_FAIL {prefix}: {e}", flush=True)
                continue
            pid = resp.get("prompt_id")
            while True:
                time.sleep(4)
                try:
                    h = api(f"/history/{pid}")
                except Exception:
                    time.sleep(8)
                    continue
                if pid in h:
                    st = h[pid]["status"].get("status_str", "")
                    if st == "error":
                        for m in h[pid]["status"].get("messages", []):
                            if m[0] == "execution_error":
                                print("NODE_ERR:", m[1].get("exception_message", "")[:150], flush=True)
                        break
                    for nid, o in h[pid]["outputs"].items():
                        for img in o.get("images", []):
                            print(f"DONE {prefix} seed{seed}", flush=True)
                            total += 1
                    break
    print(f"ALL_FINISHED total={total}", flush=True)


if __name__ == "__main__":
    main()
