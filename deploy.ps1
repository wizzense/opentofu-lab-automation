#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Quick deployment wrapper for OpenTofu Lab Automation
    
.DESCRIPTION
    Simplified entry point that handles all the nested directory navigation automatically.
    Supports both Windows and Linux deployment with sensible defaults.
    
.PARAMETER ConfigFile
    Optional config file path (defaults to included config)
    
.PARAMETER Mode
    Deployment mode: 'bootstrap', 'run', 'validate', 'clean'
    Default: 'bootstrap' (full setup from scratch)
    
.PARAMETER Quiet
    Suppress interactive prompts and verbose output
    
.PARAMETER WhatIf
    Show what would be done without making changes
    
.EXAMPLE
    # Quick start (recommended)
    ./deploy.ps1
    
.EXAMPLE
    # Silent deployment
    ./deploy.ps1 -Quiet
    
.EXAMPLE
    # Just run lab scripts (after bootstrap)
    ./deploy.ps1 -Mode run
    
.EXAMPLE
    # Validate current setup
    ./deploy.ps1 -Mode validate
#>

[CmdletBinding()]
param(
    [string]$ConfigFile,
    [ValidateSet('bootstrap', 'run', 'validate', 'clean')



]
    [string]$Mode = 'bootstrap',
    [switch]$Quiet,
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'

# Detect platform
$isWindows = $PSVersionTable.PSVersion.Major -ge 6 ? $IsWindows : ($env:OS -eq 'Windows_NT')
$scriptRoot = $PSScriptRoot

Write-Host @"
🚀 OpenTofu Lab Automation - Quick Deploy
==========================================
Mode: $Mode
Platform: $$(if (isWindows) { 'Windows' } else { 'Linux' })
Root: $scriptRoot
"@ -ForegroundColor Cyan

# Set default config if not provided
if (-not $ConfigFile) {
    $ConfigFile = Join-Path $scriptRoot "configs/config_files/default-config.json"
    if (-not (Test-Path $ConfigFile)) {
        Write-Warning "Default config not found at $ConfigFile"
        Write-Host "Available configs:" -ForegroundColor Yellow
        Get-ChildItem -Path (Join-Path $scriptRoot "configs/config_files") -Filter "*.json" | ForEach-Object {
            Write-Host "  - $($_.Name)" -ForegroundColor Gray
        }
        throw "Please specify a valid config file or ensure default-config.json exists"
    }
}

# Platform-specific script paths
$kickerScript = Join-Path $scriptRoot "pwsh/kicker-bootstrap.ps1"
$runnerScript = Join-Path $scriptRoot "pwsh/runner.ps1"
$validationScript = Join-Path $scriptRoot "run-final-validation.ps1"

function Invoke-Bootstrap {
    Write-Host "🔧 Starting bootstrap process..." -ForegroundColor Green
    Write-Host "This will set up the complete lab environment from scratch." -ForegroundColor Yellow
    
    if (-not $Quiet -and -not $WhatIf) {
        $confirm = Read-Host "Continue? (y/N)"
        if ($confirm -notmatch '^[Yy]') {
            Write-Host "Bootstrap cancelled." -ForegroundColor Yellow
            return
        }
    }
    
    $args = @()
    if ($ConfigFile) { $args += @('-ConfigFile', $ConfigFile) }
    if ($Quiet) { $args += '-Quiet' }
    if ($WhatIf) { $args += '-WhatIf' }
    
    Write-Host "Executing: pwsh -File '$kickerScript' $($args -join ' ')" -ForegroundColor Gray
    
    if ($WhatIf) {
        Write-Host "Would execute bootstrap with config: $ConfigFile" -ForegroundColor Magenta
    } else {
        & pwsh -File $kickerScript @args
    }
}

function Invoke-Run {
    Write-Host "▶️ Running lab automation..." -ForegroundColor Green
    
    if (-not (Test-Path $runnerScript)) {
        Write-Error "Runner script not found at $runnerScript. Run bootstrap first."
        return
    }
    
    $args = @()
    if ($ConfigFile) { $args += @('-ConfigFile', $ConfigFile) }
    if ($Quiet) { $args += '-Verbosity', 'silent' }
    
    Write-Host "Executing: pwsh -File '$runnerScript' $($args -join ' ')" -ForegroundColor Gray
    
    if ($WhatIf) {
        Write-Host "Would execute runner with config: $ConfigFile" -ForegroundColor Magenta
    } else {
        & pwsh -File $runnerScript @args
    }
}

function Invoke-Validate {
    Write-Host "✅ Validating lab setup..." -ForegroundColor Green
    
    # Quick health check first
    $healthScript = Join-Path $scriptRoot "scripts/maintenance/infrastructure-health-check.ps1"
    if (Test-Path $healthScript) {
        Write-Host "Running infrastructure health check..." -ForegroundColor Gray
        if (-not $WhatIf) {
            & pwsh -File $healthScript -Mode "Quick"
        }
    }
    
    # Full validation
    if (Test-Path $validationScript) {
        Write-Host "Running comprehensive validation..." -ForegroundColor Gray
        if (-not $WhatIf) {
            & pwsh -File $validationScript
        }
    } else {
        Write-Warning "Validation script not found at $validationScript"
    }
}

function Invoke-Clean {
    Write-Host "🧹 Cleaning lab environment..." -ForegroundColor Green
    Write-Host "This will remove deployed lab resources." -ForegroundColor Yellow
    
    if (-not $Quiet -and -not $WhatIf) {
        $confirm = Read-Host "Continue with cleanup? (y/N)"
        if ($confirm -notmatch '^[Yy]') {
            Write-Host "Cleanup cancelled." -ForegroundColor Yellow
            return
        }
    }
    
    # Look for cleanup scripts
    $cleanupScript = Join-Path $scriptRoot "pwsh/runner_scripts/0000_Cleanup-Files.ps1"
    if (Test-Path $cleanupScript) {
        Write-Host "Running cleanup script..." -ForegroundColor Gray
        if (-not $WhatIf) {
            & pwsh -File $cleanupScript -Config (Get-Content $ConfigFile | ConvertFrom-Json)
        }
    } else {
        Write-Warning "Cleanup script not found. Manual cleanup may be required."
    }
}

# Main execution
try {
    switch ($Mode) {
        'bootstrap' { Invoke-Bootstrap }
        'run' { Invoke-Run }
        'validate' { Invoke-Validate }
        'clean' { Invoke-Clean }
    }
    
    Write-Host "`n✅ $Mode completed successfully!" -ForegroundColor Green
    
    # Show next steps
    switch ($Mode) {
        'bootstrap' {
            Write-Host "`n📋 Next steps:" -ForegroundColor Cyan
            Write-Host "  ./deploy.ps1 -Mode validate  # Verify setup" -ForegroundColor Gray
            Write-Host "  ./deploy.ps1 -Mode run       # Run lab scripts" -ForegroundColor Gray
        }
        'run' {
            Write-Host "`n📋 Lab deployment complete!" -ForegroundColor Cyan
            Write-Host "  ./deploy.ps1 -Mode validate  # Check status" -ForegroundColor Gray
            Write-Host "  ./deploy.ps1 -Mode clean     # Cleanup when done" -ForegroundColor Gray
        }
    }
    
} catch {
    Write-Error "❌ $Mode failed: $_"
    exit 1
}


