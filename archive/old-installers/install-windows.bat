@echo off
REM OpenTofu Lab Automation - Windows Quick Installer
REM Works on Windows 10/11, Server 2016+, with or without GUI
REM No external dependencies required

setlocal enabledelayedexpansion
echo.
echo ===============================================
echo   OpenTofu Lab Automation - Windows Installer
echo ===============================================
echo.

REM Check if PowerShell is available (it should be on all modern Windows)
powershell -Command "Write-Host 'PowerShell detected'" >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: PowerShell is required but not found
    echo This should work on Windows 10/11 and Server 2016+
    pause
    exit /b 1
)

REM Download and run the PowerShell installer
echo Downloading OpenTofu Lab Automation...
powershell -ExecutionPolicy Bypass -Command "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; try { $webClient = New-Object System.Net.WebClient; $webClient.Headers.Add('User-Agent', 'OpenTofu-Installer/1.0'); $content = $webClient.DownloadString('https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/HEAD/launcher.py'); if ($content -match 'OpenTofu Lab Automation') { $content | Out-File -FilePath 'launcher.py' -Encoding UTF8; Write-Host 'Downloaded launcher.py successfully' -ForegroundColor Green; } else { throw 'Invalid content downloaded' } } catch { Write-Host 'Download failed, trying alternative method...' -ForegroundColor Yellow; try { Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/HEAD/launcher.py' -OutFile 'launcher.py' -UseBasicParsing; Write-Host 'Downloaded using Invoke-WebRequest' -ForegroundColor Green; } catch { Write-Host 'All download methods failed. Please check internet connection.' -ForegroundColor Red; exit 1 } } }"

if not exist launcher.py (
    echo ERROR: Download failed
    echo Please check your internet connection and try again
    pause
    exit /b 1
)

echo.
echo ✅ Download completed successfully!
echo.

REM Check if Python is available
python --version >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ Python found, launching interactive menu...
    echo.
    python launcher.py
) else (
    echo ⚠️ Python not found. Please install Python 3.7+ from:
    echo     https://www.python.org/downloads/
    echo.
    echo After installing Python, run: python launcher.py
    echo.
    pause
)

echo.
echo Installation files are ready in the current directory.
echo To run again: python launcher.py
pause
