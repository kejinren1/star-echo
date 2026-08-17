# output_abc 全量索引（自动生成 2026-08-13）

| 路径 | 路线 | 说明 |
|---|---|---|
| `A_nearest/` | A_nearest | A路线-传统缩放基线(nearest直缩)（36 张） |
| `A_pipeline/` | A_pipeline | A路线-游戏管线(img2sprite)（12 张） |
| `B_pixel/` | B_pixel | B路线-AI像素化(aziibpixelmix d0.45)（60 张） |
| `B_pixel_fix/` | B_pixel_fix | B路线-复跑抢救(d06/d07)（24 张） |
| `C_ipadapter/` | C_ipadapter | C路线-IPAdapter重构(weight0.8)（20 张） |
| `CB_组合/` | CB_组合 | C+B完整管线(重构+像素化d0.4)（73 张） |
| `inputs_1024/` | inputs_1024 | 预处理-1024白底输入（12 张） |
| `inputs_512/` | inputs_512 | 预处理-512白底输入（25 张） |
| `P_direct/` | P_direct | 像素直出(txt2img 512)（36 张） |

**总计：298 张 PNG**

## 命名规范
- 角色目录 = 角色名（或 立绘_XXX_1 源文件名）
- 尺寸后缀：512_pixel/2_像素化=AI像素化母图；128px/64px/32px=nearest降采样；64px_quant=游戏调色板量化版
- 路线目录：A=传统基线，B=AI像素化，C=IPAdapter重构，CB=完整管线，P_direct=直出，fix=复跑