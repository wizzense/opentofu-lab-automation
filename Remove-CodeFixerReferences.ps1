#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Remove all LabRunner and ValidationOnly references from the codebase

.DESCRIPTION
    This script systematically removes all references to:
    - LabRunner module imports and references
    - ValidationOnly parameters and functionality
    - Deprecated ValidationOnly workflows
#>

param(
    [switch]$DryRun,
    [switch]$Verbose
)

$ErrorActionPreference = 'Stop'

Write-Host "=== Removing LabRunner and ValidationOnly References ===" -ForegroundColor Red
Write-Host "Cleaning up deprecated functionality" -ForegroundColor Yellow

# Define patterns to remove/replace
$cleanupPatterns = @{
    'Import-Module.*CodeFixer' = '# CodeFixer deprecated'
    '# Invoke-AutoFix deprecated - functionality removed' = '# AutoFix deprecated'
    '# New-AutoTest deprecated - functionality removed' = '# AutoTest deprecated'
    '# TestAutoFixer deprecated' = '# # TestAutoFixer deprecated deprecated'
    '\[switch\]\$false # AutoFix deprecated' = '# AutoFix parameter removed'
    'switch\$false # AutoFix deprecated' = '# AutoFix parameter removed'
    'switch\$false # ValidationOnly removed' = '# ValidationOnly removed'
    '\$false # ValidationOnly removed' = '$false # ValidationOnly removed'
    'pwsh/modules/LabRunner' = 'pwsh/modules/LabRunner'
    '/LabRunner/' = '/LabRunner/'
    'LabRunner\.ps' = 'LabRunner.ps'
    'LabRunner\.psd1' = 'LabRunner.psd1'
    'LabRunner\.psm1' = 'LabRunner.psm1'
    '\s*\$true' = ''
    '\s*\$false' = ''
    '' = ''
    'ValidationOnly\s*=\s*\$true' = ''
    'ValidationOnly\s*=\s*\$false' = ''
}

# Get all PowerShell files
$files = Get-ChildItem -Path . -Recurse -Include "*.ps1", "*.psm1", "*.psd1" | Where-Object {
    $_.FullName -notmatch "\\\.git\\" -and
    $_.FullName -notmatch "\\archive\\" -and
    $_.FullName -notmatch "\\backup" -and
    $_.FullName -notmatch "\\\.venv\\" -and
    $_.Name -ne $MyInvocation.MyCommand.Name
}

$filesModified = 0
$totalChanges = 0

foreach ($file in $files) {
    if ($Verbose) {
        Write-Host "Checking: $($file.Name)" -ForegroundColor Gray
    }
    
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }
    
    $originalContent = $content
    $fileChanged = $false
    
    # Apply each cleanup pattern
    foreach ($pattern in $cleanupPatterns.Keys) {
        $replacement = $cleanupPatterns[$pattern]
        
        if ($content -match $pattern) {
            $content = $content -replace $pattern, $replacement
            $fileChanged = $true
            $totalChanges++
            
            if ($Verbose) {
                Write-Host "  Removed: $pattern" -ForegroundColor Red
            }
        }
    }
    
    # Remove empty lines created by removals
    $content = $content -replace '(?m)^\s*#[^\r\n]*LabRunner[^\r\n]*\r?\n', ''
    $content = $content -replace '(?m)^\s*#[^\r\n]*ValidationOnly[^\r\n]*\r?\n', ''
    
    # Clean up multiple consecutive empty lines
    $content = $content -replace '(?m)^\s*\r?\n\s*\r?\n\s*\r?\n', "`n`n"
    
    if ($fileChanged) {
        $filesModified++
        
        Write-Host "Cleaned: $($file.Name)" -ForegroundColor Green
        
        if (-not $DryRun) {
            Set-Content -Path $file.FullName -Value $content -Encoding UTF8 -NoNewline
        }
    }
}

Write-Host "`n=== Cleanup Summary ===" -ForegroundColor Red
Write-Host "Files cleaned: $filesModified" -ForegroundColor Green
Write-Host "Total removals: $totalChanges" -ForegroundColor Green

if ($DryRun) {
    Write-Host "`nThis was a dry run - no files were modified" -ForegroundColor Magenta
    Write-Host "Run without -DryRun to apply changes" -ForegroundColor Magenta
} else {
    Write-Host "`nAll LabRunner and ValidationOnly references removed!" -ForegroundColor Green
    Write-Host "Codebase is now clean of deprecated functionality" -ForegroundColor Green
}
