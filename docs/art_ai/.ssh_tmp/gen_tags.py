#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""WD14 标签反推：21 张参考图 -> danbooru 标签，分析画风共性"""
import json, sys, time, urllib.request, glob, os, re
from collections import Counter

HOST = "http://127.0.0.1:18001"
TOKEN = "$2b$12$.TAugRmvKlv5LxFdgOXP4.7mFvhRY2GpvKmr2S8kvAVB9bP/ivSae"

def api(path, payload=None):
    url = HOST + path
    data = json.dumps(payload).encode() if payload else None
    req = urllib.request.Request(url, data=data, method="POST" if payload else "GET")
    req.add_header("Authorization", "Bearer " + TOKEN)
    req.add_header("Content-Type", "application/json")
    with urllib.request.urlopen(req, timeout=90) as r:
        return json.loads(r.read())

def run_one(image, mode, tag):
    wf = {
        "1": {"class_type": "LoadImage", "inputs": {"image": image}},
        "2": {"class_type": "easy imageInterrogator", "inputs": {"image": ["1", 0], "mode": mode, "use_lowvram": True}},
        "3": {"class_type": "SaveStringKJ", "inputs": {"string": ["2", 0], "filename_prefix": f"tags_{tag}", "output_folder": "output/tags"}},
    }
    resp = api("/prompt", {"prompt": wf})
    pid = resp.get("prompt_id")
    t0 = time.time()
    while True:
        time.sleep(2)
        try:
            h = api(f"/history/{pid}")
        except Exception:
            continue
        if pid in h:
            st = h[pid]["status"].get("status_str", "")
            if st == "error":
                msgs = h[pid]["status"].get("messages", [])
                for m in msgs:
                    if m[0] == "execution_error":
                        print("NODE_ERR:", m[1].get("exception_message", "")[:200], flush=True)
                return None
            for nid, o in h[pid]["outputs"].items():
                fn = o.get("filename") or ""
                if fn:
                    return fn
            return None
        if time.time() - t0 > 120:
            return "(TIMEOUT)"

def main():
    files = sorted(os.path.basename(f) for f in glob.glob(r"D:/30DAYS/0815立绘风格、画风示例/*.webp"))
    print(f"共 {len(files)} 张", flush=True)
    all_tags = Counter()
    for f in files:
        tag = f.replace(".webp", "")
        fn = run_one(f"refs/{f}", "best", tag)
        print(f"{f} -> {fn}", flush=True)
    print("ALL_SUBMITTED", flush=True)

if __name__ == "__main__":
    main()
