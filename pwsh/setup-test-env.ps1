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

param([switch]$UsePoetry)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
. "$repoRoot/pwsh/lab_utils/Get-Platform.ps1"

function Ensure-Pester {
    if (-not (Get-Module -ListAvailable -Name Pester)) {
        Install-Module -Name Pester -RequiredVersion 5.6.1 -Force -Scope CurrentUser
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

Ensure-Pester
Ensure-Python

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

Write-Host 'Test environment ready.'
