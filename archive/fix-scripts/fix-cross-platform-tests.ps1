#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Fix cross-platform compatibility issues in Pester tests
.DESCRIPTION
    This script identifies and fixes common cross-platform issues in test files:
    - Hardcoded paths using forward slashes instead of Join-Path
    - References to deprecated lab_utils paths
    - Missing cross-platform path handling
    - Linux-specific assumptions
.PARAMETER DryRun
    Show what would be changed without making actual changes
.PARAMETER Verbose
    Show detailed information about changes
#>

param(
    switch$DryRun,
    switch$Verbose
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "CROSS-PLATFORM TEST COMPATIBILITY FIXER" -ForegroundColor Cyan
Write-Host "Fixing compatibility issues in Pester tests for Windows/Linux/macOS" -ForegroundColor Yellow

# Get project root
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

# Find all test files
$testFiles = Get-ChildItem -Path (Join-Path $projectRoot "tests") -Filter "*.Tests.ps1" -Recurse

$totalFiles = 0
$changedFiles = 0
$totalIssuesFixed = 0

Write-Host "Scanning $($testFiles.Count) test files..." -ForegroundColor Green

foreach ($testFile in $testFiles) {
    $totalFiles++
    $content = Get-Content -Path $testFile.FullName -Raw -Encoding UTF8
    $originalContent = $content
    $issuesInFile = 0
    
    if ($Verbose) {
        Write-Host "`nProcessing: $($testFile.FullName)" -ForegroundColor Yellow
    }
    
    # Fix 1: Replace hardcoded lab_utils paths with current module structure
    $oldPattern = "pwsh/modules"
    $newPattern = "pwsh/modules/LabRunner"
    if ($content -match $oldPattern) {
        $content = $content -replace regex::Escape($oldPattern), $newPattern
        $issuesInFile++
        if ($Verbose) {
            Write-Host "  Fixed deprecated lab_utils path" -ForegroundColor Green
        }
    }
      # Fix 2: Replace hardcoded forward slash paths with Join-Path
    # Pattern: 'path/subpath' -> Join-Path 'path' 'subpath'
    $pathPattern = '''(^''+/^''+)'''
    $pathMatches = regex::Matches($content, $pathPattern)
    foreach ($match in $pathMatches) {
        $originalPath = $match.Groups1.Value
        # Skip URLs (contain :// or start with http)
        if ($originalPath -match '://^https?') {
            continue
        }
        # Skip if it's already inside Join-Path
        $beforeMatch = $content.Substring(0, $match.Index)
        if ($beforeMatch -match 'Join-Path.*$') {
            continue
        }
        
        # Convert path segments
        $segments = $originalPath -split '/'
        if ($segments.Count -gt 1) {
            $joinPathExpression = "(Join-Path"
            for ($i = 0; $i -lt $segments.Count; $i++) {
                if ($i -eq 0) {
                    $joinPathExpression += " '$($segments$i)'"
                } else {
                    $joinPathExpression = "(Join-Path $joinPathExpression '$($segments$i)')"
                }
            }
            $content = $content.Replace("'$originalPath'", $joinPathExpression)
            $issuesInFile++
            if ($Verbose) {
                Write-Host "  Fixed hardcoded path: $originalPath" -ForegroundColor Green
            }
        }
    }
    
    # Fix 3: Add cross-platform compatibility checks
    if ($content -match 'BeforeAll\s*{' -and $content -notmatch '\$SkipNonWindows') {
        # Add skip condition for non-Windows tests that use Windows-specific features
        $windowsSpecific = @('Hyper-V', 'Registry', 'WMI', 'PXE', 'Sysinternals')
        $isWindowsSpecific = $false
        foreach ($feature in $windowsSpecific) {
            if ($testFile.Name -match $feature -or $content -match $feature) {
                $isWindowsSpecific = $true
                break
            }
        }
        
        if ($isWindowsSpecific) {
            $beforeAllPattern = '(BeforeAll\s*{)'
            $replacement = '$1' + "`n        if (`$SkipNonWindows) { Set-ItResult -Skipped -Because 'Windows-specific functionality' }"
            $content = $content -replace $beforeAllPattern, $replacement
            $issuesInFile++
            if ($Verbose) {
                Write-Host "  Added Windows-specific skip condition" -ForegroundColor Green
            }
        }
    }
    
    # Fix 4: Ensure TestHelpers import uses correct path
    $testHelpersPattern = '\. \(Join-Path \$PSScriptRoot ''"TestHelpers\.ps1''"?\)'
    if ($content -match $testHelpersPattern) {
        $replacement = '. (Join-Path $PSScriptRoot "helpers" "TestHelpers.ps1")'
        $content = $content -replace $testHelpersPattern, $replacement
        $issuesInFile++
        if ($Verbose) {
            Write-Host "  Fixed TestHelpers import path" -ForegroundColor Green
        }
    }
    
    # Fix 5: Add cross-platform temp path handling
    if ($content -match '\$env:TEMP' -and $content -notmatch 'Get-CrossPlatformTempPath') {
        $content = $content -replace '\$env:TEMP', '(Get-CrossPlatformTempPath)'
        $issuesInFile++
        if ($Verbose) {
            Write-Host "  Fixed temp path to be cross-platform" -ForegroundColor Green
        }
    }
    
    # Fix 6: Ensure Pester v5 compatibility
    if ($content -match 'Should\s+-Be' -and $content -notmatch 'Should-Be') {
        # This is already Pester v5 syntax, no change needed
    } elseif ($content -match '\\s*Should\s+Be') {
        # Convert old Pester v4 syntax to v5
        $content = $content -replace '\\s*Should\s+Be', ' Should -Be'
        $issuesInFile++
        if ($Verbose) {
            Write-Host "  Updated to Pester v5 syntax" -ForegroundColor Green
        }
    }
    
    # Fix 7: Add proper module imports at the beginning
    if ($content -notmatch '\. \(Join-Path \$PSScriptRoot ''"helpers''" ''"TestHelpers\.ps1''"?\)') {
        # Add TestHelpers import if missing
        $importLine = '. (Join-Path $PSScriptRoot "helpers" "TestHelpers.ps1")'
        
        # Find first Describe block and insert import before it
        if ($content -match '(Describe\s+''"^''"*)') {
            $content = $content -replace '(Describe\s+''"^''*)', "$importLine`n`n`$1"
            $issuesInFile++
            if ($Verbose) {
                Write-Host "  Added TestHelpers import" -ForegroundColor Green
            }
        }
    }
    
    # Save changes if any were made
    if ($content -ne $originalContent) {
        $changedFiles++
        $totalIssuesFixed += $issuesInFile
        
        if (-not $DryRun) {
            Set-Content -Path $testFile.FullName -Value $content -Encoding UTF8 -NoNewline
            if ($Verbose) {
                Write-Host "  Saved changes to: $($testFile.FullName)" -ForegroundColor Green
            }
        } else {
            Write-Host "  Would fix $issuesInFile issues in: $($testFile.FullName)" -ForegroundColor DarkGreen
        }
    }
}

Write-Host "`nCROSS-PLATFORM COMPATIBILITY FIX SUMMARY" -ForegroundColor Cyan
Write-Host "Total test files scanned: $totalFiles" -ForegroundColor White
Write-Host "Files with compatibility issues: $changedFiles" -ForegroundColor Yellow
Write-Host "Total issues fixed: $totalIssuesFixed" -ForegroundColor Green

if ($DryRun) {
    Write-Host "`nDRY RUN MODE - No changes were made" -ForegroundColor Magenta
    Write-Host "Run without -DryRun to apply changes" -ForegroundColor Magenta
} else {
    Write-Host "`nCross-platform compatibility fixes completed!" -ForegroundColor Green
    Write-Host "Tests should now work properly on Windows, Linux, and macOS" -ForegroundColor Green
}

# Additional recommendations
Write-Host "`nRECOMMENDATIONS:" -ForegroundColor Cyan
Write-Host "1. Run 'Invoke-Pester' to verify all tests pass" -ForegroundColor White
Write-Host "2. Test on multiple platforms if possible" -ForegroundColor White
Write-Host "3. Use `$SkipNonWindows variable for platform-specific tests" -ForegroundColor White
Write-Host "4. Always use Join-Path for file system paths" -ForegroundColor White

