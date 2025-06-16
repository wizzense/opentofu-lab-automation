#!/usr/bin/env pwsh
# Test script to verify path handling with spaces

Write-Host "=== PATH HANDLING WITH SPACES TEST ===" -ForegroundColor Cyan

# Current directory
$currentDir = Get-Location
Write-Host "Current directory: $currentDir" -ForegroundColor Green
Write-Host "Contains spaces: $($currentDir -like '* *')" -ForegroundColor Yellow

# Test various path operations
$testPaths = @(
    "tests\TestHelpers.ps1",
    "pwsh\modules\LabRunner\LabRunner.psd1",
    "scripts\utilities\purge-emojis-v2.ps1"
)

Write-Host "`n=== TESTING PATH OPERATIONS ===" -ForegroundColor Cyan

foreach ($relativePath in $testPaths) {
    Write-Host "`nTesting: $relativePath" -ForegroundColor Yellow
    
    # Method 1: Join-Path
    $joinedPath = Join-Path $currentDir $relativePath
    Write-Host "  Join-Path result: $joinedPath" -ForegroundColor White
    Write-Host "  Exists (Join-Path): $(Test-Path $joinedPath)" -ForegroundColor $(if (Test-Path $joinedPath) { "Green" } else { "Red" })
    
    # Method 2: String concatenation
    $concatPath = "$currentDir\$relativePath"
    Write-Host "  Concat result: $concatPath" -ForegroundColor White
    Write-Host "  Exists (Concat): $(Test-Path $concatPath)" -ForegroundColor $(if (Test-Path $concatPath) { "Green" } else { "Red" })
    
    # Method 3: Resolve-Path
    try {
        $resolvedPath = Resolve-Path $relativePath -ErrorAction Stop
        Write-Host "  Resolve-Path result: $resolvedPath" -ForegroundColor White
        Write-Host "  Exists (Resolve-Path): True" -ForegroundColor Green
    } catch {
        Write-Host "  Resolve-Path failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n=== TESTING QUOTED PATHS ===" -ForegroundColor Cyan

# Test with quoted paths (for command line execution)
$quotedPath = "`"$currentDir`""
Write-Host "Quoted path: $quotedPath" -ForegroundColor White

# Test PowerShell execution with spaces
Write-Host "`n=== TESTING POWERSHELL EXECUTION ===" -ForegroundColor Cyan

$testScript = Join-Path $currentDir "tests\TestHelpers.ps1"
if (Test-Path $testScript) {
    Write-Host "Testing PowerShell execution with spaces in path..." -ForegroundColor Yellow
    
    # Method 1: Direct execution
    try {
        $result = & $testScript -ErrorAction Stop 2>&1
        Write-Host "  Direct execution: SUCCESS" -ForegroundColor Green
    } catch {
        Write-Host "  Direct execution: FAILED - $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Method 2: Quoted execution
    try {
        $result = & "`"$testScript`"" -ErrorAction Stop 2>&1
        Write-Host "  Quoted execution: SUCCESS" -ForegroundColor Green
    } catch {
        Write-Host "  Quoted execution: FAILED - $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n=== TEST COMPLETE ===" -ForegroundColor Cyan
