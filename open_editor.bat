@echo off
rem Star Echo editor launcher (fixed 2026-08-14: dot-suffix on --path, same bug as play_game.bat)
rem `start` quote re-parsing swallows the trailing backslash of "%~dp0", truncating
rem the path and making Godot abort immediately. Use "%~dp0." to avoid it.
cd /d "%~dp0"

if not exist "tools\Godot_v4.3-stable_win64.exe" (
    echo [ERROR] Godot engine not found: tools\Godot_v4.3-stable_win64.exe
    echo Check the tools directory and retry.
    pause
    exit /b 1
)

start "Star Echo Editor" "%~dp0tools\Godot_v4.3-stable_win64.exe" --path "%~dp0." -e
exit /b 0
