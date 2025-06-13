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
python "%~dp0gui.py"

if %errorlevel% neq 0 (
    echo.
    echo *** GUI encountered an error ***
    pause
)
