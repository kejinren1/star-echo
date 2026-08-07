# 《星骸回响》Star Echo · Git 协作交接说明

> 创建：2026-08-07 ｜ 作者：主控 ｜ 面向：团队 roguelike-studio（game-designer / godot-dev / pixel-artist）

## 1. 仓库信息

| 项 | 值 |
|---|---|
| 托管平台 | GitHub（账号 kejinren1） |
| 仓库地址 | https://github.com/kejinren1/star-echo |
| 克隆地址（SSH，推荐） | `git@github.com:kejinren1/star-echo.git` |
| 克隆地址（HTTPS） | `https://github.com/kejinren1/star-echo.git` |
| 默认分支 | `master`（主干直推，无 PR 流程） |
| 可见性 | Public |

## 2. 网络通道说明（重要，先看这个）

**主控机实测**：`github.com:443`（HTTPS）在当前网络环境被干扰，直连超时；但 GitHub 官方 **SSH-over-443 通道（ssh.github.com:443）完全畅通**。主控机已配置：

```
# ~/.ssh/config（主控机已就位，勿动）
Host github.com
    HostName ssh.github.com
    Port 443
    User git
    IdentityFile C:\Users\Administrator\.ssh\id_ed25519
    ServerAliveInterval 30
```

**其他成员接入方法**（如遇 HTTPS 超时）：
1. `ssh-keygen -t ed25519 -C "你的邮箱"`（Windows 下 -f 用 `C:/` 格式路径）
2. 公钥（`id_ed25519.pub` 内容）加到 GitHub：Settings → SSH and GPG keys → New SSH key
3. 照上面模板写 `~/.ssh/config`（IdentityFile 换成自己的路径）
4. 验证：`ssh -T git@github.com` → 看到 `Hi 你的用户名!` 即成功

## 3. 本地仓库 = 主仓库（保留策略）

- **本地 `D:\Program Files\30DAYS` 始终是工作主仓库**，GitHub 是备份与协作镜像，两边都要留，互为冗余
- 自动化执行轮（每 2 小时）收尾会自动 `git add -A && commit && push`，远端保持最新
- **不入库内容**（.gitignore 已配置）：`.workbuddy/`（AI 工作记忆，含本说明的完整开发日志）、`build/`、`*.exe/*.pck`、探针日志 `tools/probe_logs/`、`tools/_*` 临时产物、`*.zip`
- 构建包走发布渠道（Release/云盘），不走 git

## 4. 日常工作流

```bash
# 首次拉取
git clone git@github.com:kejinren1/star-echo.git

# 每轮开工前
git pull

# 改动后提交（提交信息风格：DayXX-xxx 摘要，参照 git log）
git add <具体文件>        # 不随手 git add -A，避免混入临时产物
git commit -m "Day24-xxx 简述做了什么"

# 推送
git push origin master    # 注意：不要用 -u（Program Files 权限坑）
```

约定：
- **主干直推**，改动小、频率高，不做 PR 分支
- 提交前先跑验证护栏（见 §6），失败不推送
- 若 `git push` 报 `Permission denied`（Program Files 下 .git 写盘被 ACL 拒）：
  - 先用文件工具手动改 `.git/config` 补配置，或跳过提交并在群里说明；commit 本身不受影响

## 5. 文档地图（docs/）

| 文档 | 内容 |
|---|---|
| `GDD.md` | 游戏设计大纲 v0.1（源：游戏设计大纲.docx） |
| `ART_STYLE.md` + `ART_ANIME_SPEC.md` | 美术规格 v2（64px 基准 / 216 色 / 透明键等） |
| `30DAY_PLAN.md` | 30 天开发规划（2026-08-05 → 09-03，5 阶段 A–E） |
| `SOLUTION_PLAN.md` | 当前轮执行方案（方案师 → 执行者的交接单） |
| `TASKS.md` | 任务拆解与勾选状态 |
| `PROGRESS.md` | 进度分析（每 2h 一轮） |
| `TEST_REPORT.md` | 自动化测试报告（探针回归 + baseline） |
| `PLAYTEST_CHECKLIST.md` | 真人试玩清单 + **未解决问题追踪区**（单一事实源） |
| `REPORT_PHASE_C.md` 等 | 阶段收口报告 |

## 6. 质量护栏（推送前必跑）

- **探针回归**：`tools/` 下探针脚本（day*_check.gd），当前十四件套 ≈452 断言，全绿为准
- **baseline 检查**：`tools/baseline_check.py` → BASELINE CLEAN
- **headless 验证**：Godot 4.3 headless 模式 import 无错误、场景可实例化（`tools/Godot_v4.3-stable_win64.exe --headless --quit`）
- 探针是**白盒直构造 + 真实 GUI 点击（push_input）**双轨，别回退到只调函数

## 7. 当前状态（2026-08-07 快照）

- Phase 1 ✅（数据层 + 可运行）｜阶段 B ✅（武器 36 + 被动 20 + 商店 + 进化）｜阶段 C ✅（路线/事件/精英/Boss 两制式，Day 20 收口）
- P0 平衡热修已落地（移速 ×0.5 / 碰撞层分离 / 调试金手指）；F-15 冲锋平衡待拆解
- 引擎 Godot 4.3 / GDScript；入口场景 `CharacterSelect`
