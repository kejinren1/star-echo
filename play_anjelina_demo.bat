@echo off
rem Star Echo Anjelina dance demo launcher (2026-08-14)
rem 安杰丽娜 sit dance 游戏素材预览；ESC 退出
rem --path "%~dp0." 防 start 吞尾反斜杠（同 open_editor.bat 修复）
cd /d "%~dp0"

if not exist "tools\Godot_v4.3-stable_win64.exe" (
    echo [ERROR] Godot engine not found: tools\Godot_v4.3-stable_win64.exe
    pause
    exit /b 1
)

start "Star Echo Anjelina Dance" "%~dp0tools\Godot_v4.3-stable_win64.exe" --path "%~dp0." res://scenes/AnjelinaDance.tscn
exit /b 0
