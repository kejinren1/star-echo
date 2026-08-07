#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Day 24 音频资源程序化合成工具（D24-T1）：纯 Python 标准库生成 WAV（禁第三方依赖）。

BGM 2 轨（8-12s 循环点对齐）+ SFX 10 类（0.1-1.5s），22050Hz 16bit mono，峰值 ≤0.8。
符合 2026-08-07 用户拍板美术资源策略：程序化合成占位，不涉 AI 画图/精修。

用法：
    python tools/gen_audio.py   # 生成 assets/audio/bgm/*.wav + assets/audio/sfx/*.wav（幂等覆盖）
"""

import math
import os
import random
import struct
import wave

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BGM_DIR = os.path.join(ROOT, "assets", "audio", "bgm")
SFX_DIR = os.path.join(ROOT, "assets", "audio", "sfx")

SAMPLE_RATE = 22050
PEAK = 0.8


# ---------- 基础合成原语 ----------

def _env(t, dur, attack, decay):
    """线性 AD 包络（attack 起音 / decay 尾音，均秒）。"""
    if t < attack:
        return t / attack if attack > 0.0 else 1.0
    tail = max(dur - decay, attack)
    if t > tail:
        remain = dur - t
        return max(remain / decay, 0.0) if decay > 0.0 else 0.0
    return 1.0


def _tone(freq, dur, vol=0.5, attack=0.01, decay=0.05, wave_type="sine"):
    """单音（正弦/方波/三角），带 AD 包络。"""
    n = int(dur * SAMPLE_RATE)
    out = []
    for i in range(n):
        t = i / SAMPLE_RATE
        ph = 2.0 * math.pi * freq * t
        if wave_type == "sine":
            v = math.sin(ph)
        elif wave_type == "square":
            v = 1.0 if math.sin(ph) >= 0.0 else -1.0
        elif wave_type == "tri":
            v = 2.0 / math.pi * math.asin(math.sin(ph))
        else:
            v = math.sin(ph)
        out.append(v * vol * _env(t, dur, attack, decay))
    return out


def _noise(dur, vol=0.5, lowpass=0.0, attack=0.005, decay=0.05):
    """白噪声 + 一阶低通（lowpass 0~1，越大越亮）。"""
    n = int(dur * SAMPLE_RATE)
    out = []
    prev = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        w = random.uniform(-1.0, 1.0)
        if lowpass > 0.0:
            prev = prev + lowpass * (w - prev)
            w = prev
        out.append(w * vol * _env(t, dur, attack, decay))
    return out


def _mix(*tracks):
    n = max(len(t) for t in tracks) if tracks else 0
    out = []
    for i in range(n):
        s = 0.0
        for t in tracks:
            s += t[i] if i < len(t) else 0.0
        out.append(s)
    return out


def _seq(*segments):
    """串联（gap 秒静音分隔可选）。"""
    out = []
    for s in segments:
        out.extend(s)
    return out


def _write_wav(path, samples):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    peak = max((abs(s) for s in samples), default=0.0)
    if peak > 0.0:
        scale = PEAK / peak
        samples = [s * scale for s in samples]
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SAMPLE_RATE)
        frames = bytearray()
        for s in samples:
            v = int(max(-1.0, min(1.0, s)) * 32767)
            frames.extend(struct.pack("<h", v))
        w.writeframes(bytes(frames))


# ---------- BGM 2 轨 ----------

def _bgm_menu():
    """主界面 BGM：C 大调琶音循环（C E G E / A F C F ...），8s 一循环点对齐。"""
    notes = [261.63, 329.63, 392.00, 329.63,   # C E G E
             220.00, 329.63, 261.63, 329.63,   # A F C F
             293.66, 349.23, 440.00, 349.23,   # D F A F
             261.63, 329.63, 392.00, 523.25]   # C E G C5
    bar = 0.5  # 每音 0.5s → 16 音 = 8s 循环
    out = []
    for f in notes:
        out.extend(_tone(f, bar, 0.28, attack=0.02, decay=0.25))
        # 低八度衬底（稀疏）
    bass = []
    for f in [130.81, 110.00, 146.83, 130.81]:
        bass.extend(_tone(f, 2.0, 0.14, attack=0.03, decay=0.9))
    out = _mix(out, bass)  # 8s 循环点对齐（16 音 × 0.5s = 4 音 × 2s）
    return out


def _bgm_battle():
    """战斗 BGM：快节奏低音脉冲（E2 八分音符）+ 主音动机，8s 循环。"""
    bass_freqs = [82.41, 82.41, 98.00, 98.00, 110.00, 110.00, 98.00, 82.41]  # E G A G
    pulse = 0.5
    bass = []
    for f in bass_freqs:
        bass.extend(_tone(f, pulse, 0.30, attack=0.005, decay=0.35, wave_type="square"))
        bass.extend(_tone(f * 2.0, pulse, 0.10, attack=0.005, decay=0.30, wave_type="square"))
    lead = []
    lead_notes = [329.63, 329.63, 392.00, 329.63, 293.66, 329.63, 392.00, 523.25,
                  329.63, 329.63, 392.00, 329.63, 293.66, 261.63, 293.66, 329.63]
    for f in lead_notes:
        lead.extend(_tone(f, 0.5, 0.16, attack=0.005, decay=0.35, wave_type="tri"))
    return _mix(bass, lead)


# ---------- SFX 10 类 ----------

def _sfx_hit():
    """普通命中：短促低噪 + 低频敲击。"""
    return _mix(_noise(0.08, 0.35, lowpass=0.5, decay=0.06),
                _tone(180, 0.07, 0.30, attack=0.002, decay=0.06))


def _sfx_crit():
    """暴击/爆炸：更响亮的噪声爆发 + 低频轰鸣。"""
    return _mix(_noise(0.18, 0.45, lowpass=0.35, decay=0.16),
                _tone(90, 0.18, 0.40, attack=0.002, decay=0.16, wave_type="square"))


def _sfx_death():
    """敌人死亡：下坠滑音（方波 400→80）。"""
    n = int(0.35 * SAMPLE_RATE)
    out = []
    for i in range(n):
        t = i / SAMPLE_RATE
        f = 400.0 * math.pow(80.0 / 400.0, t / 0.35)
        ph = 2.0 * math.pi * f * t
        v = math.sin(ph)
        out.append(v * 0.35 * _env(t, 0.35, 0.01, 0.25))
    return out


def _sfx_levelup():
    """升级：上行琶音 C5 E5 G5 C6（三角波）。"""
    return _seq(*[_tone(f, 0.12, 0.30, attack=0.01, decay=0.10, wave_type="tri")
                 for f in [523.25, 659.25, 783.99, 1046.50]])


def _sfx_coin():
    """金币：高频清脆叮（双音叠加）。"""
    return _mix(_tone(1318.51, 0.10, 0.30, attack=0.002, decay=0.09),
                _tone(1975.53, 0.08, 0.15, attack=0.002, decay=0.07))


def _sfx_shop():
    """商店：柔和双音（F5 A5 顺滑）。"""
    return _seq(_tone(698.46, 0.10, 0.25, attack=0.01, decay=0.08),
                _tone(880.00, 0.14, 0.25, attack=0.01, decay=0.12))


def _sfx_skill():
    """技能施放：中频扫频上升（200→800）。"""
    n = int(0.30 * SAMPLE_RATE)
    out = []
    for i in range(n):
        t = i / SAMPLE_RATE
        f = 200.0 * math.pow(800.0 / 200.0, t / 0.30)
        ph = 2.0 * math.pi * f * t
        out.append(math.sin(ph) * 0.30 * _env(t, 0.30, 0.01, 0.20))
    return out


def _sfx_heal():
    """回血：温暖双音上行（A4 C5）。"""
    return _seq(_tone(440.00, 0.14, 0.25, attack=0.02, decay=0.12),
                _tone(523.25, 0.18, 0.25, attack=0.02, decay=0.15))


def _sfx_event():
    """事件：神秘低鸣 + 上滑音。"""
    return _mix(_tone(110.0, 0.6, 0.20, attack=0.05, decay=0.5),
                _tone(165.0, 0.4, 0.12, attack=0.03, decay=0.35))


def _sfx_boss():
    """Boss 波：低沉预警双鸣（E2 长音 + 震音）。"""
    roar = _tone(82.41, 0.9, 0.35, attack=0.03, decay=0.7, wave_type="square")
    trem = _tone(164.81, 0.9, 0.10, attack=0.03, decay=0.7)
    return _mix(roar, trem)


# ---------- 主入口 ----------

def build():
    bgm = {"bgm_menu": _bgm_menu, "bgm_battle": _bgm_battle}
    sfx = {"hit": _sfx_hit, "crit": _sfx_crit, "death": _sfx_death,
           "levelup": _sfx_levelup, "coin": _sfx_coin, "shop": _sfx_shop,
           "skill": _sfx_skill, "heal": _sfx_heal, "event": _sfx_event,
           "boss": _sfx_boss}
    for name, fn in bgm.items():
        path = os.path.join(BGM_DIR, name + ".wav")
        _write_wav(path, fn())
        print("已生成 %s" % path)
    for name, fn in sfx.items():
        path = os.path.join(SFX_DIR, name + ".wav")
        _write_wav(path, fn())
        print("已生成 %s" % path)
    print("共 12 个 WAV（BGM 2 + SFX 10）· 22050Hz 16bit mono · 峰值 ≤0.8")


if __name__ == "__main__":
    random.seed(20260808)
    build()
