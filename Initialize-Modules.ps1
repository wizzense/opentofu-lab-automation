#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Quick module initialization for OpenTofu Lab Automation

.DESCRIPTION
    Simple script that admins can run to initialize all project modules
    without having to deal with paths or complex setup. Just run once
    and everything works by module name.

.EXAMPLE
    .\Initialize-Modules.ps1
    
.EXAMPLE
    . .\Initialize-Modules.ps1
    Source the script to set up environment in current session
#>

Write-Host "=== OpenTofu Lab Automation - Module Initialization ===" -ForegroundColor Cyan

# Set up project environment variables
$projectRoot = $PSScriptRoot
$env:PROJECT_ROOT = $projectRoot
$env:PWSH_MODULES_PATH = Join-Path $projectRoot "src/pwsh/modules"

# Add project modules to PSModulePath for this session
$currentPSModulePath = $env:PSModulePath
if ($currentPSModulePath -notlike "*$env:PWSH_MODULES_PATH*") {
    $separator = if ($IsWindows) { ';' } else { ':' }
    $env:PSModulePath = "$env:PWSH_MODULES_PATH$separator$currentPSModulePath"
    Write-Host "[SYMBOL] Added project modules to PSModulePath" -ForegroundColor Green
}

# Test that modules can be imported by name
Write-Host "`nTesting module imports..." -ForegroundColor Yellow
$projectModules = @("Logging", "LabRunner", "PatchManager", "ParallelExecution", "DevEnvironment")
$successful = 0

foreach ($module in $projectModules) {
    try {
        if (Get-Module $module) {
            Remove-Module $module -Force -ErrorAction SilentlyContinue
        }
        Import-Module $module -Force -ErrorAction Stop
        Write-Host "  [SYMBOL] $module" -ForegroundColor Green
        $successful++
    }
    catch {
        Write-Host "  [SYMBOL] $module - $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n=== Results ===" -ForegroundColor Cyan
Write-Host "Modules available: $successful/$($projectModules.Count)" -ForegroundColor White

if ($successful -eq $projectModules.Count) {
    Write-Host "[SYMBOL] All modules loaded successfully!" -ForegroundColor Green
    Write-Host "[SYMBOL] You can now use Import-Module <ModuleName> anywhere" -ForegroundColor Green
    
    # Show available functions
    Write-Host "`nKey functions now available:" -ForegroundColor Yellow
    if (Get-Command Write-CustomLog -ErrorAction SilentlyContinue) {
        Write-Host "  - Write-CustomLog (from Logging)" -ForegroundColor Gray
    }
    if (Get-Command Remove-ProjectEmojis -ErrorAction SilentlyContinue) {
        Write-Host "  - Remove-ProjectEmojis (from DevEnvironment)" -ForegroundColor Gray
    }
    if (Get-Command Invoke-ParallelTaskExecution -ErrorAction SilentlyContinue) {
        Write-Host "  - Invoke-ParallelTaskExecution (from ParallelExecution)" -ForegroundColor Gray
    }
} else {
    Write-Host "[SYMBOL] Some modules failed to load. Run Setup-Environment.ps1 first" -ForegroundColor Yellow
}

Write-Host "`nEnvironment ready for emoji removal!" -ForegroundColor Cyan

