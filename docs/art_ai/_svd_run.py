import sys
sys.path.insert(0, r"D:/30DAYS/docs/art_ai")
from pathlib import Path
from comfy_client import ComfyClient
TOKEN = "$2b$12$1kK2TTR/k/1FDPgDYheTDO3BuSlPdE6e.2cwz916eSiTWvJOLkoa."
client = ComfyClient("http://127.0.0.1:18001", token=TOKEN)
base = sorted(Path("D:/30DAYS/docs/art_ai/output_abc/final_完美像素/动作帧小样/_raw").glob("云霓·中式古侠_idle_1*.png"))[0]
img_name = client.upload_image(base)
wf = {
    "1": {"class_type": "LoadImage", "inputs": {"image": img_name}},
    "2": {"class_type": "easy svdLoader", "inputs": {
        "ckpt_name": "SVD/svd_xt.safetensors", "vae_name": "Baked VAE", "clip_name": "None",
        "init_image": ["1", 0], "resolution": "768 x 768",
        "empty_latent_width": 768, "empty_latent_height": 768,
        "video_frames": 20, "motion_bucket_id": 150, "fps": 12, "augmentation_level": 0.15}},
    "7": {"class_type": "CLIPVisionLoader", "inputs": {"clip_name": "clip_vision_h.safetensors"}},
    "3": {"class_type": "SVD_img2vid_Conditioning", "inputs": {
        "clip_vision": ["7", 0], "init_image": ["1", 0], "vae": ["2", 2],
        "width": 768, "height": 768, "video_frames": 20, "fps": 8,
        "motion_bucket_id": 150, "augmentation_level": 0.15}},
    "4": {"class_type": "KSampler", "inputs": {"seed": 95001, "steps": 20, "cfg": 2.5,
         "sampler_name": "euler", "scheduler": "normal", "denoise": 1.0,
         "model": ["2", 1], "positive": ["3", 0], "negative": ["3", 1], "latent_image": ["3", 2]}},
    "5": {"class_type": "VAEDecode", "inputs": {"samples": ["4", 0], "vae": ["2", 2]}},
    "6": {"class_type": "SaveAnimatedPNG", "inputs": {"images": ["5", 0], "filename_prefix": "svd_idle", "fps": 8.0, "compress_level": 4}},
}
pid = client.submit(wf)
print("pid:", pid)
entry = client.wait_history(pid, timeout=900)
saved = client.download_outputs(entry, Path("D:/30DAYS/docs/art_ai/output_abc/final_完美像素/动作帧小样/云霓·中式古侠"), "SVD动画")
print("DONE", saved)
