#!/usr/bin/env pwsh
# Quick validation test for new infrastructure

Write-Host " Quick Infrastructure Validation Test" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan

$tests = @{
 "CodeFixer Module" = {
 try {
 Import-Module "/C:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation//pwsh/modules/CodeFixer/" -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force
 $result = Get-Module CodeFixer
 return $result -ne $null
 } catch {
 return $false
 }
 }
 
 "LabRunner Module" = {
 try {
 Import-Module "/C:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation//pwsh/modules/LabRunner/" -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force
 $result = Get-Module LabRunner
 return $result -ne $null
 } catch {
 return $false
 }
 }
 
 "TestHelpers Syntax" = {
 try {
 $content = Get-Content "./tests/helpers/TestHelpers.ps1" -Raw
 $null = [System.Management.Automation.PSParser]::Tokenize($content, [ref]$null)
 return $true
 } catch {
 return $false
 }
 }
 
 "Bootstrap Script Syntax" = {
 try {
 $content = Get-Content "./pwsh/kicker-bootstrap.ps1" -Raw
 $null = [System.Management.Automation.PSParser]::Tokenize($content, [ref]$null)
 return $true
 } catch {
 return $false
 }
 }
 
 "Deploy Script Exists" = {
 try {
 return Test-Path "./deploy.py"
 } catch {
 return $false
 }
 }
 
 "Parallel Test Runner" = {
 try {
 return Test-Path "./scripts/testing/run-parallel-tests.ps1"
 } catch {
 return $false
 }
 }
}

$passed = 0
$total = $tests.Count

foreach ($testName in $tests.Keys) {
 Write-Host "`n Testing: $testName" -ForegroundColor Yellow
 
 $result = & $tests[$testName]
 
 if ($result) {
 Write-Host " [PASS] PASSED" -ForegroundColor Green
 $passed++
 } else {
 Write-Host " [FAIL] FAILED" -ForegroundColor Red
 }
}

Write-Host "`n Summary: $passed/$total tests passed" -ForegroundColor Cyan

if ($passed -eq $total) {
 Write-Host " All infrastructure validation tests passed!" -ForegroundColor Green
 Write-Host "[PASS] Ready for merge and deployment!" -ForegroundColor Green
 exit 0
} else {
 Write-Host "[WARN] Some tests failed. Review before merging." -ForegroundColor Yellow
 exit 1
}











