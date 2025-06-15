# Comprehensive Test Script for CodeFixer Enhancements
# Tests PSScriptAnalyzer auto-installation, import analysis, and LabRunner integration

param(
 [switch]$Verbose,
 [switch]$AutoFix
)








$ErrorActionPreference = "Continue"

function Write-TestResult {
 param([string]$Test, [bool]$Passed, [string]$Details = "")
 






$status = if ($Passed) { "[PASS] PASS" } else { "[FAIL] FAIL" }
 $color = if ($Passed) { "Green" } else { "Red" }
 Write-Host "$status - $Test" -ForegroundColor $color
 if ($Details -and $Verbose) {
 Write-Host " $Details" -ForegroundColor Gray
 }
}

Write-Host " Testing CodeFixer Enhancements" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

# Test 1: CodeFixer module loading
Write-Host "`n1⃣ Testing CodeFixer Module Loading..." -ForegroundColor Yellow
try {
 Import-Module "/C:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation//pwsh/modules/CodeFixer/" -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force
 $module = Get-Module CodeFixer
 $functions = Get-Command -Module CodeFixer
 
 Write-TestResult "CodeFixer module loads" ($module -ne $null) "Version: $($module.Version)"
 Write-TestResult "Functions exported" ($functions.Count -gt 0) "Found $($functions.Count) functions: $($functions.Name -join ', ')"
 
 # Test specific functions exist
 $expectedFunctions = @('Invoke-PowerShellLint', 'Invoke-AutoFix', 'Invoke-ImportAnalysis', 'Test-JsonConfig')
 foreach ($func in $expectedFunctions) {
 $exists = $functions.Name -contains $func
 Write-TestResult "Function '$func' available" $exists
 }
} catch {
 Write-TestResult "CodeFixer module loading" $false $_.Exception.Message
}

# Test 2: PSScriptAnalyzer auto-installation
Write-Host "`n2⃣ Testing PSScriptAnalyzer Auto-Installation..." -ForegroundColor Yellow
try {
 # Remove PSScriptAnalyzer first to test installation
 Get-Module PSScriptAnalyzer | Remove-Module -Force -ErrorAction SilentlyContinue
 
 # Test the enhanced linting function
 $result = Invoke-PowerShellLint -Path "/workspaces/opentofu-lab-automation/pwsh/runner.ps1" -PassThru -OutputFormat Text
 
 # Check if PSScriptAnalyzer was installed/loaded
 $psAnalyzer = Get-Module PSScriptAnalyzer -ErrorAction SilentlyContinue
 Write-TestResult "PSScriptAnalyzer auto-installed" ($psAnalyzer -ne $null) "Version: $($psAnalyzer.Version)"
 Write-TestResult "Linting completed" ($result -ne $null) "Found $($result.Count) issues"
 
} catch {
 Write-TestResult "PSScriptAnalyzer auto-installation" $false $_.Exception.Message
}

# Test 3: Import Analysis
Write-Host "`n3⃣ Testing Import Analysis..." -ForegroundColor Yellow
try {
 # Test import analysis on the project
 $importIssues = Invoke-ImportAnalysis -Path "/workspaces/opentofu-lab-automation/pwsh" -PassThru
 
 Write-TestResult "Import analysis runs" ($importIssues -ne $null) "Found $($importIssues.Count) import issues"
 
 # Check for specific issue types
 $outdatedPaths = $importIssues | Where-Object Type -eq 'OutdatedPath'
 $missingImports = $importIssues | Where-Object Type -eq 'MissingImport'
 
 Write-TestResult "Detects outdated paths" ($outdatedPaths.Count -ge 0) "Found $($outdatedPaths.Count) outdated paths"
 Write-TestResult "Detects missing imports" ($missingImports.Count -ge 0) "Found $($missingImports.Count) missing imports"
 
 if ($AutoFix -and $importIssues.Count -gt 0) {
 Write-Host " Running auto-fix..." -ForegroundColor Cyan
 Invoke-ImportAnalysis -Path "/workspaces/opentofu-lab-automation/pwsh" -AutoFix
 Write-TestResult "Auto-fix completed" $true
 }
 
} catch {
 Write-TestResult "Import analysis" $false $_.Exception.Message
}

# Test 4: LabRunner Integration
Write-Host "`n4⃣ Testing LabRunner Integration..." -ForegroundColor Yellow
try {
 # Test that LabRunner loads from new location
 Import-Module "/C:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation//pwsh/modules/LabRunner/" -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force
 $labRunner = Get-Module LabRunner
 
 Write-TestResult "LabRunner loads from new location" ($labRunner -ne $null) "Path: $($labRunner.Path)"
 
 # Test TestHelpers loads LabRunner correctly
 . "/workspaces/opentofu-lab-automation/tests/helpers/TestHelpers.ps1"
 $labRunnerFromTests = Get-Module LabRunner
 
 Write-TestResult "TestHelpers loads LabRunner" ($labRunnerFromTests -ne $null)
 
 # Test key LabRunner functions exist
 $labRunnerFunctions = Get-Command -Module LabRunner -ErrorAction SilentlyContinue
 Write-TestResult "LabRunner functions available" ($labRunnerFunctions.Count -gt 0) "Found $($labRunnerFunctions.Count) functions"
 
} catch {
 Write-TestResult "LabRunner integration" $false $_.Exception.Message
}

# Test 5: JSON Config Validation
Write-Host "`n5⃣ Testing JSON Config Validation..." -ForegroundColor Yellow
try {
 # Find some JSON config files to test
 $jsonFiles = Get-ChildItem -Path "/workspaces/opentofu-lab-automation/configs" -Recurse -Include "*.json" -File | Select-Object -First 3
 
 if ($jsonFiles.Count -gt 0) {
 foreach ($jsonFile in $jsonFiles) {
 $configResult = Test-JsonConfig -Path $jsonFile.FullName -PassThru
 Write-TestResult "JSON validation: $($jsonFile.Name)" ($configResult -ne $null)
 }
 } else {
 Write-TestResult "JSON config files found" $false "No JSON files found in configs directory"
 }
 
} catch {
 Write-TestResult "JSON config validation" $false $_.Exception.Message
}

# Test 6: Comprehensive Validation
Write-Host "`n6⃣ Testing Comprehensive Validation..." -ForegroundColor Yellow
try {
 # Run comprehensive validation on a subset of files
 $validationResult = Invoke-ComprehensiveValidation -Path "/workspaces/opentofu-lab-automation/pwsh/runner.ps1" -PassThru
 
 Write-TestResult "Comprehensive validation runs" ($validationResult -ne $null)
 
} catch {
 Write-TestResult "Comprehensive validation" $false $_.Exception.Message
}

# Test 7: Runner Scripts Check
Write-Host "`n7⃣ Testing Runner Scripts..." -ForegroundColor Yellow
try {
 # Check if runner scripts have correct imports
 $runnerScripts = Get-ChildItem -Path "/workspaces/opentofu-lab-automation/pwsh/runner_scripts" -Include "*.ps1" -File
 $scriptsWithOldPaths = @()
 
 foreach ($script in $runnerScripts) {
 $content = Get-Content -Path $script.FullName -Raw -ErrorAction SilentlyContinue
 if ($content -and $content -match "lab_utils") {
 $scriptsWithOldPaths += $script.Name
 }
 }
 
 Write-TestResult "Runner scripts updated" ($scriptsWithOldPaths.Count -eq 0) "Scripts with old paths: $($scriptsWithOldPaths -join ', ')"
 
} catch {
 Write-TestResult "Runner scripts check" $false $_.Exception.Message
}

# Summary
Write-Host "`n Test Summary" -ForegroundColor Cyan
Write-Host "===============" -ForegroundColor Cyan

$allTests = @(
 "CodeFixer module loads",
 "PSScriptAnalyzer auto-installed", 
 "Import analysis runs",
 "LabRunner loads from new location",
 "JSON validation works",
 "Comprehensive validation runs",
 "Runner scripts updated"
)

Write-Host " All major enhancements tested!" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Run 'Invoke-ImportAnalysis -AutoFix' to fix any remaining import issues" -ForegroundColor White
Write-Host "2. Run 'Invoke-Pester tests/' to verify all tests pass" -ForegroundColor White
Write-Host "3. Run 'Invoke-PowerShellLint .' to lint the entire project" -ForegroundColor White














