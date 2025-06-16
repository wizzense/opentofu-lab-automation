#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Purge all emojis from the OpenTofu Lab Automation codebase
.DESCRIPTION
    This script removes all emojis from scripts, YAML files, and documentation
    to prevent parsing/matching issues in validation scripts.
.PARAMETER DryRun
    Show what would be changed without making actual changes
.PARAMETER Verbose
    Show detailed information about changes
#>

param(
    switch$DryRun,
    switch$Verbose
)

# Set strict mode and error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "EMOJI PURGE UTILITY" -ForegroundColor Cyan
Write-Host "Removing all emojis from codebase to prevent parsing issues" -ForegroundColor Yellow

# Define comprehensive emoji patterns
$emojiPatterns = @(
    # Unicode emoji ranges
    '[\u{1F300}-\u{1F5FF}]',     # Misc Symbols and Pictographs
    '[\u{1F600}-\u{1F64F}]',     # Emoticons
    '[\u{1F680}-\u{1F6FF}]',     # Transport and Map Symbols
    '[\u{1F700}-\u{1F77F}]',     # Alchemical Symbols
    '[\u{1F780}-\u{1F7FF}]',     # Geometric Shapes Extended
    '[\u{1F800}-\u{1F8FF}]',     # Supplemental Arrows-C
    '[\u{1F900}-\u{1F9FF}]',     # Supplemental Symbols and Pictographs
    '[\u{1FA00}-\u{1FA6F}]',     # Chess Symbols
    '[\u{1FA70}-\u{1FAFF}]',     # Symbols and Pictographs Extended-A
    '[\u{2600}-\u{26FF}]',       # Miscellaneous Symbols
    '[\u{2700}-\u{27BF}]',       # Dingbats
    '[\u{FE00}-\u{FE0F}]',       # Variation Selectors
    '[\u{1F1E0}-\u{1F1FF}]',     # Regional Indicator Symbols
    
    # Common emoji sequences and text representations
    ':\w+:',                      # :emoji_name: format
    '\u{1F44D}',                  # Thumbs up
    '\u{1F44E}',                  # Thumbs down
    '\u{2764}',                   # Red heart
    '\u{2705}',                   # Check mark
    '\u{274C}',                   # Cross mark
    '\u{2728}',                   # Sparkles
    '\u{1F389}',                  # Party popper
    '\u{1F680}',                  # Rocket
    '\u{26A0}',                   # Warning sign
    '\u{2139}',                   # Information
    '\u{1F4A1}',                  # Light bulb
    '\u{1F6AB}',                  # Prohibited
    
    # Specific problematic emojis found in attachments
    'emoji',                      # Literal text "emoji" (case-insensitive)
    'EMOJI',                      # Uppercase version
    '🚫', '⚠️', '💡', '🎉',       # Specific emojis seen in code
    '✅', '❌', '🔍', '📝',       # More specific ones
    '🛡️', '🎯', '⭐', '🔧'        # Additional ones from docs
)

# Create combined regex pattern
$emojiRegex = "($($emojiPatterns -join '|'))"

# Get the project root
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

# Define file patterns to process
$filePatterns = @(
    "*.ps1",
    "*.py", 
    "*.yml",
    "*.yaml",
    "*.md",
    "*.txt",
    "*.json",
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

Write-Host "Scanning project: $projectRoot" -ForegroundColor Green

$totalFiles = 0
$changedFiles = 0
$totalEmojisRemoved = 0

foreach ($pattern in $filePatterns) {
    $files = Get-ChildItem -Path $projectRoot -Filter $pattern -Recurse | Where-Object{
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
        $totalFiles++
        
        try {
            $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
            if (-not $content) { continue }
            
            # Count emojis in this file
            $emojiMatches = regex::Matches($content, $emojiRegex)
            
            if ($emojiMatches.Count -gt 0) {
                if ($Verbose) {
                    Write-Host "Processing: $($file.FullName)" -ForegroundColor Yellow
                    Write-Host "  Found $($emojiMatches.Count) emojis" -ForegroundColor DarkYellow
                }
                  # Professional replacements for common emojis
                $replacements = @{
                    # Status indicators
                    '\u{2705}' = 'PASS'           # ✅ Check mark
                    '\u{274C}' = 'FAIL'           # ❌ Cross mark  
                    '\u{26A0}\u{FE0F}?' = 'WARNING'  # ⚠️ Warning
                    '\u{2139}\u{FE0F}?' = 'INFO'     # ℹ️ Information
                    '\u{1F44D}' = 'SUCCESS'       # 👍 Thumbs up
                    '\u{1F44E}' = 'FAILURE'       # 👎 Thumbs down
                    '\u{1F6AB}' = 'BLOCKED'       # 🚫 Prohibited
                    
                    # Action indicators  
                    '\u{1F680}' = 'LAUNCH'        # 🚀 Rocket
                    '\u{1F4A1}' = 'TIP'           # 💡 Light bulb
                    '\u{2728}' = 'ENHANCED'       # ✨ Sparkles
                    '\u{1F389}' = 'COMPLETE'      # 🎉 Party popper
                    '\u{1F3AF}' = 'TARGET'        # 🎯 Direct hit
                    '\u{1F527}' = 'TOOL'          # 🔧 Wrench
                    '\u{1F4DD}' = 'NOTE'          # 📝 Memo
                    '\u{1F50D}' = 'SEARCH'        # 🔍 Magnifying glass
                    '\u{1F6E1}\u{FE0F}?' = 'PROTECTED'  # 🛡️ Shield
                    '\u{2B50}' = 'FEATURED'       # ⭐ Star
                    
                    # Hearts and emotions (remove entirely)
                    '\u{2764}\u{FE0F}?' = ''      # ❤️ Red heart
                    '\u{1F494}' = ''              # 💔 Broken heart
                    '\u{1F60A}' = ''              # 😊 Smiling face
                    '\u{1F62D}' = ''              # 😭 Crying face
                    
                    # Literal text patterns
                    '(?i)\bemoji\b' = ''           # Remove "emoji" text
                    ':\w+:' = ''                   # Remove :emoji_name: format
                    
                    # Markdown emoji shortcuts
                    ':white_check_mark:' = 'PASS'
                    ':x:' = 'FAIL'
                    ':warning:' = 'WARNING'
                    ':information_source:' = 'INFO'
                    ':rocket:' = 'LAUNCH'
                    ':bulb:' = 'TIP'
                    ':sparkles:' = 'ENHANCED'
                    ':tada:' = 'COMPLETE'
                    ':dart:' = 'TARGET'
                    ':wrench:' = 'TOOL'
                    ':memo:' = 'NOTE'
                    ':mag:' = 'SEARCH'
                    ':shield:' = 'PROTECTED'
                    ':star:' = 'FEATURED'
                }
                
                # Apply professional replacements
                foreach ($pattern in $replacements.Keys) {
                    $newContent = $newContent -replace $pattern, $replacements[$pattern]
                }
                
                # Remove any remaining emoji patterns
                $newContent = $newContent -replace $emojiRegex, ""
                
                # Clean up multiple spaces and empty sections
                $newContent = $newContent -replace "  +", " "  # Multiple spaces to single space
                $newContent = $newContent -replace "^\s*$", ""  # Empty lines
                $newContent = $newContent -replace "\n\n\n+", "`n`n"  # Multiple blank lines
                
                if ($newContent -ne $content) {
                    $changedFiles++
                    $totalEmojisRemoved += $emojiMatches.Count
                    
                    if (-not $DryRun) {
                        Set-Content -Path $file.FullName -Value $newContent -Encoding UTF8 -NoNewline
                        if ($Verbose) {
                            Write-Host "  Cleaned: $($file.FullName)" -ForegroundColor Green
                        }
                    } else {
                        Write-Host "  Would clean: $($file.FullName)" -ForegroundColor DarkGreen
                    }
                }
            }
        }
        catch {
            Write-Warning "Failed to process $($file.FullName): $($_.Exception.Message)"
        }
    }
}

Write-Host "`nEMOJI PURGE SUMMARY" -ForegroundColor Cyan
Write-Host "Total files scanned: $totalFiles" -ForegroundColor White
Write-Host "Files with emojis: $changedFiles" -ForegroundColor Yellow
Write-Host "Total emojis removed: $totalEmojisRemoved" -ForegroundColor Red

if ($DryRun) {
    Write-Host "`nDRY RUN MODE - No changes were made" -ForegroundColor Magenta
    Write-Host "Run without -DryRun to apply changes" -ForegroundColor Magenta
} else {
    Write-Host "`nEmoji purge completed!" -ForegroundColor Green
}

# Create a simple test to verify no emojis remain
if (-not $DryRun) {
    Write-Host "`nRunning verification scan..." -ForegroundColor Cyan
    
    $remainingEmojis = 0
    foreach ($pattern in $filePatterns) {
        $files = Get-ChildItem -Path $projectRoot -Filter $pattern -Recurse | Where-Object{
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
                if ($content) {
                    $emojiMatches = regex::Matches($content, $emojiRegex)
                    $remainingEmojis += $emojiMatches.Count
                    if ($emojiMatches.Count -gt 0 -and $Verbose) {
                        Write-Host "WARNING: $($file.FullName) still contains $($emojiMatches.Count) emojis" -ForegroundColor Red
                    }
                }
            }
            catch {
                # Ignore errors in verification
            }
        }
    }
    
    if ($remainingEmojis -eq 0) {
        Write-Host "VERIFICATION: No emojis detected in codebase" -ForegroundColor Green
    } else {
        Write-Host "VERIFICATION: $remainingEmojis emojis still detected" -ForegroundColor Red
    }
}
