<#
.SYNOPSIS
    Installs global npm packages like yarn, vite, and nodemon using config-based logic.

.DESCRIPTION
    - Assumes Node.js is already installed
    - Installs any npm packages flagged as true in the Node_Dependencies section
    - Must be used in combination with 0201-InstallNodeCore.ps1

.CONFIG FORMAT
{
  "Node_Dependencies": {
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
Write-Output "Config parameter is: $Config"
. "$PSScriptRoot\..\runner_utility_scripts\Logger.ps1"

$ErrorActionPreference = "Stop"

function Install-GlobalPackage($package) {
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        Write-CustomLog "Installing npm package: $package..."
        npm install -g $package
    } else {
        Write-Error "npm is not available. Node.js may not have installed correctly."
    }
}

Write-CustomLog "==== [0202] Installing Global npm Packages ===="

# --- npm Packages ---
if ($Config.Node_Dependencies.InstallYarn) {
    Install-GlobalPackage "yarn"
}

if ($Config.Node_Dependencies.InstallVite) {
    Install-GlobalPackage "vite"
}

if ($Config.Node_Dependencies.InstallNodemon) {
    Install-GlobalPackage "nodemon"
}

Write-CustomLog "==== Global npm package installation complete ===="
