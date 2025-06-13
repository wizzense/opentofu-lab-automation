@echo off
REM Windows GUI Launcher for OpenTofu Lab Automation

echo.
echo ========================================
echo  OpenTofu Lab Automation - GUI Launcher
echo ========================================
echo.

REM Check if Python is available
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Python is not installed or not in PATH
    echo.
    echo Please install Python 3.7+ from: https://python.org
    echo Make sure to check "Add Python to PATH" during installation
    echo.
    pause
    exit /b 1
)

REM Check for tkinter
python -c "import tkinter" >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: tkinter is not available
    echo.
    echo tkinter should be included with Python on Windows.
    echo Try reinstalling Python or updating to a newer version.
    echo.
    pause
    exit /b 1
)

echo Starting GUI...

REM Check if gui.py exists
if not exist "%~dp0gui.py" (
    echo gui.py not found. Downloading from GitHub...
    powershell -Command "try { Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/feature/deployment-wrapper-gui/gui.py' -OutFile '%~dp0gui.py' -UseBasicParsing; Write-Host 'Downloaded gui.py successfully' } catch { Write-Host 'Failed to download gui.py:' $_.Exception.Message; exit 1 }"
    if not exist "%~dp0gui.py" (
        echo Failed to download gui.py
        pause
        exit /b 1
    )
)

REM Launch GUI without extra console windows on Windows
start "" /B python "%~dp0gui.py"

echo GUI launched successfully. You can close this window.
echo (The GUI will continue running in the background)

if %errorlevel% neq 0 (
    echo.
    echo *** GUI encountered an error ***
    pause
)
