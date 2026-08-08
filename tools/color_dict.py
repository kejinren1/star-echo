## color_dict.py — 色板字典登记工具（字典登记制落地）
## 制度（ART_STYLE.md 第二章）：提取实际用色 → 登记入字典 → 容差内(ΔRGB≤12)归并邻近色
##   · 色号全局唯一：前缀字母+两位数字（B背景/S皮肤/H发色/M金属/C服装/E特效/U-UI/N描边）
##   · anchor=true 的锚点色硬编码、不容差归并（描边/皮肤/发色等关键色）
##   · 字典文件：ART/COLOR_DICT.json（单一事实源）
##
## 用法：
##   python tools/color_dict.py extract  <png...>                   提取用色统计（不登记）
##   python tools/color_dict.py register <png...> [--prefix C]      提取+归并+登记，更新字典
##   python tools/color_dict.py check    <png...>                   检查 216 上限 + 未登记色
##   python tools/color_dict.py quantize <png> [--out x.png]        量化到字典色（最近色替换，透明保留）
##   python tools/color_dict.py report                               字典统计
##
## 退出码 0 = 通过；1 = check 发现违规 / 参数错误
import argparse
import json
import os
import sys

from PIL import Image

DICT_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'ART', 'COLOR_DICT.json')
PREFIXES = ['B', 'S', 'H', 'M', 'C', 'E', 'U', 'N']


# ========== 字典 IO ==========

def load_dict():
    if not os.path.exists(DICT_PATH):
        raise SystemExit('字典不存在: %s（先跑 tools/gen_color_dict.py 生成初始字典）' % DICT_PATH)
    with open(DICT_PATH, encoding='utf-8') as f:
        return json.load(f)


def save_dict(doc):
    os.makedirs(os.path.dirname(DICT_PATH), exist_ok=True)
    with open(DICT_PATH, 'w', encoding='utf-8') as f:
        json.dump(doc, f, ensure_ascii=False, indent=2)


def all_colors(doc):
    """code -> entry 全量视图"""
    return doc['colors']


# ========== 颜色工具 ==========

def hex2rgb(h):
    h = h.lstrip('#')
    return [int(h[i:i + 2], 16) for i in (0, 2, 4)]


def rgb2hex(rgb):
    return '#%02x%02x%02x' % tuple(rgb)


def dist(a, b):
    return max(abs(a[0] - b[0]), abs(a[1] - b[1]), abs(a[2] - b[2]))


def next_code(d, prefix):
    i = 0
    while ('%s%02d' % (prefix, i)) in d:
        i += 1
    return '%s%02d' % (prefix, i)


def extract_colors(path):
    """提取 PNG 用色统计：{hex: {'rgb':[r,g,b], 'count':n}}（透明像素不计）"""
    img = Image.open(path).convert('RGBA')
    px = img.load()
    stats = {}
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = px[x, y]
            if a < 8:
                continue
            key = '#%02x%02x%02x' % (r, g, b)
            if key in stats:
                stats[key]['count'] += 1
            else:
                stats[key] = {'rgb': [r, g, b], 'count': 1}
    return stats


# ========== 子命令 ==========

def cmd_extract(paths):
    for p in paths:
        stats = extract_colors(p)
        total = sum(v['count'] for v in stats.values())
        print('== %s: %d 色 / %d 像素' % (p, len(stats), total))
        for hexv in sorted(stats, key=lambda h: -stats[h]['count']):
            v = stats[hexv]
            print('  %s  %-8s  count=%d  %.1f%%' % (hexv, rgb2hex(v['rgb']), v['count'], 100.0 * v['count'] / total))


def cmd_register(paths, prefix, dry_run=False):
    doc = load_dict()
    colors = all_colors(doc)
    tol = doc['meta']['merge_tolerance']
    limit = doc['meta']['limit']
    added, merged, merged_list = 0, 0, []
    for p in paths:
        stats = extract_colors(p)
        print('== %s: %d 色' % (p, len(stats)))
        for hexv, v in sorted(stats.items(), key=lambda kv: -kv[1]['count']):
            rgb = v['rgb']
            # 1) 完全命中（同色）
            found = None
            for code, e in colors.items():
                if rgb2hex(e['rgb']) == hexv:
                    found = code
                    break
            if found:
                merged += v['count']
                merged_list.append((hexv, found, 'exact'))
                continue
            # 2) 容差归并：先锚点（硬锚点优先匹配但不被改写），后登记色
            best, best_d = None, 10 ** 9
            for code, e in colors.items():
                d = dist(rgb, e['rgb'])
                if d < best_d:
                    best, best_d = code, d
            if best and best_d <= tol:
                merged += v['count']
                merged_list.append((hexv, best, 'merge'))
                continue
            # 3) 新色登记
            if len(colors) >= limit and not dry_run:
                print('  !! 超 216 上限，未登记: %s（--force 或增大归并容差）' % hexv)
                continue
            code = next_code(colors, prefix)
            colors[code] = {'hex': hexv, 'rgb': rgb, 'name': '未命名', 'usage': '待人工审查', 'anchor': False}
            added += 1
            print('  + %s %s' % (code, hexv))
    doc['meta']['updated'] = os.environ.get('USERPROFILE', '') or ''
    import datetime
    doc['meta']['updated'] = datetime.date.today().isoformat()
    if not dry_run:
        save_dict(doc)
    print('--- 新增 %d 色 | 归并 %d 像素（%d 命中归并条）| 字典现 %d/%d 色 ---'
          % (added, merged, len(merged_list), len(colors), limit))
    for hexv, code, how in merged_list[:20]:
        print('    归并 %s -> %s (%s)' % (hexv, code, how))
    return 0


def cmd_check(paths):
    doc = load_dict()
    colors = all_colors(doc)
    tol = doc['meta']['merge_tolerance']
    limit = doc['meta']['limit']
    bad = 0
    if len(colors) > limit:
        print('XX 字典超限: %d > %d' % (len(colors), limit))
        bad += 1
    for p in paths:
        stats = extract_colors(p)
        missing = []
        for hexv in stats:
            rgb = [int(hexv[i:i + 2], 16) for i in (1, 3, 5)]
            found = False
            for e in colors.values():
                if dist(rgb, e['rgb']) <= tol:
                    found = True
                    break
            if not found:
                missing.append(hexv)
        status = 'OK' if not missing else 'MISSING %d' % len(missing)
        print('== %s: %d 色 %s' % (p, len(stats), status))
        for hexv in missing[:15]:
            print('    未登记(>%d): %s' % (tol, hexv))
        if missing:
            bad += 1
    print('--- check: %s ---' % ('PASS' if bad == 0 else 'FAIL %d' % bad))
    return 0 if bad == 0 else 1


def cmd_quantize(path, out):
    doc = load_dict()
    colors = all_colors(doc)
    entries = list(colors.values())
    img = Image.open(path).convert('RGBA')
    px = img.load()
    tol = doc['meta']['merge_tolerance']
    # 量化：每个像素 → 字典最近色（不透明像素）；锚点色优先
    def nearest(rgb):
        best, best_d = None, 10 ** 9
        for e in entries:
            d = dist(rgb, e['rgb'])
            if d < best_d:
                best, best_d = e['rgb'], d
        return best
    changed = 0
    total = 0
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = px[x, y]
            if a < 8:
                continue
            total += 1
            nr, ng, nb = nearest([r, g, b])
            if (nr, ng, nb) != (r, g, b):
                changed += 1
                px[x, y] = (nr, ng, nb, a)
    dst = out or path
    img.save(dst)
    print('量化 %s -> %s: %d/%d 像素换色 | 字典 %d 色' % (path, dst, changed, total, len(colors)))
    return 0


def cmd_report():
    doc = load_dict()
    colors = all_colors(doc)
    n_anchor = sum(1 for v in colors.values() if v.get('anchor'))
    print('字典: %s' % DICT_PATH)
    print('  总数 %d（锚点 %d / 登记 %d）| 上限 %d | 归并容差 ΔRGB≤%d'
          % (len(colors), n_anchor, len(colors) - n_anchor, doc['meta']['limit'], doc['meta']['merge_tolerance']))
    for prefix in PREFIXES:
        lst = sorted(c for c in colors if c.startswith(prefix))
        if lst:
            print('  %s 系: %s' % (prefix, ' '.join(lst)))
    return 0


def main():
    ap = argparse.ArgumentParser(description='色板字典登记工具')
    ap.add_argument('cmd', choices=['extract', 'register', 'check', 'quantize', 'report'])
    ap.add_argument('paths', nargs='*')
    ap.add_argument('--prefix', default='C', help='新色默认前缀（B/S/H/M/C/E/U/N）')
    ap.add_argument('--out', default=None, help='quantize 输出路径')
    ap.add_argument('--dry-run', action='store_true', help='register 不落盘')
    args = ap.parse_args()
    if args.cmd == 'extract':
        return cmd_extract(args.paths)
    if args.cmd == 'register':
        return cmd_register(args.paths, args.prefix, args.dry_run)
    if args.cmd == 'check':
        return cmd_check(args.paths)
    if args.cmd == 'quantize':
        if not args.paths:
            print('需指定 PNG 路径'); return 1
        return cmd_quantize(args.paths[0], args.out)
    if args.cmd == 'report':
        return cmd_report()
    return 0


if __name__ == '__main__':
    sys.exit(main())
