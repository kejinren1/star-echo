# 音频素材来源与授权记录（AUDIO_CREDITS）

> 由 **RS-总指挥** 维护（AF-M1 CC0 音乐替换，2026-08-18 第 5 轮落地）。
> 用途：记录 `assets/audio/**` 内替换素材的出处与授权，保证商业发布合规可追溯。
> 约定：外部源文件（mp3 原曲）不入库，仅游戏内使用的转换产物（wav）入库 + 本文件登记来源。

## 已替换（2026-08-18）

| 游戏内文件 | 来源曲目 | 源仓库 | 授权 | 转换说明 |
|---|---|---|---|---|
| `assets/audio/bgm/bgm_menu.wav` | Illusionist.mp3 | [effacestudios/Royalty-Free-Music-Pack](https://github.com/effacestudios/Royalty-Free-Music-Pack)（GitHub, master 分支） | **CC0-1.0**（仓库 LICENSE，商用免署名） | 22050Hz mono 16bit，截取 80.5~90.5s 能量稳定 10s 循环段 |
| `assets/audio/bgm/bgm_battle.wav` | Fury.mp3 | 同上 | **CC0-1.0** | 22050Hz mono 16bit，截取 75.0~85.0s 能量稳定 10s 循环段 |

- 原始 BGM（程序合成占位音）备份于 git 历史 + 本地临时目录；替换仅换文件内容，`BGM_MAP/SFX_MAP` 零改动（AF-M1 零代码变更约定）。
- 校验：`day24_audio_check` 14/14（12 WAV 合法 + BGM 8-12s 循环 + mono 22050 16bit）+ 全量回归 61/61（1504 断言）+ baseline BASELINE CLEAN。

## 候选清单（未采用，可再选）

| 曲目 | 特征（脚本分析） | 备注 |
|---|---|---|
| Mysterious | 中速神秘 12.4zc/0.535cv | 备用菜单曲 |
| Science Fiction | 中慢科幻 10.8zc/0.438cv | 备用战斗曲 |
| technologist | 中速科技 18.2zc/0.732cv | 节奏偏轻 |
| Planning | 中速起伏大 20.8zc/1.114cv | 能量波动大不适宜循环 |

- 候选分析/截取工具：`tools/af_m1_analyze.py`（miniaudio 解码 22050 mono 16bit + RMS 稳定区截取，候选源 mp3 从 GitHub raw 下载，未入库）。
- 若 Owner 对听感不满意：可从「候选清单」替换或从源仓库另选曲，重跑 `af_m1_analyze.py` 即可（文件名不变零代码改动）。

## 网络可达性实测（2026-08-18，澄清「网络依赖」表述）

- **GitHub 生态（raw.githubusercontent.com / api.github.com / codeload）可达**——CC0 素材采集走此通道，无需人工代理。
- 历史记录的不可达对象：archive.org（用户网络）、spriters-resource（Cloudflare Turnstile 全站验证）——仅这两个来源受限，不适用音乐素材。
- 后续表述规范：不再笼统写「网络依赖」，改为「GitHub 生态可达，素材从 GitHub 仓库采集」。
