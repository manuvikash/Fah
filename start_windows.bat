@echo off
cd /d "%~dp0"
if not exist ".venv\Scripts\fah.exe" (
    echo fah is not installed. Run install.ps1 first.
    pause
    exit /b 1
)
.venv\Scripts\fah.exe
if errorlevel 1 pause
