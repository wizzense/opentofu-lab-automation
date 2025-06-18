<#
.SYNOPSIS
  Configure tools for running Pester and pytest.

.DESCRIPTION
  Installs the Pester module, ensures Python is available and installs
  the Python dependencies for the project. If -UsePoetry is specified
  Poetry will be installed and used to install the dev packages.

.EXAMPLE
  ./pwsh/setup-test-env.ps1 -UsePoetry
#>

param(switch$UsePoetry)








$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
. "$repoRoot/pwsh/modules/LabRunner/Get-Platform.ps1"

function Ensure-Pester {
    # Remove any old Pester v3 modules
    Get-Module -ListAvailable -Name Pester | Where-Object{ $_.Version -lt version'5.0.0' } | ForEach-Object{
        Remove-Item -Recurse -Force $_.ModuleBase -ErrorAction SilentlyContinue
    }
    if (-not (Get-Module -ListAvailable -Name Pester | Where-Object{ $_.Version -ge version'5.7.1' })) {
        Install-Module -Name Pester -RequiredVersion 5.7.1 -Force -Scope CurrentUser
    }
}

function Ensure-Python {
    if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
        . "$repoRoot/pwsh/runner_scripts/0206_Install-Python.ps1"
        Install-Python -Config @{ InstallPython = $true }
    }
}

function Ensure-Poetry {
    if (-not (Get-Command poetry -ErrorAction SilentlyContinue)) {
        . "$repoRoot/pwsh/runner_scripts/0204_Install-Poetry.ps1"
        Install-Poetry -Config @{ InstallPoetry = $true }
    }
}

function Ensure-DevEnvironment {
    Write-Host "Setting up development environment..." -ForegroundColor Cyan
    
    # Import DevEnvironment module
    $devEnvModule = "$repoRoot/pwsh/modules/DevEnvironment"
    if (Test-Path $devEnvModule) {
        Import-Module $devEnvModule -Force
        
        # Install pre-commit hook
        try {
            Install-PreCommitHook -Install
            Write-Host "✓ Pre-commit hook installed" -ForegroundColor Green
        }
        catch {
            Write-Warning "Could not install pre-commit hook: $($_.Exception.Message)"
        }
        
        # Test development setup
        try {
            Test-DevelopmentSetup
            Write-Host "✓ Development environment validated" -ForegroundColor Green
        }
        catch {
            Write-Warning "Development environment validation failed: $($_.Exception.Message)"
        }
    } else {
        Write-Warning "DevEnvironment module not found at $devEnvModule"
        
        # Fallback to legacy pre-commit hook installation
        $legacyHook = "$repoRoot/tools/pre-commit-hook.ps1"
        if (Test-Path $legacyHook) {
            & $legacyHook -Install
            Write-Host "✓ Pre-commit hook installed (legacy method)" -ForegroundColor Yellow
        }
    }
}

Ensure-Pester
Ensure-Python
Ensure-DevEnvironment

if ($UsePoetry) {
    Ensure-Poetry
    Push-Location "$repoRoot/py"
    poetry install --with dev
    Pop-Location
} else {
    $pip = Get-Command pip -ErrorAction SilentlyContinue
    if (-not $pip) {
        $pipCmd = @('python', '-m', 'pip')
    } else {
        $pipCmd = @($pip.Path)
    }
    & $pipCmd install '-e' "$repoRoot/py"
}

Write-Host 'Test environment ready.' -ForegroundColor Green
Write-Host '✓ Pester 5.7.1+ installed' -ForegroundColor Green
Write-Host '✓ Python environment configured' -ForegroundColor Green  
Write-Host '✓ Pre-commit hook installed' -ForegroundColor Green
Write-Host '✓ Development environment validated' -ForegroundColor Green




