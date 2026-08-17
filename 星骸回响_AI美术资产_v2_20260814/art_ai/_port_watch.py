"""端口守望：每 20s 探测 31170/31171，任一恢复即退出并打印状态。"""
import time, urllib.request, sys

HOSTS = [("31171(8001)", "http://61.157.218.59:31171/"),
         ("31170(8000)", "http://61.157.218.59:31170/")]

def probe(url):
    try:
        with urllib.request.urlopen(url, timeout=6) as r:
            return r.status
    except urllib.error.HTTPError as e:
        return e.code
    except Exception:
        return None

deadline = time.time() + 1800  # 最多等 30 分钟
while time.time() < deadline:
    alive = []
    for name, url in HOSTS:
        code = probe(url)
        if code is not None:
            alive.append(f"{name}=HTTP{code}")
    if alive:
        print("PORT_ALIVE " + " | ".join(alive))
        sys.exit(0)
    time.sleep(20)
print("PORT_TIMEOUT 30min 内未恢复")
sys.exit(1)
