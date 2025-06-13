#!/usr/bin/env pwsh
<#
.SYNOPSIS
Unified auto-fix script using CodeFixer module

.DESCRIPTION
Simple wrapper around the CodeFixer module for comprehensive auto-fixing
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)


]
    [string]$Path = ".",
    
    [switch]$AutoFix,
    [switch]$WhatIf,
    [switch]$SkipValidation,
    [switch]$CleanupRoot
)

# Display header
Write-Host "🚀 Running OpenTofu Lab Automation Auto-Fix" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# Import CodeFixer module
$moduleRoot = Join-Path $PSScriptRoot "pwsh/modules/CodeFixer"
$modulePath = Join-Path $moduleRoot "CodeFixer.psd1"
if (-not (Test-Path $modulePath)) {
    Write-Error "CodeFixer module not found at: $modulePath"
    exit 1
}

Write-Host "Importing CodeFixer module from: $modulePath" -ForegroundColor Gray
Import-Module $modulePath -Force -ErrorAction Stop

# If functions aren't recognized, load them directly
if (-not (Get-Command -Name "Invoke-ComprehensiveAutoFix" -ErrorAction SilentlyContinue)) {
    Write-Host "Importing functions directly from PS1 files..." -ForegroundColor Yellow
    # Get and dot source the public functions
    $publicFunctions = Get-ChildItem -Path "$moduleRoot\Public\*.ps1" -ErrorAction SilentlyContinue
    foreach ($function in $publicFunctions) {
        try {
            . $function.FullName
            Write-Host "  - Loaded function: $($function.BaseName)" -ForegroundColor DarkGray
        } catch {
            Write-Warning "Failed to load function $($function.BaseName): $_"
        }
    }
}

# Check if we need to clean up the root directory
if ($CleanupRoot) {
    Write-Host "Running root directory cleanup..." -ForegroundColor Yellow
    $cleanupScript = Join-Path $PSScriptRoot "scripts/maintenance/cleanup-root-scripts.ps1"
    if (Test-Path $cleanupScript) {
        & $cleanupScript -WhatIf:$WhatIf
    } else {
        Write-Warning "Cleanup script not found: $cleanupScript"
    }
}

# Run comprehensive auto-fix
Write-Host "Running comprehensive auto-fix..." -ForegroundColor Yellow
$fixParams = @{
    Path = $Path
    Recurse = $true
}
if ($AutoFix) { $fixParams.AutoFix = $true }
if ($WhatIf) { $fixParams.WhatIf = $true }

try {
    Invoke-ComprehensiveAutoFix @fixParams
} catch {
    Write-Warning "Comprehensive auto-fix error: $_"
}

Write-Host "✅ Auto-fix operations completed" -ForegroundColor Green


