# 组合示例（sample_prompts）

> 5 款成品组合 prompt，可直接复制进 WebUI/API 使用。结构：质量词 + 画风块 + 世界观 + 职业 + 服装 + 发型 + 配色 + 配件 + 分类尾缀。
> 负面词（统一挂）：`blurry, jpeg artifacts, watermark, text, logo, signature, extra fingers, deformed hands, bad anatomy, mutated, duplicate, cropped, low quality, worst quality, oversaturated, photorealistic, 3d render`

## 1. 方舟系 · 冷峻军武战士（女）— 立绘轨 768×1024

```
masterpiece, best quality, highly detailed, sharp focus, clean lineart,
military tactical uniform with high collar, long overcoat, cold desaturated
color palette of gray blue and dark slate, subtle glowing crystal fragments,
industrial post-apocalyptic atmosphere, clean geometric design, professional
stoic pose, muted lighting, post-apocalyptic wasteland, warrior, military
combat suit, high ponytail, cold gray blue color palette, longsword,
full body character concept art, standing pose, clean silhouette
```

**关键词组合**：方舟系画风 × 末世废土 × 战士 × 战斗服 × 高马尾 × 冷灰蓝 × 长剑
**适配**：《星骸回响》末世主角团形象底子。

## 2. 炼金系 · 温馨炼金术士（女）— 立绘轨

```
masterpiece, best quality, highly detailed, sharp focus, clean lineart,
bright soft anime cel shading, warm pastel palette of cream light blue and pink,
cute wholesome fantasy girl, cozy alchemy workshop background, gentle golden
sunlight, soft clean lineart, heartwarming pastoral mood, pastoral fantasy
town, alchemist, flowing mage robe, short bob cut, cream pink and light blue
pastel palette, gem pendant, full body character concept art, standing pose,
clean silhouette
```

**关键词组合**：炼金系画风 × 田园幻想 × 炼金术士 × 法师长袍 × 短发 × 奶油粉蓝 × 宝石吊坠
**适配**：基地 NPC、养成界面角色。

## 3. 明系 · 武侠刺客（女）— 立绘轨

```
masterpiece, best quality, highly detailed, sharp focus, clean lineart,
chinese historical fantasy, ming dynasty style hanfu and armor, ink wash
texture, vermilion red accents on ink black, traditional embroidery patterns,
wuxia warrior atmosphere, dramatic dark lighting, eastern wuxia world,
assassin, ming dynasty official robe, side ponytail, vermilion red and ink
black palette, twin daggers, full body character concept art, standing pose,
clean silhouette
```

**关键词组合**：明系画风 × 东方武侠 × 刺客 × 飞鱼服 × 单马尾 × 朱红墨黑 × 双刃匕首
**适配**：东方世界观关卡角色。

## 4. FGO 系 · 英灵骑士（女）— 立绘轨

```
masterpiece, best quality, highly detailed, sharp focus, clean lineart,
high quality anime illustration, cel shading with painterly finish, noble
mythic hero, ornate ceremonial outfit with gold filigree and star motifs,
radiant holy aura, elegant regal stance, luminous highlights, fantasy servant
of legend, mythic fantasy realm, knight, elegant ceremonial gown, elegant
updo bun, white and gold holy palette, tower shield, full body character
concept art, standing pose, clean silhouette
```

**关键词组合**：FGO 系画风 × 英灵神话 × 骑士 × 礼服 × 盘发 × 白金圣洁 × 盾牌
**适配**：主角团核心成员、封面宣传图。

## 5. DNF 系 · 重装狂战（男）— 立绘轨

```
masterpiece, best quality, highly detailed, sharp focus, clean lineart,
korean semi-realistic fantasy painting style, heroic dynamic pose, ornate
heavy armor with gold trim, dark dungeon atmosphere, dramatic glowing skill
effects, bold saturated red and gold accents, dramatic rim lighting, high
detail, dark fantasy dungeon, warrior, heavy plate armor with pauldrons,
wolf cut, warm gold and crimson palette, greatsword, full body character
concept art, standing pose, clean silhouette
```

**关键词组合**：DNF 系画风 × 暗黑地下城 × 战士 × 重铠 × 狼尾 × 暖金血红 × 巨剑
**适配**：Boss、精英怪、力量型角色。

---

## 像素直出示例（物品图标，512×512）

```
masterpiece, best quality, <lora:pixel_art_xl:1.0>, <lora:no_anti_aliasing:0.7>,
bright soft anime cel shading, warm pastel palette of cream pink and light blue,
single game item, centered, floating, plain background, game asset, pixel art
```

负面词用像素强化版：`anti-aliasing, soft edges, gradient wash, color bleed, jpeg artifacts, watermark, text, logo, signature, extra fingers, deformed hands, bad anatomy, mutated, low quality, worst quality`

## 组合操作手册

1. 选画风模板 ×5（`--style`）
2. 选世界观 ×6（`--world`）
3. 选职业 ×12（`--cls`）＋ 服装 ×14（`--outfit`）
4. 选发型 ×14（`--hair`）＋ 配色 ×8（`--color`）
5. 选配件 ×14（`--accessory`）
6. 一次 ≤4 个要素（防串味），优先级：发型 > 服装 > 配色 > 配件

理论组合空间：5 × 6 × 12 × 14 × 14 × 8 × 14 ≈ **7900 万**种组合（实际按验证后的高命中要素收敛）。
