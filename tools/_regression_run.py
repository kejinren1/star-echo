"""全量回归驱动：逐个探针 + baseline + weapons verify（带超时护栏）。Day17-P0 同步：+day17_p0_check(20)，day14_15 53→54。

用法：
    python tools/_regression_run.py
"""
import os
import subprocess
import sys

GODOT = os.path.abspath("tools/Godot_v4.3-stable_win64.exe")
PROJECT = os.path.abspath(".")

PROBES = [
    ("day2_hero_check", ["--script", "res://tools/day2_hero_check.gd"], 32),
    ("day3_skill_check", ["--script", "res://tools/day3_skill_check.gd"], 16),
    ("day4_level_check", ["--script", "res://tools/day4_level_check.gd"], 21),
    ("day5_weapon_check", ["--script", "res://tools/day5_weapon_check.gd"], 16),
    ("day6_integration_check", ["--script", "res://tools/day6_integration_check.gd"], 14),
    ("day7_weapon_data_check", ["--script", "res://tools/day7_weapon_data_check.gd"], 13),
    ("day8_weapon_data_check", ["--script", "res://tools/day8_weapon_data_check.gd"], 19),
    ("day10_evolution_check", ["--script", "res://tools/day10_evolution_check.gd"], 21),
    ("day11_12_passive_check", ["--script", "res://tools/day11_12_passive_check.gd"], 24),
    ("day13_build_check", ["--script", "res://tools/day13_build_check.gd"], 36),
    ("day14_15_route_check", ["--script", "res://tools/day14_15_route_check.gd"], 54),
    ("day16_event_check", ["--script", "res://tools/day16_event_check.gd"], 42),
    # F-47 同步（2026-08-18 执行者第 62 轮）：mom max_spawns 上限行为+数据 +2 断言 → 39→41
    ("day17_elite_check", ["--script", "res://tools/day17_elite_check.gd"], 41),
    ("day17_p0_check", ["--script", "res://tools/day17_p0_check.gd"], 20),
    # F-46 同步（2026-08-18 执行者第 62 轮）：§4 分数制 +3 断言 → 16→17
    ("day18_feedback_check", ["--script", "res://tools/day18_feedback_check.gd"], 17),
    ("day18_feedback2_check", ["--script", "res://tools/day18_feedback2_check.gd"], 42),
    ("day18_feedback3_check", ["--script", "res://tools/day18_feedback3_check.gd"], 27),
    ("day18_feedback4_check", ["--script", "res://tools/day18_feedback4_check.gd"], 18),
    ("day18_feedback5_check", ["--script", "res://tools/day18_feedback5_check.gd"], 28),
    ("day18_feedback6_check", ["--script", "res://tools/day18_feedback6_check.gd"], 10),
    ("day18_19_boss_check", ["--script", "res://tools/day18_19_boss_check.gd"], 48),
    ("day20_relic_check", ["--script", "res://tools/day20_relic_check.gd"], 23),
    ("day21_22_art_check", ["--script", "res://tools/day21_22_art_check.gd"], 38),
    ("day23_vfx_check", ["--script", "res://tools/day23_vfx_check.gd"], 18),
    ("day24_f13_check", ["--script", "res://tools/day24_f13_check.gd"], 17),
    ("day24_audio_check", ["--script", "res://tools/day24_audio_check.gd"], 14),
    ("day26_integration_check", ["--script", "res://tools/day26_integration_check.gd"], 34),
    ("day27_meta_check", ["--script", "res://tools/day27_meta_check.gd"], 35),
    ("day28_f31_check", ["--script", "res://tools/day28_f31_check.gd"], 26),
    ("day29_elin_anim_check", ["--script", "res://tools/day29_elin_anim_check.gd"], 14),
    ("day29_attack_check", ["--script", "res://tools/day29_attack_check.gd"], 20),
    ("day30_p0_fix_check", ["--script", "res://tools/day30_p0_fix_check.gd"], 15),
    ("day30_f1_scaling_check", ["--script", "res://tools/day30_f1_scaling_check.gd"], 14),
    ("day30_f1d_shop_check", ["--script", "res://tools/day30_f1d_shop_check.gd"], 8),
    ("day30_f2_boundary_check", ["--script", "res://tools/day30_f2_boundary_check.gd"], 36),
    ("day30_f1_scatter_check", ["--script", "res://tools/day30_f1_scatter_check.gd"], 19),
    ("day30_f3_compliance_check", ["--script", "res://tools/day30_f3_compliance_check.gd"], 12),
    ("day30_f3_flow_check", ["--script", "res://tools/day30_f3_flow_check.gd"], 21),
    ("day30_effect_check", ["--script", "res://tools/day30_effect_check.gd"], 18),
    ("day30_boss_skill_check", ["--script", "res://tools/day30_boss_skill_check.gd"], 49),
    # G 系列（2026-08-14 · 方案 §5 请求 #3 并入）
    ("day30_g_mainmenu_check", ["--script", "res://tools/day30_g_mainmenu_check.gd"], 8),
    ("day30_g_map_check", ["--script", "res://tools/day30_g_map_check.gd"], 10),
    ("day30_g_codex_check", ["--script", "res://tools/day30_g_codex_check.gd"], 10),
    ("day30_g_archive_check", ["--script", "res://tools/day30_g_archive_check.gd"], 8),
    ("day30_g_backpack_check", ["--script", "res://tools/day30_g_backpack_check.gd"], 8),
    ("day30_g_skilltree_check", ["--script", "res://tools/day30_g_skilltree_check.gd"], 10),
    ("day31_spawner_deadlock_check", ["--script", "res://tools/day31_spawner_deadlock_check.gd"], 7),
    # PS-A（2026-08-16 · PLAYER_SKILL_SPEC §4 多技能位 3 槽 + 键位路由）
    ("day31_skill_slots_check", ["--script", "res://tools/day31_skill_slots_check.gd"], 11),
    # PS-B（2026-08-16 · PLAYER_SKILL_SPEC §5/§6 位移三型 + invulnerable）
    ("day31_skill_movement_check", ["--script", "res://tools/day31_skill_movement_check.gd"], 13),
    # PS-C（2026-08-16 · PLAYER_SKILL_SPEC §7/§9 skill_relics 掉落 + per_character + 剑士剑气）
    ("day31_skill_relic_check", ["--script", "res://tools/day31_skill_relic_check.gd"], 9),
    # PS-E（2026-08-16 · PLAYER_SKILL_SPEC §3 D6 局外等级奖励）
    ("day31_skill_levelup_check", ["--script", "res://tools/day31_skill_levelup_check.gd"], 7),
    # PS-D（2026-08-16 · PLAYER_SKILL_SPEC §8 章节化 routes 数据层）
    # PS-D4 扩展（2026-08-17 · 方案第 24 轮 §5）：§4a 章末事件 + §4b 章界显示 + §5 一致性护栏 → 11 断言
    ("day31_chapter_check", ["--script", "res://tools/day31_chapter_check.gd"], 11),
    # 用户反馈出口（2026-08-18 · TEST_REPORT #54 观察「day31 五新探针未入 runner」→ 并入）
    ("day31_boss_after_check", ["--script", "res://tools/day31_boss_after_check.gd"], 6),
    ("day31_charsel_check", ["--script", "res://tools/day31_charsel_check.gd"], 12),
    ("day31_enemy_richness_check", ["--script", "res://tools/day31_enemy_richness_check.gd"], 5),
    ("day31_melee_sweep_check", ["--script", "res://tools/day31_melee_sweep_check.gd"], 9),
    ("day31_player_model_check", ["--script", "res://tools/day31_player_model_check.gd"], 6),
    ("day31_items_atlas_check", ["--script", "res://tools/day31_items_atlas_check.gd"], 58),
    # 总指挥 2026-08-18 F1-E 第一批：敌人精灵表现抽表闭环（presentation.json ↔ const 一致性 + DataLoader 消费）
    # expect 286 = 2026-08-19 #3 执行 F1-E-4 第四批 FX 抽表 +§6 fx 段（273 + 13，元数据同步）
    ("day31_presentation_check", ["--script", "res://tools/day31_presentation_check.gd"], 286),
    # 总指挥 2026-08-18：技能图标映射闭环（skills.png 5 帧 + SKILL_ICON_MAP 全量覆盖 + 越界防护）
    ("day31_skill_icon_check", ["--script", "res://tools/day31_skill_icon_check.gd"], 22),
    # AUDIO_FEEL（2026-08-18 AF-P0 批 A-C）：hitstop 顿帧 + 震屏分级 + 音画同步（day31_feel_check）
    ("day31_feel_check", ["--script", "res://tools/day31_feel_check.gd"], 26),
    # F-44（2026-08-18 总指挥 · 用户拍板）：小怪不逃离主角 + 不出地图边界 + 出界即死
    #   （ranged velocity 方向语义 + 边界钳制 + grow64 出界 die + 常规不误杀，物理无关白盒）
    # F-46 同步（2026-08-18 执行者第 62 轮）：+§5 Aggro Leash 4 断言 → 18→22
    ("day31_flee_bound_check", ["--script", "res://tools/day31_flee_bound_check.gd"], 22),
    # F-49 同步（2026-08-19 #3 执行 · TEST_REPORT #62 观察「day31_portal_check 未入 runner」→ 并入）：
    # 通关传送门+宝箱机制（exit_portal 开启/接触结算 + loot_chest 拾取）
    ("day31_portal_check", ["--script", "res://tools/day31_portal_check.gd"], 24),
    # LEVEL_DESIGN LD-A 同步（2026-08-19 #3 执行 · 规格 LEVEL_DESIGN_SPEC.md · 数据地基批）：
    # spawn_points/boss_phase_events 两新表导出 + 三接口 + FK 数据侧合法性 + waves 示例填值
    ("day31_level_design_data_check", ["--script", "res://tools/day31_level_design_data_check.gd"], 24),
]


def run_one(name: str, extra: list[str], expect: int) -> bool:
    out_log = os.path.abspath(f"tools/regr_{name}_out.log")
    err_log = os.path.abspath(f"tools/regr_{name}_err.log")
    cmd = [GODOT, "--headless", "--path", PROJECT] + extra
    try:
        with open(out_log, "w", encoding="utf-8") as out, \
                open(err_log, "w", encoding="utf-8") as err:
            proc = subprocess.run(cmd, stdout=out, stderr=err, timeout=300)
    except subprocess.TimeoutExpired:
        print(f"[{name}] TIMEOUT(300s)")
        return False
    out_text = open(out_log, encoding="utf-8", errors="replace").read()
    err_text = open(err_log, encoding="utf-8", errors="replace").read()
    err_clean = not any(l.strip() and "SCRIPT ERROR" not in l for l in err_text.splitlines())
    script_errors = sum(1 for l in err_text.splitlines() if "SCRIPT ERROR" in l)
    ok_exit = proc.returncode == 0
    ok_errors = script_errors == 0
    ok_asserts = True
    if "CLEAN" in out_text:
        ok_asserts = True
    else:
        # 兼容三种断言汇总格式（2026-08-18 扩展，支撑 day31 新探针并入）：
        #   "N assertions, M failures"   （英文标准）
        #   "N checked, M failed"        （英文变体，day31_boss_after_check）
        #   "检查 N 项，失败 M 项"        （中文，day31_charsel/enemy_richness/melee_sweep/player_model）
        import re
        m = (re.search(r"(\d+) assertions,\s*(\d+) failures", out_text)
             or re.search(r"(\d+) checked,\s*(\d+) failed", out_text)
             or re.search(r"检查\s*(\d+)\s*项，失败\s*(\d+)\s*项", out_text))
        if m:
            ok_asserts = int(m.group(2)) == 0 and int(m.group(1)) >= expect
        else:
            # 无汇总格式：以退出码 + 零 script error 为判据（兼容 probe 类探针）
            ok_asserts = True
    status = "PASS" if (ok_exit and ok_errors and ok_asserts) else "FAIL"
    print(f"[{name}] {status} exit={proc.returncode} script_errors={script_errors}")
    if status == "FAIL":
        for line in out_text.splitlines()[-6:]:
            print("    | " + line)
        for line in err_text.splitlines()[:4]:
            if "SCRIPT ERROR" in line:
                print("    ! " + line)
    return status == "PASS"


def main() -> int:
    results = []
    for name, extra, expect in PROBES:
        results.append((name, run_one(name, extra, expect)))
    print()
    ok = 0
    for name, passed in results:
        mark = "PASS" if passed else "FAIL"
        print(f"  {mark}  {name}")
        if passed:
            ok += 1
    print(f"\n=== REGRESSION {ok}/{len(results)} passed ===")
    return 0 if ok == len(results) else 1


if __name__ == "__main__":
    sys.exit(main())
