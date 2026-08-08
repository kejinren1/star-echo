# 美术风格与资产清单 (ART_STYLE.md)

> 本文档定义游戏的视觉方向、美术规范和 MVP 版本资产清单。
> 所有美术产出应严格遵循本文档中的尺寸、帧数和风格约定。

---

## 一、参考游戏分析

### 1. Brotato（土豆兄弟）
| 维度 | 分析 |
|------|------|
| **风格** | 卡通简约风，非纯像素。角色为圆润的蛋/土豆造型，表情夸张，配色明快 |
| **精灵尺寸** | 角色约 32x32px 级别，敌人略小，整体偏 Q 萌 |
| **动画** | 极简，2-4 帧抖动式呼吸/移动动画，无复杂骨骼 |
| **UI 布局** | 顶部：血条(红) + 经验条(绿) + 等级 + 金币 + 波次 + 剩余时间；底部：武器栏(6 槽) + 道具栏 |
| **色彩** | 暗色背景 + 高饱和角色/敌人，形成强对比，保证满屏敌人时的可读性 |
| **特效** | 简洁命中粒子、暴击数字弹字、升级光效，不喧宾夺主 |
| **优点** | 可读性极强、性能优秀、角色辨识度高 |
| **缺点** | 画面偏简陋，地图单调，缺乏视觉层次 |

### 2. Vampire Survivors（吸血鬼幸存者）
| 维度 | 分析 |
|------|------|
| **风格** | 纯像素风，致敬经典 16 位时代，精灵粒度粗但风格统一 |
| **精灵尺寸** | 角色/敌人 32x32px，武器图标 128x128px，属性图标 16x16px |
| **动画** | 2-6 帧循环动画，大量同屏敌人时靠极低帧数保性能 |
| **UI 布局** | 底部经验条 + 角等级；顶部计时器 + 金币；武器/被动栏在底部成排排列 |
| **色彩** | 经典像素调色板，暗色调为主，高亮特效区分不同武器 |
| **优点** | 极致性能、经典像素质感、同屏数百敌人无压力 |
| **缺点** | 精灵过于粗糙，辨识度依赖颜色而非造型 |

### 3. Halls of Torment（折磨大厅）
| 维度 | 分析 |
|------|------|
| **风格** | 复古 PS1 时代 3D 素描渲染 + 2D 精灵混合，暗黑奇幻风 |
| **精灵尺寸** | 角色/敌人较大，约 64x64px 级别，细节更丰富 |
| **动画** | 多帧动画，动作流畅，有受击/死亡动画 |
| **UI 布局** | 底部 HUD 栏，简洁暗色面板 + 文字，沉浸感强 |
| **色彩** | 暗色调主导，局部光源照亮角色，氛围感极强 |
| **优点** | 氛围出色、角色辨识度高、视觉层次丰富 |
| **缺点** | 制作成本较高，精灵偏大导致同屏数量受限 |

---

## 二、美术风格定位

### 风格关键词
**「暗色像素 · 高对比 · 硬朗轮廓 · 霓虹点缀」**

### 风格描述
本项目采用**暗色调像素风**，介于 Brotato 的简约卡通与 Vampire Survivors 的粗像素之间。
核心特征：

1. **暗色舞台 + 高亮角色**：背景使用低明度/低饱和的暗色调（深灰、深蓝、暗紫），角色和敌人使用高饱和/高明度的色彩，确保满屏混战时玩家能瞬间定位自身和威胁。
2. **硬朗轮廓线**：所有精灵使用 1-2px 的深色描边（接近纯黑），增强辨识度。不使用 Brotato 式的软萌轮廓，而是更偏硬朗的剪影风格。
3. **霓虹色点缀**：武器特效、暴击数字、拾取物使用高亮霓虹色（青、品红、电黄），在暗色背景上形成"光源感"。
4. **64px 像素密度**：角色精灵基准 64x64px，敌人 48x48~64x64px。2D 渲染瓶颈是屏幕像素面积而非源纹理分辨率，64px 对同屏 100+ 敌人流畅度几乎无影响（Halls of Torment 同级别）。
5. **有限调色板**：全局使用**色板字典登记制（≤216 色）**（见下文），所有美术资产取色登记入字典，确保视觉统一。

### 色板字典（216 色上限 + 锚点色板）

> **色数政策升级（2026-08-06 拍板）：从「32 色硬约束」改为「216 色上限 + 字典登记制」**
> - 技术上 RGB 不限色数，限制色数是**风格工具**（统一感）而非技术需求
> - 64px 高细节素材下 32 色实测观感大幅下降，故上限放宽至 **216 色**（网页安全色量级 6³）
> - 新素材（AI/人工生成）导出时：**提取实际用色 → 登记入字典 → 容差内归并邻近色**，人工只审查异常色
> - 保留下方 32 色「锚点色板」作为推荐基础色，关键色（描边/皮肤/发色）硬编码锚点、不容差归并

#### 色号编码规范（仿拼豆色卡）
- 格式：`前缀字母 + 两位数字`，如 `S05`、`H12`、`E07`（与拼豆图纸色号体系同构）
- 前缀表：`B`=背景基底 / `S`=皮肤 / `H`=发色 / `M`=金属装备 / `C`=服装 / `E`=特效霓虹 / `U`=UI / `N`=中性描边
- 编号 00-99，单类 100 号，总量 26×100=2600 容量，远超 216 上限
- 色号由工具自动分配并登记，人工只负责审美审查

#### 登记与归并规则
- **新颜色**：首次出现即分配新色号，登记 `色号 - 名称 - HEX - 用途` 四元组
- **容差归并**：与已有色号 RGB 距离 ≤ 容差（默认 ΔRGB ≤ 12）的像素自动归并，防字典膨胀
- **锚点色**：描边 / 皮肤 / 发色等关键色硬编码锚点，禁止容差归并

#### 字典文件协议（2026-08-08 制度化落地）
- **单一事实源**：`ART/COLOR_DICT.json`（git 入库；色号全局唯一，前缀字母+两位数字，不分命名空间）
- 结构：`meta`（version / limit=216 / merge_tolerance=12 / updated）+ `colors`（code → `{hex, rgb, name, usage, anchor}`），`anchor=true` = 硬锚点不容差归并
- **登记工具**：`tools/color_dict.py`（register 提取+归并+登记 / check 216 上限+未登记检查 / quantize 量化到字典色 / extract 统计 / report 汇总）；初始字典由 `tools/gen_color_dict.py` 生成（锚点色板 29 色 + 艾琳图纸 13 色 = 42 色起步）
- **标准流程**：新素材导出 → `register`（自动归并分配色号）→ 人工审查 name/usage/前缀 → `check` 全 PASS 即合规；需严格入字典的素材再跑 `quantize`
- **首个闭环案例（2026-08-08）**：艾琳 elin_walk/elin_idle sheet 经 register（字典 42→132 色）+ quantize → 单帧 93/95 色、`check` PASS，帧动画结构无损（相邻帧差异 242~448 像素）

#### 透明键协议（背景识别，与拼豆图纸惯例一致）
- **每张精灵 PNG 左上角 (0,0) 像素的颜色 = 透明键（背景色）**，全图与该色相同的像素一律视为透明镂空
- 该色只允许用于背景，**禁止出现在角色关键位置**（会造成"透视"破洞）
- 美工在导出时审查（拼豆网站提供此审查功能），工具链同步输出透明键色占用警告
- 引擎侧：Godot 导入后透明键像素 alpha=0，不影响渲染

#### 锚点色板（推荐基础色，32 色，可扩展）

```
=== 暗色基底 (8色) ===
#0d0d12  深空黑    — 最暗背景、描边
#1a1a2e  暗夜蓝    — 主背景
#16213e  深海蓝    — 背景渐变
#0f3460  午夜蓝    — 地面阴影
#1a1a2e  藤紫      — 次要背景
#2d2d3f  暗石灰    — 中间调暗色
#3d3d4f  冷灰      — 地面基础
#4a4a5f  暖灰      — 地面高光

=== 角色与敌人 (8色) ===
#e94560  战斗红    — 玩家主色/血条
#f38181  柔粉红    — 玩家次色/皮肤
#f6c90e  警示黄    — 精英敌人物品
#6bc86b  毒绿      — 毒系敌人/经验
#4e89de  钴蓝      — 冰系敌人/UI蓝
#9d4edd  暗紫      — Boss/稀有
#ff6b35  烈焰橙    — 火系敌人
#2ec4b6  青绿      — 闪电/特殊

=== 霓虹特效 (8色) ===
#00f5ff  电青      — 闪电特效/暴击
#ff00ff  品红      — 魔法特效
#fffd00  电黄      — 金币/拾取高亮
#39ff14  霓虹绿    — 升级/治疗
#ff5e00  烈焰橙    — 火焰特效
#b026ff  紫电      — 穿透特效
#ff073a  激光红    — 远程特效
#ffffff  纯白      — 命中闪白/文字

=== UI 与文字 (8色) ===
#1e1e2f  UI 面板底  — 半透明面板
#2a2a3f  UI 面板边  — 边框
#7a7a8f  UI 次文字  — 次要文字
#cccccc  UI 主文字  — 主文字
#ffffff  UI 高亮文字 — 标题/数值
#5c5c73  UI 禁用    — 灰色不可用
#3a3a4f  UI 槽位底  — 空/占位
#6bc86b  UI 确认绿  — 确认/成功
```

---

## 三、技术规范

### 渲染分辨率
| 参数 | 值 | 说明 |
|------|-----|------|
| 基础视口 | **640 x 360** | 完美等比缩放至 1280x720, 1920x1080, 2560x1440, 3840x2160 |
| 缩放模式 | viewport | 整体像素等比缩放 |
| 宽高比 | keep | 保持 16:9，黑边填充 |
| 缩放方式 | integer | 整数倍缩放，杜绝小数像素 |
| 纹理过滤 | Nearest | 关闭抗锯齿，保持硬边像素 |
| 像素对齐 | 开启 | snap_2d_transforms + snap_2d_vertices |

> **Godot 4 项目设置路径**：
> - Project Settings > Rendering > Textures > Canvas Textures > Default Texture Filter = Nearest
> - Project Settings > Display > Window > Stretch > Mode = viewport
> - Project Settings > Display > Window > Stretch > Aspect = keep
> - Project Settings > Display > Window > Stretch > Scale Mode = integer
> - Project Settings > Rendering > 2D > Snapping > snap_2d_transforms_to_pixel = true
> - Project Settings > Rendering > 2D > Snapping > snap_2d_vertices_to_pixel = true

### 精灵尺寸规范

| 资产类型 | 尺寸 (px) | 说明 |
|----------|-----------|------|
| 玩家角色 | **64 x 64** | 含 1-2px 描边的完整精灵（2026-08-06 由 32px 升级） |
| 普通敌人 | **48 x 48** 或 **64 x 64** | 小型敌人 48px，中型 64px |
| 精英敌人 | **64 x 64** | 带光环/配色区分 |
| Boss | **128 x 128** | 需要更大视觉冲击 |
| 武器图标 | **32 x 32** | 商店/装备栏用（UI 视口 640x360 下保持，不随精灵升级） |
| 道具图标 | **32 x 32** | 商店/装备栏用（UI 视口 640x360 下保持） |
| 属性图标 | **16 x 16** | UI 小图标 |
| 地面 Tile | **64 x 64** | 方格化地面（2026-08-06 升级，支撑后期大地图） |
| 命中特效 | **32 x 32** | 4-8 帧爆破 |
| 拾取物 | **8 x 8** 或 **16 x 16** | 金币/经验/血瓶 |
| 弹幕/投射物 | **8 x 8** 或 **16 x 16** | 小型飞行物 |
| UI 面板 | 按需 9-slice | 可平铺 |
| 标题图 | **640 x 180** | 标题画面 |

### 动画帧数规范

| 资产 | 动画 | 帧数 | FPS | 说明 |
|------|------|------|-----|------|
| 玩家 | idle（呼吸） | 4 | 6 | 上下微移 1px |
| 玩家 | walk（移动） | 6 | 10 | 上下颠簸 + 轻微摆动 |
| 玩家 | hit（受击） | 2 | 8 | 闪白 1 帧 + 正常 1 帧 |
| 玩家 | death（死亡） | 6 | 8 | 倒下消散 |
| 普通敌人 | idle/move | 2-4 | 6-8 | 最简，保性能 |
| 普通敌人 | death | 4 | 8 | 爆裂/消散 |
| 精英敌人 | idle/move | 4-6 | 8 | 稍多帧 |
| Boss | idle | 6 | 8 | 威慑感 |
| Boss | attack | 4-6 | 10 | 技能前摇 |
| 命中特效 | hit | 4-6 | 12 | 快速爆裂 |
| 拾取物 | idle（旋转/浮动） | 4 | 6 | 金币旋转/血瓶浮动 |
| 升级光效 | level_up | 6 | 10 | 扩散光环 |
| 死亡爆散 | enemy_death | 4 | 10 | 碎片飞溅 |

---

## 四、角色设计方向

### 玩家角色（MVP 3 个）

#### 1.「战士」(Fighter)
- **造型**：身披简易铠甲的人形战士，肩宽体壮，手持短剑（或空手，武器由装备系统叠加显示）
- **色彩**：银灰色铠甲 + #e94560 红色披风，深色肤色
- **辨识特征**：红色披风在暗色背景中极醒目，玩家一眼定位
- **尺寸**：64x64，体宽约 28px，身高约 56px

#### 2.「游侠」(Ranger)
- **造型**：斗篷兜帽的瘦长身形，持弓姿态，兜帽遮住面部只露发光的眼
- **色彩**：#4e89de 钴蓝斗篷 + 暗色内衣，兜帽内 #00f5ff 青色微光眼
- **辨识特征**：青色微光眼睛在暗背景中如星点
- **尺寸**：64x64，体宽约 24px，身高约 60px（偏瘦长）

#### 3.「法师」(Mage)
- **造型**：长袍法师，手持法杖，帽檐宽大，袍角飘动
- **色彩**：#9d4edd 暗紫长袍 + #ff00ff 品红法杖宝石，袍底暗色
- **辨识特征**：法杖宝石的品红微光，移动时袍摆动画
- **尺寸**：64x64，体宽约 28px，身高约 60px

### 敌人设计方向（MVP 6 种）

| 敌人 | 造型 | 尺寸 | 色彩 | 行为特征 |
|------|------|------|------|----------|
| **史莱姆** | 半圆胶状，无腿无臂，整体弹跳 | 48x48 | #6bc86b 毒绿 | 慢速直线追击 |
| **骷髅兵** | 人形骨架，持小盾，歪斜步态 | 64x64 | 冷灰 #cccccc | 中速追击 |
| **蝙蝠群** | 翅膀展开的小型飞行体 | 32x32 | #2d2d3f 暗色 + #ff073a 红眼 | 之字形飞行 |
| **火精灵** | 火焰拖尾的球体，无固定形态 | 48x48 | #ff6b35 烈焰橙 → #ff5e00 | 快速冲刺 |
| **精英骑士** | 高大骑士，巨剑/重盾，带光环 | 64x64 | 银灰 + #f6c90e 警示黄光环 | 慢速高伤 |
| **Boss：深渊领主** | 巨大暗影体，多眼，触手 | 128x128 | #1a1a2e + #9d4edd 多眼 #ff073a | 多阶段，全屏技能 |

---

## 五、UI/HUD 布局方案

### 战斗 HUD 布局（640x360 基准视口）

```
┌──────────────────────────────────────────────────────────┐
│  [HP====]  [LV3]              [WAVE 05]    [00:42]       │  ← 顶部条 (高 24px)
│  [XP====]  [💰 234]                                       │
│                                                          │
│                                                          │
│                                                          │
│                     ●  ← 玩家在画面中心                    │
│                                                          │
│                                                          │
│                                                          │
│                                                          │
│  [W1][W2][W3][W4][W5][W6]    [I1][I2][I3][I4]           │  ← 底部栏 (高 36px)
│   武器栏 (6槽)                 道具栏 (4槽)               │
└──────────────────────────────────────────────────────────┘
```

### HUD 元素详情

| 元素 | 位置 | 尺寸 | 样式 |
|------|------|------|------|
| **血条** | 左上 | 120x8px | #e94560 红，底色 #3a3a4f，边框 1px #2a2a3f |
| **经验条** | 血条下方 | 120x4px | #6bc86b 绿，底色 #3a3a4f |
| **等级** | 血条右侧 | 16x16 图标 + 数字 | #f6c90e 黄色数字 |
| **金币** | 等级右侧 | 16x16 金币图标 + 数字 | #fffd00 电黄 |
| **波次** | 顶部居中 | 文字 | #cccccc，字号 8px |
| **计时器** | 顶部右侧 | 文字 | #ffffff，倒计时最后 10s 变 #ff073a |
| **武器栏** | 底部左 | 6x (24x24) 槽位 | 槽底 #3a3a4f，有武器显示图标 |
| **道具栏** | 底部右 | 4x (24x24) 槽位 | 同上，有道具显示图标 |

### 商店界面布局

```
┌──────────────────────────────────────────────────────────┐
│                    ⚔ 商 店 ⚔                              │
│                                                          │
│  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐             │
│  │ 武器图 │ │ 武器图 │ │ 道具图 │ │ 道具图 │             │
│  │  名称  │ │  名称  │ │  名称  │ │  名称  │             │
│  │  属性  │ │  属性  │ │  属性  │ │  属性  │             │
│  │ 💰 50  │ │ 💰 80  │ │ 💰 40  │ │ 💰 60  │             │
│  └────────┘ └────────┘ └────────┘ └────────┘             │
│                                                          │
│           [🔄 刷新 (💰1)]    [✅ 确认]                     │
│                                                          │
│  当前金币: 💰 234      武器: [W1][W2][_][_][_][_]        │
│  道具: [I1][I2][_][_]                                     │
└──────────────────────────────────────────────────────────┘
```

### 字体方向

- **主字体**：像素字体，中文用「方舟像素字体」(Ark Pixel Font) 或「Galmuri」
- **英文字体**：「Press Start 2P」或「VT323」(Google Fonts)
- **字号**：标题 16px，正文 8px，数字 8px
- **字重**：不使用字重区分，用颜色和大小区分层级
- **渲染**：所有文字使用 Nearest 过滤，保持像素硬边

---

## 六、特效方向

### 特效风格原则
- **极短帧数**：4-8 帧完成一个特效循环，总时长 0.3-0.6 秒
- **粒子化**：命中/死亡使用 3-5 个小粒子碎片飞溅，不超过 8 个
- **颜色编码**：不同伤害类型用不同霓虹色（物理=#ff073a红, 火=#ff5e00橙, 冰=#00f5ff青, 电=#b026ff紫, 毒=#39ff14绿）
- **弹字反馈**：暴击数字放大 1.5x + #fffd00 电黄；普通伤害白色；治疗 #39ff14 绿色

### MVP 特效清单

| 特效 | 帧数 | 尺寸 | 说明 |
|------|------|------|------|
| 命中溅射 | 4 | 64x64 | 白色闪光 + 碎片飞溅 |
| 暴击爆发 | 6 | 64x64 | #fffd00 黄色星形放射 |
| 敌人死亡 | 4 | 64x64 | 碎片飞溅 + 淡出 |
| 升级光环 | 6 | 64x64 | #39ff14 绿色扩散圆环 |
| 拾取闪烁 | 4 | 16x16 | 金币 #fffd00 / 经验 #6bc86b / 血瓶 #e94560 |
| 弹幕拖尾 | 2 | 8x8 | 单色半透明渐变 |
| 火焰范围 | 4 | 64x64 | #ff5e00 橙色跳动 |
| 冰冻覆盖 | 2 | 64x64 | #00f5ff 青色覆盖 |
| Boss 警告 | 4 | 64x64 | 红色圆圈预警范围标记 |

### 特效色机制（升级奖励规则绑定，Backlog 2026-08-06）

- **规则奖励 → 触发指定特效 → 特效实现包含「替换对应坐标区域色块为特效色块」**
- 例：魔法师眼睛增亮（特殊升级奖励）= 替换眼睛区域色块为特效霓虹色（E 系色号）
- 落地时按具体特效三选一实现路径（**不推荐运行时逐像素改纹理**）：
  1. 升级换 sprite 变体贴图（最便宜最稳）
  2. shader 按区域调色（不换图，动态）
  3. 叠加发光层（最灵活，多一层 draw）

---

## 七、MVP 资产清单

> 以下为最小可行版本(MVP)所需的全部美术资产。
> 标注 [优先级] 的资产为必须先完成的。

### 7.1 角色精灵

| ID | 名称 | 尺寸 | 动画 | 总帧数 | 优先级 | 文件路径 |
|----|------|------|------|--------|--------|----------|
| P01 | 战士 idle | 64x64 | 4帧 | 4 | P0 | assets/sprites/characters/fighter_idle.png |
| P02 | 战士 walk | 64x64 | 6帧 | 6 | P0 | assets/sprites/characters/fighter_walk.png |
| P03 | 战士 hit | 64x64 | 2帧 | 2 | P1 | assets/sprites/characters/fighter_hit.png |
| P04 | 战士 death | 64x64 | 6帧 | 6 | P1 | assets/sprites/characters/fighter_death.png |
| P05 | 游侠 idle | 64x64 | 4帧 | 4 | P1 | assets/sprites/characters/ranger_idle.png |
| P06 | 游侠 walk | 64x64 | 6帧 | 6 | P1 | assets/sprites/characters/ranger_walk.png |
| P07 | 法师 idle | 64x64 | 4帧 | 4 | P2 | assets/sprites/characters/mage_idle.png |
| P08 | 法师 walk | 64x64 | 6帧 | 6 | P2 | assets/sprites/characters/mage_walk.png |

> **Sprite Sheet 格式**：每个动画横向排列，单帧 64x64，整图 64*N x 64。
> 留 1px 边距防止采样溢出。

### 7.2 敌人精灵

| ID | 名称 | 尺寸 | 动画 | 总帧数 | 优先级 | 文件路径 |
|----|------|------|------|--------|--------|----------|
| E01 | 史莱姆 move | 48x48 | 2帧 | 2 | P0 | assets/sprites/enemies/slime_move.png |
| E02 | 史莱姆 death | 48x48 | 4帧 | 4 | P0 | assets/sprites/enemies/slime_death.png |
| E03 | 骷髅兵 move | 64x64 | 4帧 | 4 | P0 | assets/sprites/enemies/skeleton_move.png |
| E04 | 骷髅兵 death | 64x64 | 4帧 | 4 | P0 | assets/sprites/enemies/skeleton_death.png |
| E05 | 蝙蝠 move | 32x32 | 4帧 | 4 | P1 | assets/sprites/enemies/bat_move.png |
| E06 | 蝙蝠 death | 32x32 | 2帧 | 2 | P1 | assets/sprites/enemies/bat_death.png |
| E07 | 火精灵 move | 48x48 | 4帧 | 4 | P1 | assets/sprites/enemies/firefly_move.png |
| E08 | 火精灵 death | 48x48 | 4帧 | 4 | P1 | assets/sprites/enemies/firefly_death.png |
| E09 | 精英骑士 move | 64x64 | 4帧 | 4 | P2 | assets/sprites/enemies/eliteknight_move.png |
| E10 | 精英骑士 death | 64x64 | 4帧 | 4 | P2 | assets/sprites/enemies/eliteknight_death.png |
| E11 | Boss 深渊领主 idle | 128x128 | 6帧 | 6 | P2 | assets/sprites/enemies/boss_idle.png |
| E12 | Boss 深渊领主 attack | 128x128 | 4帧 | 4 | P2 | assets/sprites/enemies/boss_attack.png |
| E13 | Boss 深渊领主 death | 128x128 | 6帧 | 6 | P2 | assets/sprites/enemies/boss_death.png |

### 7.3 武器图标

| ID | 名称 | 尺寸 | 优先级 | 文件路径 |
|----|------|------|--------|----------|
| W01 | 短剑（近战） | 32x32 | P0 | assets/sprites/ui/w_shortsword.png |
| W02 | 手枪（远程） | 32x32 | P0 | assets/sprites/ui/w_pistol.png |
| W03 | 弓（远程） | 32x32 | P0 | assets/sprites/ui/w_bow.png |
| W04 | 法杖（范围） | 32x32 | P1 | assets/sprites/ui/w_staff.png |
| W05 | 双刀（近战） | 32x32 | P1 | assets/sprites/ui/w_dualblade.png |
| W06 | 步枪（远程） | 32x32 | P1 | assets/sprites/ui/w_rifle.png |
| W07 | 火焰球（范围） | 32x32 | P1 | assets/sprites/ui/w_fireball.png |
| W08 | 闪电链（范围） | 32x32 | P2 | assets/sprites/ui/w_chain.png |

### 7.4 道具图标

| ID | 名称 | 尺寸 | 优先级 | 文件路径 |
|----|------|------|--------|----------|
| I01 | 生命药水 | 32x32 | P0 | assets/sprites/ui/i_potion_hp.png |
| I02 | 力量护符 | 32x32 | P0 | assets/sprites/ui/i_charm_str.png |
| I03 | 速度之靴 | 32x32 | P0 | assets/sprites/ui/i_boots_spd.png |
| I04 | 护甲片 | 32x32 | P0 | assets/sprites/ui/i_armor.png |
| I05 | 暴击之眼 | 32x32 | P1 | assets/sprites/ui/i_eye_crit.png |
| I06 | 幸运硬币 | 32x32 | P1 | assets/sprites/ui/i_coin_luck.png |
| I07 | 吸血牙 | 32x32 | P1 | assets/sprites/ui/i_fang_lifesteal.png |
| I08 | 范围透镜 | 32x32 | P2 | assets/sprites/ui/i_lens_range.png |

### 7.5 UI 元素

| ID | 名称 | 尺寸 | 优先级 | 文件路径 |
|----|------|------|--------|----------|
| U01 | 血条底 | 120x8 + 9-slice | P0 | assets/sprites/ui/bar_hp_bg.png |
| U02 | 血条填充 | 120x8 + 9-slice | P0 | assets/sprites/ui/bar_hp_fill.png |
| U03 | 经验条底 | 120x4 + 9-slice | P0 | assets/sprites/ui/bar_xp_bg.png |
| U04 | 经验条填充 | 120x4 + 9-slice | P0 | assets/sprites/ui/bar_xp_fill.png |
| U05 | 金币图标 | 16x16 | P0 | assets/sprites/ui/icon_coin.png |
| U06 | 等级图标 | 16x16 | P0 | assets/sprites/ui/icon_level.png |
| U07 | 武器槽底 | 24x24 | P0 | assets/sprites/ui/slot_weapon.png |
| U08 | 道具槽底 | 24x24 | P0 | assets/sprites/ui/slot_item.png |
| U09 | 商店面板 | 9-slice | P0 | assets/sprites/ui/panel_shop.png |
| U10 | 商店卡片 | 9-slice | P0 | assets/sprites/ui/panel_card.png |
| U11 | 刷新按钮 | 9-slice | P0 | assets/sprites/ui/btn_reroll.png |
| U12 | 确认按钮 | 9-slice | P0 | assets/sprites/ui/btn_confirm.png |
| U13 | 属性图标x10 | 16x16 每个 | P1 | assets/sprites/ui/icons_stats.png |

### 7.6 地面/背景 Tileset

| ID | 名称 | 尺寸 | 优先级 | 文件路径 |
|----|------|------|--------|----------|
| T01 | 石地板 tileset | 64x64 x4 变体 | P0 | assets/sprites/effects/tileset_ground.png |
| T02 | 裂纹/血迹叠加 | 64x64 x3 | P1 | assets/sprites/effects/tileset_overlay.png |
| T03 | 边界墙 | 64x64 x4 | P0 | assets/sprites/effects/tileset_wall.png |
| T04 | 场景装饰（骸骨/碎石） | 32x32 x4 | P2 | assets/sprites/effects/tileset_deco.png |

### 7.6.1 大地图 Tileset 规格（2026-08-06 立项，交主程落地）

> 背景：地面 Tile 从 32px 升至 64px（与角色基准一致，1 tile = 1 网格）。后期将加入**有逻辑的完整大地图**增强沉浸感（参考明日方舟集成战略的地图叙事感）。

**设计分层（美术产出 3 层 + 1 套规则）**
1. **L1 基础地面层**：64×64 可平铺纹理（石地/草地/沙地等，每地形 ≥4 变体防重复感）
2. **L2 过渡边缘层**：地形边界混合变体（如石地→草地过渡 8 方向 + 角），配合 Godot TileSet **Terrains（自动地形）**，艺术家只画边界变体，引擎自动过渡
3. **L3 装饰层**：稀疏摆放（骸骨/碎石/植被/星骸碎片），32×32 起，不参与碰撞或仅小碰撞，用于打破平铺重复感

**大地图两种落地路线（主程选型）**
- **A. 手绘整图切 tile（沉浸感最强）**：艺术家绘制完整大地图（如 4096×4096）→ 按 64px 网格切片 → TileMap 加载。适合 Boss 区域、商店、事件节点等关键场景
- **B. 程序化 tile 拼接（复用性最高）**：L1/L2 变体 + Terrains 自动过渡，用于普通战斗区域随机生成

**沉浸感增强（后续迭代）**
- 远景层：Parallax 2D 分层背景（暗色山脉/星骸剪影）
- 迷雾/光照：暗色舞台 + 局部光源（与角色霓虹色呼应）
- 地标节点：Boss 区/商店/事件区用 L3 装饰 + 专属 tile 变体标识

**落地分工**
- 主程（godot-dev）：TileSet/TileMapLayer 配置、Terrains 规则、场景加载、parallax
- 美术（pixel-artist）：L1/L2/L3 素材、过渡变体、整图切片
- 验收：64px 网格对齐、Nearest 无混色、过渡无缝、透明键协议生效

### 7.7 特效精灵

| ID | 名称 | 尺寸 | 帧数 | 优先级 | 文件路径 |
|----|------|------|------|--------|----------|
| F01 | 命中溅射 | 64x64 | 4 | P0 | assets/sprites/effects/fx_hit.png |
| F02 | 暴击爆发 | 64x64 | 6 | P0 | assets/sprites/effects/fx_crit.png |
| F03 | 敌人死亡 | 64x64 | 4 | P0 | assets/sprites/effects/fx_death.png |
| F04 | 升级光环 | 64x64 | 6 | P0 | assets/sprites/effects/fx_levelup.png |
| F05 | 拾取闪烁 | 16x16 | 4 | P0 | assets/sprites/effects/fx_pickup.png |
| F06 | 弹幕-物理 | 8x8 | 1 | P0 | assets/sprites/effects/fx_proj_physical.png |
| F07 | 弹幕-火焰 | 8x8 | 2 | P1 | assets/sprites/effects/fx_proj_fire.png |
| F08 | 弹幕-冰 | 8x8 | 2 | P1 | assets/sprites/effects/fx_proj_ice.png |
| F09 | 弹幕-电 | 8x8 | 2 | P1 | assets/sprites/effects/fx_proj_lightning.png |
| F10 | 火焰范围 | 64x64 | 4 | P2 | assets/sprites/effects/fx_aoe_fire.png |
| F11 | Boss 警告 | 64x64 | 4 | P2 | assets/sprites/effects/fx_boss_warn.png |

### 7.8 字体

| ID | 名称 | 用途 | 优先级 | 文件路径 |
|----|------|------|--------|----------|
| FO01 | Ark Pixel 12px | 中文正文/数字 | P0 | assets/fonts/ark-pixel-12px.ttf |
| FO02 | Press Start 2P 8px | 英文标题 | P0 | assets/fonts/press-start-2p.ttf |

---

## 八、资产统计汇总

| 类别 | P0 (必须) | P1 (重要) | P2 (可延后) | 合计 |
|------|-----------|-----------|-------------|------|
| 角色精灵 | 6 | 4 | 4 | 14 |
| 敌人精灵 | 8 | 6 | 6 | 20 |
| 武器图标 | 4 | 4 | - | 8 |
| 道具图标 | 4 | 4 | - | 8 |
| UI 元素 | 12 | 1 | - | 13 |
| 地面/背景 | 3 | 1 | 1 | 5 |
| 特效精灵 | 7 | 3 | 1 | 11 |
| 字体 | 2 | - | - | 2 |
| **合计** | **46** | **23** | **12** | **81** |

> **MVP 优先完成所有 P0 资产（46 个），即可搭建可玩原型。**

---

## 九、Godot 4 导入规范

### 通用导入设置
```
1. 纹理过滤: Nearest
   → 对每个 .png 在 Import 面板设 Filter = Nearest, 勾选 Mipmaps = Off
2. 压缩: Lossless
   → Compression > Mode = Lossless
3. 像素对齐: 全局开启
   → Project Settings > Rendering > 2D > Snapping
4.精灵表切割: 使用 AnimatedSprite2D 或 SpriteFrames
   → 每个 sprite sheet 用 Godot 的 SpriteFrames 编辑器自动切割
   → 水平帧数 = 总帧数, 垂直帧数 = 1
```

### 目录结构建议
```
assets/
  sprites/
    characters/
      fighter_idle.png        ← 32x128 (4帧横排)
      fighter_walk.png        ← 32x192 (6帧横排)
      fighter_hit.png         ← 32x64  (2帧横排)
      fighter_death.png       ← 32x192 (6帧横排)
      ranger_idle.png
      ...
    enemies/
      slime_move.png          ← 24x48  (2帧横排)
      skeleton_move.png       ← 32x128 (4帧横排)
      ...
    ui/
      bar_hp_bg.png
      bar_hp_fill.png
      icon_coin.png
      slot_weapon.png
      ...
    effects/
      fx_hit.png              ← 32x128 (4帧横排)
      fx_crit.png             ← 32x192 (6帧横排)
      tileset_ground.png      ← 128x32 (4 tile 横排)
      ...
  fonts/
    ark-pixel-12px.ttf
    press-start-2p.ttf
```

---

## 十、工作流建议

### 1. 制作工具
- **像素绘制**：Aseprite（推荐，支持动画/调色板/sprite sheet 导出）
- **备用**：LibreSprite（开源免费）、PixelLab（在线）
- **调色板**：使用本文档定义的**色板字典**（216 色上限 + 锚点色板）的 .aseprite / .hex 文件分发

### 2. 制作流程
1. 确认色板字典（加载锚点色板 .aseprite 文件，新色自动登记）
2. 草图：先画 1 帧静态精灵，确认轮廓和配色
3. 审查：与 team-lead 确认设计方向
4. 动画：基于确认的静态帧制作 idle/walk/hit/death 动画
5. 导出：横向排列导出 PNG sprite sheet，1px 安全边距
6. 导入：放入 assets/sprites/ 对应目录，配置 Godot 导入设置
7. 验证：在 Godot 中预览动画效果，确认无溢出/无错位

### 3. 命名规范
- 文件名全小写 + 下划线分隔
- 格式：`<角色名>_<动画名>.png`
- 示例：`fighter_idle.png`、`skeleton_move.png`、`fx_hit.png`
- UI 通用元素前缀：`bar_`、`icon_`、`slot_`、`panel_`、`btn_`
- 特效前缀：`fx_`
- 地面前缀：`tileset_`

---

## 十一、后续扩展方向（非 MVP）

以下内容在 MVP 验证后逐步添加：

- [ ] 更多角色（坦克/刺客/召唤师等）
- [ ] 更多敌人类型（自爆/远程/分裂等）
- [ ] 地图变体（沙漠/冰原/岩浆/丛林）
- [ ] 天气特效（雨/雾/落叶粒子）
- [ ] 装备外观变化（穿不同护甲/武器的精灵叠加）
- [ ] 皮肤系统（角色配色变体）
- [ ] 动画扩展（攻击动作/技能前摇/奔跑）
- [ ] 更多 UI 精灵（设置面板/角色选择/存档界面）
- [ ] 暗黑化处理（波次越高背景越暗，氛围递进）

---

## 十二、资产扩展规范（数据驱动新增角色 / 怪物）

> 本项目采用**数据驱动架构**：新增角色或敌人 = 新增美术资产 + 一条数据记录，**无需修改任何 GDScript 代码**。
> `SpriteFrameFactory` 运行时按帧宽切帧，`DataLoader` 统一加载并缓存 JSON。本规范把"帧 strip 约定"固化为硬契约，供内部美术与外包参照。

### 12.1 扩展流程

1. **绘制帧 strip PNG**：每个动画横向排列，单帧尺寸见第十四章规格表。
2. **放入目录**：角色 `assets/sprites/characters/`、敌人 `assets/sprites/enemies/`。
3. **登记数据**：在 `data/characters.json` 或 `data/enemies.json` 加一条目（字段见 12.3）。
4. **自动加载**：`DataLoader` 读 JSON → `SpriteFrameFactory` 按帧宽切帧 → 进缓存。
5. **进入游戏**：`EnemySpawner` / 角色系统按 `id` 取用，**零代码改动，自动出现**。

### 12.2 目录与命名约定

- 文件名全小写 + 下划线分隔（与第十章一致）。
- 格式：`<id>_<anim>.png`，`{id}` 全局唯一。
- 角色：`fighter_idle.png` / `fighter_walk.png` / `fighter_hit.png` / `fighter_death.png`
- 敌人：`slime_move.png` / `slime_death.png` / `skeleton_move.png` ...
- 多套动画（idle/walk/attack/hit/death）各自独立文件，互不耦合。

### 12.3 数据条目字段

`enemies.json` / `characters.json` 新增条目示例：

```json
{
  "id": "goblin",
  "name": "哥布林",
  "sprite": "res://assets/sprites/enemies/goblin_move.png",
  "frames": 4,
  "fps": 6,
  "death_sprite": "res://assets/sprites/enemies/goblin_death.png",
  "collision_radius": 12,
  "palette_variant": "poison"
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string | 全局唯一标识，与文件名前缀一致 |
| `name` | string | 显示名 |
| `sprite` | string | 主动画帧 strip 路径（res://） |
| `frames` | int | 横向帧数，`SpriteFrameFactory` 据此切帧 |
| `fps` | int | 播放帧率 |
| `death_sprite` | string | 死亡动画帧 strip（可选） |
| `collision_radius` | int | 碰撞 / 拾取半径（像素） |
| `palette_variant` | string | 指向色板字典的色系（B/S/H/M/C/E/U/N），用于换色变体 |

### 12.4 帧 strip 硬约束

- **横向排列**，单帧尺寸见第十四章规格表。
- 整图宽 = 帧宽 × 帧数；整图高 = 帧宽（单行动画）。
- 帧宽 = 精灵基准宽（角色 64、杂兵 48、Boss 128）。
- 留 **1px 安全边距**防采样溢出（与第七章一致）。
- 示例：4 帧 64px idle = `256×64` PNG；2 帧 48px move = `96×48` PNG。

### 12.5 进阶：导出 SpriteFrames .tres（Phase 2 推荐）

当动画套数增多（idle/walk/attack/hit/death 多套），运行时切帧不够灵活。建议美术导出 Godot 原生 **`SpriteFrames .tres`** 资源，程序仅引用资源路径，美术与程序彻底解耦。此方式在动画复杂后优于 12.1 的运行时切帧。

---

## 十三、像素化转制 SOP（从外部美术取材）

> 适用场景：用市面主流美术设计作风格参考，经像素化转制为本项目素材。
> **自动工具只能产出粗糙底稿，100% 需人工精修**，否则得到的是马赛克而非像素艺术。

### 13.1 适用边界与版权红线

- 主流作品**仅作风格参考**（配色 / 剪影 / 节奏），**禁止直接扒图像素化后商用**。
- 正式素材来源优先级：**原创** > **授权市场**（itch.io、Kenney、CraftPix、OpenGameArt）> **AI 生成后自调色板精修**。
- AI 生成素材版权更干净，但需自行确认生成平台的商用条款。

### 13.2 工具清单

| 用途 | 工具 | 说明 |
|------|------|------|
| 自动转像素（底稿） | **Pixelator**（桌面，商业） | 专做照片 / 插画转像素，效果最佳 |
| 在线快转 | **Pixelicious**（pixelicious.xyz，免费） | 上传 → 选粒度 → 下载，适合试稿 |
| 批量脚本 | **ImageMagick**（CLI） | 适合把一整套素材批量处理 |
| AI 生成 | Stable Diffusion + pixel-art LoRA / Pixel-Art.ai | 直接产出像素风，规避取材版权 |
| 手动精修（必做） | **Aseprite**（标杆，可脚本批量导出） | 抖动 / 轮廓 / 调色板量化 |
| 免费替代 | Pixel Studio / LibreSprite | Aseprite 平替 |

### 13.3 标准工序（5 步，第 3 步最关键）

1. **缩到目标小尺寸**（如宽 64px）——这一步决定像素粒度。
2. **最近邻放大**回显示尺寸（保持硬边，不开抗锯齿）。
3. **提取用色并登记入色板字典**（≤216 色，容差内归并邻近色，见第二章）——★ 漏掉这步素材会"花"，脱离统一感。
4. **加 1px 硬描边**（接近 `#0d0d12`），统一暗色像素风剪影。
5. **Aseprite 精修**抖动与轮廓细节。

### 13.4 批量命令（ImageMagick）

```bash
# 1) 缩小到目标尺寸并保持硬边（Point 过滤器 = 最近邻）
magick in.png -resize 64x64! -filter Point -scale 1000% draft.png

# 2) 按需套用锚点色板（palette.png 为 1px 宽条，见第二章；新素材默认提取+登记，不强制 remap）
magick draft.png -remap palette.png goblin_move.png
```

> 注意：当前已产素材为 RGBA 未强制 Indexed。新素材一律**提取实际用色 → 登记色板字典（≤216 色）→ 容差归并**；或在 Godot 用后处理 shader 把颜色 snap 到锚点色板，避免后期素材增多后逐步脱离统一感。

---

## 十四、标准图像规格总表（速查）

| 项目 | 规格 | 说明 |
|------|------|------|
| 基准网格 | **64px** | 所有精灵对齐 8 / 16 倍数 |
| 角色 | 64×64 | 俯视角，单帧或 4 方向 |
| 杂兵 | 48×48 | 同屏数量优先 |
| 精英 | 64×64 | 加描边 / 霓虹描边区分 |
| Boss | 128×128 | 视觉权重 |
| 帧 strip | 横向排列，帧宽 = 精灵尺寸，高固定 | 如 4 帧 idle = 256×64 |
| 帧率 | idle 4–6fps（呼吸）、move 6–8fps、death 一次性 | 低帧保性能 |
| 颜色 | **字典登记制，≤216 色**（色板字典 + 容差归并） | 统一感来源 |
| 描边 | 1-2px 深色（接近 `#0d0d12`） | 硬朗剪影 |
| 透明键 | **左上角 (0,0) 像素 = 背景色**，全图同色镂空 | 与拼豆图纸惯例一致 |
| 导出 | PNG 无损，RGBA 或 Indexed | 关闭压缩损失 |

> 本表与第三章「精灵尺寸规范 / 动画帧数规范」及第七章资产清单互为参照，扩展新素材时以上表为硬标准。
