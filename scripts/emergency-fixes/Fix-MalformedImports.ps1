#!/usr/bin/env pwsh
#Requires -Version 7.0

<#
.SYNOPSIS
    Emergency fix for malformed Import-Module statements with repeated -Force parameters
    
.DESCRIPTION
    This script fixes the catastrophic damage caused by AutoFix repeatedly appending -Force parameters
    to Import-Module statements, creating statements like:
    Import-Module "path" -Force.PARAMETER TargetPath
    Path to scan and fix (defaults to current directory)
    
.PARAMETER BackupBeforeFix
    Create backup before fixing (default: true)
    
.PARAMETER WhatIf
    Show what would be fixed without making changes
#>

param(
    string$TargetPath = ".",
    bool$BackupBeforeFix = $true,
    switch$WhatIf
)

$ErrorActionPreference = "Stop"

Write-Host "=== EMERGENCY FIX: Malformed Import-Module Statements ===" -ForegroundColor Red
Write-Host "Scanning for files with repeated -Force parameters..." -ForegroundColor Yellow

# Find all PowerShell files with malformed imports
$malformedFiles = Get-ChildItem -Path $TargetPath -Recurse -Filter "*.ps1"  Where-Object {
    $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
    $content -match 'Import-Module.*?-Force.*?-Force'
}

Write-Host "Found $($malformedFiles.Count) files with malformed imports" -ForegroundColor Cyan

if ($malformedFiles.Count -eq 0) {
    Write-Host "No malformed imports found!" -ForegroundColor Green
    exit 0
}

# Create backup if requested
if ($BackupBeforeFix -and -not $WhatIf) {
    $backupPath = "./backups/emergency-import-fix-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
    Write-Host "Creating backup at: $backupPath" -ForegroundColor Yellow
}

$fixedCount = 0
$totalIssues = 0

foreach ($file in $malformedFiles) {
    Write-Host "`nProcessing: $($file.FullName)" -ForegroundColor Cyan
    
    $content = Get-Content $file.FullName -Raw
    $originalContent = $content
    
    # Count malformed imports in this file
    $malformedImports = regex::Matches($content, 'Import-Module.*?(-Force\s+){2,}')
    $totalIssues += $malformedImports.Count
    
    Write-Host "  Found $($malformedImports.Count) malformed import(s)" -ForegroundColor Yellow
    
    foreach ($match in $malformedImports) {
        Write-Host "  BEFORE: $($match.Value)" -ForegroundColor Red
    }
    
    # Fix pattern 1: Multiple -Force parameters
    $content = $content -replace 'Import-Module\s+"(^"+)"\s+(-Force\s*)+', 'Import-Module "$1" -Force'
    $content = $content -replace "Import-Module\s+'(^'+)'\s+(-Force\s*)+", "Import-Module '$1' -Force"
    $content = $content -replace 'Import-Module\s+(^\s+)\s+(-Force\s*)+', 'Import-Module $1 -Force'
    
    # Fix pattern 2: Malformed paths with double slashes
    $content = $content -replace '//pwsh/modules/', '/pwsh/modules/'
    $content = $content -replace 'C:\\Users\\alexa\\OneDrive\\Documents\\0\. wizzense\\opentofu-lab-automation//pwsh', '/pwsh'
    $content = $content -replace '/C:\\Users\\alexa\\OneDrive\\Documents\\0\. wizzense\\opentofu-lab-automation\pwsh', '/pwsh'
    
    # Normalize to standard import pattern
    $content = $content -replace 'Import-Module\s+"?/C:\\^"*?/pwsh/modules/(^/"+)/?^"*"?\s+-Force', 'Import-Module "/pwsh/modules/$1/" -Force'
    $content = $content -replace 'Import-Module\s+"?/C:\\^"*?pwsh/modules/(^/"+)/?^"*"?\s+-Force', 'Import-Module "/pwsh/modules/$1/" -Force'
    
    if ($content -ne $originalContent) {
        if ($WhatIf) {
            Write-Host "  WOULD FIX: $($file.FullName)" -ForegroundColor Green
        } else {
            # Backup original file
            if ($BackupBeforeFix) {
                $relativePath = $file.FullName.Replace($PWD.Path, "").TrimStart('\', '/')
                $backupFilePath = Join-Path $backupPath $relativePath
                $backupDir = Split-Path $backupFilePath -Parent
                New-Item -ItemType Directory -Path $backupDir -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item $file.FullName $backupFilePath -Force
            }
            
            # Apply fix
            Set-Content -Path $file.FullName -Value $content -Encoding UTF8
            Write-Host "  FIXED: $($file.FullName)" -ForegroundColor Green
            $fixedCount++
            
            # Show fixed imports
            $fixedImports = regex::Matches($content, 'Import-Module^\r\n+')
            foreach ($match in $fixedImports) {
                Write-Host "  AFTER:  $($match.Value)" -ForegroundColor Green
            }
        }
    }
}

Write-Host "`n=== SUMMARY ===" -ForegroundColor Cyan
Write-Host "Files scanned: $($malformedFiles.Count)" -ForegroundColor White
Write-Host "Total malformed imports: $totalIssues" -ForegroundColor White
if ($WhatIf) {
    Write-Host "Files that would be fixed: $fixedCount" -ForegroundColor Yellow
    Write-Host "Run without -WhatIf to apply fixes" -ForegroundColor Yellow
} else {
    Write-Host "Files fixed: $fixedCount" -ForegroundColor Green
    if ($BackupBeforeFix) {
        Write-Host "Backup location: $backupPath" -ForegroundColor Cyan
    }
}

