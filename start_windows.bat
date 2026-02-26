@echo off
REM Windows Background Launcher for Audio Hotkey Player
REM This script runs the Python script hidden in the background

echo Starting Audio Hotkey Player in background...

REM Run Python script hidden (no window)
start /B pythonw audio_hotkey.py

echo Audio Hotkey Player started!
echo To stop it, use Task Manager to end the pythonw.exe process
echo or run: taskkill /F /IM pythonw.exe

timeout /t 3
