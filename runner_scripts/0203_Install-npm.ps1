<#
.SYNOPSIS
    Install frontend project dependencies using npm.

.DESCRIPTION
    - Finds the frontend project folder (from config or default)
    - Runs `npm install` inside it
    - Logs results to console and optionally exits on failure

.CONFIG FORMAT
{
  "Node_Dependencies": {
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
. "$PSScriptRoot\..\lab_utils\Invoke-LabScript.ps1"

Invoke-LabScript -Config $Config -ScriptBlock {

$ErrorActionPreference = "Stop"
Write-CustomLog "==== [0203] Installing Frontend npm Dependencies ===="

if ($Config.Node_Dependencies.InstallNpm) {

# Determine frontend path
$frontendPath = if ($Config.Node_Dependencies.NpmPath) {

    $Config.Node_Dependencies.NpmPath
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
    Write-CustomLog "Running npm install in $frontendPath ..."
    npm install
    Write-CustomLog "✅ npm install completed."
} catch {
    Write-Error "ERROR: npm install failed: $_"
    exit 1
}

Pop-Location
Write-CustomLog "==== Frontend dependency installation complete ===="
} else {
    Write-CustomLog "InstallNpm flag is disabled. Skipping project dependency installation."
}

}

