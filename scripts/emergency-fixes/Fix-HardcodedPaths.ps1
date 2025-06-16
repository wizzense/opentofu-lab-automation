#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Fix hardcoded absolute paths in test files to use environment variables
.DESCRIPTION
    Replaces hardcoded paths like "/C:\Users\alexa\..." with proper environment variable references
#>

Param(
    [switch]$DryRun,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# Set up environment variables if not already set
if (-not $env:PROJECT_ROOT) {
    $env:PROJECT_ROOT = (Get-Location).Path
}
if (-not $env:PWSH_MODULES_PATH) {
    $env:PWSH_MODULES_PATH = "$env:PROJECT_ROOT/pwsh/modules"
}

Write-Host "🔧 Fixing hardcoded paths in test files..." -ForegroundColor Cyan
Write-Host "   PROJECT_ROOT: $env:PROJECT_ROOT" -ForegroundColor Yellow
Write-Host "   PWSH_MODULES_PATH: $env:PWSH_MODULES_PATH" -ForegroundColor Yellow

# Find all test files with hardcoded paths
$testFiles = Get-ChildItem -Path "tests/" -Filter "*.Tests.ps1" -Recurse | Where-Object { 
    (Get-Content $_.FullName -Raw) -match 'Import-Module "/C:'
}

Write-Host "📁 Found $($testFiles.Count) files with hardcoded paths" -ForegroundColor Magenta

$fixedCount = 0
$errorCount = 0

foreach ($file in $testFiles) {
    try {
        Write-Host "   Processing: $($file.Name)" -ForegroundColor Gray
        
        $content = Get-Content $file.FullName -Raw
        
        # Replace the malformed import patterns
        $newContent = $content -replace 'Import-Module "/C:\\Users\\alexa\\OneDrive\\Documents\\0\. wizzense\\opentofu-lab-automation\\pwsh/modules/LabRunner/" -ForceImport-Module "/C:\\Users\\alexa\\OneDrive\\Documents\\0\. wizzense\\opentofu-lab-automation\\pwsh/modules/CodeFixer/" -Force', 'Import-Module "$env:PWSH_MODULES_PATH/LabRunner/" -Force
        Import-Module "$env:PWSH_MODULES_PATH/CodeFixer/" -Force'
        
        # Also fix any other hardcoded paths
        $newContent = $newContent -replace 'Import-Module "/C:\\Users\\alexa\\OneDrive\\Documents\\0\. wizzense\\opentofu-lab-automation\\pwsh/modules/', 'Import-Module "$env:PWSH_MODULES_PATH/'
        
        # Fix any remaining absolute paths
        $newContent = $newContent -replace '/C:\\Users\\alexa\\OneDrive\\Documents\\0\. wizzense\\opentofu-lab-automation/', '$env:PROJECT_ROOT/'
        
        if ($newContent -ne $content) {
            if (-not $DryRun) {
                Set-Content -Path $file.FullName -Value $newContent -NoNewline
                Write-Host "   ✅ Fixed: $($file.Name)" -ForegroundColor Green
                $fixedCount++
            } else {
                Write-Host "   🔍 Would fix: $($file.Name)" -ForegroundColor Yellow
            }
        } else {
            Write-Host "   ⏭️  No changes needed: $($file.Name)" -ForegroundColor Gray
        }
        
    } catch {
        Write-Host "   ❌ Error processing $($file.Name): $($_.Exception.Message)" -ForegroundColor Red
        $errorCount++
    }
}

Write-Host "📊 Summary:" -ForegroundColor Cyan
Write-Host "   Files processed: $($testFiles.Count)" -ForegroundColor White
Write-Host "   Files fixed: $fixedCount" -ForegroundColor Green
Write-Host "   Errors: $errorCount" -ForegroundColor Red

if ($DryRun) {
    Write-Host "🚨 DRY RUN - No files were actually modified" -ForegroundColor Yellow
    Write-Host "   Run without -DryRun to apply changes" -ForegroundColor Yellow
}

# Validate one of the fixed files
if ($fixedCount -gt 0 -and -not $DryRun) {
    Write-Host "🔍 Validating fixes..." -ForegroundColor Cyan
    $sampleFile = $testFiles[0]
    $sampleContent = Get-Content $sampleFile.FullName -Raw
    
    if ($sampleContent -notmatch '/C:\\Users\\alexa\\') {
        Write-Host "   ✅ Validation passed - no hardcoded paths found" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Validation warning - some hardcoded paths may remain" -ForegroundColor Yellow
    }
}

Write-Host "🎯 Path fixing complete!" -ForegroundColor Green
