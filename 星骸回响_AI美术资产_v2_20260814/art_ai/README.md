# 星骸回响 · AI 美术资产库（art_ai）

> 目标：为《星骸回响》批量生产全部美术素材（人物/怪物/物品/UI/场景/特效/道具），形成可持续扩充的资产库。
> 版本：v0.1.0（2026-08-11）｜方案：SDXL 1.0 + Pixel-Art-XL LoRA + No-AA LoRA

## 目录文件

| 文件 | 用途 |
|---|---|
| `prompt_library.json` | **核心词库母版**（程序可读）：画风模板×5、要素字典（发型/服装/职业/配色/配件/世界观）、分类骨架、组合规则、双轨参数 |
| `style_templates.md` | 画风反推详解：五维基因拆解 + 品牌→描述词转译 + 三条法律红线 |
| `sample_prompts.md` | 成品组合示例（5 款可直接用的完整 prompt） |
| `batch_gen.py` | 批量生成脚本骨架（纯标准库，调 SD.Next/WebUI API） |

## 生产管线

```
生成(云GPU) → 人工/程序筛选 → tools/img2sprite.py(抠底→降采样→量化)
→ ART/COLOR_DICT.json 调色板校验(ΔRGB≤12) → 实装
```

## 双轨策略

| 轨道 | 分辨率 | 用途 | LoRA |
|---|---|---|---|
| 立绘轨 portrait | 768×1024 | 角色/怪物/场景（画风基因主轨，后处理像素化） | 无（纯画风模板） |
| 像素直出轨 pixel | 512×512 | 物品/UI 图标/特效/杂兵（高吞吐） | Pixel-Art-XL 1.0 + No-AA 0.7 |

## 批量生成用法（主机部署后）

```bash
# 1. 验证模式：每个要素抽 5 张测命中率（命中率 <60% 改词）
python batch_gen.py --host http://<IP>:7860 --verify --style style_military_cold

# 2. 正式批量：方舟系战士角色 100 张（立绘轨）
python batch_gen.py --host http://<IP>:7860 --category character \
  --style style_military_cold --world world_wasteland --cls cls_warrior \
  --outfit outfit_combat_suit --hair hair_high_pony --color col_gray_blue \
  --accessory acc_longsword --count 100

# 3. 像素直出：物品 200 张
python batch_gen.py --host http://<IP>:7860 --category item --track pixel \
  --style style_cozy_atelier --count 200
```

## 执行阶段

- [x] **阶段 0 词库预制**（本目录，2026-08-11）
- [ ] 阶段 1 云主机部署：Ubuntu + 驱动 + SD.Next + 双 LoRA + ControlNet
- [ ] 阶段 2 要素验证与改词（`--verify`）
- [ ] 阶段 3 批量生成（按分类落盘 + manifest）
- [ ] 阶段 4 后处理量化 + 调色板校验 → 资产入库

## 一致性保障

- 角色形象固化：img2img 低 denoise(0.3–0.5) + 固定 base_seed + ControlNet(OpenPose) 控姿态
- 变体 seed = base_seed + 序号（`rules.consistency`）

## 项目约定对齐

- 精灵基准：角色 64 / 杂兵 48 / 精英 64 / Boss 128 / 图标 32 / 特效 64（`params.post.sprite_sizes`）
- 调色板：生成结果必须过 `ART/COLOR_DICT.json` 量化校验，色号全局唯一、ΔRGB≤12
- 法律合规：所有画风模板为风格转译描述词，无品牌/角色/艺术家名（见 style_templates.md 红线）
