#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Fix all remaining hardcoded module imports to use admin-friendly module names

.DESCRIPTION
    This script fixes all hardcoded Import-Module statements that use paths
    instead of module names, making the project completely admin-friendly.
#>

param(
    [switch]$DryRun,
    [switch]$Verbose
)

$ErrorActionPreference = 'Stop'

Write-Host "=== Fixing All Hardcoded Module Imports ===" -ForegroundColor Cyan
Write-Host "Converting hardcoded paths to admin-friendly module names" -ForegroundColor Yellow

# Define the patterns to fix
$patterns = @{
    # PSScriptRoot-based paths
    'Import-Module "\$PSScriptRoot[/\\]modules[/\\]LabRunner[/\\]?" -Force\)' = 'Import-Module "LabRunner" -Force'
    'Import-Module "\$PSScriptRoot[/\\]modules[/\\]LabRunner[/\\]?" -Force' = 'Import-Module "LabRunner" -Force'
    'Import-Module "\$PSScriptRoot[/\\]modules[/\\]PatchManager[/\\]?" -Force' = 'Import-Module "PatchManager" -Force'
    'Import-Module "\$PSScriptRoot[/\\]modules[/\\]Logging[/\\]?" -Force' = 'Import-Module "Logging" -Force'
    '# LabRunner deprecated
    
    # PWSH_MODULES_PATH-based paths  
    'Import-Module "\$env:PWSH_MODULES_PATH[/\\]LabRunner[/\\]?" -Force' = 'Import-Module "LabRunner" -Force'
    'Import-Module "\$env:PWSH_MODULES_PATH[/\\]PatchManager[/\\]?" -Force' = 'Import-Module "PatchManager" -Force'
    'Import-Module "\$env:PWSH_MODULES_PATH[/\\]Logging[/\\]?" -Force' = 'Import-Module "Logging" -Force'
    '# LabRunner deprecated
    'Import-Module "\$env:PWSH_MODULES_PATH[/\\]DevEnvironment[/\\]?" -Force' = 'Import-Module "DevEnvironment" -Force'
    
    # Join-Path patterns
    'Import-Module \(Join-Path \$PSScriptRoot "[^"]*LabRunner[^"]*"\) -Force' = 'Import-Module "LabRunner" -Force'
    'Import-Module \(Join-Path \$PSScriptRoot "[^"]*PatchManager[^"]*"\) -Force' = 'Import-Module "PatchManager" -Force'
    'Import-Module \(Join-Path \$PSScriptRoot "[^"]*Logging[^"]*"\) -Force' = 'Import-Module "Logging" -Force'
    '# LabRunner deprecated
}

# Get all PowerShell files
$files = Get-ChildItem -Path . -Recurse -Include "*.ps1", "*.psm1" | Where-Object {
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
    
    # Apply each pattern
    foreach ($pattern in $patterns.Keys) {
        $replacement = $patterns[$pattern]
        
        if ($content -match $pattern) {
            $content = $content -replace $pattern, $replacement
            $fileChanged = $true
            
            if ($Verbose) {
                Write-Host "  Fixed: $pattern" -ForegroundColor Yellow
            }
        }
    }
    
    # Also fix the specific syntax errors with ) at the end
    if ($content -match 'Import-Module "[^"]*" -Force\)') {
        $content = $content -replace '(Import-Module "[^"]*" -Force)\)', '$1'
        $fileChanged = $true
        
        if ($Verbose) {
            Write-Host "  Fixed trailing parenthesis" -ForegroundColor Yellow
        }
    }
    
    if ($fileChanged) {
        $filesModified++
        $totalChanges++
        
        Write-Host "Fixed imports in: $($file.Name)" -ForegroundColor Green
        
        if (-not $DryRun) {
            Set-Content -Path $file.FullName -Value $content -Encoding UTF8 -NoNewline
        }
    }
}

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "Files modified: $filesModified" -ForegroundColor Green
Write-Host "Total changes: $totalChanges" -ForegroundColor Green

if ($DryRun) {
    Write-Host "`nThis was a dry run - no files were modified" -ForegroundColor Magenta
    Write-Host "Run without -DryRun to apply changes" -ForegroundColor Magenta
} else {
    Write-Host "`nAll hardcoded imports have been fixed!" -ForegroundColor Green
    Write-Host "Project now uses admin-friendly module names" -ForegroundColor Green
}
