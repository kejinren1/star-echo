# 项目简报：Roguelike Studio（类 Brotato 俯视角肉鸽）

> **用途**：① 复制下方「▶ 项目指令」段到 WorkBuddy 项目组「指令」框；② 整份上传到项目资产库，供新人 Agent 通过 RAG 获得上下文，做到零重复沟通即可接手。

---

## ▶ 项目指令（直接粘贴到项目组「指令」框）

你正在协作开发一款类 Brotato 的俯视角自动射击肉鸽游戏（项目名 Roguelike Studio）。硬性背景：引擎 Godot 4.3 + GDScript，目标平台 PC(Steam)，架构必须数据驱动、低耦合、方便扩展玩法与美术。运行方式：用 `tools/Godot_v4.3-stable_win64.exe` 打开 `project.godot` 按 F5；改动前后各跑一次 `python tools/baseline_check.py`（双阶段 headless 自校验，必须 BASELINE CLEAN 才提交）；发布一条命令 `python tools/build_release.py --zip`（导出 pck→校验 exe→实测启动→出分发包，任一步失败非零退出）。约定三条必须守：①新增角色/怪物 = 一条 JSON + 一张横向帧 strip PNG，零代码改动（DataLoader 自动缓存）；②帧 strip 横向排列、帧宽=精灵尺寸（如 4 帧@32 = 128x32）；③美术 32px 基准网格、Indexed 32 色调色板、Nearest 过滤、1px 描边。像素化用 `tools/pixelate_batch.py`（网格降采样+代表色+32 色量化）。架构分层：Autoload(GameManager/DataLoader/main) → 系统层(WaveManager/Economy/Inventory/EnemySpawner) → 实体层(Player/Enemy/Weapon+WeaponController) → UI 层(HUD/Shop) → 工具层(SpriteFrameFactory/IconAtlas/VfxPlayer)。当前已接通玩家移动+鼠标方向自动射击、弹丸命中、敌人接触伤害、死亡特效、HUD、金币掉落；Phase 2 待补：武器/道具系统、商店购买生效、经验升级、角色选择、元素反应、音效、波次清场判定。代码走 git 远程（仓库 112 文件，已排除引擎 133MB 与 build 产物）；大文件/可玩 demo 走项目组资产库。`addons/godot_mcp` 已入库但未启用且需 Godot 4.6，升级未定前不要启用。改动前先读 `docs/GDD.md` 与 `docs/ART_STYLE.md`。

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
| 无头验证 | `python tools/baseline_check.py` → 输出 PASS/FAIL，`BASELINE CLEAN` 才允许提交 |
| 打包发布 | `python tools/build_release.py --zip` → 导出 pck + 校验 exe + 实测启动 + 出 `build.zip` |
| 手工打包（备用） | `tools\Godot_v4.3-stable_win64.exe --headless --path . --export-pack "Windows Desktop" build\RoguelikeStudio.pck`，再 `cp` 引擎 exe 为 `build\RoguelikeStudio.exe`（须同目录同前缀，否则 pck 不自动加载） |
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
- ✅ 已 git 化：本地仓库 5 次提交（HEAD `3da8aa8`），112 文件；`.gitignore` 排除 Godot 引擎(~133MB)、`/build/`、`.workbuddy/`、`tools/_*` 临时产物、`.zip`；`.gitattributes` 统一换行
- ✅ 工程化工具：`tools/baseline_check.py`（双阶段 headless 自校验）、`tools/build_release.py`（一条命令发布）；`export_presets.cfg` 已排除 `addons/*, docs/*, tools/*` 不进玩家 pck
- 📄 文档：`docs/GDD.md`、`docs/ART_STYLE.md`（含十二~十四章：资产扩展规范 / 像素化 SOP / 标准规格表）
- ⚠️ 未决事项：`addons/godot_mcp` 已入库但**未启用**，其 `plugin.cfg` 要求 Godot **4.6**，而项目锁定 **4.3**（`tools/` 下已下载 4.6 压缩包）。是否升级引擎需 Owner 拍板，升级前不要启用该插件
- ⏳ Phase 2 待补：武器/道具系统、商店购买生效、经验升级、角色选择、元素反应、音效、波次清场判定（当前波次纯计时制，怪跨波累积）

## 6. 目录与关键文件速查

```
project.godot              视口/Autoload/输入配置
export_presets.cfg         Windows Desktop 导出预设
data/*.json                enemies(23)/weapons(29)/items(39)/characters(6)/waves(20)/elements/stats
scripts/                   18+ GDScript（autoload/player/enemy/weapons/items/systems/ui/effects/utils）
scenes/                    Main/Player/Enemy/EnemySpawner/WaveManager/HUD/Shop/VfxPlayer/Projectile
assets/sprites/            26 PNG（角色/敌人/特效/UI/地面/图标），均 RGBA 帧 strip
addons/godot_mcp/          MCP 编辑器插件（未启用，需 Godot 4.6，见未决事项）
tools/pixelate_batch.py    批量像素化脚本（Pillow）
tools/baseline_check.py    headless 双阶段自校验（改动前后必跑）
tools/build_release.py     一条命令发布构建（--zip 出分发包）
tools/_*                   临时产物，永不入库（下划线约定）
docs/GDD.md, ART_STYLE.md  设计文档与美术规范
build/RoguelikeStudio.exe+pck  可分发可玩 demo（不进 git，走资产库）
```

## 7. 新人 Agent 上手 5 步

1. 读 `docs/GDD.md` + `docs/ART_STYLE.md`（尤其十二~十四章）
2. 读工作区根项目记忆（MEMORY）了解历史决策
3. 跑 `python tools/baseline_check.py`，确认 `BASELINE CLEAN`（注：Godot 日志用 bash 重定向不持久，必须走 Python subprocess，脚本已封装）
4. 改动严守「数据驱动 + 帧 strip + 32 色」约定
5. 大文件（引擎/build demo/美术原图）走云盘资产库共享；代码走 git 远程

## 8. 团队专家复用

roguelike-studio 团队含 `game-designer` / `godot-dev` / `pixel-artist` 三类专家，可在项目组挂为「项目专家」让成员直接召唤，避免每个 Agent 重新理解项目。
