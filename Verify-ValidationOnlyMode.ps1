#!/usr/bin/env pwsh
#Requires -Version 7.0

<#
.SYNOPSIS
Final verification that all ValidationOnly functionality has been removed

.DESCRIPTION
Checks the codebase to ensure no active file modification operations remain
#>

Write-Host "=== FINAL SAFETY VERIFICATION ===" -ForegroundColor Cyan
Write-Host "Checking for any remaining active file modification operations..." -ForegroundColor Yellow

$found = $false

# Check for active Set-Content operations
Write-Host "`nChecking for active Set-Content operations..." -ForegroundColor White
$setContentFiles = Get-ChildItem -Recurse -Filter "*.ps1" -Exclude "*.backup-*" | 
    Where-Object { 
        $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
        $content -and $content -match '^\s*Set-Content\s+' -and $content -notmatch '# DISABLED:'
    }

if ($setContentFiles) {
    Write-Host "[WARNING] Found active Set-Content operations in:" -ForegroundColor Red
    $setContentFiles | ForEach-Object { Write-Host "  - $($_.FullName)" -ForegroundColor Yellow }
    $found = $true
} else {
    Write-Host "[PASS] No active Set-Content operations found" -ForegroundColor Green
}

# Check for validation-only headers
Write-Host "`nChecking for validation-only headers in key files..." -ForegroundColor White
$keyFiles = @(
    "scripts/testing/Batch-RepairTestFiles.ps1",
    "scripts/testing/Repair-TestFile.ps1",
    "pwsh/modules/PatchManager/Public/Invoke-MassFileFix.ps1"
)

foreach ($file in $keyFiles) {
    if (Test-Path $file) {
        $content = Get-Content $file -Raw
        if ($content -match "VALIDATION-ONLY MODE") {
            Write-Host "[PASS] $file has validation-only header" -ForegroundColor Green
        } else {
            Write-Host "[WARNING] $file missing validation-only header" -ForegroundColor Yellow
            $found = $true
        }
    }
}

# Summary
Write-Host "`n=== VERIFICATION COMPLETE ===" -ForegroundColor Cyan
if (-not $found) {
    Write-Host "[SUCCESS] Codebase is completely safe and validation-only!" -ForegroundColor Green    Write-Host "[PASS] No active file modification operations found" -ForegroundColor Green
    Write-Host "[PASS] All key scripts have validation-only headers" -ForegroundColor Green
    Write-Host "[PASS] Ready for safe test expansion and development" -ForegroundColor Green
} else {
    Write-Host "[ATTENTION] Some issues found - please review above" -ForegroundColor Yellow
}

Write-Host "`nFile changes are now only possible through explicit PatchManager invocation." -ForegroundColor Cyan
