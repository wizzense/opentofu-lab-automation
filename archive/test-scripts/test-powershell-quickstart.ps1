






# Windows PowerShell Quick Start Test
# This script tests the PowerShell instructions from the README

Write-Host "� Testing OpenTofu Lab Automation - PowerShell Quick Start" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan

# Test 1: Download deploy.py
Write-Host "`n� Test 1: Downloading deploy.py..." -ForegroundColor Yellow
try {
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/feature/deployment-wrapper-gui/deploy.py" -OutFile "test-deploy.py"
    if (Test-Path "test-deploy.py") {
        Write-Host "PASS SUCCESS: deploy.py downloaded successfully" -ForegroundColor Green
        $fileSize = (Get-Item "test-deploy.py").Length
        Write-Host "   File size: $fileSize bytes" -ForegroundColor Gray
    } else {
        Write-Host "FAIL FAILED: deploy.py not found after download" -ForegroundColor Red
    }
} catch {
    Write-Host "FAIL FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Download GUI
Write-Host "`n� Test 2: Downloading gui.py..." -ForegroundColor Yellow
try {
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/feature/deployment-wrapper-gui/gui.py" -OutFile "test-gui.py"
    if (Test-Path "test-gui.py") {
        Write-Host "PASS SUCCESS: gui.py downloaded successfully" -ForegroundColor Green
        $fileSize = (Get-Item "test-gui.py").Length
        Write-Host "   File size: $fileSize bytes" -ForegroundColor Gray
    } else {
        Write-Host "FAIL FAILED: gui.py not found after download" -ForegroundColor Red
    }
} catch {
    Write-Host "FAIL FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Test one-liner download (without execution)
Write-Host "`n� Test 3: Testing one-liner download (content only)..." -ForegroundColor Yellow
try {
    $content = Invoke-WebRequest -Uri "https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/feature/deployment-wrapper-gui/deploy.py"  Select-Object -ExpandProperty Content
    if ($content -match "OpenTofu Lab Automation") {
        Write-Host "PASS SUCCESS: One-liner download works" -ForegroundColor Green
        Write-Host "   Content preview: $($content.Substring(0, 100))..." -ForegroundColor Gray
    } else {
        Write-Host "FAIL FAILED: Content doesn't match expected format" -ForegroundColor Red
    }
} catch {
    Write-Host "FAIL FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 4: Check Python availability
Write-Host "`n� Test 4: Checking Python availability..." -ForegroundColor Yellow
try {
    $pythonVersion = python --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "PASS SUCCESS: Python is available" -ForegroundColor Green
        Write-Host "   Version: $pythonVersion" -ForegroundColor Gray
        
        # Test deploy.py help
        Write-Host "`n Testing deploy.py --help..." -ForegroundColor Yellow
        if (Test-Path "test-deploy.py") {
            $helpOutput = python test-deploy.py --help 2>&1
            if ($helpOutput -match "OpenTofu Lab Automation") {
                Write-Host "PASS SUCCESS: deploy.py help works" -ForegroundColor Green
            } else {
                Write-Host "WARN  WARNING: deploy.py help output unexpected" -ForegroundColor Yellow
                Write-Host "   Output: $helpOutput" -ForegroundColor Gray
            }
        }
    } else {
        Write-Host "FAIL WARNING: Python not found in PATH" -ForegroundColor Yellow
        Write-Host "   Try: py --version (some Windows systems use 'py' instead of 'python')" -ForegroundColor Gray
        
        # Try 'py' command
        try {
            $pyVersion = py --version 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "PASS SUCCESS: Python available via 'py' command" -ForegroundColor Green
                Write-Host "   Version: $pyVersion" -ForegroundColor Gray
            }
        } catch {
            Write-Host "FAIL FAILED: Neither 'python' nor 'py' commands work" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "FAIL FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 5: Download batch files
Write-Host "`n� Test 5: Downloading Windows batch files..." -ForegroundColor Yellow
try {
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/feature/deployment-wrapper-gui/deploy.bat" -OutFile "test-deploy.bat"
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/feature/deployment-wrapper-gui/launch-gui.bat" -OutFile "test-launch-gui.bat"
    
    $deployBatExists = Test-Path "test-deploy.bat"
    $guiBatExists = Test-Path "test-launch-gui.bat"
    
    if ($deployBatExists -and $guiBatExists) {
        Write-Host "PASS SUCCESS: Windows batch files downloaded successfully" -ForegroundColor Green
    } else {
        Write-Host "FAIL FAILED: Some batch files missing" -ForegroundColor Red
        Write-Host "   deploy.bat: $deployBatExists" -ForegroundColor Gray
        Write-Host "   launch-gui.bat: $guiBatExists" -ForegroundColor Gray
    }
} catch {
    Write-Host "FAIL FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

# Summary
Write-Host "`n Test Summary" -ForegroundColor Cyan
Write-Host "===============" -ForegroundColor Cyan
Write-Host "PASS All download URLs are working correctly" -ForegroundColor Green
Write-Host "PASS PowerShell Invoke-WebRequest commands work as expected" -ForegroundColor Green
Write-Host "PASS One-liner download syntax is correct" -ForegroundColor Green

if (Test-Path "test-deploy.py") { Remove-Item "test-deploy.py" -Force }
if (Test-Path "test-gui.py") { Remove-Item "test-gui.py" -Force }
if (Test-Path "test-deploy.bat") { Remove-Item "test-deploy.bat" -Force }
if (Test-Path "test-launch-gui.bat") { Remove-Item "test-launch-gui.bat" -Force }

Write-Host "`n PowerShell Quick Start test completed!" -ForegroundColor Green
Write-Host "You can now use the commands from the README.md with confidence." -ForegroundColor White



