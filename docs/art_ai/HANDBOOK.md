# 《星骸回响》AI 美术云主机操作手册（交接包 v1 · 2026-08-12 23:40）

> 给执行子代理的自包含手册。读完本手册即可独立完成任务，无需向主代理询问背景。

## 1. 任务背景（一句话）
对 12 张二次元立绘执行「AI 像素化」批量生产（技术书 B 路线），输出 512/128/64/32 四级 + 游戏调色板量化 + 评分对照表。**路线已由用户验证通过（70 分）**，本次是批量放大。

## 2. 云主机连接（2026-08-15 已全部打通：新主机 175.155.64.171 · RTX 3080 20GB）
- **SSH**：`D:/30DAYS/docs/art_ai/.ssh_tmp/ssh_run.sh "远程命令"`（已更新为新主机：root@175.155.64.171:24104，密码内嵌）
- **ComfyUI API**：`http://175.155.64.171:61041` → 内网 8001（✅ 已验证通，Bearer 认证通过）
- **API token**：`$2b$12$rXLFadPxGNVVyXnvcpl9u.DpEL/jxBMNbWDXVPuanta.tLH7j/5eq`（08-15 取自启动日志 `/root/ComfyUI/user/comfyui_8001.log`；URL 参数 `?token=` 或 Bearer 头）
- 本地隧道（如需）：`SSH_PASS='G4@ou' SSH_ASKPASS=/d/30DAYS/docs/art_ai/.ssh_tmp/askpass.sh SSH_ASKPASS_REQUIRE=force ssh -f -N -L 18001:127.0.0.1:8001 -p 24104 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@175.155.64.171`
- ⚠️ 61040 → 内网 8000：探测异常（WayOS 重定向，API 全 404）——**用户 08-15 拍板：不影响生产，忽略**
- 🚚 **NoobAI-XL-v1.1.safetensors 下载中**（08-15 21:15 启动，hf-mirror 源，目标 `/root/ComfyUI/models/checkpoints/`）——下载完成后 sha256 校验 + 3 张测试立绘 A/B 对比，再定立绘轨主模型
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
- ⚠️ **下载通道（08-15 实测）**：公网 61041 的 `/view` 大图下载不稳（WinError 10060 超时）→ **生产模式：生成留服务器 `/root/ComfyUI/output/`，用 SSH `cat` 拉取**（`ssh_run.sh "cat /root/ComfyUI/output/<文件>_.png" > 本地.png`）；文件名注意 ComfyUI 自动加 `_NNNNN_` 序号与尾下划线
- 风格参考（08-15 用户提供 `D:/30DAYS/0815立绘风格、画风示例/`，21 张）：纯黑背景/低饱和(≈15/255)/暗调/暖米高光/竖版全身——风格块见 `.ssh_tmp/gen_style_test.py`

## 4.5 立绘轨生产定稿（08-15 用户拍板 · 双路线固化）
- **模型**：NoobAI-XL-v1.1.safetensors（立绘轨主模型；像素轨仍 aziibpixelmix）
- **尺寸**：1024×1536 直出 · 32 步 · CFG 6.5 · dpmpp_2m+karras（弃用 latent hires——见下踩坑）
- **画风块**：WD14 反推 21 张参考立绘共性（black_background / solo / full_body / looking_at_viewer / 低饱和暖光 rim light）
- **路线 A**（细节优先，虹膜强化+衣物加权）：`(masterpiece iris:1.3)(detailed iris:1.35)(sparkling eyes:1.25)(iris reflection:1.2)(long eyelashes:1.25)(detailed face:1.2)(elegant dress:1.25)(clean detailed outfit:1.2)(long hair:1.2)`；负面补 `cluttered outfit, messy clothes, tangled hair, noisy background`
- **路线 B**（构图优先，简洁）：基础眼部词（detailed eyes/iris/sparkling eyes/long eyelashes），无加权
- **生产脚本**：`docs/art_ai/gen_prod_portrait.py --route A|B --count N --seed-base X`（生成留服务器，SSH cat 拉取）
- **踩坑（08-15 用户复现昨天同款）**：**latent nearest-exact 放大 + denoise≤0.4 = 糊**（块状马赛克+未重绘）→ 禁用于立绘；要更高分辨率走 1024×1536 一步直出，或 4x-UltraSharp 像素放大 + denoise 0.5

## 4.6 立绘管线迭代状态（08-16 03:07 存档 · 明日续接）
> 12 角色像素模型已定稿（`output_abc/final_完美像素/定稿_20260816/` + `角色要素定稿表_20260816.md`，编号=混合体系 0/1 起，见清单文件头）。**立绘未定稿**，处于管线迭代中。
> **已定稿配置**：NoobAI-XL + 1024×1536 + 32步 CFG6.5 dpmpp_2m+karras + **灰底 #808080 纯色**（黑底会与深色服装融合，用户否决）+ 抠底 tol64+边缘膨胀2px（`make_init_gray.py`）
- **迭代链（勿回退到已否决方案）**：
  1. ❌ 纯文字 txt2img（A/B 路线）→ 一致性差
  2. ❌ IPAdapter（plus vit-h，w0.5/0.7/end_at 截断全试）→ 参考图是像素风→画质崩（IPAdapter 注入像素感）
  3. ❌ img2img 单段 0.75 灰底 → 画质 OK/姿势还原，但服装还原一般 + 继承像素 4 头身→全员幼态
  4. ❌ img2img 两段式 0.6+0.4 → 画质更差
  5. ❌ 7 头身文字词 → 希亚不够高挑/莱恩中年化/诺亚无变化
  6. ✅ **v2 拉伸底图（768 纵向拉伸 1.3 倍≈5.5 头身，`make_init_gray2.py`，已传服务器 input/init_gray2/）+ 8 头身词 + 莱恩 `young adult male warrior` → 希亚比例验证通过**
- **明日唯一待办**：拉伸底图后画风成熟度下降（LANCZOS 拉伸模糊纹理残留）→ 候选：a) 拉伸后段2 denoise0.3 精修 b) denoise 0.75→0.7 平衡 c) IPAdapter 低权重 0.3 补服装 d) 阶梯放大（先 2x 再裁）减模糊；参照样板：希亚（比例）、莱恩（青年化）
- 量产脚本 `gen_portraits_prod.py` 需同步：init_gray2 底图 + 8 头身词 + 分组眼部词（F 女性 natural eyelashes / M 男性 mature masculine / B 野兽 fierce / I 物品 ominous，禁 long eyelashes 一刀切）+ 全局负面锁 loli/chibi/large head/small body

## 4. 已确认可用的关键模型
- `aziibpixelmix_v10.safetensors` —— **像素风模型（SD1.5，512 输入），B 路线主力**（技术书 Pixel LoRA 的替代）
- `Neta Art XL 二次元角色 （更新V2）_V2.0.safetensors` —— SDXL 二次元立绘
- `counterfeitxl_v10.safetensors`、`cardosAnime_v20.safetensors` —— SDXL 二次元备选
- IPAdapter Plus 插件刚装好（ComfyUI 重启后生效）：`ip-adapter-plus_sdxl_vit-h.safetensors` + `CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors`（C 路线用，本轮可选）
- ⚠️ **没有 pixel-art-xl / no_anti_aliasing LoRA，禁止在调用中指定 --lora**
- 新主机实测模型清单（08-15）：**Neta Art XL V2 / aziibpixelmix_v10 / counterfeitxl / cardosAnime 均在**；另有 flux1-dev-fp8 / flux1-schnell-fp8 / F.1-dev-fp8 / svd_xt / Strawberry-α / Lamico 等；**无 Illustrious/NoobAI**（待拍板下载）；**无 IPAdapter 插件**（旧主机有，新主机未装）；custom_nodes 含 ComfyUI-Easy-Use/KJNodes/controlnet_aux/segment-anything-2/WD14-Tagger 等
- 磁盘：98G 总量，剩 56G（够装 NoobAI-XL 7GB）

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
