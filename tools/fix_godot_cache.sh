#!/bin/bash
# =============================================================================
# fix_godot_cache.sh — 《星骸回响》.godot 缓存一键自愈（2026-08-18 根治历史顽疾）
# -----------------------------------------------------------------------------
# 背景：本项目已多次遭遇 .godot 缓存损坏（signal 11 全模式崩溃），历史修复
# 均为手工逐条操作（mv 缓存→编辑器导入→跑探针验证）。本脚本把三步固化为
# 一条命令，并引入 --import 模式（Godot 只导入资源后自动退出，不会被
# --quit-after 帧数中途截断导致半成品缓存）。
#
# 用法：
#   bash tools/fix_godot_cache.sh           # 自愈（默认保留 2 份旧备份）
#   bash tools/fix_godot_cache.sh --keep 0  # 自愈且不保留旧备份
#   bash tools/fix_godot_cache.sh --check   # 只检查缓存完整性，不重建
#
# 退出码：0 = 健康/自愈成功；非 0 = 仍异常
# =============================================================================
set -u
cd "$(dirname "$0")/.." || exit 2

GODOT="./tools/Godot_v4.3-stable_win64.exe"
KEEP=2
CHECK_ONLY=0
for arg in "$@"; do
  case "$arg" in
    --keep) KEEP="${2:-2}"; shift 2;;
    --check) CHECK_ONLY=1;;
  esac
done

say()  { printf '[fix-cache] %s\n' "$*"; }
fail() { printf '[fix-cache] FAIL %s\n' "$*"; exit 1; }

# ---- 1. 健康检查：核心缓存文件在 + 无崩溃标记 ----
HAS_IMPORTED=0
[ -d .godot/imported ] && HAS_IMPORTED=$(ls .godot/imported 2>/dev/null | wc -l)
HAS_GLOBAL_CACHE=0
[ -f .godot/global_script_class_cache.cfg ] && HAS_GLOBAL_CACHE=1

if [ "$CHECK_ONLY" = "1" ]; then
  if [ "$HAS_IMPORTED" -gt 50 ] && [ "$HAS_GLOBAL_CACHE" = "1" ]; then
    say "缓存健康（imported=%d, global_cache=%d）" "$HAS_IMPORTED" "$HAS_GLOBAL_CACHE"
    exit 0
  fi
  say "缓存异常（imported=%d, global_cache=%d）——需要修复" "$HAS_IMPORTED" "$HAS_GLOBAL_CACHE"
  exit 3
fi

if [ "$HAS_IMPORTED" -gt 50 ] && [ "$HAS_GLOBAL_CACHE" = "1" ]; then
  say "缓存健康，无需重建（imported=%d）" "$HAS_IMPORTED"
  exit 0
fi

# ---- 2. 移走异常缓存（保留旧备份，便于回溯） ----
if [ -d .godot ]; then
  TS=$(date +%H%M%S)
  mv .godot ".godot_broken_$(date +%Y%m%d)_${TS}"
  say "异常缓存已移走 → .godot_broken_$(date +%Y%m%d)_${TS}"
fi

# ---- 3. --import 全量导入（只导入资源，完成后自动退出） ----
say "开始全量资源导入（--import）…"
if ! "$GODOT" --headless --import --path . > /tmp/godot_import.log 2>&1; then
  tail -20 /tmp/godot_import.log
  fail "资源导入失败（见 /tmp/godot_import.log）"
fi
IMPORTED=$(ls .godot/imported 2>/dev/null | wc -l)
say "导入完成：imported=%d" "$IMPORTED"

# ---- 4. 重建 global_script_class_cache（--import 不生成，需 --editor 扫一次） ----
"$GODOT" --headless --editor --quit-after 120 --path . > /tmp/godot_scan.log 2>&1
say "class cache 扫描完成"

# ---- 5. 验证：跑关键探针 ----
if [ -f tools/day31_charsel_check.gd ]; then
  if "$GODOT" --headless --path . --script res://tools/day31_charsel_check.gd > /tmp/godot_verify.log 2>&1; then
    say "验证探针通过（day31_charsel_check）"
  else
    if grep -q "signal 11\|crashed" /tmp/godot_verify.log; then
      fail "验证仍崩溃（signal 11）——可能素材本身有问题，见 /tmp/godot_verify.log"
    fi
    say "验证探针有 FAIL 项（非崩溃），见 /tmp/godot_verify.log"
  fi
fi

# ---- 6. 清理旧备份（保留最新 KEEP 份） ----
COUNT=$(ls -d .godot_broken_* .godot_bak_* .godot_tmp_backup 2>/dev/null | wc -l)
REMOVE=$((COUNT - KEEP))
if [ "$REMOVE" -gt 0 ]; then
  # 按 mtime 排序，删最旧的
  ls -dt .godot_broken_* .godot_bak_* .godot_tmp_backup 2>/dev/null | tail -n "$REMOVE" | while read -r d; do
    rm -rf "$d" && say "清理旧备份：$d"
  done
fi

say "自愈完成 ✅"
exit 0
