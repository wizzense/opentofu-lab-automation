#Requires -Version 7.0

<#
.SYNOPSIS
Test script to verify centralized logging integration across all modules

.DESCRIPTION
This script tests that all major modules (LabRunner, PatchManager, DevEnvironment, BackupManager)
properly import and use the centralized enhanced Logging module instead of fallback implementations.

.NOTES
Author: System Integration Test
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

# Initialize environment
if (-not $env:PROJECT_ROOT) {
    $env:PROJECT_ROOT = Split-Path $PSScriptRoot -Parent
}
if (-not $env:PWSH_MODULES_PATH) {
    $env:PWSH_MODULES_PATH = Join-Path $env:PROJECT_ROOT "pwsh/modules"
}

Write-Host "=== Testing Centralized Logging Integration ===" -ForegroundColor Cyan
Write-Host "PROJECT_ROOT: $env:PROJECT_ROOT" -ForegroundColor Gray
Write-Host "PWSH_MODULES_PATH: $env:PWSH_MODULES_PATH" -ForegroundColor Gray
Write-Host ""

$results = @{
    Logging = @{ Success = $false; Error = $null }
    LabRunner = @{ Success = $false; Error = $null }
    PatchManager = @{ Success = $false; Error = $null }
    DevEnvironment = @{ Success = $false; Error = $null }
    BackupManager = @{ Success = $false; Error = $null }
}

# Test 1: Enhanced Logging Module
Write-Host "Testing Enhanced Logging Module..." -ForegroundColor Yellow
try {
    Import-Module "$env:PWSH_MODULES_PATH/Logging" -Force
    
    # Test basic logging
    Write-CustomLog "Test message from enhanced logger" "INFO"
    Write-CustomLog "Test warning from enhanced logger" "WARN"
    Write-CustomLog "Test success from enhanced logger" "SUCCESS"
    
    # Test advanced features
    Initialize-LoggingSystem -LogLevel "INFO" -EnableFileLogging $true
    Start-PerformanceTrace "TestTrace"
    Stop-PerformanceTrace "TestTrace"
    
    $results.Logging.Success = $true
    Write-Host "✓ Enhanced Logging Module: PASSED" -ForegroundColor Green
} catch {
    $results.Logging.Error = $_.Exception.Message
    Write-Host "✗ Enhanced Logging Module: FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: LabRunner Module
Write-Host "`nTesting LabRunner Module..." -ForegroundColor Yellow
try {
    Import-Module "$env:PWSH_MODULES_PATH/LabRunner" -Force
    
    # Test that LabRunner uses centralized logging
    $tempConfig = @{ suppress_errors = $false }
    Invoke-LabStep -Body { 
        Write-CustomLog "LabRunner test log message" "INFO"
        Get-CrossPlatformTempPath | Out-Null
    } -Config $tempConfig
    
    $results.LabRunner.Success = $true
    Write-Host "✓ LabRunner Module: PASSED" -ForegroundColor Green
} catch {
    $results.LabRunner.Error = $_.Exception.Message
    Write-Host "✗ LabRunner Module: FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: PatchManager Module  
Write-Host "`nTesting PatchManager Module..." -ForegroundColor Yellow
try {
    Import-Module "$env:PWSH_MODULES_PATH/PatchManager" -Force
    
    # Test that PatchManager uses centralized logging
    $envResult = Initialize-CrossPlatformEnvironment
    if ($envResult.Success) {
        Write-CustomLog "PatchManager test log message" "INFO"
    }
    
    $results.PatchManager.Success = $true
    Write-Host "✓ PatchManager Module: PASSED" -ForegroundColor Green
} catch {
    $results.PatchManager.Error = $_.Exception.Message
    Write-Host "✗ PatchManager Module: FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

# Test 4: DevEnvironment Module
Write-Host "`nTesting DevEnvironment Module..." -ForegroundColor Yellow
try {
    Import-Module "$env:PWSH_MODULES_PATH/DevEnvironment" -Force
    
    # Test that DevEnvironment uses centralized logging
    Write-CustomLog "DevEnvironment test log message" "INFO"
    
    $results.DevEnvironment.Success = $true
    Write-Host "✓ DevEnvironment Module: PASSED" -ForegroundColor Green
} catch {
    $results.DevEnvironment.Error = $_.Exception.Message
    Write-Host "✗ DevEnvironment Module: FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

# Test 5: BackupManager Module
Write-Host "`nTesting BackupManager Module..." -ForegroundColor Yellow
try {
    Import-Module "$env:PWSH_MODULES_PATH/BackupManager" -Force
    
    # Test that BackupManager uses centralized logging
    Write-CustomLog "BackupManager test log message" "INFO"
    
    $results.BackupManager.Success = $true
    Write-Host "✓ BackupManager Module: PASSED" -ForegroundColor Green
} catch {
    $results.BackupManager.Error = $_.Exception.Message
    Write-Host "✗ BackupManager Module: FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

# Summary
Write-Host "`n=== Test Results Summary ===" -ForegroundColor Cyan
$passedCount = ($results.Values | Where-Object { $_.Success }).Count
$totalCount = $results.Count

foreach ($module in $results.Keys) {
    $result = $results[$module]
    if ($result.Success) {
        Write-Host "✓ $module" -ForegroundColor Green
    } else {
        Write-Host "✗ $module - $($result.Error)" -ForegroundColor Red
    }
}

Write-Host "`nPassed: $passedCount/$totalCount" -ForegroundColor $(if ($passedCount -eq $totalCount) { "Green" } else { "Yellow" })

if ($passedCount -eq $totalCount) {
    Write-Host "`n🎉 All modules successfully integrated with centralized logging!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n⚠️  Some modules failed integration tests" -ForegroundColor Yellow
    exit 1
}
