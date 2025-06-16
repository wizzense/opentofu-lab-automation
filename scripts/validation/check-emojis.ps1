#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Check for emoji usage in the codebase and optionally fix them
.DESCRIPTION
    This script detects emoji usage in code files and can automatically remove them.
    It's designed to be run in CI/CD or as a pre-commit hook.
.PARAMETER Fix
    Automatically remove emojis found
.PARAMETER ExitOnError
    Exit with error code if emojis are found (useful for CI)
#>

param(
    [switch]$Fix,
    [switch]$ExitOnError
)

# Set strict mode and error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Define emoji patterns (same as purge script but focused on most common ones)
$emojiPatterns = @(
    "🔧", "🚀", "📝", "[PASS]", "[FAIL]", "[WARN]️", "🎯", "📋", "🏗️", "🛠️", "🗂️", "💡", "🔍", "📊", "🧪", "🔄", "⭐", "📚", "🌟", "💻", "🎨", "🔥", "💪", "🚨", "📦", "[INFO]️", "⏳", "🩺", "🛡️"
)

# Build regex pattern
$emojiRegex = "[$($emojiPatterns -join '')]"

# Get the project root
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

# Define file patterns to check
$filePatterns = @(
    "*.ps1",
    "*.py", 
    "*.yml",
    "*.yaml",
    "*.md",
    "*.sh"
)

# Directories to skip
$skipDirs = @(
    "archive",
    "backups", 
    "coverage",
    "build",
    "keys",
    ".git",
    "node_modules"
)

$emojiFound = $false
$filesWithEmojis = @()

foreach ($pattern in $filePatterns) {
    $files = Get-ChildItem -Path $projectRoot -Filter $pattern -Recurse | Where-Object {
        $skip = $false
        foreach ($skipDir in $skipDirs) {
            if ($_.FullName -like "*\$skipDir\*" -or $_.FullName -like "*/$skipDir/*") {
                $skip = $true
                break
            }
        }
        -not $skip
    }
    
    foreach ($file in $files) {
        try {
            $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
            if (-not $content) { continue }
            
            $emojiMatches = [regex]::Matches($content, $emojiRegex)
            
            if ($emojiMatches.Count -gt 0) {
                $emojiFound = $true
                $filesWithEmojis += @{
                    File = $file.FullName
                    Count = $emojiMatches.Count
                    Emojis = $emojiMatches.Value
                }
                
                Write-Host "EMOJI DETECTED: $($file.FullName)" -ForegroundColor Red
                Write-Host "  Count: $($emojiMatches.Count)" -ForegroundColor Yellow
                Write-Host "  Emojis: $($emojiMatches.Value -join ', ')" -ForegroundColor Yellow
                
                if ($Fix) {
                    # Use the purge script to fix this file
                    Write-Host "  FIXING..." -ForegroundColor Green
                    & "$PSScriptRoot\purge-emojis.ps1"
                    Write-Host "  FIXED" -ForegroundColor Green
                    break  # Exit the loop since we fixed all files
                }
            }
        }
        catch {
            Write-Warning "Failed to check $($file.FullName): $($_.Exception.Message)"
        }
    }
    
    # If we fixed emojis, no need to continue checking
    if ($Fix -and $emojiFound) {
        break
    }
}

# Summary
if ($emojiFound) {
    Write-Host "`nEMOJI CHECK RESULT: FAILED" -ForegroundColor Red
    Write-Host "Files with emojis: $($filesWithEmojis.Count)" -ForegroundColor Red
    Write-Host "Total emojis found: $(($filesWithEmojis | ForEach-Object { $_.Count } | Measure-Object -Sum).Sum)" -ForegroundColor Red
    
    if (-not $Fix) {
        Write-Host "`nTo fix automatically, run:" -ForegroundColor Yellow
        Write-Host "  pwsh -File `"$PSCommandPath`" -Fix" -ForegroundColor Yellow
        Write-Host "OR run the full purge script:" -ForegroundColor Yellow
        Write-Host "  pwsh -File `"$PSScriptRoot\purge-emojis.ps1`"" -ForegroundColor Yellow
    }
    
    if ($ExitOnError) {
        exit 1
    }
} else {
    Write-Host "EMOJI CHECK RESULT: PASSED" -ForegroundColor Green
    Write-Host "No emojis detected in codebase" -ForegroundColor Green
}
