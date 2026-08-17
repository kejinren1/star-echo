# 《星骸回响》AI 美术生产 RUNBOOK（给执行 agent 的完整指引）

> 版本：V1.0（2026-08-13，首轮摸底验证后固化）· 适用：任何新 GPU 主机 + ComfyUI 环境
> 前置阅读：技术书 `D:/30DAYS/ComfyUI_二次元角色到像素Sprite_技术摸底与生产流程说明书_V0.1.docx` + 复盘 `技术复盘_踩坑与成功经验.md`
> 目标：从零部署 → 跑通生产管线 → 批量产出 12 角色像素资产（64px/32px + 游戏调色板量化）

---

## 0. 本 RUNBOOK 是什么 / 不是什么

- ✅ 写给**没有本项目背景的 agent**：照着做就能产出
- ✅ 包含：环境部署清单、认证获取、模型清单（首选与替代）、管线命令、参数表、验收标准、坑位速查
- ❌ 不包含：游戏本体改动（那是另一条线）；二次创作的设计决策

## 1. 环境部署清单（新主机）

### 1.1 必备软件
- ComfyUI（≥0.11）+ Python 3.12 + CUDA 12.8
- 插件（custom_nodes）：**ComfyUI-Manager**、**ComfyUI_IPAdapter_plus**（C 路线必需）、**comfyui_controlnet_aux**（动作控制用）、ComfyUI-Login 或同类认证（按云厂商）
- 无 pip 外网时：全部标准库脚本已备好（docs/art_ai/comfy_client.py 仅依赖 urllib）

### 1.2 模型清单（首选 = 技术书原始方案；括号内 = 首轮验证的替代方案）
| 用途 | 首选模型 | 替代方案（已验证） |
|---|---|---|
| 主力角色底模 | Animagine XL 4.0 Opt | Neta Art XL V2 / counterfeitxl_v10（SDXL 二次元） |
| 像素语言转换 | Pixel-Art-XL LoRA（nerijs/pixel-art-xl，权重 0.6-1.2 横向） | **aziibpixelmix_v10**（SD1.5 像素模型，img2img denoise 0.4-0.45 顶替） |
| 边缘收紧 | No-AA LoRA（0.5-0.9） | 无替代时忽略 |
| 角色一致性 | IP-Adapter Plus SDXL ViT-H + CLIP-ViT-H-14 | 同左（IPAdapterUnifiedLoader preset="PLUS (high strength)"） |
| 动作控制 | SDXL OpenPose ControlNet | SD1.5 openpose（control_v11p_sd15_openpose） |
| 备选底模 | NoobAI XL 1.1 / SDXL Base 1.0 | cardosAnime_v20 / 简单遥 |

存放：`ComfyUI/models/{checkpoints,loras,ipadapter,clip_vision,controlnet}/`

### 1.3 服务管理（晨涧云镜像）
- 状态/启停：`mornctl.sh comfyui {status|restart|start|stop}`
- **重启后等 2-3 分钟**再调 API（轮询探活）
- 模型根目录：`/root/ComfyUI/models/`；默认代理 proxy.mornai.cn:7890

## 2. 认证获取（通用方法）

1. 云厂商镜像文档看认证方式（ComfyUI-Login 常见）
2. **API token 从日志白拿**：`grep "For direct API calls" /root/ComfyUI/user/comfyui_*.log` → token 形如 `$2b$12$...`
3. 认证三通道（ComfyUI-Login 插件，源码 liusida/ComfyUI-Login）：
   - URL 参数：`/prompt?token=TOKEN`
   - Bearer：`Authorization: Bearer TOKEN`
   - Web 登录：`POST /login` 表单（username+password）→ cookie 会话
4. token 含 `$`：shell 一律**单引号包裹**

## 3. 访问通道（按可靠性排序）

1. **SSH 隧道**（最可靠，公网 HTTP 映射故障时唯一通道）：
   ```bash
   # 常驻后台（勿用 ssh -f，Windows 会杀）：
   ssh -N -L 18001:127.0.0.1:8001 -p <SSH端口> -o ServerAliveInterval=30 \
     -o ServerAliveCountMax=3 root@<主机IP>
   # 非交互密码（无 sshpass 时）：SSH_ASKPASS 技巧见复盘 #1
   ```
   API 地址 = `http://127.0.0.1:18001`；隧道失效特征 = API 返回 000 → 重建
2. 公网 HTTP 直连：`http://<IP>:<外网端口>`
3. 云厂商控制台（Web UI 观赏/人工抽检）

## 4. 生产管线（已固化的脚本，全部在本仓库）

### 4.1 客户端 comfy_client.py（docs/art_ai/）
```bash
PY="C:/Users/Administrator/.workbuddy/binaries/python/versions/3.13.12/python.exe"
# 探测模型清单（第一步必做）
$PY comfy_client.py --host http://127.0.0.1:18001 --token '<TOKEN>' --probe
# txt2img（像素直出：ui_icon/item/effect 等）
$PY comfy_client.py --host ... --token ... --category item --track portrait \
  --checkpoint "aziibpixelmix_v10.safetensors" --count 4 --seed 20005
# img2img（立绘像素化：B 路线）
$PY comfy_client.py --host ... --token ... --category character --track portrait \
  --checkpoint "aziibpixelmix_v10.safetensors" \
  --input-image "D:/30DAYS/docs/art_ai/output_abc/inputs_512/立绘_XXX_1.png" --denoise 0.45
```
参数：sampler 已自动转换（dpmpp_2m + karras）；`--lora` 仅当服务器有 pixel LoRA 时使用。

### 4.2 C+B 完整管线 run_cb_pipeline.py（docs/art_ai/，幂等可断点续跑）
```bash
$PY run_cb_pipeline.py                    # 12 角色全量（C 重构+像素化+降采样）
$PY run_cb_pipeline.py --roles 傀影,若叶睦 --skip-c   # 复用已有母图
# 量化：venv python 调 tools/img2sprite.py --palette ART/COLOR_DICT.json
```
流程：立绘(1024 白底) → IPAdapter 重构 768×1024（weight 0.8, NetaXL, hero_cel）→ 512 白底 → aziibpixelmix img2img denoise 0.4 → NN 降采样 128/64/32 → COLOR_DICT 量化。
产出：`output_abc/CB_组合/<角色>/{1_母图,2_像素化,128px,64px,32px,64px_quant}.png`

### 4.3 参数速查表
| 环节 | 关键参数 |
|---|---|
| C 重构 | IPAdapter weight 0.8 / start 0 / end 1 / standard；768×1024；28 步；cfg 7；dpmpp_2m+karras；seed 12345+ |
| 像素化(B/CB) | aziibpixelmix；denoise 0.4-0.45（**低分角色提 0.6-0.7 抢救**）；512×512；seed+1 |
| 像素直出 | 512×512；seed 20001+ 递增 |
| 降采样 | **一律 nearest**（禁 bilinear/lanczos，技术书铁律） |
| 量化 | COLOR_DICT.json（ΔRGB≤12，163 色）；32 色级 = 市面主流，定案 |
| 风格 | 角色用 style_heroic_cel；**勿用 style_military_cold 套角色**（会出"灰现代军人"） |

## 5. 验收标准（技术书四级 + 量化指标）

1. **Level 1 像素化**：128px 无糊边/噪点（崩了→查像素化步骤）
2. **Level 2 降采样**：64px 轮廓/服装/武器可读（64 正常 32 崩→重设计简化策略）
3. **Level 3 一致性**：同角色多动作可辨认为同一人（C 路线 + Character LoRA 职责分离）
4. **Level 4 生产化**：批量稳定产出（本管线已验证：12 角色 4-6 分钟）
5. **量化指标**：32px 前景占比 ≥50%（低分角色 denoise 抢救）；量化覆盖率 100%；独特色数 28-80

## 6. 坑位速查（完整版见复盘文档）

公网 HTTP 死→隧道；ssh -f 被杀→后台常驻+保活；401→ComfyUI-Login 三通道；sampler 名要拆分；IPAdapter 简化版无 positive/negative；UnifiedLoader preset 勿手动接；重启等 2-3 分钟；MSYS 路径拒；token 单引号；pip 出网受限→标准库脚本；透明底→先白底化；脚本必须容错自报告。

## 7. 交付物清单（本次已完成，供对照）

- `output_abc/_INDEX.md`：298 张 PNG 全量索引（含命名规范）
- `output_abc/B_pixel/` B 路线 12 角色；`B_pixel_fix/` 复跑；`P_direct/` 直出 12 张；`C_ipadapter/` C 路线 5 角色；`CB_组合/` 完整管线 12 角色
- `TEST_RESULT.md` 评分表；`技术复盘_踩坑与成功经验.md`；`EXECUTION_PLAN.md` 首轮计划
- 测试立绘 12 张：`D:/30DAYS/测试立绘/`
