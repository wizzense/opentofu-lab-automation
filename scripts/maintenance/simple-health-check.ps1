#!/usr/bin/env pwsh
# Simple health check script for base64 encoding test

param(
    string$Mode = 'Full',
    switch$AutoFix
)

$ErrorActionPreference = "Stop"

function Write-HealthLog {
    param(string$Message, string$Level = "INFO")
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "$timestamp $Level $Message" -ForegroundColor Green
}

function Get-ProjectRoot {
    if ($IsWindows -or $env:OS -eq "Windows_NT") {
        return "c:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation"
    } else {
        return "/workspaces/opentofu-lab-automation"
    }
}

# Main execution
$ProjectRoot = Get-ProjectRoot
Write-HealthLog "Starting infrastructure health check in mode: $Mode" "HEALTH"
Write-HealthLog "Project root: $ProjectRoot" "INFO"
Write-HealthLog "AutoFix enabled: $($AutoFix.IsPresent)" "INFO"

try {
    # Simple health check
    $psFiles = Get-ChildItem -Path $ProjectRoot -Recurse -Include "*.ps1" -ErrorAction SilentlyContinue  Measure-Object
    Write-HealthLog "Found $($psFiles.Count) PowerShell files" "SUCCESS"
    
    # Check if key directories exist
    $keyDirs = @("scripts", "pwsh", "tests", ".github")
    foreach ($dir in $keyDirs) {
        $dirPath = Join-Path $ProjectRoot $dir
        if (Test-Path $dirPath) {
            Write-HealthLog "Directory exists: $dir" "SUCCESS"
        } else {
            Write-HealthLog "Directory missing: $dir" "WARNING"
        }
    }
    
    Write-HealthLog "Health check completed successfully" "SUCCESS"
    return @{
        Status = "Success"
        Files = $psFiles.Count
        Mode = $Mode
        AutoFix = $AutoFix.IsPresent
    }
}
catch {
    Write-HealthLog "Health check failed: $($_.Exception.Message)" "ERROR"
    throw
}
