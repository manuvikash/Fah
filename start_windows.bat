@echo off
cd /d "%~dp0"
if not exist ".venv\Scripts\pythonw.exe" (
    echo fah is not installed. Run install.ps1 first.
    pause
    exit /b 1
)
start "" .venv\Scripts\pythonw.exe -m fah
echo fah is running in the background.
echo To stop:  taskkill /F /IM pythonw.exe
