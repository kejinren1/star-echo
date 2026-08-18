#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""AF-M1 CC0 BGM 候选分析与转换（总指挥 2026-08-18 第 5 轮续）
从 CC0-1.0 仓库 effacestudios/Royalty-Free-Music-Pack 下载的候选 mp3：
解码 22050Hz mono 16bit → 分析波形特征（RMS 稳定性/过零率节奏/静音边界）
→ 截取能量稳定 8-12s 循环段 → 输出 wav + 候选报告（人工听感最终拍板）。
用法：python af_m1_analyze.py <mp3 目录>
"""
import glob
import json
import math
import os
import sys
import wave

import miniaudio

SR = 22050
WIN = 2048  # RMS 窗口


def decode(path: str):
    dec = miniaudio.decode_file(path, output_format=miniaudio.SampleFormat.SIGNED16,
                                nchannels=1, sample_rate=SR)
    return dec.samples  # array('h')


def rms_frame(samples, start, n=WIN):
    seg = samples[start:start + n]
    if not seg:
        return 0.0
    acc = 0.0
    for s in seg:
        acc += s * s
    return math.sqrt(acc / len(seg)) / 32768.0


def analyze(samples):
    total = len(samples)
    dur = total / SR
    # 每 0.5s 一个 RMS 采样
    hop = SR // 2
    n_win = total // hop
    rms = [rms_frame(samples, i * hop) for i in range(n_win)]
    peak_rms = max(rms) if rms else 0.0
    # 开头静音长度（RMS < 0.005 视为静音）
    lead = 0
    while lead < len(rms) and rms[lead] < 0.005:
        lead += 1
    # 结尾静音
    tail = 0
    while tail < len(rms) and rms[len(rms) - 1 - tail] < 0.005:
        tail += 1
    # 过零率（节奏感粗指标）：每 0.5s 窗口过零次数均值
    zc_total = 0
    zc_windows = 0
    step = 256
    for start in range(0, total - step, SR):
        z = 0
        prev = samples[start]
        for i in range(1, step):
            cur = samples[start + i]
            if (prev < 0 <= cur) or (cur < 0 <= prev):
                z += 1
            prev = cur
        zc_total += z
        zc_windows += 1
    zc_rate = zc_total / zc_windows if zc_windows else 0.0  # 每 256 样本过零数
    # 能量稳定区：找最长连续段，其 RMS 波动（变异系数）最小且均值 > 0.15*peak
    best = None
    window = int(10.0 / 0.5)  # 10s 窗口
    for i in range(0, len(rms) - window):
        seg = rms[i:i + window]
        mean = sum(seg) / len(seg)
        if mean < 0.15 * max(peak_rms, 1e-9):
            continue
        var = sum((x - mean) ** 2 for x in seg) / len(seg)
        cv = math.sqrt(var) / mean if mean > 0 else 9.9
        if best is None or cv < best[0]:
            best = (cv, i, mean)
    return {"dur": dur, "lead_s": lead * 0.5, "tail_s": tail * 0.5,
            "peak_rms": peak_rms, "zc_per_256": zc_rate, "stable": best}


def cut(samples, start_s, end_s, out_path):
    s0 = int(start_s * SR)
    s1 = int(end_s * SR)
    seg = samples[s0:s1]
    with wave.open(out_path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(seg.tobytes())


def main():
    d = sys.argv[1] if len(sys.argv) > 1 else "/tmp"
    outdir = os.path.join(d, "af_m1_cands")
    os.makedirs(outdir, exist_ok=True)
    report = []
    for mp3 in sorted(glob.glob(os.path.join(d, "cand_*.mp3")) + glob.glob(os.path.join(d, "test_mysterious.mp3"))):
        name = os.path.basename(mp3).replace("cand_", "").replace(".mp3", "")
        if name == "test_mysterious":
            name = "Mysterious"
        samples = decode(mp3)
        info = analyze(samples)
        # 截取：能量稳定区优先，clip 到 8-12s，且避开首尾静音
        if info["stable"]:
            cv, idx, mean = info["stable"]
            start_s = max(idx * 0.5, info["lead_s"] + 0.2)
            dur_s = min(10.0, info["dur"] - start_s - max(info["tail_s"], 0.3))
            if dur_s < 8.0:
                dur_s = min(10.0, info["dur"] - 0.5)  # 兜底
        else:
            start_s = min(info["lead_s"] + 0.2, info["dur"] * 0.3)
            dur_s = min(10.0, info["dur"] - start_s - 1.0)
        end_s = start_s + dur_s
        out = os.path.join(outdir, name + ".wav")
        cut(samples, start_s, end_s, out)
        with wave.open(out, 'rb') as w:
            out_dur = w.getnframes() / w.getframerate()
        report.append({
            "name": name, "src_dur": round(info["dur"], 1),
            "lead_s": round(info["lead_s"], 1), "tail_s": round(info["tail_s"], 1),
            "peak_rms": round(info["peak_rms"], 3),
            "zc_per_256": round(info["zc_per_256"], 1),
            "stable_cv": round(info["stable"][0], 3) if info["stable"] else None,
            "cut": [round(start_s, 1), round(end_s, 1)], "out_dur": round(out_dur, 2),
        })
        print(json.dumps(report[-1], ensure_ascii=False))
    with open(os.path.join(outdir, "report.json"), "w", encoding="utf-8") as f:
        json.dump(report, f, ensure_ascii=False, indent=2)
    print("saved to", outdir)


if __name__ == "__main__":
    main()
