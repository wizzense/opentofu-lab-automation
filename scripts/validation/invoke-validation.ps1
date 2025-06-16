# invoke-comprehensive-validation.ps1
# This script runs a full system validation using the CodeFixer module
CmdletBinding()
param(
    switch$Fix,
    switch$GenerateTests,
    switch$SaveResults,
    ValidateSet('JSON','Text','CI')







    string$OutputFormat = 'Text',
    string$OutputDirectory = "reports/validation"
)

$ErrorActionPreference = 'Stop'

# Import the CodeFixer module
try {
    $repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $modulePath = Join-Path $repoRoot "pwsh/modules/CodeFixer/CodeFixer.psd1"
    if (Test-Path $modulePath) {
        Import-Module $modulePath -Force
    } else {
        Write-Error "CodeFixer module not found at path: $modulePath"
        exit 1
    }
} catch {
    Write-Error "Failed to import CodeFixer module: $_"
    exit 1
}

# Create timestamp for reports
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

# Create output directory if it doesn't exist
if ($SaveResults -and -not string::IsNullOrEmpty($OutputDirectory)) {
    $reportPath = Join-Path $PSScriptRoot $OutputDirectory
    if (-not (Test-Path $reportPath)) {
        New-Item -Path $reportPath -ItemType Directory -Force  Out-Null
        Write-Host "Created report directory: $reportPath" -ForegroundColor Cyan
    }
}

try {
    # Run comprehensive validation
    $params = @{
        OutputFormat = $OutputFormat
        OutputComprehensiveReport = $true
    }
    
    if ($Fix) {
        $params.ApplyFixes = $true
        Write-Host "Running validation with automatic fixes enabled..." -ForegroundColor Cyan
    } else {
        Write-Host "Running validation in report-only mode..." -ForegroundColor Cyan
    }
    
    if ($GenerateTests) {
        $params.GenerateTests = $true
        Write-Host "Test generation is enabled..." -ForegroundColor Cyan
    }
    
    if ($SaveResults) {
        if (-not string::IsNullOrEmpty($OutputDirectory)) {
            $params.OutputPath = Join-Path $PSScriptRoot $OutputDirectory "validation-report-$timestamp.json"
            Write-Host "Results will be saved to: $($params.OutputPath)" -ForegroundColor Cyan
        }
    }
    
    $results = Invoke-ComprehensiveValidation @params
    
    if ($results.OverallStatus -eq 'Success') {
        Write-Host "`nVALIDATION SUCCESSFUL!" -ForegroundColor Green
        Write-Host "- Total scripts checked: $($results.SummaryStats.TotalScripts)" -ForegroundColor Green
        Write-Host "- Syntax fixes applied: $($results.SummaryStats.SyntaxFixesApplied)" -ForegroundColor Green
        Write-Host "- Tests generated: $($results.SummaryStats.TestsGenerated)" -ForegroundColor Green
    } else {
        Write-Host "`nVALIDATION COMPLETED WITH ISSUES!" -ForegroundColor Yellow
        Write-Host "- Total scripts checked: $($results.SummaryStats.TotalScripts)" -ForegroundColor Yellow
        Write-Host "- Scripts with issues: $($results.SummaryStats.ScriptsWithIssues)" -ForegroundColor Yellow
        Write-Host "- Syntax fixes applied: $($results.SummaryStats.SyntaxFixesApplied)" -ForegroundColor Yellow
        Write-Host "- Tests generated: $($results.SummaryStats.TestsGenerated)" -ForegroundColor Yellow
        
        if (-not $Fix -and $results.SummaryStats.ScriptsWithIssues -gt 0) {
            Write-Host "`nRun again with -Fix to automatically address issues" -ForegroundColor Cyan
        }
    }
    
} catch {
    Write-Host "Validation failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Full error: $_" -ForegroundColor Red
    exit 1
}



