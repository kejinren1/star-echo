#!/usr/bin/env python3
import numpy as np, onnxruntime as ort
from PIL import Image

session = ort.InferenceSession("/root/ComfyUI/models/interrogators/wd-v1-4-vit-tagger-v2.onnx", providers=["CPUExecutionProvider"])
inp = session.get_inputs()[0]
im = Image.open("/root/ComfyUI/input/refs/Profile_3040103000_01.webp").convert("RGB").resize((448, 448), Image.BILINEAR)
arr = np.array(im, dtype=np.float32) / 255.0
outs = session.run(None, {inp.name: arr[None]})
print("输出个数:", len(outs), "shape:", outs[0].shape)
o = outs[0][0]
print("min:", o.min(), "max:", o.max(), "mean:", round(float(o.mean()), 4))
print(">0.35 数量:", int((o > 0.35).sum()))
print(">0.9 数量:", int((o > 0.9).sum()))
