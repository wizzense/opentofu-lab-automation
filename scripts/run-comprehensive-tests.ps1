#!/usr/bin/env pwsh
# Run Comprehensive Tests - Executes all validation and test scripts

CmdletBinding()
param(
    Parameter()
    switch$Verbose
)

$ErrorActionPreference = "Stop"

# Set project root path dynamically
$projectRoot = if ($PSScriptRoot) {
    Split-Path $PSScriptRoot -Parent
} else {
    Get-Location  Select-Object -ExpandProperty Path
}

# Import required modules
try {
    $codeFixerPath = Join-Path $projectRoot "pwsh/modules/CodeFixer/"
    Import-Module $codeFixerPath -Force -ErrorAction Stop
    Write-Host "CodeFixer module imported successfully" -ForegroundColor Green
} catch {
    Write-Host "Failed to import CodeFixer module: $_" -ForegroundColor Red
    exit 1
}

try {
    $labRunnerPath = Join-Path $projectRoot "pwsh/modules/LabRunner/"
    Import-Module $labRunnerPath -Force -ErrorAction Stop
    Write-Host "LabRunner module imported successfully" -ForegroundColor Green
} catch {
    Write-Host "Failed to import LabRunner module: $_" -ForegroundColor Red
    exit 1
}

# Run tests
Write-Host "Running comprehensive tests..." -ForegroundColor Yellow

try {
    Invoke-ComprehensiveValidation -Verbose:$Verbose.IsPresent
    Invoke-ParallelLabRunner -Verbose:$Verbose.IsPresent
    Write-Host "All tests completed successfully" -ForegroundColor Green
} catch {
    Write-Host "Tests failed: $_" -ForegroundColor Red
    exit 1
}
