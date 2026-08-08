## gen_color_dict.py — 初始色板字典生成（一次性）
## 输出：ART/COLOR_DICT.json（anchors=锚点硬色 / colors=登记色）
import json, datetime

# 锚点色板 32 色（ART_STYLE.md 第二章）：按语义前缀登记；重复色值只登记一次
anchor_spec = [
    # (hex, 前缀, 名称, 用途)  前缀: B背景/S皮肤/H发色/M金属/C服装/E特效/U-UI/N描边
    ('#0d0d12', 'N', '深空黑', '描边/最暗背景（硬锚点）'),
    ('#1a1a2e', 'B', '暗夜蓝', '主背景'),
    ('#16213e', 'B', '深海蓝', '背景渐变'),
    ('#0f3460', 'B', '午夜蓝', '地面阴影'),
    ('#2d2d3f', 'B', '暗石灰', '中间调暗色'),
    ('#3d3d4f', 'B', '冷灰', '地面基础'),
    ('#4a4a5f', 'B', '暖灰', '地面高光'),
    ('#e94560', 'C', '战斗红', '玩家主色/血条'),
    ('#f38181', 'S', '柔粉红', '玩家次色/皮肤（硬锚点）'),
    ('#f6c90e', 'C', '警示黄', '精英敌人/物品'),
    ('#6bc86b', 'C', '毒绿', '毒系敌人/经验/UI确认绿'),
    ('#4e89de', 'C', '钴蓝', '冰系敌人/UI蓝'),
    ('#9d4edd', 'C', '暗紫', 'Boss/稀有'),
    ('#ff6b35', 'C', '烈焰橙', '火系敌人'),
    ('#2ec4b6', 'C', '青绿', '闪电/特殊'),
    ('#00f5ff', 'E', '电青', '闪电特效/暴击'),
    ('#ff00ff', 'E', '品红', '魔法特效'),
    ('#fffd00', 'E', '电黄', '金币/拾取高亮'),
    ('#39ff14', 'E', '霓虹绿', '升级/治疗'),
    ('#ff5e00', 'E', '烈焰橙', '火焰特效'),
    ('#b026ff', 'E', '紫电', '穿透特效'),
    ('#ff073a', 'E', '激光红', '远程特效'),
    ('#ffffff', 'E', '纯白', '命中闪白/文字/UI高亮文字'),
    ('#1e1e2f', 'U', 'UI面板底', '半透明面板'),
    ('#2a2a3f', 'U', 'UI面板边', '边框'),
    ('#7a7a8f', 'U', 'UI次文字', '次要文字'),
    ('#cccccc', 'U', 'UI主文字', '主文字'),
    ('#5c5c73', 'U', 'UI禁用', '灰色不可用'),
    ('#3a3a4f', 'U', 'UI槽位底', '空/占位'),
]
# pindou 艾琳 idle 图纸 13 色（docs/pindou/elin_idle.json）：亮度启发式分 C/N 系
pindou_spec = [
    ('#6f4b48', 'C', '艾琳披风主', '艾琳(se_irene)服装主色'),
    ('#dad8d6', 'C', '艾琳浅灰', '艾琳服装高光'),
    ('#aa9892', 'C', '艾琳灰褐', '艾琳服装中间调'),
    ('#89625d', 'C', '艾琳红褐', '艾琳服装次色'),
    ('#2d2427', 'N', '艾琳深描边', '艾琳轮廓描边'),
    ('#c5bebc', 'C', '艾琳亮灰', '艾琳服装亮部'),
    ('#301818', 'N', '艾琳暗红描边', '艾琳暗部描边'),
    ('#782725', 'C', '艾琳深红', '艾琳服装暗部'),
    ('#531a18', 'N', '艾琳暗红', '艾琳发饰暗色'),
    ('#4d312d', 'C', '艾琳深褐', '艾琳服装过渡'),
    ('#220f10', 'N', '艾琳近黑', '艾琳最暗描边'),
    ('#a8342f', 'C', '艾琳红', '艾琳法袍红'),
    ('#d6ebe6', 'C', '艾琳青白', '艾琳高光/发色点缀'),
]


def hex2rgb(h):
    h = h.lstrip('#')
    return [int(h[i:i + 2], 16) for i in (0, 2, 4)]


def next_code(d, prefix):
    i = 0
    while ('%s%02d' % (prefix, i)) in d:
        i += 1
    return '%s%02d' % (prefix, i)


anchors, colors = {}, {}
# 色号全局唯一：锚点色先占号，登记色顺延
for spec in anchor_spec:
    hexv, pref, name, usage = spec
    code = next_code(anchors, pref)
    anchors[code] = {'hex': hexv, 'rgb': hex2rgb(hexv), 'name': name, 'usage': usage, 'anchor': True}

for spec in pindou_spec:
    hexv, pref, name, usage = spec
    code = next_code(anchors, pref)  # 同一命名空间，顺延不撞号
    anchors[code] = {'hex': hexv, 'rgb': hex2rgb(hexv), 'name': name, 'usage': usage, 'anchor': False}

doc = {
    'meta': {
        'version': 1,
        'limit': 216,
        'merge_tolerance': 12,
        'updated': datetime.date.today().isoformat(),
        'source': ['ART_STYLE.md 锚点色板(32色)', 'docs/pindou/elin_idle.json 艾琳图纸(13色)'],
        'note': '色板字典登记制：提取实际用色→登记入字典→容差内(ΔRGB≤12)归并邻近色；anchor=true=硬锚点不容差归并；色号全局唯一（前缀+两位数字）',
    },
    'colors': anchors,
}
out = r'D:/Program Files/30DAYS/ART/COLOR_DICT.json'
with open(out, 'w', encoding='utf-8') as f:
    json.dump(doc, f, ensure_ascii=False, indent=2)
n_anchor = sum(1 for v in anchors.values() if v['anchor'])
print('total: %d（锚点 %d + 登记 %d）' % (len(anchors), n_anchor, len(anchors) - n_anchor))
for k in sorted(anchors):
    print('  %s %s %-8s %s' % (k, anchors[k]['hex'], '*' if anchors[k]['anchor'] else ' ', anchors[k]['name']))

