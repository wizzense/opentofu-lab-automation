#!/usr/bin/env pwsh
# Test Pester with spaces in path

Write-Host "=== PESTER SPACE HANDLING TEST ===" -ForegroundColor Cyan

# Import Pester
Import-Module Pester -MinimumVersion 5.7.1 -Force
Write-Host "Pester version: $((Get-Module Pester).Version)" -ForegroundColor Green

# Test current directory with spaces
$currentDir = Get-Location
Write-Host "Current directory: $currentDir" -ForegroundColor Yellow
Write-Host "Contains spaces: $($currentDir -like '* *')" -ForegroundColor Yellow

# Test a simple Pester test file
$testFile = "tests\PathUtils.Tests.ps1"
$fullPath = Join-Path $currentDir $testFile

Write-Host "`nTesting file: $testFile" -ForegroundColor Cyan
Write-Host "Full path: $fullPath" -ForegroundColor White
Write-Host "File exists: $(Test-Path $fullPath)" -ForegroundColor $(if (Test-Path $fullPath) { "Green" } else { "Red" })

if (Test-Path $fullPath) {
    Write-Host "`nRunning Pester test..." -ForegroundColor Yellow
    
    $config = New-PesterConfiguration
    $config.Run.Path = $fullPath
    $config.Output.Verbosity = 'Detailed'
    $config.Run.PassThru = $true
    
    try {
        $result = Invoke-Pester -Configuration $config
        Write-Host "`nTest completed successfully!" -ForegroundColor Green
        Write-Host "Tests run: $($result.TotalCount)" -ForegroundColor White
        Write-Host "Passed: $($result.PassedCount)" -ForegroundColor Green
        Write-Host "Failed: $($result.FailedCount)" -ForegroundColor $(if ($result.FailedCount -gt 0) { "Red" } else { "Green" })
    } catch {
        Write-Host "`nTest failed: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "Test file not found, trying a different one..." -ForegroundColor Yellow
    
    # Find any test file
    $anyTest = Get-ChildItem -Path "tests" -Filter "*.Tests.ps1"  Select-Object -First 1
    if ($anyTest) {
        Write-Host "Found test file: $($anyTest.Name)" -ForegroundColor Green
        $config = New-PesterConfiguration
        $config.Run.Path = $anyTest.FullName
        $config.Output.Verbosity = 'Normal'
        $config.Run.PassThru = $true
        
        try {
            $result = Invoke-Pester -Configuration $config
            Write-Host "`nTest completed!" -ForegroundColor Green
        } catch {
            Write-Host "`nTest failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

Write-Host "`n=== TEST COMPLETE ===" -ForegroundColor Cyan
