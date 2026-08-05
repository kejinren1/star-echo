@echo off
rem Star Echo 一键启动
rem 2026-08-05 修复：原 `--path "%~dp0"` 路径以反斜杠结尾，cmd 引号解析会吞掉 \" 导致
rem Godot 收到错误路径、窗口一闪而过（双击"没反应"）。改为 "%~dp0." 以点结尾，消除歧义。
cd /d "%~dp0"

if not exist "tools\Godot_v4.3-stable_win64.exe" (
    echo [ERROR] 未找到 Godot 引擎: tools\Godot_v4.3-stable_win64.exe
    echo 请确认 tools\ 目录下存在引擎文件后重试。
    pause
    exit /b 1
)

start "" "tools\Godot_v4.3-stable_win64.exe" --path "%~dp0."
exit /b 0
