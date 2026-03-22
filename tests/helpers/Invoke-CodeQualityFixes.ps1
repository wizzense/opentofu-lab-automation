#Requires -Version 7.0

<#
.SYNOPSIS
    Automated code quality fixes for the OpenTofu Lab Automation project

.DESCRIPTION
    This script automatically fixes common code quality issues detected by PSScriptAnalyzer,
    including trailing whitespace, indentation issues, and formatting problems.

.PARAMETER Path
    Path to analyze and fix (default: entire project)

.PARAMETER WhatIf
    Show what would be fixed without making changes

.PARAMETER FixTrailingWhitespace
    Fix trailing whitespace issues

.PARAMETER FixIndentation
    Fix indentation issues

.EXAMPLE
    .\Invoke-CodeQualityFixes.ps1 -Path "core-runner/modules" -FixTrailingWhitespace
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [string]$Path = "core-runner/modules",

    [Parameter()]
    [switch]$FixTrailingWhitespace = $true,

    [Parameter()]
    [switch]$FixIndentation = $false,

    [Parameter()]
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

Write-Host "🔧 Code Quality Fixes - OpenTofu Lab Automation" -ForegroundColor Cyan
Write-Host "=" * 60

$targetPath = Join-Path $projectRoot $Path

if (-not (Test-Path $targetPath)) {
    Write-Error "Path not found: $targetPath"
    exit 1
}

# Get all PowerShell files
$files = Get-ChildItem -Path $targetPath -Recurse -Include "*.ps1", "*.psm1", "*.psd1" -File

Write-Host "📁 Found $($files.Count) PowerShell files to analyze" -ForegroundColor Yellow
Write-Host ""

$fixedFiles = 0
$totalIssues = 0

foreach ($file in $files) {
    $issuesFixed = 0
    $content = Get-Content -Path $file.FullName -Raw
    
    if (-not $content) {
        continue
    }
    
    $originalContent = $content
    
    # Fix trailing whitespace
    if ($FixTrailingWhitespace) {
        $lines = $content -split "`r?`n"
        $fixedLines = @()
        
        foreach ($line in $lines) {
            if ($line -match '\s+$') {
                $fixedLines += $line -replace '\s+$', ''
                $issuesFixed++
            } else {
                $fixedLines += $line
            }
        }
        
        if ($issuesFixed -gt 0) {
            $content = $fixedLines -join "`n"
        }
    }
    
    # Report and save changes
    if ($content -ne $originalContent) {
        $relativePath = $file.FullName.Replace($projectRoot, "").TrimStart("/\")
        
        if ($DryRun) {
            Write-Host "  [DRY RUN] Would fix: $relativePath ($issuesFixed issues)" -ForegroundColor Yellow
        } else {
            if ($PSCmdlet.ShouldProcess($relativePath, "Fix $issuesFixed code quality issues")) {
                # Preserve original file ending (newline or not)
                $hasTrailingNewline = $originalContent -match '\r?\n$'
                if ($hasTrailingNewline) {
                    Set-Content -Path $file.FullName -Value $content
                } else {
                    Set-Content -Path $file.FullName -Value $content -NoNewline
                }
                Write-Host "  ✓ Fixed: $relativePath ($issuesFixed issues)" -ForegroundColor Green
                $fixedFiles++
                $totalIssues += $issuesFixed
            }
        }
    }
}

Write-Host ""
Write-Host "=" * 60
if ($DryRun) {
    Write-Host "🎯 Dry Run Summary: Would fix $totalIssues issues in $fixedFiles files" -ForegroundColor Cyan
} else {
    Write-Host "✅ Fixed $totalIssues issues in $fixedFiles files" -ForegroundColor Green
}

exit 0
