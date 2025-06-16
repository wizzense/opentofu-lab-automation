#!/usr/bin/env pwsh
#Requires -Version 7.0

<#
.SYNOPSIS
    Validates that all module import issues have been resolved by DevEnvironment setup
.DESCRIPTION
    This script tests the comprehensive module import resolution to ensure:
    - All PowerShell syntax errors are fixed
    - All modules import successfully 
    - Environment variables are set correctly
    - Key functions are available
    - Development environment is fully functional
#>

Write-Host "=== TESTING MODULE IMPORT RESOLUTION ===" -ForegroundColor Cyan

$testResults = @{
    SyntaxTests = @()
    ModuleTests = @()
    FunctionTests = @()
    EnvironmentTests = @()
    Overall = $true
}

# Test 1: Validate PowerShell syntax in all key files
Write-Host "`n1️⃣ Testing PowerShell syntax..." -ForegroundColor Yellow

$criticalFiles = @(
    "pwsh/modules/LabRunner/Logger.ps1",
    "pwsh/modules/LabRunner/Get-Platform.ps1", 
    "pwsh/modules/LabRunner/Network.ps1",
    "pwsh/modules/LabRunner/InvokeOpenTofuInstaller.ps1",
    "pwsh/modules/LabRunner/Format-Config.ps1",
    "pwsh/modules/LabRunner/Expand-All.ps1",
    "pwsh/modules/LabRunner/Menu.ps1",
    "pwsh/modules/LabRunner/Download-Archive.ps1",
    "pwsh/modules/LabRunner/Public/Invoke-ParallelLabRunner.ps1",
    "pwsh/modules/LabRunner/LabRunner.psm1"
)

foreach ($file in $criticalFiles) {
    if (Test-Path $file) {
        try {
            $tokens = $errors = $null
            [System.Management.Automation.Language.Parser]::ParseFile($file, [ref]$tokens, [ref]$errors) | Out-Null
            
            if ($errors.Count -eq 0) {
                Write-Host "  ✅ $($file.Split('/')[-1]): Syntax OK" -ForegroundColor Green
                $testResults.SyntaxTests += @{ File = $file; Status = "PASS" }
            } else {
                Write-Host "  ❌ $($file.Split('/')[-1]): $($errors.Count) syntax errors" -ForegroundColor Red
                $testResults.SyntaxTests += @{ File = $file; Status = "FAIL"; Errors = $errors.Count }
                $testResults.Overall = $false
            }
        } catch {
            Write-Host "  ❌ $($file.Split('/')[-1]): Parse error - $($_.Exception.Message)" -ForegroundColor Red
            $testResults.SyntaxTests += @{ File = $file; Status = "ERROR"; Message = $_.Exception.Message }
            $testResults.Overall = $false
        }
    } else {
        Write-Host "  ⚠️ $($file.Split('/')[-1]): File not found" -ForegroundColor Yellow
        $testResults.SyntaxTests += @{ File = $file; Status = "MISSING" }
    }
}

# Test 2: Validate module imports
Write-Host "`n2️⃣ Testing module imports..." -ForegroundColor Yellow

$modules = @("Logging", "LabRunner", "PatchManager", "DevEnvironment", "BackupManager")

foreach ($module in $modules) {
    $modulePath = "pwsh/modules/$module"
    if (Test-Path $modulePath) {
        try {
            # Remove if already loaded
            if (Get-Module $module) {
                Remove-Module $module -Force
            }
            
            Import-Module "./$modulePath" -Force -ErrorAction Stop
            Write-Host "  ✅ $module`: Import successful" -ForegroundColor Green
            $testResults.ModuleTests += @{ Module = $module; Status = "PASS" }
        } catch {
            Write-Host "  ❌ $module`: Import failed - $($_.Exception.Message)" -ForegroundColor Red
            $testResults.ModuleTests += @{ Module = $module; Status = "FAIL"; Message = $_.Exception.Message }
            $testResults.Overall = $false
        }
    } else {
        Write-Host "  ⚠️ $module`: Module not found" -ForegroundColor Yellow
        $testResults.ModuleTests += @{ Module = $module; Status = "MISSING" }
    }
}

# Test 3: Validate key functions are available
Write-Host "`n3️⃣ Testing key functions..." -ForegroundColor Yellow

$keyFunctions = @{
    "Write-CustomLog" = "Logging"
    "Get-Platform" = "LabRunner"
    "Invoke-LabStep" = "LabRunner"
    "Format-Config" = "LabRunner"
    "Invoke-ParallelLabRunner" = "LabRunner"
    "Invoke-GitControlledPatch" = "PatchManager"
    "Initialize-DevelopmentEnvironment" = "DevEnvironment"
    "Resolve-ModuleImportIssues" = "DevEnvironment"
}

foreach ($func in $keyFunctions.Keys) {
    $module = $keyFunctions[$func]
    if (Get-Command $func -ErrorAction SilentlyContinue) {
        Write-Host "  ✅ $func ($module): Available" -ForegroundColor Green
        $testResults.FunctionTests += @{ Function = $func; Module = $module; Status = "PASS" }
    } else {
        Write-Host "  ❌ $func ($module): Not available" -ForegroundColor Red
        $testResults.FunctionTests += @{ Function = $func; Module = $module; Status = "FAIL" }
        $testResults.Overall = $false
    }
}

# Test 4: Validate environment setup
Write-Host "`n4️⃣ Testing environment variables..." -ForegroundColor Yellow

$requiredEnvVars = @("PROJECT_ROOT", "PWSH_MODULES_PATH")

foreach ($envVar in $requiredEnvVars) {
    $value = [Environment]::GetEnvironmentVariable($envVar)
    if ($value) {
        Write-Host "  ✅ $envVar`: $value" -ForegroundColor Green
        $testResults.EnvironmentTests += @{ Variable = $envVar; Status = "PASS"; Value = $value }
    } else {
        Write-Host "  ❌ $envVar`: Not set" -ForegroundColor Red
        $testResults.EnvironmentTests += @{ Variable = $envVar; Status = "FAIL" }
        $testResults.Overall = $false
    }
}

# Test 5: Run DevEnvironment initialization 
Write-Host "`n5️⃣ Testing DevEnvironment initialization..." -ForegroundColor Yellow

try {
    if (Get-Command Resolve-ModuleImportIssues -ErrorAction SilentlyContinue) {
        Write-Host "  ✅ Resolve-ModuleImportIssues function available" -ForegroundColor Green
        Write-Host "  🚀 Running module import resolution in WhatIf mode..." -ForegroundColor Cyan
        
        Resolve-ModuleImportIssues -WhatIf -ErrorAction Stop
        Write-Host "  ✅ Resolve-ModuleImportIssues executed successfully" -ForegroundColor Green
        
    } else {
        Write-Host "  ❌ Resolve-ModuleImportIssues function not available" -ForegroundColor Red
        $testResults.Overall = $false
    }
} catch {
    Write-Host "  ❌ DevEnvironment test failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults.Overall = $false
}

# Summary
Write-Host "`n=== TEST RESULTS SUMMARY ===" -ForegroundColor Cyan

$syntaxPassed = ($testResults.SyntaxTests | Where-Object { $_.Status -eq "PASS" }).Count
$syntaxTotal = $testResults.SyntaxTests.Count
Write-Host "Syntax Tests: $syntaxPassed/$syntaxTotal passed" -ForegroundColor $(if($syntaxPassed -eq $syntaxTotal){"Green"}else{"Yellow"})

$modulesPassed = ($testResults.ModuleTests | Where-Object { $_.Status -eq "PASS" }).Count
$modulesTotal = $testResults.ModuleTests.Count  
Write-Host "Module Tests: $modulesPassed/$modulesTotal passed" -ForegroundColor $(if($modulesPassed -eq $modulesTotal){"Green"}else{"Yellow"})

$functionsPassed = ($testResults.FunctionTests | Where-Object { $_.Status -eq "PASS" }).Count
$functionsTotal = $testResults.FunctionTests.Count
Write-Host "Function Tests: $functionsPassed/$functionsTotal passed" -ForegroundColor $(if($functionsPassed -eq $functionsTotal){"Green"}else{"Yellow"})

$envPassed = ($testResults.EnvironmentTests | Where-Object { $_.Status -eq "PASS" }).Count
$envTotal = $testResults.EnvironmentTests.Count
Write-Host "Environment Tests: $envPassed/$envTotal passed" -ForegroundColor $(if($envPassed -eq $envTotal){"Green"}else{"Yellow"})

if ($testResults.Overall) {
    Write-Host "`n🎉 ALL TESTS PASSED! Module import issues have been resolved." -ForegroundColor Green
    Write-Host "✅ DevEnvironment setup is working correctly" -ForegroundColor Green
    Write-Host "✅ All syntax errors have been fixed" -ForegroundColor Green
    Write-Host "✅ All modules import successfully" -ForegroundColor Green
    Write-Host "✅ All key functions are available" -ForegroundColor Green
} else {
    Write-Host "`n⚠️ SOME TESTS FAILED! Issues remain to be resolved." -ForegroundColor Yellow
    Write-Host "❌ Check the failed tests above for details" -ForegroundColor Red
}

Write-Host "`n🔧 To run full DevEnvironment setup:" -ForegroundColor Cyan
Write-Host "   Initialize-DevelopmentEnvironment -Force" -ForegroundColor White

Write-Host "`n📋 Test completed: $(Get-Date)" -ForegroundColor Gray
