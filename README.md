# Roguelike Studio — Brotato-like Game Project

## 项目概述
类土豆兄弟(Brotato)俯视角射击肉鸽游戏，使用 Godot 4 引擎开发。

## 技术选型
- 引擎: Godot 4
- 语言: GDScript (主) / C# (可选)
- 目标平台: PC (Steam) 优先

## 项目结构
```
docs/          — 设计文档、GDD
assets/        — 游戏资源
  sprites/     — 精灵图 (角色/敌人/UI/特效)
  audio/       — 音频 (BGM/SFX)
  fonts/       — 字体
scripts/       — GDScript 脚本
  player/      — 玩家相关
  enemy/       — 敌人相关
  weapons/     — 武器系统
  items/       — 道具系统
  systems/     — 核心系统 (波次/经济/存档等)
scenes/        — Godot 场景文件
data/          — 数据表 (道具/敌人/波次配置)
```

## 团队
- Game Designer — 游戏设计、机制平衡
- Godot Dev — 引擎实现、程序架构
- Pixel Artist — 2D美术、UI视觉
