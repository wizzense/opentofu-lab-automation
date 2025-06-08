<#
.SYNOPSIS
    Install frontend project dependencies using npm.

.DESCRIPTION
    - Finds the frontend project folder (from config or default)
    - Runs `npm install` inside it
    - Logs results to console and optionally exits on failure

.CONFIG FORMAT
{
  "Dependencies": {
    "InstallNpm": true,
    "NpmPath": "C:\\Projects\\vde-mvp\\frontend"
  }
}

.PARAMETER Config
    The config object passed in from runner.ps1

.EXAMPLE
    .\0203-InstallNpm.ps1 -Config $Config
#>

param(
    [Parameter(Mandatory)]
    [hashtable]$Config
)

$ErrorActionPreference = "Stop"
Write-Host "==== [0203] Installing Frontend npm Dependencies ===="

# Determine frontend path
$frontendPath = if ($Config.Dependencies.FrontendPath) {
    $Config.Dependencies.FrontendPath
} else {
    Join-Path $PSScriptRoot "..\frontend"
}

if (-not (Test-Path $frontendPath)) {
    Write-Error "ERROR: Frontend folder not found at: $frontendPath"
    exit 1
}

if (-not (Test-Path (Join-Path $frontendPath "package.json"))) {
    Write-Error "ERROR: No package.json found in frontend folder. Cannot run npm install."
    exit 1
}

Push-Location $frontendPath

try {
    Write-Host "Running npm install in $frontendPath ..."
    npm install
    Write-Host "✅ npm install completed."
} catch {
    Write-Error "ERROR: npm install failed: $_"
    exit 1
}

Pop-Location
Write-Host "==== Frontend dependency installation complete ===="
