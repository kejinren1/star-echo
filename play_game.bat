@echo off
rem Star Echo launcher (fixed 2026-08-05: pure ASCII + absolute paths)
rem Use --path "%~dp0." (dot suffix) so the trailing backslash is not swallowed
rem by `start`'s quote re-parsing, which truncated the path at the space in
rem "D:\30DAYS" and made Godot abort immediately.
cd /d "%~dp0"

if not exist "tools\Godot_v4.3-stable_win64.exe" (
    echo [ERROR] Godot engine not found: tools\Godot_v4.3-stable_win64.exe
    echo Check the tools directory and retry.
    pause
    exit /b 1
)

start "Star Echo" "%~dp0tools\Godot_v4.3-stable_win64.exe" --path "%~dp0."
exit /b 0
