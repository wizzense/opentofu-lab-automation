#!/usr/bin/env pwsh
# Ensure environment variables are set for admin-friendly module discovery
if (-not $env:PWSH_MODULES_PATH) {
    $env:PWSH_MODULES_PATH = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "src/pwsh/modules"
}
<#
.SYNOPSIS
    Tests admin-friendly module discovery after environment setup

.DESCRIPTION
    Verifies that all project modules can be imported by name without hardcoded paths,
    demonstrating that the admin-friendly environment is properly configured.
#>

Write-Host "=== Module Discovery Test ===" -ForegroundColor Cyan
Write-Host ""

# Show current environment
Write-Host "Current Environment:" -ForegroundColor Yellow
Write-Host "  PROJECT_ROOT: $env:PROJECT_ROOT"
Write-Host "  PWSH_MODULES_PATH: $env:PWSH_MODULES_PATH"
Write-Host ""

# Show PSModulePath
Write-Host "PSModulePath entries:" -ForegroundColor Yellow
$env:PSModulePath.Split(';') | ForEach-Object { 
    if ($_.Trim()) {
        Write-Host "  $_"
    }
}
Write-Host ""

# Test project modules by name
Write-Host "Testing module import by name:" -ForegroundColor Yellow
$projectModules = @("Logging", "LabRunner", "PatchManager", "TestingFramework", "ParallelExecution")
$results = @{}

foreach ($module in $projectModules) {
    try {
        # Remove if already loaded
        if (Get-Module $module) {
            Remove-Module $module -Force
        }
        
        Import-Module $module -Force -ErrorAction Stop
        Write-Host "  [SYMBOL] $module - SUCCESS" -ForegroundColor Green
        $results[$module] = "SUCCESS"
        
        # Test a function if available
        if ($module -eq "Logging") {
            $command = Get-Command Write-CustomLog -ErrorAction SilentlyContinue
            if ($command) {
                Write-Host "    Function available: Write-CustomLog" -ForegroundColor DarkGreen
            }
        }
        
    }
    catch {
        Write-Host "  [SYMBOL] $module - FAILED: $($_.Exception.Message)" -ForegroundColor Red
        $results[$module] = "FAILED"
        
        # Try fallback import
        $fallbackPath = "src/pwsh/modules/$module"
        if (Test-Path $fallbackPath) {
            try {
                Import-Module $fallbackPath -Force
                Write-Host "    Fallback import successful" -ForegroundColor Yellow
                $results[$module] = "FALLBACK SUCCESS"
            }
            catch {
                Write-Host "    Fallback also failed" -ForegroundColor DarkRed
            }
        }
    }
}

# Summary
Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
$successful = ($results.Values | Where-Object { $_ -eq "SUCCESS" }).Count
$total = $results.Count
Write-Host "Modules importable by name: $successful/$total"

if ($successful -eq $total) {
    Write-Host "[SYMBOL] Admin-friendly module discovery is working!" -ForegroundColor Green
} else {
    Write-Host "[SYMBOL] Module discovery needs attention" -ForegroundColor Yellow
    Write-Host "Solutions:" -ForegroundColor Yellow
    Write-Host "  1. Restart PowerShell to pick up environment changes"
    Write-Host "  2. Re-run ./Setup-Environment.ps1"
    Write-Host "  3. Check that modules are in src/pwsh/modules/"
}

Write-Host ""
Write-Host "Test complete" -ForegroundColor Cyan

