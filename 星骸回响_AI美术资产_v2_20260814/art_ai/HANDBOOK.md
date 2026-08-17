# 《星骸回响》AI 美术云主机操作手册（交接包 v1 · 2026-08-12 23:40）

> 给执行子代理的自包含手册。读完本手册即可独立完成任务，无需向主代理询问背景。

## 1. 任务背景（一句话）
对 12 张二次元立绘执行「AI 像素化」批量生产（技术书 B 路线），输出 512/128/64/32 四级 + 游戏调色板量化 + 评分对照表。**路线已由用户验证通过（70 分）**，本次是批量放大。

## 2. 云主机连接（已全部就绪，无需重建）
- **SSH**：`D:/30DAYS/docs/art_ai/.ssh_tmp/ssh_run.sh "远程命令"`（密码已内嵌，直接可用）
- **API 隧道**：本地 `http://127.0.0.1:18001` 已转发到云主机 ComfyUI 8001（ComfyUI 刚重启，等待 2-3 分钟后再调 API；若 401 是正常认证响应，000 是服务未就绪）
- **API token**：`$2b$12$w7svp7mC.4smt7Td.UxZPel32ZiFNRhk7dt9KKah6T9WblEkLYXaS`（ComfyUI-Login 认证，URL 参数 `?token=` 或 Bearer 头）
- 隧道若失效，重建：`SSH_PASS='Yr#22' SSH_ASKPASS=/d/30DAYS/docs/art_ai/.ssh_tmp/askpass.sh SSH_ASKPASS_REQUIRE=force ssh -f -N -L 18001:127.0.0.1:8001 -p 22117 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@61.157.218.59`

## 3. 生成客户端
`D:/30DAYS/docs/art_ai/comfy_client.py`（Python 3.13 标准库）
```bash
PY="C:/Users/Administrator/.workbuddy/binaries/python/versions/3.13.12/python.exe"
$PY comfy_client.py --host http://127.0.0.1:18001 --token '<TOKEN>' \
  --category character --style style_military_cold --track portrait --count 1 \
  --seed 12345 --checkpoint "aziibpixelmix_v10.safetensors" \
  --input-image "D:/30DAYS/docs/art_ai/output_abc/inputs_512/立绘_XXX_1.png" --denoise 0.45
```
- 支持：`--probe` 探测 / txt2img（无 --input-image）/ img2img（有 --input-image + --denoise）
- 输出落到 `docs/art_ai/output_comfy/character/`，文件名 `character_style_military_cold_star_echo_i2i_*.png`（按生成顺序递增，**下载后立即归档并改名，防止混淆**）
- 注意：comfy_client 已修复 sampler 拆分（dpmpp_2m + karras）与 pixel_direct 参数映射

## 4. 已确认可用的关键模型
- `aziibpixelmix_v10.safetensors` —— **像素风模型（SD1.5，512 输入），B 路线主力**（技术书 Pixel LoRA 的替代）
- `Neta Art XL 二次元角色 （更新V2）_V2.0.safetensors` —— SDXL 二次元立绘
- `counterfeitxl_v10.safetensors`、`cardosAnime_v20.safetensors` —— SDXL 二次元备选
- IPAdapter Plus 插件刚装好（ComfyUI 重启后生效）：`ip-adapter-plus_sdxl_vit-h.safetensors` + `CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors`（C 路线用，本轮可选）
- ⚠️ **没有 pixel-art-xl / no_anti_aliasing LoRA，禁止在调用中指定 --lora**

## 5. 目录约定
- 立绘源：`D:/30DAYS/测试立绘/`（12 张，1024-2048px，RGBA 透明底）
- 512 预处理输入：`D:/30DAYS/docs/art_ai/output_abc/inputs_512/`（白底 512×512，已生成 5 张：安洁莉娜/陈/重岳/傀影/龙舌兰；**其余 7 张需按同样方法预处理**）
- B 路线归档：`D:/30DAYS/docs/art_ai/output_abc/B_pixel/<角色名>/{512_pixel,128px,64px,32px}.png`
- A 路线基线：`output_abc/A_nearest/`、`output_abc/A_pipeline/`
- 后处理工具：`D:/30DAYS/tools/img2sprite.py`（venv python 运行：`C:/Users/Administrator/.workbuddy/binaries/python/envs/default/Scripts/python.exe`，PIL 12.3 已装）
- 调色板：`D:/30DAYS/ART/COLOR_DICT.json`（游戏色板，ΔRGB≤12）

## 6. 本轮任务清单
- **T1 预处理**：7 张剩余立绘 → 512×512 白底 → `inputs_512/`（PIL: RGBA 合成白底 → thumbnail 512 → 居中 pad；参考已有 5 张的做法）
- **T2 B 路线批量**：12 张全部 img2img（aziibpixelmix_v10，denoise 0.45，seed 12345）→ 每张完成后立即下载并按角色归档到 `B_pixel/<角色名>/512_pixel.png`（用生成顺序与角色顺序对应；也可先跑一张验证再批量）
- **T3 三级降采样**：每张 512_pixel → nearest 缩放 128/64/32 → `B_pixel/<角色名>/{128px,64px,32px}.png`
- **T4 调色板量化**：用 img2sprite.py 对 64px 版做 COLOR_DICT.json 量化（如时间紧可只做 3 个代表角色）
- **T5 评分对照表**：写 `D:/30DAYS/docs/art_ai/TEST_RESULT.md`（技术书十五节模板：角色/模型/seed/512质量/128/64/32/轮廓/辨识度/备注 + A vs B 对比结论 + 像素化是否值得的建议）

## 7. 铁律
1. **禁止安装/删除/修改云主机任何插件、配置、模型**（用户已拍板"凑合用现有的"）——IPAdapter 已装好，无需再动
2. 所有 python 运行用绝对路径（MSYS 路径 /d/ 会被拒绝）
3. token 含 `$`，shell 里用单引号包裹
4. 下载的图立即改名归档（文件名不携带角色信息）
5. ComfyUI 重启后前 2-3 分钟 API 不可用属正常（返回 000），轮询等待
6. 每批完成后把 manifest/进度追加写入 `docs/art_ai/output_abc/B_pixel/_PROGRESS.md`

## 8. 完成后报告格式
向主代理报告：生成总数、成功/失败清单、耗时、T5 评分结论要点、遗留问题（≤200 字）。
