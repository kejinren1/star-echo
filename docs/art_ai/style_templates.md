# 画风模板反推详解（style_templates）

> 配套文件：`prompt_library.json`（程序用）｜`sample_prompts.md`（示例）｜`batch_gen.py`（批量脚本）
> 版本：v0.1.0（2026-08-11）

## 反推方法论

每款参考画风拆成 **五维基因**：色彩体系 / 服装语言 / 质感笔触 / 氛围基调 / 构图姿态。生成时按五维重组为描述词串（`prompt_block`），**不出现任何品牌名/角色名/艺术家名**。

## 法律合规（三条红线）

1. **风格不受版权保护**（中美法律共识）：用描述词模仿画风合法，最终图与原作"神似形不似"属合理模仿。
2. 红线一：**禁用艺术家姓名作提示词**（如 "in the style of XXX"）——国外已有判例争议。
3. 红线二：**勿拿原图做 img2img 参考**——那接近复制。
4. 红线三：**勿模仿知名角色可辨识形象**（体型/配色/标志物整体像某个具体角色）——角色形象可能受版权+商标双重保护。

本词库所有模板已按红线转译，可直接商用。

---

## ① 冷峻军武·末世（方舟系参考）

**五维基因**

| 维度 | 特征 |
|---|---|
| 色彩 | 低饱和冷灰蓝、深墨灰，点缀高对比警告色/异质结晶紫 |
| 服装 | 高领战术服、长风衣大衣、干练制服剪裁、金属+布料混搭 |
| 质感 | 工业末世、干净几何轮廓、轻度做旧磨损 |
| 氛围 | 冷峻克制、末日压抑但坚毅 |
| 姿态 | 干员档案式挺拔站姿、专业职业感、微昂首 |

**prompt_block（已转译）**
```
military tactical uniform with high collar, long overcoat, cold desaturated
color palette of gray blue and dark slate, subtle glowing crystal fragments,
industrial post-apocalyptic atmosphere, clean geometric design, professional
stoic pose, muted lighting
```

**适用**：本作《星骸回响》末世世界观基调天然契合，建议作为主力画风模板之一。

## ② 韩系热血·暗黑奇幻（DNF 系参考）

**五维基因**

| 维度 | 特征 |
|---|---|
| 色彩 | 高饱和技能色（暖金/血红/暗紫），暗底亮光强对比 |
| 服装 | 华丽重甲、夸张肩甲、金边镶嵌，武器大而张扬 |
| 质感 | 韩系厚涂、肌肉体积感、硬朗笔触 |
| 氛围 | 热血激昂、地下城压迫感、力量崇拜 |
| 姿态 | 夸张动态剪影、战斗蓄力、视角微仰 |

**prompt_block（已转译）**
```
korean semi-realistic fantasy painting style, heroic dynamic pose, ornate heavy
armor with gold trim, dark dungeon atmosphere, dramatic glowing skill effects,
bold saturated red and gold accents, dramatic rim lighting, high detail
```

**适用**：Boss、精英怪、技能特效展示图（张力最强）。

## ③ 日系英灵·圣光华丽（FGO 系参考）

**五维基因**

| 维度 | 特征 |
|---|---|
| 色彩 | 白金、圣光暖黄、礼服深色底衬华丽金属高光 |
| 服装 | 礼服+战甲混搭、金线浮雕、星纹/圣纹装饰 |
| 质感 | 赛璐璐上色 + 厚涂收尾的高完成度立绘 |
| 氛围 | 高贵神圣、传说英灵气场、庄严 |
| 姿态 | 优雅挺立、微低首睥睨、宝具释放前张力 |

**prompt_block（已转译）**
```
high quality anime illustration, cel shading with painterly finish, noble mythic
hero, ornate ceremonial outfit with gold filigree and star motifs, radiant holy
aura, elegant regal stance, luminous highlights, fantasy servant of legend
```

**适用**：主角团立绘、高级 NPC、封面/宣传图。

## ④ 明制东方·武侠墨意（明制中国风参考）

> 说明：按"明朝题材"理解，词库含两个变体。若你实际指《明末：渊虚之羽》类游戏，直接用变体 B（暗黑明末）即可。

**五维基因**

| 维度 | 特征 |
|---|---|
| 色彩 | 朱红点缀墨黑、宣纸留白感、低饱和大地色 |
| 服装 | 明制汉服/飞鱼服/棉甲甲胄、束发冠、环首刀 |
| 质感 | 水墨渲染、传统刺绣纹样、绸缎+皮革对比 |
| 氛围 | 东方武侠气韵、孤寂肃杀 |
| 姿态 | 武侠站姿、袖袍飘动、刀剑在侧 |

**prompt_block（已转译）**
```
chinese historical fantasy, ming dynasty style hanfu and armor, ink wash texture,
vermilion red accents on ink black, traditional embroidery patterns, wuxia
warrior atmosphere, dramatic dark lighting
```

**变体 B（明末暗黑）**：`dark chinese fantasy, ming dynasty armor, smoldering ash atmosphere, vermilion accents, eerie ink shadows, dying empire mood`

**适用**：东方世界观关卡、武侠系角色、中式场景。

## ⑤ 温馨炼金·田园治愈（炼金工坊系参考）

**五维基因**

| 维度 | 特征 |
|---|---|
| 色彩 | 奶油白、浅蓝、樱粉高亮暖色调 |
| 服装 | 轻便裙装/围裙工装、蝴蝶结荷叶边、药剂瓶配饰 |
| 质感 | 明亮赛璐璐、柔和干净线条 |
| 氛围 | 治愈温馨、田园日常、阳光明媚 |
| 姿态 | 活泼自然、微笑亲和、日常劳作或施法微抬手 |

**prompt_block（已转译）**
```
bright soft anime cel shading, warm pastel palette of cream light blue and pink,
cute wholesome fantasy girl, cozy alchemy workshop background, gentle golden
sunlight, soft clean lineart, heartwarming pastoral mood
```

**适用**：基地/据点 NPC、休闲场景、UI 吉祥物、反差萌彩蛋。

---

## 转译对照速查（品牌 → 描述词）

| 参考品牌 | 词库模板 ID | 一句话转译 |
|---|---|---|
| 明日方舟 | `style_military_cold` | 冷灰蓝军武制服 + 末世工业感 |
| DNF | `style_korean_heroic` | 韩系厚涂 + 重甲 + 技能光效 |
| FGO | `style_heroic_cel` | 赛璐璐立绘 + 圣光英灵 + 金线浮雕 |
| 明朝题材 | `style_ming_chinese` | 明制汉服甲胄 + 水墨 + 朱红墨黑 |
| 炼金工坊 | `style_cozy_atelier` | 明亮赛璐璐 + 奶油粉蓝 + 田园治愈 |

## 双轨生产路径（重要）

- **立绘轨（portrait, 768×1024）**：画风基因主轨。先生成立绘/概念图（风格模板生效），再经 `tools/img2sprite.py` 降采样量化成 64px 精灵——**风格基因（服装细节/配色体系）在像素化后仍保留**。
- **像素直出轨（pixel, 512×512）**：高吞吐轨。SDXL + Pixel-Art-XL LoRA(1.0) + No-AA LoRA(0.7) 直出像素风，适合 UI 图标/物品/特效/杂兵等细节要求低的类别。
