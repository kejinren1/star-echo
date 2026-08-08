# ART/RAW —— 素材输入目录（用户提供 → 自动转化）

> 你（用户）提供的美术素材**统一放这里**，我负责自动转化成游戏可运行的 sprite。
> 本目录是「素材工作流」的单一入口（2026-08-08 用户拍板）。

## 一、素材交付规范（怎么给最好用）

| 项 | 约定 |
|---|---|
| **文件格式** | PNG 优先（无损）；JPG 也行（floodfill 自动处理浅灰底） |
| **背景** | 纯白 / 浅色底（自动抠底）；透明底也行（抠底容差填 0） |
| **内容** | 一张图一个角色/物体，完整不裁切，背景统一 |
| **命名** | `角色_动作_帧号.png`，如 `ailin_walk_01.png`、`ailin_idle_01.png` |
| **批量放** | 同角色同动作的帧放一起，按帧号自然排序 |

## 二、动画帧规格建议（64×64 帧，v2 美术规格）

游戏帧数由 sheet 自动推断（帧尺寸 = sheet 高，帧数 = 宽÷高），FPS 固定可配。
**生产素材时按以下规格提供**：

| 动作 | 建议帧数 | FPS | 循环 | 说明 |
|------|---------|-----|------|------|
| idle 待机 | **4 帧** | 6 | ✅ | 呼吸/飘动；最少 3，4 帧更稳 |
| walk 行走 | **6~8 帧** | 10 | ✅ | 循环步态；6 帧可用，8 帧更顺 |
| attack 攻击 | **4 帧** | 12 | ❌ | 一次挥击/施法；3~5 帧 |
| skill 技能 | **4~6 帧** | 10 | ❌ | 专属技能动作 |
| hit 受击 | 2 帧（可选） | 8 | ❌ | 现用 idle 首帧+闪白替代 |
| death 死亡 | 6 帧（可选） | 8 | ❌ | 倒下消散 |

- **最低可用**：idle 4 + walk 6 + attack 4 + skill 4 = 18 帧/角色
- **推荐完整**：idle 4 + walk 8 + attack 4 + skill 6 = 22 帧/角色
- 参考：当前 elin 实装 = idle 5 + walk 10 + attack 5 + skill 6 + hit 2（Day 29 JPG 管线，28 帧白底 JPG → 5 sheet）

## 三、ART 目录语义（2026-08-09 用户确认 · 拼豆方案已废弃）

```
ART/
├── RAW/            ← 素材输入区（唯一入口）：你提供的标准白色/浅色背景 JPG/PNG 放这里
│   ├── README.md   ← 本文件（交付规范）
│   └── <角色>/     ← 按角色建子目录，如 elin/
├── COLOR_DICT.json ← 色字典（工具数据，勿手改）
└── .gdignore       ← 防止 JPG 被 Godot 扫描（720×960 大图导入会段错误，历史教训）
```

- ✅ **拼豆图纸方案已废弃**（原 ART/CHARA/AILIN 13 张拼豆图已归档至 `.godot_tmp_backup/ART_CHARA_AILIN_legacy/`，保留可恢复）
- ✅ 当前素材形态 = **标准白色/浅色背景 JPG/PNG**（img2sprite 管线自动抠底，容差 100）
- ✅ 任何素材只要放进 `ART/RAW/`，即可被 img2sprite / pindou_editor 消费

## 四、处理流程（两个入口）

```
① 命令行批量：
   python tools/img2sprite.py --input ART/RAW/elin --output assets/sprites/characters \
       --size 64 --palette dict(或 beads) --batch
   （默认参数已按用户实测最优：色板=当前调色板字典容差12、抠底容差100）

② 可视化精修：
   tools/pindou_editor.html 双击打开 → 素材导入面板（拖放/选图）
   → 自动抠底+降维+量化 → 像素级修正 → 导出 PNG sheet 进游戏
```

**实装闭环（保证不再返工）**：素材入 `ART/RAW/` → 管线出 sheet → 替换 `assets/sprites/characters/elin_*.png` → `player.gd` 帧数自动推断（sheet 宽÷帧宽）→ `day29_elin_anim_check` 14/14 探针验证 → commit。整套在 `D:/30DAYS`（已迁移根治 ACL 问题），无需再动旧路径。

## 五、当前素材清单（新增时更新）

- （等待用户放入新素材）
