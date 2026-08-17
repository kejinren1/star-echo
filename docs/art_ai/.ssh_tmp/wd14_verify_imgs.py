#!/usr/bin/env python3
from PIL import Image
import numpy as np, glob, os

for f in sorted(glob.glob("/root/ComfyUI/input/refs/*.webp"))[:3]:
    try:
        im = Image.open(f)
        rgb = im.convert("RGB")
        arr = np.array(rgb)
        small = arr[::20, ::20].reshape(-1, 3)
        print(os.path.basename(f), "mode:", im.mode, "size:", im.size,
              "mean:", np.round(arr.mean(axis=(0,1)), 1),
              "std:", np.round(arr.std(), 1),
              "unique色(降采样):", len(np.unique(small, axis=0)))
    except Exception as e:
        print(os.path.basename(f), "ERR:", e)
