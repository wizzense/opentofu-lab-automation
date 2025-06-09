<#
.SYNOPSIS
    Installs global npm packages like yarn, vite, and nodemon using config-based logic.

.DESCRIPTION
    - Assumes Node.js is already installed
    - Installs any npm packages flagged as true in the Dependencies section
    - Must be used in combination with 0201-InstallNodeCore.ps1

.CONFIG FORMAT
{
  "Dependencies": {
    "InstallYarn": true,
    "InstallVite": true,
    "InstallNodemon": true
  }
}

.PARAMETER Config
    Hashed config object passed from runner.ps1

.EXAMPLE
    .\0202_Install-NodeGlobalPackages.ps1 -Config $Config
#>

param(
    [Parameter(Mandatory)]
    [hashtable]$Config
)
. "$PSScriptRoot\..\runner_utility_scripts\Logger.ps1"

$ErrorActionPreference = "Stop"

function Install-GlobalPackage($package) {
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        Write-Log "Installing npm package: $package..."
        npm install -g $package
    } else {
        Write-Error "npm is not available. Node.js may not have installed correctly."
    }
}

Write-Log "==== [0202] Installing Global npm Packages ===="

# --- npm Packages ---
if ($Config.Dependencies.InstallYarn) {
    Install-GlobalPackage "yarn"
}

if ($Config.Dependencies.InstallVite) {
    Install-GlobalPackage "vite"
}

if ($Config.Dependencies.InstallNodemon) {
    Install-GlobalPackage "nodemon"
}

Write-Log "==== Global npm package installation complete ===="
