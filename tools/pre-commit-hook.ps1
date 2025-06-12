#!/usr/bin/env pwsh
#Requires -Version 5.1
<#
.SYNOPSIS
    Pre-commit hook to validate PowerShell scripts

.DESCRIPTION
    This hook runs before each commit to ensure:
    - All PowerShell scripts have valid syntax
    - Param blocks are positioned correctly
    - Import-Module statements come after Param blocks
    - Scripts follow project conventions

.NOTES
    Install: Copy to .git/hooks/pre-commit (remove .ps1 extension)
    Make executable: chmod +x .git/hooks/pre-commit
#>

$ErrorActionPreference = 'Stop'

# Check if we're in a git repository
if (-not (Test-Path '.git')) {
    Write-Host "❌ Not in a git repository" -ForegroundColor Red
    exit 1
}

Write-Host "🔍 Pre-commit PowerShell validation..." -ForegroundColor Cyan

# Get staged PowerShell files
$stagedFiles = git diff --cached --name-only --diff-filter=ACM | Where-Object { $_ -match '\.ps1$' }

if ($stagedFiles.Count -eq 0) {
    Write-Host "✅ No PowerShell files to validate" -ForegroundColor Green
    exit 0
}

Write-Host "Validating $($stagedFiles.Count) PowerShell files..." -ForegroundColor White

$hasErrors = $false

foreach ($file in $stagedFiles) {
    if (-not (Test-Path $file)) {
        continue  # File might be deleted
    }
    
    Write-Host "Checking: $file" -ForegroundColor Gray
    
    # Test 1: Basic syntax
    try {
        $content = Get-Content $file -Raw -ErrorAction Stop
        [System.Management.Automation.PSParser]::Tokenize($content, [ref]$null) | Out-Null
    } catch {
        Write-Host "  ❌ SYNTAX ERROR: $($_.Exception.Message)" -ForegroundColor Red
        $hasErrors = $true
        continue
    }
    
    # Test 2: Param block positioning (for runner scripts)
    if ($file -like "*runner_scripts*") {
        $lines = Get-Content $file -ErrorAction Stop
        $firstExecutableLine = -1
        $paramLineIndex = -1
        $importLineIndex = -1
        
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i].Trim()
            
            # Skip comments and empty lines
            if ($line -eq '' -or $line.StartsWith('#') -or $line.StartsWith('<#')) {
                continue
            }
            
            if ($firstExecutableLine -eq -1) {
                $firstExecutableLine = $i
            }
            
            if ($line.StartsWith('Param(')) {
                $paramLineIndex = $i
            }
            
            if ($line -match "^Import-Module.*LabRunner.*-Force") {
                $importLineIndex = $i
            }
        }
        
        # Check Param block is first
        if ($paramLineIndex -ne -1 -and $paramLineIndex -ne $firstExecutableLine) {
            Write-Host "  ❌ PARAM ERROR: Param block must be the first executable statement" -ForegroundColor Red
            $hasErrors = $true
        }
        
        # Check Import-Module comes after Param
        if ($importLineIndex -ne -1 -and $paramLineIndex -ne -1 -and $importLineIndex -lt $paramLineIndex) {
            Write-Host "  ❌ IMPORT ERROR: Import-Module must come after Param block" -ForegroundColor Red
            $hasErrors = $true
        }
        
        # Check required elements exist
        if ($paramLineIndex -eq -1) {
            Write-Host "  ⚠️  WARNING: No Param block found in runner script" -ForegroundColor Yellow
        }
        
        if ($importLineIndex -eq -1 -and $file -like "*runner_scripts*") {
            Write-Host "  ⚠️  WARNING: No LabRunner import found in runner script" -ForegroundColor Yellow
        }
    }
    
    if (-not $hasErrors) {
        Write-Host "  ✅ Valid" -ForegroundColor Green
    }
}

if ($hasErrors) {
    Write-Host "`n❌ Pre-commit validation FAILED!" -ForegroundColor Red -BackgroundColor Black
    Write-Host "Fix the errors above before committing." -ForegroundColor Red
    Write-Host "`nTo auto-fix common issues, run:" -ForegroundColor Yellow
    Write-Host "  pwsh tools/Validate-PowerShellScripts.ps1 -Path . -Fix" -ForegroundColor Cyan
    exit 1
} else {
    Write-Host "`n✅ All PowerShell files are valid!" -ForegroundColor Green -BackgroundColor Black
    exit 0
}
