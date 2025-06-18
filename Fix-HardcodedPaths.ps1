#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Fix all hardcoded module paths across the project

.DESCRIPTION
    This script systematically finds and fixes all hardcoded module paths
    to use the standardized module discovery system instead of hardcoded paths.
#>

param(
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

Write-Host "=== OpenTofu Lab Automation - Module Path Fixer ===" -ForegroundColor Cyan
Write-Host "Fixing hardcoded module paths to use standardized discovery" -ForegroundColor Yellow

# Get all PowerShell files in the project
$psFiles = Get-ChildItem -Path . -Recurse -Include "*.ps1", "*.psm1", "*.psd1" | Where-Object {
    $_.FullName -notmatch "\\\.git\\" -and
    $_.FullName -notmatch "\\archive\\" -and
    $_.FullName -notmatch "\\backup" -and
    $_.Name -ne "Fix-ModulePaths.ps1"
}

Write-Host "Found $($psFiles.Count) PowerShell files to analyze" -ForegroundColor Green

$filesModified = 0

foreach ($file in $psFiles) {
    try {
        $content = Get-Content $file.FullName -Raw -Encoding UTF8
        $originalContent = $content
        $fileChanged = $false
        
        # Pattern 1: Join-Path with src/pwsh/modules
        if ($content -like '*Join-Path*"src/pwsh/modules*') {
            $content = $content -replace 'Join-Path \$\w+ $env:PWSH_MODULES_PATH', '$env:PWSH_MODULES_PATH'
            $content = $content -replace 'Join-Path \$\w+ "src/pwsh/modules/', 'Join-Path $env:PWSH_MODULES_PATH "'
            $fileChanged = $true
            Write-Host "  Fixed Join-Path in: $($file.Name)" -ForegroundColor Yellow
        }
        
        # Pattern 2: Import-Module with ./src/pwsh/modules paths
        if ($content -like '*Import-Module*./src/pwsh/modules*') {
            $content = $content -replace 'Import-Module [''"]?\./src/pwsh/modules/([^/\s''"]+)[^''"]*[''"]?', 'Import-Module "$1"'
            $fileChanged = $true
            Write-Host "  Fixed Import-Module paths in: $($file.Name)" -ForegroundColor Yellow
        }
        
        # Pattern 3: String literals with src/pwsh/modules
        if ($content -like '*$env:PWSH_MODULES_PATH*' -or $content -like "*$env:PWSH_MODULES_PATH*") {
            $content = $content -replace '$env:PWSH_MODULES_PATH', '$env:PWSH_MODULES_PATH'
            $content = $content -replace "$env:PWSH_MODULES_PATH", '$env:PWSH_MODULES_PATH'
            $fileChanged = $true
            Write-Host "  Fixed string literals in: $($file.Name)" -ForegroundColor Yellow
        }
        
        # Pattern 4: Test-Path with src/pwsh/modules
        if ($content -like '*Test-Path*src/pwsh/modules*') {
            $content = $content -replace 'Test-Path [''"]?\./src/pwsh/modules', 'Test-Path $env:PWSH_MODULES_PATH'
            $content = $content -replace 'Test-Path [''"]?src/pwsh/modules', 'Test-Path $env:PWSH_MODULES_PATH'
            $fileChanged = $true
            Write-Host "  Fixed Test-Path in: $($file.Name)" -ForegroundColor Yellow
        }
        
        # Pattern 5: Get-ChildItem with src/pwsh/modules
        if ($content -like '*Get-ChildItem*src/pwsh/modules*') {
            $content = $content -replace 'Get-ChildItem [''"]?\./src/pwsh/modules[''"]?', 'Get-ChildItem $env:PWSH_MODULES_PATH'
            $content = $content -replace 'Get-ChildItem [''"]?src/pwsh/modules[''"]?', 'Get-ChildItem $env:PWSH_MODULES_PATH'
            $fileChanged = $true
            Write-Host "  Fixed Get-ChildItem in: $($file.Name)" -ForegroundColor Yellow
        }
        
        if ($fileChanged) {
            $filesModified++
            
            # Add environment variable setup if using env vars and not present
            if ($content -like '*$env:PWSH_MODULES_PATH*' -and $content -notlike '*if (-not $env:PWSH_MODULES_PATH)*') {
                $envCheck = @"
# Ensure environment variables are set for admin-friendly module discovery
if (-not `$env:PWSH_MODULES_PATH) {
    `$env:PWSH_MODULES_PATH = Join-Path (Split-Path (Split-Path `$PSScriptRoot -Parent) -Parent) $env:PWSH_MODULES_PATH
}

"@
                # Insert after shebang and param block if they exist
                if ($content -match '#!/usr/bin/env pwsh\s*\n') {
                    $content = $content -replace '(#!/usr/bin/env pwsh\s*\n)', "`$1$envCheck"
                } elseif ($content -match '(?s)param\s*\([^)]*\)\s*\n') {
                    $content = $content -replace '((?s)param\s*\([^)]*\)\s*\n)', "`$1$envCheck"
                } else {
                    $content = "$envCheck$content"
                }
            }
            
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
Write-Host "Files modified: $filesModified" -ForegroundColor Yellow

if ($DryRun) {
    Write-Host "`nThis was a dry run - no files were modified" -ForegroundColor Magenta
    Write-Host "Run without -DryRun to apply changes" -ForegroundColor Magenta
} else {
    Write-Host "`nAll hardcoded module paths have been fixed!" -ForegroundColor Green
    Write-Host "Project now uses admin-friendly environment variable discovery" -ForegroundColor Green
}

