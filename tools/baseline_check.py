"""Headless baseline check for Roguelike Studio.

Onboarding step 3: verify the project imports and runs with ZERO errors
before making any change, and again before committing.

Usage:
    python tools/baseline_check.py

Why Python (not bash): bash output redirection does not persist reliably
for the Godot process on Windows; subprocess pipes to files do.

Exit code 0 = baseline clean. Non-zero = baseline broken, do not commit.
"""

import os
import subprocess
import sys

GODOT = os.path.abspath("tools/Godot_v4.3-stable_win64.exe")
PROJECT = os.path.abspath(".")

# Ignorable stderr noise that does not indicate a project defect.
BENIGN = (
    "Your video card drivers seem not to support",
    "Blocking on the GPU",
)


def _read(path: str) -> str:
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as fh:
            return fh.read()
    except FileNotFoundError:
        return ""


def _significant(text: str) -> list[str]:
    lines = []
    for line in text.splitlines():
        stripped = line.strip()
        if not stripped:
            continue
        if any(token in stripped for token in BENIGN):
            continue
        lines.append(stripped)
    return lines


def run_stage(name: str, args: list[str], tag: str, timeout: int) -> bool:
    out_log = os.path.abspath(f"tools/baseline_{tag}_out.log")
    err_log = os.path.abspath(f"tools/baseline_{tag}_err.log")
    cmd = [GODOT, "--headless", "--path", PROJECT] + args

    print(f"[{name}] {' '.join(args)}")
    with open(out_log, "w", encoding="utf-8") as out, \
            open(err_log, "w", encoding="utf-8") as err:
        try:
            proc = subprocess.run(cmd, stdout=out, stderr=err, timeout=timeout)
        except subprocess.TimeoutExpired:
            print(f"[{name}] FAIL - timed out after {timeout}s")
            return False

    errors = _significant(_read(err_log))
    ok = proc.returncode == 0 and not errors

    if ok:
        print(f"[{name}] PASS - exit 0, stderr clean")
    else:
        print(f"[{name}] FAIL - exit {proc.returncode}, {len(errors)} stderr line(s)")
        for line in errors[:20]:
            print(f"    {line}")
        if len(errors) > 20:
            print(f"    ... {len(errors) - 20} more, see {err_log}")
    return ok


def main() -> int:
    if not os.path.isfile(GODOT):
        print(f"ERROR: engine not found at {GODOT}")
        print("The Godot binary is excluded from git - fetch it from the asset library.")
        return 2

    # 1) Import + parse every script and scene. Catches parse/autoload errors.
    stage1 = run_stage("import", ["--quit"], "import", timeout=180)
    # 2) Run the main scene for 4s. Catches runtime errors in _ready/_process.
    stage2 = run_stage("runtime", ["--quit-after", "4"], "runtime", timeout=120)

    print()
    if stage1 and stage2:
        print("BASELINE CLEAN - safe to commit.")
        return 0
    print("BASELINE BROKEN - fix before committing.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
