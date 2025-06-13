#!/usr/bin/env pwsh
# run-comprehensive-tests.ps1
# This script runs the full suite of tests for the OpenTofu Lab Automation project

param(
    [switch]$SkipLint,
    [switch]$SkipPester,
    [switch]$SkipPyTest,
    [switch]$SkipHealthCheck
)





$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$rootDir = $PSScriptRoot
$startTime = Get-Date

Write-Host "Starting comprehensive test suite at $(Get-Date)" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# Import TestAutoFixer module and run syntax fixes
Write-Host "Fixing syntax issues in test files..." -ForegroundColor Green
try {
    Import-Module "$rootDir/../../tools/TestAutoFixer" -Force
    Invoke-SyntaxFix -AutoFix
    Write-Host "✅ Syntax fixes completed" -ForegroundColor Green
} catch {
    Write-Warning "Syntax fixer completed with warnings: $_"
}

$results = @{
    Lint = "SKIPPED"
    Pester = "SKIPPED"
    PyTest = "SKIPPED"
    HealthCheck = "SKIPPED"
    TotalErrors = 0
}

# Run PowerShell linting
if (-not $SkipLint) {
    Write-Host "`nRunning PowerShell linting..." -ForegroundColor Green
    try {
        # Use TestAutoFixer module for linting
        Get-LintIssues -Path "$rootDir/../../" -Fix -Detailed
        Write-Host "✅ Linting completed successfully" -ForegroundColor Green
        $results.Lint = "PASSED"
    } catch {
        Write-Host "❌ Linting failed: $_" -ForegroundColor Red
        $results.Lint = "ERROR"
        $results.TotalErrors++
    }
}

# Run Pester tests
if (-not $SkipPester) {
    Write-Host "`nRunning Pester tests..." -ForegroundColor Green
    try {
        $config = New-PesterConfiguration
        $config.Run.Path = "$rootDir/../../tests"
        $config.Run.PassThru = $true
        $config.Output.Verbosity = "Detailed"
        $config.TestResult.Enabled = $true
        $config.TestResult.OutputFormat = "NUnitXml"
        $config.TestResult.OutputPath = "$rootDir/TestResults.xml"
        
        $pesterResults = Invoke-Pester -Configuration $config
        
        if ($pesterResults.FailedCount -eq 0) {
            Write-Host "✅ Pester tests completed successfully ($($pesterResults.PassedCount) passed, $($pesterResults.SkippedCount) skipped)" -ForegroundColor Green
            $results.Pester = "PASSED"
        } else {
            Write-Host "❌ Pester tests completed with $($pesterResults.FailedCount) failures" -ForegroundColor Red
            $results.Pester = "FAILED"
            $results.TotalErrors++
        }
    } catch {
        Write-Host "❌ Pester tests failed: $_" -ForegroundColor Red
        $results.Pester = "ERROR"
        $results.TotalErrors++
    }
}

# Run Python tests
if (-not $SkipPyTest) {
    Write-Host "`nRunning Python tests..." -ForegroundColor Green
    try {
        $pythonCmd = if (Get-Command python -ErrorAction SilentlyContinue) { 
            "python" 
        } elseif (Get-Command python3 -ErrorAction SilentlyContinue) { 
            "python3" 
        } else {
            throw "No Python command found"
        }
        
        # Install pytest if needed
        & $pythonCmd -m pip install pytest pytest-cov -q
        
        # Run tests
        & $pythonCmd -m pytest "$rootDir/../../py/tests" -v
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Python tests completed successfully" -ForegroundColor Green
            $results.PyTest = "PASSED"
        } else {
            Write-Host "❌ Python tests completed with errors (code: $LASTEXITCODE)" -ForegroundColor Red
            $results.PyTest = "FAILED"
            $results.TotalErrors++
        }
    } catch {
        Write-Host "❌ Python tests failed: $_" -ForegroundColor Red
        $results.PyTest = "ERROR"
        $results.TotalErrors++
    }
}

# Run health check
if (-not $SkipHealthCheck) {
    Write-Host "`nRunning comprehensive health check..." -ForegroundColor Green
    try {
        # Use TestAutoFixer module for validation
        $healthReport = Invoke-ValidationChecks -OutputFormat JSON
        Write-Host "✅ Health check completed successfully" -ForegroundColor Green
        $results.HealthCheck = "PASSED"
    } catch {
        Write-Host "❌ Health check failed: $_" -ForegroundColor Red
        $results.HealthCheck = "ERROR"
        $results.TotalErrors++
    }
}

# Calculate elapsed time
$endTime = Get-Date
$elapsed = $endTime - $startTime
$elapsedFormatted = "{0:mm\:ss}" -f $elapsed

# Display summary
Write-Host "`n=============================================" -ForegroundColor Cyan
Write-Host "Test Suite Summary" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "PowerShell Lint:   $($results.Lint)"
Write-Host "Pester Tests:      $($results.Pester)"
Write-Host "Python Tests:      $($results.PyTest)"
Write-Host "Health Check:      $($results.HealthCheck)"
Write-Host "---------------------------------------------"
Write-Host "Total Time:        $elapsedFormatted"
Write-Host "Total Errors:      $($results.TotalErrors)"
Write-Host "============================================="

if ($results.TotalErrors -gt 0) {
    Write-Host "❌ Some tests failed - please check the logs above for details" -ForegroundColor Red
    exit 1
} else {
    Write-Host "✅ All tests completed successfully" -ForegroundColor Green
    exit 0
}


