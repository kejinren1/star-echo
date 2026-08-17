@echo off
rem Star Echo IdleDemo launcher (2026-08-14) — L1 引擎动画演示
rem 帧序列呼吸(12帧) vs 程序化呼吸(sin) 对照；ESC 退出
rem 与 open_editor.bat 同款修复：--path "%~dp0." 防 start 吞尾反斜杠
cd /d "%~dp0"

if not exist "tools\Godot_v4.3-stable_win64.exe" (
    echo [ERROR] Godot engine not found: tools\Godot_v4.3-stable_win64.exe
    echo Check the tools directory and retry.
    pause
    exit /b 1
)

start "Star Echo IdleDemo" "%~dp0tools\Godot_v4.3-stable_win64.exe" --path "%~dp0." res://scenes/IdleDemo.tscn
exit /b 0
