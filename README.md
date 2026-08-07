# 《星骸回响》Star Echo

Anime Pixel Roguelite Action —— 类 Brotato 俯视角自动射击数值肉鸽。

> Godot 4.3 / GDScript / PC (Steam) 优先
> 远程仓库：https://github.com/kejinren1/star-echo （master 主干直推）

## 快速开始

1. 安装 Godot 4.3（本机已备：`tools/Godot_v4.3-stable_win64.exe`）
2. 打开 `project.godot` 导入项目
3. 运行入口场景：**CharacterSelect**（角色选择 → 战斗）
4. 测试玩法：`play_game.bat`；编辑器：`open_editor.bat`

## 玩法核心

- 移动 + 主动技能（冷却/资源），攻击全自动
- 3 角色：炎术师·艾琳（Mage）/ 机械师·诺亚（Summoner）/ 剑士·莱恩（Melee）
- 武器 6 槽 Lv1-8，Lv8+ 核心 = 进化（炎星术+烈焰核心 → 炎星陨落）
- 被动 6 槽 20 个；10 属性成长
- 肉鸽：随机节点地图 + 文本事件 + 精英 + 遗物 + 多阶段 Boss；局外：方舟基地 + 研究系统

## 项目结构

```
docs/        — 设计文档（GDD/美术规格/规划/进度/测试报告）
data/        — 数据表 JSON（武器/被动/敌人/波次/路线/事件/Boss）
scenes/      — Godot 场景
scripts/     — GDScript（autoload 架构：GameManager/DataLoader → 战斗系统 → 实体 → UI）
assets/      — 精灵图/图标/特效（64px 基准 · 216 色 · 透明键规范）
tools/       — 生成工具 / 探针测试 / 回归脚本
build/       — 打包产物（不入库）
```

## 文档索引

| 文档 | 说明 |
|---|---|
| `docs/GIT_COLLAB.md` | **Git 协作交接说明（新成员必读）** |
| `docs/GDD.md` | 游戏设计大纲 v0.1 |
| `docs/ART_STYLE.md` | 美术规格 v2 |
| `docs/30DAY_PLAN.md` | 30 天开发规划 |
| `docs/PLAYTEST_CHECKLIST.md` | 试玩清单 + 未解决问题追踪区 |

## 团队

- Game Designer — 游戏设计、机制平衡
- Godot Dev — 引擎实现、程序架构
- Pixel Artist — 2D 美术、UI 视觉

## 协作

- 本地仓库 `D:\Program Files\30DAYS` = 主仓库，GitHub = 备份/协作镜像，两边同时保留
- 自动化执行轮每 2h 收尾自动 `commit + push`
- 推送/拉取走 SSH over 443 通道（详见 `docs/GIT_COLLAB.md` §2）
