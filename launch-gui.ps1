# OpenTofu Lab Automation - PowerShell GUI Launcher
# This script provides a cleaner way to launch the GUI on Windows

param(
    [switch]$Download,
    [switch]$Quiet
)








if (-not $Quiet) {
    Write-Host "🚀 OpenTofu Lab Automation - GUI Launcher" -ForegroundColor Cyan
    Write-Host "===========================================" -ForegroundColor Cyan
}

# Check if Python is available
try {
    $pythonVersion = python --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Python command failed"
    }
    if (-not $Quiet) {
        Write-Host "✅ Python found: $pythonVersion" -ForegroundColor Green
    }
    $pythonCmd = "python"
} catch {
    try {
        $pythonVersion = py --version 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Py command failed"
        }
        if (-not $Quiet) {
            Write-Host "✅ Python found via 'py': $pythonVersion" -ForegroundColor Green
        }
        $pythonCmd = "py"
    } catch {
        Write-Host "❌ ERROR: Python is not installed or not in PATH" -ForegroundColor Red
        Write-Host "Please install Python from python.org or Microsoft Store" -ForegroundColor Yellow
        exit 1
    }
}

# Check if gui.py exists
$guiPath = Join-Path $PSScriptRoot "gui.py"
if (-not (Test-Path $guiPath) -or $Download) {
    if (-not $Quiet) {
        Write-Host "📥 Downloading gui.py from GitHub..." -ForegroundColor Yellow
    }
    
    try {
        $uri = "https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/feature/deployment-wrapper-gui/gui.py"
        Invoke-WebRequest -Uri $uri -OutFile $guiPath -UseBasicParsing
        
        if (Test-Path $guiPath) {
            if (-not $Quiet) {
                Write-Host "✅ gui.py downloaded successfully" -ForegroundColor Green
            }
        } else {
            throw "File not created"
        }
    } catch {
        Write-Host "❌ Failed to download gui.py: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# Launch GUI without showing PowerShell console
if (-not $Quiet) {
    Write-Host "🎮 Launching GUI..." -ForegroundColor Cyan
}

try {
    # Try the cleaner method first (hide console)
    if (-not $Quiet) {
        Write-Host "Attempting optimized launch (no console window)..." -ForegroundColor Gray
    }
    
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $pythonCmd
    $psi.Arguments = "`"$guiPath`""
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.WorkingDirectory = $PSScriptRoot
    
    $process = [System.Diagnostics.Process]::Start($psi)
    
    if ($process -and -not $process.HasExited) {
        if (-not $Quiet) {
            Write-Host "✅ GUI launched successfully (PID: $($process.Id))" -ForegroundColor Green
            Write-Host "GUI is running. You can close this PowerShell window." -ForegroundColor Gray
        }
        
        # Don't exit immediately - let the process start properly
        Start-Sleep -Seconds 3
        
        # Check if process is still running
        if (-not $process.HasExited) {
            if (-not $Quiet) {
                Write-Host "✅ GUI confirmed running. Launch successful!" -ForegroundColor Green
            }
        } else {
            throw "Process exited unexpectedly"
        }
    } else {
        throw "Failed to start process"
    }
    
} catch {
    if (-not $Quiet) {
        Write-Host "⚠️  Optimized launch failed: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "Trying standard launch method..." -ForegroundColor Yellow
    }
    
    # Fallback: launch with visible console (more reliable)
    try {
        if (-not $Quiet) {
            Write-Host "Launching with standard method..." -ForegroundColor Gray
        }
        
        # Use Start-Process for better reliability
        $processParams = @{
            FilePath = $pythonCmd
            ArgumentList = $guiPath
            WorkingDirectory = $PSScriptRoot
            PassThru = $true
        }
        
        $process = Start-Process @processParams
        
        if (-not $Quiet) {
            Write-Host "✅ GUI launched successfully with standard method (PID: $($process.Id))" -ForegroundColor Green
            Write-Host "The GUI window should appear shortly." -ForegroundColor Gray
        }
        
    } catch {
        Write-Host "❌ All launch methods failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "`nManual launch options:" -ForegroundColor Yellow
        Write-Host "  python `"$guiPath`"" -ForegroundColor White
        Write-Host "  py `"$guiPath`"" -ForegroundColor White
        exit 1
    }
}



