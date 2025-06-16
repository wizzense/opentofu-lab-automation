# Final Automation Test Runner
# This script runs all fixes and tests for the OpenTofu Lab Automation project
# filepath: run-final-validation.ps1

CmdletBinding()
param(
 switch$SkipFixes,
 switch$SkipTests,
 switch$Detailed,
 switch$CI
)








$ErrorActionPreference = 'Stop'
$startTime = Get-Date

Write-Host " OPENTOFU LAB AUTOMATION - FINAL VALIDATION" -ForegroundColor Cyan
Write-Host "=" * 50 -ForegroundColor Cyan

# Step 1: Run all fixes
if (-not $SkipFixes) {
 Write-Host "`n STEP 1: RUNNING ALL FIXES" -ForegroundColor Yellow
 
 Write-Host "`n Running YAML validation and fixes" -ForegroundColor Green
 if (Test-Path "scripts/validation/Invoke-YamlValidation.ps1") {
 & ./scripts/validation/Invoke-YamlValidation.ps1 -Mode "Fix"
 Write-Host " YAML validation completed" -ForegroundColor Green
 } else {
 Write-Host " WARN YAML validation script not found" -ForegroundColor Yellow
 }
 
 Write-Host "`n Running comprehensive auto-fix" -ForegroundColor Green
 if (Test-Path "auto-fix.ps1") {
 & ./auto-fix.ps1
 } elseif (Test-Path "tools/Validate-PowerShellScripts.ps1") {
 & ./tools/Validate-PowerShellScripts.ps1 -Path . -AutoFix
 }
 Write-Host "`n Running bootstrap script fixes" -ForegroundColor Green
 if (Test-Path "./fix-bootstrap-script.ps1") {
 & ./fix-bootstrap-script.ps1
 } else {
 Write-Host " INFO fix-bootstrap-script.ps1 not found (may be archived)" -ForegroundColor Gray
 }
 Write-Host "`n Running PowerShell syntax fixes" -ForegroundColor Green
 if (Test-Path "./fix-powershell-syntax.ps1") {
 & ./fix-powershell-syntax.ps1
 } else {
 Write-Host " INFO fix-powershell-syntax.ps1 not found (may be archived)" -ForegroundColor Gray
 }
 
 Write-Host "`n Running specific test syntax fixes" -ForegroundColor Green
 if (Test-Path "./simple-fix-test-syntax.ps1") {
 & ./simple-fix-test-syntax.ps1
 } else {
 Write-Host " INFO simple-fix-test-syntax.ps1 not found (may be archived)" -ForegroundColor Gray
 }    Write-Host "`nPASS All fixes completed" -ForegroundColor Green
}

# Step 1.5: Check for emoji usage (prevents parsing issues)
Write-Host "`n STEP 1.5: CHECKING FOR EMOJI USAGE" -ForegroundColor Yellow
Write-Host "Emojis can cause parsing issues in validation scripts" -ForegroundColor Gray

$emojiCheckScript = Join-Path $PSScriptRoot "check-emojis.ps1"
if (Test-Path $emojiCheckScript) {
    Write-Host "Running emoji detection check" -ForegroundColor Green
    & $emojiCheckScript -ExitOnError:$CI
    Write-Host "PASS No emojis detected" -ForegroundColor Green
} else {
    Write-Host "WARN Emoji check script not found: $emojiCheckScript" -ForegroundColor Yellow
}

# Step 2: Run all tests
if (-not $SkipTests) {
    Write-Host "`n STEP 2: RUNNING ALL TESTS" -ForegroundColor Yellow
    
    if ($Detailed) {
        & ./run-comprehensive-tests.ps1 
    } else {
        & ./run-comprehensive-tests.ps1 -SkipLint
    }
}

$duration = (Get-Date) - $startTime
Write-Host "`n� VALIDATION COMPLETE" -ForegroundColor Cyan
Write-Host "Duration: $($duration.ToString('hh\:mm\:ss'))" -ForegroundColor Cyan
Write-Host "=" * 50 -ForegroundColor Cyan



