#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
comfy_client.py — 《星骸回响》ComfyUI 协议批量生成客户端
============================================================
对齐技术书（ComfyUI_二次元角色到像素Sprite_技术摸底与生产流程说明书_V0.1）：
  - 双轨：portrait（768×1024 画风基因主轨）/ pixel（512×512 像素直出 + Pixel-Art-XL + No-AA LoRA）
  - 认证：Bearer token（--token）或 账号密码自动登录（--user/--password）
  - 外部 workflow：--workflow <api格式.json> + --pos-node/--neg-node 替换 prompt 节点
  - --probe：探测服务器 /object_info，列出可用 checkpoint / lora

用法:
    python comfy_client.py --host http://61.157.218.59:31171 --token <TOKEN> --probe
    python comfy_client.py --host http://61.157.218.59:31171 --user u --password p \\
        --category character --style style_military_cold --track portrait --count 8
    python comfy_client.py --host ... --token ... --workflow wf.json --pos-node 6 --count 8

依赖：仅 Python 标准库（urllib）。
"""
import argparse
import base64
import json
import sys
import time
import uuid
import urllib.parse
import urllib.request
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(BASE_DIR))
from batch_gen import load_library, build_prompt  # noqa: E402

OUT_ROOT = BASE_DIR / "output_comfy"


class ComfyError(Exception):
    pass


class ComfyClient:
    """ComfyUI HTTP 客户端（支持三种认证：Bearer token / URL token / Web 登录 cookie）。"""

    def __init__(self, host: str, token: str = None,
                 user: str = None, password: str = None, timeout: int = 300):
        self.host = host.rstrip("/")
        self.timeout = timeout
        self.token = token
        # 统一走带 cookie jar 的 opener（Web 登录会话 / Bearer 都支持）
        self.opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor())
        if user and password:
            self.login_web(user, password)
        elif not token:
            # 无凭据时先试匿名（GUEST_MODE / 无认证服务器）
            pass

    # ---------- 底层 ----------
    def _request(self, path: str, payload: dict = None, method: str = None,
                 timeout: int = None, raw: bool = False, form: dict = None,
                 headers: dict = None):
        url = self.host + path
        if form is not None:
            data = urllib.parse.urlencode(form).encode("utf-8")
        elif payload is not None:
            data = json.dumps(payload).encode("utf-8")
        else:
            data = None
        req = urllib.request.Request(url, data=data, method=method)
        req.add_header("User-Agent", "star-echo-batch/0.1")
        if form is not None:
            req.add_header("Content-Type", "application/x-www-form-urlencoded")
        elif data is not None:
            req.add_header("Content-Type", "application/json")
        if headers:
            for k, v in headers.items():
                req.add_header(k, v)
        if self.token:
            req.add_header("Authorization", f"Bearer {self.token}")
        try:
            with self.opener.open(req, timeout=timeout or self.timeout) as resp:
                body = resp.read()
                return body if raw else json.loads(body.decode("utf-8"))
        except urllib.error.HTTPError as e:
            msg = e.read().decode("utf-8", "replace")[:300]
            raise ComfyError(f"HTTP {e.code} {path}: {msg}")
        except urllib.error.URLError as e:
            raise ComfyError(f"连接失败 {self.host}: {e.reason}")

    def login_web(self, user: str, password: str) -> None:
        """ComfyUI-Login 插件：POST /login 表单换 session cookie（aiohttp_session 加密）。"""
        try:
            self._request("/login", form={"username": user, "password": password},
                          timeout=60)
            print(f"[auth] Web 登录成功（{user}），已建立 cookie 会话")
        except ComfyError as e:
            raise ComfyError(f"Web 登录失败（{e}）——确认密码正确且服务器为 ComfyUI-Login 认证")

    def login(self, user: str, password: str) -> str:
        """兼容旧逻辑：直接走 Web 登录。"""
        self.login_web(user, password)
        return "cookie-session"

    # ---------- 探测 ----------
    def probe(self) -> dict:
        info = self._request("/object_info", timeout=60)
        out = {"checkpoints": [], "loras": [], "samplers": [],
               "models_total": len(info)}
        for key, node in info.items():
            if key == "CheckpointLoaderSimple":
                out["checkpoints"] = sorted(node["input"]["required"]["ckpt_name"][0])
            elif key == "LoraLoader":
                out["loras"] = sorted(node["input"]["required"]["lora_name"][0])
            elif key == "KSampler":
                out["samplers"] = sorted(node["input"]["required"]["sampler_name"][0])
        return out

    # ---------- 上传与 img2img ----------
    def upload_image(self, local_path: Path, type_: str = "input") -> str:
        """POST /upload/image（multipart），返回服务器上的文件名。"""
        import mimetypes
        boundary = "----star-echo-" + uuid.uuid4().hex
        fname = local_path.name
        ctype = mimetypes.guess_type(fname)[0] or "image/png"
        body = (
            f"--{boundary}\r\n"
            f'Content-Disposition: form-data; name="image"; filename="{fname}"\r\n'
            f"Content-Type: {ctype}\r\n\r\n"
        ).encode("utf-8")
        body += local_path.read_bytes()
        body += f"\r\n--{boundary}\r\nContent-Disposition: form-data; name=\"type\"\r\n\r\n{type_}\r\n".encode()
        body += f"--{boundary}--\r\n".encode()
        req = urllib.request.Request(self.host + "/upload/image", data=body, method="POST")
        req.add_header("Content-Type", f"multipart/form-data; boundary={boundary}")
        if self.token:
            req.add_header("Authorization", f"Bearer {self.token}")
        try:
            with self.opener.open(req, timeout=120) as resp:
                data = json.loads(resp.read().decode("utf-8"))
        except urllib.error.HTTPError as e:
            raise ComfyError(f"上传失败 HTTP {e.code}: {e.read().decode('utf-8','replace')[:200]}")
        name = data.get("name") or fname
        print(f"[upload] {fname} -> {name}")
        return name

    # ---------- 提交与取图 ----------
    def submit(self, workflow: dict) -> str:
        resp = self._request("/prompt",
                             {"prompt": workflow, "client_id": str(uuid.uuid4())},
                             timeout=60)
        pid = resp.get("prompt_id")
        if not pid:
            raise ComfyError(f"提交无 prompt_id: {json.dumps(resp, ensure_ascii=False)[:200]}")
        return pid

    def wait_history(self, prompt_id: str, timeout: int = 900, poll: float = 2.0) -> dict:
        """轮询 /history/{id} 直到完成。返回该次运行的完整输出。"""
        deadline = time.time() + timeout
        while time.time() < deadline:
            try:
                hist = self._request(f"/history/{prompt_id}", timeout=30)
            except ComfyError:
                time.sleep(poll)
                continue
            entry = hist.get(prompt_id)
            if entry:
                status = entry.get("status", {})
                if status.get("completed") or status.get("status_str") in ("success", "completed"):
                    return entry
                if status.get("status_str") == "error" or status.get("status_str") == "failed":
                    msgs = status.get("messages", [])
                    raise ComfyError(f"生成失败: {json.dumps(msgs, ensure_ascii=False)[:400]}")
            time.sleep(poll)
        raise ComfyError(f"等待超时（{timeout}s）prompt_id={prompt_id}")

    def download_outputs(self, entry: dict, out_dir: Path, prefix: str) -> list:
        """从 history entry 的 outputs 下载全部 SaveImage 结果。"""
        out_dir.mkdir(parents=True, exist_ok=True)
        saved = []
        for node_id, out in entry.get("outputs", {}).items():
            for img in out.get("images", []):
                q = urllib.parse.urlencode({
                    "filename": img["filename"],
                    "subfolder": img.get("subfolder", ""),
                    "type": img.get("type", "output"),
                })
                blob = self._request(f"/view?{q}", raw=True, timeout=120)
                fname = f"{prefix}_{img['filename']}"
                (out_dir / fname).write_bytes(blob)
                saved.append({"file": fname, "source": img["filename"]})
        return saved


def split_sampler(sampler: str) -> tuple:
    """WebUI 风格 'dpmpp_2m_karras' -> ComfyUI (sampler_name, scheduler)。"""
    for suf in ("_karras", "_exponential", "_sgm_uniform", "_simple",
                "_ddim_uniform", "_normal", "_beta"):
        if sampler.endswith(suf):
            return sampler[: -len(suf)], suf[1:]
    return sampler, "normal"


# ---------- workflow 构造 ----------
def make_txt2img_workflow(lib: dict, track: str, prompt: str, negative: str,
                          seed: int, checkpoint: str = None,
                          lora_name: str = None, lora_weight: float = None) -> dict:
    """内建 txt2img workflow（API 格式）。portrait 轨纯 checkpoint；pixel 轨挂双 LoRA。"""
    params_key = "pixel_direct" if track == "pixel" else track
    p = lib["params"][params_key]
    sampler, scheduler = split_sampler(p["sampler"])
    wf = {
        "1": {"class_type": "CheckpointLoaderSimple",
              "inputs": {"ckpt_name": checkpoint or _guess_checkpoint(lib)}},
        "4": {"class_type": "CLIPTextEncode",
              "inputs": {"text": prompt, "clip": ["1", 1]}},
        "5": {"class_type": "CLIPTextEncode",
              "inputs": {"text": negative, "clip": ["1", 1]}},
        "6": {"class_type": "EmptyLatentImage",
              "inputs": {"width": p["width"], "height": p["height"], "batch_size": 1}},
        "7": {"class_type": "KSampler",
              "inputs": {"seed": seed, "steps": p["steps"], "cfg": p["cfg"],
                         "sampler_name": sampler, "scheduler": scheduler,
                         "denoise": 1.0,
                         "model": ["1", 0], "positive": ["4", 0],
                         "negative": ["5", 0], "latent_image": ["6", 0]}},
        "8": {"class_type": "VAEDecode",
              "inputs": {"samples": ["7", 0], "vae": ["1", 2]}},
        "9": {"class_type": "SaveImage",
              "inputs": {"filename_prefix": "star_echo", "images": ["8", 0]}},
    }
    if track == "pixel":
        loras = lib["params"]["loras"]
        wf["2"] = {"class_type": "LoraLoader", "inputs": {
            "model": ["1", 0], "clip": ["1", 1],
            "lora_name": lora_name or loras["pixel_art_xl"]["name"],
            "strength_model": lora_weight or loras["pixel_art_xl"]["weight"],
            "strength_clip": lora_weight or loras["pixel_art_xl"]["weight"]}}
        wf["3"] = {"class_type": "LoraLoader", "inputs": {
            "model": ["2", 0], "clip": ["2", 1],
            "lora_name": loras["no_anti_aliasing"]["name"],
            "strength_model": loras["no_anti_aliasing"]["weight"],
            "strength_clip": loras["no_anti_aliasing"]["weight"]}}
        wf["4"]["inputs"]["clip"] = ["3", 1]
        wf["5"]["inputs"]["clip"] = ["3", 1]
        wf["7"]["inputs"]["model"] = ["3", 0]
    return wf


def make_img2img_workflow(lib: dict, track: str, prompt: str, negative: str,
                          seed: int, image_name: str, denoise: float,
                          checkpoint: str = None,
                          lora_name: str = None, lora_weight: float = None) -> dict:
    """img2img 路线（B/C 用）：LoadImage -> VAEEncode -> KSampler(denoise) -> Save。
    image_name 为已上传到 input 目录的文件名。"""
    params_key = "pixel_direct" if track == "pixel" else track
    p = lib["params"][params_key]
    sampler, scheduler = split_sampler(p["sampler"])
    wf = {
        "1": {"class_type": "CheckpointLoaderSimple",
              "inputs": {"ckpt_name": checkpoint or _guess_checkpoint(lib)}},
        "10": {"class_type": "LoadImage",
               "inputs": {"image": image_name, "upload": "image"}},
        "11": {"class_type": "VAEEncode",
               "inputs": {"pixels": ["10", 0], "vae": ["1", 2]}},
        "4": {"class_type": "CLIPTextEncode",
              "inputs": {"text": prompt, "clip": ["1", 1]}},
        "5": {"class_type": "CLIPTextEncode",
              "inputs": {"text": negative, "clip": ["1", 1]}},
        "7": {"class_type": "KSampler",
              "inputs": {"seed": seed, "steps": p["steps"], "cfg": p["cfg"],
                         "sampler_name": sampler, "scheduler": scheduler,
                         "denoise": denoise,
                         "model": ["1", 0], "positive": ["4", 0],
                         "negative": ["5", 0], "latent_image": ["11", 0]}},
        "8": {"class_type": "VAEDecode",
              "inputs": {"samples": ["7", 0], "vae": ["1", 2]}},
        "9": {"class_type": "SaveImage",
              "inputs": {"filename_prefix": "star_echo_i2i", "images": ["8", 0]}},
    }
    if track == "pixel":
        loras = lib["params"]["loras"]
        wf["2"] = {"class_type": "LoraLoader", "inputs": {
            "model": ["1", 0], "clip": ["1", 1],
            "lora_name": lora_name or loras["pixel_art_xl"]["name"],
            "strength_model": lora_weight or loras["pixel_art_xl"]["weight"],
            "strength_clip": lora_weight or loras["pixel_art_xl"]["weight"]}}
        wf["3"] = {"class_type": "LoraLoader", "inputs": {
            "model": ["2", 0], "clip": ["2", 1],
            "lora_name": loras["no_anti_aliasing"]["name"],
            "strength_model": loras["no_anti_aliasing"]["weight"],
            "strength_clip": loras["no_anti_aliasing"]["weight"]}}
        wf["4"]["inputs"]["clip"] = ["3", 1]
        wf["5"]["inputs"]["clip"] = ["3", 1]
        wf["7"]["inputs"]["model"] = ["3", 0]
        wf["11"]["inputs"]["vae"] = ["3", 2]
    return wf


def _guess_checkpoint(lib: dict) -> str:
    """从词库 meta 或常见命名猜 checkpoint；probe 后应显式指定。"""
    return lib.get("meta", {}).get("checkpoint", "animagine-xl-4.0-opt.safetensors")


def load_workflow_json(path: Path) -> dict:
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def patch_prompt_nodes(wf: dict, pos_node: str, neg_node: str,
                       prompt: str, negative: str) -> dict:
    """外部 workflow：把 pos/neg 节点的 text 换成组合 prompt。"""
    wf[pos_node]["inputs"]["text"] = prompt
    if neg_node:
        wf[neg_node]["inputs"]["text"] = negative
    return wf


# ---------- 主流程 ----------
def run(args, lib: dict) -> None:
    client = ComfyClient(args.host, token=args.token,
                         user=args.user, password=args.password)

    if args.probe:
        info = client.probe()
        print("=== 服务器探测 ===")
        print(f"节点类型总数: {info['models_total']}")
        print(f"\n[checkpoints] ({len(info['checkpoints'])})")
        for c in info["checkpoints"]:
            print("  ", c)
        print(f"\n[loras] ({len(info['loras'])})")
        for l in info["loras"]:
            print("  ", l)
        print(f"\n[samplers] ({len(info['samplers'])})")
        for s in info["samplers"]:
            print("  ", s)
        return

    track = args.track or lib["categories"][args.category]["track"]
    out_dir = OUT_ROOT / args.category
    rules = lib["rules"]
    base_seed = args.seed if args.seed is not None else rules["consistency"]["base_seed"]

    done = 0
    total = args.count
    log = []
    input_name = None
    if args.input_image:
        input_name = client.upload_image(Path(args.input_image))
    while done < total:
        seed = base_seed + done
        prompt, negative = build_prompt(
            lib, args.category, args.style, args.world, args.cls,
            args.outfit, args.hair, args.color, args.accessory, track,
        )
        if args.workflow:
            wf = patch_prompt_nodes(load_workflow_json(args.workflow),
                                    args.pos_node, args.neg_node,
                                    prompt, negative)
            if args.seed_node:
                wf[args.seed_node]["inputs"]["seed"] = seed
        elif input_name:
            wf = make_img2img_workflow(lib, track, prompt, negative, seed,
                                       input_name, args.denoise,
                                       checkpoint=args.checkpoint,
                                       lora_name=args.lora,
                                       lora_weight=args.lora_weight)
        else:
            wf = make_txt2img_workflow(lib, track, prompt, negative, seed,
                                       checkpoint=args.checkpoint,
                                       lora_name=args.lora,
                                       lora_weight=args.lora_weight)
        pid = client.submit(wf)
        print(f"[{done + 1}/{total}] prompt_id={pid} seed={seed}")
        entry = client.wait_history(pid)
        prefix = f"{args.category}_{args.style}"
        saved = client.download_outputs(entry, out_dir, prefix)
        log.extend(saved)
        done += len(saved) or 1
        print(f"  -> 存 {len(saved)} 张（累计 {done}）")

    (out_dir / "manifest.json").write_text(
        json.dumps({"category": args.category, "track": track,
                    "host": args.host, "items": log},
                   ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"完成：{len(log)} 张 → {out_dir}")


def main():
    lib = load_library()
    ap = argparse.ArgumentParser(description="《星骸回响》ComfyUI 批量生成客户端")
    ap.add_argument("--host", default="http://61.157.218.59:31171")
    ap.add_argument("--token", default=None, help="ComfyUI Bearer token")
    ap.add_argument("--user", default=None)
    ap.add_argument("--password", default=None)
    ap.add_argument("--probe", action="store_true", help="探测 checkpoints/loras/samplers")
    ap.add_argument("--category", default="character",
                    choices=list(lib["categories"].keys()))
    ap.add_argument("--style", default="style_military_cold",
                    choices=list(lib["styles"].keys()))
    ap.add_argument("--track", choices=["portrait", "pixel"], default=None)
    ap.add_argument("--world", default=None)
    ap.add_argument("--cls", default=None)
    ap.add_argument("--outfit", default=None)
    ap.add_argument("--hair", default=None)
    ap.add_argument("--color", default=None)
    ap.add_argument("--accessory", default=None)
    ap.add_argument("--checkpoint", default=None, help="显式指定 ckpt_name")
    ap.add_argument("--lora", default=None, help="pixel 轨可换 LoRA 名")
    ap.add_argument("--lora-weight", type=float, default=None)
    ap.add_argument("--workflow", default=None, help="外部 API 格式 workflow JSON")
    ap.add_argument("--pos-node", default=None, help="workflow 中正 prompt 节点 id")
    ap.add_argument("--neg-node", default=None, help="workflow 中负 prompt 节点 id")
    ap.add_argument("--seed-node", default=None, help="workflow 中 seed 节点 id")
    ap.add_argument("--input-image", default=None, help="本地立绘路径（img2img 模式，自动上传）")
    ap.add_argument("--denoise", type=float, default=0.45,
                    help="img2img 重绘强度（B 路线 0.3-0.5 / C 路线可更高）")
    ap.add_argument("--count", type=int, default=8)
    ap.add_argument("--seed", type=int, default=None)
    args = ap.parse_args()

    if args.workflow and (not args.pos_node):
        ap.error("--workflow 需要 --pos-node（正 prompt 节点 id）")
    run(args, lib)


if __name__ == "__main__":
    main()
