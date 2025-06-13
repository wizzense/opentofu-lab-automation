# Final Automation Test Runner
# This script runs all fixes and tests for the OpenTofu Lab Automation project
# filepath: run-final-validation.ps1

[CmdletBinding()]
param(
    [switch]$SkipFixes,
    [switch]$SkipTests,
    [switch]$Detailed
)





$ErrorActionPreference = 'Stop'
$startTime = Get-Date

Write-Host "🚀 OPENTOFU LAB AUTOMATION - FINAL VALIDATION" -ForegroundColor Cyan
Write-Host "=" * 50 -ForegroundColor Cyan

# Step 1: Run all fixes
if (-not $SkipFixes) {
    Write-Host "`n📋 STEP 1: RUNNING ALL FIXES" -ForegroundColor Yellow
    
    Write-Host "`n🔧 Running comprehensive auto-fix" -ForegroundColor Green
    if (Test-Path "auto-fix.ps1") {
        & ./auto-fix.ps1
    } elseif (Test-Path "tools/Validate-PowerShellScripts.ps1") {
        & ./tools/Validate-PowerShellScripts.ps1 -Path . -AutoFix
    }
    
    Write-Host "`n🔧 Running bootstrap script fixes" -ForegroundColor Green
    & ./fix-bootstrap-script.ps1
    
    Write-Host "`n🔧 Running PowerShell syntax fixes" -ForegroundColor Green
    & ./fix-powershell-syntax.ps1
    
    Write-Host "`n🔧 Running specific test syntax fixes" -ForegroundColor Green
    & ./simple-fix-test-syntax.ps1
    
    Write-Host "`n✅ All fixes completed" -ForegroundColor Green
}

# Step 2: Run all tests
if (-not $SkipTests) {
    Write-Host "`n📋 STEP 2: RUNNING ALL TESTS" -ForegroundColor Yellow
    
    if ($Detailed) {
        & ./run-comprehensive-tests.ps1 
    } else {
        & ./run-comprehensive-tests.ps1 -SkipLint
    }
}

$duration = (Get-Date) - $startTime
Write-Host "`n🏁 VALIDATION COMPLETE" -ForegroundColor Cyan
Write-Host "Duration: $($duration.ToString('hh\:mm\:ss'))" -ForegroundColor Cyan
Write-Host "=" * 50 -ForegroundColor Cyan


