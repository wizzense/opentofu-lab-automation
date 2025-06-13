@echo off
REM Windows Batch Wrapper for OpenTofu Lab Automation
REM This provides a simple double-click deployment option for Windows users

echo.
echo ===============================================
echo  OpenTofu Lab Automation - Windows Deployment
echo ===============================================
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

REM Run the deployment script
echo Starting deployment...
python "%~dp0deploy.py" %*

REM Pause to show results
if %errorlevel% neq 0 (
    echo.
    echo *** Deployment encountered errors ***
    pause
) else (
    echo.
    echo *** Deployment completed successfully ***
    timeout /t 5 /nobreak >nul
)
