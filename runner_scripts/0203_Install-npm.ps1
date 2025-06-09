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
    if ($Config.Node_Dependencies.CreateNpmPath) {
        Write-CustomLog "Creating missing frontend folder at: $frontendPath"
        New-Item -ItemType Directory -Path $frontendPath -Force | Out-Null
    } else {
        Write-CustomLog "Frontend folder not found at: $frontendPath. Skipping npm install."
        return
    }
}

if (-not (Test-Path (Join-Path $frontendPath "package.json"))) {
    Write-CustomLog "No package.json found in $frontendPath. Skipping npm install."
    return
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

