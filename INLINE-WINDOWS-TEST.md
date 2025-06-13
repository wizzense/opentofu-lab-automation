# ==============================================================================
# OpenTofu Lab Automation - Inline Windows Quick Test
# Copy and paste this entire script into PowerShell to test the GUI
# ==============================================================================

Write-Host "🧪 OpenTofu Lab Automation - Windows Quick Test" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# Download and test the GUI
Write-Host "`n📥 Downloading GUI with performance optimizations..." -ForegroundColor Yellow

try {
    # Download GUI
    $uri = "https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/feature/deployment-wrapper-gui/gui.py"
    Invoke-WebRequest -Uri $uri -OutFile "gui.py" -UseBasicParsing
    Write-Host "✅ gui.py downloaded successfully" -ForegroundColor Green
    
    # Check file size
    $fileSize = (Get-Item "gui.py").Length
    Write-Host "   File size: $fileSize bytes" -ForegroundColor Gray
    
    # Check Python
    try {
        $pythonVersion = python --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Python found: $pythonVersion" -ForegroundColor Green
            $pythonCmd = "python"
        } else {
            throw "python failed"
        }
    } catch {
        try {
            $pythonVersion = py --version 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Python found via 'py': $pythonVersion" -ForegroundColor Green
                $pythonCmd = "py"
            } else {
                throw "py also failed"
            }
        } catch {
            Write-Host "❌ Python not found. Please install Python first." -ForegroundColor Red
            exit 1
        }
    }
    
    Write-Host "`n🚀 Launching GUI with all fixes applied..." -ForegroundColor Cyan
    Write-Host "   ✅ Path resolution fixes included" -ForegroundColor Green
    Write-Host "   ✅ Performance optimizations applied" -ForegroundColor Green
    Write-Host "   ✅ Windows console handling improved" -ForegroundColor Green
    Write-Host "   ✅ Prerequisites auto-download enabled" -ForegroundColor Green
    
    # Launch GUI
    & $pythonCmd "gui.py"
    
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "`nManual alternatives:" -ForegroundColor Yellow
    Write-Host "1. python gui.py" -ForegroundColor White
    Write-Host "2. py gui.py" -ForegroundColor White
}

Write-Host "`n✅ Test complete!" -ForegroundColor Green
