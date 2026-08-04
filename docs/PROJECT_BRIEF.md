# 项目简报：Roguelike Studio（类 Brotato 俯视角肉鸽）

> **用途**：① 复制下方「▶ 项目指令」段到 WorkBuddy 项目组「指令」框；② 整份上传到项目资产库，供新人 Agent 通过 RAG 获得上下文，做到零重复沟通即可接手。

---

## ▶ 项目指令（直接粘贴到项目组「指令」框）

你正在协作开发一款类 Brotato 的俯视角自动射击肉鸽游戏（项目名 Roguelike Studio）。硬性背景：引擎 Godot 4.3 + GDScript，目标平台 PC(Steam)，架构必须数据驱动、低耦合、方便扩展玩法与美术。运行方式：用 `tools/Godot_v4.3-stable_win64.exe` 打开 `project.godot` 按 F5；打包用 `--export-pack` 生成 `build/RoguelikeStudio.pck` 并把引擎 exe 改名为同前缀 exe 同目录，双击即玩。约定三条必须守：①新增角色/怪物 = 一条 JSON + 一张横向帧 strip PNG，零代码改动（DataLoader 自动缓存）；②帧 strip 横向排列、帧宽=精灵尺寸（如 4 帧@32 = 128x32）；③美术 32px 基准网格、Indexed 32 色调色板、Nearest 过滤、1px 描边。像素化用 `tools/pixelate_batch.py`（网格降采样+代表色+32 色量化）。架构分层：Autoload(GameManager/DataLoader/main) → 系统层(WaveManager/Economy/Inventory/EnemySpawner) → 实体层(Player/Enemy/Weapon+WeaponController) → UI 层(HUD/Shop) → 工具层(SpriteFrameFactory/IconAtlas/VfxPlayer)。当前已接通玩家移动+鼠标方向自动射击、弹丸命中、敌人接触伤害、死亡特效、HUD、金币掉落；Phase 2 待补：武器/道具系统、商店购买生效、经验升级、角色选择、元素反应、音效、波次清场判定。代码走 git 远程（本地仓库已 init，76 文件/0.25MB，已排除引擎与 build）；大文件/可玩 demo 走项目组资产库。改动前先读 `docs/GDD.md` 与 `docs/ART_STYLE.md`。

---

## 1. 项目定位

- 类型：类 Brotato 俯视角自动射击肉鸽生存
- 引擎：Godot 4.3（GL Compatibility 渲染器，640×360 视口，2× 整数缩放，Nearest 过滤，像素对齐）
- 语言：GDScript
- 目标平台：PC (Steam) 优先
- 当前阶段：Phase 1 —— 游戏能动 + 架构合理可扩展（非堆玩法）
- 团队：roguelike-studio（game-designer / godot-dev / pixel-artist）

## 2. 运行与构建

| 动作 | 命令 / 路径 |
|------|------|
| 引擎本体 | `tools/Godot_v4.3-stable_win64.exe` |
| 打开项目 | 用引擎打开 `project.godot`，按 F5 运行 |
| 无头验证 | `python` subprocess 跑 `--headless` 抓日志（bash 重定向不持久，必须用 Python） |
| 打包 | `tools\Godot_v4.3-stable_win64.exe --headless --path . --export-pack "Windows Desktop" build\RoguelikeStudio.pck`，再 `cp` 引擎 exe 为 `build\RoguelikeStudio.exe`（须同目录） |
| 像素化工具 | `tools\pixelate_batch.py --input <raw> --output <out> --width 32 --mode mean --palette` |

## 3. 架构分层

- **Autoload**：`GameManager`（状态机 + 信号驱动）、`DataLoader`（单例，统一加载/缓存 JSON + 成长公式）、`main`
- **系统层**：`WaveManager`、`Economy`、`Inventory`、`EnemySpawner`
- **实体层**：`Player`、`Enemy`、`Weapon` + `WeaponController`
- **UI 层**：`HUD`、`Shop`
- **工具层**：`SpriteFrameFactory`（运行时按帧宽切帧 strip）、`IconAtlas`、`VfxPlayer`
- 约定：固定竞技场，**无 Camera2D**（世界坐标 = 屏幕坐标，中心 320,180）；信号驱动低耦合

## 4. 关键约定（必须遵守）

1. **数据驱动扩展**：新增角色/怪 = 一张帧 strip PNG + 一条 JSON 记录，代码零改动。`DataLoader` 自动进缓存，`EnemySpawner` 按 id 取。
2. **帧 strip 硬契约**：横向排列，帧宽 = 精灵尺寸（如 4 帧@32 宽 = 128×32）。`SpriteFrameFactory` 按帧宽切。
3. **美术规格**：基准网格 32px、杂兵 24、精英 32、Boss 64；Indexed 32 色调色板（ART_STYLE 调色板）；Nearest 过滤；1px 深色描边；PNG 无损。
4. **像素化**：外部美术取材先做风格参考（禁直接扒图像素化商用），用 `tools/pixelate_batch.py` 量化到 32 色。
5. **属性系统**：攻/速/暴/移/甲/闪/命/回/范/拾，统一在 `stats.json` + `DataLoader` 成长公式。

## 5. 当前进度（截至 2026-08-04）

- ✅ 已接通：玩家移动 + 鼠标方向自动射击、弹丸命中扣血/击杀掉金币、敌人接触伤害（0.4s 无敌帧）、死亡特效、HUD、金币掉落
- ✅ 已 git 化：本地仓库 `ce848af`，76 文件 / 合计 0.25MB；`.gitignore` 排除 Godot 引擎(~133MB)、`/build/`、`.workbuddy/`、测试产物、`.zip`；`.gitattributes` 统一换行
- 📄 文档：`docs/GDD.md`、`docs/ART_STYLE.md`（含十二~十四章：资产扩展规范 / 像素化 SOP / 标准规格表）
- ⏳ Phase 2 待补：武器/道具系统、商店购买生效、经验升级、角色选择、元素反应、音效、波次清场判定（当前波次纯计时制，怪跨波累积）

## 6. 目录与关键文件速查

```
project.godot              视口/Autoload/输入配置
export_presets.cfg         Windows Desktop 导出预设
data/*.json                enemies(23)/weapons(29)/items(39)/characters(6)/waves(20)/elements/stats
scripts/                   18+ GDScript（autoload/player/enemy/weapons/items/systems/ui/effects/utils）
scenes/                    Main/Player/Enemy/EnemySpawner/WaveManager/HUD/Shop/VfxPlayer/Projectile
assets/sprites/            26 PNG（角色/敌人/特效/UI/地面/图标），均 RGBA 帧 strip
tools/pixelate_batch.py    批量像素化脚本（Pillow）
docs/GDD.md, ART_STYLE.md  设计文档与美术规范
build/RoguelikeStudio.exe+pck  可分发可玩 demo（不进 git）
```

## 7. 新人 Agent 上手 5 步

1. 读 `docs/GDD.md` + `docs/ART_STYLE.md`（尤其十二~十四章）
2. 读工作区根项目记忆（MEMORY）了解历史决策
3. 用引擎跑一次游戏，headless 验证 baseline 零错误
4. 改动严守「数据驱动 + 帧 strip + 32 色」约定
5. 大文件（引擎/build demo/美术原图）走云盘资产库共享；代码走 git 远程

## 8. 团队专家复用

roguelike-studio 团队含 `game-designer` / `godot-dev` / `pixel-artist` 三类专家，可在项目组挂为「项目专家」让成员直接召唤，避免每个 Agent 重新理解项目。
