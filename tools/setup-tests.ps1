# Install dependencies for running Pester and pytest
[CmdletBinding()]
param(
    [switch]$InstallPoetry
)

$ErrorActionPreference = 'Stop'

function Ensure-Module($Name, $Version) {
    if (-not (Get-Module -ListAvailable -Name $Name)) {
        Install-Module -Name $Name -RequiredVersion $Version -Force -Scope CurrentUser
    }
}

Write-Host 'Installing PowerShell modules...'
Ensure-Module -Name 'Pester' -Version '5.6.1'
Ensure-Module -Name 'powershell-yaml' -Version '0.4.2'

$repoRoot = Split-Path $PSScriptRoot -Parent
$pyDir = Join-Path $repoRoot 'py'

if ($InstallPoetry) {
    $poetryScript = Join-Path $repoRoot 'pwsh/runner_scripts/0204_Install-Poetry.ps1'
    if (Test-Path $poetryScript) {
        . $poetryScript -Config @{ InstallPoetry = $true }
    } else {
        Write-Warning "Poetry installer not found at $poetryScript"
    }
}

if (Get-Command poetry -ErrorAction SilentlyContinue) {
    Write-Host 'Installing Python dependencies with Poetry...'
    $env:POETRY_VIRTUALENVS_IN_PROJECT = 'true'
    Push-Location $pyDir
    poetry install --with dev
    Pop-Location
} elseif (Get-Command pip -ErrorAction SilentlyContinue) {
    Write-Host 'Installing Python dependencies with pip...'
    Push-Location $pyDir
    pip install -e .
    Pop-Location
} else {
    Write-Warning 'Neither poetry nor pip found. Install Python 3 to run pytest.'
}
