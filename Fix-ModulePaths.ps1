#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Fix all hardcoded module paths across the project

.DESCRIPTION
    This script systematically finds and fixes all hardcoded module paths
    to use the standardized module discovery system instead of hardcoded paths.
    This will make the project admin-friendly by removing path dependencies.
#>

param(
    [switch]$DryRun,
    [switch]$Verbose
)

$ErrorActionPreference = 'Stop'

Write-Host "=== OpenTofu Lab Automation - Module Path Fixer ===" -ForegroundColor Cyan
Write-Host "Fixing hardcoded module paths to use standardized discovery" -ForegroundColor Yellow

# Get all PowerShell files in the project
$psFiles = Get-ChildItem -Path . -Recurse -Include "*.ps1", "*.psm1", "*.psd1" | Where-Object {
    $_.FullName -notmatch "\\\.git\\" -and
    $_.FullName -notmatch "\\archive\\" -and
    $_.FullName -notmatch "\\backup"
}

Write-Host "Found $($psFiles.Count) PowerShell files to analyze" -ForegroundColor Green

$changes = 0
$filesModified = 0

foreach ($file in $psFiles) {
    if ($Verbose) {
        Write-Host "Analyzing: $($file.Name)" -ForegroundColor Gray
    }
    
    try {
        $content = Get-Content $file.FullName -Raw -Encoding UTF8
        $originalContent = $content
        $fileChanged = $false
        
        # Fix 1: Direct module path imports
        if ($content -match 'Join-Path.*"src/pwsh/modules') {
            $content = $content -replace 'Join-Path \$\w+ "src/pwsh/modules([^"]*)"', 'Join-Path $env:PWSH_MODULES_PATH "$1"'
            $fileChanged = $true
            if ($Verbose) { Write-Host "  Fixed direct module path join" -ForegroundColor Yellow }
        }
          # Fix 2: Import-Module with hardcoded paths
        if ($content -match 'Import-Module.*[''"]\.\/src\/pwsh\/modules') {
            $content = $content -replace 'Import-Module [''"]\.\/src\/pwsh\/modules\/([^\/''\"]+).*[''"]', 'Import-Module "$1"'
            $fileChanged = $true
            if ($Verbose) { Write-Host "  Fixed Import-Module hardcoded path" -ForegroundColor Yellow }
        }
        
        # Fix 3: Import-Module with relative src/pwsh/modules paths
        if ($content -match 'Import-Module.*[''"]src\/pwsh\/modules') {
            $content = $content -replace 'Import-Module [''"]src\/pwsh\/modules\/([^\/''\"]+).*[''"]', 'Import-Module "$1"'
            $fileChanged = $true
            if ($Verbose) { Write-Host "  Fixed Import-Module relative path" -ForegroundColor Yellow }
        }
        
        # Fix 4: Test-Path with hardcoded module paths
        if ($content -match 'Test-Path.*[''"]\.\/src\/pwsh\/modules') {
            $content = $content -replace 'Test-Path [''"]\.\/src\/pwsh\/modules\/([^\/''\"]+)', 'Test-Path (Join-Path $env:PWSH_MODULES_PATH "$1")'
            $fileChanged = $true
            if ($Verbose) { Write-Host "  Fixed Test-Path hardcoded path" -ForegroundColor Yellow }
        }
        
        # Fix 5: Get-ChildItem with hardcoded module paths
        if ($content -match 'Get-ChildItem.*[''"]\.\/src\/pwsh\/modules') {
            $content = $content -replace 'Get-ChildItem [''"]\.\/src\/pwsh\/modules[''"]', 'Get-ChildItem $env:PWSH_MODULES_PATH'
            $fileChanged = $true
            if ($Verbose) { Write-Host "  Fixed Get-ChildItem hardcoded path" -ForegroundColor Yellow }
        }
        
        # Fix 6: String literals with hardcoded paths  
        if ($content -match '[''"]src\/pwsh\/modules[''"]') {
            $content = $content -replace '[''"]src\/pwsh\/modules[''"]', '$env:PWSH_MODULES_PATH'
            $fileChanged = $true
            if ($Verbose) { Write-Host "  Fixed string literal path" -ForegroundColor Yellow }
        }
        
        # Fix 7: PSScriptRoot joins with old structure
        if ($content -match '\$PSScriptRoot.*"src\/pwsh\/modules') {
            $content = $content -replace 'Join-Path \$PSScriptRoot "src\/pwsh\/modules"', '$env:PWSH_MODULES_PATH'
            $fileChanged = $true
            if ($Verbose) { Write-Host "  Fixed PSScriptRoot join" -ForegroundColor Yellow }
        }
        
        # Add environment variable fallback if not present
        if ($fileChanged -and $content -notmatch '\$env:PWSH_MODULES_PATH' -and $content -notmatch 'PROJECT_ROOT') {
            $fallbackCode = @"
# Ensure environment variables are set
if (-not `$env:PWSH_MODULES_PATH) {
    `$env:PWSH_MODULES_PATH = Join-Path (Split-Path (Split-Path `$PSScriptRoot -Parent) -Parent) "src/pwsh/modules"
}
"@
            # Insert after any existing param block or at the beginning
            if ($content -match '(?s)param\s*\([^)]*\)') {
                $content = $content -replace '((?s)param\s*\([^)]*\))', "`$1`n`n$fallbackCode"
            } else {
                $content = "$fallbackCode`n`n$content"
            }
            if ($Verbose) { Write-Host "  Added environment variable fallback" -ForegroundColor Yellow }
        }
        
        if ($fileChanged) {
            $changes++
            $filesModified++
            
            if (-not $DryRun) {
                Set-Content -Path $file.FullName -Value $content -Encoding UTF8 -NoNewline
                Write-Host "[SYMBOL] Updated: $($file.Name)" -ForegroundColor Green
            } else {
                Write-Host "[SYMBOL] Would update: $($file.Name)" -ForegroundColor DarkGreen
            }
        }
        
    } catch {
        Write-Warning "Error processing $($file.FullName): $($_.Exception.Message)"
    }
}

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "Files analyzed: $($psFiles.Count)" -ForegroundColor White
Write-Host "Files with changes: $filesModified" -ForegroundColor Yellow
Write-Host "Total changes: $changes" -ForegroundColor Yellow

if ($DryRun) {
    Write-Host "`nThis was a dry run - no files were modified" -ForegroundColor Magenta
    Write-Host "Run without -DryRun to apply changes" -ForegroundColor Magenta
} else {
    Write-Host "`nAll hardcoded module paths have been fixed!" -ForegroundColor Green
    Write-Host "Project now uses standardized environment variable discovery" -ForegroundColor Green
}

