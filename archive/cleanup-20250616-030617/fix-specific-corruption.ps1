#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Targeted fix for specific PatchManager import corruption pattern
.DESCRIPTION
    Fixes the specific pattern: Import-Module "/path" -Force Import-Module "/path" -Force
    which should be two separate lines
#>

CmdletBinding()
param(
    switch$DryRun
)

$ErrorActionPreference = "Stop"

Write-Host "� TARGETED CORRUPTION FIX" -ForegroundColor Red
Write-Host "Fixing pattern: Import-Module '/path' -Force Import-Module '/path' -Force" -ForegroundColor Yellow

# Get correct paths from manifest
$manifestPath = "PROJECT-MANIFEST.json"
$manifest = Get-Content $manifestPath  ConvertFrom-Json

$correctPaths = @{
    "LabRunner" = "../pwsh/modules/LabRunner/"
    "CodeFixer" = "../pwsh/modules/CodeFixer/"
    "BackupManager" = "../pwsh/modules/BackupManager/"
    "PatchManager" = "../pwsh/modules/PatchManager/"
}

# Find all test files
$testFiles = Get-ChildItem -Path "tests" -Filter "*.Tests.ps1"

Write-Host "Found $($testFiles.Count) test files to check" -ForegroundColor Cyan

$corruptedFiles = @()
$fixCount = 0

foreach ($testFile in $testFiles) {
    $content = Get-Content $testFile.FullName -Raw
    $originalContent = $content
    
    # Look for the specific corruption pattern
    $corruptionPattern = 'Import-Module\s+"^"*"\s+-Force\s+Import-Module\s+"^"*"\s+-Force'
    
    if ($content -match $corruptionPattern) {
        Write-Host "CORRUPTED: $($testFile.Name)" -ForegroundColor Red
        $corruptedFiles += $testFile
        
        # Fix the pattern by separating the imports onto separate lines
        $fixed = $content -replace 'Import-Module\s+"(^"*pwsh/modules/LabRunner^"*?)"\s+-Force\s+Import-Module\s+"(^"*pwsh/modules/CodeFixer^"*?)"\s+-Force', 
            "Import-Module `"../pwsh/modules/LabRunner/`" -Force`n        Import-Module `"../pwsh/modules/CodeFixer/`" -Force"
        
        # Also handle any other similar patterns
        $fixed = $fixed -replace 'Import-Module\s+"(^"*?)"\s+-Force\s+Import-Module\s+"(^"*?)"\s+-Force', 
            "Import-Module `"`$1`" -Force`n        Import-Module `"`$2`" -Force"
        
        # Fix absolute paths to relative paths
        $fixed = $fixed -replace 'Import-Module\s+"/pwsh/modules/(^/+)/"', '

Import-Module "../pwsh/modules/$1/"'
        
        if ($fixed -ne $content) {
            $fixCount++
            
            if (-not $DryRun) {
                Set-Content -Path $testFile.FullName -Value $fixed -Encoding UTF8
                Write-Host "  PASS FIXED" -ForegroundColor Green
            } else {
                Write-Host "  � WOULD FIX" -ForegroundColor Yellow
            }
        }
    }
}

Write-Host "`n SUMMARY:" -ForegroundColor Cyan
Write-Host "  Corrupted files found: $($corruptedFiles.Count)" -ForegroundColor $(if($corruptedFiles.Count -gt 0) { 'Red' } else { 'Green' })
Write-Host "  Files that would be fixed: $fixCount" -ForegroundColor Yellow

if ($DryRun) {
    Write-Host "`n� DRY RUN MODE - No changes applied" -ForegroundColor Yellow
    Write-Host "Run without -DryRun to apply fixes" -ForegroundColor Yellow
} else {
    Write-Host "`nPASS FIXES APPLIED!" -ForegroundColor Green
}

if ($corruptedFiles.Count -gt 0) {
    Write-Host "`nCorrupted files:" -ForegroundColor Red
    corruptedFiles | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor Red }
}

