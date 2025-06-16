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
 [switch]$DryRun,
 [switch]$Verbose
)

# Set strict mode and error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "EMOJI PURGE UTILITY" -ForegroundColor Cyan
Write-Host "Removing all emojis from codebase to prevent parsing issues" -ForegroundColor Yellow

# Define common emoji patterns (comprehensive list)
$emojiPatterns = @(
 # Status indicators
 "[PASS]", "[FAIL]", "[WARN]", "[INFO]",
 
 # Common technical emojis
 "[PASS]", "[FAIL]", "[WARN]", "[INFO]", "", "�", "",
 "�", "", "�", "�", "�", "", "",
 
 # Common feedback emojis
 "�", "�", "", "", "", "�", "⭐",
 
 # Error/warning indicators
 "�", "�", "�", "", "", "", "",
 
 # File/folder indicators
 "�", "�", "�", "�", "�", "", "",
 
 # Process indicators
 "⏳", "⌛", "�", "", "", "�", "�",
 
 # Cloud/network
 "", "�", "�", "�", "�", "�", "�"
)

# Build regex pattern for all emojis
$emojiRegex = "(?:$($emojiPatterns -join '|'))"

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
 $totalFiles++
 
 try {
 $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
 if (-not $content) { continue }
 # Count emojis in this file
 $emojiMatches = [regex]::Matches($content, $emojiRegex)
 
 if ($emojiMatches.Count -gt 0) {
 if ($Verbose) {
 Write-Host "Processing: $($file.FullName)" -ForegroundColor Yellow
 Write-Host " Found $($emojiMatches.Count) emojis" -ForegroundColor DarkYellow
 }
 
 # Remove emojis and replace with appropriate text
 $newContent = $content
 
 # Specific replacements for common patterns
 $replacements = @{
 "" = ""
 "" = ""
 "[PASS]" = "[PASS]"
 "[FAIL]" = "[FAIL]"
 "[WARN]" = "[WARN]"
 "" = ""
 "" = ""
 "" = ""
 "" = ""
 "" = ""
 "" = ""
 "" = ""
 "" = ""
 "" = ""
 "" = ""
 "" = ""
 "" = ""
 "" = ""
 "" = ""
 "" = ""
 "" = ""
 "" = ""
 "" = ""
 "" = ""
 "" = ""
 "" = ""
 "" = ""
 "" = ""
 "[INFO]" = "[INFO]"
 "" = ""
 "" = ""
 "" = ""
 }
 
 # Apply specific replacements first
 foreach ($emoji in $replacements.Keys) {
 $newContent = $newContent -replace [regex]::Escape($emoji), $replacements[$emoji]
 }
 
 # Remove any remaining emojis
 $newContent = $newContent -replace $emojiRegex, ""
 
 # Clean up multiple spaces and empty sections
 $newContent = $newContent -replace " +", " " # Multiple spaces to single space
 $newContent = $newContent -replace "^\s*$", "" # Empty lines
 $newContent = $newContent -replace "\n\n\n+", "`n`n" # Multiple blank lines
 if ($newContent -ne $content) {
 $changedFiles++
 $totalEmojisRemoved += $emojiMatches.Count
 
 if (-not $DryRun) {
 Set-Content -Path $file.FullName -Value $newContent -Encoding UTF8 -NoNewline
 if ($Verbose) {
 Write-Host " Cleaned: $($file.FullName)" -ForegroundColor Green
 }
 } else {
 Write-Host " Would clean: $($file.FullName)" -ForegroundColor DarkGreen
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
 try { $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
 if ($content) {
 $emojiMatches = [regex]::Matches($content, $emojiRegex)
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
