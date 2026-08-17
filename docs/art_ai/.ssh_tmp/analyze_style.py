import glob, os
from PIL import Image
from collections import Counter

files = sorted(glob.glob(r"D:/30DAYS/0815立绘风格、画风示例/*.webp"))
print(f"共 {len(files)} 张\n")
for f in files:
    im = Image.open(f).convert("RGB")
    w, h = im.size
    small = im.resize((64, 64))
    px = list(small.getdata())
    edges = [px[i] for i in range(0, 64)] + [px[i] for i in range(64*63, 64*64)]
    edge_avg = tuple(sum(c[i] for c in edges)//len(edges) for i in range(3))
    sat = sum((max(p)-min(p)) for p in px)/len(px)
    lum = sum(sum(p)/3 for p in px)/len(px)
    q = im.resize((32,32)).quantize(colors=6).convert("RGB")
    cnt = Counter(q.getdata())
    top = [f"#{r:02x}{g:02x}{b:02x}" for (r,g,b),_ in cnt.most_common(4)]
    name = os.path.basename(f)
    print(f"{name}: {w}x{h} | 边缘色 rgb{edge_avg} | 饱和度 {sat:.0f}/255 亮度 {lum:.0f}/255 | 主色: {' '.join(top)}")
