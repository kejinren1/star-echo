#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_skel_batch.py — 批量提取 10 个姿势的 openpose 骨架"""
import json, time, urllib.request

HOST = "http://127.0.0.1:18001"
TOKEN = "$2b$12$.TAugRmvKlv5LxFdgOXP4.7mFvhRY2GpvKmr2S8kvAVB9bP/ivSae"


def api(path, payload=None):
    url = HOST + path
    data = json.dumps(payload).encode() if payload else None
    req = urllib.request.Request(url, data=data, method="POST" if payload else "GET")
    req.add_header("Authorization", "Bearer " + TOKEN)
    req.add_header("Content-Type", "application/json")
    with urllib.request.urlopen(req, timeout=120) as r:
        return json.loads(r.read())


for i in range(1, 11):
    img = f"posesrc/pose{i:02d}.png"
    wf = {
        "1": {"class_type": "LoadImage", "inputs": {"image": img}},
        "2": {"class_type": "OpenposePreprocessor", "inputs": {"image": ["1", 0]}},
        "3": {"class_type": "SaveImage", "inputs": {"filename_prefix": f"skel_p{i:02d}", "images": ["2", 0]}},
    }
    try:
        resp = api("/prompt", {"prompt": wf})
    except Exception as e:
        print(f"FAIL pose{i:02d}: {e}", flush=True)
        continue
    pid = resp.get("prompt_id")
    t0 = time.time()
    while time.time() - t0 < 120:
        time.sleep(3)
        try:
            h = api(f"/history/{pid}")
        except Exception:
            continue
        if pid in h:
            st = h[pid]["status"].get("status_str", "")
            if st == "error":
                for m in h[pid]["status"].get("messages", []):
                    if m[0] == "execution_error":
                        print(f"NODE_ERR pose{i:02d}:", m[1].get("exception_message", "")[:150], flush=True)
            else:
                print(f"SKEL pose{i:02d} DONE", flush=True)
            break
print("ALL_DONE", flush=True)
