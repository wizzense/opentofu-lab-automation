#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Non-interactive validation test for Windows functionality
.DESCRIPTION
    Tests Windows-specific features without any user prompts
#>

param(
    [switch]$WhatIf
)

Write-Host "=== Windows Functionality Validation Test ===" -ForegroundColor Green

# Test 1: Check if running on Windows-compatible environment
Write-Host "1. Testing OS Detection..." -ForegroundColor Yellow
if ($IsWindows -or $env:OS -eq "Windows_NT") {
    Write-Host "   ✓ Windows environment detected" -ForegroundColor Green
} else {
    Write-Host "   ℹ️ Non-Windows environment (expected in Codespaces)" -ForegroundColor Cyan
}

# Detect the correct project root based on the current environment
if ($IsWindows -or $env:OS -eq "Windows_NT") {
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
} else {
    $ProjectRoot = "/workspaces/opentofu-lab-automation"
}

# Test 2: Test PowerShell module loading
Write-Host "2. Testing PowerShell Module Loading..." -ForegroundColor Yellow
try {
    $modulePath = "$ProjectRoot/pwsh/modules/LabRunner"
    if (Test-Path $modulePath) {
        Import-Module $modulePath -Force
        Write-Host "   ✓ LabRunner module loaded successfully" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️ LabRunner module path not found: $modulePath" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ⚠️ LabRunner module loading failed: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Test 3: Test configuration loading
Write-Host "3. Testing Configuration Loading..." -ForegroundColor Yellow
try {
    $configPath = "$ProjectRoot/configs/config_files/default-config.json"
    if (Test-Path $configPath) {
        $config = Get-Content $configPath | ConvertFrom-Json
        Write-Host "   ✓ Configuration loaded successfully" -ForegroundColor Green
        Write-Host "   ℹ️ Computer Name: $($config.ComputerName)" -ForegroundColor Cyan
    } else {
        Write-Host "   ⚠️ Configuration file not found: $configPath" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ⚠️ Configuration loading failed: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Test 4: Test Windows-specific features (simulated)
Write-Host "4. Testing Windows-specific Features..." -ForegroundColor Yellow
$windowsFeatures = @(
    "Hyper-V Management",
    "Windows Admin Center", 
    "Git for Windows",
    "PowerShell 7+",
    "Chocolatey Package Manager"
)

foreach ($feature in $windowsFeatures) {
    if ($WhatIf) {
        Write-Host "   What if: Would test $feature" -ForegroundColor Magenta
    } else {
        Write-Host "   ℹ️ Would validate: $feature" -ForegroundColor Cyan
    }
}

# Test 5: Test deployment scripts
Write-Host "5. Testing Deployment Scripts..." -ForegroundColor Yellow
$deployScripts = @(    "$ProjectRoot/deploy.py",
    "$ProjectRoot/launcher.py",
    "$ProjectRoot/gui.py"
)

foreach ($script in $deployScripts) {
    if (Test-Path $script) {
        Write-Host "   ✓ Found: $(Split-Path $script -Leaf)" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️ Missing: $(Split-Path $script -Leaf)" -ForegroundColor Yellow
    }
}

Write-Host "=== Validation Complete ===" -ForegroundColor Green
Write-Host "All tests completed without hanging on user input!" -ForegroundColor Green
