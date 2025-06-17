#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Complete removal of all LabRunner and ValidationOnly references from the codebase
    
.DESCRIPTION
    This script thoroughly removes all remaining LabRunner and ValidationOnly references including:
    - Module imports and references
    - ValidationOnly parameters and functionality
    - Documentation references
    - Configuration file entries
    - JSON manifest entries
    - Comments and deprecated code
    
.PARAMETER DryRun
    Show what would be changed without making modifications
#>

param(
    [switch]$DryRun
)

Write-Host "=== Complete LabRunner and ValidationOnly Removal ===" -ForegroundColor Red

# Define comprehensive replacement patterns
$replacementPatterns = @{
    # Import statements
    'Import-Module\s+LabRunner[^\r\n]*' = '# LabRunner deprecated'
    'Import-Module\s+LabRunnerLogging[^\r\n]*' = 'Import-Module Logging -Force'
    'Import-Module\s+.*LabRunner[^\r\n]*' = '# LabRunner deprecated'
    
    # Parameter declarations
    '\[switch\]\# ValidationOnly removed
    'param\([^)]*\[switch\]\# ValidationOnly removed
    'switch\# ValidationOnly removed
    '\# ValidationOnly removed
    
    # Function calls and references
    '[:\s]*\$[^,\s)]*' = ''
    '[:\s]*\$true' = ''
    '[:\s]*\$false' = ''
    '' = ''
    'ValidationOnly\s*=\s*\$true' = ''
    'ValidationOnly\s*=\s*\$false' = ''
    'ValidationOnly\s*:' = ''
    
    # Path and file references
    'LabRunner\.ps1' = 'LabRunner.ps1'
    'LabRunner\.psd1' = 'LabRunner.psd1'
    'LabRunner\.psm1' = 'LabRunner.psm1'
    'LabRunner/' = 'LabRunner/'
    'LabRunner\\' = 'LabRunner\'
    '/LabRunner/' = '/LabRunner/'
      # Conditional blocks
    'if\s*\(\s*\# ValidationOnly removed
    'if\s*\(\s*\$false\s*#\s*ValidationOnly[^)]*\)\s*\{[^}]*\}' = '# ValidationOnly functionality removed'
    
    # Comments and documentation
    'LabRunner' = 'LabRunner'
    'ValidationOnly(?!able)' = 'ValidationOnly'
    'validation-only' = 'validation-only'
    'validation-only' = 'VALIDATION-ONLY'
    'ValidationOnly' = 'VALIDATION'
}

# JSON-specific replacements for manifest files
$jsonReplacements = @{
    '"LabRunner"[^\r\n]*' = '# LabRunner deprecated'
    '"autoTest":\s*"LabRunner[^"]*"' = '"autoTest": "LabRunner.New-ValidationTest"'
    '"watchDirectory":\s*"LabRunner[^"]*"' = '"watchDirectory": "LabRunner.# Watch-ScriptDirectory deprecated"'
    '"importPath":\s*"/pwsh/modules/LabRunner/"' = '"importPath": "/pwsh/modules/LabRunner/"'
    '"LabRunnerGuide"[^\r\n]*' = '# LabRunner guide deprecated'
    '"LabRunner":\s*"[^"]*"' = '# LabRunner version deprecated'
    '"LabRunner":\s*\{[^}]*\}' = '# LabRunner configuration deprecated'
}

# Get all files to process
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
    
    # Apply general replacements
    foreach ($pattern in $replacementPatterns.Keys) {
        $replacement = $replacementPatterns[$pattern]
        if ($content -match $pattern) {
            $content = $content -replace $pattern, $replacement
            $fileChanged = $true
        }
    }
    
    # Apply JSON-specific replacements for JSON files
    if ($file.Extension -eq '.json') {
        foreach ($pattern in $jsonReplacements.Keys) {
            $replacement = $jsonReplacements[$pattern]
            if ($content -match $pattern) {
                $content = $content -replace $pattern, $replacement
                $fileChanged = $true
            }
        }
    }
    
    # Remove orphaned comment lines
    $content = $content -replace '(?m)^\s*#[^\r\n]*LabRunner[^\r\n]*\r?\n', ''
    $content = $content -replace '(?m)^\s*#[^\r\n]*ValidationOnly[^\r\n]*\r?\n', ''
    $content = $content -replace '(?m)^\s*//[^\r\n]*LabRunner[^\r\n]*\r?\n', ''
    $content = $content -replace '(?m)^\s*//[^\r\n]*ValidationOnly[^\r\n]*\r?\n', ''
    
    # Clean up empty lines and malformed parameter blocks
    $content = $content -replace '(?m)^\s*param\(\s*\)\s*$', ''
    $content = $content -replace '(?m)^(\s*)(param\(\s*)(#[^\r\n]*\r?\n)', '$1$3'
    $content = $content -replace '\r?\n\s*\r?\n\s*\r?\n', "`r`n`r`n"
    
    # Fix syntax issues
    $content = $content -replace 'switch\$false # ValidationOnly removed', '# ValidationOnly removed'
    $content = $content -replace '\$false # ValidationOnly removed', '# ValidationOnly removed'
    $content = $content -replace ':\$false # ValidationOnly removed', ' # ValidationOnly removed'
    
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

# Fix specific problematic files
$problematicFiles = @(
    'src\pwsh\modules\BackupManager\Public\Invoke-BackupMaintenance.ps1',
    'src\pwsh\modules\BackupManager\Public\Invoke-PermanentCleanup.ps1',
    'tests\helpers\TestHelpers.ps1',
    'configs\PROJECT-MANIFEST.json'
)

foreach ($relativePath in $problematicFiles) {
    $fullPath = Join-Path $PWD $relativePath
    if (Test-Path $fullPath) {
        $content = Get-Content -Path $fullPath -Raw
        
        # Remove ValidationOnly parameters completely
        $content = $content -replace '\s*,\s*\[switch\]\# ValidationOnly removed
        $content = $content -replace '\[switch\]\# ValidationOnly removed
        $content = $content -replace 'param\(\s*\[switch\]\# ValidationOnly removed
        
        # Fix parameter syntax in functions
        $content = $content -replace 'param\(\$Results,\s*switch\# ValidationOnly removed
        $content = $content -replace 'switch\# ValidationOnly removed
        
        # Remove function calls with ValidationOnly
        $content = $content -replace ':\# ValidationOnly removed
        $content = $content -replace ':\$true', ''
        $content = $content -replace ':\$false', ''
        
        # Clean up conditional blocks
        $content = $content -replace 'if\s*\(\s*\# ValidationOnly removed
        
        if (-not $DryRun) {
            Set-Content -Path $fullPath -Value $content -NoNewline
            Write-Host "Fixed problematic file: $fullPath" -ForegroundColor Cyan
        } else {
            Write-Host "Would fix problematic file: $fullPath" -ForegroundColor Yellow
        }
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
