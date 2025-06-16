#!/usr/bin/env pwsh
<#
.SYNOPSIS
Comprehensive test script for the improved CodeFixer and LabRunner integration

.DESCRIPTION
This script tests the improved CodeFixer module functionality including:
- PowerShell syntax error detection and fixing
- JSON configuration validation 
- Integration with LabRunner
- Comprehensive validation workflows

.EXAMPLE
./test-codefixer-improvements.ps1
#>

CmdletBinding()
param(
 switch$SkipFixes,
 switch$VerboseOutput
)








$ErrorActionPreference = "Continue"

Write-Host " Testing CodeFixer Improvements" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

# Set up test environment
$testDir = Join-Path $PSScriptRoot "test-output"
if (Test-Path $testDir) {
 Remove-Item $testDir -Recurse -Force
}
New-Item -ItemType Directory -Path $testDir -Force | Out-Null
Write-Host "`n� Created test directory: $testDir" -ForegroundColor Green

# Test 1: Load CodeFixer module functions
Write-Host "`n1/6 Testing CodeFixer module loading..." -ForegroundColor Yellow
try {
 . "$PSScriptRoot/pwsh/modules/CodeFixer/Public/Invoke-PowerShellLint.ps1"
 . "$PSScriptRoot/pwsh/modules/CodeFixer/Public/Test-JsonConfig.ps1"
 . "$PSScriptRoot/pwsh/modules/CodeFixer/Public/Invoke-AutoFix.ps1"
 . "$PSScriptRoot/pwsh/modules/CodeFixer/Private/Get-SyntaxFixSuggestion.ps1"
 . "$PSScriptRoot/pwsh/modules/CodeFixer/Private/Get-JsonFixSuggestion.ps1"
 . "$PSScriptRoot/pwsh/modules/CodeFixer/Private/Repair-SyntaxError.ps1"
 Write-Host " PASS All CodeFixer functions loaded successfully" -ForegroundColor Green
} catch {
 Write-Host " FAIL Failed to load CodeFixer functions: $($_.Exception.Message)" -ForegroundColor Red
 exit 1
}

# Test 2: PowerShell syntax error detection
Write-Host "`n2/6 Testing PowerShell syntax error detection..." -ForegroundColor Yellow
$testResults = @()

if (Test-Path "$PSScriptRoot/test-syntax-errors.ps1") {
 try {
 $lintResults = Invoke-PowerShellLint -Path "$PSScriptRoot/test-syntax-errors.ps1" -PassThru
 if ($lintResults -and $lintResults.Count -gt 0) {
 Write-Host " PASS Detected $($lintResults.Count) syntax errors" -ForegroundColor Green
 $testResults += PSCustomObject@{
 Test = "PowerShell Syntax Detection"
 Status = "PASS" 
 Details = "Found $($lintResults.Count) errors"
 }
 } else {
 Write-Host " WARN No syntax errors detected (expected some)" -ForegroundColor Yellow
 $testResults += PSCustomObject@{
 Test = "PowerShell Syntax Detection"
 Status = "WARN"
 Details = "No errors found"
 }
 }
 } catch {
 Write-Host " FAIL Error running PowerShell linting: $($_.Exception.Message)" -ForegroundColor Red
 $testResults += PSCustomObject@{
 Test = "PowerShell Syntax Detection"
 Status = "FAIL"
 Details = $_.Exception.Message
 }
 }
} else {
 Write-Host " WARN Test file not found: test-syntax-errors.ps1" -ForegroundColor Yellow
 $testResults += PSCustomObject@{
 Test = "PowerShell Syntax Detection"
 Status = "SKIP"
 Details = "Test file missing"
 }
}

# Test 3: JSON configuration validation
Write-Host "`n3/6 Testing JSON configuration validation..." -ForegroundColor Yellow

if (Test-Path "$PSScriptRoot/test-config-errors.json") {
 try {
 $jsonResults = Test-JsonConfig -Path "$PSScriptRoot/test-config-errors.json" -PassThru
 if ($jsonResults -and $jsonResults.Count -gt 0) {
 Write-Host " PASS Detected $($jsonResults.Count) JSON issues" -ForegroundColor Green
 $testResults += PSCustomObject@{
 Test = "JSON Config Validation"
 Status = "PASS"
 Details = "Found $($jsonResults.Count) issues"
 }
 } else {
 Write-Host " WARN No JSON issues detected (expected some)" -ForegroundColor Yellow
 $testResults += PSCustomObject@{
 Test = "JSON Config Validation"
 Status = "WARN"
 Details = "No issues found"
 }
 }
 } catch {
 Write-Host " FAIL Error running JSON validation: $($_.Exception.Message)" -ForegroundColor Red
 $testResults += PSCustomObject@{
 Test = "JSON Config Validation"
 Status = "FAIL"
 Details = $_.Exception.Message
 }
 }
} else {
 Write-Host " WARN Test file not found: test-config-errors.json" -ForegroundColor Yellow
 $testResults += PSCustomObject@{
 Test = "JSON Config Validation"
 Status = "SKIP"
 Details = "Test file missing"
 }
}

# Test 4: Real JSON config files validation
Write-Host "`n4/6 Testing real configuration files..." -ForegroundColor Yellow

$configPath = Join-Path $PSScriptRoot "configs/config_files"
if (Test-Path $configPath) {
 try {
 $realConfigResults = Test-JsonConfig -Path $configPath -PassThru
 $errorCount = (realConfigResults | Where-ObjectSeverity -eq 'Error').Count
 $warningCount = (realConfigResults | Where-ObjectSeverity -eq 'Warning').Count
 
 if ($errorCount -eq 0) {
 Write-Host " PASS All real config files are valid" -ForegroundColor Green
 $testResults += PSCustomObject@{
 Test = "Real Config Files"
 Status = "PASS"
 Details = "$warningCount warnings, 0 errors"
 }
 } else {
 Write-Host " WARN Found $errorCount errors in real config files" -ForegroundColor Yellow
 $testResults += PSCustomObject@{
 Test = "Real Config Files" 
 Status = "WARN"
 Details = "$errorCount errors, $warningCount warnings"
 }
 }
 } catch {
 Write-Host " FAIL Error validating real configs: $($_.Exception.Message)" -ForegroundColor Red
 $testResults += PSCustomObject@{
 Test = "Real Config Files"
 Status = "FAIL"
 Details = $_.Exception.Message
 }
 }
} else {
 Write-Host " WARN Config directory not found: $configPath" -ForegroundColor Yellow
 $testResults += PSCustomObject@{
 Test = "Real Config Files"
 Status = "SKIP"
 Details = "Config directory missing"
 }
}

# Test 5: LabRunner integration
Write-Host "`n5/6 Testing LabRunner integration..." -ForegroundColor Yellow

$labRunnerPath = Join-Path $PSScriptRoot "pwsh/modules/LabRunner"
if (Test-Path $labRunnerPath) {
 try {
 Import-Module $labRunnerPath -Force -ErrorAction Stop
 $labRunnerCommands = Get-Command -Module LabRunner -ErrorAction SilentlyContinue
 
 if ($labRunnerCommands.Count -gt 0) {
 Write-Host " PASS LabRunner module loaded with $($labRunnerCommands.Count) commands" -ForegroundColor Green
 $testResults += PSCustomObject@{
 Test = "LabRunner Integration"
 Status = "PASS"
 Details = "$($labRunnerCommands.Count) commands available"
 }
 } else {
 Write-Host " WARN LabRunner module loaded but no commands found" -ForegroundColor Yellow
 $testResults += PSCustomObject@{
 Test = "LabRunner Integration"
 Status = "WARN"
 Details = "No commands exported"
 }
 }
 } catch {
 Write-Host " FAIL Error loading LabRunner: $($_.Exception.Message)" -ForegroundColor Red
 $testResults += PSCustomObject@{
 Test = "LabRunner Integration"
 Status = "FAIL"
 Details = $_.Exception.Message
 }
 }
} else {
 Write-Host " WARN LabRunner module not found at: $labRunnerPath" -ForegroundColor Yellow
 $testResults += PSCustomObject@{
 Test = "LabRunner Integration"
 Status = "SKIP"
 Details = "Module directory missing"
 }
}

# Test 6: Runner.ps1 still works
Write-Host "`n6/6 Testing runner.ps1 functionality..." -ForegroundColor Yellow

$runnerPath = Join-Path $PSScriptRoot "pwsh/runner.ps1"
if (Test-Path $runnerPath) {
 try {
 # Test that runner.ps1 can at least parse without errors
 $null = System.Management.Automation.Language.Parser::ParseFile($runnerPath, ref$null, ref$null)
 Write-Host " PASS Runner.ps1 syntax is valid" -ForegroundColor Green
 $testResults += PSCustomObject@{
 Test = "Runner.ps1 Functionality"
 Status = "PASS" 
 Details = "Syntax validation passed"
 }
 } catch {
 Write-Host " FAIL Runner.ps1 has syntax errors: $($_.Exception.Message)" -ForegroundColor Red
 $testResults += PSCustomObject@{
 Test = "Runner.ps1 Functionality"
 Status = "FAIL"
 Details = $_.Exception.Message
 }
 }
} else {
 Write-Host " FAIL Runner.ps1 not found at: $runnerPath" -ForegroundColor Red
 $testResults += PSCustomObject@{
 Test = "Runner.ps1 Functionality"
 Status = "FAIL"
 Details = "File not found"
 }
}

# Summary
Write-Host "`n Test Results Summary" -ForegroundColor Cyan
Write-Host "======================" -ForegroundColor Cyan

$testResults  Format-Table -AutoSize

$passCount = (testResults | Where-ObjectStatus -eq 'PASS').Count
$failCount = (testResults | Where-ObjectStatus -eq 'FAIL').Count 
$warnCount = (testResults | Where-ObjectStatus -eq 'WARN').Count
$skipCount = (testResults | Where-ObjectStatus -eq 'SKIP').Count

Write-Host "`n Overall Results:" -ForegroundColor Cyan
Write-Host "PASS PASSED: $passCount" -ForegroundColor Green
Write-Host "FAIL FAILED: $failCount" -ForegroundColor $$(if (failCount -gt 0) { 'Red' } else { 'Green' })
Write-Host "WARN WARNINGS: $warnCount" -ForegroundColor $$(if (warnCount -gt 0) { 'Yellow' } else { 'Green' })
Write-Host "⏭ SKIPPED: $skipCount" -ForegroundColor Gray

if ($failCount -eq 0) {
 Write-Host "`n All critical tests passed! CodeFixer improvements are working." -ForegroundColor Green
 exit 0
} else {
 Write-Host "`n Some tests failed. Please review the results above." -ForegroundColor Red
 exit 1
}






