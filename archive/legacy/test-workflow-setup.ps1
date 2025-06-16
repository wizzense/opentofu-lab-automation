# Test script to validate workflow setup
CmdletBinding()
param()








$ErrorActionPreference = 'Stop'

Write-Host "� Testing Workflow Setup" -ForegroundColor Cyan
Write-Host "=" * 30

try {
    # Test 1: Check if Pester is available
    Write-Host "Testing Pester availability..." -ForegroundColor Yellow
    
    if (Get-Module -ListAvailable -Name Pester  Where-Object { $_.Version -ge version'5.0.0' }) {
        Write-Host "PASS Pester 5.x is available" -ForegroundColor Green
    } else {
        Write-Host "FAIL Pester 5.x not found" -ForegroundColor Red
        throw "Pester 5.x is required"
    }
    
    # Test 2: Check Pester configuration
    Write-Host "Testing Pester configuration..." -ForegroundColor Yellow
    
    if (Test-Path 'tests/PesterConfiguration.psd1') {
        $cfg = Import-PowerShellDataFile 'tests/PesterConfiguration.psd1'
        Write-Host "PASS Pester configuration loaded" -ForegroundColor Green
        Write-Host "   Test path: $($cfg.Run.Path)" -ForegroundColor Cyan
        Write-Host "   Coverage enabled: $($cfg.CodeCoverage.Enabled)" -ForegroundColor Cyan
    } else {
        throw "Pester configuration file not found"
    }
    
    # Test 3: Check test helpers
    Write-Host "Testing test helpers..." -ForegroundColor Yellow
    
    if (Test-Path 'tests/helpers/Get-ScriptAst.ps1') {
        . ./tests/helpers/Get-ScriptAst.ps1
        if (Get-Command Get-ScriptAst -ErrorAction SilentlyContinue) {
            Write-Host "PASS Test helpers loaded successfully" -ForegroundColor Green
        } else {
            throw "Get-ScriptAst function not available after loading"
        }
    } else {
        throw "Test helpers not found"
    }
    
    # Test 4: Test basic Pester configuration creation
    Write-Host "Testing Pester configuration creation..." -ForegroundColor Yellow
    
    try {
        $testCfg = New-PesterConfiguration -Hashtable $cfg
        $testCfg.Run.PassThru = $true
        $testCfg.Output.Verbosity = 'Minimal'
        $testCfg.CodeCoverage.Enabled = $false
        $testCfg.TestResult.Enabled = $false
        Write-Host "PASS Pester configuration created successfully" -ForegroundColor Green
    } catch {
        throw "Failed to create Pester configuration: $_"
    }
    
    # Test 5: Check for test files
    Write-Host "Checking test files..." -ForegroundColor Yellow
    
    $testFiles = Get-ChildItem -Path 'tests' -Filter '*.Tests.ps1' -File
    Write-Host "PASS Found $($testFiles.Count) test files" -ForegroundColor Green
    
    foreach ($testFile in $testFiles  Select-Object -First 3) {
        Write-Host "   - $($testFile.Name)" -ForegroundColor Cyan
    }
    
    if ($testFiles.Count -gt 3) {
        Write-Host "   ... and $($testFiles.Count - 3) more" -ForegroundColor Cyan
    }
    
    # Test 6: Validate a sample test file syntax
    Write-Host "Validating sample test syntax..." -ForegroundColor Yellow
    
    $sampleTest = $testFiles  Select-Object -First 1
    if ($sampleTest) {
        try {
            $ast = Get-ScriptAst -Path $sampleTest.FullName
            Write-Host "PASS Sample test syntax is valid: $($sampleTest.Name)" -ForegroundColor Green
        } catch {
            Write-Warning "Sample test syntax validation failed: $_"
        }
    }
    
    Write-Host "`n All workflow setup tests passed!" -ForegroundColor Green
    exit 0
    
} catch {
    Write-Host "`nFAIL Workflow setup test failed: $_" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
    exit 1
}



