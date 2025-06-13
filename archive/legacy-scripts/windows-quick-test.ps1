






# OpenTofu Lab Automation - Windows Quick Test Script
# Run this script to download and test the improved GUI

Write-Host "🧪 OpenTofu Lab Automation - Windows Quick Test" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# Download improved GUI
Write-Host "`n📥 Downloading improved GUI..." -ForegroundColor Yellow
try {
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/feature/deployment-wrapper-gui/gui.py" -OutFile "gui.py" -UseBasicParsing
    Write-Host "✅ gui.py downloaded successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to download gui.py: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Download new PowerShell launcher
Write-Host "`n📥 Downloading PowerShell launcher..." -ForegroundColor Yellow
try {
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/feature/deployment-wrapper-gui/launch-gui.ps1" -OutFile "launch-gui.ps1" -UseBasicParsing
    Write-Host "✅ launch-gui.ps1 downloaded successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to download launch-gui.ps1: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test direct GUI launch
Write-Host "`n🎮 Testing direct GUI launch..." -ForegroundColor Cyan
Write-Host "Note: This will launch the GUI directly for immediate testing" -ForegroundColor Gray

try {
    # Check Python availability
    $pythonCmd = $null
    try {
        python --version | Out-Null
        $pythonCmd = "python"
    } catch {
        try {
            py --version | Out-Null  
            $pythonCmd = "py"
        } catch {
            throw "Python not found"
        }
    }
    
    Write-Host "✅ Python found: $pythonCmd" -ForegroundColor Green
    Write-Host "🚀 Launching GUI (optimized for Windows performance)..." -ForegroundColor Cyan
    
    # Launch GUI
    & $pythonCmd gui.py
    
} catch {
    Write-Host "❌ Error launching GUI: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "You can try manually: python gui.py" -ForegroundColor Yellow
}

Write-Host "`n📋 Available launch options:" -ForegroundColor Cyan
Write-Host "1. python gui.py          (direct launch)" -ForegroundColor White
Write-Host "2. .\launch-gui.ps1       (PowerShell launcher)" -ForegroundColor White
Write-Host "3. .\launch-gui.ps1 -Quiet (silent launcher)" -ForegroundColor White

Write-Host "`n✅ Test complete! GUI should be running with performance optimizations." -ForegroundColor Green



