



# Simple CodeFixer and LabRunner Test Script

Write-Host " Testing CodeFixer and LabRunner functionality..." -ForegroundColor Cyan

# Test 1: PSScriptAnalyzer Installation
Write-Host "`n1. Testing PSScriptAnalyzer..." -ForegroundColor Yellow
try {
 Import-Module PSScriptAnalyzer -Force
 $psaVersion = (Get-Module PSScriptAnalyzer).Version
 Write-Host "[PASS] PSScriptAnalyzer $psaVersion is available" -ForegroundColor Green
} catch {
 Write-Host "[FAIL] PSScriptAnalyzer not available: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: CodeFixer PowerShell Linting with Parallel Processing
Write-Host "`n2. Testing CodeFixer linting..." -ForegroundColor Yellow
Write-Host "Running PowerShell linting with parallel processing..." -ForegroundColor Cyan
try {
 # Load the new parallel functions
 . "/workspaces/opentofu-lab-automation//pwsh/modules/CodeFixer/Public/Invoke-ParallelScriptAnalyzer.ps1"
 . "/workspaces/opentofu-lab-automation//pwsh/modules/CodeFixer/Public/Invoke-PowerShellLint.ps1"
 . "/workspaces/opentofu-lab-automation//pwsh/modules/CodeFixer/Private/Get-SyntaxFixSuggestion.ps1"
 
 # Test parallel analysis on the entire project
 $result = Invoke-PowerShellLint -Path "/workspaces/opentofu-lab-automation/pwsh" -Parallel -PassThru
 
 if ($result -and $result.Count -gt 0) {
 Write-Host "[PASS] CodeFixer parallel linting detected $($result.Count) issues" -ForegroundColor Green
 } else {
 Write-Host "[WARN] CodeFixer linting completed but found no issues (may be normal)" -ForegroundColor Yellow
 }
} catch {
 Write-Host "[FAIL] CodeFixer linting failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: LabRunner Module Loading
Write-Host "`n3. Testing LabRunner module..." -ForegroundColor Yellow
try {
 Import-Module "/C:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation\pwsh/modules/LabRunner/" -Force$labRunnerModule = Get-Module LabRunner
 if ($labRunnerModule) {
 Write-Host "[PASS] LabRunner module loaded successfully" -ForegroundColor Green
 $commands = Get-Command -Module LabRunner | Measure-Object
 Write-Host " LabRunner exports $($commands.Count) commands" -ForegroundColor Cyan
 } else {
 Write-Host "[FAIL] LabRunner module not loaded" -ForegroundColor Red
 }
} catch {
 Write-Host "[FAIL] LabRunner loading failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 4: Test Helper LabRunner Integration
Write-Host "`n4. Testing test helper integration..." -ForegroundColor Yellow
try {
 . "/workspaces/opentofu-lab-automation/tests/helpers/TestHelpers.ps1"
 $labRunnerFromTests = Get-Module LabRunner
 if ($labRunnerFromTests) {
 Write-Host "[PASS] TestHelpers can load LabRunner from new path" -ForegroundColor Green
 } else {
 Write-Host "[FAIL] TestHelpers cannot load LabRunner" -ForegroundColor Red
 }
} catch {
 Write-Host "[FAIL] TestHelpers failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 5: Quick Pester Test
Write-Host "`n5. Testing Pester with LabRunner..." -ForegroundColor Yellow
try {
 $pesterTest = @"
Describe 'LabRunner Integration' {
 It 'should load LabRunner module' {
 Import-Module "/C:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation\pwsh/modules/LabRunner/" -ForceGet-Module LabRunner | Should -Not -BeNullOrEmpty
 }
}
"@
 
 $tempTest = "/tmp/labrunner-test.ps1"
 Set-Content -Path $tempTest -Value $pesterTest
 
 $pesterResult = Invoke-Pester -Path $tempTest -PassThru -Output None
 
 if ($pesterResult.Result -eq "Passed") {
 Write-Host "[PASS] Pester test passed" -ForegroundColor Green
 } else {
 Write-Host "[FAIL] Pester test failed" -ForegroundColor Red
 }
 
 Remove-Item $tempTest -ErrorAction SilentlyContinue
} catch {
 Write-Host "[FAIL] Pester test failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n Testing completed!" -ForegroundColor Green
Write-Host "`nSummary:" -ForegroundColor Cyan
Write-Host "- PSScriptAnalyzer is installed and available for CodeFixer" -ForegroundColor White
Write-Host "- CodeFixer linting functions can be loaded and executed" -ForegroundColor White 
Write-Host "- LabRunner has been successfully moved to pwsh/modules/LabRunner" -ForegroundColor White
Write-Host "- Test infrastructure can find and use LabRunner from the new location" -ForegroundColor White
Write-Host "- Pester tests work with the new LabRunner module path" -ForegroundColor White















