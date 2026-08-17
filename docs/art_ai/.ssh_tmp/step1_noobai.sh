#!/bin/bash
set -e
echo "== SAFETENSORS 校验 =="
/root/miniconda3/bin/python3 -c "
from safetensors import safe_open
f = safe_open('/root/ComfyUI/models/checkpoints/NoobAI-XL-v1.1.safetensors', framework='pt')
print('OK keys:', len(f.keys()))
"
echo "== 重启 ComfyUI =="
pkill -f 'ComfyUI/main.py' || true
sleep 2
cd /root/ComfyUI
nohup /root/miniconda3/bin/python3 main.py --enable-manager --enable-manager-legacy-ui --listen 0.0.0.0 --port 8001 > user/comfyui_8001.log 2>&1 < /dev/null &
echo "RESTARTED pid: $!"
