# 《星骸回响》ComfyUI 技术摸底 · 第一轮执行计划（2026-08-12）

> 依据：`ComfyUI_二次元角色到像素Sprite_技术摸底与生产流程说明书_V0.1.docx`（技术书）
> 状态：执行中 · 阻塞点=云主机端口未通（31170/31171 自 23:15 断连）
> 云主机：61.157.218.59（31170→8000 Jupyter / 31171→8001 aiohttp 认证服务）

## 技术书执行顺序（十七节）→ 今日落地

| # | 技术书步骤 | 状态 | 说明 |
|---|-----------|------|------|
| 1 | 部署 4090 云服务器与 ComfyUI | 🔄 用户侧 | 用户已登录；端口映射存在但当前断连 |
| 2 | 只装第一批必要 Custom Nodes | ⏳ | Manager / IPAdapter Plus / controlnet_aux / Impact Pack / WAS（技术书清单） |
| 3 | 下载模型 | ⏳ | Animagine XL 4.0 Opt、SDXL Base 1.0、Pixel Art XL、IP-Adapter Plus SDXL ViT-H、CLIP Vision ViT-H、SDXL OpenPose ControlNet |
| 4 | 准备 5~10 张差异化测试立绘 | ✅ 12 张 | `D:/30DAYS/测试立绘/`（1024~2048px 透明底），覆盖长发/短发/铠甲/长裙/长武器/复杂轮廓/红黑对比 |
| 5 | 先跑高分辨率基准图 | ⏳ | 端口通后 `comfy_client.py --probe` 确认环境，再 txt2img 基准 |
| 6 | A/B/C 三路线对照 | 🔄 A 完成 | A（传统缩放基线）本地已跑完；B（AI 像素化）/C（IP-Adapter 重构）待端口 |
| 7 | 输出 128/64/32 三级 | ⏳ | B/C 输出经 img2sprite 后处理 |
| 8 | 实际游戏背景视觉审核 | ⏳ | 与游戏内角色/背景/UI 对照 |
| 9 | 决定最终 Pixel 路线与目标尺寸 | ⏳ | 依据 128/64/32 评分 |
| 10 | Character LoRA | ⏳ 第二阶段 | 20~60 张数据集，1024 分辨率，Rank 32 / Alpha 16 |

## 已就绪资产（本地）

- **测试立绘 12 张**：予愿安洁莉娜(长发法师)/傀影(兜帽男)/棘刺(短发男剑士)/狮蝎(紫发带尾)/维什戴尔(长发女)/若叶睦(短发女)/莱欧斯(短发男)/赤刃明霄陈(铠甲女)/赫拉格(白发男)/遥/重岳(铠甲+长武器)/龙舌兰(男)
- **comfy_client.py**：ComfyUI 协议批量客户端（认证/探测/txt2img/img2img/上传/外部 workflow）
- **A 路线基线**：`docs/art_ai/output_abc/A_nearest/`（nearest 直缩 64/48/32 共 36 张）+ `A_pipeline/`（img2sprite 游戏管线 64px 调色板 29 色 12 张）+ `_preview/`（对照图 4 张）
- **后处理管线**：tools/img2sprite.py（抠底→bbox→网格降采样→COLOR_DICT 量化）+ ART/COLOR_DICT.json

## 待办（端口通后，按序执行）

1. `python comfy_client.py --host http://61.157.218.59:31171 --user kejinren --password 111 --probe`
   → 确认服务身份 + 列出 checkpoints/loras/samplers，与技术书模型清单对账
2. B 路线：img2img denoise 0.45，Pixel LoRA 权重 0.6/0.8/1.0/1.2 四档横向（每档 3 张代表立绘）
3. C 路线：IP-Adapter + Pixel Art（需确认 IPAdapterPlus 节点与 clip_vision 就位）
4. 三级降采样 128→64→32（nearest 严格缩放）→ 与 A 基线并排评分
5. 汇总测试记录表（技术书十五节模板）→ 决定路线

## 阻塞与依赖

- **云主机端口 31170/31171 当前不可达**（23:15 起，之前 31171 稳定回 401）。守望脚本 `docs/art_ai/_port_watch.py` 每 20s 探测至 23:52。可能原因：服务重启 / 端口映射失效 / 云主机网络波动。**需用户确认云主机上 ComfyUI 与映射状态。**
- pip 无法安装第三方包（pypi/tuna 均不可达）→ Jupyter WebSocket 终端方案降级，主通道 = ComfyUI HTTP API
- 本机网络特性：pypi.org/github.com 443 被干扰；公网 61.157.218.59 直连正常
