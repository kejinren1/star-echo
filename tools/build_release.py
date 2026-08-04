"""One-command release build for Roguelike Studio.

Replaces the manual 3-step dance (export-pack -> copy engine exe -> zip)
with a single verified command.

Usage:
    python tools/build_release.py            # build + verify
    python tools/build_release.py --zip      # also produce build.zip

Output:
    build/RoguelikeStudio.exe   (engine binary, renamed to match the pck)
    build/RoguelikeStudio.pck   (game data)
    build.zip                   (optional, distributable bundle)

The exe and pck MUST share the same directory and filename prefix, otherwise
Godot will not auto-load the pck and the game boots to a blank project.

Exit code 0 = release is good to ship.
"""

import argparse
import hashlib
import os
import shutil
import subprocess
import sys
import zipfile

NAME = "RoguelikeStudio"
ENGINE = os.path.abspath("tools/Godot_v4.3-stable_win64.exe")
PROJECT = os.path.abspath(".")
BUILD_DIR = os.path.abspath("build")
EXE = os.path.join(BUILD_DIR, f"{NAME}.exe")
PCK = os.path.join(BUILD_DIR, f"{NAME}.pck")
ZIP = os.path.abspath("build.zip")
PRESET = "Windows Desktop"


def sha16(path: str) -> str:
    digest = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()[:16]


def step(msg: str) -> None:
    print(f"[build] {msg}")


def export_pack() -> bool:
    step(f"exporting pack -> {os.path.relpath(PCK)}")
    proc = subprocess.run(
        [ENGINE, "--headless", "--path", PROJECT, "--export-pack", PRESET, PCK],
        capture_output=True, text=True, timeout=600,
    )
    if proc.returncode != 0 or not os.path.exists(PCK):
        print(f"[build] FAIL - export exit {proc.returncode}")
        print(proc.stderr.strip()[-2000:])
        return False
    step(f"pck ok, {os.path.getsize(PCK) / 1024:.1f} KB")
    return True


def stage_exe() -> bool:
    # The shipped exe is just the engine binary renamed to match the pck.
    if os.path.exists(EXE) and sha16(EXE) == sha16(ENGINE):
        step("exe already matches engine, skip copy")
        return True
    step("copying engine binary -> build exe")
    shutil.copy2(ENGINE, EXE)
    ok = sha16(EXE) == sha16(ENGINE)
    step(f"exe {'ok' if ok else 'MISMATCH'}, {os.path.getsize(EXE) / 1048576:.1f} MB")
    return ok


def verify() -> bool:
    step("verifying packaged build boots (headless 4s)")
    proc = subprocess.run(
        [EXE, "--headless", "--quit-after", "4"],
        capture_output=True, text=True, timeout=120, cwd=BUILD_DIR,
    )
    err = proc.stderr.strip()
    if proc.returncode != 0 or err:
        print(f"[build] FAIL - boot exit {proc.returncode}")
        print(err[-2000:] or "(no stderr)")
        return False
    step("boot ok, stderr clean")
    return True


def make_zip() -> None:
    step(f"zipping -> {os.path.relpath(ZIP)}")
    with zipfile.ZipFile(ZIP, "w", zipfile.ZIP_DEFLATED) as zf:
        zf.write(EXE, f"build/{NAME}.exe")
        zf.write(PCK, f"build/{NAME}.pck")
    step(f"zip ok, {os.path.getsize(ZIP) / 1048576:.1f} MB")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--zip", action="store_true",
                        help="also produce build.zip for the asset library")
    args = parser.parse_args()

    if not os.path.isfile(ENGINE):
        print(f"[build] ERROR - engine not found at {ENGINE}")
        print("The Godot binary is excluded from git - fetch it from the asset library.")
        return 2

    os.makedirs(BUILD_DIR, exist_ok=True)
    if not (export_pack() and stage_exe() and verify()):
        print("\nRELEASE FAILED")
        return 1
    if args.zip:
        make_zip()

    print("\nRELEASE OK - double-click build/RoguelikeStudio.exe to play.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
