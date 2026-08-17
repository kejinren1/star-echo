# C 路线验证：IP-Adapter 角色一致性（安洁莉娜）

> 日期：2026-08-12 · 执行：general-purpose-3（AI 美术生产）
> 目标：验证 IP-Adapter 角色一致性重构路线是否可行（只做 1 张安洁莉娜）

## 1. 结论速览

- **节点可用性**：`IPAdapterPlus` 节点 **不存在**（核心节点列表 948 个中无此节点）。
- **等效替代**：核心节点 `IPAdapterUnifiedLoader` + `IPAdapter` 均可用，且服务器已就位
  `ip-adapter-plus_sdxl_vit-h.safetensors`（IPAdapterModelLoader 可加载）+ `CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors`（CLIPVisionLoader 可加载），**未安装/修改任何插件**。
- **生成结果**：成功生成 1 张 768×1024，已归档本目录（原图 + 128/64/32px nearest 降采样）。

## 2. Workflow 结构（API 格式，等效核心节点实现）

| 节点 | class_type | 关键输入 | 说明 |
|---|---|---|---|
| 1 | CheckpointLoaderSimple | `ckpt_name=Neta Art XL 二次元角色 （更新V2）_V2.0.safetensors` | SDXL 立绘底模 |
| 2 | CLIPTextEncode | 正 prompt（安洁莉娜·军武冷峻） | 风格/姿态描述 |
| 3 | CLIPTextEncode | 负 prompt | 通用负面 |
| 4 | LoadImage | `image=立绘_予愿安洁莉娜_1.png`（云主机 inputs/） | 参考图 512px 白底版 |
| 5 | IPAdapterUnifiedLoader | `preset="PLUS (high strength)"` | 等价 IPAdapterPlus 的模型加载（内含 ip-adapter-plus_sdxl_vit-h + CLIP-ViT-H-14） |
| 6 | IPAdapter | `weight=0.8, start_at=0.0, end_at=1.0, weight_type=standard` | 应用 IP-Adapter 注入角色特征 |
| 7 | EmptyLatentImage | 768×1024 | 竖版立绘尺寸 |
| 8 | KSampler | `dpmpp_2m / karras, 28步, cfg 7, seed=12345, denoise=1.0` | 全重绘 |
| 9 | VAEDecode | samples→vae | 解码 |
| 10 | SaveImage | filename_prefix=star_echo_c_ipadapter | 输出 |

**IPAdapterPlus 缺失说明**：任务原定用 `IPAdapterPlus` 节点，但 object_info 中不存在该节点（ComfyUI_IPAdapter_plus 自定义节点包未安装）。
按纪律**未安装任何插件**，改用核心节点等效组合：
- `IPAdapterUnifiedLoader`(preset `PLUS (high strength)`) 内部加载的正是 `ip-adapter-plus_sdxl_vit-h.safetensors` + `CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors`；
- `IPAdapter`(weight 0.8) 应用注入。

功能上与 IPAdapterPlus(weight 0.8) 一致。

## 3. 参数说明

- **weight=0.8**：IP-Adapter 注入强度。0.8 为中高强度，用于保角色特征同时保留 prompt 的姿态/服装描述；范围 0~3，值越高越像参考图。
- **start_at/end_at=0/1**：全采样步注入（非中途切换）。
- **weight_type=standard**：标准权重（不偏向 prompt 或风格）。
- **seed=12345**：固定种子便于复现。
- **denoise=1.0**：txt2img 全采样（非 img2img），由 IP-Adapter 提供角色一致性，而非依赖低 denoise 保底。

## 4. 结果说明

- 输出 1 张：`c_ipadapter_768x1024.png`（768×1024 原始输出）
- 降采样：`c_ipadapter_128px.png` / `c_ipadapter_64px.png` / `c_ipadapter_32px.png`（PIL nearest）
- 用途：验证 C 路线（AI 角色一致性重构）→ 后处理成像素 sprite 的技术路径可行性。

## 5. 遗留问题

1. `IPAdapterPlus` 节点缺失，当前用核心节点等效替代；若后续要精确复刻 IPAdapterPlus 的全部高级参数（如局部 masked 注入），需安装 ComfyUI_IPAdapter_plus 包（**用户已拍板不装，维持现状**）。
2. 本验证仅 1 张安洁莉娜；角色一致性需多 seed/多角色横向对比才能定论。
3. 参考图用的是 512px 白底预处理版（inputs_512 同源），比原始 1024px 立绘信息量低，角色细节保真度可能受此影响。
