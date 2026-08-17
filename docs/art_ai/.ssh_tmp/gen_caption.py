#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""JoyCaption2 画风反推：参考图 -> 自然语言画风描述"""
import json, sys, time, urllib.request, os

HOST = "http://127.0.0.1:18001"
TOKEN = "$2b$12$.TAugRmvKlv5LxFdgOXP4.7mFvhRY2GpvKmr2S8kvAVB9bP/ivSae"
OUT = r"D:/30DAYS/docs/art_ai/output_comfy/captions"

def api(path, payload=None):
    url = HOST + path
    data = json.dumps(payload).encode() if payload else None
    req = urllib.request.Request(url, data=data, method="POST" if payload else "GET")
    req.add_header("Authorization", "Bearer " + TOKEN)
    req.add_header("Content-Type", "application/json")
    with urllib.request.urlopen(req, timeout=90) as r:
        return json.loads(r.read())

def wf(image, ctype, clen, tag):
    return {
        "1": {"class_type": "LoadImage", "inputs": {"image": image}},
        "2": {"class_type": "easy joyCaption2API", "inputs": {
            "image": ["1", 0], "do_sample": True, "temperature": 0.6,
            "max_tokens": 300, "caption_type": ctype, "caption_length": clen,
            "extra_options": "", "name_input": "", "custom_prompt": ""}},
        "3": {"class_type": "SaveStringKJ", "inputs": {
            "string": ["2", 0], "filename_prefix": f"cap_{tag}", "output_folder": "output/captions"}},
    }

def run(image, ctype, clen, tag):
    resp = api("/prompt", {"prompt": wf(image, ctype, clen, tag)})
    pid = resp.get("prompt_id")
    t0 = time.time()
    while True:
        time.sleep(4)
        h = api(f"/history/{pid}")
        if pid in h:
            for nid, o in h[pid]["outputs"].items():
                fn = o.get("filename") or ""
                if fn:
                    return fn
            return ""
        if time.time() - t0 > 900:
            return "(TIMEOUT)"

def main():
    os.makedirs(OUT, exist_ok=True)
    args = sys.argv[1:]
    ctype = args[0] if args else "Training Prompt"
    clen = args[1] if len(args) > 1 else "long"
    files = args[2:] if len(args) > 2 else None
    if files is None:
        import glob
        files = sorted(os.path.basename(f) for f in glob.glob(r"D:/30DAYS/0815立绘风格、画风示例/*.webp"))
    for f in files:
        fname = f if f.startswith("refs/") else f"refs/{f}"
        tag = f.split("/")[-1].replace(".webp", "").replace(".png", "")
        print(f"=== {f} [{ctype}/{clen}] ===", flush=True)
        fn = run(fname, ctype, clen, tag)
        print(f"SAVED: {fn}", flush=True)
    print("ALL_DONE", flush=True)

if __name__ == "__main__":
    main()
