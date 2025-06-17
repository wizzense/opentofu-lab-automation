#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Complete removal of all LabRunner and ValidationOnly references from the codebase
    
.DESCRIPTION
    This script thoroughly removes all remaining LabRunner and ValidationOnly references
    
.PARAMETER DryRun
    Show what would be changed without making modifications
#>

param(
    [switch]$DryRun
)

Write-Host "=== Complete LabRunner and ValidationOnly Removal ===" -ForegroundColor Red

# Define replacement patterns - avoiding duplicates
$patterns = @(
    # Import statements
    @{ Pattern = 'Import-Module\s+LabRunnerLogging[^\r\n]*'; Replacement = 'Import-Module Logging -Force' }
    @{ Pattern = 'Import-Module\s+.*LabRunner[^\r\n]*'; Replacement = '# LabRunner deprecated' }
    
    # Parameter declarations
    @{ Pattern = '\[switch\]\# ValidationOnly removed
    @{ Pattern = 'switch\# ValidationOnly removed
    @{ Pattern = '\# ValidationOnly removed
    
    # Function calls
    @{ Pattern = '[:\s]*\$[^,\s)]*'; Replacement = '' }
    @{ Pattern = '[:\s]*\$true'; Replacement = '' }
    @{ Pattern = '[:\s]*\$false'; Replacement = '' }
    @{ Pattern = ''; Replacement = '' }
    @{ Pattern = 'ValidationOnly\s*=\s*\$true'; Replacement = '' }
    @{ Pattern = 'ValidationOnly\s*=\s*\$false'; Replacement = '' }
    @{ Pattern = 'ValidationOnly\s*:'; Replacement = '' }
    
    # Path references
    @{ Pattern = 'LabRunner\.ps1'; Replacement = 'LabRunner.ps1' }
    @{ Pattern = 'LabRunner\.psd1'; Replacement = 'LabRunner.psd1' }
    @{ Pattern = 'LabRunner\.psm1'; Replacement = 'LabRunner.psm1' }
    @{ Pattern = 'LabRunner/'; Replacement = 'LabRunner/' }
    @{ Pattern = 'LabRunner\\'; Replacement = 'LabRunner\' }
    @{ Pattern = '/LabRunner/'; Replacement = '/LabRunner/' }
    
    # Conditional blocks
    @{ Pattern = 'if\s*\(\s*\# ValidationOnly removed
    
    # General text replacements
    @{ Pattern = 'LabRunner'; Replacement = 'LabRunner' }
    @{ Pattern = 'ValidationOnly(?!able)'; Replacement = 'ValidationOnly' }
    @{ Pattern = 'validation-only'; Replacement = 'validation-only' }
    @{ Pattern = 'validation-only'; Replacement = 'VALIDATION-ONLY' }
    @{ Pattern = 'ValidationOnly'; Replacement = 'VALIDATION' }
)

# JSON-specific patterns
$jsonPatterns = @(
    @{ Pattern = '"LabRunner"[^\r\n]*'; Replacement = '# LabRunner deprecated' }
    @{ Pattern = '"autoTest":\s*"LabRunner[^"]*"'; Replacement = '"autoTest": "LabRunner.New-ValidationTest"' }
    @{ Pattern = '"watchDirectory":\s*"LabRunner[^"]*"'; Replacement = '"watchDirectory": "LabRunner.# Watch-ScriptDirectory deprecated"' }
    @{ Pattern = '"importPath":\s*"/pwsh/modules/LabRunner/"'; Replacement = '"importPath": "/pwsh/modules/LabRunner/"' }
    @{ Pattern = '"LabRunnerGuide"[^\r\n]*'; Replacement = '# LabRunner guide deprecated' }
    @{ Pattern = '"LabRunner":\s*"[^"]*"'; Replacement = '# LabRunner version deprecated' }
    @{ Pattern = '"LabRunner":\s*\{[^}]*\}'; Replacement = '# LabRunner configuration deprecated' }
)

# Get files to process
$filesToProcess = Get-ChildItem -Path $PWD -Recurse -File | Where-Object {
    $_.Extension -match '\.(ps1|psm1|psd1|md|json)$' -and
    $_.FullName -notmatch 'node_modules|\.git|archive|deprecated'
}

$processedCount = 0
$changedFiles = @()

foreach ($file in $filesToProcess) {
    $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }
    
    $originalContent = $content
    $fileChanged = $false
    
    # Apply general patterns
    foreach ($patternInfo in $patterns) {
        if ($content -match $patternInfo.Pattern) {
            $content = $content -replace $patternInfo.Pattern, $patternInfo.Replacement
            $fileChanged = $true
        }
    }
    
    # Apply JSON-specific patterns for JSON files
    if ($file.Extension -eq '.json') {
        foreach ($patternInfo in $jsonPatterns) {
            if ($content -match $patternInfo.Pattern) {
                $content = $content -replace $patternInfo.Pattern, $patternInfo.Replacement
                $fileChanged = $true
            }
        }
    }
    
    # Remove orphaned comment lines
    $content = $content -replace '(?m)^\s*#[^\r\n]*LabRunner[^\r\n]*\r?\n', ''
    $content = $content -replace '(?m)^\s*#[^\r\n]*ValidationOnly[^\r\n]*\r?\n', ''
    
    # Clean up syntax issues
    $content = $content -replace 'param\(\s*\)', ''
    $content = $content -replace 'switch\$false # ValidationOnly removed', '# ValidationOnly removed'
    $content = $content -replace '\$false # ValidationOnly removed', '# ValidationOnly removed'
    $content = $content -replace ':\$false # ValidationOnly removed', ' # ValidationOnly removed'
    
    # Clean up multiple empty lines
    $content = $content -replace '\r?\n\s*\r?\n\s*\r?\n', "`r`n`r`n"
    
    if ($content -ne $originalContent) {
        $fileChanged = $true
    }
    
    if ($fileChanged) {
        $changedFiles += $file.FullName
        
        if ($DryRun) {
            Write-Host "Would modify: $($file.FullName)" -ForegroundColor Yellow
        } else {
            Set-Content -Path $file.FullName -Value $content -NoNewline
            Write-Host "Modified: $($file.FullName)" -ForegroundColor Green
        }
        $processedCount++
    }
}

Write-Host "`n=== Summary ===" -ForegroundColor Green
Write-Host "Files processed: $processedCount" -ForegroundColor White
Write-Host "Mode: $(if ($DryRun) { 'DRY RUN' } else { 'LIVE CHANGES' })" -ForegroundColor $(if ($DryRun) { 'Yellow' } else { 'Green' })

if ($changedFiles.Count -gt 0) {
    Write-Host "`nModified files:" -ForegroundColor White
    $changedFiles | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
}

Write-Host "`nAll LabRunner and ValidationOnly references processed!" -ForegroundColor Green
