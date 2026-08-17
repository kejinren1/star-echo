#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""服务器端 WD14 onnx 本地反推（免联网）"""
import glob, os, csv, sys
import numpy as np
import onnxruntime as ort
from PIL import Image

MODEL = "/root/ComfyUI/custom_nodes/ComfyUI-WD14-Tagger/models/wd-v1-4-vit-tagger-v2.onnx"
CSV = "/root/ComfyUI/custom_nodes/ComfyUI-WD14-Tagger/models/wd-v1-4-vit-tagger-v2.csv"
THRESH = 0.35

tags = []
with open(CSV, encoding="utf-8") as f:
    rdr = csv.reader(f)
    next(rdr, None)  # 跳过 header
    for row in rdr:
        if len(row) >= 2 and row[1].strip():
            tags.append(row[1].strip())
print(f"标签表: {len(tags)} 条", flush=True)

session = ort.InferenceSession(MODEL, providers=["CPUExecutionProvider"])
inp = session.get_inputs()[0]
out = session.get_outputs()[0]
print(f"ONNX INPUT: {inp.shape} OUTPUT: {out.shape}", flush=True)

def infer(path):
    im = Image.open(path).convert("RGB").resize((448, 448), Image.BILINEAR)
    arr = np.array(im, dtype=np.float32)  # 0-255 值域（模型期望）
    arr = arr[None]  # NHWC: [1,448,448,3]
    logits = session.run([out.name], {inp.name: arr})[0][0]
    probs = logits  # 输出已是概率 0-1
    idx = np.where(probs > THRESH)[0]
    order = idx[np.argsort(probs[idx])[::-1]]
    kept = [tags[i] for i in order if i < len(tags)]
    return ", ".join(kept)

out_path = sys.argv[1] if len(sys.argv) > 1 else "/tmp/wd14_tags_final.txt"
with open(out_path, "w", encoding="utf-8") as fo:
    for f in sorted(glob.glob("/root/ComfyUI/input/refs_wd/*.png")):
        name = os.path.basename(f)
        try:
            t = infer(f)
        except Exception as e:
            t = f"ERR {e}"
        print(f"{name}: {t}", flush=True)
        fo.write(f"{name}: {t}\n")
        fo.flush()
print("DONE ->", out_path, flush=True)
