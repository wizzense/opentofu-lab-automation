#!/usr/bin/env pwsh
# run-all-tests.ps1
# This script executes all test and validation processes for the OpenTofu Lab Automation project

[CmdletBinding()]
param(
 [switch]$SkipLint,
 [switch]$SkipPester,
 [switch]$SkipPyTest,
 [switch]$SkipHealthCheck,
 [switch]$FixSyntax
)








$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$rootDir = $PSScriptRoot
$startTime = Get-Date

Write-Host "Starting OpenTofu Lab Automation full test suite at $(Get-Date)" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "Test execution options:"
Write-Host "- Lint: $(-not $SkipLint)"
Write-Host "- Pester: $(-not $SkipPester)"
Write-Host "- PyTest: $(-not $SkipPyTest)"
Write-Host "- Health Check: $(-not $SkipHealthCheck)"
Write-Host "- Fix Syntax: $FixSyntax"
Write-Host "=============================================" -ForegroundColor Cyan

$results = @{
 Lint = "SKIPPED"
 Pester = "SKIPPED"
 PyTest = "SKIPPED"
 HealthCheck = "SKIPPED"
 TotalErrors = 0
 TotalWarnings = 0
}

# Fix syntax issues if requested
if ($FixSyntax) {
 Write-Host "Fixing syntax issues in test files..." -ForegroundColor Green
 
 # Fix ternary operator syntax
 Write-Host "Fixing ternary operator syntax..." -ForegroundColor Yellow
 & "$rootDir/fix-ternary-syntax.ps1"
 
 # Fix other PowerShell syntax issues
 Write-Host "Fixing PowerShell script syntax..." -ForegroundColor Yellow
 & "$rootDir/fix-powershell-syntax.ps1"
}

# Run PowerShell linting
if (-not $SkipLint) {
 Write-Host "`nRunning PowerShell linting..." -ForegroundColor Green
 try {
 $lintScript = "$rootDir/../validation/run-lint.ps1"
 if (Test-Path $lintScript) {
 & $lintScript -ErrorAction Stop
 $lintCode = $LASTEXITCODE
 if ($lintCode -eq 0) {
 $results.Lint = "PASS"
 Write-Host "[PASS] Linting completed successfully" -ForegroundColor Green
 } else {
 $results.Lint = "FAIL ($lintCode)"
 $results.TotalErrors++
 Write-Host "[FAIL] Linting completed with errors (code: $lintCode)" -ForegroundColor Red
 }
 } else {
 Write-Host "[FAIL] Lint script not found: $lintScript" -ForegroundColor Red
 $results.Lint = "NOT_FOUND"
 $results.TotalErrors++
 }
 }
 catch {
 $results.Lint = "ERROR"
 $results.TotalErrors++
 Write-Host "[FAIL] Linting failed with an exception: $_" -ForegroundColor Red
 }
}

# Run Pester tests
if (-not $SkipPester) {
 Write-Host "`nRunning Pester tests..." -ForegroundColor Green
 try {
 $pesterConfig = New-PesterConfiguration
 $pesterConfig.Run.Path = "$rootDir/../../tests"
 $pesterConfig.Output.Verbosity = "Detailed"
 $pesterConfig.TestResult.Enabled = $true
 $pesterConfig.TestResult.OutputPath = "$rootDir/TestResults.xml"
 $pesterConfig.TestResult.OutputFormat = "NUnitXml"
 
 $pesterResults = Invoke-Pester -Configuration $pesterConfig -PassThru
 
 $totalTests = $pesterResults.TotalCount
 $passedTests = $pesterResults.PassedCount
 $failedTests = $pesterResults.FailedCount
 $skippedTests = $pesterResults.SkippedCount
 
 if ($failedTests -eq 0) {
 $results.Pester = "PASS ($passedTests/$totalTests)"
 Write-Host "[PASS] Pester tests completed successfully: $passedTests passed, $skippedTests skipped" -ForegroundColor Green
 } else {
 $results.Pester = "FAIL ($failedTests/$totalTests)"
 $results.TotalErrors += $failedTests
 Write-Host "[FAIL] Pester tests completed with $failedTests failures: $passedTests passed, $failedTests failed, $skippedTests skipped" -ForegroundColor Red
 }
 }
 catch {
 $results.Pester = "ERROR"
 $results.TotalErrors++
 Write-Host "[FAIL] Pester tests failed with an exception: $_" -ForegroundColor Red
 }
}

# Run Python tests
if (-not $SkipPyTest) {
 Write-Host "`nRunning Python tests..." -ForegroundColor Green
 try {
 $pyTestDir = "$rootDir/../../py"
 if (Test-Path $pyTestDir) {
 $pythonResults = & python -m pytest "$pyTestDir" -v
 $pytestCode = $LASTEXITCODE
 
 if ($pytestCode -eq 0) {
 $results.PyTest = "PASS"
 Write-Host "[PASS] Python tests completed successfully" -ForegroundColor Green
 } else {
 $results.PyTest = "FAIL ($pytestCode)"
 $results.TotalErrors++
 Write-Host "[FAIL] Python tests completed with errors (code: $pytestCode)" -ForegroundColor Red
 }
 } else {
 Write-Host "[FAIL] Python test directory not found: $pyTestDir" -ForegroundColor Red
 $results.PyTest = "NOT_FOUND"
 $results.TotalErrors++
 }
 }
 catch {
 $results.PyTest = "ERROR"
 $results.TotalErrors++
 Write-Host "[FAIL] Python tests failed with an exception: $_" -ForegroundColor Red
 }
}

# Run health checks
if (-not $SkipHealthCheck) {
 Write-Host "`nRunning health checks..." -ForegroundColor Green
 try {
 $healthScript = "$rootDir/../validation/health-check.ps1"
 if (Test-Path $healthScript) {
 $healthResults = & $healthScript
 $healthCode = $LASTEXITCODE
 
 if ($healthCode -eq 0) {
 $results.HealthCheck = "PASS"
 Write-Host "[PASS] Health check completed successfully" -ForegroundColor Green
 } else {
 $results.HealthCheck = "WARN"
 $results.TotalWarnings++
 Write-Host "[WARN] Health check found issues (code: $healthCode)" -ForegroundColor Yellow
 }
 } else {
 Write-Host "[FAIL] Health check script not found: $healthScript" -ForegroundColor Red
 $results.HealthCheck = "NOT_FOUND"
 $results.TotalErrors++
 }
 }
 catch {
 $results.HealthCheck = "ERROR"
 $results.TotalErrors++
 Write-Host "[FAIL] Health check failed with an exception: $_" -ForegroundColor Red
 }
}

# Final summary
$endTime = Get-Date
$duration = $endTime - $startTime

Write-Host "`n=============================================" -ForegroundColor Cyan
Write-Host "OpenTofu Lab Automation Test Summary" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "Lint: $($results.Lint)"
Write-Host "Pester: $($results.Pester)"
Write-Host "PyTest: $($results.PyTest)"
Write-Host "Health Check: $($results.HealthCheck)"
Write-Host "---------------------------------------------" -ForegroundColor Cyan
Write-Host "Total Errors: $($results.TotalErrors)"
Write-Host "Total Warnings: $($results.TotalWarnings)"
Write-Host "Duration: $($duration.ToString('hh\:mm\:ss'))"
Write-Host "=============================================" -ForegroundColor Cyan

# Return appropriate exit code
if ($results.TotalErrors -gt 0) {
 Write-Host "[FAIL] Tests completed with errors" -ForegroundColor Red
 exit 1
} elseif ($results.TotalWarnings -gt 0) {
 Write-Host "[WARN] Tests completed with warnings" -ForegroundColor Yellow
 exit 0
} else {
 Write-Host "[PASS] All tests passed successfully" -ForegroundColor Green
 exit 0
}



